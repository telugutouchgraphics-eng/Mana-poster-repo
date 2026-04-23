import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/data/repositories/admin_auth_repository.dart';
import 'package:mana_poster/features/admin/data/services/firebase_admin_auth_service.dart';
import 'package:mana_poster/features/admin/screens/admin_access_denied_screen.dart';
import 'package:mana_poster/features/admin/screens/admin_dashboard_screen.dart';
import 'package:mana_poster/features/admin/screens/admin_login_screen.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAdminAuthService.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AdminAuthLoadingScreen(
            message: 'Checking admin session...',
          );
        }
        final User? user = snapshot.data;
        if (user != null) {
          return _AdminAuthorizationGate(user: user);
        }
        return const AdminLoginScreen();
      },
    );
  }
}

class _AdminAuthorizationGate extends StatefulWidget {
  const _AdminAuthorizationGate({required this.user});

  final User user;

  @override
  State<_AdminAuthorizationGate> createState() =>
      _AdminAuthorizationGateState();
}

class _AdminAuthorizationGateState extends State<_AdminAuthorizationGate> {
  late Future<AdminAuthorizationResult> _authorizationFuture;

  @override
  void initState() {
    super.initState();
    _authorizationFuture = _checkAuthorization();
  }

  @override
  void didUpdateWidget(covariant _AdminAuthorizationGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _authorizationFuture = _checkAuthorization();
    }
  }

  Future<AdminAuthorizationResult> _checkAuthorization({
    bool forceRefresh = false,
  }) {
    return FirebaseAdminAuthService.instance.checkAdminAuthorization(
      forceRefresh: forceRefresh,
    );
  }

  void _retryAuthorization() {
    setState(() {
      _authorizationFuture = _checkAuthorization(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAuthorizationResult>(
      future: _authorizationFuture,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<AdminAuthorizationResult> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _AdminAuthLoadingScreen(
                message: 'Checking admin access...',
              );
            }

            final AdminAuthorizationResult? result = snapshot.data;
            if (result?.isAuthorized ?? false) {
              return const AdminDashboardScreen();
            }

            if (result?.status == AdminAuthorizationStatus.signedOut) {
              return const AdminLoginScreen();
            }

            return AdminAccessDeniedScreen(
              email: widget.user.email,
              message:
                  result?.message ??
                  'Could not verify Mana Poster admin access for this account.',
              onRetry: _retryAuthorization,
              onLogout: FirebaseAdminAuthService.instance.signOut,
            );
          },
    );
  }
}

class _AdminAuthLoadingScreen extends StatelessWidget {
  const _AdminAuthLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Color(0xFF5C6783)),
            ),
          ],
        ),
      ),
    );
  }
}
