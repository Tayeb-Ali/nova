# Nova — a complete dev environment on Android

[العربية](README.md) | **English**

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Version](https://img.shields.io/badge/Version-0.1.0-blue)
![Bridge](https://img.shields.io/badge/Bridge-Pigeon_29-7B61FF)
![State](https://img.shields.io/badge/State-Riverpod-FF6B6B)
![Tests](https://img.shields.io/badge/Tests-224_passing-success)
[![License: Waqf-1.0](https://img.shields.io/badge/License-Waqf--1.0-green)](LICENSE)
[![Google Play](https://img.shields.io/badge/Google_Play-Download-414D0B?logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=sd.adaa.codeide)

<a href="https://play.google.com/store/apps/details?id=sd.adaa.codeide">
  <img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="70"/>
</a>

> **Nova** is a code editor that runs on your Android phone and executes code **for real** on the device itself — Python, JavaScript, PHP, Go, Rust, Ruby, Java, Kotlin, Dart, C/C++ — with a real terminal, Git, and web preview. No external server, no emulation: write, press Run, and see the result.

---

## Contents

- [The idea in short](#the-idea-in-short)
- [Project philosophy](#project-philosophy)
- [How it works](#how-it-works)
- [Project structure](#project-structure)
- [Dependencies](#dependencies)
- [Install & run](#install--run)
- [Tests](#tests)
- [On-device diagnostics](#on-device-diagnostics)
- [Common issues & fixes](#common-issues--fixes)
- [Current status & roadmap](#current-status--roadmap)
- [The pro editor: completion, themes & fonts](#the-pro-editor-completion-themes--fonts)
- [Contributing](#contributing)
- [Contributors](#contributors)
- [License](#license)

---

## The idea in short

Most "code editors" on mobile are either just syntax highlighters, or they send your code to a remote server that runs it and returns the result. Nova chose the harder, more honest path:

1. **Open a project** (or create a new one: PHP / Node / Python / Go / Rust / Ruby / Java / Kotlin / Dart / C).
2. **Browse and edit your files** in an editor with language highlighting and tabs.
3. **Press Run** and the code executes inside a real Linux environment **embedded in the app itself** (built on Termux packages).
4. **Watch the output** live in the console panel, open a full terminal, or preview a web page your project serves.

All of this happens on your device, even offline (after the first package install).

---

## Project philosophy

- **The phone is a real dev machine, not just a viewer.** The idea is to program from anywhere, not to wait for a computer.
- **Real execution before pretty UI.** Any cosmetic feature must not break the rule: code has to actually execute on the device.
- **Thin, clear layers.** The UI (Flutter) knows nothing about system details, and the engine (Android/Kotlin) knows nothing about screens. Between them sits a single auto-generated contract (Pigeon) — change one side and the other is unaffected.
- **Don't reinvent the wheel.** The runtime = official Termux packages. The editor = the `re_editor` library. The terminal = `xterm`. Nova assembles these pieces instead of writing them from scratch.
- **Transparency on failure.** Every long operation (package install, task run) streams live progress, and failures show a clear cause, never a silent screen.

---

## How it works

The full picture in five lines:

```
┌──────────────┐   Pigeon (calls)    ┌──────────────────┐
│  Flutter UI   │ ───────────────▶ │  Kotlin engine    │
│  screens+state│ ◀─────────────── │  execution+files  │
└──────────────┘  single event bus └──────────────────┘
        │                                     │
        │ Riverpod (state)                    │ Embedded Linux PREFIX
        ▼                                     ▼ (files/usr/bin/…)
```

### 1. The UI (Flutter/Dart)

Everything you see: the collapsible side explorer, the editor, the Run button, the console, the terminal, the Git/runtime/settings screens. State is managed with **Riverpod** (each screen subscribes to `Provider`s instead of manual plumbing).

### 2. The bridge (Pigeon)

The UI and the engine are different languages (Dart and Kotlin), and they talk through a single file:

- `pigeons/ide_api.dart` — **the contract**: every available call (files, processes, terminal, Git, runtime...).
- Generated from it: `ide_api.g.dart` (Dart side) and `IdeApi.g.kt` (Kotlin side).

> Rule: never hand-write bridge code — edit the `pigeons` file, then regenerate.

### 3. The event channel

Calls fit request/response ("open file", "start process"), but **continuous events** (a new console line, install progress %) need a live stream. Hence a single event channel named `sd.adaa.codeide/events`.

One lesson learned the hard way: the channel effectively supports **one live listener**. So every subscription goes through **`IdeEventBus`** — a single junction that receives the stream and fans it out to (terminal, processes, preview, runtime screen). Without it, events were lost with symptoms like "install starts then freezes".

### 4. The engine (Kotlin)

Specialized managers, each owning only its file:

| Component | Role |
|---|---|
| `ProjectManager` / `FileApiImpl` | Projects and files (create, read, delete...) |
| `ProcessManager` / `ShellExecutor` | Running commands and collecting output |
| `TerminalManager` / `PtyNative` | Interactive terminal sessions |
| `GitManager` / `GitApiImpl` | Core Git operations |
| `RuntimeManager` / `BootstrapInstaller` | The runtime environment and package installs |
| `WebPreviewApiImpl` / `PortDetector` | Port detection and web preview |
| `IdeService` | Foreground service for long operations |
| `IdeCore` | Boot-time init + environment self-heal |

### 5. The runtime (Linux inside the app)

On first launch, the app unpacks a `bootstrap` package under its data dir (`files/usr/...`) — Python, Node, and core tools ready. Paths baked into the package (`/data/data/com.termux/files/usr`) are auto-patched to the app's real path.

Languages supported today: PHP and Node.js and Python, plus Go (`golang`), Rust (`rust`), Ruby (`ruby`), Java (`openjdk-25`), Kotlin (`kotlin`), Dart (`dart`), and C/C++ (`clang` — Clang 21) — all installed from Nova's own repository via in-app `apt`.

Repository: `http://elteyab.sd/nova/apt` (suite `stable`, component `main`), signed with Nova's key embedded in the bootstrap package.

The two bootstrap variants in the setup screen (`slim` is the default):

| Type | Contents | Approx. size | Source |
|---|---|---|---|
| `slim` | Base + `apt` only; other languages install on demand | ~67–70MB | `http://elteyab.sd/nova/bootstrap` |
| `full` | Every language preinstalled — for offline work | ~283MB | GitHub Releases attachments |

Installing a new package (e.g. `git`) follows a proven recipe: `apt download` the package and its deps, then extract every `.deb` directly into the environment, then fix the start (`shebang`) links. This works around a `dpkg` limitation that blocks it from creating folders outside its original prefix.

---

## Project structure

```
nova/
├── lib/                          # The UI (Dart/Flutter)
│   ├── main.dart / app.dart       # Entry point + app shell
│   └── src/
│       ├── core/
│       │   ├── bridge/           # Bridge: native_bridge + events_bus + generated
│       │   ├── models/           # Data models (project, task, process...)
│       │   └── services/         # Screen services (files, processes, terminal, Git...)
│       └── features/             # Screens: workspace, editor, terminal,
│                                 # process, git, runtime, webpreview, lsp, ai
├── android/app/src/main/kotlin/   # The engine (Kotlin)
│   └── sd/adaa/codeide/
│       ├── filesystem/ project/ process/ terminal/
│       ├── git/ runtime/ webpreview/
│       └── MainActivity · IdeCore · IdeService · IdeEvents · AllApis
├── pigeons/ide_api.dart           # The bridge contract (single source of truth)
├── test/                         # Unit tests + the comprehensive in-app test
├── DECISIONS.md                  # Architecture decision log
├── plan.md / task.md             # Plan and task tracking
└── README.md                     # This file (Arabic original)
```

### Main screens

| Screen | What it does |
|---|---|
| Workspace | Collapsible side explorer + editor + Run button |
| Editor | File tabs, language highlighting, save, dirty indicator |
| Markdown | Rich-text editor for `.md` files (edit + preview) via Fleather |
| Run Console | Task picker, run/stop, live output (collapsible, returns automatically on Run) |
| Terminal | Full interactive terminal with a custom keyboard |
| Process | Running-process list and management |
| Git | Repo status and core operations |
| Runtime | Runtime install/update/remove with live progress bar, % and download speed |
| Web Preview | Preview web pages served by your project |
| Settings / AI / LSP | Settings, OpenAI-compatible assistant, and language-server support |

---

## Dependencies

### Flutter UI

| Package | Why we use it |
|---|---|
| `flutter_riverpod` + `riverpod` | State management across the app |
| `re_editor` + `re_highlight` | The editor and language highlighting (behind an abstraction so it can be swapped later) |
| `fleather` + `parchment` | Rich Markdown editor (edit + open/save `.md`) |
| `flutter_markdown` | Read-only Markdown preview |
| `xterm` | The interactive terminal |
| `flutter_inappwebview` | In-app web preview |
| `dio` | HTTP client for the AI service |
| `flutter_secure_storage` | Storing the API key securely |
| `shared_preferences` | Storing settings (theme, timeout, AI endpoint...) |
| `file_picker` / `path_provider` / `path` | File import and paths |
| `pigeon` (dev) | Generating the Dart↔Kotlin bridge code |

### Android side

- **Kotlin** + Android SDK, `applicationId = sd.adaa.codeide`.
- `targetSdk = 28` — **deliberate, not neglect**: from 29 on, the system (SELinux) blocks executing files inside the app data dir, which kills the embedded runtime.
- `useLegacyPackaging = true` for the same reason.

---

## Install & run

> **Regular user?** Install the app straight from [Google Play](https://play.google.com/store/apps/details?id=sd.adaa.codeide) — everything below is for developers.

### Requirements

- Flutter SDK (tested on `3.47.x`) — includes Dart `3.13.x`.
- Android SDK + emulator or a real device with `USB debugging` enabled.
- Internet connection **for first launch only** (downloading runtime packages).

### Steps

```bash
# 1. Fetch dependencies
flutter pub get

# 2. (Only when pigeons/ide_api.dart changes) regenerate the bridge
dart run pigeon --input pigeons/ide_api.dart

# 3. Quick check
flutter analyze
flutter test

# 4. Run on device/emulator (flavor is mandatory: `github` for dev, `play` for the Play gate)
flutter run --flavor github

# 5. Installable APK (build via `flutter` only, never Gradle directly)
flutter build apk --debug --flavor github
# Play build (targetSdk 36 + linker mode):
flutter build apk --debug --flavor play
```

### Signing the Play build

With your key ready, export the variables before building (never put the key in the repo):

```bash
$env:NOVA_KEYSTORE_PATH="C:\keys\nova.jks"
$env:NOVA_KEYSTORE_PASSWORD="..."
$env:NOVA_KEY_ALIAS="nova"
$env:NOVA_KEY_PASSWORD="..."
flutter build apk --release --flavor play
```

Without these variables the release is signed with debug keys (dev only — never submit it to Play).

> **Two notes that save you hours:**
>
> - After any `flutter pub get`, re-apply the `proguard` patch to `flutter_inappwebview_android` (remove the `-optimize` line) or the build fails.
> - Always build with `flutter build apk`, never Gradle directly — a Gradle-only build can produce a stale APK missing your latest Dart changes.

### First boot on device

1. Install the APK and open the app.
2. Wait for the environment package to unpack (one time only).
3. Create a project (PHP / Node / Python / Go / Rust / Ruby / Java / Kotlin / Dart / C), open a file, and press **Run**.

---

## Tests

```bash
flutter analyze   # must say: No issues found
flutter test      # must say: all tests pass (224 currently)
```

- `test/comprehensive_inapp_test.dart` — a comprehensive test covering (Node / Python / Terminal) inside the app.
- `test/*_test.dart` — unit tests for services (AI, LSP, runtime, terminal).
- `DebugTestHarness.kt` — an **in-app** test suite on the device (Node + Python + Terminal) triggered by `DEBUG_*` broadcasts; all must PASS before any release.

---

## On-device diagnostics

During development you can trigger real events via `adb` (the app must be in the foreground, with the explicit component `-n`):

```bash
# Install git through the app's real install path
adb shell am broadcast -a sd.adaa.codeide.DEBUG_INSTALL_RUNTIME --es id git

# Watch events
adb logcat -s flutter:I | grep IDE-EVENT

# Inspect the environment manually
adb shell "run-as sd.adaa.codeide sh -c 'ls files/usr/bin | head'"
```

---

## Common issues & fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| Install starts then freezes | The `runtimeProgress` event never reaches the screen | Make sure every subscription goes through `IdeEventBus` alone |
| `Unable to locate package X` after update | `sources.list` files lost (re-unpacking wipes manual fixes) | The setup now lives permanently in `BootstrapInstaller.configureApt` — don't fix it manually on device |
| `Permission denied: ./data/data/com.termux` | `dpkg` refuses to create its original paths | Normal — installs use the download + direct-extract recipe, not `apt install` |
| Build fails after `pub get` | The proguard patch was lost | Re-apply it on `flutter_inappwebview_android-1.1.3` |
| APK doesn't include your changes | Built via Gradle directly | Build with `flutter build apk --debug`, then install |
| `pm clear` wiped nothing | It doesn't really clear app files here | Delete the data dir manually or reinstall with wipe |

---

## Current status & roadmap

**Working now:** multi-tab editor, explorer, run with live output, terminal, processes, Git, runtime install with live progress, web preview, settings, AI assistant, and initial LSP support — all covered by passing on-device tests.

**Suggested next:** complete Git (branches/merge), better editor completion, more runtime packages, smaller APK.

---

## The pro editor: completion, themes & fonts

- **VSCode-style autocomplete**: per-language keywords + ready snippets (python/js/php/dart/json) + words picked from the open file, with a typed suggestion popup. Togglable in settings.
- **VSCode-format themes**: 10 built-in themes (VSCode light/dark, Monokai, Nord, Tokyo Night...) + import any `tokenColors` JSON.
- **The whole app follows the editor**: picking a dark theme like VSCode Dark recolors every screen (optional, in settings).
- **Semantic colors**: functions vs variables vs classes (`semanticTokenColors`) in real VSCode colors.
- **Coding fonts**: JetBrains Mono, Fira Code, Source Code Pro, IBM Plex Mono — downloaded on first use and kept for offline work — with size control.
- **Live preview** in settings showing the editor with the font, size, and theme before applying.

---

## Contributing

1. Read `DECISIONS.md` before any architectural change — the decisions written there are binding.
2. Any new UI↔engine API goes in `pigeons/ide_api.dart`, then generated — never hand-written.
3. After any change: `flutter analyze`, then `flutter test` — never ship a broken build.
4. New feature = a covering test where possible.

---

## Contributors

| Contributor | Role |
|---|---|
| [Tayeb Ali](https://github.com/Tayeb-Ali) ([elteyab@smart.sd](mailto:elteyab@smart.sd)) | Project owner & developer |
| opencode (GLM, Muse Spark models) | AI development assistant |
| ChatGPT | AI development assistant |

---

## License

This project is a **waqf for the sake of Allah**, licensed under the **Waqf General Public License — Version 1**. Full text in [LICENSE](LICENSE), and the official text on the Ojuba site: https://ojuba.org/waqf:license

In short, you may:

- **Use** the work for any beneficial purpose that harms no one and violates no Islamic principle.
- **Redistribute** it as-is, in any quantity, crediting its owner.
- **Modify** it, with full source access.
- **Distribute the modified version** under the same Waqf license, clarifying it is modified, not the original.

Impersonating or claiming the work is forbidden, and its owner bears no liability for its use.
