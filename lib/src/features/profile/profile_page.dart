import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana_poster/src/core/localization/app_language.dart';
import 'package:mana_poster/src/core/localization/app_strings.dart';
import 'package:mana_poster/src/core/localization/localization_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localizationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.text(language, AppStrings.profileTitle),
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.text(language, AppStrings.profileUserInfo),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text('Name: Demo User'),
                const SizedBox(height: 6),
                const Text('Email: demo@manaposter.app'),
                const SizedBox(height: 6),
                const Text('Plan: Free'),
                const SizedBox(height: 16),
                Text(
                  AppStrings.text(language, AppStrings.profileLanguage),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AppLanguage>(
                  initialValue: language,
                  items: AppLanguage.values
                      .map(
                        (AppLanguage value) => DropdownMenuItem<AppLanguage>(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (AppLanguage? value) {
                    if (value == null) {
                      return;
                    }
                    ref
                        .read(localizationControllerProvider.notifier)
                        .setLanguage(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
