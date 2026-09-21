package sd.adaa.codeide

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        IdeCore.init(applicationContext)
        AllApis.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
        // Never let FGS startup crash the activity: on targetSdk 34+ a
        // background launch (adb, boot, some OEM paths) throws
        // ForegroundServiceStartNotAllowedException here. The service is
        // best-effort keep-alive; terminals/processes still work, and the
        // service is (re)started on user-initiated session creation.
        try {
            IdeService.start(this)
        } catch (e: Exception) {
            Log.w("IdeService", "deferred foreground start: ${e.message}")
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.extras?.keySet()?.takeIf { it.isNotEmpty() }?.let {
            Log.i("NovaTest", "onCreate extras=" + it.joinToString())
        }
        ensureNotificationPermission()
        checkLinkerProbeIntent(intent)
        // Debug receivers (arbitrary setup/install triggers): debug builds
        // only. Release/play builds must never export them.
        if (BuildConfig.DEBUG) {
        // Debug: trigger setup via `adb shell am broadcast -a sd.adaa.codeide.DEBUG_SETUP -n sd.adaa.codeide/.MainActivity`
        val filter = IntentFilter("sd.adaa.codeide.DEBUG_SETUP")
        registerReceiver(object : BroadcastReceiver() {
            override fun onReceive(ctx: android.content.Context, intent: Intent?) {
                Log.i("NovaDebug", "DEBUG_SETUP received, starting bootstrap...")
                IdeCore.bootstrap.start(
                    onProgress = { phase, frac -> Log.i("NovaDebug", "Progress: $phase $frac") },
                    done = { result ->
                        result.fold(
                            onSuccess = { Log.i("NovaDebug", "Bootstrap DONE OK") },
                            onFailure = { Log.e("NovaDebug", "Bootstrap FAILED: ${it.message}") }
                        )
                    }
                )
            }
        }, filter, RECEIVER_EXPORTED)

        // Debug: comprehensive in-app test � Node/Python/Terminal via `adb shell am broadcast -a sd.adaa.codeide.DEBUG_COMPREHENSIVE_TEST -n sd.adaa.codeide/.MainActivity`
        val testFilter = IntentFilter("sd.adaa.codeide.DEBUG_COMPREHENSIVE_TEST")
        registerReceiver(object : BroadcastReceiver() {
            override fun onReceive(ctx: android.content.Context, intent: Intent?) {
                Log.i("NovaTest", "DEBUG_COMPREHENSIVE_TEST received")
                DebugTestHarness.run(ctx)
            }
        }, testFilter, RECEIVER_EXPORTED)

        // Debug: exercise the UI's exact runtime install path (progress events
        // flow Kotlin -> IdeEvents -> events channel -> Dart bus).
        // `adb shell am broadcast -a sd.adaa.codeide.DEBUG_INSTALL_RUNTIME --es id git -n sd.adaa.codeide/.MainActivity`
        val installFilter = IntentFilter("sd.adaa.codeide.DEBUG_INSTALL_RUNTIME")
        registerReceiver(object : BroadcastReceiver() {
            override fun onReceive(ctx: android.content.Context, intent: Intent?) {
                val id = intent?.getStringExtra("id") ?: "git"
                Log.i("NovaTest", "DEBUG_INSTALL_RUNTIME received: $id")
                sd.adaa.codeide.runtime.RuntimeApiImpl.installRuntime(id)
            }
        }, installFilter, RECEIVER_EXPORTED)

        // Phase 0 linker-exec spike probe (debug only; stripped in the Play
        // flavor later): forces NOVA_EXEC_MODE=linker with targetSdk still 28.
        // `adb shell am broadcast -a sd.adaa.codeide.DEBUG_LINKER_PROBE -n sd.adaa.codeide/.MainActivity`
        val probeFilter = IntentFilter("sd.adaa.codeide.DEBUG_LINKER_PROBE")
        registerReceiver(object : BroadcastReceiver() {
            override fun onReceive(ctx: android.content.Context, intent: Intent?) {
                Log.i("NovaTest", "DEBUG_LINKER_PROBE received")
                DebugTestHarness.runLinkerProbe(ctx)
            }
        }, probeFilter, RECEIVER_EXPORTED)
        } // if (BuildConfig.DEBUG)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        checkLinkerProbeIntent(intent)
    }

    /**
     * Deterministic Phase-0 probe trigger (broadcasts are unreliable on some
     * OEM skins when the app is backgrounded):
     * `adb shell am start -n sd.adaa.codeide/.MainActivity --es nova_linker_probe true`
     */
    private fun checkLinkerProbeIntent(intent: Intent?) {
        if (!BuildConfig.DEBUG) return
        if (intent?.getStringExtra("nova_probe") == "full") {
            Log.i("NovaTest", "full matrix requested via start intent")
            DebugTestHarness.runFullProbe(this)
            return
        }
        if (intent?.getBooleanExtra("nova_linker_probe", false) == true) {
            Log.i("NovaTest", "linker probe requested via start intent")
            DebugTestHarness.runLinkerProbe(this)
        }
    }

    private fun ensureNotificationPermission() {
        // Android 13+ (targetSdk 33+): notification permission is runtime.
        // While targetSdk stays 28 the system pre-grants it, so this only
        // starts showing a dialog once the SDK target is raised — keeping the
        // app Google Play compliant either way. Consent is optional: the app
        // still works without notifications, so we never gate on the result.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST,
            )
        }
    }
}