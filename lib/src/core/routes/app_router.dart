import 'package:go_router/go_router.dart';
import 'package:mana_poster/src/core/constants/app_routes.dart';
import 'package:mana_poster/src/features/auth/login_page.dart';
import 'package:mana_poster/src/features/home/home_page.dart';
import 'package:mana_poster/src/features/permissions/permissions_page.dart';
import 'package:mana_poster/src/features/profile/profile_page.dart';
import 'package:mana_poster/src/features/splash/splash_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: <GoRoute>[
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.permissions,
      builder: (context, state) => const PermissionsPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);
