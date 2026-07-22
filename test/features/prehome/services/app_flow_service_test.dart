import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';

void main() {
  group('AppFlowService.determineStartupRoute', () {
    test('starts fresh installs at state selection', () {
      expect(
        AppFlowService.determineStartupRoute(
          hasAuthenticatedUser: false,
          hasSelectedRegion: false,
          hasSelectedLanguage: false,
        ),
        AppRoutes.language,
      );
    });

    test('moves to app language selection after state selection', () {
      expect(
        AppFlowService.determineStartupRoute(
          hasAuthenticatedUser: false,
          hasSelectedRegion: true,
          hasSelectedLanguage: false,
        ),
        AppRoutes.appLanguage,
      );
    });

    test('moves to login after state and language selection', () {
      expect(
        AppFlowService.determineStartupRoute(
          hasAuthenticatedUser: false,
          hasSelectedRegion: true,
          hasSelectedLanguage: true,
        ),
        AppRoutes.login,
      );
    });

    test('sends already authenticated users directly home', () {
      for (final hasSelectedRegion in <bool>[false, true]) {
        expect(
          AppFlowService.determineStartupRoute(
            hasAuthenticatedUser: true,
            hasSelectedRegion: hasSelectedRegion,
            hasSelectedLanguage: false,
          ),
          AppRoutes.home,
        );
      }
    });
  });
}
