import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:mana_poster/firebase_options.dart';

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
      await _ensureGoogleInitialized();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          'Google Sign-In setup is incomplete. Please verify Firebase OAuth configuration.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _firebaseAuth.signInWithCredential(credential);
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw AuthFailure(_mapGoogleSignInError(error));
    } on UnsupportedError {
      throw const AuthFailure(
        'Google Sign-In is not supported on this platform build.',
      );
    } catch (_) {
      throw const AuthFailure('Google Sign-In failed. Please try again.');
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
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseAuthError(error));
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
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseAuthError(error));
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    _ensureFirebaseConfigured();
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFirebaseAuthError(error));
    }
  }

  Future<void> signOut() async {
    if (Firebase.apps.isEmpty) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      return;
    }

    await Future.wait<void>(<Future<void>>[
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
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

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
      case 'network-request-failed':
        return 'Network issue. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _mapGoogleSignInError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google Sign-In was canceled.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google Sign-In was interrupted. Please try again.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In setup is incomplete. Verify Firebase OAuth client and SHA configuration.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Play services or provider configuration is not ready on this device.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In is not available right now. Try again from an active screen.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Signed-in account mismatch. Please sign out and try again.';
      case GoogleSignInExceptionCode.unknownError:
        return error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : 'Google Sign-In failed due to an unknown error.';
    }
  }

  void _ensureFirebaseConfigured() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const AuthFailure(
      'Authentication is not configured on this build. Complete Firebase setup for this platform first.',
    );
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
