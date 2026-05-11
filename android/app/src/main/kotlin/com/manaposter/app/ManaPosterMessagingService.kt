package com.manaposter.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.net.HttpURLConnection
import java.net.URL

class ManaPosterMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        ManaPosterNotificationRenderer.show(this, message)
    }
}

object ManaPosterNotificationRenderer {
    private const val channelId = "mana_poster_general"
    private const val channelName = "Mana Poster Ai Notifications"
    private const val channelDescription = "General reminders and event updates"
    private const val activeNotificationId = 1001

    fun show(context: Context, message: RemoteMessage) {
        val data = message.data
        if (data.isEmpty()) {
            return
        }

        ensureNotificationChannel(context)

        val posterImageUrl = data["posterImage"].orEmpty().trim()
        val categoryKey = data["categoryKey"].orEmpty().trim().lowercase()
        val route = data["route"].orEmpty().trim().ifEmpty { "home" }
        val appName =
            context.applicationInfo.loadLabel(context.packageManager)?.toString().orEmpty().ifEmpty { "Mana Poster Ai" }
        val deviceProfile = loadDeviceProfile(context)
        val payloadUserName = data["userName"].orEmpty().trim()
        val payloadUserPhotoUrl = data["userPhoto"].orEmpty().trim()
        val resolvedUserName = deviceProfile.resolvedName.ifBlank { payloadUserName }
        val resolvedUserPhotoUrl = deviceProfile.resolvedPhotoUrl.ifBlank { payloadUserPhotoUrl }
        val localizedCopy = localizedReminderCopy(categoryKey, resolvedUserName)
        val shouldUseLocalizedCopy = isReminderCategory(categoryKey)
        val title = if (shouldUseLocalizedCopy) {
            localizedCopy.title
        } else {
            sanitizeNotificationText(data["title"].orEmpty().trim(), localizedCopy.title).ifEmpty { appName }
        }
        val body = if (shouldUseLocalizedCopy) {
            localizedCopy.body
        } else {
            sanitizeNotificationText(data["body"].orEmpty().trim(), localizedCopy.body)
        }
        val header = if (shouldUseLocalizedCopy) {
            localizedCopy.header
        } else {
            sanitizeNotificationText(data["headerText"].orEmpty().trim(), localizedCopy.header)
        }
        val footerText = if (shouldUseLocalizedCopy) {
            localizedCopy.footer
        } else {
            sanitizeNotificationText(data["footerText"].orEmpty().trim(), localizedCopy.footer)
        }

        if (posterImageUrl.isBlank()) {
            showFallbackNotification(context, title, body, route)
            return
        }

        try {
            val compactViews = RemoteViews(context.packageName, R.layout.notification_compact)
            val expandedViews = RemoteViews(context.packageName, R.layout.notification_expanded)
            val headerBackgroundRes = headerBackgroundRes(categoryKey)
            val shareBackgroundRes = shareBackgroundRes(categoryKey)
            val preferSystemStyle = shouldPreferSystemStyle()

            compactViews.setInt(R.id.notification_compact_header, "setBackgroundResource", headerBackgroundRes)
            compactViews.setTextViewText(R.id.notification_compact_title, appName)
            compactViews.setTextViewText(R.id.notification_compact_text, header)

            expandedViews.setInt(R.id.notification_expanded_header, "setBackgroundResource", headerBackgroundRes)
            expandedViews.setTextViewText(R.id.notification_expanded_title, appName)
            expandedViews.setTextViewText(R.id.notification_expanded_text, header)
            expandedViews.setTextViewText(R.id.notification_expanded_name, resolvedUserName.ifBlank { "User" })
            expandedViews.setTextViewText(R.id.notification_expanded_share_bg, footerText.ifBlank { "Share" })
            expandedViews.setInt(R.id.notification_expanded_share_bg, "setBackgroundResource", shareBackgroundRes)

            val avatarBitmap = downloadBitmap(resolvedUserPhotoUrl)
            if (avatarBitmap != null) {
                compactViews.setImageViewBitmap(R.id.notification_compact_avatar, avatarBitmap)
                expandedViews.setImageViewBitmap(R.id.notification_expanded_header_avatar, avatarBitmap)
                expandedViews.setImageViewBitmap(R.id.notification_expanded_avatar, avatarBitmap)
            }

            val posterBitmap = downloadBitmap(posterImageUrl)
            if (posterBitmap != null) {
                expandedViews.setImageViewBitmap(R.id.notification_expanded_image, posterBitmap)
            }

            val contentIntent = buildContentIntent(context, route, categoryKey, resolvedUserName)
            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(appName)
                .setContentText(header)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_SOCIAL)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setOnlyAlertOnce(false)
                .setContentIntent(contentIntent)

            if (avatarBitmap != null) {
                builder.setLargeIcon(avatarBitmap)
            }

            if (posterBitmap != null) {
                builder.setStyle(
                    NotificationCompat.BigPictureStyle()
                        .bigPicture(posterBitmap)
                        .bigLargeIcon(null as Bitmap?)
                        .setBigContentTitle(appName)
                        .setSummaryText(header),
                )
            } else {
                builder.setStyle(NotificationCompat.BigTextStyle().bigText(header))
            }

            if (!preferSystemStyle) {
                builder.setStyle(NotificationCompat.DecoratedCustomViewStyle())
                builder.setCustomContentView(compactViews)
                builder.setCustomBigContentView(expandedViews)
            }

            NotificationManagerCompat.from(context).cancelAll()
            postNotification(context, activeNotificationId, builder.build())
            Log.i("ManaPosterNotif", "custom notification posted")
        } catch (t: Throwable) {
            Log.e("ManaPosterNotif", "custom render failed", t)
            showFallbackNotification(context, title, body, route)
        }
    }

    private fun showFallbackNotification(context: Context, title: String, body: String, route: String) {
        val contentIntent = buildContentIntent(context, route, "", "")
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
        NotificationManagerCompat.from(context).cancelAll()
        postNotification(context, activeNotificationId, builder.build())
    }

    private fun buildContentIntent(
        context: Context,
        route: String,
        categoryKey: String,
        userName: String,
    ): PendingIntent? {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            putExtra("notification_route", route)
            putExtra("notification_category", categoryKey)
            putExtra("notification_user_name", userName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntentFlags =
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getActivity(
            context,
            System.currentTimeMillis().toInt(),
            launchIntent,
            pendingIntentFlags,
        )
    }

    private fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        if (notificationManager.getNotificationChannel(channelId) != null) {
            return
        }
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = channelDescription
            enableVibration(true)
            setShowBadge(true)
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
        }
        notificationManager.createNotificationChannel(channel)
        Log.i("ManaPosterNotif", "notification channel created")
    }

    private fun postNotification(context: Context, notificationId: Int, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.w("ManaPosterNotif", "notification skipped: POST_NOTIFICATIONS not granted")
            return
        }
        NotificationManagerCompat.from(context).notify(notificationId, notification)
    }

    private fun headerBackgroundRes(categoryKey: String): Int {
        return when (categoryKey) {
            "morning" -> R.drawable.notification_header_morning
            "night" -> R.drawable.notification_header_night
            else -> R.drawable.notification_header_afternoon
        }
    }

    private fun shareBackgroundRes(categoryKey: String): Int {
        return when (categoryKey) {
            "morning" -> R.drawable.notification_share_morning
            "night" -> R.drawable.notification_share_night
            else -> R.drawable.notification_share_afternoon
        }
    }

    private fun shouldPreferSystemStyle(): Boolean {
        val manufacturer = Build.MANUFACTURER.orEmpty().lowercase()
        val brand = Build.BRAND.orEmpty().lowercase()
        return manufacturer.contains("vivo") ||
            manufacturer.contains("oppo") ||
            brand.contains("vivo") ||
            brand.contains("oppo")
    }

    private fun isReminderCategory(categoryKey: String): Boolean {
        return categoryKey == "morning" ||
            categoryKey == "afternoon" ||
            categoryKey == "night" ||
            categoryKey == "welcome"
    }

    private fun loadDeviceProfile(context: Context): DeviceProfile {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val identityMode = flutterPref(prefs, "poster_profile_identity_mode")
        val businessName = flutterPref(prefs, "poster_profile_business_name")
        val businessLogoUrl = flutterPref(prefs, "poster_profile_business_logo_url")
        val nameTelugu = flutterPref(prefs, "poster_profile_name_telugu")
        val nameEnglish = flutterPref(prefs, "poster_profile_name_english")
        val genericName = flutterPref(prefs, "poster_profile_name")
        val photoUrl = flutterPref(prefs, "poster_profile_photo_url")
        val originalPhotoUrl = flutterPref(prefs, "poster_profile_original_photo_url")
        val resolvedName =
            if (identityMode == "business" && businessName.isNotBlank()) businessName
            else listOf(nameTelugu, nameEnglish, genericName).firstOrNull { it.isNotBlank() }.orEmpty()
        val resolvedPhotoUrl =
            if (identityMode == "business" && businessLogoUrl.isNotBlank()) businessLogoUrl
            else listOf(photoUrl, originalPhotoUrl).firstOrNull { it.isNotBlank() }.orEmpty()
        return DeviceProfile(
            resolvedName = resolvedName,
            resolvedPhotoUrl = resolvedPhotoUrl,
        )
    }

    private fun flutterPref(prefs: SharedPreferences, key: String): String {
        return prefs.getString("flutter.$key", "").orEmpty().trim()
    }

    private fun downloadBitmap(url: String): Bitmap? {
        if (url.isBlank()) {
            return null
        }
        var connection: HttpURLConnection? = null
        return try {
            connection = URL(url).openConnection() as HttpURLConnection
            connection.connectTimeout = 12000
            connection.readTimeout = 12000
            connection.instanceFollowRedirects = true
            connection.doInput = true
            connection.connect()
            connection.inputStream.use { input ->
                BitmapFactory.decodeStream(input)
            }
        } catch (t: Throwable) {
            Log.w("ManaPosterNotif", "bitmap download failed: $url", t)
            null
        } finally {
            connection?.disconnect()
        }
    }

    private fun sanitizeNotificationText(value: String, fallback: String): String {
        val trimmed = value.trim()
        if (trimmed.isEmpty()) {
            return fallback
        }
        val questionMarks = trimmed.count { it == '?' }
        return if (trimmed.contains("???") || questionMarks >= 3 || questionMarks * 2 >= trimmed.length) {
            fallback
        } else {
            trimmed
        }
    }

    private fun localizedReminderCopy(categoryKey: String, userName: String): ReminderCopy {
        val name = userName.ifBlank { "User" }
        val isTelugu = userName.any { it.code in 0x0C00..0x0C7F }
        return when (categoryKey) {
            "morning" -> if (isTelugu) {
                ReminderCopy(
                    title = "\u0c36\u0c41\u0c2d\u0c4b\u0c26\u0c2f\u0c02",
                    body = "\u0c2e\u0c40 \u0c09\u0c26\u0c2f\u0c2a\u0c41 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c02\u0c26\u0c3f. \u0c07\u0c2a\u0c4d\u0c2a\u0c41\u0c21\u0c47 \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f.",
                    header = "$name, \uD83D\uDC49 \u0c2e\u0c40 \u0c09\u0c26\u0c2f\u0c2a\u0c41 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c21\u0c3e\u0c28\u0c3f\u0c15\u0c3f \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c02\u0c26\u0c3f",
                    footer = "\u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f",
                )
            } else {
                ReminderCopy(
                    title = "Good Morning",
                    body = "Your good morning poster is ready. Share it now.",
                    header = "$name, your morning poster is ready to share",
                    footer = "Share",
                )
            }

            "night" -> if (isTelugu) {
                ReminderCopy(
                    title = "\u0c36\u0c41\u0c2d \u0c30\u0c3e\u0c24\u0c4d\u0c30\u0c3f",
                    body = "\u0c2e\u0c40 \u0c30\u0c3e\u0c24\u0c4d\u0c30\u0c3f \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c02\u0c26\u0c3f. \u0c07\u0c2a\u0c4d\u0c2a\u0c41\u0c21\u0c47 \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f.",
                    header = "$name, \uD83D\uDC49 \u0c2e\u0c40 \u0c30\u0c3e\u0c24\u0c4d\u0c30\u0c3f \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c21\u0c3e\u0c28\u0c3f\u0c15\u0c3f \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c02\u0c26\u0c3f",
                    footer = "\u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f",
                )
            } else {
                ReminderCopy(
                    title = "Good Night",
                    body = "Your good night poster is ready. Share it now.",
                    header = "$name, your night poster is ready to share",
                    footer = "Share",
                )
            }

            "welcome" -> if (isTelugu) {
                ReminderCopy(
                    title = "Mana Poster \u0c15\u0c3f \u0c38\u0c4d\u0c35\u0c3e\u0c17\u0c24\u0c02",
                    body = "\u0c2e\u0c40 \u0c15\u0c4b\u0c38\u0c02 \u0c30\u0c4b\u0c1c\u0c41\u0c35\u0c3e\u0c30\u0c40 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d\u0c32\u0c41 \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c28\u0c4d\u0c28\u0c3e\u0c2f\u0c3f. \u0c2f\u0c3e\u0c2a\u0c4d \u0c13\u0c2a\u0c46\u0c28\u0c4d \u0c1a\u0c47\u0c38\u0c3f \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f.",
                    header = "$name, \uD83D\uDC49 \u0c2e\u0c40 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c21\u0c3e\u0c28\u0c3f\u0c15\u0c3f \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c02\u0c26\u0c3f",
                    footer = "\u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f",
                )
            } else {
                ReminderCopy(
                    title = "Welcome to Mana Poster",
                    body = "Daily posters are ready for you. Open and share.",
                    header = "$name, your poster is ready to share",
                    footer = "Share",
                )
            }

            else -> if (isTelugu) {
                ReminderCopy(
                    title = "\u0c36\u0c41\u0c2d \u0c2e\u0c27\u0c4d\u0c2f\u0c3e\u0c39\u0c4d\u0c28\u0c02",
                    body = "\u0c2e\u0c40 \u0c2e\u0c27\u0c4d\u0c2f\u0c3e\u0c39\u0c4d\u0c28 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c02\u0c26\u0c3f. \u0c07\u0c2a\u0c4d\u0c2a\u0c41\u0c21\u0c47 \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f.",
                    header = "$name, \uD83D\uDC49 \u0c2e\u0c40 \u0c2e\u0c27\u0c4d\u0c2f\u0c3e\u0c39\u0c4d\u0c28 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c21\u0c3e\u0c28\u0c3f\u0c15\u0c3f \u0c38\u0c3f\u0c26\u0c4d\u0c27\u0c02\u0c17\u0c3e \u0c09\u0c02\u0c26\u0c3f",
                    footer = "\u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f",
                )
            } else {
                ReminderCopy(
                    title = "Good Afternoon",
                    body = "Your good afternoon poster is ready. Share it now.",
                    header = "$name, your afternoon poster is ready to share",
                    footer = "Share",
                )
            }
        }
    }

    private data class ReminderCopy(
        val title: String,
        val body: String,
        val header: String,
        val footer: String,
    )

    private data class DeviceProfile(
        val resolvedName: String,
        val resolvedPhotoUrl: String,
    )
}
