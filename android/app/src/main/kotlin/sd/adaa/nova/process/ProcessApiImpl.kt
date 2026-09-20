package sd.adaa.nova.process

import sd.adaa.nova.IdeCore
import sd.adaa.nova.bridge.ProcessApi
import sd.adaa.nova.bridge.ProcessInfo
import sd.adaa.nova.bridge.ProcessRequest

/** Pigeon ProcessApi wiring (task.md §21) — delegates to the service-owned manager. */
object ProcessApiImpl : ProcessApi {

    override fun startProcess(request: ProcessRequest): ProcessInfo =
        IdeCore.processes.start(request)

    override fun killProcess(pid: String) {
        IdeCore.processes.kill(pid)
    }

    override fun listProcesses(): List<ProcessInfo> = IdeCore.processes.list()
}