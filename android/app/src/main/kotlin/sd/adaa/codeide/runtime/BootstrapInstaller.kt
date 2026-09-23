package sd.adaa.codeide.runtime

import android.content.Context
import android.system.Os
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry
import org.apache.commons.compress.archivers.zip.ZipFile
import sd.adaa.codeide.BuildConfig
import sd.adaa.codeide.EnvironmentManager
import sd.adaa.codeide.bridge.SetupStatus
import java.io.File
import java.io.FileOutputStream
import java.nio.file.Files
import java.security.MessageDigest

/**
 * Installs the embedded Termux-style bootstrap (plan.md §2 §6, task.md §6 §31).
 * Extracts the zipped prefix (bin/, etc/, lib/, libexec/, share/, ...) directly
 * into [EnvironmentManager.prefix], restores unix modes and SYMLINKS.txt links,
 * then stamps the sha256 into filesDir/.bootstrap-version.
 */
class BootstrapInstaller(private val context: Context) {

    fun isInstalled(): Boolean = EnvironmentManager.isBootstrapInstalled(context)

    fun patchExisting() {
        val prefix = EnvironmentManager.prefix(context)
        if (prefix.exists()) {
            // Phase 2: byte-patching is a LEGACY-termux migration only. A
            // Nova-built bootstrap already points at this app's paths, so the
            // full-tree binary walk would be a pointless 100% hit; skip it.
            if (EnvironmentManager.readOrigin(context) != EnvironmentManager.ORIGIN_NOVA) {
                patchHardcodedPaths(prefix)
            }
            configureApt(prefix)
        }
        stageNovaExec(prefix)
    }

    fun getStatus(): SetupStatus = if (isInstalled()) {
        SetupStatus(
            ready = true,
            bootstrapVersion = EnvironmentManager.bootstrapVersion(context),
        )
    } else {
        SetupStatus(
            ready = false,
            bootstrapVersion = null,
            error = "Bootstrap not installed.",
        )
    }

    fun start(onProgress: (String, Float) -> Unit, done: (Result<Unit>) -> Unit) {
        Thread {
            try {
                install(onProgress)
                done(Result.success(Unit))
            } catch (e: Throwable) {
                done(Result.failure(e))
            }
        }.start()
    }

    private fun install(onProgress: (String, Float) -> Unit) {
        val variant = readVariant()
        val arch = EnvironmentManager.arch()
        val zipFile = EnvironmentManager.bootstrapZip(context)
        val prefix = EnvironmentManager.prefix(context)
        val expectedSha = EnvironmentManager.bootstrapVariantSha256(variant)
            ?: error("No bootstrap for variant $variant on ABI $arch (only aarch64/x86_64)")
        val baseUrl = when (variant) {
            EnvironmentManager.BOOTSTRAP_VARIANT_FULL ->
                BuildConfig.NOVA_BOOTSTRAP_FULL_BASE_URL
            else -> BuildConfig.NOVA_BOOTSTRAP_SLIM_BASE_URL
        }.trim().trimEnd('/')
        require(baseUrl.isNotEmpty()) {
            "Bootstrap base URL is empty: bootstraps are downloaded, not bundled"
        }
        val url = "$baseUrl/$variant-$arch.zip"

        if (!(zipFile.exists() && sha256(zipFile).equals(expectedSha, ignoreCase = true))) {
            onProgress("downloading", 0.05f)
            downloadBootstrap(url, zipFile, onProgress)
        }

        onProgress("verifying", 0.35f)
        val actual = sha256(zipFile)
        require(actual.equals(expectedSha, ignoreCase = true)) {
            "Bootstrap SHA-256 mismatch: expected $expectedSha, got $actual"
        }

        onProgress("extracting", 0.6f)
        migratePrefix(prefix)
        extract(zipFile, prefix)

        onProgress("configuring", 0.9f)
        makeExecutable(File(prefix, "bin"))
        makeExecutable(File(prefix, "libexec"))
        patchHardcodedPaths(prefix)
        configureApt(prefix)
        configureInputrc()
        stageNovaExec(prefix)

        File(context.filesDir, ".bootstrap-version")
            .writeText(expectedSha)
        EnvironmentManager.originMarker(context)
            .writeText(EnvironmentManager.currentOrigin())

        onProgress("done", 1.0f)
    }

    /**
     * Phase 2 migration: when the origin the prefix was BUILT with differs
     * from the bundled bootstrap's origin (legacy Termux layout vs Nova-built
     * layout), the old tree is incompatible and must be rebuilt. Wipe PREFIX
     * only — HOME lives at files/home, outside the prefix, so user files
     * survive. Same-origin reinstalls skip the wipe to preserve installed
     * runtimes (node, python, ...).
     */
    private fun migratePrefix(prefix: File) {
        if (!prefix.exists()) return
        val stored = EnvironmentManager.readOrigin(context) ?: EnvironmentManager.ORIGIN_LEGACY
        val current = EnvironmentManager.currentOrigin()
        if (stored == current) return
        android.util.Log.i(
            "BootstrapInstaller",
            "Origin changed ($stored -> $current): wiping prefix for rebuild (home preserved)"
        )
        prefix.listFiles()?.forEach { f ->
            try {
                f.deleteRecursively()
            } catch (_: Exception) {
            }
        }
    }

    /**
     * Variant picked on the setup screen ("slim" or "full"). Dart persists it
     * via shared_preferences, which lands in the FlutterSharedPreferences
     * file that both sides can read — no bridge change needed. Unknown or
     * missing values fall back to slim.
     */
    private fun readVariant(): String {
        val stored = try {
            context.getSharedPreferences(
                EnvironmentManager.BOOTSTRAP_PREFS_FILE,
                Context.MODE_PRIVATE,
            ).getString(EnvironmentManager.BOOTSTRAP_VARIANT_PREF, null)
        } catch (_: Exception) {
            null
        }
        return if (stored == EnvironmentManager.BOOTSTRAP_VARIANT_FULL) {
            EnvironmentManager.BOOTSTRAP_VARIANT_FULL
        } else {
            EnvironmentManager.BOOTSTRAP_VARIANT_SLIM
        }
    }

    /**
     * Downloads the bootstrap zip with progress (fraction mapped to
     * 0.05→0.30 so later phases keep their weights). Writes to a .part file
     * and renames atomically; partial files are deleted on failure.
     */
    private fun downloadBootstrap(
        url: String,
        dest: File,
        onProgress: (String, Float) -> Unit,
    ) {
        dest.parentFile?.mkdirs()
        val part = File(dest.parentFile, "${dest.name}.part")
        if (part.exists()) part.delete()
        // NOTE: HttpURLConnection refuses to auto-follow HTTPS->HTTP
        // downgrades, and our host 301-redirects github.io to a custom
        // domain. Follow redirects manually (max 5 hops).
        var currentUrl = url
        var connection: java.net.HttpURLConnection? = null
        try {
            var hops = 0
            while (true) {
                connection?.disconnect()
                connection = java.net.URL(currentUrl).openConnection()
                    as java.net.HttpURLConnection
                connection.instanceFollowRedirects = false
                connection.connectTimeout = 15000
                connection.readTimeout = 30000
                connection.connect()
                val code = connection.responseCode
                if (code in 300..399) {
                    require(hops < 5) { "Too many redirects downloading bootstrap" }
                    val location = connection.getHeaderField("Location")
                        ?: error("Redirect without Location for $currentUrl")
                    currentUrl = java.net.URL(java.net.URL(currentUrl), location).toString()
                    hops++
                    continue
                }
                require(code == java.net.HttpURLConnection.HTTP_OK) {
                    "Bootstrap download failed: HTTP $code for $currentUrl"
                }
                break
            }
            val total = connection.contentLengthLong
            var received = 0L
            connection.inputStream.use { input ->
                FileOutputStream(part).use { output ->
                    val buf = ByteArray(256 * 1024)
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        output.write(buf, 0, n)
                        received += n
                        if (total > 0) {
                            val frac = 0.05f + 0.25f * (received.toFloat() / total)
                            onProgress("downloading", frac.coerceIn(0.05f, 0.30f))
                        }
                    }
                }
            }
            require(part.length() > 0) { "Bootstrap download is empty: $url" }
            if (dest.exists()) dest.delete()
            require(part.renameTo(dest)) { "Cannot move downloaded bootstrap into place" }
        } catch (e: Exception) {
            try {
                if (part.exists()) part.delete()
            } catch (_: Exception) {
            }
            throw e
        } finally {
            connection?.disconnect()
        }
    }

    /**
     * Ships OUR exec interceptor (Phase 1 production integration): copies
     * libnova-exec.so built with the APK (Nova paths baked in) over
     * `$PREFIX/lib/libnova-exec.so`, which is what linker-mode
     * `LD_PRELOAD` points at. The bootstrap zip keeps the legacy file so its
     * SHA stays valid; this overlay always wins. Re-applied by
     * [patchExisting], so updates and repairs restore it. Best-effort:
     * no-op when the APK has no nova-exec build for this ABI.
     */
    private fun stageNovaExec(prefix: File) {
        try {
            val src = File(context.applicationInfo.nativeLibraryDir, "libnova-exec.so")
            if (!src.isFile) return
            val dest = File(prefix, "lib/libnova-exec.so")
            if (dest.isFile && dest.length() == src.length()) return
            dest.parentFile?.mkdirs()
            src.copyTo(dest, overwrite = true)
        } catch (_: Exception) {
            // Best-effort: linker mode degrades to legacy preload behavior.
        }
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private fun extract(zip: File, prefix: File) {
        prefix.mkdirs()
        val symlinkLines = mutableListOf<String>()
        ZipFile(zip).use { zf ->
            val entries = zf.entries.toList()
            for (entry in entries) {
                val name = entry.name
                if (name == "SYMLINKS.txt") {
                    zf.getInputStream(entry).bufferedReader().readLines().forEach { symlinkLines.add(it.trim()) }
                    continue
                }
                if (entry.isUnixSymlink) {
                    continue
                }
                val target = File(prefix, name)
                if (entry.isDirectory) {
                    target.mkdirs()
                    continue
                }
                target.parentFile?.mkdirs()
                zf.getInputStream(entry).use { input ->
                    FileOutputStream(target).use { output -> input.copyTo(output) }
                }
                if (entry.unixMode != 0 && (entry.unixMode and 0x49) != 0) {
                    target.setExecutable(true, false)
                }
                if (entry.unixMode != 0 && (entry.unixMode and 0x54) != 0) {
                    target.setReadable(true, false)
                }
            }
        }
        createSymlinks(symlinkLines, prefix)
    }

    private fun createSymlinks(lines: List<String>, prefix: File) {
        var created = 0
        var failed = 0
        for (line in lines) {
            if (line.isEmpty()) continue
            // Separator is ← (U+2190) in the Termux apt.android-7 bootstrap archives
            val sep = line.indexOf('\u2190')
            if (sep <= 0) continue
            val target = line.substring(0, sep)
            var relPath = line.substring(sep + 1)
            if (relPath.startsWith("./")) relPath = relPath.substring(2)
            val link = File(prefix, relPath)
            link.parentFile?.mkdirs()
            try {
                if (link.exists()) link.delete()
                Os.symlink(target, link.absolutePath)
                created++
            } catch (e: Exception) {
                failed++
            }
        }
        android.util.Log.i("BootstrapInstaller", "Symlinks: created=$created failed=$failed")
    }

    private fun makeExecutable(dir: File) {
        if (!dir.isDirectory) return
        dir.listFiles()?.forEach { f ->
            if (f.isDirectory && !Files.isSymbolicLink(f.toPath())) {
                makeExecutable(f)
            } else if (!f.isDirectory) {
                f.setExecutable(true, false)
            }
        }
    }

    /**
     * Persist the apt configuration that the embedded bootstrap needs to work
     * under this app (previously applied by hand on the device and lost on
     * re-extraction):
     *  - while the Phase-2 Nova repository is configured (NOVA_REPO_URL), list
     *    it FIRST via sources.list.d/nova.list, signed by the bundled keyring
     *    when present (best-effort [trusted=yes] until the key ships);
     *  - keep the Cloudflare termux-main mirror as fallback with [trusted=yes]
     *    (the termux-keyring/gpgv snapshot in the bootstrap cannot verify
     *    NO_PUBKEY);
     *  - allow unauthenticated/insecure repositories in 99-nova.conf;
     *  - rebind apt's cache/archive directories to paths under our data dir so
     *    dpkg can write them.
     * Idempotent — safe to call on every boot via [patchExisting].
     */
    private fun configureApt(prefix: File) {
        try {
            val filesDir = context.filesDir
            val etc = File(prefix, "etc/apt")
            val confDir = File(etc, "apt.conf.d")
            val sourcesListDir = File(etc, "sources.list.d")
            etc.mkdirs()
            confDir.mkdirs()
            sourcesListDir.mkdirs()

            // 0. Nova binary repository (Phase 2). Not written until a release
            // build sets NOVA_REPO_URL; debug/github builds keep the legacy
            // mirror and current behavior byte-for-byte.
            val novaUrl = BuildConfig.NOVA_REPO_URL
            if (novaUrl.isNotBlank()) {
                val keyring = installNovaKeyring(etc)
                val pin =
                    if (keyring != null) "signed-by=${keyring.absolutePath}" else "trusted=yes"
                File(sourcesListDir, "nova.list").writeText(
                    "deb [$pin] $novaUrl ${BuildConfig.NOVA_REPO_SUITE} main\n"
                )
            }

            // 1. Legacy Termux fallback while the Nova repo is not live.
            val sources = File(etc, "sources.list")
            sources.writeText(
                "# The main termux repository, with cloudflare cache (trusted for embedded keyless bootstrap)\n" +
                    "deb [trusted=yes] https://packages-cf.termux.dev/apt/termux-main/ stable main\n"
            )

            // 2. Allow unauthenticated + rebind caches under our data dir.
            val novaConf = File(confDir, "99-nova.conf")
            val cacheRoot = File(filesDir, "cache")
            novaConf.writeText(
                "// Nova embedded environment: packages are pinned+verified at build time.\n" +
                    "APT::Get::AllowUnauthenticated \"true\";\n" +
                    "Acquire::AllowInsecureRepositories \"true\";\n" +
                    "Acquire::AllowDowngradeToInsecureRepositories \"true\";\n" +
                    "Dir::Cache \"${cacheRoot.absolutePath}\";\n" +
                    "Dir::State \"${File(prefix, "var/lib/apt").absolutePath}\";\n" +
                    "Dir::State::lists \"${cacheRoot.absolutePath}/apt/lists\";\n" +
                    "Dir::Cache::archives \"${cacheRoot.absolutePath}/apt/archives\";\n"
            )

            // 3. Create the cache dirs dpkg/apt expect to exist (partial/ etc).
            File(cacheRoot, "apt/lists/partial").mkdirs()
            File(cacheRoot, "apt/archives/partial").mkdirs()
            File(cacheRoot, "apt/archives").mkdirs()
            File(prefix, "var/lib/apt/lists/partial").mkdirs()
            File(prefix, "var/cache/apt/archives/partial").mkdirs()

            android.util.Log.i(
                "BootstrapInstaller",
                "configureApt: sources.list + 99-nova.conf + cache dirs under $cacheRoot"
            )
        } catch (e: Exception) {
            android.util.Log.w("BootstrapInstaller", "configureApt failed: ${e.message}")
        }
    }

    /**
     * Best-effort install of the Nova repository signing key shipped as an APK
     * asset (`assets/apt/nova.gpg`). Returns the keyring path when present, or
     * null when the build has no key yet (then configureApt falls back to
     * [trusted=yes], which is fine for pre-release builds).
     */
    private fun installNovaKeyring(etc: File): File? {
        return try {
            val dir = "apt"
            val name = "nova.gpg"
            if (context.assets.list(dir)?.contains(name) != true) return null
            val dest = File(File(etc, "trusted.gpg.d"), name)
            dest.parentFile?.mkdirs()
            context.assets.open("$dir/$name").use { input ->
                FileOutputStream(dest).use { output -> input.copyTo(output) }
            }
            android.util.Log.i("BootstrapInstaller", "Installed Nova keyring at ${dest.absolutePath}")
            dest
        } catch (e: Exception) {
            android.util.Log.w("BootstrapInstaller", "installNovaKeyring failed: ${e.message}")
            null
        }
    }

    /**
     * Drops a completion-friendly ~/.inputrc for the embedded bash (used by the
     * terminal key bar's Tab key): list candidates immediately, ignore case,
     * no bell, and prefix history search on Up/Down. Created once — an existing
     * user file is never overwritten. Idempotent via [patchExisting].
     */
    private fun configureInputrc() {
        try {
            val home = EnvironmentManager.home(context)
            home.mkdirs()
            val inputrc = File(home, ".inputrc")
            if (inputrc.exists()) return
            inputrc.writeText(
                "# Nova terminal defaults: friendlier completion on a phone keyboard.\n" +
                    "set show-all-if-ambiguous on\n" +
                    "set completion-ignore-case on\n" +
                    "set colored-stats on\n" +
                    "set bell-style none\n" +
                    "\"\\e[A\": history-search-backward\n" +
                    "\"\\e[B\": history-search-forward\n"
            )
        } catch (e: Exception) {
            android.util.Log.w("BootstrapInstaller", "configureInputrc failed: ${e.message}")
        }
    }

    private fun patchHardcodedPaths(prefix: File) {
        // Termux bootstrap hardcodes /data/data/com.termux/files/usr (31 chars via wc -c).
        // Our package is sd.adaa.codeide (prefix = /data/user/0/sd.adaa.codeide/files/usr).
        // apt fails with "Unable to determine packaging system type" because it still looks for com.termux.
        // We patch the hardcoded 31-char string in-place to a same-length writable path that we control:
        //   /data/data/com.termux/files/usr (31) -> /data/user/0/sd.adaa.codeide/ab (31)
        // We create a symlink at appDir/ab -> files/usr, so the patched path resolves correctly.
        val filesDir = prefix.parentFile ?: return
        val appDir = filesDir.parentFile ?: filesDir
        // ab must be at /data/user/0/sd.adaa.codeide/ab -> files/usr
        val abLink = File(appDir, "ab")
        try {
            if (!abLink.exists()) {
                Os.symlink("files/usr", abLink.absolutePath)
                android.util.Log.i("BootstrapInstaller", "Created ab symlink for prefix patch at ${abLink.absolutePath}")
            }
        } catch (_: Exception) {}
        // Ensure old x links still exist for backward compat
        try {
            val xLink = File(appDir, "x")
            if (!xLink.exists()) Os.symlink("files/usr", xLink.absolutePath)
            val oldX = File(filesDir, "x")
            if (!oldX.exists()) Os.symlink("usr", oldX.absolutePath)
        } catch (_: Exception) {}

        val needle = "/data/data/com.termux/files/usr".toByteArray(Charsets.UTF_8)
        // Replacement must be same length (31) to allow in-place patch.
        val replacementBase = "/data/user/0/sd.adaa.codeide/ab".toByteArray(Charsets.UTF_8)
        val replacement = ByteArray(needle.size) { 0 }
        System.arraycopy(replacementBase, 0, replacement, 0, minOf(replacementBase.size, replacement.size))

        var patchedFiles = 0
        var patchedOccurrences = 0
        fun patchFile(file: File) {
            if (!file.isFile || Files.isSymbolicLink(file.toPath())) return
            if (file.length() > 20_000_000) return
            try {
                val bytes = file.readBytes()
                var count = 0
                var i = 0
                while (i <= bytes.size - needle.size) {
                    var match = true
                    for (j in needle.indices) {
                        if (bytes[i + j] != needle[j]) { match = false; break }
                    }
                    if (match) {
                        System.arraycopy(replacement, 0, bytes, i, needle.size)
                        count++
                        i += needle.size
                    } else {
                        i++
                    }
                }
                if (count > 0) {
                    file.writeBytes(bytes)
                    patchedFiles++
                    patchedOccurrences += count
                }
            } catch (_: Exception) {}
        }
        fun walk(dir: File) {
            dir.listFiles()?.forEach { f ->
                if (f.isDirectory && !Files.isSymbolicLink(f.toPath())) {
                    walk(f)
                } else {
                    patchFile(f)
                }
            }
        }
        walk(prefix)
        // Additionally patch the shorter 22-char prefix if it appears alone
        if (patchedOccurrences > 0) {
            android.util.Log.i("BootstrapInstaller", "Patched hardcoded com.termux/files/usr: files=$patchedFiles occurrences=$patchedOccurrences")
        }
        // Also patch any remaining /data/data/com.termux (22 chars) occurrences to our data dir via empty
        val needle2 = "/data/data/com.termux".toByteArray(Charsets.UTF_8)
        var patched2 = 0
        var occ2 = 0
        fun patchFile2(file: File) {
            if (!file.isFile || Files.isSymbolicLink(file.toPath())) return
            if (file.length() > 20_000_000) return
            try {
                val bytes = file.readBytes()
                var count = 0
                var i = 0
                while (i <= bytes.size - needle2.size) {
                    var match = true
                    for (j in needle2.indices) {
                        if (bytes[i + j] != needle2[j]) { match = false; break }
                    }
                    if (match) {
                        // Replace with /data/user/0/sd.adaa.codeide padded to 22 with nulls
                        // /data/user/0/sd.adaa.codeide is 28, too long, so we use /data/data/sd.adaa (19) padded, but we already have x trick for the longer one.
                        // For the 22-char case, just null the first byte to make it empty (Dir will be used)
                        bytes[i] = 0
                        count++
                        i += needle2.size
                    } else {
                        i++
                    }
                }
                if (count > 0) {
                    file.writeBytes(bytes)
                    patched2++
                    occ2 += count
                }
            } catch (_: Exception) {}
        }
        fun walk2(dir: File) {
            dir.listFiles()?.forEach { f ->
                if (f.isDirectory && !Files.isSymbolicLink(f.toPath())) {
                    walk2(f)
                } else {
                    patchFile2(f)
                }
            }
        }
        // Only do second pass if first didn't cover all (it should have for files/usr case)
        // We run it anyway for completeness, but log separately
        walk2(prefix)
        if (occ2 > 0) {
            android.util.Log.i("BootstrapInstaller", "Patched remaining com.termux prefixes: files=$patched2 occurrences=$occ2")
        }
    }
}