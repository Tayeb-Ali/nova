package sd.adaa.nova

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Execution bridge that runs code via the Termux RUN_COMMAND API.
 *
 * Dart side talks to this object over the MethodChannel "sd.adaa.codeide/run":
 * - isTermuxInstalled -> Bool
 * - checkInterpreter(bin) -> Bool (optimistic, see below)
 * - runCode(path, args, workdir, stdin, requestId) -> Bool (dispatch ack;
 *   the real result arrives later via invokeMethod("onRunResult", {...})).
 *
 * Results come back through a PendingIntent broadcast
 * (action [ACTION_RUN_RESULT]) which [resultReceiver] forwards to Dart with
 * the originating requestId so concurrent runs can be correlated.
 */
object TermuxBridge {

    const val CHANNEL_NAME = "sd.adaa.codeide/run"

    const val TERMUX_PACKAGE = "com.termux"
    private const val RUN_COMMAND_SERVICE = "com.termux.app.RunCommandService"

    // Intent contract for com.termux.app.RunCommandService.
    private const val ACTION_RUN_COMMAND = "com.termux.RUN_COMMAND"
    private const val EXTRA_COMMAND_PATH = "com.termux.RUN_COMMAND_PATH"
    private const val EXTRA_ARGUMENTS = "com.termux.RUN_COMMAND_ARGUMENTS"
    private const val EXTRA_WORKDIR = "com.termux.RUN_COMMAND_WORKDIR"
    private const val EXTRA_STDIN = "com.termux.RUN_COMMAND_STDIN"
    private const val EXTRA_BACKGROUND = "com.termux.RUN_COMMAND_BACKGROUND"
    private const val EXTRA_PENDING_INTENT = "com.termux.RUN_COMMAND_PENDING_INTENT"

    /** Action for our own result broadcast; the result PendingIntent targets this. */
    const val ACTION_RUN_RESULT = "sd.adaa.nova.TERMUX_RUN_RESULT"
    private const val EXTRA_REQUEST_ID = "sd.adaa.nova.EXTRA_REQUEST_ID"

    /** Absolute path of the Termux usr/bin dir, used to resolve interpreter names. */
    const val TERMUX_USR_BIN = "/data/data/com.termux/files/usr/bin"

    // Result bundle key used by the Termux Tasker/RUN_COMMAND plugin API.
    private const val RESULT_BUNDLE = "com.termux.app.extra_PLUGIN_RESULT_BUNDLE"

    private var channel: MethodChannel? = null
    private var receiverRegistered = false

    private val resultReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_RUN_RESULT) return
            val requestId = intent.getIntExtra(EXTRA_REQUEST_ID, -1)

            var stdout = ""
            var stderr = ""
            var exitCode = -1

            // Primary contract: plugin result bundle with stdout/stderr/exitCode.
            val bundle = intent.getBundleExtra(RESULT_BUNDLE)
            if (bundle != null) {
                stdout = bundle.getString("stdout", "") ?: ""
                stderr = bundle.getString("stderr", "") ?: ""
                exitCode = bundle.getInt("exitCode", -1)
            }
            // Fallbacks: some versions/devices flatten the result into extras.
            if (stdout.isEmpty()) {
                stdout = intent.getStringExtra("stdout")
                    ?: intent.getStringExtra("com.termux.RUN_COMMAND_RESULT_STDOUT")
                    ?: ""
            }
            if (stderr.isEmpty()) {
                stderr = intent.getStringExtra("stderr")
                    ?: intent.getStringExtra("com.termux.RUN_COMMAND_RESULT_STDERR")
                    ?: ""
            }
            if (exitCode == -1) {
                exitCode = intent.getIntExtra(
                    "exitCode",
                    intent.getIntExtra("com.termux.RUN_COMMAND_RESULT_EXIT_CODE", -1)
                )
            }

            val payload = mapOf(
                "requestId" to requestId,
                "stdout" to stdout,
                "stderr" to stderr,
                "exitCode" to exitCode
            )
            Handler(Looper.getMainLooper()).post {
                try {
                    channel?.invokeMethod("onRunResult", payload)
                } catch (e: Exception) {
                    // Channel detached (engine destroyed); nothing to forward to.
                }
            }
        }
    }

    /**
     * Wire the MethodChannel and the result receiver.
     * Called from MainActivity.configureFlutterEngine. Returns the channel.
     */
    fun configure(engine: FlutterEngine, context: Context): MethodChannel {
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel = ch
        val appContext = context.applicationContext
        ch.setMethodCallHandler { call, result -> handleCall(appContext, call, result) }
        registerReceiverOnce(appContext)
        return ch
    }

    /** Unregister the receiver and detach the channel. Called from onDestroy. */
    fun teardown(context: Context) {
        if (receiverRegistered) {
            try {
                context.applicationContext.unregisterReceiver(resultReceiver)
            } catch (e: Exception) {
                // Already unregistered; ignore.
            }
            receiverRegistered = false
        }
        channel?.setMethodCallHandler(null)
        channel = null
    }

    private fun registerReceiverOnce(context: Context) {
        if (receiverRegistered) return
        val filter = IntentFilter(ACTION_RUN_RESULT)
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                context.registerReceiver(resultReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                context.registerReceiver(resultReceiver, filter)
            }
            receiverRegistered = true
        } catch (e: Exception) {
            receiverRegistered = false
        }
    }

    private fun handleCall(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isTermuxInstalled" -> result.success(isTermuxInstalled(context))
            "checkInterpreter" -> {
                val bin: String = call.argument<String>("bin") ?: ""
                result.success(checkInterpreter(context, bin))
            }
            "runCode" -> {
                val path: String = call.argument<String>("path") ?: ""
                @Suppress("UNCHECKED_CAST")
                val args: List<String> =
                    call.argument<List<*>>("args")?.map { it.toString() } ?: emptyList()
                val workdir: String? = call.argument<String>("workdir")
                val stdin: String? = call.argument<String>("stdin")
                val requestId: Int =
                    call.argument<Number>("requestId")?.toInt() ?: 0
                try {
                    runCode(context, path, args, workdir, stdin, requestId)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("DISPATCH_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun isTermuxInstalled(context: Context): Boolean {
        return try {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(TERMUX_PACKAGE, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    /**
     * Best-effort interpreter probe.
     *
     * LIMITATION: the RUN_COMMAND API is fire-and-forget with an async result,
     * so a synchronous boolean cannot reflect the real probe outcome without
     * blocking. This fires `sh -c "command -v <bin>"` in the background and
     * returns true optimistically whenever Termux itself is installed.
     * Callers that need certainty should run a real snippet and inspect the
     * exit code / stderr instead.
     */
    fun checkInterpreter(context: Context, bin: String): Boolean {
        if (!bin.matches(Regex("[A-Za-z0-9._-]+"))) return false
        if (!isTermuxInstalled(context)) return false
        return try {
            val intent = Intent(ACTION_RUN_COMMAND)
            intent.setClassName(TERMUX_PACKAGE, RUN_COMMAND_SERVICE)
            intent.putExtra(EXTRA_COMMAND_PATH, "$TERMUX_USR_BIN/sh")
            intent.putExtra(EXTRA_ARGUMENTS, arrayOf("-c", "command -v $bin"))
            intent.putExtra(EXTRA_BACKGROUND, true)
            startRunCommandService(context, intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun runCode(
        context: Context,
        path: String,
        args: List<String>,
        workdir: String?,
        stdin: String?,
        requestId: Int
    ) {
        require(path.isNotBlank()) { "path must not be blank" }
        val intent = Intent(ACTION_RUN_COMMAND)
        intent.setClassName(TERMUX_PACKAGE, RUN_COMMAND_SERVICE)
        intent.putExtra(EXTRA_COMMAND_PATH, path)
        intent.putExtra(EXTRA_ARGUMENTS, args.toTypedArray())
        if (!workdir.isNullOrBlank()) intent.putExtra(EXTRA_WORKDIR, workdir)
        if (!stdin.isNullOrEmpty()) intent.putExtra(EXTRA_STDIN, stdin)
        intent.putExtra(EXTRA_BACKGROUND, true)

        val resultIntent = Intent(ACTION_RUN_RESULT)
        resultIntent.setPackage(context.packageName)
        resultIntent.putExtra(EXTRA_REQUEST_ID, requestId)
        var flags = PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        val pending = PendingIntent.getBroadcast(context, requestId, resultIntent, flags)
        intent.putExtra(EXTRA_PENDING_INTENT, pending)

        startRunCommandService(context, intent)
    }

    private fun startRunCommandService(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }
}
