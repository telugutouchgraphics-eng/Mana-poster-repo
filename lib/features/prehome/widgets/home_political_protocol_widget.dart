// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _PoliticalProtocolPhotoSlots extends StatelessWidget {
  const _PoliticalProtocolPhotoSlots({
    required this.assetPaths,
    required this.imageUrls,
    required this.slots,
    this.hiddenImageUrls = const <String>{},
    this.assetSlots = const <PoliticalProtocolSlot>[],
  });

  final List<String> assetPaths;
  final List<String> imageUrls;
  final List<PoliticalProtocolSlot> slots;
  final Set<String> hiddenImageUrls;
  final List<PoliticalProtocolSlot> assetSlots;

  static double _slotSide({
    required double canvasWidth,
    required double canvasHeight,
    required double scale,
  }) {
    final baseSide = math.min(canvasWidth, canvasHeight) * 0.15;
    return math.max(1.0, baseSide * (scale / 100));
  }

  static double _slotCenter({
    required double value,
    required double canvasExtent,
    required double side,
  }) {
    final halfPercent = (side / math.max(1.0, canvasExtent)) * 50;
    return value.clamp(halfPercent, 100 - halfPercent).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final hiddenUrls = hiddenImageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();
    final visibleUrlSlots = <({String url, PoliticalProtocolSlot slot})>[];
    final resolvedSlots = slots.length >= defaultPoliticalProtocolSlots.length
        ? slots
              .take(defaultPoliticalProtocolSlots.length)
              .toList(growable: false)
        : defaultPoliticalProtocolSlots;
    for (
      var index = 0;
      index < imageUrls.length && index < resolvedSlots.length;
      index += 1
    ) {
      final url = imageUrls[index].trim();
      if (url.isEmpty || hiddenUrls.contains(url)) {
        continue;
      }
      visibleUrlSlots.add((url: url, slot: resolvedSlots[index]));
    }
    final visiblePaths = assetPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final totalCount = visibleUrlSlots.length + visiblePaths.length;
    if (totalCount == 0) {
      return const SizedBox.shrink();
    }
    final resolvedAssetSlots = assetSlots.length >= visiblePaths.length
        ? assetSlots.take(visiblePaths.length).toList(growable: false)
        : _fallbackManualSlots(visiblePaths.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = math.max(1.0, constraints.maxWidth);
        final canvasHeight = math.max(1.0, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (var index = 0; index < visibleUrlSlots.length; index += 1)
              Builder(
                builder: (context) {
                  final slot = visibleUrlSlots[index].slot;
                  final side = _slotSide(
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    scale: slot.scale,
                  );
                  final centerX = _slotCenter(
                    value: slot.x,
                    canvasExtent: canvasWidth,
                    side: side,
                  );
                  final centerY = _slotCenter(
                    value: slot.y,
                    canvasExtent: canvasHeight,
                    side: side,
                  );
                  final child = CachedNetworkImage(
                    imageUrl: visibleUrlSlots[index].url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _PoliticalProtocolFallback(),
                    errorWidget: (_, _, _) =>
                        const _PoliticalProtocolFallback(),
                  );
                  return Positioned(
                    left: (canvasWidth * (centerX / 100)) - (side / 2),
                    top: (canvasHeight * (centerY / 100)) - (side / 2),
                    width: side,
                    height: side,
                    child: _PoliticalProtocolCircle(side: side, child: child),
                  );
                },
              ),
            for (var index = 0; index < visiblePaths.length; index += 1)
              Builder(
                builder: (context) {
                  final slot = resolvedAssetSlots[index];
                  final side = _slotSide(
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    scale: slot.scale,
                  );
                  final centerX = _slotCenter(
                    value: slot.x,
                    canvasExtent: canvasWidth,
                    side: side,
                  );
                  final centerY = _slotCenter(
                    value: slot.y,
                    canvasExtent: canvasHeight,
                    side: side,
                  );
                  final child = _buildPoliticalProtocolAsset(
                    visiblePaths[index],
                  );
                  return Positioned(
                    left: (canvasWidth * (centerX / 100)) - (side / 2),
                    top: (canvasHeight * (centerY / 100)) - (side / 2),
                    width: side,
                    height: side,
                    child: _PoliticalProtocolCircle(side: side, child: child),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  List<PoliticalProtocolSlot> _fallbackManualSlots(int count) {
    return List<PoliticalProtocolSlot>.generate(count, (index) {
      final row = index ~/ 4;
      final col = index % 4;
      return PoliticalProtocolSlot(
        x: (22 + (col * 18)).clamp(8, 92).toDouble(),
        y: (22 + (row * 14)).clamp(8, 92).toDouble(),
        scale: 100,
      );
    }, growable: false);
  }

  Widget _buildPoliticalProtocolAsset(String path) {
    final source = path.trim();
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PoliticalProtocolFallback(),
        errorWidget: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    if (source.contains(Platform.pathSeparator)) {
      return Image.file(
        File(source),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
    );
  }
}

class _PoliticalProtocolFallback extends StatelessWidget {
  const _PoliticalProtocolFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE2E8F0),
      child: Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 18),
    );
  }
}

class _PoliticalProtocolCircle extends StatelessWidget {
  const _PoliticalProtocolCircle({required this.side, required this.child});

  final double side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: side,
      height: side,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 0.8,
        ),
      ),
      child: ClipOval(child: child),
    );
  }
}

class _PoliticalProtocolPhotoScreenResult {
  const _PoliticalProtocolPhotoScreenResult({
    required this.manualPhotoPaths,
    required this.defaultSlots,
    required this.manualSlots,
    required this.hiddenDefaultPhotoUrls,
  });

  final List<String> manualPhotoPaths;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<PoliticalProtocolSlot> manualSlots;
  final Set<String> hiddenDefaultPhotoUrls;
}

class _PoliticalProtocolPhotoScreen extends StatefulWidget {
  const _PoliticalProtocolPhotoScreen({
    required this.item,
    required this.language,
    required this.viewerPosterProfile,
    required this.politicalProtocolPhotoUrls,
    required this.partyLogoAssetPath,
    required this.showDefaultProtocolPhotos,
    required this.initialManualPhotoPaths,
    required this.initialHiddenDefaultPhotoUrls,
    required this.defaultSlots,
    required this.initialManualSlots,
    required this.ensureSubscriptionAccess,
    required this.ensureGallerySavePermission,
    required this.leaderPhotoLibraryScopeKey,
  });

  final _TemplateItem item;
  final AppLanguage language;
  final PosterProfileData viewerPosterProfile;
  final List<String> politicalProtocolPhotoUrls;
  final String? partyLogoAssetPath;
  final bool showDefaultProtocolPhotos;
  final List<String> initialManualPhotoPaths;
  final Set<String> initialHiddenDefaultPhotoUrls;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<PoliticalProtocolSlot> initialManualSlots;
  final Future<bool> Function(BuildContext context) ensureSubscriptionAccess;
  final Future<bool> Function() ensureGallerySavePermission;
  final String leaderPhotoLibraryScopeKey;

  @override
  State<_PoliticalProtocolPhotoScreen> createState() =>
      _PoliticalProtocolPhotoScreenState();
}

class _PoliticalProtocolPhotoScreenState
    extends State<_PoliticalProtocolPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScreenshotController _customPosterScreenshotController =
      ScreenshotController();
  late List<String> _manualPhotoPaths;
  late List<PoliticalProtocolSlot> _defaultSlots;
  late List<PoliticalProtocolSlot> _manualSlots;
  double? _posterImageAspectRatio;
  String? _posterImageAspectKey;
  String? _customPosterPath;
  String? _exportAction;
  List<String> _savedLeaderPhotoPaths = const <String>[];
  Set<String> _hiddenDefaultPhotoUrls = const <String>{};
  ImageStream? _posterImageStream;
  ImageStreamListener? _posterImageStreamListener;
  bool _busy = false;
  int? _deleteArmedDefaultIndex;
  int? _deleteArmedManualIndex;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
    _manualPhotoPaths = widget.initialManualPhotoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: true);
    _defaultSlots = _normalizeDefaultProtocolSlots(widget.defaultSlots);
    _manualSlots = _normalizeManualProtocolSlots(
      widget.initialManualSlots,
      _manualPhotoPaths.length,
    );
    _hiddenDefaultPhotoUrls = widget.initialHiddenDefaultPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();
    unawaited(_loadSavedLeaderPhotoPaths());
    unawaited(_loadHiddenDefaultPhotoUrls());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvePosterImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _PoliticalProtocolPhotoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.imageUrl != widget.item.imageUrl ||
        oldWidget.item.imageAssetPath != widget.item.imageAssetPath) {
      _resolvePosterImageAspectRatio(force: true);
    }
  }

  @override
  void dispose() {
    _clearPosterImageListener();
    unawaited(ScreenSecurityService.unprotectScreen());
    super.dispose();
  }

  void _clearPosterImageListener() {
    final stream = _posterImageStream;
    final listener = _posterImageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _posterImageStream = null;
    _posterImageStreamListener = null;
  }

  void _resolvePosterImageAspectRatio({bool force = false}) {
    final customPosterPath = _customPosterPath?.trim() ?? '';
    final imageUrl = widget.item.imageUrl?.trim() ?? '';
    final assetPath = widget.item.imageAssetPath?.trim() ?? '';
    final nextKey = customPosterPath.isNotEmpty
        ? 'file:$customPosterPath'
        : imageUrl.isNotEmpty
        ? 'network:$imageUrl'
        : assetPath.isNotEmpty
        ? 'asset:$assetPath'
        : '';
    if (!force && nextKey == _posterImageAspectKey) {
      return;
    }
    _posterImageAspectKey = nextKey;
    _posterImageAspectRatio = widget.item.pageConfig?.aspectRatio;
    _clearPosterImageListener();
    if (nextKey.isEmpty) {
      return;
    }
    final ImageProvider provider = customPosterPath.isNotEmpty
        ? FileImage(File(customPosterPath))
        : imageUrl.isNotEmpty
        ? CachedNetworkImageProvider(imageUrl)
        : AssetImage(assetPath);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      final width = info.image.width;
      final height = info.image.height;
      if (width <= 0 || height <= 0) {
        return;
      }
      final ratio = width / height;
      if (!mounted) {
        return;
      }
      final currentRatio = _posterImageAspectRatio;
      if (currentRatio != null && (currentRatio - ratio).abs() < 0.001) {
        return;
      }
      setState(() => _posterImageAspectRatio = ratio);
    }, onError: (_, _) {});
    _posterImageStream = stream;
    _posterImageStreamListener = listener;
    stream.addListener(listener);
  }

  List<PoliticalProtocolSlot> _normalizeDefaultProtocolSlots(
    List<PoliticalProtocolSlot> raw,
  ) {
    final source = raw.length >= defaultPoliticalProtocolSlots.length
        ? raw
        : defaultPoliticalProtocolSlots;
    return source
        .take(defaultPoliticalProtocolSlots.length)
        .map(
          (slot) => PoliticalProtocolSlot(
            x: slot.x.clamp(4.0, 96.0).toDouble(),
            y: slot.y.clamp(4.0, 96.0).toDouble(),
            scale: slot.scale.clamp(45.0, 135.0).toDouble(),
          ),
        )
        .toList(growable: true);
  }

  List<PoliticalProtocolSlot> _normalizeManualProtocolSlots(
    List<PoliticalProtocolSlot> raw,
    int count,
  ) {
    return List<PoliticalProtocolSlot>.generate(count, (index) {
      final fallback = _defaultManualSlot(index);
      final slot = index < raw.length ? raw[index] : fallback;
      return PoliticalProtocolSlot(
        x: slot.x.clamp(4.0, 96.0).toDouble(),
        y: slot.y.clamp(4.0, 96.0).toDouble(),
        scale: slot.scale.clamp(45.0, 135.0).toDouble(),
      );
    }, growable: true);
  }

  PoliticalProtocolSlot _defaultManualSlot(int index) {
    final row = index ~/ 4;
    final col = index % 4;
    return PoliticalProtocolSlot(
      x: (22 + (col * 18)).clamp(8, 92).toDouble(),
      y: (24 + (row * 14)).clamp(8, 92).toDouble(),
      scale: 100,
    );
  }

  String get _leaderPhotoLibraryPrefsKey {
    final scope = widget.leaderPhotoLibraryScopeKey.trim().isNotEmpty
        ? widget.leaderPhotoLibraryScopeKey.trim()
        : 'political';
    return 'political_leader_photo_library_v1_$scope';
  }

  String get _hiddenDefaultPhotoPrefsKey {
    final scope = widget.leaderPhotoLibraryScopeKey.trim().isNotEmpty
        ? widget.leaderPhotoLibraryScopeKey.trim()
        : 'political';
    return 'political_hidden_default_protocol_photos_v1_$scope';
  }

  Future<void> _loadSavedLeaderPhotoPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths =
          prefs
              .getStringList(_leaderPhotoLibraryPrefsKey)
              ?.map((path) => path.trim())
              .where((path) => path.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (!mounted) {
        return;
      }
      setState(() => _savedLeaderPhotoPaths = paths);
    } catch (_) {
      // Local leader photo library is optional.
    }
  }

  Future<void> _persistSavedLeaderPhotoPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _leaderPhotoLibraryPrefsKey,
      _savedLeaderPhotoPaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
    );
  }

  Future<void> _loadHiddenDefaultPhotoUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final urls =
          prefs
              .getStringList(_hiddenDefaultPhotoPrefsKey)
              ?.map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .toSet() ??
          const <String>{};
      if (!mounted) {
        return;
      }
      setState(() => _hiddenDefaultPhotoUrls = urls);
    } catch (_) {
      // Hidden default protocol photos are optional local preferences.
    }
  }

  Future<void> _persistHiddenDefaultPhotoUrls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _hiddenDefaultPhotoPrefsKey,
      _hiddenDefaultPhotoUrls.toList(growable: false),
    );
  }

  Future<void> _hideDefaultPhotoUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _hiddenDefaultPhotoUrls = <String>{..._hiddenDefaultPhotoUrls, trimmed};
      _deleteArmedDefaultIndex = null;
    });
    await _persistHiddenDefaultPhotoUrls();
  }

  Future<void> _restoreDefaultPhotoUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !_hiddenDefaultPhotoUrls.contains(trimmed)) {
      return;
    }
    setState(() {
      _hiddenDefaultPhotoUrls = _hiddenDefaultPhotoUrls
          .where((existing) => existing.trim() != trimmed)
          .toSet();
      _deleteArmedDefaultIndex = null;
    });
    await _persistHiddenDefaultPhotoUrls();
  }

  Future<void> _saveLeaderPhotoPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      final next = _savedLeaderPhotoPaths.toList(growable: true);
      next.remove(trimmed);
      next.add(trimmed);
      _savedLeaderPhotoPaths = next;
    });
    await _persistSavedLeaderPhotoPaths();
  }

  Future<void> _deleteSavedLeaderPhoto(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _savedLeaderPhotoPaths = _savedLeaderPhotoPaths
          .where((existing) => existing.trim() != trimmed)
          .toList(growable: false);
      for (var index = _manualPhotoPaths.length - 1; index >= 0; index -= 1) {
        if (_manualPhotoPaths[index].trim() == trimmed) {
          _manualPhotoPaths.removeAt(index);
          if (index < _manualSlots.length) {
            _manualSlots.removeAt(index);
          }
        }
      }
      _manualSlots = _normalizeManualProtocolSlots(
        _manualSlots,
        _manualPhotoPaths.length,
      );
      _deleteArmedManualIndex = null;
    });
    await _persistSavedLeaderPhotoPaths();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      await _deleteProtocolPhotoFile(File(trimmed));
    }
  }

  void _insertProtocolPhotoSource(String source, {int? insertIndex}) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      final boundedIndex = insertIndex == null
          ? _manualPhotoPaths.length
          : insertIndex.clamp(0, _manualPhotoPaths.length).toInt();
      _manualPhotoPaths.insert(boundedIndex, trimmed);
      _manualSlots.insert(boundedIndex, _defaultManualSlot(boundedIndex));
      _manualSlots = _normalizeManualProtocolSlots(
        _manualSlots,
        _manualPhotoPaths.length,
      );
      _deleteArmedManualIndex = null;
      _deleteArmedDefaultIndex = null;
    });
  }

  Future<void> _addPhoto({
    int? insertIndex,
    bool saveToLeaderLibrary = false,
  }) async {
    if (_busy) {
      return;
    }
    final existingCount =
        widget.politicalProtocolPhotoUrls
            .where((url) => url.trim().isNotEmpty)
            .length +
        _manualPhotoPaths.length;
    if (existingCount > 1000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'మీరు గరిష్టంగా 6 ఫోటోలను మాత్రమే జోడించగలరు.',
              english: 'You can add up to 6 photos only.',
              hindi: 'आप केवल 6 फ़ोटो तक जोड़ सकते हैं।',
              tamil:
                  'நீங்கள் அதிகபட்சமாக 6 புகைப்படங்களை மட்டுமே சேர்க்க முடியும்.',
              kannada: 'ನೀವು ಗರಿಷ್ಠ 6 ಫೋಟೋಗಳನ್ನು ಮಾತ್ರ ಸೇರಿಸಬಹುದು.',
              malayalam: 'പരമാവധി 6 ഫോട്ടോകൾ മാത്രമേ ചേർക്കാൻ കഴിയൂ.',
              marathi: 'तुम्ही फक्त 6 फोटोंपर्यंत जोडू शकता.',
              gujarati: 'તમે ફક્ત 6 ફોટા સુધી જ ઉમેરી શકો છો.',
              bengali: 'আপনি কেবল ৬টি ফটো পর্যন্ত যোগ করতে পারেন।',
              punjabi: 'ਤੁਸੀਂ ਸਿਰਫ਼ 6 ਫੋਟੋਆਂ ਤੱਕ ਜੋੜ ਸਕਦੇ ਹੋ।',
              odia: 'ଆପଣ କେବଳ ୬ଟି ଫଟୋ ପର୍ଯ୍ୟନ୍ତ ଯୋଡ଼ିପାରିବେ।',
              assamese: 'আপুনি কেৱল ৬খন ফটো যোগ কৰিব পাৰে।',
              konkani: 'तुमी फक्त 6 फोटों मेरेन जोडूंक शकतात.',
              nepali: 'तपाईं केवल ६ वटा तस्विरहरू थप्न सक्नुहुन्छ।',
              meitei: 'নহাক্না ফোতো 6 তখক হাপচিনবা য়াই।',
              mizo: 'Thlalak 6 chauh i thlang thei ang.',
              kashmiri: 'تُہؠ ہیٚکِو صرف 6 فوٹو رَلاوِتھ۔',
              ladakhi: 'ཁྱེད་ཀྱིས་པར་ ༦ ལས་ལྷག་པ་བསྣན་མི་ཐུབ།',
            ),
          ),
        ),
      );
      return;
    }
    final cropTitle = context.strings.localized(
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
    );
    setState(() => _busy = true);
    File? stagedFile;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      stagedFile = File(picked.path);
      final cropped = await ImageCropper().cropImage(
        sourcePath: stagedFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 96,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF0F172A),
            activeControlsWidgetColor: const Color(0xFF14B8A6),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white54,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            aspectRatioPresets: <CropAspectRatioPreset>[
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: cropTitle,
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      if (cropped == null) {
        return;
      }
      final bytes = await File(cropped.path).readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final path =
          '${dir.path}${Platform.pathSeparator}political_protocol_$stamp.png';
      await File(path).writeAsBytes(bytes, flush: true);
      if (!mounted) {
        return;
      }
      if (saveToLeaderLibrary) {
        await _saveLeaderPhotoPath(path);
        if (!mounted) {
          return;
        }
      }
      _insertProtocolPhotoSource(path, insertIndex: insertIndex);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ఫోటోను జోడించలేకపోయాము. దయచేసి మళ్లీ ప్రయత్నించండి.',
              english: 'Could not add the photo. Please try again.',
              hindi: 'फ़ोटो नहीं जोड़ी जा सकी। कृपया पुनः प्रयास करें।',
              tamil:
                  'புகைப்படத்தைச் சேர்க்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada: 'ಫೋಟೋ ಸೇರಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'ഫോട്ടോ ചേർക്കാനായില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
              marathi: 'फोटो जोडता आला नाही. कृपया पुन्हा प्रयत्न करा.',
              gujarati: 'ફોટો ઉમેરી શકાયો નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
              bengali: 'ফটো যোগ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
              punjabi:
                  'ਫੋਟੋ ਸ਼ਾਮਲ ਨਹੀਂ ਕੀਤੀ ਜਾ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
              odia:
                  'ଫଟୋ ଯୋଡ଼ିବା ସମ୍ଭବ ହେଲାନାହିଁ। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
              assamese: 'ফটো যোগ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
              konkani: 'फोटो जोडूंक जालो ना. उपकार करून परत यत्न करा.',
              nepali: 'फोटो थप्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
              meitei: 'ফোতো হাপচিনবা ঙমদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
              mizo: 'Thlalak dah theih a ni lo. Khawngaihin ti nawn leh rawh.',
              kashmiri:
                  'فوٹو ہیٚکہ نہٕ رَلٲوِتھ۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
              ladakhi: 'པར་བསྣན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _removeManualPhoto(int manualIndex) {
    if (manualIndex < 0 || manualIndex >= _manualPhotoPaths.length) {
      return;
    }
    final removedPath = _manualPhotoPaths.removeAt(manualIndex);
    if (manualIndex < _manualSlots.length) {
      _manualSlots.removeAt(manualIndex);
    }
    if (!removedPath.startsWith('http://') &&
        !removedPath.startsWith('https://')) {
      unawaited(_deleteProtocolPhotoFile(File(removedPath)));
    }
    setState(() => _deleteArmedManualIndex = null);
  }

  Future<void> _deleteProtocolPhotoFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Local protocol photos are disposable UI assets.
    }
  }

  Future<void> _pickCustomPoster() async {
    if (_busy || _exportAction != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      final pickedFile = File(picked.path);
      final pickedName = picked.path.split(RegExp(r'[\\/]')).last;
      final dotIndex = pickedName.lastIndexOf('.');
      final extension = dotIndex >= 0 ? pickedName.substring(dotIndex) : '.jpg';
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final path =
          '${dir.path}${Platform.pathSeparator}political_custom_poster_$stamp$extension';
      await pickedFile.copy(path);
      if (!mounted) {
        return;
      }
      setState(() {
        _customPosterPath = path;
        _deleteArmedManualIndex = null;
      });
      _resolvePosterImageAspectRatio(force: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showScreenSnack(context.strings.couldNotAddPoster);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _captureCustomPosterFile() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await WidgetsBinding.instance.endOfFrame;
    final bytes = await _customPosterScreenshotController.capture(
      pixelRatio: 3,
    );
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}mana_political_poster_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String get _customPosterShareText {
    final activeName = widget.viewerPosterProfile.activeName.trim();
    final resolvedName = widget.viewerPosterProfile
        .resolvedName(language: widget.language)
        .trim();
    final userName = activeName.isNotEmpty
        ? activeName
        : resolvedName.isNotEmpty
        ? resolvedName
        : 'User';
    return 'Shared by $userName using ${AppPublicInfo.appName}\n'
        'Download the app: ${AppPublicInfo.playStoreUrl}';
  }

  Future<void> _downloadCustomPoster() async {
    if (_exportAction != null) {
      return;
    }
    setState(() => _exportAction = 'download');
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
    final captureFailedMessage = context.strings.localized(
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
    final savedMessage = context.strings.localized(
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
      final hasAccess = await widget.ensureSubscriptionAccess(context);
      if (!hasAccess) {
        return;
      }
      final hasPermission = await widget.ensureGallerySavePermission();
      if (!hasPermission) {
        _showScreenSnack(galleryPermissionMessage);
        return;
      }
      final path = await _captureCustomPosterFile();
      if (path == null) {
        _showScreenSnack(captureFailedMessage);
        return;
      }
      final saveResult = await MediaExportService.saveImageFileToGalleryDetailed(
        path,
        fileName:
            'mana_political_poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      _showScreenSnack(
        saveResult.success ? savedMessage : downloadFailedMessage,
      );
    } catch (_) {
      _showScreenSnack(downloadFailedMessage);
    } finally {
      if (mounted) {
        setState(() => _exportAction = null);
      }
    }
  }

  Future<void> _shareCustomPoster() async {
    if (_exportAction != null) {
      return;
    }
    setState(() => _exportAction = 'share');
    final captureFailedMessage = context.strings.localized(
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
      mizo: 'Share a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'شیئر گوو ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
      ladakhi: 'བགོ་འགྲེམས་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
    );
    try {
      final hasAccess = await widget.ensureSubscriptionAccess(context);
      if (!hasAccess) {
        return;
      }
      final path = await _captureCustomPosterFile();
      if (path == null) {
        _showScreenSnack(captureFailedMessage);
        return;
      }
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        path,
        text: _customPosterShareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      _showScreenSnack(shareFailedMessage);
    } finally {
      if (mounted) {
        setState(() => _exportAction = null);
      }
    }
  }

  void _showScreenSnack(String message) {
    if (!mounted || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPhotoSlot({
    required double side,
    required Widget child,
    required bool isPlus,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPlus
              ? const Color(0xFF14B8A6)
              : Colors.white.withValues(alpha: 0.95),
          border: Border.all(color: Colors.white, width: 0.8),
        ),
        child: ClipOval(child: child),
      ),
    );
  }

  Widget _buildProtocolPhotoSource(String source) {
    final trimmed = source.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PoliticalProtocolFallback(),
        errorWidget: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    return Image.file(
      File(trimmed),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
    );
  }

  List<String> get _extraAdminProtocolPhotoUrls {
    return widget.politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .skip(defaultPoliticalProtocolSlots.length)
        .toList(growable: false);
  }

  List<String> get _hiddenDefaultProtocolPhotoUrls {
    return widget.politicalProtocolPhotoUrls
        .map((url) => url.trim())
        .take(defaultPoliticalProtocolSlots.length)
        .where((url) => url.isNotEmpty && _hiddenDefaultPhotoUrls.contains(url))
        .toList(growable: false);
  }

  Future<void> _openPartyLeaderPhotoSheet() async {
    if (_busy || _exportAction != null) {
      return;
    }
    final adminUrls = _extraAdminProtocolPhotoUrls;
    final hiddenDefaultUrls = _hiddenDefaultProtocolPhotoUrls;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final savedPaths = _savedLeaderPhotoPaths
                .map((path) => path.trim())
                .where((path) => path.isNotEmpty)
                .toList(growable: false);
            final totalCount =
                hiddenDefaultUrls.length +
                adminUrls.length +
                savedPaths.length +
                1;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.strings.addPartyLeaderPhotos,
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.strings.tapPhotoToPlaceOnPoster,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          if (index < hiddenDefaultUrls.length) {
                            final url = hiddenDefaultUrls[index];
                            return _buildPhotoSlot(
                              side: 62,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    const _PoliticalProtocolFallback(),
                                errorWidget: (_, _, _) =>
                                    const _PoliticalProtocolFallback(),
                              ),
                              isPlus: false,
                              onTap: () => Navigator.of(
                                sheetContext,
                              ).pop('__restore_default::$url'),
                            );
                          }
                          final adminIndex = index - hiddenDefaultUrls.length;
                          if (adminIndex < adminUrls.length) {
                            final url = adminUrls[adminIndex];
                            return _buildPhotoSlot(
                              side: 62,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    const _PoliticalProtocolFallback(),
                                errorWidget: (_, _, _) =>
                                    const _PoliticalProtocolFallback(),
                              ),
                              isPlus: false,
                              onTap: () => Navigator.of(sheetContext).pop(url),
                            );
                          }
                          final savedIndex =
                              index -
                              hiddenDefaultUrls.length -
                              adminUrls.length;
                          if (savedIndex < savedPaths.length) {
                            final path = savedPaths[savedIndex];
                            return SizedBox(
                              width: 68,
                              height: 68,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  Positioned.fill(
                                    child: Center(
                                      child: _buildPhotoSlot(
                                        side: 62,
                                        child: _buildProtocolPhotoSource(path),
                                        isPlus: false,
                                        onTap: () => Navigator.of(
                                          sheetContext,
                                        ).pop(path),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -1,
                                    top: -1,
                                    child: GestureDetector(
                                      onTap: () async {
                                        await _deleteSavedLeaderPhoto(path);
                                        if (mounted) {
                                          setSheetState(() {});
                                        }
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return _buildPhotoSlot(
                            side: 62,
                            isPlus: true,
                            onTap: () =>
                                Navigator.of(sheetContext).pop('__add'),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemCount: totalCount,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || selected == null) {
      return;
    }
    if (selected == '__add') {
      await _addPhoto(saveToLeaderLibrary: true);
      return;
    }
    if (selected.startsWith('__restore_default::')) {
      await _restoreDefaultPhotoUrl(
        selected.substring('__restore_default::'.length),
      );
      return;
    }
    _insertProtocolPhotoSource(selected);
  }

  Widget _buildAdminPhotoPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Center(
        child: FilledButton.icon(
          onPressed: _busy || _exportAction != null
              ? null
              : () => unawaited(_openPartyLeaderPhotoSheet()),
          icon: _busy
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.group_add_rounded, size: 18),
          label: Text(
            context.strings.addPartyLeaderPhotos,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterPhotoSlots({
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final adminUrls = widget.showDefaultProtocolPhotos
        ? widget.politicalProtocolPhotoUrls
              .map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .take(_defaultSlots.length)
              .toList(growable: false)
        : const <String>[];
    return _EditablePoliticalProtocolOverlay(
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      adminUrls: adminUrls,
      defaultSlots: _defaultSlots,
      manualPhotoPaths: _manualPhotoPaths,
      manualSlots: _manualSlots,
      hiddenDefaultPhotoUrls: _hiddenDefaultPhotoUrls,
      deleteArmedDefaultIndex: _deleteArmedDefaultIndex,
      deleteArmedManualIndex: _deleteArmedManualIndex,
      onDefaultSlotChanged: (index, slot) {
        if (index >= 0 && index < _defaultSlots.length) {
          _defaultSlots[index] = slot;
        }
      },
      onDefaultPhotoTap: (index, url) {
        if (_deleteArmedDefaultIndex == index) {
          unawaited(_hideDefaultPhotoUrl(url));
          return;
        }
        setState(() {
          _deleteArmedDefaultIndex = index;
          _deleteArmedManualIndex = null;
        });
      },
      onManualSlotChanged: (index, slot) {
        if (index >= 0 && index < _manualSlots.length) {
          _manualSlots[index] = slot;
        }
      },
      onManualPhotoTap: (index) {
        if (_deleteArmedManualIndex == index) {
          _removeManualPhoto(index);
          return;
        }
        setState(() {
          _deleteArmedDefaultIndex = null;
          _deleteArmedManualIndex = index;
        });
      },
    );
  }

  Widget _buildPosterImage() {
    final customPosterPath = _customPosterPath?.trim() ?? '';
    if (customPosterPath.isNotEmpty) {
      return Image.file(
        File(customPosterPath),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFF111827),
          child: Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54),
          ),
        ),
      );
    }
    final imageUrl = widget.item.imageUrl?.trim() ?? '';
    final assetPath = widget.item.imageAssetPath?.trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain);
    }
    if (assetPath.isNotEmpty) {
      return Image.asset(assetPath, fit: BoxFit.contain);
    }
    return const ColoredBox(
      color: Color(0xFF111827),
      child: Center(
        child: Icon(Icons.image_not_supported_rounded, color: Colors.white54),
      ),
    );
  }

  EditorPageConfig _currentPosterPageConfig() {
    final existing = widget.item.pageConfig;
    final aspectRatio = _posterImageAspectRatio ?? existing?.aspectRatio ?? 1.0;
    if (aspectRatio <= 0) {
      return existing ?? EditorPageConfig.defaultConfig;
    }
    const baseWidth = 1080;
    final resolvedHeight = math.max(1, (baseWidth / aspectRatio).round());
    return EditorPageConfig(
      name: existing?.name ?? 'Full Screen Poster',
      widthPx: baseWidth,
      heightPx: resolvedHeight,
      dpi: existing?.dpi ?? EditorPageConfig.defaultConfig.dpi,
    );
  }

  Widget _buildCustomPosterBase(VoidCallback onReady) {
    final customPosterPath = _customPosterPath?.trim() ?? '';
    if (customPosterPath.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
      return _buildPosterImage();
    }
    return Image.file(
      File(customPosterPath),
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null || wasSynchronouslyLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
        }
        return child;
      },
      errorBuilder: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
        return const ColoredBox(
          color: Color(0xFF111827),
          child: Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54),
          ),
        );
      },
    );
  }

  Widget _buildPersonalizedPosterBase() {
    final personalizationConfig = widget.item.personalizationConfig;
    if (personalizationConfig == null) {
      return _buildPosterImage();
    }
    final hasCustomPoster = (_customPosterPath?.trim().isNotEmpty ?? false);
    return _CreatorPosterPreview(
      imageAssetPath: hasCustomPoster ? null : widget.item.imageAssetPath,
      imageUrl: hasCustomPoster ? null : widget.item.imageUrl,
      imageStoragePath: hasCustomPoster ? null : widget.item.imageStoragePath,
      thumbnailStoragePath: hasCustomPoster
          ? null
          : widget.item.thumbnailStoragePath,
      thumbnailUrl: hasCustomPoster ? null : widget.item.thumbnailUrl,
      pageConfig: _currentPosterPageConfig(),
      basePosterBuilder: hasCustomPoster ? _buildCustomPosterBase : null,
      personalizationConfig: personalizationConfig,
      preferOriginalPosterQuality: true,
      viewerPosterProfile: widget.viewerPosterProfile,
      language: widget.language,
      partyLogoAssetPath: widget.partyLogoAssetPath,
      politicalProtocolPhotoUrls: const <String>[],
      politicalProtocolLocalPhotoPaths: const <String>[],
      politicalProtocolSlotsOverride: const <PoliticalProtocolSlot>[],
      politicalProtocolManualSlots: const <PoliticalProtocolSlot>[],
      showPoliticalProtocolOverlay: false,
      showProfilePhoto: true,
      deferLegacyTextPrime: false,
      posterRenderCycle: 0,
      interactivePhotoEnabled: false,
      photoShapeOverride: '',
      photoRenderModeOverride: '',
      photoFlipHorizontally: false,
      photoXOffsetPercent: 0,
      photoYOffsetPercent: 0,
      onPhotoTap: () {},
      stripGradientTapOffset: 0,
      additionalPhotoSelection: null,
      onAdditionalPhotoTap: null,
      onPhotoDragDeltaPercent:
          ({required double deltaXPercent, required double deltaYPercent}) {},
      onPhotoDragStateChanged: (_) {},
    );
  }

  Widget _buildPosterActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
    bool loading = false,
    Color? backgroundColor,
    Color? foregroundColor,
    double minimumHeight = 46,
    double borderRadius = 12,
    double fontSize = 14,
    double iconSize = 18,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (loading)
          const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: iconSize),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF0F766E),
          foregroundColor: foregroundColor ?? Colors.white,
          minimumSize: Size(0, minimumHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F172A),
        minimumSize: Size(0, minimumHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: child,
    );
  }

  Widget _buildCustomPosterActions() {
    final busy = _busy || _exportAction != null;
    final hasCustomPoster = (_customPosterPath?.trim().isNotEmpty ?? false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: _buildPosterActionButton(
              icon: Icons.add_photo_alternate_rounded,
              label: hasCustomPoster
                  ? context.strings.changeYourPoster
                  : context.strings.addYourPoster,
              onPressed: busy ? null : () => unawaited(_pickCustomPoster()),
              filled: true,
              loading: _busy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildPosterActionButton(
                  icon: Icons.ios_share_rounded,
                  label: context.strings.localized(
                    telugu: 'Share',
                    english: 'Share',
                    hindi: 'Share',
                    tamil: 'Share',
                    kannada: 'Share',
                    malayalam: 'Share',
                    marathi: 'Share',
                    gujarati: 'Share',
                    bengali: 'Share',
                    punjabi: 'Share',
                    odia: 'Share',
                    assamese: 'Share',
                    konkani: 'Share',
                    nepali: 'Share',
                    meitei: 'Share',
                    mizo: 'Share',
                    kashmiri: 'Share',
                    ladakhi: 'Share',
                  ),
                  onPressed: busy
                      ? null
                      : () => unawaited(_shareCustomPoster()),
                  filled: true,
                  backgroundColor: const Color(0xFF25D366),
                  minimumHeight: 32,
                  borderRadius: 999,
                  fontSize: 12,
                  iconSize: 17,
                  loading: _exportAction == 'share',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPosterActionButton(
                  icon: Icons.download_rounded,
                  label: context.strings.localized(
                    telugu: 'Download',
                    english: 'Download',
                    hindi: 'Download',
                    tamil: 'Download',
                    kannada: 'Download',
                    malayalam: 'Download',
                    marathi: 'Download',
                    gujarati: 'Download',
                    bengali: 'Download',
                    punjabi: 'Download',
                    odia: 'Download',
                    assamese: 'Download',
                    konkani: 'Download',
                    nepali: 'Download',
                    meitei: 'Download',
                    mizo: 'Download',
                    kashmiri: 'Download',
                    ladakhi: 'Download',
                  ),
                  onPressed: busy
                      ? null
                      : () => unawaited(_downloadCustomPoster()),
                  filled: true,
                  backgroundColor: const Color(0xFF64748B),
                  minimumHeight: 32,
                  borderRadius: 999,
                  fontSize: 12,
                  iconSize: 17,
                  loading: _exportAction == 'download',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAspectRatio =
        _posterImageAspectRatio ?? widget.item.pageConfig?.aspectRatio;
    final posterStage = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.max(1.0, constraints.maxWidth);
        final maxHeight = math.max(1.0, constraints.maxHeight);
        final aspectRatio = pageAspectRatio != null && pageAspectRatio > 0
            ? pageAspectRatio
            : maxWidth / maxHeight;
        final posterWidth = math.min(maxWidth, maxHeight * aspectRatio);
        final posterHeight = posterWidth / aspectRatio;
        final posterLeft = (maxWidth - posterWidth) / 2;
        final posterTop = (maxHeight - posterHeight) / 2;
        return Stack(
          children: <Widget>[
            Positioned(
              left: posterLeft,
              top: posterTop,
              width: posterWidth,
              height: posterHeight,
              child: Screenshot(
                controller: _customPosterScreenshotController,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _buildPersonalizedPosterBase(),
                    _buildPosterPhotoSlots(
                      canvasWidth: posterWidth,
                      canvasHeight: posterHeight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.6,
        title: Text(context.strings.addPoliticalPhotos),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              _PoliticalProtocolPhotoScreenResult(
                manualPhotoPaths: _manualPhotoPaths,
                defaultSlots: _defaultSlots,
                manualSlots: _manualSlots,
                hiddenDefaultPhotoUrls: _hiddenDefaultPhotoUrls,
              ),
            ),
            child: Text(
              context.strings.doneLabel,
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_deleteArmedDefaultIndex != null ||
                _deleteArmedManualIndex != null) {
              setState(() {
                _deleteArmedDefaultIndex = null;
                _deleteArmedManualIndex = null;
              });
            }
          },
          child: Column(
            children: <Widget>[
              _buildAdminPhotoPicker(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: posterStage,
                  ),
                ),
              ),
              _buildCustomPosterActions(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Text(
                  context.strings.politicalProtocolPhotoHelp,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

