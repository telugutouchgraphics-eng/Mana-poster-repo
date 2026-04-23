import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/widgets/flow_screen_header.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

enum _AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with AppLanguageStateMixin {
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
    final String nextRoute = snapshot.permissionsStepHandled
        ? await AppFlowService.resolveAuthenticatedEntryRoute()
        : AppRoutes.permissions;
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, nextRoute);
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

  Future<void> _openLegalDocument(LegalDocumentType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(documentType: type),
      ),
    );
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
                              final value = v ?? '';
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
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  authCopy.legalIntro,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 2,
                                  children: <Widget>[
                                    TextButton(
                                      onPressed: () => _openLegalDocument(
                                        LegalDocumentType.privacyPolicy,
                                      ),
                                      style: TextButton.styleFrom(
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(authCopy.privacyLabel),
                                    ),
                                    Text(
                                      authCopy.andLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _openLegalDocument(
                                        LegalDocumentType.termsAndConditions,
                                      ),
                                      style: TextButton.styleFrom(
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(authCopy.termsLabel),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
    AppLanguage.english ||
    AppLanguage.tamil ||
    AppLanguage.kannada ||
    AppLanguage.malayalam => 'Password is required',
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
    AppLanguage.english ||
    AppLanguage.tamil ||
    AppLanguage.kannada ||
    AppLanguage.malayalam =>
      isLogin
          ? 'Login with your account details and continue your poster flow.'
          : 'Create a new account and start your poster journey.',
  };

  String resetSuccess(String email) => switch (language) {
    AppLanguage.telugu => '$email కి password reset email పంపించాం.',
    AppLanguage.hindi => '$email पर password reset email भेज दिया गया है.',
    AppLanguage.english ||
    AppLanguage.tamil ||
    AppLanguage.kannada ||
    AppLanguage.malayalam => 'Password reset email sent to $email.',
  };

  String get legalIntro => switch (language) {
    AppLanguage.telugu =>
      'కొనసాగించడం ద్వారా మా ప్రైవసీ పాలసీ మరియు నిబంధనలు అంగీకరిస్తున్నారు.',
    AppLanguage.hindi =>
      'जारी रखने पर आप हमारी प्राइवेसी पॉलिसी और नियम स्वीकार करते हैं।',
    AppLanguage.english =>
      'By continuing, you agree to our Privacy Policy and Terms & Conditions.',
    AppLanguage.tamil =>
      'தொடர்வதன் மூலம் எங்கள் Privacy Policy மற்றும் Terms-ஐ ஏற்கிறீர்கள்.',
    AppLanguage.kannada =>
      'ಮುಂದುವರಿದರೆ ನಮ್ಮ Privacy Policy ಮತ್ತು Terms ಅನ್ನು ಒಪ್ಪುತ್ತೀರಿ.',
    AppLanguage.malayalam =>
      'തുടരുന്നതിലൂടെ ഞങ്ങളുടെ Privacy Policy, Terms എന്നിവ അംഗീകരിക്കുന്നു.',
  };

  String get privacyLabel => switch (language) {
    AppLanguage.telugu => 'ప్రైవసీ పాలసీ',
    AppLanguage.hindi => 'प्राइवेसी पॉलिसी',
    AppLanguage.english => 'Privacy Policy',
    AppLanguage.tamil => 'Privacy Policy',
    AppLanguage.kannada => 'Privacy Policy',
    AppLanguage.malayalam => 'Privacy Policy',
  };

  String get andLabel => switch (language) {
    AppLanguage.telugu => 'మరియు',
    AppLanguage.hindi => 'और',
    AppLanguage.english => 'and',
    AppLanguage.tamil => 'மற்றும்',
    AppLanguage.kannada => 'ಮತ್ತು',
    AppLanguage.malayalam => 'മറ്റും',
  };

  String get termsLabel => switch (language) {
    AppLanguage.telugu => 'నిబంధనలు షరతులు',
    AppLanguage.hindi => 'नियम और शर्तें',
    AppLanguage.english => 'Terms & Conditions',
    AppLanguage.tamil => 'Terms & Conditions',
    AppLanguage.kannada => 'Terms & Conditions',
    AppLanguage.malayalam => 'Terms & Conditions',
  };
}
