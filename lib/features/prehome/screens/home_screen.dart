// ignore_for_file: unused_element_parameter

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:mana_poster/app/media/poster_network_image_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show compute, kDebugMode, kIsWeb, kProfileMode, setEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/services/admob_consent_service.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/services/play_engagement_service.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/app/services/time_slot_service.dart';
import 'package:mana_poster/app/startup/post_splash_startup_gate.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/models/community_status.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/models/political_party.dart';
import 'package:mana_poster/features/prehome/screens/community_status_upload_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/screens/user_poster_uploads_screen.dart';
import 'package:mana_poster/features/prehome/services/poster_downloads_service.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_home_banner_service.dart';
import 'package:mana_poster/features/prehome/services/app_location_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/services/community_status_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/manual_event_category_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/referral_reward_service.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';
import 'package:mana_poster/features/prehome/services/user_poster_uploads_service.dart';
import 'package:mana_poster/features/prehome/widgets/poster_identity_visual.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';
import 'package:mana_poster/features/prehome/widgets/subscription_exit_video_prompt.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _homeDebugLog(String message) {
  if (!kDebugMode && !kProfileMode) {
    return;
  }
  // ignore: avoid_print
  print(message);
}

void _homeDebugLogStack(String message, StackTrace stackTrace) {
  if (!kDebugMode && !kProfileMode) {
    return;
  }
  // ignore: avoid_print
  print(message);
  // ignore: avoid_print
  print(stackTrace);
}

Future<void> _openExternalPublicUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (opened || !context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          context.strings.localized(
            telugu: 'లింక్ తెరవలేకపోయాం. మళ్లీ ప్రయత్నించండి.',
            english: 'Could not open the link. Please try again.',
          ),
        ),
      ),
    );
}

/// Firebase Storage URLs (https with token or gs://). Use [Reference.refFromURL]
/// to mint a fresh download URL when tokens expire.
bool _posterStringLooksFirebaseResolvable(String raw) {
  final s = raw.trim();
  if (s.isEmpty) {
    return false;
  }
  final lower = s.toLowerCase();
  return lower.startsWith('gs://') ||
      lower.contains('firebasestorage.googleapis.com') ||
      lower.contains('firebasestorage.app');
}

/// Already-public HTTP(S) poster asset URLs can be rendered directly without
/// minting another authenticated Firebase Storage download URL.
bool _posterStringLooksDirectHttpDownloadUrl(String raw) {
  final s = raw.trim();
  if (s.isEmpty) {
    return false;
  }
  final lower = s.toLowerCase();
  return (lower.startsWith('http://') || lower.startsWith('https://')) &&
      !lower.startsWith('gs://') &&
      !_posterStringLooksFirebaseResolvable(s);
}

/// Looks like a Storage object path for [FirebaseStorage.ref], not http(s).
bool _posterStringLooksFirebaseStorageRelativePath(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s.contains('://')) {
    return false;
  }
  return true;
}

bool _shouldPreferOriginalPosterQualitySource(String? value) {
  final raw = (value ?? '').trim().toLowerCase();
  if (raw.isEmpty) {
    return false;
  }
  return raw.contains('community_uploads') ||
      raw.contains('creator_posters/') ||
      raw.contains('creator-posters/') ||
      raw.contains('portal_assets/admin_upload_posters/') ||
      raw.contains('portal_assets/admin_app_posters/');
}

class _PosterFirebaseCandidate {
  const _PosterFirebaseCandidate.path(this.value) : urlMode = false;
  const _PosterFirebaseCandidate.url(this.value) : urlMode = true;

  final String value;
  final bool urlMode;
}

List<_PosterFirebaseCandidate> _posterFirebaseResolveCandidates({
  required String imageStoragePath,
  required String thumbnailStoragePath,
  required String imageUrl,
  required String thumbnailUrl,
}) {
  final seen = <String>{};
  final List<_PosterFirebaseCandidate> out = <_PosterFirebaseCandidate>[];

  void addPath(String p) {
    final t = p.trim();
    if (t.isEmpty) {
      return;
    }
    final key = 'p:$t';
    if (!seen.add(key)) {
      return;
    }
    out.add(_PosterFirebaseCandidate.path(t));
  }

  void addUrl(String u) {
    final t = u.trim();
    if (t.isEmpty) {
      return;
    }
    final key = 'u:$t';
    if (!seen.add(key)) {
      return;
    }
    out.add(_PosterFirebaseCandidate.url(t));
  }

  bool isGsUrl(String value) => value.trim().toLowerCase().startsWith('gs://');

  addPath(imageStoragePath);
  if (isGsUrl(imageUrl) || _posterStringLooksFirebaseResolvable(imageUrl)) {
    addUrl(imageUrl);
  } else if (_posterStringLooksFirebaseStorageRelativePath(imageUrl)) {
    addPath(imageUrl);
  }

  addPath(thumbnailStoragePath);

  final tTrim = thumbnailUrl.trim();
  final iTrim = imageUrl.trim();
  if (tTrim.isNotEmpty && tTrim != iTrim) {
    if (isGsUrl(thumbnailUrl) ||
        _posterStringLooksFirebaseResolvable(thumbnailUrl)) {
      addUrl(thumbnailUrl);
    } else if (_posterStringLooksFirebaseStorageRelativePath(thumbnailUrl)) {
      addPath(thumbnailUrl);
    }
  }
  return out;
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
    this.imageStoragePath,
    this.thumbnailStoragePath,
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
    this.primaryFirestoreCategoryId,
    this.categoryDisplayLabel,
    this.personalizationConfig,
    this.createdAtMillis = 0,
    this.preferOriginalPosterQuality = false,
  });

  final String titleTe;
  final String titleHi;
  final String titleEn;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
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
  final int createdAtMillis;

  /// Firestore `categoryId` only — used for home dynamic chips, not label tokens.
  final String? primaryFirestoreCategoryId;

  /// Firestore manual / admin category label for home chip + matching.
  final String? categoryDisplayLabel;
  final CreatorPosterPersonalization? personalizationConfig;
  final bool preferOriginalPosterQuality;

  bool get isVideo =>
      mediaType == 'video' && (videoUrl?.trim().isNotEmpty ?? false);

  String titleFor(AppLanguage language) =>
      _repairLegacyUiText(switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => titleTe,
        SupportedUiLanguage.hindi => titleHi,
        SupportedUiLanguage.english ||
        SupportedUiLanguage.tamil ||
        SupportedUiLanguage.kannada ||
        SupportedUiLanguage.malayalam => titleEn,
      });
}

class _PosterPhotoPreset {
  const _PosterPhotoPreset({
    required this.shape,
    required this.photoRenderMode,
  });

  final String shape;
  final String photoRenderMode;
}

class _PosterPhotoUserAdjustment {
  const _PosterPhotoUserAdjustment({
    required this.xOffsetPercent,
    required this.yOffsetPercent,
    this.preset,
  });

  final double xOffsetPercent;
  final double yOffsetPercent;
  final _PosterPhotoPreset? preset;

  static const _PosterPhotoUserAdjustment none = _PosterPhotoUserAdjustment(
    xOffsetPercent: 0,
    yOffsetPercent: 0,
  );

  String get effectiveShape => preset?.shape ?? '';
  String get effectivePhotoRenderMode => preset?.photoRenderMode ?? '';
}

class _PosterExtraPhotoSelection {
  const _PosterExtraPhotoSelection({
    required this.originalPhotoPath,
    required this.cutoutPhotoPath,
  });

  final String originalPhotoPath;
  final String cutoutPhotoPath;

  bool get hasPhoto =>
      originalPhotoPath.trim().isNotEmpty || cutoutPhotoPath.trim().isNotEmpty;

  PosterProfileData asPosterProfileData() {
    return PosterProfileData(
      nameTelugu: 'Add Photo',
      nameEnglish: 'Add Photo',
      whatsappNumber: '',
      nameFontFamily: 'Anek Telugu Condensed Bold',
      displayNameMode: PosterDisplayNameMode.auto,
      photoPath: cutoutPhotoPath,
      photoUrl: '',
      originalPhotoPath: originalPhotoPath,
      originalPhotoUrl: '',
    );
  }
}

Uint8List _optimizeAdditionalPosterPhotoBytes(Uint8List bytes) {
  return bytes;
}

Uint8List _prepareAdditionalPosterPhotoRemovalBytes(Uint8List bytes) {
  return _optimizeAdditionalPosterPhotoBytes(bytes);
}

class _CategoryChipData {
  const _CategoryChipData({
    required this.slug,
    required this.label,
    this.matchTags = const <String>[],
    this.presenceTags = const <String>[],
    this.isDynamic = false,
  });

  final String slug;
  final String label;
  final List<String> matchTags;
  final List<String> presenceTags;
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

enum _AllFeedBucket { primary, dynamic, motivational, jokes, remaining }

class _HomeTemplateProjection {
  const _HomeTemplateProjection({
    required this.filteredTemplates,
    required this.templates,
  });

  final List<_TemplateItem> filteredTemplates;
  final List<_TemplateItem> templates;
}

class _AllFeedRankingWorkerRequest {
  const _AllFeedRankingWorkerRequest({
    required this.templates,
    required this.slot,
    required this.year,
    required this.month,
    required this.day,
    required this.dynamicTags,
    required this.recentTemplateKeys,
  });

  final List<_TemplateItem> templates;
  final HomeFeedTimeSlot slot;
  final int year;
  final int month;
  final int day;
  final Set<String> dynamicTags;
  final Set<String> recentTemplateKeys;
}

String _normalizeTagWorker(String value) {
  var scratch = value.trim();
  if (scratch.isEmpty) {
    return '';
  }
  for (var round = 0; round < 8; round++) {
    final next = scratch.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (Match match) => '${match.group(1)}_${match.group(2)}',
    );
    if (next == scratch) {
      break;
    }
    scratch = next;
  }
  return scratch
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

Set<String> _expandCategoryAliasesWorker(String normalizedTag) {
  const aliasMap = <String, List<String>>{
    'all': <String>['all'],
    'good_morning': <String>['good_morning', 'morning'],
    'good_afternoon': <String>['good_afternoon', 'afternoon'],
    'good_evening': <String>['good_evening', 'evening'],
    'good_night': <String>['good_night', 'night'],
    'motivational': <String>['motivational'],
    'love_quotes': <String>['love_quotes', 'love'],
    'today_special': <String>['today_special', 'important_day'],
    'birthdays': <String>['birthdays', 'birthday', 'celebration'],
    'life_advice': <String>['life_advice'],
    'gita_wisdom': <String>['gita_wisdom'],
    'devotional': <String>['devotional'],
    'mahabharata': <String>['mahabharata'],
    'anniversary': <String>['anniversary', 'celebration'],
    'good_thoughts': <String>['good_thoughts'],
    'bible': <String>['bible'],
    'islam': <String>['islam'],
    'new': <String>['new', 'today_special'],
    'weekday_special': <String>['weekday_special', 'today_special'],
    'weekday_monday_special': <String>[
      'weekday_monday_special',
      'weekday_special',
      'today_special',
    ],
    'weekday_tuesday_special': <String>[
      'weekday_tuesday_special',
      'weekday_special',
      'today_special',
    ],
    'weekday_wednesday_special': <String>[
      'weekday_wednesday_special',
      'weekday_special',
      'today_special',
    ],
    'weekday_thursday_special': <String>[
      'weekday_thursday_special',
      'weekday_special',
      'today_special',
    ],
    'weekday_friday_special': <String>[
      'weekday_friday_special',
      'weekday_special',
      'today_special',
    ],
    'weekday_saturday_special': <String>[
      'weekday_saturday_special',
      'weekday_special',
      'today_special',
    ],
    'weekday_sunday_special': <String>[
      'weekday_sunday_special',
      'weekday_special',
      'today_special',
    ],
    'important_day': <String>['important_day', 'today_special'],
    'regional_special': <String>['regional_special', 'today_special'],
    'festival': <String>['festival', 'devotional', 'today_special'],
    'jayanthi': <String>['jayanthi', 'important_day', 'regional_special'],
    'vardhanthi': <String>['vardhanthi', 'important_day', 'regional_special'],
  };

  final output = <String>{normalizedTag};
  final aliases = aliasMap[normalizedTag];
  if (aliases != null) {
    output.addAll(aliases.map(_normalizeTagWorker));
  }
  return output;
}

Iterable<String> _categoryLabelTokenTagsWorker(String? label) sync* {
  if (label == null || label.trim().isEmpty) {
    return;
  }
  final norm = _normalizeTagWorker(label);
  if (norm.isNotEmpty) {
    yield norm;
  }
  for (final word in label.toLowerCase().split(RegExp(r'\s+'))) {
    final normalized = _normalizeTagWorker(word);
    if (normalized.length > 2) {
      yield normalized;
    }
  }
}

void _addNormalizedSourceTagsWorker(Set<String> tags, String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return;
  }

  final normalized = _normalizeTagWorker(trimmed);
  if (normalized.isNotEmpty) {
    tags.addAll(_expandCategoryAliasesWorker(normalized));
  }

  final words = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  for (final word in words) {
    tags.addAll(_expandCategoryAliasesWorker(_normalizeTagWorker(word)));
  }

  if (words.length >= 2) {
    for (var i = 0; i < words.length - 1; i++) {
      tags.addAll(
        _expandCategoryAliasesWorker(
          _normalizeTagWorker('${words[i]} ${words[i + 1]}'),
        ),
      );
    }
  }
}

List<String> _inferTemplateCategoryTagsWorker({
  required List<String> seedTags,
  required List<String?> sources,
}) {
  final tags = <String>{...seedTags.map(_normalizeTagWorker)};
  final cleanSources = sources
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  for (final source in cleanSources) {
    _addNormalizedSourceTagsWorker(tags, source);
  }
  final normalized = cleanSources.map((value) => value.toLowerCase()).join(' ');

  void add(String tag) => tags.add(_normalizeTagWorker(tag));

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
  if (normalized.contains('evening')) {
    add('good_evening');
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

_TemplateItem _mapApprovedCreatorTemplateWorker(
  ApprovedCreatorTemplate template,
) {
  final creatorId = template.creatorPublicId.trim();
  final displayTitle = creatorId.isNotEmpty ? creatorId : template.title;
  final rawCategoryId = template.categoryId.trim();
  final categoryLabel = template.categoryLabel.trim();
  final inferredTags = _inferTemplateCategoryTagsWorker(
    seedTags: rawCategoryId.isNotEmpty
        ? <String>[rawCategoryId]
        : const <String>[],
    sources: <String?>[
      categoryLabel.isNotEmpty ? categoryLabel : null,
      rawCategoryId.isNotEmpty ? rawCategoryId : null,
      if (rawCategoryId.isEmpty && categoryLabel.isEmpty) template.title,
    ],
  );
  final tagSet = <String>{...inferredTags};
  if (rawCategoryId.isNotEmpty) {
    tagSet.add(rawCategoryId);
    tagSet.add(_normalizeTagWorker(rawCategoryId));
    tagSet.addAll(
      _categoryLabelTokenTagsWorker(
        categoryLabel.isNotEmpty ? categoryLabel : null,
      ),
    );
  }
  final categoryTags = tagSet
      .where((tag) => tag.trim().isNotEmpty)
      .toList(growable: false);

  return _TemplateItem(
    titleTe: displayTitle,
    titleHi: displayTitle,
    titleEn: displayTitle,
    templateId: template.id,
    imageUrl: template.imageUrl,
    imageStoragePath: template.imageStoragePath.trim().isNotEmpty
        ? template.imageStoragePath
        : null,
    thumbnailStoragePath: template.thumbnailStoragePath.trim().isNotEmpty
        ? template.thumbnailStoragePath
        : null,
    thumbnailUrl: template.thumbnailUrl,
    mediaType: template.mediaType,
    videoUrl: template.videoUrl,
    categoryTags: categoryTags,
    primaryFirestoreCategoryId: rawCategoryId.isNotEmpty ? rawCategoryId : null,
    categoryDisplayLabel: categoryLabel.isNotEmpty ? categoryLabel : null,
    personalizationConfig: template.personalizationConfig,
    createdAtMillis: template.createdAtMillis,
    pageConfig: template.pageConfig,
    preferOriginalPosterQuality:
        creatorId == 'community_user' ||
        _shouldPreferOriginalPosterQualitySource(template.imageStoragePath) ||
        _shouldPreferOriginalPosterQualitySource(template.imageUrl) ||
        _shouldPreferOriginalPosterQualitySource(
          template.thumbnailStoragePath,
        ) ||
        _shouldPreferOriginalPosterQualitySource(template.thumbnailUrl),
  );
}

List<_TemplateItem> _mapApprovedCreatorTemplatesWorker(
  List<ApprovedCreatorTemplate> templates,
) {
  return templates
      .map(_mapApprovedCreatorTemplateWorker)
      .toList(growable: false);
}

String _templateSequenceKeyWorker(_TemplateItem item) {
  final id = item.templateId?.trim() ?? '';
  if (id.isNotEmpty) {
    return id;
  }
  final image = item.imageUrl?.trim() ?? '';
  if (image.isNotEmpty) {
    return image;
  }
  final storage = item.imageStoragePath?.trim() ?? '';
  if (storage.isNotEmpty) {
    return storage;
  }
  final video = item.videoUrl?.trim() ?? '';
  return '${item.titleEn}|$video';
}

List<_TemplateItem> _mergeTemplateListsWorker(
  List<List<_TemplateItem>> batches,
) {
  final merged = <_TemplateItem>[];
  final seenKeys = <String>{};
  for (final batch in batches) {
    for (final item in batch) {
      if (seenKeys.add(_templateSequenceKeyWorker(item))) {
        merged.add(item);
      }
    }
  }
  return merged;
}

bool _matchesPriorityTagWorker(_TemplateItem item, Set<String> priorityTags) {
  final primaryCategory = _normalizeTagWorker(
    item.primaryFirestoreCategoryId ?? '',
  );
  if (primaryCategory.isNotEmpty &&
      _expandCategoryAliasesWorker(
        primaryCategory,
      ).intersection(priorityTags).isNotEmpty) {
    return true;
  }
  for (final tag in item.categoryTags) {
    final normalized = _normalizeTagWorker(tag);
    if (normalized.isEmpty) {
      continue;
    }
    if (_expandCategoryAliasesWorker(
      normalized,
    ).intersection(priorityTags).isNotEmpty) {
      return true;
    }
  }
  return false;
}

String _allCategoryGroupingKeyWorker(_TemplateItem item) {
  final primary = _normalizeTagWorker(item.primaryFirestoreCategoryId ?? '');
  if (primary.isNotEmpty && primary != 'all') {
    return primary;
  }
  for (final tag in item.categoryTags) {
    final normalized = _normalizeTagWorker(tag);
    if (normalized.isNotEmpty && normalized != 'all') {
      return normalized;
    }
  }
  return item.templateId?.trim().isNotEmpty == true
      ? item.templateId!.trim()
      : item.titleEn.trim();
}

List<_TemplateItem> _spreadAllCategoryTemplateGroupsWorker(
  List<_TemplateItem> templates, {
  required int seed,
}) {
  if (templates.length < 3) {
    return templates;
  }
  final grouped = <String, List<_TemplateItem>>{};
  for (final item in templates) {
    final key = _allCategoryGroupingKeyWorker(item);
    grouped.putIfAbsent(key, () => <_TemplateItem>[]).add(item);
  }
  if (grouped.length < 2) {
    return templates;
  }
  final bucketKeys = grouped.keys.toList(growable: false)
    ..sort((a, b) => Object.hash(seed, a).compareTo(Object.hash(seed, b)));
  final arranged = <_TemplateItem>[];
  var emitted = 0;
  while (emitted < templates.length) {
    var addedThisRound = false;
    for (final key in bucketKeys) {
      final bucket = grouped[key];
      if (bucket == null || bucket.isEmpty) {
        continue;
      }
      arranged.add(bucket.removeAt(0));
      emitted++;
      addedThisRound = true;
    }
    if (!addedThisRound) {
      break;
    }
  }
  return arranged;
}

List<_TemplateItem> _blendAllFeedPriorityBucketsWorker({
  required List<_TemplateItem> primaryPriority,
  required List<_TemplateItem> dynamicPriority,
  required List<_TemplateItem> motivationalPriority,
  required List<_TemplateItem> jokesPriority,
  required List<_TemplateItem> remaining,
  required HomeFeedTimeSlot slot,
}) {
  final primaryQueue = List<_TemplateItem>.of(primaryPriority);
  final dynamicQueue = List<_TemplateItem>.of(dynamicPriority);
  final motivationalQueue = List<_TemplateItem>.of(motivationalPriority);
  final jokesQueue = List<_TemplateItem>.of(jokesPriority);
  final remainingQueue = List<_TemplateItem>.of(remaining);
  final blended = <_TemplateItem>[];
  final earlyPattern = switch (slot) {
    HomeFeedTimeSlot.morning ||
    HomeFeedTimeSlot.afternoon ||
    HomeFeedTimeSlot.evening => const <_AllFeedBucket>[
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.motivational,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.jokes,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.remaining,
    ],
    HomeFeedTimeSlot.funEvening => const <_AllFeedBucket>[
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.motivational,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.remaining,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.motivational,
      _AllFeedBucket.remaining,
    ],
    HomeFeedTimeSlot.night => const <_AllFeedBucket>[
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.jokes,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.motivational,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.jokes,
      _AllFeedBucket.remaining,
    ],
  };
  final steadyPattern = switch (slot) {
    HomeFeedTimeSlot.morning ||
    HomeFeedTimeSlot.afternoon ||
    HomeFeedTimeSlot.evening => const <_AllFeedBucket>[
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.remaining,
      _AllFeedBucket.motivational,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.remaining,
      _AllFeedBucket.jokes,
    ],
    HomeFeedTimeSlot.funEvening => const <_AllFeedBucket>[
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.remaining,
      _AllFeedBucket.motivational,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.remaining,
    ],
    HomeFeedTimeSlot.night => const <_AllFeedBucket>[
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.primary,
      _AllFeedBucket.remaining,
      _AllFeedBucket.jokes,
      _AllFeedBucket.primary,
      _AllFeedBucket.dynamic,
      _AllFeedBucket.motivational,
      _AllFeedBucket.remaining,
    ],
  };

  String? lastCategoryKey;

  List<_TemplateItem> queueFor(_AllFeedBucket bucket) {
    return switch (bucket) {
      _AllFeedBucket.primary => primaryQueue,
      _AllFeedBucket.dynamic => dynamicQueue,
      _AllFeedBucket.motivational => motivationalQueue,
      _AllFeedBucket.jokes => jokesQueue,
      _AllFeedBucket.remaining => remainingQueue,
    };
  }

  _TemplateItem? takeWithoutImmediateRepeat(List<_TemplateItem> queue) {
    if (queue.isEmpty) {
      return null;
    }
    if (lastCategoryKey == null) {
      return queue.removeAt(0);
    }
    final alternateIndex = queue.indexWhere(
      (item) => _allCategoryGroupingKeyWorker(item) != lastCategoryKey,
    );
    if (alternateIndex <= 0) {
      return queue.removeAt(0);
    }
    return queue.removeAt(alternateIndex);
  }

  void pushFrom(_AllFeedBucket preferredBucket) {
    final fallbackOrder = switch (preferredBucket) {
      _AllFeedBucket.primary => <_AllFeedBucket>[
        _AllFeedBucket.primary,
        _AllFeedBucket.dynamic,
        _AllFeedBucket.motivational,
        _AllFeedBucket.jokes,
        _AllFeedBucket.remaining,
      ],
      _AllFeedBucket.dynamic => <_AllFeedBucket>[
        _AllFeedBucket.dynamic,
        _AllFeedBucket.primary,
        _AllFeedBucket.motivational,
        _AllFeedBucket.jokes,
        _AllFeedBucket.remaining,
      ],
      _AllFeedBucket.motivational => <_AllFeedBucket>[
        _AllFeedBucket.motivational,
        _AllFeedBucket.dynamic,
        _AllFeedBucket.primary,
        _AllFeedBucket.jokes,
        _AllFeedBucket.remaining,
      ],
      _AllFeedBucket.jokes => <_AllFeedBucket>[
        _AllFeedBucket.jokes,
        _AllFeedBucket.dynamic,
        _AllFeedBucket.primary,
        _AllFeedBucket.motivational,
        _AllFeedBucket.remaining,
      ],
      _AllFeedBucket.remaining => <_AllFeedBucket>[
        _AllFeedBucket.remaining,
        _AllFeedBucket.primary,
        _AllFeedBucket.dynamic,
        _AllFeedBucket.motivational,
        _AllFeedBucket.jokes,
      ],
    };
    for (final bucket in fallbackOrder) {
      final item = takeWithoutImmediateRepeat(queueFor(bucket));
      if (item == null) {
        continue;
      }
      blended.add(item);
      lastCategoryKey = _allCategoryGroupingKeyWorker(item);
      return;
    }
  }

  for (final bucket in earlyPattern) {
    if (primaryQueue.isEmpty &&
        dynamicQueue.isEmpty &&
        motivationalQueue.isEmpty &&
        jokesQueue.isEmpty &&
        remainingQueue.isEmpty) {
      break;
    }
    pushFrom(bucket);
  }

  var steadyIndex = 0;
  while (primaryQueue.isNotEmpty ||
      dynamicQueue.isNotEmpty ||
      motivationalQueue.isNotEmpty ||
      jokesQueue.isNotEmpty ||
      remainingQueue.isNotEmpty) {
    pushFrom(steadyPattern[steadyIndex % steadyPattern.length]);
    steadyIndex++;
  }

  return blended;
}

List<_TemplateItem> _promoteDynamicAllFeedStartupBatchWorker(
  List<_TemplateItem> templates, {
  required Set<String> dynamicTags,
  int maxLeadingDynamic = 2,
}) {
  if (templates.length < 2 || dynamicTags.isEmpty || maxLeadingDynamic <= 0) {
    return templates;
  }
  final leadingDynamic = <_TemplateItem>[];
  final remainder = <_TemplateItem>[];
  for (final item in templates) {
    if (leadingDynamic.length < maxLeadingDynamic &&
        _matchesPriorityTagWorker(item, dynamicTags)) {
      leadingDynamic.add(item);
    } else {
      remainder.add(item);
    }
  }
  if (leadingDynamic.isEmpty) {
    return templates;
  }
  return <_TemplateItem>[...leadingDynamic, ...remainder];
}

List<_TemplateItem> _rankAllFeedTemplatesWorker(
  _AllFeedRankingWorkerRequest request,
) {
  final templates = request.templates;
  if (templates.length < 2) {
    return templates;
  }
  final startOfTodayMillis = IstTimeService.startOfDayUtcMillis(
    DateTime(request.year, request.month, request.day),
  );
  final endOfTodayMillis = startOfTodayMillis + IstTimeService.dayMillis;
  final freshTemplates = templates
      .where((item) {
        final createdAtMillis = item.createdAtMillis;
        return createdAtMillis >= startOfTodayMillis &&
            createdAtMillis < endOfTodayMillis;
      })
      .toList(growable: false);
  final effectiveTemplates = freshTemplates.isNotEmpty
      ? freshTemplates
      : templates;
  if (effectiveTemplates.length < 2) {
    return effectiveTemplates;
  }

  final seed = Object.hash(
    request.year,
    request.month,
    request.day,
    request.slot.name,
    freshTemplates.isNotEmpty,
  );
  final shuffled = List<_TemplateItem>.of(effectiveTemplates, growable: false)
    ..sort((a, b) {
      final aKey = Object.hash(
        seed,
        a.templateId ?? '',
        a.imageUrl ?? '',
        a.thumbnailUrl ?? '',
        a.titleEn,
      );
      final bKey = Object.hash(
        seed,
        b.templateId ?? '',
        b.imageUrl ?? '',
        b.thumbnailUrl ?? '',
        b.titleEn,
      );
      return aKey.compareTo(bKey);
    });
  if (request.recentTemplateKeys.isNotEmpty) {
    shuffled.sort((a, b) {
      final aRecent = request.recentTemplateKeys.contains(
        _templateSequenceKeyWorker(a),
      );
      final bRecent = request.recentTemplateKeys.contains(
        _templateSequenceKeyWorker(b),
      );
      if (aRecent == bRecent) {
        return 0;
      }
      return aRecent ? 1 : -1;
    });
  }
  final spreadTemplates = _spreadAllCategoryTemplateGroupsWorker(
    shuffled,
    seed: seed,
  );
  final orderedPriorityTags =
      TimeSlotService.prioritizedCategoryTagsForHomeFeed(
            DateTime(
              request.year,
              request.month,
              request.day,
              switch (request.slot) {
                HomeFeedTimeSlot.morning => 9,
                HomeFeedTimeSlot.afternoon => 13,
                HomeFeedTimeSlot.evening => 17,
                HomeFeedTimeSlot.funEvening => 19,
                HomeFeedTimeSlot.night => 22,
              },
            ),
          )
          .map(_normalizeTagWorker)
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);
  final priorityTags = orderedPriorityTags.toSet();
  if (priorityTags.isEmpty && request.dynamicTags.isEmpty) {
    return spreadTemplates;
  }

  final primaryPriority = <_TemplateItem>[];
  final dynamicPriority = <_TemplateItem>[];
  final motivationalPriority = <_TemplateItem>[];
  final jokesPriority = <_TemplateItem>[];
  final remaining = <_TemplateItem>[];
  final primaryTag = orderedPriorityTags.isNotEmpty
      ? orderedPriorityTags.first
      : null;
  final motivationalTags = orderedPriorityTags.contains('motivational')
      ? const <String>{'motivational'}
      : const <String>{};
  final jokesTags = orderedPriorityTags.contains('jokes')
      ? const <String>{'jokes'}
      : const <String>{};
  for (final item in spreadTemplates) {
    if (primaryTag != null &&
        _matchesPriorityTagWorker(item, <String>{primaryTag})) {
      primaryPriority.add(item);
    } else if (request.dynamicTags.isNotEmpty &&
        _matchesPriorityTagWorker(item, request.dynamicTags)) {
      dynamicPriority.add(item);
    } else if (motivationalTags.isNotEmpty &&
        _matchesPriorityTagWorker(item, motivationalTags)) {
      motivationalPriority.add(item);
    } else if (jokesTags.isNotEmpty &&
        _matchesPriorityTagWorker(item, jokesTags)) {
      jokesPriority.add(item);
    } else {
      remaining.add(item);
    }
  }
  if (primaryPriority.isEmpty &&
      dynamicPriority.isEmpty &&
      motivationalPriority.isEmpty &&
      jokesPriority.isEmpty) {
    return spreadTemplates;
  }
  return _blendAllFeedPriorityBucketsWorker(
    primaryPriority: primaryPriority,
    dynamicPriority: dynamicPriority,
    motivationalPriority: motivationalPriority,
    jokesPriority: jokesPriority,
    remaining: remaining,
    slot: request.slot,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialCategorySlug,
    this.initialNotificationPayload,
  });

  final String? initialCategorySlug;
  final Map<String, dynamic>? initialNotificationPayload;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AppLanguageStateMixin, RouteAware, WidgetsBindingObserver {
  static const String _allCategorySlug = 'all';
  static const String _startupTemplateSnapshotKey =
      'home_startup_template_snapshot_v1';
  static const int _templatesPageSize = 12;
  static const int _promoSlidesLimit = 5;
  static const int _startupCacheWarmTemplatesPageSize = 3;
  static const String _homeFeedRatedKey = 'home_feed_rate_card_completed_v1';
  static const String _homeReferralPromptKeyPrefix =
      'mana_poster_home_referral_prompt_dismissed_';
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
    'devotional',
    'mahabharata',
    'anniversary',
    'good_thoughts',
    'bible',
    'islam',
    'jokes',
    'new',
  ];
  static const int _initialTemplatesPageSize = 8;
  static const int _initialPriorityPrimaryFetchSize = 4;
  static const int _initialPrioritySecondaryFetchSize = 2;
  static const int _startupInitialVisibleTemplateCount = 4;
  static const int _startupMergeBatchSize = 6;
  static const int _smallMappingBatchSize = 8;
  static const int _smallMergeBatchInputCount = 16;
  static const int _startupSnapshotTemplateCount = 8;
  static const int _startupSnapshotMinimumVisibleCount = 4;
  static const Duration _startupSnapshotHydrationDelay = Duration(
    milliseconds: 450,
  );
  static const double _homeFeedCacheExtent = 48.0;

  final DynamicCategoryService _dynamicCategoryService =
      const DynamicCategoryService(daysBeforeEvent: 7);
  final AppHomeBannerService _appHomeBannerService =
      const AppHomeBannerService();
  final ApprovedCreatorTemplateService _approvedCreatorTemplateService =
      ApprovedCreatorTemplateService();
  final ManualEventCategoryService _manualEventCategoryService =
      const ManualEventCategoryService();
  final ScrollController _posterScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategorySlug = _allCategorySlug;
  Set<String> _selectedPoliticalPartyIds = <String>{};
  AppReligionPreference _religionPreference = AppReligionPreference.all;
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
  final int _posterRenderCycle = 0;
  bool _templatesLoading = true;
  bool _templatesLoadingMore = false;
  bool _templatesHasMore = true;
  bool _religionSelectionReady = false;
  String? _categoryLoadingSlug;
  int _categoryLoadGeneration = 0;
  bool _hasRatedApp = false;
  String _installedAppVersion = '';
  bool _posterPhotoDragInProgress = false;
  List<_TemplateItem> _remoteApprovedTemplates = const <_TemplateItem>[];
  List<AppHomeBanner> _homeBanners = const <AppHomeBanner>[];
  QueryDocumentSnapshot<Map<String, dynamic>>? _templatesLastDocument;
  Future<void>? _homeBannersLoadFuture;
  Future<void>? _approvedTemplatesLoadFuture;
  Future<void>? _manualEventCategoriesLoadFuture;
  Future<void>? _partyPreferenceLoadFuture;
  Future<void>? _viewerProfileLoadFuture;
  bool _referralPromptShowing = false;
  final Set<String> _hydratedCategorySlugs = <String>{};
  List<DynamicCategory> _manualEventCategories = const <DynamicCategory>[];
  final Map<String, bool> _dynamicCategoryAvailabilityBySlug = <String, bool>{};
  final Set<String> _dynamicCategoryAvailabilityInFlight = <String>{};
  String _lastCategoryDebugSnapshot = '';
  String _dynamicCategoryAvailabilitySignature = '';
  _HomeTemplateProjection? _templateProjectionCache;
  Object? _templateProjectionIdentity;
  List<_CategoryChipData>? _categoryListCache;
  Object? _categoryListIdentity;
  AppLanguage? _manualCategoryLanguage;
  bool _adFallbackSlotEnabled = false;
  HomeFeedTimeSlot _activeHomeFeedTimeSlot = TimeSlotService.homeFeedSlot(
    IstTimeService.now(),
  );
  final Stopwatch _startupStopwatch = Stopwatch()..start();
  bool _loggedFirstFeedProjection = false;
  bool _loggedFirstTemplatesPaint = false;
  bool _loggedFirstVisibleUi = false;
  bool _loggedFirstCachedFeedPaint = false;
  bool _loggedFirstRemoteFeedPaint = false;
  bool _loggedRankingComplete = false;
  bool _allFeedRankingReady = false;
  bool _allFeedRankingInFlight = false;
  bool _progressiveHydrationQueued = false;
  bool _posterFeedLoadMoreArmed = false;
  bool _startupRichPosterPreviewReady = false;
  bool _startupRichPosterPreviewActivationQueued = false;
  bool _startupSnapshotHydrationDeferred = false;
  bool _startupSnapshotAttemptCompleted = false;
  bool _startupPermissionPromptQueued = false;
  List<_TemplateItem>? _rankedAllFeedTemplates;
  List<_TemplateItem>? _lockedAllFeedTemplates;
  Set<String> _recentAllFeedTemplateKeys = <String>{};
  Timer? _startupSnapshotPersistTimer;

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
    _homeDebugLog('[StartupTiming] home_init_start t=0ms');
    final initialCategory = widget.initialCategorySlug?.trim();
    if (initialCategory != null && initialCategory.isNotEmpty) {
      _selectedCategorySlug = initialCategory;
    }
    WidgetsBinding.instance.addObserver(this);
    _posterScrollController.addListener(_onPosterScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hidePhoneNavigationButtons());
      unawaited(ScreenSecurityService.enableSecure());
      unawaited(_loadReligionPreference());
      unawaited(_loadPartyPreference());
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 40),
        _loadStartupTemplateSnapshot,
      );
      _homeDebugLog(
        '[StartupTiming] first_frame t=${_startupStopwatch.elapsedMilliseconds}ms',
      );
      if (!_loggedFirstVisibleUi) {
        _loggedFirstVisibleUi = true;
        _homeDebugLog(
          '[StartupTiming] first_visible_ui=${_startupStopwatch.elapsedMilliseconds}ms',
        );
      }
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 120),
        _loadApprovedCreatorTemplatesAfterStartup,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 140),
        _loadManualEventCategories,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 900),
        _loadViewerPosterProfile,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 300),
        _loadPromoCardPreferences,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 700),
        _loadInstalledAppVersion,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 1300),
        _handlePlayStoreEngagementOnHomeOpen,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 1100),
        _loadHomeBanners,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 1600),
        _showReferralPromptIfNeeded,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 2200),
        _requestStartupPermissionsIfNeeded,
      );
      _scheduleDeferredHomeStartupTask(const Duration(seconds: 12), () async {
        if (!mounted || _adFallbackSlotEnabled) {
          return;
        }
        setState(() => _adFallbackSlotEnabled = true);
      });
    });
  }

  void _scheduleDeferredHomeStartupTask(
    Duration delay,
    Future<void> Function() task,
  ) {
    unawaited(() async {
      await Future<void>.delayed(delay);
      if (!mounted) {
        return;
      }
      await task();
    }());
  }

  Future<void> _loadApprovedCreatorTemplatesAfterStartup() async {
    var waitCycles = 0;
    while (!_startupSnapshotAttemptCompleted && waitCycles < 8) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) {
        return;
      }
      waitCycles++;
    }
    await FirebaseBootstrap.ensureInitialized();
    if (!mounted) {
      return;
    }
    if (_remoteApprovedTemplates.isNotEmpty) {
      await Future<void>.delayed(_startupSnapshotHydrationDelay);
      if (!mounted) {
        return;
      }
    }
    await _loadApprovedCreatorTemplates();
  }

  Future<void> _loadManualEventCategories() async {
    final inFlight = _manualEventCategoriesLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      await FirebaseBootstrap.ensureInitialized();
      if (!mounted) {
        return;
      }
      final categories = await _manualEventCategoryService
          .fetchVisibleCategories(language: context.currentLanguage);
      if (!mounted) {
        return;
      }
      _homeDebugLog(
        '[ManualCategories] loaded=${categories.map((item) => item.slug).join(",")}',
      );
      setState(() {
        _manualEventCategories = categories;
      });
      _categoryListCache = null;
      _categoryListIdentity = null;
    }();
    _manualEventCategoriesLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_manualEventCategoriesLoadFuture, future)) {
        _manualEventCategoriesLoadFuture = null;
      }
    }
  }

  Future<void> _requestStartupPermissionsIfNeeded() async {
    if (_startupPermissionPromptQueued || kIsWeb || !mounted) {
      return;
    }
    _startupPermissionPromptQueued = true;
    try {
      final alreadyHandled =
          await AppFlowService.resolvePermissionsStepHandled();
      final permissionService = PermissionService();
      final snapshot = await permissionService.getSnapshot();
      if (!mounted) {
        return;
      }
      if (snapshot.allGranted) {
        await AppFlowService.markPermissionsStepHandled();
        await NotificationService.instance.syncCurrentPreferences();
        await AppLocationService.instance.requestAndSyncApproxLocation();
        return;
      }
      final bool shouldRecoverStaleHandledState =
          alreadyHandled &&
          snapshot.items.every(
            (AppPermissionState item) =>
                item.isDenied && !item.isPermanentlyDenied,
          );
      if (alreadyHandled && !shouldRecoverStaleHandledState) {
        return;
      }
      if (shouldRecoverStaleHandledState) {
        await AppFlowService.resetPermissionsStep();
      }
      await _awaitStartupUiSettled(
        minimumDelay: const Duration(milliseconds: 280),
      );
      if (!mounted) {
        return;
      }
      final updatedSnapshot = await permissionService
          .requestEssentialPermissions();
      await AppFlowService.markPermissionsStepHandled();
      await NotificationService.instance.syncCurrentPreferences();
      if (updatedSnapshot.location.isGranted) {
        await AppLocationService.instance.requestAndSyncApproxLocation();
      }
    } catch (error, stackTrace) {
      _homeDebugLogStack(
        'startup permission request skipped: $error',
        stackTrace,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLanguage = context.currentLanguage;
    if (_manualCategoryLanguage != currentLanguage) {
      _manualCategoryLanguage = currentLanguage;
      unawaited(_loadManualEventCategories());
    }
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
    unawaited(_loadPartyPreference());
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
      _refreshHomeFeedTimeSlotIfNeeded();
      unawaited(_loadPartyPreference());
      unawaited(PlayEngagementService.instance.handleAppResume());
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
    _startupSnapshotPersistTimer?.cancel();
    _posterScrollController
      ..removeListener(_onPosterScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    unawaited(_restorePhoneNavigationButtons());
    unawaited(ScreenSecurityService.disableSecure());
    super.dispose();
  }

  Future<void> _loadPartyPreference() async {
    final inFlight = _partyPreferenceLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      final selection = await AppPartyPreferenceService.loadSelection();
      if (!mounted || setEquals(_selectedPoliticalPartyIds, selection)) {
        return;
      }
      setState(() {
        _selectedPoliticalPartyIds = selection;
        _categoryListCache = null;
        _categoryListIdentity = null;
        _templateProjectionCache = null;
        _templateProjectionIdentity = null;
      });
    }();
    _partyPreferenceLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_partyPreferenceLoadFuture, future)) {
        _partyPreferenceLoadFuture = null;
      }
    }
  }

  Future<void> _loadReligionPreference() async {
    AppReligionPreference selection = AppReligionPreference.all;
    try {
      selection =
          await AppReligionService.loadSelection() ?? AppReligionPreference.all;
    } catch (_) {}
    if (!mounted) {
      return;
    }
    final categoryWillReset = _isCategoryHiddenForReligion(
      _selectedCategorySlug,
    );
    if (_religionSelectionReady &&
        _religionPreference == selection &&
        !categoryWillReset) {
      return;
    }
    setState(() {
      _religionPreference = selection;
      _religionSelectionReady = true;
      if (categoryWillReset) {
        _selectedCategorySlug = _allCategorySlug;
        _categoryLoadingSlug = null;
      }
    });
  }

  Set<String> _hiddenCategorySlugsForReligion() {
    return AppReligionService.hiddenCategorySlugsFor(_religionPreference);
  }

  bool _isCategoryHiddenForReligion(String slug) {
    final normalized = _normalizeTag(slug);
    if (normalized.isEmpty || normalized == _allCategorySlug) {
      return false;
    }
    return _hiddenCategorySlugsForReligion().contains(normalized);
  }

  Set<String> _hiddenCategoryTagsForReligion() {
    final tags = <String>{};
    for (final slug in _hiddenCategorySlugsForReligion()) {
      tags.add(_normalizeTag(slug));
      for (final tag in _defaultCategoryTagsForSlug(slug)) {
        final normalized = _normalizeTag(tag);
        if (normalized.isNotEmpty) {
          tags.addAll(_expandCategoryAliases(normalized));
        }
      }
    }
    return tags;
  }

  bool _isTemplateHiddenForReligion(_TemplateItem item) {
    final hiddenTags = _hiddenCategoryTagsForReligion();
    if (hiddenTags.isEmpty) {
      return false;
    }

    final primaryFirestore = item.primaryFirestoreCategoryId?.trim() ?? '';
    if (primaryFirestore.isNotEmpty &&
        hiddenTags.contains(_normalizeTag(primaryFirestore))) {
      return true;
    }

    final itemTags = <String>{};
    for (final tag in item.categoryTags) {
      final normalized = _normalizeTag(tag);
      if (normalized.isNotEmpty) {
        itemTags.addAll(_expandCategoryAliases(normalized));
      }
    }
    return itemTags.intersection(hiddenTags).isNotEmpty;
  }

  List<_CategoryChipData> _filterCategoriesByReligion(
    List<_CategoryChipData> categories,
  ) {
    return categories
        .where((chip) => !_isCategoryHiddenForReligion(chip.slug))
        .toList(growable: false);
  }

  bool _matchesTemplate(
    _TemplateItem item,
    AppLanguage language,
    _CategoryChipData selectedCategory,
  ) {
    if (_isTemplateHiddenForReligion(item)) {
      return false;
    }

    final query = _searchController.text.trim().toLowerCase();
    final searchable = <String>[
      item.titleEn,
      item.titleHi,
      item.titleTe,
      item.titleFor(language),
      item.primaryFirestoreCategoryId ?? '',
      item.categoryDisplayLabel ?? '',
      ...item.categoryTags,
    ].join(' ').toLowerCase();

    if (query.isNotEmpty && !searchable.contains(query)) {
      return false;
    }

    if (selectedCategory.slug == _allCategorySlug) {
      return _matchesActiveAllFeedTimeSlot(item);
    }

    final itemSignals = _templateCategorySignalsForMatching(item);
    final categorySignals = selectedCategory.isDynamic
        ? _strictDynamicCategorySignals(selectedCategory)
        : _categorySignalsForMatching(selectedCategory);
    if (itemSignals.intersection(categorySignals).isNotEmpty) {
      return true;
    }

    if (selectedCategory.isDynamic) {
      return false;
    }

    final fallbackNeedle = _normalizeTag(selectedCategory.label);
    return fallbackNeedle.isNotEmpty && searchable.contains(fallbackNeedle);
  }

  bool _matchesActiveAllFeedTimeSlot(_TemplateItem item) {
    final itemTemporalTags = _templateTemporalSignals(item);
    if (itemTemporalTags.isEmpty) {
      return true;
    }
    final activeTags = _timeSlotSignals(_activeHomeFeedTimeSlot);
    return itemTemporalTags.intersection(activeTags).isNotEmpty;
  }

  Set<String> _templateTemporalSignals(_TemplateItem item) {
    final signals = <String>{};
    for (final tag in item.categoryTags) {
      final normalized = _normalizeTag(tag);
      if (normalized.isEmpty) {
        continue;
      }
      signals.addAll(
        _expandCategoryAliases(normalized).where(
          (alias) =>
              alias == 'good_morning' ||
              alias == 'morning' ||
              alias == 'good_afternoon' ||
              alias == 'afternoon' ||
              alias == 'good_evening' ||
              alias == 'evening' ||
              alias == 'good_night' ||
              alias == 'night',
        ),
      );
    }
    return signals;
  }

  Set<String> _timeSlotSignals(HomeFeedTimeSlot slot) {
    return switch (slot) {
      HomeFeedTimeSlot.morning => const <String>{'good_morning', 'morning'},
      HomeFeedTimeSlot.afternoon => const <String>{
        'good_afternoon',
        'afternoon',
      },
      HomeFeedTimeSlot.evening ||
      HomeFeedTimeSlot.funEvening => const <String>{'good_evening', 'evening'},
      HomeFeedTimeSlot.night => const <String>{'good_night', 'night'},
    };
  }

  String _normalizedCategoryForDebug(_TemplateItem item) {
    final primary = item.primaryFirestoreCategoryId?.trim() ?? '';
    if (primary.isNotEmpty) {
      return _normalizeTag(primary);
    }
    for (final tag in item.categoryTags) {
      final normalized = _normalizeTag(tag);
      if (normalized.isNotEmpty && normalized != _allCategorySlug) {
        return normalized;
      }
    }
    return '';
  }

  Map<String, int> _countTemplatesByCategory(Iterable<_TemplateItem> items) {
    final out = <String, int>{};
    for (final item in items) {
      final key = _normalizedCategoryForDebug(item);
      out[key] = (out[key] ?? 0) + 1;
    }
    return out;
  }

  void _debugLogCategoryPipeline({
    required AppLanguage language,
    required _CategoryChipData selectedCategory,
    required List<_TemplateItem> filteredTemplates,
    required List<_TemplateItem> finalTemplates,
    required int feedEntriesCount,
  }) {
    if (!kDebugMode) {
      return;
    }
    final selectedSlug = _normalizeTag(selectedCategory.slug);
    final allCounts = _countTemplatesByCategory(_remoteApprovedTemplates);
    final filteredCounts = _countTemplatesByCategory(filteredTemplates);
    final finalCounts = _countTemplatesByCategory(finalTemplates);
    final selectedMatchCount = _remoteApprovedTemplates
        .where((item) => _matchesTemplate(item, language, selectedCategory))
        .length;
    final selectedPrimaryExactCount = _remoteApprovedTemplates
        .where(
          (item) =>
              _normalizeTag(item.primaryFirestoreCategoryId?.trim() ?? '') ==
              selectedSlug,
        )
        .length;
    final snapshot =
        'slug=$selectedSlug remote=${_remoteApprovedTemplates.length} '
        'selectedMatch=$selectedMatchCount selectedPrimaryExact=$selectedPrimaryExactCount '
        'filtered=${filteredTemplates.length} final=${finalTemplates.length} '
        'feedEntries=$feedEntriesCount hasMore=$_templatesHasMore '
        'all=$allCounts filteredByCategory=$filteredCounts finalByCategory=$finalCounts';
    if (snapshot == _lastCategoryDebugSnapshot) {
      return;
    }
    _lastCategoryDebugSnapshot = snapshot;
    _homeDebugLog('[PosterUI] $snapshot');
  }

  Set<String> _activeDynamicAllFeedTags(AppLanguage language) {
    final dynamicCategories = _buildDynamicCategories(
      IstTimeService.now(),
      language,
      templatesLoading: false,
    );
    final tags = <String>{};
    for (final category in dynamicCategories) {
      final slug = _normalizeTag(category.slug);
      if (slug.isEmpty ||
          slug == _allCategorySlug ||
          _staticCategorySlugs.contains(category.slug)) {
        continue;
      }
      tags.add(slug);
      for (final tag in category.matchTags) {
        final normalized = _normalizeTag(tag);
        if (normalized.isNotEmpty) {
          tags.add(normalized);
        }
      }
    }
    return tags;
  }

  DateTime _slotReferenceTime(HomeFeedTimeSlot slot) {
    final now = IstTimeService.now();
    final hour = switch (slot) {
      HomeFeedTimeSlot.morning => 9,
      HomeFeedTimeSlot.afternoon => 13,
      HomeFeedTimeSlot.evening => 17,
      HomeFeedTimeSlot.funEvening => 19,
      HomeFeedTimeSlot.night => 22,
    };
    return DateTime(now.year, now.month, now.day, hour);
  }

  void _refreshHomeFeedTimeSlotIfNeeded() {
    final nextSlot = TimeSlotService.homeFeedSlot(IstTimeService.now());
    if (nextSlot == _activeHomeFeedTimeSlot) {
      return;
    }
    _rememberRecentAllFeedTemplates();
    _activeHomeFeedTimeSlot = nextSlot;
    _resetAllFeedScrollOrderLock();
    _rankedAllFeedTemplates = null;
    _allFeedRankingReady = false;
    _allFeedRankingInFlight = false;
    _templateProjectionCache = null;
    _templateProjectionIdentity = null;
    if (mounted && _selectedCategorySlug == _allCategorySlug) {
      setState(() {});
    }
  }

  void _rememberRecentAllFeedTemplates({
    List<_TemplateItem>? source,
    int maxItems = 8,
  }) {
    final templates = (source ?? _currentAllFeedDisplaySource())
        .take(maxItems)
        .map(_templateSequenceKey)
        .where((key) => key.trim().isNotEmpty)
        .toSet();
    if (templates.isNotEmpty) {
      _recentAllFeedTemplateKeys = templates;
    }
  }

  void _debugLogAllFeedRanking(
    List<_TemplateItem> ranked, {
    required HomeFeedTimeSlot slot,
    required Set<String> dynamicTags,
  }) {
    if (!kDebugMode) {
      return;
    }
    final priorities = TimeSlotService.prioritizedCategoryTagsForHomeFeed(
      _slotReferenceTime(slot),
    );
    final topSlice = ranked.take(12).toList(growable: false);
    final distribution = _countTemplatesByCategory(topSlice);
    _homeDebugLog(
      '[AllFeedPriority] slot=${slot.name} '
      'priorities=${priorities.join(">")} '
      'dynamicActive=${dynamicTags.length} '
      'top12=$distribution',
    );
  }

  void _resetAllFeedScrollOrderLock() {
    if (_lockedAllFeedTemplates == null) {
      return;
    }
    _lockedAllFeedTemplates = null;
    _templateProjectionCache = null;
    _templateProjectionIdentity = null;
  }

  List<_TemplateItem> _currentAllFeedDisplaySource() {
    final locked = _lockedAllFeedTemplates;
    if (locked != null) {
      return locked;
    }
    if (_allFeedRankingReady && _rankedAllFeedTemplates != null) {
      return _rankedAllFeedTemplates!;
    }
    return _remoteApprovedTemplates;
  }

  Future<List<_TemplateItem>?> _extendLockedAllFeedTemplates(
    List<_TemplateItem> incoming, {
    required String phase,
  }) async {
    final locked = _lockedAllFeedTemplates;
    if (locked == null || incoming.isEmpty) {
      return null;
    }
    return _mergeTemplateListsOffMain(<List<_TemplateItem>>[
      locked,
      incoming,
    ], phase: '${phase}_visible_order_lock');
  }

  List<_CategoryChipData> _buildDynamicCategories(
    DateTime now,
    AppLanguage language, {
    required bool templatesLoading,
  }) {
    if (templatesLoading && _remoteApprovedTemplates.isEmpty) {
      return const <_CategoryChipData>[];
    }
    if (_startupSnapshotHydrationDeferred) {
      return const <_CategoryChipData>[];
    }

    final activeCalendarCategories = <DynamicCategory>[
      ..._dynamicCategoryService.categoriesForDate(now, language: language),
      ..._manualEventCategories,
    ];
    _scheduleDynamicCategoryAvailabilityChecks(activeCalendarCategories);
    final loadedTemplateCategoryKeys = _remoteApprovedTemplates
        .map(_normalizedCategoryForDebug)
        .where((value) => value.isNotEmpty)
        .toSet();
    final debugStates = <String>[];
    final merged = <String, _CategoryChipData>{};
    for (final item in activeCalendarCategories) {
      final slug = _normalizeTag(item.slug);
      final hasLocalTemplates = _hasVisibleTemplateForCategoryChip(item);
      final hasServerTemplates =
          _dynamicCategoryAvailabilityBySlug[slug] == true;
      final categorySignalKeys = <String>{
        _normalizeTag(item.id),
        _normalizeTag(item.slug),
        ...item.tags.map(_normalizeTag),
      }.where((value) => value.isNotEmpty).toSet();
      final hasLoadedCategoryKey = loadedTemplateCategoryKeys
          .intersection(categorySignalKeys)
          .isNotEmpty;
      debugStates.add(
        '$slug(local=$hasLocalTemplates,server=$hasServerTemplates,loaded=$hasLoadedCategoryKey)',
      );
      if (!hasLocalTemplates && !hasServerTemplates && !hasLoadedCategoryKey) {
        continue;
      }
      merged[item.slug] = _CategoryChipData(
        slug: item.slug,
        label: item.label,
        matchTags: item.tags,
        presenceTags: _dynamicPresenceTags(item).toList(growable: false),
        isDynamic: true,
      );
    }

    final loadedDynamicCategories = _dynamicCategoryService.categoriesForSlugs(
      loadedTemplateCategoryKeys,
      language: language,
    );
    final templateDrivenManualCategories = _manualEventCategories.where((item) {
      final itemSignals = <String>{
        _normalizeTag(item.id),
        _normalizeTag(item.slug),
        ...item.tags.map(_normalizeTag),
      }.where((value) => value.isNotEmpty).toSet();
      return loadedTemplateCategoryKeys.intersection(itemSignals).isNotEmpty;
    });
    for (final item in <DynamicCategory>[
      ...loadedDynamicCategories,
      ...templateDrivenManualCategories,
    ]) {
      final slug = _normalizeTag(item.slug);
      if (slug.isEmpty || merged.containsKey(item.slug)) {
        continue;
      }
      merged[item.slug] = _CategoryChipData(
        slug: item.slug,
        label: item.label,
        matchTags: item.tags,
        presenceTags: _dynamicPresenceTags(item).toList(growable: false),
        isDynamic: true,
      );
    }

    // Admin manual Firestore categories (manualEventCategories) are not in the
    // local calendar JSON — add chips from loaded templates so filters match.
    final covered = <String>{
      for (final chip in merged.values) ...chip.matchTags.map(_normalizeTag),
      for (final chip in merged.values) _normalizeTag(chip.slug),
    };
    final labelByCategoryId = <String, String>{};
    for (final template in _remoteApprovedTemplates) {
      final rawId = (template.primaryFirestoreCategoryId ?? '').trim();
      if (rawId.isEmpty) {
        continue;
      }
      final lbl = template.categoryDisplayLabel?.trim() ?? '';
      if (lbl.isNotEmpty && !labelByCategoryId.containsKey(rawId)) {
        labelByCategoryId[rawId] = lbl;
      }
    }
    for (final template in _remoteApprovedTemplates) {
      final rawId = (template.primaryFirestoreCategoryId ?? '').trim();
      if (rawId.isEmpty) {
        continue;
      }
      if (merged.containsKey(rawId)) {
        continue;
      }
      final norm = _normalizeTag(rawId);
      if (norm.isEmpty || covered.contains(norm)) {
        continue;
      }
      if (_staticCategorySlugs.contains(rawId)) {
        continue;
      }
      final label = labelByCategoryId[rawId]?.trim().isNotEmpty == true
          ? labelByCategoryId[rawId]!.trim()
          : rawId.replaceAll(RegExp(r'[_-]+'), ' ').trim();
      final matchTags = <String>{
        rawId,
        if (norm.isNotEmpty) norm,
        ..._categoryLabelTokenTags(labelByCategoryId[rawId]),
      }.where((t) => t.trim().isNotEmpty).toList(growable: false);
      merged[rawId] = _CategoryChipData(
        slug: rawId,
        label: label.isNotEmpty ? label : rawId,
        matchTags: matchTags,
        presenceTags: matchTags,
        isDynamic: true,
      );
      covered.add(norm);
    }

    if (kDebugMode) {
      _homeDebugLog(
        '[DynamicChips] active=${activeCalendarCategories.map((item) => _normalizeTag(item.slug)).join(",")} '
        'states=${debugStates.join(" | ")} '
        'shown=${merged.keys.map(_normalizeTag).join(",")}',
      );
    }

    return _filterCategoriesByReligion(merged.values.toList(growable: false));
  }

  List<_CategoryChipData> _buildLoadedTemplateDynamicCategories(
    AppLanguage language,
  ) {
    final loadedTemplateCategoryKeys = _remoteApprovedTemplates
        .map(_normalizedCategoryForDebug)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (loadedTemplateCategoryKeys.isEmpty) {
      return const <_CategoryChipData>[];
    }
    final dynamicCategories = _dynamicCategoryService.categoriesForSlugs(
      loadedTemplateCategoryKeys,
      language: language,
    );
    final manualCategories = _manualEventCategories.where((item) {
      final signals = <String>{
        _normalizeTag(item.id),
        _normalizeTag(item.slug),
        ...item.tags.map(_normalizeTag),
      }.where((value) => value.isNotEmpty).toSet();
      return loadedTemplateCategoryKeys.intersection(signals).isNotEmpty;
    });
    final mergedCategories = <DynamicCategory>[
      ...dynamicCategories,
      ...manualCategories,
    ];
    if (mergedCategories.isEmpty) {
      return const <_CategoryChipData>[];
    }
    return mergedCategories
        .map(
          (item) => _CategoryChipData(
            slug: item.slug,
            label: item.label,
            matchTags: item.tags,
            presenceTags: _dynamicPresenceTags(item).toList(growable: false),
            isDynamic: true,
          ),
        )
        .toList(growable: false);
  }

  void _scheduleDynamicCategoryAvailabilityChecks(
    List<DynamicCategory> activeCalendarCategories,
  ) {
    final normalizedSlugs =
        activeCalendarCategories
            .map((item) => _normalizeTag(item.slug))
            .where((slug) => slug.isNotEmpty)
            .toList(growable: false)
          ..sort();
    final remotePresenceSignatureParts =
        _remoteApprovedTemplates
            .expand((template) => _templateCategoryPresenceSignals(template))
            .map(_normalizeTag)
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    final signature =
        '${normalizedSlugs.join(",")}|remote=${remotePresenceSignatureParts.join(",")}';
    if (signature != _dynamicCategoryAvailabilitySignature) {
      _dynamicCategoryAvailabilitySignature = signature;
      _dynamicCategoryAvailabilityBySlug.clear();
    }

    final pending = activeCalendarCategories
        .where((item) {
          final slug = _normalizeTag(item.slug);
          if (slug.isEmpty) {
            return false;
          }
          if (_hasVisibleTemplateForCategoryChip(item)) {
            _dynamicCategoryAvailabilityBySlug[slug] = true;
            return false;
          }
          if (_dynamicCategoryAvailabilityBySlug[slug] == true) {
            return false;
          }
          return !_dynamicCategoryAvailabilityInFlight.contains(slug);
        })
        .toList(growable: false);
    if (pending.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final category in pending) {
        unawaited(_checkDynamicCategoryAvailability(category));
      }
    });
  }

  Future<void> _checkDynamicCategoryAvailability(
    DynamicCategory category,
  ) async {
    final slug = _normalizeTag(category.slug);
    if (slug.isEmpty || _dynamicCategoryAvailabilityInFlight.contains(slug)) {
      return;
    }
    _dynamicCategoryAvailabilityInFlight.add(slug);
    try {
      final available = await _approvedCreatorTemplateService
          .hasPublishedTemplatesForExactCategory(
            categoryId: slug,
            source: Source.serverAndCache,
          );
      _homeDebugLog('[DynamicAvailability] slug=$slug available=$available');
      if (!mounted) {
        return;
      }
      final previous = _dynamicCategoryAvailabilityBySlug[slug];
      _dynamicCategoryAvailabilityBySlug[slug] = available;
      if (previous != available) {
        setState(() {
          _categoryListCache = null;
          _categoryListIdentity = null;
        });
      }
    } catch (_) {
      if (mounted) {
        _dynamicCategoryAvailabilityBySlug[slug] = false;
      }
    } finally {
      _dynamicCategoryAvailabilityInFlight.remove(slug);
    }
  }

  Set<String> _dynamicPresenceTags(DynamicCategory category) {
    const broadTags = <String>{
      'festival',
      'devotional',
      'today_special',
      'important_day',
      'regional_special',
      'weekday_special',
      'global',
      'india',
      'andhra_pradesh',
      'telangana',
      'both_telugu_states',
    };
    final output = <String>{};

    void addValue(String raw) {
      final normalized = _normalizeTag(raw);
      if (normalized.isEmpty) {
        return;
      }
      output.add(normalized);
    }

    addValue(category.id);
    addValue(category.slug);
    for (final tag in category.tags) {
      final normalized = _normalizeTag(tag);
      if (normalized.isEmpty || broadTags.contains(normalized)) {
        continue;
      }
      addValue(tag);
    }
    return output;
  }

  Set<String> _templateCategoryPresenceSignals(_TemplateItem item) {
    final output = <String>{};

    void addValue(String raw) {
      final normalized = _normalizeTag(raw);
      if (normalized.isEmpty) {
        return;
      }
      output.add(normalized);
    }

    addValue(item.primaryFirestoreCategoryId ?? '');
    addValue(item.categoryDisplayLabel ?? '');
    for (final tag in item.categoryTags) {
      addValue(tag);
    }
    return output;
  }

  bool _templateMatchesDynamicCategoryExactly(
    _TemplateItem item,
    DynamicCategory category,
  ) {
    final normalizedPrimary = _normalizeTag(
      item.primaryFirestoreCategoryId?.trim() ?? '',
    );
    final normalizedCategoryId = _normalizeTag(category.id);
    final normalizedCategorySlug = _normalizeTag(category.slug);
    return normalizedPrimary.isNotEmpty &&
        (normalizedPrimary == normalizedCategoryId ||
            normalizedPrimary == normalizedCategorySlug);
  }

  Set<String> _templateCategorySignalsForMatching(_TemplateItem item) {
    final output = <String>{};

    void addValue(String raw) {
      final normalized = _normalizeTag(raw);
      if (normalized.isEmpty) {
        return;
      }
      output.add(normalized);
      output.addAll(_expandCategoryAliases(normalized));
    }

    final primaryCategoryId = (item.primaryFirestoreCategoryId ?? '').trim();
    if (primaryCategoryId.isNotEmpty) {
      addValue(primaryCategoryId);
    }

    addValue(item.categoryDisplayLabel ?? '');
    for (final tag in item.categoryTags) {
      addValue(tag);
    }
    return output;
  }

  Set<String> _categorySignalsForMatching(_CategoryChipData category) {
    final output = <String>{};

    void addValue(String raw) {
      final normalized = _normalizeTag(raw);
      if (normalized.isEmpty) {
        return;
      }
      output.add(normalized);
      output.addAll(_expandCategoryAliases(normalized));
    }

    addValue(category.slug);
    addValue(category.label);
    for (final tag in category.matchTags) {
      addValue(tag);
    }
    return output;
  }

  Set<String> _strictDynamicCategorySignals(_CategoryChipData category) {
    final normalizedSlug = _normalizeTag(category.slug);
    if (normalizedSlug.isEmpty) {
      return const <String>{};
    }
    return _expandCategoryAliases(normalizedSlug);
  }

  bool _hasVisibleTemplateForCategoryChip(DynamicCategory category) {
    final categoryChip = _CategoryChipData(
      slug: category.slug,
      label: category.label,
      matchTags: category.tags,
      presenceTags: _dynamicPresenceTags(category).toList(growable: false),
      isDynamic: true,
    );
    final categorySignals = _strictDynamicCategorySignals(categoryChip);
    for (final template in _remoteApprovedTemplates) {
      if (_templateMatchesDynamicCategoryExactly(template, category)) {
        return true;
      }
      if (categorySignals.isNotEmpty &&
          _templateCategorySignalsForMatching(
            template,
          ).intersection(categorySignals).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Iterable<String> _categoryLabelTokenTags(String? label) sync* {
    if (label == null || label.trim().isEmpty) {
      return;
    }
    final norm = _normalizeTag(label);
    if (norm.isNotEmpty) {
      yield norm;
    }
    for (final word in label.toLowerCase().split(RegExp(r'\s+'))) {
      final w = _normalizeTag(word);
      if (w.length > 2) {
        yield w;
      }
    }
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

  List<_CategoryChipData> _buildSelectedPartyCategories(AppLanguage language) {
    if (_selectedPoliticalPartyIds.isEmpty) {
      return const <_CategoryChipData>[];
    }
    final knownParties = politicalParties
        .where((party) => _selectedPoliticalPartyIds.contains(party.id))
        .toList(growable: false);
    final knownPartyIds = knownParties.map((party) => party.id).toSet();
    final unknownPartyIds =
        _selectedPoliticalPartyIds.difference(knownPartyIds).toList()..sort();

    return <_CategoryChipData>[
      for (final party in knownParties)
        _CategoryChipData(
          slug: 'party_${party.id}',
          label: party.nameFor(language),
          matchTags: <String>[
            party.id,
            party.shortName,
            party.name,
            'political',
            'politics',
          ],
          presenceTags: <String>[party.id, party.shortName, party.name],
        ),
      for (final partyId in unknownPartyIds)
        _CategoryChipData(
          slug: 'party_$partyId',
          label: partyId.replaceAll(RegExp(r'[_-]+'), ' ').trim(),
          matchTags: <String>[partyId],
          presenceTags: <String>[partyId],
        ),
    ];
  }

  List<_CategoryChipData> _mergeCategories(
    List<_CategoryChipData> staticCategories,
    List<_CategoryChipData> dynamicCategories,
    List<_CategoryChipData> partyCategories,
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
      addChip(_allCategoryChip());
    }

    for (final chip in partyCategories) {
      addChip(chip);
    }
    for (final chip in dynamicCategories) {
      addChip(chip);
    }
    for (final chip in staticCategories.skip(1)) {
      addChip(chip);
    }

    return _filterCategoriesByReligion(merged);
  }

  _CategoryChipData _allCategoryChip() {
    return _CategoryChipData(
      slug: _allCategorySlug,
      label: context.strings.localized(telugu: 'అన్నీ', english: 'All'),
      matchTags: const <String>['all'],
    );
  }

  List<String> _defaultCategoryTagsForSlug(String slug) {
    return switch (slug) {
      _allCategorySlug => const <String>['all'],
      'good_morning' => const <String>['good_morning', 'morning'],
      'good_afternoon' => const <String>['good_afternoon', 'afternoon'],
      'good_night' => const <String>['good_night', 'night'],
      'motivational' => const <String>['motivational'],
      'love_quotes' => const <String>['love_quotes', 'love'],
      'today_special' => const <String>['today_special', 'important_day'],
      'birthdays' => const <String>['birthdays', 'birthday', 'celebration'],
      'life_advice' => const <String>['life_advice'],
      'gita_wisdom' => const <String>['gita_wisdom'],
      'devotional' => const <String>['devotional'],
      'mahabharata' => const <String>['mahabharata'],
      'anniversary' => const <String>['anniversary', 'celebration'],
      'good_thoughts' => const <String>['good_thoughts'],
      'bible' => const <String>['bible'],
      'islam' => const <String>['islam'],
      'jokes' => const <String>['jokes', 'funny', 'humor', 'comedy'],
      'new' => const <String>['new', 'more', 'latest', 'today_special'],
      _ => <String>[slug],
    };
  }

  /// Same token shaping as [DynamicCategoryService] (_normalizeToken): camelCase
  /// splits to snake case before stripping punctuation so `goodMorning` and
  /// `good_morning` classify as one category token (fixes related-category filtering).
  String _normalizeTag(String value) {
    var scratch = value.trim();
    if (scratch.isEmpty) {
      return '';
    }
    for (var round = 0; round < 8; round++) {
      final next = scratch.replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (Match match) => '${match.group(1)}_${match.group(2)}',
      );
      if (next == scratch) {
        break;
      }
      scratch = next;
    }
    return scratch
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
      'motivational': <String>['motivational'],
      'love_quotes': <String>['love_quotes', 'love'],
      'today_special': <String>['today_special', 'important_day'],
      'birthdays': <String>['birthdays', 'birthday', 'celebration'],
      'life_advice': <String>['life_advice'],
      'gita_wisdom': <String>['gita_wisdom'],
      'devotional': <String>['devotional'],
      'mahabharata': <String>['mahabharata'],
      'anniversary': <String>['anniversary', 'celebration'],
      'good_thoughts': <String>['good_thoughts'],
      'bible': <String>['bible'],
      'islam': <String>['islam'],
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

  void _setPosterPhotoDragInProgress(bool value) {
    if (_posterPhotoDragInProgress == value || !mounted) {
      return;
    }
    setState(() {
      _posterPhotoDragInProgress = value;
    });
  }

  Future<void> _showReferralPromptIfNeeded() async {
    if (!mounted || _referralPromptShowing) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = '$_homeReferralPromptKeyPrefix$uid';
    if (prefs.getBool(key) == true || !mounted) {
      return;
    }

    _referralPromptShowing = true;
    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _HomeReferralCodeDialog(),
    );
    _referralPromptShowing = false;
    if (applied == true || applied == false) {
      await prefs.setBool(key, true);
    }
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
    final remoteFuture = _appHomeBannerService.fetchBanners();
    final cached = await _appHomeBannerService.fetchBannersFromCache();
    if (mounted && cached.isNotEmpty) {
      if (!_sameHomeBannerSequence(_homeBanners, cached)) {
        setState(() => _homeBanners = cached);
      }
    }

    final remote = await remoteFuture;
    if (!mounted) {
      return;
    }
    if (_sameHomeBannerSequence(_homeBanners, remote)) {
      return;
    }
    setState(() => _homeBanners = remote);
  }

  developer.TimelineTask _startStartupTimelineTask(
    String name, {
    Map<String, Object?> arguments = const <String, Object?>{},
  }) {
    final task = developer.TimelineTask(filterKey: 'home_startup');
    task.start(name, arguments: arguments);
    return task;
  }

  Future<List<_TemplateItem>> _mapTemplatesOffMain(
    List<ApprovedCreatorTemplate> templates, {
    String phase = 'map',
  }) async {
    if (templates.isEmpty) {
      return const <_TemplateItem>[];
    }
    if (templates.length <= _smallMappingBatchSize) {
      return _mapApprovedCreatorTemplatesWorker(templates);
    }
    final task = _startStartupTimelineTask(
      'map',
      arguments: <String, Object?>{'phase': phase, 'count': templates.length},
    );
    try {
      final mapped = await Isolate.run<List<_TemplateItem>>(
        () => _mapApprovedCreatorTemplatesWorker(templates),
      );
      task.finish(
        arguments: <String, Object?>{'phase': phase, 'count': mapped.length},
      );
      return mapped;
    } catch (error) {
      task.finish(
        arguments: <String, Object?>{'phase': phase, 'error': error.toString()},
      );
      rethrow;
    }
  }

  Future<List<_TemplateItem>> _mergeTemplateListsOffMain(
    List<List<_TemplateItem>> batches, {
    required String phase,
  }) async {
    if (batches.isEmpty) {
      return const <_TemplateItem>[];
    }
    final inputCount = batches.fold<int>(
      0,
      (totalCount, batch) => totalCount + batch.length,
    );
    if (inputCount <= _smallMergeBatchInputCount) {
      return _mergeTemplateListsWorker(batches);
    }
    final task = _startStartupTimelineTask(
      'dedupe',
      arguments: <String, Object?>{
        'phase': phase,
        'batches': batches.length,
        'inputCount': inputCount,
      },
    );
    try {
      final merged = await Isolate.run<List<_TemplateItem>>(
        () => _mergeTemplateListsWorker(batches),
      );
      task.finish(
        arguments: <String, Object?>{'phase': phase, 'count': merged.length},
      );
      return merged;
    } catch (error) {
      task.finish(
        arguments: <String, Object?>{'phase': phase, 'error': error.toString()},
      );
      rethrow;
    }
  }

  Map<String, Object?> _serializePageConfig(EditorPageConfig? config) {
    if (config == null) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'name': config.name,
      'widthPx': config.widthPx,
      'heightPx': config.heightPx,
    };
  }

  EditorPageConfig? _deserializePageConfig(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return null;
    }
    final name = (data['name'] as String?)?.trim() ?? '';
    final widthPx = (data['widthPx'] as num?)?.toInt() ?? 0;
    final heightPx = (data['heightPx'] as num?)?.toInt() ?? 0;
    if (name.isEmpty || widthPx <= 0 || heightPx <= 0) {
      return null;
    }
    return EditorPageConfig(name: name, widthPx: widthPx, heightPx: heightPx);
  }

  Map<String, Object?> _serializePersonalization(
    CreatorPosterPersonalization? config,
  ) {
    if (config == null) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'photoShape': config.photoShape,
      'photoX': config.photoX,
      'photoY': config.photoY,
      'photoScale': config.photoScale,
      'showVideoExtraPhoto': config.showVideoExtraPhoto,
      'videoExtraPhotoShape': config.videoExtraPhotoShape,
      'videoExtraPhotoRenderMode': config.videoExtraPhotoRenderMode,
      'videoExtraPhotoEdgeStyle': config.videoExtraPhotoEdgeStyle,
      'videoExtraPhotoX': config.videoExtraPhotoX,
      'videoExtraPhotoY': config.videoExtraPhotoY,
      'videoExtraPhotoScale': config.videoExtraPhotoScale,
      'nameX': config.nameX,
      'nameY': config.nameY,
      'showBottomStrip': config.showBottomStrip,
      'stripHeight': config.stripHeight,
      'showWhatsapp': config.showWhatsapp,
      'sampleName': config.sampleName,
      'nameScale': config.nameScale,
      'showStyledNameStrip': config.showStyledNameStrip,
      'showStyledDesignationStrip': config.showStyledDesignationStrip,
      'sampleDesignation': config.sampleDesignation,
      'designationScale': config.designationScale,
      'phoneScale': config.phoneScale,
      'nameStripColor': config.nameStripColor,
      'designationStripColor': config.designationStripColor,
      'boardVariant': config.boardVariant,
      'photoRenderMode': config.photoRenderMode,
      'edgeStyle': config.edgeStyle,
      'showSafeAreas': config.showSafeAreas,
    };
  }

  CreatorPosterPersonalization? _deserializePersonalization(
    Map<String, dynamic>? data,
  ) {
    if (data == null || data.isEmpty) {
      return null;
    }
    final photoShape = (data['photoShape'] as String?)?.trim() ?? '';
    if (photoShape.isEmpty) {
      return null;
    }
    return CreatorPosterPersonalization(
      photoShape: photoShape,
      photoX: (data['photoX'] as num?)?.toDouble() ?? 78,
      photoY: (data['photoY'] as num?)?.toDouble() ?? 42,
      photoScale: (data['photoScale'] as num?)?.toDouble() ?? 44,
      showVideoExtraPhoto: data['showVideoExtraPhoto'] as bool? ?? false,
      videoExtraPhotoShape:
          (data['videoExtraPhotoShape'] as String?)?.trim() ?? 'circle',
      videoExtraPhotoRenderMode:
          (data['videoExtraPhotoRenderMode'] as String?)?.trim() ?? 'cutout',
      videoExtraPhotoEdgeStyle:
          (data['videoExtraPhotoEdgeStyle'] as String?)?.trim() ?? 'soft_fade',
      videoExtraPhotoX: (data['videoExtraPhotoX'] as num?)?.toDouble() ?? 24,
      videoExtraPhotoY: (data['videoExtraPhotoY'] as num?)?.toDouble() ?? 44,
      videoExtraPhotoScale:
          (data['videoExtraPhotoScale'] as num?)?.toDouble() ?? 28,
      nameX: (data['nameX'] as num?)?.toDouble() ?? 50,
      nameY: (data['nameY'] as num?)?.toDouble() ?? 82,
      showBottomStrip: data['showBottomStrip'] as bool? ?? true,
      stripHeight: (data['stripHeight'] as num?)?.toDouble() ?? 16,
      showWhatsapp: data['showWhatsapp'] as bool? ?? true,
      sampleName: (data['sampleName'] as String?)?.trim() ?? 'User Name',
      nameScale: (data['nameScale'] as num?)?.toDouble() ?? 100,
      showStyledNameStrip: data['showStyledNameStrip'] as bool? ?? false,
      showStyledDesignationStrip:
          data['showStyledDesignationStrip'] as bool? ?? false,
      sampleDesignation: (data['sampleDesignation'] as String?)?.trim() ?? '',
      designationScale: (data['designationScale'] as num?)?.toDouble() ?? 100,
      phoneScale: (data['phoneScale'] as num?)?.toDouble() ?? 100,
      nameStripColor: (data['nameStripColor'] as String?)?.trim() ?? '#0F172A',
      designationStripColor:
          (data['designationStripColor'] as String?)?.trim() ?? '#1E293B',
      boardVariant: (data['boardVariant'] as num?)?.toInt() ?? 0,
      photoRenderMode: (data['photoRenderMode'] as String?)?.trim() ?? 'cutout',
      edgeStyle: (data['edgeStyle'] as String?)?.trim() ?? 'soft_fade',
      showSafeAreas: data['showSafeAreas'] as bool? ?? true,
    );
  }

  Map<String, Object?> _serializeTemplateSnapshotItem(_TemplateItem item) {
    return <String, Object?>{
      'titleTe': item.titleTe,
      'titleHi': item.titleHi,
      'titleEn': item.titleEn,
      'imageUrl': item.imageUrl,
      'imageStoragePath': item.imageStoragePath,
      'thumbnailStoragePath': item.thumbnailStoragePath,
      'thumbnailUrl': item.thumbnailUrl,
      'mediaType': item.mediaType,
      'videoUrl': item.videoUrl,
      'imageAssetPath': item.imageAssetPath,
      'price': item.price,
      'templateId': item.templateId,
      'templateDocumentSource': item.templateDocumentSource,
      'productId': item.productId,
      'fallbackProductIds': item.fallbackProductIds,
      'categoryTags': item.categoryTags,
      'createdAtMillis': item.createdAtMillis,
      'primaryFirestoreCategoryId': item.primaryFirestoreCategoryId,
      'categoryDisplayLabel': item.categoryDisplayLabel,
      'pageConfig': _serializePageConfig(item.pageConfig),
      'personalizationConfig': _serializePersonalization(
        item.personalizationConfig,
      ),
    };
  }

  _TemplateItem? _deserializeTemplateSnapshotItem(Map<String, dynamic> data) {
    final titleEn = (data['titleEn'] as String?)?.trim() ?? '';
    if (titleEn.isEmpty) {
      return null;
    }
    return _TemplateItem(
      titleTe: (data['titleTe'] as String?) ?? titleEn,
      titleHi: (data['titleHi'] as String?) ?? titleEn,
      titleEn: titleEn,
      imageUrl: (data['imageUrl'] as String?)?.trim(),
      imageStoragePath: (data['imageStoragePath'] as String?)?.trim(),
      thumbnailStoragePath: (data['thumbnailStoragePath'] as String?)?.trim(),
      thumbnailUrl: (data['thumbnailUrl'] as String?)?.trim(),
      mediaType: (data['mediaType'] as String?)?.trim() ?? 'image',
      videoUrl: (data['videoUrl'] as String?)?.trim(),
      imageAssetPath: (data['imageAssetPath'] as String?)?.trim(),
      price: (data['price'] as num?)?.toInt(),
      templateId: (data['templateId'] as String?)?.trim(),
      templateDocumentSource: (data['templateDocumentSource'] as String?)
          ?.trim(),
      productId: (data['productId'] as String?)?.trim(),
      fallbackProductIds:
          (data['fallbackProductIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) => value.toString())
              .toList(growable: false),
      categoryTags:
          (data['categoryTags'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) => value.toString())
              .toList(growable: false),
      createdAtMillis: (data['createdAtMillis'] as num?)?.toInt() ?? 0,
      primaryFirestoreCategoryId:
          (data['primaryFirestoreCategoryId'] as String?)?.trim(),
      categoryDisplayLabel: (data['categoryDisplayLabel'] as String?)?.trim(),
      pageConfig: _deserializePageConfig(
        (data['pageConfig'] as Map?)?.cast<String, dynamic>(),
      ),
      personalizationConfig: _deserializePersonalization(
        (data['personalizationConfig'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  Future<void> _persistStartupTemplateSnapshot(
    List<_TemplateItem> templates,
  ) async {
    if (templates.isEmpty) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = templates
          .take(_startupSnapshotTemplateCount)
          .map(_serializeTemplateSnapshotItem)
          .toList(growable: false);
      await prefs.setString(_startupTemplateSnapshotKey, jsonEncode(payload));
    } catch (_) {
    } finally {
      _startupSnapshotAttemptCompleted = true;
    }
  }

  void _scheduleStartupTemplateSnapshotPersist(List<_TemplateItem> templates) {
    if (templates.isEmpty) {
      return;
    }
    final snapshot = templates
        .take(_startupSnapshotTemplateCount)
        .toList(growable: false);
    _startupSnapshotPersistTimer?.cancel();
    _startupSnapshotPersistTimer = Timer(
      const Duration(milliseconds: 1200),
      () {
        if (!mounted) {
          return;
        }
        unawaited(_persistStartupTemplateSnapshot(snapshot));
      },
    );
  }

  Future<void> _loadStartupTemplateSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_startupTemplateSnapshotKey)?.trim() ?? '';
      if (raw.isEmpty || !mounted || _remoteApprovedTemplates.isNotEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final mapped = decoded
          .whereType<Map>()
          .map(
            (item) =>
                _deserializeTemplateSnapshotItem(item.cast<String, dynamic>()),
          )
          .whereType<_TemplateItem>()
          .toList(growable: false);
      if (mapped.isEmpty ||
          mapped.length < _startupSnapshotMinimumVisibleCount ||
          !mounted ||
          _remoteApprovedTemplates.isNotEmpty) {
        return;
      }
      setState(() {
        _remoteApprovedTemplates = mapped;
        _templatesLoading = false;
        _templatesHasMore = true;
      });
      _startupSnapshotHydrationDeferred = true;
      _scheduleStartupRichPosterPreviewActivation(
        initialDelay: const Duration(milliseconds: 40),
      );
      _scheduleSelectedCategoryPrefetchAfterVisibleTemplates();
      _logPostPaintTimingOnce(
        kind: 'first_snapshot_feed_paint',
        alreadyLogged: _loggedFirstCachedFeedPaint,
        markLogged: () => _loggedFirstCachedFeedPaint = true,
        count: mapped.length,
      );
      _homeDebugLog(
        '[StartupTiming] templates_snapshot_ready '
        't=${_startupStopwatch.elapsedMilliseconds}ms count=${mapped.length}',
      );
    } catch (_) {}
  }

  Future<void> _applyStartupTemplateState(
    List<_TemplateItem> templates, {
    required bool hasMore,
    required QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    required String phase,
    required bool logFirstRemotePaint,
    int primaryCount = 0,
    int secondaryCount = 0,
    int genericCount = 0,
  }) async {
    if (!mounted) {
      return;
    }
    final setStateTask = _startStartupTimelineTask(
      'first_set_state',
      arguments: <String, Object?>{'phase': phase, 'count': templates.length},
    );
    final setStateStopwatch = Stopwatch()..start();
    setState(() {
      _remoteApprovedTemplates = templates;
      _rankedAllFeedTemplates = null;
      _allFeedRankingReady = false;
      _startupSnapshotHydrationDeferred = false;
      _templatesLoading = false;
      _templatesHasMore = hasMore;
      _templatesLastDocument = lastDocument;
    });
    setStateTask.finish(
      arguments: <String, Object?>{
        'phase': phase,
        'count': templates.length,
        'setStateMs': setStateStopwatch.elapsedMilliseconds,
      },
    );
    _templateProjectionCache = null;
    _templateProjectionIdentity = null;
    _categoryListCache = null;
    _categoryListIdentity = null;
    _hydratedCategorySlugs.clear();
    _scheduleSelectedCategoryPrefetchAfterVisibleTemplates();
    _scheduleDeferredAllFeedRanking();
    _scheduleStartupRichPosterPreviewActivation();
    if (logFirstRemotePaint) {
      _logPostPaintTimingOnce(
        kind: 'first_remote_feed_paint',
        alreadyLogged: _loggedFirstRemoteFeedPaint,
        markLogged: () => _loggedFirstRemoteFeedPaint = true,
        count: templates.length,
      );
    }
    _homeDebugLog(
      '[StartupTiming] templates_$phase t=${_startupStopwatch.elapsedMilliseconds}ms '
      'count=${templates.length} primary=$primaryCount secondary=$secondaryCount '
      'generic=$genericCount hasMore=$hasMore',
    );
  }

  void _scheduleStartupRichPosterPreviewActivation({
    Duration initialDelay = const Duration(milliseconds: 2200),
  }) {
    if (_startupRichPosterPreviewReady ||
        _startupRichPosterPreviewActivationQueued) {
      return;
    }
    _startupRichPosterPreviewActivationQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await Future<void>.delayed(initialDelay);
        if (!mounted) {
          return;
        }
        if (!PostSplashStartupGate.isReady) {
          _startupRichPosterPreviewActivationQueued = false;
          await Future<void>.delayed(const Duration(milliseconds: 320));
          if (!mounted) {
            return;
          }
          _scheduleStartupRichPosterPreviewActivation(
            initialDelay: const Duration(milliseconds: 640),
          );
          return;
        }
        if (_posterScrollController.hasClients &&
            _posterScrollController.position.isScrollingNotifier.value) {
          _startupRichPosterPreviewActivationQueued = false;
          await Future<void>.delayed(const Duration(milliseconds: 900));
          if (!mounted) {
            return;
          }
          _scheduleStartupRichPosterPreviewActivation();
          return;
        }
        if (_templatesLoading ||
            _templatesLoadingMore ||
            _posterPhotoDragInProgress) {
          _startupRichPosterPreviewActivationQueued = false;
          await Future<void>.delayed(const Duration(milliseconds: 1100));
          if (!mounted) {
            return;
          }
          _scheduleStartupRichPosterPreviewActivation();
          return;
        }
        _startupRichPosterPreviewActivationQueued = false;
        if (_startupRichPosterPreviewReady) {
          return;
        }
        setState(() {
          _startupRichPosterPreviewReady = true;
        });
      }());
    });
  }

  Future<void> _awaitStartupUiSettled({
    Duration minimumDelay = const Duration(milliseconds: 420),
  }) async {
    try {
      await PostSplashStartupGate.whenReady.timeout(const Duration(seconds: 4));
    } catch (_) {}
    await Future<void>.delayed(minimumDelay);
    if (!mounted) {
      return;
    }
    if (_posterScrollController.hasClients &&
        _posterScrollController.position.isScrollingNotifier.value) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
    if (!mounted) {
      return;
    }
    if (_templatesLoading ||
        _templatesLoadingMore ||
        _posterPhotoDragInProgress) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
  }

  Future<void> _appendTemplatesIncrementally(
    List<_TemplateItem> incoming, {
    required bool hasMore,
    required QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    required String phase,
  }) async {
    if (incoming.isEmpty || !mounted) {
      if (mounted) {
        setState(() {
          _templatesHasMore = hasMore;
          _templatesLastDocument = lastDocument;
          _templatesLoadingMore = false;
        });
      }
      return;
    }
    final applyAsSingleBatch = phase == 'load_more_merge';
    if (applyAsSingleBatch) {
      final lockedMerged = await _extendLockedAllFeedTemplates(
        incoming,
        phase: phase,
      );
      final merged = await _mergeTemplateListsOffMain(<List<_TemplateItem>>[
        _remoteApprovedTemplates,
        incoming,
      ], phase: phase);
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteApprovedTemplates = merged;
        if (lockedMerged != null) {
          _lockedAllFeedTemplates = lockedMerged;
        }
        _rankedAllFeedTemplates = null;
        _allFeedRankingReady = false;
        _startupSnapshotHydrationDeferred = false;
        _templatesHasMore = hasMore;
        _templatesLastDocument = lastDocument;
        _templatesLoading = false;
        _templatesLoadingMore = false;
      });
      _templateProjectionCache = null;
      _templateProjectionIdentity = null;
      _categoryListCache = null;
      _categoryListIdentity = null;
      _scheduleDeferredAllFeedRanking();
      if (phase.contains('merge') && merged.isNotEmpty) {
        _scheduleStartupTemplateSnapshotPersist(merged);
      }
      return;
    }
    for (
      var start = 0;
      start < incoming.length && mounted;
      start += _startupMergeBatchSize
    ) {
      final end = math.min(start + _startupMergeBatchSize, incoming.length);
      final chunk = incoming.sublist(start, end);
      final lockedMerged = await _extendLockedAllFeedTemplates(
        chunk,
        phase: phase,
      );
      final merged = await _mergeTemplateListsOffMain(<List<_TemplateItem>>[
        _remoteApprovedTemplates,
        chunk,
      ], phase: '$phase:${start ~/ _startupMergeBatchSize}');
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteApprovedTemplates = merged;
        if (lockedMerged != null) {
          _lockedAllFeedTemplates = lockedMerged;
        }
        _rankedAllFeedTemplates = null;
        _allFeedRankingReady = false;
        _startupSnapshotHydrationDeferred = false;
        _templatesHasMore = hasMore;
        _templatesLastDocument = lastDocument;
        _templatesLoading = false;
        _templatesLoadingMore = false;
      });
      _templateProjectionCache = null;
      _templateProjectionIdentity = null;
      _categoryListCache = null;
      _categoryListIdentity = null;
      _scheduleDeferredAllFeedRanking();
      if (phase.contains('merge') && merged.isNotEmpty) {
        _scheduleStartupTemplateSnapshotPersist(merged);
      }
      if (end < incoming.length) {
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 24));
      }
    }
  }

  Future<void> _completeStartupSecondaryHydration({
    List<_TemplateItem> deferredPrimaryItems = const <_TemplateItem>[],
    required Future<List<ApprovedCreatorTemplate>> secondaryFuture,
    required Future<ApprovedCreatorTemplatePage> genericFuture,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    await _awaitStartupUiSettled();
    if (!mounted) {
      return;
    }

    if (deferredPrimaryItems.isNotEmpty) {
      await _appendTemplatesIncrementally(
        deferredPrimaryItems,
        hasMore: _templatesHasMore,
        lastDocument: _templatesLastDocument,
        phase: 'primary_merge',
      );
      await WidgetsBinding.instance.endOfFrame;
      await _awaitStartupUiSettled(
        minimumDelay: const Duration(milliseconds: 320),
      );
      if (!mounted) {
        return;
      }
    }

    final secondaryTemplates = await secondaryFuture;
    if (!mounted) {
      return;
    }
    final secondaryItems = await _mapTemplatesOffMain(
      secondaryTemplates,
      phase: 'secondary',
    );
    if (!mounted) {
      return;
    }
    await _appendTemplatesIncrementally(
      secondaryItems,
      hasMore: _templatesHasMore,
      lastDocument: _templatesLastDocument,
      phase: 'secondary_merge',
    );

    await WidgetsBinding.instance.endOfFrame;
    await _awaitStartupUiSettled(
      minimumDelay: const Duration(milliseconds: 320),
    );
    if (!mounted) {
      return;
    }

    final genericPage = await genericFuture;
    if (!mounted) {
      return;
    }
    final genericItems = await _mapTemplatesOffMain(
      genericPage.templates,
      phase: 'generic',
    );
    if (!mounted) {
      return;
    }
    await _appendTemplatesIncrementally(
      genericItems,
      hasMore: genericPage.hasMore,
      lastDocument: genericPage.lastDocument,
      phase: 'generic_merge',
    );
    if (!mounted) {
      return;
    }
    _scheduleProgressiveTemplateHydration();
  }

  Future<void> _loadApprovedCreatorTemplates({
    bool forceRefresh = false,
  }) async {
    final inFlight = _approvedTemplatesLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _loadApprovedCreatorTemplatesInternal(
      forceRefresh: forceRefresh,
    );
    _approvedTemplatesLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_approvedTemplatesLoadFuture, future)) {
        _approvedTemplatesLoadFuture = null;
      }
    }
  }

  void _triggerSelectedCategoryPrefetch() {
    final slug = _selectedCategorySlug;
    if (slug == _allCategorySlug || !mounted) {
      return;
    }
    final language = context.currentLanguage;
    final generation = ++_categoryLoadGeneration;
    if (_categoryLoadingSlug != slug) {
      setState(() => _categoryLoadingSlug = slug);
    }
    unawaited(_loadSelectedCategoryUntilVisible(slug, generation, language));
  }

  void _scheduleSelectedCategoryPrefetchAfterVisibleTemplates() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _remoteApprovedTemplates.isEmpty) {
        return;
      }
      if (!_loggedFirstTemplatesPaint) {
        _loggedFirstTemplatesPaint = true;
        _homeDebugLog(
          '[StartupTiming] firstTemplatesPaintMs=${_startupStopwatch.elapsedMilliseconds}ms '
          'count=${_remoteApprovedTemplates.length}',
        );
      }
      _triggerSelectedCategoryPrefetch();
    });
  }

  Future<void> _loadApprovedCreatorTemplatesInternal({
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final hadVisibleTemplates = _remoteApprovedTemplates.isNotEmpty;
    if (forceRefresh) {
      try {
        final page = await _approvedCreatorTemplateService
            .fetchApprovedTemplatesPage(
              pageSize: _templatesPageSize,
              source: Source.server,
            );
        if (!mounted) {
          return;
        }
        final mapped = await _mapTemplatesOffMain(
          page.templates,
          phase: 'refresh',
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _remoteApprovedTemplates = mapped;
          _lockedAllFeedTemplates = null;
          _rankedAllFeedTemplates = null;
          _allFeedRankingReady = false;
          _templatesLoading = false;
          _templatesLoadingMore = false;
          _templatesHasMore = page.hasMore;
          _templatesLastDocument = page.lastDocument;
          _startupSnapshotHydrationDeferred = false;
        });
        _hydratedCategorySlugs.clear();
        _templateProjectionCache = null;
        _templateProjectionIdentity = null;
        _categoryListCache = null;
        _categoryListIdentity = null;
        _scheduleSelectedCategoryPrefetchAfterVisibleTemplates();
        _scheduleProgressiveTemplateHydration();
        _homeDebugLog(
          '[PosterRefresh] server_replace '
          'duration=${stopwatch.elapsedMilliseconds}ms count=${mapped.length} '
          'hasMore=${page.hasMore}',
        );
      } catch (error, stackTrace) {
        _homeDebugLogStack('home template refresh failed: $error', stackTrace);
        if (!mounted) {
          return;
        }
        setState(() {
          _templatesLoading = false;
          _templatesLoadingMore = false;
        });
      }
      return;
    }
    final initialPageSize = hadVisibleTemplates
        ? _templatesPageSize
        : _initialTemplatesPageSize;
    final shouldUseSlotAwareStartupFetch =
        !hadVisibleTemplates && _selectedCategorySlug == _allCategorySlug;
    final startupSlot = shouldUseSlotAwareStartupFetch
        ? _activeHomeFeedTimeSlot
        : null;
    final startupOrderedTags = shouldUseSlotAwareStartupFetch
        ? TimeSlotService.prioritizedCategoryTagsForHomeFeed(
                _slotReferenceTime(startupSlot!),
              )
              .map(_normalizeTag)
              .where((tag) => tag.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final startupPrimaryTag = startupOrderedTags.isNotEmpty
        ? startupOrderedTags.first
        : null;
    final startupSecondaryTag = startupOrderedTags.length > 1
        ? startupOrderedTags[1]
        : null;
    final genericFetchStopwatch = Stopwatch()..start();
    final startupGenericRemoteFuture = shouldUseSlotAwareStartupFetch
        ? _approvedCreatorTemplateService
              .fetchApprovedTemplatesPage(
                pageSize: initialPageSize,
                allowFallbackMerge: false,
              )
              .whenComplete(() {
                _homeDebugLog(
                  '[StartupTiming] generic_fetch_done t=${_startupStopwatch.elapsedMilliseconds}ms '
                  'waitMs=${genericFetchStopwatch.elapsedMilliseconds}',
                );
              })
        : _approvedCreatorTemplateService.fetchApprovedTemplatesPage(
            pageSize: initialPageSize,
          );
    final startupSecondaryFuture = shouldUseSlotAwareStartupFetch
        ? (startupSecondaryTag == null
              ? Future<List<ApprovedCreatorTemplate>>.value(
                  const <ApprovedCreatorTemplate>[],
                )
              : _approvedCreatorTemplateService
                    .fetchAllApprovedTemplatesForCategory(
                      categoryId: startupSecondaryTag,
                      source: Source.serverAndCache,
                      scanLimit: _initialPrioritySecondaryFetchSize,
                    ))
        : null;
    final startupPrimaryFuture = shouldUseSlotAwareStartupFetch
        ? (startupPrimaryTag == null
              ? startupGenericRemoteFuture.then((page) => page.templates)
              : _approvedCreatorTemplateService
                    .fetchAllApprovedTemplatesForCategory(
                      categoryId: startupPrimaryTag,
                      source: Source.serverAndCache,
                      scanLimit: _initialPriorityPrimaryFetchSize,
                    ))
        : null;
    final shouldContinueAfterStartupSnapshot =
        hadVisibleTemplates && _startupSnapshotHydrationDeferred;
    if (mounted) {
      setState(() {
        _templatesLoading = !hadVisibleTemplates;
        _templatesLoadingMore = false;
        if (!hadVisibleTemplates) {
          _templatesHasMore = true;
          _templatesLastDocument = null;
        }
      });
    }
    try {
      final cacheQueryStopwatch = Stopwatch()..start();
      final cachedPage = await _approvedCreatorTemplateService
          .fetchApprovedTemplatesPageFromCache(
            pageSize: hadVisibleTemplates
                ? _remoteApprovedTemplates.length.clamp(
                    _startupCacheWarmTemplatesPageSize,
                    _templatesPageSize,
                  )
                : _startupCacheWarmTemplatesPageSize,
          );
      final cacheQueryMs = cacheQueryStopwatch.elapsedMilliseconds;
      if (hadVisibleTemplates &&
          _startupSnapshotHydrationDeferred &&
          _remoteApprovedTemplates.isNotEmpty) {
        if (mounted) {
          setState(() {
            _templatesLoading = false;
            _templatesHasMore = cachedPage.hasMore;
            _templatesLastDocument = cachedPage.lastDocument;
          });
        }
        _scheduleStartupRichPosterPreviewActivation(
          initialDelay: const Duration(milliseconds: 40),
        );
        _homeDebugLog(
          '[StartupTiming] templates_cache_skipped_after_snapshot '
          't=${_startupStopwatch.elapsedMilliseconds}ms '
          'duration=${stopwatch.elapsedMilliseconds}ms current=${_remoteApprovedTemplates.length} '
          'cacheQueryMs=$cacheQueryMs',
        );
        if (!shouldContinueAfterStartupSnapshot) {
          return;
        }
      }
      if (mounted && cachedPage.templates.isNotEmpty) {
        final mappingStopwatch = Stopwatch()..start();
        final mapped = await _mapTemplatesOffMain(
          cachedPage.templates,
          phase: hadVisibleTemplates ? 'cache' : 'cold_cache',
        );
        final mappingMs = mappingStopwatch.elapsedMilliseconds;
        if (!mounted) {
          return;
        }
        final changed = !_sameTemplateSequence(
          _remoteApprovedTemplates,
          mapped,
        );
        if (changed || _templatesLoading) {
          if (hadVisibleTemplates && _remoteApprovedTemplates.isNotEmpty) {
            setState(() {
              _templatesLoading = false;
              _templatesHasMore = cachedPage.hasMore;
              _templatesLastDocument = cachedPage.lastDocument;
            });
            _scheduleStartupRichPosterPreviewActivation();
            _homeDebugLog(
              '[StartupTiming] templates_cache_preserved_visible '
              't=${_startupStopwatch.elapsedMilliseconds}ms '
              'duration=${stopwatch.elapsedMilliseconds}ms current=${_remoteApprovedTemplates.length} '
              'cacheCount=${mapped.length} cacheQueryMs=$cacheQueryMs mappingMs=$mappingMs',
            );
            if (!shouldContinueAfterStartupSnapshot) {
              return;
            }
          }
          final setStateStopwatch = Stopwatch()..start();
          setState(() {
            _remoteApprovedTemplates = mapped;
            _rankedAllFeedTemplates = null;
            _allFeedRankingReady = false;
            _templatesLoading = false;
            _templatesHasMore = cachedPage.hasMore;
            _templatesLastDocument = cachedPage.lastDocument;
          });
          final setStateMs = setStateStopwatch.elapsedMilliseconds;
          _hydratedCategorySlugs.clear();
          _scheduleStartupRichPosterPreviewActivation();
          _scheduleSelectedCategoryPrefetchAfterVisibleTemplates();
          _logPostPaintTimingOnce(
            kind: 'first_cached_feed_paint',
            alreadyLogged: _loggedFirstCachedFeedPaint,
            markLogged: () => _loggedFirstCachedFeedPaint = true,
            count: mapped.length,
          );
          _homeDebugLog(
            '[StartupTiming] templates_cache_ready t=${_startupStopwatch.elapsedMilliseconds}ms '
            'duration=${stopwatch.elapsedMilliseconds}ms count=${mapped.length} '
            'cacheQueryMs=$cacheQueryMs mappingMs=$mappingMs setStateMs=$setStateMs',
          );
          _scheduleStartupTemplateSnapshotPersist(mapped);
        } else {
          final setStateStopwatch = Stopwatch()..start();
          setState(() {
            _templatesLoading = false;
            _templatesHasMore = cachedPage.hasMore;
            _templatesLastDocument = cachedPage.lastDocument;
          });
          _scheduleStartupRichPosterPreviewActivation();
          _homeDebugLog(
            '[StartupTiming] templates_cache_ready t=${_startupStopwatch.elapsedMilliseconds}ms '
            'duration=${stopwatch.elapsedMilliseconds}ms count=${mapped.length} '
            'cacheQueryMs=$cacheQueryMs mappingMs=$mappingMs '
            'setStateMs=${setStateStopwatch.elapsedMilliseconds}',
          );
        }
      } else if (!hadVisibleTemplates) {
        _homeDebugLog(
          '[StartupTiming] templates_cache_ready t=${_startupStopwatch.elapsedMilliseconds}ms '
          'duration=${stopwatch.elapsedMilliseconds}ms count=0 '
          'cacheQueryMs=$cacheQueryMs mappingMs=0 setStateMs=0',
        );
      }
      final startupFeedAlreadyVisible = _remoteApprovedTemplates.isNotEmpty;

      if (shouldUseSlotAwareStartupFetch) {
        final fetchTask = _startStartupTimelineTask(
          'fetch',
          arguments: <String, Object?>{
            'phase': 'primary',
            'tag': startupPrimaryTag ?? 'generic_fallback',
            'target': _initialPriorityPrimaryFetchSize,
          },
        );
        final primaryFetchStopwatch = Stopwatch()..start();
        final primaryTemplates = await startupPrimaryFuture!;
        fetchTask.finish(
          arguments: <String, Object?>{
            'phase': 'primary',
            'count': primaryTemplates.length,
          },
        );
        _homeDebugLog(
          '[StartupTiming] primary_fetch_done t=${_startupStopwatch.elapsedMilliseconds}ms '
          'waitMs=${primaryFetchStopwatch.elapsedMilliseconds} count=${primaryTemplates.length}',
        );
        if (!mounted) {
          return;
        }
        final primaryMapStopwatch = Stopwatch()..start();
        final primaryItems = await _mapTemplatesOffMain(
          primaryTemplates
              .take(_initialPriorityPrimaryFetchSize)
              .toList(growable: false),
          phase: 'primary',
        );
        _homeDebugLog(
          '[StartupTiming] primary_map_done t=${_startupStopwatch.elapsedMilliseconds}ms '
          'waitMs=${primaryMapStopwatch.elapsedMilliseconds} count=${primaryItems.length}',
        );
        if (!mounted) {
          return;
        }
        final startupDynamicTags = _activeDynamicAllFeedTags(
          context.currentLanguage,
        );
        final prioritizedPrimaryItems =
            _promoteDynamicAllFeedStartupBatchWorker(
              primaryItems,
              dynamicTags: startupDynamicTags,
            );
        final visiblePrimaryCount = math.min(
          _startupInitialVisibleTemplateCount,
          prioritizedPrimaryItems.length,
        );
        final initialVisiblePrimaryItems = prioritizedPrimaryItems
            .take(visiblePrimaryCount)
            .toList(growable: false);
        final deferredPrimaryItems =
            prioritizedPrimaryItems.length > visiblePrimaryCount
            ? prioritizedPrimaryItems.sublist(visiblePrimaryCount)
            : const <_TemplateItem>[];
        if (startupFeedAlreadyVisible) {
          unawaited(
            _completeStartupSecondaryHydration(
              deferredPrimaryItems: prioritizedPrimaryItems,
              secondaryFuture: startupSecondaryFuture!,
              genericFuture: startupGenericRemoteFuture,
            ),
          );
          _homeDebugLog(
            '[StartupTiming] templates_primary_merge_only '
            't=${_startupStopwatch.elapsedMilliseconds}ms '
            'duration=${stopwatch.elapsedMilliseconds}ms count=${primaryItems.length} '
            'slot=${startupSlot!.name} primaryTag=${startupPrimaryTag ?? 'none'} secondaryTag=${startupSecondaryTag ?? 'none'}',
          );
          return;
        }
        await _applyStartupTemplateState(
          initialVisiblePrimaryItems,
          hasMore: true,
          lastDocument: null,
          phase: 'primary_ready',
          logFirstRemotePaint: true,
          primaryCount: initialVisiblePrimaryItems.length,
        );
        _scheduleStartupTemplateSnapshotPersist(initialVisiblePrimaryItems);
        unawaited(
          _completeStartupSecondaryHydration(
            deferredPrimaryItems: deferredPrimaryItems,
            secondaryFuture: startupSecondaryFuture!,
            genericFuture: startupGenericRemoteFuture,
          ),
        );
        _homeDebugLog(
          '[StartupTiming] templates_primary_ready t=${_startupStopwatch.elapsedMilliseconds}ms '
          'duration=${stopwatch.elapsedMilliseconds}ms count=${primaryItems.length} '
          'slot=${startupSlot!.name} primaryTag=${startupPrimaryTag ?? 'none'} secondaryTag=${startupSecondaryTag ?? 'none'}',
        );
        return;
      }

      final remotePage = await startupGenericRemoteFuture;
      if (!mounted) {
        return;
      }
      final remoteMappingStopwatch = Stopwatch()..start();
      var mapped = await _mapTemplatesOffMain(
        remotePage.templates,
        phase: 'page',
      );
      var mappingMs = remoteMappingStopwatch.elapsedMilliseconds;
      if (mapped.isEmpty) {
        final retryPage = await _approvedCreatorTemplateService
            .fetchApprovedTemplatesPage(
              pageSize: _templatesPageSize,
              source: Source.server,
            );
        if (!mounted) {
          return;
        }
        final retryMappingStopwatch = Stopwatch()..start();
        mapped = await _mapTemplatesOffMain(
          retryPage.templates,
          phase: 'retry',
        );
        mappingMs = retryMappingStopwatch.elapsedMilliseconds;
        final visibleRetryCount = math.min(
          _startupInitialVisibleTemplateCount,
          mapped.length,
        );
        final initialVisibleRetryItems = mapped
            .take(visibleRetryCount)
            .toList(growable: false);
        final deferredRetryItems = mapped.length > visibleRetryCount
            ? mapped.sublist(visibleRetryCount)
            : const <_TemplateItem>[];
        if (startupFeedAlreadyVisible) {
          if (mapped.isNotEmpty && mounted) {
            unawaited(() async {
              await WidgetsBinding.instance.endOfFrame;
              await Future<void>.delayed(const Duration(milliseconds: 48));
              if (!mounted) {
                return;
              }
              await _appendTemplatesIncrementally(
                mapped,
                hasMore: retryPage.hasMore,
                lastDocument: retryPage.lastDocument,
                phase: 'retry_merge_only',
              );
              if (!mounted) {
                return;
              }
              _scheduleProgressiveTemplateHydration();
            }());
          } else {
            _scheduleProgressiveTemplateHydration();
          }
          _homeDebugLog(
            '[StartupTiming] templates_retry_merge_only t=${_startupStopwatch.elapsedMilliseconds}ms '
            'duration=${stopwatch.elapsedMilliseconds}ms count=${mapped.length} '
            'mappingMs=$mappingMs setStateMs=deferred',
          );
          return;
        }
        await _applyStartupTemplateState(
          initialVisibleRetryItems,
          hasMore: retryPage.hasMore,
          lastDocument: retryPage.lastDocument,
          phase: 'retry_ready',
          logFirstRemotePaint: true,
        );
        _scheduleStartupTemplateSnapshotPersist(initialVisibleRetryItems);
        if (deferredRetryItems.isNotEmpty && mounted) {
          unawaited(() async {
            await WidgetsBinding.instance.endOfFrame;
            await Future<void>.delayed(const Duration(milliseconds: 48));
            if (!mounted) {
              return;
            }
            await _appendTemplatesIncrementally(
              deferredRetryItems,
              hasMore: retryPage.hasMore,
              lastDocument: retryPage.lastDocument,
              phase: 'retry_merge',
            );
            if (!mounted) {
              return;
            }
            _scheduleProgressiveTemplateHydration();
          }());
        } else {
          _scheduleProgressiveTemplateHydration();
        }
        _homeDebugLog(
          '[StartupTiming] templates_retry_ready t=${_startupStopwatch.elapsedMilliseconds}ms '
          'duration=${stopwatch.elapsedMilliseconds}ms count=${mapped.length} '
          'mappingMs=$mappingMs setStateMs=deferred',
        );
        return;
      }
      final visibleRemoteCount = math.min(
        _startupInitialVisibleTemplateCount,
        mapped.length,
      );
      final initialVisibleRemoteItems = mapped
          .take(visibleRemoteCount)
          .toList(growable: false);
      final deferredRemoteItems = mapped.length > visibleRemoteCount
          ? mapped.sublist(visibleRemoteCount)
          : const <_TemplateItem>[];
      if (startupFeedAlreadyVisible) {
        if (mapped.isNotEmpty && mounted) {
          unawaited(() async {
            await WidgetsBinding.instance.endOfFrame;
            await Future<void>.delayed(const Duration(milliseconds: 48));
            if (!mounted) {
              return;
            }
            await _appendTemplatesIncrementally(
              mapped,
              hasMore: remotePage.hasMore,
              lastDocument: remotePage.lastDocument,
              phase: 'remote_merge_only',
            );
            if (!mounted) {
              return;
            }
            _scheduleProgressiveTemplateHydration();
          }());
        } else {
          _scheduleProgressiveTemplateHydration();
        }
        _homeDebugLog(
          '[StartupTiming] templates_remote_merge_only t=${_startupStopwatch.elapsedMilliseconds}ms '
          'duration=${stopwatch.elapsedMilliseconds}ms count=${mapped.length} '
          'mappingMs=$mappingMs setStateMs=deferred',
        );
        return;
      }
      await _applyStartupTemplateState(
        initialVisibleRemoteItems,
        hasMore: remotePage.hasMore,
        lastDocument: remotePage.lastDocument,
        phase: 'remote_ready',
        logFirstRemotePaint: true,
      );
      _scheduleStartupTemplateSnapshotPersist(initialVisibleRemoteItems);
      if (deferredRemoteItems.isNotEmpty && mounted) {
        unawaited(() async {
          await WidgetsBinding.instance.endOfFrame;
          await Future<void>.delayed(const Duration(milliseconds: 48));
          if (!mounted) {
            return;
          }
          await _appendTemplatesIncrementally(
            deferredRemoteItems,
            hasMore: remotePage.hasMore,
            lastDocument: remotePage.lastDocument,
            phase: 'remote_merge',
          );
          if (!mounted) {
            return;
          }
          _scheduleProgressiveTemplateHydration();
        }());
      } else {
        _scheduleProgressiveTemplateHydration();
      }
      _homeDebugLog(
        '[StartupTiming] templates_remote_ready t=${_startupStopwatch.elapsedMilliseconds}ms '
        'duration=${stopwatch.elapsedMilliseconds}ms count=${mapped.length} '
        'mappingMs=$mappingMs setStateMs=deferred',
      );
    } catch (error, stackTrace) {
      _homeDebugLogStack('home template load failed: $error', stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _templatesLoading = false;
        _templatesLoadingMore = false;
      });
    }
  }

  bool _sameTemplateSequence(
    List<_TemplateItem> left,
    List<_TemplateItem> right,
  ) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (_templateSequenceKey(left[i]) != _templateSequenceKey(right[i])) {
        return false;
      }
    }
    return true;
  }

  void _logPostPaintTimingOnce({
    required String kind,
    required bool alreadyLogged,
    required VoidCallback markLogged,
    required int count,
  }) {
    if (alreadyLogged) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || alreadyLogged) {
        return;
      }
      markLogged();
      _homeDebugLog(
        '[StartupTiming] $kind=${_startupStopwatch.elapsedMilliseconds}ms count=$count',
      );
    });
  }

  void _scheduleDeferredAllFeedRanking() {
    if (_lockedAllFeedTemplates != null ||
        _allFeedRankingInFlight ||
        _remoteApprovedTemplates.length < 8) {
      return;
    }
    _allFeedRankingInFlight = true;
    final rankingSource = _remoteApprovedTemplates;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 1400));
        if (!mounted ||
            _lockedAllFeedTemplates != null ||
            !identical(_remoteApprovedTemplates, rankingSource)) {
          _allFeedRankingInFlight = false;
          if (mounted &&
              _lockedAllFeedTemplates == null &&
              !identical(_remoteApprovedTemplates, rankingSource)) {
            _scheduleDeferredAllFeedRanking();
          }
          return;
        }
        final now = IstTimeService.now();
        final rankingTask = _startStartupTimelineTask(
          'ranking',
          arguments: <String, Object?>{
            'count': _remoteApprovedTemplates.length,
            'slot': _activeHomeFeedTimeSlot.name,
          },
        );
        try {
          final activeDynamicTags = _activeDynamicAllFeedTags(
            context.currentLanguage,
          );
          final ranked = await Isolate.run<List<_TemplateItem>>(
            () => _rankAllFeedTemplatesWorker(
              _AllFeedRankingWorkerRequest(
                templates: _remoteApprovedTemplates,
                slot: _activeHomeFeedTimeSlot,
                year: now.year,
                month: now.month,
                day: now.day,
                dynamicTags: activeDynamicTags,
                recentTemplateKeys: _recentAllFeedTemplateKeys,
              ),
            ),
          );
          rankingTask.finish(
            arguments: <String, Object?>{'count': ranked.length},
          );
          if (!mounted ||
              _lockedAllFeedTemplates != null ||
              !identical(_remoteApprovedTemplates, rankingSource)) {
            _allFeedRankingInFlight = false;
            if (mounted &&
                _lockedAllFeedTemplates == null &&
                !identical(_remoteApprovedTemplates, rankingSource)) {
              _scheduleDeferredAllFeedRanking();
            }
            return;
          }
          _allFeedRankingReady = true;
          _allFeedRankingInFlight = false;
          _templateProjectionCache = null;
          _templateProjectionIdentity = null;
          _debugLogAllFeedRanking(
            ranked,
            slot: _activeHomeFeedTimeSlot,
            dynamicTags: activeDynamicTags,
          );
          _rememberRecentAllFeedTemplates(source: ranked);
          setState(() {
            _rankedAllFeedTemplates = ranked;
          });
        } catch (error) {
          rankingTask.finish(
            arguments: <String, Object?>{'error': error.toString()},
          );
          _allFeedRankingInFlight = false;
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _loggedRankingComplete) {
            return;
          }
          _loggedRankingComplete = true;
          _homeDebugLog(
            '[StartupTiming] ranking_complete=${_startupStopwatch.elapsedMilliseconds}ms',
          );
        });
      }());
    });
  }

  void _scheduleProgressiveTemplateHydration() {
    if (_progressiveHydrationQueued ||
        !_templatesHasMore ||
        _templatesLastDocument == null) {
      return;
    }
    // Keep startup feed visually stable. Additional pages can load on demand
    // when the user scrolls near the bottom instead of mutating the visible
    // list immediately after first paint.
    if (_remoteApprovedTemplates.isNotEmpty) {
      return;
    }
    _progressiveHydrationQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 480));
        if (!mounted) {
          return;
        }
        await _loadMoreApprovedCreatorTemplates();
      }());
    });
  }

  bool _sameHomeBannerSequence(
    List<AppHomeBanner> left,
    List<AppHomeBanner> right,
  ) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      final a = left[index];
      final b = right[index];
      if (a.id != b.id ||
          a.imageUrl != b.imageUrl ||
          a.sortOrder != b.sortOrder ||
          a.active != b.active ||
          a.title != b.title ||
          a.subtitle != b.subtitle ||
          a.ctaLabel != b.ctaLabel ||
          a.ctaTarget != b.ctaTarget ||
          a.placement != b.placement ||
          a.targetState != b.targetState ||
          a.targetDistrict != b.targetDistrict ||
          a.targetCity != b.targetCity) {
        return false;
      }
    }
    return true;
  }

  String _templateSequenceKey(_TemplateItem item) {
    final id = item.templateId?.trim() ?? '';
    if (id.isNotEmpty) {
      return id;
    }
    final image = item.imageUrl?.trim() ?? '';
    if (image.isNotEmpty) {
      return image;
    }
    final storage = item.imageStoragePath?.trim() ?? '';
    if (storage.isNotEmpty) {
      return storage;
    }
    final video = item.videoUrl?.trim() ?? '';
    return '${item.titleEn}|$video';
  }

  Future<bool> _loadMoreApprovedCreatorTemplates() async {
    if (_templatesLoading ||
        _templatesLoadingMore ||
        !_templatesHasMore ||
        _templatesLastDocument == null) {
      return false;
    }
    setState(() => _templatesLoadingMore = true);
    try {
      final page = await _approvedCreatorTemplateService
          .fetchApprovedTemplatesPage(
            pageSize: _templatesPageSize,
            startAfterDocument: _templatesLastDocument,
          );
      if (!mounted) {
        return false;
      }
      final mapped = await _mapTemplatesOffMain(
        page.templates,
        phase: 'load_more',
      );
      if (!mounted) {
        return false;
      }
      final lockedMerged = await _extendLockedAllFeedTemplates(
        mapped,
        phase: 'load_more',
      );
      if (!mounted) {
        return false;
      }
      final merged = await _mergeTemplateListsOffMain(<List<_TemplateItem>>[
        _remoteApprovedTemplates,
        mapped,
      ], phase: 'load_more_merge');
      if (!mounted) {
        return false;
      }
      final freshCount = math.max(
        merged.length - _remoteApprovedTemplates.length,
        0,
      );
      if (kDebugMode) {
        final droppedByDedupe = mapped.length - freshCount;
        _homeDebugLog(
          '[PosterUI] loadMore pageMapped=${mapped.length} fresh=$freshCount '
          'droppedByDedupe=$droppedByDedupe '
          'remoteBefore=${_remoteApprovedTemplates.length} hasMore=${page.hasMore}',
        );
      }
      setState(() {
        _remoteApprovedTemplates = merged;
        if (lockedMerged != null) {
          _lockedAllFeedTemplates = lockedMerged;
        }
        _rankedAllFeedTemplates = null;
        _allFeedRankingReady = false;
        _startupSnapshotHydrationDeferred = false;
        _templatesLoadingMore = false;
        _templatesHasMore = page.hasMore;
        _templatesLastDocument = page.lastDocument;
      });
      _templateProjectionCache = null;
      _templateProjectionIdentity = null;
      _categoryListCache = null;
      _categoryListIdentity = null;
      _scheduleDeferredAllFeedRanking();
      return freshCount > 0 || page.hasMore;
    } catch (error, stackTrace) {
      _homeDebugLogStack('loadMore failed: $error', stackTrace);
      if (mounted) {
        setState(() => _templatesLoadingMore = false);
      }
      return false;
    }
  }

  void _onPosterScroll() {
    if (!_posterScrollController.hasClients) {
      return;
    }
    final position = _posterScrollController.position;
    if (_selectedCategorySlug == _allCategorySlug &&
        _lockedAllFeedTemplates == null &&
        position.pixels > 24) {
      _lockedAllFeedTemplates = List<_TemplateItem>.of(
        _currentAllFeedDisplaySource(),
      );
    }
    final hasScrollableExtent = position.maxScrollExtent > 0;
    final userHasActuallyScrolled = position.pixels > 120;
    if (_posterFeedLoadMoreArmed &&
        hasScrollableExtent &&
        userHasActuallyScrolled &&
        position.pixels >= position.maxScrollExtent - 320) {
      _posterFeedLoadMoreArmed = false;
      unawaited(_loadMoreApprovedCreatorTemplates());
    }
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
    final localProfile = await PosterProfileService.loadLocal();
    if (!mounted) {
      return;
    }
    if (_viewerPosterProfile != localProfile) {
      setState(() {
        _viewerPosterProfile = localProfile;
      });
    }
    _deferPosterProfileImageWarmup(
      localProfile,
      const Duration(milliseconds: 1500),
    );

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    final remoteProfile = await PosterProfileService.refreshFromRemote(
      localProfile: localProfile,
    ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    if (!mounted || remoteProfile == null) {
      return;
    }
    if (_viewerPosterProfile != remoteProfile) {
      setState(() {
        _viewerPosterProfile = remoteProfile;
      });
    }
    _deferPosterProfileImageWarmup(
      remoteProfile,
      const Duration(milliseconds: 450),
    );
  }

  void _deferPosterProfileImageWarmup(
    PosterProfileData profile,
    Duration delay,
  ) {
    unawaited(() async {
      await Future<void>.delayed(delay);
      if (!mounted) {
        return;
      }
      await _warmPosterProfileImage(profile);
    }());
  }

  Future<void> _warmPosterProfileImage(PosterProfileData profile) async {
    final imageProvider = PosterProfileService.resolveImageProvider(profile);
    if (imageProvider == null || !mounted) {
      return;
    }
    try {
      await precacheImage(imageProvider, context);
    } catch (error, stackTrace) {
      _homeDebugLogStack('profile image warmup skipped: $error', stackTrace);
    }
  }

  _HomeTemplateProjection _projectTemplatesForHomeFeed({
    required AppLanguage language,
    required _CategoryChipData selectedCategory,
  }) {
    final stopwatch = Stopwatch()..start();
    final projectionIdentity = Object.hash(
      identityHashCode(_remoteApprovedTemplates),
      identityHashCode(_rankedAllFeedTemplates),
      identityHashCode(_lockedAllFeedTemplates),
      _allFeedRankingReady,
      selectedCategory.slug,
      language,
      _searchController.text,
      _religionPreference,
      _religionSelectionReady,
      selectedCategory.slug == _allCategorySlug
          ? Object.hash(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              _activeHomeFeedTimeSlot.name,
            )
          : 0,
    );
    final cached = _templateProjectionCache;
    if (cached != null && _templateProjectionIdentity == projectionIdentity) {
      if (!_loggedFirstFeedProjection) {
        _loggedFirstFeedProjection = true;
        _homeDebugLog(
          '[StartupTiming] first_projection_cached t=${_startupStopwatch.elapsedMilliseconds}ms '
          'duration=${stopwatch.elapsedMilliseconds}ms templates=${cached.templates.length}',
        );
      }
      return cached;
    }

    final baseTemplates = selectedCategory.slug == _allCategorySlug
        ? _currentAllFeedDisplaySource()
        : _remoteApprovedTemplates;
    final filteredTemplates = baseTemplates
        .where((item) => _matchesTemplate(item, language, selectedCategory))
        .toList(growable: false);
    final templates = filteredTemplates;
    final projection = _HomeTemplateProjection(
      filteredTemplates: filteredTemplates,
      templates: templates,
    );
    _templateProjectionCache = projection;
    _templateProjectionIdentity = projectionIdentity;
    if (!_loggedFirstFeedProjection) {
      _loggedFirstFeedProjection = true;
      _homeDebugLog(
        '[StartupTiming] first_projection_built t=${_startupStopwatch.elapsedMilliseconds}ms '
        'duration=${stopwatch.elapsedMilliseconds}ms filtered=${filteredTemplates.length} '
        'final=${templates.length}',
      );
    }
    return projection;
  }

  List<_CategoryChipData> _buildCategoriesForHome(AppLanguage language) {
    final availabilityIdentity = Object.hashAll(
      _dynamicCategoryAvailabilityBySlug.entries.toList(growable: false)
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    final manualCategoryIdentity = Object.hashAll(
      _manualEventCategories
          .map((item) => '${item.slug}:${item.label}')
          .toList(growable: false)
        ..sort(),
    );
    final identity = Object.hash(
      identityHashCode(_remoteApprovedTemplates),
      language,
      _templatesLoading,
      _religionPreference,
      _religionSelectionReady,
      Object.hashAll(
        _selectedPoliticalPartyIds.toList(growable: false)..sort(),
      ),
      availabilityIdentity,
      manualCategoryIdentity,
      _startupSnapshotHydrationDeferred,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      IstTimeService.now().hour,
    );
    final cached = _categoryListCache;
    if (cached != null && _categoryListIdentity == identity) {
      return cached;
    }
    final staticCategories = _buildStaticCategories();
    final templateDrivenDynamicCategories =
        _buildLoadedTemplateDynamicCategories(language);
    final scheduledDynamicCategories = _buildDynamicCategories(
      IstTimeService.now(),
      language,
      templatesLoading: _templatesLoading,
    );
    final dynamicCategories = <_CategoryChipData>[
      ...templateDrivenDynamicCategories,
      ...scheduledDynamicCategories,
    ];
    final partyCategories = _buildSelectedPartyCategories(language);
    _homeDebugLog(
      '[DynamicCategoryList] template=${templateDrivenDynamicCategories.map((item) => _normalizeTag(item.slug)).join(",")} '
      'scheduled=${scheduledDynamicCategories.map((item) => _normalizeTag(item.slug)).join(",")} '
      'parties=${partyCategories.map((item) => _normalizeTag(item.slug)).join(",")}',
    );
    final categories = _religionSelectionReady
        ? _mergeCategories(staticCategories, dynamicCategories, partyCategories)
        : <_CategoryChipData>[_allCategoryChip()];
    _homeDebugLog(
      '[CategoryList] slugs=${categories.map((item) => _normalizeTag(item.slug)).join(",")}',
    );
    _categoryListCache = categories;
    _categoryListIdentity = identity;
    return categories;
  }

  Future<void> _refreshHomeFeed() async {
    if (_homeRefreshing) {
      return;
    }
    setState(() {
      _homeRefreshing = true;
    });
    _resetAllFeedScrollOrderLock();
    _progressiveHydrationQueued = false;
    _allFeedRankingReady = false;
    _allFeedRankingInFlight = false;
    _rankedAllFeedTemplates = null;
    _searchFocusNode.unfocus();
    try {
      await Future.wait<void>(<Future<void>>[
        _loadHomeBanners(),
        _loadApprovedCreatorTemplates(forceRefresh: true),
        _loadManualEventCategories(),
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
      final version = packageInfo.version.trim();
      if (_installedAppVersion == version) {
        return;
      }
      setState(() => _installedAppVersion = version);
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
      if (_hasRatedApp == hasRated) {
        return;
      }
      setState(() => _hasRatedApp = hasRated);
    } catch (_) {}
  }

  Future<void> _handlePlayStoreEngagementOnHomeOpen() async {
    if (!mounted) {
      return;
    }
    try {
      await _loadPromoCardPreferences();
      if (!mounted) {
        return;
      }
      await PlayEngagementService.instance.handleHomeOpen(
        hasRatedApp: _hasRatedApp,
        onReviewRecorded: _markAppRated,
      );
    } catch (error, stackTrace) {
      _homeDebugLogStack(
        'play engagement startup flow skipped: $error',
        stackTrace,
      );
    }
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
                'డౌన్‌లోడ్, షేరింగ్ మరియు మెంబర్‌షిప్ సౌకర్యాల కోసం సబ్‌స్క్రైబ్ చేయండి.',
            english:
                'Subscribe for downloads, sharing, and membership benefits.',
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

  bool _shouldShowHomeBannerAdFallback(SubscriptionBackendResult? entitlement) {
    if (!AppPublicInfo.hasHomeBannerAdUnitId) {
      return false;
    }
    if (entitlement?.hasAccess == true) {
      return false;
    }
    if (InAppPurchaseGateway.playStoreProActive) {
      return false;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && entitlement == null) {
      return false;
    }
    return true;
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
    await _openSubscriptionPlan();
  }

  Future<void> _openWebsiteSearch() async {
    final query = _searchController.text.trim();
    _searchFocusNode.unfocus();
    final baseUri = Uri.tryParse(AppPublicInfo.assetSearchUrl);
    if (baseUri == null) {
      return;
    }
    final uri = query.isEmpty
        ? baseUri
        : baseUri.replace(
            queryParameters: <String, String>{
              ...baseUri.queryParameters,
              'q': query,
            },
          );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened && mounted) {
      _searchController.clear();
      setState(() {});
    }
  }

  Future<void> _openSubscriptionPlan({bool startPurchaseOnOpen = false}) async {
    await _pushSubscriptionPlanRoute(startPurchaseOnOpen: startPurchaseOnOpen);
    if (!mounted) {
      return;
    }
    final result = await SubscriptionBackendService().fetchEntitlement(
      forceRefresh: true,
    );
    if (!mounted || result.hasAccess) {
      return;
    }
    await showSubscriptionExitVideoPromptIfAvailable(
      context,
      onSubscribe: (_) => _pushSubscriptionPlanRoute(startPurchaseOnOpen: true),
    );
  }

  Future<void> _pushSubscriptionPlanRoute({
    bool startPurchaseOnOpen = false,
  }) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SubscriptionPlanScreen(startPurchaseOnOpen: startPurchaseOnOpen),
      ),
    );
  }

  Future<void> _openUserUploadsSheet() async {
    if (!mounted) {
      return;
    }
    final strings = context.strings;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Future<void> openUploadPoster() async {
          Navigator.of(sheetContext).pop();
          if (!mounted) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const UserPosterUploadsScreen(initialTabIndex: 0),
            ),
          );
        }

        Future<void> openUploadStatus() async {
          Navigator.of(sheetContext).pop();
          if (!mounted) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CommunityStatusUploadScreen(),
            ),
          );
        }

        Widget action({
          required String label,
          required IconData icon,
          required Color color,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: action(
                    icon: Icons.cloud_upload_rounded,
                    color: const Color(0xFFD81B60),
                    label: strings.localized(
                      telugu: 'Upload Poster',
                      english: 'Upload Poster',
                    ),
                    onTap: () => unawaited(openUploadPoster()),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: action(
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF0F766E),
                    label: strings.localized(
                      telugu: 'Upload Status',
                      english: 'Upload Status',
                    ),
                    onTap: () => unawaited(openUploadStatus()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePromoTap(_HomePromoCardType type) async {
    switch (type) {
      case _HomePromoCardType.subscribe:
        if (!mounted) {
          return;
        }
        await _openSubscriptionPlan(startPurchaseOnOpen: true);
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

  void _selectCategory(String slug) {
    if (slug == _selectedCategorySlug) {
      return;
    }
    final language = context.currentLanguage;
    final generation = ++_categoryLoadGeneration;
    setState(() {
      _selectedCategorySlug = slug;
      _categoryLoadingSlug = slug == _allCategorySlug ? null : slug;
    });
    _resetAllFeedScrollOrderLock();
    _schedulePosterFeedResetToTop();
    unawaited(_loadSelectedCategoryUntilVisible(slug, generation, language));
  }

  Future<void> _loadSelectedCategoryUntilVisible(
    String slug,
    int generation,
    AppLanguage language,
  ) async {
    if (slug == _allCategorySlug) {
      return;
    }
    final category = _categoryForSlug(slug, language);
    final matchingCount = _remoteApprovedTemplates
        .where((item) => _matchesTemplate(item, language, category))
        .length;
    if (kDebugMode) {
      _homeDebugLog(
        '[PosterUI] categoryPrefetch slug=$slug localMatches=$matchingCount '
        'remoteCount=${_remoteApprovedTemplates.length} hasMore=$_templatesHasMore',
      );
    }
    final normalizedSlug = _normalizeTag(slug);
    final needsHydration = !_hydratedCategorySlugs.contains(normalizedSlug);
    final hasEnoughLocalMatches = matchingCount >= _templatesPageSize;
    if (hasEnoughLocalMatches && needsHydration) {
      _hydratedCategorySlugs.add(normalizedSlug);
      if (kDebugMode) {
        _homeDebugLog(
          '[PosterUI] categoryPrefetch slug=$slug skipped=local_satisfied '
          'localMatches=$matchingCount pageTarget=$_templatesPageSize',
        );
      }
    }
    if ((matchingCount < _templatesPageSize && needsHydration) &&
        mounted &&
        generation == _categoryLoadGeneration) {
      if (_categoryLoadingSlug != slug) {
        setState(() => _categoryLoadingSlug = slug);
      }
      await _topUpSelectedCategoryFromServer(slug, generation);
    }
    if (mounted &&
        generation == _categoryLoadGeneration &&
        _categoryLoadingSlug == slug) {
      setState(() => _categoryLoadingSlug = null);
    }
  }

  Future<void> _topUpSelectedCategoryFromServer(
    String slug,
    int generation,
  ) async {
    final normalizedSlug = _normalizeTag(slug);
    if (normalizedSlug.isEmpty || normalizedSlug == _allCategorySlug) {
      return;
    }
    final targeted = await _approvedCreatorTemplateService
        .fetchAllApprovedTemplatesForCategory(
          categoryId: normalizedSlug,
          source: Source.server,
          scanLimit: _templatesPageSize * 2,
        );
    if (!mounted || generation != _categoryLoadGeneration || targeted.isEmpty) {
      if (normalizedSlug.isNotEmpty) {
        _hydratedCategorySlugs.add(normalizedSlug);
      }
      return;
    }
    final mapped = await _mapTemplatesOffMain(
      targeted,
      phase: 'category_topup',
    );
    if (!mounted || generation != _categoryLoadGeneration) {
      return;
    }
    final merged = await _mergeTemplateListsOffMain(<List<_TemplateItem>>[
      _remoteApprovedTemplates,
      mapped,
    ], phase: 'category_topup_merge');
    if (!mounted || generation != _categoryLoadGeneration) {
      return;
    }
    final freshCount = math.max(
      merged.length - _remoteApprovedTemplates.length,
      0,
    );
    if (freshCount == 0) {
      _homeDebugLog(
        '[PosterUI] categoryTopUp slug=$slug targeted=${mapped.length} fresh=0',
      );
      return;
    }
    _homeDebugLog(
      '[PosterUI] categoryTopUp slug=$slug targeted=${mapped.length} fresh=$freshCount',
    );
    setState(() {
      _remoteApprovedTemplates = merged;
      _rankedAllFeedTemplates = null;
      _allFeedRankingReady = false;
    });
    _templateProjectionCache = null;
    _templateProjectionIdentity = null;
    _categoryListCache = null;
    _categoryListIdentity = null;
    _scheduleDeferredAllFeedRanking();
    _hydratedCategorySlugs.add(normalizedSlug);
  }

  _CategoryChipData _categoryForSlug(String slug, AppLanguage language) {
    final staticCategories = _buildStaticCategories();
    final dynamicCategories = _buildDynamicCategories(
      IstTimeService.now(),
      language,
      templatesLoading: _templatesLoading,
    );
    final categories = _mergeCategories(
      staticCategories,
      dynamicCategories,
      _buildSelectedPartyCategories(language),
    );
    return categories.firstWhere(
      (chip) => chip.slug == slug,
      orElse: () => _CategoryChipData(
        slug: slug,
        label: slug.replaceAll(RegExp(r'[_-]+'), ' ').trim(),
        matchTags: <String>[slug],
      ),
    );
  }

  void _schedulePosterFeedResetToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_posterScrollController.hasClients) {
        return;
      }
      final position = _posterScrollController.position;
      if (position.pixels <= 0) {
        return;
      }
      final target = position.minScrollExtent;
      if (!position.hasContentDimensions ||
          !target.isFinite ||
          !position.pixels.isFinite) {
        _posterScrollController.jumpTo(0);
        return;
      }
      unawaited(
        _posterScrollController
            .animateTo(
              target,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            )
            .catchError((_) {
              if (_posterScrollController.hasClients) {
                _posterScrollController.jumpTo(0);
              }
            }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.currentLanguage;
    final categories = _buildCategoriesForHome(language);
    final activeCategorySlug =
        categories.any((chip) => chip.slug == _selectedCategorySlug)
        ? _selectedCategorySlug
        : _allCategorySlug;
    final selectedCategory = categories.firstWhere(
      (chip) => chip.slug == activeCategorySlug,
      orElse: _allCategoryChip,
    );
    final strings = context.strings;
    final projection = _projectTemplatesForHomeFeed(
      language: language,
      selectedCategory: selectedCategory,
    );
    final filteredTemplates = projection.filteredTemplates;
    final templates = projection.templates;
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
    _debugLogCategoryPipeline(
      language: language,
      selectedCategory: selectedCategory,
      filteredTemplates: filteredTemplates,
      finalTemplates: templates,
      feedEntriesCount: feedEntries.length,
    );
    // Keep the poster feed visible as soon as templates are ready. Profile
    // refresh can continue in parallel without blanking the full home list.
    final hidePosterFeed =
        _templatesLoading ||
        (!_religionSelectionReady && _remoteApprovedTemplates.isEmpty);
    final loadingSelectedCategory =
        _categoryLoadingSlug == activeCategorySlug && templates.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_openUserUploadsSheet()),
        tooltip: 'Community Uploads',
        backgroundColor: const Color(0xFFD81B60),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: <Widget>[
          RepaintBoundary(
            child: _HomeHeader(
              onCreateTap: _onCreateTap,
              onProfileTap: _openProfile,
              viewerPosterProfile: _viewerPosterProfile,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchChanged: (_) {},
              onSearchSubmitted: _openWebsiteSearch,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHomeFeed,
              color: const Color(0xFF0F172A),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.dragDetails != null) {
                    _posterFeedLoadMoreArmed = true;
                  }
                  return false;
                },
                child: CustomScrollView(
                  // Keep prebuild work small so launch focuses on visible content.
                  // ignore: deprecated_member_use
                  cacheExtent: _homeFeedCacheExtent,
                  controller: _posterScrollController,
                  physics: _posterPhotoDragInProgress
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RepaintBoundary(
                          child: SizedBox(
                            height: 46,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 7),
                              itemBuilder: (_, index) => _CategoryChip(
                                data: categories[index],
                                isSelected:
                                    categories[index].slug ==
                                    activeCategorySlug,
                                onTap: () {
                                  final nextSlug = categories[index].slug;
                                  _selectCategory(nextSlug);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _HomeCommunityStatusStrip(
                        onAddStatus: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CommunityStatusUploadScreen(),
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
                              _shouldShowHomeBannerAdFallback(
                                effectiveEntitlement,
                              );
                          if (!shouldShowAdFallback ||
                              !_adFallbackSlotEnabled) {
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
                    if (hidePosterFeed || loadingSelectedCategory)
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
                            title: strings.homeEmptyPostersTitle,
                            subtitle: strings.homeEmptyPostersSubtitle,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
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
                                  item.templateId?.trim().isNotEmpty == true
                                      ? item.templateId!.trim()
                                      : '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath ?? item.videoUrl ?? 'poster'}',
                                ),
                                item: item,
                                hostContext: context,
                                language: language,
                                preferUltraLightImage:
                                    activeCategorySlug == _allCategorySlug &&
                                    index == 0 &&
                                    !_startupRichPosterPreviewReady,
                                deferRichPosterPreview:
                                    !_startupRichPosterPreviewReady,
                                onOpenSubscriptionPlan:
                                    _pushSubscriptionPlanRoute,
                                viewerPosterProfile: _viewerPosterProfile,
                                posterRenderCycle: _posterRenderCycle,
                                onPosterPhotoDragStateChanged:
                                    _setPosterPhotoDragInProgress,
                              );
                            },
                            childCount: feedEntries.length,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
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

class _HomeReferralCodeDialog extends StatefulWidget {
  const _HomeReferralCodeDialog();

  @override
  State<_HomeReferralCodeDialog> createState() =>
      _HomeReferralCodeDialogState();
}

class _HomeReferralCodeDialogState extends State<_HomeReferralCodeDialog> {
  final ReferralRewardService _service = ReferralRewardService();
  final TextEditingController _controller = TextEditingController();
  bool _applying = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_applying) {
      return;
    }
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorText = context.strings.localized(
          telugu: 'రిఫరల్ కోడ్ నమోదు చేయండి',
          english: 'Enter referral code',
        );
      });
      return;
    }
    setState(() {
      _applying = true;
      _errorText = null;
    });
    try {
      final result = await _service.applyCode(code);
      if (!mounted) {
        return;
      }
      final alreadyApplied = result.message.toLowerCase().contains(
        'already applied',
      );
      if (result.accepted || alreadyApplied) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _applying = false;
        _errorText = result.message.isEmpty
            ? context.strings.localized(
                telugu: 'రిఫరల్ కోడ్ అప్లై కాలేదు',
                english: 'Referral code could not be applied',
              )
            : result.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _applying = false;
        _errorText = context.strings.localized(
          telugu: 'రిఫరల్ కోడ్ అప్లై కాలేదు. మళ్లీ ప్రయత్నించండి',
          english: 'Referral code apply failed. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      insetPadding: EdgeInsets.fromLTRB(28, 16, 28, keyboardInset + 16),
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: <Color>[
                            Color(0xFF14B8A6),
                            Color(0xFF38BDF8),
                            Color(0xFFA78BFA),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.localized(
                        telugu: 'రిఫరల్ కోడ్',
                        english: 'Referral code',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.localized(
                        telugu:
                            'మీ దగ్గర referral code ఉంటే ఇక్కడ enter చేయండి.',
                        english: 'Enter a referral code if you have one.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: strings.localized(
                          telugu: 'రిఫరల్ కోడ్',
                          english: 'Referral code',
                        ),
                        errorText: _errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => unawaited(_apply()),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => _openExternalPublicUrl(
                        context,
                        AppPublicInfo.termsUrl,
                      ),
                      child: Text(
                        strings.localized(
                          telugu: 'నిబంధనలు మరియు షరతులు చూడండి',
                          english: 'View Terms & Conditions',
                        ),
                      ),
                    ),
                    PrimaryButton(
                      label: strings.localized(
                        telugu: 'అప్లై',
                        english: 'Apply',
                      ),
                      loading: _applying,
                      onPressed: () => unawaited(_apply()),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _applying
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        strings.localized(telugu: 'స్కిప్', english: 'Skip'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeCommunityStatusStrip extends StatelessWidget {
  const _HomeCommunityStatusStrip({required this.onAddStatus});

  final VoidCallback onAddStatus;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return StreamBuilder<List<CommunityStatus>>(
      stream: CommunityStatusService.instance.watchVisibleStatuses(),
      builder: (context, snapshot) {
        final statuses = snapshot.data ?? const <CommunityStatus>[];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
        final myStatuses = _statusGroupItemsForUser(statuses, currentUserId);
        final otherGroups = _statusGroups(statuses)
            .where((group) => group.userId != currentUserId)
            .toList(growable: false);
        return SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final group = index == 0
                  ? (myStatuses.isEmpty
                        ? null
                        : _CommunityStatusGroup(statuses: myStatuses))
                  : otherGroups[index - 1];
              final status = group?.latestStatus;
              final isMyStatus = index == 0;
              return _HomeCommunityStatusBubble(
                label: isMyStatus
                    ? strings.localized(
                        telugu: 'My Status',
                        english: 'My Status',
                      )
                    : (group?.displayName.isNotEmpty == true
                          ? group!.displayName
                          : 'User'),
                imageUrl: status?.imageUrl ?? '',
                previewText: status?.text ?? '',
                previewBackgroundColor: status?.backgroundColor ?? 0,
                icon: status == null
                    ? Icons.add_rounded
                    : status.hasImage
                    ? Icons.image_rounded
                    : Icons.format_quote_rounded,
                onTap: status == null
                    ? onAddStatus
                    : () => _showCommunityStatusDialog(context, group!),
                accentColor: status == null
                    ? const Color(0xFF0F766E)
                    : const Color(0xFFD81B60),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemCount: 1 + otherGroups.length,
          ),
        );
      },
    );
  }

  void _showCommunityStatusDialog(
    BuildContext context,
    _CommunityStatusGroup group,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _CommunityStatusViewerScreen(initialGroup: group),
      ),
    );
  }
}

class _CommunityStatusGroup {
  const _CommunityStatusGroup({required this.statuses});

  final List<CommunityStatus> statuses;

  String get userId => statuses.isEmpty ? '' : statuses.first.userId;
  CommunityStatus get latestStatus => statuses.last;
  String get displayName {
    for (final status in statuses) {
      if (status.userName.trim().isNotEmpty) {
        return status.userName.trim();
      }
    }
    return '';
  }
}

List<CommunityStatus> _statusGroupItemsForUser(
  List<CommunityStatus> statuses,
  String? userId,
) {
  final safeUserId = userId?.trim() ?? '';
  if (safeUserId.isEmpty) {
    return const <CommunityStatus>[];
  }
  final items =
      statuses
          .where((status) => status.userId == safeUserId)
          .toList(growable: false)
        ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));
  return items;
}

List<_CommunityStatusGroup> _statusGroups(List<CommunityStatus> statuses) {
  final byUser = <String, List<CommunityStatus>>{};
  for (final status in statuses) {
    final userId = status.userId.trim();
    if (userId.isEmpty) {
      continue;
    }
    byUser.putIfAbsent(userId, () => <CommunityStatus>[]).add(status);
  }
  final groups = byUser.values
      .map((items) {
        items.sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));
        return _CommunityStatusGroup(
          statuses: List<CommunityStatus>.unmodifiable(items),
        );
      })
      .toList(growable: false);
  return groups..sort(
    (a, b) => b.latestStatus.createdAtMillis.compareTo(
      a.latestStatus.createdAtMillis,
    ),
  );
}

class _CommunityStatusViewerScreen extends StatefulWidget {
  const _CommunityStatusViewerScreen({required this.initialGroup});

  final _CommunityStatusGroup initialGroup;

  @override
  State<_CommunityStatusViewerScreen> createState() =>
      _CommunityStatusViewerScreenState();
}

class _CommunityStatusViewerScreenState
    extends State<_CommunityStatusViewerScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _viewDuration = Duration(seconds: 7);
  static const List<String> _reactions = <String>['🔥', '👏', '😍', '🙏', '😠'];

  late final AnimationController _progressController;
  bool _isDeleting = false;
  bool _showingReplies = false;
  bool _isHoldPaused = false;
  int _currentIndex = 0;
  String _lastRecordedStatusId = '';

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(
          vsync: this,
          duration: _viewDuration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted && !_isDeleting) {
            _goToNextOrClose(widget.initialGroup.statuses);
          }
        });
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    _recordActiveView(widget.initialGroup.statuses.first);
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: <SystemUiOverlay>[SystemUiOverlay.top],
      ),
    );
    super.dispose();
  }

  Future<void> _deleteStatus(CommunityStatus status) async {
    if (_isDeleting) {
      return;
    }
    setState(() => _isDeleting = true);
    _progressController.stop();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    unawaited(CommunityStatusService.instance.deleteStatus(status));
  }

  void _recordActiveView(CommunityStatus status) {
    if (_lastRecordedStatusId == status.id) {
      return;
    }
    _lastRecordedStatusId = status.id;
    unawaited(CommunityStatusService.instance.recordView(status.id));
  }

  void _goToNextOrClose(List<CommunityStatus> statuses) {
    if (_currentIndex < statuses.length - 1) {
      setState(() {
        _currentIndex += 1;
      });
      _progressController
        ..reset()
        ..forward();
      _recordActiveView(statuses[_currentIndex]);
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _goToPrevious(List<CommunityStatus> statuses) {
    if (_currentIndex <= 0) {
      _progressController
        ..reset()
        ..forward();
      _recordActiveView(statuses.first);
      return;
    }
    setState(() {
      _currentIndex -= 1;
    });
    _progressController
      ..reset()
      ..forward();
    _recordActiveView(statuses[_currentIndex]);
  }

  Future<void> _showRepliesSheet(CommunityStatus status) async {
    if (_showingReplies || _isDeleting) {
      return;
    }
    setState(() => _showingReplies = true);
    _progressController.stop();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StatusRepliesSheet(status: status),
    );
    if (!mounted) {
      return;
    }
    setState(() => _showingReplies = false);
    if (!_isDeleting && _progressController.value < 1) {
      unawaited(_progressController.forward());
    }
  }

  void _pauseProgressForInput() {
    if (!_isDeleting) {
      _progressController.stop();
    }
  }

  void _resumeProgressAfterInput() {
    if (!_isDeleting && !_showingReplies && _progressController.value < 1) {
      unawaited(_progressController.forward());
    }
  }

  void _pauseProgressForHold() {
    if (_isDeleting || _showingReplies || _progressController.value >= 1) {
      return;
    }
    _isHoldPaused = true;
    _progressController.stop();
  }

  void _resumeProgressAfterHold() {
    if (!_isHoldPaused) {
      return;
    }
    _isHoldPaused = false;
    if (!_isDeleting && !_showingReplies && _progressController.value < 1) {
      unawaited(_progressController.forward());
    }
  }

  double _progressValueForIndex(int index, int total) {
    if (total <= 1) {
      return _progressController.value;
    }
    final safeIndex = index.clamp(0, total - 1);
    return ((safeIndex + _progressController.value) / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityStatus>>(
      stream: CommunityStatusService.instance.watchVisibleStatuses().map(
        (statuses) =>
            _statusGroupItemsForUser(statuses, widget.initialGroup.userId),
      ),
      initialData: widget.initialGroup.statuses,
      builder: (context, snapshot) {
        final statuses = snapshot.data ?? widget.initialGroup.statuses;
        if (statuses.isEmpty && !_isDeleting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          });
        }
        if (_currentIndex >= statuses.length && statuses.isNotEmpty) {
          _currentIndex = statuses.length - 1;
        }
        final status = statuses.isEmpty
            ? widget.initialGroup.latestStatus
            : statuses[_currentIndex];
        _recordActiveView(status);
        final isOwner =
            FirebaseAuth.instance.currentUser?.uid.trim() == status.userId;
        final statusTitle = isOwner
            ? 'My Status'
            : (status.userName.isNotEmpty ? status.userName : 'User');
        final statusColor = Color(
          status.backgroundColor == 0 ? 0xFF4CAF50 : status.backgroundColor,
        );
        return Scaffold(
          backgroundColor: status.imageUrl.isEmpty
              ? statusColor
              : const Color(0xFF050505),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (_) => _pauseProgressForHold(),
            onTapUp: (_) => _resumeProgressAfterHold(),
            onTapCancel: _resumeProgressAfterHold,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -220) {
                _goToNextOrClose(statuses);
              } else if (velocity > 220) {
                _goToPrevious(statuses);
              }
            },
            onVerticalDragEnd: isOwner
                ? (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -220) {
                      unawaited(_showRepliesSheet(status));
                    }
                  }
                : null,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: AnimatedSlide(
                    offset: _isDeleting
                        ? const Offset(0.42, -0.42)
                        : Offset.zero,
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeInBack,
                    child: AnimatedScale(
                      scale: _isDeleting ? 0.08 : 1,
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeInBack,
                      child: AnimatedRotation(
                        turns: _isDeleting ? -0.06 : 0,
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeInBack,
                        child: AnimatedOpacity(
                          opacity: _isDeleting ? 0.12 : 1,
                          duration: const Duration(milliseconds: 520),
                          child: _StatusFullScreenContent(status: status),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      return LinearProgressIndicator(
                        value: _progressValueForIndex(
                          _currentIndex,
                          statuses.length,
                        ),
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: <Widget>[
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isOwner
                                ? FontWeight.w700
                                : FontWeight.w900,
                            fontSize: 16,
                            shadows: isOwner
                                ? null
                                : const <Shadow>[
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 8,
                                    ),
                                  ],
                          ),
                        ),
                      ),
                      if (isOwner) ...<Widget>[
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          decoration: BoxDecoration(
                            color: _isDeleting
                                ? Colors.redAccent.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: IconButton(
                            color: Colors.white,
                            onPressed: _isDeleting
                                ? null
                                : () => unawaited(_deleteStatus(status)),
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ),
                      ] else ...<Widget>[
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: 'More',
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                          ),
                          color: const Color(0xFF111827),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (value) {
                            if (value == 'report') {
                              unawaited(
                                _showCommunityStatusReportSheet(
                                  context,
                                  status: status,
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'report',
                              child: Text(
                                'Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  child: _StatusEngagementPanel(
                    status: status,
                    isOwner: isOwner,
                    reactions: _reactions,
                    onPauseProgress: _pauseProgressForInput,
                    onResumeProgress: _resumeProgressAfterInput,
                    onOpenReplies: isOwner
                        ? () => unawaited(_showRepliesSheet(status))
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusRepliesSheet extends StatelessWidget {
  const _StatusRepliesSheet({required this.status});

  final CommunityStatus status;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.36,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF101418),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Replies',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<CommunityStatusComment>>(
                  stream: CommunityStatusService.instance.watchComments(
                    status.id,
                  ),
                  builder: (context, snapshot) {
                    final comments =
                        snapshot.data ?? const <CommunityStatusComment>[];
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'No replies yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  comment.userName.isNotEmpty
                                      ? comment.userName
                                      : 'User',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: _StatusCommentBubble(text: comment.text),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              tooltip: 'More',
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              color: const Color(0xFF111827),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (value) {
                                if (value == 'report') {
                                  unawaited(
                                    _showCommunityStatusReportSheet(
                                      context,
                                      status: status,
                                      comment: comment,
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (_) =>
                                  const <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'report',
                                      child: Text(
                                        'Report',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const List<String> _communityReportReasons = <String>[
  'Harassment or bullying',
  'Hate speech or discrimination',
  'Sexual or adult content',
  'Violence or dangerous content',
  'Spam, scam, or fake content',
  'Misinformation or deceptive political content',
  'Privacy violation or personal information',
  'Copyright or trademark issue',
  'Illegal content',
  'Other safety issue',
];

Future<void> _showCommunityStatusReportSheet(
  BuildContext context, {
  required CommunityStatus status,
  CommunityStatusComment? comment,
}) async {
  final detailsController = TextEditingController();
  var selectedReason = _communityReportReasons.first;
  var submitting = false;
  final reportedLabel = comment == null ? 'status' : 'reply';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFF101418),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Report $reportedLabel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose the closest reason. Reports help keep the community safe and may be reviewed by our team.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final reason in _communityReportReasons)
                                ChoiceChip(
                                  label: Text(reason),
                                  selected: selectedReason == reason,
                                  onSelected: submitting
                                      ? null
                                      : (_) => setSheetState(
                                          () => selectedReason = reason,
                                        ),
                                  selectedColor: const Color(0xFFFFD166),
                                  labelStyle: TextStyle(
                                    color: selectedReason == reason
                                        ? const Color(0xFF111827)
                                        : Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.10,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: detailsController,
                        enabled: !submitting,
                        maxLength:
                            CommunityStatusService.maxReportDetailsLength,
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          hintText: 'Add details optional',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w700,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      setSheetState(() => submitting = true);
                                      final ok = await CommunityStatusService
                                          .instance
                                          .submitReport(
                                            status: status,
                                            comment: comment,
                                            reason: selectedReason,
                                            details: detailsController.text,
                                          );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? 'Report submitted. Thank you.'
                                                  : 'Report failed. Please try again.',
                                            ),
                                          ),
                                        );
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD166),
                                foregroundColor: const Color(0xFF111827),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF111827),
                                      ),
                                    )
                                  : const Icon(Icons.flag_rounded),
                              label: Text(submitting ? 'Sending' : 'Submit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  detailsController.dispose();
}

class _StatusCommentBubble extends StatefulWidget {
  const _StatusCommentBubble({required this.text});

  final String text;

  @override
  State<_StatusCommentBubble> createState() => _StatusCommentBubbleState();
}

class _StatusCommentBubbleState extends State<_StatusCommentBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    final showReadMore = !_expanded && text.length > 70;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              text,
              maxLines: _expanded ? null : 2,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.24,
              ),
            ),
            if (showReadMore) ...<Widget>[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _expanded = true),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'Read more',
                    style: TextStyle(
                      color: Color(0xFF25D366),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusFullScreenContent extends StatelessWidget {
  const _StatusFullScreenContent({required this.status});

  final CommunityStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.imageUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: status.imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (_, _, _) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 44,
              ),
            ),
          ),
          if (status.text.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 132),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      status.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                        shadows: <Shadow>[
                          Shadow(color: Colors.black87, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          status.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusEngagementPanel extends StatelessWidget {
  const _StatusEngagementPanel({
    required this.status,
    required this.isOwner,
    required this.reactions,
    required this.onPauseProgress,
    required this.onResumeProgress,
    this.onOpenReplies,
  });

  final CommunityStatus status;
  final bool isOwner;
  final List<String> reactions;
  final VoidCallback onPauseProgress;
  final VoidCallback onResumeProgress;
  final VoidCallback? onOpenReplies;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _StatusMetric(
                  icon: Icons.visibility_rounded,
                  value: status.viewCount,
                ),
                _StatusMetric(
                  icon: Icons.favorite_rounded,
                  value: status.likeCount,
                ),
                _StatusMetric(
                  icon: Icons.emoji_emotions_rounded,
                  value: status.reactionCount,
                ),
              ],
            ),
            if (isOwner && onOpenReplies != null) ...<Widget>[
              const SizedBox(height: 10),
              InkWell(
                onTap: onOpenReplies,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Icon(
                        Icons.keyboard_double_arrow_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Swipe up for replies',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!isOwner) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _StatusLikeButton(status: status),
                  const SizedBox(width: 12),
                  for (final reaction in reactions)
                    _StatusReactionButton(status: status, reaction: reaction),
                ],
              ),
              const SizedBox(height: 10),
              _StatusReplyInput(
                status: status,
                onFocusStart: onPauseProgress,
                onFocusEnd: onResumeProgress,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusReplyInput extends StatefulWidget {
  const _StatusReplyInput({
    required this.status,
    required this.onFocusStart,
    required this.onFocusEnd,
  });

  final CommunityStatus status;
  final VoidCallback onFocusStart;
  final VoidCallback onFocusEnd;

  @override
  State<_StatusReplyInput> createState() => _StatusReplyInputState();
}

class _StatusReplyInputState extends State<_StatusReplyInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      widget.onFocusStart();
    } else {
      widget.onFocusEnd();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (_sending || text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    final ok = await CommunityStatusService.instance.submitComment(
      widget.status,
      text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    if (ok) {
      _controller.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply sent')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reply failed. Try again.')));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !_sending,
            minLines: 1,
            maxLines: 3,
            maxLength: CommunityStatusService.maxCommentLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Reply...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.14),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: const Color(0xFF06251A),
          ),
          onPressed: _sending ? null : () => unawaited(_send()),
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF06251A),
                  ),
                )
              : const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatusLikeButton extends StatelessWidget {
  const _StatusLikeButton({required this.status});

  final CommunityStatus status;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: status.viewerHasLiked
            ? const Color(0xFFE91E63)
            : Colors.white.withValues(alpha: 0.18),
        foregroundColor: Colors.white,
      ),
      onPressed: () =>
          unawaited(CommunityStatusService.instance.toggleLike(status.id)),
      icon: const Icon(Icons.favorite_rounded),
    );
  }
}

class _StatusReactionButton extends StatelessWidget {
  const _StatusReactionButton({required this.status, required this.reaction});

  final CommunityStatus status;
  final String reaction;

  @override
  Widget build(BuildContext context) {
    final selected = status.viewerReaction == reaction;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () => unawaited(
          CommunityStatusService.instance.setReaction(status.id, reaction),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(reaction, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _HomeCommunityStatusBubble extends StatelessWidget {
  const _HomeCommunityStatusBubble({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.accentColor,
    this.imageUrl = '',
    this.previewText = '',
    this.previewBackgroundColor = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;
  final String imageUrl;
  final String previewText;
  final int previewBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[accentColor, const Color(0xFFF59E0B)],
                ),
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _StatusIcon(icon: icon),
                      )
                    : previewText.isNotEmpty
                    ? _StatusTextPreview(
                        text: previewText,
                        backgroundColor: previewBackgroundColor,
                      )
                    : _StatusIcon(icon: icon),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTextPreview extends StatelessWidget {
  const _StatusTextPreview({required this.text, required this.backgroundColor});

  final String text;
  final int backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color = Color(backgroundColor == 0 ? 0xFF4CAF50 : backgroundColor);
    return Container(
      color: color,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF0F766E), size: 28),
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
    required this.onSearchSubmitted,
  });

  final VoidCallback onCreateTap;
  final VoidCallback onProfileTap;
  final PosterProfileData viewerPosterProfile;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onSearchSubmitted;

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
                  onEditingComplete: () => unawaited(onSearchSubmitted()),
                  onSubmitted: (_) => unawaited(onSearchSubmitted()),
                  decoration: InputDecoration(
                    hintText: strings.searchTemplates,
                    prefixIcon: IconButton(
                      onPressed: () => unawaited(onSearchSubmitted()),
                      icon: const Icon(Icons.search_rounded),
                    ),
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
            color: Color(0x180F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
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
                                cacheManager: PosterNetworkImageCache.instance,
                                maxWidthDiskCache:
                                    PosterNetworkImageLimits.diskFeedMaxWidth,
                                maxHeightDiskCache:
                                    PosterNetworkImageLimits.diskFeedMaxHeight,
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
                        .clamp(320, 720)
                  : 720;
              return CachedNetworkImage(
                imageUrl: _slides[index].imageUrl,
                cacheManager: PosterNetworkImageCache.instance,
                maxWidthDiskCache: PosterNetworkImageLimits.diskFeedMaxWidth,
                maxHeightDiskCache: PosterNetworkImageLimits.diskFeedMaxHeight,
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
    try {
      await PostSplashStartupGate.whenReady.timeout(
        const Duration(seconds: 20),
      );
      await Future<void>.delayed(const Duration(seconds: 10));
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    if (!await AdMobConsentService.instance.canRequestAds()) {
      return;
    }
    if (!mounted) {
      return;
    }
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
          if (error.code != 3) {
            _homeDebugLog('home banner ad failed: $error');
          }
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

class _TemplateFeedItem extends StatefulWidget {
  const _TemplateFeedItem({
    super.key,
    required this.item,
    required this.hostContext,
    required this.language,
    required this.deferRichPosterPreview,
    required this.onOpenSubscriptionPlan,
    required this.viewerPosterProfile,
    required this.posterRenderCycle,
    required this.onPosterPhotoDragStateChanged,
    this.preferUltraLightImage = false,
  });

  final _TemplateItem item;
  final BuildContext hostContext;
  final AppLanguage language;
  final bool deferRichPosterPreview;
  final Future<void> Function({bool startPurchaseOnOpen})
  onOpenSubscriptionPlan;
  final PosterProfileData viewerPosterProfile;
  final int posterRenderCycle;
  final ValueChanged<bool> onPosterPhotoDragStateChanged;
  final bool preferUltraLightImage;
  static final SubscriptionBackendService _subscriptionBackendService =
      SubscriptionBackendService();

  static SubscriptionBackendService get subscriptionBackendService =>
      _subscriptionBackendService;

  @override
  State<_TemplateFeedItem> createState() => _TemplateFeedItemState();
}

class _TemplateFeedItemState extends State<_TemplateFeedItem>
    with AutomaticKeepAliveClientMixin<_TemplateFeedItem> {
  static const OfflineBackgroundRemovalService _backgroundRemovalService =
      OfflineBackgroundRemovalService();
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');
  static const List<String> _randomPosterNameFonts = <String>[
    'Pragathi',
    'Brahma',
    'Kranthi',
    'Reshma',
    'Tejafont',
  ];
  static const List<String> _randomEnglishPosterNameFonts = <String>[
    'Montserrat',
    'Oswald',
    'Cinzel',
    'Raleway',
    'Rubik',
  ];
  final GlobalKey _posterCaptureKey = GlobalKey();
  final ScreenshotController _posterScreenshotController =
      ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
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
  bool _posterWarmupQueued = false;
  String? _queuedPosterWarmupSignature;
  static bool _globalAutoPosterWarmupActive = false;
  static final Set<String> _globalPosterWarmupSignatures = <String>{};
  static const List<_PosterPhotoPreset>
  _posterPhotoPresets = <_PosterPhotoPreset>[
    _PosterPhotoPreset(shape: 'circle', photoRenderMode: 'original'),
    _PosterPhotoPreset(shape: 'square', photoRenderMode: 'original'),
    _PosterPhotoPreset(shape: 'flower', photoRenderMode: 'cutout'),
    _PosterPhotoPreset(shape: 'blob', photoRenderMode: 'cutout'),
    _PosterPhotoPreset(shape: 'transparent_clean', photoRenderMode: 'cutout'),
    _PosterPhotoPreset(
      shape: 'transparent_bottom_fade',
      photoRenderMode: 'cutout',
    ),
    _PosterPhotoPreset(shape: 'arch', photoRenderMode: 'original'),
    _PosterPhotoPreset(shape: 'scallop_circle', photoRenderMode: 'original'),
    _PosterPhotoPreset(shape: 'shield', photoRenderMode: 'original'),
  ];

  _PosterPhotoUserAdjustment _photoUserAdjustment =
      _PosterPhotoUserAdjustment.none;
  _PosterExtraPhotoSelection? _extraPhotoSelection;
  Future<void>? _backgroundRemoverInitialization;
  bool _photoDragInProgress = false;
  bool _additionalPhotoBusy = false;

  _TemplateItem get item => widget.item;
  BuildContext get hostContext => widget.hostContext;
  AppLanguage get language => widget.language;
  bool get deferRichPosterPreview => widget.deferRichPosterPreview;
  bool get preferUltraLightImage => widget.preferUltraLightImage;
  Future<void> Function({bool startPurchaseOnOpen})
  get onOpenSubscriptionPlan => widget.onOpenSubscriptionPlan;
  PosterProfileData get viewerPosterProfile => widget.viewerPosterProfile;
  int get posterRenderCycle => widget.posterRenderCycle;
  SubscriptionBackendService get _subscriptionBackendService =>
      _TemplateFeedItem.subscriptionBackendService;

  @override
  void dispose() {
    if (_photoDragInProgress) {
      widget.onPosterPhotoDragStateChanged(false);
    }
    _invalidatePreparedPosterCache();
    _showPosterPhotoNotifier.dispose();
    _posterReadyNotifier.dispose();
    _activeActionNotifier.dispose();
    super.dispose();
  }

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

  String _resolveEnglishPosterNameFontFamily(String resolvedName) {
    final personalizationConfig = item.personalizationConfig;
    final seedSource =
        '${item.imageUrl ?? item.imageAssetPath ?? 'poster'}'
        '|${personalizationConfig?.nameX ?? 0}'
        '|${personalizationConfig?.nameY ?? 0}'
        '|${personalizationConfig?.stripHeight ?? 0}'
        '|english|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index = hash.abs() % _randomEnglishPosterNameFonts.length;
    return _randomEnglishPosterNameFonts[index];
  }

  String? _resolveDisplayNameFontFamily(String text) {
    if (_teluguTextPattern.hasMatch(text)) {
      return _resolvePosterNameFontFamily(text);
    }
    if (_latinTextPattern.hasMatch(text)) {
      return _resolveEnglishPosterNameFontFamily(text);
    }
    return null;
  }

  String _resolveDesignationFontFamily(String text) {
    if (_teluguTextPattern.hasMatch(text)) {
      return 'Pallavi Medium';
    }
    if (_latinTextPattern.hasMatch(text)) {
      return 'Montserrat';
    }
    return 'Poppins';
  }

  bool _shouldConvertForLegacyTelugu(String text, String? fontFamily) {
    return fontFamily != null &&
        _teluguTextPattern.hasMatch(text) &&
        (_randomPosterNameFonts.contains(fontFamily) ||
            fontFamily == 'Pallavi Medium');
  }

  String _posterSignature({required bool isPhotoVisible}) {
    return '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${item.videoUrl ?? ''}-${item.mediaType}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-${_photoUserAdjustment.effectiveShape}-${_photoUserAdjustment.effectivePhotoRenderMode}-${_photoUserAdjustment.xOffsetPercent.toStringAsFixed(2)}-${_photoUserAdjustment.yOffsetPercent.toStringAsFixed(2)}-${_extraPhotoSelection?.originalPhotoPath ?? ''}-${_extraPhotoSelection?.cutoutPhotoPath ?? ''}-$posterRenderCycle-$isPhotoVisible';
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
    _queuedPosterWarmupSignature = null;
    if (existingPath != null) {
      unawaited(
        File(existingPath).delete().catchError((_) => File(existingPath)),
      );
    }
  }

  Future<void> _ensureBackgroundRemoverReady() {
    return _backgroundRemoverInitialization ??= _backgroundRemovalService
        .ensureReady();
  }

  Future<File> _stagePickedImageForCrop(
    XFile picked, {
    required String filePrefix,
  }) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String extension = picked.name.contains('.')
        ? picked.name.substring(picked.name.lastIndexOf('.'))
        : '.png';
    final String targetPath =
        '${tempDir.path}${Platform.pathSeparator}'
        '${filePrefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final File targetFile = File(targetPath);
    await targetFile.writeAsBytes(await picked.readAsBytes(), flush: true);
    return targetFile;
  }

  Future<void> _deleteFileSilently(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _deleteAdditionalPhotoAssets() async {
    final selection = _extraPhotoSelection;
    if (selection == null) {
      return;
    }
    final paths = <String>{
      selection.originalPhotoPath.trim(),
      selection.cutoutPhotoPath.trim(),
    }.where((path) => path.isNotEmpty);
    for (final path in paths) {
      await _deleteFileSilently(File(path));
    }
  }

  Future<Uint8List?> _removeAdditionalPhotoBackground(
    Uint8List optimizedOriginalBytes,
  ) async {
    Future<Uint8List?> attempt(Uint8List sourceBytes, Duration timeout) async {
      await _ensureBackgroundRemoverReady();
      final removedResult = await _backgroundRemovalService
          .removeBackground(sourceBytes)
          .timeout(timeout);
      return removedResult.pngBytes;
    }

    try {
      return await attempt(optimizedOriginalBytes, const Duration(seconds: 30));
    } catch (_) {
      try {
        final smallerBytes = await compute(
          _prepareAdditionalPosterPhotoRemovalBytes,
          optimizedOriginalBytes,
        );
        return await attempt(smallerBytes, const Duration(seconds: 30));
      } catch (_) {
        return null;
      }
    }
  }

  Future<BuildContext> _showAdditionalPhotoProcessingDialog() async {
    final strings = context.strings;
    final completer = Completer<BuildContext>();
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'additional-photo-processing',
        barrierColor: Colors.black.withValues(alpha: 0.16),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          if (!completer.isCompleted) {
            completer.complete(dialogContext);
          }
          return Material(
            type: MaterialType.transparency,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.localized(
                        telugu: 'బ్యాక్‌గ్రౌండ్ తొలగిస్తోంది...',
                        english: 'Removing background...',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    return completer.future;
  }

  Future<void> _pickAdditionalPosterPhoto() async {
    final personalizationConfig = item.personalizationConfig;
    if (_additionalPhotoBusy ||
        personalizationConfig == null ||
        !personalizationConfig.showVideoExtraPhoto) {
      return;
    }
    setState(() => _additionalPhotoBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.strings;
    File? stagedCropSourceFile;
    var processingDialogOpen = false;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) {
        return;
      }
      stagedCropSourceFile = await _stagePickedImageForCrop(
        picked,
        filePrefix: 'poster_additional_photo_pick',
      );
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: stagedCropSourceFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: strings.localized(
              telugu: 'ఫోటో క్రాప్ చేయండి',
              english: 'Crop Photo',
            ),
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF0F172A),
            activeControlsWidgetColor: const Color(0xFF2563EB),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: strings.localized(
              telugu: 'ఫోటో క్రాప్ చేయండి',
              english: 'Crop Photo',
            ),
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (cropped == null) {
        return;
      }
      final originalBytes = await File(cropped.path).readAsBytes();
      final optimizedOriginalBytes = await compute(
        _optimizeAdditionalPosterPhotoBytes,
        originalBytes,
      );
      BuildContext? processingDialogContext;
      if (mounted) {
        processingDialogContext = await _showAdditionalPhotoProcessingDialog();
        processingDialogOpen = true;
      }
      final Uint8List? cutoutBytes = await _removeAdditionalPhotoBackground(
        optimizedOriginalBytes,
      );
      if (processingDialogOpen &&
          processingDialogContext != null &&
          processingDialogContext.mounted) {
        Navigator.of(processingDialogContext).pop();
        processingDialogOpen = false;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String originalTargetPath =
          '${dir.path}${Platform.pathSeparator}'
          'poster_additional_original_photo_$stamp.png';
      final File originalLocalFile = File(originalTargetPath);
      await originalLocalFile.writeAsBytes(optimizedOriginalBytes, flush: true);
      var cutoutTargetPath = '';
      if (cutoutBytes != null) {
        cutoutTargetPath =
            '${dir.path}${Platform.pathSeparator}'
            'poster_additional_photo_$stamp.png';
        await File(cutoutTargetPath).writeAsBytes(cutoutBytes, flush: true);
      }
      await _deleteAdditionalPhotoAssets();
      if (!mounted) {
        return;
      }
      setState(() {
        _extraPhotoSelection = _PosterExtraPhotoSelection(
          originalPhotoPath: originalTargetPath,
          cutoutPhotoPath: cutoutTargetPath,
        );
      });
      _invalidatePreparedPosterCache();
      _schedulePosterWarmup(force: true);
      if (cutoutBytes == null && mounted) {
        _showSnack(
          messenger,
          strings.localized(
            telugu:
                'ఫోటో జోడించాం, కానీ background remove పూర్తిగా కాలేదు. ఇప్పటికి original photo వాడుతున్నాం.',
            english:
                'Photo was added, but background removal did not complete. Using the original photo for now.',
          ),
        );
      }
    } catch (_) {
      if (processingDialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
      if (mounted) {
        _showSnack(
          messenger,
          strings.localized(
            telugu: 'అదనపు ఫోటో జోడించలేకపోయాం.',
            english: 'Could not add the extra photo.',
          ),
        );
      }
    } finally {
      if (stagedCropSourceFile != null) {
        unawaited(_deleteFileSilently(stagedCropSourceFile));
      }
      if (mounted) {
        setState(() => _additionalPhotoBusy = false);
      }
    }
  }

  bool get _canInteractWithPosterPhoto {
    final personalizationConfig = item.personalizationConfig;
    if (item.isVideo ||
        personalizationConfig == null ||
        !_showPosterPhotoNotifier.value) {
      return false;
    }
    if (viewerPosterProfile.identityMode == PosterIdentityMode.business) {
      return false;
    }
    return viewerPosterProfile.photoPath.trim().isNotEmpty ||
        viewerPosterProfile.photoUrl.trim().isNotEmpty ||
        viewerPosterProfile.originalPhotoPath.trim().isNotEmpty ||
        viewerPosterProfile.originalPhotoUrl.trim().isNotEmpty;
  }

  _PosterPhotoPreset? _pickNextPosterPhotoPreset() {
    final personalizationConfig = item.personalizationConfig;
    if (_posterPhotoPresets.isEmpty || personalizationConfig == null) {
      return null;
    }
    final defaultShape = personalizationConfig.photoShape.trim();
    final defaultRenderMode = personalizationConfig.photoRenderMode.trim();
    final currentShape = _photoUserAdjustment.effectiveShape.isNotEmpty
        ? _photoUserAdjustment.effectiveShape
        : defaultShape;
    final currentRenderMode =
        _photoUserAdjustment.effectivePhotoRenderMode.isNotEmpty
        ? _photoUserAdjustment.effectivePhotoRenderMode
        : defaultRenderMode;
    final presetsWithDefault = <_PosterPhotoPreset>[
      _PosterPhotoPreset(
        shape: defaultShape,
        photoRenderMode: defaultRenderMode,
      ),
      ..._posterPhotoPresets,
    ];
    final currentIndex = presetsWithDefault.indexWhere(
      (_PosterPhotoPreset preset) =>
          preset.shape == currentShape &&
          preset.photoRenderMode == currentRenderMode,
    );
    final nextIndex = currentIndex < 0
        ? 1
        : (currentIndex + 1) % presetsWithDefault.length;
    final next = presetsWithDefault[nextIndex];
    if (next.shape == defaultShape &&
        next.photoRenderMode == defaultRenderMode) {
      return null;
    }
    return next;
  }

  void _applyPosterPhotoPresetTap() {
    if (!_canInteractWithPosterPhoto) {
      return;
    }
    _invalidatePreparedPosterCache();
    setState(() {
      final nextPreset = _pickNextPosterPhotoPreset();
      _photoUserAdjustment = _PosterPhotoUserAdjustment(
        xOffsetPercent: _photoUserAdjustment.xOffsetPercent,
        yOffsetPercent: _photoUserAdjustment.yOffsetPercent,
        preset: nextPreset,
      );
    });
    _schedulePosterWarmup(force: true);
  }

  void _updatePosterPhotoDrag({
    required double deltaXPercent,
    required double deltaYPercent,
  }) {
    if (!_canInteractWithPosterPhoto) {
      return;
    }
    final nextX = _photoUserAdjustment.xOffsetPercent + deltaXPercent;
    final nextY = _photoUserAdjustment.yOffsetPercent + deltaYPercent;
    if (nextX == _photoUserAdjustment.xOffsetPercent &&
        nextY == _photoUserAdjustment.yOffsetPercent) {
      return;
    }
    setState(() {
      _photoUserAdjustment = _PosterPhotoUserAdjustment(
        xOffsetPercent: nextX,
        yOffsetPercent: nextY,
        preset: _photoUserAdjustment.preset,
      );
    });
  }

  void _setPhotoDragInProgress(bool value) {
    if (_photoDragInProgress == value) {
      return;
    }
    _photoDragInProgress = value;
    if (!value) {
      _invalidatePreparedPosterCache();
      _schedulePosterWarmup(force: true);
    }
    widget.onPosterPhotoDragStateChanged(value);
  }

  void _schedulePosterWarmup({bool force = false}) {
    if (item.isVideo || !_posterReadyNotifier.value) {
      return;
    }
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    if (!force && _globalAutoPosterWarmupActive) {
      return;
    }
    if (_globalPosterWarmupSignatures.contains(signature)) {
      return;
    }
    if (!force) {
      if (_preparedPosterSignature == signature &&
          _preparedPosterBytes != null) {
        return;
      }
      if (_preparePosterFuture != null || _posterWarmupQueued) {
        return;
      }
      if (_queuedPosterWarmupSignature == signature) {
        return;
      }
    }
    _posterWarmupQueued = true;
    _queuedPosterWarmupSignature = signature;
    if (!force) {
      _globalAutoPosterWarmupActive = true;
    }
    _globalPosterWarmupSignatures.add(signature);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_posterCaptureKey.currentContext == null) {
          _recordPosterCaptureTrace(
            'poster export warmup skipped: capture context unavailable',
            details: <String, Object?>{
              'itemTitle': item.titleEn,
              'signature': signature,
            },
          );
          return;
        }
        await _preparePosterExport(force: force);
      } finally {
        _globalPosterWarmupSignatures.remove(signature);
        if (!force) {
          _globalAutoPosterWarmupActive = false;
        }
        _posterWarmupQueued = false;
        if (_queuedPosterWarmupSignature == signature) {
          _queuedPosterWarmupSignature = null;
        }
      }
    });
  }

  Future<void> _prepareLegacyTextForExport() async {
    final resolvedName = viewerPosterProfile.resolvedName(language: language);
    final isBusinessProfile =
        viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final resolvedDesignation = isBusinessProfile
        ? viewerPosterProfile.businessTagline.trim()
        : viewerPosterProfile.whatsappNumber.trim();
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final designationFontFamily = _resolveDesignationFontFamily(
      resolvedDesignation,
    );
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

  Future<void> _preparePosterExport({
    bool force = false,
    bool? photoVisibleOverride,
  }) async {
    final requestedPhotoVisible =
        photoVisibleOverride ?? _showPosterPhotoNotifier.value;
    final signature = _posterSignature(isPhotoVisible: requestedPhotoVisible);
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
    final future = () async {
      final originalPhotoVisible = _showPosterPhotoNotifier.value;
      final shouldTemporarilySwitch =
          requestedPhotoVisible != originalPhotoVisible;
      if (shouldTemporarilySwitch) {
        _showPosterPhotoNotifier.value = requestedPhotoVisible;
        await _settlePosterCaptureFrame();
      }
      try {
        await _doPreparePosterExport(signature);
      } finally {
        if (shouldTemporarilySwitch) {
          _showPosterPhotoNotifier.value = originalPhotoVisible;
          await _settlePosterCaptureFrame();
          _schedulePosterWarmup(force: true);
        }
      }
    }();
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
      await _ensurePosterCaptureResourcesReady();
      await _prepareLegacyTextForExport();
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
    return _ensurePreparedPosterFileForVisibility(
      _showPosterPhotoNotifier.value,
    );
  }

  Future<String?> _ensurePreparedPosterFileForVisibility(
    bool isPhotoVisible,
  ) async {
    final signature = _posterSignature(isPhotoVisible: isPhotoVisible);
    final existingPath = _preparedPosterFilePath;
    if (_preparedPosterSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      return existingPath;
    }
    await _preparePosterExport(photoVisibleOverride: isPhotoVisible);
    final refreshedPath = _preparedPosterFilePath;
    if (refreshedPath != null && await File(refreshedPath).exists()) {
      return refreshedPath;
    }
    return null;
  }

  bool _hasImmediateSubscriptionAccess() {
    if (InAppPurchaseGateway.playStoreProActive) {
      unawaited(_subscriptionBackendService.refreshEntitlementInBackground());
      return true;
    }
    final cachedEntitlement = _subscriptionBackendService.cachedEntitlement;
    if (_subscriptionBackendService.hasFreshEntitlementCache &&
        cachedEntitlement?.hasAccess == true) {
      return true;
    }
    return false;
  }

  bool _canAttemptLiveSubscriptionStatusCheck() {
    if (!_subscriptionBackendService.isConfigured) {
      return false;
    }
    return FirebaseAuth.instance.currentUser != null;
  }

  bool _shouldRunBlockingSubscriptionStatusCheck() {
    if (!_canAttemptLiveSubscriptionStatusCheck()) {
      return false;
    }
    if (_hasImmediateSubscriptionAccess()) {
      return true;
    }
    // When the app has not hydrated the entitlement cache yet, subscribed
    // users can otherwise see a false paywall on download/share. If we have
    // a logged-in user, do one live backend check before showing the plan.
    return true;
  }

  bool get _legacySubscriptionStatusPopupEnabled => false;

  void _handlePosterReadyState(bool ready) {
    if (_posterReadyNotifier.value == ready) {
      return;
    }
    _posterReadyNotifier.value = ready;
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
    final captureContext = _posterCaptureKey.currentContext;
    if (captureContext == null) {
      _recordPosterCaptureTrace(
        'poster capture skipped: context unavailable',
        details: _posterCaptureDiagnostics(),
      );
      return null;
    }

    final renderBox = captureContext.findRenderObject() as RenderBox?;
    final logicalSize =
        renderBox != null && renderBox.hasSize && !renderBox.size.isEmpty
        ? renderBox.size
        : MediaQuery.sizeOf(captureContext);
    final pixelRatio = _capturePosterPixelRatio(captureContext);
    final targetSize = logicalSize;
    final captureContextMounted = captureContext.mounted;

    _recordPosterCaptureTrace(
      'capture start',
      details: <String, Object?>{
        'method': 'screenshot.capture',
        'logicalSize': logicalSize.toString(),
        'pixelRatio': pixelRatio,
        'targetSize': targetSize.toString(),
      },
    );

    try {
      final bytes = await _posterScreenshotController.capture(
        pixelRatio: pixelRatio,
        delay: const Duration(milliseconds: 60),
      );
      if (bytes == null || bytes.isEmpty) {
        _recordPosterCaptureTrace(
          'poster capture skipped: empty live boundary',
          details: _posterCaptureDiagnostics(
            captureContextMounted: captureContextMounted,
            logicalSize: logicalSize,
            pixelRatio: pixelRatio,
          ),
        );
        return null;
      }
      _recordPosterCaptureTrace(
        'capture success',
        details: <String, Object?>{
          'method': 'screenshot.capture',
          'byteLength': bytes.length,
          'logicalSize': logicalSize.toString(),
          'pixelRatio': pixelRatio,
        },
      );
      return bytes;
    } catch (error, stackTrace) {
      await _recordPosterCaptureFailure(
        message: 'poster capture failed',
        error: error,
        stackTrace: stackTrace,
        captureContextMounted: captureContextMounted,
        logicalSize: logicalSize,
        pixelRatio: pixelRatio,
      );
      rethrow;
    }
  }

  Future<void> _ensurePosterCaptureResourcesReady() async {
    await _precacheCurrentPosterImage();
    await _precacheCurrentPosterProfileImage();
    await _precacheCurrentPosterAdditionalPhoto();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _precacheCurrentPosterImage() async {
    if (item.isVideo) {
      return;
    }
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null) {
      return;
    }
    try {
      final assetPath = item.imageAssetPath?.trim() ?? '';
      if (assetPath.isNotEmpty) {
        await precacheImage(AssetImage(assetPath), posterContext);
        return;
      }
      final imageUrl = item.imageUrl?.trim() ?? '';
      final thumbnailUrl = item.thumbnailUrl?.trim() ?? '';
      final resolvedUrl = imageUrl.isNotEmpty ? imageUrl : thumbnailUrl;
      if (resolvedUrl.isEmpty) {
        return;
      }
      await precacheImage(
        item.preferOriginalPosterQuality
            ? CachedNetworkImageProvider(
                resolvedUrl,
                cacheManager: PosterNetworkImageCache.instance,
              )
            : CachedNetworkImageProvider(
                resolvedUrl,
                cacheManager: PosterNetworkImageCache.instance,
                maxWidth: PosterNetworkImageLimits.diskFeedMaxWidth,
                maxHeight: PosterNetworkImageLimits.diskFeedMaxHeight,
              ),
        posterContext,
      );
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster image precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack('poster image precache skipped: $error', stackTrace);
    }
  }

  Future<void> _precacheCurrentPosterProfileImage() async {
    if (item.personalizationConfig == null || !_showPosterPhotoNotifier.value) {
      return;
    }
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null) {
      return;
    }
    final imageProvider = PosterProfileService.resolveImageProvider(
      viewerPosterProfile,
      preferOriginalPersonalPhoto:
          item.personalizationConfig?.photoRenderMode == 'original',
      allowOriginalFallbackWhenCutoutUnavailable:
          item.personalizationConfig?.photoRenderMode == 'original',
    );
    if (imageProvider == null) {
      return;
    }
    try {
      await precacheImage(imageProvider, posterContext);
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster profile image precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack(
        'poster profile image precache skipped: $error',
        stackTrace,
      );
    }
  }

  Future<void> _precacheCurrentPosterAdditionalPhoto() async {
    final personalizationConfig = item.personalizationConfig;
    final selection = _extraPhotoSelection;
    if (personalizationConfig == null ||
        !personalizationConfig.showVideoExtraPhoto ||
        selection == null ||
        !selection.hasPhoto) {
      return;
    }
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null) {
      return;
    }
    final profile = selection.asPosterProfileData();
    final imageProvider = PosterProfileService.resolveImageProvider(
      profile,
      preferOriginalPersonalPhoto:
          personalizationConfig.videoExtraPhotoRenderMode == 'original',
      allowOriginalFallbackWhenCutoutUnavailable: true,
    );
    if (imageProvider == null) {
      return;
    }
    try {
      await precacheImage(imageProvider, posterContext);
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster additional photo precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack(
        'poster additional photo precache skipped: $error',
        stackTrace,
      );
    }
  }

  double _capturePosterPixelRatio(BuildContext context) {
    final view =
        View.maybeOf(context) ??
        WidgetsBinding.instance.platformDispatcher.implicitView;
    final devicePixelRatio = view?.devicePixelRatio ?? 1.0;
    final renderBox =
        _posterCaptureKey.currentContext?.findRenderObject() as RenderBox?;
    final logicalWidth =
        renderBox != null && renderBox.hasSize && renderBox.size.width > 0
        ? renderBox.size.width
        : MediaQuery.sizeOf(context).width;
    final pageConfig = _editorPageConfigForPoster();
    final targetWidthRatio = pageConfig.widthPx / math.max(1.0, logicalWidth);
    return math.max(devicePixelRatio, targetWidthRatio).clamp(1.0, 4.5);
  }

  Future<void> _settlePosterCaptureFrame() async {
    await Future<void>.delayed(const Duration(milliseconds: 24));
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    await completer.future;
    await Future<void>.delayed(const Duration(milliseconds: 36));
  }

  void _recordPosterCaptureTrace(
    String message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    final detailText = details.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    final output = detailText.isEmpty ? message : '$message $detailText';
    developer.log(output, name: 'home.poster.capture');
    _homeDebugLog(output);
  }

  Future<void> _recordPosterCaptureFailure({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    bool? captureContextMounted,
    Size? logicalSize,
    double? pixelRatio,
  }) async {
    final diagnostic = _posterCaptureDiagnostics(
      captureContextMounted: captureContextMounted,
      logicalSize: logicalSize,
      pixelRatio: pixelRatio,
    );
    _recordPosterCaptureTrace(message, details: diagnostic);
    try {
      await FirebaseCrashlytics.instance.recordError(
        error ?? Exception(message),
        stackTrace ?? StackTrace.current,
        reason: '$message | ${jsonEncode(diagnostic)}',
        fatal: false,
      );
    } catch (_) {}
  }

  Map<String, Object?> _posterCaptureDiagnostics({
    bool? captureContextMounted,
    Size? logicalSize,
    double? pixelRatio,
  }) {
    return <String, Object?>{
      'captureMethod': 'screenshot.capture',
      'itemTitle': item.titleEn,
      'isVideo': item.isVideo,
      'hasPersonalization': item.personalizationConfig != null,
      'showProfilePhoto': _showPosterPhotoNotifier.value,
      'captureContextMounted': captureContextMounted,
      'logicalSize': logicalSize?.toString(),
      'pixelRatio': pixelRatio,
      'templateImageUrl': item.imageUrl,
      'templateThumbnailUrl': item.thumbnailUrl,
      'templateAssetPath': item.imageAssetPath,
      'profileIdentityMode': viewerPosterProfile.identityMode.name,
      'profilePhotoUrl': viewerPosterProfile.photoUrl,
      'profilePhotoPath': viewerPosterProfile.photoPath,
      'businessLogoUrl': viewerPosterProfile.businessLogoUrl,
    };
  }

  Widget _buildPosterPreview({
    required bool isPhotoVisible,
    ValueChanged<bool>? onPosterReadyChanged,
  }) {
    final personalizationConfig = item.personalizationConfig;
    if (deferRichPosterPreview) {
      return item.pageConfig != null
          ? AspectRatio(
              aspectRatio: item.pageConfig!.aspectRatio,
              child: _ResolvedTemplatePosterImage(
                imageAssetPath: item.imageAssetPath,
                imageUrl: item.imageUrl ?? '',
                imageStoragePath: item.imageStoragePath,
                thumbnailStoragePath: item.thumbnailStoragePath,
                thumbnailUrl: item.thumbnailUrl,
                posterIdForDebug: item.templateId,
                preferOriginalPosterQuality: item.preferOriginalPosterQuality,
                preferUltraLightDecode: preferUltraLightImage,
                onFirstFrameReady: () => onPosterReadyChanged?.call(true),
              ),
            )
          : _ResolvedTemplatePosterImage(
              imageAssetPath: item.imageAssetPath,
              imageUrl: item.imageUrl ?? '',
              imageStoragePath: item.imageStoragePath,
              thumbnailStoragePath: item.thumbnailStoragePath,
              thumbnailUrl: item.thumbnailUrl,
              posterIdForDebug: item.templateId,
              preferOriginalPosterQuality: item.preferOriginalPosterQuality,
              preferUltraLightDecode: preferUltraLightImage,
              onFirstFrameReady: () => onPosterReadyChanged?.call(true),
            );
    }
    return item.isVideo
        ? _FeedTapToPlayVideoPoster(
            videoUrl: item.videoUrl!,
            imageAssetPath: item.imageAssetPath,
            imageUrl: item.imageUrl,
            imageStoragePath: item.imageStoragePath,
            thumbnailStoragePath: item.thumbnailStoragePath,
            thumbnailUrl: item.thumbnailUrl,
            onReady: () => onPosterReadyChanged?.call(true),
          )
        : personalizationConfig != null
        ? _CreatorPosterPreview(
            imageAssetPath: item.imageAssetPath,
            imageUrl: item.imageUrl,
            imageStoragePath: item.imageStoragePath,
            thumbnailStoragePath: item.thumbnailStoragePath,
            thumbnailUrl: item.thumbnailUrl,
            pageConfig: item.pageConfig,
            personalizationConfig: personalizationConfig,
            preferOriginalPosterQuality: item.preferOriginalPosterQuality,
            viewerPosterProfile: viewerPosterProfile,
            language: language,
            showProfilePhoto: isPhotoVisible,
            deferLegacyTextPrime: deferRichPosterPreview,
            posterRenderCycle: posterRenderCycle,
            interactivePhotoEnabled: _canInteractWithPosterPhoto,
            photoShapeOverride: _photoUserAdjustment.effectiveShape,
            photoRenderModeOverride:
                _photoUserAdjustment.effectivePhotoRenderMode,
            photoXOffsetPercent: _photoUserAdjustment.xOffsetPercent,
            photoYOffsetPercent: _photoUserAdjustment.yOffsetPercent,
            onPhotoTap: _applyPosterPhotoPresetTap,
            additionalPhotoSelection: _extraPhotoSelection,
            onAdditionalPhotoTap: personalizationConfig.showVideoExtraPhoto
                ? () => unawaited(_pickAdditionalPosterPhoto())
                : null,
            onPhotoDragDeltaPercent: _updatePosterPhotoDrag,
            onPhotoDragStateChanged: _setPhotoDragInProgress,
            onPosterReadyChanged: onPosterReadyChanged,
          )
        : item.pageConfig != null
        ? AspectRatio(
            aspectRatio: item.pageConfig!.aspectRatio,
            child: _ResolvedTemplatePosterImage(
              imageAssetPath: item.imageAssetPath,
              imageUrl: item.imageUrl ?? '',
              imageStoragePath: item.imageStoragePath,
              thumbnailStoragePath: item.thumbnailStoragePath,
              thumbnailUrl: item.thumbnailUrl,
              posterIdForDebug: item.templateId,
              preferOriginalPosterQuality: item.preferOriginalPosterQuality,
              onFirstFrameReady: () => onPosterReadyChanged?.call(true),
            ),
          )
        : _ResolvedTemplatePosterImage(
            imageAssetPath: item.imageAssetPath,
            imageUrl: item.imageUrl ?? '',
            imageStoragePath: item.imageStoragePath,
            thumbnailStoragePath: item.thumbnailStoragePath,
            thumbnailUrl: item.thumbnailUrl,
            posterIdForDebug: item.templateId,
            preferOriginalPosterQuality: item.preferOriginalPosterQuality,
            onFirstFrameReady: () => onPosterReadyChanged?.call(true),
          );
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

  Future<bool> _resolveLatestSubscriptionAccess() async {
    if (InAppPurchaseGateway.playStoreProActive) {
      unawaited(
        _subscriptionBackendService.refreshEntitlementInBackground(
          forceRefresh: true,
        ),
      );
      return true;
    }

    final cachedHint = await _subscriptionBackendService
        .fetchEntitlementWithCache(forceRefresh: false);
    if (cachedHint.hasAccess) {
      unawaited(
        _subscriptionBackendService.refreshEntitlementInBackground(
          forceRefresh: true,
        ),
      );
      return true;
    }

    final backend = await _subscriptionBackendService.fetchEntitlement(
      forceRefresh: true,
    );
    final effectiveIsPro = backend.hasAccess;
    _homeDebugLog(
      'subscription access resolve: backendResponse.isPro=$effectiveIsPro',
    );
    if (effectiveIsPro) {
      return true;
    }

    final refreshed = await _subscriptionBackendService
        .fetchFreshEntitlementWithRetry();
    final refreshedEffectiveIsPro = refreshed.hasAccess;
    _homeDebugLog(
      'subscription access retry: backendResponse.isPro=$refreshedEffectiveIsPro',
    );
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
    final BuildContext screenContext = hostContext;
    if (_hasImmediateSubscriptionAccess()) {
      unawaited(_subscriptionBackendService.refreshEntitlementInBackground());
      return true;
    }
    if (_shouldRunBlockingSubscriptionStatusCheck()) {
      final hasLatestAccess = await _resolveLatestSubscriptionAccess().timeout(
        SubscriptionPlanConfig.paywallTimeout,
        onTimeout: () async => false,
      );
      if (!screenContext.mounted) {
        return false;
      }
      if (hasLatestAccess) {
        return true;
      }
    }
    if (_legacySubscriptionStatusPopupEnabled &&
        _shouldRunBlockingSubscriptionStatusCheck()) {
      final navigator = Navigator.of(context, rootNavigator: true);
      var loadingDialogDismissed = false;
      unawaited(
        showDialog<void>(
          context: screenContext,
          barrierDismissible: false,
          useRootNavigator: true,
          barrierColor: Colors.black54,
          builder: (BuildContext dialogContext) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                content: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        screenContext.strings.localized(
                          telugu:
                              'సబ్‌స్క్రిప్షన్ స్టేటస్ తనిఖీ చేస్తున్నాం...',
                          english: 'Checking subscription status...',
                          hindi: 'सब्सक्रिप्शन स्थिति जांच रहे हैं...',
                          tamil: 'சந்தா நிலை சரிபார்க்கிறோம்...',
                          kannada: 'ಚಂದಾದಾರಿಕೆ ಸ್ಥಿತಿ ಪರಿಶೀಲಿಸುತ್ತಿದ್ದೇವೆ...',
                          malayalam: 'സബ്സ്ക്രിപ്ഷൻ നില പരിശോധിക്കുന്നു...',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      loadingDialogDismissed = true;
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      screenContext.strings.localized(
                        telugu: 'రద్దు',
                        english: 'Cancel',
                        hindi: 'रद्द करें',
                        tamil: 'ரத்துசெய்',
                        kannada: 'ರದ್ದುಮಾಡಿ',
                        malayalam: 'റദ്ദാക്കുക',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
      try {
        if (loadingDialogDismissed) {
          return false;
        }
        final hasLatestAccess = await _resolveLatestSubscriptionAccess()
            .timeout(
              SubscriptionPlanConfig.paywallTimeout,
              onTimeout: () async => false,
            );
        if (!screenContext.mounted || loadingDialogDismissed) {
          return false;
        }
        if (hasLatestAccess) {
          return true;
        }
      } finally {
        if (!loadingDialogDismissed &&
            screenContext.mounted &&
            navigator.canPop()) {
          navigator.pop();
        }
      }
    }
    _homeDebugLog('subscription access check: backendResponse.isPro=false');
    if (!screenContext.mounted) {
      return false;
    }
    final openPlan = await showModalBottomSheet<bool>(
      context: screenContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: _SubscriptionAccessDialog(
            title: _subscriptionDialogTitleLocalized(screenContext),
            message: _subscriptionPromptCopyLocalized(screenContext),
            trialTitle: _subscriptionTrialTitleLocalized(screenContext),
            trialValue: _subscriptionTrialValueLocalized(screenContext),
            monthlyTitle: _subscriptionMonthlyTitleLocalized(screenContext),
            monthlyValue: _subscriptionMonthlyValueLocalized(screenContext),
            renewalCopy: _subscriptionRenewalCopyLocalized(screenContext),
            termsLabel: _subscriptionTermsLabelLocalized(screenContext),
            skipLabel: _subscriptionSkipLabelLocalized(screenContext),
            actionLabel: _subscriptionButtonLabelLocalized(screenContext),
            onTermsTap: () =>
                _openExternalPublicUrl(dialogContext, AppPublicInfo.termsUrl),
            onSkipTap: () => Navigator.of(dialogContext).pop(false),
            onConfirmTap: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    );

    if (!screenContext.mounted) {
      return false;
    }
    if (openPlan != true) {
      await showSubscriptionExitVideoPromptIfAvailable(
        screenContext,
        onSubscribe: (_) => onOpenSubscriptionPlan(startPurchaseOnOpen: true),
      );
      return false;
    }
    await onOpenSubscriptionPlan(startPurchaseOnOpen: true);
    if (!screenContext.mounted) {
      return false;
    }
    final hasAccess = await _resolveLatestSubscriptionAccess();
    if (!screenContext.mounted || hasAccess) {
      return hasAccess;
    }
    await showSubscriptionExitVideoPromptIfAvailable(
      screenContext,
      onSubscribe: (_) => onOpenSubscriptionPlan(startPurchaseOnOpen: true),
    );
    return false;
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
        if (!kIsWeb) {
          unawaited(
            PosterDownloadsService.recordCopyFromFile(
              preparedPath,
              suggestedFileName: fileName,
            ),
          );
        }
        final posterId = item.templateId?.trim();
        if (posterId != null && posterId.isNotEmpty) {
          unawaited(
            UserPosterUploadsService.instance
                .incrementApprovedContributionCountForPoster(
                  approvedPosterTemplateId: posterId,
                  isShare: false,
                ),
          );
        }
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
      final posterId = item.templateId?.trim();
      if (posterId != null && posterId.isNotEmpty) {
        unawaited(
          UserPosterUploadsService.instance
              .incrementApprovedContributionCountForPoster(
                approvedPosterTemplateId: posterId,
                isShare: true,
              ),
        );
      }
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

  EditorPageConfig _editorPageConfigForPoster() {
    final existing = item.pageConfig;
    if (existing != null) {
      return existing;
    }
    final captureContext = _posterCaptureKey.currentContext;
    final renderBox = captureContext?.findRenderObject() as RenderBox?;
    final size =
        renderBox != null && renderBox.hasSize && !renderBox.size.isEmpty
        ? renderBox.size
        : const Size(1080, 1350);
    final safeWidth = size.width <= 0 ? 1080.0 : size.width;
    final safeHeight = size.height <= 0 ? 1350.0 : size.height;
    final widthPx = 1080;
    final heightPx = ((widthPx / safeWidth) * safeHeight).round().clamp(
      320,
      4000,
    );
    return EditorPageConfig(
      name: 'Poster Editor',
      widthPx: widthPx,
      heightPx: heightPx,
    );
  }

  Future<String?> _preparePosterEditorTemplateSource() async {
    final shouldInjectEditableUserPhoto = item.personalizationConfig != null;
    final posterPath = await _ensurePreparedPosterFileForVisibility(
      shouldInjectEditableUserPhoto ? false : _showPosterPhotoNotifier.value,
    );
    if (posterPath == null) {
      return null;
    }
    final tempDirectory = await getTemporaryDirectory();
    final fileName =
        'poster_editor_template_${item.templateId ?? item.titleEn.hashCode.abs()}.json';
    final filePath = '${tempDirectory.path}${Platform.pathSeparator}$fileName';
    final pageConfig = _editorPageConfigForPoster();
    final templateDocument = <String, Object?>{
      'templateId': item.templateId ?? 'poster_editor',
      'title': item.titleFor(language),
      'sourceWidth': pageConfig.widthPx,
      'sourceHeight': pageConfig.heightPx,
      'layers': <Map<String, Object?>>[
        <String, Object?>{
          'id': 'base_poster',
          'assetPath': posterPath,
          'left': 0,
          'top': 0,
          'width': pageConfig.widthPx,
          'height': pageConfig.heightPx,
          'opacity': 1,
          'visible': true,
          'isLocked': true,
        },
      ],
    };
    await File(
      filePath,
    ).writeAsString(jsonEncode(templateDocument), flush: true);
    return filePath;
  }

  Future<void> _openPosterPhotoEditor(BuildContext context) async {
    if (!_beginAction('poster_editor')) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.strings;
    try {
      final templateSource = await _preparePosterEditorTemplateSource();
      if (templateSource == null) {
        _showSnack(
          messenger,
          strings.localized(
            telugu: 'పోస్టర్ సిద్ధం కాలేదు. మళ్లీ ప్రయత్నించండి.',
            english: 'Poster is not ready yet. Please try again.',
          ),
        );
        return;
      }
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ImageEditorScreen(
            pageConfig: _editorPageConfigForPoster(),
            templateDocumentSource: templateSource,
            initialPosterProfile: item.personalizationConfig != null
                ? viewerPosterProfile
                : null,
            initialPersonalizationConfig: item.personalizationConfig,
            includeInitialPosterNameLayer: false,
            autoSelectInitialLayers: false,
            preferFullWidthCanvas: true,
            requireSubscriptionForExportActions: true,
            initialPhotoShapeOverride: _photoUserAdjustment.effectiveShape,
            initialPhotoRenderModeOverride:
                _photoUserAdjustment.effectivePhotoRenderMode,
            initialPhotoXOffsetPercent: _photoUserAdjustment.xOffsetPercent,
            initialPhotoYOffsetPercent: _photoUserAdjustment.yOffsetPercent,
            lockTemplateLayers: false,
            autoProcessAddedPhotos: true,
            defaultAddedPhotoMaskShape: 'transparent_bottom_fade',
          ),
        ),
      );
    } catch (error, stackTrace) {
      _homeDebugLogStack('poster editor open failed: $error', stackTrace);
      if (context.mounted) {
        _showSnack(
          messenger,
          strings.localized(
            telugu: 'ఎడిటర్ ఓపెన్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
            english: 'Could not open editor. Please try again.',
          ),
        );
      }
    } finally {
      _endAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = context.strings;
    final personalizationConfig = item.personalizationConfig;
    final canTogglePhoto = personalizationConfig != null && !item.isVideo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: _showPosterPhotoNotifier,
            builder: (context, isPhotoVisible, _) {
              final preview = _buildPosterPreview(
                isPhotoVisible: isPhotoVisible,
                onPosterReadyChanged: _handlePosterReadyState,
              );
              if (deferRichPosterPreview) {
                return KeyedSubtree(key: _posterCaptureKey, child: preview);
              }
              return KeyedSubtree(
                key: _posterCaptureKey,
                child: Screenshot(
                  controller: _posterScreenshotController,
                  child: preview,
                ),
              );
            },
          ),
          if (deferRichPosterPreview) ...<Widget>[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
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
                      onTap: deferRichPosterPreview
                          ? null
                          : () {
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
                                onChanged: deferRichPosterPreview
                                    ? null
                                    : (bool value) {
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
                      onPressed:
                          deferRichPosterPreview ||
                              item.isVideo ||
                              activeAction != null
                          ? null
                          : () => unawaited(_onShareTap(context)),
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/branding/whatsapp_icon.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.whatshot_rounded, size: 18),
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        minimumSize: const Size.fromHeight(42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
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
                        onPressed: deferRichPosterPreview
                            ? null
                            : () {
                                _invalidatePreparedPosterCache();
                                _showPosterPhotoNotifier.value =
                                    !isPhotoVisible;
                                _schedulePosterWarmup(force: true);
                              },
                        icon: Icon(
                          isPhotoVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 16,
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
                            fontSize: 12,
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
                          minimumSize: const Size.fromHeight(40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                      onPressed:
                          deferRichPosterPreview ||
                              item.isVideo ||
                              activeAction != null
                          ? null
                          : () => unawaited(_onDownloadTap(context)),
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        isBusy
                            ? strings.localized(
                                telugu: 'à°¸à°¿à°¦à±à°§à°‚...',
                                english: 'Preparing...',
                              )
                            : strings.downloadLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF64748B)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (!item.isVideo) ...<Widget>[
            const SizedBox(height: 10),
            ValueListenableBuilder<String?>(
              valueListenable: _activeActionNotifier,
              builder: (context, activeAction, _) {
                final isBusy = activeAction == 'poster_editor';
                return OutlinedButton.icon(
                  onPressed: deferRichPosterPreview || activeAction != null
                      ? null
                      : () => unawaited(_openPosterPhotoEditor(context)),
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: Text(
                    strings.localized(telugu: 'ఎడిట్', english: 'Edit'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D28D9),
                    side: const BorderSide(color: Color(0xFFC4B5FD)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size.fromHeight(38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ],
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
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}

class _TemplatePosterImage extends StatefulWidget {
  const _TemplatePosterImage({
    required this.imageAssetPath,
    required this.imageUrl,
    this.thumbnailUrl,
    this.preferOriginalPosterQuality = false,
    this.preferUltraLightDecode = false,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? thumbnailUrl;
  final bool preferOriginalPosterQuality;
  final bool preferUltraLightDecode;
  final VoidCallback? onFirstFrameReady;

  @override
  State<_TemplatePosterImage> createState() => _TemplatePosterImageState();
}

class _TemplatePosterImageState extends State<_TemplatePosterImage> {
  static const int _feedPosterDecodeMinWidth = 280;
  static const int _feedPosterDecodeMaxWidth = 560;
  static const int _feedPosterUltraLightMinWidth = 180;
  static const int _feedPosterUltraLightMaxWidth = 280;
  static const int _feedPosterThumbMinWidth = 140;
  static const int _feedPosterThumbMaxWidth = 240;
  ImageProvider<Object>? _mainNetworkProvider;
  ImageProvider<Object>? _thumbnailProvider;
  String? _mainProviderUrl;
  String? _thumbnailProviderUrl;
  int? _mainProviderWidth;
  int? _thumbnailProviderWidth;
  Object? _aspectRatioSource;
  ImageStream? _aspectRatioStream;
  ImageStreamListener? _aspectRatioListener;
  double? _resolvedAspectRatio;

  @override
  void didUpdateWidget(covariant _TemplatePosterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.preferOriginalPosterQuality !=
            widget.preferOriginalPosterQuality ||
        oldWidget.preferUltraLightDecode != widget.preferUltraLightDecode) {
      _mainNetworkProvider = null;
      _thumbnailProvider = null;
      _mainProviderUrl = null;
      _thumbnailProviderUrl = null;
      _mainProviderWidth = null;
      _thumbnailProviderWidth = null;
      _resetAspectRatioResolution();
    }
  }

  @override
  void dispose() {
    _detachAspectRatioListener();
    super.dispose();
  }

  void _resetAspectRatioResolution() {
    _detachAspectRatioListener();
    _aspectRatioSource = null;
    _resolvedAspectRatio = null;
  }

  void _detachAspectRatioListener() {
    final stream = _aspectRatioStream;
    final listener = _aspectRatioListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _aspectRatioStream = null;
    _aspectRatioListener = null;
  }

  void _resolveAspectRatio({
    required Object sourceKey,
    required ImageProvider<Object> provider,
  }) {
    if (_aspectRatioSource == sourceKey && _resolvedAspectRatio != null) {
      return;
    }
    if (_aspectRatioSource == sourceKey && _aspectRatioListener != null) {
      return;
    }

    _detachAspectRatioListener();
    _aspectRatioSource = sourceKey;

    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final width = info.image.width;
        final height = info.image.height;
        if (width <= 0 || height <= 0 || !mounted) {
          return;
        }
        final nextAspectRatio = width / height;
        if (_resolvedAspectRatio == nextAspectRatio &&
            _aspectRatioSource == sourceKey) {
          return;
        }
        void applyAspectRatio() {
          if (!mounted || _aspectRatioSource != sourceKey) {
            return;
          }
          setState(() {
            _resolvedAspectRatio = nextAspectRatio;
          });
          _detachAspectRatioListener();
        }

        if (synchronousCall) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            applyAspectRatio();
          });
        } else {
          applyAspectRatio();
        }
      },
      onError: (_, _) {
        if (_aspectRatioSource == sourceKey) {
          _detachAspectRatioListener();
        }
      },
    );
    _aspectRatioStream = stream;
    _aspectRatioListener = listener;
    stream.addListener(listener);
  }

  ImageProvider<Object> _networkProviderFor({
    required String url,
    required int decodeWidth,
  }) {
    final baseProvider = widget.preferOriginalPosterQuality
        ? CachedNetworkImageProvider(
            url,
            cacheManager: PosterNetworkImageCache.instance,
          )
        : CachedNetworkImageProvider(
            url,
            cacheManager: PosterNetworkImageCache.instance,
            maxWidth: PosterNetworkImageLimits.diskFeedMaxWidth,
            maxHeight: PosterNetworkImageLimits.diskFeedMaxHeight,
          );
    if (widget.preferOriginalPosterQuality) {
      return baseProvider;
    }
    return ResizeImage.resizeIfNeeded(decodeWidth, null, baseProvider);
  }

  ImageProvider<Object> _mainProviderFor(String url, int decodeWidth) {
    if (_mainNetworkProvider == null ||
        _mainProviderUrl != url ||
        _mainProviderWidth != decodeWidth) {
      _mainProviderUrl = url;
      _mainProviderWidth = decodeWidth;
      _mainNetworkProvider = _networkProviderFor(
        url: url,
        decodeWidth: decodeWidth,
      );
    }
    return _mainNetworkProvider!;
  }

  ImageProvider<Object> _thumbnailProviderFor(String url, int decodeWidth) {
    if (_thumbnailProvider == null ||
        _thumbnailProviderUrl != url ||
        _thumbnailProviderWidth != decodeWidth) {
      _thumbnailProviderUrl = url;
      _thumbnailProviderWidth = decodeWidth;
      _thumbnailProvider = _networkProviderFor(
        url: url,
        decodeWidth: decodeWidth,
      );
    }
    return _thumbnailProvider!;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          void schedulePosterReady() {
            final VoidCallback? cb = widget.onFirstFrameReady;
            if (cb != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => cb());
            }
          }

          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final pixelRatio = MediaQuery.devicePixelRatioOf(
            context,
          ).clamp(1.0, 3.0);
          final shouldPreferUltraLightDecode =
              !widget.preferOriginalPosterQuality &&
              (widget.preferUltraLightDecode ||
                  Scrollable.recommendDeferredLoadingForContext(context));
          final cacheWidth = shouldPreferUltraLightDecode
              ? (width * pixelRatio * 0.38).round().clamp(
                  _feedPosterUltraLightMinWidth,
                  _feedPosterUltraLightMaxWidth,
                )
              : widget.preferOriginalPosterQuality
              ? (width * pixelRatio).round().clamp(320, 2048)
              : (width * pixelRatio).round().clamp(
                  _feedPosterDecodeMinWidth,
                  _feedPosterDecodeMaxWidth,
                );
          final posterPlaceholderHeight = width.isFinite && width >= 48
              ? math.max(width * 1.25, 260.0)
              : 260.0;

          final placeholderUrl = widget.thumbnailUrl?.trim() ?? '';
          final mainUrlTrim = (widget.imageUrl ?? '').trim();
          final primaryNetworkUrl = mainUrlTrim.isNotEmpty
              ? mainUrlTrim
              : placeholderUrl;

          Widget buildNetworkPosterImage({
            required String resolvedUrl,
            required int decodeWidth,
            required bool notifyWhenLoaded,
          }) {
            final imageProvider = _mainProviderFor(resolvedUrl, decodeWidth);
            final loadingThumb = placeholderUrl;
            final hasSeparateThumbnail =
                loadingThumb.isNotEmpty && loadingThumb != resolvedUrl;
            final ImageProvider<Object>? thumbnailProvider =
                hasSeparateThumbnail
                ? _thumbnailProviderFor(
                    loadingThumb,
                    shouldPreferUltraLightDecode
                        ? decodeWidth.clamp(
                            _feedPosterThumbMinWidth,
                            _feedPosterUltraLightMaxWidth,
                          )
                        : decodeWidth.clamp(
                            _feedPosterThumbMinWidth,
                            _feedPosterThumbMaxWidth,
                          ),
                  )
                : null;
            return Image(
              image: imageProvider,
              width: double.infinity,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              filterQuality: widget.preferOriginalPosterQuality
                  ? FilterQuality.high
                  : FilterQuality.low,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  if (notifyWhenLoaded && widget.onFirstFrameReady != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onFirstFrameReady!.call();
                    });
                  }
                  if (thumbnailProvider == null) {
                    return child;
                  }
                  return Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      Image(
                        image: thumbnailProvider,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        gaplessPlayback: true,
                        filterQuality: widget.preferOriginalPosterQuality
                            ? FilterQuality.high
                            : FilterQuality.low,
                      ),
                      child,
                    ],
                  );
                }
                if (thumbnailProvider != null) {
                  return Image(
                    image: thumbnailProvider,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    filterQuality: widget.preferOriginalPosterQuality
                        ? FilterQuality.high
                        : FilterQuality.low,
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  height: posterPlaceholderHeight,
                  child: const _ImageLoadingState(),
                );
              },
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                final strings = context.strings;
                final failed = resolvedUrl.trim();
                final thumb = placeholderUrl;
                if (thumb.isNotEmpty && thumb != failed) {
                  return buildNetworkPosterImage(
                    resolvedUrl: thumb,
                    decodeWidth: decodeWidth.clamp(360, 960),
                    notifyWhenLoaded: true,
                  );
                }
                if (failed.startsWith('http://') ||
                    failed.startsWith('https://')) {
                  unawaited(
                    PosterNetworkImageCache.instance.removeFile(failed),
                  );
                  return Image.network(
                    failed,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    filterQuality: widget.preferOriginalPosterQuality
                        ? FilterQuality.high
                        : FilterQuality.low,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            if (notifyWhenLoaded &&
                                widget.onFirstFrameReady != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                widget.onFirstFrameReady!.call();
                              });
                            }
                            return child;
                          }
                          return SizedBox(
                            width: double.infinity,
                            height: posterPlaceholderHeight,
                            child: const _ImageLoadingState(),
                          );
                        },
                    errorBuilder: (_, _, _) {
                      schedulePosterReady();
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
                }
                schedulePosterReady();
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
          }

          if (widget.imageAssetPath == null && primaryNetworkUrl.isEmpty) {
            schedulePosterReady();
            final strings = context.strings;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: math.max(width, 1)),
                child: _ImageErrorState(
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
                ),
              ),
            );
          }

          final imageWidget = widget.imageAssetPath != null
              ? Image.asset(
                  widget.imageAssetPath!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  gaplessPlayback: true,
                  filterQuality: widget.preferOriginalPosterQuality
                      ? FilterQuality.high
                      : FilterQuality.low,
                  cacheWidth: cacheWidth,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          if (widget.onFirstFrameReady != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onFirstFrameReady!.call();
                            });
                          }
                          return child;
                        }
                        return SizedBox(
                          width: double.infinity,
                          height: posterPlaceholderHeight,
                          child: const _ImageLoadingState(),
                        );
                      },
                  errorBuilder: (_, _, _) {
                    schedulePosterReady();
                    return _ImageErrorState(
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
                    );
                  },
                )
              : buildNetworkPosterImage(
                  resolvedUrl: primaryNetworkUrl,
                  decodeWidth: cacheWidth,
                  notifyWhenLoaded: true,
                );

          if (widget.imageAssetPath != null) {
            _resolveAspectRatio(
              sourceKey: 'asset:${widget.imageAssetPath!}',
              provider: AssetImage(widget.imageAssetPath!),
            );
          } else if (primaryNetworkUrl.isNotEmpty) {
            _resolveAspectRatio(
              sourceKey: 'network:$primaryNetworkUrl',
              provider: _mainProviderFor(primaryNetworkUrl, cacheWidth),
            );
          }

          final wrappedImageWidget =
              _resolvedAspectRatio != null && _resolvedAspectRatio! > 0
              ? AspectRatio(
                  aspectRatio: _resolvedAspectRatio!,
                  child: imageWidget,
                )
              : imageWidget;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: math.max(width, 1)),
              child: wrappedImageWidget,
            ),
          );
        },
      ),
    );
  }
}

class _ResolvedTemplatePosterImage extends StatefulWidget {
  const _ResolvedTemplatePosterImage({
    required this.imageAssetPath,
    required this.imageUrl,
    this.imageStoragePath,
    this.thumbnailStoragePath,
    this.thumbnailUrl,
    this.posterIdForDebug,
    this.preferOriginalPosterQuality = false,
    this.preferUltraLightDecode = false,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final String? posterIdForDebug;
  final bool preferOriginalPosterQuality;
  final bool preferUltraLightDecode;
  final VoidCallback? onFirstFrameReady;

  @override
  State<_ResolvedTemplatePosterImage> createState() =>
      _ResolvedTemplatePosterImageState();
}

class _ResolvedTemplatePosterImageState
    extends State<_ResolvedTemplatePosterImage>
    with AutomaticKeepAliveClientMixin<_ResolvedTemplatePosterImage> {
  static final Map<String, String> _resolvedDownloadUrlCache =
      <String, String>{};
  static final Set<String> _failedResolveKeys = <String>{};
  static final Set<String> _loggedResolveFailures = <String>{};

  String? _resolvedImageUrl;
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _resetResolvedImageUrl();
  }

  @override
  void didUpdateWidget(covariant _ResolvedTemplatePosterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageStoragePath != widget.imageStoragePath ||
        oldWidget.thumbnailStoragePath != widget.thumbnailStoragePath ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.preferOriginalPosterQuality !=
            widget.preferOriginalPosterQuality) {
      _resetResolvedImageUrl();
    }
  }

  void _resetResolvedImageUrl() {
    _resolveGeneration++;
    final generation = _resolveGeneration;
    final path = widget.imageStoragePath?.trim() ?? '';
    final thumbPath = widget.thumbnailStoragePath?.trim() ?? '';
    final direct = widget.imageUrl?.trim() ?? '';
    final thumb = widget.thumbnailUrl?.trim() ?? '';

    final hasDirectDownloadUrl = _posterStringLooksDirectHttpDownloadUrl(
      direct,
    );
    if (hasDirectDownloadUrl) {
      _resolvedImageUrl = direct;
      return;
    }

    final candidates = List<_PosterFirebaseCandidate>.from(
      _posterFirebaseResolveCandidates(
        imageStoragePath: path,
        thumbnailStoragePath: thumbPath,
        imageUrl: direct,
        thumbnailUrl: thumb,
      ),
    );
    final cacheKey = _cacheKeyFor(candidates);

    if (candidates.isNotEmpty) {
      _resolvedImageUrl = _resolvedDownloadUrlCache[cacheKey];
      if (_failedResolveKeys.contains(cacheKey)) {
        _resolvedImageUrl = direct.isNotEmpty
            ? direct
            : (thumb.isNotEmpty ? thumb : _resolvedImageUrl);
        return;
      }
      unawaited(
        _resolvePosterFirebaseDownloads(
          candidates: candidates,
          generation: generation,
        ),
      );
    } else {
      _resolvedImageUrl = direct.isEmpty ? null : direct;
    }
  }

  Future<void> _resolvePosterFirebaseDownloads({
    required List<_PosterFirebaseCandidate> candidates,
    required int generation,
  }) async {
    if (!mounted || generation != _resolveGeneration || candidates.isEmpty) {
      return;
    }

    Object? lastError;
    StackTrace? lastTrace;

    for (final _PosterFirebaseCandidate cand in candidates) {
      if (!mounted || generation != _resolveGeneration) {
        return;
      }
      try {
        final ref = cand.urlMode
            ? FirebaseStorage.instance.refFromURL(cand.value)
            : FirebaseStorage.instance.ref(cand.value);
        final fresh = await ref.getDownloadURL();
        if (!mounted || generation != _resolveGeneration) {
          return;
        }
        final trimmedFresh = fresh.trim();
        if (!mounted || generation != _resolveGeneration) {
          return;
        }
        _resolvedDownloadUrlCache[_cacheKeyFor(candidates)] = trimmedFresh;
        if (_resolvedImageUrl == trimmedFresh) {
          return;
        }
        setState(() {
          _resolvedImageUrl = trimmedFresh;
        });
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastTrace = stackTrace;
      }
    }

    if (!mounted || generation != _resolveGeneration) {
      return;
    }
    if (lastError != null && lastTrace != null) {
      final cacheKey = _cacheKeyFor(candidates);
      _failedResolveKeys.add(cacheKey);
      final posterId = (widget.posterIdForDebug ?? '').trim();
      final debugIdentity = posterId.isNotEmpty ? posterId : cacheKey;
      if (_loggedResolveFailures.add(debugIdentity)) {
        final attempted = candidates
            .map((item) => item.value.trim())
            .join(', ');
        _homeDebugLogStack(
          'Poster asset resolve skipped after unauthorized/invalid access '
          'for $debugIdentity: $lastError; attempted=[$attempted]',
          lastTrace,
        );
      }
    }
  }

  String _cacheKeyFor(List<_PosterFirebaseCandidate> candidates) {
    return candidates
        .map((candidate) {
          final mode = candidate.urlMode ? 'url' : 'path';
          return '$mode:${candidate.value.trim()}';
        })
        .join('|');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final path = widget.imageStoragePath?.trim() ?? '';
    final thumbPath = widget.thumbnailStoragePath?.trim() ?? '';
    final thumb = widget.thumbnailUrl?.trim() ?? '';
    final direct = widget.imageUrl?.trim() ?? '';
    final resolved = _resolvedImageUrl?.trim() ?? '';

    final hasFirebaseCandidates = _posterFirebaseResolveCandidates(
      imageStoragePath: path,
      thumbnailStoragePath: thumbPath,
      imageUrl: direct,
      thumbnailUrl: thumb,
    ).isNotEmpty;

    final String displayUrl;
    if (resolved.isNotEmpty) {
      displayUrl = resolved;
    } else if (widget.preferOriginalPosterQuality &&
        (direct.isNotEmpty || path.isNotEmpty)) {
      displayUrl = direct;
    } else if ((hasFirebaseCandidates ||
            _posterStringLooksFirebaseResolvable(direct)) &&
        thumb.isNotEmpty) {
      displayUrl = thumb;
    } else {
      displayUrl = direct.isNotEmpty ? direct : thumb;
    }

    return _TemplatePosterImage(
      imageAssetPath: widget.imageAssetPath,
      imageUrl: displayUrl.isEmpty ? null : displayUrl,
      thumbnailUrl: widget.preferOriginalPosterQuality
          ? null
          : widget.thumbnailUrl,
      preferOriginalPosterQuality: widget.preferOriginalPosterQuality,
      preferUltraLightDecode: widget.preferUltraLightDecode,
      onFirstFrameReady: widget.onFirstFrameReady,
    );
  }

  @override
  bool get wantKeepAlive => false;
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
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
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

class _FeedTapToPlayVideoPoster extends StatefulWidget {
  const _FeedTapToPlayVideoPoster({
    required this.videoUrl,
    this.imageAssetPath,
    this.imageUrl,
    this.imageStoragePath,
    this.thumbnailStoragePath,
    this.thumbnailUrl,
    this.onReady,
  });

  final String videoUrl;
  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final VoidCallback? onReady;

  @override
  State<_FeedTapToPlayVideoPoster> createState() =>
      _FeedTapToPlayVideoPosterState();
}

class _FeedTapToPlayVideoPosterState extends State<_FeedTapToPlayVideoPoster> {
  bool _playing = false;

  bool get _hasStillFrame =>
      (widget.imageAssetPath?.trim().isNotEmpty ?? false) ||
      (widget.imageUrl?.trim().isNotEmpty ?? false) ||
      (widget.thumbnailUrl?.trim().isNotEmpty ?? false) ||
      (widget.imageStoragePath?.trim().isNotEmpty ?? false) ||
      (widget.thumbnailStoragePath?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    if (!_hasStillFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReady?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_playing) {
      return _TemplateVideoPlayer(
        videoUrl: widget.videoUrl,
        onReady: widget.onReady,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _playing = true),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          if (_hasStillFrame)
            _ResolvedTemplatePosterImage(
              imageAssetPath: widget.imageAssetPath,
              imageUrl: widget.imageUrl ?? '',
              imageStoragePath: widget.imageStoragePath,
              thumbnailStoragePath: widget.thumbnailStoragePath,
              thumbnailUrl: widget.thumbnailUrl,
              onFirstFrameReady: widget.onReady,
            )
          else
            const ColoredBox(color: Color(0xFFEFF3F8)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.26),
              ),
            ),
          ),
          Icon(
            Icons.play_circle_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.94),
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
    final uri = Uri.tryParse(widget.videoUrl.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
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
    this.imageStoragePath,
    this.thumbnailStoragePath,
    this.thumbnailUrl,
    this.pageConfig,
    this.preferOriginalPosterQuality = false,
    required this.personalizationConfig,
    required this.viewerPosterProfile,
    required this.language,
    required this.showProfilePhoto,
    required this.deferLegacyTextPrime,
    required this.posterRenderCycle,
    required this.interactivePhotoEnabled,
    required this.photoShapeOverride,
    required this.photoRenderModeOverride,
    required this.photoXOffsetPercent,
    required this.photoYOffsetPercent,
    required this.onPhotoTap,
    required this.additionalPhotoSelection,
    required this.onAdditionalPhotoTap,
    required this.onPhotoDragDeltaPercent,
    required this.onPhotoDragStateChanged,
    this.onPosterReadyChanged,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final EditorPageConfig? pageConfig;
  final bool preferOriginalPosterQuality;
  final CreatorPosterPersonalization personalizationConfig;
  final PosterProfileData viewerPosterProfile;
  final AppLanguage language;
  final bool showProfilePhoto;
  final bool deferLegacyTextPrime;
  final int posterRenderCycle;
  final bool interactivePhotoEnabled;
  final String photoShapeOverride;
  final String photoRenderModeOverride;
  final double photoXOffsetPercent;
  final double photoYOffsetPercent;
  final VoidCallback onPhotoTap;
  final _PosterExtraPhotoSelection? additionalPhotoSelection;
  final VoidCallback? onAdditionalPhotoTap;
  final void Function({
    required double deltaXPercent,
    required double deltaYPercent,
  })
  onPhotoDragDeltaPercent;
  final ValueChanged<bool> onPhotoDragStateChanged;
  final ValueChanged<bool>? onPosterReadyChanged;

  @override
  State<_CreatorPosterPreview> createState() => _CreatorPosterPreviewState();
}

class _CreatorPosterPreviewState extends State<_CreatorPosterPreview> {
  static const String _visibleTeluguFallbackFontFamily =
      'Anek Telugu Condensed Regular';
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');

  static const List<String> _randomPosterNameFonts = <String>[
    'Pragathi',
    'Brahma',
    'Kranthi',
    'Reshma',
    'Tejafont',
  ];
  static const List<String> _randomEnglishPosterNameFonts = <String>[
    'Montserrat',
    'Oswald',
    'Cinzel',
    'Raleway',
    'Rubik',
  ];

  static const List<List<Color>> _posterStripGradients = <List<Color>>[
    <Color>[Color(0xFF5B2C83), Color(0xFF8A4BC9)],
    <Color>[Color(0xFF0F4C75), Color(0xFF3282B8)],
    <Color>[Color(0xFF8D153A), Color(0xFFC84B68)],
    <Color>[Color(0xFF5A3E2B), Color(0xFF9C6B4A)],
    <Color>[Color(0xFF374151), Color(0xFF6B7280)],
  ];

  bool _basePosterReady = false;
  int _legacyPrimeGeneration = 0;
  final Map<String, String> _legacyTextOverrides = <String, String>{};
  final Set<String> _legacyTextRequestsInFlight = <String>{};
  Timer? _baseImageReadyFallbackTimer;
  Offset? _activePhotoDragLastGlobalPosition;

  void _scheduleBaseImageReadyFallback() {
    _baseImageReadyFallbackTimer?.cancel();
    _baseImageReadyFallbackTimer = Timer(const Duration(seconds: 12), () {
      _baseImageReadyFallbackTimer = null;
      if (!mounted || _basePosterReady) {
        return;
      }
      _handleBasePosterReady();
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.deferLegacyTextPrime) {
      _scheduleLegacyPrime();
    }
    _scheduleBaseImageReadyFallback();
  }

  @override
  void dispose() {
    _baseImageReadyFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CreatorPosterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageAssetPath != widget.imageAssetPath ||
        oldWidget.imageStoragePath != widget.imageStoragePath ||
        oldWidget.thumbnailStoragePath != widget.thumbnailStoragePath ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _basePosterReady = false;
      _scheduleBaseImageReadyFallback();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _emitPosterReadyChanged();
        }
      });
    }
    if (oldWidget.viewerPosterProfile != widget.viewerPosterProfile ||
        oldWidget.language != widget.language ||
        oldWidget.personalizationConfig != widget.personalizationConfig ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      if (!widget.deferLegacyTextPrime) {
        _scheduleLegacyPrime();
      }
    }
    if (oldWidget.deferLegacyTextPrime && !widget.deferLegacyTextPrime) {
      _scheduleLegacyPrime();
    }
  }

  void _scheduleLegacyPrime() {
    if (widget.deferLegacyTextPrime) {
      _emitPosterReadyChanged();
      return;
    }
    final generation = ++_legacyPrimeGeneration;
    if (!_needsLegacyTextPrimeForCurrentState()) {
      _emitPosterReadyChanged();
      return;
    }
    _emitPosterReadyChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final updates = await _primeLegacyTextCacheForCurrentState().timeout(
          const Duration(seconds: 15),
          onTimeout: () => const <String, String>{},
        );
        if (!mounted || generation != _legacyPrimeGeneration) {
          return;
        }
        if (updates.isNotEmpty) {
          setState(() {
            _legacyTextOverrides.addAll(updates);
          });
        }
      } catch (_) {
        if (!mounted || generation != _legacyPrimeGeneration) {
          return;
        }
      }
      _emitPosterReadyChanged();
    });
  }

  void _emitPosterReadyChanged() {
    widget.onPosterReadyChanged?.call(_basePosterReady);
  }

  void _handleBasePosterReady() {
    if (_basePosterReady || !mounted) {
      return;
    }
    _baseImageReadyFallbackTimer?.cancel();
    _baseImageReadyFallbackTimer = null;
    setState(() => _basePosterReady = true);
    _emitPosterReadyChanged();
  }

  void _startPhotoDrag(Offset globalPosition) {
    _activePhotoDragLastGlobalPosition = globalPosition;
    widget.onPhotoDragStateChanged(true);
  }

  void _updatePhotoDrag({
    required Offset globalPosition,
    required double currentLeft,
    required double currentTop,
    required double maxWidth,
    required double totalCanvasHeight,
    required double photoWidth,
    required double photoHeight,
  }) {
    final previousGlobalPosition = _activePhotoDragLastGlobalPosition;
    _activePhotoDragLastGlobalPosition = globalPosition;
    if (previousGlobalPosition == null) {
      return;
    }
    final delta = globalPosition - previousGlobalPosition;
    final clampedLeft = (currentLeft + delta.dx).clamp(
      0.0,
      math.max(0.0, maxWidth - photoWidth),
    );
    final clampedTop = (currentTop + delta.dy).clamp(
      0.0,
      math.max(0.0, totalCanvasHeight - photoHeight),
    );
    final appliedDeltaX = clampedLeft - currentLeft;
    final appliedDeltaY = clampedTop - currentTop;
    if (appliedDeltaX == 0 && appliedDeltaY == 0) {
      return;
    }
    widget.onPhotoDragDeltaPercent(
      deltaXPercent: (appliedDeltaX / maxWidth) * 100,
      deltaYPercent: (appliedDeltaY / totalCanvasHeight) * 100,
    );
  }

  void _endPhotoDrag() {
    _activePhotoDragLastGlobalPosition = null;
    widget.onPhotoDragStateChanged(false);
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

  Color _onStripColor(List<Color> colors) {
    final averageLuminance =
        colors.fold<double>(
          0,
          (double sum, Color color) => sum + color.computeLuminance(),
        ) /
        colors.length;
    return averageLuminance > 0.45 ? const Color(0xFF1F2937) : Colors.white;
  }

  String _resolveEnglishPosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|${widget.personalizationConfig.nameX}'
        '|${widget.personalizationConfig.nameY}'
        '|${widget.personalizationConfig.stripHeight}'
        '|english|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index = hash.abs() % _randomEnglishPosterNameFonts.length;
    return _randomEnglishPosterNameFonts[index];
  }

  String? _resolveDisplayNameFontFamily(String text) {
    if (_teluguTextPattern.hasMatch(text)) {
      return _resolvePosterNameFontFamily(text);
    }
    if (_latinTextPattern.hasMatch(text)) {
      return _resolveEnglishPosterNameFontFamily(text);
    }
    return null;
  }

  String _resolveDesignationFontFamily(String text) {
    if (_teluguTextPattern.hasMatch(text)) {
      return 'Pallavi Medium';
    }
    if (_latinTextPattern.hasMatch(text)) {
      return 'Montserrat';
    }
    return 'Poppins';
  }

  bool _isEnglishOnlyText(String text) {
    return !_teluguTextPattern.hasMatch(text) &&
        _latinTextPattern.hasMatch(text);
  }

  Widget _buildEnglishBusinessStrip({
    required String resolvedName,
    required String resolvedDesignation,
    required String? displayNameFontFamily,
    required String designationFontFamily,
    required Color stripTextColor,
    required Color mutedStripTextColor,
    required bool showPhoneInStrip,
    required String resolvedPhone,
  }) {
    final hasDesignation = resolvedDesignation.isNotEmpty;
    if (!hasDesignation && !showPhoneInStrip) {
      return Center(
        child: _legacyAwareText(
          text: resolvedName,
          fontFamily: displayNameFontFamily,
          maxLines: 1,
          textAlign: TextAlign.center,
          fitToWidth: true,
          style: TextStyle(
            color: stripTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 26,
            height: 1.0,
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Flexible(
                child: _legacyAwareText(
                  text: resolvedName,
                  fontFamily: displayNameFontFamily,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  fitToWidth: true,
                  style: TextStyle(
                    color: stripTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    height: 1.0,
                  ),
                ),
              ),
              if (hasDesignation) ...<Widget>[
                const SizedBox(width: 10),
                Container(
                  width: 1.4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: mutedStripTextColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: _legacyAwareText(
                    text: resolvedDesignation,
                    fontFamily: designationFontFamily,
                    maxLines: 1,
                    textAlign: TextAlign.left,
                    fitToWidth: true,
                    style: TextStyle(
                      color: mutedStripTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.0,
                    ),
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
            height: 30,
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
    );
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
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        fontFamily == null) {
      return null;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    return _legacyTextOverrides[key] ??
        TeluguLegacyTextService.cachedValue(text, fontFamily: fontFamily);
  }

  bool _needsLegacyTextPrimeForCurrentState() {
    final resolvedName = widget.viewerPosterProfile.resolvedName(
      language: widget.language,
    );
    final isBusinessProfile =
        widget.viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final resolvedDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.whatsappNumber.trim();
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final designationFontFamily = _resolveDesignationFontFamily(
      resolvedDesignation,
    );
    return _legacyTextNeedsAsyncPrime(resolvedName, displayNameFontFamily) ||
        _legacyTextNeedsAsyncPrime(resolvedDesignation, designationFontFamily);
  }

  bool _legacyTextNeedsAsyncPrime(String text, String? fontFamily) {
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        fontFamily == null ||
        text.trim().isEmpty) {
      return false;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    if (_legacyTextOverrides.containsKey(key)) {
      return false;
    }
    final cached = TeluguLegacyTextService.cachedValue(
      text,
      fontFamily: fontFamily,
    );
    if (cached != null && cached.isNotEmpty) {
      return false;
    }
    return !_legacyTextRequestsInFlight.contains(key);
  }

  Future<MapEntry<String, String>?> _primeLegacyTextValue(
    String text,
    String? fontFamily,
  ) async {
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        fontFamily == null ||
        text.trim().isEmpty) {
      return null;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    final cached = TeluguLegacyTextService.cachedValue(
      text,
      fontFamily: fontFamily,
    );
    if (cached != null && cached.isNotEmpty) {
      return null;
    }
    if (_legacyTextRequestsInFlight.contains(key)) {
      return null;
    }
    _legacyTextRequestsInFlight.add(key);
    try {
      final converted = await TeluguLegacyTextService.convert(
        text,
        fontFamily: fontFamily,
      );
      if (converted != null &&
          converted.isNotEmpty &&
          _legacyTextOverrides[key] != converted) {
        return MapEntry<String, String>(key, converted);
      }
      return null;
    } finally {
      _legacyTextRequestsInFlight.remove(key);
    }
  }

  Future<Map<String, String>> _primeLegacyTextCacheForCurrentState() async {
    final resolvedName = widget.viewerPosterProfile.resolvedName(
      language: widget.language,
    );
    final isBusinessProfile =
        widget.viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final resolvedDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.whatsappNumber.trim();
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final entries = await Future.wait<MapEntry<String, String>?>(
      <Future<MapEntry<String, String>?>>[
        _primeLegacyTextValue(resolvedName, displayNameFontFamily),
        _primeLegacyTextValue(
          resolvedDesignation,
          _resolveDesignationFontFamily(resolvedDesignation),
        ),
      ],
    );
    final updates = <String, String>{};
    for (final entry in entries) {
      if (entry != null) {
        updates[entry.key] = entry.value;
      }
    }
    return updates;
  }

  Widget _legacyAwareText({
    required String text,
    required TextStyle style,
    required String? fontFamily,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.center,
    bool fitToWidth = false,
  }) {
    Widget buildText(String value, {String? resolvedFontFamily}) {
      final textWidget = Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: style.copyWith(fontFamily: resolvedFontFamily ?? fontFamily),
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
    final override = _legacyOverrideFor(text, fontFamily);
    if (override != null && override.isNotEmpty) {
      return buildText(override);
    }
    return buildText(
      text,
      resolvedFontFamily: _visibleTeluguFallbackFontFamily,
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
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final personalNameFontSize = isTeluguName ? 42.0 : 36.0;
    final personalNameLineHeight = isTeluguName ? 0.82 : 0.95;
    final businessNameFontSize = isTeluguName ? 34.0 : 28.0;
    final designationFontFamily = _resolveDesignationFontFamily(
      resolvedDesignation,
    );
    final showPhoneInStrip = isBusinessProfile && resolvedPhone.isNotEmpty;
    final bottomStripPadding = (widget.personalizationConfig.stripHeight * 0.3)
        .clamp(4.0, 8.0);
    final preserveOriginalCanvasBounds = false;
    final stripOverflowAllowance =
        widget.personalizationConfig.showBottomStrip &&
            !preserveOriginalCanvasBounds
        ? (isBusinessProfile ? 56.0 : 60.0)
        : 0.0;

    final showPhotoOverlay = _basePosterReady;

    Widget buildPosterVisual() {
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (widget.pageConfig != null)
            AspectRatio(
              aspectRatio: widget.pageConfig!.aspectRatio,
              child: _ResolvedTemplatePosterImage(
                imageAssetPath: widget.imageAssetPath,
                imageUrl: widget.imageUrl ?? '',
                imageStoragePath: widget.imageStoragePath,
                thumbnailStoragePath: widget.thumbnailStoragePath,
                thumbnailUrl: widget.thumbnailUrl,
                preferOriginalPosterQuality: widget.preferOriginalPosterQuality,
                onFirstFrameReady: _handleBasePosterReady,
              ),
            )
          else
            _ResolvedTemplatePosterImage(
              imageAssetPath: widget.imageAssetPath,
              imageUrl: widget.imageUrl ?? '',
              imageStoragePath: widget.imageStoragePath,
              thumbnailStoragePath: widget.thumbnailStoragePath,
              thumbnailUrl: widget.thumbnailUrl,
              preferOriginalPosterQuality: widget.preferOriginalPosterQuality,
              onFirstFrameReady: _handleBasePosterReady,
            ),
          if (widget.showProfilePhoto && shouldShowIdentityVisual)
            Positioned.fill(
              bottom: -stripOverflowAllowance,
              child: Offstage(
                offstage: !showPhotoOverlay,
                child: IgnorePointer(
                  ignoring: !showPhotoOverlay,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final photoScale =
                          widget.personalizationConfig.photoScale / 100;
                      final baseImageHeight = math.max(
                        1.0,
                        constraints.maxHeight - stripOverflowAllowance,
                      );
                      final totalCanvasHeight = math.max(
                        1.0,
                        constraints.maxHeight,
                      );
                      final visualScale = isBusinessProfile
                          ? photoScale * 0.72
                          : photoScale;
                      final effectivePhotoShape = isBusinessProfile
                          ? 'circle'
                          : (widget.photoShapeOverride.trim().isNotEmpty
                                ? widget.photoShapeOverride.trim()
                                : widget.personalizationConfig.photoShape);
                      final effectivePhotoRenderMode = isBusinessProfile
                          ? 'original'
                          : (widget.photoRenderModeOverride.trim().isNotEmpty
                                ? widget.photoRenderModeOverride.trim()
                                : widget.personalizationConfig.photoRenderMode);
                      final maskAspectRatio = _photoMaskAspectRatio(
                        effectivePhotoShape,
                      );
                      final additionalPhotoProfile = widget
                          .additionalPhotoSelection
                          ?.asPosterProfileData();
                      final showAdditionalPhotoSlot =
                          widget.personalizationConfig.showVideoExtraPhoto;
                      final additionalPhotoShape =
                          widget.personalizationConfig.videoExtraPhotoShape;
                      final additionalPhotoRenderMode = widget
                          .personalizationConfig
                          .videoExtraPhotoRenderMode;
                      final additionalPhotoWidth =
                          constraints.maxWidth *
                          (widget.personalizationConfig.videoExtraPhotoScale /
                              100);
                      final additionalPhotoHeight =
                          additionalPhotoWidth /
                          _photoMaskAspectRatio(additionalPhotoShape);
                      final additionalPhotoLeft =
                          (constraints.maxWidth *
                              (widget.personalizationConfig.videoExtraPhotoX /
                                  100)) -
                          (additionalPhotoWidth / 2);
                      final additionalPhotoTop =
                          (baseImageHeight *
                              (widget.personalizationConfig.videoExtraPhotoY /
                                  100)) -
                          (additionalPhotoHeight / 2);
                      final width = constraints.maxWidth * visualScale;
                      final height = width / maskAspectRatio;
                      final left =
                          (constraints.maxWidth *
                              (widget.personalizationConfig.photoX / 100)) -
                          (width / 2) +
                          (constraints.maxWidth *
                              (widget.photoXOffsetPercent / 100));
                      final top =
                          (baseImageHeight *
                              (widget.personalizationConfig.photoY / 100)) -
                          (height / 2) +
                          (totalCanvasHeight *
                              (widget.photoYOffsetPercent / 100));
                      return Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            left: left,
                            top: top,
                            width: width,
                            height: height,
                            child: RawGestureDetector(
                              behavior: HitTestBehavior.opaque,
                              gestures: <Type, GestureRecognizerFactory>{
                                TapGestureRecognizer:
                                    GestureRecognizerFactoryWithHandlers<
                                      TapGestureRecognizer
                                    >(TapGestureRecognizer.new, (
                                      TapGestureRecognizer instance,
                                    ) {
                                      instance.onTap =
                                          widget.interactivePhotoEnabled
                                          ? widget.onPhotoTap
                                          : null;
                                    }),
                                LongPressGestureRecognizer:
                                    GestureRecognizerFactoryWithHandlers<
                                      LongPressGestureRecognizer
                                    >(
                                      () => LongPressGestureRecognizer(
                                        duration: const Duration(seconds: 2),
                                      ),
                                      (LongPressGestureRecognizer instance) {
                                        if (!widget.interactivePhotoEnabled) {
                                          instance
                                            ..onLongPressStart = null
                                            ..onLongPressMoveUpdate = null
                                            ..onLongPressEnd = null
                                            ..onLongPressCancel = null;
                                          return;
                                        }
                                        instance.onLongPressStart =
                                            (LongPressStartDetails details) =>
                                                _startPhotoDrag(
                                                  details.globalPosition,
                                                );
                                        instance.onLongPressMoveUpdate =
                                            (
                                              LongPressMoveUpdateDetails
                                              details,
                                            ) => _updatePhotoDrag(
                                              globalPosition:
                                                  details.globalPosition,
                                              currentLeft: left,
                                              currentTop: top,
                                              maxWidth: constraints.maxWidth,
                                              totalCanvasHeight:
                                                  totalCanvasHeight,
                                              photoWidth: width,
                                              photoHeight: height,
                                            );
                                        instance.onLongPressEnd =
                                            (LongPressEndDetails _) =>
                                                _endPhotoDrag();
                                        instance.onLongPressCancel =
                                            _endPhotoDrag;
                                      },
                                    ),
                              },
                              child: _PhotoShapeFrame(
                                shape: effectivePhotoShape,
                                edgeStyle:
                                    widget.personalizationConfig.edgeStyle,
                                photoRenderMode: effectivePhotoRenderMode,
                                isBusinessLogo: isBusinessProfile,
                                child: PosterIdentityVisual(
                                  profile: widget.viewerPosterProfile,
                                  fit: isBusinessProfile
                                      ? BoxFit.contain
                                      : effectivePhotoRenderMode == 'cutout'
                                      ? BoxFit.contain
                                      : BoxFit.cover,
                                  preferOriginalPersonalPhoto:
                                      effectivePhotoRenderMode == 'original',
                                  allowOriginalFallbackWhenCutoutUnavailable:
                                      effectivePhotoRenderMode == 'original',
                                  textScale:
                                      widget.viewerPosterProfile.identityMode ==
                                          PosterIdentityMode.business
                                      ? 0.84
                                      : 1.0,
                                ),
                              ),
                            ),
                          ),
                          if (showAdditionalPhotoSlot)
                            Positioned(
                              left: additionalPhotoLeft,
                              top: additionalPhotoTop,
                              width: additionalPhotoWidth,
                              height: additionalPhotoHeight,
                              child: GestureDetector(
                                onTap: widget.onAdditionalPhotoTap,
                                behavior: HitTestBehavior.opaque,
                                child: additionalPhotoProfile != null
                                    ? _PhotoShapeFrame(
                                        shape: additionalPhotoShape,
                                        edgeStyle: widget
                                            .personalizationConfig
                                            .videoExtraPhotoEdgeStyle,
                                        photoRenderMode:
                                            additionalPhotoRenderMode,
                                        isBusinessLogo: false,
                                        child: PosterIdentityVisual(
                                          profile: additionalPhotoProfile,
                                          fit:
                                              additionalPhotoRenderMode ==
                                                  'cutout'
                                              ? BoxFit.contain
                                              : BoxFit.cover,
                                          preferOriginalPersonalPhoto:
                                              additionalPhotoRenderMode ==
                                              'original',
                                          allowOriginalFallbackWhenCutoutUnavailable:
                                              true,
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.4,
                                          ),
                                          boxShadow: const <BoxShadow>[
                                            BoxShadow(
                                              color: Color(0x55000000),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            context.strings.localized(
                                              telugu: 'Add Photo',
                                              english: 'Add Photo',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          if (!widget.personalizationConfig.showBottomStrip)
                            Positioned(
                              left:
                                  constraints.maxWidth *
                                  (widget.personalizationConfig.nameX / 100),
                              top:
                                  constraints.maxHeight *
                                  (widget.personalizationConfig.nameY / 100),
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
              ),
            ),
        ],
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                buildPosterVisual(),
                if (widget.personalizationConfig.showBottomStrip &&
                    !preserveOriginalCanvasBounds)
                  _buildPosterBottomStrip(
                    resolvedName: resolvedName,
                    resolvedDesignation: resolvedDesignation,
                    displayNameFontFamily: displayNameFontFamily,
                    designationFontFamily: designationFontFamily,
                    isBusinessProfile: isBusinessProfile,
                    isTeluguName: isTeluguName,
                    businessNameFontSize: businessNameFontSize,
                    personalNameFontSize: personalNameFontSize,
                    personalNameLineHeight: personalNameLineHeight,
                    showPhoneInStrip: showPhoneInStrip,
                    resolvedPhone: resolvedPhone,
                    bottomStripPadding: bottomStripPadding,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterBottomStrip({
    required String resolvedName,
    required String resolvedDesignation,
    required String? displayNameFontFamily,
    required String designationFontFamily,
    required bool isBusinessProfile,
    required bool isTeluguName,
    required double businessNameFontSize,
    required double personalNameFontSize,
    required double personalNameLineHeight,
    required bool showPhoneInStrip,
    required String resolvedPhone,
    required double bottomStripPadding,
  }) {
    final stripGradient = _resolvePosterStripGradient(resolvedName);
    final stripTextColor = _onStripColor(stripGradient);
    final mutedStripTextColor = stripTextColor.withValues(alpha: 0.82);
    final dividerColor = Colors.white.withValues(alpha: 0.9);

    Widget buildSplitStripRow({
      required double nameFontSize,
      required double designationFontSize,
      required FontWeight nameFontWeight,
      required FontWeight designationFontWeight,
      required double nameHeight,
      required double designationHeight,
    }) {
      return Row(
        children: <Widget>[
          Expanded(
            child: _legacyAwareText(
              text: resolvedName,
              fontFamily: displayNameFontFamily,
              maxLines: 1,
              textAlign: TextAlign.left,
              fitToWidth: true,
              style: TextStyle(
                color: stripTextColor,
                fontWeight: nameFontWeight,
                fontSize: nameFontSize,
                height: nameHeight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1.5,
            height: 18,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _legacyAwareText(
              text: resolvedDesignation,
              fontFamily: designationFontFamily,
              maxLines: 1,
              textAlign: TextAlign.right,
              fitToWidth: true,
              style: TextStyle(
                color: mutedStripTextColor,
                fontWeight: designationFontWeight,
                fontSize: designationFontSize,
                height: designationHeight,
              ),
            ),
          ),
        ],
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isBusinessProfile)
          resolvedDesignation.isNotEmpty
              ? buildSplitStripRow(
                  nameFontSize: _isEnglishOnlyText(resolvedName)
                      ? 24
                      : businessNameFontSize,
                  designationFontSize: _isEnglishOnlyText(resolvedName)
                      ? 13.5
                      : 18,
                  nameFontWeight: FontWeight.w500,
                  designationFontWeight: _isEnglishOnlyText(resolvedName)
                      ? FontWeight.w600
                      : FontWeight.w400,
                  nameHeight: isTeluguName ? 0.98 : 1.0,
                  designationHeight: 0.98,
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: _isEnglishOnlyText(resolvedName)
                          ? _buildEnglishBusinessStrip(
                              resolvedName: resolvedName,
                              resolvedDesignation: resolvedDesignation,
                              displayNameFontFamily: displayNameFontFamily,
                              designationFontFamily: designationFontFamily,
                              stripTextColor: stripTextColor,
                              mutedStripTextColor: mutedStripTextColor,
                              showPhoneInStrip: showPhoneInStrip,
                              resolvedPhone: resolvedPhone,
                            )
                          : _legacyAwareText(
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
                    ),
                  ],
                )
        else if (_isEnglishOnlyText(resolvedName) &&
            resolvedDesignation.isEmpty) ...<Widget>[
          _legacyAwareText(
            text: resolvedName,
            fontFamily: displayNameFontFamily,
            maxLines: 1,
            textAlign: TextAlign.center,
            fitToWidth: true,
            style: TextStyle(
              color: stripTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              height: 1.0,
            ),
          ),
        ] else if (_isEnglishOnlyText(resolvedName) &&
            resolvedDesignation.isNotEmpty) ...<Widget>[
          buildSplitStripRow(
            nameFontSize: 24,
            designationFontSize: 13.5,
            nameFontWeight: FontWeight.w700,
            designationFontWeight: FontWeight.w600,
            nameHeight: 1.0,
            designationHeight: 1.0,
          ),
        ] else ...<Widget>[
          if (resolvedDesignation.isNotEmpty)
            buildSplitStripRow(
              nameFontSize: personalNameFontSize,
              designationFontSize: 20,
              nameFontWeight: FontWeight.w500,
              designationFontWeight: FontWeight.w400,
              nameHeight: personalNameLineHeight,
              designationHeight: 0.82,
            )
          else
            _legacyAwareText(
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
        ],
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: stripGradient,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: bottomStripPadding,
        ),
        child: content,
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

  bool _isOriginalCleanShape(String currentShape) {
    return currentShape == 'circle' || currentShape == 'square';
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
        return BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.78),
            width: 2.2,
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
      case 'flower':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFFB7185), Color(0xFFF59E0B)],
          ),
        );
      case 'shield':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF1D4ED8), Color(0xFF60A5FA)],
          ),
        );
      case 'arch':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF0F766E), Color(0xFF38BDF8)],
          ),
        );
      case 'blob':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF7C3AED), Color(0xFFF472B6)],
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
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.76),
            width: 2.0,
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
        return const Alignment(0, 0.2);
      case 'blob':
        return const Alignment(0, 0.1);
      case 'shield':
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
        return const _ShapeFramePreset(photoInset: EdgeInsets.all(7));
      case 'soft_burst':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'square':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'arch':
        return const _ShapeFramePreset(
          photoInset: EdgeInsets.fromLTRB(8, 10, 8, 8),
        );
      case 'flower':
        return const _ShapeFramePreset(photoInset: EdgeInsets.all(6));
      case 'shield':
        return const _ShapeFramePreset(
          photoInset: EdgeInsets.fromLTRB(8, 10, 8, 6),
        );
      case 'blob':
        return const _ShapeFramePreset(photoInset: EdgeInsets.all(5));
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
    final shouldForceCleanOriginal =
        effectivePhotoRenderMode == 'original' && _isOriginalCleanShape(shape);
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
      if (shouldForceCleanOriginal) {
        return layer;
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
                Color(0xF2FFFFFF),
                Color(0xCCFFFFFF),
                Color(0x7AFFFFFF),
                Color(0x30FFFFFF),
                Color(0x08FFFFFF),
                Color(0x00FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.4, 0.52, 0.62, 0.72, 0.8, 0.86, 0.9, 1.0],
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

    if (isBusinessLogo) {
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.86),
            width: 1.4,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(clipBehavior: Clip.antiAlias, child: imageWidget),
      );
    }

    final preset = _presetForShape(shape);
    final photoLayer = Padding(
      padding: preset.photoInset,
      child: _isTransparentRoundShape(shape)
          ? _clipPhotoShape(_resolvedShape(shape), imageWidget)
          : _isTransparentPhotoShape(shape)
          ? ClipRect(clipBehavior: Clip.antiAlias, child: imageWidget)
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
