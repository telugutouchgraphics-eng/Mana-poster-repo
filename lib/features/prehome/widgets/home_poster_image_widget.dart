// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _TemplatePosterImage extends StatefulWidget {
  const _TemplatePosterImage({
    required this.imageAssetPath,
    required this.imageUrl,
    this.thumbnailUrl,
    this.fixedAspectRatio,
    this.preferOriginalPosterQuality = false,
    this.preferUltraLightDecode = false,
    this.onAspectRatioResolved,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? fixedAspectRatio;
  final bool preferOriginalPosterQuality;
  final bool preferUltraLightDecode;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onFirstFrameReady;

  @override
  State<_TemplatePosterImage> createState() => _TemplatePosterImageState();
}

class _TemplatePosterImageState extends State<_TemplatePosterImage> {
  static const int _feedPosterDecodeMinWidth = 280;
  static const int _feedPosterDecodeMaxWidth = 960;
  static const int _feedPosterThumbMinWidth = 180;
  static const int _feedPosterThumbMaxWidth = 360;
  static final Map<Object, double> _aspectRatioCache = <Object, double>{};
  ImageProvider<Object>? _mainNetworkProvider;
  ImageProvider<Object>? _thumbnailProvider;
  String? _mainProviderUrl;
  String? _thumbnailProviderUrl;
  int? _mainProviderWidth;
  int? _thumbnailProviderWidth;
  Object? _aspectRatioSource;
  ImageStream? _aspectRatioStream;
  ImageStreamListener? _aspectRatioListener;
  double? _resolvedAspectRatio;

  @override
  void didUpdateWidget(covariant _TemplatePosterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.preferOriginalPosterQuality !=
            widget.preferOriginalPosterQuality ||
        oldWidget.preferUltraLightDecode != widget.preferUltraLightDecode ||
        oldWidget.fixedAspectRatio != widget.fixedAspectRatio ||
        oldWidget.onAspectRatioResolved != widget.onAspectRatioResolved) {
      _mainNetworkProvider = null;
      _thumbnailProvider = null;
      _mainProviderUrl = null;
      _thumbnailProviderUrl = null;
      _mainProviderWidth = null;
      _thumbnailProviderWidth = null;
      _resetAspectRatioResolution();
    }
  }

  @override
  void dispose() {
    _detachAspectRatioListener();
    super.dispose();
  }

  void _resetAspectRatioResolution() {
    _detachAspectRatioListener();
    _aspectRatioSource = null;
    _resolvedAspectRatio = null;
  }

  void _detachAspectRatioListener() {
    final stream = _aspectRatioStream;
    final listener = _aspectRatioListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _aspectRatioStream = null;
    _aspectRatioListener = null;
  }

  void _resolveAspectRatio({
    required Object sourceKey,
    required ImageProvider<Object> provider,
  }) {
    if (_aspectRatioSource == sourceKey && _resolvedAspectRatio != null) {
      return;
    }
    if (_aspectRatioSource == sourceKey && _aspectRatioListener != null) {
      return;
    }
    final cachedAspectRatio = _aspectRatioCache[sourceKey];
    if (cachedAspectRatio != null && cachedAspectRatio > 0) {
      _aspectRatioSource = sourceKey;
      _resolvedAspectRatio = cachedAspectRatio;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _aspectRatioSource == sourceKey) {
          widget.onAspectRatioResolved?.call(cachedAspectRatio);
        }
      });
      return;
    }

    _detachAspectRatioListener();
    _aspectRatioSource = sourceKey;

    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final width = info.image.width;
        final height = info.image.height;
        if (width <= 0 || height <= 0 || !mounted) {
          return;
        }
        final nextAspectRatio = width / height;
        if (_resolvedAspectRatio == nextAspectRatio &&
            _aspectRatioSource == sourceKey) {
          return;
        }
        _aspectRatioCache[sourceKey] = nextAspectRatio;
        void applyAspectRatio() {
          if (!mounted || _aspectRatioSource != sourceKey) {
            return;
          }
          setState(() {
            _resolvedAspectRatio = nextAspectRatio;
          });
          widget.onAspectRatioResolved?.call(nextAspectRatio);
          _detachAspectRatioListener();
        }

        if (synchronousCall) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            applyAspectRatio();
          });
        } else {
          applyAspectRatio();
        }
      },
      onError: (_, _) {
        if (_aspectRatioSource == sourceKey) {
          _detachAspectRatioListener();
        }
      },
    );
    _aspectRatioStream = stream;
    _aspectRatioListener = listener;
    stream.addListener(listener);
  }

  ImageProvider<Object> _networkProviderFor({
    required String url,
    required int decodeWidth,
  }) {
    final baseProvider = widget.preferOriginalPosterQuality
        ? CachedNetworkImageProvider(
            url,
            cacheManager: PosterNetworkImageCache.instance,
          )
        : CachedNetworkImageProvider(
            url,
            cacheManager: PosterNetworkImageCache.instance,
            maxWidth: PosterNetworkImageLimits.diskFeedMaxWidth,
            maxHeight: PosterNetworkImageLimits.diskFeedMaxHeight,
          );
    if (widget.preferOriginalPosterQuality) {
      return baseProvider;
    }
    return ResizeImage.resizeIfNeeded(decodeWidth, null, baseProvider);
  }

  ImageProvider<Object> _mainProviderFor(String url, int decodeWidth) {
    if (_mainNetworkProvider == null ||
        _mainProviderUrl != url ||
        _mainProviderWidth != decodeWidth) {
      _mainProviderUrl = url;
      _mainProviderWidth = decodeWidth;
      _mainNetworkProvider = _networkProviderFor(
        url: url,
        decodeWidth: decodeWidth,
      );
    }
    return _mainNetworkProvider!;
  }

  ImageProvider<Object> _thumbnailProviderFor(String url, int decodeWidth) {
    if (_thumbnailProvider == null ||
        _thumbnailProviderUrl != url ||
        _thumbnailProviderWidth != decodeWidth) {
      _thumbnailProviderUrl = url;
      _thumbnailProviderWidth = decodeWidth;
      _thumbnailProvider = _networkProviderFor(
        url: url,
        decodeWidth: decodeWidth,
      );
    }
    return _thumbnailProvider!;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          void schedulePosterReady() {
            final VoidCallback? cb = widget.onFirstFrameReady;
            if (cb != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => cb());
            }
          }

          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final pixelRatio = MediaQuery.devicePixelRatioOf(
            context,
          ).clamp(1.0, 3.0);
          final shouldPreferUltraLightDecode =
              !widget.preferOriginalPosterQuality &&
              widget.preferUltraLightDecode;
          final cacheWidth = shouldPreferUltraLightDecode
              ? (width * pixelRatio).round().clamp(
                  _feedPosterThumbMinWidth,
                  _feedPosterThumbMaxWidth,
                )
              : widget.preferOriginalPosterQuality
              ? (width * pixelRatio).round().clamp(320, 2048)
              : (width * pixelRatio).round().clamp(
                  _feedPosterDecodeMinWidth,
                  _feedPosterDecodeMaxWidth,
                );
          final posterPlaceholderHeight = width.isFinite && width >= 48
              ? math.max(width * 1.25, 260.0)
              : 260.0;

          final placeholderUrl = widget.thumbnailUrl?.trim() ?? '';
          final mainUrlTrim = (widget.imageUrl ?? '').trim();
          final primaryNetworkUrl = mainUrlTrim.isNotEmpty
              ? mainUrlTrim
              : placeholderUrl;

          Widget buildNetworkPosterImage({
            required String resolvedUrl,
            required int decodeWidth,
            required bool notifyWhenLoaded,
          }) {
            final imageProvider = _mainProviderFor(resolvedUrl, decodeWidth);
            final loadingThumb = placeholderUrl;
            final hasSeparateThumbnail =
                loadingThumb.isNotEmpty && loadingThumb != resolvedUrl;
            final ImageProvider<Object>? thumbnailProvider =
                hasSeparateThumbnail
                ? _thumbnailProviderFor(
                    loadingThumb,
                    decodeWidth.clamp(
                      _feedPosterThumbMinWidth,
                      _feedPosterThumbMaxWidth,
                    ),
                  )
                : null;
            return Image(
              image: imageProvider,
              width: double.infinity,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              filterQuality: widget.preferOriginalPosterQuality
                  ? FilterQuality.high
                  : FilterQuality.medium,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  if (notifyWhenLoaded && widget.onFirstFrameReady != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onFirstFrameReady!.call();
                    });
                  }
                  if (thumbnailProvider == null) {
                    return child;
                  }
                  return child;
                }
                if (thumbnailProvider != null) {
                  return Image(
                    image: thumbnailProvider,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    filterQuality: widget.preferOriginalPosterQuality
                        ? FilterQuality.high
                        : FilterQuality.medium,
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  height: posterPlaceholderHeight,
                  child: const _ImageLoadingState(),
                );
              },
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                final strings = context.strings;
                final failed = resolvedUrl.trim();
                final thumb = placeholderUrl;
                if (thumb.isNotEmpty && thumb != failed) {
                  return buildNetworkPosterImage(
                    resolvedUrl: thumb,
                    decodeWidth: decodeWidth.clamp(360, 960),
                    notifyWhenLoaded: true,
                  );
                }
                if (_shouldRetryUnavailableNetworkImage(failed) &&
                    (failed.startsWith('http://') ||
                        failed.startsWith('https://'))) {
                  unawaited(
                    PosterNetworkImageCache.instance.removeFile(failed),
                  );
                  return Image(
                    image: widget.preferOriginalPosterQuality
                        ? NetworkImage(failed)
                        : ResizeImage.resizeIfNeeded(
                            decodeWidth,
                            null,
                            NetworkImage(failed),
                          ),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    filterQuality: widget.preferOriginalPosterQuality
                        ? FilterQuality.high
                        : FilterQuality.medium,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            if (notifyWhenLoaded &&
                                widget.onFirstFrameReady != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                widget.onFirstFrameReady!.call();
                              });
                            }
                            return child;
                          }
                          return SizedBox(
                            width: double.infinity,
                            height: posterPlaceholderHeight,
                            child: const _ImageLoadingState(),
                          );
                        },
                    errorBuilder: (_, _, _) {
                      schedulePosterReady();
                      return _ImageErrorState(
                        title: strings.localized(
                          telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                          english: 'Template image unavailable',
                          hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                          tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                          kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                          malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                          marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                          gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                          bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                          punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                          odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                          assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                          konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                          nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                          meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                          mizo: 'Template thlalak a awm lo',
                          kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                          ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                        ),
                        subtitle: strings.localized(
                          telugu:
                              'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                          english: 'Please refresh or try another template.',
                          hindi:
                              'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                          tamil:
                              'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                          kannada:
                              'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                          malayalam:
                              'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                          marathi:
                              'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                          gujarati:
                              'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                          bengali:
                              'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                          punjabi:
                              'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                          odia:
                              'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                          assamese:
                              'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                          konkani:
                              'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                          nepali:
                              'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                          meitei:
                              'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                          mizo:
                              'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                          kashmiri:
                              'مہر بانی کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                          ladakhi:
                              'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
                        ),
                      );
                    },
                  );
                }
                schedulePosterReady();
                return _ImageErrorState(
                  title: strings.localized(
                    telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                    english: 'Template image unavailable',
                    hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                    tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                    kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                    malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                    marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                    gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                    bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                    punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                    odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                    assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                    konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                    nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                    meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                    mizo: 'Template thlalak a awm lo',
                    kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                    ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                  ),
                  subtitle: strings.localized(
                    telugu:
                        'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                    english: 'Please refresh or try another template.',
                    hindi: 'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                    tamil:
                        'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                    kannada:
                        'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                    malayalam:
                        'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                    marathi: 'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                    gujarati:
                        'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                    bengali:
                        'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                    punjabi:
                        'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                    odia:
                        'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                    assamese:
                        'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                    konkani:
                        'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                    nepali:
                        'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                    meitei:
                        'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                    mizo:
                        'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                    kashmiri:
                        'مہر بانی کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                    ladakhi:
                        'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
                  ),
                );
              },
            );
          }

          if (widget.imageAssetPath == null && primaryNetworkUrl.isEmpty) {
            schedulePosterReady();
            final strings = context.strings;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: math.max(width, 1)),
                child: _ImageErrorState(
                  title: strings.localized(
                    telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                    english: 'Template image unavailable',
                    hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                    tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                    kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                    malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                    marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                    gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                    bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                    punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                    odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                    assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                    konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                    nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                    meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                    mizo: 'Template thlalak a awm lo',
                    kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                    ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                  ),
                  subtitle: strings.localized(
                    telugu:
                        'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                    english: 'Please refresh or try another template.',
                    hindi: 'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                    tamil:
                        'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                    kannada:
                        'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                    malayalam:
                        'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                    marathi: 'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                    gujarati:
                        'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                    bengali:
                        'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                    punjabi:
                        'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                    odia:
                        'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                    assamese:
                        'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                    konkani:
                        'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                    nepali:
                        'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                    meitei:
                        'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                    mizo:
                        'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                    kashmiri:
                        'مہر بانی کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                    ladakhi:
                        'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
                  ),
                ),
              ),
            );
          }

          final imageWidget = widget.imageAssetPath != null
              ? Image.asset(
                  widget.imageAssetPath!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  gaplessPlayback: true,
                  filterQuality: widget.preferOriginalPosterQuality
                      ? FilterQuality.high
                      : FilterQuality.medium,
                  cacheWidth: cacheWidth,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          if (widget.onFirstFrameReady != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onFirstFrameReady!.call();
                            });
                          }
                          return child;
                        }
                        return SizedBox(
                          width: double.infinity,
                          height: posterPlaceholderHeight,
                          child: const _ImageLoadingState(),
                        );
                      },
                  errorBuilder: (_, _, _) {
                    schedulePosterReady();
                    return _ImageErrorState(
                      title: context.strings.localized(
                        telugu: 'టెంప్లేట్ చిత్రం అందుబాటులో లేదు',
                        english: 'Template image unavailable',
                        hindi: 'टेम्पलेट छवि उपलब्ध नहीं है',
                        tamil: 'டெம்ப்ளேட் படம் கிடைக்கவில்லை',
                        kannada: 'ಟೆಂಪ್ಲೇಟ್ ಚಿತ್ರ ಲಭ್ಯವಿಲ್ಲ',
                        malayalam: 'ടെംപ്ലേറ്റ് ചിത്രം ലഭ്യമല്ല',
                        marathi: 'टेम्पलेट प्रतिमा उपलब्ध नाही',
                        gujarati: 'ટેમ્પલેટ છબી ઉપલબ્ધ નથી',
                        bengali: 'টেমপ্লেট ছবি উপলব্ধ নয়',
                        punjabi: 'ਟੈਂਪਲੇਟ ਤਸਵੀਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                        odia: 'ଟେମ୍ପଲେଟ୍ ଛବି ଉପଲବ୍ଧ ନାହିଁ',
                        assamese: 'টেমপ্লেট ছবি উপলব্ধ নহয়',
                        konkani: 'टेम्पलेट चित्र उपलब्ध ना',
                        nepali: 'टेम्प्लेट तस्विर उपलब्ध छैन',
                        meitei: 'তেমপ্লেতকী ফোতো ফংদে',
                        mizo: 'Template thlalak a awm lo',
                        kashmiri: 'ٹیمپلیٹ تصویر چھُنہٕ دستیاب',
                        ladakhi: 'དཔེ་གཞིའི་པར་མི་འདུག',
                      ),
                      subtitle: context.strings.localized(
                        telugu:
                            'దయచేసి రిఫ్రెష్ చేయండి లేదా వేరొక టెంప్లేట్ ప్రయత్నించండి.',
                        english: 'Please refresh or try another template.',
                        hindi: 'कृपया रीफ़्रेश करें या अन्य टेम्पलेट आज़माएं।',
                        tamil:
                            'புதுப்பிக்கவும் அல்லது வேறு டெம்ப்ளேட்டை முயற்சிக்கவும்.',
                        kannada:
                            'ದಯವಿಟ್ಟು ರಿಫ್ರೆಶ್ ಮಾಡಿ ಅಥವಾ ಇನ್ನೊಂದು ಟೆಂಪ್ಲೇಟ್ ಪ್ರಯತ್ನಿಸಿ.',
                        malayalam:
                            'ദയവായി പുതുക്കുക അല്ലെങ്കിൽ മറ്റൊരു ടെംപ്ലേറ്റ് പരീക്ഷിക്കുക.',
                        marathi:
                            'कृपया रीफ्रेश करा किंवा इतर टेम्पलेट वापरून पहा.',
                        gujarati:
                            'કૃપા કરીને રિફ્રેશ કરો અથવા અન્ય ટેમ્પલેટ અજમાવો.',
                        bengali:
                            'অনুগ্রহ করে রিফ্রেশ করুন বা অন্য টেমপ্লেট চেষ্টা করুন।',
                        punjabi:
                            'ਕਿਰਪਾ ਕਰਕੇ ਰਿਫ੍ਰੈਸ਼ ਕਰੋ ਜਾਂ ਕੋਈ ਹੋਰ ਟੈਂਪਲੇਟ ਅਜ਼ਮਾਓ।',
                        odia:
                            'ଦୟାକରି ରିଫ୍ରେସ୍ କରନ୍ତୁ କିମ୍ବା ଅନ୍ୟ ଏକ ଟେମ୍ପଲେଟ୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
                        assamese:
                            'অনুগ্ৰহ কৰি সতেজ কৰক বা আন এটা টেমপ্লেট চেষ্টা কৰক।',
                        konkani:
                            'उपकार करून रिफ्रेश करा वा दुसरें टेम्पलेट वापरून पळयात.',
                        nepali:
                            'कृपया रिफ्रेस गर्नुहोस् वा अर्को टेम्प्लेट प्रयास गर्नुहोस्।',
                        meitei:
                            'চানবীদুনা রিফ্রেস তৌবীয়ু নত্রগা অতৈ তেমপ্লেত অমা হোৎনবীয়ু।',
                        mizo:
                            'Khawngaihin refresh rawh lehkha template dang ti chhin rawh.',
                        kashmiri:
                            'مہر بانی کٔرِتھ کٔرِو رِفریش یا دۆیم ٹیمپلیٹ کوٗشِش کٔرِو۔',
                        ladakhi:
                            'སྐུ་མཁྱེན་གསར་སྒྱུར་བྱོསའམ་དཔེ་གཞི་གཞན་ཞིག་ལ་འབད་པ་གནང་།',
                      ),
                    );
                  },
                )
              : buildNetworkPosterImage(
                  resolvedUrl: primaryNetworkUrl,
                  decodeWidth: cacheWidth,
                  notifyWhenLoaded: true,
                );

          final fixedAspectRatio = widget.fixedAspectRatio;
          if (fixedAspectRatio == null || fixedAspectRatio <= 0) {
            if (widget.imageAssetPath != null) {
              _resolveAspectRatio(
                sourceKey: 'asset:${widget.imageAssetPath!}',
                provider: AssetImage(widget.imageAssetPath!),
              );
            } else if (primaryNetworkUrl.isNotEmpty) {
              _resolveAspectRatio(
                sourceKey: 'network:$primaryNetworkUrl',
                provider: _mainProviderFor(primaryNetworkUrl, cacheWidth),
              );
            }
          }

          final effectiveAspectRatio =
              fixedAspectRatio != null && fixedAspectRatio > 0
              ? fixedAspectRatio
              : _resolvedAspectRatio;
          final wrappedImageWidget =
              effectiveAspectRatio != null && effectiveAspectRatio > 0
              ? AspectRatio(
                  aspectRatio: effectiveAspectRatio,
                  child: imageWidget,
                )
              : imageWidget;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: math.max(width, 1)),
              child: wrappedImageWidget,
            ),
          );
        },
      ),
    );
  }
}

class _ResolvedTemplatePosterImage extends StatefulWidget {
  const _ResolvedTemplatePosterImage({
    required this.imageAssetPath,
    required this.imageUrl,
    this.imageStoragePath,
    this.thumbnailStoragePath,
    this.thumbnailUrl,
    this.fixedAspectRatio,
    this.posterIdForDebug,
    this.preferOriginalPosterQuality = false,
    this.preferUltraLightDecode = false,
    this.onAspectRatioResolved,
    this.onFirstFrameReady,
  });

  final String? imageAssetPath;
  final String? imageUrl;
  final String? imageStoragePath;
  final String? thumbnailStoragePath;
  final String? thumbnailUrl;
  final double? fixedAspectRatio;
  final String? posterIdForDebug;
  final bool preferOriginalPosterQuality;
  final bool preferUltraLightDecode;
  final ValueChanged<double>? onAspectRatioResolved;
  final VoidCallback? onFirstFrameReady;

  @override
  State<_ResolvedTemplatePosterImage> createState() =>
      _ResolvedTemplatePosterImageState();
}

class _ResolvedTemplatePosterImageState
    extends State<_ResolvedTemplatePosterImage>
    with AutomaticKeepAliveClientMixin<_ResolvedTemplatePosterImage> {
  static final Map<String, String> _resolvedDownloadUrlCache =
      <String, String>{};
  static final Set<String> _failedResolveKeys = <String>{};
  static final Set<String> _loggedResolveFailures = <String>{};

  String? _resolvedImageUrl;
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _resetResolvedImageUrl();
  }

  @override
  void didUpdateWidget(covariant _ResolvedTemplatePosterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageStoragePath != widget.imageStoragePath ||
        oldWidget.thumbnailStoragePath != widget.thumbnailStoragePath ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.fixedAspectRatio != widget.fixedAspectRatio ||
        oldWidget.preferOriginalPosterQuality !=
            widget.preferOriginalPosterQuality ||
        oldWidget.preferUltraLightDecode != widget.preferUltraLightDecode ||
        oldWidget.onAspectRatioResolved != widget.onAspectRatioResolved) {
      _resetResolvedImageUrl();
    }
  }

  void _resetResolvedImageUrl() {
    _resolveGeneration++;
    final generation = _resolveGeneration;
    final path = widget.imageStoragePath?.trim() ?? '';
    final thumbPath = widget.thumbnailStoragePath?.trim() ?? '';
    final direct = widget.imageUrl?.trim() ?? '';
    final thumb = widget.thumbnailUrl?.trim() ?? '';

    if (_posterStringLooksHttpUrl(direct)) {
      _resolvedImageUrl = direct;
      return;
    }

    final candidates = List<_PosterFirebaseCandidate>.from(
      _posterFirebaseResolveCandidates(
        imageStoragePath: path,
        thumbnailStoragePath: thumbPath,
        imageUrl: direct,
        thumbnailUrl: thumb,
      ),
    );
    final cacheKey = _cacheKeyFor(candidates);

    if (candidates.isNotEmpty) {
      _resolvedImageUrl = _resolvedDownloadUrlCache[cacheKey];
      if (!_shouldRunFirebaseUiServices) {
        _resolvedImageUrl = direct.isNotEmpty
            ? direct
            : (thumb.isNotEmpty ? thumb : _resolvedImageUrl);
        return;
      }
      if (_failedResolveKeys.contains(cacheKey)) {
        _resolvedImageUrl = direct.isNotEmpty
            ? direct
            : (thumb.isNotEmpty ? thumb : _resolvedImageUrl);
        return;
      }
      unawaited(
        _resolvePosterFirebaseDownloads(
          candidates: candidates,
          generation: generation,
        ),
      );
    } else {
      _resolvedImageUrl = direct.isEmpty ? null : direct;
    }
  }

  Future<void> _resolvePosterFirebaseDownloads({
    required List<_PosterFirebaseCandidate> candidates,
    required int generation,
  }) async {
    if (!mounted || generation != _resolveGeneration || candidates.isEmpty) {
      return;
    }

    Object? lastError;
    StackTrace? lastTrace;

    for (final _PosterFirebaseCandidate cand in candidates) {
      if (!mounted || generation != _resolveGeneration) {
        return;
      }
      try {
        final ref = cand.urlMode
            ? FirebaseStorage.instance.refFromURL(cand.value)
            : FirebaseStorage.instance.ref(cand.value);
        final fresh = await ref.getDownloadURL();
        if (!mounted || generation != _resolveGeneration) {
          return;
        }
        final trimmedFresh = fresh.trim();
        if (!mounted || generation != _resolveGeneration) {
          return;
        }
        _resolvedDownloadUrlCache[_cacheKeyFor(candidates)] = trimmedFresh;
        if (_resolvedImageUrl == trimmedFresh) {
          return;
        }
        setState(() {
          _resolvedImageUrl = trimmedFresh;
        });
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastTrace = stackTrace;
      }
    }

    if (!mounted || generation != _resolveGeneration) {
      return;
    }
    if (lastError != null && lastTrace != null) {
      final cacheKey = _cacheKeyFor(candidates);
      _failedResolveKeys.add(cacheKey);
      final posterId = (widget.posterIdForDebug ?? '').trim();
      final debugIdentity = posterId.isNotEmpty ? posterId : cacheKey;
      if (_loggedResolveFailures.add(debugIdentity)) {
        final attempted = candidates
            .map((item) => item.value.trim())
            .join(', ');
        _homeDebugLogStack(
          'Poster asset resolve skipped after unauthorized/invalid access '
          'for $debugIdentity: $lastError; attempted=[$attempted]',
          lastTrace,
        );
      }
    }
  }

  String _cacheKeyFor(List<_PosterFirebaseCandidate> candidates) {
    return candidates
        .map((candidate) {
          final mode = candidate.urlMode ? 'url' : 'path';
          return '$mode:${candidate.value.trim()}';
        })
        .join('|');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final path = widget.imageStoragePath?.trim() ?? '';
    final thumbPath = widget.thumbnailStoragePath?.trim() ?? '';
    final thumb = widget.thumbnailUrl?.trim() ?? '';
    final direct = widget.imageUrl?.trim() ?? '';
    final resolved = _resolvedImageUrl?.trim() ?? '';

    final hasFirebaseCandidates = _posterFirebaseResolveCandidates(
      imageStoragePath: path,
      thumbnailStoragePath: thumbPath,
      imageUrl: direct,
      thumbnailUrl: thumb,
    ).isNotEmpty;

    final String displayUrl;
    if (resolved.isNotEmpty) {
      displayUrl = resolved;
    } else if (widget.preferOriginalPosterQuality &&
        (direct.isNotEmpty || path.isNotEmpty)) {
      displayUrl = direct;
    } else if ((hasFirebaseCandidates ||
            _posterStringLooksFirebaseResolvable(direct)) &&
        thumb.isNotEmpty) {
      displayUrl = thumb;
    } else {
      displayUrl = direct.isNotEmpty ? direct : thumb;
    }

    return _TemplatePosterImage(
      imageAssetPath: widget.imageAssetPath,
      imageUrl: displayUrl.isEmpty ? null : displayUrl,
      thumbnailUrl: widget.preferOriginalPosterQuality
          ? null
          : widget.thumbnailUrl,
      fixedAspectRatio: widget.fixedAspectRatio,
      preferOriginalPosterQuality: widget.preferOriginalPosterQuality,
      preferUltraLightDecode: widget.preferUltraLightDecode,
      onAspectRatioResolved: widget.onAspectRatioResolved,
      onFirstFrameReady: widget.onFirstFrameReady,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

