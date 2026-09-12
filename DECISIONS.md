# Nova IDE - Architecture Decisions

Package: sd.adaa.codeide | App: Nova | Stack: Flutter + Riverpod

## 1. Editor: re_editor for MVP behind abstraction
- Use re_editor plus re_highlight for the MVP code editor.
- Keep all editor access behind a thin wrapper so a custom editor can replace it later without touching features.
- Rationale: fastest path to syntax highlighting and editing on mobile; abstraction limits lock in.

## 2. Execution: Termux background RUN_COMMAND
- Run py, js, php in background via Termux RUN_COMMAND using channel sd.adaa.codeide/run.
- No foreground terminal dependency for MVP execution.
- Bootstrap mapping: python3 maps to pkg python, node maps to nodejs, php maps to php.
- Language map: py maps to python3, js maps to node, php maps to php.
- Limits: timeout default 25000 ms, stdin cap 45000 chars.
- Manifest: com.termux.permission.RUN_COMMAND plus queries entry for com.termux.

## 3. AI: OpenAI compatible first
- Default base URL https://api.openai.com/v1 with model gpt-4o-mini.
- Dio client against OpenAI compatible chat completions so other backends can be plugged in by changing base URL and model.
- API key lives in flutter_secure_storage and is owned by the AI feature. Settings screen only edits URL and model.

## 4. Git postponed per user request
- No git integration in MVP scope. File handling covers local storage plus file_picker import and export.

## 5. Riverpod over Bloc
- flutter_riverpod StateNotifier for settings and feature state.
- Rationale: less boilerplate than Bloc, good provider composition, works well for small team parallel agent work.
- Settings persisted with shared_preferences: themeMode, timeoutMs, aiBaseUrl, aiModel.

## 6. Module boundaries for parallel agents
- Core owner: app_config, settings_store, app shell, manifest queries, this file.
- Other agents own: home, editor, files, run bridge plus Termux service, AI service plus chat UI.
