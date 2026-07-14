import 'package:flutter/material.dart';

import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/poster_profile_details_screen.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PosterProfileData>(
      future: PosterProfileService.load(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Stack(
            children: <Widget>[
              PosterProfileDetailsScreen(
                initialProfile: snapshot.data!,
                completeToHomeOnSave: true,
              ),
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + 12,
                right: 16,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    backgroundColor: Colors.white.withValues(alpha: 0.88),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onPressed: () async {
                    await PosterProfileService.markSetupSkipped();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        }
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
