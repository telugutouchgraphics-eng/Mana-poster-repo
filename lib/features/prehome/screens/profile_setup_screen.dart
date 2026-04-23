import 'package:flutter/material.dart';

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
          return PosterProfileDetailsScreen(
            initialProfile: snapshot.data!,
            completeToHomeOnSave: true,
          );
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
