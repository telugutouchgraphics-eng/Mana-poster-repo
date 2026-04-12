import 'package:flutter/material.dart';

import 'package:mana_poster/app/routes/app_routes.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void openHome() {
    final NavigatorState? state = navigatorKey.currentState;
    if (state == null) {
      return;
    }
    state.pushNamedAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
  }
}
