import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/routes/app_routes.dart';

class DeviceSessionService {
  DeviceSessionService._();

  static final DeviceSessionService instance = DeviceSessionService._();

  static const String _deviceIdKey = 'device_session_installation_id_v1';
  static const String _sessionCollection = 'activeSession';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _remoteSessionSubscription;
  bool _started = false;
  bool _forcingLogout = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    _authSubscription = _auth.authStateChanges().listen((user) {
      unawaited(_handleAuthStateChanged(user));
    });

    await _handleAuthStateChanged(_auth.currentUser);
  }

  Future<void> registerCurrentDeviceSession() async {
    if (_auth.currentUser == null) {
      return;
    }
    await _pushSessionOwnership(_auth.currentUser!);
  }

  Future<void> stop() async {
    await _remoteSessionSubscription?.cancel();
    _remoteSessionSubscription = null;
    await _authSubscription?.cancel();
    _authSubscription = null;
    _started = false;
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    await _remoteSessionSubscription?.cancel();
    _remoteSessionSubscription = null;

    if (user == null) {
      return;
    }

    _remoteSessionSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection(_sessionCollection)
        .doc('current')
        .snapshots()
        .listen((snapshot) {
          unawaited(_enforceSingleDevice(snapshot));
        });
  }

  Future<void> _pushSessionOwnership(User user) async {
    final installationId = await _installationId();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(_sessionCollection)
        .doc('current')
        .set(<String, dynamic>{
          'activeDeviceId': installationId,
          'uid': user.uid,
          'email': user.email,
          'platform': _platformLabel(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _enforceSingleDevice(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_forcingLogout) {
      return;
    }
    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data();
    if (data == null) {
      return;
    }

    final activeDeviceId = (data['activeDeviceId'] ?? '').toString();
    if (activeDeviceId.isEmpty) {
      return;
    }

    final navigator = AppNavigator.navigatorKey.currentState;
    final currentContext = AppNavigator.navigatorKey.currentContext;
    final messenger = currentContext == null
        ? null
        : ScaffoldMessenger.maybeOf(currentContext);

    final localInstallationId = await _installationId();
    if (activeDeviceId == localInstallationId) {
      return;
    }

    _forcingLogout = true;
    try {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      await _auth.signOut();

      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (Route<dynamic> route) => false,
        );
      }
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'This account was logged in on another device. You were signed out from this device.',
          ),
        ),
      );
    } finally {
      _forcingLogout = false;
    }
  }

  Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey)?.trim() ?? '';
    if (existing.isNotEmpty) {
      return existing;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(1 << 32);
    final generated = 'dev_${now.toRadixString(16)}_${random.toRadixString(16)}';
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }
}
