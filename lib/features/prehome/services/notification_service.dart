import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mana_poster_general',
    'Mana Poster Notifications',
    description: 'General reminders and event updates',
    importance: Importance.high,
  );
  static const String _publicTokenSyncedPrefix = 'public_push_token_synced_';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supportsNativeNotifications {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (!_supportsNativeNotifications) {
      _initialized = true;
      return;
    }

    await _initializeLocalNotifications();

    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      await messaging.subscribeToTopic('all_users');
    } catch (error, stackTrace) {
      developer.log(
        'Notification topic subscription skipped: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    messaging.onTokenRefresh.listen((String token) {
      unawaited(_guardedSyncToken(token));
    });

    FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(_guardedRegisterCurrentToken());
    });

    await _guardedRegisterCurrentToken();
    _initialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String payload = response.payload ?? '';
        if (payload.trim().toLowerCase() == 'home') {
          _openHomeWithRetry();
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _registerCurrentToken() async {
    if (!_supportsNativeNotifications) {
      return;
    }
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final String? token = await messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }
    await _syncToken(token);
  }

  Future<void> _guardedRegisterCurrentToken() async {
    try {
      await _registerCurrentToken();
    } catch (error, stackTrace) {
      developer.log(
        'Notification token registration skipped: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _guardedSyncToken(String token) async {
    try {
      await _syncToken(token);
    } catch (error, stackTrace) {
      developer.log(
        'Notification token sync skipped: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncToken(String token) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await _syncPublicToken(token);
      return;
    }

    await _syncUserToken(currentUser, token);
  }

  Future<void> _syncPublicToken(String token) async {
    final String tokenId = _tokenToDocId(token);
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('publicDeviceTokens')
        .doc(tokenId);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String syncedKey = '$_publicTokenSyncedPrefix$tokenId';
    final String platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'other';
    final bool alreadySynced = prefs.getBool(syncedKey) ?? false;
    final Map<String, dynamic> payload = <String, dynamic>{
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!alreadySynced) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['welcomeSent'] = false;
    }

    await ref.set(payload, SetOptions(merge: true));
    await prefs.setBool(syncedKey, true);
  }

  Future<void> _syncUserToken(User currentUser, String token) async {
    final String tokenId = _tokenToDocId(token);
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('deviceTokens')
        .doc(tokenId);

    final Map<String, dynamic> payload = <String, dynamic>{
      'token': token,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'other',
      'uid': currentUser.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
    if (!existing.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['welcomeSent'] = false;
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  String _tokenToDocId(String token) {
    return token.replaceAll('/', '_');
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final String? title = message.notification?.title;
    final String? body = message.notification?.body;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final String? imageUrl = _resolveNotificationImageUrl(message);
    final NotificationDetails details = await _buildNotificationDetails(
      imageUrl: imageUrl,
      title: title,
      body: body,
    );
    final String payload =
        (message.data['route'] ?? '').toString().trim().toLowerCase() == 'home'
            ? 'home'
            : '';
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  String? _resolveNotificationImageUrl(RemoteMessage message) {
    final String dataImage =
        (message.data['imageUrl'] ?? '').toString().trim();
    if (dataImage.isNotEmpty) {
      return dataImage;
    }
    final String notificationAndroidImage =
        (message.notification?.android?.imageUrl ?? '').trim();
    if (notificationAndroidImage.isNotEmpty) {
      return notificationAndroidImage;
    }
    final String notificationAppleImage =
        (message.notification?.apple?.imageUrl ?? '').trim();
    if (notificationAppleImage.isNotEmpty) {
      return notificationAppleImage;
    }
    return null;
  }

  Future<NotificationDetails> _buildNotificationDetails({
    required String? imageUrl,
    required String? title,
    required String? body,
  }) async {
    final AndroidNotificationDetails androidDetails;
    final String normalizedImageUrl = (imageUrl ?? '').trim();
    if (normalizedImageUrl.isNotEmpty) {
      final String? filePath = await _downloadImageForNotification(
        normalizedImageUrl,
      );
      if (filePath != null) {
        androidDetails = AndroidNotificationDetails(
          'mana_poster_general',
          'Mana Poster Notifications',
          channelDescription: 'General reminders and event updates',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(filePath),
            largeIcon: FilePathAndroidBitmap(filePath),
            contentTitle: title,
            summaryText: body,
            htmlFormatContentTitle: false,
            htmlFormatSummaryText: false,
          ),
        );
      } else {
        androidDetails = const AndroidNotificationDetails(
          'mana_poster_general',
          'Mana Poster Notifications',
          channelDescription: 'General reminders and event updates',
          importance: Importance.high,
          priority: Priority.high,
        );
      }
    } else {
      androidDetails = const AndroidNotificationDetails(
        'mana_poster_general',
        'Mana Poster Notifications',
        channelDescription: 'General reminders and event updates',
        importance: Importance.high,
        priority: Priority.high,
      );
    }

    return NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<String?> _downloadImageForNotification(String imageUrl) async {
    try {
      final Uri uri = Uri.parse(imageUrl);
      if (!uri.hasScheme) {
        return null;
      }
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        client.close(force: true);
        return null;
      }
      final List<int> bytes = await consolidateHttpClientResponseBytes(
        response,
      );
      client.close(force: true);
      if (bytes.isEmpty) {
        return null;
      }
      final Directory directory = await getTemporaryDirectory();
      final String extension = _guessNotificationImageExtension(uri.path);
      final File file = File(
        '${directory.path}/notif_${DateTime.now().microsecondsSinceEpoch}.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (error, stackTrace) {
      developer.log(
        'Notification image download failed: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _guessNotificationImageExtension(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'jpg';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    return 'png';
  }

  void _handleNotificationTap(RemoteMessage message) {
    final String route =
        (message.data['route'] ?? '').toString().trim().toLowerCase();
    if (route == 'home') {
      _openHomeWithRetry();
    }
  }

  void _openHomeWithRetry([int attempt = 0]) {
    AppNavigator.openHome();
    if (AppNavigator.navigatorKey.currentState != null || attempt >= 6) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _openHomeWithRetry(attempt + 1);
    });
  }
}
