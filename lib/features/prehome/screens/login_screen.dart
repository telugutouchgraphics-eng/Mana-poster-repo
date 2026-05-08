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
  bool _showPassword = false;

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
      return _localizedAuthError(error);
    }
    return context.strings.localized(
      telugu: 'ఇంకోసారి ప్రయత్నించండి.',
      english: 'Please try again.',
    );
  }

  String _localizedAuthError(AuthFailure error) {
    final strings = context.strings;
    switch (error.code) {
      case 'invalid-email':
        return strings.validEmailError;
      case 'user-disabled':
        return strings.localized(
          telugu: 'ఈ ఖాతా నిలిపివేయబడింది.',
          english: 'This account has been disabled.',
        );
      case 'user-not-found':
        return strings.localized(
          telugu: 'ఈ ఇమెయిల్‌కు ఖాతా కనిపించలేదు.',
          english: 'No account found for this email.',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return strings.localized(
          telugu: 'ఇమెయిల్ లేదా పాస్‌వర్డ్ సరైనది కాదు.',
          english: 'Incorrect email or password.',
        );
      case 'email-already-in-use':
        return strings.localized(
          telugu: 'ఈ ఇమెయిల్‌తో ఇప్పటికే ఖాతా ఉంది.',
          english: 'An account already exists with this email.',
        );
      case 'weak-password':
        return strings.passwordError;
      case 'operation-not-allowed':
        return strings.localized(
          telugu: 'ఈ లాగిన్ విధానం ఇంకా అందుబాటులో లేదు.',
          english: 'This sign-in method is not enabled yet.',
        );
      case 'unauthorized-domain':
        return strings.localized(
          telugu: 'ఈ డొమైన్ Firebase Authentication లో అనుమతించబడలేదు.',
          english: 'This domain is not authorized in Firebase Authentication.',
        );
      case 'popup-blocked':
        return strings.localized(
          telugu:
              'Google login popup block అయింది. Popups allow చేసి మళ్లీ ప్రయత్నించండి.',
          english:
              'Google Sign-In popup was blocked. Allow popups and try again.',
        );
      case 'popup-closed-by-user':
      case 'google-canceled':
        return strings.localized(
          telugu: 'Google login పూర్తయ్యే ముందే మూసేశారు.',
          english: 'Google Sign-In was canceled before completing sign-in.',
        );
      case 'cancelled-popup-request':
      case 'google-interrupted':
        return strings.localized(
          telugu: 'Google login మధ్యలో ఆగింది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In was interrupted. Please try again.',
        );
      case 'network-request-failed':
        return strings.localized(
          telugu:
              'ఇంటర్నెట్ సమస్య ఉంది. కనెక్షన్ చెక్ చేసి మళ్లీ ప్రయత్నించండి.',
          english: 'Network issue. Please check your internet connection.',
        );
      case 'too-many-requests':
        return strings.localized(
          telugu: 'చాలా ప్రయత్నాలు అయ్యాయి. కొంచెం తర్వాత మళ్లీ ప్రయత్నించండి.',
          english: 'Too many attempts. Please wait and try again.',
        );
      case 'google-sign-in-incomplete':
      case 'google-client-configuration-error':
        return strings.localized(
          telugu:
              'Google login setup పూర్తిగా లేదు. కొద్దిసేపటి తర్వాత మళ్లీ ప్రయత్నించండి.',
          english:
              'Google Sign-In setup is incomplete. Please try again later.',
        );
      case 'google-provider-configuration-error':
      case 'google-ui-unavailable':
        return strings.localized(
          telugu: 'ఈ డివైస్‌లో Google login ప్రస్తుతం అందుబాటులో లేదు.',
          english: 'Google Sign-In is not available on this device right now.',
        );
      case 'google-user-mismatch':
        return strings.localized(
          telugu: 'Google account mismatch వచ్చింది. మళ్లీ sign in చేయండి.',
          english: 'Signed-in account mismatch. Please sign in again.',
        );
      case 'unsupported-platform':
        return strings.localized(
          telugu: 'ఈ build లో Google login support లేదు.',
          english: 'Google Sign-In is not supported on this build.',
        );
      case 'not-configured':
        return strings.localized(
          telugu: 'ఈ build లో authentication setup పూర్తి కాలేదు.',
          english: 'Authentication is not configured on this build.',
        );
      case 'google-sign-in-failed':
      case 'google-unknown-error':
        return strings.localized(
          telugu: 'Google login విఫలమైంది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In failed. Please try again.',
        );
      default:
        return error.message;
    }
  }

  Future<void> _continueAfterAuth() async {
    await AppFlowService.loadSnapshot();
    final permissionsHandled =
        await AppFlowService.resolvePermissionsStepHandled();
    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final String nextRoute = permissionsHandled
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
                            obscureText: !_showPassword,
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
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _showPassword = !_showPassword,
                                  );
                                },
                                tooltip: authCopy.passwordVisibilityTooltip(
                                  _showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
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
                                : Image.asset(
                                    'assets/branding/google_logo.png',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                  ),
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
    AppLanguage.telugu => 'పాస్‌వర్డ్ అవసరం',
    AppLanguage.hindi => 'पासवर्ड आवश्यक है',
    AppLanguage.english => 'Password is required',
    AppLanguage.tamil => 'கடவுச்சொல் அவசியம்',
    AppLanguage.kannada => 'ಪಾಸ್‌ವರ್ಡ್ ಅಗತ್ಯವಿದೆ',
    AppLanguage.malayalam => 'പാസ്‌വേഡ് ആവശ്യമാണ്',
  };

  String formSubtitle(bool isLogin) => switch (language) {
    AppLanguage.telugu =>
      isLogin
          ? 'మీ ఖాతా వివరాలతో లాగిన్ అయి పోస్టర్ ప్రయాణాన్ని కొనసాగించండి.'
          : 'కొత్త ఖాతా సృష్టించి మీ పోస్టర్ ప్రయాణాన్ని ప్రారంభించండి.',
    AppLanguage.hindi =>
      isLogin
          ? 'अपने खाते की जानकारी से लॉगिन करें और पोस्टर यात्रा जारी रखें।'
          : 'नया खाता बनाएं और अपनी पोस्टर यात्रा शुरू करें।',
    AppLanguage.english =>
      isLogin
          ? 'Login with your account details and continue your poster flow.'
          : 'Create a new account and start your poster journey.',
    AppLanguage.tamil =>
      isLogin
          ? 'உங்கள் கணக்கு விவரங்களுடன் உள்நுழைந்து போஸ்டர் பயணத்தை தொடருங்கள்.'
          : 'புதிய கணக்கை உருவாக்கி உங்கள் போஸ்டர் பயணத்தை தொடங்குங்கள்.',
    AppLanguage.kannada =>
      isLogin
          ? 'ನಿಮ್ಮ ಖಾತೆ ವಿವರಗಳಿಂದ ಲಾಗಿನ್ ಮಾಡಿ ಪೋಸ್ಟರ್ ಪ್ರಯಾಣವನ್ನು ಮುಂದುವರಿಸಿ.'
          : 'ಹೊಸ ಖಾತೆ ಸೃಷ್ಟಿಸಿ ನಿಮ್ಮ ಪೋಸ್ಟರ್ ಪ್ರಯಾಣವನ್ನು ಆರಂಭಿಸಿ.',
    AppLanguage.malayalam =>
      isLogin
          ? 'നിങ്ങളുടെ അക്കൗണ്ട് വിവരങ്ങളോടെ ലോഗിൻ ചെയ്ത് പോസ്റ്റർ യാത്ര തുടരുക.'
          : 'പുതിയ അക്കൗണ്ട് സൃഷ്ടിച്ച് നിങ്ങളുടെ പോസ്റ്റർ യാത്ര ആരംഭിക്കുക.',
  };

  String resetSuccess(String email) => switch (language) {
    AppLanguage.telugu => '$email కి పాస్‌వర్డ్ రీసెట్ మెయిల్ పంపించాం.',
    AppLanguage.hindi => '$email पर पासवर्ड रीसेट मेल भेज दिया गया है।',
    AppLanguage.english => 'Password reset email sent to $email.',
    AppLanguage.tamil => '$email க்கு கடவுச்சொல் ரீசெட் மெயில் அனுப்பப்பட்டது.',
    AppLanguage.kannada => '$email ಗೆ ಪಾಸ್‌ವರ್ಡ್ ರೀಸೆಟ್ ಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ.',
    AppLanguage.malayalam => '$email ലേക്ക് പാസ്‌വേഡ് റീസെറ്റ് മെയിൽ അയച്ചു.',
  };

  String get legalIntro => switch (language) {
    AppLanguage.telugu =>
      'కొనసాగించడం ద్వారా మీరు మా గోప్యతా విధానం మరియు నిబంధనలకు అంగీకరిస్తారు.',
    AppLanguage.hindi =>
      'जारी रखने पर आप हमारी प्राइवेसी पॉलिसी और नियम एवं शर्तों से सहमत होते हैं।',
    AppLanguage.english =>
      'By continuing, you agree to our Privacy Policy and Terms & Conditions.',
    AppLanguage.tamil =>
      'தொடருவதன் மூலம் எங்கள் தனியுரிமைக் கொள்கை மற்றும் விதிமுறைகளுக்கு நீங்கள் ஒப்புக்கொள்கிறீர்கள்.',
    AppLanguage.kannada =>
      'ಮುಂದುವರಿದರೆ ನಮ್ಮ ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ನಿಯಮಗಳು ಹಾಗೂ ಷರತ್ತುಗಳಿಗೆ ನೀವು ಒಪ್ಪುತ್ತೀರಿ.',
    AppLanguage.malayalam =>
      'തുടരുന്നതിലൂടെ ഞങ്ങളുടെ സ്വകാര്യതാ നയംയും നിബന്ധനകളും നിങ്ങൾ അംഗീകരിക്കുന്നു.',
  };

  String get privacyLabel => switch (language) {
    AppLanguage.telugu => 'గోప్యతా విధానం',
    AppLanguage.hindi => 'प्राइवेसी पॉलिसी',
    AppLanguage.english => 'Privacy Policy',
    AppLanguage.tamil => 'தனியுரிமைக் கொள்கை',
    AppLanguage.kannada => 'ಗೌಪ್ಯತಾ ನೀತಿ',
    AppLanguage.malayalam => 'സ്വകാര്യതാ നയം',
  };

  String get andLabel => switch (language) {
    AppLanguage.telugu => 'మరియు',
    AppLanguage.hindi => 'और',
    AppLanguage.english => 'and',
    AppLanguage.tamil => 'மற்றும்',
    AppLanguage.kannada => 'ಮತ್ತು',
    AppLanguage.malayalam => 'കൂടാതെ',
  };

  String get termsLabel => switch (language) {
    AppLanguage.telugu => 'నిబంధనలు',
    AppLanguage.hindi => 'नियम एवं शर्तें',
    AppLanguage.english => 'Terms & Conditions',
    AppLanguage.tamil => 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
    AppLanguage.kannada => 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
    AppLanguage.malayalam => 'നിബന്ധനകളും വ്യവസ്ഥകളും',
  };

  String passwordVisibilityTooltip(bool isVisible) => switch (language) {
    AppLanguage.telugu => isVisible ? 'పాస్‌వర్డ్ దాచు' : 'పాస్‌వర్డ్ చూపు',
    AppLanguage.hindi => isVisible ? 'पासवर्ड छिपाएँ' : 'पासवर्ड दिखाएँ',
    AppLanguage.english => isVisible ? 'Hide password' : 'Show password',
    AppLanguage.tamil => isVisible ? 'கடவுச்சொல்லை மறை' : 'கடவுச்சொல்லை காட்டு',
    AppLanguage.kannada =>
      isVisible ? 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆಮಾಡಿ' : 'ಪಾಸ್‌ವರ್ಡ್ ತೋರಿಸಿ',
    AppLanguage.malayalam =>
      isVisible ? 'പാസ്‌വേഡ് മറയ്ക്കുക' : 'പാസ്‌വേഡ് കാണിക്കുക',
  };
}
