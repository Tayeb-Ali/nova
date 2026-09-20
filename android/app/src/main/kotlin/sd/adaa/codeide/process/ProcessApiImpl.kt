package sd.adaa.codeide.process

import sd.adaa.codeide.IdeCore
import sd.adaa.codeide.bridge.ProcessApi
import sd.adaa.codeide.bridge.ProcessInfo
import sd.adaa.codeide.bridge.ProcessRequest

/** Pigeon ProcessApi wiring (task.md §21) — delegates to the service-owned manager. */
object ProcessApiImpl : ProcessApi {

    override fun startProcess(request: ProcessRequest): ProcessInfo =
        IdeCore.processes.start(request)

    override fun killProcess(pid: String) {
        IdeCore.processes.kill(pid)
    }

    override fun listProcesses(): List<ProcessInfo> = IdeCore.processes.list()
}