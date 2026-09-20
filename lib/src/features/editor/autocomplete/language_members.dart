import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:re_editor/re_editor.dart";


class MemberRegistry {
  static const Map<String, String> _assetForLanguage = {
    "javascript": "assets/autocomplete/javascript.json",
    "python": "assets/autocomplete/python.json",
    "dart": "assets/autocomplete/dart.json",
  };

  static final Map<String, Map<String, List<CodePrompt>>> _tables = {};
  static bool _warming = false;
  static bool _warm = false;

  static Future<void> ensureLoaded() async {
    if (_warm || _warming) return;
    _warming = true;
    try {
      for (final entry in _assetForLanguage.entries) {
        try {
          final raw = await rootBundle.loadString(entry.value);
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            _tables[entry.key] = _parseReceivers(decoded);
          }
        } catch (_) {
          // One bad file must not block the others.
        }
      }
    } finally {
      _warming = false;
      _warm = true;
    }
  }


  @visibleForTesting
  static Map<String, List<CodePrompt>> parseReceivers(
    Map<String, dynamic> json,
  ) {
    return _parseReceivers(json);
  }

  static Map<String, List<CodePrompt>> _parseReceivers(
    Map<String, dynamic> json,
  ) {
    final result = <String, List<CodePrompt>>{};
    final receivers = json["receivers"];
    if (receivers is! Map<String, dynamic>) return result;
    for (final receiverEntry in receivers.entries) {
      final receiver = receiverEntry.value;
      if (receiver is! Map<String, dynamic>) continue;
      final prompts = <CodePrompt>[];
      final methods = receiver["methods"];
      if (methods is Map<String, dynamic>) {
        for (final method in methods.entries) {
          if (method.value is! String) continue;
          prompts.add(
            CodeFunctionPrompt(word: method.key, type: method.value as String),
          );
        }
      }
      final fields = receiver["fields"];
      if (fields is Map<String, dynamic>) {
        for (final field in fields.entries) {
          if (field.value is! String) continue;
          prompts.add(
            CodeFieldPrompt(word: field.key, type: field.value as String),
          );
        }
      }
      if (prompts.isNotEmpty) {
        result[receiverEntry.key] = prompts;
      }
    }
    return result;
  }

  /// Test seam: installs a parsed table without asset loading.
  @visibleForTesting
  static void debugFill(String languageId, Map<String, dynamic> json) {
    _tables[languageId] = _parseReceivers(json);
  }

  static List<CodePrompt>? lookup(
    String? languageId,
    String receiver,
    String partial,
  ) {
    final members = _tables[languageId]?[receiver];
    if (members == null) return null;
    final matched = members
        .where((prompt) => prompt.match(partial))
        .toList(growable: false);
    return matched.isEmpty ? null : matched;
  }
}

List<CodePrompt>? memberPrompts(
  String? languageId,
  String receiver,
  String partial,
) {
  return MemberRegistry.lookup(languageId, receiver, partial);
}
