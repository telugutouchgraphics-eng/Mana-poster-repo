// ignore_for_file: unused_element_parameter

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';
import 'package:mana_poster/features/prehome/services/app_home_banner_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';
import 'package:mana_poster/features/prehome/widgets/poster_identity_visual.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class _TemplateItem {
  const _TemplateItem({
    required this.titleTe,
    required this.titleHi,
    required this.titleEn,
    this.imageUrl,
    this.mediaType = 'image',
    this.videoUrl,
    this.imageAssetPath,
    this.price,
    this.templateId,
    this.templateDocumentSource,
    this.productId,
    this.fallbackProductIds = const <String>[],
    this.pageConfig,
    this.categoryTags = const <String>[],
    this.personalizationConfig,
  });

  final String titleTe;
  final String titleHi;
  final String titleEn;
  final String? imageUrl;
  final String mediaType;
  final String? videoUrl;
  final String? imageAssetPath;
  final int? price;
  final String? templateId;
  final String? templateDocumentSource;
  final String? productId;
  final List<String> fallbackProductIds;
  final EditorPageConfig? pageConfig;
  final List<String> categoryTags;
  final CreatorPosterPersonalization? personalizationConfig;

  bool get isVideo =>
      mediaType == 'video' && (videoUrl?.trim().isNotEmpty ?? false);

  String titleFor(AppLanguage language) => switch (language) {
    AppLanguage.telugu => titleTe,
    AppLanguage.hindi => titleHi,
    AppLanguage.english ||
    AppLanguage.tamil ||
    AppLanguage.kannada ||
    AppLanguage.malayalam => titleEn,
  };
}

class _CategoryChipData {
  const _CategoryChipData({
    required this.slug,
    required this.label,
    this.matchTags = const <String>[],
    this.isDynamic = false,
  });

  final String slug;
  final String label;
  final List<String> matchTags;
  final bool isDynamic;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AppLanguageStateMixin, RouteAware, WidgetsBindingObserver {
  static const String _allCategorySlug = 'all';
  static const List<String> _staticCategorySlugs = <String>[
    'all',
    'good_morning',
    'good_afternoon',
    'good_night',
    'motivational',
    'love_quotes',
    'today_special',
    'birthdays',
    'life_advice',
    'gita_wisdom',
    'news',
    'devotional',
    'mahabharata',
    'anniversary',
    'good_thoughts',
    'bible',
    'islam',
    'new',
  ];

  final DynamicCategoryService _dynamicCategoryService =
      const DynamicCategoryService();
  final AppHomeBannerService _appHomeBannerService =
      const AppHomeBannerService();
  final ApprovedCreatorTemplateService _approvedCreatorTemplateService =
      ApprovedCreatorTemplateService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategorySlug = _allCategorySlug;
  PosterProfileData _viewerPosterProfile = const PosterProfileData(
    nameTelugu: 'User',
    nameEnglish: '',
    whatsappNumber: '',
    nameFontFamily: 'Anek Telugu Condensed Bold',
    displayNameMode: PosterDisplayNameMode.auto,
    photoPath: '',
    photoUrl: '',
  );
  bool _homeRefreshing = false;
  int _posterRenderCycle = 0;
  bool _templatesLoading = true;
  bool _viewerProfileLoading = true;
  List<_TemplateItem> _remoteApprovedTemplates = const <_TemplateItem>[];
  List<AppHomeBanner> _homeBanners = const <AppHomeBanner>[];

  // ignore: unused_field
  static const List<_TemplateItem> _freeTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'శుభోదయం పోస్టర్',
      titleHi: 'गुड मॉर्निंग पोस्टर',
      titleEn: 'Good Morning Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200',
      categoryTags: <String>['good_morning', 'today_special', 'new'],
    ),
    _TemplateItem(
      titleTe: 'బర్త్‌డే పోస్టర్',
      titleHi: 'बर्थडे पोस्टर',
      titleEn: 'Birthday Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?w=1200',
      categoryTags: <String>['birthdays', 'anniversary', 'celebration'],
    ),
    _TemplateItem(
      titleTe: 'భక్తి పోస్టర్',
      titleHi: 'भक्ति पोस्टर',
      titleEn: 'Devotional Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200',
      categoryTags: <String>[
        'devotional',
        'festival',
        'today_special',
        'both_telugu_states',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_hidePhoneNavigationButtons());
    unawaited(ScreenSecurityService.enableSecure());
    unawaited(_loadApprovedCreatorTemplates());
    unawaited(_loadHomeBanners());
    unawaited(_loadViewerPosterProfile());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      AppNavigator.routeObserver.subscribe(this, route);
    }
  }

  Future<void> _hidePhoneNavigationButtons() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: <SystemUiOverlay>[SystemUiOverlay.top],
    );
  }

  Future<void> _restorePhoneNavigationButtons() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  void didPush() {
    unawaited(_hidePhoneNavigationButtons());
    unawaited(ScreenSecurityService.enableSecure());
  }

  @override
  void didPopNext() {
    unawaited(_hidePhoneNavigationButtons());
    unawaited(ScreenSecurityService.enableSecure());
    unawaited(_loadViewerPosterProfile());
    unawaited(
      _TemplateFeedItem.subscriptionBackendService
          .refreshEntitlementInBackground(forceRefresh: true),
    );
  }

  @override
  void didPushNext() {
    unawaited(_restorePhoneNavigationButtons());
    unawaited(ScreenSecurityService.disableSecure());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        _TemplateFeedItem.subscriptionBackendService
            .refreshEntitlementInBackground(forceRefresh: true),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppNavigator.routeObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    unawaited(_restorePhoneNavigationButtons());
    unawaited(ScreenSecurityService.disableSecure());
    super.dispose();
  }

  bool _matchesTemplate(
    _TemplateItem item,
    AppLanguage language,
    _CategoryChipData selectedCategory,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final searchable = <String>[
      item.titleEn,
      item.titleHi,
      item.titleTe,
      item.titleFor(language),
      ...item.categoryTags,
    ].join(' ').toLowerCase();

    if (query.isNotEmpty && !searchable.contains(query)) {
      return false;
    }

    if (selectedCategory.slug == _allCategorySlug) {
      return true;
    }

    final itemTags = item.categoryTags.map(_normalizeTag).toSet();
    final categoryTags = selectedCategory.matchTags.map(_normalizeTag).toSet();
    if (itemTags.intersection(categoryTags).isNotEmpty) {
      return true;
    }

    final fallbackNeedle = _normalizeTag(selectedCategory.label);
    return fallbackNeedle.isNotEmpty && searchable.contains(fallbackNeedle);
  }

  List<_CategoryChipData> _buildDynamicCategories(
    DateTime now,
    AppLanguage language,
  ) {
    final generated = _dynamicCategoryService.categoriesForDate(
      now,
      language: language,
    );
    return generated
        .map(
          (item) => _CategoryChipData(
            slug: item.slug,
            label: item.label,
            matchTags: item.tags,
            isDynamic: true,
          ),
        )
        .toList();
  }

  List<_CategoryChipData> _buildStaticCategories() {
    final labels = context.strings.localizedHomeCategories();
    return List<_CategoryChipData>.generate(labels.length, (int index) {
      final slug = index < _staticCategorySlugs.length
          ? _staticCategorySlugs[index]
          : 'category_$index';
      return _CategoryChipData(
        slug: slug,
        label: labels[index],
        matchTags: _defaultCategoryTagsForSlug(slug),
      );
    }, growable: false);
  }

  List<_CategoryChipData> _mergeCategories(
    List<_CategoryChipData> staticCategories,
    List<_CategoryChipData> dynamicCategories,
  ) {
    final merged = <_CategoryChipData>[];
    final seenSlugs = <String>{};

    void addChip(_CategoryChipData chip) {
      if (seenSlugs.add(chip.slug)) {
        merged.add(chip);
      }
    }

    if (staticCategories.isNotEmpty) {
      addChip(staticCategories.first);
    } else {
      addChip(
        _CategoryChipData(
          slug: _allCategorySlug,
          label: context.strings.localized(telugu: 'అన్నీ', english: 'All'),
          matchTags: <String>['all'],
        ),
      );
    }

    for (final chip in dynamicCategories) {
      addChip(chip);
    }
    for (final chip in staticCategories.skip(1)) {
      addChip(chip);
    }

    return merged;
  }

  List<String> _defaultCategoryTagsForSlug(String slug) {
    return switch (slug) {
      _allCategorySlug => const <String>['all'],
      'good_morning' => const <String>['good_morning', 'morning'],
      'good_afternoon' => const <String>['good_afternoon', 'afternoon'],
      'good_night' => const <String>['good_night', 'night'],
      'motivational' => const <String>['motivational', 'quotes'],
      'love_quotes' => const <String>['love_quotes', 'love'],
      'today_special' => const <String>['today_special', 'important_day'],
      'birthdays' => const <String>['birthdays', 'birthday', 'celebration'],
      'life_advice' => const <String>['life_advice', 'good_thoughts'],
      'gita_wisdom' => const <String>['gita_wisdom', 'devotional'],
      'news' => const <String>['news', 'important_day'],
      'devotional' => const <String>['devotional', 'festival'],
      'mahabharata' => const <String>['mahabharata', 'devotional'],
      'anniversary' => const <String>['anniversary', 'celebration'],
      'good_thoughts' => const <String>['good_thoughts', 'motivational'],
      'bible' => const <String>['bible', 'devotional'],
      'islam' => const <String>['islam', 'devotional'],
      'new' => const <String>['new', 'today_special'],
      _ => <String>[slug],
    };
  }

  String _normalizeTag(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Set<String> _expandCategoryAliases(String normalizedTag) {
    const aliasMap = <String, List<String>>{
      'all': <String>['all'],
      'good_morning': <String>['good_morning', 'morning'],
      'good_afternoon': <String>['good_afternoon', 'afternoon'],
      'good_night': <String>['good_night', 'night'],
      'motivational': <String>['motivational', 'quotes', 'good_thoughts'],
      'love_quotes': <String>['love_quotes', 'love'],
      'today_special': <String>['today_special', 'important_day'],
      'birthdays': <String>['birthdays', 'birthday', 'celebration'],
      'life_advice': <String>['life_advice', 'good_thoughts'],
      'gita_wisdom': <String>['gita_wisdom', 'devotional'],
      'news': <String>['news', 'important_day'],
      'devotional': <String>['devotional', 'festival'],
      'mahabharata': <String>['mahabharata', 'devotional'],
      'anniversary': <String>['anniversary', 'celebration'],
      'good_thoughts': <String>['good_thoughts', 'motivational'],
      'bible': <String>['bible', 'devotional'],
      'islam': <String>['islam', 'devotional'],
      'new': <String>['new', 'today_special'],
      'weekday_special': <String>['weekday_special', 'today_special'],
      'important_day': <String>['important_day', 'today_special'],
      'regional_special': <String>['regional_special', 'today_special'],
      'festival': <String>['festival', 'devotional', 'today_special'],
      'jayanthi': <String>['jayanthi', 'important_day', 'regional_special'],
      'vardhanthi': <String>['vardhanthi', 'important_day', 'regional_special'],
    };

    final output = <String>{normalizedTag};
    final aliases = aliasMap[normalizedTag];
    if (aliases != null) {
      output.addAll(aliases.map(_normalizeTag));
    }
    return output;
  }

  void _addNormalizedSourceTags(Set<String> tags, String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final normalized = _normalizeTag(trimmed);
    if (normalized.isNotEmpty) {
      tags.addAll(_expandCategoryAliases(normalized));
    }

    final words = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    for (final word in words) {
      tags.addAll(_expandCategoryAliases(_normalizeTag(word)));
    }

    if (words.length >= 2) {
      for (var i = 0; i < words.length - 1; i++) {
        tags.addAll(
          _expandCategoryAliases(_normalizeTag('${words[i]} ${words[i + 1]}')),
        );
      }
    }
  }

  List<String> _inferTemplateCategoryTags({
    required List<String> seedTags,
    required List<String?> sources,
  }) {
    final tags = <String>{...seedTags.map(_normalizeTag)};
    final cleanSources = sources
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    for (final source in cleanSources) {
      _addNormalizedSourceTags(tags, source);
    }
    final normalized = cleanSources
        .map((value) => value.toLowerCase())
        .join(' ');

    void add(String tag) => tags.add(_normalizeTag(tag));

    if (normalized.contains('birthday')) {
      add('birthdays');
      add('celebration');
    }
    if (normalized.contains('morning')) {
      add('good_morning');
    }
    if (normalized.contains('afternoon')) {
      add('good_afternoon');
    }
    if (normalized.contains('night')) {
      add('good_night');
    }
    if (normalized.contains('festival') ||
        normalized.contains('ekadasi') ||
        normalized.contains('devotional')) {
      add('festival');
      add('devotional');
      add('both_telugu_states');
    }
    if (normalized.contains('political')) {
      add('political');
      add('jayanthi');
      add('vardhanthi');
      add('regional_special');
      add('important_day');
    }
    if (normalized.contains('poster') || normalized.contains('flyer')) {
      add('today_special');
    }
    if (normalized.contains('telangana')) {
      add('telangana');
    }
    if (normalized.contains('andhra')) {
      add('andhra_pradesh');
    }
    if (tags.isEmpty) {
      add('today_special');
    }
    return tags.toList(growable: false);
  }

  void _showWebEditorUnavailableMessage() {
    if (!mounted) {
      return;
    }
    final strings = context.strings;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            strings.localized(
              telugu:
                  'వెబ్‌లో editor అందుబాటులో లేదు. పోస్టర్ create చేయాలంటే mobile app ఉపయోగించండి.',
              english:
                  'Editor is not available on web. Use the mobile app to create posters.',
              hindi:
                  'वेब पर editor उपलब्ध नहीं है। पोस्टर बनाने के लिए mobile app उपयोग करें।',
              tamil:
                  'வெபில் editor கிடைக்காது. Poster create செய்ய mobile app பயன்படுத்துங்கள்.',
              kannada:
                  'ವೆಬ್‌ನಲ್ಲಿ editor ಲಭ್ಯವಿಲ್ಲ. Poster create ಮಾಡಲು mobile app ಬಳಸಿ.',
              malayalam:
                  'വെബിൽ editor ലഭ്യമല്ല. Poster create ചെയ്യാൻ mobile app ഉപയോഗിക്കുക.',
            ),
          ),
        ),
      );
  }

  void _onCreateTap() {
    if (kIsWeb) {
      _showWebEditorUnavailableMessage();
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.pageSetup);
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  Future<void> _loadHomeBanners() async {
    final cached = await _appHomeBannerService.fetchBannersFromCache();
    if (mounted && cached.isNotEmpty) {
      setState(() => _homeBanners = cached);
      _warmBannerImages(cached);
    }

    final remote = await _appHomeBannerService.fetchBanners();
    if (!mounted) {
      return;
    }
    setState(() => _homeBanners = remote);
    _warmBannerImages(remote);
  }

  Future<void> _loadApprovedCreatorTemplates() async {
    if (mounted) {
      setState(() => _templatesLoading = true);
    }
    final cached = await _approvedCreatorTemplateService
        .fetchApprovedTemplatesFromCache(maxItems: 80);
    if (mounted && cached.isNotEmpty) {
      final mapped = cached
          .map(_mapApprovedCreatorTemplate)
          .toList(growable: false);
      setState(() {
        _remoteApprovedTemplates = mapped;
        _templatesLoading = false;
      });
      _warmTemplateImages(mapped);
    }

    final remote = await _approvedCreatorTemplateService.fetchApprovedTemplates(
      maxItems: 80,
    );
    if (!mounted) {
      return;
    }
    final mapped = remote
        .map(_mapApprovedCreatorTemplate)
        .toList(growable: false);
    setState(() {
      _remoteApprovedTemplates = mapped;
      _templatesLoading = false;
    });
    _warmTemplateImages(mapped);
  }

  _TemplateItem _mapApprovedCreatorTemplate(ApprovedCreatorTemplate template) {
    final creatorId = template.creatorPublicId.trim();
    final displayTitle = creatorId.isNotEmpty ? creatorId : template.title;
    final rawCategoryId = template.categoryId.trim();
    final categoryTags = rawCategoryId.isNotEmpty
        ? <String>[rawCategoryId]
        : _inferTemplateCategoryTags(
            seedTags: const <String>[],
            sources: <String?>[
              template.categoryLabel,
              template.categoryId,
              template.title,
            ],
          );

    return _TemplateItem(
      titleTe: displayTitle,
      titleHi: displayTitle,
      titleEn: displayTitle,
      imageUrl: template.imageUrl,
      mediaType: template.mediaType,
      videoUrl: template.videoUrl,
      categoryTags: categoryTags,
      personalizationConfig: template.personalizationConfig,
    );
  }

  Future<void> _loadViewerPosterProfile() async {
    if (mounted) {
      setState(() => _viewerProfileLoading = true);
    }
    final localProfile = await PosterProfileService.loadLocal();
    if (!mounted) {
      return;
    }
    PosterProfileData resolvedProfile = localProfile;
    final remoteProfile = await PosterProfileService.refreshFromRemote(
      localProfile: localProfile,
    ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    if (!mounted) {
      return;
    }
    if (remoteProfile != null) {
      resolvedProfile = remoteProfile;
    }
    await _warmPosterProfileImage(resolvedProfile);
    if (!mounted) {
      return;
    }
    setState(() {
      _viewerPosterProfile = resolvedProfile;
      _viewerProfileLoading = false;
    });
  }

  Future<void> _warmPosterProfileImage(PosterProfileData profile) async {
    final imageProvider = PosterProfileService.resolveImageProvider(profile);
    if (imageProvider == null || !mounted) {
      return;
    }
    try {
      await precacheImage(imageProvider, context);
    } catch (_) {}
  }

  void _warmTemplateImages(List<_TemplateItem> items) {
    if (!mounted) {
      return;
    }
    final seen = <String>{};
    for (final item in items.take(8)) {
      if (item.isVideo) {
        continue;
      }
      final imageUrl = item.imageUrl?.trim() ?? '';
      if (imageUrl.isEmpty || !seen.add(imageUrl)) {
        continue;
      }
      unawaited(precacheImage(CachedNetworkImageProvider(imageUrl), context));
    }
  }

  void _warmBannerImages(List<AppHomeBanner> banners) {
    if (!mounted) {
      return;
    }
    final seen = <String>{};
    for (final banner in banners.take(4)) {
      final imageUrl = banner.imageUrl.trim();
      if (imageUrl.isEmpty || !seen.add(imageUrl)) {
        continue;
      }
      unawaited(precacheImage(CachedNetworkImageProvider(imageUrl), context));
    }
  }

  Future<void> _refreshHomeFeed() async {
    if (_homeRefreshing) {
      return;
    }
    setState(() {
      _homeRefreshing = true;
      _posterRenderCycle += 1;
      _templatesLoading = true;
      _viewerProfileLoading = true;
    });
    _searchFocusNode.unfocus();
    try {
      await Future.wait<void>(<Future<void>>[
        _loadHomeBanners(),
        _loadApprovedCreatorTemplates(),
        _loadViewerPosterProfile(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _homeRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.currentLanguage;
    final staticCategories = _buildStaticCategories();
    final dynamicCategories = _buildDynamicCategories(DateTime.now(), language);
    final categories = _mergeCategories(staticCategories, dynamicCategories);
    final activeCategorySlug =
        categories.any((chip) => chip.slug == _selectedCategorySlug)
        ? _selectedCategorySlug
        : _allCategorySlug;
    final selectedCategory = categories.firstWhere(
      (chip) => chip.slug == activeCategorySlug,
      orElse: () => _CategoryChipData(
        slug: _allCategorySlug,
        label: context.strings.localized(telugu: 'అన్నీ', english: 'All'),
        matchTags: <String>['all'],
      ),
    );
    final strings = context.strings;
    final List<_TemplateItem> freeTemplates = _remoteApprovedTemplates;
    final templates = freeTemplates
        .where((item) => _matchesTemplate(item, language, selectedCategory))
        .toList(growable: false);
    final hidePosterFeed =
        _templatesLoading || _homeRefreshing || _viewerProfileLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: Column(
        children: <Widget>[
          RepaintBoundary(
            child: _HomeHeader(
              onCreateTap: _onCreateTap,
              onProfileTap: _openProfile,
              viewerPosterProfile: _viewerPosterProfile,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHomeFeed,
              color: const Color(0xFF0F172A),
              child: CustomScrollView(
                key: ValueKey<String>(
                  hidePosterFeed ? 'home-loading-feed' : 'home-loaded-feed',
                ),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                cacheExtent: 1400,
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RepaintBoundary(
                        child: SizedBox(
                          height: 46,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 7),
                            itemBuilder: (_, index) => _CategoryChip(
                              data: categories[index],
                              isSelected:
                                  categories[index].slug == activeCategorySlug,
                              onTap: () {
                                final nextSlug = categories[index].slug;
                                if (nextSlug == activeCategorySlug) {
                                  return;
                                }
                                setState(
                                  () => _selectedCategorySlug = nextSlug,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_homeBanners.isNotEmpty) ...<Widget>[
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: _HomeHeroBanner(banners: _homeBanners),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  if (_homeRefreshing)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                  if (_homeRefreshing)
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (hidePosterFeed)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      sliver: _PosterFeedSkeletonSliver(),
                    )
                  else if (templates.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _HomeFeedState(
                          icon: Icons.collections_outlined,
                          title: strings.localized(
                            telugu: 'ఈ విభాగంలో పోస్టర్లు అందుబాటులో లేవు',
                            english: 'No posters are available in this section',
                            hindi: 'इस सेक्शन में पोस्टर उपलब्ध नहीं हैं',
                            tamil: 'இந்த பகுதியில் போஸ்டர்கள் இல்லை',
                            kannada: 'ಈ ವಿಭಾಗದಲ್ಲಿ ಪೋಸ್ಟರ್‌ಗಳು ಲಭ್ಯವಿಲ್ಲ',
                            malayalam: 'ഈ വിഭാഗത്തിൽ പോസ്റ്ററുകൾ ലഭ്യമല്ല',
                          ),
                          subtitle: strings.localized(
                            telugu:
                                'ఈ కేటగిరీలో ప్రస్తుతం పోస్టర్లు లేవు. రిఫ్రెష్ చేసి మళ్లీ చూడండి.',
                            english:
                                'There are no posters for this category right now. Pull down to refresh and check again.',
                            hindi:
                                'इस कैटेगरी में अभी पोस्टर नहीं हैं। रिफ्रेश करके फिर देखें।',
                            tamil:
                                'இந்த வகையில் இப்போது போஸ்டர்கள் இல்லை. ரிப்ரெஷ் செய்து மீண்டும் பார்க்கவும்.',
                            kannada:
                                'ಈ ವರ್ಗದಲ್ಲಿ ಈಗ ಪೋಸ್ಟರ್‌ಗಳಿಲ್ಲ. ರಿಫ್ರೆಶ್ ಮಾಡಿ ಮತ್ತೆ ನೋಡಿ.',
                            malayalam:
                                'ഈ വിഭാഗത്തിൽ ഇപ്പോൾ പോസ്റ്ററുകൾ ഇല്ല. റിഫ്രെഷ് ചെയ്ത് വീണ്ടും നോക്കൂ.',
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final item = templates[index];
                          return RepaintBoundary(
                            child: _TemplateFeedItem(
                              key: ValueKey<String>(
                                '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${language.name}-${_viewerPosterProfile.identityMode.name}-${_viewerPosterProfile.activeName}-${_viewerPosterProfile.activeWhatsappNumber}-${_viewerPosterProfile.photoPath}-${_viewerPosterProfile.photoUrl}-${_viewerPosterProfile.businessLogoPath}-${_viewerPosterProfile.businessLogoUrl}-$_posterRenderCycle',
                              ),
                              item: item,
                              language: language,
                              viewerPosterProfile: _viewerPosterProfile,
                              posterRenderCycle: _posterRenderCycle,
                            ),
                          );
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onCreateTap,
    required this.onProfileTap,
    required this.viewerPosterProfile,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
  });

  final VoidCallback onCreateTap;
  final VoidCallback onProfileTap;
  final PosterProfileData viewerPosterProfile;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFD81B60),
            Color(0xFFFF6F3C),
            Color(0xFFFFB703),
          ],
          stops: <double>[0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Mana Poster',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                onTap: onProfileTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: _HeaderProfileAvatar(
                    viewerPosterProfile: viewerPosterProfile,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppPublicInfo.appTagline,
            style: const TextStyle(
              color: Color(0xFFFFF4E6),
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: strings.searchTemplates,
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onCreateTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD81B60),
                  minimumSize: const Size(74, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(strings.createLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerSlideData {
  const _BannerSlideData({required this.imageUrl});

  final String imageUrl;
}

class _HomeHeroBanner extends StatefulWidget {
  const _HomeHeroBanner({required this.banners});

  final List<AppHomeBanner> banners;

  @override
  State<_HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<_HomeHeroBanner> {
  static const double _bannerAspectRatio = 1080 / 300;
  late final PageController _pageController = PageController();
  Timer? _autoSwipeTimer;
  int _currentPage = 0;

  List<_BannerSlideData> get _slides => widget.banners
      .map((banner) => _BannerSlideData(imageUrl: banner.imageUrl))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients || _slides.length <= 1) {
        return;
      }
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: _bannerAspectRatio,
      child: SizedBox(
        width: double.infinity,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _slides.length,
          onPageChanged: (index) => _currentPage = index,
          itemBuilder: (context, index) => Image.network(
            _slides[index].imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              return loadingProgress == null
                  ? child
                  : const _ImageLoadingState();
            },
            errorBuilder: (context, error, stackTrace) => _ImageErrorState(
              compact: true,
              title: context.strings.localized(
                telugu: 'బ్యానర్ అందుబాటులో లేదు',
                english: 'Banner unavailable',
              ),
              subtitle: context.strings.localized(
                telugu: 'దయచేసి కొద్దిసేపటి తర్వాత మళ్లీ ప్రయత్నించండి.',
                english: 'Please try again shortly.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderProfileAvatar extends StatelessWidget {
  const _HeaderProfileAvatar({required this.viewerPosterProfile});

  final PosterProfileData viewerPosterProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.2),
        ),
        child: ClipOval(
          child: PosterIdentityVisual(
            profile: viewerPosterProfile,
            fallbackBackground: Colors.white.withValues(alpha: 0.08),
            fallbackIcon: Icons.person_outline_rounded,
            fallbackIconColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _CategoryChipData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = this.data;
    final isSelected = this.isSelected;
    final isAll = data.slug == _HomeScreenState._allCategorySlug;
    const selectedChipColor = Color(0xFF6D28D9);
    const selectedChipBorder = Color(0xFF5B21B6);
    const allChipColor = Color(0xFF25D366);
    const allChipBorder = Color(0xFF1FAE54);
    final chipTint = isAll
        ? allChipColor
        : isSelected
        ? selectedChipColor
        : data.isDynamic
        ? const Color(0xFFFFF4DB)
        : Colors.white;
    final borderColor = isAll
        ? allChipBorder
        : isSelected
        ? selectedChipBorder
        : data.isDynamic
        ? const Color(0xFFF2C66D)
        : const Color(0xFFDCE6F3);
    final textColor = isAll || isSelected
        ? Colors.white
        : data.isDynamic
        ? const Color(0xFF8A5A00)
        : const Color(0xFF334155);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: chipTint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isSelected || isAll
                    ? const Color(0x140F172A)
                    : const Color(0x0A0F172A),
                blurRadius: isSelected || isAll ? 10 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected || isAll
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

String _subscriptionPromptCopyLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'పోస్టర్లు షేర్ లేదా డౌన్‌లోడ్ చేయడానికి సబ్‌స్క్రిప్షన్ యాక్టివ్ చేయాలి.',
    english: 'Activate subscription to share or download posters.',
  );
}

String _subscriptionDialogTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ అవసరం',
    english: 'Subscription Required',
  );
}

String _subscriptionTrialTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '3-day trial plan',
  );
}

String _subscriptionTrialValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay}',
    english:
        '${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days',
  );
}

String _subscriptionMonthlyTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలవారీ ప్లాన్',
    english: 'Monthly plan',
  );
}

String _subscriptionMonthlyValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'తర్వాత నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    english: '${SubscriptionPlanConfig.monthlyPriceDisplay} per month',
  );
}

String _subscriptionRenewalCopyLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజుల ట్రయల్ పూర్తయ్యాక మీరు క్యాన్సిల్ చేయకపోతే నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} ఆటో రీన్యూవల్ అవుతుంది. ${SubscriptionPlanConfig.trialDays} రోజుల లోపు క్యాన్సిల్ చేస్తే నెలవారీ చార్జ్ పడదు. క్యాన్సిల్ చేసినా ప్రస్తుత ప్లాన్ గడువు ముగిసే వరకు బెనిఫిట్స్ ఉపయోగించవచ్చు.',
    english:
        'After the ${SubscriptionPlanConfig.trialDays}-day trial, it auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay}/month unless cancelled. If cancelled within ${SubscriptionPlanConfig.trialDays} days, the monthly charge does not apply. Benefits continue until the current plan expires.',
  );
}

String _subscriptionTermsLabelLocalized(BuildContext context) {
  return context.strings.localized(telugu: 'నిబంధనలు', english: 'Terms');
}

String _subscriptionSkipLabelLocalized(BuildContext context) {
  return context.strings.localized(telugu: 'స్కిప్', english: 'Skip');
}

String _subscriptionButtonLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe',
  );
}

class _TemplateFeedItem extends StatelessWidget {
  _TemplateFeedItem({
    super.key,
    required this.item,
    required this.language,
    required this.viewerPosterProfile,
    required this.posterRenderCycle,
  });

  final _TemplateItem item;
  final AppLanguage language;
  final PosterProfileData viewerPosterProfile;
  final int posterRenderCycle;
  final GlobalKey _posterRepaintKey = GlobalKey();
  final ValueNotifier<bool> _showPosterPhotoNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> _posterReadyNotifier = ValueNotifier<bool>(false);
  static final SubscriptionBackendService _subscriptionBackendService =
      SubscriptionBackendService();
  static final ProPurchaseGateway _subscriptionRestoreGateway =
      InAppPurchaseGateway(
        productId: SubscriptionPlanConfig.primaryMonthlyProductId,
        fallbackProductIds: <String>[
          SubscriptionPlanConfig.primaryMonthlyProductId,
        ],
      );

  static SubscriptionBackendService get subscriptionBackendService =>
      _subscriptionBackendService;

  Future<Uint8List?> _capturePosterBytes() async {
    final binding = WidgetsBinding.instance;
    for (var attempt = 0; attempt < 3; attempt++) {
      await binding.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final boundary =
          _posterRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('capture boundary unavailable on attempt=$attempt');
        continue;
      }
      try {
        final image = await boundary.toImage(pixelRatio: 3);
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data != null) {
            return data.buffer.asUint8List();
          }
        } finally {
          image.dispose();
        }
      } catch (error, stackTrace) {
        debugPrint('capture attempt failed: $error');
        debugPrint('$stackTrace');
        if (attempt == 2) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 32));
      }
    }
    return null;
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    if (Platform.isAndroid &&
        !(await MediaExportService.needsGalleryPermission())) {
      return true;
    }
    final permission = Platform.isAndroid
        ? Permission.storage
        : Permission.photos;
    final photosStatus = await permission.status;
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }
    final requested = await <Permission>[permission].request();
    return requested.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<SubscriptionBackendResult> _verifyPurchaseWithRetry(
    PurchaseVerificationEvidence evidence,
  ) async {
    const delays = <Duration>[
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 6),
    ];

    SubscriptionBackendResult? lastResult;
    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      lastResult = await _subscriptionBackendService.verifyPurchase(
        evidence: evidence,
      );
      if (lastResult.isSuccess) {
        return lastResult;
      }
    }
    return lastResult ??
        const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Subscription verification failed',
        );
  }

  Future<void> _syncPlayStorePurchaseToBackend(
    PurchaseVerificationEvidence evidence,
  ) async {
    final verifyResult = await _verifyPurchaseWithRetry(evidence);
    if (verifyResult.isSuccess) {
      await evidence.completeStorePurchase();
    }
    final refreshed = await _subscriptionBackendService
        .fetchFreshEntitlementWithRetry();
    debugPrint('subscription sync: backendResponse.isPro=${refreshed.isPro}');
  }

  Future<bool> _tryRestoreSubscriptionSilently() async {
    final outcome = await _subscriptionRestoreGateway.restorePurchases();
    final evidence = outcome.evidence;
    final playStorePurchaseFound =
        outcome.result == PurchaseFlowResult.success && evidence != null;
    debugPrint(
      'subscription restore check: playStorePurchaseFound=$playStorePurchaseFound',
    );
    if (playStorePurchaseFound) {
      await _syncPlayStorePurchaseToBackend(evidence);
      final refreshed = await _subscriptionBackendService
          .fetchFreshEntitlementWithRetry();
      debugPrint(
        'subscription restore verify: backendResponse.isPro=${refreshed.isPro}',
      );
      return refreshed.isPro;
    }

    final fallback = await _subscriptionBackendService
        .fetchFreshEntitlementWithRetry();
    debugPrint(
      'subscription restore fallback: backendResponse.isPro=${fallback.isPro}',
    );
    return fallback.isPro;
  }

  bool _hasRecentCachedProFallback({
    required SubscriptionBackendResult? cachedEntitlement,
    required DateTime? cachedEntitlementAt,
  }) {
    if (cachedEntitlement?.isPro != true || cachedEntitlementAt == null) {
      return false;
    }
    const offlineGraceWindow = Duration(hours: 1);
    return DateTime.now().difference(cachedEntitlementAt) <=
        offlineGraceWindow;
  }

  Future<bool> _resolveLatestSubscriptionAccess() async {
    final cachedEntitlement = _subscriptionBackendService.cachedEntitlement;
    final cachedEntitlementAt = _subscriptionBackendService.cachedEntitlementAt;
    final backend = await _subscriptionBackendService.fetchFreshEntitlement();
    final effectiveIsPro = backend.isPro;
    debugPrint(
      'subscription access resolve: backendResponse.isPro=$effectiveIsPro',
    );
    if (effectiveIsPro) {
      return true;
    }
    if (backend.state == SubscriptionBackendState.failed &&
        _hasRecentCachedProFallback(
          cachedEntitlement: cachedEntitlement,
          cachedEntitlementAt: cachedEntitlementAt,
        )) {
      debugPrint('subscription access resolve: using cached Pro fallback');
      return true;
    }

    final restoredSilently = await _tryRestoreSubscriptionSilently();
    if (restoredSilently) {
      return true;
    }

    final refreshed = await _subscriptionBackendService
        .fetchFreshEntitlementWithRetry();
    final refreshedEffectiveIsPro = refreshed.isPro;
    debugPrint(
      'subscription access retry: backendResponse.isPro=$refreshedEffectiveIsPro',
    );
    if (!refreshedEffectiveIsPro &&
        refreshed.state == SubscriptionBackendState.failed &&
        _hasRecentCachedProFallback(
          cachedEntitlement: cachedEntitlement,
          cachedEntitlementAt: cachedEntitlementAt,
        )) {
      debugPrint('subscription access retry: using cached Pro fallback');
      return true;
    }
    return refreshedEffectiveIsPro;
  }

  String _downloadSaveFailureMessage(
    BuildContext context,
    MediaExportResult result,
  ) {
    switch (result.code) {
      case 'permission_denied':
        return context.strings.localized(
          telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
          english: 'Gallery permission was denied.',
        );
      case 'file_missing':
      case 'write_failed':
      case 'open_output_failed':
      case 'media_insert_failed':
      case 'directory_create_failed':
      case 'save_failed':
      case 'platform_exception':
      case 'empty_result':
        return context.strings.localized(
          telugu: 'ఫైల్ సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
          english: 'File save failed. Please try again.',
        );
      default:
        return context.strings.localized(
          telugu: 'డౌన్‌లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
          english: 'Download failed. Please try again.',
        );
    }
  }

  Future<bool> _ensureSubscriptionAccess(BuildContext context) async {
    final hasLatestAccess = await _resolveLatestSubscriptionAccess().timeout(
      SubscriptionPlanConfig.paywallTimeout,
      onTimeout: () async => false,
    );
    if (hasLatestAccess) {
      return true;
    }
    debugPrint(
      'subscription access check: backendResponse.isPro=false',
    );
    if (!context.mounted) {
      return false;
    }
    final openPlan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: _SubscriptionAccessDialog(
            title: _subscriptionDialogTitleLocalized(context),
            message: _subscriptionPromptCopyLocalized(context),
            trialTitle: _subscriptionTrialTitleLocalized(context),
            trialValue: _subscriptionTrialValueLocalized(context),
            monthlyTitle: _subscriptionMonthlyTitleLocalized(context),
            monthlyValue: _subscriptionMonthlyValueLocalized(context),
            renewalCopy: _subscriptionRenewalCopyLocalized(context),
            termsLabel: _subscriptionTermsLabelLocalized(context),
            skipLabel: _subscriptionSkipLabelLocalized(context),
            actionLabel: _subscriptionButtonLabelLocalized(context),
            onTermsTap: () => Navigator.of(dialogContext).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(
                  documentType: LegalDocumentType.termsAndConditions,
                ),
              ),
            ),
            onSkipTap: () => Navigator.of(dialogContext).pop(false),
            onConfirmTap: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    );

    if (openPlan != true || !context.mounted) {
      return false;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SubscriptionPlanScreen(startPurchaseOnOpen: true),
      ),
    );
    if (!context.mounted) {
      return false;
    }
    return _resolveLatestSubscriptionAccess();
  }

  Future<void> _onDownloadTap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final galleryPermissionMessage = context.strings.localized(
      telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
      english: 'Gallery permission was denied.',
    );
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'పోస్టర్ capture కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
    );
    final posterSavedMessage = context.strings.localized(
      telugu: 'పోస్టర్ గ్యాలరీలో సేవ్ అయింది.',
      english: 'Poster saved to gallery.',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'ఫైల్ సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'File save failed. Please try again.',
    );
    final downloadFailedMessage = context.strings.localized(
      telugu: 'డౌన్‌లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'Download failed. Please try again.',
    );
    try {
      final hasAccess = await _ensureSubscriptionAccess(context);
      if (!hasAccess) {
        result = false;
        return;
      }
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        result = false;
        _showSnack(messenger, galleryPermissionMessage);
        return;
      }
      await ScreenSecurityService.disableSecure();
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final bytes = await _capturePosterBytes();
      if (bytes == null) {
        result = false;
        _showSnack(messenger, posterNotReadyMessage);
        return;
      }
      final fileName =
          'mana_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempDirectory = await getTemporaryDirectory();
      final tempPath =
          '${tempDirectory.path}${Platform.pathSeparator}$fileName';
      final tempFile = File(tempPath);
      try {
        await tempFile.writeAsBytes(bytes, flush: true);
      } on FileSystemException catch (error, stackTrace) {
        result = false;
        debugPrint('download temp write failed: $error');
        debugPrint('$stackTrace');
        _showSnack(messenger, fileSaveFailedMessage);
        return;
      }
      debugPrint('download capture bytes=${bytes.length}');
      final saveResult = await MediaExportService.saveImageFileToGalleryDetailed(
        tempFile.path,
        fileName: fileName,
      );
      result = saveResult.success;
      if (result) {
        _showSnack(messenger, posterSavedMessage);
        return;
      }
      debugPrint(
        'download native save failed: code=${saveResult.code}, message=${saveResult.message}',
      );
      if (!context.mounted) {
        return;
      }
      _showSnack(messenger, _downloadSaveFailureMessage(context, saveResult));
    } on FileSystemException catch (error, stackTrace) {
      result = false;
      debugPrint('download file save failed: $error');
      debugPrint('$stackTrace');
      _showSnack(messenger, fileSaveFailedMessage);
    } catch (error, stackTrace) {
      result = false;
      debugPrint('download failed: $error');
      debugPrint('$stackTrace');
      _showSnack(messenger, downloadFailedMessage);
    } finally {
      debugPrint('download result=$result');
      await ScreenSecurityService.enableSecure();
    }
  }

  Future<void> _onShareTap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'పోస్టర్ capture కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
    );
    final shareFailedMessage = context.strings.localized(
      telugu: 'షేర్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'Share failed. Please try again.',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'ఫైల్ సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'File save failed. Please try again.',
    );
    try {
      final hasAccess = await _ensureSubscriptionAccess(context);
      if (!hasAccess) {
        result = false;
        return;
      }
      await ScreenSecurityService.disableSecure();
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final bytes = await _capturePosterBytes();
      if (bytes == null) {
        result = false;
        _showSnack(messenger, posterNotReadyMessage);
        return;
      }
      if (!context.mounted) {
        result = false;
        return;
      }
      debugPrint('share capture bytes=${bytes.length}');
      final tempDirectory = await getTemporaryDirectory();
      final tempPath =
          '${tempDirectory.path}${Platform.pathSeparator}mana_poster_share.png';
      final tempFile = File(tempPath);
      try {
        await tempFile.writeAsBytes(bytes, flush: true);
      } on FileSystemException catch (error, stackTrace) {
        result = false;
        debugPrint('share temp write failed: $error');
        debugPrint('$stackTrace');
        _showSnack(messenger, fileSaveFailedMessage);
        return;
      }
      if (!context.mounted) {
        result = false;
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        tempFile.path,
        text: 'Mana Poster',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      result = true;
    } on MediaShareException catch (error, stackTrace) {
      result = false;
      debugPrint('share media service failed: $error');
      debugPrint('$stackTrace');
      _showSnack(messenger, shareFailedMessage);
    } on FileSystemException catch (error, stackTrace) {
      result = false;
      debugPrint('share file save failed: $error');
      debugPrint('$stackTrace');
      _showSnack(messenger, fileSaveFailedMessage);
    } catch (error, stackTrace) {
      result = false;
      debugPrint('share failed: $error');
      debugPrint('$stackTrace');
      _showSnack(messenger, shareFailedMessage);
    } finally {
      debugPrint('share result=$result');
      await ScreenSecurityService.enableSecure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final personalizationConfig = item.personalizationConfig;
    final canTogglePhoto = personalizationConfig != null && !item.isVideo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ValueListenableBuilder<bool>(
        valueListenable: _posterReadyNotifier,
        builder: (context, isPosterReady, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: _showPosterPhotoNotifier,
                builder: (context, isPhotoVisible, _) {
                  return RepaintBoundary(
                    key: _posterRepaintKey,
                    child: KeyedSubtree(
                      key: ValueKey<String>(
                        '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${item.videoUrl ?? ''}-${item.mediaType}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-$posterRenderCycle',
                      ),
                      child: item.isVideo
                          ? _TemplateVideoPlayer(
                              videoUrl: item.videoUrl!,
                              onReady: () {
                                if (!_posterReadyNotifier.value) {
                                  _posterReadyNotifier.value = true;
                                }
                              },
                            )
                          : personalizationConfig != null
                          ? _CreatorPosterPreview(
                              key: ValueKey<String>(
                                '${item.titleEn}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-$posterRenderCycle',
                              ),
                              imageAssetPath: item.imageAssetPath,
                              imageUrl: item.imageUrl,
                              personalizationConfig: personalizationConfig,
                              viewerPosterProfile: viewerPosterProfile,
                              language: language,
                              showProfilePhoto: isPhotoVisible,
                              posterRenderCycle: posterRenderCycle,
                              onPosterReady: () {
                                if (!_posterReadyNotifier.value) {
                                  _posterReadyNotifier.value = true;
                                }
                              },
                            )
                          : _TemplatePosterImage(
                              imageAssetPath: item.imageAssetPath,
                              imageUrl: item.imageUrl,
                              onFirstFrameReady: () {
                                if (!_posterReadyNotifier.value) {
                                  _posterReadyNotifier.value = true;
                                }
                              },
                            ),
                    ),
                  );
                },
              ),
              if (!isPosterReady)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: _PosterCardMetaLoadingState(),
                )
              else ...<Widget>[
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                if (canTogglePhoto && item.titleEn.trim().isEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  ValueListenableBuilder<bool>(
                    valueListenable: _showPosterPhotoNotifier,
                    builder: (context, isPhotoVisible, _) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              _showPosterPhotoNotifier.value = !isPhotoVisible;
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    isPhotoVisible
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 14,
                                    color: isPhotoVisible
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    strings.localized(
                                      telugu: 'ఫోటో',
                                      english: 'Photo',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isPhotoVisible
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.68,
                                    child: Switch.adaptive(
                                      value: isPhotoVisible,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      activeTrackColor: const Color(0xFF25D366),
                                      activeThumbColor: Colors.white,
                                      onChanged: (bool value) {
                                        _showPosterPhotoNotifier.value = value;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: item.isVideo
                            ? null
                            : () => unawaited(_onShareTap(context)),
                        icon: Image.asset(
                          'assets/branding/whatsapp_icon.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.whatshot_rounded, size: 22),
                        ),
                        label: Text(
                          strings.localized(telugu: 'షేర్', english: 'Share'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    if (canTogglePhoto) ...<Widget>[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _showPosterPhotoNotifier,
                          builder: (context, isPhotoVisible, _) {
                            return OutlinedButton.icon(
                              onPressed: () {
                                _showPosterPhotoNotifier.value =
                                    !isPhotoVisible;
                              },
                              icon: Icon(
                                isPhotoVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 18,
                                color: isPhotoVisible
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B),
                              ),
                              label: Text(
                                strings.localized(
                                  telugu: 'ఫోటో',
                                  english: 'Photo',
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isPhotoVisible
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: BorderSide(
                                  color: isPhotoVisible
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFD8E2F0),
                                ),
                                backgroundColor: isPhotoVisible
                                    ? const Color(0xFFF0FDF4)
                                    : Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: item.isVideo
                            ? null
                            : () => unawaited(_onDownloadTap(context)),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(strings.downloadLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.titleFor(language),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TemplatePosterImage extends StatelessWidget {
  const _TemplatePosterImage({
    required this.imageAssetPath,
    required this.imageUrl,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final VoidCallback? onFirstFrameReady;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pixelRatio = MediaQuery.devicePixelRatioOf(
          context,
        ).clamp(1.0, 3.0);
        final cacheWidth = (width * pixelRatio).round().clamp(360, 1440);

        final imageWidget = imageAssetPath != null
            ? Image.asset(
                imageAssetPath!,
                width: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.low,
                cacheWidth: cacheWidth,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    if (onFirstFrameReady != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onFirstFrameReady!.call();
                      });
                    }
                    return child;
                  }
                  return const _ImageLoadingState();
                },
                errorBuilder: (_, _, _) => _ImageErrorState(
                  title: context.strings.localized(
                    telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                    english: 'Template image unavailable',
                  ),
                  subtitle: context.strings.localized(
                    telugu: 'రిఫ్రెష్ చేయండి లేదా మరో టెంప్లేట్ ప్రయత్నించండి.',
                    english: 'Please refresh or try another template.',
                  ),
                ),
              )
            : Image(
                image: ResizeImage.resizeIfNeeded(
                  cacheWidth,
                  null,
                  CachedNetworkImageProvider(imageUrl ?? ''),
                ),
                width: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.low,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    if (onFirstFrameReady != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onFirstFrameReady!.call();
                      });
                    }
                    return child;
                  }
                  return const _ImageLoadingState();
                },
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      final strings = context.strings;
                      return _ImageErrorState(
                        title: strings.localized(
                          telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                          english: 'Template image unavailable',
                        ),
                        subtitle: strings.localized(
                          telugu:
                              'రిఫ్రెష్ చేయండి లేదా మరో టెంప్లేట్ ప్రయత్నించండి.',
                          english: 'Please refresh or try another template.',
                        ),
                      );
                    },
              );

        return Align(alignment: Alignment.topCenter, child: imageWidget);
      },
    );
  }
}

class _SubscriptionInfoLine extends StatelessWidget {
  const _SubscriptionInfoLine({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionAccessDialog extends StatelessWidget {
  const _SubscriptionAccessDialog({
    required this.title,
    required this.message,
    required this.trialTitle,
    required this.trialValue,
    required this.monthlyTitle,
    required this.monthlyValue,
    required this.renewalCopy,
    required this.termsLabel,
    required this.skipLabel,
    required this.actionLabel,
    required this.onTermsTap,
    required this.onSkipTap,
    required this.onConfirmTap,
  });

  final String title;
  final String message;
  final String trialTitle;
  final String trialValue;
  final String monthlyTitle;
  final String monthlyValue;
  final String renewalCopy;
  final String termsLabel;
  final String skipLabel;
  final String actionLabel;
  final VoidCallback onTermsTap;
  final VoidCallback onSkipTap;
  final VoidCallback onConfirmTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF7C3AED), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SubscriptionInfoLine(
                        title: trialTitle,
                        value: trialValue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SubscriptionInfoLine(
                        title: monthlyTitle,
                        value: monthlyValue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          renewalCopy,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onTermsTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    termsLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onConfirmTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onSkipTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFD6DCE8)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    skipLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class _TemplateVideoPlayer extends StatefulWidget {
  const _TemplateVideoPlayer({required this.videoUrl, this.onReady});

  final String videoUrl;
  final VoidCallback? onReady;

  @override
  State<_TemplateVideoPlayer> createState() => _TemplateVideoPlayerState();
}

class _TemplateVideoPlayerState extends State<_TemplateVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _readyNotified = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _TemplateVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _readyNotified = false;
      _hasError = false;
      unawaited(_disposeController());
      _initialize();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        return;
      }
      if (!_readyNotified) {
        _readyNotified = true;
        widget.onReady?.call();
      }
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_hasError || controller == null) {
      return _ImageErrorState(
        title: context.strings.localized(
          telugu: 'వీడియో అందుబాటులో లేదు',
          english: 'Video unavailable',
        ),
        subtitle: context.strings.localized(
          telugu: 'మళ్ళీ ప్రయత్నించండి.',
          english: 'Please try again.',
        ),
      );
    }
    if (!controller.value.isInitialized) {
      return const _ImageLoadingState();
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            VideoPlayer(controller),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorPosterPreview extends StatefulWidget {
  const _CreatorPosterPreview({
    super.key,
    required this.imageAssetPath,
    required this.imageUrl,
    required this.personalizationConfig,
    required this.viewerPosterProfile,
    required this.language,
    required this.showProfilePhoto,
    required this.posterRenderCycle,
    this.onPosterReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final CreatorPosterPersonalization personalizationConfig;
  final PosterProfileData viewerPosterProfile;
  final AppLanguage language;
  final bool showProfilePhoto;
  final int posterRenderCycle;
  final VoidCallback? onPosterReady;

  @override
  State<_CreatorPosterPreview> createState() => _CreatorPosterPreviewState();
}

class _CreatorPosterPreviewState extends State<_CreatorPosterPreview> {
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');

  static const List<String> _randomPosterNameFonts = <String>[
    'Pragathi',
    'Pridhvi',
    'Brahma',
    'Kranthi',
    'Tejafont',
  ];

  static const List<List<Color>> _posterStripGradients = <List<Color>>[
    <Color>[Color(0xFF071E48), Color(0xFF0057B8)],
    <Color>[Color(0xFF062D1D), Color(0xFF0F9F6E)],
    <Color>[Color(0xFF4A1407), Color(0xFFE76F1E)],
    <Color>[Color(0xFF34115B), Color(0xFF9D4EDD)],
    <Color>[Color(0xFF5A3A00), Color(0xFFFFB703)],
  ];

  bool _basePosterReady = false;

  @override
  void didUpdateWidget(covariant _CreatorPosterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageAssetPath != widget.imageAssetPath ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _basePosterReady = false;
    }
  }

  void _handleBasePosterReady() {
    if (_basePosterReady || !mounted) {
      return;
    }
    setState(() => _basePosterReady = true);
    widget.onPosterReady?.call();
  }

  String _resolvePosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|${widget.personalizationConfig.nameX}'
        '|${widget.personalizationConfig.nameY}'
        '|${widget.personalizationConfig.stripHeight}'
        '|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index = hash.abs() % _randomPosterNameFonts.length;
    return _randomPosterNameFonts[index];
  }

  List<Color> _resolvePosterStripGradient(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|${widget.personalizationConfig.stripHeight}'
        '|$resolvedName';
    var hash = 23;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 41 * hash + codeUnit;
    }
    return _posterStripGradients[hash.abs() % _posterStripGradients.length];
  }

  Color _onStripColor(List<Color> gradient) {
    final averageLuminance =
        gradient.fold<double>(
          0,
          (sum, color) => sum + color.computeLuminance(),
        ) /
        gradient.length;
    return averageLuminance > 0.48 ? const Color(0xFF111827) : Colors.white;
  }

  String? _stripNameFontFamily(String text, String teluguFontFamily) {
    if (_teluguTextPattern.hasMatch(text)) {
      return teluguFontFamily;
    }
    if (_latinTextPattern.hasMatch(text)) {
      return 'League Spartan';
    }
    return null;
  }

  bool _shouldConvertForLegacyTelugu(String text, String? fontFamily) {
    return fontFamily != null &&
        _teluguTextPattern.hasMatch(text) &&
        (_randomPosterNameFonts.contains(fontFamily) ||
            fontFamily == 'Pallavi Medium');
  }

  Widget _legacyAwareText({
    required String text,
    required TextStyle style,
    required String? fontFamily,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.center,
    bool fitToWidth = false,
  }) {
    Widget buildText(String value) {
      final textWidget = Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: style.copyWith(fontFamily: fontFamily),
      );
      if (!fitToWidth) {
        return textWidget;
      }
      return SizedBox(
        width: double.infinity,
        child: FittedBox(fit: BoxFit.scaleDown, child: textWidget),
      );
    }

    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        text.trim().isEmpty) {
      return buildText(text);
    }
    return FutureBuilder<String?>(
      future: TeluguLegacyTextService.convert(text, fontFamily: fontFamily!),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        return buildText(snapshot.data ?? text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBusinessIdentity =
        widget.viewerPosterProfile.identityMode ==
            PosterIdentityMode.business &&
        widget.viewerPosterProfile.activeName.trim().isNotEmpty;
    final hasPersonalIdentity =
        widget.viewerPosterProfile.photoPath.trim().isNotEmpty ||
        widget.viewerPosterProfile.photoUrl.trim().isNotEmpty ||
        widget.viewerPosterProfile.originalPhotoPath.trim().isNotEmpty ||
        widget.viewerPosterProfile.originalPhotoUrl.trim().isNotEmpty;
    final shouldShowIdentityVisual = hasBusinessIdentity || hasPersonalIdentity;
    final resolvedName = widget.viewerPosterProfile.resolvedName(
      language: widget.language,
    );
    final isBusinessProfile =
        widget.viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final resolvedDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.whatsappNumber.trim();
    final resolvedPhone = isBusinessProfile
        ? widget.viewerPosterProfile.activeWhatsappNumber.trim()
        : '';
    final isTeluguName = _teluguTextPattern.hasMatch(resolvedName);
    final displayNameFontFamily = _stripNameFontFamily(
      resolvedName,
      _resolvePosterNameFontFamily(resolvedName),
    );
    final personalNameFontSize = isTeluguName ? 42.0 : 36.0;
    final personalNameBoxHeight = isTeluguName ? 38.0 : 40.0;
    final personalNameLineHeight = isTeluguName ? 0.82 : 0.95;
    final businessNameFontSize = isTeluguName ? 34.0 : 28.0;
    const designationFontFamily = 'Pallavi Medium';
    final stripGradient = _resolvePosterStripGradient(resolvedName);
    final stripTextColor = _onStripColor(stripGradient);
    final mutedStripTextColor = stripTextColor.withValues(alpha: 0.86);
    final showPhoneInStrip = isBusinessProfile && resolvedPhone.isNotEmpty;
    final bottomStripPadding = (widget.personalizationConfig.stripHeight * 0.3)
        .clamp(4.0, 8.0);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              _TemplatePosterImage(
                imageAssetPath: widget.imageAssetPath,
                imageUrl: widget.imageUrl,
                onFirstFrameReady: _handleBasePosterReady,
              ),
              if (_basePosterReady &&
                  widget.showProfilePhoto &&
                  shouldShowIdentityVisual)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final photoScale =
                              widget.personalizationConfig.photoScale / 100;
                          final visualScale = isBusinessProfile
                              ? photoScale * 0.72
                              : photoScale;
                          final maskAspectRatio = _photoMaskAspectRatio(
                            widget.personalizationConfig.photoShape,
                          );
                          final width = constraints.maxWidth * visualScale;
                          final height = width / maskAspectRatio;
                          final left =
                              (constraints.maxWidth *
                                  (widget.personalizationConfig.photoX / 100)) -
                              (width / 2);
                          final top =
                              (constraints.maxHeight *
                                  (widget.personalizationConfig.photoY / 100)) -
                              (height / 2);
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: <Widget>[
                              Positioned(
                                left: left,
                                top: top,
                                width: width,
                                height: height,
                                child: _PhotoShapeFrame(
                                  shape:
                                      widget.personalizationConfig.photoShape,
                                  edgeStyle:
                                      widget.personalizationConfig.edgeStyle,
                                  photoRenderMode: widget
                                      .personalizationConfig
                                      .photoRenderMode,
                                  isBusinessLogo: isBusinessProfile,
                                  child: PosterIdentityVisual(
                                    profile: widget.viewerPosterProfile,
                                    fit:
                                        widget
                                                .personalizationConfig
                                                .photoRenderMode ==
                                            'cutout'
                                        ? BoxFit.contain
                                        : BoxFit.cover,
                                    preferOriginalPersonalPhoto:
                                        widget
                                            .personalizationConfig
                                            .photoRenderMode ==
                                        'original',
                                    allowOriginalFallbackWhenCutoutUnavailable:
                                        widget
                                            .personalizationConfig
                                            .photoRenderMode ==
                                        'original',
                                    textScale:
                                        widget
                                                .viewerPosterProfile
                                                .identityMode ==
                                            PosterIdentityMode.business
                                        ? 0.84
                                        : 1.0,
                                  ),
                                ),
                              ),
                              if (!widget.personalizationConfig.showBottomStrip)
                                Positioned(
                                  left:
                                      constraints.maxWidth *
                                      (widget.personalizationConfig.nameX /
                                          100),
                                  top:
                                      constraints.maxHeight *
                                      (widget.personalizationConfig.nameY /
                                          100),
                                  child: Transform.translate(
                                    offset: const Offset(-80, -16),
                                    child: SizedBox(
                                      width: 160,
                                      child: _legacyAwareText(
                                        text: resolvedName,
                                        fontFamily: displayNameFontFamily,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          shadows: const <Shadow>[
                                            Shadow(
                                              color: Color(0xCC000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                  ),
                ),
            ],
          ),
          if (_basePosterReady && widget.personalizationConfig.showBottomStrip)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: bottomStripPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: stripGradient,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (isBusinessProfile)
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _legacyAwareText(
                                text: resolvedName,
                                fontFamily: displayNameFontFamily,
                                maxLines: 1,
                                textAlign: TextAlign.left,
                                fitToWidth: true,
                                style: TextStyle(
                                  color: stripTextColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: businessNameFontSize,
                                  height: isTeluguName ? 0.98 : 1.0,
                                ),
                              ),
                              if (resolvedDesignation.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 0),
                                _legacyAwareText(
                                  text: resolvedDesignation,
                                  fontFamily: designationFontFamily,
                                  maxLines: 1,
                                  textAlign: TextAlign.left,
                                  fitToWidth: true,
                                  style: TextStyle(
                                    color: mutedStripTextColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 18,
                                    height: 0.98,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showPhoneInStrip) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            width: 2,
                            height: 34,
                            decoration: BoxDecoration(
                              color: mutedStripTextColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 82),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  resolvedPhone,
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: mutedStripTextColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  else ...<Widget>[
                    SizedBox(
                      height: personalNameBoxHeight,
                      child: _legacyAwareText(
                        text: resolvedName,
                        fontFamily: displayNameFontFamily,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        fitToWidth: true,
                        style: TextStyle(
                          color: stripTextColor,
                          fontWeight: FontWeight.w500,
                          fontSize: personalNameFontSize,
                          height: personalNameLineHeight,
                        ),
                      ),
                    ),
                    if (resolvedDesignation.isNotEmpty)
                      SizedBox(
                        height: 18,
                        child: Transform.translate(
                          offset: const Offset(0, -3),
                          child: _legacyAwareText(
                            text: resolvedDesignation,
                            fontFamily: designationFontFamily,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            fitToWidth: true,
                            style: TextStyle(
                              color: mutedStripTextColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                              height: 0.82,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoShapeFrame extends StatelessWidget {
  const _PhotoShapeFrame({
    required this.shape,
    required this.child,
    required this.edgeStyle,
    required this.photoRenderMode,
    required this.isBusinessLogo,
  });

  final String shape;
  final Widget child;
  final String edgeStyle;
  final String photoRenderMode;
  final bool isBusinessLogo;

  bool _isTransparentPhotoShape(String currentShape) {
    return currentShape == 'transparent_bottom_fade' ||
        currentShape == 'transparent_clean' ||
        currentShape == 'transparent_soft_round' ||
        currentShape == 'transparent_sharp_round';
  }

  bool _isTransparentRoundShape(String currentShape) {
    return currentShape == 'transparent_soft_round' ||
        currentShape == 'transparent_sharp_round';
  }

  String _resolvedShape(String currentShape) {
    if (_isTransparentRoundShape(currentShape)) {
      return 'circle';
    }
    return currentShape;
  }

  String _resolvedEdgeStyle(String currentShape, String currentEdgeStyle) {
    if (currentShape == 'transparent_bottom_fade') {
      return 'bottom_fade';
    }
    if (currentShape == 'transparent_soft_round') {
      return 'feather';
    }
    if (currentShape == 'transparent_clean' ||
        currentShape == 'transparent_sharp_round') {
      return 'sharp';
    }
    return currentEdgeStyle;
  }

  String _normalizedEdgeStyle(String currentEdgeStyle) {
    return currentEdgeStyle == 'soft_fade' ? 'bottom_fade' : currentEdgeStyle;
  }

  BoxDecoration _outerDecorationForShape(String currentShape) {
    if (_isTransparentPhotoShape(currentShape)) {
      return const BoxDecoration(color: Colors.transparent);
    }
    switch (currentShape) {
      case 'circle':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF22C55E), Color(0xFF14B8A6)],
          ),
        );
      case 'scallop_circle':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF59E0B), Color(0xFFEF4444)],
          ),
        );
      case 'soft_burst':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFA855F7), Color(0xFFEC4899)],
          ),
        );
      case 'badge':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF2563EB), Color(0xFF06B6D4)],
          ),
        );
      case 'rounded':
      case 'rounded_square':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF8B5CF6), Color(0xFF3B82F6)],
          ),
        );
      case 'custom_frame_fit':
      case 'vertical_rectangle':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0EA5E9), Color(0xFF22C55E)],
          ),
        );
      case 'square':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF97316), Color(0xFFFACC15)],
          ),
        );
      default:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF64748B), Color(0xFF334155)],
          ),
        );
    }
  }

  Alignment _cutoutAlignmentForShape(String currentShape) {
    switch (_resolvedShape(currentShape)) {
      case 'flower':
        return const Alignment(0, 0.24);
      case 'scallop_circle':
      case 'soft_burst':
      case 'sunburst':
        return const Alignment(0, 0.2);
      case 'badge':
        return const Alignment(0, 0.22);
      case 'oval':
        return const Alignment(0, 0.16);
      case 'circle':
      case 'square':
        return const Alignment(0, 0.12);
      default:
        return const Alignment(0, 0.12);
    }
  }

  _ShapeFramePreset _presetForShape(String currentShape) {
    switch (currentShape) {
      case 'circle':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'scallop_circle':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'soft_burst':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'square':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'badge':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'vertical_rectangle':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'rounded':
      case 'rounded_square':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'custom_frame_fit':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      default:
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePhotoRenderMode = isBusinessLogo
        ? 'original'
        : (_isTransparentPhotoShape(shape) ? 'cutout' : photoRenderMode);
    final effectiveEdgeStyle = _resolvedEdgeStyle(
      shape,
      isBusinessLogo ? 'clean' : edgeStyle,
    );
    final normalizedEdgeStyle = _normalizedEdgeStyle(effectiveEdgeStyle);
    final imageAlignment = effectivePhotoRenderMode == 'cutout'
        ? _cutoutAlignmentForShape(shape)
        : Alignment.center;
    final mainImageScale = effectivePhotoRenderMode == 'cutout' ? 1.035 : 1.0;
    final blurImageScale = effectivePhotoRenderMode == 'cutout' ? 1.07 : 1.04;

    Widget buildImageLayer({required double scale, required bool isBlurLayer}) {
      Widget layer = DecoratedBox(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: imageAlignment,
          child: SizedBox.square(dimension: 100, child: child),
        ),
      );
      if (effectivePhotoRenderMode == 'cutout') {
        layer = Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: layer,
        );
      }
      if (normalizedEdgeStyle == 'feather') {
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const RadialGradient(
              center: Alignment.center,
              radius: 0.72,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xE6FFFFFF),
                Color(0x52FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.78, 0.84, 0.94, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
        if (isBlurLayer) {
          layer = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Opacity(opacity: 0.9, child: layer),
          );
        }
      } else if (normalizedEdgeStyle == 'bottom_fade') {
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xFAFFFFFF),
                Color(0xD1FFFFFF),
                Color(0x70FFFFFF),
                Color(0x1FFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.56, 0.68, 0.78, 0.88, 0.94, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
      }
      return layer;
    }

    Widget imageWidget;
    if (effectivePhotoRenderMode == 'cutout' && !isBusinessLogo) {
      if (normalizedEdgeStyle == 'feather') {
        imageWidget = Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: buildImageLayer(scale: blurImageScale, isBlurLayer: true),
            ),
            Positioned.fill(
              child: buildImageLayer(scale: mainImageScale, isBlurLayer: false),
            ),
          ],
        );
      } else {
        imageWidget = buildImageLayer(
          scale: mainImageScale,
          isBlurLayer: false,
        );
      }
    } else {
      imageWidget = buildImageLayer(scale: 1.0, isBlurLayer: false);
    }

    final preset = _presetForShape(shape);
    final photoLayer = Padding(
      padding: preset.photoInset,
      child: _isTransparentRoundShape(shape)
          ? _clipPhotoShape(_resolvedShape(shape), imageWidget)
          : _isTransparentPhotoShape(shape)
          ? ClipRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: imageWidget,
            )
          : _clipPhotoShape(shape, imageWidget),
    );
    final framedChild = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (!_isTransparentPhotoShape(shape))
          _clipPhotoShape(
            shape,
            DecoratedBox(decoration: _outerDecorationForShape(shape)),
          ),
        photoLayer,
      ],
    );

    if (_isTransparentPhotoShape(shape)) {
      return framedChild;
    }

    switch (shape) {
      case 'circle':
        return ClipOval(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'rounded':
      case 'rounded_square':
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'pill':
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'oval':
        return ClipOval(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'hexagon':
        return ClipPath(
          clipper: const _PosterMaskClipper('hexagon'),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'scallop_circle':
      case 'soft_burst':
      case 'diamond':
      case 'flower':
      case 'sunburst':
      case 'star':
      case 'shield':
      case 'arch':
      case 'blob':
      case 'badge':
      case 'heart':
      case 'custom_polygon_fit':
        return ClipPath(
          clipper: _PosterMaskClipper(shape),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'custom_screen_fit':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'custom_board_fit':
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'custom_frame_fit':
      case 'vertical_rectangle':
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: framedChild,
        );
      case 'square':
      default:
        return framedChild;
    }
  }
}

class _ShapeFramePreset {
  const _ShapeFramePreset({required this.photoInset});

  final EdgeInsets photoInset;
}

Widget _clipPhotoShape(String shape, Widget child) {
  switch (shape) {
    case 'circle':
    case 'oval':
      return ClipOval(clipBehavior: Clip.antiAliasWithSaveLayer, child: child);
    case 'rounded':
    case 'rounded_square':
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'pill':
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'custom_screen_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'custom_board_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'custom_frame_fit':
    case 'vertical_rectangle':
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'hexagon':
    case 'scallop_circle':
    case 'soft_burst':
    case 'diamond':
    case 'flower':
    case 'sunburst':
    case 'star':
    case 'shield':
    case 'arch':
    case 'blob':
    case 'badge':
    case 'heart':
    case 'custom_polygon_fit':
      return ClipPath(
        clipper: _PosterMaskClipper(shape),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'square':
    default:
      return ClipRect(clipBehavior: Clip.antiAliasWithSaveLayer, child: child);
  }
}

double _photoMaskAspectRatio(String shape) {
  switch (shape) {
    case 'custom_screen_fit':
      return 16 / 9;
    case 'custom_board_fit':
      return 16 / 7;
    case 'custom_frame_fit':
    case 'oval':
      return 4 / 5;
    case 'custom_polygon_fit':
      return 4 / 3;
    default:
      return 1;
  }
}

Path _buildRadialMaskPath(
  Size size, {
  required int pointCount,
  required double innerRadiusFactor,
  double outerRadiusFactor = 1,
  double rotationRadians = -math.pi / 2,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2;
  final path = Path();
  final totalPoints = pointCount * 2;

  for (int index = 0; index < totalPoints; index += 1) {
    final currentRadius =
        radius * (index.isEven ? outerRadiusFactor : innerRadiusFactor);
    final angle = rotationRadians + ((math.pi * 2) / totalPoints) * index;
    final point = Offset(
      center.dx + math.cos(angle) * currentRadius,
      center.dy + math.sin(angle) * currentRadius,
    );
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }

  path.close();
  return path;
}

Path _buildSmoothRadialMaskPath(
  Size size, {
  required int pointCount,
  required double innerRadiusFactor,
  double outerRadiusFactor = 1,
  double rotationRadians = -math.pi / 2,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2;
  final vertices = <Offset>[];
  final totalPoints = pointCount * 2;

  for (int index = 0; index < totalPoints; index += 1) {
    final currentRadius =
        radius * (index.isEven ? outerRadiusFactor : innerRadiusFactor);
    final angle = rotationRadians + ((math.pi * 2) / totalPoints) * index;
    vertices.add(
      Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      ),
    );
  }

  Offset midpoint(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  final path = Path();
  final start = midpoint(vertices.last, vertices.first);
  path.moveTo(start.dx, start.dy);

  for (int index = 0; index < vertices.length; index += 1) {
    final current = vertices[index];
    final next = vertices[(index + 1) % vertices.length];
    final end = midpoint(current, next);
    path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
  }

  path.close();
  return path;
}

class _PosterMaskClipper extends CustomClipper<Path> {
  const _PosterMaskClipper(this.shape);

  final String shape;

  @override
  Path getClip(Size size) {
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);
    switch (shape) {
      case 'scallop_circle':
        return _buildSmoothRadialMaskPath(
          size,
          pointCount: 16,
          innerRadiusFactor: 0.9,
        );
      case 'soft_burst':
        return _buildRadialMaskPath(
          size,
          pointCount: 44,
          innerRadiusFactor: 0.95,
        );
      case 'hexagon':
        return Path()
          ..moveTo(size.width * 0.25, size.height * 0.06)
          ..lineTo(size.width * 0.75, size.height * 0.06)
          ..lineTo(size.width, size.height * 0.5)
          ..lineTo(size.width * 0.75, size.height * 0.94)
          ..lineTo(size.width * 0.25, size.height * 0.94)
          ..lineTo(0, size.height * 0.5)
          ..close();
      case 'diamond':
        return Path()
          ..moveTo(size.width * 0.5, 0)
          ..lineTo(size.width, size.height * 0.5)
          ..lineTo(size.width * 0.5, size.height)
          ..lineTo(0, size.height * 0.5)
          ..close();
      case 'star':
        return Path()
          ..moveTo(size.width * 0.5, 0)
          ..lineTo(size.width * 0.61, size.height * 0.34)
          ..lineTo(size.width * 0.98, size.height * 0.35)
          ..lineTo(size.width * 0.68, size.height * 0.56)
          ..lineTo(size.width * 0.79, size.height * 0.91)
          ..lineTo(size.width * 0.5, size.height * 0.7)
          ..lineTo(size.width * 0.21, size.height * 0.91)
          ..lineTo(size.width * 0.32, size.height * 0.56)
          ..lineTo(size.width * 0.02, size.height * 0.35)
          ..lineTo(size.width * 0.39, size.height * 0.34)
          ..close();
      case 'shield':
        return Path()
          ..moveTo(size.width * 0.5, 0)
          ..lineTo(size.width * 0.92, size.height * 0.18)
          ..lineTo(size.width * 0.82, size.height * 0.76)
          ..lineTo(size.width * 0.5, size.height)
          ..lineTo(size.width * 0.18, size.height * 0.76)
          ..lineTo(size.width * 0.08, size.height * 0.18)
          ..close();
      case 'arch':
        return Path()
          ..moveTo(0, size.height)
          ..lineTo(0, size.height * 0.44)
          ..cubicTo(
            0,
            size.height * 0.14,
            size.width * 0.22,
            0,
            size.width * 0.5,
            0,
          )
          ..cubicTo(
            size.width * 0.78,
            0,
            size.width,
            size.height * 0.14,
            size.width,
            size.height * 0.44,
          )
          ..lineTo(size.width, size.height)
          ..close();
      case 'blob':
        return Path()
          ..moveTo(p(0.55, 0.02).dx, p(0.55, 0.02).dy)
          ..cubicTo(
            size.width * 0.82,
            0,
            size.width,
            size.height * 0.2,
            size.width * 0.94,
            size.height * 0.48,
          )
          ..cubicTo(
            size.width * 0.9,
            size.height * 0.78,
            size.width * 0.68,
            size.height,
            size.width * 0.42,
            size.height * 0.95,
          )
          ..cubicTo(
            size.width * 0.14,
            size.height * 0.9,
            0,
            size.height * 0.68,
            size.width * 0.06,
            size.height * 0.38,
          )
          ..cubicTo(
            size.width * 0.12,
            size.height * 0.1,
            size.width * 0.3,
            size.height * 0.03,
            size.width * 0.55,
            size.height * 0.02,
          )
          ..close();
      case 'flower':
        return _buildSmoothRadialMaskPath(
          size,
          pointCount: 8,
          innerRadiusFactor: 0.74,
        );
      case 'badge':
        return _buildSmoothRadialMaskPath(
          size,
          pointCount: 12,
          innerRadiusFactor: 0.86,
        );
      case 'heart':
        return Path()
          ..moveTo(size.width * 0.5, size.height * 0.92)
          ..cubicTo(
            size.width * 0.18,
            size.height * 0.68,
            0,
            size.height * 0.48,
            size.width * 0.08,
            size.height * 0.25,
          )
          ..cubicTo(
            size.width * 0.16,
            size.height * 0.02,
            size.width * 0.4,
            size.height * 0.08,
            size.width * 0.5,
            size.height * 0.25,
          )
          ..cubicTo(
            size.width * 0.6,
            size.height * 0.08,
            size.width * 0.84,
            size.height * 0.02,
            size.width * 0.92,
            size.height * 0.25,
          )
          ..cubicTo(
            size.width,
            size.height * 0.48,
            size.width * 0.82,
            size.height * 0.68,
            size.width * 0.5,
            size.height * 0.92,
          )
          ..close();
      case 'sunburst':
        return _buildRadialMaskPath(
          size,
          pointCount: 20,
          innerRadiusFactor: 0.56,
        );
      case 'custom_polygon_fit':
        return Path()
          ..moveTo(size.width * 0.07, size.height * 0.1)
          ..lineTo(size.width * 0.95, 0)
          ..lineTo(size.width * 0.88, size.height)
          ..lineTo(0, size.height * 0.88)
          ..close();
      default:
        return Path()..addRect(Offset.zero & size);
    }
  }

  @override
  bool shouldReclip(covariant _PosterMaskClipper oldClipper) =>
      oldClipper.shape != shape;
}

class _HomeFeedState extends StatelessWidget {
  const _HomeFeedState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterFeedSkeletonSliver extends StatelessWidget {
  const _PosterFeedSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _PosterSkeletonCard(),
      ),
    );
  }
}

class _PosterSkeletonCard extends StatelessWidget {
  const _PosterSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            _SkeletonBox(height: 220, radius: 18),
            SizedBox(height: 12),
            _SkeletonBox(width: 120, height: 12),
            SizedBox(height: 10),
            _SkeletonBox(height: 54, radius: 14),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: _SkeletonBox(height: 44, radius: 14)),
                SizedBox(width: 10),
                Expanded(child: _SkeletonBox(height: 44, radius: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterCardMetaLoadingState extends StatelessWidget {
  const _PosterCardMetaLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        _SkeletonBox(width: 110, height: 12, radius: 999),
        SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(child: _SkeletonBox(height: 44, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 44, radius: 14)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.55, end: 0.95),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      onEnd: () {},
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFE8EEF5), Color(0xFFF3F6FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}

class _ImageLoadingState extends StatelessWidget {
  const _ImageLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3F8),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }
}

class _ImageErrorState extends StatelessWidget {
  const _ImageErrorState({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 20,
        vertical: compact ? 10 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.image_not_supported_outlined,
            color: const Color(0xFF94A3B8),
            size: compact ? 22 : 28,
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12.5 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              height: 1.35,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
