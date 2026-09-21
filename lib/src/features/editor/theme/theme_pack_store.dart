import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_riverpod/legacy.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "builtin_packs.dart";
import "editor_theme_pack.dart";

/// Active editor theme selection + user-imported packs.
class EditorThemeState {
  const EditorThemeState({
    required this.lightPackId,
    required this.darkPackId,
    this.customPacks = const [],
  });

  final String lightPackId;
  final String darkPackId;
  final List<EditorThemePack> customPacks;

  EditorThemeState copyWith({
    String? lightPackId,
    String? darkPackId,
    List<EditorThemePack>? customPacks,
  }) {
    return EditorThemeState(
      lightPackId: lightPackId ?? this.lightPackId,
      darkPackId: darkPackId ?? this.darkPackId,
      customPacks: customPacks ?? this.customPacks,
    );
  }
}

class EditorThemeStore extends StateNotifier<EditorThemeState> {
  static const kLight = "nova.editorThemeLight";
  static const kDark = "nova.editorThemeDark";

  EditorThemeStore()
      : super(const EditorThemeState(
          lightPackId: BuiltinThemePacks.defaultLightPackId,
          darkPackId: BuiltinThemePacks.defaultDarkPackId,
        )) {
    load();
  }

  /// Every pack: built-ins first, then user imports.
  List<EditorThemePack> get allPacks =>
      [...BuiltinThemePacks.all, ...state.customPacks];

  /// Pack effective for [brightness]: custom match, builtin match,
  /// else the brightness default.
  EditorThemePack packFor(Brightness brightness) {
    final id = brightness == Brightness.light
        ? state.lightPackId
        : state.darkPackId;
    for (final pack in state.customPacks) {
      if (pack.id == id) return pack;
    }
    return BuiltinThemePacks.byId(id) ??
        BuiltinThemePacks.byId(brightness == Brightness.light
            ? BuiltinThemePacks.defaultLightPackId
            : BuiltinThemePacks.defaultDarkPackId)!;
  }

  Future<void> setPackFor(Brightness brightness, String id) async {
    state = brightness == Brightness.light
        ? state.copyWith(lightPackId: id)
        : state.copyWith(darkPackId: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        brightness == Brightness.light ? kLight : kDark, id);
  }

  /// Validates + registers a VSCode-compatible JSON pack, persisting it.
  Future<EditorThemePack> importPack(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException("Theme JSON must be an object");
    }
    var id = slugifyId(decoded["name"] as String? ?? "custom");
    if (BuiltinThemePacks.byId(id) != null) id = "$id-custom";
    final pack = EditorThemePack.fromJson(id, decoded);
    final dir = await _packsDir();
    await File("${dir.path}/$id.json").writeAsString(jsonString);
    state = state.copyWith(
      customPacks: [
        for (final p in state.customPacks)
          if (p.id != id) p,
        pack,
      ],
    );
    return pack;
  }

  // Exports a pack (built-in or custom) as its JSON string for copy/share.
  // Throws [StateError] for unknown ids.
  Future<String> exportPackJson(String id) async {
    for (final pack in allPacks) {
      if (pack.id == id) return jsonEncode(pack.toJson());
    }
    throw StateError("Unknown theme pack $id");
  }

  Future<void> deleteCustomPack(String id) async {
    if (BuiltinThemePacks.byId(id) != null) {
      throw StateError("Built-in pack $id cannot be deleted");
    }
    final dir = await _packsDir();
    final file = File("${dir.path}/$id.json");
    if (await file.exists()) await file.delete();
    var next = state.copyWith(
      customPacks: [for (final p in state.customPacks) if (p.id != id) p],
    );
    if (next.lightPackId == id) {
      next = next.copyWith(
          lightPackId: BuiltinThemePacks.defaultLightPackId);
    }
    if (next.darkPackId == id) {
      next =
          next.copyWith(darkPackId: BuiltinThemePacks.defaultDarkPackId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLight, state.lightPackId);
    await prefs.setString(kDark, state.darkPackId);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final customs = <EditorThemePack>[];
    try {
      final dir = await _packsDir();
      if (await dir.exists()) {
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith(".json"))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        for (final file in files) {
          try {
            final decoded = jsonDecode(await file.readAsString());
            if (decoded is! Map<String, dynamic>) continue;
            final name = file.uri.pathSegments.last.replaceAll(".json", "");
            customs.add(EditorThemePack.fromJson(name, decoded));
          } catch (_) {
            // Skip one corrupt file without failing the load.
          }
        }
      }
    } catch (_) {
      // Storage unavailable: fall back to built-ins.
    }
    state = EditorThemeState(
      lightPackId: prefs.getString(kLight) ??
          BuiltinThemePacks.defaultLightPackId,
      darkPackId:
          prefs.getString(kDark) ?? BuiltinThemePacks.defaultDarkPackId,
      customPacks: customs,
    );
  }

  Future<Directory> _packsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory("${docs.path}/nova_themes");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}

final editorThemeStoreProvider =
    StateNotifierProvider<EditorThemeStore, EditorThemeState>(
        (ref) => EditorThemeStore());

/// "My Cool Theme!" -> "my-cool-theme".
String slugifyId(String raw) {
  final slug = raw
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), "-")
      .replaceAll(RegExp(r"^-+|-+$"), "");
  return slug.isEmpty ? "custom" : slug;
}
