import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/onboarding_audio_service.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = FirebaseAuthService();
  final OnboardingAudioService _onboardingAudio = OnboardingAudioService();
  final _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.login;
  bool _authBootstrapping = !FirebaseBootstrap.hasFirebaseApp;
  bool _loadingGoogle = false;
  bool _loadingEmail = false;
  bool _loadingReset = false;
  bool _showPassword = false;
  bool _autoPlayedGuide = false;

  bool get _isBusy =>
      _authBootstrapping || _loadingGoogle || _loadingEmail || _loadingReset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stabilizeBottomSystemUi();
    unawaited(_prepareAuthDependencies());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    unawaited(_onboardingAudio.dispose());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoPlayedGuide) {
      return;
    }
    _autoPlayedGuide = true;
    unawaited(
      _onboardingAudio.autoplayIfSupported(
        language: context.currentLanguage,
        cue: OnboardingAudioCue.login,
      ),
    );
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
      overlays: const <SystemUiOverlay>[SystemUiOverlay.top],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 180), () async {
          if (!mounted) {
            return;
          }
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: const <SystemUiOverlay>[SystemUiOverlay.top],
          );
        }),
      );
    });
  }

  Future<void> _continueWithGoogle() async {
    if (_loadingEmail || _loadingReset) {
      return;
    }
    setState(() => _loadingGoogle = true);
    try {
      final authResult = await _service.signInWithGoogle();
      await _stabilizeBottomSystemUi();
      await _showFirst150TrialDialogIfNeeded(authResult);
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
        final authResult = await _service.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await _showFirst150TrialDialogIfNeeded(authResult);
      } else {
        final authResult = await _service.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await _showFirst150TrialDialogIfNeeded(authResult);
      }
      await _stabilizeBottomSystemUi();
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
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  void _showSuccess(String message) {
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
      builder: (context) {
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
      case 'email-already-in-use-google':
        return strings.localized(
          telugu:
              'ఈ ఇమెయిల్ ఇప్పటికే Google login తో ఉంది. Google తోనే continue చేయండి.',
          english:
              'This email is already linked to Google Sign-In. Continue with Google.',
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
      case 'use-google-for-this-email':
        return strings.localized(
          telugu:
              'ఈ ఇమెయిల్ Google login తో register అయ్యింది. Google తోనే continue చేయండి.',
          english:
              'This email is registered with Google Sign-In. Continue with Google.',
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
      case 'google-timeout':
        return strings.localized(
          telugu:
              'Google login ఎక్కువ సమయం తీసుకుంటోంది. ఇంటర్నెట్, Google Play Services చెక్ చేసి మళ్లీ ప్రయత్నించండి.',
          english:
              'Google Sign-In is taking too long. Check internet and Google Play Services, then try again.',
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
    await _stabilizeBottomSystemUi();
    await AppFlowService.persistLastKnownAuthUid(_service.currentUser?.uid);
    await AppFlowService.loadSnapshot();
    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final String nextRoute =
        await AppFlowService.resolveAuthenticatedEntryRoute();
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
    final url = type == LegalDocumentType.privacyPolicy
        ? AppPublicInfo.privacyPolicyUrl
        : AppPublicInfo.termsUrl;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final openedExternally = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternally) {
        return;
      }
      final openedInDefaultMode = await launchUrl(
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
    final strings = context.strings;
    final isLogin = _mode == _AuthMode.login;
    final authCopy = _AuthUiCopy(context.currentLanguage);
    final cs = Theme.of(context).colorScheme;
    final showGuideAudio = context.currentLanguage == AppLanguage.telugu;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x120F172A),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      Color(0xFF14B8A6),
                                      Color(0xFF38BDF8),
                                      Color(0xFFA78BFA),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                isLogin
                                    ? strings.loginLabel
                                    : strings.signUpLabel,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authCopy.formSubtitle(isLogin),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12.5,
                                ),
                              ),
                              if (showGuideAudio) ...<Widget>[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      unawaited(
                                        _onboardingAudio.replayIfSupported(
                                          language: context.currentLanguage,
                                          cue: OnboardingAudioCue.login,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.volume_up_rounded),
                                    label: Text(
                                      strings.localized(
                                        telugu: 'వాయిస్ గైడ్ మళ్లీ వినండి',
                                        english: 'Replay voice guide',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _ModeChip(
                                        label: strings.loginLabel,
                                        selected: isLogin,
                                        onTap: _isBusy
                                            ? null
                                            : () {
                                                FocusScope.of(
                                                  context,
                                                ).unfocus();
                                                setState(
                                                  () => _mode = _AuthMode.login,
                                                );
                                              },
                                      ),
                                    ),
                                    Expanded(
                                      child: _ModeChip(
                                        label: strings.signUpLabel,
                                        selected: !isLogin,
                                        onTap: _isBusy
                                            ? null
                                            : () {
                                                FocusScope.of(
                                                  context,
                                                ).unfocus();
                                                setState(
                                                  () =>
                                                      _mode = _AuthMode.signup,
                                                );
                                              },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const <String>[
                                  AutofillHints.email,
                                ],
                                decoration: InputDecoration(
                                  hintText: strings.emailAddress,
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
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
                                keyboardType: TextInputType.visiblePassword,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: isLogin
                                    ? const <String>[AutofillHints.password]
                                    : const <String>[AutofillHints.newPassword],
                                onFieldSubmitted: (_) => _continueWithEmail(),
                                decoration: InputDecoration(
                                  hintText: strings.password,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
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
                              if (isLogin) ...<Widget>[
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _loadingReset
                                        ? null
                                        : _onForgotPassword,
                                    child: Text(strings.forgotPassword),
                                  ),
                                ),
                              ],
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
                              if (_authBootstrapping) ...<Widget>[
                                const SizedBox(height: 6),
                                const LinearProgressIndicator(minHeight: 2),
                                const SizedBox(height: 10),
                              ],
                              PrimaryButton(
                                label: isLogin
                                    ? strings.loginLabel
                                    : strings.signUpLabel,
                                icon: Icons.arrow_forward_rounded,
                                loading: _loadingEmail,
                                onPressed: _continueWithEmail,
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _isBusy ? null : _continueWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
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
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 2,
                                children: <Widget>[
                                  TextButton(
                                    onPressed: () => _openLegalDocument(
                                      LegalDocumentType.privacyPolicy,
                                    ),
                                    child: Text(authCopy.privacyLabel),
                                  ),
                                  Text(
                                    authCopy.andLabel,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _openLegalDocument(
                                      LegalDocumentType.termsAndConditions,
                                    ),
                                    child: Text(authCopy.termsLabel),
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
    final hasRegion = await AppRegionService.hasSelection();
    return hasRegion ? AppRoutes.politicalParties : AppRoutes.language;
  }
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: <Color>[Color(0xFF14B8A6), Color(0xFF0EA5E9)],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AuthUiCopy {
  const _AuthUiCopy(this.language);

  final AppLanguage language;

  String get passwordRequired => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'పాస్‌వర్డ్ అవసరం',
    SupportedUiLanguage.hindi => 'पासवर्ड आवश्यक है',
    SupportedUiLanguage.english => 'Password is required',
    SupportedUiLanguage.tamil => 'கடவுச்சொல் அவசியம்',
    SupportedUiLanguage.kannada => 'ಪಾಸ್‌ವರ್ಡ್ ಅಗತ್ಯವಿದೆ',
    SupportedUiLanguage.malayalam => 'പാസ്‌വേഡ് ആവശ്യമാണ്',
  };

  String formSubtitle(bool isLogin) => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      isLogin ? 'Continue with your account' : 'Create account',
    SupportedUiLanguage.hindi => isLogin ? 'जारी रखें' : 'खाता बनाएँ',
    SupportedUiLanguage.english =>
      isLogin ? 'Continue with your account' : 'Create account',
    SupportedUiLanguage.tamil => isLogin ? 'தொடரவும்' : 'கணக்கு உருவாக்கவும்',
    SupportedUiLanguage.kannada => isLogin ? 'ಮುಂದುವರಿಸಿ' : 'ಖಾತೆ ರಚಿಸಿ',
    SupportedUiLanguage.malayalam =>
      isLogin ? 'തുടരുക' : 'അക്കൗണ്ട് സൃഷ്ടിക്കുക',
  };

  String resetSuccess(String email) => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      '$email కి పాస్‌వర్డ్ రీసెట్ మెయిల్ పంపించాం.',
    SupportedUiLanguage.hindi => '$email पर पासवर्ड रीसेट मेल भेज दिया गया है।',
    SupportedUiLanguage.english => 'Password reset email sent to $email.',
    SupportedUiLanguage.tamil =>
      '$email க்கு கடவுச்சொல் ரீசெட் மெயில் அனுப்பப்பட்டது.',
    SupportedUiLanguage.kannada =>
      '$email ಗೆ ಪಾಸ್‌ವರ್ಡ್ ರೀಸೆಟ್ ಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ.',
    SupportedUiLanguage.malayalam =>
      '$email ലേക്ക് പാസ്‌വേഡ് റീസെറ്റ് മെയിൽ അയച്ചു.',
  };

  String get legalIntro => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      'కొనసాగించడం ద్వారా మీరు మా గోప్యతా విధానం మరియు నిబంధనలకు అంగీకరిస్తారు.',
    SupportedUiLanguage.hindi =>
      'जारी रखने पर आप हमारी प्राइवेसी पॉलिसी और नियम एवं शर्तों से सहमत होते हैं।',
    SupportedUiLanguage.english =>
      'By continuing, you agree to our Privacy Policy and Terms & Conditions.',
    SupportedUiLanguage.tamil =>
      'தொடருவதன் மூலம் எங்கள் தனியுரிமைக் கொள்கை மற்றும் விதிமுறைகளுக்கு நீங்கள் ஒப்புக்கொள்கிறீர்கள்.',
    SupportedUiLanguage.kannada =>
      'ಮುಂದುವರಿದರೆ ನಮ್ಮ ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ನಿಯಮಗಳು ಹಾಗೂ ಷರತ್ತುಗಳಿಗೆ ನೀವು ಒಪ್ಪುತ್ತೀರಿ.',
    SupportedUiLanguage.malayalam =>
      'തുടരുന്നതിലൂടെ ഞങ്ങളുടെ സ്വകാര്യതാ നയംയും നിബന്ധനകളും നിങ്ങൾ അംഗീകരിക്കുന്നു.',
  };

  String get privacyLabel => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'గోప్యతా విధానం',
    SupportedUiLanguage.hindi => 'प्राइवेसी पॉलिसी',
    SupportedUiLanguage.english => 'Privacy Policy',
    SupportedUiLanguage.tamil => 'தனியுரிமைக் கொள்கை',
    SupportedUiLanguage.kannada => 'ಗೌಪ್ಯತಾ ನೀತಿ',
    SupportedUiLanguage.malayalam => 'സ്വകാര്യതാ നയം',
  };

  String get andLabel => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'మరియు',
    SupportedUiLanguage.hindi => 'और',
    SupportedUiLanguage.english => 'and',
    SupportedUiLanguage.tamil => 'மற்றும்',
    SupportedUiLanguage.kannada => 'ಮತ್ತು',
    SupportedUiLanguage.malayalam => 'കൂടാതെ',
  };

  String get termsLabel => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'నిబంధనలు',
    SupportedUiLanguage.hindi => 'नियम एवं शर्तें',
    SupportedUiLanguage.english => 'Terms & Conditions',
    SupportedUiLanguage.tamil => 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
    SupportedUiLanguage.kannada => 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
    SupportedUiLanguage.malayalam => 'നിബന്ധനകളും വ്യവസ്ഥകളും',
  };

  String passwordVisibilityTooltip(bool isVisible) =>
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          isVisible ? 'పాస్‌వర్డ్ దాచు' : 'పాస్‌వర్డ్ చూపు',
        SupportedUiLanguage.hindi =>
          isVisible ? 'पासवर्ड छिपाएँ' : 'पासवर्ड दिखाएँ',
        SupportedUiLanguage.english =>
          isVisible ? 'Hide password' : 'Show password',
        SupportedUiLanguage.tamil =>
          isVisible ? 'கடவுச்சொல்லை மறை' : 'கடவுச்சொல்லை காட்டு',
        SupportedUiLanguage.kannada =>
          isVisible ? 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆಮಾಡಿ' : 'ಪಾಸ್‌ವರ್ಡ್ ತೋರಿಸಿ',
        SupportedUiLanguage.malayalam =>
          isVisible ? 'പാസ്‌വേഡ് മറയ്ക്കുക' : 'പാസ്‌വേഡ് കാണിക്കുക',
      };
}
