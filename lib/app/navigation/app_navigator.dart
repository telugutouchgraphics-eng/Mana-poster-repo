import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static const Set<String> _supportedRoutes = <String>{
    AppRoutes.home,
    AppRoutes.pageSetup,
    AppRoutes.imageEditor,
    AppRoutes.login,
    AppRoutes.religion,
    AppRoutes.politicalParties,
    AppRoutes.profileSetup,
    AppRoutes.language,
    AppRoutes.appLanguage,
    AppRoutes.notificationUnavailable,
  };

  static void openHome() {
    final NavigatorState? state = navigatorKey.currentState;
    if (state == null) {
      return;
    }
    unawaited(_openResolvedHome(state));
  }

  static Future<void> _openResolvedHome(NavigatorState state) async {
    final route = await AppFlowService.resolveAuthenticatedEntryRoute();
    state.pushNamedAndRemoveUntil(route, (Route<dynamic> route) => false);
  }

  static void openNotificationRoute(
    String route, {
    Object? arguments,
    String fallbackRoute = AppRoutes.home,
  }) {
    final NavigatorState? state = navigatorKey.currentState;
    if (state == null) {
      return;
    }
    final String normalized = route.trim();
    final bool isDynamicNotificationRoute = _looksLikeDynamicNotificationRoute(
      normalized,
    );
    final String targetRoute =
        _supportedRoutes.contains(normalized) || isDynamicNotificationRoute
        ? normalized
        : fallbackRoute;
    state.pushNamedAndRemoveUntil(
      targetRoute,
      (Route<dynamic> existing) => false,
      arguments: arguments,
    );
  }

  static bool _looksLikeDynamicNotificationRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) {
      return false;
    }
    final segments = uri.pathSegments;
    if (segments.length != 2) {
      return false;
    }
    return <String>{
      'poster',
      'category',
      'editor',
      'offer',
      'event',
    }.contains(segments.first.trim().toLowerCase());
  }
}
