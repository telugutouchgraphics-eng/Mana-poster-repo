// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class HomeFullscreenPopupBanner extends StatefulWidget {
  const HomeFullscreenPopupBanner({
    super.key,
    required this.banner,
    required this.imageProvider,
    required this.onClose,
    required this.onViewed,
    this.onTap,
  });

  final AppHomeBanner banner;
  final ImageProvider imageProvider;
  final VoidCallback onClose;
  final ValueChanged<String> onViewed;
  final VoidCallback? onTap;

  @override
  State<HomeFullscreenPopupBanner> createState() =>
      _HomeFullscreenPopupBannerState();
}

class _HomeFullscreenPopupBannerState extends State<HomeFullscreenPopupBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  String? _viewedBannerId;
  bool _imageFailureScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HomeFullscreenPopupBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.id != widget.banner.id) {
      _viewedBannerId = null;
      _imageFailureScheduled = false;
      _controller
        ..value = 0
        ..forward();
    }
  }

  void _recordLoadedImageView() {
    final id = widget.banner.id;
    if (_viewedBannerId == id) return;
    _viewedBannerId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.banner.id == id) widget.onViewed(id);
    });
  }

  void _skipFailedImage() {
    if (_imageFailureScheduled) return;
    _imageFailureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    final imageUrl = widget.banner.imageUrl.trim();
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.82),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1080 / 1920,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: GestureDetector(
                          onTap: widget.onTap,
                          child: Image(
                            image: widget.imageProvider,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            frameBuilder: (_, child, frame, _) {
                              if (frame != null) _recordLoadedImageView();
                              return child;
                            },
                            errorBuilder: (_, _, _) {
                              _skipFailedImage();
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: math.max(8, safePadding.top * 0.25),
                right: 12,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: context.strings.localized(
                      telugu: 'మూసివేయండి',
                      english: 'Close',
                      hindi: 'बंद करें',
                      tamil: 'மூடு',
                      kannada: 'ಮುಚ್ಚಿ',
                      malayalam: 'അടയ്ക്കുക',
                      marathi: 'बंद करा',
                      gujarati: 'બંધ કરો',
                      bengali: 'বন্ধ করুন',
                      punjabi: 'ਬੰਦ ਕਰੋ',
                      odia: 'ବନ୍ଦ କରନ୍ତୁ',
                      assamese: 'বন্ধ কৰক',
                      konkani: 'बंद करात',
                      nepali: 'बन्द गर्नुहोस्',
                      meitei: 'লোনশিনবিয়ু',
                      mizo: 'Khar rawh',
                      kashmiri: 'بند کٔریو',
                      ladakhi: 'སྒོ་རྒྱག',
                    ),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
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
