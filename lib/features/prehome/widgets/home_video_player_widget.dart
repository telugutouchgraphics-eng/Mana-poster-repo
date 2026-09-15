// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _FeedTapToPlayVideoPoster extends StatefulWidget {
  const _FeedTapToPlayVideoPoster({
    required this.videoUrl,
    this.playbackEnabled = true,
    this.imageAssetPath,
    this.imageUrl,
    this.imageStoragePath,
    this.thumbnailStoragePath,
    this.thumbnailUrl,
    this.onAspectRatioResolved,
    this.onReady,
    this.onOpenPreview,
    this.onReplay,
  });

  final String videoUrl;
  final bool playbackEnabled;
  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onReady;
  final VoidCallback? onOpenPreview;
  final VoidCallback? onReplay;

  @override
  State<_FeedTapToPlayVideoPoster> createState() =>
      _FeedTapToPlayVideoPosterState();
}

class _FeedTapToPlayVideoPosterState extends State<_FeedTapToPlayVideoPoster> {
  bool _playing = true;

  bool get _hasStillFrame =>
      (widget.imageAssetPath?.trim().isNotEmpty ?? false) ||
      (widget.imageUrl?.trim().isNotEmpty ?? false) ||
      (widget.thumbnailUrl?.trim().isNotEmpty ?? false) ||
      (widget.imageStoragePath?.trim().isNotEmpty ?? false) ||
      (widget.thumbnailStoragePath?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    if (!_hasStillFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReady?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_playing) {
      return _TemplateVideoPlayer(
        videoUrl: widget.videoUrl,
        playbackEnabled: widget.playbackEnabled,
        onAspectRatioResolved: widget.onAspectRatioResolved,
        onReady: widget.onReady,
        onOpenPreview: widget.onOpenPreview,
        onReplay: widget.onReplay,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOpenPreview ?? () => setState(() => _playing = true),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          if (_hasStillFrame)
            _ResolvedTemplatePosterImage(
              imageAssetPath: widget.imageAssetPath,
              imageUrl: widget.imageUrl ?? '',
              imageStoragePath: widget.imageStoragePath,
              thumbnailStoragePath: widget.thumbnailStoragePath,
              thumbnailUrl: widget.thumbnailUrl,
              onAspectRatioResolved: widget.onAspectRatioResolved,
              onFirstFrameReady: widget.onReady,
            )
          else
            const ColoredBox(color: Color(0xFFEFF3F8)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.26),
              ),
            ),
          ),
          Icon(
            Icons.play_circle_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.94),
          ),
        ],
      ),
    );
  }
}

class _TemplateVideoPlayer extends StatefulWidget {
  const _TemplateVideoPlayer({
    required this.videoUrl,
    this.playbackEnabled = true,
    this.onAspectRatioResolved,
    this.onReady,
    this.onOpenPreview,
    this.onReplay,
  });

  final String videoUrl;
  final bool playbackEnabled;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onReady;
  final VoidCallback? onOpenPreview;
  final VoidCallback? onReplay;

  @override
  State<_TemplateVideoPlayer> createState() => _TemplateVideoPlayerState();
}

class _TemplateVideoPlayerState extends State<_TemplateVideoPlayer> {
  static const Duration _initialVideoInitDelay = Duration(milliseconds: 900);

  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _readyNotified = false;
  bool _showPlayOverlay = false;
  bool _userPaused = false;
  Duration _lastPosition = Duration.zero;
  DateTime? _lastReplayNotificationAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_initialVideoInitDelay, () {
        _initializeWhenSettled();
      });
    });
  }

  @override
  void didUpdateWidget(covariant _TemplateVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _readyNotified = false;
      _hasError = false;
      _showPlayOverlay = false;
      _userPaused = false;
      _lastPosition = Duration.zero;
      _lastReplayNotificationAt = null;
      unawaited(_disposeController());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(_initialVideoInitDelay, () {
          _initializeWhenSettled();
        });
      });
    } else if (oldWidget.playbackEnabled != widget.playbackEnabled) {
      unawaited(_applyPlaybackPolicy());
    }
  }

  void _initializeWhenSettled([int attempt = 0]) {
    if (!mounted || _controller != null) {
      return;
    }
    if (Scrollable.recommendDeferredLoadingForContext(context) && attempt < 8) {
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        _initializeWhenSettled(attempt + 1);
      });
      return;
    }
    unawaited(_initialize());
  }

  void _handlePlaybackTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    if (duration.inMilliseconds <= 0) {
      _lastPosition = position;
      return;
    }
    final loopedToStart =
        position <= const Duration(milliseconds: 450) &&
        _lastPosition >= duration * 0.72 &&
        position < _lastPosition;
    if (loopedToStart) {
      final now = DateTime.now();
      final lastNotified = _lastReplayNotificationAt;
      if (lastNotified == null ||
          now.difference(lastNotified) > const Duration(milliseconds: 900)) {
        _lastReplayNotificationAt = now;
        widget.onReplay?.call();
      }
    }
    _lastPosition = position;
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_handlePlaybackTick);
      await controller.dispose();
    }
  }

  Future<void> _initialize() async {
    final uri = Uri.tryParse(widget.videoUrl.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      final videoSize = controller.value.size;
      if (videoSize.width > 0 && videoSize.height > 0) {
        widget.onAspectRatioResolved?.call(videoSize.width / videoSize.height);
      }
      await controller.setLooping(true);
      await controller.setVolume(1.0);
      controller.addListener(_handlePlaybackTick);
      if (widget.playbackEnabled && !_userPaused) {
        await controller.play();
      } else {
        await controller.pause();
      }
      if (!mounted) {
        return;
      }
      if (!_readyNotified) {
        _readyNotified = true;
        widget.onReady?.call();
      }
      setState(() {});
    } catch (_) {
      controller.removeListener(_handlePlaybackTick);
      if (!mounted) {
        return;
      }
      setState(() => _hasError = true);
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
      if (mounted) {
        setState(() {
          _userPaused = true;
          _showPlayOverlay = true;
        });
      }
      return;
    }
    _userPaused = false;
    await controller.play();
    if (mounted) {
      setState(() => _showPlayOverlay = false);
    }
  }

  Future<void> _applyPlaybackPolicy() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (!widget.playbackEnabled) {
      if (controller.value.isPlaying) {
        await controller.pause();
      }
      return;
    }
    if (!_userPaused && !controller.value.isPlaying) {
      await controller.play();
      if (mounted && _showPlayOverlay) {
        setState(() => _showPlayOverlay = false);
      }
    }
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_hasError || controller == null) {
      return _ImageErrorState(
        title: context.strings.localized(
          telugu: 'వీడియో అందుబాటులో లేదు',
          english: 'Video unavailable',
          hindi: 'वीडियो उपलब्ध नहीं है',
          tamil: 'வீடியோ கிடைக்கவில்லை',
          kannada: 'ವೀಡಿಯೊ ಲಭ್ಯವಿಲ್ಲ',
          malayalam: 'വീഡിയോ ലഭ്യമല്ല',
          marathi: 'व्हिडिओ उपलब्ध नाही',
          gujarati: 'વીડિયો ઉપલબ્ધ નથી',
          bengali: 'ভিডিও উপলব্ধ নয়',
          punjabi: 'ਵੀਡੀਓ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
          odia: 'ଭିଡିଓ ଉପଲବ୍ଧ ନାହିଁ',
          assamese: 'ভিডিঅ’ উপলব্ধ নহয়',
          konkani: 'व्हिडिओ उपलब्ध ना',
          nepali: 'भिडियो उपलब्ध छैन',
          meitei: 'ভিদিও ফংদে',
          mizo: 'Video a awm lo',
          kashmiri: 'ویڈیو چھُنہٕ دستیاب',
          ladakhi: 'བརྙན་འཕྲིན་མི་འདུག',
        ),
        subtitle: context.strings.localized(
          telugu: 'దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'Please try again.',
          hindi: 'कृपया पुनः प्रयास करें।',
          tamil: 'மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali: 'অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi: 'ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'उपकार करून परत यत्न करा.',
          nepali: 'कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
          mizo: 'Khawngaihin ti nawn leh rawh.',
          kashmiri: 'مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
          ladakhi: 'སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
        ),
      );
    }
    if (!controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: _ImageLoadingState(),
      );
    }
    final videoSize = controller.value.size;
    final videoWidth = videoSize.width > 0 ? videoSize.width : 9.0;
    final videoHeight = videoSize.height > 0 ? videoSize.height : 16.0;
    final aspectRatio = videoWidth > 0 && videoHeight > 0
        ? videoWidth / videoHeight
        : 9 / 16;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOpenPreview ?? () => unawaited(_togglePlayback()),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: <Widget>[
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: videoWidth,
                    height: videoHeight,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
            if (_showPlayOverlay)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

