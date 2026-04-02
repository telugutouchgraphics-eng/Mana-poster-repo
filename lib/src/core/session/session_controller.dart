import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana_poster/src/core/session/app_role.dart';
import 'package:mana_poster/src/core/session/session_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  static const String _permissionsKey = 'session.permissions_completed';
  StreamSubscription<User?>? _authSubscription;

  @override
  SessionState build() {
    final initial = SessionState(
      isAuthenticated: _currentUserExists(),
      hasCompletedPermissions: false,
      role: AppRole.user,
    );
    _bindAuthState();
    _hydratePermissions();
    ref.onDispose(() {
      _authSubscription?.cancel();
    });
    return initial;
  }

  static bool _currentUserExists() {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      // In tests or early app setup Firebase may not be initialized yet.
      return false;
    }
  }

  void markAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }

  Future<void> completePermissions() async {
    state = state.copyWith(hasCompletedPermissions: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsKey, true);
  }

  void setRole(AppRole role) {
    state = state.copyWith(role: role);
  }

  Future<void> reset() async {
    state = const SessionState(
      isAuthenticated: false,
      hasCompletedPermissions: false,
      role: AppRole.user,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
  }

  void _bindAuthState() {
    try {
      _authSubscription?.cancel();
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (user) {
          state = state.copyWith(isAuthenticated: user != null);
        },
      );
    } catch (_) {
      // Ignore when Firebase is not initialized in tests.
    }
  }

  Future<void> _hydratePermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool(_permissionsKey) ?? false;
      state = state.copyWith(hasCompletedPermissions: hasCompleted);
    } catch (_) {
      // Ignore local persistence errors and keep safe defaults.
    }
  }
}
