package sd.adaa.nova.process

import android.content.Context
import sd.adaa.nova.IdeEvents
import sd.adaa.nova.bridge.ProcessInfo
import sd.adaa.nova.bridge.ProcessRequest
import sd.adaa.nova.webpreview.PortDetector
import java.io.ByteArrayOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Managed (non-PTY) background processes (task.md §21). Output is merged via
 * ShellExecutor, batched every ~16ms and scanned by PortDetector for a
 * server URL (task.md §22).
 */
class ProcessManager(private val context: Context) {

    private class ProcessHandle(
        val pid: String,
        val request: ProcessRequest,
        val process: Process,
    ) {
        val buffer = ByteArrayOutputStream()

        @Volatile
        var serverEmitted = false
    }

    private val shell by lazy { ShellExecutor(context) }
    private val processes = ConcurrentHashMap<String, ProcessHandle>()
    private val flusherStarted = AtomicBoolean(false)

    init {
        ensureFlusher()
    }

    fun start(request: ProcessRequest): ProcessInfo {
        val started = AtomicReference<ProcessHandle>()
        val pending = mutableListOf<String>()

        val process = shell.executeAsync(
            command = request.command,
            args = request.args,
            cwd = request.cwd,
            env = request.environment ?: emptyMap(),
            onOutput = { chunk ->
                val handle = started.get()
                if (handle != null) {
                    feed(handle, chunk)
                } else {
                    synchronized(pending) {
                        pending.add(chunk)
                    }
                }
            },
            onExit = { code ->
                val handle = started.get() ?: return@executeAsync
                flush(handle)
                processes.remove(handle.pid)
                IdeEvents.emit(
                    mapOf(
                        "event" to "processExit",
                        "pid" to handle.pid,
                        "exitCode" to code,
                    )
                )
            },
        )

        val pid = pidOf(process)
        val handle = ProcessHandle(pid, request, process)
        started.set(handle)
        processes[pid] = handle
        synchronized(pending) {
            pending.forEach { feed(handle, it) }
            pending.clear()
        }
        return ProcessInfo(
            pid = pid,
            command = request.command,
            cwd = request.cwd,
            status = "running",
        )
    }

    fun kill(pid: String) {
        processes.remove(pid)?.let { it.process.destroyForcibly() }
    }

    fun list(): List<ProcessInfo> = processes.values.map {
        ProcessInfo(
            pid = it.pid,
            command = it.request.command,
            cwd = it.request.cwd,
            status = "running",
        )
    }

    private fun feed(handle: ProcessHandle, chunk: String) {
        PortDetector.scan(chunk)
        if (!handle.serverEmitted && PortDetector.currentUrl != null) {
            handle.serverEmitted = true
            IdeEvents.emit(
                mapOf(
                    "event" to "serverDetected",
                    "url" to PortDetector.previewUrl(),
                )
            )
        }
        synchronized(handle.buffer) {
            handle.buffer.write(chunk.toByteArray(Charsets.UTF_8))
        }
    }

    private fun pidOf(process: Process): String {
        return try {
            val field = process.javaClass.getDeclaredField("pid")
            field.isAccessible = true
            (field.get(process) as? Number)?.toLong()?.toString()
        } catch (ignored: Throwable) {
            null
        } ?: System.identityHashCode(process).toString()
    }

    private fun ensureFlusher() {
        if (!flusherStarted.compareAndSet(false, true)) return
        Thread({
            while (true) {
                try {
                    Thread.sleep(16)
                } catch (ignored: InterruptedException) {
                    return@Thread
                }
                for (handle in processes.values) {
                    flush(handle)
                }
            }
        }, "nova-process-flusher").apply {
            isDaemon = true
            start()
        }
    }

    private fun flush(handle: ProcessHandle) {
        val text: String = synchronized(handle.buffer) {
            if (handle.buffer.size() == 0) return
            val data = handle.buffer.toByteArray()
            handle.buffer.reset()
            data.toString(Charsets.UTF_8)
        }
        IdeEvents.emit(
            mapOf(
                "event" to "processOutput",
                "pid" to handle.pid,
                "data" to text,
            )
        )
    }
}