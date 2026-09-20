package sd.adaa.nova.webpreview

/**
 * Scans process output for a serving URL (artisan serve / vite / react-scripts ...)
 * and exposes it for the in-app WebView preview (task.md §22).
 */
object PortDetector {
    private val urlPattern = Regex("""(?:127\.0\.0\.1|localhost|0\.0\.0\.0):(\d+)""")

    @Volatile
    var currentUrl: String? = null
        private set

    /** Feed stdout/stderr lines here from any managed process. */
    fun scan(text: String) {
        if (currentUrl != null) return
        val match = urlPattern.find(text) ?: return
        currentUrl = "http://127.0.0.1:${match.groupValues[1]}"
    }

    fun reset() {
        currentUrl = null
    }

    fun previewUrl(): String? = currentUrl
}