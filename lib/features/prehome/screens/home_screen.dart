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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart'
    show compute, kDebugMode, kIsWeb, kProfileMode, setEquals, ValueListenable;
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
import 'package:mana_poster/app/config/category_display_helper.dart';
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
import 'package:mana_poster/features/image_editor/screens/image_editor_screen_web.dart'
    if (dart.library.io) 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/models/community_status.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/models/political_party.dart';
import 'package:mana_poster/features/prehome/screens/community_status_upload_screen.dart';
import 'package:mana_poster/features/prehome/screens/political_parties_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/screens/user_poster_uploads_screen.dart';
import 'package:mana_poster/features/prehome/services/poster_downloads_service.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_home_banner_service.dart';
import 'package:mana_poster/features/prehome/services/app_location_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/services/community_status_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_schedule_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_lunar_event_dates.dart';
import 'package:mana_poster/features/prehome/services/manual_event_category_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/services/permanent_category_service.dart';
import 'package:mana_poster/features/prehome/services/personalized_video_export_service.dart';
import 'package:mana_poster/features/prehome/services/political_protocol_photo_service.dart';
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

const bool _verboseHomeDebugLogs = false;
bool get _shouldRunFirebaseUiServices => Firebase.apps.isNotEmpty;

void _homeDebugLog(String message) {
  if (!_verboseHomeDebugLogs || (!kDebugMode && !kProfileMode)) {
    return;
  }
  debugPrint(message);
}

void _homeDebugLogStack(String message, StackTrace stackTrace) {
  if (!kDebugMode && !kProfileMode) {
    return;
  }
  developer.log(message, name: 'ManaPosterHome', stackTrace: stackTrace);
  debugPrint(message);
  debugPrint(stackTrace.toString());
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
    ..hideCurrentTopSnackBar()
    ..showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          context.strings.localized(
            telugu:
                'à°²à°¿à°‚à°•à± à°¤à±†à°°à°µà°²à±‡à°•à°ªà±‹à°¯à°¾à°‚. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
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

bool _posterStringLooksHttpUrl(String raw) {
  final lower = raw.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Looks like a Storage object path for [FirebaseStorage.ref], not http(s).
bool _posterStringLooksFirebaseStorageRelativePath(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s.contains('://')) {
    return false;
  }
  return true;
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
  if (!(value.contains('\u00E0\u00B0') ||
      value.contains('\u00E0\u00A4') ||
      value.contains('\u00E0\u00AE') ||
      value.contains('\u00E0\u00B2') ||
      value.contains('\u00E0\u00B4') ||
      value.contains('\u00C3'))) {
    return value;
  }
  var repaired = value;
  try {
    for (var index = 0; index < 3; index++) {
      final decoded = utf8.decode(
        latin1.encode(repaired),
        allowMalformed: true,
      );
      if (decoded == repaired || decoded.trim().isEmpty) {
        break;
      }
      repaired = decoded;
    }
    return repaired;
  } catch (_) {
    return repaired;
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
    this.creatorPublicId,
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

  /// Firestore `categoryId` only â€” used for home dynamic chips, not label tokens.
  final String? primaryFirestoreCategoryId;

  /// Firestore manual / admin category label for home chip + matching.
  final String? categoryDisplayLabel;
  final String? creatorPublicId;
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
        SupportedUiLanguage.malayalam ||
        SupportedUiLanguage.assamese ||
        SupportedUiLanguage.konkani ||
        SupportedUiLanguage.gujarati ||
        SupportedUiLanguage.marathi ||
        SupportedUiLanguage.meitei ||
        SupportedUiLanguage.mizo ||
        SupportedUiLanguage.odia ||
        SupportedUiLanguage.punjabi ||
        SupportedUiLanguage.nepali ||
        SupportedUiLanguage.bengali ||
        SupportedUiLanguage.kashmiri ||
        SupportedUiLanguage.ladakhi => titleEn,
      });
}

class _PosterPhotoUserAdjustment {
  const _PosterPhotoUserAdjustment({
    required this.xOffsetPercent,
    required this.yOffsetPercent,
    this.flipHorizontally = false,
  });

  final double xOffsetPercent;
  final double yOffsetPercent;
  final bool flipHorizontally;

  static const _PosterPhotoUserAdjustment none = _PosterPhotoUserAdjustment(
    xOffsetPercent: 0,
    yOffsetPercent: 0,
  );
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
    this.iconAssetPath,
    this.dateLabel,
    this.selectionSlug,
  });

  final String slug;
  final String label;
  final List<String> matchTags;
  final List<String> presenceTags;
  final bool isDynamic;
  final String? iconAssetPath;
  final String? dateLabel;
  final String? selectionSlug;

  String get effectiveSelectionSlug => selectionSlug ?? slug;
}

class _CategoryChipSlot {
  const _CategoryChipSlot({required this.row, required this.index});

  final int row;
  final int index;
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
    'today_special': <String>['today_special'],
    'birthdays': <String>['birthdays', 'birthday'],
    'life_advice': <String>['life_advice'],
    'gita_wisdom': <String>['gita_wisdom'],
    'devotional': <String>['devotional'],
    'mahabharata': <String>['mahabharata'],
    'anniversary': <String>['anniversary'],
    'good_thoughts': <String>['good_thoughts'],
    'bible': <String>['bible'],
    'islam': <String>['islam'],
    'new': <String>['new'],
    'weekday_special': <String>['weekday_special'],
    'weekday_monday_special': <String>['weekday_monday_special'],
    'weekday_tuesday_special': <String>['weekday_tuesday_special'],
    'weekday_wednesday_special': <String>['weekday_wednesday_special'],
    'weekday_thursday_special': <String>['weekday_thursday_special'],
    'weekday_friday_special': <String>['weekday_friday_special'],
    'weekday_saturday_special': <String>['weekday_saturday_special'],
    'weekday_sunday_special': <String>['weekday_sunday_special'],
    'important_day': <String>['important_day'],
    'regional_special': <String>['regional_special'],
    'festival': <String>['festival'],
    'jayanthi': <String>['jayanthi'],
    'vardhanthi': <String>['vardhanthi'],
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

  final hasExplicitCategory = tags.any(
    (tag) =>
        tag.isNotEmpty &&
        tag != 'all' &&
        !tag.startsWith('state_') &&
        tag != 'india' &&
        tag != 'both_telugu_states',
  );

  if (normalized.contains('birthday')) {
    add('birthdays');
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
    if (!hasExplicitCategory) {
      add('festival');
    }
    add('both_telugu_states');
  }
  if (!hasExplicitCategory && normalized.contains('political')) {
    add('political');
    add('jayanthi');
    add('vardhanthi');
    add('regional_special');
    add('important_day');
  }
  if (!hasExplicitCategory &&
      (normalized.contains('poster') || normalized.contains('flyer'))) {
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
    creatorPublicId: creatorId.isNotEmpty ? creatorId : null,
    personalizationConfig: template.personalizationConfig,
    createdAtMillis: template.createdAtMillis,
    pageConfig: template.pageConfig,
    // Web portal uploads must stay visually lossless in app preview/export.
    // Thumbnails can still exist as fallback metadata, but approved posters
    // should render from the original image source.
    preferOriginalPosterQuality: true,
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

  _TemplateItem? takeWithoutImmediateRepeat(
    List<_TemplateItem> queue, {
    bool allowRepeat = false,
  }) {
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
      if (!allowRepeat &&
          _allCategoryGroupingKeyWorker(queue.first) == lastCategoryKey) {
        return null;
      }
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
    for (final bucket in fallbackOrder) {
      final item = takeWithoutImmediateRepeat(
        queueFor(bucket),
        allowRepeat: true,
      );
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
  final freshTemplateKeys = templates
      .where((item) {
        final createdAtMillis = item.createdAtMillis;
        return createdAtMillis >= startOfTodayMillis &&
            createdAtMillis < endOfTodayMillis;
      })
      .map(_templateSequenceKeyWorker)
      .where((key) => key.isNotEmpty)
      .toSet();

  final seed = Object.hash(
    request.year,
    request.month,
    request.day,
    request.slot.name,
    freshTemplateKeys.isNotEmpty,
  );
  final shuffled = List<_TemplateItem>.of(templates, growable: false)
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
  static const int _allTemplatesWindowPageSize = 24;
  static const int _categoryTemplatesPageSize = 12;
  static const int _promoSlidesLimit = 5;
  static const int _startupCacheWarmTemplatesPageSize = 3;
  static const String _homeFeedRatedKey = 'home_feed_rate_card_completed_v1';
  static const String _allFeedInterestPrefsKey =
      'home_all_feed_interest_scores_v1';
  static const String _homeReferralPromptKeyPrefix =
      'mana_poster_home_referral_prompt_dismissed_';
  static const List<String> _staticCategorySlugs = <String>[
    'all',
    'good_morning',
    'good_afternoon',
    'good_night',
    'motivational',
    'good_evening',
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
  static const String _moreCategorySlug = 'new';
  static const String _selectedMoreCategorySlotSlug = 'selected_more_category';
  static const String _politicalCategorySlug = 'political';
  static const Set<String> _morePopupCategorySlugs = <String>{
    'life_advice',
    'motivational',
    'mahabharata',
    'birthdays',
    'anniversary',
    'good_thoughts',
    'jokes',
  };
  static const int _initialTemplatesPageSize = 8;
  static const int _initialPriorityPrimaryFetchSize = 8;
  static const int _initialPrioritySecondaryFetchSize = 4;
  static const int _startupInitialVisibleTemplateCount = 8;
  static const int _startupMinimumScrollableTemplateCount = 3;
  static const Duration _startupGenericFirstPaintMergeTimeout = Duration(
    milliseconds: 900,
  );
  static const int _startupMergeBatchSize = 6;
  static const int _smallMappingBatchSize = 8;
  static const int _smallMergeBatchInputCount = 16;
  static const int _startupSnapshotTemplateCount = 8;
  static const int _startupSnapshotMinimumVisibleCount = 6;
  static const Duration _startupSnapshotHydrationDelay = Duration(
    milliseconds: 450,
  );
  static const Duration _homeStartupRemoteTimeout = Duration(seconds: 7);
  static const Duration _homeResumeRefreshCooldown = Duration(minutes: 7);
  static const bool _enableDebugHomeStartupServices = bool.fromEnvironment(
    'MANA_POSTER_ENABLE_PROFILE_STARTUP_SERVICES',
    defaultValue: false,
  );

  bool get _shouldRunRemoteHomeStartupTasks =>
      _remoteHomeStartupAllowed || _enableDebugHomeStartupServices;

  static const int _dynamicMorePreviewDays = 3;
  final DynamicCategoryService _dynamicCategoryService =
      const DynamicCategoryService();
  final DynamicCategoryService _dynamicPreviewCategoryService =
      const DynamicCategoryService(daysBeforeEvent: _dynamicMorePreviewDays);
  final AppHomeBannerService _appHomeBannerService =
      const AppHomeBannerService();
  final ApprovedCreatorTemplateService _approvedCreatorTemplateService =
      ApprovedCreatorTemplateService();
  final ManualEventCategoryService _manualEventCategoryService =
      const ManualEventCategoryService();
  final PermanentCategoryService _permanentCategoryService =
      const PermanentCategoryService();
  final ScrollController _posterScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final PageController _posterPageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategorySlug = _allCategorySlug;
  String? _selectedMoreCategorySlug;
  _CategoryChipData? _selectedMoreCategoryChip;
  Set<String> _selectedPoliticalPartyIds = <String>{};
  String _selectedRegionId = '';
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
  bool _allTemplatesWindowExhausted = false;
  int _allTemplatesWindowLimit = _allTemplatesWindowPageSize;
  int _activePosterPage = 0;
  final ValueNotifier<int> _activePosterPageNotifier = ValueNotifier<int>(0);
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
  Future<void>? _permanentCategoriesLoadFuture;
  Future<void>? _partyPreferenceLoadFuture;
  Future<void>? _regionSelectionLoadFuture;
  Future<void>? _regionDependentReloadFuture;
  Future<void>? _viewerProfileLoadFuture;
  bool _referralPromptShowing = false;
  final Set<String> _hydratedCategorySlugs = <String>{};
  final Map<String, int> _categoryFetchLimitBySlug = <String, int>{};
  final Set<String> _categoryExhaustedSlugs = <String>{};
  List<DynamicCategory> _manualEventCategories = const <DynamicCategory>[];
  List<DynamicCategory> _permanentCategories = const <DynamicCategory>[];
  final Map<String, bool> _dynamicCategoryAvailabilityBySlug = <String, bool>{};
  final Map<String, Future<void>> _dynamicCategoryAvailabilityFutureBySlug =
      <String, Future<void>>{};
  final Set<String> _dynamicCategoryAvailabilityInFlight = <String>{};
  bool _moreCategorySheetOpen = false;
  bool _categoryAvailabilityChangedWhileMoreSheetOpen = false;
  String _lastCategoryDebugSnapshot = '';
  String _dynamicCategoryAvailabilitySignature = '';
  _HomeTemplateProjection? _templateProjectionCache;
  Object? _templateProjectionIdentity;
  List<_CategoryChipData>? _categoryListCache;
  Object? _categoryListIdentity;
  AppLanguage? _manualCategoryLanguage;
  bool _adFallbackSlotEnabled = false;
  bool _remoteHomeStartupAllowed = false;
  bool _remoteHomeStartupScheduled = false;
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
  bool _posterFeedLoadMoreArmed = true;
  String _startupFeedWarmupSignature = '';
  bool _startupSnapshotHydrationDeferred = false;
  bool _startupSnapshotAttemptCompleted = false;
  bool _startupPermissionPromptQueued = false;
  bool _screenSecurityProtected = false;
  DateTime? _lastHomeFeedRefreshAt;
  List<_TemplateItem>? _rankedAllFeedTemplates;
  List<_TemplateItem>? _lockedAllFeedTemplates;
  Set<String> _recentAllFeedTemplateKeys = <String>{};
  StreamSubscription<User?>? _authStateSubscription;
  String _lastHomeAuthUid = '';
  Timer? _homeAuthReadyRetryTimer;
  Timer? _startupSnapshotPersistTimer;
  Timer? _allFeedInterestSaveTimer;
  Map<String, double> _allFeedInterestScores = <String, double>{};
  int _allFeedPersonalizationRevision = 0;

  // ignore: unused_field
  static const List<_TemplateItem> _freeTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'à°¶à±à°­à±‹à°¦à°¯à°‚ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤—à¥à¤¡ à¤®à¥‰à¤°à¥à¤¨à¤¿à¤‚à¤— à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Good Morning Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200',
      categoryTags: <String>['good_morning'],
    ),
    _TemplateItem(
      titleTe: 'à°¬à°°à±à°¤à±â€Œà°¡à±‡ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤¬à¤°à¥à¤¥à¤¡à¥‡ à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Birthday Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?w=1200',
      categoryTags: <String>['birthdays'],
    ),
    _TemplateItem(
      titleTe: 'à°­à°•à±à°¤à°¿ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤­à¤•à¥à¤¤à¤¿ à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Devotional Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200',
      categoryTags: <String>['devotional', 'both_telugu_states'],
    ),
  ];
  @override
  void initState() {
    super.initState();
    _protectHomeScreen();
    _homeDebugLog('[StartupTiming] home_init_start t=0ms');
    final initialCategory = widget.initialCategorySlug?.trim();
    if (initialCategory != null && initialCategory.isNotEmpty) {
      _selectedCategorySlug = initialCategory;
    }
    WidgetsBinding.instance.addObserver(this);
    AppRegionService.selectionVersion.addListener(
      _handleRegionSelectionChanged,
    );
    _attachHomeAuthStateSubscriptionIfReady();
    _posterScrollController.addListener(_onPosterScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(() async {
        await _resolveAndScheduleRemoteHomeStartupTasks();
        if (!mounted || !_shouldRunRemoteHomeStartupTasks) {
          return;
        }
        await _refreshHomeFeed();
      }());
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 550),
        _loadAllFeedInterestScores,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 900),
        _loadReligionPreference,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 1150),
        _loadRegionSelection,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 1400),
        _loadPartyPreference,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 2100),
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
        const Duration(milliseconds: 2600),
        _loadPromoCardPreferences,
      );
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 3400),
        _loadInstalledAppVersion,
      );
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

  Future<void> _loadAllFeedInterestScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_allFeedInterestPrefsKey);
      if (raw == null || raw.trim().isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final scores = <String, double>{};
      decoded.forEach((key, value) {
        final normalizedKey = key.toString().trim();
        final normalizedValue = value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
        if (normalizedKey.isNotEmpty &&
            normalizedValue != null &&
            normalizedValue > 0) {
          scores[normalizedKey] = normalizedValue;
        }
      });
      final trimmed = _trimAllFeedInterestScores(scores);
      if (!mounted || trimmed.isEmpty) {
        _allFeedInterestScores = trimmed;
        return;
      }
      setState(() {
        _allFeedInterestScores = trimmed;
        _allFeedPersonalizationRevision++;
        _templateProjectionCache = null;
        _templateProjectionIdentity = null;
      });
    } catch (error, stackTrace) {
      _homeDebugLogStack('all feed interest load skipped: $error', stackTrace);
    }
  }

  Future<void> _persistAllFeedInterestScores() async {
    final scores = _allFeedInterestScores;
    if (scores.isEmpty) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_allFeedInterestPrefsKey, jsonEncode(scores));
    } catch (error, stackTrace) {
      _homeDebugLogStack('all feed interest save skipped: $error', stackTrace);
    }
  }

  void _scheduleAllFeedInterestSave() {
    _allFeedInterestSaveTimer?.cancel();
    _allFeedInterestSaveTimer = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(_persistAllFeedInterestScores()),
    );
  }

  Map<String, double> _trimAllFeedInterestScores(Map<String, double> scores) {
    final entries =
        scores.entries
            .where((entry) => entry.key.trim().isNotEmpty && entry.value > 0.05)
            .toList(growable: false)
          ..sort((a, b) => b.value.compareTo(a.value));
    return <String, double>{
      for (final entry in entries.take(96)) entry.key: entry.value,
    };
  }

  String _compactAllFeedInterestKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final encoded = base64Url.encode(utf8.encode(trimmed));
    return encoded.length <= 72 ? encoded : encoded.substring(0, 72);
  }

  List<String> _allFeedInterestKeysForTemplate(_TemplateItem item) {
    final keys = <String>[];
    final group = _normalizeTag(_allCategoryGroupingKeyWorker(item));
    if (group.isNotEmpty && group != _allCategorySlug) {
      keys.add('category:$group');
    }
    for (final tag in item.categoryTags) {
      final normalized = _normalizeTag(tag);
      if (normalized.isNotEmpty &&
          normalized != _allCategorySlug &&
          normalized != group) {
        keys.add('tag:$normalized');
      }
    }
    final templateId = item.templateId?.trim();
    final stableId = templateId != null && templateId.isNotEmpty
        ? templateId
        : _templateSequenceKey(item);
    final compactId = _compactAllFeedInterestKey(stableId);
    if (compactId.isNotEmpty) {
      keys.add('template:$compactId');
    }
    return keys;
  }

  double _allFeedPersonalizationScore(_TemplateItem item) {
    if (_allFeedInterestScores.isEmpty) {
      return 0;
    }
    var score = 0.0;
    for (final key in _allFeedInterestKeysForTemplate(item)) {
      final value = _allFeedInterestScores[key] ?? 0;
      if (key.startsWith('template:')) {
        score += value * 1.7;
      } else if (key.startsWith('category:')) {
        score += value;
      } else {
        score += value * 0.45;
      }
    }
    return score;
  }

  List<_TemplateItem> _applyAllFeedPersonalization(List<_TemplateItem> source) {
    if (_allFeedInterestScores.isEmpty || source.length < 3) {
      return source;
    }
    final ranked = <({int index, _TemplateItem item, double score})>[];
    var hasPositiveScore = false;
    for (var index = 0; index < source.length; index++) {
      final item = source[index];
      final score = _allFeedPersonalizationScore(item);
      if (score > 0.01) {
        hasPositiveScore = true;
      }
      ranked.add((index: index, item: item, score: score));
    }
    if (!hasPositiveScore) {
      return source;
    }
    ranked.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.index.compareTo(b.index);
    });
    final personalized = ranked
        .map((entry) => entry.item)
        .toList(growable: false);
    final now = IstTimeService.now();
    return _spreadAllCategoryTemplateGroupsWorker(
      personalized,
      seed: Object.hash(
        now.year,
        now.month,
        now.day,
        _activeHomeFeedTimeSlot.name,
        'personalized',
      ),
    );
  }

  void _recordAllFeedTemplateInteraction(_TemplateItem item, String action) {
    if (_selectedCategorySlug != _allCategorySlug) {
      return;
    }
    final weight = switch (action) {
      'share' => 5.0,
      'download' => 3.5,
      'edit' => 2.0,
      'view' => 0.35,
      _ => 0.2,
    };
    final keys = _allFeedInterestKeysForTemplate(item);
    if (keys.isEmpty) {
      return;
    }
    final next = <String, double>{
      for (final entry in _allFeedInterestScores.entries)
        entry.key: entry.value * 0.997,
    };
    for (final key in keys) {
      final multiplier = key.startsWith('template:')
          ? 1.0
          : key.startsWith('category:')
          ? 0.85
          : 0.35;
      next[key] = (next[key] ?? 0) + (weight * multiplier);
    }
    _allFeedInterestScores = _trimAllFeedInterestScores(next);
    _scheduleAllFeedInterestSave();
  }

  void _handleRegionSelectionChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadRegionSelection());
  }

  Future<void> _resolveAndScheduleRemoteHomeStartupTasks() async {
    if (_remoteHomeStartupScheduled) {
      return;
    }
    final allowed = await _isRemoteHomeStartupAllowedForCurrentInstall();
    if (!mounted) {
      return;
    }
    if (!allowed) {
      setState(() {
        _templatesLoading = false;
        _templatesLoadingMore = false;
        _templatesHasMore = false;
        _religionSelectionReady = true;
      });
      return;
    }
    _remoteHomeStartupAllowed = true;
    _remoteHomeStartupScheduled = true;
    setState(() {});
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 450),
        _hidePhoneNavigationButtons,
      ),
    );
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 700),
        ScreenSecurityService.enableSecure,
      ),
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 6200),
      _loadApprovedCreatorTemplatesAfterStartup,
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 7200),
      _loadManualEventCategories,
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 7600),
      _loadPermanentCategories,
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 8200),
      _loadViewerPosterProfile,
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 9000),
      _loadHomeBanners,
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 9800),
      _handlePlayStoreEngagementOnHomeOpen,
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 10800),
      _showReferralPromptIfNeeded,
    );
    _scheduleDeferredHomeStartupTask(
      const Duration(milliseconds: 11800),
      _requestStartupPermissionsIfNeeded,
    );
    _scheduleDeferredHomeStartupTask(const Duration(seconds: 12), () async {
      if (!mounted || _adFallbackSlotEnabled) {
        return;
      }
      setState(() => _adFallbackSlotEnabled = true);
    });
  }

  Future<bool> _isRemoteHomeStartupAllowedForCurrentInstall() async {
    return true;
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
    if (!_shouldRunRemoteHomeStartupTasks) {
      return;
    }
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

  Future<void> _loadPermanentCategories() async {
    if (!_shouldRunRemoteHomeStartupTasks) {
      return;
    }
    final inFlight = _permanentCategoriesLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      await FirebaseBootstrap.ensureInitialized();
      if (!mounted) {
        return;
      }
      final categories = await _permanentCategoryService.fetchActiveCategories(
        language: context.currentLanguage,
      );
      if (!mounted) {
        return;
      }
      _homeDebugLog(
        '[PermanentCategories] loaded=${categories.map((item) => item.slug).join(",")}',
      );
      setState(() {
        _permanentCategories = categories;
      });
      _categoryListCache = null;
      _categoryListIdentity = null;
    }();
    _permanentCategoriesLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_permanentCategoriesLoadFuture, future)) {
        _permanentCategoriesLoadFuture = null;
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
    if (_shouldRunRemoteHomeStartupTasks &&
        _manualCategoryLanguage != currentLanguage) {
      _manualCategoryLanguage = currentLanguage;
      unawaited(_loadManualEventCategories());
      unawaited(_loadPermanentCategories());
    }
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      AppNavigator.routeObserver.subscribe(this, route);
    }
  }

  Future<void> _hidePhoneNavigationButtons() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _restorePhoneNavigationButtons() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _protectHomeScreen() {
    if (_screenSecurityProtected) {
      return;
    }
    _screenSecurityProtected = true;
    unawaited(ScreenSecurityService.protectScreen());
  }

  void _unprotectHomeScreen() {
    if (!_screenSecurityProtected) {
      return;
    }
    _screenSecurityProtected = false;
    unawaited(ScreenSecurityService.unprotectScreen());
  }

  @override
  void didPush() {
    _protectHomeScreen();
    if (_shouldRunRemoteHomeStartupTasks) {
      unawaited(_hidePhoneNavigationButtons());
    }
  }

  @override
  void didPopNext() {
    _protectHomeScreen();
    if (_shouldRunRemoteHomeStartupTasks) {
      unawaited(_hidePhoneNavigationButtons());
      unawaited(_loadViewerPosterProfile());
      unawaited(_loadRegionSelection());
      unawaited(_loadPartyPreference());
      unawaited(_loadReligionPreference());
      unawaited(
        _TemplateFeedItem.subscriptionBackendService
            .refreshEntitlementInBackground(forceRefresh: true),
      );
    }
  }

  @override
  void didPushNext() {
    unawaited(_restorePhoneNavigationButtons());
    _unprotectHomeScreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHomeFeedTimeSlotIfNeeded();
      unawaited(_refreshHomeFeed());
      unawaited(_loadRegionSelection());
      unawaited(_loadPartyPreference());
      unawaited(_loadReligionPreference());
      unawaited(PlayEngagementService.instance.handleAppResume());
      unawaited(
        _TemplateFeedItem.subscriptionBackendService
            .refreshEntitlementInBackground(forceRefresh: true),
      );
    }
  }

  void _handleHomeAuthStateChanged(User? user) {
    final nextUid = user?.uid.trim() ?? '';
    if (nextUid == _lastHomeAuthUid) {
      return;
    }
    _lastHomeAuthUid = nextUid;
    if (!mounted || nextUid.isEmpty) {
      return;
    }
    unawaited(_reloadHomeContentAfterAuthReady());
  }

  void _attachHomeAuthStateSubscriptionIfReady() {
    if (_authStateSubscription != null) {
      return;
    }
    if (!_shouldRunFirebaseUiServices) {
      unawaited(FirebaseBootstrap.ensureInitialized());
      _homeAuthReadyRetryTimer ??= Timer.periodic(
        const Duration(milliseconds: 350),
        (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (_shouldRunFirebaseUiServices) {
            timer.cancel();
            _homeAuthReadyRetryTimer = null;
            _attachHomeAuthStateSubscriptionIfReady();
          }
        },
      );
      return;
    }
    _lastHomeAuthUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleHomeAuthStateChanged,
    );
  }

  Future<void> _reloadHomeContentAfterAuthReady() async {
    await FirebaseBootstrap.ensureInitialized();
    if (!mounted) {
      return;
    }
    if (!_shouldRunRemoteHomeStartupTasks) {
      await _resolveAndScheduleRemoteHomeStartupTasks();
    }
    if (!mounted || !_shouldRunRemoteHomeStartupTasks) {
      return;
    }
    _hydratedCategorySlugs.clear();
    _dynamicCategoryAvailabilityBySlug.clear();
    _dynamicCategoryAvailabilityInFlight.clear();
    _dynamicCategoryAvailabilitySignature = '';
    _categoryListCache = null;
    _categoryListIdentity = null;
    _templateProjectionCache = null;
    _templateProjectionIdentity = null;
    await _refreshHomeFeed(force: true);
    if (!mounted) {
      return;
    }
    _triggerSelectedCategoryPrefetch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppRegionService.selectionVersion.removeListener(
      _handleRegionSelectionChanged,
    );
    AppNavigator.routeObserver.unsubscribe(this);
    _authStateSubscription?.cancel();
    _homeAuthReadyRetryTimer?.cancel();
    _startupSnapshotPersistTimer?.cancel();
    _allFeedInterestSaveTimer?.cancel();
    unawaited(_persistAllFeedInterestScores());
    _posterScrollController
      ..removeListener(_onPosterScroll)
      ..dispose();
    _categoryScrollController.dispose();
    _posterPageController.dispose();
    _activePosterPageNotifier.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    unawaited(_restorePhoneNavigationButtons());
    _unprotectHomeScreen();
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

  Future<void> _loadRegionSelection() async {
    final inFlight = _regionSelectionLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      final region = await AppRegionService.loadSelection();
      final regionId = region?.id ?? '';
      if (!mounted || _selectedRegionId == regionId) {
        return;
      }
      setState(() {
        _selectedRegionId = regionId;
        _homeBanners = const <AppHomeBanner>[];
        _remoteApprovedTemplates = const <_TemplateItem>[];
        _manualEventCategories = const <DynamicCategory>[];
        _templatesLoading = true;
        _templatesLoadingMore = false;
        _templatesHasMore = true;
        _templatesLastDocument = null;
        _lockedAllFeedTemplates = null;
        _rankedAllFeedTemplates = null;
        _allFeedRankingReady = false;
        _allFeedRankingInFlight = false;
        _hydratedCategorySlugs.clear();
        _recentAllFeedTemplateKeys.clear();
        _dynamicCategoryAvailabilityBySlug.clear();
        _dynamicCategoryAvailabilityInFlight.clear();
        _lastCategoryDebugSnapshot = '';
        _dynamicCategoryAvailabilitySignature = '';
        _categoryListCache = null;
        _categoryListIdentity = null;
        _templateProjectionCache = null;
        _templateProjectionIdentity = null;
      });
      unawaited(_reloadRegionDependentHomeContent());
    }();
    _regionSelectionLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_regionSelectionLoadFuture, future)) {
        _regionSelectionLoadFuture = null;
      }
    }
  }

  Future<void> _reloadRegionDependentHomeContent() async {
    final inFlight = _regionDependentReloadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      await Future.wait<void>(<Future<void>>[
        _loadHomeBanners(),
        _loadManualEventCategories(),
        _loadPermanentCategories(),
        _loadApprovedCreatorTemplates(forceRefresh: true),
      ]);
    }();
    _regionDependentReloadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_regionDependentReloadFuture, future)) {
        _regionDependentReloadFuture = null;
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
    final categoryWillReset = _isCategoryHiddenForReligionPreference(
      _selectedCategorySlug,
      selection,
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
        _selectedMoreCategorySlug = null;
        _selectedMoreCategoryChip = null;
      }
    });
  }

  Set<String> _hiddenCategorySlugsForReligion() {
    return AppReligionService.hiddenCategorySlugsFor(_religionPreference);
  }

  bool _isCategoryHiddenForReligion(String slug) {
    return _isCategoryHiddenForReligionPreference(slug, _religionPreference);
  }

  bool _isCategoryHiddenForReligionPreference(
    String slug,
    AppReligionPreference preference,
  ) {
    final normalized = _normalizeTag(slug);
    if (normalized.isEmpty || normalized == _allCategorySlug) {
      return false;
    }
    return AppReligionService.hiddenCategorySlugsFor(
      preference,
    ).contains(normalized);
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
        .where(
          (chip) => !_isCategoryHiddenForReligion(chip.effectiveSelectionSlug),
        )
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

    if (selectedCategory.slug == _politicalCategorySlug) {
      return !_isJokesTemplate(item);
    }

    if (_normalizeTag(selectedCategory.slug).startsWith('party_')) {
      return !_isJokesTemplate(item);
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

    return false;
  }

  bool _isJokesTemplate(_TemplateItem item) {
    final signals = _templateCategorySignalsForMatching(item);
    return signals.contains('jokes') ||
        signals.contains('funny') ||
        signals.contains('humor') ||
        signals.contains('comedy');
  }

  bool _isPoliticalFeedSlug(String slug) {
    final normalized = _normalizeTag(slug);
    return normalized == _politicalCategorySlug ||
        normalized.startsWith('party_');
  }

  String? _partyIdFromCategorySlug(String slug) {
    final normalized = _normalizeTag(slug);
    if (!normalized.startsWith('party_')) {
      return null;
    }
    final partyId = normalized.substring('party_'.length).trim();
    return partyId.isEmpty ? null : partyId;
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
      if (locked.length < _startupMinimumScrollableTemplateCount &&
          _remoteApprovedTemplates.length > locked.length) {
        _lockedAllFeedTemplates = null;
        _templateProjectionCache = null;
        _templateProjectionIdentity = null;
      } else {
        return _applyAllFeedPersonalization(locked);
      }
    }
    if (_allFeedRankingReady && _rankedAllFeedTemplates != null) {
      return _applyAllFeedPersonalization(_rankedAllFeedTemplates!);
    }
    return _applyAllFeedPersonalization(_remoteApprovedTemplates);
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
      ..._dynamicCategoryService.categoriesForDate(
        now,
        language: language,
        selectedRegionId: _selectedRegionId,
      ),
      ..._manualEventCategories.where(
        (item) => _isCategoryActiveOnEventDay(item, now),
      ),
    ];
    final availabilityCandidates = _moreCategoryAvailabilityCandidates(now);
    final eventDateLabelBySlug = _activeDynamicEventDateLabels(now);
    _scheduleDynamicCategoryAvailabilityChecks(<DynamicCategory>[
      ...activeCalendarCategories,
      ...availabilityCandidates,
    ]);
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
        label: _localizedDynamicCategoryLabelForCategory(item),
        matchTags: item.tags,
        presenceTags: _dynamicPresenceTags(item).toList(growable: false),
        isDynamic: true,
        dateLabel: _resolvedDynamicCategoryDateLabel(
          item,
          now: now,
          eventDateLabelBySlug: eventDateLabelBySlug,
        ),
      );
    }

    final loadedDynamicCategories = _dynamicCategoryService
        .categoriesForSlugs(loadedTemplateCategoryKeys, language: language)
        .where((item) => _isDynamicCategoryActiveOnEventDay(item, now));
    final templateDrivenManualCategories = _manualEventCategories.where((item) {
      if (!_isCategoryActiveOnEventDay(item, now)) {
        return false;
      }
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
        label: _localizedDynamicCategoryLabelForCategory(item),
        matchTags: item.tags,
        presenceTags: _dynamicPresenceTags(item).toList(growable: false),
        isDynamic: true,
        dateLabel: _resolvedDynamicCategoryDateLabel(
          item,
          now: now,
          eventDateLabelBySlug: eventDateLabelBySlug,
        ),
      );
    }

    // Admin manual Firestore categories (manualEventCategories) are not in the
    // local calendar JSON â€” add chips from loaded templates so filters match.
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
        label: _localizedDynamicCategoryLabelForSlug(
          rawId,
          label.isNotEmpty ? label : rawId,
        ),
        matchTags: matchTags,
        presenceTags: matchTags,
        isDynamic: true,
        dateLabel: _resolvedDynamicCategoryDateLabelForSignals(
          slug: rawId,
          tags: matchTags,
          now: now,
          eventDateLabelBySlug: eventDateLabelBySlug,
        ),
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

  Map<String, String> _activeDynamicEventDateLabels(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final schedules = const DynamicEventScheduleService()
        .schedulesForYear(now.year, daysBeforeEvent: _dynamicMorePreviewDays)
        .where((item) => item.isVisibleOn(today));
    return <String, String>{
      for (final schedule in schedules)
        _normalizeTag(schedule.event.slug): _formatCategoryEventDate(schedule),
    };
  }

  String _formatCategoryEventDate(ResolvedDynamicEventSchedule schedule) {
    return _formatCategoryDateRange(schedule.startDate, schedule.endDate);
  }

  String? _categoryDateLabel(DynamicCategory category) {
    final start = category.eventStartDate;
    final end = category.eventEndDate;
    if (start == null || end == null) {
      return null;
    }
    return _shortCategoryDate(end);
  }

  String? _resolvedDynamicCategoryDateLabel(
    DynamicCategory category, {
    required DateTime now,
    required Map<String, String> eventDateLabelBySlug,
  }) {
    final signals = <String>{
      category.id,
      category.slug,
      ...category.tags,
    }.map(_normalizeTag).where((value) => value.isNotEmpty).toSet();
    return _resolvedDynamicCategoryDateLabelForSignals(
      slug: category.slug,
      tags: signals,
      now: now,
      eventDateLabelBySlug: eventDateLabelBySlug,
    );
  }

  String? _resolvedDynamicCategoryDateLabelForSignals({
    required String slug,
    required Iterable<String> tags,
    required DateTime now,
    required Map<String, String> eventDateLabelBySlug,
  }) {
    final signals = <String>{
      _normalizeTag(slug),
      ...tags.map(_normalizeTag),
    }.where((value) => value.isNotEmpty).toSet();
    for (final signal in signals) {
      final scheduleLabel = eventDateLabelBySlug[signal];
      if (scheduleLabel != null && scheduleLabel.trim().isNotEmpty) {
        return scheduleLabel;
      }
    }
    for (final category in _manualEventCategories) {
      final manualSignals = <String>{
        category.id,
        category.slug,
        ...category.tags,
      }.map(_normalizeTag).where((value) => value.isNotEmpty).toSet();
      if (signals.intersection(manualSignals).isNotEmpty) {
        final manualLabel = _categoryDateLabel(category);
        if (manualLabel != null && manualLabel.trim().isNotEmpty) {
          return manualLabel;
        }
      }
    }
    final directCategoryLabel = _categoryDateLabelForDynamicSlug(
      _normalizeTag(slug),
      now,
    );
    if (directCategoryLabel != null && directCategoryLabel.trim().isNotEmpty) {
      return directCategoryLabel;
    }
    return null;
  }

  String? _categoryDateLabelForDynamicSlug(String slug, DateTime now) {
    if (slug.isEmpty) {
      return null;
    }
    final schedules = const DynamicEventScheduleService().schedulesForYear(
      now.year,
      daysBeforeEvent: _dynamicMorePreviewDays,
    );
    for (final schedule in schedules) {
      if (_normalizeTag(schedule.event.slug) == slug &&
          _dynamicEventMatchesSelectedRegion(schedule.event)) {
        return _formatCategoryEventDate(schedule);
      }
    }
    return null;
  }

  String _formatCategoryDateRange(DateTime start, DateTime end) {
    final startLabel = _shortCategoryDate(start);
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return startLabel;
    }
    return '$startLabel-${_shortCategoryDate(end)}';
  }

  String _shortCategoryDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  List<_CategoryChipData> _buildDynamicPreviewCategoriesForMore(DateTime now) {
    final eventDateLabelBySlug = _activeDynamicEventDateLabels(now);
    return _morePopupDynamicEventCategories(now)
        .where(_hasApprovedPosterAvailabilityForDynamicCategory)
        .map((item) {
          return _CategoryChipData(
            slug: item.slug,
            label: _localizedDynamicCategoryLabelForCategory(item),
            matchTags: item.tags,
            presenceTags: _dynamicPresenceTags(item).toList(growable: false),
            isDynamic: true,
            dateLabel: _resolvedDynamicCategoryDateLabel(
              item,
              now: now,
              eventDateLabelBySlug: eventDateLabelBySlug,
            ),
          );
        })
        .toList(growable: false);
  }

  List<DynamicCategory> _morePopupDynamicEventCategories(DateTime now) {
    return _dynamicPreviewCategoryService
        .categoriesForDate(
          now,
          language: context.currentLanguage,
          selectedRegionId: _selectedRegionId,
        )
        .where((item) => item.type != DynamicCategoryType.weekdaySpecial)
        .toList(growable: false);
  }

  List<DynamicCategory> _moreCategoryAvailabilityCandidates(DateTime now) {
    return <DynamicCategory>[
      ..._morePopupDynamicEventCategories(now),
      ..._manualEventCategories,
      ..._permanentCategories,
    ];
  }

  bool _isCategoryActiveOnEventDay(DynamicCategory category, DateTime now) {
    final start = category.eventStartDate;
    final end = category.eventEndDate;
    if (start != null && end != null) {
      final today = DateTime(now.year, now.month, now.day);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);
      return !today.isBefore(startDay) && !today.isAfter(endDay);
    }
    return _isDynamicCategoryActiveOnEventDay(category, now);
  }

  bool _isDynamicCategoryActiveOnEventDay(
    DynamicCategory category,
    DateTime now,
  ) {
    final slug = _normalizeTag(category.slug);
    if (slug.isEmpty) {
      return false;
    }
    final today = DateTime(now.year, now.month, now.day);
    final schedules = const DynamicEventScheduleService().schedulesForYear(
      now.year,
      daysBeforeEvent: 0,
    );
    for (final schedule in schedules) {
      if (_normalizeTag(schedule.event.slug) != slug ||
          !_dynamicEventMatchesSelectedRegion(schedule.event)) {
        continue;
      }
      if (!today.isBefore(schedule.startDate) &&
          !today.isAfter(schedule.endDate)) {
        return true;
      }
    }
    return false;
  }

  bool _dynamicEventMatchesSelectedRegion(DynamicCalendarEvent event) {
    final regionId = _normalizeTag(_selectedRegionId);
    if (regionId.isEmpty || event.regionIds.isEmpty) {
      return true;
    }
    const teluguSharedRegionIds = <String>{'andhra_pradesh', 'telangana'};
    final selectedRegions = teluguSharedRegionIds.contains(regionId)
        ? teluguSharedRegionIds
        : <String>{regionId};
    final eventRegions = event.regionIds.map(_normalizeTag).toSet();
    return eventRegions.intersection(selectedRegions).isNotEmpty;
  }

  _CategoryChipData? _buildBonaluSharedCategory(DateTime now) {
    if (!_isTeluguSharedRegion(_selectedRegionId) ||
        !_isLunarEventActive('bonalu', now)) {
      return null;
    }
    const category = DynamicCategory(
      id: 'bonalu',
      slug: 'bonalu',
      label: 'Bonalu',
      type: DynamicCategoryType.festival,
      scope: DynamicEventScope.bothTeluguStates,
      tags: <String>[
        'bonalu',
        'festival',
        'devotional',
        'andhra_pradesh',
        'telangana',
        'regional_special',
      ],
    );
    if (!_hasApprovedPosterAvailabilityForDynamicCategory(category)) {
      return null;
    }
    return _CategoryChipData(
      slug: 'bonalu',
      label: _localizedDynamicCategoryLabel('Bonalu'),
      matchTags: category.tags,
      presenceTags: _dynamicPresenceTags(category).toList(growable: false),
      isDynamic: true,
      dateLabel: _activeDynamicEventDateLabels(now)['bonalu'],
    );
  }

  bool _isTeluguSharedRegion(String regionId) {
    final selectedRegion = _normalizeTag(regionId);
    return selectedRegion == 'andhra_pradesh' || selectedRegion == 'telangana';
  }

  bool _isLunarEventActive(String slug, DateTime now) {
    final resolved = resolvedLunarEventDatesForYear(now.year)[slug];
    if (resolved == null) {
      return false;
    }
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(now.year, resolved.month, resolved.day);
    final endDate = switch ((resolved.endMonth, resolved.endDay)) {
      (final int endMonth, final int endDay) => DateTime(
        now.year,
        endMonth,
        endDay,
      ),
      _ => startDate.add(Duration(days: resolved.durationDays - 1)),
    };
    return !today.isBefore(startDate) && !today.isAfter(endDate);
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
      if (!_isCategoryActiveOnEventDay(item, IstTimeService.now())) {
        return false;
      }
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
    final now = IstTimeService.now();
    final eventDateLabelBySlug = _activeDynamicEventDateLabels(now);
    return mergedCategories
        .where((item) => _isCategoryActiveOnEventDay(item, now))
        .map((item) {
          return _CategoryChipData(
            slug: item.slug,
            label: _localizedDynamicCategoryLabelForCategory(item),
            matchTags: item.tags,
            presenceTags: _dynamicPresenceTags(item).toList(growable: false),
            isDynamic: true,
            dateLabel: _resolvedDynamicCategoryDateLabel(
              item,
              now: now,
              eventDateLabelBySlug: eventDateLabelBySlug,
            ),
          );
        })
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
      _dynamicCategoryAvailabilityFutureBySlug.clear();
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
    if (!_shouldRunRemoteHomeStartupTasks) {
      return;
    }
    final slug = _normalizeTag(category.slug);
    if (slug.isEmpty) {
      return;
    }
    final existing = _dynamicCategoryAvailabilityFutureBySlug[slug];
    if (existing != null) {
      return existing;
    }
    final future = _runDynamicCategoryAvailabilityCheck(category, slug);
    _dynamicCategoryAvailabilityFutureBySlug[slug] = future;
    return future;
  }

  Future<void> _runDynamicCategoryAvailabilityCheck(
    DynamicCategory category,
    String slug,
  ) async {
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
        _categoryListCache = null;
        _categoryListIdentity = null;
        if (_moreCategorySheetOpen) {
          _categoryAvailabilityChangedWhileMoreSheetOpen = true;
        } else {
          setState(() {});
        }
      }
    } catch (_) {
      if (mounted) {
        _dynamicCategoryAvailabilityBySlug[slug] = false;
      }
    } finally {
      _dynamicCategoryAvailabilityInFlight.remove(slug);
      _dynamicCategoryAvailabilityFutureBySlug.remove(slug);
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
    final normalizedSelectionSlug = _normalizeTag(
      category.effectiveSelectionSlug,
    );
    final normalizedSlug = _normalizeTag(category.slug);
    final weekdaySlug = normalizedSelectionSlug.isNotEmpty
        ? normalizedSelectionSlug
        : normalizedSlug;
    if (weekdaySlug.isEmpty) {
      return const <String>{};
    }
    if (_isWeekdaySpecialCategorySlug(weekdaySlug)) {
      return <String>{weekdaySlug};
    }
    const broadDynamicTags = <String>{
      'festival',
      'festivals',
      'jayanthi',
      'jayanthulu',
      'vardhanthi',
      'vardhanthulu',
      'birthday',
      'birthdays',
      'important_day',
      'special_day',
      'regional_special',
      'weekday_special',
    };
    final output = <String>{};

    void addValue(String raw) {
      final normalized = _normalizeTag(raw);
      if (normalized.isEmpty || broadDynamicTags.contains(normalized)) {
        return;
      }
      output.add(normalized);
      output.addAll(
        _expandCategoryAliases(
          normalized,
        ).where((alias) => !broadDynamicTags.contains(alias)),
      );
    }

    addValue(category.effectiveSelectionSlug);
    addValue(category.slug);
    addValue(category.label);
    for (final tag in category.presenceTags) {
      addValue(tag);
    }
    for (final tag in category.matchTags) {
      addValue(tag);
    }
    return output;
  }

  bool _isWeekdaySpecialCategorySlug(String slug) {
    return slug.startsWith('weekday_') &&
        slug.endsWith('_special') &&
        slug != 'weekday_special';
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

  bool _hasApprovedPosterAvailabilityForDynamicCategory(
    DynamicCategory category,
  ) {
    final slug = _normalizeTag(category.slug);
    if (slug.isEmpty) {
      return false;
    }
    return _hasVisibleTemplateForCategoryChip(category) ||
        _dynamicCategoryAvailabilityBySlug[slug] == true;
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
    final categories = _allStaticCategories();
    final selectedMoreSlug = _selectedMoreCategorySlug;
    final selectedMoreCategory = selectedMoreSlug == null
        ? null
        : (_selectedMoreCategoryChip?.slug == selectedMoreSlug
              ? _selectedMoreCategoryChip
              : _morePopupCategoryForSlug(selectedMoreSlug));
    final selectedMoreSlotCategory = selectedMoreCategory == null
        ? null
        : _CategoryChipData(
            slug: _selectedMoreCategorySlotSlug,
            label: selectedMoreCategory.label,
            matchTags: selectedMoreCategory.matchTags,
            presenceTags: selectedMoreCategory.presenceTags,
            isDynamic: selectedMoreCategory.isDynamic,
            iconAssetPath: selectedMoreCategory.iconAssetPath,
            dateLabel: selectedMoreCategory.dateLabel,
            selectionSlug: selectedMoreCategory.slug,
          );
    final visibleCategories = <_CategoryChipData>[];
    for (final category in categories) {
      if (_morePopupCategorySlugs.contains(category.slug)) {
        continue;
      }
      if (category.slug == _moreCategorySlug &&
          selectedMoreSlotCategory != null) {
        visibleCategories.add(selectedMoreSlotCategory);
      }
      visibleCategories.add(category);
    }
    return visibleCategories;
  }

  List<_CategoryChipData> _allStaticCategories() {
    final labels = context.strings.localizedHomeCategories();
    return List<_CategoryChipData>.generate(labels.length, (int index) {
      final slug = index < _staticCategorySlugs.length
          ? _staticCategorySlugs[index]
          : 'category_$index';
      return _CategoryChipData(
        slug: slug,
        label: _localizedCategoryLabel(slug, labels[index]),
        matchTags: _defaultCategoryTagsForSlug(slug),
      );
    }, growable: false);
  }

  String _localizedCategoryLabel(String slug, String fallbackLabel) {
    return switch (slug) {
      'good_evening' => ScriptLocalizationService.localizeCategoryLabel(
        'Good Evening',
        context.currentLanguage,
      ),
      _ => fallbackLabel,
    };
  }

  String _localizedDynamicCategoryLabel(String label) {
    return ScriptLocalizationService.localizeCategoryLabel(
      label,
      context.currentLanguage,
    );
  }

  String _localizedDynamicCategoryLabelForSlug(String slug, String label) {
    final language = context.currentLanguage;
    final rawLabel = label.trim();
    final shouldUseTeluguLabel =
        language.supportedUiLanguage == SupportedUiLanguage.telugu ||
        context.strings.localizedHomeCategories().any(_containsTeluguScript);
    if (shouldUseTeluguLabel && !_containsTeluguScript(rawLabel)) {
      final teluguOverride = _teluguDynamicCategoryLabelOverride(slug);
      if (teluguOverride != null) {
        return teluguOverride;
      }
    }
    return _localizedDynamicCategoryLabel(
      rawLabel.isNotEmpty ? rawLabel : slug,
    );
  }

  String _localizedDynamicCategoryLabelForCategory(DynamicCategory category) {
    final language = context.currentLanguage;
    final rawLabel = category.label.trim();
    final shouldUseTeluguLabel =
        language.supportedUiLanguage == SupportedUiLanguage.telugu ||
        context.strings.localizedHomeCategories().any(_containsTeluguScript);
    if (shouldUseTeluguLabel && !_containsTeluguScript(rawLabel)) {
      final teluguOverride = _teluguDynamicCategoryLabelOverride(category.slug);
      if (teluguOverride != null) {
        return teluguOverride;
      }
      for (final localized in _dynamicCategoryService.categoriesForSlugs(
        <String>[category.slug],
        language: AppLanguage.telugu,
      )) {
        if (_normalizeTag(localized.slug) == _normalizeTag(category.slug) &&
            _containsTeluguScript(localized.label)) {
          return localized.label;
        }
      }
    }
    return _localizedDynamicCategoryLabel(
      rawLabel.isNotEmpty ? rawLabel : category.slug,
    );
  }

  bool _containsTeluguScript(String value) =>
      RegExp(r'[\u0C00-\u0C7F]').hasMatch(value);

  String? _teluguDynamicCategoryLabelOverride(String slug) {
    return switch (_normalizeTag(slug)) {
      'gurram_jashuva_jayanthi' =>
        'à°—à±à°°à±à°°à°‚ à°œà°¾à°·à±à°µà°¾ à°œà°¯à°‚à°¤à°¿',
      'gurram_jashuva_vardhanthi' =>
        'à°—à±à°°à±à°°à°‚ à°œà°¾à°·à±à°µà°¾ à°µà°°à±à°§à°‚à°¤à°¿',
      _ => null,
    };
  }

  List<_CategoryChipData> _morePopupCategories({
    bool scheduleAvailabilityChecks = true,
  }) {
    final bySlug = <String, _CategoryChipData>{};

    void addCategory(_CategoryChipData category) {
      final slug = _normalizeTag(category.slug);
      if (slug.isEmpty || slug == _moreCategorySlug) {
        return;
      }
      bySlug.putIfAbsent(category.slug, () => category);
    }

    final staticCategories = _allStaticCategories();
    for (final slug in _morePopupCategorySlugs) {
      for (final category in staticCategories) {
        if (category.slug == slug) {
          addCategory(category);
          break;
        }
      }
    }
    final now = IstTimeService.now();
    final availabilityCandidates = _moreCategoryAvailabilityCandidates(now);
    if (scheduleAvailabilityChecks) {
      _scheduleDynamicCategoryAvailabilityChecks(availabilityCandidates);
    }
    for (final category in _buildDynamicPreviewCategoriesForMore(now)) {
      addCategory(category);
    }
    for (final category in _manualEventCategories) {
      if (_hasApprovedPosterAvailabilityForDynamicCategory(category)) {
        addCategory(_categoryChipFromDynamicCategory(category));
      }
    }
    for (final category in _permanentCategories) {
      if (_hasApprovedPosterAvailabilityForDynamicCategory(category)) {
        addCategory(_categoryChipFromDynamicCategory(category));
      }
    }
    return bySlug.values.toList(growable: false);
  }

  _CategoryChipData? _morePopupCategoryForSlug(String slug) {
    for (final category in _morePopupCategories()) {
      if (category.slug == slug) {
        return category;
      }
    }
    return null;
  }

  Future<void> _refreshMoreCategoryAvailabilityBeforeOpeningSheet() async {
    if (!_shouldRunRemoteHomeStartupTasks) {
      return;
    }
    final candidates = _moreCategoryAvailabilityCandidates(
      IstTimeService.now(),
    );
    final pending = <DynamicCategory>[];
    final futures = <Future<void>>[];
    final seenSlugs = <String>{};
    for (final category in candidates) {
      final slug = _normalizeTag(category.slug);
      if (slug.isEmpty ||
          !seenSlugs.add(slug) ||
          _hasVisibleTemplateForCategoryChip(category)) {
        continue;
      }
      final existing = _dynamicCategoryAvailabilityFutureBySlug[slug];
      if (existing != null) {
        futures.add(existing);
        continue;
      }
      pending.add(category);
    }
    futures.addAll(pending.map(_checkDynamicCategoryAvailability));
    if (futures.isEmpty) {
      return;
    }
    try {
      await Future.wait(futures).timeout(const Duration(seconds: 9));
    } on TimeoutException {
      // Open with the availability that has completed instead of blocking UI.
    }
  }

  _CategoryChipData _categoryChipFromDynamicCategory(DynamicCategory category) {
    final now = IstTimeService.now();
    final eventDateLabelBySlug = _activeDynamicEventDateLabels(now);
    return _CategoryChipData(
      slug: category.slug,
      label: ScriptLocalizationService.localizeCategoryLabel(
        category.label,
        context.currentLanguage,
      ),
      matchTags: category.tags,
      presenceTags: _dynamicPresenceTags(category).toList(growable: false),
      isDynamic: true,
      iconAssetPath: category.iconAssetPath,
      dateLabel: _resolvedDynamicCategoryDateLabel(
        category,
        now: now,
        eventDateLabelBySlug: eventDateLabelBySlug,
      ),
    );
  }

  List<_CategoryChipData> _buildSelectedPartyCategories(AppLanguage language) {
    final selectedPartyId = _selectedPoliticalPartyId();
    if (selectedPartyId == null) {
      return const <_CategoryChipData>[];
    }
    final knownParties = politicalParties
        .where((party) => party.id == selectedPartyId)
        .toList(growable: false);
    final knownPartyIds = knownParties.map((party) => party.id).toSet();
    final unknownPartyIds = knownPartyIds.isEmpty
        ? <String>[selectedPartyId]
        : <String>[];

    return <_CategoryChipData>[
      for (final party in knownParties)
        _CategoryChipData(
          slug: 'party_${party.id}',
          label: party.nameFor(language),
          iconAssetPath: party.logoAssetPath,
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

  String? _selectedPoliticalPartyId() {
    if (_selectedPoliticalPartyIds.isEmpty) {
      return null;
    }
    for (final party in politicalParties) {
      if (_selectedPoliticalPartyIds.contains(party.id)) {
        return party.id;
      }
    }
    final sortedIds = _selectedPoliticalPartyIds.toList()..sort();
    return sortedIds.first;
  }

  List<_CategoryChipData> _mergeCategories(
    List<_CategoryChipData> staticCategories,
    List<_CategoryChipData> dynamicCategories,
    List<_CategoryChipData> partyCategories,
  ) {
    final merged = <_CategoryChipData>[];
    final allowedSlugs = _filterCategoriesByReligion(<_CategoryChipData>[
      ...staticCategories,
      ...dynamicCategories,
      ...partyCategories,
      _politicalCategoryChip(),
    ]).map((chip) => _normalizeTag(chip.slug)).toSet();
    final seenSlugs = <String>{};
    final seenSelectionSlugs = <String>{};

    void addChip(_CategoryChipData chip) {
      final slug = _normalizeTag(chip.slug);
      final selectionSlug = _normalizeTag(chip.effectiveSelectionSlug);
      if (slug.isEmpty ||
          !allowedSlugs.contains(slug) ||
          _morePopupCategorySlugs.contains(slug) ||
          !seenSlugs.add(slug) ||
          !seenSelectionSlugs.add(selectionSlug)) {
        return;
      }
      if (chip.slug == _selectedMoreCategorySlotSlug) {
        final selectedMoreSlug = _normalizeTag(_selectedMoreCategorySlug ?? '');
        if (selectedMoreSlug.isNotEmpty) {
          seenSlugs.add(selectedMoreSlug);
        }
      }
      merged.add(chip);
    }

    if (staticCategories.isNotEmpty) {
      addChip(staticCategories.first);
    } else {
      addChip(_allCategoryChip());
    }

    addChip(_politicalCategoryChip());
    for (final chip in partyCategories) {
      addChip(chip);
    }
    final selectedMoreSlug = _selectedMoreCategorySlug;
    for (final chip in staticCategories.skip(1)) {
      if (selectedMoreSlug != null &&
          chip.effectiveSelectionSlug == selectedMoreSlug) {
        addChip(chip);
      }
    }
    for (final chip in dynamicCategories) {
      addChip(chip);
    }
    for (final chip in staticCategories.skip(1)) {
      if (selectedMoreSlug != null &&
          chip.effectiveSelectionSlug == selectedMoreSlug) {
        continue;
      }
      addChip(chip);
    }

    return merged;
  }

  _CategoryChipData _allCategoryChip() {
    return _CategoryChipData(
      slug: _allCategorySlug,
      label: context.strings.localized(
        telugu: 'à°…à°¨à±à°¨à±€',
        english: 'All',
      ),
      matchTags: const <String>['all'],
    );
  }

  _CategoryChipData _politicalCategoryChip() {
    return _CategoryChipData(
      slug: _politicalCategorySlug,
      label: ScriptLocalizationService.localizeCategoryLabel(
        'Political',
        context.currentLanguage,
      ),
      matchTags: const <String>['political', 'politics'],
    );
  }

  List<String> _defaultCategoryTagsForSlug(String slug) {
    return switch (slug) {
      _allCategorySlug => const <String>['all'],
      'good_morning' => const <String>['good_morning', 'morning'],
      'good_afternoon' => const <String>['good_afternoon', 'afternoon'],
      'good_night' => const <String>['good_night', 'night'],
      'motivational' => const <String>['motivational'],
      'good_evening' => const <String>['good_evening', 'evening'],
      'today_special' => const <String>['today_special'],
      'birthdays' => const <String>['birthdays', 'birthday'],
      'life_advice' => const <String>['life_advice'],
      'gita_wisdom' => const <String>['gita_wisdom'],
      'devotional' => const <String>['devotional'],
      'mahabharata' => const <String>['mahabharata'],
      'anniversary' => const <String>['anniversary'],
      'good_thoughts' => const <String>['good_thoughts'],
      'bible' => const <String>['bible'],
      'islam' => const <String>['islam'],
      'jokes' => const <String>['jokes', 'funny', 'humor', 'comedy'],
      'new' => const <String>['new', 'more', 'latest'],
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
      'good_evening': <String>['good_evening', 'evening'],
      'good_night': <String>['good_night', 'night'],
      'motivational': <String>['motivational'],
      'today_special': <String>['today_special'],
      'birthdays': <String>['birthdays', 'birthday'],
      'life_advice': <String>['life_advice'],
      'gita_wisdom': <String>['gita_wisdom'],
      'devotional': <String>['devotional'],
      'mahabharata': <String>['mahabharata'],
      'anniversary': <String>['anniversary'],
      'good_thoughts': <String>['good_thoughts'],
      'bible': <String>['bible'],
      'islam': <String>['islam'],
      'new': <String>['new'],
      'weekday_special': <String>['weekday_special'],
      'important_day': <String>['important_day'],
      'regional_special': <String>['regional_special'],
      'festival': <String>['festival'],
      'jayanthi': <String>['jayanthi'],
      'vardhanthi': <String>['vardhanthi'],
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
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(
        AppSnackBar.build(
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
      'photoAnimation': config.photoAnimation,
      'showVideoExtraPhoto': config.showVideoExtraPhoto,
      'videoExtraPhotoShape': config.videoExtraPhotoShape,
      'videoExtraPhotoRenderMode': config.videoExtraPhotoRenderMode,
      'videoExtraPhotoEdgeStyle': config.videoExtraPhotoEdgeStyle,
      'videoExtraPhotoAnimation': config.videoExtraPhotoAnimation,
      'videoExtraPhotoX': config.videoExtraPhotoX,
      'videoExtraPhotoY': config.videoExtraPhotoY,
      'videoExtraPhotoScale': config.videoExtraPhotoScale,
      'nameX': config.nameX,
      'nameY': config.nameY,
      'showBottomStrip': config.showBottomStrip,
      'stripHeight': config.stripHeight,
      'stripWidth': config.stripWidth,
      'stripX': config.stripX,
      'stripBottom': config.stripBottom,
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
      'showPoliticalProtocol': config.showPoliticalProtocol,
      'politicalProtocolEnabledAtMillis':
          config.politicalProtocolEnabledAtMillis,
      'politicalProtocolX': config.politicalProtocolX,
      'politicalProtocolY': config.politicalProtocolY,
      'politicalProtocolScale': config.politicalProtocolScale,
      'politicalProtocolSlots': config.politicalProtocolSlots
          .map((slot) => slot.toJson())
          .toList(growable: false),
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
      photoAnimation: _normalizeVideoPhotoAnimation(
        data['photoAnimation'] as String?,
      ),
      showVideoExtraPhoto: data['showVideoExtraPhoto'] as bool? ?? false,
      videoExtraPhotoShape:
          (data['videoExtraPhotoShape'] as String?)?.trim() ?? 'circle',
      videoExtraPhotoRenderMode:
          (data['videoExtraPhotoRenderMode'] as String?)?.trim() ?? 'cutout',
      videoExtraPhotoEdgeStyle:
          (data['videoExtraPhotoEdgeStyle'] as String?)?.trim() ?? 'soft_fade',
      videoExtraPhotoAnimation: _normalizeVideoPhotoAnimation(
        data['videoExtraPhotoAnimation'] as String?,
      ),
      videoExtraPhotoX: (data['videoExtraPhotoX'] as num?)?.toDouble() ?? 24,
      videoExtraPhotoY: (data['videoExtraPhotoY'] as num?)?.toDouble() ?? 44,
      videoExtraPhotoScale:
          (data['videoExtraPhotoScale'] as num?)?.toDouble() ?? 28,
      nameX: (data['nameX'] as num?)?.toDouble() ?? 50,
      nameY: (data['nameY'] as num?)?.toDouble() ?? 82,
      showBottomStrip: data['showBottomStrip'] as bool? ?? true,
      stripHeight: (data['stripHeight'] as num?)?.toDouble() ?? 16,
      stripWidth: (data['stripWidth'] as num?)?.toDouble() ?? 100,
      stripX: (data['stripX'] as num?)?.toDouble() ?? 50,
      stripBottom: (data['stripBottom'] as num?)?.toDouble() ?? 0,
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
      showPoliticalProtocol: data['showPoliticalProtocol'] as bool? ?? false,
      politicalProtocolEnabledAtMillis:
          (data['politicalProtocolEnabledAtMillis'] as num?)?.toInt() ?? 0,
      politicalProtocolX:
          (data['politicalProtocolX'] as num?)?.toDouble() ?? 50,
      politicalProtocolY: (data['politicalProtocolY'] as num?)?.toDouble() ?? 7,
      politicalProtocolScale:
          (data['politicalProtocolScale'] as num?)?.toDouble() ?? 85,
      politicalProtocolSlots: _deserializePoliticalProtocolSlots(
        data['politicalProtocolSlots'],
        fallbackX: (data['politicalProtocolX'] as num?)?.toDouble() ?? 50,
        fallbackY: (data['politicalProtocolY'] as num?)?.toDouble() ?? 7,
        fallbackScale:
            (data['politicalProtocolScale'] as num?)?.toDouble() ?? 85,
      ),
    );
  }

  List<PoliticalProtocolSlot> _deserializePoliticalProtocolSlots(
    Object? raw, {
    required double fallbackX,
    required double fallbackY,
    required double fallbackScale,
  }) {
    if (raw is List) {
      final slots = raw
          .whereType<Map>()
          .map(
            (slot) => PoliticalProtocolSlot(
              x: ((slot['x'] as num?)?.toDouble() ?? 50)
                  .clamp(4.0, 96.0)
                  .toDouble(),
              y: ((slot['y'] as num?)?.toDouble() ?? 8)
                  .clamp(4.0, 96.0)
                  .toDouble(),
              scale: ((slot['scale'] as num?)?.toDouble() ?? 100)
                  .clamp(45.0, 135.0)
                  .toDouble(),
            ),
          )
          .take(defaultPoliticalProtocolSlots.length)
          .toList(growable: false);
      if (slots.length == defaultPoliticalProtocolSlots.length) {
        return slots;
      }
    }
    final spacing = 44.0 * (fallbackScale.clamp(55.0, 135.0) / 100);
    return List<PoliticalProtocolSlot>.generate(
      defaultPoliticalProtocolSlots.length,
      (index) {
        final x =
            fallbackX +
            ((index - ((defaultPoliticalProtocolSlots.length - 1) / 2)) *
                spacing);
        return PoliticalProtocolSlot(
          x: x.clamp(4.0, 96.0).toDouble(),
          y: fallbackY.clamp(4.0, 96.0).toDouble(),
          scale: fallbackScale.clamp(45.0, 135.0).toDouble(),
        );
      },
      growable: false,
    );
  }

  String _normalizeVideoPhotoAnimation(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'top_to_place':
      case 'bottom_to_place':
      case 'left_to_place':
      case 'right_to_place':
      case 'zoom_in':
      case 'zoom_out':
        return raw!.trim().toLowerCase();
      default:
        return 'none';
    }
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
      'creatorPublicId': item.creatorPublicId,
      'pageConfig': _serializePageConfig(item.pageConfig),
      'personalizationConfig': _serializePersonalization(
        item.personalizationConfig,
      ),
      'preferOriginalPosterQuality': item.preferOriginalPosterQuality,
    };
  }

  _TemplateItem? _deserializeTemplateSnapshotItem(Map<String, dynamic> data) {
    final titleEn = (data['titleEn'] as String?)?.trim() ?? '';
    if (titleEn.isEmpty) {
      return null;
    }
    final imageUrl = (data['imageUrl'] as String?)?.trim();
    final imageStoragePath = (data['imageStoragePath'] as String?)?.trim();
    final imageAssetPath = (data['imageAssetPath'] as String?)?.trim();
    final templateId = (data['templateId'] as String?)?.trim();
    final templateDocumentSource = (data['templateDocumentSource'] as String?)
        ?.trim();
    final pageConfig = _deserializePageConfig(
      (data['pageConfig'] as Map?)?.cast<String, dynamic>(),
    );
    final personalizationConfig = _deserializePersonalization(
      (data['personalizationConfig'] as Map?)?.cast<String, dynamic>(),
    );
    final isRemotePortalPoster =
        (imageAssetPath == null || imageAssetPath.isEmpty) &&
        ((templateId?.isNotEmpty ?? false) ||
            (templateDocumentSource?.isNotEmpty ?? false) ||
            pageConfig != null ||
            personalizationConfig != null) &&
        ((imageUrl?.isNotEmpty ?? false) ||
            (imageStoragePath?.isNotEmpty ?? false));
    return _TemplateItem(
      titleTe: (data['titleTe'] as String?) ?? titleEn,
      titleHi: (data['titleHi'] as String?) ?? titleEn,
      titleEn: titleEn,
      imageUrl: imageUrl,
      imageStoragePath: imageStoragePath,
      thumbnailStoragePath: (data['thumbnailStoragePath'] as String?)?.trim(),
      thumbnailUrl: (data['thumbnailUrl'] as String?)?.trim(),
      mediaType: (data['mediaType'] as String?)?.trim() ?? 'image',
      videoUrl: (data['videoUrl'] as String?)?.trim(),
      imageAssetPath: imageAssetPath,
      price: (data['price'] as num?)?.toInt(),
      templateId: templateId,
      templateDocumentSource: templateDocumentSource,
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
      creatorPublicId: (data['creatorPublicId'] as String?)?.trim(),
      pageConfig: pageConfig,
      personalizationConfig: personalizationConfig,
      preferOriginalPosterQuality:
          (data['preferOriginalPosterQuality'] as bool?) ??
          isRemotePortalPoster,
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
      if (_selectedCategorySlug == _allCategorySlug &&
          _lockedAllFeedTemplates == null &&
          templates.length >= _startupMinimumScrollableTemplateCount) {
        _lockedAllFeedTemplates = List<_TemplateItem>.of(templates);
      }
      _rankedAllFeedTemplates = null;
      _allFeedRankingReady = false;
      _startupSnapshotHydrationDeferred = false;
      _templatesLoading = false;
      _templatesHasMore = hasMore;
      _templatesLastDocument = lastDocument;
      _allTemplatesWindowExhausted = false;
      _allTemplatesWindowLimit = math.max(
        _allTemplatesWindowPageSize,
        templates.length,
      );
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
    _scheduleStartupFeedImageWarmup(templates);
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

  void _scheduleStartupFeedImageWarmup(List<_TemplateItem> templates) {
    final urls = templates
        .where((item) => !item.isVideo)
        .map((item) {
          final thumb = (item.thumbnailUrl ?? '').trim();
          if (_posterStringLooksHttpUrl(thumb)) {
            return thumb;
          }
          final image = (item.imageUrl ?? '').trim();
          return _posterStringLooksHttpUrl(image) ? image : '';
        })
        .where((url) => url.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (urls.isEmpty) {
      return;
    }
    final signature = urls.join('|');
    if (_startupFeedWarmupSignature == signature) {
      return;
    }
    _startupFeedWarmupSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted) {
          return;
        }
        for (final url in urls) {
          if (!mounted) {
            return;
          }
          try {
            final provider = ResizeImage.resizeIfNeeded(
              960,
              null,
              CachedNetworkImageProvider(
                url,
                cacheManager: PosterNetworkImageCache.instance,
                maxWidth: PosterNetworkImageLimits.diskFeedMaxWidth,
                maxHeight: PosterNetworkImageLimits.diskFeedMaxHeight,
              ),
            );
            await precacheImage(
              provider,
              context,
            ).timeout(const Duration(milliseconds: 900));
          } catch (error, stackTrace) {
            _homeDebugLogStack(
              'startup feed image warmup skipped: $error',
              stackTrace,
            );
          }
        }
      }());
    });
  }

  void _scheduleStartupRichPosterPreviewActivation({
    Duration initialDelay = const Duration(milliseconds: 2200),
  }) {}

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
    if (!_shouldRunRemoteHomeStartupTasks) {
      return;
    }
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
    if (!_shouldRunRemoteHomeStartupTasks) {
      return;
    }
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

  Future<ApprovedCreatorTemplatePage> _startupTemplatePageWithTimeout(
    Future<ApprovedCreatorTemplatePage> future, {
    required String phase,
  }) async {
    try {
      return await future.timeout(_homeStartupRemoteTimeout);
    } catch (error, stackTrace) {
      _homeDebugLogStack(
        'home template $phase timed out/failed: $error',
        stackTrace,
      );
      return const ApprovedCreatorTemplatePage(
        templates: <ApprovedCreatorTemplate>[],
        lastDocument: null,
        hasMore: false,
      );
    }
  }

  Future<List<ApprovedCreatorTemplate>> _startupTemplateListWithTimeout(
    Future<List<ApprovedCreatorTemplate>> future, {
    required String phase,
  }) async {
    try {
      return await future.timeout(_homeStartupRemoteTimeout);
    } catch (error, stackTrace) {
      _homeDebugLogStack(
        'home template $phase timed out/failed: $error',
        stackTrace,
      );
      return const <ApprovedCreatorTemplate>[];
    }
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
    final startupGenericRemoteFuture = _startupTemplatePageWithTimeout(
      shouldUseSlotAwareStartupFetch
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
            ),
      phase: 'generic_startup',
    );
    final startupSecondaryFuture = shouldUseSlotAwareStartupFetch
        ? (startupSecondaryTag == null
              ? Future<List<ApprovedCreatorTemplate>>.value(
                  const <ApprovedCreatorTemplate>[],
                )
              : _startupTemplateListWithTimeout(
                  _approvedCreatorTemplateService
                      .fetchAllApprovedTemplatesForCategory(
                        categoryId: startupSecondaryTag,
                        source: Source.serverAndCache,
                        scanLimit: _initialPrioritySecondaryFetchSize,
                      ),
                  phase: 'secondary_startup',
                ))
        : null;
    final startupPrimaryFuture = shouldUseSlotAwareStartupFetch
        ? (startupPrimaryTag == null
              ? startupGenericRemoteFuture.then((page) => page.templates)
              : _startupTemplateListWithTimeout(
                  _approvedCreatorTemplateService
                      .fetchAllApprovedTemplatesForCategory(
                        categoryId: startupPrimaryTag,
                        source: Source.serverAndCache,
                        scanLimit: _initialPriorityPrimaryFetchSize,
                      ),
                  phase: 'primary_startup',
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
        var firstPaintItems = prioritizedPrimaryItems;
        var firstPaintHasMore = true;
        QueryDocumentSnapshot<Map<String, dynamic>>? firstPaintLastDocument;
        var firstPaintGenericCount = 0;
        if (firstPaintItems.length < _startupMinimumScrollableTemplateCount) {
          try {
            final genericPage = await startupGenericRemoteFuture.timeout(
              _startupGenericFirstPaintMergeTimeout,
            );
            if (!mounted) {
              return;
            }
            final genericItems = await _mapTemplatesOffMain(
              genericPage.templates,
              phase: 'generic_first_paint',
            );
            if (!mounted) {
              return;
            }
            if (genericItems.isNotEmpty) {
              firstPaintItems = await _mergeTemplateListsOffMain(
                <List<_TemplateItem>>[prioritizedPrimaryItems, genericItems],
                phase: 'primary_generic_first_paint_merge',
              );
              if (!mounted) {
                return;
              }
              firstPaintHasMore =
                  genericPage.hasMore && genericPage.lastDocument != null;
              firstPaintLastDocument = genericPage.lastDocument;
              firstPaintGenericCount = genericItems.length;
              _homeDebugLog(
                '[StartupTiming] generic_first_paint_merge '
                't=${_startupStopwatch.elapsedMilliseconds}ms '
                'primary=${prioritizedPrimaryItems.length} '
                'generic=${genericItems.length} merged=${firstPaintItems.length} '
                'hasMore=$firstPaintHasMore',
              );
            }
          } catch (error) {
            _homeDebugLog(
              '[StartupTiming] generic_first_paint_merge_skipped '
              't=${_startupStopwatch.elapsedMilliseconds}ms '
              'primary=${prioritizedPrimaryItems.length} error=$error',
            );
          }
        }
        final visiblePrimaryCount = math.min(
          _startupInitialVisibleTemplateCount,
          firstPaintItems.length,
        );
        final initialVisiblePrimaryItems = firstPaintItems
            .take(visiblePrimaryCount)
            .toList(growable: false);
        final deferredPrimaryItems =
            firstPaintItems.length > visiblePrimaryCount
            ? firstPaintItems.sublist(visiblePrimaryCount)
            : const <_TemplateItem>[];
        if (startupFeedAlreadyVisible) {
          unawaited(
            _completeStartupSecondaryHydration(
              deferredPrimaryItems: firstPaintItems,
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
          hasMore: firstPaintHasMore,
          lastDocument: firstPaintLastDocument,
          phase: 'primary_ready',
          logFirstRemotePaint: true,
          primaryCount: initialVisiblePrimaryItems.length,
          genericCount: firstPaintGenericCount,
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
        final retryPage = await _startupTemplatePageWithTimeout(
          _approvedCreatorTemplateService.fetchApprovedTemplatesPage(
            pageSize: _templatesPageSize,
            source: Source.server,
          ),
          phase: 'retry_startup',
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
      final sameTargetRegionIds =
          a.targetRegionIds.length == b.targetRegionIds.length &&
          a.targetRegionIds.every(b.targetRegionIds.contains);
      if (a.id != b.id ||
          a.imageUrl != b.imageUrl ||
          a.sortOrder != b.sortOrder ||
          a.active != b.active ||
          a.title != b.title ||
          a.subtitle != b.subtitle ||
          a.ctaLabel != b.ctaLabel ||
          a.ctaTarget != b.ctaTarget ||
          a.placement != b.placement ||
          !sameTargetRegionIds ||
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
    if (_templatesLoading || _templatesLoadingMore) {
      return false;
    }
    if (!_templatesHasMore || _templatesLastDocument == null) {
      return _loadMoreApprovedCreatorTemplatesWindow();
    }
    final startAfterDocument = _templatesLastDocument;
    setState(() => _templatesLoadingMore = true);
    try {
      final page = await _approvedCreatorTemplateService
          .fetchApprovedTemplatesPage(
            pageSize: _templatesPageSize,
            startAfterDocument: startAfterDocument,
            source: Source.server,
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
      final effectiveHasMore = page.hasMore && page.lastDocument != null;
      if (freshCount == 0 && !effectiveHasMore) {
        setState(() {
          _templatesLoadingMore = false;
          _templatesHasMore = false;
          _templatesLastDocument = page.lastDocument;
        });
        return _loadMoreApprovedCreatorTemplatesWindow();
      }
      if (kDebugMode) {
        final droppedByDedupe = mapped.length - freshCount;
        _homeDebugLog(
          '[PosterUI] loadMore pageMapped=${mapped.length} fresh=$freshCount '
          'droppedByDedupe=$droppedByDedupe '
          'remoteBefore=${_remoteApprovedTemplates.length} hasMore=${page.hasMore} '
          'cursorBootstrap=${startAfterDocument == null} effectiveHasMore=$effectiveHasMore',
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
        _templatesHasMore = effectiveHasMore;
        _templatesLastDocument = page.lastDocument;
        _allTemplatesWindowLimit = math.max(
          _allTemplatesWindowLimit,
          merged.length,
        );
      });
      _templateProjectionCache = null;
      _templateProjectionIdentity = null;
      _scheduleDeferredAllFeedRanking();
      if (!effectiveHasMore && freshCount < _templatesPageSize) {
        unawaited(_loadMoreApprovedCreatorTemplatesWindow());
      }
      return freshCount > 0 || effectiveHasMore;
    } catch (error, stackTrace) {
      _homeDebugLogStack('loadMore failed: $error', stackTrace);
      if (mounted) {
        setState(() => _templatesLoadingMore = false);
      }
      return _loadMoreApprovedCreatorTemplatesWindow();
    }
  }

  Future<bool> _loadMoreApprovedCreatorTemplatesWindow() async {
    if (_templatesLoading ||
        _templatesLoadingMore ||
        _allTemplatesWindowExhausted) {
      return false;
    }
    final nextLimit = math.max(
      _allTemplatesWindowLimit + _allTemplatesWindowPageSize,
      _remoteApprovedTemplates.length + _allTemplatesWindowPageSize,
    );
    _allTemplatesWindowLimit = nextLimit;
    setState(() => _templatesLoadingMore = true);
    try {
      final templates = await _approvedCreatorTemplateService
          .fetchApprovedTemplatesWindow(
            scanLimit: nextLimit,
            source: Source.server,
          );
      if (!mounted) {
        return false;
      }
      final mapped = await _mapTemplatesOffMain(
        templates,
        phase: 'load_more_window',
      );
      if (!mounted) {
        return false;
      }
      final lockedMerged = await _extendLockedAllFeedTemplates(
        mapped,
        phase: 'load_more_window',
      );
      if (!mounted) {
        return false;
      }
      final merged = await _mergeTemplateListsOffMain(<List<_TemplateItem>>[
        _remoteApprovedTemplates,
        mapped,
      ], phase: 'load_more_window_merge');
      if (!mounted) {
        return false;
      }
      final freshCount = math.max(
        merged.length - _remoteApprovedTemplates.length,
        0,
      );
      final exhausted = mapped.length < nextLimit || freshCount == 0;
      if (kDebugMode) {
        final droppedByDedupe = mapped.length - freshCount;
        _homeDebugLog(
          '[PosterUI] loadMoreWindow limit=$nextLimit mapped=${mapped.length} '
          'fresh=$freshCount droppedByDedupe=$droppedByDedupe '
          'remoteBefore=${_remoteApprovedTemplates.length} exhausted=$exhausted',
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
        _templatesHasMore = !exhausted;
        _allTemplatesWindowExhausted = exhausted;
      });
      _templateProjectionCache = null;
      _templateProjectionIdentity = null;
      _scheduleDeferredAllFeedRanking();
      return freshCount > 0 || !exhausted;
    } catch (error, stackTrace) {
      _homeDebugLogStack('loadMore window failed: $error', stackTrace);
      if (mounted) {
        setState(() => _templatesLoadingMore = false);
      }
      return false;
    }
  }

  Future<bool> _loadMoreSelectedCategoryTemplates() async {
    final slug = _selectedCategorySlug;
    final normalizedSlug = _normalizeTag(slug);
    if (normalizedSlug.isEmpty ||
        normalizedSlug == _allCategorySlug ||
        _templatesLoading ||
        _templatesLoadingMore ||
        _categoryExhaustedSlugs.contains(normalizedSlug)) {
      return false;
    }
    final generation = _categoryLoadGeneration;
    final nextLimit = math.max(
      (_categoryFetchLimitBySlug[normalizedSlug] ?? (_templatesPageSize * 2)) +
          _categoryTemplatesPageSize,
      _templatesPageSize * 2,
    );
    _categoryFetchLimitBySlug[normalizedSlug] = nextLimit;
    setState(() => _templatesLoadingMore = true);
    try {
      final targeted = _isPoliticalFeedSlug(normalizedSlug)
          ? await _approvedCreatorTemplateService.fetchApprovedTemplatesWindow(
              scanLimit: nextLimit,
              source: Source.server,
            )
          : await _approvedCreatorTemplateService
                .fetchAllApprovedTemplatesForCategory(
                  categoryId: normalizedSlug,
                  source: Source.server,
                  scanLimit: nextLimit,
                );
      if (!mounted || generation != _categoryLoadGeneration) {
        if (mounted && generation != _categoryLoadGeneration) {
          setState(() => _templatesLoadingMore = false);
        }
        return false;
      }
      final mapped = await _mapTemplatesOffMain(
        targeted,
        phase: 'category_load_more',
      );
      if (!mounted || generation != _categoryLoadGeneration) {
        if (mounted && generation != _categoryLoadGeneration) {
          setState(() => _templatesLoadingMore = false);
        }
        return false;
      }
      final merged = await _mergeTemplateListsOffMain(<List<_TemplateItem>>[
        _remoteApprovedTemplates,
        mapped,
      ], phase: 'category_load_more_merge');
      if (!mounted || generation != _categoryLoadGeneration) {
        if (mounted && generation != _categoryLoadGeneration) {
          setState(() => _templatesLoadingMore = false);
        }
        return false;
      }
      final freshCount = math.max(
        merged.length - _remoteApprovedTemplates.length,
        0,
      );
      final exhausted = targeted.length < nextLimit;
      setState(() {
        _remoteApprovedTemplates = merged;
        _rankedAllFeedTemplates = null;
        _allFeedRankingReady = false;
        _templatesLoadingMore = false;
      });
      _templateProjectionCache = null;
      _templateProjectionIdentity = null;
      _categoryListCache = null;
      _categoryListIdentity = null;
      _hydratedCategorySlugs.add(normalizedSlug);
      if (exhausted) {
        _categoryExhaustedSlugs.add(normalizedSlug);
      } else {
        _categoryExhaustedSlugs.remove(normalizedSlug);
      }
      _homeDebugLog(
        '[PosterUI] categoryLoadMore slug=$slug limit=$nextLimit '
        'targeted=${targeted.length} fresh=$freshCount exhausted=$exhausted',
      );
      return freshCount > 0 || !exhausted;
    } catch (error, stackTrace) {
      _homeDebugLogStack('category loadMore failed: $error', stackTrace);
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
    if (hasScrollableExtent &&
        position.pixels < position.maxScrollExtent - 520) {
      _posterFeedLoadMoreArmed = true;
    }
    if (_posterFeedLoadMoreArmed &&
        hasScrollableExtent &&
        userHasActuallyScrolled &&
        position.pixels >= position.maxScrollExtent - 320) {
      _posterFeedLoadMoreArmed = false;
      if (_selectedCategorySlug == _allCategorySlug) {
        unawaited(_loadMoreApprovedCreatorTemplates());
      } else {
        unawaited(_loadMoreSelectedCategoryTemplates());
      }
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
      selectedCategory.effectiveSelectionSlug,
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
              _allFeedPersonalizationRevision,
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
    if (!_religionSelectionReady) {
      final identity = Object.hash(
        language,
        _religionPreference,
        _religionSelectionReady,
      );
      final cached = _categoryListCache;
      if (cached != null && _categoryListIdentity == identity) {
        return cached;
      }
      final categories = <_CategoryChipData>[_allCategoryChip()];
      _categoryListCache = categories;
      _categoryListIdentity = identity;
      return categories;
    }

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
    final permanentCategoryIdentity = Object.hashAll(
      _permanentCategories
          .map((item) => '${item.slug}:${item.label}')
          .toList(growable: false)
        ..sort(),
    );
    final identity = Object.hash(
      language,
      _templatesLoading,
      _religionPreference,
      _religionSelectionReady,
      _selectedMoreCategorySlug,
      Object.hashAll(
        _selectedPoliticalPartyIds.toList(growable: false)..sort(),
      ),
      availabilityIdentity,
      manualCategoryIdentity,
      permanentCategoryIdentity,
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
    final now = IstTimeService.now();
    final scheduledDynamicCategories = _buildDynamicCategories(
      now,
      language,
      templatesLoading: _templatesLoading,
    );
    final bonaluSharedCategory = _buildBonaluSharedCategory(now);
    final dynamicCategories = <_CategoryChipData>[
      ?bonaluSharedCategory,
      ...templateDrivenDynamicCategories,
      ...scheduledDynamicCategories,
    ];
    final partyCategories = _buildSelectedPartyCategories(language);
    _homeDebugLog(
      '[DynamicCategoryList] template=${templateDrivenDynamicCategories.map((item) => _normalizeTag(item.slug)).join(",")} '
      'scheduled=${scheduledDynamicCategories.map((item) => _normalizeTag(item.slug)).join(",")} '
      'parties=${partyCategories.map((item) => _normalizeTag(item.slug)).join(",")}',
    );
    final categories = _mergeCategories(
      staticCategories,
      dynamicCategories,
      partyCategories,
    );
    _homeDebugLog(
      '[CategoryList] slugs=${categories.map((item) => _normalizeTag(item.slug)).join(",")}',
    );
    _categoryListCache = categories;
    _categoryListIdentity = identity;
    return categories;
  }

  // ignore: unused_element
  Future<void> _refreshHomeFeed({bool force = false}) async {
    if (_homeRefreshing) {
      return;
    }
    if (!force) {
      final lastRefresh = _lastHomeFeedRefreshAt;
      if (lastRefresh != null &&
          DateTime.now().difference(lastRefresh) < _homeResumeRefreshCooldown) {
        return;
      }
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
      await FirebaseBootstrap.ensureInitialized();
      if (!mounted) {
        return;
      }
      await Future.wait<void>(<Future<void>>[
        _loadHomeBanners(),
        _loadApprovedCreatorTemplates(forceRefresh: true),
        _loadManualEventCategories(),
        _loadPermanentCategories(),
        _loadViewerPosterProfile(),
      ]);
      _lastHomeFeedRefreshAt = DateTime.now();
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
            telugu:
                'à°®à°°à°¿à°¨à±à°¨à°¿ à°ªà±‹à°¸à±à°Ÿà°°à±à°² à°•à±‹à°¸à°‚ à°®à±†à°‚à°¬à°°à±â€Œà°·à°¿à°ªà± à°¤à±€à°¸à±à°•à±‹à°‚à°¡à°¿',
            english: 'Unlock more posters with membership',
          ),
          subtitle: strings.localized(
            telugu:
                'à°¡à±Œà°¨à±â€Œà°²à±‹à°¡à±, à°·à±‡à°°à°¿à°‚à°—à± à°®à°°à°¿à°¯à± à°®à±†à°‚à°¬à°°à±â€Œà°·à°¿à°ªà± à°¸à±Œà°•à°°à±à°¯à°¾à°² à°•à±‹à°¸à°‚ à°¸à°¬à±â€Œà°¸à±à°•à±à°°à±ˆà°¬à± à°šà±‡à°¯à°‚à°¡à°¿.',
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
            telugu:
                'à°®à±€ à°®à±†à°‚à°¬à°°à±â€Œà°·à°¿à°ªà± à°¤à±à°µà°°à°²à±‹ à°®à±à°—à°¿à°¯à°¬à±‹à°¤à±‹à°‚à°¦à°¿',
            english: 'Your membership is expiring soon',
          ),
          subtitle: strings.localized(
            telugu:
                'à°‡à°‚à°•à°¾ 3 à°°à±‹à°œà±à°²à°²à±‹à°ªà± à°ªà±à°²à°¾à°¨à± à°®à±à°—à±à°¸à±à°¤à±à°‚à°¦à°¿. à°…à°‚à°¤à°°à°¾à°¯à°‚ à°²à±‡à°•à±à°‚à°¡à°¾ à°ªà±‹à°¸à±à°Ÿà°°à±à°²à± à°µà°¾à°¡à°¾à°²à°‚à°Ÿà±‡ à°‡à°ªà±à°ªà±à°¡à±‡ renew à°šà±‡à°¯à°‚à°¡à°¿.',
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
            telugu:
                'à°•à±Šà°¤à±à°¤ à°¯à°¾à°ªà± à°…à°ªà±â€Œà°¡à±‡à°Ÿà± à°¸à°¿à°¦à±à°§à°‚à°—à°¾ à°‰à°‚à°¦à°¿',
            english: 'A new app update is ready',
          ),
          subtitle: strings.localized(
            telugu:
                'Play Store à°²à±‹ à°•à±Šà°¤à±à°¤ version à°…à°‚à°¦à±à°¬à°¾à°Ÿà±à°²à±‹ à°‰à°‚à°¦à°¿. à°¤à°¾à°œà°¾ à°®à±†à°°à±à°—à±à°¦à°²à°² à°•à±‹à°¸à°‚ à°‡à°ªà±à°ªà±à°¡à± à°…à°ªà±â€Œà°¡à±‡à°Ÿà± à°šà±‡à°¯à°‚à°¡à°¿.',
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
            telugu:
                'Mana Poster Ai à°•à°¿ à°°à±‡à°Ÿà°¿à°‚à°—à± à°‡à°µà±à°µà°‚à°¡à°¿',
            english: 'Rate Mana Poster Ai',
          ),
          subtitle: strings.localized(
            telugu:
                'à°®à±€ rating à°®à°°à°¿à°¯à± review à°µà°²à±à°² à°®à°°à°¿à°‚à°¤ à°®à°‚à°¦à°¿à°•à°¿ à°¯à°¾à°ªà± à°—à±à°°à°¿à°‚à°šà°¿ à°¤à±†à°²à±à°¸à±à°¤à±à°‚à°¦à°¿.',
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
    if (!_shouldRunRemoteHomeStartupTasks) {
      return false;
    }
    if (!AppPublicInfo.hasHomeBannerAdUnitId) {
      return false;
    }
    if (entitlement?.hasAccess == true) {
      return false;
    }
    if (InAppPurchaseGateway.playStoreProActive) {
      return false;
    }
    if (!_shouldRunFirebaseUiServices) {
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
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu:
                  'Play Store à°¤à±†à°°à°µà°²à±‡à°•à°ªà±‹à°¯à°¾à°‚. à°‡à°‚à°•à±‹à°¸à°¾à°°à°¿ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
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
    if (slug == _moreCategorySlug) {
      unawaited(_openMoreCategorySheet());
      return;
    }
    if (slug == _politicalCategorySlug) {
      unawaited(_openPoliticalPartyPicker());
      return;
    }
    if (slug == _selectedCategorySlug) {
      return;
    }
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    final language = context.currentLanguage;
    final generation = ++_categoryLoadGeneration;
    if (_posterPageController.hasClients) {
      _posterPageController.jumpToPage(0);
    }
    _activePosterPageNotifier.value = 0;
    setState(() {
      _selectedCategorySlug = slug;
      _categoryLoadingSlug = slug == _allCategorySlug ? null : slug;
      _activePosterPage = 0;
    });
    _resetAllFeedScrollOrderLock();
    _schedulePosterFeedResetToTop();
    unawaited(_loadSelectedCategoryUntilVisible(slug, generation, language));
  }

  Future<void> _openPoliticalPartyPicker() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            const PoliticalPartiesScreen(returnToPreviousOnSave: true),
      ),
    );
    if (!mounted || changed != true) {
      return;
    }
    await _loadPartyPreference();
    if (!mounted) {
      return;
    }
    final selectedPartyId = _selectedPoliticalPartyId();
    if (selectedPartyId == null || selectedPartyId.trim().isEmpty) {
      return;
    }
    _selectCategory('party_$selectedPartyId');
  }

  Future<void> _openMoreCategorySheet() async {
    final initialPopupCategories = _morePopupCategories();
    if (initialPopupCategories.isEmpty) {
      return;
    }
    _moreCategorySheetOpen = true;
    _categoryAvailabilityChangedWhileMoreSheetOpen = false;
    final availabilityRefreshFuture =
        _refreshMoreCategoryAvailabilityBeforeOpeningSheet();
    var popupCategories = initialPopupCategories;
    var refreshing = true;
    var refreshListenerAttached = false;
    final selectedSlug =
        await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (sheetContext) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                if (!refreshListenerAttached) {
                  refreshListenerAttached = true;
                  availabilityRefreshFuture.whenComplete(() {
                    if (!sheetContext.mounted || !refreshing) {
                      return;
                    }
                    setSheetState(() {
                      refreshing = false;
                      popupCategories = _morePopupCategories(
                        scheduleAvailabilityChecks: false,
                      );
                    });
                  });
                }
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'More Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: refreshing
                              ? const LinearProgressIndicator(
                                  key: ValueKey<String>('more-refreshing'),
                                  minHeight: 2,
                                )
                              : const SizedBox(
                                  key: ValueKey<String>('more-ready'),
                                  height: 2,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final category in popupCategories)
                              _CategoryChip(
                                data: category,
                                isSelected:
                                    category.slug == _selectedMoreCategorySlug,
                                onTap: () => Navigator.of(
                                  sheetContext,
                                ).pop(category.slug),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ).whenComplete(() {
          _moreCategorySheetOpen = false;
          if (_categoryAvailabilityChangedWhileMoreSheetOpen && mounted) {
            _categoryAvailabilityChangedWhileMoreSheetOpen = false;
            setState(() {});
          }
        });
    if (!mounted || selectedSlug == null) {
      return;
    }
    _CategoryChipData? selectedCategory;
    for (final category in _morePopupCategories(
      scheduleAvailabilityChecks: false,
    )) {
      if (category.slug == selectedSlug) {
        selectedCategory = category;
        break;
      }
    }
    setState(() {
      _selectedMoreCategorySlug = selectedSlug;
      _selectedMoreCategoryChip = selectedCategory;
      _categoryListCache = null;
      _categoryListIdentity = null;
    });
    _selectCategory(selectedSlug);
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
    final normalizedSlug = _normalizeTag(slug);
    if (kDebugMode) {
      _homeDebugLog(
        '[PosterUI] categoryPrefetch slug=$slug localMatches=$matchingCount '
        'remoteCount=${_remoteApprovedTemplates.length} hasMore=$_templatesHasMore',
      );
    }
    final needsHydration = !_hydratedCategorySlugs.contains(normalizedSlug);
    if (needsHydration) {
      final currentLimit = _categoryFetchLimitBySlug[normalizedSlug] ?? 0;
      _categoryFetchLimitBySlug[normalizedSlug] = math.max(
        currentLimit,
        math.max(
          matchingCount + _categoryTemplatesPageSize,
          _templatesPageSize * 2,
        ),
      );
    }
    if (needsHydration && mounted && generation == _categoryLoadGeneration) {
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
    final fetchLimit = math.max(
      _categoryFetchLimitBySlug[normalizedSlug] ?? (_templatesPageSize * 2),
      _templatesPageSize * 2,
    );
    final targeted = _isPoliticalFeedSlug(normalizedSlug)
        ? await _approvedCreatorTemplateService.fetchApprovedTemplatesWindow(
            scanLimit: fetchLimit,
            source: Source.server,
          )
        : await _approvedCreatorTemplateService
              .fetchAllApprovedTemplatesForCategory(
                categoryId: normalizedSlug,
                source: Source.server,
                scanLimit: fetchLimit,
              );
    if (!mounted || generation != _categoryLoadGeneration) {
      return;
    }
    if (targeted.isEmpty) {
      _categoryExhaustedSlugs.add(normalizedSlug);
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
      _templateProjectionCache = null;
      _templateProjectionIdentity = null;
      _categoryListCache = null;
      _categoryListIdentity = null;
      _hydratedCategorySlugs.add(normalizedSlug);
      if (targeted.length < fetchLimit) {
        _categoryExhaustedSlugs.add(normalizedSlug);
      } else {
        _categoryExhaustedSlugs.remove(normalizedSlug);
      }
      setState(() {});
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
    if (targeted.length < fetchLimit) {
      _categoryExhaustedSlugs.add(normalizedSlug);
    } else {
      _categoryExhaustedSlugs.remove(normalizedSlug);
    }
  }

  _CategoryChipData _categoryForSlug(String slug, AppLanguage language) {
    final morePopupCategory = _morePopupCategoryForSlug(slug);
    if (morePopupCategory != null) {
      return morePopupCategory;
    }
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
      if (mounted && _posterPageController.hasClients) {
        _posterPageController.jumpToPage(0);
        return;
      }
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

  Future<void> _scrollHomeFeedToTop() async {
    _searchFocusNode.unfocus();
    if (_posterPageController.hasClients) {
      await _posterPageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!_posterScrollController.hasClients) {
      return;
    }
    final position = _posterScrollController.position;
    if (!position.hasContentDimensions ||
        position.pixels <= position.minScrollExtent) {
      return;
    }
    await _posterScrollController.animateTo(
      position.minScrollExtent,
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handlePosterPageChanged(int index, List<_HomeFeedEntry> feedEntries) {
    if (_activePosterPage != index) {
      _activePosterPage = index;
      _activePosterPageNotifier.value = index;
    }
    if (_selectedCategorySlug == _allCategorySlug &&
        _lockedAllFeedTemplates == null &&
        index > 0) {
      _lockedAllFeedTemplates = List<_TemplateItem>.of(
        _currentAllFeedDisplaySource(),
      );
    }
    if (index >= 0 && index < feedEntries.length) {
      final item = feedEntries[index].template;
      if (item != null) {
        _recordAllFeedTemplateInteraction(item, 'view');
      }
    }
    final feedEntryCount = feedEntries.length;
    if (feedEntryCount > 0 && index >= feedEntryCount - 3) {
      if (_selectedCategorySlug == _allCategorySlug) {
        unawaited(_loadMoreApprovedCreatorTemplates());
      } else {
        unawaited(_loadMoreSelectedCategoryTemplates());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.currentLanguage;
    final categories = _buildCategoriesForHome(language);
    final activeCategorySlug =
        categories.any(
          (chip) => chip.effectiveSelectionSlug == _selectedCategorySlug,
        )
        ? _selectedCategorySlug
        : _allCategorySlug;
    final selectedCategory = categories.firstWhere(
      (chip) => chip.effectiveSelectionSlug == activeCategorySlug,
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
    final mediaSize = MediaQuery.sizeOf(context);
    final useCompactLandscapeHome = mediaSize.width > mediaSize.height;
    final safePadding = MediaQuery.paddingOf(context);
    final uploadTabTop = (mediaSize.height * 0.32).clamp(
      safePadding.top + 220,
      mediaSize.height - safePadding.bottom - 260,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              RepaintBoundary(
                child: _HomeHeader(
                  onHeaderTap: () => unawaited(_scrollHomeFeedToTop()),
                  onCreateTap: _onCreateTap,
                  onStatusTap: _shouldRunRemoteHomeStartupTasks
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _CommunityStatusGridScreen(),
                          ),
                        )
                      : () {},
                  onProfileTap: _openProfile,
                  viewerPosterProfile: _viewerPosterProfile,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchChanged: (_) {},
                  onSearchSubmitted: _openWebsiteSearch,
                  compact: useCompactLandscapeHome,
                ),
              ),
              _HomePinnedFeedControls(
                categories: categories,
                activeCategorySlug: activeCategorySlug,
                scrollController: _categoryScrollController,
                onCategoryTap: _selectCategory,
                banners: _homeBanners,
                showAdFallback: _adFallbackSlotEnabled,
                shouldShowAdFallback: _shouldShowHomeBannerAdFallback(
                  effectiveEntitlement,
                ),
                homeRefreshing: _homeRefreshing,
                compact: useCompactLandscapeHome,
              ),
              Expanded(
                child: hidePosterFeed || loadingSelectedCategory
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _PosterFeedSkeletonViewport(),
                      )
                    : templates.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _EmptyPosterGameState(
                          key: ValueKey<String>(
                            'empty-poster-game-$activeCategorySlug',
                          ),
                          icon: Icons.collections_outlined,
                          title: strings.homeEmptyPostersTitle,
                          subtitle: strings.homeEmptyPostersSubtitle,
                          categorySlug: selectedCategory.slug,
                          categoryLabel: selectedCategory.label,
                        ),
                      )
                    : ValueListenableBuilder<int>(
                        valueListenable: _activePosterPageNotifier,
                        builder: (context, activePosterPage, _) {
                          final activeFeedPage = feedEntries.isEmpty
                              ? 0
                              : math.min(
                                  activePosterPage,
                                  feedEntries.length - 1,
                                );
                          return PageView.builder(
                            controller: _posterPageController,
                            scrollDirection: Axis.vertical,
                            allowImplicitScrolling: true,
                            physics: _posterPhotoDragInProgress
                                ? const NeverScrollableScrollPhysics()
                                : const PageScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                            onPageChanged: (index) =>
                                _handlePosterPageChanged(index, feedEntries),
                            itemCount:
                                feedEntries.length +
                                (_templatesLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= feedEntries.length) {
                                return const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                                );
                              }
                              final entry = feedEntries[index];
                              if (entry.isPromo) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    18,
                                  ),
                                  child: Center(
                                    child: _HomeInlinePromoCard(
                                      data: entry.promo!,
                                      viewerPosterProfile: _viewerPosterProfile,
                                      slides: promoSlides,
                                      onTap: () => unawaited(
                                        _handlePromoTap(entry.promo!.type),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final item = entry.template!;
                              final isActivePoster = index == activeFeedPage;
                              return _TemplateFeedItem(
                                key: ValueKey<String>(
                                  item.templateId?.trim().isNotEmpty == true
                                      ? item.templateId!.trim()
                                      : '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath ?? item.videoUrl ?? 'poster'}',
                                ),
                                item: item,
                                hostContext: context,
                                language: language,
                                preferUltraLightImage: !isActivePoster,
                                deferRichPosterPreview: !isActivePoster,
                                fillViewport: true,
                                playbackEnabled: isActivePoster,
                                enablePoliticalProtocolOverlay:
                                    selectedCategory.slug ==
                                        _politicalCategorySlug ||
                                    _partyIdFromCategorySlug(
                                          selectedCategory.slug,
                                        ) !=
                                        null,
                                politicalProtocolPhotoScopeKey: _normalizeTag(
                                  selectedCategory.slug,
                                ),
                                forcedPoliticalProtocolPartyId:
                                    _partyIdFromCategorySlug(
                                      selectedCategory.slug,
                                    ),
                                onOpenSubscriptionPlan:
                                    _pushSubscriptionPlanRoute,
                                viewerPosterProfile: _viewerPosterProfile,
                                posterRenderCycle: _posterRenderCycle,
                                onPosterPhotoDragStateChanged:
                                    _setPosterPhotoDragInProgress,
                                onInteraction:
                                    _recordAllFeedTemplateInteraction,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          PositionedDirectional(
            top: uploadTabTop,
            end: 0,
            child: _CommunityUploadEdgeTab(
              onTap: () => unawaited(_openUserUploadsSheet()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityUploadEdgeTab extends StatelessWidget {
  const _CommunityUploadEdgeTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: 'Community Uploads',
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: Container(
              width: 36,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(14),
                ),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1A0F172A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.cloud_upload_rounded,
                  color: Color(0xFFD81B60),
                  size: 21,
                ),
              ),
            ),
          ),
        ),
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
          telugu:
              'à°°à°¿à°«à°°à°²à± à°•à±‹à°¡à± à°¨à°®à±‹à°¦à± à°šà±‡à°¯à°‚à°¡à°¿',
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
                telugu:
                    'à°°à°¿à°«à°°à°²à± à°•à±‹à°¡à± à°…à°ªà±à°²à±ˆ à°•à°¾à°²à±‡à°¦à±',
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
          telugu:
              'à°°à°¿à°«à°°à°²à± à°•à±‹à°¡à± à°…à°ªà±à°²à±ˆ à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿',
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
                        telugu: 'à°°à°¿à°«à°°à°²à± à°•à±‹à°¡à±',
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
                            'à°®à±€ à°¦à°—à±à°—à°° referral code à°‰à°‚à°Ÿà±‡ à°‡à°•à±à°•à°¡ enter à°šà±‡à°¯à°‚à°¡à°¿.',
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
                          telugu: 'à°°à°¿à°«à°°à°²à± à°•à±‹à°¡à±',
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
                          telugu:
                              'à°¨à°¿à°¬à°‚à°§à°¨à°²à± à°®à°°à°¿à°¯à± à°·à°°à°¤à±à°²à± à°šà±‚à°¡à°‚à°¡à°¿',
                          english: 'View Terms & Conditions',
                        ),
                      ),
                    ),
                    PrimaryButton(
                      label: strings.localized(
                        telugu: 'à°…à°ªà±à°²à±ˆ',
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
                        strings.localized(
                          telugu: 'à°¸à±à°•à°¿à°ªà±',
                          english: 'Skip',
                        ),
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

class _CommunityStatusGroup {
  const _CommunityStatusGroup({required this.statuses});

  final List<CommunityStatus> statuses;

  String get userId => statuses.isEmpty ? '' : statuses.first.userId;
  CommunityStatus get latestStatus => statuses.last;
  bool get hasUnseenStatus => statuses.any((status) => !status.viewerHasViewed);
  String get displayName {
    for (final status in statuses) {
      if (status.userName.trim().isNotEmpty) {
        return status.userName.trim();
      }
    }
    return '';
  }
}

class _CommunityStatusGridScreen extends StatefulWidget {
  const _CommunityStatusGridScreen();

  @override
  State<_CommunityStatusGridScreen> createState() =>
      _CommunityStatusGridScreenState();
}

class _CommunityStatusGridScreenState
    extends State<_CommunityStatusGridScreen> {
  static const int _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _statusBubbleScrollController = ScrollController();
  late Stream<List<CommunityStatus>> _statusesStream;
  List<CommunityStatus> _lastStatuses = const <CommunityStatus>[];
  String _selectedRegionId = '';
  int _statusLimit = _pageSize;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _loadCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    if (!_shouldRunFirebaseUiServices) {
      _statusesStream = const Stream<List<CommunityStatus>>.empty();
      return;
    }
    _statusesStream = CommunityStatusService.instance.watchVisibleStatuses(
      maxStatuses: _statusLimit,
    );
    _scrollController.addListener(_handleScroll);
    _statusBubbleScrollController.addListener(_handleStatusBubbleScroll);
    unawaited(_loadSelectedRegion());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _statusBubbleScrollController
      ..removeListener(_handleStatusBubbleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 520) {
      _loadMoreStatuses();
    }
  }

  void _handleStatusBubbleScroll() {
    if (_statusBubbleScrollController.position.extentAfter < 360) {
      _loadMoreStatuses();
    }
  }

  Future<void> _loadSelectedRegion() async {
    final region = await AppRegionService.loadSelection();
    if (!mounted) {
      return;
    }
    setState(() => _selectedRegionId = region?.id ?? '');
  }

  void _loadMoreStatuses() {
    if (_loadingMore || !_hasMore) {
      return;
    }
    setState(() {
      _loadingMore = true;
      _statusLimit += _pageSize;
      _statusesStream = CommunityStatusService.instance.watchVisibleStatuses(
        maxStatuses: _statusLimit,
      );
    });
  }

  void _scheduleLoadCheck() {
    if (_loadCheckScheduled || _loadingMore || !_hasMore) {
      return;
    }
    _loadCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckScheduled = false;
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (_scrollController.position.extentAfter < 520) {
        _loadMoreStatuses();
      }
    });
  }

  Future<void> _openUpload() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CommunityStatusUploadScreen(),
      ),
    );
  }

  void _openViewer(List<_CommunityStatusGroup> groups, int initialGroupIndex) {
    if (groups.isEmpty || initialGroupIndex < 0) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _CommunityStatusViewerScreen(
          initialGroups: groups,
          initialGroupIndex: initialGroupIndex,
          visibleStatusLimit: _statusLimit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          SafeArea(
            child: StreamBuilder<List<CommunityStatus>>(
              stream: _statusesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _lastStatuses = snapshot.data!;
                  _hasMore = _lastStatuses.length >= _statusLimit;
                  _loadingMore = false;
                  _scheduleLoadCheck();
                }
                final statuses = snapshot.data ?? _lastStatuses;
                final myStatuses = _statusGroupItemsForUser(
                  statuses,
                  currentUserId,
                );
                final otherGroups =
                    _statusGroups(statuses)
                        .where((group) => group.userId != currentUserId)
                        .toList(growable: false)
                      ..sort(_compareStatusGroupsForHome);
                final viewerGroups = <_CommunityStatusGroup>[
                  if (myStatuses.isNotEmpty)
                    _CommunityStatusGroup(statuses: myStatuses),
                  ...otherGroups,
                ];
                final calendarEvents = _statusCalendarEvents(
                  context.currentLanguage,
                  _selectedRegionId,
                );

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        child: Row(
                          children: <Widget>[
                            Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                strings.localized(
                                  telugu: 'à°¸à±à°Ÿà±‡à°Ÿà°¸à±à°²à±',
                                  english: 'Statuses',
                                  hindi: 'à¤¸à¥à¤Ÿà¥‡à¤Ÿà¤¸',
                                  tamil: 'à®¨à®¿à®²à¯ˆà®•à®³à¯',
                                  kannada: 'à²¸à³à²Ÿà³‡à²Ÿà²¸à³â€Œà²—à²³à³',
                                  malayalam:
                                      'à´¸àµà´±àµà´±à´¾à´±àµà´±à´¸àµà´•àµ¾',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Material(
                              color: const Color(0xFFD81B60),
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: strings.localized(
                                  telugu:
                                      'à°¸à±à°Ÿà±‡à°Ÿà°¸à± à°œà±‹à°¡à°¿à°‚à°šà°‚à°¡à°¿',
                                  english: 'Add Status',
                                ),
                                onPressed: () => unawaited(_openUpload()),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
                        child: SizedBox(
                          height: 116,
                          child: ListView.separated(
                            controller: _statusBubbleScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 1 + otherGroups.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _StatusBubbleCard(
                                  group: myStatuses.isEmpty
                                      ? null
                                      : _CommunityStatusGroup(
                                          statuses: myStatuses,
                                        ),
                                  label: strings.localized(
                                    telugu: 'à°¨à°¾ à°¸à±à°Ÿà±‡à°Ÿà°¸à±',
                                    english: 'My Status',
                                    hindi: 'à¤®à¥‡à¤°à¤¾ à¤¸à¥à¤Ÿà¥‡à¤Ÿà¤¸',
                                    tamil: 'à®Žà®©à¯ à®¨à®¿à®²à¯ˆ',
                                    kannada:
                                        'à²¨à²¨à³à²¨ à²¸à³à²Ÿà³‡à²Ÿà²¸à³',
                                    malayalam:
                                        'à´Žà´¨àµà´±àµ† à´¸àµà´±àµà´±à´¾à´±àµà´±à´¸àµ',
                                  ),
                                  isMine: true,
                                  onAdd: () => unawaited(_openUpload()),
                                  onOpen: () => _openViewer(viewerGroups, 0),
                                );
                              }
                              final group = otherGroups[index - 1];
                              final viewerIndex = viewerGroups.indexWhere(
                                (item) => item.userId == group.userId,
                              );
                              return _StatusBubbleCard(
                                group: group,
                                label: group.displayName.isEmpty
                                    ? strings.localized(
                                        telugu:
                                            'à°µà°¿à°¨à°¿à°¯à±‹à°—à°¦à°¾à°°à±',
                                        english: 'User',
                                        hindi: 'à¤‰à¤ªà¤¯à¥‹à¤—à¤•à¤°à¥à¤¤à¤¾',
                                        tamil: 'à®ªà®¯à®©à®°à¯',
                                        kannada: 'à²¬à²³à²•à³†à²¦à²¾à²°',
                                        malayalam:
                                            'à´‰à´ªà´¯àµ‹à´•àµà´¤à´¾à´µàµ',
                                      )
                                    : group.displayName,
                                onOpen: () =>
                                    _openViewer(viewerGroups, viewerIndex),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        statuses.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: _SocialMediaCalendarRail(
                            events: calendarEvents,
                            monthLabel: _statusCalendarMonthLabel(
                              IstTimeService.now(),
                            ),
                          ),
                        ),
                      ),
                    if (_loadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }
}

class _StatusBubbleCard extends StatelessWidget {
  const _StatusBubbleCard({
    required this.group,
    required this.label,
    required this.onOpen,
    this.isMine = false,
    this.onAdd,
  });

  final _CommunityStatusGroup? group;
  final String label;
  final VoidCallback onOpen;
  final bool isMine;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final status = group?.latestStatus;
    final hasStatus = status != null;
    final ringGradient = hasStatus && (group?.hasUnseenStatus ?? false);
    return SizedBox(
      width: 82,
      child: InkWell(
        onTap: hasStatus ? onOpen : onAdd,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ringGradient
                    ? const LinearGradient(
                        colors: <Color>[
                          Color(0xFFFFD60A),
                          Color(0xFFFF4D8D),
                          Color(0xFF7C3AED),
                        ],
                      )
                    : null,
                color: ringGradient ? null : const Color(0xFFCBD5E1),
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: hasStatus
                    ? Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          _StatusGridPreview(status: status),
                          if (group!.statuses.length > 1)
                            Positioned(
                              right: 3,
                              bottom: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.58),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${group!.statuses.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const ColoredBox(
                        color: Color(0xFFF8FAFC),
                        child: Icon(
                          Icons.add_rounded,
                          color: Color(0xFFD81B60),
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMine
                    ? const Color(0xFFD81B60)
                    : const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCalendarEvent {
  const _StatusCalendarEvent({
    required this.title,
    required this.date,
    required this.monthLabel,
    required this.type,
  });

  final String title;
  final DateTime date;
  final String monthLabel;
  final DynamicCategoryType type;
}

class _SocialMediaCalendarRail extends StatefulWidget {
  const _SocialMediaCalendarRail({
    required this.events,
    required this.monthLabel,
  });

  final List<_StatusCalendarEvent> events;
  final String monthLabel;

  @override
  State<_SocialMediaCalendarRail> createState() =>
      _SocialMediaCalendarRailState();
}

class _SocialMediaCalendarRailState extends State<_SocialMediaCalendarRail> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _SocialMediaCalendarRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (_paused || !_controller.hasClients || widget.events.length < 4) {
        return;
      }
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) {
        return;
      }
      final next = _controller.offset + 0.85;
      if (next >= max) {
        _controller.jumpTo(0);
      } else {
        _controller.jumpTo(next);
      }
    });
  }

  void _togglePaused() {
    setState(() => _paused = !_paused);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final events = widget.events;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePaused,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD81B60).withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFFD81B60),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.localized(
                          telugu:
                              'à°¸à±‹à°·à°²à± à°®à±€à°¡à°¿à°¯à°¾ à°•à±à°¯à°¾à°²à±†à°‚à°¡à°°à±',
                          english: 'Social Media Calendar',
                          hindi: 'Social Media Calendar',
                          tamil: 'Social Media Calendar',
                          kannada: 'Social Media Calendar',
                          malayalam: 'Social Media Calendar',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.monthLabel,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 360,
              child: events.isEmpty
                  ? Center(
                      child: Text(
                        strings.localized(
                          telugu: 'à°ˆ à°¨à±†à°²à°²à±‹ events à°²à±‡à°µà±',
                          english: 'No events for this month',
                          hindi:
                              'à¤‡à¤¸ à¤®à¤¹à¥€à¤¨à¥‡ à¤•à¥‹à¤ˆ event à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆ',
                          tamil:
                              'à®‡à®¨à¯à®¤ à®®à®¾à®¤à®¤à¯à®¤à®¿à®²à¯ events à®‡à®²à¯à®²à¯ˆ',
                          kannada:
                              'à²ˆ à²¤à²¿à²‚à²—à²³à²²à³à²²à²¿ events à²‡à²²à³à²²',
                          malayalam:
                              'à´ˆ à´®à´¾à´¸à´¤àµà´¤à´¿àµ½ events à´‡à´²àµà´²',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _StatusCalendarEventTile(event: events[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCalendarEventTile extends StatelessWidget {
  const _StatusCalendarEventTile({required this.event});

  final _StatusCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final accent = _statusCalendarTypeColor(event.type);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  event.date.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.monthLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_StatusCalendarEvent> _statusCalendarEvents(
  AppLanguage language,
  String selectedRegionId,
) {
  final now = IstTimeService.now();
  final schedules = const DynamicEventScheduleService().schedulesForYear(
    now.year,
    daysBeforeEvent: 0,
  );
  return schedules
      .where((item) => item.occursInMonth(now.month))
      .where(
        (item) => _statusCalendarEventMatchesRegion(item, selectedRegionId),
      )
      .map(
        (item) => _StatusCalendarEvent(
          title: item.event.title.resolve(language),
          date: item.startDate,
          monthLabel: _statusCalendarMonthShort(item.startDate.month),
          type: item.event.type,
        ),
      )
      .toList(growable: false);
}

bool _statusCalendarEventMatchesRegion(
  ResolvedDynamicEventSchedule item,
  String selectedRegionId,
) {
  final region = _statusCalendarNormalize(selectedRegionId);
  final event = item.event;
  if (event.regionIds.isNotEmpty) {
    return event.regionIds.map(_statusCalendarNormalize).contains(region);
  }
  switch (event.scope) {
    case DynamicEventScope.global:
    case DynamicEventScope.india:
      return true;
    case DynamicEventScope.andhraPradesh:
      return region == 'andhra_pradesh';
    case DynamicEventScope.telangana:
      return region == 'telangana';
    case DynamicEventScope.bothTeluguStates:
      return region == 'andhra_pradesh' || region == 'telangana';
  }
}

String _statusCalendarNormalize(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

Color _statusCalendarTypeColor(DynamicCategoryType type) {
  return switch (type) {
    DynamicCategoryType.festival => const Color(0xFFD97706),
    DynamicCategoryType.birthday => const Color(0xFFDB2777),
    DynamicCategoryType.jayanthi => const Color(0xFF2563EB),
    DynamicCategoryType.vardhanthi => const Color(0xFF64748B),
    DynamicCategoryType.importantDay => const Color(0xFFD81B60),
    DynamicCategoryType.weekdaySpecial => const Color(0xFF16A34A),
    DynamicCategoryType.regionalSpecial => const Color(0xFF7C3AED),
  };
}

String _statusCalendarMonthLabel(DateTime date) {
  return '${_statusCalendarMonthShort(date.month)} ${date.year}';
}

String _statusCalendarMonthShort(int month) {
  const labels = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  if (month < 1 || month > 12) {
    return '';
  }
  return labels[month - 1];
}

class _StatusGridPreview extends StatelessWidget {
  const _StatusGridPreview({required this.status});

  final CommunityStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.hasImage) {
      return CachedNetworkImage(
        imageUrl: status.imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => const ColoredBox(
          color: Color(0xFFE2E8F0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, _, _) => const ColoredBox(
          color: Color(0xFFF1F5F9),
          child: Icon(Icons.broken_image_rounded, color: Color(0xFF64748B)),
        ),
      );
    }
    final color = Color(
      status.backgroundColor == 0 ? 0xFF4CAF50 : status.backgroundColor,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 64 || constraints.maxHeight < 64;
        return ColoredBox(
          color: color,
          child: Padding(
            padding: EdgeInsets.all(compact ? 3 : 14),
            child: Center(
              child: Text(
                status.text,
                maxLines: compact ? 3 : 6,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 7.5 : 15,
                  height: compact ? 1.0 : 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

int _compareStatusGroupsForHome(
  _CommunityStatusGroup a,
  _CommunityStatusGroup b,
) {
  if (a.hasUnseenStatus != b.hasUnseenStatus) {
    return a.hasUnseenStatus ? -1 : 1;
  }
  return b.latestStatus.createdAtMillis.compareTo(
    a.latestStatus.createdAtMillis,
  );
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
  const _CommunityStatusViewerScreen({
    required this.initialGroups,
    required this.initialGroupIndex,
    this.visibleStatusLimit = 60,
  });

  final List<_CommunityStatusGroup> initialGroups;
  final int initialGroupIndex;
  final int visibleStatusLimit;

  @override
  State<_CommunityStatusViewerScreen> createState() =>
      _CommunityStatusViewerScreenState();
}

class _CommunityStatusViewerScreenState
    extends State<_CommunityStatusViewerScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _viewDuration = Duration(seconds: 7);
  static const List<String> _reactions = <String>[
    'ðŸ”¥',
    'ðŸ‘',
    'ðŸ˜',
    'ðŸ™',
    'ðŸ˜ ',
  ];

  late final AnimationController _progressController;
  bool _isDeleting = false;
  bool _showingReplies = false;
  bool _isHoldPaused = false;
  late final List<String> _groupUserOrder;
  late int _currentGroupIndex;
  List<_CommunityStatusGroup> _latestViewerGroups =
      const <_CommunityStatusGroup>[];
  int _currentIndex = 0;
  DateTime? _tapStartedAt;
  String _lastRecordedStatusId = '';

  @override
  void initState() {
    super.initState();
    _groupUserOrder = widget.initialGroups
        .map((group) => group.userId)
        .where((userId) => userId.isNotEmpty)
        .toList(growable: true);
    _currentGroupIndex = widget.initialGroupIndex.clamp(
      0,
      math.max(0, widget.initialGroups.length - 1),
    );
    _progressController =
        AnimationController(
          vsync: this,
          duration: _viewDuration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted && !_isDeleting) {
            _goToNextOrStay(
              _latestViewerGroups.isEmpty
                  ? _orderedGroups(widget.initialGroups)
                  : _latestViewerGroups,
            );
          }
        });
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    if (widget.initialGroups.isNotEmpty) {
      _recordActiveView(
        widget.initialGroups[_currentGroupIndex].statuses.first,
      );
    }
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
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

  List<_CommunityStatusGroup> _orderedGroups(
    List<_CommunityStatusGroup> groups,
  ) {
    if (groups.isEmpty) {
      return const <_CommunityStatusGroup>[];
    }
    final byUserId = <String, _CommunityStatusGroup>{
      for (final group in groups)
        if (group.userId.isNotEmpty) group.userId: group,
    };
    final ordered = <_CommunityStatusGroup>[];
    for (final userId in List<String>.of(_groupUserOrder)) {
      final group = byUserId.remove(userId);
      if (group == null || group.statuses.isEmpty) {
        _groupUserOrder.remove(userId);
      } else {
        ordered.add(group);
      }
    }
    final newGroups = byUserId.values.toList(growable: false)
      ..sort(_compareStatusGroupsForHome);
    for (final group in newGroups) {
      _groupUserOrder.add(group.userId);
      ordered.add(group);
    }
    return ordered;
  }

  void _goToNextOrStay(List<_CommunityStatusGroup> groups) {
    if (groups.isEmpty) {
      return;
    }
    final statuses = groups[_currentGroupIndex].statuses;
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
    if (_currentGroupIndex < groups.length - 1) {
      setState(() {
        _currentGroupIndex += 1;
        _currentIndex = 0;
      });
      _progressController
        ..reset()
        ..forward();
      _recordActiveView(groups[_currentGroupIndex].statuses.first);
      return;
    }
    _progressController.stop();
    Navigator.of(context).maybePop();
  }

  void _goToPrevious(List<_CommunityStatusGroup> groups) {
    if (groups.isEmpty) {
      return;
    }
    if (_currentIndex <= 0 && _currentGroupIndex <= 0) {
      _progressController
        ..reset()
        ..forward();
      _recordActiveView(groups.first.statuses.first);
      return;
    }
    if (_currentIndex <= 0) {
      final previousGroupIndex = _currentGroupIndex - 1;
      final previousStatuses = groups[previousGroupIndex].statuses;
      setState(() {
        _currentGroupIndex = previousGroupIndex;
        _currentIndex = math.max(0, previousStatuses.length - 1);
      });
      _progressController
        ..reset()
        ..forward();
      _recordActiveView(groups[_currentGroupIndex].statuses[_currentIndex]);
      return;
    }
    setState(() {
      _currentIndex -= 1;
    });
    _progressController
      ..reset()
      ..forward();
    _recordActiveView(groups[_currentGroupIndex].statuses[_currentIndex]);
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

  double _progressValueForSegment(int index) {
    if (index < _currentIndex) {
      return 1;
    }
    if (index == _currentIndex) {
      return _progressController.value;
    }
    return 0;
  }

  void _handleViewerTapUp(
    TapUpDetails details,
    List<_CommunityStatusGroup> groups,
  ) {
    final startedAt = _tapStartedAt;
    _tapStartedAt = null;
    final tapDuration = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
    _resumeProgressAfterHold();
    if (_isDeleting ||
        _showingReplies ||
        tapDuration > const Duration(milliseconds: 280)) {
      return;
    }
    final width = MediaQuery.sizeOf(context).width;
    final dx = details.localPosition.dx;
    if (dx < width * 0.42) {
      _goToPrevious(groups);
    } else if (dx > width * 0.58) {
      _goToNextOrStay(groups);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRunFirebaseUiServices) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6FB),
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    return StreamBuilder<List<_CommunityStatusGroup>>(
      stream: CommunityStatusService.instance
          .watchVisibleStatuses(maxStatuses: widget.visibleStatusLimit)
          .map((statuses) {
            final myStatuses = _statusGroupItemsForUser(
              statuses,
              currentUserId,
            );
            final otherGroups =
                _statusGroups(statuses)
                    .where((group) => group.userId != currentUserId)
                    .toList(growable: false)
                  ..sort(_compareStatusGroupsForHome);
            return <_CommunityStatusGroup>[
              if (myStatuses.isNotEmpty)
                _CommunityStatusGroup(statuses: myStatuses),
              ...otherGroups,
            ];
          }),
      initialData: widget.initialGroups,
      builder: (context, snapshot) {
        final strings = context.strings;
        final groups = _orderedGroups(snapshot.data ?? widget.initialGroups);
        _latestViewerGroups = groups;
        if (groups.isEmpty && !_isDeleting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          });
        }
        if (groups.isEmpty && widget.initialGroups.isEmpty) {
          return const Scaffold(backgroundColor: Color(0xFF050505));
        }
        if (_currentGroupIndex >= groups.length && groups.isNotEmpty) {
          _currentGroupIndex = groups.length - 1;
        }
        final activeGroup = groups.isEmpty
            ? widget.initialGroups[_currentGroupIndex]
            : groups[_currentGroupIndex];
        if (_currentIndex >= activeGroup.statuses.length &&
            activeGroup.statuses.isNotEmpty) {
          _currentIndex = activeGroup.statuses.length - 1;
        }
        final statuses = activeGroup.statuses;
        final status = statuses[_currentIndex];
        _recordActiveView(status);
        final isOwner =
            FirebaseAuth.instance.currentUser?.uid.trim() == status.userId;
        final statusTitle = isOwner
            ? strings.localized(
                telugu: 'à°¨à°¾ à°¸à±à°Ÿà±‡à°Ÿà°¸à±',
                english: 'My Status',
              )
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
            onTapDown: (_) {
              _tapStartedAt = DateTime.now();
              _pauseProgressForHold();
            },
            onTapUp: (details) => _handleViewerTapUp(details, groups),
            onTapCancel: () {
              _tapStartedAt = null;
              _resumeProgressAfterHold();
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -220) {
                _goToNextOrStay(groups);
              } else if (velocity > 220) {
                _goToPrevious(groups);
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
                      return _StatusSegmentProgressBar(
                        itemCount: statuses.length,
                        valueForIndex: _progressValueForSegment,
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
                          tooltip: strings.localized(
                            telugu: 'à°®à°°à°¿à°¨à±à°¨à°¿',
                            english: 'More',
                          ),
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
                          itemBuilder: (_) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'report',
                              child: Text(
                                strings.localized(
                                  telugu: 'à°°à°¿à°ªà±‹à°°à±à°Ÿà±',
                                  english: 'Report',
                                ),
                                style: const TextStyle(
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
    final strings = context.strings;
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
              Text(
                strings.localized(
                  telugu: 'à°°à°¿à°ªà±à°²à±ˆà°²à±',
                  english: 'Replies',
                ),
                style: const TextStyle(
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
                      return Center(
                        child: Text(
                          strings.localized(
                            telugu:
                                'à°‡à°‚à°•à°¾ à°°à°¿à°ªà±à°²à±ˆà°²à± à°²à±‡à°µà±',
                            english: 'No replies yet',
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 8, 12, 24),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: _StatusInlineComment(
                                userName: comment.userName.isNotEmpty
                                    ? comment.userName
                                    : 'User',
                                text: comment.text,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: strings.localized(
                                telugu: 'à°®à°°à°¿à°¨à±à°¨à°¿',
                                english: 'More',
                              ),
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white54,
                                size: 17,
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
                              itemBuilder: (_) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'report',
                                  child: Text(
                                    strings.localized(
                                      telugu: 'à°°à°¿à°ªà±‹à°°à±à°Ÿà±',
                                      english: 'Report',
                                    ),
                                    style: const TextStyle(
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

String _localizedCommunityReportReason(BuildContext context, String reason) {
  final strings = context.strings;
  return switch (reason) {
    'Harassment or bullying' => strings.localized(
      telugu: 'à°µà±‡à°§à°¿à°‚à°ªà± à°²à±‡à°¦à°¾ à°¬à±†à°¦à°¿à°°à°¿à°‚à°ªà±',
      english: 'Harassment or bullying',
    ),
    'Hate speech or discrimination' => strings.localized(
      telugu:
          'à°¦à±à°µà±‡à°· à°ªà±à°°à°¸à°‚à°—à°‚ à°²à±‡à°¦à°¾ à°µà°¿à°µà°•à±à°·',
      english: 'Hate speech or discrimination',
    ),
    'Sexual or adult content' => strings.localized(
      telugu:
          'à°²à±ˆà°‚à°—à°¿à°• à°²à±‡à°¦à°¾ à°ªà±†à°¦à±à°¦à°² à°•à°‚à°Ÿà±†à°‚à°Ÿà±',
      english: 'Sexual or adult content',
    ),
    'Violence or dangerous content' => strings.localized(
      telugu:
          'à°¹à°¿à°‚à°¸ à°²à±‡à°¦à°¾ à°ªà±à°°à°®à°¾à°¦à°•à°° à°•à°‚à°Ÿà±†à°‚à°Ÿà±',
      english: 'Violence or dangerous content',
    ),
    'Spam, scam, or fake content' => strings.localized(
      telugu:
          'à°¸à±à°ªà°¾à°®à±, à°®à±‹à°¸à°‚ à°²à±‡à°¦à°¾ à°¨à°•à°¿à°²à±€ à°•à°‚à°Ÿà±†à°‚à°Ÿà±',
      english: 'Spam, scam, or fake content',
    ),
    'Misinformation or deceptive political content' => strings.localized(
      telugu:
          'à°¤à°ªà±à°ªà±à°¡à± à°¸à°®à°¾à°šà°¾à°°à°‚ à°²à±‡à°¦à°¾ à°®à±‹à°¸à°ªà±‚à°°à°¿à°¤ à°°à°¾à°œà°•à±€à°¯ à°•à°‚à°Ÿà±†à°‚à°Ÿà±',
      english: 'Misinformation or deceptive political content',
    ),
    'Privacy violation or personal information' => strings.localized(
      telugu:
          'à°ªà±à°°à±ˆà°µà°¸à±€ à°‰à°²à±à°²à°‚à°˜à°¨ à°²à±‡à°¦à°¾ à°µà±à°¯à°•à±à°¤à°¿à°—à°¤ à°¸à°®à°¾à°šà°¾à°°à°‚',
      english: 'Privacy violation or personal information',
    ),
    'Copyright or trademark issue' => strings.localized(
      telugu:
          'à°•à°¾à°ªà±€à°°à±ˆà°Ÿà± à°²à±‡à°¦à°¾ à°Ÿà±à°°à±‡à°¡à±â€Œà°®à°¾à°°à±à°•à± à°¸à°®à°¸à±à°¯',
      english: 'Copyright or trademark issue',
    ),
    'Illegal content' => strings.localized(
      telugu: 'à°šà°Ÿà±à°Ÿà°µà°¿à°°à±à°¦à±à°§ à°•à°‚à°Ÿà±†à°‚à°Ÿà±',
      english: 'Illegal content',
    ),
    _ => strings.localized(
      telugu: 'à°‡à°¤à°° à°¸à±‡à°«à±à°Ÿà±€ à°¸à°®à°¸à±à°¯',
      english: 'Other safety issue',
    ),
  };
}

Future<void> _showCommunityStatusReportSheet(
  BuildContext context, {
  required CommunityStatus status,
  CommunityStatusComment? comment,
}) async {
  final detailsController = TextEditingController();
  final strings = context.strings;
  var selectedReason = _communityReportReasons.first;
  var submitting = false;
  final reportedLabel = comment == null
      ? strings.localized(telugu: 'à°¸à±à°Ÿà±‡à°Ÿà°¸à±', english: 'status')
      : strings.localized(telugu: 'à°°à°¿à°ªà±à°²à±ˆ', english: 'reply');
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
                        strings.localized(
                          telugu:
                              '$reportedLabel à°°à°¿à°ªà±‹à°°à±à°Ÿà± à°šà±‡à°¯à°‚à°¡à°¿',
                          english: 'Report $reportedLabel',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.localized(
                          telugu:
                              'à°¦à°—à±à°—à°°à°—à°¾ à°¸à°°à°¿à°ªà±‹à°¯à±‡ à°•à°¾à°°à°£à°‚ à°Žà°‚à°šà±à°•à±‹à°‚à°¡à°¿. à°°à°¿à°ªà±‹à°°à±à°Ÿà±à°¸à± community safety à°•à±‹à°¸à°‚ team review à°šà±‡à°¯à°µà°šà±à°šà±.',
                          english:
                              'Choose the closest reason. Reports help keep the community safe and may be reviewed by our team.',
                        ),
                        style: const TextStyle(
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
                                  label: Text(
                                    _localizedCommunityReportReason(
                                      context,
                                      reason,
                                    ),
                                  ),
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
                          hintText: strings.localized(
                            telugu: 'à°µà°¿à°µà°°à°¾à°²à± optional',
                            english: 'Add details optional',
                          ),
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
                              child: Text(
                                strings.localized(
                                  telugu: 'à°°à°¦à±à°¦à±',
                                  english: 'Cancel',
                                ),
                              ),
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
                                        ..hideCurrentTopSnackBar()
                                        ..showTopSnackBar(
                                          AppSnackBar.build(
                                            content: Text(
                                              ok
                                                  ? strings.localized(
                                                      telugu:
                                                          'à°°à°¿à°ªà±‹à°°à±à°Ÿà± submit à°…à°¯à°¿à°‚à°¦à°¿. à°§à°¨à±à°¯à°µà°¾à°¦à°¾à°²à±.',
                                                      english:
                                                          'Report submitted. Thank you.',
                                                    )
                                                  : strings.localized(
                                                      telugu:
                                                          'à°°à°¿à°ªà±‹à°°à±à°Ÿà± à°µà°¿à°«à°²à°®à±ˆà°‚à°¦à°¿. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
                                                      english:
                                                          'Report failed. Please try again.',
                                                    ),
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
                              label: Text(
                                submitting
                                    ? strings.localized(
                                        telugu: 'à°ªà°‚à°ªà±à°¤à±‹à°‚à°¦à°¿',
                                        english: 'Sending',
                                      )
                                    : strings.localized(
                                        telugu:
                                            'à°¸à°®à°°à±à°ªà°¿à°‚à°šà°‚à°¡à°¿',
                                        english: 'Submit',
                                      ),
                              ),
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

class _StatusInlineComment extends StatefulWidget {
  const _StatusInlineComment({required this.userName, required this.text});

  final String userName;
  final String text;

  @override
  State<_StatusInlineComment> createState() => _StatusInlineCommentState();
}

class _StatusInlineCommentState extends State<_StatusInlineComment> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final userName = widget.userName.trim().isEmpty
        ? 'User'
        : widget.userName.trim();
    final text = widget.text.trim();
    final showReadMore = !_expanded && text.length > 70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w400,
            ),
            children: <InlineSpan>[
              TextSpan(
                text: '$userName  ',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: text),
            ],
          ),
        ),
        if (showReadMore) ...<Widget>[
          const SizedBox(height: 3),
          InkWell(
            onTap: () => setState(() => _expanded = true),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                strings.localized(
                  telugu: 'à°®à°°à°¿à°‚à°¤ à°šà°¦à°µà°‚à°¡à°¿',
                  english: 'Read more',
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusSegmentProgressBar extends StatelessWidget {
  const _StatusSegmentProgressBar({
    required this.itemCount,
    required this.valueForIndex,
  });

  final int itemCount;
  final double Function(int index) valueForIndex;

  @override
  Widget build(BuildContext context) {
    final count = math.max(1, itemCount);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List<Widget>.generate(count, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: itemCount <= 0 ? 0 : valueForIndex(index),
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.28),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }),
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
    final strings = context.strings;
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
                    children: <Widget>[
                      const Icon(
                        Icons.keyboard_double_arrow_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        strings.localized(
                          telugu:
                              'à°°à°¿à°ªà±à°²à±ˆà°²à± à°šà±‚à°¡à°¡à°¾à°¨à°¿à°•à°¿ à°ªà±ˆà°•à°¿ swipe à°šà±‡à°¯à°‚à°¡à°¿',
                          english: 'Swipe up for replies',
                        ),
                        style: const TextStyle(
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
    final strings = context.strings;
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
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu: 'à°°à°¿à°ªà±à°²à±ˆ à°ªà°‚à°ªà°¬à°¡à°¿à°‚à°¦à°¿',
              english: 'Reply sent',
            ),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          strings.localized(
            telugu:
                'à°°à°¿à°ªà±à°²à±ˆ à°µà°¿à°«à°²à°®à±ˆà°‚à°¦à°¿. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
            english: 'Reply failed. Try again.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
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
              hintText: strings.localized(
                telugu: 'à°°à°¿à°ªà±à°²à±ˆ...',
                english: 'Reply...',
              ),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onHeaderTap,
    required this.onCreateTap,
    required this.onStatusTap,
    required this.onProfileTap,
    required this.viewerPosterProfile,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.compact,
  });

  final VoidCallback onHeaderTap;
  final VoidCallback onCreateTap;
  final VoidCallback onStatusTap;
  final VoidCallback onProfileTap;
  final PosterProfileData viewerPosterProfile;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onSearchSubmitted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final topInset = MediaQuery.of(context).padding.top;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onHeaderTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          10,
          topInset + (compact ? 4 : 8),
          10,
          compact ? 5 : 9,
        ),
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.05,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  cursorColor: Colors.white,
                  onChanged: onSearchChanged,
                  onTapOutside: (_) => searchFocusNode.unfocus(),
                  onEditingComplete: () => unawaited(onSearchSubmitted()),
                  onSubmitted: (_) => unawaited(onSearchSubmitted()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: strings.searchTemplates,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                    prefixIcon: IconButton(
                      onPressed: () => unawaited(onSearchSubmitted()),
                      icon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    fillColor: Colors.white.withValues(alpha: 0.16),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                strings.localized(
                  telugu: 'à°•à±à°°à°¿à°¯à±‡à°Ÿà±',
                  english: 'Create',
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD81B60),
                minimumSize: const Size(93, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: strings.localized(
                telugu: 'à°¸à±à°Ÿà±‡à°Ÿà°¸à±â€Œà°²à±',
                english: 'Statuses',
              ),
              child: InkWell(
                onTap: onStatusTap,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: _HeaderStatusShortcut(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36,
                height: 36,
                child: _HeaderProfileAvatar(
                  viewerPosterProfile: viewerPosterProfile,
                ),
              ),
            ),
          ],
        ),
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

class _HeaderStatusShortcut extends StatefulWidget {
  const _HeaderStatusShortcut();

  @override
  State<_HeaderStatusShortcut> createState() => _HeaderStatusShortcutState();
}

class _HeaderStatusShortcutState extends State<_HeaderStatusShortcut> {
  Timer? _firebaseReadyRetryTimer;

  @override
  void initState() {
    super.initState();
    _scheduleFirebaseReadyRetryIfNeeded();
  }

  @override
  void dispose() {
    _firebaseReadyRetryTimer?.cancel();
    super.dispose();
  }

  void _scheduleFirebaseReadyRetryIfNeeded() {
    if (_shouldRunFirebaseUiServices || _firebaseReadyRetryTimer != null) {
      return;
    }
    _firebaseReadyRetryTimer = Timer.periodic(
      const Duration(milliseconds: 350),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_shouldRunFirebaseUiServices) {
          timer.cancel();
          _firebaseReadyRetryTimer = null;
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRunFirebaseUiServices) {
      _scheduleFirebaseReadyRetryIfNeeded();
      return const SizedBox(
        width: 30,
        height: 30,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add_rounded, color: Color(0xFF111827), size: 18),
        ),
      );
    }
    return StreamBuilder<List<CommunityStatus>>(
      stream: CommunityStatusService.instance.watchMyActiveStatuses(limit: 8),
      builder: (context, snapshot) {
        final statuses = snapshot.data ?? const <CommunityStatus>[];
        final latest = statuses.isEmpty ? null : statuses.first;
        final hasStatus = latest != null;
        return SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStatus
                        ? const SweepGradient(
                            colors: <Color>[
                              Color(0xFFFFD60A),
                              Color(0xFFFF4D8D),
                              Color(0xFF7C3AED),
                              Color(0xFFFFD60A),
                            ],
                          )
                        : null,
                    color: hasStatus
                        ? null
                        : Colors.white.withValues(alpha: 0.92),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: ClipOval(
                          child: ColoredBox(
                            color: hasStatus
                                ? Colors.white
                                : const Color(0xFFFFF7ED),
                            child: hasStatus
                                ? _StatusGridPreview(status: latest)
                                : const Icon(
                                    Icons.auto_stories_rounded,
                                    color: Color(0xFFD81B60),
                                    size: 17,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!hasStatus)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 9,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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

class _HomePinnedFeedControls extends StatelessWidget {
  const _HomePinnedFeedControls({
    required this.categories,
    required this.activeCategorySlug,
    required this.scrollController,
    required this.onCategoryTap,
    required this.banners,
    required this.showAdFallback,
    required this.shouldShowAdFallback,
    required this.homeRefreshing,
    required this.compact,
  });

  final List<_CategoryChipData> categories;
  final String activeCategorySlug;
  final ScrollController scrollController;
  final ValueChanged<String> onCategoryTap;
  final List<AppHomeBanner> banners;
  final bool showAdFallback;
  final bool shouldShowAdFallback;
  final bool homeRefreshing;
  final bool compact;
  static const double _categoryPanelHeight = 94;
  static const double _compactCategoryPanelHeight = 36;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF3F6FB)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: RepaintBoundary(
              child: SizedBox(
                height: compact
                    ? _compactCategoryPanelHeight
                    : _categoryPanelHeight,
                width: double.infinity,
                child: ClipRect(
                  child: _CategoryRowsScroller(
                    categories: categories,
                    activeCategorySlug: activeCategorySlug,
                    scrollController: scrollController,
                    onCategoryTap: onCategoryTap,
                    compact: compact,
                  ),
                ),
              ),
            ),
          ),
          if (!compact && banners.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            RepaintBoundary(child: _HomeHeroBanner(banners: banners)),
          ] else if (!compact &&
              showAdFallback &&
              shouldShowAdFallback) ...<Widget>[
            const SizedBox(height: 3),
            const RepaintBoundary(child: _HomeBannerAdFallback()),
          ],
          if (homeRefreshing)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }
}

class _CategoryRowsScroller extends StatefulWidget {
  const _CategoryRowsScroller({
    required this.categories,
    required this.activeCategorySlug,
    required this.scrollController,
    required this.onCategoryTap,
    required this.compact,
  });

  static const int _rowCount = 3;
  static const double _minChipWidth = 38;
  static const double _maxChipWidth = 184;
  static const double _maxSelectedMoreChipWidth = 132;
  static const double _maxDynamicChipWidth = 268;
  static const double _rowHeight = 30;
  static const double _rowGap = 1;
  static const double _columnGap = 3;
  static const int _layoutStrategyVersion = 3;

  final List<_CategoryChipData> categories;
  final String activeCategorySlug;
  final ScrollController scrollController;
  final ValueChanged<String> onCategoryTap;
  final bool compact;

  @override
  State<_CategoryRowsScroller> createState() => _CategoryRowsScrollerState();
}

class _CategoryRowsScrollerState extends State<_CategoryRowsScroller> {
  final Map<String, _CategoryChipSlot> _slotsBySlug =
      <String, _CategoryChipSlot>{};
  final Map<String, double> _slotWidthBySlug = <String, double>{};
  final List<List<String>> _slugRows = List<List<String>>.generate(
    _CategoryRowsScroller._rowCount,
    (_) => <String>[],
  );
  int _appliedLayoutStrategyVersion = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      final chips = _buildCompactRow();
      return SingleChildScrollView(
        key: const PageStorageKey<String>('home-category-horizontal-scroll'),
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          children: <Widget>[
            for (var index = 0; index < chips.length; index++) ...<Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: _CategoryRowsScroller._minChipWidth,
                  maxWidth: _CategoryRowsScroller._maxChipWidth,
                ),
                child: _CategoryChip(
                  data: chips[index],
                  isSelected:
                      chips[index].effectiveSelectionSlug ==
                      widget.activeCategorySlug,
                  onTap: () =>
                      widget.onCategoryTap(chips[index].effectiveSelectionSlug),
                ),
              ),
              if (index != chips.length - 1)
                const SizedBox(width: _CategoryRowsScroller._columnGap),
            ],
          ],
        ),
      );
    }
    final rows = _buildStableRows();
    return SingleChildScrollView(
      key: const PageStorageKey<String>('home-category-horizontal-scroll'),
      controller: widget.scrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
            Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == rows.length - 1
                    ? 0
                    : _CategoryRowsScroller._rowGap,
              ),
              child: SizedBox(
                height: _CategoryRowsScroller._rowHeight,
                child: Row(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < rows[rowIndex].length;
                      index++
                    ) ...<Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: _CategoryRowsScroller._minChipWidth,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: rows[rowIndex][index].isDynamic
                                ? _CategoryRowsScroller._maxDynamicChipWidth
                                : rows[rowIndex][index].slug ==
                                      _HomeScreenState
                                          ._selectedMoreCategorySlotSlug
                                ? _CategoryRowsScroller
                                      ._maxSelectedMoreChipWidth
                                : _CategoryRowsScroller._maxChipWidth,
                          ),
                          child: _CategoryChip(
                            key: ValueKey<String>(
                              'home-category-${rows[rowIndex][index].slug}',
                            ),
                            data: rows[rowIndex][index],
                            isSelected:
                                rows[rowIndex][index].effectiveSelectionSlug ==
                                widget.activeCategorySlug,
                            onTap: () => widget.onCategoryTap(
                              rows[rowIndex][index].effectiveSelectionSlug,
                            ),
                          ),
                        ),
                      ),
                      if (index != rows[rowIndex].length - 1)
                        const SizedBox(width: _CategoryRowsScroller._columnGap),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_CategoryChipData> _buildCompactRow() {
    final utility = <_CategoryChipData>[];
    final normal = <_CategoryChipData>[];
    final dynamic = <_CategoryChipData>[];
    for (final category in widget.categories) {
      if (category.slug == _HomeScreenState._moreCategorySlug ||
          category.selectionSlug != null ||
          category.slug == 'today_special' ||
          _HomeScreenState._morePopupCategorySlugs.contains(category.slug)) {
        utility.add(category);
      } else if (category.isDynamic) {
        dynamic.add(category);
      } else {
        normal.add(category);
      }
    }
    return <_CategoryChipData>[...normal, ...dynamic, ...utility];
  }

  List<List<_CategoryChipData>> _buildStableRows() {
    if (_appliedLayoutStrategyVersion !=
        _CategoryRowsScroller._layoutStrategyVersion) {
      _slotsBySlug.clear();
      _slotWidthBySlug.clear();
      for (final row in _slugRows) {
        row.clear();
      }
      _appliedLayoutStrategyVersion =
          _CategoryRowsScroller._layoutStrategyVersion;
    }
    final bySlug = <String, _CategoryChipData>{
      for (final category in widget.categories) category.slug: category,
    };
    _removeMissingSlugs(bySlug.keys.toSet());
    final newChips = widget.categories
        .where((category) => !_slotsBySlug.containsKey(category.slug))
        .toList(growable: false);
    _assignNewChips(newChips);
    _moveSelectedMoreSlotBeforeMore();
    return <List<_CategoryChipData>>[
      for (final row in _slugRows)
        <_CategoryChipData>[
          for (final slug in row)
            if (bySlug[slug] != null) bySlug[slug]!,
        ],
    ];
  }

  void _removeMissingSlugs(Set<String> visibleSlugs) {
    final missing = _slotsBySlug.keys
        .where((slug) => !visibleSlugs.contains(slug))
        .toList(growable: false);
    for (final slug in missing) {
      final slot = _slotsBySlug.remove(slug);
      _slotWidthBySlug.remove(slug);
      if (slot == null) {
        continue;
      }
      _slugRows[slot.row].remove(slug);
    }
    for (var rowIndex = 0; rowIndex < _slugRows.length; rowIndex++) {
      for (var index = 0; index < _slugRows[rowIndex].length; index++) {
        _slotsBySlug[_slugRows[rowIndex][index]] = _CategoryChipSlot(
          row: rowIndex,
          index: index,
        );
      }
    }
  }

  void _moveSelectedMoreSlotBeforeMore() {
    const selectedSlotSlug = _HomeScreenState._selectedMoreCategorySlotSlug;
    const moreSlotSlug = _HomeScreenState._moreCategorySlug;
    final selectedSlot = _slotsBySlug[selectedSlotSlug];
    final moreSlot = _slotsBySlug[moreSlotSlug];
    if (selectedSlot == null || moreSlot == null) {
      return;
    }
    final selectedRow = _slugRows[selectedSlot.row];
    final moreRow = _slugRows[moreSlot.row];
    final selectedIndex = selectedRow.indexOf(selectedSlotSlug);
    final moreIndex = moreRow.indexOf(moreSlotSlug);
    if (selectedIndex < 0 || moreIndex < 0) {
      return;
    }
    if (selectedSlot.row == moreSlot.row && selectedIndex == moreIndex - 1) {
      return;
    }
    selectedRow.removeAt(selectedIndex);
    final adjustedMoreIndex =
        selectedSlot.row == moreSlot.row && selectedIndex < moreIndex
        ? moreIndex - 1
        : moreIndex;
    moreRow.insert(adjustedMoreIndex, selectedSlotSlug);
    for (var rowIndex = 0; rowIndex < _slugRows.length; rowIndex++) {
      for (var index = 0; index < _slugRows[rowIndex].length; index++) {
        _slotsBySlug[_slugRows[rowIndex][index]] = _CategoryChipSlot(
          row: rowIndex,
          index: index,
        );
      }
    }
  }

  void _assignNewChips(List<_CategoryChipData> newChips) {
    if (newChips.isEmpty) {
      return;
    }
    _CategoryChipData? moreChip;
    final beforeMoreChips = <_CategoryChipData>[];
    final regularChips = <_CategoryChipData>[];

    for (final category in newChips) {
      if (category.slug == _HomeScreenState._moreCategorySlug) {
        moreChip = category;
      } else if (category.selectionSlug != null) {
        beforeMoreChips.add(category);
      } else if (_HomeScreenState._morePopupCategorySlugs.contains(
        category.slug,
      )) {
        beforeMoreChips.add(category);
      } else {
        regularChips.add(category);
      }
    }

    void appendToRow(int rowIndex, _CategoryChipData chip) {
      if (_slotsBySlug.containsKey(chip.slug)) {
        return;
      }
      final safeRowIndex = rowIndex.clamp(0, _slugRows.length - 1);
      final row = _slugRows[safeRowIndex];
      _slotsBySlug[chip.slug] = _CategoryChipSlot(
        row: safeRowIndex,
        index: row.length,
      );
      _slotWidthBySlug[chip.slug] = _estimatedChipWidth(chip);
      row.add(chip.slug);
    }

    void insertBeforeSlug(
      String targetSlug,
      int fallbackRowIndex,
      _CategoryChipData chip,
    ) {
      if (_slotsBySlug.containsKey(chip.slug)) {
        return;
      }
      final targetSlot = _slotsBySlug[targetSlug];
      if (targetSlot == null) {
        appendToRow(fallbackRowIndex, chip);
        return;
      }
      final row = _slugRows[targetSlot.row];
      final insertIndex = row.indexOf(targetSlug);
      if (insertIndex < 0) {
        appendToRow(fallbackRowIndex, chip);
        return;
      }
      row.insert(insertIndex, chip.slug);
      _slotWidthBySlug[chip.slug] = _estimatedChipWidth(chip);
      for (var index = insertIndex; index < row.length; index++) {
        _slotsBySlug[row[index]] = _CategoryChipSlot(
          row: targetSlot.row,
          index: index,
        );
      }
    }

    int shortestRowIndex() {
      var bestRow = 0;
      var bestWidth = double.infinity;
      for (var rowIndex = 0; rowIndex < _slugRows.length; rowIndex++) {
        final width = _rowEstimatedWidth(_slugRows[rowIndex]);
        if (width < bestWidth) {
          bestWidth = width;
          bestRow = rowIndex;
        }
      }
      return bestRow;
    }

    for (final chip in regularChips) {
      appendToRow(shortestRowIndex(), chip);
    }
    for (final chip in beforeMoreChips) {
      insertBeforeSlug(
        _HomeScreenState._moreCategorySlug,
        shortestRowIndex(),
        chip,
      );
    }
    if (moreChip != null) {
      appendToRow(shortestRowIndex(), moreChip);
    }
  }

  double _rowEstimatedWidth(List<String> row) {
    if (row.isEmpty) {
      return 0;
    }
    return row.fold<double>(
          0,
          (total, slug) => total + (_slotWidthBySlug[slug] ?? 96),
        ) +
        ((row.length - 1) * _CategoryRowsScroller._columnGap);
  }

  double _estimatedChipWidth(_CategoryChipData chip) {
    final cleanLabel = CategoryDisplayHelper.stripIcon(chip.label).trim();
    final dateExtra = (chip.dateLabel?.trim().isNotEmpty ?? false) ? 28 : 0;
    final iconExtra =
        chip.iconAssetPath != null ||
            CategoryDisplayHelper.assetPathFor(
                  chip.selectionSlug ?? chip.slug,
                  chip.label,
                ) !=
                null
        ? 22
        : 0;
    final rawWidth = 26 + iconExtra + dateExtra + (cleanLabel.length * 8.5);
    final maxWidth = chip.isDynamic
        ? _CategoryRowsScroller._maxDynamicChipWidth
        : chip.slug == _HomeScreenState._selectedMoreCategorySlotSlug
        ? _CategoryRowsScroller._maxSelectedMoreChipWidth
        : _CategoryRowsScroller._maxChipWidth;
    return rawWidth.clamp(_CategoryRowsScroller._minChipWidth, maxWidth);
  }
}

class _HomeHeroBanner extends StatefulWidget {
  const _HomeHeroBanner({required this.banners});

  final List<AppHomeBanner> banners;

  @override
  State<_HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<_HomeHeroBanner> {
  static const double _bannerAspectRatio = 1080 / 190;
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
  static const int _maxLoadAttempts = 3;

  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _loadAttempted = false;
  bool _isLoaded = false;
  int _loadAttemptCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadAttempted) {
      return;
    }
    _loadAttempted = true;
    unawaited(_loadBanner());
  }

  void _scheduleRetry() {
    if (!mounted || _isLoaded || _loadAttemptCount >= _maxLoadAttempts) {
      return;
    }
    Future<void>.delayed(const Duration(seconds: 12), () {
      if (!mounted || _isLoaded) {
        return;
      }
      unawaited(_loadBanner());
    });
  }

  Future<void> _loadBanner() async {
    if (kIsWeb || !Platform.isAndroid || !AppPublicInfo.hasHomeBannerAdUnitId) {
      return;
    }
    _loadAttemptCount += 1;
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
      await AdMobConsentService.instance.prepareForAds();
    }
    if (!await AdMobConsentService.instance.canRequestAds()) {
      _scheduleRetry();
      return;
    }
    try {
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (!mounted) {
      return;
    }
    final adaptiveSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      availableWidth.truncate(),
    );
    if (!mounted || adaptiveSize == null) {
      _scheduleRetry();
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
          _scheduleRetry();
        },
      ),
    );
    try {
      await banner.load();
    } catch (error) {
      banner.dispose();
      _homeDebugLog('home banner ad load exception: $error');
      _scheduleRetry();
    }
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
    super.key,
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
    final displaySlug = data.selectionSlug ?? data.slug;
    final iconAssetPath =
        data.iconAssetPath ??
        CategoryDisplayHelper.assetPathFor(displaySlug, data.label);
    final cleanLabel = CategoryDisplayHelper.stripIcon(data.label);
    final dateLabel = data.dateLabel?.trim();
    final showDate =
        data.isDynamic && dateLabel != null && dateLabel.isNotEmpty;
    const selectedChipColor = Color(0xFF6D28D9);
    const selectedChipBorder = Color(0xFF5B21B6);
    const allChipColor = Color(0xFF25D366);
    const allChipBorder = Color(0xFF1FAE54);
    final chipTint = isAll && isSelected
        ? allChipColor
        : isSelected
        ? selectedChipColor
        : data.isDynamic
        ? const Color(0xFFFFF4DB)
        : Colors.white;
    final borderColor = isAll && isSelected
        ? allChipBorder
        : isSelected
        ? selectedChipBorder
        : data.isDynamic
        ? const Color(0xFFF2C66D)
        : const Color(0xFFDCE6F3);
    final textColor = isSelected
        ? Colors.white
        : data.isDynamic
        ? const Color(0xFF8A5A00)
        : const Color(0xFF334155);
    final secondaryTextColor = isSelected
        ? Colors.white.withValues(alpha: 0.82)
        : textColor.withValues(alpha: 0.78);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: BoxConstraints(minHeight: showDate ? 29 : 27),
          padding: EdgeInsets.symmetric(
            horizontal: showDate ? 7 : 8,
            vertical: showDate ? 2.5 : 3.5,
          ),
          decoration: BoxDecoration(
            color: chipTint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isSelected || isAll
                    ? const Color(0x140F172A)
                    : const Color(0x0A0F172A),
                blurRadius: isSelected || isAll ? 5 : 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (iconAssetPath != null) ...<Widget>[
                _CategoryChipAssetIcon(assetPath: iconAssetPath),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: showDate
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            cleanLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 9.8,
                              height: 1.02,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 8.5,
                              height: 1.0,
                              fontWeight: FontWeight.w700,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        cleanLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10.4,
                          fontWeight: FontWeight.w600,
                          color: textColor,
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

class _CategoryChipAssetIcon extends StatelessWidget {
  const _CategoryChipAssetIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final normalized = assetPath.trim();
    final lower = normalized.toLowerCase();
    final isNetwork = lower.startsWith('https://');
    final isSvg = lower.endsWith('.svg') || lower.contains('.svg?');
    return Container(
      width: 15,
      height: 15,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: isNetwork
          ? (isSvg
                ? SvgPicture.network(
                    normalized,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) =>
                        const _CategoryChipFallbackIcon(),
                  )
                : Image.network(
                    normalized,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const _CategoryChipFallbackIcon(),
                  ))
          : (isSvg
                ? SvgPicture.asset(
                    normalized,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) =>
                        const _CategoryChipFallbackIcon(),
                  )
                : Image.asset(
                    normalized,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const _CategoryChipFallbackIcon(),
                  )),
    );
  }
}

class _CategoryChipFallbackIcon extends StatelessWidget {
  const _CategoryChipFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.category_rounded,
      size: 11,
      color: Color(0xFF64748B),
    );
  }
}

// ignore: unused_element
String _subscriptionPromptCopyLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'à°ªà±‹à°¸à±à°Ÿà°°à±à°²à°¨à± à°·à±‡à°°à± à°²à±‡à°¦à°¾ à°¡à±Œà°¨à±â€Œà°²à±‹à°¡à± à°šà±‡à°¯à°¡à°¾à°¨à°¿à°•à°¿ à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à± à°¯à°¾à°•à±à°Ÿà°¿à°µà± à°šà±‡à°¯à°¾à°²à°¿.',
    english: 'Activate subscription to share or download posters.',
  );
}

// ignore: unused_element
String _subscriptionDialogTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à± à°…à°µà°¸à°°à°‚',
    english: 'Subscription Required',
  );
}

// ignore: unused_element
String _subscriptionTrialTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 à°°à±‹à°œà±à°² à°Ÿà±à°°à°¯à°²à± à°ªà±à°²à°¾à°¨à±',
    english: '3-day trial plan',
  );
}

// ignore: unused_element
String _subscriptionTrialValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°²à°•à± ${SubscriptionPlanConfig.trialPriceDisplay}',
    english:
        '${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days',
  );
}

// ignore: unused_element
String _subscriptionMonthlyTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¨à±†à°²à°µà°¾à°°à±€ à°ªà±à°²à°¾à°¨à±',
    english: 'Monthly plan',
  );
}

// ignore: unused_element
String _subscriptionMonthlyValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'à°¤à°°à±à°µà°¾à°¤ à°¨à±†à°²à°•à± ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    english: '${SubscriptionPlanConfig.monthlyPriceDisplay} per month',
  );
}

// ignore: unused_element
String _subscriptionRenewalCopyLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°² à°Ÿà±à°°à°¯à°²à± à°ªà±‚à°°à±à°¤à°¯à±à°¯à°¾à°• à°®à±€à°°à± à°•à±à°¯à°¾à°¨à±à°¸à°¿à°²à± à°šà±‡à°¯à°•à°ªà±‹à°¤à±‡ à°¨à±†à°²à°•à± ${SubscriptionPlanConfig.monthlyPriceDisplay} à°†à°Ÿà±‹ à°°à±€à°¨à±à°¯à±à°µà°²à± à°…à°µà±à°¤à±à°‚à°¦à°¿. ${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°² à°²à±‹à°ªà± à°•à±à°¯à°¾à°¨à±à°¸à°¿à°²à± à°šà±‡à°¸à±à°¤à±‡ à°¨à±†à°²à°µà°¾à°°à±€ à°›à°¾à°°à±à°œà± à°ªà°¡à°¦à±. à°•à±à°¯à°¾à°¨à±à°¸à°¿à°²à± à°šà±‡à°¸à°¿à°¨à°¾ à°ªà±à°°à°¸à±à°¤à±à°¤ à°ªà±à°²à°¾à°¨à± à°—à°¡à±à°µà± à°®à±à°—à°¿à°¸à±‡ à°µà°°à°•à± à°¬à±†à°¨à°¿à°«à°¿à°Ÿà±à°¸à± à°‰à°ªà°¯à±‹à°—à°¿à°‚à°šà°µà°šà±à°šà±.',
    english:
        'After the ${SubscriptionPlanConfig.trialDays}-day trial, it auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay}/month unless cancelled. If cancelled within ${SubscriptionPlanConfig.trialDays} days, the monthly charge does not apply. Benefits continue until the current plan expires.',
  );
}

// ignore: unused_element
String _subscriptionTermsLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¨à°¿à°¬à°‚à°§à°¨à°²à±',
    english: 'Terms',
  );
}

// ignore: unused_element
String _subscriptionSkipLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¸à±à°•à°¿à°ªà±',
    english: 'Skip',
  );
}

// ignore: unused_element
String _subscriptionButtonLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à±ˆà°¬à± à°šà±‡à°¯à°‚à°¡à°¿',
    english: 'Subscribe',
  );
}

String _subscriptionPromptCopyCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'à°ªà±‹à°¸à±à°Ÿà°°à±à°²à°¨à± à°·à±‡à°°à± à°²à±‡à°¦à°¾ à°¡à±Œà°¨à±â€Œà°²à±‹à°¡à± à°šà±‡à°¯à°¡à°¾à°¨à°¿à°•à°¿ à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à± à°¯à°¾à°•à±à°Ÿà°¿à°µà± à°šà±‡à°¯à°‚à°¡à°¿.',
    english: 'Activate subscription to share or download posters.',
  );
}

String _subscriptionDialogTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à± à°…à°µà°¸à°°à°‚',
    english: 'Subscription Required',
  );
}

String _subscriptionTrialTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 à°°à±‹à°œà±à°² à°Ÿà±à°°à°¯à°²à± à°ªà±à°²à°¾à°¨à±',
    english: '3-day trial plan',
  );
}

String _subscriptionTrialValueCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°²à°•à± ${SubscriptionPlanConfig.trialPriceDisplay}',
    english:
        '${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days',
  );
}

String _subscriptionMonthlyTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¨à±†à°²à°µà°¾à°°à±€ à°ªà±à°²à°¾à°¨à±',
    english: 'Monthly plan',
  );
}

String _subscriptionMonthlyValueCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'à°¤à°°à±à°µà°¾à°¤ à°¨à±†à°²à°•à± ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    english: '${SubscriptionPlanConfig.monthlyPriceDisplay} per month',
  );
}

String _subscriptionRenewalCopyCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°² à°Ÿà±à°°à°¯à°²à± à°¤à°°à±à°µà°¾à°¤, à°°à°¦à±à°¦à± à°šà±‡à°¯à°•à°ªà±‹à°¤à±‡ à°¨à±†à°²à°•à± ${SubscriptionPlanConfig.monthlyPriceDisplay} à°†à°Ÿà±‹ à°°à±†à°¨à±à°¯à±à°µà°²à± à°…à°µà±à°¤à±à°‚à°¦à°¿. ${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°²à±à°²à±‹ à°°à°¦à±à°¦à± à°šà±‡à°¸à±à°¤à±‡ à°¨à±†à°²à°µà°¾à°°à±€ à°›à°¾à°°à±à°œà± à°ªà°¡à°¦à±. à°°à°¦à±à°¦à± à°šà±‡à°¸à°¿à°¨à°¾ à°ªà±à°°à°¸à±à°¤à±à°¤ à°ªà±à°²à°¾à°¨à± à°—à°¡à±à°µà± à°®à±à°—à°¿à°¸à±‡ à°µà°°à°•à± à°¬à±†à°¨à°¿à°«à°¿à°Ÿà±à°¸à± à°•à±Šà°¨à°¸à°¾à°—à±à°¤à°¾à°¯à°¿.',
    english:
        'After the ${SubscriptionPlanConfig.trialDays}-day trial, it auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay}/month unless cancelled. If cancelled within ${SubscriptionPlanConfig.trialDays} days, the monthly charge does not apply. Benefits continue until the current plan expires.',
  );
}

String _subscriptionTermsLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¨à°¿à°¬à°‚à°§à°¨à°²à±',
    english: 'Terms',
  );
}

String _subscriptionSkipLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¸à±à°•à°¿à°ªà±',
    english: 'Skip',
  );
}

String _subscriptionButtonLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à±ˆà°¬à± à°šà±‡à°¯à°‚à°¡à°¿',
    english: 'Subscribe',
  );
}

String _posterShareLabel(BuildContext context) {
  return context.strings.localized(telugu: 'à°·à±‡à°°à±', english: 'Share');
}

class _VideoSideActions extends StatelessWidget {
  const _VideoSideActions({
    required this.activeActionListenable,
    required this.videoExportReadyListenable,
    required this.onShareTap,
    required this.onDownloadTap,
  });

  final ValueListenable<String?> activeActionListenable;
  final ValueListenable<bool> videoExportReadyListenable;
  final VoidCallback onShareTap;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return ValueListenableBuilder<String?>(
      valueListenable: activeActionListenable,
      builder: (context, activeAction, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: videoExportReadyListenable,
          builder: (context, videoReady, _) {
            final actionsEnabled = activeAction == null && videoReady;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _VideoSideActionButton(
                      icon: Image.asset(
                        'assets/branding/whatsapp_icon.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.share_rounded, size: 20),
                      ),
                      label: _posterShareLabel(context),
                      color: const Color(0xFF25D366),
                      busy: activeAction == 'share',
                      enabled: actionsEnabled,
                      onTap: onShareTap,
                    ),
                    const SizedBox(height: 12),
                    _VideoSideActionButton(
                      icon: const Icon(Icons.download_rounded, size: 23),
                      label: strings.downloadLabel,
                      color: const Color(0xFF334155),
                      busy: activeAction == 'download',
                      enabled: actionsEnabled,
                      onTap: onDownloadTap,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VideoSideActionButton extends StatelessWidget {
  const _VideoSideActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color color;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? Colors.white : Colors.white70;
    return Opacity(
      opacity: enabled || busy ? 1 : 0.58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            child: InkWell(
              onTap: enabled ? onTap : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : IconTheme(
                          data: IconThemeData(color: foreground),
                          child: icon,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
              shadows: const <Shadow>[
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoliticalProtocolPhotoSlots extends StatelessWidget {
  const _PoliticalProtocolPhotoSlots({
    required this.assetPaths,
    required this.imageUrls,
    required this.slots,
    this.assetSlots = const <PoliticalProtocolSlot>[],
  });

  final List<String> assetPaths;
  final List<String> imageUrls;
  final List<PoliticalProtocolSlot> slots;
  final List<PoliticalProtocolSlot> assetSlots;

  static double _slotSide({
    required double canvasWidth,
    required double canvasHeight,
    required double scale,
  }) {
    final baseSide = math.min(canvasWidth, canvasHeight) * 0.15;
    return math.max(1.0, baseSide * (scale / 100));
  }

  static double _slotCenter({
    required double value,
    required double canvasExtent,
    required double side,
  }) {
    final halfPercent = (side / math.max(1.0, canvasExtent)) * 50;
    return value.clamp(halfPercent, 100 - halfPercent).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final visibleUrls = imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .take(slots.length)
        .toList(growable: false);
    final visiblePaths = assetPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final totalCount = visibleUrls.length + visiblePaths.length;
    if (totalCount == 0) {
      return const SizedBox.shrink();
    }
    final resolvedSlots = slots.length >= defaultPoliticalProtocolSlots.length
        ? slots
              .take(defaultPoliticalProtocolSlots.length)
              .toList(growable: false)
        : defaultPoliticalProtocolSlots;
    final resolvedAssetSlots = assetSlots.length >= visiblePaths.length
        ? assetSlots.take(visiblePaths.length).toList(growable: false)
        : _fallbackManualSlots(visiblePaths.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = math.max(1.0, constraints.maxWidth);
        final canvasHeight = math.max(1.0, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (var index = 0; index < visibleUrls.length; index += 1)
              Builder(
                builder: (context) {
                  final slot = resolvedSlots[index];
                  final side = _slotSide(
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    scale: slot.scale,
                  );
                  final centerX = _slotCenter(
                    value: slot.x,
                    canvasExtent: canvasWidth,
                    side: side,
                  );
                  final centerY = _slotCenter(
                    value: slot.y,
                    canvasExtent: canvasHeight,
                    side: side,
                  );
                  final child = CachedNetworkImage(
                    imageUrl: visibleUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _PoliticalProtocolFallback(),
                    errorWidget: (_, _, _) =>
                        const _PoliticalProtocolFallback(),
                  );
                  return Positioned(
                    left: (canvasWidth * (centerX / 100)) - (side / 2),
                    top: (canvasHeight * (centerY / 100)) - (side / 2),
                    width: side,
                    height: side,
                    child: _PoliticalProtocolCircle(side: side, child: child),
                  );
                },
              ),
            for (var index = 0; index < visiblePaths.length; index += 1)
              Builder(
                builder: (context) {
                  final slot = resolvedAssetSlots[index];
                  final side = _slotSide(
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    scale: slot.scale,
                  );
                  final centerX = _slotCenter(
                    value: slot.x,
                    canvasExtent: canvasWidth,
                    side: side,
                  );
                  final centerY = _slotCenter(
                    value: slot.y,
                    canvasExtent: canvasHeight,
                    side: side,
                  );
                  final child = _buildPoliticalProtocolAsset(
                    visiblePaths[index],
                  );
                  return Positioned(
                    left: (canvasWidth * (centerX / 100)) - (side / 2),
                    top: (canvasHeight * (centerY / 100)) - (side / 2),
                    width: side,
                    height: side,
                    child: _PoliticalProtocolCircle(side: side, child: child),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  List<PoliticalProtocolSlot> _fallbackManualSlots(int count) {
    return List<PoliticalProtocolSlot>.generate(count, (index) {
      final row = index ~/ 4;
      final col = index % 4;
      return PoliticalProtocolSlot(
        x: (22 + (col * 18)).clamp(8, 92).toDouble(),
        y: (22 + (row * 14)).clamp(8, 92).toDouble(),
        scale: 100,
      );
    }, growable: false);
  }

  Widget _buildPoliticalProtocolAsset(String path) {
    final source = path.trim();
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PoliticalProtocolFallback(),
        errorWidget: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    if (source.contains(Platform.pathSeparator)) {
      return Image.file(
        File(source),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
    );
  }
}

class _PoliticalProtocolFallback extends StatelessWidget {
  const _PoliticalProtocolFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE2E8F0),
      child: Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 18),
    );
  }
}

class _PoliticalProtocolCircle extends StatelessWidget {
  const _PoliticalProtocolCircle({required this.side, required this.child});

  final double side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: side,
      height: side,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 0.8,
        ),
      ),
      child: ClipOval(child: child),
    );
  }
}

class _PoliticalProtocolPhotoScreenResult {
  const _PoliticalProtocolPhotoScreenResult({
    required this.manualPhotoPaths,
    required this.defaultSlots,
    required this.manualSlots,
  });

  final List<String> manualPhotoPaths;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<PoliticalProtocolSlot> manualSlots;
}

class _PoliticalProtocolPhotoScreen extends StatefulWidget {
  const _PoliticalProtocolPhotoScreen({
    required this.item,
    required this.language,
    required this.viewerPosterProfile,
    required this.politicalProtocolPhotoUrls,
    required this.showDefaultProtocolPhotos,
    required this.initialManualPhotoPaths,
    required this.defaultSlots,
    required this.initialManualSlots,
    required this.ensureSubscriptionAccess,
    required this.ensureGallerySavePermission,
    required this.leaderPhotoLibraryScopeKey,
  });

  final _TemplateItem item;
  final AppLanguage language;
  final PosterProfileData viewerPosterProfile;
  final List<String> politicalProtocolPhotoUrls;
  final bool showDefaultProtocolPhotos;
  final List<String> initialManualPhotoPaths;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<PoliticalProtocolSlot> initialManualSlots;
  final Future<bool> Function(BuildContext context) ensureSubscriptionAccess;
  final Future<bool> Function() ensureGallerySavePermission;
  final String leaderPhotoLibraryScopeKey;

  @override
  State<_PoliticalProtocolPhotoScreen> createState() =>
      _PoliticalProtocolPhotoScreenState();
}

class _PoliticalProtocolPhotoScreenState
    extends State<_PoliticalProtocolPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScreenshotController _customPosterScreenshotController =
      ScreenshotController();
  late List<String> _manualPhotoPaths;
  late List<PoliticalProtocolSlot> _defaultSlots;
  late List<PoliticalProtocolSlot> _manualSlots;
  double? _posterImageAspectRatio;
  String? _posterImageAspectKey;
  String? _customPosterPath;
  String? _exportAction;
  List<String> _savedLeaderPhotoPaths = const <String>[];
  ImageStream? _posterImageStream;
  ImageStreamListener? _posterImageStreamListener;
  bool _busy = false;
  int? _deleteArmedManualIndex;

  @override
  void initState() {
    super.initState();
    _manualPhotoPaths = widget.initialManualPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: true);
    _defaultSlots = _normalizeDefaultProtocolSlots(widget.defaultSlots);
    _manualSlots = _normalizeManualProtocolSlots(
      widget.initialManualSlots,
      _manualPhotoPaths.length,
    );
    unawaited(_loadSavedLeaderPhotoPaths());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvePosterImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _PoliticalProtocolPhotoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.imageUrl != widget.item.imageUrl ||
        oldWidget.item.imageAssetPath != widget.item.imageAssetPath) {
      _resolvePosterImageAspectRatio(force: true);
    }
  }

  @override
  void dispose() {
    _clearPosterImageListener();
    super.dispose();
  }

  void _clearPosterImageListener() {
    final stream = _posterImageStream;
    final listener = _posterImageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _posterImageStream = null;
    _posterImageStreamListener = null;
  }

  void _resolvePosterImageAspectRatio({bool force = false}) {
    final customPosterPath = _customPosterPath?.trim() ?? '';
    final imageUrl = widget.item.imageUrl?.trim() ?? '';
    final assetPath = widget.item.imageAssetPath?.trim() ?? '';
    final nextKey = customPosterPath.isNotEmpty
        ? 'file:$customPosterPath'
        : imageUrl.isNotEmpty
        ? 'network:$imageUrl'
        : assetPath.isNotEmpty
        ? 'asset:$assetPath'
        : '';
    if (!force && nextKey == _posterImageAspectKey) {
      return;
    }
    _posterImageAspectKey = nextKey;
    _posterImageAspectRatio = widget.item.pageConfig?.aspectRatio;
    _clearPosterImageListener();
    if (nextKey.isEmpty) {
      return;
    }
    final ImageProvider provider = customPosterPath.isNotEmpty
        ? FileImage(File(customPosterPath))
        : imageUrl.isNotEmpty
        ? CachedNetworkImageProvider(imageUrl)
        : AssetImage(assetPath);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      final width = info.image.width;
      final height = info.image.height;
      if (width <= 0 || height <= 0) {
        return;
      }
      final ratio = width / height;
      if (!mounted) {
        return;
      }
      final currentRatio = _posterImageAspectRatio;
      if (currentRatio != null && (currentRatio - ratio).abs() < 0.001) {
        return;
      }
      setState(() => _posterImageAspectRatio = ratio);
    }, onError: (_, _) {});
    _posterImageStream = stream;
    _posterImageStreamListener = listener;
    stream.addListener(listener);
  }

  List<PoliticalProtocolSlot> _normalizeDefaultProtocolSlots(
    List<PoliticalProtocolSlot> raw,
  ) {
    final source = raw.length >= defaultPoliticalProtocolSlots.length
        ? raw
        : defaultPoliticalProtocolSlots;
    return source
        .take(defaultPoliticalProtocolSlots.length)
        .map(
          (slot) => PoliticalProtocolSlot(
            x: slot.x.clamp(4.0, 96.0).toDouble(),
            y: slot.y.clamp(4.0, 96.0).toDouble(),
            scale: slot.scale.clamp(45.0, 135.0).toDouble(),
          ),
        )
        .toList(growable: true);
  }

  List<PoliticalProtocolSlot> _normalizeManualProtocolSlots(
    List<PoliticalProtocolSlot> raw,
    int count,
  ) {
    return List<PoliticalProtocolSlot>.generate(count, (index) {
      final fallback = _defaultManualSlot(index);
      final slot = index < raw.length ? raw[index] : fallback;
      return PoliticalProtocolSlot(
        x: slot.x.clamp(4.0, 96.0).toDouble(),
        y: slot.y.clamp(4.0, 96.0).toDouble(),
        scale: slot.scale.clamp(45.0, 135.0).toDouble(),
      );
    }, growable: true);
  }

  PoliticalProtocolSlot _defaultManualSlot(int index) {
    final row = index ~/ 4;
    final col = index % 4;
    return PoliticalProtocolSlot(
      x: (22 + (col * 18)).clamp(8, 92).toDouble(),
      y: (24 + (row * 14)).clamp(8, 92).toDouble(),
      scale: 100,
    );
  }

  String get _leaderPhotoLibraryPrefsKey {
    final scope = widget.leaderPhotoLibraryScopeKey.trim().isNotEmpty
        ? widget.leaderPhotoLibraryScopeKey.trim()
        : 'political';
    return 'political_leader_photo_library_v1_$scope';
  }

  Future<void> _loadSavedLeaderPhotoPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths =
          prefs
              .getStringList(_leaderPhotoLibraryPrefsKey)
              ?.map((path) => path.trim())
              .where((path) => path.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (!mounted) {
        return;
      }
      setState(() => _savedLeaderPhotoPaths = paths);
    } catch (_) {
      // Local leader photo library is optional.
    }
  }

  Future<void> _persistSavedLeaderPhotoPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _leaderPhotoLibraryPrefsKey,
      _savedLeaderPhotoPaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
    );
  }

  Future<void> _saveLeaderPhotoPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      final next = _savedLeaderPhotoPaths.toList(growable: true);
      next.remove(trimmed);
      next.add(trimmed);
      _savedLeaderPhotoPaths = next;
    });
    await _persistSavedLeaderPhotoPaths();
  }

  Future<void> _deleteSavedLeaderPhoto(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _savedLeaderPhotoPaths = _savedLeaderPhotoPaths
          .where((existing) => existing.trim() != trimmed)
          .toList(growable: false);
      for (var index = _manualPhotoPaths.length - 1; index >= 0; index -= 1) {
        if (_manualPhotoPaths[index].trim() == trimmed) {
          _manualPhotoPaths.removeAt(index);
          if (index < _manualSlots.length) {
            _manualSlots.removeAt(index);
          }
        }
      }
      _manualSlots = _normalizeManualProtocolSlots(
        _manualSlots,
        _manualPhotoPaths.length,
      );
      _deleteArmedManualIndex = null;
    });
    await _persistSavedLeaderPhotoPaths();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      await _deleteProtocolPhotoFile(File(trimmed));
    }
  }

  void _insertProtocolPhotoSource(String source, {int? insertIndex}) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      final boundedIndex = insertIndex == null
          ? _manualPhotoPaths.length
          : insertIndex.clamp(0, _manualPhotoPaths.length).toInt();
      _manualPhotoPaths.insert(boundedIndex, trimmed);
      _manualSlots.insert(boundedIndex, _defaultManualSlot(boundedIndex));
      _manualSlots = _normalizeManualProtocolSlots(
        _manualSlots,
        _manualPhotoPaths.length,
      );
      _deleteArmedManualIndex = null;
    });
  }

  Future<void> _addPhoto({
    int? insertIndex,
    bool saveToLeaderLibrary = false,
  }) async {
    if (_busy) {
      return;
    }
    final existingCount =
        widget.politicalProtocolPhotoUrls
            .where((url) => url.trim().isNotEmpty)
            .length +
        _manualPhotoPaths.length;
    if (existingCount > 1000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu:
                  'à°®à±Šà°¤à±à°¤à°‚ 6 à°«à±‹à°Ÿà±‹à°²à± à°®à°¾à°¤à±à°°à°®à±‡ à°ªà±†à°Ÿà±à°Ÿà°µà°šà±à°šà±.',
              english: 'You can add up to 6 photos only.',
            ),
          ),
        ),
      );
      return;
    }
    final cropTitle = context.strings.localized(
      telugu: 'à°«à±‹à°Ÿà±‹ à°•à±à°°à°¾à°ªà± à°šà±‡à°¯à°‚à°¡à°¿',
      english: 'Crop Photo',
    );
    setState(() => _busy = true);
    File? stagedFile;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      stagedFile = File(picked.path);
      final cropped = await ImageCropper().cropImage(
        sourcePath: stagedFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 96,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF0F172A),
            activeControlsWidgetColor: const Color(0xFF14B8A6),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white54,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            aspectRatioPresets: <CropAspectRatioPreset>[
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: cropTitle,
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      if (cropped == null) {
        return;
      }
      final bytes = await File(cropped.path).readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final path =
          '${dir.path}${Platform.pathSeparator}political_protocol_$stamp.png';
      await File(path).writeAsBytes(bytes, flush: true);
      if (!mounted) {
        return;
      }
      if (saveToLeaderLibrary) {
        await _saveLeaderPhotoPath(path);
        if (!mounted) {
          return;
        }
      }
      _insertProtocolPhotoSource(path, insertIndex: insertIndex);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu:
                  'à°«à±‹à°Ÿà±‹ à°œà±‹à°¡à°¿à°‚à°šà°²à±‡à°•à°ªà±‹à°¯à°¾à°‚. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
              english: 'Could not add the photo. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _removeManualPhoto(int manualIndex) {
    if (manualIndex < 0 || manualIndex >= _manualPhotoPaths.length) {
      return;
    }
    final removedPath = _manualPhotoPaths.removeAt(manualIndex);
    if (manualIndex < _manualSlots.length) {
      _manualSlots.removeAt(manualIndex);
    }
    if (!removedPath.startsWith('http://') &&
        !removedPath.startsWith('https://')) {
      unawaited(_deleteProtocolPhotoFile(File(removedPath)));
    }
    setState(() => _deleteArmedManualIndex = null);
  }

  Future<void> _deleteProtocolPhotoFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Local protocol photos are disposable UI assets.
    }
  }

  Future<void> _pickCustomPoster() async {
    if (_busy || _exportAction != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      final pickedFile = File(picked.path);
      final pickedName = picked.path.split(RegExp(r'[\\/]')).last;
      final dotIndex = pickedName.lastIndexOf('.');
      final extension = dotIndex >= 0 ? pickedName.substring(dotIndex) : '.jpg';
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final path =
          '${dir.path}${Platform.pathSeparator}political_custom_poster_$stamp$extension';
      await pickedFile.copy(path);
      if (!mounted) {
        return;
      }
      setState(() {
        _customPosterPath = path;
        _deleteArmedManualIndex = null;
      });
      _resolvePosterImageAspectRatio(force: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showScreenSnack(
        context.strings.localized(
          telugu: 'Could not add your poster. Please try again.',
          english: 'Could not add your poster. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _captureCustomPosterFile() async {
    await WidgetsBinding.instance.endOfFrame;
    final bytes = await _customPosterScreenshotController.capture(
      pixelRatio: 3,
    );
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}mana_political_poster_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String get _customPosterShareText {
    final activeName = widget.viewerPosterProfile.activeName.trim();
    final resolvedName = widget.viewerPosterProfile
        .resolvedName(language: widget.language)
        .trim();
    final userName = activeName.isNotEmpty
        ? activeName
        : resolvedName.isNotEmpty
        ? resolvedName
        : 'User';
    return 'Shared by $userName using ${AppPublicInfo.appName}\n'
        'Download the app: ${AppPublicInfo.playStoreUrl}';
  }

  Future<void> _downloadCustomPoster() async {
    if (_exportAction != null) {
      return;
    }
    setState(() => _exportAction = 'download');
    final galleryPermissionMessage = context.strings.localized(
      telugu: 'Gallery permission was denied.',
      english: 'Gallery permission was denied.',
    );
    final captureFailedMessage = context.strings.localized(
      telugu: 'Capture failed. Please try again.',
      english: 'Capture failed. Please try again.',
    );
    final savedMessage = context.strings.localized(
      telugu: 'Poster saved to gallery.',
      english: 'Poster saved to gallery.',
    );
    final downloadFailedMessage = context.strings.localized(
      telugu: 'Download failed. Please try again.',
      english: 'Download failed. Please try again.',
    );
    try {
      final hasAccess = await widget.ensureSubscriptionAccess(context);
      if (!hasAccess) {
        return;
      }
      final hasPermission = await widget.ensureGallerySavePermission();
      if (!hasPermission) {
        _showScreenSnack(galleryPermissionMessage);
        return;
      }
      final path = await _captureCustomPosterFile();
      if (path == null) {
        _showScreenSnack(captureFailedMessage);
        return;
      }
      final saveResult = await MediaExportService.saveImageFileToGalleryDetailed(
        path,
        fileName:
            'mana_political_poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      _showScreenSnack(
        saveResult.success ? savedMessage : downloadFailedMessage,
      );
    } catch (_) {
      _showScreenSnack(downloadFailedMessage);
    } finally {
      if (mounted) {
        setState(() => _exportAction = null);
      }
    }
  }

  Future<void> _shareCustomPoster() async {
    if (_exportAction != null) {
      return;
    }
    setState(() => _exportAction = 'share');
    final captureFailedMessage = context.strings.localized(
      telugu: 'Capture failed. Please try again.',
      english: 'Capture failed. Please try again.',
    );
    final shareFailedMessage = context.strings.localized(
      telugu: 'Share failed. Please try again.',
      english: 'Share failed. Please try again.',
    );
    try {
      final hasAccess = await widget.ensureSubscriptionAccess(context);
      if (!hasAccess) {
        return;
      }
      final path = await _captureCustomPosterFile();
      if (path == null) {
        _showScreenSnack(captureFailedMessage);
        return;
      }
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        path,
        text: _customPosterShareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      _showScreenSnack(shareFailedMessage);
    } finally {
      if (mounted) {
        setState(() => _exportAction = null);
      }
    }
  }

  void _showScreenSnack(String message) {
    if (!mounted || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPhotoSlot({
    required double side,
    required Widget child,
    required bool isPlus,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPlus
              ? const Color(0xFF14B8A6)
              : Colors.white.withValues(alpha: 0.95),
          border: Border.all(color: Colors.white, width: 0.8),
        ),
        child: ClipOval(child: child),
      ),
    );
  }

  Widget _buildProtocolPhotoSource(String source) {
    final trimmed = source.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PoliticalProtocolFallback(),
        errorWidget: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    return Image.file(
      File(trimmed),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
    );
  }

  List<String> get _extraAdminProtocolPhotoUrls {
    return widget.politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .skip(defaultPoliticalProtocolSlots.length)
        .toList(growable: false);
  }

  Future<void> _openPartyLeaderPhotoSheet() async {
    if (_busy || _exportAction != null) {
      return;
    }
    final adminUrls = _extraAdminProtocolPhotoUrls;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final savedPaths = _savedLeaderPhotoPaths
                .map((path) => path.trim())
                .where((path) => path.isNotEmpty)
                .toList(growable: false);
            final totalCount = adminUrls.length + savedPaths.length + 1;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Add party leader photos',
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a photo to place it on the poster.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          if (index < adminUrls.length) {
                            final url = adminUrls[index];
                            return _buildPhotoSlot(
                              side: 62,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    const _PoliticalProtocolFallback(),
                                errorWidget: (_, _, _) =>
                                    const _PoliticalProtocolFallback(),
                              ),
                              isPlus: false,
                              onTap: () => Navigator.of(sheetContext).pop(url),
                            );
                          }
                          final savedIndex = index - adminUrls.length;
                          if (savedIndex < savedPaths.length) {
                            final path = savedPaths[savedIndex];
                            return SizedBox(
                              width: 68,
                              height: 68,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  Positioned.fill(
                                    child: Center(
                                      child: _buildPhotoSlot(
                                        side: 62,
                                        child: _buildProtocolPhotoSource(path),
                                        isPlus: false,
                                        onTap: () => Navigator.of(
                                          sheetContext,
                                        ).pop(path),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -1,
                                    top: -1,
                                    child: GestureDetector(
                                      onTap: () async {
                                        await _deleteSavedLeaderPhoto(path);
                                        if (mounted) {
                                          setSheetState(() {});
                                        }
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return _buildPhotoSlot(
                            side: 62,
                            isPlus: true,
                            onTap: () =>
                                Navigator.of(sheetContext).pop('__add'),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemCount: totalCount,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || selected == null) {
      return;
    }
    if (selected == '__add') {
      await _addPhoto(saveToLeaderLibrary: true);
      return;
    }
    _insertProtocolPhotoSource(selected);
  }

  Widget _buildAdminPhotoPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Center(
        child: FilledButton.icon(
          onPressed: _busy || _exportAction != null
              ? null
              : () => unawaited(_openPartyLeaderPhotoSheet()),
          icon: _busy
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.group_add_rounded, size: 18),
          label: const Text(
            'Add party leader photos',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterPhotoSlots({
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final adminUrls = widget.showDefaultProtocolPhotos
        ? widget.politicalProtocolPhotoUrls
              .map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .take(_defaultSlots.length)
              .toList(growable: false)
        : const <String>[];
    return _EditablePoliticalProtocolOverlay(
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      adminUrls: adminUrls,
      defaultSlots: _defaultSlots,
      manualPhotoPaths: _manualPhotoPaths,
      manualSlots: _manualSlots,
      deleteArmedManualIndex: _deleteArmedManualIndex,
      onDefaultSlotChanged: (index, slot) {
        if (index >= 0 && index < _defaultSlots.length) {
          _defaultSlots[index] = slot;
        }
      },
      onManualSlotChanged: (index, slot) {
        if (index >= 0 && index < _manualSlots.length) {
          _manualSlots[index] = slot;
        }
      },
      onManualPhotoTap: (index) {
        if (_deleteArmedManualIndex == index) {
          _removeManualPhoto(index);
          return;
        }
        setState(() => _deleteArmedManualIndex = index);
      },
    );
  }

  Widget _buildPosterImage() {
    final customPosterPath = _customPosterPath?.trim() ?? '';
    if (customPosterPath.isNotEmpty) {
      return Image.file(
        File(customPosterPath),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFF111827),
          child: Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54),
          ),
        ),
      );
    }
    final imageUrl = widget.item.imageUrl?.trim() ?? '';
    final assetPath = widget.item.imageAssetPath?.trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain);
    }
    if (assetPath.isNotEmpty) {
      return Image.asset(assetPath, fit: BoxFit.contain);
    }
    return const ColoredBox(
      color: Color(0xFF111827),
      child: Center(
        child: Icon(Icons.image_not_supported_rounded, color: Colors.white54),
      ),
    );
  }

  EditorPageConfig _currentPosterPageConfig() {
    final existing = widget.item.pageConfig;
    final aspectRatio = _posterImageAspectRatio ?? existing?.aspectRatio ?? 1.0;
    if (aspectRatio <= 0) {
      return existing ?? EditorPageConfig.defaultConfig;
    }
    const baseWidth = 1080;
    final resolvedHeight = math.max(1, (baseWidth / aspectRatio).round());
    return EditorPageConfig(
      name: existing?.name ?? 'Full Screen Poster',
      widthPx: baseWidth,
      heightPx: resolvedHeight,
      dpi: existing?.dpi ?? EditorPageConfig.defaultConfig.dpi,
    );
  }

  Widget _buildCustomPosterBase(VoidCallback onReady) {
    final customPosterPath = _customPosterPath?.trim() ?? '';
    if (customPosterPath.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
      return _buildPosterImage();
    }
    return Image.file(
      File(customPosterPath),
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null || wasSynchronouslyLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
        }
        return child;
      },
      errorBuilder: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
        return const ColoredBox(
          color: Color(0xFF111827),
          child: Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54),
          ),
        );
      },
    );
  }

  Widget _buildPersonalizedPosterBase() {
    final personalizationConfig = widget.item.personalizationConfig;
    if (personalizationConfig == null) {
      return _buildPosterImage();
    }
    final hasCustomPoster = (_customPosterPath?.trim().isNotEmpty ?? false);
    return _CreatorPosterPreview(
      imageAssetPath: hasCustomPoster ? null : widget.item.imageAssetPath,
      imageUrl: hasCustomPoster ? null : widget.item.imageUrl,
      imageStoragePath: hasCustomPoster ? null : widget.item.imageStoragePath,
      thumbnailStoragePath: hasCustomPoster
          ? null
          : widget.item.thumbnailStoragePath,
      thumbnailUrl: hasCustomPoster ? null : widget.item.thumbnailUrl,
      pageConfig: _currentPosterPageConfig(),
      basePosterBuilder: hasCustomPoster ? _buildCustomPosterBase : null,
      personalizationConfig: personalizationConfig,
      preferOriginalPosterQuality: true,
      viewerPosterProfile: widget.viewerPosterProfile,
      language: widget.language,
      politicalProtocolPhotoUrls: const <String>[],
      politicalProtocolLocalPhotoPaths: const <String>[],
      politicalProtocolSlotsOverride: const <PoliticalProtocolSlot>[],
      politicalProtocolManualSlots: const <PoliticalProtocolSlot>[],
      showPoliticalProtocolOverlay: false,
      showProfilePhoto: true,
      deferLegacyTextPrime: false,
      posterRenderCycle: 0,
      interactivePhotoEnabled: false,
      photoShapeOverride: '',
      photoRenderModeOverride: '',
      photoFlipHorizontally: false,
      photoXOffsetPercent: 0,
      photoYOffsetPercent: 0,
      onPhotoTap: () {},
      stripGradientTapOffset: 0,
      additionalPhotoSelection: null,
      onAdditionalPhotoTap: null,
      onPhotoDragDeltaPercent:
          ({required double deltaXPercent, required double deltaYPercent}) {},
      onPhotoDragStateChanged: (_) {},
    );
  }

  Widget _buildPosterActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
    bool loading = false,
    Color? backgroundColor,
    Color? foregroundColor,
    double minimumHeight = 46,
    double borderRadius = 12,
    double fontSize = 14,
    double iconSize = 18,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (loading)
          const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: iconSize),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF0F766E),
          foregroundColor: foregroundColor ?? Colors.white,
          minimumSize: Size(0, minimumHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F172A),
        minimumSize: Size(0, minimumHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: child,
    );
  }

  Widget _buildCustomPosterActions() {
    final busy = _busy || _exportAction != null;
    final hasCustomPoster = (_customPosterPath?.trim().isNotEmpty ?? false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: _buildPosterActionButton(
              icon: Icons.add_photo_alternate_rounded,
              label: hasCustomPoster ? 'Change your poster' : 'Add your poster',
              onPressed: busy ? null : () => unawaited(_pickCustomPoster()),
              filled: true,
              loading: _busy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildPosterActionButton(
                  icon: Icons.ios_share_rounded,
                  label: context.strings.localized(
                    telugu: 'Share',
                    english: 'Share',
                  ),
                  onPressed: busy
                      ? null
                      : () => unawaited(_shareCustomPoster()),
                  filled: true,
                  backgroundColor: const Color(0xFF25D366),
                  minimumHeight: 32,
                  borderRadius: 999,
                  fontSize: 12,
                  iconSize: 17,
                  loading: _exportAction == 'share',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPosterActionButton(
                  icon: Icons.download_rounded,
                  label: context.strings.localized(
                    telugu: 'Download',
                    english: 'Download',
                  ),
                  onPressed: busy
                      ? null
                      : () => unawaited(_downloadCustomPoster()),
                  filled: true,
                  backgroundColor: const Color(0xFF64748B),
                  minimumHeight: 32,
                  borderRadius: 999,
                  fontSize: 12,
                  iconSize: 17,
                  loading: _exportAction == 'download',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAspectRatio =
        _posterImageAspectRatio ?? widget.item.pageConfig?.aspectRatio;
    final posterStage = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.max(1.0, constraints.maxWidth);
        final maxHeight = math.max(1.0, constraints.maxHeight);
        final aspectRatio = pageAspectRatio != null && pageAspectRatio > 0
            ? pageAspectRatio
            : maxWidth / maxHeight;
        final posterWidth = math.min(maxWidth, maxHeight * aspectRatio);
        final posterHeight = posterWidth / aspectRatio;
        final posterLeft = (maxWidth - posterWidth) / 2;
        final posterTop = (maxHeight - posterHeight) / 2;
        return Stack(
          children: <Widget>[
            Positioned(
              left: posterLeft,
              top: posterTop,
              width: posterWidth,
              height: posterHeight,
              child: Screenshot(
                controller: _customPosterScreenshotController,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _buildPersonalizedPosterBase(),
                    _buildPosterPhotoSlots(
                      canvasWidth: posterWidth,
                      canvasHeight: posterHeight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.6,
        title: Text(
          context.strings.localized(
            telugu: 'పొలిటికల్ ఫోటోలు',
            english: 'Add Political Photos',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              _PoliticalProtocolPhotoScreenResult(
                manualPhotoPaths: _manualPhotoPaths,
                defaultSlots: _defaultSlots,
                manualSlots: _manualSlots,
              ),
            ),
            child: Text(
              context.strings.localized(telugu: 'Done', english: 'Done'),
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_deleteArmedManualIndex != null) {
              setState(() => _deleteArmedManualIndex = null);
            }
          },
          child: Column(
            children: <Widget>[
              _buildAdminPhotoPicker(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: posterStage,
                  ),
                ),
              ),
              _buildCustomPosterActions(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Text(
                  context.strings.localized(
                    telugu:
                        '+ à°®à±€à°¦ tap à°šà±‡à°¸à°¿ à°«à±‹à°Ÿà±‹ à°œà±‹à°¡à°¿à°‚à°šà°‚à°¡à°¿. à°«à±‹à°Ÿà±‹ à°®à±€à°¦ tap à°šà±‡à°¸à±à°¤à±‡ delete à°µà°¸à±à°¤à±à°‚à°¦à°¿.',
                    english:
                        'Drag circles to adjust position. Tap + to add a photo. Tap an added photo to delete it.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _EditablePoliticalProtocolOverlay extends StatefulWidget {
  const _EditablePoliticalProtocolOverlay({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.adminUrls,
    required this.defaultSlots,
    required this.manualPhotoPaths,
    required this.manualSlots,
    required this.deleteArmedManualIndex,
    required this.onDefaultSlotChanged,
    required this.onManualSlotChanged,
    required this.onManualPhotoTap,
  });

  final double canvasWidth;
  final double canvasHeight;
  final List<String> adminUrls;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<String> manualPhotoPaths;
  final List<PoliticalProtocolSlot> manualSlots;
  final int? deleteArmedManualIndex;
  final void Function(int index, PoliticalProtocolSlot slot)
  onDefaultSlotChanged;
  final void Function(int index, PoliticalProtocolSlot slot)
  onManualSlotChanged;
  final ValueChanged<int> onManualPhotoTap;

  @override
  State<_EditablePoliticalProtocolOverlay> createState() =>
      _EditablePoliticalProtocolOverlayState();
}

class _EditablePoliticalProtocolOverlayState
    extends State<_EditablePoliticalProtocolOverlay> {
  late List<PoliticalProtocolSlot> _defaultSlots;
  late List<PoliticalProtocolSlot> _manualSlots;

  @override
  void initState() {
    super.initState();
    _defaultSlots = _copySlots(widget.defaultSlots);
    _manualSlots = _copySlots(widget.manualSlots);
  }

  @override
  void didUpdateWidget(covariant _EditablePoliticalProtocolOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultSlots.length != widget.defaultSlots.length ||
        oldWidget.adminUrls.length != widget.adminUrls.length) {
      _defaultSlots = _copySlots(widget.defaultSlots);
    }
    if (oldWidget.manualSlots.length != widget.manualSlots.length ||
        oldWidget.manualPhotoPaths.length != widget.manualPhotoPaths.length) {
      _manualSlots = _copySlots(widget.manualSlots);
    }
  }

  List<PoliticalProtocolSlot> _copySlots(List<PoliticalProtocolSlot> slots) {
    return slots
        .map(
          (slot) =>
              PoliticalProtocolSlot(x: slot.x, y: slot.y, scale: slot.scale),
        )
        .toList(growable: true);
  }

  Widget _buildPhotoSlot({
    required double side,
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.95),
          border: Border.all(color: Colors.white, width: 0.8),
        ),
        child: ClipOval(child: child),
      ),
    );
  }

  Widget _buildProtocolPhotoSource(String source) {
    final trimmed = source.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PoliticalProtocolFallback(),
        errorWidget: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    return Image.file(
      File(trimmed),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
    );
  }

  PoliticalProtocolSlot _defaultManualSlot(int index) {
    final row = index ~/ 4;
    final col = index % 4;
    return PoliticalProtocolSlot(
      x: (22 + (col * 18)).clamp(8, 92).toDouble(),
      y: (24 + (row * 14)).clamp(8, 92).toDouble(),
      scale: 100,
    );
  }

  PoliticalProtocolSlot _draggedSlot({
    required PoliticalProtocolSlot slot,
    required DragUpdateDetails details,
    required double side,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final nextX = (slot.x + (details.delta.dx / canvasWidth) * 100)
        .clamp((side / canvasWidth) * 50, 100 - ((side / canvasWidth) * 50))
        .toDouble();
    final nextY = (slot.y + (details.delta.dy / canvasHeight) * 100)
        .clamp((side / canvasHeight) * 50, 100 - ((side / canvasHeight) * 50))
        .toDouble();
    return PoliticalProtocolSlot(x: nextX, y: nextY, scale: slot.scale);
  }

  @override
  Widget build(BuildContext context) {
    final safeCanvasWidth = math.max(1.0, widget.canvasWidth);
    final safeCanvasHeight = math.max(1.0, widget.canvasHeight);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (var index = 0; index < widget.adminUrls.length; index += 1)
          Builder(
            builder: (context) {
              final slot = index < _defaultSlots.length
                  ? _defaultSlots[index]
                  : defaultPoliticalProtocolSlots[index %
                        defaultPoliticalProtocolSlots.length];
              final side = _PoliticalProtocolPhotoSlots._slotSide(
                canvasWidth: safeCanvasWidth,
                canvasHeight: safeCanvasHeight,
                scale: slot.scale,
              );
              final centerX = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.x,
                canvasExtent: safeCanvasWidth,
                side: side,
              );
              final centerY = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.y,
                canvasExtent: safeCanvasHeight,
                side: side,
              );
              return Positioned(
                left: (safeCanvasWidth * (centerX / 100)) - (side / 2),
                top: (safeCanvasHeight * (centerY / 100)) - (side / 2),
                width: side,
                height: side,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final nextSlot = _draggedSlot(
                      slot: slot,
                      details: details,
                      side: side,
                      canvasWidth: safeCanvasWidth,
                      canvasHeight: safeCanvasHeight,
                    );
                    setState(() {
                      if (index < _defaultSlots.length) {
                        _defaultSlots[index] = nextSlot;
                      }
                    });
                    widget.onDefaultSlotChanged(index, nextSlot);
                  },
                  child: _buildPhotoSlot(
                    side: side,
                    child: CachedNetworkImage(
                      imageUrl: widget.adminUrls[index],
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.person_rounded),
                    ),
                    onTap: null,
                  ),
                ),
              );
            },
          ),
        for (
          var manualIndex = 0;
          manualIndex < widget.manualPhotoPaths.length;
          manualIndex += 1
        )
          Builder(
            builder: (context) {
              final slot = manualIndex < _manualSlots.length
                  ? _manualSlots[manualIndex]
                  : _defaultManualSlot(manualIndex);
              final side = _PoliticalProtocolPhotoSlots._slotSide(
                canvasWidth: safeCanvasWidth,
                canvasHeight: safeCanvasHeight,
                scale: slot.scale,
              );
              final centerX = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.x,
                canvasExtent: safeCanvasWidth,
                side: side,
              );
              final centerY = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.y,
                canvasExtent: safeCanvasHeight,
                side: side,
              );
              final deleteArmed = widget.deleteArmedManualIndex == manualIndex;
              final child = Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _buildProtocolPhotoSource(
                    widget.manualPhotoPaths[manualIndex],
                  ),
                  if (deleteArmed)
                    ColoredBox(
                      color: Colors.red.withValues(alpha: 0.78),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              );
              return Positioned(
                left: (safeCanvasWidth * (centerX / 100)) - (side / 2),
                top: (safeCanvasHeight * (centerY / 100)) - (side / 2),
                width: side,
                height: side,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final nextSlot = _draggedSlot(
                      slot: slot,
                      details: details,
                      side: side,
                      canvasWidth: safeCanvasWidth,
                      canvasHeight: safeCanvasHeight,
                    );
                    setState(() {
                      if (manualIndex < _manualSlots.length) {
                        _manualSlots[manualIndex] = nextSlot;
                      }
                    });
                    widget.onManualSlotChanged(manualIndex, nextSlot);
                  },
                  child: _buildPhotoSlot(
                    side: side,
                    child: child,
                    onTap: () => widget.onManualPhotoTap(manualIndex),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
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
    this.playbackEnabled = true,
    this.enablePoliticalProtocolOverlay = false,
    this.politicalProtocolPhotoScopeKey = '',
    this.forcedPoliticalProtocolPartyId,
    this.preferUltraLightImage = false,
    this.fillViewport = false,
    this.onInteraction,
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
  final bool playbackEnabled;
  final bool enablePoliticalProtocolOverlay;
  final String politicalProtocolPhotoScopeKey;
  final String? forcedPoliticalProtocolPartyId;
  final bool preferUltraLightImage;
  final bool fillViewport;
  final void Function(_TemplateItem item, String action)? onInteraction;
  static final SubscriptionBackendService _subscriptionBackendService =
      SubscriptionBackendService();
  static const PoliticalProtocolPhotoService _politicalProtocolPhotoService =
      PoliticalProtocolPhotoService();

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
  final ValueNotifier<bool> _videoExportReadyNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<int> _videoReplayTickNotifier = ValueNotifier<int>(0);
  Uint8List? _preparedPosterBytes;
  String? _preparedPosterSignature;
  String? _preparedPosterFilePath;
  Future<void>? _preparePosterFuture;
  Future<Uint8List?>? _posterCaptureFuture;
  String? _preparedVideoSignature;
  String? _preparedVideoFilePath;
  Future<String?>? _prepareVideoFuture;
  String? _prepareVideoFutureSignature;
  int _videoExportGeneration = 0;
  bool _videoWarmupQueued = false;
  String? _queuedVideoWarmupSignature;
  bool _posterWarmupQueued = false;
  String? _queuedPosterWarmupSignature;
  static bool _globalAutoPosterWarmupActive = false;
  static final Set<String> _globalPosterWarmupSignatures = <String>{};
  _PosterPhotoUserAdjustment _photoUserAdjustment =
      _PosterPhotoUserAdjustment.none;
  _PosterExtraPhotoSelection? _extraPhotoSelection;
  int _stripGradientTapOffset = 0;
  Future<void>? _backgroundRemoverInitialization;
  bool _photoDragInProgress = false;
  bool _additionalPhotoBusy = false;
  double? _resolvedPreviewAspectRatio;
  String? _politicalProtocolPartyId;
  List<String> _politicalProtocolPhotoUrls = const <String>[];
  List<String> _manualPoliticalProtocolPhotoPaths = const <String>[];
  List<PoliticalProtocolSlot>? _politicalProtocolDefaultSlotsOverride;
  List<PoliticalProtocolSlot> _manualPoliticalProtocolSlots =
      const <PoliticalProtocolSlot>[];
  Future<void>? _politicalProtocolPhotoLoadFuture;
  ValueNotifier<List<String>>? _manualProtocolPhotoNotifier;
  ValueNotifier<List<PoliticalProtocolSlot>>? _manualProtocolPhotoSlotNotifier;

  _TemplateItem get item => widget.item;
  BuildContext get hostContext => widget.hostContext;
  AppLanguage get language => widget.language;
  bool get deferRichPosterPreview => widget.deferRichPosterPreview;
  bool get playbackEnabled => widget.playbackEnabled;
  bool get preferUltraLightImage => widget.preferUltraLightImage;
  bool get fillViewport => widget.fillViewport;
  Future<void> Function({bool startPurchaseOnOpen})
  get onOpenSubscriptionPlan => widget.onOpenSubscriptionPlan;
  PosterProfileData get viewerPosterProfile => widget.viewerPosterProfile;
  int get posterRenderCycle => widget.posterRenderCycle;
  SubscriptionBackendService get _subscriptionBackendService =>
      _TemplateFeedItem.subscriptionBackendService;

  bool get _canAddPoliticalProtocolPhotos {
    final partyId = _resolvePoliticalPartyId();
    return widget.enablePoliticalProtocolOverlay &&
        partyId != null &&
        partyId.trim().isNotEmpty &&
        !item.isVideo &&
        item.personalizationConfig != null;
  }

  PoliticalParty? _resolvePoliticalParty() {
    final tags = <String>{
      for (final tag in item.categoryTags) _normalizeTagWorker(tag),
      _normalizeTagWorker(item.primaryFirestoreCategoryId ?? ''),
    }..removeWhere((tag) => tag.isEmpty);
    if (tags.isEmpty) {
      return null;
    }
    for (final party in politicalParties) {
      final partyId = _normalizeTagWorker(party.id);
      final shortName = _normalizeTagWorker(party.shortName);
      final matches =
          tags.contains(partyId) ||
          tags.contains('party_$partyId') ||
          (shortName.isNotEmpty && tags.contains(shortName)) ||
          (shortName.isNotEmpty && tags.contains('party_$shortName'));
      if (matches) {
        return party;
      }
    }
    return null;
  }

  String? _resolvePoliticalPartyLogoAssetPath() {
    return _resolvePoliticalParty()?.logoAssetPath;
  }

  String? _resolvePoliticalPartyId() {
    final forced = widget.forcedPoliticalProtocolPartyId?.trim() ?? '';
    if (forced.isNotEmpty) {
      return forced;
    }
    return _resolvePoliticalParty()?.id;
  }

  void _syncPoliticalProtocolPhotos() {
    if (!widget.enablePoliticalProtocolOverlay) {
      _politicalProtocolPartyId = null;
      _politicalProtocolPhotoUrls = const <String>[];
      _politicalProtocolPhotoLoadFuture = null;
      return;
    }
    final partyId = _resolvePoliticalPartyId();
    if (partyId == null || partyId.isEmpty) {
      _politicalProtocolPartyId = null;
      _politicalProtocolPhotoUrls = const <String>[];
      _politicalProtocolPhotoLoadFuture = null;
      return;
    }
    if (_politicalProtocolPartyId == partyId &&
        _politicalProtocolPhotoLoadFuture != null) {
      return;
    }
    _politicalProtocolPartyId = partyId;
    _politicalProtocolPhotoUrls = const <String>[];
    final future = _TemplateFeedItem._politicalProtocolPhotoService
        .fetchPhotoUrlsForParty(partyId);
    _politicalProtocolPhotoLoadFuture = future;
    unawaited(
      future.then((urls) {
        if (!mounted ||
            _politicalProtocolPartyId != partyId ||
            _politicalProtocolPhotoLoadFuture != future) {
          return;
        }
        setState(() {
          _politicalProtocolPhotoUrls = urls;
        });
      }),
    );
  }

  String _manualProtocolPhotoScopeKey() {
    if (!widget.enablePoliticalProtocolOverlay) {
      return '';
    }
    final rawScope = widget.politicalProtocolPhotoScopeKey.trim();
    if (rawScope.isNotEmpty) {
      return rawScope;
    }
    final forced = widget.forcedPoliticalProtocolPartyId?.trim() ?? '';
    if (forced.isNotEmpty) {
      return 'party_${_normalizeTagWorker(forced)}';
    }
    return _normalizeTagWorker(item.primaryFirestoreCategoryId ?? 'political');
  }

  void _handleManualProtocolPhotosChanged() {
    final notifier = _manualProtocolPhotoNotifier;
    final slotNotifier = _manualProtocolPhotoSlotNotifier;
    if (!mounted || notifier == null) {
      return;
    }
    setState(() {
      _manualPoliticalProtocolPhotoPaths = notifier.value
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false);
      final slots = slotNotifier?.value ?? const <PoliticalProtocolSlot>[];
      _manualPoliticalProtocolSlots = slots
          .take(_manualPoliticalProtocolPhotoPaths.length)
          .toList(growable: false);
    });
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    _schedulePosterWarmup(force: true);
  }

  void _syncManualProtocolPhotoScope() {
    _manualProtocolPhotoNotifier?.removeListener(
      _handleManualProtocolPhotosChanged,
    );
    _manualProtocolPhotoSlotNotifier?.removeListener(
      _handleManualProtocolPhotosChanged,
    );
    _manualProtocolPhotoNotifier = null;
    _manualProtocolPhotoSlotNotifier = null;
    _manualPoliticalProtocolPhotoPaths = const <String>[];
    _manualPoliticalProtocolSlots = const <PoliticalProtocolSlot>[];
  }

  @override
  void initState() {
    super.initState();
    _resolvedPreviewAspectRatio = _initialPreviewAspectRatioFor(item);
    _syncManualProtocolPhotoScope();
    _syncPoliticalProtocolPhotos();
    if (item.isVideo && playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scheduleVideoWarmup(requireReady: false, allowScrollDeferral: false);
        _scheduleVideoWarmupRetries();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _TemplateFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackEnabled != widget.playbackEnabled) {
      updateKeepAlive();
    }
    if (oldWidget.enablePoliticalProtocolOverlay !=
            widget.enablePoliticalProtocolOverlay ||
        oldWidget.politicalProtocolPhotoScopeKey !=
            widget.politicalProtocolPhotoScopeKey ||
        oldWidget.forcedPoliticalProtocolPartyId !=
            widget.forcedPoliticalProtocolPartyId ||
        oldWidget.item.categoryTags != widget.item.categoryTags ||
        oldWidget.item.primaryFirestoreCategoryId !=
            widget.item.primaryFirestoreCategoryId) {
      _syncManualProtocolPhotoScope();
      _syncPoliticalProtocolPhotos();
    }
    if (oldWidget.item.videoUrl != widget.item.videoUrl ||
        oldWidget.item.imageUrl != widget.item.imageUrl ||
        oldWidget.item.imageStoragePath != widget.item.imageStoragePath ||
        oldWidget.item.thumbnailStoragePath !=
            widget.item.thumbnailStoragePath ||
        oldWidget.item.thumbnailUrl != widget.item.thumbnailUrl ||
        oldWidget.item.imageAssetPath != widget.item.imageAssetPath ||
        oldWidget.item.pageConfig != widget.item.pageConfig ||
        oldWidget.viewerPosterProfile != widget.viewerPosterProfile ||
        oldWidget.language != widget.language ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _resolvedPreviewAspectRatio = _initialPreviewAspectRatioFor(item);
      _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
      if (item.isVideo && playbackEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _scheduleVideoWarmup(requireReady: false, allowScrollDeferral: false);
          _scheduleVideoWarmupRetries();
        });
      }
    } else if (item.isVideo &&
        !oldWidget.playbackEnabled &&
        widget.playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scheduleVideoWarmup(requireReady: false, allowScrollDeferral: false);
        _scheduleVideoWarmupRetries();
      });
    }
  }

  double? _initialPreviewAspectRatioFor(_TemplateItem item) {
    final pageConfig = item.pageConfig;
    if (pageConfig != null &&
        pageConfig.widthPx > 0 &&
        pageConfig.heightPx > 0) {
      return pageConfig.aspectRatio;
    }
    return null;
  }

  void _handlePreviewAspectRatioResolved(double aspectRatio) {
    if (!mounted || aspectRatio <= 0) {
      return;
    }
    final existing = _resolvedPreviewAspectRatio;
    if (existing != null && (existing - aspectRatio).abs() < 0.001) {
      return;
    }
    setState(() => _resolvedPreviewAspectRatio = aspectRatio);
  }

  @override
  void dispose() {
    if (_photoDragInProgress) {
      widget.onPosterPhotoDragStateChanged(false);
    }
    _manualProtocolPhotoNotifier?.removeListener(
      _handleManualProtocolPhotosChanged,
    );
    _invalidatePreparedPosterCache();
    _showPosterPhotoNotifier.dispose();
    _posterReadyNotifier.dispose();
    _activeActionNotifier.dispose();
    _videoExportReadyNotifier.dispose();
    _videoReplayTickNotifier.dispose();
    super.dispose();
  }

  String _resolvePosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${item.imageUrl ?? item.imageAssetPath ?? 'poster'}'
        '|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + _stripGradientTapOffset) % _randomPosterNameFonts.length;
    return _randomPosterNameFonts[index];
  }

  String _resolveEnglishPosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${item.imageUrl ?? item.imageAssetPath ?? 'poster'}'
        '|english|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + _stripGradientTapOffset) %
        _randomEnglishPosterNameFonts.length;
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
    final defaultProtocolSlots =
        _politicalProtocolDefaultSlotsOverride ??
        item.personalizationConfig?.politicalProtocolSlots ??
        const <PoliticalProtocolSlot>[];
    final protocolSlotSignature =
        <PoliticalProtocolSlot>[
              ...defaultProtocolSlots,
              ..._manualPoliticalProtocolSlots,
            ]
            .map(
              (slot) =>
                  '${slot.x.toStringAsFixed(2)},${slot.y.toStringAsFixed(2)},${slot.scale.toStringAsFixed(2)}',
            )
            .join('|');
    final protocolPhotoSignature = <String>[
      ..._politicalProtocolPhotoUrls.take(defaultPoliticalProtocolSlots.length),
      ..._manualPoliticalProtocolPhotoPaths,
    ].join('|');
    return '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${item.videoUrl ?? ''}-${item.mediaType}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-${_photoUserAdjustment.flipHorizontally}-${_photoUserAdjustment.xOffsetPercent.toStringAsFixed(2)}-${_photoUserAdjustment.yOffsetPercent.toStringAsFixed(2)}-${_extraPhotoSelection?.originalPhotoPath ?? ''}-${_extraPhotoSelection?.cutoutPhotoPath ?? ''}-protocol$protocolPhotoSignature-$protocolSlotSignature-strip$_stripGradientTapOffset-$posterRenderCycle-$isPhotoVisible';
  }

  void _cyclePosterDesign() {
    setState(() {
      _stripGradientTapOffset =
          (_stripGradientTapOffset + 1) %
          _CreatorPosterPreviewState.posterStripGradientCount;
    });
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    _schedulePosterWarmup(force: true);
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

  void _invalidatePreparedPosterCache({bool cancelVideoExport = false}) {
    final existingPath = _preparedPosterFilePath;
    final shouldCancelVideoExport =
        cancelVideoExport && item.isVideo && _prepareVideoFuture != null;
    _preparedPosterBytes = null;
    _preparedPosterSignature = null;
    _preparedPosterFilePath = null;
    _preparedVideoSignature = null;
    _preparedVideoFilePath = null;
    _prepareVideoFuture = null;
    _prepareVideoFutureSignature = null;
    _videoExportGeneration += 1;
    _queuedVideoWarmupSignature = null;
    _videoWarmupQueued = false;
    if (item.isVideo) {
      _videoExportReadyNotifier.value = false;
    }
    _queuedPosterWarmupSignature = null;
    if (shouldCancelVideoExport) {
      _homeDebugLog('video export stale in-flight cancelled');
      unawaited(FFmpegKit.cancel());
    }
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
                        telugu:
                            'à°¬à±à°¯à°¾à°•à±â€Œà°—à±à°°à±Œà°‚à°¡à± à°¤à±Šà°²à°—à°¿à°¸à±à°¤à±‹à°‚à°¦à°¿...',
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
              telugu: 'à°«à±‹à°Ÿà±‹ à°•à±à°°à°¾à°ªà± à°šà±‡à°¯à°‚à°¡à°¿',
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
              telugu: 'à°«à±‹à°Ÿà±‹ à°•à±à°°à°¾à°ªà± à°šà±‡à°¯à°‚à°¡à°¿',
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
      _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
      _schedulePosterWarmup(force: true);
      if (cutoutBytes == null && mounted) {
        _showSnack(
          messenger,
          strings.localized(
            telugu:
                'à°«à±‹à°Ÿà±‹ à°œà±‹à°¡à°¿à°‚à°šà°¾à°‚, à°•à°¾à°¨à±€ background remove à°ªà±‚à°°à±à°¤à°¿à°—à°¾ à°•à°¾à°²à±‡à°¦à±. à°‡à°ªà±à°ªà°Ÿà°¿à°•à°¿ original photo à°µà°¾à°¡à±à°¤à±à°¨à±à°¨à°¾à°‚.',
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
            telugu:
                'à°…à°¦à°¨à°ªà± à°«à±‹à°Ÿà±‹ à°œà±‹à°¡à°¿à°‚à°šà°²à±‡à°•à°ªà±‹à°¯à°¾à°‚.',
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

  Future<void> _openPoliticalProtocolPhotoScreen(BuildContext context) async {
    final partyId = _resolvePoliticalPartyId();
    if (!widget.enablePoliticalProtocolOverlay ||
        partyId == null ||
        partyId.trim().isEmpty ||
        item.isVideo) {
      return;
    }
    final result = await Navigator.of(context)
        .push<_PoliticalProtocolPhotoScreenResult>(
          MaterialPageRoute<_PoliticalProtocolPhotoScreenResult>(
            fullscreenDialog: true,
            builder: (_) => _PoliticalProtocolPhotoScreen(
              item: item,
              language: language,
              viewerPosterProfile: viewerPosterProfile,
              politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
              showDefaultProtocolPhotos:
                  item.personalizationConfig?.hasPoliticalProtocolLayout ??
                  false,
              initialManualPhotoPaths: _manualPoliticalProtocolPhotoPaths,
              defaultSlots:
                  _politicalProtocolDefaultSlotsOverride ??
                  item.personalizationConfig?.politicalProtocolSlots ??
                  defaultPoliticalProtocolSlots,
              initialManualSlots: _manualPoliticalProtocolSlots,
              ensureSubscriptionAccess: _ensureSubscriptionAccess,
              ensureGallerySavePermission: _ensureGallerySavePermission,
              leaderPhotoLibraryScopeKey: _manualProtocolPhotoScopeKey(),
            ),
          ),
        );
    if (!mounted || result == null) {
      return;
    }
    final normalizedPaths = result.manualPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final normalizedSlots = result.manualSlots
        .take(normalizedPaths.length)
        .toList(growable: false);
    final normalizedDefaultSlots =
        result.defaultSlots.length >= defaultPoliticalProtocolSlots.length
        ? result.defaultSlots
              .take(defaultPoliticalProtocolSlots.length)
              .toList(growable: false)
        : item.personalizationConfig?.politicalProtocolSlots ??
              defaultPoliticalProtocolSlots;
    setState(() {
      _manualPoliticalProtocolPhotoPaths = normalizedPaths;
      _politicalProtocolDefaultSlotsOverride = normalizedDefaultSlots;
      _manualPoliticalProtocolSlots = normalizedSlots;
    });
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    _schedulePosterWarmup(force: true);
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

  void _togglePosterPhotoFlipTap() {
    if (!_canInteractWithPosterPhoto) {
      return;
    }
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    setState(() {
      _photoUserAdjustment = _PosterPhotoUserAdjustment(
        xOffsetPercent: _photoUserAdjustment.xOffsetPercent,
        yOffsetPercent: _photoUserAdjustment.yOffsetPercent,
        flipHorizontally: !_photoUserAdjustment.flipHorizontally,
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
        flipHorizontally: _photoUserAdjustment.flipHorizontally,
      );
    });
  }

  void _setPhotoDragInProgress(bool value) {
    if (_photoDragInProgress == value) {
      return;
    }
    _photoDragInProgress = value;
    if (!value) {
      _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
      _schedulePosterWarmup(force: true);
    }
    widget.onPosterPhotoDragStateChanged(value);
  }

  void _schedulePosterWarmup({bool force = false}) {
    if (item.isVideo && playbackEnabled) {
      _scheduleVideoWarmup();
      return;
    }
    if (!_posterReadyNotifier.value) {
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

  void _scheduleVideoWarmup({
    bool requireReady = true,
    bool allowScrollDeferral = true,
  }) {
    if (!playbackEnabled ||
        !item.isVideo ||
        (requireReady && !_posterReadyNotifier.value)) {
      return;
    }
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    if (_prepareVideoFuture != null ||
        (_videoWarmupQueued && _queuedVideoWarmupSignature == signature)) {
      return;
    }
    final existingPath = _preparedVideoFilePath;
    if (_preparedVideoSignature == signature &&
        existingPath != null &&
        File(existingPath).existsSync()) {
      if (!_videoExportReadyNotifier.value) {
        _videoExportReadyNotifier.value = true;
      }
      return;
    }
    if (_videoExportReadyNotifier.value) {
      _videoExportReadyNotifier.value = false;
    }
    _videoWarmupQueued = true;
    _queuedVideoWarmupSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || (requireReady && !_posterReadyNotifier.value)) {
          return;
        }
        if (allowScrollDeferral &&
            Scrollable.recommendDeferredLoadingForContext(context)) {
          await Future<void>.delayed(const Duration(milliseconds: 650));
          if (!mounted || (requireReady && !_posterReadyNotifier.value)) {
            return;
          }
          _videoWarmupQueued = false;
          if (_queuedVideoWarmupSignature == signature) {
            _queuedVideoWarmupSignature = null;
          }
          _scheduleVideoWarmup(
            requireReady: requireReady,
            allowScrollDeferral: false,
          );
          return;
        }
        await _ensurePreparedVideoFile(isWarmup: true);
      } finally {
        _videoWarmupQueued = false;
        if (_queuedVideoWarmupSignature == signature) {
          _queuedVideoWarmupSignature = null;
        }
      }
    });
  }

  void _scheduleVideoWarmupRetries() {
    if (!item.isVideo || !playbackEnabled) {
      return;
    }
    const retryDelays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 180),
      Duration(milliseconds: 450),
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2500),
      Duration(seconds: 5),
      Duration(seconds: 9),
    ];
    for (final delay in retryDelays) {
      Future<void>.delayed(delay, () {
        if (!mounted ||
            !playbackEnabled ||
            !item.isVideo ||
            _videoExportReadyNotifier.value) {
          return;
        }
        _scheduleVideoWarmup(requireReady: false, allowScrollDeferral: false);
      });
    }
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

  Future<String?> _ensurePreparedVideoFile({bool isWarmup = false}) async {
    final videoUrl = item.videoUrl?.trim() ?? '';
    if (!item.isVideo || videoUrl.isEmpty) {
      return null;
    }
    final startedAt = DateTime.now();
    final personalization =
        item.personalizationConfig ?? CreatorPosterPersonalization.defaults;
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    final existingPath = _preparedVideoFilePath;
    if (_preparedVideoSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      if (!_videoExportReadyNotifier.value) {
        _videoExportReadyNotifier.value = true;
      }
      if (kDebugMode) {
        _homeDebugLog(
          'video export ${isWarmup ? "warmup" : "action"} cache hit in '
          '${DateTime.now().difference(startedAt).inMilliseconds}ms '
          'title=${item.titleEn}',
        );
      }
      return existingPath;
    }
    final inFlight = _prepareVideoFuture;
    if (inFlight != null && _prepareVideoFutureSignature == signature) {
      if (kDebugMode) {
        _homeDebugLog(
          'video export ${isWarmup ? "warmup" : "action"} joined in-flight '
          'title=${item.titleEn}',
        );
      }
      return inFlight;
    }
    final generation = _videoExportGeneration;
    final future = () async {
      try {
        if (kDebugMode) {
          _homeDebugLog(
            'video export ${isWarmup ? "warmup" : "action"} start '
            'title=${item.titleEn}',
          );
        }
        final outputPath = await const PersonalizedVideoExportService().export(
          videoUrl: videoUrl,
          profile: viewerPosterProfile,
          personalization: personalization,
          language: language,
          extraPhotoProfile:
              personalization.showVideoExtraPhoto &&
                  (_extraPhotoSelection?.hasPhoto ?? false)
              ? _extraPhotoSelection!.asPosterProfileData()
              : null,
          title: item.titleFor(language),
          previewSeed: item.imageUrl ?? item.imageAssetPath ?? 'poster',
          stripGradientTapOffset: _stripGradientTapOffset,
        );
        if (_videoExportGeneration == generation) {
          _preparedVideoSignature = signature;
          _preparedVideoFilePath = outputPath;
        }
        if (mounted && _videoExportGeneration == generation) {
          if (!_videoExportReadyNotifier.value) {
            _videoExportReadyNotifier.value = true;
          }
          setState(() {});
        }
        if (kDebugMode) {
          _homeDebugLog(
            'video export ${isWarmup ? "warmup" : "action"} ready in '
            '${DateTime.now().difference(startedAt).inMilliseconds}ms '
            'title=${item.titleEn}',
          );
        }
        return outputPath;
      } catch (error, stackTrace) {
        if (mounted &&
            _videoExportGeneration == generation &&
            _videoExportReadyNotifier.value) {
          _videoExportReadyNotifier.value = false;
        }
        _homeDebugLogStack('video export failed: $error', stackTrace);
        return null;
      }
    }();
    _prepareVideoFuture = future;
    _prepareVideoFutureSignature = signature;
    try {
      return await future;
    } finally {
      if (identical(_prepareVideoFuture, future)) {
        _prepareVideoFuture = null;
        _prepareVideoFutureSignature = null;
      }
    }
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
    if (ready && item.isVideo && playbackEnabled) {
      _scheduleVideoWarmup(allowScrollDeferral: false);
      _scheduleVideoWarmupRetries();
    }
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
    final renderOriginalPosterQuality = item.preferOriginalPosterQuality;
    if (deferRichPosterPreview) {
      return _ResolvedTemplatePosterImage(
        imageAssetPath: item.imageAssetPath,
        imageUrl: item.imageUrl ?? '',
        imageStoragePath: item.imageStoragePath,
        thumbnailStoragePath: item.thumbnailStoragePath,
        thumbnailUrl: item.thumbnailUrl,
        posterIdForDebug: item.templateId,
        preferOriginalPosterQuality: renderOriginalPosterQuality,
        preferUltraLightDecode: preferUltraLightImage,
        onAspectRatioResolved: _handlePreviewAspectRatioResolved,
        onFirstFrameReady: () => onPosterReadyChanged?.call(true),
      );
    }
    return item.isVideo
        ? personalizationConfig != null
              ? _CreatorPosterPreview(
                  imageAssetPath: item.imageAssetPath,
                  imageUrl: item.imageUrl,
                  imageStoragePath: item.imageStoragePath,
                  thumbnailStoragePath: item.thumbnailStoragePath,
                  thumbnailUrl: item.thumbnailUrl,
                  pageConfig: item.pageConfig,
                  basePosterBuilder: (VoidCallback onReady) =>
                      _FeedTapToPlayVideoPoster(
                        videoUrl: item.videoUrl!,
                        playbackEnabled: playbackEnabled,
                        imageAssetPath: item.imageAssetPath,
                        imageUrl: item.imageUrl,
                        imageStoragePath: item.imageStoragePath,
                        thumbnailStoragePath: item.thumbnailStoragePath,
                        thumbnailUrl: item.thumbnailUrl,
                        onAspectRatioResolved:
                            _handlePreviewAspectRatioResolved,
                        onReady: onReady,
                        onReplay: () {
                          _videoReplayTickNotifier.value =
                              _videoReplayTickNotifier.value + 1;
                        },
                      ),
                  videoReplayTickListenable: _videoReplayTickNotifier,
                  personalizationConfig: personalizationConfig,
                  preferOriginalPosterQuality: renderOriginalPosterQuality,
                  viewerPosterProfile: viewerPosterProfile,
                  language: language,
                  partyLogoAssetPath: _resolvePoliticalPartyLogoAssetPath(),
                  politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
                  politicalProtocolLocalPhotoPaths:
                      _manualPoliticalProtocolPhotoPaths,
                  politicalProtocolSlotsOverride:
                      _politicalProtocolDefaultSlotsOverride,
                  politicalProtocolManualSlots: _manualPoliticalProtocolSlots,
                  showPoliticalProtocolOverlay:
                      widget.enablePoliticalProtocolOverlay,
                  showProfilePhoto: isPhotoVisible,
                  deferLegacyTextPrime: deferRichPosterPreview,
                  posterRenderCycle: posterRenderCycle,
                  interactivePhotoEnabled: false,
                  photoShapeOverride: '',
                  photoRenderModeOverride: '',
                  photoFlipHorizontally: _photoUserAdjustment.flipHorizontally,
                  photoXOffsetPercent: _photoUserAdjustment.xOffsetPercent,
                  photoYOffsetPercent: _photoUserAdjustment.yOffsetPercent,
                  onPhotoTap: _togglePosterPhotoFlipTap,
                  stripGradientTapOffset: _stripGradientTapOffset,
                  onNameStripTap: null,
                  additionalPhotoSelection: _extraPhotoSelection,
                  onAdditionalPhotoTap:
                      personalizationConfig.showVideoExtraPhoto
                      ? () => unawaited(_pickAdditionalPosterPhoto())
                      : null,
                  onPhotoDragDeltaPercent: _updatePosterPhotoDrag,
                  onPhotoDragStateChanged: _setPhotoDragInProgress,
                  onAspectRatioResolved: _handlePreviewAspectRatioResolved,
                  onPosterReadyChanged: onPosterReadyChanged,
                )
              : _FeedTapToPlayVideoPoster(
                  videoUrl: item.videoUrl!,
                  playbackEnabled: playbackEnabled,
                  imageAssetPath: item.imageAssetPath,
                  imageUrl: item.imageUrl,
                  imageStoragePath: item.imageStoragePath,
                  thumbnailStoragePath: item.thumbnailStoragePath,
                  thumbnailUrl: item.thumbnailUrl,
                  onAspectRatioResolved: _handlePreviewAspectRatioResolved,
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
            preferOriginalPosterQuality: renderOriginalPosterQuality,
            viewerPosterProfile: viewerPosterProfile,
            language: language,
            partyLogoAssetPath: _resolvePoliticalPartyLogoAssetPath(),
            politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
            politicalProtocolLocalPhotoPaths:
                _manualPoliticalProtocolPhotoPaths,
            politicalProtocolSlotsOverride:
                _politicalProtocolDefaultSlotsOverride,
            politicalProtocolManualSlots: _manualPoliticalProtocolSlots,
            showPoliticalProtocolOverlay: widget.enablePoliticalProtocolOverlay,
            showProfilePhoto: isPhotoVisible,
            deferLegacyTextPrime: deferRichPosterPreview,
            posterRenderCycle: posterRenderCycle,
            interactivePhotoEnabled: _canInteractWithPosterPhoto,
            photoShapeOverride: '',
            photoRenderModeOverride: '',
            photoFlipHorizontally: _photoUserAdjustment.flipHorizontally,
            photoXOffsetPercent: _photoUserAdjustment.xOffsetPercent,
            photoYOffsetPercent: _photoUserAdjustment.yOffsetPercent,
            onPhotoTap: _togglePosterPhotoFlipTap,
            stripGradientTapOffset: _stripGradientTapOffset,
            onNameStripTap: null,
            additionalPhotoSelection: _extraPhotoSelection,
            onAdditionalPhotoTap: personalizationConfig.showVideoExtraPhoto
                ? () => unawaited(_pickAdditionalPosterPhoto())
                : null,
            onPhotoDragDeltaPercent: _updatePosterPhotoDrag,
            onPhotoDragStateChanged: _setPhotoDragInProgress,
            onAspectRatioResolved: _handlePreviewAspectRatioResolved,
            onPosterReadyChanged: onPosterReadyChanged,
          )
        : _ResolvedTemplatePosterImage(
            imageAssetPath: item.imageAssetPath,
            imageUrl: item.imageUrl ?? '',
            imageStoragePath: item.imageStoragePath,
            thumbnailStoragePath: item.thumbnailStoragePath,
            thumbnailUrl: item.thumbnailUrl,
            posterIdForDebug: item.templateId,
            preferOriginalPosterQuality: renderOriginalPosterQuality,
            onAspectRatioResolved: _handlePreviewAspectRatioResolved,
            onFirstFrameReady: () => onPosterReadyChanged?.call(true),
          );
  }

  Widget _buildCapturedPosterPreview({
    required bool isPhotoVisible,
    ValueChanged<bool>? onPosterReadyChanged,
  }) {
    final preview = _buildPosterPreview(
      isPhotoVisible: isPhotoVisible,
      onPosterReadyChanged: onPosterReadyChanged,
    );
    final framedPreview = preview;
    if (deferRichPosterPreview) {
      return KeyedSubtree(key: _posterCaptureKey, child: framedPreview);
    }
    return KeyedSubtree(
      key: _posterCaptureKey,
      child: Screenshot(
        controller: _posterScreenshotController,
        child: framedPreview,
      ),
    );
  }

  Widget _buildCreatorIdLabel({bool compact = false}) {
    final creatorId = item.creatorPublicId?.trim() ?? '';
    if (creatorId.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, compact ? 3 : 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          creatorId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0,
          ),
        ),
      ),
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
    messenger.showTopSnackBar(AppSnackBar.build(content: Text(message)));
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
          telugu: 'Gallery permission was denied.',
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
          telugu: 'File save failed. Please try again.',
          english: 'File save failed. Please try again.',
        );
      default:
        return context.strings.localized(
          telugu: 'Download failed. Please try again.',
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
                              'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à± à°¸à±à°Ÿà±‡à°Ÿà°¸à± à°¤à°¨à°¿à°–à±€ à°šà±‡à°¸à±à°¤à±à°¨à±à°¨à°¾à°‚...',
                          english: 'Checking subscription status...',
                          hindi:
                              'à¤¸à¤¬à¥à¤¸à¤•à¥à¤°à¤¿à¤ªà¥à¤¶à¤¨ à¤¸à¥à¤¥à¤¿à¤¤à¤¿ à¤œà¤¾à¤‚à¤š à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚...',
                          tamil:
                              'à®šà®¨à¯à®¤à®¾ à®¨à®¿à®²à¯ˆ à®šà®°à®¿à®ªà®¾à®°à¯à®•à¯à®•à®¿à®±à¯‹à®®à¯...',
                          kannada:
                              'à²šà²‚à²¦à²¾à²¦à²¾à²°à²¿à²•à³† à²¸à³à²¥à²¿à²¤à²¿ à²ªà²°à²¿à²¶à³€à²²à²¿à²¸à³à²¤à³à²¤à²¿à²¦à³à²¦à³‡à²µà³†...',
                          malayalam:
                              'à´¸à´¬àµà´¸àµà´•àµà´°à´¿à´ªàµà´·àµ» à´¨à´¿à´² à´ªà´°à´¿à´¶àµ‹à´§à´¿à´•àµà´•àµà´¨àµà´¨àµ...',
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
                        telugu: 'à°°à°¦à±à°¦à±',
                        english: 'Cancel',
                        hindi: 'à¤°à¤¦à¥à¤¦ à¤•à¤°à¥‡à¤‚',
                        tamil: 'à®°à®¤à¯à®¤à¯à®šà¯†à®¯à¯',
                        kannada: 'à²°à²¦à³à²¦à³à²®à²¾à²¡à²¿',
                        malayalam: 'à´±à´¦àµà´¦à´¾à´•àµà´•àµà´•',
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
            title: _subscriptionDialogTitleCleanLocalized(screenContext),
            message: _subscriptionPromptCopyCleanLocalized(screenContext),
            trialTitle: _subscriptionTrialTitleCleanLocalized(screenContext),
            trialValue: _subscriptionTrialValueCleanLocalized(screenContext),
            monthlyTitle: _subscriptionMonthlyTitleCleanLocalized(
              screenContext,
            ),
            monthlyValue: _subscriptionMonthlyValueCleanLocalized(
              screenContext,
            ),
            renewalCopy: _subscriptionRenewalCopyCleanLocalized(screenContext),
            termsLabel: _subscriptionTermsLabelCleanLocalized(screenContext),
            skipLabel: _subscriptionSkipLabelCleanLocalized(screenContext),
            actionLabel: _subscriptionButtonLabelCleanLocalized(screenContext),
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
      telugu: 'Gallery permission was denied.',
      english: 'Gallery permission was denied.',
    );
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'Capture failed. Please try again.',
      english: 'Capture failed. Please try again.',
    );
    final posterSavedMessage = context.strings.localized(
      telugu: 'Poster saved to gallery.',
      english: 'Poster saved to gallery.',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'File save failed. Please try again.',
      english: 'File save failed. Please try again.',
    );
    final downloadFailedMessage = context.strings.localized(
      telugu: 'Download failed. Please try again.',
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
      if (item.isVideo) {
        final preparedVideoPath = await _ensurePreparedVideoFile();
        if (preparedVideoPath == null) {
          result = false;
          _showSnack(messenger, '$posterNotReadyMessage (video export)');
          return;
        }
        final fileName =
            'mana_poster_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final saveResult =
            await MediaExportService.saveVideoFileToGalleryDetailed(
              preparedVideoPath,
              fileName: fileName,
            );
        result = saveResult.success;
        if (result) {
          widget.onInteraction?.call(item, 'download');
          final posterId = item.templateId?.trim();
          if (posterId != null && posterId.isNotEmpty) {
            unawaited(
              ApprovedCreatorTemplateService().incrementPosterEngagementCount(
                posterId: posterId,
                isShare: false,
              ),
            );
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
        if (!context.mounted) {
          return;
        }
        _showSnack(
          messenger,
          '${_downloadSaveFailureMessage(context, saveResult)} '
          '(${saveResult.code ?? 'unknown'})',
        );
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
        widget.onInteraction?.call(item, 'download');
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
            ApprovedCreatorTemplateService().incrementPosterEngagementCount(
              posterId: posterId,
              isShare: false,
            ),
          );
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
      telugu: 'Capture failed. Please try again.',
      english: 'Capture failed. Please try again.',
    );
    final shareFailedMessage = context.strings.localized(
      telugu: 'Share failed. Please try again.',
      english: 'Share failed. Please try again.',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'File save failed. Please try again.',
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
        'Shared by $resolvedUserName using ${AppPublicInfo.appName}\n'
        'Download the app: ${AppPublicInfo.playStoreUrl}';
    try {
      final hasAccess = await _ensureSubscriptionAccess(context);
      if (!hasAccess) {
        result = false;
        return;
      }
      if (item.isVideo) {
        final preparedVideoPath = await _ensurePreparedVideoFile();
        if (preparedVideoPath == null) {
          result = false;
          _showSnack(messenger, '$posterNotReadyMessage (video export)');
          return;
        }
        if (!context.mounted) {
          result = false;
          return;
        }
        final box = context.findRenderObject() as RenderBox?;
        await MediaExportService.shareVideoFile(
          preparedVideoPath,
          text: shareText,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
        final posterId = item.templateId?.trim();
        if (posterId != null && posterId.isNotEmpty) {
          unawaited(
            ApprovedCreatorTemplateService().incrementPosterEngagementCount(
              posterId: posterId,
              isShare: true,
            ),
          );
          unawaited(
            UserPosterUploadsService.instance
                .incrementApprovedContributionCountForPoster(
                  approvedPosterTemplateId: posterId,
                  isShare: true,
                ),
          );
        }
        widget.onInteraction?.call(item, 'share');
        result = true;
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
          ApprovedCreatorTemplateService().incrementPosterEngagementCount(
            posterId: posterId,
            isShare: true,
          ),
        );
        unawaited(
          UserPosterUploadsService.instance
              .incrementApprovedContributionCountForPoster(
                approvedPosterTemplateId: posterId,
                isShare: true,
              ),
        );
      }
      widget.onInteraction?.call(item, 'share');
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
            telugu:
                'à°ªà±‹à°¸à±à°Ÿà°°à± à°¸à°¿à°¦à±à°§à°‚ à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
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
            initialPhotoShapeOverride: '',
            initialPhotoRenderModeOverride: '',
            initialPhotoFlipHorizontally: _photoUserAdjustment.flipHorizontally,
            initialPhotoXOffsetPercent: _photoUserAdjustment.xOffsetPercent,
            initialPhotoYOffsetPercent: _photoUserAdjustment.yOffsetPercent,
            lockTemplateLayers: false,
            autoProcessAddedPhotos: true,
            defaultAddedPhotoMaskShape: 'transparent_bottom_fade',
          ),
        ),
      );
      widget.onInteraction?.call(item, 'edit');
    } catch (error, stackTrace) {
      _homeDebugLogStack('poster editor open failed: $error', stackTrace);
      if (context.mounted) {
        _showSnack(
          messenger,
          strings.localized(
            telugu:
                'à°Žà°¡à°¿à°Ÿà°°à± à°“à°ªà±†à°¨à± à°•à°¾à°²à±‡à°¦à±. à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
            english: 'Could not open editor. Please try again.',
          ),
        );
      }
    } finally {
      _endAction();
    }
  }

  Widget _buildViewportItem(
    BuildContext context,
    AppStrings strings,
    bool canTogglePhoto,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final horizontalPadding = maxWidth >= 420 ? 6.0 : 4.0;
        final previewMaxWidth = math.max(
          1.0,
          maxWidth - (horizontalPadding * 2),
        );
        final previewAspectRatio = _resolvedPreviewAspectRatio;
        final previewNaturalHeight = previewAspectRatio == null
            ? constraints.maxHeight
            : previewMaxWidth / previewAspectRatio;
        final heightFirstTallVideo =
            item.isVideo &&
            previewAspectRatio != null &&
            previewAspectRatio < 0.7;
        final controlsReserveHeight = item.isVideo ? 0.0 : 96.0;
        final availablePreviewHeight = math.max(
          1.0,
          constraints.maxHeight - controlsReserveHeight,
        );
        final previewMaxHeight = math.min(
          heightFirstTallVideo ? availablePreviewHeight : constraints.maxHeight,
          previewNaturalHeight,
        );
        final effectivePreviewMaxWidth = heightFirstTallVideo
            ? math.min(previewMaxWidth, previewMaxHeight * previewAspectRatio)
            : previewMaxWidth;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            item.isVideo ? 4 : 10,
          ),
          child: Column(
            children: <Widget>[
              _buildCreatorIdLabel(compact: true),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _showPosterPhotoNotifier,
                  builder: (context, isPhotoVisible, _) {
                    final previewChild = _buildCapturedPosterPreview(
                      isPhotoVisible: isPhotoVisible,
                      onPosterReadyChanged: _handlePosterReadyState,
                    );
                    final preview = Center(
                      child: heightFirstTallVideo
                          ? SizedBox(
                              width: effectivePreviewMaxWidth,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: previewMaxHeight,
                                ),
                                child: previewChild,
                              ),
                            )
                          : ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: previewMaxWidth,
                                maxHeight: previewMaxHeight,
                              ),
                              child: previewChild,
                            ),
                    );
                    if (!item.isVideo) {
                      return preview;
                    }
                    return Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        preview,
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _VideoSideActions(
                              activeActionListenable: _activeActionNotifier,
                              videoExportReadyListenable:
                                  _videoExportReadyNotifier,
                              onShareTap: () => unawaited(_onShareTap(context)),
                              onDownloadTap: () =>
                                  unawaited(_onDownloadTap(context)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (deferRichPosterPreview)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (!item.isVideo) ...<Widget>[
                const SizedBox(height: 3),
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
                                    activeAction != null ||
                                    (item.isVideo &&
                                        !_videoExportReadyNotifier.value)
                                ? null
                                : () => unawaited(_onShareTap(context)),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/branding/whatsapp_icon.png',
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.share_rounded,
                                      size: 17,
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF25D366),
                              side: const BorderSide(color: Color(0xFF25D366)),
                              minimumSize: const Size.fromHeight(32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
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
                                      _invalidatePreparedPosterCache(
                                        cancelVideoExport: item.isVideo,
                                      );
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
                                  fontWeight: FontWeight.w800,
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
                                minimumSize: const Size.fromHeight(32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
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
                                    activeAction != null ||
                                    (item.isVideo &&
                                        !_videoExportReadyNotifier.value)
                                ? null
                                : () => unawaited(_onDownloadTap(context)),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 17),
                            label: Text(
                              isBusy
                                  ? strings.localized(
                                      telugu: 'à°¸à°¿à°¦à±à°§à°‚...',
                                      english: 'Preparing...',
                                    )
                                  : strings.downloadLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF64748B),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!item.isVideo)
                  ValueListenableBuilder<String?>(
                    valueListenable: _activeActionNotifier,
                    builder: (context, activeAction, _) {
                      final isBusy = activeAction == 'poster_editor';
                      final controlsDisabled =
                          deferRichPosterPreview || activeAction != null;
                      return Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: controlsDisabled
                                  ? null
                                  : () => unawaited(
                                      _openPosterPhotoEditor(context),
                                    ),
                              icon: isBusy
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 16,
                                    ),
                              label: Text(
                                strings.localized(
                                  telugu: '\u0C0E\u0C21\u0C3F\u0C1F\u0C4D',
                                  english: 'Edit',
                                ),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6D28D9),
                                side: const BorderSide(
                                  color: Color(0xFFC4B5FD),
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                minimumSize: const Size.fromHeight(32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                          if (_canAddPoliticalProtocolPhotos) ...<Widget>[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: controlsDisabled
                                    ? null
                                    : () => unawaited(
                                        _openPoliticalProtocolPhotoScreen(
                                          context,
                                        ),
                                      ),
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    strings.localized(
                                      telugu:
                                          'à°ªà±Šà°²à°¿à°Ÿà°¿à°•à°²à± à°«à±‹à°Ÿà±‹à°²à±',
                                      english: 'Add Political Photos',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                  side: const BorderSide(
                                    color: Color(0xFF99F6E4),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 7,
                                  ),
                                  minimumSize: const Size.fromHeight(32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: controlsDisabled
                                  ? null
                                  : _cyclePosterDesign,
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                              ),
                              label: Text(
                                strings.localized(
                                  telugu:
                                      '\u0C21\u0C3F\u0C1C\u0C48\u0C28\u0C4D \u0C2E\u0C3E\u0C30\u0C4D\u0C1A\u0C41',
                                  english: 'Change Design',
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6D28D9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                minimumSize: const Size.fromHeight(32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else
                  const SizedBox(height: 32),
                const SizedBox(height: 22),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = context.strings;
    final personalizationConfig = item.personalizationConfig;
    final canTogglePhoto = personalizationConfig != null && !item.isVideo;

    if (fillViewport) {
      return _buildViewportItem(context, strings, canTogglePhoto);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCreatorIdLabel(),
          ValueListenableBuilder<bool>(
            valueListenable: _showPosterPhotoNotifier,
            builder: (context, isPhotoVisible, _) {
              return _buildCapturedPosterPreview(
                isPhotoVisible: isPhotoVisible,
                onPosterReadyChanged: _handlePosterReadyState,
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
                                        _invalidatePreparedPosterCache(
                                          cancelVideoExport: item.isVideo,
                                        );
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
                              activeAction != null ||
                              (item.isVideo && !_videoExportReadyNotifier.value)
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
                                _invalidatePreparedPosterCache(
                                  cancelVideoExport: item.isVideo,
                                );
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
                              activeAction != null ||
                              (item.isVideo && !_videoExportReadyNotifier.value)
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
                final controlsDisabled =
                    deferRichPosterPreview || activeAction != null;
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controlsDisabled
                            ? null
                            : () => unawaited(_openPosterPhotoEditor(context)),
                        icon: isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 16,
                              ),
                        label: Text(
                          strings.localized(
                            telugu: '\u0C0E\u0C21\u0C3F\u0C1F\u0C4D',
                            english: 'Edit',
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6D28D9),
                          side: const BorderSide(color: Color(0xFFC4B5FD)),
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 8,
                          ),
                          minimumSize: const Size.fromHeight(36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (_canAddPoliticalProtocolPhotos) ...<Widget>[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controlsDisabled
                              ? null
                              : () => unawaited(
                                  _openPoliticalProtocolPhotoScreen(context),
                                ),
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 16,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              strings.localized(
                                telugu:
                                    'à°ªà±Šà°²à°¿à°Ÿà°¿à°•à°²à± à°«à±‹à°Ÿà±‹à°²à±',
                                english: 'Add Political Photos',
                              ),
                              style: const TextStyle(
                                fontSize: 10.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF99F6E4)),
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 7,
                            ),
                            minimumSize: const Size.fromHeight(36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controlsDisabled ? null : _cyclePosterDesign,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text(
                          strings.localized(
                            telugu:
                                '\u0C21\u0C3F\u0C1C\u0C48\u0C28\u0C4D \u0C2E\u0C3E\u0C30\u0C4D\u0C1A\u0C41',
                            english: 'Change Design',
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6D28D9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 8,
                          ),
                          minimumSize: const Size.fromHeight(36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => playbackEnabled;
}

class _TemplatePosterImage extends StatefulWidget {
  const _TemplatePosterImage({
    required this.imageAssetPath,
    required this.imageUrl,
    this.thumbnailUrl,
    this.fixedAspectRatio,
    this.preferOriginalPosterQuality = false,
    this.preferUltraLightDecode = false,
    this.onAspectRatioResolved,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? fixedAspectRatio;
  final bool preferOriginalPosterQuality;
  final bool preferUltraLightDecode;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onFirstFrameReady;

  @override
  State<_TemplatePosterImage> createState() => _TemplatePosterImageState();
}

class _TemplatePosterImageState extends State<_TemplatePosterImage> {
  static const int _feedPosterDecodeMinWidth = 280;
  static const int _feedPosterDecodeMaxWidth = 960;
  static const int _feedPosterThumbMinWidth = 180;
  static const int _feedPosterThumbMaxWidth = 360;
  static final Map<Object, double> _aspectRatioCache = <Object, double>{};
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
        oldWidget.preferUltraLightDecode != widget.preferUltraLightDecode ||
        oldWidget.fixedAspectRatio != widget.fixedAspectRatio ||
        oldWidget.onAspectRatioResolved != widget.onAspectRatioResolved) {
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
    final cachedAspectRatio = _aspectRatioCache[sourceKey];
    if (cachedAspectRatio != null && cachedAspectRatio > 0) {
      _aspectRatioSource = sourceKey;
      _resolvedAspectRatio = cachedAspectRatio;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _aspectRatioSource == sourceKey) {
          widget.onAspectRatioResolved?.call(cachedAspectRatio);
        }
      });
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
        _aspectRatioCache[sourceKey] = nextAspectRatio;
        void applyAspectRatio() {
          if (!mounted || _aspectRatioSource != sourceKey) {
            return;
          }
          setState(() {
            _resolvedAspectRatio = nextAspectRatio;
          });
          widget.onAspectRatioResolved?.call(nextAspectRatio);
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
              widget.preferUltraLightDecode;
          final cacheWidth = shouldPreferUltraLightDecode
              ? (width * pixelRatio).round().clamp(
                  _feedPosterThumbMinWidth,
                  _feedPosterThumbMaxWidth,
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
                    decodeWidth.clamp(
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
                  : FilterQuality.medium,
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
                  return child;
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
                        : FilterQuality.medium,
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
                  return Image(
                    image: widget.preferOriginalPosterQuality
                        ? NetworkImage(failed)
                        : ResizeImage.resizeIfNeeded(
                            decodeWidth,
                            null,
                            NetworkImage(failed),
                          ),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    filterQuality: widget.preferOriginalPosterQuality
                        ? FilterQuality.high
                        : FilterQuality.medium,
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
                      : FilterQuality.medium,
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

          final fixedAspectRatio = widget.fixedAspectRatio;
          if (fixedAspectRatio == null || fixedAspectRatio <= 0) {
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
          }

          final effectiveAspectRatio =
              fixedAspectRatio != null && fixedAspectRatio > 0
              ? fixedAspectRatio
              : _resolvedAspectRatio;
          final wrappedImageWidget =
              effectiveAspectRatio != null && effectiveAspectRatio > 0
              ? AspectRatio(
                  aspectRatio: effectiveAspectRatio,
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
    this.fixedAspectRatio,
    this.posterIdForDebug,
    this.preferOriginalPosterQuality = false,
    this.preferUltraLightDecode = false,
    this.onAspectRatioResolved,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final double? fixedAspectRatio;
  final String? posterIdForDebug;
  final bool preferOriginalPosterQuality;
  final bool preferUltraLightDecode;
  final ValueChanged<double>? onAspectRatioResolved;
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
        oldWidget.fixedAspectRatio != widget.fixedAspectRatio ||
        oldWidget.preferOriginalPosterQuality !=
            widget.preferOriginalPosterQuality ||
        oldWidget.preferUltraLightDecode != widget.preferUltraLightDecode ||
        oldWidget.onAspectRatioResolved != widget.onAspectRatioResolved) {
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

    if (_posterStringLooksHttpUrl(direct)) {
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
      if (!_shouldRunFirebaseUiServices) {
        _resolvedImageUrl = direct.isNotEmpty
            ? direct
            : (thumb.isNotEmpty ? thumb : _resolvedImageUrl);
        return;
      }
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
      fixedAspectRatio: widget.fixedAspectRatio,
      preferOriginalPosterQuality: widget.preferOriginalPosterQuality,
      preferUltraLightDecode: widget.preferUltraLightDecode,
      onAspectRatioResolved: widget.onAspectRatioResolved,
      onFirstFrameReady: widget.onFirstFrameReady,
    );
  }

  @override
  bool get wantKeepAlive => true;
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
    this.playbackEnabled = true,
    this.imageAssetPath,
    this.imageUrl,
    this.imageStoragePath,
    this.thumbnailStoragePath,
    this.thumbnailUrl,
    this.onAspectRatioResolved,
    this.onReady,
    this.onReplay,
  });

  final String videoUrl;
  final bool playbackEnabled;
  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onReady;
  final VoidCallback? onReplay;

  @override
  State<_FeedTapToPlayVideoPoster> createState() =>
      _FeedTapToPlayVideoPosterState();
}

class _FeedTapToPlayVideoPosterState extends State<_FeedTapToPlayVideoPoster> {
  bool _playing = true;

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
        playbackEnabled: widget.playbackEnabled,
        onAspectRatioResolved: widget.onAspectRatioResolved,
        onReady: widget.onReady,
        onReplay: widget.onReplay,
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
              onAspectRatioResolved: widget.onAspectRatioResolved,
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
  const _TemplateVideoPlayer({
    required this.videoUrl,
    this.playbackEnabled = true,
    this.onAspectRatioResolved,
    this.onReady,
    this.onReplay,
  });

  final String videoUrl;
  final bool playbackEnabled;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onReady;
  final VoidCallback? onReplay;

  @override
  State<_TemplateVideoPlayer> createState() => _TemplateVideoPlayerState();
}

class _TemplateVideoPlayerState extends State<_TemplateVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _readyNotified = false;
  bool _showPlayOverlay = false;
  bool _userPaused = false;
  Duration _lastPosition = Duration.zero;
  DateTime? _lastReplayNotificationAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWhenSettled();
    });
  }

  @override
  void didUpdateWidget(covariant _TemplateVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _readyNotified = false;
      _hasError = false;
      _showPlayOverlay = false;
      _userPaused = false;
      _lastPosition = Duration.zero;
      _lastReplayNotificationAt = null;
      unawaited(_disposeController());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeWhenSettled();
      });
    } else if (oldWidget.playbackEnabled != widget.playbackEnabled) {
      unawaited(_applyPlaybackPolicy());
    }
  }

  void _initializeWhenSettled([int attempt = 0]) {
    if (!mounted || _controller != null) {
      return;
    }
    if (Scrollable.recommendDeferredLoadingForContext(context) && attempt < 8) {
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        _initializeWhenSettled(attempt + 1);
      });
      return;
    }
    unawaited(_initialize());
  }

  void _handlePlaybackTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    if (duration.inMilliseconds <= 0) {
      _lastPosition = position;
      return;
    }
    final loopedToStart =
        position <= const Duration(milliseconds: 450) &&
        _lastPosition >= duration * 0.72 &&
        position < _lastPosition;
    if (loopedToStart) {
      final now = DateTime.now();
      final lastNotified = _lastReplayNotificationAt;
      if (lastNotified == null ||
          now.difference(lastNotified) > const Duration(milliseconds: 900)) {
        _lastReplayNotificationAt = now;
        widget.onReplay?.call();
      }
    }
    _lastPosition = position;
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_handlePlaybackTick);
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
      final videoSize = controller.value.size;
      if (videoSize.width > 0 && videoSize.height > 0) {
        widget.onAspectRatioResolved?.call(videoSize.width / videoSize.height);
      }
      await controller.setLooping(true);
      await controller.setVolume(1.0);
      controller.addListener(_handlePlaybackTick);
      if (widget.playbackEnabled && !_userPaused) {
        await controller.play();
      } else {
        await controller.pause();
      }
      if (!mounted) {
        return;
      }
      if (!_readyNotified) {
        _readyNotified = true;
        widget.onReady?.call();
      }
      setState(() {});
    } catch (_) {
      controller.removeListener(_handlePlaybackTick);
      if (!mounted) {
        return;
      }
      setState(() => _hasError = true);
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
      if (mounted) {
        setState(() {
          _userPaused = true;
          _showPlayOverlay = true;
        });
      }
      return;
    }
    _userPaused = false;
    await controller.play();
    if (mounted) {
      setState(() => _showPlayOverlay = false);
    }
  }

  Future<void> _applyPlaybackPolicy() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (!widget.playbackEnabled) {
      if (controller.value.isPlaying) {
        await controller.pause();
      }
      return;
    }
    if (!_userPaused && !controller.value.isPlaying) {
      await controller.play();
      if (mounted && _showPlayOverlay) {
        setState(() => _showPlayOverlay = false);
      }
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
          telugu: 'à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.',
          english: 'Please try again.',
        ),
      );
    }
    if (!controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: _ImageLoadingState(),
      );
    }
    final videoSize = controller.value.size;
    final videoWidth = videoSize.width > 0 ? videoSize.width : 9.0;
    final videoHeight = videoSize.height > 0 ? videoSize.height : 16.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(_togglePlayback()),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: <Widget>[
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: videoWidth,
                    height: videoHeight,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
            if (_showPlayOverlay)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.92),
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
    this.basePosterBuilder,
    this.videoReplayTickListenable,
    this.preferOriginalPosterQuality = false,
    required this.personalizationConfig,
    required this.viewerPosterProfile,
    required this.language,
    this.partyLogoAssetPath,
    this.politicalProtocolPhotoUrls = const <String>[],
    this.politicalProtocolLocalPhotoPaths = const <String>[],
    this.politicalProtocolSlotsOverride,
    this.politicalProtocolManualSlots = const <PoliticalProtocolSlot>[],
    this.showPoliticalProtocolOverlay = false,
    required this.showProfilePhoto,
    required this.deferLegacyTextPrime,
    required this.posterRenderCycle,
    required this.interactivePhotoEnabled,
    required this.photoShapeOverride,
    required this.photoRenderModeOverride,
    required this.photoFlipHorizontally,
    required this.photoXOffsetPercent,
    required this.photoYOffsetPercent,
    required this.onPhotoTap,
    required this.stripGradientTapOffset,
    this.onNameStripTap,
    required this.additionalPhotoSelection,
    required this.onAdditionalPhotoTap,
    required this.onPhotoDragDeltaPercent,
    required this.onPhotoDragStateChanged,
    this.onAspectRatioResolved,
    this.onPosterReadyChanged,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final EditorPageConfig? pageConfig;
  final Widget Function(VoidCallback onReady)? basePosterBuilder;
  final ValueListenable<int>? videoReplayTickListenable;
  final bool preferOriginalPosterQuality;
  final CreatorPosterPersonalization personalizationConfig;
  final PosterProfileData viewerPosterProfile;
  final AppLanguage language;
  final String? partyLogoAssetPath;
  final List<String> politicalProtocolPhotoUrls;
  final List<String> politicalProtocolLocalPhotoPaths;
  final List<PoliticalProtocolSlot>? politicalProtocolSlotsOverride;
  final List<PoliticalProtocolSlot> politicalProtocolManualSlots;
  final bool showPoliticalProtocolOverlay;
  final bool showProfilePhoto;
  final bool deferLegacyTextPrime;
  final int posterRenderCycle;
  final bool interactivePhotoEnabled;
  final String photoShapeOverride;
  final String photoRenderModeOverride;
  final bool photoFlipHorizontally;
  final double photoXOffsetPercent;
  final double photoYOffsetPercent;
  final VoidCallback onPhotoTap;
  final int stripGradientTapOffset;
  final VoidCallback? onNameStripTap;
  final _PosterExtraPhotoSelection? additionalPhotoSelection;
  final VoidCallback? onAdditionalPhotoTap;
  final void Function({
    required double deltaXPercent,
    required double deltaYPercent,
  })
  onPhotoDragDeltaPercent;
  final ValueChanged<bool> onPhotoDragStateChanged;
  final ValueChanged<double>? onAspectRatioResolved;
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
    <Color>[Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFC2410C)],
    <Color>[Color(0xFF581C87), Color(0xFFBE185D), Color(0xFF9D174D)],
    <Color>[Color(0xFF064E3B), Color(0xFF059669), Color(0xFF047857)],
    <Color>[Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFF991B1B)],
    <Color>[Color(0xFF082F49), Color(0xFF0891B2), Color(0xFF0F766E)],
    <Color>[Color(0xFF831843), Color(0xFFDB2777), Color(0xFFBE185D)],
    <Color>[Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF5B21B6)],
    <Color>[Color(0xFF134E4A), Color(0xFF0D9488), Color(0xFF115E59)],
    <Color>[Color(0xFF3F1D38), Color(0xFFC026D3), Color(0xFFDB2777)],
    <Color>[Color(0xFF3B0764), Color(0xFF9333EA), Color(0xFF7E22CE)],
  ];
  static int get posterStripGradientCount => _posterStripGradients.length;

  bool _basePosterReady = false;
  int _legacyPrimeGeneration = 0;
  final Map<String, String> _legacyTextOverrides = <String, String>{};
  final Set<String> _legacyTextRequestsInFlight = <String>{};
  Timer? _baseImageReadyFallbackTimer;

  List<String> _politicalProtocolAssetPaths() {
    if (!widget.showPoliticalProtocolOverlay) {
      return const <String>[];
    }
    return widget.politicalProtocolLocalPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _politicalProtocolImageUrls() {
    if (!widget.showPoliticalProtocolOverlay ||
        !widget.personalizationConfig.hasPoliticalProtocolLayout) {
      return const <String>[];
    }
    return widget.politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .take(widget.personalizationConfig.politicalProtocolSlots.length)
        .toList(growable: false);
  }

  Offset? _activePhotoDragLastGlobalPosition;
  int _videoReplayTick = 0;
  double? _resolvedPosterAspectRatio;

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

  void _handleVideoReplayTick() {
    final nextTick = widget.videoReplayTickListenable?.value ?? 0;
    if (_videoReplayTick == nextTick) {
      return;
    }
    setState(() => _videoReplayTick = nextTick);
  }

  @override
  void initState() {
    super.initState();
    _resolvedPosterAspectRatio = _initialPosterAspectRatio;
    if (!widget.deferLegacyTextPrime) {
      _scheduleLegacyPrime();
    }
    _videoReplayTick = widget.videoReplayTickListenable?.value ?? 0;
    widget.videoReplayTickListenable?.addListener(_handleVideoReplayTick);
    _scheduleBaseImageReadyFallback();
  }

  @override
  void dispose() {
    widget.videoReplayTickListenable?.removeListener(_handleVideoReplayTick);
    _baseImageReadyFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CreatorPosterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoReplayTickListenable !=
        widget.videoReplayTickListenable) {
      oldWidget.videoReplayTickListenable?.removeListener(
        _handleVideoReplayTick,
      );
      _videoReplayTick = widget.videoReplayTickListenable?.value ?? 0;
      widget.videoReplayTickListenable?.addListener(_handleVideoReplayTick);
    }
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageAssetPath != widget.imageAssetPath ||
        oldWidget.imageStoragePath != widget.imageStoragePath ||
        oldWidget.thumbnailStoragePath != widget.thumbnailStoragePath ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.pageConfig != widget.pageConfig ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _basePosterReady = false;
      _resolvedPosterAspectRatio = _initialPosterAspectRatio;
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
        oldWidget.stripGradientTapOffset != widget.stripGradientTapOffset ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      if (!widget.deferLegacyTextPrime) {
        _scheduleLegacyPrime();
      }
    }
    if (oldWidget.deferLegacyTextPrime && !widget.deferLegacyTextPrime) {
      _scheduleLegacyPrime();
    }
  }

  double? get _initialPosterAspectRatio {
    final pageConfig = widget.pageConfig;
    if (pageConfig != null &&
        pageConfig.widthPx > 0 &&
        pageConfig.heightPx > 0) {
      return pageConfig.aspectRatio;
    }
    return null;
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

  void _handlePosterAspectRatioResolved(double aspectRatio) {
    if (!mounted || aspectRatio <= 0) {
      return;
    }
    final existing = _resolvedPosterAspectRatio;
    if (existing != null && (existing - aspectRatio).abs() < 0.001) {
      return;
    }
    setState(() => _resolvedPosterAspectRatio = aspectRatio);
    widget.onAspectRatioResolved?.call(aspectRatio);
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
        '|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + widget.stripGradientTapOffset) %
        _randomPosterNameFonts.length;
    return _randomPosterNameFonts[index];
  }

  List<Color> _resolvePosterStripGradient(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|$resolvedName';
    var hash = 23;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 41 * hash + codeUnit;
    }
    final baseIndex = hash.abs() % _posterStripGradients.length;
    final resolvedIndex =
        (baseIndex + widget.stripGradientTapOffset) %
        _posterStripGradients.length;
    return _posterStripGradients[resolvedIndex];
  }

  int _resolvePosterStripModel(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|model|$resolvedName';
    var hash = 29;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 43 * hash + codeUnit;
    }
    return hash.abs() % 10;
  }

  Color _onStripColor(List<Color> colors) {
    return Colors.white;
  }

  String _resolveEnglishPosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|english|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + widget.stripGradientTapOffset) %
        _randomEnglishPosterNameFonts.length;
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

  Widget _buildNameDesignationSeparator({
    required Color fallbackColor,
    double fallbackWidth = 1.5,
    double fallbackHeight = 18,
  }) {
    final logoPath = widget.partyLogoAssetPath?.trim();
    if (logoPath == null || logoPath.isEmpty) {
      return Container(
        width: fallbackWidth,
        height: fallbackHeight,
        decoration: BoxDecoration(
          color: fallbackColor,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    final logo = logoPath.toLowerCase().endsWith('.svg')
        ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
        : Image.asset(
            logoPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(color: fallbackColor),
          );

    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(child: logo),
    );
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
                const SizedBox(width: 8),
                _buildNameDesignationSeparator(
                  fallbackColor: mutedStripTextColor,
                  fallbackWidth: 1.4,
                ),
                const SizedBox(width: 8),
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

  bool _usesLegacyTeluguStripFont(String text, String? fontFamily) {
    return _shouldConvertForLegacyTelugu(text, fontFamily);
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
        TeluguLegacyTextService.cachedValue(text, fontFamily: fontFamily) ??
        TeluguLegacyTextService.convertSync(text, fontFamily: fontFamily);
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
    final usesLegacyTeluguNameFont = _usesLegacyTeluguStripFont(
      resolvedName,
      displayNameFontFamily,
    );
    final nameScaleFactor = (widget.personalizationConfig.nameScale / 100)
        .clamp(0.45, 1.6);
    final designationScaleFactor =
        (widget.personalizationConfig.designationScale / 100).clamp(0.45, 1.6);
    final legacyTeluguNameBoost = usesLegacyTeluguNameFont ? 1.52 : 1.0;
    final personalNameFontSize =
        (isTeluguName ? 42.0 : 36.0) * nameScaleFactor * legacyTeluguNameBoost;
    final personalNameLineHeight = usesLegacyTeluguNameFont
        ? 0.94
        : (isTeluguName ? 0.82 : 0.95);
    final businessNameFontSize =
        (isTeluguName ? 34.0 : 28.0) * nameScaleFactor * legacyTeluguNameBoost;
    final designationFontFamily = _resolveDesignationFontFamily(
      resolvedDesignation,
    );
    final usesLegacyTeluguDesignationFont = _usesLegacyTeluguStripFont(
      resolvedDesignation,
      designationFontFamily,
    );
    final legacyTeluguDesignationBoost = usesLegacyTeluguDesignationFont
        ? 1.34
        : 1.0;
    final personalDesignationFontSize =
        26.0 * designationScaleFactor * legacyTeluguDesignationBoost;
    final businessDesignationFontSize =
        23.0 * designationScaleFactor * legacyTeluguDesignationBoost;
    final englishDesignationFontSize = 18.0 * designationScaleFactor;
    final englishPersonalNameFontSize = 26.0 * nameScaleFactor;
    final englishSplitNameFontSize = 24.0 * nameScaleFactor;
    final showPhoneInStrip = isBusinessProfile && resolvedPhone.isNotEmpty;
    final hasDesignationText =
        resolvedDesignation.isNotEmpty || showPhoneInStrip;
    final stripOverflowAllowance = 0.0;

    final showPhotoOverlay = _basePosterReady;
    final shouldShowBottomStrip =
        widget.personalizationConfig.showBottomStrip &&
        (widget.basePosterBuilder == null || _basePosterReady);

    Widget buildBottomStrip({
      required double stripScale,
      required double bottomStripPadding,
      required double stripPixelHeight,
    }) {
      return _buildPosterBottomStrip(
        resolvedName: resolvedName,
        resolvedDesignation: resolvedDesignation,
        displayNameFontFamily: displayNameFontFamily,
        designationFontFamily: designationFontFamily,
        isBusinessProfile: isBusinessProfile,
        isTeluguName: isTeluguName,
        businessNameFontSize: businessNameFontSize * stripScale,
        personalNameFontSize: personalNameFontSize * stripScale,
        personalDesignationFontSize: personalDesignationFontSize * stripScale,
        businessDesignationFontSize: businessDesignationFontSize * stripScale,
        englishDesignationFontSize: englishDesignationFontSize * stripScale,
        englishPersonalNameFontSize: englishPersonalNameFontSize * stripScale,
        englishSplitNameFontSize: englishSplitNameFontSize * stripScale,
        personalNameLineHeight: personalNameLineHeight,
        showPhoneInStrip: showPhoneInStrip,
        resolvedPhone: resolvedPhone,
        bottomStripPadding: bottomStripPadding,
        stripPixelHeight: stripPixelHeight,
      );
    }

    Widget buildPosterVisual() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio =
              widget.pageConfig?.aspectRatio ?? _resolvedPosterAspectRatio;
          final visualWidth =
              aspectRatio != null &&
                  constraints.maxHeight.isFinite &&
                  constraints.maxHeight > 0
              ? math.min(
                  constraints.maxWidth,
                  constraints.maxHeight * aspectRatio,
                )
              : constraints.maxWidth;
          final visualHeight = aspectRatio != null && aspectRatio > 0
              ? visualWidth / aspectRatio
              : constraints.maxHeight;
          final visualLeft = math.max(
            0.0,
            (constraints.maxWidth - visualWidth) / 2,
          );
          final ratioBaseStripHeight = math
              .max(
                1.0,
                visualHeight *
                    (widget.personalizationConfig.stripHeight / 100) *
                    0.5,
              )
              .clamp(1.0, math.max(1.0, visualHeight * 0.18))
              .toDouble();
          final estimatedNameHeight =
              (isBusinessProfile ? businessNameFontSize : personalNameFontSize)
                  .abs() *
              (usesLegacyTeluguNameFont ? 1.22 : 1.08);
          final estimatedDesignationHeight = hasDesignationText
              ? (isBusinessProfile
                            ? businessDesignationFontSize
                            : personalDesignationFontSize)
                        .abs() *
                    (usesLegacyTeluguDesignationFont ? 1.28 : 1.10)
              : 0.0;
          final fontNeededStripHeight =
              math.max(estimatedNameHeight, estimatedDesignationHeight) + 24.0;
          final stripPixelHeight = math
              .max(ratioBaseStripHeight, fontNeededStripHeight)
              .clamp(
                ratioBaseStripHeight,
                math.max(ratioBaseStripHeight, ratioBaseStripHeight * 1.08),
              )
              .toDouble();
          final defaultStripReferenceHeight = math
              .max(1.0, visualHeight * (16 / 100) * 0.5)
              .toDouble();
          final stripScale = (stripPixelHeight / defaultStripReferenceHeight)
              .clamp(0.04, 1.42)
              .toDouble();
          final scaledBottomStripPadding = (stripPixelHeight * 0.08)
              .clamp(0.0, 12.0)
              .toDouble();
          final stripWidthPercent = widget.personalizationConfig.stripWidth
              .clamp(35.0, 100.0)
              .toDouble();
          final stripWidthPx = visualWidth * (stripWidthPercent / 100);
          final stripCenterX = widget.personalizationConfig.stripX
              .clamp(stripWidthPercent / 2, 100 - (stripWidthPercent / 2))
              .toDouble();
          final stripLeft =
              visualLeft +
              (visualWidth * (stripCenterX / 100)) -
              (stripWidthPx / 2);
          final stripBottomPx =
              visualHeight *
              (widget.personalizationConfig.stripBottom.clamp(0.0, 20.0) / 100);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              if (widget.basePosterBuilder != null && widget.pageConfig != null)
                AspectRatio(
                  aspectRatio: widget.pageConfig!.aspectRatio,
                  child: widget.basePosterBuilder!(_handleBasePosterReady),
                )
              else if (widget.basePosterBuilder != null)
                widget.basePosterBuilder!(_handleBasePosterReady)
              else if (widget.pageConfig != null)
                _ResolvedTemplatePosterImage(
                  imageAssetPath: widget.imageAssetPath,
                  imageUrl: widget.imageUrl ?? '',
                  imageStoragePath: widget.imageStoragePath,
                  thumbnailStoragePath: widget.thumbnailStoragePath,
                  thumbnailUrl: widget.thumbnailUrl,
                  fixedAspectRatio: _resolvedPosterAspectRatio,
                  preferOriginalPosterQuality:
                      widget.preferOriginalPosterQuality,
                  onAspectRatioResolved: _handlePosterAspectRatioResolved,
                  onFirstFrameReady: _handleBasePosterReady,
                )
              else
                _ResolvedTemplatePosterImage(
                  imageAssetPath: widget.imageAssetPath,
                  imageUrl: widget.imageUrl ?? '',
                  imageStoragePath: widget.imageStoragePath,
                  thumbnailStoragePath: widget.thumbnailStoragePath,
                  thumbnailUrl: widget.thumbnailUrl,
                  preferOriginalPosterQuality:
                      widget.preferOriginalPosterQuality,
                  onAspectRatioResolved: _handlePosterAspectRatioResolved,
                  onFirstFrameReady: _handleBasePosterReady,
                ),
              if (widget.showPoliticalProtocolOverlay &&
                  (_politicalProtocolImageUrls().isNotEmpty ||
                      _politicalProtocolAssetPaths().isNotEmpty))
                Positioned(
                  left: visualLeft,
                  top: 0,
                  width: visualWidth,
                  height: visualHeight,
                  child: IgnorePointer(
                    child: _PoliticalProtocolPhotoSlots(
                      assetPaths: _politicalProtocolAssetPaths(),
                      imageUrls: _politicalProtocolImageUrls(),
                      slots:
                          widget.politicalProtocolSlotsOverride ??
                          widget.personalizationConfig.politicalProtocolSlots,
                      assetSlots: widget.politicalProtocolManualSlots,
                    ),
                  ),
                ),
              if (widget.showProfilePhoto && shouldShowIdentityVisual)
                Positioned(
                  left: visualLeft,
                  top: 0,
                  width: visualWidth,
                  height: math.max(
                    1.0,
                    constraints.maxHeight + stripOverflowAllowance,
                  ),
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
                            constraints.maxHeight,
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
                              : (widget.photoRenderModeOverride
                                        .trim()
                                        .isNotEmpty
                                    ? widget.photoRenderModeOverride.trim()
                                    : widget
                                          .personalizationConfig
                                          .photoRenderMode);
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
                              (widget
                                      .personalizationConfig
                                      .videoExtraPhotoScale /
                                  100);
                          final additionalPhotoHeight =
                              additionalPhotoWidth /
                              _photoMaskAspectRatio(additionalPhotoShape);
                          final additionalPhotoLeft =
                              (constraints.maxWidth *
                                  (widget
                                          .personalizationConfig
                                          .videoExtraPhotoX /
                                      100)) -
                              (additionalPhotoWidth / 2);
                          final additionalPhotoTop =
                              (baseImageHeight *
                                  (widget
                                          .personalizationConfig
                                          .videoExtraPhotoY /
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
                          Widget animatedOverlay({
                            required Widget child,
                            required String animation,
                            required double overlayWidth,
                            required double overlayHeight,
                          }) {
                            final normalizedAnimation = animation
                                .trim()
                                .toLowerCase();
                            return TweenAnimationBuilder<double>(
                              key: ValueKey<String>(
                                '$normalizedAnimation-$overlayWidth-$overlayHeight-$_videoReplayTick',
                              ),
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1150),
                              curve: Curves.easeOutCubic,
                              builder: (context, progress, child) {
                                var offset = Offset.zero;
                                var scale = 1.0;
                                switch (normalizedAnimation) {
                                  case 'top_to_place':
                                    offset = Offset(
                                      0,
                                      (-baseImageHeight - overlayHeight) *
                                          (1 - progress),
                                    );
                                    break;
                                  case 'bottom_to_place':
                                    offset = Offset(
                                      0,
                                      (baseImageHeight + overlayHeight) *
                                          (1 - progress),
                                    );
                                    break;
                                  case 'left_to_place':
                                    offset = Offset(
                                      (-constraints.maxWidth - overlayWidth) *
                                          (1 - progress),
                                      0,
                                    );
                                    break;
                                  case 'right_to_place':
                                    offset = Offset(
                                      (constraints.maxWidth + overlayWidth) *
                                          (1 - progress),
                                      0,
                                    );
                                    break;
                                  case 'zoom_in':
                                    scale = 0.22 + (0.78 * progress);
                                    break;
                                  case 'zoom_out':
                                    scale = 1.35 - (0.35 * progress);
                                    break;
                                }
                                return Transform.translate(
                                  offset: offset,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          }

                          return Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned(
                                left: left,
                                top: top,
                                width: width,
                                height: height,
                                child: animatedOverlay(
                                  animation: widget
                                      .personalizationConfig
                                      .photoAnimation,
                                  overlayWidth: width,
                                  overlayHeight: height,
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
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                            (
                                              LongPressGestureRecognizer
                                              instance,
                                            ) {
                                              if (!widget
                                                  .interactivePhotoEnabled) {
                                                instance
                                                  ..onLongPressStart = null
                                                  ..onLongPressMoveUpdate = null
                                                  ..onLongPressEnd = null
                                                  ..onLongPressCancel = null;
                                                return;
                                              }
                                              instance.onLongPressStart =
                                                  (
                                                    LongPressStartDetails
                                                    details,
                                                  ) => _startPhotoDrag(
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
                                                    maxWidth:
                                                        constraints.maxWidth,
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
                                      edgeStyle: widget
                                          .personalizationConfig
                                          .edgeStyle,
                                      photoRenderMode: effectivePhotoRenderMode,
                                      isBusinessLogo: isBusinessProfile,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..scaleByDouble(
                                            widget.photoFlipHorizontally &&
                                                    !isBusinessProfile
                                                ? -1
                                                : 1,
                                            1,
                                            1,
                                            1,
                                          ),
                                        child: PosterIdentityVisual(
                                          profile: widget.viewerPosterProfile,
                                          fit: isBusinessProfile
                                              ? BoxFit.contain
                                              : effectivePhotoRenderMode ==
                                                    'cutout'
                                              ? BoxFit.contain
                                              : BoxFit.cover,
                                          preferOriginalPersonalPhoto:
                                              effectivePhotoRenderMode ==
                                              'original',
                                          allowOriginalFallbackWhenCutoutUnavailable:
                                              effectivePhotoRenderMode ==
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
                                    child: animatedOverlay(
                                      animation: widget
                                          .personalizationConfig
                                          .videoExtraPhotoAnimation,
                                      overlayWidth: additionalPhotoWidth,
                                      overlayHeight: additionalPhotoHeight,
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
                  ),
                ),
              if (shouldShowBottomStrip)
                Positioned(
                  left: stripLeft,
                  width: stripWidthPx,
                  bottom: stripBottomPx,
                  child: SizedBox(
                    height: stripPixelHeight,
                    child: buildBottomStrip(
                      stripScale: stripScale,
                      bottomStripPadding: scaledBottomStripPadding,
                      stripPixelHeight: stripPixelHeight,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    Widget buildFramedPoster() {
      return ClipRect(child: buildPosterVisual());
    }

    final posterAspectRatio = _resolvedPosterAspectRatio;
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: posterAspectRatio != null
            ? AspectRatio(
                aspectRatio: posterAspectRatio,
                child: buildFramedPoster(),
              )
            : buildFramedPoster(),
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
    required double personalDesignationFontSize,
    required double businessDesignationFontSize,
    required double englishDesignationFontSize,
    required double englishPersonalNameFontSize,
    required double englishSplitNameFontSize,
    required double personalNameLineHeight,
    required bool showPhoneInStrip,
    required String resolvedPhone,
    required double bottomStripPadding,
    required double stripPixelHeight,
  }) {
    final stripGradient = _resolvePosterStripGradient(resolvedName);
    final stripModel = _resolvePosterStripModel(resolvedName);
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
            flex: 58,
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
          const SizedBox(width: 6),
          _buildNameDesignationSeparator(fallbackColor: dividerColor),
          const SizedBox(width: 6),
          Expanded(
            flex: 42,
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
                      ? englishSplitNameFontSize
                      : businessNameFontSize,
                  designationFontSize: _isEnglishOnlyText(resolvedName)
                      ? englishDesignationFontSize
                      : businessDesignationFontSize,
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
              fontSize: englishPersonalNameFontSize,
              height: 1.0,
            ),
          ),
        ] else if (_isEnglishOnlyText(resolvedName) &&
            resolvedDesignation.isNotEmpty) ...<Widget>[
          buildSplitStripRow(
            nameFontSize: englishSplitNameFontSize,
            designationFontSize: englishDesignationFontSize,
            nameFontWeight: FontWeight.w700,
            designationFontWeight: FontWeight.w600,
            nameHeight: 1.0,
            designationHeight: 1.0,
          ),
        ] else ...<Widget>[
          if (resolvedDesignation.isNotEmpty)
            buildSplitStripRow(
              nameFontSize: personalNameFontSize,
              designationFontSize: personalDesignationFontSize,
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

    Widget accentLayer() {
      final hairlineWidth = (stripPixelHeight * 0.035).clamp(0.4, 2.8);
      final capsuleHorizontalInset = (stripPixelHeight * 0.95).clamp(1.0, 14.0);
      final capsuleVerticalInset = (stripPixelHeight * 0.12).clamp(0.0, 7.0);
      final outlineInset = (stripPixelHeight * 0.10).clamp(0.0, 7.0);
      switch (stripModel) {
        case 0:
          return Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: hairlineWidth,
                  ),
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.22),
                    width: hairlineWidth,
                  ),
                ),
              ),
            ),
          );
        case 1:
          return Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalStripAccentPainter(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          );
        case 2:
          return Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: stripGradient.last.withValues(alpha: 0.86),
                    width: hairlineWidth,
                  ),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: stripGradient.last.withValues(alpha: 0.38),
                    blurRadius: 20,
                    spreadRadius: -6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
            ),
          );
        case 3:
          return Positioned(
            left: capsuleHorizontalInset,
            right: capsuleHorizontalInset,
            top: capsuleVerticalInset,
            bottom: capsuleVerticalInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
            ),
          );
        case 4:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.42,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          );
        case 5:
          return Positioned.fill(
            child: CustomPaint(
              painter: _DotStripAccentPainter(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          );
        case 6:
          return Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.50),
                    width: hairlineWidth,
                  ),
                ),
              ),
            ),
          );
        case 7:
          return Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.34,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          );
        case 8:
          return Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const <double>[0, 0.5, 1],
                ),
              ),
            ),
          );
        default:
          return Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: outlineInset,
                vertical: outlineInset,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: hairlineWidth,
                  ),
                ),
              ),
            ),
          );
      }
    }

    final strip = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: stripModel == 1 ? Alignment.topLeft : Alignment.centerLeft,
          end: stripModel == 1 ? Alignment.bottomRight : Alignment.centerRight,
          colors: stripGradient,
        ),
      ),
      child: Stack(
        children: <Widget>[
          accentLayer(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: stripModel == 3 ? 24 : 14,
              vertical: bottomStripPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    final onTap = widget.onNameStripTap;
    if (onTap == null) {
      return strip;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: strip,
    );
  }
}

class _DiagonalStripAccentPainter extends CustomPainter {
  const _DiagonalStripAccentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final stripeWidth = size.width * 0.18;
    for (
      var start = -size.width;
      start < size.width * 1.4;
      start += stripeWidth * 1.55
    ) {
      final path = Path()
        ..moveTo(start, size.height)
        ..lineTo(start + stripeWidth, size.height)
        ..lineTo(start + stripeWidth + size.height * 0.7, 0)
        ..lineTo(start + size.height * 0.7, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripAccentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DotStripAccentPainter extends CustomPainter {
  const _DotStripAccentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final gap = size.height * 0.36;
    final radius = size.height * 0.035;
    for (var x = gap * 0.8; x < size.width; x += gap) {
      canvas.drawCircle(Offset(x, size.height * 0.28), radius, paint);
      canvas.drawCircle(
        Offset(x + gap * 0.45, size.height * 0.72),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotStripAccentPainter oldDelegate) {
    return oldDelegate.color != color;
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
        return BoxDecoration(color: Colors.transparent, shape: BoxShape.circle);
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
        return const BoxDecoration(color: Colors.transparent);
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
      return ClipOval(clipBehavior: Clip.antiAlias, child: imageWidget);
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
    case 'transparent_bottom_fade':
    case 'transparent_clean':
    case 'vertical_rectangle':
    case 'blob':
    case 'wave_bottom':
    case 'arch':
    case 'parallelogram':
      return 4 / 5;
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
              _repairLegacyUiText(title),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _repairLegacyUiText(subtitle),
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

class _EmptyPosterGameState extends StatefulWidget {
  const _EmptyPosterGameState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.categorySlug,
    required this.categoryLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String categorySlug;
  final String categoryLabel;

  @override
  State<_EmptyPosterGameState> createState() => _EmptyPosterGameStateState();
}

class _EmptyPosterGameStateState extends State<_EmptyPosterGameState> {
  bool _gameStarted = false;
  bool _gameDismissed = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Column(
      children: <Widget>[
        _HomeFeedState(
          icon: widget.icon,
          title: widget.title,
          subtitle: widget.subtitle,
        ),
        const SizedBox(height: 12),
        if (!_gameDismissed)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _gameStarted
                ? _SnakePosterGameCard(
                    key: ValueKey<String>(
                      'snake-${widget.categorySlug}-${widget.categoryLabel}',
                    ),
                    onExit: () => setState(() => _gameDismissed = true),
                  )
                : _SnakeCountdownCard(
                    key: const ValueKey<String>('snake-countdown'),
                    label: strings.localized(
                      telugu:
                          'à°ªà±‹à°¸à±à°Ÿà°°à±à°²à± à°µà°šà±à°šà±‡ à°µà°°à°•à± Snake game à°†à°¡à°‚à°¡à°¿',
                      english: 'Play Snake while posters load',
                      hindi: 'Posters à¤†à¤¨à¥‡ à¤¤à¤• Snake à¤–à¥‡à¤²à¥‡à¤‚',
                      tamil:
                          'Posters à®µà®°à¯à®®à¯ à®µà®°à¯ˆ Snake à®µà®¿à®³à¯ˆà®¯à®¾à®Ÿà¯à®™à¯à®•à®³à¯',
                      kannada:
                          'Posters à²¬à²°à³à²µà²µà²°à³†à²—à³† Snake à²†à²¡à²¿',
                      malayalam:
                          'Posters à´µà´°àµà´‚ à´µà´°àµ† Snake à´•à´³à´¿à´•àµà´•àµà´•',
                    ),
                    onPlay: () => setState(() => _gameStarted = true),
                  ),
          ),
      ],
    );
  }
}

class _SnakeCountdownCard extends StatelessWidget {
  const _SnakeCountdownCard({
    super.key,
    required this.label,
    required this.onPlay,
  });

  final String label;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.sports_esports_rounded, size: 18),
            label: Text(
              strings.localized(
                telugu: 'Play',
                english: 'Play',
                hindi: 'Play',
                tamil: 'Play',
                kannada: 'Play',
                malayalam: 'Play',
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SnakeDirection { up, right, down, left }

class _SnakePosterGameCard extends StatefulWidget {
  const _SnakePosterGameCard({super.key, required this.onExit});

  final VoidCallback onExit;

  @override
  State<_SnakePosterGameCard> createState() => _SnakePosterGameCardState();
}

class _SnakePosterGameCardState extends State<_SnakePosterGameCard> {
  static const int _gridSize = 14;
  static const Duration _tickDuration = Duration(milliseconds: 230);
  final math.Random _random = math.Random();
  Timer? _timer;
  List<math.Point<int>> _snake = const <math.Point<int>>[
    math.Point<int>(6, 7),
    math.Point<int>(5, 7),
    math.Point<int>(4, 7),
  ];
  math.Point<int> _food = const math.Point<int>(10, 7);
  _SnakeDirection _direction = _SnakeDirection.right;
  _SnakeDirection _nextDirection = _SnakeDirection.right;
  int _score = 0;
  bool _gameOver = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, (_) => _tick());
  }

  void _tick() {
    if (!mounted || _gameOver || _isPaused) {
      return;
    }
    final head = _snake.first;
    final direction = _nextDirection;
    final nextHead = switch (direction) {
      _SnakeDirection.up => math.Point<int>(head.x, head.y - 1),
      _SnakeDirection.right => math.Point<int>(head.x + 1, head.y),
      _SnakeDirection.down => math.Point<int>(head.x, head.y + 1),
      _SnakeDirection.left => math.Point<int>(head.x - 1, head.y),
    };
    final wrappedHead = math.Point<int>(
      (nextHead.x + _gridSize) % _gridSize,
      (nextHead.y + _gridSize) % _gridSize,
    );
    final ateFood = wrappedHead == _food;
    final nextSnake = <math.Point<int>>[wrappedHead, ..._snake];
    if (!ateFood) {
      nextSnake.removeLast();
    }
    final hitSelf = nextSnake.skip(1).contains(wrappedHead);
    if (hitSelf) {
      setState(() => _gameOver = true);
      _timer?.cancel();
      return;
    }
    setState(() {
      _direction = direction;
      _snake = nextSnake;
      if (ateFood) {
        _score++;
        _food = _newFood(nextSnake);
      }
    });
  }

  math.Point<int> _newFood(List<math.Point<int>> occupied) {
    if (occupied.length >= _gridSize * _gridSize) {
      return const math.Point<int>(0, 0);
    }
    while (true) {
      final point = math.Point<int>(
        _random.nextInt(_gridSize),
        _random.nextInt(_gridSize),
      );
      if (!occupied.contains(point)) {
        return point;
      }
    }
  }

  void _setDirection(_SnakeDirection direction) {
    final opposite = switch (_direction) {
      _SnakeDirection.up => _SnakeDirection.down,
      _SnakeDirection.right => _SnakeDirection.left,
      _SnakeDirection.down => _SnakeDirection.up,
      _SnakeDirection.left => _SnakeDirection.right,
    };
    if (direction == opposite) {
      return;
    }
    setState(() => _nextDirection = direction);
  }

  void _handleDrag(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance < 80) {
      return;
    }
    if (velocity.dx.abs() > velocity.dy.abs()) {
      _setDirection(
        velocity.dx > 0 ? _SnakeDirection.right : _SnakeDirection.left,
      );
    } else {
      _setDirection(
        velocity.dy > 0 ? _SnakeDirection.down : _SnakeDirection.up,
      );
    }
  }

  void _restart() {
    setState(() {
      _snake = const <math.Point<int>>[
        math.Point<int>(6, 7),
        math.Point<int>(5, 7),
        math.Point<int>(4, 7),
      ];
      _food = const math.Point<int>(10, 7);
      _direction = _SnakeDirection.right;
      _nextDirection = _SnakeDirection.right;
      _score = 0;
      _gameOver = false;
      _isPaused = false;
    });
    _startTimer();
  }

  void _togglePause() {
    if (_gameOver) {
      _restart();
      return;
    }
    setState(() => _isPaused = !_isPaused);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF07111F), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x240F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.videogame_asset_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.localized(
                    telugu: 'Snake Game',
                    english: 'Snake Game',
                    hindi: 'Snake Game',
                    tamil: 'Snake Game',
                    kannada: 'Snake Game',
                    malayalam: 'Snake Game',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SnakeScorePill(score: _score),
              const SizedBox(width: 8),
              _SnakePauseButton(isPaused: _isPaused, onTap: _togglePause),
              const SizedBox(width: 8),
              _SnakeExitButton(onTap: widget.onExit),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _handleDrag,
            onVerticalDragEnd: _handleDrag,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF02131C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    CustomPaint(
                      painter: _SnakeBoardPainter(
                        gridSize: _gridSize,
                        snake: _snake,
                        food: _food,
                        direction: _direction,
                      ),
                      child: const SizedBox.expand(),
                    ),
                    if (_gameOver)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                strings.localized(
                                  telugu: 'Game Over',
                                  english: 'Game Over',
                                  hindi: 'Game Over',
                                  tamil: 'Game Over',
                                  kannada: 'Game Over',
                                  malayalam: 'Game Over',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _restart,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                ),
                                child: Text(
                                  strings.localized(
                                    telugu: 'à°®à°³à±à°³à±€ à°†à°¡à±',
                                    english: 'Play again',
                                    hindi: 'Play again',
                                    tamil: 'Play again',
                                    kannada: 'Play again',
                                    malayalam: 'Play again',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isPaused && !_gameOver)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.38),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.pause_circle_filled_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.localized(
                                  telugu: 'Paused',
                                  english: 'Paused',
                                  hindi: 'Paused',
                                  tamil: 'Paused',
                                  kannada: 'Paused',
                                  malayalam: 'Paused',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
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
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _SnakeControlButton(
                icon: Icons.keyboard_arrow_left_rounded,
                onTap: () => _setDirection(_SnakeDirection.left),
              ),
              const SizedBox(width: 8),
              Column(
                children: <Widget>[
                  _SnakeControlButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onTap: () => _setDirection(_SnakeDirection.up),
                  ),
                  const SizedBox(height: 8),
                  _SnakeControlButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () => _setDirection(_SnakeDirection.down),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              _SnakeControlButton(
                icon: Icons.keyboard_arrow_right_rounded,
                onTap: () => _setDirection(_SnakeDirection.right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnakeScorePill extends StatelessWidget {
  const _SnakeScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Score $score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SnakePauseButton extends StatelessWidget {
  const _SnakePauseButton({required this.isPaused, required this.onTap});

  final bool isPaused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _SnakeExitButton extends StatelessWidget {
  const _SnakeExitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _SnakeControlButton extends StatelessWidget {
  const _SnakeControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 46,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _SnakeBoardPainter extends CustomPainter {
  const _SnakeBoardPainter({
    required this.gridSize,
    required this.snake,
    required this.food,
    required this.direction,
  });

  final int gridSize;
  final List<math.Point<int>> snake;
  final math.Point<int> food;
  final _SnakeDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var index = 1; index < gridSize; index++) {
      final offset = index * cell;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        gridPaint,
      );
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), gridPaint);
    }

    final foodCenter = Offset(
      food.x * cell + cell / 2,
      food.y * cell + cell / 2,
    );
    canvas
      ..drawCircle(
        foodCenter,
        cell * 0.34,
        Paint()..color = const Color(0xFFEF4444),
      )
      ..drawCircle(
        foodCenter.translate(-cell * 0.1, -cell * 0.11),
        cell * 0.11,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      )
      ..drawOval(
        Rect.fromCenter(
          center: foodCenter.translate(cell * 0.13, -cell * 0.35),
          width: cell * 0.3,
          height: cell * 0.16,
        ),
        Paint()..color = const Color(0xFF22C55E),
      );

    for (var index = snake.length - 1; index >= 0; index--) {
      final part = snake[index];
      final isHead = index == 0;
      final center = Offset(part.x * cell + cell / 2, part.y * cell + cell / 2);
      final radius = isHead ? cell * 0.43 : cell * (0.34 + index * 0.002);
      canvas.drawCircle(
        center.translate(0, cell * 0.05),
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            center.translate(-cell * 0.14, -cell * 0.18),
            radius * 1.4,
            isHead
                ? const <Color>[Color(0xFFBBF7D0), Color(0xFF16A34A)]
                : const <Color>[Color(0xFF99F6E4), Color(0xFF0D9488)],
          ),
      );
      if (!isHead && index.isOdd) {
        canvas.drawCircle(
          center.translate(-cell * 0.06, -cell * 0.06),
          cell * 0.07,
          Paint()..color = Colors.white.withValues(alpha: 0.16),
        );
      }
      if (isHead) {
        _paintSnakeFace(canvas, center, cell);
      }
    }
  }

  void _paintSnakeFace(Canvas canvas, Offset center, double cell) {
    final eyePaint = Paint()..color = const Color(0xFF06220F);
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final tonguePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final offsets = switch (direction) {
      _SnakeDirection.up => (
        Offset(-cell * 0.15, -cell * 0.14),
        Offset(cell * 0.15, -cell * 0.14),
        Offset(0, -cell * 0.44),
      ),
      _SnakeDirection.right => (
        Offset(cell * 0.14, -cell * 0.15),
        Offset(cell * 0.14, cell * 0.15),
        Offset(cell * 0.44, 0),
      ),
      _SnakeDirection.down => (
        Offset(-cell * 0.15, cell * 0.14),
        Offset(cell * 0.15, cell * 0.14),
        Offset(0, cell * 0.44),
      ),
      _SnakeDirection.left => (
        Offset(-cell * 0.14, -cell * 0.15),
        Offset(-cell * 0.14, cell * 0.15),
        Offset(-cell * 0.44, 0),
      ),
    };
    final firstEye = center + offsets.$1;
    final secondEye = center + offsets.$2;
    canvas
      ..drawCircle(firstEye, cell * 0.06, eyePaint)
      ..drawCircle(secondEye, cell * 0.06, eyePaint)
      ..drawCircle(
        firstEye.translate(cell * 0.015, -cell * 0.018),
        cell * 0.018,
        shinePaint,
      )
      ..drawCircle(
        secondEye.translate(cell * 0.015, -cell * 0.018),
        cell * 0.018,
        shinePaint,
      );

    final tongueStart = center + offsets.$3 * 0.72;
    final tongueEnd = center + offsets.$3;
    canvas.drawLine(tongueStart, tongueEnd, tonguePaint);
    final forkA = switch (direction) {
      _SnakeDirection.up || _SnakeDirection.down => Offset(-cell * 0.07, 0),
      _SnakeDirection.left || _SnakeDirection.right => Offset(0, -cell * 0.07),
    };
    canvas
      ..drawLine(tongueEnd, tongueEnd + forkA, tonguePaint)
      ..drawLine(tongueEnd, tongueEnd - forkA, tonguePaint);
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter oldDelegate) =>
      oldDelegate.snake != snake ||
      oldDelegate.food != food ||
      oldDelegate.direction != direction;
}

// ignore: unused_element
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

class _PosterFeedSkeletonViewport extends StatelessWidget {
  const _PosterFeedSkeletonViewport();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => const _PosterSkeletonCard(),
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
