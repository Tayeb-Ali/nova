package sd.adaa.codeide.process

import android.content.Context
import sd.adaa.codeide.EnvironmentManager
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Runs host-side commands inside the embedded environment
 * (PREFIX env, PATH -> prefix/bin, termux-exec preload).
 * All runtime script execution routes through here (task.md §13 §24).
 */
class ShellExecutor(private val context: Context) {

    fun buildProcess(command: String, args: List<String>, cwd: String?, env: Map<String, String>): ProcessBuilder {
        val pb = ProcessBuilder(listOf(command) + args)
        cwd?.takeIf { File(it).isDirectory }?.let { pb.directory(File(it)) }
        pb.environment().putAll(EnvironmentManager.buildEnvironment(context))
        pb.environment().putAll(env)
        // First-hop policy lives in NovaExecLauncher: rewrite the first hop
        // through the system linker when opted in. Default is direct (no change).
        val mode = pb.environment()[EnvironmentManager.ENV_EXEC_MODE]
            ?: EnvironmentManager.EXEC_MODE_DIRECT
        val hop = NovaExecLauncher.buildLinkerArgv(
            command, args,
            EnvironmentManager.prefix(context).absolutePath,
            mode,
            scopeRoot = EnvironmentManager.filesDir(context).absolutePath,
        )
        if (hop.command != command || hop.args != args) {
            return ProcessBuilder(listOf(hop.command) + hop.args).also {
                it.directory(pb.directory())
                it.environment().putAll(pb.environment())
                it.redirectErrorStream(true)
            }
        }
        pb.redirectErrorStream(true)
        return pb
    }

    /** Synchronous run; returns (merged stdout+stderr) or a failure. */
    fun execute(
        command: String,
        args: List<String> = emptyList(),
        cwd: String? = null,
        env: Map<String, String> = emptyMap(),
        timeoutMs: Long = 600_000,
    ): Result<String> {
        return runCatching {
            val pb = buildProcess(command, args, cwd, env)
            val p = pb.start()
            val output = p.inputStream.bufferedReader().use { it.readText() }
            if (!p.waitFor(timeoutMs, TimeUnit.MILLISECONDS)) {
                p.destroyForcibly()
                error("Command timed out: $command ${args.joinToString(" ")}".trim())
            }
            if (p.exitValue() != 0) {
                error(output.ifBlank { "Command failed: $command" })
            }
            output
        }
    }

/**
 * Central first-hop exec policy (Phase 0 linker-exec spike).
 *
 * `LD_PRELOAD` only covers grandchildren: the very first exec from the app
 * process (Java `ProcessBuilder` / pty `execve`) bypasses interception, so in
 * linker mode the first hop must name `/system/bin/linker64` explicitly and
 * pass the real target as its argument. Pure logic (no Android APIs) so the
 * rules stay reviewable in one place. Default mode is direct (pass-through).
 *
 * Rules (linker mode only; everything else passes through untouched):
 * - non-absolute commands and anything outside the prefix: untouched
 *   (system binaries must never be rewritten).
 * - ELF (`\x7fELF` magic): `[linker64, target] + args`.
 * - script (`#!` magic): `[linker64, interpreter, script] + args`, with
 *   `/usr/bin/env NAME` and `/bin|/usr/bin/` interpreters resolved into the
 *   prefix (mirrors the shebang extraction the preload interceptor performs
 *   for deeper hops).
 */
object NovaExecLauncher {
    data class FirstHop(val command: String, val args: List<String>)

    /** Mode gate: only linker mode rewrites the first hop; default is direct. */
    fun shouldUseSystemLinker(mode: String): Boolean =
        mode == EnvironmentManager.EXEC_MODE_LINKER

    /** Rewrites the first hop through the system linker when opted in.
     *
     * @param scopeRoot sandbox root allowed for rewriting (the app data dir:
     *   prefix binaries AND user scripts under home/projects). Interpreters
     *   still resolve into [prefixPath].
     */
    fun buildLinkerArgv(
        command: String,
        args: List<String>,
        prefixPath: String,
        mode: String,
        linkerPath: String = EnvironmentManager.SYSTEM_LINKER,
        scopeRoot: String = prefixPath,
    ): FirstHop {
        if (!shouldUseSystemLinker(mode)) return FirstHop(command, args)
        if (!command.startsWith("/")) return FirstHop(command, args)
        val prefixRoot = prefixPath.trimEnd('/') + "/"
        val scope = scopeRoot.trimEnd('/') + "/"
        if (!command.startsWith(scope)) return FirstHop(command, args)
        val magic = readMagic(command) ?: return FirstHop(command, args)
        if (isElf(magic)) return FirstHop(linkerPath, listOf(command) + args)
        if (isScript(magic)) {
            val interp = resolveInterpreter(magic, prefixRoot) ?: return FirstHop(command, args)
            return FirstHop(linkerPath, listOf(interp, command) + args)
        }
        return FirstHop(command, args)
    }

    /** Legacy alias of [buildLinkerArgv]; prefer [buildLinkerArgv] for new code. */
    fun resolve(
        command: String,
        args: List<String>,
        prefixPath: String,
        mode: String,
        linkerPath: String = EnvironmentManager.SYSTEM_LINKER,
        scopeRoot: String = prefixPath,
    ): FirstHop = buildLinkerArgv(command, args, prefixPath, mode, linkerPath, scopeRoot)

    private fun readMagic(path: String): ByteArray? {
        return try {
            val f = File(path)
            if (!f.isFile) return null
            val buf = ByteArray(512)
            f.inputStream().use { stream ->
                var off = 0
                while (off < buf.size) {
                    val n = stream.read(buf, off, buf.size - off)
                    if (n <= 0) break
                    off += n
                }
                if (off == 0) return null
                buf.copyOf(off)
            }
        } catch (_: Exception) {
            null
        }
    }

    fun isElf(magic: ByteArray): Boolean =
        magic.size >= 4 &&
            magic[0] == 0x7f.toByte() &&
            magic[1] == 'E'.code.toByte() &&
            magic[2] == 'L'.code.toByte() &&
            magic[3] == 'F'.code.toByte()

    fun isScript(magic: ByteArray): Boolean =
        magic.size >= 2 &&
            magic[0] == '#'.code.toByte() &&
            magic[1] == '!'.code.toByte()

    fun resolveInterpreter(magic: ByteArray, prefixRoot: String): String? {
        val line = magic.toString(Charsets.UTF_8)
            .lineSequence().firstOrNull()
            ?.removePrefix("#!")?.trim()
            ?: return null
        // Strip VAR=value assignments (e.g. `#!/usr/bin/env -S VAR=1 name` keeps it simple:
        // find a `name` token after `/usr/bin/env`).
        val parts = line.split(Regex("\\s+")).filter { it.isNotEmpty() && !it.contains('=') }
        if (parts.isEmpty()) return null
        val bin = prefixRoot.trimEnd('/') + "/bin/"
        val envIdx = parts.indexOf("/usr/bin/env")
        if (envIdx >= 0) {
            val name = parts.drop(envIdx + 1).firstOrNull { !it.startsWith("-") } ?: return null
            return bin + name.substringAfterLast('/')
        }
        val first = parts[0]
        if (first.startsWith("/bin/") || first.startsWith("/usr/bin/")) {
            return bin + first.substringAfterLast('/')
        }
        if (first.startsWith("/")) return first
        // Bare interpreter name (`#!python3`): resolve into the prefix.
        if (!first.contains('/')) return bin + first
        return null
    }
}

    /** Async run streaming output lines; caller manages the returned Process. */
    fun executeAsync(
        command: String,
        args: List<String> = emptyList(),
        cwd: String? = null,
        env: Map<String, String> = emptyMap(),
        onOutput: (String) -> Unit,
        onExit: (Int) -> Unit,
    ): Process {
        val pb = buildProcess(command, args, cwd, env)
        val p = pb.start()
        Thread {
            p.inputStream.bufferedReader().useLines { lines ->
                lines.forEach { onOutput("$it\n") }
            }
            onExit(p.waitFor())
        }.start()
        return p
    }
}