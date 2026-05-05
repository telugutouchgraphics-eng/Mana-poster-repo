package com.manaposter.app

import android.content.ContentValues
import android.util.Log
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.view.WindowManager
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val screenSecurityChannelName = "mana_poster/screen_security"
    private val mediaExportChannelName = "mana_poster/media_export"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenSecurityChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecure" -> {
                        runOnUiThread {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    "disableSecure" -> {
                        runOnUiThread {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaExportChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveImageFileToGallery" -> {
                        val filePath = call.argument<String>("filePath")
                        val fileName = call.argument<String>("fileName")
                        val mimeType = call.argument<String>("mimeType") ?: "image/png"
                        if (filePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "code" to "invalid_args",
                                    "message" to "filePath or fileName is missing",
                                )
                            )
                            return@setMethodCallHandler
                        }
                        result.success(saveImageFileToGallery(filePath, fileName, mimeType))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveImageFileToGallery(filePath: String, fileName: String, mimeType: String): Map<String, Any?> {
        return try {
            val sourceFile = File(filePath)
            if (!sourceFile.exists()) {
                return mapOf(
                    "success" to false,
                    "code" to "file_missing",
                    "message" to "Source file does not exist: $filePath",
                )
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = applicationContext.contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                    put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Mana Poster")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                    ?: return mapOf(
                        "success" to false,
                        "code" to "media_insert_failed",
                        "message" to "MediaStore insert returned null",
                    )
                resolver.openOutputStream(uri)?.use { output ->
                    FileInputStream(sourceFile).use { input ->
                        input.copyTo(output)
                    }
                } ?: return mapOf(
                    "success" to false,
                    "code" to "open_output_failed",
                    "message" to "Unable to open MediaStore output stream",
                )
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                mapOf(
                    "success" to true,
                    "code" to "saved",
                    "message" to "Saved image to gallery successfully",
                )
            } else {
                val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val appDir = File(picturesDir, "Mana Poster")
                if (!appDir.exists() && !appDir.mkdirs()) {
                    return mapOf(
                        "success" to false,
                        "code" to "directory_create_failed",
                        "message" to "Unable to create gallery directory: ${appDir.absolutePath}",
                    )
                }
                val targetFile = File(appDir, fileName)
                FileInputStream(sourceFile).use { input ->
                    FileOutputStream(targetFile).use { output ->
                        input.copyTo(output)
                        output.flush()
                    }
                }
                MediaScannerConnection.scanFile(
                    applicationContext,
                    arrayOf(targetFile.absolutePath),
                    arrayOf(mimeType),
                    null,
                )
                mapOf(
                    "success" to true,
                    "code" to "saved",
                    "message" to "Saved image to gallery successfully",
                )
            }
        } catch (t: Throwable) {
            Log.e("ManaPosterSave", "saveImageFileToGallery failed", t)
            mapOf(
                "success" to false,
                "code" to "save_failed",
                "message" to (t.message ?: t.javaClass.simpleName),
            )
        }
    }
}
