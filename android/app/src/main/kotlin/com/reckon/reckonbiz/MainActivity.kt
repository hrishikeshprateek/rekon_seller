package com.reckon.reckonbiz

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import android.Manifest
import android.view.WindowManager
import android.util.Log

class MainActivity: FlutterActivity() {
    private val PERMISSION_REQUEST_CODE = 1001
    private val CHANNEL = "com.reckon.reckonbiz/screenshot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up method channel for screenshot prevention
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "disableScreenshot" -> {
                    disableScreenshot()
                    result.success("Screenshot disabled")
                }
                "enableScreenshot" -> {
                    enableScreenshot()
                    result.success("Screenshot enabled")
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Apply FLAG_SECURE by default to prevent screenshots
        disableScreenshot()

        // Request permissions on startup
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.READ_MEDIA_IMAGES
            )
        } else {
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
        }

        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
    }

    private fun disableScreenshot() {
        try {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
            Log.d("MainActivity", "✅ Screenshot disabled")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error disabling screenshot: ${e.message}")
        }
    }

    private fun enableScreenshot() {
        try {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            Log.d("MainActivity", "✅ Screenshot enabled")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error enabling screenshot: ${e.message}")
        }
    }
}

