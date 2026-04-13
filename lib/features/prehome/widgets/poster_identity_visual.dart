import 'package:flutter/material.dart';

import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class PosterIdentityVisual extends StatelessWidget {
  const PosterIdentityVisual({
    super.key,
    required this.profile,
    this.fit = BoxFit.cover,
    this.preferOriginalPersonalPhoto = false,
    this.fallbackIcon = Icons.person_rounded,
    this.fallbackBackground = const Color(0xFFF1F5F9),
    this.fallbackIconColor = const Color(0xFF64748B),
    this.textScale = 1.0,
  });

  final PosterProfileData profile;
  final BoxFit fit;
  final bool preferOriginalPersonalPhoto;
  final IconData fallbackIcon;
  final Color fallbackBackground;
  final Color fallbackIconColor;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final imageProvider = PosterProfileService.resolveImageProvider(
      profile,
      preferOriginalPersonalPhoto: preferOriginalPersonalPhoto,
    );
    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _fallbackVisual(),
      );
    }

    if (profile.identityMode == PosterIdentityMode.business &&
        profile.businessName.trim().isNotEmpty) {
      return _GeneratedBusinessLogo(
        businessName: profile.businessName.trim(),
        styleId: profile.businessLogoStyleId.trim().isEmpty
            ? 'style_1'
            : profile.businessLogoStyleId.trim(),
        tagline: profile.businessTagline.trim(),
        textScale: textScale,
      );
    }

    return _fallbackVisual();
  }

  Widget _fallbackVisual() {
    return Container(
      color: fallbackBackground,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: fallbackIconColor,
        size: 28 * textScale.clamp(0.8, 1.4),
      ),
    );
  }
}

class _GeneratedBusinessLogo extends StatelessWidget {
  const _GeneratedBusinessLogo({
    required this.businessName,
    required this.styleId,
    required this.tagline,
    required this.textScale,
  });

  final String businessName;
  final String styleId;
  final String tagline;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(businessName);
    final palette = _paletteForStyle(styleId);
    final useFullName = styleId == 'style_5' || styleId == 'style_9';
    final hasTagline =
        tagline.isNotEmpty &&
        (styleId == 'style_4' || styleId == 'style_7' || styleId == 'style_10');

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide <= 0
            ? 100.0
            : constraints.biggest.shortestSide;
        if (size < 44) {
          return ClipOval(
            child: Container(
              decoration: BoxDecoration(
                color: palette.background,
                shape: BoxShape.circle,
                border: palette.border == null
                    ? null
                    : Border.all(color: palette.border!),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: palette.accent,
                  fontSize: (size * 0.34 * textScale).clamp(10.0, 16.0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          );
        }
        final badgeSize = size * 0.34;
        final initialsSize = size * 0.2 * textScale;
        final nameSize = (useFullName ? size * 0.11 : size * 0.12)
            .clamp(9.5, 16.0)
            .toDouble();
        final taglineSize = (size * 0.08).clamp(7.0, 11.0).toDouble();
        final bottomBandHeight = (size * 0.18).clamp(12.0, 20.0).toDouble();

        return ClipOval(
          child: Container(
            decoration: BoxDecoration(
              color: palette.background,
              shape: BoxShape.circle,
              border: palette.border == null
                  ? null
                  : Border.all(color: palette.border!),
            ),
            child: Stack(
              children: <Widget>[
                if (styleId == 'style_2' || styleId == 'style_6')
                  Positioned(
                    right: -size * 0.08,
                    top: -size * 0.08,
                    child: Container(
                      width: size * 0.42,
                      height: size * 0.42,
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (styleId == 'style_8')
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: bottomBandHeight,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(bottomBandHeight),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(size * 0.1),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: size * 0.72,
                          maxHeight: size * 0.72,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (styleId == 'style_1' ||
                                styleId == 'style_3' ||
                                styleId == 'style_6' ||
                                styleId == 'style_10')
                              Container(
                                width: badgeSize,
                                height: badgeSize,
                                decoration: BoxDecoration(
                                  color: palette.accent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: palette.onAccent,
                                    fontSize: initialsSize,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              )
                            else
                              Text(
                                initials,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: TextStyle(
                                  color: palette.accent,
                                  fontSize: (size * 0.24 * textScale)
                                      .clamp(16.0, 28.0)
                                      .toDouble(),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            SizedBox(height: size * 0.05),
                            Text(
                              useFullName
                                  ? businessName
                                  : _shortName(businessName),
                              maxLines: useFullName ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.foreground,
                                fontSize: nameSize,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                            if (hasTagline) ...<Widget>[
                              SizedBox(height: size * 0.03),
                              Text(
                                tagline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: palette.foreground.withValues(
                                    alpha: 0.72,
                                  ),
                                  fontSize: taglineSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initialsFromName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'MP';
    }
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _shortName(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 14) {
      return trimmed;
    }
    return '${trimmed.substring(0, 14)}…';
  }

  _LogoPalette _paletteForStyle(String id) {
    return switch (id) {
      'style_2' => const _LogoPalette(
        background: Color(0xFFF8FAFC),
        foreground: Color(0xFF0F172A),
        accent: Color(0xFF2563EB),
        onAccent: Colors.white,
        border: Color(0xFFDCE7F8),
      ),
      'style_3' => const _LogoPalette(
        background: Color(0xFF0F172A),
        foreground: Colors.white,
        accent: Color(0xFFF59E0B),
        onAccent: Color(0xFF0F172A),
      ),
      'style_4' => const _LogoPalette(
        background: Color(0xFFECFDF5),
        foreground: Color(0xFF14532D),
        accent: Color(0xFF22C55E),
        onAccent: Colors.white,
      ),
      'style_5' => const _LogoPalette(
        background: Color(0xFFFEF2F2),
        foreground: Color(0xFF991B1B),
        accent: Color(0xFFEF4444),
        onAccent: Colors.white,
        border: Color(0xFFFECACA),
      ),
      'style_6' => const _LogoPalette(
        background: Color(0xFFF5F3FF),
        foreground: Color(0xFF5B21B6),
        accent: Color(0xFF7C3AED),
        onAccent: Colors.white,
      ),
      'style_7' => const _LogoPalette(
        background: Color(0xFFFFFBEB),
        foreground: Color(0xFF92400E),
        accent: Color(0xFFF59E0B),
        onAccent: Colors.white,
      ),
      'style_8' => const _LogoPalette(
        background: Colors.white,
        foreground: Color(0xFF111827),
        accent: Color(0xFF10B981),
        onAccent: Colors.white,
        border: Color(0xFFE5E7EB),
      ),
      'style_9' => const _LogoPalette(
        background: Color(0xFF111827),
        foreground: Colors.white,
        accent: Color(0xFF38BDF8),
        onAccent: Color(0xFF082F49),
      ),
      'style_10' => const _LogoPalette(
        background: Color(0xFFFFF1F2),
        foreground: Color(0xFF9F1239),
        accent: Color(0xFFE11D48),
        onAccent: Colors.white,
      ),
      _ => const _LogoPalette(
        background: Colors.white,
        foreground: Color(0xFF0F172A),
        accent: Color(0xFF6D28D9),
        onAccent: Colors.white,
        border: Color(0xFFE2E8F0),
      ),
    };
  }
}

class _LogoPalette {
  const _LogoPalette({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.onAccent,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color accent;
  final Color onAccent;
  final Color? border;
}
