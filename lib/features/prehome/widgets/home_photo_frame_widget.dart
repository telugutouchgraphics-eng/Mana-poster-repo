// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _PhotoShapeFrame extends StatelessWidget {
  const _PhotoShapeFrame({
    required this.shape,
    required this.child,
    required this.edgeStyle,
    required this.photoRenderMode,
    required this.isBusinessLogo,
  });

  final String shape;
  final Widget child;
  final String edgeStyle;
  final String photoRenderMode;
  final bool isBusinessLogo;

  bool _isTransparentPhotoShape(String currentShape) {
    return currentShape == 'transparent_bottom_fade' ||
        currentShape == 'transparent_clean' ||
        currentShape == 'transparent_soft_round' ||
        currentShape == 'transparent_sharp_round';
  }

  bool _isOriginalCleanShape(String currentShape) {
    return currentShape == 'circle' || currentShape == 'square';
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

  String _resolvedEdgeStyle(String currentShape, String currentEdgeStyle) {
    if (currentShape == 'transparent_bottom_fade') {
      return 'bottom_fade';
    }
    if (currentShape == 'transparent_soft_round') {
      return currentEdgeStyle == 'bottom_fade' || currentEdgeStyle == 'feather'
          ? currentEdgeStyle
          : 'feather';
    }
    if (currentShape == 'transparent_clean' ||
        currentShape == 'transparent_sharp_round') {
      return 'sharp';
    }
    return currentEdgeStyle;
  }

  String _normalizedEdgeStyle(String currentEdgeStyle) {
    return currentEdgeStyle == 'soft_fade' ? 'bottom_fade' : currentEdgeStyle;
  }

  BoxDecoration _outerDecorationForShape(String currentShape) {
    if (_isTransparentPhotoShape(currentShape)) {
      return const BoxDecoration(color: Colors.transparent);
    }
    switch (currentShape) {
      case 'circle':
        return BoxDecoration(color: Colors.transparent, shape: BoxShape.circle);
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
      case 'flower':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFFB7185), Color(0xFFF59E0B)],
          ),
        );
      case 'shield':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF1D4ED8), Color(0xFF60A5FA)],
          ),
        );
      case 'arch':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF0F766E), Color(0xFF38BDF8)],
          ),
        );
      case 'blob':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF7C3AED), Color(0xFFF472B6)],
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
        return const BoxDecoration(color: Colors.transparent);
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

  Alignment _cutoutAlignmentForShape(String currentShape) {
    switch (_resolvedShape(currentShape)) {
      case 'flower':
        return const Alignment(0, 0.24);
      case 'scallop_circle':
      case 'soft_burst':
        return const Alignment(0, 0.2);
      case 'blob':
        return const Alignment(0, 0.1);
      case 'shield':
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

  _ShapeFramePreset _presetForShape(String currentShape) {
    switch (currentShape) {
      case 'circle':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'scallop_circle':
        return const _ShapeFramePreset(photoInset: EdgeInsets.all(7));
      case 'soft_burst':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'square':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'arch':
        return const _ShapeFramePreset(
          photoInset: EdgeInsets.fromLTRB(8, 10, 8, 8),
        );
      case 'flower':
        return const _ShapeFramePreset(photoInset: EdgeInsets.all(6));
      case 'shield':
        return const _ShapeFramePreset(
          photoInset: EdgeInsets.fromLTRB(8, 10, 8, 6),
        );
      case 'blob':
        return const _ShapeFramePreset(photoInset: EdgeInsets.all(5));
      case 'vertical_rectangle':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'rounded':
      case 'rounded_square':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      case 'custom_frame_fit':
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
      default:
        return const _ShapeFramePreset(photoInset: EdgeInsets.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldDeferHeavyEffects =
        Scrollable.recommendDeferredLoadingForContext(context);
    final effectivePhotoRenderMode = isBusinessLogo
        ? 'original'
        : (_isTransparentPhotoShape(shape) ? 'cutout' : photoRenderMode);
    final effectiveEdgeStyle = _resolvedEdgeStyle(
      shape,
      isBusinessLogo ? 'clean' : edgeStyle,
    );
    final normalizedEdgeStyle = _normalizedEdgeStyle(effectiveEdgeStyle);
    final shouldForceCleanOriginal =
        effectivePhotoRenderMode == 'original' && _isOriginalCleanShape(shape);
    final imageAlignment = effectivePhotoRenderMode == 'cutout'
        ? _cutoutAlignmentForShape(shape)
        : Alignment.center;
    final mainImageScale = effectivePhotoRenderMode == 'cutout' ? 1.035 : 1.0;
    final blurImageScale = effectivePhotoRenderMode == 'cutout' ? 1.07 : 1.04;

    Widget buildImageLayer({required double scale, required bool isBlurLayer}) {
      Widget layer = DecoratedBox(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: imageAlignment,
          child: SizedBox.square(dimension: 100, child: child),
        ),
      );
      if (effectivePhotoRenderMode == 'cutout') {
        layer = Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: layer,
        );
      }
      if (shouldForceCleanOriginal) {
        return layer;
      }
      if (shape == 'transparent_soft_round') {
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const RadialGradient(
              center: Alignment(0, -0.6),
              radius: 0.92,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xFAFFFFFF),
                Color(0xDBFFFFFF),
                Color(0x8FFFFFFF),
                Color(0x38FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.58, 0.68, 0.77, 0.86, 0.93, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
        layer = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0xE6FFFFFF),
                Color(0x99FFFFFF),
                Color(0x33FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.64, 0.76, 0.86, 0.94, 1.0],
            ).createShader(bounds);
          },
          child: layer,
        );
      } else if (normalizedEdgeStyle == 'feather') {
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
        if (isBlurLayer && !shouldDeferHeavyEffects) {
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

    Widget imageWidget;
    if (effectivePhotoRenderMode == 'cutout' && !isBusinessLogo) {
      if (normalizedEdgeStyle == 'feather' &&
          shape != 'transparent_soft_round' &&
          !shouldDeferHeavyEffects) {
        imageWidget = Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: buildImageLayer(scale: blurImageScale, isBlurLayer: true),
            ),
            Positioned.fill(
              child: buildImageLayer(scale: mainImageScale, isBlurLayer: false),
            ),
          ],
        );
      } else {
        imageWidget = buildImageLayer(
          scale: mainImageScale,
          isBlurLayer: false,
        );
      }
    } else {
      imageWidget = buildImageLayer(scale: 1.0, isBlurLayer: false);
    }

    if (isBusinessLogo) {
      return ClipOval(clipBehavior: Clip.antiAlias, child: imageWidget);
    }

    final preset = _presetForShape(shape);
    final photoLayer = Padding(
      padding: preset.photoInset,
      child: _isTransparentRoundShape(shape)
          ? _clipPhotoShape(_resolvedShape(shape), imageWidget)
          : _isTransparentPhotoShape(shape)
          ? ClipRect(clipBehavior: Clip.antiAlias, child: imageWidget)
          : _clipPhotoShape(shape, imageWidget),
    );
    final framedChild = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (!_isTransparentPhotoShape(shape))
          _clipPhotoShape(
            shape,
            DecoratedBox(decoration: _outerDecorationForShape(shape)),
          ),
        photoLayer,
      ],
    );

    if (_isTransparentRoundShape(shape)) {
      return ClipOval(clipBehavior: Clip.antiAlias, child: framedChild);
    }

    if (_isTransparentPhotoShape(shape)) {
      return framedChild;
    }

    switch (shape) {
      case 'circle':
        return ClipOval(clipBehavior: Clip.antiAlias, child: framedChild);
      case 'rounded':
      case 'rounded_square':
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'pill':
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'oval':
        return ClipOval(clipBehavior: Clip.antiAlias, child: framedChild);
      case 'hexagon':
        return ClipPath(
          clipper: const _PosterMaskClipper('hexagon'),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
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
          clipper: _PosterMaskClipper(shape),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'custom_screen_fit':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'custom_board_fit':
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'custom_frame_fit':
      case 'vertical_rectangle':
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: framedChild,
        );
      case 'square':
      default:
        return framedChild;
    }
  }
}

class _ShapeFramePreset {
  const _ShapeFramePreset({required this.photoInset});

  final EdgeInsets photoInset;
}

Widget _clipPhotoShape(String shape, Widget child) {
  switch (shape) {
    case 'circle':
    case 'oval':
      return ClipOval(clipBehavior: Clip.antiAlias, child: child);
    case 'rounded':
    case 'rounded_square':
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'pill':
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'custom_screen_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'custom_board_fit':
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'custom_frame_fit':
    case 'vertical_rectangle':
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
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
        clipper: _PosterMaskClipper(shape),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    case 'square':
    default:
      return ClipRect(clipBehavior: Clip.antiAlias, child: child);
  }
}

double _photoMaskAspectRatio(String shape) {
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

Path _buildRadialMaskPath(
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

Path _buildSmoothRadialMaskPath(
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

class _PosterMaskClipper extends CustomClipper<Path> {
  const _PosterMaskClipper(this.shape);

  final String shape;

  @override
  Path getClip(Size size) {
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);
    switch (shape) {
      case 'scallop_circle':
        return _buildSmoothRadialMaskPath(
          size,
          pointCount: 16,
          innerRadiusFactor: 0.9,
        );
      case 'soft_burst':
        return _buildRadialMaskPath(
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
          ..moveTo(p(0.55, 0.02).dx, p(0.55, 0.02).dy)
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
        return _buildSmoothRadialMaskPath(
          size,
          pointCount: 8,
          innerRadiusFactor: 0.74,
        );
      case 'badge':
        return _buildSmoothRadialMaskPath(
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
        return _buildRadialMaskPath(
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
  bool shouldReclip(covariant _PosterMaskClipper oldClipper) =>
      oldClipper.shape != shape;
}

