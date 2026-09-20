package sd.adaa.nova.filesystem

import sd.adaa.nova.bridge.FileApi
import sd.adaa.nova.bridge.FileEntry

/** Pigeon FileApi delegating to [FileSystemManager]. */
object FileApiImpl : FileApi {
    override fun readFile(path: String): String = FileSystemManager.readFile(path)

    override fun writeFile(path: String, content: String) {
        FileSystemManager.writeFile(path, content)
    }

    override fun listFiles(path: String): List<FileEntry> = FileSystemManager.listFiles(path)

    override fun rename(oldPath: String, newPath: String): Boolean =
        FileSystemManager.rename(oldPath, newPath)

    override fun delete(path: String): Boolean = FileSystemManager.delete(path)

    override fun mkdir(path: String): Boolean = FileSystemManager.mkdir(path)
}