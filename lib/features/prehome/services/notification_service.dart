import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/notification_preferences_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    return;
  }
  DartPluginRegistrant.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();
  await NotificationService.showRemoteMessage(message);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mana_poster_general',
    'Mana Poster Ai Notifications',
    description: 'General reminders and event updates',
    importance: Importance.high,
  );
  static const String _publicTokenSyncedPrefix = 'public_push_token_synced_';
  static const String _topicAllUsers = 'all_users';
  static const String _suppressedExpandedText = '\u2060';

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
    await _requestNotificationPermission(messaging);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    try {
      await _syncTopicSubscription(messaging);
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

    final posterImageUrl = _readDataValue(message.data, 'posterImage');
    final posterBaseImageUrl = _readDataValue(message.data, 'posterBaseImage');
    final headerText = _readDataValue(message.data, 'headerText');
    final footerText = _readDataValue(message.data, 'footerText');
    final categoryKey = _readDataValue(message.data, 'categoryKey');
    final userName = _readDataValue(message.data, 'userName');
    final resolved = await _resolveMessageText(message.data);
    if (resolved.title.isEmpty &&
        resolved.body.isEmpty &&
        posterImageUrl.isEmpty) {
      return;
    }

    final NotificationDetails details = await _buildNotificationDetails(
      posterImageUrl: posterImageUrl,
      posterBaseImageUrl: posterBaseImageUrl,
      userPhotoUrl: _readDataValue(message.data, 'userPhoto'),
      userName: userName,
      headerText: headerText,
      footerText: footerText,
      categoryKey: categoryKey,
      title: resolved.title,
      body: resolved.body,
    );
    final payload =
        (_readDataValue(message.data, 'route')).trim().toLowerCase() == 'home'
        ? 'home'
        : '';
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final bool suppressExpandedText = posterImageUrl.trim().isNotEmpty;
    await plugin.show(
      id,
      suppressExpandedText ? _suppressedExpandedText : resolved.title,
      suppressExpandedText ? _suppressedExpandedText : resolved.body,
      details,
      payload: payload,
    );
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
    final Map<String, dynamic> preferencePayload =
        await _buildPreferenceSyncPayload();
    final Map<String, dynamic> payload = <String, dynamic>{
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
      ...preferencePayload,
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

    final Map<String, dynamic> preferencePayload =
        await _buildPreferenceSyncPayload();
    final Map<String, dynamic> payload = <String, dynamic>{
      'token': token,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'other',
      'uid': currentUser.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      ...preferencePayload,
    };

    final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
    if (!existing.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['welcomeSent'] = false;
    }

    await ref.set(payload, SetOptions(merge: true));
    await FirebaseFirestore.instance
        .collection('publicDeviceTokens')
        .doc(tokenId)
        .delete()
        .catchError((_) {});
  }

  Future<void> syncCurrentPreferences() async {
    if (!_supportsNativeNotifications) {
      return;
    }
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    try {
      await _syncTopicSubscription(messaging);
    } catch (error, stackTrace) {
      developer.log(
        'Notification topic sync skipped: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _guardedRegisterCurrentToken();
  }

  String _tokenToDocId(String token) {
    return token.replaceAll('/', '_');
  }

  Future<void> _requestNotificationPermission(
    FirebaseMessaging messaging,
  ) async {
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Notification permission request skipped: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncTopicSubscription(FirebaseMessaging messaging) async {
    final NotificationPreferencesSnapshot snapshot =
        await NotificationPreferencesService.load();
    if (snapshot.allNotifications) {
      await messaging.subscribeToTopic(_topicAllUsers);
      return;
    }
    await messaging.unsubscribeFromTopic(_topicAllUsers);
  }

  Future<Map<String, dynamic>> _buildPreferenceSyncPayload() async {
    final NotificationPreferencesSnapshot snapshot =
        await NotificationPreferencesService.load();
    return <String, dynamic>{
      'allNotifications': snapshot.allNotifications,
      'newPosters': snapshot.newPosters,
      'offersUpdates': snapshot.offersUpdates,
      'subscriptionReminders': snapshot.subscriptionReminders,
    };
  }

  void _handleNotificationTap(RemoteMessage message) {
    final String route = _readDataValue(
      message.data,
      'route',
    ).trim().toLowerCase();
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
    final snapshot = await AppFlowService.loadSnapshot();
    final titleKey = _readDataValue(data, 'title_key');
    final bodyKey = _readDataValue(data, 'body_key');
    if (titleKey.isNotEmpty || bodyKey.isNotEmpty) {
      final title = _localizedNotificationText(
        key: titleKey,
        language: snapshot.language,
      );
      final body = _localizedNotificationText(
        key: bodyKey,
        language: snapshot.language,
      );
      return _ResolvedNotificationText(title: title, body: body);
    }

    final directTitle = _sanitizeNotificationText(
      _readDataValue(data, 'title'),
    );
    final directBody = _sanitizeNotificationText(_readDataValue(data, 'body'));
    return _ResolvedNotificationText(title: directTitle, body: directBody);
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
        AppLanguage.english: 'Welcome to Mana Poster Ai',
        AppLanguage.tamil: 'மனா போஸ்டருக்கு வரவேற்கிறோம்',
        AppLanguage.kannada: 'ಮನಾ ಪೋಸ್ಟರ್‌ಗೆ ಸ್ವಾಗತ',
        AppLanguage.malayalam: 'മന പോസ്റ്ററിലേക്ക് സ്വാഗതം',
      },
      'welcome_body': {
        AppLanguage.telugu:
            'మీ కోసం పోస్టర్లు సిద్ధంగా ఉన్నాయి. ఇప్పుడే చూడండి.',
        AppLanguage.hindi: 'आपके लिए पोस्टर तैयार हैं। अभी देखें।',
        AppLanguage.english: 'Your posters are ready. Open now.',
        AppLanguage.tamil: 'உங்களுக்கான போஸ்டர்கள் தயார். இப்போது திறக்கவும்.',
        AppLanguage.kannada: 'ನಿಮಗಾಗಿ ಪೋಸ್ಟರ್‌ಗಳು ಸಿದ್ಧವಾಗಿವೆ. ಈಗ ತೆರೆಯಿರಿ.',
        AppLanguage.malayalam:
            'നിങ്ങൾക്കായി പോസ്റ്ററുകൾ തയ്യാറാണ്. ഇപ്പോൾ തുറക്കൂ.',
      },
      'morning_title': {
        AppLanguage.telugu: 'శుభోదయం',
        AppLanguage.hindi: 'शुभ प्रभात',
        AppLanguage.english: 'Good Morning',
        AppLanguage.tamil: 'காலை வணக்கம்',
        AppLanguage.kannada: 'ಶುಭೋದಯ',
        AppLanguage.malayalam: 'ശുഭ പ്രഭാതം',
      },
      'morning_body': {
        AppLanguage.telugu:
            'మీ ఉదయ పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.',
        AppLanguage.english: 'Your morning poster is ready. Share it now.',
      },
      'afternoon_title': {
        AppLanguage.telugu: 'శుభ మధ్యాహ్నం',
        AppLanguage.hindi: 'शुभ दोपहर',
        AppLanguage.english: 'Good Afternoon',
        AppLanguage.tamil: 'மதிய வணக்கம்',
        AppLanguage.kannada: 'ಶುಭ ಮಧ್ಯಾಹ್ನ',
        AppLanguage.malayalam: 'ശുഭ ഉച്ചകഴിഞ്ഞ്',
      },
      'afternoon_body': {
        AppLanguage.telugu:
            'మీ మధ్యాహ్న పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.',
        AppLanguage.english: 'Your afternoon poster is ready. Share it now.',
      },
      'night_title': {
        AppLanguage.telugu: 'శుభ రాత్రి',
        AppLanguage.hindi: 'शुभ रात्रि',
        AppLanguage.english: 'Good Night',
        AppLanguage.tamil: 'இரவு வணக்கம்',
        AppLanguage.kannada: 'ಶುಭ ರಾತ್ರಿ',
        AppLanguage.malayalam: 'ശുഭ രാത്രി',
      },
      'night_body': {
        AppLanguage.telugu:
            'మీ రాత్రి పోస్టర్ సిద్ధంగా ఉంది. ఇప్పుడే షేర్ చేయండి.',
        AppLanguage.english: 'Your night poster is ready. Share it now.',
      },
    };

    final bucket = fallback[normalized];
    if (bucket == null) {
      return '';
    }
    final value = bucket[language] ?? bucket[AppLanguage.english] ?? '';
    return _sanitizeNotificationText(value);
  }

  static String _readDataValue(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString().trim();
  }

  static String _sanitizeNotificationText(String value) {
    if (!_looksCorruptedText(value)) {
      return value;
    }
    try {
      final decoded = utf8.decode(latin1.encode(value), allowMalformed: true);
      return decoded.trim().isEmpty ? value : decoded;
    } catch (_) {
      return value;
    }
  }

  static bool _looksCorruptedText(String value) {
    return value.contains('à°') ||
        value.contains('à¤') ||
        value.contains('à®') ||
        value.contains('à²') ||
        value.contains('à´');
  }

  static Future<NotificationDetails> _buildNotificationDetails({
    required String posterImageUrl,
    required String posterBaseImageUrl,
    required String userPhotoUrl,
    required String userName,
    required String headerText,
    required String footerText,
    required String categoryKey,
    required String title,
    required String body,
  }) async {
    final downloadedPosterPath = await _downloadImageForNotification(
      posterImageUrl,
    );
    final posterPath = await _prepareExpandedPosterImage(downloadedPosterPath);
    final userPhotoPath = await _downloadImageForNotification(userPhotoUrl);

    final AndroidNotificationDetails androidDetails;
    if (posterPath != null) {
      androidDetails = AndroidNotificationDetails(
        'mana_poster_general',
        'Mana Poster Ai Notifications',
        channelDescription: 'General reminders and event updates',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigPictureStyleInformation(
          FilePathAndroidBitmap(posterPath),
          contentTitle: '',
          summaryText: '',
          htmlFormatContentTitle: false,
          htmlFormatSummaryText: false,
          hideExpandedLargeIcon: true,
        ),
        subText: '',
        category: AndroidNotificationCategory.social,
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        'mana_poster_general',
        'Mana Poster Ai Notifications',
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

  static Future<String?> _prepareExpandedPosterImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }
    try {
      final File sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        return imagePath;
      }
      final Uint8List bytes = await sourceFile.readAsBytes();
      if (bytes.isEmpty) {
        return imagePath;
      }
      final ui.Codec codec = await instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image sourceImage = frame.image;
      try {
        final double sourceWidth = sourceImage.width.toDouble();
        final double sourceHeight = sourceImage.height.toDouble();
        if (sourceWidth <= 0 || sourceHeight <= 0) {
          return imagePath;
        }

        const double targetAspectRatio = 16 / 9;
        final double sourceAspectRatio = sourceWidth / sourceHeight;
        final double canvasWidth;
        final double canvasHeight;
        if (sourceAspectRatio > targetAspectRatio) {
          canvasWidth = sourceWidth;
          canvasHeight = sourceWidth / targetAspectRatio;
        } else {
          canvasHeight = sourceHeight;
          canvasWidth = sourceHeight * targetAspectRatio;
        }

        final double padding =
            (canvasHeight * 0.035).clamp(18.0, 42.0).toDouble();
        final Rect outputBounds = Rect.fromLTWH(
          padding,
          padding,
          canvasWidth - (padding * 2),
          canvasHeight - (padding * 2),
        );
        final FittedSizes fitted = applyBoxFit(
          BoxFit.contain,
          Size(sourceWidth, sourceHeight),
          outputBounds.size,
        );
        final Rect destinationRect = Alignment.center.inscribe(
          fitted.destination,
          outputBounds,
        );

        final ui.PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
          Paint()..color = const Color(0xFFF7F7F7),
        );
        canvas.drawImageRect(
          sourceImage,
          Rect.fromLTWH(0, 0, sourceWidth, sourceHeight),
          destinationRect,
          Paint()..isAntiAlias = true,
        );

        final ui.Picture picture = recorder.endRecording();
        final ui.Image renderedImage = await picture.toImage(
          canvasWidth.round(),
          canvasHeight.round(),
        );
        try {
          final ByteData? byteData = await renderedImage.toByteData(
            format: ImageByteFormat.png,
          );
          if (byteData == null) {
            return imagePath;
          }
          final Directory directory = await getTemporaryDirectory();
          final File file = File(
            '${directory.path}/notif_expanded_${DateTime.now().microsecondsSinceEpoch}.png',
          );
          await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
          return file.path;
        } finally {
          renderedImage.dispose();
        }
      } finally {
        sourceImage.dispose();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Notification expanded image preparation failed: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
      return imagePath;
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
