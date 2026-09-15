// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HomeInlinePromoCard extends StatefulWidget {
  const _HomeInlinePromoCard({
    required this.data,
    required this.viewerPosterProfile,
    required this.slides,
    required this.onTap,
  });

  final _HomeFeedPromoCardData data;
  final PosterProfileData viewerPosterProfile;
  final List<_HomePromoSlide> slides;
  final ValueChanged<String> onTap;

  @override
  State<_HomeInlinePromoCard> createState() => _HomeInlinePromoCardState();
}

class _HomeInlinePromoCardState extends State<_HomeInlinePromoCard> {
  late final PageController _pageController = PageController(
    viewportFraction: 1,
  );
  late final List<_HomePromoSlide> _slides = widget.slides
      .where((slide) => slide.imageUrl.trim().isNotEmpty)
      .take(6)
      .toList(growable: false);
  Timer? _autoScrollTimer;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients || _slides.length <= 1) {
        return;
      }
      final nextPage = (_pageIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openCurrentSlideTarget() {
    final ctaTarget =
        _slides.isEmpty || _pageIndex < 0 || _pageIndex >= _slides.length
        ? ''
        : _slides[_pageIndex].ctaTarget;
    widget.onTap(ctaTarget);
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = PosterProfileService.resolveImageProvider(
      widget.viewerPosterProfile,
      preferPersonalPhotoOverBusinessLogo: true,
      allowOriginalFallbackWhenCutoutUnavailable: true,
    );
    final userName = widget.viewerPosterProfile.activeName.trim().isNotEmpty
        ? widget.viewerPosterProfile.activeName.trim()
        : widget.viewerPosterProfile.resolvedName(
            language: context.currentLanguage,
          );
    final contact = widget.viewerPosterProfile.activeWhatsappNumber.trim();
    final actionStripColor = switch (widget.data.type) {
      _HomePromoCardType.featured => const Color(0xFF7C3AED),
      _HomePromoCardType.subscribe => const Color(0xFF4123C7),
      _HomePromoCardType.renewalReminder => const Color(0xFFB45309),
      _HomePromoCardType.update => const Color(0xFF0F766E),
      _HomePromoCardType.rate => const Color(0xFFD97706),
    };
    final isPlayStoreCard =
        widget.data.type == _HomePromoCardType.update ||
        widget.data.type == _HomePromoCardType.rate;
    final accentIcon = switch (widget.data.type) {
      _HomePromoCardType.featured => Icons.auto_awesome_rounded,
      _HomePromoCardType.subscribe => Icons.workspace_premium_rounded,
      _HomePromoCardType.renewalReminder => Icons.notifications_active_rounded,
      _HomePromoCardType.update || _HomePromoCardType.rate => null,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCurrentSlideTarget,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  child: SizedBox(
                    height: 118,
                    child: _slides.isEmpty
                        ? const ColoredBox(color: Color(0xFFF8FAFC))
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _slides.length,
                            onPageChanged: (index) => _pageIndex = index,
                            itemBuilder: (context, index) => Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CachedNetworkImage(
                                  imageUrl: _slides[index].imageUrl,
                                  cacheManager:
                                      PosterNetworkImageCache.instance,
                                  maxWidthDiskCache:
                                      PosterNetworkImageLimits.diskFeedMaxWidth,
                                  maxHeightDiskCache: PosterNetworkImageLimits
                                      .diskFeedMaxHeight,
                                  fit: BoxFit.cover,
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        Colors.black.withValues(alpha: 0.10),
                                        Colors.black.withValues(alpha: 0.42),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? Text(
                                userName.isEmpty ? 'U' : userName[0],
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (contact.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 5),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.call_rounded,
                                    size: 16,
                                    color: Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      contact,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(color: actionStripColor),
                  child: Row(
                    children: <Widget>[
                      if (isPlayStoreCard)
                        const _PromoPlayStoreAccentBadge()
                      else
                        _PromoAccentBadge(
                          icon: accentIcon!,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.data.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: switch (widget.data.type) {
                    _HomePromoCardType.update ||
                    _HomePromoCardType.rate => const Align(
                      alignment: Alignment.centerLeft,
                      child: _GooglePlayMiniBadge(),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _openCurrentSlideTarget,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: const Color(0xFFFFD60A),
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (widget.data.type ==
                                _HomePromoCardType.subscribe)
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 18,
                              )
                            else if (widget.data.type ==
                                _HomePromoCardType.renewalReminder)
                              const Icon(
                                Icons.notifications_active_rounded,
                                size: 18,
                              )
                            else
                              const _GooglePlayActionBadge(),
                            const SizedBox(width: 8),
                            Text(
                              widget.data.buttonLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoAccentBadge extends StatelessWidget {
  const _PromoAccentBadge({required this.icon, required this.backgroundColor});

  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

class _GooglePlayMiniBadge extends StatelessWidget {
  const _GooglePlayMiniBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            'assets/branding/google_logo.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 7),
          const Text(
            'Google Play',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoPlayStoreAccentBadge extends StatelessWidget {
  const _PromoPlayStoreAccentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const _GooglePlayActionBadge(),
    );
  }
}

class _GooglePlayActionBadge extends StatelessWidget {
  const _GooglePlayActionBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/branding/google_logo.png',
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 5),
        const Text(
          'Play',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BannerSlideData {
  const _BannerSlideData({required this.id, required this.imageUrl});

  final String id;
  final String imageUrl;
}

