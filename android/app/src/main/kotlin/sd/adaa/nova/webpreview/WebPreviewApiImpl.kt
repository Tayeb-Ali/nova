package sd.adaa.nova.webpreview

import sd.adaa.nova.bridge.WebPreviewApi

/** Pigeon WebPreviewApi surfacing the detected preview URL (task.md §22). */
object WebPreviewApiImpl : WebPreviewApi {
    override fun previewUrl(): String? = PortDetector.previewUrl()
}