import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mana_poster/src/core/constants/app_routes.dart';
import 'package:mana_poster/src/core/localization/app_strings.dart';
import 'package:mana_poster/src/core/localization/localization_controller.dart';
import 'package:mana_poster/src/core/session/session_controller.dart';
import 'package:mana_poster/src/features/auth/data/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onGoogleSignIn() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      ref.read(sessionControllerProvider.notifier).markAuthenticated(true);
      final session = ref.read(sessionControllerProvider);
      if (!mounted) {
        return;
      }
      context.go(
        session.hasCompletedPermissions ? AppRoutes.home : AppRoutes.permissions,
      );
    } on AuthCancelledException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Google sign-in cancelled')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onEmailAuth({required bool createAccount}) async {
    if (_loading) {
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid email and 6+ char password')),
      );
      return;
    }

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (createAccount) {
        await ref
            .read(authServiceProvider)
            .createAccountWithEmail(email: email, password: password);
      } else {
        await ref
            .read(authServiceProvider)
            .signInWithEmail(email: email, password: password);
      }
      ref.read(sessionControllerProvider.notifier).markAuthenticated(true);
      final session = ref.read(sessionControllerProvider);
      if (!mounted) {
        return;
      }
      context.go(
        session.hasCompletedPermissions ? AppRoutes.home : AppRoutes.permissions,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(localizationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.text(language, AppStrings.loginTitle))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(AppStrings.text(language, AppStrings.loginTitle)),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: AppStrings.text(language, AppStrings.emailHint),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: AppStrings.text(language, AppStrings.passwordHint),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () => _onEmailAuth(createAccount: false),
                child: Text(
                  _loading
                      ? AppStrings.text(language, AppStrings.authInProgress)
                      : AppStrings.text(language, AppStrings.loginWithEmail),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _onEmailAuth(createAccount: true),
                child: Text(AppStrings.text(language, AppStrings.createAccount)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _onGoogleSignIn,
                child: Text(AppStrings.text(language, AppStrings.loginWithGoogle)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
