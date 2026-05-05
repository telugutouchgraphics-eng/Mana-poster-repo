// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/home_category_catalog.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/landing_page_config.dart';
import 'package:mana_poster/features/prehome/models/website_poster.dart';
import 'package:mana_poster/features/prehome/services/landing_page_config_service.dart';
import 'package:mana_poster/features/prehome/services/website_poster_service.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  _LandingPageData _data = _LandingPageData.fallback();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final LandingPageConfig config = await const LandingPageConfigService()
        .fetchConfig();
    final List<WebsitePoster> posters = await const WebsitePosterService()
        .fetchActivePosters();
    if (!mounted) {
      return;
    }
    setState(() {
      _data = _LandingPageData(config: config, posters: posters);
    });
  }

  Future<void> _openUrl(String rawUrl) async {
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _LandingPageData data = _data;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF3),
      body: PublicAppLandingPage(
        config: data.config,
        posters: data.posters,
        onInstall: () => _openUrl(
          data.config.downloadUrl.isEmpty
              ? AppPublicInfo.playStoreUrl
              : data.config.downloadUrl,
        ),
        onDemo: () => _openUrl(data.config.watchDemoUrl),
        onPrivacy: () => _openUrl(AppPublicInfo.privacyPolicyUrl),
        onTerms: () => _openUrl(AppPublicInfo.termsUrl),
      ),
    );
  }
}

class LandingPagePreview extends StatefulWidget {
  const LandingPagePreview({
    super.key,
    required this.config,
    required this.posters,
    required this.onInstall,
    required this.onDemo,
    required this.onPrivacy,
    required this.onTerms,
    this.sectionEditActions = const <String, VoidCallback>{},
  });

  final LandingPageConfig config;
  final List<WebsitePoster> posters;
  final VoidCallback onInstall;
  final VoidCallback onDemo;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final Map<String, VoidCallback> sectionEditActions;

  @override
  State<LandingPagePreview> createState() => _LandingPagePreviewState();
}

class _LandingPagePreviewState extends State<LandingPagePreview> {
  String _selectedCategoryId = HomeCategoryCatalog.all.first.id;

  @override
  Widget build(BuildContext context) {
    final LandingPageConfig config = widget.config;
    final HomeCategoryCatalogEntry selectedCategory = HomeCategoryCatalog.all
        .firstWhere(
          (HomeCategoryCatalogEntry item) => item.id == _selectedCategoryId,
          orElse: () => HomeCategoryCatalog.all.first,
        );

    return CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeaderDelegate(
            config: config,
            installLabel: config.heroPrimaryCtaLabel.isEmpty
                ? 'Install App'
                : config.heroPrimaryCtaLabel,
            onInstall: widget.onInstall,
          ),
        ),
        if (config.showHero)
          SliverToBoxAdapter(
            child: _EditableLandingSection(
              label: 'Hero',
              onEdit: widget.sectionEditActions['hero'],
              child: _JoyBanner(
                config: config,
                onInstall: widget.onInstall,
                onDemo: widget.onDemo,
              ),
            ),
          ),
        if (config.showCategories)
          SliverToBoxAdapter(
            child: _EditableLandingSection(
              label: 'Categories',
              onEdit: widget.sectionEditActions['categories'],
              child: _CategoryChipsSection(
                config: config,
                selectedId: _selectedCategoryId,
                onSelected: (String id) {
                  setState(() => _selectedCategoryId = id);
                },
              ),
            ),
          ),
        if (config.showCategories)
          SliverToBoxAdapter(
            child: _EditableLandingSection(
              label: 'Posters',
              onEdit: widget.sectionEditActions['posters'],
              child: _PosterGallerySection(
                category: selectedCategory,
                posters: widget.posters,
              ),
            ),
          ),
        if (config.showFeatures)
          SliverToBoxAdapter(
            child: _EditableLandingSection(
              label: 'Features',
              onEdit: widget.sectionEditActions['features'],
              child: _AppFeaturesSection(config: config),
            ),
          ),
        if (config.showPreview)
          SliverToBoxAdapter(
            child: _EditableLandingSection(
              label: 'Preview',
              onEdit: widget.sectionEditActions['preview'],
              child: _CreatorFlowSection(config: config),
            ),
          ),
        if (config.showDynamicEvents || config.showPlans || config.showFaq)
          SliverToBoxAdapter(
            child: _EditableLandingSection(
              label: 'Why Section',
              onEdit: widget.sectionEditActions['why'],
              child: _WhyManaPosterSection(config: config),
            ),
          ),
        if (config.showDownloadCta)
          SliverToBoxAdapter(
            child: _EditableLandingSection(
              label: 'Download CTA',
              onEdit: widget.sectionEditActions['download'],
              child: _DownloadCtaSection(
                config: config,
                onInstall: widget.onInstall,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: _EditableLandingSection(
            label: 'Footer',
            onEdit: widget.sectionEditActions['footer'],
            child: _FooterSection(
              config: config,
              onInstall: widget.onInstall,
              onPrivacy: widget.onPrivacy,
              onTerms: widget.onTerms,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableLandingSection extends StatelessWidget {
  const _EditableLandingSection({
    required this.label,
    required this.child,
    this.onEdit,
  });

  final String label;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (onEdit == null) {
      return child;
    }
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          top: 12,
          right: 12,
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text('Edit $label'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _LandingPageData {
  const _LandingPageData({required this.config, required this.posters});

  factory _LandingPageData.fallback() {
    return _LandingPageData(
      config: LandingPageConfig.fallback(),
      posters: const <WebsitePoster>[],
    );
  }

  final LandingPageConfig config;
  final List<WebsitePoster> posters;
}

const double _publicManualBannerCompactHeight = 320;
const double _publicManualBannerWideHeight = 560;

class PublicAppLandingPage extends StatefulWidget {
  const PublicAppLandingPage({
    super.key,
    required this.config,
    required this.posters,
    required this.onInstall,
    required this.onDemo,
    required this.onPrivacy,
    required this.onTerms,
  });

  final LandingPageConfig config;
  final List<WebsitePoster> posters;
  final VoidCallback onInstall;
  final VoidCallback onDemo;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  State<PublicAppLandingPage> createState() => _PublicAppLandingPageState();
}

class _PublicAppLandingPageState extends State<PublicAppLandingPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    context.currentLanguage;
    final List<_PublicPosterCategory> categories = _allPublicCategories(
      widget.posters,
    );
    final String? selectedCategory =
        categories.any(
          (_PublicPosterCategory category) => category.id == _selectedCategory,
        )
        ? _selectedCategory
        : (categories.isEmpty ? null : categories.first.id);
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(child: _PublicHeader(onInstall: widget.onInstall)),
        SliverToBoxAdapter(
          child: _PublicManualBanner(
            config: widget.config,
            onInstall: widget.onInstall,
            onDemo: widget.onDemo,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicHeroBanner(
            config: widget.config,
            posters: widget.posters,
            onInstall: widget.onInstall,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicCategoryRibbon(
            categories: categories,
            selectedCategory: selectedCategory,
            onSelected: (String category) {
              setState(() => _selectedCategory = category);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicPosterShowcase(
            posters: widget.posters,
            selectedCategory: selectedCategory,
          ),
        ),
        SliverToBoxAdapter(child: _PublicAudienceSection(config: widget.config)),
        SliverToBoxAdapter(child: _PublicPromiseSection(config: widget.config)),
        SliverToBoxAdapter(
          child: _PublicInsideAppSection(config: widget.config),
        ),
        SliverToBoxAdapter(child: _PublicDailyFlowSection(config: widget.config)),
        SliverToBoxAdapter(child: _PublicUseCasesSection(config: widget.config)),
        SliverToBoxAdapter(child: _PublicTrustSection(config: widget.config)),
        SliverToBoxAdapter(child: _PublicFaqSection(config: widget.config)),
        SliverToBoxAdapter(
          child: _PublicDownloadSection(
            config: widget.config,
            onInstall: widget.onInstall,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _PublicFooter(
            config: widget.config,
            onPrivacy: widget.onPrivacy,
            onTerms: widget.onTerms,
          ),
        ),
      ],
    );
  }
}

class WebsiteInlineEditableLandingPage extends StatefulWidget {
  const WebsiteInlineEditableLandingPage({
    super.key,
    required this.config,
    required this.posters,
    required this.controllers,
    required this.selectedCategoryId,
    required this.onSelectedCategory,
    required this.onUploadBanner,
    required this.onUploadPoster,
    required this.onTogglePoster,
    required this.onReplacePoster,
    required this.onDeletePoster,
    required this.onInstall,
    required this.onDemo,
    required this.onPrivacy,
    required this.onTerms,
    required this.bannerSizeLabel,
  });

  final LandingPageConfig config;
  final List<WebsitePoster> posters;
  final Map<String, TextEditingController> controllers;
  final String selectedCategoryId;
  final ValueChanged<String> onSelectedCategory;
  final VoidCallback? onUploadBanner;
  final VoidCallback? onUploadPoster;
  final ValueChanged<WebsitePoster> onTogglePoster;
  final ValueChanged<WebsitePoster> onReplacePoster;
  final ValueChanged<WebsitePoster> onDeletePoster;
  final VoidCallback onInstall;
  final VoidCallback onDemo;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final String bannerSizeLabel;

  @override
  State<WebsiteInlineEditableLandingPage> createState() =>
      _WebsiteInlineEditableLandingPageState();
}

class _WebsiteInlineEditableLandingPageState
    extends State<WebsiteInlineEditableLandingPage> {
  @override
  Widget build(BuildContext context) {
    context.currentLanguage;
    final List<_PublicPosterCategory> categories = _allPublicCategories(
      widget.posters,
    );
    final String? selectedCategory =
        categories.any(
          (_PublicPosterCategory category) =>
              category.id == widget.selectedCategoryId,
        )
        ? widget.selectedCategoryId
        : (categories.isEmpty ? null : categories.first.id);
    final List<WebsitePoster> selectedPosters = selectedCategory == null
        ? const <WebsitePoster>[]
        : widget.posters
              .where(
                (WebsitePoster poster) =>
                    HomeCategoryCatalog.normalizeKey(poster.category) ==
                    selectedCategory,
              )
              .toList(growable: false)
          ..sort(
            (WebsitePoster a, WebsitePoster b) =>
                b.sortOrder.compareTo(a.sortOrder),
          );

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _EditablePublicHeader(
            controllers: widget.controllers,
            onInstall: widget.onInstall,
          ),
        ),
        SliverToBoxAdapter(
          child: _EditablePublicManualBanner(
            imageUrl: _controllerText(
              widget.controllers,
              'heroImageUrl',
              widget.config.heroImageUrl,
            ),
            primaryButton: widget.controllers['heroPrimaryCtaLabel'],
            secondaryButton: widget.controllers['heroSecondaryCtaLabel'],
            onUpload: widget.onUploadBanner,
            bannerSizeLabel: widget.bannerSizeLabel,
          ),
        ),
        SliverToBoxAdapter(
          child: _EditablePublicHeroBanner(
            controllers: widget.controllers,
            posters: widget.posters,
            onInstall: widget.onInstall,
          ),
        ),
        SliverToBoxAdapter(
          child: _EditablePublicCategoryRibbon(
            categories: categories,
            selectedCategory: selectedCategory,
            controllers: widget.controllers,
            onSelected: widget.onSelectedCategory,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicPosterShowcase(
            posters: widget.posters,
            selectedCategory: selectedCategory,
          ),
        ),
        SliverToBoxAdapter(
          child: _EditablePosterUploadSection(
            controllers: widget.controllers,
            selectedCategoryId: selectedCategory,
            selectedPosters: selectedPosters,
            onUploadPoster: widget.onUploadPoster,
            onTogglePoster: widget.onTogglePoster,
            onReplacePoster: widget.onReplacePoster,
            onDeletePoster: widget.onDeletePoster,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicAudienceSection(
            config: widget.config,
            controllers: widget.controllers,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicPromiseSection(
            config: widget.config,
            controllers: widget.controllers,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicInsideAppSection(
            config: widget.config,
            controllers: widget.controllers,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicDailyFlowSection(
            config: widget.config,
            controllers: widget.controllers,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicUseCasesSection(
            config: widget.config,
            controllers: widget.controllers,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicTrustSection(
            config: widget.config,
            controllers: widget.controllers,
          ),
        ),
        SliverToBoxAdapter(
          child: _PublicFaqSection(
            config: widget.config,
            controllers: widget.controllers,
          ),
        ),
        SliverToBoxAdapter(
          child: _EditablePublicDownloadSection(
            controllers: widget.controllers,
            onInstall: widget.onInstall,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EditablePublicFooter(
            controllers: widget.controllers,
            config: widget.config,
            onPrivacy: widget.onPrivacy,
            onTerms: widget.onTerms,
          ),
        ),
      ],
    );
  }
}

String _controllerText(
  Map<String, TextEditingController> controllers,
  String key,
  String fallback,
) {
  final String? value = controllers[key]?.text.trim();
  if (value == null || value.isEmpty) {
    return fallback;
  }
  return value;
}

String _cmsTextValue({
  required LandingPageConfig? config,
  required Map<String, TextEditingController>? controllers,
  required String key,
  required String fallback,
}) {
  final String? controllerValue = controllers?[key]?.text.trim();
  if (controllerValue != null && controllerValue.isNotEmpty) {
    return controllerValue;
  }
  if (config != null) {
    final String mapped = (config.customText[key] ?? '').trim();
    if (mapped.isNotEmpty) {
      return mapped;
    }
  }
  return fallback;
}

class _EditablePublicHeader extends StatelessWidget {
  const _EditablePublicHeader({
    required this.controllers,
    required this.onInstall,
  });

  final Map<String, TextEditingController> controllers;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: compact ? 70 : 78,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 42),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFFFE0B2), width: 1),
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/branding/mana_poster_logo.png',
                  width: compact ? 42 : 48,
                  height: compact ? 42 : 48,
                  errorBuilder: (_, _, _) => Container(
                    width: compact ? 42 : 48,
                    height: compact ? 42 : 48,
                    color: const Color(0xFFFF5A5F),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: _EditorInlineText(
                  controller: controllers['customText.headerAppName'],
                  fallback: 'Mana Poster',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                ),
              ),
              const Spacer(),
              if (!compact) ...<Widget>[
                _EditorHeaderNavText(
                  controller: controllers['customText.navCategories'],
                  fallback: 'App',
                ),
                _EditorHeaderNavText(
                  controller: controllers['customText.navPosters'],
                  fallback: 'Categories',
                ),
                _EditorHeaderNavText(
                  controller: controllers['customText.navFeatures'],
                  fallback: 'Benefits',
                ),
                _EditorHeaderNavText(
                  controller: controllers['customText.navSupport'],
                  fallback: 'Download',
                ),
                const SizedBox(width: 12),
              ],
              _PublicLanguageMenu(compact: compact),
              SizedBox(width: compact ? 8 : 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? 118 : 156,
                  minWidth: compact ? 110 : 146,
                ),
                child: _EditorFilledActionButton(
                  controller: controllers['downloadButtonLabel'],
                  fallback: compact ? _tr(context, 'Install') : _tr(context, 'Install App'),
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  borderColor: const Color(0xFF111827),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  onTap: onInstall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorHeaderNavText extends StatelessWidget {
  const _EditorHeaderNavText({
    required this.controller,
    required this.fallback,
  });

  final TextEditingController? controller;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: 88,
        child: _EditorInlineText(
          controller: controller,
          fallback: fallback,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w800,
          ),
          centered: true,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _EditablePublicManualBanner extends StatelessWidget {
  const _EditablePublicManualBanner({
    required this.imageUrl,
    required this.primaryButton,
    required this.secondaryButton,
    required this.onUpload,
    required this.bannerSizeLabel,
  });

  final String imageUrl;
  final TextEditingController? primaryButton;
  final TextEditingController? secondaryButton;
  final VoidCallback? onUpload;
  final String bannerSizeLabel;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 760;
    return SizedBox(
      width: double.infinity,
      height: compact
          ? _publicManualBannerCompactHeight
          : _publicManualBannerWideHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (imageUrl.isEmpty)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFFFB703),
                    Color(0xFFFF7A00),
                    Color(0xFFE11D48),
                  ],
                ),
              ),
            )
          else
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFFFFB703),
                      Color(0xFFFF7A00),
                      Color(0xFFE11D48),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _EditorUploadBadge(
                  onPressed: onUpload,
                  label: '+ Upload',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    bannerSizeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: compact ? 16 : 42,
            right: compact ? 16 : 42,
            bottom: compact ? 18 : 34,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: compact ? 176 : 198,
                  child: _EditorFilledActionButton(
                    controller: primaryButton,
                    fallback: _tr(context, 'Play Store'),
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    borderColor: const Color(0xFFE11D48),
                    icon: const Icon(Icons.shop_rounded, size: 18),
                  ),
                ),
                SizedBox(
                  width: compact ? 188 : 212,
                  child: _EditorFilledActionButton(
                    controller: secondaryButton,
                    fallback: _tr(context, 'Watch Demo'),
                    backgroundColor: Colors.white.withValues(alpha: 0.94),
                    foregroundColor: const Color(0xFF111827),
                    borderColor: Colors.white,
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditablePublicHeroBanner extends StatelessWidget {
  const _EditablePublicHeroBanner({
    required this.controllers,
    required this.posters,
    required this.onInstall,
  });

  final Map<String, TextEditingController> controllers;
  final List<WebsitePoster> posters;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 820;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 620 : 520),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF7ED),
            Color(0xFFFFE4E6),
            Color(0xFFE0F2FE),
            Color(0xFFE7F8EF),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 34,
            right: compact ? -70 : 44,
            child: const _PublicColorPatch(size: 190, color: Color(0x66FFB703)),
          ),
          Positioned(
            bottom: 36,
            left: compact ? -80 : 42,
            child: const _PublicColorPatch(size: 170, color: Color(0x5522C55E)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 52,
              compact ? 28 : 44,
              compact ? 18 : 52,
              compact ? 34 : 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: compact
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _EditablePublicHeroCopy(
                            controllers: controllers,
                            onInstall: onInstall,
                          ),
                          const SizedBox(height: 30),
                          _PublicHeroVisual(posters: posters),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            flex: 10,
                            child: _EditablePublicHeroCopy(
                              controllers: controllers,
                              onInstall: onInstall,
                            ),
                          ),
                          const SizedBox(width: 34),
                          Expanded(
                            flex: 9,
                            child: _PublicHeroVisual(posters: posters),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditablePublicHeroCopy extends StatelessWidget {
  const _EditablePublicHeroCopy({
    required this.controllers,
    required this.onInstall,
  });

  final Map<String, TextEditingController> controllers;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFB703), width: 1.4),
          ),
          child: SizedBox(
            width: compact ? 240 : 290,
            child: _EditorInlineText(
              controller: controllers['heroEyebrow'],
              fallback: _tr(context, 'Telugu poster app for every day'),
              style: const TextStyle(
                color: Color(0xFF7C2D12),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
              centered: compact,
              maxLines: 2,
            ),
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: _EditorInlineText(
            controller: controllers['heroTitle'],
            fallback: _tr(
              context,
              'Posters, wishes and festival creatives in one joyful app.',
            ),
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: compact ? 40 : 66,
              height: 1.02,
              fontWeight: FontWeight.w900,
            ),
            centered: compact,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _EditorInlineText(
            controller: controllers['heroSubtitle'],
            fallback: _tr(
              context,
              'Mana Poster helps people find ready-to-share designs for daily wishes, festivals, devotional posts, birthdays, events, news and business promotions.',
            ),
            style: TextStyle(
              color: const Color(0xFF334155),
              fontSize: compact ? 17 : 20,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
            centered: compact,
            maxLines: 5,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: 180,
              child: _EditorButtonText(
                controller: controllers['heroPrimaryCtaLabel'],
                fallback: _tr(context, 'Get the App'),
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                borderColor: const Color(0xFFE11D48),
                onTap: onInstall,
              ),
            ),
            SizedBox(
              width: 216,
              child: _EditorButtonText(
                controller: controllers['heroSecondaryCtaLabel'],
                fallback: _tr(context, 'Available on mobile'),
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFF111827),
                borderColor: const Color(0xFF111827),
                onTap: onInstall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _PublicMiniStat(label: 'Daily wishes'),
            _PublicMiniStat(label: 'Festival posters'),
            _PublicMiniStat(label: 'Quick sharing'),
          ],
        ),
      ],
    );
  }
}

class _EditablePublicCategoryRibbon extends StatelessWidget {
  const _EditablePublicCategoryRibbon({
    required this.categories,
    required this.selectedCategory,
    required this.controllers,
    required this.onSelected,
  });

  final List<_PublicPosterCategory> categories;
  final String? selectedCategory;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PublicEditableText(
                controller: controllers['customText.categoriesRibbonLabel'],
                value: _cmsTextValue(
                  config: null,
                  controllers: controllers,
                  key: 'customText.categoriesRibbonLabel',
                  fallback: 'Categories',
                ),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories
                    .map(
                      (_PublicPosterCategory category) => _PublicCategoryPill(
                        label: category.label,
                        badge: category.badge,
                        colors: category.colors,
                        selected: selectedCategory == category.id,
                        onTap: () => onSelected(category.id),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditablePosterUploadSection extends StatelessWidget {
  const _EditablePosterUploadSection({
    required this.controllers,
    required this.selectedCategoryId,
    required this.selectedPosters,
    required this.onUploadPoster,
    required this.onTogglePoster,
    required this.onReplacePoster,
    required this.onDeletePoster,
  });

  final Map<String, TextEditingController> controllers;
  final String? selectedCategoryId;
  final List<WebsitePoster> selectedPosters;
  final VoidCallback? onUploadPoster;
  final ValueChanged<WebsitePoster> onTogglePoster;
  final ValueChanged<WebsitePoster> onReplacePoster;
  final ValueChanged<WebsitePoster> onDeletePoster;

  @override
  Widget build(BuildContext context) {
    final HomeCategoryCatalogEntry? selectedCategory = selectedCategoryId == null
        ? null
        : (HomeCategoryCatalog.byRawCategory(selectedCategoryId!) ??
              HomeCategoryCatalog.uploadable.first);
    return Container(
      color: const Color(0xFFFFFBF3),
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (selectedCategory != null) ...<Widget>[
                Text(
                  '${selectedCategory.label} uploads',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload box stays ready for the next poster. Preview keeps the original image ratio.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _EditorSquareUploadBox(
                  label: selectedCategory.label,
                  onUpload: onUploadPoster,
                ),
                const SizedBox(height: 28),
              ],
              if (selectedPosters.isNotEmpty) ...<Widget>[
                const Text(
                  'Recent uploads',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: selectedPosters
                      .map(
                        (WebsitePoster poster) => _EditablePosterTile(
                          poster: poster,
                          onToggle: () => onTogglePoster(poster),
                          onReplace: () => onReplacePoster(poster),
                          onDelete: () => onDeletePoster(poster),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditablePublicDownloadSection extends StatelessWidget {
  const _EditablePublicDownloadSection({
    required this.controllers,
    required this.onInstall,
  });

  final Map<String, TextEditingController> controllers;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 54, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF111827), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _EditorInlineText(
                  controller: controllers['downloadEyebrow'],
                  fallback: 'GET STARTED',
                  style: const TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                _EditorInlineText(
                  controller: controllers['downloadTitle'],
                  fallback: 'Install Mana Poster and start sharing better creatives.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _EditorInlineText(
                    controller: controllers['downloadSubtitle'],
                    fallback:
                        'Keep the public page clear, colorful and useful while the app does the work for posters, wishes and quick sharing.',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 17,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 220,
                  child: _EditorButtonText(
                    controller: controllers['downloadButtonLabel'],
                    fallback: 'Install App',
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    borderColor: const Color(0xFFE11D48),
                    onTap: onInstall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditablePublicFooter extends StatelessWidget {
  const _EditablePublicFooter({
    required this.controllers,
    required this.config,
    required this.onPrivacy,
    required this.onTerms,
  });

  final Map<String, TextEditingController> controllers;
  final LandingPageConfig config;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(18, 54, 18, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 260,
                child: _EditorInlineText(
                  controller: controllers['customText.headerAppName'],
                  fallback: 'Mana Poster',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _EditorInlineText(
                  controller: controllers['footerTagline'],
                  fallback: config.footerTagline.isEmpty
                      ? 'Colorful Telugu poster creation for every daily, devotional, festival, and campaign need.'
                      : config.footerTagline,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 16,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: onPrivacy,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF475569)),
                    ),
                    child: const Text('Privacy'),
                  ),
                  OutlinedButton(
                    onPressed: onTerms,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF475569)),
                    ),
                    child: const Text('Terms'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorInlineText extends StatelessWidget {
  const _EditorInlineText({
    required this.controller,
    required this.fallback,
    required this.style,
    this.maxLines = 1,
    this.centered = false,
  });

  final TextEditingController? controller;
  final String fallback;
  final TextStyle style;
  final int maxLines;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle = style.copyWith(
      backgroundColor: Colors.transparent,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: TextField(
        controller: controller,
        minLines: maxLines > 1 ? 1 : 1,
        maxLines: maxLines,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: effectiveStyle,
        cursorColor: effectiveStyle.color ?? const Color(0xFF7C3AED),
        decoration: InputDecoration(
          hintText: fallback,
          hintStyle: effectiveStyle.copyWith(
            color: effectiveStyle.color?.withValues(alpha: 0.72),
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
          ),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}

class _EditorButtonText extends StatelessWidget {
  const _EditorButtonText({
    required this.controller,
    required this.fallback,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.onTap,
  });

  final TextEditingController? controller;
  final String fallback;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: _EditorInlineText(
            controller: controller,
            fallback: fallback,
            centered: true,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _EditorFilledActionButton extends StatelessWidget {
  const _EditorFilledActionButton({
    required this.controller,
    required this.fallback,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
    this.onTap,
  });

  final TextEditingController? controller;
  final String fallback;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconTheme(
                data: IconThemeData(color: foregroundColor, size: 18),
                child: icon,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PublicEditableText(
                  controller: controller,
                  value: fallback,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorUploadBadge extends StatelessWidget {
  const _EditorUploadBadge({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 6,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.add_photo_alternate_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorSquareUploadBox extends StatelessWidget {
  const _EditorSquareUploadBox({
    required this.label,
    required this.onUpload,
  });

  final String label;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: OutlinedButton(
        onPressed: onUpload,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6D28D9),
          side: const BorderSide(color: Color(0xFFDDD6FE), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.add_photo_alternate_rounded, size: 42),
            const SizedBox(height: 10),
            Text(
              '+ Upload $label poster\n1080 x 1080',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditablePosterTile extends StatelessWidget {
  const _EditablePosterTile({
    required this.poster,
    required this.onToggle,
    required this.onReplace,
    required this.onDelete,
  });

  final WebsitePoster poster;
  final VoidCallback onToggle;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  poster.imageUrl,
                  width: 244,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 160,
                    child: ColoredBox(
                      color: Color(0xFFE5E7EB),
                      child: Center(child: Icon(Icons.broken_image_rounded)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      poster.active ? 'Visible' : 'Hidden',
                      style: TextStyle(
                        color: poster.active
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: poster.active ? 'Hide' : 'Show',
                    onPressed: onToggle,
                    icon: Icon(
                      poster.active
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Replace image',
                    onPressed: onReplace,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicManualBanner extends StatelessWidget {
  const _PublicManualBanner({
    required this.config,
    required this.onInstall,
    required this.onDemo,
  });

  final LandingPageConfig config;
  final VoidCallback onInstall;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 760;
    final String imageUrl = config.heroImageUrl.trim();
    return SizedBox(
      width: double.infinity,
      height: compact
          ? _publicManualBannerCompactHeight
          : _publicManualBannerWideHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (imageUrl.isEmpty)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFFFB703),
                    Color(0xFFFF7A00),
                    Color(0xFFE11D48),
                  ],
                ),
              ),
            )
          else
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFFFFB703),
                      Color(0xFFFF7A00),
                      Color(0xFFE11D48),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: compact ? 16 : 42,
            right: compact ? 16 : 42,
            bottom: compact ? 18 : 34,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onInstall,
                  icon: const Icon(Icons.shop_rounded),
                  label: Text(_tr(context, 'Play Store')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 18 : 24,
                      vertical: compact ? 14 : 18,
                    ),
                    textStyle: TextStyle(
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onDemo,
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: Text(_tr(context, 'Watch Demo')),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Colors.white, width: 1.4),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 18 : 24,
                      vertical: compact ? 14 : 18,
                    ),
                    textStyle: TextStyle(
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicHeader extends StatelessWidget {
  const _PublicHeader({required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: compact ? 70 : 78,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 42),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFFFE0B2), width: 1),
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/branding/mana_poster_logo.png',
                  width: compact ? 42 : 48,
                  height: compact ? 42 : 48,
                  errorBuilder: (_, _, _) => Container(
                    width: compact ? 42 : 48,
                    height: compact ? 42 : 48,
                    color: const Color(0xFFFF5A5F),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Mana Poster',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              if (!compact) ...<Widget>[
                const _PublicNavText('App'),
                const _PublicNavText('Categories'),
                const _PublicNavText('Benefits'),
                const _PublicNavText('Download'),
                const SizedBox(width: 12),
              ],
              _PublicLanguageMenu(compact: compact),
              SizedBox(width: compact ? 8 : 12),
              FilledButton.icon(
                onPressed: onInstall,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  compact
                      ? _tr(context, 'Install')
                      : _tr(context, 'Install App'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 20,
                    vertical: compact ? 12 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicNavText extends StatelessWidget {
  const _PublicNavText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        _tr(context, label),
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PublicLanguageMenu extends StatelessWidget {
  const _PublicLanguageMenu({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLanguage current = context.currentLanguage;
    final AppStrings strings = context.strings;
    return PopupMenuButton<AppLanguage>(
      tooltip: _tr(context, 'Language'),
      initialValue: current,
      onSelected: context.languageController.setLanguage,
      itemBuilder: (BuildContext context) {
        return AppLanguage.values
            .map(
              (AppLanguage language) => PopupMenuItem<AppLanguage>(
                value: language,
                child: Row(
                  children: <Widget>[
                    if (language == current)
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Color(0xFFE11D48),
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(
                      strings.languageName(language),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      child: Container(
        height: compact ? 42 : 46,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD1A3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.language_rounded, color: Color(0xFFE11D48)),
            if (!compact) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                strings.languageName(current),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, color: Color(0xFF475569)),
          ],
        ),
      ),
    );
  }
}

class _PublicHeroBanner extends StatelessWidget {
  const _PublicHeroBanner({
    required this.config,
    required this.posters,
    required this.onInstall,
  });

  final LandingPageConfig config;
  final List<WebsitePoster> posters;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 820;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 620 : 520),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF7ED),
            Color(0xFFFFE4E6),
            Color(0xFFE0F2FE),
            Color(0xFFE7F8EF),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 34,
            right: compact ? -70 : 44,
            child: const _PublicColorPatch(size: 190, color: Color(0x66FFB703)),
          ),
          Positioned(
            bottom: 36,
            left: compact ? -80 : 42,
            child: const _PublicColorPatch(size: 170, color: Color(0x5522C55E)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 52,
              compact ? 28 : 44,
              compact ? 18 : 52,
              compact ? 34 : 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: compact
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _PublicHeroCopy(onInstall: onInstall),
                          const SizedBox(height: 30),
                          _PublicHeroVisual(posters: posters),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            flex: 10,
                            child: _PublicHeroCopy(onInstall: onInstall),
                          ),
                          const SizedBox(width: 34),
                          Expanded(
                            flex: 9,
                            child: _PublicHeroVisual(posters: posters),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicHeroCopy extends StatelessWidget {
  const _PublicHeroCopy({required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFB703), width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFF7A00),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _tr(context, 'Telugu poster app for every day'),
                style: const TextStyle(
                  color: Color(0xFF7C2D12),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          _tr(
            context,
            'Posters, wishes and festival creatives in one joyful app.',
          ),
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: compact ? 40 : 66,
            height: 1.02,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            _tr(
              context,
              'Mana Poster helps people find ready-to-share designs for daily wishes, festivals, devotional posts, birthdays, events, news and business promotions.',
            ),
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: const Color(0xFF334155),
              fontSize: compact ? 17 : 20,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.icon(
              onPressed: onInstall,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(_tr(context, 'Get the App')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onInstall,
              icon: const Icon(Icons.phone_android_rounded),
              label: Text(_tr(context, 'Available on mobile')),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Color(0xFF111827), width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _PublicMiniStat(label: 'Daily wishes'),
            _PublicMiniStat(label: 'Festival posters'),
            _PublicMiniStat(label: 'Quick sharing'),
          ],
        ),
      ],
    );
  }
}

class _PublicMiniStat extends StatelessWidget {
  const _PublicMiniStat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14EA580C),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        _tr(context, label),
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PublicHeroVisual extends StatelessWidget {
  const _PublicHeroVisual({required this.posters});

  final List<WebsitePoster> posters;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    final List<WebsitePoster> usable = posters
        .where((WebsitePoster poster) => poster.imageUrl.isNotEmpty)
        .take(5)
        .toList(growable: false);

    return SizedBox(
      height: compact ? 390 : 470,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: compact ? 14 : 22,
            top: compact ? 24 : 42,
            child: _PublicFloatingPoster(
              width: compact ? 122 : 150,
              height: compact ? 154 : 188,
              poster: usable.isNotEmpty ? usable[0] : null,
              title: 'Festival',
              colors: const <Color>[Color(0xFFFF7A00), Color(0xFFFFD166)],
            ),
          ),
          Positioned(
            right: compact ? 10 : 12,
            top: compact ? 18 : 30,
            child: _PublicFloatingPoster(
              width: compact ? 112 : 138,
              height: compact ? 142 : 174,
              poster: usable.length > 1 ? usable[1] : null,
              title: 'Birthday',
              colors: const <Color>[Color(0xFFE11D48), Color(0xFFFFB4C8)],
            ),
          ),
          Positioned(
            left: compact ? 26 : 44,
            bottom: compact ? 18 : 16,
            child: _PublicFloatingPoster(
              width: compact ? 112 : 140,
              height: compact ? 142 : 176,
              poster: usable.length > 2 ? usable[2] : null,
              title: 'Devotional',
              colors: const <Color>[Color(0xFF0EA5E9), Color(0xFFA7F3D0)],
            ),
          ),
          Positioned(
            right: compact ? 32 : 54,
            bottom: compact ? 4 : 18,
            child: _PublicFloatingPoster(
              width: compact ? 104 : 132,
              height: compact ? 132 : 166,
              poster: usable.length > 3 ? usable[3] : null,
              title: 'Business',
              colors: const <Color>[Color(0xFF16A34A), Color(0xFFFFF3B0)],
            ),
          ),
          const _PublicPhoneMock(),
        ],
      ),
    );
  }
}

class _PublicPhoneMock extends StatelessWidget {
  const _PublicPhoneMock();

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return Container(
      width: compact ? 190 : 230,
      height: compact ? 332 : 398,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33111827),
            blurRadius: 34,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          color: const Color(0xFFFFFBF3),
          child: Column(
            children: <Widget>[
              Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFFFF4D6D), Color(0xFFFFB703)],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/branding/mana_poster_logo.png',
                        width: 34,
                        height: 34,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mana Poster',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: <Widget>[
                      const _PublicPhoneHeroCard(),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: const <Widget>[
                            _PublicPhoneTile('AM'),
                            _PublicPhoneTile('BDAY'),
                            _PublicPhoneTile('BHAKTI'),
                            _PublicPhoneTile('NEW'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicPhoneHeroCard extends StatelessWidget {
  const _PublicPhoneHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _tr(context, 'Today special'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            _tr(context, 'Ready designs for sharing'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xEEFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPhoneTile extends StatelessWidget {
  const _PublicPhoneTile(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE11D48),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PublicFloatingPoster extends StatelessWidget {
  const _PublicFloatingPoster({
    required this.width,
    required this.height,
    required this.title,
    required this.colors,
    this.poster,
  });

  final double width;
  final double height;
  final String title;
  final List<Color> colors;
  final WebsitePoster? poster;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: title.length.isEven ? -0.08 : 0.08,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x24111827),
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: poster == null
            ? _PublicPosterFallback(title: title, colors: colors)
            : Image.network(
                poster!.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _PublicPosterFallback(title: title, colors: colors),
              ),
      ),
    );
  }
}

class _PublicColorPatch extends StatelessWidget {
  const _PublicColorPatch({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PublicCategoryRibbon extends StatelessWidget {
  const _PublicCategoryRibbon({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<_PublicPosterCategory> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _tr(context, 'Categories'),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories
                    .map(
                      (_PublicPosterCategory category) => _PublicCategoryPill(
                        label: category.label,
                        badge: category.badge,
                        colors: category.colors,
                        selected: selectedCategory == category.id,
                        onTap: () => onSelected(category.id),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicCategoryPill extends StatelessWidget {
  const _PublicCategoryPill({
    required this.label,
    required this.badge,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String badge;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6D28D9) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF6D28D9) : const Color(0xFF111827),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0F111827),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _tr(context, label),
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicProductHighlightsSection extends StatelessWidget {
  const _PublicProductHighlightsSection();

  @override
  Widget build(BuildContext context) {
    final List<_PublicHighlightItem> items = <_PublicHighlightItem>[
      _PublicHighlightItem(
        icon: Icons.auto_awesome_rounded,
        title: _tr(context, 'Fast Design Creation'),
        desc: _tr(
          context,
          'Create professional Telugu posters in seconds with ready templates.',
        ),
      ),
      _PublicHighlightItem(
        icon: Icons.photo_library_rounded,
        title: _tr(context, 'Unlimited Poster Library'),
        desc: _tr(
          context,
          'Upload and manage category-wise posters with smooth browsing.',
        ),
      ),
      _PublicHighlightItem(
        icon: Icons.language_rounded,
        title: _tr(context, 'Multi Language Ready'),
        desc: _tr(
          context,
          'Use multiple Indian languages and publish localized content quickly.',
        ),
      ),
      _PublicHighlightItem(
        icon: Icons.rocket_launch_rounded,
        title: _tr(context, 'Instant Publishing'),
        desc: _tr(
          context,
          'Design once and share across WhatsApp, status and social channels.',
        ),
      ),
    ];

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(18, 36, 18, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _tr(context, 'Why Mana Poster App'),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _tr(
                  context,
                  'Built for creators, managers and teams who need speed with quality.',
                ),
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;
                  final int columns = width >= 1040
                      ? 4
                      : (width >= 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: columns == 1 ? 2.9 : 1.5,
                    ),
                    itemBuilder: (_, int index) {
                      final _PublicHighlightItem item = items[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              item.icon,
                              size: 22,
                              color: const Color(0xFF4F46E5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.desc,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicHowItWorksLiteSection extends StatelessWidget {
  const _PublicHowItWorksLiteSection();

  @override
  Widget build(BuildContext context) {
    final List<String> steps = <String>[
      _tr(context, 'Select category and choose a ready template.'),
      _tr(context, 'Edit text, image and branding in a few taps.'),
      _tr(context, 'Export and share instantly to your audience.'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _tr(context, 'How It Works'),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool mobile = constraints.maxWidth < 760;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: List<Widget>.generate(steps.length, (int index) {
                      return SizedBox(
                        width: mobile
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 28) / 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  steps[index],
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 14,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicHighlightItem {
  const _PublicHighlightItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;
}

class _PublicAudienceSection extends StatelessWidget {
  const _PublicAudienceSection({required this.config, this.controllers});

  final LandingPageConfig config;
  final Map<String, TextEditingController>? controllers;

  @override
  Widget build(BuildContext context) {
    return _PublicSectionShell(
      background: const Color(0xFFEFFCF4),
      child: Column(
        children: <Widget>[
          _PublicSectionTitle(
            eyebrow: 'MADE FOR REAL USE',
            title:
                'For greetings, local updates, promotions and personal wishes.',
            subtitle:
                'Mana Poster is simple enough for everyday users and useful enough for people who post regularly for community, business and events.',
            config: config,
            controllers: controllers,
            eyebrowKey: 'audienceEyebrow',
            titleKey: 'audienceTitle',
            subtitleKey: 'audienceSubtitle',
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 780;
              return GridView.count(
                crossAxisCount: compact ? 1 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: compact ? 3.4 : 1.05,
                children: <Widget>[
                  _PublicAudienceTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.wb_sunny_rounded,
                    title: 'Daily wishes',
                    body: 'Morning, night and positive thought posters.',
                    color: Color(0xFFFFB703),
                    titleKey: 'audienceCard1Title',
                    bodyKey: 'audienceCard1Body',
                  ),
                  _PublicAudienceTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.temple_hindu_rounded,
                    title: 'Festivals',
                    body: 'Seasonal and devotional poster collections.',
                    color: Color(0xFFF97316),
                    titleKey: 'audienceCard2Title',
                    bodyKey: 'audienceCard2Body',
                  ),
                  _PublicAudienceTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.campaign_rounded,
                    title: 'Promotions',
                    body: 'Business, event and announcement creatives.',
                    color: Color(0xFF0EA5E9),
                    titleKey: 'audienceCard3Title',
                    bodyKey: 'audienceCard3Body',
                  ),
                  _PublicAudienceTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.favorite_rounded,
                    title: 'Personal moments',
                    body: 'Birthday, anniversary and special day wishes.',
                    color: Color(0xFFE11D48),
                    titleKey: 'audienceCard4Title',
                    bodyKey: 'audienceCard4Body',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicAudienceTile extends StatelessWidget {
  const _PublicAudienceTile({
    required this.config,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.controllers,
    this.titleKey,
    this.bodyKey,
  });

  final LandingPageConfig config;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Map<String, TextEditingController>? controllers;
  final String? titleKey;
  final String? bodyKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6F5E1)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PublicEditableText(
                  controller: titleKey == null ? null : controllers?[titleKey!],
                  value: _cmsTextValue(
                    config: config,
                    controllers: controllers,
                    key: titleKey ?? '',
                    fallback: title,
                  ),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                _PublicEditableText(
                  controller: bodyKey == null ? null : controllers?[bodyKey!],
                  value: _cmsTextValue(
                    config: config,
                    controllers: controllers,
                    key: bodyKey ?? '',
                    fallback: body,
                  ),
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPromiseSection extends StatelessWidget {
  const _PublicPromiseSection({required this.config, this.controllers});

  final LandingPageConfig config;
  final Map<String, TextEditingController>? controllers;

  @override
  Widget build(BuildContext context) {
    return _PublicSectionShell(
      background: const Color(0xFFFFFBF3),
      child: Column(
        children: <Widget>[
          _PublicSectionTitle(
            eyebrow: 'CLEAR APP VALUE',
            title: 'Everything people need for daily social posting.',
            subtitle:
                'The app keeps poster discovery simple: pick the occasion, choose a ready design, add profile details where needed and share it quickly.',
            config: config,
            controllers: controllers,
            eyebrowKey: 'promiseEyebrow',
            titleKey: 'promiseTitle',
            subtitleKey: 'promiseSubtitle',
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 840;
              return GridView.count(
                crossAxisCount: compact ? 1 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: compact ? 1.55 : 1.25,
                children: <Widget>[
                  _PublicBenefitCard(
                    config: config,
                    controllers: controllers,
                    icon: Icons.celebration_rounded,
                    title: 'Occasion-ready',
                    body:
                        'Good morning, birthdays, devotional, news, events and new collections are easy to browse.',
                    color: Color(0xFFFF7A00),
                    titleKey: 'promiseCard1Title',
                    bodyKey: 'promiseCard1Body',
                  ),
                  _PublicBenefitCard(
                    config: config,
                    controllers: controllers,
                    icon: Icons.badge_rounded,
                    title: 'Profile-friendly',
                    body:
                        'Names, contact details and branding can be used wherever the app supports personalized posters.',
                    color: Color(0xFF16A34A),
                    titleKey: 'promiseCard2Title',
                    bodyKey: 'promiseCard2Body',
                  ),
                  _PublicBenefitCard(
                    config: config,
                    controllers: controllers,
                    icon: Icons.ios_share_rounded,
                    title: 'Share fast',
                    body:
                        'Download and share posters on social platforms without making the user feel lost.',
                    color: Color(0xFF0EA5E9),
                    titleKey: 'promiseCard3Title',
                    bodyKey: 'promiseCard3Body',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicBenefitCard extends StatelessWidget {
  const _PublicBenefitCard({
    required this.config,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.controllers,
    this.titleKey,
    this.bodyKey,
  });

  final LandingPageConfig config;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Map<String, TextEditingController>? controllers;
  final String? titleKey;
  final String? bodyKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 16),
          _PublicEditableText(
            controller: titleKey == null ? null : controllers?[titleKey!],
            value: _cmsTextValue(
              config: config,
              controllers: controllers,
              key: titleKey ?? '',
              fallback: title,
            ),
            maxLines: 2,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _PublicEditableText(
            controller: bodyKey == null ? null : controllers?[bodyKey!],
            value: _cmsTextValue(
              config: config,
              controllers: controllers,
              key: bodyKey ?? '',
              fallback: body,
            ),
            maxLines: 4,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPosterShowcase extends StatelessWidget {
  const _PublicPosterShowcase({
    required this.posters,
    required this.selectedCategory,
  });

  final List<WebsitePoster> posters;
  final String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final List<_PublicPosterCategory> categories = _allPublicCategories(
      posters,
    );
    final _PublicPosterCategory category = _publicCategoryById(
      selectedCategory,
      categories,
    );
    final List<WebsitePoster> usable =
        posters
            .where(
              (WebsitePoster poster) =>
                  poster.imageUrl.isNotEmpty &&
                  _publicPosterCategoryId(poster.category) == selectedCategory,
            )
            .toList(growable: false)
          ..sort(
            (WebsitePoster a, WebsitePoster b) =>
                a.sortOrder.compareTo(b.sortOrder),
          );
    final List<WebsitePoster> visible = usable.take(24).toList(growable: false);
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _tr(context, category.label),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _tr(
                  context,
                  'Posters uploaded from admin appear here in horizontal scroll.',
                ),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              if (visible.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Text(
                    _tr(context, 'No posters uploaded in this category yet.'),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: MediaQuery.sizeOf(context).width < 760 ? 260 : 360,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (BuildContext context, int index) {
                      return _PublicGalleryPoster(
                        imageUrl: visible[index].imageUrl,
                        label: category.label,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicInsideAppSection extends StatelessWidget {
  const _PublicInsideAppSection({required this.config, this.controllers});

  final LandingPageConfig config;
  final Map<String, TextEditingController>? controllers;

  @override
  Widget build(BuildContext context) {
    return _PublicSectionShell(
      background: const Color(0xFFFFFBF3),
      child: Column(
        children: <Widget>[
          _PublicSectionTitle(
            eyebrow: 'INSIDE THE APP',
            title: 'Everything is arranged for fast poster discovery.',
            subtitle:
                'The app experience is focused on finding the right poster quickly, keeping useful details ready, and sharing without confusion.',
            config: config,
            controllers: controllers,
            eyebrowKey: 'insideEyebrow',
            titleKey: 'insideTitle',
            subtitleKey: 'insideSubtitle',
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int count = constraints.maxWidth < 680
                  ? 1
                  : constraints.maxWidth < 1020
                  ? 2
                  : 3;
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: count == 1 ? 3.2 : 1.55,
                children: <Widget>[
                  _PublicInsideTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.person_pin_rounded,
                    title: 'Saved profile details',
                    body:
                        'Keep name, photo, phone and identity details ready for poster use.',
                    color: Color(0xFFE11D48),
                    titleKey: 'insideCard1Title',
                    bodyKey: 'insideCard1Body',
                  ),
                  _PublicInsideTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.category_rounded,
                    title: 'Easy category browsing',
                    body:
                        'Daily, festival, devotional, birthday and special collections stay organized.',
                    color: Color(0xFFFF7A00),
                    titleKey: 'insideCard2Title',
                    bodyKey: 'insideCard2Body',
                  ),
                  _PublicInsideTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.workspace_premium_rounded,
                    title: 'Premium collections',
                    body:
                        'Useful poster sets and polished designs can be surfaced for regular users.',
                    color: Color(0xFF7C3AED),
                    titleKey: 'insideCard3Title',
                    bodyKey: 'insideCard3Body',
                  ),
                  _PublicInsideTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.translate_rounded,
                    title: 'Telugu-first feel',
                    body:
                        'The app is shaped around Telugu users, local occasions and daily sharing habits.',
                    color: Color(0xFF0EA5E9),
                    titleKey: 'insideCard4Title',
                    bodyKey: 'insideCard4Body',
                  ),
                  _PublicInsideTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.notifications_active_rounded,
                    title: 'Timely updates',
                    body:
                        'Fresh posters and important occasion collections are easy to notice.',
                    color: Color(0xFF16A34A),
                    titleKey: 'insideCard5Title',
                    bodyKey: 'insideCard5Body',
                  ),
                  _PublicInsideTile(
                    config: config,
                    controllers: controllers,
                    icon: Icons.download_done_rounded,
                    title: 'Clean downloads',
                    body:
                        'Save useful posters and share them on WhatsApp and social platforms.',
                    color: Color(0xFF0891B2),
                    titleKey: 'insideCard6Title',
                    bodyKey: 'insideCard6Body',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicInsideTile extends StatelessWidget {
  const _PublicInsideTile({
    required this.config,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.controllers,
    this.titleKey,
    this.bodyKey,
  });

  final LandingPageConfig config;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Map<String, TextEditingController>? controllers;
  final String? titleKey;
  final String? bodyKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PublicEditableText(
                  controller: titleKey == null ? null : controllers?[titleKey!],
                  value: _cmsTextValue(
                    config: config,
                    controllers: controllers,
                    key: titleKey ?? '',
                    fallback: title,
                  ),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                _PublicEditableText(
                  controller: bodyKey == null ? null : controllers?[bodyKey!],
                  value: _cmsTextValue(
                    config: config,
                    controllers: controllers,
                    key: bodyKey ?? '',
                    fallback: body,
                  ),
                  maxLines: 3,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicGalleryPoster extends StatelessWidget {
  const _PublicGalleryPoster({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double posterHeight = MediaQuery.sizeOf(context).width < 760
        ? 250
        : 350;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        height: posterHeight,
        fit: BoxFit.contain,
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? progress) {
              if (progress == null) {
                return child;
              }
              return SizedBox(
                width: posterHeight,
                height: posterHeight,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
        errorBuilder: (_, _, _) => SizedBox(
          width: posterHeight,
          height: posterHeight,
          child: _PublicPosterFallback(
            title: label,
            colors: const <Color>[Color(0xFFFFB347), Color(0xFFE11D48)],
          ),
        ),
      ),
    );
  }
}

class _PublicPosterCategory {
  const _PublicPosterCategory({
    required this.id,
    required this.label,
    required this.badge,
    required this.colors,
  });

  final String id;
  final String label;
  final String badge;
  final List<Color> colors;
}

List<_PublicPosterCategory> _allPublicCategories(List<WebsitePoster> posters) {
  final List<_PublicPosterCategory> catalogCategories = HomeCategoryCatalog
      .uploadable
      .map(
        (HomeCategoryCatalogEntry entry) => _PublicPosterCategory(
          id: entry.id,
          label: entry.label,
          badge: entry.badge,
          colors: entry.gradient,
        ),
      )
      .toList(growable: false);

  final Set<String> knownIds = catalogCategories
      .map((_PublicPosterCategory item) => item.id)
      .toSet();
  final List<_PublicPosterCategory> extraCategories = <_PublicPosterCategory>[];

  for (final WebsitePoster poster in posters) {
    final String raw = poster.category.trim();
    if (raw.isEmpty) {
      continue;
    }
    final String id = _publicPosterCategoryId(raw);
    if (id.isEmpty || knownIds.contains(id)) {
      continue;
    }
    knownIds.add(id);
    final String label = HomeCategoryCatalog.canonicalLabel(raw);
    extraCategories.add(
      _PublicPosterCategory(
        id: id,
        label: label,
        badge: _categoryBadgeFromLabel(label),
        colors: _categoryColorsFromId(id),
      ),
    );
  }

  return <_PublicPosterCategory>[...catalogCategories, ...extraCategories];
}

_PublicPosterCategory _publicCategoryById(
  String? id,
  List<_PublicPosterCategory> categories,
) {
  if (categories.isEmpty) {
    return const _PublicPosterCategory(
      id: 'posters',
      label: 'Posters',
      badge: 'POST',
      colors: <Color>[Color(0xFF111827), Color(0xFF6B7280)],
    );
  }
  return categories.firstWhere(
    (_PublicPosterCategory item) => item.id == id,
    orElse: () => categories.first,
  );
}

String _publicPosterCategoryId(String raw) {
  final HomeCategoryCatalogEntry? catalog = HomeCategoryCatalog.byRawCategory(
    raw,
  );
  if (catalog != null) {
    return catalog.id;
  }
  final String normalized = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  if (normalized.isNotEmpty) {
    return normalized;
  }
  return raw.trim().isEmpty ? 'posters' : raw.trim();
}

String _categoryBadgeFromLabel(String label) {
  final String compact = label.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (compact.isEmpty) {
    return 'NEW';
  }
  return compact.toUpperCase().substring(0, compact.length.clamp(1, 4));
}

List<Color> _categoryColorsFromId(String id) {
  final int hash = id.codeUnits.fold(0, (int sum, int ch) => sum + ch);
  final List<List<Color>> palette = <List<Color>>[
    <Color>[const Color(0xFF7C3AED), const Color(0xFFC4B5FD)],
    <Color>[const Color(0xFF0EA5E9), const Color(0xFFBAE6FD)],
    <Color>[const Color(0xFFF97316), const Color(0xFFFCD34D)],
    <Color>[const Color(0xFF16A34A), const Color(0xFFBBF7D0)],
    <Color>[const Color(0xFFE11D48), const Color(0xFFFDA4AF)],
    <Color>[const Color(0xFF1D4ED8), const Color(0xFF93C5FD)],
  ];
  return palette[hash % palette.length];
}

class _PublicPosterFallback extends StatelessWidget {
  const _PublicPosterFallback({required this.title, required this.colors});

  final String title;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'MANA',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _tr(context, title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicDailyFlowSection extends StatelessWidget {
  const _PublicDailyFlowSection({required this.config, this.controllers});

  final LandingPageConfig config;
  final Map<String, TextEditingController>? controllers;

  @override
  Widget build(BuildContext context) {
    return _PublicSectionShell(
      background: const Color(0xFFFFF7ED),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 860;
          final Widget copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PublicSectionTitle(
                eyebrow: 'DAILY FLOW',
                title: 'A poster routine that feels simple every morning.',
                subtitle:
                    'People can open the app, scan today-friendly collections, pick a useful poster, and share it in a few taps.',
                config: config,
                controllers: controllers,
                eyebrowKey: 'dailyFlowEyebrow',
                titleKey: 'dailyFlowTitle',
                subtitleKey: 'dailyFlowSubtitle',
              ),
            ],
          );
          final Widget timeline = Column(
            children: <Widget>[
              _PublicTimelineItem(
                config: config,
                controllers: controllers,
                icon: Icons.today_rounded,
                title: 'Open today collections',
                body: 'Fresh and relevant categories are easy to scan.',
                color: Color(0xFFFF7A00),
                titleKey: 'dailyFlowStep1Title',
                bodyKey: 'dailyFlowStep1Body',
              ),
              _PublicTimelineItem(
                config: config,
                controllers: controllers,
                icon: Icons.touch_app_rounded,
                title: 'Select the right design',
                body: 'Choose the poster that matches your message.',
                color: Color(0xFFE11D48),
                titleKey: 'dailyFlowStep2Title',
                bodyKey: 'dailyFlowStep2Body',
              ),
              _PublicTimelineItem(
                config: config,
                controllers: controllers,
                icon: Icons.send_rounded,
                title: 'Save and share',
                body: 'Use it for WhatsApp, status, groups or social pages.',
                color: Color(0xFF16A34A),
                titleKey: 'dailyFlowStep3Title',
                bodyKey: 'dailyFlowStep3Body',
              ),
            ],
          );
          if (compact) {
            return Column(
              children: <Widget>[copy, const SizedBox(height: 26), timeline],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(flex: 9, child: copy),
              const SizedBox(width: 34),
              Expanded(flex: 8, child: timeline),
            ],
          );
        },
      ),
    );
  }
}

class _PublicTimelineItem extends StatelessWidget {
  const _PublicTimelineItem({
    required this.config,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.controllers,
    this.titleKey,
    this.bodyKey,
  });

  final LandingPageConfig config;
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Map<String, TextEditingController>? controllers;
  final String? titleKey;
  final String? bodyKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PublicEditableText(
                  controller: titleKey == null ? null : controllers?[titleKey!],
                  value: _cmsTextValue(
                    config: config,
                    controllers: controllers,
                    key: titleKey ?? '',
                    fallback: title,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                _PublicEditableText(
                  controller: bodyKey == null ? null : controllers?[bodyKey!],
                  value: _cmsTextValue(
                    config: config,
                    controllers: controllers,
                    key: bodyKey ?? '',
                    fallback: body,
                  ),
                  maxLines: 3,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicUseCasesSection extends StatelessWidget {
  const _PublicUseCasesSection({required this.config, this.controllers});

  final LandingPageConfig config;
  final Map<String, TextEditingController>? controllers;

  @override
  Widget build(BuildContext context) {
    return _PublicSectionShell(
      background: const Color(0xFFEFFCF4),
      child: Column(
        children: <Widget>[
          _PublicSectionTitle(
            eyebrow: 'HOW PEOPLE USE IT',
            title:
                'Open the app, find the right design, share with confidence.',
            subtitle:
                'Mana Poster is built for busy users who want clear categories, familiar Telugu-first content and quick sharing.',
            config: config,
            controllers: controllers,
            eyebrowKey: 'useCasesEyebrow',
            titleKey: 'useCasesTitle',
            subtitleKey: 'useCasesSubtitle',
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 760;
              final List<Widget> steps = <Widget>[
                _PublicStepTile(
                  config: config,
                  controllers: controllers,
                  number: '1',
                  title: 'Choose occasion',
                  body:
                      'Browse the category that matches the day, festival, event or message.',
                  color: Color(0xFFFF7A00),
                  titleKey: 'useCasesStep1Title',
                  bodyKey: 'useCasesStep1Body',
                ),
                _PublicStepTile(
                  config: config,
                  controllers: controllers,
                  number: '2',
                  title: 'Pick a poster',
                  body:
                      'Select a ready design that looks right for your audience.',
                  color: Color(0xFFE11D48),
                  titleKey: 'useCasesStep2Title',
                  bodyKey: 'useCasesStep2Body',
                ),
                _PublicStepTile(
                  config: config,
                  controllers: controllers,
                  number: '3',
                  title: 'Download or share',
                  body:
                      'Save the poster or share it directly wherever you need it.',
                  color: Color(0xFF0EA5E9),
                  titleKey: 'useCasesStep3Title',
                  bodyKey: 'useCasesStep3Body',
                ),
              ];
              if (compact) {
                return Column(
                  children: <Widget>[
                    steps[0],
                    const SizedBox(height: 14),
                    steps[1],
                    const SizedBox(height: 14),
                    steps[2],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: steps[0]),
                  const SizedBox(width: 14),
                  Expanded(child: steps[1]),
                  const SizedBox(width: 14),
                  Expanded(child: steps[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicStepTile extends StatelessWidget {
  const _PublicStepTile({
    required this.config,
    required this.number,
    required this.title,
    required this.body,
    required this.color,
    this.controllers,
    this.titleKey,
    this.bodyKey,
  });

  final LandingPageConfig config;
  final String number;
  final String title;
  final String body;
  final Color color;
  final Map<String, TextEditingController>? controllers;
  final String? titleKey;
  final String? bodyKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6F5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PublicEditableText(
            controller: titleKey == null ? null : controllers?[titleKey!],
            value: _cmsTextValue(
              config: config,
              controllers: controllers,
              key: titleKey ?? '',
              fallback: title,
            ),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _PublicEditableText(
            controller: bodyKey == null ? null : controllers?[bodyKey!],
            value: _cmsTextValue(
              config: config,
              controllers: controllers,
              key: bodyKey ?? '',
              fallback: body,
            ),
            maxLines: 4,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicTrustSection extends StatelessWidget {
  const _PublicTrustSection({required this.config, this.controllers});

  final LandingPageConfig config;
  final Map<String, TextEditingController>? controllers;

  @override
  Widget build(BuildContext context) {
    return _PublicSectionShell(
      background: const Color(0xFFFFFBF3),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 820;
          final Widget copy = _PublicSectionTitle(
            eyebrow: 'WHY IT FEELS EASY',
            title: 'Clear categories, familiar content and quick actions.',
            subtitle:
                'The landing page now explains the app without confusing backend language. Visitors immediately understand what the app is for.',
            config: config,
            controllers: controllers,
            eyebrowKey: 'trustEyebrow',
            titleKey: 'trustTitle',
            subtitleKey: 'trustSubtitle',
          );
          final Widget pills = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _PublicTrustPill(
                config: config,
                controllers: controllers,
                icon: Icons.language_rounded,
                label: 'Telugu audience',
                labelKey: 'trustPill1',
              ),
              _PublicTrustPill(
                config: config,
                controllers: controllers,
                icon: Icons.grid_view_rounded,
                label: 'Clear categories',
                labelKey: 'trustPill2',
              ),
              _PublicTrustPill(
                config: config,
                controllers: controllers,
                icon: Icons.collections_rounded,
                label: 'Poster library',
                labelKey: 'trustPill3',
              ),
              _PublicTrustPill(
                config: config,
                controllers: controllers,
                icon: Icons.phone_android_rounded,
                label: 'Mobile friendly',
                labelKey: 'trustPill4',
              ),
              _PublicTrustPill(
                config: config,
                controllers: controllers,
                icon: Icons.share_rounded,
                label: 'Fast sharing',
                labelKey: 'trustPill5',
              ),
            ],
          );
          if (compact) {
            return Column(
              children: <Widget>[copy, const SizedBox(height: 24), pills],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(flex: 9, child: copy),
              const SizedBox(width: 28),
              Expanded(flex: 8, child: pills),
            ],
          );
        },
      ),
    );
  }
}

class _PublicTrustPill extends StatelessWidget {
  const _PublicTrustPill({
    required this.config,
    required this.icon,
    required this.label,
    this.controllers,
    this.labelKey,
  });

  final LandingPageConfig config;
  final IconData icon;
  final String label;
  final Map<String, TextEditingController>? controllers;
  final String? labelKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE0B2)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: const Color(0xFFE11D48), size: 19),
          const SizedBox(width: 8),
          _PublicEditableText(
            controller: labelKey == null ? null : controllers?[labelKey!],
            value: _cmsTextValue(
              config: config,
              controllers: controllers,
              key: labelKey ?? '',
              fallback: label,
            ),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicFaqSection extends StatelessWidget {
  const _PublicFaqSection({required this.config, this.controllers});

  final LandingPageConfig config;
  final Map<String, TextEditingController>? controllers;

  @override
  Widget build(BuildContext context) {
    return _PublicSectionShell(
      background: Colors.white,
      child: Column(
        children: <Widget>[
          _PublicSectionTitle(
            eyebrow: 'COMMON QUESTIONS',
            title: 'Visitors should understand the app before installing.',
            subtitle:
                'These quick answers make the landing page feel complete and reduce confusion for new users.',
            config: config,
            controllers: controllers,
            eyebrowKey: 'faqEyebrow',
            titleKey: 'faqTitle',
            subtitleKey: 'faqSubtitle',
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int count = constraints.maxWidth < 820 ? 1 : 2;
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: count == 1 ? 3.1 : 2.35,
                children: <Widget>[
                  _PublicFaqTile(
                    config: config,
                    controllers: controllers,
                    question: 'What is Mana Poster?',
                    answer:
                        'It is a Telugu poster app for daily wishes, festivals, devotional posts, birthdays, events and promotions.',
                    questionKey: 'faq1Question',
                    answerKey: 'faq1Answer',
                  ),
                  _PublicFaqTile(
                    config: config,
                    controllers: controllers,
                    question: 'Can users share posters quickly?',
                    answer:
                        'Yes. The app is designed for fast save and share flows for mobile-first users.',
                    questionKey: 'faq2Question',
                    answerKey: 'faq2Answer',
                  ),
                  _PublicFaqTile(
                    config: config,
                    controllers: controllers,
                    question: 'Does it support personal details?',
                    answer:
                        'Yes. Saved profile details help users keep identity information ready where the app supports it.',
                    questionKey: 'faq3Question',
                    answerKey: 'faq3Answer',
                  ),
                  _PublicFaqTile(
                    config: config,
                    controllers: controllers,
                    question: 'Who is it useful for?',
                    answer:
                        'Individuals, local businesses, event organizers, community pages and regular social media users.',
                    questionKey: 'faq4Question',
                    answerKey: 'faq4Answer',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicFaqTile extends StatelessWidget {
  const _PublicFaqTile({
    required this.config,
    required this.question,
    required this.answer,
    this.controllers,
    this.questionKey,
    this.answerKey,
  });

  final LandingPageConfig config;
  final String question;
  final String answer;
  final Map<String, TextEditingController>? controllers;
  final String? questionKey;
  final String? answerKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.help_rounded,
                color: Color(0xFFE11D48),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PublicEditableText(
                  controller: questionKey == null ? null : controllers?[questionKey!],
                  value: _cmsTextValue(
                    config: config,
                    controllers: controllers,
                    key: questionKey ?? '',
                    fallback: question,
                  ),
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PublicEditableText(
            controller: answerKey == null ? null : controllers?[answerKey!],
            value: _cmsTextValue(
              config: config,
              controllers: controllers,
              key: answerKey ?? '',
              fallback: answer,
            ),
            maxLines: 4,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicDownloadSection extends StatelessWidget {
  const _PublicDownloadSection({required this.config, required this.onInstall});

  final LandingPageConfig config;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 760;
              final Widget copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _tr(context, 'Ready to make daily posting easier?'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _tr(
                      context,
                      'Install Mana Poster and keep useful poster collections close to your phone.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 17,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
              final Widget button = FilledButton.icon(
                onPressed: onInstall,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  config.downloadButtonLabel.isEmpty
                      ? _tr(context, 'Install Mana Poster')
                      : config.downloadButtonLabel,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB703),
                  foregroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 18,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[copy, const SizedBox(height: 24), button],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: copy),
                  const SizedBox(width: 28),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PublicFooter extends StatelessWidget {
  const _PublicFooter({
    required this.config,
    required this.onPrivacy,
    required this.onTerms,
  });

  final LandingPageConfig config;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 720;
    return Container(
      width: double.infinity,
      color: const Color(0xFF111827),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 42,
        vertical: compact ? 32 : 42,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Wrap(
                spacing: 18,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/branding/mana_poster_logo.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Mana Poster',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    config.footerTagline.isEmpty
                        ? _tr(context, 'Telugu poster app for daily sharing.')
                        : config.footerTagline,
                    style: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      TextButton(
                        onPressed: onPrivacy,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_tr(context, 'Privacy')),
                      ),
                      TextButton(
                        onPressed: onTerms,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_tr(context, 'Terms')),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 18),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                ),
                child: Text(
                  _tr(context, '(c) 2026 Mana Poster. All rights reserved.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicSectionShell extends StatelessWidget {
  const _PublicSectionShell({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 58),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _PublicSectionTitle extends StatelessWidget {
  const _PublicSectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.config,
    this.controllers,
    this.eyebrowKey,
    this.titleKey,
    this.subtitleKey,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final LandingPageConfig? config;
  final Map<String, TextEditingController>? controllers;
  final String? eyebrowKey;
  final String? titleKey;
  final String? subtitleKey;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    final String eyebrowText = eyebrowKey == null
        ? eyebrow
        : _cmsTextValue(
            config: config,
            controllers: controllers,
            key: eyebrowKey!,
            fallback: eyebrow,
          );
    final String titleText = titleKey == null
        ? title
        : _cmsTextValue(
            config: config,
            controllers: controllers,
            key: titleKey!,
            fallback: title,
          );
    final String subtitleText = subtitleKey == null
        ? subtitle
        : _cmsTextValue(
            config: config,
            controllers: controllers,
            key: subtitleKey!,
            fallback: subtitle,
          );
    return Column(
      children: <Widget>[
        _PublicEditableText(
          controller: eyebrowKey == null ? null : controllers?[eyebrowKey!],
          value: eyebrowText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE11D48),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: _PublicEditableText(
            controller: titleKey == null ? null : controllers?[titleKey!],
            value: titleText,
            textAlign: TextAlign.center,
            maxLines: 4,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: compact ? 31 : 44,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _PublicEditableText(
            controller: subtitleKey == null ? null : controllers?[subtitleKey!],
            value: subtitleText,
            textAlign: TextAlign.center,
            maxLines: 5,
            style: TextStyle(
              color: const Color(0xFF475569),
              fontSize: compact ? 16 : 18,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PublicEditableText extends StatelessWidget {
  const _PublicEditableText({
    required this.value,
    required this.style,
    this.controller,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
  });

  final String value;
  final TextStyle style;
  final TextEditingController? controller;
  final TextAlign textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return Text(
        _tr(context, value),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
        style: style,
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: maxLines,
        textAlign: textAlign,
        cursorColor: style.color ?? const Color(0xFF7C3AED),
        style: style,
        decoration: InputDecoration(
          hintText: _tr(context, value),
          hintStyle: style,
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
        ),
      ),
    );
  }
}

String _tr(BuildContext context, String english) {
  final AppLanguage language = context.currentLanguage;
  if (language == AppLanguage.english) {
    return english;
  }
  final Map<String, String>? languageMap = _publicLandingTranslations[language];
  return languageMap?[english] ??
      context.strings.localized(telugu: english, english: english);
}

const Map<AppLanguage, Map<String, String>>
_publicLandingTranslations = <AppLanguage, Map<String, String>>{
  AppLanguage.telugu: <String, String>{
    'Language': 'భాష',
    'Install': 'ఇన్‌స్టాల్',
    'Install App': 'యాప్ ఇన్‌స్టాల్',
    'Play Store': 'ప్లే స్టోర్',
    'Watch Demo': 'డెమో చూడండి',
    'App': 'యాప్',
    'Categories': 'కేటగిరీలు',
    'Benefits': 'లాభాలు',
    'Download': 'డౌన్‌లోడ్',
    'Get the App': 'యాప్ పొందండి',
    'Available on mobile': 'మొబైల్‌లో అందుబాటులో',
    'Telugu poster app for every day': 'ప్రతి రోజుకు తెలుగు పోస్టర్ యాప్',
    'Posters, wishes and festival creatives in one joyful app.':
        'పోస్టర్లు, శుభాకాంక్షలు, పండుగ క్రియేటివ్స్ అన్నీ ఒకే యాప్‌లో.',
    'Mana Poster helps people find ready-to-share designs for daily wishes, festivals, devotional posts, birthdays, events, news and business promotions.':
        'రోజువారీ శుభాకాంక్షలు, పండుగలు, భక్తి పోస్టులు, పుట్టినరోజులు, ఈవెంట్లు, వార్తలు, బిజినెస్ ప్రమోషన్లకు రెడీ డిజైన్లు Mana Poster లో సులభంగా దొరుకుతాయి.',
    'Daily wishes': 'రోజువారీ శుభాకాంక్షలు',
    'Festival posters': 'పండుగ పోస్టర్లు',
    'Quick sharing': 'త్వరిత షేరింగ్',
    'Today special': 'ఈరోజు ప్రత్యేకం',
    'Ready designs for sharing': 'షేర్ చేయడానికి రెడీ డిజైన్లు',
    'Festival': 'పండుగ',
    'Birthday': 'పుట్టినరోజు',
    'Devotional': 'భక్తి',
    'Business': 'బిజినెస్',
    'Good Night': 'శుభ రాత్రి',
    'Good Morning': 'శుభోదయం',
    'Motivational': 'ప్రేరణాత్మక',
    'Love Quotes': 'ప్రేమ కోట్స్',
    'Today Special': 'ఈరోజు ప్రత్యేకం',
    'Birthdays': 'పుట్టినరోజులు',
    'Life Advice': 'జీవిత సలహాలు',
    'Gita Wisdom': 'గీతా జ్ఞానం',
    'News': 'వార్తలు',
    'Mahabharata': 'మహాభారతం',
    'Anniversary': 'వార్షికోత్సవం',
    'Good Thoughts': 'మంచి ఆలోచనలు',
    'Bible': 'బైబిల్',
    'Islam': 'ఇస్లాం',
    'New': 'కొత్తవి',
    'MADE FOR REAL USE': 'నిజమైన ఉపయోగం కోసం',
    'For greetings, local updates, promotions and personal wishes.':
        'శుభాకాంక్షలు, స్థానిక అప్‌డేట్లు, ప్రమోషన్లు, వ్యక్తిగత విషెస్ కోసం.',
    'Mana Poster is simple enough for everyday users and useful enough for people who post regularly for community, business and events.':
        'ప్రతి రోజు వాడే వారికి సింపుల్‌గా, కమ్యూనిటీ, బిజినెస్, ఈవెంట్ల కోసం రెగ్యులర్‌గా పోస్ట్ చేసే వారికి ఉపయోగకరంగా ఉంటుంది.',
    'Morning, night and positive thought posters.':
        'మార్నింగ్, నైట్, మంచి ఆలోచనల పోస్టర్లు.',
    'Festivals': 'పండుగలు',
    'Seasonal and devotional poster collections.':
        'సీజనల్ మరియు భక్తి పోస్టర్ కలెక్షన్లు.',
    'Promotions': 'ప్రమోషన్లు',
    'Business, event and announcement creatives.':
        'బిజినెస్, ఈవెంట్, అనౌన్స్‌మెంట్ క్రియేటివ్స్.',
    'Personal moments': 'వ్యక్తిగత సందర్భాలు',
    'Birthday, anniversary and special day wishes.':
        'పుట్టినరోజు, వార్షికోత్సవం, ప్రత్యేక రోజు శుభాకాంక్షలు.',
    'CLEAR APP VALUE': 'స్పష్టమైన యాప్ విలువ',
    'Everything people need for daily social posting.':
        'రోజువారీ సోషల్ పోస్టింగ్‌కు కావాల్సిన ప్రతిదీ.',
    'The app keeps poster discovery simple: pick the occasion, choose a ready design, add profile details where needed and share it quickly.':
        'సందర్భం ఎంచుకోండి, రెడీ డిజైన్ తీసుకోండి, అవసరమైన చోట ప్రొఫైల్ వివరాలు జోడించి వెంటనే షేర్ చేయండి.',
    'Occasion-ready': 'సందర్భానికి రెడీ',
    'Good morning, birthdays, devotional, news, events and new collections are easy to browse.':
        'శుభోదయం, పుట్టినరోజులు, భక్తి, వార్తలు, ఈవెంట్లు, కొత్త కలెక్షన్లు సులభంగా చూడొచ్చు.',
    'Profile-friendly': 'ప్రొఫైల్‌కు అనుకూలం',
    'Names, contact details and branding can be used wherever the app supports personalized posters.':
        'పర్సనలైజ్డ్ పోస్టర్లలో పేరు, కాంటాక్ట్ వివరాలు, బ్రాండింగ్ ఉపయోగించొచ్చు.',
    'Share fast': 'వేగంగా షేర్',
    'Download and share posters on social platforms without making the user feel lost.':
        'కన్ఫ్యూజన్ లేకుండా పోస్టర్లను డౌన్‌లోడ్ చేసి సోషల్ ప్లాట్‌ఫార్మ్‌లలో షేర్ చేయండి.',
    'POSTER COLLECTIONS': 'పోస్టర్ కలెక్షన్లు',
    'A colorful library for every moment.': 'ప్రతి సందర్భానికి రంగుల లైబ్రరీ.',
    'Festival wishes, daily posts, devotional messages, birthday designs and fresh collections stay easy to recognize.':
        'పండుగ విషెస్, రోజువారీ పోస్టులు, భక్తి మెసేజ్‌లు, బర్త్‌డే డిజైన్లు, కొత్త కలెక్షన్లు స్పష్టంగా కనిపిస్తాయి.',
    'INSIDE THE APP': 'యాప్ లోపల',
    'Everything is arranged for fast poster discovery.':
        'పోస్టర్లు త్వరగా కనుగొనడానికి అన్నీ సరిగ్గా అమర్చబడ్డాయి.',
    'The app experience is focused on finding the right poster quickly, keeping useful details ready, and sharing without confusion.':
        'సరైన పోస్టర్ త్వరగా కనుగొనడం, వివరాలు రెడీగా ఉంచడం, కన్ఫ్యూజన్ లేకుండా షేర్ చేయడం మీద యాప్ ఫోకస్ ఉంటుంది.',
    'Saved profile details': 'సేవ్ చేసిన ప్రొఫైల్ వివరాలు',
    'Keep name, photo, phone and identity details ready for poster use.':
        'పోస్టర్ల కోసం పేరు, ఫోటో, ఫోన్, గుర్తింపు వివరాలు రెడీగా ఉంచండి.',
    'Easy category browsing': 'సులభమైన కేటగిరీ బ్రౌజింగ్',
    'Daily, festival, devotional, birthday and special collections stay organized.':
        'రోజువారీ, పండుగ, భక్తి, పుట్టినరోజు, ప్రత్యేక కలెక్షన్లు ఆర్గనైజ్డ్‌గా ఉంటాయి.',
    'Premium collections': 'ప్రీమియం కలెక్షన్లు',
    'Useful poster sets and polished designs can be surfaced for regular users.':
        'రెగ్యులర్ యూజర్లకు ఉపయోగకరమైన పోస్టర్ సెట్లు, పాలిష్డ్ డిజైన్లు అందుబాటులో ఉంటాయి.',
    'Telugu-first feel': 'తెలుగు-ఫస్ట్ ఫీల్',
    'The app is shaped around Telugu users, local occasions and daily sharing habits.':
        'తెలుగు యూజర్లు, స్థానిక సందర్భాలు, రోజువారీ షేరింగ్ అలవాట్లకు అనుగుణంగా యాప్ రూపొందింది.',
    'Timely updates': 'సమయానికి అప్‌డేట్లు',
    'Fresh posters and important occasion collections are easy to notice.':
        'కొత్త పోస్టర్లు, ముఖ్యమైన సందర్భాల కలెక్షన్లు సులభంగా కనిపిస్తాయి.',
    'Clean downloads': 'క్లీన్ డౌన్‌లోడ్లు',
    'Save useful posters and share them on WhatsApp and social platforms.':
        'ఉపయోగకరమైన పోస్టర్లను సేవ్ చేసి WhatsApp మరియు సోషల్ ప్లాట్‌ఫార్మ్‌లలో షేర్ చేయండి.',
    'DAILY FLOW': 'రోజువారీ ఫ్లో',
    'A poster routine that feels simple every morning.':
        'ప్రతి ఉదయం సింపుల్‌గా అనిపించే పోస్టర్ రొటీన్.',
    'People can open the app, scan today-friendly collections, pick a useful poster, and share it in a few taps.':
        'యాప్ ఓపెన్ చేసి, ఈరోజుకి సరిపోయే కలెక్షన్లు చూసి, ఉపయోగకరమైన పోస్టర్ ఎంచుకుని కొన్ని ట్యాప్స్‌లో షేర్ చేయవచ్చు.',
    'Open today collections': 'ఈరోజు కలెక్షన్లు ఓపెన్ చేయండి',
    'Fresh and relevant categories are easy to scan.':
        'ఫ్రెష్ మరియు రిలెవెంట్ కేటగిరీలు సులభంగా స్కాన్ చేయొచ్చు.',
    'Select the right design': 'సరైన డిజైన్ ఎంచుకోండి',
    'Choose the poster that matches your message.':
        'మీ మెసేజ్‌కు సరిపోయే పోస్టర్ ఎంచుకోండి.',
    'Save and share': 'సేవ్ చేసి షేర్ చేయండి',
    'Use it for WhatsApp, status, groups or social pages.':
        'WhatsApp, స్టేటస్, గ్రూప్స్ లేదా సోషల్ పేజీల కోసం ఉపయోగించండి.',
    'HOW PEOPLE USE IT': 'ఎలా వాడతారు',
    'Open the app, find the right design, share with confidence.':
        'యాప్ ఓపెన్ చేయండి, సరైన డిజైన్ కనుగొనండి, నమ్మకంగా షేర్ చేయండి.',
    'Mana Poster is built for busy users who want clear categories, familiar Telugu-first content and quick sharing.':
        'క్లియర్ కేటగిరీలు, తెలుగు-ఫస్ట్ కంటెంట్, త్వరిత షేరింగ్ కావాలనుకునే బిజీ యూజర్ల కోసం Mana Poster నిర్మించబడింది.',
    'Choose occasion': 'సందర్భం ఎంచుకోండి',
    'Browse the category that matches the day, festival, event or message.':
        'రోజు, పండుగ, ఈవెంట్ లేదా మెసేజ్‌కు సరిపోయే కేటగిరీ చూడండి.',
    'Pick a poster': 'పోస్టర్ ఎంచుకోండి',
    'Select a ready design that looks right for your audience.':
        'మీ ఆడియన్స్‌కు సరిపోయే రెడీ డిజైన్ ఎంచుకోండి.',
    'Download or share': 'డౌన్‌లోడ్ లేదా షేర్',
    'Save the poster or share it directly wherever you need it.':
        'పోస్టర్ సేవ్ చేయండి లేదా అవసరమైన చోట నేరుగా షేర్ చేయండి.',
    'WHY IT FEELS EASY': 'ఎందుకు సులభంగా అనిపిస్తుంది',
    'Clear categories, familiar content and quick actions.':
        'క్లియర్ కేటగిరీలు, పరిచయం ఉన్న కంటెంట్, త్వరిత యాక్షన్స్.',
    'The landing page now explains the app without confusing backend language. Visitors immediately understand what the app is for.':
        'కన్ఫ్యూజింగ్ పదాలు లేకుండా యాప్ ఏం చేస్తుందో ఈ పేజీ వెంటనే అర్థమయ్యేలా చెబుతుంది.',
    'Telugu audience': 'తెలుగు ఆడియన్స్',
    'Clear categories': 'క్లియర్ కేటగిరీలు',
    'Poster library': 'పోస్టర్ లైబ్రరీ',
    'Mobile friendly': 'మొబైల్ ఫ్రెండ్లీ',
    'Fast sharing': 'ఫాస్ట్ షేరింగ్',
    'COMMON QUESTIONS': 'సాధారణ ప్రశ్నలు',
    'Visitors should understand the app before installing.':
        'ఇన్‌స్టాల్ చేసే ముందు యాప్ గురించి స్పష్టంగా అర్థం కావాలి.',
    'These quick answers make the landing page feel complete and reduce confusion for new users.':
        'ఈ త్వరిత సమాధానాలు కొత్త యూజర్ల కన్ఫ్యూజన్ తగ్గిస్తాయి.',
    'What is Mana Poster?': 'Mana Poster అంటే ఏమిటి?',
    'It is a Telugu poster app for daily wishes, festivals, devotional posts, birthdays, events and promotions.':
        'ఇది రోజువారీ విషెస్, పండుగలు, భక్తి పోస్టులు, పుట్టినరోజులు, ఈవెంట్లు, ప్రమోషన్ల కోసం తెలుగు పోస్టర్ యాప్.',
    'Can users share posters quickly?':
        'యూజర్లు పోస్టర్లు త్వరగా షేర్ చేయగలరా?',
    'Yes. The app is designed for fast save and share flows for mobile-first users.':
        'అవును. మొబైల్ యూజర్ల కోసం ఫాస్ట్ సేవ్ మరియు షేర్ ఫ్లోలతో యాప్ రూపొందింది.',
    'Does it support personal details?': 'వ్యక్తిగత వివరాలకు సపోర్ట్ ఉందా?',
    'Yes. Saved profile details help users keep identity information ready where the app supports it.':
        'అవును. సేవ్ చేసిన ప్రొఫైల్ వివరాలు అవసరమైన చోట రెడీగా ఉంటాయి.',
    'Who is it useful for?': 'ఎవరికి ఉపయోగపడుతుంది?',
    'Individuals, local businesses, event organizers, community pages and regular social media users.':
        'వ్యక్తులు, స్థానిక బిజినెస్‌లు, ఈవెంట్ ఆర్గనైజర్లు, కమ్యూనిటీ పేజీలు, రెగ్యులర్ సోషల్ మీడియా యూజర్లకు.',
    'Ready to make daily posting easier?':
        'రోజువారీ పోస్టింగ్‌ను సులభం చేయడానికి రెడీనా?',
    'Install Mana Poster and keep useful poster collections close to your phone.':
        'Mana Poster ఇన్‌స్టాల్ చేసి ఉపయోగకరమైన పోస్టర్ కలెక్షన్లు మీ ఫోన్‌లో దగ్గర ఉంచుకోండి.',
    'Install Mana Poster': 'Mana Poster ఇన్‌స్టాల్ చేయండి',
    'Telugu poster app for daily sharing.':
        'రోజువారీ షేరింగ్ కోసం తెలుగు పోస్టర్ యాప్.',
    'Privacy': 'ప్రైవసీ',
    'Terms': 'నిబంధనలు',
    '(c) 2026 Mana Poster. All rights reserved.':
        '(c) 2026 Mana Poster. అన్ని హక్కులు రిజర్వ్ చేయబడ్డాయి.',
  },
  AppLanguage.hindi: <String, String>{
    'Language': 'भाषा',
    'Install': 'इंस्टॉल',
    'Install App': 'ऐप इंस्टॉल करें',
    'Play Store': 'प्ले स्टोर',
    'Watch Demo': 'डेमो देखें',
    'App': 'ऐप',
    'Categories': 'कैटेगरी',
    'Benefits': 'फायदे',
    'Download': 'डाउनलोड',
    'Get the App': 'ऐप पाएं',
    'Available on mobile': 'मोबाइल पर उपलब्ध',
    'Telugu poster app for every day': 'हर दिन के लिए तेलुगु पोस्टर ऐप',
    'Posters, wishes and festival creatives in one joyful app.':
        'पोस्टर, शुभकामनाएं और त्योहार क्रिएटिव्स एक ही ऐप में.',
    'Mana Poster helps people find ready-to-share designs for daily wishes, festivals, devotional posts, birthdays, events, news and business promotions.':
        'Mana Poster में daily wishes, festivals, devotional posts, birthdays, events, news और business promotions के ready designs आसानी से मिलते हैं.',
    'Daily wishes': 'डेली शुभकामनाएं',
    'Festival posters': 'त्योहार पोस्टर',
    'Quick sharing': 'फास्ट शेयरिंग',
    'Today special': 'आज का स्पेशल',
    'Ready designs for sharing': 'शेयर करने के लिए रेडी डिजाइन',
    'Festival': 'त्योहार',
    'Birthday': 'जन्मदिन',
    'Devotional': 'भक्ति',
    'Business': 'बिजनेस',
    'Good Night': 'शुभ रात्रि',
    'Good Morning': 'सुप्रभात',
    'Motivational': 'प्रेरणादायक',
    'Love Quotes': 'लव कोट्स',
    'Today Special': 'आज का स्पेशल',
    'Birthdays': 'जन्मदिन',
    'Life Advice': 'जीवन सलाह',
    'Gita Wisdom': 'गीता ज्ञान',
    'News': 'समाचार',
    'Mahabharata': 'महाभारत',
    'Anniversary': 'वर्षगांठ',
    'Good Thoughts': 'अच्छे विचार',
    'Bible': 'बाइबल',
    'Islam': 'इस्लाम',
    'New': 'नया',
    'MADE FOR REAL USE': 'असल उपयोग के लिए',
    'For greetings, local updates, promotions and personal wishes.':
        'ग्रीटिंग्स, लोकल अपडेट्स, प्रमोशन्स और personal wishes के लिए.',
    'Mana Poster is simple enough for everyday users and useful enough for people who post regularly for community, business and events.':
        'यह daily users के लिए simple है और community, business, events के regular posting users के लिए useful है.',
    'Morning, night and positive thought posters.':
        'मॉर्निंग, नाइट और positive thought posters.',
    'Festivals': 'त्योहार',
    'Seasonal and devotional poster collections.':
        'सीजनल और devotional poster collections.',
    'Promotions': 'प्रमोशन्स',
    'Business, event and announcement creatives.':
        'बिजनेस, इवेंट और announcement creatives.',
    'Personal moments': 'पर्सनल मोमेंट्स',
    'Birthday, anniversary and special day wishes.':
        'Birthday, anniversary और special day wishes.',
    'CLEAR APP VALUE': 'स्पष्ट ऐप वैल्यू',
    'Everything people need for daily social posting.':
        'Daily social posting के लिए जरूरी सब कुछ.',
    'The app keeps poster discovery simple: pick the occasion, choose a ready design, add profile details where needed and share it quickly.':
        'Occasion चुनें, ready design लें, जरूरत हो तो profile details जोड़ें और जल्दी share करें.',
    'Occasion-ready': 'Occasion-ready',
    'Good morning, birthdays, devotional, news, events and new collections are easy to browse.':
        'Good morning, birthdays, devotional, news, events और new collections आसानी से browse होते हैं.',
    'Profile-friendly': 'Profile-friendly',
    'Names, contact details and branding can be used wherever the app supports personalized posters.':
        'जहां app support करता है वहां name, contact details और branding use कर सकते हैं.',
    'Share fast': 'जल्दी शेयर',
    'Download and share posters on social platforms without making the user feel lost.':
        'बिना confusion के posters download करके social platforms पर share करें.',
    'POSTER COLLECTIONS': 'पोस्टर कलेक्शन्स',
    'A colorful library for every moment.': 'हर मौके के लिए colorful library.',
    'Festival wishes, daily posts, devotional messages, birthday designs and fresh collections stay easy to recognize.':
        'Festival wishes, daily posts, devotional messages, birthday designs और fresh collections साफ दिखते हैं.',
    'INSIDE THE APP': 'ऐप के अंदर',
    'Everything is arranged for fast poster discovery.':
        'Fast poster discovery के लिए सब कुछ arranged है.',
    'The app experience is focused on finding the right poster quickly, keeping useful details ready, and sharing without confusion.':
        'Right poster जल्दी ढूंढना, details ready रखना और बिना confusion share करना इसका focus है.',
    'Saved profile details': 'Saved profile details',
    'Keep name, photo, phone and identity details ready for poster use.':
        'Poster use के लिए name, photo, phone और identity details ready रखें.',
    'Easy category browsing': 'Easy category browsing',
    'Daily, festival, devotional, birthday and special collections stay organized.':
        'Daily, festival, devotional, birthday और special collections organized रहते हैं.',
    'Premium collections': 'Premium collections',
    'Useful poster sets and polished designs can be surfaced for regular users.':
        'Regular users के लिए useful poster sets और polished designs दिखते हैं.',
    'Telugu-first feel': 'Telugu-first feel',
    'The app is shaped around Telugu users, local occasions and daily sharing habits.':
        'App Telugu users, local occasions और daily sharing habits के हिसाब से बना है.',
    'Timely updates': 'समय पर अपडेट्स',
    'Fresh posters and important occasion collections are easy to notice.':
        'Fresh posters और important occasion collections आसानी से दिखते हैं.',
    'Clean downloads': 'Clean downloads',
    'Save useful posters and share them on WhatsApp and social platforms.':
        'Useful posters save करें और WhatsApp/social platforms पर share करें.',
    'DAILY FLOW': 'डेली फ्लो',
    'A poster routine that feels simple every morning.':
        'हर सुबह simple लगने वाला poster routine.',
    'People can open the app, scan today-friendly collections, pick a useful poster, and share it in a few taps.':
        'App खोलें, today-friendly collections देखें, poster चुनें और कुछ taps में share करें.',
    'Open today collections': 'आज के collections खोलें',
    'Fresh and relevant categories are easy to scan.':
        'Fresh और relevant categories scan करना आसान है.',
    'Select the right design': 'सही design चुनें',
    'Choose the poster that matches your message.':
        'अपने message से match होने वाला poster चुनें.',
    'Save and share': 'Save और share',
    'Use it for WhatsApp, status, groups or social pages.':
        'WhatsApp, status, groups या social pages के लिए use करें.',
    'HOW PEOPLE USE IT': 'लोग कैसे use करते हैं',
    'Open the app, find the right design, share with confidence.':
        'App खोलें, right design ढूंढें, confidence से share करें.',
    'Mana Poster is built for busy users who want clear categories, familiar Telugu-first content and quick sharing.':
        'Clear categories, Telugu-first content और quick sharing चाहने वाले busy users के लिए.',
    'Choose occasion': 'Occasion चुनें',
    'Browse the category that matches the day, festival, event or message.':
        'Day, festival, event या message से match category browse करें.',
    'Pick a poster': 'Poster चुनें',
    'Select a ready design that looks right for your audience.':
        'Audience के लिए सही ready design चुनें.',
    'Download or share': 'Download या share',
    'Save the poster or share it directly wherever you need it.':
        'Poster save करें या जहां जरूरत हो direct share करें.',
    'WHY IT FEELS EASY': 'क्यों आसान लगता है',
    'Clear categories, familiar content and quick actions.':
        'Clear categories, familiar content और quick actions.',
    'The landing page now explains the app without confusing backend language. Visitors immediately understand what the app is for.':
        'Page confusing language के बिना app को clear explain करता है.',
    'Telugu audience': 'Telugu audience',
    'Clear categories': 'Clear categories',
    'Poster library': 'Poster library',
    'Mobile friendly': 'Mobile friendly',
    'Fast sharing': 'Fast sharing',
    'COMMON QUESTIONS': 'सामान्य सवाल',
    'Visitors should understand the app before installing.':
        'Install करने से पहले visitors को app समझ आना चाहिए.',
    'These quick answers make the landing page feel complete and reduce confusion for new users.':
        'ये quick answers new users की confusion कम करते हैं.',
    'What is Mana Poster?': 'Mana Poster क्या है?',
    'It is a Telugu poster app for daily wishes, festivals, devotional posts, birthdays, events and promotions.':
        'यह daily wishes, festivals, devotional posts, birthdays, events और promotions के लिए Telugu poster app है.',
    'Can users share posters quickly?':
        'क्या users posters जल्दी share कर सकते हैं?',
    'Yes. The app is designed for fast save and share flows for mobile-first users.':
        'हां. Mobile-first users के लिए fast save और share flows हैं.',
    'Does it support personal details?': 'क्या personal details support हैं?',
    'Yes. Saved profile details help users keep identity information ready where the app supports it.':
        'हां. Saved profile details identity information ready रखती हैं.',
    'Who is it useful for?': 'यह किसके लिए useful है?',
    'Individuals, local businesses, event organizers, community pages and regular social media users.':
        'Individuals, local businesses, event organizers, community pages और regular social media users.',
    'Ready to make daily posting easier?': 'Daily posting आसान बनाना है?',
    'Install Mana Poster and keep useful poster collections close to your phone.':
        'Mana Poster install करें और useful poster collections phone में रखें.',
    'Install Mana Poster': 'Mana Poster इंस्टॉल करें',
    'Telugu poster app for daily sharing.':
        'Daily sharing के लिए Telugu poster app.',
    'Privacy': 'Privacy',
    'Terms': 'Terms',
    '(c) 2026 Mana Poster. All rights reserved.':
        '(c) 2026 Mana Poster. सभी अधिकार सुरक्षित.',
  },
  AppLanguage.tamil: <String, String>{
    'Language': 'மொழி',
    'Install': 'நிறுவு',
    'Install App': 'ஆப் நிறுவு',
    'Play Store': 'ப்ளே ஸ்டோர்',
    'Watch Demo': 'டெமோ பார்க்க',
    'App': 'ஆப்',
    'Categories': 'வகைகள்',
    'Benefits': 'நன்மைகள்',
    'Download': 'பதிவிறக்கம்',
    'Get the App': 'ஆப் பெறுங்கள்',
    'Available on mobile': 'மொபைலில் கிடைக்கும்',
    'Telugu poster app for every day':
        'ஒவ்வொரு நாளுக்கும் தெலுங்கு போஸ்டர் ஆப்',
    'Posters, wishes and festival creatives in one joyful app.':
        'போஸ்டர்கள், வாழ்த்துகள், பண்டிகை கிரியேட்டிவ்கள் எல்லாம் ஒரே ஆப்பில்.',
    'Daily wishes': 'தினசரி வாழ்த்துகள்',
    'Festival posters': 'பண்டிகை போஸ்டர்கள்',
    'Quick sharing': 'வேகமான பகிர்வு',
    'Today special': 'இன்றைய சிறப்பு',
    'Ready designs for sharing': 'பகிர தயாரான டிசைன்கள்',
    'Festival': 'பண்டிகை',
    'Birthday': 'பிறந்தநாள்',
    'Devotional': 'பக்தி',
    'Business': 'பிசினஸ்',
    'Good Night': 'இனிய இரவு',
    'Good Morning': 'காலை வணக்கம்',
    'Motivational': 'ஊக்கமூட்டும்',
    'Love Quotes': 'காதல் மேற்கோள்கள்',
    'Today Special': 'இன்றைய சிறப்பு',
    'Birthdays': 'பிறந்தநாள்',
    'Life Advice': 'வாழ்க்கை அறிவுரை',
    'Gita Wisdom': 'கீதை ஞானம்',
    'News': 'செய்திகள்',
    'Mahabharata': 'மகாபாரதம்',
    'Anniversary': 'ஆண்டு விழா',
    'Good Thoughts': 'நல்ல எண்ணங்கள்',
    'Bible': 'பைபிள்',
    'Islam': 'இஸ்லாம்',
    'New': 'புதியவை',
    'MADE FOR REAL USE': 'உண்மையான பயன்பாட்டுக்கு',
    'For greetings, local updates, promotions and personal wishes.':
        'வாழ்த்துகள், உள்ளூர் அப்டேட்கள், புரமோஷன்கள், தனிப்பட்ட wishes க்கு.',
    'Festivals': 'பண்டிகைகள்',
    'Promotions': 'புரமோஷன்கள்',
    'Personal moments': 'தனிப்பட்ட தருணங்கள்',
    'CLEAR APP VALUE': 'தெளிவான ஆப் மதிப்பு',
    'Everything people need for daily social posting.':
        'தினசரி social posting க்கு தேவையான எல்லாம்.',
    'Occasion-ready': 'நிகழ்வுக்கு தயார்',
    'Profile-friendly': 'புரொஃபைல் friendly',
    'Share fast': 'வேகமாக பகிர்',
    'POSTER COLLECTIONS': 'போஸ்டர் கலெக்ஷன்கள்',
    'A colorful library for every moment.':
        'ஒவ்வொரு தருணத்திற்கும் வண்ணமயமான library.',
    'INSIDE THE APP': 'ஆப் உள்ளே',
    'Everything is arranged for fast poster discovery.':
        'போஸ்டர்கள் விரைவாக கண்டுபிடிக்க அனைத்தும் ஒழுங்காக உள்ளது.',
    'Saved profile details': 'சேமித்த புரொஃபைல் விவரங்கள்',
    'Easy category browsing': 'எளிய category browsing',
    'Premium collections': 'பிரீமியம் கலெக்ஷன்கள்',
    'Telugu-first feel': 'Telugu-first உணர்வு',
    'Timely updates': 'நேரமான அப்டேட்கள்',
    'Clean downloads': 'சுத்தமான downloads',
    'DAILY FLOW': 'தினசரி flow',
    'A poster routine that feels simple every morning.':
        'ஒவ்வொரு காலையிலும் எளிதாக இருக்கும் poster routine.',
    'Open today collections': 'இன்றைய collections திறக்க',
    'Select the right design': 'சரியான design தேர்வு',
    'Save and share': 'சேமித்து பகிர்',
    'HOW PEOPLE USE IT': 'மக்கள் எப்படி பயன்படுத்துகிறார்கள்',
    'Open the app, find the right design, share with confidence.':
        'ஆப் திறந்து, சரியான design கண்டுபிடித்து, நம்பிக்கையுடன் பகிருங்கள்.',
    'Choose occasion': 'நிகழ்வு தேர்வு',
    'Pick a poster': 'போஸ்டர் தேர்வு',
    'Download or share': 'Download அல்லது share',
    'WHY IT FEELS EASY': 'ஏன் எளிதாக தெரிகிறது',
    'Clear categories, familiar content and quick actions.':
        'தெளிவான categories, பழக்கமான content, விரைவான actions.',
    'Telugu audience': 'தெலுங்கு audience',
    'Clear categories': 'தெளிவான categories',
    'Poster library': 'போஸ்டர் library',
    'Mobile friendly': 'மொபைல் friendly',
    'Fast sharing': 'வேகமான sharing',
    'COMMON QUESTIONS': 'பொதுவான கேள்விகள்',
    'Visitors should understand the app before installing.':
        'நிறுவுவதற்கு முன் visitors ஆப்பை புரிந்துகொள்ள வேண்டும்.',
    'What is Mana Poster?': 'Mana Poster என்றால் என்ன?',
    'Can users share posters quickly?':
        'Users போஸ்டர்களை விரைவாக share செய்ய முடியுமா?',
    'Does it support personal details?': 'Personal details support இருக்கிறதா?',
    'Who is it useful for?': 'யாருக்கு பயன்படும்?',
    'Ready to make daily posting easier?': 'Daily posting எளிதாக்க தயாரா?',
    'Install Mana Poster': 'Mana Poster நிறுவு',
    'Telugu poster app for daily sharing.':
        'தினசரி sharing க்கு தெலுங்கு poster app.',
    'Privacy': 'தனியுரிமை',
    'Terms': 'விதிமுறைகள்',
    '(c) 2026 Mana Poster. All rights reserved.':
        '(c) 2026 Mana Poster. அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை.',
  },
  AppLanguage.kannada: <String, String>{
    'Language': 'ಭಾಷೆ',
    'Install': 'ಇನ್‌ಸ್ಟಾಲ್',
    'Install App': 'ಆಪ್ ಇನ್‌ಸ್ಟಾಲ್',
    'Play Store': 'ಪ್ಲೇ ಸ್ಟೋರ್',
    'Watch Demo': 'ಡೆಮೋ ನೋಡಿ',
    'App': 'ಆಪ್',
    'Categories': 'ವರ್ಗಗಳು',
    'Benefits': 'ಲಾಭಗಳು',
    'Download': 'ಡೌನ್‌ಲೋಡ್',
    'Get the App': 'ಆಪ್ ಪಡೆಯಿರಿ',
    'Available on mobile': 'ಮೊಬೈಲ್‌ನಲ್ಲಿ ಲಭ್ಯ',
    'Telugu poster app for every day': 'ಪ್ರತಿ ದಿನಕ್ಕೂ ತೆಲುಗು ಪೋಸ್ಟರ್ ಆಪ್',
    'Posters, wishes and festival creatives in one joyful app.':
        'ಪೋಸ್ಟರ್‌ಗಳು, ಶುಭಾಶಯಗಳು, ಹಬ್ಬದ creatives ಎಲ್ಲವೂ ಒಂದೇ ಆಪ್‌ನಲ್ಲಿ.',
    'Daily wishes': 'ದಿನನಿತ್ಯ ಶುಭಾಶಯಗಳು',
    'Festival posters': 'ಹಬ್ಬದ ಪೋಸ್ಟರ್‌ಗಳು',
    'Quick sharing': 'ವೇಗದ ಹಂಚಿಕೆ',
    'Today special': 'ಇಂದಿನ ವಿಶೇಷ',
    'Ready designs for sharing': 'ಹಂಚಲು ಸಿದ್ಧ designs',
    'Festival': 'ಹಬ್ಬ',
    'Birthday': 'ಹುಟ್ಟುಹಬ್ಬ',
    'Devotional': 'ಭಕ್ತಿ',
    'Business': 'ಬಿಸಿನೆಸ್',
    'Good Night': 'ಶುಭ ರಾತ್ರಿ',
    'Good Morning': 'ಶುಭೋದಯ',
    'Motivational': 'ಪ್ರೇರಣಾತ್ಮಕ',
    'Love Quotes': 'ಪ್ರೇಮ quotes',
    'Today Special': 'ಇಂದಿನ ವಿಶೇಷ',
    'Birthdays': 'ಹುಟ್ಟುಹಬ್ಬಗಳು',
    'Life Advice': 'ಜೀವನ ಸಲಹೆ',
    'Gita Wisdom': 'ಗೀತಾ ಜ್ಞಾನ',
    'News': 'ಸುದ್ದಿ',
    'Mahabharata': 'ಮಹಾಭಾರತ',
    'Anniversary': 'ವಾರ್ಷಿಕೋತ್ಸವ',
    'Good Thoughts': 'ಒಳ್ಳೆಯ ಆಲೋಚನೆಗಳು',
    'Bible': 'ಬೈಬಲ್',
    'Islam': 'ಇಸ್ಲಾಂ',
    'New': 'ಹೊಸದು',
    'MADE FOR REAL USE': 'ನಿಜವಾದ ಬಳಕೆಗೆ',
    'For greetings, local updates, promotions and personal wishes.':
        'ಶುಭಾಶಯಗಳು, local updates, promotions ಮತ್ತು personal wishes ಗೆ.',
    'Festivals': 'ಹಬ್ಬಗಳು',
    'Promotions': 'ಪ್ರಮೋಶನ್‌ಗಳು',
    'Personal moments': 'ವೈಯಕ್ತಿಕ ಕ್ಷಣಗಳು',
    'CLEAR APP VALUE': 'ಸ್ಪಷ್ಟ ಆಪ್ ಮೌಲ್ಯ',
    'Everything people need for daily social posting.':
        'Daily social posting ಗೆ ಬೇಕಾದ ಎಲ್ಲವೂ.',
    'Occasion-ready': 'ಸಂದರ್ಭಕ್ಕೆ ಸಿದ್ಧ',
    'Profile-friendly': 'Profile-friendly',
    'Share fast': 'ವೇಗವಾಗಿ share',
    'POSTER COLLECTIONS': 'ಪೋಸ್ಟರ್ collections',
    'A colorful library for every moment.': 'ಪ್ರತಿ ಕ್ಷಣಕ್ಕೂ ಬಣ್ಣಬಣ್ಣದ library.',
    'INSIDE THE APP': 'ಆಪ್ ಒಳಗೆ',
    'Everything is arranged for fast poster discovery.':
        'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಬೇಗ ಹುಡುಕಲು ಎಲ್ಲವೂ ಸಿದ್ಧವಾಗಿದೆ.',
    'Saved profile details': 'ಸೇವ್ ಮಾಡಿದ profile details',
    'Easy category browsing': 'ಸುಲಭ category browsing',
    'Premium collections': 'Premium collections',
    'Telugu-first feel': 'Telugu-first feel',
    'Timely updates': 'ಸಮಯಕ್ಕೆ updates',
    'Clean downloads': 'Clean downloads',
    'DAILY FLOW': 'ದಿನನಿತ್ಯ flow',
    'A poster routine that feels simple every morning.':
        'ಪ್ರತಿ ಬೆಳಿಗ್ಗೆ ಸುಲಭವಾಗಿ ಅನಿಸುವ poster routine.',
    'Open today collections': 'ಇಂದಿನ collections ತೆರೆ',
    'Select the right design': 'ಸರಿಯಾದ design ಆರಿಸಿ',
    'Save and share': 'Save ಮಾಡಿ share ಮಾಡಿ',
    'HOW PEOPLE USE IT': 'ಜನರು ಹೇಗೆ ಬಳಸುತ್ತಾರೆ',
    'Open the app, find the right design, share with confidence.':
        'ಆಪ್ ತೆರೆದು, ಸರಿಯಾದ design ಹುಡುಕಿ, ನಂಬಿಕೆಯಿಂದ share ಮಾಡಿ.',
    'Choose occasion': 'ಸಂದರ್ಭ ಆರಿಸಿ',
    'Pick a poster': 'ಪೋಸ್ಟರ್ ಆರಿಸಿ',
    'Download or share': 'Download ಅಥವಾ share',
    'WHY IT FEELS EASY': 'ಏಕೆ ಸುಲಭ ಅನಿಸುತ್ತದೆ',
    'Clear categories, familiar content and quick actions.':
        'Clear categories, familiar content ಮತ್ತು quick actions.',
    'Telugu audience': 'ತೆಲುಗು audience',
    'Clear categories': 'Clear categories',
    'Poster library': 'Poster library',
    'Mobile friendly': 'Mobile friendly',
    'Fast sharing': 'Fast sharing',
    'COMMON QUESTIONS': 'ಸಾಮಾನ್ಯ ಪ್ರಶ್ನೆಗಳು',
    'Visitors should understand the app before installing.':
        'Install ಮಾಡುವ ಮುನ್ನ visitors ಗೆ app ಅರ್ಥವಾಗಬೇಕು.',
    'What is Mana Poster?': 'Mana Poster ಎಂದರೆ ಏನು?',
    'Can users share posters quickly?': 'Users posters ಬೇಗ share ಮಾಡಬಹುದಾ?',
    'Does it support personal details?': 'Personal details support ಇದೆಯಾ?',
    'Who is it useful for?': 'ಯಾರಿಗೆ ಉಪಯುಕ್ತ?',
    'Ready to make daily posting easier?': 'Daily posting ಸುಲಭ ಮಾಡಲು ಸಿದ್ಧವೇ?',
    'Install Mana Poster': 'Mana Poster ಇನ್‌ಸ್ಟಾಲ್ ಮಾಡಿ',
    'Telugu poster app for daily sharing.':
        'Daily sharing ಗೆ Telugu poster app.',
    'Privacy': 'Privacy',
    'Terms': 'Terms',
    '(c) 2026 Mana Poster. All rights reserved.':
        '(c) 2026 Mana Poster. ಎಲ್ಲಾ ಹಕ್ಕುಗಳು ಕಾಯ್ದಿರಿಸಲಾಗಿದೆ.',
  },
  AppLanguage.malayalam: <String, String>{
    'Language': 'ഭാഷ',
    'Install': 'ഇൻസ്റ്റാൾ',
    'Install App': 'ആപ്പ് ഇൻസ്റ്റാൾ',
    'Play Store': 'പ്ലേ സ്റ്റോർ',
    'Watch Demo': 'ഡെമോ കാണുക',
    'App': 'ആപ്പ്',
    'Categories': 'വിഭാഗങ്ങൾ',
    'Benefits': 'ഗുണങ്ങൾ',
    'Download': 'ഡൗൺലോഡ്',
    'Get the App': 'ആപ്പ് നേടുക',
    'Available on mobile': 'മൊബൈലിൽ ലഭ്യം',
    'Telugu poster app for every day':
        'എല്ലാ ദിവസത്തിനും തെലുങ്ക് പോസ്റ്റർ ആപ്പ്',
    'Posters, wishes and festival creatives in one joyful app.':
        'പോസ്റ്ററുകൾ, ആശംസകൾ, ഉത്സവ creatives എല്ലാം ഒരു ആപ്പിൽ.',
    'Daily wishes': 'ദൈനംദിന ആശംസകൾ',
    'Festival posters': 'ഉത്സവ പോസ്റ്ററുകൾ',
    'Quick sharing': 'വേഗത്തിലുള്ള sharing',
    'Today special': 'ഇന്നത്തെ സ്പെഷ്യൽ',
    'Ready designs for sharing': 'Share ചെയ്യാൻ ready designs',
    'Festival': 'ഉത്സവം',
    'Birthday': 'ജന്മദിനം',
    'Devotional': 'ഭക്തി',
    'Business': 'ബിസിനസ്',
    'Good Night': 'ശുഭ രാത്രി',
    'Good Morning': 'സുപ്രഭാതം',
    'Motivational': 'പ്രചോദനാത്മക',
    'Love Quotes': 'ലവ് quotes',
    'Today Special': 'ഇന്നത്തെ സ്പെഷ്യൽ',
    'Birthdays': 'ജന്മദിനങ്ങൾ',
    'Life Advice': 'ജീവിത ഉപദേശം',
    'Gita Wisdom': 'ഗീത ജ്ഞാനം',
    'News': 'വാർത്തകൾ',
    'Mahabharata': 'മഹാഭാരതം',
    'Anniversary': 'വാർഷികം',
    'Good Thoughts': 'നല്ല ചിന്തകൾ',
    'Bible': 'ബൈബിൾ',
    'Islam': 'ഇസ്ലാം',
    'New': 'പുതിയത്',
    'MADE FOR REAL USE': 'യഥാർത്ഥ ഉപയോഗത്തിന്',
    'For greetings, local updates, promotions and personal wishes.':
        'Greetings, local updates, promotions, personal wishes എന്നിവയ്ക്ക്.',
    'Festivals': 'ഉത്സവങ്ങൾ',
    'Promotions': 'Promotions',
    'Personal moments': 'വ്യക്തിഗത നിമിഷങ്ങൾ',
    'CLEAR APP VALUE': 'വ്യക്തമായ ആപ്പ് value',
    'Everything people need for daily social posting.':
        'Daily social posting നു വേണ്ടതെല്ലാം.',
    'Occasion-ready': 'Occasion-ready',
    'Profile-friendly': 'Profile-friendly',
    'Share fast': 'വേഗത്തിൽ share',
    'POSTER COLLECTIONS': 'Poster collections',
    'A colorful library for every moment.':
        'ഓരോ നിമിഷത്തിനും colorful library.',
    'INSIDE THE APP': 'ആപ്പിനുള്ളിൽ',
    'Everything is arranged for fast poster discovery.':
        'Posters വേഗത്തിൽ കണ്ടെത്താൻ എല്ലാം arranged ആണ്.',
    'Saved profile details': 'Saved profile details',
    'Easy category browsing': 'Easy category browsing',
    'Premium collections': 'Premium collections',
    'Telugu-first feel': 'Telugu-first feel',
    'Timely updates': 'സമയോചിത updates',
    'Clean downloads': 'Clean downloads',
    'DAILY FLOW': 'Daily flow',
    'A poster routine that feels simple every morning.':
        'ഓരോ രാവിലെയും simple ആയി തോന്നുന്ന poster routine.',
    'Open today collections': 'Today collections തുറക്കുക',
    'Select the right design': 'ശരിയായ design തിരഞ്ഞെടുക്കുക',
    'Save and share': 'Save ചെയ്ത് share ചെയ്യുക',
    'HOW PEOPLE USE IT': 'ആൾക്കാർ എങ്ങനെ ഉപയോഗിക്കുന്നു',
    'Open the app, find the right design, share with confidence.':
        'ആപ്പ് തുറന്ന് right design കണ്ടെത്തി confidence ആയി share ചെയ്യുക.',
    'Choose occasion': 'Occasion തിരഞ്ഞെടുക്കുക',
    'Pick a poster': 'Poster തിരഞ്ഞെടുക്കുക',
    'Download or share': 'Download അല്ലെങ്കിൽ share',
    'WHY IT FEELS EASY': 'എന്തുകൊണ്ട് എളുപ്പം തോന്നുന്നു',
    'Clear categories, familiar content and quick actions.':
        'Clear categories, familiar content, quick actions.',
    'Telugu audience': 'Telugu audience',
    'Clear categories': 'Clear categories',
    'Poster library': 'Poster library',
    'Mobile friendly': 'Mobile friendly',
    'Fast sharing': 'Fast sharing',
    'COMMON QUESTIONS': 'സാധാരണ ചോദ്യങ്ങൾ',
    'Visitors should understand the app before installing.':
        'Install ചെയ്യുന്നതിന് മുമ്പ് visitors app മനസ്സിലാക്കണം.',
    'What is Mana Poster?': 'Mana Poster എന്താണ്?',
    'Can users share posters quickly?':
        'Users posters വേഗത്തിൽ share ചെയ്യാമോ?',
    'Does it support personal details?': 'Personal details support ഉണ്ടോ?',
    'Who is it useful for?': 'ആർക്കാണ് ഉപയോഗപ്രദം?',
    'Ready to make daily posting easier?':
        'Daily posting എളുപ്പമാക്കാൻ ready ആണോ?',
    'Install Mana Poster': 'Mana Poster install ചെയ്യുക',
    'Telugu poster app for daily sharing.':
        'Daily sharing നുള്ള Telugu poster app.',
    'Privacy': 'Privacy',
    'Terms': 'Terms',
    '(c) 2026 Mana Poster. All rights reserved.':
        '(c) 2026 Mana Poster. എല്ലാ അവകാശങ്ങളും സംരക്ഷിതം.',
  },
};

String _customText(LandingPageConfig config, String key, String fallback) {
  final String value = config.customText[key]?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate({
    required this.config,
    required this.installLabel,
    required this.onInstall,
  });

  final LandingPageConfig config;
  final String installLabel;
  final VoidCallback onInstall;

  @override
  double get minExtent => 76;

  @override
  double get maxExtent => 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: overlapsContent ? 4 : 0,
      shadowColor: const Color(0x1A111827),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 30),
          child: Row(
            children: <Widget>[
              Image.asset(
                'assets/branding/mana_poster_logo.png',
                width: 42,
                height: 42,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Color(0xFF6D28D9),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _customText(config, 'headerAppName', AppPublicInfo.appName),
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (!compact) ...<Widget>[
                _HeaderLink(
                  label: _customText(config, 'navCategories', 'Categories'),
                ),
                _HeaderLink(
                  label: _customText(config, 'navPosters', 'Posters'),
                ),
                _HeaderLink(
                  label: _customText(config, 'navFeatures', 'Features'),
                ),
                _HeaderLink(
                  label: _customText(config, 'navSupport', 'Support'),
                ),
              ],
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: onInstall,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(compact ? 'Install' : installLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return oldDelegate.installLabel != installLabel ||
        oldDelegate.config != config ||
        oldDelegate.onInstall != onInstall;
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _JoyBanner extends StatelessWidget {
  const _JoyBanner({
    required this.config,
    required this.onInstall,
    required this.onDemo,
  });

  final LandingPageConfig config;
  final VoidCallback onInstall;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 720;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        width: double.infinity,
        height: compact ? 340 : 460,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F3FF),
            border: Border(bottom: BorderSide(color: Color(0xFFDDD6FE))),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (config.heroImageUrl.isNotEmpty)
                Image.network(
                  config.heroImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              if (config.heroImageUrl.isNotEmpty)
                ColoredBox(color: Colors.white.withValues(alpha: 0.78)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (config.heroEyebrow.isNotEmpty)
                          Text(
                            config.heroEyebrow,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          config.heroTitle.isEmpty
                              ? AppPublicInfo.appName
                              : config.heroTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        if (config.heroSubtitle.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            config.heroSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: onInstall,
                              icon: const Icon(Icons.download_rounded),
                              label: Text(
                                config.heroPrimaryCtaLabel.isEmpty
                                    ? 'Download App'
                                    : config.heroPrimaryCtaLabel,
                              ),
                            ),
                            if (config.watchDemoUrl.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: onDemo,
                                icon: const Icon(Icons.play_circle_rounded),
                                label: Text(
                                  config.heroSecondaryCtaLabel.isEmpty
                                      ? 'Watch Demo'
                                      : config.heroSecondaryCtaLabel,
                                ),
                              ),
                          ],
                        ),
                        if (config.heroHighlightLabel.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 14),
                          Text(
                            config.heroHighlightLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChipsSection extends StatelessWidget {
  const _CategoryChipsSection({
    required this.config,
    required this.selectedId,
    required this.onSelected,
  });

  final LandingPageConfig config;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeading(
            eyebrow: config.categoriesEyebrow.isEmpty
                ? 'Categories'
                : config.categoriesEyebrow,
            title: config.categoriesTitle.isEmpty
                ? 'All app categories'
                : config.categoriesTitle,
            subtitle: config.categoriesSubtitle.isEmpty
                ? 'Browse poster categories and uploaded public website posters.'
                : config.categoriesSubtitle,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: HomeCategoryCatalog.all
                .map((HomeCategoryCatalogEntry item) {
                  final bool selected = item.id == selectedId;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(item.label),
                    avatar: CircleAvatar(
                      backgroundColor: selected
                          ? Colors.white
                          : item.gradient.first,
                      foregroundColor: selected
                          ? const Color(0xFF4C1D95)
                          : Colors.white,
                      child: Text(
                        item.badge.characters.take(1).toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    onSelected: (_) => onSelected(item.id),
                    selectedColor: const Color(0xFF6D28D9),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w900,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF6D28D9)
                          : const Color(0xFFDDD6FE),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _PosterGallerySection extends StatelessWidget {
  const _PosterGallerySection({required this.category, required this.posters});

  final HomeCategoryCatalogEntry category;
  final List<WebsitePoster> posters;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CategoryTitleCard(category: category),
          const SizedBox(height: 16),
          _WebsitePosterGallery(category: category, posters: posters),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CategoryTitleCard extends StatelessWidget {
  const _CategoryTitleCard({required this.category});

  final HomeCategoryCatalogEntry category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: category.gradient),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              category.badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${category.label} posters',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Unlimited poster uploads can live under each category.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebsitePosterGallery extends StatelessWidget {
  const _WebsitePosterGallery({required this.category, required this.posters});

  final HomeCategoryCatalogEntry category;
  final List<WebsitePoster> posters;

  @override
  Widget build(BuildContext context) {
    final List<WebsitePoster> visible = posters
        .where((WebsitePoster poster) {
          final String value = poster.category.toLowerCase().trim();
          return value == category.id.toLowerCase() ||
              value == category.label.toLowerCase();
        })
        .toList(growable: false);
    if (visible.isNotEmpty) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double tileWidth = constraints.maxWidth >= 980
              ? 250
              : constraints.maxWidth >= 680
              ? 210
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: visible
                .map((WebsitePoster poster) {
                  return SizedBox(
                    width: tileWidth.clamp(140, 280),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Image.network(
                          poster.imageUrl,
                          width: tileWidth.clamp(140, 280),
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 180,
                            child: ColoredBox(
                              color: Color(0xFFFFF7ED),
                              child: Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          );
        },
      );
    }
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFB923C)),
      ),
      child: Text(
        '${category.label} posters are empty now. Upload approved posters from the admin page to show them here.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w900,
          height: 1.45,
        ),
      ),
    );
  }
}

class _AppFeaturesSection extends StatelessWidget {
  const _AppFeaturesSection({required this.config});

  final LandingPageConfig config;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeading(
            eyebrow: config.featuresEyebrow.isEmpty
                ? 'App features'
                : config.featuresEyebrow,
            title: config.featuresTitle.isEmpty
                ? 'Ready-made poster platform features'
                : config.featuresTitle,
            subtitle: config.featuresSubtitle.isEmpty
                ? 'Mana Poster keeps ready-made poster designs available.'
                : config.featuresSubtitle,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.4 : 1.45,
                children: <Widget>[
                  _FeatureCard(
                    icon: Icons.collections_rounded,
                    title: _customText(
                      config,
                      'feature1Title',
                      'Ready-made poster library',
                    ),
                    body: _customText(
                      config,
                      'feature1Body',
                      'Festival, devotional, birthday, political, and daily-use posters are ready to browse.',
                    ),
                    colors: const <Color>[Color(0xFF4C1D95), Color(0xFF6D28D9)],
                  ),
                  _FeatureCard(
                    icon: Icons.account_circle_rounded,
                    title: _customText(
                      config,
                      'feature2Title',
                      'Profile-based auto fill',
                    ),
                    body: _customText(
                      config,
                      'feature2Body',
                      'Name, photo, designation, and phone number can be saved once and reused automatically on posters.',
                    ),
                    colors: const <Color>[Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  _FeatureCard(
                    icon: Icons.auto_awesome_rounded,
                    title: _customText(
                      config,
                      'feature3Title',
                      'Featured templates',
                    ),
                    body: _customText(
                      config,
                      'feature3Body',
                      'Polished poster collections are organized by category and ready to use.',
                    ),
                    colors: const <Color>[Color(0xFF7C3AED), Color(0xFF60A5FA)],
                  ),
                  _FeatureCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Unlimited poster uploads',
                    body:
                        'Admins can upload unlimited posters into each category and display them on the public landing page.',
                    colors: <Color>[Color(0xFF9333EA), Color(0xFF60A5FA)],
                  ),
                  _FeatureCard(
                    icon: Icons.verified_user_rounded,
                    title: 'Single profile, many posters',
                    body:
                        'Once profile details are saved, the same details can be reused across many ready-made posters.',
                    colors: <Color>[Color(0xFF60A5FA), Color(0xFF38BDF8)],
                  ),
                  _FeatureCard(
                    icon: Icons.share_rounded,
                    title: 'Download and share',
                    body:
                        'Finished posters can be used for WhatsApp, status updates, and social sharing.',
                    colors: <Color>[Color(0xFF38BDF8), Color(0xFF6D28D9)],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorFlowSection extends StatelessWidget {
  const _CreatorFlowSection({required this.config});

  final LandingPageConfig config;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 62,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF4C1D95),
              Color(0xFF6D28D9),
              Color(0xFF9333EA),
              Color(0xFF0EA5E9),
              Color(0xFFF97316),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 860;
            final Widget copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DarkEyebrow(
                  config.previewEyebrow.isEmpty
                      ? 'Creator flow'
                      : config.previewEyebrow,
                ),
                const SizedBox(height: 8),
                Text(
                  config.previewTitle.isEmpty
                      ? 'Choose poster, auto fill profile, share'
                      : config.previewTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  config.previewSubtitle.isEmpty
                      ? 'Users choose a ready-made design, apply saved profile details, and share quickly.'
                      : config.previewSubtitle,
                  style: const TextStyle(
                    color: Color(0xFFE0F2F1),
                    fontSize: 16,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
            final Widget steps = Column(
              children: <Widget>[
                if (config.previewImageUrl.isNotEmpty) ...<Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        config.previewImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0x33FFFFFF),
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _FlowStep(
                  number: '01',
                  label: _customText(config, 'flowStep1', 'Select category'),
                ),
                _FlowStep(
                  number: '02',
                  label: _customText(
                    config,
                    'flowStep2',
                    'Choose ready-made poster',
                  ),
                ),
                _FlowStep(
                  number: '03',
                  label: _customText(
                    config,
                    'flowStep3',
                    'Use saved profile details',
                  ),
                ),
                _FlowStep(
                  number: '04',
                  label: _customText(config, 'flowStep4', 'Download/share'),
                ),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: copy),
                  const SizedBox(width: 26),
                  Expanded(child: steps),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[copy, const SizedBox(height: 18), steps],
            );
          },
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: <Widget>[
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyManaPosterSection extends StatelessWidget {
  const _WhyManaPosterSection({required this.config});

  final LandingPageConfig config;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeading(
            eyebrow: config.dynamicEventsEyebrow.isEmpty
                ? 'Why Mana Poster'
                : config.dynamicEventsEyebrow,
            title: config.dynamicEventsTitle.isEmpty
                ? 'Built for frequent poster publishing'
                : config.dynamicEventsTitle,
            subtitle: config.dynamicEventsSubtitle.isEmpty
                ? 'Fast, colorful, mobile-focused poster publishing.'
                : config.dynamicEventsSubtitle,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const <Widget>[
              _ReasonPill(icon: Icons.bolt_rounded, label: 'Fast creation'),
              _ReasonPill(
                icon: Icons.language_rounded,
                label: 'Telugu audience',
              ),
              _ReasonPill(
                icon: Icons.category_rounded,
                label: 'Category-first',
              ),
              _ReasonPill(
                icon: Icons.auto_awesome_rounded,
                label: 'Colorful templates',
              ),
              _ReasonPill(
                icon: Icons.mobile_friendly_rounded,
                label: 'Mobile focused',
              ),
              _ReasonPill(
                icon: Icons.campaign_rounded,
                label: 'Campaign ready',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReasonPill extends StatelessWidget {
  const _ReasonPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.config,
    required this.onInstall,
    required this.onPrivacy,
    required this.onTerms,
  });

  final LandingPageConfig config;
  final VoidCallback onInstall;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 68),
      padding: const EdgeInsets.fromLTRB(24, 46, 24, 34),
      color: const Color(0xFF111827),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 24,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 440,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      AppPublicInfo.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.footerTagline.isEmpty
                          ? 'Colorful Telugu poster creation for every daily, devotional, festival, and campaign need.'
                          : config.footerTagline,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onInstall,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      config.downloadButtonLabel.isEmpty
                          ? 'Install App'
                          : config.downloadButtonLabel,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                    ),
                  ),
                  TextButton(
                    onPressed: onPrivacy,
                    child: const Text('Privacy'),
                  ),
                  TextButton(onPressed: onTerms, child: const Text('Terms')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadCtaSection extends StatelessWidget {
  const _DownloadCtaSection({required this.config, required this.onInstall});

  final LandingPageConfig config;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 62,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFB923C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SectionHeading(
              eyebrow: config.downloadEyebrow.isEmpty
                  ? 'Download'
                  : config.downloadEyebrow,
              title: config.downloadTitle.isEmpty
                  ? 'Start Creating Beautiful Telugu Posters Today'
                  : config.downloadTitle,
              subtitle: config.downloadSubtitle.isEmpty
                  ? 'Ready templates and fast sharing in one app.'
                  : config.downloadSubtitle,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onInstall,
              icon: const Icon(Icons.download_rounded),
              label: Text(
                config.downloadButtonLabel.isEmpty
                    ? 'Download App'
                    : config.downloadButtonLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBand extends StatelessWidget {
  const _PageBand({required this.child, this.top = 0});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, top, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFF6D28D9),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 40,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkEyebrow extends StatelessWidget {
  const _DarkEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFFFD166),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
