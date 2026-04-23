part of '../image_editor_screen.dart';

class EditorFullscreenOverlay extends StatefulWidget {
  const EditorFullscreenOverlay({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.onBack,
    this.onDone,
    this.backLabel = 'Back',
    this.doneLabel = 'Done',
    this.showDone = true,
    this.blurSigma = 16,
    this.scrimColor = const Color(0xCC020617),
    this.enterDuration = const Duration(milliseconds: 220),
    this.exitDuration = const Duration(milliseconds: 170),
    this.passThroughBody = false,
  });

  final String title;
  final Widget child;
  final Widget? bottom;
  final FutureOr<void> Function()? onBack;
  final FutureOr<void> Function()? onDone;
  final String backLabel;
  final String doneLabel;
  final bool showDone;
  final double blurSigma;
  final Color scrimColor;
  final Duration enterDuration;
  final Duration exitDuration;
  final bool passThroughBody;

  @override
  State<EditorFullscreenOverlay> createState() =>
      _EditorFullscreenOverlayState();
}

class _EditorFullscreenOverlayState extends State<EditorFullscreenOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.enterDuration,
    reverseDuration: widget.exitDuration,
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  bool _closing = false;

  Future<void> _closeWithCallback(FutureOr<void> Function()? callback) async {
    if (_closing) {
      return;
    }
    _closing = true;
    await _controller.reverse();
    if (!mounted) {
      return;
    }
    if (callback != null) {
      await callback();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topBar = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Row(
          children: <Widget>[
            _PressableSurface(
              onTap: () => unawaited(_closeWithCallback(widget.onBack)),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  widget.backLabel,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            widget.showDone
                ? _PressableSurface(
                    onTap: () => unawaited(_closeWithCallback(widget.onDone)),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.doneLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 58),
          ],
        ),
      ),
    );

    final content = Column(
      children: <Widget>[
        topBar,
        Expanded(
          child: IgnorePointer(
            ignoring: widget.passThroughBody,
            child: RepaintBoundary(child: widget.child),
          ),
        ),
        if (widget.bottom != null) RepaintBoundary(child: widget.bottom!),
      ],
    );

    return AnimatedBuilder(
      animation: _curve,
      child: content,
      builder: (BuildContext context, Widget? child) {
        final t = _curve.value;
        final sigma = ui.lerpDouble(0, widget.blurSigma, t) ?? widget.blurSigma;
        final scrim = widget.scrimColor.withValues(
          alpha: (widget.scrimColor.a * t).clamp(0, 1),
        );
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            IgnorePointer(
              ignoring: true,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: const SizedBox.expand(),
              ),
            ),
            IgnorePointer(ignoring: true, child: ColoredBox(color: scrim)),
            FadeTransition(
              opacity: _curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.015),
                  end: Offset.zero,
                ).animate(_curve),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
