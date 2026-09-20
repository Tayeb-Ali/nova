import "package:flutter_test/flutter_test.dart";
import "package:parchment/codecs.dart";

import "package:nova/src/features/editor/editor_engine.dart";

void main() {
  group("editor routing", () {
    test("markdown extensions route to the rich editor", () {
      expect(kindForPath("notes.md"), EditorKind.markdown);
      expect(kindForPath("README.MARKDOWN"), EditorKind.markdown);
      expect(kindForPath("doc.mdown"), EditorKind.markdown);
    });

    test("code stays in the code editor", () {
      expect(kindForPath("main.py"), EditorKind.code);
      expect(kindForPath("app.dart"), EditorKind.code);
      expect(kindForPath("Makefile"), EditorKind.code);
      expect(kindForPath("noext"), EditorKind.code);
    });

    test("tab model derives kind and latex language", () {
      final md = EditorTabModel.fromPath("/x/notes.md");
      expect(md.kind, EditorKind.markdown);
      expect(md.language, "markdown");
      final tex = EditorTabModel.fromPath("/x/paper.tex");
      expect(tex.kind, EditorKind.code);
      expect(tex.language, "latex");
    });
  });

  group("markdown round-trip", () {
    const sample = "# Title\n\nHello **bold** and *italic*.\n\n"
        "- one\n- two\n\n"
        "> quote\n\n"
        "```dart\nvoid main() {}\n```\n";

    test("decode/encode preserves structure", () {
      final doc = parchmentMarkdown.decode(sample);
      final back = parchmentMarkdown.encode(doc);
      expect(back, contains("# Title"));
      expect(back, contains("**bold**"));
      expect(back, contains("one"));
      expect(back, contains("void main() {}"));
      // Second pass is stable (encode is idempotent on its own output).
      final again = parchmentMarkdown.encode(parchmentMarkdown.decode(back));
      expect(again, back);
    });
  });
}
