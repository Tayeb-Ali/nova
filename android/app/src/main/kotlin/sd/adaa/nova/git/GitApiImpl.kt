package sd.adaa.nova.git

import sd.adaa.nova.IdeCore
import sd.adaa.nova.bridge.GitApi
import sd.adaa.nova.bridge.GitStatus

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
}