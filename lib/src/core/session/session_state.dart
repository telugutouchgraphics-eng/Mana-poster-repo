import 'package:mana_poster/src/core/session/app_role.dart';

class SessionState {
  const SessionState({
    required this.isAuthenticated,
    required this.hasCompletedPermissions,
    required this.role,
  });

  final bool isAuthenticated;
  final bool hasCompletedPermissions;
  final AppRole role;

  SessionState copyWith({
    bool? isAuthenticated,
    bool? hasCompletedPermissions,
    AppRole? role,
  }) {
    return SessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasCompletedPermissions:
          hasCompletedPermissions ?? this.hasCompletedPermissions,
      role: role ?? this.role,
    );
  }
}
