import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

PosterProfileData _profile({
  String nameTelugu = '',
  String nameEnglish = '',
  String whatsappNumber = '',
  String photoPath = '',
  String photoUrl = '',
  String businessName = '',
  bool setupCompleted = false,
}) {
  return PosterProfileData(
    nameTelugu: nameTelugu,
    nameEnglish: nameEnglish,
    whatsappNumber: whatsappNumber,
    nameFontFamily: PosterProfileService.nameFontOptions.first.family,
    displayNameMode: PosterDisplayNameMode.auto,
    photoPath: photoPath,
    photoUrl: photoUrl,
    businessName: businessName,
    setupCompleted: setupCompleted,
  );
}

void main() {
  group('PosterProfileService.isSetupComplete', () {
    test('does not treat default placeholder names as complete', () {
      expect(
        PosterProfileService.isSetupComplete(
          _profile(nameTelugu: 'User', setupCompleted: true),
        ),
        isFalse,
      );
      expect(
        PosterProfileService.isSetupComplete(
          _profile(nameTelugu: 'Mana Poster Ai User', setupCompleted: true),
        ),
        isFalse,
      );
    });

    test('requires saved setup marker before name-only profiles pass', () {
      expect(
        PosterProfileService.isSetupComplete(_profile(nameTelugu: 'Ravi')),
        isFalse,
      );
      expect(
        PosterProfileService.isSetupComplete(
          _profile(nameTelugu: 'Ravi', setupCompleted: true),
        ),
        isTrue,
      );
    });

    test('treats profile photo as complete', () {
      expect(
        PosterProfileService.isSetupComplete(_profile(photoUrl: 'https://x/y')),
        isTrue,
      );
    });
  });

  group('PosterProfileService setup skip', () {
    test('persists optional setup skip locally', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      expect(await PosterProfileService.hasSkippedSetup(), isFalse);

      await PosterProfileService.markSetupSkipped();

      expect(await PosterProfileService.hasSkippedSetup(), isTrue);
    });
  });

  group('ScriptLocalizationService.localizeCategoryLabel', () {
    test('does not re-convert dynamic Telugu category labels', () {
      expect(
        ScriptLocalizationService.localizeCategoryLabel(
          'చంద్రశేఖర్ ఆజాద్ జయంతి',
          AppLanguage.telugu,
        ),
        'చంద్రశేఖర్ ఆజాద్ జయంతి',
      );
    });

    test('localizes common home category labels to Telugu', () {
      expect(
        ScriptLocalizationService.localizeCategoryLabel(
          'Political',
          AppLanguage.telugu,
        ),
        'రాజకీయం',
      );
      expect(
        ScriptLocalizationService.localizeCategoryLabel(
          'Good Evening',
          AppLanguage.telugu,
        ),
        'శుభ సాయంత్రం',
      );
      expect(
        ScriptLocalizationService.localizeCategoryLabel(
          'Bonalu',
          AppLanguage.telugu,
        ),
        'బోనాలు',
      );
    });
  });
}
