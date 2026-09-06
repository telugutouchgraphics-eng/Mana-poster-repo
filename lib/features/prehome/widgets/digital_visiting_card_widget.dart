import 'package:flutter/material.dart';

import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

enum VisitingCardStyle {
  royalBlue,
  royalGold,
  emeraldTech,
}

class DigitalVisitingCardWidget extends StatelessWidget {
  const DigitalVisitingCardWidget({
    super.key,
    required this.profile,
    this.style = VisitingCardStyle.royalBlue,
    this.designation,
    this.showAppLogo = true,
  });

  final PosterProfileData profile;
  final VisitingCardStyle style;
  final String? designation;
  final bool showAppLogo;

  static const double cardAspectRatio = 3.5 / 2.0; // 1.75 (Standard Visiting Card)

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: cardAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1E000000),
              blurRadius: 18,
              spreadRadius: 2,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: switch (style) {
          VisitingCardStyle.royalBlue => _buildRoyalBlueCard(context),
          VisitingCardStyle.royalGold => _buildRoyalGoldCard(context),
          VisitingCardStyle.emeraldTech => _buildEmeraldTechCard(context),
        },
      ),
    );
  }

  String get _effectiveName {
    final name = profile.displayName.trim();
    return name.isNotEmpty ? name : 'Mana Poster User';
  }

  String get _effectiveDesignation {
    if (designation != null && designation!.trim().isNotEmpty) {
      return designation!.trim();
    }
    final tagline = profile.businessTagline.trim();
    if (tagline.isNotEmpty) {
      return tagline;
    }
    if (profile.identityMode == PosterIdentityMode.business &&
        profile.businessName.trim().isNotEmpty) {
      return profile.businessName.trim();
    }
    return 'Digital Member';
  }

  String get _effectivePhone {
    final phone = profile.activeWhatsappNumber.trim();
    if (phone.isNotEmpty) {
      return phone.startsWith('+') ? phone : '+91 $phone';
    }
    return '+91 98765 43210';
  }

  ImageProvider? _resolvePhotoProvider() {
    return PosterProfileService.resolveImageProvider(
      profile,
      preferOriginalPersonalPhoto: true,
      preferPersonalPhotoOverBusinessLogo: true,
      allowOriginalFallbackWhenCutoutUnavailable: true,
    );
  }

  Widget _buildPhotoBox({
    required BorderRadius borderRadius,
    required Border border,
    BoxShadow? shadow,
  }) {
    final imageProvider = _resolvePhotoProvider();
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadow != null ? <BoxShadow>[shadow] : null,
        color: const Color(0xFFF1F5F9),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageProvider != null
          ? Image(
              image: imageProvider,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => _fallbackPhoto(),
            )
          : _fallbackPhoto(),
    );
  }

  Widget _fallbackPhoto() {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        size: 54,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Design 1: Royal Corporate Blue
  // ---------------------------------------------------------------------------
  Widget _buildRoyalBlueCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;

        return Container(
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              // Left blue backdrop accent
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: cardW * 0.42,
                child: Container(
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              // Diagonal silver trim
              Positioned(
                left: cardW * 0.40,
                top: -cardH * 0.2,
                bottom: -cardH * 0.2,
                width: 14 * scale,
                child: Transform.rotate(
                  angle: 0.16,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFFFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
              // Subtle background geometric accents
              Positioned(
                right: -20 * scale,
                bottom: -30 * scale,
                width: 140 * scale,
                height: 140 * scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                  ),
                ),
              ),

              // Content Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 14 * scale,
                ),
                child: Row(
                  children: <Widget>[
                    // Left: Large Photo Box
                    SizedBox(
                      width: cardH * 0.78,
                      height: cardH * 0.78,
                      child: _buildPhotoBox(
                        borderRadius: BorderRadius.circular(14 * scale),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 3.5 * scale,
                        ),
                        shadow: BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10 * scale,
                          offset: Offset(0, 4 * scale),
                        ),
                      ),
                    ),

                    SizedBox(width: 22 * scale),

                    // Right: Info & Brand
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Top App Badge
                          if (showAppLogo)
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildBrandBadge(
                                color: const Color(0xFF1E3A8A),
                                textColor: const Color(0xFF1E3A8A),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),

                          // Name
                          Text(
                            _effectiveName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontSize: 19 * scale,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 3 * scale),

                          // Designation
                          Text(
                            _effectiveDesignation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF2563EB),
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 12 * scale),

                          // Phone chip
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8 * scale),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.phone_rounded,
                                  size: 13 * scale,
                                  color: const Color(0xFF1E3A8A),
                                ),
                                SizedBox(width: 6 * scale),
                                Text(
                                  _effectivePhone,
                                  style: TextStyle(
                                    color: const Color(0xFF1E293B),
                                    fontSize: 11.5 * scale,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Design 2: Royal Gold & Maroon
  // ---------------------------------------------------------------------------
  Widget _buildRoyalGoldCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;

        return Container(
          color: const Color(0xFFFCFBF7),
          child: Stack(
            children: <Widget>[
              // Ornate Outer Gold Border
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(8 * scale),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * scale),
                      border: Border.all(
                        color: const Color(0xFFC5A059),
                        width: 1.8 * scale,
                      ),
                    ),
                  ),
                ),
              ),
              // Corner Gold Flourishes
              Positioned(
                top: 14 * scale,
                left: 14 * scale,
                child: Icon(
                  Icons.auto_awesome,
                  size: 12 * scale,
                  color: const Color(0xFFC5A059),
                ),
              ),
              Positioned(
                bottom: 14 * scale,
                right: 14 * scale,
                child: Icon(
                  Icons.auto_awesome,
                  size: 12 * scale,
                  color: const Color(0xFFC5A059),
                ),
              ),

              // Content Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 18 * scale,
                ),
                child: Row(
                  children: <Widget>[
                    // Photo with gold & maroon frame
                    SizedBox(
                      width: cardH * 0.72,
                      height: cardH * 0.72,
                      child: _buildPhotoBox(
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: Border.all(
                          color: const Color(0xFF800020),
                          width: 2.8 * scale,
                        ),
                        shadow: BoxShadow(
                          color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                          blurRadius: 10 * scale,
                          offset: Offset(0, 3 * scale),
                        ),
                      ),
                    ),

                    SizedBox(width: 20 * scale),

                    // Text details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (showAppLogo)
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildBrandBadge(
                                color: const Color(0xFF800020),
                                textColor: const Color(0xFF800020),
                                badgeBg: const Color(0xFFFBF4E8),
                                borderColor: const Color(0xFFC5A059),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),

                          Text(
                            _effectiveName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF800020),
                              fontSize: 20 * scale,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.1,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 3 * scale),

                          Text(
                            _effectiveDesignation.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF9A7B38),
                              fontSize: 10.5 * scale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 10 * scale),

                          Row(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.all(5 * scale),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF800020),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  size: 11 * scale,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              Text(
                                _effectivePhone,
                                style: TextStyle(
                                  color: const Color(0xFF1E293B),
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Design 3: Modern Emerald Tech
  // ---------------------------------------------------------------------------
  Widget _buildEmeraldTechCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;

        return Container(
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              // Top diagonal emerald facet
              Positioned(
                top: -cardH * 0.4,
                right: -cardW * 0.1,
                width: cardW * 0.6,
                height: cardH * 0.9,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF059669).withValues(alpha: 0.12),
                          const Color(0xFF10B981).withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom right geometric polygon accent
              Positioned(
                bottom: -20 * scale,
                right: -20 * scale,
                width: 120 * scale,
                height: 120 * scale,
                child: Transform.rotate(
                  angle: 0.78,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0F766E)],
                      ),
                      borderRadius: BorderRadius.circular(16 * scale),
                    ),
                  ),
                ),
              ),

              // Content Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 18 * scale,
                  vertical: 16 * scale,
                ),
                child: Row(
                  children: <Widget>[
                    // Photo with Emerald rounded border
                    SizedBox(
                      width: cardH * 0.76,
                      height: cardH * 0.76,
                      child: _buildPhotoBox(
                        borderRadius: BorderRadius.circular(18 * scale),
                        border: Border.all(
                          color: const Color(0xFF059669),
                          width: 3.2 * scale,
                        ),
                        shadow: BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                          blurRadius: 10 * scale,
                          offset: Offset(0, 4 * scale),
                        ),
                      ),
                    ),

                    SizedBox(width: 22 * scale),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (showAppLogo)
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildBrandBadge(
                                color: const Color(0xFF059669),
                                textColor: const Color(0xFF059669),
                                badgeBg: const Color(0xFFECFDF5),
                                borderColor: const Color(0xFFA7F3D0),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),

                          Text(
                            _effectiveName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontSize: 19.5 * scale,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 3 * scale),

                          Text(
                            _effectiveDesignation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF475569),
                              fontSize: 11.5 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 10 * scale),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9 * scale,
                              vertical: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8 * scale),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.phone_rounded,
                                  size: 13 * scale,
                                  color: const Color(0xFF059669),
                                ),
                                SizedBox(width: 6 * scale),
                                Text(
                                  _effectivePhone,
                                  style: TextStyle(
                                    color: const Color(0xFF065F46),
                                    fontSize: 11.5 * scale,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: Mana Poster Logo Badge
  // ---------------------------------------------------------------------------
  Widget _buildBrandBadge({
    required Color color,
    required Color textColor,
    Color? badgeBg,
    Color? borderColor,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7 * scale,
        vertical: 3 * scale,
      ),
      decoration: BoxDecoration(
        color: badgeBg ?? const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
          width: 1 * scale,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 14 * scale,
            height: 14 * scale,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 5 * scale),
          Text(
            'Mana Poster',
            style: TextStyle(
              color: textColor,
              fontSize: 9.5 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
