package sd.adaa.codeide.project

/**
 * Hello-world template for C projects (NEXT_PLAN item 1.1).
 *
 * Mirrors the per-language snippets in [ProjectManager.writeTemplates]:
 * a single `main.c` printing "Hello from Nova", built/run on device with
 * the `cc` toolchain (`cc main.c -o app && ./app`, see `task_detector`),
 * plus a small `Makefile` (`make`, `make run`, `make clean`).
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

    /** Simple `make` wrapper so C projects build/run/clean without typing the `cc` line. */
    const val makefile =
        "APP = app\n" +
            "CC = cc\n" +
            "CFLAGS = -Wall -O2\n" +
            "\n" +
            "$(APP): main.c\n" +
            "\t$(CC) $(CFLAGS) main.c -o $(APP)\n" +
            "\n" +
            "run: $(APP)\n" +
            "\t./$(APP)\n" +
            "\n" +
            "clean:\n" +
            "\trm -f $(APP)\n" +
            "\n" +
            ".PHONY: run clean\n"
}
