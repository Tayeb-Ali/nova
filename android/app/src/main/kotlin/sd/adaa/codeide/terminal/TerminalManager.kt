package sd.adaa.codeide.terminal

import android.content.Context
import android.util.Base64
import sd.adaa.codeide.BuildConfig
import sd.adaa.codeide.EnvironmentManager
import sd.adaa.codeide.IdeEvents
import sd.adaa.codeide.IdeService
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Interactive PTY shell sessions (task.md §8-§10).
 * Output is accumulated Kotlin-side and flushed every ~16ms as base64 chunks
 * over the shared event stream, never per-byte.
 */
class TerminalManager(private val context: Context) {

    private class SessionHandle(
        val id: String,
        val handle: Long,
    ) {
        val buffer = ByteArrayOutputStream()
    }

    private val sessions = ConcurrentHashMap<String, SessionHandle>()
    private val flusherStarted = AtomicBoolean(false)

    private val bashPath: String
        get() = "${EnvironmentManager.prefix(context).absolutePath}/bin/bash"

    init {
        ensureFlusher()
    }

    // Default follows the flavor (github=direct, play=linker): the UI bridge
    // calls without a mode, so THIS default is the production terminal path.
    fun createSession(cwd: String, cols: Int, rows: Int, execMode: String = BuildConfig.DEFAULT_EXEC_MODE): String {
        // Production FGS policy (target 34+): engine-init start can be denied
        // on background launches, so (re)start keep-alive here — an explicit
        // user action, which exempts the foreground-service start.
        try {
            IdeService.start(context)
        } catch (_: Exception) {
        }
        val id = UUID.randomUUID().toString()
        val workDir =
            if (File(cwd).isDirectory) cwd else EnvironmentManager.home(context).absolutePath
        val envp = EnvironmentManager.buildEnvironment(context, execMode = execMode)
            .map { "${it.key}=${it.value}" }
            .toTypedArray()
        val handle = PtyNative.nativeOpen(bashPath, arrayOf(bashPath), envp, workDir, cols, rows)
        // NOTE: the handle is an opaque native pointer, NOT a small int.
        // On modern devices the pointer's high bit is routinely set, so it
        // reads negative as a signed Long. Only -1 (forkpty failure from the
        // JNI shim) is an error; any other bit pattern round-trips back to
        // native intact.
        if (handle == -1L) error("Failed to open PTY for $bashPath")

        val session = SessionHandle(id, handle)
        sessions[id] = session

        PtyNative.nativeStartReader(handle, object : PtyNative.PtyCallback {
            override fun onData(data: ByteArray) {
                synchronized(session.buffer) {
                    session.buffer.write(data)
                }
            }

            override fun onExit(exitCode: Int) {
                flush(session)
                sessions.remove(id)
                IdeEvents.emit(
                    mapOf(
                        "event" to "terminalExit",
                        "sessionId" to id,
                        "exitCode" to exitCode,
                    )
                )
            }
        })
        return id
    }

    fun write(sessionId: String, data: String) {
        sessions[sessionId]?.let {
            PtyNative.nativeWrite(it.handle, data.toByteArray(Charsets.UTF_8))
        }
    }

    fun resize(sessionId: String, cols: Int, rows: Int) {
        sessions[sessionId]?.let {
            PtyNative.nativeResize(it.handle, cols, rows)
        }
    }

    fun close(sessionId: String) {
        sessions.remove(sessionId)?.let {
            PtyNative.nativeClose(it.handle)
        }
    }

    fun sendSignal(sessionId: String, signal: String) {
        val sig = when (val s = signal.trim().uppercase()) {
            "SIGHUP", "HUP" -> 1
            "SIGINT", "INT" -> 2
            "SIGQUIT", "QUIT" -> 3
            "SIGKILL", "KILL" -> 9
            "SIGTERM", "TERM" -> 15
            else -> s.toIntOrNull() ?: 15
        }
        sessions[sessionId]?.let {
            PtyNative.nativeSignal(it.handle, sig)
        }
    }

    private fun ensureFlusher() {
        if (!flusherStarted.compareAndSet(false, true)) return
        Thread({
            while (true) {
                try {
                    Thread.sleep(16)
                } catch (ignored: InterruptedException) {
                    flusherStarted.set(false)
                    return@Thread
                }
                for (session in sessions.values) {
                    flush(session)
                }
            }
        }, "nova-terminal-flusher").apply {
            isDaemon = true
            start()
        }
    }

    private fun flush(session: SessionHandle) {
        val bytes: ByteArray = synchronized(session.buffer) {
            if (session.buffer.size() == 0) return
            val data = session.buffer.toByteArray()
            session.buffer.reset()
            data
        }
        IdeEvents.emit(
            mapOf(
                "event" to "terminalOutput",
                "sessionId" to session.id,
                "data" to Base64.encodeToString(bytes, Base64.NO_WRAP),
            )
        )
    }
}