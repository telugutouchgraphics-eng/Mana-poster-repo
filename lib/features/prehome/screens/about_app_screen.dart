import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  static const String _supportEmail = AppPublicInfo.supportEmail;
  Future<PackageInfo>? _packageInfoFuture;

  Future<void> _openPublicUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          context.strings.localized(
            telugu:
                'Ã Â°Â²Ã Â°Â¿Ã Â°â€šÃ Â°â€¢Ã Â±Â Ã Â°Â¤Ã Â±â€ Ã Â°Â°Ã Â°ÂµÃ Â°Â²Ã Â±â€¡Ã Â°â€¢Ã Â°ÂªÃ Â±â€¹Ã Â°Â¯Ã Â°Â¾Ã Â°â€š. Ã Â°Â®Ã Â°Â³Ã Â±ÂÃ Â°Â²Ã Â±â‚¬ Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¯Ã Â°Â¤Ã Â±ÂÃ Â°Â¨Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
            english: 'Could not open the link. Please try again.',
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final copy = _AboutCopy(strings);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.screenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -90,
            right: -36,
            child: _BlurOrb(size: 180, color: const Color(0x1822C55E)),
          ),
          Positioned(
            top: 130,
            left: -56,
            child: _BlurOrb(size: 140, color: const Color(0x182563EB)),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFFE8F4EE), Color(0xFFFFFFFF)],
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x100F172A),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: const Color(0xD9E5EEF7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x100F172A),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/branding/mana_poster_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  copy.teluguFirstPill,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF166534),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                copy.appName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                copy.heroSubtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF475569),
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      copy.heroBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF334155),
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder<PackageInfo>(
                      future: _packageInfoFuture,
                      builder: (context, snapshot) {
                        final versionName =
                            snapshot.data?.version.trim().isNotEmpty == true
                            ? snapshot.data!.version.trim()
                            : 'Unknown';
                        final buildNumber =
                            snapshot.data?.buildNumber.trim().isNotEmpty == true
                            ? snapshot.data!.buildNumber.trim()
                            : 'Unknown';
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 340;
                            final cardWidth = stacked
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 10) / 2;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                SizedBox(
                                  width: cardWidth,
                                  child: _HeroStatCard(
                                    label: copy.versionPill,
                                    value: versionName,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _HeroStatCard(
                                    label: copy.buildPill,
                                    value: buildNumber,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: copy.whatIsTitle),
              const SizedBox(height: 8),
              _DetailSection(title: copy.whatIsTitle, body: copy.whatIsBody),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.whoForTitle),
              const SizedBox(height: 8),
              _DetailSection(title: copy.whoForTitle, body: copy.whoForBody),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.featuresTitle),
              const SizedBox(height: 8),
              _ChecklistSection(
                title: copy.featuresTitle,
                items: copy.featureItems,
              ),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.flowTitle),
              const SizedBox(height: 8),
              _ChecklistSection(title: copy.flowTitle, items: copy.flowItems),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.languagesTitle),
              const SizedBox(height: 8),
              _ChecklistSection(
                title: copy.languagesTitle,
                items: copy.languageItems,
              ),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.supportTitle),
              const SizedBox(height: 8),
              _DetailSection(
                title: copy.supportTitle,
                body: '${copy.supportBody}\n\n$_supportEmail',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 360;
                  final buttonWidth = stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SizedBox(
                        width: buttonWidth,
                        child: _LegalActionButton(
                          label: copy.privacyButton,
                          icon: Icons.verified_user_outlined,
                          onTap: () =>
                              _openPublicUrl(AppPublicInfo.privacyPolicyUrl),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: _LegalActionButton(
                          label: copy.termsButton,
                          icon: Icons.article_outlined,
                          onTap: () => _openPublicUrl(AppPublicInfo.termsUrl),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xD9E3ECF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.68,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.62,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalActionButton extends StatelessWidget {
  const _LegalActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E8F2)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCopy {
  const _AboutCopy(this.strings);

  final AppStrings strings;

  String get screenTitle => strings.localized(
    telugu:
        'Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°â€”Ã Â±ÂÃ Â°Â°Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿',
    english: 'About App',
    hindi:
        'Ã Â¤ÂÃ Â¤Âª Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â°Ã Â¥â€¡ Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š',
    tamil: 'Ã Â®â€ Ã Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â®Â¿',
    kannada: 'Ã Â²â€¦Ã Â²ÂªÃ Â³Â Ã Â²Â¬Ã Â²â€”Ã Â³ÂÃ Â²â€”Ã Â³â€ ',
    malayalam:
        'Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¿Ã Â´Â¨Ã Âµâ€ Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â±Ã Â´Â¿Ã Â´Å¡Ã ÂµÂÃ Â´Å¡Ã ÂµÂ',
  );

  String get appName => AppPublicInfo.appName;

  String get heroSubtitle => strings.localized(
    telugu:
        'Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°Â¸Ã Â±ÂÃ Â°Â²Ã Â°Â­Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â°Ã Â±â€šÃ Â°ÂªÃ Â±Å Ã Â°â€šÃ Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±â€¡ Ã Â°Â¤Ã Â±â€ Ã Â°Â²Ã Â±ÂÃ Â°â€”Ã Â±ÂÃ Â°Â¨Ã Â±â€¡ Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â§Ã Â°Â¾Ã Â°Â¨Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°â€°Ã Â°â€šÃ Â°Å¡Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â',
    english: 'A Telugu-first app for creating posters with ease',
    hindi:
        'Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤â€ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â¨Ã Â¥â‚¬ Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤Â¤Ã Â¥â€¡Ã Â¤Â²Ã Â¥ÂÃ Â¤â€”Ã Â¥Â-Ã Â¤Â«Ã Â¤Â°Ã Â¥ÂÃ Â¤Â¸Ã Â¥ÂÃ Â¤Å¸ Ã Â¤ÂÃ Â¤Âª',
    tamil:
        'Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë† Ã Â®Å½Ã Â®Â³Ã Â®Â¿Ã Â®Â¤Ã Â®Â¾Ã Â®â€¢ Ã Â®â€°Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â®Â¾Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Â¤Ã Â¯â€ Ã Â®Â²Ã Â¯ÂÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â-Ã Â®Â®Ã Â¯ÂÃ Â®Â¤Ã Â®Â²Ã Â¯Â Ã Â®â€ Ã Â®ÂªÃ Â¯Â',
    kannada:
        'Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¸Ã Â³ÂÃ Â²Â²Ã Â²Â­Ã Â²ÂµÃ Â²Â¾Ã Â²â€”Ã Â²Â¿ Ã Â²Â°Ã Â²Å¡Ã Â²Â¿Ã Â²Â¸Ã Â²Â²Ã Â³Â Ã Â²Â¤Ã Â³â€ Ã Â²Â²Ã Â³ÂÃ Â²â€”Ã Â³Â-Ã Â²Â«Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â³Â Ã Â²â€ Ã Â²ÂªÃ Â³Â',
    malayalam:
        'Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾ Ã Â´Å½Ã Â´Â³Ã ÂµÂÃ Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¤Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´Â±Ã Â´Â¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã ÂµÂ» Ã Â´Â¸Ã Â´Â¹Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨ Ã Â´Â¤Ã Âµâ€ Ã Â´Â²Ã ÂµÂÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ-Ã Â´Â«Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ',
  );

  String get heroBody => strings.localized(
    telugu:
        'Mana Poster Ai Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ Ã Â°Â¶Ã Â±ÂÃ Â°Â­Ã Â°Â¾Ã Â°â€¢Ã Â°Â¾Ã Â°â€šÃ Â°â€¢Ã Â±ÂÃ Â°Â·Ã Â°Â²Ã Â±Â, Ã Â°ÂªÃ Â°â€šÃ Â°Â¡Ã Â±ÂÃ Â°â€” Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â°Â¾Ã Â°Â° Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Å¡Ã Â°Â¾Ã Â°Â° Ã Â°Â¡Ã Â°Â¿Ã Â°Å“Ã Â±Ë†Ã Â°Â¨Ã Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°Â­Ã Â°â€¢Ã Â±ÂÃ Â°Â¤Ã Â°Â¿ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¤Ã Â±ÂÃ Â°Â¯Ã Â±â€¡Ã Â°â€¢ Ã Â°Â¸Ã Â°â€šÃ Â°Â¦Ã Â°Â°Ã Â±ÂÃ Â°Â­Ã Â°Â¾Ã Â°Â² Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°ÂµÃ Â°â€šÃ Â°Å¸Ã Â°Â¿ Ã Â°ÂµÃ Â°Â¾Ã Â°Å¸Ã Â°Â¿Ã Â°Â¨Ã Â°Â¿ Ã Â°ÂµÃ Â±â€¡Ã Â°â€”Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ Ã Â°Â®Ã Â±â‚¬ Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â°Â¤Ã Â±â€¹ Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°â€¢Ã Â±ÂÃ Â°Â¤Ã Â°Â¿Ã Â°â€”Ã Â°Â¤Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°Â®Ã Â±Å Ã Â°Â¬Ã Â±Ë†Ã Â°Â²Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹Ã Â°Â¨Ã Â±â€¡ Ã Â°Å¡Ã Â±â€šÃ Â°Â¸Ã Â°Â¿, Ã Â°Å½Ã Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€¢ Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿, Ã Â°Â¸Ã Â°ÂµÃ Â°Â°Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿, Ã Â°â€¡Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â°Â¤Ã Â±â€¹ Ã Â°ÂªÃ Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Â¡Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°Â¸Ã Â°Â°Ã Â°Â³Ã Â°Â®Ã Â±Ë†Ã Â°Â¨ Ã Â°ÂªÃ Â°Â¨Ã Â°Â¿ Ã Â°ÂµÃ Â°Â¿Ã Â°Â§Ã Â°Â¾Ã Â°Â¨Ã Â°â€š Ã Â°Ë† Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
    english:
        'Mana Poster Ai helps users quickly choose, personalize, edit, export, and share greeting posters, festival designs, business promotions, devotional content, and other occasion-based posters. The app combines ready-made posters with a mobile editor, premium assets, Telugu fonts, background removal, and export tools in one place.',
    hindi:
        'Mana Poster Ai Ã Â¤â€¢Ã Â¥â‚¬ Ã Â¤Â®Ã Â¤Â¦Ã Â¤Â¦ Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â­Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â®Ã Â¤Â¨Ã Â¤Â¾ Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â°, Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â¯Ã Â¥â€¹Ã Â¤Â¹Ã Â¤Â¾Ã Â¤Â° Ã Â¤Â¡Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â¨, Ã Â¤Â¬Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¨Ã Â¥â€¡Ã Â¤Â¸ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â®Ã Â¥â€¹Ã Â¤Â¶Ã Â¤Â¨ Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â°, Ã Â¤Â­Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â¤Ã Â¤Â¿ Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤â€Ã Â¤Â° Ã Â¤â€“Ã Â¤Â¾Ã Â¤Â¸ Ã Â¤Â®Ã Â¥Å’Ã Â¤â€¢Ã Â¥â€¹Ã Â¤â€š Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤Å“Ã Â¤Â²Ã Â¥ÂÃ Â¤Â¦Ã Â¥â‚¬ Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¤â€¢Ã Â¤Â° Ã Â¤â€¦Ã Â¤ÂªÃ Â¤Â¨Ã Â¥â‚¬ Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â¨Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â¥ Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Å“Ã Â¥â‚¬ Ã Â¤Â°Ã Â¥â€šÃ Â¤Âª Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¤Ã Â¥Ë†Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â° Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤ Ã Â¤Â®Ã Â¥â€¹Ã Â¤Â¬Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤ÂªÃ Â¤Â° Ã Â¤Â¹Ã Â¥â‚¬ Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¤Â¨Ã Â¤Â¾, Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¤Â¨Ã Â¤Â¾, Ã Â¤Â¸Ã Â¤â€šÃ Â¤ÂªÃ Â¤Â¾Ã Â¤Â¦Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¨Ã Â¤Â¾ Ã Â¤â€Ã Â¤Â° Ã Â¤Â¸Ã Â¤Â¾Ã Â¤ÂÃ Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¨Ã Â¤Â¾ Ã Â¤â€ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â¨ Ã Â¤Â¬Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
    tamil:
        'Mana Poster Ai Ã Â®Â®Ã Â¯â€šÃ Â®Â²Ã Â®Â®Ã Â¯Â Ã Â®ÂµÃ Â®Â¾Ã Â®Â´Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯Â Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®Â¤Ã Â®Â¿Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â®Â¿Ã Â®Â´Ã Â®Â¾ Ã Â®ÂµÃ Â®Å¸Ã Â®Â¿Ã Â®ÂµÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®ÂµÃ Â®Â£Ã Â®Â¿Ã Â®â€¢ Ã Â®ÂµÃ Â®Â¿Ã Â®Â³Ã Â®Â®Ã Â¯ÂÃ Â®ÂªÃ Â®Â° Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®ÂªÃ Â®â€¢Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿ Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Å¡Ã Â®Â¿Ã Â®Â±Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯Â Ã Â®Â¨Ã Â®Â¾Ã Â®Â³Ã Â¯Â Ã Â®ÂµÃ Â®Å¸Ã Â®Â¿Ã Â®ÂµÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë† Ã Â®ÂµÃ Â®Â¿Ã Â®Â°Ã Â¯Ë†Ã Â®ÂµÃ Â®Â¾Ã Â®â€¢ Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â¯Â Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¤Ã Â¯Â, Ã Â®â€°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯ÂÃ Â®Å¸Ã Â®Â©Ã Â¯Â Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â®Â¾Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â. Ã Â®Â®Ã Â¯Å Ã Â®ÂªÃ Â¯Ë†Ã Â®Â²Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®ÂªÃ Â®Â¾Ã Â®Â°Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯Â, Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â¯Â Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¤Ã Â¯Â, Ã Â®Â¤Ã Â®Â¿Ã Â®Â°Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿, Ã Â®ÂªÃ Â®â€¢Ã Â®Â¿Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â®Â¤Ã Â®Â±Ã Â¯ÂÃ Â®â€¢Ã Â®Â¾Ã Â®Â© Ã Â®Å½Ã Â®Â³Ã Â®Â¿Ã Â®Â¯ Ã Â®Â¨Ã Â®Å¸Ã Â¯Ë†Ã Â®Â®Ã Â¯ÂÃ Â®Â±Ã Â¯Ë† Ã Â®â€¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤ Ã Â®â€ Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®â€°Ã Â®Â³Ã Â¯ÂÃ Â®Â³Ã Â®Â¤Ã Â¯Â.',
    kannada:
        'Mana Poster Ai Ã Â²Â®Ã Â³â€šÃ Â²Â²Ã Â²â€¢ Ã Â²Â¶Ã Â³ÂÃ Â²Â­Ã Â²Â¾Ã Â²Â¶Ã Â²Â¯ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²Â¹Ã Â²Â¬Ã Â³ÂÃ Â²Â¬Ã Â²Â¦ Ã Â²ÂµÃ Â²Â¿Ã Â²Â¨Ã Â³ÂÃ Â²Â¯Ã Â²Â¾Ã Â²Â¸Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²ÂµÃ Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¹Ã Â²Â¾Ã Â²Â° Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Å¡Ã Â²Â¾Ã Â²Â° Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²Â­Ã Â²â€¢Ã Â³ÂÃ Â²Â¤Ã Â²Â¿Ã Â²ÂªÃ Â²Â° Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²Â¶Ã Â³â€¡Ã Â²Â· Ã Â²Â¸Ã Â²â€šÃ Â²Â¦Ã Â²Â°Ã Â³ÂÃ Â²Â­Ã Â²â€”Ã Â²Â³ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²ÂµÃ Â³â€¡Ã Â²â€”Ã Â²ÂµÃ Â²Â¾Ã Â²â€”Ã Â²Â¿ Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿ Ã Â²Â¨Ã Â²Â¿Ã Â²Â®Ã Â³ÂÃ Â²Â® Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â²Â°Ã Â²â€”Ã Â²Â³Ã Â³Å Ã Â²â€šÃ Â²Â¦Ã Â²Â¿Ã Â²â€”Ã Â³â€  Ã Â²ÂµÃ Â³Ë†Ã Â²Â¯Ã Â²â€¢Ã Â³ÂÃ Â²Â¤Ã Â²Â¿Ã Â²â€¢Ã Â²â€”Ã Â³Å Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â. Ã Â²Â®Ã Â³Å Ã Â²Â¬Ã Â³Ë†Ã Â²Â²Ã Â³ÂÃ¢â‚¬Å’Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â³â€¡ Ã Â²Â¨Ã Â³â€¹Ã Â²Â¡Ã Â²Â²Ã Â³Â, Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â²Ã Â³Â, Ã Â²Â¤Ã Â²Â¿Ã Â²Â¦Ã Â³ÂÃ Â²Â¦Ã Â³ÂÃ Â²ÂªÃ Â²Â¡Ã Â²Â¿ Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â²Ã Â³Â Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â¹Ã Â²â€šÃ Â²Å¡Ã Â²Â¿Ã Â²â€¢Ã Â³Å Ã Â²Â³Ã Â³ÂÃ Â²Â³Ã Â²Â²Ã Â³Â Ã Â²Â¸Ã Â²Â°Ã Â²Â³Ã Â²ÂµÃ Â²Â¾Ã Â²Â¦ Ã Â²â€¢Ã Â³ÂÃ Â²Â°Ã Â²Â®Ã Â²ÂµÃ Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Ë† Ã Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²Â¨Ã Â³â‚¬Ã Â²Â¡Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ .',
    malayalam:
        'Mana Poster Ai Ã Â´â€°Ã Â´ÂªÃ Â´Â¯Ã Âµâ€¹Ã Â´â€”Ã Â´Â¿Ã Â´Å¡Ã ÂµÂÃ Â´Å¡Ã ÂµÂ Ã Â´â€ Ã Â´Â¶Ã Â´â€šÃ Â´Â¸Ã Â´Â¾ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾, Ã Â´â€°Ã Â´Â¤Ã ÂµÂÃ Â´Â¸Ã Â´Âµ Ã Â´Â¡Ã Â´Â¿Ã Â´Â¸Ã ÂµË†Ã Â´Â¨Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾, Ã Â´Â¬Ã Â´Â¿Ã Â´Â¸Ã Â´Â¿Ã Â´Â¨Ã Â´Â¸Ã ÂµÂ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â®Ã Âµâ€¹Ã Â´Â·Ã ÂµÂ» Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾, Ã Â´Â­Ã Â´â€¢Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´ÂªÃ Â´Â°Ã Â´Â®Ã Â´Â¾Ã Â´Â¯ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾, Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¤Ã ÂµÂÃ Â´Â¯Ã Âµâ€¡Ã Â´â€¢ Ã Â´Â¦Ã Â´Â¿Ã Â´ÂµÃ Â´Â¸Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â³Ã Â´Â¿Ã Â´Â²Ã Âµâ€  Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ Ã Â´ÂµÃ Âµâ€¡Ã Â´â€”Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿ Ã Â´Â¨Ã Â´Â¿Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â³Ã ÂµÂÃ Â´Å¸Ã Âµâ€  Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´Å¡Ã Âµâ€¡Ã ÂµÂ¼Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã ÂµÂ Ã Â´ÂµÃ ÂµÂÃ Â´Â¯Ã Â´â€¢Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´ÂªÃ Â´Â°Ã Â´Â®Ã Â´Â¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š. Ã Â´Â®Ã ÂµÅ Ã Â´Â¬Ã ÂµË†Ã Â´Â²Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¤Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Âµâ€  Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã ÂµÂÃ Â´â€¢, Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢, Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã ÂµÂÃ Â´Â¤Ã ÂµÂÃ Â´Â¤Ã ÂµÂÃ Â´â€¢, Ã Â´ÂªÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã Â´Å¸Ã ÂµÂÃ Â´â€¢ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨ Ã Â´Â²Ã Â´Â³Ã Â´Â¿Ã Â´Â¤Ã Â´Â®Ã Â´Â¾Ã Â´Â¯ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´ÂµÃ ÂµÆ’Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿ Ã Â´Â°Ã Âµâ‚¬Ã Â´Â¤Ã Â´Â¿Ã Â´Â¯Ã Â´Â¾Ã Â´Â£Ã ÂµÂ Ã Â´Ë† Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¿Ã Â´Â¨Ã ÂµÂÃ Â´Â±Ã Âµâ€  Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¤Ã ÂµÂÃ Â´Â¯Ã Âµâ€¡Ã Â´â€¢Ã Â´Â¤.',
  );

  String get teluguFirstPill => strings.localized(
    telugu:
        'Ã Â°Â¤Ã Â±â€ Ã Â°Â²Ã Â±ÂÃ Â°â€”Ã Â±Â Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â§Ã Â°Â¾Ã Â°Â¨ Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â­Ã Â°ÂµÃ Â°â€š',
    english: 'Telugu-first experience',
    hindi:
        'Ã Â¤Â¤Ã Â¥â€¡Ã Â¤Â²Ã Â¥ÂÃ Â¤â€”Ã Â¥Â-Ã Â¤Â«Ã Â¤Â°Ã Â¥ÂÃ Â¤Â¸Ã Â¥ÂÃ Â¤Å¸ Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â­Ã Â¤Âµ',
    tamil:
        'Ã Â®Â¤Ã Â¯â€ Ã Â®Â²Ã Â¯ÂÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â-Ã Â®Â®Ã Â¯ÂÃ Â®Â¤Ã Â®Â²Ã Â¯Â Ã Â®â€¦Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®ÂµÃ Â®Â®Ã Â¯Â',
    kannada:
        'Ã Â²Â¤Ã Â³â€ Ã Â²Â²Ã Â³ÂÃ Â²â€”Ã Â³Â-Ã Â²Â«Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â³Â Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²Â­Ã Â²Âµ',
    malayalam:
        'Ã Â´Â¤Ã Âµâ€ Ã Â´Â²Ã ÂµÂÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ-Ã Â´Â«Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ Ã Â´â€¦Ã Â´Â¨Ã ÂµÂÃ Â´Â­Ã Â´ÂµÃ Â´â€š',
  );

  String get versionPill => strings.localized(
    telugu: 'Ã Â°â€ Ã Â°ÂµÃ Â±Æ’Ã Â°Â¤Ã Â°Â¿',
    english: 'Version',
    hindi: 'Ã Â¤ÂµÃ Â¤Â°Ã Â¥ÂÃ Â¤Å“Ã Â¤Â¼Ã Â¤Â¨',
    tamil: 'Ã Â®ÂªÃ Â®Â¤Ã Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯Â',
    kannada: 'Ã Â²â€ Ã Â²ÂµÃ Â³Æ’Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¿',
    malayalam: 'Ã Â´ÂµÃ ÂµÂ¼Ã Â´Â·Ã ÂµÂ»',
  );

  String get buildPill => strings.localized(
    telugu:
        'Ã Â°Â¨Ã Â°Â¿Ã Â°Â°Ã Â±ÂÃ Â°Â®Ã Â°Â¾Ã Â°Â£ Ã Â°Â¸Ã Â°â€šÃ Â°â€“Ã Â±ÂÃ Â°Â¯',
    english: 'Build',
    hindi: 'Ã Â¤Â¬Ã Â¤Â¿Ã Â¤Â²Ã Â¥ÂÃ Â¤Â¡',
    tamil: 'Ã Â®ÂªÃ Â®Â¿Ã Â®Â²Ã Â¯ÂÃ Â®Å¸Ã Â¯Â',
    kannada: 'Ã Â²Â¬Ã Â²Â¿Ã Â²Â²Ã Â³ÂÃ Â²Â¡Ã Â³Â',
    malayalam: 'Ã Â´Â¬Ã Â´Â¿Ã ÂµÂ½Ã Â´Â¡Ã ÂµÂ',
  );

  String get whatIsTitle => strings.localized(
    telugu:
        'Ã Â°Ë† Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°ÂÃ Â°Â®Ã Â°Â¿ Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿',
    english: 'What this app does',
    hindi:
        'Ã Â¤Â¯Ã Â¤Â¹ Ã Â¤ÂÃ Â¤Âª Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†',
    tamil:
        'Ã Â®â€¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤ Ã Â®â€ Ã Â®ÂªÃ Â¯Â Ã Â®Å½Ã Â®Â©Ã Â¯ÂÃ Â®Â© Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®â€¢Ã Â®Â¿Ã Â®Â±Ã Â®Â¤Ã Â¯Â',
    kannada:
        'Ã Â²Ë† Ã Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²ÂÃ Â²Â¨Ã Â³Â Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ ',
    malayalam:
        'Ã Â´Ë† Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¤Ã ÂµÂ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã ÂµÂ',
  );

  String get whatIsBody => strings.localized(
    telugu:
        'Ã Â°â€¡Ã Â°Â¦Ã Â°Â¿ Ã Â°Â®Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°â€”Ã Â°Â¾Ã Â°Â¨Ã Â±â€¡ Ã Â°Â¸Ã Â°Â¿Ã Â°Â¦Ã Â±ÂÃ Â°Â§Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â°Â¨Ã Â±Â Ã Â°Å¡Ã Â±â€šÃ Â°Â¸Ã Â°Â¿, Ã Â°Â®Ã Â±â‚¬ Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹, Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â°Â¾Ã Â°Â° Ã Â°ÂªÃ Â±â€¡Ã Â°Â°Ã Â±Â, Ã Â°ÂµÃ Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â¸Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¨ Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°â€¢Ã Â±ÂÃ Â°Â¤Ã Â°Â¿Ã Â°â€”Ã Â°Â¤ Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°Å“Ã Â±â€¹Ã Â°Â¡Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿, Ã Â°Â®Ã Â±â‚¬ Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°Â¤Ã Â°â€”Ã Â±ÂÃ Â°â€”Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â±ÂÃ Â°â€”Ã Â°Â¾ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±â€¡ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±Â Ã Â°Â¤Ã Â°Â¯Ã Â°Â¾Ã Â°Â°Ã Â±â‚¬ Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â. Ã Â°Â¨Ã Â°Â®Ã Â±â€šÃ Â°Â¨Ã Â°Â¾Ã Â°Â²Ã Â±Â, Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Å Ã Â°Â«Ã Â±Ë†Ã Â°Â²Ã Â±Â Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â, Ã Â°Â¸Ã Â°Â¬Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â°Ã Â°Â¿Ã Â°ÂªÃ Â±ÂÃ Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°Â¸Ã Â°Â®Ã Â°Â¾Ã Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â°â€š, Ã Â°Â¸Ã Â°Â¹Ã Â°Â¾Ã Â°Â¯Ã Â°â€š Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¨Ã Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°Â¯ Ã Â°Â¸Ã Â°Â®Ã Â°Â¾Ã Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â°â€š Ã Â°â€™Ã Â°â€¢Ã Â±â€¡ Ã Â°Å¡Ã Â±â€¹Ã Â°Å¸ Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
    english:
        'This is a poster creation app where users can choose ready-made designs and personalize them with their photo, business name, WhatsApp details, and other relevant information. The editor also supports text layers, photo layers, brushes, layer effects, PSD/TIFF import where supported, premium downloadable assets, Telugu font access, background removal, save/export workflows, subscription information, help, and legal access in one place.',
    hindi:
        'Ã Â¤Â¯Ã Â¤Â¹ Ã Â¤ÂÃ Â¤â€¢ Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¿Ã Â¤ÂÃ Â¤Â¶Ã Â¤Â¨ Ã Â¤ÂÃ Â¤Âª Ã Â¤Â¹Ã Â¥Ë† Ã Â¤Å“Ã Â¤Â¿Ã Â¤Â¸Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€”Ã Â¤â€¢Ã Â¤Â°Ã Â¥ÂÃ Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¤Ã Â¥Ë†Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â° Ã Â¤Â¡Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â¨ Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¤â€¢Ã Â¤Â° Ã Â¤â€¦Ã Â¤ÂªÃ Â¤Â¨Ã Â¥â‚¬ Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹, Ã Â¤Â¬Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¨Ã Â¥â€¡Ã Â¤Â¸ Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â®, Ã Â¤ÂµÃ Â¥ÂÃ Â¤Â¹Ã Â¤Â¾Ã Â¤Å¸Ã Â¥ÂÃ Â¤Â¸Ã Â¤ÂÃ Â¤Âª Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â¨Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤â€Ã Â¤Â° Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¯ Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â°Ã Â¥â€šÃ Â¤Â°Ã Â¥â‚¬ Ã Â¤ÂµÃ Â¤Â¿Ã Â¤ÂµÃ Â¤Â°Ã Â¤Â£ Ã Â¤Å“Ã Â¥â€¹Ã Â¤Â¡Ã Â¤Â¼ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤ Ã Â¤Å¸Ã Â¥â€¡Ã Â¤Â®Ã Â¥ÂÃ Â¤ÂªÃ Â¤Â²Ã Â¥â€¡Ã Â¤Å¸Ã Â¥ÂÃ Â¤Â¸, Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â¨Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¥â‚¬, Ã Â¤Â¸Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â¸Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¿Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¶Ã Â¤Â¨ Ã Â¤ÂµÃ Â¤Â¿Ã Â¤ÂµÃ Â¤Â°Ã Â¤Â£, Ã Â¤Â¸Ã Â¤Â¹Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤â€Ã Â¤Â° Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â¨Ã Â¥â€šÃ Â¤Â¨Ã Â¥â‚¬ Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â¨Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤ÂÃ Â¤â€¢ Ã Â¤Â¹Ã Â¥â‚¬ Ã Â¤Å“Ã Â¤â€”Ã Â¤Â¹ Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â²Ã Â¤Â¤Ã Â¥â‚¬ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
    tamil:
        'Ã Â®â€¡Ã Â®Â¤Ã Â¯Â Ã Â®Â¤Ã Â®Â¯Ã Â®Â¾Ã Â®Â°Ã Â®Â¾Ã Â®â€¢ Ã Â®â€°Ã Â®Â³Ã Â¯ÂÃ Â®Â³ Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯Â Ã Â®ÂµÃ Â®Å¸Ã Â®Â¿Ã Â®ÂµÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë†Ã Â®Â¤Ã Â¯Â Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â¯Â Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¤Ã Â¯Â, Ã Â®â€°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®ÂªÃ Â¯ÂÃ Â®â€¢Ã Â¯Ë†Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â®Â®Ã Â¯Â, Ã Â®ÂµÃ Â®Â£Ã Â®Â¿Ã Â®â€¢Ã Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â¯â€ Ã Â®Â¯Ã Â®Â°Ã Â¯Â, Ã Â®ÂµÃ Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®Â¸Ã Â¯ÂÃ Â®â€¦Ã Â®ÂªÃ Â¯Â Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Â¤Ã Â¯â€¡Ã Â®ÂµÃ Â¯Ë†Ã Â®Â¯Ã Â®Â¾Ã Â®Â© Ã Â®ÂªÃ Â®Â¿Ã Â®Â± Ã Â®Â¤Ã Â®â€¢Ã Â®ÂµÃ Â®Â²Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë†Ã Â®Å¡Ã Â¯Â Ã Â®Å¡Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯Â Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â®Â¾Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢ Ã Â®â€°Ã Â®Â¤Ã Â®ÂµÃ Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯Â Ã Â®â€°Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â®Â¾Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®â€ Ã Â®ÂªÃ Â¯Â. Ã Â®Å¸Ã Â¯â€ Ã Â®Â®Ã Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®Â³Ã Â¯â€¡Ã Â®Å¸Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®Å¡Ã Â¯ÂÃ Â®Â¯Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â° Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®Å¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â®Â¾ Ã Â®Â¤Ã Â®â€¢Ã Â®ÂµÃ Â®Â²Ã Â¯Â, Ã Â®â€°Ã Â®Â¤Ã Â®ÂµÃ Â®Â¿ Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Å¡Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸ Ã Â®Â¤Ã Â®â€¢Ã Â®ÂµÃ Â®Â²Ã Â¯Â Ã Â®â€¦Ã Â®Â©Ã Â¯Ë†Ã Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®â€™Ã Â®Â°Ã Â¯â€¡ Ã Â®â€¡Ã Â®Å¸Ã Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®â€¢Ã Â®Â¿Ã Â®Å¸Ã Â¯Ë†Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â.',
    kannada:
        'Ã Â²â€¡Ã Â²Â¦Ã Â³Â Ã Â²Â¸Ã Â²Â¿Ã Â²Â¦Ã Â³ÂÃ Â²Â§ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²Â¨Ã Â³ÂÃ Â²Â¯Ã Â²Â¾Ã Â²Â¸Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿, Ã Â²Â¨Ã Â²Â¿Ã Â²Â®Ã Â³ÂÃ Â²Â® Ã Â²Â«Ã Â³â€¹Ã Â²Å¸Ã Â³â€¹, Ã Â²ÂµÃ Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¹Ã Â²Â¾Ã Â²Â°Ã Â²Â¦ Ã Â²Â¹Ã Â³â€ Ã Â²Â¸Ã Â²Â°Ã Â³Â, Ã Â²ÂµÃ Â²Â¾Ã Â²Å¸Ã Â³ÂÃ Â²Â¸Ã Â³ÂÃ Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â²Â°Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²â€¦Ã Â²â€”Ã Â²Â¤Ã Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¾Ã Â²Â¦ Ã Â²â€¡Ã Â²Â¤Ã Â²Â°Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¹Ã Â²Â¿Ã Â²Â¤Ã Â²Â¿Ã Â²Â¯Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¸Ã Â³â€¡Ã Â²Â°Ã Â²Â¿Ã Â²Â¸Ã Â²Â¿ Ã Â²ÂµÃ Â³Ë†Ã Â²Â¯Ã Â²â€¢Ã Â³ÂÃ Â²Â¤Ã Â²Â¿Ã Â²â€¢Ã Â²â€”Ã Â³Å Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â²Â²Ã Â³Â Ã Â²Â¸Ã Â²Â¹Ã Â²Â¾Ã Â²Â¯ Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â³ÂÃ Â²Âµ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³Â Ã Â²Â¸Ã Â³Æ’Ã Â²Â·Ã Â³ÂÃ Â²Å¸Ã Â²Â¿ Ã Â²â€ Ã Â²ÂªÃ Â³Â. Ã Â²Å¸Ã Â³â€ Ã Â²â€šÃ Â²ÂªÃ Â³ÂÃ Â²Â²Ã Â³â€¡Ã Â²Å¸Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â³Å Ã Â²Â«Ã Â³Ë†Ã Â²Â²Ã Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â²Â°Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²Å¡Ã Â²â€šÃ Â²Â¦Ã Â²Â¾Ã Â²Â¦Ã Â²Â¾Ã Â²Â°Ã Â²Â¿Ã Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¹Ã Â²Â¿Ã Â²Â¤Ã Â²Â¿, Ã Â²Â¸Ã Â²Â¹Ã Â²Â¾Ã Â²Â¯ Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²â€¢Ã Â²Â¾Ã Â²Â¨Ã Â³â€šÃ Â²Â¨Ã Â³Â Ã Â²Â®Ã Â²Â¾Ã Â²Â¹Ã Â²Â¿Ã Â²Â¤Ã Â²Â¿ Ã Â²Å½Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²ÂµÃ Â³â€š Ã Â²â€™Ã Â²â€šÃ Â²Â¦Ã Â³â€¡ Ã Â²Â¸Ã Â³ÂÃ Â²Â¥Ã Â²Â³Ã Â²Â¦Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²Â²Ã Â²Â­Ã Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¿Ã Â²Â°Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²ÂµÃ Â³â€ .',
    malayalam:
        'Ã Â´â€¡Ã Â´Â¤Ã ÂµÂ Ã Â´Â¤Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´Â±Ã Â´Â¾Ã Â´Â¯ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ¼ Ã Â´Â°Ã Âµâ€šÃ Â´ÂªÃ Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿, Ã Â´Â¨Ã Â´Â¿Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â³Ã ÂµÂÃ Â´Å¸Ã Âµâ€  Ã Â´Â«Ã Âµâ€¹Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Âµâ€¹, Ã Â´Â¬Ã Â´Â¿Ã Â´Â¸Ã Â´Â¿Ã Â´Â¨Ã Â´Â¸Ã ÂµÂ Ã Â´ÂªÃ Âµâ€¡Ã Â´Â°Ã ÂµÂ, Ã Â´ÂµÃ Â´Â¾Ã Â´Å¸Ã ÂµÂÃ¢â‚¬Å’Ã Â´Â¸Ã ÂµÂÃ Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾, Ã Â´â€ Ã Â´ÂµÃ Â´Â¶Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â¯ Ã Â´Â®Ã Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ Ã Â´ÂµÃ Â´Â¿Ã Â´Â¶Ã Â´Â¦Ã Â´Â¾Ã Â´â€šÃ Â´Â¶Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ Ã Â´Å¡Ã Âµâ€¡Ã ÂµÂ¼Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã ÂµÂ Ã Â´ÂµÃ ÂµÂÃ Â´Â¯Ã Â´â€¢Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´ÂªÃ Â´Â°Ã Â´Â®Ã Â´Â¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã ÂµÂ» Ã Â´Â¸Ã Â´Â¹Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ¼ Ã Â´Â¸Ã ÂµÆ’Ã Â´Â·Ã ÂµÂÃ Â´Å¸Ã Â´Â¿ Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¾Ã Â´Â£Ã ÂµÂ. Ã Â´Å¸Ã Âµâ€ Ã Â´â€šÃ Â´ÂªÃ ÂµÂÃ Â´Â²Ã Âµâ€¡Ã Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾, Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã ÂµÅ Ã Â´Â«Ã ÂµË†Ã ÂµÂ½ Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾, Ã Â´Â¸Ã Â´Â¬Ã ÂµÂÃ Â´Â¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â°Ã Â´Â¿Ã Â´ÂªÃ ÂµÂÃ Â´Â·Ã ÂµÂ» Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â€š, Ã Â´Â¸Ã Â´Â¹Ã Â´Â¾Ã Â´Â¯Ã Â´â€š, Ã Â´Â¨Ã Â´Â¿Ã Â´Â¯Ã Â´Â® Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ Ã Â´â€™Ã Â´Â±Ã ÂµÂÃ Â´Â± Ã Â´Â¸Ã ÂµÂÃ Â´Â¥Ã Â´Â²Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã ÂµÂ Ã Â´Â²Ã Â´Â­Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â£Ã ÂµÂ.',
  );

  String get whoForTitle => strings.localized(
    telugu:
        'Ã Â°Å½Ã Â°ÂµÃ Â°Â°Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°ÂªÃ Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿',
    english: 'Who it is for',
    hindi:
        'Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â¸Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€”Ã Â¥â‚¬ Ã Â¤Â¹Ã Â¥Ë†',
    tamil:
        'Ã Â®Â¯Ã Â®Â¾Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â Ã Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â®Ã Â¯Â',
    kannada:
        'Ã Â²Â¯Ã Â²Â¾Ã Â²Â°Ã Â²Â¿Ã Â²â€”Ã Â³â€  Ã Â²â€°Ã Â²ÂªÃ Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³ÂÃ Â²Â¤',
    malayalam:
        'Ã Â´â€ Ã ÂµÂ¼Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´Â£Ã ÂµÂ Ã Â´â€°Ã Â´ÂªÃ Â´â€¢Ã Â´Â¾Ã Â´Â°Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¤Ã ÂµÂ',
  );

  String get whoForBody => strings.localized(
    telugu:
        'Ã Â°Â°Ã Â±â€¹Ã Â°Å“Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â±â‚¬ Ã Â°Â¶Ã Â±ÂÃ Â°Â­Ã Â°Â¾Ã Â°â€¢Ã Â°Â¾Ã Â°â€šÃ Â°â€¢Ã Â±ÂÃ Â°Â·Ã Â°Â²Ã Â±Â Ã Â°ÂªÃ Â°â€šÃ Â°ÂªÃ Â±â€¡ Ã Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â±Â, Ã Â°Å¡Ã Â°Â¿Ã Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â°Â¾Ã Â°Â°Ã Â°Â¾Ã Â°Â² Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â®Ã Â±â€¹Ã Â°Â·Ã Â°Â¨Ã Â°Â²Ã Â±Â Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¨ Ã Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â±Â, Ã Â°Â­Ã Â°â€¢Ã Â±ÂÃ Â°Â¤Ã Â°Â¿ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¤Ã Â±ÂÃ Â°Â¯Ã Â±â€¡Ã Â°â€¢ Ã Â°Â¦Ã Â°Â¿Ã Â°Â¨Ã Â±â€¹Ã Â°Â¤Ã Â±ÂÃ Â°Â¸Ã Â°Âµ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°Â·Ã Â±â€¡Ã Â°Â°Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±â€¡ Ã Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â±Â, Ã Â°Â¤Ã Â°Â® Ã Â°ÂªÃ Â±â€¡Ã Â°Â°Ã Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â°Â¾Ã Â°Â° Ã Â°â€”Ã Â±ÂÃ Â°Â°Ã Â±ÂÃ Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â¤Ã Â±â€¹ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±Â Ã Â°Â¤Ã Â°Â¯Ã Â°Â¾Ã Â°Â°Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¾Ã Â°Â²Ã Â°Â¨Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±â€¡ Ã Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â±Â Ã Â°Ë† Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â¨Ã Â±Â Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
    english:
        'This app is useful for people who share daily greetings, create posters for small businesses, publish devotional or occasion-based posts, or want personalized posters with their own name or business identity.',
    hindi:
        'Ã Â¤Â¯Ã Â¤Â¹ Ã Â¤ÂÃ Â¤Âª Ã Â¤â€°Ã Â¤Â¨ Ã Â¤Â²Ã Â¥â€¹Ã Â¤â€”Ã Â¥â€¹Ã Â¤â€š Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€”Ã Â¥â‚¬ Ã Â¤Â¹Ã Â¥Ë† Ã Â¤Å“Ã Â¥â€¹ Ã Â¤Â°Ã Â¥â€¹Ã Â¤Å“Ã Â¤Â¼ Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â­Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â®Ã Â¤Â¨Ã Â¤Â¾Ã Â¤ÂÃ Â¤Â Ã Â¤Â¸Ã Â¤Â¾Ã Â¤ÂÃ Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€š, Ã Â¤â€ºÃ Â¥â€¹Ã Â¤Å¸Ã Â¥â€¡ Ã Â¤ÂµÃ Â¥ÂÃ Â¤Â¯Ã Â¤ÂµÃ Â¤Â¸Ã Â¤Â¾Ã Â¤Â¯Ã Â¥â€¹Ã Â¤â€š Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â®Ã Â¥â€¹Ã Â¤Â¶Ã Â¤Â¨Ã Â¤Â² Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤Â¬Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â¨Ã Â¤Â¾ Ã Â¤Å¡Ã Â¤Â¾Ã Â¤Â¹Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€š, Ã Â¤Â­Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â¤Ã Â¤Â¿ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤ÂµÃ Â¤Â¿Ã Â¤Â¶Ã Â¥â€¡Ã Â¤Â· Ã Â¤â€¦Ã Â¤ÂµÃ Â¤Â¸Ã Â¤Â°Ã Â¥â€¹Ã Â¤â€š Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤ÂÃ Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€š, Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¦Ã Â¤ÂªÃ Â¤Â¨Ã Â¥â€¡ Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â® Ã Â¤â€Ã Â¤Â° Ã Â¤ÂµÃ Â¥ÂÃ Â¤Â¯Ã Â¤ÂµÃ Â¤Â¸Ã Â¤Â¾Ã Â¤Â¯ Ã Â¤ÂªÃ Â¤Â¹Ã Â¤Å¡Ã Â¤Â¾Ã Â¤Â¨ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â¥ Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Å“Ã Â¥â‚¬ Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤Â¤Ã Â¥Ë†Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â° Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¨Ã Â¤Â¾ Ã Â¤Å¡Ã Â¤Â¾Ã Â¤Â¹Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤',
    tamil:
        'Ã Â®Â¤Ã Â®Â¿Ã Â®Â©Ã Â®Å¡Ã Â®Â°Ã Â®Â¿ Ã Â®ÂµÃ Â®Â¾Ã Â®Â´Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë† Ã Â®ÂªÃ Â®â€¢Ã Â®Â¿Ã Â®Â°Ã Â¯ÂÃ Â®ÂªÃ Â®ÂµÃ Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®Å¡Ã Â®Â¿Ã Â®Â±Ã Â¯Â Ã Â®ÂµÃ Â®Â£Ã Â®Â¿Ã Â®â€¢Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â¾Ã Â®Â© Ã Â®ÂµÃ Â®Â¿Ã Â®Â³Ã Â®Â®Ã Â¯ÂÃ Â®ÂªÃ Â®Â° Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®Â¤Ã Â¯â€¡Ã Â®ÂµÃ Â¯Ë†Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®ÂªÃ Â®ÂµÃ Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®ÂªÃ Â®â€¢Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿ Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®Å¡Ã Â®Â¿Ã Â®Â±Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯Â Ã Â®Â¨Ã Â®Â¾Ã Â®Â³Ã Â¯Â Ã Â®ÂªÃ Â®Â¤Ã Â®Â¿Ã Â®ÂµÃ Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë†Ã Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â®â€¢Ã Â®Â¿Ã Â®Â°Ã Â¯ÂÃ Â®ÂªÃ Â®ÂµÃ Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®Â¤Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®ÂªÃ Â¯â€ Ã Â®Â¯Ã Â®Â°Ã Â¯Â Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®ÂµÃ Â®Â£Ã Â®Â¿Ã Â®â€¢ Ã Â®â€¦Ã Â®Å¸Ã Â¯Ë†Ã Â®Â¯Ã Â®Â¾Ã Â®Â³Ã Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Å¸Ã Â®Â©Ã Â¯Â Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯Â Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®â€°Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â®Â¾Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢ Ã Â®ÂµÃ Â®Â¿Ã Â®Â°Ã Â¯ÂÃ Â®Â®Ã Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®ÂµÃ Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®â€¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤ Ã Â®â€ Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯Ë†Ã Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
    kannada:
        'Ã Â²Â¦Ã Â³Ë†Ã Â²Â¨Ã Â²â€šÃ Â²Â¦Ã Â²Â¿Ã Â²Â¨ Ã Â²Â¶Ã Â³ÂÃ Â²Â­Ã Â²Â¾Ã Â²Â¶Ã Â²Â¯Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¹Ã Â²â€šÃ Â²Å¡Ã Â²Â¿Ã Â²â€¢Ã Â³Å Ã Â²Â³Ã Â³ÂÃ Â²Â³Ã Â³ÂÃ Â²ÂµÃ Â²ÂµÃ Â²Â°Ã Â³Â, Ã Â²Â¸Ã Â²Â£Ã Â³ÂÃ Â²Â£ Ã Â²ÂµÃ Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¹Ã Â²Â¾Ã Â²Â°Ã Â²â€”Ã Â²Â³Ã Â²Â¿Ã Â²â€”Ã Â²Â¾Ã Â²â€”Ã Â²Â¿ Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Å¡Ã Â²Â¾Ã Â²Â° Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³Â Ã Â²Â¬Ã Â³â€¡Ã Â²â€¢Ã Â²Â¿Ã Â²Â°Ã Â³ÂÃ Â²ÂµÃ Â²ÂµÃ Â²Â°Ã Â³Â, Ã Â²Â­Ã Â²â€¢Ã Â³ÂÃ Â²Â¤Ã Â²Â¿Ã Â²ÂªÃ Â²Â° Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²ÂµÃ Â²Â¿Ã Â²Â¶Ã Â³â€¡Ã Â²Â· Ã Â²Â¸Ã Â²â€šÃ Â²Â¦Ã Â²Â°Ã Â³ÂÃ Â²Â­Ã Â²Â¦ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¹Ã Â²â€šÃ Â²Å¡Ã Â²Â¿Ã Â²â€¢Ã Â³Å Ã Â²Â³Ã Â³ÂÃ Â²Â³Ã Â³ÂÃ Â²ÂµÃ Â²ÂµÃ Â²Â°Ã Â³Â, Ã Â²Â¤Ã Â²Â®Ã Â³ÂÃ Â²Â® Ã Â²Â¹Ã Â³â€ Ã Â²Â¸Ã Â²Â°Ã Â³Â Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²ÂµÃ Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¹Ã Â²Â¾Ã Â²Â°Ã Â²Â¦ Ã Â²â€”Ã Â³ÂÃ Â²Â°Ã Â³ÂÃ Â²Â¤Ã Â²Â¿Ã Â²Â¨Ã Â³Å Ã Â²â€šÃ Â²Â¦Ã Â²Â¿Ã Â²â€”Ã Â³â€  Ã Â²ÂµÃ Â³Ë†Ã Â²Â¯Ã Â²â€¢Ã Â³ÂÃ Â²Â¤Ã Â²Â¿Ã Â²â€¢ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³Â Ã Â²Â°Ã Â²Å¡Ã Â²Â¿Ã Â²Â¸Ã Â²Â²Ã Â³Â Ã Â²Â¬Ã Â²Â¯Ã Â²Â¸Ã Â³ÂÃ Â²ÂµÃ Â²ÂµÃ Â²Â°Ã Â³Â Ã Â²Ë† Ã Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²Â¬Ã Â²Â³Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
    malayalam:
        'Ã Â´Â¦Ã ÂµË†Ã Â´Â¨Ã Â´â€šÃ Â´Â¦Ã Â´Â¿Ã Â´Â¨ Ã Â´â€ Ã Â´Â¶Ã Â´â€šÃ Â´Â¸Ã Â´â€¢Ã ÂµÂ¾ Ã Â´ÂªÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã Â´Å¸Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´ÂµÃ ÂµÂ¼, Ã Â´Å¡Ã Âµâ€ Ã Â´Â±Ã Â´Â¿Ã Â´Â¯ Ã Â´Â¬Ã Â´Â¿Ã Â´Â¸Ã Â´Â¿Ã Â´Â¨Ã Â´Â¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â®Ã Âµâ€¹Ã Â´Â·Ã ÂµÂ» Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾ Ã Â´ÂµÃ Âµâ€¡Ã Â´Â£Ã ÂµÂÃ Â´Å¸Ã Â´ÂµÃ ÂµÂ¼, Ã Â´Â­Ã Â´â€¢Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´ÂªÃ Â´Â°Ã Â´Â®Ã Â´Â¾Ã Â´Â¯Ã Âµâ€¹ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¤Ã ÂµÂÃ Â´Â¯Ã Âµâ€¡Ã Â´â€¢ Ã Â´Â¦Ã Â´Â¿Ã Â´ÂµÃ Â´Â¸Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â³Ã Â´Â¿Ã Â´Â²Ã Âµâ€¡Ã Â´Â¯Ã Âµâ€¹ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾ Ã Â´ÂªÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã Â´Å¸Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´ÂµÃ ÂµÂ¼, Ã Â´Â¸Ã ÂµÂÃ Â´ÂµÃ Â´Â¨Ã ÂµÂÃ Â´Â¤Ã Â´â€š Ã Â´ÂªÃ Âµâ€¡Ã Â´Â°Ã ÂµÂ Ã Â´â€¦Ã Â´Â²Ã ÂµÂÃ Â´Â²Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¬Ã Â´Â¿Ã Â´Â¸Ã Â´Â¿Ã Â´Â¨Ã Â´Â¸Ã ÂµÂ Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Â¿Ã Â´Å¡Ã ÂµÂÃ Â´Å¡Ã Â´Â±Ã Â´Â¿Ã Â´Â¯Ã Â´Â²Ã Âµâ€¹Ã Â´Å¸Ã Âµâ€  Ã Â´ÂµÃ ÂµÂÃ Â´Â¯Ã Â´â€¢Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´â€”Ã Â´Â¤ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾ Ã Â´Â¤Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´Â±Ã Â´Â¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã ÂµÂ» Ã Â´â€ Ã Â´â€”Ã ÂµÂÃ Â´Â°Ã Â´Â¹Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´ÂµÃ ÂµÂ¼Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ Ã Â´Ë† Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´â€°Ã Â´ÂªÃ Â´â€¢Ã Â´Â¾Ã Â´Â°Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€š.',
  );

  String get featuresTitle => strings.localized(
    telugu:
        'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â§Ã Â°Â¾Ã Â°Â¨ Ã Â°Â¸Ã Â±Å’Ã Â°â€¢Ã Â°Â°Ã Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°Â²Ã Â±Â',
    english: 'Main features',
    hindi:
        'Ã Â¤Â®Ã Â¥ÂÃ Â¤â€“Ã Â¥ÂÃ Â¤Â¯ Ã Â¤Â¸Ã Â¥ÂÃ Â¤ÂµÃ Â¤Â¿Ã Â¤Â§Ã Â¤Â¾Ã Â¤ÂÃ Â¤Â',
    tamil:
        'Ã Â®Â®Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â¿Ã Â®Â¯ Ã Â®â€¦Ã Â®Â®Ã Â¯ÂÃ Â®Å¡Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â',
    kannada:
        'Ã Â²Â®Ã Â³ÂÃ Â²â€“Ã Â³ÂÃ Â²Â¯ Ã Â²Â¸Ã Â³Å’Ã Â²Â²Ã Â²Â­Ã Â³ÂÃ Â²Â¯Ã Â²â€”Ã Â²Â³Ã Â³Â',
    malayalam:
        'Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â§Ã Â´Â¾Ã Â´Â¨ Ã Â´Â¸Ã Âµâ€”Ã Â´â€¢Ã Â´Â°Ã ÂµÂÃ Â´Â¯Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾',
  );

  List<String> get featureItems => <String>[
    strings.localized(
      telugu:
          'Ã Â°ÂµÃ Â°Â¿Ã Â°Â­Ã Â°Â¾Ã Â°â€”Ã Â°Â¾Ã Â°Â²Ã Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â±â‚¬Ã Â°â€”Ã Â°Â¾ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°Å¡Ã Â±â€šÃ Â°Â¸Ã Â°Â¿, Ã Â°Â®Ã Â±â‚¬Ã Â°â€¢Ã Â±Â Ã Â°Â¨Ã Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¡Ã Â°Â¿Ã Â°Å“Ã Â±Ë†Ã Â°Â¨Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¨Ã Â±Â Ã Â°Â¤Ã Â±ÂÃ Â°ÂµÃ Â°Â°Ã Â°â€”Ã Â°Â¾ Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'Browse posters by category and quickly choose a suitable design.',
      hindi:
          'Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â°Ã Â¥â€¡Ã Â¤Â£Ã Â¥â‚¬ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¸Ã Â¤Â¾Ã Â¤Â° Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¤â€¢Ã Â¤Â°, Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥ÂÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â¤ Ã Â¤Â¡Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â¨ Ã Â¤Å“Ã Â¤Â²Ã Â¥ÂÃ Â¤Â¦Ã Â¥â‚¬ Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Â¿Ã Â®ÂµÃ Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â®Â¿Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â®Â¿ Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë†Ã Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â®Â¾Ã Â®Â°Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯Â, Ã Â®ÂªÃ Â¯Å Ã Â®Â°Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â®Ã Â®Â¾Ã Â®Â© Ã Â®ÂµÃ Â®Å¸Ã Â®Â¿Ã Â®ÂµÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯Ë† Ã Â®ÂµÃ Â®Â¿Ã Â®Â°Ã Â¯Ë†Ã Â®ÂµÃ Â®Â¾Ã Â®â€¢ Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â¯Â Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¯Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²ÂµÃ Â²Â¿Ã Â²Â­Ã Â²Â¾Ã Â²â€”Ã Â²â€”Ã Â²Â³ Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²â€¢Ã Â²Â¾Ã Â²Â° Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¨Ã Â³â€¹Ã Â²Â¡Ã Â²Â¿, Ã Â²Â¸Ã Â³â€šÃ Â²â€¢Ã Â³ÂÃ Â²Â¤ Ã Â²ÂµÃ Â²Â¿Ã Â²Â¨Ã Â³ÂÃ Â²Â¯Ã Â²Â¾Ã Â²Â¸Ã Â²ÂµÃ Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¬Ã Â³â€¡Ã Â²â€” Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´ÂµÃ Â´Â¿Ã Â´Â­Ã Â´Â¾Ã Â´â€”Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´â€¦Ã Â´Â¨Ã ÂµÂÃ Â´Â¸Ã Â´Â°Ã Â´Â¿Ã Â´Å¡Ã ÂµÂÃ Â´Å¡Ã ÂµÂ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾ Ã Â´â€¢Ã Â´Â£Ã ÂµÂÃ Â´Å¸Ã ÂµÂ, Ã Â´â€¦Ã Â´Â¨Ã ÂµÂÃ Â´Â¯Ã Âµâ€¹Ã Â´Å“Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â¯ Ã Â´Â¡Ã Â´Â¿Ã Â´Â¸Ã ÂµË†Ã ÂµÂ» Ã Â´ÂµÃ Âµâ€¡Ã Â´â€”Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'State/Union Territory Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°â€  Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¾Ã Â°â€šÃ Â°Â¤ Ã Â°Â­Ã Â°Â¾Ã Â°Â·Ã Â°â€¢Ã Â±Â Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â°Â¿, Ã Â°Â¸Ã Â°â€šÃ Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¿Ã Â°Â¤ categories Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â political party categories Ã Â°Å¡Ã Â±â€šÃ Â°ÂªÃ Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english:
          'After selecting a State or Union Territory, the app switches to the region language and shows relevant categories, including political party categories.',
      hindi:
          'Ã Â¤Â°Ã Â¤Â¾Ã Â¤Å“Ã Â¥ÂÃ Â¤Â¯ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¢Ã Â¥â€¡Ã Â¤â€šÃ Â¤Â¦Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¶Ã Â¤Â¾Ã Â¤Â¸Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¦Ã Â¥â€¡Ã Â¤Â¶ Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ Ã Â¤ÂÃ Â¤Âª Ã Â¤â€°Ã Â¤Â¸ Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¥â€¡Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â° Ã Â¤â€¢Ã Â¥â‚¬ Ã Â¤Â­Ã Â¤Â¾Ã Â¤Â·Ã Â¤Â¾ Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¬Ã Â¤Â¦Ã Â¤Â²Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë† Ã Â¤â€Ã Â¤Â° Ã Â¤Â¸Ã Â¤â€šÃ Â¤Â¬Ã Â¤â€šÃ Â¤Â§Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤Â°Ã Â¤Â¾Ã Â¤Å“Ã Â¤Â¨Ã Â¥â‚¬Ã Â¤Â¤Ã Â¤Â¿Ã Â¤â€¢ Ã Â¤ÂªÃ Â¤Â¾Ã Â¤Â°Ã Â¥ÂÃ Â¤Å¸Ã Â¥â‚¬ Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â°Ã Â¥â€¡Ã Â¤Â£Ã Â¤Â¿Ã Â¤Â¯Ã Â¥â€¹Ã Â¤â€š Ã Â¤Â¸Ã Â¤Â¹Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥ÂÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â¤ Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â°Ã Â¥â€¡Ã Â¤Â£Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â Ã Â¤Â¦Ã Â¤Â¿Ã Â¤â€“Ã Â¤Â¾Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®Â®Ã Â®Â¾Ã Â®Â¨Ã Â®Â¿Ã Â®Â²Ã Â®Â®Ã Â¯Â Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®Â¯Ã Â¯â€šÃ Â®Â©Ã Â®Â¿Ã Â®Â¯Ã Â®Â©Ã Â¯Â Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Â¤Ã Â¯â€¡Ã Â®Å¡Ã Â®Â®Ã Â¯Â Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â¯â€ Ã Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤ Ã Â®ÂªÃ Â®Â¿Ã Â®Â±Ã Â®â€¢Ã Â¯Â, Ã Â®â€ Ã Â®ÂªÃ Â¯Â Ã Â®â€¦Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤ Ã Â®ÂªÃ Â®â€¢Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿ Ã Â®Â®Ã Â¯Å Ã Â®Â´Ã Â®Â¿Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â Ã Â®Â®Ã Â®Â¾Ã Â®Â±Ã Â®Â¿, Ã Â®â€¦Ã Â®Â°Ã Â®Å¡Ã Â®Â¿Ã Â®Â¯Ã Â®Â²Ã Â¯Â Ã Â®â€¢Ã Â®Å¸Ã Â¯ÂÃ Â®Å¡Ã Â®Â¿ Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Â¿Ã Â®ÂµÃ Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®â€°Ã Â®Å¸Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸ Ã Â®Â¤Ã Â¯Å Ã Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®Å¸Ã Â¯Ë†Ã Â®Â¯ Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Â¿Ã Â®ÂµÃ Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë† Ã Â®â€¢Ã Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â¯ÂÃ Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²Â°Ã Â²Â¾Ã Â²Å“Ã Â³ÂÃ Â²Â¯ Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²â€¢Ã Â³â€¡Ã Â²â€šÃ Â²Â¦Ã Â³ÂÃ Â²Â°Ã Â²Â¾Ã Â²Â¡Ã Â²Â³Ã Â²Â¿Ã Â²Â¤ Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Â¦Ã Â³â€¡Ã Â²Â¶ Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿Ã Â²Â¦ Ã Â²Â¨Ã Â²â€šÃ Â²Â¤Ã Â²Â° Ã Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²â€  Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Â¦Ã Â³â€¡Ã Â²Â¶Ã Â²Â¦ Ã Â²Â­Ã Â²Â¾Ã Â²Â·Ã Â³â€ Ã Â²â€”Ã Â³â€  Ã Â²Â¬Ã Â²Â¦Ã Â²Â²Ã Â²Â¾Ã Â²â€”Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€  Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â°Ã Â²Â¾Ã Â²Å“Ã Â²â€¢Ã Â³â‚¬Ã Â²Â¯ Ã Â²ÂªÃ Â²â€¢Ã Â³ÂÃ Â²Â·Ã Â²â€”Ã Â²Â³ Ã Â²ÂµÃ Â²Â¿Ã Â²Â­Ã Â²Â¾Ã Â²â€”Ã Â²â€”Ã Â²Â³Ã Â³Å Ã Â²â€šÃ Â²Â¦Ã Â²Â¿Ã Â²â€”Ã Â³â€  Ã Â²Â¸Ã Â²â€šÃ Â²Â¬Ã Â²â€šÃ Â²Â§Ã Â²Â¿Ã Â²Â¤ Ã Â²ÂµÃ Â²Â¿Ã Â²Â­Ã Â²Â¾Ã Â²â€”Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¤Ã Â³â€¹Ã Â²Â°Ã Â²Â¿Ã Â²Â¸Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ .',
      malayalam:
          'Ã Â´Â¸Ã Â´â€šÃ Â´Â¸Ã ÂµÂÃ Â´Â¥Ã Â´Â¾Ã Â´Â¨Ã Â´â€š Ã Â´â€¦Ã Â´Â²Ã ÂµÂÃ Â´Â²Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´â€¢Ã Âµâ€¡Ã Â´Â¨Ã ÂµÂÃ Â´Â¦Ã ÂµÂÃ Â´Â°Ã Â´Â­Ã Â´Â°Ã Â´Â£ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¦Ã Âµâ€¡Ã Â´Â¶Ã Â´â€š Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´Â¤Ã ÂµÂÃ Â´Â¤ Ã Â´Â¶Ã Âµâ€¡Ã Â´Â·Ã Â´â€š Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´â€  Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¦Ã Âµâ€¡Ã Â´Â¶Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´Â¨Ã ÂµÂÃ Â´Â±Ã Âµâ€  Ã Â´Â­Ã Â´Â¾Ã Â´Â·Ã Â´Â¯Ã Â´Â¿Ã Â´Â²Ã Âµâ€¡Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ Ã Â´Â®Ã Â´Â¾Ã Â´Â±Ã Â´Â¿, Ã Â´Â°Ã Â´Â¾Ã Â´Â·Ã ÂµÂÃ Â´Å¸Ã ÂµÂÃ Â´Â°Ã Âµâ‚¬Ã Â´Â¯ Ã Â´ÂªÃ Â´Â¾Ã ÂµÂ¼Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Â´Â¿ Ã Â´ÂµÃ Â´Â¿Ã Â´Â­Ã Â´Â¾Ã Â´â€”Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´â€°Ã ÂµÂ¾Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Âµâ€ Ã Â´Å¸Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â³Ã ÂµÂÃ Â´Â³ Ã Â´â€¦Ã Â´Â¨Ã ÂµÂÃ Â´Â¯Ã Âµâ€¹Ã Â´Å“Ã ÂµÂÃ Â´Â¯ Ã Â´ÂµÃ Â´Â¿Ã Â´Â­Ã Â´Â¾Ã Â´â€”Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Community upload Ã Â°Â²Ã Â±â€¹ image, quote Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°Â°Ã Â±â€ Ã Â°â€šÃ Â°Â¡Ã Â±â€š manager review Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°ÂªÃ Â°â€šÃ Â°ÂªÃ Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â; approved poster Ã Â°Â¸Ã Â°Â°Ã Â±Ë†Ã Â°Â¨ category Ã Â°Â²Ã Â±â€¹ Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english:
          'Community upload lets users send an image, quote, or both for manager review; approved posters appear in the appropriate category.',
      hindi:
          'Community upload Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€”Ã Â¤â€¢Ã Â¤Â°Ã Â¥ÂÃ Â¤Â¤Ã Â¤Â¾ manager review Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â image, quote Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¦Ã Â¥â€¹Ã Â¤Â¨Ã Â¥â€¹Ã Â¤â€š Ã Â¤Â­Ã Â¥â€¡Ã Â¤Å“ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€š; approved poster Ã Â¤Â¸Ã Â¤Â¹Ã Â¥â‚¬ category Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¦Ã Â¤Â¿Ã Â¤â€“Ã Â¤Â¾Ã Â¤Ë† Ã Â¤Â¦Ã Â¥â€¡Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Community upload Ã Â®Â®Ã Â¯â€šÃ Â®Â²Ã Â®Â®Ã Â¯Â image, quote Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®â€¡Ã Â®Â°Ã Â®Â£Ã Â¯ÂÃ Â®Å¸Ã Â¯Ë†Ã Â®Â¯Ã Â¯ÂÃ Â®Â®Ã Â¯Â manager review Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â Ã Â®â€¦Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â; approved poster Ã Â®ÂªÃ Â¯Å Ã Â®Â°Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â®Ã Â®Â¾Ã Â®Â© category Ã Â®Â¯Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®â€¢Ã Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â®Ã Â¯Â.',
      kannada:
          'Community upload Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ image, quote Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²Å½Ã Â²Â°Ã Â²Â¡Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³â€š manager review Ã Â²â€”Ã Â²Â¾Ã Â²â€”Ã Â²Â¿ Ã Â²â€¢Ã Â²Â³Ã Â³ÂÃ Â²Â¹Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â; approved poster Ã Â²Â¸Ã Â²Â°Ã Â²Â¿Ã Â²Â¯Ã Â²Â¾Ã Â²Â¦ category Ã Â²Â¯Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²â€¢Ã Â²Â¾Ã Â²Â£Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ .',
      malayalam:
          'Community upload Ã Â´ÂµÃ Â´Â´Ã Â´Â¿ image, quote Ã Â´â€¦Ã Â´Â²Ã ÂµÂÃ Â´Â²Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â°Ã Â´Â£Ã ÂµÂÃ Â´Å¸Ã ÂµÂÃ Â´â€š manager review Ã Â´Â¨Ã ÂµÂ Ã Â´â€¦Ã Â´Â¯Ã Â´Â¯Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š; approved poster Ã Â´Â¶Ã Â´Â°Ã Â´Â¿Ã Â´Â¯Ã Â´Â¾Ã Â´Â¯ category Ã Â´Â¯Ã Â´Â¿Ã ÂµÂ½ Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±Â Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Å Ã Â°Â«Ã Â±Ë†Ã Â°Â²Ã Â±Â, Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â°Â¾Ã Â°Â° Ã Â°ÂªÃ Â±â€¡Ã Â°Â°Ã Â±Â, Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹, Ã Â°ÂµÃ Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â¸Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'Save poster profile, business name, photo, and WhatsApp details.',
      hindi:
          'Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â², Ã Â¤Â¬Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¨Ã Â¥â€¡Ã Â¤Â¸ Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â®, Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹ Ã Â¤â€Ã Â¤Â° Ã Â¤ÂµÃ Â¥ÂÃ Â¤Â¹Ã Â¤Â¾Ã Â¤Å¸Ã Â¥ÂÃ Â¤Â¸Ã Â¤ÂÃ Â¤Âª Ã Â¤ÂµÃ Â¤Â¿Ã Â¤ÂµÃ Â¤Â°Ã Â¤Â£ Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â°Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤Â°Ã Â¤â€“Ã Â¥â€¡ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤',
      tamil:
          'Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯Â Ã Â®Å¡Ã Â¯ÂÃ Â®Â¯Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â°Ã Â®Â®Ã Â¯Â, Ã Â®ÂµÃ Â®Â£Ã Â®Â¿Ã Â®â€¢Ã Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â¯â€ Ã Â®Â¯Ã Â®Â°Ã Â¯Â, Ã Â®ÂªÃ Â¯ÂÃ Â®â€¢Ã Â¯Ë†Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â®Â®Ã Â¯Â Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®ÂµÃ Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®Â¸Ã Â¯ÂÃ Â®â€¦Ã Â®ÂªÃ Â¯Â Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë†Ã Â®Å¡Ã Â¯Â Ã Â®Å¡Ã Â¯â€¡Ã Â®Â®Ã Â®Â¿Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³Â Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â³Å Ã Â²Â«Ã Â³Ë†Ã Â²Â²Ã Â³Â, Ã Â²ÂµÃ Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¹Ã Â²Â¾Ã Â²Â°Ã Â²Â¦ Ã Â²Â¹Ã Â³â€ Ã Â²Â¸Ã Â²Â°Ã Â³Â, Ã Â²Â«Ã Â³â€¹Ã Â²Å¸Ã Â³â€¹ Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²ÂµÃ Â²Â¾Ã Â²Å¸Ã Â³ÂÃ Â²Â¸Ã Â³ÂÃ Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â²Â°Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²â€°Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ¼ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã ÂµÅ Ã Â´Â«Ã ÂµË†Ã ÂµÂ½, Ã Â´Â¬Ã Â´Â¿Ã Â´Â¸Ã Â´Â¿Ã Â´Â¨Ã Â´Â¸Ã ÂµÂ Ã Â´ÂªÃ Âµâ€¡Ã Â´Â°Ã ÂµÂ, Ã Â´Â«Ã Âµâ€¹Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Âµâ€¹, Ã Â´ÂµÃ Â´Â¾Ã Â´Å¸Ã ÂµÂÃ¢â‚¬Å’Ã Â´Â¸Ã ÂµÂÃ Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ Ã Â´Â¸Ã Â´â€šÃ Â´Â°Ã Â´â€¢Ã ÂµÂÃ Â´Â·Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Å¸Ã Â±â€ Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â²Ã Â±â€¡Ã Â°Å¸Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¨Ã Â±Â Ã Â°Å½Ã Â°Â¡Ã Â°Â¿Ã Â°Å¸Ã Â°Â°Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ Ã Â°Â¤Ã Â±ÂÃ Â°Â¦Ã Â°Â¿ Ã Â°Â°Ã Â±â€šÃ Â°ÂªÃ Â°â€šÃ Â°Â²Ã Â±â€¹ Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°Â·Ã Â±â€¡Ã Â°Â°Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'Customize the selected template in the editor, then save or share it.',
      hindi:
          'Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¥â€¡ Ã Â¤â€”Ã Â¤Â Ã Â¤Å¸Ã Â¥â€¡Ã Â¤Â®Ã Â¥ÂÃ Â¤ÂªÃ Â¤Â²Ã Â¥â€¡Ã Â¤Å¸ Ã Â¤â€¢Ã Â¥â€¹ Ã Â¤ÂÃ Â¤Â¡Ã Â¤Â¿Ã Â¤Å¸Ã Â¤Â° Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¬Ã Â¤Â¦Ã Â¤Â²Ã Â¤â€¢Ã Â¤Â° Ã Â¤â€¦Ã Â¤â€šÃ Â¤Â¤Ã Â¤Â¿Ã Â¤Â® Ã Â¤Â°Ã Â¥â€šÃ Â¤Âª Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¸Ã Â¥â€¡Ã Â¤Âµ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¶Ã Â¥â€¡Ã Â¤Â¯Ã Â¤Â° Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â¯â€ Ã Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤ Ã Â®Å¸Ã Â¯â€ Ã Â®Â®Ã Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®Â³Ã Â¯â€¡Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â¯Ë† Ã Â®Å½Ã Â®Å¸Ã Â®Â¿Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®Â®Ã Â®Â¾Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â®Â¿, Ã Â®â€¡Ã Â®Â±Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿Ã Â®Â¯Ã Â®Â¾Ã Â®â€¢ Ã Â®Å¡Ã Â¯â€¡Ã Â®Â®Ã Â®Â¿Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢ Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®ÂªÃ Â®â€¢Ã Â®Â¿Ã Â®Â°Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²Â¦ Ã Â²Å¸Ã Â³â€ Ã Â²â€šÃ Â²ÂªÃ Â³ÂÃ Â²Â²Ã Â³â€¡Ã Â²Å¸Ã Â³Â Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Å½Ã Â²Â¡Ã Â²Â¿Ã Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²Â¤Ã Â²Â¿Ã Â²Â¦Ã Â³ÂÃ Â²Â¦Ã Â³ÂÃ Â²ÂªÃ Â²Â¡Ã Â²Â¿ Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿, Ã Â²Â¨Ã Â²â€šÃ Â²Â¤Ã Â²Â° Ã Â²â€°Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²Â¹Ã Â²â€šÃ Â²Å¡Ã Â²Â¿Ã Â²â€¢Ã Â³Å Ã Â²Â³Ã Â³ÂÃ Â²Â³Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´Â¤Ã ÂµÂÃ Â´Â¤ Ã Â´Å¸Ã Âµâ€ Ã Â´â€šÃ Â´ÂªÃ ÂµÂÃ Â´Â²Ã Âµâ€¡Ã Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ Ã Â´Å½Ã Â´Â¡Ã Â´Â¿Ã Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â®Ã Â´Â¾Ã Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â¿, Ã Â´â€¦Ã Â´ÂµÃ Â´Â¸Ã Â´Â¾Ã Â´Â¨Ã Â´â€š Ã Â´Â¸Ã Âµâ€¡Ã Â´ÂµÃ ÂµÂ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã ÂµÂÃ Â´â€¢Ã Â´Â¯Ã Âµâ€¹ Ã Â´Â·Ã Âµâ€ Ã Â´Â¯Ã ÂµÂ¼ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã ÂµÂÃ Â´â€¢Ã Â´Â¯Ã Âµâ€¹ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Ã Â°Â¨Ã Â±â€¹Ã Â°Å¸Ã Â°Â¿Ã Â°Â«Ã Â°Â¿Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°Â¸Ã Â°Â¹Ã Â°Â¾Ã Â°Â¯Ã Â°â€š, Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Ë†Ã Â°ÂµÃ Â°Â¸Ã Â±â‚¬ Ã Â°ÂªÃ Â°Â¾Ã Â°Â²Ã Â°Â¸Ã Â±â‚¬, Ã Â°Â¨Ã Â°Â¿Ã Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¨Ã Â°Â²Ã Â±Â Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹Ã Â°Â¨Ã Â±â€¡ Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
      english:
          'Notifications, permissions, help, privacy policy, and terms are available inside the app.',
      hindi:
          'Ã Â¤Â¨Ã Â¥â€¹Ã Â¤Å¸Ã Â¤Â¿Ã Â¤Â«Ã Â¤Â¿Ã Â¤â€¢Ã Â¥â€¡Ã Â¤Â¶Ã Â¤Â¨, Ã Â¤ÂªÃ Â¤Â°Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â¶Ã Â¤Â¨, Ã Â¤Â¸Ã Â¤Â¹Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¤Ã Â¤Â¾, Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤â€¡Ã Â¤ÂµÃ Â¥â€¡Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤ÂªÃ Â¥â€°Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤â€Ã Â¤Â° Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â® Ã Â¤ÂÃ Â¤Âª Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤â€¦Ã Â¤â€šÃ Â¤Â¦Ã Â¤Â° Ã Â¤Â¹Ã Â¥â‚¬ Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â²Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â§ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤',
      tamil:
          'Ã Â®â€¦Ã Â®Â±Ã Â®Â¿Ã Â®ÂµÃ Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®â€¦Ã Â®Â©Ã Â¯ÂÃ Â®Â®Ã Â®Â¤Ã Â®Â¿Ã Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®â€°Ã Â®Â¤Ã Â®ÂµÃ Â®Â¿, Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®Â¯Ã Â¯ÂÃ Â®Â°Ã Â®Â¿Ã Â®Â®Ã Â¯Ë†Ã Â®â€¢Ã Â¯Â Ã Â®â€¢Ã Â¯Å Ã Â®Â³Ã Â¯ÂÃ Â®â€¢Ã Â¯Ë† Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®ÂµÃ Â®Â¿Ã Â®Â¤Ã Â®Â¿Ã Â®Â®Ã Â¯ÂÃ Â®Â±Ã Â¯Ë†Ã Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®â€ Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â¿Ã Â®Â²Ã Â¯â€¡Ã Â®Â¯Ã Â¯â€¡ Ã Â®â€¢Ã Â®Â¿Ã Â®Å¸Ã Â¯Ë†Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²â€¦Ã Â²Â§Ã Â²Â¿Ã Â²Â¸Ã Â³â€šÃ Â²Å¡Ã Â²Â¨Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²Â®Ã Â²Â¤Ã Â²Â¿Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²Â¸Ã Â²Â¹Ã Â²Â¾Ã Â²Â¯, Ã Â²â€”Ã Â³Å’Ã Â²ÂªÃ Â³ÂÃ Â²Â¯Ã Â²Â¤Ã Â²Â¾ Ã Â²Â¨Ã Â³â‚¬Ã Â²Â¤Ã Â²Â¿ Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â¨Ã Â²Â¿Ã Â²Â¯Ã Â²Â®Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²â€ Ã Â²ÂªÃ Â³ÂÃ¢â‚¬Å’Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â³â€¡ Ã Â²Â²Ã Â²Â­Ã Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â³â€ .',
      malayalam:
          'Ã Â´Â¨Ã Âµâ€¹Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Â´Â¿Ã Â´Â«Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Âµâ€¡Ã Â´Â·Ã Â´Â¨Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾, Ã Â´â€¦Ã Â´Â¨Ã ÂµÂÃ Â´Â®Ã Â´Â¤Ã Â´Â¿Ã Â´â€¢Ã ÂµÂ¾, Ã Â´Â¸Ã Â´Â¹Ã Â´Â¾Ã Â´Â¯Ã Â´â€š, Ã Â´Â¸Ã ÂµÂÃ Â´ÂµÃ Â´â€¢Ã Â´Â¾Ã Â´Â°Ã ÂµÂÃ Â´Â¯Ã Â´Â¤Ã Â´Â¾ Ã Â´Â¨Ã Â´Â¯Ã Â´â€š, Ã Â´Â¨Ã Â´Â¿Ã Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´Â¨Ã Â´â€¢Ã ÂµÂ¾ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¿Ã Â´Â¨Ã ÂµÂÃ Â´Â³Ã ÂµÂÃ Â´Â³Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¤Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Âµâ€  Ã Â´Â²Ã Â´Â­Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â£Ã ÂµÂ.',
    ),
  ];

  String get flowTitle => strings.localized(
    telugu:
        'Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°ÂªÃ Â°Â¨Ã Â°Â¿ Ã Â°ÂµÃ Â°Â¿Ã Â°Â§Ã Â°Â¾Ã Â°Â¨Ã Â°â€š',
    english: 'How the app works',
    hindi:
        'Ã Â¤ÂÃ Â¤Âª Ã Â¤â€¢Ã Â¥Ë†Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â® Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†',
    tamil:
        'Ã Â®â€ Ã Â®ÂªÃ Â¯Â Ã Â®Å½Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â®Â¿ Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â®Â²Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®â€¢Ã Â®Â¿Ã Â®Â±Ã Â®Â¤Ã Â¯Â',
    kannada:
        'Ã Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²Â¹Ã Â³â€¡Ã Â²â€”Ã Â³â€  Ã Â²â€¢Ã Â³â€ Ã Â²Â²Ã Â²Â¸ Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ ',
    malayalam:
        'Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´Å½Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â¨Ã Âµâ€  Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´ÂµÃ ÂµÂ¼Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã ÂµÂ',
  );

  List<String> get flowItems => <String>[
    strings.localized(
      telugu:
          'Ã Â°Â²Ã Â°Â¾Ã Â°â€”Ã Â°Â¿Ã Â°Â¨Ã Â±Â Ã Â°â€¦Ã Â°Â¯Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°Â¹Ã Â±â€¹Ã Â°Â®Ã Â±Â Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â°Ã Â±â‚¬Ã Â°Â¨Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±Â Ã Â°ÂµÃ Â°Â¿Ã Â°Â­Ã Â°Â¾Ã Â°â€”Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¡Ã Â°Â¿Ã Â°Å“Ã Â±Ë†Ã Â°Â¨Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°â€¢Ã Â°Â¨Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
      english:
          'After login, the home screen shows poster categories and designs.',
      hindi:
          'Ã Â¤Â²Ã Â¥â€°Ã Â¤â€”Ã Â¤Â¿Ã Â¤Â¨ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ Ã Â¤Â¹Ã Â¥â€¹Ã Â¤Â® Ã Â¤Â¸Ã Â¥ÂÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â°Ã Â¥â‚¬Ã Â¤Â¨ Ã Â¤ÂªÃ Â¤Â° Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â°Ã Â¥â€¡Ã Â¤Â£Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â Ã Â¤â€Ã Â¤Â° Ã Â¤Â¡Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â¨ Ã Â¤Â¦Ã Â¤Â¿Ã Â¤â€“Ã Â¤Â¾Ã Â¤Ë† Ã Â¤Â¦Ã Â¥â€¡Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤',
      tamil:
          'Ã Â®â€°Ã Â®Â³Ã Â¯ÂÃ Â®Â¨Ã Â¯ÂÃ Â®Â´Ã Â¯Ë†Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤ Ã Â®ÂªÃ Â®Â¿Ã Â®Â±Ã Â®â€¢Ã Â¯Â Ã Â®Â¹Ã Â¯â€¹Ã Â®Â®Ã Â¯Â Ã Â®Â¤Ã Â®Â¿Ã Â®Â°Ã Â¯Ë†Ã Â®Â¯Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯Â Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Â¿Ã Â®ÂµÃ Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®ÂµÃ Â®Å¸Ã Â®Â¿Ã Â®ÂµÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®â€¢Ã Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²Â²Ã Â²Â¾Ã Â²â€”Ã Â²Â¿Ã Â²Â¨Ã Â³Â Ã Â²â€ Ã Â²Â¦ Ã Â²Â¨Ã Â²â€šÃ Â²Â¤Ã Â²Â° Ã Â²Â¹Ã Â³â€¹Ã Â²Â®Ã Â³Â Ã Â²ÂªÃ Â²Â°Ã Â²Â¦Ã Â³â€ Ã Â²Â¯Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²Â­Ã Â²Â¾Ã Â²â€”Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²Â¨Ã Â³ÂÃ Â²Â¯Ã Â²Â¾Ã Â²Â¸Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²â€¢Ã Â²Â¾Ã Â²Â£Ã Â²Â¿Ã Â²Â¸Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²ÂµÃ Â³â€ .',
      malayalam:
          'Ã Â´Â²Ã Âµâ€¹Ã Â´â€”Ã Â´Â¿Ã ÂµÂ» Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¤ Ã Â´Â¶Ã Âµâ€¡Ã Â´Â·Ã Â´â€š Ã Â´Â¹Ã Âµâ€¹Ã Â´â€š Ã Â´Â¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â°Ã Âµâ‚¬Ã Â´Â¨Ã Â´Â¿Ã ÂµÂ½ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ¼ Ã Â´ÂµÃ Â´Â¿Ã Â´Â­Ã Â´Â¾Ã Â´â€”Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â³Ã ÂµÂÃ Â´â€š Ã Â´Â¡Ã Â´Â¿Ã Â´Â¸Ã ÂµË†Ã Â´Â¨Ã ÂµÂÃ Â´â€¢Ã Â´Â³Ã ÂµÂÃ Â´â€š Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Å Ã Â°Â«Ã Â±Ë†Ã Â°Â²Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°Â®Ã Â±â‚¬ Ã Â°ÂªÃ Â±â€¡Ã Â°Â°Ã Â±Â, Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹, Ã Â°Â¬Ã Â°Â¿Ã Â°Å“Ã Â°Â¿Ã Â°Â¨Ã Â±â€ Ã Â°Â¸Ã Â±Â Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°ÂµÃ Â°â€šÃ Â°Å¸Ã Â°Â¿ Ã Â°Â¸Ã Â°Â®Ã Â°Â¾Ã Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â°Â¾Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ Ã Â°Â®Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°â€”Ã Â°Â¾ Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'You can first save your name, photo, and business details in the profile section.',
      hindi:
          'Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤ÂªÃ Â¤Â¹Ã Â¤Â²Ã Â¥â€¡ Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤â€¦Ã Â¤ÂªÃ Â¤Â¨Ã Â¤Â¾ Ã Â¤Â¨Ã Â¤Â¾Ã Â¤Â®, Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹ Ã Â¤â€Ã Â¤Â° Ã Â¤Â¬Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¨Ã Â¥â€¡Ã Â¤Â¸ Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â¨Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Â¸Ã Â¥â€¡Ã Â¤Âµ Ã Â¤â€¢Ã Â¥â‚¬ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¥â‚¬ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®Å¡Ã Â¯ÂÃ Â®Â¯Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â° Ã Â®ÂªÃ Â®â€¢Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿Ã Â®Â¯Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®â€°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®ÂªÃ Â¯â€ Ã Â®Â¯Ã Â®Â°Ã Â¯Â, Ã Â®ÂªÃ Â¯ÂÃ Â®â€¢Ã Â¯Ë†Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â®Â®Ã Â¯Â Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®ÂµÃ Â®Â£Ã Â®Â¿Ã Â®â€¢ Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë† Ã Â®Â®Ã Â¯ÂÃ Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â¯â€¡ Ã Â®Å¡Ã Â¯â€¡Ã Â®Â®Ã Â®Â¿Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â³Å Ã Â²Â«Ã Â³Ë†Ã Â²Â²Ã Â³Â Ã Â²ÂµÃ Â²Â¿Ã Â²Â­Ã Â²Â¾Ã Â²â€”Ã Â²Â¦Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²Â¨Ã Â²Â¿Ã Â²Â®Ã Â³ÂÃ Â²Â® Ã Â²Â¹Ã Â³â€ Ã Â²Â¸Ã Â²Â°Ã Â³Â, Ã Â²Â«Ã Â³â€¹Ã Â²Å¸Ã Â³â€¹ Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²ÂµÃ Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¹Ã Â²Â¾Ã Â²Â°Ã Â²Â¦ Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â²Â°Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â®Ã Â³Å Ã Â²Â¦Ã Â²Â²Ã Â³Â Ã Â²â€°Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã ÂµÅ Ã Â´Â«Ã ÂµË†Ã ÂµÂ½ Ã Â´ÂµÃ Â´Â¿Ã Â´Â­Ã Â´Â¾Ã Â´â€”Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¨Ã Â´Â¿Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â³Ã ÂµÂÃ Â´Å¸Ã Âµâ€  Ã Â´ÂªÃ Âµâ€¡Ã Â´Â°Ã ÂµÂ, Ã Â´Â«Ã Âµâ€¹Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Âµâ€¹, Ã Â´Â¬Ã Â´Â¿Ã Â´Â¸Ã Â´Â¿Ã Â´Â¨Ã Â´Â¸Ã ÂµÂ Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ Ã Â´â€ Ã Â´Â¦Ã ÂµÂÃ Â´Â¯Ã Â´â€š Ã Â´Â¸Ã Â´â€šÃ Â´Â°Ã Â´â€¢Ã ÂµÂÃ Â´Â·Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Community upload Ã Â°Â²Ã Â±â€¹ Ã Â°ÂªÃ Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°Â¨ quote/image Ã Â°Â¨Ã Â±Â manager review Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿, Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¤Ã Â±â€¡ customize Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿ Ã Â°Â¸Ã Â°Â°Ã Â±Ë†Ã Â°Â¨ category Ã Â°Â²Ã Â±â€¹ publish Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'Community quote/image submissions are reviewed by a manager, who may customize and publish the poster in the correct category.',
      hindi:
          'Community quote/image submissions Ã Â¤â€¢Ã Â¥â€¹ manager review Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë† Ã Â¤â€Ã Â¤Â° Ã Â¤Å“Ã Â¤Â°Ã Â¥â€šÃ Â¤Â°Ã Â¤Â¤ Ã Â¤Â¹Ã Â¥â€¹Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤ÂªÃ Â¤Â° customize Ã Â¤â€¢Ã Â¤Â°Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¸Ã Â¤Â¹Ã Â¥â‚¬ category Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š publish Ã Â¤â€¢Ã Â¤Â° Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Community quote/image submissions Ã Â®Â manager review Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¤Ã Â¯Â, Ã Â®Â¤Ã Â¯â€¡Ã Â®ÂµÃ Â¯Ë†Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â¾Ã Â®Â²Ã Â¯Â customize Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¤Ã Â¯Â Ã Â®Å¡Ã Â®Â°Ã Â®Â¿Ã Â®Â¯Ã Â®Â¾Ã Â®Â© category Ã Â®Â¯Ã Â®Â¿Ã Â®Â²Ã Â¯Â publish Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¯Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Community quote/image submissions Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â manager review Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿, Ã Â²Â¬Ã Â³â€¡Ã Â²â€¢Ã Â²Â¾Ã Â²Â¦Ã Â²Â°Ã Â³â€  customize Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿ Ã Â²Â¸Ã Â²Â°Ã Â²Â¿Ã Â²Â¯Ã Â²Â¾Ã Â²Â¦ category Ã Â²Â¯Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ publish Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Community quote/image submissions manager review Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¤Ã ÂµÂ, Ã Â´â€ Ã Â´ÂµÃ Â´Â¶Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ customize Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¤Ã ÂµÂ Ã Â´Â¶Ã Â´Â°Ã Â´Â¿Ã Â´Â¯Ã Â´Â¾Ã Â´Â¯ category Ã Â´Â¯Ã Â´Â¿Ã ÂµÂ½ publish Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Ã Â°Â¡Ã Â°Â¿Ã Â°Å“Ã Â±Ë†Ã Â°Â¨Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¨Ã Â±Â Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ Ã Â°Å½Ã Â°Â¡Ã Â°Â¿Ã Â°Å¸Ã Â°Â°Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€¦Ã Â°ÂµÃ Â°Â¸Ã Â°Â°Ã Â°Â®Ã Â±Ë†Ã Â°Â¨ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°ÂªÃ Â±ÂÃ Â°Â²Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿ Ã Â°ÂµÃ Â±ÂÃ Â°Â¯Ã Â°â€¢Ã Â±ÂÃ Â°Â¤Ã Â°Â¿Ã Â°â€”Ã Â°Â¤ Ã Â°Â°Ã Â±â€šÃ Â°ÂªÃ Â°â€šÃ Â°Â²Ã Â±â€¹ Ã Â°Â®Ã Â°Â¾Ã Â°Â°Ã Â±ÂÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'Once a design is selected, it can be edited and personalized in the editor with layers, text, photos, brushes, effects, background removal, and export tools.',
      hindi:
          'Ã Â¤Â¡Ã Â¤Â¿Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â¨ Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ Ã Â¤â€°Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤ÂÃ Â¤Â¡Ã Â¤Â¿Ã Â¤Å¸Ã Â¤Â° Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¬Ã Â¤Â¦Ã Â¤Â²Ã Â¤â€¢Ã Â¤Â° Ã Â¤ÂµÃ Â¥ÂÃ Â¤Â¯Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â¤Ã Â¤Â¿Ã Â¤â€”Ã Â¤Â¤ Ã Â¤Â°Ã Â¥â€šÃ Â¤Âª Ã Â¤Â¦Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®â€™Ã Â®Â°Ã Â¯Â Ã Â®ÂµÃ Â®Å¸Ã Â®Â¿Ã Â®ÂµÃ Â®Â®Ã Â¯Â Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â¯â€ Ã Â®Å¸Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â¤Ã Â¯ÂÃ Â®Â®Ã Â¯Â, Ã Â®Å½Ã Â®Å¸Ã Â®Â¿Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®â€¦Ã Â®Â¤Ã Â¯Ë† Ã Â®Â®Ã Â®Â¾Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â®Â¿ Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â®Â¾Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²ÂµÃ Â²Â¿Ã Â²Â¨Ã Â³ÂÃ Â²Â¯Ã Â²Â¾Ã Â²Â¸Ã Â²ÂµÃ Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿Ã Â²Â¦ Ã Â²Â¨Ã Â²â€šÃ Â²Â¤Ã Â²Â°, Ã Â²â€¦Ã Â²Â¦Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Å½Ã Â²Â¡Ã Â²Â¿Ã Â²Å¸Ã Â²Â°Ã Â³ÂÃ¢â‚¬Å’Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²Â¤Ã Â²Â¿Ã Â²Â¦Ã Â³ÂÃ Â²Â¦Ã Â³ÂÃ Â²ÂªÃ Â²Â¡Ã Â²Â¿ Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿ Ã Â²ÂµÃ Â³Ë†Ã Â²Â¯Ã Â²â€¢Ã Â³ÂÃ Â²Â¤Ã Â²Â¿Ã Â²â€¢Ã Â²â€”Ã Â³Å Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´â€™Ã Â´Â°Ã ÂµÂ Ã Â´Â¡Ã Â´Â¿Ã Â´Â¸Ã ÂµË†Ã ÂµÂ» Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Â´Â¾Ã ÂµÂ½, Ã Â´â€¦Ã Â´Â¤Ã ÂµÂ Ã Â´Å½Ã Â´Â¡Ã Â´Â¿Ã Â´Â±Ã ÂµÂÃ Â´Â±Ã Â´Â±Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã ÂµÂÃ Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿ Ã Â´ÂµÃ ÂµÂÃ Â´Â¯Ã Â´â€¢Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´ÂªÃ Â´Â°Ã Â´Â®Ã Â´Â¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Assets tool Ã Â°Â¦Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â°Ã Â°Â¾ app-provided premium assets categories Ã Â°Å¡Ã Â±â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â; download Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°ÂµÃ Â°Â¾Ã Â°Â¤ poster canvas Ã Â°Â²Ã Â±â€¹ import Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'The Assets tool can show app-provided premium asset categories; after download, supported assets can be imported onto the poster canvas.',
      hindi:
          'Assets tool app-provided premium asset categories Ã Â¤Â¦Ã Â¤Â¿Ã Â¤â€“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†; download Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ supported assets poster canvas Ã Â¤ÂªÃ Â¤Â° import Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤',
      tamil:
          'Assets tool app-provided premium asset categories Ã Â®â€¢Ã Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â¯ÂÃ Â®Â®Ã Â¯Â; download Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¤ Ã Â®ÂªÃ Â®Â¿Ã Â®Â±Ã Â®â€¢Ã Â¯Â supported assets poster canvas-Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â import Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¯Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Assets tool app-provided premium asset categories Ã Â²Â¤Ã Â³â€¹Ã Â²Â°Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â; download Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¿Ã Â²Â¦ Ã Â²Â¨Ã Â²â€šÃ Â²Â¤Ã Â²Â° supported assets poster canvas Ã Â²â€”Ã Â³â€  import Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Assets tool app-provided premium asset categories Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€š; download Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¤ Ã Â´Â¶Ã Âµâ€¡Ã Â´Â·Ã Â´â€š supported assets poster canvas-Ã Â´Â²Ã Âµâ€¡Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ import Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Ã Â°Å¡Ã Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°â€”Ã Â°Â¾ Ã Â°Â¤Ã Â°Â¯Ã Â°Â¾Ã Â°Â°Ã Â±Ë†Ã Â°Â¨ Ã Â°ÂªÃ Â±â€¹Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â°Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¨Ã Â±Â Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°â€¡Ã Â°Â¤Ã Â°Â°Ã Â±ÂÃ Â°Â²Ã Â°Â¤Ã Â±â€¹ Ã Â°ÂªÃ Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±â€¹Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english: 'Finally, the completed poster can be saved or shared.',
      hindi:
          'Ã Â¤â€¦Ã Â¤â€šÃ Â¤Â¤ Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¤Ã Â¥Ë†Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â° Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â° Ã Â¤â€¢Ã Â¥â€¹ Ã Â¤Â¸Ã Â¥â€¡Ã Â¤Âµ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¶Ã Â¥â€¡Ã Â¤Â¯Ã Â¤Â° Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®â€¡Ã Â®Â±Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿Ã Â®Â¯Ã Â®Â¾Ã Â®â€¢ Ã Â®Â¤Ã Â®Â¯Ã Â®Â¾Ã Â®Â°Ã Â¯Â Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¯Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Å¸ Ã Â®ÂªÃ Â¯â€¹Ã Â®Â¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â°Ã Â¯Ë† Ã Â®Å¡Ã Â¯â€¡Ã Â®Â®Ã Â®Â¿Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢ Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®ÂªÃ Â®â€¢Ã Â®Â¿Ã Â®Â°Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²â€¢Ã Â³Å Ã Â²Â¨Ã Â³â€ Ã Â²Â¯Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²Â¸Ã Â²Â¿Ã Â²Â¦Ã Â³ÂÃ Â²Â§Ã Â²ÂµÃ Â²Â¾Ã Â²Â¦ Ã Â²ÂªÃ Â³â€¹Ã Â²Â¸Ã Â³ÂÃ Â²Å¸Ã Â²Â°Ã Â³Â Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²â€°Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²Â¹Ã Â²â€šÃ Â²Å¡Ã Â²Â¿Ã Â²â€¢Ã Â³Å Ã Â²Â³Ã Â³ÂÃ Â²Â³Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´â€¦Ã Â´ÂµÃ Â´Â¸Ã Â´Â¾Ã Â´Â¨Ã Â´Â®Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿ Ã Â´Â¤Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´Â±Ã Â´Â¾Ã Â´Â¯ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â¸Ã ÂµÂÃ Â´Â±Ã ÂµÂÃ Â´Â±Ã ÂµÂ¼ Ã Â´Â¸Ã Âµâ€¡Ã Â´ÂµÃ ÂµÂ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã ÂµÂÃ Â´â€¢Ã Â´Â¯Ã Âµâ€¹ Ã Â´ÂªÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã Â´Â¯Ã Âµâ€¹ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã Â´Â¾Ã Â´â€š.',
    ),
  ];

  String get subscriptionTitle => strings.localized(
    telugu:
        'Ã Â°Â¸Ã Â°Â¬Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â°Ã Â°Â¿Ã Â°ÂªÃ Â±ÂÃ Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°ÂµÃ Â°Â¿Ã Â°ÂµÃ Â°Â°Ã Â°Â¾Ã Â°Â²Ã Â±Â',
    english: 'Subscription details',
    hindi:
        'Ã Â¤Â¸Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â¸Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¿Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¶Ã Â¤Â¨ Ã Â¤â€Ã Â¤Â° Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â‚¬Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â® Ã Â¤ÂµÃ Â¤Â¿Ã Â¤ÂµÃ Â¤Â°Ã Â¤Â£',
    tamil:
        'Ã Â®Å¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â®Â¾ Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â¯â‚¬Ã Â®Â®Ã Â®Â¿Ã Â®Â¯Ã Â®Â®Ã Â¯Â Ã Â®ÂµÃ Â®Â¿Ã Â®ÂµÃ Â®Â°Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â',
    kannada:
        'Ã Â²Å¡Ã Â²â€šÃ Â²Â¦Ã Â²Â¾Ã Â²Â¦Ã Â²Â¾Ã Â²Â°Ã Â²Â¿Ã Â²â€¢Ã Â³â€  Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â³â‚¬Ã Â²Â®Ã Â²Â¿Ã Â²Â¯Ã Â²â€š Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â²Â°Ã Â²â€”Ã Â²Â³Ã Â³Â',
    malayalam:
        'Ã Â´Â¸Ã Â´Â¬Ã ÂµÂÃ Â´Â¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â°Ã Â´Â¿Ã Â´ÂªÃ ÂµÂÃ Â´Â·Ã ÂµÂ»Ã Â´Â¯Ã ÂµÂÃ Â´â€š Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Âµâ‚¬Ã Â´Â®Ã Â´Â¿Ã Â´Â¯Ã Â´â€š Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ Â´Â°Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã Â´Â³Ã ÂµÂÃ Â´â€š',
  );

  List<String> get subscriptionItems => <String>[
    strings.localized(
      telugu:
          'App Pro poster access, poster creation Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â exports Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°ÂªÃ Â°Â¡Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english: 'App Pro supports poster access, poster creation, and exports.',
      hindi:
          'App Pro poster access, poster creation Ã Â¤â€Ã Â¤Â° exports Ã Â¤â€¢Ã Â¥â€¹ support Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'App Pro poster access, poster creation Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â exports-Ã Â®Â support Ã Â®Å¡Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®â€¢Ã Â®Â¿Ã Â®Â±Ã Â®Â¤Ã Â¯Â.',
      kannada:
          'App Pro poster access, poster creation Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â exports Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â support Ã Â²Â®Ã Â²Â¾Ã Â²Â¡Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ .',
      malayalam:
          'App Pro poster access, poster creation, exports Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ support Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã ÂµÂÃ Â´Â¨Ã ÂµÂÃ Â´Â¨Ã ÂµÂ.',
    ),
    strings.localized(
      telugu:
          'Ã Â°Å¸Ã Â±ÂÃ Â°Â°Ã Â°Â¯Ã Â°Â²Ã Â±Â Ã Â°ÂªÃ Â±ÂÃ Â°Â²Ã Â°Â¾Ã Â°Â¨Ã Â±Â: ${SubscriptionPlanConfig.trialDays} Ã Â°Â°Ã Â±â€¹Ã Â°Å“Ã Â±ÂÃ Â°Â²Ã Â°â€¢Ã Â±Â ${SubscriptionPlanConfig.trialPriceDisplay}.',
      english:
          'Trial plan: ${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days.',
      hindi:
          'Ã Â¤Å¸Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â² Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â²Ã Â¤Â¾Ã Â¤Â¨: 3 Ã Â¤Â¦Ã Â¤Â¿Ã Â¤Â¨Ã Â¥â€¹Ã Â¤â€š Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã¢â€šÂ¹4Ã Â¥Â¤',
      tamil:
          'Ã Â®Å¸Ã Â¯ÂÃ Â®Â°Ã Â®Â¯Ã Â®Â²Ã Â¯Â Ã Â®Â¤Ã Â®Â¿Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â®Â®Ã Â¯Â: 3 Ã Â®Â¨Ã Â®Â¾Ã Â®Å¸Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â Ã¢â€šÂ¹4.',
      kannada:
          'Ã Â²Å¸Ã Â³ÂÃ Â²Â°Ã Â²Â¯Ã Â²Â²Ã Â³Â Ã Â²Â¯Ã Â³â€¹Ã Â²Å“Ã Â²Â¨Ã Â³â€ : 3 Ã Â²Â¦Ã Â²Â¿Ã Â²Â¨Ã Â²â€”Ã Â²Â³Ã Â²Â¿Ã Â²â€”Ã Â³â€  Ã¢â€šÂ¹4.',
      malayalam:
          'Ã Â´Å¸Ã ÂµÂÃ Â´Â°Ã Â´Â¯Ã ÂµÂ½ Ã Â´ÂªÃ Â´Â¦Ã ÂµÂÃ Â´Â§Ã Â´Â¤Ã Â´Â¿: 3 Ã Â´Â¦Ã Â´Â¿Ã Â´ÂµÃ Â´Â¸Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´Â¨Ã ÂµÂ Ã¢â€šÂ¹4.',
    ),
    strings.localized(
      telugu:
          '${SubscriptionPlanConfig.trialDays} Ã Â°Â°Ã Â±â€¹Ã Â°Å“Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°ÂªÃ Â±â€šÃ Â°Â°Ã Â±ÂÃ Â°Â¤Ã Â°Â¯Ã Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°â€¢ Ã Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±Â Ã Â°â€¢Ã Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°Â¨Ã Â±ÂÃ Â°Â¸Ã Â°Â¿Ã Â°Â²Ã Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°â€¢Ã Â°ÂªÃ Â±â€¹Ã Â°Â¤Ã Â±â€¡ Ã Â°Â¨Ã Â±â€ Ã Â°Â²Ã Â°â€¢Ã Â±Â ${SubscriptionPlanConfig.monthlyPriceDisplay} Ã Â°â€ Ã Â°Å¸Ã Â±â€¹ Ã Â°Â°Ã Â±â‚¬Ã Â°Â¨Ã Â±ÂÃ Â°Â¯Ã Â±ÂÃ Â°ÂµÃ Â°Â²Ã Â±ÂÃ¢â‚¬Å’Ã Â°â€”Ã Â°Â¾ Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â°Â¸Ã Â°Â¾Ã Â°â€”Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english:
          'After ${SubscriptionPlanConfig.trialDays} days, it continues at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month with auto-renewal unless cancelled.',
      hindi:
          'Ã Â¤Å¸Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â² Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ Ã Â¤Â¯Ã Â¤Â¹ Ã¢â€šÂ¹149 Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¤Ã Â¤Â¿ Ã Â¤Â®Ã Â¤Â¾Ã Â¤Â¹ Ã Â¤â€˜Ã Â¤Å¸Ã Â¥â€¹-Ã Â¤Â°Ã Â¤Â¿Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¯Ã Â¥â€šÃ Â¤â€¦Ã Â¤Â² Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â¥ Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Â°Ã Â¤Â¹Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®Å¸Ã Â¯ÂÃ Â®Â°Ã Â®Â¯Ã Â®Â²Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â®Â¿Ã Â®Â±Ã Â®â€¢Ã Â¯Â Ã Â®Â®Ã Â®Â¾Ã Â®Â¤Ã Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿Ã Â®Â±Ã Â¯ÂÃ Â®â€¢Ã Â¯Â Ã¢â€šÂ¹149 Ã Â®â€ Ã Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â¯â€¹ Ã Â®Â°Ã Â®Â¿Ã Â®Â©Ã Â®Â¿Ã Â®Â¯Ã Â¯â€šÃ Â®ÂµÃ Â®Â²Ã Â®Â¾Ã Â®â€¢ Ã Â®Â¤Ã Â¯Å Ã Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²Å¸Ã Â³ÂÃ Â²Â°Ã Â²Â¯Ã Â²Â²Ã Â³Â Ã Â²Â¨Ã Â²â€šÃ Â²Â¤Ã Â²Â° Ã Â²Â¤Ã Â²Â¿Ã Â²â€šÃ Â²â€”Ã Â²Â³Ã Â²Â¿Ã Â²â€”Ã Â³â€  Ã¢â€šÂ¹149 Ã Â²â€ Ã Â²Å¸Ã Â³â€¹-Ã Â²Â°Ã Â²Â¿Ã Â²Â¨Ã Â³ÂÃ Â²Â¯Ã Â³â€šÃ Â²ÂµÃ Â²Â²Ã Â³Â Ã Â²Â®Ã Â³â€šÃ Â²Â²Ã Â²â€¢ Ã Â²Â®Ã Â³ÂÃ Â²â€šÃ Â²Â¦Ã Â³ÂÃ Â²ÂµÃ Â²Â°Ã Â³â€ Ã Â²Â¯Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ .',
      malayalam:
          'Ã Â´Å¸Ã ÂµÂÃ Â´Â°Ã Â´Â¯Ã Â´Â²Ã Â´Â¿Ã Â´Â¨Ã ÂµÂ Ã Â´Â¶Ã Âµâ€¡Ã Â´Â·Ã Â´â€š Ã Â´Â®Ã Â´Â¾Ã Â´Â¸Ã Â´â€š Ã¢â€šÂ¹149 Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨ Ã Â´Â¨Ã Â´Â¿Ã Â´Â°Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´â€œÃ Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Âµâ€¹ Ã Â´Â±Ã Â´Â¿Ã Â´Â¨Ã ÂµÂÃ Â´Â¯Ã Âµâ€šÃ Â´ÂµÃ Â´Â²Ã Âµâ€¹Ã Â´Å¸Ã Âµâ€  Ã Â´Â¤Ã ÂµÂÃ Â´Å¸Ã Â´Â°Ã ÂµÂÃ Â´â€š.',
    ),
    strings.localized(
      telugu:
          'Editor Pro Ã Â°Â²Ã Â±â€¹ premium editor assets, Telugu fonts Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â background removal Ã Â°â€°Ã Â°â€šÃ Â°Å¸Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿; available Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Å¡Ã Â±â€¹Ã Â°Å¸ Ã Â°Â¨Ã Â±â€ Ã Â°Â²Ã Â°â€¢Ã Â±Â Ã¢â€šÂ¹99.',
      english:
          'Editor Pro is available separately at Ã¢â€šÂ¹99 per month for premium editor assets, Telugu fonts, and background removal where available.',
      hindi:
          'Editor Pro Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š premium editor assets, Telugu fonts Ã Â¤â€Ã Â¤Â° background removal Ã Â¤Â¶Ã Â¤Â¾Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â² Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€š; Ã Â¤Å“Ã Â¤Â¹Ã Â¤Â¾Ã Â¤Â Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â²Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â§ Ã Â¤Â¹Ã Â¥â€¹ Ã Â¤ÂµÃ Â¤Â¹Ã Â¤Â¾Ã Â¤Â Ã¢â€šÂ¹99 Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¤Ã Â¤Â¿ Ã Â¤Â®Ã Â¤Â¾Ã Â¤Â¹Ã Â¥Â¤',
      tamil:
          'Editor Pro-Ã Â®ÂµÃ Â®Â¿Ã Â®Â²Ã Â¯Â premium editor assets, Telugu fonts Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â background removal Ã Â®â€¡Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â; Ã Â®â€¢Ã Â®Â¿Ã Â®Å¸Ã Â¯Ë†Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®â€¡Ã Â®Å¸Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®Â®Ã Â®Â¾Ã Â®Â¤Ã Â®Â®Ã Â¯Â Ã¢â€šÂ¹99.',
      kannada:
          'Editor Pro Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ premium editor assets, Telugu fonts Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â background removal Ã Â²â€¡Ã Â²Â°Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²ÂµÃ Â³â€ ; Ã Â²Â²Ã Â²Â­Ã Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¿Ã Â²Â°Ã Â³ÂÃ Â²Âµ Ã Â²â€¢Ã Â²Â¡Ã Â³â€  Ã Â²Â¤Ã Â²Â¿Ã Â²â€šÃ Â²â€”Ã Â²Â³Ã Â²Â¿Ã Â²â€”Ã Â³â€  Ã¢â€šÂ¹99.',
      malayalam:
          'Editor Pro-Ã Â´Â¯Ã Â´Â¿Ã ÂµÂ½ premium editor assets, Telugu fonts, background removal Ã Â´Å½Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¿Ã Â´Âµ Ã Â´â€°Ã Â´Â£Ã ÂµÂÃ Â´Å¸Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿Ã Â´Â°Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€š; Ã Â´Â²Ã Â´Â­Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿Ã Â´Å¸Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã ÂµÂ Ã Â´Â®Ã Â´Â¾Ã Â´Â¸Ã Â´â€š Ã¢â€šÂ¹99.',
    ),
    strings.localized(
      telugu:
          'Ã¢â€šÂ¹699 yearly all-access plan available Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Å¡Ã Â±â€¹Ã Â°Å¸ App Pro Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Editor Pro benefits Ã Â°Â°Ã Â±â€ Ã Â°â€šÃ Â°Â¡Ã Â±â€š Ã Â°â€¢Ã Â°Â²Ã Â°Â¿Ã Â°ÂªÃ Â°Â¿ Ã Â°â€¡Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english:
          'The Ã¢â€šÂ¹699 yearly all-access plan includes both App Pro and Editor Pro benefits where the yearly plan is available.',
      hindi:
          'Ã¢â€šÂ¹699 yearly all-access plan Ã Â¤Å“Ã Â¤Â¹Ã Â¤Â¾Ã Â¤Â Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â²Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â§ Ã Â¤Â¹Ã Â¥â€¹, App Pro Ã Â¤â€Ã Â¤Â° Editor Pro Ã Â¤Â¦Ã Â¥â€¹Ã Â¤Â¨Ã Â¥â€¹Ã Â¤â€š benefits Ã Â¤Â¶Ã Â¤Â¾Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â² Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã¢â€šÂ¹699 yearly all-access plan Ã Â®â€¢Ã Â®Â¿Ã Â®Å¸Ã Â¯Ë†Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®â€¡Ã Â®Å¸Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â®Â¿Ã Â®Â²Ã Â¯Â App Pro Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Editor Pro benefits Ã Â®â€¡Ã Â®Â°Ã Â®Â£Ã Â¯ÂÃ Â®Å¸Ã Â¯Ë†Ã Â®Â¯Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Å¡Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â¿Ã Â®Â±Ã Â®Â¤Ã Â¯Â.',
      kannada:
          'Ã¢â€šÂ¹699 yearly all-access plan Ã Â²Â²Ã Â²Â­Ã Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¿Ã Â²Â°Ã Â³ÂÃ Â²Âµ Ã Â²â€¢Ã Â²Â¡Ã Â³â€  App Pro Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Editor Pro benefits Ã Â²Å½Ã Â²Â°Ã Â²Â¡Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³â€š Ã Â²â€™Ã Â²Â³Ã Â²â€”Ã Â³Å Ã Â²â€šÃ Â²Â¡Ã Â²Â¿Ã Â²Â°Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ .',
      malayalam:
          'Ã¢â€šÂ¹699 yearly all-access plan Ã Â´Â²Ã Â´Â­Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿Ã Â´Å¸Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã ÂµÂ App Pro, Editor Pro benefits Ã Â´Â°Ã Â´Â£Ã ÂµÂÃ Â´Å¸Ã ÂµÂÃ Â´â€š Ã Â´â€°Ã ÂµÂ¾Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€š.',
    ),
  ];

  String get languagesTitle => strings.localized(
    telugu:
        'Ã Â°â€¦Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°Â­Ã Â°Â¾Ã Â°Â·Ã Â°Â²Ã Â±Â',
    english: 'Available languages',
    hindi:
        'Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â²Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â§ Ã Â¤Â­Ã Â¤Â¾Ã Â¤Â·Ã Â¤Â¾Ã Â¤ÂÃ Â¤Â',
    tamil:
        'Ã Â®â€¢Ã Â®Â¿Ã Â®Å¸Ã Â¯Ë†Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Â®Ã Â¯Å Ã Â®Â´Ã Â®Â¿Ã Â®â€¢Ã Â®Â³Ã Â¯Â',
    kannada:
        'Ã Â²Â²Ã Â²Â­Ã Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¿Ã Â²Â°Ã Â³ÂÃ Â²Âµ Ã Â²Â­Ã Â²Â¾Ã Â²Â·Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â³Â',
    malayalam:
        'Ã Â´Â²Ã Â´Â­Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â¯ Ã Â´Â­Ã Â´Â¾Ã Â´Â·Ã Â´â€¢Ã ÂµÂ¾',
  );

  List<String> get languageItems => <String>[
    strings.localized(
      telugu:
          'Ã Â°Â¤Ã Â±â€ Ã Â°Â²Ã Â±ÂÃ Â°â€”Ã Â±Â Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â§Ã Â°Â¾Ã Â°Â¨ Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â­Ã Â°ÂµÃ Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Ë† Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°Â°Ã Â±â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â¦Ã Â°Â¿Ã Â°Â¦Ã Â±ÂÃ Â°Â¦Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english: 'This app is designed with Telugu as the primary experience.',
      hindi:
          'Ã Â¤Â¯Ã Â¤Â¹ Ã Â¤ÂÃ Â¤Âª Ã Â¤Â¤Ã Â¥â€¡Ã Â¤Â²Ã Â¥ÂÃ Â¤â€”Ã Â¥Â Ã Â¤â€¢Ã Â¥â€¹ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤Â¥Ã Â¤Â®Ã Â¤Â¿Ã Â¤â€¢ Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â­Ã Â¤Âµ Ã Â¤Â®Ã Â¤Â¾Ã Â¤Â¨Ã Â¤â€¢Ã Â¤Â° Ã Â¤Â¤Ã Â¥Ë†Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â° Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®â€¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤ Ã Â®â€ Ã Â®ÂªÃ Â¯Â Ã Â®Â¤Ã Â¯â€ Ã Â®Â²Ã Â¯ÂÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Ë† Ã Â®Â®Ã Â¯ÂÃ Â®Â¤Ã Â®Â©Ã Â¯ÂÃ Â®Â®Ã Â¯Ë† Ã Â®â€¦Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®ÂµÃ Â®Â®Ã Â®Â¾Ã Â®â€¢Ã Â®â€¢Ã Â¯Â Ã Â®â€¢Ã Â¯Å Ã Â®Â£Ã Â¯ÂÃ Â®Å¸Ã Â¯Â Ã Â®ÂµÃ Â®Å¸Ã Â®Â¿Ã Â®ÂµÃ Â®Â®Ã Â¯Ë†Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Å¸Ã Â¯ÂÃ Â®Â³Ã Â¯ÂÃ Â®Â³Ã Â®Â¤Ã Â¯Â.',
      kannada:
          'Ã Â²Ë† Ã Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²Â¤Ã Â³â€ Ã Â²Â²Ã Â³ÂÃ Â²â€”Ã Â³ÂÃ Â²ÂµÃ Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Â®Ã Â³ÂÃ Â²â€“ Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²Â­Ã Â²ÂµÃ Â²ÂµÃ Â²Â¾Ã Â²â€”Ã Â²Â¿ Ã Â²â€¡Ã Â²Å¸Ã Â³ÂÃ Â²Å¸Ã Â³Â Ã Â²Â°Ã Â³â€šÃ Â²ÂªÃ Â³ÂÃ Â²â€”Ã Â³Å Ã Â²â€šÃ Â²Â¡Ã Â²Â¿Ã Â²Â¦Ã Â³â€ .',
      malayalam:
          'Ã Â´Ë† Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´Â¤Ã Âµâ€ Ã Â´Â²Ã ÂµÂÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã Â´Â¨Ã Âµâ€  Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â§Ã Â´Â¾Ã Â´Â¨ Ã Â´â€¦Ã Â´Â¨Ã ÂµÂÃ Â´Â­Ã Â´ÂµÃ Â´Â®Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿ Ã Â´â€¢Ã Â´Â°Ã ÂµÂÃ Â´Â¤Ã Â´Â¿ Ã Â´Â°Ã Âµâ€šÃ Â´ÂªÃ Â´â€¢Ã ÂµÂ½Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¨ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¤Ã Â´Â¤Ã Â´Â¾Ã Â´Â£Ã ÂµÂ.',
    ),
    strings.localized(
      telugu:
          'Ã Â°Â¤Ã Â±â€ Ã Â°Â²Ã Â±ÂÃ Â°â€”Ã Â±Â, Ã Â°Â¹Ã Â°Â¿Ã Â°â€šÃ Â°Â¦Ã Â±â‚¬, Ã Â°â€¡Ã Â°â€šÃ Â°â€”Ã Â±ÂÃ Â°Â²Ã Â±â‚¬Ã Â°Â·Ã Â±Â, Ã Â°Â¤Ã Â°Â®Ã Â°Â¿Ã Â°Â³Ã Â°â€š, Ã Â°â€¢Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¡, Ã Â°Â®Ã Â°Â²Ã Â°Â¯Ã Â°Â¾Ã Â°Â³Ã Â°â€š, Ã Â°â€¦Ã Â°Â¸Ã Â±ÂÃ Â°Â¸Ã Â°Â¾Ã Â°Â®Ã Â±â‚¬, Ã Â°â€¢Ã Â±Å Ã Â°â€šÃ Â°â€¢Ã Â°Â£Ã Â°Â¿, Ã Â°â€”Ã Â±ÂÃ Â°Å“Ã Â°Â°Ã Â°Â¾Ã Â°Â¤Ã Â±â‚¬, Ã Â°Â®Ã Â°Â°Ã Â°Â¾Ã Â°Â Ã Â±â‚¬, Ã Â°Â®Ã Â±Ë†Ã Â°Â¤Ã Â±â€¡Ã Â°Â¯Ã Â°Â¿, Ã Â°Â®Ã Â°Â¿Ã Â°Å“Ã Â±â€¹, Ã Â°â€™Ã Â°Â¡Ã Â°Â¿Ã Â°Â¯Ã Â°Â¾, Ã Â°ÂªÃ Â°â€šÃ Â°Å“Ã Â°Â¾Ã Â°Â¬Ã Â±â‚¬, Ã Â°Â¨Ã Â±â€¡Ã Â°ÂªÃ Â°Â¾Ã Â°Â²Ã Â°Â¿, Ã Â°Â¬Ã Â±â€ Ã Â°â€šÃ Â°â€”Ã Â°Â¾Ã Â°Â²Ã Â±â‚¬, Ã Â°â€¢Ã Â°Â¾Ã Â°Â¶Ã Â±ÂÃ Â°Â®Ã Â±â‚¬Ã Â°Â°Ã Â±â‚¬ Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â²Ã Â°Â¡Ã Â°Â¾Ã Â°â€“Ã Â±â‚¬ Ã Â°Â­Ã Â°Â¾Ã Â°Â·Ã Â°Â²Ã Â±ÂÃ Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'It can be used in Telugu, Hindi, English, Tamil, Kannada, Malayalam, Assamese, Konkani, Gujarati, Marathi, Meitei, Mizo, Odia, Punjabi, Nepali, Bengali, Kashmiri, and Ladakhi.',
      hindi:
          'Ã Â¤â€¡Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤Â¤Ã Â¥â€¡Ã Â¤Â²Ã Â¥ÂÃ Â¤â€”Ã Â¥Â, Ã Â¤Â¹Ã Â¤Â¿Ã Â¤â€šÃ Â¤Â¦Ã Â¥â‚¬, Ã Â¤â€¦Ã Â¤â€šÃ Â¤â€”Ã Â¥ÂÃ Â¤Â°Ã Â¥â€¡Ã Â¤Å“Ã Â¤Â¼Ã Â¥â‚¬, Ã Â¤Â¤Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â², Ã Â¤â€¢Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¨Ã Â¤Â¡Ã Â¤Â¼, Ã Â¤Â®Ã Â¤Â²Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â²Ã Â¤Â®, Ã Â¤â€¦Ã Â¤Â¸Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾, Ã Â¤â€¢Ã Â¥â€¹Ã Â¤â€šÃ Â¤â€¢Ã Â¤Â£Ã Â¥â‚¬, Ã Â¤â€”Ã Â¥ÂÃ Â¤Å“Ã Â¤Â°Ã Â¤Â¾Ã Â¤Â¤Ã Â¥â‚¬, Ã Â¤Â®Ã Â¤Â°Ã Â¤Â¾Ã Â¤Â Ã Â¥â‚¬, Ã Â¤Â®Ã Â¥Ë†Ã Â¤Â¤Ã Â¥â€¡Ã Â¤Ë†, Ã Â¤Â®Ã Â¤Â¿Ã Â¤Å“Ã Â¥â€¹, Ã Â¤â€œÃ Â¤Â¡Ã Â¤Â¼Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾, Ã Â¤ÂªÃ Â¤â€šÃ Â¤Å“Ã Â¤Â¾Ã Â¤Â¬Ã Â¥â‚¬, Ã Â¤Â¨Ã Â¥â€¡Ã Â¤ÂªÃ Â¤Â¾Ã Â¤Â²Ã Â¥â‚¬, Ã Â¤Â¬Ã Â¤â€šÃ Â¤â€”Ã Â¤Â¾Ã Â¤Â²Ã Â¥â‚¬, Ã Â¤â€¢Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â®Ã Â¥â‚¬Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤â€Ã Â¤Â° Ã Â¤Â²Ã Â¤Â¦Ã Â¥ÂÃ Â¤Â¦Ã Â¤Â¾Ã Â¤â€“Ã Â¥â‚¬ Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€” Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      tamil:
          'Ã Â®â€¡Ã Â®Â¤Ã Â¯Ë† Ã Â®Â¤Ã Â¯â€ Ã Â®Â²Ã Â¯ÂÃ Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â¯Â, Ã Â®â€¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿, Ã Â®â€ Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â¿Ã Â®Â²Ã Â®Â®Ã Â¯Â, Ã Â®Â¤Ã Â®Â®Ã Â®Â¿Ã Â®Â´Ã Â¯Â, Ã Â®â€¢Ã Â®Â©Ã Â¯ÂÃ Â®Â©Ã Â®Å¸Ã Â®Â®Ã Â¯Â, Ã Â®Â®Ã Â®Â²Ã Â¯Ë†Ã Â®Â¯Ã Â®Â¾Ã Â®Â³Ã Â®Â®Ã Â¯Â, Ã Â®â€¦Ã Â®Å¡Ã Â®Â¾Ã Â®Â®Ã Â®Â¿, Ã Â®â€¢Ã Â¯Å Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â£Ã Â®Â¿, Ã Â®â€¢Ã Â¯ÂÃ Â®Å“Ã Â®Â°Ã Â®Â¾Ã Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿, Ã Â®Â®Ã Â®Â°Ã Â®Â¾Ã Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿, Ã Â®Â®Ã Â¯â€ Ã Â®Â¯Ã Â¯ÂÃ Â®Â¤Ã Â¯â€ Ã Â®Â¯Ã Â¯Â, Ã Â®Â®Ã Â®Â¿Ã Â®Å¡Ã Â¯â€¹, Ã Â®â€™Ã Â®Å¸Ã Â®Â¿Ã Â®Â¯Ã Â®Â¾, Ã Â®ÂªÃ Â®Å¾Ã Â¯ÂÃ Â®Å¡Ã Â®Â¾Ã Â®ÂªÃ Â®Â¿, Ã Â®Â¨Ã Â¯â€¡Ã Â®ÂªÃ Â®Â¾Ã Â®Â³Ã Â®Â¿, Ã Â®ÂªÃ Â¯â€ Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â¾Ã Â®Â²Ã Â®Â¿, Ã Â®â€¢Ã Â®Â¾Ã Â®Â·Ã Â¯ÂÃ Â®Â®Ã Â¯â‚¬Ã Â®Â°Ã Â®Â¿ Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Â²Ã Â®Å¸Ã Â®Â¾Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â¿ Ã Â®Â®Ã Â¯Å Ã Â®Â´Ã Â®Â¿Ã Â®â€¢Ã Â®Â³Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²â€¡Ã Â²Â¦Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¤Ã Â³â€ Ã Â²Â²Ã Â³ÂÃ Â²â€”Ã Â³Â, Ã Â²Â¹Ã Â²Â¿Ã Â²â€šÃ Â²Â¦Ã Â²Â¿, Ã Â²â€¡Ã Â²â€šÃ Â²â€”Ã Â³ÂÃ Â²Â²Ã Â²Â¿Ã Â²Â·Ã Â³Â, Ã Â²Â¤Ã Â²Â®Ã Â²Â¿Ã Â²Â³Ã Â³Â, Ã Â²â€¢Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â²Â¡, Ã Â²Â®Ã Â²Â²Ã Â²Â¯Ã Â²Â¾Ã Â²Â³Ã Â²â€š, Ã Â²â€¦Ã Â²Â¸Ã Â³ÂÃ Â²Â¸Ã Â²Â¾Ã Â²Â®Ã Â²Â¿, Ã Â²â€¢Ã Â³Å Ã Â²â€šÃ Â²â€¢Ã Â²Â£Ã Â²Â¿, Ã Â²â€”Ã Â³ÂÃ Â²Å“Ã Â²Â°Ã Â²Â¾Ã Â²Â¤Ã Â²Â¿, Ã Â²Â®Ã Â²Â°Ã Â²Â¾Ã Â²Â Ã Â²Â¿, Ã Â²Â®Ã Â³Ë†Ã Â²Â¤Ã Â³â€¡Ã Â²Â¯Ã Â²Â¿, Ã Â²Â®Ã Â²Â¿Ã Â²Å“Ã Â³â€¹, Ã Â²â€™Ã Â²Â¡Ã Â²Â¿Ã Â²Â¯Ã Â²Â¾, Ã Â²ÂªÃ Â²â€šÃ Â²Å“Ã Â²Â¾Ã Â²Â¬Ã Â²Â¿, Ã Â²Â¨Ã Â³â€¡Ã Â²ÂªÃ Â²Â¾Ã Â²Â³Ã Â²Â¿, Ã Â²Â¬Ã Â³â€ Ã Â²â€šÃ Â²â€”Ã Â²Â¾Ã Â²Â³Ã Â²Â¿, Ã Â²â€¢Ã Â²Â¾Ã Â²Â¶Ã Â³ÂÃ Â²Â®Ã Â³â‚¬Ã Â²Â°Ã Â²Â¿ Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â²Ã Â²Â¡Ã Â²Â¾Ã Â²â€“Ã Â²Â¿ Ã Â²Â­Ã Â²Â¾Ã Â²Â·Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²Â¬Ã Â²Â³Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´â€¡Ã Â´Â¤Ã ÂµÂ Ã Â´Â¤Ã Âµâ€ Ã Â´Â²Ã ÂµÂÃ Â´â„¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ, Ã Â´Â¹Ã Â´Â¿Ã Â´Â¨Ã ÂµÂÃ Â´Â¦Ã Â´Â¿, Ã Â´â€¡Ã Â´â€šÃ Â´â€”Ã ÂµÂÃ Â´Â²Ã Âµâ‚¬Ã Â´Â·Ã ÂµÂ, Ã Â´Â¤Ã Â´Â®Ã Â´Â¿Ã Â´Â´Ã ÂµÂ, Ã Â´â€¢Ã Â´Â¨Ã ÂµÂÃ Â´Â¨Ã Â´Â¡, Ã Â´Â®Ã Â´Â²Ã Â´Â¯Ã Â´Â¾Ã Â´Â³Ã Â´â€š, Ã Â´â€¦Ã Â´Â¸Ã Â´Â®Ã Âµâ‚¬Ã Â´Â¸Ã ÂµÂ, Ã Â´â€¢Ã ÂµÅ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â£Ã Â´Â¿, Ã Â´â€”Ã ÂµÂÃ Â´Å“Ã Â´Â±Ã Â´Â¾Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿, Ã Â´Â®Ã Â´Â±Ã Â´Â¾Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿, Ã Â´Â®Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¤Ã Âµâ€ Ã Â´Â¯Ã ÂµÂ, Ã Â´Â®Ã Â´Â¿Ã Â´Â¸Ã Âµâ€¹, Ã Â´â€™Ã Â´Â¡Ã Â´Â¿Ã Â´Â¯, Ã Â´ÂªÃ Â´Å¾Ã ÂµÂÃ Â´Å¡Ã Â´Â¾Ã Â´Â¬Ã Â´Â¿, Ã Â´Â¨Ã Âµâ€¡Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¾Ã Â´Â³Ã Â´Â¿, Ã Â´Â¬Ã Âµâ€ Ã Â´â€šÃ Â´â€”Ã Â´Â¾Ã Â´Â³Ã Â´Â¿, Ã Â´â€¢Ã Â´Â¾Ã Â´Â¶Ã ÂµÂÃ Â´Â®Ã Âµâ‚¬Ã Â´Â°Ã Â´Â¿, Ã Â´Â²Ã Â´Â¡Ã Â´Â¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿ Ã Â´Â­Ã Â´Â¾Ã Â´Â·Ã Â´â€¢Ã Â´Â³Ã Â´Â¿Ã ÂµÂ½ Ã Â´â€°Ã Â´ÂªÃ Â´Â¯Ã Âµâ€¹Ã Â´â€”Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š.',
    ),
    strings.localized(
      telugu:
          'State/Union Territory Ã Â°Å½Ã Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€¢ Ã Â°â€ Ã Â°Â§Ã Â°Â¾Ã Â°Â°Ã Â°â€šÃ Â°â€”Ã Â°Â¾ Ã Â°Â¸Ã Â°Â°Ã Â°Â¿Ã Â°ÂªÃ Â±â€¹Ã Â°Â¯Ã Â±â€¡ Ã Â°Â­Ã Â°Â¾Ã Â°Â· apply Ã Â°â€¦Ã Â°ÂµÃ Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°â€šÃ Â°Â¦Ã Â°Â¿; core app screens regional translations Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿, Ã Â°â€¢Ã Â±Å Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ editor/file-format technical labels English Ã Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
      english:
          'The matching language is applied from the selected State or Union Territory; core app screens use regional translations, while some editor or file-format technical labels may remain in English.',
      hindi:
          'Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¥â€¡ Ã Â¤â€”Ã Â¤Â Ã Â¤Â°Ã Â¤Â¾Ã Â¤Å“Ã Â¥ÂÃ Â¤Â¯ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¢Ã Â¥â€¡Ã Â¤â€šÃ Â¤Â¦Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¶Ã Â¤Â¾Ã Â¤Â¸Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¦Ã Â¥â€¡Ã Â¤Â¶ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤â€ Ã Â¤Â§Ã Â¤Â¾Ã Â¤Â° Ã Â¤ÂªÃ Â¤Â° Ã Â¤Â¸Ã Â¤â€šÃ Â¤Â¬Ã Â¤â€šÃ Â¤Â§Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤Â­Ã Â¤Â¾Ã Â¤Â·Ã Â¤Â¾ Ã Â¤Â²Ã Â¤Â¾Ã Â¤â€”Ã Â¥â€š Ã Â¤Â¹Ã Â¥â€¹Ã Â¤Â¤Ã Â¥â‚¬ Ã Â¤Â¹Ã Â¥Ë†; core app screens Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š regional translations Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€” Ã Â¤Â¹Ã Â¥â€¹Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€š, Ã Â¤Å“Ã Â¤Â¬Ã Â¤â€¢Ã Â¤Â¿ Ã Â¤â€¢Ã Â¥ÂÃ Â¤â€º editor/file-format technical labels English Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â°Ã Â¤Â¹ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤',
      tamil:
          'Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â¯â€ Ã Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤ Ã Â®Â®Ã Â®Â¾Ã Â®Â¨Ã Â®Â¿Ã Â®Â²Ã Â®Â®Ã Â¯Â Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®Â¯Ã Â¯â€šÃ Â®Â©Ã Â®Â¿Ã Â®Â¯Ã Â®Â©Ã Â¯Â Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Â¤Ã Â¯â€¡Ã Â®Å¡Ã Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿Ã Â®Â©Ã Â¯Â Ã Â®â€¦Ã Â®Å¸Ã Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯Ë†Ã Â®Â¯Ã Â®Â¿Ã Â®Â²Ã Â¯Â Ã Â®ÂªÃ Â¯Å Ã Â®Â°Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â®Ã Â®Â¾Ã Â®Â© Ã Â®Â®Ã Â¯Å Ã Â®Â´Ã Â®Â¿ Ã Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â®Ã Â¯Â; core app screens Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Â¾Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â®Â¿Ã Â®Â¯ Ã Â®Â®Ã Â¯Å Ã Â®Â´Ã Â®Â¿Ã Â®ÂªÃ Â¯â€ Ã Â®Â¯Ã Â®Â°Ã Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Ë†Ã Â®ÂªÃ Â¯Â Ã Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â®Ã Â¯Â, Ã Â®Å¡Ã Â®Â¿Ã Â®Â² editor/file-format technical labels English-Ã Â®Â²Ã Â¯Â Ã Â®â€¡Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â.',
      kannada:
          'Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²Â¦ Ã Â²Â°Ã Â²Â¾Ã Â²Å“Ã Â³ÂÃ Â²Â¯ Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²â€¢Ã Â³â€¡Ã Â²â€šÃ Â²Â¦Ã Â³ÂÃ Â²Â°Ã Â²Â¾Ã Â²Â¡Ã Â²Â³Ã Â²Â¿Ã Â²Â¤ Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Â¦Ã Â³â€¡Ã Â²Â¶Ã Â²Â¦ Ã Â²â€ Ã Â²Â§Ã Â²Â¾Ã Â²Â°Ã Â²Â¦ Ã Â²Â®Ã Â³â€¡Ã Â²Â²Ã Â³â€  Ã Â²Â¹Ã Â³Å Ã Â²â€šÃ Â²Â¦Ã Â³ÂÃ Â²Âµ Ã Â²Â­Ã Â²Â¾Ã Â²Â·Ã Â³â€  Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²ÂµÃ Â²Â¯Ã Â²Â¿Ã Â²Â¸Ã Â²Â²Ã Â²Â¾Ã Â²â€”Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²Â¦Ã Â³â€ ; core app screens Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Â¾Ã Â²Â¦Ã Â³â€¡Ã Â²Â¶Ã Â²Â¿Ã Â²â€¢ Ã Â²â€¦Ã Â²Â¨Ã Â³ÂÃ Â²ÂµÃ Â²Â¾Ã Â²Â¦Ã Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¬Ã Â²Â³Ã Â²Â¸Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â²ÂµÃ Â³â€ , Ã Â²â€¢Ã Â³â€ Ã Â²Â²Ã Â²ÂµÃ Â³Â editor/file-format technical labels English Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â²Â¿ Ã Â²â€¡Ã Â²Â°Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â.',
      malayalam:
          'Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´Â¤Ã ÂµÂÃ Â´Â¤ Ã Â´Â¸Ã Â´â€šÃ Â´Â¸Ã ÂµÂÃ Â´Â¥Ã Â´Â¾Ã Â´Â¨Ã Â´â€š Ã Â´â€¦Ã Â´Â²Ã ÂµÂÃ Â´Â²Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´â€¢Ã Âµâ€¡Ã Â´Â¨Ã ÂµÂÃ Â´Â¦Ã ÂµÂÃ Â´Â°Ã Â´Â­Ã Â´Â°Ã Â´Â£ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¦Ã Âµâ€¡Ã Â´Â¶Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Âµâ€  Ã Â´â€¦Ã Â´Å¸Ã Â´Â¿Ã Â´Â¸Ã ÂµÂÃ Â´Â¥Ã Â´Â¾Ã Â´Â¨Ã Â´Â®Ã Â´Â¾Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿ Ã Â´â€¦Ã Â´Â¨Ã ÂµÂÃ Â´Â¯Ã Âµâ€¹Ã Â´Å“Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â¯ Ã Â´Â­Ã Â´Â¾Ã Â´Â· Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¯Ã Âµâ€¹Ã Â´â€”Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€š; core app screens Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¾Ã Â´Â¦Ã Âµâ€¡Ã Â´Â¶Ã Â´Â¿Ã Â´â€¢ Ã Â´ÂµÃ Â´Â¿Ã Â´ÂµÃ ÂµÂ¼Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¨Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾ Ã Â´â€°Ã Â´ÂªÃ Â´Â¯Ã Âµâ€¹Ã Â´â€”Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€š, Ã Â´Å¡Ã Â´Â¿Ã Â´Â² editor/file-format technical labels English-Ã ÂµÂ½ Ã Â´Â¤Ã ÂµÂÃ Â´Å¸Ã Â´Â°Ã Â´Â¾Ã Â´â€š.',
    ),
  ];

  String get supportTitle => strings.localized(
    telugu:
        'Ã Â°Â¸Ã Â°Â¹Ã Â°Â¾Ã Â°Â¯Ã Â°â€š Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¸Ã Â°â€šÃ Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¦Ã Â°Â¿Ã Â°â€šÃ Â°ÂªÃ Â±Â',
    english: 'Support and contact',
    hindi:
        'Ã Â¤Â¸Ã Â¤Â¹Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤â€Ã Â¤Â° Ã Â¤Â¸Ã Â¤â€šÃ Â¤ÂªÃ Â¤Â°Ã Â¥ÂÃ Â¤â€¢',
    tamil:
        'Ã Â®â€°Ã Â®Â¤Ã Â®ÂµÃ Â®Â¿ Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®Â¤Ã Â¯Å Ã Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®ÂªÃ Â¯Â',
    kannada:
        'Ã Â²Â¸Ã Â²Â¹Ã Â²Â¾Ã Â²Â¯ Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â¸Ã Â²â€šÃ Â²ÂªÃ Â²Â°Ã Â³ÂÃ Â²â€¢',
    malayalam:
        'Ã Â´Â¸Ã Â´Â¹Ã Â´Â¾Ã Â´Â¯Ã Â´ÂµÃ ÂµÂÃ Â´â€š Ã Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Âµâ€ Ã Â´Å¸Ã ÂµÂ½',
  );

  String get supportBody => strings.localized(
    telugu:
        'Ã Â°Â²Ã Â°Â¾Ã Â°â€”Ã Â°Â¿Ã Â°Â¨Ã Â±Â Ã Â°Â¸Ã Â°Â®Ã Â°Â¸Ã Â±ÂÃ Â°Â¯Ã Â°Â²Ã Â±Â, Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹ Ã Â°Å½Ã Â°â€šÃ Â°ÂªÃ Â°Â¿Ã Â°â€¢ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°â€¦Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹Ã Â°Â¡Ã Â±Â Ã Â°â€¡Ã Â°Â¬Ã Â±ÂÃ Â°Â¬Ã Â°â€šÃ Â°Â¦Ã Â±ÂÃ Â°Â²Ã Â±Â, Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°Å½Ã Â°â€”Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°Â¸Ã Â°Â®Ã Â°Â¸Ã Â±ÂÃ Â°Â¯Ã Â°Â²Ã Â±Â, Ã Â°Â¸Ã Â°Â¬Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¸Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â°Ã Â°Â¿Ã Â°ÂªÃ Â±ÂÃ Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°Â¸Ã Â°â€šÃ Â°Â¦Ã Â±â€¡Ã Â°Â¹Ã Â°Â¾Ã Â°Â²Ã Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â°Â¾ Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°ÂµÃ Â°Â¿Ã Â°Â¨Ã Â°Â¿Ã Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¾Ã Â°Â¨Ã Â°Â¿Ã Â°â€¢Ã Â°Â¿ Ã Â°Â¸Ã Â°â€šÃ Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¸Ã Â°Â¹Ã Â°Â¾Ã Â°Â¯Ã Â°â€š Ã Â°â€¢Ã Â±â€¹Ã Â°Â¸Ã Â°â€š Ã Â°Ë† Ã Â°Â®Ã Â±â€ Ã Â°Â¯Ã Â°Â¿Ã Â°Â²Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â¨Ã Â±Â Ã Â°â€°Ã Â°ÂªÃ Â°Â¯Ã Â±â€¹Ã Â°â€”Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â. Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Ë†Ã Â°ÂµÃ Â°Â¸Ã Â±â‚¬ Ã Â°ÂªÃ Â°Â¾Ã Â°Â²Ã Â°Â¸Ã Â±â‚¬ Ã Â°Â®Ã Â°Â°Ã Â°Â¿Ã Â°Â¯Ã Â±Â Ã Â°Â¨Ã Â°Â¿Ã Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¨Ã Â°Â²Ã Â±Â Ã Â°â€¢Ã Â±â€šÃ Â°Â¡Ã Â°Â¾ Ã Â°Â¯Ã Â°Â¾Ã Â°ÂªÃ Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹Ã Â°Â¨Ã Â±â€¡ Ã Â°Å¡Ã Â±â€šÃ Â°Â¡Ã Â°ÂµÃ Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â±Â.',
    english:
        'Use this email for login problems, photo selection or upload issues, save or export problems, subscription questions, or general app support. Privacy Policy and Terms & Conditions are also available inside the app.',
    hindi:
        'Ã Â¤Â²Ã Â¥â€°Ã Â¤â€”Ã Â¤Â¿Ã Â¤Â¨ Ã Â¤Â¸Ã Â¤Â®Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾, Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹ Ã Â¤Å¡Ã Â¥ÂÃ Â¤Â¨Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¦Ã Â¤ÂªÃ Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¦Ã Â¤Â¿Ã Â¤â€¢Ã Â¥ÂÃ Â¤â€¢Ã Â¤Â¤, Ã Â¤Â¸Ã Â¥â€¡Ã Â¤Âµ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤ÂÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â¸Ã Â¤ÂªÃ Â¥â€¹Ã Â¤Â°Ã Â¥ÂÃ Â¤Å¸ Ã Â¤Â¸Ã Â¤Â®Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾, Ã Â¤Â¸Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â¸Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â°Ã Â¤Â¿Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¶Ã Â¤Â¨ Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤Å“Ã Â¥ÂÃ Â¤Â¡Ã Â¤Â¼Ã Â¥â€¡ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â¨, Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â®Ã Â¤Â¾Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¯ Ã Â¤ÂÃ Â¤Âª Ã Â¤Â¸Ã Â¤Â¹Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤â€¡Ã Â¤Â¸ Ã Â¤Ë†Ã Â¤Â®Ã Â¥â€¡Ã Â¤Â² Ã Â¤â€¢Ã Â¤Â¾ Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â¯Ã Â¥â€¹Ã Â¤â€” Ã Â¤â€¢Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤â€¡Ã Â¤ÂµÃ Â¥â€¡Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤ÂªÃ Â¥â€°Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤â€Ã Â¤Â° Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â® Ã Â¤Â­Ã Â¥â‚¬ Ã Â¤ÂÃ Â¤Âª Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â²Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â§ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€šÃ Â¥Â¤',
    tamil:
        'Ã Â®â€°Ã Â®Â³Ã Â¯ÂÃ Â®Â¨Ã Â¯ÂÃ Â®Â´Ã Â¯Ë†Ã Â®ÂµÃ Â¯Â Ã Â®Å¡Ã Â®Â¿Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â²Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®ÂªÃ Â¯ÂÃ Â®â€¢Ã Â¯Ë†Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â®Â®Ã Â¯Â Ã Â®Â¤Ã Â¯â€¡Ã Â®Â°Ã Â¯ÂÃ Â®ÂµÃ Â¯Â Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®ÂªÃ Â®Â¤Ã Â®Â¿Ã Â®ÂµÃ Â¯â€¡Ã Â®Â±Ã Â¯ÂÃ Â®Â± Ã Â®Å¡Ã Â®Â¿Ã Â®Â°Ã Â®Â®Ã Â®Â®Ã Â¯Â, Ã Â®Å¡Ã Â¯â€¡Ã Â®Â®Ã Â®Â¿Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â¯Â Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â®Â¤Ã Â®Â¿ Ã Â®ÂªÃ Â®Â¿Ã Â®Â°Ã Â®Å¡Ã Â¯ÂÃ Â®Å¡Ã Â®Â¿Ã Â®Â©Ã Â¯Ë†Ã Â®â€¢Ã Â®Â³Ã Â¯Â, Ã Â®Å¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â®Â¾ Ã Â®Â¤Ã Â¯Å Ã Â®Å¸Ã Â®Â°Ã Â¯ÂÃ Â®ÂªÃ Â®Â¾Ã Â®Â© Ã Â®Å¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤Ã Â¯â€¡Ã Â®â€¢Ã Â®â„¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â³Ã Â¯Â Ã Â®â€¦Ã Â®Â²Ã Â¯ÂÃ Â®Â²Ã Â®Â¤Ã Â¯Â Ã Â®ÂªÃ Â¯Å Ã Â®Â¤Ã Â¯ÂÃ Â®ÂµÃ Â®Â¾Ã Â®Â© Ã Â®â€ Ã Â®ÂªÃ Â¯Â Ã Â®â€°Ã Â®Â¤Ã Â®ÂµÃ Â®Â¿Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®Â¾Ã Â®â€¢ Ã Â®â€¡Ã Â®Â¨Ã Â¯ÂÃ Â®Â¤ Ã Â®Â®Ã Â®Â¿Ã Â®Â©Ã Â¯ÂÃ Â®Â©Ã Â®Å¾Ã Â¯ÂÃ Â®Å¡Ã Â®Â²Ã Â¯Ë† Ã Â®ÂªÃ Â®Â¯Ã Â®Â©Ã Â¯ÂÃ Â®ÂªÃ Â®Å¸Ã Â¯ÂÃ Â®Â¤Ã Â¯ÂÃ Â®Â¤Ã Â®Â²Ã Â®Â¾Ã Â®Â®Ã Â¯Â. Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®Â¯Ã Â¯ÂÃ Â®Â°Ã Â®Â¿Ã Â®Â®Ã Â¯Ë†Ã Â®â€¢Ã Â¯Â Ã Â®â€¢Ã Â¯Å Ã Â®Â³Ã Â¯ÂÃ Â®â€¢Ã Â¯Ë† Ã Â®Â®Ã Â®Â±Ã Â¯ÂÃ Â®Â±Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®ÂµÃ Â®Â¿Ã Â®Â¤Ã Â®Â¿Ã Â®Â®Ã Â¯ÂÃ Â®Â±Ã Â¯Ë†Ã Â®â€¢Ã Â®Â³Ã Â¯ÂÃ Â®Â®Ã Â¯Â Ã Â®â€ Ã Â®ÂªÃ Â¯ÂÃ Â®ÂªÃ Â®Â¿Ã Â®Â²Ã Â¯â€¡Ã Â®Â¯Ã Â¯â€¡ Ã Â®â€¢Ã Â®Â¿Ã Â®Å¸Ã Â¯Ë†Ã Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®Â®Ã Â¯Â.',
    kannada:
        'Ã Â²Â²Ã Â²Â¾Ã Â²â€”Ã Â²Â¿Ã Â²Â¨Ã Â³Â Ã Â²Â¸Ã Â²Â®Ã Â²Â¸Ã Â³ÂÃ Â²Â¯Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²Â«Ã Â³â€¹Ã Â²Å¸Ã Â³â€¹ Ã Â²â€ Ã Â²Â¯Ã Â³ÂÃ Â²â€¢Ã Â³â€  Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²â€¦Ã Â²ÂªÃ Â³ÂÃ¢â‚¬Å’Ã Â²Â²Ã Â³â€¹Ã Â²Â¡Ã Â³Â Ã Â²Â¤Ã Â³Å Ã Â²â€šÃ Â²Â¦Ã Â²Â°Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²â€°Ã Â²Â³Ã Â²Â¿Ã Â²Â¸Ã Â³ÂÃ Â²ÂµÃ Â²Â¿Ã Â²â€¢Ã Â³â€  Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²Å½Ã Â²â€¢Ã Â³ÂÃ Â²Â¸Ã Â³ÂÃ¢â‚¬Å’Ã Â²ÂªÃ Â³â€¹Ã Â²Â°Ã Â³ÂÃ Â²Å¸Ã Â³Â Ã Â²Â¸Ã Â²Â®Ã Â²Â¸Ã Â³ÂÃ Â²Â¯Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â³Â, Ã Â²Å¡Ã Â²â€šÃ Â²Â¦Ã Â²Â¾Ã Â²Â¦Ã Â²Â¾Ã Â²Â°Ã Â²Â¿Ã Â²â€¢Ã Â³â€  Ã Â²ÂªÃ Â³ÂÃ Â²Â°Ã Â²Â¶Ã Â³ÂÃ Â²Â¨Ã Â³â€ Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²â€¦Ã Â²Â¥Ã Â²ÂµÃ Â²Â¾ Ã Â²Â¸Ã Â²Â¾Ã Â²Â®Ã Â²Â¾Ã Â²Â¨Ã Â³ÂÃ Â²Â¯ Ã Â²â€ Ã Â²ÂªÃ Â³Â Ã Â²Â¸Ã Â²Â¹Ã Â²Â¾Ã Â²Â¯Ã Â²â€¢Ã Â³ÂÃ Â²â€¢Ã Â²Â¾Ã Â²â€”Ã Â²Â¿ Ã Â²Ë† Ã Â²â€¡Ã Â²Â®Ã Â³â€¡Ã Â²Â²Ã Â³Â Ã Â²Â¬Ã Â²Â³Ã Â²Â¸Ã Â²Â¬Ã Â²Â¹Ã Â³ÂÃ Â²Â¦Ã Â³Â. Ã Â²â€”Ã Â³Å’Ã Â²ÂªÃ Â³ÂÃ Â²Â¯Ã Â²Â¤Ã Â²Â¾ Ã Â²Â¨Ã Â³â‚¬Ã Â²Â¤Ã Â²Â¿ Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â¨Ã Â²Â¿Ã Â²Â¯Ã Â²Â®Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²â€¢Ã Â³â€šÃ Â²Â¡ Ã Â²â€ Ã Â²ÂªÃ Â³ÂÃ¢â‚¬Å’Ã Â²Â¨Ã Â²Â²Ã Â³ÂÃ Â²Â²Ã Â³â€¡ Ã Â²Â²Ã Â²Â­Ã Â³ÂÃ Â²Â¯Ã Â²ÂµÃ Â²Â¿Ã Â²ÂµÃ Â³â€ .',
    malayalam:
        'Ã Â´Â²Ã Âµâ€¹Ã Â´â€”Ã Â´Â¿Ã ÂµÂ» Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¶Ã ÂµÂÃ Â´Â¨Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾, Ã Â´Â«Ã Âµâ€¹Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã Âµâ€¹ Ã Â´Â¤Ã Â´Â¿Ã Â´Â°Ã Â´Å¾Ã ÂµÂÃ Â´Å¾Ã Âµâ€ Ã Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´â€¢Ã ÂµÂ½ Ã Â´â€¦Ã Â´Â²Ã ÂµÂÃ Â´Â²Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´â€¦Ã Â´ÂªÃ ÂµÂÃ¢â‚¬Å’Ã Â´Â²Ã Âµâ€¹Ã Â´Â¡Ã ÂµÂ Ã Â´Â¬Ã ÂµÂÃ Â´Â¦Ã ÂµÂÃ Â´Â§Ã Â´Â¿Ã Â´Â®Ã ÂµÂÃ Â´Å¸Ã ÂµÂÃ Â´Å¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂ¾, Ã Â´Â¸Ã Âµâ€¡Ã Â´ÂµÃ ÂµÂ Ã Â´Å¡Ã Âµâ€ Ã Â´Â¯Ã ÂµÂÃ Â´Â¯Ã ÂµÂ½ Ã Â´â€¦Ã Â´Â²Ã ÂµÂÃ Â´Â²Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´Å½Ã Â´â€¢Ã ÂµÂÃ Â´Â¸Ã ÂµÂÃ Â´ÂªÃ Âµâ€¹Ã ÂµÂ¼Ã Â´Å¸Ã ÂµÂÃ Â´Å¸Ã ÂµÂ Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã Â´Â¶Ã ÂµÂÃ Â´Â¨Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾, Ã Â´Â¸Ã Â´Â¬Ã ÂµÂÃ Â´Â¸Ã ÂµÂÃ Â´â€¢Ã ÂµÂÃ Â´Â°Ã Â´Â¿Ã Â´ÂªÃ ÂµÂÃ Â´Â·Ã ÂµÂ» Ã Â´Â¸Ã Â´â€šÃ Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´Â®Ã Â´Â¾Ã Â´Â¯ Ã Â´Â¸Ã Â´â€šÃ Â´Â¶Ã Â´Â¯Ã Â´â„¢Ã ÂµÂÃ Â´â„¢Ã ÂµÂ¾, Ã Â´â€¦Ã Â´Â²Ã ÂµÂÃ Â´Â²Ã Âµâ€ Ã Â´â„¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¿Ã ÂµÂ½ Ã Â´ÂªÃ ÂµÅ Ã Â´Â¤Ã ÂµÂÃ Â´ÂµÃ Â´Â¾Ã Â´Â¯ Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ ÂµÂ Ã Â´Â¸Ã Â´Â¹Ã Â´Â¾Ã Â´Â¯Ã Â´Â¤Ã ÂµÂÃ Â´Â¤Ã Â´Â¿Ã Â´Â¨Ã Â´Â¾Ã Â´Â¯Ã Â´Â¿ Ã Â´Ë† Ã Â´â€¡Ã Â´Â®Ã Âµâ€ Ã Â´Â¯Ã Â´Â¿Ã ÂµÂ½ Ã Â´â€°Ã Â´ÂªÃ Â´Â¯Ã Âµâ€¹Ã Â´â€”Ã Â´Â¿Ã Â´â€¢Ã ÂµÂÃ Â´â€¢Ã Â´Â¾Ã Â´â€š. Ã Â´ÂªÃ ÂµÂÃ Â´Â°Ã ÂµË†Ã Â´ÂµÃ Â´Â¸Ã Â´Â¿ Ã Â´ÂªÃ Âµâ€¹Ã Â´Â³Ã Â´Â¿Ã Â´Â¸Ã Â´Â¿Ã Â´Â¯Ã ÂµÂÃ Â´â€š Ã Â´Â¨Ã Â´Â¿Ã Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´Â¨Ã Â´â€¢Ã Â´Â³Ã ÂµÂÃ Â´â€š Ã Â´â€ Ã Â´ÂªÃ ÂµÂÃ Â´ÂªÃ Â´Â¿Ã Â´Â¨Ã ÂµÂÃ Â´Â³Ã ÂµÂÃ Â´Â³Ã Â´Â¿Ã ÂµÂ½ Ã Â´Â²Ã Â´Â­Ã ÂµÂÃ Â´Â¯Ã Â´Â®Ã Â´Â¾Ã Â´Â£Ã ÂµÂ.',
  );

  String get privacyButton => strings.localized(
    telugu:
        'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â±Ë†Ã Â°ÂµÃ Â°Â¸Ã Â±â‚¬ Ã Â°ÂªÃ Â°Â¾Ã Â°Â²Ã Â°Â¸Ã Â±â‚¬ Ã Â°Å¡Ã Â±â€šÃ Â°Â¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿',
    english: 'View Privacy Policy',
    hindi:
        'Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤â€¡Ã Â¤ÂµÃ Â¥â€¡Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤ÂªÃ Â¥â€°Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¥â€¡Ã Â¤â€š',
    tamil:
        'Ã Â®Â¤Ã Â®Â©Ã Â®Â¿Ã Â®Â¯Ã Â¯ÂÃ Â®Â°Ã Â®Â¿Ã Â®Â®Ã Â¯Ë†Ã Â®â€¢Ã Â¯Â Ã Â®â€¢Ã Â¯Å Ã Â®Â³Ã Â¯ÂÃ Â®â€¢Ã Â¯Ë†Ã Â®Â¯Ã Â¯Ë† Ã Â®ÂªÃ Â®Â¾Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®ÂµÃ Â¯ÂÃ Â®Â®Ã Â¯Â',
    kannada:
        'Ã Â²â€”Ã Â³Å’Ã Â²ÂªÃ Â³ÂÃ Â²Â¯Ã Â²Â¤Ã Â²Â¾ Ã Â²Â¨Ã Â³â‚¬Ã Â²Â¤Ã Â²Â¿Ã Â²Â¯Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¨Ã Â³â€¹Ã Â²Â¡Ã Â²Â¿',
    malayalam:
        'Ã Â´Â¸Ã ÂµÂÃ Â´ÂµÃ Â´â€¢Ã Â´Â¾Ã Â´Â°Ã ÂµÂÃ Â´Â¯Ã Â´Â¤Ã Â´Â¾ Ã Â´Â¨Ã Â´Â¯Ã Â´â€š Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã ÂµÂÃ Â´â€¢',
  );

  String get termsButton => strings.localized(
    telugu:
        'Ã Â°Â¨Ã Â°Â¿Ã Â°Â¬Ã Â°â€šÃ Â°Â§Ã Â°Â¨Ã Â°Â²Ã Â±Â Ã Â°Å¡Ã Â±â€šÃ Â°Â¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿',
    english: 'View Terms & Conditions',
    hindi:
        'Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â® Ã Â¤â€Ã Â¤Â° Ã Â¤Â¶Ã Â¤Â°Ã Â¥ÂÃ Â¤Â¤Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¥â€¡Ã Â¤â€š',
    tamil:
        'Ã Â®ÂµÃ Â®Â¿Ã Â®Â¤Ã Â®Â¿Ã Â®Â®Ã Â¯ÂÃ Â®Â±Ã Â¯Ë†Ã Â®â€¢Ã Â®Â³Ã Â¯Ë† Ã Â®ÂªÃ Â®Â¾Ã Â®Â°Ã Â¯ÂÃ Â®â€¢Ã Â¯ÂÃ Â®â€¢Ã Â®ÂµÃ Â¯ÂÃ Â®Â®Ã Â¯Â',
    kannada:
        'Ã Â²Â¨Ã Â²Â¿Ã Â²Â¯Ã Â²Â®Ã Â²â€”Ã Â²Â³Ã Â³Â Ã Â²Â®Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³Â Ã Â²Â·Ã Â²Â°Ã Â²Â¤Ã Â³ÂÃ Â²Â¤Ã Â³ÂÃ Â²â€”Ã Â²Â³Ã Â²Â¨Ã Â³ÂÃ Â²Â¨Ã Â³Â Ã Â²Â¨Ã Â³â€¹Ã Â²Â¡Ã Â²Â¿',
    malayalam:
        'Ã Â´Â¨Ã Â´Â¿Ã Â´Â¬Ã Â´Â¨Ã ÂµÂÃ Â´Â§Ã Â´Â¨Ã Â´â€¢Ã ÂµÂ¾ Ã Â´â€¢Ã Â´Â¾Ã Â´Â£Ã ÂµÂÃ Â´â€¢',
  );
}
