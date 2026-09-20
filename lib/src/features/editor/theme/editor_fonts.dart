import "package:google_fonts/google_fonts.dart";


class EditorFont {
  const EditorFont({
    required this.id,
    required this.label,
    this.googleName,
    this.bundled = false,
    this.url,
    this.family,
  });

  final String id;
  final String label;

  final String? googleName;

  final bool bundled;

  final String? url;

  final String? family;
}

const List<EditorFont> editorFonts = [
  EditorFont(id: "system", label: "System monospace", bundled: true),
  EditorFont(
    id: "jetbrains-mono",
    label: "JetBrains Mono",
    googleName: "JetBrains Mono",
    bundled: true,
  ),
  EditorFont(id: "fira-code", label: "Fira Code", googleName: "Fira Code"),
  EditorFont(
    id: "cascadia-code",
    label: "Cascadia Code",
    googleName: "Cascadia Code",
  ),
  EditorFont(
    id: "source-code-pro",
    label: "Source Code Pro",
    googleName: "Source Code Pro",
  ),
  EditorFont(
    id: "ibm-plex-mono",
    label: "IBM Plex Mono",
    googleName: "IBM Plex Mono",
  ),
  EditorFont(
    id: "roboto-mono",
    label: "Roboto Mono",
    googleName: "Roboto Mono",
  ),
  EditorFont(
    id: "ubuntu-mono",
    label: "Ubuntu Mono",
    googleName: "Ubuntu Mono",
  ),
  EditorFont(id: "inconsolata", label: "Inconsolata", googleName: "Inconsolata"),
  EditorFont(id: "space-mono", label: "Space Mono", googleName: "Space Mono"),
  EditorFont(
    id: "anonymous-pro",
    label: "Anonymous Pro",
    googleName: "Anonymous Pro",
  ),
  EditorFont(id: "cousine", label: "Cousine", googleName: "Cousine"),
  EditorFont(
    id: "victor-mono",
    label: "Victor Mono",
    googleName: "Victor Mono",
  ),
  EditorFont(id: "geist-mono", label: "Geist Mono", googleName: "Geist Mono"),
  EditorFont(
    id: "jetbrainsmono-nerd",
    label: "JetBrainsMono Nerd Font Mono",
    url:
        "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFontMono-Regular.ttf",
    family: "JetBrainsMonoNerdFontMono",
  ),
  EditorFont(
    id: "hack-nerd",
    label: "Hack Nerd Font Mono",
    url:
        "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/Hack/HackNerdFontMono-Regular.ttf",
    family: "HackNerdFontMono",
  ),
  EditorFont(
    id: "meslo-nerd",
    label: "Meslo LG Nerd Font Mono",
    url:
        "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/Meslo/L/MesloLGLNerdFontMono-Regular.ttf",
    family: "MesloLGLNerdFontMono",
  ),
  EditorFont(
    id: "caskaydia-nerd",
    label: "Caskaydia Cove Nerd Font Mono",
    url:
        "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/CascadiaCode/CaskaydiaCoveNerdFontMono-Regular.ttf",
    family: "CaskaydiaCoveNerdFontMono",
  ),
];


String? fontFamilyFor(String id) {
  for (final font in editorFonts) {
    if (font.id == id) {
     
     if (font.url != null) return font.family;
      final google = font.googleName;
      if (google == null) return null;
      // Kicks off the download on first use; cached afterwards.
      return GoogleFonts.getFont(google).fontFamily;
    }
  }
  return null;
}
