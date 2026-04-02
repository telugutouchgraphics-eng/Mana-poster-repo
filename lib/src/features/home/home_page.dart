import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mana_poster/src/core/constants/app_routes.dart';
import 'package:mana_poster/src/core/localization/app_language.dart';
import 'package:mana_poster/src/core/localization/app_strings.dart';
import 'package:mana_poster/src/core/localization/localization_controller.dart';
import 'package:mana_poster/src/features/home/domain/models/home_category.dart';
import 'package:mana_poster/src/features/home/domain/models/home_template.dart';
import 'package:mana_poster/src/features/home/presentation/providers/home_feed_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localizationControllerProvider);
    final homeFeed = ref.watch(homeFeedProvider);
    final localeCode = language.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.text(language, AppStrings.homeTitle),
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _SectionCard(
            title: AppStrings.text(language, AppStrings.homeHeaderTitle),
            content: AppStrings.text(language, AppStrings.homeHeaderSubtitle),
          ),
          SizedBox(height: 12),
          _SectionCard(
            title: AppStrings.text(language, AppStrings.homeCategoriesTitle),
            content: homeFeed.categories
                .map((HomeCategory category) =>
                    category.labels[localeCode] ?? category.labels['en'] ?? '')
                .join(', '),
          ),
          SizedBox(height: 12),
          _SectionCard(
            title: AppStrings.text(language, AppStrings.homeTemplatesTitle),
            content: homeFeed.templates
                .map((HomeTemplate template) => template.isPremium
                    ? '${template.title} (${template.priceLabel ?? 'Premium'})'
                    : template.title)
                .join(' | '),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
