import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mana_poster/src/core/constants/app_routes.dart';
import 'package:mana_poster/src/core/localization/app_strings.dart';
import 'package:mana_poster/src/core/localization/localization_controller.dart';
import 'package:mana_poster/src/core/session/session_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final session = ref.read(sessionControllerProvider);
        if (session.isAuthenticated && session.hasCompletedPermissions) {
          context.go(AppRoutes.home);
          return;
        }
        if (session.isAuthenticated) {
          context.go(AppRoutes.permissions);
          return;
        }
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(localizationControllerProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.auto_awesome, size: 48),
            const SizedBox(height: 12),
            Text(
              AppStrings.text(language, AppStrings.splashTitle),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.text(language, AppStrings.splashSubtitle)),
          ],
        ),
      ),
    );
  }
}
