import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();
  await NotificationService.showRemoteMessage(message);
}

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

  static FlutterLocalNotificationsPlugin get _backgroundNotifications =>
      FlutterLocalNotificationsPlugin();

  bool get _supportsNativeNotifications {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (!_supportsNativeNotifications) {
      _initialized = true;
      return;
    }

    await _initializeLocalNotifications(_localNotifications);

    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
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

    FirebaseMessaging.onMessage.listen((message) async {
      await showRemoteMessage(message);
    });
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

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    final plugin = _backgroundNotifications;
    await _initializeLocalNotifications(plugin);

    final resolved = await _resolveMessageText(message.data);
    if (resolved.title.isEmpty && resolved.body.isEmpty) {
      return;
    }

    final NotificationDetails details = await _buildNotificationDetails(
      posterImageUrl: _readDataValue(message.data, 'posterImage'),
      userPhotoUrl: _readDataValue(message.data, 'userPhoto'),
      title: resolved.title,
      body: resolved.body,
    );
    final payload =
        (_readDataValue(message.data, 'route')).trim().toLowerCase() == 'home'
            ? 'home'
            : '';
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await plugin.show(id, resolved.title, resolved.body, details, payload: payload);
  }

  static Future<void> _initializeLocalNotifications(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String payload = response.payload ?? '';
        if (payload.trim().toLowerCase() == 'home') {
          _openHomeWithRetry();
        }
      },
    );

    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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

  void _handleNotificationTap(RemoteMessage message) {
    final String route = _readDataValue(message.data, 'route').trim().toLowerCase();
    if (route == 'home') {
      _openHomeWithRetry();
    }
  }

  static void _openHomeWithRetry([int attempt = 0]) {
    AppNavigator.openHome();
    if (AppNavigator.navigatorKey.currentState != null || attempt >= 6) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _openHomeWithRetry(attempt + 1);
    });
  }

  static Future<_ResolvedNotificationText> _resolveMessageText(
    Map<String, dynamic> data,
  ) async {
    final directTitle = _readDataValue(data, 'title');
    final directBody = _readDataValue(data, 'body');
    if (directTitle.isNotEmpty || directBody.isNotEmpty) {
      return _ResolvedNotificationText(title: directTitle, body: directBody);
    }

    final snapshot = await AppFlowService.loadSnapshot();
    final title = _localizedNotificationText(
      key: _readDataValue(data, 'title_key'),
      language: snapshot.language,
    );
    final body = _localizedNotificationText(
      key: _readDataValue(data, 'body_key'),
      language: snapshot.language,
    );
    return _ResolvedNotificationText(title: title, body: body);
  }

  static String _localizedNotificationText({
    required String key,
    required AppLanguage language,
  }) {
    final normalized = key.trim().toLowerCase();
    const fallback = <String, Map<AppLanguage, String>>{
      'welcome_title': {
        AppLanguage.telugu: 'మన పోస్టర్‌కు స్వాగతం',
        AppLanguage.hindi: 'मना पोस्टर में आपका स्वागत है',
        AppLanguage.english: 'Welcome to Mana Poster',
        AppLanguage.tamil: 'மனா போஸ்டருக்கு வரவேற்கிறோம்',
        AppLanguage.kannada: 'ಮನಾ ಪೋಸ್ಟರ್‌ಗೆ ಸ್ವಾಗತ',
        AppLanguage.malayalam: 'മന പോസ്റ്ററിലേക്ക് സ്വാഗതം',
      },
      'welcome_body': {
        AppLanguage.telugu: 'మీ కోసం పోస్టర్లు సిద్ధంగా ఉన్నాయి. ఇప్పుడే చూడండి.',
        AppLanguage.hindi: 'आपके लिए पोस्टर तैयार हैं। अभी देखें।',
        AppLanguage.english: 'Your posters are ready. Open now.',
        AppLanguage.tamil: 'உங்களுக்கான போஸ்டர்கள் தயார். இப்போது திறக்கவும்.',
        AppLanguage.kannada: 'ನಿಮಗಾಗಿ ಪೋಸ್ಟರ್‌ಗಳು ಸಿದ್ಧವಾಗಿವೆ. ಈಗ ತೆರೆಯಿರಿ.',
        AppLanguage.malayalam: 'നിങ്ങൾക്കായി പോസ്റ്ററുകൾ തയ്യാറാണ്. ഇപ്പോൾ തുറക്കൂ.',
      },
      'morning_title': {
        AppLanguage.telugu: 'శుభోదయం',
        AppLanguage.hindi: 'शुभ प्रभात',
        AppLanguage.english: 'Good Morning',
        AppLanguage.tamil: 'காலை வணக்கம்',
        AppLanguage.kannada: 'ಶುಭೋದಯ',
        AppLanguage.malayalam: 'ശുഭ പ്രഭാതം',
      },
      'afternoon_title': {
        AppLanguage.telugu: 'శుభ మధ్యాహ్నం',
        AppLanguage.hindi: 'शुभ दोपहर',
        AppLanguage.english: 'Good Afternoon',
        AppLanguage.tamil: 'மதிய வணக்கம்',
        AppLanguage.kannada: 'ಶುಭ ಮಧ್ಯಾಹ್ನ',
        AppLanguage.malayalam: 'ശുഭ ഉച്ചകഴിഞ്ഞ്',
      },
      'night_title': {
        AppLanguage.telugu: 'శుభ రాత్రి',
        AppLanguage.hindi: 'शुभ रात्रि',
        AppLanguage.english: 'Good Night',
        AppLanguage.tamil: 'இரவு வணக்கம்',
        AppLanguage.kannada: 'ಶುಭ ರಾತ್ರಿ',
        AppLanguage.malayalam: 'ശുഭ രാത്രി',
      },
    };

    final bucket = fallback[normalized];
    if (bucket == null) {
      return '';
    }
    return bucket[language] ?? bucket[AppLanguage.english] ?? '';
  }

  static String _readDataValue(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString().trim();
  }

  static Future<NotificationDetails> _buildNotificationDetails({
    required String posterImageUrl,
    required String userPhotoUrl,
    required String title,
    required String body,
  }) async {
    final posterPath = await _downloadImageForNotification(posterImageUrl);
    final userPhotoPath = await _downloadImageForNotification(userPhotoUrl);

    final AndroidNotificationDetails androidDetails;
    if (posterPath != null) {
      androidDetails = AndroidNotificationDetails(
        'mana_poster_general',
        'Mana Poster Notifications',
        channelDescription: 'General reminders and event updates',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigPictureStyleInformation(
          FilePathAndroidBitmap(posterPath),
          largeIcon: userPhotoPath != null
              ? FilePathAndroidBitmap(userPhotoPath)
              : null,
          contentTitle: title,
          summaryText: body,
          htmlFormatContentTitle: false,
          htmlFormatSummaryText: false,
        ),
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        'mana_poster_general',
        'Mana Poster Notifications',
        channelDescription: 'General reminders and event updates',
        importance: Importance.high,
        priority: Priority.high,
        largeIcon: userPhotoPath != null
            ? FilePathAndroidBitmap(userPhotoPath)
            : null,
      );
    }

    return NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<String?> _downloadImageForNotification(String imageUrl) async {
    final normalizedUrl = imageUrl.trim();
    if (normalizedUrl.isEmpty) {
      return null;
    }
    try {
      final Uri uri = Uri.parse(normalizedUrl);
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
      final List<int> bytes = await consolidateHttpClientResponseBytes(response);
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

  static String _guessNotificationImageExtension(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'jpg';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    return 'png';
  }
}

class _ResolvedNotificationText {
  const _ResolvedNotificationText({required this.title, required this.body});

  final String title;
  final String body;
}
