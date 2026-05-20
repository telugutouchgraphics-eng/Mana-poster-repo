import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:mana_poster/firebase_options.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/services/device_session_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithGoogle() async {
    _ensureFirebaseConfigured();
    try {
      if (kIsWeb) {
        await _signInWithGoogleOnWeb();
        await DeviceSessionService.instance.registerCurrentDeviceSession();
        return;
      }

      await _ensureGoogleInitialized();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          'Google Sign-In setup is incomplete. Please verify Firebase OAuth configuration.',
          code: 'google-sign-in-incomplete',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _firebaseAuth.signInWithCredential(credential);
      await DeviceSessionService.instance.registerCurrentDeviceSession();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    } on GoogleSignInException catch (error) {
      throw _mapGoogleSignInError(error);
    } on UnsupportedError {
      throw const AuthFailure(
        'Google Sign-In is not supported on this platform build.',
        code: 'unsupported-platform',
      );
    } catch (_) {
      throw const AuthFailure(
        'Google Sign-In failed. Please try again.',
        code: 'google-sign-in-failed',
      );
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseConfigured();
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await DeviceSessionService.instance.registerCurrentDeviceSession();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseConfigured();
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await DeviceSessionService.instance.registerCurrentDeviceSession();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    _ensureFirebaseConfigured();
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<void> signOut() async {
    final previousUid = _firebaseAuth.currentUser?.uid;
    try {
      await SubscriptionBackendService.resetLocalClientStateForAuthChange();
    } catch (_) {}
    if (Firebase.apps.isEmpty) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      if (previousUid != null && previousUid.trim().isNotEmpty) {
        try {
          await PosterProfileService.clearLocalCacheForUid(previousUid);
        } catch (_) {}
      }
      return;
    }

    await Future.wait<void>(<Future<void>>[
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
    if (previousUid != null && previousUid.trim().isNotEmpty) {
      try {
        await PosterProfileService.clearLocalCacheForUid(previousUid);
      } catch (_) {}
    }
  }

  Future<void> _signInWithGoogleOnWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters(<String, String>{'prompt': 'select_account'});

    try {
      await _firebaseAuth.signInWithPopup(provider);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'operation-not-supported-in-this-environment') {
        await _firebaseAuth.signInWithRedirect(provider);
        return;
      }
      rethrow;
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }

    final String? clientId = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => DefaultFirebaseOptions.iosClientId,
      TargetPlatform.macOS => DefaultFirebaseOptions.iosClientId,
      _ => null,
    };

    await _googleSignIn.initialize(
      clientId: kIsWeb ? DefaultFirebaseOptions.webClientId : clientId,
      serverClientId: DefaultFirebaseOptions.webClientId,
    );
    _googleInitialized = true;
  }

  AuthFailure _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return const AuthFailure(
          'Please enter a valid email address.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthFailure(
          'This account has been disabled.',
          code: 'user-disabled',
        );
      case 'user-not-found':
        return const AuthFailure(
          'No account found for this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure(
          'Incorrect email or password.',
          code: 'invalid-credential',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          'An account already exists with this email.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthFailure(
          'Password should be at least 6 characters.',
          code: 'weak-password',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          'This sign-in method is not enabled in Firebase yet.',
          code: 'operation-not-allowed',
        );
      case 'unauthorized-domain':
        return const AuthFailure(
          'This admin domain is not authorized in Firebase Authentication. Add this domain under Authorized domains.',
          code: 'unauthorized-domain',
        );
      case 'popup-blocked':
        return const AuthFailure(
          'Google Sign-In popup was blocked. Allow popups and try again.',
          code: 'popup-blocked',
        );
      case 'popup-closed-by-user':
        return const AuthFailure(
          'Google Sign-In popup was closed before completing sign-in.',
          code: 'popup-closed-by-user',
        );
      case 'cancelled-popup-request':
        return const AuthFailure(
          'Google Sign-In popup was interrupted. Try again once.',
          code: 'cancelled-popup-request',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'Network issue. Please check your internet connection.',
          code: 'network-request-failed',
        );
      case 'too-many-requests':
        return const AuthFailure(
          'Too many attempts. Please wait and try again.',
          code: 'too-many-requests',
        );
      default:
        return AuthFailure(
          error.message ?? 'Authentication failed. Please try again.',
          code: error.code,
        );
    }
  }

  AuthFailure _mapGoogleSignInError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return const AuthFailure(
          'Google Sign-In was canceled.',
          code: 'google-canceled',
        );
      case GoogleSignInExceptionCode.interrupted:
        return const AuthFailure(
          'Google Sign-In was interrupted. Please try again.',
          code: 'google-interrupted',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
        return const AuthFailure(
          'Google Sign-In setup is incomplete. Verify Firebase OAuth client and SHA configuration.',
          code: 'google-client-configuration-error',
        );
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const AuthFailure(
          'Google Play services or provider configuration is not ready on this device.',
          code: 'google-provider-configuration-error',
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AuthFailure(
          'Google Sign-In is not available right now. Try again from an active screen.',
          code: 'google-ui-unavailable',
        );
      case GoogleSignInExceptionCode.userMismatch:
        return const AuthFailure(
          'Signed-in account mismatch. Please sign out and try again.',
          code: 'google-user-mismatch',
        );
      case GoogleSignInExceptionCode.unknownError:
        return AuthFailure(
          error.description?.trim().isNotEmpty == true
              ? error.description!.trim()
              : 'Google Sign-In failed due to an unknown error.',
          code: 'google-unknown-error',
        );
    }
  }

  void _ensureFirebaseConfigured() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const AuthFailure(
      'Authentication is not configured on this build. Complete Firebase setup for this platform first.',
      code: 'not-configured',
    );
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
