// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HomeHeroBanner extends StatefulWidget {
  const _HomeHeroBanner({required this.banners, required this.onBannerViewed});

  final List<AppHomeBanner> banners;
  final ValueChanged<String> onBannerViewed;

  @override
  State<_HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<_HomeHeroBanner> {
  static const double _bannerAspectRatio = 1080 / 190;
  late final PageController _pageController = PageController();
  Timer? _autoSwipeTimer;
  int _currentPage = 0;

  List<_BannerSlideData> get _slides => widget.banners
      .map(
        (banner) => _BannerSlideData(id: banner.id, imageUrl: banner.imageUrl),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _recordCurrentSlideView();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients || _slides.length <= 1) {
        return;
      }
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _HomeHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length ||
        !_sameBannerIds(widget.banners, oldWidget.banners)) {
      if (_currentPage >= widget.banners.length) {
        _currentPage = 0;
      }
      _recordCurrentSlideView();
    }
  }

  bool _sameBannerIds(List<AppHomeBanner> left, List<AppHomeBanner> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index].id != right[index].id) {
        return false;
      }
    }
    return true;
  }

  void _recordCurrentSlideView() {
    final slides = _slides;
    if (slides.isEmpty) {
      return;
    }
    final index = _currentPage.clamp(0, slides.length - 1).toInt();
    widget.onBannerViewed(slides[index].id);
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: _bannerAspectRatio,
      child: SizedBox(
        width: double.infinity,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _slides.length,
          onPageChanged: (index) {
            _currentPage = index;
            _recordCurrentSlideView();
          },
          itemBuilder: (context, index) => LayoutBuilder(
            builder: (context, constraints) {
              final memWidth = constraints.maxWidth.isFinite
                  ? (constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(320, 720)
                  : 720;
              return CachedNetworkImage(
                imageUrl: _slides[index].imageUrl,
                cacheManager: PosterNetworkImageCache.instance,
                maxWidthDiskCache: PosterNetworkImageLimits.diskFeedMaxWidth,
                maxHeightDiskCache: PosterNetworkImageLimits.diskFeedMaxHeight,
                fit: BoxFit.cover,
                memCacheWidth: memWidth,
                filterQuality: FilterQuality.low,
                placeholder: (_, _) => const _ImageLoadingState(),
                errorWidget: (_, _, _) => _ImageErrorState(
                  compact: true,
                  title: context.strings.localized(
                    telugu: 'బ్యానర్ అందుబాటులో లేదు',
                    english: 'Banner unavailable',
                    hindi: 'बैनर उपलब्ध नहीं है',
                    tamil: 'பேனர் கிடைக்கவில்லை',
                    kannada: 'ಬ್ಯಾನರ್ ಲಭ್ಯವಿಲ್ಲ',
                    malayalam: 'ബാനർ ലഭ്യമല്ല',
                    marathi: 'बॅनर उपलब्ध नाही',
                    gujarati: 'બૅનર ઉપલબ્ધ નથી',
                    bengali: 'ব্যানার উপলব্ধ নয়',
                    punjabi: 'ਬੈਨਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
                    odia: 'ବ୍ୟାନର୍ ଉପଲବ୍ଧ ନାହିଁ',
                    assamese: 'বেনাৰ উপলব্ধ নহয়',
                    konkani: 'बॅनर उपलब्ध ना',
                    nepali: 'ब्यानर उपलब्ध छैन',
                    meitei: 'বেনর ফংদে',
                    mizo: 'Banner a awm lo',
                    kashmiri: 'بینر چھُنہٕ دستیاب',
                    ladakhi: 'བྱང་བུ་མི་འདུག',
                  ),
                  subtitle: context.strings.localized(
                    telugu: 'దయచేసి కాసేపటి తర్వాత మళ్లీ ప్రయత్నించండి.',
                    english: 'Please try again shortly.',
                    hindi: 'कृपया कुछ देर बाद पुनः प्रयास करें।',
                    tamil: 'சிறிது நேரத்தில் மீண்டும் முயற்சிக்கவும்.',
                    kannada: 'ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                    malayalam: 'ദയവായി കുറച്ച് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
                    marathi: 'कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.',
                    gujarati: 'કૃપા કરીને થોડા સમય પછી ફરી પ્રયાસ કરો.',
                    bengali: 'অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।',
                    punjabi: 'ਕਿਰਪਾ ਕਰਕੇ ਥੋੜ੍ਹੀ ਦੇਰ ਬਾਅਦ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                    odia: 'ଦୟାକରି କିଛି ସମୟ ପରେ ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
                    assamese: 'অনুগ্ৰহ কৰি অলপ পিছত পুনৰ চেষ্টা কৰক।',
                    konkani: 'उपकार करून थोड्या वेळान परत यत्न करा.',
                    nepali: 'कृपया केही समयपछि पुन: प्रयास गर्नुहोस्।',
                    meitei: 'চানবীদুना মতম খরা লৈরগা অমুক হন্না হোৎনবীয়ু।',
                    mizo: 'Khawngaihin nakin deuhvah ti nawn leh rawh.',
                    kashmiri:
                        'مہر بانی کٔرِتھ کیٚنٛہہ کال پتہٕ دُوبارٕ کوٗشِش کٔرِو۔',
                    ladakhi:
                        'སྐུ་མཁྱེན་དུས་ཚོད་ཐུང་ངུ་ཞིག་གི་རྗེས་སུ་ཡང་བསྐྱར་འབད་པ་གནང་།',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeBannerAdFallback extends StatefulWidget {
  const _HomeBannerAdFallback({super.key});

  @override
  State<_HomeBannerAdFallback> createState() => _HomeBannerAdFallbackState();
}

class _HomeBannerAdFallbackState extends State<_HomeBannerAdFallback>
    with AutomaticKeepAliveClientMixin {
  static BannerAd? _cachedBannerAd;
  static AdSize? _cachedAdSize;
  static bool _cachedIsLoaded = false;
  static bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachedBannerAd != null && _cachedIsLoaded) {
      return;
    }
    if (_isLoading) {
      return;
    }
    unawaited(_loadBanner());
  }

  void _scheduleRetry() {
    if (!mounted || _cachedIsLoaded) {
      return;
    }
    Future<void>.delayed(const Duration(seconds: 20), () {
      if (!mounted || _cachedIsLoaded || _isLoading) {
        return;
      }
      unawaited(_loadBanner());
    });
  }

  Future<void> _loadBanner() async {
    if (kIsWeb || !Platform.isAndroid || !AppPublicInfo.hasHomeBannerAdUnitId) {
      return;
    }
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    try {
      await PostSplashStartupGate.whenReady.timeout(
        const Duration(seconds: 20),
      );
    } catch (_) {
      _isLoading = false;
      return;
    }
    if (!mounted) {
      _isLoading = false;
      return;
    }
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    try {
      if (!await AdMobConsentService.instance.canRequestAds()) {
        await AdMobConsentService.instance.prepareForAds();
      }
    } catch (_) {}
    try {
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (!mounted) {
      _isLoading = false;
      return;
    }
    final adaptiveSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      availableWidth.truncate(),
    );
    if (!mounted || adaptiveSize == null) {
      _isLoading = false;
      _scheduleRetry();
      return;
    }
    final banner = BannerAd(
      adUnitId: AppPublicInfo.adMobHomeBannerAdUnitId,
      request: const AdRequest(),
      size: adaptiveSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('ManaPosterAdMob: home banner ad loaded successfully');
          _cachedBannerAd = ad as BannerAd;
          _cachedAdSize = adaptiveSize;
          _cachedIsLoaded = true;
          _isLoading = false;
          if (!mounted) {
            return;
          }
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('ManaPosterAdMob: home banner ad failed: $error');
          ad.dispose();
          _isLoading = false;
          if (_cachedBannerAd == null) {
            _cachedIsLoaded = false;
            if (mounted) {
              setState(() {});
            }
          }
          _scheduleRetry();
        },
      ),
    );
    try {
      debugPrint(
        'ManaPosterAdMob: requesting home banner ad load for unit: ${AppPublicInfo.adMobHomeBannerAdUnitId}',
      );
      await banner.load();
    } catch (error) {
      banner.dispose();
      _isLoading = false;
      debugPrint('ManaPosterAdMob: home banner ad load exception: $error');
      _scheduleRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _cachedBannerAd;
    final size = _cachedAdSize;
    if (!_cachedIsLoaded || ad == null || size == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          width: size.width.toDouble(),
          height: size.height.toDouble(),
          child: AdWidget(key: ValueKey(ad.hashCode), ad: ad),
        ),
      ),
    );
  }
}
