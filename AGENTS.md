# AGENTS.md

Nova: a Flutter/Android IDE app that runs code in an embedded Termux Linux runtime inside the app itself. UI/state is Dart (`lib/`), the engine is Kotlin (`android/app/src/main/kotlin/sd/adaa/codeide/`). State management is Riverpod 3. Flutter 3.47 / Dart 3.13. README is in Arabic; code comments are English.

## Commands

- `flutter pub get` — deps (then re-apply the inappwebview proguard patch, see below).
- `dart run pigeon --input pigeons/ide_api.dart` — regenerate the bridge after editing the Pigeon contract (never hand-write bridge code).
- `flutter analyze` — must end in `No issues found`.
- `flutter test` — 224 unit/widget tests, all native APIs mocked (`TestDefaultBinaryMessenger`); no device needed.
- `flutter build apk --debug --flavor github` — the only trustworthy APK path. Running Gradle directly can produce stale APKs missing recent Dart changes.

## Product flavors (hard rule: ALWAYS pass `--flavor`)

`android/app/build.gradle.kts` declares `flavorDimensions += "store"` with flavors `github` and `play`.

**A flavor-less `flutter run` / `flutter build apk` FAILS** with
`Gradle build failed to produce an .apk file` — not a Gradle error. `assembleDebug`
succeeds and emits `app-github-debug.apk` + `app-play-debug.apk`, but the Flutter tool
looks for the non-existent `app-debug.apk`. Always pass `--flavor`:

- `flutter run --flavor github` — dev default. targetSdk 28 + `DEFAULT_EXEC_MODE=direct` (the shipping path).
- `flutter run --flavor play` — targetSdk 36 + `DEFAULT_EXEC_MODE=linker` (the tested Play gate).

`.vscode/launch.json` uses `--flavor github`. There is no `target36spike` flavor; references to it are stale.

## Package naming (hard rule, user-ordered, never violate)

- The Dart package name is `nova` forever (`pubspec.yaml`, all `package:nova/` imports). NEVER rename it to `codeide`.
- The Android applicationId/namespace is `sd.adaa.codeide` forever. The two names are unrelated — do NOT unify them.
- Pigeon channel strings are `dev.flutter.pigeon.codeide.*` on BOTH sides (the checked-in generated files are the source of truth and match). Regenerating with `pubspec=nova` would flip the Dart channels to `pigeon.nova` and break the bridge — do NOT regenerate unless the Kotlin output is regenerated in the same step and both files' channel strings are verified equal afterwards.

## The Pigeon bridge (hard rule)

- `pigeons/ide_api.dart` is the single contract between Dart and Kotlin. Do NOT edit generated files by hand.
- Outputs are configured in the `@ConfigurePigeon` annotation: `lib/src/core/bridge/generated/ide_api.g.dart` and `android/app/src/main/kotlin/sd/adaa/codeide/bridge/IdeApi.g.kt`. Regenerate, then commit both.
- Regen keeps the `codeide` channel prefix ONLY if run with the pubspec name temporarily set to `codeide` (backup `pubspec.yaml`, rename `nova`→`codeide`, run pigeon, restore — no `pub get` in between). A plain regen emits `pigeon.nova.*` and breaks the bridge + every test mock.
- Flutter side talks to the platform through `NativeBridge` (`lib/src/core/bridge/native_bridge.dart`); screen-facing services wrap it in `lib/src/core/services/`.

## Event channel (hard rule)

- The native→Dart event stream is one `EventChannel` (`sd.adaa.codeide/events`, name in `AppConfig.eventsChannel`), and it supports effectively ONE live listener. Subscribing to `NativeBridge.events.receiveBroadcastStream()` directly from multiple places silently drops events for the others — symptom: "install starts then stalls".
- All consumers must subscribe via the `IdeEventBus` singleton (`lib/src/core/bridge/events_bus.dart`), which owns the single native subscription and fans out.

## Android constraints (deliberate, don't "fix")

- `targetSdk = 28` on the **github** flavor is INTENTIONAL (comment in `android/app/build.gradle.kts`): targetSdk 29+ blocks exec from the app data dir via SELinux, killing the embedded runtime. `defaultConfig` tracks Flutter's targetSdk so release lint passes; the github flavor pins 28. Same reason for `useLegacyPackaging = true`.
- Internal storage path `run-as sd.adaa.codeide` is used because `pm clear` does not truly wipe app files.
- Release signing reads `android/key.properties` (never committed) with `NOVA_KEYSTORE_*` env fallback, else debug keys (local only — never ship a fallback build to Play).
- `android/app/src/release/java/pl/leancode/patrol/PatrolPlugin.java` is a no-op stub: `patrol` is a dev_dependency (debug-only classes) but the generated registrant references it in all builds. Do NOT delete it and do NOT move `patrol` to `dependencies` (would bundle test libs into the Play APK).
- Native C (`pty`) lives in `android/app/src/main/cpp` via CMake; ABIs are arm64-v8a + x86_64.

## Runtime / Termux gotchas

- Bootstrap unpacks into the app data dir (`files/usr/...`); shebang paths from `/data/data/com.termux/files/usr` are patched at install. Don't hand-edit apt state on device — the `sources.list` fix is persisted in `BootstrapInstaller.configureApt`.
- Package installation is `apt download` + direct `.deb` extraction, NOT `apt install` (dpkg can't create paths outside its original prefix; `Permission denied: ./data/data/com.termux` is expected, not an error).

## On-device debugging

App must be in the foreground; broadcast with the explicit component (registered in `MainActivity`):

```
adb shell am broadcast -a sd.adaa.codeide.DEBUG_SETUP -n sd.adaa.codeide/.MainActivity
adb shell am broadcast -a sd.adaa.codeide.DEBUG_INSTALL_RUNTIME --es id git -n sd.adaa.codeide/.MainActivity
adb shell am broadcast -a sd.adaa.codeide.DEBUG_COMPREHENSIVE_TEST -n sd.adaa.codeide/.MainActivity   # Kotlin DebugTestHarness: Node/Python/Terminal, must all PASS pre-release
adb logcat -s flutter:I | grep IDE-EVENT
adb shell "run-as sd.adaa.codeide sh -c 'ls files/usr/bin | head'"
```

## Layout

- `lib/src/core/bridge/` — NativeBridge + IdeEventBus + generated Pigeon code.
- `lib/src/core/services/` — service classes used by screens (files, process, terminal, git, runtime, setup, webpreview).
- `lib/src/core/models/` — self-contained data models (see comment in `project.dart`).
- `lib/src/features/<feature>/` — screens/widgets, each usually with a `<feature>_providers.dart`.
- Kotlin `sd/adaa/codeide/`: one manager per concern (`ProjectManager`, `ProcessManager`, `TerminalManager`, `GitManager`, `RuntimeManager`, `WebPreviewApiImpl`), plus `IdeCore` (bootstrap/self-heal), `IdeService` (foreground service), `IdeEvents`.
- Edit for Markdown is `fleather`+`parchment`; code editor is `re_editor` behind adapters (`editor_engine.dart`, `re_editor_adapter.dart`) so it can be swapped later.
- Entry: `lib/main.dart` → `NovaApp` (`lib/app.dart`) → `IdeShell` (bottom nav; switches to `NavigationRail` at width ≥ 700px).

## Stale references

- Code comments and README reference `DECISIONS.md`, `plan.md`, `task.md` (e.g. `task.md §27`) — these files are NOT in the repo; don't chase them.
- README's "22 tests" is outdated (224 pass today).