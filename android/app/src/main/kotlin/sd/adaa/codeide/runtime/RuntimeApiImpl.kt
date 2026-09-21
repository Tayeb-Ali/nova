package sd.adaa.codeide.runtime

import sd.adaa.codeide.IdeCore
import sd.adaa.codeide.IdeEvents
import sd.adaa.codeide.bridge.RuntimeApi
import sd.adaa.codeide.bridge.RuntimeInfo

/**
 * Pigeon RuntimeApi backend (plan.md validation §132, AllApis.kt).
 * Long operations run on a background thread and stream progress/final
 * events on the shared `sd.adaa.codeide/events` channel (task.md §28).
 */
object RuntimeApiImpl : RuntimeApi {

    private val manager get() = IdeCore.runtimes

    override fun getRuntimes(): List<RuntimeInfo> = manager.getRuntimes()

    override fun getRuntime(id: String): RuntimeInfo = manager.getRuntime(id)

    override fun installRuntime(id: String) {
        Thread {
            try {
                manager.install(
                    id = id,
                    onProgress = { line -> IdeEvents.emit(runtimeEvent("runtimeProgress", id, line)) },
                    done = { result -> finish(result, id, "install") },
                )
            } catch (t: Throwable) {
                finish(Result.failure(t), id, "install")
            }
        }.start()
    }

    override fun uninstallRuntime(id: String) {
        Thread {
            try {
                manager.uninstall(
                    id = id,
                    done = { result -> finish(result, id, "uninstall") },
                )
            } catch (t: Throwable) {
                finish(Result.failure(t), id, "uninstall")
            }
        }.start()
    }

    override fun updateRuntime(id: String) {
        Thread {
            try {
                manager.update(
                    id = id,
                    onProgress = { line -> IdeEvents.emit(runtimeEvent("runtimeProgress", id, line)) },
                    done = { result -> finish(result, id, "update") },
                )
            } catch (t: Throwable) {
                finish(Result.failure(t), id, "update")
            }
        }.start()
    }

    private fun runtimeEvent(event: String, id: String, data: String): Map<String, Any?> =
        mapOf("event" to event, "id" to id, "data" to data)

    private fun finish(result: Result<Unit>, id: String, action: String) {
        result.onSuccess {
            IdeEvents.emit(mapOf("event" to "runtimeCompleted", "id" to id))
        }.onFailure {
            IdeEvents.emit(
                mapOf(
                    "event" to "runtimeFailed",
                    "id" to id,
                    "error" to (it.message ?: "$action failed"),
                )
            )
        }
    }
}