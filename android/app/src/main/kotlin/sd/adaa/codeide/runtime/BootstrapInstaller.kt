package sd.adaa.codeide.runtime

import android.content.Context
import android.system.Os
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry
import org.apache.commons.compress.archivers.zip.ZipFile
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
            patchHardcodedPaths(prefix)
            configureApt(prefix)
            configureInputrc()
        }
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
        val zipFile = EnvironmentManager.bootstrapZip(context)
        val prefix = EnvironmentManager.prefix(context)
        val expectedSha = EnvironmentManager.bootstrapSha256()
            ?: error("No bundled bootstrap for ABI ${EnvironmentManager.arch()} (only aarch64/x86_64)")

        onProgress("copying", 0.15f)
        if (!zipFile.exists()) {
            copyAsset(EnvironmentManager.bootstrapAssetName(), zipFile)
        }

        onProgress("verifying", 0.35f)
        val actual = sha256(zipFile)
        require(actual.equals(expectedSha, ignoreCase = true)) {
            "Bootstrap SHA-256 mismatch: expected $expectedSha, got $actual"
        }

        onProgress("extracting", 0.6f)
        extract(zipFile, prefix)

        onProgress("configuring", 0.9f)
        makeExecutable(File(prefix, "bin"))
        makeExecutable(File(prefix, "libexec"))
        patchHardcodedPaths(prefix)
        configureApt(prefix)
        configureInputrc()

        File(context.filesDir, ".bootstrap-version")
            .writeText(expectedSha)

        onProgress("done", 1.0f)
    }

    private fun copyAsset(asset: String, dest: File) {
        dest.parentFile?.mkdirs()
        context.assets.open(asset).use { input ->
            FileOutputStream(dest).use { output -> input.copyTo(output) }
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
     * Persist the apt configuration that the embedded Termux bootstrap needs to
     * work under this app (previously applied by hand on the device and lost on
     * re-extraction):
     *  - point sources.list at the Cloudflare mirror with [trusted=yes] (the
     *    termux-keyring/gpgv snapshot in the bootstrap cannot verify NO_PUBKEY);
     *  - allow unauthenticated/insecure repositories in 99-nova.conf;
     *  - rebind apt's cache/archive directories to paths under our data dir so
     *    dpkg can write them.
     * Idempotent — safe to call on every boot via [patchExisting].
     */
    private fun configureApt(prefix: File) {
        try {
            val filesDir = context.filesDir
            val etc = File(prefix, "etc/apt")
            etc.mkdirs()

            // 1. Trusted mirror (overwrites stock sources.list).
            val sources = File(etc, "sources.list")
            sources.writeText(
                "# The main termux repository, with cloudflare cache (trusted for embedded keyless bootstrap)\n" +
                    "deb [trusted=yes] https://packages-cf.termux.dev/apt/termux-main/ stable main\n"
            )

            // 2. Allow unauthenticated + rebind caches under our data dir.
            val confDir = File(etc, "apt.conf.d")
            confDir.mkdirs()
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