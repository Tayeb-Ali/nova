package sd.adaa.codeide.terminal

import sd.adaa.codeide.IdeCore
import sd.adaa.codeide.bridge.TerminalApi

/** Pigeon TerminalApi wiring (task.md §11) — delegates to the service-owned manager. */
object TerminalApiImpl : TerminalApi {

    override fun createSession(cwd: String, cols: Long, rows: Long): String =
        IdeCore.terminal.createSession(cwd, cols.toInt(), rows.toInt())

    override fun write(sessionId: String, data: String) {
        IdeCore.terminal.write(sessionId, data)
    }

    override fun resize(sessionId: String, cols: Long, rows: Long) {
        IdeCore.terminal.resize(sessionId, cols.toInt(), rows.toInt())
    }

    override fun close(sessionId: String) {
        IdeCore.terminal.close(sessionId)
    }

    override fun sendSignal(sessionId: String, signal: String) {
        IdeCore.terminal.sendSignal(sessionId, signal)
    }
}