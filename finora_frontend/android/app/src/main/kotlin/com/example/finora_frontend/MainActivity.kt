package com.example.finora_frontend

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val platformVersionChannel = "com.finora.app/platform_version"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel para obtener información de la versión de Android
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, platformVersionChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidVersion" -> {
                        // Retorna el API level de Android
                        result.success(Build.VERSION.SDK_INT)
                    }
                    "getAndroidVersionName" -> {
                        // Retorna el nombre de la versión (e.g., "8.0.0")
                        result.success(Build.VERSION.RELEASE)
                    }
                    "getDeviceInfo" -> {
                        // Retorna información completa del dispositivo
                        val deviceInfo = mapOf(
                            "apiLevel" to Build.VERSION.SDK_INT,
                            "versionName" to Build.VERSION.RELEASE,
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "device" to Build.DEVICE,
                            "brand" to Build.BRAND,
                            "sdkInt" to Build.VERSION.SDK_INT
                        )
                        result.success(deviceInfo)
                    }
                    "isAtLeastVersion" -> {
                        // Verifica si el dispositivo tiene al menos cierta versión
                        val requiredVersion = call.argument<Int>("version")
                        if (requiredVersion != null) {
                            result.success(Build.VERSION.SDK_INT >= requiredVersion)
                        } else {
                            result.error("INVALID_ARGUMENT", "Version argument is required", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
