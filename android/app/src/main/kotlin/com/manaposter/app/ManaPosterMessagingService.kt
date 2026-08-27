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
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.io.ByteArrayOutputStream
import java.util.Calendar
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

    fun show(context: Context, message: RemoteMessage) {
        val data = message.data
        if (data.isEmpty()) {
            return
        }

        ensureNotificationChannel(context)

        val posterImageUrl = data["posterImage"].orEmpty().trim()
        val categoryKey = data["categoryKey"].orEmpty().trim().lowercase()
        val source = data["source"].orEmpty().trim()
        val notificationId = uniqueNotificationId(message, data)
        val isQuizWinnerNotification =
            categoryKey == "daily_quiz" ||
                data["category"].orEmpty().trim().lowercase() == "daily_quiz" ||
                data["notificationKind"].orEmpty().trim().lowercase() == "daily_quiz" ||
                source == "admin_quiz_winner_push"
        val route = data["route"].orEmpty().trim().ifEmpty { "home" }
        val appName =
            context.applicationInfo.loadLabel(context.packageManager)?.toString().orEmpty().ifEmpty { "Mana Poster Ai" }
        val deviceProfile = loadDeviceProfile(context)
        val payloadUserName = data["userName"].orEmpty().trim()
        val payloadUserPhotoUrl = data["userPhoto"].orEmpty().trim()
        val resolvedUserName = payloadUserName.ifBlank { deviceProfile.resolvedName }
        val resolvedUserPhotoUrl = payloadUserPhotoUrl.ifBlank { deviceProfile.resolvedPhotoUrl }
        val effectiveLanguageCode = data["languageCode"].orEmpty().trim().ifBlank { deviceProfile.languageCode }
        val localizedCopy = localizedReminderCopy(categoryKey, resolvedUserName, effectiveLanguageCode)
        val title = sanitizeNotificationText(data["title"].orEmpty().trim(), localizedCopy.title).ifEmpty { appName }
        val body = sanitizeNotificationText(data["body"].orEmpty().trim(), localizedCopy.body)
        val header = sanitizeNotificationText(data["headerText"].orEmpty().trim(), localizedCopy.header)
        val footerText = sanitizeNotificationText(data["footerText"].orEmpty().trim(), localizedCopy.footer)

        if (posterImageUrl.isBlank() && !isQuizWinnerNotification) {
            showFallbackNotification(context, title, body, route, categoryKey, notificationId)
            return
        }

        try {
            val compactViews = RemoteViews(context.packageName, R.layout.notification_compact)
            val expandedViews = RemoteViews(context.packageName, R.layout.notification_expanded)
            val paletteIndex = notificationPaletteIndex(categoryKey, data["paletteIndex"].orEmpty())
            val headerBackgroundRes = headerBackgroundRes(categoryKey, paletteIndex)
            val shareBackgroundRes = shareBackgroundRes(categoryKey, paletteIndex)
            val effectiveHeaderBackgroundRes =
                if (isQuizWinnerNotification) R.drawable.notification_header_quiz_winner else headerBackgroundRes
            compactViews.setInt(R.id.notification_compact_header, "setBackgroundResource", effectiveHeaderBackgroundRes)
            compactViews.setTextViewText(R.id.notification_compact_title, appName)
            compactViews.setTextViewText(R.id.notification_compact_text, header)

            expandedViews.setInt(R.id.notification_expanded_header, "setBackgroundResource", effectiveHeaderBackgroundRes)
            expandedViews.setTextViewText(R.id.notification_expanded_title, appName)
            expandedViews.setTextViewText(R.id.notification_expanded_text, header)
            expandedViews.setTextViewText(R.id.notification_expanded_name, resolvedUserName.ifBlank { "User" })
            expandedViews.setTextViewText(R.id.notification_expanded_share_bg, footerText.ifBlank { "Share" })
            expandedViews.setInt(R.id.notification_expanded_share_bg, "setBackgroundResource", shareBackgroundRes)
            expandedViews.setImageViewResource(R.id.notification_expanded_avatar, R.mipmap.ic_launcher)
            if (isQuizWinnerNotification) {
                expandedViews.setViewVisibility(R.id.notification_expanded_title, View.GONE)
                expandedViews.setViewVisibility(R.id.notification_expanded_celebration_top, View.VISIBLE)
                expandedViews.setViewVisibility(R.id.notification_expanded_celebration_bottom, View.VISIBLE)
                expandedViews.setViewVisibility(R.id.notification_expanded_image_frame, View.GONE)
                expandedViews.setViewVisibility(R.id.notification_expanded_user_panel, View.GONE)
                expandedViews.setInt(R.id.notification_expanded_text, "setMaxLines", 4)
            } else {
                expandedViews.setViewVisibility(R.id.notification_expanded_title, View.VISIBLE)
                expandedViews.setViewVisibility(R.id.notification_expanded_celebration_top, View.GONE)
                expandedViews.setViewVisibility(R.id.notification_expanded_celebration_bottom, View.GONE)
                expandedViews.setViewVisibility(R.id.notification_expanded_image_frame, View.VISIBLE)
                expandedViews.setViewVisibility(R.id.notification_expanded_user_panel, View.VISIBLE)
            }

            val avatarBitmap = downloadBitmap(resolvedUserPhotoUrl)
            if (avatarBitmap != null) {
                expandedViews.setImageViewBitmap(R.id.notification_expanded_avatar, circularAvatarBitmap(avatarBitmap))
            }

            val posterBitmap = if (isQuizWinnerNotification) null else downloadBitmap(posterImageUrl)
            if (!isQuizWinnerNotification && posterBitmap == null) {
                    showFallbackNotification(context, title, body, route, categoryKey, notificationId)
                    return
            }
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

            if (posterBitmap != null) {
                builder.setStyle(
                    NotificationCompat.BigPictureStyle()
                        .bigPicture(posterBitmap)
                        .bigLargeIcon(null as Bitmap?)
                        .setBigContentTitle(appName)
                        .setSummaryText(header),
                )
            }

            builder.setStyle(NotificationCompat.DecoratedCustomViewStyle())
            builder.setCustomContentView(compactViews)
            builder.setCustomBigContentView(expandedViews)

            postNotification(context, notificationId, builder.build())
            Log.i("ManaPosterNotif", "custom notification posted")
        } catch (t: Throwable) {
            Log.e("ManaPosterNotif", "custom render failed", t)
            showFallbackNotification(context, title, body, route, categoryKey, notificationId)
        }
    }

    private fun showFallbackNotification(
        context: Context,
        title: String,
        body: String,
        route: String,
        categoryKey: String,
        notificationId: Int,
    ) {
        val contentIntent = buildContentIntent(context, route, categoryKey, "")
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
        postNotification(context, notificationId, builder.build())
    }

    private fun uniqueNotificationId(message: RemoteMessage, data: Map<String, String>): Int {
        val stableSeed = listOf(
            message.messageId.orEmpty().trim(),
            data["messageId"].orEmpty().trim(),
            data["sentAt"].orEmpty().trim(),
            data["renderedAt"].orEmpty().trim(),
        ).firstOrNull { it.isNotEmpty() } ?: System.currentTimeMillis().toString()
        val mixed = "$stableSeed:${data["categoryKey"].orEmpty()}:${data["posterImage"].orEmpty()}".hashCode()
        val positive = mixed and 0x7fffffff
        return if (positive == 0) 1001 else positive
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

    private fun notificationPaletteIndex(categoryKey: String, requestedPaletteIndex: String): Int {
        val requested = requestedPaletteIndex.toIntOrNull()
        if (requested != null && requested in 0..4) {
            return requested
        }
        val calendar = Calendar.getInstance()
        val daySeed = calendar.get(Calendar.YEAR) * 366 + calendar.get(Calendar.DAY_OF_YEAR)
        return kotlin.math.abs(daySeed + categoryKey.hashCode()) % 5
    }

    private fun headerBackgroundRes(categoryKey: String, paletteIndex: Int): Int {
        return when (categoryKey) {
            "morning" -> when (paletteIndex) {
                0 -> R.drawable.notification_header_morning_1
                1 -> R.drawable.notification_header_morning_2
                2 -> R.drawable.notification_header_morning_3
                3 -> R.drawable.notification_header_morning_4
                else -> R.drawable.notification_header_morning_5
            }
            "night" -> when (paletteIndex) {
                0 -> R.drawable.notification_header_night_1
                1 -> R.drawable.notification_header_night_2
                2 -> R.drawable.notification_header_night_3
                3 -> R.drawable.notification_header_night_4
                else -> R.drawable.notification_header_night_5
            }
            else -> when (paletteIndex) {
                0 -> R.drawable.notification_header_afternoon_1
                1 -> R.drawable.notification_header_afternoon_2
                2 -> R.drawable.notification_header_afternoon_3
                3 -> R.drawable.notification_header_afternoon_4
                else -> R.drawable.notification_header_afternoon_5
            }
        }
    }

    private fun shareBackgroundRes(categoryKey: String, paletteIndex: Int): Int {
        return when (categoryKey) {
            "morning" -> when (paletteIndex) {
                0 -> R.drawable.notification_share_morning_1
                1 -> R.drawable.notification_share_morning_2
                2 -> R.drawable.notification_share_morning_3
                3 -> R.drawable.notification_share_morning_4
                else -> R.drawable.notification_share_morning_5
            }
            "night" -> when (paletteIndex) {
                0 -> R.drawable.notification_share_night_1
                1 -> R.drawable.notification_share_night_2
                2 -> R.drawable.notification_share_night_3
                3 -> R.drawable.notification_share_night_4
                else -> R.drawable.notification_share_night_5
            }
            else -> when (paletteIndex) {
                0 -> R.drawable.notification_share_afternoon_1
                1 -> R.drawable.notification_share_afternoon_2
                2 -> R.drawable.notification_share_afternoon_3
                3 -> R.drawable.notification_share_afternoon_4
                else -> R.drawable.notification_share_afternoon_5
            }
        }
    }

    private fun circularAvatarBitmap(source: Bitmap): Bitmap {
        val size = 96
        val strokeWidth = 6f
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG)
        val radius = size / 2f
        val innerRadius = radius - strokeWidth
        val center = radius

        paint.color = Color.WHITE
        paint.style = Paint.Style.FILL
        canvas.drawCircle(center, center, radius, paint)

        val clipPath = Path().apply {
            addCircle(center, center, innerRadius, Path.Direction.CW)
        }
        canvas.save()
        canvas.clipPath(clipPath)
        paint.reset()
        paint.isAntiAlias = true
        paint.isFilterBitmap = true
        paint.isDither = true

        val innerSize = innerRadius * 2f
        val scale = minOf(innerSize / source.width.toFloat(), innerSize / source.height.toFloat())
        val drawWidth = source.width * scale
        val drawHeight = source.height * scale
        val left = center - drawWidth / 2f
        val top = center - drawHeight / 2f
        val dst = RectF(left, top, left + drawWidth, top + drawHeight)
        canvas.drawBitmap(source, null, dst, paint)
        canvas.restore()

        paint.reset()
        paint.isAntiAlias = true
        paint.color = Color.WHITE
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = strokeWidth
        canvas.drawCircle(center, center, radius - strokeWidth / 2f, paint)
        return bitmap
    }

    private fun isReminderCategory(categoryKey: String): Boolean {
        return categoryKey == "morning" ||
            categoryKey == "afternoon" ||
            categoryKey == "night" ||
            categoryKey == "welcome"
    }

    private fun loadDeviceProfile(context: Context): DeviceProfile {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val currentUid = flutterPref(prefs, "last_known_auth_uid_v1")
        val identityMode = flutterProfilePref(prefs, "poster_profile_identity_mode", currentUid)
        val businessName = flutterProfilePref(prefs, "poster_profile_business_name", currentUid)
        val businessLogoUrl = flutterProfilePref(prefs, "poster_profile_business_logo_url", currentUid)
        val nameTelugu = flutterProfilePref(prefs, "poster_profile_name_telugu", currentUid)
        val nameEnglish = flutterProfilePref(prefs, "poster_profile_name_english", currentUid)
        val genericName = flutterProfilePref(prefs, "poster_profile_name", currentUid)
        val photoUrl = flutterProfilePref(prefs, "poster_profile_photo_url", currentUid)
        val originalPhotoUrl = flutterProfilePref(prefs, "poster_profile_original_photo_url", currentUid)
        val languageCode = flutterPref(prefs, "selected_region_language_code_v1")
            .ifBlank { flutterPref(prefs, "selected_language") }
        val resolvedName =
            if (identityMode == "business" && businessName.isNotBlank()) businessName
            else listOf(nameTelugu, nameEnglish, genericName).firstOrNull { it.isNotBlank() }.orEmpty()
        val resolvedPhotoUrl =
            if (identityMode == "business" && businessLogoUrl.isNotBlank()) businessLogoUrl
            else listOf(photoUrl, originalPhotoUrl).firstOrNull { it.isNotBlank() }.orEmpty()
        return DeviceProfile(
            resolvedName = resolvedName,
            resolvedPhotoUrl = resolvedPhotoUrl,
            languageCode = languageCode,
        )
    }

    private fun flutterPref(prefs: SharedPreferences, key: String): String {
        return prefs.getString("flutter.$key", "").orEmpty().trim()
    }

    private fun flutterProfilePref(prefs: SharedPreferences, key: String, uid: String): String {
        if (uid.isNotBlank()) {
            return prefs.getString("flutter.${key}_$uid", "").orEmpty().trim()
        }
        return flutterPref(prefs, key)
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
            val bytes = connection.inputStream.use { input ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(16 * 1024)
                while (true) {
                    val read = input.read(buffer)
                    if (read <= 0) {
                        break
                    }
                    output.write(buffer, 0, read)
                }
                output.toByteArray()
            }
            decodeSampledBitmap(bytes, maxWidth = 1080, maxHeight = 720)
        } catch (t: Throwable) {
            Log.w("ManaPosterNotif", "bitmap download failed: $url", t)
            null
        } finally {
            connection?.disconnect()
        }
    }

    private fun decodeSampledBitmap(bytes: ByteArray, maxWidth: Int, maxHeight: Int): Bitmap? {
        if (bytes.isEmpty()) {
            return null
        }
        val bounds = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            return null
        }
        val options = BitmapFactory.Options().apply {
            inPreferredConfig = Bitmap.Config.RGB_565
            inDither = true
            inSampleSize = calculateInSampleSize(bounds.outWidth, bounds.outHeight, maxWidth, maxHeight)
        }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    }

    private fun calculateInSampleSize(width: Int, height: Int, maxWidth: Int, maxHeight: Int): Int {
        var sampleSize = 1
        var halfWidth = width / 2
        var halfHeight = height / 2
        while ((halfWidth / sampleSize) >= maxWidth || (halfHeight / sampleSize) >= maxHeight) {
            sampleSize *= 2
        }
        return sampleSize.coerceAtLeast(1)
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

    private fun localizedReminderCopy(categoryKey: String, userName: String, languageCode: String): ReminderCopy {
        val language = normalizeLanguageCode(languageCode)
        val lexicon = notificationLexicon(language)
        val name = userName.ifBlank { lexicon.user }
        return when (categoryKey) {
            "morning" -> ReminderCopy(
                title = lexicon.morningTitle,
                body = lexicon.morningBody,
                header = lexicon.morningHeader(name),
                footer = lexicon.share,
            )

            "night" -> ReminderCopy(
                title = lexicon.nightTitle,
                body = lexicon.nightBody,
                header = lexicon.nightHeader(name),
                footer = lexicon.share,
            )

            "welcome" -> ReminderCopy(
                title = lexicon.welcomeTitle,
                body = lexicon.welcomeBody(name),
                header = lexicon.welcomeHeader(name),
                footer = lexicon.share,
            )

            else -> ReminderCopy(
                title = lexicon.afternoonTitle,
                body = lexicon.afternoonBody,
                header = lexicon.afternoonHeader(name),
                footer = lexicon.share,
            )
        }
    }

    private fun normalizeLanguageCode(raw: String): String {
        return when (raw.trim().lowercase()) {
            "telugu" -> "te"
            "hindi" -> "hi"
            "english" -> "en"
            "tamil" -> "ta"
            "kannada" -> "kn"
            "malayalam" -> "ml"
            "marathi" -> "mr"
            "gujarati" -> "gu"
            "bengali" -> "bn"
            "odia" -> "or"
            "punjabi" -> "pa"
            "assamese" -> "as"
            "nepali" -> "ne"
            "konkani" -> "kok"
            else -> raw.trim().lowercase().ifBlank { "en" }
        }
    }

    private fun notificationLexicon(languageCode: String): NotificationLexicon {
        return when (languageCode) {
            "te" -> NotificationLexicon(
                user = "\u0C2F\u0C42\u0C1C\u0C30\u0C4D",
                share = "\u0C37\u0C47\u0C30\u0C4D \u0C1A\u0C47\u0C2F\u0C02\u0C21\u0C3F",
                morningTitle = "\u0C36\u0C41\u0C2D\u0C4B\u0C26\u0C2F\u0C02",
                afternoonTitle = "\u0C36\u0C41\u0C2D \u0C2E\u0C27\u0C4D\u0C2F\u0C3E\u0C39\u0C4D\u0C28\u0C02",
                nightTitle = "\u0C36\u0C41\u0C2D \u0C30\u0C3E\u0C24\u0C4D\u0C30\u0C3F",
                welcomeTitle = "Mana Poster \u0C15\u0C3F \u0C38\u0C4D\u0C35\u0C3E\u0C17\u0C24\u0C02",
                morningBody = "\u0C2E\u0C40 \u0C09\u0C26\u0C2F\u0C02 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C02\u0C26\u0C3F. \u0C07\u0C2A\u0C4D\u0C2A\u0C41\u0C21\u0C47 \u0C37\u0C47\u0C30\u0C4D \u0C1A\u0C47\u0C2F\u0C02\u0C21\u0C3F.",
                afternoonBody = "\u0C2E\u0C40 \u0C2E\u0C27\u0C4D\u0C2F\u0C3E\u0C39\u0C4D\u0C28 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C02\u0C26\u0C3F. \u0C07\u0C2A\u0C4D\u0C2A\u0C41\u0C21\u0C47 \u0C37\u0C47\u0C30\u0C4D \u0C1A\u0C47\u0C2F\u0C02\u0C21\u0C3F.",
                nightBody = "\u0C2E\u0C40 \u0C30\u0C3E\u0C24\u0C4D\u0C30\u0C3F \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C02\u0C26\u0C3F. \u0C07\u0C2A\u0C4D\u0C2A\u0C41\u0C21\u0C47 \u0C37\u0C47\u0C30\u0C4D \u0C1A\u0C47\u0C2F\u0C02\u0C21\u0C3F.",
                morningHeader = { "${it}, \u0C2E\u0C40 \u0C09\u0C26\u0C2F\u0C02 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C02\u0C26\u0C3F" },
                afternoonHeader = { "${it}, \u0C2E\u0C40 \u0C2E\u0C27\u0C4D\u0C2F\u0C3E\u0C39\u0C4D\u0C28 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C02\u0C26\u0C3F" },
                nightHeader = { "${it}, \u0C2E\u0C40 \u0C30\u0C3E\u0C24\u0C4D\u0C30\u0C3F \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C02\u0C26\u0C3F" },
                welcomeHeader = { "${it}, \u0C2E\u0C40 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D \u0C37\u0C47\u0C30\u0C4D \u0C1A\u0C47\u0C2F\u0C21\u0C3E\u0C28\u0C3F\u0C15\u0C3F \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C02\u0C26\u0C3F" },
                welcomeBody = { "${it}, \u0C2E\u0C40 \u0C15\u0C4B\u0C38\u0C02 \u0C30\u0C4B\u0C1C\u0C41\u0C35\u0C3E\u0C30\u0C40 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D\u0C32\u0C41 \u0C38\u0C3F\u0C26\u0C4D\u0C27\u0C02\u0C17\u0C3E \u0C09\u0C28\u0C4D\u0C28\u0C3E\u0C2F\u0C3F. \u0C2F\u0C3E\u0C2A\u0C4D \u0C13\u0C2A\u0C46\u0C28\u0C4D \u0C1A\u0C47\u0C38\u0C3F \u0C37\u0C47\u0C30\u0C4D \u0C1A\u0C47\u0C2F\u0C02\u0C21\u0C3F." },
            )
            "hi" -> NotificationLexicon(
                user = "\u092F\u0942\u091C\u093C\u0930",
                share = "\u0936\u0947\u092F\u0930 \u0915\u0930\u0947\u0902",
                morningTitle = "\u0938\u0941\u092A\u094D\u0930\u092D\u093E\u0924",
                afternoonTitle = "\u0936\u0941\u092D \u0926\u094B\u092A\u0939\u0930",
                nightTitle = "\u0936\u0941\u092D \u0930\u093E\u0924\u094D\u0930\u093F",
                welcomeTitle = "Mana Poster \u092E\u0947\u0902 \u0906\u092A\u0915\u093E \u0938\u094D\u0935\u093E\u0917\u0924 \u0939\u0948",
                morningBody = "\u0906\u092A\u0915\u093E \u0938\u0941\u092C\u0939 \u0915\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u0948\u092F\u093E\u0930 \u0939\u0948\u0964 \u0905\u092D\u0940 \u0936\u0947\u092F\u0930 \u0915\u0930\u0947\u0902\u0964",
                afternoonBody = "\u0906\u092A\u0915\u093E \u0926\u094B\u092A\u0939\u0930 \u0915\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u0948\u092F\u093E\u0930 \u0939\u0948\u0964 \u0905\u092D\u0940 \u0936\u0947\u092F\u0930 \u0915\u0930\u0947\u0902\u0964",
                nightBody = "\u0906\u092A\u0915\u093E \u0930\u093E\u0924 \u0915\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u0948\u092F\u093E\u0930 \u0939\u0948\u0964 \u0905\u092D\u0940 \u0936\u0947\u092F\u0930 \u0915\u0930\u0947\u0902\u0964",
                morningHeader = { "${it}, \u0906\u092A\u0915\u093E \u0938\u0941\u092C\u0939 \u0915\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u0948\u092F\u093E\u0930 \u0939\u0948" },
                afternoonHeader = { "${it}, \u0906\u092A\u0915\u093E \u0926\u094B\u092A\u0939\u0930 \u0915\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u0948\u092F\u093E\u0930 \u0939\u0948" },
                nightHeader = { "${it}, \u0906\u092A\u0915\u093E \u0930\u093E\u0924 \u0915\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u0948\u092F\u093E\u0930 \u0939\u0948" },
                welcomeHeader = { "${it}, \u0906\u092A\u0915\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0936\u0947\u092F\u0930 \u0915\u0930\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0924\u0948\u092F\u093E\u0930 \u0939\u0948" },
                welcomeBody = { "${it}, \u0906\u092A\u0915\u0947 \u0932\u093F\u090F \u0930\u094B\u091C\u093C \u0915\u0947 \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u0948\u092F\u093E\u0930 \u0939\u0948\u0902\u0964 \u0910\u092A \u0916\u094B\u0932\u0947\u0902 \u0914\u0930 \u0936\u0947\u092F\u0930 \u0915\u0930\u0947\u0902\u0964" },
            )
            "ta" -> NotificationLexicon(
                user = "\u0BAA\u0BAF\u0BA9\u0BB0\u0BCD",
                share = "\u0BAA\u0B95\u0BBF\u0BB0\u0BCD",
                morningTitle = "\u0B95\u0BBE\u0BB2\u0BC8 \u0BB5\u0BA3\u0B95\u0BCD\u0B95\u0BAE\u0BCD",
                afternoonTitle = "\u0BAE\u0BA4\u0BBF\u0BAF \u0BB5\u0BA3\u0B95\u0BCD\u0B95\u0BAE\u0BCD",
                nightTitle = "\u0B87\u0BA9\u0BBF\u0BAF \u0B87\u0BB0\u0BB5\u0BC1",
                welcomeTitle = "Mana Poster-\u0B95\u0BCD\u0B95\u0BC1 \u0BB5\u0BB0\u0BB5\u0BC7\u0BB1\u0BCD\u0B95\u0BBF\u0BB1\u0BCB\u0BAE\u0BCD",
                morningBody = "\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B95\u0BBE\u0BB2\u0BC8 \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD. \u0B87\u0BAA\u0BCD\u0BAA\u0BCB\u0BA4\u0BC1 \u0BAA\u0B95\u0BBF\u0BB0\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD.",
                afternoonBody = "\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0BAE\u0BA4\u0BBF\u0BAF \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD. \u0B87\u0BAA\u0BCD\u0BAA\u0BCB\u0BA4\u0BC1 \u0BAA\u0B95\u0BBF\u0BB0\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD.",
                nightBody = "\u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B87\u0BB0\u0BB5\u0BC1 \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD. \u0B87\u0BAA\u0BCD\u0BAA\u0BCB\u0BA4\u0BC1 \u0BAA\u0B95\u0BBF\u0BB0\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD.",
                morningHeader = { "${it}, \u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B95\u0BBE\u0BB2\u0BC8 \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD" },
                afternoonHeader = { "${it}, \u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0BAE\u0BA4\u0BBF\u0BAF \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD" },
                nightHeader = { "${it}, \u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B87\u0BB0\u0BB5\u0BC1 \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD" },
                welcomeHeader = { "${it}, \u0B89\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD \u0BAA\u0B95\u0BBF\u0BB0 \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD" },
                welcomeBody = { "${it}, \u0BA4\u0BBF\u0BA9\u0B9A\u0BB0\u0BBF \u0BAA\u0BCB\u0BB8\u0BCD\u0B9F\u0BB0\u0BCD\u0B95\u0BB3\u0BCD \u0BA4\u0BAF\u0BBE\u0BB0\u0BCD. \u0B86\u0BAA\u0BCD\u0BAA\u0BC8 \u0BA4\u0BBF\u0BB1\u0BA8\u0BCD\u0BA4\u0BC1 \u0BAA\u0B95\u0BBF\u0BB0\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD." },
            )
            "kn" -> NotificationLexicon(
                user = "\u0CAC\u0CB3\u0C95\u0CC6\u0CA6\u0CBE\u0CB0",
                share = "\u0CB9\u0C82\u0C9A\u0CBF",
                morningTitle = "\u0CB6\u0CC1\u0CAD\u0CCB\u0CA6\u0CAF",
                afternoonTitle = "\u0CB6\u0CC1\u0CAD \u0CAE\u0CA7\u0CCD\u0CAF\u0CBE\u0CB9\u0CCD\u0CA8",
                nightTitle = "\u0CB6\u0CC1\u0CAD \u0CB0\u0CBE\u0CA4\u0CCD\u0CB0\u0CBF",
                welcomeTitle = "Mana Poster \u0C97\u0CC6 \u0CB8\u0CCD\u0CB5\u0CBE\u0C97\u0CA4",
                morningBody = "\u0CA8\u0CBF\u0CAE\u0CCD\u0CAE \u0CAC\u0CC6\u0CB3\u0C97\u0CBF\u0CA8 \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CA6\u0CC6. \u0C88\u0C97 \u0CB9\u0C82\u0C9A\u0CBF.",
                afternoonBody = "\u0CA8\u0CBF\u0CAE\u0CCD\u0CAE \u0CAE\u0CA7\u0CCD\u0CAF\u0CBE\u0CB9\u0CCD\u0CA8\u0CA6 \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CA6\u0CC6. \u0C88\u0C97 \u0CB9\u0C82\u0C9A\u0CBF.",
                nightBody = "\u0CA8\u0CBF\u0CAE\u0CCD\u0CAE \u0CB0\u0CBE\u0CA4\u0CCD\u0CB0\u0CBF\u0CAF \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CA6\u0CC6. \u0C88\u0C97 \u0CB9\u0C82\u0C9A\u0CBF.",
                morningHeader = { "${it}, \u0CA8\u0CBF\u0CAE\u0CCD\u0CAE \u0CAC\u0CC6\u0CB3\u0C97\u0CBF\u0CA8 \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CA6\u0CC6" },
                afternoonHeader = { "${it}, \u0CA8\u0CBF\u0CAE\u0CCD\u0CAE \u0CAE\u0CA7\u0CCD\u0CAF\u0CBE\u0CB9\u0CCD\u0CA8\u0CA6 \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CA6\u0CC6" },
                nightHeader = { "${it}, \u0CA8\u0CBF\u0CAE\u0CCD\u0CAE \u0CB0\u0CBE\u0CA4\u0CCD\u0CB0\u0CBF\u0CAF \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CA6\u0CC6" },
                welcomeHeader = { "${it}, \u0CA8\u0CBF\u0CAE\u0CCD\u0CAE \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD \u0CB9\u0C82\u0C9A\u0CB2\u0CC1 \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CA6\u0CC6" },
                welcomeBody = { "${it}, \u0CA8\u0CBF\u0CAE\u0C97\u0CBE\u0C97\u0CBF \u0CA6\u0CBF\u0CA8\u0CA8\u0CBF\u0CA4\u0CCD\u0CAF\u0CA6 \u0CAA\u0CCB\u0CB8\u0CCD\u0C9F\u0CB0\u0CCD\u200C\u0C97\u0CB3\u0CC1 \u0CB8\u0CBF\u0CA6\u0CCD\u0CA7\u0CB5\u0CBE\u0C97\u0CBF\u0CB5\u0CC6. \u0C86\u0CAA\u0CCD \u0CA4\u0CC6\u0CB0\u0CC6\u0CAF\u0CBF\u0CB0\u0CBF \u0CAE\u0CA4\u0CCD\u0CA4\u0CC1 \u0CB9\u0C82\u0C9A\u0CBF." },
            )
            "ml" -> NotificationLexicon(
                user = "\u0D09\u0D2A\u0D2F\u0D4B\u0D15\u0D4D\u0D24\u0D3E\u0D35\u0D4D",
                share = "\u0D37\u0D46\u0D2F\u0D7C",
                morningTitle = "\u0D38\u0D41\u0D2A\u0D4D\u0D30\u0D2D\u0D3E\u0D24\u0D02",
                afternoonTitle = "\u0D36\u0D41\u0D2D \u0D09\u0D1A\u0D4D\u0D1A\u0D2F\u0D4D\u0D15\u0D4D\u0D15\u0D4D",
                nightTitle = "\u0D36\u0D41\u0D2D \u0D30\u0D3E\u0D24\u0D4D\u0D30\u0D3F",
                welcomeTitle = "Mana Poster-\u0D32\u0D47\u0D15\u0D4D\u0D15\u0D4D \u0D38\u0D4D\u0D35\u0D3E\u0D17\u0D24\u0D02",
                morningBody = "\u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D33\u0D41\u0D1F\u0D46 \u0D30\u0D3E\u0D35\u0D3F\u0D32\u0D46 \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D7C \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D. \u0D07\u0D2A\u0D4D\u0D2A\u0D4B\u0D7E \u0D37\u0D46\u0D2F\u0D7C \u0D1A\u0D46\u0D2F\u0D4D\u0D2F\u0D42.",
                afternoonBody = "\u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D33\u0D41\u0D1F\u0D46 \u0D09\u0D1A\u0D4D\u0D1A\u0D2F\u0D3F\u0D32\u0D46 \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D7C \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D. \u0D07\u0D2A\u0D4D\u0D2A\u0D4B\u0D7E \u0D37\u0D46\u0D2F\u0D7C \u0D1A\u0D46\u0D2F\u0D4D\u0D2F\u0D42.",
                nightBody = "\u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D33\u0D41\u0D1F\u0D46 \u0D30\u0D3E\u0D24\u0D4D\u0D30\u0D3F \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D7C \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D. \u0D07\u0D2A\u0D4D\u0D2A\u0D4B\u0D7E \u0D37\u0D46\u0D2F\u0D7C \u0D1A\u0D46\u0D2F\u0D4D\u0D2F\u0D42.",
                morningHeader = { "${it}, \u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D33\u0D41\u0D1F\u0D46 \u0D30\u0D3E\u0D35\u0D3F\u0D32\u0D46 \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D7C \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D" },
                afternoonHeader = { "${it}, \u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D33\u0D41\u0D1F\u0D46 \u0D09\u0D1A\u0D4D\u0D1A\u0D2F\u0D3F\u0D32\u0D46 \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D7C \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D" },
                nightHeader = { "${it}, \u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D33\u0D41\u0D1F\u0D46 \u0D30\u0D3E\u0D24\u0D4D\u0D30\u0D3F \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D7C \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D" },
                welcomeHeader = { "${it}, \u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D33\u0D41\u0D1F\u0D46 \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D7C \u0D37\u0D46\u0D2F\u0D7C \u0D1A\u0D46\u0D2F\u0D4D\u0D2F\u0D3E\u0D7B \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D" },
                welcomeBody = { "${it}, \u0D26\u0D3F\u0D35\u0D38\u0D47\u0D28\u0D2F\u0D41\u0D33\u0D4D\u0D33 \u0D2A\u0D4B\u0D38\u0D4D\u0D31\u0D4D\u0D31\u0D31\u0D41\u0D15\u0D7E \u0D24\u0D2F\u0D4D\u0D2F\u0D3E\u0D31\u0D3E\u0D23\u0D4D. \u0D06\u0D2A\u0D4D\u0D2A\u0D4D \u0D24\u0D41\u0D31\u0D28\u0D4D\u0D28\u0D4D \u0D37\u0D46\u0D2F\u0D7C \u0D1A\u0D46\u0D2F\u0D4D\u0D2F\u0D42." },
            )
            "mr" -> NotificationLexicon(
                user = "\u092F\u0942\u091C\u0930",
                share = "\u0936\u0947\u0905\u0930 \u0915\u0930\u093E",
                morningTitle = "\u0936\u0941\u092D \u0938\u0915\u093E\u0933",
                afternoonTitle = "\u0936\u0941\u092D \u0926\u0941\u092A\u093E\u0930",
                nightTitle = "\u0936\u0941\u092D \u0930\u093E\u0924\u094D\u0930\u0940",
                welcomeTitle = "Mana Poster \u092E\u0927\u094D\u092F\u0947 \u0938\u094D\u0935\u093E\u0917\u0924",
                morningBody = "\u0924\u0941\u092E\u091A\u093E \u0938\u0915\u093E\u0933\u091A\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947. \u0906\u0924\u094D\u0924\u093E\u091A \u0936\u0947\u0905\u0930 \u0915\u0930\u093E.",
                afternoonBody = "\u0924\u0941\u092E\u091A\u093E \u0926\u0941\u092A\u093E\u0930\u091A\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947. \u0906\u0924\u094D\u0924\u093E\u091A \u0936\u0947\u0905\u0930 \u0915\u0930\u093E.",
                nightBody = "\u0924\u0941\u092E\u091A\u093E \u0930\u093E\u0924\u094D\u0930\u0940\u091A\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947. \u0906\u0924\u094D\u0924\u093E\u091A \u0936\u0947\u0905\u0930 \u0915\u0930\u093E.",
                morningHeader = { "${it}, \u0924\u0941\u092E\u091A\u093E \u0938\u0915\u093E\u0933\u091A\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947" },
                afternoonHeader = { "${it}, \u0924\u0941\u092E\u091A\u093E \u0926\u0941\u092A\u093E\u0930\u091A\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947" },
                nightHeader = { "${it}, \u0924\u0941\u092E\u091A\u093E \u0930\u093E\u0924\u094D\u0930\u0940\u091A\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947" },
                welcomeHeader = { "${it}, \u0924\u0941\u092E\u091A\u093E \u092A\u094B\u0938\u094D\u091F\u0930 \u0936\u0947\u0905\u0930 \u0915\u0930\u0923\u094D\u092F\u093E\u0938\u093E\u0920\u0940 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947" },
                welcomeBody = { "${it}, \u0924\u0941\u092E\u091A\u094D\u092F\u093E\u0938\u093E\u0920\u0940 \u0930\u094B\u091C\u091A\u0947 \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0939\u0947\u0924. \u0905\u0945\u092A \u0909\u0918\u0921\u093E \u0906\u0923\u093F \u0936\u0947\u0905\u0930 \u0915\u0930\u093E." },
            )
            "gu" -> NotificationLexicon(
                user = "\u0AAF\u0AC2\u0A9D\u0AB0",
                share = "\u0AB6\u0AC7\u0AB0 \u0A95\u0AB0\u0ACB",
                morningTitle = "\u0AB8\u0AC1\u0AAA\u0ACD\u0AB0\u0AAD\u0ABE\u0AA4",
                afternoonTitle = "\u0AB6\u0AC1\u0AAD \u0AAC\u0AAA\u0ACB\u0AB0",
                nightTitle = "\u0AB6\u0AC1\u0AAD \u0AB0\u0ABE\u0AA4\u0ACD\u0AB0\u0ABF",
                welcomeTitle = "Mana Poster \u0AAE\u0ABE\u0A82 \u0A86\u0AAA\u0AA8\u0AC1\u0A82 \u0AB8\u0ACD\u0AB5\u0ABE\u0A97\u0AA4 \u0A9B\u0AC7",
                morningBody = "\u0AA4\u0AAE\u0ABE\u0AB0\u0AC1\u0A82 \u0AB8\u0AB5\u0ABE\u0AB0\u0AA8\u0AC1\u0A82 \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7. \u0AB9\u0AAE\u0AA3\u0ABE\u0A82 \u0AB6\u0AC7\u0AB0 \u0A95\u0AB0\u0ACB.",
                afternoonBody = "\u0AA4\u0AAE\u0ABE\u0AB0\u0AC1\u0A82 \u0AAC\u0AAA\u0ACB\u0AB0\u0AA8\u0AC1\u0A82 \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7. \u0AB9\u0AAE\u0AA3\u0ABE\u0A82 \u0AB6\u0AC7\u0AB0 \u0A95\u0AB0\u0ACB.",
                nightBody = "\u0AA4\u0AAE\u0ABE\u0AB0\u0AC1\u0A82 \u0AB0\u0ABE\u0AA4\u0ACD\u0AB0\u0ABF\u0AA8\u0AC1\u0A82 \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7. \u0AB9\u0AAE\u0AA3\u0ABE\u0A82 \u0AB6\u0AC7\u0AB0 \u0A95\u0AB0\u0ACB.",
                morningHeader = { "${it}, \u0AA4\u0AAE\u0ABE\u0AB0\u0AC1\u0A82 \u0AB8\u0AB5\u0ABE\u0AB0\u0AA8\u0AC1\u0A82 \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7" },
                afternoonHeader = { "${it}, \u0AA4\u0AAE\u0ABE\u0AB0\u0AC1\u0A82 \u0AAC\u0AAA\u0ACB\u0AB0\u0AA8\u0AC1\u0A82 \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7" },
                nightHeader = { "${it}, \u0AA4\u0AAE\u0ABE\u0AB0\u0AC1\u0A82 \u0AB0\u0ABE\u0AA4\u0ACD\u0AB0\u0ABF\u0AA8\u0AC1\u0A82 \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7" },
                welcomeHeader = { "${it}, \u0AA4\u0AAE\u0ABE\u0AB0\u0AC1\u0A82 \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AB6\u0AC7\u0AB0 \u0A95\u0AB0\u0AB5\u0ABE \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7" },
                welcomeBody = { "${it}, \u0AA4\u0AAE\u0ABE\u0AB0\u0ABE \u0AAE\u0ABE\u0A9F\u0AC7 \u0AB0\u0ACB\u0A9C\u0AA8\u0ABE \u0AAA\u0ACB\u0AB8\u0ACD\u0A9F\u0AB0 \u0AA4\u0AC8\u0AAF\u0ABE\u0AB0 \u0A9B\u0AC7. \u0A8F\u0AAA \u0A96\u0ACB\u0AB2\u0ACB \u0A85\u0AA8\u0AC7 \u0AB6\u0AC7\u0AB0 \u0A95\u0AB0\u0ACB." },
            )
            "bn" -> NotificationLexicon(
                user = "\u09AC\u09CD\u09AF\u09AC\u09B9\u09BE\u09B0\u0995\u09BE\u09B0\u09C0",
                share = "\u09B6\u09C7\u09AF\u09BC\u09BE\u09B0 \u0995\u09B0\u09C1\u09A8",
                morningTitle = "\u09B6\u09C1\u09AD \u09B8\u0995\u09BE\u09B2",
                afternoonTitle = "\u09B6\u09C1\u09AD \u0985\u09AA\u09B0\u09BE\u09B9\u09CD\u09A8",
                nightTitle = "\u09B6\u09C1\u09AD \u09B0\u09BE\u09A4\u09CD\u09B0\u09BF",
                welcomeTitle = "Mana Poster-\u098F \u09B8\u09CD\u09AC\u09BE\u0997\u09A4\u09AE",
                morningBody = "\u0986\u09AA\u09A8\u09BE\u09B0 \u09B8\u0995\u09BE\u09B2\u09C7\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4\u0964 \u098F\u0996\u09A8\u0987 \u09B6\u09C7\u09AF\u09BC\u09BE\u09B0 \u0995\u09B0\u09C1\u09A8\u0964",
                afternoonBody = "\u0986\u09AA\u09A8\u09BE\u09B0 \u09A6\u09C1\u09AA\u09C1\u09B0\u09C7\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4\u0964 \u098F\u0996\u09A8\u0987 \u09B6\u09C7\u09AF\u09BC\u09BE\u09B0 \u0995\u09B0\u09C1\u09A8\u0964",
                nightBody = "\u0986\u09AA\u09A8\u09BE\u09B0 \u09B0\u09BE\u09A4\u09C7\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4\u0964 \u098F\u0996\u09A8\u0987 \u09B6\u09C7\u09AF\u09BC\u09BE\u09B0 \u0995\u09B0\u09C1\u09A8\u0964",
                morningHeader = { "${it}, \u0986\u09AA\u09A8\u09BE\u09B0 \u09B8\u0995\u09BE\u09B2\u09C7\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4" },
                afternoonHeader = { "${it}, \u0986\u09AA\u09A8\u09BE\u09B0 \u09A6\u09C1\u09AA\u09C1\u09B0\u09C7\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4" },
                nightHeader = { "${it}, \u0986\u09AA\u09A8\u09BE\u09B0 \u09B0\u09BE\u09A4\u09C7\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4" },
                welcomeHeader = { "${it}, \u0986\u09AA\u09A8\u09BE\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09B6\u09C7\u09AF\u09BC\u09BE\u09B0 \u0995\u09B0\u09BE\u09B0 \u099C\u09A8\u09CD\u09AF \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4" },
                welcomeBody = { "${it}, \u0986\u09AA\u09A8\u09BE\u09B0 \u099C\u09A8\u09CD\u09AF \u09AA\u09CD\u09B0\u09A4\u09BF\u09A6\u09BF\u09A8\u09C7\u09B0 \u09AA\u09CB\u09B8\u09CD\u099F\u09BE\u09B0 \u09AA\u09CD\u09B0\u09B8\u09CD\u09A4\u09C1\u09A4\u0964 \u0985\u09CD\u09AF\u09BE\u09AA \u0996\u09C1\u09B2\u09C1\u09A8 \u098F\u09AC\u0982 \u09B6\u09C7\u09AF\u09BC\u09BE\u09B0 \u0995\u09B0\u09C1\u09A8\u0964" },
            )
            "pa" -> NotificationLexicon(
                user = "\u0A2F\u0A42\u0A1C\u0A3C\u0A30",
                share = "\u0A38\u0A3C\u0A47\u0A05\u0A30 \u0A15\u0A30\u0A4B",
                morningTitle = "\u0A38\u0A3C\u0A41\u0A2D \u0A38\u0A35\u0A47\u0A30",
                afternoonTitle = "\u0A38\u0A3C\u0A41\u0A2D \u0A26\u0A41\u0A2A\u0A39\u0A3F\u0A30",
                nightTitle = "\u0A38\u0A3C\u0A41\u0A2D \u0A30\u0A3E\u0A24\u0A30\u0A40",
                welcomeTitle = "Mana Poster \u0A35\u0A3F\u0A71\u0A1A \u0A38\u0A41\u0A06\u0A17\u0A24 \u0A39\u0A48",
                morningBody = "\u0A24\u0A41\u0A39\u0A3E\u0A21\u0A3E \u0A38\u0A35\u0A47\u0A30 \u0A26\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A48\u0964 \u0A39\u0A41\u0A23\u0A47 \u0A38\u0A3C\u0A47\u0A05\u0A30 \u0A15\u0A30\u0A4B\u0964",
                afternoonBody = "\u0A24\u0A41\u0A39\u0A3E\u0A21\u0A3E \u0A26\u0A41\u0A2A\u0A39\u0A3F\u0A30 \u0A26\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A48\u0964 \u0A39\u0A41\u0A23\u0A47 \u0A38\u0A3C\u0A47\u0A05\u0A30 \u0A15\u0A30\u0A4B\u0964",
                nightBody = "\u0A24\u0A41\u0A39\u0A3E\u0A21\u0A3E \u0A30\u0A3E\u0A24 \u0A26\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A48\u0964 \u0A39\u0A41\u0A23\u0A47 \u0A38\u0A3C\u0A47\u0A05\u0A30 \u0A15\u0A30\u0A4B\u0964",
                morningHeader = { "${it}, \u0A24\u0A41\u0A39\u0A3E\u0A21\u0A3E \u0A38\u0A35\u0A47\u0A30 \u0A26\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A48" },
                afternoonHeader = { "${it}, \u0A24\u0A41\u0A39\u0A3E\u0A21\u0A3E \u0A26\u0A41\u0A2A\u0A39\u0A3F\u0A30 \u0A26\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A48" },
                nightHeader = { "${it}, \u0A24\u0A41\u0A39\u0A3E\u0A21\u0A3E \u0A30\u0A3E\u0A24 \u0A26\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A48" },
                welcomeHeader = { "${it}, \u0A24\u0A41\u0A39\u0A3E\u0A21\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A38\u0A3C\u0A47\u0A05\u0A30 \u0A15\u0A30\u0A28 \u0A32\u0A08 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A48" },
                welcomeBody = { "${it}, \u0A24\u0A41\u0A39\u0A3E\u0A21\u0A47 \u0A32\u0A08 \u0A30\u0A4B\u0A1C\u0A3C\u0A3E\u0A28\u0A3E \u0A2A\u0A4B\u0A38\u0A1F\u0A30 \u0A24\u0A3F\u0A06\u0A30 \u0A39\u0A28\u0964 \u0A10\u0A2A \u0A16\u0A4B\u0A32\u0A4D\u0A39\u0A4B \u0A05\u0A24\u0A47 \u0A38\u0A3C\u0A47\u0A05\u0A30 \u0A15\u0A30\u0A4B\u0964" },
            )
            "or" -> NotificationLexicon(
                user = "\u0B5F\u0B41\u0B1C\u0B30",
                share = "\u0B38\u0B47\u0B5F\u0B3E\u0B30 \u0B15\u0B30\u0B28\u0B4D\u0B24\u0B41",
                morningTitle = "\u0B38\u0B41\u0B2A\u0B4D\u0B30\u0B2D\u0B3E\u0B24",
                afternoonTitle = "\u0B36\u0B41\u0B2D \u0B2E\u0B27\u0B4D\u0B5F\u0B3E\u0B39\u0B4D\u0B28",
                nightTitle = "\u0B36\u0B41\u0B2D \u0B30\u0B3E\u0B24\u0B4D\u0B30\u0B3F",
                welcomeTitle = "Mana Poster \u0B15\u0B41 \u0B38\u0B4D\u0B71\u0B3E\u0B17\u0B24",
                morningBody = "\u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B38\u0B15\u0B3E\u0B33 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24\u0964 \u0B0F\u0B2C\u0B47 \u0B38\u0B47\u0B5F\u0B3E\u0B30 \u0B15\u0B30\u0B28\u0B4D\u0B24\u0B41\u0964",
                afternoonBody = "\u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B2E\u0B27\u0B4D\u0B5F\u0B3E\u0B39\u0B4D\u0B28 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24\u0964 \u0B0F\u0B2C\u0B47 \u0B38\u0B47\u0B5F\u0B3E\u0B30 \u0B15\u0B30\u0B28\u0B4D\u0B24\u0B41\u0964",
                nightBody = "\u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B30\u0B3E\u0B24\u0B3F\u0B30 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24\u0964 \u0B0F\u0B2C\u0B47 \u0B38\u0B47\u0B5F\u0B3E\u0B30 \u0B15\u0B30\u0B28\u0B4D\u0B24\u0B41\u0964",
                morningHeader = { "${it}, \u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B38\u0B15\u0B3E\u0B33 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24" },
                afternoonHeader = { "${it}, \u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B2E\u0B27\u0B4D\u0B5F\u0B3E\u0B39\u0B4D\u0B28 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24" },
                nightHeader = { "${it}, \u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B30\u0B3E\u0B24\u0B3F\u0B30 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24" },
                welcomeHeader = { "${it}, \u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B38\u0B47\u0B5F\u0B3E\u0B30 \u0B2A\u0B3E\u0B07\u0B01 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24" },
                welcomeBody = { "${it}, \u0B06\u0B2A\u0B23\u0B19\u0B4D\u0B15 \u0B2A\u0B3E\u0B07\u0B01 \u0B26\u0B48\u0B28\u0B3F\u0B15 \u0B2A\u0B4B\u0B37\u0B4D\u0B1F\u0B30 \u0B2A\u0B4D\u0B30\u0B38\u0B4D\u0B24\u0B41\u0B24\u0964 \u0B06\u0B2A\u0B4D \u0B16\u0B4B\u0B32\u0B28\u0B4D\u0B24\u0B41 \u0B0F\u0B2C\u0B02 \u0B38\u0B47\u0B5F\u0B3E\u0B30 \u0B15\u0B30\u0B28\u0B4D\u0B24\u0B41\u0964" },
            )
            "as" -> NotificationLexicon(
                user = "\u09AC\u09CD\u09AF\u09F1\u09B9\u09BE\u09F0\u0995\u09BE\u09F0\u09C0",
                share = "\u09B6\u09CD\u09AC\u09C7\u09AF\u09BC\u09BE\u09F0 \u0995\u09F0\u0995",
                morningTitle = "\u09B8\u09C1\u09AA\u09CD\u09F0\u09AD\u09BE\u09A4",
                afternoonTitle = "\u09B6\u09C1\u09AD \u09A6\u09C1\u09AA\u09F0\u09C0\u09AF\u09BC\u09BE",
                nightTitle = "\u09B6\u09C1\u09AD \u09F0\u09BE\u09A4\u09BF",
                welcomeTitle = "Mana Poster \u09B2\u09C8 \u09B8\u09CD\u09AC\u09BE\u0997\u09A4\u09AE",
                morningBody = "\u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09F0\u09BE\u09A4\u09BF\u09AA\u09C1\u09F1\u09BE\u09F0 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B8\u09BE\u099C\u09C1\u0964 \u098F\u09A4\u09BF\u09AF\u09BC\u09BE\u0987 \u09B6\u09CD\u09AC\u09C7\u09AF\u09BC\u09BE\u09F0 \u0995\u09F0\u0995\u0964",
                afternoonBody = "\u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09A6\u09C1\u09AA\u09F0\u09C0\u09AF\u09BC\u09BE\u09F0 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B8\u09BE\u099C\u09C1\u0964 \u098F\u09A4\u09BF\u09AF\u09BC\u09BE\u0987 \u09B6\u09CD\u09AC\u09C7\u09AF\u09BC\u09BE\u09F0 \u0995\u09F0\u0995\u0964",
                nightBody = "\u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09F0\u09BE\u09A4\u09BF\u09F0 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B8\u09BE\u099C\u09C1\u0964 \u098F\u09A4\u09BF\u09AF\u09BC\u09BE\u0987 \u09B6\u09CD\u09AC\u09C7\u09AF\u09BC\u09BE\u09F0 \u0995\u09F0\u0995\u0964",
                morningHeader = { "${it}, \u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09F0\u09BE\u09A4\u09BF\u09AA\u09C1\u09F1\u09BE\u09F0 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B8\u09BE\u099C\u09C1" },
                afternoonHeader = { "${it}, \u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09A6\u09C1\u09AA\u09F0\u09C0\u09AF\u09BC\u09BE\u09F0 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B8\u09BE\u099C\u09C1" },
                nightHeader = { "${it}, \u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09F0\u09BE\u09A4\u09BF\u09F0 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B8\u09BE\u099C\u09C1" },
                welcomeHeader = { "${it}, \u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B6\u09CD\u09AC\u09C7\u09AF\u09BC\u09BE\u09F0 \u0995\u09F0\u09BF\u09AC\u09B2\u09C8 \u09B8\u09BE\u099C\u09C1" },
                welcomeBody = { "${it}, \u0986\u09AA\u09CB\u09A8\u09BE\u09F0 \u09AC\u09BE\u09AC\u09C7 \u09A6\u09C8\u09A8\u09BF\u0995 \u09AA\u09CB\u09B7\u09CD\u099F\u09BE\u09F0 \u09B8\u09BE\u099C\u09C1\u0964 \u098F\u09AA \u0996\u09C1\u09B2\u09BF \u09B6\u09CD\u09AC\u09C7\u09AF\u09BC\u09BE\u09F0 \u0995\u09F0\u0995\u0964" },
            )
            "ne" -> NotificationLexicon(
                user = "\u092A\u094D\u0930\u092F\u094B\u0917\u0915\u0930\u094D\u0924\u093E",
                share = "\u0936\u0947\u092F\u0930 \u0917\u0930\u094D\u0928\u0941\u0939\u094B\u0938\u094D",
                morningTitle = "\u0936\u0941\u092D \u092C\u093F\u0939\u093E\u0928\u0940",
                afternoonTitle = "\u0936\u0941\u092D \u0926\u093F\u0909\u0901\u0938\u094B",
                nightTitle = "\u0936\u0941\u092D \u0930\u093E\u0924\u094D\u0930\u093F",
                welcomeTitle = "Mana Poster \u092E\u093E \u0938\u094D\u0935\u093E\u0917\u0924 \u091B",
                morningBody = "\u0924\u092A\u093E\u0908\u0902\u0915\u094B \u092C\u093F\u0939\u093E\u0928\u0915\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u091B\u0964 \u0905\u0939\u093F\u0932\u0947 \u0936\u0947\u092F\u0930 \u0917\u0930\u094D\u0928\u0941\u0939\u094B\u0938\u094D\u0964",
                afternoonBody = "\u0924\u092A\u093E\u0908\u0902\u0915\u094B \u0926\u093F\u0909\u0901\u0938\u094B\u0915\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u091B\u0964 \u0905\u0939\u093F\u0932\u0947 \u0936\u0947\u092F\u0930 \u0917\u0930\u094D\u0928\u0941\u0939\u094B\u0938\u094D\u0964",
                nightBody = "\u0924\u092A\u093E\u0908\u0902\u0915\u094B \u0930\u093E\u0924\u093F\u0915\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u091B\u0964 \u0905\u0939\u093F\u0932\u0947 \u0936\u0947\u092F\u0930 \u0917\u0930\u094D\u0928\u0941\u0939\u094B\u0938\u094D\u0964",
                morningHeader = { "${it}, \u0924\u092A\u093E\u0908\u0902\u0915\u094B \u092C\u093F\u0939\u093E\u0928\u0915\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u091B" },
                afternoonHeader = { "${it}, \u0924\u092A\u093E\u0908\u0902\u0915\u094B \u0926\u093F\u0909\u0901\u0938\u094B\u0915\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u091B" },
                nightHeader = { "${it}, \u0924\u092A\u093E\u0908\u0902\u0915\u094B \u0930\u093E\u0924\u093F\u0915\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u091B" },
                welcomeHeader = { "${it}, \u0924\u092A\u093E\u0908\u0902\u0915\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0936\u0947\u092F\u0930 \u0917\u0930\u094D\u0928 \u0924\u092F\u093E\u0930 \u091B" },
                welcomeBody = { "${it}, \u0924\u092A\u093E\u0908\u0902\u0915\u093E \u0932\u093E\u0917\u093F \u0926\u0948\u0928\u093F\u0915 \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u091B\u0928\u094D\u0964 \u090F\u092A \u0916\u094B\u0932\u094D\u0928\u0941\u0939\u094B\u0938\u094D \u0930 \u0936\u0947\u092F\u0930 \u0917\u0930\u094D\u0928\u0941\u0939\u094B\u0938\u094D\u0964" },
            )
            "kok" -> NotificationLexicon(
                user = "\u092F\u0942\u091C\u0930",
                share = "\u0936\u0947\u0905\u0930 \u0915\u0930\u093E\u0924",
                morningTitle = "\u0938\u0941\u092A\u094D\u0930\u092D\u093E\u0924",
                afternoonTitle = "\u0936\u0941\u092D \u0926\u0928\u092A\u093E\u0930",
                nightTitle = "\u0936\u0941\u092D \u0930\u093E\u0924",
                welcomeTitle = "Mana Poster \u0928\u094D\u0939\u092F \u0924\u0941\u092E\u0915\u093E\u0902 \u092F\u0947\u0935\u0915\u093E\u0930",
                morningBody = "\u0924\u0941\u092E\u091A\u094B \u0938\u0915\u093E\u0933\u091A\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E. \u0906\u0924\u093E\u0902 \u0936\u0947\u0905\u0930 \u0915\u0930\u093E\u0924.",
                afternoonBody = "\u0924\u0941\u092E\u091A\u094B \u0926\u0928\u092A\u093E\u0930\u091A\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E. \u0906\u0924\u093E\u0902 \u0936\u0947\u0905\u0930 \u0915\u0930\u093E\u0924.",
                nightBody = "\u0924\u0941\u092E\u091A\u094B \u0930\u093E\u0924\u091A\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E. \u0906\u0924\u093E\u0902 \u0936\u0947\u0905\u0930 \u0915\u0930\u093E\u0924.",
                morningHeader = { "${it}, \u0924\u0941\u092E\u091A\u094B \u0938\u0915\u093E\u0933\u091A\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E" },
                afternoonHeader = { "${it}, \u0924\u0941\u092E\u091A\u094B \u0926\u0928\u092A\u093E\u0930\u091A\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E" },
                nightHeader = { "${it}, \u0924\u0941\u092E\u091A\u094B \u0930\u093E\u0924\u091A\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E" },
                welcomeHeader = { "${it}, \u0924\u0941\u092E\u091A\u094B \u092A\u094B\u0938\u094D\u091F\u0930 \u0936\u0947\u0905\u0930 \u0915\u0930\u092A\u093E\u0915 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E" },
                welcomeBody = { "${it}, \u0924\u0941\u092E\u0915\u093E\u0902 \u0930\u094B\u091C\u091A\u0947 \u092A\u094B\u0938\u094D\u091F\u0930 \u0924\u092F\u093E\u0930 \u0906\u0938\u093E\u0924. \u0905\u0945\u092A \u0909\u0917\u0921\u093E\u0924 \u0906\u0928\u0940 \u0936\u0947\u0905\u0930 \u0915\u0930\u093E\u0924." },
            )
            else -> englishNotificationLexicon()
        }
    }

    private fun englishNotificationLexicon(): NotificationLexicon {
        return NotificationLexicon(
            user = "User",
            share = "Share",
            morningTitle = "Good Morning",
            afternoonTitle = "Good Afternoon",
            nightTitle = "Good Night",
            welcomeTitle = "Welcome to Mana Poster",
            morningBody = "Your morning poster is ready. Share it now.",
            afternoonBody = "Your afternoon poster is ready. Share it now.",
            nightBody = "Your night poster is ready. Share it now.",
            morningHeader = { "$it, your morning poster is ready" },
            afternoonHeader = { "$it, your afternoon poster is ready" },
            nightHeader = { "$it, your night poster is ready" },
            welcomeHeader = { "$it, your poster is ready to share" },
            welcomeBody = { "$it, daily posters are ready for you. Open and share." },
        )
    }

    private data class ReminderCopy(
        val title: String,
        val body: String,
        val header: String,
        val footer: String,
    )

    private data class NotificationLexicon(
        val user: String,
        val share: String,
        val morningTitle: String,
        val afternoonTitle: String,
        val nightTitle: String,
        val welcomeTitle: String,
        val morningBody: String,
        val afternoonBody: String,
        val nightBody: String,
        val morningHeader: (String) -> String,
        val afternoonHeader: (String) -> String,
        val nightHeader: (String) -> String,
        val welcomeHeader: (String) -> String,
        val welcomeBody: (String) -> String,
    )

    private data class DeviceProfile(
        val resolvedName: String,
        val resolvedPhotoUrl: String,
        val languageCode: String,
    )
}
