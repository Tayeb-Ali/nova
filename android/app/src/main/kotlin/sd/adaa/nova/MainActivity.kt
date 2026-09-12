package sd.adaa.nova

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Wire the Termux RUN_COMMAND bridge (channel "sd.adaa.codeide/run").
        TermuxBridge.configure(flutterEngine, this)
    }

    override fun onDestroy() {
        try {
            TermuxBridge.teardown(this)
        } catch (e: Exception) {
            // Best-effort receiver cleanup; ignore.
        }
        super.onDestroy()
    }
}
