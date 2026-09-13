package sd.adaa.nova

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Handles APK install + external URL intents for Nova.
 *
 * Dart side (termux_installer.dart) talks over channel "sd.adaa.codeide/install":
 * - installApk(path) -> Bool (fires ACTION_VIEW via FileProvider)
 * - canRequestInstalls -> Bool
 * - openInstallPermissionSettings -> opens "install unknown apps" page for Nova
 * - openUrl(url) -> opens the browser
 */
object InstallBridge {
    const val CHANNEL_NAME = "sd.adaa.codeide/install"

    fun configure(flutterEngine: FlutterEngine, activity: MainActivity) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("ARG", "missing path", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = FileProvider.getUriForFile(
                            activity,
                            "${activity.packageName}.fileprovider",
                            File(path)
                        )
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL", e.message, null)
                    }
                }
                "canRequestInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(activity.packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSettings" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:${activity.packageName}")
                    ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                    activity.startActivity(intent)
                    result.success(true)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url == null) {
                        result.error("ARG", "missing url", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(
                        Intent.ACTION_VIEW,
                        Uri.parse(url)
                    ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                    activity.startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
