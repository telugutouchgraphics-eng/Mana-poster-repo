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


part '../widgets/home_banner_widget.dart';
part '../widgets/home_referral_dialog_widget.dart';
part '../widgets/home_header_widget.dart';
part '../widgets/home_promo_card_widget.dart';
part '../widgets/home_category_chips_widget.dart';
part '../widgets/home_hero_banner_widget.dart';
part '../widgets/home_profile_avatar_widget.dart';
part '../widgets/home_category_chip_widget.dart';
part '../widgets/home_video_side_actions_widget.dart';
part '../widgets/home_political_protocol_widget.dart';
part '../widgets/home_editable_protocol_widget.dart';
part '../widgets/home_template_feed_item_widget.dart';
part '../widgets/home_poster_image_widget.dart';
part '../widgets/home_fullscreen_preview_widget.dart';
part '../widgets/home_subscription_info_widget.dart';
part '../widgets/home_export_ad_dialog_widget.dart';
part '../widgets/home_subscription_dialog_widget.dart';
part '../widgets/home_video_player_widget.dart';
part '../widgets/home_creator_preview_widget.dart';
part '../widgets/home_photo_frame_widget.dart';
part '../widgets/home_feed_state_widget.dart';
part '../widgets/home_snake_game_widget.dart';
part '../widgets/home_skeleton_widget.dart';

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
                'لِنک ہیٚکہ نہٕ کٔڈِتھ۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
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

  /// Firestore `categoryId` only, used for home dynamic chips, not label tokens.
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

  static const int _dynamicMorePreviewDays = 0;
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
  bool _adFallbackSlotEnabled = true;
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
      titleTe: 'శుభోదయం పోస్టర్',
      titleHi: 'गुड मॉर्निंग पोस्टर',
      titleEn: 'Good Morning Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200',
      categoryTags: <String>['good_morning'],
    ),
    _TemplateItem(
      titleTe: 'బర్త్‌డే పోస్టర్',
      titleHi: 'बर्थडे पोस्टर',
      titleEn: 'Birthday Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?w=1200',
      categoryTags: <String>['birthdays'],
    ),
    _TemplateItem(
      titleTe: 'భక్తి పోస్టర్',
      titleHi: 'भक्ति पोस्टर',
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
        await NotificationService.instance.syncCurrentPreferences(force: true);
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
      await NotificationService.instance.syncCurrentPreferences(force: true);
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
          'మహాభారత',
          'महाभारत',
          'மகாபாரத',
          'ಮಹಾಭಾರತ',
          'മഹാഭാരത',
          'মহাভারত',
          'મહાભારત',
          'ਮਹਾਭਾਰਤ',
          'ମହାଭାରତ',
        ])) {
      return true;
    }

    if (hiddenTags.contains('devotional') &&
        containsAny(const <String>[
          'devotional',
          'bhakti',
          'భక్తి',
          'भक्ति',
          'பக்தி',
          'ಭಕ್ತಿ',
          'ഭക്തി',
          'ভক্তি',
          'ભક્તિ',
          'ਭਗਤੀ',
          'ଭକ୍ତି',
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
    // local calendar JSON, add chips from loaded templates so filters match.
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
      if (_isInactiveExactDynamicTemplateCategory(rawId, now)) {
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

  bool _isInactiveExactDynamicTemplateCategory(
    String categoryId,
    DateTime now,
  ) {
    final normalized = _normalizeTag(categoryId);
    if (normalized.isEmpty) {
      return false;
    }

    for (final category in _manualEventCategories) {
      final categoryId = _normalizeTag(category.id);
      final categorySlug = _normalizeTag(category.slug);
      if (normalized == categoryId || normalized == categorySlug) {
        return !_isCategoryActiveOnEventDay(category, now);
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final schedules = const DynamicEventScheduleService().schedulesForYear(
      now.year,
      daysBeforeEvent: 0,
    );
    for (final schedule in schedules) {
      final eventId = _normalizeTag(schedule.event.id);
      final eventSlug = _normalizeTag(schedule.event.slug);
      if (normalized != eventId && normalized != eventSlug) {
        continue;
      }
      if (!_dynamicEventMatchesSelectedRegion(schedule.event)) {
        return true;
      }
      final active =
          !today.isBefore(schedule.startDate) &&
          !today.isAfter(schedule.endDate);
      return !active;
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
      'gurram_jashuva_jayanthi' => 'గుర్రం జాషువా జయంతి',
      'gurram_jashuva_vardhanthi' => 'గుర్రం జాషువా వర్ధంతి',
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
        builder: (_) => ProfileScreen(initialProfile: _viewerPosterProfile),
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
        await ref.update(<String, Object?>{
          'viewCount': FieldValue.increment(1),
          'lastViewedAt': FieldValue.serverTimestamp(),
        });
      } catch (error, stackTrace) {
        _homeDebugLogStack(
          '$debugLabel view count skipped: $error',
          stackTrace,
        );
      }
    }());
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
                  'پلے سٹوٗر ہیٚکہ نہٕ کٔڈِتھ۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
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

