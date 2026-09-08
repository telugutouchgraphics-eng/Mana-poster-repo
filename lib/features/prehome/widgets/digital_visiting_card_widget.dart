import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';

enum VisitingCardStyle {
  classicPearlGold,
  dualToneObsidian,
  royalSapphire,
  emeraldCrest,
  modernTitaniumSlate,
}

class DigitalVisitingCardWidget extends StatelessWidget {
  const DigitalVisitingCardWidget({
    super.key,
    required this.profile,
    this.style = VisitingCardStyle.classicPearlGold,
    this.designation,
    this.phoneNumber,
    this.email,
    this.address,
    this.showAppLogo = true,
    this.enableShineEffect = true,
  });

  final PosterProfileData profile;
  final VisitingCardStyle style;
  final String? designation;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final bool showAppLogo;
  final bool enableShineEffect;

  static const double cardAspectRatio = 3.5 / 2.0;

  @override
  Widget build(BuildContext context) {
    final cardContent = switch (style) {
      VisitingCardStyle.classicPearlGold => _buildClassicPearlGoldCard(context),
      VisitingCardStyle.dualToneObsidian => _buildDualToneObsidianCard(context),
      VisitingCardStyle.royalSapphire => _buildRoyalSapphireCard(context),
      VisitingCardStyle.emeraldCrest => _buildEmeraldCrestCard(context),
      VisitingCardStyle.modernTitaniumSlate => _buildModernTitaniumSlateCard(
        context,
      ),
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

  String get _effectiveEmail {
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim();
    }
    if (profile.email.trim().isNotEmpty) {
      return profile.email.trim();
    }
    try {
      final authEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
      if (authEmail.isNotEmpty) {
        return authEmail;
      }
    } catch (_) {}
    return '';
  }

  String get _effectiveAddress {
    final raw = (address != null && address!.trim().isNotEmpty)
        ? address!.trim()
        : profile.address.trim();
    final alphanumericOnly = raw.replaceAll(RegExp(r'[\s,.\-_]'), '');
    if (alphanumericOnly.isEmpty) return '';
    return raw;
  }

  static final RegExp _teluguRegExp = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinRegExp = RegExp(r'[A-Za-z]');

  bool _isMixedTeluguAndLatin(String text) {
    return _teluguRegExp.hasMatch(text) && _latinRegExp.hasMatch(text);
  }

  bool _isTeluguCodeUnit(int codeUnit) {
    return codeUnit >= 0x0C00 && codeUnit <= 0x0C7F;
  }

  TextSpan _mixedLegacySpan({
    required String text,
    required TextStyle baseStyle,
    required String legacyFontFamily,
    required String latinFontFamily,
  }) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    bool? currentIsTelugu;

    void flush() {
      if (buffer.isEmpty || currentIsTelugu == null) {
        return;
      }
      final raw = buffer.toString();
      final isTeluguRun = currentIsTelugu;
      final displayText = isTeluguRun
          ? (TeluguLegacyTextService.convertSync(
                  raw,
                  fontFamily: legacyFontFamily,
                ) ??
                raw)
          : raw;
      spans.add(
        TextSpan(
          text: displayText,
          style: baseStyle.copyWith(
            fontFamily: isTeluguRun ? legacyFontFamily : latinFontFamily,
          ),
        ),
      );
      buffer.clear();
    }

    for (final rune in text.runes) {
      final isTelugu = _isTeluguCodeUnit(rune);
      if (currentIsTelugu != null && currentIsTelugu != isTelugu) {
        flush();
      }
      currentIsTelugu = isTelugu;
      buffer.write(String.fromCharCode(rune));
    }
    flush();
    return TextSpan(style: baseStyle, children: spans);
  }

  Widget _buildNameWidget({required Color color, required double scale}) {
    final rawName = _effectiveName;
    final isTelugu = _teluguRegExp.hasMatch(rawName);
    final isMixed = _isMixedTeluguAndLatin(rawName);
    String displayName = rawName;
    String? fontFamily;
    if (!isMixed && isTelugu) {
      final converted = TeluguLegacyTextService.convertSync(
        rawName,
        fontFamily: 'Kranthi',
      );
      if (converted != null && converted.trim().isNotEmpty) {
        displayName = converted;
        fontFamily = 'Kranthi';
      }
    }

    final textStyle = TextStyle(
      color: color,
      fontSize: (fontFamily != null || isMixed ? 24.0 : 18.0) * scale,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      letterSpacing: fontFamily != null || isMixed ? 0.0 : -0.2,
      height: fontFamily != null || isMixed ? 1.05 : 1.15,
    );
    if (isMixed) {
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: _mixedLegacySpan(
          text: rawName,
          baseStyle: textStyle,
          legacyFontFamily: 'Kranthi',
          latinFontFamily: 'Poppins',
        ),
      );
    }

    return Text(
      displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
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
      final isMixed = _isMixedTeluguAndLatin(text);
      String displayDesig = text;
      String? fontFamily;
      if (!isMixed && isTelugu) {
        final converted = TeluguLegacyTextService.convertSync(
          text,
          fontFamily: 'Pallavi Medium',
        );
        if (converted != null && converted.trim().isNotEmpty) {
          displayDesig = converted;
          fontFamily = 'Pallavi Medium';
        }
      }

      final textStyle = TextStyle(
        color: textColor ?? color,
        fontSize:
            (fontFamily != null || isMixed
                ? baseFontSize * 1.12
                : baseFontSize) *
            scale,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
        height: fontFamily != null || isMixed ? 1.05 : 1.2,
      );
      if (isMixed) {
        return RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: _mixedLegacySpan(
            text: text,
            baseStyle: textStyle,
            legacyFontFamily: 'Pallavi Medium',
            latinFontFamily: 'Montserrat',
          ),
        );
      }

      return Text(
        displayDesig,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    if (primary.isNotEmpty && secondary.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildLine(primary, baseFontSize: 11.5),
          SizedBox(height: 2 * scale),
          buildLine(secondary, baseFontSize: 11.5, textColor: color),
        ],
      );
    }

    return buildLine(
      primary.isNotEmpty ? primary : secondary,
      baseFontSize: 12.0,
    );
  }

  Widget _buildContactSection({
    required Color iconColor,
    required Color textColor,
    required Color addressColor,
    Color? iconBgColor,
    Color? iconBorderColor,
    required double scale,
  }) {
    final phone = _effectivePhone;
    final email = _effectiveEmail;
    final address = _effectiveAddress;

    if (phone.isEmpty && email.isEmpty && address.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget makeIcon(IconData icon) {
      if (iconBgColor != null) {
        return Container(
          width: 17 * scale,
          height: 17 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBgColor,
            border: iconBorderColor != null
                ? Border.all(color: iconBorderColor, width: 0.8 * scale)
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 9.5 * scale, color: iconColor),
        );
      }
      return Icon(icon, size: 11 * scale, color: iconColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (phone.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 2.8 * scale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                makeIcon(Icons.phone_rounded),
                SizedBox(width: 6 * scale),
                Flexible(
                  child: Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10.5 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (email.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 2.8 * scale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                makeIcon(Icons.email_rounded),
                SizedBox(width: 6 * scale),
                Flexible(
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 9.5 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (address.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 1 * scale),
                child: makeIcon(Icons.location_on_rounded),
              ),
              SizedBox(width: 6 * scale),
              Flexible(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: addressColor,
                    fontSize: 8.5 * scale,
                    fontWeight: FontWeight.w600,
                    height: 1.18,
                  ),
                ),
              ),
            ],
          ),
      ],
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
    BoxShape shape = BoxShape.rectangle,
  }) {
    final imageProvider = _resolvePhotoProvider();
    return Container(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
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
  // Design 1: Classic Pearl & Gold Executive
  // ---------------------------------------------------------------------------
  Widget _buildClassicPearlGoldCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;
        final photoSize = cardH * 0.58;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFAF8F5), Color(0xFFF4EFE6), Color(0xFFEBE3D3)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              // Top Gold Foil Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4.5 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFB8860B),
                        Color(0xFFFDE68A),
                        Color(0xFFD4AF37),
                        Color(0xFF996515),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom Gold Foil Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 4.5 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF996515),
                        Color(0xFFD4AF37),
                        Color(0xFFFDE68A),
                        Color(0xFFB8860B),
                      ],
                    ),
                  ),
                ),
              ),
              // Luxury Inner Gold Filigree Frame
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.all(7 * scale),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11 * scale),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                      width: 0.9 * scale,
                    ),
                  ),
                ),
              ),
              // Subtle luxury background geometric accent
              Positioned(
                right: -20 * scale,
                bottom: -20 * scale,
                width: 140 * scale,
                height: 140 * scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                      width: 18 * scale,
                    ),
                  ),
                ),
              ),
              // Content Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 16 * scale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // Circular Gold Bezel Photo
                    Container(
                      width: photoSize,
                      height: photoSize,
                      padding: EdgeInsets.all(3.0 * scale),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFF7D6),
                            Color(0xFFD4AF37),
                            Color(0xFFAA771C),
                            Color(0xFFFDE68A),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(
                              0xFFB8860B,
                            ).withValues(alpha: 0.28),
                            blurRadius: 10 * scale,
                            offset: Offset(0, 4 * scale),
                          ),
                        ],
                      ),
                      child: _buildPhotoBox(
                        shape: BoxShape.circle,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.transparent, width: 0),
                      ),
                    ),
                    SizedBox(width: 18 * scale),
                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (showAppLogo)
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildBrandBadge(
                                textColor: const Color(0xFF78350F),
                                badgeBg: Colors.white,
                                borderColor: const Color(0xFFD4AF37),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(
                            color: const Color(0xFF0F172A),
                            scale: scale,
                          ),
                          SizedBox(height: 2.5 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFF996515),
                              scale: scale,
                            ),
                            SizedBox(height: 5 * scale),
                          ] else
                            SizedBox(height: 4 * scale),
                          // Subtle Gold Accent Divider
                          Container(
                            height: 1.2 * scale,
                            width: 120 * scale,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFD4AF37), Color(0x22D4AF37)],
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          _buildContactSection(
                            iconColor: const Color(0xFF996515),
                            textColor: const Color(0xFF1E293B),
                            addressColor: const Color(0xFF475569),
                            iconBgColor: const Color(0xFFFBF4E4),
                            iconBorderColor: const Color(0xFFE2C988),
                            scale: scale,
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
  // Design 2: Dual-Tone Obsidian & Gold
  // ---------------------------------------------------------------------------
  Widget _buildDualToneObsidianCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;
        final photoSize = cardH * 0.58;

        return Container(
          decoration: const BoxDecoration(color: Color(0xFF0C0D12)),
          child: Stack(
            children: <Widget>[
              // Right Midnight Slate Section
              Positioned(
                top: 0,
                bottom: 0,
                left: cardW * 0.35,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF181B24), Color(0xFF10131A)],
                    ),
                  ),
                ),
              ),
              // 24K Gold Divider Bar
              Positioned(
                top: 0,
                bottom: 0,
                left: cardW * 0.35 - (1.5 * scale),
                width: 3 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFDE68A),
                        Color(0xFFD4AF37),
                        Color(0xFFAA771C),
                        Color(0xFFF5D77F),
                      ],
                    ),
                  ),
                ),
              ),
              // Outer micro gold border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      width: 1 * scale,
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
                    // Left Section: Photo in Obsidian Gold Squircle
                    SizedBox(
                      width: cardW * 0.35 - (24 * scale),
                      child: Center(
                        child: Container(
                          width: photoSize,
                          height: photoSize,
                          padding: EdgeInsets.all(2.8 * scale),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16 * scale),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFF3B0),
                                Color(0xFFD4AF37),
                                Color(0xFF8C5E0D),
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10 * scale,
                                offset: Offset(0, 3 * scale),
                              ),
                            ],
                          ),
                          child: _buildPhotoBox(
                            borderRadius: BorderRadius.circular(13.2 * scale),
                            border: Border.all(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20 * scale),
                    // Right Section: Details
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
                                badgeBg: const Color(0xFF0F1118),
                                borderColor: const Color(0xFFD4AF37),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(
                            color: const Color(0xFFFFFDF5),
                            scale: scale,
                          ),
                          SizedBox(height: 2.5 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFFF5C542),
                              scale: scale,
                            ),
                            SizedBox(height: 6 * scale),
                          ] else
                            SizedBox(height: 4 * scale),
                          _buildContactSection(
                            iconColor: const Color(0xFFF5C542),
                            textColor: const Color(0xFFF8FAFC),
                            addressColor: const Color(0xFFCBD5E1),
                            iconBgColor: const Color(0xFF222736),
                            iconBorderColor: const Color(0xFF424A5E),
                            scale: scale,
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
  // Design 3: Royal Sapphire
  // ---------------------------------------------------------------------------
  Widget _buildRoyalSapphireCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;
        final photoSize = cardH * 0.58;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A162B), Color(0xFF0E2244), Color(0xFF070F1E)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              // Top Cyan Accent Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3.5 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0284C7),
                        Color(0xFF38BDF8),
                        Color(0xFF93C5FD),
                        Color(0xFF0284C7),
                      ],
                    ),
                  ),
                ),
              ),
              // Platinum Inner Geometric Border
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.all(7 * scale),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11 * scale),
                    border: Border.all(
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.3),
                      width: 0.9 * scale,
                    ),
                  ),
                ),
              ),
              // Modern Radial Glow
              Positioned(
                left: -30 * scale,
                top: -30 * scale,
                width: 140 * scale,
                height: 140 * scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 16 * scale,
                ),
                child: Row(
                  children: <Widget>[
                    // Photo in Platinum & Sapphire Squircle
                    Container(
                      width: photoSize,
                      height: photoSize,
                      padding: EdgeInsets.all(2.8 * scale),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16 * scale),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFBAE6FD),
                            Color(0xFF38BDF8),
                            Color(0xFF1E40AF),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(
                              0xFF0284C7,
                            ).withValues(alpha: 0.35),
                            blurRadius: 10 * scale,
                            offset: Offset(0, 3 * scale),
                          ),
                        ],
                      ),
                      child: _buildPhotoBox(
                        borderRadius: BorderRadius.circular(13.2 * scale),
                        border: Border.all(color: Colors.transparent, width: 0),
                      ),
                    ),
                    SizedBox(width: 18 * scale),
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
                                textColor: const Color(0xFF7DD3FC),
                                badgeBg: const Color(0xFF0F2342),
                                borderColor: const Color(0xFF38BDF8),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(color: Colors.white, scale: scale),
                          SizedBox(height: 2.5 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFF38BDF8),
                              scale: scale,
                            ),
                            SizedBox(height: 5 * scale),
                          ] else
                            SizedBox(height: 4 * scale),
                          // Subtle Sapphire Divider
                          Container(
                            height: 1 * scale,
                            width: 110 * scale,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0x1138BDF8)],
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          _buildContactSection(
                            iconColor: const Color(0xFF38BDF8),
                            textColor: const Color(0xFFF1F5F9),
                            addressColor: const Color(0xFF94A3B8),
                            iconBgColor: const Color(0xFF132B4F),
                            iconBorderColor: const Color(0xFF1D4ED8),
                            scale: scale,
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
  // Design 4: Emerald Crest
  // ---------------------------------------------------------------------------
  Widget _buildEmeraldCrestCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;
        final photoSize = cardH * 0.58;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF041C14), Color(0xFF0A3326), Color(0xFF03140E)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              // Champagne Gold Top/Bottom Corner Accents
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3.5 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFDE68A),
                        Color(0xFFEAB308),
                        Color(0xFFCA8A04),
                        Color(0xFFFDE68A),
                      ],
                    ),
                  ),
                ),
              ),
              // Inner Champagne Frame
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.all(7 * scale),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11 * scale),
                    border: Border.all(
                      color: const Color(0xFFEAB308).withValues(alpha: 0.35),
                      width: 0.9 * scale,
                    ),
                  ),
                ),
              ),
              // Emerald geometric corner flourish
              Positioned(
                right: -25 * scale,
                bottom: -25 * scale,
                width: 130 * scale,
                height: 130 * scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      width: 14 * scale,
                    ),
                  ),
                ),
              ),
              // Content Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 16 * scale,
                ),
                child: Row(
                  children: <Widget>[
                    // Photo in Champagne Gold Circular Rim
                    Container(
                      width: photoSize,
                      height: photoSize,
                      padding: EdgeInsets.all(3.0 * scale),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFEF08A),
                            Color(0xFFEAB308),
                            Color(0xFF854D0E),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(
                              0xFFEAB308,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10 * scale,
                            offset: Offset(0, 3 * scale),
                          ),
                        ],
                      ),
                      child: _buildPhotoBox(
                        shape: BoxShape.circle,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.transparent, width: 0),
                      ),
                    ),
                    SizedBox(width: 18 * scale),
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
                                textColor: const Color(0xFFFEF08A),
                                badgeBg: const Color(0xFF09291E),
                                borderColor: const Color(0xFFEAB308),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(
                            color: const Color(0xFFECFDF5),
                            scale: scale,
                          ),
                          SizedBox(height: 2.5 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFFFDE047),
                              scale: scale,
                            ),
                            SizedBox(height: 5 * scale),
                          ] else
                            SizedBox(height: 4 * scale),
                          // Subtle Emerald/Gold Divider
                          Container(
                            height: 1 * scale,
                            width: 110 * scale,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEAB308), Color(0x11EAB308)],
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          _buildContactSection(
                            iconColor: const Color(0xFFFDE047),
                            textColor: const Color(0xFFF0FDF4),
                            addressColor: const Color(0xFFA7F3D0),
                            iconBgColor: const Color(0xFF0D3D2E),
                            iconBorderColor: const Color(0xFF059669),
                            scale: scale,
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
  // Design 5: Modern Titanium Slate
  // ---------------------------------------------------------------------------
  Widget _buildModernTitaniumSlateCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final scale = cardW / 420.0;
        final photoSize = cardH * 0.58;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF181D26), Color(0xFF222834), Color(0xFF13171F)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              // Electric Amber Micro Ribbon Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3.5 * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF97316),
                        Color(0xFFFDBA74),
                        Color(0xFFEA580C),
                      ],
                    ),
                  ),
                ),
              ),
              // Modern Titanium Border
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.all(7 * scale),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11 * scale),
                    border: Border.all(
                      color: const Color(0xFF64748B).withValues(alpha: 0.35),
                      width: 0.9 * scale,
                    ),
                  ),
                ),
              ),
              // High-tech corner accent lines
              Positioned(
                right: 14 * scale,
                bottom: 14 * scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 14 * scale,
                      height: 2 * scale,
                      color: const Color(0xFFF97316).withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 3 * scale),
                    Container(
                      width: 5 * scale,
                      height: 2 * scale,
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              // Content Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 16 * scale,
                ),
                child: Row(
                  children: <Widget>[
                    // Photo in Titanium & Amber Bezel
                    Container(
                      width: photoSize,
                      height: photoSize,
                      padding: EdgeInsets.all(2.8 * scale),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16 * scale),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFED7AA),
                            Color(0xFFF97316),
                            Color(0xFF475569),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(
                              0xFFF97316,
                            ).withValues(alpha: 0.28),
                            blurRadius: 10 * scale,
                            offset: Offset(0, 3 * scale),
                          ),
                        ],
                      ),
                      child: _buildPhotoBox(
                        borderRadius: BorderRadius.circular(13.2 * scale),
                        border: Border.all(color: Colors.transparent, width: 0),
                      ),
                    ),
                    SizedBox(width: 18 * scale),
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
                                textColor: const Color(0xFFFED7AA),
                                badgeBg: const Color(0xFF1E2533),
                                borderColor: const Color(0xFFF97316),
                                scale: scale,
                              ),
                            ),
                          const Spacer(),
                          _buildNameWidget(color: Colors.white, scale: scale),
                          SizedBox(height: 2.5 * scale),
                          if (_hasAnyDesignation) ...<Widget>[
                            _buildDesignationWidget(
                              color: const Color(0xFFFB923C),
                              scale: scale,
                            ),
                            SizedBox(height: 5 * scale),
                          ] else
                            SizedBox(height: 4 * scale),
                          // Subtle Titanium/Amber Divider
                          Container(
                            height: 1 * scale,
                            width: 110 * scale,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFF97316), Color(0x11F97316)],
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          _buildContactSection(
                            iconColor: const Color(0xFFFB923C),
                            textColor: const Color(0xFFF1F5F9),
                            addressColor: const Color(0xFF94A3B8),
                            iconBgColor: const Color(0xFF2A3242),
                            iconBorderColor: const Color(0xFF475569),
                            scale: scale,
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
