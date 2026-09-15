// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class CreatorPosterPreview extends StatefulWidget {
  const CreatorPosterPreview({
    super.key,
    this.imageAssetPath,
    this.imageUrl,
    this.imageStoragePath,
    this.thumbnailStoragePath,
    this.thumbnailUrl,
    this.pageConfig,
    this.basePosterBuilder,
    this.videoReplayTickListenable,
    this.preferOriginalPosterQuality = false,
    required this.personalizationConfig,
    required this.viewerPosterProfile,
    required this.language,
    this.partyLogoAssetPath,
    this.politicalProtocolPhotoUrls = const <String>[],
    this.hiddenPoliticalProtocolPhotoUrls = const <String>{},
    this.politicalProtocolLocalPhotoPaths = const <String>[],
    this.politicalProtocolSlotsOverride,
    this.politicalProtocolManualSlots = const <PoliticalProtocolSlot>[],
    this.showPoliticalProtocolOverlay = false,
    this.showProfilePhoto = true,
    this.deferLegacyTextPrime = false,
    this.posterRenderCycle = 0,
    this.photoTapEnabled = false,
    this.interactivePhotoEnabled = false,
    this.photoShapeOverride = '',
    this.photoRenderModeOverride = '',
    this.photoFlipHorizontally = false,
    this.photoXOffsetPercent = 0,
    this.photoYOffsetPercent = 0,
    this.onPhotoTap,
    this.stripGradientTapOffset = 0,
    this.onNameStripTap,
    this.additionalPhotoSelection,
    this.onAdditionalPhotoTap,
    this.onPhotoDragDeltaPercent,
    this.onPhotoDragStateChanged,
    this.onAspectRatioResolved,
    this.onPosterReadyChanged,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final EditorPageConfig? pageConfig;
  final Widget Function(VoidCallback onReady)? basePosterBuilder;
  final ValueListenable<int>? videoReplayTickListenable;
  final bool preferOriginalPosterQuality;
  final CreatorPosterPersonalization personalizationConfig;
  final PosterProfileData viewerPosterProfile;
  final AppLanguage language;
  final String? partyLogoAssetPath;
  final List<String> politicalProtocolPhotoUrls;
  final Set<String> hiddenPoliticalProtocolPhotoUrls;
  final List<String> politicalProtocolLocalPhotoPaths;
  final List<PoliticalProtocolSlot>? politicalProtocolSlotsOverride;
  final List<PoliticalProtocolSlot> politicalProtocolManualSlots;
  final bool showPoliticalProtocolOverlay;
  final bool showProfilePhoto;
  final bool deferLegacyTextPrime;
  final int posterRenderCycle;
  final bool photoTapEnabled;
  final bool interactivePhotoEnabled;
  final String photoShapeOverride;
  final String photoRenderModeOverride;
  final bool photoFlipHorizontally;
  final double photoXOffsetPercent;
  final double photoYOffsetPercent;
  final VoidCallback? onPhotoTap;
  final int stripGradientTapOffset;
  final VoidCallback? onNameStripTap;
  final PosterExtraPhotoSelection? additionalPhotoSelection;
  final VoidCallback? onAdditionalPhotoTap;
  final void Function({
    required double deltaXPercent,
    required double deltaYPercent,
  })?
  onPhotoDragDeltaPercent;
  final ValueChanged<bool>? onPhotoDragStateChanged;
  final ValueChanged<double>? onAspectRatioResolved;
  final ValueChanged<bool>? onPosterReadyChanged;

  @override
  State<CreatorPosterPreview> createState() => CreatorPosterPreviewState();
}

typedef _CreatorPosterPreview = CreatorPosterPreview;

String _normalizePosterStripLayoutStyle(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'split':
    case 'badge':
    case 'full':
      return raw!.trim().toLowerCase();
    default:
      return 'full';
  }
}

typedef _CreatorPosterPreviewState = CreatorPosterPreviewState;

class CreatorPosterPreviewState extends State<CreatorPosterPreview> {
  static const String _visibleTeluguFallbackFontFamily =
      'Anek Telugu Condensed Regular';
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');

  static const List<String> _randomPosterNameFonts = <String>[
    'Pragathi',
    'Brahma',
    'Kranthi',
    'Reshma',
    'Tejafont',
  ];
  static const List<String> _randomEnglishPosterNameFonts = <String>[
    'Montserrat',
    'Oswald',
    'Cinzel',
    'Raleway',
    'Rubik',
  ];

  static const List<Color> _posterStripSolidColors = <Color>[
    Color(0xFF111827),
    Color(0xFF0F172A),
    Color(0xFF064E3B),
    Color(0xFF1E3A8A),
    Color(0xFF581C87),
    Color(0xFF7F1D1D),
    Color(0xFF134E4A),
    Color(0xFF3F1D38),
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
  ];
  static int get posterStripGradientCount => _posterStripSolidColors.length;

  bool _basePosterReady = false;
  int _legacyPrimeGeneration = 0;
  final Map<String, String> _legacyTextOverrides = <String, String>{};
  final Set<String> _legacyTextRequestsInFlight = <String>{};
  Timer? _baseImageReadyFallbackTimer;

  List<String> _politicalProtocolAssetPaths() {
    if (!widget.showPoliticalProtocolOverlay) {
      return const <String>[];
    }
    return widget.politicalProtocolLocalPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _politicalProtocolImageUrls() {
    if (!widget.showPoliticalProtocolOverlay ||
        !widget.personalizationConfig.hasPoliticalProtocolLayout) {
      return const <String>[];
    }
    return widget.politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .take(widget.personalizationConfig.politicalProtocolSlots.length)
        .toList(growable: false);
  }

  Offset? _activePhotoDragLastGlobalPosition;
  int _videoReplayTick = 0;
  double? _resolvedPosterAspectRatio;

  void _scheduleBaseImageReadyFallback() {
    _baseImageReadyFallbackTimer?.cancel();
    _baseImageReadyFallbackTimer = Timer(const Duration(seconds: 12), () {
      _baseImageReadyFallbackTimer = null;
      if (!mounted || _basePosterReady) {
        return;
      }
      _handleBasePosterReady();
    });
  }

  void _handleVideoReplayTick() {
    final nextTick = widget.videoReplayTickListenable?.value ?? 0;
    if (_videoReplayTick == nextTick) {
      return;
    }
    setState(() => _videoReplayTick = nextTick);
  }

  @override
  void initState() {
    super.initState();
    _resolvedPosterAspectRatio = _initialPosterAspectRatio;
    if (!widget.deferLegacyTextPrime) {
      _scheduleLegacyPrime();
    }
    _videoReplayTick = widget.videoReplayTickListenable?.value ?? 0;
    widget.videoReplayTickListenable?.addListener(_handleVideoReplayTick);
    _scheduleBaseImageReadyFallback();
  }

  @override
  void dispose() {
    widget.videoReplayTickListenable?.removeListener(_handleVideoReplayTick);
    _baseImageReadyFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CreatorPosterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoReplayTickListenable !=
        widget.videoReplayTickListenable) {
      oldWidget.videoReplayTickListenable?.removeListener(
        _handleVideoReplayTick,
      );
      _videoReplayTick = widget.videoReplayTickListenable?.value ?? 0;
      widget.videoReplayTickListenable?.addListener(_handleVideoReplayTick);
    }
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageAssetPath != widget.imageAssetPath ||
        oldWidget.imageStoragePath != widget.imageStoragePath ||
        oldWidget.thumbnailStoragePath != widget.thumbnailStoragePath ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.pageConfig != widget.pageConfig ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _basePosterReady = false;
      _resolvedPosterAspectRatio = _initialPosterAspectRatio;
      _scheduleBaseImageReadyFallback();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _emitPosterReadyChanged();
        }
      });
    }
    if (oldWidget.viewerPosterProfile != widget.viewerPosterProfile ||
        oldWidget.language != widget.language ||
        oldWidget.personalizationConfig != widget.personalizationConfig ||
        oldWidget.stripGradientTapOffset != widget.stripGradientTapOffset ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      if (!widget.deferLegacyTextPrime) {
        _scheduleLegacyPrime();
      }
    }
    if (oldWidget.deferLegacyTextPrime && !widget.deferLegacyTextPrime) {
      _scheduleLegacyPrime();
    }
  }

  double? get _initialPosterAspectRatio {
    final pageConfig = widget.pageConfig;
    if (pageConfig != null &&
        pageConfig.widthPx > 0 &&
        pageConfig.heightPx > 0) {
      return pageConfig.aspectRatio;
    }
    return null;
  }

  void _scheduleLegacyPrime() {
    if (widget.deferLegacyTextPrime) {
      _emitPosterReadyChanged();
      return;
    }
    final generation = ++_legacyPrimeGeneration;
    if (!_needsLegacyTextPrimeForCurrentState()) {
      _emitPosterReadyChanged();
      return;
    }
    _emitPosterReadyChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final updates = await _primeLegacyTextCacheForCurrentState().timeout(
          const Duration(seconds: 15),
          onTimeout: () => const <String, String>{},
        );
        if (!mounted || generation != _legacyPrimeGeneration) {
          return;
        }
        if (updates.isNotEmpty) {
          setState(() {
            _legacyTextOverrides.addAll(updates);
          });
        }
      } catch (_) {
        if (!mounted || generation != _legacyPrimeGeneration) {
          return;
        }
      }
      _emitPosterReadyChanged();
    });
  }

  void _emitPosterReadyChanged() {
    widget.onPosterReadyChanged?.call(_basePosterReady);
  }

  void _handleBasePosterReady() {
    if (_basePosterReady || !mounted) {
      return;
    }
    _baseImageReadyFallbackTimer?.cancel();
    _baseImageReadyFallbackTimer = null;
    setState(() => _basePosterReady = true);
    _emitPosterReadyChanged();
  }

  void _handlePosterAspectRatioResolved(double aspectRatio) {
    if (!mounted || aspectRatio <= 0) {
      return;
    }
    final existing = _resolvedPosterAspectRatio;
    if (existing != null && (existing - aspectRatio).abs() < 0.001) {
      return;
    }
    setState(() => _resolvedPosterAspectRatio = aspectRatio);
    widget.onAspectRatioResolved?.call(aspectRatio);
  }

  void _startPhotoDrag(Offset globalPosition) {
    _activePhotoDragLastGlobalPosition = globalPosition;
    widget.onPhotoDragStateChanged?.call(true);
  }

  void _updatePhotoDrag({
    required Offset globalPosition,
    required double currentLeft,
    required double currentTop,
    required double maxWidth,
    required double totalCanvasHeight,
    required double photoWidth,
    required double photoHeight,
  }) {
    final previousGlobalPosition = _activePhotoDragLastGlobalPosition;
    _activePhotoDragLastGlobalPosition = globalPosition;
    if (previousGlobalPosition == null) {
      return;
    }
    final delta = globalPosition - previousGlobalPosition;
    final clampedLeft = (currentLeft + delta.dx).clamp(
      0.0,
      math.max(0.0, maxWidth - photoWidth),
    );
    final clampedTop = (currentTop + delta.dy).clamp(
      0.0,
      math.max(0.0, totalCanvasHeight - photoHeight),
    );
    final appliedDeltaX = clampedLeft - currentLeft;
    final appliedDeltaY = clampedTop - currentTop;
    if (appliedDeltaX == 0 && appliedDeltaY == 0) {
      return;
    }
    widget.onPhotoDragDeltaPercent?.call(
      deltaXPercent: (appliedDeltaX / maxWidth) * 100,
      deltaYPercent: (appliedDeltaY / totalCanvasHeight) * 100,
    );
  }

  void _endPhotoDrag() {
    _activePhotoDragLastGlobalPosition = null;
    widget.onPhotoDragStateChanged?.call(false);
  }

  String _resolvePosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + widget.stripGradientTapOffset) %
        _randomPosterNameFonts.length;
    return _randomPosterNameFonts[index];
  }

  Color _resolvePosterStripColor(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|$resolvedName';
    var hash = 23;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 41 * hash + codeUnit;
    }
    final baseIndex = hash.abs() % _posterStripSolidColors.length;
    final resolvedIndex =
        (baseIndex + widget.stripGradientTapOffset) %
        _posterStripSolidColors.length;
    return _posterStripSolidColors[resolvedIndex];
  }

  Color _onStripColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF111827);
  }

  Color _mutedOnStripColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF334155);
  }

  String _resolveEnglishPosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${widget.imageUrl ?? widget.imageAssetPath ?? 'poster'}'
        '|english|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + widget.stripGradientTapOffset) %
        _randomEnglishPosterNameFonts.length;
    return _randomEnglishPosterNameFonts[index];
  }

  String? _resolveDisplayNameFontFamily(String text) {
    if (_teluguTextPattern.hasMatch(text)) {
      final family = _resolvePosterNameFontFamily(text);
      if (family.toLowerCase().contains('pallavi')) {
        return 'Pragathi';
      }
      return family;
    }
    if (_latinTextPattern.hasMatch(text)) {
      return _resolveEnglishPosterNameFontFamily(text);
    }
    return null;
  }

  String _resolveDesignationFontFamily(String text) {
    if (_teluguTextPattern.hasMatch(text)) {
      return 'Pallavi Medium';
    }
    if (_latinTextPattern.hasMatch(text)) {
      return 'Montserrat';
    }
    return 'Poppins';
  }

  bool _isEnglishOnlyText(String text) {
    return !_teluguTextPattern.hasMatch(text) &&
        _latinTextPattern.hasMatch(text);
  }

  bool _isMixedTeluguAndLatinText(String text) {
    return _teluguTextPattern.hasMatch(text) &&
        _latinTextPattern.hasMatch(text);
  }

  bool _isTeluguCodeUnit(int codeUnit) {
    return codeUnit >= 0x0C00 && codeUnit <= 0x0C7F;
  }

  TextSpan _mixedLegacyTextSpan({
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
          ? (_legacyOverrideFor(raw, legacyFontFamily) ?? raw)
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

  Widget _buildNameDesignationSeparator({
    required Color fallbackColor,
    double fallbackWidth = 1.5,
    double fallbackHeight = 18,
  }) {
    final logoPath = widget.partyLogoAssetPath?.trim();
    if (_showPartyLogoInNameChip || logoPath == null || logoPath.isEmpty) {
      return Container(
        width: fallbackWidth,
        height: fallbackHeight,
        decoration: BoxDecoration(
          color: fallbackColor,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    final logo = logoPath.toLowerCase().endsWith('.svg')
        ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
        : Image.asset(
            logoPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(color: fallbackColor),
          );

    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(child: logo),
    );
  }

  bool get _showPartyLogoInNameChip {
    final logoPath = widget.partyLogoAssetPath?.trim();
    return logoPath != null && logoPath.isNotEmpty;
  }

  Widget _buildPartyLogoForNameChip({double size = 24}) {
    final logoPath = widget.partyLogoAssetPath!.trim();
    final lower = logoPath.toLowerCase();
    final isNetwork =
        lower.startsWith('https://') || lower.startsWith('http://');
    final isSvg = lower.endsWith('.svg') || lower.contains('.svg?');
    final fallback = Icon(
      Icons.flag_rounded,
      color: const Color(0xFF64748B),
      size: (size * 0.56).clamp(12.0, 20.0),
    );
    final logo = isNetwork
        ? (isSvg
              ? SvgPicture.network(
                  logoPath,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => fallback,
                )
              : CachedNetworkImage(
                  imageUrl: logoPath,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ))
        : (isSvg
              ? SvgPicture.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => fallback,
                )
              : Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => fallback,
                ));

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all((size * 0.035).clamp(0.5, 1.2)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: (size * 0.018).clamp(0.4, 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(child: logo),
    );
  }

  Widget _buildNameWithOptionalPartyLogo({
    required Widget name,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    double logoSize = 24,
    double gap = 6,
  }) {
    if (!_showPartyLogoInNameChip) {
      return name;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: <Widget>[
        _buildPartyLogoForNameChip(size: logoSize),
        SizedBox(width: gap),
        Flexible(child: name),
      ],
    );
  }

  double _nameChipPartyLogoSize(double stripPixelHeight) {
    return (stripPixelHeight * 0.92).clamp(24.0, 64.0).toDouble();
  }

  Widget _buildEnglishBusinessStrip({
    required String resolvedName,
    required String resolvedDesignation,
    required String? displayNameFontFamily,
    required String designationFontFamily,
    required Color stripTextColor,
    required Color mutedStripTextColor,
    required bool showPhoneInStrip,
    required String resolvedPhone,
    double partyLogoSize = 28,
  }) {
    final hasDesignation = resolvedDesignation.isNotEmpty;
    if (!hasDesignation && !showPhoneInStrip) {
      return Center(
        child: _buildNameWithOptionalPartyLogo(
          logoSize: partyLogoSize,
          name: _legacyAwareText(
            text: resolvedName,
            fontFamily: displayNameFontFamily,
            maxLines: 1,
            textAlign: TextAlign.center,
            fitToWidth: true,
            style: TextStyle(
              color: stripTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              height: 1.0,
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              if (_showPartyLogoInNameChip) ...<Widget>[
                _buildPartyLogoForNameChip(size: partyLogoSize),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: _legacyAwareText(
                  text: resolvedName,
                  fontFamily: displayNameFontFamily,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  fitToWidth: true,
                  style: TextStyle(
                    color: stripTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    height: 1.0,
                  ),
                ),
              ),
              if (hasDesignation) ...<Widget>[
                const SizedBox(width: 8),
                _buildNameDesignationSeparator(
                  fallbackColor: mutedStripTextColor,
                  fallbackWidth: 1.4,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _legacyAwareText(
                    text: resolvedDesignation,
                    fontFamily: designationFontFamily,
                    maxLines: 1,
                    textAlign: TextAlign.left,
                    fitToWidth: true,
                    style: TextStyle(
                      color: mutedStripTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showPhoneInStrip) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            width: 2,
            height: 30,
            decoration: BoxDecoration(
              color: mutedStripTextColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 82),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  resolvedPhone,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: mutedStripTextColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldConvertForLegacyTelugu(String text, String? fontFamily) {
    return fontFamily != null &&
        _teluguTextPattern.hasMatch(text) &&
        !_isMixedTeluguAndLatinText(text) &&
        (_randomPosterNameFonts.contains(fontFamily) ||
            fontFamily == 'Pallavi Medium' ||
            fontFamily == 'Pallavi Bold');
  }

  bool _usesLegacyTeluguStripFont(String text, String? fontFamily) {
    return _shouldConvertForLegacyTelugu(text, fontFamily);
  }

  String _legacyTextCacheKey(String text, String fontFamily) {
    return '$fontFamily::$text';
  }

  String? _legacyOverrideFor(String text, String? fontFamily) {
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        fontFamily == null) {
      return null;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    return _legacyTextOverrides[key] ??
        TeluguLegacyTextService.cachedValue(text, fontFamily: fontFamily) ??
        TeluguLegacyTextService.convertSync(text, fontFamily: fontFamily);
  }

  bool _needsLegacyTextPrimeForCurrentState() {
    final resolvedName = widget.viewerPosterProfile.resolvedName(
      language: widget.language,
    );
    final isBusinessProfile =
        widget.viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final primaryDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : widget.viewerPosterProfile.secondaryPersonalDesignation;
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final primaryDesignationFontFamily = _resolveDesignationFontFamily(
      primaryDesignation,
    );
    final secondaryDesignationFontFamily = _resolveDesignationFontFamily(
      secondaryDesignation,
    );
    return _legacyTextNeedsAsyncPrime(resolvedName, displayNameFontFamily) ||
        _legacyTextNeedsAsyncPrime(
          primaryDesignation,
          primaryDesignationFontFamily,
        ) ||
        (secondaryDesignation.isNotEmpty &&
            _legacyTextNeedsAsyncPrime(
              secondaryDesignation,
              secondaryDesignationFontFamily,
            ));
  }

  bool _legacyTextNeedsAsyncPrime(String text, String? fontFamily) {
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        fontFamily == null ||
        text.trim().isEmpty) {
      return false;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    if (_legacyTextOverrides.containsKey(key)) {
      return false;
    }
    final cached = TeluguLegacyTextService.cachedValue(
      text,
      fontFamily: fontFamily,
    );
    if (cached != null && cached.isNotEmpty) {
      return false;
    }
    return !_legacyTextRequestsInFlight.contains(key);
  }

  Future<MapEntry<String, String>?> _primeLegacyTextValue(
    String text,
    String? fontFamily,
  ) async {
    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        fontFamily == null ||
        text.trim().isEmpty) {
      return null;
    }
    final key = _legacyTextCacheKey(text, fontFamily);
    final cached = TeluguLegacyTextService.cachedValue(
      text,
      fontFamily: fontFamily,
    );
    if (cached != null && cached.isNotEmpty) {
      return null;
    }
    if (_legacyTextRequestsInFlight.contains(key)) {
      return null;
    }
    _legacyTextRequestsInFlight.add(key);
    try {
      final converted = await TeluguLegacyTextService.convert(
        text,
        fontFamily: fontFamily,
      );
      if (converted != null &&
          converted.isNotEmpty &&
          _legacyTextOverrides[key] != converted) {
        return MapEntry<String, String>(key, converted);
      }
      return null;
    } finally {
      _legacyTextRequestsInFlight.remove(key);
    }
  }

  Future<Map<String, String>> _primeLegacyTextCacheForCurrentState() async {
    final resolvedName = widget.viewerPosterProfile.resolvedName(
      language: widget.language,
    );
    final isBusinessProfile =
        widget.viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final primaryDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : widget.viewerPosterProfile.secondaryPersonalDesignation;
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final entries = await Future.wait<MapEntry<String, String>?>(
      <Future<MapEntry<String, String>?>>[
        _primeLegacyTextValue(resolvedName, displayNameFontFamily),
        _primeLegacyTextValue(
          primaryDesignation,
          _resolveDesignationFontFamily(primaryDesignation),
        ),
        if (secondaryDesignation.isNotEmpty)
          _primeLegacyTextValue(
            secondaryDesignation,
            _resolveDesignationFontFamily(secondaryDesignation),
          ),
      ],
    );
    final updates = <String, String>{};
    for (final entry in entries) {
      if (entry != null) {
        updates[entry.key] = entry.value;
      }
    }
    return updates;
  }

  Widget _legacyAwareText({
    required String text,
    required TextStyle style,
    required String? fontFamily,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.center,
    bool fitToWidth = false,
  }) {
    Widget buildText(String value, {String? resolvedFontFamily}) {
      final effectiveFontFamily = resolvedFontFamily ?? fontFamily;
      final mixed = _isMixedTeluguAndLatinText(value) && fontFamily != null;
      final textWidget = mixed
          ? RichText(
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              text: _mixedLegacyTextSpan(
                text: value,
                baseStyle: style,
                legacyFontFamily: fontFamily,
                latinFontFamily: _resolveEnglishPosterNameFontFamily(value),
              ),
            )
          : Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: style.copyWith(fontFamily: effectiveFontFamily),
            );
      if (!fitToWidth) {
        return textWidget;
      }
      final fitAlignment = switch (textAlign) {
        TextAlign.left || TextAlign.start => Alignment.centerLeft,
        TextAlign.right || TextAlign.end => Alignment.centerRight,
        _ => Alignment.center,
      };
      return SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: fitAlignment,
          child: textWidget,
        ),
      );
    }

    if (!_shouldConvertForLegacyTelugu(text, fontFamily) ||
        text.trim().isEmpty) {
      return buildText(text);
    }
    final override = _legacyOverrideFor(text, fontFamily);
    if (override != null && override.isNotEmpty) {
      return buildText(override);
    }
    return buildText(
      text,
      resolvedFontFamily: _visibleTeluguFallbackFontFamily,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBusinessIdentity =
        widget.viewerPosterProfile.identityMode ==
            PosterIdentityMode.business &&
        widget.viewerPosterProfile.activeName.trim().isNotEmpty;
    final hasPersonalIdentity =
        widget.viewerPosterProfile.photoPath.trim().isNotEmpty ||
        widget.viewerPosterProfile.photoUrl.trim().isNotEmpty ||
        widget.viewerPosterProfile.originalPhotoPath.trim().isNotEmpty ||
        widget.viewerPosterProfile.originalPhotoUrl.trim().isNotEmpty;
    final shouldShowIdentityVisual = hasBusinessIdentity || hasPersonalIdentity;
    final resolvedName = widget.viewerPosterProfile.resolvedName(
      language: widget.language,
    );
    final isBusinessProfile =
        widget.viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final primaryDesignation = isBusinessProfile
        ? widget.viewerPosterProfile.businessTagline.trim()
        : widget.viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : widget.viewerPosterProfile.secondaryPersonalDesignation;
    final resolvedDesignation = primaryDesignation.isNotEmpty
        ? primaryDesignation
        : secondaryDesignation;
    final resolvedPhone = isBusinessProfile
        ? widget.viewerPosterProfile.activeWhatsappNumber.trim()
        : '';
    final isTeluguName = _teluguTextPattern.hasMatch(resolvedName);
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final usesLegacyTeluguNameFont = _usesLegacyTeluguStripFont(
      resolvedName,
      displayNameFontFamily,
    );
    final nameScaleFactor = (widget.personalizationConfig.nameScale / 100)
        .clamp(0.45, 1.6);
    final designationScaleFactor =
        (widget.personalizationConfig.designationScale / 100).clamp(0.45, 1.6);
    final legacyTeluguNameBoost = usesLegacyTeluguNameFont ? 1.52 : 1.0;
    final personalNameFontSize =
        (isTeluguName ? 46.0 : 40.0) * nameScaleFactor * legacyTeluguNameBoost;
    final personalNameLineHeight = usesLegacyTeluguNameFont
        ? 0.94
        : (isTeluguName ? 0.82 : 0.95);
    final businessNameFontSize =
        (isTeluguName ? 36.0 : 30.0) * nameScaleFactor * legacyTeluguNameBoost;
    final designationFontFamily = _resolveDesignationFontFamily(
      resolvedDesignation,
    );
    final secondaryDesignationFontFamily = _resolveDesignationFontFamily(
      secondaryDesignation,
    );
    final usesLegacyTeluguDesignationFont = _usesLegacyTeluguStripFont(
      resolvedDesignation,
      designationFontFamily,
    );
    final usesLegacyTeluguSecondaryDesignationFont = _usesLegacyTeluguStripFont(
      secondaryDesignation,
      secondaryDesignationFontFamily,
    );
    final legacyTeluguDesignationBoost =
        (usesLegacyTeluguDesignationFont ||
            usesLegacyTeluguSecondaryDesignationFont)
        ? 1.10
        : 1.0;
    final personalDesignationFontSize =
        23.0 * designationScaleFactor * legacyTeluguDesignationBoost;
    final businessDesignationFontSize =
        21.0 * designationScaleFactor * legacyTeluguDesignationBoost;
    final englishDesignationFontSize = 18.0 * designationScaleFactor;
    final englishPersonalNameFontSize = 30.0 * nameScaleFactor;
    final englishSplitNameFontSize = 28.0 * nameScaleFactor;
    final showPhoneInStrip = isBusinessProfile && resolvedPhone.isNotEmpty;
    const stripOverflowAllowance = 0.0;

    final showPhotoOverlay = _basePosterReady;
    final shouldShowBottomStrip =
        widget.personalizationConfig.showBottomStrip &&
        (widget.basePosterBuilder == null || _basePosterReady);

    Widget buildBottomStrip({
      required double stripScale,
      required double bottomStripPadding,
      required double stripPixelHeight,
    }) {
      return _buildPosterBottomStrip(
        resolvedName: resolvedName,
        resolvedDesignation: resolvedDesignation,
        resolvedSecondaryDesignation: secondaryDesignation,
        displayNameFontFamily: displayNameFontFamily,
        designationFontFamily: designationFontFamily,
        secondaryDesignationFontFamily: secondaryDesignationFontFamily,
        isBusinessProfile: isBusinessProfile,
        isTeluguName: isTeluguName,
        businessNameFontSize: businessNameFontSize * stripScale,
        personalNameFontSize: personalNameFontSize * stripScale,
        personalDesignationFontSize: personalDesignationFontSize * stripScale,
        businessDesignationFontSize: businessDesignationFontSize * stripScale,
        englishDesignationFontSize: englishDesignationFontSize * stripScale,
        englishPersonalNameFontSize: englishPersonalNameFontSize * stripScale,
        englishSplitNameFontSize: englishSplitNameFontSize * stripScale,
        personalNameLineHeight: personalNameLineHeight,
        showPhoneInStrip: showPhoneInStrip,
        resolvedPhone: resolvedPhone,
        bottomStripPadding: bottomStripPadding,
        stripPixelHeight: stripPixelHeight,
      );
    }

    Widget buildPosterVisual() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio =
              widget.pageConfig?.aspectRatio ?? _resolvedPosterAspectRatio;
          final visualWidth =
              aspectRatio != null &&
                  constraints.maxHeight.isFinite &&
                  constraints.maxHeight > 0
              ? math.min(
                  constraints.maxWidth,
                  constraints.maxHeight * aspectRatio,
                )
              : constraints.maxWidth;
          final visualHeight = aspectRatio != null && aspectRatio > 0
              ? visualWidth / aspectRatio
              : constraints.maxHeight;
          final visualLeft = math.max(
            0.0,
            (constraints.maxWidth - visualWidth) / 2,
          );
          final configuredStripHeightRatio =
              (widget.personalizationConfig.stripHeight * 0.5) / 100;
          final stripPixelHeight = math
              .max(1.0, visualHeight * configuredStripHeightRatio)
              .toDouble();
          final defaultStripReferenceHeight = math
              .max(1.0, visualHeight * (16 * 0.5 / 100))
              .toDouble();
          final stripScale = (stripPixelHeight / defaultStripReferenceHeight)
              .clamp(0.1, 3.0)
              .toDouble();
          final scaledBottomStripPadding = (stripPixelHeight * 0.04)
              .clamp(0.0, 6.0)
              .toDouble();
          final stripWidthPercent = widget.personalizationConfig.stripWidth
              .clamp(20.0, 100.0)
              .toDouble();
          final stripWidthPx = visualWidth * (stripWidthPercent / 100);
          final stripCenterX = widget.personalizationConfig.stripX
              .clamp(stripWidthPercent / 2, 100 - (stripWidthPercent / 2))
              .toDouble();
          final stripLeft =
              visualLeft +
              (visualWidth * (stripCenterX / 100)) -
              (stripWidthPx / 2);
          final stripBottomPx =
              visualHeight *
              (widget.personalizationConfig.stripBottom.clamp(0.0, 50.0) / 100);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              if (widget.basePosterBuilder != null && widget.pageConfig != null)
                AspectRatio(
                  aspectRatio: widget.pageConfig!.aspectRatio,
                  child: widget.basePosterBuilder!(_handleBasePosterReady),
                )
              else if (widget.basePosterBuilder != null)
                widget.basePosterBuilder!(_handleBasePosterReady)
              else if (widget.pageConfig != null)
                _ResolvedTemplatePosterImage(
                  imageAssetPath: widget.imageAssetPath,
                  imageUrl: widget.imageUrl ?? '',
                  imageStoragePath: widget.imageStoragePath,
                  thumbnailStoragePath: widget.thumbnailStoragePath,
                  thumbnailUrl: widget.thumbnailUrl,
                  fixedAspectRatio: _resolvedPosterAspectRatio,
                  preferOriginalPosterQuality:
                      widget.preferOriginalPosterQuality,
                  onAspectRatioResolved: _handlePosterAspectRatioResolved,
                  onFirstFrameReady: _handleBasePosterReady,
                )
              else
                _ResolvedTemplatePosterImage(
                  imageAssetPath: widget.imageAssetPath,
                  imageUrl: widget.imageUrl ?? '',
                  imageStoragePath: widget.imageStoragePath,
                  thumbnailStoragePath: widget.thumbnailStoragePath,
                  thumbnailUrl: widget.thumbnailUrl,
                  preferOriginalPosterQuality:
                      widget.preferOriginalPosterQuality,
                  onAspectRatioResolved: _handlePosterAspectRatioResolved,
                  onFirstFrameReady: _handleBasePosterReady,
                ),
              if (widget.showPoliticalProtocolOverlay &&
                  (_politicalProtocolImageUrls().isNotEmpty ||
                      _politicalProtocolAssetPaths().isNotEmpty))
                Positioned(
                  left: visualLeft,
                  top: 0,
                  width: visualWidth,
                  height: visualHeight,
                  child: IgnorePointer(
                    child: _PoliticalProtocolPhotoSlots(
                      assetPaths: _politicalProtocolAssetPaths(),
                      imageUrls: _politicalProtocolImageUrls(),
                      hiddenImageUrls: widget.hiddenPoliticalProtocolPhotoUrls,
                      slots:
                          widget.politicalProtocolSlotsOverride ??
                          widget.personalizationConfig.politicalProtocolSlots,
                      assetSlots: widget.politicalProtocolManualSlots,
                    ),
                  ),
                ),
              if (widget.showProfilePhoto && shouldShowIdentityVisual)
                Positioned(
                  left: visualLeft,
                  top: 0,
                  width: visualWidth,
                  height: math.max(
                    1.0,
                    constraints.maxHeight + stripOverflowAllowance,
                  ),
                  child: Offstage(
                    offstage: !showPhotoOverlay,
                    child: IgnorePointer(
                      ignoring: !showPhotoOverlay,
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final photoScale =
                              widget.personalizationConfig.photoScale / 100;
                          final baseImageHeight = math.max(
                            1.0,
                            constraints.maxHeight,
                          );
                          final totalCanvasHeight = math.max(
                            1.0,
                            constraints.maxHeight,
                          );
                          final visualScale = isBusinessProfile
                              ? photoScale * 0.72
                              : photoScale;
                          final effectivePhotoShape = isBusinessProfile
                              ? 'circle'
                              : (widget.photoShapeOverride.trim().isNotEmpty
                                    ? widget.photoShapeOverride.trim()
                                    : (widget
                                              .viewerPosterProfile
                                              .preferOriginalPersonalPhoto
                                          ? 'circle'
                                          : widget
                                                .personalizationConfig
                                                .photoShape));
                          final effectivePhotoRenderMode = isBusinessProfile
                              ? 'original'
                              : (widget.photoRenderModeOverride
                                        .trim()
                                        .isNotEmpty
                                    ? widget.photoRenderModeOverride.trim()
                                    : (widget
                                              .viewerPosterProfile
                                              .preferOriginalPersonalPhoto
                                          ? 'original'
                                          : widget
                                                .personalizationConfig
                                                .photoRenderMode));
                          final maskAspectRatio = _photoMaskAspectRatio(
                            effectivePhotoShape,
                          );
                          final additionalPhotoProfile = widget
                              .additionalPhotoSelection
                              ?.asPosterProfileData();
                          final showAdditionalPhotoSlot =
                              widget.personalizationConfig.showVideoExtraPhoto;
                          final additionalPhotoShape =
                              widget.personalizationConfig.videoExtraPhotoShape;
                          final additionalPhotoRenderMode = widget
                              .personalizationConfig
                              .videoExtraPhotoRenderMode;
                          final additionalPhotoWidth =
                              constraints.maxWidth *
                              (widget
                                      .personalizationConfig
                                      .videoExtraPhotoScale /
                                  100);
                          final additionalPhotoHeight =
                              additionalPhotoWidth /
                              _photoMaskAspectRatio(additionalPhotoShape);
                          final additionalPhotoLeft =
                              (constraints.maxWidth *
                                  (widget
                                          .personalizationConfig
                                          .videoExtraPhotoX /
                                      100)) -
                              (additionalPhotoWidth / 2);
                          final additionalPhotoTop =
                              (baseImageHeight *
                                  (widget
                                          .personalizationConfig
                                          .videoExtraPhotoY /
                                      100)) -
                              (additionalPhotoHeight / 2);
                          final width = constraints.maxWidth * visualScale;
                          final height = width / maskAspectRatio;
                          final left =
                              (constraints.maxWidth *
                                  (widget.personalizationConfig.photoX / 100)) -
                              (width / 2) +
                              (constraints.maxWidth *
                                  (widget.photoXOffsetPercent / 100));
                          final top =
                              (baseImageHeight *
                                  (widget.personalizationConfig.photoY / 100)) -
                              (height / 2) +
                              (totalCanvasHeight *
                                  (widget.photoYOffsetPercent / 100));
                          Widget animatedOverlay({
                            required Widget child,
                            required String animation,
                            required double overlayWidth,
                            required double overlayHeight,
                          }) {
                            final normalizedAnimation = animation
                                .trim()
                                .toLowerCase();
                            return TweenAnimationBuilder<double>(
                              key: ValueKey<String>(
                                '$normalizedAnimation-$overlayWidth-$overlayHeight-$_videoReplayTick',
                              ),
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1150),
                              curve: Curves.easeOutCubic,
                              builder: (context, progress, child) {
                                var offset = Offset.zero;
                                var scale = 1.0;
                                switch (normalizedAnimation) {
                                  case 'top_to_place':
                                    offset = Offset(
                                      0,
                                      (-baseImageHeight - overlayHeight) *
                                          (1 - progress),
                                    );
                                    break;
                                  case 'bottom_to_place':
                                    offset = Offset(
                                      0,
                                      (baseImageHeight + overlayHeight) *
                                          (1 - progress),
                                    );
                                    break;
                                  case 'left_to_place':
                                    offset = Offset(
                                      (-constraints.maxWidth - overlayWidth) *
                                          (1 - progress),
                                      0,
                                    );
                                    break;
                                  case 'right_to_place':
                                    offset = Offset(
                                      (constraints.maxWidth + overlayWidth) *
                                          (1 - progress),
                                      0,
                                    );
                                    break;
                                  case 'zoom_in':
                                    scale = 0.22 + (0.78 * progress);
                                    break;
                                  case 'zoom_out':
                                    scale = 1.35 - (0.35 * progress);
                                    break;
                                }
                                return Transform.translate(
                                  offset: offset,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          }

                          return Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned(
                                left: left,
                                top: top,
                                width: width,
                                height: height,
                                child: animatedOverlay(
                                  animation: widget
                                      .personalizationConfig
                                      .photoAnimation,
                                  overlayWidth: width,
                                  overlayHeight: height,
                                  child: RawGestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    gestures: <Type, GestureRecognizerFactory>{
                                      TapGestureRecognizer:
                                          GestureRecognizerFactoryWithHandlers<
                                            TapGestureRecognizer
                                          >(TapGestureRecognizer.new, (
                                            TapGestureRecognizer instance,
                                          ) {
                                            instance.onTap =
                                                widget.photoTapEnabled
                                                ? widget.onPhotoTap
                                                : null;
                                          }),
                                      LongPressGestureRecognizer:
                                          GestureRecognizerFactoryWithHandlers<
                                            LongPressGestureRecognizer
                                          >(
                                            () => LongPressGestureRecognizer(
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                            (
                                              LongPressGestureRecognizer
                                              instance,
                                            ) {
                                              if (!widget
                                                  .interactivePhotoEnabled) {
                                                instance
                                                  ..onLongPressStart = null
                                                  ..onLongPressMoveUpdate = null
                                                  ..onLongPressEnd = null
                                                  ..onLongPressCancel = null;
                                                return;
                                              }
                                              instance.onLongPressStart =
                                                  (
                                                    LongPressStartDetails
                                                    details,
                                                  ) => _startPhotoDrag(
                                                    details.globalPosition,
                                                  );
                                              instance.onLongPressMoveUpdate =
                                                  (
                                                    LongPressMoveUpdateDetails
                                                    details,
                                                  ) => _updatePhotoDrag(
                                                    globalPosition:
                                                        details.globalPosition,
                                                    currentLeft: left,
                                                    currentTop: top,
                                                    maxWidth:
                                                        constraints.maxWidth,
                                                    totalCanvasHeight:
                                                        totalCanvasHeight,
                                                    photoWidth: width,
                                                    photoHeight: height,
                                                  );
                                              instance.onLongPressEnd =
                                                  (LongPressEndDetails _) =>
                                                      _endPhotoDrag();
                                              instance.onLongPressCancel =
                                                  _endPhotoDrag;
                                            },
                                          ),
                                    },
                                    child: _PhotoShapeFrame(
                                      shape: effectivePhotoShape,
                                      edgeStyle: widget
                                          .personalizationConfig
                                          .edgeStyle,
                                      photoRenderMode: effectivePhotoRenderMode,
                                      isBusinessLogo: isBusinessProfile,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..scaleByDouble(
                                            widget.photoFlipHorizontally &&
                                                    !isBusinessProfile
                                                ? -1
                                                : 1,
                                            1,
                                            1,
                                            1,
                                          ),
                                        child: PosterIdentityVisual(
                                          profile: widget.viewerPosterProfile,
                                          fit: isBusinessProfile
                                              ? BoxFit.contain
                                              : effectivePhotoRenderMode ==
                                                    'cutout'
                                              ? BoxFit.contain
                                              : BoxFit.cover,
                                          preferOriginalPersonalPhoto:
                                              effectivePhotoRenderMode ==
                                                  'original' ||
                                              widget
                                                  .viewerPosterProfile
                                                  .preferOriginalPersonalPhoto,
                                          allowOriginalFallbackWhenCutoutUnavailable:
                                              true,
                                          textScale:
                                              widget
                                                      .viewerPosterProfile
                                                      .identityMode ==
                                                  PosterIdentityMode.business
                                              ? 0.84
                                              : 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (showAdditionalPhotoSlot)
                                Positioned(
                                  left: additionalPhotoLeft,
                                  top: additionalPhotoTop,
                                  width: additionalPhotoWidth,
                                  height: additionalPhotoHeight,
                                  child: GestureDetector(
                                    onTap: widget.onAdditionalPhotoTap,
                                    behavior: HitTestBehavior.opaque,
                                    child: animatedOverlay(
                                      animation: widget
                                          .personalizationConfig
                                          .videoExtraPhotoAnimation,
                                      overlayWidth: additionalPhotoWidth,
                                      overlayHeight: additionalPhotoHeight,
                                      child: additionalPhotoProfile != null
                                          ? _PhotoShapeFrame(
                                              shape: additionalPhotoShape,
                                              edgeStyle: widget
                                                  .personalizationConfig
                                                  .videoExtraPhotoEdgeStyle,
                                              photoRenderMode:
                                                  additionalPhotoRenderMode,
                                              isBusinessLogo: false,
                                              child: PosterIdentityVisual(
                                                profile: additionalPhotoProfile,
                                                fit:
                                                    additionalPhotoRenderMode ==
                                                        'cutout'
                                                    ? BoxFit.contain
                                                    : BoxFit.cover,
                                                preferOriginalPersonalPhoto:
                                                    additionalPhotoRenderMode ==
                                                    'original',
                                                allowOriginalFallbackWhenCutoutUnavailable:
                                                    true,
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withValues(
                                                  alpha: 0.34,
                                                ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2.5,
                                                ),
                                                boxShadow: <BoxShadow>[
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.22,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        const Icon(
                                                          Icons
                                                              .add_a_photo_rounded,
                                                          color: Colors.white,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          context.strings.localized(
                                                            telugu:
                                                                'ఫోటో జోడించండి',
                                                            english:
                                                                'Add Photo',
                                                            hindi:
                                                                'फ़ोटो जोड़ें',
                                                            tamil:
                                                                'புகைப்படம் சேர்க்கவும்',
                                                            kannada:
                                                                'ಫೋಟೋ ಸೇರಿಸಿ',
                                                            malayalam:
                                                                'ഫോട്ടോ ചേർക്കുക',
                                                            marathi:
                                                                'फोटो जोडा',
                                                            gujarati:
                                                                'ફોટો ઉમેરો',
                                                            bengali:
                                                                'ফটো যোগ করুন',
                                                            punjabi:
                                                                'ਫੋਟੋ ਸ਼ਾਮਲ ਕਰੋ',
                                                            odia:
                                                                'ଫଟୋ ଯୋଡ଼ନ୍ତୁ',
                                                            assamese:
                                                                'ফটো যোগ কৰক',
                                                            konkani:
                                                                'फोटो जोडा',
                                                            nepali:
                                                                'तस्विर थप्नुहोस्',
                                                            meitei:
                                                                'ফোতো হাপচিনবীয়ু',
                                                            mizo:
                                                                'Thlalak dah rawh',
                                                            kashmiri:
                                                                'فوٹو رَلاوِو',
                                                            ladakhi: 'པར་སྣོན།',
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                height: 1.05,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              if (!widget.personalizationConfig.showBottomStrip)
                                Positioned(
                                  left:
                                      constraints.maxWidth *
                                      (widget.personalizationConfig.nameX /
                                          100),
                                  top:
                                      constraints.maxHeight *
                                      (widget.personalizationConfig.nameY /
                                          100),
                                  child: Transform.translate(
                                    offset: const Offset(-80, -16),
                                    child: SizedBox(
                                      width: 160,
                                      child: _legacyAwareText(
                                        text: resolvedName,
                                        fontFamily: displayNameFontFamily,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          shadows: const <Shadow>[
                                            Shadow(
                                              color: Color(0xCC000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              if (shouldShowBottomStrip)
                Positioned(
                  left: stripLeft,
                  width: stripWidthPx,
                  bottom: stripBottomPx,
                  child: SizedBox(
                    height: stripPixelHeight,
                    child: buildBottomStrip(
                      stripScale: stripScale,
                      bottomStripPadding: scaledBottomStripPadding,
                      stripPixelHeight: stripPixelHeight,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    Widget buildFramedPoster() {
      return ClipRect(child: buildPosterVisual());
    }

    final posterAspectRatio = _resolvedPosterAspectRatio;
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: posterAspectRatio != null
            ? AspectRatio(
                aspectRatio: posterAspectRatio,
                child: buildFramedPoster(),
              )
            : buildFramedPoster(),
      ),
    );
  }

  Widget _buildPosterBottomStrip({
    required String resolvedName,
    required String resolvedDesignation,
    String? resolvedSecondaryDesignation,
    required String? displayNameFontFamily,
    required String designationFontFamily,
    String? secondaryDesignationFontFamily,
    required bool isBusinessProfile,
    required bool isTeluguName,
    required double businessNameFontSize,
    required double personalNameFontSize,
    required double personalDesignationFontSize,
    required double businessDesignationFontSize,
    required double englishDesignationFontSize,
    required double englishPersonalNameFontSize,
    required double englishSplitNameFontSize,
    required double personalNameLineHeight,
    required bool showPhoneInStrip,
    required String resolvedPhone,
    required double bottomStripPadding,
    required double stripPixelHeight,
  }) {
    final stripColor = _resolvePosterStripColor(resolvedName);
    final stripTextColor = _onStripColor(stripColor);
    final mutedStripTextColor = _mutedOnStripColor(stripColor);
    final dividerColor = mutedStripTextColor;
    final partyLogoSize = _nameChipPartyLogoSize(stripPixelHeight);
    final hasBothDesignations =
        !isBusinessProfile &&
        resolvedSecondaryDesignation != null &&
        resolvedSecondaryDesignation.trim().isNotEmpty &&
        resolvedDesignation.trim().isNotEmpty;
    Widget buildSplitStripRow({
      required double nameFontSize,
      required double designationFontSize,
      required FontWeight nameFontWeight,
      required FontWeight designationFontWeight,
      required double nameHeight,
      required double designationHeight,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (_showPartyLogoInNameChip) ...<Widget>[
            _buildPartyLogoForNameChip(size: partyLogoSize),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: 52,
            child: SizedBox.expand(
              child: _legacyAwareText(
                text: resolvedName,
                fontFamily: displayNameFontFamily,
                maxLines: 1,
                textAlign: TextAlign.left,
                fitToWidth: true,
                style: TextStyle(
                  color: stripTextColor,
                  fontWeight: nameFontWeight,
                  fontSize: nameFontSize,
                  height: nameHeight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildNameDesignationSeparator(
            fallbackColor: dividerColor,
            fallbackHeight: hasBothDesignations ? 24 : 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 48,
            child: SizedBox.expand(
              child: hasBothDesignations
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: _legacyAwareText(
                            text: resolvedDesignation,
                            fontFamily: designationFontFamily,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            fitToWidth: true,
                            style: TextStyle(
                              color: mutedStripTextColor,
                              fontWeight: designationFontWeight,
                              fontSize: designationFontSize,
                              height: designationHeight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Expanded(
                          child: _legacyAwareText(
                            text: resolvedSecondaryDesignation,
                            fontFamily:
                                secondaryDesignationFontFamily ??
                                designationFontFamily,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            fitToWidth: true,
                            style: TextStyle(
                              color: mutedStripTextColor,
                              fontWeight: designationFontWeight,
                              fontSize: designationFontSize * 0.92,
                              height: designationHeight,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _legacyAwareText(
                      text: resolvedDesignation,
                      fontFamily: designationFontFamily,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      fitToWidth: true,
                      style: TextStyle(
                        color: mutedStripTextColor,
                        fontWeight: designationFontWeight,
                        fontSize: designationFontSize,
                        height: designationHeight,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    Widget buildSingleName({
      required double nameFontSize,
      required FontWeight nameFontWeight,
      required double nameHeight,
      TextAlign textAlign = TextAlign.center,
      MainAxisAlignment alignment = MainAxisAlignment.center,
    }) {
      return SizedBox.expand(
        child: _buildNameWithOptionalPartyLogo(
          alignment: alignment,
          logoSize: partyLogoSize,
          gap: 8,
          name: _legacyAwareText(
            text: resolvedName,
            fontFamily: displayNameFontFamily,
            maxLines: 1,
            textAlign: textAlign,
            fitToWidth: true,
            style: TextStyle(
              color: stripTextColor,
              fontWeight: nameFontWeight,
              fontSize: nameFontSize,
              height: nameHeight,
            ),
          ),
        ),
      );
    }

    final Widget content;
    if (isBusinessProfile) {
      content = resolvedDesignation.isNotEmpty
          ? buildSplitStripRow(
              nameFontSize: _isEnglishOnlyText(resolvedName)
                  ? englishSplitNameFontSize
                  : businessNameFontSize,
              designationFontSize: _isEnglishOnlyText(resolvedName)
                  ? englishDesignationFontSize
                  : businessDesignationFontSize,
              nameFontWeight: FontWeight.w500,
              designationFontWeight: FontWeight.w500,
              nameHeight: isTeluguName ? 0.98 : 1.0,
              designationHeight: 0.98,
            )
          : SizedBox.expand(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _isEnglishOnlyText(resolvedName)
                        ? _buildEnglishBusinessStrip(
                            resolvedName: resolvedName,
                            resolvedDesignation: resolvedDesignation,
                            displayNameFontFamily: displayNameFontFamily,
                            designationFontFamily: designationFontFamily,
                            stripTextColor: stripTextColor,
                            mutedStripTextColor: mutedStripTextColor,
                            showPhoneInStrip: showPhoneInStrip,
                            resolvedPhone: resolvedPhone,
                            partyLogoSize: partyLogoSize,
                          )
                        : _buildNameWithOptionalPartyLogo(
                            alignment: MainAxisAlignment.start,
                            logoSize: partyLogoSize,
                            gap: 8,
                            name: _legacyAwareText(
                              text: resolvedName,
                              fontFamily: displayNameFontFamily,
                              maxLines: 1,
                              textAlign: TextAlign.left,
                              fitToWidth: true,
                              style: TextStyle(
                                color: stripTextColor,
                                fontWeight: FontWeight.w500,
                                fontSize: businessNameFontSize,
                                height: isTeluguName ? 0.98 : 1.0,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
    } else if (_isEnglishOnlyText(resolvedName) &&
        resolvedDesignation.isEmpty) {
      content = SizedBox.expand(
        child: _buildNameWithOptionalPartyLogo(
          logoSize: partyLogoSize,
          name: _legacyAwareText(
            text: resolvedName,
            fontFamily: displayNameFontFamily,
            maxLines: 1,
            textAlign: TextAlign.center,
            fitToWidth: true,
            style: TextStyle(
              color: stripTextColor,
              fontWeight: FontWeight.w500,
              fontSize: englishPersonalNameFontSize,
              height: 1.0,
            ),
          ),
        ),
      );
    } else if (_isEnglishOnlyText(resolvedName) &&
        resolvedDesignation.isNotEmpty) {
      content = buildSplitStripRow(
        nameFontSize: englishSplitNameFontSize,
        designationFontSize: englishDesignationFontSize,
        nameFontWeight: FontWeight.w500,
        designationFontWeight: FontWeight.w500,
        nameHeight: 1.0,
        designationHeight: 1.0,
      );
    } else {
      if (resolvedDesignation.isNotEmpty) {
        content = buildSplitStripRow(
          nameFontSize: personalNameFontSize,
          designationFontSize: personalDesignationFontSize,
          nameFontWeight: FontWeight.w500,
          designationFontWeight: FontWeight.w500,
          nameHeight: personalNameLineHeight,
          designationHeight: 0.86,
        );
      } else {
        content = buildSingleName(
          nameFontSize: personalNameFontSize,
          nameFontWeight: FontWeight.w500,
          nameHeight: personalNameLineHeight,
        );
      }
    }

    return _wrapPosterBottomStrip(
      stripColor: stripColor,
      bottomStripPadding: bottomStripPadding,
      child: content,
    );
  }

  Widget _wrapPosterBottomStrip({
    required Color stripColor,
    required double bottomStripPadding,
    required Widget child,
  }) {
    final strip = Container(
      width: double.infinity,
      decoration: BoxDecoration(color: stripColor),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: bottomStripPadding,
        ),
        child: SizedBox.expand(child: child),
      ),
    );
    final onTap = widget.onNameStripTap;
    if (onTap == null) {
      return strip;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: strip,
    );
  }
}

