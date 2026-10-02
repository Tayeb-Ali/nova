package sd.adaa.codeide.git

import android.content.Context
import sd.adaa.codeide.EnvironmentManager
import sd.adaa.codeide.bridge.GitStatus
import sd.adaa.codeide.process.ShellExecutor
import java.io.File

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

    fun listBranches(projectPath: String): List<String> =
        runGit(projectPath, listOf("branch", "--format=%(refname:short)"))
            .getOrThrow()
            .lines()
            .map { it.trim() }
            .filter { it.isNotEmpty() }

    fun currentBranch(projectPath: String): String =
        runGit(projectPath, listOf("rev-parse", "--abbrev-ref", "HEAD"))
            .getOrThrow()
            .trim()

    fun checkout(projectPath: String, branch: String) {
        runGit(projectPath, listOf("checkout", branch)).getOrThrow()
    }

    fun createBranch(projectPath: String, branch: String) {
        runGit(projectPath, listOf("checkout", "-b", branch)).getOrThrow()
    }

    fun deleteBranch(projectPath: String, branch: String) {
        runGit(projectPath, listOf("branch", "-d", branch)).getOrThrow()
    }

    fun stashList(projectPath: String): List<String> =
        runGit(projectPath, listOf("stash", "list"))
            .getOrThrow()
            .lines()
            .map { it.trim() }
            .filter { it.isNotEmpty() }

    fun stashSave(projectPath: String, message: String) {
        val args = if (message.isBlank()) {
            listOf("stash", "push")
        } else {
            listOf("stash", "push", "-m", message)
        }
        runGit(projectPath, args).getOrThrow()
    }

    fun stashPop(projectPath: String, index: Long) {
        runGit(projectPath, listOf("stash", "pop", "stash@{$index}")).getOrThrow()
    }

    fun stashDrop(projectPath: String, index: Long) {
        runGit(projectPath, listOf("stash", "drop", "stash@{$index}")).getOrThrow()
    }

    // ---- Remote operations over SSH (Phase 1: SSH first, no HTTPS tokens).
    //
    // The key lives at home/.ssh/id_nova_ed25519 (created on demand via the
    // embedded openssh `ssh-keygen`). Every remote command runs with
    // GIT_SSH_COMMAND in batch mode so a missing key/host fails fast with a
    // mappable error instead of hanging on an interactive prompt (there is
    // no TTY on device).

    private val sshDir: File
        get() = File(EnvironmentManager.home(context), ".ssh")

    private val sshKey: File
        get() = File(sshDir, "id_nova_ed25519")

    fun getSshPublicKey(): String {
        val pub = File(sshKey.absolutePath + ".pub")
        return if (pub.exists()) pub.readText().trim() else ""
    }

    fun generateSshKey(): String {
        val existing = getSshPublicKey()
        if (existing.isNotEmpty()) return existing
        if (!sshDir.exists() && !sshDir.mkdirs()) {
            error("Cannot create ${sshDir.absolutePath}")
        }
        shell.execute(
            command = "ssh-keygen",
            args = listOf("-t", "ed25519", "-N", "", "-f", sshKey.absolutePath),
            env = EnvironmentManager.buildEnvironment(context),
            timeoutMs = 60_000,
        ).getOrThrow()
        return getSshPublicKey().ifBlank {
            error("ssh-keygen produced no public key")
        }
    }

    /** Extra env forcing non-interactive SSH with our key. */
    private fun gitSshEnv(): Map<String, String> {
        val key = sshKey.absolutePath
        return mapOf(
            "GIT_SSH_COMMAND" to
                "ssh -i $key -o BatchMode=yes " +
                "-o StrictHostKeyChecking=accept-new -o ConnectTimeout=20",
        )
    }

    private fun runGitRemote(
        projectPath: String?,
        args: List<String>,
        timeoutMs: Long = 300_000,
    ): Result<String> = shell.execute(
        command = "git",
        args = args,
        cwd = projectPath,
        env = EnvironmentManager.buildEnvironment(context, projectPath) + gitSshEnv(),
        timeoutMs = timeoutMs,
    )

    fun clone(url: String, directory: String) {
        val dest = File(directory)
        if (dest.exists()) error("Directory already exists: $directory")
        val parent = dest.parentFile ?: error("Invalid directory: $directory")
        if (!parent.exists() && !parent.mkdirs()) {
            error("Cannot create parent directory: ${parent.absolutePath}")
        }
        runGitRemote(
            projectPath = null,
            args = listOf("clone", url, directory),
            timeoutMs = 600_000,
        ).onFailure { throw remapRemoteError(it, url) }.getOrThrow()
    }

    fun fetch(projectPath: String) {
        runGitRemote(projectPath, listOf("fetch", "--all", "--prune"))
            .onFailure { throw remapRemoteError(it, null) }.getOrThrow()
    }

    fun pull(projectPath: String) {
        runGitRemote(projectPath, listOf("pull", "--ff-only"))
            .onFailure { throw remapRemoteError(it, null) }.getOrThrow()
    }

    fun push(projectPath: String) {
        runGitRemote(projectPath, listOf("push"))
            .onFailure { throw remapRemoteError(it, null) }.getOrThrow()
    }

    /**
     * Maps raw git/ssh failures to actionable messages. Merge conflicts are
     * reported as-is (conflict UI is out of scope); everything else keeps
     * the raw tail for diagnosability.
     */
    private fun remapRemoteError(e: Throwable, url: String?): Throwable {
        val msg = e.message.orEmpty()
        val hint = when {
            msg.contains("Permission denied (publickey)", ignoreCase = true) ->
                "SSH authentication failed. Add this app's public key " +
                    "(Git > Remote > SSH key) to your hosting account and retry."
            msg.contains("Could not resolve hostname", ignoreCase = true) ||
                msg.contains("Network is unreachable", ignoreCase = true) ||
                msg.contains("Connection timed out", ignoreCase = true) ||
                msg.contains("Temporary failure in name resolution", ignoreCase = true) ->
                "Network unreachable. Check the connection and retry."
            msg.contains("Host key verification failed", ignoreCase = true) ->
                "SSH host key rejected. Retry once to accept the host key."
            msg.contains("CONFLICT", ignoreCase = true) ||
                msg.contains("Automatic merge failed", ignoreCase = true) ->
                "Merge conflict: resolve it in the terminal, then commit."
            msg.contains("no upstream", ignoreCase = true) ||
                msg.contains("has no upstream branch", ignoreCase = true) ->
                "No upstream branch. Push once from the terminal with " +
                    "`git push -u origin <branch>`."
            msg.contains("already exists", ignoreCase = true) -> msg
            else -> msg.ifBlank { "Git remote operation failed" }
        }
        val where = if (url != null) " ($url)" else ""
        return RuntimeException("$hint$where\n$msg".trim())
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