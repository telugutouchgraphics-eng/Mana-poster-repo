import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:mana_poster/firebase_options.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/device_session_service.dart';
import 'package:mana_poster/features/prehome/services/first150_trial_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class AuthFlowResult {
  const AuthFlowResult({
    this.first150TrialGranted = false,
    this.first150TrialExpiry,
  });

  final bool first150TrialGranted;
  final DateTime? first150TrialExpiry;
}

class FirebaseAuthService {
  static const String _googleProviderId = 'google.com';
  static const String _passwordProviderId = 'password';
  static const Duration _first150RetryWindow = Duration(hours: 24);
  static const Duration _googleStepTimeout = Duration(seconds: 35);

  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuthOverride = firebaseAuth,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth? _firebaseAuthOverride;
  final GoogleSignIn _googleSignIn;
  static Future<void>? _googleSignInInitializeFuture;

  FirebaseAuth get _firebaseAuth {
    final override = _firebaseAuthOverride;
    if (override != null) {
      return override;
    }
    _ensureFirebaseConfigured();
    return FirebaseAuth.instance;
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<AuthFlowResult> signInWithGoogle() async {
    _ensureFirebaseConfigured();
    try {
      if (kIsWeb) {
        final isNewUser = await _signInWithGoogleOnWeb();
        await _registerCurrentDeviceSessionBestEffort();
        return _claimFirst150TrialIfEligible(isNewUser: isNewUser);
      }

      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await _withGoogleTimeout(
        _resolveGoogleAccount(),
      );
      final googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          'Google Sign-In setup is incomplete. Please verify Firebase OAuth configuration.',
          code: 'google-sign-in-incomplete',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final userCredential = await _withGoogleTimeout(
        _firebaseAuth.signInWithCredential(credential),
      );
      await _withGoogleTimeout(_registerCurrentDeviceSessionBestEffort());
      return _claimFirst150TrialIfEligible(
        isNewUser: userCredential.additionalUserInfo?.isNewUser == true,
      );
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    } on GoogleSignInException catch (error) {
      throw _mapGoogleSignInError(error);
    } on PlatformException catch (error) {
      throw _mapGooglePlatformError(error);
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

  Future<AuthFlowResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseConfigured();
    final normalizedEmail = _normalizeEmail(email);
    final normalizedPassword = _sanitizePassword(password);
    final trimmedPassword = normalizedPassword.trim();
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      await _registerCurrentDeviceSessionBestEffort();
      return _claimFirst150TrialIfEligible(isNewUser: false);
    } on FirebaseAuthException catch (error) {
      final canRetryWithTrimmedPassword =
          error.code == 'invalid-credential' &&
          trimmedPassword != normalizedPassword &&
          trimmedPassword.length >= 6;
      if (canRetryWithTrimmedPassword) {
        try {
          await _firebaseAuth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: trimmedPassword,
          );
          await _registerCurrentDeviceSessionBestEffort();
          return _claimFirst150TrialIfEligible(isNewUser: false);
        } on FirebaseAuthException catch (retryError) {
          throw _mapFirebaseAuthError(retryError);
        }
      }
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<AuthFlowResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseConfigured();
    final normalizedEmail = _normalizeEmail(email);
    final normalizedPassword = _sanitizePassword(password);
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      await _registerCurrentDeviceSessionBestEffort();
      return _claimFirst150TrialIfEligible(isNewUser: true);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        final methods = await _fetchSignInMethods(normalizedEmail);
        if (methods.contains(_googleProviderId) &&
            !methods.contains(_passwordProviderId)) {
          throw const AuthFailure(
            'This email is already registered with Google Sign-In. Continue with Google for this account.',
            code: 'email-already-in-use-google',
          );
        }
      }
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    _ensureFirebaseConfigured();
    final normalizedEmail = _normalizeEmail(email);
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: normalizedEmail);
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
        await _ensureGoogleSignInInitialized();
        await _googleSignIn.signOut();
      } catch (_) {}
      await AppFlowService.persistLastKnownAuthUid(null);
      if (previousUid != null && previousUid.trim().isNotEmpty) {
        try {
          await PosterProfileService.clearLocalCacheForUid(previousUid);
        } catch (_) {}
      }
      return;
    }

    await Future.wait<void>(<Future<void>>[
      _firebaseAuth.signOut(),
      _ensureGoogleSignInInitialized().then((_) => _googleSignIn.signOut()),
    ]);
    await AppFlowService.persistLastKnownAuthUid(null);
    if (previousUid != null && previousUid.trim().isNotEmpty) {
      try {
        await PosterProfileService.clearLocalCacheForUid(previousUid);
      } catch (_) {}
    }
  }

  Future<bool> _signInWithGoogleOnWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters(<String, String>{'prompt': 'select_account'});

    try {
      final credential = await _firebaseAuth.signInWithPopup(provider);
      return credential.additionalUserInfo?.isNewUser == true;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'operation-not-supported-in-this-environment') {
        await _firebaseAuth.signInWithRedirect(provider);
        return false;
      }
      rethrow;
    }
  }

  Future<AuthFlowResult> _claimFirst150TrialIfEligible({
    required bool isNewUser,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const AuthFlowResult();
    }
    final creationTime = user.metadata.creationTime;
    final isRecentUser =
        creationTime != null &&
        DateTime.now().difference(creationTime) <= _first150RetryWindow;
    if (!isNewUser && !isRecentUser) {
      return const AuthFlowResult();
    }
    final result = await First150TrialService(
      firebaseAuth: _firebaseAuth,
    ).claimIfEligible();
    if (!result.claimed) {
      return const AuthFlowResult();
    }
    return AuthFlowResult(
      first150TrialGranted: true,
      first150TrialExpiry: result.expiryTime,
    );
  }

  Future<GoogleSignInAccount> _resolveGoogleAccount() async {
    final restoredFuture = _googleSignIn.attemptLightweightAuthentication();
    final restored = restoredFuture == null
        ? null
        : await _withGoogleTimeout(restoredFuture);
    if (restored != null) {
      return restored;
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthFailure(
        'Google Sign-In is not supported on this platform build.',
        code: 'unsupported-platform',
      );
    }
    return _withGoogleTimeout(
      _googleSignIn.authenticate(scopeHint: const <String>['email']),
    );
  }

  Future<T> _withGoogleTimeout<T>(Future<T> future) {
    return future.timeout(
      _googleStepTimeout,
      onTimeout: () {
        throw const AuthFailure(
          'Google Sign-In is taking too long. Check Google Play Services and internet, then try again.',
          code: 'google-timeout',
        );
      },
    );
  }

  Future<Set<String>> _fetchSignInMethods(String email) async {
    try {
      final delegate = FirebaseAuthPlatform.instanceFor(
        app: _firebaseAuth.app,
        pluginConstants: const <String, dynamic>{},
      );
      final methods = await delegate.fetchSignInMethodsForEmail(email);
      return methods
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    } on FirebaseAuthException {
      return <String>{};
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _sanitizePassword(String password) {
    return password.replaceAll('\r', '').replaceAll('\n', '');
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

  AuthFailure _mapGooglePlatformError(PlatformException error) {
    switch (error.code) {
      case 'sign_in_canceled':
        return const AuthFailure(
          'Google Sign-In was canceled.',
          code: 'google-canceled',
        );
      case 'network_error':
        return const AuthFailure(
          'Network issue. Please check your internet connection.',
          code: 'network-request-failed',
        );
      case 'sign_in_required':
        return const AuthFailure(
          'Google Sign-In was interrupted. Please try again.',
          code: 'google-interrupted',
        );
      case 'sign_in_failed':
      default:
        return AuthFailure(
          error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'Google Sign-In failed due to an unknown error.',
          code: 'google-unknown-error',
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
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AuthFailure(
          'Google Sign-In was interrupted. Please try again.',
          code: 'google-interrupted',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return AuthFailure(
          error.description?.trim().isNotEmpty == true
              ? error.description!.trim()
              : 'Google Sign-In setup is incomplete. Please verify Firebase OAuth configuration.',
          code: 'google-sign-in-incomplete',
        );
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return AuthFailure(
          error.description?.trim().isNotEmpty == true
              ? error.description!.trim()
              : 'Google Sign-In failed due to an unknown error.',
          code: 'google-unknown-error',
        );
    }
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitializeFuture ??= _googleSignIn.initialize(
      clientId: kIsWeb
          ? DefaultFirebaseOptions.webClientId
          : switch (defaultTargetPlatform) {
              TargetPlatform.iOS => DefaultFirebaseOptions.iosClientId,
              TargetPlatform.macOS => DefaultFirebaseOptions.iosClientId,
              _ => null,
            },
      serverClientId: DefaultFirebaseOptions.webClientId,
    );
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

  Future<void> _registerCurrentDeviceSessionBestEffort() async {
    try {
      await DeviceSessionService.instance.registerCurrentDeviceSession();
    } catch (_) {
      // Auth should still succeed even if post-login session sync is blocked.
    }
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
