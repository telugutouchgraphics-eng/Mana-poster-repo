import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/features/prehome/services/app_region_service.dart';

class AppScreenUsageService extends NavigatorObserver
    with WidgetsBindingObserver {
  AppScreenUsageService._();

  static final AppScreenUsageService instance = AppScreenUsageService._();

  static const String _endpoint =
      'https://asia-south1-mana-poster-ap.cloudfunctions.net/recordAppScreenUsage';
  static const String _installationKey = 'app_screen_usage_install_id_v1';

  String? _currentScreenName;
  DateTime? _enteredAt;
  bool _lifecycleAttached = false;
  bool _appPaused = false;
  PackageInfo? _packageInfo;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _ensureLifecycleObserver();
    _finishCurrent();
    _start(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _finishCurrent(routeName: _nameFor(route));
    _start(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _finishCurrent(routeName: _nameFor(oldRoute));
    _start(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_nameFor(route) == _currentScreenName) {
      _finishCurrent();
      _start(previousRoute);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (!_appPaused) {
        _appPaused = true;
        _finishCurrent();
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _appPaused = false;
      if (_currentScreenName != null && _enteredAt == null) {
        _enteredAt = DateTime.now();
      }
    }
  }

  void _ensureLifecycleObserver() {
    if (_lifecycleAttached) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _lifecycleAttached = true;
  }

  void _start(Route<dynamic>? route) {
    final screenName = _nameFor(route);
    if (screenName == null) {
      _currentScreenName = null;
      _enteredAt = null;
      return;
    }
    _currentScreenName = screenName;
    _enteredAt = DateTime.now();
  }

  void _finishCurrent({String? routeName}) {
    final screenName = routeName ?? _currentScreenName;
    final enteredAt = _enteredAt;
    if (screenName == null || enteredAt == null) {
      return;
    }
    final exitedAt = DateTime.now();
    final durationMs = exitedAt.difference(enteredAt).inMilliseconds;
    if (routeName == null || routeName == _currentScreenName) {
      _enteredAt = null;
    }
    if (durationMs < 800) {
      return;
    }
    unawaited(_send(screenName, enteredAt, exitedAt, durationMs));
  }

  String? _nameFor(Route<dynamic>? route) {
    if (route == null) {
      return null;
    }
    final name = route.settings.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return route.runtimeType.toString();
  }

  Future<void> _send(
    String screenName,
    DateTime enteredAt,
    DateTime exitedAt,
    int durationMs,
  ) async {
    await _postUsagePayload(<String, Object?>{
      'screenName': screenName,
      'durationMs': durationMs,
      'enteredAtMillis': enteredAt.millisecondsSinceEpoch,
      'exitedAtMillis': exitedAt.millisecondsSinceEpoch,
    });
  }

  Future<void> recordLoginEvent({
    required String eventType,
    required String authMethod,
    required String authMode,
    String reasonCode = '',
  }) async {
    await _postUsagePayload(<String, Object?>{
      'screenName': '/login',
      'eventType': eventType,
      'authMethod': authMethod,
      'authMode': authMode,
      'reasonCode': reasonCode,
    });
  }

  Future<void> _postUsagePayload(Map<String, Object?> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final installId = await _installationId(prefs);
      final region = await AppRegionService.loadSelection(prefs: prefs);
      final packageInfo = await _loadPackageInfo();
      final token = await _idTokenOrNull();
      final language =
          prefs.getString(AppRegionService.selectedRegionLanguageCodeKey) ?? '';
      final headers = <String, String>{
        'content-type': 'application/json',
        if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
      };
      final body = <String, Object?>{
        ...payload,
        'installId': installId,
        'regionId': region?.id ?? '',
        'regionName': region?.name ?? '',
        'language': language,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };
      await http
          .post(Uri.parse(_endpoint), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<String?> _idTokenOrNull() async {
    try {
      if (Firebase.apps.isEmpty) {
        return null;
      }
      return FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<PackageInfo> _loadPackageInfo() async {
    final cached = _packageInfo;
    if (cached != null) {
      return cached;
    }
    final loaded = await PackageInfo.fromPlatform();
    _packageInfo = loaded;
    return loaded;
  }

  Future<String> _installationId(SharedPreferences prefs) async {
    final existing = prefs.getString(_installationKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }
    final generated =
        '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';
    await prefs.setString(_installationKey, generated);
    return generated;
  }
}
