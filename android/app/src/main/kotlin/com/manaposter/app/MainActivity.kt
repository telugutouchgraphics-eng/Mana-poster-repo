package com.manaposter.app

import android.content.ContentValues
import android.content.Intent
import android.util.Log
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.view.WindowManager
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import com.google.android.play.core.review.ReviewManagerFactory
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val screenSecurityChannelName = "mana_poster/screen_security"
    private val mediaExportChannelName = "mana_poster/media_export"
    private val installSourceChannelName = "mana_poster/install_source"
    private val playEngagementChannelName = "mana_poster/play_engagement"
    private val startupStateChannelName = "mana_poster/startup_state"
    private val startupStatePrefsName = "mana_poster_startup_state_v1"
    private val notificationTapRouteKey = "notificationTapRoute"
    private val notificationTapAtKey = "notificationTapAt"
    private val appUpdateRequestCode = 3017
    private val appUpdateManager: AppUpdateManager by lazy {
        AppUpdateManagerFactory.create(this)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
        rememberNotificationLaunch(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        rememberNotificationLaunch(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == appUpdateRequestCode) {
            Log.d("ManaPosterPlay", "updateFlow resultCode=$resultCode")
        }
    }

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
                    "saveImageBytesToGallery" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        val mimeType = call.argument<String>("mimeType") ?: "image/png"
                        if (bytes == null || bytes.isEmpty() || fileName.isNullOrBlank()) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "code" to "invalid_args",
                                    "message" to "bytes or fileName is missing",
                                )
                            )
                            return@setMethodCallHandler
                        }
                        result.success(saveImageBytesToGallery(bytes, fileName, mimeType))
                    }
                    "saveVideoFileToGallery" -> {
                        val filePath = call.argument<String>("filePath")
                        val fileName = call.argument<String>("fileName")
                        val mimeType = call.argument<String>("mimeType") ?: "video/mp4"
                        if (filePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "code" to "invalid_arguments",
                                    "message" to "filePath and fileName are required",
                                )
                            )
                            return@setMethodCallHandler
                        }
                        result.success(saveVideoFileToGallery(filePath, fileName, mimeType))
                    }
                    "saveFileToDownloads" -> {
                        val filePath = call.argument<String>("filePath")
                        val fileName = call.argument<String>("fileName")
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        if (filePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "code" to "invalid_arguments",
                                    "message" to "filePath and fileName are required",
                                )
                            )
                            return@setMethodCallHandler
                        }
                        result.success(saveFileToDownloads(filePath, fileName, mimeType))
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installSourceChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTrustedPlayInstall" -> {
                        result.success(isTrustedPlayInstall())
                    }
                    "isProbablyEmulator" -> {
                        result.success(isProbablyEmulator())
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, playEngagementChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkForAppUpdate" -> {
                        checkForAppUpdate(result)
                    }
                    "startImmediateUpdate" -> {
                        startUpdateFlow(AppUpdateType.IMMEDIATE, result)
                    }
                    "startFlexibleUpdate" -> {
                        startUpdateFlow(AppUpdateType.FLEXIBLE, result)
                    }
                    "completeFlexibleUpdate" -> {
                        completeFlexibleUpdate(result)
                    }
                    "requestInAppReview" -> {
                        requestInAppReview(result)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, startupStateChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readState" -> {
                        result.success(readStartupState())
                    }
                    "writeState" -> {
                        @Suppress("UNCHECKED_CAST")
                        val entries = call.argument<Map<String, Any?>>("entries")
                        if (entries == null) {
                            result.success(false)
                        } else {
                            result.success(writeStartupState(entries))
                        }
                    }
                    else -> result.notImplemented()
                }
            }

    }

    private fun checkForAppUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { appUpdateInfo ->
                result.success(
                    mapOf(
                        "updateAvailable" to (
                            appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE ||
                                appUpdateInfo.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
                            ),
                        "updateInProgress" to
                            (appUpdateInfo.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS),
                        "immediateAllowed" to appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                        "flexibleAllowed" to appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                        "stalenessDays" to appUpdateInfo.clientVersionStalenessDays(),
                        "priority" to appUpdateInfo.updatePriority(),
                        "installStatus" to appUpdateInfo.installStatus(),
                    ),
                )
            }
            .addOnFailureListener { throwable ->
                Log.e("ManaPosterPlay", "checkForAppUpdate failed", throwable)
                result.error(
                    "update_check_failed",
                    throwable.message ?: "Update check failed",
                    null,
                )
            }
    }

    private fun startUpdateFlow(updateType: Int, result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { appUpdateInfo ->
                val allowed = appUpdateInfo.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS ||
                    appUpdateInfo.isUpdateTypeAllowed(updateType)
                if (!allowed) {
                    result.success(false)
                    return@addOnSuccessListener
                }
                launchUpdateFlow(appUpdateInfo, updateType, result)
            }
            .addOnFailureListener { throwable ->
                Log.e("ManaPosterPlay", "startUpdateFlow failed", throwable)
                result.success(false)
            }
    }

    private fun launchUpdateFlow(
        appUpdateInfo: AppUpdateInfo,
        updateType: Int,
        result: MethodChannel.Result,
    ) {
        try {
            appUpdateManager.startUpdateFlowForResult(
                appUpdateInfo,
                updateType,
                this,
                appUpdateRequestCode,
            )
            result.success(true)
        } catch (throwable: Throwable) {
            Log.e("ManaPosterPlay", "launchUpdateFlow failed", throwable)
            result.success(false)
        }
    }

    private fun completeFlexibleUpdate(result: MethodChannel.Result) {
        appUpdateManager.completeUpdate()
            .addOnSuccessListener {
                result.success(true)
            }
            .addOnFailureListener { throwable ->
                Log.e("ManaPosterPlay", "completeFlexibleUpdate failed", throwable)
                result.success(false)
            }
    }

    private fun requestInAppReview(result: MethodChannel.Result) {
        val reviewManager = ReviewManagerFactory.create(this)
        reviewManager.requestReviewFlow()
            .addOnCompleteListener { requestTask ->
                if (!requestTask.isSuccessful) {
                    val throwable = requestTask.exception
                    Log.e("ManaPosterPlay", "requestReviewFlow failed", throwable)
                    result.success(false)
                    return@addOnCompleteListener
                }
                val reviewInfo = requestTask.result
                reviewManager.launchReviewFlow(this, reviewInfo)
                    .addOnCompleteListener { launchTask ->
                        if (!launchTask.isSuccessful) {
                            Log.e(
                                "ManaPosterPlay",
                                "launchReviewFlow failed",
                                launchTask.exception,
                            )
                            result.success(false)
                            return@addOnCompleteListener
                        }
                        result.success(true)
                    }
            }
    }

    private fun readStartupState(): Map<String, Any?> {
        val prefs = applicationContext.getSharedPreferences(startupStatePrefsName, MODE_PRIVATE)
        val state = prefs.all.mapValues { (_, value) ->
            when (value) {
                is String, is Boolean, is Int, is Long, is Float -> value
                else -> value?.toString()
            }
        }
        return state
    }

    private fun writeStartupState(entries: Map<String, Any?>): Boolean {
        val prefs = applicationContext.getSharedPreferences(startupStatePrefsName, MODE_PRIVATE)
        val editor = prefs.edit()
        for ((key, value) in entries) {
            when (value) {
                null -> editor.remove(key)
                is String -> editor.putString(key, value)
                is Boolean -> editor.putBoolean(key, value)
                is Int -> editor.putInt(key, value)
                is Long -> editor.putLong(key, value)
                is Float -> editor.putFloat(key, value)
                is Double -> editor.putString(key, value.toString())
                else -> editor.putString(key, value.toString())
            }
        }
        val committed = editor.commit()
        return committed
    }

    private fun rememberNotificationLaunch(intent: Intent?) {
        val route = intent
            ?.getStringExtra("notification_route")
            ?.trim()
            .orEmpty()
        if (route.isBlank()) {
            return
        }
        writeStartupState(
            mapOf(
                notificationTapRouteKey to route,
                notificationTapAtKey to System.currentTimeMillis(),
            )
        )
    }

    private fun isTrustedPlayInstall(): Boolean {
        return try {
            val installerPackage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName)
            }?.trim()
            installerPackage == "com.android.vending"
        } catch (_: Throwable) {
            false
        }
    }

    private fun isProbablyEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val device = Build.DEVICE.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        return fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator") ||
            model.contains("emulator") ||
            model.contains("android sdk built for") ||
            model.contains("sdk_gphone") ||
            manufacturer.contains("genymotion") ||
            hardware.contains("goldfish") ||
            hardware.contains("ranchu") ||
            (brand.startsWith("generic") && device.startsWith("generic")) ||
            product.contains("sdk_gphone") ||
            product.contains("google_sdk")
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

    private fun saveImageBytesToGallery(bytes: ByteArray, fileName: String, mimeType: String): Map<String, Any?> {
        return try {
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
                    output.write(bytes)
                    output.flush()
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
                    "message" to "Saved image bytes to gallery successfully",
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
                FileOutputStream(targetFile).use { output ->
                    output.write(bytes)
                    output.flush()
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
                    "message" to "Saved image bytes to gallery successfully",
                )
            }
        } catch (t: Throwable) {
            Log.e("ManaPosterSave", "saveImageBytesToGallery failed", t)
            mapOf(
                "success" to false,
                "code" to "save_failed",
                "message" to (t.message ?: t.javaClass.simpleName),
            )
        }
    }

    private fun saveFileToDownloads(filePath: String, fileName: String, mimeType: String): Map<String, Any?> {
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
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/Mana Poster")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: return mapOf(
                        "success" to false,
                        "code" to "media_insert_failed",
                        "message" to "MediaStore downloads insert returned null",
                    )
                resolver.openOutputStream(uri)?.use { output ->
                    FileInputStream(sourceFile).use { input ->
                        input.copyTo(output)
                    }
                } ?: return mapOf(
                    "success" to false,
                    "code" to "open_output_failed",
                    "message" to "Unable to open downloads output stream",
                )
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                mapOf(
                    "success" to true,
                    "code" to "saved",
                    "message" to "Saved file to downloads successfully",
                )
            } else {
                val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                val appDir = File(downloadsDir, "Mana Poster")
                if (!appDir.exists() && !appDir.mkdirs()) {
                    return mapOf(
                        "success" to false,
                        "code" to "directory_create_failed",
                        "message" to "Unable to create downloads directory: ${appDir.absolutePath}",
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
                    "message" to "Saved file to downloads successfully",
                )
            }
        } catch (t: Throwable) {
            Log.e("ManaPosterSave", "saveFileToDownloads failed", t)
            mapOf(
                "success" to false,
                "code" to "save_failed",
                "message" to (t.message ?: t.javaClass.simpleName),
            )
        }
    }

    private fun saveVideoFileToGallery(filePath: String, fileName: String, mimeType: String): Map<String, Any?> {
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
                    put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Video.Media.MIME_TYPE, mimeType)
                    put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/Mana Poster")
                    put(MediaStore.Video.Media.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
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
                values.put(MediaStore.Video.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                mapOf(
                    "success" to true,
                    "code" to "saved",
                    "message" to "Saved video to gallery successfully",
                )
            } else {
                val moviesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
                val appDir = File(moviesDir, "Mana Poster")
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
                    "message" to "Saved video to gallery successfully",
                )
            }
        } catch (t: Throwable) {
            Log.e("ManaPosterSave", "saveVideoFileToGallery failed", t)
            mapOf(
                "success" to false,
                "code" to "save_failed",
                "message" to (t.message ?: t.javaClass.simpleName),
            )
        }
    }
}
