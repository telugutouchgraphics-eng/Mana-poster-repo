import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/localization/app_language.dart';

enum PosterDisplayNameMode { auto, telugu, english }

class PosterProfileData {
  const PosterProfileData({
    required this.nameTelugu,
    required this.nameEnglish,
    required this.whatsappNumber,
    required this.nameFontFamily,
    required this.displayNameMode,
    required this.photoPath,
    required this.photoUrl,
    this.originalPhotoPath = '',
    this.originalPhotoUrl = '',
  });

  final String nameTelugu;
  final String nameEnglish;
  final String whatsappNumber;
  final String nameFontFamily;
  final PosterDisplayNameMode displayNameMode;
  final String photoPath;
  final String photoUrl;
  final String originalPhotoPath;
  final String originalPhotoUrl;

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

  PosterProfileData copyWith({
    String? nameTelugu,
    String? nameEnglish,
    String? displayName,
    String? whatsappNumber,
    String? nameFontFamily,
    PosterDisplayNameMode? displayNameMode,
    String? photoPath,
    String? photoUrl,
    String? originalPhotoPath,
    String? originalPhotoUrl,
  }) {
    final resolvedDisplayName = displayName?.trim() ?? '';
    final nextTelugu = nameTelugu ?? (resolvedDisplayName.isNotEmpty ? resolvedDisplayName : this.nameTelugu);
    final nextEnglish = nameEnglish ?? (resolvedDisplayName.isNotEmpty ? '' : this.nameEnglish);
    return PosterProfileData(
      nameTelugu: nextTelugu,
      nameEnglish: nextEnglish,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      nameFontFamily: nameFontFamily ?? this.nameFontFamily,
      displayNameMode: displayNameMode ?? this.displayNameMode,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      originalPhotoPath: originalPhotoPath ?? this.originalPhotoPath,
      originalPhotoUrl: originalPhotoUrl ?? this.originalPhotoUrl,
    );
  }

  String resolvedName({required AppLanguage language}) {
    final base = displayName.trim().isEmpty
        ? PosterProfileService.defaultName
        : displayName.trim();
    return _NameScriptConverter.convert(base, language);
  }
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
  static const String _originalPhotoPathKey = 'poster_profile_original_photo_path';
  static const String _originalPhotoUrlKey = 'poster_profile_original_photo_url';

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
      ];

  static const String _defaultName = 'User';
  static const String _defaultFontFamily = 'Anek Telugu Condensed Bold';
  static const PosterDisplayNameMode _defaultDisplayNameMode =
      PosterDisplayNameMode.auto;

  static String get defaultName => _defaultName;

  static Future<PosterProfileData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyTeluguName = (prefs.getString(_nameTeluguKey) ?? '').trim();
    final legacyEnglishName = (prefs.getString(_nameEnglishKey) ?? '').trim();
    final legacyName = (prefs.getString(_nameKey) ?? '').trim();
    final firebaseDisplayName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    final resolvedLegacyName = legacyName.isNotEmpty
        ? legacyName
        : (legacyTeluguName.isNotEmpty
              ? legacyTeluguName
              : (legacyEnglishName.isNotEmpty
                    ? legacyEnglishName
                    : (firebaseDisplayName.isNotEmpty
                          ? firebaseDisplayName
                          : _defaultName)));

    final localProfile = PosterProfileData(
      nameTelugu: resolvedLegacyName,
      nameEnglish: '',
      whatsappNumber: (prefs.getString(_whatsappKey) ?? '').trim(),
      nameFontFamily: _sanitizeFont(prefs.getString(_nameFontKey)),
      displayNameMode: _defaultDisplayNameMode,
      photoPath: (prefs.getString(_photoPathKey) ?? '').trim(),
      photoUrl: (prefs.getString(_photoUrlKey) ?? '').trim(),
      originalPhotoPath: (prefs.getString(_originalPhotoPathKey) ?? '').trim(),
      originalPhotoUrl: (prefs.getString(_originalPhotoUrlKey) ?? '').trim(),
    );

    final user = FirebaseAuth.instance.currentUser;
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
      final merged = remote.copyWith(
        photoPath: localProfile.photoPath.trim().isNotEmpty
            ? localProfile.photoPath
            : remote.photoPath,
        originalPhotoPath: localProfile.originalPhotoPath.trim().isNotEmpty
            ? localProfile.originalPhotoPath
            : remote.originalPhotoPath,
      );
      await _saveLocal(merged);
      return merged;
    } catch (_) {
      return localProfile;
    }
  }

  static Future<void> save(PosterProfileData data) async {
    await _saveLocal(data);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('posterProfile')
        .doc('main')
        .set(<String, dynamic>{
          'displayName': data.displayName.trim().isEmpty
              ? _defaultName
              : data.displayName.trim(),
          'whatsappNumber': data.whatsappNumber.trim(),
          'nameFontFamily': _sanitizeFont(data.nameFontFamily),
          'photoUrl': data.photoUrl.trim(),
          'originalPhotoUrl': data.originalPhotoUrl.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<String> uploadProfilePhoto({
    required File file,
    required String extension,
    bool isOriginal = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return '';
    }
    final cleanExtension = extension.trim().isEmpty ? 'jpg' : extension.trim();
    final ref = FirebaseStorage.instance.ref(
      'users/${user.uid}/poster_profile/${isOriginal ? 'original_photo' : 'photo'}.$cleanExtension',
    );
    await ref.putFile(
      file,
      SettableMetadata(contentType: _contentTypeForExtension(cleanExtension)),
    );
    return ref.getDownloadURL();
  }

  static Future<void> deleteProfilePhoto({
    required String photoUrl,
  }) async {
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
    await prefs.setString(_nameKey, cleanName);
    // Cleanup old split-name keys after migration.
    await prefs.remove(_nameTeluguKey);
    await prefs.remove(_nameEnglishKey);
    await prefs.setString(_whatsappKey, data.whatsappNumber.trim());
    await prefs.setString(_nameFontKey, _sanitizeFont(data.nameFontFamily));
    if (data.photoPath.trim().isEmpty) {
      await prefs.remove(_photoPathKey);
    } else {
      await prefs.setString(_photoPathKey, data.photoPath.trim());
    }
    if (data.photoUrl.trim().isEmpty) {
      await prefs.remove(_photoUrlKey);
    } else {
      await prefs.setString(_photoUrlKey, data.photoUrl.trim());
    }
  }

  static PosterProfileData _fromRemoteMap(Map<String, dynamic> data) {
    final remoteName = (data['displayName'] as String? ?? '').trim();
    return PosterProfileData(
      nameTelugu: remoteName.isEmpty ? _defaultName : remoteName,
      nameEnglish: '',
      whatsappNumber: (data['whatsappNumber'] as String? ?? '').trim(),
      nameFontFamily: _sanitizeFont(data['nameFontFamily'] as String?),
      displayNameMode: _defaultDisplayNameMode,
      photoPath: '',
      photoUrl: (data['photoUrl'] as String? ?? '').trim(),
      originalPhotoPath: '',
      originalPhotoUrl: (data['originalPhotoUrl'] as String? ?? '').trim(),
    );
  }

  static String _contentTypeForExtension(String extension) {
    return switch (extension.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
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
}

class _NameScriptConverter {
  static final RegExp _teluguRegExp = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _devanagariRegExp = RegExp(r'[\u0900-\u097F]');
  static final RegExp _tamilRegExp = RegExp(r'[\u0B80-\u0BFF]');
  static final RegExp _kannadaRegExp = RegExp(r'[\u0C80-\u0CFF]');
  static final RegExp _malayalamRegExp = RegExp(r'[\u0D00-\u0D7F]');

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
    return switch (language) {
      AppLanguage.telugu => _toTelugu(raw),
      AppLanguage.hindi => _toHindi(raw),
      AppLanguage.english => _toEnglish(raw),
      AppLanguage.tamil => _toTamil(raw),
      AppLanguage.kannada => _toKannada(raw),
      AppLanguage.malayalam => _toMalayalam(raw),
    };
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



