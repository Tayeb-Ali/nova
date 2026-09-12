/// Abstract editing surface + tab model shared by editor widgets
/// and file/riverpod layers.
abstract class EditorEngine {
  String get language;
  void setContent(String content);
  String getContent();
}

/// A single open file tab.
class EditorTabModel {
  final String id;
  final String path;
  final String language;
  final bool dirty;

  const EditorTabModel({
    required this.id,
    required this.path,
    required this.language,
    this.dirty = false,
  });

  EditorTabModel copyWith({
    String? id,
    String? path,
    String? language,
    bool? dirty,
  }) {
    return EditorTabModel(
      id: id ?? this.id,
      path: path ?? this.path,
      language: language ?? this.language,
      dirty: dirty ?? this.dirty,
    );
  }

  /// Map a file path to a highlight language id.
  /// py -> python, js -> javascript, php -> php, dart -> dart,
  /// everything else -> plaintext.
  static String languageForPath(String filePath) {
    final dot = filePath.lastIndexOf(".");
    if (dot < 0 || dot == filePath.length - 1) return "plaintext";
    final ext = filePath.substring(dot + 1).toLowerCase();
    switch (ext) {
      case "py":
        return "python";
      case "js":
        return "javascript";
      case "php":
        return "php";
      case "dart":
        return "dart";
      case "json":
        return "json";
      default:
        return "plaintext";
    }
  }

  /// Create a tab model for [filePath], deriving the language.
  factory EditorTabModel.fromPath(String filePath) {
    return EditorTabModel(
      id: filePath,
      path: filePath,
      language: languageForPath(filePath),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTabModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}