import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/prehome/services/app_home_banner_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';

void main() {
  group('AppHomeBannerService religion targeting', () {
    test('all religion users can see specific religion banners', () {
      expect(
        AppHomeBannerService.religionMatchesForSelection(
          AppReligionPreference.all,
          <String>['hindu'],
        ),
        isTrue,
      );
      expect(
        AppHomeBannerService.religionMatchesForSelection(
          AppReligionPreference.all,
          <String>['muslim'],
        ),
        isTrue,
      );
      expect(
        AppHomeBannerService.religionMatchesForSelection(
          AppReligionPreference.all,
          <String>['christian'],
        ),
        isTrue,
      );
    });

    test('specific religion users see common and matching banners only', () {
      expect(
        AppHomeBannerService.religionMatchesForSelection(
          AppReligionPreference.hindu,
          <String>['all'],
        ),
        isTrue,
      );
      expect(
        AppHomeBannerService.religionMatchesForSelection(
          AppReligionPreference.hindu,
          <String>['hindu'],
        ),
        isTrue,
      );
      expect(
        AppHomeBannerService.religionMatchesForSelection(
          AppReligionPreference.hindu,
          <String>['muslim'],
        ),
        isFalse,
      );
    });
  });
}
