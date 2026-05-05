import 'package:firebase_auth/firebase_auth.dart';

enum AdminAuthorizationStatus { signedOut, authorized, unauthorized, error }

enum AdminPortalRole { admin, manager, creator }

class AdminAuthorizationResult {
  const AdminAuthorizationResult({
    required this.status,
    required this.role,
    this.user,
    this.message,
  });

  final AdminAuthorizationStatus status;
  final AdminPortalRole role;
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
    required AdminPortalRole role,
    bool forceRefresh = false,
  });

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
