// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _PosterFullScreenPreview extends StatefulWidget {
  const _PosterFullScreenPreview({
    required this.title,
    required this.heroTag,
    required this.child,
    this.aspectRatio,
  });

  final String title;
  final String heroTag;
  final Widget child;
  final double? aspectRatio;

  @override
  State<_PosterFullScreenPreview> createState() =>
      _PosterFullScreenPreviewState();
}

class _PosterFullScreenPreviewState extends State<_PosterFullScreenPreview> {
  final TransformationController _transformationController =
      TransformationController();
  final Set<int> _activePointerIds = <int>{};
  bool _isZoomed = false;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final nextZoomed = scale > 1.02;
    if (nextZoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = nextZoomed);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    _updatePinchState();
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointerIds.remove(event.pointer);
    _updatePinchState();
  }

  void _updatePinchState() {
    final nextPinching = _activePointerIds.length >= 2;
    if (nextPinching != _isPinching && mounted) {
      setState(() => _isPinching = nextPinching);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAspectRatio = widget.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Hero(
                tag: widget.heroTag,
                transitionOnUserGestures: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final maxHeight = constraints.maxHeight;
                      final targetWidth = maxWidth.isFinite
                          ? maxWidth
                          : MediaQuery.sizeOf(context).width;
                      final targetHeight =
                          resolvedAspectRatio != null && resolvedAspectRatio > 0
                          ? targetWidth / resolvedAspectRatio
                          : null;
                      final preview = targetHeight == null
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: targetWidth,
                              ),
                              child: widget.child,
                            )
                          : SizedBox(
                              width: targetWidth,
                              height: targetHeight,
                              child: widget.child,
                            );
                      final blockScroll = _isZoomed || _isPinching;
                      return Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: _handlePointerDown,
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerUp,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1,
                          maxScale: 4,
                          panEnabled: blockScroll,
                          scaleEnabled: true,
                          clipBehavior: Clip.none,
                          child: SingleChildScrollView(
                            physics: blockScroll
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: maxHeight),
                              child: Center(child: preview),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: <Widget>[
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.48),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterFullScreenGallery extends StatefulWidget {
  const _PosterFullScreenGallery({
    required this.initialIndex,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
  });

  final int initialIndex;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;

  @override
  State<_PosterFullScreenGallery> createState() =>
      _PosterFullScreenGalleryState();
}

class _PosterFullScreenGalleryState extends State<_PosterFullScreenGallery> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex.clamp(0, widget.itemCount - 1),
  );
  late int _pageIndex = widget.initialIndex.clamp(0, widget.itemCount - 1);
  bool _isPageZoomed = false;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(ScreenSecurityService.unprotectScreen());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              physics: _isPageZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: widget.itemCount,
              onPageChanged: (index) {
                widget.onPageChanged?.call(index);
                _isPageZoomed = false;
                setState(() => _pageIndex = index);
              },
              itemBuilder: (context, index) {
                return _ZoomableFullScreenGalleryItem(
                  onZoomChanged: (zoomed) {
                    if (zoomed != _isPageZoomed && mounted) {
                      setState(() => _isPageZoomed = zoomed);
                    }
                  },
                  child: widget.itemBuilder(context, index),
                );
              },
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: <Widget>[
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.48),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        '${_pageIndex + 1}/${widget.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableFullScreenGalleryItem extends StatefulWidget {
  const _ZoomableFullScreenGalleryItem({
    required this.child,
    required this.onZoomChanged,
  });

  final Widget child;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableFullScreenGalleryItem> createState() =>
      _ZoomableFullScreenGalleryItemState();
}

class _ZoomableFullScreenGalleryItemState
    extends State<_ZoomableFullScreenGalleryItem> {
  final TransformationController _transformationController =
      TransformationController();
  final Set<int> _activePointerIds = <int>{};
  bool _isZoomed = false;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    widget.onZoomChanged(false);
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final nextZoomed = scale > 1.02;
    if (nextZoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = nextZoomed);
      widget.onZoomChanged(nextZoomed || _isPinching);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    _updatePinchState();
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointerIds.remove(event.pointer);
    _updatePinchState();
  }

  void _updatePinchState() {
    final nextPinching = _activePointerIds.length >= 2;
    if (nextPinching != _isPinching && mounted) {
      setState(() => _isPinching = nextPinching);
      widget.onZoomChanged(nextPinching || _isZoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockPageScroll = _isZoomed || _isPinching;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1,
        maxScale: 4,
        panEnabled: blockPageScroll,
        scaleEnabled: true,
        clipBehavior: Clip.none,
        child: Center(child: widget.child),
      ),
    );
  }
}

