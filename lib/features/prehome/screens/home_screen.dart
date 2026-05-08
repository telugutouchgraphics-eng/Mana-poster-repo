// ignore_for_file: unused_element_parameter

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'package:shared_preferences/shared_preferences.dart';

void _homeDebugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

void _homeDebugLogStack(String message, StackTrace stackTrace) {
  if (!kDebugMode) {
    return;
  }
  debugPrint(message);
  debugPrintStack(stackTrace: stackTrace);
}

String _repairLegacyUiText(String value) {
  if (!(value.contains('à°') ||
      value.contains('à¤') ||
      value.contains('à®') ||
      value.contains('à²') ||
      value.contains('à´'))) {
    return value;
  }
  try {
    final decoded = utf8.decode(latin1.encode(value), allowMalformed: true);
    return decoded.trim().isEmpty ? value : decoded;
  } catch (_) {
    return value;
  }
}

class _TemplateItem {
  const _TemplateItem({
    required this.titleTe,
    required this.titleHi,
    required this.titleEn,
    this.imageUrl,
    this.thumbnailUrl,
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
  final String? thumbnailUrl;
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

  String titleFor(AppLanguage language) =>
      _repairLegacyUiText(switch (language) {
        AppLanguage.telugu => titleTe,
        AppLanguage.hindi => titleHi,
        AppLanguage.english ||
        AppLanguage.tamil ||
        AppLanguage.kannada ||
        AppLanguage.malayalam => titleEn,
      });
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

enum _HomePromoCardType { subscribe, renewalReminder, update, rate }

class _HomeFeedPromoCardData {
  const _HomeFeedPromoCardData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  final _HomePromoCardType type;
  final String title;
  final String subtitle;
  final String buttonLabel;
}

class _HomeFeedEntry {
  const _HomeFeedEntry.template(this.template) : promo = null;
  const _HomeFeedEntry.promo(this.promo) : template = null;

  final _TemplateItem? template;
  final _HomeFeedPromoCardData? promo;

  bool get isPromo => promo != null;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AppLanguageStateMixin, RouteAware, WidgetsBindingObserver {
  static const String _allCategorySlug = 'all';
  static const int _templatesPageSize = 5;
  static const int _promoSlidesLimit = 5;
  static const int _templateWarmCount = 4;
  static const String _homeFeedRatedKey = 'home_feed_rate_card_completed_v1';
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
  final ScrollController _posterScrollController = ScrollController();
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
  bool _templatesLoadingMore = false;
  bool _templatesHasMore = true;
  bool _viewerProfileLoading = true;
  bool _hasRatedApp = false;
  String _installedAppVersion = '';
  List<_TemplateItem> _remoteApprovedTemplates = const <_TemplateItem>[];
  List<AppHomeBanner> _homeBanners = const <AppHomeBanner>[];
  QueryDocumentSnapshot<Map<String, dynamic>>? _templatesLastDocument;
  Future<void>? _homeBannersLoadFuture;
  Future<void>? _approvedTemplatesLoadFuture;
  Future<void>? _viewerProfileLoadFuture;

  // ignore: unused_field
  static const List<_TemplateItem> _freeTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'à°¶à±à°­à±‹à°¦à°¯à°‚ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤—à¥à¤¡ à¤®à¥‰à¤°à¥à¤¨à¤¿à¤‚à¤— à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Good Morning Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200',
      categoryTags: <String>['good_morning', 'today_special', 'new'],
    ),
    _TemplateItem(
      titleTe: 'à°¬à°°à±à°¤à±â€Œà°¡à±‡ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤¬à¤°à¥à¤¥à¤¡à¥‡ à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Birthday Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?w=1200',
      categoryTags: <String>['birthdays', 'anniversary', 'celebration'],
    ),
    _TemplateItem(
      titleTe: 'à°­à°•à±à°¤à°¿ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤­à¤•à¥à¤¤à¤¿ à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
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
    _posterScrollController.addListener(_onPosterScroll);
    unawaited(_hidePhoneNavigationButtons());
    unawaited(ScreenSecurityService.enableSecure());
    unawaited(_loadApprovedCreatorTemplates());
    unawaited(_loadHomeBanners());
    unawaited(_loadViewerPosterProfile());
    unawaited(_loadInstalledAppVersion());
    unawaited(_loadPromoCardPreferences());
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
    _posterScrollController
      ..removeListener(_onPosterScroll)
      ..dispose();
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
          label: context.strings.localized(
            telugu: 'à°…à°¨à±à°¨à±€',
            english: 'All',
          ),
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
                  'à°µà±†à°¬à±â€Œà°²à±‹ editor à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°¦à±. à°ªà±‹à°¸à±à°Ÿà°°à± create à°šà±‡à°¯à°¾à°²à°‚à°Ÿà±‡ mobile app à°‰à°ªà°¯à±‹à°—à°¿à°‚à°šà°‚à°¡à°¿.',
              english:
                  'Editor is not available on web. Use the mobile app to create posters.',
              hindi:
                  'à¤µà¥‡à¤¬ à¤ªà¤° editor à¤‰à¤ªà¤²à¤¬à¥à¤§ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¥¤ à¤ªà¥‹à¤¸à¥à¤Ÿà¤° à¤¬à¤¨à¤¾à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ mobile app à¤‰à¤ªà¤¯à¥‹à¤— à¤•à¤°à¥‡à¤‚à¥¤',
              tamil:
                  'à®µà¯†à®ªà®¿à®²à¯ editor à®•à®¿à®Ÿà¯ˆà®•à¯à®•à®¾à®¤à¯. Poster create à®šà¯†à®¯à¯à®¯ mobile app à®ªà®¯à®©à¯à®ªà®Ÿà¯à®¤à¯à®¤à¯à®™à¯à®•à®³à¯.',
              kannada:
                  'à²µà³†à²¬à³â€Œà²¨à²²à³à²²à²¿ editor à²²à²­à³à²¯à²µà²¿à²²à³à²². Poster create à²®à²¾à²¡à²²à³ mobile app à²¬à²³à²¸à²¿.',
              malayalam:
                  'à´µàµ†à´¬à´¿àµ½ editor à´²à´­àµà´¯à´®à´²àµà´². Poster create à´šàµ†à´¯àµà´¯à´¾àµ» mobile app à´‰à´ªà´¯àµ‹à´—à´¿à´•àµà´•àµà´•.',
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
    final inFlight = _homeBannersLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _loadHomeBannersInternal();
    _homeBannersLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_homeBannersLoadFuture, future)) {
        _homeBannersLoadFuture = null;
      }
    }
  }

  Future<void> _loadHomeBannersInternal() async {
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
    final inFlight = _approvedTemplatesLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _loadApprovedCreatorTemplatesInternal();
    _approvedTemplatesLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_approvedTemplatesLoadFuture, future)) {
        _approvedTemplatesLoadFuture = null;
      }
    }
  }

  Future<void> _loadApprovedCreatorTemplatesInternal() async {
    if (mounted) {
      setState(() {
        _templatesLoading = true;
        _templatesLoadingMore = false;
        _templatesHasMore = true;
        _templatesLastDocument = null;
      });
    }
    final cachedPage = await _approvedCreatorTemplateService
        .fetchApprovedTemplatesPageFromCache(pageSize: _templatesPageSize);
    if (mounted && cachedPage.templates.isNotEmpty) {
      final mapped = cachedPage.templates
          .map(_mapApprovedCreatorTemplate)
          .toList(growable: false);
      setState(() {
        _remoteApprovedTemplates = mapped;
        _templatesLoading = false;
        _templatesHasMore = cachedPage.hasMore;
        _templatesLastDocument = cachedPage.lastDocument;
      });
      _warmTemplateImages(mapped);
    }

    final remotePage = await _approvedCreatorTemplateService
        .fetchApprovedTemplatesPage(pageSize: _templatesPageSize);
    if (!mounted) {
      return;
    }
    final mapped = remotePage.templates
        .map(_mapApprovedCreatorTemplate)
        .toList(growable: false);
    setState(() {
      _remoteApprovedTemplates = mapped;
      _templatesLoading = false;
      _templatesHasMore = remotePage.hasMore;
      _templatesLastDocument = remotePage.lastDocument;
    });
    _warmTemplateImages(mapped);
  }

  Future<void> _loadMoreApprovedCreatorTemplates() async {
    if (_templatesLoading ||
        _templatesLoadingMore ||
        !_templatesHasMore ||
        _templatesLastDocument == null) {
      return;
    }
    setState(() => _templatesLoadingMore = true);
    final page = await _approvedCreatorTemplateService
        .fetchApprovedTemplatesPage(
          pageSize: _templatesPageSize,
          startAfterDocument: _templatesLastDocument,
        );
    if (!mounted) {
      return;
    }
    final mapped = page.templates
        .map(_mapApprovedCreatorTemplate)
        .toList(growable: false);
    final existingIds = _remoteApprovedTemplates
        .map(
          (item) => item.imageUrl ?? '${item.titleEn}-${item.videoUrl ?? ''}',
        )
        .toSet();
    final fresh = mapped
        .where((item) {
          final key = item.imageUrl ?? '${item.titleEn}-${item.videoUrl ?? ''}';
          return !existingIds.contains(key);
        })
        .toList(growable: false);
    setState(() {
      _remoteApprovedTemplates = <_TemplateItem>[
        ..._remoteApprovedTemplates,
        ...fresh,
      ];
      _templatesLoadingMore = false;
      _templatesHasMore = page.hasMore;
      _templatesLastDocument = page.lastDocument;
    });
    _warmTemplateImages(fresh);
  }

  void _onPosterScroll() {
    if (!_posterScrollController.hasClients) {
      return;
    }
    final position = _posterScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      unawaited(_loadMoreApprovedCreatorTemplates());
    }
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
      thumbnailUrl: template.thumbnailUrl,
      mediaType: template.mediaType,
      videoUrl: template.videoUrl,
      categoryTags: categoryTags,
      personalizationConfig: template.personalizationConfig,
    );
  }

  Future<void> _loadViewerPosterProfile() async {
    final inFlight = _viewerProfileLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _loadViewerPosterProfileInternal();
    _viewerProfileLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_viewerProfileLoadFuture, future)) {
        _viewerProfileLoadFuture = null;
      }
    }
  }

  Future<void> _loadViewerPosterProfileInternal() async {
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
    for (final item in items.take(_templateWarmCount)) {
      if (item.isVideo) {
        continue;
      }
      final thumbnailUrl = item.thumbnailUrl?.trim() ?? '';
      final imageUrl = item.imageUrl?.trim() ?? '';
      final warmUrl = thumbnailUrl.isNotEmpty ? thumbnailUrl : imageUrl;
      if (warmUrl.isEmpty || !seen.add(warmUrl)) {
        continue;
      }
      unawaited(precacheImage(CachedNetworkImageProvider(warmUrl), context));
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

  Future<void> _loadInstalledAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() => _installedAppVersion = packageInfo.version.trim());
    } catch (_) {}
  }

  Future<void> _loadPromoCardPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRated = prefs.getBool(_homeFeedRatedKey) ?? false;
      if (!mounted) {
        _hasRatedApp = hasRated;
        return;
      }
      setState(() => _hasRatedApp = hasRated);
    } catch (_) {}
  }

  bool _isUpdateAvailable() {
    final latest = AppPublicInfo.latestPlayStoreVersion.trim();
    final installed = _installedAppVersion.trim();
    if (latest.isEmpty || installed.isEmpty || latest == installed) {
      return false;
    }
    List<int> parseVersion(String value) => value
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
    final currentParts = parseVersion(installed);
    final latestParts = parseVersion(latest);
    final maxLength = math.max(currentParts.length, latestParts.length);
    for (var index = 0; index < maxLength; index++) {
      final current = index < currentParts.length ? currentParts[index] : 0;
      final next = index < latestParts.length ? latestParts[index] : 0;
      if (next > current) {
        return true;
      }
      if (next < current) {
        return false;
      }
    }
    return false;
  }

  bool _shouldShowRenewalReminder(SubscriptionBackendResult? entitlement) {
    if (entitlement == null || !entitlement.isPro || !entitlement.isActive) {
      return false;
    }
    final expiryTime = entitlement.expiryTime;
    if (expiryTime == null) {
      return false;
    }
    final remaining = expiryTime.difference(DateTime.now());
    return !remaining.isNegative && remaining <= const Duration(days: 3);
  }

  Future<void> _markAppRated() async {
    if (_hasRatedApp) {
      return;
    }
    setState(() => _hasRatedApp = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_homeFeedRatedKey, true);
    } catch (_) {}
  }

  List<_HomeFeedPromoCardData> _buildPromoCards({
    required AppStrings strings,
    required SubscriptionBackendResult? entitlement,
  }) {
    final isPro = entitlement?.hasAccess ?? false;
    final cards = <_HomeFeedPromoCardData>[
      if (!isPro)
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.subscribe,
          title: strings.localized(
            telugu: 'మరిన్ని పోస్టర్ల కోసం మెంబర్‌షిప్ తీసుకోండి',
            english: 'Unlock more posters with membership',
          ),
          subtitle: strings.localized(
            telugu:
                'ప్రీమియం పోస్టర్లు, వేగమైన షేర్, డౌన్‌లోడ్ మరియు అదనపు సౌకర్యాలకు సబ్‌స్క్రైబ్ చేయండి.',
            english:
                'Subscribe for premium posters, faster sharing, downloads, and extra features.',
          ),
          buttonLabel: strings.localized(
            telugu: 'Purchase Membership',
            english: 'Purchase Membership',
          ),
        ),
      if (_shouldShowRenewalReminder(entitlement))
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.renewalReminder,
          title: strings.localized(
            telugu: 'మీ మెంబర్‌షిప్ త్వరలో ముగియబోతోంది',
            english: 'Your membership is expiring soon',
          ),
          subtitle: strings.localized(
            telugu:
                'ఇంకా 3 రోజులలోపు ప్లాన్ ముగుస్తుంది. అంతరాయం లేకుండా పోస్టర్లు వాడాలంటే ఇప్పుడే renew చేయండి.',
            english:
                'Your plan ends within the next 3 days. Renew now to keep using posters without interruption.',
          ),
          buttonLabel: strings.localized(
            telugu: 'Renew Membership',
            english: 'Renew Membership',
          ),
        ),
      if (isPro && _isUpdateAvailable())
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.update,
          title: strings.localized(
            telugu: 'కొత్త యాప్ అప్‌డేట్ సిద్ధంగా ఉంది',
            english: 'A new app update is ready',
          ),
          subtitle: strings.localized(
            telugu:
                'Play Store లో కొత్త version అందుబాటులో ఉంది. తాజా మెరుగుదలల కోసం ఇప్పుడు అప్‌డేట్ చేయండి.',
            english:
                'A newer version is available on the Play Store. Update now for the latest improvements.',
          ),
          buttonLabel: strings.localized(
            telugu: 'Update App',
            english: 'Update App',
          ),
        ),
      if (!_hasRatedApp)
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.rate,
          title: strings.localized(
            telugu: 'Mana Poster Ai కి రేటింగ్ ఇవ్వండి',
            english: 'Rate Mana Poster Ai',
          ),
          subtitle: strings.localized(
            telugu:
                'మీ rating మరియు review వల్ల మరింత మందికి యాప్ గురించి తెలుస్తుంది.',
            english:
                'Your rating and review help more people discover the app.',
          ),
          buttonLabel: strings.localized(
            telugu: 'Rate App',
            english: 'Rate App',
          ),
        ),
    ];
    final seed = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    if (cards.length > 1) {
      cards.sort(
        (a, b) => ((a.type.index + seed) % 11) - ((b.type.index + seed) % 11),
      );
    }
    return cards;
  }

  List<_HomeFeedEntry> _buildFeedEntries({
    required List<_TemplateItem> templates,
    required List<_HomeFeedPromoCardData> promoCards,
  }) {
    if (templates.isEmpty) {
      return const <_HomeFeedEntry>[];
    }
    if (promoCards.isEmpty) {
      return templates.map(_HomeFeedEntry.template).toList(growable: false);
    }
    const insertAfterEvery = 10;
    final entries = <_HomeFeedEntry>[];
    var promoIndex = 0;
    for (var index = 0; index < templates.length; index++) {
      entries.add(_HomeFeedEntry.template(templates[index]));
      final shouldInsert = (index + 1) % insertAfterEvery == 0;
      if (shouldInsert) {
        entries.add(_HomeFeedEntry.promo(promoCards[promoIndex]));
        promoIndex = (promoIndex + 1) % promoCards.length;
      }
    }
    return entries;
  }

  Future<bool> _openPlayStore() async {
    final uri = Uri.parse(AppPublicInfo.playStoreUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) {
      return opened;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Play Store తెరవలేకపోయాం. ఇంకోసారి ప్రయత్నించండి.',
              english: 'Could not open the Play Store. Please try again.',
            ),
          ),
        ),
      );
    return false;
  }

  Future<void> _openManageSubscription() async {
    final uri = Uri.parse(SubscriptionPlanConfig.manageSubscriptionUrl());
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SubscriptionPlanScreen()),
    );
  }

  Future<void> _handlePromoTap(_HomePromoCardType type) async {
    switch (type) {
      case _HomePromoCardType.subscribe:
        if (!mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const SubscriptionPlanScreen(startPurchaseOnOpen: true),
          ),
        );
        return;
      case _HomePromoCardType.renewalReminder:
        await _openManageSubscription();
        return;
      case _HomePromoCardType.update:
        await _openPlayStore();
        return;
      case _HomePromoCardType.rate:
        final opened = await _openPlayStore();
        if (opened) {
          await _markAppRated();
        }
        return;
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
        label: context.strings.localized(
          telugu: 'à°…à°¨à±à°¨à±€',
          english: 'All',
        ),
        matchTags: <String>['all'],
      ),
    );
    final strings = context.strings;
    final List<_TemplateItem> freeTemplates = _remoteApprovedTemplates;
    final templates = freeTemplates
        .where((item) => _matchesTemplate(item, language, selectedCategory))
        .toList(growable: false);
    final effectiveEntitlement =
        SubscriptionBackendService.entitlementNotifier.value ??
        _TemplateFeedItem.subscriptionBackendService.cachedEntitlement;
    final promoCards = _buildPromoCards(
      strings: strings,
      entitlement: effectiveEntitlement,
    );
    final promoSlides = templates
        .take(_promoSlidesLimit)
        .toList(growable: false);
    final feedEntries = _buildFeedEntries(
      templates: templates,
      promoCards: promoCards,
    );
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
                controller: _posterScrollController,
                key: ValueKey<String>(
                  hidePosterFeed ? 'home-loading-feed' : 'home-loaded-feed',
                ),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                cacheExtent: 120,
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
                  ] else
                    ValueListenableBuilder<SubscriptionBackendResult?>(
                      valueListenable:
                          SubscriptionBackendService.entitlementNotifier,
                      builder: (context, entitlement, _) {
                        final effectiveEntitlement =
                            entitlement ??
                            _TemplateFeedItem
                                .subscriptionBackendService
                                .cachedEntitlement;
                        final shouldShowAdFallback =
                            AppPublicInfo.hasHomeBannerAdUnitId &&
                            !(effectiveEntitlement?.hasAccess ?? false);
                        if (!shouldShowAdFallback) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }
                        return const SliverToBoxAdapter(
                          child: Column(
                            children: <Widget>[
                              SizedBox(height: 14),
                              RepaintBoundary(child: _HomeBannerAdFallback()),
                              SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
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
                            telugu:
                                'à°ˆ à°µà°¿à°­à°¾à°—à°‚à°²à±‹ à°ªà±‹à°¸à±à°Ÿà°°à±à°²à± à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°µà±',
                            english: 'No posters are available in this section',
                            hindi:
                                'à¤‡à¤¸ à¤¸à¥‡à¤•à¥à¤¶à¤¨ à¤®à¥‡à¤‚ à¤ªà¥‹à¤¸à¥à¤Ÿà¤° à¤‰à¤ªà¤²à¤¬à¥à¤§ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¤‚',
                            tamil:
                                'à®‡à®¨à¯à®¤ à®ªà®•à¯à®¤à®¿à®¯à®¿à®²à¯ à®ªà¯‹à®¸à¯à®Ÿà®°à¯à®•à®³à¯ à®‡à®²à¯à®²à¯ˆ',
                            kannada:
                                'à²ˆ à²µà²¿à²­à²¾à²—à²¦à²²à³à²²à²¿ à²ªà³‹à²¸à³à²Ÿà²°à³â€Œà²—à²³à³ à²²à²­à³à²¯à²µà²¿à²²à³à²²',
                            malayalam:
                                'à´ˆ à´µà´¿à´­à´¾à´—à´¤àµà´¤à´¿àµ½ à´ªàµ‹à´¸àµà´±àµà´±à´±àµà´•àµ¾ à´²à´­àµà´¯à´®à´²àµà´²',
                          ),
                          subtitle: strings.localized(
                            telugu:
                                'à°ˆ à°•à±‡à°Ÿà°—à°¿à°°à±€à°²à±‹ à°ªà±à°°à°¸à±à°¤à±à°¤à°‚ à°ªà±‹à°¸à±à°Ÿà°°à±à°²à± à°²à±‡à°µà±. à°°à°¿à°«à±à°°à±†à°·à± à°šà±‡à°¸à°¿ à°®à°³à±à°²à±€ à°šà±‚à°¡à°‚à°¡à°¿.',
                            english:
                                'There are no posters for this category right now. Pull down to refresh and check again.',
                            hindi:
                                'à¤‡à¤¸ à¤•à¥ˆà¤Ÿà¥‡à¤—à¤°à¥€ à¤®à¥‡à¤‚ à¤…à¤­à¥€ à¤ªà¥‹à¤¸à¥à¤Ÿà¤° à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¤‚à¥¤ à¤°à¤¿à¤«à¥à¤°à¥‡à¤¶ à¤•à¤°à¤•à¥‡ à¤«à¤¿à¤° à¤¦à¥‡à¤–à¥‡à¤‚à¥¤',
                            tamil:
                                'à®‡à®¨à¯à®¤ à®µà®•à¯ˆà®¯à®¿à®²à¯ à®‡à®ªà¯à®ªà¯‹à®¤à¯ à®ªà¯‹à®¸à¯à®Ÿà®°à¯à®•à®³à¯ à®‡à®²à¯à®²à¯ˆ. à®°à®¿à®ªà¯à®°à¯†à®·à¯ à®šà¯†à®¯à¯à®¤à¯ à®®à¯€à®£à¯à®Ÿà¯à®®à¯ à®ªà®¾à®°à¯à®•à¯à®•à®µà¯à®®à¯.',
                            kannada:
                                'à²ˆ à²µà²°à³à²—à²¦à²²à³à²²à²¿ à²ˆà²— à²ªà³‹à²¸à³à²Ÿà²°à³â€Œà²—à²³à²¿à²²à³à²². à²°à²¿à²«à³à²°à³†à²¶à³ à²®à²¾à²¡à²¿ à²®à²¤à³à²¤à³† à²¨à³‹à²¡à²¿.',
                            malayalam:
                                'à´ˆ à´µà´¿à´­à´¾à´—à´¤àµà´¤à´¿àµ½ à´‡à´ªàµà´ªàµ‹àµ¾ à´ªàµ‹à´¸àµà´±àµà´±à´±àµà´•àµ¾ à´‡à´²àµà´². à´±à´¿à´«àµà´°àµ†à´·àµ à´šàµ†à´¯àµà´¤àµ à´µàµ€à´£àµà´Ÿàµà´‚ à´¨àµ‹à´•àµà´•àµ‚.',
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = feedEntries[index];
                            if (entry.isPromo) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _HomeInlinePromoCard(
                                  data: entry.promo!,
                                  viewerPosterProfile: _viewerPosterProfile,
                                  slides: promoSlides,
                                  onTap: () => unawaited(
                                    _handlePromoTap(entry.promo!.type),
                                  ),
                                ),
                              );
                            }
                            final item = entry.template!;
                            return _TemplateFeedItem(
                              key: ValueKey<String>(
                                '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${language.name}-${_viewerPosterProfile.identityMode.name}-${_viewerPosterProfile.activeName}-${_viewerPosterProfile.activeWhatsappNumber}-${_viewerPosterProfile.photoPath}-${_viewerPosterProfile.photoUrl}-${_viewerPosterProfile.businessLogoPath}-${_viewerPosterProfile.businessLogoUrl}-$_posterRenderCycle',
                              ),
                              item: item,
                              language: language,
                              viewerPosterProfile: _viewerPosterProfile,
                              posterRenderCycle: _posterRenderCycle,
                            );
                          },
                          childCount: feedEntries.length,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                          addSemanticIndexes: false,
                        ),
                      ),
                    ),
                  if (_templatesLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        ),
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
              Expanded(
                child: Text(
                  AppPublicInfo.appName,
                  style: const TextStyle(
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

class _HomeInlinePromoCard extends StatefulWidget {
  const _HomeInlinePromoCard({
    required this.data,
    required this.viewerPosterProfile,
    required this.slides,
    required this.onTap,
  });

  final _HomeFeedPromoCardData data;
  final PosterProfileData viewerPosterProfile;
  final List<_TemplateItem> slides;
  final VoidCallback onTap;

  @override
  State<_HomeInlinePromoCard> createState() => _HomeInlinePromoCardState();
}

class _HomeInlinePromoCardState extends State<_HomeInlinePromoCard> {
  late final PageController _pageController = PageController(
    viewportFraction: 1,
  );
  late final List<String> _slideUrls = widget.slides
      .map((item) => (item.thumbnailUrl ?? item.imageUrl ?? '').trim())
      .where((url) => url.isNotEmpty)
      .take(6)
      .toList(growable: false);
  Timer? _autoScrollTimer;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients || _slideUrls.length <= 1) {
        return;
      }
      final nextPage = (_pageIndex + 1) % _slideUrls.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = PosterProfileService.resolveImageProvider(
      widget.viewerPosterProfile,
      preferPersonalPhotoOverBusinessLogo: true,
      allowOriginalFallbackWhenCutoutUnavailable: true,
    );
    final userName = widget.viewerPosterProfile.activeName.trim().isNotEmpty
        ? widget.viewerPosterProfile.activeName.trim()
        : widget.viewerPosterProfile.resolvedName(
            language: context.currentLanguage,
          );
    final contact = widget.viewerPosterProfile.activeWhatsappNumber.trim();
    final actionStripColor = switch (widget.data.type) {
      _HomePromoCardType.subscribe => const Color(0xFF4123C7),
      _HomePromoCardType.renewalReminder => const Color(0xFFB45309),
      _HomePromoCardType.update => const Color(0xFF0F766E),
      _HomePromoCardType.rate => const Color(0xFFD97706),
    };
    final isPlayStoreCard =
        widget.data.type == _HomePromoCardType.update ||
        widget.data.type == _HomePromoCardType.rate;
    final accentIcon = switch (widget.data.type) {
      _HomePromoCardType.subscribe => Icons.workspace_premium_rounded,
      _HomePromoCardType.renewalReminder => Icons.notifications_active_rounded,
      _HomePromoCardType.update || _HomePromoCardType.rate => null,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF4F46E5)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 148,
                  child: _slideUrls.isEmpty
                      ? const ColoredBox(color: Color(0xFFF8FAFC))
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: _slideUrls.length,
                          onPageChanged: (index) => _pageIndex = index,
                          itemBuilder: (context, index) => Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              CachedNetworkImage(
                                imageUrl: _slideUrls[index],
                                fit: BoxFit.cover,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      Colors.black.withValues(alpha: 0.10),
                                      Colors.black.withValues(alpha: 0.42),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 31,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? Text(
                              userName.isEmpty ? 'U' : userName[0],
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (contact.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.call_rounded,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    contact,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(color: actionStripColor),
                child: Row(
                  children: <Widget>[
                    if (isPlayStoreCard)
                      const _PromoPlayStoreAccentBadge()
                    else
                      _PromoAccentBadge(
                        icon: accentIcon!,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: switch (widget.data.type) {
                  _HomePromoCardType.update ||
                  _HomePromoCardType.rate => const Align(
                    alignment: Alignment.centerLeft,
                    child: _GooglePlayMiniBadge(),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.data.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: widget.onTap,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: const Color(0xFFFFD60A),
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (widget.data.type == _HomePromoCardType.subscribe)
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 18,
                            )
                          else if (widget.data.type ==
                              _HomePromoCardType.renewalReminder)
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                            )
                          else
                            const _GooglePlayActionBadge(),
                          const SizedBox(width: 8),
                          Text(
                            widget.data.buttonLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoAccentBadge extends StatelessWidget {
  const _PromoAccentBadge({required this.icon, required this.backgroundColor});

  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

class _GooglePlayMiniBadge extends StatelessWidget {
  const _GooglePlayMiniBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            'assets/branding/google_logo.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 7),
          const Text(
            'Google Play',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoPlayStoreAccentBadge extends StatelessWidget {
  const _PromoPlayStoreAccentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const _GooglePlayActionBadge(),
    );
  }
}

class _GooglePlayActionBadge extends StatelessWidget {
  const _GooglePlayActionBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/branding/google_logo.png',
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 5),
        const Text(
          'Play',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 6), (_) {
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
          itemBuilder: (context, index) => LayoutBuilder(
            builder: (context, constraints) {
              final memWidth = constraints.maxWidth.isFinite
                  ? (constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(480, 1600)
                  : 1080;
              return CachedNetworkImage(
                imageUrl: _slides[index].imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: memWidth,
                filterQuality: FilterQuality.low,
                placeholder: (_, _) => const _ImageLoadingState(),
                errorWidget: (_, _, _) => _ImageErrorState(
                  compact: true,
                  title: context.strings.localized(
                    telugu:
                        'à°¬à±à°¯à°¾à°¨à°°à± à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°¦à±',
                    english: 'Banner unavailable',
                  ),
                  subtitle: context.strings.localized(
                    telugu:
                        'à°¦à°¯à°šà±‡à°¸à°¿ à°•à±Šà°¦à±à°¦à°¿à°¸à±‡à°ªà°Ÿà°¿ à°¤à°°à±à°µà°¾à°¤ à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
                    english: 'Please try again shortly.',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeBannerAdFallback extends StatefulWidget {
  const _HomeBannerAdFallback();

  @override
  State<_HomeBannerAdFallback> createState() => _HomeBannerAdFallbackState();
}

class _HomeBannerAdFallbackState extends State<_HomeBannerAdFallback> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _loadAttempted = false;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadAttempted) {
      return;
    }
    _loadAttempted = true;
    unawaited(_loadBanner());
  }

  Future<void> _loadBanner() async {
    if (kIsWeb || !Platform.isAndroid || !AppPublicInfo.hasHomeBannerAdUnitId) {
      return;
    }
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          availableWidth.truncate(),
        );
    if (!mounted || adaptiveSize == null) {
      return;
    }
    final banner = BannerAd(
      adUnitId: AppPublicInfo.adMobHomeBannerAdUnitId,
      request: const AdRequest(),
      size: adaptiveSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _adSize = adaptiveSize;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          _homeDebugLog('home banner ad failed: $error');
          ad.dispose();
          if (!mounted) {
            return;
          }
          setState(() {
            _bannerAd = null;
            _adSize = null;
            _isLoaded = false;
          });
        },
      ),
    );
    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          width: _adSize!.width.toDouble(),
          height: _adSize!.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
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
        'పోస్టర్లను షేర్ లేదా డౌన్‌లోడ్ చేయడానికి సబ్‌స్క్రిప్షన్ యాక్టివ్ చేయాలి.',
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
        '${SubscriptionPlanConfig.trialDays} రోజుల ట్రయల్ పూర్తయ్యాక మీరు క్యాన్సిల్ చేయకపోతే నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} ఆటో రీన్యువల్ అవుతుంది. ${SubscriptionPlanConfig.trialDays} రోజుల లోపు క్యాన్సిల్ చేస్తే నెలవారీ ఛార్జ్ పడదు. క్యాన్సిల్ చేసినా ప్రస్తుత ప్లాన్ గడువు ముగిసే వరకు బెనిఫిట్స్ ఉపయోగించవచ్చు.',
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

// ignore: must_be_immutable
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
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');
  static const List<String> _randomPosterNameFonts = <String>[
    'Pragathi',
    'Brahma',
    'Kranthi',
    'Reshma',
    'Tejafont',
  ];
  final GlobalKey _posterRepaintKey = GlobalKey();
  final ValueNotifier<bool> _showPosterPhotoNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> _posterReadyNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _activeActionNotifier = ValueNotifier<String?>(
    null,
  );
  Uint8List? _preparedPosterBytes;
  String? _preparedPosterSignature;
  String? _preparedPosterFilePath;
  Future<void>? _preparePosterFuture;
  Future<Uint8List?>? _posterCaptureFuture;
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

  String _resolvePosterNameFontFamily(String resolvedName) {
    final personalizationConfig = item.personalizationConfig;
    final seedSource =
        '${item.imageUrl ?? item.imageAssetPath ?? 'poster'}'
        '|${personalizationConfig?.nameX ?? 0}'
        '|${personalizationConfig?.nameY ?? 0}'
        '|${personalizationConfig?.stripHeight ?? 0}'
        '|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index = hash.abs() % _randomPosterNameFonts.length;
    return _randomPosterNameFonts[index];
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

  String _posterSignature({required bool isPhotoVisible}) {
    return '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${item.videoUrl ?? ''}-${item.mediaType}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-$posterRenderCycle-$isPhotoVisible';
  }

  bool _beginAction(String action) {
    if (_activeActionNotifier.value != null) {
      return false;
    }
    _activeActionNotifier.value = action;
    return true;
  }

  void _endAction() {
    _activeActionNotifier.value = null;
  }

  void _invalidatePreparedPosterCache() {
    final existingPath = _preparedPosterFilePath;
    _preparedPosterBytes = null;
    _preparedPosterSignature = null;
    _preparedPosterFilePath = null;
    if (existingPath != null) {
      unawaited(
        File(existingPath).delete().catchError((_) => File(existingPath)),
      );
    }
  }

  void _schedulePosterWarmup({bool force = false}) {
    if (item.isVideo || !_posterReadyNotifier.value) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_preparePosterExport(force: force));
    });
  }

  Future<void> _prepareLegacyTextForExport() async {
    final resolvedName = viewerPosterProfile.resolvedName(language: language);
    final isBusinessProfile =
        viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final resolvedDesignation = isBusinessProfile
        ? viewerPosterProfile.businessTagline.trim()
        : viewerPosterProfile.whatsappNumber.trim();
    final displayNameFontFamily = _stripNameFontFamily(
      resolvedName,
      _resolvePosterNameFontFamily(resolvedName),
    );
    const designationFontFamily = 'Pallavi Medium';
    final futures = <Future<String?>>[];

    if (_shouldConvertForLegacyTelugu(resolvedName, displayNameFontFamily) &&
        TeluguLegacyTextService.cachedValue(
              resolvedName,
              fontFamily: displayNameFontFamily!,
            ) ==
            null) {
      futures.add(
        TeluguLegacyTextService.convert(
          resolvedName,
          fontFamily: displayNameFontFamily,
        ),
      );
    }

    if (_shouldConvertForLegacyTelugu(
          resolvedDesignation,
          designationFontFamily,
        ) &&
        TeluguLegacyTextService.cachedValue(
              resolvedDesignation,
              fontFamily: designationFontFamily,
            ) ==
            null) {
      futures.add(
        TeluguLegacyTextService.convert(
          resolvedDesignation,
          fontFamily: designationFontFamily,
        ),
      );
    }

    if (futures.isEmpty) {
      return;
    }

    await Future.wait(futures);
  }

  Future<void> _preparePosterExport({bool force = false}) async {
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    if (!force &&
        _preparedPosterSignature == signature &&
        _preparedPosterBytes != null &&
        _preparedPosterFilePath != null &&
        await File(_preparedPosterFilePath!).exists()) {
      return;
    }
    final inFlight = _preparePosterFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _doPreparePosterExport(signature);
    _preparePosterFuture = future;
    try {
      await future;
    } finally {
      if (identical(_preparePosterFuture, future)) {
        _preparePosterFuture = null;
      }
    }
  }

  Future<void> _doPreparePosterExport(String signature) async {
    try {
      await ScreenSecurityService.disableSecure();
      await _prepareLegacyTextForExport();
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 32));
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final bytes = await _capturePosterBytes();
      if (bytes == null) {
        return;
      }
      final tempDirectory = await getTemporaryDirectory();
      final fileName = 'mana_poster_export_${signature.hashCode.abs()}.png';
      final filePath =
          '${tempDirectory.path}${Platform.pathSeparator}$fileName';
      await File(filePath).writeAsBytes(bytes, flush: false);
      _preparedPosterBytes = bytes;
      _preparedPosterSignature = signature;
      _preparedPosterFilePath = filePath;
      _homeDebugLog('poster export warmup ready bytes=${bytes.length}');
    } catch (error, stackTrace) {
      _homeDebugLogStack('poster export warmup failed: $error', stackTrace);
    } finally {
      await ScreenSecurityService.enableSecure();
    }
  }

  Future<String?> _ensurePreparedPosterFile() async {
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    final existingPath = _preparedPosterFilePath;
    if (_preparedPosterSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      return existingPath;
    }
    await _preparePosterExport();
    final refreshedPath = _preparedPosterFilePath;
    if (refreshedPath != null && await File(refreshedPath).exists()) {
      return refreshedPath;
    }
    return null;
  }

  bool _hasImmediateSubscriptionAccess() {
    final cachedEntitlement = _subscriptionBackendService.cachedEntitlement;
    if (_subscriptionBackendService.hasFreshEntitlementCache &&
        cachedEntitlement?.hasAccess == true) {
      return true;
    }
    return _hasRecentCachedProFallback(
      cachedEntitlement: cachedEntitlement,
      cachedEntitlementAt: _subscriptionBackendService.cachedEntitlementAt,
    );
  }

  void _handlePosterReady() {
    if (!_posterReadyNotifier.value) {
      _posterReadyNotifier.value = true;
    }
    _schedulePosterWarmup();
  }

  Future<Uint8List?> _capturePosterBytes() async {
    final inFlight = _posterCaptureFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _capturePosterBytesInternal();
    _posterCaptureFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_posterCaptureFuture, future)) {
        _posterCaptureFuture = null;
      }
    }
  }

  Future<Uint8List?> _capturePosterBytesInternal() async {
    final binding = WidgetsBinding.instance;
    for (var attempt = 0; attempt < 3; attempt++) {
      await binding.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary =
          _posterRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _homeDebugLog('capture boundary unavailable on attempt=$attempt');
        continue;
      }
      if (boundary.debugNeedsPaint) {
        _homeDebugLog('capture boundary pending paint on attempt=$attempt');
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
        if (attempt == 2) {
          _homeDebugLogStack('capture attempt failed: $error', stackTrace);
          rethrow;
        }
        _homeDebugLog('capture attempt deferred after failure: $error');
        await binding.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 50));
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
    _homeDebugLog(
      'subscription sync: backendResponse.isPro=${refreshed.isPro}',
    );
  }

  Future<bool> _tryRestoreSubscriptionSilently() async {
    final outcome = await _subscriptionRestoreGateway.restorePurchases();
    final evidence = outcome.evidence;
    final playStorePurchaseFound =
        outcome.result == PurchaseFlowResult.success && evidence != null;
    _homeDebugLog(
      'subscription restore check: playStorePurchaseFound=$playStorePurchaseFound',
    );
    if (playStorePurchaseFound) {
      await _syncPlayStorePurchaseToBackend(evidence);
      final refreshed = await _subscriptionBackendService
          .fetchFreshEntitlementWithRetry();
      _homeDebugLog(
        'subscription restore verify: backendResponse.isPro=${refreshed.isPro}',
      );
      return refreshed.hasAccess;
    }

    final fallback = await _subscriptionBackendService
        .fetchFreshEntitlementWithRetry();
    _homeDebugLog(
      'subscription restore fallback: backendResponse.isPro=${fallback.isPro}',
    );
    return fallback.hasAccess;
  }

  bool _hasRecentCachedProFallback({
    required SubscriptionBackendResult? cachedEntitlement,
    required DateTime? cachedEntitlementAt,
  }) {
    if (cachedEntitlement?.hasAccess != true || cachedEntitlementAt == null) {
      return false;
    }
    const offlineGraceWindow = Duration(hours: 1);
    return DateTime.now().difference(cachedEntitlementAt) <= offlineGraceWindow;
  }

  Future<bool> _resolveLatestSubscriptionAccess() async {
    final cachedEntitlement = _subscriptionBackendService.cachedEntitlement;
    final cachedEntitlementAt = _subscriptionBackendService.cachedEntitlementAt;
    final backend = await _subscriptionBackendService.fetchFreshEntitlement();
    final effectiveIsPro = backend.hasAccess;
    _homeDebugLog(
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
      _homeDebugLog('subscription access resolve: using cached Pro fallback');
      return true;
    }

    final restoredSilently = await _tryRestoreSubscriptionSilently();
    if (restoredSilently) {
      return true;
    }

    final refreshed = await _subscriptionBackendService
        .fetchFreshEntitlementWithRetry();
    final refreshedEffectiveIsPro = refreshed.hasAccess;
    _homeDebugLog(
      'subscription access retry: backendResponse.isPro=$refreshedEffectiveIsPro',
    );
    if (!refreshedEffectiveIsPro &&
        refreshed.state == SubscriptionBackendState.failed &&
        _hasRecentCachedProFallback(
          cachedEntitlement: cachedEntitlement,
          cachedEntitlementAt: cachedEntitlementAt,
        )) {
      _homeDebugLog('subscription access retry: using cached Pro fallback');
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
          telugu:
              'à°—à±à°¯à°¾à°²à°°à±€ à°…à°¨à±à°®à°¤à°¿ à°¨à°¿à°°à°¾à°•à°°à°¿à°‚à°šà°¬à°¡à°¿à°‚à°¦à°¿.',
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
          telugu:
              'à°«à±ˆà°²à± à°¸à±‡à°µà± à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
          english: 'File save failed. Please try again.',
        );
      default:
        return context.strings.localized(
          telugu:
              'à°¡à±Œà°¨à±â€Œà°²à±‹à°¡à± à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
          english: 'Download failed. Please try again.',
        );
    }
  }

  Future<bool> _ensureSubscriptionAccess(BuildContext context) async {
    if (_hasImmediateSubscriptionAccess()) {
      unawaited(_subscriptionBackendService.refreshEntitlementInBackground());
      return true;
    }
    final hasLatestAccess = await _resolveLatestSubscriptionAccess().timeout(
      SubscriptionPlanConfig.paywallTimeout,
      onTimeout: () async => false,
    );
    if (hasLatestAccess) {
      return true;
    }
    _homeDebugLog('subscription access check: backendResponse.isPro=false');
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
    if (!_beginAction('download')) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final galleryPermissionMessage = context.strings.localized(
      telugu:
          'à°—à±à°¯à°¾à°²à°°à±€ à°…à°¨à±à°®à°¤à°¿ à°¨à°¿à°°à°¾à°•à°°à°¿à°‚à°šà°¬à°¡à°¿à°‚à°¦à°¿.',
      english: 'Gallery permission was denied.',
    );
    final posterNotReadyMessage = context.strings.localized(
      telugu:
          'à°ªà±‹à°¸à±à°Ÿà°°à± capture à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
      english: 'Capture failed. Please try again.',
    );
    final posterSavedMessage = context.strings.localized(
      telugu:
          'à°ªà±‹à°¸à±à°Ÿà°°à± à°—à±à°¯à°¾à°²à°°à±€à°²à±‹ à°¸à±‡à°µà± à°…à°¯à°¿à°‚à°¦à°¿.',
      english: 'Poster saved to gallery.',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu:
          'à°«à±ˆà°²à± à°¸à±‡à°µà± à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
      english: 'File save failed. Please try again.',
    );
    final downloadFailedMessage = context.strings.localized(
      telugu:
          'à°¡à±Œà°¨à±â€Œà°²à±‹à°¡à± à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
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
      final preparedPath = await _ensurePreparedPosterFile();
      if (preparedPath == null) {
        result = false;
        _showSnack(messenger, posterNotReadyMessage);
        return;
      }
      final fileName =
          'mana_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final saveResult =
          await MediaExportService.saveImageFileToGalleryDetailed(
            preparedPath,
            fileName: fileName,
          );
      result = saveResult.success;
      if (result) {
        _showSnack(messenger, posterSavedMessage);
        return;
      }
      _homeDebugLog(
        'download native save failed: code=${saveResult.code}, message=${saveResult.message}',
      );
      if (!context.mounted) {
        return;
      }
      _showSnack(messenger, _downloadSaveFailureMessage(context, saveResult));
    } on FileSystemException catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('download file save failed: $error', stackTrace);
      _showSnack(messenger, fileSaveFailedMessage);
    } catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('download failed: $error', stackTrace);
      _showSnack(messenger, downloadFailedMessage);
    } finally {
      _homeDebugLog('download result=$result');
      _endAction();
    }
  }

  Future<void> _onShareTap(BuildContext context) async {
    if (!_beginAction('share')) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final posterNotReadyMessage = context.strings.localized(
      telugu:
          'à°ªà±‹à°¸à±à°Ÿà°°à± capture à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
      english: 'Capture failed. Please try again.',
    );
    final shareFailedMessage = context.strings.localized(
      telugu:
          'à°·à±‡à°°à± à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
      english: 'Share failed. Please try again.',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu:
          'à°«à±ˆà°²à± à°¸à±‡à°µà± à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
      english: 'File save failed. Please try again.',
    );
    final resolvedUserName = viewerPosterProfile.activeName.trim().isNotEmpty
        ? viewerPosterProfile.activeName.trim()
        : (viewerPosterProfile
                  .resolvedName(language: language)
                  .trim()
                  .isNotEmpty
              ? viewerPosterProfile.resolvedName(language: language).trim()
              : 'User');
    final shareText =
        '✨ Shared by $resolvedUserName using ${AppPublicInfo.appName}\n'
        'Download the app: ${AppPublicInfo.playStoreUrl}';
    try {
      final hasAccess = await _ensureSubscriptionAccess(context);
      if (!hasAccess) {
        result = false;
        return;
      }
      final preparedPath = await _ensurePreparedPosterFile();
      if (preparedPath == null) {
        result = false;
        _showSnack(messenger, posterNotReadyMessage);
        return;
      }
      if (!context.mounted) {
        result = false;
        return;
      }
      if (!context.mounted) {
        result = false;
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        preparedPath,
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      result = true;
    } on MediaShareException catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('share media service failed: $error', stackTrace);
      _showSnack(messenger, shareFailedMessage);
    } on FileSystemException catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('share file save failed: $error', stackTrace);
      _showSnack(messenger, fileSaveFailedMessage);
    } catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('share failed: $error', stackTrace);
      _showSnack(messenger, shareFailedMessage);
    } finally {
      _homeDebugLog('share result=$result');
      _endAction();
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
          if (isPosterReady) {
            _schedulePosterWarmup();
          }
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
                        '${item.titleEn}-${item.imageUrl ?? item.thumbnailUrl ?? item.imageAssetPath}-${item.videoUrl ?? ''}-${item.mediaType}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-$posterRenderCycle',
                      ),
                      child: item.isVideo
                          ? _TemplateVideoPlayer(
                              videoUrl: item.videoUrl!,
                              onReady: _handlePosterReady,
                            )
                          : personalizationConfig != null
                          ? _CreatorPosterPreview(
                              key: ValueKey<String>(
                                '${item.titleEn}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-$posterRenderCycle',
                              ),
                              imageAssetPath: item.imageAssetPath,
                              imageUrl: item.imageUrl,
                              thumbnailUrl: item.thumbnailUrl,
                              personalizationConfig: personalizationConfig,
                              viewerPosterProfile: viewerPosterProfile,
                              language: language,
                              showProfilePhoto: isPhotoVisible,
                              posterRenderCycle: posterRenderCycle,
                              onPosterReady: _handlePosterReady,
                            )
                          : _TemplatePosterImage(
                              imageAssetPath: item.imageAssetPath,
                              imageUrl: item.imageUrl,
                              thumbnailUrl: item.thumbnailUrl,
                              onFirstFrameReady: _handlePosterReady,
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
                              _invalidatePreparedPosterCache();
                              _showPosterPhotoNotifier.value = !isPhotoVisible;
                              _schedulePosterWarmup(force: true);
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
                                      telugu: 'à°«à±‹à°Ÿà±‹',
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
                                        _invalidatePreparedPosterCache();
                                        _showPosterPhotoNotifier.value = value;
                                        _schedulePosterWarmup(force: true);
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
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _activeActionNotifier,
                        builder: (context, activeAction, _) {
                          final isBusy = activeAction == 'share';
                          return OutlinedButton.icon(
                            onPressed: item.isVideo || activeAction != null
                                ? null
                                : () => unawaited(_onShareTap(context)),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/branding/whatsapp_icon.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.whatshot_rounded,
                                      size: 22,
                                    ),
                                  ),
                            label: Text(
                              isBusy
                                  ? strings.localized(
                                      telugu: 'à°¸à°¿à°¦à±à°§à°‚...',
                                      english: 'Preparing...',
                                    )
                                  : strings.localized(
                                      telugu: 'à°·à±‡à°°à±',
                                      english: 'Share',
                                    ),
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
                          );
                        },
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
                                _invalidatePreparedPosterCache();
                                _showPosterPhotoNotifier.value =
                                    !isPhotoVisible;
                                _schedulePosterWarmup(force: true);
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
                                  telugu: 'à°«à±‹à°Ÿà±‹',
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
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _activeActionNotifier,
                        builder: (context, activeAction, _) {
                          final isBusy = activeAction == 'download';
                          return FilledButton.icon(
                            onPressed: item.isVideo || activeAction != null
                                ? null
                                : () => unawaited(_onDownloadTap(context)),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.download_rounded),
                            label: Text(
                              isBusy
                                  ? strings.localized(
                                      telugu: 'à°¸à°¿à°¦à±à°§à°‚...',
                                      english: 'Preparing...',
                                    )
                                  : strings.downloadLabel,
                            ),
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
                          );
                        },
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
    this.thumbnailUrl,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? thumbnailUrl;
  final VoidCallback? onFirstFrameReady;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pixelRatio = MediaQuery.devicePixelRatioOf(
          context,
        ).clamp(1.0, 3.0);
        final cacheWidth = (width * pixelRatio).round().clamp(360, 1080);

        final placeholderUrl = thumbnailUrl?.trim() ?? '';
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
                    telugu:
                        'à°Ÿà±†à°‚à°ªà±à°²à±‡à°Ÿà± à°šà°¿à°¤à±à°°à°‚ à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°¦à±',
                    english: 'Template image unavailable',
                  ),
                  subtitle: context.strings.localized(
                    telugu:
                        'à°°à°¿à°«à±à°°à±†à°·à± à°šà±‡à°¯à°‚à°¡à°¿ à°²à±‡à°¦à°¾ à°®à°°à±‹ à°Ÿà±†à°‚à°ªà±à°²à±‡à°Ÿà± à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
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
                  if (placeholderUrl.isNotEmpty &&
                      placeholderUrl != (imageUrl ?? '').trim()) {
                    return Image(
                      image: ResizeImage.resizeIfNeeded(
                        cacheWidth.clamp(240, 540),
                        null,
                        CachedNetworkImageProvider(placeholderUrl),
                      ),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.low,
                    );
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
                          telugu:
                              'à°Ÿà±†à°‚à°ªà±à°²à±‡à°Ÿà± à°šà°¿à°¤à±à°°à°‚ à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°¦à±',
                          english: 'Template image unavailable',
                        ),
                        subtitle: strings.localized(
                          telugu:
                              'à°°à°¿à°«à±à°°à±†à°·à± à°šà±‡à°¯à°‚à°¡à°¿ à°²à±‡à°¦à°¾ à°®à°°à±‹ à°Ÿà±†à°‚à°ªà±à°²à±‡à°Ÿà± à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
                          english: 'Please refresh or try another template.',
                        ),
                      );
                    },
              );

          return Align(alignment: Alignment.topCenter, child: imageWidget);
        },
      ),
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
          telugu:
              'à°µà±€à°¡à°¿à°¯à±‹ à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°²à±‡à°¦à±',
          english: 'Video unavailable',
        ),
        subtitle: context.strings.localized(
          telugu: 'à°®à°³à±à°³à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
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
    this.thumbnailUrl,
    required this.personalizationConfig,
    required this.viewerPosterProfile,
    required this.language,
    required this.showProfilePhoto,
    required this.posterRenderCycle,
    this.onPosterReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? thumbnailUrl;
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
    'Brahma',
    'Kranthi',
    'Reshma',
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
  final Map<String, String> _legacyTextOverrides = <String, String>{};
  final Set<String> _legacyTextRequestsInFlight = <String>{};

  @override
  void initState() {
    super.initState();
    _primeLegacyTextCacheForCurrentState();
  }

  @override
  void didUpdateWidget(covariant _CreatorPosterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageAssetPath != widget.imageAssetPath ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _basePosterReady = false;
    }
    if (oldWidget.viewerPosterProfile != widget.viewerPosterProfile ||
        oldWidget.language != widget.language ||
        oldWidget.personalizationConfig != widget.personalizationConfig ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _primeLegacyTextCacheForCurrentState();
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
          (luminanceTotal, color) => luminanceTotal + color.computeLuminance(),
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

  String _legacyTextCacheKey(String text, String fontFamily) {
    return '$fontFamily::$text';
  }

  String? _legacyOverrideFor(String text, String? fontFamily) {
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) || fontFamily == null) {
      return null;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    return _legacyTextOverrides[key] ??
        TeluguLegacyTextService.cachedValue(text, fontFamily: fontFamily);
  }

  Future<void> _primeLegacyTextValue(
    String text,
    String? fontFamily,
  ) async {
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        fontFamily == null ||
        text.trim().isEmpty) {
      return;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    final cached = TeluguLegacyTextService.cachedValue(
      text,
      fontFamily: fontFamily,
    );
    if (cached != null && cached.isNotEmpty) {
      _legacyTextOverrides[key] = cached;
      return;
    }
    if (_legacyTextRequestsInFlight.contains(key)) {
      return;
    }
    _legacyTextRequestsInFlight.add(key);
    try {
      final converted = await TeluguLegacyTextService.convert(
        text,
        fontFamily: fontFamily,
      );
      if (!mounted) {
        return;
      }
      if (converted != null &&
          converted.isNotEmpty &&
          _legacyTextOverrides[key] != converted) {
        setState(() {
          _legacyTextOverrides[key] = converted;
        });
      }
    } finally {
      _legacyTextRequestsInFlight.remove(key);
    }
  }

  Future<void> _primeLegacyTextCacheForCurrentState() async {
    final resolvedName = widget.viewerPosterProfile.resolvedName(
      language: widget.language,
    );
    final isBusinessProfile =
        widget.viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final resolvedDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.whatsappNumber.trim();
    final displayNameFontFamily = _stripNameFontFamily(
      resolvedName,
      _resolvePosterNameFontFamily(resolvedName),
    );
    await Future.wait<void>(<Future<void>>[
      _primeLegacyTextValue(resolvedName, displayNameFontFamily),
      _primeLegacyTextValue(resolvedDesignation, 'Pallavi Medium'),
    ]);
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
    return buildText(_legacyOverrideFor(text, fontFamily) ?? text);
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

    return RepaintBoundary(
      child: SizedBox(
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
                thumbnailUrl: widget.thumbnailUrl,
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
    final shouldDeferHeavyEffects =
        Scrollable.recommendDeferredLoadingForContext(context);
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
        if (isBlurLayer && !shouldDeferHeavyEffects) {
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
      if (normalizedEdgeStyle == 'feather' && !shouldDeferHeavyEffects) {
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
              clipBehavior: Clip.antiAlias,
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
        return ClipOval(clipBehavior: Clip.antiAlias, child: framedChild);
      case 'rounded':
      case 'rounded_square':
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'pill':
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'oval':
        return ClipOval(clipBehavior: Clip.antiAlias, child: framedChild);
      case 'hexagon':
        return ClipPath(
          clipper: const _PosterMaskClipper('hexagon'),
          clipBehavior: Clip.antiAlias,
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
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'custom_screen_fit':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'custom_board_fit':
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'custom_frame_fit':
      case 'vertical_rectangle':
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
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
      return ClipOval(clipBehavior: Clip.antiAlias, child: child);
    case 'rounded':
    case 'rounded_square':
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'pill':
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'custom_screen_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'custom_board_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'custom_frame_fit':
    case 'vertical_rectangle':
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
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
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'square':
    default:
      return ClipRect(clipBehavior: Clip.antiAlias, child: child);
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
