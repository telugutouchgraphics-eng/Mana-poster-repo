import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mana_poster/app/services/native_startup_state_store.dart';
import 'package:image/image.dart' as img;
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/notification_preferences_service.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:path_provider/path_provider.dart';

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
  static const String _topicAllUsers = 'all_users';

  /// Word joiner — non-empty so Android does not substitute app name for title.
  static const String _collapsedImageTitle = '\u2060';
  static const String _homeNotificationPayload = 'home';
  static const String _nativeNotificationTapRouteKey = 'notificationTapRoute';
  static const String _nativeNotificationTapAtKey = 'notificationTapAt';
  static const String _nativeNotificationTapCategoryKey =
      'notificationTapCategory';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  AppLifecycleListener? _nativeNotificationTapLifecycleListener;
  int? _lastHandledNativeNotificationTapAt;

  bool _initialized = false;
  Future<void>? _initializationFuture;

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
    final existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      return existingInitialization;
    }
    final initialization = _initializeOnce();
    _initializationFuture = initialization;
    try {
      await initialization;
    } catch (_) {
      if (!_initialized) {
        _initializationFuture = null;
      }
      rethrow;
    }
  }

  Future<void> _initializeOnce() async {
    if (_initialized) {
      return;
    }
    if (!_supportsNativeNotifications) {
      _initialized = true;
      return;
    }

    await _initializeLocalNotifications(_localNotifications);

    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
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

    _initialized = true;
    await _attachRealtimeListeners(messaging);
    _attachNativeNotificationTapListener();

    final RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
    await _consumeNativeNotificationTap();

    await _guardedRegisterCurrentToken();
  }

  void _attachNativeNotificationTapListener() {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        _nativeNotificationTapLifecycleListener != null) {
      return;
    }
    _nativeNotificationTapLifecycleListener = AppLifecycleListener(
      onResume: () {
        unawaited(_consumeNativeNotificationTap());
      },
    );
  }

  Future<void> _attachRealtimeListeners(FirebaseMessaging messaging) async {
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _authStateSubscription?.cancel();

    _onMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      await showRemoteMessage(message);
    });
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen(_handleNotificationTap);
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((String token) {
      unawaited(_guardedSyncToken(token));
    });
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      _,
    ) {
      unawaited(_guardedRegisterCurrentToken());
    });
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
    final dataResolved = await _resolveMessageText(message.data);
    final resolved = await _personalizeWelcomeNotificationText(
      categoryKey: categoryKey,
      userName: userName,
      text: _ResolvedNotificationText(
        title: dataResolved.title.isNotEmpty
            ? dataResolved.title
            : _sanitizeNotificationText(message.notification?.title ?? ''),
        body: dataResolved.body.isNotEmpty
            ? dataResolved.body
            : _sanitizeNotificationText(message.notification?.body ?? ''),
      ),
    );
    if (resolved.title.isEmpty &&
        resolved.body.isEmpty &&
        posterImageUrl.isEmpty) {
      return;
    }

    final _NotificationArtifactBundle bundle =
        await _buildNotificationArtifactBundle(
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
    final String route = _normalizeNotificationRoute(
      _readDataValue(message.data, 'route'),
    );
    final String payload = jsonEncode(<String, String>{
      'route': route,
      'categoryKey': categoryKey,
    });
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await plugin.show(
      id,
      resolved.title,
      resolved.body,
      bundle.details,
      payload: payload,
    );
    _scheduleDeleteNotificationTempFiles(bundle.disposablePaths);
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
        final _NotificationTapPayload parsed = _parseNotificationTapPayload(
          payload,
        );
        unawaited(
          _logNotificationOpen(
            route: parsed.route,
            categoryKey: parsed.categoryKey,
            source: 'local_notification',
          ),
        );
        if (_isHomeNotificationRoute(parsed.route)) {
          _openHomeWithRetry();
          return;
        }
        AppNavigator.openNotificationRoute(
          parsed.route,
          arguments: parsed.toArguments(),
        );
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
    if (!await _canSyncTokenForCurrentPermissionState()) {
      return;
    }
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await _syncPublicToken(token);
      return;
    }

    await _syncUserToken(currentUser, token);
    await _syncPublicToken(token, currentUser: currentUser);
  }

  Future<void> _syncUserToken(User currentUser, String token) async {
    final String tokenId = _tokenToDocId(token);
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('deviceTokens')
        .doc(tokenId);

    final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
    final Map<String, dynamic> payload = await _buildTokenPayload(
      token: token,
      uid: currentUser.uid,
      includeCreatedAt: !existing.exists,
      includeWelcomeSent: !existing.exists,
    );

    try {
      developer.log(
        'Syncing authenticated notification token',
        name: 'notification.service',
        error: <String, Object?>{
          'uid': currentUser.uid,
          'token': token,
          'tokenId': tokenId,
          'documentPath': ref.path,
          'payload': payload,
        },
      );
      await ref.set(payload, SetOptions(merge: true));
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'User notification token sync skipped: ${error.code}',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncPublicToken(String token, {User? currentUser}) async {
    final String tokenId = _tokenToDocId(token);
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('publicDeviceTokens')
        .doc(tokenId);
    try {
      final Map<String, dynamic> updatePayload = await _buildTokenPayload(
        token: token,
        uid: currentUser?.uid,
        includeCreatedAt: false,
        includeWelcomeSent: false,
      );
      developer.log(
        'Syncing public notification token',
        name: 'notification.service',
        error: <String, Object?>{
          'uid': currentUser?.uid,
          'token': token,
          'tokenId': tokenId,
          'documentPath': ref.path,
          'payload': updatePayload,
        },
      );
      await ref.set(updatePayload, SetOptions(merge: true));
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Public notification token sync skipped: ${error.code}',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
    }
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

  Future<void> _syncTopicSubscription(FirebaseMessaging messaging) async {
    final NotificationPreferencesSnapshot snapshot =
        await NotificationPreferencesService.load();
    if (snapshot.allNotifications) {
      await messaging.subscribeToTopic(_topicAllUsers);
      return;
    }
    await messaging.unsubscribeFromTopic(_topicAllUsers);
  }

  Future<bool> _canSyncTokenForCurrentPermissionState() async {
    if (!_supportsNativeNotifications) {
      return false;
    }
    try {
      final snapshot = await PermissionService().getSnapshot();
      return snapshot.notifications.isGranted;
    } catch (_) {
      return false;
    }
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

  Future<Map<String, dynamic>> _buildTokenPayload({
    required String token,
    String? uid,
    required bool includeCreatedAt,
    required bool includeWelcomeSent,
  }) async {
    final Map<String, dynamic> preferencePayload =
        await _buildPreferenceSyncPayload();
    final AppFlowSnapshot snapshot = await AppFlowService.loadSnapshot();
    final region = await AppRegionService.loadSelection();
    return <String, dynamic>{
      'token': token,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'other',
      if (uid != null && uid.trim().isNotEmpty) 'uid': uid.trim(),
      'preferredLanguage': snapshot.language.name,
      if (region != null) ...<String, Object?>{
        'selectedRegion': region.id,
        'selectedRegionName': region.name,
        'selectedRegionLanguage': region.primaryLanguage,
        'selectedRegionLanguageCode': region.primaryLanguageCode,
      },
      'updatedAt': FieldValue.serverTimestamp(),
      ...preferencePayload,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      if (includeWelcomeSent) 'welcomeSent': false,
    };
  }

  void _handleNotificationTap(RemoteMessage message) {
    final String route = _normalizeNotificationRoute(
      _readDataValue(message.data, 'route'),
    );
    final String categoryKey = _readDataValue(message.data, 'categoryKey');
    unawaited(
      _logNotificationOpen(
        route: route,
        categoryKey: categoryKey,
        source: 'fcm_opened_app',
      ),
    );
    if (_isHomeNotificationRoute(route)) {
      _openHomeWithRetry();
      return;
    }
    AppNavigator.openNotificationRoute(
      route,
      arguments: <String, dynamic>{
        if (categoryKey.isNotEmpty) 'categoryKey': categoryKey,
        'source': 'notification',
      },
    );
  }

  Future<void> _consumeNativeNotificationTap() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final state = await NativeStartupStateStore.readAll();
    final route = _normalizeNotificationRoute(
      state[_nativeNotificationTapRouteKey]?.toString() ?? '',
    );
    final categoryKey =
        state[_nativeNotificationTapCategoryKey]?.toString().trim() ?? '';
    final tappedAt = _readInt(state[_nativeNotificationTapAtKey]);
    if (route.isEmpty || tappedAt <= 0) {
      return;
    }
    if (_lastHandledNativeNotificationTapAt == tappedAt) {
      return;
    }
    _lastHandledNativeNotificationTapAt = tappedAt;
    await NativeStartupStateStore.writeEntries(<String, Object?>{
      _nativeNotificationTapRouteKey: null,
      _nativeNotificationTapAtKey: null,
      _nativeNotificationTapCategoryKey: null,
    });
    unawaited(
      _logNotificationOpen(
        route: route,
        categoryKey: categoryKey,
        source: 'native_notification',
      ),
    );
    if (_isHomeNotificationRoute(route)) {
      _openHomeWithRetry();
      return;
    }
    AppNavigator.openNotificationRoute(
      route,
      arguments: <String, dynamic>{
        if (categoryKey.isNotEmpty) 'categoryKey': categoryKey,
        'source': 'notification',
      },
    );
  }

  static _NotificationTapPayload _parseNotificationTapPayload(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == _homeNotificationPayload) {
      return const _NotificationTapPayload(route: _homeNotificationPayload);
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return _NotificationTapPayload(
          route: _normalizeNotificationRoute(
            decoded['route']?.toString() ?? '',
          ),
          categoryKey: decoded['categoryKey']?.toString().trim() ?? '',
        );
      }
    } catch (_) {
      // Fall through to treating the payload as a route.
    }
    return _NotificationTapPayload(route: _normalizeNotificationRoute(trimmed));
  }

  static Future<void> _logNotificationOpen({
    required String route,
    required String source,
    String categoryKey = '',
  }) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'notification_open',
        parameters: <String, Object>{
          'route': route.isEmpty ? _homeNotificationPayload : route,
          'source': source,
          if (categoryKey.trim().isNotEmpty) 'category_key': categoryKey.trim(),
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Notification open analytics skipped: $error',
        name: 'notification.service',
        error: error,
        stackTrace: stackTrace,
      );
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

  static String _normalizeNotificationRoute(String route) {
    final normalized = route.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _homeNotificationPayload;
    }
    if (normalized == _homeNotificationPayload || normalized == '/home') {
      return AppRoutes.home;
    }
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }

  static bool _isHomeNotificationRoute(String route) {
    return route.isEmpty ||
        route == _homeNotificationPayload ||
        route == AppRoutes.home;
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  static Future<_ResolvedNotificationText> _resolveMessageText(
    Map<String, dynamic> data,
  ) async {
    final snapshot = await AppFlowService.loadSnapshot();
    final titleKey = _readDataValue(data, 'title_key');
    final bodyKey = _readDataValue(data, 'body_key');
    final directTitle = _sanitizeNotificationText(
      _readDataValue(data, 'title'),
    );
    final directBody = _sanitizeNotificationText(_readDataValue(data, 'body'));
    if (directTitle.isNotEmpty || directBody.isNotEmpty) {
      return _ResolvedNotificationText(title: directTitle, body: directBody);
    }
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

  static Future<_ResolvedNotificationText> _personalizeWelcomeNotificationText({
    required String categoryKey,
    required String userName,
    required _ResolvedNotificationText text,
  }) async {
    if (categoryKey.trim().toLowerCase() != 'welcome') {
      return text;
    }
    final name = userName.trim().isEmpty ? 'User' : userName.trim();
    final language = (await AppFlowService.loadSnapshot()).language;
    final suffix = switch (language.supportedUiLanguage) {
      SupportedUiLanguage.telugu => '$name గారు, ',
      SupportedUiLanguage.hindi => '$name जी, ',
      _ => '$name, ',
    };
    if (text.body.trim().startsWith(name)) {
      return text;
    }
    return _ResolvedNotificationText(
      title: text.title,
      body: '$suffix${text.body}',
    );
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
    return value.contains('\u00E0\u00B0') ||
        value.contains('\u00E0\u00A4') ||
        value.contains('\u00E0\u00AE') ||
        value.contains('\u00E0\u00B2') ||
        value.contains('\u00E0\u00B4');
  }

  static Future<_NotificationArtifactBundle> _buildNotificationArtifactBundle({
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
    final Set<String> disposablePaths = <String>{};
    final String? downloadedPosterPath = await _downloadImageForNotification(
      posterImageUrl,
    );
    if (downloadedPosterPath != null) {
      disposablePaths.add(downloadedPosterPath);
    }
    final String? collapsedHeaderPath = downloadedPosterPath != null
        ? await _extractCollapsedHeaderStrip(downloadedPosterPath)
        : null;
    if (collapsedHeaderPath != null) {
      disposablePaths.add(collapsedHeaderPath);
    }
    final String? posterPath = await _prepareExpandedPosterImage(
      downloadedPosterPath,
    );
    if (posterPath != null && posterPath.trim().isNotEmpty) {
      disposablePaths.add(posterPath.trim());
    }
    final String? userPhotoPath = await _downloadImageForNotification(
      userPhotoUrl,
    );
    if (userPhotoPath != null) {
      disposablePaths.add(userPhotoPath);
    }

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
          contentTitle: title.isNotEmpty ? title : _collapsedImageTitle,
          summaryText: body.isNotEmpty ? body : _collapsedImageTitle,
          htmlFormatContentTitle: false,
          htmlFormatSummaryText: false,
          largeIcon: collapsedHeaderPath != null
              ? FilePathAndroidBitmap(collapsedHeaderPath)
              : null,
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

    return _NotificationArtifactBundle(
      details: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      disposablePaths: disposablePaths.toList(growable: false),
    );
  }

  static void _scheduleDeleteNotificationTempFiles(List<String> paths) {
    final List<String> unique = paths
        .map((String p) => p.trim())
        .where((String p) => p.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (unique.isEmpty) {
      return;
    }
    Future<void>.delayed(const Duration(minutes: 2), () async {
      for (final String path in unique) {
        try {
          final File file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    });
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

  /// Top band of the rendered card (matches Cloud Function header height 232/900).
  static Future<String?> _extractCollapsedHeaderStrip(String imagePath) async {
    final String trimmed = imagePath.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final File sourceFile = File(trimmed);
      if (!await sourceFile.exists()) {
        return null;
      }
      final Uint8List bytes = await sourceFile.readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return null;
      }
      const double stripRatio = 232 / 900;
      final int stripHeight = (decoded.height * stripRatio).round().clamp(
        1,
        decoded.height,
      );
      final img.Image cropped = img.copyCrop(
        decoded,
        x: 0,
        y: 0,
        width: decoded.width,
        height: stripHeight,
      );
      final Directory directory = await getTemporaryDirectory();
      final File out = File(
        '${directory.path}/notif_strip_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await out.writeAsBytes(img.encodePng(cropped), flush: true);
      return out.path;
    } catch (error, stackTrace) {
      developer.log(
        'Notification collapsed header crop failed: $error',
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

        final double padding = (canvasHeight * 0.035)
            .clamp(18.0, 42.0)
            .toDouble();
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

class _NotificationArtifactBundle {
  const _NotificationArtifactBundle({
    required this.details,
    required this.disposablePaths,
  });

  final NotificationDetails details;
  final List<String> disposablePaths;
}

class _NotificationTapPayload {
  const _NotificationTapPayload({required this.route, this.categoryKey = ''});

  final String route;
  final String categoryKey;

  Map<String, dynamic> toArguments() {
    return <String, dynamic>{
      if (categoryKey.trim().isNotEmpty) 'categoryKey': categoryKey.trim(),
      'source': 'notification',
    };
  }
}

class _ResolvedNotificationText {
  const _ResolvedNotificationText({required this.title, required this.body});

  final String title;
  final String body;
}
