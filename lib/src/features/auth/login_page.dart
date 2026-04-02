import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mana_poster/src/core/constants/app_routes.dart';
import 'package:mana_poster/src/core/localization/app_strings.dart';
import 'package:mana_poster/src/core/localization/localization_controller.dart';
import 'package:mana_poster/src/core/session/session_controller.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localizationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.text(language, AppStrings.loginTitle))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(AppStrings.text(language, AppStrings.loginTitle)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(sessionControllerProvider.notifier).markAuthenticated(true);
                  context.go(AppRoutes.permissions);
                },
                child: Text(AppStrings.text(language, AppStrings.loginContinue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
