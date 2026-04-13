// ignore_for_file: unused_element_parameter

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/image_editor/screens/page_setup_screen.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/screens/profile_screen.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';
import 'package:mana_poster/features/prehome/services/app_home_banner_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/premium_template_access_service.dart';
import 'package:mana_poster/features/prehome/services/template_entitlement_backend_service.dart';
import 'package:mana_poster/features/prehome/services/template_purchase_gateway.dart';
import 'package:mana_poster/features/prehome/widgets/poster_identity_visual.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

enum _HomeTab { free, premium }

class _TemplateItem {
  const _TemplateItem({
    required this.titleTe,
    required this.titleHi,
    required this.titleEn,
    this.imageUrl,
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
  final String? imageAssetPath;
  final int? price;
  final String? templateId;
  final String? templateDocumentSource;
  final String? productId;
  final List<String> fallbackProductIds;
  final EditorPageConfig? pageConfig;
  final List<String> categoryTags;
  final CreatorPosterPersonalization? personalizationConfig;

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

class _HomeScreenState extends State<HomeScreen> with AppLanguageStateMixin {
  static const String _allCategorySlug = 'all';
  static const List<String> _staticCategorySlugs = <String>[
    'all',
    'good_night',
    'good_morning',
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

  _HomeTab _selectedTab = _HomeTab.free;
  final DynamicCategoryService _dynamicCategoryService =
      const DynamicCategoryService();
  final AppHomeBannerService _appHomeBannerService =
      const AppHomeBannerService();
  final ApprovedCreatorTemplateService _approvedCreatorTemplateService =
      const ApprovedCreatorTemplateService();
  final PremiumTemplateAccessService _premiumTemplateAccessService =
      const PremiumTemplateAccessService();
  final TemplateEntitlementBackendService _templateEntitlementBackendService =
      TemplateEntitlementBackendService();
  final TemplatePurchaseGateway _templatePurchaseGateway =
      TemplatePurchaseGateway();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategorySlug = _allCategorySlug;
  Set<String> _unlockedPremiumTemplateIds = <String>{};
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

  // ignore: unused_field
  static const List<_TemplateItem> _premiumTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'ప్రీమియమ్ పొలిటికల్ డిజైన్',
      titleHi: 'प्रीमियम पॉलिटिकल डिज़ाइन',
      titleEn: 'Premium Political Design',
      imageUrl:
          'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?w=1200',
      price: 99,
      categoryTags: <String>[
        'political',
        'jayanthi',
        'vardhanthi',
        'important_day',
        'regional_special',
      ],
    ),
    _TemplateItem(
      titleTe: 'ప్రీమియమ్ ఫెస్టివల్ గోల్డ్',
      titleHi: 'प्रीमियम फेस्टिवल गोल्ड',
      titleEn: 'Premium Festival Gold',
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200',
      price: 149,
      categoryTags: <String>[
        'festival',
        'devotional',
        'today_special',
        'both_telugu_states',
      ],
    ),
    _TemplateItem(
      titleTe: 'ప్రీమియమ్ ఈవెంట్ ఫ్లయర్',
      titleHi: 'प्रीमियम इवेंट फ्लायर',
      titleEn: 'Premium Event Flyer',
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200',
      price: 79,
      categoryTags: <String>[
        'important_day',
        'regional_special',
        'jayanthi',
        'event',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadApprovedCreatorTemplates());
    unawaited(_loadHomeBanners());
    unawaited(_loadUnlockedPremiumTemplates());
    unawaited(_syncUnlockedTemplatesFromBackend());
    unawaited(_loadViewerPosterProfile());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        const _CategoryChipData(
          slug: _allCategorySlug,
          label: 'All',
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
      'good_night' => const <String>['good_night', 'night'],
      'good_morning' => const <String>['good_morning', 'morning'],
      'motivational' => const <String>['motivational', 'quotes'],
      'love_quotes' => const <String>['love_quotes', 'quotes', 'celebration'],
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
      'good_night': <String>['good_night', 'night'],
      'motivational': <String>['motivational', 'quotes', 'good_thoughts'],
      'love_quotes': <String>['love_quotes', 'love', 'quotes'],
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PageSetupScreen()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  Future<void> _loadUnlockedPremiumTemplates() async {
    final unlocked = await _premiumTemplateAccessService
        .loadUnlockedTemplateIds();
    if (!mounted) {
      return;
    }
    setState(() => _unlockedPremiumTemplateIds = unlocked);
  }

  Future<void> _loadHomeBanners() async {
    final cached = await _appHomeBannerService.fetchBannersFromCache();
    if (mounted && cached.isNotEmpty) {
      setState(() => _homeBanners = cached);
      _warmBannerImages(cached);
    }

    final remote = await _appHomeBannerService.fetchBanners();
    if (!mounted || remote.isEmpty && _homeBanners.isNotEmpty) {
      return;
    }
    setState(() => _homeBanners = remote);
    _warmBannerImages(remote);
  }

  Future<void> _loadApprovedCreatorTemplates() async {
    final cached = await _approvedCreatorTemplateService
        .fetchApprovedTemplatesFromCache(maxItems: 80);
    if (mounted && cached.isNotEmpty) {
      final mapped = cached
          .map(_mapApprovedCreatorTemplate)
          .toList(growable: false);
      setState(() => _remoteApprovedTemplates = mapped);
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
    setState(() => _remoteApprovedTemplates = mapped);
    _warmTemplateImages(mapped);
  }

  _TemplateItem _mapApprovedCreatorTemplate(ApprovedCreatorTemplate template) {
    final creatorId = template.creatorPublicId.trim();
    final displayTitle = creatorId.isNotEmpty ? creatorId : template.title;
    final categoryTags = _inferTemplateCategoryTags(
      seedTags: <String>[
        'today_special',
        if (template.categoryId.trim().isNotEmpty) template.categoryId.trim(),
      ],
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
      categoryTags: categoryTags,
      personalizationConfig: template.personalizationConfig,
    );
  }

  Future<void> _loadViewerPosterProfile() async {
    final profile = await PosterProfileService.loadLocal();
    if (!mounted) {
      return;
    }
    setState(() => _viewerPosterProfile = profile);
    _warmPosterProfileImage(profile);
    unawaited(_refreshViewerPosterProfileRemote(profile));
  }

  Future<void> _refreshViewerPosterProfileRemote(
    PosterProfileData local,
  ) async {
    final profile = await PosterProfileService.refreshFromRemote(
      localProfile: local,
    );
    if (!mounted || profile == null || profile == _viewerPosterProfile) {
      return;
    }
    setState(() => _viewerPosterProfile = profile);
    _warmPosterProfileImage(profile);
  }

  void _warmPosterProfileImage(PosterProfileData profile) {
    final imageProvider = PosterProfileService.resolveImageProvider(profile);
    if (imageProvider == null || !mounted) {
      return;
    }
    unawaited(precacheImage(imageProvider, context));
  }

  void _warmTemplateImages(List<_TemplateItem> items) {
    if (!mounted) {
      return;
    }
    final seen = <String>{};
    for (final item in items.take(8)) {
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
    setState(() => _homeRefreshing = true);
    _searchFocusNode.unfocus();
    try {
      await Future.wait<void>(<Future<void>>[
        _loadHomeBanners(),
        _loadApprovedCreatorTemplates(),
        _loadUnlockedPremiumTemplates(),
        _syncUnlockedTemplatesFromBackend(),
        _loadViewerPosterProfile(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _homeRefreshing = false);
      }
    }
  }

  Future<void> _syncUnlockedTemplatesFromBackend() async {
    final result = await _templateEntitlementBackendService.fetchEntitlements();
    if (!mounted || !result.isSuccess || result.unlockedTemplateIds.isEmpty) {
      return;
    }
    final unlocked = await _premiumTemplateAccessService.unlockTemplates(
      result.unlockedTemplateIds,
    );
    if (!mounted) {
      return;
    }
    setState(() => _unlockedPremiumTemplateIds = unlocked);
  }

  bool _isTemplateUnlocked(_TemplateItem item) {
    final templateId = item.templateId;
    if (templateId == null || templateId.isEmpty) {
      return false;
    }
    return _unlockedPremiumTemplateIds.contains(templateId);
  }

  Future<void> _openPremiumTemplate(_TemplateItem item) async {
    if (kIsWeb) {
      _showWebEditorUnavailableMessage();
      return;
    }
    final documentAsset = item.templateDocumentSource;
    final pageConfig = item.pageConfig;
    if (documentAsset == null || pageConfig == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageEditorScreen(
          pageConfig: pageConfig,
          templateDocumentSource: documentAsset,
        ),
      ),
    );
  }

  Future<void> _handlePremiumTemplateAction(_TemplateItem item) async {
    if (kIsWeb) {
      _showWebEditorUnavailableMessage();
      return;
    }
    final templateId = item.templateId;
    final productId = item.productId;
    if (templateId == null || templateId.isEmpty) {
      return;
    }

    if (_isTemplateUnlocked(item)) {
      await _openPremiumTemplate(item);
      return;
    }
    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template product id configure cheyyali')),
      );
      return;
    }

    final outcome = await _templatePurchaseGateway.purchaseTemplate(
      productId: productId,
      fallbackProductIds: item.fallbackProductIds,
    );
    if (!mounted) {
      return;
    }
    switch (outcome.result) {
      case PurchaseFlowResult.success:
        final purchasedProductId = outcome.evidence?.productId ?? productId;
        Set<String> unlocked;
        final evidence = outcome.evidence;
        if (evidence != null &&
            _templateEntitlementBackendService.isConfigured) {
          final verifyResult = await _templateEntitlementBackendService
              .verifyPurchase(templateId: templateId, evidence: evidence);
          if (!mounted) {
            return;
          }
          if (verifyResult.isSuccess) {
            unlocked = await _premiumTemplateAccessService.unlockTemplates(
              verifyResult.unlockedTemplateIds.isEmpty
                  ? <String>{templateId}
                  : verifyResult.unlockedTemplateIds,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  verifyResult.message?.isNotEmpty == true
                      ? 'Verification fail: ${verifyResult.message}'
                      : 'Payment verify avvaledu',
                ),
              ),
            );
            return;
          }
        } else {
          unlocked = await _premiumTemplateAccessService
              .unlockTemplateForProduct(
                templateId: templateId,
                productId: purchasedProductId,
              );
        }
        if (!mounted) {
          return;
        }
        setState(() => _unlockedPremiumTemplateIds = unlocked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment success. Edit unlocked.')),
        );
        await _openPremiumTemplate(item);
      case PurchaseFlowResult.cancelled:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment cancel chesaru')));
      case PurchaseFlowResult.billingUnavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Billing service available ledu')),
        );
      case PurchaseFlowResult.productNotFound:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Play Console product dorakaledu')),
        );
      case PurchaseFlowResult.timedOut:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment response timeout ayyindi')),
        );
      case PurchaseFlowResult.failed:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment fail ayyindi')));
      case PurchaseFlowResult.nothingToRestore:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase restore avvaledu')),
        );
    }
  }

  Future<void> _handleRestorePremiumPurchases(
    List<_TemplateItem> premiumTemplates,
  ) async {
    final productToTemplateId = <String, String>{};
    for (final item in premiumTemplates) {
      final templateId = item.templateId;
      final productId = item.productId;
      if (templateId == null ||
          templateId.isEmpty ||
          productId == null ||
          productId.isEmpty) {
        continue;
      }
      productToTemplateId[productId] = templateId;
      for (final fallbackProductId in item.fallbackProductIds) {
        if (fallbackProductId.isNotEmpty) {
          productToTemplateId[fallbackProductId] = templateId;
        }
      }
    }

    if (productToTemplateId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore cheyadaniki products levu')),
      );
      return;
    }

    final restoredProductIds = await _templatePurchaseGateway
        .restoreTemplateProductIds(productToTemplateId.keys.toSet());
    if (!mounted) {
      return;
    }
    if (restoredProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore purchases dorakaledu')),
      );
      return;
    }

    final restoredTemplateIds = restoredProductIds
        .map((productId) => productToTemplateId[productId])
        .whereType<String>()
        .toSet();
    final unlocked = await _premiumTemplateAccessService.unlockTemplates(
      restoredTemplateIds,
    );
    if (!mounted) {
      return;
    }
    setState(() => _unlockedPremiumTemplateIds = unlocked);
    unawaited(_syncUnlockedTemplatesFromBackend());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${restoredTemplateIds.length} premium design(s) restore ayyayi',
        ),
      ),
    );
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
      orElse: () => const _CategoryChipData(
        slug: _allCategorySlug,
        label: 'All',
        matchTags: <String>['all'],
      ),
    );
    final strings = context.strings;
    final isPremiumTab = _selectedTab == _HomeTab.premium;
    final List<_TemplateItem> freeTemplates = _remoteApprovedTemplates;
    final List<_TemplateItem> premiumTemplates = const <_TemplateItem>[];
    final templates = (isPremiumTab ? premiumTemplates : freeTemplates)
        .where((item) => _matchesTemplate(item, language, selectedCategory))
        .toList(growable: false);

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
                          height: 42,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SegmentedButton<_HomeTab>(
                        showSelectedIcon: false,
                        segments: <ButtonSegment<_HomeTab>>[
                          ButtonSegment<_HomeTab>(
                            value: _HomeTab.free,
                            label: Text(strings.freeTab),
                          ),
                          ButtonSegment<_HomeTab>(
                            value: _HomeTab.premium,
                            label: Text(strings.premiumTab),
                          ),
                        ],
                        selected: <_HomeTab>{_selectedTab},
                        style: ButtonStyle(
                          animationDuration: const Duration(milliseconds: 180),
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color?>(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? const Color(0xFF6D28D9)
                                    : Colors.white,
                              ),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color?>(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                          side: const WidgetStatePropertyAll<BorderSide>(
                            BorderSide(color: Color(0xFFD9E2F1)),
                          ),
                          shape: WidgetStatePropertyAll<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          textStyle: const WidgetStatePropertyAll<TextStyle>(
                            TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          padding: const WidgetStatePropertyAll<EdgeInsets>(
                            EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        onSelectionChanged: (value) {
                          final nextTab = value.first;
                          if (nextTab == _selectedTab) {
                            return;
                          }
                          setState(() => _selectedTab = nextTab);
                        },
                      ),
                    ),
                  ),
                  if (isPremiumTab)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _handleRestorePremiumPurchases(
                              premiumTemplates,
                            ),
                            icon: const Icon(Icons.restore_rounded),
                            label: Text(
                              strings.localized(
                                telugu: 'Restore Purchases',
                                english: 'Restore Purchases',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                  if (templates.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _HomeFeedState(
                          icon: isPremiumTab
                              ? Icons.workspace_premium_outlined
                              : Icons.collections_outlined,
                          title: isPremiumTab
                              ? strings.localized(
                                  telugu:
                                      'ప్రస్తుతం premium పోస్టర్లు అందుబాటులో లేవు',
                                  english:
                                      'Premium posters are not available now',
                                )
                              : strings.localized(
                                  telugu: 'ఈ విభాగంలో పోస్టర్లు ఇప్పుడిలేవు',
                                  english:
                                      'No posters are available in this section',
                                ),
                          subtitle: isPremiumTab
                              ? strings.localized(
                                  telugu:
                                      'కొత్త premium posters add అయిన వెంటనే ఇక్కడ కనిపిస్తాయి. తర్వాత మళ్లీ check చేయండి.',
                                  english:
                                      'Check again later after premium posters are added.',
                                )
                              : strings.localized(
                                  telugu:
                                      'ఈ category కి ఇప్పుడే పోస్టర్లు లేవు. Pull down చేసి refresh చేసి మళ్లీ check చేయండి.',
                                  english:
                                      'There are no posters for this category right now. Pull down to refresh and check again.',
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
                                '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-$isPremiumTab-${language.name}-${_viewerPosterProfile.identityMode.name}-${_viewerPosterProfile.activeName}-${_viewerPosterProfile.activeWhatsappNumber}-${_viewerPosterProfile.photoPath}-${_viewerPosterProfile.photoUrl}-${_viewerPosterProfile.businessLogoPath}-${_viewerPosterProfile.businessLogoUrl}',
                              ),
                              item: item,
                              isPremium: isPremiumTab,
                              isUnlocked:
                                  !isPremiumTab || _isTemplateUnlocked(item),
                              language: language,
                              viewerPosterProfile: _viewerPosterProfile,
                              onPrimaryAction: isPremiumTab
                                  ? () => _handlePremiumTemplateAction(item)
                                  : null,
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
            Color(0xFF4C1D95),
            Color(0xFF6D28D9),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mana Poster',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: InkWell(
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
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.homeTagline,
            style: const TextStyle(
              color: Color(0xFFF3E8FF),
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
                  onTapOutside: (_) => searchFocusNode.unfocus(),
                  decoration: InputDecoration(
                    hintText: strings.searchTemplates,
                    hintStyle: const TextStyle(
                      color: Color(0xFF7C6AA9),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF6B5CA3),
                    ),
                    fillColor: Colors.white.withValues(alpha: 0.96),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFE9D5FF),
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onCreateTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5B21B6),
                  minimumSize: const Size(96, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  strings.createLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
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
  List<_BannerSlideData> get _slides {
    return widget.banners
        .map((banner) => _BannerSlideData(imageUrl: banner.imageUrl))
        .toList(growable: false);
  }

  late final PageController _pageController = PageController();
  Timer? _autoSwipeTimer;
  int _currentPage = 0;

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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 360;
        final bannerHeight = compact ? 106.0 : 112.0;

        return SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                PageView.builder(
                  controller: _pageController,
                  padEnds: false,
                  itemCount: _slides.length,
                  onPageChanged: (int index) {
                    if (_currentPage == index) {
                      return;
                    }
                    _currentPage = index;
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final slide = _slides[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image.network(
                          slide.imageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          loadingBuilder:
                              (
                                BuildContext context,
                                Widget child,
                                ImageChunkEvent? loadingProgress,
                              ) {
                                if (loadingProgress == null) {
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
                                  compact: true,
                                  title: strings.localized(
                                    telugu: 'Banner unavailable',
                                    english: 'Banner unavailable',
                                  ),
                                  subtitle: strings.localized(
                                    telugu: 'Please try again shortly.',
                                    english: 'Please try again shortly.',
                                  ),
                                );
                              },
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: <Color>[
                                Color(0x260F172A),
                                Color(0x1A1E293B),
                                Color(0x0A1E293B),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            style: TextStyle(
              fontSize: 12.5,
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

class _TemplateFeedItem extends StatelessWidget {
  _TemplateFeedItem({
    super.key,
    required this.item,
    required this.isPremium,
    required this.isUnlocked,
    required this.language,
    required this.viewerPosterProfile,
    this.onPrimaryAction,
  });

  final _TemplateItem item;
  final bool isPremium;
  final bool isUnlocked;
  final AppLanguage language;
  final PosterProfileData viewerPosterProfile;
  final VoidCallback? onPrimaryAction;
  final GlobalKey _posterRepaintKey = GlobalKey();
  final ValueNotifier<bool> _showPosterPhotoNotifier = ValueNotifier<bool>(
    true,
  );

  Future<Uint8List?> _capturePosterBytes() async {
    RenderRepaintBoundary? boundary =
        _posterRepaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      boundary =
          _posterRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
    }
    if (boundary == null || boundary.debugNeedsPaint) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }
    final requested = await <Permission>[Permission.photos].request();
    return requested.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  bool _isGallerySaveSuccess(dynamic saveResult) {
    if (saveResult is bool) {
      return saveResult;
    }
    if (saveResult is! Map) {
      return false;
    }
    final status = saveResult['isSuccess'] ?? saveResult['success'];
    if (status is bool) {
      return status;
    }
    if (status is num) {
      return status > 0;
    }
    final normalized = status?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onDownloadTap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        _showSnack(messenger, 'Gallery permission ivvandi');
        return;
      }
      final bytes = await _capturePosterBytes();
      if (bytes == null) {
        _showSnack(messenger, 'Poster ready kaaledu, malli try cheyyandi');
        return;
      }
      final fileName =
          'mana_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: fileName,
      );
      if (_isGallerySaveSuccess(result)) {
        _showSnack(messenger, 'Poster gallery lo save ayyindi');
        return;
      }
      final tempDirectory = await getTemporaryDirectory();
      final tempPath =
          '${tempDirectory.path}${Platform.pathSeparator}$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);
      final fallback = await ImageGallerySaverPlus.saveFile(
        tempFile.path,
        name: fileName,
      );
      if (_isGallerySaveSuccess(fallback)) {
        _showSnack(messenger, 'Poster gallery lo save ayyindi');
      } else {
        _showSnack(messenger, 'Download fail ayyindi, malli try cheyyandi');
      }
    } catch (_) {
      _showSnack(messenger, 'Download fail ayyindi, malli try cheyyandi');
    }
  }

  Future<void> _onShareTap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _capturePosterBytes();
      if (bytes == null) {
        _showSnack(messenger, 'Poster ready kaaledu, malli try cheyyandi');
        return;
      }
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}${Platform.pathSeparator}mana_poster_share.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: 'Mana Poster');
    } catch (_) {
      _showSnack(messenger, 'Share fail ayyindi, malli try cheyyandi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final personalizationConfig = item.personalizationConfig;
    final canTogglePhoto = !isPremium && personalizationConfig != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: _showPosterPhotoNotifier,
            builder: (context, isPhotoVisible, _) {
              return RepaintBoundary(
                key: _posterRepaintKey,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}',
                  ),
                  child: !isPremium && personalizationConfig != null
                      ? _CreatorPosterPreview(
                          key: ValueKey<String>(
                            '${item.titleEn}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}',
                          ),
                          imageAssetPath: item.imageAssetPath,
                          imageUrl: item.imageUrl,
                          personalizationConfig: personalizationConfig,
                          viewerPosterProfile: viewerPosterProfile,
                          language: language,
                          showProfilePhoto: isPhotoVisible,
                        )
                      : _TemplatePosterImage(
                          imageAssetPath: item.imageAssetPath,
                          imageUrl: item.imageUrl,
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            item.titleFor(language),
            style: TextStyle(
              fontWeight: isPremium ? FontWeight.w800 : FontWeight.w600,
              fontSize: isPremium ? 15.5 : 13,
              color: isPremium
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF94A3B8),
            ),
          ),
          if (canTogglePhoto) ...<Widget>[
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
                                telugu: 'Photo',
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
          const SizedBox(height: 8),
          if (isPremium)
            Row(
              children: <Widget>[
                if (item.price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD89A)),
                    ),
                    child: Text(
                      '\u20B9${item.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A6700),
                      ),
                    ),
                  ),
                if (item.price != null) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isUnlocked ? 'Edit' : 'Buy ₹${item.price ?? 499}',
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => unawaited(_onShareTap(context)),
                    icon: Image.asset(
                      'assets/branding/whatsapp_icon.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.whatshot_rounded, size: 22),
                    ),
                    label: Text(
                      strings.localized(telugu: 'Share', english: 'Share'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFD8E2F0)),
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
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => unawaited(_onDownloadTap(context)),
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
        ],
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
                    telugu: 'Template image unavailable',
                    english: 'Template image unavailable',
                  ),
                  subtitle: context.strings.localized(
                    telugu: 'Please refresh or try another template.',
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
                          telugu: 'Template image unavailable',
                          english: 'Template image unavailable',
                        ),
                        subtitle: strings.localized(
                          telugu: 'Please refresh or try another template.',
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

class _CreatorPosterPreview extends StatefulWidget {
  const _CreatorPosterPreview({
    super.key,
    required this.imageAssetPath,
    required this.imageUrl,
    required this.personalizationConfig,
    required this.viewerPosterProfile,
    required this.language,
    required this.showProfilePhoto,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final CreatorPosterPersonalization personalizationConfig;
  final PosterProfileData viewerPosterProfile;
  final AppLanguage language;
  final bool showProfilePhoto;

  @override
  State<_CreatorPosterPreview> createState() => _CreatorPosterPreviewState();
}

class _CreatorPosterPreviewState extends State<_CreatorPosterPreview> {
  bool _basePosterReady = false;

  @override
  void didUpdateWidget(covariant _CreatorPosterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageAssetPath != widget.imageAssetPath) {
      _basePosterReady = false;
    }
  }

  void _handleBasePosterReady() {
    if (_basePosterReady || !mounted) {
      return;
    }
    setState(() => _basePosterReady = true);
  }

  bool _containsTelugu(String value) {
    return RegExp(r'[\u0C00-\u0C7F]').hasMatch(value);
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
    final displayNameFontFamily = _containsTelugu(resolvedName)
        ? 'Prabhava'
        : widget.viewerPosterProfile.nameFontFamily;
    final showWhatsapp =
        widget.personalizationConfig.showWhatsapp &&
        widget.viewerPosterProfile.activeWhatsappNumber.trim().isNotEmpty;
    final stripPadding = (widget.personalizationConfig.stripHeight * 0.45)
        .clamp(6.0, 14.0);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
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
                          final size =
                              constraints.maxWidth *
                              (widget.personalizationConfig.photoScale / 100);
                          final left =
                              (constraints.maxWidth *
                                  (widget.personalizationConfig.photoX / 100)) -
                              (size / 2);
                          final top =
                              (constraints.maxHeight *
                                  (widget.personalizationConfig.photoY / 100)) -
                              (size / 2);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned(
                                left: left,
                                top: top,
                                width: size,
                                height: size,
                                child: _PhotoShapeFrame(
                                  shape:
                                      widget.personalizationConfig.photoShape,
                                  edgeStyle:
                                      widget.personalizationConfig.edgeStyle,
                                  photoRenderMode: widget
                                      .personalizationConfig
                                      .photoRenderMode,
                                  child: PosterIdentityVisual(
                                    profile: widget.viewerPosterProfile,
                                    preferOriginalPersonalPhoto:
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
                                      child: Text(
                                        resolvedName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          fontFamily: displayNameFontFamily,
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
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: stripPadding,
              ),
              child: Text(
                resolvedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  fontFamily: displayNameFontFamily,
                ),
              ),
            ),
          if (_basePosterReady && showWhatsapp)
            Container(
              width: double.infinity,
              color: const Color(0xFF25D366),
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: stripPadding - 1,
              ),
              child: Text(
                widget.viewerPosterProfile.activeWhatsappNumber.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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
  });

  final String shape;
  final Widget child;
  final String edgeStyle;
  final String photoRenderMode;

  @override
  Widget build(BuildContext context) {
    final imageAlignment = photoRenderMode == 'cutout'
        ? const Alignment(0, -0.78)
        : Alignment.center;
    final imageScale = photoRenderMode == 'cutout' ? 0.95 : 1.0;

    final shapedImage = DecoratedBox(
      decoration: BoxDecoration(color: Colors.transparent),
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: imageAlignment,
        child: SizedBox.square(dimension: 100 * imageScale, child: child),
      ),
    );
    final imageWidget = edgeStyle == 'soft_fade'
        ? ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white,
                  Colors.white,
                  Color(0xE6FFFFFF),
                  Colors.transparent,
                ],
                stops: <double>[0.0, 0.66, 0.82, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: shapedImage,
          )
        : shapedImage;

    switch (shape) {
      case 'circle':
        return ClipOval(child: imageWidget);
      case 'rounded':
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: imageWidget,
        );
      case 'pill':
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: imageWidget,
        );
      case 'hexagon':
        return ClipPath(clipper: const _HexagonClipper(), child: imageWidget);
      case 'square':
      default:
        return imageWidget;
    }
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.25, size.height * 0.06)
      ..lineTo(size.width * 0.75, size.height * 0.06)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height * 0.94)
      ..lineTo(size.width * 0.25, size.height * 0.94)
      ..lineTo(0, size.height * 0.5)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
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
