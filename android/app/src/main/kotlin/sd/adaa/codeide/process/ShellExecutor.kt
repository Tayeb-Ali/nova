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