part of '../image_editor_screen.dart';

@immutable
class _StretchStroke {
  const _StretchStroke({
    required this.points,
    required this.radius,
    required this.strength,
    required this.opacity,
  });

  final List<Offset> points;
  final double radius;
  final double strength;
  final double opacity;
}

@immutable
class _StretchLivePreviewState {
  const _StretchLivePreviewState({
    required this.layerId,
    required this.image,
    required this.strokes,
  });

  final String layerId;
  final ui.Image image;
  final List<_StretchStroke> strokes;
}

extension _EditorStretchToolState on _ImageEditorScreenState {
  double get _stretchBrushCanvasRadius =>
      (_stretchBrushSize / 2) / math.max(0.1, _workspaceZoom);

  void _activatePhotoStretchMode() {
    final selected = _selectedLayer;
    if (selected == null ||
        !selected.isPhoto ||
        selected.isLocked ||
        selected.bytes == null ||
        _isCommitWorkerBusy) {
      return;
    }
    if (_selectedTextFocusNode.hasFocus) {
      _selectedTextFocusNode.unfocus();
    }
    _commitSelectedTextContentEdit();
    setState(() {
      _isPhotoStretchMode = true;
      _isPhotoEraserMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isDrawBrushMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _isMagicWandMode = false;
      _isAdjustMode = false;
      _isCropMode = false;
      _isTextPlacementMode = false;
      _showTextControls = false;
      _showSelectedLayerHandles = false;
      _activeBottomPrimaryTool = _BottomPrimaryTool.photo;
      _activeInlineMode = _BottomInlineMode.none;
      _activeMainToolLabel = 'Smudge';
      _stretchStrokePoints.clear();
      _stretchLiveStrokes.clear();
      _stretchRedoStrokes.clear();
      _stretchStrokeLayerId = null;
      _stretchStrokeLayerSize = Size.zero;
    });
    unawaited(_prepareStretchPreviewImage(selected));
    _showStretchBrushCursorPreview();
  }

  void _closePhotoStretchMode() {
    _commitStretchLiveStrokes();
    setState(() {
      _isPhotoStretchMode = false;
      _stretchStrokePoints.clear();
      _stretchStrokeLayerId = null;
      _stretchStrokeLayerSize = Size.zero;
      _showSelectedLayerHandles = true;
      _restoreSelectedLayerToolContextFields();
    });
    _eraserPreviewNotifier.value = null;
  }

  Future<void> _prepareStretchPreviewImage(_CanvasLayer layer) async {
    final bytes = layer.bytes;
    if (bytes == null) {
      return;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      if (!mounted || _selectedLayerId != layer.id) {
        frame.image.dispose();
        return;
      }
      _stretchPreviewImage?.dispose();
      _stretchPreviewImage = frame.image;
      _stretchPreviewLayerId = layer.id;
      _publishStretchPreview();
    } finally {
      codec.dispose();
    }
  }

  void _commitStretchLiveStrokes() {
    final layerId = _stretchPreviewLayerId ?? _selectedLayerId;
    final strokes = _stretchLiveStrokes
        .where((stroke) => stroke.opacity > 0)
        .toList(growable: false);
    final previewSize = _stretchStrokeLayerSize;
    if (layerId == null || strokes.isEmpty) {
      _stretchPreviewNotifier.value = null;
      _stretchPreviewImage?.dispose();
      _stretchPreviewImage = null;
      _stretchPreviewLayerId = null;
      _stretchLiveStrokes.clear();
      _stretchRedoStrokes.clear();
      return;
    }
    _stretchLiveStrokes.clear();
    _stretchRedoStrokes.clear();
    unawaited(
      _runQueuedCommitJob<Uint8List>(
        jobKey: 'smudge_$layerId',
        label: 'Smudge',
        detail: 'Applying smudge',
        showBusyMessage: false,
        showCommitState: false,
        operation: () async {
          final index = _layers.indexWhere((layer) => layer.id == layerId);
          if (index == -1 || !_layers[index].isPhoto) {
            return Uint8List(0);
          }
          final sourceBytes = _layers[index].bytes;
          if (sourceBytes == null) {
            return Uint8List(0);
          }
          return _renderSmudgeBytesFromLiveStrokes(
            bytes: sourceBytes,
            strokes: strokes,
            referenceSize: previewSize,
          );
        },
      ).then((resultBytes) {
        if (!mounted || resultBytes == null || resultBytes.isEmpty) {
          return;
        }
        final index = _layers.indexWhere((layer) => layer.id == layerId);
        if (index == -1 || !_layers[index].isPhoto) {
          return;
        }
        final beforeLayer = _layers[index];
        final afterLayer = beforeLayer.copyWith(bytes: resultBytes);
        _pushLayerHistoryEntry(
          beforeLayer: beforeLayer,
          afterLayer: afterLayer,
        );
        setState(() => _layers[index] = afterLayer);
        _selectedPhotoRenderNotifier.value = null;
        _stretchPreviewNotifier.value = null;
        _stretchPreviewImage?.dispose();
        _stretchPreviewImage = null;
        _stretchPreviewLayerId = null;
      }),
    );
  }

  void _handlePhotoStretchStart(Offset localPosition, Size layerSize) {
    if (!_isPhotoStretchMode || layerSize.isEmpty || _stretchOpacity <= 0) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null ||
        !_hasSelectedPhotoLayer ||
        _isSelectedLayerLocked) {
      return;
    }
    _stretchStrokeLayerId = selectedId;
    _stretchStrokeLayerSize = layerSize;
    final normalizedPoint = _normalizeEraserPoint(localPosition, layerSize);
    _rememberLayerBrushPreviewPoint(selectedId, normalizedPoint);
    _stretchStrokePoints = <Offset>[normalizedPoint];
    _stretchRedoStrokes.clear();
    _stretchLiveStrokes.add(
      _StretchStroke(
        points: _stretchStrokePoints,
        radius: _stretchBrushCanvasRadius,
        strength: _stretchStrength,
        opacity: _stretchOpacity,
      ),
    );
    _publishStretchPreview();
  }

  void _handlePhotoStretchUpdate(Offset localPosition, Size layerSize) {
    if (!_isPhotoStretchMode ||
        _stretchStrokeLayerId == null ||
        layerSize.isEmpty) {
      return;
    }
    final nextPoint = _normalizeEraserPoint(localPosition, layerSize);
    _rememberLayerBrushPreviewPoint(_stretchStrokeLayerId!, nextPoint);
    final previousPoint = _stretchStrokePoints.isEmpty
        ? null
        : _stretchStrokePoints.last;
    if (previousPoint != null) {
      final minStep =
          ((_stretchBrushCanvasRadius * 2) /
              math.max(layerSize.width, layerSize.height)) *
          0.16;
      if ((nextPoint - previousPoint).distance < minStep.clamp(0.002, 0.018)) {
        return;
      }
    }
    _stretchStrokePoints.add(nextPoint);
    _publishStretchPreview();
  }

  Future<void> _handlePhotoStretchEnd() async {
    if (!_isPhotoStretchMode) {
      _cancelPhotoStretchStroke();
      return;
    }
    final layerId = _stretchStrokeLayerId;
    final strokePoints = List<Offset>.of(_stretchStrokePoints);
    final strokeLayerSize = _stretchStrokeLayerSize;
    if (strokePoints.length < 2) {
      _stretchLiveStrokes.removeWhere(
        (stroke) => identical(stroke.points, _stretchStrokePoints),
      );
    }
    _stretchStrokePoints = <Offset>[];
    _stretchStrokeLayerId = null;
    if (layerId == null || strokePoints.length < 2) {
      _showStretchBrushCursorPreview();
      return;
    }
    final layerIndex = _layers.indexWhere((item) => item.id == layerId);
    if (layerIndex == -1 || !_layers[layerIndex].isPhoto) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final layer = _layers[layerIndex];
    final sourceBytes = layer.bytes;
    if (sourceBytes == null) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final strokeRadius = _stretchBrushCanvasRadius;
    final encodedStrokes = <Map<String, Object?>>[
      <String, Object?>{
        'points': <double>[
          for (final point in strokePoints) ...<double>[
            point.dx.clamp(0.0, 1.0).toDouble(),
            point.dy.clamp(0.0, 1.0).toDouble(),
          ],
        ],
        'radiusNormalized': strokeLayerSize.shortestSide <= 0
            ? 0.08
            : strokeRadius / strokeLayerSize.shortestSide,
        'strength': _stretchStrength,
        'opacity': _stretchOpacity,
      },
    ];
    final resultBytes = await _runQueuedCommitJob<Uint8List>(
      jobKey: 'smudge_$layerId',
      label: context.strings.localized(
        telugu: 'స్ట్రెచ్ అప్లై అవుతోంది',
        english: 'Applying smudge',
      ),
      detail: context.strings.localized(
        telugu: 'Brush దిశలో pixels ను smoothగా warp చేస్తోంది',
        english: 'Pushing and blending pixels along the brush direction',
      ),
      operation: () => compute(_applySmudgeBytes, <String, Object?>{
        'bytes': sourceBytes,
        'strokes': encodedStrokes,
      }),
      showBusyMessage: false,
      showCommitState: false,
    );
    if (!mounted || resultBytes == null) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || !_layers[index].isPhoto) {
      return;
    }
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(bytes: resultBytes);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
      _stretchLiveStrokes.clear();
      _stretchRedoStrokes.clear();
    });
    _selectedPhotoRenderNotifier.value = null;
    _stretchPreviewNotifier.value = null;
    _stretchPreviewImage?.dispose();
    _stretchPreviewImage = null;
    _stretchPreviewLayerId = null;
    unawaited(_prepareStretchPreviewImage(afterLayer));
    _showStretchBrushCursorPreview();
  }

  void _cancelPhotoStretchStroke() {
    _stretchLiveStrokes.removeWhere(
      (stroke) => identical(stroke.points, _stretchStrokePoints),
    );
    _stretchStrokePoints = <Offset>[];
    _stretchStrokeLayerId = null;
    _stretchStrokeLayerSize = Size.zero;
    _eraserPreviewNotifier.value = null;
    _publishStretchPreview();
  }

  void _undoStretchLiveStroke() {
    if (_stretchLiveStrokes.isEmpty) {
      return;
    }
    _stretchRedoStrokes.add(_stretchLiveStrokes.removeLast());
    if (_stretchLiveStrokes.isEmpty) {
      _stretchPreviewNotifier.value = null;
    } else {
      _publishStretchPreview();
    }
    _showStretchBrushCursorPreview();
    setState(() {});
  }

  void _redoStretchLiveStroke() {
    if (_stretchRedoStrokes.isEmpty) {
      return;
    }
    _stretchLiveStrokes.add(_stretchRedoStrokes.removeLast());
    _publishStretchPreview();
    _showStretchBrushCursorPreview();
    setState(() {});
  }

  void _publishStretchPreview() {
    final layerId = _stretchStrokeLayerId ?? _stretchPreviewLayerId;
    if (layerId == null ||
        (_stretchStrokePoints.isEmpty && _stretchLiveStrokes.isEmpty)) {
      _eraserPreviewNotifier.value = null;
      if (_stretchLiveStrokes.isEmpty) {
        _stretchPreviewNotifier.value = null;
      }
      return;
    }
    _stretchPreviewNotifier.value = null;
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: layerId,
      points: List<Offset>.of(_stretchStrokePoints),
      brushSize: _stretchBrushSize,
      hardness: _stretchStrength,
    );
  }

  void _showStretchBrushCursorPreview([Offset? point]) {
    if (!_isPhotoStretchMode) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null || !_hasSelectedPhotoLayer) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final previewPoint = _resolveLayerBrushPreviewPoint(selectedId, point);
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: selectedId,
      points: <Offset>[previewPoint],
      brushSize: _stretchBrushSize,
      hardness: _stretchStrength,
    );
  }
}

class _StretchMeshPainter extends CustomPainter {
  const _StretchMeshPainter({
    required this.image,
    required this.strokes,
    required this.displayScale,
  });

  final ui.Image image;
  final List<_StretchStroke> strokes;
  final double displayScale;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      bounds,
      Paint()..filterQuality = FilterQuality.high,
    );

    for (final stroke in strokes) {
      if (stroke.points.length < 2 || stroke.opacity <= 0) {
        continue;
      }
      final radius = stroke.radius.clamp(1.0, size.shortestSide).toDouble();
      final path = Path();
      for (var index = 0; index < stroke.points.length; index++) {
        final point = Offset(
          stroke.points[index].dx * size.width,
          stroke.points[index].dy * size.height,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.saveLayer(bounds, Paint()..isAntiAlias = true);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = math.max(1.0, radius * 1.2),
      );
      canvas.drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = math.max(1.0, radius * 0.46),
      );
      canvas.restore();
    }

    if (strokes.isNotEmpty && strokes.last.points.isNotEmpty) {
      final point = strokes.last.points.last;
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        strokes.last.radius,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * displayScale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StretchMeshPainter oldDelegate) => true;
}

Future<Uint8List> _renderSmudgeBytesFromLiveStrokes({
  required Uint8List bytes,
  required List<_StretchStroke> strokes,
  required Size referenceSize,
}) async {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }
  final shortestSide = math.min(decoded.width, decoded.height).toDouble();
  final radiusScale = referenceSize.shortestSide <= 0
      ? 1.0
      : shortestSide / referenceSize.shortestSide;
  final encodedStrokes = <Map<String, Object?>>[
    for (final stroke in strokes)
      <String, Object?>{
        'points': <double>[
          for (final point in stroke.points) ...<double>[
            point.dx.clamp(0.0, 1.0).toDouble(),
            point.dy.clamp(0.0, 1.0).toDouble(),
          ],
        ],
        'radiusNormalized': shortestSide <= 0
            ? 0.08
            : (stroke.radius * radiusScale) / shortestSide,
        'strength': stroke.strength,
        'opacity': stroke.opacity,
      },
  ];
  return _applySmudgeBytes(<String, Object?>{
    'bytes': bytes,
    'strokes': encodedStrokes,
  });
}

Uint8List _applySmudgeBytes(Map<String, Object?> input) {
  final bytes = input['bytes'] as Uint8List;
  final rawStrokes = input['strokes'] as List;
  final fallbackRadiusNormalized =
      (input['radiusNormalized'] as num?)?.toDouble() ?? 0.1;
  final fallbackStrength = ((input['strength'] as num?)?.toDouble() ?? 0.62)
      .clamp(0.1, 1.0)
      .toDouble();
  final fallbackOpacity = ((input['opacity'] as num?)?.toDouble() ?? 1.0)
      .clamp(0.0, 1.0)
      .toDouble();
  final decoded = img.decodeImage(bytes);
  if (decoded == null || rawStrokes.isEmpty) {
    return bytes;
  }
  var output = img.Image.from(decoded).convert(numChannels: 4);
  final width = output.width;
  final height = output.height;

  for (final rawStroke in rawStrokes) {
    final strokeMap = rawStroke is Map ? rawStroke : null;
    final rawPoints = strokeMap == null ? rawStroke : strokeMap['points'];
    final radiusNormalized =
        (strokeMap?['radiusNormalized'] as num?)?.toDouble() ??
        fallbackRadiusNormalized;
    final strokeStrength =
        ((strokeMap?['strength'] as num?)?.toDouble() ?? fallbackStrength)
            .clamp(0.1, 1.0)
            .toDouble();
    final strokeOpacity =
        ((strokeMap?['opacity'] as num?)?.toDouble() ?? fallbackOpacity)
            .clamp(0.0, 1.0)
            .toDouble();
    if (strokeOpacity <= 0) {
      continue;
    }
    final radius = (radiusNormalized * math.min(width, height))
        .clamp(1.0, math.min(width, height) / 2)
        .toDouble();
    final flat = (rawPoints as List)
        .cast<num>()
        .map((value) => value.toDouble())
        .toList(growable: false);
    if (flat.length < 4) {
      continue;
    }
    final points = <Offset>[
      for (var index = 0; index + 1 < flat.length; index += 2)
        Offset(flat[index] * width, flat[index + 1] * height),
    ];
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final segment = current - previous;
      if (segment.distanceSquared < 0.0001) {
        continue;
      }
      final snapshot = img.Image.from(output);
      final left = math.max(
        0,
        (math.min(previous.dx, current.dx) - radius).floor(),
      );
      final right = math.min(
        width - 1,
        (math.max(previous.dx, current.dx) + radius).ceil(),
      );
      final top = math.max(
        0,
        (math.min(previous.dy, current.dy) - radius).floor(),
      );
      final bottom = math.min(
        height - 1,
        (math.max(previous.dy, current.dy) + radius).ceil(),
      );
      for (var y = top; y <= bottom; y++) {
        for (var x = left; x <= right; x++) {
          final pixelCenter = Offset(x + 0.5, y + 0.5);
          final projection =
              ((pixelCenter - previous).dx * segment.dx +
                  (pixelCenter - previous).dy * segment.dy) /
              segment.distanceSquared;
          final closest =
              previous + (segment * projection.clamp(0.0, 1.0).toDouble());
          final distance = (pixelCenter - closest).distance;
          if (distance >= radius) {
            continue;
          }
          final normalized = 1 - (distance / radius);
          final falloff = normalized * normalized * (3 - (2 * normalized));
          final effectiveStrength = strokeStrength * 0.42;
          final effectiveOpacity = strokeOpacity * falloff * 0.58;
          if (effectiveOpacity <= 0.001) {
            continue;
          }
          final sampleX = x - (segment.dx * effectiveStrength * falloff);
          final sampleY = y - (segment.dy * effectiveStrength * falloff);
          final sampled = _sampleImageBilinear(snapshot, sampleX, sampleY);
          final blended = _blendStretchSample(
            snapshot.getPixel(x, y),
            sampled,
            effectiveOpacity,
          );
          output.setPixelRgba(
            x,
            y,
            blended.$1,
            blended.$2,
            blended.$3,
            blended.$4,
          );
        }
      }
    }
  }
  return Uint8List.fromList(img.encodePng(output));
}

(int, int, int, int) _blendStretchSample(
  img.Pixel destination,
  (int, int, int, int) sampled,
  double opacity,
) {
  final destinationAlpha = destination.a.toDouble() / 255;
  final warpedAlpha = math.max(destination.a.toDouble(), sampled.$4) / 255;
  final mixedAlpha =
      (destinationAlpha * (1 - opacity)) + (warpedAlpha * opacity);
  if (mixedAlpha <= 0.000001) {
    return (0, 0, 0, 0);
  }

  int mixChannel(num destinationChannel, int warpedChannel) {
    final premultiplied =
        (destinationChannel.toDouble() * destinationAlpha * (1 - opacity)) +
        (warpedChannel * warpedAlpha * opacity);
    return (premultiplied / mixedAlpha).round().clamp(0, 255);
  }

  return (
    mixChannel(destination.r, sampled.$1),
    mixChannel(destination.g, sampled.$2),
    mixChannel(destination.b, sampled.$3),
    (mixedAlpha * 255).round().clamp(0, 255),
  );
}

(int, int, int, int) _sampleImageBilinear(img.Image image, double x, double y) {
  final clampedX = x.clamp(0.0, image.width - 1.0).toDouble();
  final clampedY = y.clamp(0.0, image.height - 1.0).toDouble();
  final x0 = clampedX.floor();
  final y0 = clampedY.floor();
  final x1 = math.min(image.width - 1, x0 + 1);
  final y1 = math.min(image.height - 1, y0 + 1);
  final tx = clampedX - x0;
  final ty = clampedY - y0;
  final p00 = image.getPixel(x0, y0);
  final p10 = image.getPixel(x1, y0);
  final p01 = image.getPixel(x0, y1);
  final p11 = image.getPixel(x1, y1);

  int interpolate(num a, num b, num c, num d) {
    final top = a.toDouble() + ((b.toDouble() - a.toDouble()) * tx);
    final bottom = c.toDouble() + ((d.toDouble() - c.toDouble()) * tx);
    return (top + ((bottom - top) * ty)).round().clamp(0, 255);
  }

  return (
    interpolate(p00.r, p10.r, p01.r, p11.r),
    interpolate(p00.g, p10.g, p01.g, p11.g),
    interpolate(p00.b, p10.b, p01.b, p11.b),
    interpolate(p00.a, p10.a, p01.a, p11.a),
  );
}
