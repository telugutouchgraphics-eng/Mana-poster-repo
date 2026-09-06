import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';

enum VisitingCardStyle { royalBlue, royalGold, emeraldTech }

class DigitalVisitingCardWidget extends StatelessWidget {
  const DigitalVisitingCardWidget({
    super.key,
    required this.profile,
    this.style = VisitingCardStyle.royalBlue,
    this.designation,
    this.phoneNumber,
    this.showAppLogo = true,
    this.enableShineEffect = true,
  });

  final PosterProfileData profile;
  final VisitingCardStyle style;
  final String? designation;
  final String? phoneNumber;
  final bool showAppLogo;
  final bool enableShineEffect;

  static const double cardAspectRatio = 3.5 / 2.0;

  @override
  Widget build(BuildContext context) {
    final cardContent = switch (style) {
      VisitingCardStyle.royalBlue => _buildRoyalBlueCard(context),
      VisitingCardStyle.royalGold => _buildRoyalGoldCard(context),
      VisitingCardStyle.emeraldTech => _buildEmeraldTechCard(context),
    };

    return AspectRatio(
      aspectRatio: cardAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              spreadRadius: 2,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            cardContent,
            if (enableShineEffect)
              VisitingCardShineOverlay(
                borderRadius: BorderRadius.circular(16),
                isActive: enableShineEffect,
              ),
          ],
        ),
      ),
    );
  }

  String get _effectiveName {
    final name = profile.displayName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final active = profile.activeName.trim();
    if (active.isNotEmpty) {
      return active;
    }
    return 'Mana Poster User';
  }

  String get _effectiveDesignation {
    if (designation != null && designation!.trim().isNotEmpty) {
      return designation!.trim();
    }
    final personalRaw = profile.whatsappNumber.trim();
    final digits = personalRaw.replaceAll(RegExp(r'\D'), '');
    if (personalRaw.isNotEmpty && digits.length < 10) {
      return personalRaw;
    }
    if (profile.identityMode == PosterIdentityMode.personal &&
        personalRaw.isNotEmpty) {
      return personalRaw;
    }
    final tagline = profile.businessTagline.trim();
    if (tagline.isNotEmpty) {
      return tagline;
    }
    if (profile.identityMode == PosterIdentityMode.business &&
        profile.businessName.trim().isNotEmpty) {
      return profile.businessName.trim();
    }
    return '';
  }

  String get _effectiveSecondaryDesignation {
    if (profile.identityMode == PosterIdentityMode.personal) {
      return profile.secondaryDesignation.trim();
    }
    return '';
  }

  bool get _hasAnyDesignation =>
      _effectiveDesignation.isNotEmpty ||
      _effectiveSecondaryDesignation.isNotEmpty;

  String get _effectivePhone {
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      return _formatPhone(phoneNumber!.trim());
    }

    if (profile.identityMode == PosterIdentityMode.personal) {
      final personalPhone = profile.personalPhoneNumber.trim();
      final personalPhoneDigits = personalPhone.replaceAll(RegExp(r'\D'), '');
      if (personalPhoneDigits.length >= 10) {
        return _formatPhone(personalPhone);
      }
    }

    final biz = profile.businessWhatsappNumber.trim();
    final bizDigits = biz.replaceAll(RegExp(r'\D'), '');
    if (bizDigits.length >= 10) {
      return _formatPhone(biz);
    }

    final personalPhone = profile.personalPhoneNumber.trim();
    final personalPhoneDigits = personalPhone.replaceAll(RegExp(r'\D'), '');
    if (personalPhoneDigits.length >= 10) {
      return _formatPhone(personalPhone);
    }

    try {
      final authPhone =
          FirebaseAuth.instance.currentUser?.phoneNumber?.trim() ?? '';
      if (authPhone.isNotEmpty) {
        return _formatPhone(authPhone);
      }
    } catch (_) {}

    final personal = profile.whatsappNumber.trim();
    final personalDigits = personal.replaceAll(RegExp(r'\D'), '');
    if (personalDigits.length >= 10) {
      return _formatPhone(personal);
    }

    final active = profile.activeWhatsappNumber.trim();
    final activeDigits = active.replaceAll(RegExp(r'\D'), '');
    if (activeDigits.length >= 10) {
      return _formatPhone(active);
    }

    return '';
  }

  String _formatPhone(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return '';
    if (clean.startsWith('+')) return clean;
    final digits = clean.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return '+91 $clean';
  }

  static final RegExp _teluguRegExp = RegExp(r'[\u0C00-\u0C7F]');

  Widget _buildNameWidget({required Color color, required double scale}) {
    final rawName = _effectiveName;
    final isTelugu = _teluguRegExp.hasMatch(rawName);
    String displayName = rawName;
    String? fontFamily;
    if (isTelugu) {
      final converted = TeluguLegacyTextService.convertSync(
        rawName,
        fontFamily: 'Pallavi Bold',
      );
      if (converted != null && converted.trim().isNotEmpty) {
        displayName = converted;
        fontFamily = 'Pallavi Bold';
      }
    }

    return Text(
      displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: (fontFamily != null ? 20.0 : 18.0) * scale,
        fontWeight: FontWeight.w900,
        fontFamily: fontFamily,
        letterSpacing: fontFamily != null ? 0.0 : -0.2,
        height: fontFamily != null ? 1.05 : 1.15,
      ),
    );
  }

  Widget _buildDesignationWidget({
    required Color color,
    required double scale,
  }) {
    final primary = _effectiveDesignation;
    final secondary = _effectiveSecondaryDesignation;
    if (primary.isEmpty && secondary.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget buildLine(
      String text, {
      required double baseFontSize,
      Color? textColor,
    }) {
      final isTelugu = _teluguRegExp.hasMatch(text);
      String displayDesig = text;
      String? fontFamily;
      if (isTelugu) {
        final converted = TeluguLegacyTextService.convertSync(
          text,
          fontFamily: 'Pallavi Medium',
        );
        if (converted != null && converted.trim().isNotEmpty) {
          displayDesig = converted;
          fontFamily = 'Pallavi Medium';
        }
      }

      return Text(
        displayDesig,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor ?? color,
          fontSize:
              (fontFamily != null ? baseFontSize * 1.12 : baseFontSize) * scale,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          height: fontFamily != null ? 1.05 : 1.2,
        ),
      );
    }

    if (primary.isNotEmpty && secondary.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildLine(primary, baseFontSize: 12.0),
          SizedBox(height: 2 * scale),
          buildLine(
            secondary,
            baseFontSize: 10.5,
            textColor: color.withValues(alpha: 0.88),
          ),
        ],
      );
    }

    return buildLine(
      primary.isNotEmpty ? primary : secondary,
      baseFontSize: 12.0,
    );
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
      child: Icon(Icons.person_rounded, size: 54, color: Color(0xFF94A3B8)),
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
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: cardW * 0.42,
                child: Container(color: const Color(0xFF1E3A8A)),
              ),
              Positioned(
                left: cardW * 0.39,
                top: -20,
                bottom: -20,
                width: 22 * scale,
                child: Transform.rotate(
                  angle: 0.12,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE2E8F0),
                          Color(0xFF94A3B8),
                          Color(0xFFE2E8F0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 14 * scale,
                ),
                child: Row(
                  children: <Widget>[
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (showAppLogo)
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildBrandBadge(
                                textColor: const Color(0xFF1E3A8A),
                                badgeBg: Colors.white,
                                borderColor: const Color(0xFFCBD5E1),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(
                            color: const Color(0xFF0F172A),
                            scale: scale,
                          ),
                          SizedBox(height: 3 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFF2563EB),
                              scale: scale,
                            ),
                            SizedBox(height: 10 * scale),
                          ] else
                            SizedBox(height: 6 * scale),
                          if (_effectivePhone.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8 * scale),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 13 * scale,
                                    color: const Color(0xFF2563EB),
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
  // Design 2: Royal Gold VIP
  // ---------------------------------------------------------------------------
  Widget _buildRoyalGoldCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0A0F1D)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                height: 4 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFFDE68A),
                        Color(0xFFD97706),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                height: 4 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFD97706),
                        Color(0xFFFDE68A),
                        Color(0xFFF59E0B),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 18 * scale,
                  vertical: 16 * scale,
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: cardH * 0.74,
                      height: cardH * 0.74,
                      child: Container(
                        padding: EdgeInsets.all(3.5 * scale),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFFDE68A),
                              Color(0xFFB45309),
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.35),
                              blurRadius: 12 * scale,
                              offset: Offset(0, 4 * scale),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildPhotoBox(
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 22 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (showAppLogo)
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildBrandBadge(
                                textColor: const Color(0xFFFDE68A),
                                badgeBg: const Color(0x33F59E0B),
                                borderColor: const Color(0x66F59E0B),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(
                            color: const Color(0xFFF8FAFC),
                            scale: scale,
                          ),
                          SizedBox(height: 3 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFFFBBF24),
                              scale: scale,
                            ),
                            SizedBox(height: 10 * scale),
                          ] else
                            SizedBox(height: 6 * scale),
                          if (_effectivePhone.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x22FBBF24),
                                borderRadius: BorderRadius.circular(8 * scale),
                                border: Border.all(
                                  color: const Color(0x55FBBF24),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 13 * scale,
                                    color: const Color(0xFFFDE68A),
                                  ),
                                  SizedBox(width: 6 * scale),
                                  Text(
                                    _effectivePhone,
                                    style: TextStyle(
                                      color: const Color(0xFFFDE68A),
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
  // Design 3: Emerald Tech Modern
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 18 * scale,
                  vertical: 16 * scale,
                ),
                child: Row(
                  children: <Widget>[
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
                          color: const Color(
                            0xFF059669,
                          ).withValues(alpha: 0.25),
                          blurRadius: 10 * scale,
                          offset: Offset(0, 4 * scale),
                        ),
                      ),
                    ),
                    SizedBox(width: 22 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (showAppLogo)
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildBrandBadge(
                                textColor: const Color(0xFF059669),
                                badgeBg: const Color(0xFFECFDF5),
                                borderColor: const Color(0xFFA7F3D0),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(
                            color: const Color(0xFF0F172A),
                            scale: scale,
                          ),
                          SizedBox(height: 3 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFF059669),
                              scale: scale,
                            ),
                            SizedBox(height: 10 * scale),
                          ] else
                            SizedBox(height: 6 * scale),
                          if (_effectivePhone.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 9 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8 * scale),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                ),
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
    required Color textColor,
    Color? badgeBg,
    Color? borderColor,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: badgeBg ?? Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
          width: 1 * scale,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4 * scale,
            offset: Offset(0, 1.5 * scale),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4 * scale),
            child: Image.asset(
              'assets/branding/mana_poster_logo.png',
              width: 18 * scale,
              height: 18 * scale,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 5 * scale),
          Text(
            'MANA POSTER',
            style: TextStyle(
              color: textColor,
              fontSize: 9 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Holographic Shine & Light Beam Sweep Overlay
// ---------------------------------------------------------------------------
class VisitingCardShineOverlay extends StatefulWidget {
  const VisitingCardShineOverlay({
    super.key,
    required this.borderRadius,
    this.isActive = true,
  });

  final BorderRadius borderRadius;
  final bool isActive;

  @override
  State<VisitingCardShineOverlay> createState() =>
      _VisitingCardShineOverlayState();
}

class _VisitingCardShineOverlayState extends State<VisitingCardShineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VisitingCardShineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return IgnorePointer(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final pos = -2.2 + (_animation.value * 5.4);
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(pos - 0.6, -1.3),
                  end: Alignment(pos + 0.6, 1.3),
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.52),
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const <double>[
                    0.0,
                    0.38,
                    0.44,
                    0.48,
                    0.50,
                    0.52,
                    0.56,
                    0.62,
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
