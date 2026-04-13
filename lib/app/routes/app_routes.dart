import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/prehome/screens/home_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/login_screen.dart';
import 'package:mana_poster/features/prehome/screens/onboarding_screen.dart';
import 'package:mana_poster/features/prehome/screens/permissions_screen.dart';
import 'package:mana_poster/features/prehome/screens/splash_screen.dart';
import 'package:mana_poster/features/prehome/screens/web_landing_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const webLanding = '/web';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const permissions = '/permissions';
  static const home = '/home';
  static const imageEditor = '/image-editor';

  static Widget _webEntry(Widget mobileScreen) {
    return kIsWeb ? const WebLandingScreen() : mobileScreen;
  }

  static final Map<String, WidgetBuilder> map = <String, WidgetBuilder>{
    splash: (_) => _webEntry(const SplashScreen()),
    webLanding: (_) => const WebLandingScreen(),
    language: (_) => _webEntry(const LanguageSelectionScreen()),
    onboarding: (_) => _webEntry(const OnboardingScreen()),
    login: (_) => _webEntry(const LoginScreen()),
    permissions: (_) => _webEntry(const PermissionsScreen()),
    home: (_) => _webEntry(const HomeScreen()),
    imageEditor: (_) => _webEntry(const ImageEditorScreen()),
  };
}
