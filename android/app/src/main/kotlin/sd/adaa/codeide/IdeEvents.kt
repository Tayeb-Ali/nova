package sd.adaa.codeide

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * One shared Kotlin -> Flutter event sink (task.md §28).
 * TerminalManager/ProcessManager emit here from worker threads, so every
 * emission is marshalled onto the main thread — Flutter's EventChannel
 * requires @UiThread.
 */
object IdeEvents {
    @Volatile
    var sink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    fun emit(event: Map<String, Any?>) {
        mainHandler.post { sink?.success(event) }
    }

    fun emitError(code: String, message: String, details: Any?) {
        mainHandler.post { sink?.error(code, message, details) }
    }
}