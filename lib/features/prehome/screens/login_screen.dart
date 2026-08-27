import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

enum _AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with AppLanguageStateMixin, WidgetsBindingObserver {
  final FirebaseAuthService _service = FirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _authBootstrapping = !FirebaseBootstrap.hasFirebaseApp;
  bool _loadingGoogle = false;
  bool _loadingEmail = false;
  bool _loadingReset = false;
  bool _skipping = false;
  bool _showOtherOptions = false;
  bool _showPassword = false;
  _AuthMode _authMode = _AuthMode.login;

  bool get _isBusy =>
      _authBootstrapping ||
      _loadingGoogle ||
      _loadingEmail ||
      _loadingReset ||
      _skipping;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ScreenSecurityService.disableSecure());
    _stabilizeBottomSystemUi();
    unawaited(_prepareAuthDependencies());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ScreenSecurityService.enableSecure());
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _stabilizeBottomSystemUi();
    }
  }

  Future<void> _prepareAuthDependencies() async {
    if (FirebaseBootstrap.hasFirebaseApp) {
      if (mounted && _authBootstrapping) {
        setState(() => _authBootstrapping = false);
      }
      return;
    }
    try {
      await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);
    } finally {
      if (mounted) {
        setState(() => _authBootstrapping = false);
      }
    }
  }

  Future<void> _stabilizeBottomSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 180), () async {
          if (!mounted) {
            return;
          }
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
        }),
      );
    });
  }

  Future<void> _continueWithGoogle() async {
    if (_isBusy) {
      return;
    }
    setState(() => _loadingGoogle = true);
    try {
      final AuthFlowResult authResult = await _service.signInWithGoogle();
      await _stabilizeBottomSystemUi();
      await _showFirst150TrialDialogIfNeeded(authResult);
      await _continueAfterAuth();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(_messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingGoogle = false);
      }
    }
  }

  Future<void> _continueWithEmail() async {
    if (_isBusy) {
      return;
    }
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    setState(() => _loadingEmail = true);
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      final AuthFlowResult authResult = _authMode == _AuthMode.login
          ? await _service.signInWithEmail(email: email, password: password)
          : await _service.signUpWithEmail(email: email, password: password);
      await _stabilizeBottomSystemUi();
      await _showFirst150TrialDialogIfNeeded(authResult);
      await _continueAfterAuth();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(_messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingEmail = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_isBusy) {
      return;
    }
    final String email = _emailController.text.trim();
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
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentTopSnackBar()
        ..showTopSnackBar(
          AppSnackBar.build(content: Text(_LoginUiCopy(context.currentLanguage).resetSent(email))),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(_messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingReset = false);
      }
    }
  }

  Future<void> _skipNow() async {
    if (_isBusy) {
      return;
    }
    setState(() => _skipping = true);
    try {
      await _service.signOut();
      await AppFlowService.persistLastKnownAuthUid(null);
      await AppFlowService.loadSnapshot();
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } finally {
      if (mounted) {
        setState(() => _skipping = false);
      }
    }
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  Future<void> _showFirst150TrialDialogIfNeeded(AuthFlowResult result) async {
    if (!result.first150TrialGranted || !mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            context.strings.localized(
              telugu: 'ప్రీమియం బహుమతి',
              english: 'Premium Gift',
            ),
          ),
          content: Text(
            context.strings.localized(
              telugu: 'అభినందనలు! మీకు 30 రోజుల ప్రీమియం ఉచితంగా లభించింది.',
              english: 'Congratulations! You received 30 days Premium free.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.strings.localized(telugu: 'సరే', english: 'OK'),
              ),
            ),
          ],
        );
      },
    );
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
    final AppStrings strings = context.strings;
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
      case 'email-already-in-use-google':
      case 'use-google-for-this-email':
        return strings.localized(
          telugu: 'ఈ ఖాతాకు Google తోనే continue చేయాలి.',
          english: 'Continue with Google for this account.',
        );
      case 'weak-password':
        return strings.passwordError;
      case 'popup-blocked':
        return strings.localized(
          telugu: 'Google login popup block అయింది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In popup was blocked. Try again.',
        );
      case 'popup-closed-by-user':
      case 'google-canceled':
        return strings.localized(
          telugu: 'Google login cancel అయింది.',
          english: 'Google Sign-In was canceled.',
        );
      case 'google-interrupted':
      case 'cancelled-popup-request':
        return strings.localized(
          telugu: 'Google login మధ్యలో ఆగింది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In was interrupted. Please try again.',
        );
      case 'network-request-failed':
        return strings.localized(
          telugu: 'ఇంటర్నెట్ సమస్య ఉంది. కనెక్షన్ చెక్ చేయండి.',
          english: 'Network issue. Please check your internet connection.',
        );
      case 'too-many-requests':
        return strings.localized(
          telugu: 'చాలా ప్రయత్నాలు అయ్యాయి. కొంచెం తర్వాత మళ్లీ ప్రయత్నించండి.',
          english: 'Too many attempts. Please wait and try again.',
        );
      case 'google-sign-in-incomplete':
      case 'google-client-configuration-error':
      case 'google-provider-configuration-error':
        return strings.localized(
          telugu: 'Google login setup పూర్తి కాలేదు.',
          english: 'Google Sign-In setup is incomplete.',
        );
      case 'google-ui-unavailable':
      case 'unsupported-platform':
        return strings.localized(
          telugu: 'ఈ డివైస్‌లో Google login ప్రస్తుతం అందుబాటులో లేదు.',
          english: 'Google Sign-In is not available on this device right now.',
        );
      case 'not-configured':
        return strings.localized(
          telugu: 'ఈ build లో authentication setup పూర్తి కాలేదు.',
          english: 'Authentication is not configured on this build.',
        );
      case 'google-timeout':
        return strings.localized(
          telugu: 'Google login ఎక్కువ సమయం తీసుకుంది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In timed out. Please try again.',
        );
      case 'google-sign-in-failed':
      case 'google-unknown-error':
      default:
        return error.message.trim().isNotEmpty
            ? error.message.trim()
            : strings.localized(
                telugu: 'Google login విఫలమైంది. మళ్లీ ప్రయత్నించండి.',
                english: 'Google Sign-In failed. Please try again.',
              );
    }
  }

  Future<void> _continueAfterAuth() async {
    await _stabilizeBottomSystemUi();
    await AppFlowService.persistLastKnownAuthUid(_service.currentUser?.uid);
    unawaited(AppRegionService.ensureRemoteSelectionSynced());
    unawaited(AppPartyPreferenceService.syncStoredSelectionToRemote());
    await AppFlowService.loadSnapshot();
    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final String nextRoute =
        await AppFlowService.resolveAuthenticatedEntryRoute();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  Future<void> _openLegalDocument(LegalDocumentType type) async {
    final String url = type == LegalDocumentType.privacyPolicy
        ? AppPublicInfo.privacyPolicyUrl
        : AppPublicInfo.termsUrl;
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      final bool openedExternally = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternally) {
        return;
      }
      final bool openedInDefaultMode = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (openedInDefaultMode) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          context.strings.localized(
            telugu: 'లీగల్ పేజీ తెరవలేకపోయాము. మళ్లీ ప్రయత్నించండి.',
            english: 'Unable to open legal page. Please try again.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _LoginUiCopy copy = _LoginUiCopy(context.currentLanguage);
    final String screenTitle = context.strings.localized(
      telugu: 'మన పోస్టర్ AI',
      english: 'Mana Poster AI',
    );
    final String screenSubtitle = context.strings.localized(
      telugu:
          'రోజువారీ పోస్టర్లు, కస్టమైజేషన్, షేర్ మరియు డౌన్‌లోడ్‌ల కోసం సురక్షితంగా కొనసాగండి.',
      english:
          'Continue securely to access daily posters, customization, sharing, and downloads.',
    );
    final String googleButtonLabel = context.strings.localized(
      telugu: 'Google తో కొనసాగండి',
      english: 'Continue with Google',
    );
    final String otherOptionsLabel = context.strings.localized(
      telugu: 'ఇతర ఎంపికలు',
      english: 'Other options',
    );
    final String skipNowLabel = context.strings.localized(
      telugu: 'ప్రస్తుతం దాటవేయండి',
      english: 'Skip now',
    );
    final String disclaimerLabel = context.strings.localized(
      telugu: 'షేర్, డౌన్‌లోడ్ వంటి కొన్ని చర్యలకు తర్వాత లాగిన్ అవసరం కావచ్చు.',
      english: 'Some actions like sharing and downloading may require login later.',
    );
    final String privacyLabel = context.strings.localized(
      telugu: 'గోప్యతా విధానం',
      english: 'Privacy Policy',
    );
    final String termsLabel = context.strings.localized(
      telugu: 'నిబంధనలు',
      english: 'Terms & Conditions',
    );
    final String andLabel = context.strings.localized(
      telugu: 'మరియు',
      english: 'and',
    );

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 88, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            screenTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            screenSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_authBootstrapping) ...<Widget>[
                            const LinearProgressIndicator(minHeight: 2),
                            const SizedBox(height: 20),
                          ],
                          FilledButton(
                            onPressed: _isBusy ? null : _continueWithGoogle,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                if (_loadingGoogle)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                else ...<Widget>[
                                  Container(
                                    width: 34,
                                    height: 34,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: const <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x1F000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/branding/google_logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    googleButtonLabel,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _isBusy
                                ? null
                                : () {
                                    setState(() {
                                      _showOtherOptions = !_showOtherOptions;
                                    });
                                  },
                            icon: Icon(
                              _showOtherOptions
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                            label: Text(
                              otherOptionsLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF0F766E),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 180),
                            crossFadeState: _showOtherOptions
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              children: <Widget>[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: _ModeChip(
                                          label: copy.signInLabel,
                                          selected: _authMode == _AuthMode.login,
                                          onTap: _isBusy
                                              ? null
                                              : () {
                                                  setState(
                                                    () => _authMode = _AuthMode.login,
                                                  );
                                                },
                                        ),
                                      ),
                                      Expanded(
                                        child: _ModeChip(
                                          label: copy.signUpLabel,
                                          selected: _authMode == _AuthMode.signup,
                                          onTap: _isBusy
                                              ? null
                                              : () {
                                                  setState(
                                                    () => _authMode = _AuthMode.signup,
                                                  );
                                                },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const <String>[AutofillHints.email],
                                  decoration: InputDecoration(
                                    hintText: copy.emailHint,
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (String? value) {
                                    if (!_showOtherOptions) {
                                      return null;
                                    }
                                    final String safeValue = (value ?? '').trim();
                                    if (safeValue.isEmpty || !safeValue.contains('@')) {
                                      return context.strings.validEmailError;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: _authMode == _AuthMode.login
                                      ? const <String>[AutofillHints.password]
                                      : const <String>[AutofillHints.newPassword],
                                  onFieldSubmitted: (_) => _continueWithEmail(),
                                  decoration: InputDecoration(
                                    hintText: copy.passwordHint,
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _showPassword = !_showPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                      ),
                                    ),
                                  ),
                                  validator: (String? value) {
                                    if (!_showOtherOptions) {
                                      return null;
                                    }
                                    final String safeValue = value ?? '';
                                    if (safeValue.trim().isEmpty) {
                                      return copy.passwordRequired;
                                    }
                                    if (safeValue.length < 6) {
                                      return context.strings.passwordError;
                                    }
                                    return null;
                                  },
                                ),
                                if (_authMode == _AuthMode.login) ...<Widget>[
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _loadingReset ? null : _sendPasswordReset,
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF0F766E),
                                      ),
                                      child: Text(copy.forgotPasswordLabel),
                                    ),
                                  ),
                                ],
                                PrimaryButton(
                                  label: _authMode == _AuthMode.login
                                      ? copy.signInLabel
                                      : copy.signUpLabel,
                                  icon: Icons.arrow_forward_rounded,
                                  loading: _loadingEmail,
                                  onPressed: _isBusy ? null : _continueWithEmail,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _isBusy ? null : _skipNow,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: const Color(0x330F172A),
                              ),
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                            child: _skipping
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(skipNowLabel),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            disclaimerLabel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
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
                                  foregroundColor: const Color(0xFF0F766E),
                                ),
                                child: Text(privacyLabel),
                              ),
                              Text(
                                andLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openLegalDocument(
                                  LegalDocumentType.termsAndConditions,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                ),
                                child: Text(termsLabel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 0,
            child: SafeArea(
              child: AppScreenBackButton(
                fallbackRouteResolver: _resolveBackRoute,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _resolveBackRoute() async {
    final bool hasRegion = await AppRegionService.hasSelection();
    final AppFlowSnapshot snapshot = await AppFlowService.loadSnapshot();
    if (!hasRegion) {
      return AppRoutes.language;
    }
    return snapshot.languageSelected
        ? AppRoutes.appLanguage
        : AppRoutes.language;
  }
}

class _LoginUiCopy {
  const _LoginUiCopy(this.language);

  final AppLanguage language;

  String _localized({required String telugu, required String english}) =>
      AppStrings(language).localized(telugu: telugu, english: english);

  String get title => _localized(
    telugu: 'Mana Poster లోకి రండి',
    english: 'Continue to Mana Poster',
  );

  String get subtitle => _localized(
    telugu: 'Google account తో వెంటనే login అవ్వండి లేదా ఇప్పటికైతే skip చేయండి.',
    english: 'Continue with Google or skip for now.',
  );

  String get otherOptionsLabel => _localized(
    telugu: 'Other options',
    english: 'Other options',
  );

  String get signInLabel => _localized(
    telugu: 'Sign in',
    english: 'Sign in',
  );

  String get signUpLabel => _localized(
    telugu: 'Sign up',
    english: 'Sign up',
  );

  String get emailHint => _localized(
    telugu: 'Email address',
    english: 'Email address',
  );

  String get passwordHint => _localized(
    telugu: 'Password',
    english: 'Password',
  );

  String get forgotPasswordLabel => _localized(
    telugu: 'Forgot password?',
    english: 'Forgot password?',
  );

  String get passwordRequired => _localized(
    telugu: 'పాస్‌వర్డ్ అవసరం',
    english: 'Password is required',
  );

  String get skipNowLabel => _localized(
    telugu: 'ఇప్పటికైతే Skip',
    english: 'Skip now',
  );

  String get disclaimer => _localized(
    telugu: 'Share, download లాంటి actions కి తర్వాత login అవసరం కావచ్చు.',
    english: 'Some actions like share and download may require login later.',
  );

  String get privacyLabel =>
      _localized(telugu: 'గోప్యతా విధానం', english: 'Privacy Policy');

  String get termsLabel =>
      _localized(telugu: 'నిబంధనలు', english: 'Terms & Conditions');

  String get andLabel => _localized(telugu: 'మరియు', english: 'and');

  String resetSent(String email) => _localized(
    telugu: '$email కి password reset mail పంపించాం.',
    english: 'Password reset email sent to $email.',
  );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? cs.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}
