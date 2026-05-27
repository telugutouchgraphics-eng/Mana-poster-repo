import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/language_selection_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with AppLanguageStateMixin {
  static const Duration _minimumSplashDuration = Duration.zero;
  late final DateTime _startedAt;
  Timer? _navigationTimer;
  String _nextRoute = AppRoutes.language;

  void _startupLog(String message) {
    developer.log(message, name: 'splash.startup.trace');
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) {
          return;
        }
        await _prepareNextRoute();
      }());
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _goToNextScreen() {
    if (!mounted) {
      return;
    }

    final builder = AppRoutes.map[_nextRoute];
    if (builder != null) {
      Navigator.of(context).pushReplacement(
        _buildImmediateRoute(builder(context), routeName: _nextRoute),
      );
    } else if (_nextRoute == AppRoutes.language) {
      Navigator.of(context).pushReplacement(
        _buildImmediateRoute(
          const LanguageSelectionScreen(),
          routeName: AppRoutes.language,
        ),
      );
    } else {
      Navigator.of(context).pushReplacementNamed(_nextRoute);
    }
  }

  Future<void> _prepareNextRoute() async {
    try {
      unawaited(
        FirebaseBootstrap.ensureInitialized(activateAppCheck: false),
      );
      SharedPreferences? startupPrefs;
      try {
        startupPrefs = await SharedPreferences.getInstance();
      } catch (_) {}
      final snapshot = await AppFlowService.loadSnapshot(prefs: startupPrefs);
      _startupLog(
        'snapshot languageSelected=${snapshot.languageSelected}'
        ' permissionsHandled=${snapshot.permissionsStepHandled}'
        ' initialSetupCompleted=${snapshot.initialSetupCompleted}'
        ' language=${snapshot.language.name}',
      );
      final String? storedAuthUid = await AppFlowService.loadLastKnownAuthUid(
        prefs: startupPrefs,
      );
      if (!snapshot.languageSelected) {
        if (!mounted) {
          return;
        }
        _nextRoute = AppRoutes.language;
        _startupLog('final_route_decision nextRoute=$_nextRoute');
        return;
      }

      final String cachedAuthUid = storedAuthUid?.trim() ?? '';
      User? startupUser;
      if (cachedAuthUid.isEmpty && FirebaseBootstrap.hasFirebaseApp) {
        try {
          startupUser = await _resolveStartupUser();
        } catch (_) {
          startupUser = null;
        }
      }
      if (startupUser?.uid.trim().isNotEmpty == true) {
        unawaited(AppFlowService.persistLastKnownAuthUid(startupUser!.uid));
      }
      final String effectiveAuthUid = startupUser?.uid.trim().isNotEmpty == true
          ? startupUser!.uid.trim()
          : cachedAuthUid;
      final bool isAuthenticated = effectiveAuthUid.isNotEmpty;
      _startupLog(
        'startup_user uid=${startupUser?.uid ?? 'null'}'
        ' email=${startupUser?.email ?? 'null'}'
        ' storedUid=${storedAuthUid ?? 'null'}',
      );
      String nextRoute;
      if (!isAuthenticated) {
        nextRoute = AppRoutes.login;
      } else {
        final Future<String> startupEntryRouteFuture =
            AppFlowService.resolveAuthenticatedEntryRouteForStartup(
              includeReligionGate: true,
              startupUidHint: effectiveAuthUid,
              allowRemoteProfileRefresh: false,
              prefs: startupPrefs,
            );
        final authenticatedEntryRoute = await startupEntryRouteFuture;
        nextRoute = authenticatedEntryRoute;
        unawaited(
          AppFlowService.syncInitialSetupCompletion(
            isAuthenticated: isAuthenticated,
          ).timeout(const Duration(seconds: 2), onTimeout: () {}),
        );
        _startupLog(
          'pre_profile_route_decision nextRoute=$nextRoute'
          ' isAuthenticated=$isAuthenticated'
          ' permissionsHandled=deferred',
        );
      }
      if (!isAuthenticated) {
        _startupLog(
          'pre_profile_route_decision nextRoute=$nextRoute'
          ' isAuthenticated=$isAuthenticated'
          ' permissionsHandled=deferred',
        );
      }
      if (!mounted) {
        return;
      }
      _nextRoute = nextRoute;
      _startupLog('final_route_decision nextRoute=$_nextRoute');
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

  Future<User?> _resolveStartupUser() async {
    try {
      if (!FirebaseBootstrap.hasFirebaseApp) {
        _startupLog('resolve_startup_user firebase_not_ready');
        return null;
      }
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      _startupLog('currentUser_at_startup uid=${currentUser?.uid ?? 'null'}');
      return currentUser;
    } on Exception {
      return null;
    }
  }

  PageRouteBuilder<void> _buildImmediateRoute(
    Widget child, {
    required String routeName,
  }) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: routeName),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFFF8FAFF), child: SizedBox.expand());
  }
}
