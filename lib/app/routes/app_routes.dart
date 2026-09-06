import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:mana_poster/app/startup/post_splash_startup_gate.dart';
import 'package:mana_poster/features/prehome/screens/digital_visiting_card_screen.dart';
import 'package:mana_poster/features/prehome/screens/home_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/login_screen.dart';
import 'package:mana_poster/features/prehome/screens/notification_unavailable_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_setup_screen.dart';
import 'package:mana_poster/features/prehome/screens/region_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/religion_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/splash_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/screens/web_reset_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const appLanguage = '/app-language';
  static const politicalParties = '/political-parties';
  static const login = '/login';
  static const permissions = '/permissions';
  static const religion = '/religion';
  static const profileSetup = '/profile-setup';
  static const digitalVisitingCard = '/digital-visiting-card';
  static const home = '/home';
  static const pageSetup = '/page-setup';
  static const imageEditor = '/image-editor';
  static const notificationUnavailable = '/notification-unavailable';
  static const subscription = '/subscription';

  static String poster(String id) => '/poster/$id';
  static String category(String id) => '/category/$id';
  static String offer(String id) => '/offer/$id';
  static String event(String id) => '/event/$id';

  static String get initialRoute => splash;

  static Widget _webEntry(Widget mobileScreen) {
    if (!kIsWeb) {
      return mobileScreen;
    }
    return const WebResetScreen();
  }

  static Widget _readyEntry(Widget mobileScreen) {
    return _webEntry(PostSplashStartupReadyMarker(child: mobileScreen));
  }

  static Widget startupScreenFor(String routeName) {
    switch (routeName) {
      case language:
        return _readyEntry(const RegionSelectionScreen());
      case appLanguage:
        return _readyEntry(const LanguageSettingsScreen(onboardingMode: true));
      case login:
        return _readyEntry(const LoginScreen());
      case home:
        return _readyEntry(const HomeScreen());
      case subscription:
        return _readyEntry(const SubscriptionPlanScreen());
      default:
        return _readyEntry(const RegionSelectionScreen());
    }
  }

  static final Map<String, WidgetBuilder> map = <String, WidgetBuilder>{
    splash: (_) => _webEntry(const SplashScreen()),
    language: (_) => _readyEntry(const RegionSelectionScreen()),
    appLanguage: (_) =>
        _readyEntry(const LanguageSettingsScreen(onboardingMode: true)),
    login: (_) => _readyEntry(const LoginScreen()),
    religion: (_) => _readyEntry(const ReligionSelectionScreen()),
    profileSetup: (_) => _readyEntry(const ProfileSetupScreen()),
    digitalVisitingCard: (_) =>
        _readyEntry(const DigitalVisitingCardScreen()),
    home: (_) => _readyEntry(const HomeScreen()),
    pageSetup: (_) => _readyEntry(const NotificationUnavailableScreen()),
    imageEditor: (_) => _readyEntry(const NotificationUnavailableScreen()),
    notificationUnavailable: (_) =>
        _readyEntry(const NotificationUnavailableScreen()),
    subscription: (_) => _readyEntry(const SubscriptionPlanScreen()),
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
        screen = _readyEntry(
          HomeScreen(
            initialCategorySlug: id,
            initialNotificationPayload: payload,
          ),
        );
        break;
      case 'event':
        screen = _readyEntry(
          HomeScreen(
            initialCategorySlug: id,
            initialNotificationPayload: payload,
          ),
        );
        break;
      case 'offer':
      case 'poster':
        screen = _readyEntry(
          HomeScreen(
            initialNotificationPayload: payload..putIfAbsent('id', () => id),
          ),
        );
        break;
      case 'editor':
        screen = _readyEntry(const NotificationUnavailableScreen());
        break;
      case 'subscription':
      case 'plan':
      case 'paywall':
        screen = _readyEntry(const SubscriptionPlanScreen());
        break;
      default:
        screen = _readyEntry(const NotificationUnavailableScreen());
    }

    return MaterialPageRoute<void>(builder: (_) => screen!, settings: settings);
  }
}
