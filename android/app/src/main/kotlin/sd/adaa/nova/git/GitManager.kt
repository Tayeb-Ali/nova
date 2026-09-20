package sd.adaa.nova.git

import android.content.Context
import sd.adaa.nova.EnvironmentManager
import sd.adaa.nova.bridge.GitStatus
import sd.adaa.nova.process.ShellExecutor

/**
 * Git integration through the embedded git binary (task.md §24).
 * All commands run via ShellExecutor inside the project directory with the
 * embedded runtime environment.
 */
class GitManager(private val context: Context) {

    private val shell = ShellExecutor(context)

    fun status(projectPath: String): GitStatus {
        val result = runGit(
            projectPath,
            listOf("status", "--porcelain=v1", "-b", "--untracked-files=all"),
        )
        if (result.isFailure) {
            return GitStatus(
                branch = "",
                modified = emptyList(),
                added = emptyList(),
                deleted = emptyList(),
                untracked = emptyList(),
                error = result.exceptionOrNull()?.message ?: "git status failed",
            )
        }
        val output = result.getOrThrow()
        val modified = mutableListOf<String>()
        val added = mutableListOf<String>()
        val deleted = mutableListOf<String>()
        val untracked = mutableListOf<String>()
        var branch = ""
        output.lines().forEach { line ->
            if (line.isBlank()) return@forEach
            when {
                line.startsWith("##") -> branch = parseBranch(line)
                line.startsWith("??") -> untracked.add(pathOf(line, 2))
                line.length >= 3 -> {
                    val index = line[0]
                    val worktree = line[1]
                    val path = line.substring(3).substringBefore(" -> ")
                    when {
                        index == 'M' || worktree == 'M' -> modified.add(path)
                        index == 'A' || worktree == 'A' -> added.add(path)
                        index == 'D' || worktree == 'D' -> deleted.add(path)
                    }
                }
            }
        }
        return GitStatus(branch, modified, added, deleted, untracked)
    }

    fun add(projectPath: String, paths: List<String>) {
        if (paths.isEmpty()) return
        runGit(projectPath, listOf("add") + paths).getOrThrow()
    }

    fun commit(projectPath: String, message: String) {
        runGit(projectPath, listOf("add", "-A")).getOrThrow()
        runGit(projectPath, listOf("commit", "-m", message)).getOrThrow()
    }

    /** Staged + unstaged diff merged. */
    fun diff(projectPath: String): String {
        val staged = runGit(projectPath, listOf("diff", "--cached")).getOrNull()
        val unstaged = runGit(projectPath, listOf("diff")).getOrNull()
        return listOf(staged, unstaged)
            .filterNotNull()
            .filter { it.isNotBlank() }
            .joinToString("\n")
    }

    private fun runGit(projectPath: String, args: List<String>): Result<String> =
        shell.execute(
            command = "git",
            args = args,
            cwd = projectPath,
            env = EnvironmentManager.buildEnvironment(context, projectPath),
        )

    private fun parseBranch(header: String): String {
        var s = header.substring(2).trim()
        if (s.startsWith("No commits yet on ")) return s.removePrefix("No commits yet on ").trim()
        val upstream = s.indexOf("...")
        if (upstream >= 0) s = s.substring(0, upstream)
        else {
            val space = s.indexOf(' ')
            if (space >= 0) s = s.substring(0, space)
        }
        return s
    }

    private fun pathOf(line: String, statusWidth: Int): String {
        var path = line.substring(statusWidth).trim()
        path = path.trim('"')
        path = path.replace("\\\"", "\"").replace("\\\\", "\\")
        return path
    }
}