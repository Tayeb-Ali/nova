package sd.adaa.nova

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder

/**
 * Foreground service that keeps terminal sessions / background processes alive
 * when the UI is backgrounded (task.md §25 §26).
 */
class IdeService : Service() {

    companion object {
        private const val CHANNEL_ID = "ide_runtime"
        private const val NOTIFICATION_ID = 42
        private var foregroundStarted = false

        fun start(context: Context) {
            val intent = Intent(context, IdeService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    override fun onBind(intent: Intent): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        IdeCore.init(this)
        startForegroundCompat()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Safety net: ensure startForeground is always called promptly (API 34+)
        startForegroundCompat()
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        foregroundStarted = false
    }

    private fun startForegroundCompat() {
        if (foregroundStarted) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val channel = NotificationChannel(
                    CHANNEL_ID, "Nova Runtime", NotificationManager.IMPORTANCE_LOW
                )
                manager.createNotificationChannel(channel)
            }
            val launch = packageManager.getLaunchIntentForPackage(packageName)?.let {
                PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE)
            }
            val notification: Notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ID)
                    .setContentTitle("Nova IDE")
                    .setContentText("Runtime active")
                    .setContentIntent(launch)
                    .setSmallIcon(android.R.drawable.ic_popup_sync)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
                    .setContentTitle("Nova IDE")
                    .setContentText("Runtime active")
                    .setContentIntent(launch)
                    .setSmallIcon(android.R.drawable.ic_popup_sync)
                    .build()
            }
            startForeground(NOTIFICATION_ID, notification)
            foregroundStarted = true
        } catch (e: Exception) {
            android.util.Log.e("IdeService", "startForeground failed: ${e.message}")
        }
    }
}