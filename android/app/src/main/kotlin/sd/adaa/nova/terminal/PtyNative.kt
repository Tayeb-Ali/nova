package sd.adaa.nova.terminal

/**
 * JNI wrapper for the forkpty shim in src/main/cpp/pty.c.
 * Native reader thread posts [ByteArray] chunks / exit codes here so output
 * batching happens Kotlin-side (task.md §8-§10).
 */
object PtyNative {

    init {
        System.loadLibrary("pty")
    }

    interface PtyCallback {
        fun onData(data: ByteArray)
        fun onExit(exitCode: Int)
    }

    external fun nativeOpen(
        exe: String,
        argv: Array<String>,
        envp: Array<String>,
        cwd: String?,
        cols: Int,
        rows: Int,
    ): Long

    external fun nativeWrite(handle: Long, data: ByteArray): Int

    external fun nativeResize(handle: Long, cols: Int, rows: Int): Int

    external fun nativeSignal(handle: Long, signal: Int)

    external fun nativeClose(handle: Long)

    external fun nativeStartReader(handle: Long, callback: PtyCallback)
}