package pl.leancode.patrol;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Release-only stub for the Patrol test plugin.
 *
 * `patrol` is a dev_dependency, so the real plugin classes exist only in
 * debug builds — but the (build-time generated) plugin registrant references
 * `new PatrolPlugin()` unconditionally, which breaks release javac with
 * "package pl.leancode.patrol does not exist".
 *
 * This no-op stub lives in the `release` source set, so it is compiled into
 * release builds only: debug keeps the real Patrol plugin (E2E tests), and
 * release ships zero test libraries. Do NOT move this file into `main`.
 */
public class PatrolPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        // No-op: test automation hooks exist in debug builds only.
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        // No-op.
    }
}
