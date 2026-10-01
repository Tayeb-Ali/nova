package sd.adaa.codeide.project

import android.content.Context
import org.json.JSONObject
import sd.adaa.codeide.EnvironmentManager
import sd.adaa.codeide.bridge.ProjectInfo
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Owns project workspaces under `<files>/projects` (task.md §19 §23).
 * Every project carries a `.nova/project.json` metadata file.
 */
class ProjectManager(private val context: Context) {

    private val metaDirName = ".nova"
    private val metaFileName = "project.json"

    fun projectsRoot(): File {
        val root = EnvironmentManager.projectsDir(context)
        root.mkdirs()
        return root
    }

    fun createProject(name: String, language: String): ProjectInfo {
        val safe = sanitizeName(name)
        require(safe.isNotBlank()) { "Invalid project name: '$name'" }
        val dir = File(projectsRoot(), safe)
        dir.mkdirs()
        writeMeta(dir, safe, language)
        writeTemplates(dir, safe, language)
        return ProjectInfo(safe, dir.absolutePath, language)
    }

    fun listProjects(): List<ProjectInfo> {
        val root = projectsRoot()
        if (!root.isDirectory) return emptyList()
        return (root.listFiles() ?: emptyArray())
            .filter { it.isDirectory }
            .mapNotNull { readMeta(it) }
            .sortedBy { it.name }
    }

    /** Validates the directory exists and refreshes `.nova/project.json` (idempotent). */
    fun openProject(path: String) {
        val dir = File(path)
        require(dir.isDirectory) { "Project directory does not exist: $path" }
        val meta = readMeta(dir) ?: ProjectInfo(dir.name, dir.absolutePath, null)
        writeMeta(dir, meta.name, meta.language)
    }

    fun deleteProject(path: String): Boolean {
        val dir = File(path)
        if (!dir.isDirectory) return false
        val root = projectsRoot()
        val rootPath = root.absolutePath.trimEnd('/') + "/"
        val dirPath = dir.absolutePath
        if (!dirPath.startsWith(rootPath)) return false
        if (dirPath == rootPath) return false
        return dir.deleteRecursively()
    }

    private fun sanitizeName(name: String): String =
        name.replace(Regex("[^A-Za-z0-9_\\- ]"), "_").trim()

    private fun writeTemplates(dir: File, name: String, language: String) {
        // Slug safe for module/crate names (lowercase, no spaces).
        val slug = slugify(name)
        val lang = language.lowercase()
        when (lang) {
            "php" -> {
                File(dir, "composer.json").let { f ->
                    if (!f.exists()) {
                        val pkg = JSONObject().apply {
                            put("name", slug)
                            put("description", "$name created with Nova")
                            put("scripts", JSONObject().put("start", "php index.php"))
                        }
                        f.writeText(pkg.toString(2))
                    }
                }
                File(dir, "index.php").let { if (!it.exists()) it.writeText("<?php echo \"Hello from Nova\";") }
            }
            "node" -> {
                File(dir, "package.json").let { f ->
                    if (!f.exists()) {
                        val pkg = JSONObject().apply {
                            put("name", slug)
                            put("version", "1.0.0")
                            put("scripts", JSONObject().put("start", "node index.js"))
                        }
                        f.writeText(pkg.toString(2))
                    }
                }
                File(dir, "index.js").let { if (!it.exists()) it.writeText("console.log(\"Hello from Nova\");") }
            }
            "python" -> {
                File(dir, "requirements.txt").let {
                    if (!it.exists()) it.writeText("# Add project dependencies below, one per line.\n")
                }
                File(dir, "main.py").let { if (!it.exists()) it.writeText("print(\"Hello from Nova\")") }
            }
            "go" -> {
                File(dir, "go.mod").let { if (!it.exists()) it.writeText("module $slug\n\ngo 1.21\n") }
                File(dir, "main.go").let {
                    if (!it.exists()) it.writeText("package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello from Nova\")\n}\n")
                }
            }
            "rust" -> {
                File(dir, "Cargo.toml").let {
                    if (!it.exists()) it.writeText("[package]\nname = \"$slug\"\nversion = \"0.1.0\"\nedition = \"2021\"\n")
                }
                File(dir, "src").mkdirs()
                File(dir, "src/main.rs").let { if (!it.exists()) it.writeText("fn main() {\n    println!(\"Hello from Nova\");\n}\n") }
            }
            "java" -> File(dir, "Main.java").let {
                if (!it.exists()) it.writeText("public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello from Nova\");\n    }\n}\n")
            }
            "kotlin" -> File(dir, "Main.kt").let { if (!it.exists()) it.writeText("fun main() {\n    println(\"Hello from Nova\")\n}\n") }
            "ruby" -> {
                File(dir, "Gemfile").let {
                    if (!it.exists()) it.writeText("source \"https://rubygems.org\"\n")
                }
                File(dir, "main.rb").let { if (!it.exists()) it.writeText("puts \"Hello from Nova\"\n") }
            }
            "dart" -> {
                File(dir, "pubspec.yaml").let {
                    if (!it.exists()) it.writeText("name: $slug\nversion: 1.0.0\n\nenvironment:\n  sdk: ^3.0.0\n")
                }
                File(dir, "main.dart").let { if (!it.exists()) it.writeText("void main() {\n  print('Hello from Nova');\n}\n") }
            }
            "c" -> {
                File(dir, "Makefile").let { if (!it.exists()) it.writeText(TemplateC.makefile) }
                File(dir, TemplateC.fileName).let { if (!it.exists()) it.writeText(TemplateC.content) }
            }
        }
        // Every project gets a README and a .gitignore (which always hides .nova/).
        // Guarded by exists() so re-open never clobbers user edits.
        File(dir, "README.md").let { if (!it.exists()) it.writeText(readmeFor(name, language)) }
        File(dir, ".gitignore").let { if (!it.exists()) it.writeText(gitignoreFor(lang)) }
    }

    private fun readmeFor(name: String, language: String): String {
        val hint = runFor(language)?.let { (cmd, args) ->
            if (args != null) "$cmd $args" else cmd
        }
        return buildString {
            appendLine("# $name")
            appendLine()
            appendLine("Created with Nova.")
            if (hint != null) {
                appendLine()
                appendLine("## Run")
                appendLine()
                appendLine("```sh")
                appendLine(hint)
                appendLine("```")
            }
        }
    }

    private fun gitignoreFor(language: String): String = buildString {
        appendLine(".nova/")
        when (language.lowercase()) {
            "node" -> {
                appendLine("node_modules/")
                appendLine("npm-debug.log")
            }
            "python" -> {
                appendLine("__pycache__/")
                appendLine("*.py[cod]")
                appendLine(".venv/")
            }
            "ruby" -> {
                appendLine(".bundle/")
                appendLine("vendor/bundle/")
            }
            "php" -> appendLine("vendor/")
            "rust" -> appendLine("/target/")
            "java", "kotlin" -> {
                appendLine("*.class")
                appendLine("*.jar")
                appendLine(".gradle/")
            }
            "dart" -> {
                appendLine(".dart_tool/")
                appendLine("build/")
            }
            "c" -> {
                appendLine("app")
                appendLine("*.o")
            }
        }
    }

    private fun writeMeta(dir: File, name: String, language: String?) {
        val metaDir = File(dir, metaDirName)
        metaDir.mkdirs()
        val metaFile = File(metaDir, metaFileName)
        val lang = language?.takeIf { it.isNotBlank() }?.lowercase()
        val slug = slugify(name)
        // Preserve the original creation timestamp on refresh (idempotent open).
        val createdAt = try {
            if (metaFile.exists()) {
                JSONObject(metaFile.readText()).optString("createdAt")
                    .takeIf { it.isNotBlank() }
            } else null
        } catch (e: Exception) {
            null
        } ?: utcNow()
        val meta = JSONObject().apply {
            put("name", name)
            if (lang != null) put("language", lang) else remove("language")
            put("schemaVersion", 1)
            put("createdAt", createdAt)
            put("slug", slug)
            val entry = lang?.let { entryPointFor(it) }
            if (entry != null) put("entryPoint", entry) else remove("entryPoint")
            val run = lang?.let { runFor(it) }
            if (run != null) {
                put("run", JSONObject().apply {
                    put("command", run.first)
                    if (run.second != null) put("args", run.second) else remove("args")
                })
            } else remove("run")
            val toolchain = lang?.let { toolchainFor(it) }
            if (toolchain != null) {
                put("toolchain", JSONObject().apply {
                    put("runtimeId", toolchain.first)
                    put("executable", toolchain.second)
                    put("packageName", toolchain.third)
                })
            } else remove("toolchain")
            val pm = lang?.let { packageManagerFor(it) }
            if (pm != null) put("packageManager", pm) else remove("packageManager")
        }
        metaFile.writeText(meta.toString())
    }

    private fun slugify(name: String): String =
        name.lowercase().replace(Regex("[^a-z0-9]+"), "-").trim('-')
            .ifBlank { "app" }

    private fun utcNow(): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        fmt.timeZone = TimeZone.getTimeZone("UTC")
        return fmt.format(Date())
    }

    /** Default entry file created by [writeTemplates] for each language. */
    private fun entryPointFor(language: String): String? = when (language.lowercase()) {
        "php" -> "index.php"
        "node" -> "index.js"
        "python" -> "main.py"
        "go" -> "main.go"
        "rust" -> "src/main.rs"
        "ruby" -> "main.rb"
        "java" -> "Main.java"
        "kotlin" -> "Main.kt"
        "dart" -> "main.dart"
        "c" -> "main.c"
        else -> null
    }

    /** Default run task, mirroring the commands detected in `task_detector`. */
    private fun runFor(language: String): Pair<String, String?>? = when (language.lowercase()) {
        "php" -> "php" to "index.php"
        "node" -> "npm" to "run start"
        "python" -> "python" to "main.py"
        "go" -> "go" to "run ."
        "rust" -> "cargo" to "run"
        "ruby" -> "ruby" to "main.rb"
        "java" -> "sh" to "-c \"javac Main.java && java Main\""
        "kotlin" -> "sh" to "-c \"kotlinc Main.kt -include-runtime -d app.jar && java -jar app.jar\""
        "dart" -> "dart" to "main.dart"
        "c" -> "sh" to "-c \"cc main.c -o app && ./app\""
        else -> null
    }

    /** (runtimeId, executable, apt package) mirroring `RuntimeRegistry`. */
    private fun toolchainFor(language: String): Triple<String, String, String>? =
        when (language.lowercase()) {
            "php" -> Triple("php", "php", "php")
            "node" -> Triple("node", "node", "nodejs")
            "python" -> Triple("python", "python3", "python")
            "go" -> Triple("go", "go", "golang")
            "rust" -> Triple("rust", "rustc", "rust")
            "ruby" -> Triple("ruby", "ruby", "ruby")
            "java" -> Triple("java", "java", "openjdk-25")
            "kotlin" -> Triple("kotlin", "kotlinc", "kotlin")
            "dart" -> Triple("dart", "dart", "dart")
            "c" -> Triple("c", "cc", "clang")
            else -> null
        }

    private fun packageManagerFor(language: String): String? = when (language.lowercase()) {
        "node" -> "npm"
        "python" -> "pip"
        "php" -> "composer"
        "ruby" -> "gem"
        else -> null
    }

    private fun readMeta(dir: File): ProjectInfo? {
        if (!dir.isDirectory) return null
        val metaFile = File(File(dir, metaDirName), metaFileName)
        var name = dir.name
        var language: String? = null
        if (metaFile.exists()) {
            try {
                val json = JSONObject(metaFile.readText())
                name = json.optString("name").ifBlank { dir.name }
                language = json.optString("language").takeIf { it.isNotBlank() }
            } catch (e: Exception) {
                // fall back to directory name
            }
        }
        return ProjectInfo(name, dir.absolutePath, language)
    }
}