package sd.adaa.codeide.project

import android.content.Context
import org.json.JSONObject
import sd.adaa.codeide.EnvironmentManager
import sd.adaa.codeide.bridge.ProjectInfo
import java.io.File

/**
 * Owns project workspaces under `<files>/projects` (task.md §19 §23).
 * Every project carries a `.mobileide/project.json` metadata file.
 */
class ProjectManager(private val context: Context) {

    private val metaDirName = ".mobileide"
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

    /** Validates the directory exists and refreshes `.mobileide/project.json` (idempotent). */
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
        val slug = name.lowercase().replace(Regex("[^a-z0-9]+"), "-").trim('-')
            .ifBlank { "app" }
        when (language.lowercase()) {
            "php" -> File(dir, "index.php").let { if (!it.exists()) it.writeText("<?php echo \"Hello from Nova\";") }
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
            "python" -> File(dir, "main.py").let { if (!it.exists()) it.writeText("print(\"Hello from Nova\")") }
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
            "ruby" -> File(dir, "main.rb").let { if (!it.exists()) it.writeText("puts \"Hello from Nova\"\n") }
            "dart" -> {
                File(dir, "pubspec.yaml").let {
                    if (!it.exists()) it.writeText("name: $slug\nversion: 1.0.0\n\nenvironment:\n  sdk: ^3.0.0\n")
                }
                File(dir, "main.dart").let { if (!it.exists()) it.writeText("void main() {\n  print('Hello from Nova');\n}\n") }
            }
            "c" -> File(dir, TemplateC.fileName).let { if (!it.exists()) it.writeText(TemplateC.content) }
        }
    }

    private fun writeMeta(dir: File, name: String, language: String?) {
        File(dir, metaDirName).mkdirs()
        val meta = JSONObject().apply {
            put("name", name)
            if (!language.isNullOrBlank()) put("language", language) else remove("language")
        }
        File(File(dir, metaDirName), metaFileName).writeText(meta.toString())
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