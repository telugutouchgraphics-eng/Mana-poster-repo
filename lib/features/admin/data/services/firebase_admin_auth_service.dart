import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mana_poster/features/admin/data/models/admin_audit_log.dart';
import 'package:mana_poster/features/admin/data/repositories/admin_auth_repository.dart';
import 'package:mana_poster/features/admin/data/services/admin_audit_log_service.dart';

class FirebaseAdminAuthService implements AdminAuthRepository {
  FirebaseAdminAuthService._({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static final FirebaseAdminAuthService instance = FirebaseAdminAuthService._();

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> authStateChanges() {
    if (Firebase.apps.isEmpty) {
      return Stream<User?>.value(null);
    }
    return _firebaseAuth.authStateChanges();
  }

  @override
  User? currentUser() {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return _firebaseAuth.currentUser;
  }

  @override
  bool isLoggedIn() => currentUser() != null;

  @override
  Future<AdminAuthorizationResult> checkAdminAuthorization({
    bool forceRefresh = false,
  }) async {
    if (Firebase.apps.isEmpty) {
      return const AdminAuthorizationResult(
        status: AdminAuthorizationStatus.error,
        message:
            'Firebase is not configured on this build. Complete Firebase setup first.',
      );
    }

    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return const AdminAuthorizationResult(
        status: AdminAuthorizationStatus.signedOut,
      );
    }

    try {
      final IdTokenResult token = await user.getIdTokenResult(forceRefresh);
      final bool isAdmin = token.claims?['admin'] == true;

      if (isAdmin) {
        return AdminAuthorizationResult(
          status: AdminAuthorizationStatus.authorized,
          user: user,
        );
      }

      return AdminAuthorizationResult(
        status: AdminAuthorizationStatus.unauthorized,
        user: user,
        message:
            'This account is signed in, but it does not have Mana Poster admin access.',
      );
    } on FirebaseAuthException catch (error) {
      return AdminAuthorizationResult(
        status: AdminAuthorizationStatus.error,
        user: user,
        message: _mapFirebaseAuthError(error),
      );
    } catch (_) {
      return AdminAuthorizationResult(
        status: AdminAuthorizationStatus.error,
        user: user,
        message:
            'Could not verify admin access right now. Check your connection and try again.',
      );
    }
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseConfigured();
    try {
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      unawaited(
        AdminAuditLogService.instance.success(
          actionType: AdminAuditActionType.loginSuccess,
          entityType: AdminAuditEntityType.auth,
          entityId: credential.user?.uid ?? '',
          message: 'Admin login completed.',
          summary: 'Admin signed in',
        ),
      );
      return credential;
    } on FirebaseAuthException catch (error) {
      throw AdminAuthFailure(_mapFirebaseAuthError(error));
    }
  }

  @override
  Future<void> signOut() async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    final User? user = _firebaseAuth.currentUser;
    unawaited(
      AdminAuditLogService.instance.success(
        actionType: AdminAuditActionType.logout,
        entityType: AdminAuditEntityType.auth,
        entityId: user?.uid ?? '',
        message: 'Admin logged out.',
        summary: 'Admin signed out',
      ),
    );
    await _firebaseAuth.signOut();
  }

  void _ensureFirebaseConfigured() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const AdminAuthFailure(
      'Firebase is not configured on this build. Complete Firebase setup first.',
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid admin email address.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'Network issue. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication yet.';
      default:
        return error.message ?? 'Admin login failed. Please try again.';
    }
  }
}

class AdminAuthFailure implements Exception {
  const AdminAuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
