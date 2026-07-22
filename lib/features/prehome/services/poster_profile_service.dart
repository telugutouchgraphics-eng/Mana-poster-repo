import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/media/poster_network_image_cache.dart';

enum PosterDisplayNameMode { auto, telugu, english }

enum PosterIdentityMode { personal, business }

class _PreparedStorageUpload {
  const _PreparedStorageUpload({
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String contentType;
  final String fileName;
}

class PosterProfileData {
  const PosterProfileData({
    required this.nameTelugu,
    required this.nameEnglish,
    required this.whatsappNumber,
    required this.nameFontFamily,
    required this.displayNameMode,
    required this.photoPath,
    required this.photoUrl,
    this.identityMode = PosterIdentityMode.personal,
    this.businessName = '',
    this.businessTagline = '',
    this.businessWhatsappNumber = '',
    this.businessLogoPath = '',
    this.businessLogoUrl = '',
    this.businessLogoStyleId = 'style_1',
    this.originalPhotoPath = '',
    this.originalPhotoUrl = '',
    this.setupCompleted = false,
  });

  final String nameTelugu;
  final String nameEnglish;
  final String whatsappNumber;
  final String nameFontFamily;
  final PosterDisplayNameMode displayNameMode;
  final String photoPath;
  final String photoUrl;
  final PosterIdentityMode identityMode;
  final String businessName;
  final String businessTagline;
  final String businessWhatsappNumber;
  final String businessLogoPath;
  final String businessLogoUrl;
  final String businessLogoStyleId;
  final String originalPhotoPath;
  final String originalPhotoUrl;
  final bool setupCompleted;

  String get displayName {
    final te = nameTelugu.trim();
    final en = nameEnglish.trim();
    if (te.isNotEmpty) {
      return te;
    }
    if (en.isNotEmpty) {
      return en;
    }
    return PosterProfileService.defaultName;
  }

  String get activeName {
    if (identityMode == PosterIdentityMode.business &&
        businessName.trim().isNotEmpty) {
      return businessName.trim();
    }
    return displayName;
  }

  String get activeWhatsappNumber {
    if (identityMode == PosterIdentityMode.business &&
        businessWhatsappNumber.trim().isNotEmpty) {
      return businessWhatsappNumber.trim();
    }
    return whatsappNumber.trim();
  }

  bool get usesGeneratedBusinessLogo {
    return identityMode == PosterIdentityMode.business &&
        businessLogoPath.trim().isEmpty &&
        businessLogoUrl.trim().isEmpty &&
        businessName.trim().isNotEmpty;
  }

  PosterProfileData copyWith({
    String? nameTelugu,
    String? nameEnglish,
    String? displayName,
    String? whatsappNumber,
    String? nameFontFamily,
    PosterDisplayNameMode? displayNameMode,
    String? photoPath,
    String? photoUrl,
    PosterIdentityMode? identityMode,
    String? businessName,
    String? businessTagline,
    String? businessWhatsappNumber,
    String? businessLogoPath,
    String? businessLogoUrl,
    String? businessLogoStyleId,
    String? originalPhotoPath,
    String? originalPhotoUrl,
    bool? setupCompleted,
  }) {
    final resolvedDisplayName = displayName?.trim() ?? '';
    final nextTelugu =
        nameTelugu ??
        (resolvedDisplayName.isNotEmpty
            ? resolvedDisplayName
            : this.nameTelugu);
    final nextEnglish =
        nameEnglish ?? (resolvedDisplayName.isNotEmpty ? '' : this.nameEnglish);
    return PosterProfileData(
      nameTelugu: nextTelugu,
      nameEnglish: nextEnglish,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      nameFontFamily: nameFontFamily ?? this.nameFontFamily,
      displayNameMode: displayNameMode ?? this.displayNameMode,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      identityMode: identityMode ?? this.identityMode,
      businessName: businessName ?? this.businessName,
      businessTagline: businessTagline ?? this.businessTagline,
      businessWhatsappNumber:
          businessWhatsappNumber ?? this.businessWhatsappNumber,
      businessLogoPath: businessLogoPath ?? this.businessLogoPath,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      businessLogoStyleId: businessLogoStyleId ?? this.businessLogoStyleId,
      originalPhotoPath: originalPhotoPath ?? this.originalPhotoPath,
      originalPhotoUrl: originalPhotoUrl ?? this.originalPhotoUrl,
      setupCompleted: setupCompleted ?? this.setupCompleted,
    );
  }

  String resolvedName({required AppLanguage language}) {
    final name = switch (identityMode) {
      PosterIdentityMode.business => activeName.trim(),
      PosterIdentityMode.personal => displayName.trim(),
    };
    return name.isEmpty ? PosterProfileService.defaultName : name;
  }

  String translatedName({required AppLanguage language}) {
    final base = switch (identityMode) {
      PosterIdentityMode.business =>
        activeName.trim().isEmpty
            ? PosterProfileService.defaultName
            : activeName.trim(),
      PosterIdentityMode.personal => _preferredPersonalNameFor(language),
    };
    if (language == AppLanguage.english) {
      final english = nameEnglish.trim();
      if (english.isNotEmpty) {
        return english;
      }
    }
    return _NameScriptConverter.convert(base, language);
  }

  String _preferredPersonalNameFor(AppLanguage language) {
    final telugu = nameTelugu.trim();
    final english = nameEnglish.trim();
    if (language == AppLanguage.english && english.isNotEmpty) {
      return english;
    }
    if (english.isNotEmpty) {
      return english;
    }
    if (telugu.isNotEmpty) {
      return telugu;
    }
    return PosterProfileService.defaultName;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PosterProfileData &&
            other.nameTelugu == nameTelugu &&
            other.nameEnglish == nameEnglish &&
            other.whatsappNumber == whatsappNumber &&
            other.nameFontFamily == nameFontFamily &&
            other.displayNameMode == displayNameMode &&
            other.photoPath == photoPath &&
            other.photoUrl == photoUrl &&
            other.identityMode == identityMode &&
            other.businessName == businessName &&
            other.businessTagline == businessTagline &&
            other.businessWhatsappNumber == businessWhatsappNumber &&
            other.businessLogoPath == businessLogoPath &&
            other.businessLogoUrl == businessLogoUrl &&
            other.businessLogoStyleId == businessLogoStyleId &&
            other.originalPhotoPath == originalPhotoPath &&
            other.originalPhotoUrl == originalPhotoUrl &&
            other.setupCompleted == setupCompleted;
  }

  @override
  int get hashCode => Object.hash(
    nameTelugu,
    nameEnglish,
    whatsappNumber,
    nameFontFamily,
    displayNameMode,
    photoPath,
    photoUrl,
    identityMode,
    businessName,
    businessTagline,
    businessWhatsappNumber,
    businessLogoPath,
    businessLogoUrl,
    businessLogoStyleId,
    originalPhotoPath,
    originalPhotoUrl,
    setupCompleted,
  );
}

class ScriptLocalizationService {
  const ScriptLocalizationService._();

  static String convert(String input, AppLanguage language) {
    return _NameScriptConverter.convert(input, language);
  }

  static String localizeCategoryLabel(String input, AppLanguage language) {
    final raw = input.trim();
    if (raw.isEmpty || language == AppLanguage.english) {
      return input;
    }
    if (language.supportedUiLanguage == SupportedUiLanguage.telugu &&
        RegExp(r'[\u0C00-\u0C7F]').hasMatch(raw)) {
      return raw;
    }
    final normalized = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final phraseOverride = _categoryPhraseOverrides[language]?[normalized];
    if (phraseOverride != null && phraseOverride.isNotEmpty) {
      return phraseOverride;
    }
    final wordOverrides = _categoryWordOverrides[language];
    if (wordOverrides == null || wordOverrides.isEmpty) {
      return input;
    }
    var hasReplacement = false;
    var missingWord = false;
    final localized = raw.replaceAllMapped(RegExp(r'[A-Za-z]+'), (match) {
      final word = match.group(0) ?? '';
      final replacement = wordOverrides[word.toLowerCase()];
      if (replacement == null || replacement.isEmpty) {
        missingWord = true;
        return word;
      }
      hasReplacement = true;
      return replacement;
    });
    if (hasReplacement && !missingWord) {
      return localized;
    }
    return input;
  }

  static const Map<AppLanguage, Map<String, String>> _categoryPhraseOverrides =
      <AppLanguage, Map<String, String>>{
        AppLanguage.telugu: <String, String>{
          'good evening': 'శుభ సాయంత్రం',
          'political': 'రాజకీయం',
          'bonalu': 'బోనాలు',
          'sankranthi': 'సంక్రాంతి',
          'sankranti': 'సంక్రాంతి',
          'pongal': 'పొంగల్',
        },
        AppLanguage.hindi: <String, String>{
          'sankranthi': 'संक्रांति',
          'sankranti': 'संक्रांति',
          'pongal': 'पोंगल',
        },
        AppLanguage.tamil: <String, String>{
          'sankranthi': 'சங்கராந்தி',
          'sankranti': 'சங்கராந்தி',
          'pongal': 'பொங்கல்',
        },
        AppLanguage.kannada: <String, String>{
          'sankranthi': 'ಸಂಕ್ರಾಂತಿ',
          'sankranti': 'ಸಂಕ್ರಾಂತಿ',
          'pongal': 'ಪೊಂಗಲ್',
        },
        AppLanguage.malayalam: <String, String>{
          'sankranthi': 'സംക്രാന്തി',
          'sankranti': 'സംക്രാന്തി',
          'pongal': 'പൊങ്കൽ',
        },
      };

  static const Map<AppLanguage, Map<String, String>> _categoryWordOverrides =
      <AppLanguage, Map<String, String>>{
        AppLanguage.telugu: <String, String>{
          'test': 'టెస్ట్',
          'category': 'కేటగిరీ',
          'categori': 'కేటగిరీ',
          'special': 'స్పెషల్',
          'festival': 'ఫెస్టివల్',
          'wish': 'విష్',
          'wishes': 'విషెస్',
          'quotes': 'కోట్స్',
          'quote': 'కోట్',
          'birthday': 'పుట్టినరోజు',
          'anniversary': 'వార్షికోత్సవం',
          'love': 'లవ్',
          'life': 'లైఫ్',
          'good': 'శుభ',
          'evening': 'సాయంత్రం',
          'morning': 'ఉదయం',
          'night': 'రాత్రి',
          'devotional': 'భక్తి',
          'political': 'రాజకీయం',
          'politics': 'రాజకీయం',
          'bonalu': 'బోనాలు',
          'jayanthi': 'జయంతి',
          'vardhanthi': 'వర్ధంతి',
          'sankranthi': 'సంక్రాంతి',
          'sankranti': 'సంక్రాంతి',
          'pongal': 'పొంగల్',
        },
      };
}

class PosterNameFontOption {
  const PosterNameFontOption({required this.label, required this.family});

  final String label;
  final String family;
}

class PosterProfileService {
  PosterProfileService._();

  static const String _nameKey = 'poster_profile_name';
  static const String _nameTeluguKey = 'poster_profile_name_telugu';
  static const String _nameEnglishKey = 'poster_profile_name_english';
  static const String _whatsappKey = 'poster_profile_whatsapp';
  static const String _nameFontKey = 'poster_profile_name_font';
  static const String _photoPathKey = 'poster_profile_photo_path';
  static const String _photoUrlKey = 'poster_profile_photo_url';
  static const String _identityModeKey = 'poster_profile_identity_mode';
  static const String _businessNameKey = 'poster_profile_business_name';
  static const String _businessTaglineKey = 'poster_profile_business_tagline';
  static const String _businessWhatsappKey = 'poster_profile_business_whatsapp';
  static const String _businessLogoPathKey =
      'poster_profile_business_logo_path';
  static const String _businessLogoUrlKey = 'poster_profile_business_logo_url';
  static const String _businessLogoStyleKey =
      'poster_profile_business_logo_style';
  static const String _originalPhotoPathKey =
      'poster_profile_original_photo_path';
  static const String _originalPhotoUrlKey =
      'poster_profile_original_photo_url';
  static const String _setupCompletedKey = 'poster_profile_setup_completed';
  static const String _setupSkippedKey = 'poster_profile_setup_skipped';
  static const String _legacyMigrationPrefix = 'poster_profile_migrated_';

  static const List<PosterNameFontOption> nameFontOptions =
      <PosterNameFontOption>[
        PosterNameFontOption(
          label: 'Anek Telugu Condensed Bold',
          family: 'Anek Telugu Condensed Bold',
        ),
        PosterNameFontOption(
          label: 'Anek Telugu Condensed Extra Bold',
          family: 'Anek Telugu Condensed Extra Bold',
        ),
        PosterNameFontOption(
          label: 'Anek Telugu Condensed Medium',
          family: 'Anek Telugu Condensed Medium',
        ),
        PosterNameFontOption(
          label: 'Anek Telugu Condensed Regular',
          family: 'Anek Telugu Condensed Regular',
        ),
        PosterNameFontOption(
          label: 'Noto Sans Telugu Condensed Black',
          family: 'Noto Sans Telugu Condensed Black',
        ),
        PosterNameFontOption(
          label: 'Noto Sans Telugu Condensed Bold',
          family: 'Noto Sans Telugu Condensed Bold',
        ),
        PosterNameFontOption(
          label: 'Noto Sans Telugu Condensed Extra Bold',
          family: 'Noto Sans Telugu Condensed Extra Bold',
        ),
        PosterNameFontOption(label: 'Gowthami Bold', family: 'Gowthami Bold'),
        PosterNameFontOption(label: 'Pallavi Bold', family: 'Pallavi Bold'),
        PosterNameFontOption(label: 'Tejafont', family: 'Tejafont'),
        PosterNameFontOption(label: 'Anton', family: 'Anton'),
        PosterNameFontOption(label: 'Archivo Black', family: 'Archivo Black'),
        PosterNameFontOption(label: 'Bebas Neue', family: 'Bebas Neue'),
        PosterNameFontOption(label: 'League Spartan', family: 'League Spartan'),
        PosterNameFontOption(label: 'Montserrat', family: 'Montserrat'),
        PosterNameFontOption(
          label: 'Playfair Display',
          family: 'Playfair Display',
        ),
        PosterNameFontOption(label: 'Poppins', family: 'Poppins'),
        PosterNameFontOption(label: 'Rasa', family: 'Rasa'),
      ];

  static const String _defaultName = 'User';
  static const String _defaultFontFamily = 'Anek Telugu Condensed Bold';
  static const PosterDisplayNameMode _defaultDisplayNameMode =
      PosterDisplayNameMode.auto;

  static String get defaultName => _defaultName;

  static User? _currentFirebaseUserOrNull() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool isSetupComplete(PosterProfileData profile) {
    return (profile.setupCompleted && _hasMeaningfulPersonalName(profile)) ||
        profile.whatsappNumber.trim().isNotEmpty ||
        profile.photoPath.trim().isNotEmpty ||
        profile.photoUrl.trim().isNotEmpty ||
        profile.originalPhotoPath.trim().isNotEmpty ||
        profile.originalPhotoUrl.trim().isNotEmpty ||
        profile.businessName.trim().isNotEmpty ||
        profile.businessTagline.trim().isNotEmpty ||
        profile.businessWhatsappNumber.trim().isNotEmpty ||
        profile.businessLogoPath.trim().isNotEmpty ||
        profile.businessLogoUrl.trim().isNotEmpty;
  }

  static Future<bool> hasSkippedSetup({
    String? fallbackUid,
    SharedPreferences? prefs,
  }) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    return resolvedPrefs.getBool(
          _scopedKey(_setupSkippedKey, fallbackUid: fallbackUid),
        ) ??
        false;
  }

  static Future<void> markSetupSkipped({SharedPreferences? prefs}) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await resolvedPrefs.setBool(_scopedKey(_setupSkippedKey), true);
  }

  static bool _hasMeaningfulPersonalName(PosterProfileData profile) {
    return _isMeaningfulProfileName(profile.nameTelugu) ||
        _isMeaningfulProfileName(profile.nameEnglish);
  }

  static bool _isMeaningfulProfileName(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized != _defaultName.toLowerCase() &&
        normalized != 'mana poster ai user' &&
        normalized != 'add photo';
  }

  static Future<PosterProfileData> load() async {
    final localProfile = await loadLocal();
    final remoteProfile = await refreshFromRemote(localProfile: localProfile);
    final profile = remoteProfile ?? localProfile;
    return _ensureRemotePersonalPhotoSynced(profile);
  }

  static Future<PosterProfileData> loadLocal({
    String? fallbackUid,
    SharedPreferences? prefs,
  }) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await _migrateLegacyProfileKeysIfNeeded(
      resolvedPrefs,
      fallbackUid: fallbackUid,
    );
    final legacyTeluguName =
        (resolvedPrefs.getString(
                  _scopedKey(_nameTeluguKey, fallbackUid: fallbackUid),
                ) ??
                '')
            .trim();
    final legacyEnglishName =
        (resolvedPrefs.getString(
                  _scopedKey(_nameEnglishKey, fallbackUid: fallbackUid),
                ) ??
                '')
            .trim();
    final legacyName =
        (resolvedPrefs.getString(
                  _scopedKey(_nameKey, fallbackUid: fallbackUid),
                ) ??
                '')
            .trim();
    final hasPersistedName =
        resolvedPrefs.containsKey(
          _scopedKey(_nameTeluguKey, fallbackUid: fallbackUid),
        ) ||
        resolvedPrefs.containsKey(
          _scopedKey(_nameEnglishKey, fallbackUid: fallbackUid),
        ) ||
        resolvedPrefs.containsKey(
          _scopedKey(_nameKey, fallbackUid: fallbackUid),
        );
    final firebaseDisplayName =
        _currentFirebaseUserOrNull()?.displayName?.trim() ?? '';
    final resolvedLegacyName = legacyName.isNotEmpty
        ? legacyName
        : (legacyTeluguName.isNotEmpty
              ? legacyTeluguName
              : (legacyEnglishName.isNotEmpty
                    ? legacyEnglishName
                    : (firebaseDisplayName.isNotEmpty
                          ? firebaseDisplayName
                          : _defaultName)));
    final inferredLegacy = splitDisplayName(resolvedLegacyName);

    final localProfile = PosterProfileData(
      nameTelugu: legacyTeluguName.isNotEmpty
          ? legacyTeluguName
          : inferredLegacy.$1,
      nameEnglish: legacyEnglishName.isNotEmpty
          ? legacyEnglishName
          : inferredLegacy.$2,
      whatsappNumber:
          (resolvedPrefs.getString(
                    _scopedKey(_whatsappKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      nameFontFamily: _sanitizeFont(
        resolvedPrefs.getString(
          _scopedKey(_nameFontKey, fallbackUid: fallbackUid),
        ),
      ),
      displayNameMode: _defaultDisplayNameMode,
      photoPath:
          (resolvedPrefs.getString(
                    _scopedKey(_photoPathKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      photoUrl:
          (resolvedPrefs.getString(
                    _scopedKey(_photoUrlKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      identityMode: _parseIdentityMode(
        resolvedPrefs.getString(
          _scopedKey(_identityModeKey, fallbackUid: fallbackUid),
        ),
      ),
      businessName:
          (resolvedPrefs.getString(
                    _scopedKey(_businessNameKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      businessTagline:
          (resolvedPrefs.getString(
                    _scopedKey(_businessTaglineKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      businessWhatsappNumber:
          (resolvedPrefs.getString(
                    _scopedKey(_businessWhatsappKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      businessLogoPath:
          (resolvedPrefs.getString(
                    _scopedKey(_businessLogoPathKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      businessLogoUrl:
          (resolvedPrefs.getString(
                    _scopedKey(_businessLogoUrlKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      businessLogoStyleId:
          (resolvedPrefs.getString(
                    _scopedKey(_businessLogoStyleKey, fallbackUid: fallbackUid),
                  ) ??
                  'style_1')
              .trim(),
      originalPhotoPath:
          (resolvedPrefs.getString(
                    _scopedKey(_originalPhotoPathKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      originalPhotoUrl:
          (resolvedPrefs.getString(
                    _scopedKey(_originalPhotoUrlKey, fallbackUid: fallbackUid),
                  ) ??
                  '')
              .trim(),
      setupCompleted:
          resolvedPrefs.getBool(
            _scopedKey(_setupCompletedKey, fallbackUid: fallbackUid),
          ) ??
          (hasPersistedName &&
              (_isMeaningfulProfileName(legacyTeluguName) ||
                  _isMeaningfulProfileName(legacyEnglishName) ||
                  _isMeaningfulProfileName(legacyName))),
    );
    return localProfile;
  }

  static Future<PosterProfileData?> refreshFromRemote({
    PosterProfileData? localProfile,
  }) async {
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return localProfile;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posterProfile')
          .doc('main')
          .get();
      if (!snapshot.exists) {
        return localProfile;
      }
      final remote = _fromRemoteMap(snapshot.data() ?? <String, dynamic>{});
      final fallbackProfile = localProfile ?? await loadLocal();
      final localHasBusinessProfile =
          fallbackProfile.identityMode == PosterIdentityMode.business ||
          fallbackProfile.businessName.trim().isNotEmpty ||
          fallbackProfile.businessTagline.trim().isNotEmpty ||
          fallbackProfile.businessWhatsappNumber.trim().isNotEmpty ||
          fallbackProfile.businessLogoPath.trim().isNotEmpty ||
          fallbackProfile.businessLogoUrl.trim().isNotEmpty;
      final merged = remote.copyWith(
        photoPath: fallbackProfile.photoPath.trim().isNotEmpty
            ? fallbackProfile.photoPath
            : remote.photoPath,
        originalPhotoPath: fallbackProfile.originalPhotoPath.trim().isNotEmpty
            ? fallbackProfile.originalPhotoPath
            : remote.originalPhotoPath,
        identityMode: localHasBusinessProfile
            ? fallbackProfile.identityMode
            : remote.identityMode,
        businessName: fallbackProfile.businessName.trim().isNotEmpty
            ? fallbackProfile.businessName
            : remote.businessName,
        businessTagline: fallbackProfile.businessTagline.trim().isNotEmpty
            ? fallbackProfile.businessTagline
            : remote.businessTagline,
        businessWhatsappNumber:
            fallbackProfile.businessWhatsappNumber.trim().isNotEmpty
            ? fallbackProfile.businessWhatsappNumber
            : remote.businessWhatsappNumber,
        businessLogoPath: fallbackProfile.businessLogoPath.trim().isNotEmpty
            ? fallbackProfile.businessLogoPath
            : remote.businessLogoPath,
        businessLogoUrl: fallbackProfile.businessLogoUrl.trim().isNotEmpty
            ? fallbackProfile.businessLogoUrl
            : remote.businessLogoUrl,
        businessLogoStyleId: fallbackProfile.businessLogoStyleId.trim().isEmpty
            ? remote.businessLogoStyleId
            : fallbackProfile.businessLogoStyleId,
      );
      await _saveLocal(merged);
      return merged;
    } catch (_) {
      return localProfile;
    }
  }

  static ImageProvider<Object>? resolveImageProvider(
    PosterProfileData profile, {
    bool preferOriginalPersonalPhoto = false,
    bool preferPersonalPhotoOverBusinessLogo = false,
    bool allowOriginalFallbackWhenCutoutUnavailable = true,
  }) {
    if (preferPersonalPhotoOverBusinessLogo) {
      if (preferOriginalPersonalPhoto) {
        final localOriginalPath = profile.originalPhotoPath.trim();
        if (localOriginalPath.isNotEmpty) {
          final file = File(localOriginalPath);
          if (file.existsSync()) {
            return FileImage(file);
          }
        }
        final remoteOriginalUrl = profile.originalPhotoUrl.trim();
        if (remoteOriginalUrl.isNotEmpty) {
          return CachedNetworkImageProvider(
            remoteOriginalUrl,
            cacheManager: PosterNetworkImageCache.instance,
            maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
            maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
          );
        }
      }

      final localCutoutPath = profile.photoPath.trim();
      if (localCutoutPath.isNotEmpty) {
        final file = File(localCutoutPath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
      final remoteCutoutUrl = profile.photoUrl.trim();
      if (remoteCutoutUrl.isNotEmpty) {
        return CachedNetworkImageProvider(
          remoteCutoutUrl,
          cacheManager: PosterNetworkImageCache.instance,
          maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
          maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
        );
      }

      if (!preferOriginalPersonalPhoto &&
          allowOriginalFallbackWhenCutoutUnavailable) {
        final localOriginalPath = profile.originalPhotoPath.trim();
        if (localOriginalPath.isNotEmpty) {
          final file = File(localOriginalPath);
          if (file.existsSync()) {
            return FileImage(file);
          }
        }
        final remoteOriginalUrl = profile.originalPhotoUrl.trim();
        if (remoteOriginalUrl.isNotEmpty) {
          return CachedNetworkImageProvider(
            remoteOriginalUrl,
            cacheManager: PosterNetworkImageCache.instance,
            maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
            maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
          );
        }
      }
    }

    if (profile.identityMode == PosterIdentityMode.business) {
      final localLogoPath = profile.businessLogoPath.trim();
      if (localLogoPath.isNotEmpty) {
        final file = File(localLogoPath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
      final remoteLogoUrl = profile.businessLogoUrl.trim();
      if (remoteLogoUrl.isNotEmpty) {
        return CachedNetworkImageProvider(
          remoteLogoUrl,
          cacheManager: PosterNetworkImageCache.instance,
          maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
          maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
        );
      }
      return null;
    }

    if (preferOriginalPersonalPhoto) {
      final localOriginalPath = profile.originalPhotoPath.trim();
      if (localOriginalPath.isNotEmpty) {
        final file = File(localOriginalPath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
      final remoteOriginalUrl = profile.originalPhotoUrl.trim();
      if (remoteOriginalUrl.isNotEmpty) {
        return CachedNetworkImageProvider(
          remoteOriginalUrl,
          cacheManager: PosterNetworkImageCache.instance,
          maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
          maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
        );
      }
    }

    final localCutoutPath = profile.photoPath.trim();
    if (localCutoutPath.isNotEmpty) {
      final file = File(localCutoutPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    final remoteCutoutUrl = profile.photoUrl.trim();
    if (remoteCutoutUrl.isNotEmpty) {
      return CachedNetworkImageProvider(
        remoteCutoutUrl,
        cacheManager: PosterNetworkImageCache.instance,
        maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
        maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
      );
    }

    if (!preferOriginalPersonalPhoto &&
        allowOriginalFallbackWhenCutoutUnavailable) {
      final localOriginalPath = profile.originalPhotoPath.trim();
      if (localOriginalPath.isNotEmpty) {
        final file = File(localOriginalPath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
      final remoteOriginalUrl = profile.originalPhotoUrl.trim();
      if (remoteOriginalUrl.isNotEmpty) {
        return CachedNetworkImageProvider(
          remoteOriginalUrl,
          cacheManager: PosterNetworkImageCache.instance,
          maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
          maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
        );
      }
    }

    return null;
  }

  static Future<void> save(PosterProfileData data) async {
    final completedData = data.copyWith(setupCompleted: true);
    await _saveLocal(completedData);
    await _clearSetupSkipped();
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return;
    }
    unawaited(_saveRemoteProfile(user.uid, completedData));
  }

  static Future<void> _saveRemoteProfile(
    String uid,
    PosterProfileData data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('posterProfile')
          .doc('main')
          .set(<String, dynamic>{
            'displayName': data.displayName.trim().isEmpty
                ? _defaultName
                : data.displayName.trim(),
            'nameTelugu': data.nameTelugu.trim(),
            'nameEnglish': data.nameEnglish.trim(),
            'whatsappNumber': data.whatsappNumber.trim(),
            'nameFontFamily': _sanitizeFont(data.nameFontFamily),
            'photoUrl': data.photoUrl.trim(),
            'originalPhotoUrl': data.originalPhotoUrl.trim(),
            'identityMode': data.identityMode.name,
            'businessName': data.businessName.trim(),
            'businessTagline': data.businessTagline.trim(),
            'businessWhatsappNumber': data.businessWhatsappNumber.trim(),
            'businessLogoUrl': data.businessLogoUrl.trim(),
            'businessLogoStyleId': data.businessLogoStyleId.trim(),
            'setupCompleted': data.setupCompleted,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Poster profile remote save deferred: $error',
        name: 'poster_profile.save',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> savePersonalPhotoAssets({
    required String photoPath,
    required String originalPhotoPath,
    String photoUrl = '',
    String originalPhotoUrl = '',
    bool saveRemoteUrls = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedPhotoPath = photoPath.trim();
    final trimmedOriginalPhotoPath = originalPhotoPath.trim();
    final trimmedPhotoUrl = photoUrl.trim();
    final trimmedOriginalPhotoUrl = originalPhotoUrl.trim();

    if (trimmedPhotoPath.isEmpty) {
      await prefs.remove(_scopedKey(_photoPathKey));
    } else {
      await prefs.setString(_scopedKey(_photoPathKey), trimmedPhotoPath);
    }
    if (trimmedOriginalPhotoPath.isEmpty) {
      await prefs.remove(_scopedKey(_originalPhotoPathKey));
    } else {
      await prefs.setString(
        _scopedKey(_originalPhotoPathKey),
        trimmedOriginalPhotoPath,
      );
    }
    if (trimmedPhotoUrl.isEmpty) {
      await prefs.remove(_scopedKey(_photoUrlKey));
    } else {
      await prefs.setString(_scopedKey(_photoUrlKey), trimmedPhotoUrl);
    }
    if (trimmedOriginalPhotoUrl.isEmpty) {
      await prefs.remove(_scopedKey(_originalPhotoUrlKey));
    } else {
      await prefs.setString(
        _scopedKey(_originalPhotoUrlKey),
        trimmedOriginalPhotoUrl,
      );
    }

    if (!saveRemoteUrls) {
      return;
    }

    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (trimmedPhotoUrl.isNotEmpty) {
      payload['photoUrl'] = trimmedPhotoUrl;
    }
    if (trimmedOriginalPhotoUrl.isNotEmpty) {
      payload['originalPhotoUrl'] = trimmedOriginalPhotoUrl;
    }
    if (payload.length == 1) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('posterProfile')
        .doc('main')
        .set(payload, SetOptions(merge: true));
  }

  static Future<PosterProfileData> _ensureRemotePersonalPhotoSynced(
    PosterProfileData profile,
  ) async {
    final bool needsCutoutUpload =
        profile.photoUrl.trim().isEmpty && profile.photoPath.trim().isNotEmpty;
    final bool needsOriginalUpload =
        profile.originalPhotoUrl.trim().isEmpty &&
        profile.originalPhotoPath.trim().isNotEmpty;
    if (!needsCutoutUpload && !needsOriginalUpload) {
      return profile;
    }

    String nextPhotoUrl = profile.photoUrl.trim();
    String nextOriginalPhotoUrl = profile.originalPhotoUrl.trim();

    try {
      if (needsOriginalUpload) {
        final File originalFile = File(profile.originalPhotoPath.trim());
        if (originalFile.existsSync()) {
          nextOriginalPhotoUrl = await uploadProfilePhoto(
            file: originalFile,
            extension: 'png',
            isOriginal: true,
          );
        }
      }

      if (needsCutoutUpload) {
        final File cutoutFile = File(profile.photoPath.trim());
        if (cutoutFile.existsSync()) {
          nextPhotoUrl = await uploadProfilePhoto(
            file: cutoutFile,
            extension: 'png',
          );
        }
      }

      if (nextPhotoUrl == profile.photoUrl.trim() &&
          nextOriginalPhotoUrl == profile.originalPhotoUrl.trim()) {
        return profile;
      }

      final PosterProfileData updated = profile.copyWith(
        photoUrl: nextPhotoUrl,
        originalPhotoUrl: nextOriginalPhotoUrl,
      );
      await savePersonalPhotoAssets(
        photoPath: updated.photoPath,
        originalPhotoPath: updated.originalPhotoPath,
        photoUrl: updated.photoUrl,
        originalPhotoUrl: updated.originalPhotoUrl,
        saveRemoteUrls: true,
      );
      await _saveLocal(updated);
      return updated;
    } catch (_) {
      return profile;
    }
  }

  static Future<void> saveBusinessLogoAssets({
    required String businessLogoPath,
    String businessLogoUrl = '',
    String? businessLogoStyleId,
    PosterIdentityMode? identityMode,
    bool saveRemoteUrl = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedLogoPath = businessLogoPath.trim();
    final trimmedLogoUrl = businessLogoUrl.trim();
    final trimmedStyleId = businessLogoStyleId?.trim();

    if (trimmedLogoPath.isEmpty) {
      await prefs.remove(_scopedKey(_businessLogoPathKey));
    } else {
      await prefs.setString(_scopedKey(_businessLogoPathKey), trimmedLogoPath);
    }
    if (trimmedLogoUrl.isEmpty) {
      await prefs.remove(_scopedKey(_businessLogoUrlKey));
    } else {
      await prefs.setString(_scopedKey(_businessLogoUrlKey), trimmedLogoUrl);
    }
    if (trimmedStyleId != null && trimmedStyleId.isNotEmpty) {
      await prefs.setString(_scopedKey(_businessLogoStyleKey), trimmedStyleId);
    }
    if (identityMode != null) {
      await prefs.setString(_scopedKey(_identityModeKey), identityMode.name);
    }

    if (!saveRemoteUrl && trimmedStyleId == null && identityMode == null) {
      return;
    }

    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return;
    }

    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (saveRemoteUrl && trimmedLogoUrl.isNotEmpty) {
      payload['businessLogoUrl'] = trimmedLogoUrl;
    }
    if (trimmedStyleId != null && trimmedStyleId.isNotEmpty) {
      payload['businessLogoStyleId'] = trimmedStyleId;
    }
    if (identityMode != null) {
      payload['identityMode'] = identityMode.name;
    }
    if (payload.length == 1) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('posterProfile')
        .doc('main')
        .set(payload, SetOptions(merge: true));
  }

  static Future<String> uploadProfilePhoto({
    required File file,
    required String extension,
    bool isOriginal = false,
  }) async {
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return '';
    }
    final upload = await _prepareOptimizedUpload(
      file: file,
      extension: extension,
      assetPrefix: isOriginal ? 'original_photo' : 'photo',
    );
    final ref = FirebaseStorage.instance.ref(
      'users/${user.uid}/poster_profile/${upload.fileName}',
    );
    await ref.putData(
      upload.bytes,
      SettableMetadata(contentType: upload.contentType),
    );
    return ref.getDownloadURL();
  }

  static Future<String> uploadBusinessLogo({
    required File file,
    required String extension,
  }) async {
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return '';
    }
    final upload = await _prepareOptimizedUpload(
      file: file,
      extension: extension,
      assetPrefix: 'business_logo',
    );
    final ref = FirebaseStorage.instance.ref(
      'users/${user.uid}/poster_profile/${upload.fileName}',
    );
    await ref.putData(
      upload.bytes,
      SettableMetadata(contentType: upload.contentType),
    );
    return ref.getDownloadURL();
  }

  static Future<void> deleteProfilePhoto({required String photoUrl}) async {
    final trimmedUrl = photoUrl.trim();
    if (trimmedUrl.isEmpty) {
      return;
    }
    try {
      await FirebaseStorage.instance.refFromURL(trimmedUrl).delete();
    } catch (_) {
      // Ignore remote cleanup failures; profile state should still clear.
    }
  }

  static Future<void> _saveLocal(PosterProfileData data) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanName = data.displayName.trim().isEmpty
        ? _defaultName
        : data.displayName.trim();
    await prefs.setString(_scopedKey(_nameKey), cleanName);
    await prefs.setString(_scopedKey(_nameTeluguKey), data.nameTelugu.trim());
    await prefs.setString(_scopedKey(_nameEnglishKey), data.nameEnglish.trim());
    await prefs.setString(_scopedKey(_whatsappKey), data.whatsappNumber.trim());
    await prefs.setString(
      _scopedKey(_nameFontKey),
      _sanitizeFont(data.nameFontFamily),
    );
    await prefs.setString(_scopedKey(_identityModeKey), data.identityMode.name);
    await prefs.setString(
      _scopedKey(_businessNameKey),
      data.businessName.trim(),
    );
    await prefs.setString(
      _scopedKey(_businessTaglineKey),
      data.businessTagline.trim(),
    );
    await prefs.setString(
      _scopedKey(_businessWhatsappKey),
      data.businessWhatsappNumber.trim(),
    );
    await prefs.setString(
      _scopedKey(_businessLogoStyleKey),
      data.businessLogoStyleId.trim().isEmpty
          ? 'style_1'
          : data.businessLogoStyleId.trim(),
    );
    await prefs.setBool(_scopedKey(_setupCompletedKey), data.setupCompleted);
    if (data.photoPath.trim().isEmpty) {
      await prefs.remove(_scopedKey(_photoPathKey));
    } else {
      await prefs.setString(_scopedKey(_photoPathKey), data.photoPath.trim());
    }
    if (data.photoUrl.trim().isEmpty) {
      await prefs.remove(_scopedKey(_photoUrlKey));
    } else {
      await prefs.setString(_scopedKey(_photoUrlKey), data.photoUrl.trim());
    }
    if (data.businessLogoPath.trim().isEmpty) {
      await prefs.remove(_scopedKey(_businessLogoPathKey));
    } else {
      await prefs.setString(
        _scopedKey(_businessLogoPathKey),
        data.businessLogoPath.trim(),
      );
    }
    if (data.businessLogoUrl.trim().isEmpty) {
      await prefs.remove(_scopedKey(_businessLogoUrlKey));
    } else {
      await prefs.setString(
        _scopedKey(_businessLogoUrlKey),
        data.businessLogoUrl.trim(),
      );
    }
    if (data.originalPhotoPath.trim().isEmpty) {
      await prefs.remove(_scopedKey(_originalPhotoPathKey));
    } else {
      await prefs.setString(
        _scopedKey(_originalPhotoPathKey),
        data.originalPhotoPath.trim(),
      );
    }
    if (data.originalPhotoUrl.trim().isEmpty) {
      await prefs.remove(_scopedKey(_originalPhotoUrlKey));
    } else {
      await prefs.setString(
        _scopedKey(_originalPhotoUrlKey),
        data.originalPhotoUrl.trim(),
      );
    }
  }

  static Future<void> _clearSetupSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedKey(_setupSkippedKey));
  }

  static Future<void> clearLocalCacheForCurrentUser() async {
    final uid = _currentFirebaseUserOrNull()?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return;
    }
    await clearLocalCacheForUid(uid);
  }

  static Future<void> clearLocalCacheForUid(String uid) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final keys = <String>[
      _nameKey,
      _nameTeluguKey,
      _nameEnglishKey,
      _whatsappKey,
      _nameFontKey,
      _photoPathKey,
      _photoUrlKey,
      _identityModeKey,
      _businessNameKey,
      _businessTaglineKey,
      _businessWhatsappKey,
      _businessLogoPathKey,
      _businessLogoUrlKey,
      _businessLogoStyleKey,
      _originalPhotoPathKey,
      _originalPhotoUrlKey,
      _setupCompletedKey,
      _setupSkippedKey,
    ];
    for (final key in keys) {
      await prefs.remove('${key}_$trimmedUid');
    }
    await prefs.remove('$_legacyMigrationPrefix$trimmedUid');
  }

  static String _scopedKey(String baseKey, {String? fallbackUid}) {
    final uid = _currentFirebaseUserOrNull()?.uid ?? fallbackUid;
    if (uid == null || uid.trim().isEmpty) {
      return baseKey;
    }
    return '${baseKey}_$uid';
  }

  static Future<void> _migrateLegacyProfileKeysIfNeeded(
    SharedPreferences prefs, {
    String? fallbackUid,
  }) async {
    final uid = _currentFirebaseUserOrNull()?.uid ?? fallbackUid;
    if (uid == null || uid.trim().isEmpty) {
      return;
    }
    final markerKey = '$_legacyMigrationPrefix$uid';
    if (prefs.getBool(markerKey) == true) {
      return;
    }
    final keys = <String>[
      _nameKey,
      _nameTeluguKey,
      _nameEnglishKey,
      _whatsappKey,
      _nameFontKey,
      _photoPathKey,
      _photoUrlKey,
      _identityModeKey,
      _businessNameKey,
      _businessTaglineKey,
      _businessWhatsappKey,
      _businessLogoPathKey,
      _businessLogoUrlKey,
      _businessLogoStyleKey,
      _originalPhotoPathKey,
      _originalPhotoUrlKey,
      _setupCompletedKey,
      _setupSkippedKey,
    ];
    for (final key in keys) {
      final scopedKey = '${key}_$uid';
      if (prefs.containsKey(scopedKey) || !prefs.containsKey(key)) {
        continue;
      }
      final value = prefs.get(key);
      if (value is String) {
        await prefs.setString(scopedKey, value);
      } else if (value is bool) {
        await prefs.setBool(scopedKey, value);
      }
    }
    await prefs.setBool(markerKey, true);
  }

  static PosterProfileData _fromRemoteMap(Map<String, dynamic> data) {
    final remoteName = (data['displayName'] as String? ?? '').trim();
    final remoteNameTelugu = (data['nameTelugu'] as String? ?? '').trim();
    final remoteNameEnglish = (data['nameEnglish'] as String? ?? '').trim();
    final inferred = splitDisplayName(remoteName);
    return PosterProfileData(
      nameTelugu: remoteNameTelugu.isNotEmpty
          ? remoteNameTelugu
          : (inferred.$1.isNotEmpty
                ? inferred.$1
                : (remoteName.isEmpty ? _defaultName : remoteName)),
      nameEnglish: remoteNameEnglish.isNotEmpty
          ? remoteNameEnglish
          : inferred.$2,
      whatsappNumber: (data['whatsappNumber'] as String? ?? '').trim(),
      nameFontFamily: _sanitizeFont(data['nameFontFamily'] as String?),
      displayNameMode: _defaultDisplayNameMode,
      photoPath: '',
      photoUrl: (data['photoUrl'] as String? ?? '').trim(),
      identityMode: _parseIdentityMode(data['identityMode'] as String?),
      businessName: (data['businessName'] as String? ?? '').trim(),
      businessTagline: (data['businessTagline'] as String? ?? '').trim(),
      businessWhatsappNumber: (data['businessWhatsappNumber'] as String? ?? '')
          .trim(),
      businessLogoPath: '',
      businessLogoUrl: (data['businessLogoUrl'] as String? ?? '').trim(),
      businessLogoStyleId: (data['businessLogoStyleId'] as String? ?? 'style_1')
          .trim(),
      originalPhotoPath: '',
      originalPhotoUrl: (data['originalPhotoUrl'] as String? ?? '').trim(),
      setupCompleted:
          data['setupCompleted'] == true ||
          _isMeaningfulProfileName(remoteNameTelugu) ||
          _isMeaningfulProfileName(remoteNameEnglish) ||
          _isMeaningfulProfileName(remoteName),
    );
  }

  static PosterIdentityMode _parseIdentityMode(String? rawMode) {
    return switch ((rawMode ?? '').trim()) {
      'business' => PosterIdentityMode.business,
      _ => PosterIdentityMode.personal,
    };
  }

  static String _contentTypeForExtension(String extension) {
    return switch (extension.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  static Future<_PreparedStorageUpload> _prepareOptimizedUpload({
    required File file,
    required String extension,
    required String assetPrefix,
  }) async {
    final cleanExtension = extension.trim().isEmpty ? 'jpg' : extension.trim();
    final originalBytes = await file.readAsBytes();
    final normalizedExtension = _normalizedUploadExtension(cleanExtension);
    final fileHash = _stableBytesHash(originalBytes);
    return _PreparedStorageUpload(
      bytes: originalBytes,
      contentType: _contentTypeForExtension(normalizedExtension),
      fileName: '${assetPrefix}_$fileHash.$normalizedExtension',
    );
  }

  static String _normalizedUploadExtension(String extension) {
    final normalized = extension.trim().toLowerCase();
    return switch (normalized) {
      'png' => 'png',
      'webp' => 'webp',
      'jpeg' => 'jpg',
      'jpg' => 'jpg',
      _ => 'jpg',
    };
  }

  static String _stableBytesHash(Uint8List bytes) {
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  static String _sanitizeFont(String? rawFont) {
    final candidate = (rawFont ?? '').trim();
    for (final option in nameFontOptions) {
      if (option.family == candidate) {
        return option.family;
      }
    }
    return _defaultFontFamily;
  }

  static (String, String) splitDisplayName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return ('', '');
    }
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(value);
    if (hasLatin) {
      return ('', value);
    }
    return (value, '');
  }
}

class _NameScriptConverter {
  static final RegExp _teluguRegExp = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _devanagariRegExp = RegExp(r'[\u0900-\u097F]');
  static final RegExp _tamilRegExp = RegExp(r'[\u0B80-\u0BFF]');
  static final RegExp _kannadaRegExp = RegExp(r'[\u0C80-\u0CFF]');
  static final RegExp _malayalamRegExp = RegExp(r'[\u0D00-\u0D7F]');

  static final RegExp _latinWordRegExp = RegExp(r'[A-Za-z]+');
  static final RegExp _latinPhraseRegExp = RegExp(r'[A-Za-z][A-Za-z\s&.-]*');

  static const Map<AppLanguage, Map<String, String>>
  _phraseOverrides = <AppLanguage, Map<String, String>>{
    AppLanguage.telugu: <String, String>{
      'mana poster': 'à°®à°¨ à°ªà±‹à°¸à±à°Ÿà°°à±',
      'telugu touch graphics':
          'à°¤à±†à°²à±à°—à± à°Ÿà°šà± à°—à±à°°à°¾à°«à°¿à°•à±à°¸à±',
    },
    AppLanguage.hindi: <String, String>{
      'mana poster': 'à¤®à¤¨à¤¾ à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      'telugu touch graphics':
          'à¤¤à¥‡à¤²à¥à¤—à¥ à¤Ÿà¤š à¤—à¥à¤°à¤¾à¤«à¤¿à¤•à¥à¤¸',
    },
    AppLanguage.tamil: <String, String>{
      'mana poster': 'à®®à®© à®ªà¯‹à®¸à¯à®Ÿà®°à¯',
      'telugu touch graphics':
          'à®¤à¯†à®²à¯à®•à¯ à®Ÿà®šà¯ à®•à®¿à®°à®¾à®ªà®¿à®•à¯à®¸à¯',
    },
    AppLanguage.kannada: <String, String>{
      'mana poster': 'à²®à²¨ à²ªà³‹à²¸à³à²Ÿà²°à³',
      'telugu touch graphics':
          'à²¤à³†à²²à³à²—à³ à²Ÿà²šà³ à²—à³à²°à²¾à²«à²¿à²•à³à²¸à³',
    },
    AppLanguage.malayalam: <String, String>{
      'mana poster': 'à´®à´¨ à´ªàµ‹à´¸àµà´±àµà´±àµ¼',
      'telugu touch graphics':
          'à´¤àµ†à´²àµà´—àµ à´Ÿà´šàµà´šàµ à´—àµà´°à´¾à´«à´¿à´•àµà´¸àµ',
    },
  };

  static const Map<AppLanguage, Map<String, String>> _wordOverrides =
      <AppLanguage, Map<String, String>>{
        AppLanguage.telugu: <String, String>{
          'telugu': 'à°¤à±†à°²à±à°—à±',
          'touch': 'à°Ÿà°šà±',
          'graphics': 'à°—à±à°°à°¾à°«à°¿à°•à±à°¸à±',
          'graphic': 'à°—à±à°°à°¾à°«à°¿à°•à±',
          'poster': 'à°ªà±‹à°¸à±à°Ÿà°°à±',
          'mana': 'à°®à°¨',
          'digital': 'à°¡à°¿à°œà°¿à°Ÿà°²à±',
          'studio': 'à°¸à±à°Ÿà±‚à°¡à°¿à°¯à±‹',
          'design': 'à°¡à°¿à°œà±ˆà°¨à±',
          'designs': 'à°¡à°¿à°œà±ˆà°¨à±à°¸à±',
          'media': 'à°®à±€à°¡à°¿à°¯à°¾',
          'tech': 'à°Ÿà±†à°•à±',
          'solutions': 'à°¸à±Šà°²à±à°¯à±‚à°·à°¨à±à°¸à±',
          'sankranthi': 'à°¸à°‚à°•à±à°°à°¾à°‚à°¤à°¿',
          'sankranti': 'à°¸à°‚à°•à±à°°à°¾à°‚à°¤à°¿',
          'pongal': 'à°ªà±Šà°‚à°—à°²à±',
        },
        AppLanguage.hindi: <String, String>{
          'telugu': 'à¤¤à¥‡à¤²à¥à¤—à¥',
          'touch': 'à¤Ÿà¤š',
          'graphics': 'à¤—à¥à¤°à¤¾à¤«à¤¿à¤•à¥à¤¸',
          'graphic': 'à¤—à¥à¤°à¤¾à¤«à¤¿à¤•',
          'poster': 'à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
          'mana': 'à¤®à¤¨à¤¾',
          'digital': 'à¤¡à¤¿à¤œà¤¿à¤Ÿà¤²',
          'studio': 'à¤¸à¥à¤Ÿà¥‚à¤¡à¤¿à¤¯à¥‹',
          'design': 'à¤¡à¤¿à¤œà¤¼à¤¾à¤‡à¤¨',
          'designs': 'à¤¡à¤¿à¤œà¤¼à¤¾à¤‡à¤¨à¥à¤¸',
          'media': 'à¤®à¥€à¤¡à¤¿à¤¯à¤¾',
          'tech': 'à¤Ÿà¥‡à¤•',
          'solutions': 'à¤¸à¥‹à¤²à¥à¤¯à¥‚à¤¶à¤¨à¥à¤¸',
          'sankranthi': 'à¤¸à¤‚à¤•à¥à¤°à¤¾à¤‚à¤¤à¤¿',
          'sankranti': 'à¤¸à¤‚à¤•à¥à¤°à¤¾à¤‚à¤¤à¤¿',
          'pongal': 'à¤ªà¥‹à¤‚à¤—à¤²',
        },
        AppLanguage.tamil: <String, String>{
          'telugu': 'à®¤à¯†à®²à¯à®•à¯',
          'touch': 'à®Ÿà®šà¯',
          'graphics': 'à®•à®¿à®°à®¾à®ªà®¿à®•à¯à®¸à¯',
          'graphic': 'à®•à®¿à®°à®¾à®ªà®¿à®•à¯',
          'poster': 'à®ªà¯‹à®¸à¯à®Ÿà®°à¯',
          'mana': 'à®®à®©',
          'digital': 'à®Ÿà®¿à®œà®¿à®Ÿà¯à®Ÿà®²à¯',
          'studio': 'à®¸à¯à®Ÿà¯à®Ÿà®¿à®¯à¯‹',
          'design': 'à®Ÿà®¿à®šà¯ˆà®©à¯',
          'designs': 'à®Ÿà®¿à®šà¯ˆà®©à¯à®¸à¯',
          'media': 'à®®à¯€à®Ÿà®¿à®¯à®¾',
          'tech': 'à®Ÿà¯†à®•à¯',
          'solutions': 'à®šà¯Šà®²à¯à®¯à¯‚à®·à®©à¯à®¸à¯',
          'sankranthi': 'à®šà®™à¯à®•à®°à®¾à®¨à¯à®¤à®¿',
          'sankranti': 'à®šà®™à¯à®•à®°à®¾à®¨à¯à®¤à®¿',
          'pongal': 'à®ªà¯Šà®™à¯à®•à®²à¯',
        },
        AppLanguage.kannada: <String, String>{
          'telugu': 'à²¤à³†à²²à³à²—à³',
          'touch': 'à²Ÿà²šà³',
          'graphics': 'à²—à³à²°à²¾à²«à²¿à²•à³à²¸à³',
          'graphic': 'à²—à³à²°à²¾à²«à²¿à²•à³',
          'poster': 'à²ªà³‹à²¸à³à²Ÿà²°à³',
          'mana': 'à²®à²¨',
          'digital': 'à²¡à²¿à²œà²¿à²Ÿà²²à³',
          'studio': 'à²¸à³à²Ÿà³à²¡à²¿à²¯à³‹',
          'design': 'à²¡à²¿à²¸à³ˆà²¨à³',
          'designs': 'à²¡à²¿à²¸à³ˆà²¨à³à²¸à³',
          'media': 'à²®à³€à²¡à²¿à²¯à²¾',
          'tech': 'à²Ÿà³†à²•à³',
          'solutions': 'à²¸à³Šà²²à³à²¯à³‚à²¶à²¨à³à²¸à³',
          'sankranthi': 'à²¸à²‚à²•à³à²°à²¾à²‚à²¤à²¿',
          'sankranti': 'à²¸à²‚à²•à³à²°à²¾à²‚à²¤à²¿',
          'pongal': 'à²ªà³Šà²‚à²—à²²à³',
        },
        AppLanguage.malayalam: <String, String>{
          'telugu': 'à´¤àµ†à´²àµà´—àµ',
          'touch': 'à´Ÿà´šàµà´šàµ',
          'graphics': 'à´—àµà´°à´¾à´«à´¿à´•àµà´¸àµ',
          'graphic': 'à´—àµà´°à´¾à´«à´¿à´•àµ',
          'poster': 'à´ªàµ‹à´¸àµà´±àµà´±àµ¼',
          'mana': 'à´®à´¨',
          'digital': 'à´¡à´¿à´œà´¿à´±àµà´±àµ½',
          'studio': 'à´¸àµà´±àµà´±àµà´¡à´¿à´¯àµ‹',
          'design': 'à´¡à´¿à´¸àµˆàµ»',
          'designs': 'à´¡à´¿à´¸àµˆàµ»à´¸àµ',
          'media': 'à´®àµ€à´¡à´¿à´¯',
          'tech': 'à´Ÿàµ†à´•àµ',
          'solutions': 'à´¸àµŠà´²àµà´¯àµ‚à´·àµ»à´¸àµ',
          'sankranthi': 'à´¸à´‚à´•àµà´°à´¾à´¨àµà´¤à´¿',
          'sankranti': 'à´¸à´‚à´•àµà´°à´¾à´¨àµà´¤à´¿',
          'pongal': 'à´ªàµŠà´™àµà´•àµ½',
        },
      };

  static const Map<String, String> _latinToTelugu = <String, String>{
    'a': 'à°…',
    'b': 'à°¬',
    'c': 'à°¸',
    'd': 'à°¦',
    'e': 'à°Ž',
    'f': 'à°«',
    'g': 'à°—',
    'h': 'à°¹',
    'i': 'à°‡',
    'j': 'à°œ',
    'k': 'à°•',
    'l': 'à°²',
    'm': 'à°®',
    'n': 'à°¨',
    'o': 'à°’',
    'p': 'à°ª',
    'q': 'à°•à±à°¯',
    'r': 'à°°',
    's': 'à°¸',
    't': 'à°Ÿ',
    'u': 'à°‰',
    'v': 'à°µ',
    'w': 'à°µ',
    'x': 'à°•à±à°¸à±',
    'y': 'à°¯',
    'z': 'à°œà±',
  };

  static const Map<String, String> _latinToDevanagari = <String, String>{
    'a': 'à¤…',
    'b': 'à¤¬',
    'c': 'à¤¸',
    'd': 'à¤¦',
    'e': 'à¤',
    'f': 'à¤«',
    'g': 'à¤—',
    'h': 'à¤¹',
    'i': 'à¤‡',
    'j': 'à¤œ',
    'k': 'à¤•',
    'l': 'à¤²',
    'm': 'à¤®',
    'n': 'à¤¨',
    'o': 'à¤“',
    'p': 'à¤ª',
    'q': 'à¤•',
    'r': 'à¤°',
    's': 'à¤¸',
    't': 'à¤¤',
    'u': 'à¤‰',
    'v': 'à¤µ',
    'w': 'à¤µ',
    'x': 'à¤•à¥à¤¸',
    'y': 'à¤¯',
    'z': 'à¤œà¤¼',
  };

  static const Map<String, String> _latinToTamil = <String, String>{
    'a': 'à®…',
    'b': 'à®ª',
    'c': 'à®š',
    'd': 'à®¤',
    'e': 'à®Ž',
    'f': 'à®ƒà®ª',
    'g': 'à®•',
    'h': 'à®¹',
    'i': 'à®‡',
    'j': 'à®œ',
    'k': 'à®•',
    'l': 'à®²',
    'm': 'à®®',
    'n': 'à®¨',
    'o': 'à®’',
    'p': 'à®ª',
    'q': 'à®•',
    'r': 'à®°',
    's': 'à®¸',
    't': 'à®Ÿ',
    'u': 'à®‰',
    'v': 'à®µ',
    'w': 'à®µ',
    'x': 'à®•à¯à®¸à¯',
    'y': 'à®¯',
    'z': 'à®œ',
  };

  static const Map<String, String> _latinToKannada = <String, String>{
    'a': 'à²…',
    'b': 'à²¬',
    'c': 'à²¸',
    'd': 'à²¦',
    'e': 'à²Ž',
    'f': 'à²«',
    'g': 'à²—',
    'h': 'à²¹',
    'i': 'à²‡',
    'j': 'à²œ',
    'k': 'à²•',
    'l': 'à²²',
    'm': 'à²®',
    'n': 'à²¨',
    'o': 'à²’',
    'p': 'à²ª',
    'q': 'à²•',
    'r': 'à²°',
    's': 'à²¸',
    't': 'à²Ÿ',
    'u': 'à²‰',
    'v': 'à²µ',
    'w': 'à²µ',
    'x': 'à²•à³à²¸à³',
    'y': 'à²¯',
    'z': 'à²œ',
  };

  static const Map<String, String> _latinToMalayalam = <String, String>{
    'a': 'à´…',
    'b': 'à´¬',
    'c': 'à´¸',
    'd': 'à´¦',
    'e': 'à´Ž',
    'f': 'à´«',
    'g': 'à´—',
    'h': 'à´¹',
    'i': 'à´‡',
    'j': 'à´œ',
    'k': 'à´•',
    'l': 'à´²',
    'm': 'à´®',
    'n': 'à´¨',
    'o': 'à´’',
    'p': 'à´ª',
    'q': 'à´•',
    'r': 'à´°',
    's': 'à´¸',
    't': 'à´Ÿ',
    'u': 'à´‰',
    'v': 'à´µ',
    'w': 'à´µ',
    'x': 'à´•àµà´¸àµ',
    'y': 'à´¯',
    'z': 'à´œ',
  };

  static const Map<String, String> _teluguToLatin = <String, String>{
    'à°…': 'a',
    'à°†': 'aa',
    'à°‡': 'i',
    'à°ˆ': 'ii',
    'à°‰': 'u',
    'à°Š': 'uu',
    'à°Ž': 'e',
    'à°': 'ee',
    'à°’': 'o',
    'à°“': 'oo',
    'à°•': 'ka',
    'à°–': 'kha',
    'à°—': 'ga',
    'à°˜': 'gha',
    'à°š': 'cha',
    'à°œ': 'ja',
    'à°Ÿ': 'ta',
    'à°¡': 'da',
    'à°¤': 'tha',
    'à°¦': 'dha',
    'à°¨': 'na',
    'à°ª': 'pa',
    'à°¬': 'ba',
    'à°®': 'ma',
    'à°¯': 'ya',
    'à°°': 'ra',
    'à°²': 'la',
    'à°µ': 'va',
    'à°¶': 'sha',
    'à°¸': 'sa',
    'à°¹': 'ha',
    'à°³': 'la',
  };

  static const Map<String, String> _devanagariToLatin = <String, String>{
    'à¤…': 'a',
    'à¤†': 'aa',
    'à¤‡': 'i',
    'à¤ˆ': 'ii',
    'à¤‰': 'u',
    'à¤Š': 'uu',
    'à¤': 'e',
    'à¤': 'ai',
    'à¤“': 'o',
    'à¤”': 'au',
    'à¤•': 'ka',
    'à¤–': 'kha',
    'à¤—': 'ga',
    'à¤˜': 'gha',
    'à¤š': 'cha',
    'à¤œ': 'ja',
    'à¤Ÿ': 'ta',
    'à¤¡': 'da',
    'à¤¤': 'tha',
    'à¤¦': 'dha',
    'à¤¨': 'na',
    'à¤ª': 'pa',
    'à¤¬': 'ba',
    'à¤®': 'ma',
    'à¤¯': 'ya',
    'à¤°': 'ra',
    'à¤²': 'la',
    'à¤µ': 'va',
    'à¤¶': 'sha',
    'à¤¸': 'sa',
    'à¤¹': 'ha',
  };

  static const Map<String, String> _tamilToLatin = <String, String>{
    'à®…': 'a',
    'à®†': 'aa',
    'à®‡': 'i',
    'à®ˆ': 'ii',
    'à®‰': 'u',
    'à®Š': 'uu',
    'à®Ž': 'e',
    'à®': 'ee',
    'à®’': 'o',
    'à®“': 'oo',
    'à®•': 'ka',
    'à®š': 'sa',
    'à®œ': 'ja',
    'à®Ÿ': 'ta',
    'à®¤': 'tha',
    'à®¨': 'na',
    'à®ª': 'pa',
    'à®®': 'ma',
    'à®¯': 'ya',
    'à®°': 'ra',
    'à®²': 'la',
    'à®µ': 'va',
    'à®¸': 'sa',
    'à®¹': 'ha',
  };

  static const Map<String, String> _kannadaToLatin = <String, String>{
    'à²…': 'a',
    'à²†': 'aa',
    'à²‡': 'i',
    'à²ˆ': 'ii',
    'à²‰': 'u',
    'à²Š': 'uu',
    'à²Ž': 'e',
    'à²': 'ee',
    'à²’': 'o',
    'à²“': 'oo',
    'à²•': 'ka',
    'à²—': 'ga',
    'à²š': 'cha',
    'à²œ': 'ja',
    'à²Ÿ': 'ta',
    'à²¡': 'da',
    'à²¤': 'tha',
    'à²¦': 'dha',
    'à²¨': 'na',
    'à²ª': 'pa',
    'à²¬': 'ba',
    'à²®': 'ma',
    'à²¯': 'ya',
    'à²°': 'ra',
    'à²²': 'la',
    'à²µ': 'va',
    'à²¶': 'sha',
    'à²¸': 'sa',
    'à²¹': 'ha',
  };

  static const Map<String, String> _malayalamToLatin = <String, String>{
    'à´…': 'a',
    'à´†': 'aa',
    'à´‡': 'i',
    'à´ˆ': 'ii',
    'à´‰': 'u',
    'à´Š': 'uu',
    'à´Ž': 'e',
    'à´': 'ee',
    'à´’': 'o',
    'à´“': 'oo',
    'à´•': 'ka',
    'à´—': 'ga',
    'à´š': 'cha',
    'à´œ': 'ja',
    'à´Ÿ': 'ta',
    'à´¡': 'da',
    'à´¤': 'tha',
    'à´¦': 'dha',
    'à´¨': 'na',
    'à´ª': 'pa',
    'à´¬': 'ba',
    'à´®': 'ma',
    'à´¯': 'ya',
    'à´°': 'ra',
    'à´²': 'la',
    'à´µ': 'va',
    'à´¶': 'sha',
    'à´¸': 'sa',
    'à´¹': 'ha',
  };

  static String convert(String input, AppLanguage language) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return input;
    }
    if (language == AppLanguage.english) {
      return _toEnglish(raw);
    }
    final phraseProcessed = _applyPhraseOverrides(raw, language);
    return phraseProcessed.replaceAllMapped(_latinWordRegExp, (match) {
      final word = match.group(0) ?? '';
      if (word.isEmpty) {
        return word;
      }
      final lower = word.toLowerCase();
      final override = _wordOverrides[language]?[lower];
      if (override != null) {
        return override;
      }
      return switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => _toTelugu(word),
        SupportedUiLanguage.hindi => _toHindi(word),
        SupportedUiLanguage.english => word,
        SupportedUiLanguage.tamil => _toTamil(word),
        SupportedUiLanguage.kannada => _toKannada(word),
        SupportedUiLanguage.malayalam => _toMalayalam(word),
      };
    });
  }

  static String _applyPhraseOverrides(String value, AppLanguage language) {
    final overrides = _phraseOverrides[language];
    if (overrides == null || overrides.isEmpty) {
      return value;
    }
    return value.replaceAllMapped(_latinPhraseRegExp, (match) {
      final phrase = match.group(0) ?? '';
      final normalized = phrase.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      return overrides[normalized] ?? phrase;
    });
  }

  static String _toTelugu(String input) {
    if (_teluguRegExp.hasMatch(input)) {
      return input;
    }
    final latin = _devanagariRegExp.hasMatch(input)
        ? _scriptToLatin(input, _devanagariToLatin)
        : input;
    return _latinToScript(latin, _latinToTelugu);
  }

  static String _toHindi(String input) {
    if (_devanagariRegExp.hasMatch(input)) {
      return input;
    }
    final latin = _teluguRegExp.hasMatch(input)
        ? _scriptToLatin(input, _teluguToLatin)
        : input;
    return _latinToScript(latin, _latinToDevanagari);
  }

  static String _toEnglish(String input) {
    if (_teluguRegExp.hasMatch(input)) {
      return _scriptToLatin(input, _teluguToLatin);
    }
    if (_devanagariRegExp.hasMatch(input)) {
      return _scriptToLatin(input, _devanagariToLatin);
    }
    if (_tamilRegExp.hasMatch(input)) {
      return _scriptToLatin(input, _tamilToLatin);
    }
    if (_kannadaRegExp.hasMatch(input)) {
      return _scriptToLatin(input, _kannadaToLatin);
    }
    if (_malayalamRegExp.hasMatch(input)) {
      return _scriptToLatin(input, _malayalamToLatin);
    }
    return input;
  }

  static String _toTamil(String input) {
    if (_tamilRegExp.hasMatch(input)) {
      return input;
    }
    return _latinToScript(_toEnglish(input), _latinToTamil);
  }

  static String _toKannada(String input) {
    if (_kannadaRegExp.hasMatch(input)) {
      return input;
    }
    return _latinToScript(_toEnglish(input), _latinToKannada);
  }

  static String _toMalayalam(String input) {
    if (_malayalamRegExp.hasMatch(input)) {
      return input;
    }
    return _latinToScript(_toEnglish(input), _latinToMalayalam);
  }

  static String _latinToScript(String value, Map<String, String> charMap) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final lower = char.toLowerCase();
      if (charMap.containsKey(lower)) {
        buffer.write(charMap[lower]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String _scriptToLatin(String value, Map<String, String> charMap) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(charMap[char] ?? char);
    }
    return buffer.toString();
  }
}
