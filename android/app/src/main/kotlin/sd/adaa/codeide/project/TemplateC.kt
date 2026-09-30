package sd.adaa.codeide.project

/**
 * Hello-world template for C projects (NEXT_PLAN item 1.1).
 *
 * Mirrors the per-language snippets in [ProjectManager.writeTemplates]:
 * a single `main.c` printing "Hello from Nova", built/run on device with
 * the `cc` toolchain (`cc main.c -o app && ./app`, see `task_detector`).
 * Wiring (a `"c"` branch in `writeTemplates`) is a one-liner follow-up.
 */
object TemplateC {
    const val fileName = "main.c"

    const val content =
        "#include <stdio.h>\n" +
            "\n" +
            "int main(void) {\n" +
            "    printf(\"Hello from Nova\\n\");\n" +
            "    return 0;\n" +
            "}\n"
}
