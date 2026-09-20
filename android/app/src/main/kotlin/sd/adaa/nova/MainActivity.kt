package sd.adaa.nova

import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        IdeCore.init(applicationContext)
        AllApis.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
        IdeService.start(this)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Debug: trigger setup via `adb shell am broadcast -a sd.adaa.nova.DEBUG_SETUP -n sd.adaa.nova/.MainActivity`
        val filter = IntentFilter("sd.adaa.nova.DEBUG_SETUP")
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

        // Debug: comprehensive in-app test — Node/Python/Terminal via `adb shell am broadcast -a sd.adaa.nova.DEBUG_COMPREHENSIVE_TEST -n sd.adaa.nova/.MainActivity`
        val testFilter = IntentFilter("sd.adaa.nova.DEBUG_COMPREHENSIVE_TEST")
        registerReceiver(object : BroadcastReceiver() {
            override fun onReceive(ctx: android.content.Context, intent: Intent?) {
                Log.i("NovaTest", "DEBUG_COMPREHENSIVE_TEST received")
                DebugTestHarness.run(ctx)
            }
        }, testFilter, RECEIVER_EXPORTED)

        // Debug: exercise the UI's exact runtime install path (progress events
        // flow Kotlin -> IdeEvents -> events channel -> Dart bus).
        // `adb shell am broadcast -a sd.adaa.nova.DEBUG_INSTALL_RUNTIME --es id git -n sd.adaa.nova/.MainActivity`
        val installFilter = IntentFilter("sd.adaa.nova.DEBUG_INSTALL_RUNTIME")
        registerReceiver(object : BroadcastReceiver() {
            override fun onReceive(ctx: android.content.Context, intent: Intent?) {
                val id = intent?.getStringExtra("id") ?: "git"
                Log.i("NovaTest", "DEBUG_INSTALL_RUNTIME received: $id")
                sd.adaa.nova.runtime.RuntimeApiImpl.installRuntime(id)
            }
        }, installFilter, RECEIVER_EXPORTED)
    }
}