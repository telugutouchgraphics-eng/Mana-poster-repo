import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana_poster/src/core/session/app_role.dart';
import 'package:mana_poster/src/core/session/session_state.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return SessionState(
      isAuthenticated: _currentUserExists(),
      hasCompletedPermissions: false,
      role: AppRole.user,
    );
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

  void completePermissions() {
    state = state.copyWith(hasCompletedPermissions: true);
  }

  void setRole(AppRole role) {
    state = state.copyWith(role: role);
  }

  void reset() {
    state = const SessionState(
      isAuthenticated: false,
      hasCompletedPermissions: false,
      role: AppRole.user,
    );
  }
}
