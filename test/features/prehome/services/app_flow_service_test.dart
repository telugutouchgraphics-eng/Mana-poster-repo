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
          hasHandledPoliticalParties: false,
        ),
        AppRoutes.language,
      );
    });

    test('resumes political party selection after state selection', () {
      expect(
        AppFlowService.determineStartupRoute(
          hasAuthenticatedUser: false,
          hasSelectedRegion: true,
          hasHandledPoliticalParties: false,
        ),
        AppRoutes.politicalParties,
      );
    });

    test('sends unauthenticated completed party step to login', () {
      expect(
        AppFlowService.determineStartupRoute(
          hasAuthenticatedUser: false,
          hasSelectedRegion: true,
          hasHandledPoliticalParties: true,
        ),
        AppRoutes.login,
      );
    });

    test('sends already authenticated users directly home', () {
      for (final hasSelectedRegion in <bool>[false, true]) {
        for (final hasHandledParties in <bool>[false, true]) {
          expect(
            AppFlowService.determineStartupRoute(
              hasAuthenticatedUser: true,
              hasSelectedRegion: hasSelectedRegion,
              hasHandledPoliticalParties: hasHandledParties,
            ),
            AppRoutes.home,
          );
        }
      }
    });
  });
}
