import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/widgets/flow_screen_header.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

enum _AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.login;
  bool _loadingGoogle = false;
  bool _loadingEmail = false;
  bool _loadingReset = false;

  bool get _isBusy => _loadingGoogle || _loadingEmail || _loadingReset;

  Future<void> _continueWithGoogle() async {
    if (_loadingEmail || _loadingReset) {
      return;
    }
    setState(() => _loadingGoogle = true);
    try {
      await _service.signInWithGoogle();
      await _continueAfterAuth();
    } catch (e) {
      _showError(_messageForError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingGoogle = false);
      }
    }
  }

  Future<void> _continueWithEmail() async {
    if (_loadingGoogle || _loadingReset) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loadingEmail = true);
    try {
      if (_mode == _AuthMode.login) {
        await _service.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _service.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      await _continueAfterAuth();
    } catch (e) {
      _showError(_messageForError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingEmail = false);
      }
    }
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForError(Object error) {
    if (error is AuthFailure) {
      return error.message;
    }
    return 'Please try again.';
  }

  Future<void> _continueAfterAuth() async {
    final snapshot = await AppFlowService.loadSnapshot();
    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      snapshot.permissionsStepHandled ? AppRoutes.home : AppRoutes.permissions,
    );
  }

  Future<void> _onForgotPassword() async {
    if (_loadingEmail || _loadingGoogle) {
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError(context.strings.validEmailError);
      return;
    }

    setState(() => _loadingReset = true);
    try {
      await _service.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }
      _showSuccess(_AuthUiCopy(context.currentLanguage).resetSuccess(email));
    } catch (e) {
      _showError(_messageForError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingReset = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final isLogin = _mode == _AuthMode.login;
    final authCopy = _AuthUiCopy(context.currentLanguage);

    return Scaffold(
      body: GradientShell(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                FlowScreenHeader(
                  title: strings.loginWelcome,
                  subtitle: strings.loginSubtitle,
                  badge: '03',
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            isLogin ? strings.loginLabel : strings.signUpLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            authCopy.formSubtitle(isLogin),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[AutofillHints.email],
                            decoration: InputDecoration(
                              hintText: strings.emailAddress,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty || !value.contains('@')) {
                                return strings.validEmailError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: isLogin
                                ? const <String>[AutofillHints.password]
                                : const <String>[AutofillHints.newPassword],
                            onFieldSubmitted: (_) => _continueWithEmail(),
                            decoration: InputDecoration(
                              hintText: strings.password,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '');
                              if (value.trim().isEmpty) {
                                return authCopy.passwordRequired;
                              }
                              if (value.length < 6) {
                                return strings.passwordError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loadingReset
                                    ? null
                                    : _onForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(strings.forgotPassword),
                              ),
                            ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _loadingReset
                                ? const Padding(
                                    key: ValueKey<String>('reset-loading'),
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: LinearProgressIndicator(
                                      minHeight: 2,
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey<String>('reset-space'),
                                    height: 8,
                                  ),
                          ),
                          PrimaryButton(
                            label: isLogin
                                ? strings.loginWithEmail
                                : strings.signUpWithEmail,
                            icon: isLogin
                                ? Icons.login_rounded
                                : Icons.person_add_alt_1_rounded,
                            loading: _loadingEmail,
                            onPressed: _continueWithEmail,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isBusy ? null : _continueWithGoogle,
                            icon: _loadingGoogle
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.g_mobiledata_rounded),
                            label: Text(strings.googleContinue),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                isLogin
                                    ? strings.noAccount
                                    : strings.alreadyHaveAccount,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              TextButton(
                                onPressed: _isBusy
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        setState(
                                          () => _mode = isLogin
                                              ? _AuthMode.signup
                                              : _AuthMode.login,
                                        );
                                      },
                                child: Text(
                                  isLogin
                                      ? strings.signUpLabel
                                      : strings.loginLabel,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthUiCopy {
  const _AuthUiCopy(this.language);

  final AppLanguage language;

  String get passwordRequired => switch (language) {
    AppLanguage.telugu => 'Password అవసరం',
    AppLanguage.hindi => 'Password ज़रूरी है',
    AppLanguage.english => 'Password is required',
  };

  String formSubtitle(bool isLogin) => switch (language) {
    AppLanguage.telugu =>
      isLogin
          ? 'మీ account details తో login అయి మీ poster flow కొనసాగించండి.'
          : 'కొత్త account create చేసి మీ poster journey ప్రారంభించండి.',
    AppLanguage.hindi =>
      isLogin
          ? 'अपने account details से login करके poster flow जारी रखें.'
          : 'नया account बनाकर अपनी poster journey शुरू करें.',
    AppLanguage.english =>
      isLogin
          ? 'Login with your account details and continue your poster flow.'
          : 'Create a new account and start your poster journey.',
  };

  String resetSuccess(String email) => switch (language) {
    AppLanguage.telugu => '$email కి password reset email పంపించాం.',
    AppLanguage.hindi => '$email पर password reset email भेज दिया गया है.',
    AppLanguage.english => 'Password reset email sent to $email.',
  };
}
