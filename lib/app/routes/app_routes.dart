import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/image_editor/screens/page_setup_screen.dart';
import 'package:mana_poster/features/admin/screens/admin_auth_gate.dart';
import 'package:mana_poster/features/prehome/screens/home_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/login_screen.dart';
import 'package:mana_poster/features/prehome/screens/onboarding_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_setup_screen.dart';
import 'package:mana_poster/features/prehome/screens/permissions_screen.dart';
import 'package:mana_poster/features/prehome/screens/splash_screen.dart';
import 'package:mana_poster/features/prehome/screens/web_landing_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const permissions = '/permissions';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const pageSetup = '/page-setup';
  static const imageEditor = '/image-editor';
  static const websiteAdmin = '/website-admin';
  static const adminLogin = '/admin-login';

  static bool get isWebLandingHost {
    if (!kIsWeb) {
      return false;
    }
    final host = Uri.base.host.toLowerCase();
    return host == 'manaposter.in' ||
        host == 'www.manaposter.in' ||
        host == 'mana-poster.web.app';
  }

  static bool get isAdminWebHost {
    if (!kIsWeb) {
      return false;
    }
    final host = Uri.base.host.toLowerCase();
    return host == 'admin.manaposter.in' ||
        host == 'webapp.manaposter.in' ||
        host == 'mana-poster-admin.web.app';
  }

  static bool get isWebsiteAdminPath {
    if (!kIsWeb) {
      return false;
    }
    final path = Uri.base.path.toLowerCase();
    return path == websiteAdmin || path.startsWith('$websiteAdmin/');
  }

  static String get initialRoute {
    if (kIsWeb && (isAdminWebHost || isWebsiteAdminPath)) {
      return websiteAdmin;
    }
    return splash;
  }

  static Widget _webEntry(Widget mobileScreen) {
    if (!kIsWeb) {
      return mobileScreen;
    }
    if (isAdminWebHost || isWebsiteAdminPath) {
      return const AdminAuthGate();
    }
    if (isWebLandingHost || Uri.base.host.isNotEmpty) {
      return const WebLandingScreen();
    }
    return mobileScreen;
  }

  static final Map<String, WidgetBuilder> map = <String, WidgetBuilder>{
    splash: (_) => _webEntry(const SplashScreen()),
    language: (_) => _webEntry(const LanguageSelectionScreen()),
    onboarding: (_) => _webEntry(const OnboardingScreen()),
    login: (_) => _webEntry(const LoginScreen()),
    permissions: (_) => _webEntry(const PermissionsScreen()),
    profileSetup: (_) => _webEntry(const ProfileSetupScreen()),
    home: (_) => _webEntry(const HomeScreen()),
    pageSetup: (_) => _webEntry(const PageSetupScreen()),
    imageEditor: (_) => _webEntry(const ImageEditorScreen()),
    websiteAdmin: (_) => const AdminAuthGate(),
    adminLogin: (_) => const AdminAuthGate(),
  };
}
