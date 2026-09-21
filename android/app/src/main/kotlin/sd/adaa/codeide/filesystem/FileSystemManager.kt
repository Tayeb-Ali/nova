package sd.adaa.codeide.filesystem

import sd.adaa.codeide.bridge.FileEntry
import java.io.File

/**
 * Real file operations for the IDE workspace (task.md §23). Operates on absolute
 * paths; relative paths are resolved against [workspaceRoot] when set.
 */
object FileSystemManager {

    /** Optional base used to resolve relative paths. */
    @Volatile
    var workspaceRoot: File? = null

    private fun resolve(path: String): File {
        val f = File(path)
        if (f.isAbsolute) return f.absoluteFile
        val root = workspaceRoot
        return if (root != null) File(root, path).absoluteFile else f.absoluteFile
    }

    /** List a directory sorted directories-first, then by name. */
    fun listFiles(path: String): List<FileEntry> {
        val dir = resolve(path)
        if (!dir.isDirectory) return emptyList()
        return (dir.listFiles() ?: emptyArray())
            .map { f ->
                FileEntry(
                    name = f.name,
                    path = f.absolutePath,
                    isDirectory = f.isDirectory,
                    size = if (f.isFile) f.length() else null,
                )
            }
            .sortedWith(compareBy({ !it.isDirectory }, { it.name }))
    }

    fun readFile(path: String): String = resolve(path).readText()

    fun writeFile(path: String, content: String) {
        val f = resolve(path)
        f.parentFile?.mkdirs()
        f.writeText(content)
    }

    fun rename(oldPath: String, newPath: String): Boolean {
        val from = resolve(oldPath)
        val to = resolve(newPath)
        to.parentFile?.mkdirs()
        return from.renameTo(to)
    }

    fun delete(path: String): Boolean {
        val f = resolve(path)
        if (!f.exists()) return false
        return f.deleteRecursively()
    }

    fun mkdir(path: String): Boolean {
        val f = resolve(path)
        return f.mkdirs() || f.isDirectory
    }
}