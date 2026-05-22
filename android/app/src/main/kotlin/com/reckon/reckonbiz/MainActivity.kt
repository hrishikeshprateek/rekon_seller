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
import android.content.ContentValues
import android.provider.MediaStore
import android.os.Environment
import java.io.File

class MainActivity: FlutterActivity() {
    private val PERMISSION_REQUEST_CODE = 1001
    private val CHANNEL = "com.reckon.reckonbiz/screenshot"
    private val FILES_CHANNEL = "com.reckon.reckonbiz/files"

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

        // Method channel for saving files into the public Downloads folder
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILES_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    try {
                        val fileName = call.argument<String>("fileName") ?: "file"
                        val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                        val mime = call.argument<String>("mimeType") ?: "application/octet-stream"
                        result.success(saveToDownloads(fileName, bytes, mime))
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
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

    /// Writes [bytes] into the device's public Downloads folder and returns a
    /// human-readable location. Uses MediaStore on Android 10+ (no permission
    /// needed); falls back to a direct file write on older versions.
    private fun saveToDownloads(fileName: String, bytes: ByteArray, mime: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw Exception("Could not create file in Downloads")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw Exception("Could not open output stream")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Downloads/$fileName"
        } else {
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, fileName)
            file.writeBytes(bytes)
            return file.absolutePath
        }
    }
}

