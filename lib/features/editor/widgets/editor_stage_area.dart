import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:mana_poster/features/editor/controllers/editor_controller.dart';
import 'package:mana_poster/features/editor/models/editor_stage.dart';
import 'package:mana_poster/features/editor/models/editor_text.dart';
import 'package:mana_poster/features/editor/utils/editor_image_source.dart';

class EditorStageArea extends StatelessWidget {
  const EditorStageArea({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        controller.setStageSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );

        return GestureDetector(
          onTap:
              controller.isDrawSessionActive || controller.isAnyLayerInteracting
              ? null
              : controller.clearOverlaySelection,
          onScaleStart: controller.onScaleStart,
          onScaleUpdate: controller.onScaleUpdate,
          onScaleEnd: controller.onScaleEnd,
          onDoubleTap: controller.resetMainSurfaceTransform,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final overlayNodes = <_OverlayLayerNode>[
                ...controller.extraPhotoLayers
                    .where((layer) => layer.isVisible)
                    .map((layer) => _OverlayLayerNode.photo(layer)),
                ...controller.elementLayers
                    .where((layer) => layer.isVisible)
                    .map((layer) => _OverlayLayerNode.element(layer)),
                ...controller.stickerLayers
                    .where((layer) => layer.isVisible)
                    .map((layer) => _OverlayLayerNode.sticker(layer)),
                ...controller.shapeLayers
                    .where((layer) => layer.isVisible)
                    .map((layer) => _OverlayLayerNode.shape(layer)),
                ...controller.drawLayers
                    .where((layer) => layer.isVisible)
                    .map((layer) => _OverlayLayerNode.draw(layer)),
                ...controller.textLayers
                    .where((layer) => layer.isVisible)
                    .map((layer) => _OverlayLayerNode.text(layer)),
              ]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

              return SizedBox.expand(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _StageBackground(
                      background: controller.stageBackground,
                      isTransparentExport:
                          controller.isStageExportMode &&
                          controller.exportTransparentBackground,
                    ),
                    if (controller
                        .stageBackground
                        .posterDecoration
                        .hasDecoration)
                      IgnorePointer(
                        child: _DecorationOverlay(
                          decoration:
                              controller.stageBackground.posterDecoration,
                          framePresetResolver: controller.framePresets,
                          isPosterOverlay: true,
                        ),
                      ),
                    if (controller.mainSurfacePhoto != null)
                      Center(
                        child: Transform.translate(
                          offset: controller.mainSurfaceOffset,
                          child: Transform.rotate(
                            angle: controller.mainSurfaceRotation,
                            child: Transform.scale(
                              scaleX: controller.mainSurfacePhoto!.visuals.flipX
                                  ? -controller.mainSurfaceScale
                                  : controller.mainSurfaceScale,
                              scaleY: controller.mainSurfacePhoto!.visuals.flipY
                                  ? -controller.mainSurfaceScale
                                  : controller.mainSurfaceScale,
                              child: SizedBox(
                                width: controller.mainSurfaceFitSize.width,
                                height: controller.mainSurfaceFitSize.height,
                                child: _LayerVisualWrapper(
                                  visuals: controller.mainSurfacePhoto!.visuals,
                                  child: _PhotoCanvasGestureLayer(
                                    isActive:
                                        controller.isRemoveBgRefineActive &&
                                        controller.isMainSurfaceSelected,
                                    onPanStart:
                                        controller.startRemoveBgRefineStroke,
                                    onPanUpdate:
                                        controller.appendRemoveBgRefineStroke,
                                    onPanEnd:
                                        controller.endRemoveBgRefineStroke,
                                    child: RotatedBox(
                                      quarterTurns:
                                          controller.mainSurfaceCropTurns,
                                      child: _PhotoLayerImage(
                                        imageUrl: controller
                                            .mainSurfacePhoto!
                                            .imageUrl,
                                        adjustments: controller
                                            .mainSurfacePhoto!
                                            .adjustments,
                                        filter:
                                            controller.mainSurfacePhoto!.filter,
                                        removeBgState: controller
                                            .mainSurfacePhoto!
                                            .removeBgState,
                                        fit:
                                            controller.mainSurfaceCropRatio ==
                                                null
                                            ? BoxFit.contain
                                            : BoxFit.cover,
                                        alignment: Alignment.center,
                                        decoration: controller
                                            .mainSurfacePhoto!
                                            .decoration,
                                        framePresets: controller.framePresets,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Text(
                          'ఫోటో చేర్చండి\n(మొదటి ఫోటో స్టేజ్ సర్ఫేస్ అవుతుంది)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ...overlayNodes.map((node) {
                      if (node.photoLayer != null) {
                        final layer = node.photoLayer!;
                        return _ExtraPhotoLayerWidget(
                          layer: layer,
                          isSelected:
                              !controller.isStageExportMode &&
                              controller.selectedExtraPhotoLayerId == layer.id,
                          onTap: () =>
                              controller.selectExtraPhotoLayer(layer.id),
                          onScaleStart: (details) => controller
                              .onExtraPhotoScaleStart(layer.id, details),
                          onScaleUpdate: (details) => controller
                              .onExtraPhotoScaleUpdate(layer.id, details),
                          onScaleEnd: (details) => controller
                              .onExtraPhotoScaleEnd(layer.id, details),
                          isRemoveBgRefineActive:
                              controller.isRemoveBgRefineActive &&
                              controller.selectedExtraPhotoLayerId == layer.id,
                          onRefinePanStart:
                              controller.startRemoveBgRefineStroke,
                          onRefinePanUpdate:
                              controller.appendRemoveBgRefineStroke,
                          onRefinePanEnd: controller.endRemoveBgRefineStroke,
                          framePresets: controller.framePresets,
                        );
                      }
                      if (node.elementLayer != null) {
                        final layer = node.elementLayer!;
                        return _ElementLayerWidget(
                          layer: layer,
                          isSelected:
                              !controller.isStageExportMode &&
                              controller.selectedElementLayerId == layer.id,
                          onTap: () => controller.selectElementLayer(layer.id),
                          onScaleStart: (details) =>
                              controller.onElementScaleStart(layer.id, details),
                          onScaleUpdate: (details) => controller
                              .onElementScaleUpdate(layer.id, details),
                          onScaleEnd: (details) =>
                              controller.onElementScaleEnd(layer.id, details),
                        );
                      }
                      if (node.stickerLayer != null) {
                        final layer = node.stickerLayer!;
                        return _StickerLayerWidget(
                          layer: layer,
                          isSelected:
                              !controller.isStageExportMode &&
                              controller.selectedStickerLayerId == layer.id,
                          onTap: () => controller.selectStickerLayer(layer.id),
                          onScaleStart: (details) =>
                              controller.onStickerScaleStart(layer.id, details),
                          onScaleUpdate: (details) => controller
                              .onStickerScaleUpdate(layer.id, details),
                          onScaleEnd: (details) =>
                              controller.onStickerScaleEnd(layer.id, details),
                        );
                      }
                      if (node.shapeLayer != null) {
                        final layer = node.shapeLayer!;
                        return _ShapeLayerWidget(
                          layer: layer,
                          isSelected:
                              !controller.isStageExportMode &&
                              controller.selectedShapeLayerId == layer.id,
                          onTap: () => controller.selectShapeLayer(layer.id),
                          onScaleStart: (details) =>
                              controller.onShapeScaleStart(layer.id, details),
                          onScaleUpdate: (details) =>
                              controller.onShapeScaleUpdate(layer.id, details),
                          onScaleEnd: (details) =>
                              controller.onShapeScaleEnd(layer.id, details),
                        );
                      }
                      if (node.drawLayer != null) {
                        final layer = node.drawLayer!;
                        return _DrawLayerWidget(
                          layer: layer,
                          isSelected:
                              !controller.isStageExportMode &&
                              controller.selectedDrawLayerId == layer.id,
                        );
                      }
                      final layer = node.textLayer!;
                      return _TextLayerWidget(
                        layer: layer,
                        isSelected:
                            !controller.isStageExportMode &&
                            controller.selectedTextLayerId == layer.id,
                        onTap: () => controller.selectTextLayer(layer.id),
                        onDoubleTap: () =>
                            controller.requestFullScreenTextEditor(layer.id),
                        onScaleStart: (details) =>
                            controller.onTextScaleStart(layer.id, details),
                        onScaleUpdate: (details) =>
                            controller.onTextScaleUpdate(layer.id, details),
                        onScaleEnd: (_) =>
                            controller.completeTextLayerTransform(layer.id),
                      );
                    }),
                    if (controller.drawDraftStrokes.isNotEmpty)
                      IgnorePointer(
                        child: _DrawSessionPreview(
                          strokes: controller.drawDraftStrokes,
                        ),
                      ),
                    if (controller.isDrawSessionActive)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) => controller.beginDrawStroke(
                            _normalizePoint(
                              details.localPosition,
                              constraints.biggest,
                            ),
                          ),
                          onPanUpdate: (details) =>
                              controller.appendDrawStrokePoint(
                                _normalizePoint(
                                  details.localPosition,
                                  constraints.biggest,
                                ),
                              ),
                          onPanEnd: (_) => controller.endDrawStroke(),
                          onPanCancel: controller.endDrawStroke,
                        ),
                      ),
                    if (controller.smartGuides.enabled &&
                        !controller.isStageExportMode)
                      IgnorePointer(
                        child: _GuideOverlay(
                          showVertical: controller.showVerticalGuide,
                          showHorizontal: controller.showHorizontalGuide,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Offset _normalizePoint(Offset point, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return const Offset(0.5, 0.5);
    }
    return Offset(point.dx / size.width, point.dy / size.height);
  }
}

class _OverlayLayerNode {
  _OverlayLayerNode.photo(StagePhotoLayer layer)
    : photoLayer = layer,
      shapeLayer = null,
      drawLayer = null,
      stickerLayer = null,
      elementLayer = null,
      textLayer = null,
      zIndex = layer.zIndex;

  _OverlayLayerNode.element(StageElementLayer layer)
    : elementLayer = layer,
      shapeLayer = null,
      drawLayer = null,
      stickerLayer = null,
      photoLayer = null,
      textLayer = null,
      zIndex = layer.zIndex;

  _OverlayLayerNode.text(EditorTextLayer layer)
    : textLayer = layer,
      shapeLayer = null,
      drawLayer = null,
      stickerLayer = null,
      elementLayer = null,
      photoLayer = null,
      zIndex = layer.zIndex;

  _OverlayLayerNode.sticker(StageStickerLayer layer)
    : stickerLayer = layer,
      shapeLayer = null,
      drawLayer = null,
      textLayer = null,
      elementLayer = null,
      photoLayer = null,
      zIndex = layer.zIndex;

  _OverlayLayerNode.draw(StageDrawLayer layer)
    : drawLayer = layer,
      shapeLayer = null,
      stickerLayer = null,
      textLayer = null,
      elementLayer = null,
      photoLayer = null,
      zIndex = layer.zIndex;

  _OverlayLayerNode.shape(StageShapeLayer layer)
    : shapeLayer = layer,
      drawLayer = null,
      stickerLayer = null,
      textLayer = null,
      elementLayer = null,
      photoLayer = null,
      zIndex = layer.zIndex;

  final StagePhotoLayer? photoLayer;
  final StageElementLayer? elementLayer;
  final StageStickerLayer? stickerLayer;
  final StageShapeLayer? shapeLayer;
  final StageDrawLayer? drawLayer;
  final EditorTextLayer? textLayer;
  final int zIndex;
}

class _DrawLayerWidget extends StatelessWidget {
  const _DrawLayerWidget({required this.layer, required this.isSelected});

  final StageDrawLayer layer;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: _LayerVisualWrapper(
          visuals: layer.visuals,
          child: CustomPaint(
            painter: _DrawStrokesPainter(
              strokes: layer.strokes,
              showSelectionOutline: isSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawSessionPreview extends StatelessWidget {
  const _DrawSessionPreview({required this.strokes});

  final List<DrawStroke> strokes;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _DrawStrokesPainter(strokes: strokes)),
    );
  }
}

class _DrawStrokesPainter extends CustomPainter {
  _DrawStrokesPainter({
    required this.strokes,
    this.showSelectionOutline = false,
  });

  final List<DrawStroke> strokes;
  final bool showSelectionOutline;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, size, stroke);
    }
    if (showSelectionOutline) {
      final paint = Paint()
        ..color = const Color(0x332563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  void _paintStroke(Canvas canvas, Size size, DrawStroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }
    final points = stroke.points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);

    if (stroke.mode == DrawToolMode.eraser) {
      canvas.saveLayer(Offset.zero & size, Paint());
      final erasePaint = Paint()
        ..blendMode = BlendMode.clear
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = (stroke.size * size.shortestSide).clamp(6.0, 64.0);
      final path = _buildSmoothPath(points);
      if (points.length == 1) {
        canvas.drawCircle(points.first, erasePaint.strokeWidth / 2, erasePaint);
      } else {
        canvas.drawPath(path, erasePaint);
      }
      canvas.restore();
      return;
    }

    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = (stroke.size * size.shortestSide).clamp(2.0, 44.0);

    switch (stroke.style) {
      case DrawBrushStyle.smoothPen:
        break;
      case DrawBrushStyle.softBrush:
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.4);
      case DrawBrushStyle.neonHighlighter:
        paint
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2)
          ..strokeWidth = (paint.strokeWidth * 1.35).clamp(4.0, 60.0);
      case DrawBrushStyle.dottedLine:
        _paintDotted(canvas, points, paint);
        return;
    }

    final path = _buildSmoothPath(points);
    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length < 2) {
      return path;
    }
    for (var i = 1; i < points.length - 1; i += 1) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  void _paintDotted(Canvas canvas, List<Offset> points, Paint paint) {
    final radius = (paint.strokeWidth / 2).clamp(1.0, 16.0);
    for (final point in points) {
      canvas.drawCircle(point, radius, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawStrokesPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.showSelectionOutline != showSelectionOutline;
  }
}

class _ExtraPhotoLayerWidget extends StatelessWidget {
  const _ExtraPhotoLayerWidget({
    required this.layer,
    required this.isSelected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.isRemoveBgRefineActive,
    required this.onRefinePanStart,
    required this.onRefinePanUpdate,
    required this.onRefinePanEnd,
    required this.framePresets,
  });

  final StagePhotoLayer layer;
  final bool isSelected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;
  final bool isRemoveBgRefineActive;
  final ValueChanged<Offset> onRefinePanStart;
  final ValueChanged<Offset> onRefinePanUpdate;
  final VoidCallback onRefinePanEnd;
  final List<FramePresetConfig> framePresets;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: layer.offset,
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scaleX: layer.visuals.flipX ? -layer.scale : layer.scale,
            scaleY: layer.visuals.flipY ? -layer.scale : layer.scale,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              onScaleStart: layer.isLocked || isRemoveBgRefineActive
                  ? null
                  : onScaleStart,
              onScaleUpdate: layer.isLocked || isRemoveBgRefineActive
                  ? null
                  : onScaleUpdate,
              onScaleEnd: layer.isLocked || isRemoveBgRefineActive
                  ? null
                  : onScaleEnd,
              onPanStart: layer.isLocked || !isRemoveBgRefineActive
                  ? null
                  : (details) => onRefinePanStart(
                      _normalizePoint(details.localPosition),
                    ),
              onPanUpdate: layer.isLocked || !isRemoveBgRefineActive
                  ? null
                  : (details) => onRefinePanUpdate(
                      _normalizePoint(details.localPosition),
                    ),
              onPanEnd: layer.isLocked || !isRemoveBgRefineActive
                  ? null
                  : (_) => onRefinePanEnd(),
              onPanCancel: layer.isLocked || !isRemoveBgRefineActive
                  ? null
                  : onRefinePanEnd,
              child: Container(
                width: layer.size.width,
                height: layer.size.height,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: const Color(0x662563EB), width: 1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: _LayerVisualWrapper(
                  visuals: layer.visuals,
                  child: RotatedBox(
                    quarterTurns: layer.cropTurns,
                    child: _PhotoLayerImage(
                      imageUrl: layer.imageUrl,
                      adjustments: layer.adjustments,
                      filter: layer.filter,
                      removeBgState: layer.removeBgState,
                      fit: layer.cropRatio == null
                          ? BoxFit.contain
                          : BoxFit.cover,
                      decoration: layer.decoration,
                      framePresets: framePresets,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _normalizePoint(Offset point) {
    if (layer.size.width <= 0 || layer.size.height <= 0) {
      return const Offset(0.5, 0.5);
    }
    return Offset(point.dx / layer.size.width, point.dy / layer.size.height);
  }
}

class _ElementLayerWidget extends StatelessWidget {
  const _ElementLayerWidget({
    required this.layer,
    required this.isSelected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final StageElementLayer layer;
  final bool isSelected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: layer.offset,
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scaleX: layer.visuals.flipX ? -layer.scale : layer.scale,
            scaleY: layer.visuals.flipY ? -layer.scale : layer.scale,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              onScaleStart: layer.isLocked ? null : onScaleStart,
              onScaleUpdate: layer.isLocked ? null : onScaleUpdate,
              onScaleEnd: layer.isLocked ? null : onScaleEnd,
              child: Container(
                width: layer.size.width,
                height: layer.size.height,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: const Color(0x552563EB), width: 1)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: _LayerVisualWrapper(
                  visuals: layer.visuals,
                  child: buildEditorImage(layer.assetUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeLayerWidget extends StatelessWidget {
  const _ShapeLayerWidget({
    required this.layer,
    required this.isSelected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final StageShapeLayer layer;
  final bool isSelected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: layer.offset,
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scaleX: layer.visuals.flipX ? -layer.scale : layer.scale,
            scaleY: layer.visuals.flipY ? -layer.scale : layer.scale,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              onScaleStart: layer.isLocked ? null : onScaleStart,
              onScaleUpdate: layer.isLocked ? null : onScaleUpdate,
              onScaleEnd: layer.isLocked ? null : onScaleEnd,
              child: SizedBox(
                width: layer.size.width,
                height: layer.size.height,
                child: _LayerVisualWrapper(
                  visuals: layer.visuals,
                  child: CustomPaint(
                    painter: _ShapeLayerPainter(
                      layer: layer,
                      showSelectionOutline: isSelected,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeLayerPainter extends CustomPainter {
  _ShapeLayerPainter({required this.layer, required this.showSelectionOutline});

  final StageShapeLayer layer;
  final bool showSelectionOutline;

  @override
  void paint(Canvas canvas, Size size) {
    final shapePath = _shapePath(size, layer.kind, layer.cornerRadius);
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final clampedOpacity = layer.opacity.clamp(0.0, 1.0);

    if (layer.useGradientFill && layer.gradientColors.length >= 2) {
      fillPaint.shader = LinearGradient(
        colors: layer.gradientColors
            .map((color) => color.withValues(alpha: color.a * clampedOpacity))
            .toList(growable: false),
      ).createShader(Offset.zero & size);
    } else {
      fillPaint.color = layer.fillColor.withValues(alpha: clampedOpacity);
    }

    if (layer.kind == ShapeKind.line) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = _lineStrokeWidth(size, layer)
        ..color = layer.useGradientFill && layer.gradientColors.length >= 2
            ? layer.gradientColors.first.withValues(alpha: clampedOpacity)
            : layer.fillColor.withValues(alpha: clampedOpacity);
      canvas.drawPath(shapePath, strokePaint);
    } else {
      canvas.drawPath(shapePath, fillPaint);
    }

    if (layer.strokeWidth > 0.001 && layer.kind != ShapeKind.line) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outlineStrokeWidth(size, layer.strokeWidth)
        ..color = layer.strokeColor.withValues(alpha: clampedOpacity);
      canvas.drawPath(shapePath, strokePaint);
    }

    if (showSelectionOutline) {
      final selectionPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x552563EB);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
        selectionPaint,
      );
    }
  }

  Path _shapePath(Size size, ShapeKind kind, double cornerRadius) {
    final rect = Offset.zero & size;
    switch (kind) {
      case ShapeKind.rectangle:
        return Path()..addRect(rect);
      case ShapeKind.roundedRectangle:
        final radius = Radius.circular(
          (size.shortestSide * cornerRadius).clamp(4.0, size.shortestSide / 2),
        );
        return Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
      case ShapeKind.circle:
        final radius = size.shortestSide / 2;
        return Path()
          ..addOval(Rect.fromCircle(center: rect.center, radius: radius));
      case ShapeKind.oval:
        return Path()..addOval(rect);
      case ShapeKind.line:
        return Path()
          ..moveTo(rect.left, rect.center.dy)
          ..lineTo(rect.right, rect.center.dy);
      case ShapeKind.triangle:
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case ShapeKind.polygon:
        return _regularPolygonPath(rect.center, size.shortestSide / 2, 6);
      case ShapeKind.star:
        return _starPath(rect.center, size.shortestSide / 2, 5);
      case ShapeKind.heart:
        return _heartPath(rect);
      case ShapeKind.arrow:
        return _arrowPath(rect);
    }
  }

  Path _regularPolygonPath(Offset center, double radius, int sides) {
    final path = Path();
    for (var i = 0; i < sides; i += 1) {
      final angle = (-math.pi / 2) + (2 * math.pi * i / sides);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _starPath(Offset center, double radius, int points) {
    final innerRadius = radius * 0.45;
    final path = Path();
    for (var i = 0; i < points * 2; i += 1) {
      final useOuter = i.isEven;
      final r = useOuter ? radius : innerRadius;
      final angle = (-math.pi / 2) + (math.pi * i / points);
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _heartPath(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final x = rect.left;
    final y = rect.top;
    return Path()
      ..moveTo(x + w * 0.5, y + h * 0.88)
      ..cubicTo(
        x + w * 0.08,
        y + h * 0.62,
        x + w * 0.06,
        y + h * 0.26,
        x + w * 0.3,
        y + h * 0.2,
      )
      ..cubicTo(
        x + w * 0.44,
        y + h * 0.17,
        x + w * 0.5,
        y + h * 0.27,
        x + w * 0.5,
        y + h * 0.27,
      )
      ..cubicTo(
        x + w * 0.5,
        y + h * 0.27,
        x + w * 0.56,
        y + h * 0.17,
        x + w * 0.7,
        y + h * 0.2,
      )
      ..cubicTo(
        x + w * 0.94,
        y + h * 0.26,
        x + w * 0.92,
        y + h * 0.62,
        x + w * 0.5,
        y + h * 0.88,
      )
      ..close();
  }

  Path _arrowPath(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final shaftH = h * 0.34;
    final shaftTop = rect.center.dy - (shaftH / 2);
    final shaftBottom = rect.center.dy + (shaftH / 2);
    return Path()
      ..moveTo(rect.left, shaftTop)
      ..lineTo(rect.left + w * 0.62, shaftTop)
      ..lineTo(rect.left + w * 0.62, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.left + w * 0.62, rect.bottom)
      ..lineTo(rect.left + w * 0.62, shaftBottom)
      ..lineTo(rect.left, shaftBottom)
      ..close();
  }

  double _outlineStrokeWidth(Size size, double value) {
    return (size.shortestSide * value).clamp(1.0, 24.0);
  }

  double _lineStrokeWidth(Size size, StageShapeLayer layer) {
    final base = _outlineStrokeWidth(
      size,
      layer.strokeWidth <= 0 ? 0.08 : layer.strokeWidth,
    );
    return base.clamp(2.0, 30.0);
  }

  @override
  bool shouldRepaint(covariant _ShapeLayerPainter oldDelegate) {
    return oldDelegate.layer != layer ||
        oldDelegate.showSelectionOutline != showSelectionOutline;
  }
}

class _PhotoCanvasGestureLayer extends StatelessWidget {
  const _PhotoCanvasGestureLayer({
    required this.isActive,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.child,
  });

  final bool isActive;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) =>
          onPanStart(_normalize(details.localPosition, context)),
      onPanUpdate: (details) =>
          onPanUpdate(_normalize(details.localPosition, context)),
      onPanEnd: (_) => onPanEnd(),
      onPanCancel: onPanEnd,
      child: child,
    );
  }

  Offset _normalize(Offset point, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? Size.zero;
    if (size.width <= 0 || size.height <= 0) {
      return const Offset(0.5, 0.5);
    }
    return Offset(point.dx / size.width, point.dy / size.height);
  }
}

class _PhotoLayerImage extends StatefulWidget {
  const _PhotoLayerImage({
    required this.imageUrl,
    required this.adjustments,
    required this.filter,
    required this.removeBgState,
    required this.fit,
    required this.decoration,
    required this.framePresets,
    this.alignment = Alignment.center,
  });

  final String imageUrl;
  final PhotoAdjustments adjustments;
  final PhotoFilterConfig filter;
  final RemoveBgState removeBgState;
  final BoxFit fit;
  final DecorationStyleConfig decoration;
  final List<FramePresetConfig> framePresets;
  final Alignment alignment;

  @override
  State<_PhotoLayerImage> createState() => _PhotoLayerImageState();
}

class _PhotoLayerImageState extends State<_PhotoLayerImage> {
  ImageStream? _imageStream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _PhotoLayerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return buildEditorImage(
        widget.imageUrl,
        fit: widget.fit,
        alignment: widget.alignment,
      );
    }

    return CustomPaint(
      painter: _PhotoLayerPainter(
        image: _image!,
        adjustments: widget.adjustments,
        filter: widget.filter,
        removeBgState: widget.removeBgState,
        fit: widget.fit,
        alignment: widget.alignment,
        decoration: widget.decoration,
        framePresets: widget.framePresets,
      ),
      child: const SizedBox.expand(),
    );
  }

  void _resolveImage() {
    _removeImageListener();
    final provider = editorImageProvider(widget.imageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    _imageStream = stream;
    _listener = ImageStreamListener((info, _) {
      if (!mounted) {
        return;
      }
      setState(() {
        _image = info.image;
      });
    });
    stream.addListener(_listener!);
  }

  void _removeImageListener() {
    final stream = _imageStream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _listener = null;
  }
}

class _PhotoLayerPainter extends CustomPainter {
  _PhotoLayerPainter({
    required this.image,
    required this.adjustments,
    required this.filter,
    required this.removeBgState,
    required this.fit,
    required this.alignment,
    required this.decoration,
    required this.framePresets,
  });

  final ui.Image image;
  final PhotoAdjustments adjustments;
  final PhotoFilterConfig filter;
  final RemoveBgState removeBgState;
  final BoxFit fit;
  final Alignment alignment;
  final DecorationStyleConfig decoration;
  final List<FramePresetConfig> framePresets;

  @override
  void paint(Canvas canvas, Size size) {
    final outputRect = Offset.zero & size;
    final inputSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(fit, inputSize, size);
    final scaleX = fitted.destination.width / size.width;
    final scaleY = fitted.destination.height / size.height;
    final dx =
        (size.width - fitted.destination.width) * ((alignment.x + 1) / 2);
    final dy =
        (size.height - fitted.destination.height) * ((alignment.y + 1) / 2);
    final destinationRect = Rect.fromLTWH(
      dx,
      dy,
      size.width * scaleX,
      size.height * scaleY,
    );
    final sourceRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & inputSize,
    );

    canvas.saveLayer(outputRect, Paint());
    final imagePaint = Paint();
    final colorMatrix = _resolvedColorMatrix();
    if (colorMatrix != null) {
      imagePaint.colorFilter = ColorFilter.matrix(colorMatrix);
    }
    if (!adjustments.isNeutral) {
      if (adjustments.softnessSigma > 0.001) {
        imagePaint.imageFilter = ui.ImageFilter.blur(
          sigmaX: adjustments.softnessSigma,
          sigmaY: adjustments.softnessSigma,
        );
      }
    }
    canvas.drawImageRect(image, sourceRect, destinationRect, imagePaint);

    if (removeBgState.autoMask.isActive) {
      _applyAutoMask(canvas, destinationRect, removeBgState.autoMask);
    }
    if (removeBgState.strokes.isNotEmpty) {
      _applyRefineStrokes(
        canvas,
        destinationRect,
        sourceRect,
        imagePaint,
        removeBgState.strokes,
      );
    }
    if (decoration.hasDecoration) {
      _paintDecoration(canvas, outputRect);
    }
    canvas.restore();
  }

  void _paintDecoration(Canvas canvas, Rect rect) {
    final border = decoration.border;
    if (border.isVisible) {
      _paintBorder(canvas, rect, border);
    }
    final frame = decoration.frame;
    if (frame.isVisible) {
      final preset = _framePresetById(frame.presetId);
      if (preset != null) {
        _paintFrame(canvas, rect, preset, frame);
      }
    }
  }

  void _paintBorder(Canvas canvas, Rect rect, BorderDecorationConfig border) {
    final stroke = (rect.shortestSide * border.thickness).clamp(1.0, 32.0);
    final radius = Radius.circular(
      (rect.shortestSide * border.cornerRadius).clamp(0.0, 48.0),
    );
    final drawRect = rect.deflate(stroke / 2);
    final rrect = RRect.fromRectAndRadius(drawRect, radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    switch (border.style) {
      case BorderStylePreset.solid:
        paint.color = border.solidColor.withValues(alpha: border.opacity);
      case BorderStylePreset.gradient:
        final colors = border.gradientColors.isEmpty
            ? const <Color>[Color(0xFFF59E0B), Color(0xFFFB7185)]
            : border.gradientColors;
        paint.shader = LinearGradient(
          colors: colors
              .map((color) => color.withValues(alpha: border.opacity))
              .toList(growable: false),
        ).createShader(drawRect);
      case BorderStylePreset.dashed:
        paint.color = border.solidColor.withValues(alpha: border.opacity);
    }

    if (border.shadow > 0.001) {
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.black.withValues(alpha: border.shadow * 0.22)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (stroke * border.shadow * 0.8).clamp(0.0, 18.0),
        );
      canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), shadowPaint);
    }

    if (border.style == BorderStylePreset.dashed) {
      final path = Path()..addRRect(rrect);
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        const dashLength = 14.0;
        const gapLength = 8.0;
        while (distance < metric.length) {
          final next = math.min(distance + dashLength, metric.length);
          canvas.drawPath(metric.extractPath(distance, next), paint);
          distance += dashLength + gapLength;
        }
      }
      return;
    }

    canvas.drawRRect(rrect, paint);
  }

  void _paintFrame(
    Canvas canvas,
    Rect rect,
    FramePresetConfig preset,
    FrameDecorationConfig frame,
  ) {
    final thickness = (rect.shortestSide * frame.size).clamp(8.0, 44.0);
    final outer = rect.deflate(thickness * 0.12);
    final inner = outer.deflate(thickness);
    final alpha = frame.opacity;
    final framePaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          preset.primaryColor.withValues(alpha: alpha),
          preset.secondaryColor.withValues(alpha: alpha),
        ],
      ).createShader(outer);
    final ring = Path()
      ..addRRect(
        RRect.fromRectAndRadius(outer, Radius.circular(thickness * 0.5)),
      )
      ..addRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(thickness * 0.35)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(ring, framePaint);

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, thickness * 0.16)
      ..color = preset.accentColor.withValues(alpha: alpha * 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        outer.deflate(thickness * 0.18),
        Radius.circular(thickness * 0.42),
      ),
      accentPaint,
    );

    final ornamentPaint = Paint()
      ..color = preset.accentColor.withValues(alpha: alpha * 0.82);
    final ornamentRadius = thickness * 0.24;
    final corners = <Offset>[
      Offset(outer.left + thickness * 0.44, outer.top + thickness * 0.44),
      Offset(outer.right - thickness * 0.44, outer.top + thickness * 0.44),
      Offset(outer.left + thickness * 0.44, outer.bottom - thickness * 0.44),
      Offset(outer.right - thickness * 0.44, outer.bottom - thickness * 0.44),
    ];
    for (final corner in corners) {
      canvas.drawCircle(corner, ornamentRadius, ornamentPaint);
    }
  }

  FramePresetConfig? _framePresetById(String? presetId) {
    if (presetId == null) {
      return null;
    }
    for (final preset in framePresets) {
      if (preset.id == presetId) {
        return preset;
      }
    }
    return null;
  }

  List<double>? _resolvedColorMatrix() {
    final adjustmentMatrix = adjustments.isNeutral
        ? null
        : adjustments.toColorMatrix();
    final filterMatrix = filter.toColorMatrix();

    if (adjustmentMatrix == null) {
      return filterMatrix;
    }
    if (filterMatrix == null) {
      return adjustmentMatrix;
    }

    final combined = List<double>.from(adjustmentMatrix);
    for (var row = 0; row < 4; row += 1) {
      final offsetIndex = (row * 5) + 4;
      combined[offsetIndex] += filterMatrix[offsetIndex];
    }
    for (var i = 0; i < combined.length; i += 1) {
      if ((i + 1) % 5 == 0) {
        continue;
      }
      combined[i] *= filterMatrix[i];
    }
    return combined;
  }

  void _applyAutoMask(Canvas canvas, Rect rect, AutoMaskTemplate template) {
    final center = Offset(
      rect.left + (rect.width * template.center.dx),
      rect.top + (rect.height * template.center.dy),
    );
    final ovalRect = Rect.fromCenter(
      center: center,
      width: rect.width * template.radiusX * 2,
      height: rect.height * template.radiusY * 2,
    );
    final paint = Paint()
      ..color = Colors.white
      ..blendMode = BlendMode.dstIn
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        (rect.shortestSide * template.feather * 0.18).clamp(0.0, 28.0),
      );
    canvas.drawOval(ovalRect, paint);
  }

  void _applyRefineStrokes(
    Canvas canvas,
    Rect destinationRect,
    Rect sourceRect,
    Paint sourcePaint,
    List<RemoveBgStroke> strokes,
  ) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) {
        continue;
      }
      final points = stroke.points
          .map(
            (point) => Offset(
              destinationRect.left + (destinationRect.width * point.dx),
              destinationRect.top + (destinationRect.height * point.dy),
            ),
          )
          .toList(growable: false);
      final brushRadius = destinationRect.shortestSide * stroke.brushSize * 0.5;
      final blurSigma = brushRadius * stroke.softness * 0.55;

      if (stroke.mode == RemoveBgRefineMode.erase) {
        final erasePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = brushRadius * 2
          ..blendMode = BlendMode.dstOut;
        if (blurSigma > 0.001) {
          erasePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
        }
        if (points.length == 1) {
          final circlePaint = Paint()
            ..color = Colors.white
            ..blendMode = BlendMode.dstOut;
          if (blurSigma > 0.001) {
            circlePaint.maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              blurSigma,
            );
          }
          canvas.drawCircle(points.first, brushRadius, circlePaint);
        } else {
          canvas.drawPoints(ui.PointMode.polygon, points, erasePaint);
        }
        continue;
      }

      canvas.saveLayer(destinationRect, Paint());
      canvas.drawImageRect(image, sourceRect, destinationRect, sourcePaint);
      final restorePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = brushRadius * 2
        ..blendMode = BlendMode.dstIn;
      if (blurSigma > 0.001) {
        restorePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
      }
      if (points.length == 1) {
        final circlePaint = Paint()
          ..color = Colors.white
          ..blendMode = BlendMode.dstIn;
        if (blurSigma > 0.001) {
          circlePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
        }
        canvas.drawCircle(points.first, brushRadius, circlePaint);
      } else {
        canvas.drawPoints(ui.PointMode.polygon, points, restorePaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoLayerPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.adjustments != adjustments ||
        oldDelegate.filter != filter ||
        oldDelegate.removeBgState != removeBgState ||
        oldDelegate.fit != fit ||
        oldDelegate.alignment != alignment ||
        oldDelegate.decoration != decoration ||
        oldDelegate.framePresets != framePresets;
  }
}

class _DecorationOverlay extends StatelessWidget {
  const _DecorationOverlay({
    required this.decoration,
    required this.framePresetResolver,
    this.isPosterOverlay = false,
  });

  final DecorationStyleConfig decoration;
  final List<FramePresetConfig> framePresetResolver;
  final bool isPosterOverlay;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DecorationOverlayPainter(
        decoration: decoration,
        framePresets: framePresetResolver,
        insetFactor: isPosterOverlay ? 0.0 : 0.02,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DecorationOverlayPainter extends CustomPainter {
  _DecorationOverlayPainter({
    required this.decoration,
    required this.framePresets,
    required this.insetFactor,
  });

  final DecorationStyleConfig decoration;
  final List<FramePresetConfig> framePresets;
  final double insetFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * insetFactor;
    final rect =
        Offset(inset, inset) &
        Size(size.width - (inset * 2), size.height - (inset * 2));
    final border = decoration.border;
    if (border.isVisible) {
      final stroke = (rect.shortestSide * border.thickness).clamp(1.0, 32.0);
      final radius = Radius.circular(
        (rect.shortestSide * border.cornerRadius).clamp(0.0, 48.0),
      );
      final drawRect = rect.deflate(stroke / 2);
      final rrect = RRect.fromRectAndRadius(drawRect, radius);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      switch (border.style) {
        case BorderStylePreset.solid:
          paint.color = border.solidColor.withValues(alpha: border.opacity);
        case BorderStylePreset.gradient:
          final colors = border.gradientColors.isEmpty
              ? const <Color>[Color(0xFFF59E0B), Color(0xFFFB7185)]
              : border.gradientColors;
          paint.shader = LinearGradient(
            colors: colors
                .map((color) => color.withValues(alpha: border.opacity))
                .toList(growable: false),
          ).createShader(drawRect);
        case BorderStylePreset.dashed:
          paint.color = border.solidColor.withValues(alpha: border.opacity);
      }
      if (border.shadow > 0.001) {
        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Colors.black.withValues(alpha: border.shadow * 0.22)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (stroke * border.shadow * 0.8).clamp(0.0, 18.0),
          );
        canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), shadowPaint);
      }
      if (border.style == BorderStylePreset.dashed) {
        final path = Path()..addRRect(rrect);
        for (final metric in path.computeMetrics()) {
          var distance = 0.0;
          const dashLength = 14.0;
          const gapLength = 8.0;
          while (distance < metric.length) {
            final next = math.min(distance + dashLength, metric.length);
            canvas.drawPath(metric.extractPath(distance, next), paint);
            distance += dashLength + gapLength;
          }
        }
      } else {
        canvas.drawRRect(rrect, paint);
      }
    }
    final frame = decoration.frame;
    if (frame.isVisible) {
      FramePresetConfig? preset;
      for (final item in framePresets) {
        if (item.id == frame.presetId) {
          preset = item;
          break;
        }
      }
      if (preset != null) {
        final thickness = (rect.shortestSide * frame.size).clamp(8.0, 44.0);
        final outer = rect.deflate(thickness * 0.12);
        final inner = outer.deflate(thickness);
        final alpha = frame.opacity;
        final framePaint = Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              preset.primaryColor.withValues(alpha: alpha),
              preset.secondaryColor.withValues(alpha: alpha),
            ],
          ).createShader(outer);
        final ring = Path()
          ..addRRect(
            RRect.fromRectAndRadius(outer, Radius.circular(thickness * 0.5)),
          )
          ..addRRect(
            RRect.fromRectAndRadius(inner, Radius.circular(thickness * 0.35)),
          )
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(ring, framePaint);
        final accentPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, thickness * 0.16)
          ..color = preset.accentColor.withValues(alpha: alpha * 0.9);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            outer.deflate(thickness * 0.18),
            Radius.circular(thickness * 0.42),
          ),
          accentPaint,
        );
        final ornamentPaint = Paint()
          ..color = preset.accentColor.withValues(alpha: alpha * 0.82);
        final ornamentRadius = thickness * 0.24;
        final corners = <Offset>[
          Offset(outer.left + thickness * 0.44, outer.top + thickness * 0.44),
          Offset(outer.right - thickness * 0.44, outer.top + thickness * 0.44),
          Offset(
            outer.left + thickness * 0.44,
            outer.bottom - thickness * 0.44,
          ),
          Offset(
            outer.right - thickness * 0.44,
            outer.bottom - thickness * 0.44,
          ),
        ];
        for (final corner in corners) {
          canvas.drawCircle(corner, ornamentRadius, ornamentPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DecorationOverlayPainter oldDelegate) {
    return oldDelegate.decoration != decoration ||
        oldDelegate.framePresets != framePresets ||
        oldDelegate.insetFactor != insetFactor;
  }
}

class _StickerLayerWidget extends StatelessWidget {
  const _StickerLayerWidget({
    required this.layer,
    required this.isSelected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final StageStickerLayer layer;
  final bool isSelected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: layer.offset,
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scaleX: layer.visuals.flipX ? -layer.scale : layer.scale,
            scaleY: layer.visuals.flipY ? -layer.scale : layer.scale,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              onScaleStart: layer.isLocked ? null : onScaleStart,
              onScaleUpdate: layer.isLocked ? null : onScaleUpdate,
              onScaleEnd: layer.isLocked ? null : onScaleEnd,
              child: Container(
                width: layer.size.width,
                height: layer.size.height,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: const Color(0x552563EB), width: 1)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: _LayerVisualWrapper(
                  visuals: layer.visuals,
                  child: buildEditorImage(
                    layer.stickerUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextLayerWidget extends StatelessWidget {
  const _TextLayerWidget({
    required this.layer,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final EditorTextLayer layer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;

  @override
  Widget build(BuildContext context) {
    final style = layer.style;
    final textColor = style.color.withValues(alpha: style.opacity);

    final fillTextStyle = TextStyle(
      color: style.gradientColors == null ? textColor : Colors.white,
      fontFamily: style.fontFamily,
      fontSize: style.fontSize,
      fontWeight: style.isBold ? FontWeight.w700 : FontWeight.w500,
      fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: style.letterSpacing,
      height: style.lineHeight,
      shadows: style.shadow.color == Colors.transparent
          ? null
          : <Shadow>[style.shadow],
    );

    final strokeStyle = style.strokeWidth <= 0 || style.strokeColor == null
        ? null
        : TextStyle(
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            fontWeight: style.isBold ? FontWeight.w700 : FontWeight.w500,
            fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
            letterSpacing: style.letterSpacing,
            height: style.lineHeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.strokeWidth
              ..color = style.strokeColor!,
          );

    final content = _TextVisualContent(
      text: layer.text,
      style: style,
      fillTextStyle: fillTextStyle,
      strokeStyle: strokeStyle,
    );

    return Center(
      child: Transform.translate(
        offset: layer.offset,
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scaleX: layer.isFlipped ? -layer.scale : layer.scale,
            scaleY: layer.isFlippedVertical ? -layer.scale : layer.scale,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onScaleStart: layer.isLocked ? null : onScaleStart,
              onScaleUpdate: layer.isLocked ? null : onScaleUpdate,
              onScaleEnd: layer.isLocked ? null : onScaleEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: style.backgroundHighlightColor,
                  border: isSelected
                      ? Border.all(color: const Color(0x662563EB), width: 1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _LayerBlendWrapper(
                  blendMode: layer.blendMode,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextVisualContent extends StatelessWidget {
  const _TextVisualContent({
    required this.text,
    required this.style,
    required this.fillTextStyle,
    required this.strokeStyle,
  });

  final String text;
  final EditorTextStyleConfig style;
  final TextStyle fillTextStyle;
  final TextStyle? strokeStyle;

  @override
  Widget build(BuildContext context) {
    final curved = style.curve.abs() > 0.001;
    if (!curved || text.contains('\n')) {
      Widget textWidget = Text(
        text,
        textAlign: style.alignment,
        style: fillTextStyle,
      );

      if (style.gradientColors != null && style.gradientColors!.length >= 2) {
        textWidget = ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: style.gradientColors!,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: textWidget,
        );
      }

      return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (strokeStyle != null)
            Text(text, textAlign: style.alignment, style: strokeStyle),
          textWidget,
        ],
      );
    }

    return _CurvedTextContent(
      text: text,
      style: style,
      fillTextStyle: fillTextStyle,
      strokeStyle: strokeStyle,
    );
  }
}

class _CurvedTextContent extends StatelessWidget {
  const _CurvedTextContent({
    required this.text,
    required this.style,
    required this.fillTextStyle,
    required this.strokeStyle,
  });

  final String text;
  final EditorTextStyleConfig style;
  final TextStyle fillTextStyle;
  final TextStyle? strokeStyle;

  @override
  Widget build(BuildContext context) {
    final glyphs = text.characters.toList(growable: false);
    if (glyphs.isEmpty) {
      return const SizedBox.shrink();
    }

    final measuredWidths = glyphs
        .map((glyph) => _measureGlyphWidth(glyph, fillTextStyle))
        .toList(growable: false);
    final totalWidth = measuredWidths.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    final spacing = style.letterSpacing.clamp(-1.0, 20.0);
    final widthWithSpacing =
        totalWidth + (spacing * math.max(0, glyphs.length - 1));
    final radius = math.max(
      56.0,
      widthWithSpacing / (0.7 + (style.curve.abs() * 1.9)),
    );
    final direction = style.curve >= 0 ? 1.0 : -1.0;
    final totalAngle = (widthWithSpacing / radius).clamp(0.0, math.pi * 1.2);
    final startAngle = -totalAngle / 2;
    final height = radius * 0.55 + style.fontSize * 1.8;
    final width = math.max(
      widthWithSpacing + style.fontSize,
      style.fontSize * 2.4,
    );
    double runningWidth = 0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(glyphs.length, (index) {
          final glyph = glyphs[index];
          final glyphWidth = measuredWidths[index];
          final centerAlongArc = runningWidth + (glyphWidth / 2);
          final glyphAngle = startAngle + (centerAlongArc / radius);
          final x = (width / 2) + radius * math.sin(glyphAngle);
          final y =
              (height / 2) + direction * radius * (1 - math.cos(glyphAngle));
          final rotation = glyphAngle * direction;
          runningWidth += glyphWidth + spacing;

          return Positioned(
            left: x - (glyphWidth / 2),
            top: y - style.fontSize,
            child: Transform.rotate(angle: rotation, child: _buildGlyph(glyph)),
          );
        }),
      ),
    );
  }

  Widget _buildGlyph(String glyph) {
    Widget fill = Text(glyph, style: fillTextStyle);
    if (style.gradientColors != null && style.gradientColors!.length >= 2) {
      fill = ShaderMask(
        shaderCallback: (bounds) =>
            LinearGradient(colors: style.gradientColors!).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: fill,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (strokeStyle != null) Text(glyph, style: strokeStyle),
        fill,
      ],
    );
  }

  double _measureGlyphWidth(String glyph, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: glyph, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

class _LayerVisualWrapper extends StatelessWidget {
  const _LayerVisualWrapper({required this.visuals, required this.child});

  final LayerVisualConfig visuals;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget current = _LayerBlendWrapper(
      blendMode: visuals.blendMode,
      child: child,
    );
    if (visuals.shadow.isVisible) {
      current = Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: visuals.shadow.color.withValues(
                  alpha: visuals.shadow.opacity * 0.45,
                ),
                blurRadius: visuals.shadow.blur * 24,
                offset: Offset(0, visuals.shadow.distance * 18),
              ),
            ],
          ),
          child: current,
        ),
      );
    }
    if (visuals.opacity < 0.999) {
      current = Opacity(
        opacity: visuals.opacity.clamp(0.0, 1.0),
        child: current,
      );
    }
    return current;
  }
}

class _LayerBlendWrapper extends StatelessWidget {
  const _LayerBlendWrapper({required this.blendMode, required this.child});

  final LayerBlendModeOption blendMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (blendMode == LayerBlendModeOption.normal) {
      return child;
    }
    final color = switch (blendMode) {
      LayerBlendModeOption.normal => Colors.transparent,
      LayerBlendModeOption.multiply => const Color(0x26CBD5E1),
      LayerBlendModeOption.screen => const Color(0x26FFFFFF),
      LayerBlendModeOption.overlay => const Color(0x2AF59E0B),
    };
    final mode = switch (blendMode) {
      LayerBlendModeOption.normal => BlendMode.srcOver,
      LayerBlendModeOption.multiply => BlendMode.multiply,
      LayerBlendModeOption.screen => BlendMode.screen,
      LayerBlendModeOption.overlay => BlendMode.overlay,
    };
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, mode),
      child: child,
    );
  }
}

class _StageBackground extends StatelessWidget {
  const _StageBackground({
    required this.background,
    required this.isTransparentExport,
  });

  final StageBackgroundConfig background;
  final bool isTransparentExport;

  @override
  Widget build(BuildContext context) {
    if (isTransparentExport) {
      return const SizedBox.expand();
    }
    switch (background.type) {
      case StageBackgroundType.solid:
        return ColoredBox(color: background.solidColor ?? Colors.white);
      case StageBackgroundType.gradient:
        final colors =
            background.gradientColors ??
            const <Color>[Colors.white, Color(0xFFF8FAFF)];
        final radians = background.gradientAngle * math.pi / 180;
        final begin = Alignment(
          math.cos(radians + math.pi),
          math.sin(radians + math.pi),
        );
        final end = Alignment(math.cos(radians), math.sin(radians));
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: begin, end: end, colors: colors),
          ),
        );
      case StageBackgroundType.image:
        final imageUrl = background.imageUrl;
        if (imageUrl == null || imageUrl.isEmpty) {
          return const ColoredBox(color: Colors.white);
        }
        final fit = switch (background.imageFit) {
          StageBackgroundImageFit.fit => BoxFit.contain,
          StageBackgroundImageFit.fill => BoxFit.cover,
          StageBackgroundImageFit.stretch => BoxFit.fill,
        };
        Widget image = buildEditorImage(
          imageUrl,
          fit: fit,
          alignment: Alignment.center,
        );
        if (background.imageBlur > 0) {
          image = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: background.imageBlur,
              sigmaY: background.imageBlur,
            ),
            child: image,
          );
        }
        return Opacity(opacity: background.imageOpacity, child: image);
    }
  }
}

class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay({
    required this.showVertical,
    required this.showHorizontal,
  });

  final bool showVertical;
  final bool showHorizontal;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GuidePainter(
        showVertical: showVertical,
        showHorizontal: showHorizontal,
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter({required this.showVertical, required this.showHorizontal});

  final bool showVertical;
  final bool showHorizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x220F172A)
      ..strokeWidth = 1;

    if (showVertical) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    }

    if (showHorizontal) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) {
    return oldDelegate.showVertical != showVertical ||
        oldDelegate.showHorizontal != showHorizontal;
  }
}
