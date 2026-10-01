package sd.adaa.codeide.runtime

import android.content.Context
import sd.adaa.codeide.BuildConfig
import sd.adaa.codeide.EnvironmentManager
import sd.adaa.codeide.IdeEvents
import sd.adaa.codeide.IdeService
import sd.adaa.codeide.bridge.RuntimeInfo
import sd.adaa.codeide.process.ShellExecutor
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Installs / inspects / removes runtimes through the embedded bootstrap's apt
 * (task.md §13-§17). Runs inside the embedded environment (PREFIX/LD_PRELOAD
 * set by [ShellExecutor]).
 *
 * Install strategy: Termux .debs are laid out as `./data/data/com.termux/files/usr/...`
 * and dpkg refuses to create those parent dirs in our sandbox (Permission denied).
 * So we apt-download-only the package + its dependencies, then unpack each .deb
 * with `dpkg-deb --fsys-tarfile | tar --strip-components=5` directly into our
 * prefix. Installed-ness is therefore determined by binary presence, not dpkg
 * state (which is never written for extracted packages).
 */
class RuntimeManager(
    private val installer: BootstrapInstaller,
    private val context: Context,
) {

    private val shell = ShellExecutor(context)
    private val prefix get() = EnvironmentManager.prefix(context)
    private val filesDir get() = EnvironmentManager.filesDir(context)
    private val cwd get() = EnvironmentManager.home(context)
    private val env get() = EnvironmentManager.buildEnvironment(context)

    // Version cache: Pigeon handlers run on the platform main thread, so
    // getRuntimes()/getRuntime() must never block on process exec. Probing
    // every installed binary costs seconds (kotlinc alone takes ~4s of JVM
    // startup) and trips an ANR with 500+ skipped frames. The hot path below
    // does only File.exists checks + cache reads; version probing happens on
    // a background pool and notifies Dart with `runtimeVersionsRefreshed`.
    private val versionCache = ConcurrentHashMap<String, String>()
    private val probedAt = ConcurrentHashMap<String, Long>()
    private val versionProbes: ExecutorService =
        Executors.newFixedThreadPool(4) { r ->
            Thread(r).apply { isDaemon = true; name = "runtime-version" }
        }
    private val refreshCoordinator: ExecutorService =
        Executors.newSingleThreadExecutor { r ->
            Thread(r).apply { isDaemon = true; name = "runtime-refresh" }
        }

    @Volatile
    private var refreshInFlight = false

    @Volatile
    private var refreshAgain = false

    companion object {
        private const val VERSION_TTL_MS = 60_000L
        private const val VERSION_TIMEOUT_MS = 10_000L
    }

    /** Fast path: install flags + cached versions only, never execs. */
    fun getRuntimes(): List<RuntimeInfo> {
        val infos = RuntimeRegistry.all.map { toInfoFast(it) }
        val stale = RuntimeRegistry.all.filter { needsProbe(it) }
        if (stale.isNotEmpty()) refreshVersionsAsync(stale)
        return infos
    }

    /** Fast path: install flag + cached version only, never execs. */
    fun getRuntime(id: String): RuntimeInfo {
        val def = byId(id)
        val info = toInfoFast(def)
        if (needsProbe(def)) refreshVersionsAsync(listOf(def))
        return info
    }

    fun isInstalled(id: String): Boolean {
        val def = byId(id)
        return isInstalled(def)
    }

    /** Downloads + unpacks a runtime and its dependency closure into PREFIX. */
    fun install(
        id: String,
        onProgress: (String) -> Unit,
        done: (Result<Unit>) -> Unit,
        execMode: String = BuildConfig.DEFAULT_EXEC_MODE,
    ) {
        // User-initiated install: (re)start keep-alive (see TerminalManager).
        try {
            IdeService.start(context)
        } catch (_: Exception) {
        }
        val def = byId(id)
        val env = EnvironmentManager.buildEnvironment(context, execMode = execMode)
        // --reinstall: apt re-downloads even when its status db claims the
        // package is installed. Fresh bootstraps can ship gutted files with
        // a stale "installed" status (python's dangling symlinks); without
        // this flag apt fetches nothing and install wrongly fails.
        val download = downloadDebs(def, onProgress, env, reinstall = true)
        download
            .mapCatching { finishDownload(def, onProgress, env) }
            .onSuccess {
                installer.patchExisting()
                invalidateVersion(def.id)
                done(Result.success(Unit))
            }
            .onFailure { done(Result.failure(it)) }
    }

    /** Uninstall: remove the runtime binaries so [isInstalled] flips off. */
    fun uninstall(id: String, done: (Result<Unit>) -> Unit) {
        val def = byId(id)
        val result = runCatching {
            // Prefer apt remove when dpkg knows the package; fall back to binary deletion.
            val aptResult = shell.execute(
                File(prefix, "bin/apt").absolutePath,
                listOf("remove", "-y", def.packageName),
                cwd.absolutePath,
                env,
                300_000,
            )
            if (aptResult.isFailure) {
                removeById(def)
            }
        }
        result.onSuccess {
            invalidateVersion(def.id)
            done(Result.success(Unit))
        }
            .onFailure { done(Result.failure(it)) }
    }

    fun update(
        id: String,
        onProgress: (String) -> Unit,
        done: (Result<Unit>) -> Unit,
        execMode: String = BuildConfig.DEFAULT_EXEC_MODE,
    ) {
        // User-initiated install: (re)start keep-alive (see TerminalManager).
        try {
            IdeService.start(context)
        } catch (_: Exception) {
        }
        val def = byId(id)
        val env = EnvironmentManager.buildEnvironment(context, execMode = execMode)
        // Plain fetch: succeeds with zero debs when already at newest
        // version (finishDownload short-circuits to success then).
        val download = downloadDebs(def, onProgress, env, reinstall = false)
        download
            .mapCatching { finishDownload(def, onProgress, env) }
            .onSuccess {
                installer.patchExisting()
                invalidateVersion(def.id)
                done(Result.success(Unit))
            }
            .onFailure { done(Result.failure(it)) }
    }

    /**
     * apt update + download-only fetch of a package. With [reinstall], apt
     * re-downloads the .deb even when its status db claims the package is
     * installed (repairs bootstraps that ship gutted files with a stale
     * "installed" status, e.g. python's dangling symlinks).
     */
    private fun downloadDebs(
        def: RuntimeDefinition,
        onProgress: (String) -> Unit,
        env: Map<String, String>,
        reinstall: Boolean,
    ): Result<Unit> {
        onProgress("apt update")
        runCatching {
            shell.execute(File(prefix, "bin/apt").absolutePath, listOf("update"), cwd.absolutePath, env, 120_000)
        }
        onProgress("apt download ${def.packageName}")
        clearArchives()
        return runCatching {
            val args = mutableListOf("install", "--download-only", "-y", "--no-install-recommends")
            if (reinstall) args.add("--reinstall")
            args.add(def.packageName)
            args.addAll(def.extraPackages)
            shell.execute(File(prefix, "bin/apt").absolutePath, args, cwd.absolutePath, env, 600_000)
            Unit
        }
    }

    /** Unpacks freshly downloaded debs, or succeeds when apt fetched nothing
     *  because the package is already installed and usable. */
    private fun finishDownload(
        def: RuntimeDefinition,
        onProgress: (String) -> Unit,
        env: Map<String, String>,
    ) {
        val debs = debsInArchives()
        android.util.Log.i(
            "NovaShell",
            "post-download v2: pkg=${def.packageName} debs=${debs.size} installed=${isInstalled(def)}",
        )
        if (debs.isEmpty()) {
            // apt fetched nothing: package already at newest version or repo
            // has nothing for us. Succeed when the binary is usable; fail
            // only when nothing is actually installed.
            if (!isInstalled(def)) {
                throw IllegalStateException("No .deb archives found after download. Check network / repository.")
            }
            onProgress("already installed ${def.packageName}")
        } else {
            unpacking(def, debs, onProgress, env)
        }
    }

    // ---------------------------------------------------------------------

    private fun clearArchives() {
        val dir = File(filesDir, "cache/apt/archives")
        if (dir.isDirectory) {
            dir.listFiles { f -> f.isFile && f.name.endsWith(".deb") }?.forEach { it.delete() }
        }
    }

    private fun debsInArchives(): List<File> {
        val dir = File(filesDir, "cache/apt/archives")
        if (!dir.isDirectory) return emptyList()
        return dir.listFiles { f -> f.isFile && f.name.endsWith(".deb") }
            ?.sortedBy { it.name }
            ?: emptyList()
    }

    /**
     * Unpack every .deb currently in the apt archive cache into the prefix.
     * Termux debs embed the full jail path; GNU tar's --transform rewrites the
     * known prefix layouts down to `usr/...` relative to filesDir (the parent
     * of `usr/`), so the exact component count never matters:
     *   legacy:  ./data/data/com.termux/files/usr/bin/git
     *   nova:    ./data/data/sd.adaa.codeide/files/usr/bin/git
     *   (a /data/user/0/... canonical variant for nova is covered too)
     * Paths that match none (e.g. already prefix-relative `./usr/...`) pass
     * through untouched and still land correctly.
     */
    private fun unpacking(
        def: RuntimeDefinition,
        debs: List<File>,
        onProgress: (String) -> Unit,
        env: Map<String, String>,
    ): Unit {
        if (debs.isEmpty()) {
            throw IllegalStateException("No .deb archives found after download. Check network / repository.")
        }
        val dpkgDeb = File(prefix, "bin/dpkg-deb").absolutePath
        val tar = File(prefix, "bin/tar").absolutePath
        // GNU tar --transform uses POSIX BRE: `(...)` is LITERAL, so the old
        // `(\./)?` groups never matched and every path passed through into a
        // nested files/data/... tree. Emit the optional `./` as explicit rules.
        val transform = "s#^\\./data/data/com\\.termux/files/usr/#usr/#;" +
            "s#^data/data/com\\.termux/files/usr/#usr/#;" +
            "s#^\\./data/user/0/sd\\.adaa\\.codeide/files/usr/#usr/#;" +
            "s#^data/user/0/sd\\.adaa\\.codeide/files/usr/#usr/#;" +
            "s#^\\./data/data/sd\\.adaa\\.codeide/files/usr/#usr/#;" +
            "s#^data/data/sd\\.adaa\\.codeide/files/usr/#usr/#"
        for (deb in debs) {
            onProgress("unpacking ${deb.name}")
            // Extract via dpkg-deb -> tar pipe in one go.
            val pipeCmd = "$dpkgDeb --fsys-tarfile '${deb.absolutePath}' | $tar -x --transform='$transform' -C '${filesDir.absolutePath}'"
            val res = shell.execute(
                File(prefix, "bin/bash").absolutePath,
                listOf("-c", pipeCmd),
                filesDir.absolutePath,
                env,
                300_000,
            )
            if (res.isFailure) {
                throw IllegalStateException("Extracting ${deb.name} failed: ${res.exceptionOrNull()?.message}")
            }
        }
        // openjdk debs ship the JDK under usr/lib/jvm/<name>/bin with no
        // usr/bin links (those are created by postinst update-alternatives,
        // which never runs for manual unpacks). Link them so bin/java etc.
        // exist and `isInstalled("java")` flips on.
        if (def.id == "java") linkJvmBins()
    }

    private fun linkJvmBins() {
        val binDir = File(prefix, "bin")
        val jvmDir = File(prefix, "lib/jvm")
        val jvms = jvmDir.listFiles { f -> f.isDirectory }
            ?.sortedByDescending { it.name } ?: return
        for (jvm in jvms) {
            val jvmBin = File(jvm, "bin")
            val exes = jvmBin.listFiles { f -> f.isFile } ?: continue
            for (exe in exes) {
                val link = File(binDir, exe.name)
                if (link.exists()) continue
                runCatching {
                    java.nio.file.Files.createSymbolicLink(link.toPath(), exe.toPath())
                }
            }
        }
    }

    private fun removeById(def: RuntimeDefinition) {
        // Packs own no binaries: apt remove drops just the metapackage,
        // members stay (standard metapackage semantics).
        if (def.isPack) return
        for (name in (listOf(def.executable) + def.aliases).distinct()) {
            val bin = File(prefix, "bin/$name")
            if (bin.exists()) bin.delete()
        }
    }

    private fun byId(id: String): RuntimeDefinition =
        requireNotNull(RuntimeRegistry.get(id)) { "Unknown runtime: $id" }

    private fun toInfoFast(def: RuntimeDefinition): RuntimeInfo = RuntimeInfo(
        id = def.id,
        displayName = def.displayName,
        version = versionCache[def.id],
        installed = isInstalled(def),
        executable = def.executable,
        supported = def.supportedAbis.isEmpty() ||
            def.supportedAbis.contains(android.os.Build.SUPPORTED_ABIS.firstOrNull()),
    )

    private fun isInstalled(def: RuntimeDefinition): Boolean {
        // A pack counts as installed only when every member binary exists.
        if (def.isPack) {
            if (def.memberBins.isEmpty()) return false
            return def.memberBins.all { File(prefix, "bin/$it").exists() }
        }
        val binary = File(prefix, "bin/${def.executable}")
        return binary.exists()
    }

    private fun needsProbe(def: RuntimeDefinition): Boolean {
        if (def.isPack) return false
        if (!isInstalled(def)) return false
        val at = probedAt[def.id] ?: return true
        return System.currentTimeMillis() - at > VERSION_TTL_MS
    }

    private fun invalidateVersion(id: String) {
        versionCache.remove(id)
        probedAt.remove(id)
    }

    /**
     * Probes [defs] off the main thread (up to 4 concurrent execs) and emits
     * `runtimeVersionsRefreshed` when the cache is filled. Coalesces bursts:
     * while one refresh is in flight, further triggers just set [refreshAgain].
     */
    private fun refreshVersionsAsync(defs: List<RuntimeDefinition>) {
        synchronized(this) {
            if (refreshInFlight) {
                refreshAgain = true
                return
            }
            refreshInFlight = true
        }
        refreshCoordinator.execute {
            try {
                val futures = defs.map { def ->
                    versionProbes.submit<String?> { probeVersion(def) }
                }
                futures.forEachIndexed { index, future ->
                    val def = defs[index]
                    val version = runCatching {
                        future.get(VERSION_TIMEOUT_MS + 5_000, TimeUnit.MILLISECONDS)
                    }.getOrNull()
                    probedAt[def.id] = System.currentTimeMillis()
                    if (version != null) {
                        versionCache[def.id] = version
                    } else {
                        versionCache.remove(def.id)
                    }
                }
                IdeEvents.emit(mapOf("event" to "runtimeVersionsRefreshed"))
            } catch (_: Exception) {
            } finally {
                val again = synchronized(this) {
                    refreshInFlight = false
                    val a = refreshAgain
                    refreshAgain = false
                    a
                }
                if (again) {
                    val stale = RuntimeRegistry.all.filter { needsProbe(it) }
                    if (stale.isNotEmpty()) refreshVersionsAsync(stale)
                }
            }
        }
    }

    /** Blocking single probe; runs only on [versionProbes] threads. */
    private fun probeVersion(def: RuntimeDefinition): String? {
        // Packs have no single version; the tile shows member state instead.
        if (def.isPack) return null
        val executable = File(prefix, "bin/${def.executable}")
        if (!executable.exists()) return null
        val output = runCatching {
            shell.execute(executable.absolutePath, def.versionArgs, cwd.absolutePath, env, VERSION_TIMEOUT_MS)
                .getOrNull()
        }.getOrNull() ?: return null
        return output.lineSequence().firstOrNull { it.isNotBlank() }?.trim()
    }
}