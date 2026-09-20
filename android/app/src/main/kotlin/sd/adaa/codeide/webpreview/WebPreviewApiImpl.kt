package sd.adaa.codeide.webpreview

import sd.adaa.codeide.bridge.WebPreviewApi

/** Pigeon WebPreviewApi surfacing the detected preview URL (task.md §22). */
object WebPreviewApiImpl : WebPreviewApi {
    override fun previewUrl(): String? = PortDetector.previewUrl()
}