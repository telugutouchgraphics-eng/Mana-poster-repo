part of '../image_editor_screen.dart';

const int _designImportMaxCanvasPixels = 64 * 1000 * 1000;
const int _designImportMaxPsdLayerWorkPixels = 512 * 1000 * 1000;
const int _editorPhotoImportMaxPixels = 18 * 1000 * 1000;
const int _editorPhotoImportMaxEncodedBytes = 14 * 1024 * 1024;
const int _editorPhotoImportMaxSide = 4096;

final LinkedHashMap<int, ui.ImageFilter> _expandedMaskFilterCache =
    LinkedHashMap<int, ui.ImageFilter>();

ui.ImageFilter? _expandedMaskFilter({
  required double dilate,
  required double blur,
}) {
  final safeDilate = dilate.clamp(0.0, 48.0).toDouble();
  final safeBlur = blur.clamp(0.0, 96.0).toDouble();
  if (safeDilate <= 0.001 && safeBlur <= 0.001) {
    return null;
  }
  final dilateKey = (safeDilate * 2).round();
  final blurKey = (safeBlur * 2).round();
  final key = Object.hash(dilateKey, blurKey);
  final cached = _expandedMaskFilterCache.remove(key);
  if (cached != null) {
    _expandedMaskFilterCache[key] = cached;
    return cached;
  }
  ui.ImageFilter filter;
  if (safeDilate > 0.001 && safeBlur > 0.001) {
    filter = ui.ImageFilter.compose(
      inner: ui.ImageFilter.dilate(radiusX: safeDilate, radiusY: safeDilate),
      outer: ui.ImageFilter.blur(sigmaX: safeBlur, sigmaY: safeBlur),
    );
  } else if (safeDilate > 0.001) {
    filter = ui.ImageFilter.dilate(radiusX: safeDilate, radiusY: safeDilate);
  } else {
    filter = ui.ImageFilter.blur(sigmaX: safeBlur, sigmaY: safeBlur);
  }
  _expandedMaskFilterCache[key] = filter;
  while (_expandedMaskFilterCache.length > 64) {
    _expandedMaskFilterCache.remove(_expandedMaskFilterCache.keys.first);
  }
  return filter;
}

class _EditorClippingStack extends MultiChildRenderObjectWidget {
  const _EditorClippingStack({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderEditorClippingStack(
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderEditorClippingStack renderObject,
  ) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class _EditorClippingStackParentData extends StackParentData {
  int? maskBaseChildIndex;
}

class _EditorClippingLayer
    extends ParentDataWidget<_EditorClippingStackParentData> {
  const _EditorClippingLayer({
    required this.maskBaseChildIndex,
    required super.child,
  });

  final int? maskBaseChildIndex;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData =
        renderObject.parentData! as _EditorClippingStackParentData;
    if (parentData.maskBaseChildIndex == maskBaseChildIndex) {
      return;
    }
    parentData.maskBaseChildIndex = maskBaseChildIndex;
    final parent = renderObject.parent;
    if (parent is RenderObject) {
      parent.markNeedsPaint();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _EditorClippingStack;
}

class _RenderEditorClippingStack extends RenderStack {
  _RenderEditorClippingStack({required TextDirection textDirection})
    : super(
        alignment: AlignmentDirectional.topStart,
        textDirection: textDirection,
        fit: StackFit.loose,
        clipBehavior: Clip.hardEdge,
      );

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EditorClippingStackParentData) {
      child.parentData = _EditorClippingStackParentData();
    }
  }

  @override
  void paintStack(PaintingContext context, Offset offset) {
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      children.add(child);
      final parentData = child.parentData! as _EditorClippingStackParentData;
      child = parentData.nextSibling;
    }

    final bounds = offset & size;
    for (final current in children) {
      final parentData = current.parentData! as _EditorClippingStackParentData;
      final childOffset = offset + parentData.offset;
      final maskIndex = parentData.maskBaseChildIndex;
      if (maskIndex == null ||
          maskIndex < 0 ||
          maskIndex >= children.length ||
          identical(children[maskIndex], current)) {
        context.paintChild(current, childOffset);
        continue;
      }

      final maskChild = children[maskIndex];
      final maskParentData =
          maskChild.parentData! as _EditorClippingStackParentData;
      context.canvas.saveLayer(bounds, Paint());
      context.paintChild(current, childOffset);
      context.canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
      context.paintChild(maskChild, offset + maskParentData.offset);
      context.canvas.restore();
      context.canvas.restore();
    }
  }
}

@visibleForTesting
Widget buildEditorLayerStylePixelTestSurface({
  required Key repaintBoundaryKey,
  double strokeWidth = 0,
  double strokeOpacity = 1,
  double shadowOpacity = 0,
  double shadowBlur = 0,
  double shadowSpread = 0,
  Offset shadowOffset = Offset.zero,
  double innerShadowOpacity = 0,
  double innerShadowBlur = 0,
  double innerShadowChoke = 0,
  double innerShadowDistance = 0,
  double outerGlowOpacity = 0,
  double outerGlowSize = 0,
  double outerGlowSpread = 0,
  double overlayOpacity = 0,
  Color overlayColor = Colors.black,
  bool gradientOverlayEnabled = false,
  double gradientOverlayOpacity = 0,
  Color childColor = Colors.white,
}) {
  return RepaintBoundary(
    key: repaintBoundaryKey,
    child: SizedBox.square(
      dimension: 96,
      child: Center(
        child: _EditorUniversalLayerStyle(
          overlayColor: overlayColor,
          overlayOpacity: overlayOpacity,
          strokeColor: Colors.red,
          strokeWidth: strokeWidth,
          shadowColor: Colors.black,
          shadowOpacity: shadowOpacity,
          shadowBlur: shadowBlur,
          shadowSpread: shadowSpread,
          shadowOffset: shadowOffset,
          strokeOpacity: strokeOpacity,
          innerShadowColor: Colors.black,
          innerShadowOpacity: innerShadowOpacity,
          innerShadowBlur: innerShadowBlur,
          innerShadowChoke: innerShadowChoke,
          innerShadowDistance: innerShadowDistance,
          innerShadowAngle: 120,
          gradientOverlayEnabled: gradientOverlayEnabled,
          gradientOverlayColors: const <Color>[Colors.white, Colors.black],
          gradientOverlayOpacity: gradientOverlayOpacity,
          gradientOverlayAngle: 0,
          gradientOverlayScale: 100,
          gradientOverlayReversed: false,
          outerGlowColor: Colors.white,
          outerGlowOpacity: outerGlowOpacity,
          outerGlowSize: outerGlowSize,
          outerGlowSpread: outerGlowSpread,
          child: SizedBox.square(
            dimension: 40,
            child: ColoredBox(color: childColor),
          ),
        ),
      ),
    ),
  );
}

class _EditorUniversalLayerStyle extends SingleChildRenderObjectWidget {
  const _EditorUniversalLayerStyle({
    super.key,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.strokeColor,
    required this.strokeWidth,
    required this.strokeOpacity,
    required this.shadowColor,
    required this.shadowOpacity,
    required this.shadowBlur,
    required this.shadowSpread,
    required this.shadowOffset,
    required this.innerShadowColor,
    required this.innerShadowOpacity,
    required this.innerShadowBlur,
    required this.innerShadowChoke,
    required this.innerShadowDistance,
    required this.innerShadowAngle,
    required this.gradientOverlayEnabled,
    required this.gradientOverlayColors,
    required this.gradientOverlayOpacity,
    required this.gradientOverlayAngle,
    required this.gradientOverlayScale,
    required this.gradientOverlayReversed,
    required this.outerGlowColor,
    required this.outerGlowOpacity,
    required this.outerGlowSize,
    required this.outerGlowSpread,
    required super.child,
  });

  final Color overlayColor;
  final double overlayOpacity;
  final Color strokeColor;
  final double strokeWidth;
  final double strokeOpacity;
  final Color shadowColor;
  final double shadowOpacity;
  final double shadowBlur;
  final double shadowSpread;
  final Offset shadowOffset;
  final Color innerShadowColor;
  final double innerShadowOpacity;
  final double innerShadowBlur;
  final double innerShadowChoke;
  final double innerShadowDistance;
  final double innerShadowAngle;
  final bool gradientOverlayEnabled;
  final List<Color> gradientOverlayColors;
  final double gradientOverlayOpacity;
  final double gradientOverlayAngle;
  final double gradientOverlayScale;
  final bool gradientOverlayReversed;
  final Color outerGlowColor;
  final double outerGlowOpacity;
  final double outerGlowSize;
  final double outerGlowSpread;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderEditorUniversalLayerStyle(
      overlayColor: overlayColor,
      overlayOpacity: overlayOpacity,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      strokeOpacity: strokeOpacity,
      shadowColor: shadowColor,
      shadowOpacity: shadowOpacity,
      shadowBlur: shadowBlur,
      shadowSpread: shadowSpread,
      shadowOffset: shadowOffset,
      innerShadowColor: innerShadowColor,
      innerShadowOpacity: innerShadowOpacity,
      innerShadowBlur: innerShadowBlur,
      innerShadowChoke: innerShadowChoke,
      innerShadowDistance: innerShadowDistance,
      innerShadowAngle: innerShadowAngle,
      gradientOverlayEnabled: gradientOverlayEnabled,
      gradientOverlayColors: gradientOverlayColors,
      gradientOverlayOpacity: gradientOverlayOpacity,
      gradientOverlayAngle: gradientOverlayAngle,
      gradientOverlayScale: gradientOverlayScale,
      gradientOverlayReversed: gradientOverlayReversed,
      outerGlowColor: outerGlowColor,
      outerGlowOpacity: outerGlowOpacity,
      outerGlowSize: outerGlowSize,
      outerGlowSpread: outerGlowSpread,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderEditorUniversalLayerStyle renderObject,
  ) {
    renderObject
      ..overlayColor = overlayColor
      ..overlayOpacity = overlayOpacity
      ..strokeColor = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeOpacity = strokeOpacity
      ..shadowColor = shadowColor
      ..shadowOpacity = shadowOpacity
      ..shadowBlur = shadowBlur
      ..shadowSpread = shadowSpread
      ..shadowOffset = shadowOffset
      ..innerShadowColor = innerShadowColor
      ..innerShadowOpacity = innerShadowOpacity
      ..innerShadowBlur = innerShadowBlur
      ..innerShadowChoke = innerShadowChoke
      ..innerShadowDistance = innerShadowDistance
      ..innerShadowAngle = innerShadowAngle
      ..gradientOverlayEnabled = gradientOverlayEnabled
      ..gradientOverlayColors = gradientOverlayColors
      ..gradientOverlayOpacity = gradientOverlayOpacity
      ..gradientOverlayAngle = gradientOverlayAngle
      ..gradientOverlayScale = gradientOverlayScale
      ..gradientOverlayReversed = gradientOverlayReversed
      ..outerGlowColor = outerGlowColor
      ..outerGlowOpacity = outerGlowOpacity
      ..outerGlowSize = outerGlowSize
      ..outerGlowSpread = outerGlowSpread;
  }
}

class _RenderEditorUniversalLayerStyle extends RenderProxyBox {
  _RenderEditorUniversalLayerStyle({
    required Color overlayColor,
    required double overlayOpacity,
    required Color strokeColor,
    required double strokeWidth,
    required double strokeOpacity,
    required Color shadowColor,
    required double shadowOpacity,
    required double shadowBlur,
    required double shadowSpread,
    required Offset shadowOffset,
    required Color innerShadowColor,
    required double innerShadowOpacity,
    required double innerShadowBlur,
    required double innerShadowChoke,
    required double innerShadowDistance,
    required double innerShadowAngle,
    required bool gradientOverlayEnabled,
    required List<Color> gradientOverlayColors,
    required double gradientOverlayOpacity,
    required double gradientOverlayAngle,
    required double gradientOverlayScale,
    required bool gradientOverlayReversed,
    required Color outerGlowColor,
    required double outerGlowOpacity,
    required double outerGlowSize,
    required double outerGlowSpread,
  }) : _overlayColor = overlayColor,
       _overlayOpacity = overlayOpacity,
       _strokeColor = strokeColor,
       _strokeWidth = strokeWidth,
       _strokeOpacity = strokeOpacity,
       _shadowColor = shadowColor,
       _shadowOpacity = shadowOpacity,
       _shadowBlur = shadowBlur,
       _shadowSpread = shadowSpread,
       _shadowOffset = shadowOffset,
       _innerShadowColor = innerShadowColor,
       _innerShadowOpacity = innerShadowOpacity,
       _innerShadowBlur = innerShadowBlur,
       _innerShadowChoke = innerShadowChoke,
       _innerShadowDistance = innerShadowDistance,
       _innerShadowAngle = innerShadowAngle,
       _gradientOverlayEnabled = gradientOverlayEnabled,
       _gradientOverlayColors = gradientOverlayColors,
       _gradientOverlayOpacity = gradientOverlayOpacity,
       _gradientOverlayAngle = gradientOverlayAngle,
       _gradientOverlayScale = gradientOverlayScale,
       _gradientOverlayReversed = gradientOverlayReversed,
       _outerGlowColor = outerGlowColor,
       _outerGlowOpacity = outerGlowOpacity,
       _outerGlowSize = outerGlowSize,
       _outerGlowSpread = outerGlowSpread;

  Color _overlayColor;
  double _overlayOpacity;
  Color _strokeColor;
  double _strokeWidth;
  double _strokeOpacity;
  Color _shadowColor;
  double _shadowOpacity;
  double _shadowBlur;
  double _shadowSpread;
  Offset _shadowOffset;
  Color _innerShadowColor;
  double _innerShadowOpacity;
  double _innerShadowBlur;
  double _innerShadowChoke;
  double _innerShadowDistance;
  double _innerShadowAngle;
  bool _gradientOverlayEnabled;
  List<Color> _gradientOverlayColors;
  double _gradientOverlayOpacity;
  double _gradientOverlayAngle;
  double _gradientOverlayScale;
  bool _gradientOverlayReversed;
  Color _outerGlowColor;
  double _outerGlowOpacity;
  double _outerGlowSize;
  double _outerGlowSpread;

  set overlayColor(Color value) {
    if (_overlayColor == value) return;
    _overlayColor = value;
    markNeedsPaint();
  }

  set overlayOpacity(double value) {
    if (_overlayOpacity == value) return;
    _overlayOpacity = value;
    markNeedsPaint();
  }

  set strokeColor(Color value) {
    if (_strokeColor == value) return;
    _strokeColor = value;
    markNeedsPaint();
  }

  set strokeWidth(double value) {
    if (_strokeWidth == value) return;
    _strokeWidth = value;
    markNeedsPaint();
  }

  set strokeOpacity(double value) {
    if (_strokeOpacity == value) return;
    _strokeOpacity = value;
    markNeedsPaint();
  }

  set shadowColor(Color value) {
    if (_shadowColor == value) return;
    _shadowColor = value;
    markNeedsPaint();
  }

  set shadowOpacity(double value) {
    if (_shadowOpacity == value) return;
    _shadowOpacity = value;
    markNeedsPaint();
  }

  set shadowBlur(double value) {
    if (_shadowBlur == value) return;
    _shadowBlur = value;
    markNeedsPaint();
  }

  set shadowSpread(double value) {
    if (_shadowSpread == value) return;
    _shadowSpread = value;
    markNeedsPaint();
  }

  set shadowOffset(Offset value) {
    if (_shadowOffset == value) return;
    _shadowOffset = value;
    markNeedsPaint();
  }

  set innerShadowColor(Color value) {
    if (_innerShadowColor == value) return;
    _innerShadowColor = value;
    markNeedsPaint();
  }

  set innerShadowOpacity(double value) {
    if (_innerShadowOpacity == value) return;
    _innerShadowOpacity = value;
    markNeedsPaint();
  }

  set innerShadowBlur(double value) {
    if (_innerShadowBlur == value) return;
    _innerShadowBlur = value;
    markNeedsPaint();
  }

  set innerShadowChoke(double value) {
    if (_innerShadowChoke == value) return;
    _innerShadowChoke = value;
    markNeedsPaint();
  }

  set innerShadowDistance(double value) {
    if (_innerShadowDistance == value) return;
    _innerShadowDistance = value;
    markNeedsPaint();
  }

  set innerShadowAngle(double value) {
    if (_innerShadowAngle == value) return;
    _innerShadowAngle = value;
    markNeedsPaint();
  }

  set gradientOverlayEnabled(bool value) {
    if (_gradientOverlayEnabled == value) return;
    _gradientOverlayEnabled = value;
    markNeedsPaint();
  }

  set gradientOverlayColors(List<Color> value) {
    if (listEquals(_gradientOverlayColors, value)) return;
    _gradientOverlayColors = value;
    markNeedsPaint();
  }

  set gradientOverlayOpacity(double value) {
    if (_gradientOverlayOpacity == value) return;
    _gradientOverlayOpacity = value;
    markNeedsPaint();
  }

  set gradientOverlayAngle(double value) {
    if (_gradientOverlayAngle == value) return;
    _gradientOverlayAngle = value;
    markNeedsPaint();
  }

  set gradientOverlayScale(double value) {
    if (_gradientOverlayScale == value) return;
    _gradientOverlayScale = value;
    markNeedsPaint();
  }

  set gradientOverlayReversed(bool value) {
    if (_gradientOverlayReversed == value) return;
    _gradientOverlayReversed = value;
    markNeedsPaint();
  }

  set outerGlowColor(Color value) {
    if (_outerGlowColor == value) return;
    _outerGlowColor = value;
    markNeedsPaint();
  }

  set outerGlowOpacity(double value) {
    if (_outerGlowOpacity == value) return;
    _outerGlowOpacity = value;
    markNeedsPaint();
  }

  set outerGlowSize(double value) {
    if (_outerGlowSize == value) return;
    _outerGlowSize = value;
    markNeedsPaint();
  }

  set outerGlowSpread(double value) {
    if (_outerGlowSpread == value) return;
    _outerGlowSpread = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }
    final effectiveOuterGlowSize = _outerGlowSize.clamp(0.0, 64.0).toDouble();
    final effectiveOuterGlowSpread = _outerGlowSpread
        .clamp(0.0, 32.0)
        .toDouble();
    final effectiveShadowBlur = _shadowBlur.clamp(0.0, 56.0).toDouble();
    final effectiveShadowSpread = _shadowSpread.clamp(0.0, 32.0).toDouble();
    final effectiveStrokeWidth = _strokeWidth.clamp(0.0, 36.0).toDouble();
    final effectiveInnerShadowBlur = _innerShadowBlur
        .clamp(0.0, 56.0)
        .toDouble();
    final effectiveInnerShadowDistance = _innerShadowDistance
        .clamp(0.0, 80.0)
        .toDouble();
    final visualPadding =
        math.max(
          math.max(
            effectiveStrokeWidth,
            effectiveOuterGlowSize + effectiveOuterGlowSpread,
          ),
          math.max(
            effectiveShadowBlur +
                effectiveShadowSpread +
                _shadowOffset.distance,
            effectiveInnerShadowBlur + effectiveInnerShadowDistance,
          ),
        ) +
        12;
    final bounds = (offset & size).inflate(visualPadding);

    void paintChildMask({
      required Offset at,
      required Color color,
      double blur = 0,
      ui.ImageFilter? imageFilter,
      BlendMode blendMode = BlendMode.srcOver,
    }) {
      final paint = Paint()..blendMode = blendMode;
      if (imageFilter != null) {
        paint.imageFilter = imageFilter;
      } else if (blur > 0.001) {
        paint.imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);
      }
      context.canvas.saveLayer(bounds, paint);
      context.paintChild(child!, at);
      context.canvas.drawRect(
        bounds,
        Paint()
          ..color = color
          ..blendMode = BlendMode.srcIn,
      );
      context.canvas.restore();
    }

    final outerGlowOpacity = _outerGlowOpacity.clamp(0.0, 1.0).toDouble();
    if (outerGlowOpacity > 0.001 && _outerGlowSize > 0.001) {
      final glowSize = _outerGlowSize.clamp(0.0, 64.0).toDouble();
      final spread = _outerGlowSpread.clamp(0.0, 32.0).toDouble();
      final glowDilate = math.min(18.0, spread * 0.22);
      final glowBlur = math.max(0.1, (glowSize * 0.42) + (spread * 0.18));
      paintChildMask(
        at: offset,
        color: _outerGlowColor.withValues(alpha: outerGlowOpacity),
        imageFilter: _expandedMaskFilter(dilate: glowDilate, blur: glowBlur),
      );
    }

    final shadowOpacity = _shadowOpacity.clamp(0.0, 1.0).toDouble();
    if (shadowOpacity > 0.001) {
      final spread = _shadowSpread.clamp(0.0, 32.0).toDouble();
      final shadowDilate = math.min(32.0, spread);
      final shadowBlur = math.max(0.0, _shadowBlur.clamp(0.0, 56.0) / 2.0);
      paintChildMask(
        at: offset + _shadowOffset,
        color: _shadowColor.withValues(alpha: shadowOpacity),
        imageFilter: _expandedMaskFilter(
          dilate: shadowDilate,
          blur: shadowBlur,
        ),
      );
    }

    final strokeOpacity = _strokeOpacity.clamp(0.0, 1.0).toDouble();
    if (strokeOpacity > 0.001 && effectiveStrokeWidth > 0.001) {
      paintChildMask(
        at: offset,
        color: _strokeColor.withValues(alpha: strokeOpacity),
        imageFilter: _expandedMaskFilter(
          dilate: math.max(0.75, effectiveStrokeWidth / 2.0),
          blur: effectiveStrokeWidth > 2.5 ? 0.45 : 0.15,
        ),
      );
    }

    context.paintChild(child!, offset);

    final innerShadowOpacity = _innerShadowOpacity.clamp(0.0, 1.0).toDouble();
    if (innerShadowOpacity > 0.001) {
      final radians = _innerShadowAngle * math.pi / 180.0;
      final shadowShift = Offset(
        math.cos(radians) * effectiveInnerShadowDistance,
        math.sin(radians) * effectiveInnerShadowDistance,
      );
      paintChildMask(
        at: offset + shadowShift,
        color: _innerShadowColor.withValues(
          alpha:
              innerShadowOpacity *
              (1 - (_innerShadowChoke / 140).clamp(0.0, 0.7)),
        ),
        blur: math.max(0.0, effectiveInnerShadowBlur / 3.0),
        blendMode: BlendMode.srcATop,
      );
    }

    final overlayOpacity = _overlayOpacity.clamp(0.0, 1.0).toDouble();
    if (overlayOpacity > 0.001) {
      paintChildMask(
        at: offset,
        color: _overlayColor.withValues(alpha: overlayOpacity),
        blendMode: BlendMode.srcATop,
      );
    }

    final gradientOpacity = _gradientOverlayOpacity.clamp(0.0, 1.0).toDouble();
    if (_gradientOverlayEnabled &&
        gradientOpacity > 0.001 &&
        _gradientOverlayColors.isNotEmpty) {
      final colors = _gradientOverlayReversed
          ? _gradientOverlayColors.reversed.toList(growable: false)
          : _gradientOverlayColors;
      final radians = _gradientOverlayAngle * math.pi / 180.0;
      final scale = (_gradientOverlayScale / 100).clamp(0.2, 3.0).toDouble();
      final direction = Offset(math.cos(radians), math.sin(radians)) * scale;
      context.canvas.saveLayer(
        bounds,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = const Color(0xFFFFFFFF).withValues(alpha: gradientOpacity),
      );
      context.paintChild(child!, offset);
      context.canvas.drawRect(
        offset & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(-direction.dx, -direction.dy),
            end: Alignment(direction.dx, direction.dy),
            colors: colors,
          ).createShader(offset & size)
          ..blendMode = BlendMode.srcIn,
      );
      context.canvas.restore();
    }
  }
}

class _EditorBlendLayer extends SingleChildRenderObjectWidget {
  const _EditorBlendLayer({
    required this.blendMode,
    this.opacity = 1,
    required super.child,
  });

  final BlendMode blendMode;
  final double opacity;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEditorBlendLayer(blendMode, opacity);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderEditorBlendLayer renderObject,
  ) {
    renderObject.blendMode = blendMode;
    renderObject.opacity = opacity;
  }
}

class _RenderEditorBlendLayer extends RenderProxyBox {
  _RenderEditorBlendLayer(this._blendMode, this._opacity);

  BlendMode _blendMode;
  double _opacity;

  set blendMode(BlendMode value) {
    if (_blendMode == value) return;
    _blendMode = value;
    markNeedsPaint();
  }

  set opacity(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if ((_opacity - next).abs() < 0.0001) return;
    _opacity = next;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_blendMode == BlendMode.srcOver && _opacity >= 0.9999) {
      super.paint(context, offset);
      return;
    }
    context.canvas.saveLayer(
      offset & size,
      Paint()
        ..blendMode = _blendMode
        ..color = Color.fromRGBO(255, 255, 255, _opacity),
    );
    super.paint(context, offset);
    context.canvas.restore();
  }
}

class _EditorLayerMaskFrame extends SingleChildRenderObjectWidget {
  const _EditorLayerMaskFrame({
    required this.shape,
    required this.inverted,
    required this.feather,
    required this.brushStrokes,
    required super.child,
  });

  final String shape;
  final bool inverted;
  final double feather;
  final List<_LayerMaskBrushStroke> brushStrokes;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEditorLayerMaskFrame(shape, inverted, feather, brushStrokes);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderEditorLayerMaskFrame renderObject,
  ) {
    renderObject
      ..shape = shape
      ..inverted = inverted
      ..feather = feather
      ..brushStrokes = brushStrokes;
  }
}

class _RenderEditorLayerMaskFrame extends RenderProxyBox {
  _RenderEditorLayerMaskFrame(
    this._shape,
    this._inverted,
    this._feather,
    this._brushStrokes,
  );

  String _shape;
  bool _inverted;
  double _feather;
  List<_LayerMaskBrushStroke> _brushStrokes;

  set shape(String value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  set inverted(bool value) {
    if (_inverted == value) return;
    _inverted = value;
    markNeedsPaint();
  }

  set feather(double value) {
    final next = value.clamp(0.0, 60.0).toDouble();
    if ((_feather - next).abs() < 0.0001) return;
    _feather = next;
    markNeedsPaint();
  }

  set brushStrokes(List<_LayerMaskBrushStroke> value) {
    if (identical(_brushStrokes, value)) return;
    _brushStrokes = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null ||
        size.isEmpty ||
        (_shape.trim().isEmpty && _brushStrokes.isEmpty)) {
      super.paint(context, offset);
      return;
    }
    final bounds = offset & size;
    context.canvas.saveLayer(bounds, Paint());
    super.paint(context, offset);
    context.canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _paintLayerMaskAlpha(context.canvas, offset, size);
    context.canvas.restore();
    context.canvas.restore();
  }

  void _paintLayerMaskAlpha(Canvas canvas, Offset offset, Size size) {
    final bounds = offset & size;
    canvas.saveLayer(bounds, Paint());
    if (_shape.trim().isNotEmpty) {
      final path = _EditorPhotoMaskClipper(_shape).getClip(size).shift(offset);
      final maskPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..blendMode = BlendMode.srcOver;
      final feather = _feather.clamp(0.0, 60.0).toDouble();
      if (feather > 0.001) {
        maskPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, feather / 2);
      }
      if (_inverted) {
        canvas.drawRect(bounds, Paint()..color = const Color(0xFFFFFFFF));
        final cutPaint = Paint()
          ..blendMode = BlendMode.clear
          ..isAntiAlias = true;
        if (feather > 0.001) {
          cutPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, feather / 2);
        }
        canvas.drawPath(path, cutPaint);
      } else {
        canvas.drawPath(path, maskPaint);
      }
    } else {
      canvas.drawRect(bounds, Paint()..color = const Color(0xFFFFFFFF));
    }
    for (final stroke in _brushStrokes) {
      _paintLayerMaskBrushStroke(canvas, offset, size, stroke);
    }
    canvas.restore();
  }

  void _paintLayerMaskBrushStroke(
    Canvas canvas,
    Offset offset,
    Size size,
    _LayerMaskBrushStroke stroke,
  ) {
    if (stroke.points.isEmpty) {
      return;
    }
    final radius = math.max(0.0001, stroke.brushSize / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..blendMode = stroke.restores ? BlendMode.srcOver : BlendMode.clear
      ..strokeWidth = radius * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final hardness = stroke.hardness.clamp(0.0, 1.0).toDouble();
    if (hardness < 0.98) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(0.0001, radius * (1 - hardness)),
      );
    }
    Offset resolve(Offset point) =>
        offset +
        Offset(
          point.dx.clamp(0.0, 1.0).toDouble() * size.width,
          point.dy.clamp(0.0, 1.0).toDouble() * size.height,
        );
    if (stroke.points.length == 1) {
      canvas.drawCircle(resolve(stroke.points.first), radius, paint);
      return;
    }
    final path = Path()
      ..moveTo(
        resolve(stroke.points.first).dx,
        resolve(stroke.points.first).dy,
      );
    for (final point in stroke.points.skip(1)) {
      final resolved = resolve(point);
      path.lineTo(resolved.dx, resolved.dy);
    }
    canvas.drawPath(path, paint);
  }
}

class _TransparentCheckerPainter extends CustomPainter {
  const _TransparentCheckerPainter();

  static const double _cellSize = 14;
  static const Color _light = Color(0xFFE5E7EB);
  static const Color _dark = Color(0xFFCBD5E1);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final columns = (size.width / _cellSize).ceil();
    final rows = (size.height / _cellSize).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        paint.color = (x + y).isEven ? _light : _dark;
        canvas.drawRect(
          Rect.fromLTWH(x * _cellSize, y * _cellSize, _cellSize, _cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TransparentCheckerPainter oldDelegate) => false;
}

double _mapAdjustBlurToSigma(double blur) {
  final normalized = (blur / 14).clamp(0.0, 1.0);
  final eased = math.pow(normalized, 1.85).toDouble();
  return (eased * 14).clamp(0.0, 14.0);
}

List<double> _brightnessContrastMatrix({
  required double brightness,
  required double contrast,
}) {
  final clampedContrast = contrast.clamp(0.38, 1.8);
  final clampedBrightness = brightness.clamp(-0.55, 0.55);
  final bias = (clampedBrightness * 255) + ((1 - clampedContrast) * 128);
  return <double>[
    clampedContrast,
    0,
    0,
    0,
    bias,
    0,
    clampedContrast,
    0,
    0,
    bias,
    0,
    0,
    clampedContrast,
    0,
    bias,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _saturationMatrix(double saturation) {
  final s = saturation.clamp(0.0, 2.5);
  const rw = 0.3086;
  const gw = 0.6094;
  const bw = 0.0820;
  final inv = 1 - s;
  final r = inv * rw;
  final g = inv * gw;
  final b = inv * bw;
  return <double>[
    r + s,
    g,
    b,
    0,
    0,
    r,
    g + s,
    b,
    0,
    0,
    r,
    g,
    b + s,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

double _normalizeAngle(double angle) {
  var normalized = angle % (2 * math.pi);
  if (normalized < 0) {
    normalized += 2 * math.pi;
  }
  return normalized;
}

double _shortestAngleDelta({required double from, required double to}) {
  var delta = to - from;
  while (delta > math.pi) {
    delta -= 2 * math.pi;
  }
  while (delta < -math.pi) {
    delta += 2 * math.pi;
  }
  return delta;
}

double _matrixRotationZ(Matrix4 matrix) {
  final m = matrix.storage;
  return math.atan2(m[1], m[0]);
}

double _softSnapRotation(double angle) {
  final normalized = _normalizeAngle(angle);
  const targets = <double>[
    0,
    math.pi / 4,
    math.pi / 2,
    3 * math.pi / 4,
    math.pi,
    5 * math.pi / 4,
    3 * math.pi / 2,
    7 * math.pi / 4,
    2 * math.pi,
  ];

  var nearest = targets.first;
  var smallestDelta = double.infinity;
  for (final target in targets) {
    final delta = _shortestAngleDelta(from: normalized, to: target).abs();
    if (delta < smallestDelta) {
      smallestDelta = delta;
      nearest = target;
    }
  }

  if (smallestDelta > _ImageEditorScreenState._rotationSnapThresholdRadians) {
    return angle;
  }

  final snapDelta = _shortestAngleDelta(from: normalized, to: nearest);
  return angle + snapDelta;
}

double? _rotationSnapGuideAngle(double angle) {
  final normalized = _normalizeAngle(angle);
  const targets = <double>[
    0,
    math.pi / 4,
    math.pi / 2,
    3 * math.pi / 4,
    math.pi,
    5 * math.pi / 4,
    3 * math.pi / 2,
    7 * math.pi / 4,
    2 * math.pi,
  ];
  var nearest = targets.first;
  var smallestDelta = double.infinity;
  for (final target in targets) {
    final delta = _shortestAngleDelta(from: normalized, to: target).abs();
    if (delta < smallestDelta) {
      smallestDelta = delta;
      nearest = target;
    }
  }
  if (smallestDelta > _ImageEditorScreenState._rotationSnapThresholdRadians) {
    return null;
  }
  return nearest == 2 * math.pi ? 0 : nearest;
}

Uint8List _optimizeEditorPhotoBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    throw const FormatException('Unsupported editor image');
  }

  final sourcePixels = decoded.width * decoded.height;
  if (sourcePixels <= _editorPhotoImportMaxPixels &&
      bytes.length <= _editorPhotoImportMaxEncodedBytes) {
    return bytes;
  }

  var working = img.bakeOrientation(decoded);
  final width = working.width;
  final height = working.height;
  final pixelScale = math.sqrt(_editorPhotoImportMaxPixels / (width * height));
  final sideScale = _editorPhotoImportMaxSide / math.max(width, height);
  final scale = math.min(1.0, math.min(pixelScale, sideScale));
  if (scale < 0.999) {
    working = img.copyResize(
      working,
      width: math.max(1, (width * scale).round()),
      height: math.max(1, (height * scale).round()),
      interpolation: img.Interpolation.linear,
    );
  }

  if (_editorImageHasTransparency(working)) {
    return Uint8List.fromList(img.encodePng(working));
  }
  return Uint8List.fromList(img.encodeJpg(working, quality: 92));
}

_OptimizedPhotoPayload _optimizeEditorPhotoPayload(Uint8List bytes) {
  final optimizedBytes = _optimizeEditorPhotoBytes(bytes);
  final info = img
      .findDecoderForData(optimizedBytes)
      ?.startDecode(optimizedBytes);
  final aspectRatio = info != null && info.height > 0
      ? info.width / info.height
      : null;
  return _OptimizedPhotoPayload(
    bytes: optimizedBytes,
    aspectRatio: aspectRatio,
  );
}

bool _editorImageHasTransparency(img.Image image) {
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a < 255) {
        return true;
      }
    }
  }
  return false;
}

Map<String, Object?>? _decodePsdToEditorPayload(Uint8List bytes) {
  try {
    final textLayers = _extractPsdTextLayerPayloads(bytes);
    final file = psd.File.fromByteData(bytes);
    final document = psd.Document.fromFile(file);
    final width = document.width ?? 0;
    final height = document.height ?? 0;
    final bits = document.bitsPerChannel ?? 0;
    if (width <= 0 || height <= 0 || bits != 8) {
      return <String, Object?>{
        'error': 'Only 8-bit RGB PSD files are supported.',
      };
    }
    final canvasPixels = width * height;
    if (canvasPixels > _designImportMaxCanvasPixels) {
      return <String, Object?>{
        'error':
            'PSD canvas is too large. Keep it under 64 megapixels for import.',
      };
    }
    if (document.colorMode != psd.ColorMode.rgb) {
      return <String, Object?>{'error': 'Only RGB PSD files are supported.'};
    }
    final layerMaskSection = document.parseLayerMaskSection(file);
    final records = (layerMaskSection?.layers ?? <psd.Layer?>[])
        .whereType<psd.Layer>()
        .toList(growable: false);
    final layerWorkPixels = canvasPixels * math.max(1, records.length);
    if (layerWorkPixels > _designImportMaxPsdLayerWorkPixels) {
      return <String, Object?>{
        'error':
            'PSD has too many large layers for safe mobile import. '
            'Flatten unused layers or reduce canvas size.',
      };
    }
    final layers = <Map<String, Object?>>[];
    var layerIndex = 0;
    for (final layer in records) {
      layer.extract(file);
      final textLayer = layerIndex < textLayers.length
          ? textLayers[layerIndex]
          : null;
      layerIndex++;
      final redChannel = layer.findChannel(psd.ChannelType.r);
      final greenChannel = layer.findChannel(psd.ChannelType.g);
      final blueChannel = layer.findChannel(psd.ChannelType.b);
      if (redChannel?.data == null ||
          greenChannel?.data == null ||
          blueChannel?.data == null) {
        continue;
      }
      final red = _expandPsdLayerChannel(
        layer,
        redChannel!.data!,
        bits,
        width,
        height,
      );
      final green = _expandPsdLayerChannel(
        layer,
        greenChannel!.data!,
        bits,
        width,
        height,
      );
      final blue = _expandPsdLayerChannel(
        layer,
        blueChannel!.data!,
        bits,
        width,
        height,
      );
      if (red == null || green == null || blue == null) {
        continue;
      }
      final alphaChannel = layer.findChannel(psd.ChannelType.transparencyMask);
      final alpha = alphaChannel?.data == null
          ? _opaqueAlphaForPsdLayerBounds(layer, width, height)
          : _expandPsdLayerChannel(
              layer,
              alphaChannel!.data!,
              bits,
              width,
              height,
            );
      final rgba = psd.interleaveRGBA(
        red,
        green,
        blue,
        alpha,
        bits,
        width,
        height,
      );
      if (rgba == null || rgba.isEmpty) {
        continue;
      }
      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: Uint8List.fromList(rgba).buffer,
        order: img.ChannelOrder.rgba,
      );
      final layerLeft = ((layer.left ?? 0).clamp(0, width)).toInt();
      final layerTop = ((layer.top ?? 0).clamp(0, height)).toInt();
      final layerRight = ((layer.right ?? width).clamp(0, width)).toInt();
      final layerBottom = ((layer.bottom ?? height).clamp(0, height)).toInt();
      final hasValidBounds = layerRight > layerLeft && layerBottom > layerTop;
      final exportImage = hasValidBounds
          ? img.copyCrop(
              image,
              x: layerLeft,
              y: layerTop,
              width: layerRight - layerLeft,
              height: layerBottom - layerTop,
            )
          : image;
      final pngBytes = Uint8List.fromList(img.encodePng(exportImage, level: 6));
      final utf16Name = layer.utf16Name;
      final layerName = utf16Name == null
          ? (layer.name ?? '')
          : String.fromCharCodes(utf16Name.where((value) => value != 0));
      layers.add(<String, Object?>{
        'name': layerName.trim().isEmpty ? 'PSD Layer' : layerName.trim(),
        'bytes': pngBytes,
        'opacity': ((layer.opacity ?? 255) / 255).clamp(0.0, 1.0),
        'hidden': layer.isVisible == false,
        'left': hasValidBounds ? layerLeft : 0,
        'top': hasValidBounds ? layerTop : 0,
        'right': hasValidBounds ? layerRight : width,
        'bottom': hasValidBounds ? layerBottom : height,
        if (textLayer != null) ...textLayer.toPayload(),
      });
    }
    if (layers.isEmpty) {
      final merged = _decodePsdMergedImage(document, file, width, height, bits);
      if (merged != null) {
        layers.add(<String, Object?>{
          'name': 'PSD Merged Image',
          'bytes': merged,
          'opacity': 1.0,
          'hidden': false,
        });
      }
    }
    if (layers.isEmpty) {
      return <String, Object?>{
        'error': 'PSD file has no readable raster layer data.',
      };
    }
    return <String, Object?>{
      'width': width,
      'height': height,
      'layers': layers,
    };
  } catch (_) {
    return <String, Object?>{
      'error': 'PSD file import failed. Try another PSD.',
    };
  }
}

@visibleForTesting
Map<String, Object?>? debugDecodePsdToEditorPayloadForTest(Uint8List bytes) {
  return _decodePsdToEditorPayload(bytes);
}

List<_PsdTextLayerPayload?> _extractPsdTextLayerPayloads(Uint8List bytes) {
  try {
    final reader = _PsdByteReader(bytes);
    if (reader.readAscii(4) != '8BPS' || reader.readUint16() != 1) {
      return const <_PsdTextLayerPayload?>[];
    }
    reader.skip(6);
    reader.skip(2);
    reader.skip(4);
    reader.skip(4);
    reader.skip(2);
    reader.skip(2);
    reader.skip(reader.readUint32());
    reader.skip(reader.readUint32());
    final layerMaskLength = reader.readUint32();
    if (layerMaskLength <= 0 || !reader.canRead(layerMaskLength)) {
      return const <_PsdTextLayerPayload?>[];
    }
    final layerInfoLength = reader.readUint32();
    if (layerInfoLength <= 0 || !reader.canRead(layerInfoLength)) {
      return const <_PsdTextLayerPayload?>[];
    }
    final layerInfoEnd = reader.position + layerInfoLength;
    var layerCount = reader.readInt16();
    if (layerCount < 0) {
      layerCount = -layerCount;
    }
    if (layerCount <= 0 || layerCount > 4096) {
      return const <_PsdTextLayerPayload?>[];
    }
    final result = List<_PsdTextLayerPayload?>.filled(layerCount, null);
    for (var i = 0; i < layerCount; i++) {
      final top = reader.readInt32();
      final left = reader.readInt32();
      final bottom = reader.readInt32();
      final right = reader.readInt32();
      final channelCount = reader.readUint16();
      for (var c = 0; c < channelCount; c++) {
        reader.skip(2);
        reader.skip(4);
      }
      reader.skip(4);
      reader.skip(4);
      reader.skip(1);
      reader.skip(1);
      reader.skip(1);
      reader.skip(1);
      final extraLength = reader.readUint32();
      final extraEnd = reader.position + extraLength;
      if (extraLength < 0 || extraEnd > bytes.length) {
        break;
      }
      if (reader.position < extraEnd) {
        reader.skip(reader.readUint32());
      }
      if (reader.position < extraEnd) {
        reader.skip(reader.readUint32());
      }
      if (reader.position < extraEnd) {
        final nameLength = reader.readUint8();
        reader.skip(nameLength);
        reader.skip((4 - ((nameLength + 1) % 4)) % 4);
      }
      while (reader.position + 12 <= extraEnd) {
        final signature = reader.readAscii(4);
        if (signature != '8BIM' && signature != '8B64') {
          break;
        }
        final key = reader.readAscii(4);
        final length = reader.readUint32();
        final dataStart = reader.position;
        final dataEnd = dataStart + length;
        if (length < 0 || dataEnd > extraEnd || dataEnd > bytes.length) {
          break;
        }
        if (key == 'TySh' || key == 'tySh') {
          final typeToolData = Uint8List.sublistView(bytes, dataStart, dataEnd);
          final text = _extractPsdDescriptorText(typeToolData).trim();
          if (_looksLikeReadablePsdText(text)) {
            final width = math.max(1, right - left);
            final height = math.max(1, bottom - top);
            final style = _extractPsdEngineTextStyle(typeToolData);
            final typeToolScale = _extractPsdTypeToolVerticalScale(
              typeToolData,
            );
            result[i] = _PsdTextLayerPayload(
              text: text.replaceAll('\r', '\n'),
              fontSize:
                  (style.fontSize == null
                      ? null
                      : style.fontSize! * typeToolScale) ??
                  math.max(10, math.min(220, height * 0.72)).toDouble(),
              fontFamily: style.fontFamily,
              textAlign: width > height * 8 ? 'left' : 'center',
            );
          }
        }
        reader.position = dataEnd + (length.isOdd ? 1 : 0);
      }
      reader.position = extraEnd;
    }
    reader.position = layerInfoEnd;
    return result;
  } catch (_) {
    return const <_PsdTextLayerPayload?>[];
  }
}

String _extractPsdDescriptorText(Uint8List data) {
  for (final key in const <String>['Txt ', 'text', 'Text']) {
    final keyIndex = _indexOfAscii(data, key);
    if (keyIndex < 0) {
      continue;
    }
    final typeIndex = _indexOfAscii(data, 'TEXT', start: keyIndex + 4);
    if (typeIndex < 0 || typeIndex + 8 > data.length) {
      continue;
    }
    final reader = _PsdByteReader(data)..position = typeIndex + 4;
    final count = reader.readUint32();
    if (count <= 0 || count > 20000 || !reader.canRead(count * 2)) {
      continue;
    }
    final units = <int>[];
    for (var i = 0; i < count && reader.canRead(2); i++) {
      final value = reader.readUint16();
      if (value != 0) {
        units.add(value);
      }
    }
    final value = String.fromCharCodes(units).trim();
    if (_looksLikeReadablePsdText(value)) {
      return value;
    }
  }
  return '';
}

_PsdEngineTextStyle _extractPsdEngineTextStyle(Uint8List data) {
  final engineIndex = _indexOfAscii(data, 'EngineData');
  if (engineIndex < 0) {
    return const _PsdEngineTextStyle();
  }
  final engine = String.fromCharCodes(data.sublist(engineIndex));
  final fontMatch = RegExp(
    r'/StyleSheetData\s*<<[\s\S]*?/Font\s+(\d+)[\s\S]*?/FontSize\s+([0-9.]+)',
  ).firstMatch(engine);
  final fontIndex = int.tryParse(fontMatch?.group(1) ?? '');
  final fontSize = double.tryParse(fontMatch?.group(2) ?? '');
  final fontNames = <String>[];
  final fontSetIndex = engine.indexOf('/FontSet');
  if (fontSetIndex >= 0) {
    final fontSet = data.sublist(engineIndex + fontSetIndex);
    const nameMarker = '/Name (';
    var searchStart = 0;
    while (true) {
      final markerIndex = _indexOfAscii(
        fontSet,
        nameMarker,
        start: searchStart,
      );
      if (markerIndex < 0) {
        break;
      }
      final valueStart = markerIndex + nameMarker.length;
      var valueEnd = valueStart;
      var escaped = false;
      while (valueEnd < fontSet.length) {
        final value = fontSet[valueEnd];
        if (value == 0x29 && !escaped) {
          break;
        }
        if (value == 0x5C && !escaped) {
          escaped = true;
        } else {
          escaped = false;
        }
        valueEnd++;
      }
      if (valueEnd > valueStart) {
        final decoded = _decodePsdEngineName(
          Uint8List.sublistView(fontSet, valueStart, valueEnd),
        );
        if (decoded.isNotEmpty &&
            !decoded.toLowerCase().startsWith('photoshop')) {
          fontNames.add(decoded);
        }
      }
      searchStart = valueEnd + 1;
    }
  }
  final fontFamily =
      fontIndex != null && fontIndex >= 0 && fontIndex < fontNames.length
      ? fontNames[fontIndex]
      : (fontNames.isNotEmpty ? fontNames.first : null);
  return _PsdEngineTextStyle(fontFamily: fontFamily, fontSize: fontSize);
}

String _decodePsdEngineName(Uint8List bytes) {
  if (bytes.isEmpty) {
    return '';
  }
  final decodedBytes = <int>[];
  for (var i = 0; i < bytes.length; i++) {
    final value = bytes[i];
    if (value != 0x5C || i + 1 >= bytes.length) {
      decodedBytes.add(value);
      continue;
    }
    final next = bytes[i + 1];
    if (next >= 0x30 && next <= 0x37) {
      var octalValue = 0;
      var digits = 0;
      while (digits < 3 && i + 1 < bytes.length) {
        final digit = bytes[i + 1];
        if (digit < 0x30 || digit > 0x37) {
          break;
        }
        octalValue = (octalValue * 8) + digit - 0x30;
        digits++;
        i++;
      }
      decodedBytes.add(octalValue & 0xFF);
      continue;
    }
    i++;
    switch (next) {
      case 0x6E:
        decodedBytes.add(0x0A);
        break;
      case 0x72:
        decodedBytes.add(0x0D);
        break;
      case 0x74:
        decodedBytes.add(0x09);
        break;
      case 0x62:
        decodedBytes.add(0x08);
        break;
      case 0x66:
        decodedBytes.add(0x0C);
        break;
      case 0x0A:
        break;
      case 0x0D:
        if (i + 1 < bytes.length && bytes[i + 1] == 0x0A) {
          i++;
        }
        break;
      default:
        decodedBytes.add(next);
    }
  }
  final normalizedBytes = Uint8List.fromList(decodedBytes);
  var start = 0;
  if (normalizedBytes.length >= 2 &&
      normalizedBytes[0] == 0xFE &&
      normalizedBytes[1] == 0xFF) {
    start = 2;
  }
  final looksUtf16 =
      normalizedBytes.length - start >= 2 &&
      normalizedBytes
          .skip(start)
          .take(12)
          .where((value) => value == 0)
          .isNotEmpty;
  if (looksUtf16) {
    final units = <int>[];
    for (var i = start; i + 1 < normalizedBytes.length; i += 2) {
      final value = (normalizedBytes[i] << 8) | normalizedBytes[i + 1];
      if (value != 0) {
        units.add(value);
      }
    }
    return String.fromCharCodes(units).trim();
  }
  return String.fromCharCodes(
    normalizedBytes.where((value) => value != 0),
  ).trim();
}

double _extractPsdTypeToolVerticalScale(Uint8List data) {
  try {
    final reader = _PsdByteReader(data);
    if (reader.readUint16() != 1) {
      return 1;
    }
    reader.readFloat64();
    reader.readFloat64();
    final yx = reader.readFloat64();
    final yy = reader.readFloat64();
    final scale = math.sqrt((yx * yx) + (yy * yy));
    if (!scale.isFinite || scale <= 0.001 || scale > 100) {
      return 1;
    }
    return scale;
  } catch (_) {
    return 1;
  }
}

@visibleForTesting
String debugDecodePsdEngineNameForTest(Uint8List bytes) =>
    _decodePsdEngineName(bytes);

@visibleForTesting
double debugExtractPsdTypeToolVerticalScaleForTest(Uint8List bytes) =>
    _extractPsdTypeToolVerticalScale(bytes);

bool _looksLikeReadablePsdText(String value) {
  final trimmed = value.trim();
  if (trimmed.length < 2) {
    return false;
  }
  var useful = 0;
  var visible = 0;
  var cjk = 0;
  for (final rune in trimmed.runes) {
    if (rune == 0 ||
        (rune < 0x20 && rune != 0x09 && rune != 0x0A && rune != 0x0D) ||
        (rune >= 0xD800 && rune <= 0xDFFF) ||
        rune == 0xFFFD) {
      return false;
    }
    if (rune == 0x09 || rune == 0x0A || rune == 0x0D || rune == 0x20) {
      continue;
    }
    visible += 1;
    final isLatin =
        (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
    final isDigit = rune >= 0x30 && rune <= 0x39;
    final isIndic = rune >= 0x0900 && rune <= 0x0D7F;
    final isLegacy = rune >= 0xE000 && rune <= 0xF8FF;
    final isPunctuation =
        (rune >= 0x21 && rune <= 0x2F) ||
        (rune >= 0x3A && rune <= 0x40) ||
        (rune >= 0x5B && rune <= 0x7E) ||
        rune == 0x20B9;
    if (rune >= 0x3400 && rune <= 0x9FFF) {
      cjk += 1;
    }
    if (isLatin || isDigit || isIndic || isLegacy || isPunctuation) {
      useful += 1;
    }
  }
  if (visible == 0 || useful < 2) {
    return false;
  }
  return cjk < math.max(4, visible * 0.18) && useful >= visible * 0.7;
}

int _indexOfAscii(Uint8List data, String pattern, {int start = 0}) {
  final codes = pattern.codeUnits;
  for (var i = math.max(0, start); i <= data.length - codes.length; i++) {
    var matched = true;
    for (var j = 0; j < codes.length; j++) {
      if (data[i + j] != codes[j]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      return i;
    }
  }
  return -1;
}

class _PsdTextLayerPayload {
  const _PsdTextLayerPayload({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
    required this.textAlign,
  });

  final String text;
  final double fontSize;
  final String? fontFamily;
  final String textAlign;

  Map<String, Object?> toPayload() => <String, Object?>{
    'psdEditableText': text,
    'psdEditableFontSize': fontSize,
    'psdEditableFontFamily': fontFamily,
    'psdEditableTextAlign': textAlign,
  };
}

class _PsdEngineTextStyle {
  const _PsdEngineTextStyle({this.fontFamily, this.fontSize});

  final String? fontFamily;
  final double? fontSize;
}

class _PsdByteReader {
  _PsdByteReader(this.bytes) : data = ByteData.sublistView(bytes);

  final Uint8List bytes;
  final ByteData data;
  int position = 0;

  bool canRead(int count) => count >= 0 && position + count <= bytes.length;

  void skip(int count) {
    position = (position + math.max(0, count)).clamp(0, bytes.length).toInt();
  }

  int readUint8() {
    final value = data.getUint8(position);
    position += 1;
    return value;
  }

  int readUint16() {
    final value = data.getUint16(position);
    position += 2;
    return value;
  }

  int readInt16() {
    final value = data.getInt16(position);
    position += 2;
    return value;
  }

  int readUint32() {
    final value = data.getUint32(position);
    position += 4;
    return value;
  }

  int readInt32() {
    final value = data.getInt32(position);
    position += 4;
    return value;
  }

  double readFloat64() {
    final value = data.getFloat64(position);
    position += 8;
    return value;
  }

  String readAscii(int count) {
    if (!canRead(count)) {
      position = bytes.length;
      return '';
    }
    final value = String.fromCharCodes(
      bytes.sublist(position, position + count),
    );
    position += count;
    return value;
  }
}

Uint8List _opaqueAlphaForPsdLayerBounds(
  psd.Layer layer,
  int canvasWidth,
  int canvasHeight,
) {
  final alpha = Uint8List(canvasWidth * canvasHeight);
  final left = (layer.left ?? 0).clamp(0, canvasWidth).toInt();
  final top = (layer.top ?? 0).clamp(0, canvasHeight).toInt();
  final right = (layer.right ?? 0).clamp(0, canvasWidth).toInt();
  final bottom = (layer.bottom ?? 0).clamp(0, canvasHeight).toInt();
  for (var y = top; y < bottom; y++) {
    final rowOffset = y * canvasWidth;
    for (var x = left; x < right; x++) {
      alpha[rowOffset + x] = 255;
    }
  }
  return alpha;
}

Uint8List? _expandPsdLayerChannel(
  psd.Layer layer,
  Uint8List channelData,
  int bits,
  int canvasWidth,
  int canvasHeight,
) {
  final canvasData = Uint8List((bits ~/ 8) * canvasWidth * canvasHeight);
  final copied = psd.ImageUtil.copyLayerData(
    channelData,
    canvasData,
    bits,
    layer.left ?? 0,
    layer.top ?? 0,
    layer.right ?? 0,
    layer.bottom ?? 0,
    canvasWidth,
    canvasHeight,
  );
  return copied ? canvasData : null;
}

Uint8List? _decodePsdMergedImage(
  psd.Document document,
  psd.File file,
  int width,
  int height,
  int bits,
) {
  final imageData = document.parseImageDataSection(file);
  if (imageData == null || (imageData.imageCount) < 3) {
    return null;
  }
  final red = (imageData.images?[0])?.data;
  final green = (imageData.images?[1])?.data;
  final blue = (imageData.images?[2])?.data;
  if (red == null || green == null || blue == null) {
    return null;
  }
  final alpha = imageData.imageCount >= 4 ? (imageData.images?[3])?.data : null;
  final rgba = alpha == null
      ? psd.interleaveRGB(red, green, blue, 255, bits, width, height)
      : psd.interleaveRGBA(red, green, blue, alpha, bits, width, height);
  if (rgba == null) {
    return null;
  }
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: Uint8List.fromList(rgba).buffer,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodePng(image, level: 6));
}

Uint8List _encodeFlattenedPsdFromRgba(Map<String, Object?> input) {
  final width = input['width']! as int;
  final height = input['height']! as int;
  final rgba = input['rgba']! as Uint8List;
  return _encodeLayeredPsdFromRgbaPayload(<String, Object?>{
    'width': width,
    'height': height,
    'mergedRgba': rgba,
    'layers': <Map<String, Object?>>[
      <String, Object?>{'name': 'Mana Poster Export', 'rgba': rgba},
    ],
  });
}

Uint8List _encodeLayeredPsdFromRgbaPayload(Map<String, Object?> input) {
  final width = input['width']! as int;
  final height = input['height']! as int;
  final mergedRgba = input['mergedRgba']! as Uint8List;
  final layers = (input['layers']! as List<Object?>)
      .whereType<Map<Object?, Object?>>()
      .toList(growable: false);
  if (width <= 0 || height <= 0 || layers.isEmpty) {
    throw Exception('PSD layer payload is empty');
  }
  final pixelBytes = width * height * 4;
  if (mergedRgba.length != pixelBytes) {
    throw Exception('PSD merged payload size is invalid');
  }
  final document = psd.ExportDocument(
    width,
    height,
    8,
    psd.ExportColorMode.rgb,
  );
  final mergedChannels = _splitRgbaToPsdChannels(width, height, mergedRgba);
  document.updateMergedImage(
    mergedChannels.red,
    mergedChannels.green,
    mergedChannels.blue,
  );
  for (final layerPayload in layers) {
    final rgba = layerPayload['rgba'];
    if (rgba is! Uint8List || rgba.length != pixelBytes) {
      continue;
    }
    final name = _normalizePsdLayerName(
      layerPayload['name'] as String? ?? 'Mana Poster Layer',
    );
    final layer = document.addLayer(
      document,
      name.isEmpty ? 'Mana Poster Layer' : name,
    );
    if (layer == null) {
      continue;
    }
    final channels = _splitRgbaToPsdChannels(width, height, rgba);
    document.updateLayer(
      layer,
      psd.ExportChannel.red,
      0,
      0,
      width,
      height,
      channels.red,
      psd.CompressionType.rle,
    );
    document.updateLayer(
      layer,
      psd.ExportChannel.green,
      0,
      0,
      width,
      height,
      channels.green,
      psd.CompressionType.rle,
    );
    document.updateLayer(
      layer,
      psd.ExportChannel.blue,
      0,
      0,
      width,
      height,
      channels.blue,
      psd.CompressionType.rle,
    );
    document.updateLayer(
      layer,
      psd.ExportChannel.alpha,
      0,
      0,
      width,
      height,
      channels.alpha,
      psd.CompressionType.rle,
    );
  }
  if (document.layerCount == 0) {
    throw Exception('PSD layer creation failed');
  }
  final file = psd.File();
  document.write(file);
  final output = file.bytes;
  if (output == null || output.isEmpty) {
    throw Exception('PSD write failed');
  }
  return output;
}

@visibleForTesting
Uint8List debugEncodeLayeredPsdFromRgbaPayloadForTest(
  Map<String, Object?> input,
) {
  return _encodeLayeredPsdFromRgbaPayload(input);
}

String _normalizePsdLayerName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Mana Poster Layer';
  }
  const maxPascalLayerNameLength = 255;
  if (trimmed.length <= maxPascalLayerNameLength) {
    return trimmed;
  }
  return trimmed.substring(0, maxPascalLayerNameLength);
}

({Uint8List red, Uint8List green, Uint8List blue, Uint8List alpha})
_splitRgbaToPsdChannels(int width, int height, Uint8List rgba) {
  final pixelCount = width * height;
  final red = Uint8List(pixelCount);
  final green = Uint8List(pixelCount);
  final blue = Uint8List(pixelCount);
  final alpha = Uint8List(pixelCount);
  for (var i = 0; i < pixelCount; i++) {
    final source = i * 4;
    red[i] = rgba[source];
    green[i] = rgba[source + 1];
    blue[i] = rgba[source + 2];
    alpha[i] = rgba[source + 3];
  }
  return (red: red, green: green, blue: blue, alpha: alpha);
}

_OptimizedPhotoPayload _trimTransparentEditorPhotoPayload(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    return _OptimizedPhotoPayload(bytes: bytes, aspectRatio: null);
  }

  const alphaThreshold = 8;
  var minX = decoded.width;
  var minY = decoded.height;
  var maxX = -1;
  var maxY = -1;
  var hasTransparentPixel = false;

  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final alpha = decoded.getPixel(x, y).a.toInt();
      if (alpha < 250) {
        hasTransparentPixel = true;
      }
      if (alpha > alphaThreshold) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (!hasTransparentPixel || maxX < minX || maxY < minY) {
    return _OptimizedPhotoPayload(
      bytes: bytes,
      aspectRatio: decoded.width / decoded.height,
    );
  }

  const paddingRatio = 0.025;
  final contentWidth = maxX - minX + 1;
  final contentHeight = maxY - minY + 1;
  final padX = math.max(2, (contentWidth * paddingRatio).round());
  final padY = math.max(2, (contentHeight * paddingRatio).round());
  final cropX = math.max(0, minX - padX);
  final cropY = math.max(0, minY - padY);
  final cropRight = math.min(decoded.width - 1, maxX + padX);
  final cropBottom = math.min(decoded.height - 1, maxY + padY);
  final cropWidth = cropRight - cropX + 1;
  final cropHeight = cropBottom - cropY + 1;

  final widthCoverage = cropWidth / decoded.width;
  final heightCoverage = cropHeight / decoded.height;
  if (widthCoverage > 0.985 && heightCoverage > 0.985) {
    return _OptimizedPhotoPayload(
      bytes: bytes,
      aspectRatio: decoded.width / decoded.height,
    );
  }

  final cropped = img.copyCrop(
    decoded,
    x: cropX,
    y: cropY,
    width: cropWidth,
    height: cropHeight,
  );
  final croppedBytes = Uint8List.fromList(img.encodePng(cropped, level: 6));
  return _OptimizedPhotoPayload(
    bytes: croppedBytes,
    aspectRatio: cropWidth / cropHeight,
  );
}

double? _extractImageAspectRatio(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.height == 0) {
    return null;
  }
  return decoded.width / decoded.height;
}

class _CanvasWorkspace extends StatelessWidget {
  const _CanvasWorkspace({
    required this.layers,
    required this.selectedLayerId,
    required this.canvasBackgroundColor,
    required this.canvasBackgroundGradientIndex,
    required this.stageBackgroundImageBytes,
    required this.backgroundBlurAmount,
    required this.borderStyle,
    required this.borderWidth,
    required this.borderRadius,
    required this.borderColor,
    required this.borderTargetLayerId,
    required this.canvasSize,
    required this.pageAspectRatio,
    required this.hideAutoPageFrame,
    required this.showTransparentCheckerboard,
    required this.topInset,
    required this.bottomInset,
    required this.viewportScale,
    required this.transformationController,
    required this.onSelectedLayerInteractionStart,
    required this.onSelectedLayerScaleUpdate,
    required this.onLayerSelected,
    required this.onSelectedLayerInteractionEnd,
    required this.onSelectedTransformHandlePointerDown,
    required this.onSelectedStickerHandleStart,
    required this.onSelectedStickerHandleUpdate,
    required this.onSelectedObjectHorizontalResizeHandleStart,
    required this.onSelectedObjectHorizontalResizeHandleUpdate,
    required this.onSelectedObjectVerticalResizeHandleStart,
    required this.onSelectedObjectVerticalResizeHandleUpdate,
    required this.onSelectedStickerRotateHandleStart,
    required this.onSelectedStickerRotateHandleUpdate,
    required this.onSelectedTextResizeHandleStart,
    required this.onSelectedTextResizeHandleUpdate,
    required this.onSelectedTextRotateHandleStart,
    required this.onSelectedTextRotateHandleUpdate,
    required this.onSelectedTextStretchHandleStart,
    required this.onSelectedTextStretchHandleUpdate,
    required this.onSelectedStickerHandleEnd,
    required this.onSelectedLayerDoubleTap,
    required this.onSelectedTextTap,
    required this.onSelectedTextDoubleTap,
    required this.onSelectedTextPointerDown,
    required this.onSelectedTextPointerMove,
    required this.onSelectedTextPointerCancel,
    required this.isTextTypingScreenOpen,
    required this.isPhotoEraserMode,
    required this.isPhotoStretchMode,
    required this.isContentAwareMode,
    required this.isPhotoCloneMode,
    required this.isLayerMaskBrushMode,
    required this.isDrawBrushMode,
    required this.onPhotoEraserStart,
    required this.onPhotoEraserUpdate,
    required this.onPhotoEraserEnd,
    required this.onPhotoEraserCancel,
    required this.onContentAwareStart,
    required this.onContentAwareUpdate,
    required this.onContentAwareEnd,
    required this.onContentAwareCancel,
    required this.onContentAwarePointerDown,
    required this.onContentAwarePointerEnd,
    required this.canUseContentAwarePointerStroke,
    required this.onPhotoCloneSourceTap,
    required this.onPhotoCloneStart,
    required this.onPhotoCloneUpdate,
    required this.onPhotoCloneEnd,
    required this.onPhotoCloneCancel,
    required this.onPhotoStretchStart,
    required this.onPhotoStretchUpdate,
    required this.onPhotoStretchEnd,
    required this.onPhotoStretchCancel,
    required this.onLayerMaskBrushStart,
    required this.onLayerMaskBrushUpdate,
    required this.onLayerMaskBrushEnd,
    required this.onLayerMaskBrushCancel,
    required this.onDrawBrushStart,
    required this.onDrawBrushUpdate,
    required this.onDrawBrushEnd,
    required this.onDrawBrushCancel,
    required this.onCanvasTapDown,
    required this.onCanvasLongPressStart,
    required this.onCanvasTap,
    required this.routeCanvasGesturesToSelectedLayer,
    required this.showCanvasBackground,
    required this.photoBrightnessForLayer,
    required this.photoContrastForLayer,
    required this.photoSaturationForLayer,
    required this.photoBlurForLayer,
    required this.photoSharpenForLayer,
    required this.photoGrainForLayer,
    required this.photoVignetteForLayer,
    required this.photoMotionForLayer,
    required this.photoTiltShiftForLayer,
    required this.photoShadowsForLayer,
    required this.photoHighlightsForLayer,
    required this.photoTemperatureForLayer,
    required this.photoTintForLayer,
    required this.showSelectionDecorations,
    required this.isLayerInteracting,
    required this.showPageFramePreview,
    required this.snapGuideListenable,
    required this.snapGuidesEnabled,
    required this.selectedPhotoRenderListenable,
    required this.eraserPreviewListenable,
    required this.stretchPreviewListenable,
    required this.drawPreviewListenable,
    required this.exportHighQuality,
    this.preferFullWidthPage = false,
    this.forceFullWidthPage = false,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final Color canvasBackgroundColor;
  final int canvasBackgroundGradientIndex;
  final Uint8List? stageBackgroundImageBytes;
  final double backgroundBlurAmount;
  final _BorderStyle borderStyle;
  final double borderWidth;
  final double borderRadius;
  final Color borderColor;
  final String? borderTargetLayerId;
  final Size canvasSize;
  final double? pageAspectRatio;
  final bool hideAutoPageFrame;
  final bool showTransparentCheckerboard;
  final double topInset;
  final double bottomInset;
  final double viewportScale;
  final TransformationController transformationController;
  final ValueChanged<ScaleStartDetails> onSelectedLayerInteractionStart;
  final ValueChanged<ScaleUpdateDetails> onSelectedLayerScaleUpdate;
  final ValueChanged<String> onLayerSelected;
  final VoidCallback onSelectedLayerInteractionEnd;
  final VoidCallback onSelectedTransformHandlePointerDown;
  final ValueChanged<DragStartDetails> onSelectedStickerHandleStart;
  final ValueChanged<DragUpdateDetails> onSelectedStickerHandleUpdate;
  final ValueChanged<DragStartDetails>
  onSelectedObjectHorizontalResizeHandleStart;
  final ValueChanged<DragUpdateDetails>
  onSelectedObjectHorizontalResizeHandleUpdate;
  final ValueChanged<DragStartDetails>
  onSelectedObjectVerticalResizeHandleStart;
  final ValueChanged<DragUpdateDetails>
  onSelectedObjectVerticalResizeHandleUpdate;
  final ValueChanged<DragStartDetails> onSelectedStickerRotateHandleStart;
  final ValueChanged<DragUpdateDetails> onSelectedStickerRotateHandleUpdate;
  final ValueChanged<DragStartDetails> onSelectedTextResizeHandleStart;
  final ValueChanged<DragUpdateDetails> onSelectedTextResizeHandleUpdate;
  final ValueChanged<DragStartDetails> onSelectedTextRotateHandleStart;
  final ValueChanged<DragUpdateDetails> onSelectedTextRotateHandleUpdate;
  final ValueChanged<DragStartDetails> onSelectedTextStretchHandleStart;
  final ValueChanged<DragUpdateDetails> onSelectedTextStretchHandleUpdate;
  final VoidCallback onSelectedStickerHandleEnd;
  final VoidCallback onSelectedLayerDoubleTap;
  final VoidCallback onSelectedTextTap;
  final VoidCallback onSelectedTextDoubleTap;
  final ValueChanged<PointerDownEvent> onSelectedTextPointerDown;
  final ValueChanged<PointerMoveEvent> onSelectedTextPointerMove;
  final VoidCallback onSelectedTextPointerCancel;
  final bool isTextTypingScreenOpen;
  final bool isPhotoEraserMode;
  final bool isPhotoStretchMode;
  final bool isContentAwareMode;
  final bool isPhotoCloneMode;
  final bool isLayerMaskBrushMode;
  final bool isDrawBrushMode;
  final void Function(Offset localPosition, Size layerSize) onPhotoEraserStart;
  final void Function(Offset localPosition, Size layerSize) onPhotoEraserUpdate;
  final VoidCallback onPhotoEraserEnd;
  final VoidCallback onPhotoEraserCancel;
  final void Function(Offset localPosition, Size layerSize) onContentAwareStart;
  final void Function(Offset localPosition, Size layerSize)
  onContentAwareUpdate;
  final VoidCallback onContentAwareEnd;
  final VoidCallback onContentAwareCancel;
  final ValueChanged<PointerDownEvent> onContentAwarePointerDown;
  final ValueChanged<PointerEvent> onContentAwarePointerEnd;
  final bool Function() canUseContentAwarePointerStroke;
  final void Function(Offset localPosition, Size layerSize)
  onPhotoCloneSourceTap;
  final void Function(Offset localPosition, Size layerSize) onPhotoCloneStart;
  final void Function(Offset localPosition, Size layerSize) onPhotoCloneUpdate;
  final VoidCallback onPhotoCloneEnd;
  final VoidCallback onPhotoCloneCancel;
  final void Function(Offset localPosition, Size layerSize) onPhotoStretchStart;
  final void Function(Offset localPosition, Size layerSize)
  onPhotoStretchUpdate;
  final VoidCallback onPhotoStretchEnd;
  final VoidCallback onPhotoStretchCancel;
  final void Function(Offset localPosition, Size layerSize)
  onLayerMaskBrushStart;
  final void Function(Offset localPosition, Size layerSize)
  onLayerMaskBrushUpdate;
  final VoidCallback onLayerMaskBrushEnd;
  final VoidCallback onLayerMaskBrushCancel;
  final void Function(Offset localPosition, Size pageSize) onDrawBrushStart;
  final void Function(Offset localPosition, Size pageSize) onDrawBrushUpdate;
  final VoidCallback onDrawBrushEnd;
  final VoidCallback onDrawBrushCancel;
  final void Function(Offset localPosition, Rect pageRect, Size pageSize)
  onCanvasTapDown;
  final void Function(
    Offset globalPosition,
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  )
  onCanvasLongPressStart;
  final VoidCallback onCanvasTap;
  final bool routeCanvasGesturesToSelectedLayer;
  final bool showCanvasBackground;
  final double Function(_CanvasLayer layer) photoBrightnessForLayer;
  final double Function(_CanvasLayer layer) photoContrastForLayer;
  final double Function(_CanvasLayer layer) photoSaturationForLayer;
  final double Function(_CanvasLayer layer) photoBlurForLayer;
  final double Function(_CanvasLayer layer) photoSharpenForLayer;
  final double Function(_CanvasLayer layer) photoGrainForLayer;
  final double Function(_CanvasLayer layer) photoVignetteForLayer;
  final double Function(_CanvasLayer layer) photoMotionForLayer;
  final double Function(_CanvasLayer layer) photoTiltShiftForLayer;
  final double Function(_CanvasLayer layer) photoShadowsForLayer;
  final double Function(_CanvasLayer layer) photoHighlightsForLayer;
  final double Function(_CanvasLayer layer) photoTemperatureForLayer;
  final double Function(_CanvasLayer layer) photoTintForLayer;
  final bool showSelectionDecorations;
  final bool isLayerInteracting;
  final bool showPageFramePreview;
  final ValueListenable<_SnapGuideState> snapGuideListenable;
  final bool snapGuidesEnabled;
  final ValueListenable<_SelectedPhotoRenderState?>
  selectedPhotoRenderListenable;
  final ValueListenable<_PhotoEraserPreviewState?> eraserPreviewListenable;
  final ValueListenable<_StretchLivePreviewState?> stretchPreviewListenable;
  final ValueListenable<_DrawPreviewState?> drawPreviewListenable;
  final bool exportHighQuality;
  final bool preferFullWidthPage;
  final bool forceFullWidthPage;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final unselectedPhotoCacheWidth = exportHighQuality
        ? null
        : (canvasSize.width * devicePixelRatio * 1.5).round().clamp(720, 1600);
    final workspaceHeight = math.max(
      0.0,
      canvasSize.height - topInset - bottomInset,
    );
    final workspaceSize = Size(canvasSize.width, workspaceHeight);
    final hasPageSelection = pageAspectRatio != null;
    final showPageFrame =
        hasPageSelection && !hideAutoPageFrame && showPageFramePreview;
    final pageSize = hasPageSelection
        ? _fitPageSize(
            workspaceSize: workspaceSize,
            aspectRatio: pageAspectRatio!,
            preferFullWidth: preferFullWidthPage,
            forceFullWidth: forceFullWidthPage,
          )
        : workspaceSize;
    final pageRect = Rect.fromCenter(
      center: Offset(canvasSize.width / 2, topInset + (workspaceHeight / 2)),
      width: pageSize.width,
      height: pageSize.height,
    );
    final hasImageBorderTarget =
        borderStyle != _BorderStyle.none &&
        borderTargetLayerId != null &&
        layers.any((layer) => layer.id == borderTargetLayerId && layer.isPhoto);
    final applyStageBorder =
        borderStyle != _BorderStyle.none && !hasImageBorderTarget;
    final effectiveBorderWidth = borderWidth.clamp(0.5, 100).toDouble();
    final effectiveBorderRadius = borderRadius.clamp(0, 100).toDouble();
    final stageBorderRadius = effectiveBorderRadius;
    final stageBorderSide = switch (borderStyle) {
      _BorderStyle.thinWhite => BorderSide(
        color: Colors.white.withValues(alpha: 0.95),
        width: effectiveBorderWidth,
      ),
      _BorderStyle.thinBlack => BorderSide(
        color: const Color(0xE20F172A),
        width: effectiveBorderWidth,
      ),
      _BorderStyle.rounded => BorderSide(
        color: Colors.white.withValues(alpha: 0.8),
        width: effectiveBorderWidth,
      ),
      _BorderStyle.glow => BorderSide(
        color: const Color(0xFF60A5FA).withValues(alpha: 0.7),
        width: effectiveBorderWidth,
      ),
      _BorderStyle.custom => BorderSide(
        color: borderColor,
        width: effectiveBorderWidth,
      ),
      _BorderStyle.none => null,
    };
    final stageGlow = borderStyle == _BorderStyle.glow
        ? <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 1.2,
            ),
          ]
        : null;
    final resolvedBackgroundBlur = stageBackgroundImageBytes == null
        ? 0.0
        : backgroundBlurAmount.clamp(0, 100) / 6.5;
    final shouldShowTransparentCheckerboard =
        showTransparentCheckerboard &&
        showCanvasBackground &&
        stageBackgroundImageBytes == null &&
        canvasBackgroundGradientIndex < 0 &&
        canvasBackgroundColor.a <= 0.001;
    final visibleLayers = layers
        .where((layer) => !layer.isHidden)
        .toList(growable: false);
    final activeLayerBrushPointers = <int>{};
    var suppressLayerBrushStroke = false;

    void trackLayerBrushPointerDown(PointerDownEvent event) {
      activeLayerBrushPointers.add(event.pointer);
      if (isContentAwareMode) {
        onContentAwarePointerDown(event);
      }
      if (activeLayerBrushPointers.length > 1) {
        suppressLayerBrushStroke = true;
        if (isPhotoEraserMode) {
          onPhotoEraserCancel();
        } else if (isPhotoCloneMode) {
          onPhotoCloneCancel();
        } else if (isPhotoStretchMode) {
          onPhotoStretchCancel();
        } else if (isLayerMaskBrushMode) {
          onLayerMaskBrushCancel();
        }
      }
    }

    void trackLayerBrushPointerEnd(PointerEvent event) {
      activeLayerBrushPointers.remove(event.pointer);
      if (isContentAwareMode) {
        onContentAwarePointerEnd(event);
      }
      if (activeLayerBrushPointers.isEmpty) {
        suppressLayerBrushStroke = false;
      }
    }

    bool canUsePhotoEraserStroke() {
      return isPhotoEraserMode &&
          !suppressLayerBrushStroke &&
          activeLayerBrushPointers.length <= 1;
    }

    bool canUsePhotoStretchStroke() {
      return isPhotoStretchMode &&
          !suppressLayerBrushStroke &&
          activeLayerBrushPointers.length <= 1;
    }

    bool canUseContentAwareStroke() {
      return isContentAwareMode && canUseContentAwarePointerStroke();
    }

    bool canUsePhotoCloneStroke() {
      return isPhotoCloneMode &&
          !suppressLayerBrushStroke &&
          activeLayerBrushPointers.length <= 1;
    }

    bool canUseLayerMaskBrushStroke() {
      return isLayerMaskBrushMode &&
          !suppressLayerBrushStroke &&
          activeLayerBrushPointers.length <= 1;
    }

    final lockLayerSelectionForBrushTool =
        isPhotoEraserMode ||
        isContentAwareMode ||
        isPhotoCloneMode ||
        isPhotoStretchMode ||
        isLayerMaskBrushMode ||
        isDrawBrushMode;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: showCanvasBackground
            ? _editorCanvasBackdrop
            : Colors.transparent,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: isTextTypingScreenOpen || lockLayerSelectionForBrushTool
            ? null
            : (details) =>
                  onCanvasTapDown(details.localPosition, pageRect, pageSize),
        onScaleStart: routeCanvasGesturesToSelectedLayer
            ? onSelectedLayerInteractionStart
            : null,
        onScaleUpdate: routeCanvasGesturesToSelectedLayer
            ? onSelectedLayerScaleUpdate
            : null,
        onScaleEnd: routeCanvasGesturesToSelectedLayer
            ? (_) => onSelectedLayerInteractionEnd()
            : null,
        onLongPressStart: isTextTypingScreenOpen
            ? null
            : (details) => onCanvasLongPressStart(
                details.globalPosition,
                details.localPosition,
                pageRect,
                pageSize,
              ),
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                  child: ClipRect(
                    child: _EditorClippingStack(
                      children: <Widget>[
                        Center(
                          child: RepaintBoundary(
                            child: Container(
                              width: pageSize.width,
                              height: pageSize.height,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                gradient:
                                    stageBackgroundImageBytes == null &&
                                        canvasBackgroundGradientIndex >= 0 &&
                                        canvasBackgroundGradientIndex <
                                            editorBackgroundGradients.length &&
                                        showCanvasBackground
                                    ? LinearGradient(
                                        colors:
                                            editorBackgroundGradients[canvasBackgroundGradientIndex],
                                      )
                                    : null,
                                color: showCanvasBackground
                                    ? canvasBackgroundColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  applyStageBorder ? stageBorderRadius : 2,
                                ),
                                border: applyStageBorder
                                    ? (stageBorderSide == null
                                          ? null
                                          : Border.fromBorderSide(
                                              stageBorderSide,
                                            ))
                                    : showPageFrame && showCanvasBackground
                                    ? Border.all(
                                        color: const Color(0x331E293B),
                                        width: 1,
                                      )
                                    : null,
                                boxShadow: applyStageBorder ? stageGlow : null,
                              ),
                              child:
                                  stageBackgroundImageBytes != null &&
                                      showCanvasBackground
                                  ? SizedBox.expand(
                                      child: ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(
                                          sigmaX: resolvedBackgroundBlur,
                                          sigmaY: resolvedBackgroundBlur,
                                        ),
                                        child: Image.memory(
                                          stageBackgroundImageBytes!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                          filterQuality: isLayerInteracting
                                              ? FilterQuality.low
                                              : exportHighQuality
                                              ? FilterQuality.high
                                              : FilterQuality.medium,
                                        ),
                                      ),
                                    )
                                  : shouldShowTransparentCheckerboard
                                  ? const SizedBox.expand(
                                      child: CustomPaint(
                                        painter: _TransparentCheckerPainter(),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (visibleLayers.isNotEmpty)
                          ...visibleLayers.asMap().entries.map((entry) {
                            final visibleLayerIndex = entry.key;
                            final layer = entry.value;
                            final maskBaseChildIndex =
                                layer.clipsToLayerBelow && visibleLayerIndex > 0
                                ? visibleLayerIndex
                                : null;
                            final isSelected =
                                layer.id == selectedLayerId && !layer.isLocked;
                            final isBrushEditingLayer =
                                isSelected &&
                                (isPhotoEraserMode ||
                                    isContentAwareMode ||
                                    isPhotoCloneMode ||
                                    isPhotoStretchMode ||
                                    isLayerMaskBrushMode);
                            final layerSize = _workspaceLayerVisualSize(
                              layer,
                              pageSize,
                            );
                            final textSelectionBoxSize = layer.isText
                                ? _workspaceTextSelectionBoxSize(
                                    layer,
                                    pageSize,
                                  )
                                : Size.zero;
                            final textTapTargetSize = layer.isText
                                ? (isSelected
                                      ? Size(
                                          textSelectionBoxSize.width + 8,
                                          textSelectionBoxSize.height + 8,
                                        )
                                      : Size(
                                          layerSize.width + 56,
                                          layerSize.height + 36,
                                        ))
                                : layerSize;
                            final photoSize = layer.isPhoto
                                ? (layer.fillPageBounds
                                      ? pageSize
                                      : _photoLayerVisualSize(layer, pageSize))
                                : Size.zero;
                            final transformLayerSize = layer.isPhoto
                                ? photoSize
                                : layerSize;
                            final photoCacheWidth =
                                layer.isPhoto &&
                                    !exportHighQuality &&
                                    (!isSelected || isLayerInteracting)
                                ? (photoSize.width * devicePixelRatio)
                                      .round()
                                      .clamp(512, 2048)
                                : null;
                            final effectiveBrightness = layer.isPhoto
                                ? photoBrightnessForLayer(layer)
                                : 0.0;
                            final effectiveContrast = layer.isPhoto
                                ? photoContrastForLayer(layer)
                                : 1.0;
                            final effectiveSaturation = layer.isPhoto
                                ? photoSaturationForLayer(layer)
                                : 1.0;
                            final effectiveBlur = layer.isPhoto
                                ? photoBlurForLayer(layer)
                                : 0.0;
                            final effectiveSharpen = layer.isPhoto
                                ? photoSharpenForLayer(layer)
                                : 0.0;
                            final effectiveGrain = layer.isPhoto
                                ? photoGrainForLayer(layer)
                                : 0.0;
                            final effectiveVignette = layer.isPhoto
                                ? photoVignetteForLayer(layer)
                                : 0.0;
                            final effectiveMotion = layer.isPhoto
                                ? photoMotionForLayer(layer)
                                : 0.0;
                            final effectiveTiltShift = layer.isPhoto
                                ? photoTiltShiftForLayer(layer)
                                : 0.0;
                            final effectiveShadows = layer.isPhoto
                                ? photoShadowsForLayer(layer)
                                : 0.0;
                            final effectiveHighlights = layer.isPhoto
                                ? photoHighlightsForLayer(layer)
                                : 0.0;
                            final effectiveTemperature = layer.isPhoto
                                ? photoTemperatureForLayer(layer)
                                : 0.0;
                            final effectiveTint = layer.isPhoto
                                ? photoTintForLayer(layer)
                                : 0.0;
                            final blendOpacity = layer.isPhoto
                                ? layer.photoOpacity.clamp(0.0, 1.0).toDouble()
                                : 1.0;
                            Widget layerChild = layer.isPhoto
                                ? SizedBox(
                                    width: photoSize.width,
                                    height: photoSize.height,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        if (isSelected)
                                          ValueListenableBuilder<
                                            _SelectedPhotoRenderState?
                                          >(
                                            valueListenable:
                                                selectedPhotoRenderListenable,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  _SelectedPhotoRenderState?
                                                  renderState,
                                                  Widget? child,
                                                ) {
                                                  final resolvedState =
                                                      renderState != null &&
                                                          renderState.layerId ==
                                                              layer.id
                                                      ? renderState
                                                      : _SelectedPhotoRenderState(
                                                          layerId: layer.id,
                                                          bytes: layer.bytes!,
                                                          opacity: layer
                                                              .photoOpacity
                                                              .clamp(0.1, 1),
                                                          flipHorizontally: layer
                                                              .flipPhotoHorizontally,
                                                          flipVertically: layer
                                                              .flipPhotoVertically,
                                                          brightness:
                                                              effectiveBrightness,
                                                          contrast:
                                                              effectiveContrast,
                                                          saturation:
                                                              effectiveSaturation,
                                                          blur: effectiveBlur,
                                                          sharpen:
                                                              effectiveSharpen,
                                                          grain: effectiveGrain,
                                                          vignette:
                                                              effectiveVignette,
                                                          motion:
                                                              effectiveMotion,
                                                          tiltShift:
                                                              effectiveTiltShift,
                                                          shadows:
                                                              effectiveShadows,
                                                          highlights:
                                                              effectiveHighlights,
                                                          temperature:
                                                              effectiveTemperature,
                                                          tint: effectiveTint,
                                                        );
                                                  return Transform(
                                                    alignment: Alignment.center,
                                                    transform:
                                                        Matrix4.diagonal3Values(
                                                          resolvedState
                                                                  .flipHorizontally
                                                              ? -1
                                                              : 1,
                                                          resolvedState
                                                                  .flipVertically
                                                              ? -1
                                                              : 1,
                                                          1,
                                                        ),
                                                    child: _buildAdjustedPhoto(
                                                      bytes:
                                                          resolvedState.bytes,
                                                      cacheKey: resolvedState
                                                          .cacheKey,
                                                      cacheWidth:
                                                          photoCacheWidth,
                                                      highQuality:
                                                          exportHighQuality,
                                                      brightness: resolvedState
                                                          .brightness,
                                                      contrast: resolvedState
                                                          .contrast,
                                                      saturation: resolvedState
                                                          .saturation,
                                                      blur: resolvedState.blur,
                                                      sharpen:
                                                          resolvedState.sharpen,
                                                      grain:
                                                          resolvedState.grain,
                                                      vignette: resolvedState
                                                          .vignette,
                                                      motion:
                                                          resolvedState.motion,
                                                      tiltShift: resolvedState
                                                          .tiltShift,
                                                      shadows:
                                                          resolvedState.shadows,
                                                      highlights: resolvedState
                                                          .highlights,
                                                      temperature: resolvedState
                                                          .temperature,
                                                      tint: resolvedState.tint,
                                                    ),
                                                  );
                                                },
                                          )
                                        else
                                          Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.diagonal3Values(
                                              layer.flipPhotoHorizontally
                                                  ? -1
                                                  : 1,
                                              layer.flipPhotoVertically
                                                  ? -1
                                                  : 1,
                                              1,
                                            ),
                                            child: _buildAdjustedPhoto(
                                              bytes: layer.bytes!,
                                              cacheKey:
                                                  '${_photoBytesSignature(layer.bytes!)}_'
                                                  '${effectiveBrightness.toStringAsFixed(3)}_'
                                                  '${effectiveContrast.toStringAsFixed(3)}_'
                                                  '${effectiveSaturation.toStringAsFixed(3)}_'
                                                  '${effectiveBlur.toStringAsFixed(3)}_'
                                                  '${effectiveSharpen.toStringAsFixed(3)}_'
                                                  '${effectiveGrain.toStringAsFixed(3)}_'
                                                  '${effectiveVignette.toStringAsFixed(3)}_'
                                                  '${effectiveMotion.toStringAsFixed(3)}_'
                                                  '${effectiveTiltShift.toStringAsFixed(3)}_'
                                                  '${effectiveShadows.toStringAsFixed(3)}_'
                                                  '${effectiveHighlights.toStringAsFixed(3)}_'
                                                  '${effectiveTemperature.toStringAsFixed(3)}_'
                                                  '${effectiveTint.toStringAsFixed(3)}',
                                              cacheWidth: isSelected
                                                  ? photoCacheWidth
                                                  : photoCacheWidth ??
                                                        unselectedPhotoCacheWidth,
                                              highQuality: exportHighQuality,
                                              brightness: effectiveBrightness,
                                              contrast: effectiveContrast,
                                              saturation: effectiveSaturation,
                                              blur: effectiveBlur,
                                              sharpen: effectiveSharpen,
                                              grain: effectiveGrain,
                                              vignette: effectiveVignette,
                                              motion: effectiveMotion,
                                              tiltShift: effectiveTiltShift,
                                              shadows: effectiveShadows,
                                              highlights: effectiveHighlights,
                                              temperature: effectiveTemperature,
                                              tint: effectiveTint,
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : layer.isText
                                ? _CanvasTextLayerView(
                                    text: _resolveLayerRenderText(layer),
                                    textColor: _layerStyleTextColor(layer),
                                    textAlign: layer.textAlign,
                                    textOpacity: layer.textOpacity,
                                    fontFamily: _resolveLayerRenderFontFamily(
                                      layer,
                                    ),
                                    textLineHeight: layer.textLineHeight,
                                    textLetterSpacing: layer.textLetterSpacing,
                                    textShadowOpacity:
                                        _layerStyleTextShadowOpacity(layer),
                                    textShadowColor: _layerStyleTextShadowColor(
                                      layer,
                                    ),
                                    textShadowBlur: _layerStyleTextShadowBlur(
                                      layer,
                                    ),
                                    textShadowOffsetX:
                                        _layerStyleTextShadowOffset(layer).dx,
                                    textShadowOffsetY:
                                        _layerStyleTextShadowOffset(layer).dy,
                                    textOuterGlowColor:
                                        layer.layerStyleOuterGlowColor,
                                    textOuterGlowOpacity:
                                        layer.layerStyleOuterGlowOpacity,
                                    textOuterGlowSize:
                                        layer.layerStyleOuterGlowSize,
                                    textOuterGlowSpread:
                                        layer.layerStyleOuterGlowSpread,
                                    isTextBold: layer.isTextBold,
                                    isTextItalic: layer.isTextItalic,
                                    isTextUnderline: layer.isTextUnderline,
                                    textStrokeColor:
                                        layer.layerStyleStrokeWidth > 0.001
                                        ? layer.layerStyleStrokeColor
                                              .withValues(
                                                alpha: layer
                                                    .layerStyleStrokeOpacity
                                                    .clamp(0.0, 1.0),
                                              )
                                        : layer.textStrokeColor,
                                    textStrokeWidth: math.max(
                                      layer.textStrokeWidth,
                                      layer.layerStyleStrokeWidth,
                                    ),
                                    textStrokeGradient:
                                        layer.textStrokeGradientIndex >= 0 &&
                                            layer.textStrokeGradientIndex <
                                                _textGradients.length
                                        ? _textGradients[layer
                                              .textStrokeGradientIndex]
                                        : null,
                                    textBackgroundColor:
                                        layer.textBackgroundColor,
                                    textBackgroundOpacity:
                                        layer.textBackgroundOpacity,
                                    textBackgroundRadius:
                                        layer.textBackgroundRadius,
                                    textBackgroundTopPadding:
                                        layer.textBackgroundTopPadding,
                                    textBackgroundBottomPadding:
                                        layer.textBackgroundBottomPadding,
                                    maxWidth: layer.isParagraphText
                                        ? pageSize.width * 0.9
                                        : null,
                                    textGradient: _layerStyleTextGradient(
                                      layer,
                                      _textGradients,
                                    ),
                                    textGradientAngle:
                                        layer.layerStyleGradientOverlayEnabled
                                        ? layer.layerStyleGradientOverlayAngle
                                        : 0,
                                    textGradientScale:
                                        layer.layerStyleGradientOverlayEnabled
                                        ? layer.layerStyleGradientOverlayScale
                                        : 100,
                                    fontSize: layer.fontSize,
                                  )
                                : Text(
                                    layer.sticker ?? '?',
                                    style: TextStyle(fontSize: layer.fontSize),
                                  );
                            if (layer.isPhoto &&
                                (layer.photoPerspectiveX.abs() > 0.001 ||
                                    layer.photoPerspectiveY.abs() > 0.001)) {
                              double perspectiveStrength(double value) {
                                final normalized =
                                    (value.clamp(-100.0, 100.0).toDouble() /
                                            100)
                                        .clamp(-1.0, 1.0)
                                        .toDouble();
                                if (normalized.abs() < 0.0001) {
                                  return 0;
                                }
                                return normalized.sign *
                                    math.pow(normalized.abs(), 0.72).toDouble();
                              }

                              final horizontalStrength = perspectiveStrength(
                                layer.photoPerspectiveX,
                              );
                              final verticalStrength = perspectiveStrength(
                                layer.photoPerspectiveY,
                              );
                              final perspectiveDepth =
                                  0.0018 +
                                  (math.max(
                                        horizontalStrength.abs(),
                                        verticalStrength.abs(),
                                      ) *
                                      0.0022);
                              final horizontalRadians =
                                  horizontalStrength * (math.pi / 3.25);
                              final verticalRadians =
                                  verticalStrength * (math.pi / 3.25);
                              layerChild = Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, perspectiveDepth)
                                  ..rotateX(verticalRadians)
                                  ..rotateY(-horizontalRadians),
                                filterQuality: isLayerInteracting
                                    ? FilterQuality.low
                                    : FilterQuality.high,
                                child: layerChild,
                              );
                            }
                            if (layer.isPhoto &&
                                layer.photoMaskShape.trim().isNotEmpty) {
                              layerChild = _EditorPhotoMaskFrame(
                                shape: layer.photoMaskShape,
                                scale: layer.photoMaskScale,
                                offsetX: layer.photoMaskOffsetX,
                                offsetY: layer.photoMaskOffsetY,
                                feather: layer.photoMaskFeather,
                                child: layerChild,
                              );
                            }
                            if (layer.layerMaskEnabled &&
                                (layer.layerMaskShape.trim().isNotEmpty ||
                                    layer.layerMaskBrushStrokes.isNotEmpty)) {
                              layerChild = _EditorLayerMaskFrame(
                                shape: layer.layerMaskShape,
                                inverted: layer.layerMaskInverted,
                                feather: layer.layerMaskFeather,
                                brushStrokes: layer.layerMaskBrushStrokes,
                                child: layerChild,
                              );
                            }
                            if (layer.isPhoto &&
                                layer.photoShadowOpacity > 0.001) {
                              layerChild = DecoratedBox(
                                decoration: BoxDecoration(
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: layer.photoShadowColor.withValues(
                                        alpha: layer.photoShadowOpacity
                                            .clamp(0.0, 1.0)
                                            .toDouble(),
                                      ),
                                      blurRadius: layer.photoShadowBlur
                                          .clamp(0.0, 100.0)
                                          .toDouble(),
                                      offset: Offset(
                                        0,
                                        layer.photoShadowOffsetY
                                            .clamp(-100.0, 100.0)
                                            .toDouble(),
                                      ),
                                    ),
                                  ],
                                ),
                                child: layerChild,
                              );
                            }
                            if (layer.isPhoto &&
                                borderStyle != _BorderStyle.none &&
                                layer.id == borderTargetLayerId) {
                              final borderRadius = effectiveBorderRadius;
                              final borderSide = switch (borderStyle) {
                                _BorderStyle.thinWhite => BorderSide(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  width: effectiveBorderWidth,
                                ),
                                _BorderStyle.thinBlack => BorderSide(
                                  color: const Color(0xE20F172A),
                                  width: effectiveBorderWidth,
                                ),
                                _BorderStyle.rounded => BorderSide(
                                  color: Colors.white.withValues(alpha: 0.84),
                                  width: effectiveBorderWidth,
                                ),
                                _BorderStyle.glow => BorderSide(
                                  color: const Color(
                                    0xFF60A5FA,
                                  ).withValues(alpha: 0.75),
                                  width: effectiveBorderWidth,
                                ),
                                _BorderStyle.custom => BorderSide(
                                  color: borderColor,
                                  width: effectiveBorderWidth,
                                ),
                                _BorderStyle.none => BorderSide.none,
                              };
                              final glowShadow =
                                  borderStyle == _BorderStyle.glow
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: const Color(
                                          0xFF60A5FA,
                                        ).withValues(alpha: 0.38),
                                        blurRadius: 20,
                                        spreadRadius: 1.3,
                                      ),
                                    ]
                                  : null;
                              layerChild = DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                  border: Border.fromBorderSide(borderSide),
                                  boxShadow: glowShadow,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                  child: layerChild,
                                ),
                              );
                            }
                            final stickerAsset =
                                _EditorTextState._isImageLikeSticker(
                                  layer.sticker,
                                );
                            final stickerOrTextChild =
                                layer.isSticker && stickerAsset
                                ? SizedBox(
                                    width: layerSize.width,
                                    height: layerSize.height,
                                    child: _EditorTextState._buildStickerVisual(
                                      layer.sticker,
                                      fontSize: layer.fontSize,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  )
                                : layer.isSticker
                                ? DefaultTextStyle.merge(
                                    style: TextStyle(color: layer.stickerColor),
                                    child: layerChild,
                                  )
                                : layerChild;
                            final stretchAwareLayerChild = layer.isPhoto
                                ? ValueListenableBuilder<
                                    _StretchLivePreviewState?
                                  >(
                                    valueListenable: stretchPreviewListenable,
                                    builder: (context, stretchPreview, child) {
                                      if (stretchPreview == null ||
                                          stretchPreview.layerId != layer.id ||
                                          stretchPreview.strokes.isEmpty) {
                                        return child ?? stickerOrTextChild;
                                      }
                                      return SizedBox(
                                        width: transformLayerSize.width,
                                        height: transformLayerSize.height,
                                        child: CustomPaint(
                                          painter: _StretchMeshPainter(
                                            image: stretchPreview.image,
                                            strokes: stretchPreview.strokes,
                                            displayScale:
                                                1 /
                                                math.max(0.1, viewportScale),
                                          ),
                                          size: Size.infinite,
                                        ),
                                      );
                                    },
                                    child: stickerOrTextChild,
                                  )
                                : stickerOrTextChild;
                            final contentLayerChild =
                                _EditorUniversalLayerStyle(
                                  key: ValueKey<String>(
                                    _layerStyleVisualSignature(layer),
                                  ),
                                  overlayColor: layer.layerStyleOverlayColor,
                                  overlayOpacity: layer.isText
                                      ? 0
                                      : layer.layerStyleOverlayOpacity,
                                  strokeColor: layer.layerStyleStrokeColor,
                                  strokeWidth: layer.isText
                                      ? 0
                                      : layer.layerStyleStrokeWidth,
                                  shadowColor: layer.layerStyleShadowColor,
                                  shadowOpacity: layer.isText
                                      ? 0
                                      : layer.layerStyleShadowOpacity,
                                  shadowBlur: layer.layerStyleShadowBlur,
                                  shadowSpread: layer.layerStyleShadowSpread,
                                  shadowOffset: Offset(
                                    layer.layerStyleShadowOffsetX,
                                    layer.layerStyleShadowOffsetY,
                                  ),
                                  strokeOpacity: layer.layerStyleStrokeOpacity,
                                  innerShadowColor:
                                      layer.layerStyleInnerShadowColor,
                                  innerShadowOpacity: layer.isText
                                      ? 0
                                      : layer.layerStyleInnerShadowOpacity,
                                  innerShadowBlur:
                                      layer.layerStyleInnerShadowBlur,
                                  innerShadowChoke:
                                      layer.layerStyleInnerShadowChoke,
                                  innerShadowDistance:
                                      layer.layerStyleInnerShadowDistance,
                                  innerShadowAngle:
                                      layer.layerStyleInnerShadowAngle,
                                  gradientOverlayEnabled: layer.isText
                                      ? false
                                      : layer.layerStyleGradientOverlayEnabled,
                                  gradientOverlayColors:
                                      layer.layerStyleGradientOverlayIndex >=
                                              0 &&
                                          layer.layerStyleGradientOverlayIndex <
                                              _textGradients.length
                                      ? _textGradients[layer
                                            .layerStyleGradientOverlayIndex]
                                      : const <Color>[
                                          Color(0xFFFFFFFF),
                                          Color(0xFF000000),
                                        ],
                                  gradientOverlayOpacity:
                                      layer.layerStyleGradientOverlayOpacity,
                                  gradientOverlayAngle:
                                      layer.layerStyleGradientOverlayAngle,
                                  gradientOverlayScale:
                                      layer.layerStyleGradientOverlayScale,
                                  gradientOverlayReversed:
                                      layer.layerStyleGradientOverlayReversed,
                                  outerGlowColor:
                                      layer.layerStyleOuterGlowColor,
                                  outerGlowOpacity: layer.isText
                                      ? 0
                                      : layer.layerStyleOuterGlowOpacity,
                                  outerGlowSize: layer.layerStyleOuterGlowSize,
                                  outerGlowSpread:
                                      layer.layerStyleOuterGlowSpread,
                                  child: stretchAwareLayerChild,
                                );

                            final decoratedChild = contentLayerChild;
                            final effectiveTextChild = layer.isText
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: decoratedChild,
                                  )
                                : decoratedChild;
                            final unselectedInteractiveChild = layer.isPhoto
                                ? SizedBox(
                                    width: transformLayerSize.width,
                                    height: transformLayerSize.height,
                                    child: contentLayerChild,
                                  )
                                : layer.isText
                                ? SizedBox(
                                    width: textTapTargetSize.width,
                                    height: textTapTargetSize.height,
                                    child: OverflowBox(
                                      alignment: Alignment.center,
                                      minWidth: 0,
                                      minHeight: 0,
                                      maxWidth: double.infinity,
                                      maxHeight: double.infinity,
                                      child: effectiveTextChild,
                                    ),
                                  )
                                : layer.isSticker
                                ? SizedBox(
                                    width: layerSize.width,
                                    height: layerSize.height,
                                    child: Center(child: contentLayerChild),
                                  )
                                : contentLayerChild;

                            Widget child = isSelected
                                ? (layer.isPhoto || layer.isSticker)
                                      ? SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: ValueListenableBuilder<Matrix4>(
                                            valueListenable:
                                                transformationController,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  Matrix4 matrix,
                                                  Widget? child,
                                                ) {
                                                  return Stack(
                                                    clipBehavior: Clip.none,
                                                    children: <Widget>[
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        width: pageSize.width,
                                                        height: pageSize.height,
                                                        child: ClipRect(
                                                          child: _EditorBlendLayer(
                                                            blendMode:
                                                                layer.blendMode,
                                                            opacity:
                                                                blendOpacity,
                                                            child: Center(
                                                              child: Transform(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                transform:
                                                                    matrix,
                                                                child: SizedBox(
                                                                  width:
                                                                      transformLayerSize
                                                                          .width,
                                                                  height:
                                                                      transformLayerSize
                                                                          .height,
                                                                  child: Stack(
                                                                    clipBehavior:
                                                                        Clip.none,
                                                                    fit: StackFit
                                                                        .expand,
                                                                    children: <Widget>[
                                                                      Listener(
                                                                        behavior:
                                                                            HitTestBehavior.translucent,
                                                                        onPointerDown:
                                                                            (isPhotoEraserMode ||
                                                                                isContentAwareMode ||
                                                                                isPhotoCloneMode ||
                                                                                isPhotoStretchMode ||
                                                                                isLayerMaskBrushMode)
                                                                            ? trackLayerBrushPointerDown
                                                                            : null,
                                                                        onPointerUp:
                                                                            (isPhotoEraserMode ||
                                                                                isContentAwareMode ||
                                                                                isPhotoCloneMode ||
                                                                                isPhotoStretchMode ||
                                                                                isLayerMaskBrushMode)
                                                                            ? trackLayerBrushPointerEnd
                                                                            : null,
                                                                        onPointerCancel:
                                                                            (isPhotoEraserMode ||
                                                                                isContentAwareMode ||
                                                                                isPhotoCloneMode ||
                                                                                isPhotoStretchMode ||
                                                                                isLayerMaskBrushMode)
                                                                            ? trackLayerBrushPointerEnd
                                                                            : null,
                                                                        child: GestureDetector(
                                                                          behavior:
                                                                              HitTestBehavior.translucent,
                                                                          onDoubleTap:
                                                                              isBrushEditingLayer
                                                                              ? null
                                                                              : onSelectedLayerDoubleTap,
                                                                          onPanDown:
                                                                              isPhotoEraserMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUsePhotoEraserStroke()) {
                                                                                    onPhotoEraserStart(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isContentAwareMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUseContentAwareStroke()) {
                                                                                    onContentAwareStart(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isPhotoStretchMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUsePhotoStretchStroke()) {
                                                                                    onPhotoStretchStart(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isLayerMaskBrushMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUseLayerMaskBrushStroke()) {
                                                                                    onLayerMaskBrushStart(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : null,
                                                                          onTapUp:
                                                                              isPhotoCloneMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUsePhotoCloneStroke()) {
                                                                                    onPhotoCloneSourceTap(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isContentAwareMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUseContentAwareStroke()) {
                                                                                    onContentAwareStart(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                    onContentAwareEnd();
                                                                                  }
                                                                                }
                                                                              : null,
                                                                          onPanStart:
                                                                              isPhotoCloneMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUsePhotoCloneStroke()) {
                                                                                    onPhotoCloneStart(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : null,
                                                                          onPanUpdate:
                                                                              isPhotoEraserMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUsePhotoEraserStroke()) {
                                                                                    onPhotoEraserUpdate(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isContentAwareMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUseContentAwareStroke()) {
                                                                                    onContentAwareUpdate(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isPhotoStretchMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUsePhotoStretchStroke()) {
                                                                                    onPhotoStretchUpdate(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isPhotoCloneMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUsePhotoCloneStroke()) {
                                                                                    onPhotoCloneUpdate(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : isLayerMaskBrushMode
                                                                              ? (
                                                                                  details,
                                                                                ) {
                                                                                  if (canUseLayerMaskBrushStroke()) {
                                                                                    onLayerMaskBrushUpdate(
                                                                                      details.localPosition,
                                                                                      transformLayerSize,
                                                                                    );
                                                                                  }
                                                                                }
                                                                              : null,
                                                                          onPanEnd:
                                                                              isPhotoEraserMode
                                                                              ? (
                                                                                  _,
                                                                                ) => onPhotoEraserEnd()
                                                                              : isContentAwareMode
                                                                              ? (
                                                                                  _,
                                                                                ) => onContentAwareEnd()
                                                                              : isPhotoCloneMode
                                                                              ? (
                                                                                  _,
                                                                                ) => onPhotoCloneEnd()
                                                                              : isPhotoStretchMode
                                                                              ? (
                                                                                  _,
                                                                                ) => onPhotoStretchEnd()
                                                                              : isLayerMaskBrushMode
                                                                              ? (
                                                                                  _,
                                                                                ) => onLayerMaskBrushEnd()
                                                                              : null,
                                                                          onPanCancel:
                                                                              isPhotoEraserMode
                                                                              ? onPhotoEraserCancel
                                                                              : isContentAwareMode
                                                                              ? onContentAwareCancel
                                                                              : isPhotoCloneMode
                                                                              ? onPhotoCloneCancel
                                                                              : isPhotoStretchMode
                                                                              ? onPhotoStretchCancel
                                                                              : isLayerMaskBrushMode
                                                                              ? onLayerMaskBrushCancel
                                                                              : null,
                                                                          onScaleStart:
                                                                              isBrushEditingLayer
                                                                              ? null
                                                                              : onSelectedLayerInteractionStart,
                                                                          onScaleUpdate:
                                                                              isBrushEditingLayer
                                                                              ? null
                                                                              : onSelectedLayerScaleUpdate,
                                                                          onScaleEnd:
                                                                              isBrushEditingLayer
                                                                              ? null
                                                                              : (_) => onSelectedLayerInteractionEnd(),
                                                                          child: _EraserPreviewLayer(
                                                                            layerId:
                                                                                layer.id,
                                                                            previewListenable:
                                                                                eraserPreviewListenable,
                                                                            brushScale:
                                                                                isPhotoStretchMode ||
                                                                                    isContentAwareMode ||
                                                                                    isPhotoCloneMode ||
                                                                                    isPhotoEraserMode ||
                                                                                    isLayerMaskBrushMode
                                                                                ? 1 /
                                                                                      math.max(
                                                                                        0.1,
                                                                                        viewportScale,
                                                                                      )
                                                                                : 1,
                                                                            child:
                                                                                contentLayerChild,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                          ),
                                        )
                                      : layer.isText
                                      ? SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: ValueListenableBuilder<Matrix4>(
                                            valueListenable:
                                                transformationController,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  Matrix4 matrix,
                                                  Widget? child,
                                                ) {
                                                  return Stack(
                                                    clipBehavior: Clip.none,
                                                    children: <Widget>[
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        width: pageSize.width,
                                                        height: pageSize.height,
                                                        child: ClipRect(
                                                          child: _EditorBlendLayer(
                                                            blendMode:
                                                                layer.blendMode,
                                                            opacity:
                                                                blendOpacity,
                                                            child: Center(
                                                              child: Transform(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                transform:
                                                                    matrix,
                                                                child: SizedBox(
                                                                  width:
                                                                      textTapTargetSize
                                                                          .width,
                                                                  height:
                                                                      textTapTargetSize
                                                                          .height,
                                                                  child: Listener(
                                                                    onPointerDown:
                                                                        onSelectedTextPointerDown,
                                                                    onPointerMove:
                                                                        onSelectedTextPointerMove,
                                                                    onPointerUp:
                                                                        (_) =>
                                                                            onSelectedTextPointerCancel(),
                                                                    onPointerCancel:
                                                                        (_) =>
                                                                            onSelectedTextPointerCancel(),
                                                                    child: GestureDetector(
                                                                      behavior:
                                                                          HitTestBehavior
                                                                              .opaque,
                                                                      onTapUp:
                                                                          (_) =>
                                                                              onSelectedTextTap(),
                                                                      onDoubleTap:
                                                                          onSelectedTextDoubleTap,
                                                                      onScaleStart:
                                                                          onSelectedLayerInteractionStart,
                                                                      onScaleUpdate:
                                                                          onSelectedLayerScaleUpdate,
                                                                      onScaleEnd:
                                                                          (_) =>
                                                                              onSelectedLayerInteractionEnd(),
                                                                      child: OverflowBox(
                                                                        alignment:
                                                                            Alignment.center,
                                                                        minWidth:
                                                                            0,
                                                                        minHeight:
                                                                            0,
                                                                        maxWidth:
                                                                            double.infinity,
                                                                        maxHeight:
                                                                            double.infinity,
                                                                        child:
                                                                            effectiveTextChild,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                          ),
                                        )
                                      : SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onDoubleTap:
                                                onSelectedLayerDoubleTap,
                                            child: InteractiveViewer(
                                              transformationController:
                                                  transformationController,
                                              minScale: 0.2,
                                              maxScale: 8.0,
                                              panEnabled: true,
                                              scaleEnabled: true,
                                              constrained: false,
                                              clipBehavior: Clip.hardEdge,
                                              boundaryMargin:
                                                  const EdgeInsets.all(2400),
                                              onInteractionStart:
                                                  onSelectedLayerInteractionStart,
                                              onInteractionUpdate:
                                                  onSelectedLayerScaleUpdate,
                                              onInteractionEnd: (_) =>
                                                  onSelectedLayerInteractionEnd(),
                                              child: Center(
                                                child: decoratedChild,
                                              ),
                                            ),
                                          ),
                                        )
                                : ClipRect(
                                    child: _EditorBlendLayer(
                                      blendMode: layer.blendMode,
                                      opacity: blendOpacity,
                                      child: SizedBox(
                                        width: pageSize.width,
                                        height: pageSize.height,
                                        child: Center(
                                          child: layer.isText
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10,
                                                      ),
                                                  child: Transform(
                                                    alignment: Alignment.center,
                                                    transform: layer.transform,
                                                    child:
                                                        unselectedInteractiveChild,
                                                  ),
                                                )
                                              : Transform(
                                                  alignment: Alignment.center,
                                                  transform: layer.transform,
                                                  child:
                                                      unselectedInteractiveChild,
                                                ),
                                        ),
                                      ),
                                    ),
                                  );

                            return _EditorClippingLayer(
                              maskBaseChildIndex: maskBaseChildIndex,
                              child: Center(
                                child: layer.isLocked
                                    ? IgnorePointer(child: child)
                                    : child,
                              ),
                            );
                          }),
                        if (showSelectionDecorations)
                          _buildDetachedSelectionOverlay(
                            visibleLayers: visibleLayers,
                            pageRect: pageRect,
                            pageSize: pageSize,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isDrawBrushMode)
                Positioned(
                  left: pageRect.left,
                  top: pageRect.top,
                  width: pageSize.width,
                  height: pageSize.height,
                  child: _DrawCanvasLiveOverlay(
                    pageSize: pageSize,
                    previewListenable: drawPreviewListenable,
                    onStart: onDrawBrushStart,
                    onUpdate: onDrawBrushUpdate,
                    onEnd: onDrawBrushEnd,
                    onCancel: onDrawBrushCancel,
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: topInset,
                      bottom: bottomInset,
                    ),
                    child: ValueListenableBuilder<_SnapGuideState>(
                      valueListenable: snapGuideListenable,
                      builder:
                          (
                            BuildContext context,
                            _SnapGuideState snapGuides,
                            Widget? child,
                          ) {
                            return RepaintBoundary(
                              child: CustomPaint(
                                painter: _SnapGuidesPainter(
                                  showVerticalGuide:
                                      snapGuidesEnabled &&
                                      snapGuides.showVerticalGuide,
                                  showHorizontalGuide:
                                      snapGuidesEnabled &&
                                      snapGuides.showHorizontalGuide,
                                  rotationGuideAngle: snapGuidesEnabled
                                      ? snapGuides.rotationGuideAngle
                                      : null,
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    /*
    final background = canvasBackgroundGradientIndex >= 0 &&
            canvasBackgroundGradientIndex <
                editorBackgroundGradients.length
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: editorBackgroundGradients[canvasBackgroundGradientIndex],
            ),
          )
        : BoxDecoration(color: canvasBackgroundColor);

    return DecoratedBox(
      decoration: background,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onCanvasTap,
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
          if (layers.isEmpty)
            Center(
              child: Text(
                'Canvas Area',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
            )
          else
            ...layers.map((layer) {
              final isSelected = layer.id == selectedLayerId;
              final layerChild = layer.isPhoto
                  ? Image.memory(
                      layer.bytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      cacheWidth: isSelected ? null : unselectedPhotoCacheWidth,
                    )
                  : layer.isText
                      ? _CanvasTextLayerView(
                          text: _resolveLayerRenderText(layer),
                          textColor: layer.textColor,
                          textAlign: layer.textAlign,
                          fontSize: layer.fontSize,
                          textOpacity: layer.textOpacity,
                          fontFamily: _resolveLayerRenderFontFamily(layer),
                          textLineHeight: layer.textLineHeight,
                          textLetterSpacing: layer.textLetterSpacing,
                          textShadowOpacity: layer.textShadowOpacity,
                          textShadowColor: layer.textShadowColor,
                          textShadowBlur: layer.textShadowBlur,
                          textShadowOffsetY: layer.textShadowOffsetY,
                          isTextBold: layer.isTextBold,
                          isTextItalic: layer.isTextItalic,
                          isTextUnderline: layer.isTextUnderline,
                          textStrokeColor: layer.textStrokeColor,
                          textStrokeWidth: layer.textStrokeWidth,
                          textStrokeGradient:
                              layer.textStrokeGradientIndex >= 0 &&
                                  layer.textStrokeGradientIndex <
                                      _textGradients.length
                              ? _textGradients[layer.textStrokeGradientIndex]
                              : null,
                          textBackgroundColor: layer.textBackgroundColor,
                          textBackgroundOpacity: layer.textBackgroundOpacity,
                          textBackgroundRadius: layer.textBackgroundRadius,
                          textBackgroundTopPadding:
                              layer.textBackgroundTopPadding,
                          textBackgroundBottomPadding:
                              layer.textBackgroundBottomPadding,
                          textGradient: layer.textGradientIndex >= 0 &&
                                  layer.textGradientIndex <
                                      _textGradients.length
                              ? _textGradients[layer.textGradientIndex]
                              : null,
                        )
                      : Text(
                          layer.sticker ?? '⭐',
                          style: TextStyle(fontSize: layer.fontSize),
                        );

              final child = isSelected
                  ? InteractiveViewer(
                      transformationController: transformationController,
                      minScale: 1,
                      maxScale: layer.isPhoto || layer.isSticker ? 5 : 1,
                      scaleEnabled: layer.isPhoto || layer.isSticker,
                      constrained: false,
                      clipBehavior: Clip.none,
                      boundaryMargin: const EdgeInsets.all(240),
                      onInteractionUpdate: (_) => onSelectedLayerInteractionUpdate(),
                      onInteractionEnd: (_) => onSelectedLayerInteractionEnd(),
                      child: showSelectionDecorations
                          ? _EditorExcludeFromClipMask(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.9),
                                    width: 1.5,
                                  ),
                                ),
                                child: layerChild,
                              ),
                            )
                          : layerChild,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: layer.transform,
                      child: layerChild,
                    );

              return Center(
                child: isSelected || lockLayerSelectionForBrushTool
                    ? child
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onLayerSelected(layer.id),
                        child: child,
                      ),
              );
            }),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                child: CustomPaint(
                  painter: _SnapGuidesPainter(
                    showVerticalGuide: showVerticalSnapGuide,
                    showHorizontalGuide: showHorizontalSnapGuide,
                    rotationGuideAngle: null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
*/
  }

  Widget _buildDetachedSelectionOverlay({
    required List<_CanvasLayer> visibleLayers,
    required Rect pageRect,
    required Size pageSize,
  }) {
    _CanvasLayer? selectedLayer;
    for (final layer in visibleLayers) {
      if (layer.id == selectedLayerId && !layer.isLocked) {
        selectedLayer = layer;
        break;
      }
    }
    final layer = selectedLayer;
    if (layer == null ||
        (!layer.isPhoto && !layer.isSticker && !layer.isText) ||
        (layer.isText && isTextTypingScreenOpen)) {
      return const SizedBox.shrink();
    }

    final layerSize = _workspaceLayerVisualSize(layer, pageSize);
    final photoSize = layer.isPhoto
        ? (layer.fillPageBounds
              ? pageSize
              : _photoLayerVisualSize(layer, pageSize))
        : Size.zero;
    final transformLayerSize = layer.isPhoto ? photoSize : layerSize;
    final photoPaintRect = layer.isPhoto
        ? _photoVisiblePaintRect(layer, photoSize)
        : Rect.zero;
    final textSelectionBoxSize = layer.isText
        ? _workspaceTextSelectionBoxSize(layer, pageSize)
        : Size.zero;

    final pageOrigin = Offset(pageRect.left, pageRect.top - topInset);
    return Positioned.fill(
      child: ValueListenableBuilder<Matrix4>(
        valueListenable: transformationController,
        builder: (BuildContext context, Matrix4 matrix, Widget? child) {
          if (layer.isText) {
            return _LayerSelectionBoxOverlay(
              pageSize: pageSize,
              pageOrigin: pageOrigin,
              matrix: matrix,
              viewportScale: viewportScale,
              layerSize: textSelectionBoxSize,
              centerOffset: _workspaceTextSelectionCenterOffset(
                layer,
                pageSize,
              ),
              highlightPageOverflow: true,
              showTopStretchHandle: true,
              showSideResizeHandles: true,
              onPointerDown: onSelectedTransformHandlePointerDown,
              onResizePanStart: onSelectedTextResizeHandleStart,
              onResizePanUpdate: onSelectedTextResizeHandleUpdate,
              onHorizontalSidePanStart:
                  onSelectedObjectHorizontalResizeHandleStart,
              onHorizontalSidePanUpdate:
                  onSelectedObjectHorizontalResizeHandleUpdate,
              onVerticalSidePanStart: onSelectedObjectVerticalResizeHandleStart,
              onVerticalSidePanUpdate:
                  onSelectedObjectVerticalResizeHandleUpdate,
              onRotatePanStart: onSelectedTextRotateHandleStart,
              onRotatePanUpdate: onSelectedTextRotateHandleUpdate,
              onTopPanStart: onSelectedTextStretchHandleStart,
              onTopPanUpdate: onSelectedTextStretchHandleUpdate,
              onPanEnd: (_) => onSelectedStickerHandleEnd(),
            );
          }
          return _LayerSelectionBoxOverlay(
            pageSize: pageSize,
            pageOrigin: pageOrigin,
            matrix: matrix,
            viewportScale: viewportScale,
            layerSize: layer.isPhoto ? photoPaintRect.size : transformLayerSize,
            centerOffset: layer.isPhoto
                ? (photoPaintRect.center -
                      Offset(
                        transformLayerSize.width / 2,
                        transformLayerSize.height / 2,
                      ))
                : Offset.zero,
            showTopStretchHandle: false,
            showSideResizeHandles: true,
            onPointerDown: onSelectedTransformHandlePointerDown,
            onResizePanStart: onSelectedStickerHandleStart,
            onResizePanUpdate: onSelectedStickerHandleUpdate,
            onHorizontalSidePanStart:
                onSelectedObjectHorizontalResizeHandleStart,
            onHorizontalSidePanUpdate:
                onSelectedObjectHorizontalResizeHandleUpdate,
            onVerticalSidePanStart: onSelectedObjectVerticalResizeHandleStart,
            onVerticalSidePanUpdate: onSelectedObjectVerticalResizeHandleUpdate,
            onRotatePanStart: onSelectedStickerRotateHandleStart,
            onRotatePanUpdate: onSelectedStickerRotateHandleUpdate,
            onTopPanStart: onSelectedStickerHandleStart,
            onTopPanUpdate: onSelectedStickerHandleUpdate,
            onPanEnd: (_) => onSelectedStickerHandleEnd(),
          );
        },
      ),
    );
  }
}

class _EraserPreviewLayer extends StatelessWidget {
  const _EraserPreviewLayer({
    required this.layerId,
    required this.previewListenable,
    required this.brushScale,
    required this.child,
  });

  final String layerId;
  final ValueListenable<_PhotoEraserPreviewState?> previewListenable;
  final double brushScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_PhotoEraserPreviewState?>(
      valueListenable: previewListenable,
      child: child,
      builder: (context, preview, child) {
        final activePreview = preview != null && preview.layerId == layerId
            ? preview
            : null;
        return CustomPaint(
          foregroundPainter: activePreview == null
              ? null
              : _PhotoEraserPreviewPainter(
                  activePreview,
                  brushScale: brushScale,
                ),
          child: child,
        );
      },
    );
  }
}

class _PhotoEraserPreviewPainter extends CustomPainter {
  const _PhotoEraserPreviewPainter(this.preview, {required this.brushScale});

  final _PhotoEraserPreviewState preview;
  final double brushScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (preview.points.isEmpty || size.isEmpty) {
      return;
    }
    final radius = math.max(0.0001, (preview.brushSize / 2) * brushScale);
    final hardness = preview.hardness.clamp(0.0, 1.0).toDouble();
    final hardStop = _editorRoundBrushHardRadiusFactor(hardness);
    final cloneImage = preview.cloneSourceImage;
    final cloneSampleOffset = preview.cloneSampleOffset;

    void drawStrokePreview() {
      final strokePoints = preview.strokePreviewPoints;
      if (strokePoints == null || strokePoints.isEmpty) {
        return;
      }
      final isErasePreview = preview.effect == _PhotoBrushPreviewEffect.erase;
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = radius * 2
        ..color =
            (isErasePreview ? const Color(0xFFEF4444) : const Color(0xFFFFFFFF))
                .withValues(
                  alpha: preview.strokePreviewOpacity.clamp(0.0, 0.42),
                );
      final outlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1.0, 1.2 * brushScale)
        ..color = const Color(0xFF0F172A).withValues(alpha: 0.38);
      final path = Path();
      for (var index = 0; index < strokePoints.length; index++) {
        final point = Offset(
          strokePoints[index].dx * size.width,
          strokePoints[index].dy * size.height,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, strokePaint);
      canvas.drawPath(path, outlinePaint);
    }

    if (cloneImage != null && cloneSampleOffset != null) {
      final cloneOpacity = preview.cloneOpacity.clamp(0.0, 1.0).toDouble();
      final layerBounds = Rect.fromLTWH(0, 0, size.width, size.height);
      final offsetPixels = Offset(
        cloneSampleOffset.dx * size.width,
        cloneSampleOffset.dy * size.height,
      );
      final validDestinationBounds = Rect.fromLTWH(
        -offsetPixels.dx,
        -offsetPixels.dy,
        size.width,
        size.height,
      ).intersect(layerBounds);
      final stampCenters = <Offset>[];
      void addStampCenter(Offset center) {
        if (stampCenters.isNotEmpty &&
            (stampCenters.last - center).distance < radius * 0.32) {
          return;
        }
        stampCenters.add(center);
      }

      final cachedStampPoints = preview.cloneStampPoints;
      if (cachedStampPoints != null && cachedStampPoints.isNotEmpty) {
        for (final point in cachedStampPoints) {
          addStampCenter(Offset(point.dx * size.width, point.dy * size.height));
        }
      } else {
        for (var index = 0; index < preview.points.length; index++) {
          final current = Offset(
            preview.points[index].dx * size.width,
            preview.points[index].dy * size.height,
          );
          if (index == 0) {
            addStampCenter(current);
            continue;
          }
          final previous = Offset(
            preview.points[index - 1].dx * size.width,
            preview.points[index - 1].dy * size.height,
          );
          final distance = (current - previous).distance;
          final steps = math.max(
            1,
            (distance / math.max(1, radius * 0.42)).ceil(),
          );
          for (var step = 1; step <= steps; step++) {
            addStampCenter(Offset.lerp(previous, current, step / steps)!);
          }
        }
      }

      Rect? dirtyBounds;
      for (final center in stampCenters) {
        final stampBounds = Rect.fromCircle(
          center: center,
          radius: radius,
        ).intersect(layerBounds);
        if (stampBounds.isEmpty) {
          continue;
        }
        dirtyBounds = dirtyBounds == null
            ? stampBounds
            : dirtyBounds.expandToInclude(stampBounds);
      }

      final dirty = dirtyBounds?.intersect(validDestinationBounds);
      if (dirty != null && !dirty.isEmpty) {
        final sourceLayerBounds = dirty.shift(offsetPixels);
        final sourceImageRect = Rect.fromLTRB(
          (sourceLayerBounds.left / size.width) * cloneImage.width,
          (sourceLayerBounds.top / size.height) * cloneImage.height,
          (sourceLayerBounds.right / size.width) * cloneImage.width,
          (sourceLayerBounds.bottom / size.height) * cloneImage.height,
        );
        canvas.saveLayer(
          dirty,
          Paint()
            ..isAntiAlias = true
            ..color = Color.fromRGBO(255, 255, 255, cloneOpacity),
        );
        canvas.drawImageRect(
          cloneImage,
          sourceImageRect,
          dirty,
          Paint()
            ..isAntiAlias = true
            ..filterQuality = FilterQuality.low,
        );
        canvas.saveLayer(
          dirty,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..isAntiAlias = true,
        );
        final maskPaint = Paint()..isAntiAlias = true;
        for (final center in stampCenters) {
          if (!dirty.overlaps(
            Rect.fromCircle(center: center, radius: radius),
          )) {
            continue;
          }
          if (hardStop >= 1) {
            maskPaint
              ..shader = null
              ..color = Colors.white;
          } else {
            maskPaint
              ..color = Colors.white
              ..shader = ui.Gradient.radial(
                center,
                radius,
                const <Color>[Colors.white, Colors.white, Colors.transparent],
                <double>[0, hardStop.clamp(0.001, 0.999).toDouble(), 1],
              );
          }
          canvas.drawCircle(center, radius, maskPaint);
        }
        maskPaint.shader = null;
        canvas.restore();
        canvas.restore();
      }
    }

    drawStrokePreview();

    void drawBrushCursor(Offset normalizedPoint) {
      final center = Offset(
        normalizedPoint.dx * size.width,
        normalizedPoint.dy * size.height,
      );
      final fillPaint = Paint()..style = PaintingStyle.fill;
      if (hardStop >= 1) {
        fillPaint.color = const Color(0xFFF8FAFC).withValues(alpha: 0.12);
      } else {
        fillPaint.shader = ui.Gradient.radial(
          center,
          radius,
          <Color>[
            const Color(0xFFF8FAFC).withValues(alpha: 0.16),
            const Color(0xFFF8FAFC).withValues(alpha: 0.16),
            const Color(0xFFF8FAFC).withValues(alpha: 0),
          ],
          <double>[0, hardStop.clamp(0.001, 0.999).toDouble(), 1],
        );
      }
      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * brushScale,
      );
    }

    drawBrushCursor(preview.points.last);
  }

  @override
  bool shouldRepaint(covariant _PhotoEraserPreviewPainter oldDelegate) {
    return oldDelegate.preview != preview ||
        oldDelegate.brushScale != brushScale;
  }
}

Size _fitPageSize({
  required Size workspaceSize,
  required double aspectRatio,
  bool preferFullWidth = false,
  bool forceFullWidth = false,
}) {
  if (workspaceSize.width <= 0 || workspaceSize.height <= 0) {
    return Size.zero;
  }

  final safeAspect = aspectRatio <= 0 ? 1.0 : aspectRatio;
  if (forceFullWidth) {
    final width = workspaceSize.width;
    return Size(width, width / safeAspect);
  }
  if (preferFullWidth) {
    final width = workspaceSize.width;
    final height = width / safeAspect;
    if (height <= workspaceSize.height) {
      return Size(width, height);
    }
  }
  final maxWidth = workspaceSize.width;
  final maxHeight = workspaceSize.height;

  var width = maxWidth;
  var height = width / safeAspect;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * safeAspect;
  }

  return Size(width, height);
}

@visibleForTesting
Size debugFitPageSizeForTest({
  required Size workspaceSize,
  required double aspectRatio,
  bool forceFullWidth = false,
}) {
  return _fitPageSize(
    workspaceSize: workspaceSize,
    aspectRatio: aspectRatio,
    forceFullWidth: forceFullWidth,
  );
}

Size _fitPhotoLayerSize({
  required Size pageSize,
  required double? photoAspectRatio,
}) {
  if (pageSize.width <= 0 || pageSize.height <= 0) {
    return Size.zero;
  }

  final ratio = (photoAspectRatio != null && photoAspectRatio > 0)
      ? photoAspectRatio
      : (pageSize.width / pageSize.height);

  final maxWidth = pageSize.width * 0.88;
  final maxHeight = pageSize.height * 0.88;
  var width = maxWidth;
  var height = width / ratio;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * ratio;
  }
  return Size(width, height);
}

Size _photoLayerVisualSize(_CanvasLayer layer, Size pageSize) {
  final fixedWidth = layer.photoFixedWidth;
  final fixedHeight = layer.photoFixedHeight;
  if (fixedWidth != null &&
      fixedHeight != null &&
      fixedWidth > 0 &&
      fixedHeight > 0) {
    return Size(fixedWidth, fixedHeight);
  }
  return _fitPhotoLayerSize(
    pageSize: pageSize,
    photoAspectRatio: layer.photoAspectRatio,
  );
}

Rect _photoVisiblePaintRect(_CanvasLayer layer, Size layerSize) {
  if (layerSize.width <= 0 || layerSize.height <= 0) {
    return Rect.zero;
  }
  final aspectRatio =
      (layer.photoAspectRatio != null && layer.photoAspectRatio! > 0)
      ? layer.photoAspectRatio!
      : layerSize.width / layerSize.height;
  var width = layerSize.width;
  var height = width / aspectRatio;
  if (height > layerSize.height) {
    height = layerSize.height;
    width = height * aspectRatio;
  }
  final left = (layerSize.width - width) / 2;
  final top = (layerSize.height - height) / 2;
  return Rect.fromLTWH(left, top, width, height);
}

double _editorPhotoMaskAspectRatio(String shape) {
  switch (shape) {
    case 'transparent_bottom_fade':
    case 'transparent_clean':
    case 'vertical_rectangle':
    case 'blob':
    case 'wave_bottom':
    case 'arch':
    case 'parallelogram':
      return 4 / 5;
    case 'custom_screen_fit':
      return 16 / 9;
    case 'custom_board_fit':
      return 16 / 7;
    case 'custom_frame_fit':
    case 'oval':
      return 4 / 5;
    case 'custom_polygon_fit':
      return 4 / 3;
    default:
      return 1;
  }
}

Path _buildEditorRadialMaskPath(
  Size size, {
  required int pointCount,
  required double innerRadiusFactor,
  double outerRadiusFactor = 1,
  double rotationRadians = -math.pi / 2,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2;
  final path = Path();
  final totalPoints = pointCount * 2;

  for (int index = 0; index < totalPoints; index += 1) {
    final currentRadius =
        radius * (index.isEven ? outerRadiusFactor : innerRadiusFactor);
    final angle = rotationRadians + ((math.pi * 2) / totalPoints) * index;
    final point = Offset(
      center.dx + math.cos(angle) * currentRadius,
      center.dy + math.sin(angle) * currentRadius,
    );
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }

  path.close();
  return path;
}

Path _buildEditorSmoothRadialMaskPath(
  Size size, {
  required int pointCount,
  required double innerRadiusFactor,
  double outerRadiusFactor = 1,
  double rotationRadians = -math.pi / 2,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2;
  final vertices = <Offset>[];
  final totalPoints = pointCount * 2;

  for (int index = 0; index < totalPoints; index += 1) {
    final currentRadius =
        radius * (index.isEven ? outerRadiusFactor : innerRadiusFactor);
    final angle = rotationRadians + ((math.pi * 2) / totalPoints) * index;
    vertices.add(
      Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      ),
    );
  }

  Offset midpoint(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  final path = Path();
  final start = midpoint(vertices.last, vertices.first);
  path.moveTo(start.dx, start.dy);

  for (int index = 0; index < vertices.length; index += 1) {
    final current = vertices[index];
    final next = vertices[(index + 1) % vertices.length];
    final end = midpoint(current, next);
    path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
  }

  path.close();
  return path;
}

class _EditorPhotoMaskFrame extends StatelessWidget {
  const _EditorPhotoMaskFrame({
    required this.shape,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.feather,
    required this.child,
  });

  final String shape;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double feather;
  final Widget child;

  bool _isTransparentPhotoShape(String currentShape) {
    return currentShape == 'transparent_bottom_fade' ||
        currentShape == 'transparent_clean' ||
        currentShape == 'transparent_soft_round' ||
        currentShape == 'transparent_sharp_round';
  }

  bool _isTransparentRoundShape(String currentShape) {
    return currentShape == 'transparent_soft_round' ||
        currentShape == 'transparent_sharp_round';
  }

  String _resolvedShape(String currentShape) {
    if (_isTransparentRoundShape(currentShape)) {
      return 'circle';
    }
    return currentShape;
  }

  String _resolvedEdgeStyle(String currentShape) {
    if (currentShape == 'transparent_bottom_fade') {
      return 'bottom_fade';
    }
    if (currentShape == 'transparent_soft_round') {
      return 'feather';
    }
    if (currentShape == 'transparent_clean' ||
        currentShape == 'transparent_sharp_round') {
      return 'sharp';
    }
    return 'bottom_fade';
  }

  BoxDecoration _outerDecorationForShape(String currentShape) {
    if (_isTransparentPhotoShape(currentShape)) {
      return const BoxDecoration(color: Colors.transparent);
    }
    switch (currentShape) {
      case 'circle':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF22C55E), Color(0xFF14B8A6)],
          ),
        );
      case 'scallop_circle':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF59E0B), Color(0xFFEF4444)],
          ),
        );
      case 'soft_burst':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFA855F7), Color(0xFFEC4899)],
          ),
        );
      case 'badge':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF2563EB), Color(0xFF06B6D4)],
          ),
        );
      case 'rounded':
      case 'rounded_square':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF8B5CF6), Color(0xFF3B82F6)],
          ),
        );
      case 'custom_frame_fit':
      case 'vertical_rectangle':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0EA5E9), Color(0xFF22C55E)],
          ),
        );
      case 'square':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF97316), Color(0xFFFACC15)],
          ),
        );
      default:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF64748B), Color(0xFF334155)],
          ),
        );
    }
  }

  Alignment _maskAlignmentForShape(String currentShape) {
    switch (_resolvedShape(currentShape)) {
      case 'flower':
        return const Alignment(0, 0.24);
      case 'scallop_circle':
      case 'soft_burst':
      case 'sunburst':
        return const Alignment(0, 0.2);
      case 'badge':
        return const Alignment(0, 0.22);
      case 'oval':
        return const Alignment(0, 0.16);
      case 'circle':
      case 'square':
        return const Alignment(0, 0.12);
      default:
        return const Alignment(0, 0.12);
    }
  }

  _EditorShapeFramePreset _presetForShape(String currentShape) {
    switch (currentShape) {
      case 'circle':
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'scallop_circle':
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'soft_burst':
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'square':
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'badge':
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'rounded':
      case 'rounded_square':
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'vertical_rectangle':
      case 'custom_frame_fit':
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
      default:
        return const _EditorShapeFramePreset(photoInset: EdgeInsets.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presetForShape(shape);
    final normalizedEdgeStyle = _resolvedEdgeStyle(shape);
    final maskScale = scale.clamp(0.5, 2.5).toDouble();
    final maskOffsetX = offsetX.clamp(-100.0, 100.0).toDouble();
    final maskOffsetY = offsetY.clamp(-100.0, 100.0).toDouble();
    final maskFeather = feather.clamp(0.0, 100.0).toDouble();
    Widget buildImageLayer({required double scale, required bool isBlurLayer}) {
      Widget layer = DecoratedBox(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: _maskAlignmentForShape(shape),
          child: SizedBox.square(dimension: 100, child: child),
        ),
      );
      layer = Transform.scale(
        scale: scale * maskScale,
        alignment: Alignment.topCenter,
        child: FractionalTranslation(
          translation: Offset(maskOffsetX / 220, maskOffsetY / 220),
          child: layer,
        ),
      );
      if (normalizedEdgeStyle == 'feather') {
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const RadialGradient(
              center: Alignment.center,
              radius: 0.72,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xE6FFFFFF),
                Color(0x52FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.78, 0.84, 0.94, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
        if (isBlurLayer) {
          layer = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Opacity(opacity: 0.9, child: layer),
          );
        }
      } else if (normalizedEdgeStyle == 'bottom_fade') {
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xF2FFFFFF),
                Color(0xCCFFFFFF),
                Color(0x7AFFFFFF),
                Color(0x30FFFFFF),
                Color(0x08FFFFFF),
                Color(0x00FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.4, 0.52, 0.62, 0.72, 0.8, 0.86, 0.9, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
      }
      return layer;
    }

    Widget alignedChild;
    if (normalizedEdgeStyle == 'feather') {
      alignedChild = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: buildImageLayer(scale: 1.07, isBlurLayer: true),
          ),
          Positioned.fill(
            child: buildImageLayer(scale: 1.035, isBlurLayer: false),
          ),
        ],
      );
    } else {
      alignedChild = buildImageLayer(scale: 1.035, isBlurLayer: false);
    }
    final photoLayer = Padding(
      padding: preset.photoInset,
      child: _isTransparentRoundShape(shape)
          ? _editorClipPhotoShape(_resolvedShape(shape), alignedChild)
          : _isTransparentPhotoShape(shape)
          ? ClipRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: alignedChild,
            )
          : _editorClipPhotoShape(shape, alignedChild),
    );
    final framedChild = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (!_isTransparentPhotoShape(shape))
          _editorClipPhotoShape(
            shape,
            DecoratedBox(decoration: _outerDecorationForShape(shape)),
          ),
        photoLayer,
      ],
    );

    if (_isTransparentPhotoShape(shape)) {
      return framedChild;
    }

    Widget withOptionalFeather(Widget child) {
      if (maskFeather <= 0.001) {
        return child;
      }
      final blurSigma = (maskFeather / 12).clamp(0.4, 8.0).toDouble();
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Opacity(
            opacity: (0.16 + (maskFeather / 220)).clamp(0.16, 0.58).toDouble(),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: Transform.scale(scale: 1.012, child: child),
            ),
          ),
          child,
        ],
      );
    }

    switch (shape) {
      case 'circle':
      case 'oval':
        return withOptionalFeather(
          ClipOval(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
      case 'rounded':
      case 'rounded_square':
        return withOptionalFeather(
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
      case 'pill':
        return withOptionalFeather(
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
      case 'custom_screen_fit':
        return withOptionalFeather(
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
      case 'custom_board_fit':
        return withOptionalFeather(
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
      case 'custom_frame_fit':
      case 'vertical_rectangle':
        return withOptionalFeather(
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
      case 'hexagon':
      case 'scallop_circle':
      case 'soft_burst':
      case 'diamond':
      case 'flower':
      case 'sunburst':
      case 'star':
      case 'shield':
      case 'arch':
      case 'blob':
      case 'badge':
      case 'heart':
      case 'custom_polygon_fit':
        return withOptionalFeather(
          ClipPath(
            clipper: _EditorPhotoMaskClipper(shape),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
      case 'square':
      default:
        return withOptionalFeather(
          ClipRect(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: framedChild,
          ),
        );
    }
  }
}

class _EditorShapeFramePreset {
  const _EditorShapeFramePreset({required this.photoInset});

  final EdgeInsets photoInset;
}

Widget _editorClipPhotoShape(String shape, Widget child) {
  switch (shape) {
    case 'circle':
    case 'oval':
      return ClipOval(clipBehavior: Clip.antiAliasWithSaveLayer, child: child);
    case 'rounded':
    case 'rounded_square':
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'pill':
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'custom_screen_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'custom_board_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'custom_frame_fit':
    case 'vertical_rectangle':
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'hexagon':
    case 'scallop_circle':
    case 'soft_burst':
    case 'diamond':
    case 'flower':
    case 'sunburst':
    case 'star':
    case 'shield':
    case 'arch':
    case 'blob':
    case 'badge':
    case 'heart':
    case 'custom_polygon_fit':
      return ClipPath(
        clipper: _EditorPhotoMaskClipper(shape),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: child,
      );
    case 'square':
    default:
      return ClipRect(clipBehavior: Clip.antiAliasWithSaveLayer, child: child);
  }
}

class _EditorPhotoMaskClipper extends CustomClipper<Path> {
  const _EditorPhotoMaskClipper(this.shape);

  final String shape;

  @override
  Path getClip(Size size) {
    switch (shape) {
      case 'circle':
        final diameter = math.min(size.width, size.height);
        return Path()..addOval(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: diameter,
            height: diameter,
          ),
        );
      case 'square':
        final side = math.min(size.width, size.height);
        return Path()..addRect(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: side,
            height: side,
          ),
        );
      case 'rounded':
      case 'rounded_square':
        final side = math.min(size.width, size.height);
        final bounds = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: side,
          height: side,
        );
        return Path()..addRRect(
          RRect.fromRectAndRadius(bounds, Radius.circular(side * 0.16)),
        );
      case 'oval':
        return Path()..addOval(Offset.zero & size);
      case 'scallop_circle':
        return _buildEditorSmoothRadialMaskPath(
          size,
          pointCount: 16,
          innerRadiusFactor: 0.9,
        );
      case 'soft_burst':
        return _buildEditorRadialMaskPath(
          size,
          pointCount: 44,
          innerRadiusFactor: 0.95,
        );
      case 'hexagon':
        return Path()
          ..moveTo(size.width * 0.25, size.height * 0.06)
          ..lineTo(size.width * 0.75, size.height * 0.06)
          ..lineTo(size.width, size.height * 0.5)
          ..lineTo(size.width * 0.75, size.height * 0.94)
          ..lineTo(size.width * 0.25, size.height * 0.94)
          ..lineTo(0, size.height * 0.5)
          ..close();
      case 'diamond':
        return Path()
          ..moveTo(size.width * 0.5, 0)
          ..lineTo(size.width, size.height * 0.5)
          ..lineTo(size.width * 0.5, size.height)
          ..lineTo(0, size.height * 0.5)
          ..close();
      case 'star':
        return Path()
          ..moveTo(size.width * 0.5, 0)
          ..lineTo(size.width * 0.61, size.height * 0.34)
          ..lineTo(size.width * 0.98, size.height * 0.35)
          ..lineTo(size.width * 0.68, size.height * 0.56)
          ..lineTo(size.width * 0.79, size.height * 0.91)
          ..lineTo(size.width * 0.5, size.height * 0.7)
          ..lineTo(size.width * 0.21, size.height * 0.91)
          ..lineTo(size.width * 0.32, size.height * 0.56)
          ..lineTo(size.width * 0.02, size.height * 0.35)
          ..lineTo(size.width * 0.39, size.height * 0.34)
          ..close();
      case 'shield':
        return Path()
          ..moveTo(size.width * 0.5, 0)
          ..lineTo(size.width * 0.92, size.height * 0.18)
          ..lineTo(size.width * 0.82, size.height * 0.76)
          ..lineTo(size.width * 0.5, size.height)
          ..lineTo(size.width * 0.18, size.height * 0.76)
          ..lineTo(size.width * 0.08, size.height * 0.18)
          ..close();
      case 'arch':
        return Path()
          ..moveTo(0, size.height)
          ..lineTo(0, size.height * 0.44)
          ..cubicTo(
            0,
            size.height * 0.14,
            size.width * 0.22,
            0,
            size.width * 0.5,
            0,
          )
          ..cubicTo(
            size.width * 0.78,
            0,
            size.width,
            size.height * 0.14,
            size.width,
            size.height * 0.44,
          )
          ..lineTo(size.width, size.height)
          ..close();
      case 'blob':
        return Path()
          ..moveTo(size.width * 0.55, size.height * 0.02)
          ..cubicTo(
            size.width * 0.82,
            0,
            size.width,
            size.height * 0.2,
            size.width * 0.94,
            size.height * 0.48,
          )
          ..cubicTo(
            size.width * 0.9,
            size.height * 0.78,
            size.width * 0.68,
            size.height,
            size.width * 0.42,
            size.height * 0.95,
          )
          ..cubicTo(
            size.width * 0.14,
            size.height * 0.9,
            0,
            size.height * 0.68,
            size.width * 0.06,
            size.height * 0.38,
          )
          ..cubicTo(
            size.width * 0.12,
            size.height * 0.1,
            size.width * 0.3,
            size.height * 0.03,
            size.width * 0.55,
            size.height * 0.02,
          )
          ..close();
      case 'flower':
        return _buildEditorSmoothRadialMaskPath(
          size,
          pointCount: 8,
          innerRadiusFactor: 0.74,
        );
      case 'badge':
        return _buildEditorSmoothRadialMaskPath(
          size,
          pointCount: 12,
          innerRadiusFactor: 0.86,
        );
      case 'heart':
        return Path()
          ..moveTo(size.width * 0.5, size.height * 0.92)
          ..cubicTo(
            size.width * 0.18,
            size.height * 0.68,
            0,
            size.height * 0.48,
            size.width * 0.08,
            size.height * 0.25,
          )
          ..cubicTo(
            size.width * 0.16,
            size.height * 0.02,
            size.width * 0.4,
            size.height * 0.08,
            size.width * 0.5,
            size.height * 0.25,
          )
          ..cubicTo(
            size.width * 0.6,
            size.height * 0.08,
            size.width * 0.84,
            size.height * 0.02,
            size.width * 0.92,
            size.height * 0.25,
          )
          ..cubicTo(
            size.width,
            size.height * 0.48,
            size.width * 0.82,
            size.height * 0.68,
            size.width * 0.5,
            size.height * 0.92,
          )
          ..close();
      case 'sunburst':
        return _buildEditorRadialMaskPath(
          size,
          pointCount: 20,
          innerRadiusFactor: 0.56,
        );
      case 'custom_polygon_fit':
        return Path()
          ..moveTo(size.width * 0.07, size.height * 0.1)
          ..lineTo(size.width * 0.95, 0)
          ..lineTo(size.width * 0.88, size.height)
          ..lineTo(0, size.height * 0.88)
          ..close();
      default:
        return Path()..addRect(Offset.zero & size);
    }
  }

  @override
  bool shouldReclip(covariant _EditorPhotoMaskClipper oldClipper) =>
      oldClipper.shape != shape;
}

TextDirection _textDirectionForValue(String value) {
  final hasRtlScript = RegExp(
    r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
  ).hasMatch(value);
  return hasRtlScript ? TextDirection.rtl : TextDirection.ltr;
}

bool _textValueNeedsScriptSafety(String value) {
  return RegExp(
    r'[\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0A80-\u0AFF\u0B00-\u0B7F\u0B80-\u0BFF\u0C00-\u0C7F\u0C80-\u0CFF\u0D00-\u0D7F\u0D80-\u0DFF]',
  ).hasMatch(value);
}

bool _fontFamilyNeedsScriptSafety(String fontFamily) {
  return _isLegacyTeluguFontFamily(fontFamily) ||
      _unicodeTeluguFontFamilies.contains(fontFamily) ||
      _hindiTextFontFamilies.contains(fontFamily);
}

bool _textLayerNeedsScriptSafety({
  required String fontFamily,
  required String text,
}) {
  return _fontFamilyNeedsScriptSafety(fontFamily) ||
      _textValueNeedsScriptSafety(text);
}

Size _workspaceLayerVisualSize(_CanvasLayer layer, Size pageSize) {
  if (layer.isPhoto) {
    return layer.fillPageBounds
        ? pageSize
        : _photoLayerVisualSize(layer, pageSize);
  }
  if (layer.isText) {
    final maxTextWidth = math.max(72.0, pageSize.width * 0.9);
    final renderFontFamily = _resolveLayerRenderFontFamily(layer);
    final textPadding = _textLayerVisualPadding(layer);
    final viewPadding = _textLayerViewPadding(layer);
    final renderLineHeight = _effectiveTextLineHeightForRender(
      fontFamily: layer.fontFamily,
      textLineHeight: layer.textLineHeight,
      text: _resolveLayerRenderText(layer),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: _resolveLayerRenderText(layer),
        style: TextStyle(
          fontFamily: renderFontFamily,
          fontSize: layer.fontSize,
          height: renderLineHeight,
          letterSpacing: layer.textLetterSpacing,
          fontWeight: layer.isTextBold ? FontWeight.w700 : FontWeight.w500,
          fontStyle: layer.isTextItalic ? FontStyle.italic : FontStyle.normal,
          decoration: layer.isTextUnderline
              ? TextDecoration.underline
              : TextDecoration.none,
          color: layer.textColor,
        ),
      ),
      textDirection: _textDirectionForValue(_resolveLayerRenderText(layer)),
      textAlign: layer.textAlign,
      textScaler: TextScaler.noScaling,
      maxLines: null,
    );
    if (layer.isParagraphText) {
      painter.layout(maxWidth: maxTextWidth);
    } else {
      painter.layout();
    }
    return Size(
      painter.size.width + textPadding.horizontal + viewPadding.horizontal,
      painter.size.height + textPadding.vertical + viewPadding.vertical,
    );
  }
  final sticker = layer.sticker;
  if (_EditorTextState._isImageLikeSticker(sticker)) {
    return Size.square(layer.fontSize);
  }
  return _textStickerVisualSize(sticker, layer.fontSize);
}

Size _textStickerVisualSize(String? sticker, double fontSize) {
  final safeFontSize = fontSize.clamp(1.0, 400.0).toDouble();
  final painter = TextPainter(
    text: TextSpan(
      text: sticker ?? '*',
      style: TextStyle(fontSize: safeFontSize, height: 1.15),
    ),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
    maxLines: 1,
  )..layout();
  final verticalPadding = math.max(6.0, safeFontSize * 0.16);
  final horizontalPadding = math.max(4.0, safeFontSize * 0.08);
  return Size(
    math.max(safeFontSize, painter.width + (horizontalPadding * 2)),
    math.max(safeFontSize * 1.22, painter.height + (verticalPadding * 2)),
  );
}

Size _workspaceTextSelectionBoxSize(_CanvasLayer layer, Size pageSize) {
  if (!layer.isText) {
    return Size.zero;
  }
  final visualSize = _workspaceTextSelectionVisualSize(layer, pageSize);
  return Size(
    math.max(24.0, visualSize.width),
    math.max(24.0, visualSize.height),
  );
}

Size _workspaceTextSelectionVisualSize(_CanvasLayer layer, Size pageSize) {
  final metrics = _workspaceTextSelectionMetrics(layer, pageSize);
  return metrics.size;
}

Offset _workspaceTextSelectionCenterOffset(_CanvasLayer layer, Size pageSize) {
  return _workspaceTextSelectionMetrics(layer, pageSize).centerOffset;
}

_TextSelectionMetrics _workspaceTextSelectionMetrics(
  _CanvasLayer layer,
  Size pageSize,
) {
  final maxTextWidth = math.max(72.0, pageSize.width * 0.9);
  final renderText = _resolveLayerRenderText(layer);
  final renderFontFamily = _resolveLayerRenderFontFamily(layer);
  final renderLineHeight = _effectiveTextLineHeightForRender(
    fontFamily: layer.fontFamily,
    textLineHeight: layer.textLineHeight,
    text: renderText,
  );
  final painter = TextPainter(
    text: TextSpan(
      text: renderText,
      style: TextStyle(
        fontFamily: renderFontFamily,
        fontSize: layer.fontSize,
        height: renderLineHeight,
        letterSpacing: layer.textLetterSpacing,
        fontWeight: layer.isTextBold ? FontWeight.w700 : FontWeight.w500,
        fontStyle: layer.isTextItalic ? FontStyle.italic : FontStyle.normal,
        decoration: layer.isTextUnderline
            ? TextDecoration.underline
            : TextDecoration.none,
        color: layer.textColor,
      ),
    ),
    textDirection: _textDirectionForValue(renderText),
    textAlign: layer.textAlign,
    textScaler: TextScaler.noScaling,
    maxLines: null,
  );
  if (layer.isParagraphText) {
    painter.layout(maxWidth: maxTextWidth);
  } else {
    painter.layout();
  }
  final lineMetrics = painter.computeLineMetrics();
  final lineTop = lineMetrics.isEmpty
      ? 0.0
      : lineMetrics.first.baseline - lineMetrics.first.ascent;
  final lineBottom = lineMetrics.isEmpty
      ? painter.size.height
      : lineMetrics.last.baseline + lineMetrics.last.descent;
  final tightTextHeight = math.max(1.0, lineBottom - lineTop);
  final hasBackground = layer.textBackgroundOpacity > 0.001;
  final effectiveStrokeWidth = math.max(
    layer.textStrokeWidth,
    layer.layerStyleStrokeWidth,
  );
  final strokeInset = effectiveStrokeWidth > 0.001
      ? math.min(8.0, math.max(2.0, effectiveStrokeWidth * 0.5))
      : 2.0;
  final backgroundHorizontal = hasBackground ? 24.0 : 0.0;
  final backgroundTop = hasBackground
      ? layer.textBackgroundTopPadding.clamp(0, 100).toDouble()
      : 0.0;
  final backgroundBottom = hasBackground
      ? layer.textBackgroundBottomPadding.clamp(0, 100).toDouble()
      : 0.0;
  final backgroundVertical = hasBackground
      ? backgroundTop + backgroundBottom
      : 0.0;
  final overflowPadding = _textLayerVisualPadding(layer);
  final viewPadding = _textLayerViewPadding(layer);
  final fullLayerHeight =
      painter.size.height + overflowPadding.vertical + viewPadding.vertical;
  final contentCenterY =
      viewPadding.top + overflowPadding.top + lineTop + (tightTextHeight / 2);
  final centerOffsetY = contentCenterY - (fullLayerHeight / 2);
  return _TextSelectionMetrics(
    size: Size(
      painter.size.width + backgroundHorizontal + (strokeInset * 2),
      tightTextHeight + backgroundVertical + (strokeInset * 2),
    ),
    centerOffset: Offset(0, centerOffsetY),
  );
}

class _TextSelectionMetrics {
  const _TextSelectionMetrics({required this.size, required this.centerOffset});

  final Size size;
  final Offset centerOffset;
}

EdgeInsets _textLayerViewPadding(_CanvasLayer layer) {
  final hasBackground = layer.textBackgroundOpacity > 0.001;
  return EdgeInsets.fromLTRB(
    8 + (hasBackground ? 12 : 0),
    6 +
        (hasBackground
            ? layer.textBackgroundTopPadding.clamp(0, 100).toDouble()
            : 0),
    8 + (hasBackground ? 12 : 0),
    6 +
        (hasBackground
            ? layer.textBackgroundBottomPadding.clamp(0, 100).toDouble()
            : 0),
  );
}

String _layerStyleVisualSignature(_CanvasLayer layer) {
  return Object.hashAll(<Object?>[
    layer.id,
    layer.layerStyleOverlayColor.toARGB32(),
    layer.layerStyleOverlayOpacity.toStringAsFixed(4),
    layer.layerStyleStrokeColor.toARGB32(),
    layer.layerStyleStrokeWidth.toStringAsFixed(3),
    layer.layerStyleStrokeOpacity.toStringAsFixed(4),
    layer.layerStyleShadowColor.toARGB32(),
    layer.layerStyleShadowOpacity.toStringAsFixed(4),
    layer.layerStyleShadowBlur.toStringAsFixed(3),
    layer.layerStyleShadowSpread.toStringAsFixed(3),
    layer.layerStyleShadowOffsetX.toStringAsFixed(3),
    layer.layerStyleShadowOffsetY.toStringAsFixed(3),
    layer.layerStyleInnerShadowColor.toARGB32(),
    layer.layerStyleInnerShadowOpacity.toStringAsFixed(4),
    layer.layerStyleInnerShadowBlur.toStringAsFixed(3),
    layer.layerStyleInnerShadowChoke.toStringAsFixed(3),
    layer.layerStyleInnerShadowDistance.toStringAsFixed(3),
    layer.layerStyleInnerShadowAngle.toStringAsFixed(3),
    layer.layerStyleOuterGlowColor.toARGB32(),
    layer.layerStyleOuterGlowOpacity.toStringAsFixed(4),
    layer.layerStyleOuterGlowSize.toStringAsFixed(3),
    layer.layerStyleOuterGlowSpread.toStringAsFixed(3),
    layer.layerStyleGradientOverlayEnabled,
    layer.layerStyleGradientOverlayIndex,
    layer.layerStyleGradientOverlayOpacity.toStringAsFixed(4),
    layer.layerStyleGradientOverlayAngle.toStringAsFixed(3),
    layer.layerStyleGradientOverlayScale.toStringAsFixed(3),
    layer.layerStyleGradientOverlayReversed,
  ]).toString();
}

Color _layerStyleTextColor(_CanvasLayer layer) {
  if (layer.layerStyleOverlayOpacity <= 0.001) {
    return layer.textColor;
  }
  return Color.lerp(
    layer.textColor,
    layer.layerStyleOverlayColor,
    layer.layerStyleOverlayOpacity.clamp(0.0, 1.0),
  )!;
}

List<Color>? _layerStyleTextGradient(
  _CanvasLayer layer,
  List<List<Color>> textGradients,
) {
  if (layer.layerStyleGradientOverlayEnabled &&
      layer.layerStyleGradientOverlayOpacity > 0.001 &&
      layer.layerStyleGradientOverlayIndex >= 0 &&
      layer.layerStyleGradientOverlayIndex < textGradients.length) {
    final opacity = layer.layerStyleGradientOverlayOpacity
        .clamp(0.0, 1.0)
        .toDouble();
    final colors = layer.layerStyleGradientOverlayReversed
        ? textGradients[layer.layerStyleGradientOverlayIndex].reversed
        : textGradients[layer.layerStyleGradientOverlayIndex];
    return colors
        .map((color) => color.withValues(alpha: color.a * opacity))
        .toList(growable: false);
  }
  if (layer.textGradientIndex >= 0 &&
      layer.textGradientIndex < textGradients.length) {
    return textGradients[layer.textGradientIndex];
  }
  return null;
}

double _layerStyleTextShadowOpacity(_CanvasLayer layer) {
  if (layer.layerStyleShadowOpacity > 0.001) {
    return layer.layerStyleShadowOpacity;
  }
  if (layer.layerStyleInnerShadowOpacity > 0.001) {
    return layer.layerStyleInnerShadowOpacity;
  }
  return layer.textShadowOpacity;
}

Color _layerStyleTextShadowColor(_CanvasLayer layer) {
  if (layer.layerStyleShadowOpacity > 0.001) {
    return layer.layerStyleShadowColor;
  }
  if (layer.layerStyleInnerShadowOpacity > 0.001) {
    return layer.layerStyleInnerShadowColor;
  }
  return layer.textShadowColor;
}

double _layerStyleTextShadowBlur(_CanvasLayer layer) {
  if (layer.layerStyleShadowOpacity > 0.001) {
    return layer.layerStyleShadowBlur;
  }
  if (layer.layerStyleInnerShadowOpacity > 0.001) {
    return layer.layerStyleInnerShadowBlur;
  }
  return layer.textShadowBlur;
}

Offset _layerStyleTextShadowOffset(_CanvasLayer layer) {
  if (layer.layerStyleShadowOpacity > 0.001) {
    return Offset(layer.layerStyleShadowOffsetX, layer.layerStyleShadowOffsetY);
  }
  if (layer.layerStyleInnerShadowOpacity > 0.001) {
    final radians = layer.layerStyleInnerShadowAngle * math.pi / 180.0;
    return Offset(math.cos(radians), -math.sin(radians)) *
        layer.layerStyleInnerShadowDistance;
  }
  if (layer.textShadowOpacity > 0.001) {
    return Offset(0, layer.textShadowOffsetY);
  }
  return Offset.zero;
}

final LinkedHashMap<int, ui.ImageFilter> _textOuterGlowFilterCache =
    LinkedHashMap<int, ui.ImageFilter>();

ui.ImageFilter _textOuterGlowFilter(double size, double spread) {
  final sizeStep = (size * 0.5).round().clamp(0, 60);
  final spreadStep = (spread * 0.5).round().clamp(0, 32);
  final key = sizeStep * 100 + spreadStep;
  final cached = _textOuterGlowFilterCache.remove(key);
  if (cached != null) {
    _textOuterGlowFilterCache[key] = cached;
    return cached;
  }

  final visualSize = sizeStep * 2.0;
  final visualSpread = spreadStep * 2.0;
  final dilateRadius = math.min(18.0, visualSpread * 0.22);
  final blurRadius = math.max(
    0.01,
    (visualSize * 0.42) + (visualSpread * 0.18),
  );
  final filter = ui.ImageFilter.compose(
    inner: ui.ImageFilter.dilate(radiusX: dilateRadius, radiusY: dilateRadius),
    outer: ui.ImageFilter.blur(
      sigmaX: math.max(0.01, blurRadius * 0.5),
      sigmaY: math.max(0.01, blurRadius * 0.5),
      tileMode: TileMode.decal,
    ),
  );
  _textOuterGlowFilterCache[key] = filter;
  if (_textOuterGlowFilterCache.length > 48) {
    _textOuterGlowFilterCache.remove(_textOuterGlowFilterCache.keys.first);
  }
  return filter;
}

EdgeInsets _textLayerVisualPadding(_CanvasLayer layer) {
  final useLayerShadow =
      layer.layerStyleShadowOpacity > 0.001 ||
      layer.layerStyleOuterGlowOpacity > 0.001 ||
      layer.layerStyleInnerShadowOpacity > 0.001;
  return _textVisualOverflowPadding(
    fontFamily: layer.fontFamily,
    text: _resolveLayerRenderText(layer),
    fontSize: layer.fontSize,
    textStrokeWidth: math.max(
      layer.textStrokeWidth,
      layer.layerStyleStrokeWidth,
    ),
    textShadowOpacity: useLayerShadow
        ? _layerStyleTextShadowOpacity(layer)
        : layer.textShadowOpacity,
    textShadowBlur: useLayerShadow
        ? _layerStyleTextShadowBlur(layer)
        : layer.textShadowBlur,
    textShadowOffsetX: useLayerShadow
        ? _layerStyleTextShadowOffset(layer).dx
        : 0,
    textShadowOffsetY: useLayerShadow
        ? _layerStyleTextShadowOffset(layer).dy
        : layer.textShadowOffsetY,
    isTextUnderline: layer.isTextUnderline,
  );
}

EdgeInsets _textVisualOverflowPadding({
  required String fontFamily,
  required String text,
  required double fontSize,
  required double textStrokeWidth,
  required double textShadowOpacity,
  required double textShadowBlur,
  double textShadowOffsetX = 0,
  required double textShadowOffsetY,
  required bool isTextUnderline,
}) {
  final strokePad = textStrokeWidth > 0.001
      ? textStrokeWidth.ceilToDouble() + 2
      : 2.0;
  final shadowBlurPad = textShadowOpacity > 0.001 ? textShadowBlur + 2 : 0.0;
  final shadowTop = shadowBlurPad + math.max(0, -textShadowOffsetY);
  final shadowBottom = shadowBlurPad + math.max(0, textShadowOffsetY);
  final shadowLeft = shadowBlurPad + math.max(0, -textShadowOffsetX);
  final shadowRight = shadowBlurPad + math.max(0, textShadowOffsetX);
  final needsScriptSafety = _textLayerNeedsScriptSafety(
    fontFamily: fontFamily,
    text: text,
  );
  final scriptTopPad = needsScriptSafety
      ? math.max(7.0, fontSize * 0.28)
      : math.max(4.0, fontSize * 0.20);
  final descenderPad = needsScriptSafety
      ? math.max(10.0, fontSize * 0.40)
      : math.max(6.0, fontSize * 0.30);
  final underlinePad = isTextUnderline ? math.max(2.0, fontSize * 0.04) : 0.0;
  final leftPad = math.max(2.0, strokePad + shadowLeft);
  final rightPad = math.max(2.0, strokePad + shadowRight);
  final topPad = math.max(scriptTopPad, strokePad + shadowTop);
  final bottomPad =
      math.max(descenderPad + underlinePad, strokePad) + shadowBottom;
  return EdgeInsets.fromLTRB(leftPad, topPad, rightPad, bottomPad);
}

class _LayerSelectionBoxOverlay extends StatelessWidget {
  const _LayerSelectionBoxOverlay({
    required this.pageSize,
    this.pageOrigin = Offset.zero,
    required this.matrix,
    required this.viewportScale,
    required this.layerSize,
    this.centerOffset = Offset.zero,
    this.highlightPageOverflow = false,
    required this.showTopStretchHandle,
    required this.showSideResizeHandles,
    required this.onPointerDown,
    required this.onResizePanStart,
    required this.onResizePanUpdate,
    required this.onHorizontalSidePanStart,
    required this.onHorizontalSidePanUpdate,
    required this.onVerticalSidePanStart,
    required this.onVerticalSidePanUpdate,
    required this.onRotatePanStart,
    required this.onRotatePanUpdate,
    required this.onTopPanStart,
    required this.onTopPanUpdate,
    required this.onPanEnd,
  });

  final Size pageSize;
  final Offset pageOrigin;
  final Matrix4 matrix;
  final double viewportScale;
  final Size layerSize;
  final Offset centerOffset;
  final bool highlightPageOverflow;
  final bool showTopStretchHandle;
  final bool showSideResizeHandles;
  final VoidCallback onPointerDown;
  final GestureDragStartCallback onResizePanStart;
  final GestureDragUpdateCallback onResizePanUpdate;
  final GestureDragStartCallback onHorizontalSidePanStart;
  final GestureDragUpdateCallback onHorizontalSidePanUpdate;
  final GestureDragStartCallback onVerticalSidePanStart;
  final GestureDragUpdateCallback onVerticalSidePanUpdate;
  final GestureDragStartCallback onRotatePanStart;
  final GestureDragUpdateCallback onRotatePanUpdate;
  final GestureDragStartCallback onTopPanStart;
  final GestureDragUpdateCallback onTopPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    final safeLayerSize = Size(
      math.max(layerSize.width, 24),
      math.max(layerSize.height, 24),
    );
    final boxSize = Size(
      safeLayerSize.width.clamp(
        24.0,
        pageSize.width * (highlightPageOverflow ? 8 : 1.6),
      ),
      safeLayerSize.height.clamp(
        24.0,
        pageSize.height * (highlightPageOverflow ? 8 : 1.6),
      ),
    );
    final pageCenter =
        pageOrigin + Offset(pageSize.width / 2, pageSize.height / 2);
    Offset transformedPoint(Offset point) =>
        pageCenter + MatrixUtils.transformPoint(matrix, point + centerOffset);
    final topHandleCenter = transformedPoint(Offset(0, -boxSize.height / 2));
    final bottomSideHandleCenter = transformedPoint(
      Offset(0, boxSize.height / 2),
    );
    final leftSideHandleCenter = transformedPoint(
      Offset(-boxSize.width / 2, 0),
    );
    final rightSideHandleCenter = transformedPoint(
      Offset(boxSize.width / 2, 0),
    );
    final topLeft = transformedPoint(
      Offset(-boxSize.width / 2, -boxSize.height / 2),
    );
    final topRight = transformedPoint(
      Offset(boxSize.width / 2, -boxSize.height / 2),
    );
    final bottomRight = transformedPoint(
      Offset(boxSize.width / 2, boxSize.height / 2),
    );
    final bottomLeft = transformedPoint(
      Offset(-boxSize.width / 2, boxSize.height / 2),
    );
    final pageBounds = pageOrigin & pageSize;
    const overflowTolerance = 0.5;
    final leftOverflow =
        highlightPageOverflow &&
        <Offset>[
          topLeft,
          bottomLeft,
        ].any((point) => point.dx < pageBounds.left - overflowTolerance);
    final rightOverflow =
        highlightPageOverflow &&
        <Offset>[
          topRight,
          bottomRight,
        ].any((point) => point.dx > pageBounds.right + overflowTolerance);
    final topOverflow =
        highlightPageOverflow &&
        <Offset>[
          topLeft,
          topRight,
        ].any((point) => point.dy < pageBounds.top - overflowTolerance);
    final bottomOverflow =
        highlightPageOverflow &&
        <Offset>[
          bottomLeft,
          bottomRight,
        ].any((point) => point.dy > pageBounds.bottom + overflowTolerance);
    final overflowColor = const Color(0xFFEF4444).withValues(alpha: 0.58);
    final validColor = const Color(0xFF1A73E8).withValues(alpha: 0.48);
    final decorationScale = 1 / viewportScale.clamp(0.25, 8.0);
    double scaled(double value) => value * decorationScale;
    final sideHandleHitSize = scaled(44);
    final cornerHandleHitSize = scaled(48);
    final rotateHandleHitSize = scaled(48);
    final stretchHandleHitSize = scaled(44);
    final sideHandleVisualSize = scaled(7.5);
    final cornerHandleVisualSize = scaled(13);
    final rotateHandleVisualSize = scaled(13);
    final stretchHandleVisualSize = scaled(10);
    final rotateHandleCenter = transformedPoint(
      Offset(0, boxSize.height / 2 + scaled(30)),
    );
    Widget cornerResizeHandle({required Offset center, required Color color}) {
      return Positioned(
        left: center.dx - (cornerHandleHitSize / 2),
        top: center.dy - (cornerHandleHitSize / 2),
        child: _TextBoxHandle(
          visualSize: cornerHandleVisualSize,
          hitSize: cornerHandleHitSize,
          decorationScale: decorationScale,
          isRound: false,
          color: color,
          icon: Icons.open_in_full_rounded,
          onPointerDown: onPointerDown,
          onPanStart: onResizePanStart,
          onPanUpdate: onResizePanUpdate,
          onPanEnd: onPanEnd,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SelectionBoxPainter(
                topLeft: topLeft,
                topRight: topRight,
                bottomRight: bottomRight,
                bottomLeft: bottomLeft,
                leftColor: leftOverflow ? overflowColor : validColor,
                topColor: topOverflow ? overflowColor : validColor,
                rightColor: rightOverflow ? overflowColor : validColor,
                bottomColor: bottomOverflow ? overflowColor : validColor,
                strokeWidth: scaled(0.72),
              ),
            ),
          ),
        ),
        if (showTopStretchHandle)
          Positioned(
            left: topHandleCenter.dx - (stretchHandleHitSize / 2),
            top: topHandleCenter.dy - (stretchHandleHitSize / 2),
            child: _TextBoxHandle(
              visualSize: stretchHandleVisualSize,
              hitSize: stretchHandleHitSize,
              decorationScale: decorationScale,
              isRound: true,
              color: topOverflow ? overflowColor : validColor,
              onPointerDown: onPointerDown,
              onPanStart: onTopPanStart,
              onPanUpdate: onTopPanUpdate,
              onPanEnd: onPanEnd,
            ),
          ),
        if (showSideResizeHandles) ...<Widget>[
          Positioned(
            left: leftSideHandleCenter.dx - (sideHandleHitSize / 2),
            top: leftSideHandleCenter.dy - (sideHandleHitSize / 2),
            child: _TextBoxHandle(
              visualSize: sideHandleVisualSize,
              hitSize: sideHandleHitSize,
              decorationScale: decorationScale,
              isRound: true,
              color: leftOverflow ? overflowColor : validColor,
              onPointerDown: onPointerDown,
              onPanStart: onHorizontalSidePanStart,
              onPanUpdate: onHorizontalSidePanUpdate,
              onPanEnd: onPanEnd,
            ),
          ),
          Positioned(
            left: rightSideHandleCenter.dx - (sideHandleHitSize / 2),
            top: rightSideHandleCenter.dy - (sideHandleHitSize / 2),
            child: _TextBoxHandle(
              visualSize: sideHandleVisualSize,
              hitSize: sideHandleHitSize,
              decorationScale: decorationScale,
              isRound: true,
              color: rightOverflow ? overflowColor : validColor,
              onPointerDown: onPointerDown,
              onPanStart: onHorizontalSidePanStart,
              onPanUpdate: onHorizontalSidePanUpdate,
              onPanEnd: onPanEnd,
            ),
          ),
          Positioned(
            left: topHandleCenter.dx - (sideHandleHitSize / 2),
            top: topHandleCenter.dy - (sideHandleHitSize / 2),
            child: _TextBoxHandle(
              visualSize: sideHandleVisualSize,
              hitSize: sideHandleHitSize,
              decorationScale: decorationScale,
              isRound: true,
              color: topOverflow ? overflowColor : validColor,
              onPointerDown: onPointerDown,
              onPanStart: onVerticalSidePanStart,
              onPanUpdate: onVerticalSidePanUpdate,
              onPanEnd: onPanEnd,
            ),
          ),
          Positioned(
            left: bottomSideHandleCenter.dx - (sideHandleHitSize / 2),
            top: bottomSideHandleCenter.dy - (sideHandleHitSize / 2),
            child: _TextBoxHandle(
              visualSize: sideHandleVisualSize,
              hitSize: sideHandleHitSize,
              decorationScale: decorationScale,
              isRound: true,
              color: bottomOverflow ? overflowColor : validColor,
              onPointerDown: onPointerDown,
              onPanStart: onVerticalSidePanStart,
              onPanUpdate: onVerticalSidePanUpdate,
              onPanEnd: onPanEnd,
            ),
          ),
        ],
        cornerResizeHandle(
          center: topRight,
          color: topOverflow || rightOverflow ? overflowColor : validColor,
        ),
        Positioned(
          left: rotateHandleCenter.dx - (rotateHandleHitSize / 2),
          top: rotateHandleCenter.dy - (rotateHandleHitSize / 2),
          child: _TextBoxHandle(
            visualSize: rotateHandleVisualSize,
            hitSize: rotateHandleHitSize,
            decorationScale: decorationScale,
            isRound: true,
            color: topOverflow || rightOverflow ? overflowColor : validColor,
            icon: Icons.rotate_right_rounded,
            onPointerDown: onPointerDown,
            onPanStart: onRotatePanStart,
            onPanUpdate: onRotatePanUpdate,
            onPanEnd: onPanEnd,
          ),
        ),
      ],
    );
  }
}

class _SelectionBoxPainter extends CustomPainter {
  const _SelectionBoxPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.leftColor,
    required this.topColor,
    required this.rightColor,
    required this.bottomColor,
    required this.strokeWidth,
  });

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final Color leftColor;
  final Color topColor;
  final Color rightColor;
  final Color bottomColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(topLeft, topRight, paint..color = topColor);
    canvas.drawLine(topRight, bottomRight, paint..color = rightColor);
    canvas.drawLine(bottomRight, bottomLeft, paint..color = bottomColor);
    canvas.drawLine(bottomLeft, topLeft, paint..color = leftColor);
  }

  @override
  bool shouldRepaint(covariant _SelectionBoxPainter oldDelegate) {
    return topLeft != oldDelegate.topLeft ||
        topRight != oldDelegate.topRight ||
        bottomRight != oldDelegate.bottomRight ||
        bottomLeft != oldDelegate.bottomLeft ||
        leftColor != oldDelegate.leftColor ||
        topColor != oldDelegate.topColor ||
        rightColor != oldDelegate.rightColor ||
        bottomColor != oldDelegate.bottomColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

class _TextBoxHandle extends StatelessWidget {
  const _TextBoxHandle({
    required this.visualSize,
    required this.hitSize,
    required this.decorationScale,
    required this.isRound,
    this.color = const Color(0xFF1A73E8),
    required this.onPointerDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.icon,
  });

  final double visualSize;
  final double hitSize;
  final double decorationScale;
  final bool isRound;
  final Color color;
  final VoidCallback onPointerDown;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPointerDown(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: icon == null ? 0.78 : 0.88),
                shape: isRound ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isRound
                    ? null
                    : BorderRadius.circular(visualSize * 0.32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                  width: 1.1 * decorationScale,
                ),
              ),
              child: SizedBox(
                width: visualSize,
                height: visualSize,
                child: icon == null
                    ? null
                    : Icon(
                        icon,
                        size: visualSize * 0.58,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapGuidesPainter extends CustomPainter {
  const _SnapGuidesPainter({
    required this.showVerticalGuide,
    required this.showHorizontalGuide,
    required this.rotationGuideAngle,
  });

  final bool showVerticalGuide;
  final bool showHorizontalGuide;
  final double? rotationGuideAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    if (showVerticalGuide) {
      final x = size.width / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    if (showHorizontalGuide) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final angle = rotationGuideAngle;
    if (angle != null) {
      final center = Offset(size.width / 2, size.height / 2);
      final length = math.sqrt(
        (size.width * size.width) + (size.height * size.height),
      );
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center - (direction * length),
        center + (direction * length),
        paint
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.9)
          ..strokeWidth = 1.35,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnapGuidesPainter oldDelegate) {
    return oldDelegate.showVerticalGuide != showVerticalGuide ||
        oldDelegate.showHorizontalGuide != showHorizontalGuide ||
        oldDelegate.rotationGuideAngle != rotationGuideAngle;
  }
}

class _CanvasTextLayerView extends StatelessWidget {
  const _CanvasTextLayerView({
    required this.text,
    required this.textColor,
    required this.textAlign,
    required this.fontSize,
    required this.textOpacity,
    required this.fontFamily,
    required this.textLineHeight,
    required this.textLetterSpacing,
    required this.textShadowOpacity,
    required this.textShadowColor,
    required this.textShadowBlur,
    this.textShadowOffsetX = 0,
    required this.textShadowOffsetY,
    this.textOuterGlowColor = Colors.transparent,
    this.textOuterGlowOpacity = 0,
    this.textOuterGlowSize = 0,
    this.textOuterGlowSpread = 0,
    required this.isTextBold,
    required this.isTextItalic,
    required this.isTextUnderline,
    required this.textStrokeColor,
    required this.textStrokeWidth,
    this.textStrokeGradient,
    required this.textBackgroundColor,
    required this.textBackgroundOpacity,
    required this.textBackgroundRadius,
    required this.textBackgroundTopPadding,
    required this.textBackgroundBottomPadding,
    this.maxWidth,
    this.textGradient,
    this.textGradientAngle = 0,
    this.textGradientScale = 100,
  });

  final String text;
  final Color textColor;
  final TextAlign textAlign;
  final double fontSize;
  final double textOpacity;
  final String fontFamily;
  final double textLineHeight;
  final double textLetterSpacing;
  final double textShadowOpacity;
  final Color textShadowColor;
  final double textShadowBlur;
  final double textShadowOffsetX;
  final double textShadowOffsetY;
  final Color textOuterGlowColor;
  final double textOuterGlowOpacity;
  final double textOuterGlowSize;
  final double textOuterGlowSpread;
  final bool isTextBold;
  final bool isTextItalic;
  final bool isTextUnderline;
  final Color textStrokeColor;
  final double textStrokeWidth;
  final List<Color>? textStrokeGradient;
  final Color textBackgroundColor;
  final double textBackgroundOpacity;
  final double textBackgroundRadius;
  final double textBackgroundTopPadding;
  final double textBackgroundBottomPadding;
  final double? maxWidth;
  final List<Color>? textGradient;
  final double textGradientAngle;
  final double textGradientScale;

  @override
  Widget build(BuildContext context) {
    final hasOuterGlow = textOuterGlowOpacity > 0.001;
    final effectiveTextShadowBlur = textShadowBlur.clamp(0.0, 48.0).toDouble();
    final overflowPadding = _textVisualOverflowPadding(
      fontFamily: fontFamily,
      text: text,
      fontSize: fontSize,
      textStrokeWidth: textStrokeWidth,
      textShadowOpacity: textShadowOpacity,
      textShadowBlur: effectiveTextShadowBlur,
      textShadowOffsetX: textShadowOffsetX,
      textShadowOffsetY: textShadowOffsetY,
      isTextUnderline: isTextUnderline,
    );
    final fillForeground = textGradient == null
        ? null
        : (Paint()
            ..shader =
                LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: textGradient!,
                  transform: GradientRotation(
                    textGradientAngle * math.pi / 180,
                  ),
                ).createShader(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width:
                        (fontSize * math.max(text.length, 3)).clamp(
                          fontSize * 2,
                          2400,
                        ) *
                        (textGradientScale / 100).clamp(0.1, 2.0),
                    height:
                        fontSize *
                        math.max(text.split('\n').length, 1) *
                        2.4 *
                        (textGradientScale / 100).clamp(0.1, 2.0),
                  ),
                ));
    final baseStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontSize: fontSize,
      height: _effectiveTextLineHeightForRender(
        fontFamily: fontFamily,
        textLineHeight: textLineHeight,
        text: text,
      ),
      letterSpacing: textLetterSpacing,
      fontWeight: isTextBold ? FontWeight.w700 : FontWeight.w500,
      fontStyle: isTextItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isTextUnderline
          ? TextDecoration.underline
          : TextDecoration.none,
      fontFamily: fontFamily,
      color: fillForeground == null ? textColor : null,
      foreground: fillForeground,
    );

    final shadowText = textShadowOpacity <= 0.001
        ? null
        : Text(
            text,
            textAlign: textAlign,
            textDirection: _textDirectionForValue(text),
            textScaler: TextScaler.noScaling,
            softWrap: true,
            style: TextStyle(
              fontSize: fontSize,
              height: _effectiveTextLineHeightForRender(
                fontFamily: fontFamily,
                textLineHeight: textLineHeight,
                text: text,
              ),
              letterSpacing: textLetterSpacing,
              fontWeight: isTextBold ? FontWeight.w700 : FontWeight.w500,
              fontStyle: isTextItalic ? FontStyle.italic : FontStyle.normal,
              fontFamily: fontFamily,
              color: Colors.transparent,
              shadows: <Shadow>[
                Shadow(
                  color: textShadowColor.withValues(alpha: textShadowOpacity),
                  blurRadius: effectiveTextShadowBlur,
                  offset: Offset(textShadowOffsetX, textShadowOffsetY),
                ),
              ],
            ),
          );

    final glowLayers = !hasOuterGlow
        ? const <Widget>[]
        : <Widget>[
            Opacity(
              opacity: textOuterGlowOpacity.clamp(0.0, 1.0),
              child: ImageFiltered(
                imageFilter: _textOuterGlowFilter(
                  textOuterGlowSize,
                  textOuterGlowSpread,
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    textOuterGlowColor,
                    BlendMode.srcIn,
                  ),
                  child: Text(
                    text,
                    textAlign: textAlign,
                    textDirection: _textDirectionForValue(text),
                    textScaler: TextScaler.noScaling,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: _effectiveTextLineHeightForRender(
                        fontFamily: fontFamily,
                        textLineHeight: textLineHeight,
                        text: text,
                      ),
                      letterSpacing: textLetterSpacing,
                      fontWeight: isTextBold
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontStyle: isTextItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      fontFamily: fontFamily,
                      color: textOuterGlowColor,
                    ),
                  ),
                ),
              ),
            ),
          ];

    final strokeText = textStrokeWidth <= 0.001
        ? null
        : Text(
            text,
            textAlign: textAlign,
            textDirection: _textDirectionForValue(text),
            textScaler: TextScaler.noScaling,
            softWrap: true,
            style: TextStyle(
              fontSize: fontSize,
              height: _effectiveTextLineHeightForRender(
                fontFamily: fontFamily,
                textLineHeight: textLineHeight,
                text: text,
              ),
              letterSpacing: textLetterSpacing,
              fontWeight: isTextBold ? FontWeight.w700 : FontWeight.w500,
              fontStyle: isTextItalic ? FontStyle.italic : FontStyle.normal,
              decoration: isTextUnderline
                  ? TextDecoration.underline
                  : TextDecoration.none,
              fontFamily: fontFamily,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..strokeWidth = textStrokeWidth
                ..color = textStrokeColor
                ..shader = (textStrokeGradient == null
                    ? null
                    : LinearGradient(colors: textStrokeGradient!).createShader(
                        Rect.fromLTWH(
                          0,
                          0,
                          (fontSize * math.max(text.length, 3)).clamp(
                            fontSize * 2,
                            2400,
                          ),
                          fontSize * math.max(text.split('\n').length, 1) * 2.4,
                        ),
                      )),
            ),
          );

    final fillText = Text(
      text,
      textAlign: textAlign,
      textDirection: _textDirectionForValue(text),
      textScaler: TextScaler.noScaling,
      softWrap: true,
      style: baseStyle,
    );

    final textView = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[...glowLayers, ?shadowText, ?strokeText, fillText],
    );

    final constrainedTextView = maxWidth == null
        ? textView
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: textView,
          );

    final hasBackground = textBackgroundOpacity > 0.001;
    final textForeground = Opacity(
      opacity: textOpacity.clamp(0, 1),
      child: constrainedTextView,
    );
    if (!hasBackground) {
      return Padding(padding: overflowPadding, child: textForeground);
    }

    return Padding(
      padding: overflowPadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: textBackgroundColor.withValues(alpha: textBackgroundOpacity),
          borderRadius: BorderRadius.circular(textBackgroundRadius),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            textBackgroundTopPadding.clamp(0, 100).toDouble(),
            12,
            textBackgroundBottomPadding.clamp(0, 100).toDouble(),
          ),
          child: textForeground,
        ),
      ),
    );
  }
}

class _DrawCanvasLiveOverlay extends StatefulWidget {
  const _DrawCanvasLiveOverlay({
    required this.pageSize,
    required this.previewListenable,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final Size pageSize;
  final ValueListenable<_DrawPreviewState?> previewListenable;
  final void Function(Offset localPosition, Size pageSize) onStart;
  final void Function(Offset localPosition, Size pageSize) onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  State<_DrawCanvasLiveOverlay> createState() => _DrawCanvasLiveOverlayState();
}

class _DrawCanvasLiveOverlayState extends State<_DrawCanvasLiveOverlay> {
  final Set<int> _activePointers = <int>{};
  bool _suppressStroke = false;

  bool get _canStroke => !_suppressStroke && _activePointers.length <= 1;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    if (_activePointers.length > 1) {
      _suppressStroke = true;
      widget.onCancel();
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) {
      _suppressStroke = false;
      widget.onEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (!_canStroke) {
            return;
          }
          widget.onStart(details.localPosition, widget.pageSize);
          widget.onEnd();
        },
        onPanStart: (details) {
          if (_canStroke) {
            widget.onStart(details.localPosition, widget.pageSize);
          }
        },
        onPanUpdate: (details) {
          if (_canStroke) {
            widget.onUpdate(details.localPosition, widget.pageSize);
          }
        },
        onPanEnd: (_) => widget.onEnd(),
        onPanCancel: widget.onEnd,
        child: ClipRect(
          child: ValueListenableBuilder<_DrawPreviewState?>(
            valueListenable: widget.previewListenable,
            builder:
                (
                  BuildContext context,
                  _DrawPreviewState? preview,
                  Widget? child,
                ) {
                  if (preview == null || preview.strokes.isEmpty) {
                    return const SizedBox.expand();
                  }
                  return CustomPaint(
                    painter: _DrawStrokesPainter(
                      strokes: preview.strokes,
                      brushMasks: preview.brushMasks,
                    ),
                    size: Size.infinite,
                  );
                },
          ),
        ),
      ),
    );
  }
}

enum _TextToolTab { color, size, alignment, style, background }
