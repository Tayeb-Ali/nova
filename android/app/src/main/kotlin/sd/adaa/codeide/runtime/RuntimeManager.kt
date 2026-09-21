package sd.adaa.codeide.runtime

import android.content.Context
import sd.adaa.codeide.EnvironmentManager
import sd.adaa.codeide.bridge.RuntimeInfo
import sd.adaa.codeide.process.ShellExecutor
import java.io.File

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

    fun getRuntimes(): List<RuntimeInfo> = RuntimeRegistry.all.map { toInfo(it) }

    fun getRuntime(id: String): RuntimeInfo {
        val def = byId(id)
        return toInfo(def)
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
        execMode: String = EnvironmentManager.EXEC_MODE_DIRECT,
    ) {
        val def = byId(id)
        val env = EnvironmentManager.buildEnvironment(context, execMode = execMode)
        onProgress("apt update")
        runCatching {
            shell.execute(File(prefix, "bin/apt").absolutePath, listOf("update"), cwd.absolutePath, env, 120_000)
        }
        onProgress("apt download ${def.packageName}")
        clearArchives()
        val download = runCatching {
            shell.execute(
                File(prefix, "bin/apt").absolutePath,
                listOf("install", "--download-only", "-y", "--no-install-recommends", def.packageName),
                cwd.absolutePath,
                env,
                600_000,
            )
        }
        download
            .mapCatching { unpacking(debsInArchives(), onProgress) }
            .onSuccess {
                installer.patchExisting()
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
        result.onSuccess { done(Result.success(Unit)) }
            .onFailure { done(Result.failure(it)) }
    }

    fun update(
        id: String,
        onProgress: (String) -> Unit,
        done: (Result<Unit>) -> Unit,
        execMode: String = EnvironmentManager.EXEC_MODE_DIRECT,
    ) {
        val def = byId(id)
        val env = EnvironmentManager.buildEnvironment(context, execMode = execMode)
        onProgress("apt update")
        runCatching {
            shell.execute(File(prefix, "bin/apt").absolutePath, listOf("update"), cwd.absolutePath, env, 120_000)
        }
        onProgress("apt download ${def.packageName}")
        clearArchives()
        val download = runCatching {
            shell.execute(
                File(prefix, "bin/apt").absolutePath,
                listOf("install", "--download-only", "-y", "--no-install-recommends", def.packageName),
                cwd.absolutePath,
                env,
                600_000,
            )
        }
        download
            .mapCatching { unpacking(debsInArchives(), onProgress) }
            .onSuccess {
                installer.patchExisting()
                done(Result.success(Unit))
            }
            .onFailure { done(Result.failure(it)) }
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
     * Termux .deb data paths start `./data/data/com.termux/files/usr/...`;
     * GNU tar counts `./` as leading component, so --strip-components=5 turns
     * `./data/data/com.termux/files/usr/bin/git` into `bin/git` relative to
     * filesDir (which holds `usr/`), i.e. it lands at `files/usr/bin/git`.
     */
    private fun unpacking(debs: List<File>, onProgress: (String) -> Unit): Unit {
        if (debs.isEmpty()) {
            throw IllegalStateException("No .deb archives found after download. Check network / repository.")
        }
        val dpkgDeb = File(prefix, "bin/dpkg-deb").absolutePath
        val tar = File(prefix, "bin/tar").absolutePath
        for (deb in debs) {
            onProgress("unpacking ${deb.name}")
            // Extract via dpkg-deb -> tar pipe in one go.
            val pipeCmd = "$dpkgDeb --fsys-tarfile '${deb.absolutePath}' | $tar -x --strip-components=5 -C '${filesDir.absolutePath}'"
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
    }

    private fun removeById(def: RuntimeDefinition) {
        for (name in (listOf(def.executable) + def.aliases).distinct()) {
            val bin = File(prefix, "bin/$name")
            if (bin.exists()) bin.delete()
        }
    }

    private fun byId(id: String): RuntimeDefinition =
        requireNotNull(RuntimeRegistry.get(id)) { "Unknown runtime: $id" }

    private fun toInfo(def: RuntimeDefinition): RuntimeInfo = RuntimeInfo(
        id = def.id,
        displayName = def.displayName,
        version = queryVersion(def),
        installed = isInstalled(def),
        executable = def.executable,
    )

    private fun isInstalled(def: RuntimeDefinition): Boolean {
        val binary = File(prefix, "bin/${def.executable}")
        return binary.exists()
    }

    private fun queryVersion(def: RuntimeDefinition): String? {
        val executable = File(prefix, "bin/${def.executable}")
        if (!executable.exists()) return null
        val output = runCatching {
            shell.execute(executable.absolutePath, listOf("--version"), cwd.absolutePath, env, 60_000)
                .getOrNull()
        }.getOrNull() ?: return null
        return output.lineSequence().firstOrNull { it.isNotBlank() }?.trim()
    }
}