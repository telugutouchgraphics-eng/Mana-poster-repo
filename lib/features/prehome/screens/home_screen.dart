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
    show
        compute,
        kDebugMode,
        kIsWeb,
        kProfileMode,
        mapEquals,
        setEquals,
        ValueListenable;
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
import 'package:mana_poster/app/services/rewarded_access_service.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/app/services/time_slot_service.dart';
import 'package:mana_poster/app/startup/post_splash_startup_gate.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/models/political_party.dart';
import 'package:mana_poster/features/prehome/screens/daily_quiz_screen.dart';
import 'package:mana_poster/features/prehome/screens/political_parties_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/services/poster_downloads_service.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_home_banner_service.dart';
import 'package:mana_poster/features/prehome/services/app_location_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/app_survey_service.dart';
import 'package:mana_poster/features/prehome/services/app_update_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_schedule_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_lunar_event_dates.dart';
import 'package:mana_poster/features/prehome/services/home_export_ad_settings_service.dart';
import 'package:mana_poster/features/prehome/services/manual_event_category_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/services/permanent_category_service.dart';
import 'package:mana_poster/features/prehome/services/personalized_video_export_service.dart';
import 'package:mana_poster/features/prehome/services/political_party_logo_service.dart';
import 'package:mana_poster/features/prehome/services/political_party_service.dart';
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
            telugu: 'లింక్ తెరవలేకపోయాము. దయచేసి మళ్లీ ప్రయత్నించండి.',
            english: 'Could not open the link. Please try again.',
            hindi: 'लिंक नहीं खोला जा सका। कृपया पुनः प्रयास करें।',
            tamil: 'இணைப்பைத் திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
            kannada: 'ಲಿಂಕ್ ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
            malayalam: 'ലിങ്ക് തുറക്കാനായില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
            marathi: 'लिंक उघडता आली नाही. कृपया पुन्हा प्रयत्न करा.',
            gujarati: 'લિંક ખોલી શકાઈ નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
            bengali: 'লিঙ্কটি খোলা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
            punjabi:
                'ਲਿੰਕ ਖੋਲ੍ਹਿਆ ਨਹੀਂ ਜਾ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
            odia:
                'ଲିଙ୍କ୍ ଖୋଲିବା ସମ୍ଭବ ହେଲାନାହିଁ। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
            assamese: 'লিংকটো খুলিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
            konkani: 'दुवो उगडूंक जालो ना. उपकार करून परत यत्न करा.',
            nepali: 'लिङ्क खोल्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
            meitei: 'লিঙ্ক হাংদোকপা ঙমদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
            mizo: 'Link hawn theih a ni lo. Khawngaihin ti nawn leh rawh.',
            kashmiri:
                'لِنک ہیٚکہ نہٕ کٔڈِتھ۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
            ladakhi: 'འབྲེལ་མཐུད་ཁ་འབྱེད་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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

bool _shouldRetryUnavailableNetworkImage(String raw) {
  return false;
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
    this.publishAtMillis = 0,
    this.preferOriginalPosterQuality = false,
    this.viewCount = 0,
    this.shareCount = 0,
    this.downloadCount = 0,
    this.displayViewCount = 0,
    this.displayShareCount = 0,
    this.displayDownloadCount = 0,
    this.displayEngagementCount = 0,
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
  final int publishAtMillis;

  /// Firestore `categoryId` only ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â used for home dynamic chips, not label tokens.
  final String? primaryFirestoreCategoryId;

  /// Firestore manual / admin category label for home chip + matching.
  final String? categoryDisplayLabel;
  final String? creatorPublicId;
  final CreatorPosterPersonalization? personalizationConfig;
  final bool preferOriginalPosterQuality;
  final int viewCount;
  final int shareCount;
  final int downloadCount;
  final int displayViewCount;
  final int displayShareCount;
  final int displayDownloadCount;
  final int displayEngagementCount;

  bool get isVideo =>
      mediaType == 'video' && (videoUrl?.trim().isNotEmpty ?? false);

  int displayCountFor(String kind) {
    final real = switch (kind) {
      'view' => viewCount,
      'share' => shareCount,
      'download' => downloadCount,
      _ => 0,
    };
    final display = switch (kind) {
      'view' => displayViewCount,
      'share' => displayShareCount,
      'download' => displayDownloadCount,
      _ => 0,
    };
    if (display > 0) {
      return display;
    }
    final id = templateId?.trim().isNotEmpty == true
        ? templateId!.trim()
        : (imageUrl ?? imageStoragePath ?? titleEn);
    return _boostedPosterDisplayCount(id, kind, real);
  }

  int displayCombinedEngagementCount() {
    final id = templateId?.trim().isNotEmpty == true
        ? templateId!.trim()
        : (imageUrl ?? imageStoragePath ?? titleEn);
    return _boostedPosterDisplayEngagementCount(id, shareCount + downloadCount);
  }

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

int _stablePosterHash(String value) {
  var hash = 2166136261;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}

int _boostedPosterDisplayCount(String posterId, String kind, int realCount) {
  if (realCount <= 0) {
    if (kind == 'view') {
      return _defaultPosterDisplayViewCount(posterId);
    }
    if (kind == 'share') {
      return _defaultPosterDisplayShareCount(posterId);
    }
    return 0;
  }
  final baseCount = switch (kind) {
    'view' => _defaultPosterDisplayViewCount(posterId),
    'share' => _defaultPosterDisplayShareCount(posterId),
    'download' => 0,
    _ => 0,
  };
  final range = switch (kind) {
    'view' => (min: 25, max: 60),
    'share' => (min: 8, max: 20),
    'download' => (min: 10, max: 25),
    _ => (min: 1, max: 1),
  };
  final spread = range.max - range.min + 1;
  final multiplier =
      range.min + (_stablePosterHash('$kind:$posterId') % spread);
  return baseCount + (realCount * multiplier);
}

int _defaultPosterDisplayViewCount(String posterId) {
  return 120 + (_stablePosterHash('default-view:$posterId') % 121);
}

int _defaultPosterDisplayShareCount(String posterId) {
  final views = _defaultPosterDisplayViewCount(posterId);
  final percentage = 62 + (_stablePosterHash('default-share:$posterId') % 14);
  return math.min(views - 1, (views * percentage / 100).round());
}

int _boostedPosterDisplayEngagementCount(
  String posterId,
  int realEngagementCount,
) {
  final baseCount = _defaultPosterDisplayShareCount(posterId);
  if (realEngagementCount <= 0) {
    return baseCount;
  }
  final multiplier = 2 + (_stablePosterHash('engagement:$posterId') % 4);
  return baseCount + (realEngagementCount * multiplier);
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

class PosterExtraPhotoSelection {
  const PosterExtraPhotoSelection({
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

typedef _PosterExtraPhotoSelection = PosterExtraPhotoSelection;

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

enum _HomePromoCardType { featured, subscribe, renewalReminder, update, rate }

class _HomePromoSlide {
  const _HomePromoSlide({required this.imageUrl, required this.ctaTarget});

  final String imageUrl;
  final String ctaTarget;
}

class _HomeFeedPromoCardData {
  const _HomeFeedPromoCardData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.slides = const <_HomePromoSlide>[],
  });

  final _HomePromoCardType type;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final List<_HomePromoSlide> slides;
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
    required this.sessionSeed,
    required this.dynamicTags,
    required this.recentTemplateKeys,
  });

  final List<_TemplateItem> templates;
  final HomeFeedTimeSlot slot;
  final int year;
  final int month;
  final int day;
  final int sessionSeed;
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
    publishAtMillis: template.publishAtMillis,
    pageConfig: template.pageConfig,
    viewCount: template.viewCount,
    shareCount: template.shareCount,
    downloadCount: template.downloadCount,
    displayViewCount: template.displayViewCount,
    displayShareCount: template.displayShareCount,
    displayDownloadCount: template.displayDownloadCount,
    displayEngagementCount: template.displayEngagementCount,
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

List<_TemplateItem> _breakUpAdjacentCategoryRunsWorker(
  List<_TemplateItem> templates, {
  required int seed,
  int maxAdjacentFromSameCategory = 1,
}) {
  if (templates.length < 3 || maxAdjacentFromSameCategory < 1) {
    return templates;
  }
  final pending = List<_TemplateItem>.of(templates);
  final arranged = <_TemplateItem>[];
  String? lastKey;
  var adjacentCount = 0;

  while (pending.isNotEmpty) {
    var pickIndex = 0;
    if (lastKey != null && adjacentCount >= maxAdjacentFromSameCategory) {
      final alternateIndex = pending.indexWhere(
        (item) => _allCategoryGroupingKeyWorker(item) != lastKey,
      );
      if (alternateIndex > 0) {
        pickIndex = alternateIndex;
      }
    }

    final picked = pending.removeAt(pickIndex);
    final pickedKey = _allCategoryGroupingKeyWorker(picked);
    if (pickedKey == lastKey) {
      adjacentCount++;
    } else {
      lastKey = pickedKey;
      adjacentCount = 1;
    }
    arranged.add(picked);
  }

  if (arranged.length != templates.length) {
    return templates;
  }
  return arranged;
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
    final shuffledOnly = List<_TemplateItem>.of(templates, growable: false)
      ..sort(
        (a, b) => Object.hash(
          seed,
          _templateSequenceKeyWorker(a),
        ).compareTo(Object.hash(seed, _templateSequenceKeyWorker(b))),
      );
    return shuffledOnly;
  }
  for (final entry in grouped.entries) {
    entry.value.sort(
      (a, b) => Object.hash(
        seed,
        entry.key,
        _templateSequenceKeyWorker(a),
      ).compareTo(Object.hash(seed, entry.key, _templateSequenceKeyWorker(b))),
    );
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
    request.sessionSeed,
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
  static const String _dailyQuizCategorySlug = 'daily_quiz';
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

  static const int _dynamicMorePreviewDays = 7;
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
  final PoliticalPartyLogoService _politicalPartyLogoService =
      const PoliticalPartyLogoService();
  final PoliticalPartyService _politicalPartyService =
      const PoliticalPartyService();
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
  List<AppHomeBanner> _promoCardBanners = const <AppHomeBanner>[];
  List<AppHomeBanner> _fullscreenPopupBanners = const <AppHomeBanner>[];
  AppHomeBanner? _activeFullscreenPopupBanner;
  bool _fullscreenPopupDismissed = false;
  bool _fullscreenPopupDismissedThisSession = false;
  final Set<String> _countedFullscreenPopupBannerIds = <String>{};
  final Set<String> _countedHomeBannerIds = <String>{};
  final Set<String> _countedPosterViewIds = <String>{};
  int _fullscreenPopupBannerGeneration = 0;
  QueryDocumentSnapshot<Map<String, dynamic>>? _templatesLastDocument;
  Future<void>? _homeBannersLoadFuture;
  Future<void>? _approvedTemplatesLoadFuture;
  Future<void>? _manualEventCategoriesLoadFuture;
  Future<void>? _permanentCategoriesLoadFuture;
  Future<void>? _politicalPartyLogosLoadFuture;
  Future<void>? _politicalPartiesLoadFuture;
  StreamSubscription<Map<String, String>>? _politicalPartyLogoSubscription;
  StreamSubscription<List<PoliticalParty>>? _politicalPartySubscription;
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
  Map<String, String> _partyLogoOverridesByPartyId = const <String, String>{};
  List<PoliticalParty> _politicalParties = politicalParties;
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
  bool _currentSlotAllFeedHydrationInFlight = false;
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
  final Set<String> _currentSlotAllFeedHydrationAttempts = <String>{};
  StreamSubscription<User?>? _authStateSubscription;
  String _lastHomeAuthUid = '';
  Timer? _homeAuthReadyRetryTimer;
  Timer? _startupSnapshotPersistTimer;
  Timer? _allFeedInterestSaveTimer;
  Map<String, double> _allFeedInterestScores = <String, double>{};
  int _allFeedPersonalizationRevision = 0;
  late final int _allFeedSessionSeed = Object.hash(
    DateTime.now().microsecondsSinceEpoch,
    math.Random().nextInt(0x7fffffff),
  );

  // ignore: unused_field
  static const List<_TemplateItem> _freeTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe:
          'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¶ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â­ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚Â',
      titleHi:
          'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¡ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â®ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â°',
      titleEn: 'Good Morning Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200',
      categoryTags: <String>['good_morning'],
    ),
    _TemplateItem(
      titleTe:
          'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¤ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚Â',
      titleHi:
          'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¥ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â°',
      titleEn: 'Birthday Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?w=1200',
      categoryTags: <String>['birthdays'],
    ),
    _TemplateItem(
      titleTe:
          'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â­ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¤ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¿ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚Â',
      titleHi:
          'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â­ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¤ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¿ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚ÂªÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â¤Ãƒâ€šÃ‚Â°',
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
    unawaited(AppFlowService.recordZeroCostDailyHeartbeat());
    _posterScrollController.addListener(_onPosterScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedCategorySlug == _dailyQuizCategorySlug) {
        setState(() => _selectedCategorySlug = _allCategorySlug);
        unawaited(_openDailyQuiz());
      }
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
        const Duration(milliseconds: 1650),
        _loadPoliticalParties,
      );
      _politicalPartySubscription ??= _politicalPartyService
          .watchParties()
          .listen(_applyPoliticalParties, onError: (_) {});
      _scheduleDeferredHomeStartupTask(
        const Duration(milliseconds: 1800),
        _loadPoliticalPartyLogos,
      );
      _politicalPartyLogoSubscription ??= _politicalPartyLogoService
          .watchLogoUrlsByPartyId()
          .listen(_applyPoliticalPartyLogos, onError: (_) {});
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

  Future<void> _loadPoliticalParties() async {
    final existing = _politicalPartiesLoadFuture;
    if (existing != null) {
      return existing;
    }
    final future = _loadPoliticalPartiesInternal();
    _politicalPartiesLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_politicalPartiesLoadFuture, future)) {
        _politicalPartiesLoadFuture = null;
      }
    }
  }

  Future<void> _loadPoliticalPartiesInternal() async {
    final parties = await _politicalPartyService.fetchParties();
    _applyPoliticalParties(parties);
  }

  void _applyPoliticalParties(List<PoliticalParty> parties) {
    if (!mounted) {
      return;
    }
    final currentSignature = _politicalPartySignature(_politicalParties);
    final nextSignature = _politicalPartySignature(parties);
    if (currentSignature == nextSignature) {
      return;
    }
    setState(() {
      _politicalParties = parties;
      _categoryListCache = null;
      _categoryListIdentity = null;
    });
  }

  String _politicalPartySignature(List<PoliticalParty> parties) {
    return parties
        .map(
          (party) =>
              '${party.id}:${party.name}:${party.shortName}:${party.regionIds.join(",")}:${party.logoAssetPath ?? ""}:${party.localizedNamesSignature}',
        )
        .join('|');
  }

  Future<void> _loadPoliticalPartyLogos() async {
    final existing = _politicalPartyLogosLoadFuture;
    if (existing != null) {
      return existing;
    }
    final future = _loadPoliticalPartyLogosInternal();
    _politicalPartyLogosLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_politicalPartyLogosLoadFuture, future)) {
        _politicalPartyLogosLoadFuture = null;
      }
    }
  }

  Future<void> _loadPoliticalPartyLogosInternal() async {
    final logos = await _politicalPartyLogoService.fetchLogoUrlsByPartyId();
    _applyPoliticalPartyLogos(logos);
  }

  void _applyPoliticalPartyLogos(Map<String, String> logos) {
    if (!mounted || mapEquals(_partyLogoOverridesByPartyId, logos)) {
      return;
    }
    setState(() {
      _partyLogoOverridesByPartyId = logos;
      _categoryListCache = null;
      _categoryListIdentity = null;
    });
  }

  String? _partyLogoPathFor(PoliticalParty party) {
    final overrideUrl = _partyLogoOverridesByPartyId[party.id]?.trim() ?? '';
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    return party.logoAssetPath;
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
      return _balancedHomeFeedOrder(source, reason: 'base');
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
      return _balancedHomeFeedOrder(source, reason: 'no_personalization');
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
    final spread = _spreadAllCategoryTemplateGroupsWorker(
      personalized,
      seed: Object.hash(
        now.year,
        now.month,
        now.day,
        _activeHomeFeedTimeSlot.name,
        'personalized',
        _allFeedSessionSeed,
      ),
    );
    return _balancedHomeFeedOrder(spread, reason: 'personalized');
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

  void _recordPosterViewCount(_TemplateItem item) {
    final posterId = item.templateId?.trim();
    if (posterId == null || posterId.isEmpty) {
      return;
    }
    if (!_countedPosterViewIds.add(posterId)) {
      return;
    }
    unawaited(
      _approvedCreatorTemplateService.incrementPosterViewCount(
        posterId: posterId,
        creatorPublicId: item.creatorPublicId ?? '',
        posterTitle: item.titleEn,
        categoryId: item.primaryFirestoreCategoryId ?? '',
        categoryLabel: item.categoryDisplayLabel ?? '',
      ),
    );
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
      _homeAuthReadyRetryTimer ??= Timer(const Duration(seconds: 75), () {
        _homeAuthReadyRetryTimer = null;
        if (!mounted) {
          return;
        }
        unawaited(() async {
          await FirebaseBootstrap.ensureInitialized();
          if (mounted) {
            _attachHomeAuthStateSubscriptionIfReady();
          }
        }());
      });
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
    _politicalPartySubscription?.cancel();
    _politicalPartyLogoSubscription?.cancel();
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
        _fullscreenPopupBanners = const <AppHomeBanner>[];
        _activeFullscreenPopupBanner = null;
        _fullscreenPopupDismissed = false;
        _fullscreenPopupDismissedThisSession = false;
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

  bool _isCategoryHiddenForReligion(String slug) {
    return _isCategoryHiddenForReligionPreference(slug, _religionPreference);
  }

  bool _isCategoryHiddenForReligionPreference(
    String slug,
    AppReligionPreference preference,
  ) {
    final normalized = _normalizeTag(slug);
    if (normalized.isEmpty || normalized == _allCategorySlug) {
      return _rawCategoryValueMatchesHiddenReligion(
        slug,
        _hiddenCategoryTagsForReligionPreference(preference),
      );
    }
    final hiddenTags = _hiddenCategoryTagsForReligionPreference(preference);
    return hiddenTags.contains(normalized) ||
        _rawCategoryValueMatchesHiddenReligion(slug, hiddenTags);
  }

  Set<String> _hiddenCategoryTagsForReligion() {
    return _hiddenCategoryTagsForReligionPreference(_religionPreference);
  }

  Set<String> _hiddenCategoryTagsForReligionPreference(
    AppReligionPreference preference,
  ) {
    final tags = <String>{};
    for (final slug in AppReligionService.hiddenCategorySlugsFor(preference)) {
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
    final rawCategoryValues = <String>[
      primaryFirestore,
      item.categoryDisplayLabel ?? '',
      ...item.categoryTags,
    ];
    if (rawCategoryValues.any(
      (value) => _rawCategoryValueMatchesHiddenReligion(value, hiddenTags),
    )) {
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

  bool _rawCategoryValueMatchesHiddenReligion(
    String rawValue,
    Set<String> hiddenTags,
  ) {
    final text = rawValue.trim().toLowerCase();
    if (text.isEmpty) {
      return false;
    }
    final collapsed = text.replaceAll(RegExp(r'[\s_\-]+'), '');

    bool containsAny(Iterable<String> values) {
      return values.any((value) => collapsed.contains(value));
    }

    const mahabharataTags = <String>{
      'mahabharata',
      'mahabharatam',
      'mahabharatham',
      'maha_bharatam',
      'maha_bharatham',
    };
    if (hiddenTags.intersection(mahabharataTags).isNotEmpty &&
        containsAny(const <String>[
          'mahabharata',
          'mahabharatam',
          'mahabharatham',
          'ÃƒÂ Ã‚Â°Ã‚Â®ÃƒÂ Ã‚Â°Ã‚Â¹ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â­ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â°Ã‚Â¤',
          'ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â­ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¤',
          'ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã‚Â°ÃƒÂ Ã‚Â®Ã‚Â¤',
          'ÃƒÂ Ã‚Â²Ã‚Â®ÃƒÂ Ã‚Â²Ã‚Â¹ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â­ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¤',
          'ÃƒÂ Ã‚Â´Ã‚Â®ÃƒÂ Ã‚Â´Ã‚Â¹ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â­ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â°ÃƒÂ Ã‚Â´Ã‚Â¤',
          'ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¤',
          'ÃƒÂ Ã‚ÂªÃ‚Â®ÃƒÂ Ã‚ÂªÃ‚Â¹ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ‚Â­ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚ÂªÃ‚Â¤',
          'ÃƒÂ Ã‚Â¨Ã‚Â®ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã‚Â­ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â¨Ã‚Â¤',
          'ÃƒÂ Ã‚Â¬Ã‚Â®ÃƒÂ Ã‚Â¬Ã‚Â¹ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â­ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â¬Ã‚Â¤',
        ])) {
      return true;
    }

    if (hiddenTags.contains('devotional') &&
        containsAny(const <String>[
          'devotional',
          'bhakti',
          'ÃƒÂ Ã‚Â°Ã‚Â­ÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â¤ÃƒÂ Ã‚Â°Ã‚Â¿',
          'ÃƒÂ Ã‚Â¤Ã‚Â­ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¿',
          'ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¿',
          'ÃƒÂ Ã‚Â²Ã‚Â­ÃƒÂ Ã‚Â²Ã¢â‚¬Â¢ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¤ÃƒÂ Ã‚Â²Ã‚Â¿',
          'ÃƒÂ Ã‚Â´Ã‚Â­ÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â¤ÃƒÂ Ã‚Â´Ã‚Â¿',
          'ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¿',
          'ÃƒÂ Ã‚ÂªÃ‚Â­ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â¤ÃƒÂ Ã‚ÂªÃ‚Â¿',
          'ÃƒÂ Ã‚Â¨Ã‚Â­ÃƒÂ Ã‚Â¨Ã¢â‚¬â€ÃƒÂ Ã‚Â¨Ã‚Â¤ÃƒÂ Ã‚Â©Ã¢â€šÂ¬',
          'ÃƒÂ Ã‚Â¬Ã‚Â­ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â¤ÃƒÂ Ã‚Â¬Ã‚Â¿',
        ])) {
      return true;
    }

    return false;
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
      return _matchesAllCategoryTimeWindow(item);
    }

    if (selectedCategory.slug == _politicalCategorySlug) {
      return !_isJokesTemplate(item);
    }

    if (_normalizeTag(selectedCategory.slug).startsWith('party_')) {
      return _matchesPoliticalPartyFeedAllowedCategory(item, language);
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

  bool _matchesPoliticalPartyFeedAllowedCategory(
    _TemplateItem item,
    AppLanguage language,
  ) {
    if (_isJokesTemplate(item)) {
      return false;
    }

    final normalizedPrimary = _normalizeTag(
      item.primaryFirestoreCategoryId?.trim() ?? '',
    );
    if (normalizedPrimary.startsWith('party_')) {
      return true;
    }

    final now = IstTimeService.now();
    final allowedEventSignals = <String>{};

    allowedEventSignals.add('today_special');

    void addDynamicCategorySignals(DynamicCategory category) {
      final chip = _CategoryChipData(
        slug: category.slug,
        label: category.label,
        matchTags: category.tags,
        presenceTags: _dynamicPresenceTags(category).toList(growable: false),
        isDynamic: true,
      );
      allowedEventSignals.addAll(_strictDynamicCategorySignals(chip));
    }

    for (final category in _dynamicPreviewCategoryService.categoriesForDate(
      now,
      language: language,
      selectedRegionId: _selectedRegionId,
    )) {
      if (category.type == DynamicCategoryType.weekdaySpecial) {
        continue;
      }
      addDynamicCategorySignals(category);
    }
    if (_isBonaluSharedVisibleForPoliticalFeed(now)) {
      const bonaluCategory = DynamicCategory(
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
      addDynamicCategorySignals(bonaluCategory);
    }
    for (final category in _manualEventCategories.where(
      (item) => item.allowPoliticalProtocol,
    )) {
      addDynamicCategorySignals(category);
    }
    for (final category in _permanentCategories.where(
      (item) => item.allowPoliticalProtocol,
    )) {
      addDynamicCategorySignals(category);
    }

    if (allowedEventSignals.isEmpty) {
      return false;
    }
    return _templateCategorySignalsForMatching(
      item,
    ).intersection(allowedEventSignals).isNotEmpty;
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

  List<String> _activePoliticalPartyFeedCategoryIds(AppLanguage language) {
    final now = IstTimeService.now();
    final categoryIds = <String>{};

    void addCategoryId(String raw) {
      final normalized = _normalizeTag(raw);
      if (normalized.isNotEmpty) {
        categoryIds.add(normalized);
      }
    }

    addCategoryId('today_special');

    for (final category in _dynamicPreviewCategoryService.categoriesForDate(
      now,
      language: language,
      selectedRegionId: _selectedRegionId,
    )) {
      if (category.type == DynamicCategoryType.weekdaySpecial) {
        continue;
      }
      addCategoryId(category.slug);
    }

    if (_isBonaluSharedVisibleForPoliticalFeed(now)) {
      addCategoryId('bonalu');
    }

    for (final category in _manualEventCategories.where(
      (item) => item.allowPoliticalProtocol,
    )) {
      addCategoryId(category.slug);
    }

    for (final category in _permanentCategories.where(
      (item) => item.allowPoliticalProtocol,
    )) {
      addCategoryId(category.slug);
    }

    return categoryIds.toList(growable: false)..sort();
  }

  bool _isBonaluSharedVisibleForPoliticalFeed(DateTime now) {
    if (!_isTeluguSharedRegion(_selectedRegionId)) {
      return false;
    }
    final resolved = resolvedLunarEventDatesForYear(now.year)['bonalu'];
    if (resolved == null) {
      return false;
    }
    final today = DateTime(now.year, now.month, now.day);
    final eventStart = DateTime(now.year, resolved.month, resolved.day);
    final visibleStart = eventStart.subtract(
      const Duration(days: _dynamicMorePreviewDays),
    );
    final eventEnd = switch ((resolved.endMonth, resolved.endDay)) {
      (final int endMonth, final int endDay) => DateTime(
        now.year,
        endMonth,
        endDay,
      ),
      _ => eventStart.add(Duration(days: resolved.durationDays - 1)),
    };
    return !today.isBefore(visibleStart) && !today.isAfter(eventEnd);
  }

  Future<List<ApprovedCreatorTemplate>> _fetchPoliticalPartyFeedTemplates({
    required String categorySlug,
    required int scanLimit,
    required Source source,
  }) async {
    final normalizedSlug = _normalizeTag(categorySlug);
    if (!normalizedSlug.startsWith('party_')) {
      return const <ApprovedCreatorTemplate>[];
    }
    final categoryIds = <String>{
      normalizedSlug,
      ..._activePoliticalPartyFeedCategoryIds(context.currentLanguage),
    }.where((item) => item.trim().isNotEmpty).toList(growable: false);

    final fetchedLists = await Future.wait(
      categoryIds.map(
        (categoryId) => _approvedCreatorTemplateService
            .fetchAllApprovedTemplatesForCategory(
              categoryId: categoryId,
              source: source,
              scanLimit: scanLimit,
            ),
      ),
    );

    final byId = <String, ApprovedCreatorTemplate>{};
    for (final templates in fetchedLists) {
      for (final template in templates) {
        byId[template.id] = template;
      }
    }
    final merged = byId.values.toList(growable: false)
      ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return merged.length <= scanLimit
        ? merged
        : merged.take(scanLimit).toList(growable: false);
  }

  bool _matchesAllCategoryTimeWindow(_TemplateItem item) {
    final itemTemporalTags = _templateTemporalSignals(item);
    if (itemTemporalTags.isEmpty) {
      return true;
    }
    final allowedForSlot = itemTemporalTags.intersection(
      _allowedAllFeedTemporalSignals(_activeHomeFeedTimeSlot),
    );
    if (allowedForSlot.isEmpty) {
      return false;
    }
    if (itemTemporalTags.contains('good_night') ||
        itemTemporalTags.contains('night')) {
      return _isInGoodNightAllFeedWindow(item);
    }
    return true;
  }

  bool _isInGoodNightAllFeedWindow(_TemplateItem item) {
    final visibleFromMillis = item.publishAtMillis > 0
        ? item.publishAtMillis
        : item.createdAtMillis;
    if (visibleFromMillis <= 0) {
      return true;
    }
    final visibleFromIst = IstTimeService.toIst(
      DateTime.fromMillisecondsSinceEpoch(visibleFromMillis),
    );
    final windowStartMillis = DateTime.utc(
      visibleFromIst.year,
      visibleFromIst.month,
      visibleFromIst.day + 1,
      20,
    ).subtract(IstTimeService.offset).millisecondsSinceEpoch;
    final windowEndMillis = DateTime.utc(
      visibleFromIst.year,
      visibleFromIst.month,
      visibleFromIst.day + 2,
      4,
    ).subtract(IstTimeService.offset).millisecondsSinceEpoch;
    final nowMillis = IstTimeService.nowEpochMillis();
    return nowMillis >= windowStartMillis && nowMillis < windowEndMillis;
  }

  Set<String> _templateTemporalSignals(_TemplateItem item) {
    final signals = <String>{};
    final rawTags = <String>[
      item.primaryFirestoreCategoryId ?? '',
      item.categoryDisplayLabel ?? '',
      ...item.categoryTags,
    ];
    for (final tag in rawTags) {
      final normalized = _normalizeTag(tag);
      if (normalized.isEmpty) {
        continue;
      }
      signals.addAll(
        _expandCategoryAliases(normalized).where(_isTimeGreetingSignal),
      );
    }
    return signals;
  }

  bool _isTimeGreetingSignal(String tag) {
    return tag == 'good_morning' ||
        tag == 'morning' ||
        tag == 'good_afternoon' ||
        tag == 'afternoon' ||
        tag == 'good_evening' ||
        tag == 'evening' ||
        tag == 'good_night' ||
        tag == 'night';
  }

  Set<String> _allowedAllFeedTemporalSignals(HomeFeedTimeSlot slot) {
    return switch (slot) {
      HomeFeedTimeSlot.morning => const <String>{'good_morning', 'morning'},
      HomeFeedTimeSlot.afternoon => const <String>{
        'good_afternoon',
        'afternoon',
      },
      HomeFeedTimeSlot.evening => const <String>{'good_evening', 'evening'},
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
    _currentSlotAllFeedHydrationAttempts.clear();
    _currentSlotAllFeedHydrationInFlight = false;
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
        return locked;
      }
    }
    if (_allFeedRankingReady && _rankedAllFeedTemplates != null) {
      return _applyAllFeedPersonalization(_rankedAllFeedTemplates!);
    }
    return _applyAllFeedPersonalization(
      _balancedHomeFeedOrder(
        _remoteApprovedTemplates,
        reason: 'all_feed_unranked_startup',
      ),
    );
  }

  List<_TemplateItem> _rankVisibleAllFeedTemplates(
    List<_TemplateItem> source, {
    required AppLanguage language,
  }) {
    if (source.length < 2) {
      return source;
    }
    final now = IstTimeService.now();
    return _rankAllFeedTemplatesWorker(
      _AllFeedRankingWorkerRequest(
        templates: source,
        slot: _activeHomeFeedTimeSlot,
        year: now.year,
        month: now.month,
        day: now.day,
        sessionSeed: _allFeedSessionSeed,
        dynamicTags: _activeDynamicAllFeedTags(language),
        recentTemplateKeys: _recentAllFeedTemplateKeys,
      ),
    );
  }

  void _ensureCurrentSlotAllFeedTemplatesLoaded({
    required AppLanguage language,
    required List<_TemplateItem> visibleTemplates,
  }) {
    if (_selectedCategorySlug != _allCategorySlug ||
        _currentSlotAllFeedHydrationInFlight) {
      return;
    }
    final now = IstTimeService.now();
    final orderedTags = TimeSlotService.prioritizedCategoryTagsForHomeFeed(
      now,
    ).map(_normalizeTag).where((tag) => tag.isNotEmpty).toList(growable: false);
    if (orderedTags.isEmpty) {
      return;
    }
    final primaryTag = orderedTags.first;
    final currentSlotAlreadyVisible = visibleTemplates.any(
      (item) =>
          _matchesPriorityTagWorker(item, <String>{primaryTag}) &&
          _matchesAllCategoryTimeWindow(item),
    );
    if (currentSlotAlreadyVisible) {
      return;
    }
    final attemptKey =
        '${now.year}-${now.month}-${now.day}:${_activeHomeFeedTimeSlot.name}:$primaryTag';
    if (!_currentSlotAllFeedHydrationAttempts.add(attemptKey)) {
      return;
    }
    _currentSlotAllFeedHydrationInFlight = true;
    unawaited(() async {
      try {
        final templates = await _approvedCreatorTemplateService
            .fetchAllApprovedTemplatesForCategory(
              categoryId: primaryTag,
              source: Source.server,
              scanLimit: _initialPriorityPrimaryFetchSize * 4,
            );
        if (!mounted || templates.isEmpty) {
          return;
        }
        final mapped = await _mapTemplatesOffMain(
          templates,
          phase: 'current_slot_all_feed',
        );
        if (!mounted || mapped.isEmpty) {
          return;
        }
        final visible = await _ensureAllCategoryStartupVisibleTemplates(
          mapped,
          language: language,
          phase: 'current_slot_all_feed',
        );
        if (!mounted || visible.isEmpty) {
          return;
        }
        await _appendTemplatesIncrementally(
          visible,
          hasMore: _templatesHasMore,
          lastDocument: _templatesLastDocument,
          phase: 'current_slot_all_feed',
        );
      } catch (error, stackTrace) {
        _homeDebugLogStack(
          'current slot all feed hydration failed: $error',
          stackTrace,
        );
      } finally {
        _currentSlotAllFeedHydrationInFlight = false;
      }
    }());
  }

  List<_TemplateItem> _balancedHomeFeedOrder(
    List<_TemplateItem> source, {
    required String reason,
  }) {
    if (source.length < 3) {
      return source;
    }
    final now = IstTimeService.now();
    final seed = Object.hash(
      now.year,
      now.month,
      now.day,
      _activeHomeFeedTimeSlot.name,
      reason,
      _allFeedSessionSeed,
      source.length,
    );
    final spread = _spreadAllCategoryTemplateGroupsWorker(source, seed: seed);
    return _breakUpAdjacentCategoryRunsWorker(spread, seed: seed);
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
    // local calendar JSON ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â add chips from loaded templates so filters match.
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
    final exactSlug = normalizedSelectionSlug.isNotEmpty
        ? normalizedSelectionSlug
        : normalizedSlug;
    if (exactSlug.isEmpty) {
      return const <String>{};
    }
    return <String>{exactSlug, if (normalizedSlug.isNotEmpty) normalizedSlug};
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
    final normalized = _normalizeTag(slug);
    for (final perm in _permanentCategories) {
      if (_normalizeTag(perm.slug) == normalized ||
          _normalizeTag(perm.id) == normalized) {
        if (perm.labelsByLanguage.isNotEmpty) {
          final translated = perm.labelFor(language);
          if (translated.isNotEmpty) {
            return translated;
          }
        }
      }
    }
    for (final manual in _manualEventCategories) {
      if (_normalizeTag(manual.slug) == normalized ||
          _normalizeTag(manual.id) == normalized) {
        if (manual.labelsByLanguage.isNotEmpty) {
          final translated = manual.labelFor(language);
          if (translated.isNotEmpty) {
            return translated;
          }
        }
      }
    }
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
    if (category.labelsByLanguage.isNotEmpty) {
      final translated = category.labelFor(language);
      if (translated.isNotEmpty) {
        return translated;
      }
    }
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
        'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â·ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚ÂµÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¾ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¤ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¿',
      'gurram_jashuva_vardhanthi' =>
        'ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â·ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚ÂµÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¾ ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚ÂµÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â°ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â±Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â§ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¤ÃƒÆ’Ã‚Â Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â¿',
      _ => null,
    };
  }

  List<_CategoryChipData> _morePopupCategories({
    bool scheduleAvailabilityChecks = true,
  }) {
    final bySlug = <String, _CategoryChipData>{};

    void addCategory(_CategoryChipData category) {
      final slug = _normalizeTag(category.slug);
      if (slug.isEmpty ||
          slug == _moreCategorySlug ||
          _isCategoryHiddenForReligion(category.effectiveSelectionSlug) ||
          _rawCategoryValueMatchesHiddenReligion(
            category.label,
            _hiddenCategoryTagsForReligion(),
          )) {
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
    return _filterCategoriesByReligion(bySlug.values.toList(growable: false));
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
      label: category.labelsByLanguage.isNotEmpty
          ? category.labelFor(context.currentLanguage)
          : ScriptLocalizationService.localizeCategoryLabel(
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
    final knownParties = _politicalParties
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
          iconAssetPath: _partyLogoPathFor(party),
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
    for (final party in _politicalParties) {
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
      _dailyQuizCategoryChip(),
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
    addChip(_dailyQuizCategoryChip());
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
        telugu: 'అన్నీ',
        english: 'All',
        hindi: 'सभी',
        tamil: 'அனைத்தும்',
        kannada: 'ಎಲ್ಲವೂ',
        malayalam: 'എല്ലാം',
        marathi: 'सर्व',
        gujarati: 'બધા',
        bengali: 'সব',
        punjabi: 'ਸਾਰੇ',
        odia: 'ସମସ୍ତ',
        assamese: 'সকলো',
        konkani: 'सगळें',
        nepali: 'सबै',
        meitei: 'পুম্নমক',
        mizo: 'A vaiin',
        kashmiri: 'سٲری',
        ladakhi: 'ཚང་མ།',
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

  _CategoryChipData _dailyQuizCategoryChip() {
    return _CategoryChipData(
      slug: _dailyQuizCategorySlug,
      label: localizedDailyQuizTitle(context.strings),
      matchTags: const <String>['daily_quiz', 'quiz'],
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
      'mahabharata' => const <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
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
      'mahabharata': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'mahabharatam': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'mahabharatham': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'maha_bharatam': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
      'maha_bharatham': <String>[
        'mahabharata',
        'mahabharatam',
        'mahabharatham',
        'maha_bharatam',
        'maha_bharatham',
      ],
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

  Future<void> _openProfile() async {
    final updatedProfile = await Navigator.of(context).push<PosterProfileData>(
      MaterialPageRoute<PosterProfileData>(
        builder: (_) => const ProfileScreen(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (updatedProfile != null && updatedProfile != _viewerPosterProfile) {
      setState(() {
        _viewerPosterProfile = updatedProfile;
      });
    }
    await _loadViewerPosterProfile();
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
    final remotePromoFuture = _appHomeBannerService.fetchBanners(
      maxItems: 6,
      placement: 'home_promo_card_carousel',
    );
    final remotePopupFuture = _appHomeBannerService.fetchBanners(
      maxItems: 12,
      placement: 'home_fullscreen_popup',
    );
    final cached = await _appHomeBannerService.fetchBannersFromCache();
    final cachedPromo = await _appHomeBannerService.fetchBannersFromCache(
      maxItems: 6,
      placement: 'home_promo_card_carousel',
    );
    final cachedPopup = await _appHomeBannerService.fetchBannersFromCache(
      maxItems: 12,
      placement: 'home_fullscreen_popup',
    );
    if (mounted && cached.isNotEmpty) {
      if (!_sameHomeBannerSequence(_homeBanners, cached)) {
        setState(() => _homeBanners = cached);
      }
    }
    if (mounted && cachedPromo.isNotEmpty) {
      if (!_sameHomeBannerSequence(_promoCardBanners, cachedPromo)) {
        setState(() => _promoCardBanners = cachedPromo);
      }
    }
    if (mounted && cachedPopup.isNotEmpty) {
      if (!_sameHomeBannerSequence(_fullscreenPopupBanners, cachedPopup)) {
        _applyFullscreenPopupBanners(cachedPopup);
      }
    }

    final remote = await remoteFuture;
    final remotePromo = await remotePromoFuture;
    final remotePopup = await remotePopupFuture;
    if (!mounted) {
      return;
    }
    final homeChanged = !_sameHomeBannerSequence(_homeBanners, remote);
    final promoChanged = !_sameHomeBannerSequence(
      _promoCardBanners,
      remotePromo,
    );
    final popupChanged = !_sameHomeBannerSequence(
      _fullscreenPopupBanners,
      remotePopup,
    );
    if (!homeChanged && !promoChanged && !popupChanged) {
      return;
    }
    setState(() {
      if (homeChanged) {
        _homeBanners = remote;
      }
      if (promoChanged) {
        _promoCardBanners = remotePromo;
      }
    });
    if (popupChanged) {
      unawaited(_applyFullscreenPopupBanners(remotePopup));
    }
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
      'stripLayoutStyle': config.stripLayoutStyle,
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
      stripLayoutStyle: _normalizePosterStripLayoutStyle(
        data['stripLayoutStyle'] as String?,
      ),
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
      'publishAtMillis': item.publishAtMillis,
      'primaryFirestoreCategoryId': item.primaryFirestoreCategoryId,
      'categoryDisplayLabel': item.categoryDisplayLabel,
      'creatorPublicId': item.creatorPublicId,
      'pageConfig': _serializePageConfig(item.pageConfig),
      'viewCount': item.viewCount,
      'shareCount': item.shareCount,
      'downloadCount': item.downloadCount,
      'displayViewCount': item.displayViewCount,
      'displayShareCount': item.displayShareCount,
      'displayDownloadCount': item.displayDownloadCount,
      'displayEngagementCount': item.displayEngagementCount,
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
      publishAtMillis: (data['publishAtMillis'] as num?)?.toInt() ?? 0,
      primaryFirestoreCategoryId:
          (data['primaryFirestoreCategoryId'] as String?)?.trim(),
      categoryDisplayLabel: (data['categoryDisplayLabel'] as String?)?.trim(),
      creatorPublicId: (data['creatorPublicId'] as String?)?.trim(),
      pageConfig: pageConfig,
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      downloadCount: (data['downloadCount'] as num?)?.toInt() ?? 0,
      displayViewCount: (data['displayViewCount'] as num?)?.toInt() ?? 0,
      displayShareCount: (data['displayShareCount'] as num?)?.toInt() ?? 0,
      displayDownloadCount:
          (data['displayDownloadCount'] as num?)?.toInt() ?? 0,
      displayEngagementCount:
          (data['displayEngagementCount'] as num?)?.toInt() ?? 0,
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
        .take(1)
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
        await Future<void>.delayed(const Duration(seconds: 7));
        if (!mounted) {
          return;
        }
        for (final url in urls) {
          if (!mounted) {
            return;
          }
          try {
            final provider = ResizeImage.resizeIfNeeded(
              720,
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
            ).timeout(const Duration(milliseconds: 650));
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

  Future<List<_TemplateItem>> _ensureAllCategoryStartupVisibleTemplates(
    List<_TemplateItem> items, {
    required AppLanguage language,
    required String phase,
  }) async {
    if (_selectedCategorySlug != _allCategorySlug ||
        items.any(
          (item) => _matchesTemplate(item, language, _allCategoryChip()),
        )) {
      return items;
    }
    final windowTemplates = await _approvedCreatorTemplateService
        .fetchApprovedTemplatesWindow(
          scanLimit: math.max(_allTemplatesWindowPageSize * 3, 72),
          source: Source.server,
        );
    if (!mounted || windowTemplates.isEmpty) {
      return items;
    }
    final windowItems = await _mapTemplatesOffMain(
      windowTemplates,
      phase: '${phase}_all_window',
    );
    if (!mounted || windowItems.isEmpty) {
      return items;
    }
    final merged = await _mergeTemplateListsOffMain(<List<_TemplateItem>>[
      items,
      windowItems,
    ], phase: '${phase}_all_window_merge');
    return merged;
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
    final startupLanguage = context.currentLanguage;
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
        var mapped = await _mapTemplatesOffMain(
          page.templates,
          phase: 'refresh',
        );
        mapped = await _ensureAllCategoryStartupVisibleTemplates(
          mapped,
          language: startupLanguage,
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
                .fetchApprovedTemplatesPage(pageSize: initialPageSize)
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
        var firstPaintItems = await _ensureAllCategoryStartupVisibleTemplates(
          prioritizedPrimaryItems,
          language: startupLanguage,
          phase: 'primary',
        );
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
          if (firstPaintItems.isNotEmpty) {
            await _appendTemplatesIncrementally(
              firstPaintItems,
              hasMore: firstPaintHasMore,
              lastDocument: firstPaintLastDocument,
              phase: 'primary_immediate_merge',
            );
            if (!mounted) {
              return;
            }
          }
          unawaited(
            _completeStartupSecondaryHydration(
              deferredPrimaryItems: const <_TemplateItem>[],
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
      mapped = await _ensureAllCategoryStartupVisibleTemplates(
        mapped,
        language: startupLanguage,
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
        mapped = await _ensureAllCategoryStartupVisibleTemplates(
          mapped,
          language: startupLanguage,
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
                sessionSeed: _allFeedSessionSeed,
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
      final sameTargetReligions =
          a.targetReligions.length == b.targetReligions.length &&
          a.targetReligions.every(b.targetReligions.contains);
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
          !sameTargetReligions ||
          a.targetState != b.targetState ||
          a.targetDistrict != b.targetDistrict ||
          a.targetCity != b.targetCity) {
        return false;
      }
    }
    return true;
  }

  Future<void> _applyFullscreenPopupBanners(List<AppHomeBanner> banners) async {
    if (!mounted) {
      return;
    }
    final generation = ++_fullscreenPopupBannerGeneration;
    final currentBannerId = _activeFullscreenPopupBanner?.id;
    final selectedBanner = currentBannerId == null
        ? await _selectNextFullscreenPopupBanner(banners)
        : _findBannerById(banners, currentBannerId) ??
              await _selectNextFullscreenPopupBanner(banners);
    if (!mounted || generation != _fullscreenPopupBannerGeneration) {
      return;
    }
    setState(() => _setFullscreenPopupBanners(banners, selectedBanner));
  }

  void _setFullscreenPopupBanners(
    List<AppHomeBanner> banners,
    AppHomeBanner? selectedBanner,
  ) {
    final previousId = _activeFullscreenPopupBanner?.id;
    _fullscreenPopupBanners = banners;
    _activeFullscreenPopupBanner = selectedBanner;
    if (_activeFullscreenPopupBanner?.id != previousId) {
      _fullscreenPopupDismissed = _fullscreenPopupDismissedThisSession;
    }
  }

  Future<AppHomeBanner?> _selectNextFullscreenPopupBanner(
    List<AppHomeBanner> banners,
  ) async {
    if (banners.isEmpty) {
      return null;
    }
    if (banners.length == 1) {
      return banners.first;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      const indexKey = 'home_fullscreen_popup_next_index_v1';
      const idsKey = 'home_fullscreen_popup_banner_ids_v1';
      final currentIds = banners.map((banner) => banner.id).toList();
      final previousIds = prefs.getStringList(idsKey) ?? const <String>[];
      final rawIndex =
          previousIds.length == currentIds.length &&
              _sameStringSequence(previousIds, currentIds)
          ? prefs.getInt(indexKey) ?? 0
          : 0;
      final selectedIndex = rawIndex.clamp(0, banners.length - 1).toInt();
      final nextIndex = (selectedIndex + 1) % banners.length;
      await prefs.setStringList(idsKey, currentIds);
      await prefs.setInt(indexKey, nextIndex);
      return banners[selectedIndex];
    } catch (error, stackTrace) {
      _homeDebugLogStack(
        'fullscreen popup banner rotation skipped: $error',
        stackTrace,
      );
      return banners.first;
    }
  }

  AppHomeBanner? _findBannerById(List<AppHomeBanner> banners, String id) {
    for (final banner in banners) {
      if (banner.id == id) {
        return banner;
      }
    }
    return null;
  }

  bool _sameStringSequence(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  void _dismissFullscreenPopupBanner() {
    if (_fullscreenPopupDismissed) {
      return;
    }
    setState(() {
      _fullscreenPopupDismissed = true;
      _fullscreenPopupDismissedThisSession = true;
    });
  }

  void _recordFullscreenPopupBannerView(String bannerId) {
    if (bannerId.trim().isEmpty ||
        !_countedFullscreenPopupBannerIds.add(bannerId)) {
      return;
    }
    _recordAppBannerView(
      bannerId: bannerId,
      debugLabel: 'fullscreen popup banner',
    );
  }

  void _recordHomeBannerView(String bannerId) {
    if (bannerId.trim().isEmpty || !_countedHomeBannerIds.add(bannerId)) {
      return;
    }
    _recordAppBannerView(bannerId: bannerId, debugLabel: 'home banner');
  }

  void _recordAppBannerView({
    required String bannerId,
    required String debugLabel,
  }) {
    unawaited(() async {
      try {
        final ref = FirebaseFirestore.instance
            .collection('appBanners')
            .doc(bannerId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            return;
          }
          final data = snapshot.data();
          final current = _readCounter(data?['viewCount']);
          transaction.update(ref, <String, Object?>{
            'viewCount': current + 1,
            'lastViewedAt': FieldValue.serverTimestamp(),
          });
        });
      } catch (error, stackTrace) {
        _homeDebugLogStack(
          '$debugLabel view count skipped: $error',
          stackTrace,
        );
      }
    }());
  }

  int _readCounter(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
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
      final targeted = normalizedSlug.startsWith('party_')
          ? await _fetchPoliticalPartyFeedTemplates(
              categorySlug: normalizedSlug,
              scanLimit: nextLimit,
              source: Source.server,
            )
          : _isPoliticalFeedSlug(normalizedSlug)
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
              _allFeedSessionSeed,
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
    final rawFilteredTemplates = baseTemplates
        .where((item) => _matchesTemplate(item, language, selectedCategory))
        .toList(growable: false);
    final allFeedOrderLocked =
        selectedCategory.slug == _allCategorySlug &&
        _lockedAllFeedTemplates != null;
    final filteredTemplates =
        selectedCategory.slug == _allCategorySlug && !allFeedOrderLocked
        ? _rankVisibleAllFeedTemplates(rawFilteredTemplates, language: language)
        : rawFilteredTemplates;
    if (selectedCategory.slug == _allCategorySlug) {
      _ensureCurrentSlotAllFeedTemplatesLoaded(
        language: language,
        visibleTemplates: filteredTemplates,
      );
    }
    final normalizedSelectedSlug = _normalizeTag(
      selectedCategory.effectiveSelectionSlug,
    );
    final templates = normalizedSelectedSlug.startsWith('party_')
        ? _breakUpAdjacentCategoryRunsWorker(
            filteredTemplates,
            seed: Object.hash(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              normalizedSelectedSlug,
            ),
          )
        : filteredTemplates;
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
      unawaited(AppUpdateService.instance.checkForUpdate());
      if (mounted) {
        unawaited(AppSurveyService.instance.checkAndShowSurvey(context));
      }
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

  List<List<_HomePromoSlide>> _buildPromoSlideGroups(
    List<AppHomeBanner> banners,
  ) {
    final groups = List<List<_HomePromoSlide>>.generate(
      3,
      (_) => <_HomePromoSlide>[],
    );
    for (final banner in banners) {
      final imageUrl = banner.imageUrl.trim();
      if (imageUrl.isEmpty) {
        continue;
      }
      final groupIndex = banner.promoCardGroup.clamp(1, 3).toInt() - 1;
      groups[groupIndex].add(
        _HomePromoSlide(imageUrl: imageUrl, ctaTarget: banner.ctaTarget.trim()),
      );
    }
    return groups
        .map((slides) => slides.take(6).toList(growable: false))
        .toList(growable: false);
  }

  List<_HomeFeedPromoCardData> _buildPromoCards({
    required AppStrings strings,
    required SubscriptionBackendResult? entitlement,
    required List<List<_HomePromoSlide>> promoSlideGroups,
  }) {
    final isPro = entitlement?.hasAccess ?? false;
    final cards = <_HomeFeedPromoCardData>[
      for (final slides in promoSlideGroups)
        if (slides.isNotEmpty)
          _HomeFeedPromoCardData(
            type: _HomePromoCardType.featured,
            title: strings.localized(
              telugu: 'మన పోస్టర్ ప్రత్యేకం',
              english: 'Mana Poster special',
              hindi: 'माना पोस्टर विशेष',
              tamil: 'மனா போஸ்டர் சிறப்பு',
              kannada: 'ಮನ ಪೋಸ್ಟರ್ ವಿಶೇಷ',
              malayalam: 'മന പോസ്റ്റർ സ്പെഷ്യൽ',
              marathi: 'मना पोस्टर विशेष',
              gujarati: 'માના પોસ્ટર વિશેષ',
              bengali: 'মানা পোস্টার বিশেষ',
              punjabi: 'ਮਾਨਾ ਪੋਸਟਰ ਵਿਸ਼ੇਸ਼',
              odia: 'ମନା ପୋଷ୍ଟର ସ୍ୱତନ୍ତ୍ର',
              assamese: 'মানা পোষ্টাৰ বিশেষ',
              konkani: 'माना पोस्टर खाशेलें',
              nepali: 'माना पोस्टर विशेष',
              meitei: 'মানা পোস্তর স্পিসিএল',
              mizo: 'Mana Poster bik',
              kashmiri: 'مانا پوسٹر خاص',
              ladakhi: 'མཱ་ན་པོ་སི་ཊར་དམིགས་བསལ།',
            ),
            subtitle: strings.localized(
              telugu: 'మీ కోసం సరికొత్త పోస్టర్లు, ఆఫర్లు మరియు అప్‌డేట్లు.',
              english: 'Fresh posters, offers, and updates for you.',
              hindi: 'आपके लिए नए पोस्टर, ऑफ़र और अपडेट।',
              tamil:
                  'உங்களுக்கான புதிய போஸ்டர்கள், சலுகைகள் மற்றும் புதுப்பிப்புகள்.',
              kannada: 'ನಿಮಗಾಗಿ ಹೊಸ ಪೋಸ್ಟರ್‌ಗಳು, ಆಫರ್‌ಗಳು ಮತ್ತು ನವೀಕರಣಗಳು.',
              malayalam:
                  'നിങ്ങൾക്കായി പുതിയ പോസ്റ്ററുകൾ, ഓഫറുകൾ, അപ്‌ഡേറ്റുകൾ.',
              marathi: 'तुमच्यासाठी नवीन पोस्टर्स, ऑफर्स आणि अपडेट्स.',
              gujarati: 'તમારા માટે નવા પોસ્ટરો, ઑફર્સ અને અપડેટ્સ.',
              bengali: 'আপনার জন্য নতুন পোস্টার, অফার এবং আপডেট।',
              punjabi: 'ਤੁਹਾਡੇ ਲਈ ਨਵੇਂ ਪੋਸਟਰ, ਆਫ਼ਰਾਂ ਅਤੇ ਅੱਪਡੇਟ।',
              odia: 'ଆପଣଙ୍କ ପାଇଁ ନୂଆ ପୋଷ୍ଟର, ଅଫର ଏବଂ ଅପଡେଟ୍।',
              assamese: 'আপোনাৰ বাবে নতুন পোষ্টাৰ, অফাৰ আৰু আপডেট।',
              konkani: 'तुमच्या खातीर नवी पोस्टरां, ऑफर्स आनी अपडेट्स.',
              nepali: 'तपाईंको लागि नयाँ पोस्टरहरू, अफरहरू र अपडेटहरू।',
              meitei: 'নহাক্কীদমক অনৌবা পোস্তরশিং, ওফরশিং অমসুং অপদেতশিং।',
              mizo: 'Poster thar, offer leh update te i tan.',
              kashmiri: 'تُہندِ خٲطرٕ نٔوؠ پوسٹر، پیشکش تہٕ اپڈیٹ۔',
              ladakhi:
                  'ཁྱེད་ཀྱི་ཆེད་དུ་པོ་སི་ཊར་གསར་པ། གཅོག་ཆ་དང་གནས་ཚུལ་གསར་པ།',
            ),
            buttonLabel: strings.localized(
              telugu: 'తెరవండి',
              english: 'Open',
              hindi: 'खोलें',
              tamil: 'திற',
              kannada: 'ತೆರೆಯಿರಿ',
              malayalam: 'തുറക്കുക',
              marathi: 'उघडा',
              gujarati: 'ખોલો',
              bengali: 'খুলুন',
              punjabi: 'ਖੋਲ੍ਹੋ',
              odia: 'ଖୋଲନ୍ତୁ',
              assamese: 'খোলক',
              konkani: 'उगडात',
              nepali: 'खोल्नुहोस्',
              meitei: 'হাংদোকউ',
              mizo: 'Hawng rawh',
              kashmiri: 'کھولِو',
              ladakhi: 'ཁ་ཕྱེ།',
            ),
            slides: slides,
          ),
      if (promoSlideGroups.every((slides) => slides.isEmpty) &&
          _promoCardBanners.isNotEmpty)
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.featured,
          title: strings.localized(
            telugu: 'మన పోస్టర్ ప్రత్యేకం',
            english: 'Mana Poster special',
            hindi: 'माना पोस्टर विशेष',
            tamil: 'மனா போஸ்டர் சிறப்பு',
            kannada: 'ಮನ ಪೋಸ್ಟರ್ ವಿಶೇಷ',
            malayalam: 'മന പോസ്റ്റർ സ്പെഷ്യൽ',
            marathi: 'मना पोस्टर विशेष',
            gujarati: 'માના પોસ્ટર વિશેષ',
            bengali: 'মানা পোস্টার বিশেষ',
            punjabi: 'ਮਾਨਾ ਪੋਸਟਰ ਵਿਸ਼ੇਸ਼',
            odia: 'ମନା ପୋଷ୍ଟର ସ୍ୱତନ୍ତ୍ର',
            assamese: 'মানা পোষ্টাৰ বিশেষ',
            konkani: 'माना पोस्टर खाशेलें',
            nepali: 'माना पोस्टर विशेष',
            meitei: 'মানা পোস্তর স্পিসিএল',
            mizo: 'Mana Poster bik',
            kashmiri: 'مانا پوسٹر خاص',
            ladakhi: 'མཱ་ན་པོ་སི་ཊར་དམིགས་བསལ།',
          ),
          subtitle: strings.localized(
            telugu: 'మీ కోసం సరికొత్త పోస్టర్లు, ఆఫర్లు మరియు అప్‌డేట్లు.',
            english: 'Fresh posters, offers, and updates for you.',
            hindi: 'आपके लिए नए पोस्टर, ऑफ़र और अपडेट।',
            tamil:
                'உங்களுக்கான புதிய போஸ்டர்கள், சலுகைகள் மற்றும் புதுப்பிப்புகள்.',
            kannada: 'ನಿಮಗಾಗಿ ಹೊಸ ಪೋಸ್ಟರ್‌ಗಳು, ಆಫರ್‌ಗಳು ಮತ್ತು ನವೀಕರಣಗಳು.',
            malayalam: 'നിങ്ങൾക്കായി പുതിയ പോസ്റ്ററുകൾ, ഓഫറുകൾ, അപ്‌ഡേറ്റുകൾ.',
            marathi: 'तुमच्यासाठी नवीन पोस्टर्स, ऑफर्स आणि अपडेट्स.',
            gujarati: 'તમારા માટે નવા પોસ્ટરો, ઑફર્સ અને અપડેટ્સ.',
            bengali: 'আপনার জন্য নতুন পোস্টার, অফার এবং আপডেট।',
            punjabi: 'ਤੁਹਾਡੇ ਲਈ ਨਵੇਂ ਪੋਸਟਰ, ਆਫ਼ਰਾਂ ਅਤੇ ਅੱਪਡੇਟ।',
            odia: 'ଆପଣଙ୍କ ପାଇଁ ନୂଆ ପୋଷ୍ଟର, ଅଫର ଏବଂ ଅପଡେଟ୍।',
            assamese: 'আপোনাৰ বাবে নতুন পোষ্টাৰ, অফাৰ আৰু আপডেট।',
            konkani: 'तुमच्या खातीर नवी पोस्टरां, ऑफर्स आनी अपडेट्स.',
            nepali: 'तपाईंको लागि नयाँ पोस्टरहरू, अफरहरू र अपडेटहरू।',
            meitei: 'নহাক্কীদমক অনৌবা পোস্তরশিং, ওফরশিং অমসুং অপদেতশিং।',
            mizo: 'Poster thar, offer leh update te i tan.',
            kashmiri: 'تُہندِ خٲطرٕ نٔوؠ پوسٹر، پیشکش تہٕ اپڈیٹ۔',
            ladakhi: 'ཁྱེད་ཀྱི་ཆེད་དུ་པོ་སི་ཊར་གསར་པ། གཅོག་ཆ་དང་གནས་ཚུལ་གསར་པ།',
          ),
          buttonLabel: strings.localized(
            telugu: 'తెరవండి',
            english: 'Open',
            hindi: 'खोलें',
            tamil: 'திற',
            kannada: 'ತೆರೆಯಿರಿ',
            malayalam: 'തുറക്കുക',
            marathi: 'उघडा',
            gujarati: 'ખોલો',
            bengali: 'খুলুন',
            punjabi: 'ਖੋਲ੍ਹੋ',
            odia: 'ଖୋଲନ୍ତୁ',
            assamese: 'খোলক',
            konkani: 'उगडात',
            nepali: 'खोल्नुहोस्',
            meitei: 'হাংদোকউ',
            mizo: 'Hawng rawh',
            kashmiri: 'کھولِو',
            ladakhi: 'ཁ་ཕྱེ།',
          ),
        ),
      if (!isPro)
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.subscribe,
          title: strings.localized(
            telugu: 'మెంబర్‌షిప్‌తో మరిన్ని పోస్టర్లను పొందండి',
            english: 'Unlock more posters with membership',
            hindi: 'सदस्यता के साथ अधिक पोस्टर अनलॉक करें',
            tamil:
                'உறுப்பினர் சேர்க்கையுடன் கூடுதல் போஸ்டர்களை அன்லாக் செய்யவும்',
            kannada: 'ಸದಸ್ಯತ್ವದೊಂದಿಗೆ ಹೆಚ್ಚಿನ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡಿ',
            malayalam: 'മെമ്പർഷിപ്പ് വഴി കൂടുതൽ പോസ്റ്ററുകൾ അൺലോക്ക് ചെയ്യുക',
            marathi: 'सदस्यत्वासह अधिक पोस्टर्स अनलॉक करा',
            gujarati: 'સભ્યપદ સાથે વધુ પોસ્ટર્સ અનલૉક કરો',
            bengali: 'মেম্বারশিপের সাথে আরও পোস্টার আনলক করুন',
            punjabi: 'ਮੈਂਬਰਸ਼ਿਪ ਨਾਲ ਹੋਰ ਪੋਸਟਰ ਅਨਲੌਕ ਕਰੋ',
            odia: 'ମେମ୍ବରସିପ୍ ସହିତ ଅଧିକ ପୋଷ୍ଟର ଅନଲକ୍ କରନ୍ତୁ',
            assamese: 'সদস্যপদৰ সৈতে অধিক পোষ্টাৰ আনলক কৰক',
            konkani: 'वांगडेपणा सयत आनीक पोस्टरां अनलॉक करात',
            nepali: 'सदस्यता लिएर थप पोस्टरहरू अनलक गर्नुहोस्',
            meitei: 'মেম্বরশিপকা লোয়ননা অহেনবা পোস্তরশিং হাংদোকউ',
            mizo: 'Membership hmangin poster tam zawk hawng rawh',
            kashmiri: 'ممبرشِپ سٟتؠ کٔرِو زیٛادٕ پوسٹر انلاک',
            ladakhi: 'ཚོགས་མིའི་ཐོབ་ཐང་དང་མཉམ་དུ་པོ་སི་ཊར་མང་པོ་ཁ་ཕྱེ།',
          ),
          subtitle: strings.localized(
            telugu:
                'డౌన్‌లోడ్‌లు, షేరింగ్ మరియు మెంబర్‌షిప్ ప్రయోజనాల కోసం సబ్‌స్క్రైబ్ చేయండి.',
            english:
                'Subscribe for downloads, sharing, and membership benefits.',
            hindi: 'डाउनलोड, शेयरिंग और सदस्यता लाभों के लिए सदस्यता लें।',
            tamil:
                'பதிவிறக்கங்கள், பகிர்வு மற்றும் உறுப்பினர் நன்மைகளுக்கு குழுசேரவும்.',
            kannada:
                'ಡೌನ್‌ಲೋಡ್‌ಗಳು, ಹಂಚಿಕೆ ಮತ್ತು ಸದಸ್ಯತ್ವ ಪ್ರಯೋಜನಗಳಿಗಾಗಿ ಚಂದಾದಾರರಾಗಿ.',
            malayalam:
                'ഡൗൺലോഡുകൾ, പങ്കിടൽ, മെമ്പർഷിപ്പ് ആനുകൂല്യങ്ങൾ എന്നിവയ്ക്കായി സബ്സ്ക്രൈബ് ചെയ്യുക.',
            marathi:
                'डाउनलोड, शेअरिंग आणि सदस्यत्वाच्या फायद्यांसाठी सदस्यता घ्या.',
            gujarati: 'ડાઉનલોડ્સ, શેરિંગ અને સભ્યપદ લાભો માટે સબ્સ્ક્રાઇબ કરો.',
            bengali:
                'ডাউনলোড, শেয়ারিং এবং মেম্বারশিপের সুবিধার জন্য সাবস্ক্রাইব করুন।',
            punjabi: 'ਡਾਊਨਲੋਡਾਂ, ਸਾਂਝਾਕਰਨ ਅਤੇ ਮੈਂਬਰਸ਼ਿਪ ਲਾਭਾਂ ਲਈ ਗਾਹਕ ਬਣੋ।',
            odia:
                'ଡାଉନଲୋଡ୍, ସେୟାରିଂ ଏବଂ ମେମ୍ବରସିପ୍ ଲାଭ ପାଇଁ ସବସ୍କ୍ରାଇବ୍ କରନ୍ତୁ।',
            assamese:
                'ডাউনলোড, শ্বেয়াৰিং আৰু সদস্যপদৰ সুবিধাৰ বাবে চাবস্ক্ৰাইব কৰক।',
            konkani:
                'डाऊनलोड, वांटप आनी वांगडेपणाच्या फायद्यां खातीर वर्गणीदार जायात.',
            nepali:
                'डाउनलोड, सेयरिङ र सदस्यता फाइदाहरूका लागि सदस्यता लिनुहोस्।',
            meitei:
                'দাউনলোদ, শিয়ারিং অমসুং মেম্বরশিপকী কান্নবশিংগীদমক সবস্ক্রাইব তৌবীয়ু।',
            mizo: 'Download, share leh membership hlawkna atan subscribe rawh.',
            kashmiri:
                'ڈاؤنلوڈ، شیئرِنگ تہٕ ممبرشِپ فایدن خٲطرٕ کٔرِو سبسکرائب۔',
            ladakhi:
                'ཕབ་ལེན། བགོ་འགྲེམས་དང་ཚོགས་མིའི་ཁེ་ཕན་ཆེད་དུ་མངགས་ཉོ་བྱོས།',
          ),
          buttonLabel: strings.localized(
            telugu: 'మెంబర్‌షిప్ తీసుకోండి',
            english: 'Purchase Membership',
            hindi: 'सदस्यता खरीदें',
            tamil: 'உறுப்பினர் சேர்க்கையை வாங்கவும்',
            kannada: 'ಸದಸ್ಯತ್ವ ಖರೀದಿಸಿ',
            malayalam: 'മെമ്പർഷിപ്പ് വാങ്ങുക',
            marathi: 'सदस्यत्व खरेदी करा',
            gujarati: 'સભ્યપદ ખરીદો',
            bengali: 'মেম্বারশিপ কিনুন',
            punjabi: 'ਮੈਂਬਰਸ਼ਿਪ ਖਰੀਦੋ',
            odia: 'ମେମ୍ବରସିପ୍ କିଣନ୍ତୁ',
            assamese: 'সদস্যপদ ক্ৰয় কৰক',
            konkani: 'वांगडेपण विकतें घेयात',
            nepali: 'सदस्यता खरिद गर्नुहोस्',
            meitei: 'মেম্বরশিপ লৈবীয়ু',
            mizo: 'Membership lei rawh',
            kashmiri: 'ممبرشِپ ہؠوِو',
            ladakhi: 'ཚོགས་མིའི་ཐོབ་ཐང་ཉོས།',
          ),
        ),
      if (_shouldShowRenewalReminder(entitlement))
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.renewalReminder,
          title: strings.localized(
            telugu: 'మీ మెంబర్‌షిప్ త్వరలో ముగియనుంది',
            english: 'Your membership is expiring soon',
            hindi: 'आपकी सदस्यता जल्द समाप्त हो रही है',
            tamil: 'உங்கள் உறுப்பினர் சேர்க்கை விரைவில் காலாவதியாகிறது',
            kannada: 'ನಿಮ್ಮ ಸದಸ್ಯತ್ವ ಶೀಘ್ರದಲ್ಲೇ ಮುಕ್ತಾಯಗೊಳ್ಳಲಿದೆ',
            malayalam: 'നിങ്ങളുടെ മെമ്പർഷിപ്പ് ഉടൻ കാലഹരണപ്പെടും',
            marathi: 'तुमचे सदस्यत्व लवकरच संपत आहे',
            gujarati: 'તમારું સભ્યપદ ટૂંક સમયમાં સમાપ્ત થઈ રહ્યું છે',
            bengali: 'আপনার মেম্বারশিপ শীঘ্রই শেষ হতে চলেছে',
            punjabi: 'ਤੁਹਾਡੀ ਮੈਂਬਰਸ਼ਿਪ ਜਲਦੀ ਖਤਮ ਹੋ ਰਹੀ ਹੈ',
            odia: 'ଆପଣଙ୍କ ମେମ୍ବରସିପ୍ ଶୀଘ୍ର ଶେଷ ହେବାକୁ ଯାଉଛି',
            assamese: 'আপোনাৰ সদস্যপদৰ ম্যাদ সোনকালে উকলিব',
            konkani: 'तुमचें वांगडेपण बेगीनच सोंपतलें',
            nepali: 'तपाईंको सदस्यता चाँडै समाप्त हुँदैछ',
            meitei: 'নহাক্কী মেম্বরশিপ থুনা লোইশিনগদৌরক্লে',
            mizo: 'I membership a tawp tep e',
            kashmiri: 'تُہنزِ ممبرشِپ چھِ جلد ختم گژھان',
            ladakhi: 'ཁྱེད་ཀྱི་ཚོགས་མིའི་དུས་ཚོད་མགྱོགས་པར་རྫོགས་རྒྱུ་ཡིན།',
          ),
          subtitle: strings.localized(
            telugu:
                'మీ ప్లాన్ రాబోయే 3 రోజుల్లో ముగుస్తుంది. అంతరాయం లేకుండా పోస్టర్లను ఉపయోగించడానికి ఇప్పుడే పునరుద్ధరించండి.',
            english:
                'Your plan ends within the next 3 days. Renew now to keep using posters without interruption.',
            hindi:
                'आपका प्लान अगले 3 दिनों में समाप्त हो रहा है। बिना रुकावट पोस्टर उपयोग करने के लिए अभी नवीनीकरण करें।',
            tamil:
                'உங்கள் திட்டம் அடுத்த 3 நாட்களில் முடிகிறது. தடையின்றி போஸ்டர்களைப் பயன்படுத்த இப்போதே புதுப்பிக்கவும்.',
            kannada:
                'ನಿಮ್ಮ ಪ್ಲಾನ್ ಮುಂದಿನ 3 ದಿನಗಳಲ್ಲಿ ಕೊನೆಗೊಳ್ಳುತ್ತದೆ. ಅಡೆತಡೆಯಿಲ್ಲದೆ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಬಳಸಲು ಈಗಲೇ ನವೀಕರಿಸಿ.',
            malayalam:
                'നിങ്ങളുടെ പ്ലാൻ അടുത്ത 3 ദിവസത്തിനുള്ളിൽ അവസാനിക്കും. തടസ്സമില്ലാതെ പോസ്റ്ററുകൾ ഉപയോഗിക്കാൻ ഇപ്പോൾ പുതുക്കുക.',
            marathi:
                'तुमचा प्लॅन पुढील 3 दिवसांत संपेल. अखंड पोस्टर्स वापरण्यासाठी आता नूतनीकरण करा.',
            gujarati:
                'તમારો પ્લાન આગામી 3 દિવસમાં સમાપ્ત થાય છે. અવિરતપણે પોસ્ટરો વાપરવા માટે હમણાં જ રિન્યૂ કરો.',
            bengali:
                'আপনার প্ল্যান আগামী ৩ দিনের মধ্যে শেষ হবে। নিরবচ্ছিন্নভাবে পোস্টার ব্যবহার করতে এখনই পুনর্নবীকরণ করুন।',
            punjabi:
                'ਤੁਹਾਡਾ ਪਲਾਨ ਅਗਲੇ 3 ਦਿਨਾਂ ਵਿੱਚ ਖਤਮ ਹੋ ਰਿਹਾ ਹੈ। ਬਿਨਾਂ ਰੁਕਾਵਟ ਪੋਸਟਰ ਵਰਤਣ ਲਈ ਹੁਣੇ ਰੀਨਿਊ ਕਰੋ।',
            odia:
                'ଆପଣଙ୍କ ପ୍ଲାନ୍ ଆଗାମୀ ୩ ଦିନରେ ଶେଷ ହେବ। ବିନା ବାଧାରେ ପୋଷ୍ଟର ବ୍ୟବହାର କରିବା ପାଇଁ ଏବେ ନବୀକରଣ କରନ୍ତୁ।',
            assamese:
                'আপোনাৰ প্লেন অহা ৩ দিনৰ ভিতৰত শেষ হ’ব। কোনো বাধা নোহোৱাকৈ পোষ্টাৰ ব্যৱহাৰ কৰিবলৈ এতিয়াই নবীকৰণ কৰক।',
            konkani:
                'तुमचो प्लॅन फुडल्या 3 दिसांत सोंपाय. विनाअडचण पोस्टरां वापरूंक आतांच नूतनीकरण करात.',
            nepali:
                'तपाईंको योजना आगामी ३ दिन भित्र समाप्त हुँदैछ। निरन्तर पोस्टरहरू प्रयोग गर्न अहिले नवीकरण गर्नुहोस्।',
            meitei:
                'নহাক্কী প্লান লাক্কদৌরিবা নুমিৎ 3 নিগী মনুংদা লোইশিনগনি। অকায়বা য়াওদনা পোস্তরশিং শীজিন্ননবগীদমক হৌজিক নৌথোকহন্নবীয়ু।',
            mizo:
                'I plan chu ni 3 chhungin a tawp dawn. Poster tibuai lova hmang chhunzawm zel turin renew nghal rawh.',
            kashmiri:
                'تُہند پلان چُھ یِوان والؠن 3 دوہن منٛز ختم گژھان۔ بلا رُکاوٹ پوسٹر اِستعمال کرن خٲطرٕ کٔرِو وۄنؠ نویں سرٕ۔',
            ladakhi:
                'ཁྱེད་ཀྱི་འཆར་གཞི་ཉིན་ ༣ ནང་རྫོགས་རྒྱུ་ཡིན། བར་ཆད་མེད་པར་པོ་སི་ཊར་བེད་སྤྱོད་གཏོང་ཆེད་ད་ལྟ་གསར་བཟོ་བྱོས།',
          ),
          buttonLabel: strings.localized(
            telugu: 'మెంబర్‌షిప్ పునరుద్ధరించండి',
            english: 'Renew Membership',
            hindi: 'सदस्यता नवीनीकृत करें',
            tamil: 'உறுப்பினர் சேர்க்கையைப் புதுப்பிக்கவும்',
            kannada: 'ಸದಸ್ಯತ್ವ ನವೀಕರಿಸಿ',
            malayalam: 'മെമ്പർഷിപ്പ് പുതുക്കുക',
            marathi: 'सदस्यत्व नूतनीकरण करा',
            gujarati: 'સભ્યપદ રિન્યૂ કરો',
            bengali: 'মেম্বারশিপ রিনিউ করুন',
            punjabi: 'ਮੈਂਬਰਸ਼ਿਪ ਰੀਨਿਊ ਕਰੋ',
            odia: 'ମେମ୍ବରସିପ୍ ନବୀକରଣ କରନ୍ତୁ',
            assamese: 'সদস্যপদ নবীকৰণ কৰক',
            konkani: 'वांगडेपणाचें नूतनीकरण करात',
            nepali: 'सदस्यता नवीकरण गर्नुहोस्',
            meitei: 'মেম্বরশিপ নৌথোকহনবীয়ু',
            mizo: 'Membership renew rawh',
            kashmiri: 'ممبرشِپ نویں سرٕ کٔرِو',
            ladakhi: 'ཚོགས་མིའི་ཐོབ་ཐང་གསར་བཟོ་བྱོས།',
          ),
        ),
      if (isPro && _isUpdateAvailable())
        if (_isUpdateAvailable())
          _HomeFeedPromoCardData(
            type: _HomePromoCardType.update,
            title: strings.localized(
              telugu: 'కొత్త యాప్ అప్‌డేట్ సిద్ధంగా ఉంది',
              english: 'A new app update is ready',
              hindi: 'नया ऐप अपडेट उपलब्ध है',
              tamil: 'புதிய செயலி புதுப்பிப்பு தயாராக உள்ளது',
              kannada: 'ಹೊಸ ಆ್ಯಪ್ ಅಪ್‌ಡೇಟ್ ಸಿದ್ಧವಾಗಿದೆ',
              malayalam: 'പുതിയ ആപ്പ് അപ്‌ഡേറ്റ് ലഭ്യമാണ്',
              marathi: 'नवीन ॲप अपडेट तयार आहे',
              gujarati: 'નવું ઍપ અપડેટ તૈયાર છે',
              bengali: 'একটি নতুন অ্যাপ আপডেট উপলব্ধ',
              punjabi: 'ਇੱਕ ਨਵਾਂ ਐਪ ਅੱਪਡੇਟ ਤਿਆਰ ਹੈ',
              odia: 'ଏକ ନୂଆ ଆପ୍ ଅପଡେଟ୍ ପ୍ରସ୍ତୁତ ଅଛି',
              assamese: 'এটা নতুন এপ আপডেট প্ৰস্তুত আছে',
              konkani: 'नवें ॲप अपडेट तयार आसा',
              nepali: 'नयाँ एप अपडेट तयार छ',
              meitei: 'অনৌবা এপ অপদেত অমা শেম-শাদুনা লৈরে',
              mizo: 'App update thar a awm e',
              kashmiri: 'نۆو ایپ اپڈیٹ چُھ تیار',
              ladakhi: 'མཉེན་ཆས་གསར་སྒྱུར་གསར་པ་གྲ་སྒྲིག་ཡོད།',
            ),
            subtitle: strings.localized(
              telugu:
                  'ప్లే స్టోర్‌లో సరికొత్త వెర్షన్ అందుబాటులో ఉంది. తాజా మెరుగుదలల కోసం ఇప్పుడే అప్‌డేట్ చేయండి.',
              english:
                  'A newer version is available on the Play Store. Update now for the latest improvements.',
              hindi:
                  'प्ले स्टोर पर नया वर्शन उपलब्ध है। नवीनतम सुधारों के लिए अभी अपडेट करें।',
              tamil:
                  'ப்ளே ஸ்டோரில் புதிய பதிப்பு கிடைக்கிறது. சமீபத்திய மேம்பாடுகளுக்கு இப்போதே புதுப்பிக்கவும்.',
              kannada:
                  'ಪ್ಲೇ ಸ್ಟೋರ್‌ನಲ್ಲಿ ಹೊಸ ಆವೃತ್ತಿ ಲಭ್ಯವಿದೆ. ಇತ್ತೀಚಿನ ಸುಧಾರಣೆಗಳಿಗಾಗಿ ಈಗಲೇ ಅಪ್‌ಡೇಟ್ ಮಾಡಿ.',
              malayalam:
                  'പ്ലേ സ്റ്റോറിൽ പുതിയ പതിപ്പ് ലഭ്യമാണ്. ഏറ്റവും പുതിയ മെച്ചപ്പെടുത്തലുകൾക്കായി ഇപ്പോൾ അപ്‌ഡേറ്റ് ചെയ്യുക.',
              marathi:
                  'प्ले स्टोअरवर नवीन आवृत्ती उपलब्ध आहे. नवीनतम सुधारणांसाठी आता अपडेट करा.',
              gujarati:
                  'પ્લે સ્ટોર પર નવું વર્ઝન ઉપલબ્ધ છે. નવીનતમ સુધારાઓ માટે હમણાં જ અપડેટ કરો.',
              bengali:
                  'প্লে স্টোরে একটি নতুন সংস্করণ উপলব্ধ রয়েছে। সর্বশেষ উন্নতির জন্য এখনই আপডেট করুন।',
              punjabi:
                  'ਪਲੇ ਸਟੋਰ \'ਤੇ ਇੱਕ ਨਵਾਂ ਵਰਜਨ ਉਪਲਬਧ ਹੈ। ਨਵੀਨਤਮ ਸੁਧਾਰਾਂ ਲਈ ਹੁਣੇ ਅੱਪਡੇਟ ਕਰੋ।',
              odia:
                  'ପ୍ଲେ ଷ୍ଟୋରରେ ଏକ ନୂତନ ସଂସ୍କରଣ ଉପଲବ୍ଧ। ସର୍ବଶେଷ ସୁଧାର ପାଇଁ ଏବେ ଅପଡେଟ୍ କରନ୍ତୁ।',
              assamese:
                  'প্লে ষ্টোৰত এটা নতুন সংস্কৰণ উপলব্ধ। শেহতীয়া উন্নতিৰ বাবে এতিয়াই আপডেট কৰক।',
              konkani:
                  'प्ले स्टोरार नवी आवृत्ती मेळटा. ताज्या सुदारणां खातीर आतांच अपडेट करात.',
              nepali:
                  'प्ले स्टोरमा नयाँ संस्करण उपलब्ध छ। पछिल्ला सुधारहरूका लागि अहिले नै अपडेट गर्नुहोस्।',
              meitei:
                  'প্লে স্তোরদা অনৌবা ভর্সন অমা ফংলে। নৌবা ফগৎলকপশিংগীদমক হৌজিক অপদেত তৌবীয়ু।',
              mizo:
                  'Play Store-ah version thar a awm. Siamthat thar ber ber te nei turin update nghal rawh.',
              kashmiri:
                  'پلے سٹوٗرس پؠٹھ چُھ نۆو ورژن دستیاب۔ تازہ ترین سُدھارن خٲطرٕ کٔرِو وۄنؠ اپڈیٹ۔',
              ladakhi:
                  'པེ་ལེ་སི་ཊོར་ནང་ཐོན་རིམ་གསར་པ་ཡོད། ལེགས་བཅོས་གསར་ཤོས་ཆེད་ད་ལྟ་གསར་སྒྱུར་བྱོས།',
            ),
            buttonLabel: strings.localized(
              telugu: 'యాప్‌ను అప్‌డేట్ చేయండి',
              english: 'Update App',
              hindi: 'ऐप अपडेट करें',
              tamil: 'செயலியைப் புதுப்பிக்கவும்',
              kannada: 'ಆ್ಯಪ್ ಅಪ್‌ಡೇಟ್ ಮಾಡಿ',
              malayalam: 'ആപ്പ് അപ്‌ഡേറ്റ് ചെയ്യുക',
              marathi: 'ॲप अपडेट करा',
              gujarati: 'ઍપ અપડેટ કરો',
              bengali: 'অ্যাপ আপডেট করুন',
              punjabi: 'ਐਪ ਅੱਪਡੇਟ ਕਰੋ',
              odia: 'ଆପ୍ ଅପଡେଟ୍ କରନ୍ତୁ',
              assamese: 'এপ আপডেট কৰক',
              konkani: 'ॲप अपडेट करात',
              nepali: 'एप अपडेट गर्नुहोस्',
              meitei: 'এপ অপদেত তৌবীয়ু',
              mizo: 'App update rawh',
              kashmiri: 'ایپ کٔرِو اپڈیٹ',
              ladakhi: 'མཉེན་ཆས་གསར་སྒྱུར་བྱོས།',
            ),
          ),
      if (!_hasRatedApp)
        _HomeFeedPromoCardData(
          type: _HomePromoCardType.rate,
          title: strings.localized(
            telugu: 'మన పోస్టర్ Ai ని రేట్ చేయండి',
            english: 'Rate Mana Poster Ai',
            hindi: 'माना पोस्टर Ai को रेट करें',
            tamil: 'மனா போஸ்டர் Ai-ஐ மதிப்பிடவும்',
            kannada: 'ಮನ ಪೋಸ್ಟರ್ Ai ರೇಟ್ ಮಾಡಿ',
            malayalam: 'മന പോസ്റ്റർ Ai റേറ്റ് ചെയ്യുക',
            marathi: 'मना पोस्टर Ai ला रेट करा',
            gujarati: 'માના પોસ્ટર Ai ને રેટ કરો',
            bengali: 'মানা পোস্টার Ai রেট করুন',
            punjabi: 'ਮਾਨਾ ਪੋਸਟਰ Ai ਨੂੰ ਰੇਟ ਕਰੋ',
            odia: 'ମନା ପୋଷ୍ଟର Ai କୁ ରେଟ୍ କରନ୍ତୁ',
            assamese: 'মানা পোষ্টাৰ Ai ৰেট কৰক',
            konkani: 'माना पोस्टर Ai चेर मोल घालात',
            nepali: 'माना पोस्टर Ai लाई मूल्याङ्कन गर्नुहोस्',
            meitei: 'মানা পোস্তর Ai রেত তৌবীয়ু',
            mizo: 'Mana Poster Ai rate rawh',
            kashmiri: 'مانا پوسٹر Ai کٔرِو ریٹ',
            ladakhi: 'མཱ་ན་པོ་སི་ཊར་ Ai ལ་སྐར་མ་སྤྲོད།',
          ),
          subtitle: strings.localized(
            telugu:
                'మీ రేటింగ్ మరియు సమీక్ష ద్వారా ఎక్కువ మందికి ఈ యాప్ చేరువవుతుంది.',
            english:
                'Your rating and review help more people discover the app.',
            hindi:
                'आपकी रेटिंग और समीक्षा अधिक लोगों को इस ऐप को खोजने में मदद करती है।',
            tamil:
                'உங்கள் மதிப்பீடும் மதிப்பாய்வும் அதிகமான மக்கள் செயலியை அறிய உதவும்.',
            kannada:
                'ನಿಮ್ಮ ರೇಟಿಂಗ್ ಮತ್ತು ವಿಮರ್ಶೆಯು ಹೆಚ್ಚಿನ ಜನರಿಗೆ ಈ ಆ್ಯಪ್ ತಲುಪಲು ಸಹಾಯ ಮಾಡುತ್ತದೆ.',
            malayalam:
                'നിങ്ങളുടെ റേറ്റിംഗും അവലോകനവും കൂടുതൽ ആളുകൾക്ക് ആപ്പ് കണ്ടെത്താൻ സഹായിക്കുന്നു.',
            marathi:
                'तुमचे रेटिंग आणि पुनरावलोकन अधिक लोकांना हे ॲप शोधण्यात मदत करते.',
            gujarati:
                'તમારું રેટિંગ અને સમીક્ષા વધુ લોકોને ઍપ શોધવામાં મદદ કરે છે.',
            bengali:
                'আপনার রেটিং এবং পর্যালোচনা আরও অনেক মানুষকে অ্যাপটি খুঁজে পেতে সাহায্য করবে।',
            punjabi:
                'ਤੁਹਾਡੀ ਰੇਟਿੰਗ ਅਤੇ ਸਮੀਖਿਆ ਹੋਰ ਲੋਕਾਂ ਨੂੰ ਐਪ ਖੋਜਣ ਵਿੱਚ ਮਦਦ ਕਰਦੀ ਹੈ।',
            odia:
                'ଆପଣଙ୍କ ରେଟିଂ ଏବଂ ସମୀକ୍ଷା ଅଧିକ ଲୋକଙ୍କୁ ଆପ୍ ଖୋଜିବାରେ ସାହାଯ୍ୟ କରେ।',
            assamese:
                'আপোনাৰ ৰেটিং আৰু পৰ্যালোচনাই অধিক ব্যক্তিক এপটো বিচাৰি পোৱাত সহায় কৰিব।',
            konkani:
                'तुमचें मोल आनी अभिप्राय चड लोकांक हें ॲप सोदून काडूंक मजत करतलें.',
            nepali:
                'तपाईंको मूल्याङ्कन र समीक्षाले धेरै मानिसहरूलाई एप फेला पार्न मद्दत गर्दछ।',
            meitei:
                'নহাক্কী রেতিং অমসুং রিব্যুনা অহেনবা মীওইশিংদা এপ অসি খঙহনবদা মতেং পাংগনি।',
            mizo:
                'I rating leh review hian mi tam zawk app hmuhchhuah nan a pui a ni.',
            kashmiri:
                'تُہند ریٹِنگ تہٕ رِویو چھُ زیٛادٕ لوٗکن ایپ دٔریافت کرنس منٛز مدد کران۔',
            ladakhi:
                'ཁྱེད་ཀྱི་སྐར་མ་དང་བསམ་ཚུལ་གྱིས་མི་མང་པོར་མཉེན་ཆས་འདི་རྙེད་པར་རོགས་བྱེད།',
          ),
          buttonLabel: strings.localized(
            telugu: 'యాప్‌ను రేట్ చేయండి',
            english: 'Rate App',
            hindi: 'ऐप को रेट करें',
            tamil: 'செயலியை மதிப்பிடு',
            kannada: 'ಆ್ಯಪ್ ರೇಟ್ ಮಾಡಿ',
            malayalam: 'ആപ്പ് റേറ്റ് ചെയ്യുക',
            marathi: 'ॲपला रेट करा',
            gujarati: 'ઍપ રેટ કરો',
            bengali: 'অ্যাপ রেট করুন',
            punjabi: 'ਐਪ ਨੂੰ ਰੇਟ ਕਰੋ',
            odia: 'ଆପ୍ କୁ ରେଟ୍ କରନ୍ତୁ',
            assamese: 'এপ ৰেট কৰক',
            konkani: 'ॲपाचेर मोल घालात',
            nepali: 'एप मूल्याङ्कन गर्नुहोस्',
            meitei: 'এপ রেত তৌবীয়ু',
            mizo: 'App rate rawh',
            kashmiri: 'ایپ کٔرِو ریٹ',
            ladakhi: 'མཉེན་ཆས་ལ་སྐར་མ་སྤྲོད།',
          ),
        ),
    ];
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
    const insertAfterEvery = 6;
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
                  'ప్లే స్టోర్‌ను తెరవలేకపోయాము. దయచేసి మళ్లీ ప్రయత్నించండి.',
              english: 'Could not open the Play Store. Please try again.',
              hindi: 'प्ले स्टोर नहीं खोला जा सका। कृपया पुनः प्रयास करें।',
              tamil:
                  'ப்ளே ஸ்டோரைத் திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada:
                  'ಪ್ಲೇ ಸ್ಟೋರ್ ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'പ്ലേ സ്റ്റോർ തുറക്കാനായില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
              marathi: 'प्ले स्टोअर उघडता आले नाही. कृपया पुन्हा प्रयत्न करा.',
              gujarati:
                  'પ્લે સ્ટોર ખોલી શકાયું નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
              bengali: 'প্লে স্টোর খোলা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
              punjabi:
                  'ਪਲੇ ਸਟੋਰ ਨਹੀਂ ਖੋਲ੍ਹਿਆ ਜਾ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
              odia:
                  'ପ୍ଲେ ଷ୍ଟୋର୍ ଖୋଲିବା ସମ୍ଭବ ହେଲାନାହିଁ। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
              assamese:
                  'প্লে ষ্টোৰ খুলিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
              konkani: 'प्ले स्टोर उगडूंक जालो ना. उपकार करून परत यत्न करा.',
              nepali: 'प्ले स्टोर खोल्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
              meitei:
                  'প্লে স্তোর হাংদোকপা ঙমদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
              mizo:
                  'Play Store hawn theih a ni lo. Khawngaihin ti nawn leh rawh.',
              kashmiri:
                  'پلے سٹوٗر ہیٚکہ نہٕ کٔڈِتھ۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
              ladakhi:
                  'པེ་ལེ་སི་ཊོར་ཁ་འབྱེད་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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

  Future<void> _handlePromoTap(
    _HomePromoCardType type, {
    String ctaTarget = '',
  }) async {
    switch (type) {
      case _HomePromoCardType.featured:
        final target = ctaTarget.trim();
        final uri = Uri.tryParse(target);
        final canOpenExternal =
            uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
        if (canOpenExternal) {
          await _openExternalPublicUrl(context, target);
        }
        return;
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
    if (slug == _dailyQuizCategorySlug) {
      unawaited(_openDailyQuiz());
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

  Future<void> _openDailyQuiz() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const DailyQuizScreen()),
    );
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
    final targeted = normalizedSlug.startsWith('party_')
        ? await _fetchPoliticalPartyFeedTemplates(
            categorySlug: normalizedSlug,
            scanLimit: fetchLimit,
            source: Source.server,
          )
        : _isPoliticalFeedSlug(normalizedSlug)
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
      final visibleTemplates = feedEntries
          .map((entry) => entry.template)
          .whereType<_TemplateItem>()
          .toList(growable: false);
      if (visibleTemplates.isNotEmpty) {
        _lockedAllFeedTemplates = visibleTemplates;
        _templateProjectionCache = null;
        _templateProjectionIdentity = null;
      }
    }
    if (index >= 0 && index < feedEntries.length) {
      final item = feedEntries[index].template;
      if (item != null) {
        _recordAllFeedTemplateInteraction(item, 'view');
        _recordPosterViewCount(item);
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

  void _openFullScreenPosterGallery({
    required int feedIndex,
    required List<_HomeFeedEntry> feedEntries,
    required _CategoryChipData selectedCategory,
    required AppLanguage language,
  }) {
    final templateFeedIndexes = <int>[];
    final templates = <_TemplateItem>[];
    for (var index = 0; index < feedEntries.length; index++) {
      final template = feedEntries[index].template;
      if (template == null) {
        continue;
      }
      templateFeedIndexes.add(index);
      templates.add(template);
    }
    if (templates.isEmpty || feedIndex < 0 || feedIndex >= feedEntries.length) {
      return;
    }
    final tappedTemplate = feedEntries[feedIndex].template;
    if (tappedTemplate == null) {
      return;
    }
    final initialIndex = math.max(0, templates.indexOf(tappedTemplate));
    var currentFeedIndex = feedIndex;
    final selectedSlug = selectedCategory.slug;
    final forcedPartyId = _partyIdFromCategorySlug(selectedSlug);
    Navigator.of(context)
        .push<void>(
          PageRouteBuilder<void>(
            opaque: true,
            barrierColor: Colors.black,
            transitionDuration: const Duration(milliseconds: 340),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (_, _, _) => _PosterFullScreenGallery(
              initialIndex: initialIndex,
              itemCount: templates.length,
              onPageChanged: (galleryIndex) {
                if (galleryIndex >= 0 &&
                    galleryIndex < templateFeedIndexes.length) {
                  currentFeedIndex = templateFeedIndexes[galleryIndex];
                }
              },
              itemBuilder: (galleryContext, index) {
                final item = templates[index];
                return _TemplateFeedItem(
                  key: ValueKey<String>(
                    'fullscreen-${item.templateId?.trim().isNotEmpty == true ? item.templateId!.trim() : '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath ?? item.videoUrl ?? 'poster'}'}',
                  ),
                  item: item,
                  hostContext: galleryContext,
                  language: language,
                  deferRichPosterPreview: false,
                  onOpenSubscriptionPlan: _pushSubscriptionPlanRoute,
                  viewerPosterProfile: _viewerPosterProfile,
                  posterRenderCycle: _posterRenderCycle,
                  onPosterPhotoDragStateChanged: (_) {},
                  playbackEnabled: true,
                  enablePoliticalProtocolOverlay:
                      selectedSlug == _politicalCategorySlug ||
                      forcedPartyId != null,
                  showPartyLogoInNameChip: forcedPartyId != null,
                  politicalProtocolPhotoScopeKey: _normalizeTag(selectedSlug),
                  partyLogoOverridesByPartyId: _partyLogoOverridesByPartyId,
                  politicalParties: _politicalParties,
                  forcedPoliticalProtocolPartyId: forcedPartyId,
                  showPosterEditButton: false,
                  allowPoliticalProtocolWithoutParty:
                      selectedSlug == _politicalCategorySlug,
                  preferUltraLightImage: false,
                  fillViewport: false,
                  previewOnly: true,
                  onInteraction: _recordAllFeedTemplateInteraction,
                );
              },
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.985,
                        end: 1,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
          ),
        )
        .whenComplete(() {
          if (!mounted || !_posterPageController.hasClients) {
            return;
          }
          final safeIndex =
              currentFeedIndex.clamp(0, math.max(0, feedEntries.length - 1))
                  as int;
          if (_activePosterPage != safeIndex) {
            _activePosterPage = safeIndex;
            _activePosterPageNotifier.value = safeIndex;
          }
          _posterPageController.jumpToPage(safeIndex);
        });
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
    final promoSlideGroups = _buildPromoSlideGroups(_promoCardBanners);
    final remotePromoSlides = promoSlideGroups
        .expand((slides) => slides)
        .toList(growable: false);
    final fallbackPromoSlides = remotePromoSlides.isNotEmpty
        ? remotePromoSlides.take(6).toList(growable: false)
        : templates
              .take(_promoSlidesLimit)
              .map(
                (item) => _HomePromoSlide(
                  imageUrl: (item.thumbnailUrl ?? item.imageUrl ?? '').trim(),
                  ctaTarget: '',
                ),
              )
              .where((slide) => slide.imageUrl.isNotEmpty)
              .toList(growable: false);
    final promoCards = _buildPromoCards(
      strings: strings,
      entitlement: effectiveEntitlement,
      promoSlideGroups: promoSlideGroups,
    );
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
                onBannerViewed: _recordHomeBannerView,
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
                          if (feedEntries.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _handlePosterPageChanged(
                                  activeFeedPage,
                                  feedEntries,
                                );
                              }
                            });
                          }
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
                                final promo = entry.promo!;
                                final cardSlides = promo.slides.isNotEmpty
                                    ? promo.slides
                                    : fallbackPromoSlides;
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    18,
                                  ),
                                  child: Center(
                                    child: _HomeInlinePromoCard(
                                      data: promo,
                                      viewerPosterProfile: _viewerPosterProfile,
                                      slides: cardSlides,
                                      onTap: (ctaTarget) => unawaited(
                                        _handlePromoTap(
                                          promo.type,
                                          ctaTarget: ctaTarget,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final item = entry.template!;
                              final isActivePoster = index == activeFeedPage;
                              final keepRichPosterPreview =
                                  (index - activeFeedPage).abs() <= 1;
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
                                deferRichPosterPreview: !keepRichPosterPreview,
                                fillViewport: true,
                                playbackEnabled: isActivePoster,
                                enablePoliticalProtocolOverlay:
                                    selectedCategory.slug ==
                                        _politicalCategorySlug ||
                                    _partyIdFromCategorySlug(
                                          selectedCategory.slug,
                                        ) !=
                                        null,
                                showPartyLogoInNameChip:
                                    _partyIdFromCategorySlug(
                                      selectedCategory.slug,
                                    ) !=
                                    null,
                                politicalProtocolPhotoScopeKey: _normalizeTag(
                                  selectedCategory.slug,
                                ),
                                partyLogoOverridesByPartyId:
                                    _partyLogoOverridesByPartyId,
                                politicalParties: _politicalParties,
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
                                onPreviewTap: () =>
                                    _openFullScreenPosterGallery(
                                      feedIndex: index,
                                      feedEntries: feedEntries,
                                      selectedCategory: selectedCategory,
                                      language: language,
                                    ),
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
          if (_activeFullscreenPopupBanner != null &&
              !_fullscreenPopupDismissed)
            _HomeFullscreenPopupBanner(
              banner: _activeFullscreenPopupBanner!,
              onClose: _dismissFullscreenPopupBanner,
              onViewed: _recordFullscreenPopupBannerView,
            ),
        ],
      ),
    );
  }
}

class _HomeFullscreenPopupBanner extends StatefulWidget {
  const _HomeFullscreenPopupBanner({
    required this.banner,
    required this.onClose,
    required this.onViewed,
  });

  final AppHomeBanner banner;
  final VoidCallback onClose;
  final ValueChanged<String> onViewed;

  @override
  State<_HomeFullscreenPopupBanner> createState() =>
      _HomeFullscreenPopupBannerState();
}

class _HomeFullscreenPopupBannerState extends State<_HomeFullscreenPopupBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    widget.onViewed(widget.banner.id);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _HomeFullscreenPopupBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.id != widget.banner.id) {
      widget.onViewed(widget.banner.id);
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    final imageUrl = widget.banner.imageUrl.trim();
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.82),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1080 / 1920,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheManager: PosterNetworkImageCache.instance,
                          maxWidthDiskCache:
                              PosterNetworkImageLimits.diskFeedMaxWidth,
                          maxHeightDiskCache:
                              PosterNetworkImageLimits.diskFeedMaxHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          placeholder: (_, _) => const _ImageLoadingState(),
                          errorWidget: (_, _, _) => const _ImageErrorState(
                            compact: true,
                            title: 'Banner unavailable',
                            subtitle: 'Please try again shortly.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: math.max(8, safePadding.top * 0.25),
                right: 12,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
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
          telugu: 'రిఫరల్ కోడ్‌ను నమోదు చేయండి',
          english: 'Enter referral code',
          hindi: 'रेफ़रल कोड दर्ज करें',
          tamil: 'பரிந்துரை குறியீட்டை உள்ளிடவும்',
          kannada: 'ರೆಫರಲ್ ಕೋಡ್ ನಮೂದಿಸಿ',
          malayalam: 'റഫറൽ കോഡ് നൽകുക',
          marathi: 'रेफरल कोड प्रविष्ट करा',
          gujarati: 'રેફરલ કોડ દાખલ કરો',
          bengali: 'রেফারেল কোড লিখুন',
          punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ ਦਾਖਲ ਕਰੋ',
          odia: 'ରେଫରାଲ୍ କୋଡ୍ ପ୍ରବେଶ କରନ୍ତୁ',
          assamese: 'ৰেফাৰেল কোড দিয়ক',
          konkani: 'रेफरल कोड घालात',
          nepali: 'रेफरल कोड प्रविष्ट गर्नुहोस्',
          meitei: 'রিফরল কোদ ইবীয়ু',
          mizo: 'Referral code chhu rawh',
          kashmiri: 'ریفَرل کوڈ دَرٕج کٔرِو',
          ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས་བཅུག',
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
                telugu: 'రిఫరల్ కోడ్ వర్తించలేదు',
                english: 'Referral code could not be applied',
                hindi: 'रेफ़रल कोड लागू नहीं किया जा सका',
                tamil: 'பரிந்துரை குறியீட்டைப் பயன்படுத்த முடியவில்லை',
                kannada: 'ರೆಫರಲ್ ಕೋಡ್ ಅನ್ವಯಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ',
                malayalam: 'റഫറൽ കോഡ് പ്രയോഗിക്കാനായില്ല',
                marathi: 'रेफरल कोड लागू केला जाऊ शकला नाही',
                gujarati: 'રેફરલ કોડ લાગુ કરી શકાયો નથી',
                bengali: 'রেফারেল কোড প্রয়োগ করা যায়নি',
                punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ ਲਾਗੂ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਿਆ',
                odia: 'ରେଫରାଲ୍ କୋଡ୍ ଲାଗୁ ହୋଇପାରିଲା ନାହିଁ',
                assamese: 'ৰেফাৰেল কোড প্ৰয়োগ কৰিব পৰা নগ’ল',
                konkani: 'रेफरल कोड लागू करूंक जालो ना',
                nepali: 'रेफरल कोड लागू गर्न सकिएन',
                meitei: 'রিফরল কোদ চৎনহনবা ঙমদে',
                mizo: 'Referral code hman theih a ni lo',
                kashmiri: 'ریفَرل کوڈ ہیٚکہ نہٕ لاگوٗ گژھِتھ',
                ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས་ལག་ལེན་བསྟར་མ་ཐུབ།',
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
          telugu: 'రిఫరల్ కోడ్ దరఖాస్తు విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'Referral code apply failed. Please try again.',
          hindi: 'रेफ़रल कोड लागू करना विफल रहा। कृपया पुन: प्रयास करें।',
          tamil:
              'பரிந்துரை குறியீட்டைப் பயன்படுத்துவது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
          kannada:
              'ರೆಫರಲ್ ಕೋಡ್ ಅನ್ವಯಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam:
              'റഫറൽ കോഡ് പ്രയോഗിക്കുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi:
              'रेफरल कोड लागू करणे अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'રેફરલ કોડ લાગુ કરવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali:
              'রেফারেল কোড প্রয়োগ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi:
              'ਰੈਫ਼ਰਲ ਕੋਡ ਲਾਗੂ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ରେଫରାଲ୍ କୋଡ୍ ପ୍ରୟୋଗ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese:
              'ৰেফাৰেল কোড প্ৰয়োগ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'रेफरल कोड लागू जावंक ना. उपकार करून परत यत्न करा.',
          nepali: 'रेफरल कोड लागू गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'রিফরল কোদ চৎনহনবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
          mizo:
              'Referral code hman a hlawhchham. Khawngaihin ti nawn leh rawh.',
          kashmiri:
              'ریفَرل کوڈ لاگوٗ گژھنس منٛز ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
          ladakhi:
              'ངོ་སྤྲོད་ཨང་གྲངས་ལག་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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
                        hindi: 'रेफ़रल कोड',
                        tamil: 'பரிந்துரை குறியீடு',
                        kannada: 'ರೆಫರಲ್ ಕೋಡ್',
                        malayalam: 'റഫറൽ കോഡ്',
                        marathi: 'रेफरल कोड',
                        gujarati: 'રેફરલ કોડ',
                        bengali: 'রেফারেল কোড',
                        punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ',
                        odia: 'ରେଫରାଲ୍ କୋଡ୍',
                        assamese: 'ৰেফাৰেল কোড',
                        konkani: 'रेफरल कोड',
                        nepali: 'रेफरल कोड',
                        meitei: 'রিফরল কোদ',
                        mizo: 'Referral code',
                        kashmiri: 'ریفَرل کوڈ',
                        ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས།',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.localized(
                        telugu: 'మీ వద్ద రిఫరల్ కోడ్ ఉంటే నమోదు చేయండి.',
                        english: 'Enter a referral code if you have one.',
                        hindi: 'यदि आपके पास रेफ़रल कोड है तो दर्ज करें।',
                        tamil:
                            'உங்களிடம் பரிந்துரை குறியீடு இருந்தால் உள்ளிடவும்.',
                        kannada: 'ನಿಮ್ಮ ಬಳಿ ರೆಫರಲ್ ಕೋಡ್ ಇದ್ದರೆ ನಮೂದಿಸಿ.',
                        malayalam:
                            'നിങ്ങളുടെ പക്കൽ റഫറൽ കോഡ് ഉണ്ടെങ്കിൽ നൽകുക.',
                        marathi: 'तुमच्याकडे असल्यास रेफरल कोड प्रविष्ट करा.',
                        gujarati: 'જો તમારી પાસે રેફરલ કોડ હોય તો દાખલ કરો.',
                        bengali: 'আপনার কাছে রেফারেল কোড থাকলে তা লিখুন।',
                        punjabi: 'ਜੇਕਰ ਤੁਹਾਡੇ ਕੋਲ ਰੈਫ਼ਰਲ ਕੋਡ ਹੈ ਤਾਂ ਦਾਖਲ ਕਰੋ।',
                        odia:
                            'ଯଦି ଆପଣଙ୍କ ପାଖରେ ରେଫରାଲ୍ କୋଡ୍ ଅଛି ତେବେ ପ୍ରବେଶ କରନ୍ତୁ।',
                        assamese:
                            'যদি আপোনাৰ হাতত ৰেফাৰেল কোড আছে তেন্তে দিয়ক।',
                        konkani: 'तुमच्या कडेन रेफरल कोड आसल्यार घालात.',
                        nepali:
                            'यदि तपाईंसँग रेफरल कोड छ भने प्रविष्ट गर्नुहोस्।',
                        meitei: 'নহাক্কীদা রিফরল কোদ লৈরবদি ইবীয়ু।',
                        mizo: 'Referral code i neih chuan chhu rawh.',
                        kashmiri:
                            'اگر تُہؠ نِش ریفَرل کوڈ آسہِ تیٚلہِ دَرٕج کٔرِو۔',
                        ladakhi: 'ཁྱེད་ལ་ངོ་སྤྲོད་ཨང་གྲངས་ཡོད་ན་འདིར་བཅུག',
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
                          hindi: 'रेफ़रल कोड',
                          tamil: 'பரிந்துரை குறியீடு',
                          kannada: 'ರೆಫರಲ್ ಕೋಡ್',
                          malayalam: 'റഫറൽ കോഡ്',
                          marathi: 'रेफरल कोड',
                          gujarati: 'રેફરલ કોડ',
                          bengali: 'রেফারেল কোড',
                          punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ',
                          odia: 'ରେଫରାଲ୍ କୋଡ୍',
                          assamese: 'ৰেফাৰেল কোড',
                          konkani: 'रेफरल कोड',
                          nepali: 'रेफरल कोड',
                          meitei: 'রিফরল কোদ',
                          mizo: 'Referral code',
                          kashmiri: 'ریفَرل کوڈ',
                          ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས།',
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
                          telugu: 'నిబంధనలు మరియు షరతులను చూడండి',
                          english: 'View Terms & Conditions',
                          hindi: 'नियम और शर्तें देखें',
                          tamil: 'விதிமுறைகள் மற்றும் நிபந்தனைகளைக் காண்க',
                          kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
                          malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും കാണുക',
                          marathi: 'अटी आणि शर्ती पहा',
                          gujarati: 'નિયમો અને શરતો જુઓ',
                          bengali: 'শর্তাবলী দেখুন',
                          punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ ਦੇਖੋ',
                          odia: 'ନିୟମ ଓ ସର୍ତ୍ତାବଳୀ ଦେଖନ୍ତୁ',
                          assamese: 'নিয়ম আৰু চৰ্তসমূহ চাওক',
                          konkani: 'अटी आनी शर्ती पळयात',
                          nepali: 'नियम तथा सर्तहरू हेर्नुहोस्',
                          meitei: 'নিয়ম অমসুং চৎন-পথাপশিং য়েংবীয়ু',
                          mizo: 'Terms & Conditions en rawh',
                          kashmiri: 'شرائط تہٕ ضوابط وُچھِو',
                          ladakhi: 'ཆ་རྐྱེན་དང་སྒྲིག་གཞི་ལ་ལྟོས།',
                        ),
                      ),
                    ),
                    PrimaryButton(
                      label: strings.localized(
                        telugu: 'వర్తింపజేయి',
                        english: 'Apply',
                        hindi: 'लागू करें',
                        tamil: 'பயன்படுத்து',
                        kannada: 'ಅನ್ವಯಿಸಿ',
                        malayalam: 'ബാധകമാക്കുക',
                        marathi: 'लागू करा',
                        gujarati: 'લાગુ કરો',
                        bengali: 'প্রয়োগ করুন',
                        punjabi: 'ਲਾਗੂ ਕਰੋ',
                        odia: 'ପ୍ରୟୋଗ କରନ୍ତୁ',
                        assamese: 'প্ৰয়োগ কৰক',
                        konkani: 'लागू करा',
                        nepali: 'लागू गर्नुहोस्',
                        meitei: 'চৎনহনবীয়ু',
                        mizo: 'Hman rawh',
                        kashmiri: 'لاگوٗ کٔرِو',
                        ladakhi: 'ལག་ལེན་བསྟར།',
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
                          telugu: 'దాటవేయి',
                          english: 'Skip',
                          hindi: 'छोड़ें',
                          tamil: 'தவிர்',
                          kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
                          malayalam: 'ഒഴിവാക്കുക',
                          marathi: 'वगळा',
                          gujarati: 'છોડો',
                          bengali: 'এড়িয়ে যান',
                          punjabi: 'ਛੱਡੋ',
                          odia: 'ଛାଡ଼ନ୍ତୁ',
                          assamese: 'এৰক',
                          konkani: 'सोडून दियात',
                          nepali: 'छोड्नुहोस्',
                          meitei: 'থাংদোইথোকউ',
                          mizo: 'Kalsan rawh',
                          kashmiri: 'ترک کٔرِو',
                          ladakhi: 'མཆོང་།',
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onHeaderTap,
    required this.onProfileTap,
    required this.viewerPosterProfile,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.compact,
  });

  final VoidCallback onHeaderTap;
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
  final List<_HomePromoSlide> slides;
  final ValueChanged<String> onTap;

  @override
  State<_HomeInlinePromoCard> createState() => _HomeInlinePromoCardState();
}

class _HomeInlinePromoCardState extends State<_HomeInlinePromoCard> {
  late final PageController _pageController = PageController(
    viewportFraction: 1,
  );
  late final List<_HomePromoSlide> _slides = widget.slides
      .where((slide) => slide.imageUrl.trim().isNotEmpty)
      .take(6)
      .toList(growable: false);
  Timer? _autoScrollTimer;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients || _slides.length <= 1) {
        return;
      }
      final nextPage = (_pageIndex + 1) % _slides.length;
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

  void _openCurrentSlideTarget() {
    final ctaTarget =
        _slides.isEmpty || _pageIndex < 0 || _pageIndex >= _slides.length
        ? ''
        : _slides[_pageIndex].ctaTarget;
    widget.onTap(ctaTarget);
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
      _HomePromoCardType.featured => const Color(0xFF7C3AED),
      _HomePromoCardType.subscribe => const Color(0xFF4123C7),
      _HomePromoCardType.renewalReminder => const Color(0xFFB45309),
      _HomePromoCardType.update => const Color(0xFF0F766E),
      _HomePromoCardType.rate => const Color(0xFFD97706),
    };
    final isPlayStoreCard =
        widget.data.type == _HomePromoCardType.update ||
        widget.data.type == _HomePromoCardType.rate;
    final accentIcon = switch (widget.data.type) {
      _HomePromoCardType.featured => Icons.auto_awesome_rounded,
      _HomePromoCardType.subscribe => Icons.workspace_premium_rounded,
      _HomePromoCardType.renewalReminder => Icons.notifications_active_rounded,
      _HomePromoCardType.update || _HomePromoCardType.rate => null,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCurrentSlideTarget,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  child: SizedBox(
                    height: 118,
                    child: _slides.isEmpty
                        ? const ColoredBox(color: Color(0xFFF8FAFC))
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _slides.length,
                            onPageChanged: (index) => _pageIndex = index,
                            itemBuilder: (context, index) => Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CachedNetworkImage(
                                  imageUrl: _slides[index].imageUrl,
                                  cacheManager:
                                      PosterNetworkImageCache.instance,
                                  maxWidthDiskCache:
                                      PosterNetworkImageLimits.diskFeedMaxWidth,
                                  maxHeightDiskCache: PosterNetworkImageLimits
                                      .diskFeedMaxHeight,
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
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? Text(
                                userName.isEmpty ? 'U' : userName[0],
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 11),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (contact.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 5),
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
                                        fontSize: 12,
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
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
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
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _openCurrentSlideTarget,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
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
                            if (widget.data.type ==
                                _HomePromoCardType.subscribe)
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
                                fontSize: 15,
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
  const _BannerSlideData({required this.id, required this.imageUrl});

  final String id;
  final String imageUrl;
}

class _HomePinnedFeedControls extends StatelessWidget {
  const _HomePinnedFeedControls({
    required this.categories,
    required this.activeCategorySlug,
    required this.scrollController,
    required this.onCategoryTap,
    required this.banners,
    required this.onBannerViewed,
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
  final ValueChanged<String> onBannerViewed;
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
            RepaintBoundary(
              child: _HomeHeroBanner(
                banners: banners,
                onBannerViewed: onBannerViewed,
              ),
            ),
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
  const _HomeHeroBanner({required this.banners, required this.onBannerViewed});

  final List<AppHomeBanner> banners;
  final ValueChanged<String> onBannerViewed;

  @override
  State<_HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<_HomeHeroBanner> {
  static const double _bannerAspectRatio = 1080 / 190;
  late final PageController _pageController = PageController();
  Timer? _autoSwipeTimer;
  int _currentPage = 0;

  List<_BannerSlideData> get _slides => widget.banners
      .map(
        (banner) => _BannerSlideData(id: banner.id, imageUrl: banner.imageUrl),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _recordCurrentSlideView();
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
  void didUpdateWidget(covariant _HomeHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length ||
        !_sameBannerIds(widget.banners, oldWidget.banners)) {
      if (_currentPage >= widget.banners.length) {
        _currentPage = 0;
      }
      _recordCurrentSlideView();
    }
  }

  bool _sameBannerIds(List<AppHomeBanner> left, List<AppHomeBanner> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index].id != right[index].id) {
        return false;
      }
    }
    return true;
  }

  void _recordCurrentSlideView() {
    final slides = _slides;
    if (slides.isEmpty) {
      return;
    }
    final index = _currentPage.clamp(0, slides.length - 1).toInt();
    widget.onBannerViewed(slides[index].id);
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
          onPageChanged: (index) {
            _currentPage = index;
            _recordCurrentSlideView();
          },
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
                    telugu: 'బ్యానర్ అందుబాటులో లేదు',
                    english: 'Banner unavailable',
                    hindi: 'बैनर उपलब्ध नहीं है',
                    tamil: 'பேனர் கிடைக்கவில்லை',
                    kannada: 'ಬ್ಯಾನರ್ ಲಭ್ಯವಿಲ್ಲ',
                    malayalam: 'ബാനർ ലഭ്യമല്ല',
                    marathi: 'बॅनर उपलब्ध नाही',
                    gujarati: 'બૅનર ઉપલબ્ધ નથી',
                    bengali: 'ব্যানার উপলব্ধ নয়',
                    punjabi: 'ਬੈਨਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                    odia: 'ବ୍ୟାନର୍ ଉପଲବ୍ଧ ନାହିଁ',
                    assamese: 'বেনাৰ উপলব্ধ নহয়',
                    konkani: 'बॅनर उपलब्ध ना',
                    nepali: 'ब्यानर उपलब्ध छैन',
                    meitei: 'বেনর ফংদে',
                    mizo: 'Banner a awm lo',
                    kashmiri: 'بینر چھُنہٕ دستیاب',
                    ladakhi: 'བྱང་བུ་མི་འདུག',
                  ),
                  subtitle: context.strings.localized(
                    telugu: 'దయచేసి కాసేపటి తర్వాత మళ్లీ ప్రయత్నించండి.',
                    english: 'Please try again shortly.',
                    hindi: 'कृपया कुछ देर बाद पुनः प्रयास करें।',
                    tamil: 'சிறிது நேரத்தில் மீண்டும் முயற்சிக்கவும்.',
                    kannada: 'ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                    malayalam: 'ദയവായി കുറച്ച് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
                    marathi: 'कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.',
                    gujarati: 'કૃપા કરીને થોડા સમય પછી ફરી પ્રયાસ કરો.',
                    bengali: 'অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।',
                    punjabi: 'ਕਿਰਪਾ ਕਰਕੇ ਥੋੜ੍ਹੀ ਦੇਰ ਬਾਅਦ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                    odia: 'ଦୟାକରି କିଛି ସମୟ ପରେ ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
                    assamese: 'অনুগ্ৰহ কৰি অলপ পিছত পুনৰ চেষ্টা কৰক।',
                    konkani: 'उपकार करून थोड्या वेळान परत यत्न करा.',
                    nepali: 'कृपया केही समयपछि पुन: प्रयास गर्नुहोस्।',
                    meitei: 'চানবীদুना মতম খরা লৈরগা অমুক হন্না হোৎনবীয়ু।',
                    mizo: 'Khawngaihin nakin deuhvah ti nawn leh rawh.',
                    kashmiri:
                        'مہر Ships کٔرِتھ کیٚنٛہہ کال پتہٕ دُوبارٕ کوٗشِش کٔرِو۔',
                    ladakhi:
                        'སྐུ་མཁྱེན་དུས་ཚོད་ཐུང་ངུ་ཞིག་གི་རྗེས་སུ་ཡང་བསྐྱར་འབད་པ་གནང་།',
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
        'పోస్టర్లను షేర్ చేయడానికి లేదా డౌన్‌లోడ్ చేయడానికి సబ్‌స్క్రిప్షన్‌ను యాక్టివేట్ చేయండి.',
    english: 'Activate subscription to share or download posters.',
    hindi: 'पोस्टर शेयर या डाउनलोड करने के लिए सदस्यता सक्रिय करें।',
    tamil: 'போஸ்டர்களைப் பகிர அல்லது பதிவிறக்க சந்தாவைச் செயல்படுத்தவும்.',
    kannada:
        'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳಲು ಅಥವಾ ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಚಂದಾದಾರಿಕೆಯನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ.',
    malayalam:
        'പോസ്റ്ററുകൾ പങ്കിടാനോ ഡൗൺലോഡ് ചെയ്യാനോ സബ്‌സ്‌ക്രിപ്ഷൻ സജീവമാക്കുക.',
    marathi: 'पोस्टर्स शेअर किंवा डाउनलोड करण्यासाठी सदस्यता सक्रिय करा.',
    gujarati: 'પોસ્ટર્સ શેર અથવા ડાઉનલોડ કરવા માટે સબ્સ્ક્રિપ્શન સક્રિય કરો.',
    bengali: 'পোস্টার শেয়ার বা ডাউনলোড করতে সাবস্ক্রিপশন সক্রিয় করুন।',
    punjabi: 'ਪੋਸਟਰ ਸਾਂਝੇ ਕਰਨ ਜਾਂ ਡਾਊਨਲੋਡ ਕਰਨ ਲਈ ਗਾਹਕੀ ਨੂੰ ਸਰਗਰਮ ਕਰੋ।',
    odia: 'ପୋଷ୍ଟର ସେୟାର କିମ୍ବା ଡାଉନଲୋଡ୍ କରିବାକୁ ସବସ୍କ୍ରିପସନ୍ ସକ୍ରିୟ କରନ୍ତୁ।',
    assamese: 'পোষ্টাৰ শ্বেয়াৰ বা ডাউনলোড কৰিবলৈ চাবস্ক্ৰিপচন সক্ৰিয় কৰক।',
    konkani: 'पोस्टरां वांटूंक वा डाऊनलोड करूंक वर्गणी सक्रीय करात.',
    nepali: 'पोस्टरहरू सेयर वा डाउनलोड गर्न सदस्यता सक्रिय गर्नुहोस्।',
    meitei: 'পোস্তরশিং শিয়র নত্রগা দাউনলোদ তৌনবগীদমক সবস্ক্রিপসন সনা তৌবীয়ু।',
    mizo: 'Poster share emaw download turin subscription ti nung rawh.',
    kashmiri: 'پوسٹر شیئر یا ڈاؤنلوڈ کرن خٲطرٕ کٔرِو سبسکرپشن چالوٗ۔',
    ladakhi: 'པོ་སི་ཊར་བགོ་འགྲེམས་སམ་ཕབ་ལེན་ཆེད་དུ་མངགས་ཉོ་ནུས་ལྡན་བཟོས།',
  );
}

// ignore: unused_element
String _subscriptionDialogTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ అవసరం',
    english: 'Subscription Required',
    hindi: 'सदस्यता आवश्यक है',
    tamil: 'சந்தா தேவை',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಅಗತ್ಯವಿದೆ',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ ആവശ്യമാണ്',
    marathi: 'सदस्यता आवश्यक आहे',
    gujarati: 'સબ્સ્ક્રિપ્શન જરૂરી છે',
    bengali: 'সাবস্ক্রিপশন প্রয়োজন',
    punjabi: 'ਗਾਹਕੀ ਲੋੜੀਂਦੀ ਹੈ',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ଆବଶ୍ୟକ',
    assamese: 'চাবস্ক্ৰিপচন প্ৰয়োজন',
    konkani: 'वर्गणी जाय',
    nepali: 'सदस्यता आवश्यक छ',
    meitei: 'সবস্ক্রিপসন মথৌ তাই',
    mizo: 'Subscription a ngai',
    kashmiri: 'سبسکرپشن ضۆروٗری',
    ladakhi: 'མངགས་ཉོ་དགོས།',
  );
}

// ignore: unused_element
String _subscriptionTrialTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '3-day trial plan',
    hindi: '3-दिवसीय परीक्षण योजना',
    tamil: '3 நாள் சோதனைத் திட்டம்',
    kannada: '3 ದಿನಗಳ ಪ್ರಾಯೋಗಿಕ ಯೋಜನೆ',
    malayalam: '3 ദിവസത്തെ ട്രയൽ പ്ലാൻ',
    marathi: '3 दिवसांचा ट्रायल प्लॅन',
    gujarati: '3-દિવસનો ટ્રાયલ પ્લાન',
    bengali: '৩ দিনের ট্রায়াল প্ল্যান',
    punjabi: '3 ਦਿਨਾਂ ਦਾ ਟਰਾਇਲ ਪਲਾਨ',
    odia: '୩ ଦିନର ଟ୍ରାଏଲ୍ ପ୍ଲାନ୍',
    assamese: '৩ দিনীয়া ট্ৰায়েল প্লেন',
    konkani: '3 दिसांचो ट्रायल प्लॅन',
    nepali: '३ दिने परीक्षण योजना',
    meitei: 'নুমিৎ 3 নিগী ত্রায়ল প্লান',
    mizo: 'Ni 3 chhung trial plan',
    kashmiri: '3 دوہُن ٹرائل پلان',
    ladakhi: 'ཉིན་ ༣ ཚོད་ལྟའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionTrialValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay}',
    english:
        '${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days',
    hindi:
        '${SubscriptionPlanConfig.trialDays} दिनों के लिए ${SubscriptionPlanConfig.trialPriceDisplay}',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாட்களுக்கு ${SubscriptionPlanConfig.trialPriceDisplay}',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳಿಗೆ ${SubscriptionPlanConfig.trialPriceDisplay}',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തേക്ക് ${SubscriptionPlanConfig.trialPriceDisplay}',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांसाठी ${SubscriptionPlanConfig.trialPriceDisplay}',
    gujarati:
        '${SubscriptionPlanConfig.trialDays} દિવસ માટે ${SubscriptionPlanConfig.trialPriceDisplay}',
    bengali:
        '${SubscriptionPlanConfig.trialDays} দিনের জন্য ${SubscriptionPlanConfig.trialPriceDisplay}',
    punjabi:
        '${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਲਈ ${SubscriptionPlanConfig.trialPriceDisplay}',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନ ପାଇଁ ${SubscriptionPlanConfig.trialPriceDisplay}',
    assamese:
        '${SubscriptionPlanConfig.trialDays} দিনৰ বাবে ${SubscriptionPlanConfig.trialPriceDisplay}',
    konkani:
        '${SubscriptionPlanConfig.trialDays} दिसां खातीर ${SubscriptionPlanConfig.trialPriceDisplay}',
    nepali:
        '${SubscriptionPlanConfig.trialDays} दिनको लागि ${SubscriptionPlanConfig.trialPriceDisplay}',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগীদমক ${SubscriptionPlanConfig.trialPriceDisplay}',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} atan ${SubscriptionPlanConfig.trialPriceDisplay}',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن خٲطرٕ ${SubscriptionPlanConfig.trialPriceDisplay}',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཆེད་དུ ${SubscriptionPlanConfig.trialPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionMonthlyTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలవారీ ప్లాన్',
    english: 'Monthly plan',
    hindi: 'मासिक योजना',
    tamil: 'மாதாந்திர திட்டம்',
    kannada: 'ಮಾಸಿಕ ಯೋಜನೆ',
    malayalam: 'പ്രതിമാസ പ്ലാൻ',
    marathi: 'मासिक प्लॅन',
    gujarati: 'માસિક પ્લાન',
    bengali: 'মাসিক প্ল্যান',
    punjabi: 'ਮਹੀਨਾਵਾਰ ਪਲਾਨ',
    odia: 'ମାସିକ ପ୍ଲାନ୍',
    assamese: 'মাহেকীয়া প্লেন',
    konkani: 'म्हयन्याचो प्लॅन',
    nepali: 'मासिक योजना',
    meitei: 'থাগী প্লান',
    mizo: 'Thla tina plan',
    kashmiri: 'ماہانہ پلان',
    ladakhi: 'ཟླ་རེའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionMonthlyValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    english: '${SubscriptionPlanConfig.monthlyPriceDisplay} per month',
    hindi: '${SubscriptionPlanConfig.monthlyPriceDisplay} प्रति माह',
    tamil: 'மாதத்திற்கு ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kannada: 'ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    malayalam: 'പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    marathi: 'दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    gujarati: 'દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    bengali: 'প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    punjabi: 'ਪ੍ਰਤੀ ਮਹੀਨਾ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    odia: 'ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    assamese: 'প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    konkani: 'दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    nepali: 'प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    meitei: 'থা খুদিংগী ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    mizo: 'Thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kashmiri: 'پر ماہ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    ladakhi: 'ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionRenewalCopyLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజుల ట్రయల్ తర్వాత, రద్దు చేయకపోతే నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} ఆటో-రీన్యూ అవుతుంది. ${SubscriptionPlanConfig.trialDays} రోజులలోపు రద్దు చేస్తే, నెలవారీ ఛార్జీ వర్తించదు. ప్రస్తుత ప్లాన్ ముగిసే వరకు ప్రయోజనాలు కొనసాగుతాయి.',
    english:
        'After the ${SubscriptionPlanConfig.trialDays}-day trial, it auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay}/month unless cancelled. If cancelled within ${SubscriptionPlanConfig.trialDays} days, the monthly charge does not apply. Benefits continue until the current plan expires.',
    hindi:
        '${SubscriptionPlanConfig.trialDays}-दिनों के परीक्षण के बाद, रद्द न करने पर यह ${SubscriptionPlanConfig.monthlyPriceDisplay}/माह पर स्वतः नवीनीकृत होगा। यदि ${SubscriptionPlanConfig.trialDays} दिनों में रद्द किया जाता है, तो मासिक शुल्क लागू नहीं होगा। लाभ मौजूदा योजना समाप्त होने तक जारी रहेंगे।',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாள் சோதனைக்குப் பிறகு, ரத்து செய்யாவிட்டால் மாதம் ${SubscriptionPlanConfig.monthlyPriceDisplay}-க்கு தானாகப் புதுப்பிக்கப்படும். ${SubscriptionPlanConfig.trialDays} நாட்களுக்குள் ரத்து செய்தால் மாதாந்திரக் கட்டணம் பொருந்தாது. நடப்புத் திட்டம் முடியும் வரை நன்மைகள் தொடரும்.',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳ ಪ್ರಯೋಗದ ನಂತರ, ರದ್ದುಗೊಳಿಸದಿದ್ದರೆ ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay} ಸ್ವಯಂ-ನವೀಕರಣಗೊಳ್ಳುತ್ತದೆ. ${SubscriptionPlanConfig.trialDays} ದಿನಗಳಲ್ಲಿ ರದ್ದುಗೊಳಿಸಿದರೆ ಮಾಸಿಕ ಶುಲ್ಕ ಅನ್ವಯಿಸುವುದಿಲ್ಲ. ಪ್ರಸ್ತುತ ಪ್ಲಾನ್ ಮುಗಿಯುವವರೆಗೆ ಪ್ರಯೋಜನಗಳು ಮುಂದುವರಿಯುತ್ತವೆ.',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തെ ട്രയലിന് ശേഷം, റദ്ദാക്കിയില്ലെങ്കിൽ പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay} നിരക്കിൽ സ്വയമേവ പുതുക്കും. ${SubscriptionPlanConfig.trialDays} ദിവസത്തിനുള്ളിൽ റദ്ദാക്കിയാൽ പ്രതിമാസ നിരക്ക് ബാധകമല്ല. നിലവിലെ പ്ലാൻ തീരുന്നതുവരെ ആനുകൂല്യങ്ങൾ തുടരും.',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांच्या चाचणीनंतर, रद्द न केल्यास दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay} वर ऑटो-रिन्यू होईल. ${SubscriptionPlanConfig.trialDays} दिवसांच्या आत रद्द केल्यास, मासिक शुल्क आकारले जाणार नाही. चालू प्लॅन संपेपर्यंत फायदे सुरू राहतील.',
    gujarati:
        '${SubscriptionPlanConfig.trialDays}-દિવસની અજમાયશ પછી, રદ ન કરવામાં આવે તો તે દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay} પર ઑટો-રિન્યૂ થાય છે. જો ${SubscriptionPlanConfig.trialDays} દિવસમાં રદ કરવામાં આવે, તો માસિક શુલ્ક લાગુ પડતું નથી. વર્તમાન પ્લાન સમાપ્ત થાય ત્યાં સુધી લાભો ચાલુ રહે છે.',
    bengali:
        '${SubscriptionPlanConfig.trialDays}-দিনের ট্রায়ালের পরে, বাতিল না করা হলে প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay} হারে স্বতঃ-নবায়ন হবে। ${SubscriptionPlanConfig.trialDays} দিনের মধ্যে বাতিল করলে মাসিক চার্জ প্রযোজ্য হবে না। বর্তমান প্ল্যানের মেয়াদ শেষ না হওয়া পর্যন্ত সুবিধাগুলি অব্যাহত থাকবে।',
    punjabi:
        '${SubscriptionPlanConfig.trialDays}-ਦਿਨਾਂ ਦੇ ਟਰਾਇਲ ਤੋਂ ਬਾਅਦ, ਰੱਦ ਨਾ ਕਰਨ \'ਤੇ ਇਹ ${SubscriptionPlanConfig.monthlyPriceDisplay}/ਮਹੀਨਾ \'ਤੇ ਸਵੈ-ਨਵਿਆਇਆ ਜਾਵੇਗਾ। ਜੇਕਰ ${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਦੇ ਅੰਦਰ ਰੱਦ ਕੀਤਾ ਜਾਂਦਾ ਹੈ, ਤਾਂ ਮਹੀਨਾਵਾਰ ਖਰਚਾ ਲਾਗੂ ਨਹੀਂ ਹੋਵੇਗਾ। ਲਾਭ ਮੌਜੂਦਾ ਪਲਾਨ ਖਤਮ ਹੋਣ ਤੱਕ ਜਾਰੀ ਰਹਿਣਗੇ।',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନର ଟ୍ରାଏଲ୍ ପରେ, ବାତିଲ୍ ନକଲେ ଏହା ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay} ରେ ସ୍ୱୟଂ-ନବୀକରଣ ହେବ। ${SubscriptionPlanConfig.trialDays} ଦିନ ମଧ୍ୟରେ ବାତିଲ୍ କଲେ ମାସିକ ଶୁଳ୍କ ଲାଗୁ ହେବ ନାହିଁ। ବର୍ତ୍ତମାନର ପ୍ଲାନ୍ ସରିବା ପର୍ଯ୍ୟନ୍ତ ସୁବିଧା ଜାରି ରହିବ।',
    assamese:
        '${SubscriptionPlanConfig.trialDays} দিনীয়া ট্ৰায়েলৰ পিছত, বাতিল নকৰিলে প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay} ত স্বয়ংক্ৰিয়ভাৱে নবীকৰণ হ’ব। ${SubscriptionPlanConfig.trialDays} দিনৰ ভিতৰত বাতিল কৰিলে মাহেকীয়া মাচুল প্ৰযোজ্য নহয়। বৰ্তমানৰ প্লেন শেষ নোহোৱালৈকে সুবিধাসমূহ অব্যাহত থাকিব।',
    konkani:
        '${SubscriptionPlanConfig.trialDays} दिसांच्या चाचणी उपरांत, रद्द करीना जाल्यार दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay} प्रमाण स्वयंचलित नूतनीकरण जातलें. ${SubscriptionPlanConfig.trialDays} दिसां भितर रद्द केल्यार म्हयन्याचो आकार लागू जायना. चालू प्लॅन सोंपमेरेन फायदे चालू उरतले.',
    nepali:
        '${SubscriptionPlanConfig.trialDays}-दिने परीक्षण पछि, रद्द नगरेमा यो प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay} मा स्वतः नवीकरण हुन्छ। यदि ${SubscriptionPlanConfig.trialDays} दिन भित्र रद्द गरियो भने, मासिक शुल्क लाग्दैन। हालको योजना समाप्त नभएसम्म फाइदाहरू जारी रहनेछन्।',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী ত্রায়ল মতুংদা, কেন্সেল তৌদ্রবদি থাদা ${SubscriptionPlanConfig.monthlyPriceDisplay} দা ওতো-রিনিউ তৌগনি। নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী মনুংদা কেন্সেল তৌরবদি থাগী চান্দা লৌরোই। হৌজিক্কী প্লান লোইদ্রিফাওবা কান্নবশিং চত্থগনি।',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} trial hnuah, cancel loh chuan thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}-in auto-renew ang. Ni ${SubscriptionPlanConfig.trialDays} chhunga cancel chuan thla tin charge a kal lo ang. Tun thlenga plan a tawp hma chuan a hlawkna a chhunzawm zel ang.',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن ہُنٛد ٹرائل پتہٕ، کینسل نہٕ کرنہٕ کِس صورتس منٛز گژھِ یہِ خود بخود ${SubscriptionPlanConfig.monthlyPriceDisplay}/ماہس پؠٹھ نویں سرٕ। اگر ${SubscriptionPlanConfig.trialDays} دوہَن منٛز کینسل کٔرِو، تیٚلہِ لاگوٗ گژھِ نہٕ ماہانہ فیس। فایدٕ روزَن موٗجوٗدٕ پلان ختم گژھنَس تام جٲری۔',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཚོད་ལྟའི་རྗེས་སུ། ཕྱིར་འཐེན་མ་བྱས་ན་ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay} རང་བཞིན་གྱིས་གསར་བཟོ་བྱེད། ཉིན་ ${SubscriptionPlanConfig.trialDays} ནང་ཕྱིར་འཐེན་བྱས་ན་ཟླ་རེའི་རིན་པ་མི་ལེན། ད་ལྟའི་འཆར་གཞི་མ་རྫོགས་བར་དུ་ཁེ་ཕན་རྣམས་འཐོབ་རྒྱུ།',
  );
}

// ignore: unused_element
String _subscriptionTermsLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నిబంధనలు',
    english: 'Terms',
    hindi: 'नियम',
    tamil: 'விதிமுறைகள்',
    kannada: 'ನಿಯಮಗಳು',
    malayalam: 'നിബന്ധനകൾ',
    marathi: 'अटी',
    gujarati: 'શરતો',
    bengali: 'শর্তাবলী',
    punjabi: 'ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ',
    assamese: 'চৰ্তাৱলী',
    konkani: 'अटी',
    nepali: 'सर्तहरू',
    meitei: 'চৎন-পথাপশিং',
    mizo: 'Hman dan tur',
    kashmiri: 'شرائط',
    ladakhi: 'ཆ་རྐྱེན།',
  );
}

// ignore: unused_element
String _subscriptionSkipLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'దాటవేయి',
    english: 'Skip',
    hindi: 'छोड़ें',
    tamil: 'தவிர்',
    kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
    malayalam: 'ഒഴിവാക്കുക',
    marathi: 'वगळा',
    gujarati: 'છોડો',
    bengali: 'এড়িয়ে যান',
    punjabi: 'ਛੱਡੋ',
    odia: 'ଛାଡ଼ନ୍ତୁ',
    assamese: 'এৰক',
    konkani: 'सोडून दियात',
    nepali: 'छोड्नुहोस्',
    meitei: 'থাংদোইথোকউ',
    mizo: 'Kalsan rawh',
    kashmiri: 'ترک کٔرِو',
    ladakhi: 'མཆོང་།',
  );
}

// ignore: unused_element
String _subscriptionButtonLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రైబ్',
    english: 'Subscribe',
    hindi: 'सदस्यता लें',
    tamil: 'குழுசேர்',
    kannada: 'ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'സബ്സ്ക്രൈബ് ചെയ്യുക',
    marathi: 'सदस्यता घ्या',
    gujarati: 'સબ્સ્ક્રાઇબ કરો',
    bengali: 'সাবস্ক্রাইব করুন',
    punjabi: 'ਗਾਹਕ ਬਣੋ',
    odia: 'ସବସ୍କ୍ରାଇବ୍ କରନ୍ତୁ',
    assamese: 'চাবস্ক্ৰাইব কৰক',
    konkani: 'वर्गणीदार जायात',
    nepali: 'सदस्यता लिनुहोस्',
    meitei: 'সবস্ক্রাইব তৌবীয়ু',
    mizo: 'Subscribe rawh',
    kashmiri: 'سبسکرائب کٔرِو',
    ladakhi: 'མངགས་ཉོ་བྱོས།',
  );
}

// ignore: unused_element
String _subscriptionPromptCopyCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'పోస్టర్లను షేర్ చేయడానికి లేదా డౌన్‌లోడ్ చేయడానికి సబ్‌స్క్రిప్షన్‌ను యాక్టివేట్ చేయండి.',
    english: 'Activate subscription to share or download posters.',
    hindi: 'पोस्टर शेयर या डाउनलोड करने के लिए सदस्यता सक्रिय करें।',
    tamil: 'போஸ்டர்களைப் பகிர அல்லது பதிவிறக்க சந்தாவைச் செயல்படுத்தவும்.',
    kannada:
        'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳಲು ಅಥವಾ ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಚಂದಾದಾರಿಕೆಯನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ.',
    malayalam:
        'പോസ്റ്ററുകൾ പങ്കിടാനോ ഡൗൺലോഡ് ചെയ്യാനോ സബ്‌സ്‌ക്രിപ്ഷൻ സജീവമാക്കുക.',
    marathi: 'पोस्टर्स शेअर किंवा डाउनलोड करण्यासाठी सदस्यता सक्रिय करा.',
    gujarati: 'પોસ્ટર્સ શેર અથવા ડાઉનલોડ કરવા માટે સબ્સ્ક્રિપ્શન સક્રિય કરો.',
    bengali: 'পোস্টার শেয়ার বা ডাউনলোড করতে সাবস্ক্রিপশন সক্রিয় করুন।',
    punjabi: 'ਪੋਸਟਰ ਸਾਂਝੇ ਕਰਨ ਜਾਂ ਡਾਊਨਲੋਡ ਕਰਨ ਲਈ ਗਾਹਕੀ ਨੂੰ ਸਰਗਰਮ ਕਰੋ।',
    odia: 'ପୋଷ୍ଟର ସେୟାର କିମ୍ବା ଡାଉନଲୋଡ୍ କରିବାକୁ ସବସ୍କ୍ରିପସନ୍ ସକ୍ରିୟ କରନ୍ତୁ।',
    assamese: 'পোষ্টাৰ শ্বেয়াৰ বা ডাউনলোড কৰিবলৈ চাবস্ক্ৰিপচন সক্ৰিয় কৰক।',
    konkani: 'पोस्टरां वांटूंक वा डाऊनलोड करूंक वर्गणी सक्रीय करात.',
    nepali: 'पोस्टरहरू सेयर वा डाउनलोड गर्न सदस्यता सक्रिय गर्नुहोस्।',
    meitei: 'পোস্তরশিং শিয়র নত্রগা দাউনলোদ তৌনবগীদমক সবস্ক্রিপসন সনা তৌবীয়ু।',
    mizo: 'Poster share emaw download turin subscription ti nung rawh.',
    kashmiri: 'پوسٹر شیئر یا ڈاؤنلوڈ کرن خٲطرٕ کٔرِو سبسکرپشن چالوٗ।',
    ladakhi: 'པོ་སི་ཊར་བགོ་འགྲེམས་སམ་ཕབ་ལེན་ཆེད་དུ་མངགས་ཉོ་ནུས་ལྡན་བཟོས།',
  );
}

// ignore: unused_element
String _subscriptionDialogTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ అవసరం',
    english: 'Subscription Required',
    hindi: 'सदस्यता आवश्यक है',
    tamil: 'சந்தா தேவை',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಅಗತ್ಯವಿದೆ',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ ആവശ്യമാണ്',
    marathi: 'सदस्यता आवश्यक आहे',
    gujarati: 'સબ્સ્ક્રિપ્શન જરૂરી છે',
    bengali: 'সাবস্ক্রিপশন প্রয়োজন',
    punjabi: 'ਗਾਹਕੀ ਲੋੜੀਂਦੀ ਹੈ',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ଆବଶ୍ୟକ',
    assamese: 'চাবস্ক্ৰিপচন প্ৰয়োজন',
    konkani: 'वर्गणी जाय',
    nepali: 'सदस्यता आवश्यक छ',
    meitei: 'সবস্ক্রিপসন মথৌ তাই',
    mizo: 'Subscription a ngai',
    kashmiri: 'سبسکرپشن ضۆروٗری',
    ladakhi: 'མངགས་ཉོ་དགོས།',
  );
}

// ignore: unused_element
String _subscriptionTrialTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '3-day trial plan',
    hindi: '3-दिवसीय परीक्षण योजना',
    tamil: '3 நாள் சோதனைத் திட்டம்',
    kannada: '3 ದಿನಗಳ ಪ್ರಾಯೋಗಿಕ ಯೋಜನೆ',
    malayalam: '3 ദിവസത്തെ ട്രയൽ പ്ലാൻ',
    marathi: '3 दिवसांचा ट्रायल प्लॅन',
    gujarati: '3-દિવસનો ટ્રાયલ પ્લાન',
    bengali: '৩ দিনের ট্রায়াল প্ল্যান',
    punjabi: '3 ਦਿਨਾਂ ਦਾ ਟਰਾਇਲ ਪਲਾਨ',
    odia: '୩ ଦିନର ଟ୍ରାଏଲ୍ ପ୍ଲାନ୍',
    assamese: '৩ দিনীয়া ট্ৰায়েল প্লেন',
    konkani: '3 दिसांचो ट्रायल प्लॅन',
    nepali: '३ दिने परीक्षण योजना',
    meitei: 'নুমিৎ 3 নিগী ত্রায়ল প্লান',
    mizo: 'Ni 3 chhung trial plan',
    kashmiri: '3 دوہُن ٹرائل پلان',
    ladakhi: 'ཉིན་ ༣ ཚོད་ལྟའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionTrialValueCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay}',
    english:
        '${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days',
    hindi:
        '${SubscriptionPlanConfig.trialDays} दिनों के लिए ${SubscriptionPlanConfig.trialPriceDisplay}',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாட்களுக்கு ${SubscriptionPlanConfig.trialPriceDisplay}',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳಿಗೆ ${SubscriptionPlanConfig.trialPriceDisplay}',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തേക്ക് ${SubscriptionPlanConfig.trialPriceDisplay}',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांसाठी ${SubscriptionPlanConfig.trialPriceDisplay}',
    gujarati:
        '${SubscriptionPlanConfig.trialDays} દિવસ માટે ${SubscriptionPlanConfig.trialPriceDisplay}',
    bengali:
        '${SubscriptionPlanConfig.trialDays} দিনের জন্য ${SubscriptionPlanConfig.trialPriceDisplay}',
    punjabi:
        '${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਲਈ ${SubscriptionPlanConfig.trialPriceDisplay}',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନ ପାଇଁ ${SubscriptionPlanConfig.trialPriceDisplay}',
    assamese:
        '${SubscriptionPlanConfig.trialDays} দিনৰ বাবে ${SubscriptionPlanConfig.trialPriceDisplay}',
    konkani:
        '${SubscriptionPlanConfig.trialDays} दिसां खातीर ${SubscriptionPlanConfig.trialPriceDisplay}',
    nepali:
        '${SubscriptionPlanConfig.trialDays} दिनको लागि ${SubscriptionPlanConfig.trialPriceDisplay}',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগীদমক ${SubscriptionPlanConfig.trialPriceDisplay}',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} atan ${SubscriptionPlanConfig.trialPriceDisplay}',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن خٲطرٕ ${SubscriptionPlanConfig.trialPriceDisplay}',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཆེད་དུ ${SubscriptionPlanConfig.trialPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionMonthlyTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలవారీ ప్లాన్',
    english: 'Monthly plan',
    hindi: 'मासिक योजना',
    tamil: 'மாதாந்திர திட்டம்',
    kannada: 'ಮಾಸಿಕ ಯೋಜನೆ',
    malayalam: 'പ്രതിമാസ പ്ലാൻ',
    marathi: 'मासिक प्लॅन',
    gujarati: 'માસિક પ્લાન',
    bengali: 'মাসিক প্ল্যান',
    punjabi: 'ਮਹੀਨਾਵਾਰ ਪਲਾਨ',
    odia: 'ମାସିକ ପ୍ଲାନ୍',
    assamese: 'মাহেকীয়া প্লেন',
    konkani: 'म्हयन्याचो प्लॅन',
    nepali: 'मासिक योजना',
    meitei: 'থাগী প্লান',
    mizo: 'Thla tina plan',
    kashmiri: 'ماہانہ پلان',
    ladakhi: 'ཟླ་རེའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionMonthlyValueCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    english: '${SubscriptionPlanConfig.monthlyPriceDisplay} per month',
    hindi: '${SubscriptionPlanConfig.monthlyPriceDisplay} प्रति माह',
    tamil: 'மாதத்திற்கு ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kannada: 'ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    malayalam: 'പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    marathi: 'दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    gujarati: 'દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    bengali: 'প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    punjabi: 'ਪ੍ਰਤੀ ਮਹੀਨਾ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    odia: 'ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    assamese: 'প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    konkani: 'दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    nepali: 'प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    meitei: 'থা খুদিংগী ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    mizo: 'Thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kashmiri: 'پر ماہ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    ladakhi: 'ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionRenewalCopyCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజుల ట్రయల్ తర్వాత, రద్దు చేయకపోతే నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} ఆటో-రీన్యూ అవుతుంది. ${SubscriptionPlanConfig.trialDays} రోజులలోపు రద్దు చేస్తే, నెలవారీ ఛార్జీ వర్తించదు. ప్రస్తుత ప్లాన్ ముగిసే వరకు ప్రయోజనాలు కొనసాగుతాయి.',
    english:
        'After the ${SubscriptionPlanConfig.trialDays}-day trial, it auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay}/month unless cancelled. If cancelled within ${SubscriptionPlanConfig.trialDays} days, the monthly charge does not apply. Benefits continue until the current plan expires.',
    hindi:
        '${SubscriptionPlanConfig.trialDays}-दिनों के परीक्षण के बाद, रद्द न करने पर यह ${SubscriptionPlanConfig.monthlyPriceDisplay}/माह पर स्वतः नवीनीकृत होगा। यदि ${SubscriptionPlanConfig.trialDays} दिनों में रद्द किया जाता है, तो मासिक शुल्क लागू नहीं होगा। लाभ मौजूदा योजना समाप्त होने तक जारी रहेंगे।',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாள் சோதனைக்குப் பிறகு, ரத்து செய்யாவிட்டால் மாதம் ${SubscriptionPlanConfig.monthlyPriceDisplay}-க்கு தானாகப் புதுப்பிக்கப்படும். ${SubscriptionPlanConfig.trialDays} நாட்களுக்குள் ரத்து செய்தால் மாதாந்திரக் கட்டணம் பொருந்தாது. நடப்புத் திட்டம் முடியும் வரை நன்மைகள் தொடரும்.',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳ ಪ್ರಯೋಗದ ನಂತರ, ರದ್ದುಗೊಳಿಸದಿದ್ದರೆ ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay} ಸ್ವಯಂ-ನವೀಕರಣಗೊಳ್ಳುತ್ತದೆ. ${SubscriptionPlanConfig.trialDays} ದಿನಗಳಲ್ಲಿ ರದ್ದುಗೊಳಿಸಿದರೆ ಮಾಸಿಕ ಶುಲ್ಕ ಅನ್ವಯಿಸುವುದಿಲ್ಲ. ಪ್ರಸ್ತುತ ಪ್ಲಾನ್ ಮುಗಿಯುವವರೆಗೆ ಪ್ರಯೋಜನಗಳು ಮುಂದುವರಿಯುತ್ತವೆ.',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തെ ട്രയലിന് ശേഷം, റദ്ദാക്കിയില്ലെങ്കിൽ പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay} നിരക്കിൽ സ്വയമേവ പുതുക്കും. ${SubscriptionPlanConfig.trialDays} ദിവസത്തിനുള്ളിൽ റദ്ദാക്കിയാൽ പ്രതിമാസ നിരക്ക് ബാധകമല്ല. നിലവിലെ പ്ലാൻ തീരുന്നതുവരെ ആനുകൂല്യങ്ങൾ തുടരും.',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांच्या चाचणीनंतर, रद्द न केल्यास दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay} वर ऑटो-रिन्यू होईल. ${SubscriptionPlanConfig.trialDays} दिवसांच्या आत रद्द केल्यास, मासिक शुल्क आकारले जाणार नाही. चालू प्लॅन संपेपर्यंत फायदे सुरू राहतील.',
    gujarati:
        '${SubscriptionPlanConfig.trialDays}-દિવસની અજમાયશ પછી, રદ ન કરવામાં આવે તો તે દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay} પર ઑટો-રિન્યૂ થાય છે. જો ${SubscriptionPlanConfig.trialDays} દિવસમાં રદ કરવામાં આવે, તો માસિક શુલ્ક લાગુ પડતું નથી. વર્તમાન પ્લાન સમાપ્ત થાય ત્યાં સુધી લાભો ચાલુ રહે છે.',
    bengali:
        '${SubscriptionPlanConfig.trialDays}-দিনের ট্রায়ালের পরে, বাতিল না করা হলে প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay} হারে স্বতঃ-নবায়ন হবে। ${SubscriptionPlanConfig.trialDays} দিনের মধ্যে বাতিল করলে মাসিক চার্জ প্রযোজ্য হবে না। বর্তমান প্ল্যানের মেয়াদ শেষ না হওয়া পর্যন্ত সুবিধাগুলি অব্যাহত থাকবে।',
    punjabi:
        '${SubscriptionPlanConfig.trialDays}-ਦਿਨਾਂ ਦੇ ਟਰਾਇਲ ਤੋਂ ਬਾਅਦ, ਰੱਦ ਨਾ ਕਰਨ \'ਤੇ ਇਹ ${SubscriptionPlanConfig.monthlyPriceDisplay}/ਮਹੀਨਾ \'ਤੇ ਸਵੈ-ਨਵਿਆਇਆ ਜਾਵੇਗਾ। ਜੇਕਰ ${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਦੇ ਅੰਦਰ ਰੱਦ ਕੀਤਾ ਜਾਂਦਾ ਹੈ, ਤਾਂ ਮਹੀਨਾਵਾਰ ਖਰਚਾ ਲਾਗੂ ਨਹੀਂ ਹੋਵੇਗਾ। ਲਾਭ ਮੌਜੂਦਾ ਪਲਾਨ ਖਤਮ ਹੋਣ ਤੱਕ ਜਾਰੀ ਰਹਿਣਗੇ।',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନର ଟ୍ରାଏଲ୍ ପରେ, ବାତିଲ୍ ନକଲେ ଏହା ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay} ରେ ସ୍ୱୟଂ-ନବୀକରଣ ହେବ। ${SubscriptionPlanConfig.trialDays} ଦିନ ମଧ୍ୟରେ ବାତିଲ୍ କଲେ ମାସିକ ଶୁଳ୍କ ଲାଗୁ ହେବ ନାହିଁ। ବର୍ତ୍ତମାନର ପ୍ଲାନ୍ ସରିବା ପର୍ଯ୍ୟନ୍ତ ସୁବିଧା ଜାରି ରହିବ।',
    assamese:
        'আপোনাৰ প্লেন শেষ নোহোৱালৈকে সুবিধাসমূহ অব্যাহত থাকিব। ${SubscriptionPlanConfig.trialDays} দিনীয়া ট্ৰায়েলৰ পিছত, বাতিল নকৰিলে প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay} ত স্বয়ংক্ৰিয়ভাৱে নবীকৰণ হ’ব। ${SubscriptionPlanConfig.trialDays} দিনৰ ভিতৰত বাতিল কৰিলে মাহেকীয়া মাচুল প্ৰযোজ্য নহয়।',
    konkani:
        'चालू प्लॅन सोंपमेरेन फायदे चालू उरतले. ${SubscriptionPlanConfig.trialDays} दिसांच्या चाचणी उपरांत, रद्द करीना जाल्यार दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay} प्रमाण स्वयंचलित नूतनीकरण जातलें. ${SubscriptionPlanConfig.trialDays} दिसां भितर रद्द केल्यार म्हयन्याचो आकार लागू जायना.',
    nepali:
        '${SubscriptionPlanConfig.trialDays}-दिने परीक्षण पछि, रद्द नगरेमा यो प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay} मा स्वतः नवीकरण हुन्छ। यदि ${SubscriptionPlanConfig.trialDays} दिन भित्र रद्द गरियो भने, मासिक शुल्क लाग्दैन। हालको योजना समाप्त नभएसम्म फाइदाहरू जारी रहनेछन्।',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী ত্রায়ল মতুংদা, কেন্সেল তৌদ্রবদি থাদা ${SubscriptionPlanConfig.monthlyPriceDisplay} দা ওতো-রিনিউ তৌগনি। নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী মনুংদা কেন্সেল তৌরবদি থাগী চান্দা লৌরোই। হৌজিক্কী প্লান লোইদ্রিফাওবা কান্নবশিং চত্থগনি।',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} trial hnuah, cancel loh chuan thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}-in auto-renew ang. Ni ${SubscriptionPlanConfig.trialDays} chhunga cancel chuan thla tin charge a kal lo ang. Tun thlenga plan a tawp hma chuan a hlawkna a chhunzawm zel ang.',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن ہُنٛد ٹرائل پتہٕ، کینسل نہٕ کرنہٕ کِس صورتس منٛز گژھِ یہِ خود بخود ${SubscriptionPlanConfig.monthlyPriceDisplay}/ماہس پؠٹھ نویں سرٕ۔ اگر ${SubscriptionPlanConfig.trialDays} دوہَن منٛز کینسل کٔرِو، تیٚلہِ لاگوٗ گژھِ نہٕ ماہانہ فیس۔ فایدٕ روزَن موٗجوٗدٕ پلان ختم گژھنَس تام جٲری۔',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཚོད་ལྟའི་རྗེས་སུ། ཕྱིར་འཐེན་མ་བྱས་ན་ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay} རང་བཞིན་གྱིས་གསར་བཟོ་བྱེད། ཉིན་ ${SubscriptionPlanConfig.trialDays} ནང་ཕྱིར་འཐེན་བྱས་ན་ཟླ་རེའི་རིན་པ་མི་ལེན། ད་ལྟའི་འཆར་གཞི་མ་རྫོགས་བར་དུ་ཁེ་ཕན་རྣམས་འཐོབ་རྒྱུ།',
  );
}

// ignore: unused_element
String _subscriptionTermsLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నిబంధనలు',
    english: 'Terms',
    hindi: 'नियम',
    tamil: 'விதிமுறைகள்',
    kannada: 'ನಿಯಮಗಳು',
    malayalam: 'നിബന്ധനകൾ',
    marathi: 'अटी',
    gujarati: 'શરતો',
    bengali: 'শর্তাবলী',
    punjabi: 'ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ',
    assamese: 'চৰ্তাৱলী',
    konkani: 'अटी',
    nepali: 'सर्तहरू',
    meitei: 'চৎন-পথাপশিং',
    mizo: 'Hman dan tur',
    kashmiri: 'شرائط',
    ladakhi: 'ཆ་རྐྱེན།',
  );
}

// ignore: unused_element
String _subscriptionSkipLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'దాటవేయి',
    english: 'Skip',
    hindi: 'छोड़ें',
    tamil: 'தவிர்',
    kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
    malayalam: 'ഒഴിവാക്കുക',
    marathi: 'वगळा',
    gujarati: 'છોડો',
    bengali: 'এড়িয়ে যান',
    punjabi: 'ਛੱਡੋ',
    odia: 'ଛାଡ଼ନ୍ତୁ',
    assamese: 'এৰক',
    konkani: 'सोडून दियात',
    nepali: 'छोड्नुहोस्',
    meitei: 'থাংদোইথোকউ',
    mizo: 'Kalsan rawh',
    kashmiri: 'ترک کٔرِو',
    ladakhi: 'མཆོང་།',
  );
}

// ignore: unused_element
String _subscriptionButtonLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రైబ్',
    english: 'Subscribe',
    hindi: 'सदस्यता लें',
    tamil: 'குழுசேர்',
    kannada: 'ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'സബ്സ്ക്രൈബ് ചെയ്യുക',
    marathi: 'सदस्यता घ्या',
    gujarati: 'સબ્સ્ક્રાઇબ કરો',
    bengali: 'সাবস্ক্রাইব করুন',
    punjabi: 'ਗਾਹਕ ਬਣੋ',
    odia: 'ସବସ୍କ୍ରାଇବ୍ କରନ୍ତୁ',
    assamese: 'চাবস্ক্ৰাইব কৰক',
    konkani: 'वर्गणीदार जायात',
    nepali: 'सदस्यता लिनुहोस्',
    meitei: 'সবস্ক্রাইব তৌবীয়ু',
    mizo: 'Subscribe rawh',
    kashmiri: 'سبسکرائب کٔرِو',
    ladakhi: 'མངགས་ཉོ་བྱོས།',
  );
}

String _subscriptionPromptCopyAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'ÃƒÂ Ã‚Â°Ã‚ÂªÃƒÂ Ã‚Â±Ã¢â‚¬Â¹ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã…Â¸ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã‚Â·ÃƒÂ Ã‚Â±Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â±Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚Â¦ÃƒÂ Ã‚Â°Ã‚Â¾ ÃƒÂ Ã‚Â°Ã‚Â¡ÃƒÂ Ã‚Â±Ã…â€™ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ¢Ã¢â€šÂ¬Ã…â€™ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â±Ã¢â‚¬Â¹ÃƒÂ Ã‚Â°Ã‚Â¡ÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã…Â¡ÃƒÂ Ã‚Â±Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚Â¯ÃƒÂ Ã‚Â°Ã‚Â¡ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â°Ã‚Â¿ÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â°Ã‚Â¿ ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â°Ã‚Â¬ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ¢Ã¢â€šÂ¬Ã…â€™ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â°Ã‚Â¿ÃƒÂ Ã‚Â°Ã‚ÂªÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â·ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã‚Â¯ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã…Â¸ÃƒÂ Ã‚Â°Ã‚Â¿ÃƒÂ Ã‚Â°Ã‚ÂµÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã…Â¡ÃƒÂ Ã‚Â±Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚Â¯ÃƒÂ Ã‚Â°Ã¢â‚¬Å¡ÃƒÂ Ã‚Â°Ã‚Â¡ÃƒÂ Ã‚Â°Ã‚Â¿.',
    english: 'Activate subscription to share or download posters.',
    hindi:
        'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¶ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¡ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Â°ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¯ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¥Ã‚Â¤',
    tamil:
        'ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â¯Ã¢â‚¬Â¹ÃƒÂ Ã‚Â®Ã‚Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â®Ã‚Â°ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚Â³ÃƒÂ Ã‚Â¯Ã‹â€  ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã‚Â° ÃƒÂ Ã‚Â®Ã¢â‚¬Â¦ÃƒÂ Ã‚Â®Ã‚Â²ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â²ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â¯Ã‚Â ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã‚ÂµÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã‚Â±ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â®Ã…Â¡ÃƒÂ Ã‚Â®Ã‚Â¨ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã‚ÂµÃƒÂ Ã‚Â¯Ã‹â€  ÃƒÂ Ã‚Â®Ã¢â‚¬Â¡ÃƒÂ Ã‚Â®Ã‚Â¯ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚ÂµÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â¯Ã‚Â.',
    kannada:
        'ÃƒÂ Ã‚Â²Ã‚ÂªÃƒÂ Ã‚Â³Ã¢â‚¬Â¹ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã…Â¸ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ¢Ã¢â€šÂ¬Ã…â€™ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â²Ã‚Â³ÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â³Ã‚Â ÃƒÂ Ã‚Â²Ã‚Â¹ÃƒÂ Ã‚Â²Ã¢â‚¬Å¡ÃƒÂ Ã‚Â²Ã…Â¡ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â³Ã‚Â ÃƒÂ Ã‚Â²Ã¢â‚¬Â¦ÃƒÂ Ã‚Â²Ã‚Â¥ÃƒÂ Ã‚Â²Ã‚ÂµÃƒÂ Ã‚Â²Ã‚Â¾ ÃƒÂ Ã‚Â²Ã‚Â¡ÃƒÂ Ã‚Â³Ã…â€™ÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ¢Ã¢â€šÂ¬Ã…â€™ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â³Ã¢â‚¬Â¹ÃƒÂ Ã‚Â²Ã‚Â¡ÃƒÂ Ã‚Â³Ã‚Â ÃƒÂ Ã‚Â²Ã‚Â®ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â¡ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â³Ã‚Â ÃƒÂ Ã‚Â²Ã…Â¡ÃƒÂ Ã‚Â²Ã¢â‚¬Å¡ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã¢â‚¬Â¢ÃƒÂ Ã‚Â³Ã¢â‚¬Â ÃƒÂ Ã‚Â²Ã‚Â¯ÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â³Ã‚Â ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â²Ã¢â‚¬Â¢ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¯ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â³Ã…Â ÃƒÂ Ã‚Â²Ã‚Â³ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â²Ã‚Â¿.',
    malayalam:
        'ÃƒÂ Ã‚Â´Ã‚ÂªÃƒÂ Ã‚ÂµÃ¢â‚¬Â¹ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚Â¾ ÃƒÂ Ã‚Â´Ã‚ÂªÃƒÂ Ã‚Â´Ã¢â€žÂ¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã…Â¸ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â¨ÃƒÂ Ã‚ÂµÃ¢â‚¬Â¹ ÃƒÂ Ã‚Â´Ã‚Â¡ÃƒÂ Ã‚ÂµÃ¢â‚¬â€ÃƒÂ Ã‚ÂµÃ‚ÂºÃƒÂ Ã‚Â´Ã‚Â²ÃƒÂ Ã‚ÂµÃ¢â‚¬Â¹ÃƒÂ Ã‚Â´Ã‚Â¡ÃƒÂ Ã‚ÂµÃ‚Â ÃƒÂ Ã‚Â´Ã…Â¡ÃƒÂ Ã‚ÂµÃ¢â‚¬Â ÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â¨ÃƒÂ Ã‚ÂµÃ¢â‚¬Â¹ ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚Â´Ã‚Â¬ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â°ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã‚ÂªÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â·ÃƒÂ Ã‚ÂµÃ‚Â» ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚Â´Ã…â€œÃƒÂ Ã‚ÂµÃ¢â€šÂ¬ÃƒÂ Ã‚Â´Ã‚ÂµÃƒÂ Ã‚Â´Ã‚Â®ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢.',
    assamese:
        'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â·ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â§Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â§Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â°ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¡ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‹â€  ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã‚Â¤',
    konkani:
        'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¶ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¡ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Â°ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¤.',
    gujarati:
        'ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚Â«Ã¢â‚¬Â¹ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ…Â¸ÃƒÂ Ã‚ÂªÃ‚Â° ÃƒÂ Ã‚ÂªÃ‚Â¶ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ÃƒÂ Ã‚ÂªÃ‚Â° ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¦ÃƒÂ Ã‚ÂªÃ‚Â¥ÃƒÂ Ã‚ÂªÃ‚ÂµÃƒÂ Ã‚ÂªÃ‚Â¾ ÃƒÂ Ã‚ÂªÃ‚Â¡ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ¢â‚¬Â°ÃƒÂ Ã‚ÂªÃ‚Â¨ÃƒÂ Ã‚ÂªÃ‚Â²ÃƒÂ Ã‚Â«Ã¢â‚¬Â¹ÃƒÂ Ã‚ÂªÃ‚Â¡ ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚ÂªÃ‚ÂµÃƒÂ Ã‚ÂªÃ‚Â¾ ÃƒÂ Ã‚ÂªÃ‚Â®ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ…Â¸ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚ÂªÃ‚Â¬ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â¶ÃƒÂ Ã‚ÂªÃ‚Â¨ ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ‚Â¯ ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â‚¬Â¹.',
    marathi:
        'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¶ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¡ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Â°ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â£ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¯ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¾.',
    meitei:
        'Poster share touba nattraga download tounaba subscription active tou.',
    mizo: 'Poster share emaw download turin subscription activate rawh.',
    odia:
        'ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â­Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¬Ã‚Â·ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã…Â¸ÃƒÂ Ã‚Â¬Ã‚Â° ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ÃƒÂ Ã‚Â­Ã…Â¸ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â° ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã‚Â®ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â¬ÃƒÂ Ã‚Â¬Ã‚Â¾ ÃƒÂ Ã‚Â¬Ã‚Â¡ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã¢â‚¬Â°ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â¬Ã‚Â²ÃƒÂ Ã‚Â­Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¬Ã‚Â¡ÃƒÂ Ã‚Â­Ã‚Â ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚Â ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â¬Ã‚Â¬ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â­Ã‚Â ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â­Ã…Â¸ ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â¤ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¥Ã‚Â¤',
    punjabi:
        'ÃƒÂ Ã‚Â¨Ã‚ÂªÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã…Â¸ÃƒÂ Ã‚Â¨Ã‚Â° ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¨Ã‚ÂÃƒÂ Ã‚Â©Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¨Ã…â€œÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¨Ã‚Â¡ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã…Â ÃƒÂ Ã‚Â¨Ã‚Â¨ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¨Ã‚Â¡ ÃƒÂ Ã‚Â¨Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â¨Ã‚Â¨ ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â¨Ã‹â€  ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã‚Â¬ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã¢â‚¬Â¢ÃƒÂ Ã‚Â©Ã‚ÂÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã‚ÂªÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã‚Â¼ÃƒÂ Ã‚Â¨Ã‚Â¨ ÃƒÂ Ã‚Â¨Ã…Â¡ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â©Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¨Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¥Ã‚Â¤',
    nepali:
        'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¡ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Â°ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¨ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¯ ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¥Ã‚Â¤',
    bengali:
        'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â°ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¡ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚Â¤',
    kashmiri:
        'Ãƒâ„¢Ã‚Â¾Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â³Ãƒâ„¢Ã‚Â¹ÃƒËœÃ‚Â± ÃƒËœÃ‚Â´Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â¦ÃƒËœÃ‚Â± Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â§ ÃƒÅ¡Ã‹â€ ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¤Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‹â€ ÃƒÅ¡Ã‹â€  ÃƒÅ¡Ã‚Â©ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â Ãƒâ€ºÃ‚ÂÃƒâ„¢Ã¢â‚¬Â¢ ÃƒËœÃ‚Â®Ãƒâ„¢Ã‚Â²ÃƒËœÃ‚Â·ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¢ ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â³ÃƒÅ¡Ã‚Â©ÃƒËœÃ‚Â±Ãƒâ„¢Ã‚Â¾ÃƒËœÃ‚Â´Ãƒâ„¢Ã¢â‚¬Â  ÃƒÅ¡Ã¢â‚¬Â ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‹â€  ÃƒÅ¡Ã‚Â©Ãƒâ„¢Ã¢â‚¬ÂÃƒËœÃ‚Â±Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã‹â€ Ãƒâ€ºÃ¢â‚¬Â',
    ladakhi:
        'Poster share ÃƒÂ Ã‚Â½Ã‚Â¡ÃƒÂ Ã‚Â½Ã¢â‚¬Å¾ÃƒÂ Ã‚Â¼Ã¢â‚¬Â¹ÃƒÂ Ã‚Â½Ã¢â‚¬Å“ download ÃƒÂ Ã‚Â½Ã¢â‚¬â€œÃƒÂ Ã‚Â¾Ã‚Â±ÃƒÂ Ã‚Â½Ã‚ÂºÃƒÂ Ã‚Â½Ã¢â‚¬ËœÃƒÂ Ã‚Â¼Ã¢â‚¬Â¹ÃƒÂ Ã‚Â½Ã¢â‚¬ÂÃƒÂ Ã‚Â½Ã‚Â¢ subscription ÃƒÂ Ã‚Â½Ã‚Â ÃƒÂ Ã‚Â½Ã¢â‚¬Å¡ÃƒÂ Ã‚Â½Ã‚Â¼ÃƒÂ Ã‚Â¼Ã¢â‚¬Â¹ÃƒÂ Ã‚Â½Ã‚Â ÃƒÂ Ã‚Â½Ã¢â‚¬ÂºÃƒÂ Ã‚Â½Ã‚Â´ÃƒÂ Ã‚Â½Ã¢â‚¬Å¡ÃƒÂ Ã‚Â½Ã‚Â¦ÃƒÂ Ã‚Â¼Ã¢â‚¬Â¹ÃƒÂ Ã‚Â½Ã¢â‚¬â€œÃƒÂ Ã‚Â¾Ã‚Â±ÃƒÂ Ã‚Â½Ã‚ÂºÃƒÂ Ã‚Â½Ã¢â‚¬ËœÃƒÂ Ã‚Â¼Ã‚Â',
  );
}

String _subscriptionDialogTitleAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â°Ã‚Â¬ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ¢Ã¢â€šÂ¬Ã…â€™ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â°Ã‚Â¿ÃƒÂ Ã‚Â°Ã‚ÂªÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â·ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã¢â‚¬Â¦ÃƒÂ Ã‚Â°Ã‚ÂµÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â°Ã¢â‚¬Å¡',
    english: 'Subscription Required',
    hindi:
        'ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¶ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢',
    tamil:
        'ÃƒÂ Ã‚Â®Ã…Â¡ÃƒÂ Ã‚Â®Ã‚Â¨ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¾ ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â¯Ã¢â‚¬Â¡ÃƒÂ Ã‚Â®Ã‚ÂµÃƒÂ Ã‚Â¯Ã‹â€ ',
    kannada:
        'ÃƒÂ Ã‚Â²Ã…Â¡ÃƒÂ Ã‚Â²Ã¢â‚¬Å¡ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã¢â‚¬Â¢ÃƒÂ Ã‚Â³Ã¢â‚¬Â  ÃƒÂ Ã‚Â²Ã¢â‚¬Â¦ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â²Ã‚Â¤ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¯',
    malayalam:
        'ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚Â´Ã‚Â¬ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â°ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã‚ÂªÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â·ÃƒÂ Ã‚ÂµÃ‚Â» ÃƒÂ Ã‚Â´Ã¢â‚¬Â ÃƒÂ Ã‚Â´Ã‚ÂµÃƒÂ Ã‚Â´Ã‚Â¶ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚Â´Ã‚Â®ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â£ÃƒÂ Ã‚ÂµÃ‚Â',
    assamese:
        'ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¨',
    konkani:
        'ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã…â€œÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã…Â¡ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬',
    gujarati:
        'ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚ÂªÃ‚Â¬ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â¶ÃƒÂ Ã‚ÂªÃ‚Â¨ ÃƒÂ Ã‚ÂªÃ…â€œÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â‚¬Å¡ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â€šÂ¬',
    marathi:
        'ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¶ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢',
    meitei: 'Subscription mathou tai',
    mizo: 'Subscription a ngai',
    odia:
        'ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â¬Ã‚Â¬ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â­Ã‚Â ÃƒÂ Ã‚Â¬Ã¢â‚¬Â ÃƒÂ Ã‚Â¬Ã‚Â¬ÃƒÂ Ã‚Â¬Ã‚Â¶ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â­Ã…Â¸ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢',
    punjabi:
        'ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã‚Â¬ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã¢â‚¬Â¢ÃƒÂ Ã‚Â©Ã‚ÂÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã‚ÂªÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã‚Â¼ÃƒÂ Ã‚Â¨Ã‚Â¨ ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â©Ã…â€œÃƒÂ Ã‚Â©Ã¢â€šÂ¬ÃƒÂ Ã‚Â¨Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¨Ã‚Â¦ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â©Ã‹â€ ',
    nepali:
        'ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¶ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢',
    bengali:
        'ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â¶ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¨',
    kashmiri:
        'ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â³ÃƒÅ¡Ã‚Â©ÃƒËœÃ‚Â±Ãƒâ„¢Ã‚Â¾ÃƒËœÃ‚Â´Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â¶ÃƒËœÃ‚Â±Ãƒâ„¢Ã‚Â²ÃƒËœÃ‚Â±ÃƒËœÃ‚Âª',
    ladakhi:
        'Subscription ÃƒÂ Ã‚Â½Ã¢â‚¬ËœÃƒÂ Ã‚Â½Ã¢â‚¬Å¡ÃƒÂ Ã‚Â½Ã‚Â¼ÃƒÂ Ã‚Â½Ã‚Â¦ÃƒÂ Ã‚Â¼Ã‚Â ',
  );
}

String _subscriptionTrialTitleAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '3-day trial plan',
    hindi: '3 दिन का ट्रायल प्लान',
    tamil: '3 நாள் சோதனை திட்டம்',
    kannada: '3 ದಿನಗಳ ಪ್ರಾಯೋಗಿಕ ಯೋಜನೆ',
    malayalam: '3 ദിവസത്തെ ട്രയൽ പ്ലാൻ',
    marathi: '३ दिवसांची चाचणी योजना',
    gujarati: '3 દિવસની ટ્રાયલ યોજના',
    bengali: '৩ দিনের ট্রায়াল প্ল্যান',
    punjabi: '3 ਦਿਨਾਂ ਦਾ ਟ੍ਰਾਇਲ ਪਲਾਨ',
    odia: '୩ ଦିନର ଟ୍ରାଏଲ୍ ପ୍ଲାନ୍',
    assamese: '৩ দিনৰ ট্রায়েল প্লেন',
    konkani: '३ दिसांची ट्रायल येवजण',
    nepali: '३ दिने परीक्षण योजना',
    meitei: '3-day trial plan',
    mizo: '3-day trial plan',
    kashmiri: '۳ دۄہَن ہُنٛد آزمٲیِشی منصوٗبہٕ',
    ladakhi: 'ཉིན་ ༣ གྱི་ཚོད་ལྟའི་འཆར་གཞི།',
  );
}

String _subscriptionTrialValueAppLocalized(BuildContext context) {
  final days = SubscriptionPlanConfig.trialDays;
  final price = SubscriptionPlanConfig.trialPriceDisplay;
  return context.strings.localized(
    telugu:
        '$days ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã¢â‚¬Â¹ÃƒÂ Ã‚Â°Ã…â€œÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â±Ã‚Â $price',
    english: '$price for $days days',
    hindi:
        '$days ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â $price',
    tamil:
        '$days ÃƒÂ Ã‚Â®Ã‚Â¨ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚Â³ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚Â $price',
    kannada:
        '$days ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â²Ã‚Â³ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â³Ã¢â‚¬Â  $price',
    malayalam:
        '$days ÃƒÂ Ã‚Â´Ã‚Â¦ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã‚ÂµÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚Â´Ã¢â€žÂ¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â€žÂ¢ÃƒÂ Ã‚ÂµÃ‚Â¾ÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚Â $price',
    assamese:
        '$days ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ $price',
    konkani:
        '$days ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¤Ã¢â‚¬â€œÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ÃƒÂ Ã‚Â¤Ã‚Â° $price',
    gujarati:
        '$days ÃƒÂ Ã‚ÂªÃ‚Â¦ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ‚ÂµÃƒÂ Ã‚ÂªÃ‚Â¸ ÃƒÂ 
... [truncated for diff preview]
        '$days ÃƒÂ Ã‚ÂªÃ‚Â¦ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ‚ÂµÃƒÂ Ã‚ÂªÃ‚Â¸ ÃƒÂ Ã‚ÂªÃ‚Â®ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ…Â¸ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ $price',
    marathi:
        '$days ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ $price',
    meitei: '$days numitki $price',
    mizo: '$days ni atan $price',
    odia:
        '$days ÃƒÂ Ã‚Â¬Ã‚Â¦ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã‚Â¨ ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚Â $price',
    punjabi:
        '$days ÃƒÂ Ã‚Â¨Ã‚Â¦ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã‚Â¨ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â¨Ã‹â€  $price',
    nepali:
        '$days ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¤Ã‚Â¿ $price',
    bengali:
        '$days ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ $price',
    kashmiri:
        '$days ÃƒËœÃ‚Â¯Ãƒâ€ºÃ¢â‚¬Å¾Ãƒâ€ºÃ‚ÂÃƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â®Ãƒâ„¢Ã‚Â²ÃƒËœÃ‚Â·ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¢ $price',
    ladakhi:
        '$days ÃƒÂ Ã‚Â½Ã¢â‚¬Â°ÃƒÂ Ã‚Â½Ã‚Â²ÃƒÂ Ã‚Â½Ã¢â‚¬Å“ÃƒÂ Ã‚Â¼Ã¢â‚¬Â¹ÃƒÂ Ã‚Â½Ã‚Â£ $price',
  );
}

String _subscriptionMonthlyTitleAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â±Ã¢â‚¬Â ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â°Ã‚ÂµÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã¢â€šÂ¬ ÃƒÂ Ã‚Â°Ã‚ÂªÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â±Ã‚Â',
    english: 'Monthly plan',
    hindi:
        'ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¨',
    tamil:
        'ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã‚Â¨ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã‚Â° ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â¯Ã‚Â',
    kannada:
        'ÃƒÂ Ã‚Â²Ã‚Â®ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â²Ã‚ÂªÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â³Ã‚Â',
    malayalam:
        'ÃƒÂ Ã‚Â´Ã‚Â®ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â´Ã‚ÂªÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â²ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚ÂµÃ‚Â»',
    assamese:
        'ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â€šÂ¬ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¨',
    konkani:
        'ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã…Â¡ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â¨',
    gujarati:
        'ÃƒÂ Ã‚ÂªÃ‚Â®ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â²ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ‚Â¨',
    marathi:
        'ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â¨',
    meitei: 'Monthly plan',
    mizo: 'Monthly plan',
    odia:
        'ÃƒÂ Ã‚Â¬Ã‚Â®ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â²ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â­Ã‚Â',
    punjabi:
        'ÃƒÂ Ã‚Â¨Ã‚Â®ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ÃƒÂ Ã‚Â¨Ã‚Â¨ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã‚ÂµÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã‚Â° ÃƒÂ Ã‚Â¨Ã‚ÂªÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã‚Â¨',
    nepali:
        'ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¨',
    bengali:
        'ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨',
    kashmiri:
        'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§Ãƒâ€ºÃ‚ÂÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â Ãƒâ€ºÃ‚Â Ãƒâ„¢Ã‚Â¾Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ',
    ladakhi: 'Monthly plan',
  );
}

String _subscriptionMonthlyValueAppLocalized(BuildContext context) {
  final price = SubscriptionPlanConfig.monthlyPriceDisplay;
  return context.strings.localized(
    telugu:
        'ÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â±Ã¢â‚¬Â ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â±Ã‚Â $price',
    english: '$price per month',
    hindi:
        '$price ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¿ ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¹',
    tamil:
        'ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã‚Â±ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚Â $price',
    kannada:
        'ÃƒÂ Ã‚Â²Ã‚Â¤ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã¢â‚¬Å¡ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â²Ã‚Â³ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â³Ã¢â‚¬Â  $price',
    malayalam: 'ÃƒÂ Ã‚Â´Ã‚Â®ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚Â´Ã¢â‚¬Å¡ $price',
    assamese:
        'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¿ ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ $price',
    konkani:
        'ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ $price',
    gujarati:
        'ÃƒÂ Ã‚ÂªÃ‚Â¦ÃƒÂ Ã‚ÂªÃ‚Â° ÃƒÂ Ã‚ÂªÃ‚Â®ÃƒÂ Ã‚ÂªÃ‚Â¹ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ‚Â¨ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ $price',
    marathi:
        'ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â¾ $price',
    meitei: 'tha khuding $price',
    mizo: 'thla tin $price',
    odia:
        'ÃƒÂ Ã‚Â¬Ã‚Â®ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â­Ã‚Â $price',
    punjabi:
        'ÃƒÂ Ã‚Â¨Ã‚ÂªÃƒÂ Ã‚Â©Ã‚ÂÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â¨Ã‚Â¤ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¨Ã‚Â®ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ÃƒÂ Ã‚Â¨Ã‚Â¨ÃƒÂ Ã‚Â¨Ã‚Â¾ $price',
    nepali:
        'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¿ ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â¾ $price',
    bengali:
        'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¿ ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ $price',
    kashmiri: 'Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ€ºÃ‚ÂÃƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â³ $price',
    ladakhi:
        'ÃƒÂ Ã‚Â½Ã…Â¸ÃƒÂ Ã‚Â¾Ã‚Â³ÃƒÂ Ã‚Â¼Ã¢â‚¬Â¹ÃƒÂ Ã‚Â½Ã‚Â¢ÃƒÂ Ã‚Â½Ã‚ÂºÃƒÂ Ã‚Â½Ã‚Â¢ $price',
  );
}

String _subscriptionRenewalCopyAppLocalized(BuildContext context) {
  final days = SubscriptionPlanConfig.trialDays;
  final price = SubscriptionPlanConfig.monthlyPriceDisplay;
  final copy =
      'After the $days-day trial, it auto-renews at $price/month unless cancelled.';
  return context.strings.localized(
    telugu:
        '$days రోజుల ట్రయల్ తర్వాత, రద్దు చేయకపోతే నెలకు $price ఆటో-రీన్యూ అవుతుంది.',
    english: copy,
    hindi:
        '$days-दिनों के परीक्षण के बाद, रद्द न करने पर यह $price/माह पर स्वतः नवीनीकृत होगा।',
    tamil:
        '$days நாள் சோதனைக்குப் பிறகு, ரத்து செய்யாவிட்டால் மாதம் $price-க்கு தானாகப் புதுப்பிக்கப்படும்.',
    kannada:
        '$days ದಿನಗಳ ಪ್ರಯೋಗದ ನಂತರ, ರದ್ದುಗೊಳಿಸದಿದ್ದರೆ ತಿಂಗಳಿಗೆ $price ಸ್ವಯಂ-ನವೀಕರಣಗೊಳ್ಳುತ್ತದೆ.',
    malayalam:
        '$days ദിവസത്തെ ട്രയലിന് ശേഷം, റദ്ദാക്കിയില്ലെങ്കിൽ പ്രതിമാസം $price നിരക്കിൽ സ്വയമേവ പുതുക്കും.',
    marathi:
        '$days दिवसांच्या चाचणीनंतर, रद्द न केल्यास दरमहा $price वर ऑटो-रिन्यू होईल.',
    gujarati:
        '$days-દિવસની અજમાયશ પછી, રદ ન કરવામાં આવે તો તે દર મહિને $price પર ઑટો-રિન્યૂ થાય છે.',
    bengali:
        '$days-দিনের ট্রায়ালের পরে, বাতিল না করা হলে প্রতি মাসে $price হারে স্বতঃ-নবায়ন হবে।',
    punjabi:
        '$days-ਦਿਨਾਂ ਦੇ ਟਰਾਇਲ ਤੋਂ ਬਾਅਦ, ਰੱਦ ਨਾ ਕਰਨ \'ਤੇ ਇਹ $price/ਮਹੀਨਾ \'ਤੇ ਸਵੈ-ਨਵਿਆਇਆ ਜਾਵੇਗਾ।',
    odia:
        '$days ଦିନର ଟ୍ରାଏଲ୍ ପରେ, ବାତିଲ୍ ନକଲେ ଏହା ମାସକୁ $price ରେ ସ୍ୱୟଂ-ନବୀକରଣ ହେବ।',
    assamese:
        '$days দিনীয়া ট্ৰায়েলৰ পিছত, বাতিল নকৰিলে প্ৰতি মাহে $price ত স্বয়ংক্ৰিয়ভাৱে নবীকৰণ হ’ব।',
    konkani:
        '$days दिसांच्या चाचणी उपरांत, रद्द करीना जाल्यार दर म्हयन्याक $price प्रमाण स्वयंचलित नूतनीकरण जातलें.',
    nepali:
        '$days-दिने परीक्षण पछि, रद्द नगरेमा यो प्रति महिना $price मा स्वतः नवीकरण हुन्छ।',
    meitei:
        'নুমিৎ $days নিগী ত্রায়ল মতুংদা, কেন্সেল তৌদ্রবদি থাদা $price দা ওতো-রিনিউ তৌগনি।',
    mizo:
        'Ni $days trial hnuah, cancel loh chuan thla tin $price-in auto-renew ang.',
    kashmiri:
        '$days دوہَن ہُنٛد ٹرائل پتہٕ، کینسل نہٕ کرنہٕ کِس صورتس منٛز گژھِ یہِ خود بخود $price/ماہس پؠٹھ نویں سرٕ۔',
    ladakhi:
        'ཉིན་ $days ཚོད་ལྟའི་རྗེས་སུ། ཕྱིར་འཐེན་མ་བྱས་ན་ཟླ་རེར $price རང་བཞིན་གྱིས་གསར་བཟོ་བྱེད།',
  );
}

String _subscriptionTermsLabelAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నిబంధనలు',
    english: 'Terms',
    hindi: 'नियम',
    tamil: 'விதிமுறைகள்',
    kannada: 'ನಿಯಮಗಳು',
    malayalam: 'നിബന്ധനകൾ',
    marathi: 'अटी',
    gujarati: 'શરતો',
    bengali: 'শর্তাবলী',
    punjabi: 'ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ',
    assamese: 'চৰ্তাৱলী',
    konkani: 'अटी',
    nepali: 'सर्तहरू',
    meitei: 'চৎন-পথাপশিং',
    mizo: 'Hman dan tur',
    kashmiri: 'شرائط',
    ladakhi: 'ཆ་རྐྱེན།',
  );
}

String _subscriptionSkipLabelAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'దాటవేయి',
    english: 'Skip',
    hindi: 'छोड़ें',
    tamil: 'தவிர்',
    kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
    malayalam: 'ഒഴിവാക്കുക',
    marathi: 'वगळा',
    gujarati: 'છોડો',
    bengali: 'এড়িয়ে যান',
    punjabi: 'ਛੱਡੋ',
    odia: 'ଛାଡ଼ନ୍ତୁ',
    assamese: 'এৰক',
    konkani: 'सोडून दियात',
    nepali: 'छोड्नुहोस्',
    meitei: 'থাংদোইথোকউ',
    mizo: 'Kalsan rawh',
    kashmiri: 'ترک کٔرِو',
    ladakhi: 'མཆོང་།',
  );
}

String _subscriptionButtonLabelAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe',
    hindi: 'सदस्यता लें',
    tamil: 'குழுசேர்',
    kannada: 'ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'സബ്സ്ക്രൈബ് ചെയ്യുക',
    marathi: 'सदस्यता घ्या',
    gujarati: 'સબ્સ્ક્રાઇબ કરો',
    bengali: 'সাবস্ক্রাইব করুন',
    punjabi: 'ਗਾਹਕ ਬਣੋ',
    odia: 'ସବସ୍କ੍ਰਾਈବ୍ କରନ୍ତୁ',
    assamese: 'চাবস্ক্ৰাইব কৰক',
    konkani: 'वर्गणीदार जायात',
    nepali: 'सदस्यता लिनुहोस्',
    meitei: 'সবস্ক্রাইব তৌবীয়ু',
    mizo: 'Subscribe rawh',
    kashmiri: 'سبسکرائب کٔرِو',
    ladakhi: 'མངགས་ཉོ་བྱོས།',
  );
}

String _posterShareLabel(BuildContext context) => 'Share';
String _posterDownloadLabel(BuildContext context) => 'Download';

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
                      label: _posterDownloadLabel(context),
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
    this.hiddenImageUrls = const <String>{},
    this.assetSlots = const <PoliticalProtocolSlot>[],
  });

  final List<String> assetPaths;
  final List<String> imageUrls;
  final List<PoliticalProtocolSlot> slots;
  final Set<String> hiddenImageUrls;
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
    final hiddenUrls = hiddenImageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();
    final visibleUrlSlots = <({String url, PoliticalProtocolSlot slot})>[];
    final resolvedSlots = slots.length >= defaultPoliticalProtocolSlots.length
        ? slots
              .take(defaultPoliticalProtocolSlots.length)
              .toList(growable: false)
        : defaultPoliticalProtocolSlots;
    for (
      var index = 0;
      index < imageUrls.length && index < resolvedSlots.length;
      index += 1
    ) {
      final url = imageUrls[index].trim();
      if (url.isEmpty || hiddenUrls.contains(url)) {
        continue;
      }
      visibleUrlSlots.add((url: url, slot: resolvedSlots[index]));
    }
    final visiblePaths = assetPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final totalCount = visibleUrlSlots.length + visiblePaths.length;
    if (totalCount == 0) {
      return const SizedBox.shrink();
    }
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
            for (var index = 0; index < visibleUrlSlots.length; index += 1)
              Builder(
                builder: (context) {
                  final slot = visibleUrlSlots[index].slot;
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
                    imageUrl: visibleUrlSlots[index].url,
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
    required this.hiddenDefaultPhotoUrls,
  });

  final List<String> manualPhotoPaths;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<PoliticalProtocolSlot> manualSlots;
  final Set<String> hiddenDefaultPhotoUrls;
}

class _PoliticalProtocolPhotoScreen extends StatefulWidget {
  const _PoliticalProtocolPhotoScreen({
    required this.item,
    required this.language,
    required this.viewerPosterProfile,
    required this.politicalProtocolPhotoUrls,
    required this.partyLogoAssetPath,
    required this.showDefaultProtocolPhotos,
    required this.initialManualPhotoPaths,
    required this.initialHiddenDefaultPhotoUrls,
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
  final String? partyLogoAssetPath;
  final bool showDefaultProtocolPhotos;
  final List<String> initialManualPhotoPaths;
  final Set<String> initialHiddenDefaultPhotoUrls;
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
  Set<String> _hiddenDefaultPhotoUrls = const <String>{};
  ImageStream? _posterImageStream;
  ImageStreamListener? _posterImageStreamListener;
  bool _busy = false;
  int? _deleteArmedDefaultIndex;
  int? _deleteArmedManualIndex;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
    _manualPhotoPaths = widget.initialManualPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: true);
    _defaultSlots = _normalizeDefaultProtocolSlots(widget.defaultSlots);
    _manualSlots = _normalizeManualProtocolSlots(
      widget.initialManualSlots,
      _manualPhotoPaths.length,
    );
    _hiddenDefaultPhotoUrls = widget.initialHiddenDefaultPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();
    unawaited(_loadSavedLeaderPhotoPaths());
    unawaited(_loadHiddenDefaultPhotoUrls());
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
    unawaited(ScreenSecurityService.unprotectScreen());
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

  String get _hiddenDefaultPhotoPrefsKey {
    final scope = widget.leaderPhotoLibraryScopeKey.trim().isNotEmpty
        ? widget.leaderPhotoLibraryScopeKey.trim()
        : 'political';
    return 'political_hidden_default_protocol_photos_v1_$scope';
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

  Future<void> _loadHiddenDefaultPhotoUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final urls =
          prefs
              .getStringList(_hiddenDefaultPhotoPrefsKey)
              ?.map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .toSet() ??
          const <String>{};
      if (!mounted) {
        return;
      }
      setState(() => _hiddenDefaultPhotoUrls = urls);
    } catch (_) {
      // Hidden default protocol photos are optional local preferences.
    }
  }

  Future<void> _persistHiddenDefaultPhotoUrls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _hiddenDefaultPhotoPrefsKey,
      _hiddenDefaultPhotoUrls.toList(growable: false),
    );
  }

  Future<void> _hideDefaultPhotoUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _hiddenDefaultPhotoUrls = <String>{..._hiddenDefaultPhotoUrls, trimmed};
      _deleteArmedDefaultIndex = null;
    });
    await _persistHiddenDefaultPhotoUrls();
  }

  Future<void> _restoreDefaultPhotoUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !_hiddenDefaultPhotoUrls.contains(trimmed)) {
      return;
    }
    setState(() {
      _hiddenDefaultPhotoUrls = _hiddenDefaultPhotoUrls
          .where((existing) => existing.trim() != trimmed)
          .toSet();
      _deleteArmedDefaultIndex = null;
    });
    await _persistHiddenDefaultPhotoUrls();
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
      _deleteArmedDefaultIndex = null;
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
              telugu: 'మీరు గరిష్టంగా 6 ఫోటోలను మాత్రమే జోడించగలరు.',
              english: 'You can add up to 6 photos only.',
              hindi: 'आप केवल 6 फ़ोटो तक जोड़ सकते हैं।',
              tamil:
                  'நீங்கள் அதிகபட்சமாக 6 புகைப்படங்களை மட்டுமே சேர்க்க முடியும்.',
              kannada: 'ನೀವು ಗರಿಷ್ಠ 6 ಫೋಟೋಗಳನ್ನು ಮಾತ್ರ ಸೇರಿಸಬಹುದು.',
              malayalam: 'പരമാവധി 6 ഫോട്ടോകൾ മാത്രമേ ചേർക്കാൻ കഴിയൂ.',
              marathi: 'तुम्ही फक्त 6 फोटोंपर्यंत जोडू शकता.',
              gujarati: 'તમે ફક્ત 6 ફોટા સુધી જ ઉમેરી શકો છો.',
              bengali: 'আপনি কেবল ৬টি ফটো পর্যন্ত যোগ করতে পারেন।',
              punjabi: 'ਤੁਸੀਂ ਸਿਰਫ਼ 6 ਫੋਟੋਆਂ ਤੱਕ ਜੋੜ ਸਕਦੇ ਹੋ।',
              odia: 'ଆପଣ କେବଳ ୬ଟି ଫଟୋ ପର୍ଯ୍ୟନ୍ତ ଯୋଡ଼ିପାରିବେ।',
              assamese: 'আপুনি কেৱল ৬খন ফটো যোগ কৰিব পাৰে।',
              konkani: 'तुमी फक्त 6 फोटों मेरेन जोडूंक शकतात.',
              nepali: 'तपाईं केवल ६ वटा तस्विरहरू थप्न सक्नुहुन्छ।',
              meitei: 'নহাক্না ফোতো 6 তখক হাপচিনবা য়াই।',
              mizo: 'Thlalak 6 chauh i thlang thei ang.',
              kashmiri: 'تُہؠ ہیٚکِو صرف 6 فوٹو رَلاوِتھ۔',
              ladakhi: 'ཁྱེད་ཀྱིས་པར་ ༦ ལས་ལྷག་པ་བསྣན་མི་ཐུབ།',
            ),
          ),
        ),
      );
      return;
    }
    final cropTitle = context.strings.localized(
      telugu: 'ఫోటో కత్తిరించండి',
      english: 'Crop Photo',
      hindi: 'फ़ोटो क्रॉप करें',
      tamil: 'புகைப்படத்தை செதுக்கு',
      kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
      malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
      marathi: 'फोटो क्रॉप करा',
      gujarati: 'ફોટો ક્રોપ કરો',
      bengali: 'ছবি ক্রপ করুন',
      punjabi: 'ਫੋਟੋ ਕੱਟੋ',
      odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
      assamese: 'ফটো ক্ৰপ কৰক',
      konkani: 'फोटो क्रॉप करा',
      nepali: 'फोटो क्रप गर्नुहोस्',
      meitei: 'ফোতো ক্রপ তৌবীয়ু',
      mizo: 'Thlalak tan rawh',
      kashmiri: 'فوٹو کٹ کرِو',
      ladakhi: 'པར་བཅད་ཏེ་བཟོས།',
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
              telugu: 'ఫోటోను జోడించలేకపోయాము. దయచేసి మళ్లీ ప్రయత్నించండి.',
              english: 'Could not add the photo. Please try again.',
              hindi: 'फ़ोटो नहीं जोड़ी जा सकी। कृपया पुनः प्रयास करें।',
              tamil:
                  'புகைப்படத்தைச் சேர்க்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada: 'ಫೋಟೋ ಸೇರಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'ഫോട്ടോ ചേർക്കാനായില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
              marathi: 'फोटो जोडता आला नाही. कृपया पुन्हा प्रयत्न करा.',
              gujarati: 'ફોટો ઉમેરી શકાયો નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
              bengali: 'ফটো যোগ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
              punjabi:
                  'ਫੋਟੋ ਸ਼ਾਮਲ ਨਹੀਂ ਕੀਤੀ ਜਾ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
              odia:
                  'ଫଟୋ ଯୋଡ଼ିବା ସମ୍ଭବ ହେଲାନାହିଁ। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
              assamese: 'ফটো যোগ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
              konkani: 'फोटो जोडूंक जालो ना. उपकार करून परत यत्न करा.',
              nepali: 'फोटो थप्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
              meitei: 'ফোতো হাপচিনবা ঙমদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
              mizo: 'Thlalak dah theih a ni lo. Khawngaihin ti nawn leh rawh.',
              kashmiri:
                  'فوٹو ہیٚکہ نہٕ رَلٲوِتھ۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
              ladakhi: 'པར་བསྣན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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
      _showScreenSnack(context.strings.couldNotAddPoster);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _captureCustomPosterFile() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
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
      telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
      english: 'Gallery permission was denied.',
      hindi: 'गैलरी की अनुमति अस्वीकार कर दी गई।',
      tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
      kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ.',
      malayalam: 'ഗ്യാലറി അനുമതി നിരസിച്ചു.',
      marathi: 'गॅलरी परवानगी नाकारली गेली.',
      gujarati: 'ગૅલેરી પરવાનગી નકારી દેવામાં આવી.',
      bengali: 'গ্যালারির অনুমতি প্রত্যাখ্যান করা হয়েছে।',
      punjabi: 'ਗੈਲਰੀ ਦੀ ਇਜਾਜ਼ਤ ਅਸਵੀਕਾਰ ਕਰ ਦਿੱਤੀ ਗਈ।',
      odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଗଲା।',
      assamese: 'গেলেৰীৰ অনুমতি নাকচ কৰা হ’ল।',
      konkani: 'गॅलरीची परवानगी नाकारली.',
      nepali: 'ग्यालरी अनुमति अस्वीकृत गरियो।',
      meitei: 'গেলরিগী অয়াবা য়াদে।',
      mizo: 'Gallery phalna hnar a ni.',
      kashmiri: 'گیلری ہٕنٛز اِجازت آیہِ مسترد کَرنہٕ۔',
      ladakhi: 'པར་མཛོད་ཆོག་མཆན་ཕྱིར་འཐེན་བྱས།',
    );
    final captureFailedMessage = context.strings.localized(
      telugu: 'క్యాప్చర్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
      hindi: 'कैप्चर विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'படமெடுத்தல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಕ್ಯಾಪ್ಚರ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ക്യാപ്‌ചർ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'कॅप्चर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'કૅપ્ચર નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ক্যাপচার ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਕੈਪਚਰ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'କ୍ୟାପଚର୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'কেপচাৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'कॅप्चर जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'क्याप्चर असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'কেপচর তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Capture a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'کیپچر گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'པར་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final savedMessage = context.strings.localized(
      telugu: 'పోస్టర్ గ్యాలరీలో సేవ్ చేయబడింది.',
      english: 'Poster saved to gallery.',
      hindi: 'पोस्टर गैलरी में सहेजा गया।',
      tamil: 'போஸ்டர் கேலரியில் சேமிக்கப்பட்டது.',
      kannada: 'ಪೋಸ್ಟರ್ ಗ್ಯಾಲರಿಯಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ.',
      malayalam: 'പോസ്റ്റർ ഗ്യാലറിയിൽ സൂക്ഷിച്ചു.',
      marathi: 'पोस्टर गॅलरीमध्ये जतन केले.',
      gujarati: 'પોસ્ટર ગૅલેરીમાં સાચવવામાં આવ્યું.',
      bengali: 'পোস্টারটি গ্যালারিতে সংরক্ষিত হয়েছে।',
      punjabi: 'ਪੋਸਟਰ ਗੈਲਰੀ ਵਿੱਚ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਗਿਆ।',
      odia: 'ପୋଷ୍ଟର ଗ୍ୟାଲେରୀରେ ସେଭ୍ ହୋଇଛି।',
      assamese: 'পোষ্টাৰ গেলেৰীত সংৰক্ষণ কৰা হ’ল।',
      konkani: 'पोस्टर गॅलरींत सांबाळ्ळें.',
      nepali: 'पोस्टर ग्यालरीमा सुरक्षित गरियो।',
      meitei: 'পোস্তর অসি গেলরিদা সেভ তৌখ্রে।',
      mizo: 'Poster gallery-ah dahthat a ni ta.',
      kashmiri: 'پوسٹر آو گیلری منٛز محفوٗظ کَرنہٕ۔',
      ladakhi: 'པོ་སི་ཊར་པར་མཛོད་ནང་ཉར་ཚགས་བྱས།',
    );
    final downloadFailedMessage = context.strings.localized(
      telugu: 'డౌన్‌లోడ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Download failed. Please try again.',
      hindi: 'डाउनलोड विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'பதிவிறக்கம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ഡൗൺലോഡ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'डाउनलोड अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'ડાઉનલોડ નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ডাউনলোড ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਡਾਊਨਲੋਡ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଡାଉନଲୋଡ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'ডাউনলোড ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'डाऊनलोड जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'डाउनलोड असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'দাউনলোদ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Download a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'ڈاؤنلوڈ گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'ཕབ་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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
      telugu: 'క్యాప్చర్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
      hindi: 'कैप्चर विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'படமெடுத்தல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಕ್ಯಾಪ್ಚರ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ക്യാപ്‌ചർ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'कॅप्चर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'કૅપ્ચર નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ক্যাপচার ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਕੈਪਚਰ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'କ୍ୟାପଚର୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'কেপচাৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'कॅप्चर जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'क्याप्चर असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'কেপচর তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Capture a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'کیپچر گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'པར་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final shareFailedMessage = context.strings.localized(
      telugu: 'షేర్ చేయడం విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Share failed. Please try again.',
      hindi: 'शेयर करना विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'பகிர்வது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಹಂಚಿಕೆ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'പങ്കിടൽ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'शेअर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'શેર કરવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'শেয়ার করা ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਸਾਂਝਾ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ସେୟାର୍ କରିବା ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'শ্বেয়াৰ কৰা ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'वांटप जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'सेयर गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'শিয়র তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Share a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'شیئر گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'བགོ་འགྲེམས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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

  List<String> get _hiddenDefaultProtocolPhotoUrls {
    return widget.politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .take(defaultPoliticalProtocolSlots.length)
        .where((url) => url.isNotEmpty && _hiddenDefaultPhotoUrls.contains(url))
        .toList(growable: false);
  }

  Future<void> _openPartyLeaderPhotoSheet() async {
    if (_busy || _exportAction != null) {
      return;
    }
    final adminUrls = _extraAdminProtocolPhotoUrls;
    final hiddenDefaultUrls = _hiddenDefaultProtocolPhotoUrls;
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
            final totalCount =
                hiddenDefaultUrls.length +
                adminUrls.length +
                savedPaths.length +
                1;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.strings.addPartyLeaderPhotos,
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.strings.tapPhotoToPlaceOnPoster,
                      style: const TextStyle(
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
                          if (index < hiddenDefaultUrls.length) {
                            final url = hiddenDefaultUrls[index];
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
                              onTap: () => Navigator.of(
                                sheetContext,
                              ).pop('__restore_default::$url'),
                            );
                          }
                          final adminIndex = index - hiddenDefaultUrls.length;
                          if (adminIndex < adminUrls.length) {
                            final url = adminUrls[adminIndex];
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
                          final savedIndex =
                              index -
                              hiddenDefaultUrls.length -
                              adminUrls.length;
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
    if (selected.startsWith('__restore_default::')) {
      await _restoreDefaultPhotoUrl(
        selected.substring('__restore_default::'.length),
      );
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
          label: Text(
            context.strings.addPartyLeaderPhotos,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
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
      hiddenDefaultPhotoUrls: _hiddenDefaultPhotoUrls,
      deleteArmedDefaultIndex: _deleteArmedDefaultIndex,
      deleteArmedManualIndex: _deleteArmedManualIndex,
      onDefaultSlotChanged: (index, slot) {
        if (index >= 0 && index < _defaultSlots.length) {
          _defaultSlots[index] = slot;
        }
      },
      onDefaultPhotoTap: (index, url) {
        if (_deleteArmedDefaultIndex == index) {
          unawaited(_hideDefaultPhotoUrl(url));
          return;
        }
        setState(() {
          _deleteArmedDefaultIndex = index;
          _deleteArmedManualIndex = null;
        });
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
        setState(() {
          _deleteArmedDefaultIndex = null;
          _deleteArmedManualIndex = index;
        });
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
      partyLogoAssetPath: widget.partyLogoAssetPath,
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
              label: hasCustomPoster
                  ? context.strings.changeYourPoster
                  : context.strings.addYourPoster,
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
                    hindi: 'Share',
                    tamil: 'Share',
                    kannada: 'Share',
                    malayalam: 'Share',
                    marathi: 'Share',
                    gujarati: 'Share',
                    bengali: 'Share',
                    punjabi: 'Share',
                    odia: 'Share',
                    assamese: 'Share',
                    konkani: 'Share',
                    nepali: 'Share',
                    meitei: 'Share',
                    mizo: 'Share',
                    kashmiri: 'Share',
                    ladakhi: 'Share',
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
                    hindi: 'Download',
                    tamil: 'Download',
                    kannada: 'Download',
                    malayalam: 'Download',
                    marathi: 'Download',
                    gujarati: 'Download',
                    bengali: 'Download',
                    punjabi: 'Download',
                    odia: 'Download',
                    assamese: 'Download',
                    konkani: 'Download',
                    nepali: 'Download',
                    meitei: 'Download',
                    mizo: 'Download',
                    kashmiri: 'Download',
                    ladakhi: 'Download',
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
        title: Text(context.strings.addPoliticalPhotos),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              _PoliticalProtocolPhotoScreenResult(
                manualPhotoPaths: _manualPhotoPaths,
                defaultSlots: _defaultSlots,
                manualSlots: _manualSlots,
                hiddenDefaultPhotoUrls: _hiddenDefaultPhotoUrls,
              ),
            ),
            child: Text(
              context.strings.doneLabel,
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
            if (_deleteArmedDefaultIndex != null ||
                _deleteArmedManualIndex != null) {
              setState(() {
                _deleteArmedDefaultIndex = null;
                _deleteArmedManualIndex = null;
              });
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
                  context.strings.politicalProtocolPhotoHelp,
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
    required this.hiddenDefaultPhotoUrls,
    required this.deleteArmedDefaultIndex,
    required this.deleteArmedManualIndex,
    required this.onDefaultSlotChanged,
    required this.onDefaultPhotoTap,
    required this.onManualSlotChanged,
    required this.onManualPhotoTap,
  });

  final double canvasWidth;
  final double canvasHeight;
  final List<String> adminUrls;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<String> manualPhotoPaths;
  final List<PoliticalProtocolSlot> manualSlots;
  final Set<String> hiddenDefaultPhotoUrls;
  final int? deleteArmedDefaultIndex;
  final int? deleteArmedManualIndex;
  final void Function(int index, PoliticalProtocolSlot slot)
  onDefaultSlotChanged;
  final void Function(int index, String url) onDefaultPhotoTap;
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
    } else {
      _defaultSlots = _copySlots(widget.defaultSlots);
    }
    if (oldWidget.manualSlots.length != widget.manualSlots.length ||
        oldWidget.manualPhotoPaths.length != widget.manualPhotoPaths.length) {
      _manualSlots = _copySlots(widget.manualSlots);
    } else {
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

  Widget _buildPhotoSlot({required double side, required Widget child}) {
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.95),
        border: Border.all(color: Colors.white, width: 0.8),
      ),
      child: ClipOval(child: child),
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
    final hiddenDefaultUrls = widget.hiddenDefaultPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (var index = 0; index < widget.adminUrls.length; index += 1)
          Builder(
            builder: (context) {
              final adminUrl = widget.adminUrls[index].trim();
              if (adminUrl.isEmpty || hiddenDefaultUrls.contains(adminUrl)) {
                return const SizedBox.shrink();
              }
              final slot = index < _defaultSlots.length
                  ? widget.defaultSlots[index]
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
              final deleteArmed = widget.deleteArmedDefaultIndex == index;
              final child = Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CachedNetworkImage(
                    imageUrl: adminUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const Icon(Icons.person_rounded),
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onDefaultPhotoTap(index, adminUrl),
                  onPanUpdate: (details) {
                    final nextSlot = _draggedSlot(
                      slot: index < widget.defaultSlots.length
                          ? widget.defaultSlots[index]
                          : slot,
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
                    if (index < widget.defaultSlots.length) {
                      widget.onDefaultSlotChanged(index, nextSlot);
                    }
                  },
                  child: _buildPhotoSlot(side: side, child: child),
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
                  ? widget.manualSlots[manualIndex]
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onManualPhotoTap(manualIndex),
                  onPanUpdate: (details) {
                    final nextSlot = _draggedSlot(
                      slot: manualIndex < widget.manualSlots.length
                          ? widget.manualSlots[manualIndex]
                          : slot,
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
                    if (manualIndex < widget.manualSlots.length) {
                      widget.onManualSlotChanged(manualIndex, nextSlot);
                    }
                  },
                  child: _buildPhotoSlot(side: side, child: child),
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
    this.showPartyLogoInNameChip = false,
    this.politicalProtocolPhotoScopeKey = '',
    this.partyLogoOverridesByPartyId = const <String, String>{},
    this.politicalParties = const <PoliticalParty>[],
    this.forcedPoliticalProtocolPartyId,
    this.showPosterEditButton = false,
    this.allowPoliticalProtocolWithoutParty = false,
    this.preferUltraLightImage = false,
    this.fillViewport = false,
    this.previewOnly = false,
    this.onPreviewTap,
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
  final bool showPartyLogoInNameChip;
  final String politicalProtocolPhotoScopeKey;
  final Map<String, String> partyLogoOverridesByPartyId;
  final List<PoliticalParty> politicalParties;
  final String? forcedPoliticalProtocolPartyId;
  final bool showPosterEditButton;
  final bool allowPoliticalProtocolWithoutParty;
  final bool preferUltraLightImage;
  final bool fillViewport;
  final bool previewOnly;
  final VoidCallback? onPreviewTap;
  final void Function(_TemplateItem item, String action)? onInteraction;
  static final SubscriptionBackendService _subscriptionBackendService =
      SubscriptionBackendService();
  static const PoliticalProtocolPhotoService _politicalProtocolPhotoService =
      PoliticalProtocolPhotoService();
  static final RewardedAccessService _homeExportRewardedAccessService =
      RewardedAccessService();
  static final HomeExportAdSettingsService _homeExportAdSettingsService =
      HomeExportAdSettingsService();

  static SubscriptionBackendService get subscriptionBackendService =>
      _subscriptionBackendService;

  @override
  State<_TemplateFeedItem> createState() => _TemplateFeedItemState();
}

class _TemplateFeedItemState extends State<_TemplateFeedItem>
    with AutomaticKeepAliveClientMixin<_TemplateFeedItem> {
  static const CloudFirstBackgroundRemovalService _backgroundRemovalService =
      CloudFirstBackgroundRemovalService();
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');
  static const List<String> _randomPosterNameFonts = <String>[
    'Pallavi Bold',
    'Pallavi Medium',
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
  bool _forcePlainPosterCapture = false;
  String? _preparedVideoSignature;
  String? _preparedVideoFilePath;
  String? _preparedPlainVideoSignature;
  String? _preparedPlainVideoFilePath;
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
  Set<String> _hiddenDefaultPoliticalProtocolPhotoUrls = const <String>{};
  List<String> _manualPoliticalProtocolPhotoPaths = const <String>[];
  List<PoliticalProtocolSlot>? _politicalProtocolDefaultSlotsOverride;
  List<PoliticalProtocolSlot> _manualPoliticalProtocolSlots =
      const <PoliticalProtocolSlot>[];
  Future<void>? _politicalProtocolPhotoLoadFuture;
  ValueNotifier<List<String>>? _manualProtocolPhotoNotifier;
  ValueNotifier<List<PoliticalProtocolSlot>>? _manualProtocolPhotoSlotNotifier;
  bool _directTrialPurchaseBusy = false;
  int _localViewCountDelta = 0;
  int _localShareCountDelta = 0;
  int _localDownloadCountDelta = 0;
  bool _localViewMarked = false;

  _TemplateItem get item => widget.item;
  BuildContext get hostContext => widget.hostContext;
  AppLanguage get language => widget.language;
  bool get deferRichPosterPreview => widget.deferRichPosterPreview;
  bool get playbackEnabled => widget.playbackEnabled;
  bool get preferUltraLightImage => widget.preferUltraLightImage;
  bool get fillViewport => widget.fillViewport;
  String get _fullScreenHeroTag =>
      'home-poster-preview-${item.templateId?.trim().isNotEmpty == true ? item.templateId!.trim() : Object.hash(item.titleEn, item.imageUrl, item.videoUrl, item.imageAssetPath)}';
  Future<void> Function({bool startPurchaseOnOpen})
  get onOpenSubscriptionPlan => widget.onOpenSubscriptionPlan;
  PosterProfileData get viewerPosterProfile => widget.viewerPosterProfile;
  int get posterRenderCycle => widget.posterRenderCycle;
  SubscriptionBackendService get _subscriptionBackendService =>
      _TemplateFeedItem.subscriptionBackendService;

  void _markLocalViewCounted() {
    if (_localViewMarked) {
      return;
    }
    setState(() {
      _localViewMarked = true;
      _localViewCountDelta = 1;
    });
  }

  void _bumpLocalEngagementCount(String action) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (action == 'share') {
        _localShareCountDelta += 1;
      } else if (action == 'download') {
        _localDownloadCountDelta += 1;
      }
    });
  }

  bool _isCurrentJokesPoster() {
    final signals = <String>{};

    void addSignal(String raw) {
      final normalized = _normalizeTagWorker(raw);
      if (normalized.isEmpty) {
        return;
      }
      signals.add(normalized);
      signals.addAll(_expandCategoryAliasesWorker(normalized));
    }

    addSignal(item.primaryFirestoreCategoryId ?? '');
    addSignal(item.categoryDisplayLabel ?? '');
    for (final tag in item.categoryTags) {
      addSignal(tag);
    }
    return signals.contains('jokes') ||
        signals.contains('funny') ||
        signals.contains('humor') ||
        signals.contains('comedy');
  }

  bool get _canAddPoliticalProtocolPhotos {
    final partyId = _resolvePoliticalPartyId();
    return widget.enablePoliticalProtocolOverlay &&
        !item.isVideo &&
        (item.personalizationConfig?.hasPoliticalProtocolLayout ?? false) &&
        (widget.allowPoliticalProtocolWithoutParty ||
            (partyId != null && partyId.trim().isNotEmpty));
  }

  List<PoliticalParty> get _availablePoliticalParties =>
      widget.politicalParties.isEmpty
      ? politicalParties
      : widget.politicalParties;

  PoliticalParty? _resolvePoliticalParty() {
    final forcedParty = _resolvePoliticalPartyFromId(
      widget.forcedPoliticalProtocolPartyId ?? '',
    );
    if (forcedParty != null) {
      return forcedParty;
    }

    final tags = <String>{
      for (final tag in item.categoryTags) _normalizeTagWorker(tag),
      _normalizeTagWorker(item.primaryFirestoreCategoryId ?? ''),
    }..removeWhere((tag) => tag.isEmpty);
    if (tags.isEmpty) {
      return null;
    }
    for (final party in _availablePoliticalParties) {
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

  PoliticalParty? _resolvePoliticalPartyFromId(String rawId) {
    final normalized = _normalizeTagWorker(rawId);
    if (normalized.isEmpty) {
      return null;
    }
    for (final party in _availablePoliticalParties) {
      final partyId = _normalizeTagWorker(party.id);
      final shortName = _normalizeTagWorker(party.shortName);
      if (normalized == partyId ||
          normalized == 'party_$partyId' ||
          (shortName.isNotEmpty && normalized == shortName) ||
          (shortName.isNotEmpty && normalized == 'party_$shortName')) {
        return party;
      }
    }
    return null;
  }

  String? _resolvePoliticalPartyLogoAssetPath() {
    final party = _resolvePoliticalParty();
    if (party == null) {
      return null;
    }
    final overrideUrl =
        widget.partyLogoOverridesByPartyId[party.id]?.trim() ?? '';
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    return party.logoAssetPath;
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
        (_politicalProtocolPhotoLoadFuture != null ||
            _politicalProtocolPhotoUrls.isNotEmpty)) {
      return;
    }
    final partyChanged = _politicalProtocolPartyId != partyId;
    _politicalProtocolPartyId = partyId;
    if (partyChanged) {
      _politicalProtocolPhotoUrls = const <String>[];
    }
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

  String _hiddenDefaultProtocolPhotoPrefsKey() {
    final scope = _manualProtocolPhotoScopeKey().trim().isNotEmpty
        ? _manualProtocolPhotoScopeKey().trim()
        : 'political';
    return 'political_hidden_default_protocol_photos_v1_$scope';
  }

  Future<void> _loadHiddenDefaultProtocolPhotoUrls() async {
    if (!widget.enablePoliticalProtocolOverlay) {
      _hiddenDefaultPoliticalProtocolPhotoUrls = const <String>{};
      return;
    }
    final prefsKey = _hiddenDefaultProtocolPhotoPrefsKey();
    try {
      final prefs = await SharedPreferences.getInstance();
      final urls =
          prefs
              .getStringList(prefsKey)
              ?.map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .toSet() ??
          const <String>{};
      if (!mounted || prefsKey != _hiddenDefaultProtocolPhotoPrefsKey()) {
        return;
      }
      setState(() => _hiddenDefaultPoliticalProtocolPhotoUrls = urls);
    } catch (_) {
      // Hidden default protocol photos are optional local preferences.
    }
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
    unawaited(_loadHiddenDefaultProtocolPhotoUrls());
    unawaited(_preloadHomeExportRewardedAdAfterFirstSettledFrames());
    if (playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && playbackEnabled) {
          _markLocalViewCounted();
        }
      });
    }
    if (item.isVideo && playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scheduleVideoWarmupAfterSettledFrames());
      });
    }
  }

  Future<void> _preloadHomeExportRewardedAdAfterFirstSettledFrames() async {
    await Future<void>.delayed(const Duration(seconds: 45));
    if (!mounted) {
      return;
    }
    await _preloadHomeExportRewardedAdIfEnabled();
  }

  Future<void> _scheduleVideoWarmupAfterSettledFrames() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted || !playbackEnabled) {
      return;
    }
    _scheduleVideoWarmup(requireReady: false, allowScrollDeferral: true);
    _scheduleVideoWarmupRetries();
  }

  @override
  void didUpdateWidget(covariant _TemplateFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackEnabled != widget.playbackEnabled) {
      updateKeepAlive();
    }
    if (oldWidget.item.templateId != widget.item.templateId) {
      _localViewCountDelta = 0;
      _localShareCountDelta = 0;
      _localDownloadCountDelta = 0;
      _localViewMarked = false;
    }
    if (!oldWidget.playbackEnabled && widget.playbackEnabled) {
      _markLocalViewCounted();
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
      unawaited(_loadHiddenDefaultProtocolPhotoUrls());
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
          unawaited(_scheduleVideoWarmupAfterSettledFrames());
        });
      }
    } else if (item.isVideo &&
        !oldWidget.playbackEnabled &&
        widget.playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scheduleVideoWarmupAfterSettledFrames());
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
            fontFamily == 'Pallavi Medium' ||
            fontFamily == 'Pallavi Bold');
  }

  CreatorPosterPersonalization _plainPosterPersonalization(
    CreatorPosterPersonalization config,
  ) {
    return CreatorPosterPersonalization(
      photoShape: config.photoShape,
      photoX: config.photoX,
      photoY: config.photoY,
      photoScale: config.photoScale,
      photoAnimation: config.photoAnimation,
      showVideoExtraPhoto: false,
      videoExtraPhotoShape: config.videoExtraPhotoShape,
      videoExtraPhotoRenderMode: config.videoExtraPhotoRenderMode,
      videoExtraPhotoEdgeStyle: config.videoExtraPhotoEdgeStyle,
      videoExtraPhotoAnimation: config.videoExtraPhotoAnimation,
      videoExtraPhotoX: config.videoExtraPhotoX,
      videoExtraPhotoY: config.videoExtraPhotoY,
      videoExtraPhotoScale: config.videoExtraPhotoScale,
      nameX: config.nameX,
      nameY: config.nameY,
      showBottomStrip: false,
      stripHeight: config.stripHeight,
      stripWidth: config.stripWidth,
      stripX: config.stripX,
      stripBottom: config.stripBottom,
      showWhatsapp: false,
      sampleName: config.sampleName,
      nameScale: config.nameScale,
      showStyledNameStrip: false,
      showStyledDesignationStrip: false,
      sampleDesignation: config.sampleDesignation,
      designationScale: config.designationScale,
      phoneScale: config.phoneScale,
      nameStripColor: config.nameStripColor,
      designationStripColor: config.designationStripColor,
      stripLayoutStyle: config.stripLayoutStyle,
      boardVariant: config.boardVariant,
      photoRenderMode: config.photoRenderMode,
      edgeStyle: config.edgeStyle,
      showSafeAreas: false,
      showPoliticalProtocol: false,
      politicalProtocolX: config.politicalProtocolX,
      politicalProtocolY: config.politicalProtocolY,
      politicalProtocolScale: config.politicalProtocolScale,
      politicalProtocolSlots: config.politicalProtocolSlots,
      politicalProtocolEnabledAtMillis: 0,
    );
  }

  String _posterSignature({
    required bool isPhotoVisible,
    bool plainPersonalization = false,
  }) {
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
    return '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${item.videoUrl ?? ''}-${item.mediaType}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-${viewerPosterProfile.preferOriginalPersonalPhoto}-${_photoUserAdjustment.flipHorizontally}-${_photoUserAdjustment.xOffsetPercent.toStringAsFixed(2)}-${_photoUserAdjustment.yOffsetPercent.toStringAsFixed(2)}-${_extraPhotoSelection?.originalPhotoPath ?? ''}-${_extraPhotoSelection?.cutoutPhotoPath ?? ''}-protocol$protocolPhotoSignature-$protocolSlotSignature-strip$_stripGradientTapOffset-$posterRenderCycle-$isPhotoVisible-plain$plainPersonalization';
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
    _preparedPlainVideoSignature = null;
    _preparedPlainVideoFilePath = null;
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

  Future<void> _ensureBackgroundRemovalReady() {
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
      await _ensureBackgroundRemovalReady();
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
                        telugu: 'బ్యాక్‌గ్రౌండ్ తొలగిస్తున్నాము...',
                        english: 'Removing background...',
                        hindi: 'पृष्ठभूमि हटाई जा रही है...',
                        tamil: 'பின்னணி நீக்கப்படுகிறது...',
                        kannada: 'ಹಿನ್ನೆಲೆಯನ್ನು ತೆಗೆದುಹಾಕಲಾಗುತ್ತಿದೆ...',
                        malayalam: 'പശ്ചാത്തലം നീക്കംചെയ്യുന്നു...',
                        marathi: 'पार्श्वभूमी काढली जात आहे...',
                        gujarati: 'પૃષ્ઠભૂમિ દૂર કરી રહ્યાં છીએ...',
                        bengali: 'ব্যাকগ্রাউন্ড সরানো হচ্ছে...',
                        punjabi: 'ਪਿਛੋਕੜ ਹਟਾਇਆ ਜਾ ਰਿਹਾ ਹੈ...',
                        odia: 'ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଯାଉଛି...',
                        assamese: 'পৃষ্ঠভূমি আঁতৰোৱা হৈছে...',
                        konkani: 'फाटभुंय काडटात...',
                        nepali: 'पृष्ठभूमि हटाइँदैछ...',
                        meitei: 'বেকগ্রাউন্দ লৌথোকপগী থবক চত্থরি...',
                        mizo: 'Background paih mek a ni...',
                        kashmiri: 'پس منظر چُھ ہٹاونہٕ یِوان...',
                        ladakhi: 'རྒྱབ་ལྗོངས་བསུབ་བཞིན་པ...',
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
              telugu: 'ఫోటో కత్తిరించండి',
              english: 'Crop Photo',
              hindi: 'फ़ोटो क्रॉप करें',
              tamil: 'புகைப்படத்தை செதுக்கு',
              kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'फोटो क्रॉप करा',
              gujarati: 'ફોટો ક્રોપ કરો',
              bengali: 'ছবি ক্রপ করুন',
              punjabi: 'ਫੋਟੋ ਕੱਟੋ',
              odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'ফটো ক্ৰপ কৰক',
              konkani: 'फोटो क्रॉप करा',
              nepali: 'फोटो क्रप गर्नुहोस्',
              meitei: 'ফোতো ক্রপ তৌবীয়ু',
              mizo: 'Thlalak tan rawh',
              kashmiri: 'فوٹو کٹ کرِو',
              ladakhi: 'པར་བཅད་ཏེ་བཟོས།',
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
              telugu: 'ఫోటో కత్తిరించండి',
              english: 'Crop Photo',
              hindi: 'फ़ोटो क्रॉप करें',
              tamil: 'புகைப்படத்தை செதுக்கு',
              kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'फोटो क्रॉप करा',
              gujarati: 'ફોટો ક્રોપ કરો',
              bengali: 'ছবি ক্রপ করুন',
              punjabi: 'ਫੋਟੋ ਕੱਟੋ',
              odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'ফটো ক্ৰপ কৰক',
              konkani: 'फोटो क्रॉप करा',
              nepali: 'फोटो क्रप गर्नुहोस्',
              meitei: 'ফোতো ক্রপ তৌবীয়ু',
              mizo: 'Thlalak tan rawh',
              kashmiri: 'فوٹو کٹ کرِو',
              ladakhi: 'པར་བཅད་ཏེ་བཟོས།',
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
                'ఫోటో జోడించాం, కానీ background remove పూర్తిగా కాలేదు. ప్రస్తుతానికి అసలు ఫోటోనే ఉపయోగిస్తున్నాం.',
            english:
                'Photo was added, but background removal did not complete. Using the original photo for now.',
            hindi:
                'फ़ोटो जोड़ी गई, लेकिन पृष्ठभूमि पूरी तरह नहीं हट सकी। फ़िलहाल मूल फ़ोटो का उपयोग किया जा रहा है।',
            tamil:
                'புகைப்படம் சேர்க்கப்பட்டது, ஆனால் பின்னணி நீக்கம் முழுமையடையவில்லை. இப்போதைக்கு அசல் புகைப்படம் பயன்படுத்தப்படுகிறது.',
            kannada:
                'ಫೋಟೋ ಸೇರಿಸಲಾಗಿದೆ, ಆದರೆ ಹಿನ್ನೆಲೆ ತೆಗೆದುಹಾಕುವಿಕೆ ಪೂರ್ಣಗೊಂಡಿಲ್ಲ. ಸದ್ಯಕ್ಕೆ ಮೂಲ ಫೋಟೋವನ್ನೇ ಬಳಸಲಾಗುತ್ತಿದೆ.',
            malayalam:
                'ഫോട്ടോ ചേർത്തു, എന്നാൽ പശ്ചാത്തലം നീക്കംചെയ്യൽ പൂർത്തിയായില്ല. തൽക്കാലം യഥാർത്ഥ ഫോട്ടോ ഉപയോഗിക്കുന്നു.',
            marathi:
                'फोटो जोडला गेला, परंतु पार्श्वभूमी काढणे पूर्ण झाले नाही. सध्या मूळ फोटो वापरत आहोत.',
            gujarati:
                'ફોટો ઉમેરાયો, પરંતુ પૃષ્ઠભૂમિ દૂર કરવાની પ્રક્રિયા પૂર્ણ થઈ નથી. હમણાં માટે મૂળ ફોટો વાપરી રહ્યાં છીએ.',
            bengali:
                'ফটো যোগ করা হয়েছে, তবে ব্যাকগ্রাউন্ড অপসারণ সম্পন্ন হয়নি। আপাতত আসল ছবিটি ব্যবহার করা হচ্ছে।',
            punjabi:
                'ਫੋਟੋ ਸ਼ਾਮਲ ਕੀਤੀ ਗਈ, ਪਰ ਪਿਛੋਕੜ ਹਟਾਉਣਾ ਪੂਰਾ ਨਹੀਂ ਹੋਇਆ। ਫਿਲਹਾਲ ਅਸਲ ਫੋਟੋ ਦੀ ਵਰਤੋਂ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ।',
            odia:
                'ଫଟୋ ଯୋଡ଼ାଗଲା, କିନ୍ତୁ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଇବା ସମ୍ପୂର୍ଣ୍ଣ ହେଲାନାହିଁ। ବର୍ତ୍ତମାନ ପାଇଁ ମୂଳ ଫଟୋ ବ୍ୟବହାର କରାଯାଉଛି।',
            assamese:
                'ফটো যোগ কৰা হ’ল, কিন্তু পটভূমি আঁতৰোৱা সম্পূৰ্ণ নহ’ল। বৰ্তমানৰ বাবে মূল ফটোখন ব্যৱহাৰ কৰা হৈছে।',
            konkani:
                'फोटो जोडलो, पूण फाटभुंय काडपाचें काम पूर्ण जावंक ना. सध्या मूळ फोटोच वापरतात.',
            nepali:
                'फोटो थपियो, तर पृष्ठभूमि हटाउने काम पूरा भएन। हालको लागि मूल तस्विर नै प्रयोग गरिँदैछ।',
            meitei:
                'ফোতো হাপচিনখ্রে, অদুবু বেকগ্রাউন্দ লৌথোকপা লোইশিনবা ঙমদ্রে। হৌজিক্কীদি অশেংবা ফোতো শীজিন্নরি।',
            mizo:
                'Thlalak dah a ni a, mahse background paih a la zo lo. Tun atan chuan thlalak tak tak zawk hman rih a ni.',
            kashmiri:
                'فوٹو آو رَلاونہٕ، مگر پس منظر ہٹاونُک کٲم گوو نہٕ پوٗرٕ। وۄنؠ تام چُھ اصل فوٹو اِستعمال گژھان۔',
            ladakhi:
                'པར་བསྣན་ཟིན། འོན་ཀྱང་རྒྱབ་ལྗོངས་བསུབ་རྒྱུ་མ་རྫོགས། ད་ལྟའི་ཆེད་དུ་པར་ངོ་མ་དེ་བེད་སྤྱོད་གཏོང་བཞིན་ཡོད།',
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
            hindi: 'अतिरिक्त फ़ोटो नहीं जोड़ी जा सकी।',
            tamil: 'கூடுதல் புகைப்படத்தைச் சேர்க்க முடியவில்லை.',
            kannada: 'ಹೆಚ್ಚುವರಿ ಫೋಟೋ ಸೇರಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
            malayalam: 'കൂടുതൽ ഫോട്ടോ ചേർക്കാനായില്ല.',
            marathi: 'अतिरिक्त फोटो जोडता आला नाही.',
            gujarati: 'વધારાનો ફોટો ઉમેરી શકાયો નથી.',
            bengali: 'অতিরিক্ত ছবি যোগ করা যায়নি।',
            punjabi: 'ਵਾਧੂ ਫੋਟੋ ਸ਼ਾਮਲ ਨਹੀਂ ਕੀਤੀ ਜਾ ਸਕੀ।',
            odia: 'ଅତିରିକ୍ତ ଫଟୋ ଯୋଡ଼ିବା ସମ୍ଭବ ହେଲାନାହିଁ।',
            assamese: 'অতিৰিক্ত ফটোখন যোগ কৰিব পৰা নগ’ল।',
            konkani: 'अदिक फोटो जोडूंक जालो ना.',
            nepali: 'थप तस्विर थप्न सकिएन।',
            meitei: 'অহেনবা ফোতো হাপচিনবা ঙমদে।',
            mizo: 'Thlalak dang dah belh theih a ni lo.',
            kashmiri: 'اضافی فوٹو ہیٚکہ نہٕ رَلٲوِتھ۔',
            ladakhi: 'པར་འཕར་མ་བསྣན་མ་ཐུབ།',
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
        item.isVideo ||
        !(item.personalizationConfig?.hasPoliticalProtocolLayout ?? false) ||
        (!widget.allowPoliticalProtocolWithoutParty &&
            (partyId == null || partyId.trim().isEmpty))) {
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
              partyLogoAssetPath: _resolvePoliticalPartyLogoAssetPath(),
              showDefaultProtocolPhotos:
                  item.personalizationConfig?.hasPoliticalProtocolLayout ??
                  false,
              initialManualPhotoPaths: _manualPoliticalProtocolPhotoPaths,
              initialHiddenDefaultPhotoUrls:
                  _hiddenDefaultPoliticalProtocolPhotoUrls,
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
      _hiddenDefaultPoliticalProtocolPhotoUrls = result.hiddenDefaultPhotoUrls;
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
    final primaryDesignation = isBusinessProfile
        ? viewerPosterProfile.businessTagline.trim()
        : viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : viewerPosterProfile.secondaryPersonalDesignation;
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final primaryDesignationFontFamily = _resolveDesignationFontFamily(
      primaryDesignation,
    );
    final secondaryDesignationFontFamily = _resolveDesignationFontFamily(
      secondaryDesignation,
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
          primaryDesignation,
          primaryDesignationFontFamily,
        ) &&
        TeluguLegacyTextService.cachedValue(
              primaryDesignation,
              fontFamily: primaryDesignationFontFamily,
            ) ==
            null) {
      futures.add(
        TeluguLegacyTextService.convert(
          primaryDesignation,
          fontFamily: primaryDesignationFontFamily,
        ),
      );
    }

    if (secondaryDesignation.isNotEmpty &&
        _shouldConvertForLegacyTelugu(
          secondaryDesignation,
          secondaryDesignationFontFamily,
        ) &&
        TeluguLegacyTextService.cachedValue(
              secondaryDesignation,
              fontFamily: secondaryDesignationFontFamily,
            ) ==
            null) {
      futures.add(
        TeluguLegacyTextService.convert(
          secondaryDesignation,
          fontFamily: secondaryDesignationFontFamily,
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
    bool plainPersonalization = false,
  }) async {
    final requestedPhotoVisible = plainPersonalization
        ? false
        : photoVisibleOverride ?? _showPosterPhotoNotifier.value;
    final signature = _posterSignature(
      isPhotoVisible: requestedPhotoVisible,
      plainPersonalization: plainPersonalization,
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
    final future = () async {
      final originalPhotoVisible = _showPosterPhotoNotifier.value;
      final originalPlainCapture = _forcePlainPosterCapture;
      final shouldTemporarilySwitch =
          requestedPhotoVisible != originalPhotoVisible;
      final shouldTemporarilySwitchPlain =
          plainPersonalization != originalPlainCapture;
      if (shouldTemporarilySwitch) {
        _showPosterPhotoNotifier.value = requestedPhotoVisible;
      }
      if (shouldTemporarilySwitchPlain && mounted) {
        setState(() => _forcePlainPosterCapture = plainPersonalization);
      } else if (shouldTemporarilySwitchPlain) {
        _forcePlainPosterCapture = plainPersonalization;
      }
      if (shouldTemporarilySwitch || shouldTemporarilySwitchPlain) {
        await _settlePosterCaptureFrame();
      }
      try {
        await _doPreparePosterExport(signature);
      } finally {
        var shouldRestoreFrame = false;
        if (shouldTemporarilySwitch) {
          _showPosterPhotoNotifier.value = originalPhotoVisible;
          shouldRestoreFrame = true;
        }
        if (shouldTemporarilySwitchPlain && mounted) {
          setState(() => _forcePlainPosterCapture = originalPlainCapture);
          shouldRestoreFrame = true;
        } else if (shouldTemporarilySwitchPlain) {
          _forcePlainPosterCapture = originalPlainCapture;
          shouldRestoreFrame = true;
        }
        if (shouldRestoreFrame) {
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
    bool isPhotoVisible, {
    bool plainPersonalization = false,
  }) async {
    final signature = _posterSignature(
      isPhotoVisible: isPhotoVisible,
      plainPersonalization: plainPersonalization,
    );
    final existingPath = _preparedPosterFilePath;
    if (_preparedPosterSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      return existingPath;
    }
    await _preparePosterExport(
      photoVisibleOverride: isPhotoVisible,
      plainPersonalization: plainPersonalization,
    );
    final refreshedPath = _preparedPosterFilePath;
    if (refreshedPath != null && await File(refreshedPath).exists()) {
      return refreshedPath;
    }
    return null;
  }

  Future<String?> _ensurePreparedPlainPosterFile() async {
    return _ensurePreparedPosterFileForVisibility(
      false,
      plainPersonalization: true,
    );
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

  Future<String?> _ensurePreparedPlainVideoFile() async {
    final videoUrl = item.videoUrl?.trim() ?? '';
    if (!item.isVideo || videoUrl.isEmpty) {
      return null;
    }
    final personalization = item.personalizationConfig;
    if (personalization == null) {
      return _ensurePreparedVideoFile();
    }
    final plainPersonalization = _plainPosterPersonalization(personalization);
    final signature = _posterSignature(
      isPhotoVisible: false,
      plainPersonalization: true,
    );
    final existingPath = _preparedPlainVideoFilePath;
    if (_preparedPlainVideoSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      return existingPath;
    }
    try {
      final outputPath = await const PersonalizedVideoExportService().export(
        videoUrl: videoUrl,
        profile: viewerPosterProfile,
        personalization: plainPersonalization,
        language: language,
        title: item.titleFor(language),
        previewSeed: item.imageUrl ?? item.imageAssetPath ?? 'poster',
        stripGradientTapOffset: _stripGradientTapOffset,
      );
      _preparedPlainVideoSignature = signature;
      _preparedPlainVideoFilePath = outputPath;
      return outputPath;
    } catch (error, stackTrace) {
      _homeDebugLogStack('plain video export failed: $error', stackTrace);
      return null;
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

  bool _isAuthenticated() {
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

  Future<bool> _ensureAuthenticatedForPosterAction(
    BuildContext context, {
    required String actionLabel,
  }) async {
    if (_isAuthenticated()) {
      return true;
    }
    final messenger = ScaffoldMessenger.of(context);
    _showSnack(
      messenger,
      context.strings.localized(
        telugu: '$actionLabel చేయడానికి ముందుగా లాగిన్ చేయండి.',
        english: 'Please login before $actionLabel.',
        hindi: '$actionLabel करने से पहले कृपया लॉगिन करें।',
        tamil: '$actionLabel செய்வதற்கு முன் உள்நுழையவும்.',
        kannada: '$actionLabel ಮಾಡುವ ಮೊದಲು ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ.',
        malayalam: '$actionLabel ചെയ്യുന്നതിന് മുമ്പ് ദയവായി ലോഗിൻ ചെയ്യുക.',
        marathi: '$actionLabel करण्यापूर्वी कृपया लॉगिन करा.',
        gujarati: '$actionLabel કરતાં પહેલાં કૃપા કરીને લૉગિન કરો.',
        bengali: '$actionLabel করার আগে অনুগ্রহ করে লগইন করুন।',
        punjabi: '$actionLabel ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਕਿਰਪਾ ਕਰਕੇ ਲਾਗਇਨ ਕਰੋ।',
        odia: '$actionLabel କରିବା ପୂର୍ବରୁ ଦୟାକରି ଲଗଇନ୍ କରନ୍ତୁ।',
        assamese: '$actionLabel কৰাৰ আগতে অনুগ্ৰহ কৰি লগইন কৰক।',
        konkani: '$actionLabel करचे पयलीं उपकार करून लॉगिन करात.',
        nepali: '$actionLabel गर्नु अघि कृपया लगइन गर्नुहोस्।',
        meitei: '$actionLabel তৌদ্রিঙৈ মমাংদা চানবীদুনা লগইন তৌবীয়ু।',
        mizo: '$actionLabel hmain khawngaihin lut rawh.',
        kashmiri: '$actionLabel کرنہٕ برٛونٛہہ مہر Ships کٔرِتھ کٔرِو لاگ اِن۔',
        ladakhi: '$actionLabel མ་བྱས་གོང་སྐུ་མཁྱེན་ནང་འཛུལ་གནང་།',
      ),
    );
    await Navigator.of(context).pushNamed(AppRoutes.login);
    return false;
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
    await _precacheCurrentPoliticalProtocolPhotos();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _precacheCurrentPosterImage() async {
    if (item.isVideo) {
      return;
    }
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null || !posterContext.mounted) {
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
    if (posterContext == null || !posterContext.mounted) {
      return;
    }
    final imageProvider = PosterProfileService.resolveImageProvider(
      viewerPosterProfile,
      preferOriginalPersonalPhoto:
          item.personalizationConfig?.photoRenderMode == 'original' ||
          viewerPosterProfile.preferOriginalPersonalPhoto,
      allowOriginalFallbackWhenCutoutUnavailable: true,
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

  Future<void> _precacheCurrentPoliticalProtocolPhotos() async {
    final personalizationConfig = item.personalizationConfig;
    if (!widget.enablePoliticalProtocolOverlay ||
        personalizationConfig == null ||
        !personalizationConfig.hasPoliticalProtocolLayout) {
      return;
    }
    final pendingDefaultPhotos = _politicalProtocolPhotoLoadFuture;
    if (pendingDefaultPhotos != null) {
      try {
        await pendingDefaultPhotos.timeout(const Duration(seconds: 2));
      } catch (_) {
        // Best effort: manual photos and already loaded defaults can still export.
      }
    }
    final defaultUrls = _politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .where(
          (url) =>
              url.isNotEmpty &&
              !_hiddenDefaultPoliticalProtocolPhotoUrls.contains(url),
        )
        .take(personalizationConfig.politicalProtocolSlots.length)
        .toList(growable: false);
    final manualPaths = _manualPoliticalProtocolPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    await _precachePoliticalProtocolPhotoProviders(
      defaultUrls: defaultUrls,
      manualPaths: manualPaths,
    );
  }

  Future<void> _precachePoliticalProtocolPhotoProviders({
    required List<String> defaultUrls,
    required List<String> manualPaths,
  }) async {
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null || !posterContext.mounted) {
      return;
    }
    final futures = <Future<void>>[
      for (final url in defaultUrls)
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: PosterNetworkImageCache.instance,
          ),
          posterContext,
        ),
      for (final path in manualPaths)
        precacheImage(FileImage(File(path)), posterContext),
    ];
    if (futures.isEmpty) {
      return;
    }
    try {
      await Future.wait(futures).timeout(const Duration(seconds: 4));
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster protocol photos precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack(
        'poster protocol photos precache skipped: $error',
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
    bool? playbackEnabledOverride,
    bool enableFullScreenTap = true,
    bool personalizationEnabled = true,
  }) {
    final sourcePersonalizationConfig = item.personalizationConfig;
    final personalizationConfig =
        personalizationEnabled || sourcePersonalizationConfig == null
        ? sourcePersonalizationConfig
        : _plainPosterPersonalization(sourcePersonalizationConfig);
    final renderOriginalPosterQuality = item.preferOriginalPosterQuality;
    final effectivePlaybackEnabled = playbackEnabledOverride ?? playbackEnabled;
    final fullScreenTap = enableFullScreenTap ? _openFullScreenPreview : null;
    final effectiveShowProfilePhoto = personalizationEnabled && isPhotoVisible;
    final effectiveShowPoliticalProtocol =
        personalizationEnabled && widget.enablePoliticalProtocolOverlay;
    final effectiveAdditionalPhotoSelection = personalizationEnabled
        ? _extraPhotoSelection
        : null;
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
                        playbackEnabled: effectivePlaybackEnabled,
                        imageAssetPath: item.imageAssetPath,
                        imageUrl: item.imageUrl,
                        imageStoragePath: item.imageStoragePath,
                        thumbnailStoragePath: item.thumbnailStoragePath,
                        thumbnailUrl: item.thumbnailUrl,
                        onAspectRatioResolved:
                            _handlePreviewAspectRatioResolved,
                        onReady: onReady,
                        onOpenPreview: fullScreenTap,
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
                  partyLogoAssetPath: widget.showPartyLogoInNameChip
                      ? _resolvePoliticalPartyLogoAssetPath()
                      : null,
                  politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
                  hiddenPoliticalProtocolPhotoUrls:
                      _hiddenDefaultPoliticalProtocolPhotoUrls,
                  politicalProtocolLocalPhotoPaths:
                      _manualPoliticalProtocolPhotoPaths,
                  politicalProtocolSlotsOverride:
                      _politicalProtocolDefaultSlotsOverride,
                  politicalProtocolManualSlots: _manualPoliticalProtocolSlots,
                  showPoliticalProtocolOverlay: effectiveShowPoliticalProtocol,
                  showProfilePhoto: effectiveShowProfilePhoto,
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
                  additionalPhotoSelection: effectiveAdditionalPhotoSelection,
                  onAdditionalPhotoTap:
                      personalizationEnabled &&
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
                  playbackEnabled: effectivePlaybackEnabled,
                  imageAssetPath: item.imageAssetPath,
                  imageUrl: item.imageUrl,
                  imageStoragePath: item.imageStoragePath,
                  thumbnailStoragePath: item.thumbnailStoragePath,
                  thumbnailUrl: item.thumbnailUrl,
                  onAspectRatioResolved: _handlePreviewAspectRatioResolved,
                  onReady: () => onPosterReadyChanged?.call(true),
                  onOpenPreview: fullScreenTap,
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
            partyLogoAssetPath: widget.showPartyLogoInNameChip
                ? _resolvePoliticalPartyLogoAssetPath()
                : null,
            politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
            hiddenPoliticalProtocolPhotoUrls:
                _hiddenDefaultPoliticalProtocolPhotoUrls,
            politicalProtocolLocalPhotoPaths:
                _manualPoliticalProtocolPhotoPaths,
            politicalProtocolSlotsOverride:
                _politicalProtocolDefaultSlotsOverride,
            politicalProtocolManualSlots: _manualPoliticalProtocolSlots,
            showPoliticalProtocolOverlay: effectiveShowPoliticalProtocol,
            showProfilePhoto: effectiveShowProfilePhoto,
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
            additionalPhotoSelection: effectiveAdditionalPhotoSelection,
            onAdditionalPhotoTap:
                personalizationEnabled &&
                    personalizationConfig.showVideoExtraPhoto
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
    final plainCapture =
        _forcePlainPosterCapture || (!item.isVideo && _isCurrentJokesPoster());
    final preview = _buildPosterPreview(
      isPhotoVisible: plainCapture ? false : isPhotoVisible,
      onPosterReadyChanged: onPosterReadyChanged,
      personalizationEnabled: !plainCapture,
    );
    final framedPreview = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: deferRichPosterPreview
          ? null
          : (widget.onPreviewTap ?? _openFullScreenPreview),
      child: Hero(
        tag: _fullScreenHeroTag,
        transitionOnUserGestures: true,
        child: Material(type: MaterialType.transparency, child: preview),
      ),
    );
    final captureContent = plainCapture
        ? Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              framedPreview,
              Positioned(
                right: 10,
                bottom: 10,
                child: IgnorePointer(child: _buildPlainPosterWatermark()),
              ),
            ],
          )
        : framedPreview;
    if (deferRichPosterPreview) {
      return KeyedSubtree(key: _posterCaptureKey, child: captureContent);
    }
    return KeyedSubtree(
      key: _posterCaptureKey,
      child: Screenshot(
        controller: _posterScreenshotController,
        child: captureContent,
      ),
    );
  }

  Widget _buildPlainPosterWatermark() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.96)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(
              child: Image.asset(
                'assets/branding/mana_poster_logo.png',
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Mana Poster Ai',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
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

  void _showDownloadSuccessSnack(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.showTopSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.asset(
                  'assets/branding/mana_poster_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F9F6E),
        elevation: 10,
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.down,
        clipBehavior: Clip.hardEdge,
      ),
    );
  }

  void _showFullScreenDownloadSuccessToast(
    BuildContext context,
    String message,
  ) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showDownloadSuccessSnack(ScaffoldMessenger.of(context), message);
      return;
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.paddingOf(context).top + 14;
        return Positioned(
          top: topPadding,
          left: 14,
          right: 14,
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0F9F6E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/branding/mana_poster_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    Timer(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
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

  Future<bool> _startDirectTrialPurchaseFromFreeExportChoice() async {
    if (_directTrialPurchaseBusy || !mounted) {
      return false;
    }
    setState(() => _directTrialPurchaseBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final purchaseGateway = InAppPurchaseGateway();
    try {
      await purchaseGateway.initialize();
      if (!mounted) {
        return false;
      }
      final outcome = await purchaseGateway.purchaseMonthlyPro();
      if (!mounted) {
        return false;
      }

      if (outcome.result != PurchaseFlowResult.success ||
          outcome.evidence == null) {
        if (outcome.result != PurchaseFlowResult.cancelled) {
          _showSnack(messenger, _directTrialPurchaseMessage(outcome.result));
        }
        if (mounted) {
          setState(() => _directTrialPurchaseBusy = false);
        }
        await showSubscriptionExitVideoPromptIfAvailable(
          context,
          onSubscribe: (_) => _startDirectTrialPurchaseFromFreeExportChoice(),
        );
        return false;
      }

      final verification = await _verifyDirectTrialPurchaseWithRetry(
        outcome.evidence!,
      );
      if (!mounted) {
        return false;
      }
      if (!verification.hasAccess) {
        _showSnack(
          messenger,
          verification.message?.trim().isNotEmpty == true
              ? verification.message!.trim()
              : context.strings.localized(
                  telugu: 'సబ్‌స్క్రిప్షన్ ధృవీకరణ విఫలమైంది',
                  english: 'Subscription verification failed',
                  hindi: 'सदस्यता सत्यापन विफल रहा',
                  tamil: 'சந்தா சரிபார்ப்பு தோல்வியடைந்தது',
                  kannada: 'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆ ವಿಫಲವಾಗಿದೆ',
                  malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ സ്ഥിരീകരണം പരാജയപ്പെട്ടു',
                  marathi: 'सदस्यता पडताळणी अयशस्वी',
                  gujarati: 'સબ્સ્ક્રિપ્શન ચકાસણી નિષ્ફળ',
                  bengali: 'সাবস্ক্রিপশন যাচাইকরণ ব্যর্থ হয়েছে',
                  punjabi: 'ਗਾਹਕੀ ਤਸਦੀਕ ਅਸਫਲ ਰਹੀ',
                  odia: 'ସବସ୍କ୍ରିପସନ୍ ଯାଞ୍ଚ ବିଫଳ ହେଲା',
                  assamese: 'চাবস্ক্ৰিপচন পৰীক্ষণ ব্যৰ্থ হ’ল',
                  konkani: 'वर्गणी पडताळणी जावंक ना',
                  nepali: 'सदस्यता प्रमाणीकरण असफल भयो',
                  meitei: 'সবস্ক্রিপসন চেকিং তৌবা য়ামদে',
                  mizo: 'Subscription nemngheh a hlawhchham',
                  kashmiri: 'سبسکرپشن تصدیٖق گژھنس منٛز ناکام',
                  ladakhi: 'མངགས་ཉོ་བདེན་དཔང་མ་ཐུབ།',
                ),
        );
        if (mounted) {
          setState(() => _directTrialPurchaseBusy = false);
        }
        await showSubscriptionExitVideoPromptIfAvailable(
          context,
          onSubscribe: (_) => _startDirectTrialPurchaseFromFreeExportChoice(),
        );
        return false;
      }

      await outcome.evidence!.completeStorePurchase();
      final refreshed = await _subscriptionBackendService
          .fetchFreshEntitlementWithRetry();
      if (!mounted) {
        return false;
      }
      await _showSubscriptionThanksVideoPromptOnceFromHome(
        refreshed.hasAccess ? refreshed : verification,
      );
      return true;
    } finally {
      if (mounted) {
        setState(() => _directTrialPurchaseBusy = false);
      }
    }
  }

  Future<SubscriptionBackendResult> _verifyDirectTrialPurchaseWithRetry(
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
      if (lastResult.hasAccess) {
        return lastResult;
      }
    }
    return lastResult ??
        const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Subscription verification failed',
        );
  }

  String _directTrialPurchaseMessage(PurchaseFlowResult result) {
    return switch (result) {
      PurchaseFlowResult.pending => context.strings.localized(
        telugu: 'చెల్లింపు పెండింగ్‌లో ఉంది',
        english: 'Payment is pending',
        hindi: 'भुगतान लंबित है',
        tamil: 'பணம் செலுத்துதல் நிலுவையில் உள்ளது',
        kannada: 'ಪಾವತಿ ಬಾಕಿ ಇದೆ',
        malayalam: 'പേയ്‌മെന്റ് തീർപ്പുകൽപ്പിച്ചിട്ടില്ല',
        marathi: 'पेमेंट प्रलंबित आहे',
        gujarati: 'ચુકવણી બાકી છે',
        bengali: 'পেমেন্ট মুলতুবি রয়েছে',
        punjabi: 'ਭੁਗਤਾਨ ਬਕਾਇਆ ਹੈ',
        odia: 'ପେମେଣ୍ଟ୍ ବାକି ଅଛି',
        assamese: 'পৰিশোধ বাকী আছে',
        konkani: 'पेमेंट उरलां',
        nepali: 'भुक्तानी विचाराधीन छ',
        meitei: 'থিবগী থবক লেমহৌরি',
        mizo: 'Pawisa chawi a la pending',
        kashmiri: 'ادائیگی چھِ پینڈِنگ',
        ladakhi: 'དངུལ་སྤྲོད་སྒུག་བཞིན་པ།',
      ),
      PurchaseFlowResult.billingUnavailable => context.strings.localized(
        telugu: 'బిల్లింగ్ సేవ అందుబాటులో లేదు',
        english: 'Billing service is unavailable',
        hindi: 'बिलिंग सेवा उपलब्ध नहीं है',
        tamil: 'பில்லிங் சேவை கிடைக்கவில்லை',
        kannada: 'ಬಿಲ್ಲಿಂಗ್ ಸೇವೆ ಲಭ್ಯವಿಲ್ಲ',
        malayalam: 'ബില്ലിംഗ് സേവനം ലഭ്യമല്ല',
        marathi: 'बिलिंग सेवा उपलब्ध नाही',
        gujarati: 'બિલિંગ સેવા ઉપલબ્ધ નથી',
        bengali: 'বিলিং পরিষেবা অনুপলব্ধ',
        punjabi: 'ਬਿਲਿੰਗ ਸੇਵਾ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
        odia: 'ବିଲିଂ ସେବା ଉପଲବ୍ଧ ନାହିଁ',
        assamese: 'বিলিং সেৱা উপলব্ধ নহয়',
        konkani: 'बिलिंग सेवा उपलब्ध ना',
        nepali: 'बिलिङ सेवा उपलब्ध छैन',
        meitei: 'বিলিং সর্ভিস ফংদে',
        mizo: 'Billing service a awm lo',
        kashmiri: 'بلِنگ سٔروِس چھُنہٕ دستیاب',
        ladakhi: 'དངུལ་རྩིས་ཞབས་ཞུ་མི་འདུག',
      ),
      PurchaseFlowResult.productNotFound => context.strings.localized(
        telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్ కనుగొనబడలేదు',
        english: 'Subscription plan was not found',
        hindi: 'सदस्यता योजना नहीं मिली',
        tamil: 'சந்தா திட்டம் கிடைக்கவில்லை',
        kannada: 'ಚಂದಾದಾರಿಕೆ ಯೋಜನೆ ಕಂಡುಬಂದಿಲ್ಲ',
        malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ പ്ലാൻ കണ്ടെത്തിയില്ല',
        marathi: 'सदस्यता योजना आढळली नाही',
        gujarati: 'સબ્સ્ક્રિપ્શન પ્લાન મળ્યો નથી',
        bengali: 'সাবস্ক্রিপশন প্ল্যান পাওয়া যায়নি',
        punjabi: 'ਗਾਹਕੀ ਪਲਾਨ ਨਹੀਂ ਮਿਲਿਆ',
        odia: 'ସବସ୍କ୍ରିପସନ୍ ପ୍ଲାନ୍ ମିଳିଲା ନାହିଁ',
        assamese: 'চাবস্ক্ৰিপচন প্লেন পোৱা নগ’ল',
        konkani: 'वर्गणी प्लॅन मेळ्ळो ना',
        nepali: 'सदस्यता योजना फेला परेन',
        meitei: 'সবস্ক্রিপসন প্লান ফংদে',
        mizo: 'Subscription plan hmuh a ni lo',
        kashmiri: 'سبسکرپشن پلان آو نہٕ لَبنہٕ',
        ladakhi: 'མངགས་ཉོའི་འཆར་གཞི་མ་རྙེད།',
      ),
      PurchaseFlowResult.timedOut => context.strings.localized(
        telugu: 'చెల్లింపు సమయం ముగిసింది',
        english: 'Payment timed out',
        hindi: 'भुगतान का समय समाप्त हो गया',
        tamil: 'பணம் செலுத்தும் நேரம் முடிந்தது',
        kannada: 'ಪಾವತಿಯ ಸಮಯ ಮೀರಿದೆ',
        malayalam: 'പേയ്‌മെന്റ് സമയം കഴിഞ്ഞു',
        marathi: 'पेमेंट कालबाह्य झाले',
        gujarati: 'ચુકવણી સમય સમાપ્ત થયો',
        bengali: 'পেমেন্টের সময় শেষ হয়েছে',
        punjabi: 'ਭੁਗਤਾਨ ਦਾ ਸਮਾਂ ਸਮਾਪਤ ਹੋ ਗਿਆ',
        odia: 'ପେମେଣ୍ଟ୍ ସମୟ ସରିଗଲା',
        assamese: 'পৰিশোধৰ সময় উকলিল',
        konkani: 'पेमेंटाचो वेळ सोंपलो',
        nepali: 'भुक्तानी समय समाप्त भयो',
        meitei: 'থিবগী মতম লোইখ্রে',
        mizo: 'Pawisa chawi hun a ral',
        kashmiri: 'ادائیگی ہُنٛد وقت گوو ختم',
        ladakhi: 'དངུལ་སྤྲོད་དུས་ཚོད་རྫོགས།',
      ),
      PurchaseFlowResult.purchaseInProgress => context.strings.localized(
        telugu: 'చెల్లింపు ఇప్పటికే పురోగతిలో ఉంది',
        english: 'Payment is already in progress',
        hindi: 'भुगतान पहले से जारी है',
        tamil: 'பணம் செலுத்துதல் ஏற்கனவே செயல்பாட்டில் உள்ளது',
        kannada: 'ಪಾವತಿ ಈಗಾಗಲೇ ಪ್ರಗತಿಯಲ್ಲಿದೆ',
        malayalam: 'പേയ്‌മെന്റ് ഇതിനകം പുരോഗതിയിലാണ്',
        marathi: 'पेमेंट आधीच प्रगतीपथावर आहे',
        gujarati: 'ચુકવણી પહેલેથી જ પ્રક્રિયામાં છે',
        bengali: 'পেমেন্ট ইতিমধ্যেই প্রক্রিয়াধীন রয়েছে',
        punjabi: 'ਭੁਗਤਾਨ ਪਹਿਲਾਂ ਹੀ ਪ੍ਰਕਿਰਿਆ ਵਿੱਚ ਹੈ',
        odia: 'ପେମେଣ୍ଟ୍ ପୂର୍ବରୁ ପ୍ରକ୍ରିୟାଧୀନ ଅଛି',
        assamese: 'পৰিশোধ ইতিমধ্যে চলি আছে',
        konkani: 'पेमेंट पयलींच चालू आसा',
        nepali: 'भुक्तानी पहिले नै जारी छ',
        meitei: 'থিবগী থবক হান্ননা চত্থরি',
        mizo: 'Pawisa chawi mek a ni',
        kashmiri: 'ادائیگی چھِ گۄڈے جٲری',
        ladakhi: 'དངུལ་སྤྲོད་སྔར་ནས་འགྲོ་བཞིན་ཡོད།',
      ),
      _ => context.strings.localized(
        telugu: 'చెల్లింపు పూర్తి కాలేదు',
        english: 'Payment was not completed',
        hindi: 'भुगतान पूरा नहीं हुआ',
        tamil: 'பணம் செலுத்துதல் பூர்த்தியாகவில்லை',
        kannada: 'ಪಾವತಿ ಪೂರ್ಣಗೊಂಡಿಲ್ಲ',
        malayalam: 'പേയ്‌മെന്റ് പൂർത്തിയായില്ല',
        marathi: 'पेमेंट पूर्ण झाले नाही',
        gujarati: 'ચુકવણી પૂર્ણ થઈ નથી',
        bengali: 'পেমেন্ট সম্পন্ন হয়নি',
        punjabi: 'ਭੁਗਤਾਨ ਪੂਰਾ ਨਹੀਂ ਹੋਇਆ',
        odia: 'ପେମେଣ୍ଟ୍ ସମ୍ପୂର୍ଣ୍ଣ ହେଲାନାହିଁ',
        assamese: 'পৰিশোধ সম্পূৰ্ণ নহ’ল',
        konkani: 'पेमेंट पूर्ण जावंक ना',
        nepali: 'भुक्तानी पूरा भएन',
        meitei: 'থিবগী থবক লোইশিনদে',
        mizo: 'Pawisa chawi a zo lo',
        kashmiri: 'ادائیگی سپٕز نہٕ پوٗرٕ',
        ladakhi: 'དངུལ་སྤྲོད་མ་ཚང་།',
      ),
    };
  }

  Future<void> _showSubscriptionThanksVideoPromptOnceFromHome(
    SubscriptionBackendResult result,
  ) async {
    final identity = _subscriptionThanksPromptIdentity(result);
    if (identity == null) {
      await showSubscriptionThanksVideoPromptIfAvailable(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _subscriptionThanksPromptSeenKey(result);
    if (prefs.getString(key) == identity || !mounted) {
      return;
    }

    await showSubscriptionThanksVideoPromptIfAvailable(context);
    if (!mounted) {
      return;
    }
    await prefs.setString(key, identity);
  }

  String _subscriptionThanksPromptSeenKey(SubscriptionBackendResult result) {
    final authUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final latestOrderId = result.latestOrderId?.trim() ?? '';
    final identityScope = authUid.isNotEmpty ? authUid : latestOrderId;
    final resolvedScope = identityScope.isNotEmpty ? identityScope : 'anon';
    return 'subscription_thanks_video_seen_v1_$resolvedScope';
  }

  String? _subscriptionThanksPromptIdentity(SubscriptionBackendResult result) {
    if (!result.hasAccess) {
      return null;
    }
    final latestOrderId = result.latestOrderId?.trim() ?? '';
    final subscriptionState = result.subscriptionState?.trim() ?? '';
    final startEpoch =
        result.startDate?.millisecondsSinceEpoch.toString() ?? '';
    final expiryEpoch =
        result.expiryTime?.millisecondsSinceEpoch.toString() ?? '';
    final identity = <String>[
      latestOrderId,
      subscriptionState,
      startEpoch,
      expiryEpoch,
    ].where((value) => value.isNotEmpty).join('|');
    return identity.isEmpty ? null : identity;
  }

  Future<bool> _hasSubscriptionAccessForExport() async {
    if (_hasImmediateSubscriptionAccess()) {
      unawaited(_subscriptionBackendService.refreshEntitlementInBackground());
      return true;
    }
    if (!_shouldRunBlockingSubscriptionStatusCheck()) {
      return false;
    }
    return _resolveLatestSubscriptionAccess().timeout(
      SubscriptionPlanConfig.paywallTimeout,
      onTimeout: () async => false,
    );
  }

  String _homePosterShareText() {
    final resolvedUserName = viewerPosterProfile.activeName.trim().isNotEmpty
        ? viewerPosterProfile.activeName.trim()
        : (viewerPosterProfile
                  .resolvedName(language: language)
                  .trim()
                  .isNotEmpty
              ? viewerPosterProfile.resolvedName(language: language).trim()
              : 'User');
    return 'Shared by $resolvedUserName using ${AppPublicInfo.appName}\n'
        'Download the app: ${AppPublicInfo.playStoreUrl}';
  }

  void _recordPosterExportEngagement({required bool isShare}) {
    _bumpLocalEngagementCount(isShare ? 'share' : 'download');
    widget.onInteraction?.call(item, isShare ? 'share' : 'download');
    final posterId = item.templateId?.trim();
    if (posterId == null || posterId.isEmpty) {
      return;
    }
    unawaited(
      ApprovedCreatorTemplateService().incrementPosterEngagementCount(
        posterId: posterId,
        isShare: isShare,
        creatorPublicId: item.creatorPublicId ?? '',
        posterTitle: item.titleEn,
        categoryId: item.primaryFirestoreCategoryId ?? '',
        categoryLabel: item.categoryDisplayLabel ?? '',
      ),
    );
    unawaited(
      UserPosterUploadsService.instance
          .incrementApprovedContributionCountForPoster(
            approvedPosterTemplateId: posterId,
            isShare: isShare,
          ),
    );
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
          hindi: 'गैलरी की अनुमति अस्वीकार कर दी गई।',
          tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
          kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ.',
          malayalam: 'ഗ്യാലറി അനുമതി നിരസിച്ചു.',
          marathi: 'गॅलरी परवानगी नाकारली गेली.',
          gujarati: 'ગૅલેરી પરવાનગી નકારી દેવામાં આવી.',
          bengali: 'গ্যালারির অনুমতি প্রত্যাখ্যান করা হয়েছে।',
          punjabi: 'ਗੈਲਰੀ ਦੀ ਇਜਾਜ਼ਤ ਅਸਵੀਕਾਰ ਕਰ ਦਿੱਤੀ ਗਈ।',
          odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଗଲା।',
          assamese: 'গেলেৰীৰ অনুমতি নাকচ কৰা হ’ল।',
          konkani: 'गॅलरीची परवानगी नाकारली.',
          nepali: 'ग्यालरी अनुमति अस्वीकृत गरियो।',
          meitei: 'গেলরিগী অয়াবা য়াদে।',
          mizo: 'Gallery phalna hnar a ni.',
          kashmiri: 'گیلری ہٕنٛز اِجازت آیہِ مسترد کَرنہٕ۔',
          ladakhi: 'པར་མཛོད་ཆོག་མཆན་ཕྱིར་འཐེན་བྱས།',
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
          telugu: 'ఫైల్ సేవ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'File save failed. Please try again.',
          hindi: 'फ़ाइल सहेजना विफल रहा। कृपया पुनः प्रयास करें।',
          tamil: 'கோப்பைச் சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ಫೈಲ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam:
              'ഫയൽ സൂക്ഷിക്കുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'फाइल सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'ફાઇલ સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali: 'ফাইল সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi:
              'ਫਾਈਲ ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଫାଇଲ୍ ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'ফাইল সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'फायल सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
          nepali: 'फाइल बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'ফাইল সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
          mizo: 'File dahthat a hlawhchham. Khawngaihin ti nawn leh rawh.',
          kashmiri:
              'فائل محفوٗظ کرنس منٛز ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
          ladakhi: 'ཡིག་སྣོད་ཉར་ཚགས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
        );
      default:
        return context.strings.localized(
          telugu: 'డౌన్‌లోడ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'Download failed. Please try again.',
          hindi: 'डाउनलोड विफल रहा। कृपया पुनः प्रयास करें।',
          tamil: 'பதிவிறக்கம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'ഡൗൺലോഡ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'डाउनलोड अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'ડાઉનલોડ નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali: 'ডাউনলোড ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi: 'ਡਾਊਨਲੋਡ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଡାଉନଲୋଡ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'ডাউনলোড ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'डाऊनलोड जावंक ना. उपकार करून परत यत्न करा.',
          nepali: 'डाउनलोड असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'দাউনলোদ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
          mizo: 'Download a hlawhchham. Khawngaihin ti nawn leh rawh.',
          kashmiri: 'ڈاؤنلوڈ گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
          ladakhi: 'ཕབ་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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
                              'సబ్‌స్క్రిప్షన్ స్థితిని తనిఖీ చేస్తున్నాము...',
                          english: 'Checking subscription status...',
                          hindi: 'सदस्यता स्थिति की जाँच की जा रही है...',
                          tamil: 'சந்தா நிலை சரிபார்க்கப்படுகிறது...',
                          kannada:
                              'ಚಂದಾದಾರಿಕೆ ಸ್ಥಿತಿಯನ್ನು ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
                          malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ നില പരിശോധിക്കുന്നു...',
                          marathi: 'सदस्यता स्थिती तपासत आहे...',
                          gujarati: 'સબ્સ્ક્રિપ્શન સ્થિતિ તપાસી રહ્યાં છીએ...',
                          bengali: 'সাবস্ক্রিপশনের স্থিতি পরীক্ষা করা হচ্ছে...',
                          punjabi: 'ਗਾਹਕੀ ਸਥਿਤੀ ਦੀ ਜਾਂਚ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ...',
                          odia: 'ସବସ୍କ୍ରିପସନ୍ ସ୍ଥିତି ଯାଞ୍ଚ କରାଯାଉଛି...',
                          assamese: 'চাবস্ক্ৰিপচনৰ স্থিতি পৰীক্ষা কৰা হৈছে...',
                          konkani: 'वर्गणी स्थिती तपासतात...',
                          nepali: 'सदस्यता स्थिति जाँच गरिँदैछ...',
                          meitei: 'সবস্ক্রিপসন ফীভম য়েংশিল্লি...',
                          mizo: 'Subscription dinhmun en dik mek a ni...',
                          kashmiri: 'سبسکرپشن کِس حالَتُک جائزہ نِوان...',
                          ladakhi: 'མངགས་ཉོའི་གནས་སྟངས་ཞིབ་བཤེར་བྱེད་བཞིན་པ...',
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
                        marathi: 'रद्द करा',
                        gujarati: 'રદ કરો',
                        bengali: 'বাতিল',
                        punjabi: 'ਰੱਦ ਕਰੋ',
                        odia: 'ବାତିଲ୍ କରନ୍ତୁ',
                        assamese: 'বাতিল কৰক',
                        konkani: 'रद्द करा',
                        nepali: 'रद्द गर्नुहोस्',
                        meitei: 'তৌদবা',
                        mizo: 'Sutna',
                        kashmiri: 'منسوخ',
                        ladakhi: 'ཕྱིར་འཐེན།',
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
            title: _subscriptionDialogTitleAppLocalized(screenContext),
            message: _subscriptionPromptCopyAppLocalized(screenContext),
            trialTitle: _subscriptionTrialTitleAppLocalized(screenContext),
            trialValue: _subscriptionTrialValueAppLocalized(screenContext),
            monthlyTitle: _subscriptionMonthlyTitleAppLocalized(screenContext),
            monthlyValue: _subscriptionMonthlyValueAppLocalized(screenContext),
            renewalCopy: _subscriptionRenewalCopyAppLocalized(screenContext),
            termsLabel: _subscriptionTermsLabelAppLocalized(screenContext),
            skipLabel: _subscriptionSkipLabelAppLocalized(screenContext),
            actionLabel: _subscriptionButtonLabelAppLocalized(screenContext),
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

  // ignore: unused_element
  String _freeExportWithPhotoTitle(BuildContext context) =>
      context.strings.localized(
        telugu: 'ఫోటో మరియు పేరుతో',
        english: 'With photo and name',
        hindi: 'फोटो और नाम के साथ',
        tamil: 'புகைப்படம் மற்றும் பெயருடன்',
        kannada: 'ಫೋಟೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ',
        malayalam: 'ഫോട്ടോയും പേരും ചേർത്ത്',
        assamese: 'ফটো আৰু নামৰ সৈতে',
        konkani: 'फोटो आनी नांवासयत',
        gujarati: 'ફોટો અને નામ સાથે',
        marathi: 'फोटो आणि नावासह',
        meitei: 'Photo amasung mingga',
        mizo: 'Photo leh hming nen',
        odia: 'ଫଟୋ ଏବଂ ନାମ ସହିତ',
        punjabi: 'ਫੋਟੋ ਅਤੇ ਨਾਮ ਨਾਲ',
        nepali: 'फोटो र नामसहित',
        bengali: 'ছবি ও নামসহ',
        kashmiri: 'فوٹو تہ ناو سٲتھ',
        ladakhi: 'Photo dang ming che',
      );

  // ignore: unused_element
  String _freeExportWithPhotoMessage(BuildContext context) =>
      context.strings.localized(
        telugu: 'ఫోటో, పేరుతో షేర్ చేయండి',
        english: 'Share with photo and name',
        hindi: 'फोटो और नाम के साथ शेयर करें',
        tamil: 'புகைப்படம் மற்றும் பெயருடன் பகிரவும்',
        kannada: 'ಫೋಟೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಿ',
        malayalam: 'ഫോട്ടോയും പേരും ചേർത്ത് ഷെയർ ചെയ്യുക',
        assamese: 'ফটো আৰু নামৰ সৈতে শ্বেয়াৰ কৰক',
        konkani: 'फोटो आनी नांवासयत शेयर करात',
        gujarati: 'ફોટો અને નામ સાથે શેર કરો',
        marathi: 'फोटो आणि नावासह शेअर करा',
        meitei: 'Photo amasung mingga share tou',
        mizo: 'Photo leh hming nen share rawh',
        odia: 'ଫଟୋ ଏବଂ ନାମ ସହିତ ଶେୟାର କରନ୍ତୁ',
        punjabi: 'ਫੋਟੋ ਅਤੇ ਨਾਮ ਨਾਲ ਸ਼ੇਅਰ ਕਰੋ',
        nepali: 'फोटो र नामसहित शेयर गर्नुहोस्',
        bengali: 'ছবি ও নামসহ শেয়ার করুন',
        kashmiri: 'فوٹو تہ ناو سٲتھ شیئر کریو',
        ladakhi: 'Photo dang ming che share byed',
      );

  // ignore: unused_element
  String _freeExportTrialPlanLabel(BuildContext context) {
    final price = SubscriptionPlanConfig.trialPriceDisplay;
    return context.strings.localized(
      telugu: '$price ట్రయల్ ప్లాన్',
      english: '$price Trial plan',
      hindi: '$price ट्रायल प्लान',
      tamil: '$price ட்ரயல் திட்டம்',
      kannada: '$price ಟ್ರಯಲ್ ಪ್ಲಾನ್',
      malayalam: '$price ട്രയൽ പ്ലാൻ',
      assamese: '$price ট্ৰায়েল প্লেন',
      konkani: '$price ट्रायल प्लॅन',
      gujarati: '$price ટ્રાયલ પ્લાન',
      marathi: '$price ट्रायल प्लॅन',
      meitei: '$price Trial plan',
      mizo: '$price Trial plan',
      odia: '$price ଟ୍ରାୟାଲ ପ୍ଲାନ',
      punjabi: '$price ਟ੍ਰਾਇਲ ਪਲਾਨ',
      nepali: '$price ट्रायल प्लान',
      bengali: '$price ট্রায়াল প্ল্যান',
      kashmiri: '$price ٹرائل پلان',
      ladakhi: '$price Trial plan',
    );
  }

  // ignore: unused_element
  String _freeExportPlainTitle(BuildContext context) =>
      context.strings.localized(
        telugu: 'ఉచితంగా షేర్ చేయండి',
        english: 'Share free',
        hindi: 'मुफ्त शेयर करें',
        tamil: 'இலவசமாக பகிரவும்',
        kannada: 'ಉಚಿತವಾಗಿ ಹಂಚಿಕೊಳ್ಳಿ',
        malayalam: 'സൗജന്യമായി ഷെയർ ചെയ്യുക',
        assamese: 'বিনামূল্যে শ্বেয়াৰ কৰক',
        konkani: 'फुकट शेयर करात',
        gujarati: 'મફતમાં શેર કરો',
        marathi: 'मोफत शेअर करा',
        meitei: 'Free oina share tou',
        mizo: 'Free-a share rawh',
        odia: 'ମାଗଣାରେ ଶେୟାର କରନ୍ତୁ',
        punjabi: 'ਮੁਫ਼ਤ ਸ਼ੇਅਰ ਕਰੋ',
        nepali: 'निःशुल्क शेयर गर्नुहोस्',
        bengali: 'ফ্রি শেয়ার করুন',
        kashmiri: 'مفت شیئر کریو',
        ladakhi: 'Free share byed',
      );

  // ignore: unused_element
  String _freeExportPlainMessage(BuildContext context) =>
      context.strings.localized(
        telugu: 'పేరు, ఫోటో లేకుండా పోస్టర్ మాత్రమే',
        english: 'Poster only, without name and photo',
        hindi: 'केवल पोस्टर, नाम और फोटो के बिना',
        tamil: 'பெயரும் புகைப்படமும் இல்லாமல் போஸ்டர் மட்டும்',
        kannada: 'ಹೆಸರು, ಫೋಟೋ ಇಲ್ಲದೆ ಪೋಸ್ಟರ್ ಮಾತ್ರ',
        malayalam: 'പേരും ഫോട്ടോയും ഇല്ലാതെ പോസ്റ്റർ മാത്രം',
        assamese: 'নাম আৰু ফটো নোহোৱাকৈ কেৱল পোষ্টাৰ',
        konkani: 'नांव आनी फोटो नासतना फकत पोस्टर',
        gujarati: 'નામ અને ફોટો વગર માત્ર પોસ્ટર',
        marathi: 'नाव आणि फोटोशिवाय फक्त पोस्टर',
        meitei: 'Ming amasung photo yaodana poster khaktang',
        mizo: 'Hming leh photo tel lo poster chauh',
        odia: 'ନାମ ଏବଂ ଫଟୋ ବିନା କେବଳ ପୋଷ୍ଟର',
        punjabi: 'ਨਾਮ ਅਤੇ ਫੋਟੋ ਬਿਨਾਂ ਸਿਰਫ਼ ਪੋਸਟਰ',
        nepali: 'नाम र फोटो बिना पोस्टर मात्र',
        bengali: 'নাম ও ছবি ছাড়া শুধু পোস্টার',
        kashmiri: 'ناو تہ فوٹو بغیر صرف پوسٹر',
        ladakhi: 'Ming dang photo medpa poster tsam',
      );

  // ignore: unused_element
  String _freeExportDownloadLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'డౌన్‌లోడ్',
        english: 'Download',
        hindi: 'डाउनलोड',
        tamil: 'பதிவிறக்கம்',
        kannada: 'ಡೌನ್‌ಲೋಡ್',
        malayalam: 'ഡൗൺലോഡ്',
        assamese: 'ডাউনলোড',
        konkani: 'डाउनलोड',
        gujarati: 'ડાઉનલોડ',
        marathi: 'डाउनलोड',
        meitei: 'Download',
        mizo: 'Download',
        odia: 'ଡାଉନଲୋଡ୍',
        punjabi: 'ਡਾਊਨਲੋਡ',
        nepali: 'डाउनलोड',
        bengali: 'ডাউনলোড',
        kashmiri: 'ڈاؤنلوڈ',
        ladakhi: 'Download',
      );

  // ignore: unused_element
  String _freeExportShareLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'షేర్',
        english: 'Share',
        hindi: 'शेयर',
        tamil: 'பகிர்',
        kannada: 'ಹಂಚಿಕೆ',
        malayalam: 'ഷെയർ',
        assamese: 'শ্বেয়াৰ',
        konkani: 'शेयर',
        gujarati: 'શેર',
        marathi: 'शेअर',
        meitei: 'Share',
        mizo: 'Share',
        odia: 'ଶେୟାର',
        punjabi: 'ਸ਼ੇਅਰ',
        nepali: 'शेयर',
        bengali: 'শেয়ার',
        kashmiri: 'شیئر',
        ladakhi: 'Share',
      );

  Future<bool> _showFreeExportChoiceSheet(
    BuildContext context, {
    required bool preferShare,
  }) async {
    if (!context.mounted) {
      return false;
    }
    await ScreenSecurityService.protectScreen(adminOnlyBypass: true);
    try {
      if (!context.mounted) {
        return false;
      }
      final title = context.strings.localized(
        telugu: 'సబ్‌స్క్రైబ్ చేసి పోస్టర్ ఉపయోగించండి',
        english: 'Subscribe to use this poster',
        hindi: 'इस पोस्टर का उपयोग करने के लिए सब्सक्राइब करें',
        tamil: 'இந்த போஸ்டரை பயன்படுத்த சந்தா செலுத்துங்கள்',
        kannada: 'ಈ ಪೋಸ್ಟರ್ ಬಳಸಲು ಸಬ್‌ಸ್ಕ್ರೈಬ್ ಮಾಡಿ',
        malayalam: 'ഈ പോസ്റ്റർ ഉപയോഗിക്കാൻ സബ്സ്ക്രൈബ് ചെയ്യുക',
        assamese: 'এই পোষ্টাৰ ব্যৱহাৰ কৰিবলৈ চাবস্ক্ৰাইব কৰক',
        konkani: 'हो पोस्टर वापरपाक सबस्क्राइब करात',
        gujarati: 'આ પોસ્ટર વાપરવા માટે સબ્સ્ક્રાઇબ કરો',
        marathi: 'हा पोस्टर वापरण्यासाठी सबस्क्राइब करा',
        meitei: 'Poster asi sijinnaba subscribe tou',
        mizo: 'He poster hman turin subscribe rawh',
        odia: 'ଏହି ପୋଷ୍ଟର ବ୍ୟବହାର ପାଇଁ ସବସ୍କ୍ରାଇବ କରନ୍ତୁ',
        punjabi: 'ਇਹ ਪੋਸਟਰ ਵਰਤਣ ਲਈ ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ',
        nepali: 'यो पोस्टर प्रयोग गर्न सदस्यता लिनुहोस्',
        bengali: 'এই পোস্টার ব্যবহার করতে সাবস্ক্রাইব করুন',
        kashmiri: 'یہ پوسٹر استعمال کرنہ خٲطر سبسکرائب کریو',
        ladakhi: 'Poster di use bya la subscribe byed',
      );
      final message = context.strings.localized(
        telugu:
            'మీ ఫోటో, పేరుతో పోస్టర్‌ను డౌన్‌లోడ్ లేదా షేర్ చేయడానికి సబ్‌స్క్రైబ్ చేయండి.',
        english:
            'Subscribe to download or share this poster with your photo and name.',
        hindi:
            'अपनी फोटो और नाम के साथ इस पोस्टर को डाउनलोड या शेयर करने के लिए सब्सक्राइब करें।',
        tamil:
            'உங்கள் புகைப்படம் மற்றும் பெயருடன் இந்த போஸ்டரை பதிவிறக்கம் அல்லது பகிர சந்தா செலுத்துங்கள்.',
        kannada:
            'ನಿಮ್ಮ ಫೋಟೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ ಈ ಪೋಸ್ಟರ್ ಡೌನ್‌ಲೋಡ್ ಅಥವಾ ಶೇರ್ ಮಾಡಲು ಸಬ್‌ಸ್ಕ್ರೈಬ್ ಮಾಡಿ.',
        malayalam:
            'നിങ്ങളുടെ ഫോട്ടോയും പേരും ചേർത്ത് ഈ പോസ്റ്റർ ഡൗൺലോഡ് അല്ലെങ്കിൽ ഷെയർ ചെയ്യാൻ സബ്സ്ക്രൈബ് ചെയ്യുക.',
        assamese:
            'আপোনাৰ ফটো আৰু নামৰ সৈতে এই পোষ্টাৰ ডাউনলোড বা শ্বেয়াৰ কৰিবলৈ চাবস্ক্ৰাইব কৰক।',
        konkani:
            'तुमच्या फोटो आनी नांवासयत हो पोस्टर डाउनलोड वा शेयर करपाक सबस्क्राइब करात.',
        gujarati:
            'તમારા ફોટો અને નામ સાથે આ પોસ્ટર ડાઉનલોડ અથવા શેર કરવા માટે સબ્સ્ક્રાઇબ કરો.',
        marathi:
            'तुमचा फोटो आणि नावासह हा पोस्टर डाउनलोड किंवा शेअर करण्यासाठी सबस्क्राइब करा.',
        meitei:
            'Nakhoigi photo amasung mingga poster asi download/share tounaba subscribe tou.',
        mizo:
            'I photo leh hming nen he poster download/share turin subscribe rawh.',
        odia:
            'ଆପଣଙ୍କ ଫଟୋ ଏବଂ ନାମ ସହ ଏହି ପୋଷ୍ଟର ଡାଉନଲୋଡ୍ କିମ୍ବା ସେୟାର ପାଇଁ ସବସ୍କ୍ରାଇବ କରନ୍ତୁ।',
        punjabi:
            'ਆਪਣੀ ਫੋਟੋ ਅਤੇ ਨਾਮ ਨਾਲ ਇਹ ਪੋਸਟਰ ਡਾਊਨਲੋਡ ਜਾਂ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ।',
        nepali:
            'आफ्नो फोटो र नामसहित यो पोस्टर डाउनलोड वा शेयर गर्न सदस्यता लिनुहोस्।',
        bengali:
            'আপনার ছবি ও নামসহ এই পোস্টার ডাউনলোড বা শেয়ার করতে সাবস্ক্রাইব করুন।',
        kashmiri:
            'پنُن فوٹو تہ ناو سٲتھ یہ پوسٹر ڈاؤنلوڈ یا شیئر کرنہ خٲطر سبسکرائب کریو۔',
        ladakhi:
            'Rang gi photo dang ming che poster download/share bya la subscribe byed.',
      );
      final continueLabel = context.strings.localized(
        telugu: 'కొనసాగించండి',
        english: 'Continue',
        hindi: 'जारी रखें',
        tamil: 'தொடரவும்',
        kannada: 'ಮುಂದುವರಿಸಿ',
        malayalam: 'തുടരുക',
        assamese: 'আগবাঢ়ক',
        konkani: 'मुखार वचात',
        gujarati: 'આગળ વધો',
        marathi: 'पुढे जा',
        meitei: 'Continue tou',
        mizo: 'Continue rawh',
        odia: 'ଆଗକୁ ଯାଆନ୍ତୁ',
        punjabi: 'ਜਾਰੀ ਰੱਖੋ',
        nepali: 'जारी राख्नुहोस्',
        bengali: 'চালিয়ে যান',
        kashmiri: 'جاری تھأیو',
        ladakhi: 'Continue byed',
      );
      // ignore: unused_local_variable
      final posterLabel = context.strings.localized(
        telugu: 'ఎంచుకున్న పోస్టర్',
        english: 'Selected poster',
        hindi: 'चुना गया पोस्टर',
        tamil: 'தேர்ந்தெடுத்த போஸ்டர்',
        kannada: 'ಆಯ್ಕೆ ಮಾಡಿದ ಪೋಸ್ಟರ್',
        malayalam: 'തിരഞ്ഞെടുത്ത പോസ്റ്റർ',
        assamese: 'বাছনি কৰা পোষ্টাৰ',
        konkani: 'वेंचिल्लो पोस्टर',
        gujarati: 'પસંદ કરેલું પોસ્ટર',
        marathi: 'निवडलेला पोस्टर',
        meitei: 'Khanbiba poster',
        mizo: 'Poster thlan',
        odia: 'ଚୟନିତ ପୋଷ୍ଟର',
        punjabi: 'ਚੁਣਿਆ ਪੋਸਟਰ',
        nepali: 'चयन गरिएको पोस्टर',
        bengali: 'নির্বাচিত পোস্টার',
        kashmiri: 'ژارنہ آمُت پوسٹر',
        ladakhi: 'Selected poster',
      );
      final posterTitle = item.titleFor(language).trim().isNotEmpty
          ? item.titleFor(language).trim()
          : item.titleEn.trim();
      final previewAspectRatio =
          _resolvedPreviewAspectRatio ??
          item.pageConfig?.aspectRatio ??
          (item.isVideo ? 9 / 16 : 4 / 5);
      final shouldStartPayment = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.38),
        builder: (sheetContext) {
          var busy = false;
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return FractionallySizedBox(
                heightFactor: 0.72,
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 44,
                              ),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.12,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: busy
                                    ? null
                                    : () =>
                                          Navigator.of(sheetContext).pop(false),
                                icon: const Icon(Icons.close_rounded),
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final aspectRatio = previewAspectRatio <= 0
                                  ? 4 / 5
                                  : previewAspectRatio;
                              final maxPreviewWidth =
                                  (constraints.maxHeight * aspectRatio).clamp(
                                    0.0,
                                    constraints.maxWidth,
                                  );
                              return Center(
                                child: SizedBox(
                                  width: maxPreviewWidth,
                                  child: AspectRatio(
                                    aspectRatio: aspectRatio,
                                    child: ClipRect(
                                      child: Semantics(
                                        label: posterTitle.isEmpty
                                            ? AppPublicInfo.appName
                                            : posterTitle,
                                        image: true,
                                        child: _buildPosterPreview(
                                          isPhotoVisible: true,
                                          playbackEnabledOverride: false,
                                          enableFullScreenTap: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: busy
                                ? null
                                : () {
                                    setSheetState(() => busy = true);
                                    Navigator.of(sheetContext).pop(true);
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    preferShare
                                        ? Icons.ios_share_rounded
                                        : Icons.download_rounded,
                                  ),
                            label: Text(
                              continueLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
      if (shouldStartPayment != true || !context.mounted) {
        return false;
      }
      return _startDirectTrialPurchaseFromFreeExportChoice();
    } finally {
      if (context.mounted) {
        await ScreenSecurityService.protectScreen(adminOnlyBypass: false);
      }
    }
  }

  // ignore: unused_element
  Future<bool> _ensureHomeExportRewardedAccess({
    required String debugLabel,
  }) async {
    if (item.isVideo || AppPublicInfo.adMobHomeExportRewardedAdUnitId.isEmpty) {
      return true;
    }
    final settings = await _TemplateFeedItem._homeExportAdSettingsService
        .fetchForSelectedRegion();
    final manualAd = settings.manualAd;
    if (manualAd?.canShow == true) {
      return _showHomeExportManualAd(manualAd!);
    }
    if (!settings.rewardedEnabled) {
      return true;
    }
    return _TemplateFeedItem._homeExportRewardedAccessService
        .showRewardedAccessAd(
          adUnitId: AppPublicInfo.adMobHomeExportRewardedAdUnitId,
          debugLabel: debugLabel,
        );
  }

  Future<void> _preloadHomeExportRewardedAdIfEnabled() async {
    if (item.isVideo || !AppPublicInfo.hasHomeExportRewardedAdUnitId) {
      return;
    }
    final settings = await _TemplateFeedItem._homeExportAdSettingsService
        .fetchForSelectedRegion();
    if (!settings.rewardedEnabled) {
      return;
    }
    await _TemplateFeedItem._homeExportRewardedAccessService.preloadRewardedAd(
      adUnitId: AppPublicInfo.adMobHomeExportRewardedAdUnitId,
    );
  }

  Future<bool> _showHomeExportManualAd(HomeExportManualAd ad) async {
    if (!mounted || ad.url.trim().isEmpty) {
      return true;
    }
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _HomeExportManualAdDialog(ad: ad),
    );
    return allowed ?? false;
  }

  Future<void> _performPlainFreeExport(
    BuildContext context, {
    required bool share,
  }) async {
    final messenger = ScaffoldMessenger.of(
      hostContext.mounted ? hostContext : context,
    );
    final posterNotReadyMessage = context.strings.localized(
      telugu:
          'ÃƒÂ Ã‚Â°Ã‚ÂªÃƒÂ Ã‚Â±Ã¢â‚¬Â¹ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã…Â¸ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â°Ã‚Â¿ÃƒÂ Ã‚Â°Ã‚Â¦ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â§ÃƒÂ Ã‚Â°Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â°Ã¢â‚¬Â¢ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â±Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚Â¦ÃƒÂ Ã‚Â±Ã‚Â. ÃƒÂ Ã‚Â°Ã‚Â®ÃƒÂ Ã‚Â°Ã‚Â³ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â±Ã¢â€šÂ¬ ÃƒÂ Ã‚Â°Ã‚ÂªÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â°Ã‚Â¯ÃƒÂ Ã‚Â°Ã‚Â¤ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â¨ÃƒÂ Ã‚Â°Ã‚Â¿ÃƒÂ Ã‚Â°Ã¢â‚¬Å¡ÃƒÂ Ã‚Â°Ã…Â¡ÃƒÂ Ã‚Â°Ã¢â‚¬Å¡ÃƒÂ Ã‚Â°Ã‚Â¡ÃƒÂ Ã‚Â°Ã‚Â¿.',
      english: 'Poster is not ready. Please try again.',
      hindi:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¥Ã‹â€ ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¥Ã‹â€ ÃƒÂ Ã‚Â¥Ã‚Â¤ ÃƒÂ Ã‚Â¤Ã‚Â«ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¶ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â¶ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¥Ã‚Â¤',
      tamil:
          'ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â¯Ã¢â‚¬Â¹ÃƒÂ Ã‚Â®Ã‚Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â®Ã‚Â°ÃƒÂ Ã‚Â¯Ã‚Â ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¯ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã‚Â°ÃƒÂ Ã‚Â®Ã‚Â¾ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â®Ã¢â‚¬Â¡ÃƒÂ Ã‚Â®Ã‚Â²ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â²ÃƒÂ Ã‚Â¯Ã‹â€ . ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â¯Ã¢â€šÂ¬ÃƒÂ Ã‚Â®Ã‚Â£ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â¯Ã‚Â ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â¯ÃƒÂ Ã‚Â®Ã‚Â±ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¡ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚ÂµÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â¯Ã‚Â.',
      kannada:
          'ÃƒÂ Ã‚Â²Ã‚ÂªÃƒÂ Ã‚Â³Ã¢â‚¬Â¹ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã…Â¸ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â³Ã‚Â ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â§ÃƒÂ Ã‚Â²Ã‚ÂµÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â². ÃƒÂ Ã‚Â²Ã‚Â®ÃƒÂ Ã‚Â²Ã‚Â¤ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¤ÃƒÂ Ã‚Â³Ã¢â‚¬Â  ÃƒÂ Ã‚Â²Ã‚ÂªÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¯ÃƒÂ Ã‚Â²Ã‚Â¤ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â²Ã‚Â¿.',
      malayalam:
          'ÃƒÂ Ã‚Â´Ã‚ÂªÃƒÂ Ã‚ÂµÃ¢â‚¬Â¹ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚ÂµÃ‚Â¼ ÃƒÂ Ã‚Â´Ã‚Â¤ÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã…Â¸ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã…Â¸ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã‚Â²ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â². ÃƒÂ Ã‚Â´Ã‚ÂµÃƒÂ Ã‚ÂµÃ¢â€šÂ¬ÃƒÂ Ã‚Â´Ã‚Â£ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã…Â¸ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â´Ã‚Â¶ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â°ÃƒÂ Ã‚Â´Ã‚Â®ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã¢â‚¬Â¢.',
      assamese:
          'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â·ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â§Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â§Ã‚Â ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â§Ã‚Â±ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¥Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚Â° ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â·ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¥Ã‚Â¤',
      konkani:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â¾. ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¤ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¨ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¤.',
      gujarati:
          'ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚Â«Ã¢â‚¬Â¹ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ…Â¸ÃƒÂ Ã‚ÂªÃ‚Â° ÃƒÂ Ã‚ÂªÃ‚Â¤ÃƒÂ Ã‚Â«Ã‹â€ ÃƒÂ Ã‚ÂªÃ‚Â¯ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ‚Â° ÃƒÂ Ã‚ÂªÃ‚Â¨ÃƒÂ Ã‚ÂªÃ‚Â¥ÃƒÂ Ã‚Â«Ã¢â€šÂ¬. ÃƒÂ Ã‚ÂªÃ‚Â«ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â€šÂ¬ ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚ÂªÃ‚Â¯ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ‚Â¸ ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â‚¬Â¹.',
      marathi:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬. ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¨ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¾.',
      meitei: 'Poster ready oidiramde. Amuk hotnou.',
      mizo: 'Poster a la ready lo. Han tum leh rawh.',
      odia:
          'ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â­Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¬Ã‚Â·ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã…Â¸ÃƒÂ Ã‚Â¬Ã‚Â° ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â¤ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â¤ ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â¹ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚ÂÃƒÂ Ã‚Â¥Ã‚Â¤ ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â£ÃƒÂ Ã‚Â¬Ã‚Â¿ ÃƒÂ Ã‚Â¬Ã…Â¡ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚Â·ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã…Â¸ÃƒÂ Ã‚Â¬Ã‚Â¾ ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â¤ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¥Ã‚Â¤',
      punjabi:
          'ÃƒÂ Ã‚Â¨Ã‚ÂªÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã…Â¸ÃƒÂ Ã‚Â¨Ã‚Â° ÃƒÂ Ã‚Â¨Ã‚Â¤ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã¢â‚¬Â ÃƒÂ Ã‚Â¨Ã‚Â° ÃƒÂ Ã‚Â¨Ã‚Â¨ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ÃƒÂ Ã‚Â¨Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â©Ã‹â€ ÃƒÂ Ã‚Â¥Ã‚Â¤ ÃƒÂ Ã‚Â¨Ã‚Â«ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã‚Â° ÃƒÂ Ã‚Â¨Ã¢â‚¬Â¢ÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã‚Â¼ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã‚Â¼ ÃƒÂ Ã‚Â¨Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¥Ã‚Â¤',
      nepali:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã¢â‚¬ÂºÃƒÂ Ã‚Â¥Ã‹â€ ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚Â¤ ÃƒÂ Ã‚Â¤Ã‚Â«ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¿ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¸ ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¥Ã‚Â¤',
      bengali:
          'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¥Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â·ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚Â¤',
      kashmiri:
          'Ãƒâ„¢Ã‚Â¾Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â³Ãƒâ„¢Ã‚Â¹ÃƒËœÃ‚Â± ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™ÃƒËœÃ‚Â§ÃƒËœÃ‚Â± ÃƒÅ¡Ã¢â‚¬Â ÃƒÅ¡Ã‚Â¾Ãƒâ„¢Ã‚Â Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã¢â‚¬Â¢Ãƒâ€ºÃ‚ÂÃƒâ€ºÃ¢â‚¬Â ÃƒËœÃ‚Â¯Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â§ÃƒËœÃ‚Â± ÃƒÅ¡Ã‚Â©Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â´ÃƒËœÃ‚Â´ ÃƒÅ¡Ã‚Â©ÃƒËœÃ‚Â±Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã‹â€ Ãƒâ€ºÃ¢â‚¬Â',
      ladakhi: 'Poster ready med. Yang try byed.',
    );
    final posterSavedMessage = context.strings.localized(
      telugu:
          'ÃƒÂ Ã‚Â°Ã‚ÂªÃƒÂ Ã‚Â±Ã¢â‚¬Â¹ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã…Â¸ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã¢â‚¬â€ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â¯ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã¢â€šÂ¬ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â±Ã¢â‚¬Â¹ ÃƒÂ Ã‚Â°Ã‚Â¸ÃƒÂ Ã‚Â±Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚ÂµÃƒÂ Ã‚Â±Ã‚Â ÃƒÂ Ã‚Â°Ã¢â‚¬Â¦ÃƒÂ Ã‚Â°Ã‚Â¯ÃƒÂ Ã‚Â°Ã‚Â¿ÃƒÂ Ã‚Â°Ã¢â‚¬Å¡ÃƒÂ Ã‚Â°Ã‚Â¦ÃƒÂ Ã‚Â°Ã‚Â¿.',
      english: 'Poster saved to gallery.',
      hindi:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã‹â€ ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Âµ ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¥Ã‚Â¤',
      tamil:
          'ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â¯Ã¢â‚¬Â¹ÃƒÂ Ã‚Â®Ã‚Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â®Ã‚Â°ÃƒÂ Ã‚Â¯Ã‚Â ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã¢â‚¬Â¡ÃƒÂ Ã‚Â®Ã‚Â²ÃƒÂ Ã‚Â®Ã‚Â°ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã‚Â¯ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã‚Â²ÃƒÂ Ã‚Â¯Ã‚Â ÃƒÂ Ã‚Â®Ã…Â¡ÃƒÂ Ã‚Â¯Ã¢â‚¬Â¡ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â®Ã‚Â¿ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â¯Ã‚Â.',
      kannada:
          'ÃƒÂ Ã‚Â²Ã‚ÂªÃƒÂ Ã‚Â³Ã¢â‚¬Â¹ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã…Â¸ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â³Ã‚Â ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¯ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¯ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â²Ã‚Â¿ ÃƒÂ Ã‚Â²Ã¢â‚¬Â°ÃƒÂ Ã‚Â²Ã‚Â³ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â³Ã¢â‚¬Â .',
      malayalam:
          'ÃƒÂ Ã‚Â´Ã‚ÂªÃƒÂ Ã‚ÂµÃ¢â‚¬Â¹ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚ÂµÃ‚Â¼ ÃƒÂ Ã‚Â´Ã¢â‚¬â€ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â²ÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚ÂµÃ‚Â½ ÃƒÂ Ã‚Â´Ã‚Â¸ÃƒÂ Ã‚ÂµÃ¢â‚¬Â¡ÃƒÂ Ã‚Â´Ã‚ÂµÃƒÂ Ã‚ÂµÃ‚Â ÃƒÂ Ã‚Â´Ã…Â¡ÃƒÂ Ã‚ÂµÃ¢â‚¬Â ÃƒÂ Ã‚Â´Ã‚Â¯ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â¤ÃƒÂ Ã‚ÂµÃ‚Â.',
      assamese:
          'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â·ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â§Ã‚Â° ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â§Ã¢â€šÂ¬ÃƒÂ Ã‚Â¦Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â­ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¥Ã‚Â¤',
      konkani:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¤Ã‚Â¤ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Âµ ÃƒÂ Ã‚Â¤Ã…â€œÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â¾.',
      gujarati:
          'ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚Â«Ã¢â‚¬Â¹ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ…Â¸ÃƒÂ Ã‚ÂªÃ‚Â° ÃƒÂ Ã‚ÂªÃ¢â‚¬â€ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ÃƒÂ Ã‚ÂªÃ‚Â²ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â€šÂ¬ÃƒÂ Ã‚ÂªÃ‚Â®ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ¢â‚¬Å¡ ÃƒÂ Ã‚ÂªÃ‚Â¸ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ÃƒÂ Ã‚ÂªÃ‚Âµ ÃƒÂ Ã‚ÂªÃ‚Â¥ÃƒÂ Ã‚ÂªÃ‚Â¯ÃƒÂ Ã‚Â«Ã‚ÂÃƒÂ Ã‚ÂªÃ¢â‚¬Å¡.',
      marathi:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ÃƒÂ Ã‚Â¤Ã‚Â¤ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Âµ ÃƒÂ Ã‚Â¤Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡.',
      meitei: 'Poster gallery-da save toure.',
      mizo: 'Poster gallery-ah save a ni.',
      odia:
          'ÃƒÂ Ã‚Â¬Ã‚ÂªÃƒÂ Ã‚Â­Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¬Ã‚Â·ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã…Â¸ÃƒÂ Ã‚Â¬Ã‚Â° ÃƒÂ Ã‚Â¬Ã¢â‚¬â€ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â­Ã…Â¸ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â²ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â­Ã¢â€šÂ¬ÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¬Ã‚Â¸ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚Â­ÃƒÂ Ã‚Â­Ã‚Â ÃƒÂ Ã‚Â¬Ã‚Â¹ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚Â²ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¥Ã‚Â¤',
      punjabi:
          'ÃƒÂ Ã‚Â¨Ã‚ÂªÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â¨Ã…Â¸ÃƒÂ Ã‚Â¨Ã‚Â° ÃƒÂ Ã‚Â¨Ã¢â‚¬â€ÃƒÂ Ã‚Â©Ã‹â€ ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¨Ã‚ÂµÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â©Ã‚Â±ÃƒÂ Ã‚Â¨Ã…Â¡ ÃƒÂ Ã‚Â¨Ã‚Â¸ÃƒÂ Ã‚Â©Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¨Ã‚Âµ ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â©Ã¢â‚¬Â¹ ÃƒÂ Ã‚Â¨Ã¢â‚¬â€ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã¢â‚¬Â ÃƒÂ Ã‚Â¥Ã‚Â¤',
      nepali:
          'ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã…Â¸ÃƒÂ Ã‚Â¤Ã‚Â° ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¾ ÃƒÂ Ã‚Â¤Ã‚Â¸ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Â­ ÃƒÂ Ã‚Â¤Ã‚Â­ÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¥Ã‚Â¤',
      bengali:
          'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â­ ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬ÂºÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¥Ã‚Â¤',
      kashmiri:
          'Ãƒâ„¢Ã‚Â¾Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â³Ãƒâ„¢Ã‚Â¹ÃƒËœÃ‚Â± ÃƒÅ¡Ã‚Â¯Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â±Ãƒâ€ºÃ…â€™ Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â² Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â­Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¸ ÃƒÅ¡Ã‚Â¯Ãƒâ€ºÃ¢â‚¬Â Ãƒâ„¢Ã‹â€ Ãƒâ€ºÃ¢â‚¬Â',
      ladakhi: 'Poster gallery nang save song.',
    );
    final galleryPermissionMessage = context.strings.localized(
      telugu:
          'ÃƒÂ Ã‚Â°Ã¢â‚¬â€ÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚Â¯ÃƒÂ Ã‚Â°Ã‚Â¾ÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â°Ã‚Â°ÃƒÂ Ã‚Â±Ã¢â€šÂ¬ permission ÃƒÂ Ã‚Â°Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚ÂµÃƒÂ Ã‚Â±Ã‚ÂÃƒÂ Ã‚Â°Ã‚ÂµÃƒÂ Ã‚Â°Ã‚Â²ÃƒÂ Ã‚Â±Ã¢â‚¬Â¡ÃƒÂ Ã‚Â°Ã‚Â¦ÃƒÂ Ã‚Â±Ã‚Â.',
      english: 'Gallery permission was denied.',
      hindi:
          'ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã‹â€ ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¿ ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ÃƒÂ Ã‚Â¤Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ÃƒÂ Ã‚Â¥Ã‚Â¤',
      tamil:
          'ÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã¢â‚¬Â¡ÃƒÂ Ã‚Â®Ã‚Â²ÃƒÂ Ã‚Â®Ã‚Â°ÃƒÂ Ã‚Â®Ã‚Â¿ ÃƒÂ Ã‚Â®Ã¢â‚¬Â¦ÃƒÂ Ã‚Â®Ã‚Â©ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â®Ã‚Â¿ ÃƒÂ Ã‚Â®Ã‚Â®ÃƒÂ Ã‚Â®Ã‚Â±ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã¢â‚¬Â¢ÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã‚ÂªÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â¯Ã‚ÂÃƒÂ Ã‚Â®Ã…Â¸ÃƒÂ Ã‚Â®Ã‚Â¤ÃƒÂ Ã‚Â¯Ã‚Â.',
      kannada:
          'ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â¯ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¿ ÃƒÂ Ã‚Â²Ã¢â‚¬Â¦ÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â³Ã‚ÂÃƒÂ Ã‚Â²Ã‚Â®ÃƒÂ Ã‚Â²Ã‚Â¤ÃƒÂ Ã‚Â²Ã‚Â¿ ÃƒÂ Ã‚Â²Ã‚Â¨ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã¢â‚¬Â¢ÃƒÂ Ã‚Â²Ã‚Â°ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¸ÃƒÂ Ã‚Â²Ã‚Â²ÃƒÂ Ã‚Â²Ã‚Â¾ÃƒÂ Ã‚Â²Ã¢â‚¬â€ÃƒÂ Ã‚Â²Ã‚Â¿ÃƒÂ Ã‚Â²Ã‚Â¦ÃƒÂ Ã‚Â³Ã¢â‚¬Â .',
      malayalam:
          'ÃƒÂ Ã‚Â´Ã¢â‚¬â€ÃƒÂ Ã‚Â´Ã‚Â¾ÃƒÂ Ã‚Â´Ã‚Â²ÃƒÂ Ã‚Â´Ã‚Â±ÃƒÂ Ã‚Â´Ã‚Â¿ ÃƒÂ Ã‚Â´Ã¢â‚¬Â¦ÃƒÂ Ã‚Â´Ã‚Â¨ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã‚Â®ÃƒÂ Ã‚Â´Ã‚Â¤ÃƒÂ Ã‚Â´Ã‚Â¿ ÃƒÂ Ã‚Â´Ã‚Â¨ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã‚Â·ÃƒÂ Ã‚ÂµÃ¢â‚¬Â¡ÃƒÂ Ã‚Â´Ã‚Â§ÃƒÂ Ã‚Â´Ã‚Â¿ÃƒÂ Ã‚Â´Ã…Â¡ÃƒÂ Ã‚ÂµÃ‚ÂÃƒÂ Ã‚Â´Ã…Â¡ÃƒÂ Ã‚ÂµÃ‚Â.',
      assamese:
          'ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â§Ã‚Â°ÃƒÂ Ã‚Â§Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¿ ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â§Ã‚Â±ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¥Ã‚Â¤',
      konkani:
          'ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¹ÃƒÂ Ã‚Â¤Ã‚Â¯ ÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚Â³ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â³ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬.',
      gujarati:
          'ÃƒÂ Ã‚ÂªÃ¢â‚¬â€ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ÃƒÂ Ã‚ÂªÃ‚Â²ÃƒÂ Ã‚Â«Ã¢â‚¬Â¡ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â€šÂ¬ ÃƒÂ Ã‚ÂªÃ‚ÂªÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚ÂªÃ‚Â®ÃƒÂ Ã‚ÂªÃ‚Â¿ÃƒÂ Ã‚ÂªÃ‚Â¶ÃƒÂ Ã‚ÂªÃ‚Â¨ ÃƒÂ Ã‚ÂªÃ‚Â¨ÃƒÂ Ã‚ÂªÃ¢â‚¬Â¢ÃƒÂ Ã‚ÂªÃ‚Â¾ÃƒÂ Ã‚ÂªÃ‚Â°ÃƒÂ Ã‚Â«Ã¢â€šÂ¬.',
      marathi:
          'ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã‚ÂªÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚ÂµÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬.',
      meitei: 'Gallery permission piramde.',
      mizo: 'Gallery permission pek a ni lo.',
      odia:
          'ÃƒÂ Ã‚Â¬Ã¢â‚¬â€ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â­Ã…Â¸ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â²ÃƒÂ Ã‚Â­Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¬Ã‚Â°ÃƒÂ Ã‚Â­Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¬Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â­Ã‚ÂÃƒÂ Ã‚Â¬Ã‚Â®ÃƒÂ Ã‚Â¬Ã‚Â¤ÃƒÂ Ã‚Â¬Ã‚Â¿ ÃƒÂ Ã‚Â¬Ã‚Â®ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã‚Â³ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã‚Â²ÃƒÂ Ã‚Â¬Ã‚Â¾ ÃƒÂ Ã‚Â¬Ã‚Â¨ÃƒÂ Ã‚Â¬Ã‚Â¾ÃƒÂ Ã‚Â¬Ã‚Â¹ÃƒÂ Ã‚Â¬Ã‚Â¿ÃƒÂ Ã‚Â¬Ã‚ÂÃƒÂ Ã‚Â¥Ã‚Â¤',
      punjabi:
          'ÃƒÂ Ã‚Â¨Ã¢â‚¬â€ÃƒÂ Ã‚Â©Ã‹â€ ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â¨Ã‚Â°ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¨Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¨Ã…â€œÃƒÂ Ã‚Â¨Ã‚Â¾ÃƒÂ Ã‚Â¨Ã…â€œÃƒÂ Ã‚Â¨Ã‚Â¼ÃƒÂ Ã‚Â¨Ã‚Â¤ ÃƒÂ Ã‚Â¨Ã‚Â¨ÃƒÂ Ã‚Â¨Ã‚Â¹ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ÃƒÂ Ã‚Â¨Ã¢â‚¬Å¡ ÃƒÂ Ã‚Â¨Ã‚Â®ÃƒÂ Ã‚Â¨Ã‚Â¿ÃƒÂ Ã‚Â¨Ã‚Â²ÃƒÂ Ã‚Â©Ã¢â€šÂ¬ÃƒÂ Ã‚Â¥Ã‚Â¤',
      nepali:
          'ÃƒÂ Ã‚Â¤Ã¢â‚¬â€ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¯ÃƒÂ Ã‚Â¤Ã‚Â¾ÃƒÂ Ã‚Â¤Ã‚Â²ÃƒÂ Ã‚Â¤Ã‚Â°ÃƒÂ Ã‚Â¥Ã¢â€šÂ¬ ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â®ÃƒÂ Ã‚Â¤Ã‚Â¤ÃƒÂ Ã‚Â¤Ã‚Â¿ ÃƒÂ Ã‚Â¤Ã‚Â¦ÃƒÂ Ã‚Â¤Ã‚Â¿ÃƒÂ Ã‚Â¤Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¤Ã‚ÂÃƒÂ Ã‚Â¤Ã‚Â¨ÃƒÂ Ã‚Â¥Ã‚Â¤',
      bengali:
          'ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¦ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¤ÃƒÂ Ã‚Â¦Ã‚Â¿ ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬Å“ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¯ÃƒÂ Ã‚Â¦Ã‚Â¼ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¥Ã‚Â¤',
      kashmiri:
          'ÃƒÅ¡Ã‚Â¯Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â±Ãƒâ€ºÃ…â€™ ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â²ÃƒËœÃ‚Âª Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã¢â‚¬Â¢Ãƒâ€ºÃ‚Â Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ€ºÃ…â€™Ãƒâ€ºÃ¢â‚¬Â',
      ladakhi: 'Gallery permission ma thob.',
    );
    final plainShareText = _homePosterShareText();
    if (!share) {
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        if (!context.mounted) {
          return;
        }
        _showSnack(messenger, galleryPermissionMessage);
        return;
      }
    }
    if (item.isVideo) {
      final preparedPath = await _ensurePreparedPlainVideoFile();
      if (!context.mounted) {
        return;
      }
      if (preparedPath == null) {
        _showSnack(messenger, '$posterNotReadyMessage (video export)');
        return;
      }
      if (share) {
        _recordPosterExportEngagement(isShare: true);
        final box = context.findRenderObject() as RenderBox?;
        await MediaExportService.shareVideoFile(
          preparedPath,
          text: plainShareText,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
        return;
      }
      final fileName =
          'mana_poster_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final saveResult =
          await MediaExportService.saveVideoFileToGalleryDetailed(
            preparedPath,
            fileName: fileName,
          );
      if (!context.mounted) {
        return;
      }
      if (saveResult.success) {
        _recordPosterExportEngagement(isShare: false);
        _showFullScreenDownloadSuccessToast(context, posterSavedMessage);
        return;
      }
      _showSnack(messenger, _downloadSaveFailureMessage(context, saveResult));
      return;
    }
    final preparedPath = await _ensurePreparedPlainPosterFile();
    if (!context.mounted) {
      return;
    }
    if (preparedPath == null) {
      _showSnack(messenger, posterNotReadyMessage);
      return;
    }
    if (share) {
      _recordPosterExportEngagement(isShare: true);
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        preparedPath,
        text: plainShareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      return;
    }
    final fileName = 'mana_poster_${DateTime.now().millisecondsSinceEpoch}.png';
    final saveResult = await MediaExportService.saveImageFileToGalleryDetailed(
      preparedPath,
      fileName: fileName,
    );
    if (!context.mounted) {
      return;
    }
    if (saveResult.success) {
      _recordPosterExportEngagement(isShare: false);
      if (!kIsWeb) {
        unawaited(
          PosterDownloadsService.recordCopyFromFile(
            preparedPath,
            suggestedFileName: fileName,
          ),
        );
      }
      _showFullScreenDownloadSuccessToast(context, posterSavedMessage);
      return;
    }
    _showSnack(messenger, _downloadSaveFailureMessage(context, saveResult));
  }

  Future<void> _onDownloadTap(BuildContext context) async {
    if (!await _ensureAuthenticatedForPosterAction(
      context,
      actionLabel: context.strings.localized(
        telugu: 'డౌన్‌లోడ్',
        english: 'download',
        hindi: 'डाउनलोड',
        tamil: 'பதிவிறக்கம்',
        kannada: 'ಡೌನ್‌ಲೋಡ್',
        malayalam: 'ഡൗൺലോഡ്',
        marathi: 'डाउनलोड',
        gujarati: 'ડાઉનલોડ',
        bengali: 'ডাউনলোড',
        punjabi: 'ਡਾਊਨਲੋਡ',
        odia: 'ଡାଉନଲୋଡ୍',
        assamese: 'ডাউনলোড',
        konkani: 'डाऊनलोड',
        nepali: 'डाउनलोड',
        meitei: 'দাউনলোদ',
        mizo: 'download',
        kashmiri: 'ڈاؤنلوڈ',
        ladakhi: 'ཕབ་ལེན།',
      ),
    )) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (!_beginAction('download')) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final galleryPermissionMessage = context.strings.localized(
      telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
      english: 'Gallery permission was denied.',
      hindi: 'गैलरी की अनुमति अस्वीकार कर दी गई।',
      tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
      kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ.',
      malayalam: 'ഗ്യാലറി അനുമതി നിരസിച്ചു.',
      marathi: 'गॅलरी परवानगी नाकारली गेली.',
      gujarati: 'ગૅલેરી પરવાનગી નકારી દેવામાં આવી.',
      bengali: 'গ্যালারির অনুমতি প্রত্যাখ্যান করা হয়েছে।',
      punjabi: 'ਗੈਲਰੀ ਦੀ ਇਜਾਜ਼ਤ ਅਸਵੀਕਾਰ ਕਰ ਦਿੱਤੀ ਗਈ।',
      odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଗଲା।',
      assamese: 'গেলেৰীৰ অনুমতি নাকচ কৰা হ’ল।',
      konkani: 'गॅलरीची परवानगी नाकारली.',
      nepali: 'ग्यालरी अनुमति अस्वीकृत गरियो।',
      meitei: 'গেলরিগী অয়াবা য়াদে।',
      mizo: 'Gallery phalna hnar a ni.',
      kashmiri: 'گیلری ہٕنٛز اِجازت آیہِ مسترد کَرنہٕ۔',
      ladakhi: 'པར་མཛོད་ཆོག་མཆན་ཕྱིར་འཐེན་བྱས།',
    );
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'క్యాప్చర్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
      hindi: 'कैप्चर विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'படமெடுத்தல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಕ್ಯಾಪ್ಚರ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ക്യാപ്‌ചർ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'कॅप्चर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'કૅપ્ચર નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ক্যাপচার ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਕੈਪਚਰ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'କ୍ୟାପଚର୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'কেপচাৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'कॅप्चर जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'क्याप्चर असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'কেপচর তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Capture a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'کیپچر گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'པར་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final posterSavedMessage = context.strings.localized(
      telugu: 'పోస్టర్ గ్యాలరీలో సేవ్ చేయబడింది.',
      english: 'Poster saved to gallery.',
      hindi: 'पोस्टर गैलरी में सहेजा गया।',
      tamil: 'போஸ்டர் கேலரியில் சேமிக்கப்பட்டது.',
      kannada: 'ಪೋಸ್ಟರ್ ಗ್ಯಾಲರಿಯಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ.',
      malayalam: 'പോസ്റ്റർ ഗ്യാലറിയിൽ സൂക്ഷിച്ചു.',
      marathi: 'पोस्टर गॅलरीमध्ये जतन केले.',
      gujarati: 'પોસ્ટર ગૅલેરીમાં સાચવવામાં આવ્યું.',
      bengali: 'পোস্টারটি গ্যালারিতে সংরক্ষিত হয়েছে।',
      punjabi: 'ਪੋਸਟਰ ਗੈਲਰੀ ਵਿੱਚ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਗਿਆ।',
      odia: 'ପୋଷ୍ଟର ଗ୍ୟାଲେରୀରେ ସେଭ୍ ହୋଇଛି।',
      assamese: 'পোষ্টাৰ গেলেৰীত সংৰক্ষণ কৰা হ’ল।',
      konkani: 'पोस्टर गॅलरींत सांबाळ्ळें.',
      nepali: 'पोस्टर ग्यालरीमा सुरक्षित गरियो।',
      meitei: 'পোস্তর অসি গেলরিদা সেভ তৌখ্রে।',
      mizo: 'Poster gallery-ah dahthat a ni ta.',
      kashmiri: 'پوسٹر آو گیلری منٛز محفوٗظ کَرنہٕ۔',
      ladakhi: 'པོ་སི་ཊར་པར་མཛོད་ནང་ཉར་ཚགས་བྱས།',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'ఫైల్ సేవ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'File save failed. Please try again.',
      hindi: 'फ़ाइल सहेजना विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'கோப்பைச் சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಫೈಲ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam:
          'ഫയൽ സൂക്ഷിക്കുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'फाइल सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'ફાઇલ સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ফাইল সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਫਾਈਲ ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଫାଇଲ୍ ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'ফাইল সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'फायल सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'फाइल बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'ফাইল সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'File dahthat a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri:
          'فائل محفوٗظ کرنس منٛز ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'ཡིག་སྣོད་ཉར་ཚགས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final downloadFailedMessage = context.strings.localized(
      telugu: 'డౌన్‌లోడ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Download failed. Please try again.',
      hindi: 'डाउनलोड विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'பதிவிறக்கம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ഡൗൺലോഡ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'डाउनलोड अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'ડાઉનલોડ નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ডাউনলোড ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਡਾਊਨਲੋਡ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଡାଉନଲୋଡ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'ডাউনলোড ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'डाऊनलोड जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'डाउनलोड असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'দাউনলোদ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Download a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'ڈاؤنلوڈ گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'ཕབ་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    try {
      if (!item.isVideo && _isCurrentJokesPoster()) {
        await _performPlainFreeExport(context, share: false);
        result = true;
        return;
      }
      final hasAccess = await _hasSubscriptionAccessForExport();
      if (!context.mounted) {
        result = false;
        return;
      }
      if (!hasAccess) {
        final purchased = await _showFreeExportChoiceSheet(
          context,
          preferShare: false,
        );
        if (!context.mounted || !purchased) {
          result = false;
          return;
        }
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
          _recordPosterExportEngagement(isShare: false);
          _showDownloadSuccessSnack(messenger, posterSavedMessage);
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
        if (!kIsWeb) {
          unawaited(
            PosterDownloadsService.recordCopyFromFile(
              preparedPath,
              suggestedFileName: fileName,
            ),
          );
        }
        _recordPosterExportEngagement(isShare: false);
        _showDownloadSuccessSnack(messenger, posterSavedMessage);
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
    if (!await _ensureAuthenticatedForPosterAction(
      context,
      actionLabel: context.strings.localized(
        telugu: 'షేర్',
        english: 'share',
        hindi: 'शेयर',
        tamil: 'பகிர்',
        kannada: 'ಹಂಚಿಕೆ',
        malayalam: 'പങ്കിടൽ',
        marathi: 'शेअर',
        gujarati: 'શેર',
        bengali: 'শেয়ার',
        punjabi: 'ਸਾਂਝਾ',
        odia: 'ସେୟାର୍',
        assamese: 'শ্বেয়াৰ',
        konkani: 'वांटप',
        nepali: 'सेयर',
        meitei: 'শিয়র',
        mizo: 'share',
        kashmiri: 'شیئر',
        ladakhi: 'བགོ་འགྲེམས།',
      ),
    )) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (!_beginAction('share')) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'క్యాప్చర్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
      hindi: 'कैप्चर विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'படமெடுத்தல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಕ್ಯಾಪ್ಚರ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ക്യാപ്‌ചർ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'कॅप्चर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'કૅપ્ચર નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ক্যাপচার ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਕੈਪਚਰ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'କ୍ୟାପଚର୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'কেপচাৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'कॅप्चर जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'क्याप्चर असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'কেপচর তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Capture a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'کیپچر گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'པར་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final shareFailedMessage = context.strings.localized(
      telugu: 'షేర్ చేయడం విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Share failed. Please try again.',
      hindi: 'शेयर करना विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'பகிர்வது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಹಂಚಿಕೆ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'പങ്കിടൽ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'शेअर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'શેર કરવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'শেয়ার করা ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਸਾਂਝਾ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ସେୟାର୍ କରିବା ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'শ্বেয়াৰ কৰা ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'वांटप जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'सेयर गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'শিয়র তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Share a hlawhchham. Khawngaihin ti nawn leh raw.',
      kashmiri: 'شیئر گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'བགོ་འགྲེམས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'ఫైల్ సేవ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'File save failed. Please try again.',
      hindi: 'फ़ाइल सहेजना विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'கோப்பைச் சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಫೈಲ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam:
          'ഫയൽ സൂക്ഷിക്കുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'फाइल सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'ફાઇલ સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ফাইল সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਫਾਈਲ ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଫାଇଲ୍ ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'ফাইল সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'फायल सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'फाइल बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'ফাইল সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'File dahthat a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri:
          'فائل محفوٗظ کرنس منٛز ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'ཡིག་སྣོད་ཉར་ཚགས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final shareText = _homePosterShareText();
    try {
      if (!item.isVideo && _isCurrentJokesPoster()) {
        await _performPlainFreeExport(context, share: true);
        result = true;
        return;
      }
      final hasAccess = await _hasSubscriptionAccessForExport();
      if (!context.mounted) {
        result = false;
        return;
      }
      if (!hasAccess) {
        final purchased = await _showFreeExportChoiceSheet(
          context,
          preferShare: true,
        );
        if (!context.mounted || !purchased) {
          result = false;
          return;
        }
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
        _recordPosterExportEngagement(isShare: true);
        final box = context.findRenderObject() as RenderBox?;
        await MediaExportService.shareVideoFile(
          preparedVideoPath,
          text: shareText,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
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
      _recordPosterExportEngagement(isShare: true);
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

  void _openFullScreenPreview() {
    if (!mounted || deferRichPosterPreview) {
      return;
    }
    final aspectRatio =
        _resolvedPreviewAspectRatio ??
        item.pageConfig?.aspectRatio ??
        (item.isVideo ? 9 / 16 : null);
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => _PosterFullScreenPreview(
          title: item.titleFor(language),
          heroTag: _fullScreenHeroTag,
          aspectRatio: aspectRatio,
          child: _buildPosterPreview(
            isPhotoVisible: _showPosterPhotoNotifier.value,
            playbackEnabledOverride: true,
            enableFullScreenTap: false,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    widget.onInteraction?.call(item, 'preview');
  }

  Future<void> _openPosterPhotoEditor(BuildContext context) async {
    if (!_beginAction('poster_editor_removed')) {
      return;
    }
    try {
      if (!context.mounted) {
        return;
      }
      _showSnack(
        ScaffoldMessenger.of(context),
        context.strings.localized(
          telugu: 'ఎడిటర్ ఇప్పుడు వేరే యాప్‌లో అందుబాటులో ఉంది.',
          english: 'Editor is now available in the separate app.',
          hindi: 'संपादक अब अलग ऐप में उपलब्ध है।',
          tamil: 'எடிட்டர் இப்போது தனி செயலியில் கிடைக்கிறது.',
          kannada: 'ಎಡಿಟರ್ ಈಗ ಪ್ರತ್ಯೇಕ ಆ್ಯಪ್‌ನಲ್ಲಿ ಲಭ್ಯವಿದೆ.',
          malayalam: 'എഡിറ്റർ ഇപ്പോൾ പ്രത്യേക ആപ്പിൽ ലഭ്യമാണ്.',
          marathi: 'संपादक आता वेगळ्या ॲपमध्ये उपलब्ध आहे.',
          gujarati: 'એડિટર હવે અલગ ઍપમાં ઉપલબ્ધ છે.',
          bengali: 'সম্পাদক এখন পৃথক অ্যাপে উপলব্ধ।',
          punjabi: 'ਸੰਪਾਦਕ ਹੁਣ ਵੱਖਰੀ ਐਪ ਵਿੱਚ ਉਪਲਬਧ ਹੈ।',
          odia: 'ଏଡିଟର୍ ଏବେ ଅଲଗା ଆପରେ ଉପଲବ୍ଧ।',
          assamese: 'সম্পাদক এতিয়া পৃথক এপত উপলব্ধ।',
          konkani: 'संपादक आतां वेगळ्या ॲपाचेर मेळटा.',
          nepali: 'सम्पादक अब छुट्टै एपमा उपलब्ध छ।',
          meitei: 'এদিতর অসি হৌজিক তোঙানবা এপত ফংলে।',
          mizo: 'Editor chu app hranah a awm ta.',
          kashmiri: 'ایڈیٹر چُھ وۄنؠ اَکھ اَلگ ایپَس منٛز دستیاب۔',
          ladakhi: 'རྩོམ་སྒྲིག་པ་ད་ལྟ་མཉེན་ཆས་ལོགས་སུ་ཡོད།',
        ),
      );
    } finally {
      _endAction();
    }
  }

  String _formatEngagementCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toString();
  }

  int _displayCountWithLocalDelta(String kind, int localDelta) {
    final baseDisplay = item.displayCountFor(kind);
    return baseDisplay + math.max(0, localDelta);
  }

  Widget _buildPlainEngagementCount({
    required IconData icon,
    required int value,
    required MainAxisAlignment alignment,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            _formatEngagementCount(value),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterEngagementCounts() {
    final localShareAndDownloadDelta =
        _localShareCountDelta + _localDownloadCountDelta;
    final shareAndDownloadCount =
        item.displayCombinedEngagementCount() + localShareAndDownloadDelta;
    final viewCount = math.max(
      _displayCountWithLocalDelta('view', _localViewCountDelta),
      shareAndDownloadCount + 1,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          _buildPlainEngagementCount(
            icon: Icons.visibility_rounded,
            value: viewCount,
            alignment: MainAxisAlignment.start,
          ),
          _buildPlainEngagementCount(
            icon: Icons.send_rounded,
            value: shareAndDownloadCount,
            alignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
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
              const SizedBox(height: 4),
              _buildPosterEngagementCounts(),
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
                                  ? 'Preparing...'
                                  : _posterShareLabel(context),
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
                                  telugu: 'ఫోటో',
                                  english: 'Photo',
                                  hindi: 'फ़ोटो',
                                  tamil: 'புகைப்படம்',
                                  kannada: 'ಫೋಟೋ',
                                  malayalam: 'ഫോട്ടോ',
                                  marathi: 'फोटो',
                                  gujarati: 'ફોટો',
                                  bengali: 'ছবি',
                                  punjabi: 'ਫੋਟੋ',
                                  odia: 'ଫଟୋ',
                                  assamese: 'ফটো',
                                  konkani: 'फोटो',
                                  nepali: 'तस्विर',
                                  meitei: 'ফোতো',
                                  mizo: 'Thlalak',
                                  kashmiri: 'فوٹو',
                                  ladakhi: 'པར།',
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
                                  ? 'Preparing...'
                                  : _posterDownloadLabel(context),
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
                      final showEditButton = widget.showPosterEditButton;
                      return Row(
                        children: <Widget>[
                          if (showEditButton)
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
                                    telugu: 'ఎడిట్',
                                    english: 'Edit',
                                    hindi: 'संपादित करें',
                                    tamil: 'திருத்து',
                                    kannada: 'ಸಂಪಾದಿಸಿ',
                                    malayalam: 'എഡിറ്റ് ചെയ്യുക',
                                    marathi: 'संपादित करा',
                                    gujarati: 'સંપાદિત કરો',
                                    bengali: 'সম্পাদনা',
                                    punjabi: 'ਸੰਪਾਦਨ',
                                    odia: 'ସମ୍ପାଦନା',
                                    assamese: 'সম্পাদনা',
                                    konkani: 'बदल करा',
                                    nepali: 'सम्पादन गर्नुहोस्',
                                    meitei: 'শেমদোকপা',
                                    mizo: 'Siamthatna',
                                    kashmiri: 'ترمیٖم',
                                    ladakhi: 'རྩོམ་སྒྲིག',
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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          if (_canAddPoliticalProtocolPhotos) ...<Widget>[
                            if (showEditButton) const SizedBox(width: 8),
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
                                label: Text(
                                  strings.addPoliticalPhotos,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
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
                                  telugu: 'డిజైన్ మార్చండి',
                                  english: 'Change Design',
                                  hindi: 'डिज़ाइन बदलें',
                                  tamil: 'வடிவமைப்பை மாற்று',
                                  kannada: 'ವಿನ್ಯಾಸ ಬದಲಾಯಿಸಿ',
                                  malayalam: 'ഡിസൈൻ മാറ്റുക',
                                  marathi: 'डिझाइन बदला',
                                  gujarati: 'ડિઝાઇન બદલો',
                                  bengali: 'ডিজাইন পরিবর্তন করুন',
                                  punjabi: 'ਡਿਜ਼ਾਈਨ ਬਦਲੋ',
                                  odia: 'ଡିଜାଇନ୍ ବଦଳାନ୍ତୁ',
                                  assamese: 'ডিজাইন সলনি কৰক',
                                  konkani: 'डिझाइन बदलात',
                                  nepali: 'डिजाइन परिवर्तन गर्नुहोस्',
                                  meitei: 'দিজাইন হোংদোকউ',
                                  mizo: 'Design thlak rawh',
                                  kashmiri: 'ڈیزائن بَدلٲوِو',
                                  ladakhi: 'བཟོ་བཀོད་བརྗེ་པོ་རྒྱོབ།',
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

    if (widget.previewOnly) {
      return ValueListenableBuilder<bool>(
        valueListenable: _showPosterPhotoNotifier,
        builder: (context, isPhotoVisible, _) {
          final preview = _buildPosterPreview(
            isPhotoVisible: isPhotoVisible,
            playbackEnabledOverride: true,
            enableFullScreenTap: false,
          );
          final aspectRatio =
              _resolvedPreviewAspectRatio ??
              item.pageConfig?.aspectRatio ??
              (item.isVideo ? 9 / 16 : null);
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              if (aspectRatio != null && aspectRatio > 0) {
                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    height: maxWidth / aspectRatio,
                    child: preview,
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: preview,
                ),
              );
            },
          );
        },
      );
    }

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
                                telugu: 'ఫోటో',
                                english: 'Photo',
                                hindi: 'फ़ोटो',
                                tamil: 'புகைப்படம்',
                                kannada: 'ಫೋಟೋ',
                                malayalam: 'ഫോട്ടോ',
                                marathi: 'फोटो',
                                gujarati: 'ફોટો',
                                bengali: 'ছবি',
                                punjabi: 'ਫੋਟੋ',
                                odia: 'ଫଟୋ',
                                assamese: 'ফটো',
                                konkani: 'फोटो',
                                nepali: 'तस्विर',
                                meitei: 'ফোতো',
                                mizo: 'Thlalak',
                                kashmiri: 'فوٹو',
                                ladakhi: 'པར།',
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
                        isBusy ? 'Preparing...' : _posterShareLabel(context),
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
                            telugu: 'ఫోటో',
                            english: 'Photo',
                            hindi: 'फ़ोटो',
                            tamil: 'புகைப்படம்',
                            kannada: 'ಫೋಟೋ',
                            malayalam: 'ഫോട്ടോ',
                            marathi: 'फोटो',
                            gujarati: 'ફોટો',
                            bengali: 'ছবি',
                            punjabi: 'ਫੋਟੋ',
                            odia: 'ଫଟୋ',
                            assamese: 'ফটো',
                            konkani: 'फोटो',
                            nepali: 'तस्विर',
                            meitei: 'ফোতো',
                            mizo: 'Thlalak',
                            kashmiri: 'فوٹو',
                            ladakhi: 'པར།',
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
                        isBusy ? 'Preparing...' : _posterDownloadLabel(context),
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
                final showEditButton = widget.showPosterEditButton;
                return Row(
                  children: <Widget>[
                    if (showEditButton)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controlsDisabled
                              ? null
                              : () =>
                                    unawaited(_openPosterPhotoEditor(context)),
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
                              telugu: 'ఎడిట్',
                              english: 'Edit',
                              hindi: 'संपादित करें',
                              tamil: 'திருத்து',
                              kannada: 'ಸಂಪಾದಿಸಿ',
                              malayalam: 'എഡിറ്റ് ചെയ്യുക',
                              marathi: 'संपादित करा',
                              gujarati: 'સંપાદિત કરો',
                              bengali: 'সম্পাদনা',
                              punjabi: 'ਸੰਪਾਦਨ',
                              odia: 'ସମ୍ପାଦନା',
                              assamese: 'সম্পাদনা',
                              konkani: 'बदल करा',
                              nepali: 'सम्पादन गर्नुहोस्',
                              meitei: 'শেমদোকপা',
                              mizo: 'Siamthatna',
                              kashmiri: 'ترمیٖم',
                              ladakhi: 'རྩོམ་སྒྲིག',
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
                      if (showEditButton) const SizedBox(width: 8),
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
                          label: Text(
                            strings.addPoliticalPhotos,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.3,
                              fontWeight: FontWeight.w800,
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
                            telugu: 'డిజైన్ మార్చండి',
                            english: 'Change Design',
                            hindi: 'डिज़ाइन बदलें',
                            tamil: 'வடிவமைப்பை மாற்று',
                            kannada: 'ವಿನ್ಯಾಸ ಬದಲಾಯಿಸಿ',
                            malayalam: 'ഡിസൈൻ മാറ്റുക',
                            marathi: 'डिझाइन बदला',
                            gujarati: 'ડિઝાઇન બદલો',
                            bengali: 'ডিজাইন পরিবর্তন করুন',
                            punjabi: 'ਡਿਜ਼ਾਈਨ ਬਦਲੋ',
                            odia: 'ଡିଜାଇନ୍ ବଦଳାନ୍ତୁ',
                            assamese: 'ডিজাইন সলনি কৰক',
                            konkani: 'डिझाइन बदलात',
                            nepali: 'डिजाइन परिवर्तन गर्नुहोस्',
                            meitei: 'দিজাইন হোংদোকউ',
                            mizo: 'Design thlak rawh',
                            kashmiri: 'ڈیزائن بَدلٲوِو',
                            ladakhi: 'བཟོ་བཀོད་བརྗེ་པོ་རྒྱོབ།',
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
                if (_shouldRetryUnavailableNetworkImage(failed) &&
                    (failed.startsWith('http://') ||
                        failed.startsWith('https://'))) {
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
                          telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                          english: 'Template image unavailable',
                          hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                          tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                          kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                          malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                          marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                          gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                          bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                          punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                          odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                          assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                          konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                          nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                          meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                          mizo: 'Template thlalak a awm lo',
                          kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                          ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                        ),
                        subtitle: strings.localized(
                          telugu:
                              'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                          english: 'Please refresh or try another template.',
                          hindi:
                              'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                          tamil:
                              'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                          kannada:
                              'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                          malayalam:
                              'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                          marathi:
                              'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                          gujarati:
                              'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                          bengali:
                              'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                          punjabi:
                              'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                          odia:
                              'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                          assamese:
                              'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                          konkani:
                              'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                          nepali:
                              'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                          meitei:
                              'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                          mizo:
                              'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                          kashmiri:
                              'مہر Ships کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                          ladakhi:
                              'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
                        ),
                      );
                    },
                  );
                }
                schedulePosterReady();
                return _ImageErrorState(
                  title: strings.localized(
                    telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                    english: 'Template image unavailable',
                    hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                    tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                    kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                    malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                    marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                    gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                    bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                    punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                    odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                    assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                    konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                    nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                    meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                    mizo: 'Template thlalak a awm lo',
                    kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                    ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                  ),
                  subtitle: strings.localized(
                    telugu:
                        'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                    english: 'Please refresh or try another template.',
                    hindi: 'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                    tamil:
                        'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                    kannada:
                        'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                    malayalam:
                        'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                    marathi: 'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                    gujarati:
                        'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                    bengali:
                        'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                    punjabi:
                        'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                    odia:
                        'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                    assamese:
                        'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                    konkani:
                        'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                    nepali:
                        'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                    meitei:
                        'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                    mizo:
                        'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                    kashmiri:
                        'مہر Ships کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                    ladakhi:
                        'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
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
                    telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                    english: 'Template image unavailable',
                    hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                    tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                    kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                    malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                    marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                    gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                    bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                    punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                    odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                    assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                    konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                    nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                    meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                    mizo: 'Template thlalak a awm lo',
                    kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                    ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                  ),
                  subtitle: strings.localized(
                    telugu:
                        'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                    english: 'Please refresh or try another template.',
                    hindi: 'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                    tamil:
                        'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                    kannada:
                        'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                    malayalam:
                        'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                    marathi: 'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                    gujarati:
                        'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                    bengali:
                        'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                    punjabi:
                        'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                    odia:
                        'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                    assamese:
                        'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                    konkani:
                        'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                    nepali:
                        'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                    meitei:
                        'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                    mizo:
                        'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                    kashmiri:
                        'مہر Ships کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                    ladakhi:
                        'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
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
                        telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                        english: 'Template image unavailable',
                        hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                        tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                        kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                        malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                        marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                        gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                        bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                        punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                        odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                        assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                        konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                        nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                        meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                        mizo: 'Template thlalak a awm lo',
                        kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                        ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                      ),
                      subtitle: context.strings.localized(
                        telugu:
                            'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                        english: 'Please refresh or try another template.',
                        hindi: 'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                        tamil:
                            'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                        kannada:
                            'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                        malayalam:
                            'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                        marathi:
                            'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                        gujarati:
                            'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                        bengali:
                            'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                        punjabi:
                            'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                        odia:
                            'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                        assamese:
                            'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                        konkani:
                            'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                        nepali:
                            'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                        meitei:
                            'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                        mizo:
                            'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                        kashmiri:
                            'مہر Ships کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                        ladakhi:
                            'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
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

class _PosterFullScreenPreview extends StatefulWidget {
  const _PosterFullScreenPreview({
    required this.title,
    required this.heroTag,
    required this.child,
    this.aspectRatio,
  });

  final String title;
  final String heroTag;
  final Widget child;
  final double? aspectRatio;

  @override
  State<_PosterFullScreenPreview> createState() =>
      _PosterFullScreenPreviewState();
}

class _PosterFullScreenPreviewState extends State<_PosterFullScreenPreview> {
  final TransformationController _transformationController =
      TransformationController();
  final Set<int> _activePointerIds = <int>{};
  bool _isZoomed = false;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final nextZoomed = scale > 1.02;
    if (nextZoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = nextZoomed);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    _updatePinchState();
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointerIds.remove(event.pointer);
    _updatePinchState();
  }

  void _updatePinchState() {
    final nextPinching = _activePointerIds.length >= 2;
    if (nextPinching != _isPinching && mounted) {
      setState(() => _isPinching = nextPinching);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAspectRatio = widget.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Hero(
                tag: widget.heroTag,
                transitionOnUserGestures: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final maxHeight = constraints.maxHeight;
                      final targetWidth = maxWidth.isFinite
                          ? maxWidth
                          : MediaQuery.sizeOf(context).width;
                      final targetHeight =
                          resolvedAspectRatio != null && resolvedAspectRatio > 0
                          ? targetWidth / resolvedAspectRatio
                          : null;
                      final preview = targetHeight == null
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: targetWidth,
                              ),
                              child: widget.child,
                            )
                          : SizedBox(
                              width: targetWidth,
                              height: targetHeight,
                              child: widget.child,
                            );
                      final blockScroll = _isZoomed || _isPinching;
                      return Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: _handlePointerDown,
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerUp,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1,
                          maxScale: 4,
                          panEnabled: blockScroll,
                          scaleEnabled: true,
                          clipBehavior: Clip.none,
                          child: SingleChildScrollView(
                            physics: blockScroll
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: maxHeight),
                              child: Center(child: preview),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: <Widget>[
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.48),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterFullScreenGallery extends StatefulWidget {
  const _PosterFullScreenGallery({
    required this.initialIndex,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
  });

  final int initialIndex;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;

  @override
  State<_PosterFullScreenGallery> createState() =>
      _PosterFullScreenGalleryState();
}

class _PosterFullScreenGalleryState extends State<_PosterFullScreenGallery> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex.clamp(0, widget.itemCount - 1),
  );
  late int _pageIndex = widget.initialIndex.clamp(0, widget.itemCount - 1);
  bool _isPageZoomed = false;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(ScreenSecurityService.unprotectScreen());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              physics: _isPageZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: widget.itemCount,
              onPageChanged: (index) {
                widget.onPageChanged?.call(index);
                _isPageZoomed = false;
                setState(() => _pageIndex = index);
              },
              itemBuilder: (context, index) {
                return _ZoomableFullScreenGalleryItem(
                  onZoomChanged: (zoomed) {
                    if (zoomed != _isPageZoomed && mounted) {
                      setState(() => _isPageZoomed = zoomed);
                    }
                  },
                  child: widget.itemBuilder(context, index),
                );
              },
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: <Widget>[
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.48),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        '${_pageIndex + 1}/${widget.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableFullScreenGalleryItem extends StatefulWidget {
  const _ZoomableFullScreenGalleryItem({
    required this.child,
    required this.onZoomChanged,
  });

  final Widget child;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableFullScreenGalleryItem> createState() =>
      _ZoomableFullScreenGalleryItemState();
}

class _ZoomableFullScreenGalleryItemState
    extends State<_ZoomableFullScreenGalleryItem> {
  final TransformationController _transformationController =
      TransformationController();
  final Set<int> _activePointerIds = <int>{};
  bool _isZoomed = false;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    widget.onZoomChanged(false);
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final nextZoomed = scale > 1.02;
    if (nextZoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = nextZoomed);
      widget.onZoomChanged(nextZoomed || _isPinching);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    _updatePinchState();
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointerIds.remove(event.pointer);
    _updatePinchState();
  }

  void _updatePinchState() {
    final nextPinching = _activePointerIds.length >= 2;
    if (nextPinching != _isPinching && mounted) {
      setState(() => _isPinching = nextPinching);
      widget.onZoomChanged(nextPinching || _isZoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockPageScroll = _isZoomed || _isPinching;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1,
        maxScale: 4,
        panEnabled: blockPageScroll,
        scaleEnabled: true,
        clipBehavior: Clip.none,
        child: Center(child: widget.child),
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

// ignore: unused_element
class _FreeExportPreviewCard extends StatelessWidget {
  const _FreeExportPreviewCard({
    required this.title,
    required this.message,
    required this.accentColor,
    required this.preview,
    required this.previewAspectRatio,
    this.actionLabel,
    this.onTap,
    this.footer,
  });

  final String title;
  final String message;
  final Color accentColor;
  final Widget preview;
  final double previewAspectRatio;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final previewWidth = (constraints.maxWidth * 0.44)
            .clamp(142.0, 178.0)
            .toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: previewWidth,
                  child: AspectRatio(
                    aspectRatio: previewAspectRatio <= 0
                        ? 4 / 5
                        : previewAspectRatio,
                    child: ClipRect(child: preview),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (footer != null)
                        footer!
                      else if (actionLabel != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Text(
                                actionLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _HomeExportManualAdDialog extends StatefulWidget {
  const _HomeExportManualAdDialog({required this.ad});

  final HomeExportManualAd ad;

  @override
  State<_HomeExportManualAdDialog> createState() =>
      _HomeExportManualAdDialogState();
}

class _HomeExportManualAdDialogState extends State<_HomeExportManualAdDialog> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.ad.isVideo) {
      unawaited(_loadVideo());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    final uri = Uri.tryParse(widget.ad.url.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _videoFailed = true);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _videoFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showVideo =
        widget.ad.isVideo &&
        !_videoFailed &&
        controller != null &&
        controller.value.isInitialized;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: showVideo
                  ? controller.value.aspectRatio
                  : widget.ad.isVideo
                  ? 9 / 16
                  : 4 / 5,
              child: ColoredBox(
                color: const Color(0xFF0F172A),
                child: widget.ad.isVideo
                    ? showVideo
                          ? VideoPlayer(controller)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                    : CachedNetworkImage(
                        imageUrl: widget.ad.url,
                        cacheManager: PosterNetworkImageCache.instance,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.strings.localized(
                      telugu: 'కొనసాగించండి',
                      english: 'Continue',
                      hindi: 'जारी रखें',
                      tamil: 'தொடரவும்',
                      kannada: 'ಮುಂದುವರಿಸಿ',
                      malayalam: 'തുടരുക',
                      marathi: 'पुढे चालू ठेवा',
                      gujarati: 'ચાલુ રાખો',
                      bengali: 'চালিয়ে যান',
                      punjabi: 'ਜਾਰੀ ਰੱਖੋ',
                      odia: 'ଜାରି ରଖନ୍ତୁ',
                      assamese: 'অব্যাহত ৰাখক',
                      konkani: 'चालू दवरात',
                      nepali: 'जारी राख्नुहोस्',
                      meitei: 'মখা চত্থবীয়ু',
                      mizo: 'Chhunzawm rawh',
                      kashmiri: 'جٲری تھٲوِو',
                      ladakhi: 'མུ་མཐུད་དུ་བྱོས།',
                    ),
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
    this.onOpenPreview,
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
  final VoidCallback? onOpenPreview;
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
        onOpenPreview: widget.onOpenPreview,
        onReplay: widget.onReplay,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOpenPreview ?? () => setState(() => _playing = true),
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
    this.onOpenPreview,
    this.onReplay,
  });

  final String videoUrl;
  final bool playbackEnabled;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onReady;
  final VoidCallback? onOpenPreview;
  final VoidCallback? onReplay;

  @override
  State<_TemplateVideoPlayer> createState() => _TemplateVideoPlayerState();
}

class _TemplateVideoPlayerState extends State<_TemplateVideoPlayer> {
  static const Duration _initialVideoInitDelay = Duration(milliseconds: 900);

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
      Future<void>.delayed(_initialVideoInitDelay, () {
        _initializeWhenSettled();
      });
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
        Future<void>.delayed(_initialVideoInitDelay, () {
          _initializeWhenSettled();
        });
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
          telugu: 'వీడియో అందుబాటులో లేదు',
          english: 'Video unavailable',
          hindi: 'वीडियो उपलब्ध नहीं है',
          tamil: 'வீடியோ கிடைக்கவில்லை',
          kannada: 'ವೀಡಿಯೊ ಲಭ್ಯವಿಲ್ಲ',
          malayalam: 'വീഡിയോ ലഭ്യമല്ല',
          marathi: 'व्हिडिओ उपलब्ध नाही',
          gujarati: 'વીડિયો ઉપલબ્ધ નથી',
          bengali: 'ভিডিও উপলব্ধ নয়',
          punjabi: 'ਵੀਡੀਓ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
          odia: 'ଭିଡିଓ ଉପଲବ୍ଧ ନାହିଁ',
          assamese: 'ভিডিঅ’ উপলব্ধ নহয়',
          konkani: 'व्हिडिओ उपलब्ध ना',
          nepali: 'भिडियो उपलब्ध छैन',
          meitei: 'ভিদিও ফংদে',
          mizo: 'Video a awm lo',
          kashmiri: 'ویڈیو چھُنہٕ دستیاب',
          ladakhi: 'བརྙན་འཕྲིན་མི་འདུག',
        ),
        subtitle: context.strings.localized(
          telugu: 'దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'Please try again.',
          hindi: 'कृपया पुनः प्रयास करें।',
          tamil: 'மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali: 'অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi: 'ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'उपकार करून परत यत्न करा.',
          nepali: 'कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
          mizo: 'Khawngaihin ti nawn leh rawh.',
          kashmiri: 'مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
          ladakhi: 'སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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
    final aspectRatio = videoWidth > 0 && videoHeight > 0
        ? videoWidth / videoHeight
        : 9 / 16;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOpenPreview ?? () => unawaited(_togglePlayback()),
      child: AspectRatio(
        aspectRatio: aspectRatio,
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

class CreatorPosterPreview extends StatefulWidget {
  const CreatorPosterPreview({
    super.key,
    this.imageAssetPath,
    this.imageUrl,
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
    this.hiddenPoliticalProtocolPhotoUrls = const <String>{},
    this.politicalProtocolLocalPhotoPaths = const <String>[],
    this.politicalProtocolSlotsOverride,
    this.politicalProtocolManualSlots = const <PoliticalProtocolSlot>[],
    this.showPoliticalProtocolOverlay = false,
    this.showProfilePhoto = true,
    this.deferLegacyTextPrime = false,
    this.posterRenderCycle = 0,
    this.interactivePhotoEnabled = false,
    this.photoShapeOverride = '',
    this.photoRenderModeOverride = '',
    this.photoFlipHorizontally = false,
    this.photoXOffsetPercent = 0,
    this.photoYOffsetPercent = 0,
    this.onPhotoTap,
    this.stripGradientTapOffset = 0,
    this.onNameStripTap,
    this.additionalPhotoSelection,
    this.onAdditionalPhotoTap,
    this.onPhotoDragDeltaPercent,
    this.onPhotoDragStateChanged,
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
  final Set<String> hiddenPoliticalProtocolPhotoUrls;
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
  final VoidCallback? onPhotoTap;
  final int stripGradientTapOffset;
  final VoidCallback? onNameStripTap;
  final PosterExtraPhotoSelection? additionalPhotoSelection;
  final VoidCallback? onAdditionalPhotoTap;
  final void Function({
    required double deltaXPercent,
    required double deltaYPercent,
  })?
  onPhotoDragDeltaPercent;
  final ValueChanged<bool>? onPhotoDragStateChanged;
  final ValueChanged<double>? onAspectRatioResolved;
  final ValueChanged<bool>? onPosterReadyChanged;

  @override
  State<CreatorPosterPreview> createState() => CreatorPosterPreviewState();
}

typedef _CreatorPosterPreview = CreatorPosterPreview;

String _normalizePosterStripLayoutStyle(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'split':
    case 'badge':
    case 'full':
      return raw!.trim().toLowerCase();
    default:
      return 'full';
  }
}

typedef _CreatorPosterPreviewState = CreatorPosterPreviewState;

class CreatorPosterPreviewState extends State<CreatorPosterPreview> {
  static const String _visibleTeluguFallbackFontFamily =
      'Anek Telugu Condensed Regular';
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');

  static const List<String> _randomPosterNameFonts = <String>[
    'Pallavi Bold',
    'Pallavi Medium',
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

  static const List<Color> _posterStripSolidColors = <Color>[
    Color(0xFF111827),
    Color(0xFF0F172A),
    Color(0xFF064E3B),
    Color(0xFF1E3A8A),
    Color(0xFF581C87),
    Color(0xFF7F1D1D),
    Color(0xFF134E4A),
    Color(0xFF3F1D38),
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
  ];
  static int get posterStripGradientCount => _posterStripSolidColors.length;

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
  void didUpdateWidget(covariant CreatorPosterPreview oldWidget) {
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
    widget.onPhotoDragStateChanged?.call(true);
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
    widget.onPhotoDragDeltaPercent?.call(
      deltaXPercent: (appliedDeltaX / maxWidth) * 100,
      deltaYPercent: (appliedDeltaY / totalCanvasHeight) * 100,
    );
  }

  void _endPhotoDrag() {
    _activePhotoDragLastGlobalPosition = null;
    widget.onPhotoDragStateChanged?.call(false);
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

  Color _resolvePosterStripColor(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|$resolvedName';
    var hash = 23;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 41 * hash + codeUnit;
    }
    final baseIndex = hash.abs() % _posterStripSolidColors.length;
    final resolvedIndex =
        (baseIndex + widget.stripGradientTapOffset) %
        _posterStripSolidColors.length;
    return _posterStripSolidColors[resolvedIndex];
  }

  Color _onStripColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF111827);
  }

  Color _mutedOnStripColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF334155);
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
    if (_showPartyLogoInNameChip || logoPath == null || logoPath.isEmpty) {
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

  bool get _showPartyLogoInNameChip {
    final logoPath = widget.partyLogoAssetPath?.trim();
    return logoPath != null && logoPath.isNotEmpty;
  }

  Widget _buildPartyLogoForNameChip({double size = 24}) {
    final logoPath = widget.partyLogoAssetPath!.trim();
    final lower = logoPath.toLowerCase();
    final isNetwork =
        lower.startsWith('https://') || lower.startsWith('http://');
    final isSvg = lower.endsWith('.svg') || lower.contains('.svg?');
    final fallback = Icon(
      Icons.flag_rounded,
      color: const Color(0xFF64748B),
      size: (size * 0.56).clamp(12.0, 20.0),
    );
    final logo = isNetwork
        ? (isSvg
              ? SvgPicture.network(
                  logoPath,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => fallback,
                )
              : CachedNetworkImage(
                  imageUrl: logoPath,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ))
        : (isSvg
              ? SvgPicture.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => fallback,
                )
              : Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => fallback,
                ));

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all((size * 0.035).clamp(0.5, 1.2)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: (size * 0.018).clamp(0.4, 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(child: logo),
    );
  }

  Widget _buildNameWithOptionalPartyLogo({
    required Widget name,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    double logoSize = 24,
    double gap = 6,
  }) {
    if (!_showPartyLogoInNameChip) {
      return name;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: <Widget>[
        _buildPartyLogoForNameChip(size: logoSize),
        SizedBox(width: gap),
        Flexible(child: name),
      ],
    );
  }

  double _nameChipPartyLogoSize(double stripPixelHeight) {
    return (stripPixelHeight * 0.92).clamp(24.0, 64.0).toDouble();
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
    double partyLogoSize = 28,
  }) {
    final hasDesignation = resolvedDesignation.isNotEmpty;
    if (!hasDesignation && !showPhoneInStrip) {
      return Center(
        child: _buildNameWithOptionalPartyLogo(
          logoSize: partyLogoSize,
          name: _legacyAwareText(
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
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              if (_showPartyLogoInNameChip) ...<Widget>[
                _buildPartyLogoForNameChip(size: partyLogoSize),
                const SizedBox(width: 8),
              ],
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
            fontFamily == 'Pallavi Medium' ||
            fontFamily == 'Pallavi Bold');
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
    final primaryDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : widget.viewerPosterProfile.secondaryPersonalDesignation;
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final primaryDesignationFontFamily = _resolveDesignationFontFamily(
      primaryDesignation,
    );
    final secondaryDesignationFontFamily = _resolveDesignationFontFamily(
      secondaryDesignation,
    );
    return _legacyTextNeedsAsyncPrime(resolvedName, displayNameFontFamily) ||
        _legacyTextNeedsAsyncPrime(
          primaryDesignation,
          primaryDesignationFontFamily,
        ) ||
        (secondaryDesignation.isNotEmpty &&
            _legacyTextNeedsAsyncPrime(
              secondaryDesignation,
              secondaryDesignationFontFamily,
            ));
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
    final primaryDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : widget.viewerPosterProfile.secondaryPersonalDesignation;
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final entries = await Future.wait<MapEntry<String, String>?>(
      <Future<MapEntry<String, String>?>>[
        _primeLegacyTextValue(resolvedName, displayNameFontFamily),
        _primeLegacyTextValue(
          primaryDesignation,
          _resolveDesignationFontFamily(primaryDesignation),
        ),
        if (secondaryDesignation.isNotEmpty)
          _primeLegacyTextValue(
            secondaryDesignation,
            _resolveDesignationFontFamily(secondaryDesignation),
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
      final fitAlignment = switch (textAlign) {
        TextAlign.left || TextAlign.start => Alignment.centerLeft,
        TextAlign.right || TextAlign.end => Alignment.centerRight,
        _ => Alignment.center,
      };
      return SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: fitAlignment,
          child: textWidget,
        ),
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
    final primaryDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : widget.viewerPosterProfile.secondaryPersonalDesignation;
    final hasBothPersonalDesignations = !isBusinessProfile &&
        primaryDesignation.isNotEmpty &&
        secondaryDesignation.isNotEmpty;
    final resolvedDesignation = primaryDesignation.isNotEmpty
        ? primaryDesignation
        : secondaryDesignation;
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
    final secondaryDesignationFontFamily = _resolveDesignationFontFamily(
      secondaryDesignation,
    );
    final usesLegacyTeluguDesignationFont = _usesLegacyTeluguStripFont(
      resolvedDesignation,
      designationFontFamily,
    );
    final usesLegacyTeluguSecondaryDesignationFont = _usesLegacyTeluguStripFont(
      secondaryDesignation,
      secondaryDesignationFontFamily,
    );
    final legacyTeluguDesignationBoost = (usesLegacyTeluguDesignationFont ||
            usesLegacyTeluguSecondaryDesignationFont)
        ? 1.34
        : 1.0;
    final personalDesignationFontSize =
        31.0 * designationScaleFactor * legacyTeluguDesignationBoost;
    final businessDesignationFontSize =
        28.0 * designationScaleFactor * legacyTeluguDesignationBoost;
    final englishDesignationFontSize = 23.0 * designationScaleFactor;
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
        resolvedSecondaryDesignation: secondaryDesignation,
        displayNameFontFamily: displayNameFontFamily,
        designationFontFamily: designationFontFamily,
        secondaryDesignationFontFamily: secondaryDesignationFontFamily,
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
                    (usesLegacyTeluguDesignationFont ? 1.28 : 1.10) *
                    (hasBothPersonalDesignations ? 1.45 : 1.0)
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
                      hiddenImageUrls: widget.hiddenPoliticalProtocolPhotoUrls,
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
                                    : (widget
                                              .viewerPosterProfile
                                              .preferOriginalPersonalPhoto
                                          ? 'circle'
                                          : widget
                                                .personalizationConfig
                                                .photoShape));
                          final effectivePhotoRenderMode = isBusinessProfile
                              ? 'original'
                              : (widget.photoRenderModeOverride
                                        .trim()
                                        .isNotEmpty
                                    ? widget.photoRenderModeOverride.trim()
                                    : (widget
                                              .viewerPosterProfile
                                              .preferOriginalPersonalPhoto
                                          ? 'original'
                                          : widget
                                                .personalizationConfig
                                                .photoRenderMode));
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
                                                  'original' ||
                                              widget
                                                  .viewerPosterProfile
                                                  .preferOriginalPersonalPhoto,
                                          allowOriginalFallbackWhenCutoutUnavailable:
                                              true,
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
                                                color: Colors.black.withValues(
                                                  alpha: 0.34,
                                                ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2.5,
                                                ),
                                                boxShadow: <BoxShadow>[
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.22,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        const Icon(
                                                          Icons
                                                              .add_a_photo_rounded,
                                                          color: Colors.white,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          context.strings.localized(
                                                            telugu:
                                                                'ఫోటో జోడించండి',
                                                            english:
                                                                'Add Photo',
                                                            hindi:
                                                                'फ़ोटो जोड़ें',
                                                            tamil:
                                                                'புகைப்படம் சேர்க்கவும்',
                                                            kannada:
                                                                'ಫೋಟೋ ಸೇರಿಸಿ',
                                                            malayalam:
                                                                'ഫോട്ടോ ചേർക്കുക',
                                                            marathi:
                                                                'फोटो जोडा',
                                                            gujarati:
                                                                'ફોટો ઉમેરો',
                                                            bengali:
                                                                'ফটো যোগ করুন',
                                                            punjabi:
                                                                'ਫੋਟੋ ਸ਼ਾਮਲ ਕਰੋ',
                                                            odia:
                                                                'ଫଟୋ ଯୋଡ଼ନ୍ତୁ',
                                                            assamese:
                                                                'ফটো যোগ কৰক',
                                                            konkani:
                                                                'फोटो जोडा',
                                                            nepali:
                                                                'तस्विर थप्नुहोस्',
                                                            meitei:
                                                                'ফোতো হাপচিনবীয়ু',
                                                            mizo:
                                                                'Thlalak dah rawh',
                                                            kashmiri:
                                                                'فوٹو رَلاوِو',
                                                            ladakhi: 'པར་སྣོན།',
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                height: 1.05,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
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
    String? resolvedSecondaryDesignation,
    required String? displayNameFontFamily,
    required String designationFontFamily,
    String? secondaryDesignationFontFamily,
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
    final stripColor = _resolvePosterStripColor(resolvedName);
    final stripTextColor = _onStripColor(stripColor);
    final mutedStripTextColor = _mutedOnStripColor(stripColor);
    final dividerColor = mutedStripTextColor;
    final partyLogoSize = _nameChipPartyLogoSize(stripPixelHeight);
    final hasBothDesignations = !isBusinessProfile &&
        resolvedSecondaryDesignation != null &&
        resolvedSecondaryDesignation.trim().isNotEmpty &&
        resolvedDesignation.trim().isNotEmpty;
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
          if (_showPartyLogoInNameChip) ...<Widget>[
            _buildPartyLogoForNameChip(size: partyLogoSize),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: 54,
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
            flex: 46,
            child: hasBothDesignations
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _legacyAwareText(
                        text: resolvedDesignation,
                        fontFamily: designationFontFamily,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        fitToWidth: true,
                        style: TextStyle(
                          color: mutedStripTextColor,
                          fontWeight: designationFontWeight,
                          fontSize: designationFontSize * 0.84,
                          height: designationHeight,
                        ),
                      ),
                      const SizedBox(height: 1),
                      _legacyAwareText(
                        text: resolvedSecondaryDesignation,
                        fontFamily: secondaryDesignationFontFamily ??
                            designationFontFamily,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        fitToWidth: true,
                        style: TextStyle(
                          color: mutedStripTextColor.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w400,
                          fontSize: designationFontSize * 0.72,
                          height: designationHeight,
                        ),
                      ),
                    ],
                  )
                : _legacyAwareText(
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

    Widget buildSingleName({
      required double nameFontSize,
      required FontWeight nameFontWeight,
      required double nameHeight,
      TextAlign textAlign = TextAlign.center,
      MainAxisAlignment alignment = MainAxisAlignment.center,
    }) {
      return _buildNameWithOptionalPartyLogo(
        alignment: alignment,
        logoSize: partyLogoSize,
        gap: 8,
        name: _legacyAwareText(
          text: resolvedName,
          fontFamily: displayNameFontFamily,
          maxLines: 1,
          textAlign: textAlign,
          fitToWidth: true,
          style: TextStyle(
            color: stripTextColor,
            fontWeight: nameFontWeight,
            fontSize: nameFontSize,
            height: nameHeight,
          ),
        ),
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
                              partyLogoSize: partyLogoSize,
                            )
                          : _buildNameWithOptionalPartyLogo(
                              alignment: MainAxisAlignment.start,
                              logoSize: partyLogoSize,
                              gap: 8,
                              name: _legacyAwareText(
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
                    ),
                  ],
                )
        else if (_isEnglishOnlyText(resolvedName) &&
            resolvedDesignation.isEmpty) ...<Widget>[
          _buildNameWithOptionalPartyLogo(
            logoSize: partyLogoSize,
            name: _legacyAwareText(
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
            buildSingleName(
              nameFontSize: personalNameFontSize,
              nameFontWeight: FontWeight.w500,
              nameHeight: personalNameLineHeight,
            ),
        ],
      ],
    );

    return _wrapPosterBottomStrip(
      stripColor: stripColor,
      bottomStripPadding: bottomStripPadding,
      child: content,
    );
  }

  Widget _wrapPosterBottomStrip({
    required Color stripColor,
    required double bottomStripPadding,
    required Widget child,
  }) {
    final strip = Container(
      width: double.infinity,
      decoration: BoxDecoration(color: stripColor),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: bottomStripPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(width: constraints.maxWidth, child: child),
              ),
            );
          },
        ),
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
      return currentEdgeStyle == 'bottom_fade' || currentEdgeStyle == 'feather'
          ? currentEdgeStyle
          : 'feather';
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
      if (shape == 'transparent_soft_round') {
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const RadialGradient(
              center: Alignment(0, -0.6),
              radius: 0.92,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xFAFFFFFF),
                Color(0xDBFFFFFF),
                Color(0x8FFFFFFF),
                Color(0x38FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.58, 0.68, 0.77, 0.86, 0.93, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xE6FFFFFF),
                Color(0x99FFFFFF),
                Color(0x33FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.64, 0.76, 0.86, 0.94, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
      } else if (normalizedEdgeStyle == 'feather') {
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
      if (normalizedEdgeStyle == 'feather' &&
          shape != 'transparent_soft_round' &&
          !shouldDeferHeavyEffects) {
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

    if (_isTransparentRoundShape(shape)) {
      return ClipOval(clipBehavior: Clip.antiAlias, child: framedChild);
    }

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
                      telugu: 'పోస్టర్లు లోడ్ అయ్యే వరకు స్నేక్ గేమ్ ఆడండి',
                      english: 'Play Snake while posters load',
                      hindi: 'पोस्टर लोड होने तक स्नेक गेम खेलें',
                      tamil:
                          'போஸ்டர்கள் ஏற்றப்படும் வரை ஸ்னேக் கேம் விளையாடுங்கள்',
                      kannada: 'ಪೋಸ್ಟರ್‌ಗಳು ಲೋಡ್ ಆಗುವವರೆಗೆ ಸ್ನೇಕ್ ಗೇಮ್ ಆಡಿ',
                      malayalam:
                          'പോസ്റ്ററുകൾ ലോഡാകുന്നതുവരെ സ്നേക്ക് ഗെയിം കളിക്കുക',
                      marathi: 'पोस्टर्स लोड होईपर्यंत स्नेक गेम खेळा',
                      gujarati: 'પોસ્ટરો લોડ થાય ત્યાં સુધી સ્નેક ગેમ રમો',
                      bengali: 'পোস্টার লোড হওয়ার সময় স্নেক গেম খেলুন',
                      punjabi: 'ਪੋਸਟਰ ਲੋਡ ਹੋਣ ਤੱਕ ਸੱਪ ਵਾਲੀ ਗੇਮ ਖੇਡੋ',
                      odia: 'ପୋଷ୍ଟର ଲୋଡ୍ ହେବା ପର୍ଯ୍ୟନ୍ତ ସ୍ନେକ୍ ଗେମ୍ ଖେଳନ୍ତୁ',
                      assamese: 'পোষ্টাৰ লোড হোৱালৈকে স্নেক গেম খেলক',
                      konkani: 'पोस्टरां लोड जावंचे मेरेन स्नेक खेळ खेळात',
                      nepali: 'पोस्टर लोड हुँदा सम्म स्नेक गेम खेल्नुहोस्',
                      meitei: 'পোস্তরশিং লোদ ওইরিঙৈ মনুংদা স্নেক শান্নবীয়ু',
                      mizo: 'Poster load chhungin Snake game khel rawh',
                      kashmiri: 'پوسٹر لوڈ گژھنس تام گِندِو سنیک گیم',
                      ladakhi: 'པོ་སི་ཊར་མ་བསླེབ་བར་དུ་སྦྲུལ་གྱི་རྩེད་མོ་རྩེས།',
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
                telugu: 'ఆడండి',
                english: 'Play',
                hindi: 'खेलें',
                tamil: 'விளையாடு',
                kannada: 'ಆಟವಾಡಿ',
                malayalam: 'കളിക്കുക',
                marathi: 'खेळा',
                gujarati: 'રમો',
                bengali: 'খেলুন',
                punjabi: 'ਖੇਡੋ',
                odia: 'ଖେଳନ୍ତୁ',
                assamese: 'খেলক',
                konkani: 'खेळात',
                nepali: 'खेल्नुहोस्',
                meitei: 'শান্নবীয়ু',
                mizo: 'Khel rawh',
                kashmiri: 'گِندِو',
                ladakhi: 'རྩེས།',
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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + bottomInset),
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
                    telugu: 'స్నేక్ గేమ్',
                    english: 'Snake Game',
                    hindi: 'स्नेक गेम',
                    tamil: 'ஸ்னேக் கேம்',
                    kannada: 'ಸ್ನೇಕ್ ಗೇಮ್',
                    malayalam: 'സ്നേക്ക് ഗെയിം',
                    marathi: 'स्नेक गेम',
                    gujarati: 'સ્નેક ગેમ',
                    bengali: 'স্নেক গেম',
                    punjabi: 'ਸੱਪ ਵਾਲੀ ਗੇਮ',
                    odia: 'ସ୍ନେକ୍ ଗେମ୍',
                    assamese: 'স্নেক গেম',
                    konkani: 'स्नेक खेळ',
                    nepali: 'स्नेक गेम',
                    meitei: 'স্নেক শান্নপোৎ',
                    mizo: 'Snake Game',
                    kashmiri: 'سنیک گیم',
                    ladakhi: 'སྦྲུལ་གྱི་རྩེད་མོ།',
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
                                  telugu: 'గేమ్ ముగిసింది',
                                  english: 'Game Over',
                                  hindi: 'खेल समाप्त',
                                  tamil: 'ஆட்டம் முடிந்தது',
                                  kannada: 'ಆಟ ಮುಕ್ತಾಯ',
                                  malayalam: 'ഗെയിം അവസാനിച്ചു',
                                  marathi: 'खेळ संपला',
                                  gujarati: 'રમત સમાપ્ત',
                                  bengali: 'খেলা সমাপ্ত',
                                  punjabi: 'ਗੇਮ ਖਤਮ',
                                  odia: 'ଖେଳ ସମାପ୍ତ',
                                  assamese: 'খেল সমাপ্ত',
                                  konkani: 'खेळ सोंपलो',
                                  nepali: 'खेल समाप्त',
                                  meitei: 'শান্নবা লোইরে',
                                  mizo: 'Game tawp',
                                  kashmiri: 'گیم گوو ختم',
                                  ladakhi: 'རྩེད་མོ་རྫོགས།',
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
                                    telugu: 'మళ్లీ ఆడండి',
                                    english: 'Play again',
                                    hindi: 'फिर से खेलें',
                                    tamil: 'மீண்டும் விளையாடு',
                                    kannada: 'ಮತ್ತೆ ಆಟವಾಡಿ',
                                    malayalam: 'വീണ്ടും കളിക്കുക',
                                    marathi: 'पुन्हा खेळा',
                                    gujarati: 'ફરીથી રમો',
                                    bengali: 'আবার খেলুন',
                                    punjabi: 'ਦੁਬਾਰਾ ਖੇਡੋ',
                                    odia: 'ପୁନର୍ବାର ଖେଳନ୍ତୁ',
                                    assamese: 'পুনৰ খেলক',
                                    konkani: 'परत खेळात',
                                    nepali: 'फेरि खेल्नुहोस्',
                                    meitei: 'অমুক হন্না শান্নবীয়ু',
                                    mizo: 'Khel nawn leh rawh',
                                    kashmiri: 'دُوبارٕ گِندِو',
                                    ladakhi: 'ཡང་བསྐྱར་རྩེས།',
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
                                  telugu: 'పాజ్ చేయబడింది',
                                  english: 'Paused',
                                  hindi: 'रोका गया',
                                  tamil: 'இடைநிறுத்தப்பட்டது',
                                  kannada: 'ವಿರಾಮಗೊಳಿಸಲಾಗಿದೆ',
                                  malayalam: 'താൽക്കാലികമായി നിർത്തി',
                                  marathi: 'थांबवले',
                                  gujarati: 'થોભાવેલ',
                                  bengali: 'বিরতি দেওয়া হয়েছে',
                                  punjabi: 'ਰੋਕਿਆ ਗਿਆ',
                                  odia: 'ସ୍ଥଗିତ',
                                  assamese: 'স্থগিত কৰা হ’ল',
                                  konkani: 'थांबयलां',
                                  nepali: 'रोकिएको',
                                  meitei: 'লেপলেপ তৌরে',
                                  mizo: 'Chawl rih',
                                  kashmiri: 'روٗکِتھ',
                                  ladakhi: 'བར་མཚམས་བཞག',
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
          SafeArea(
            top: false,
            left: false,
            right: false,
            minimum: const EdgeInsets.only(bottom: 6),
            child: Row(
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