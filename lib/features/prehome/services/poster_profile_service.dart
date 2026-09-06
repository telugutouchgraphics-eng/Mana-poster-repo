import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/media/poster_network_image_cache.dart';

enum PosterDisplayNameMode { auto, telugu, english }

enum PosterIdentityMode { personal, business }

const int _profileUploadMaxBytes = 14 * 1024 * 1024;

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
    this.preferOriginalPersonalPhoto = false,
    this.personalPhotoRevision = 0,
    this.profileRevision = 0,
    this.setupCompleted = false,
    this.secondaryDesignation = '',
    this.personalPhoneNumber = '',
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
  final bool preferOriginalPersonalPhoto;
  final int personalPhotoRevision;
  final int profileRevision;
  final bool setupCompleted;
  final String secondaryDesignation;
  final String personalPhoneNumber;

  String get primaryPersonalDesignation => whatsappNumber.trim();
  String get secondaryPersonalDesignation => secondaryDesignation.trim();
  bool get hasBothPersonalDesignations =>
      identityMode == PosterIdentityMode.personal &&
      primaryPersonalDesignation.isNotEmpty &&
      secondaryPersonalDesignation.isNotEmpty;

  String get effectivePersonalDesignation {
    final d1 = whatsappNumber.trim();
    final d2 = secondaryDesignation.trim();
    final d1 = primaryPersonalDesignation;
    final d2 = secondaryPersonalDesignation;
    if (d1.isNotEmpty && d2.isNotEmpty) {
      return '$d1, $d2';
      return '$d1\n$d2';
    }
    return d1.isNotEmpty ? d1 : d2;
  }

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
    if (personalPhoneNumber.trim().isNotEmpty) {
      return personalPhoneNumber.trim();
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
    bool? preferOriginalPersonalPhoto,
    int? personalPhotoRevision,
    int? profileRevision,
    bool? setupCompleted,
    String? secondaryDesignation,
    String? personalPhoneNumber,
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
      preferOriginalPersonalPhoto:
          preferOriginalPersonalPhoto ?? this.preferOriginalPersonalPhoto,
      personalPhotoRevision:
          personalPhotoRevision ?? this.personalPhotoRevision,
      profileRevision: profileRevision ?? this.profileRevision,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      secondaryDesignation: secondaryDesignation ?? this.secondaryDesignation,
      personalPhoneNumber: personalPhoneNumber ?? this.personalPhoneNumber,
    );
  }

  String resolvedName({required AppLanguage language}) {
    final name = switch (identityMode) {
      PosterIdentityMode.business => activeName.trim(),
      PosterIdentityMode.personal => displayName.trim(),
    };
    return name.isEmpty ? PosterProfileService.defaultName : name;
  }

  String resolvedPersonalDesignation({required AppLanguage language}) {
    return effectivePersonalDesignation;
  }

  String get activeWhatsapp {
    return activeWhatsappNumber;
  }

  bool get hasValidName {
    return nameTelugu.trim().isNotEmpty || nameEnglish.trim().isNotEmpty;
  }

  bool get hasValidWhatsapp {
    return whatsappNumber.trim().isNotEmpty;
  }

  bool get hasValidPhoto {
    return photoPath.trim().isNotEmpty || photoUrl.trim().isNotEmpty;
  }

  bool get hasBusinessName {
    return businessName.trim().isNotEmpty;
  }

  bool get hasBusinessTagline {
    return businessTagline.trim().isNotEmpty;
  }

  bool get hasBusinessWhatsapp {
    return businessWhatsappNumber.trim().isNotEmpty;
  }

  bool get hasBusinessLogo {
    return businessLogoPath.trim().isNotEmpty ||
        businessLogoUrl.trim().isNotEmpty;
  }

  bool get isBusinessProfileValid {
    return hasBusinessName && hasBusinessWhatsapp;
  }

  bool get isPersonalProfileValid {
    return hasValidName && hasValidWhatsapp;
  }

  String resolvedDesignation({required AppLanguage language}) {
    if (identityMode == PosterIdentityMode.business) {
      return businessTagline.trim();
    }
    return effectivePersonalDesignation;
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
            other.preferOriginalPersonalPhoto == preferOriginalPersonalPhoto &&
            other.personalPhotoRevision == personalPhotoRevision &&
            other.profileRevision == profileRevision &&
            other.setupCompleted == setupCompleted &&
            other.secondaryDesignation == secondaryDesignation &&
            other.personalPhoneNumber == personalPhoneNumber;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
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
    preferOriginalPersonalPhoto,
    personalPhotoRevision,
    profileRevision,
    setupCompleted,
    secondaryDesignation,
    personalPhoneNumber,
  ]);
}

class UserSavedCutoutPhoto {
  const UserSavedCutoutPhoto({
    required this.id,
    required this.downloadUrl,
    required this.localPath,
    this.originalUrl = '',
    this.originalLocalPath = '',
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String downloadUrl;
  final String localPath;
  final String originalUrl;
  final String originalLocalPath;
  final String source;
  final DateTime? createdAt;

  static UserSavedCutoutPhoto fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final createdValue = data['createdAt'];
    return UserSavedCutoutPhoto(
      id: snapshot.id,
      downloadUrl: (data['downloadUrl'] as String? ?? '').trim(),
      localPath: (data['localPath'] as String? ?? '').trim(),
      originalUrl: (data['originalUrl'] as String? ?? '').trim(),
      originalLocalPath: (data['originalLocalPath'] as String? ?? '').trim(),
      source: (data['source'] as String? ?? '').trim(),
      createdAt: createdValue is Timestamp ? createdValue.toDate() : null,
    );
  }
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
  static const String _secondaryDesignationKey =
      'poster_profile_secondary_designation';
  static const String _personalPhoneKey = 'poster_profile_personal_phone';
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
  static const String _preferOriginalPhotoKey =
      'poster_profile_prefer_original_photo';
  static const String _personalPhotoRevisionKey =
      'poster_profile_personal_photo_revision';
  static const String _profileRevisionKey = 'poster_profile_revision';
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
        profile.secondaryDesignation.trim().isNotEmpty ||
        profile.personalPhoneNumber.trim().isNotEmpty ||
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
      secondaryDesignation:
          (resolvedPrefs.getString(
                    _scopedKey(
                      _secondaryDesignationKey,
                      fallbackUid: fallbackUid,
                    ),
                  ) ??
                  '')
              .trim(),
      personalPhoneNumber:
          (resolvedPrefs.getString(
                    _scopedKey(_personalPhoneKey, fallbackUid: fallbackUid),
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
      preferOriginalPersonalPhoto:
          resolvedPrefs.getBool(
            _scopedKey(_preferOriginalPhotoKey, fallbackUid: fallbackUid),
          ) ??
          false,
      personalPhotoRevision:
          resolvedPrefs.getInt(
            _scopedKey(_personalPhotoRevisionKey, fallbackUid: fallbackUid),
          ) ??
          0,
      profileRevision:
          resolvedPrefs.getInt(
            _scopedKey(_profileRevisionKey, fallbackUid: fallbackUid),
          ) ??
          0,
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
      final localPersonalPhotoPendingSync =
          (fallbackProfile.photoPath.trim().isNotEmpty ||
              fallbackProfile.originalPhotoPath.trim().isNotEmpty) &&
          fallbackProfile.photoUrl.trim().isEmpty &&
          fallbackProfile.originalPhotoUrl.trim().isEmpty;
      final localPersonalPhotoIsNewer =
          fallbackProfile.personalPhotoRevision > remote.personalPhotoRevision;
      fallbackProfile.personalPhotoRevision >= remote.personalPhotoRevision;
      final preferLocalPersonalPhoto =
          localPersonalPhotoPendingSync || localPersonalPhotoIsNewer;
      final preferLocalProfile =
          fallbackProfile.profileRevision > remote.profileRevision;
      fallbackProfile.profileRevision >= remote.profileRevision;
      final localHasBusinessProfile =
          fallbackProfile.identityMode == PosterIdentityMode.business ||
          fallbackProfile.businessName.trim().isNotEmpty ||
          fallbackProfile.businessTagline.trim().isNotEmpty ||
          fallbackProfile.businessWhatsappNumber.trim().isNotEmpty ||
          fallbackProfile.businessLogoPath.trim().isNotEmpty ||
          fallbackProfile.businessLogoUrl.trim().isNotEmpty;
      final merged = remote.copyWith(
        nameTelugu: preferLocalProfile
            ? fallbackProfile.nameTelugu
            : remote.nameTelugu,
        nameEnglish: preferLocalProfile
            ? fallbackProfile.nameEnglish
            : remote.nameEnglish,
        whatsappNumber: preferLocalProfile
            ? fallbackProfile.whatsappNumber
            : remote.whatsappNumber,
        secondaryDesignation:
            preferLocalProfile ||
                fallbackProfile.secondaryDesignation.trim().isNotEmpty
            ? fallbackProfile.secondaryDesignation
            : remote.secondaryDesignation,
        personalPhoneNumber:
            preferLocalProfile ||
                fallbackProfile.personalPhoneNumber.trim().isNotEmpty
            ? fallbackProfile.personalPhoneNumber
            : remote.personalPhoneNumber,
        nameFontFamily: preferLocalProfile
            ? fallbackProfile.nameFontFamily
            : remote.nameFontFamily,
        displayNameMode: preferLocalProfile
            ? fallbackProfile.displayNameMode
            : remote.displayNameMode,
        photoPath: fallbackProfile.photoPath.trim().isNotEmpty
            ? fallbackProfile.photoPath
            : remote.photoPath,
        photoUrl: preferLocalPersonalPhoto
            ? fallbackProfile.photoUrl
            : remote.photoUrl,
        originalPhotoPath: fallbackProfile.originalPhotoPath.trim().isNotEmpty
            ? fallbackProfile.originalPhotoPath
            : remote.originalPhotoPath,
        originalPhotoUrl: preferLocalPersonalPhoto
            ? fallbackProfile.originalPhotoUrl
            : remote.originalPhotoUrl,
        preferOriginalPersonalPhoto: preferLocalPersonalPhoto
            ? fallbackProfile.preferOriginalPersonalPhoto
            : remote.preferOriginalPersonalPhoto,
        personalPhotoRevision: preferLocalPersonalPhoto
            ? fallbackProfile.personalPhotoRevision
            : remote.personalPhotoRevision,
        identityMode: localHasBusinessProfile
            ? fallbackProfile.identityMode
            : remote.identityMode,
        businessName:
            preferLocalProfile || fallbackProfile.businessName.trim().isNotEmpty
            ? fallbackProfile.businessName
            : remote.businessName,
        businessTagline:
            preferLocalProfile ||
                fallbackProfile.businessTagline.trim().isNotEmpty
            ? fallbackProfile.businessTagline
            : remote.businessTagline,
        businessWhatsappNumber:
            preferLocalProfile ||
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
        profileRevision: preferLocalProfile
            ? fallbackProfile.profileRevision
            : remote.profileRevision,
      );
      await _saveLocal(merged);
      return merged;
    } catch (_) {
      return localProfile;
    }
  }

  static ImageProvider<Object>? resolveImageProvider(
    PosterProfileData profile, {
    bool? preferOriginalPersonalPhoto,
    bool preferPersonalPhotoOverBusinessLogo = false,
    bool allowOriginalFallbackWhenCutoutUnavailable = true,
  }) {
    final effectivePreferOriginal =
        preferOriginalPersonalPhoto ?? profile.preferOriginalPersonalPhoto;
    if (preferPersonalPhotoOverBusinessLogo) {
      if (effectivePreferOriginal) {
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

      if (!effectivePreferOriginal &&
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

    if (effectivePreferOriginal) {
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

    if (!effectivePreferOriginal &&
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
    final completedData = data.copyWith(
      setupCompleted: true,
      profileRevision: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveLocal(completedData);
    await _clearSetupSkipped();
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return;
    }
    await _saveRemoteProfile(user.uid, completedData);
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
            'secondaryDesignation': data.secondaryDesignation.trim(),
            'personalPhoneNumber': data.personalPhoneNumber.trim(),
            'nameFontFamily': _sanitizeFont(data.nameFontFamily),
            'photoUrl': data.photoUrl.trim(),
            'originalPhotoUrl': data.originalPhotoUrl.trim(),
            'preferOriginalPersonalPhoto': data.preferOriginalPersonalPhoto,
            'personalPhotoRevision': data.personalPhotoRevision,
            'identityMode': data.identityMode.name,
            'businessName': data.businessName.trim(),
            'businessTagline': data.businessTagline.trim(),
            'businessWhatsappNumber': data.businessWhatsappNumber.trim(),
            'businessLogoUrl': data.businessLogoUrl.trim(),
            'businessLogoStyleId': data.businessLogoStyleId.trim(),
            'setupCompleted': data.setupCompleted,
            'profileRevision': data.profileRevision,
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
    bool? preferOriginalPersonalPhoto,
    bool saveRemoteUrls = false,
    int? personalPhotoRevision,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedPhotoPath = photoPath.trim();
    final trimmedOriginalPhotoPath = originalPhotoPath.trim();
    final trimmedPhotoUrl = photoUrl.trim();
    final trimmedOriginalPhotoUrl = originalPhotoUrl.trim();
    final nextRevision =
        personalPhotoRevision ?? DateTime.now().millisecondsSinceEpoch;

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
    if (preferOriginalPersonalPhoto != null) {
      await prefs.setBool(
        _scopedKey(_preferOriginalPhotoKey),
        preferOriginalPersonalPhoto,
      );
    }
    await prefs.setInt(_scopedKey(_personalPhotoRevisionKey), nextRevision);

    if (!saveRemoteUrls) {
      return;
    }

    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'photoUrl': trimmedPhotoUrl,
      'originalPhotoUrl': trimmedOriginalPhotoUrl,
      if (preferOriginalPersonalPhoto != null) ...<String, dynamic>{
        'preferOriginalPersonalPhoto': preferOriginalPersonalPhoto,
      },
      'personalPhotoRevision': nextRevision,
      'personalPhotoSyncPending':
          trimmedPhotoUrl.isEmpty &&
          trimmedOriginalPhotoUrl.isEmpty &&
          (trimmedPhotoPath.isNotEmpty || trimmedOriginalPhotoPath.isNotEmpty),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posterProfile')
          .doc('main')
          .set(payload, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Personal photo remote save deferred: $error',
        name: 'poster_profile.personal_photo',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> saveReusableCutoutPhoto({
    required File cutoutFile,
    required String downloadUrl,
    String originalUrl = '',
    String originalLocalPath = '',
    required int personalPhotoRevision,
    String source = 'profile',
  }) async {
    await FirebaseBootstrap.ensureInitialized(activateAppCheck: true);
    final user = _currentFirebaseUserOrNull();
    if (user == null || downloadUrl.trim().isEmpty) {
      return;
    }
    final bytes = await cutoutFile.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }
    final id = sha256.convert(bytes).toString();
    final email = user.email?.trim() ?? '';
    final photosCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedCutoutPhotos');

    try {
      final existingSnap = await photosCol
          .orderBy('createdAt', descending: true)
          .get();
      final exists = existingSnap.docs.any((d) => d.id == id);
      if (!exists && existingSnap.docs.length >= 5) {
        for (int i = 4; i < existingSnap.docs.length; i++) {
          await existingSnap.docs[i].reference.delete();
        }
      }
    } catch (_) {}

    await photosCol.doc(id).set(<String, dynamic>{
      'uid': user.uid,
      'email': email,
      'downloadUrl': downloadUrl.trim(),
      'localPath': cutoutFile.path,
      if (originalUrl.trim().isNotEmpty) 'originalUrl': originalUrl.trim(),
      if (originalLocalPath.trim().isNotEmpty)
        'originalLocalPath': originalLocalPath.trim(),
      'source': source.trim().isEmpty ? 'profile' : source.trim(),
      'revision': personalPhotoRevision,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<List<UserSavedCutoutPhoto>> fetchReusableCutoutPhotos({
    int limit = 10,
  }) async {
    await FirebaseBootstrap.ensureInitialized(activateAppCheck: true);
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      return const <UserSavedCutoutPhoto>[];
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedCutoutPhotos')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(UserSavedCutoutPhoto.fromSnapshot)
        .where(
          (item) =>
              item.downloadUrl.trim().isNotEmpty ||
              item.localPath.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  static Future<bool> deleteReusableCutoutPhoto({
    required String id,
    String downloadUrl = '',
  }) async {
    await FirebaseBootstrap.ensureInitialized(activateAppCheck: true);
    final user = _currentFirebaseUserOrNull();
    if (user == null || id.trim().isEmpty) {
      return false;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedCutoutPhotos')
          .doc(id.trim())
          .delete();
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to delete reusable cutout photo: $error',
        name: 'poster_profile.delete_cutout',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future<void> evictRemoteProfilePhotoCache(
    PosterProfileData profile,
  ) async {
    final urls = <String>{
      profile.photoUrl.trim(),
      profile.originalPhotoUrl.trim(),
      profile.businessLogoUrl.trim(),
    }..removeWhere((url) => url.isEmpty);

    for (final url in urls) {
      try {
        await PosterNetworkImageCache.instance.removeFile(url);
      } catch (_) {}
      try {
        await CachedNetworkImageProvider(
          url,
          cacheManager: PosterNetworkImageCache.instance,
          maxWidth: PosterNetworkImageLimits.diskIdentityMaxWidth,
          maxHeight: PosterNetworkImageLimits.diskIdentityMaxHeight,
        ).evict();
      } catch (_) {}
    }
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
        if (await originalFile.exists()) {
          nextOriginalPhotoUrl = await uploadProfilePhoto(
            file: originalFile,
            extension: 'png',
            isOriginal: true,
          ).catchError((_) => nextOriginalPhotoUrl);
        }
      }

      if (needsCutoutUpload) {
        final File cutoutFile = File(profile.photoPath.trim());
        if (await cutoutFile.exists()) {
          nextPhotoUrl = await uploadProfilePhoto(
            file: cutoutFile,
            extension: 'png',
          ).catchError((_) => nextPhotoUrl);
        }
      }

      if (nextPhotoUrl == profile.photoUrl.trim() &&
          nextOriginalPhotoUrl == profile.originalPhotoUrl.trim()) {
        return profile;
      }

      final PosterProfileData updated = profile.copyWith(
        photoUrl: nextPhotoUrl,
        originalPhotoUrl: nextOriginalPhotoUrl,
        personalPhotoRevision: DateTime.now().millisecondsSinceEpoch,
      );
      await savePersonalPhotoAssets(
        photoPath: updated.photoPath,
        originalPhotoPath: updated.originalPhotoPath,
        photoUrl: updated.photoUrl,
        originalPhotoUrl: updated.originalPhotoUrl,
        saveRemoteUrls: true,
        personalPhotoRevision: updated.personalPhotoRevision,
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

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posterProfile')
          .doc('main')
          .set(payload, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Business logo remote save deferred: $error',
        name: 'poster_profile.business_logo',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<String> uploadProfilePhoto({
    required File file,
    required String extension,
    bool isOriginal = false,
  }) async {
    await FirebaseBootstrap.ensureInitialized(activateAppCheck: true);
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      throw StateError('Cannot upload profile photo without signed-in user.');
    }
    final upload = await _prepareOptimizedUpload(
      file: file,
      extension: extension,
      assetPrefix: isOriginal ? 'original_photo' : 'photo',
    );
    final ref = FirebaseStorage.instance.ref(
      'users/${user.uid}/poster_profile/${upload.fileName}',
    );
    await _putProfileUploadWithRetry(
      ref,
      upload,
      logName: 'poster_profile.photo_upload',
    );
    return ref.getDownloadURL();
  }

  static Future<String> uploadBusinessLogo({
    required File file,
    required String extension,
  }) async {
    await FirebaseBootstrap.ensureInitialized(activateAppCheck: true);
    final user = _currentFirebaseUserOrNull();
    if (user == null) {
      throw StateError('Cannot upload business logo without signed-in user.');
    }
    final upload = await _prepareOptimizedUpload(
      file: file,
      extension: extension,
      assetPrefix: 'business_logo',
    );
    final ref = FirebaseStorage.instance.ref(
      'users/${user.uid}/poster_profile/${upload.fileName}',
    );
    await _putProfileUploadWithRetry(
      ref,
      upload,
      logName: 'poster_profile.logo_upload',
    );
    return ref.getDownloadURL();
  }

  static Future<void> _putProfileUploadWithRetry(
    Reference ref,
    _PreparedStorageUpload upload, {
    required String logName,
  }) async {
    Object? firstError;
    StackTrace? firstStackTrace;
    for (var attempt = 0; attempt < 2; attempt += 1) {
      try {
        await ref
            .putData(
              upload.bytes,
              SettableMetadata(contentType: upload.contentType),
            )
            .timeout(const Duration(seconds: 45));
        return;
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
        if (attempt == 0 && _isRetryableStorageUploadError(error)) {
          await Future<void>.delayed(const Duration(milliseconds: 650));
          continue;
        }
        developer.log(
          'Profile storage upload failed: $error',
          name: logName,
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    }
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }

  static bool _isRetryableStorageUploadError(Object error) {
    if (error is TimeoutException) {
      return true;
    }
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      return code == 'retry-limit-exceeded' ||
          code == 'canceled' ||
          code == 'unknown' ||
          code == 'unavailable';
    }
    return error is IOException;
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
      _scopedKey(_secondaryDesignationKey),
      data.secondaryDesignation.trim(),
    );
    await prefs.setString(
      _scopedKey(_personalPhoneKey),
      data.personalPhoneNumber.trim(),
    );
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
    await prefs.setBool(
      _scopedKey(_preferOriginalPhotoKey),
      data.preferOriginalPersonalPhoto,
    );
    await prefs.setInt(
      _scopedKey(_personalPhotoRevisionKey),
      data.personalPhotoRevision,
    );
    await prefs.setInt(_scopedKey(_profileRevisionKey), data.profileRevision);
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
      _secondaryDesignationKey,
      _personalPhoneKey,
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
      _preferOriginalPhotoKey,
      _personalPhotoRevisionKey,
      _profileRevisionKey,
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
      _secondaryDesignationKey,
      _personalPhoneKey,
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
      _preferOriginalPhotoKey,
      _personalPhotoRevisionKey,
      _profileRevisionKey,
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
      } else if (value is int) {
        await prefs.setInt(scopedKey, value);
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
      secondaryDesignation: (data['secondaryDesignation'] as String? ?? '')
          .trim(),
      personalPhoneNumber: (data['personalPhoneNumber'] as String? ?? '')
          .trim(),
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
      preferOriginalPersonalPhoto: data['preferOriginalPersonalPhoto'] == true,
      personalPhotoRevision: _parseInt(data['personalPhotoRevision']),
      profileRevision: _parseInt(data['profileRevision']),
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

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
    final upload = _fitProfileUploadBytes(originalBytes, normalizedExtension);
    final fileHash = _stableBytesHash(upload.bytes);
    return _PreparedStorageUpload(
      bytes: upload.bytes,
      contentType: _contentTypeForExtension(upload.extension),
      fileName: '${assetPrefix}_$fileHash.${upload.extension}',
    );
  }

  static ({Uint8List bytes, String extension}) _fitProfileUploadBytes(
    Uint8List sourceBytes,
    String extension,
  ) {
    if (sourceBytes.length <= _profileUploadMaxBytes) {
      return (bytes: sourceBytes, extension: extension);
    }

    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      return (bytes: sourceBytes, extension: extension);
    }

    var working = img.bakeOrientation(decoded);
    final encodePngFirst = extension == 'png' && working.hasAlpha;
    if (encodePngFirst) {
      final png = Uint8List.fromList(img.encodePng(working, level: 6));
      if (png.length <= _profileUploadMaxBytes) {
        return (bytes: png, extension: 'png');
      }
    }

    for (final quality in <int>[94, 90, 86, 82]) {
      final encoded = Uint8List.fromList(
        img.encodeJpg(working, quality: quality),
      );
      if (encoded.length <= _profileUploadMaxBytes) {
        return (bytes: encoded, extension: 'jpg');
      }
    }

    final longestSide = math.max(working.width, working.height);
    for (final targetSide in <int>[4096, 3200, 2560, 1920]) {
      if (longestSide > targetSide) {
        final scale = targetSide / longestSide;
        working = img.copyResize(
          working,
          width: math.max(1, (working.width * scale).round()),
          height: math.max(1, (working.height * scale).round()),
          interpolation: img.Interpolation.linear,
        );
      }
      for (final quality in <int>[92, 88, 84, 80]) {
        final encoded = Uint8List.fromList(
          img.encodeJpg(working, quality: quality),
        );
        if (encoded.length <= _profileUploadMaxBytes) {
          return (bytes: encoded, extension: 'jpg');
        }
      }
    }

    return (
      bytes: Uint8List.fromList(img.encodeJpg(working, quality: 76)),
      extension: 'jpg',
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

  static const Map<AppLanguage, Map<String, String>> _phraseOverrides =
      <AppLanguage, Map<String, String>>{
        AppLanguage.telugu: <String, String>{
          'mana poster': 'మన పోస్టర్',
          'telugu touch graphics': 'తెలుగు టచ్ గ్రాఫిక్స్',
        },
        AppLanguage.hindi: <String, String>{
          'mana poster': 'मना पोस्टर',
          'telugu touch graphics': 'तेलुगु टच ग्राफिक्स',
        },
        AppLanguage.tamil: <String, String>{
          'mana poster': 'மன போஸ்டர்',
          'telugu touch graphics': 'தெலுகு டச் கிராபிக்ஸ்',
        },
        AppLanguage.kannada: <String, String>{
          'mana poster': 'ಮನ ಪೋಸ್ಟರ್',
          'telugu touch graphics': 'ತೆಲುಗು ಟಚ್ ಗ್ರಾಫಿಕ್ಸ್',
        },
        AppLanguage.malayalam: <String, String>{
          'mana poster': 'മന പോസ്റ്റർ',
          'telugu touch graphics': 'തെലുഗു ടച്ച് ഗ്രാഫിക്സ്',
        },
      };

  static const Map<AppLanguage, Map<String, String>> _wordOverrides =
      <AppLanguage, Map<String, String>>{
        AppLanguage.telugu: <String, String>{
          'telugu': 'తెలుగు',
          'touch': 'టచ్',
          'graphics': 'గ్రాఫిక్స్',
          'graphic': 'గ్రాఫిక్',
          'poster': 'పోస్టర్',
          'mana': 'మన',
          'digital': 'డిజిటల్',
          'studio': 'స్టూడియో',
          'design': 'డిజైన్',
          'designs': 'డిజైన్స్',
          'media': 'మీడియా',
          'tech': 'టెక్',
          'solutions': 'సొల్యూషన్స్',
          'sankranthi': 'సంక్రాంతి',
          'sankranti': 'సంక్రాంతి',
          'pongal': 'పొంగల్',
        },
        AppLanguage.hindi: <String, String>{
          'telugu': 'तेलुगु',
          'touch': 'टच',
          'graphics': 'ग्राफिक्स',
          'graphic': 'ग्राफिक',
          'poster': 'पोस्टर',
          'mana': 'मना',
          'digital': 'डिजिटल',
          'studio': 'स्टूडियो',
          'design': 'डिज़ाइन',
          'designs': 'डिज़ाइन्स',
          'media': 'मीडिया',
          'tech': 'टेक',
          'solutions': 'सोल्यूशन्स',
          'sankranthi': 'संक्रांति',
          'sankranti': 'संक्रांति',
          'pongal': 'पोंगल',
        },
        AppLanguage.tamil: <String, String>{
          'telugu': 'தெலுகு',
          'touch': 'டச்',
          'graphics': 'கிராபிக்ஸ்',
          'graphic': 'கிராபிக்',
          'poster': 'போஸ்டர்',
          'mana': 'மன',
          'digital': 'டிஜிட்டல்',
          'studio': 'ஸ்டுடியோ',
          'design': 'டிசைன்',
          'designs': 'டிசைன்ஸ்',
          'media': 'மீடியா',
          'tech': 'டெக்',
          'solutions': 'சொல்யூஷன்ஸ்',
          'sankranthi': 'சங்கராந்தி',
          'sankranti': 'சங்கராந்தி',
          'pongal': 'பொங்கல்',
        },
        AppLanguage.kannada: <String, String>{
          'telugu': 'ತೆಲುಗು',
          'touch': 'ಟಚ್',
          'graphics': 'ಗ್ರಾಫಿಕ್ಸ್',
          'graphic': 'ಗ್ರಾಫಿಕ್',
          'poster': 'ಪೋಸ್ಟರ್',
          'mana': 'ಮನ',
          'digital': 'ಡಿಜಿಟಲ್',
          'studio': 'ಸ್ಟುಡಿಯೋ',
          'design': 'ಡಿಸೈನ್',
          'designs': 'ಡಿಸೈನ್ಸ್',
          'media': 'ಮೀಡಿಯಾ',
          'tech': 'ಟೆಕ್',
          'solutions': 'ಸೊಲ್ಯೂಶನ್ಸ್',
          'sankranthi': 'ಸಂಕ್ರಾಂತಿ',
          'sankranti': 'ಸಂಕ್ರಾಂತಿ',
          'pongal': 'ಪೊಂಗಲ್',
        },
        AppLanguage.malayalam: <String, String>{
          'telugu': 'തെലുഗു',
          'touch': 'ടച്ച്',
          'graphics': 'ഗ്രാഫിക്സ്',
          'graphic': 'ഗ്രാഫിക്',
          'poster': 'പോസ്റ്റർ',
          'mana': 'മന',
          'digital': 'ഡിജിറ്റൽ',
          'studio': 'സ്റ്റുഡിയോ',
          'design': 'ഡിസൈൻ',
          'designs': 'ഡിസൈൻസ്',
          'media': 'മീഡിയ',
          'tech': 'ടെക്',
          'solutions': 'സൊല്യൂഷൻസ്',
          'sankranthi': 'സംക്രാന്തി',
          'sankranti': 'സംക്രാന്തി',
          'pongal': 'പൊങ്കൽ',
        },
      };

  static const Map<String, String> _latinToTelugu = <String, String>{
    'a': 'అ',
    'b': 'బ',
    'c': 'స',
    'd': 'ద',
    'e': 'ఎ',
    'f': 'ఫ',
    'g': 'గ',
    'h': 'హ',
    'i': 'ఇ',
    'j': 'జ',
    'k': 'క',
    'l': 'ల',
    'm': 'మ',
    'n': 'న',
    'o': 'ఒ',
    'p': 'ప',
    'q': 'క్య',
    'r': 'ర',
    's': 'స',
    't': 'ట',
    'u': 'ఉ',
    'v': 'వ',
    'w': 'వ',
    'x': 'క్స్',
    'y': 'య',
    'z': 'జ్',
  };

  static const Map<String, String> _latinToDevanagari = <String, String>{
    'a': 'अ',
    'b': 'ब',
    'c': 'स',
    'd': 'द',
    'e': 'ए',
    'f': 'फ',
    'g': 'ग',
    'h': 'ह',
    'i': 'इ',
    'j': 'ज',
    'k': 'क',
    'l': 'ल',
    'm': 'म',
    'n': 'न',
    'o': 'ओ',
    'p': 'प',
    'q': 'क',
    'r': 'र',
    's': 'स',
    't': 'त',
    'u': 'उ',
    'v': 'व',
    'w': 'व',
    'x': 'क्स',
    'y': 'य',
    'z': 'ज़',
  };

  static const Map<String, String> _latinToTamil = <String, String>{
    'a': 'அ',
    'b': 'ப',
    'c': 'ச',
    'd': 'த',
    'e': 'எ',
    'f': 'ஃப',
    'g': 'க',
    'h': 'ஹ',
    'i': 'இ',
    'j': 'ஜ',
    'k': 'க',
    'l': 'ல',
    'm': 'ம',
    'n': 'ந',
    'o': 'ஒ',
    'p': 'ப',
    'q': 'க',
    'r': 'ர',
    's': 'ஸ',
    't': 'ட',
    'u': 'உ',
    'v': 'வ',
    'w': 'வ',
    'x': 'க்ஸ்',
    'y': 'ய',
    'z': 'ஜ',
  };

  static const Map<String, String> _latinToKannada = <String, String>{
    'a': 'ಅ',
    'b': 'ಬ',
    'c': 'ಸ',
    'd': 'ದ',
    'e': 'ಎ',
    'f': 'ಫ',
    'g': 'ಗ',
    'h': 'ಹ',
    'i': 'ಇ',
    'j': 'ಜ',
    'k': 'ಕ',
    'l': 'ಲ',
    'm': 'ಮ',
    'n': 'ನ',
    'o': 'ಒ',
    'p': 'ಪ',
    'q': 'ಕ',
    'r': 'ರ',
    's': 'ಸ',
    't': 'ಟ',
    'u': 'ಉ',
    'v': 'ವ',
    'w': 'ವ',
    'x': 'ಕ್ಸ್',
    'y': 'ಯ',
    'z': 'ಜ',
  };

  static const Map<String, String> _latinToMalayalam = <String, String>{
    'a': 'അ',
    'b': 'ബ',
    'c': 'സ',
    'd': 'ദ',
    'e': 'എ',
    'f': 'ഫ',
    'g': 'ഗ',
    'h': 'ഹ',
    'i': 'ഇ',
    'j': 'ജ',
    'k': 'ക',
    'l': 'ല',
    'm': 'മ',
    'n': 'ന',
    'o': 'ഒ',
    'p': 'പ',
    'q': 'ക',
    'r': 'ര',
    's': 'സ',
    't': 'ട',
    'u': 'ഉ',
    'v': 'വ',
    'w': 'വ',
    'x': 'ക്സ്',
    'y': 'യ',
    'z': 'ജ',
  };

  static const Map<String, String> _teluguToLatin = <String, String>{
    'అ': 'a',
    'ఆ': 'aa',
    'ఇ': 'i',
    'ఈ': 'ii',
    'ఉ': 'u',
    'ఊ': 'uu',
    'ఎ': 'e',
    'ఏ': 'ee',
    'ఒ': 'o',
    'ఓ': 'oo',
    'క': 'ka',
    'ఖ': 'kha',
    'గ': 'ga',
    'ఘ': 'gha',
    'చ': 'cha',
    'జ': 'ja',
    'ట': 'ta',
    'డ': 'da',
    'త': 'tha',
    'ద': 'dha',
    'న': 'na',
    'ప': 'pa',
    'బ': 'ba',
    'మ': 'ma',
    'య': 'ya',
    'ర': 'ra',
    'ల': 'la',
    'వ': 'va',
    'శ': 'sha',
    'స': 'sa',
    'హ': 'ha',
    'ళ': 'la',
  };

  static const Map<String, String> _devanagariToLatin = <String, String>{
    'अ': 'a',
    'आ': 'aa',
    'इ': 'i',
    'ई': 'ii',
    'उ': 'u',
    'ऊ': 'uu',
    'ए': 'e',
    'ऐ': 'ai',
    'ओ': 'o',
    'औ': 'au',
    'क': 'ka',
    'ख': 'kha',
    'ग': 'ga',
    'घ': 'gha',
    'च': 'cha',
    'ज': 'ja',
    'ट': 'ta',
    'ड': 'da',
    'त': 'tha',
    'द': 'dha',
    'न': 'na',
    'प': 'pa',
    'ब': 'ba',
    'म': 'ma',
    'य': 'ya',
    'र': 'ra',
    'ल': 'la',
    'व': 'va',
    'श': 'sha',
    'स': 'sa',
    'ह': 'ha',
  };

  static const Map<String, String> _tamilToLatin = <String, String>{
    'அ': 'a',
    'ஆ': 'aa',
    'இ': 'i',
    'ஈ': 'ii',
    'உ': 'u',
    'ஊ': 'uu',
    'எ': 'e',
    'ஏ': 'ee',
    'ஒ': 'o',
    'ஓ': 'oo',
    'க': 'ka',
    'ச': 'sa',
    'ஜ': 'ja',
    'ட': 'ta',
    'த': 'tha',
    'ந': 'na',
    'ப': 'pa',
    'ம': 'ma',
    'ய': 'ya',
    'ர': 'ra',
    'ல': 'la',
    'வ': 'va',
    'ஸ': 'sa',
    'ஹ': 'ha',
  };

  static const Map<String, String> _kannadaToLatin = <String, String>{
    'ಅ': 'a',
    'ಆ': 'aa',
    'ಇ': 'i',
    'ಈ': 'ii',
    'ಉ': 'u',
    'ಊ': 'uu',
    'ಎ': 'e',
    'ಏ': 'ee',
    'ಒ': 'o',
    'ಓ': 'oo',
    'ಕ': 'ka',
    'ಗ': 'ga',
    'ಚ': 'cha',
    'ಜ': 'ja',
    'ಟ': 'ta',
    'ಡ': 'da',
    'ತ': 'tha',
    'ದ': 'dha',
    'ನ': 'na',
    'ಪ': 'pa',
    'ಬ': 'ba',
    'ಮ': 'ma',
    'ಯ': 'ya',
    'ರ': 'ra',
    'ಲ': 'la',
    'ವ': 'va',
    'ಶ': 'sha',
    'ಸ': 'sa',
    'ಹ': 'ha',
  };

  static const Map<String, String> _malayalamToLatin = <String, String>{
    'അ': 'a',
    'ആ': 'aa',
    'ഇ': 'i',
    'ഈ': 'ii',
    'ഉ': 'u',
    'ഊ': 'uu',
    'എ': 'e',
    'ഏ': 'ee',
    'ഒ': 'o',
    'ഓ': 'oo',
    'ക': 'ka',
    'ഗ': 'ga',
    'ച': 'cha',
    'ജ': 'ja',
    'ട': 'ta',
    'ഡ': 'da',
    'ത': 'tha',
    'ദ': 'dha',
    'ന': 'na',
    'പ': 'pa',
    'ബ': 'ba',
    'മ': 'ma',
    'യ': 'ya',
    'ര': 'ra',
    'ല': 'la',
    'വ': 'va',
    'ശ': 'sha',
    'സ': 'sa',
    'ഹ': 'ha',
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
        _ => word,
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
