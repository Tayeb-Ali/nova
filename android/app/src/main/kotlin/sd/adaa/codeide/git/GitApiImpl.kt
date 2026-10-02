package sd.adaa.codeide.git

import sd.adaa.codeide.IdeCore
import sd.adaa.codeide.bridge.GitApi
import sd.adaa.codeide.bridge.GitStatus

/** Pigeon GitApi delegating to [IdeCore.git]. */
object GitApiImpl : GitApi {
    override fun status(projectPath: String): GitStatus = IdeCore.git.status(projectPath)

    override fun add(projectPath: String, paths: List<String>) {
        IdeCore.git.add(projectPath, paths)
    }

    override fun commit(projectPath: String, message: String) {
        IdeCore.git.commit(projectPath, message)
    }

    override fun diff(projectPath: String): String = IdeCore.git.diff(projectPath)

    override fun listBranches(projectPath: String): List<String> =
        IdeCore.git.listBranches(projectPath)

    override fun currentBranch(projectPath: String): String =
        IdeCore.git.currentBranch(projectPath)

    override fun checkout(projectPath: String, branch: String) {
        IdeCore.git.checkout(projectPath, branch)
    }

    override fun createBranch(projectPath: String, branch: String) {
        IdeCore.git.createBranch(projectPath, branch)
    }

    override fun deleteBranch(projectPath: String, branch: String) {
        IdeCore.git.deleteBranch(projectPath, branch)
    }

    override fun stashList(projectPath: String): List<String> =
        IdeCore.git.stashList(projectPath)

    override fun stashSave(projectPath: String, message: String) {
        IdeCore.git.stashSave(projectPath, message)
    }

    override fun stashPop(projectPath: String, index: Long) {
        IdeCore.git.stashPop(projectPath, index)
    }

    override fun stashDrop(projectPath: String, index: Long) {
        IdeCore.git.stashDrop(projectPath, index)
    }

    override fun clone(url: String, directory: String) {
        IdeCore.git.clone(url, directory)
    }

    override fun fetch(projectPath: String) {
        IdeCore.git.fetch(projectPath)
    }

    override fun pull(projectPath: String) {
        IdeCore.git.pull(projectPath)
    }

    override fun push(projectPath: String) {
        IdeCore.git.push(projectPath)
    }

    override fun generateSshKey(): String = IdeCore.git.generateSshKey()

    override fun getSshPublicKey(): String = IdeCore.git.getSshPublicKey()
}