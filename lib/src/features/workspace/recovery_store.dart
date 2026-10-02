import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

/// Crash-recovery drafts for unsaved editor buffers ("hot exit").
///
/// When a tab is dirty, the editor debounces its current text here; if the
/// app is killed (or the tab closed) before saving, the next open of the
/// same path finds the draft and offers to restore it. Drafts are cleared
/// on successful save, on explicit reload, and when the user discards them.
///
/// Storage is one self-describing JSON file per path under
/// `<app docs>/nova_recovery/`. All methods are best-effort and never throw.
class RecoveryDraft {
  const RecoveryDraft({
    required this.path,
    required this.text,
    required this.savedAt,
  });

  final String path;
  final String text;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        "path": path,
        "text": text,
        "savedAt": savedAt.millisecondsSinceEpoch,
      };

  static RecoveryDraft? fromJson(Map<String, dynamic> json) {
    final path = json["path"];
    final text = json["text"];
    final savedAt = json["savedAt"];
    if (path is! String || text is! String || savedAt is! int) return null;
    return RecoveryDraft(
      path: path,
      text: text,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
    );
  }
}

class RecoveryStore {
  /// Production store rooted at the app documents directory.
  RecoveryStore() : _overrideDir = null;

  /// Test seam: root drafts at [dir] instead of app documents.
  RecoveryStore.testWithDir(this._overrideDir);

  final Directory? _overrideDir;

  /// Drafts larger than this are skipped (protects prefs-less file IO and
  /// startup scans from pathological buffers).
  static const int maxDraftBytes = 512 * 1024;

  /// Drafts older than this are pruned opportunistically on write.
  static const Duration maxDraftAge = Duration(days: 7);

  Future<Directory> _dir() async {
    final override = _overrideDir;
    if (override != null) {
      if (!await override.exists()) {
        await override.create(recursive: true);
      }
      return override;
    }
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, "nova_recovery"));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Deterministic file name for [path] (base64url, truncated with a hash
  /// suffix when the encoded form would exceed file-name limits).
  @visibleForTesting
  static String fileNameFor(String path) {
    final encoded =
        base64Url.encode(utf8.encode(path)).replaceAll("=", "");
    if (encoded.length <= 160) return "$encoded.draft.json";
    final hash = path.hashCode.toUnsigned(32).toRadixString(16);
    return "${encoded.substring(0, 120)}-$hash.draft.json";
  }

  Future<void> writeDraft(String path, String text) async {
    try {
      if (utf8.encode(text).length > maxDraftBytes) return;
      final dir = await _dir();
      final file = File(p.join(dir.path, fileNameFor(path)));
      final draft = RecoveryDraft(
        path: path,
        text: text,
        savedAt: DateTime.now(),
      );
      await file.writeAsString(jsonEncode(draft.toJson()));
      await _prune(dir);
    } catch (_) {
      // Best effort: recovery must never break editing.
    }
  }

  Future<RecoveryDraft?> readDraft(String path) async {
    try {
      final dir = await _dir();
      final file = File(p.join(dir.path, fileNameFor(path)));
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final draft = RecoveryDraft.fromJson(decoded);
      if (draft == null || draft.path != path) return null;
      return draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft(String path) async {
    try {
      final dir = await _dir();
      final file = File(p.join(dir.path, fileNameFor(path)));
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort.
    }
  }

  Future<void> _prune(Directory dir) async {
    try {
      final cutoff = DateTime.now().subtract(maxDraftAge);
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith(".draft.json")) {
          continue;
        }
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Best effort.
    }
  }
}
