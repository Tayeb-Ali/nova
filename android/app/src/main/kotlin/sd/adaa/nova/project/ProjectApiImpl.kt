package sd.adaa.nova.project

import sd.adaa.nova.IdeCore
import sd.adaa.nova.bridge.ProjectApi
import sd.adaa.nova.bridge.ProjectInfo

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