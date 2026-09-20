import "package:google_fonts/google_fonts.dart";

/// Monospace fonts usable in the editor.
///
/// `family` null means the platform system monospace. Google fonts are
/// downloaded on first use and cached offline by the google_fonts package,
/// which is also the future download mechanism (new entries, no app update).
class EditorFont {
  const EditorFont({required this.id, required this.label, this.googleName});

  final String id;
  final String label;

  /// google_fonts family name; null for the system font.
  final String? googleName;
}

const List<EditorFont> editorFonts = [
  EditorFont(id: "system", label: "System monospace"),
  EditorFont(
      id: "jetbrains-mono", label: "JetBrains Mono", googleName: "JetBrains Mono"),
  EditorFont(id: "fira-code", label: "Fira Code", googleName: "Fira Code"),
  EditorFont(
      id: "source-code-pro",
      label: "Source Code Pro",
      googleName: "Source Code Pro"),
  EditorFont(
      id: "ibm-plex-mono", label: "IBM Plex Mono", googleName: "IBM Plex Mono"),
];

/// Resolves [id] to a font family for CodeEditorStyle, ensuring a Google
/// font is loaded on first use. Returns null for the system font or an
/// unknown id.
String? fontFamilyFor(String id) {
  for (final font in editorFonts) {
    if (font.id == id) {
      final google = font.googleName;
      if (google == null) return null;
      // Kicks off the download on first use; cached afterwards.
      return GoogleFonts.getFont(google).fontFamily;
    }
  }
  return null;
}
