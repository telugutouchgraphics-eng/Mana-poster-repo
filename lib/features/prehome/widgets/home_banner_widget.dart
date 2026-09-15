// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HomeFullscreenPopupBanner extends StatefulWidget {
  const _HomeFullscreenPopupBanner({
    required this.banner,
    required this.onClose,
    required this.onViewed,
  });

  final AppHomeBanner banner;
  final VoidCallback onClose;
  final ValueChanged<String> onViewed;

  @override
  State<_HomeFullscreenPopupBanner> createState() =>
      _HomeFullscreenPopupBannerState();
}

class _HomeFullscreenPopupBannerState extends State<_HomeFullscreenPopupBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    widget.onViewed(widget.banner.id);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _HomeFullscreenPopupBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.id != widget.banner.id) {
      widget.onViewed(widget.banner.id);
      _controller
        ..value = 0
        ..forward();
    }
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
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheManager: PosterNetworkImageCache.instance,
                          maxWidthDiskCache:
                              PosterNetworkImageLimits.diskFeedMaxWidth,
                          maxHeightDiskCache:
                              PosterNetworkImageLimits.diskFeedMaxHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          placeholder: (_, _) => const _ImageLoadingState(),
                          errorWidget: (_, _, _) => const _ImageErrorState(
                            compact: true,
                            title: 'Banner unavailable',
                            subtitle: 'Please try again shortly.',
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
                    tooltip: 'Close',
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

