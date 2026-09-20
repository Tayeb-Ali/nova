package sd.adaa.nova

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import sd.adaa.nova.bridge.FileApi
import sd.adaa.nova.bridge.GitApi
import sd.adaa.nova.bridge.ProcessApi
import sd.adaa.nova.bridge.ProjectApi
import sd.adaa.nova.bridge.RuntimeApi
import sd.adaa.nova.bridge.SetupApi
import sd.adaa.nova.bridge.SetupStatus
import sd.adaa.nova.bridge.TerminalApi
import sd.adaa.nova.bridge.WebPreviewApi
import sd.adaa.nova.filesystem.FileApiImpl
import sd.adaa.nova.git.GitApiImpl
import sd.adaa.nova.process.ProcessApiImpl
import sd.adaa.nova.project.ProjectApiImpl
import sd.adaa.nova.runtime.RuntimeApiImpl
import sd.adaa.nova.terminal.TerminalApiImpl
import sd.adaa.nova.webpreview.WebPreviewApiImpl

/**
 * Registers every Pigeon API + the events stream (task.md §27 §28).
 * Owned by the integration layer — feature agents must not edit this file.
 */
object AllApis {
    fun register(messenger: BinaryMessenger, context: Context) {
        EventChannel(messenger, EnvironmentManager.EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    IdeEvents.sink = events
                }

                override fun onCancel(arguments: Any?) {
                    IdeEvents.sink = null
                }
            })

        SetupApi.setUp(messenger, SetupApiImpl)
        RuntimeApi.setUp(messenger, RuntimeApiImpl)
        TerminalApi.setUp(messenger, TerminalApiImpl)
        ProcessApi.setUp(messenger, ProcessApiImpl)
        ProjectApi.setUp(messenger, ProjectApiImpl)
        FileApi.setUp(messenger, FileApiImpl)
        GitApi.setUp(messenger, GitApiImpl)
        WebPreviewApi.setUp(messenger, WebPreviewApiImpl)
    }
}

object SetupApiImpl : SetupApi {
    override fun getStatus(): SetupStatus = IdeCore.bootstrap.getStatus()

    override fun startSetup() {
        IdeCore.bootstrap.start(
            onProgress = { phase, fraction ->
                IdeEvents.emit(
                    mapOf(
                        "event" to "setupProgress",
                        "phase" to phase,
                        "fraction" to fraction.toDouble(),
                    )
                )
            },
            done = { result ->
                result.onSuccess {
                    IdeEvents.emit(mapOf("event" to "setupCompleted"))
                }.onFailure {
                    IdeEvents.emit(
                        mapOf(
                            "event" to "setupFailed",
                            "error" to (it.message ?: "setup failed"),
                        )
                    )
                }
            },
        )
    }
}