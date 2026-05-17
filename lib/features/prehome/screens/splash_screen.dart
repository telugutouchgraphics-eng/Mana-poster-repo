import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/language_selection_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin, AppLanguageStateMixin {
  static const Duration _minimumSplashDuration = Duration(seconds: 3);
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final DateTime _startedAt;
  Timer? _navigationTimer;
  String _nextRoute = AppRoutes.language;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    unawaited(_prepareNextRoute());
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _goToNextScreen() {
    if (!mounted) {
      return;
    }

    if (_nextRoute == AppRoutes.language) {
      Navigator.of(
        context,
      ).pushReplacement(_buildTransitionRoute(const LanguageSelectionScreen()));
      return;
    }

    Navigator.of(context).pushReplacementNamed(_nextRoute);
  }

  Future<void> _prepareNextRoute() async {
    try {
      final snapshot = await AppFlowService.loadSnapshot().timeout(
        const Duration(seconds: 2),
      );
      final bool isAuthenticated = _hasAuthenticatedUser();
      final bool permissionsHandled =
          await AppFlowService.resolvePermissionsStepHandled().timeout(
            const Duration(seconds: 2),
          );
      String nextRoute;
      if (!snapshot.languageSelected) {
        nextRoute = AppRoutes.language;
      } else if (!isAuthenticated) {
        nextRoute = AppRoutes.login;
      } else if (!permissionsHandled) {
        nextRoute = AppRoutes.permissions;
      } else {
        nextRoute = AppRoutes.home;
      }
      await AppFlowService.syncInitialSetupCompletion(
        isAuthenticated: isAuthenticated,
      ).timeout(const Duration(seconds: 2));
      if (nextRoute == AppRoutes.home) {
        nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute()
            .timeout(const Duration(seconds: 2));
      }
      if (!mounted) {
        return;
      }
      _nextRoute = nextRoute;
    } catch (error, stackTrace) {
      developer.log(
        'Splash route preparation failed. Falling back to language screen.',
        name: 'splash.startup',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      _nextRoute = AppRoutes.language;
    } finally {
      if (mounted) {
        _navigationTimer?.cancel();
        final elapsed = DateTime.now().difference(_startedAt);
        final remaining = elapsed >= _minimumSplashDuration
            ? Duration.zero
            : _minimumSplashDuration - elapsed;
        _navigationTimer = Timer(remaining, _goToNextScreen);
      }
    }
  }

  bool _hasAuthenticatedUser() {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } on Exception {
      return false;
    }
  }

  PageRouteBuilder<void> _buildTransitionRoute(Widget child) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<Offset> offsetAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(color: cs.surface)),
            ),
            SafeArea(
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: <Widget>[
                      const Spacer(),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.all(9),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/branding/mana_poster_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppPublicInfo.appName,
                                style: TextStyle(
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppPublicInfo.appTagline,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: <Widget>[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.strings.localized(
                              telugu: 'లోడ్ అవుతోంది...',
                              english: 'Loading...',
                              hindi: 'लोड हो रहा है...',
                              tamil: 'ஏற்றப்படுகிறது...',
                              kannada: 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
                              malayalam: 'ലോഡ് ചെയ്യുന്നു...',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
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
    );
  }
}
