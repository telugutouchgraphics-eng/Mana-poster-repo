part of '../image_editor_screen.dart';

extension _EditorContentAwareToolState on _ImageEditorScreenState {
  void _activateContentAwareMode() {
    if (_isCommitWorkerBusy) {
      return;
    }
    if (!_hasSelectedPhotoLayer || _isSelectedLayerLocked) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(content: const Text('Select a photo first')),
      );
      return;
    }
    setState(() {
      _isContentAwareMode = true;
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isPhotoCloneMode = false;
      _isDrawBrushMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _isMagicWandMode = false;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
      _activeMainToolLabel = 'Content Aware';
      _contentAwareStrokePoints.clear();
      _contentAwareStrokeLayerId = null;
      _contentAwareStrokeLayerSize = Size.zero;
      _contentAwareActivePointers.clear();
      _suppressContentAwareStroke = false;
    });
    _showContentAwareBrushCursorPreview();
  }

  void _closeContentAwareMode() {
    setState(() {
      _isContentAwareMode = false;
      _contentAwareStrokePoints.clear();
      _contentAwareStrokeLayerId = null;
      _contentAwareStrokeLayerSize = Size.zero;
      _contentAwareActivePointers.clear();
      _suppressContentAwareStroke = false;
      _setEraserPreviewState(null);
      _restoreSelectedLayerToolContextFields();
    });
  }

  void _handleContentAwareStart(Offset localPosition, Size layerSize) {
    if (!_canUseContentAwarePointerStroke() ||
        _isCommitWorkerBusy ||
        layerSize.isEmpty) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null ||
        !_hasSelectedPhotoLayer ||
        _isSelectedLayerLocked) {
      return;
    }
    _contentAwareStrokeLayerId = selectedId;
    _contentAwareStrokeLayerSize = layerSize;
    final normalizedPoint = _normalizeEraserPoint(localPosition, layerSize);
    _rememberLayerBrushPreviewPoint(selectedId, normalizedPoint);
    _contentAwareStrokePoints
      ..clear()
      ..add(normalizedPoint);
    _publishContentAwarePreview(coalesce: false);
  }

  void _handleContentAwareUpdate(Offset localPosition, Size layerSize) {
    if (!_canUseContentAwarePointerStroke() ||
        _isCommitWorkerBusy ||
        _contentAwareStrokeLayerId == null ||
        layerSize.isEmpty) {
      return;
    }
    final nextPoint = _normalizeEraserPoint(localPosition, layerSize);
    _rememberLayerBrushPreviewPoint(_contentAwareStrokeLayerId!, nextPoint);
    final previousPoint = _contentAwareStrokePoints.isEmpty
        ? null
        : _contentAwareStrokePoints.last;
    if (previousPoint != null) {
      final brushSize = _workspaceBrushSize(_contentAwareBrushSize);
      final minStep =
          (brushSize / math.max(layerSize.width, layerSize.height)) * 0.012;
      if ((nextPoint - previousPoint).distance <
          minStep.clamp(0.00035, 0.0022)) {
        return;
      }
    }
    _contentAwareStrokePoints.add(nextPoint);
    _publishContentAwarePreview();
  }

  Future<void> _handleContentAwareEnd() async {
    if (!_isContentAwareMode || _isCommitWorkerBusy) {
      _cancelContentAwareStroke();
      return;
    }
    final layerId = _contentAwareStrokeLayerId;
    final strokePoints = List<Offset>.of(_contentAwareStrokePoints);
    final strokeLayerSize = _contentAwareStrokeLayerSize;
    _contentAwareStrokePoints.clear();
    _contentAwareStrokeLayerId = null;
    _contentAwareStrokeLayerSize = Size.zero;
    if (layerId == null || strokePoints.isEmpty) {
      _setEraserPreviewState(null);
      return;
    }
    final layerIndex = _layers.indexWhere((item) => item.id == layerId);
    if (layerIndex == -1 || !_layers[layerIndex].isPhoto) {
      _setEraserPreviewState(null);
      return;
    }
    final layer = _layers[layerIndex];
    final sourceBytes = layer.bytes;
    if (sourceBytes == null) {
      _setEraserPreviewState(null);
      return;
    }
    final flatPoints = <double>[];
    for (final point in strokePoints) {
      flatPoints
        ..add(point.dx.clamp(0.0, 1.0).toDouble())
        ..add(point.dy.clamp(0.0, 1.0).toDouble());
    }
    final brushSize = _workspaceBrushSize(_contentAwareBrushSize);
    final resultBytes = await _runQueuedCommitJob<Uint8List>(
      jobKey: 'content_aware_$layerId',
      label: 'Content Aware',
      detail: 'Blending brushed pixels into the surrounding background',
      showBusyMessage: false,
      showCommitState: true,
      compactCommitState: true,
      operation: () => compute(_applyContentAwareFillBytes, <String, Object?>{
        'bytes': sourceBytes,
        'points': flatPoints,
        'brushSize': brushSize,
        'brushRadiusNormalized': strokeLayerSize.shortestSide <= 0
            ? null
            : (brushSize / 2) / strokeLayerSize.shortestSide,
        'strength': _contentAwareStrength,
        'flipX': layer.flipPhotoHorizontally,
        'flipY': layer.flipPhotoVertically,
      }),
    );
    if (resultBytes == null || !mounted) {
      _setEraserPreviewState(null);
      return;
    }
    final currentIndex = _layers.indexWhere((item) => item.id == layerId);
    if (currentIndex == -1) {
      _setEraserPreviewState(null);
      return;
    }
    final beforeLayer = _layers[currentIndex];
    final afterLayer = beforeLayer.copyWith(bytes: resultBytes);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() => _layers[currentIndex] = afterLayer);
    _setEraserPreviewState(null);
    _selectedPhotoRenderNotifier.value = null;
    _showContentAwareBrushCursorPreview();
  }

  void _cancelContentAwareStroke() {
    _contentAwareStrokePoints.clear();
    _contentAwareStrokeLayerId = null;
    _contentAwareStrokeLayerSize = Size.zero;
    _setEraserPreviewState(null);
  }

  void _handleContentAwarePointerDown(PointerDownEvent event) {
    _contentAwareActivePointers.add(event.pointer);
    if (_contentAwareActivePointers.length > 1) {
      _suppressContentAwareStroke = true;
      _cancelContentAwareStroke();
    }
  }

  void _handleContentAwarePointerEnd(PointerEvent event) {
    _contentAwareActivePointers.remove(event.pointer);
    if (_contentAwareActivePointers.isEmpty) {
      _suppressContentAwareStroke = false;
    }
  }

  bool _canUseContentAwarePointerStroke() {
    return _isContentAwareMode &&
        !_suppressContentAwareStroke &&
        _contentAwareActivePointers.length <= 1;
  }

  void _publishContentAwarePreview({bool coalesce = true}) {
    final layerId = _contentAwareStrokeLayerId;
    if (layerId == null || _contentAwareStrokePoints.isEmpty) {
      _setEraserPreviewState(null);
      return;
    }
    _setEraserPreviewState(
      _PhotoEraserPreviewState(
        layerId: layerId,
        points: <Offset>[_contentAwareStrokePoints.last],
        strokePreviewPoints: List<Offset>.of(_contentAwareStrokePoints),
        strokePreviewOpacity: 0.2,
        brushSize: _contentAwareBrushSize,
        hardness: _contentAwareStrength,
      ),
    );
  }

  void _showContentAwareBrushCursorPreview([Offset? point]) {
    if (!_isContentAwareMode || _isCommitWorkerBusy) {
      return;
    }
    final layerId = _selectedLayerId;
    if (layerId == null || !_hasSelectedPhotoLayer) {
      _setEraserPreviewState(null);
      return;
    }
    final previewPoint = _resolveLayerBrushPreviewPoint(layerId, point);
    _setEraserPreviewState(
      _PhotoEraserPreviewState(
        layerId: layerId,
        points: <Offset>[previewPoint],
        brushSize: _contentAwareBrushSize,
        hardness: _contentAwareStrength,
      ),
    );
  }
}

Uint8List _applyContentAwareFillBytes(Map<String, Object?> input) {
  final bytes = input['bytes'] as Uint8List;
  final decoded = img.decodeImage(bytes);
  final rawPoints = (input['points'] as List?)?.cast<num>();
  if (decoded == null || rawPoints == null || rawPoints.length < 2) {
    return bytes;
  }

  final source = img.Image.from(decoded).convert(numChannels: 4);
  final output = img.Image.from(source);
  final width = output.width;
  final height = output.height;
  final strength = ((input['strength'] as num?)?.toDouble() ?? 0.82)
      .clamp(0.1, 1.0)
      .toDouble();
  final brushSize = (input['brushSize'] as num?)?.toDouble() ?? 54;
  final radiusNormalized = (input['brushRadiusNormalized'] as num?)?.toDouble();
  final radius = radiusNormalized == null || radiusNormalized <= 0
      ? ((brushSize / 2) * (width / 360.0))
      : radiusNormalized * math.min(width, height);
  final resolvedRadius = radius.clamp(3.0, math.min(width, height) / 2);
  final effectiveStrength = (strength * 0.88).clamp(0.1, 0.92).toDouble();
  final flipX = (input['flipX'] as bool?) ?? false;
  final flipY = (input['flipY'] as bool?) ?? false;

  final points = <Offset>[];
  for (var index = 0; index + 1 < rawPoints.length; index += 2) {
    final nx = rawPoints[index].toDouble();
    final ny = rawPoints[index + 1].toDouble();
    points.add(
      Offset(
        (flipX ? 1 - nx : nx).clamp(0.0, 1.0) * (width - 1),
        (flipY ? 1 - ny : ny).clamp(0.0, 1.0) * (height - 1),
      ),
    );
  }
  if (points.isEmpty) {
    return bytes;
  }

  final searchRadius = (resolvedRadius * (1.8 + strength)).round().clamp(
    10,
    96,
  );
  var minDirtyX = width - 1;
  var minDirtyY = height - 1;
  var maxDirtyX = 0;
  var maxDirtyY = 0;
  for (final point in points) {
    minDirtyX = math.min(minDirtyX, point.dx.floor());
    minDirtyY = math.min(minDirtyY, point.dy.floor());
    maxDirtyX = math.max(maxDirtyX, point.dx.ceil());
    maxDirtyY = math.max(maxDirtyY, point.dy.ceil());
  }
  final margin = (resolvedRadius + searchRadius + 16).ceil();
  final cropLeft = math.max(0, minDirtyX - margin);
  final cropTop = math.max(0, minDirtyY - margin);
  final cropRight = math.min(width - 1, maxDirtyX + margin);
  final cropBottom = math.min(height - 1, maxDirtyY + margin);
  final cropWidth = cropRight - cropLeft + 1;
  final cropHeight = cropBottom - cropTop + 1;
  if (cropWidth <= 0 || cropHeight <= 0) {
    return bytes;
  }

  final cropSource = img.copyCrop(
    source,
    x: cropLeft,
    y: cropTop,
    width: cropWidth,
    height: cropHeight,
  );
  final localPoints = points
      .map((point) => point - Offset(cropLeft.toDouble(), cropTop.toDouble()))
      .toList(growable: false);
  final cropOutput = img.Image.from(cropSource);

  final coverage = _buildContentAwareCoverage(
    points: localPoints,
    width: cropWidth,
    height: cropHeight,
    radius: resolvedRadius,
    strength: strength,
  );
  final fillMask = Uint8List(cropWidth * cropHeight);
  var fillCount = 0;
  for (var index = 0; index < coverage.length; index++) {
    if (coverage[index] > 10) {
      fillMask[index] = 1;
      fillCount++;
    }
  }
  if (fillCount == 0) {
    return bytes;
  }

  final fillPixels = _contentAwareFillPixels(
    cropSource,
    fillMask,
    cropWidth,
    cropHeight,
    searchRadius: searchRadius,
  );

  final smooth = img.Image(
    width: cropWidth,
    height: cropHeight,
    numChannels: 4,
  );
  for (var y = 0; y < cropHeight; y++) {
    for (var x = 0; x < cropWidth; x++) {
      final index = (y * cropWidth) + x;
      final base = cropSource.getPixel(x, y);
      final filled = fillPixels[index] ?? base;
      final coverageAlpha = coverage[index] / 255.0;
      final alpha =
          (Curves.easeInOut.transform(coverageAlpha) * effectiveStrength)
              .clamp(0.0, 0.94)
              .toDouble();
      final r = (base.r + ((filled.r - base.r) * alpha)).round();
      final g = (base.g + ((filled.g - base.g) * alpha)).round();
      final b = (base.b + ((filled.b - base.b) * alpha)).round();
      smooth.setPixelRgba(x, y, r, g, b, base.a);
    }
  }

  final maskImage = img.Image(
    width: cropWidth,
    height: cropHeight,
    numChannels: 4,
  );
  for (var y = 0; y < cropHeight; y++) {
    for (var x = 0; x < cropWidth; x++) {
      final value = coverage[(y * cropWidth) + x];
      maskImage.setPixelRgba(x, y, value, value, value, 255);
    }
  }
  final blurRadius = (resolvedRadius * 0.055).round().clamp(1, 8);
  final blurred = img.gaussianBlur(smooth, radius: blurRadius, mask: maskImage);
  for (var y = 0; y < cropHeight; y++) {
    for (var x = 0; x < cropWidth; x++) {
      final index = (y * cropWidth) + x;
      final blend = math.min(coverage[index] / 255.0, 1.0);
      if (blend <= 0) {
        continue;
      }
      final original = cropSource.getPixel(x, y);
      final soft = blurred.getPixel(x, y);
      cropOutput.setPixelRgba(
        x,
        y,
        (original.r + ((soft.r - original.r) * blend)).round(),
        (original.g + ((soft.g - original.g) * blend)).round(),
        (original.b + ((soft.b - original.b) * blend)).round(),
        original.a,
      );
    }
  }
  final polishRadius = (resolvedRadius * 0.028).round().clamp(1, 4);
  final polished = img.gaussianBlur(
    cropOutput,
    radius: polishRadius,
    mask: maskImage,
  );
  for (var y = 0; y < cropHeight; y++) {
    for (var x = 0; x < cropWidth; x++) {
      final index = (y * cropWidth) + x;
      final coverageAlpha = coverage[index] / 255.0;
      if (coverageAlpha <= 0) {
        continue;
      }
      final current = cropOutput.getPixel(x, y);
      final soft = polished.getPixel(x, y);
      final polish = (coverageAlpha * 0.28).clamp(0.0, 0.28).toDouble();
      cropOutput.setPixelRgba(
        x,
        y,
        (current.r + ((soft.r - current.r) * polish)).round(),
        (current.g + ((soft.g - current.g) * polish)).round(),
        (current.b + ((soft.b - current.b) * polish)).round(),
        current.a,
      );
    }
  }
  for (var y = 0; y < cropHeight; y++) {
    for (var x = 0; x < cropWidth; x++) {
      final pixel = cropOutput.getPixel(x, y);
      output.setPixelRgba(
        cropLeft + x,
        cropTop + y,
        pixel.r,
        pixel.g,
        pixel.b,
        pixel.a,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(output, level: 1));
}

Uint8List _buildContentAwareCoverage({
  required List<Offset> points,
  required int width,
  required int height,
  required double radius,
  required double strength,
}) {
  final mask = Uint8List(width * height);
  final hardRadius = radius * (0.58 + (strength * 0.22));
  final featherSpan = math.max(0.001, radius - hardRadius);
  void stamp(Offset center) {
    final minX = math.max(0, (center.dx - radius).floor());
    final maxX = math.min(width - 1, (center.dx + radius).ceil());
    final minY = math.max(0, (center.dy - radius).floor());
    final maxY = math.min(height - 1, (center.dy + radius).ceil());
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final distance = (Offset(x.toDouble(), y.toDouble()) - center).distance;
        if (distance > radius) {
          continue;
        }
        final feather = distance <= hardRadius
            ? 1.0
            : (1.0 - ((distance - hardRadius) / featherSpan)).clamp(0.0, 1.0);
        final value = (feather * 255).round();
        final index = (y * width) + x;
        if (value > mask[index]) {
          mask[index] = value;
        }
      }
    }
  }

  stamp(points.first);
  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final distance = (current - previous).distance;
    final steps = math.max(1, (distance / math.max(1.0, radius * 0.28)).ceil());
    for (var step = 1; step <= steps; step++) {
      stamp(Offset.lerp(previous, current, step / steps)!);
    }
  }
  return mask;
}

List<img.Pixel?> _contentAwareFillPixels(
  img.Image source,
  Uint8List mask,
  int width,
  int height, {
  required int searchRadius,
}) {
  final filled = List<img.Pixel?>.filled(width * height, null);
  final known = Uint8List(width * height);
  for (var index = 0; index < mask.length; index++) {
    known[index] = mask[index] == 0 ? 1 : 0;
  }

  final queue = <int>[];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width) + x;
      if (mask[index] == 0) {
        continue;
      }
      if (_hasKnownNeighbor(known, width, height, x, y)) {
        queue.add(index);
      }
    }
  }

  var cursor = 0;
  while (cursor < queue.length) {
    final index = queue[cursor++];
    if (known[index] == 1) {
      continue;
    }
    final x = index % width;
    final y = index ~/ width;
    final sampled = _sampleContentAwarePixel(
      source,
      filled,
      known,
      width,
      height,
      x,
      y,
      searchRadius,
    );
    filled[index] = sampled;
    known[index] = 1;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) {
          continue;
        }
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
          continue;
        }
        final nIndex = (ny * width) + nx;
        if (mask[nIndex] != 0 && known[nIndex] == 0) {
          queue.add(nIndex);
        }
      }
    }
  }
  return filled;
}

bool _hasKnownNeighbor(Uint8List known, int width, int height, int x, int y) {
  for (var dy = -1; dy <= 1; dy++) {
    for (var dx = -1; dx <= 1; dx++) {
      if (dx == 0 && dy == 0) {
        continue;
      }
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
        continue;
      }
      if (known[(ny * width) + nx] == 1) {
        return true;
      }
    }
  }
  return false;
}

img.Pixel _sampleContentAwarePixel(
  img.Image source,
  List<img.Pixel?> filled,
  Uint8List known,
  int width,
  int height,
  int x,
  int y,
  int searchRadius,
) {
  var totalWeight = 0.0;
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;
  var a = 0.0;
  final maxRadius = math.max(3, searchRadius);
  for (var radius = 1; radius <= maxRadius; radius++) {
    final minX = math.max(0, x - radius);
    final maxX = math.min(width - 1, x + radius);
    final minY = math.max(0, y - radius);
    final maxY = math.min(height - 1, y + radius);
    for (var yy = minY; yy <= maxY; yy++) {
      for (var xx = minX; xx <= maxX; xx++) {
        if (xx != minX && xx != maxX && yy != minY && yy != maxY) {
          continue;
        }
        final index = (yy * width) + xx;
        if (known[index] == 0) {
          continue;
        }
        final distance = math.max(
          1.0,
          (Offset(xx - x + 0.0, yy - y + 0.0)).distance,
        );
        final weight = 1.0 / (distance * distance);
        final pixel = filled[index] ?? source.getPixel(xx, yy);
        r += pixel.r * weight;
        g += pixel.g * weight;
        b += pixel.b * weight;
        a += pixel.a * weight;
        totalWeight += weight;
      }
    }
    if (totalWeight > 4.0 || radius >= 8) {
      break;
    }
  }
  if (totalWeight <= 0) {
    return source.getPixel(x.clamp(0, width - 1), y.clamp(0, height - 1));
  }
  final out = img.Image(width: 1, height: 1, numChannels: 4);
  out.setPixelRgba(
    0,
    0,
    (r / totalWeight).round().clamp(0, 255),
    (g / totalWeight).round().clamp(0, 255),
    (b / totalWeight).round().clamp(0, 255),
    (a / totalWeight).round().clamp(0, 255),
  );
  return out.getPixel(0, 0);
}
