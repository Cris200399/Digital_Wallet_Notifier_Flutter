package com.example.yape_notifier

import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class NotificationListenerForegroundService : Service() {

    companion object {
        private const val TAG = "DWN_ForegroundService"
        const val ACTION_START = "com.example.yape_notifier.START_FOREGROUND"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called - iniciando foreground service")

        try {
            createNotificationChannel()

            val notification = NotificationCompat.Builder(this, "dwn_listener_channel")
                .setContentTitle("DWN")
                .setContentText("Escuchando pagos")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setOngoing(true)
                .build()

            Log.d(TAG, "Notificación construida, iniciando foreground")
            startForeground(2, notification)
            Log.d(TAG, "Foreground iniciado exitosamente")

        } catch (e: Exception) {
            Log.e(TAG, "Error al iniciar foreground service: ${e.message}", e)
        }

        // START_STICKY hace que Android reinicie el servicio si lo mata
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "dwn_listener_channel",
                "Digital Wallet Notifier",
                NotificationManager.IMPORTANCE_MIN
            )
            channel.description = "Notificaciones de pagos en segundo plano"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel creado")
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called - servicio fue destruido, reiniciando...")
        super.onDestroy()
        // Intenta reiniciar el servicio
        val restartIntent = Intent(this, NotificationListenerForegroundService::class.java)
        startService(restartIntent)
    }

    override fun onBind(intent: Intent?) = null
}