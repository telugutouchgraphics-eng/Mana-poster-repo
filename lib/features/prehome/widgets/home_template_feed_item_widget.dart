// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _TemplateFeedItem extends StatefulWidget {
  const _TemplateFeedItem({
    super.key,
    required this.item,
    required this.hostContext,
    required this.language,
    required this.deferRichPosterPreview,
    required this.onOpenSubscriptionPlan,
    required this.viewerPosterProfile,
    required this.posterRenderCycle,
    required this.onPosterPhotoDragStateChanged,
    this.playbackEnabled = true,
    this.enablePoliticalProtocolOverlay = false,
    this.showPartyLogoInNameChip = false,
    this.politicalProtocolPhotoScopeKey = '',
    this.partyLogoOverridesByPartyId = const <String, String>{},
    this.politicalParties = const <PoliticalParty>[],
    this.forcedPoliticalProtocolPartyId,
    this.showPosterEditButton = false,
    this.allowPoliticalProtocolWithoutParty = false,
    this.preferUltraLightImage = false,
    this.fillViewport = false,
    this.previewOnly = false,
    this.onPreviewTap,
    this.onInteraction,
  });

  final _TemplateItem item;
  final BuildContext hostContext;
  final AppLanguage language;
  final bool deferRichPosterPreview;
  final Future<void> Function({bool startPurchaseOnOpen})
  onOpenSubscriptionPlan;
  final PosterProfileData viewerPosterProfile;
  final int posterRenderCycle;
  final ValueChanged<bool> onPosterPhotoDragStateChanged;
  final bool playbackEnabled;
  final bool enablePoliticalProtocolOverlay;
  final bool showPartyLogoInNameChip;
  final String politicalProtocolPhotoScopeKey;
  final Map<String, String> partyLogoOverridesByPartyId;
  final List<PoliticalParty> politicalParties;
  final String? forcedPoliticalProtocolPartyId;
  final bool showPosterEditButton;
  final bool allowPoliticalProtocolWithoutParty;
  final bool preferUltraLightImage;
  final bool fillViewport;
  final bool previewOnly;
  final VoidCallback? onPreviewTap;
  final void Function(_TemplateItem item, String action)? onInteraction;
  static final SubscriptionBackendService _subscriptionBackendService =
      SubscriptionBackendService();
  static const PoliticalProtocolPhotoService _politicalProtocolPhotoService =
      PoliticalProtocolPhotoService();
  static final RewardedAccessService _homeExportRewardedAccessService =
      RewardedAccessService();
  static final HomeExportAdSettingsService _homeExportAdSettingsService =
      HomeExportAdSettingsService();

  static SubscriptionBackendService get subscriptionBackendService =>
      _subscriptionBackendService;

  @override
  State<_TemplateFeedItem> createState() => _TemplateFeedItemState();
}

class _TemplateFeedItemState extends State<_TemplateFeedItem>
    with AutomaticKeepAliveClientMixin<_TemplateFeedItem> {
  static const CloudFirstBackgroundRemovalService _backgroundRemovalService =
      CloudFirstBackgroundRemovalService();
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
  final GlobalKey _posterCaptureKey = GlobalKey();
  final ScreenshotController _posterScreenshotController =
      ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
  final ValueNotifier<bool> _showPosterPhotoNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> _posterReadyNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _activeActionNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<bool> _videoExportReadyNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<int> _videoReplayTickNotifier = ValueNotifier<int>(0);
  Uint8List? _preparedPosterBytes;
  String? _preparedPosterSignature;
  String? _preparedPosterFilePath;
  Future<void>? _preparePosterFuture;
  Future<Uint8List?>? _posterCaptureFuture;
  bool _forcePlainPosterCapture = false;
  String? _preparedVideoSignature;
  String? _preparedVideoFilePath;
  String? _preparedPlainVideoSignature;
  String? _preparedPlainVideoFilePath;
  Future<String?>? _prepareVideoFuture;
  String? _prepareVideoFutureSignature;
  int _videoExportGeneration = 0;
  bool _videoWarmupQueued = false;
  String? _queuedVideoWarmupSignature;
  bool _posterWarmupQueued = false;
  String? _queuedPosterWarmupSignature;
  static bool _globalAutoPosterWarmupActive = false;
  static final Set<String> _globalPosterWarmupSignatures = <String>{};
  _PosterPhotoUserAdjustment _photoUserAdjustment =
      _PosterPhotoUserAdjustment.none;
  _PosterExtraPhotoSelection? _extraPhotoSelection;
  int _stripGradientTapOffset = 0;
  Future<void>? _backgroundRemoverInitialization;
  bool _photoDragInProgress = false;
  bool _additionalPhotoBusy = false;
  double? _resolvedPreviewAspectRatio;
  String? _politicalProtocolPartyId;
  List<String> _politicalProtocolPhotoUrls = const <String>[];
  Set<String> _hiddenDefaultPoliticalProtocolPhotoUrls = const <String>{};
  List<String> _manualPoliticalProtocolPhotoPaths = const <String>[];
  List<PoliticalProtocolSlot>? _politicalProtocolDefaultSlotsOverride;
  List<PoliticalProtocolSlot> _manualPoliticalProtocolSlots =
      const <PoliticalProtocolSlot>[];
  Future<void>? _politicalProtocolPhotoLoadFuture;
  ValueNotifier<List<String>>? _manualProtocolPhotoNotifier;
  ValueNotifier<List<PoliticalProtocolSlot>>? _manualProtocolPhotoSlotNotifier;
  bool _directTrialPurchaseBusy = false;
  int _localViewCountDelta = 0;
  int _localShareCountDelta = 0;
  int _localDownloadCountDelta = 0;
  bool _localViewMarked = false;

  _TemplateItem get item => widget.item;
  BuildContext get hostContext => widget.hostContext;
  AppLanguage get language => widget.language;
  bool get deferRichPosterPreview => widget.deferRichPosterPreview;
  bool get playbackEnabled => widget.playbackEnabled;
  bool get preferUltraLightImage => widget.preferUltraLightImage;
  bool get fillViewport => widget.fillViewport;
  String get _fullScreenHeroTag =>
      'home-poster-preview-${item.templateId?.trim().isNotEmpty == true ? item.templateId!.trim() : Object.hash(item.titleEn, item.imageUrl, item.videoUrl, item.imageAssetPath)}';
  Future<void> Function({bool startPurchaseOnOpen})
  get onOpenSubscriptionPlan => widget.onOpenSubscriptionPlan;
  PosterProfileData get viewerPosterProfile => widget.viewerPosterProfile;
  int get posterRenderCycle => widget.posterRenderCycle;
  SubscriptionBackendService get _subscriptionBackendService =>
      _TemplateFeedItem.subscriptionBackendService;

  void _markLocalViewCounted() {
    if (_localViewMarked) {
      return;
    }
    setState(() {
      _localViewMarked = true;
      _localViewCountDelta = 1;
    });
  }

  void _bumpLocalEngagementCount(String action) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (action == 'share') {
        _localShareCountDelta += 1;
      } else if (action == 'download') {
        _localDownloadCountDelta += 1;
      }
    });
  }

  bool _isCurrentJokesPoster() {
    final signals = <String>{};

    void addSignal(String raw) {
      final normalized = _normalizeTagWorker(raw);
      if (normalized.isEmpty) {
        return;
      }
      signals.add(normalized);
      signals.addAll(_expandCategoryAliasesWorker(normalized));
    }

    addSignal(item.primaryFirestoreCategoryId ?? '');
    addSignal(item.categoryDisplayLabel ?? '');
    for (final tag in item.categoryTags) {
      addSignal(tag);
    }
    return signals.contains('jokes') ||
        signals.contains('funny') ||
        signals.contains('humor') ||
        signals.contains('comedy');
  }

  bool get _canAddPoliticalProtocolPhotos {
    final partyId = _resolvePoliticalPartyId();
    return widget.enablePoliticalProtocolOverlay &&
        !item.isVideo &&
        (item.personalizationConfig?.hasPoliticalProtocolLayout ?? false) &&
        (widget.allowPoliticalProtocolWithoutParty ||
            (partyId != null && partyId.trim().isNotEmpty));
  }

  List<PoliticalParty> get _availablePoliticalParties =>
      widget.politicalParties.isEmpty
      ? politicalParties
      : widget.politicalParties;

  PoliticalParty? _resolvePoliticalParty() {
    final forcedParty = _resolvePoliticalPartyFromId(
      widget.forcedPoliticalProtocolPartyId ?? '',
    );
    if (forcedParty != null) {
      return forcedParty;
    }

    final tags = <String>{
      for (final tag in item.categoryTags) _normalizeTagWorker(tag),
      _normalizeTagWorker(item.primaryFirestoreCategoryId ?? ''),
    }..removeWhere((tag) => tag.isEmpty);
    if (tags.isEmpty) {
      return null;
    }
    for (final party in _availablePoliticalParties) {
      final partyId = _normalizeTagWorker(party.id);
      final shortName = _normalizeTagWorker(party.shortName);
      final matches =
          tags.contains(partyId) ||
          tags.contains('party_$partyId') ||
          (shortName.isNotEmpty && tags.contains(shortName)) ||
          (shortName.isNotEmpty && tags.contains('party_$shortName'));
      if (matches) {
        return party;
      }
    }
    return null;
  }

  PoliticalParty? _resolvePoliticalPartyFromId(String rawId) {
    final normalized = _normalizeTagWorker(rawId);
    if (normalized.isEmpty) {
      return null;
    }
    for (final party in _availablePoliticalParties) {
      final partyId = _normalizeTagWorker(party.id);
      final shortName = _normalizeTagWorker(party.shortName);
      if (normalized == partyId ||
          normalized == 'party_$partyId' ||
          (shortName.isNotEmpty && normalized == shortName) ||
          (shortName.isNotEmpty && normalized == 'party_$shortName')) {
        return party;
      }
    }
    return null;
  }

  String? _resolvePoliticalPartyLogoAssetPath() {
    final party = _resolvePoliticalParty();
    if (party == null) {
      return null;
    }
    final overrideUrl =
        widget.partyLogoOverridesByPartyId[party.id]?.trim() ?? '';
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    return party.logoAssetPath;
  }

  String? _resolvePoliticalPartyId() {
    final forced = widget.forcedPoliticalProtocolPartyId?.trim() ?? '';
    if (forced.isNotEmpty) {
      return forced;
    }
    return _resolvePoliticalParty()?.id;
  }

  void _syncPoliticalProtocolPhotos() {
    if (!widget.enablePoliticalProtocolOverlay) {
      _politicalProtocolPartyId = null;
      _politicalProtocolPhotoUrls = const <String>[];
      _politicalProtocolPhotoLoadFuture = null;
      return;
    }
    final partyId = _resolvePoliticalPartyId();
    if (partyId == null || partyId.isEmpty) {
      _politicalProtocolPartyId = null;
      _politicalProtocolPhotoUrls = const <String>[];
      _politicalProtocolPhotoLoadFuture = null;
      return;
    }
    if (_politicalProtocolPartyId == partyId &&
        (_politicalProtocolPhotoLoadFuture != null ||
            _politicalProtocolPhotoUrls.isNotEmpty)) {
      return;
    }
    final partyChanged = _politicalProtocolPartyId != partyId;
    _politicalProtocolPartyId = partyId;
    if (partyChanged) {
      _politicalProtocolPhotoUrls = const <String>[];
    }
    final future = _TemplateFeedItem._politicalProtocolPhotoService
        .fetchPhotoUrlsForParty(partyId);
    _politicalProtocolPhotoLoadFuture = future;
    unawaited(
      future.then((urls) {
        if (!mounted ||
            _politicalProtocolPartyId != partyId ||
            _politicalProtocolPhotoLoadFuture != future) {
          return;
        }
        setState(() {
          _politicalProtocolPhotoUrls = urls;
        });
      }),
    );
  }

  String _manualProtocolPhotoScopeKey() {
    if (!widget.enablePoliticalProtocolOverlay) {
      return '';
    }
    final rawScope = widget.politicalProtocolPhotoScopeKey.trim();
    if (rawScope.isNotEmpty) {
      return rawScope;
    }
    final forced = widget.forcedPoliticalProtocolPartyId?.trim() ?? '';
    if (forced.isNotEmpty) {
      return 'party_${_normalizeTagWorker(forced)}';
    }
    return _normalizeTagWorker(item.primaryFirestoreCategoryId ?? 'political');
  }

  String _hiddenDefaultProtocolPhotoPrefsKey() {
    final scope = _manualProtocolPhotoScopeKey().trim().isNotEmpty
        ? _manualProtocolPhotoScopeKey().trim()
        : 'political';
    return 'political_hidden_default_protocol_photos_v1_$scope';
  }

  Future<void> _loadHiddenDefaultProtocolPhotoUrls() async {
    if (!widget.enablePoliticalProtocolOverlay) {
      _hiddenDefaultPoliticalProtocolPhotoUrls = const <String>{};
      return;
    }
    final prefsKey = _hiddenDefaultProtocolPhotoPrefsKey();
    try {
      final prefs = await SharedPreferences.getInstance();
      final urls =
          prefs
              .getStringList(prefsKey)
              ?.map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .toSet() ??
          const <String>{};
      if (!mounted || prefsKey != _hiddenDefaultProtocolPhotoPrefsKey()) {
        return;
      }
      setState(() => _hiddenDefaultPoliticalProtocolPhotoUrls = urls);
    } catch (_) {
      // Hidden default protocol photos are optional local preferences.
    }
  }

  void _handleManualProtocolPhotosChanged() {
    final notifier = _manualProtocolPhotoNotifier;
    final slotNotifier = _manualProtocolPhotoSlotNotifier;
    if (!mounted || notifier == null) {
      return;
    }
    setState(() {
      _manualPoliticalProtocolPhotoPaths = notifier.value
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false);
      final slots = slotNotifier?.value ?? const <PoliticalProtocolSlot>[];
      _manualPoliticalProtocolSlots = slots
          .take(_manualPoliticalProtocolPhotoPaths.length)
          .toList(growable: false);
    });
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    _schedulePosterWarmup(force: true);
  }

  void _syncManualProtocolPhotoScope() {
    _manualProtocolPhotoNotifier?.removeListener(
      _handleManualProtocolPhotosChanged,
    );
    _manualProtocolPhotoSlotNotifier?.removeListener(
      _handleManualProtocolPhotosChanged,
    );
    _manualProtocolPhotoNotifier = null;
    _manualProtocolPhotoSlotNotifier = null;
    _manualPoliticalProtocolPhotoPaths = const <String>[];
    _manualPoliticalProtocolSlots = const <PoliticalProtocolSlot>[];
  }

  @override
  void initState() {
    super.initState();
    _resolvedPreviewAspectRatio = _initialPreviewAspectRatioFor(item);
    _syncManualProtocolPhotoScope();
    _syncPoliticalProtocolPhotos();
    unawaited(_loadHiddenDefaultProtocolPhotoUrls());
    unawaited(_preloadHomeExportRewardedAdAfterFirstSettledFrames());
    if (playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && playbackEnabled) {
          _markLocalViewCounted();
        }
      });
    }
    if (item.isVideo && playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scheduleVideoWarmupAfterSettledFrames());
      });
    }
  }

  Future<void> _preloadHomeExportRewardedAdAfterFirstSettledFrames() async {
    await Future<void>.delayed(const Duration(seconds: 45));
    if (!mounted) {
      return;
    }
    await _preloadHomeExportRewardedAdIfEnabled();
  }

  Future<void> _scheduleVideoWarmupAfterSettledFrames() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted || !playbackEnabled) {
      return;
    }
    _scheduleVideoWarmup(requireReady: false, allowScrollDeferral: true);
    _scheduleVideoWarmupRetries();
  }

  @override
  void didUpdateWidget(covariant _TemplateFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackEnabled != widget.playbackEnabled) {
      updateKeepAlive();
    }
    if (oldWidget.item.templateId != widget.item.templateId) {
      _localViewCountDelta = 0;
      _localShareCountDelta = 0;
      _localDownloadCountDelta = 0;
      _localViewMarked = false;
    }
    if (!oldWidget.playbackEnabled && widget.playbackEnabled) {
      _markLocalViewCounted();
    }
    if (oldWidget.enablePoliticalProtocolOverlay !=
            widget.enablePoliticalProtocolOverlay ||
        oldWidget.politicalProtocolPhotoScopeKey !=
            widget.politicalProtocolPhotoScopeKey ||
        oldWidget.forcedPoliticalProtocolPartyId !=
            widget.forcedPoliticalProtocolPartyId ||
        oldWidget.item.categoryTags != widget.item.categoryTags ||
        oldWidget.item.primaryFirestoreCategoryId !=
            widget.item.primaryFirestoreCategoryId) {
      _syncManualProtocolPhotoScope();
      _syncPoliticalProtocolPhotos();
      unawaited(_loadHiddenDefaultProtocolPhotoUrls());
    }
    if (oldWidget.item.videoUrl != widget.item.videoUrl ||
        oldWidget.item.imageUrl != widget.item.imageUrl ||
        oldWidget.item.imageStoragePath != widget.item.imageStoragePath ||
        oldWidget.item.thumbnailStoragePath !=
            widget.item.thumbnailStoragePath ||
        oldWidget.item.thumbnailUrl != widget.item.thumbnailUrl ||
        oldWidget.item.imageAssetPath != widget.item.imageAssetPath ||
        oldWidget.item.pageConfig != widget.item.pageConfig ||
        oldWidget.viewerPosterProfile != widget.viewerPosterProfile ||
        oldWidget.language != widget.language ||
        oldWidget.posterRenderCycle != widget.posterRenderCycle) {
      _resolvedPreviewAspectRatio = _initialPreviewAspectRatioFor(item);
      _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
      if (item.isVideo && playbackEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_scheduleVideoWarmupAfterSettledFrames());
        });
      }
    } else if (item.isVideo &&
        !oldWidget.playbackEnabled &&
        widget.playbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scheduleVideoWarmupAfterSettledFrames());
      });
    }
  }

  double? _initialPreviewAspectRatioFor(_TemplateItem item) {
    final pageConfig = item.pageConfig;
    if (pageConfig != null &&
        pageConfig.widthPx > 0 &&
        pageConfig.heightPx > 0) {
      return pageConfig.aspectRatio;
    }
    return null;
  }

  void _handlePreviewAspectRatioResolved(double aspectRatio) {
    if (!mounted || aspectRatio <= 0) {
      return;
    }
    final existing = _resolvedPreviewAspectRatio;
    if (existing != null && (existing - aspectRatio).abs() < 0.001) {
      return;
    }
    setState(() => _resolvedPreviewAspectRatio = aspectRatio);
  }

  @override
  void dispose() {
    if (_photoDragInProgress) {
      widget.onPosterPhotoDragStateChanged(false);
    }
    _manualProtocolPhotoNotifier?.removeListener(
      _handleManualProtocolPhotosChanged,
    );
    _invalidatePreparedPosterCache();
    _showPosterPhotoNotifier.dispose();
    _posterReadyNotifier.dispose();
    _activeActionNotifier.dispose();
    _videoExportReadyNotifier.dispose();
    _videoReplayTickNotifier.dispose();
    super.dispose();
  }

  String _resolvePosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${item.imageUrl ?? item.imageAssetPath ?? 'poster'}'
        '|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + _stripGradientTapOffset) % _randomPosterNameFonts.length;
    return _randomPosterNameFonts[index];
  }

  String _resolveEnglishPosterNameFontFamily(String resolvedName) {
    final seedSource =
        '${item.imageUrl ?? item.imageAssetPath ?? 'poster'}'
        '|english|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    final index =
        (hash.abs() + _stripGradientTapOffset) %
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

  bool _shouldConvertForLegacyTelugu(String text, String? fontFamily) {
    return fontFamily != null &&
        _teluguTextPattern.hasMatch(text) &&
        !_isMixedTeluguAndLatinText(text) &&
        (_randomPosterNameFonts.contains(fontFamily) ||
            fontFamily == 'Pallavi Medium' ||
            fontFamily == 'Pallavi Bold');
  }

  bool _isMixedTeluguAndLatinText(String text) {
    return _teluguTextPattern.hasMatch(text) &&
        _latinTextPattern.hasMatch(text);
  }

  CreatorPosterPersonalization _plainPosterPersonalization(
    CreatorPosterPersonalization config,
  ) {
    return CreatorPosterPersonalization(
      photoShape: config.photoShape,
      photoX: config.photoX,
      photoY: config.photoY,
      photoScale: config.photoScale,
      photoAnimation: config.photoAnimation,
      showVideoExtraPhoto: false,
      videoExtraPhotoShape: config.videoExtraPhotoShape,
      videoExtraPhotoRenderMode: config.videoExtraPhotoRenderMode,
      videoExtraPhotoEdgeStyle: config.videoExtraPhotoEdgeStyle,
      videoExtraPhotoAnimation: config.videoExtraPhotoAnimation,
      videoExtraPhotoX: config.videoExtraPhotoX,
      videoExtraPhotoY: config.videoExtraPhotoY,
      videoExtraPhotoScale: config.videoExtraPhotoScale,
      nameX: config.nameX,
      nameY: config.nameY,
      showBottomStrip: false,
      stripHeight: config.stripHeight,
      stripWidth: config.stripWidth,
      stripX: config.stripX,
      stripBottom: config.stripBottom,
      showWhatsapp: false,
      sampleName: config.sampleName,
      nameScale: config.nameScale,
      showStyledNameStrip: false,
      showStyledDesignationStrip: false,
      sampleDesignation: config.sampleDesignation,
      designationScale: config.designationScale,
      phoneScale: config.phoneScale,
      nameStripColor: config.nameStripColor,
      designationStripColor: config.designationStripColor,
      stripLayoutStyle: config.stripLayoutStyle,
      boardVariant: config.boardVariant,
      photoRenderMode: config.photoRenderMode,
      edgeStyle: config.edgeStyle,
      showSafeAreas: false,
      showPoliticalProtocol: false,
      politicalProtocolX: config.politicalProtocolX,
      politicalProtocolY: config.politicalProtocolY,
      politicalProtocolScale: config.politicalProtocolScale,
      politicalProtocolSlots: config.politicalProtocolSlots,
      politicalProtocolEnabledAtMillis: 0,
    );
  }

  String _posterSignature({
    required bool isPhotoVisible,
    bool plainPersonalization = false,
  }) {
    final defaultProtocolSlots =
        _politicalProtocolDefaultSlotsOverride ??
        item.personalizationConfig?.politicalProtocolSlots ??
        const <PoliticalProtocolSlot>[];
    final protocolSlotSignature =
        <PoliticalProtocolSlot>[
              ...defaultProtocolSlots,
              ..._manualPoliticalProtocolSlots,
            ]
            .map(
              (slot) =>
                  '${slot.x.toStringAsFixed(2)},${slot.y.toStringAsFixed(2)},${slot.scale.toStringAsFixed(2)}',
            )
            .join('|');
    final protocolPhotoSignature = <String>[
      ..._politicalProtocolPhotoUrls.take(defaultPoliticalProtocolSlots.length),
      ..._manualPoliticalProtocolPhotoPaths,
    ].join('|');
    return '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-${item.videoUrl ?? ''}-${item.mediaType}-${language.name}-${viewerPosterProfile.identityMode.name}-${viewerPosterProfile.activeName}-${viewerPosterProfile.activeWhatsappNumber}-${viewerPosterProfile.photoPath}-${viewerPosterProfile.photoUrl}-${viewerPosterProfile.businessLogoPath}-${viewerPosterProfile.businessLogoUrl}-${viewerPosterProfile.preferOriginalPersonalPhoto}-${_photoUserAdjustment.flipHorizontally}-${_photoUserAdjustment.xOffsetPercent.toStringAsFixed(2)}-${_photoUserAdjustment.yOffsetPercent.toStringAsFixed(2)}-${_extraPhotoSelection?.originalPhotoPath ?? ''}-${_extraPhotoSelection?.cutoutPhotoPath ?? ''}-protocol$protocolPhotoSignature-$protocolSlotSignature-strip$_stripGradientTapOffset-$posterRenderCycle-$isPhotoVisible-plain$plainPersonalization';
  }

  void _cyclePosterDesign() {
    setState(() {
      _stripGradientTapOffset =
          (_stripGradientTapOffset + 1) %
          _CreatorPosterPreviewState.posterStripGradientCount;
    });
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    _schedulePosterWarmup(force: true);
  }

  bool _beginAction(String action) {
    if (_activeActionNotifier.value != null) {
      return false;
    }
    _activeActionNotifier.value = action;
    return true;
  }

  void _endAction() {
    _activeActionNotifier.value = null;
  }

  void _invalidatePreparedPosterCache({bool cancelVideoExport = false}) {
    final existingPath = _preparedPosterFilePath;
    final shouldCancelVideoExport =
        cancelVideoExport && item.isVideo && _prepareVideoFuture != null;
    _preparedPosterBytes = null;
    _preparedPosterSignature = null;
    _preparedPosterFilePath = null;
    _preparedVideoSignature = null;
    _preparedVideoFilePath = null;
    _preparedPlainVideoSignature = null;
    _preparedPlainVideoFilePath = null;
    _prepareVideoFuture = null;
    _prepareVideoFutureSignature = null;
    _videoExportGeneration += 1;
    _queuedVideoWarmupSignature = null;
    _videoWarmupQueued = false;
    if (item.isVideo) {
      _videoExportReadyNotifier.value = false;
    }
    _queuedPosterWarmupSignature = null;
    if (shouldCancelVideoExport) {
      _homeDebugLog('video export stale in-flight cancelled');
      unawaited(FFmpegKit.cancel());
    }
    if (existingPath != null) {
      unawaited(
        File(existingPath).delete().catchError((_) => File(existingPath)),
      );
    }
  }

  Future<void> _ensureBackgroundRemovalReady() {
    return _backgroundRemoverInitialization ??= _backgroundRemovalService
        .ensureReady();
  }

  Future<File> _stagePickedImageForCrop(
    XFile picked, {
    required String filePrefix,
  }) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String extension = picked.name.contains('.')
        ? picked.name.substring(picked.name.lastIndexOf('.'))
        : '.png';
    final String targetPath =
        '${tempDir.path}${Platform.pathSeparator}'
        '${filePrefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final File targetFile = File(targetPath);
    await targetFile.writeAsBytes(await picked.readAsBytes(), flush: true);
    return targetFile;
  }

  Future<void> _deleteFileSilently(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _deleteAdditionalPhotoAssets() async {
    final selection = _extraPhotoSelection;
    if (selection == null) {
      return;
    }
    final paths = <String>{
      selection.originalPhotoPath.trim(),
      selection.cutoutPhotoPath.trim(),
    }.where((path) => path.isNotEmpty);
    for (final path in paths) {
      await _deleteFileSilently(File(path));
    }
  }

  Future<Uint8List?> _removeAdditionalPhotoBackground(
    Uint8List optimizedOriginalBytes,
  ) async {
    Future<Uint8List?> attempt(Uint8List sourceBytes, Duration timeout) async {
      await _ensureBackgroundRemovalReady();
      final removedResult = await _backgroundRemovalService
          .removeBackground(sourceBytes)
          .timeout(timeout);
      return removedResult.pngBytes;
    }

    try {
      return await attempt(optimizedOriginalBytes, const Duration(seconds: 30));
    } catch (_) {
      try {
        final smallerBytes = await compute(
          _prepareAdditionalPosterPhotoRemovalBytes,
          optimizedOriginalBytes,
        );
        return await attempt(smallerBytes, const Duration(seconds: 30));
      } catch (_) {
        return null;
      }
    }
  }

  Future<BuildContext> _showAdditionalPhotoProcessingDialog() async {
    final strings = context.strings;
    final completer = Completer<BuildContext>();
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'additional-photo-processing',
        barrierColor: Colors.black.withValues(alpha: 0.16),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          if (!completer.isCompleted) {
            completer.complete(dialogContext);
          }
          return Material(
            type: MaterialType.transparency,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.localized(
                        telugu: 'బ్యాక్‌గ్రౌండ్ తొలగిస్తున్నాము...',
                        english: 'Removing background...',
                        hindi: 'पृष्ठभूमि हटाई जा रही है...',
                        tamil: 'பின்னணி நீக்கப்படுகிறது...',
                        kannada: 'ಹಿನ್ನೆಲೆಯನ್ನು ತೆಗೆದುಹಾಕಲಾಗುತ್ತಿದೆ...',
                        malayalam: 'പശ്ചാത്തലം നീക്കംചെയ്യുന്നു...',
                        marathi: 'पार्श्वभूमी काढली जात आहे...',
                        gujarati: 'પૃષ્ઠભૂમિ દૂર કરી રહ્યાં છીએ...',
                        bengali: 'ব্যাকগ্রাউন্ড সরানো হচ্ছে...',
                        punjabi: 'ਪਿਛੋਕੜ ਹਟਾਇਆ ਜਾ ਰਿਹਾ ਹੈ...',
                        odia: 'ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଯାଉଛି...',
                        assamese: 'পৃষ্ঠভূমি আঁতৰোৱা হৈছে...',
                        konkani: 'फाटभुंय काडटात...',
                        nepali: 'पृष्ठभूमि हटाइँदैछ...',
                        meitei: 'বেকগ্রাউন্দ লৌথোকপগী থবক চত্থরি...',
                        mizo: 'Background paih mek a ni...',
                        kashmiri: 'پس منظر چُھ ہٹاونہٕ یِوان...',
                        ladakhi: 'རྒྱབ་ལྗོངས་བསུབ་བཞིན་པ...',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    return completer.future;
  }

  Future<void> _pickAdditionalPosterPhoto() async {
    final personalizationConfig = item.personalizationConfig;
    if (_additionalPhotoBusy ||
        personalizationConfig == null ||
        !personalizationConfig.showVideoExtraPhoto) {
      return;
    }
    setState(() => _additionalPhotoBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.strings;
    File? stagedCropSourceFile;
    var processingDialogOpen = false;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) {
        return;
      }
      stagedCropSourceFile = await _stagePickedImageForCrop(
        picked,
        filePrefix: 'poster_additional_photo_pick',
      );
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: stagedCropSourceFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: strings.localized(
              telugu: 'ఫోటో కత్తిరించండి',
              english: 'Crop Photo',
              hindi: 'फ़ोटो क्रॉप करें',
              tamil: 'புகைப்படத்தை செதுக்கு',
              kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'फोटो क्रॉप करा',
              gujarati: 'ફોટો ક્રોપ કરો',
              bengali: 'ছবি ক্রপ করুন',
              punjabi: 'ਫੋਟੋ ਕੱਟੋ',
              odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'ফটো ক্ৰপ কৰক',
              konkani: 'फोटो क्रॉप करा',
              nepali: 'फोटो क्रप गर्नुहोस्',
              meitei: 'ফোতো ক্রপ তৌবীয়ু',
              mizo: 'Thlalak tan rawh',
              kashmiri: 'فوٹو کٹ کرِو',
              ladakhi: 'པར་བཅད་ཏེ་བཟོས།',
            ),
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF0F172A),
            activeControlsWidgetColor: const Color(0xFF2563EB),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: strings.localized(
              telugu: 'ఫోటో కత్తిరించండి',
              english: 'Crop Photo',
              hindi: 'फ़ोटो क्रॉप करें',
              tamil: 'புகைப்படத்தை செதுக்கு',
              kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'फोटो क्रॉप करा',
              gujarati: 'ફોટો ક્રોપ કરો',
              bengali: 'ছবি ক্রপ করুন',
              punjabi: 'ਫੋਟੋ ਕੱਟੋ',
              odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'ফটো ক্ৰপ কৰক',
              konkani: 'फोटो क्रॉप करा',
              nepali: 'फोटो क्रप गर्नुहोस्',
              meitei: 'ফোতো ক্রপ তৌবীয়ু',
              mizo: 'Thlalak tan rawh',
              kashmiri: 'فوٹو کٹ کرِو',
              ladakhi: 'པར་བཅད་ཏེ་བཟོས།',
            ),
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (cropped == null) {
        return;
      }
      final originalBytes = await File(cropped.path).readAsBytes();
      final optimizedOriginalBytes = await compute(
        _optimizeAdditionalPosterPhotoBytes,
        originalBytes,
      );
      BuildContext? processingDialogContext;
      if (mounted) {
        processingDialogContext = await _showAdditionalPhotoProcessingDialog();
        processingDialogOpen = true;
      }
      final Uint8List? cutoutBytes = await _removeAdditionalPhotoBackground(
        optimizedOriginalBytes,
      );
      if (processingDialogOpen &&
          processingDialogContext != null &&
          processingDialogContext.mounted) {
        Navigator.of(processingDialogContext).pop();
        processingDialogOpen = false;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String originalTargetPath =
          '${dir.path}${Platform.pathSeparator}'
          'poster_additional_original_photo_$stamp.png';
      final File originalLocalFile = File(originalTargetPath);
      await originalLocalFile.writeAsBytes(optimizedOriginalBytes, flush: true);
      var cutoutTargetPath = '';
      if (cutoutBytes != null) {
        cutoutTargetPath =
            '${dir.path}${Platform.pathSeparator}'
            'poster_additional_photo_$stamp.png';
        await File(cutoutTargetPath).writeAsBytes(cutoutBytes, flush: true);
      }
      await _deleteAdditionalPhotoAssets();
      if (!mounted) {
        return;
      }
      setState(() {
        _extraPhotoSelection = _PosterExtraPhotoSelection(
          originalPhotoPath: originalTargetPath,
          cutoutPhotoPath: cutoutTargetPath,
        );
      });
      _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
      _schedulePosterWarmup(force: true);
      if (cutoutBytes == null && mounted) {
        _showSnack(
          messenger,
          strings.localized(
            telugu:
                'ఫోటో జోడించాం, కానీ background remove పూర్తిగా కాలేదు. ప్రస్తుతానికి అసలు ఫోటోనే ఉపయోగిస్తున్నాం.',
            english:
                'Photo was added, but background removal did not complete. Using the original photo for now.',
            hindi:
                'फ़ोटो जोड़ी गई, लेकिन पृष्ठभूमि पूरी तरह नहीं हट सकी। फ़िलहाल मूल फ़ोटो का उपयोग किया जा रहा है।',
            tamil:
                'புகைப்படம் சேர்க்கப்பட்டது, ஆனால் பின்னணி நீக்கம் முழுமையடையவில்லை. இப்போதைக்கு அசல் புகைப்படம் பயன்படுத்தப்படுகிறது.',
            kannada:
                'ಫೋಟೋ ಸೇರಿಸಲಾಗಿದೆ, ಆದರೆ ಹಿನ್ನೆಲೆ ತೆಗೆದುಹಾಕುವಿಕೆ ಪೂರ್ಣಗೊಂಡಿಲ್ಲ. ಸದ್ಯಕ್ಕೆ ಮೂಲ ಫೋಟೋವನ್ನೇ ಬಳಸಲಾಗುತ್ತಿದೆ.',
            malayalam:
                'ഫോട്ടോ ചേർത്തു, എന്നാൽ പശ്ചാത്തലം നീക്കംചെയ്യൽ പൂർത്തിയായില്ല. തൽക്കാലം യഥാർത്ഥ ഫോട്ടോ ഉപയോഗിക്കുന്നു.',
            marathi:
                'फोटो जोडला गेला, परंतु पार्श्वभूमी काढणे पूर्ण झाले नाही. सध्या मूळ फोटो वापरत आहोत.',
            gujarati:
                'ફોટો ઉમેરાયો, પરંતુ પૃષ્ઠભૂમિ દૂર કરવાની પ્રક્રિયા પૂર્ણ થઈ નથી. હમણાં માટે મૂળ ફોટો વાપરી રહ્યાં છીએ.',
            bengali:
                'ফটো যোগ করা হয়েছে, তবে ব্যাকগ্রাউন্ড অপসারণ সম্পন্ন হয়নি। আপাতত আসল ছবিটি ব্যবহার করা হচ্ছে।',
            punjabi:
                'ਫੋਟੋ ਸ਼ਾਮਲ ਕੀਤੀ ਗਈ, ਪਰ ਪਿਛੋਕੜ ਹਟਾਉਣਾ ਪੂਰਾ ਨਹੀਂ ਹੋਇਆ। ਫਿਲਹਾਲ ਅਸਲ ਫੋਟੋ ਦੀ ਵਰਤੋਂ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ।',
            odia:
                'ଫଟୋ ଯୋଡ଼ାଗଲା, କିନ୍ତୁ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଇବା ସମ୍ପୂର୍ଣ୍ଣ ହେଲାନାହିଁ। ବର୍ତ୍ତମାନ ପାଇଁ ମୂଳ ଫଟୋ ବ୍ୟବହାର କରାଯାଉଛି।',
            assamese:
                'ফটো যোগ কৰা হ’ল, কিন্তু পটভূমি আঁতৰোৱা সম্পূৰ্ণ নহ’ল। বৰ্তমানৰ বাবে মূল ফটোখন ব্যৱহাৰ কৰা হৈছে।',
            konkani:
                'फोटो जोडलो, पूण फाटभुंय काडपाचें काम पूर्ण जावंक ना. सध्या मूळ फोटोच वापरतात.',
            nepali:
                'फोटो थपियो, तर पृष्ठभूमि हटाउने काम पूरा भएन। हालको लागि मूल तस्विर नै प्रयोग गरिँदैछ।',
            meitei:
                'ফোতো হাপচিনখ্রে, অদুবু বেকগ্রাউন্দ লৌথোকপা লোইশিনবা ঙমদ্রে। হৌজিক্কীদি অশেংবা ফোতো শীজিন্নরি।',
            mizo:
                'Thlalak dah a ni a, mahse background paih a la zo lo. Tun atan chuan thlalak tak tak zawk hman rih a ni.',
            kashmiri:
                'فوٹو آو رَلاونہٕ، مگر پس منظر ہٹاونُک کٲم گوو نہٕ پوٗرٕ। وۄنؠ تام چُھ اصل فوٹو اِستعمال گژھان۔',
            ladakhi:
                'པར་བསྣན་ཟིན། འོན་ཀྱང་རྒྱབ་ལྗོངས་བསུབ་རྒྱུ་མ་རྫོགས། ད་ལྟའི་ཆེད་དུ་པར་ངོ་མ་དེ་བེད་སྤྱོད་གཏོང་བཞིན་ཡོད།',
          ),
        );
      }
    } catch (_) {
      if (processingDialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
      if (mounted) {
        _showSnack(
          messenger,
          strings.localized(
            telugu: 'అదనపు ఫోటో జోడించలేకపోయాం.',
            english: 'Could not add the extra photo.',
            hindi: 'अतिरिक्त फ़ोटो नहीं जोड़ी जा सकी।',
            tamil: 'கூடுதல் புகைப்படத்தைச் சேர்க்க முடியவில்லை.',
            kannada: 'ಹೆಚ್ಚುವರಿ ಫೋಟೋ ಸೇರಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
            malayalam: 'കൂടുതൽ ഫോട്ടോ ചേർക്കാനായില്ല.',
            marathi: 'अतिरिक्त फोटो जोडता आला नाही.',
            gujarati: 'વધારાનો ફોટો ઉમેરી શકાયો નથી.',
            bengali: 'অতিরিক্ত ছবি যোগ করা যায়নি।',
            punjabi: 'ਵਾਧੂ ਫੋਟੋ ਸ਼ਾਮਲ ਨਹੀਂ ਕੀਤੀ ਜਾ ਸਕੀ।',
            odia: 'ଅତିରିକ୍ତ ଫଟୋ ଯୋଡ଼ିବା ସମ୍ଭବ ହେଲାନାହିଁ।',
            assamese: 'অতিৰিক্ত ফটোখন যোগ কৰিব পৰা নগ’ল।',
            konkani: 'अदिक फोटो जोडूंक जालो ना.',
            nepali: 'थप तस्विर थप्न सकिएन।',
            meitei: 'অহেনবা ফোতো হাপচিনবা ঙমদে।',
            mizo: 'Thlalak dang dah belh theih a ni lo.',
            kashmiri: 'اضافی فوٹو ہیٚکہ نہٕ رَلٲوِتھ۔',
            ladakhi: 'པར་འཕར་མ་བསྣན་མ་ཐུབ།',
          ),
        );
      }
    } finally {
      if (stagedCropSourceFile != null) {
        unawaited(_deleteFileSilently(stagedCropSourceFile));
      }
      if (mounted) {
        setState(() => _additionalPhotoBusy = false);
      }
    }
  }

  Future<void> _openPoliticalProtocolPhotoScreen(BuildContext context) async {
    final partyId = _resolvePoliticalPartyId();
    if (!widget.enablePoliticalProtocolOverlay ||
        item.isVideo ||
        !(item.personalizationConfig?.hasPoliticalProtocolLayout ?? false) ||
        (!widget.allowPoliticalProtocolWithoutParty &&
            (partyId == null || partyId.trim().isEmpty))) {
      return;
    }
    final result = await Navigator.of(context)
        .push<_PoliticalProtocolPhotoScreenResult>(
          MaterialPageRoute<_PoliticalProtocolPhotoScreenResult>(
            fullscreenDialog: true,
            builder: (_) => _PoliticalProtocolPhotoScreen(
              item: item,
              language: language,
              viewerPosterProfile: viewerPosterProfile,
              politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
              partyLogoAssetPath: _resolvePoliticalPartyLogoAssetPath(),
              showDefaultProtocolPhotos:
                  item.personalizationConfig?.hasPoliticalProtocolLayout ??
                  false,
              initialManualPhotoPaths: _manualPoliticalProtocolPhotoPaths,
              initialHiddenDefaultPhotoUrls:
                  _hiddenDefaultPoliticalProtocolPhotoUrls,
              defaultSlots:
                  _politicalProtocolDefaultSlotsOverride ??
                  item.personalizationConfig?.politicalProtocolSlots ??
                  defaultPoliticalProtocolSlots,
              initialManualSlots: _manualPoliticalProtocolSlots,
              ensureSubscriptionAccess: _ensureSubscriptionAccess,
              ensureGallerySavePermission: _ensureGallerySavePermission,
              leaderPhotoLibraryScopeKey: _manualProtocolPhotoScopeKey(),
            ),
          ),
        );
    if (!mounted || result == null) {
      return;
    }
    final normalizedPaths = result.manualPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final normalizedSlots = result.manualSlots
        .take(normalizedPaths.length)
        .toList(growable: false);
    final normalizedDefaultSlots =
        result.defaultSlots.length >= defaultPoliticalProtocolSlots.length
        ? result.defaultSlots
              .take(defaultPoliticalProtocolSlots.length)
              .toList(growable: false)
        : item.personalizationConfig?.politicalProtocolSlots ??
              defaultPoliticalProtocolSlots;
    setState(() {
      _manualPoliticalProtocolPhotoPaths = normalizedPaths;
      _hiddenDefaultPoliticalProtocolPhotoUrls = result.hiddenDefaultPhotoUrls;
      _politicalProtocolDefaultSlotsOverride = normalizedDefaultSlots;
      _manualPoliticalProtocolSlots = normalizedSlots;
    });
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    _schedulePosterWarmup(force: true);
  }

  bool get _canInteractWithPosterPhoto {
    final personalizationConfig = item.personalizationConfig;
    if (item.isVideo ||
        personalizationConfig == null ||
        !_showPosterPhotoNotifier.value) {
      return false;
    }
    if (viewerPosterProfile.identityMode == PosterIdentityMode.business) {
      return false;
    }
    return viewerPosterProfile.photoPath.trim().isNotEmpty ||
        viewerPosterProfile.photoUrl.trim().isNotEmpty ||
        viewerPosterProfile.originalPhotoPath.trim().isNotEmpty ||
        viewerPosterProfile.originalPhotoUrl.trim().isNotEmpty;
  }

  void _togglePosterPhotoFlipTap() {
    if (!_canInteractWithPosterPhoto) {
      return;
    }
    _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
    setState(() {
      _photoUserAdjustment = _PosterPhotoUserAdjustment(
        xOffsetPercent: _photoUserAdjustment.xOffsetPercent,
        yOffsetPercent: _photoUserAdjustment.yOffsetPercent,
        flipHorizontally: !_photoUserAdjustment.flipHorizontally,
      );
    });
    _schedulePosterWarmup(force: true);
  }

  void _updatePosterPhotoDrag({
    required double deltaXPercent,
    required double deltaYPercent,
  }) {
    if (!_canInteractWithPosterPhoto) {
      return;
    }
    final nextX = _photoUserAdjustment.xOffsetPercent + deltaXPercent;
    final nextY = _photoUserAdjustment.yOffsetPercent + deltaYPercent;
    if (nextX == _photoUserAdjustment.xOffsetPercent &&
        nextY == _photoUserAdjustment.yOffsetPercent) {
      return;
    }
    setState(() {
      _photoUserAdjustment = _PosterPhotoUserAdjustment(
        xOffsetPercent: nextX,
        yOffsetPercent: nextY,
        flipHorizontally: _photoUserAdjustment.flipHorizontally,
      );
    });
  }

  void _setPhotoDragInProgress(bool value) {
    if (_photoDragInProgress == value) {
      return;
    }
    _photoDragInProgress = value;
    if (!value) {
      _invalidatePreparedPosterCache(cancelVideoExport: item.isVideo);
      _schedulePosterWarmup(force: true);
    }
    widget.onPosterPhotoDragStateChanged(value);
  }

  void _schedulePosterWarmup({bool force = false}) {
    if (item.isVideo && playbackEnabled) {
      _scheduleVideoWarmup();
      return;
    }
    if (!_posterReadyNotifier.value) {
      return;
    }
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    if (!force && _globalAutoPosterWarmupActive) {
      return;
    }
    if (_globalPosterWarmupSignatures.contains(signature)) {
      return;
    }
    if (!force) {
      if (_preparedPosterSignature == signature &&
          _preparedPosterBytes != null) {
        return;
      }
      if (_preparePosterFuture != null || _posterWarmupQueued) {
        return;
      }
      if (_queuedPosterWarmupSignature == signature) {
        return;
      }
    }
    _posterWarmupQueued = true;
    _queuedPosterWarmupSignature = signature;
    if (!force) {
      _globalAutoPosterWarmupActive = true;
    }
    _globalPosterWarmupSignatures.add(signature);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) {
          return;
        }
        if (!force && Scrollable.recommendDeferredLoadingForContext(context)) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (!mounted) {
            return;
          }
        }
        if (_posterCaptureKey.currentContext == null) {
          _recordPosterCaptureTrace(
            'poster export warmup skipped: capture context unavailable',
            details: <String, Object?>{
              'itemTitle': item.titleEn,
              'signature': signature,
            },
          );
          return;
        }
        await _preparePosterExport(force: force);
      } finally {
        _globalPosterWarmupSignatures.remove(signature);
        if (!force) {
          _globalAutoPosterWarmupActive = false;
        }
        _posterWarmupQueued = false;
        if (_queuedPosterWarmupSignature == signature) {
          _queuedPosterWarmupSignature = null;
        }
      }
    });
  }

  void _scheduleVideoWarmup({
    bool requireReady = true,
    bool allowScrollDeferral = true,
  }) {
    if (!playbackEnabled ||
        !item.isVideo ||
        (requireReady && !_posterReadyNotifier.value)) {
      return;
    }
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    if (_prepareVideoFuture != null ||
        (_videoWarmupQueued && _queuedVideoWarmupSignature == signature)) {
      return;
    }
    final existingPath = _preparedVideoFilePath;
    if (_preparedVideoSignature == signature &&
        existingPath != null &&
        File(existingPath).existsSync()) {
      if (!_videoExportReadyNotifier.value) {
        _videoExportReadyNotifier.value = true;
      }
      return;
    }
    if (_videoExportReadyNotifier.value) {
      _videoExportReadyNotifier.value = false;
    }
    _videoWarmupQueued = true;
    _queuedVideoWarmupSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || (requireReady && !_posterReadyNotifier.value)) {
          return;
        }
        if (allowScrollDeferral &&
            Scrollable.recommendDeferredLoadingForContext(context)) {
          await Future<void>.delayed(const Duration(milliseconds: 650));
          if (!mounted || (requireReady && !_posterReadyNotifier.value)) {
            return;
          }
          _videoWarmupQueued = false;
          if (_queuedVideoWarmupSignature == signature) {
            _queuedVideoWarmupSignature = null;
          }
          _scheduleVideoWarmup(
            requireReady: requireReady,
            allowScrollDeferral: false,
          );
          return;
        }
        await _ensurePreparedVideoFile(isWarmup: true);
      } finally {
        _videoWarmupQueued = false;
        if (_queuedVideoWarmupSignature == signature) {
          _queuedVideoWarmupSignature = null;
        }
      }
    });
  }

  void _scheduleVideoWarmupRetries() {
    if (!item.isVideo || !playbackEnabled) {
      return;
    }
    const retryDelays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 180),
      Duration(milliseconds: 450),
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2500),
      Duration(seconds: 5),
      Duration(seconds: 9),
    ];
    for (final delay in retryDelays) {
      Future<void>.delayed(delay, () {
        if (!mounted ||
            !playbackEnabled ||
            !item.isVideo ||
            _videoExportReadyNotifier.value) {
          return;
        }
        _scheduleVideoWarmup(requireReady: false, allowScrollDeferral: false);
      });
    }
  }

  Future<void> _prepareLegacyTextForExport() async {
    final resolvedName = viewerPosterProfile.resolvedName(language: language);
    final isBusinessProfile =
        viewerPosterProfile.identityMode == PosterIdentityMode.business;
    final primaryDesignation = isBusinessProfile
        ? viewerPosterProfile.businessTagline.trim()
        : viewerPosterProfile.primaryPersonalDesignation;
    final secondaryDesignation = isBusinessProfile
        ? ''
        : viewerPosterProfile.secondaryPersonalDesignation;
    final displayNameFontFamily = _resolveDisplayNameFontFamily(resolvedName);
    final primaryDesignationFontFamily = _resolveDesignationFontFamily(
      primaryDesignation,
    );
    final secondaryDesignationFontFamily = _resolveDesignationFontFamily(
      secondaryDesignation,
    );
    final futures = <Future<String?>>[];

    if (_shouldConvertForLegacyTelugu(resolvedName, displayNameFontFamily) &&
        TeluguLegacyTextService.cachedValue(
              resolvedName,
              fontFamily: displayNameFontFamily!,
            ) ==
            null) {
      futures.add(
        TeluguLegacyTextService.convert(
          resolvedName,
          fontFamily: displayNameFontFamily,
        ),
      );
    }

    if (_shouldConvertForLegacyTelugu(
          primaryDesignation,
          primaryDesignationFontFamily,
        ) &&
        TeluguLegacyTextService.cachedValue(
              primaryDesignation,
              fontFamily: primaryDesignationFontFamily,
            ) ==
            null) {
      futures.add(
        TeluguLegacyTextService.convert(
          primaryDesignation,
          fontFamily: primaryDesignationFontFamily,
        ),
      );
    }

    if (secondaryDesignation.isNotEmpty &&
        _shouldConvertForLegacyTelugu(
          secondaryDesignation,
          secondaryDesignationFontFamily,
        ) &&
        TeluguLegacyTextService.cachedValue(
              secondaryDesignation,
              fontFamily: secondaryDesignationFontFamily,
            ) ==
            null) {
      futures.add(
        TeluguLegacyTextService.convert(
          secondaryDesignation,
          fontFamily: secondaryDesignationFontFamily,
        ),
      );
    }

    if (futures.isEmpty) {
      return;
    }

    await Future.wait(futures);
  }

  Future<void> _preparePosterExport({
    bool force = false,
    bool? photoVisibleOverride,
    bool plainPersonalization = false,
  }) async {
    final requestedPhotoVisible = plainPersonalization
        ? false
        : photoVisibleOverride ?? _showPosterPhotoNotifier.value;
    final signature = _posterSignature(
      isPhotoVisible: requestedPhotoVisible,
      plainPersonalization: plainPersonalization,
    );
    if (!force &&
        _preparedPosterSignature == signature &&
        _preparedPosterBytes != null &&
        _preparedPosterFilePath != null &&
        await File(_preparedPosterFilePath!).exists()) {
      return;
    }
    final inFlight = _preparePosterFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      final originalPhotoVisible = _showPosterPhotoNotifier.value;
      final originalPlainCapture = _forcePlainPosterCapture;
      final shouldTemporarilySwitch =
          requestedPhotoVisible != originalPhotoVisible;
      final shouldTemporarilySwitchPlain =
          plainPersonalization != originalPlainCapture;
      if (shouldTemporarilySwitch) {
        _showPosterPhotoNotifier.value = requestedPhotoVisible;
      }
      if (shouldTemporarilySwitchPlain && mounted) {
        setState(() => _forcePlainPosterCapture = plainPersonalization);
      } else if (shouldTemporarilySwitchPlain) {
        _forcePlainPosterCapture = plainPersonalization;
      }
      if (shouldTemporarilySwitch || shouldTemporarilySwitchPlain) {
        await _settlePosterCaptureFrame();
      }
      try {
        await _doPreparePosterExport(signature);
      } finally {
        var shouldRestoreFrame = false;
        if (shouldTemporarilySwitch) {
          _showPosterPhotoNotifier.value = originalPhotoVisible;
          shouldRestoreFrame = true;
        }
        if (shouldTemporarilySwitchPlain && mounted) {
          setState(() => _forcePlainPosterCapture = originalPlainCapture);
          shouldRestoreFrame = true;
        } else if (shouldTemporarilySwitchPlain) {
          _forcePlainPosterCapture = originalPlainCapture;
          shouldRestoreFrame = true;
        }
        if (shouldRestoreFrame) {
          await _settlePosterCaptureFrame();
          _schedulePosterWarmup(force: true);
        }
      }
    }();
    _preparePosterFuture = future;
    try {
      await future;
    } finally {
      if (identical(_preparePosterFuture, future)) {
        _preparePosterFuture = null;
      }
    }
  }

  Future<void> _doPreparePosterExport(String signature) async {
    try {
      await ScreenSecurityService.disableSecure();
      await _ensurePosterCaptureResourcesReady();
      await _prepareLegacyTextForExport();
      final bytes = await _capturePosterBytes();
      if (bytes == null) {
        return;
      }
      final tempDirectory = await getTemporaryDirectory();
      final fileName = 'mana_poster_export_${signature.hashCode.abs()}.png';
      final filePath =
          '${tempDirectory.path}${Platform.pathSeparator}$fileName';
      await File(filePath).writeAsBytes(bytes, flush: false);
      _preparedPosterBytes = bytes;
      _preparedPosterSignature = signature;
      _preparedPosterFilePath = filePath;
      _homeDebugLog('poster export warmup ready bytes=${bytes.length}');
    } catch (error, stackTrace) {
      _homeDebugLogStack('poster export warmup failed: $error', stackTrace);
    } finally {
      await ScreenSecurityService.enableSecure();
    }
  }

  Future<String?> _ensurePreparedPosterFile() async {
    return _ensurePreparedPosterFileForVisibility(
      _showPosterPhotoNotifier.value,
    );
  }

  Future<String?> _ensurePreparedPosterFileForVisibility(
    bool isPhotoVisible, {
    bool plainPersonalization = false,
  }) async {
    final signature = _posterSignature(
      isPhotoVisible: isPhotoVisible,
      plainPersonalization: plainPersonalization,
    );
    final existingPath = _preparedPosterFilePath;
    if (_preparedPosterSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      return existingPath;
    }
    await _preparePosterExport(
      photoVisibleOverride: isPhotoVisible,
      plainPersonalization: plainPersonalization,
    );
    final refreshedPath = _preparedPosterFilePath;
    if (refreshedPath != null && await File(refreshedPath).exists()) {
      return refreshedPath;
    }
    return null;
  }

  Future<String?> _ensurePreparedPlainPosterFile() async {
    return _ensurePreparedPosterFileForVisibility(
      false,
      plainPersonalization: true,
    );
  }

  Future<String?> _ensurePreparedVideoFile({bool isWarmup = false}) async {
    final videoUrl = item.videoUrl?.trim() ?? '';
    if (!item.isVideo || videoUrl.isEmpty) {
      return null;
    }
    final startedAt = DateTime.now();
    final personalization =
        item.personalizationConfig ?? CreatorPosterPersonalization.defaults;
    final signature = _posterSignature(
      isPhotoVisible: _showPosterPhotoNotifier.value,
    );
    final existingPath = _preparedVideoFilePath;
    if (_preparedVideoSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      if (!_videoExportReadyNotifier.value) {
        _videoExportReadyNotifier.value = true;
      }
      if (kDebugMode) {
        _homeDebugLog(
          'video export ${isWarmup ? "warmup" : "action"} cache hit in '
          '${DateTime.now().difference(startedAt).inMilliseconds}ms '
          'title=${item.titleEn}',
        );
      }
      return existingPath;
    }
    final inFlight = _prepareVideoFuture;
    if (inFlight != null && _prepareVideoFutureSignature == signature) {
      if (kDebugMode) {
        _homeDebugLog(
          'video export ${isWarmup ? "warmup" : "action"} joined in-flight '
          'title=${item.titleEn}',
        );
      }
      return inFlight;
    }
    final generation = _videoExportGeneration;
    final future = () async {
      try {
        if (kDebugMode) {
          _homeDebugLog(
            'video export ${isWarmup ? "warmup" : "action"} start '
            'title=${item.titleEn}',
          );
        }
        final outputPath = await const PersonalizedVideoExportService().export(
          videoUrl: videoUrl,
          profile: viewerPosterProfile,
          personalization: personalization,
          language: language,
          extraPhotoProfile:
              personalization.showVideoExtraPhoto &&
                  (_extraPhotoSelection?.hasPhoto ?? false)
              ? _extraPhotoSelection!.asPosterProfileData()
              : null,
          title: item.titleFor(language),
          previewSeed: item.imageUrl ?? item.imageAssetPath ?? 'poster',
          stripGradientTapOffset: _stripGradientTapOffset,
        );
        if (_videoExportGeneration == generation) {
          _preparedVideoSignature = signature;
          _preparedVideoFilePath = outputPath;
        }
        if (mounted && _videoExportGeneration == generation) {
          if (!_videoExportReadyNotifier.value) {
            _videoExportReadyNotifier.value = true;
          }
          setState(() {});
        }
        if (kDebugMode) {
          _homeDebugLog(
            'video export ${isWarmup ? "warmup" : "action"} ready in '
            '${DateTime.now().difference(startedAt).inMilliseconds}ms '
            'title=${item.titleEn}',
          );
        }
        return outputPath;
      } catch (error, stackTrace) {
        if (mounted &&
            _videoExportGeneration == generation &&
            _videoExportReadyNotifier.value) {
          _videoExportReadyNotifier.value = false;
        }
        _homeDebugLogStack('video export failed: $error', stackTrace);
        return null;
      }
    }();
    _prepareVideoFuture = future;
    _prepareVideoFutureSignature = signature;
    try {
      return await future;
    } finally {
      if (identical(_prepareVideoFuture, future)) {
        _prepareVideoFuture = null;
        _prepareVideoFutureSignature = null;
      }
    }
  }

  Future<String?> _ensurePreparedPlainVideoFile() async {
    final videoUrl = item.videoUrl?.trim() ?? '';
    if (!item.isVideo || videoUrl.isEmpty) {
      return null;
    }
    final personalization = item.personalizationConfig;
    if (personalization == null) {
      return _ensurePreparedVideoFile();
    }
    final plainPersonalization = _plainPosterPersonalization(personalization);
    final signature = _posterSignature(
      isPhotoVisible: false,
      plainPersonalization: true,
    );
    final existingPath = _preparedPlainVideoFilePath;
    if (_preparedPlainVideoSignature == signature &&
        existingPath != null &&
        await File(existingPath).exists()) {
      return existingPath;
    }
    try {
      final outputPath = await const PersonalizedVideoExportService().export(
        videoUrl: videoUrl,
        profile: viewerPosterProfile,
        personalization: plainPersonalization,
        language: language,
        title: item.titleFor(language),
        previewSeed: item.imageUrl ?? item.imageAssetPath ?? 'poster',
        stripGradientTapOffset: _stripGradientTapOffset,
      );
      _preparedPlainVideoSignature = signature;
      _preparedPlainVideoFilePath = outputPath;
      return outputPath;
    } catch (error, stackTrace) {
      _homeDebugLogStack('plain video export failed: $error', stackTrace);
      return null;
    }
  }

  bool _hasImmediateSubscriptionAccess() {
    if (InAppPurchaseGateway.playStoreProActive) {
      unawaited(_subscriptionBackendService.refreshEntitlementInBackground());
      return true;
    }
    final cachedEntitlement = _subscriptionBackendService.cachedEntitlement;
    if (_subscriptionBackendService.hasFreshEntitlementCache &&
        cachedEntitlement?.hasAccess == true) {
      return true;
    }
    return false;
  }

  bool _canAttemptLiveSubscriptionStatusCheck() {
    if (!_subscriptionBackendService.isConfigured) {
      return false;
    }
    return FirebaseAuth.instance.currentUser != null;
  }

  bool _isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  bool _shouldRunBlockingSubscriptionStatusCheck() {
    if (!_canAttemptLiveSubscriptionStatusCheck()) {
      return false;
    }
    if (_hasImmediateSubscriptionAccess()) {
      return true;
    }
    // When the app has not hydrated the entitlement cache yet, subscribed
    // users can otherwise see a false paywall on download/share. If we have
    // a logged-in user, do one live backend check before showing the plan.
    return true;
  }

  Future<bool> _ensureAuthenticatedForPosterAction(
    BuildContext context, {
    required String actionLabel,
  }) async {
    if (_isAuthenticated()) {
      return true;
    }
    final messenger = ScaffoldMessenger.of(context);
    _showSnack(
      messenger,
      context.strings.localized(
        telugu: '$actionLabel చేయడానికి ముందుగా లాగిన్ చేయండి.',
        english: 'Please login before $actionLabel.',
        hindi: '$actionLabel करने से पहले कृपया लॉगिन करें।',
        tamil: '$actionLabel செய்வதற்கு முன் உள்நுழையவும்.',
        kannada: '$actionLabel ಮಾಡುವ ಮೊದಲು ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ.',
        malayalam: '$actionLabel ചെയ്യുന്നതിന് മുമ്പ് ദയവായി ലോഗിൻ ചെയ്യുക.',
        marathi: '$actionLabel करण्यापूर्वी कृपया लॉगिन करा.',
        gujarati: '$actionLabel કરતાં પહેલાં કૃપા કરીને લૉગિન કરો.',
        bengali: '$actionLabel করার আগে অনুগ্রহ করে লগইন করুন।',
        punjabi: '$actionLabel ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਕਿਰਪਾ ਕਰਕੇ ਲਾਗਇਨ ਕਰੋ।',
        odia: '$actionLabel କରିବା ପୂର୍ବରୁ ଦୟାକରି ଲଗଇନ୍ କରନ୍ତୁ।',
        assamese: '$actionLabel কৰাৰ আগতে অনুগ্ৰহ কৰি লগইন কৰক।',
        konkani: '$actionLabel करचे पयलीं उपकार करून लॉगिन करात.',
        nepali: '$actionLabel गर्नु अघि कृपया लगइन गर्नुहोस्।',
        meitei: '$actionLabel তৌদ্রিঙৈ মমাংদা চানবীদুনা লগইন তৌবীয়ু।',
        mizo: '$actionLabel hmain khawngaihin lut rawh.',
        kashmiri: '$actionLabel کرنہٕ برٛونٛہہ مہر بانی کٔرِتھ کٔرِو لاگ اِن۔',
        ladakhi: '$actionLabel མ་བྱས་གོང་སྐུ་མཁྱེན་ནང་འཛུལ་གནང་།',
      ),
    );
    await Navigator.of(context).pushNamed(AppRoutes.login);
    return false;
  }

  bool get _legacySubscriptionStatusPopupEnabled => false;

  void _handlePosterReadyState(bool ready) {
    if (_posterReadyNotifier.value == ready) {
      return;
    }
    _posterReadyNotifier.value = ready;
    if (ready && item.isVideo && playbackEnabled) {
      _scheduleVideoWarmup(allowScrollDeferral: false);
      _scheduleVideoWarmupRetries();
    }
  }

  Future<Uint8List?> _capturePosterBytes() async {
    final inFlight = _posterCaptureFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _capturePosterBytesInternal();
    _posterCaptureFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_posterCaptureFuture, future)) {
        _posterCaptureFuture = null;
      }
    }
  }

  Future<Uint8List?> _capturePosterBytesInternal() async {
    final captureContext = _posterCaptureKey.currentContext;
    if (captureContext == null) {
      _recordPosterCaptureTrace(
        'poster capture skipped: context unavailable',
        details: _posterCaptureDiagnostics(),
      );
      return null;
    }

    final renderBox = captureContext.findRenderObject() as RenderBox?;
    final logicalSize =
        renderBox != null && renderBox.hasSize && !renderBox.size.isEmpty
        ? renderBox.size
        : MediaQuery.sizeOf(captureContext);
    final pixelRatio = _capturePosterPixelRatio(captureContext);
    final targetSize = logicalSize;
    final captureContextMounted = captureContext.mounted;

    _recordPosterCaptureTrace(
      'capture start',
      details: <String, Object?>{
        'method': 'screenshot.capture',
        'logicalSize': logicalSize.toString(),
        'pixelRatio': pixelRatio,
        'targetSize': targetSize.toString(),
      },
    );

    try {
      final bytes = await _posterScreenshotController.capture(
        pixelRatio: pixelRatio,
        delay: const Duration(milliseconds: 60),
      );
      if (bytes == null || bytes.isEmpty) {
        _recordPosterCaptureTrace(
          'poster capture skipped: empty live boundary',
          details: _posterCaptureDiagnostics(
            captureContextMounted: captureContextMounted,
            logicalSize: logicalSize,
            pixelRatio: pixelRatio,
          ),
        );
        return null;
      }
      _recordPosterCaptureTrace(
        'capture success',
        details: <String, Object?>{
          'method': 'screenshot.capture',
          'byteLength': bytes.length,
          'logicalSize': logicalSize.toString(),
          'pixelRatio': pixelRatio,
        },
      );
      return bytes;
    } catch (error, stackTrace) {
      await _recordPosterCaptureFailure(
        message: 'poster capture failed',
        error: error,
        stackTrace: stackTrace,
        captureContextMounted: captureContextMounted,
        logicalSize: logicalSize,
        pixelRatio: pixelRatio,
      );
      rethrow;
    }
  }

  Future<void> _ensurePosterCaptureResourcesReady() async {
    await _precacheCurrentPosterImage();
    await _precacheCurrentPosterProfileImage();
    await _precacheCurrentPosterAdditionalPhoto();
    await _precacheCurrentPoliticalProtocolPhotos();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _precacheCurrentPosterImage() async {
    if (item.isVideo) {
      return;
    }
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null || !posterContext.mounted) {
      return;
    }
    try {
      final assetPath = item.imageAssetPath?.trim() ?? '';
      if (assetPath.isNotEmpty) {
        await precacheImage(AssetImage(assetPath), posterContext);
        return;
      }
      final imageUrl = item.imageUrl?.trim() ?? '';
      final thumbnailUrl = item.thumbnailUrl?.trim() ?? '';
      final resolvedUrl = imageUrl.isNotEmpty ? imageUrl : thumbnailUrl;
      if (resolvedUrl.isEmpty) {
        return;
      }
      await precacheImage(
        item.preferOriginalPosterQuality
            ? CachedNetworkImageProvider(
                resolvedUrl,
                cacheManager: PosterNetworkImageCache.instance,
              )
            : CachedNetworkImageProvider(
                resolvedUrl,
                cacheManager: PosterNetworkImageCache.instance,
                maxWidth: PosterNetworkImageLimits.diskFeedMaxWidth,
                maxHeight: PosterNetworkImageLimits.diskFeedMaxHeight,
              ),
        posterContext,
      );
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster image precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack('poster image precache skipped: $error', stackTrace);
    }
  }

  Future<void> _precacheCurrentPosterProfileImage() async {
    if (item.personalizationConfig == null || !_showPosterPhotoNotifier.value) {
      return;
    }
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null || !posterContext.mounted) {
      return;
    }
    final imageProvider = PosterProfileService.resolveImageProvider(
      viewerPosterProfile,
      preferOriginalPersonalPhoto:
          item.personalizationConfig?.photoRenderMode == 'original' ||
          viewerPosterProfile.preferOriginalPersonalPhoto,
      allowOriginalFallbackWhenCutoutUnavailable: true,
    );
    if (imageProvider == null) {
      return;
    }
    try {
      await precacheImage(imageProvider, posterContext);
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster profile image precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack(
        'poster profile image precache skipped: $error',
        stackTrace,
      );
    }
  }

  Future<void> _precacheCurrentPosterAdditionalPhoto() async {
    final personalizationConfig = item.personalizationConfig;
    final selection = _extraPhotoSelection;
    if (personalizationConfig == null ||
        !personalizationConfig.showVideoExtraPhoto ||
        selection == null ||
        !selection.hasPhoto) {
      return;
    }
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null) {
      return;
    }
    final profile = selection.asPosterProfileData();
    final imageProvider = PosterProfileService.resolveImageProvider(
      profile,
      preferOriginalPersonalPhoto:
          personalizationConfig.videoExtraPhotoRenderMode == 'original',
      allowOriginalFallbackWhenCutoutUnavailable: true,
    );
    if (imageProvider == null) {
      return;
    }
    try {
      await precacheImage(imageProvider, posterContext);
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster additional photo precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack(
        'poster additional photo precache skipped: $error',
        stackTrace,
      );
    }
  }

  Future<void> _precacheCurrentPoliticalProtocolPhotos() async {
    final personalizationConfig = item.personalizationConfig;
    if (!widget.enablePoliticalProtocolOverlay ||
        personalizationConfig == null ||
        !personalizationConfig.hasPoliticalProtocolLayout) {
      return;
    }
    final pendingDefaultPhotos = _politicalProtocolPhotoLoadFuture;
    if (pendingDefaultPhotos != null) {
      try {
        await pendingDefaultPhotos.timeout(const Duration(seconds: 2));
      } catch (_) {
        // Best effort: manual photos and already loaded defaults can still export.
      }
    }
    final defaultUrls = _politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .where(
          (url) =>
              url.isNotEmpty &&
              !_hiddenDefaultPoliticalProtocolPhotoUrls.contains(url),
        )
        .take(personalizationConfig.politicalProtocolSlots.length)
        .toList(growable: false);
    final manualPaths = _manualPoliticalProtocolPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    await _precachePoliticalProtocolPhotoProviders(
      defaultUrls: defaultUrls,
      manualPaths: manualPaths,
    );
  }

  Future<void> _precachePoliticalProtocolPhotoProviders({
    required List<String> defaultUrls,
    required List<String> manualPaths,
  }) async {
    final posterContext = _posterCaptureKey.currentContext;
    if (posterContext == null || !posterContext.mounted) {
      return;
    }
    final futures = <Future<void>>[
      for (final url in defaultUrls)
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: PosterNetworkImageCache.instance,
          ),
          posterContext,
        ),
      for (final path in manualPaths)
        precacheImage(FileImage(File(path)), posterContext),
    ];
    if (futures.isEmpty) {
      return;
    }
    try {
      await Future.wait(futures).timeout(const Duration(seconds: 4));
    } catch (error, stackTrace) {
      _recordPosterCaptureTrace(
        'poster protocol photos precache skipped',
        details: <String, Object?>{'error': error.toString()},
      );
      _homeDebugLogStack(
        'poster protocol photos precache skipped: $error',
        stackTrace,
      );
    }
  }

  double _capturePosterPixelRatio(BuildContext context) {
    final view =
        View.maybeOf(context) ??
        WidgetsBinding.instance.platformDispatcher.implicitView;
    final devicePixelRatio = view?.devicePixelRatio ?? 1.0;
    final renderBox =
        _posterCaptureKey.currentContext?.findRenderObject() as RenderBox?;
    final logicalWidth =
        renderBox != null && renderBox.hasSize && renderBox.size.width > 0
        ? renderBox.size.width
        : MediaQuery.sizeOf(context).width;
    final pageConfig = _editorPageConfigForPoster();
    final targetWidthRatio = pageConfig.widthPx / math.max(1.0, logicalWidth);
    return math.max(devicePixelRatio, targetWidthRatio).clamp(1.0, 4.5);
  }

  Future<void> _settlePosterCaptureFrame() async {
    await Future<void>.delayed(const Duration(milliseconds: 24));
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    await completer.future;
    await Future<void>.delayed(const Duration(milliseconds: 36));
  }

  void _recordPosterCaptureTrace(
    String message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    final detailText = details.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    final output = detailText.isEmpty ? message : '$message $detailText';
    developer.log(output, name: 'home.poster.capture');
    _homeDebugLog(output);
  }

  Future<void> _recordPosterCaptureFailure({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    bool? captureContextMounted,
    Size? logicalSize,
    double? pixelRatio,
  }) async {
    final diagnostic = _posterCaptureDiagnostics(
      captureContextMounted: captureContextMounted,
      logicalSize: logicalSize,
      pixelRatio: pixelRatio,
    );
    _recordPosterCaptureTrace(message, details: diagnostic);
    final captureError = error ?? Exception(message);
    if (_isRecoverablePosterCaptureError(captureError)) {
      _homeDebugLog(
        'poster capture recoverable failure skipped for Crashlytics: '
        '${_safeCrashlyticsText(captureError)}',
      );
      return;
    }
    await _recordPosterCaptureNonFatalSafely(
      captureError,
      stackTrace ?? StackTrace.current,
      reason: '${_safeCrashlyticsText(message)} | ${jsonEncode(diagnostic)}',
    );
  }

  Future<void> _recordPosterCaptureNonFatalSafely(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: _safeWellFormedString(reason),
        fatal: false,
      );
    } catch (recordingError, recordingStackTrace) {
      _homeDebugLogStack(
        'poster capture Crashlytics record skipped: '
        '${_safeCrashlyticsText(recordingError)}',
        recordingStackTrace,
      );
    }
  }

  bool _isRecoverablePosterCaptureError(Object error) {
    final normalized = _safeCrashlyticsText(error).toLowerCase();
    return normalized.contains('permission-denied') ||
        normalized.contains('permission_denied') ||
        normalized.contains('permission denied') ||
        normalized.contains('bad state: future already completed') ||
        normalized.contains('string is not well-formed utf-16') ||
        normalized.contains('skipped frames') ||
        normalized.contains('choreographer');
  }

  String _safeCrashlyticsText(Object? value) {
    try {
      return _safeWellFormedString(value?.toString() ?? '');
    } catch (_) {
      return '';
    }
  }

  String _safeWellFormedString(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        if (i + 1 < value.length) {
          final next = value.codeUnitAt(i + 1);
          if (next >= 0xDC00 && next <= 0xDFFF) {
            buffer.writeCharCode(codeUnit);
            buffer.writeCharCode(next);
            i++;
            continue;
          }
        }
        buffer.writeCharCode(0xFFFD);
      } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
        buffer.writeCharCode(0xFFFD);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  Map<String, Object?> _posterCaptureDiagnostics({
    bool? captureContextMounted,
    Size? logicalSize,
    double? pixelRatio,
  }) {
    return <String, Object?>{
      'captureMethod': 'screenshot.capture',
      'itemTitle': item.titleEn,
      'isVideo': item.isVideo,
      'hasPersonalization': item.personalizationConfig != null,
      'showProfilePhoto': _showPosterPhotoNotifier.value,
      'captureContextMounted': captureContextMounted,
      'logicalSize': logicalSize?.toString(),
      'pixelRatio': pixelRatio,
      'templateImageUrl': item.imageUrl,
      'templateThumbnailUrl': item.thumbnailUrl,
      'templateAssetPath': item.imageAssetPath,
      'profileIdentityMode': viewerPosterProfile.identityMode.name,
      'profilePhotoUrl': viewerPosterProfile.photoUrl,
      'profilePhotoPath': viewerPosterProfile.photoPath,
      'businessLogoUrl': viewerPosterProfile.businessLogoUrl,
    };
  }

  Widget _buildPosterPreview({
    required bool isPhotoVisible,
    ValueChanged<bool>? onPosterReadyChanged,
    bool? playbackEnabledOverride,
    bool enableFullScreenTap = true,
    bool personalizationEnabled = true,
  }) {
    final sourcePersonalizationConfig = item.personalizationConfig;
    final personalizationConfig =
        personalizationEnabled || sourcePersonalizationConfig == null
        ? sourcePersonalizationConfig
        : _plainPosterPersonalization(sourcePersonalizationConfig);
    final renderOriginalPosterQuality = item.preferOriginalPosterQuality;
    final effectivePlaybackEnabled = playbackEnabledOverride ?? playbackEnabled;
    final fullScreenTap = enableFullScreenTap ? _openFullScreenPreview : null;
    final effectiveShowProfilePhoto = personalizationEnabled && isPhotoVisible;
    final effectiveShowPoliticalProtocol =
        personalizationEnabled && widget.enablePoliticalProtocolOverlay;
    final effectiveAdditionalPhotoSelection = personalizationEnabled
        ? _extraPhotoSelection
        : null;
    if (deferRichPosterPreview) {
      return _ResolvedTemplatePosterImage(
        imageAssetPath: item.imageAssetPath,
        imageUrl: item.imageUrl ?? '',
        imageStoragePath: item.imageStoragePath,
        thumbnailStoragePath: item.thumbnailStoragePath,
        thumbnailUrl: item.thumbnailUrl,
        posterIdForDebug: item.templateId,
        preferOriginalPosterQuality: renderOriginalPosterQuality,
        preferUltraLightDecode: preferUltraLightImage,
        onAspectRatioResolved: _handlePreviewAspectRatioResolved,
        onFirstFrameReady: () => onPosterReadyChanged?.call(true),
      );
    }
    return item.isVideo
        ? personalizationConfig != null
              ? _CreatorPosterPreview(
                  imageAssetPath: item.imageAssetPath,
                  imageUrl: item.imageUrl,
                  imageStoragePath: item.imageStoragePath,
                  thumbnailStoragePath: item.thumbnailStoragePath,
                  thumbnailUrl: item.thumbnailUrl,
                  pageConfig: item.pageConfig,
                  basePosterBuilder: (VoidCallback onReady) =>
                      _FeedTapToPlayVideoPoster(
                        videoUrl: item.videoUrl!,
                        playbackEnabled: effectivePlaybackEnabled,
                        imageAssetPath: item.imageAssetPath,
                        imageUrl: item.imageUrl,
                        imageStoragePath: item.imageStoragePath,
                        thumbnailStoragePath: item.thumbnailStoragePath,
                        thumbnailUrl: item.thumbnailUrl,
                        onAspectRatioResolved:
                            _handlePreviewAspectRatioResolved,
                        onReady: onReady,
                        onOpenPreview: fullScreenTap,
                        onReplay: () {
                          _videoReplayTickNotifier.value =
                              _videoReplayTickNotifier.value + 1;
                        },
                      ),
                  videoReplayTickListenable: _videoReplayTickNotifier,
                  personalizationConfig: personalizationConfig,
                  preferOriginalPosterQuality: renderOriginalPosterQuality,
                  viewerPosterProfile: viewerPosterProfile,
                  language: language,
                  partyLogoAssetPath: widget.showPartyLogoInNameChip
                      ? _resolvePoliticalPartyLogoAssetPath()
                      : null,
                  politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
                  hiddenPoliticalProtocolPhotoUrls:
                      _hiddenDefaultPoliticalProtocolPhotoUrls,
                  politicalProtocolLocalPhotoPaths:
                      _manualPoliticalProtocolPhotoPaths,
                  politicalProtocolSlotsOverride:
                      _politicalProtocolDefaultSlotsOverride,
                  politicalProtocolManualSlots: _manualPoliticalProtocolSlots,
                  showPoliticalProtocolOverlay: effectiveShowPoliticalProtocol,
                  showProfilePhoto: effectiveShowProfilePhoto,
                  deferLegacyTextPrime: deferRichPosterPreview,
                  posterRenderCycle: posterRenderCycle,
                  photoTapEnabled: _canInteractWithPosterPhoto,
                  interactivePhotoEnabled: false,
                  photoShapeOverride: '',
                  photoRenderModeOverride: '',
                  photoFlipHorizontally: _photoUserAdjustment.flipHorizontally,
                  photoXOffsetPercent: _photoUserAdjustment.xOffsetPercent,
                  photoYOffsetPercent: _photoUserAdjustment.yOffsetPercent,
                  onPhotoTap: _togglePosterPhotoFlipTap,
                  stripGradientTapOffset: _stripGradientTapOffset,
                  onNameStripTap: null,
                  additionalPhotoSelection: effectiveAdditionalPhotoSelection,
                  onAdditionalPhotoTap:
                      personalizationEnabled &&
                          personalizationConfig.showVideoExtraPhoto
                      ? () => unawaited(_pickAdditionalPosterPhoto())
                      : null,
                  onPhotoDragDeltaPercent: _updatePosterPhotoDrag,
                  onPhotoDragStateChanged: _setPhotoDragInProgress,
                  onAspectRatioResolved: _handlePreviewAspectRatioResolved,
                  onPosterReadyChanged: onPosterReadyChanged,
                )
              : _FeedTapToPlayVideoPoster(
                  videoUrl: item.videoUrl!,
                  playbackEnabled: effectivePlaybackEnabled,
                  imageAssetPath: item.imageAssetPath,
                  imageUrl: item.imageUrl,
                  imageStoragePath: item.imageStoragePath,
                  thumbnailStoragePath: item.thumbnailStoragePath,
                  thumbnailUrl: item.thumbnailUrl,
                  onAspectRatioResolved: _handlePreviewAspectRatioResolved,
                  onReady: () => onPosterReadyChanged?.call(true),
                  onOpenPreview: fullScreenTap,
                )
        : personalizationConfig != null
        ? _CreatorPosterPreview(
            imageAssetPath: item.imageAssetPath,
            imageUrl: item.imageUrl,
            imageStoragePath: item.imageStoragePath,
            thumbnailStoragePath: item.thumbnailStoragePath,
            thumbnailUrl: item.thumbnailUrl,
            pageConfig: item.pageConfig,
            personalizationConfig: personalizationConfig,
            preferOriginalPosterQuality: renderOriginalPosterQuality,
            viewerPosterProfile: viewerPosterProfile,
            language: language,
            partyLogoAssetPath: widget.showPartyLogoInNameChip
                ? _resolvePoliticalPartyLogoAssetPath()
                : null,
            politicalProtocolPhotoUrls: _politicalProtocolPhotoUrls,
            hiddenPoliticalProtocolPhotoUrls:
                _hiddenDefaultPoliticalProtocolPhotoUrls,
            politicalProtocolLocalPhotoPaths:
                _manualPoliticalProtocolPhotoPaths,
            politicalProtocolSlotsOverride:
                _politicalProtocolDefaultSlotsOverride,
            politicalProtocolManualSlots: _manualPoliticalProtocolSlots,
            showPoliticalProtocolOverlay: effectiveShowPoliticalProtocol,
            showProfilePhoto: effectiveShowProfilePhoto,
            deferLegacyTextPrime: deferRichPosterPreview,
            posterRenderCycle: posterRenderCycle,
            photoTapEnabled: _canInteractWithPosterPhoto,
            interactivePhotoEnabled: false,
            photoShapeOverride: '',
            photoRenderModeOverride: '',
            photoFlipHorizontally: _photoUserAdjustment.flipHorizontally,
            photoXOffsetPercent: _photoUserAdjustment.xOffsetPercent,
            photoYOffsetPercent: _photoUserAdjustment.yOffsetPercent,
            onPhotoTap: _togglePosterPhotoFlipTap,
            stripGradientTapOffset: _stripGradientTapOffset,
            onNameStripTap: null,
            additionalPhotoSelection: effectiveAdditionalPhotoSelection,
            onAdditionalPhotoTap:
                personalizationEnabled &&
                    personalizationConfig.showVideoExtraPhoto
                ? () => unawaited(_pickAdditionalPosterPhoto())
                : null,
            onPhotoDragDeltaPercent: _updatePosterPhotoDrag,
            onPhotoDragStateChanged: _setPhotoDragInProgress,
            onAspectRatioResolved: _handlePreviewAspectRatioResolved,
            onPosterReadyChanged: onPosterReadyChanged,
          )
        : _ResolvedTemplatePosterImage(
            imageAssetPath: item.imageAssetPath,
            imageUrl: item.imageUrl ?? '',
            imageStoragePath: item.imageStoragePath,
            thumbnailStoragePath: item.thumbnailStoragePath,
            thumbnailUrl: item.thumbnailUrl,
            posterIdForDebug: item.templateId,
            preferOriginalPosterQuality: renderOriginalPosterQuality,
            onAspectRatioResolved: _handlePreviewAspectRatioResolved,
            onFirstFrameReady: () => onPosterReadyChanged?.call(true),
          );
  }

  Widget _buildCapturedPosterPreview({
    required bool isPhotoVisible,
    ValueChanged<bool>? onPosterReadyChanged,
  }) {
    final plainCapture =
        _forcePlainPosterCapture || (!item.isVideo && _isCurrentJokesPoster());
    final preview = _buildPosterPreview(
      isPhotoVisible: plainCapture ? false : isPhotoVisible,
      onPosterReadyChanged: onPosterReadyChanged,
      personalizationEnabled: !plainCapture,
    );
    final framedPreview = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: deferRichPosterPreview
          ? null
          : (widget.onPreviewTap ?? _openFullScreenPreview),
      child: Hero(
        tag: _fullScreenHeroTag,
        transitionOnUserGestures: true,
        child: Material(type: MaterialType.transparency, child: preview),
      ),
    );
    final captureContent = plainCapture
        ? Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              framedPreview,
              Positioned(
                right: 10,
                bottom: 10,
                child: IgnorePointer(child: _buildPlainPosterWatermark()),
              ),
            ],
          )
        : framedPreview;
    if (deferRichPosterPreview) {
      return KeyedSubtree(key: _posterCaptureKey, child: captureContent);
    }
    return KeyedSubtree(
      key: _posterCaptureKey,
      child: Screenshot(
        controller: _posterScreenshotController,
        child: captureContent,
      ),
    );
  }

  Widget _buildPlainPosterWatermark() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.96)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(
              child: Image.asset(
                'assets/branding/mana_poster_logo.png',
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Mana Poster Ai',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorIdLabel({bool compact = false}) {
    final creatorId = item.creatorPublicId?.trim() ?? '';
    if (creatorId.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, compact ? 3 : 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          creatorId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    if (Platform.isAndroid &&
        !(await MediaExportService.needsGalleryPermission())) {
      return true;
    }
    final permission = Platform.isAndroid
        ? Permission.storage
        : Permission.photos;
    final photosStatus = await permission.status;
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }
    final requested = await <Permission>[permission].request();
    return requested.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  void _showDownloadSuccessSnack(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.showTopSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.asset(
                  'assets/branding/mana_poster_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F9F6E),
        elevation: 10,
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.down,
        clipBehavior: Clip.hardEdge,
      ),
    );
  }

  void _showFullScreenDownloadSuccessToast(
    BuildContext context,
    String message,
  ) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showDownloadSuccessSnack(ScaffoldMessenger.of(context), message);
      return;
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.paddingOf(context).top + 14;
        return Positioned(
          top: topPadding,
          left: 14,
          right: 14,
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0F9F6E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/branding/mana_poster_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    Timer(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  Future<bool> _resolveLatestSubscriptionAccess() async {
    if (InAppPurchaseGateway.playStoreProActive) {
      unawaited(
        _subscriptionBackendService.refreshEntitlementInBackground(
          forceRefresh: true,
        ),
      );
      return true;
    }

    final cachedHint = await _subscriptionBackendService
        .fetchEntitlementWithCache(forceRefresh: false);
    if (cachedHint.hasAccess) {
      unawaited(
        _subscriptionBackendService.refreshEntitlementInBackground(
          forceRefresh: true,
        ),
      );
      return true;
    }

    final backend = await _subscriptionBackendService.fetchEntitlement(
      forceRefresh: true,
    );
    final effectiveIsPro = backend.hasAccess;
    _homeDebugLog(
      'subscription access resolve: backendResponse.isPro=$effectiveIsPro',
    );
    if (effectiveIsPro) {
      return true;
    }

    final refreshed = await _subscriptionBackendService
        .fetchFreshEntitlementWithRetry();
    final refreshedEffectiveIsPro = refreshed.hasAccess;
    _homeDebugLog(
      'subscription access retry: backendResponse.isPro=$refreshedEffectiveIsPro',
    );
    return refreshedEffectiveIsPro;
  }

  // ignore: unused_element
  Future<bool> _startDirectTrialPurchaseFromFreeExportChoice() async {
    if (_directTrialPurchaseBusy || !mounted) {
      return false;
    }
    setState(() => _directTrialPurchaseBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final purchaseGateway = InAppPurchaseGateway();
    try {
      await purchaseGateway.initialize();
      if (!mounted) {
        return false;
      }
      final outcome = await purchaseGateway.purchaseMonthlyPro();
      if (!mounted) {
        return false;
      }

      if (outcome.result != PurchaseFlowResult.success ||
          outcome.evidence == null) {
        if (outcome.result != PurchaseFlowResult.cancelled) {
          _showSnack(messenger, _directTrialPurchaseMessage(outcome.result));
        }
        if (mounted) {
          setState(() => _directTrialPurchaseBusy = false);
        }
        await showSubscriptionExitVideoPromptIfAvailable(
          context,
          onSubscribe: (_) => _startDirectTrialPurchaseFromFreeExportChoice(),
        );
        return false;
      }

      final verification = await _verifyDirectTrialPurchaseWithRetry(
        outcome.evidence!,
      );
      if (!mounted) {
        return false;
      }
      if (!verification.hasAccess) {
        _showSnack(
          messenger,
          verification.message?.trim().isNotEmpty == true
              ? verification.message!.trim()
              : context.strings.localized(
                  telugu: 'సబ్‌స్క్రిప్షన్ ధృవీకరణ విఫలమైంది',
                  english: 'Subscription verification failed',
                  hindi: 'सदस्यता सत्यापन विफल रहा',
                  tamil: 'சந்தா சரிபார்ப்பு தோல்வியடைந்தது',
                  kannada: 'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆ ವಿಫಲವಾಗಿದೆ',
                  malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ സ്ഥിരീകരണം പരാജയപ്പെട്ടു',
                  marathi: 'सदस्यता पडताळणी अयशस्वी',
                  gujarati: 'સબ્સ્ક્રિપ્શન ચકાસણી નિષ્ફળ',
                  bengali: 'সাবস্ক্রিপশন যাচাইকরণ ব্যর্থ হয়েছে',
                  punjabi: 'ਗਾਹਕੀ ਤਸਦੀਕ ਅਸਫਲ ਰਹੀ',
                  odia: 'ସବସ୍କ୍ରିପସନ୍ ଯାଞ୍ଚ ବିଫଳ ହେଲା',
                  assamese: 'চাবস্ক্ৰিপচন পৰীক্ষণ ব্যৰ্থ হ’ল',
                  konkani: 'वर्गणी पडताळणी जावंक ना',
                  nepali: 'सदस्यता प्रमाणीकरण असफल भयो',
                  meitei: 'সবস্ক্রিপসন চেকিং তৌবা য়ামদে',
                  mizo: 'Subscription nemngheh a hlawhchham',
                  kashmiri: 'سبسکرپشن تصدیٖق گژھنس منٛز ناکام',
                  ladakhi: 'མངགས་ཉོ་བདེན་དཔང་མ་ཐུབ།',
                ),
        );
        if (mounted) {
          setState(() => _directTrialPurchaseBusy = false);
        }
        await showSubscriptionExitVideoPromptIfAvailable(
          context,
          onSubscribe: (_) => _startDirectTrialPurchaseFromFreeExportChoice(),
        );
        return false;
      }

      await outcome.evidence!.completeStorePurchase();
      final refreshed = await _subscriptionBackendService
          .fetchFreshEntitlementWithRetry();
      if (!mounted) {
        return false;
      }
      await _showSubscriptionThanksVideoPromptOnceFromHome(
        refreshed.hasAccess ? refreshed : verification,
      );
      return true;
    } finally {
      if (mounted) {
        setState(() => _directTrialPurchaseBusy = false);
      }
    }
  }

  Future<SubscriptionBackendResult> _verifyDirectTrialPurchaseWithRetry(
    PurchaseVerificationEvidence evidence,
  ) async {
    const delays = <Duration>[
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 6),
    ];
    SubscriptionBackendResult? lastResult;
    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      lastResult = await _subscriptionBackendService.verifyPurchase(
        evidence: evidence,
      );
      if (lastResult.hasAccess) {
        return lastResult;
      }
    }
    return lastResult ??
        const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Subscription verification failed',
        );
  }

  String _directTrialPurchaseMessage(PurchaseFlowResult result) {
    return switch (result) {
      PurchaseFlowResult.pending => context.strings.localized(
        telugu: 'చెల్లింపు పెండింగ్‌లో ఉంది',
        english: 'Payment is pending',
        hindi: 'भुगतान लंबित है',
        tamil: 'பணம் செலுத்துதல் நிலுவையில் உள்ளது',
        kannada: 'ಪಾವತಿ ಬಾಕಿ ಇದೆ',
        malayalam: 'പേയ്‌മെന്റ് തീർപ്പുകൽപ്പിച്ചിട്ടില്ല',
        marathi: 'पेमेंट प्रलंबित आहे',
        gujarati: 'ચુકવણી બાકી છે',
        bengali: 'পেমেন্ট মুলতুবি রয়েছে',
        punjabi: 'ਭੁਗਤਾਨ ਬਕਾਇਆ ਹੈ',
        odia: 'ପେମେଣ୍ଟ୍ ବାକି ଅଛି',
        assamese: 'পৰিশোধ বাকী আছে',
        konkani: 'पेमेंट उरलां',
        nepali: 'भुक्तानी विचाराधीन छ',
        meitei: 'থিবগী থবক লেমহৌরি',
        mizo: 'Pawisa chawi a la pending',
        kashmiri: 'ادائیگی چھِ پینڈِنگ',
        ladakhi: 'དངུལ་སྤྲོད་སྒུག་བཞིན་པ།',
      ),
      PurchaseFlowResult.billingUnavailable => context.strings.localized(
        telugu: 'బిల్లింగ్ సేవ అందుబాటులో లేదు',
        english: 'Billing service is unavailable',
        hindi: 'बिलिंग सेवा उपलब्ध नहीं है',
        tamil: 'பில்லிங் சேவை கிடைக்கவில்லை',
        kannada: 'ಬಿಲ್ಲಿಂಗ್ ಸೇವೆ ಲಭ್ಯವಿಲ್ಲ',
        malayalam: 'ബില്ലിംഗ് സേവനം ലഭ്യമല്ല',
        marathi: 'बिलिंग सेवा उपलब्ध नाही',
        gujarati: 'બિલિંગ સેવા ઉપલબ્ધ નથી',
        bengali: 'বিলিং পরিষেবা অনুপলব্ধ',
        punjabi: 'ਬਿਲਿੰਗ ਸੇਵਾ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
        odia: 'ବିଲିଂ ସେବା ଉପଲବ୍ଧ ନାହିଁ',
        assamese: 'বিলিং সেৱা উপলব্ধ নহয়',
        konkani: 'बिलिंग सेवा उपलब्ध ना',
        nepali: 'बिलिङ सेवा उपलब्ध छैन',
        meitei: 'বিলিং সর্ভিস ফংদে',
        mizo: 'Billing service a awm lo',
        kashmiri: 'بلِنگ سٔروِس چھُنہٕ دستیاب',
        ladakhi: 'དངུལ་རྩིས་ཞབས་ཞུ་མི་འདུག',
      ),
      PurchaseFlowResult.productNotFound => context.strings.localized(
        telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్ కనుగొనబడలేదు',
        english: 'Subscription plan was not found',
        hindi: 'सदस्यता योजना नहीं मिली',
        tamil: 'சந்தா திட்டம் கிடைக்கவில்லை',
        kannada: 'ಚಂದಾದಾರಿಕೆ ಯೋಜನೆ ಕಂಡುಬಂದಿಲ್ಲ',
        malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ പ്ലാൻ കണ്ടെത്തിയില്ല',
        marathi: 'सदस्यता योजना आढळली नाही',
        gujarati: 'સબ્સ્ક્રિપ્શન પ્લાન મળ્યો નથી',
        bengali: 'সাবস্ক্রিপশন প্ল্যান পাওয়া যায়নি',
        punjabi: 'ਗਾਹਕੀ ਪਲਾਨ ਨਹੀਂ ਮਿਲਿਆ',
        odia: 'ସବସ୍କ୍ରିପସନ୍ ପ୍ଲାନ୍ ମିଳିଲା ନାହିଁ',
        assamese: 'চাবস্ক্ৰিপচন প্লেন পোৱা নগ’ল',
        konkani: 'वर्गणी प्लॅन मेळ्ळो ना',
        nepali: 'सदस्यता योजना फेला परेन',
        meitei: 'সবস্ক্রিপসন প্লান ফংদে',
        mizo: 'Subscription plan hmuh a ni lo',
        kashmiri: 'سبسکرپشن پلان آو نہٕ لَبنہٕ',
        ladakhi: 'མངགས་ཉོའི་འཆར་གཞི་མ་རྙེད།',
      ),
      PurchaseFlowResult.timedOut => context.strings.localized(
        telugu: 'చెల్లింపు సమయం ముగిసింది',
        english: 'Payment timed out',
        hindi: 'भुगतान का समय समाप्त हो गया',
        tamil: 'பணம் செலுத்தும் நேரம் முடிந்தது',
        kannada: 'ಪಾವತಿಯ ಸಮಯ ಮೀರಿದೆ',
        malayalam: 'പേയ്‌മെന്റ് സമയം കഴിഞ്ഞു',
        marathi: 'पेमेंट कालबाह्य झाले',
        gujarati: 'ચુકવણી સમય સમાપ્ત થયો',
        bengali: 'পেমেন্টের সময় শেষ হয়েছে',
        punjabi: 'ਭੁਗਤਾਨ ਦਾ ਸਮਾਂ ਸਮਾਪਤ ਹੋ ਗਿਆ',
        odia: 'ପେମେଣ୍ଟ୍ ସମୟ ସରିଗଲା',
        assamese: 'পৰিশোধৰ সময় উকলিল',
        konkani: 'पेमेंटाचो वेळ सोंपलो',
        nepali: 'भुक्तानी समय समाप्त भयो',
        meitei: 'থিবগী মতম লোইখ্রে',
        mizo: 'Pawisa chawi hun a ral',
        kashmiri: 'ادائیگی ہُنٛد وقت گوو ختم',
        ladakhi: 'དངུལ་སྤྲོད་དུས་ཚོད་རྫོགས།',
      ),
      PurchaseFlowResult.purchaseInProgress => context.strings.localized(
        telugu: 'చెల్లింపు ఇప్పటికే పురోగతిలో ఉంది',
        english: 'Payment is already in progress',
        hindi: 'भुगतान पहले से जारी है',
        tamil: 'பணம் செலுத்துதல் ஏற்கனவே செயல்பாட்டில் உள்ளது',
        kannada: 'ಪಾವತಿ ಈಗಾಗಲೇ ಪ್ರಗತಿಯಲ್ಲಿದೆ',
        malayalam: 'പേയ്‌മെന്റ് ഇതിനകം പുരോഗതിയിലാണ്',
        marathi: 'पेमेंट आधीच प्रगतीपथावर आहे',
        gujarati: 'ચુકવણી પહેલેથી જ પ્રક્રિયામાં છે',
        bengali: 'পেমেন্ট ইতিমধ্যেই প্রক্রিয়াধীন রয়েছে',
        punjabi: 'ਭੁਗਤਾਨ ਪਹਿਲਾਂ ਹੀ ਪ੍ਰਕਿਰਿਆ ਵਿੱਚ ਹੈ',
        odia: 'ପେମେଣ୍ଟ୍ ପୂର୍ବରୁ ପ୍ରକ୍ରିୟାଧୀନ ଅଛି',
        assamese: 'পৰিশোধ ইতিমধ্যে চলি আছে',
        konkani: 'पेमेंट पयलींच चालू आसा',
        nepali: 'भुक्तानी पहिले नै जारी छ',
        meitei: 'থিবগী থবক হান্ননা চত্থরি',
        mizo: 'Pawisa chawi mek a ni',
        kashmiri: 'ادائیگی چھِ گۄڈے جٲری',
        ladakhi: 'དངུལ་སྤྲོད་སྔར་ནས་འགྲོ་བཞིན་ཡོད།',
      ),
      _ => context.strings.localized(
        telugu: 'చెల్లింపు పూర్తి కాలేదు',
        english: 'Payment was not completed',
        hindi: 'भुगतान पूरा नहीं हुआ',
        tamil: 'பணம் செலுத்துதல் பூர்த்தியாகவில்லை',
        kannada: 'ಪಾವತಿ ಪೂರ್ಣಗೊಂಡಿಲ್ಲ',
        malayalam: 'പേയ്‌മെന്റ് പൂർത്തിയായില്ല',
        marathi: 'पेमेंट पूर्ण झाले नाही',
        gujarati: 'ચુકવણી પૂર્ણ થઈ નથી',
        bengali: 'পেমেন্ট সম্পন্ন হয়নি',
        punjabi: 'ਭੁਗਤਾਨ ਪੂਰਾ ਨਹੀਂ ਹੋਇਆ',
        odia: 'ପେମେଣ୍ଟ୍ ସମ୍ପୂର୍ଣ୍ଣ ହେଲାନାହିଁ',
        assamese: 'পৰিশোধ সম্পূৰ্ণ নহ’ল',
        konkani: 'पेमेंट पूर्ण जावंक ना',
        nepali: 'भुक्तानी पूरा भएन',
        meitei: 'থিবগী থবক লোইশিনদে',
        mizo: 'Pawisa chawi a zo lo',
        kashmiri: 'ادائیگی سپٕز نہٕ پوٗرٕ',
        ladakhi: 'དངུལ་སྤྲོད་མ་ཚང་།',
      ),
    };
  }

  Future<void> _showSubscriptionThanksVideoPromptOnceFromHome(
    SubscriptionBackendResult result,
  ) async {
    final identity = _subscriptionThanksPromptIdentity(result);
    if (identity == null) {
      await showSubscriptionThanksVideoPromptIfAvailable(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _subscriptionThanksPromptSeenKey(result);
    if (prefs.getString(key) == identity || !mounted) {
      return;
    }

    await showSubscriptionThanksVideoPromptIfAvailable(context);
    if (!mounted) {
      return;
    }
    await prefs.setString(key, identity);
  }

  String _subscriptionThanksPromptSeenKey(SubscriptionBackendResult result) {
    final authUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final latestOrderId = result.latestOrderId?.trim() ?? '';
    final identityScope = authUid.isNotEmpty ? authUid : latestOrderId;
    final resolvedScope = identityScope.isNotEmpty ? identityScope : 'anon';
    return 'subscription_thanks_video_seen_v1_$resolvedScope';
  }

  String? _subscriptionThanksPromptIdentity(SubscriptionBackendResult result) {
    if (!result.hasAccess) {
      return null;
    }
    final latestOrderId = result.latestOrderId?.trim() ?? '';
    final subscriptionState = result.subscriptionState?.trim() ?? '';
    final startEpoch =
        result.startDate?.millisecondsSinceEpoch.toString() ?? '';
    final expiryEpoch =
        result.expiryTime?.millisecondsSinceEpoch.toString() ?? '';
    final identity = <String>[
      latestOrderId,
      subscriptionState,
      startEpoch,
      expiryEpoch,
    ].where((value) => value.isNotEmpty).join('|');
    return identity.isEmpty ? null : identity;
  }

  Future<bool> _hasSubscriptionAccessForExport() async {
    if (_hasImmediateSubscriptionAccess()) {
      unawaited(_subscriptionBackendService.refreshEntitlementInBackground());
      return true;
    }
    if (!_shouldRunBlockingSubscriptionStatusCheck()) {
      return false;
    }
    return _resolveLatestSubscriptionAccess().timeout(
      const Duration(milliseconds: 400),
      onTimeout: () async => false,
    );
  }

  String _homePosterShareText() {
    final resolvedUserName = viewerPosterProfile.activeName.trim().isNotEmpty
        ? viewerPosterProfile.activeName.trim()
        : (viewerPosterProfile
                  .resolvedName(language: language)
                  .trim()
                  .isNotEmpty
              ? viewerPosterProfile.resolvedName(language: language).trim()
              : 'User');
    return 'Shared by $resolvedUserName using ${AppPublicInfo.appName}\n'
        'Download the app: ${AppPublicInfo.playStoreUrl}';
  }

  void _recordPosterExportEngagement({required bool isShare}) {
    _bumpLocalEngagementCount(isShare ? 'share' : 'download');
    widget.onInteraction?.call(item, isShare ? 'share' : 'download');
    final posterId = item.templateId?.trim();
    if (posterId == null || posterId.isEmpty) {
      return;
    }
    unawaited(
      ApprovedCreatorTemplateService().incrementPosterEngagementCount(
        posterId: posterId,
        isShare: isShare,
        creatorPublicId: item.creatorPublicId ?? '',
        posterTitle: item.titleEn,
        categoryId: item.primaryFirestoreCategoryId ?? '',
        categoryLabel: item.categoryDisplayLabel ?? '',
      ),
    );
    unawaited(
      UserPosterUploadsService.instance
          .incrementApprovedContributionCountForPoster(
            approvedPosterTemplateId: posterId,
            isShare: isShare,
          ),
    );
  }

  String _downloadSaveFailureMessage(
    BuildContext context,
    MediaExportResult result,
  ) {
    switch (result.code) {
      case 'permission_denied':
        return context.strings.localized(
          telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
          english: 'Gallery permission was denied.',
          hindi: 'गैलरी की अनुमति अस्वीकार कर दी गई।',
          tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
          kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ.',
          malayalam: 'ഗാലറി അനുമതി നിരസിച്ചു.',
          marathi: 'गॅलरी परवानगी नाकारली गेली.',
          gujarati: 'ગેલેરી પરવાનગી નકારી દેવામાં આવી.',
          bengali: 'গ্যালারির অনুমতি প্রত্যাখ্যান করা হয়েছে।',
          punjabi: 'ਗੈਲਰੀ ਦੀ ਇਜਾਜ਼ਤ ਅਸਵੀਕਾਰ ਕਰ ਦਿੱਤੀ ਗਈ।',
          odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଗଲା।',
          assamese: 'গেলাৰীৰ অনুমতি নাকচ কৰা হ’ল।',
          konkani: 'गॅलरीची परवानगी नाकारली.',
          nepali: 'ग्यालरी अनुमति अस्वीकार गरियो।',
          meitei: 'গেলরিগী অয়াবা যাদে।',
          mizo: 'Gallery phalna hnar a ni.',
          kashmiri: 'گیلری ہٕنز اجازت مسترد کرنہٕ آمٕژ۔',
          ladakhi: 'གྱེལ་རིའི་ཆོག་མཆན་དང་ལེན་མ་བྱས།',
        );
      case 'file_missing':
      case 'write_failed':
      case 'open_output_failed':
      case 'media_insert_failed':
      case 'directory_create_failed':
      case 'save_failed':
      case 'platform_exception':
      case 'empty_result':
        return context.strings.localized(
          telugu: 'ఫైల్ సేవ్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'File save failed. Please try again.',
          hindi: 'फ़ाइल सेव नहीं हो सकी। कृपया फिर से प्रयास करें।',
          tamil: 'கோப்பை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ಫೈಲ್ ಉಳಿಸಲಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'ഫയൽ സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'फाइल सेव्ह झाली नाही. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'ફાઇલ સાચવી શકાઈ નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali: 'ফাইল সেভ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi: 'ਫਾਈਲ ਸੇਵ ਨਹੀਂ ਹੋਈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଫାଇଲ୍ ସେଭ୍ ହୋଇନି। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'ফাইল সংৰক্ষণ নহ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'फायल सेव्ह जाली ना. उपकार करून परत यत्न करात.',
          nepali: 'फाइल सेभ भएन। कृपया फेरि प्रयास गर्नुहोस्।',
          meitei: 'ফাইল সেভ তৌবা যামদে। চানবিদুনা অমুক চেষ্টা তৌবিয়ু।',
          mizo: 'File dahthat a hlawhchham. Khawngaihin ti nawn leh rawh.',
          kashmiri: 'فائل محفوظ نہٕ گژھ۔ مہربانی کٔرتھ دوبار کوشش کٔریو۔',
          ladakhi: 'ཡིག་སྣོད་ཉར་མ་ཐུབ། ཡང་བསྐྱར་འབད་གནང་།',
        );
      default:
        return context.strings.localized(
          telugu: 'డౌన్‌లోడ్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'Download failed. Please try again.',
          hindi: 'डाउनलोड नहीं हो सका। कृपया फिर से प्रयास करें।',
          tamil: 'பதிவிறக்கம் முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ಡೌನ್‌ಲೋಡ್ ಆಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'ഡൗൺലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'डाउनलोड झाले नाही. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'ડાઉનલોડ થઈ શક્યું નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali: 'ডাউনলোড করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi: 'ਡਾਊਨਲੋਡ ਨਹੀਂ ਹੋਇਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଡାଉନଲୋଡ୍ ହୋଇନି। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'ডাউনলোড নহ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'डाउनलोड जालें ना. उपकार करून परत यत्न करात.',
          nepali: 'डाउनलोड भएन। कृपया फेरि प्रयास गर्नुहोस्।',
          meitei: 'দাউনলোদ তৌবা যামদে। চানবিদুনা অমুক চেষ্টা তৌবিয়ু।',
          mizo: 'Download a hlawhchham. Khawngaihin ti nawn leh rawh.',
          kashmiri: 'ڈاؤنلوڈ نہٕ گژھ۔ مہربانی کٔرتھ دوبار کوشش کٔریو۔',
          ladakhi: 'ཕབ་ལེན་མ་ཐུབ། ཡང་བསྐྱར་འབད་གནང་།',
        );
    }
  }

  Future<bool> _ensureSubscriptionAccess(BuildContext context) async {
    final BuildContext screenContext = hostContext;
    if (_hasImmediateSubscriptionAccess()) {
      unawaited(_subscriptionBackendService.refreshEntitlementInBackground());
      return true;
    }
    if (_shouldRunBlockingSubscriptionStatusCheck()) {
      final hasLatestAccess = await _resolveLatestSubscriptionAccess().timeout(
        SubscriptionPlanConfig.paywallTimeout,
        onTimeout: () async => false,
      );
      if (!screenContext.mounted) {
        return false;
      }
      if (hasLatestAccess) {
        return true;
      }
    }
    if (_legacySubscriptionStatusPopupEnabled &&
        _shouldRunBlockingSubscriptionStatusCheck()) {
      final navigator = Navigator.of(context, rootNavigator: true);
      var loadingDialogDismissed = false;
      unawaited(
        showDialog<void>(
          context: screenContext,
          barrierDismissible: false,
          useRootNavigator: true,
          barrierColor: Colors.black54,
          builder: (BuildContext dialogContext) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                content: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        screenContext.strings.localized(
                          telugu:
                              'సబ్‌స్క్రిప్షన్ స్థితిని తనిఖీ చేస్తున్నాము...',
                          english: 'Checking subscription status...',
                          hindi: 'सदस्यता स्थिति की जाँच की जा रही है...',
                          tamil: 'சந்தா நிலை சரிபார்க்கப்படுகிறது...',
                          kannada:
                              'ಚಂದಾದಾರಿಕೆ ಸ್ಥಿತಿಯನ್ನು ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
                          malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ നില പരിശോധിക്കുന്നു...',
                          marathi: 'सदस्यता स्थिती तपासत आहे...',
                          gujarati: 'સબ્સ્ક્રિપ્શન સ્થિતિ તપાસી રહ્યાં છીએ...',
                          bengali: 'সাবস্ক্রিপশনের স্থিতি পরীক্ষা করা হচ্ছে...',
                          punjabi: 'ਗਾਹਕੀ ਸਥਿਤੀ ਦੀ ਜਾਂਚ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ...',
                          odia: 'ସବସ୍କ୍ରିପସନ୍ ସ୍ଥିତି ଯାଞ୍ଚ କରାଯାଉଛି...',
                          assamese: 'চাবস্ক্ৰিপচনৰ স্থিতি পৰীক্ষা কৰা হৈছে...',
                          konkani: 'वर्गणी स्थिती तपासतात...',
                          nepali: 'सदस्यता स्थिति जाँच गरिँदैछ...',
                          meitei: 'সবস্ক্রিপসন ফীভম য়েংশিল্লি...',
                          mizo: 'Subscription dinhmun en dik mek a ni...',
                          kashmiri: 'سبسکرپشن کِس حالَتُک جائزہ نِوان...',
                          ladakhi: 'མངགས་ཉོའི་གནས་སྟངས་ཞིབ་བཤེར་བྱེད་བཞིན་པ...',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      loadingDialogDismissed = true;
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      screenContext.strings.localized(
                        telugu: 'రద్దు',
                        english: 'Cancel',
                        hindi: 'रद्द करें',
                        tamil: 'ரத்துசெய்',
                        kannada: 'ರದ್ದುಮಾಡಿ',
                        malayalam: 'റദ്ദാക്കുക',
                        marathi: 'रद्द करा',
                        gujarati: 'રદ કરો',
                        bengali: 'বাতিল',
                        punjabi: 'ਰੱਦ ਕਰੋ',
                        odia: 'ବାତିଲ୍ କରନ୍ତୁ',
                        assamese: 'বাতিল কৰক',
                        konkani: 'रद्द करा',
                        nepali: 'रद्द गर्नुहोस्',
                        meitei: 'তৌদবা',
                        mizo: 'Sutna',
                        kashmiri: 'منسوخ',
                        ladakhi: 'ཕྱིར་འཐེན།',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
      try {
        if (loadingDialogDismissed) {
          return false;
        }
        final hasLatestAccess = await _resolveLatestSubscriptionAccess()
            .timeout(
              SubscriptionPlanConfig.paywallTimeout,
              onTimeout: () async => false,
            );
        if (!screenContext.mounted || loadingDialogDismissed) {
          return false;
        }
        if (hasLatestAccess) {
          return true;
        }
      } finally {
        if (!loadingDialogDismissed &&
            screenContext.mounted &&
            navigator.canPop()) {
          navigator.pop();
        }
      }
    }
    _homeDebugLog('subscription access check: backendResponse.isPro=false');
    if (!screenContext.mounted) {
      return false;
    }
    final openPlan = await showModalBottomSheet<bool>(
      context: screenContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: _SubscriptionAccessDialog(
            message: screenContext.strings.monthlyPlanStartsFromFour,
            trialTitle: _subscriptionTrialTitleAppLocalized(screenContext),
            trialValue: _subscriptionTrialValueAppLocalized(screenContext),
            monthlyTitle: _subscriptionMonthlyTitleAppLocalized(screenContext),
            monthlyValue: _subscriptionMonthlyValueAppLocalized(screenContext),
            renewalCopy: _subscriptionRenewalCopyAppLocalized(screenContext),
            termsLabel: _subscriptionTermsLabelAppLocalized(screenContext),
            skipLabel: _subscriptionSkipLabelAppLocalized(screenContext),
            actionLabel: _subscriptionButtonLabelAppLocalized(screenContext),
            onTermsTap: () =>
                _openExternalPublicUrl(dialogContext, AppPublicInfo.termsUrl),
            onSkipTap: () => Navigator.of(dialogContext).pop(false),
            onConfirmTap: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    );

    if (!screenContext.mounted) {
      return false;
    }
    if (openPlan != true) {
      await showSubscriptionExitVideoPromptIfAvailable(
        screenContext,
        onSubscribe: (_) => onOpenSubscriptionPlan(startPurchaseOnOpen: true),
      );
      return false;
    }
    await onOpenSubscriptionPlan(startPurchaseOnOpen: true);
    if (!screenContext.mounted) {
      return false;
    }
    final hasAccess = await _resolveLatestSubscriptionAccess();
    if (!screenContext.mounted || hasAccess) {
      return hasAccess;
    }
    await showSubscriptionExitVideoPromptIfAvailable(
      screenContext,
      onSubscribe: (_) => onOpenSubscriptionPlan(startPurchaseOnOpen: true),
    );
    return false;
  }

  // ignore: unused_element
  String _freeExportWithPhotoTitle(BuildContext context) =>
      context.strings.localized(
        telugu: 'ఫోటో మరియు పేరుతో',
        english: 'With photo and name',
        hindi: 'फोटो और नाम के साथ',
        tamil: 'புகைப்படம் மற்றும் பெயருடன்',
        kannada: 'ಫೋಟೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ',
        malayalam: 'ഫോട്ടോയും പേരും ചേർത്ത്',
        assamese: 'ফটো আৰু নামৰ সৈতে',
        konkani: 'फोटो आनी नांवासयत',
        gujarati: 'ફોટો અને નામ સાથે',
        marathi: 'फोटो आणि नावासह',
        meitei: 'Photo amasung mingga',
        mizo: 'Photo leh hming nen',
        odia: 'ଫଟୋ ଏବଂ ନାମ ସହିତ',
        punjabi: 'ਫੋਟੋ ਅਤੇ ਨਾਮ ਨਾਲ',
        nepali: 'फोटो र नामसहित',
        bengali: 'ছবি ও নামসহ',
        kashmiri: 'فوٹو تہ ناو سٲتھ',
        ladakhi: 'Photo dang ming che',
      );

  // ignore: unused_element
  String _freeExportWithPhotoMessage(BuildContext context) =>
      context.strings.localized(
        telugu: 'ఫోటో, పేరుతో షేర్ చేయండి',
        english: 'Share with photo and name',
        hindi: 'फोटो और नाम के साथ शेयर करें',
        tamil: 'புகைப்படம் மற்றும் பெயருடன் பகிரவும்',
        kannada: 'ಫೋಟೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಿ',
        malayalam: 'ഫോട്ടോയും പേരും ചേർത്ത് ഷെയർ ചെയ്യുക',
        assamese: 'ফটো আৰু নামৰ সৈতে শ্বেয়াৰ কৰক',
        konkani: 'फोटो आनी नांवासयत शेयर करात',
        gujarati: 'ફોટો અને નામ સાથે શેર કરો',
        marathi: 'फोटो आणि नावासह शेअर करा',
        meitei: 'Photo amasung mingga share tou',
        mizo: 'Photo leh hming nen share rawh',
        odia: 'ଫଟୋ ଏବଂ ନାମ ସହିତ ଶେୟାର କରନ୍ତୁ',
        punjabi: 'ਫੋਟੋ ਅਤੇ ਨਾਮ ਨਾਲ ਸ਼ੇਅਰ ਕਰੋ',
        nepali: 'फोटो र नामसहित शेयर गर्नुहोस्',
        bengali: 'ছবি ও নামসহ শেয়ার করুন',
        kashmiri: 'فوٹو تہ ناو سٲتھ شیئر کریو',
        ladakhi: 'Photo dang ming che share byed',
      );

  // ignore: unused_element
  String _freeExportTrialPlanLabel(BuildContext context) {
    final price = SubscriptionPlanConfig.trialPriceDisplay;
    return context.strings.localized(
      telugu: '$price ట్రయల్ ప్లాన్',
      english: '$price Trial plan',
      hindi: '$price ट्रायल प्लान',
      tamil: '$price ட்ரயல் திட்டம்',
      kannada: '$price ಟ್ರಯಲ್ ಪ್ಲಾನ್',
      malayalam: '$price ട്രയൽ പ്ലാൻ',
      assamese: '$price ট্ৰায়েল প্লেন',
      konkani: '$price ट्रायल प्लॅन',
      gujarati: '$price ટ્રાયલ પ્લાન',
      marathi: '$price ट्रायल प्लॅन',
      meitei: '$price Trial plan',
      mizo: '$price Trial plan',
      odia: '$price ଟ୍ରାୟାଲ ପ୍ଲାନ',
      punjabi: '$price ਟ੍ਰਾਇਲ ਪਲਾਨ',
      nepali: '$price ट्रायल प्लान',
      bengali: '$price ট্রায়াল প্ল্যান',
      kashmiri: '$price ٹرائل پلان',
      ladakhi: '$price Trial plan',
    );
  }

  // ignore: unused_element
  String _freeExportPlainTitle(BuildContext context) =>
      context.strings.localized(
        telugu: 'ఉచితంగా షేర్ చేయండి',
        english: 'Share free',
        hindi: 'मुफ्त शेयर करें',
        tamil: 'இலவசமாக பகிரவும்',
        kannada: 'ಉಚಿತವಾಗಿ ಹಂಚಿಕೊಳ್ಳಿ',
        malayalam: 'സൗജന്യമായി ഷെയർ ചെയ്യുക',
        assamese: 'বিনামূল্যে শ্বেয়াৰ কৰক',
        konkani: 'फुकट शेयर करात',
        gujarati: 'મફતમાં શેર કરો',
        marathi: 'मोफत शेअर करा',
        meitei: 'Free oina share tou',
        mizo: 'Free-a share rawh',
        odia: 'ମାଗଣାରେ ଶେୟାର କରନ୍ତୁ',
        punjabi: 'ਮੁਫ਼ਤ ਸ਼ੇਅਰ ਕਰੋ',
        nepali: 'निःशुल्क शेयर गर्नुहोस्',
        bengali: 'ফ্রি শেয়ার করুন',
        kashmiri: 'مفت شیئر کریو',
        ladakhi: 'Free share byed',
      );

  // ignore: unused_element
  String _freeExportPlainMessage(BuildContext context) =>
      context.strings.localized(
        telugu: 'పేరు, ఫోటో లేకుండా పోస్టర్ మాత్రమే',
        english: 'Poster only, without name and photo',
        hindi: 'केवल पोस्टर, नाम और फोटो के बिना',
        tamil: 'பெயரும் புகைப்படமும் இல்லாமல் போஸ்டர் மட்டும்',
        kannada: 'ಹೆಸರು, ಫೋಟೋ ಇಲ್ಲದೆ ಪೋಸ್ಟರ್ ಮಾತ್ರ',
        malayalam: 'പേരും ഫോട്ടോയും ഇല്ലാതെ പോസ്റ്റർ മാത്രം',
        assamese: 'নাম আৰু ফটো নোহোৱাকৈ কেৱল পোষ্টাৰ',
        konkani: 'नांव आनी फोटो नासतना फकत पोस्टर',
        gujarati: 'નામ અને ફોટો વગર માત્ર પોસ્ટર',
        marathi: 'नाव आणि फोटोशिवाय फक्त पोस्टर',
        meitei: 'Ming amasung photo yaodana poster khaktang',
        mizo: 'Hming leh photo tel lo poster chauh',
        odia: 'ନାମ ଏବଂ ଫଟୋ ବିନା କେବଳ ପୋଷ୍ଟର',
        punjabi: 'ਨਾਮ ਅਤੇ ਫੋਟੋ ਬਿਨਾਂ ਸਿਰਫ਼ ਪੋਸਟਰ',
        nepali: 'नाम र फोटो बिना पोस्टर मात्र',
        bengali: 'নাম ও ছবি ছাড়া শুধু পোস্টার',
        kashmiri: 'ناو تہ فوٹو بغیر صرف پوسٹر',
        ladakhi: 'Ming dang photo medpa poster tsam',
      );

  String _freeExportFourRupeesTrialLabel(BuildContext context) =>
      context.strings.localized(
        telugu: '₹4 ట్రయల్',
        english: '₹4 trial',
        hindi: '₹4 ट्रायल',
        tamil: '₹4 சோதனை',
        kannada: '₹4 ಟ್ರಯಲ್',
        malayalam: '₹4 ട്രയൽ',
        assamese: '₹4 ট্ৰায়েল',
        konkani: '₹4 ट्रायल',
        gujarati: '₹4 ટ્રાયલ',
        marathi: '₹4 ट्रायल',
        meitei: '₹4 trial',
        mizo: '₹4 trial',
        odia: '₹4 ଟ୍ରାଏଲ୍',
        punjabi: '₹4 ਟ੍ਰਾਇਲ',
        nepali: '₹4 ट्रायल',
        bengali: '₹4 ট্রায়াল',
        kashmiri: '₹4 ٹرائل',
        ladakhi: '₹4 trial',
      );

  // ignore: unused_element
  String _freeExportDownloadLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'డౌన్‌లోడ్',
        english: 'Download',
        hindi: 'डाउनलोड',
        tamil: 'பதிவிறக்கம்',
        kannada: 'ಡೌನ್‌ಲೋಡ್',
        malayalam: 'ഡൗൺലോഡ്',
        assamese: 'ডাউনলোড',
        konkani: 'डाउनलोड',
        gujarati: 'ડાઉનલોડ',
        marathi: 'डाउनलोड',
        meitei: 'Download',
        mizo: 'Download',
        odia: 'ଡାଉନଲୋଡ୍',
        punjabi: 'ਡਾਊਨਲੋਡ',
        nepali: 'डाउनलोड',
        bengali: 'ডাউনলোড',
        kashmiri: 'ڈاؤنلوڈ',
        ladakhi: 'Download',
      );

  // ignore: unused_element
  String _freeExportShareLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'షేర్',
        english: 'Share',
        hindi: 'शेयर',
        tamil: 'பகிர்',
        kannada: 'ಹಂಚಿಕೆ',
        malayalam: 'ഷെയർ',
        assamese: 'শ্বেয়াৰ',
        konkani: 'शेयर',
        gujarati: 'શેર',
        marathi: 'शेअर',
        meitei: 'Share',
        mizo: 'Share',
        odia: 'ଶେୟାର',
        punjabi: 'ਸ਼ੇਅਰ',
        nepali: 'शेयर',
        bengali: 'শেয়ার',
        kashmiri: 'شیئر',
        ladakhi: 'Share',
      );

  Future<_FreeExportChoice> _showFreeExportChoiceSheet(
    BuildContext context, {
    required bool preferShare,
  }) async {
    if (!context.mounted) {
      return _FreeExportChoice.none;
    }
    await ScreenSecurityService.protectScreen(adminOnlyBypass: true);
    try {
      if (!context.mounted) {
        return _FreeExportChoice.none;
      }
      final autoRenewNote = context.strings.localized(
        telugu:
            'ఎప్పుడైనా రద్దు చేయవచ్చు. సబ్‌స్క్రిప్షన్ ఆటో-రీన్యూ అవుతుంది.',
        english: 'Cancel anytime. Subscription auto-renews.',
        hindi: 'कभी भी रद्द करें। सदस्यता अपने आप नवीनीकृत होती है।',
        tamil:
            'எப்போது வேண்டுமானாலும் ரத்து செய்யலாம். சந்தா தானாக புதுப்பிக்கும்.',
        kannada: 'ಯಾವಾಗ ಬೇಕಾದರೂ ರದ್ದುಮಾಡಿ. ಚಂದಾ ಸ್ವಯಂ ನವೀಕರಿಸುತ್ತದೆ.',
        malayalam: 'എപ്പോഴും റദ്ദാക്കാം. സബ്സ്ക്രിപ്ഷൻ സ്വയം പുതുക്കും.',
        assamese:
            'যিকোনো সময় বাতিল কৰিব পাৰে। সদস্যতা স্বয়ংক্ৰিয়ভাৱে নবীকৰণ হয়।',
        konkani: 'केन्नाय रद्द करात. सदस्यता आपोआप नूतनीकरण जाता.',
        gujarati: 'ક્યારેય પણ રદ કરો. સબ્સ્ક્રિપ્શન આપમેળે રિન્યૂ થાય છે.',
        marathi: 'कधीही रद्द करा. सदस्यता आपोआप नूतनीकरण होते.',
        meitei: 'Matam amada cancel tou. Subscription auto-renew tougani.',
        mizo: 'Engtik lai pawhin cancel theih. Subscription auto-renew ang.',
        odia: 'ଯେକେବେଳେ ଚାହିଲେ ବାତିଲ୍ କରନ୍ତୁ। ସବସ୍କ୍ରିପ୍ସନ୍ ସ୍ୱୟଂ ନବୀକରଣ ହୁଏ।',
        punjabi: 'ਕਦੇ ਵੀ ਰੱਦ ਕਰੋ। ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਆਪਣੇ ਆਪ ਰਿਨਿਊ ਹੁੰਦੀ ਹੈ।',
        nepali: 'जुनसुकै बेला रद्द गर्नुहोस्। सदस्यता स्वतः नवीकरण हुन्छ।',
        bengali: 'যেকোনো সময় বাতিল করুন। সাবস্ক্রিপশন নিজে থেকেই নবায়ন হয়।',
        kashmiri:
            'کُنہِ تہ وقتس منٛز کینسل کٔرِو۔ سبسکرپشن خود بخود نوٚو گژھان چھ۔',
        ladakhi: 'Nam yang cancel byed. Subscription auto-renew byed.',
      );
      final subscriptionTermsLinkLabel = context.strings.localized(
        telugu: 'నిబంధనలు, రీఫండ్ మరియు రద్దు',
        english: 'Terms, refund and cancellation',
        hindi: 'नियम, रिफंड और रद्दीकरण',
        tamil: 'விதிமுறைகள், பணத்தீர்ப்பு மற்றும் ரத்து',
        kannada: 'ನಿಯಮಗಳು, ರಿಫಂಡ್ ಮತ್ತು ರದ್ದು',
        malayalam: 'നിബന്ധനകൾ, റീഫണ്ട്, റദ്ദാക്കൽ',
        assamese: 'চৰ্ত, ৰিফাণ্ড আৰু বাতিলকৰণ',
        konkani: 'अटी, रिफंड आनी रद्द करप',
        gujarati: 'શરતો, રિફંડ અને રદ કરવું',
        marathi: 'अटी, रिफंड आणि रद्द करणे',
        meitei: 'Terms, refund amasung cancellation',
        mizo: 'Terms, refund leh cancellation',
        odia: 'ସର୍ତ୍ତାବଳୀ, ରିଫଣ୍ଡ ଏବଂ ବାତିଲ୍',
        punjabi: 'ਨਿਯਮ, ਰਿਫੰਡ ਅਤੇ ਰੱਦ ਕਰਨਾ',
        nepali: 'सर्त, रिफन्ड र रद्द',
        bengali: 'শর্ত, রিফান্ড ও বাতিল',
        kashmiri: 'شرطن، ریفنڈ تہٕ کینسلیشن',
        ladakhi: 'Terms, refund dang cancellation',
      );
      if (!context.mounted) {
        return _FreeExportChoice.none;
      }
      // ignore: unused_local_variable
      final title = context.strings.localized(
        telugu: 'సబ్‌స్క్రైబ్ చేసి పోస్టర్ ఉపయోగించండి',
        english: 'Subscribe to use this poster',
        hindi: 'इस पोस्टर का उपयोग करने के लिए सब्सक्राइब करें',
        tamil: 'இந்த போஸ்டரை பயன்படுத்த சந்தா செலுத்துங்கள்',
        kannada: 'ಈ ಪೋಸ್ಟರ್ ಬಳಸಲು ಸಬ್‌ಸ್ಕ್ರೈಬ್ ಮಾಡಿ',
        malayalam: 'ഈ പോസ്റ്റർ ഉപയോഗിക്കാൻ സബ്സ്ക്രൈബ് ചെയ്യുക',
        assamese: 'এই পোষ্টাৰ ব্যৱহাৰ কৰিবলৈ চাবস্ক্ৰাইব কৰক',
        konkani: 'हो पोस्टर वापरपाक सबस्क्राइब करात',
        gujarati: 'આ પોસ્ટર વાપરવા માટે સબ્સ્ક્રાઇબ કરો',
        marathi: 'हा पोस्टर वापरण्यासाठी सबस्क्राइब करा',
        meitei: 'Poster asi sijinnaba subscribe tou',
        mizo: 'He poster hman turin subscribe rawh',
        odia: 'ଏହି ପୋଷ୍ଟର ବ୍ୟବହାର ପାଇଁ ସବସ୍କ୍ରାଇବ କରନ୍ତୁ',
        punjabi: 'ਇਹ ਪੋਸਟਰ ਵਰਤਣ ਲਈ ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ',
        nepali: 'यो पोस्टर प्रयोग गर्न सदस्यता लिनुहोस्',
        bengali: 'এই পোস্টার ব্যবহার করতে সাবস্ক্রাইব করুন',
        kashmiri: 'یہ پوسٹر استعمال کرنہ خٲطر سبسکرائب کریو',
        ladakhi: 'Poster di use bya la subscribe byed',
      );
      // ignore: unused_local_variable
      final message = context.strings.localized(
        telugu:
            'మీ ఫోటో, పేరుతో పోస్టర్‌ను డౌన్‌లోడ్ లేదా షేర్ చేయడానికి సబ్‌స్క్రైబ్ చేయండి.',
        english:
            'Subscribe to download or share this poster with your photo and name.',
        hindi:
            'अपनी फोटो और नाम के साथ इस पोस्टर को डाउनलोड या शेयर करने के लिए सब्सक्राइब करें।',
        tamil:
            'உங்கள் புகைப்படம் மற்றும் பெயருடன் இந்த போஸ்டரை பதிவிறக்கம் அல்லது பகிர சந்தா செலுத்துங்கள்.',
        kannada:
            'ನಿಮ್ಮ ಫೋಟೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ ಈ ಪೋಸ್ಟರ್ ಡೌನ್‌ಲೋಡ್ ಅಥವಾ ಶೇರ್ ಮಾಡಲು ಸಬ್‌ಸ್ಕ್ರೈಬ್ ಮಾಡಿ.',
        malayalam:
            'നിങ്ങളുടെ ഫോട്ടോയും പേരും ചേർത്ത് ഈ പോസ്റ്റർ ഡൗൺലോഡ് അല്ലെങ്കിൽ ഷെയർ ചെയ്യാൻ സബ്സ്ക്രൈബ് ചെയ്യുക.',
        assamese:
            'আপোনাৰ ফটো আৰু নামৰ সৈতে এই পোষ্টাৰ ডাউনলোড বা শ্বেয়াৰ কৰিবলৈ চাবস্ক্ৰাইব কৰক।',
        konkani:
            'तुमच्या फोटो आनी नांवासयत हो पोस्टर डाउनलोड वा शेयर करपाक सबस्क्राइब करात.',
        gujarati:
            'તમારા ફોટો અને નામ સાથે આ પોસ્ટર ડાઉનલોડ અથવા શેર કરવા માટે સબ્સ્ક્રાઇબ કરો.',
        marathi:
            'तुमचा फोटो आणि नावासह हा पोस्टर डाउनलोड किंवा शेअर करण्यासाठी सबस्क्राइब करा.',
        meitei:
            'Nakhoigi photo amasung mingga poster asi download/share tounaba subscribe tou.',
        mizo:
            'I photo leh hming nen he poster download/share turin subscribe rawh.',
        odia:
            'ଆପଣଙ୍କ ଫଟୋ ଏବଂ ନାମ ସହ ଏହି ପୋଷ୍ଟର ଡାଉନଲୋଡ୍ କିମ୍ବା ସେୟାର ପାଇଁ ସବସ୍କ୍ରାଇବ କରନ୍ତୁ।',
        punjabi:
            'ਆਪਣੀ ਫੋਟੋ ਅਤੇ ਨਾਮ ਨਾਲ ਇਹ ਪੋਸਟਰ ਡਾਊਨਲੋਡ ਜਾਂ ਸ਼ੇਅਰ ਕਰਨ ਲਈ ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ।',
        nepali:
            'आफ्नो फोटो र नामसहित यो पोस्टर डाउनलोड वा शेयर गर्न सदस्यता लिनुहोस्।',
        bengali:
            'আপনার ছবি ও নামসহ এই পোস্টার ডাউনলোড বা শেয়ার করতে সাবস্ক্রাইব করুন।',
        kashmiri:
            'پنُن فوٹو تہ ناو سٲتھ یہ پوسٹر ڈاؤنلوڈ یا شیئر کرنہ خٲطر سبسکرائب کریو۔',
        ladakhi:
            'Rang gi photo dang ming che poster download/share bya la subscribe byed.',
      );
      // ignore: unused_local_variable
      final continueLabel = context.strings.localized(
        telugu: 'కొనసాగించండి',
        english: 'Continue',
        hindi: 'जारी रखें',
        tamil: 'தொடரவும்',
        kannada: 'ಮುಂದುವರಿಸಿ',
        malayalam: 'തുടരുക',
        assamese: 'আগবাঢ়ক',
        konkani: 'मुखार वचात',
        gujarati: 'આગળ વધો',
        marathi: 'पुढे जा',
        meitei: 'Continue tou',
        mizo: 'Continue rawh',
        odia: 'ଆଗକୁ ଯାଆନ୍ତୁ',
        punjabi: 'ਜਾਰੀ ਰੱਖੋ',
        nepali: 'जारी राख्नुहोस्',
        bengali: 'চালিয়ে যান',
        kashmiri: 'جاری تھأیو',
        ladakhi: 'Continue byed',
      );
      // ignore: unused_local_variable
      final posterLabel = context.strings.localized(
        telugu: 'ఎంచుకున్న పోస్టర్',
        english: 'Selected poster',
        hindi: 'चुना गया पोस्टर',
        tamil: 'தேர்ந்தெடுத்த போஸ்டர்',
        kannada: 'ಆಯ್ಕೆ ಮಾಡಿದ ಪೋಸ್ಟರ್',
        malayalam: 'തിരഞ്ഞെടുത്ത പോസ്റ്റർ',
        assamese: 'বাছনি কৰা পোষ্টাৰ',
        konkani: 'वेंचिल्लो पोस्टर',
        gujarati: 'પસંદ કરેલું પોસ્ટર',
        marathi: 'निवडलेला पोस्टर',
        meitei: 'Khanbiba poster',
        mizo: 'Poster thlan',
        odia: 'ଚୟନିତ ପୋଷ୍ଟର',
        punjabi: 'ਚੁਣਿਆ ਪੋਸਟਰ',
        nepali: 'चयन गरिएको पोस्टर',
        bengali: 'নির্বাচিত পোস্টার',
        kashmiri: 'ژارنہ آمُت پوسٹر',
        ladakhi: 'Selected poster',
      );
      final posterTitle = item.titleFor(language).trim().isNotEmpty
          ? item.titleFor(language).trim()
          : item.titleEn.trim();
      final previewAspectRatio =
          _resolvedPreviewAspectRatio ??
          item.pageConfig?.aspectRatio ??
          (item.isVideo ? 9 / 16 : 4 / 5);
      final existingPaidPath = _preparedPosterFilePath;
      final paidPreviewPath =
          (!item.isVideo &&
              existingPaidPath != null &&
              File(existingPaidPath).existsSync())
          ? existingPaidPath
          : null;
      const String? plainPreviewPath = null;
      if (!item.isVideo) {
        unawaited(_ensurePreparedPlainPosterFile());
      }
      if (!context.mounted) {
        return _FreeExportChoice.none;
      }
      final premiumHeading = context.strings.localized(
        telugu: 'లోగో మరియు పేరుతో (ప్రీమియం ఫీచర్)',
        english: 'With logo and name (premium feature)',
        hindi: 'लोगो और नाम के साथ (प्रीमियम फीचर)',
        tamil: 'லோகோ மற்றும் பெயருடன் (பிரீமியம் அம்சம்)',
        kannada: 'ಲೋಗೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ (ಪ್ರೀಮಿಯಂ ವೈಶಿಷ್ಟ್ಯ)',
        malayalam: 'ലോഗോയും പേരും സഹിതം (പ്രീമിയം ഫീച്ചർ)',
        assamese: 'ল’গ’ আৰু নামৰ সৈতে (প্ৰিমিয়াম সুবিধা)',
        konkani: 'लोगो आनी नांवासयत (प्रीमियम फीचर)',
        gujarati: 'લોગો અને નામ સાથે (પ્રીમિયમ ફીચર)',
        marathi: 'लोगो आणि नावासह (प्रीमियम फीचर)',
        meitei: 'Logo amasung mingga (premium feature)',
        mizo: 'Logo leh hming nen (premium feature)',
        odia: 'ଲୋଗୋ ଏବଂ ନାମ ସହିତ (ପ୍ରିମିୟମ୍ ଫିଚର୍)',
        punjabi: 'ਲੋਗੋ ਅਤੇ ਨਾਮ ਨਾਲ (ਪ੍ਰੀਮੀਅਮ ਫੀਚਰ)',
        nepali: 'लोगो र नामसहित (प्रिमियम फिचर)',
        bengali: 'লোগো ও নামসহ (প্রিমিয়াম ফিচার)',
        kashmiri: 'لوگو تہٕ ناو سٲتھ (پریمیم فیچر)',
        ladakhi: 'Logo dang ming che (premium feature)',
      );
      final freeHeading = context.strings.localized(
        telugu: 'లోగో మరియు పేరు లేకుండా (ఉచితం)',
        english: 'Without logo and name (free)',
        hindi: 'लोगो और नाम के बिना (मुफ्त)',
        tamil: 'லோகோ மற்றும் பெயர் இல்லாமல் (இலவசம்)',
        kannada: 'ಲೋಗೋ ಮತ್ತು ಹೆಸರಿಲ್ಲದೆ (ಉಚಿತ)',
        malayalam: 'ലോഗോയും പേരും ഇല്ലാതെ (സൗജന്യം)',
        assamese: 'ল’গ’ আৰু নাম নোহোৱাকৈ (বিনামূলীয়া)',
        konkani: 'लोगो आनी नांव नासतना (फुकट)',
        gujarati: 'લોગો અને નામ વગર (મફત)',
        marathi: 'लोगो आणि नावाशिवाय (मोफत)',
        meitei: 'Logo amasung ming yaodana (free)',
        mizo: 'Logo leh hming tel lo (free)',
        odia: 'ଲୋଗୋ ଏବଂ ନାମ ବିନା (ମାଗଣା)',
        punjabi: 'ਲੋਗੋ ਅਤੇ ਨਾਮ ਤੋਂ ਬਿਨਾਂ (ਮੁਫ਼ਤ)',
        nepali: 'लोगो र नाम बिना (निःशुल्क)',
        bengali: 'লোগো ও নাম ছাড়া (ফ্রি)',
        kashmiri: 'لوگو تہٕ ناو بغیر (مفت)',
        ladakhi: 'Logo dang ming medpa (free)',
      );
      if (!context.mounted) {
        return _FreeExportChoice.none;
      }
      final choice = await Navigator.of(context).push<_FreeExportChoice>(
        PageRouteBuilder<_FreeExportChoice>(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (routeContext, animation, secondaryAnimation) {
            final aspectRatio = previewAspectRatio <= 0
                ? 4 / 5
                : previewAspectRatio;

            Widget preview({required bool withPhoto}) {
              final imagePath = withPhoto ? paidPreviewPath : plainPreviewPath;
              if (imagePath != null) {
                return AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                );
              }
              return Semantics(
                label: posterTitle.isEmpty
                    ? AppPublicInfo.appName
                    : posterTitle,
                image: true,
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: ClipRect(
                    child: _buildPosterPreview(
                      isPhotoVisible: withPhoto,
                      playbackEnabledOverride: false,
                      enableFullScreenTap: false,
                    ),
                  ),
                ),
              );
            }

            Widget choicePill({
              required Color backgroundColor,
              required Color foregroundColor,
              required Widget child,
              BorderSide? border,
            }) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: border == null ? null : Border.fromBorderSide(border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: foregroundColor),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      child: child,
                    ),
                  ),
                ),
              );
            }

            Widget priceLine() {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBE3155),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _subscriptionMonthlyTitleAppLocalized(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '@ ${_freeExportFourRupeesTrialLabel(context)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBE3155),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '\u20B9499',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Color(0xFF4B5563),
                              decorationThickness: 2.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget posterThumb(bool withPhoto) {
              return SizedBox(
                width: 156,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 188),
                    child: preview(withPhoto: withPhoto),
                  ),
                ),
              );
            }

            Widget dividerOr() {
              return Row(
                children: <Widget>[
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      context.strings.orLabel,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                ],
              );
            }

            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: Scaffold(
                backgroundColor: const Color(0xFFFFFEFB),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                premiumHeading,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(
                                routeContext,
                              ).pop(_FreeExportChoice.none),
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            posterThumb(true),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.of(
                                  routeContext,
                                ).pop(_FreeExportChoice.subscribe),
                                child: priceLine(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        dividerOr(),
                        const SizedBox(height: 34),
                        Text(
                          freeHeading,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            posterThumb(false),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () => Navigator.of(
                                      routeContext,
                                    ).pop(_FreeExportChoice.plainShare),
                                    child: choicePill(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: const Color(0xFF2563EB),
                                      border: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          const Icon(
                                            Icons.share_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(_freeExportShareLabel(context)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () => Navigator.of(
                                      routeContext,
                                    ).pop(_FreeExportChoice.plainDownload),
                                    child: choicePill(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: const Color(0xFFBE3155),
                                      border: const BorderSide(
                                        color: Color(0xFFBE3155),
                                        width: 1.2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          const Icon(
                                            Icons.download_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _freeExportDownloadLabel(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          autoRenewNote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB8B8B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openExternalPublicUrl(
                            routeContext,
                            AppPublicInfo.termsUrl,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF9CA3AF),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            subscriptionTermsLinkLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      return choice ?? _FreeExportChoice.none;
    } finally {
      if (context.mounted) {
        await ScreenSecurityService.protectScreen(adminOnlyBypass: false);
      }
    }
  }

  // ignore: unused_element
  Future<bool> _ensureHomeExportRewardedAccess({
    required String debugLabel,
  }) async {
    if (item.isVideo || AppPublicInfo.adMobHomeExportRewardedAdUnitId.isEmpty) {
      return true;
    }
    final settings = await _TemplateFeedItem._homeExportAdSettingsService
        .fetchForSelectedRegion();
    final manualAd = settings.manualAd;
    if (manualAd?.canShow == true) {
      return _showHomeExportManualAd(manualAd!);
    }
    if (!settings.rewardedEnabled) {
      return true;
    }
    return _TemplateFeedItem._homeExportRewardedAccessService
        .showRewardedAccessAd(
          adUnitId: AppPublicInfo.adMobHomeExportRewardedAdUnitId,
          debugLabel: debugLabel,
        );
  }

  Future<void> _preloadHomeExportRewardedAdIfEnabled() async {
    if (item.isVideo || !AppPublicInfo.hasHomeExportRewardedAdUnitId) {
      return;
    }
    final settings = await _TemplateFeedItem._homeExportAdSettingsService
        .fetchForSelectedRegion();
    if (!settings.rewardedEnabled) {
      return;
    }
    await _TemplateFeedItem._homeExportRewardedAccessService.preloadRewardedAd(
      adUnitId: AppPublicInfo.adMobHomeExportRewardedAdUnitId,
    );
  }

  Future<bool> _showHomeExportManualAd(HomeExportManualAd ad) async {
    if (!mounted || ad.url.trim().isEmpty) {
      return true;
    }
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _HomeExportManualAdDialog(ad: ad),
    );
    return allowed ?? false;
  }

  Future<void> _performPlainFreeExport(
    BuildContext context, {
    required bool share,
  }) async {
    final messenger = ScaffoldMessenger.of(
      hostContext.mounted ? hostContext : context,
    );
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'పోస్టర్ సిద్ధం కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'Poster is not ready. Please try again.',
      hindi: 'पोस्टर तैयार नहीं है। फिर कोशिश करें।',
      tamil: 'போஸ்டர் தயாராக இல்லை. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'പോസ്റ്റർ തയ്യാറായിട്ടില്ല. വീണ്ടും ശ്രമിക്കുക.',
      assamese: 'পোষ্টাৰ সাজু হোৱা নাই। পুনৰ চেষ্টা কৰক।',
      konkani: 'पोस्टर तयार ना. परत प्रयत्न करात.',
      gujarati: 'પોસ્ટર તૈયાર નથી. ફરી પ્રયાસ કરો.',
      marathi: 'पोस्टर तयार नाही. पुन्हा प्रयत्न करा.',
      meitei: 'Poster ready oidiramde. Amuk hotnou.',
      mizo: 'Poster a la ready lo. Han tum leh rawh.',
      odia: 'ପୋଷ୍ଟର ପ୍ରସ୍ତୁତ ନୁହେଁ। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
      punjabi: 'ਪੋਸਟਰ ਤਿਆਰ ਨਹੀਂ ਹੈ। ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      nepali: 'पोस्टर तयार छैन। फेरि प्रयास गर्नुहोस्।',
      bengali: 'পোস্টার প্রস্তুত নয়। আবার চেষ্টা করুন।',
      kashmiri: 'پوسٹر تیار چھُ نٕہ۔ دوبار کوشش کریو۔',
      ladakhi: 'Poster ready med. Yang try byed.',
    );
    final posterSavedMessage = context.strings.localized(
      telugu: 'పోస్టర్ గ్యాలరీలో సేవ్ అయింది.',
      english: 'Poster saved to gallery.',
      hindi: 'पोस्टर गैलरी में सेव हो गया।',
      tamil: 'போஸ்டர் கேலரியில் சேமிக்கப்பட்டது.',
      kannada: 'ಪೋಸ್ಟರ್ ಗ್ಯಾಲರಿಯಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ.',
      malayalam: 'പോസ്റ്റർ ഗാലറിയിൽ സേവ് ചെയ്തു.',
      assamese: 'পোষ্টাৰ গ্যালাৰীত সেভ কৰা হ’ল।',
      konkani: 'पोस्टर गॅलरींत सेव जाला.',
      gujarati: 'પોસ્ટર ગેલેરીમાં સેવ થયું.',
      marathi: 'पोस्टर गॅलरीत सेव झाले.',
      meitei: 'Poster gallery-da save toure.',
      mizo: 'Poster gallery-ah save a ni.',
      odia: 'ପୋଷ୍ଟର ଗ୍ୟାଲେରୀରେ ସେଭ୍ ହେଲା।',
      punjabi: 'ਪੋਸਟਰ ਗੈਲਰੀ ਵਿੱਚ ਸੇਵ ਹੋ ਗਿਆ।',
      nepali: 'पोस्टर ग्यालरीमा सेभ भयो।',
      bengali: 'পোস্টার গ্যালারিতে সেভ হয়েছে।',
      kashmiri: 'پوسٹر گیلری منز محفوظ گۆو۔',
      ladakhi: 'Poster gallery nang save song.',
    );
    final galleryPermissionMessage = context.strings.localized(
      telugu: 'గ్యాలరీ permission ఇవ్వలేదు.',
      english: 'Gallery permission was denied.',
      hindi: 'गैलरी अनुमति नहीं मिली।',
      tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
      kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿ ನಿರಾಕರಿಸಲಾಗಿದೆ.',
      malayalam: 'ഗാലറി അനുമതി നിഷേധിച്ചു.',
      assamese: 'গ্যালাৰী অনুমতি দিয়া হোৱা নাই।',
      konkani: 'गॅलरी परवानगी न्हय मेळ्ळी.',
      gujarati: 'ગેલેરી પરમિશન નકારી.',
      marathi: 'गॅलरी परवानगी नाकारली.',
      meitei: 'Gallery permission piramde.',
      mizo: 'Gallery permission pek a ni lo.',
      odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ମିଳିଲା ନାହିଁ।',
      punjabi: 'ਗੈਲਰੀ ਇਜਾਜ਼ਤ ਨਹੀਂ ਮਿਲੀ।',
      nepali: 'ग्यालरी अनुमति दिइएन।',
      bengali: 'গ্যালারি অনুমতি দেওয়া হয়নি।',
      kashmiri: 'گیلری اجازت نٕہ ملی۔',
      ladakhi: 'Gallery permission ma thob.',
    );
    final plainShareText = _homePosterShareText();
    if (!share) {
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        if (!context.mounted) {
          return;
        }
        _showSnack(messenger, galleryPermissionMessage);
        return;
      }
    }
    if (item.isVideo) {
      final preparedPath = await _ensurePreparedPlainVideoFile();
      if (!context.mounted) {
        return;
      }
      if (preparedPath == null) {
        _showSnack(messenger, '$posterNotReadyMessage (video export)');
        return;
      }
      if (share) {
        _recordPosterExportEngagement(isShare: true);
        final box = context.findRenderObject() as RenderBox?;
        await MediaExportService.shareVideoFile(
          preparedPath,
          text: plainShareText,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
        return;
      }
      final fileName =
          'mana_poster_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final saveResult =
          await MediaExportService.saveVideoFileToGalleryDetailed(
            preparedPath,
            fileName: fileName,
          );
      if (!context.mounted) {
        return;
      }
      if (saveResult.success) {
        _recordPosterExportEngagement(isShare: false);
        _showFullScreenDownloadSuccessToast(context, posterSavedMessage);
        return;
      }
      _showSnack(messenger, _downloadSaveFailureMessage(context, saveResult));
      return;
    }
    final preparedPath = await _ensurePreparedPlainPosterFile();
    if (!context.mounted) {
      return;
    }
    if (preparedPath == null) {
      _showSnack(messenger, posterNotReadyMessage);
      return;
    }
    if (share) {
      _recordPosterExportEngagement(isShare: true);
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        preparedPath,
        text: plainShareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      return;
    }
    final fileName = 'mana_poster_${DateTime.now().millisecondsSinceEpoch}.png';
    final saveResult = await MediaExportService.saveImageFileToGalleryDetailed(
      preparedPath,
      fileName: fileName,
    );
    if (!context.mounted) {
      return;
    }
    if (saveResult.success) {
      _recordPosterExportEngagement(isShare: false);
      if (!kIsWeb) {
        unawaited(
          PosterDownloadsService.recordCopyFromFile(
            preparedPath,
            suggestedFileName: fileName,
          ),
        );
      }
      _showFullScreenDownloadSuccessToast(context, posterSavedMessage);
      return;
    }
    _showSnack(messenger, _downloadSaveFailureMessage(context, saveResult));
  }

  Future<void> _onDownloadTap(BuildContext context) async {
    if (!_beginAction('download')) {
      return;
    }
    if (!await _ensureAuthenticatedForPosterAction(
      context,
      actionLabel: context.strings.localized(
        telugu: 'డౌన్‌లోడ్',
        english: 'download',
        hindi: 'डाउनलोड',
        tamil: 'பதிவிறக்கம்',
        kannada: 'ಡೌನ್‌ಲೋಡ್',
        malayalam: 'ഡൗൺലോഡ്',
        marathi: 'डाउनलोड',
        gujarati: 'ડાઉનલોડ',
        bengali: 'ডাউনলোড',
        punjabi: 'ਡਾਊਨਲੋਡ',
        odia: 'ଡାଉନଲୋଡ୍',
        assamese: 'ডাউনলোড',
        konkani: 'डाऊनलोड',
        nepali: 'डाउनलोड',
        meitei: 'দাউনলোদ',
        mizo: 'download',
        kashmiri: 'ڈاؤنلوڈ',
        ladakhi: 'ཕབ་ལེན།',
      ),
    )) {
      _endAction();
      return;
    }
    if (!context.mounted) {
      _endAction();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final galleryPermissionMessage = context.strings.localized(
      telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
      english: 'Gallery permission was denied.',
      hindi: 'गैलरी की अनुमति अस्वीकार कर दी गई।',
      tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
      kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ.',
      malayalam: 'ഗ്യാലറി അനുമതി നിരസിച്ചു.',
      marathi: 'गॅलरी परवानगी नाकारली गेली.',
      gujarati: 'ગૅલેરી પરવાનગી નકારી દેવામાં આવી.',
      bengali: 'গ্যালারির অনুমতি প্রত্যাখ্যান করা হয়েছে।',
      punjabi: 'ਗੈਲਰੀ ਦੀ ਇਜਾਜ਼ਤ ਅਸਵੀਕਾਰ ਕਰ ਦਿੱਤੀ ਗਈ।',
      odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଗଲା।',
      assamese: 'গেলেৰীৰ অনুমতি নাকচ কৰা হ’ল।',
      konkani: 'गॅलरीची परवानगी नाकारली.',
      nepali: 'ग्यालरी अनुमति अस्वीकृत गरियो।',
      meitei: 'গেলরিগী অয়াবা য়াদে।',
      mizo: 'Gallery phalna hnar a ni.',
      kashmiri: 'گیلری ہٕنٛز اِجازت آیہِ مسترد کَرنہٕ۔',
      ladakhi: 'པར་མཛོད་ཆོག་མཆན་ཕྱིར་འཐེན་བྱས།',
    );
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'క్యాప్చర్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
      hindi: 'कैप्चर विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'படமெடுத்தல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಕ್ಯಾಪ್ಚರ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ക്യാപ്‌ചർ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'कॅप्चर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'કૅપ્ચર નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ক্যাপচার ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਕੈਪਚਰ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'କ୍ୟାପଚର୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'কেপচাৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'कॅप्चर जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'क्याप्चर असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'কেপচর তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Capture a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'کیپچر گوو ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'པར་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final posterSavedMessage = context.strings.localized(
      telugu: 'పోస్టర్ గ్యాలరీలో సేవ్ చేయబడింది.',
      english: 'Poster saved to gallery.',
      hindi: 'पोस्टर गैलरी में सहेजा गया।',
      tamil: 'போஸ்டர் கேலரியில் சேமிக்கப்பட்டது.',
      kannada: 'ಪೋಸ್ಟರ್ ಗ್ಯಾಲರಿಯಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ.',
      malayalam: 'പോസ്റ്റർ ഗ്യാലറിയിൽ സൂക്ഷിച്ചു.',
      marathi: 'पोस्टर गॅलरीमध्ये जतन केले.',
      gujarati: 'પોસ્ટર ગૅલેરીમાં સાચવવામાં આવ્યું.',
      bengali: 'পোস্টারটি গ্যালারিতে সংরক্ষিত হয়েছে।',
      punjabi: 'ਪੋਸਟਰ ਗੈਲਰੀ ਵਿੱਚ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਗਿਆ।',
      odia: 'ପୋଷ୍ଟର ଗ୍ୟାଲେରୀରେ ସେଭ୍ ହୋଇଛି।',
      assamese: 'পোষ্টাৰ গেলেৰীত সংৰক্ষণ কৰা হ’ল।',
      konkani: 'पोस्टर गॅलरींत सांबाळ्ळें.',
      nepali: 'पोस्टर ग्यालरीमा सुरक्षित गरियो।',
      meitei: 'পোস্তর অসি গেলরিদা সেভ তৌখ্রে।',
      mizo: 'Poster gallery-ah dahthat a ni ta.',
      kashmiri: 'پوسٹر آو گیلری منٛز محفوٗظ کَرنہٕ۔',
      ladakhi: 'པོ་སི་ཊར་པར་མཛོད་ནང་ཉར་ཚགས་བྱས།',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'ఫైల్ సేవ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'File save failed. Please try again.',
      hindi: 'फ़ाइल सहेजना विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'கோப்பைச் சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಫೈಲ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam:
          'ഫയൽ സൂക്ഷിക്കുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'फाइल सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'ફાઇલ સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ফাইল সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਫਾਈਲ ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଫାଇଲ୍ ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'ফাইল সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'फायल सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'फाइल बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'ফাইল সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'File dahthat a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri:
          'فائل محفوٗظ کرنس منٛز ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'ཡིག་སྣོད་ཉར་ཚགས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final downloadFailedMessage = context.strings.localized(
      telugu: 'డౌన్‌లోడ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Download failed. Please try again.',
      hindi: 'डाउनलोड विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'பதிவிறக்கம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ഡൗൺലോഡ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'डाउनलोड अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'ડાઉનલોડ નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ডাউনলোড ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਡਾਊਨਲੋਡ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଡାଉନଲୋଡ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'ডাউনলোড ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'डाऊनलोड जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'डाउनलोड असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'দাউনলোদ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Download a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'ڈاؤنلوڈ گوو ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'ཕབ་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    try {
      if (!item.isVideo && _isCurrentJokesPoster()) {
        await _performPlainFreeExport(context, share: false);
        result = true;
        return;
      }
      final hasAccess = await _hasSubscriptionAccessForExport();
      if (!context.mounted) {
        result = false;
        return;
      }
      if (!hasAccess) {
        final choice = await _showFreeExportChoiceSheet(
          context,
          preferShare: false,
        );
        if (!context.mounted) {
          result = false;
          return;
        }
        switch (choice) {
          case _FreeExportChoice.subscribe:
            final purchased =
                await _startDirectTrialPurchaseFromFreeExportChoice();
            if (!context.mounted || !purchased) {
              result = false;
              return;
            }
          case _FreeExportChoice.plainDownload:
            await _performPlainFreeExport(context, share: false);
            result = true;
            return;
          case _FreeExportChoice.plainShare:
            await _performPlainFreeExport(context, share: true);
            result = true;
            return;
          case _FreeExportChoice.none:
            result = false;
            return;
        }
      }
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        result = false;
        _showSnack(messenger, galleryPermissionMessage);
        return;
      }
      if (item.isVideo) {
        final preparedVideoPath = await _ensurePreparedVideoFile();
        if (preparedVideoPath == null) {
          result = false;
          _showSnack(messenger, '$posterNotReadyMessage (video export)');
          return;
        }
        final fileName =
            'mana_poster_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final saveResult =
            await MediaExportService.saveVideoFileToGalleryDetailed(
              preparedVideoPath,
              fileName: fileName,
            );
        result = saveResult.success;
        if (result) {
          _recordPosterExportEngagement(isShare: false);
          _showDownloadSuccessSnack(messenger, posterSavedMessage);
          return;
        }
        if (!context.mounted) {
          return;
        }
        _showSnack(
          messenger,
          '${_downloadSaveFailureMessage(context, saveResult)} '
          '(${saveResult.code ?? 'unknown'})',
        );
        return;
      }
      final preparedPath = await _ensurePreparedPosterFile();
      if (preparedPath == null) {
        result = false;
        _showSnack(messenger, posterNotReadyMessage);
        return;
      }
      final fileName =
          'mana_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final saveResult =
          await MediaExportService.saveImageFileToGalleryDetailed(
            preparedPath,
            fileName: fileName,
          );
      result = saveResult.success;
      if (result) {
        if (!kIsWeb) {
          unawaited(
            PosterDownloadsService.recordCopyFromFile(
              preparedPath,
              suggestedFileName: fileName,
            ),
          );
        }
        _recordPosterExportEngagement(isShare: false);
        _showDownloadSuccessSnack(messenger, posterSavedMessage);
        return;
      }
      _homeDebugLog(
        'download native save failed: code=${saveResult.code}, message=${saveResult.message}',
      );
      if (!context.mounted) {
        return;
      }
      _showSnack(messenger, _downloadSaveFailureMessage(context, saveResult));
    } on FileSystemException catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('download file save failed: $error', stackTrace);
      _showSnack(messenger, fileSaveFailedMessage);
    } catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('download failed: $error', stackTrace);
      _showSnack(messenger, downloadFailedMessage);
    } finally {
      _homeDebugLog('download result=$result');
      _endAction();
    }
  }

  Future<void> _onShareTap(BuildContext context) async {
    if (!_beginAction('share')) {
      return;
    }
    if (!await _ensureAuthenticatedForPosterAction(
      context,
      actionLabel: context.strings.localized(
        telugu: 'షేర్',
        english: 'share',
        hindi: 'शेयर',
        tamil: 'பகிர்',
        kannada: 'ಹಂಚಿಕೆ',
        malayalam: 'പങ്കിടൽ',
        marathi: 'शेअर',
        gujarati: 'શેર',
        bengali: 'শেয়ার',
        punjabi: 'ਸਾਂਝਾ',
        odia: 'ସେୟାର୍',
        assamese: 'শ্বেয়াৰ',
        konkani: 'वांटप',
        nepali: 'सेयर',
        meitei: 'শিয়র',
        mizo: 'share',
        kashmiri: 'شیئر',
        ladakhi: 'བགོ་འགྲེམས།',
      ),
    )) {
      _endAction();
      return;
    }
    if (!context.mounted) {
      _endAction();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    bool result = false;
    final posterNotReadyMessage = context.strings.localized(
      telugu: 'క్యాప్చర్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Capture failed. Please try again.',
      hindi: 'कैप्चर विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'படமெடுத்தல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಕ್ಯಾಪ್ಚರ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ക്യാപ്‌ചർ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'कॅप्चर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'કૅપ્ચર નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ক্যাপচার ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਕੈਪਚਰ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'କ୍ୟାପଚର୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'কেপচাৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'कॅप्चर जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'क्याप्चर असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'কেপচর তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Capture a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'کیپچر گوو ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'པར་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final shareFailedMessage = context.strings.localized(
      telugu: 'షేర్ చేయడం విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'Share failed. Please try again.',
      hindi: 'शेयर करना विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'பகிர்வது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಹಂಚಿಕೆ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'പങ്കിടൽ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'शेअर अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'શેર કરવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'শেয়ার করা ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਸਾਂਝਾ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ସେୟାର୍ କରିବା ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'শ্বেয়াৰ কৰা ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'वांटप जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'सेयर गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'শিয়র তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'Share a hlawhchham. Khawngaihin ti nawn leh raw.',
      kashmiri: 'شیئر گوو ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'བགོ་འགྲེམས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final fileSaveFailedMessage = context.strings.localized(
      telugu: 'ఫైల్ సేవ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      english: 'File save failed. Please try again.',
      hindi: 'फ़ाइल सहेजना विफल रहा। कृपया पुनः प्रयास करें।',
      tamil: 'கோப்பைச் சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ಫೈಲ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam:
          'ഫയൽ സൂക്ഷിക്കുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'फाइल सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'ફાઇલ સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'ফাইল সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਫਾਈਲ ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଫାଇଲ୍ ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'ফাইল সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'फायल सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
      nepali: 'फाइल बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'ফাইল সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
      mizo: 'File dahthat a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri:
          'فائل محفوٗظ کرنس منٛز ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'ཡིག་སྣོད་ཉར་ཚགས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    final shareText = _homePosterShareText();
    try {
      if (!item.isVideo && _isCurrentJokesPoster()) {
        await _performPlainFreeExport(context, share: true);
        result = true;
        return;
      }
      final hasAccess = await _hasSubscriptionAccessForExport();
      if (!context.mounted) {
        result = false;
        return;
      }
      if (!hasAccess) {
        final choice = await _showFreeExportChoiceSheet(
          context,
          preferShare: true,
        );
        if (!context.mounted) {
          result = false;
          return;
        }
        switch (choice) {
          case _FreeExportChoice.subscribe:
            final purchased =
                await _startDirectTrialPurchaseFromFreeExportChoice();
            if (!context.mounted || !purchased) {
              result = false;
              return;
            }
          case _FreeExportChoice.plainDownload:
            await _performPlainFreeExport(context, share: false);
            result = true;
            return;
          case _FreeExportChoice.plainShare:
            await _performPlainFreeExport(context, share: true);
            result = true;
            return;
          case _FreeExportChoice.none:
            result = false;
            return;
        }
      }
      if (item.isVideo) {
        final preparedVideoPath = await _ensurePreparedVideoFile();
        if (preparedVideoPath == null) {
          result = false;
          _showSnack(messenger, '$posterNotReadyMessage (video export)');
          return;
        }
        if (!context.mounted) {
          result = false;
          return;
        }
        _recordPosterExportEngagement(isShare: true);
        final box = context.findRenderObject() as RenderBox?;
        await MediaExportService.shareVideoFile(
          preparedVideoPath,
          text: shareText,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
        result = true;
        return;
      }
      final preparedPath = await _ensurePreparedPosterFile();
      if (preparedPath == null) {
        result = false;
        _showSnack(messenger, posterNotReadyMessage);
        return;
      }
      if (!context.mounted) {
        result = false;
        return;
      }
      _recordPosterExportEngagement(isShare: true);
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        preparedPath,
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      result = true;
    } on MediaShareException catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('share media service failed: $error', stackTrace);
      _showSnack(messenger, shareFailedMessage);
    } on FileSystemException catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('share file save failed: $error', stackTrace);
      _showSnack(messenger, fileSaveFailedMessage);
    } catch (error, stackTrace) {
      result = false;
      _homeDebugLogStack('share failed: $error', stackTrace);
      _showSnack(messenger, shareFailedMessage);
    } finally {
      _homeDebugLog('share result=$result');
      _endAction();
    }
  }

  EditorPageConfig _editorPageConfigForPoster() {
    final existing = item.pageConfig;
    if (existing != null) {
      return existing;
    }
    final captureContext = _posterCaptureKey.currentContext;
    final renderBox = captureContext?.findRenderObject() as RenderBox?;
    final size =
        renderBox != null && renderBox.hasSize && !renderBox.size.isEmpty
        ? renderBox.size
        : const Size(1080, 1350);
    final safeWidth = size.width <= 0 ? 1080.0 : size.width;
    final safeHeight = size.height <= 0 ? 1350.0 : size.height;
    final widthPx = 1080;
    final heightPx = ((widthPx / safeWidth) * safeHeight).round().clamp(
      320,
      4000,
    );
    return EditorPageConfig(
      name: 'Poster Editor',
      widthPx: widthPx,
      heightPx: heightPx,
    );
  }

  void _openFullScreenPreview() {
    if (!mounted || deferRichPosterPreview) {
      return;
    }
    final aspectRatio =
        _resolvedPreviewAspectRatio ??
        item.pageConfig?.aspectRatio ??
        (item.isVideo ? 9 / 16 : null);
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => _PosterFullScreenPreview(
          title: item.titleFor(language),
          heroTag: _fullScreenHeroTag,
          aspectRatio: aspectRatio,
          child: _buildPosterPreview(
            isPhotoVisible: _showPosterPhotoNotifier.value,
            playbackEnabledOverride: true,
            enableFullScreenTap: false,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    widget.onInteraction?.call(item, 'preview');
  }

  Future<void> _openPosterPhotoEditor(BuildContext context) async {
    if (!_beginAction('poster_editor_removed')) {
      return;
    }
    try {
      if (!context.mounted) {
        return;
      }
      _showSnack(
        ScaffoldMessenger.of(context),
        context.strings.localized(
          telugu: 'ఎడిటర్ ఇప్పుడు వేరే యాప్‌లో అందుబాటులో ఉంది.',
          english: 'Editor is now available in the separate app.',
          hindi: 'संपादक अब अलग ऐप में उपलब्ध है।',
          tamil: 'எடிட்டர் இப்போது தனி செயலியில் கிடைக்கிறது.',
          kannada: 'ಎಡಿಟರ್ ಈಗ ಪ್ರತ್ಯೇಕ ಆ್ಯಪ್‌ನಲ್ಲಿ ಲಭ್ಯವಿದೆ.',
          malayalam: 'എഡിറ്റർ ഇപ്പോൾ പ്രത്യേക ആപ്പിൽ ലഭ്യമാണ്.',
          marathi: 'संपादक आता वेगळ्या ॲपमध्ये उपलब्ध आहे.',
          gujarati: 'એડિટર હવે અલગ ઍપમાં ઉપલબ્ધ છે.',
          bengali: 'সম্পাদক এখন পৃথক অ্যাপে উপলব্ধ।',
          punjabi: 'ਸੰਪਾਦਕ ਹੁਣ ਵੱਖਰੀ ਐਪ ਵਿੱਚ ਉਪਲਬਧ ਹੈ।',
          odia: 'ଏଡିଟର୍ ଏବେ ଅଲଗା ଆପରେ ଉପଲବ୍ଧ।',
          assamese: 'সম্পাদক এতিয়া পৃথক এপত উপলব্ধ।',
          konkani: 'संपादक आतां वेगळ्या ॲपाचेर मेळटा.',
          nepali: 'सम्पादक अब छुट्टै एपमा उपलब्ध छ।',
          meitei: 'এদিতর অসি হৌজিক তোঙানবা এপত ফংলে।',
          mizo: 'Editor chu app hranah a awm ta.',
          kashmiri: 'ایڈیٹر چُھ وۄنؠ اَکھ اَلگ ایپَس منٛز دستیاب۔',
          ladakhi: 'རྩོམ་སྒྲིག་པ་ད་ལྟ་མཉེན་ཆས་ལོགས་སུ་ཡོད།',
        ),
      );
    } finally {
      _endAction();
    }
  }

  String _formatEngagementCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toString();
  }

  int _displayCountWithLocalDelta(String kind, int localDelta) {
    final baseDisplay = item.displayCountFor(kind);
    return baseDisplay + math.max(0, localDelta);
  }

  Widget _buildPlainEngagementCount({
    required IconData icon,
    required int value,
    required MainAxisAlignment alignment,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            _formatEngagementCount(value),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterEngagementCounts() {
    final localShareAndDownloadDelta =
        _localShareCountDelta + _localDownloadCountDelta;
    final shareAndDownloadCount =
        item.displayCombinedEngagementCount() + localShareAndDownloadDelta;
    final viewCount = math.max(
      _displayCountWithLocalDelta('view', _localViewCountDelta),
      shareAndDownloadCount + 1,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          _buildPlainEngagementCount(
            icon: Icons.visibility_rounded,
            value: viewCount,
            alignment: MainAxisAlignment.start,
          ),
          _buildPlainEngagementCount(
            icon: Icons.send_rounded,
            value: shareAndDownloadCount,
            alignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  Widget _buildViewportItem(
    BuildContext context,
    AppStrings strings,
    bool canTogglePhoto,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final horizontalPadding = maxWidth >= 420 ? 6.0 : 4.0;
        final previewMaxWidth = math.max(
          1.0,
          maxWidth - (horizontalPadding * 2),
        );
        final previewAspectRatio = _resolvedPreviewAspectRatio;
        final previewNaturalHeight = previewAspectRatio == null
            ? constraints.maxHeight
            : previewMaxWidth / previewAspectRatio;
        final heightFirstTallVideo =
            item.isVideo &&
            previewAspectRatio != null &&
            previewAspectRatio < 0.7;
        final controlsReserveHeight = item.isVideo ? 0.0 : 96.0;
        final availablePreviewHeight = math.max(
          1.0,
          constraints.maxHeight - controlsReserveHeight,
        );
        final previewMaxHeight = math.min(
          heightFirstTallVideo ? availablePreviewHeight : constraints.maxHeight,
          previewNaturalHeight,
        );
        final effectivePreviewMaxWidth = heightFirstTallVideo
            ? math.min(previewMaxWidth, previewMaxHeight * previewAspectRatio)
            : previewMaxWidth;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            item.isVideo ? 4 : 10,
          ),
          child: Column(
            children: <Widget>[
              _buildCreatorIdLabel(compact: true),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _showPosterPhotoNotifier,
                  builder: (context, isPhotoVisible, _) {
                    final previewChild = _buildCapturedPosterPreview(
                      isPhotoVisible: isPhotoVisible,
                      onPosterReadyChanged: _handlePosterReadyState,
                    );
                    final preview = Center(
                      child: heightFirstTallVideo
                          ? SizedBox(
                              width: effectivePreviewMaxWidth,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: previewMaxHeight,
                                ),
                                child: previewChild,
                              ),
                            )
                          : ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: previewMaxWidth,
                                maxHeight: previewMaxHeight,
                              ),
                              child: previewChild,
                            ),
                    );
                    if (!item.isVideo) {
                      return preview;
                    }
                    return Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        preview,
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _VideoSideActions(
                              activeActionListenable: _activeActionNotifier,
                              videoExportReadyListenable:
                                  _videoExportReadyNotifier,
                              onShareTap: () => unawaited(_onShareTap(context)),
                              onDownloadTap: () =>
                                  unawaited(_onDownloadTap(context)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (deferRichPosterPreview)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              const SizedBox(height: 4),
              _buildPosterEngagementCounts(),
              if (!item.isVideo) ...<Widget>[
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _activeActionNotifier,
                        builder: (context, activeAction, _) {
                          final isBusy = activeAction == 'share';
                          return OutlinedButton.icon(
                            onPressed:
                                deferRichPosterPreview ||
                                    activeAction != null ||
                                    (item.isVideo &&
                                        !_videoExportReadyNotifier.value)
                                ? null
                                : () => unawaited(_onShareTap(context)),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/branding/whatsapp_icon.png',
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.share_rounded,
                                      size: 17,
                                    ),
                                  ),
                            label: Text(
                              isBusy
                                  ? 'Preparing...'
                                  : _posterShareLabel(context),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF25D366),
                              side: const BorderSide(color: Color(0xFF25D366)),
                              minimumSize: const Size.fromHeight(32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (canTogglePhoto) ...<Widget>[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _showPosterPhotoNotifier,
                          builder: (context, isPhotoVisible, _) {
                            return OutlinedButton.icon(
                              onPressed: deferRichPosterPreview
                                  ? null
                                  : () {
                                      _invalidatePreparedPosterCache(
                                        cancelVideoExport: item.isVideo,
                                      );
                                      _showPosterPhotoNotifier.value =
                                          !isPhotoVisible;
                                      _schedulePosterWarmup(force: true);
                                    },
                              icon: Icon(
                                isPhotoVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 16,
                                color: isPhotoVisible
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B),
                              ),
                              label: Text(
                                strings.localized(
                                  telugu: 'ఫోటో',
                                  english: 'Photo',
                                  hindi: 'फ़ोटो',
                                  tamil: 'புகைப்படம்',
                                  kannada: 'ಫೋಟೋ',
                                  malayalam: 'ഫോട്ടോ',
                                  marathi: 'फोटो',
                                  gujarati: 'ફોટો',
                                  bengali: 'ছবি',
                                  punjabi: 'ਫੋਟੋ',
                                  odia: 'ଫଟୋ',
                                  assamese: 'ফটো',
                                  konkani: 'फोटो',
                                  nepali: 'तस्विर',
                                  meitei: 'ফোতো',
                                  mizo: 'Thlalak',
                                  kashmiri: 'فوٹو',
                                  ladakhi: 'པར།',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isPhotoVisible
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: BorderSide(
                                  color: isPhotoVisible
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFD8E2F0),
                                ),
                                backgroundColor: isPhotoVisible
                                    ? const Color(0xFFF0FDF4)
                                    : Colors.white,
                                minimumSize: const Size.fromHeight(32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _activeActionNotifier,
                        builder: (context, activeAction, _) {
                          final isBusy = activeAction == 'download';
                          return FilledButton.icon(
                            onPressed:
                                deferRichPosterPreview ||
                                    activeAction != null ||
                                    (item.isVideo &&
                                        !_videoExportReadyNotifier.value)
                                ? null
                                : () => unawaited(_onDownloadTap(context)),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 17),
                            label: Text(
                              isBusy
                                  ? 'Preparing...'
                                  : _posterDownloadLabel(context),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF64748B),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!item.isVideo)
                  ValueListenableBuilder<String?>(
                    valueListenable: _activeActionNotifier,
                    builder: (context, activeAction, _) {
                      final isBusy = activeAction == 'poster_editor';
                      final controlsDisabled =
                          deferRichPosterPreview || activeAction != null;
                      final showEditButton = widget.showPosterEditButton;
                      return Row(
                        children: <Widget>[
                          if (showEditButton)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: controlsDisabled
                                    ? null
                                    : () => unawaited(
                                        _openPosterPhotoEditor(context),
                                      ),
                                icon: isBusy
                                    ? const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  strings.localized(
                                    telugu: 'ఎడిట్',
                                    english: 'Edit',
                                    hindi: 'संपादित करें',
                                    tamil: 'திருத்து',
                                    kannada: 'ಸಂಪಾದಿಸಿ',
                                    malayalam: 'എഡിറ്റ് ചെയ്യുക',
                                    marathi: 'संपादित करा',
                                    gujarati: 'સંપાદિત કરો',
                                    bengali: 'সম্পাদনা',
                                    punjabi: 'ਸੰਪਾਦਨ',
                                    odia: 'ସମ୍ପାଦନା',
                                    assamese: 'সম্পাদনা',
                                    konkani: 'बदल करा',
                                    nepali: 'सम्पादन गर्नुहोस्',
                                    meitei: 'শেমদোকপা',
                                    mizo: 'Siamthatna',
                                    kashmiri: 'ترمیٖم',
                                    ladakhi: 'རྩོམ་སྒྲིག',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6D28D9),
                                  side: const BorderSide(
                                    color: Color(0xFFC4B5FD),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size.fromHeight(32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          if (_canAddPoliticalProtocolPhotos) ...<Widget>[
                            if (showEditButton) const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: controlsDisabled
                                    ? null
                                    : () => unawaited(
                                        _openPoliticalProtocolPhotoScreen(
                                          context,
                                        ),
                                      ),
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  strings.addPoliticalPhotos,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                  side: const BorderSide(
                                    color: Color(0xFF99F6E4),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 7,
                                  ),
                                  minimumSize: const Size.fromHeight(32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: controlsDisabled
                                  ? null
                                  : _cyclePosterDesign,
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                              ),
                              label: Text(
                                strings.localized(
                                  telugu: 'డిజైన్ మార్చండి',
                                  english: 'Change Design',
                                  hindi: 'डिज़ाइन बदलें',
                                  tamil: 'வடிவமைப்பை மாற்று',
                                  kannada: 'ವಿನ್ಯಾಸ ಬದಲಾಯಿಸಿ',
                                  malayalam: 'ഡിസൈൻ മാറ്റുക',
                                  marathi: 'डिझाइन बदला',
                                  gujarati: 'ડિઝાઇન બદલો',
                                  bengali: 'ডিজাইন পরিবর্তন করুন',
                                  punjabi: 'ਡਿਜ਼ਾਈਨ ਬਦਲੋ',
                                  odia: 'ଡିଜାଇନ୍ ବଦଳାନ୍ତୁ',
                                  assamese: 'ডিজাইন সলনি কৰক',
                                  konkani: 'डिझाइन बदलात',
                                  nepali: 'डिजाइन परिवर्तन गर्नुहोस्',
                                  meitei: 'দিজাইন হোংদোকউ',
                                  mizo: 'Design thlak rawh',
                                  kashmiri: 'ڈیزائن بَدلٲوِو',
                                  ladakhi: 'བཟོ་བཀོད་བརྗེ་པོ་རྒྱོབ།',
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6D28D9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                minimumSize: const Size.fromHeight(32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else
                  const SizedBox(height: 32),
                const SizedBox(height: 22),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = context.strings;
    final personalizationConfig = item.personalizationConfig;
    final canTogglePhoto = personalizationConfig != null && !item.isVideo;

    if (widget.previewOnly) {
      return ValueListenableBuilder<bool>(
        valueListenable: _showPosterPhotoNotifier,
        builder: (context, isPhotoVisible, _) {
          final preview = _buildPosterPreview(
            isPhotoVisible: isPhotoVisible,
            playbackEnabledOverride: true,
            enableFullScreenTap: false,
          );
          final aspectRatio =
              _resolvedPreviewAspectRatio ??
              item.pageConfig?.aspectRatio ??
              (item.isVideo ? 9 / 16 : null);
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              if (aspectRatio != null && aspectRatio > 0) {
                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    height: maxWidth / aspectRatio,
                    child: preview,
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: preview,
                ),
              );
            },
          );
        },
      );
    }

    if (fillViewport) {
      return _buildViewportItem(context, strings, canTogglePhoto);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCreatorIdLabel(),
          ValueListenableBuilder<bool>(
            valueListenable: _showPosterPhotoNotifier,
            builder: (context, isPhotoVisible, _) {
              return _buildCapturedPosterPreview(
                isPhotoVisible: isPhotoVisible,
                onPosterReadyChanged: _handlePosterReadyState,
              );
            },
          ),
          if (deferRichPosterPreview) ...<Widget>[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (canTogglePhoto && item.titleEn.trim().isEmpty) ...<Widget>[
            const SizedBox(height: 4),
            ValueListenableBuilder<bool>(
              valueListenable: _showPosterPhotoNotifier,
              builder: (context, isPhotoVisible, _) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: deferRichPosterPreview
                          ? null
                          : () {
                              _invalidatePreparedPosterCache();
                              _showPosterPhotoNotifier.value = !isPhotoVisible;
                              _schedulePosterWarmup(force: true);
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              isPhotoVisible
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 14,
                              color: isPhotoVisible
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              strings.localized(
                                telugu: 'ఫోటో',
                                english: 'Photo',
                                hindi: 'फ़ोटो',
                                tamil: 'புகைப்படம்',
                                kannada: 'ಫೋಟೋ',
                                malayalam: 'ഫോട്ടോ',
                                marathi: 'फोटो',
                                gujarati: 'ફોટો',
                                bengali: 'ছবি',
                                punjabi: 'ਫੋਟੋ',
                                odia: 'ଫଟୋ',
                                assamese: 'ফটো',
                                konkani: 'फोटो',
                                nepali: 'तस्विर',
                                meitei: 'ফোতো',
                                mizo: 'Thlalak',
                                kashmiri: 'فوٹو',
                                ladakhi: 'པར།',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isPhotoVisible
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.68,
                              child: Switch.adaptive(
                                value: isPhotoVisible,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                activeTrackColor: const Color(0xFF25D366),
                                activeThumbColor: Colors.white,
                                onChanged: deferRichPosterPreview
                                    ? null
                                    : (bool value) {
                                        _invalidatePreparedPosterCache(
                                          cancelVideoExport: item.isVideo,
                                        );
                                        _showPosterPhotoNotifier.value = value;
                                        _schedulePosterWarmup(force: true);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 2),
          Row(
            children: <Widget>[
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _activeActionNotifier,
                  builder: (context, activeAction, _) {
                    final isBusy = activeAction == 'share';
                    return OutlinedButton.icon(
                      onPressed:
                          deferRichPosterPreview ||
                              activeAction != null ||
                              (item.isVideo && !_videoExportReadyNotifier.value)
                          ? null
                          : () => unawaited(_onShareTap(context)),
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/branding/whatsapp_icon.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.whatshot_rounded, size: 18),
                            ),
                      label: Text(
                        isBusy ? 'Preparing...' : _posterShareLabel(context),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        minimumSize: const Size.fromHeight(42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (canTogglePhoto) ...<Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showPosterPhotoNotifier,
                    builder: (context, isPhotoVisible, _) {
                      return OutlinedButton.icon(
                        onPressed: deferRichPosterPreview
                            ? null
                            : () {
                                _invalidatePreparedPosterCache(
                                  cancelVideoExport: item.isVideo,
                                );
                                _showPosterPhotoNotifier.value =
                                    !isPhotoVisible;
                                _schedulePosterWarmup(force: true);
                              },
                        icon: Icon(
                          isPhotoVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 16,
                          color: isPhotoVisible
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                        label: Text(
                          strings.localized(
                            telugu: 'ఫోటో',
                            english: 'Photo',
                            hindi: 'फ़ोटो',
                            tamil: 'புகைப்படம்',
                            kannada: 'ಫೋಟೋ',
                            malayalam: 'ഫോട്ടോ',
                            marathi: 'फोटो',
                            gujarati: 'ફોટો',
                            bengali: 'ছবি',
                            punjabi: 'ਫੋਟੋ',
                            odia: 'ଫଟୋ',
                            assamese: 'ফটো',
                            konkani: 'फोटो',
                            nepali: 'तस्विर',
                            meitei: 'ফোতো',
                            mizo: 'Thlalak',
                            kashmiri: 'فوٹو',
                            ladakhi: 'པར།',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPhotoVisible
                                ? const Color(0xFF166534)
                                : const Color(0xFF475569),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: BorderSide(
                            color: isPhotoVisible
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFD8E2F0),
                          ),
                          backgroundColor: isPhotoVisible
                              ? const Color(0xFFF0FDF4)
                              : Colors.white,
                          minimumSize: const Size.fromHeight(40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _activeActionNotifier,
                  builder: (context, activeAction, _) {
                    final isBusy = activeAction == 'download';
                    return FilledButton.icon(
                      onPressed:
                          deferRichPosterPreview ||
                              activeAction != null ||
                              (item.isVideo && !_videoExportReadyNotifier.value)
                          ? null
                          : () => unawaited(_onDownloadTap(context)),
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        isBusy ? 'Preparing...' : _posterDownloadLabel(context),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF64748B)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (!item.isVideo) ...<Widget>[
            const SizedBox(height: 10),
            ValueListenableBuilder<String?>(
              valueListenable: _activeActionNotifier,
              builder: (context, activeAction, _) {
                final isBusy = activeAction == 'poster_editor';
                final controlsDisabled =
                    deferRichPosterPreview || activeAction != null;
                final showEditButton = widget.showPosterEditButton;
                return Row(
                  children: <Widget>[
                    if (showEditButton)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controlsDisabled
                              ? null
                              : () =>
                                    unawaited(_openPosterPhotoEditor(context)),
                          icon: isBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            strings.localized(
                              telugu: 'ఎడిట్',
                              english: 'Edit',
                              hindi: 'संपादित करें',
                              tamil: 'திருத்து',
                              kannada: 'ಸಂಪಾದಿಸಿ',
                              malayalam: 'എഡിറ്റ് ചെയ്യുക',
                              marathi: 'संपादित करा',
                              gujarati: 'સંપાદિત કરો',
                              bengali: 'সম্পাদনা',
                              punjabi: 'ਸੰਪਾਦਨ',
                              odia: 'ସମ୍ପାଦନା',
                              assamese: 'সম্পাদনা',
                              konkani: 'बदल करा',
                              nepali: 'सम्पादन गर्नुहोस्',
                              meitei: 'শেমদোকপা',
                              mizo: 'Siamthatna',
                              kashmiri: 'ترمیٖم',
                              ladakhi: 'རྩོམ་སྒྲིག',
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6D28D9),
                            side: const BorderSide(color: Color(0xFFC4B5FD)),
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 8,
                            ),
                            minimumSize: const Size.fromHeight(36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    if (_canAddPoliticalProtocolPhotos) ...<Widget>[
                      if (showEditButton) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controlsDisabled
                              ? null
                              : () => unawaited(
                                  _openPoliticalProtocolPhotoScreen(context),
                                ),
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 16,
                          ),
                          label: Text(
                            strings.addPoliticalPhotos,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF99F6E4)),
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 7,
                            ),
                            minimumSize: const Size.fromHeight(36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controlsDisabled ? null : _cyclePosterDesign,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text(
                          strings.localized(
                            telugu: 'డిజైన్ మార్చండి',
                            english: 'Change Design',
                            hindi: 'डिज़ाइन बदलें',
                            tamil: 'வடிவமைப்பை மாற்று',
                            kannada: 'ವಿನ್ಯಾಸ ಬದಲಾಯಿಸಿ',
                            malayalam: 'ഡിസൈൻ മാറ്റുക',
                            marathi: 'डिझाइन बदला',
                            gujarati: 'ડિઝાઇન બદલો',
                            bengali: 'ডিজাইন পরিবর্তন করুন',
                            punjabi: 'ਡਿਜ਼ਾਈਨ ਬਦਲੋ',
                            odia: 'ଡିଜାଇନ୍ ବଦଳାନ୍ତୁ',
                            assamese: 'ডিজাইন সলনি কৰক',
                            konkani: 'डिझाइन बदलात',
                            nepali: 'डिजाइन परिवर्तन गर्नुहोस्',
                            meitei: 'দিজাইন হোংদোকউ',
                            mizo: 'Design thlak rawh',
                            kashmiri: 'ڈیزائن بَدلٲوِو',
                            ladakhi: 'བཟོ་བཀོད་བརྗེ་པོ་རྒྱོབ།',
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6D28D9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 8,
                          ),
                          minimumSize: const Size.fromHeight(36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => playbackEnabled;
}
