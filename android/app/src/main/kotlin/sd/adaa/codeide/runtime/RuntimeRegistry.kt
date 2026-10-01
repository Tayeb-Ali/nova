package sd.adaa.codeide.runtime

/**
 * Static metadata for a managed runtime (task.md §4 §13).
 * New runtimes are added here only — no architecture change (plan.md §29 rule 8).
 */
data class RuntimeDefinition(
    val id: String,
    val displayName: String,
    val executable: String,
    val packageName: String,
    val aliases: List<String>,
    /** Args that print the version (first non-blank line). Most tools take
     *  --version, but e.g. `go` needs `go version` and `tcc` needs `-v`. */
    val versionArgs: List<String> = listOf("--version"),
    /**
     * True for install packs (metapackages): [executable] is unused and
     * installation state derives from [memberBins] instead. Removing a pack
     * only removes the metapackage itself (apt behavior), never binaries.
     */
    val isPack: Boolean = false,
    /** bin/ names that must all exist for a pack to count as installed. */
    val memberBins: List<String> = emptyList(),
    /**
     * Device ABIs this runtime is built for (e.g. listOf("arm64-v8a")).
     * Empty = all ABIs. Used for languages skipped on x86_64
     * (go/rust/java/dart/c + their packs).
     */
    val supportedAbis: List<String> = emptyList(),
    /**
     * Extra apt packages fetched alongside [packageName] (Termux splits some
     * toolchains: `npm` ships separately from `nodejs`). Downloaded by the
     * same `apt install --download-only` call and unpacked together.
     */
    val extraPackages: List<String> = emptyList(),
)

object RuntimeRegistry {
    /** ABIs with full language packages (x86_64 batch skipped these). */
    private val arm64Only = listOf("arm64-v8a")

    val all: List<RuntimeDefinition> = listOf(
        RuntimeDefinition("php", "PHP", "php", "php", listOf("php")),
        RuntimeDefinition("node", "Node.js", "node", "nodejs", listOf("node", "npm", "npx"),
            extraPackages = listOf("npm")),
        RuntimeDefinition("python", "Python", "python3", "python", listOf("python", "python3", "pip")),
        RuntimeDefinition("git", "Git", "git", "git", listOf("git")),
        RuntimeDefinition("composer", "Composer", "composer", "composer", listOf("composer")),
        RuntimeDefinition("openssh", "OpenSSH", "ssh", "openssh", listOf("ssh", "scp", "sftp"),
            listOf("-V")),
        // ---- Phase 3 language pack (built from source for our prefix) ----
        // Package names verified against the Nova apt repo after the build;
        // install/update/remove flow is unchanged (apt by packageName).
        // x86_64 has no packages for these (skipped batch): arm64-only.
        RuntimeDefinition("go", "Go", "go", "golang", listOf("go", "gofmt"), listOf("version"),
            supportedAbis = arm64Only),
        RuntimeDefinition("rust", "Rust", "rustc", "rust", listOf("rustc", "cargo", "rustdoc"),
            supportedAbis = arm64Only),
        RuntimeDefinition("ruby", "Ruby", "ruby", "ruby", listOf("ruby", "gem", "irb")),
        RuntimeDefinition("java", "Java", "java", "openjdk-25", listOf("java", "javac", "jar"),
            supportedAbis = arm64Only),
        RuntimeDefinition("kotlin", "Kotlin", "kotlinc", "kotlin", listOf("kotlinc", "kotlin"),
            listOf("-version")),
        RuntimeDefinition("dart", "Dart", "dart", "dart", listOf("dart"),
            supportedAbis = arm64Only),
        // Clang 21 (apt package `clang`): C/C++ frontend; version probing is
        // the default `cc --version` (first line: "clang version 21…").
        RuntimeDefinition("c", "C", "cc", "clang", listOf("cc", "clang", "clang++"),
            supportedAbis = arm64Only),
        // ---- Install packs (metapackages, one-tap groups) ----
        RuntimeDefinition("nova-web", "Web Pack", "", "nova-web", emptyList(), isPack = true,
            memberBins = listOf("php", "composer", "ruby", "node", "npm")),
        RuntimeDefinition("nova-systems", "Systems Pack", "", "nova-systems", emptyList(), isPack = true,
            memberBins = listOf("rustc", "go", "make", "cmake"), supportedAbis = arm64Only),
        RuntimeDefinition("nova-jvm", "JVM Pack", "", "nova-jvm", emptyList(), isPack = true,
            memberBins = listOf("java", "kotlinc"), supportedAbis = arm64Only),
        RuntimeDefinition("nova-python", "Python Pack", "", "nova-python", emptyList(), isPack = true,
            memberBins = listOf("python3", "pip")),
        RuntimeDefinition("nova-dart", "Dart Pack", "", "nova-dart", emptyList(), isPack = true,
            memberBins = listOf("dart"), supportedAbis = arm64Only),
    )

    fun get(id: String): RuntimeDefinition? = all.firstOrNull { it.id == id }
}