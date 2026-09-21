package sd.adaa.codeide.project

import sd.adaa.codeide.IdeCore
import sd.adaa.codeide.bridge.ProjectApi
import sd.adaa.codeide.bridge.ProjectInfo

/** Pigeon ProjectApi delegating to [IdeCore.projects]. */
object ProjectApiImpl : ProjectApi {
    override fun createProject(name: String, language: String): ProjectInfo =
        IdeCore.projects.createProject(name, language)

    override fun listProjects(): List<ProjectInfo> = IdeCore.projects.listProjects()

    override fun openProject(path: String) {
        IdeCore.projects.openProject(path)
    }

    override fun deleteProject(path: String) {
        IdeCore.projects.deleteProject(path)
    }
}