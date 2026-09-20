/// Abstract editing surface + tab model shared by editor widgets
/// and file/riverpod layers.
abstract class EditorEngine {
  String get language;
  void setContent(String content);
  String getContent();
}

/// Lets a tab content widget (code, markdown...) expose its current savable
/// text to the tab shell that owns the Save button.
class TabContentBridge {
  String Function()? readContent;
}

/// How a tab is rendered: plain code editor or rich Markdown editor.
enum EditorKind { code, markdown }

/// Map a file path to an editor kind by extension.
EditorKind kindForPath(String filePath) {
  final dot = filePath.lastIndexOf(".");
  if (dot < 0 || dot == filePath.length - 1) return EditorKind.code;
  switch (filePath.substring(dot + 1).toLowerCase()) {
    case "md":
    case "markdown":
    case "mdown":
      return EditorKind.markdown;
    default:
      return EditorKind.code;
  }
}

/// A single open file tab.
class EditorTabModel {
  final String id;
  final String path;
  final String language;
  final EditorKind kind;
  final bool dirty;

  const EditorTabModel({
    required this.id,
    required this.path,
    required this.language,
    this.kind = EditorKind.code,
    this.dirty = false,
  });

  EditorTabModel copyWith({
    String? id,
    String? path,
    String? language,
    EditorKind? kind,
    bool? dirty,
  }) {
    return EditorTabModel(
      id: id ?? this.id,
      path: path ?? this.path,
      language: language ?? this.language,
      kind: kind ?? this.kind,
      dirty: dirty ?? this.dirty,
    );
  }

  /// Map a file path to a highlight language id.
  /// py -> python, js -> javascript, php -> php, dart -> dart,
  /// tex -> latex, md -> markdown, everything else -> plaintext.
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
      case "tex":
        return "latex";
      case "md":
      case "markdown":
      case "mdown":
        return "markdown";
      default:
        return "plaintext";
    }
  }

  /// Create a tab model for [filePath], deriving language and editor kind.
  factory EditorTabModel.fromPath(String filePath) {
    return EditorTabModel(
      id: filePath,
      path: filePath,
      language: languageForPath(filePath),
      kind: kindForPath(filePath),
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