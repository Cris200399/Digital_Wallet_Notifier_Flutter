package com.example.yape_notifier

import android.app.Activity
import android.os.PowerManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    companion object {
        private const val FOREGROUND_CHANNEL = "com.example.yape_notifier/foreground"
        private const val BATTERY_CHANNEL = "com.example.yape_notifier/battery"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal para iniciar el foreground service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        startForegroundService()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Canal para verificar y pedir exención de batería
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBatteryOptimizationDisabled" -> {
                        result.success(isBatteryOptimizationDisabled())
                    }
                    "openBatterySettings" -> {
                        openBatterySettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startForegroundService() {
        val serviceIntent = Intent(this, NotificationListenerForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openBatterySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent().apply {
                action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                data = Uri.parse("package:$packageName")
            }
            try {
                startActivity(intent)
            } catch (e: Exception) {
                // Si no funciona, abre la pantalla general de batería
                val fallbackIntent = Intent().apply {
                    action = Settings.ACTION_BATTERY_SAVER_SETTINGS
                }
                try {
                    startActivity(fallbackIntent)
                } catch (e: Exception) {
                    // Último resort: abre los ajustes generales
                    val settingsIntent = Intent().apply {
                        action = Settings.ACTION_SETTINGS
                    }
                    startActivity(settingsIntent)
                }
            }
        }
    }
}