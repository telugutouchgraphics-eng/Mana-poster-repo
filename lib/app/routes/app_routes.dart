import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:mana_poster/features/image_editor/screens/image_editor_screen_web.dart'
    if (dart.library.io)
        'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/image_editor/screens/page_setup_screen.dart';
import 'package:mana_poster/features/prehome/screens/home_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/login_screen.dart';
import 'package:mana_poster/features/prehome/screens/notification_unavailable_screen.dart';
import 'package:mana_poster/features/prehome/screens/onboarding_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_setup_screen.dart';
import 'package:mana_poster/features/prehome/screens/permissions_screen.dart';
import 'package:mana_poster/features/prehome/screens/splash_screen.dart';
import 'package:mana_poster/features/prehome/screens/web_reset_screen.dart';

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
  static const notificationUnavailable = '/notification-unavailable';

  static String poster(String id) => '/poster/$id';
  static String category(String id) => '/category/$id';
  static String editor(String id) => '/editor/$id';
  static String offer(String id) => '/offer/$id';
  static String event(String id) => '/event/$id';

  static String get initialRoute => splash;

  static Widget _webEntry(Widget mobileScreen) {
    if (!kIsWeb) {
      return mobileScreen;
    }
    return const WebResetScreen();
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
    notificationUnavailable: (_) => _webEntry(const NotificationUnavailableScreen()),
  };

  static Route<dynamic>? resolveDynamicRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final uri = Uri.tryParse(name);
    if (uri == null) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length != 2) {
      return null;
    }
    final kind = segments[0].trim().toLowerCase();
    final id = segments[1].trim();
    final rawArgs = settings.arguments;
    final payload = rawArgs is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};

    Widget? screen;
    switch (kind) {
      case 'category':
        screen = _webEntry(
          HomeScreen(
            initialCategorySlug: id,
            initialNotificationPayload: payload,
          ),
        );
        break;
      case 'event':
        screen = _webEntry(
          HomeScreen(
            initialCategorySlug: id,
            initialNotificationPayload: payload,
          ),
        );
        break;
      case 'offer':
      case 'poster':
        screen = _webEntry(
          HomeScreen(
            initialNotificationPayload: payload..putIfAbsent('id', () => id),
          ),
        );
        break;
      case 'editor':
        if (id.isEmpty) {
          screen = _webEntry(const NotificationUnavailableScreen());
        } else {
          screen = _webEntry(ImageEditorScreen(templateDocumentSource: id));
        }
        break;
      default:
        screen = _webEntry(const NotificationUnavailableScreen());
    }

    return MaterialPageRoute<void>(
      builder: (_) => screen!,
      settings: settings,
    );
  }
}
