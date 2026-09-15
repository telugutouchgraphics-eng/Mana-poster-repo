// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HeaderProfileAvatar extends StatelessWidget {
  const _HeaderProfileAvatar({required this.viewerPosterProfile});

  final PosterProfileData viewerPosterProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.2),
        ),
        child: ClipOval(
          child: PosterIdentityVisual(
            profile: viewerPosterProfile,
            fallbackBackground: Colors.white.withValues(alpha: 0.08),
            fallbackIcon: Icons.person_outline_rounded,
            fallbackIconColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

