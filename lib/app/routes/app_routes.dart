import 'package:flutter/material.dart';

import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/prehome/screens/home_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/login_screen.dart';
import 'package:mana_poster/features/prehome/screens/onboarding_screen.dart';
import 'package:mana_poster/features/prehome/screens/permissions_screen.dart';
import 'package:mana_poster/features/prehome/screens/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const permissions = '/permissions';
  static const home = '/home';
  static const imageEditor = '/image-editor';
  static final Map<String, WidgetBuilder> map = <String, WidgetBuilder>{
    splash: (_) => const SplashScreen(),
    language: (_) => const LanguageSelectionScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    permissions: (_) => const PermissionsScreen(),
    home: (_) => const HomeScreen(),
    imageEditor: (_) => const ImageEditorScreen(),
  };
}
