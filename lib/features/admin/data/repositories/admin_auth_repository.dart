import 'package:firebase_auth/firebase_auth.dart';

enum AdminAuthorizationStatus { signedOut, authorized, unauthorized, error }

class AdminAuthorizationResult {
  const AdminAuthorizationResult({
    required this.status,
    this.user,
    this.message,
  });

  final AdminAuthorizationStatus status;
  final User? user;
  final String? message;

  bool get isAuthorized => status == AdminAuthorizationStatus.authorized;

  bool get isUnauthorized => status == AdminAuthorizationStatus.unauthorized;
}

abstract class AdminAuthRepository {
  Stream<User?> authStateChanges();

  User? currentUser();

  bool isLoggedIn();

  Future<AdminAuthorizationResult> checkAdminAuthorization({
    bool forceRefresh = false,
  });

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
