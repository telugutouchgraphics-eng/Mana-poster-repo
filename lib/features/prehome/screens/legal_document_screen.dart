import 'package:flutter/material.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';

enum LegalDocumentType { privacyPolicy, termsAndConditions }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.documentType});

  final LegalDocumentType documentType;

  @override
  Widget build(BuildContext context) {
    final copy = _LegalCopy(context.strings, documentType);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          copy.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: GradientShell(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      copy.badge,
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.lastUpdated,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...copy.sections.map((section) => _SectionCard(section: section)),
            const SizedBox(height: 8),
            Text(
              copy.footer,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

class _LegalCopy {
  const _LegalCopy(this.strings, this.documentType);

  final AppStrings strings;
  final LegalDocumentType documentType;

  bool get _isPrivacy => documentType == LegalDocumentType.privacyPolicy;

  String get title => _isPrivacy
      ? strings.localized(
          telugu:
              'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Ë†Ã Â°ÂµÃ Â°Â¸Ã Â±â‚¬ Ã Â°ÂªÃ Â°Â¾Ã Â°Â²Ã Â°Â¸Ã Â±â‚¬',
          english: 'Privacy Policy',
          hindi:
              'Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤â€¡Ã Â¤ÂµÃ Â¥â€¡Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤ÂªÃ Â¥â€°Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â¸Ã Â¥â‚¬',
          tamil:
              'Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®Â¯Ã Â¯ÂÃ Â®Â°Ã Â®Â¿Ã Â®Â®Ã Â¯Ë† Ã Â®â€¢Ã Â¯Å Ã Â®Â³Ã Â¯ÂÃ Â®â€¢Ã Â¯Ë†',
          kannada:
              'Ã Â²â€”Ã Â³Å’Ã Â²ÂªÃ Â³ÂÃ Â²Â¯Ã Â²Â¤Ã Â²Â¾ Ã Â²Â¨Ã Â³â‚¬Ã Â²Â¤Ã Â²Â¿',
          malayalam:
              'Ã Â´Â¸Ã ÂµÂÃ Â´ÂµÃ Â´â€¢Ã Â´Â¾Ã Â´Â°Ã ÂµÂÃ Â´Â¯Ã Â´Â¤Ã Â´Â¾ Ã Â´Â¨Ã Â´Â¯Ã Â´â€š',
        )
      : strings.localized(
          telugu:
              'Ã Â°Â¨Ã Â°Â¿Ã Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¨Ã Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â·Ã Â°Â°Ã Â°Â¤Ã Â±ÂÃ Â°Â²Ã Â±Â',
          english: 'Terms & Conditions',
          hindi:
              'Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â® Ã Â¤â€Ã Â¤Â° Ã Â¤Â¶Ã Â¤Â°Ã Â¥ÂÃ Â¤Â¤Ã Â¥â€¡Ã Â¤â€š',
          tamil:
              'Ã Â®ÂµÃ Â®Â¿Ã Â®Â¤Ã Â®Â¿Ã Â®Â®Ã Â¯ÂÃ Â®Â±Ã Â¯Ë†Ã Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Â¨Ã Â®Â¿Ã Â®ÂªÃ Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â®Â©Ã Â¯Ë†Ã Â®â€¢Ã Â®Â³Ã Â¯Â',
          kannada:
              'Ã Â²Â¨Ã Â²Â¿Ã Â²Â¯Ã Â²Â®Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â·Ã Â²Â°Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²â€”Ã Â²Â³Ã Â³Â',
          malayalam:
              'Ã Â´Â¨Ã Â´Â¿Ã Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´Â¨Ã Â´â€¢Ã Â´Â³Ã ÂµÂÃ Â´â€š Ã Â´ÂµÃ ÂµÂÃ Â´Â¯Ã Â´ÂµÃ Â´Â¸Ã ÂµÂÃ Â´Â¥Ã Â´â€¢Ã Â´Â³Ã ÂµÂÃ Â´â€š',
        );

  String get badge => _isPrivacy
      ? strings.localized(
          telugu: 'Ã Â°Â¡Ã Â±â€¡Ã Â°Å¸Ã Â°Â¾ Ã Â°Â°Ã Â°â€¢Ã Â±ÂÃ Â°Â·Ã Â°Â£',
          english: 'Data Protection',
          hindi:
              'Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â°Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¾',
          tamil:
              'Ã Â®Â¤Ã Â®Â°Ã Â®ÂµÃ Â¯Â Ã Â®ÂªÃ Â®Â¾Ã Â®Â¤Ã Â¯ÂÃ Â®â€¢Ã Â®Â¾Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯Â',
          kannada:
              'Ã Â²Â¡Ã Â³â€¡Ã Â²Å¸Ã Â²Â¾ Ã Â²Â°Ã Â²â€¢Ã Â³ÂÃ Â²Â·Ã Â²Â£Ã Â³â€ ',
          malayalam:
              'Ã Â´Â¡Ã Â´Â¾Ã Â´Â±Ã ÂµÂÃ Â´Â± Ã Â´Â¸Ã Â´â€šÃ Â´Â°Ã Â´â€¢Ã ÂµÂÃ Â´Â·Ã Â´Â£Ã Â´â€š',
        )
      : strings.localized(
          telugu:
              'Ã Â°ÂµÃ Â°Â¿Ã Â°Â¨Ã Â°Â¿Ã Â°Â¯Ã Â±â€¹Ã Â°â€” Ã Â°Â¨Ã Â°Â¿Ã Â°Â¯Ã Â°Â®Ã Â°Â¾Ã Â°Â²Ã Â±Â',
          english: 'Usage Terms',
          hindi: 'Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€” Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â®',
          tamil:
              'Ã Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â¯Â Ã Â®ÂµÃ Â®Â¿Ã Â®Â¤Ã Â®Â¿Ã Â®â€¢Ã Â®Â³Ã Â¯Â',
          kannada:
              'Ã Â²Â¬Ã Â²Â³Ã Â²â€¢Ã Â³â€  Ã Â²Â¨Ã Â²Â¿Ã Â²Â¯Ã Â²Â®Ã Â²â€”Ã Â²Â³Ã Â³Â',
          malayalam:
              'Ã Â´â€°Ã Â´ÂªÃ Â´Â¯Ã Âµâ€¹Ã Â´â€” Ã Â´Â¨Ã Â´Â¿Ã Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´Â¨Ã Â´â€¢Ã ÂµÂ¾',
        );

  String get summary => _isPrivacy
      ? strings.localized(
          telugu:
              'Ã Â°Â®Ã Â±â‚¬ Ã Â°Â¡Ã Â±â€¡Ã Â°Å¸Ã Â°Â¾, subscriptions, Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°â€¢Ã Â°Å¸Ã Â°Â¨Ã Â°Â²Ã Â±Â, account deletion Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Firebase Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â°Â² Ã Â°ÂµÃ Â°Â¿Ã Â°Â¨Ã Â°Â¿Ã Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°â€š Ã Â°â€”Ã Â±ÂÃ Â°Â°Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿ Ã Â°Ë† Ã Â°ÂªÃ Â±â€¡Ã Â°Å“Ã Â±â‚¬ Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
          english:
              'This page explains how Mana Poster Ai handles your data, subscriptions, editor assets, Telugu fonts, background removal, ads, account deletion, and Firebase-powered services.',
        )
      : strings.localized(
          telugu:
              'Mana Poster Ai Ã Â°ÂµÃ Â°Â¾Ã Â°Â¡Ã Â°â€¢Ã Â°â€š, subscriptions, Ã Â°Å¡Ã Â±â€ Ã Â°Â²Ã Â±ÂÃ Â°Â²Ã Â°Â¿Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°â€¢Ã Â°Å¸Ã Â°Â¨Ã Â°Â²Ã Â±Â, Ã Â°â€“Ã Â°Â¾Ã Â°Â¤Ã Â°Â¾ Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â°Â¤Ã Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â°Â¾ Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Â®Ã Â°Â¿Ã Â°Â¤Ã Â±ÂÃ Â°Â²Ã Â°â€¢Ã Â±Â Ã Â°Â¸Ã Â°â€šÃ Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¨Ã Â°Â¿Ã Â°Â¯Ã Â°Â®Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°â€¡Ã Â°â€¢Ã Â±ÂÃ Â°â€¢Ã Â°Â¡ Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
          english:
              'This page contains the rules for using Mana Poster Ai, including subscriptions, editor tools, premium assets, payments, ads, account responsibility, and service limitations.',
        );

  String get lastUpdated => strings.localized(
    telugu:
        'Ã Â°Å¡Ã Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¿ Ã Â°Â¨Ã Â°ÂµÃ Â±â‚¬Ã Â°â€¢Ã Â°Â°Ã Â°Â£: 23 Ã Â°Å“Ã Â±â€šÃ Â°Â²Ã Â±Ë† 2026',
    english: 'Last updated: July 23, 2026',
  );

  List<_LegalSection> get sections =>
      _isPrivacy ? _privacySections : _termsSections;

  String get footer => strings.localized(
    telugu:
        'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¶Ã Â±ÂÃ Â°Â¨Ã Â°Â²Ã Â±Â Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±â€¡ ${AppPublicInfo.supportEmail} Ã Â°â€¢Ã Â°Â¿ Ã Â°Â¸Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
    english: 'For questions, contact ${AppPublicInfo.supportEmail}.',
    hindi:
        'Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â¨ Ã Â¤Â¹Ã Â¥â€¹Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤ÂªÃ Â¤Â° ${AppPublicInfo.supportEmail} Ã Â¤ÂªÃ Â¤Â° Ã Â¤Â¸Ã Â¤â€šÃ Â¤ÂªÃ Â¤Â°Ã Â¥ÂÃ Â¤â€¢ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤',
    tamil:
        'Ã Â®â€¢Ã Â¯â€¡Ã Â®Â³Ã Â¯ÂÃ Â®ÂµÃ Â®Â¿Ã Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®â€¡Ã Â®Â°Ã Â¯ÂÃ Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â®Â¾Ã Â®Â²Ã Â¯Â ${AppPublicInfo.supportEmail}-Ã Â®Â Ã Â®Â¤Ã Â¯Å Ã Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®ÂªÃ Â¯Â Ã Â®â€¢Ã Â¯Å Ã Â®Â³Ã Â¯ÂÃ Â®Â³Ã Â¯ÂÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â.',
    kannada:
        'Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Â¶Ã Â³ÂÃ Â²Â¨Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â²Â¿Ã Â²Â¦Ã Â³ÂÃ Â²Â¦Ã Â²Â°Ã Â³â€  ${AppPublicInfo.supportEmail} Ã Â²â€”Ã Â³â€  Ã Â²Â¸Ã Â²â€šÃ Â²ÂªÃ Â²Â°Ã Â³ÂÃ Â²â€¢Ã Â²Â¿Ã Â²Â¸Ã Â²Â¿.',
    malayalam:
        'Ã Â´Å¡Ã Âµâ€¹Ã Â´Â¦Ã ÂµÂÃ Â´Â¯Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´â€°Ã Â´Â£Ã ÂµÂÃ Â´Å¸Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ ${AppPublicInfo.supportEmail}-Ã ÂµÂ½ Ã Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€¢.',
  );

  List<_LegalSection> get _privacySections => <_LegalSection>[
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â®Ã Â±â€¡Ã Â°Â®Ã Â±Â Ã Â°Â Ã Â°Â¸Ã Â°Â®Ã Â°Â¾Ã Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â°â€š Ã Â°Â¸Ã Â±â€¡Ã Â°â€¢Ã Â°Â°Ã Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â®Ã Â±Â',
        english: 'What We Collect',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â®Ã Â±â€¡Ã Â°Â®Ã Â±Â Ã Â°Â®Ã Â±â‚¬ email address, Ã Â°ÂªÃ Â±â€¡Ã Â°Â°Ã Â±Â, Firebase UID, Google Sign-In details, profile photo, logo, poster profile details, business name, WhatsApp number, selected State/Union Territory, selected app language, selected political party categories, notification token, subscription status, referral code, referral attribution details, purchase verification Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¨ billing information, editor asset download/cache records, ad consent/status signals, support/report details Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â app operate Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¨ technical diagnostics Ã Â°Â¨Ã Â±Â collect/process Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'We collect your email address, name, Firebase UID, Google Sign-In details, profile photo, logo, poster profile details, business name, WhatsApp number, selected State/Union Territory, selected app language, selected political party categories, notification token, subscription status, referral code, referral attribution details, billing information needed for purchase verification, editor asset download/cache records, ad consent/status signals, support/report details, and technical diagnostics needed to operate the app.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â¡Ã Â±â€¡Ã Â°Å¸Ã Â°Â¾Ã Â°Â¨Ã Â±Â Ã Â°Å½Ã Â°Â²Ã Â°Â¾ Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â®Ã Â±Â',
        english: 'How We Use Data',
      ),
      strings.localized(
        telugu:
            'Ã Â°Ë† Ã Â°Â¸Ã Â°Â®Ã Â°Â¾Ã Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â°Â¾Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ login, account security, region-based language selection, relevant poster categories Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°â€š, poster personalization, editor asset delivery, asset download access, save/export flows, PSD/TIFF import support, background removal, notification delivery, subscription verification, purchase restoration, rewarded-ad access checks, referral rewards, abuse prevention Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â customer support Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â®Ã Â±Â.',
        english:
            'We use this data for login, account security, region-based language selection, showing relevant poster categories, poster personalization, editor asset delivery, asset download access, save and export flows, PSD/TIFF import support, background removal, notification delivery, subscription verification, purchase restoration, rewarded-ad access checks, referral rewards, abuse prevention, and customer support.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¾Ã Â°â€šÃ Â°Â¤Ã Â°â€š, Ã Â°Â­Ã Â°Â¾Ã Â°Â· Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â°Ã Â°Â¾Ã Â°Å“Ã Â°â€¢Ã Â±â‚¬Ã Â°Â¯ Ã Â°ÂµÃ Â°Â°Ã Â±ÂÃ Â°â€”Ã Â°Â¾Ã Â°Â² Ã Â°Å½Ã Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€¢Ã Â°Â²Ã Â±Â',
        english: 'Region, Language, and Political Category Choices',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â State/Union Territory Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°Â¡Ã Â±Â Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°â€  Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¾Ã Â°â€šÃ Â°Â¤Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°Â¸Ã Â°â€šÃ Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿Ã Â°Â¨ primary language Ã Â°Â¨Ã Â±Â apply Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¾Ã Â°â€šÃ Â°Â¤Ã Â°â€š, language Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â political party category preferences Ã Â°Â¨Ã Â±Â local device Ã Â°Â²Ã Â±â€¹ Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â signed-in account Ã Â°Â¤Ã Â±â€¹ sync Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ server Ã Â°Â²Ã Â±â€¹ save Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°â€¡Ã Â°ÂµÃ Â°Â¿ home categories, dashboard uploads matching, personalization Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â support Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â settings/profile Ã Â°Â²Ã Â±â€¹ Ã Â°Ë† Ã Â°Å½Ã Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€¢Ã Â°Â²Ã Â°Â¨Ã Â±Â Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'When you select a State or Union Territory, the app may apply the primary language for that region. Your selected region, language, and political party category preferences may be saved locally and synced with your signed-in account. These choices are used for home categories, dashboard upload matching, personalization, and support. You can update these choices from settings/profile.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°â€¢Ã Â°Â®Ã Â±ÂÃ Â°Â¯Ã Â±â€šÃ Â°Â¨Ã Â°Â¿Ã Â°Å¸Ã Â±â‚¬ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±Â Ã Â°â€¦Ã Â°ÂªÃ Â±ÂÃ Â°Â²Ã Â±â€¹Ã Â°Â¡Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¸Ã Â°Â®Ã Â±â‚¬Ã Â°â€¢Ã Â±ÂÃ Â°Â·',
        english: 'Community Uploads and Review',
      ),
      strings.localized(
        telugu:
            'Users manager review Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š image, quote text Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ image + quote Ã Â°Â°Ã Â±â€ Ã Â°â€šÃ Â°Â¡Ã Â±â€š submit Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Upload Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ media, quote text, selected region, selected/user-corrected category, political party category where applicable, upload time, applicable visibility date, review status, rejection reason, contribution share/download counts Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â related moderation history Ã Â°Â¨Ã Â±Â process Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Quote-only submissions raw text Ã Â°â€”Ã Â°Â¾ publish Ã Â°â€¦Ã Â°ÂµÃ Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¨Ã Â°Â¿ Ã Â°Â¹Ã Â°Â¾Ã Â°Â®Ã Â±â‚¬ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â±Â; manager quote Ã Â°Â¨Ã Â±Â reference Ã Â°â€”Ã Â°Â¾ Ã Â°Â¤Ã Â±â‚¬Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ poster image create/customize Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿ Ã Â°Â¸Ã Â°Â°Ã Â±Ë†Ã Â°Â¨ category Ã Â°Â²Ã Â±â€¹ upload Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Approved poster selected Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ manager-corrected category Ã Â°Â²Ã Â±â€¹ Ã Â°â€¡Ã Â°Â¤Ã Â°Â° users Ã Â°â€¢Ã Â±Â Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Pending, rejected Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ policy-violating uploads Ã Â°Â¨Ã Â±Â review, reject, edit, delay, remove Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ retain Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ managers/admins Ã Â°â€¢Ã Â±Â Ã Â°Â¹Ã Â°â€¢Ã Â±ÂÃ Â°â€¢Ã Â±Â Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
        english:
            'Users may submit an image, quote text, or both for manager review. We may process the uploaded media, quote text, selected region, selected or manager-corrected category, political party category where applicable, upload time, applicable visibility date, review status, rejection reason, contribution share/download counts, and related moderation history. Quote-only submissions are not guaranteed to be published as raw text; a manager may use the quote as reference and create or customize a poster image. Approved community uploads are visible only to the uploading user in My Uploads and are not shown to other users in public app categories. Managers and admins may review, reject, edit, delay, remove, or retain pending, rejected, or policy-violating uploads as part of moderation and record-keeping.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Firebase, Analytics Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ads',
        english: 'Firebase, Analytics, and Ads',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Firebase Authentication, Firestore, Storage, Messaging, Analytics, Crashlytics, Google Sign-In, Google Play Billing Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â AdMob Ã Â°Â¨Ã Â±Â Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Ã Â°Ë† Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â°Â²Ã Â±Â app performance, crash diagnostics, notifications, billing verification, premium asset delivery Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â ad delivery Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿. Personalized Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ non-personalized ads, Ã Â°â€¦Ã Â°Â²Ã Â°Â¾Ã Â°â€”Ã Â±â€¡ paid subscription Ã Â°Â²Ã Â±â€¡Ã Â°â€¢Ã Â±ÂÃ Â°â€šÃ Â°Â¡Ã Â°Â¾ Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ editor actions unlock Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ rewarded ads Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ AdMob device identifiers, IP address, consent status Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â usage data Ã Â°Â¨Ã Â±Â process Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'The app uses Firebase Authentication, Firestore, Storage, Messaging, Analytics, Crashlytics, Google Sign-In, Google Play Billing, and AdMob. These services support app performance, crash diagnostics, notifications, billing verification, premium asset delivery, and ad delivery. AdMob may collect device identifiers, IP address, consent status, and usage data to provide personalized or non-personalized ads, including rewarded ads that may unlock selected editor actions without a paid subscription.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â¡Ã Â±â€¡Ã Â°Å¸Ã Â°Â¾ Ã Â°Â·Ã Â±â€¡Ã Â°Â°Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±Â',
        english: 'Data Sharing',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â®Ã Â±â€¡Ã Â°Â®Ã Â±Â personal data Ã Â°Â¨Ã Â±Â Ã Â°â€¦Ã Â°Â®Ã Â±ÂÃ Â°Â®Ã Â°Â®Ã Â±Â. Data essential service providers, lawful authorities, billing/review partners Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ legal/security obligations Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¨Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°Â¡Ã Â±Â Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ share Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'We do not sell personal data. Data may be shared only with essential service providers, lawful authorities, or where reasonably necessary for billing, moderation, fraud prevention, security, or legal compliance.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°ÂªÃ Â°Â¿Ã Â°Â²Ã Â±ÂÃ Â°Â²Ã Â°Â² Ã Â°â€”Ã Â±â€¹Ã Â°ÂªÃ Â±ÂÃ Â°Â¯Ã Â°Â¤',
        english: 'Children\'s Privacy',
      ),
      strings.localized(
        telugu:
            'Ã Â°Ë† Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â 13 Ã Â°Â¸Ã Â°â€šÃ Â°ÂµÃ Â°Â¤Ã Â±ÂÃ Â°Â¸Ã Â°Â°Ã Â°Â¾Ã Â°Â² Ã Â°Â²Ã Â±â€¹Ã Â°ÂªÃ Â±Â Ã Â°ÂªÃ Â°Â¿Ã Â°Â²Ã Â±ÂÃ Â°Â²Ã Â°Â² Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€°Ã Â°Â¦Ã Â±ÂÃ Â°Â¦Ã Â±â€¡Ã Â°Â¶Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â±Â.',
        english: 'This app is not intended for children under the age of 13.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹Ã Â°Â²Ã Â±Â, permissions Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â storage',
        english: 'Photos, Permissions, and Storage',
      ),
      strings.localized(
        telugu:
            'Photo selection, poster saving, status image selection, PSD/TIFF import, local export Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â optional notifications Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ permissions Ã Â°â€¦Ã Â°Â¡Ã Â±ÂÃ Â°â€”Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â®Ã Â±Â. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â Ã Â°ÂµÃ Â±â‚¬Ã Â°Å¸Ã Â°Â¿Ã Â°Â¨Ã Â°Â¿ device settings Ã Â°Â²Ã Â±â€¹ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â upload, import, export, status Ã Â°â€”Ã Â°Â¾ use, comment/reply Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ share Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ content Ã Â°â€¢Ã Â±Â Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â±ÂÃ Â°Â²Ã Â±Â. App media files, downloaded premium assets, brush resources, previews, export files Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â temporary cache Ã Â°Â¨Ã Â±Â Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°â€š Ã Â°Â®Ã Â±â€¡Ã Â°Â°Ã Â°â€¢Ã Â±Â save Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿, Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°â€š Ã Â°Â®Ã Â±ÂÃ Â°â€”Ã Â°Â¿Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ remove Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Status images upload Ã Â°Â®Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â±Â compress Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¬Ã Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â; temporary compressed files device Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ backend processing Ã Â°ÂªÃ Â±â€šÃ Â°Â°Ã Â±ÂÃ Â°Â¤Ã Â°Â¯Ã Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°â€¢ remove Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'Permissions are requested only for photo selection, poster saving, status image selection, PSD/TIFF import, local export, and optional notifications. You can manage them from device settings. You remain responsible for any content you upload, import, export, use as a status, comment/reply to, or share. The app may temporarily cache media files, downloaded premium assets, brush resources, previews, and export files, and may remove temporary files when they are no longer needed. Status images may be compressed before upload; temporary compressed files may be removed after device or backend processing is complete.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Editor processing, assets Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â downloads',
        english: 'Editor Processing, Assets, and Downloads',
      ),
      strings.localized(
        telugu:
            'Editor Ã Â°Â²Ã Â±â€¹ PSD/TIFF import, photo editing, brushes, layer effects, Telugu fonts, premium assets Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â background removal tools Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Premium assets backend/dashboard Ã Â°Â¨Ã Â±ÂÃ Â°â€šÃ Â°Â¡Ã Â°Â¿ categories Ã Â°â€”Ã Â°Â¾ Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Asset thumbnail app Ã Â°Â²Ã Â±â€¹ Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿; user download/import Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°Â¡Ã Â±Â asset device cache Ã Â°Â²Ã Â±â€¹ save Ã Â°â€¢Ã Â°Â¾Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Admins assets/categories Ã Â°Â¨Ã Â±Â update, remove Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ replace Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'The editor may support PSD/TIFF import, photo editing, brushes, layer effects, Telugu fonts, premium assets, and background removal tools. Premium assets may be delivered from the backend/admin dashboard by category. Asset thumbnails may be shown in the app, and downloaded/imported assets may be saved in device cache for faster reuse. Admins may update, remove, replace, or reorganize assets and categories over time. Background removal and other editor processing may run on-device where supported or through configured app services when needed for the requested feature.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Subscriptions Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â billing',
        english: 'Subscriptions and Billing',
      ),
      strings.localized(
        telugu:
            'Subscription verification Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š purchase tokens, product IDs, entitlement status Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â billing status Ã Â°Â¨Ã Â±Â server-side Ã Â°Â²Ã Â±â€¹ process Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Mana Poster Ai Ã Â°Â²Ã Â±â€¹ Ã Â°ÂµÃ Â±â€¡Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â±â€¡Ã Â°Â°Ã Â±Â Google Play Billing plans Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â: App Pro (${SubscriptionPlanConfig.trialPriceDisplay} ${SubscriptionPlanConfig.trialDays} Ã Â°Â°Ã Â±â€¹Ã Â°Å“Ã Â±ÂÃ Â°Â²Ã Â°â€¢Ã Â±Â, cancel Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°â€¢Ã Â°ÂªÃ Â±â€¹Ã Â°Â¤Ã Â±â€¡ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°Â¨Ã Â±â€ Ã Â°Â²Ã Â°â€¢Ã Â±Â ${SubscriptionPlanConfig.monthlyPriceDisplay}), Editor Pro (premium editor assets, Telugu fonts, background removal Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°Â¨Ã Â±â€ Ã Â°Â²Ã Â°â€¢Ã Â±Â Ã¢â€šÂ¹99), yearly all-access (available Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Å¡Ã Â±â€¹Ã Â°Å¸ App Pro + Editor Pro benefits Ã Â°â€¢Ã Â°Â²Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿ Ã Â°Â¸Ã Â°â€šÃ Â°ÂµÃ Â°Â¤Ã Â±ÂÃ Â°Â¸Ã Â°Â°Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã¢â€šÂ¹699). Plan availability, prices, taxes, grace periods, renewal behavior Google Play Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ control Ã Â°â€¦Ã Â°ÂµÃ Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿ Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â country/platform Ã Â°â€ Ã Â°Â§Ã Â°Â¾Ã Â°Â°Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'For subscription verification, purchase tokens, product IDs, entitlement status, and billing status may be processed server-side. Mana Poster Ai may offer separate Play Billing plans, including App Pro (${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days, then ${SubscriptionPlanConfig.monthlyPriceDisplay} per month unless cancelled), Editor Pro (Ã¢â€šÂ¹99 per month for premium editor assets, Telugu fonts, and background removal), and yearly all-access (Ã¢â€šÂ¹699 per year where available, covering App Pro and Editor Pro benefits). Plan availability, prices, taxes, grace periods, and renewal behavior are controlled through Google Play and may vary by country or platform.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â®Ã Â±â‚¬ Ã Â°Å½Ã Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€¢Ã Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â account deletion',
        english: 'Your Choices and Account Deletion',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â optional notifications Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â permissions Ã Â°Â¨Ã Â±Â off Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ account deletion request option Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Users complete data deletion Ã Â°Â¨Ã Â±Â in-app deletion option Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ support Ã Â°Â¨Ã Â±Â Ã Â°Â¸Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°â€š Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ request Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Account delete Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ login access, poster profile details Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â linked app data Ã Â°Â¤Ã Â±Å Ã Â°Â²Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ billing, tax, anti-fraud Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ platform-required records Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Â®Ã Â°Â¿Ã Â°Â¤ Ã Â°â€¢Ã Â°Â¾Ã Â°Â²Ã Â°â€š Ã Â°Â¨Ã Â°Â¿Ã Â°Â²Ã Â±ÂÃ Â°Âµ Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â: ${AppPublicInfo.accountDeletionUrl}',
        english:
            'You can turn off optional notifications and permissions. The app provides an in-app account deletion request option. Users can request complete data deletion using the in-app deletion option or by contacting support. After deletion, login access, poster profile details, and linked app data may be removed. Some billing, tax, anti-fraud, or platform-required records may be retained for a limited period. More details: ${AppPublicInfo.accountDeletionUrl}',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â°Ã Â°Â¿Ã Â°ÂªÃ Â±â€¹Ã Â°Â°Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°â€¦Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Å¡Ã Â°Â¿Ã Â°Â¤/Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Å¡Ã Â°Â¿Ã Â°Â¤ Ã Â°â€¢Ã Â°â€šÃ Â°Å¸Ã Â±â€ Ã Â°â€šÃ Â°Å¸Ã Â±Â',
        english: 'Reporting and Abusive Content',
      ),
      strings.localized(
        telugu:
            'Ã Â°â€¦Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Å¡Ã Â°Â¿Ã Â°Â¤, Ã Â°Â¦Ã Â±ÂÃ Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¿Ã Â°Â¨Ã Â°Â¿Ã Â°Â¯Ã Â±â€¹Ã Â°â€”, Ã Â°â€¢Ã Â°Â¾Ã Â°ÂªÃ Â±â‚¬Ã Â°Â°Ã Â±Ë†Ã Â°Å¸Ã Â±Â Ã Â°â€°Ã Â°Â²Ã Â±ÂÃ Â°Â²Ã Â°â€šÃ Â°ËœÃ Â°Â¨, impersonation Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ spam Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±Â Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±â€¡, app Ã Â°Â²Ã Â±â€¹ available support/report option Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ ${AppPublicInfo.supportEmail} Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ report Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Complaints, moderation decisions, review evidence Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â limited enforcement records Ã Â°Â¨Ã Â±Â abuse prevention, legal compliance Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â safety Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š retain Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'If you see abusive, infringing, impersonating, deceptive, or spam content, you can report it using the app support/report option or by emailing ${AppPublicInfo.supportEmail}. Complaints, moderation decisions, review evidence, and limited enforcement records may be retained for abuse prevention, legal compliance, and user safety.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â¸Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°ÂªÃ Â±Â Ã Â°Â¸Ã Â°Â®Ã Â°Â¾Ã Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â°â€š',
        english: 'Contact Information',
      ),
      strings.localized(
        telugu:
            'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Ë†Ã Â°ÂµÃ Â°Â¸Ã Â±â‚¬, billing, data usage Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ account deletion Ã Â°Â¸Ã Â°Â¹Ã Â°Â¾Ã Â°Â¯Ã Â°â€š Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š ${AppPublicInfo.supportEmail} Ã Â°â€¢Ã Â±Â Ã Â°â€¡Ã Â°Â®Ã Â±â€ Ã Â°Â¯Ã Â°Â¿Ã Â°Â²Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
        english:
            'For privacy, billing, data usage, or account deletion support, email ${AppPublicInfo.supportEmail}.',
      ),
    ),
  ];

  List<_LegalSection> get _termsSections => <_LegalSection>[
    _LegalSection(
      strings.localized(
        telugu: 'Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°ÂµÃ Â°Â¾Ã Â°Â¡Ã Â°â€¢Ã Â°â€š',
        english: 'Using the App',
      ),
      strings.localized(
        telugu:
            'Mana Poster Ai Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°â€¢Ã Â±ÂÃ Â°Â¤Ã Â°Â¿Ã Â°â€”Ã Â°Â¤, Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â°Â¾Ã Â°Â° Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Å¡Ã Â°Â¾Ã Â°Â° Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°Â°Ã Â±â€šÃ Â°ÂªÃ Â±Å Ã Â°â€šÃ Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°â€°Ã Â°Â¦Ã Â±ÂÃ Â°Â¦Ã Â±â€¡Ã Â°Â¶Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°Â¿Ã Â°â€šÃ Â°Â¦Ã Â°Â¿. Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â¨Ã Â±Â Ã Â°Å¡Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°Â¬Ã Â°Â¦Ã Â±ÂÃ Â°Â§Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â°Â¤Ã Â°Â¤Ã Â±â€¹ Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¾Ã Â°Â²Ã Â°Â¿.',
        english:
            'Mana Poster Ai is intended for personal, business, and promotional poster creation. You must use the app lawfully and responsibly.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°â€“Ã Â°Â¾Ã Â°Â¤Ã Â°Â¾ Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°â€¢Ã Â°â€šÃ Â°Å¸Ã Â±â€ Ã Â°â€šÃ Â°Å¸Ã Â±Â Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â°Â¤',
        english: 'Account and Content Responsibility',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â®Ã Â±â‚¬ login Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°Â­Ã Â°Â¦Ã Â±ÂÃ Â°Â°Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°â€°Ã Â°â€šÃ Â°Å¡Ã Â°Â¾Ã Â°Â²Ã Â°Â¿. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â upload Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ photos, quote text, status images, status captions, status replies/comments, videos, logos Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ poster materials Ã Â°Â¨Ã Â±Â Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±â€¡ Ã Â°Â¹Ã Â°â€¢Ã Â±ÂÃ Â°â€¢Ã Â±Â Ã Â°Â®Ã Â±â‚¬Ã Â°â€¢Ã Â±â€¡ Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°Â¾Ã Â°Â²Ã Â°Â¿. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â submit Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ quote Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ image Ã Â°Â¨Ã Â±Â review, edit/customize, category correction Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â app Ã Â°Â²Ã Â±â€¹ publication Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Mana Poster Ai Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ non-exclusive permission Ã Â°â€¡Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â°Ã Â±Â. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â status Ã Â°â€”Ã Â°Â¾ upload Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ text/image/caption Ã Â°Â¨Ã Â±Â selected region/religion scope Ã Â°Â²Ã Â±â€¹ Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ temporary permission Ã Â°â€¡Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â°Ã Â±Â. Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â status reply/comment Ã Â°ÂªÃ Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°Â¤Ã Â±â€¡, Ã Â°â€  reply/comment status owner Ã Â°â€¢Ã Â±Â Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â safety/moderation/security purposes Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š process Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ permission Ã Â°â€¡Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â°Ã Â±Â. Ã Â°Å¡Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°ÂµÃ Â°Â¿Ã Â°Â°Ã Â±ÂÃ Â°Â¦Ã Â±ÂÃ Â°Â§Ã Â°â€š, Ã Â°Â®Ã Â±â€¹Ã Â°Â¸Ã Â°ÂªÃ Â±â€šÃ Â°Â°Ã Â°Â¿Ã Â°Â¤Ã Â°â€š, Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â±â€¡Ã Â°Â·Ã Â°ÂªÃ Â±â€šÃ Â°Â°Ã Â°Â¿Ã Â°Â¤Ã Â°â€š, Ã Â°â€¦Ã Â°Â¸Ã Â°Â­Ã Â±ÂÃ Â°Â¯Ã Â°â€š, threatening, harassment, privacy-violating Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°â€¡Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°Â² Ã Â°Â¹Ã Â°â€¢Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â²Ã Â°Â¨Ã Â±Â Ã Â°â€°Ã Â°Â²Ã Â±ÂÃ Â°Â²Ã Â°â€šÃ Â°ËœÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±â€¡ content Ã Â°Â¨Ã Â°Â¿Ã Â°Â·Ã Â±â€¡Ã Â°Â§Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€¡Ã Â°Â¤Ã Â°Â° users Ã Â°â€¢Ã Â±Â Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±â€¡ posters/videos publication Ã Â°â€¢Ã Â±Â Ã Â°Â®Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â±Â review Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¬Ã Â°Â¡Ã Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿; statuses/replies short-lived Ã Â°â€¦Ã Â°Â¯Ã Â°Â¿Ã Â°Â¨Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â°Å¸Ã Â°Â¿Ã Â°â€¢Ã Â±â‚¬ policy/security review Ã Â°â€¢Ã Â±Â Ã Â°Â²Ã Â±â€¹Ã Â°Â¬Ã Â°Â¡Ã Â°Â¿ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
        english:
            'You must keep your login details secure. You must have the right to use any photos, quote text, status images, status captions, status replies/comments, videos, logos, or poster materials you upload. By submitting a quote or image, you give Mana Poster Ai non-exclusive permission to review, edit/customize, correct the category, and show the approved result to you in My Uploads. By uploading text/image/caption as a status, you give temporary permission to show it within the selected region/religion scope. By sending a status reply/comment, you give permission to show that reply/comment to the status owner and to process it for safety, moderation, and security purposes. Illegal, deceptive, hateful, obscene, threatening, harassing, privacy-violating, or infringing content is prohibited. Posters or videos shown to other users in the app are reviewed before publication; statuses/replies are short-lived but remain subject to policy and security review.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â°Ã Â°Â¾Ã Â°Å“Ã Â°â€¢Ã Â±â‚¬Ã Â°Â¯ Ã Â°ÂµÃ Â°Â°Ã Â±ÂÃ Â°â€”Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Å“Ã Â°Â¾ Ã Â°â€”Ã Â±ÂÃ Â°Â°Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°Â²Ã Â±Â',
        english: 'Political Categories and Public Symbols',
      ),
      strings.localized(
        telugu:
            'Political party categories, party names, party symbols/logos, State/Union Territory emblems Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â public identifiers Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ category navigation, regional relevance Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â poster discovery Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°â€¡Ã Â°ÂµÃ Â°Â¿ Mana Poster Ai Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ endorsement, affiliation, sponsorship Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ political claim Ã Â°â€”Ã Â°Â¾ Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°â€”Ã Â°Â£Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â°Ã Â°Â¾Ã Â°Â¦Ã Â±Â. Users Ã Â°Â°Ã Â°Â¾Ã Â°Å“Ã Â°â€¢Ã Â±â‚¬Ã Â°Â¯ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ public-interest content Ã Â°Â¤Ã Â°Â¯Ã Â°Â¾Ã Â°Â°Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ Ã Â°Â¸Ã Â°Â®Ã Â°Â¯Ã Â°â€šÃ Â°Â²Ã Â±â€¹ Ã Â°ÂµÃ Â°Â°Ã Â±ÂÃ Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±â€¡ laws, election rules, platform policies, copyright/trademark rights Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â factual accuracy Ã Â°â€¢Ã Â°Â¿ Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â°Â¤ Ã Â°ÂµÃ Â°Â¹Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¾Ã Â°Â²Ã Â°Â¿.',
        english:
            'Political party categories, party names, party symbols/logos, State/Union Territory emblems, and public identifiers may be shown only for category navigation, regional relevance, and poster discovery. They do not imply endorsement, affiliation, sponsorship, or any political claim by Mana Poster Ai. Users creating political or public-interest content are responsible for complying with applicable laws, election rules, platform policies, copyright/trademark rights, and factual accuracy.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Subscriptions Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â premium access',
        english: 'Subscriptions and Premium Access',
      ),
      strings.localized(
        telugu:
            'Mana Poster Ai Ã Â°Â²Ã Â±â€¹ multiple subscription plans Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. App Pro Ã Â°â€¢Ã Â°Â¿ ${SubscriptionPlanConfig.trialPriceDisplay} trial ${SubscriptionPlanConfig.trialDays} Ã Â°Â°Ã Â±â€¹Ã Â°Å“Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â; cancel Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°â€¢Ã Â°ÂªÃ Â±â€¹Ã Â°Â¤Ã Â±â€¡ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°Â¨Ã Â±â€ Ã Â°Â²Ã Â°â€¢Ã Â±Â ${SubscriptionPlanConfig.monthlyPriceDisplay} Ã Â°Å¡Ã Â±Å Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°Â¨ renew Ã Â°â€¦Ã Â°ÂµÃ Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Editor Pro premium editor assets, Telugu fonts Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â background removal Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°Â¨Ã Â±â€ Ã Â°Â²Ã Â°â€¢Ã Â±Â Ã¢â€šÂ¹99 Ã Â°â€”Ã Â°Â¾ Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Yearly all-access plan available Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Å¡Ã Â±â€¹Ã Â°Å¸ App Pro Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Editor Pro benefits Ã Â°â€¢Ã Â°Â²Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿ Ã Â°Â¸Ã Â°â€šÃ Â°ÂµÃ Â°Â¤Ã Â±ÂÃ Â°Â¸Ã Â°Â°Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã¢â€šÂ¹699 Ã Â°â€”Ã Â°Â¾ Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Active benefits purchased plan, successful Google Play verification, country availability Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â current product configuration Ã Â°Â®Ã Â±â‚¬Ã Â°Â¦ Ã Â°â€ Ã Â°Â§Ã Â°Â¾Ã Â°Â°Ã Â°ÂªÃ Â°Â¡Ã Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
        english:
            'Mana Poster Ai may offer multiple subscription plans. App Pro may include a ${SubscriptionPlanConfig.trialPriceDisplay} trial for ${SubscriptionPlanConfig.trialDays} days and then renew at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month unless cancelled. Editor Pro may provide premium editor assets, Telugu fonts, and background removal for Ã¢â€šÂ¹99 per month. A yearly all-access plan may provide App Pro and Editor Pro benefits together for Ã¢â€šÂ¹699 per year where available. Active benefits depend on the plan purchased, successful Google Play verification, country availability, and current product configuration.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Editor tools Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â asset license',
        english: 'Editor Tools and Asset License',
      ),
      strings.localized(
        telugu:
            'Editor Ã Â°Â²Ã Â±â€¹ premium assets, Telugu fonts, background removal, PSD/TIFF import, brushes, layer effects, text tools, erase tools Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â export tools Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Download Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ assets Ã Â°Â¨Ã Â±Â app Ã Â°Â²Ã Â±â€¹ poster/design creation Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¾Ã Â°Â²Ã Â°Â¿. Asset files Ã Â°Â¨Ã Â±Â resell, redistribute, extract, republish, package Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ standalone library Ã Â°â€”Ã Â°Â¾ share Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°â€š Ã Â°Â¨Ã Â°Â¿Ã Â°Â·Ã Â±â€¡Ã Â°Â§Ã Â°â€š. Third-party images, PSD files, fonts, logos Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ copyrighted material import Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±â€¡ Ã Â°ÂµÃ Â°Â¾Ã Â°Å¸Ã Â°Â¿ rights user Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â°Â¤.',
        english:
            'The editor may include premium assets, Telugu fonts, background removal, PSD/TIFF import, brushes, layer effects, text tools, erase tools, and export tools. Downloaded assets are licensed for creating posters/designs inside Mana Poster Ai only. You must not resell, redistribute, extract, republish, package, or share asset files as a standalone asset library. If you import third-party images, PSD files, fonts, logos, or copyrighted material, you are responsible for having the required rights. Export quality may depend on source file quality, selected canvas size, device capability, memory limits, and the export settings used.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â°Ã Â±â‚¬Ã Â°Â«Ã Â°â€šÃ Â°Â¡Ã Â±Â, Ã Â°Â°Ã Â°Â¦Ã Â±ÂÃ Â°Â¦Ã Â±Â, Ã Â°â€ Ã Â°Å¸Ã Â±â€¹ Ã Â°Â°Ã Â±â‚¬Ã Â°Â¨Ã Â±ÂÃ Â°Â¯Ã Â±ÂÃ Â°ÂµÃ Â°Â²Ã Â±Â',
        english: 'Refund, Cancellation, and Auto-Renewal',
      ),
      strings.localized(
        telugu:
            'Subscription cancellation Ã Â°Â¸Ã Â°Â¾Ã Â°Â§Ã Â°Â¾Ã Â°Â°Ã Â°Â£Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â®Ã Â±â‚¬ Play Store Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ App Store subscription settings Ã Â°Â²Ã Â±â€¹ Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¾Ã Â°Â²Ã Â°Â¿. Ã Â°Â°Ã Â°Â¦Ã Â±ÂÃ Â°Â¦Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°Â¤ billing period Ã Â°Â®Ã Â±ÂÃ Â°â€”Ã Â°Â¿Ã Â°Â¸Ã Â±â€¡ Ã Â°ÂµÃ Â°Â°Ã Â°â€¢Ã Â±Â access Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â°Â¸Ã Â°Â¾Ã Â°â€”Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Refund eligibility Ã Â°Â¨Ã Â±Â Google Play Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Apple policies Ã Â°Â¨Ã Â°Â¿Ã Â°Â°Ã Â±ÂÃ Â°Â£Ã Â°Â¯Ã Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
        english:
            'Subscription cancellation is generally managed through your Play Store or App Store subscription settings. After cancelling, access may continue until the current billing period ends. Refund eligibility is determined by Google Play or Apple policies.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Referral Rewards',
        english: 'Referral Rewards',
      ),
      strings.localized(
        telugu:
            'Mana Poster Ai referral reward Ã Â°â€™Ã Â°â€¢ promotional benefit Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡. Ã Â°â€¡Ã Â°Â¦Ã Â°Â¿ cash, wallet balance, gift card, payout Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ transferable benefit Ã Â°â€¢Ã Â°Â¾Ã Â°Â¦Ã Â±Â. Ã Â°â€™Ã Â°â€¢ user Ã Â°Â¤Ã Â°Â¨ referral code Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ referral link Ã Â°Â¨Ã Â±Â Ã Â°â€¡Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â°â€¢Ã Â±Â share Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Referred user Ã Â°â€  referral code/link Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ app Ã Â°Â²Ã Â±â€¹ Ã Â°Å¡Ã Â±â€¡Ã Â°Â°Ã Â°Â¿, valid account Ã Â°Â¤Ã Â±â€¹ login Ã Â°â€¦Ã Â°Â¯Ã Â°Â¿, Ã¢â€šÂ¹149 monthly subscription Ã Â°Â¨Ã Â±Â successful Ã Â°â€”Ã Â°Â¾ purchase Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿, server-side billing verification complete Ã Â°â€¦Ã Â°Â¯Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ referral count Ã Â°ÂªÃ Â±â€ Ã Â°Â°Ã Â±ÂÃ Â°â€”Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Install, signup, app open, trial-only access, failed payment, cancelled payment, refunded payment, chargeback, duplicate purchase, test purchase, sandbox purchase, unsupported SKU Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ verification fail Ã Â°â€¦Ã Â°Â¯Ã Â°Â¿Ã Â°Â¨ purchase referral count Ã Â°â€”Ã Â°Â¾ Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°â€”Ã Â°Â£Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°Â¦Ã Â±Â.\n\nÃ Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°Â¤Ã Â°â€š 15 valid paid referrals complete Ã Â°â€¦Ã Â°Â¯Ã Â°Â¿Ã Â°Â¤Ã Â±â€¡ referrer account Ã Â°â€¢Ã Â±Â 30 days premium reward Ã Â°â€¡Ã Â°ÂµÃ Â±ÂÃ Â°ÂµÃ Â°Â¬Ã Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Reward automatic paid subscription Ã Â°â€¢Ã Â°Â¾Ã Â°Â¦Ã Â±Â, auto-renew Ã Â°â€¦Ã Â°ÂµÃ Â°Â¦Ã Â±Â, cash value Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°Â¦Ã Â±Â, refund Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ encashment Ã Â°â€¢Ã Â±Â eligible Ã Â°â€¢Ã Â°Â¾Ã Â°Â¦Ã Â±Â. Referrer Ã Â°â€¢Ã Â±Â Ã Â°â€¡Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â°Å¸Ã Â°Â¿Ã Â°â€¢Ã Â±â€¡ paid subscription active Ã Â°â€”Ã Â°Â¾ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±â€¡, reward generally current paid access Ã Â°Â®Ã Â±ÂÃ Â°â€”Ã Â°Â¿Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ system-calculated eligible time Ã Â°Â¨Ã Â±ÂÃ Â°â€šÃ Â°Â¡Ã Â°Â¿ apply Ã Â°â€¢Ã Â°Â¾Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â, zodat paid days lose Ã Â°â€¢Ã Â°Â¾Ã Â°â€¢Ã Â±ÂÃ Â°â€šÃ Â°Â¡Ã Â°Â¾ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Reward period Ã Â°ÂªÃ Â±â€šÃ Â°Â°Ã Â±ÂÃ Â°Â¤Ã Â°Â¯Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ premium access continue Ã Â°â€¢Ã Â°Â¾Ã Â°ÂµÃ Â°Â¾Ã Â°Â²Ã Â°â€šÃ Â°Å¸Ã Â±â€¡ user normal subscription Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â°Â¸Ã Â°Â¾Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¾Ã Â°Â²Ã Â°Â¿ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°â€¢Ã Â±Å Ã Â°Â¤Ã Â±ÂÃ Â°Â¤ valid referral cycle complete Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¾Ã Â°Â²Ã Â°Â¿.\n\nSame referred user Ã Â°â€™Ã Â°â€¢Ã Â°Â¸Ã Â°Â¾Ã Â°Â°Ã Â°Â¿ Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ count Ã Â°â€¦Ã Â°ÂµÃ Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â¡Ã Â±Â. Self-referral, same person multiple accounts create Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°â€š, device/account farming, fake payments, recycled accounts, shared payment tokens, manipulated install referrer, automated signups, misleading invitations, spam, abuse, fraud, refund abuse Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ platform policy violation strictly prohibited. Mana Poster Ai suspected misuse Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°Â¡Ã Â±Â referral count, reward eligibility, reward access Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ linked accounts Ã Â°Â¨Ã Â±Â review, hold, reverse, suspend Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ remove Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Fraud/abuse investigation Ã Â°Â²Ã Â±â€¹ Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ anti-fraud records Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Â®Ã Â°Â¿Ã Â°Â¤ Ã Â°â€¢Ã Â°Â¾Ã Â°Â²Ã Â°â€š retain Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.\n\nReferral rewards backend verification Ã Â°Â®Ã Â±â‚¬Ã Â°Â¦ Ã Â°â€ Ã Â°Â§Ã Â°Â¾Ã Â°Â°Ã Â°ÂªÃ Â°Â¡Ã Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿. Network delay, Play Billing/App Store delay, Firebase delay, account mismatch, product mismatch, stale attribution, server outage Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ policy/security review Ã Â°â€¢Ã Â°Â¾Ã Â°Â°Ã Â°Â£Ã Â°â€šÃ Â°â€”Ã Â°Â¾ count Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ reward update Ã Â°â€ Ã Â°Â²Ã Â°Â¸Ã Â±ÂÃ Â°Â¯Ã Â°Â®Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. App Ã Â°Â²Ã Â±â€¹ Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±â€¡ progress informational Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡; final eligibility Mana Poster Ai server records Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â verified billing status Ã Â°â€ Ã Â°Â§Ã Â°Â¾Ã Â°Â°Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â¨Ã Â°Â¿Ã Â°Â°Ã Â±ÂÃ Â°Â£Ã Â°Â¯Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Mana Poster Ai referral rules, required referral count, reward duration, eligibility criteria, fraud checks, availability Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ program continuation Ã Â°Â¨Ã Â±Â business, legal, security Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ platform policy Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â°â€¢Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°â€”Ã Â±ÂÃ Â°Â£Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â, pause Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ stop Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Already earned valid rewards Ã Â°Â¨Ã Â±Â unfair Ã Â°â€”Ã Â°Â¾ remove Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°â€¢Ã Â±ÂÃ Â°â€šÃ Â°Â¡Ã Â°Â¾ reasonable effort Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â®Ã Â±Â, Ã Â°â€¢Ã Â°Â¾Ã Â°Â¨Ã Â±â‚¬ fraud, refund, chargeback, billing reversal, technical error Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ policy/legal requirement Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±â€¡ correction Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.\n\nReferral code share Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ user truthful invitation Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¾Ã Â°Â²Ã Â°Â¿. Mana Poster Ai official offer Ã Â°Â¨Ã Â±Â Ã Â°Â¤Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°â€”Ã Â°Â¾ represent Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°â€š, guaranteed income Ã Â°â€¦Ã Â°Â¨Ã Â°Â¿ Ã Â°Å¡Ã Â±â€ Ã Â°ÂªÃ Â±ÂÃ Â°ÂªÃ Â°Â¡Ã Â°â€š, unauthorized ads/spam Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°â€š, third-party brand/platform rules Ã Â°â€°Ã Â°Â²Ã Â±ÂÃ Â°Â²Ã Â°â€šÃ Â°ËœÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°â€š Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°â€¡Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°Â² personal data misuse Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°â€š Ã Â°Â¨Ã Â°Â¿Ã Â°Â·Ã Â±â€¡Ã Â°Â§Ã Â°â€š. Referral reward Ã Â°â€”Ã Â±ÂÃ Â°Â°Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿ dispute Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±â€¡ ${AppPublicInfo.supportEmail} Ã Â°â€¢Ã Â±Â contact Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¾Ã Â°Â²Ã Â°Â¿. Review Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š user UID, referral code, subscribed account, purchase verification status Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â relevant timestamps Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°â€š Ã Â°â€¢Ã Â°Â¾Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'The Mana Poster Ai referral reward is a promotional benefit only. It is not cash, wallet balance, a gift card, a payout, or a transferable benefit. A user may share their referral code or referral link with others. A referral is counted only when the referred user joins through that referral code/link, signs in with a valid account, successfully purchases the Ã¢â€šÂ¹149 monthly subscription, and the purchase is verified by Mana Poster Ai server-side billing verification. Installs, signups, app opens, trial-only access, failed payments, cancelled payments, refunded payments, chargebacks, duplicate purchases, test purchases, sandbox purchases, unsupported SKUs, or purchases that fail verification do not count as paid referrals.\n\nCurrently, 15 valid paid referrals earn 30 days of premium access for the referring account. The reward is not an automatic paid subscription, does not auto-renew, has no cash value, and is not eligible for refund, payout, or encashment. If the referring user already has active paid subscription access, the reward may generally be applied after the current paid access ends or from the system-calculated eligible time so that paid days are not lost. After the reward period ends, premium access continues only if the user maintains a normal subscription or completes another valid referral cycle.\n\nThe same referred user can be counted only once. Self-referrals, creating multiple accounts for the same person, device/account farming, fake payments, recycled accounts, shared payment tokens, manipulated install referrers, automated signups, misleading invitations, spam, abuse, fraud, refund abuse, or platform policy violations are strictly prohibited. If misuse is suspected, Mana Poster Ai may review, hold, reverse, suspend, or remove referral counts, reward eligibility, reward access, or linked accounts. Some anti-fraud records may be retained for a limited period for fraud and abuse investigation.\n\nReferral rewards depend on backend verification. Count or reward updates may be delayed because of network delay, Play Billing/App Store delay, Firebase delay, account mismatch, product mismatch, stale attribution, server outage, or policy/security review. Progress shown in the app is informational; final eligibility is determined from Mana Poster Ai server records and verified billing status. Mana Poster Ai may change, pause, or stop the referral program, including the required referral count, reward duration, eligibility criteria, fraud checks, or availability, to meet business, legal, security, or platform policy requirements. We will make reasonable efforts not to unfairly remove valid rewards already earned, but corrections may be made for fraud, refunds, chargebacks, billing reversals, technical errors, or legal/policy requirements.\n\nUsers sharing referral codes must make truthful invitations only. Misrepresenting the official Mana Poster Ai offer, claiming guaranteed income, running unauthorized ads/spam, violating third-party brand/platform rules, or misusing another person\'s personal data is prohibited. For referral reward disputes, contact ${AppPublicInfo.supportEmail}. Review may require user UID, referral code, subscribed account, purchase verification status, and relevant timestamps.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°â€¢Ã Â°Å¸Ã Â°Â¨Ã Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â third-party services',
        english: 'Ads and Third-Party Services',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ AdMob ads Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Paid subscription Ã Â°Â²Ã Â±â€¡Ã Â°â€¢Ã Â±ÂÃ Â°â€šÃ Â°Â¡Ã Â°Â¾ Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ premium editor actions unlock Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ rewarded ads Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Rewarded-ad access paid subscription Ã Â°â€¢Ã Â°Â¾Ã Â°Â¦Ã Â±Â, auto-renew Ã Â°â€¢Ã Â°Â¾Ã Â°Â¦Ã Â±Â, device state, ad availability, network, policy Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ fraud checks Ã Â°â€¢Ã Â°Â¾Ã Â°Â°Ã Â°Â£Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Â®Ã Â°Â¿Ã Â°Â¤Ã Â°â€š Ã Â°â€¢Ã Â°Â¾Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ads availability, ad skip timing, billing services, Google sign-in, notifications Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Firebase services Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿Ã Â°Â¸Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â third-party providers Ã Â°Â®Ã Â±â‚¬Ã Â°Â¦ Ã Â°â€ Ã Â°Â§Ã Â°Â¾Ã Â°Â°Ã Â°ÂªÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°Â®Ã Â±â€šÃ Â°Â¡Ã Â±â€¹ Ã Â°ÂªÃ Â°â€¢Ã Â±ÂÃ Â°Â· Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â°Â²Ã Â±Â Ã Â°Â¨Ã Â°Â¿Ã Â°Â°Ã Â°â€šÃ Â°Â¤Ã Â°Â°Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â°Â¾Ã Â°Â¯Ã Â°Â¨Ã Â°Â¿ Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°Â¹Ã Â°Â¾Ã Â°Â®Ã Â±â‚¬ Ã Â°â€¡Ã Â°ÂµÃ Â±ÂÃ Â°ÂµÃ Â°Â¦Ã Â±Â.',
        english:
            'The app may display AdMob ads, including rewarded ads that can unlock selected premium editor actions without a paid subscription. Rewarded-ad access is not a paid subscription, does not auto-renew, and may be limited by device state, ad availability, network, policy, or fraud checks. Ad availability, ad-skip timing, billing services, Google sign-in, notifications, or Firebase services may depend on third-party providers. The app does not guarantee uninterrupted availability of third-party services.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Account deletion Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â device access',
        english: 'Account Deletion and Device Access',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ account deletion request option Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Delete Ã Â°â€¦Ã Â°Â­Ã Â±ÂÃ Â°Â¯Ã Â°Â°Ã Â±ÂÃ Â°Â¥Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ login access, poster profile data Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â linked app data Ã Â°Â¤Ã Â±Å Ã Â°Â²Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ billing Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ platform-required records Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Â®Ã Â°Â¿Ã Â°Â¤ Ã Â°â€¢Ã Â°Â¾Ã Â°Â²Ã Â°â€š Ã Â°Â¨Ã Â°Â¿Ã Â°Â²Ã Â±ÂÃ Â°Âµ Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'The app provides an account deletion request option. After deletion, login access, poster profile data, and linked app data may be removed. Some billing or platform-required records may be retained for a limited period.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°â€¢Ã Â°Â®Ã Â±ÂÃ Â°Â¯Ã Â±â€šÃ Â°Â¨Ã Â°Â¿Ã Â°Å¸Ã Â±â‚¬ Ã Â°â€¦Ã Â°ÂªÃ Â±ÂÃ Â°Â²Ã Â±â€¹Ã Â°Â¡Ã Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°Â®Ã Â±â€¹Ã Â°Â¡Ã Â°Â°Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â°Ã Â°Â¿Ã Â°ÂªÃ Â±â€¹Ã Â°Â°Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±Â',
        english: 'Community Uploads, Moderation, and Reporting',
      ),
      strings.localized(
        telugu:
            'Users manager review Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š image, quote text Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°Â°Ã Â±â€ Ã Â°â€šÃ Â°Â¡Ã Â±â€š submit Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Quote text optional; manager Ã Â°Â¦Ã Â°Â¾Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ copy/reference Ã Â°â€”Ã Â°Â¾ Ã Â°Â¤Ã Â±â‚¬Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ poster image create/customize Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿ user selected category Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¤Ã Â±â€¡ correct related category Ã Â°Â²Ã Â±â€¹ publish Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Dashboard Ã Â°Â²Ã Â±â€¹ manager Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±ÂÃ Â°Â¨ final category app Ã Â°Â²Ã Â±â€¹ poster Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±â€¡ category Ã Â°â€”Ã Â°Â¾ Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Publication guarantee Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â±Â. Copyright Ã Â°Â²Ã Â±â€¡Ã Â°â€¢Ã Â±ÂÃ Â°â€šÃ Â°Â¡Ã Â°Â¾ third-party content upload Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°â€š, Ã Â°â€¡Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±ÂÃ Â°â€”Ã Â°Â¾ Ã Â°Â¨Ã Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°â€š, abusive/offensive content, deceptive political misuse, spam uploads, repeated low-quality uploads, illegal notices, fake claims Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ rights Ã Â°Â²Ã Â±â€¡Ã Â°Â¨Ã Â°Â¿ material Ã Â°Â¨Ã Â°Â¿Ã Â°Â·Ã Â±â€¡Ã Â°Â§Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿. Managers/admins uploads Ã Â°Â¨Ã Â±Â approve, reject, customize, delay, unpublish Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ remove Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Rejected uploads Ã Â°â€¢Ã Â±Â reason Ã Â°â€¡Ã Â°ÂµÃ Â±ÂÃ Â°ÂµÃ Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Abuse Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ infringement report Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ app support flow Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ ${AppPublicInfo.supportEmail} Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
        english:
            'Users may submit an image, quote text, or both for manager review. Quote text is optional; a manager may copy or use it as reference to create/customize a poster image and publish it in the user-selected category or, when needed, a corrected related category. The final category selected in the dashboard is the category where the poster appears in the app. Publication is not guaranteed. Uploading third-party content without rights, impersonation, abusive or offensive content, deceptive political misuse, spam uploads, repeated low-quality uploads, illegal notices, fake claims, or material you do not have rights to use is prohibited. Managers and admins may approve, reject, customize, delay, unpublish, or remove uploads. Rejected uploads may include a reason. Abusive or infringing content can be reported through the app support flow or by emailing ${AppPublicInfo.supportEmail}.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â¡Ã Â°Â¿Ã Â°ÂµÃ Â±Ë†Ã Â°Â¸Ã Â±Â Ã Â°Â¯Ã Â°Â¾Ã Â°â€¢Ã Â±ÂÃ Â°Â¸Ã Â±â€ Ã Â°Â¸Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¸Ã Â±â€ Ã Â°Â·Ã Â°Â¨Ã Â±ÂÃ Â°Â¸Ã Â±Â',
        english: 'Device Access and Sessions',
      ),
      strings.localized(
        telugu:
            'Ã Â°â€“Ã Â°Â¾Ã Â°Â¤Ã Â°Â¾ Ã Â°Â­Ã Â°Â¦Ã Â±ÂÃ Â°Â°Ã Â°Â¤ Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€™Ã Â°â€¢Ã Â±â€¡ Ã Â°â€“Ã Â°Â¾Ã Â°Â¤Ã Â°Â¾ Ã Â°â€™Ã Â°â€¢Ã Â±â€¡Ã Â°Â¸Ã Â°Â¾Ã Â°Â°Ã Â°Â¿ Ã Â°â€™Ã Â°â€¢ primary device session Ã Â°ÂªÃ Â±Ë† Ã Â°Â®Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¡ Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â°Â¸Ã Â°Â¾Ã Â°â€”Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°â€¦Ã Â°Â¦Ã Â±â€¡ Ã Â°â€“Ã Â°Â¾Ã Â°Â¤Ã Â°Â¾ Ã Â°Â®Ã Â°Â°Ã Â±Å Ã Â°â€¢ primary device Ã Â°ÂªÃ Â±Ë† activate Ã Â°â€¦Ã Â°Â¯Ã Â°Â¿Ã Â°Â¤Ã Â±â€¡ Ã Â°ÂªÃ Â°Â¾Ã Â°Â¤ session sign out Ã Â°â€¢Ã Â°Â¾Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°â€¡Ã Â°Â¦Ã Â°Â¿ account misuse Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â unauthorized access Ã Â°Â¨Ã Â±Â Ã Â°Â¤Ã Â°â€”Ã Â±ÂÃ Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¬Ã Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
        english:
            'For account security, one account may remain active on only one primary device session at a time. If the same account is activated on another primary device, the previous session may be signed out. This helps reduce account misuse and unauthorized access.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â¸Ã Â±â€¡Ã Â°Âµ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â°Â¤ Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Â®Ã Â°Â¿Ã Â°Â¤Ã Â°Â¿',
        english: 'Service Changes and Limitation of Liability',
      ),
      strings.localized(
        telugu:
            'Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â features, prices, designs, assets, fonts, ads, editor tools Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Ë† terms Ã Â°Â¸Ã Â°Â®Ã Â°Â¯Ã Â°Â¾Ã Â°Â¨Ã Â±ÂÃ Â°Â¸Ã Â°Â¾Ã Â°Â°Ã Â°â€š Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Backend assets/categories add, remove, replace, rename Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ reorganize Ã Â°â€¢Ã Â°Â¾Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Technical issues, platform restrictions, ad-fill issues, billing verification delay, backend maintenance, device limits Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ third-party failures Ã Â°ÂµÃ Â°Â²Ã Â±ÂÃ Â°Â² Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ features Ã Â°Â¤Ã Â°Â¾Ã Â°Â¤Ã Â±ÂÃ Â°â€¢Ã Â°Â¾Ã Â°Â²Ã Â°Â¿Ã Â°â€¢Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°Â²Ã Â±â€¡Ã Â°â€¢Ã Â°ÂªÃ Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°Å¡Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°â€š Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±â€¡ Ã Â°ÂªÃ Â°Â°Ã Â°Â¿Ã Â°Â®Ã Â°Â¿Ã Â°Â¤Ã Â°Â¿Ã Â°Â²Ã Â±â€¹ indirect loss, data loss, low-quality source files Ã Â°ÂµÃ Â°Â²Ã Â±ÂÃ Â°Â² export quality loss Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ missed business opportunity Ã Â°â€¢Ã Â±Â Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°Â¬Ã Â°Â¾Ã Â°Â§Ã Â±ÂÃ Â°Â¯Ã Â°Â¤ Ã Â°ÂµÃ Â°Â¹Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¦Ã Â±Â.',
        english:
            'Features, pricing, designs, assets, fonts, ads, editor tools, and these terms may change over time. Backend assets and categories may be added, removed, replaced, renamed, or reorganized. Some features may become temporarily unavailable because of technical issues, platform restrictions, ad-fill issues, billing verification delay, backend maintenance, device limits, or third-party failures. To the extent permitted by law, the app is not liable for indirect loss, data loss, export quality loss caused by low-quality source files, or missed business opportunities.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu:
            'Ã Â°Â¸Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°ÂªÃ Â±Â Ã Â°Â¸Ã Â°Â®Ã Â°Â¾Ã Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â°â€š',
        english: 'Contact Information',
      ),
      strings.localized(
        telugu:
            'Terms, billing, subscriptions, account deletion Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ legal Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¶Ã Â±ÂÃ Â°Â¨Ã Â°Â² Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š ${AppPublicInfo.supportEmail} Ã Â°â€¢Ã Â±Â Ã Â°â€¡Ã Â°Â®Ã Â±â€ Ã Â°Â¯Ã Â°Â¿Ã Â°Â²Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
        english:
            'For terms, billing, subscriptions, account deletion, or legal questions, email ${AppPublicInfo.supportEmail}.',
      ),
    ),
  ];
}
