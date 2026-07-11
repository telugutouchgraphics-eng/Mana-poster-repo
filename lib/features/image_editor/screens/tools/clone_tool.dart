part of '../image_editor_screen.dart';

extension _EditorCloneToolState on _ImageEditorScreenState {
  double get _cloneBrushCanvasRadius =>
      (_cloneBrushSize / 2) / math.max(0.1, _workspaceZoom);

  void _activatePhotoCloneMode() {
    final selected = _selectedLayer;
    if (selected == null ||
        !selected.isPhoto ||
        selected.isLocked ||
        selected.bytes == null ||
        _isCommitWorkerBusy) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(content: const Text('Select a photo first')),
      );
      return;
    }
    if (_selectedTextFocusNode.hasFocus) {
      _selectedTextFocusNode.unfocus();
    }
    _commitSelectedTextContentEdit();
    setState(() {
      _isPhotoCloneMode = true;
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isDrawBrushMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _isMagicWandMode = false;
      _isAdjustMode = false;
      _isCropMode = false;
      _isTextPlacementMode = false;
      _showTextControls = false;
      _showSelectedLayerHandles = false;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
      _activeMainToolLabel = 'Clone';
      _cloneStrokePoints = <Offset>[];
      _clonePreviewStampPoints = <Offset>[];
      _cloneStrokeLayerId = null;
      _cloneStrokeLayerSize = Size.zero;
    });
    unawaited(_prepareClonePreviewImage(selected));
    _showCloneBrushCursorPreview();
  }

  void _closePhotoCloneMode() {
    setState(() {
      _isPhotoCloneMode = false;
      _cloneStrokePoints = <Offset>[];
      _clonePreviewStampPoints = <Offset>[];
      _cloneStrokeLayerId = null;
      _cloneStrokeLayerSize = Size.zero;
      _cloneSourcePoint = null;
      _cloneAlignedSampleOffset = null;
      _clonePreviewImage?.dispose();
      _clonePreviewImage = null;
      _clonePreviewLayerId = null;
      _showSelectedLayerHandles = true;
      _eraserPreviewNotifier.value = null;
      _restoreSelectedLayerToolContextFields();
    });
  }

  Future<void> _prepareClonePreviewImage(_CanvasLayer layer) async {
    final bytes = layer.bytes;
    if (bytes == null) {
      return;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      if (!mounted ||
          !_isPhotoCloneMode ||
          _selectedLayerId != layer.id ||
          !identical(_selectedLayer?.bytes, bytes)) {
        frame.image.dispose();
        return;
      }
      _clonePreviewImage?.dispose();
      _clonePreviewImage = frame.image;
      _clonePreviewLayerId = layer.id;
      _publishClonePreview();
    } finally {
      codec.dispose();
    }
  }

  void _handlePhotoCloneSourceTap(Offset localPosition, Size layerSize) {
    if (!_isPhotoCloneMode || _isCommitWorkerBusy || layerSize.isEmpty) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null ||
        !_hasSelectedPhotoLayer ||
        _isSelectedLayerLocked) {
      return;
    }
    final source = _normalizeEraserPoint(localPosition, layerSize);
    _rememberLayerBrushPreviewPoint(selectedId, source);
    setState(() {
      _cloneSourcePoint = source;
      _cloneAlignedSampleOffset = null;
      _cloneStrokePoints = <Offset>[];
      _clonePreviewStampPoints = <Offset>[];
      _cloneStrokeLayerId = null;
      _cloneStrokeLayerSize = Size.zero;
    });
    HapticFeedback.selectionClick();
    _showCloneBrushCursorPreview(source);
  }

  void _handlePhotoCloneStart(Offset localPosition, Size layerSize) {
    if (!_isPhotoCloneMode || _isCommitWorkerBusy || layerSize.isEmpty) {
      return;
    }
    final selectedId = _selectedLayerId;
    final source = _cloneSourcePoint;
    if (selectedId == null ||
        source == null ||
        !_hasSelectedPhotoLayer ||
        _isSelectedLayerLocked) {
      if (source == null) {
        _handlePhotoCloneSourceTap(localPosition, layerSize);
      }
      return;
    }
    final start = _normalizeEraserPoint(localPosition, layerSize);
    _rememberLayerBrushPreviewPoint(selectedId, start);
    final sampleOffset = _cloneAligned
        ? (_cloneAlignedSampleOffset ?? source - start)
        : source - start;
    if (_clonePreviewImage == null || _clonePreviewLayerId != selectedId) {
      final selected = _selectedLayer;
      if (selected != null && selected.bytes != null) {
        unawaited(_prepareClonePreviewImage(selected));
      }
    }
    setState(() {
      if (_cloneAligned) {
        _cloneAlignedSampleOffset = sampleOffset;
      }
      _cloneStrokeLayerId = selectedId;
      _cloneStrokeLayerSize = layerSize;
      _cloneStrokePoints = <Offset>[start];
      _clonePreviewStampPoints = <Offset>[start];
    });
    _publishClonePreview();
  }

  void _appendClonePreviewStamps(Offset previous, Offset current, Size size) {
    final spacing =
        (_cloneBrushCanvasRadius / math.max(size.width, size.height)) * 0.42;
    final normalizedSpacing = spacing.clamp(0.002, 0.022).toDouble();
    final distance = (current - previous).distance;
    final steps = math.max(1, (distance / normalizedSpacing).ceil());
    for (var step = 1; step <= steps; step++) {
      final point = Offset.lerp(previous, current, step / steps)!;
      if (_clonePreviewStampPoints.isNotEmpty &&
          (_clonePreviewStampPoints.last - point).distance <
              normalizedSpacing * 0.68) {
        continue;
      }
      _clonePreviewStampPoints.add(point);
    }
  }

  void _handlePhotoCloneUpdate(Offset localPosition, Size layerSize) {
    if (!_isPhotoCloneMode ||
        _isCommitWorkerBusy ||
        _cloneStrokeLayerId == null ||
        layerSize.isEmpty) {
      return;
    }
    final nextPoint = _normalizeEraserPoint(localPosition, layerSize);
    _rememberLayerBrushPreviewPoint(_cloneStrokeLayerId!, nextPoint);
    final previousPoint = _cloneStrokePoints.isEmpty
        ? null
        : _cloneStrokePoints.last;
    if (previousPoint != null) {
      final minStep =
          (_cloneBrushCanvasRadius /
              math.max(layerSize.width, layerSize.height)) *
          0.24;
      if ((nextPoint - previousPoint).distance < minStep.clamp(0.0016, 0.016)) {
        return;
      }
      _appendClonePreviewStamps(previousPoint, nextPoint, layerSize);
    }
    _cloneStrokePoints.add(nextPoint);
    _publishClonePreview();
  }

  Future<void> _handlePhotoCloneEnd() async {
    if (!_isPhotoCloneMode || _isCommitWorkerBusy) {
      _cancelPhotoCloneStroke();
      return;
    }
    final layerId = _cloneStrokeLayerId;
    final strokePoints = List<Offset>.of(_cloneStrokePoints);
    final strokeLayerSize = _cloneStrokeLayerSize;
    final source = _cloneSourcePoint;
    _cloneStrokePoints = <Offset>[];
    _clonePreviewStampPoints = <Offset>[];
    _cloneStrokeLayerId = null;
    _cloneStrokeLayerSize = Size.zero;
    if (layerId == null || source == null || strokePoints.isEmpty) {
      _showCloneBrushCursorPreview(source);
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
    final destinationStart = strokePoints.first;
    final sampleOffset = _cloneAligned
        ? (_cloneAlignedSampleOffset ?? source - destinationStart)
        : source - destinationStart;
    final encodedStroke = <String, Object?>{
      'sourceX': (destinationStart + sampleOffset).dx.clamp(0.0, 1.0),
      'sourceY': (destinationStart + sampleOffset).dy.clamp(0.0, 1.0),
      'destinationX': destinationStart.dx,
      'destinationY': destinationStart.dy,
      'sampleOffsetX': sampleOffset.dx,
      'sampleOffsetY': sampleOffset.dy,
      'radiusNormalized': strokeLayerSize.shortestSide <= 0
          ? 0.055
          : _cloneBrushCanvasRadius / strokeLayerSize.shortestSide,
      'hardness': _cloneHardness,
      'opacity': _cloneOpacity,
      'points': <double>[
        for (final point in strokePoints) ...<double>[
          point.dx.clamp(0.0, 1.0).toDouble(),
          point.dy.clamp(0.0, 1.0).toDouble(),
        ],
      ],
    };
    final resultBytes = await _runQueuedCommitJob<Uint8List>(
      jobKey: 'clone_stamp_$layerId',
      label: 'Clone',
      detail: 'Applying cloned pixels',
      showBusyMessage: false,
      showCommitState: false,
      operation: () => compute(_applyCloneStampBytes, <String, Object?>{
        'bytes': sourceBytes,
        'strokes': <Map<String, Object?>>[encodedStroke],
      }),
    );
    if (!mounted || resultBytes == null) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final currentIndex = _layers.indexWhere((item) => item.id == layerId);
    if (currentIndex == -1 || !_layers[currentIndex].isPhoto) {
      return;
    }
    final beforeLayer = _layers[currentIndex];
    final afterLayer = beforeLayer.copyWith(bytes: resultBytes);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() => _layers[currentIndex] = afterLayer);
    _selectedPhotoRenderNotifier.value = null;
    _clonePreviewImage?.dispose();
    _clonePreviewImage = null;
    _clonePreviewLayerId = null;
    unawaited(_prepareClonePreviewImage(afterLayer));
    _showCloneBrushCursorPreview(_cloneSourcePoint);
  }

  void _cancelPhotoCloneStroke() {
    _cloneStrokePoints = <Offset>[];
    _clonePreviewStampPoints = <Offset>[];
    _cloneStrokeLayerId = null;
    _cloneStrokeLayerSize = Size.zero;
    _showCloneBrushCursorPreview(_cloneSourcePoint);
  }

  void _publishClonePreview() {
    final layerId = _cloneStrokeLayerId ?? _selectedLayerId;
    final previewPoint = _cloneStrokePoints.isNotEmpty
        ? _cloneStrokePoints.last
        : _cloneSourcePoint;
    if (layerId == null || previewPoint == null) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    Offset? sampleOffset;
    final source = _cloneSourcePoint;
    if (_cloneStrokePoints.isNotEmpty && source != null) {
      final destinationStart = _cloneStrokePoints.first;
      sampleOffset = _cloneAligned
          ? (_cloneAlignedSampleOffset ?? source - destinationStart)
          : source - destinationStart;
    }
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: layerId,
      points: _cloneStrokePoints.isNotEmpty
          ? List<Offset>.of(_cloneStrokePoints)
          : <Offset>[previewPoint],
      brushSize: _cloneBrushSize,
      hardness: _cloneHardness,
      cloneSourceImage: sampleOffset == null || _clonePreviewLayerId != layerId
          ? null
          : _clonePreviewImage,
      cloneSampleOffset: sampleOffset,
      cloneStampPoints: _clonePreviewStampPoints.isEmpty
          ? null
          : List<Offset>.unmodifiable(_clonePreviewStampPoints),
      cloneOpacity: _cloneOpacity,
    );
  }

  void _showCloneBrushCursorPreview([Offset? point]) {
    if (!_isPhotoCloneMode || _isCommitWorkerBusy) {
      return;
    }
    final layerId = _selectedLayerId;
    if (layerId == null || !_hasSelectedPhotoLayer) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final previewPoint = point ?? _cloneSourcePoint;
    final resolvedPoint = _resolveLayerBrushPreviewPoint(layerId, previewPoint);
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: layerId,
      points: <Offset>[resolvedPoint],
      brushSize: _cloneBrushSize,
      hardness: _cloneHardness,
    );
  }
}

Uint8List _applyCloneStampBytes(Map<String, Object?> input) {
  final bytes = input['bytes'] as Uint8List;
  final rawStrokes = input['strokes'] as List;
  final fallbackRadiusNormalized =
      (input['radiusNormalized'] as num?)?.toDouble() ?? 0.055;
  final fallbackHardness = ((input['hardness'] as num?)?.toDouble() ?? 0.72)
      .clamp(0.0, 1.0)
      .toDouble();
  final decoded = img.decodeImage(bytes);
  if (decoded == null || rawStrokes.isEmpty) {
    return bytes;
  }
  final original = img.Image.from(decoded).convert(numChannels: 4);
  final output = img.Image.from(original);
  final width = output.width;
  final height = output.height;
  for (final raw in rawStrokes) {
    final stroke = Map<String, Object?>.from(raw as Map);
    final radiusNormalized =
        (stroke['radiusNormalized'] as num?)?.toDouble() ??
        fallbackRadiusNormalized;
    final hardness =
        ((stroke['hardness'] as num?)?.toDouble() ?? fallbackHardness)
            .clamp(0.0, 1.0)
            .toDouble();
    final opacity = ((stroke['opacity'] as num?)?.toDouble() ?? 1.0)
        .clamp(0.0, 1.0)
        .toDouble();
    final radius = (radiusNormalized * math.min(width, height))
        .clamp(2.0, math.min(width, height) / 2)
        .toDouble();
    final hardRadius = radius * hardness;
    final featherSpan = math.max(0.001, radius - hardRadius);
    final sourceX = (stroke['sourceX'] as num).toDouble() * width;
    final sourceY = (stroke['sourceY'] as num).toDouble() * height;
    final destinationX = (stroke['destinationX'] as num).toDouble() * width;
    final destinationY = (stroke['destinationY'] as num).toDouble() * height;
    final flatPoints = (stroke['points'] as List)
        .cast<num>()
        .map((value) => value.toDouble())
        .toList(growable: false);
    if (flatPoints.length < 2) {
      continue;
    }
    final points = <Offset>[
      for (var index = 0; index + 1 < flatPoints.length; index += 2)
        Offset(flatPoints[index] * width, flatPoints[index + 1] * height),
    ];
    final mask = Uint8List(width * height);

    void stamp(Offset center) {
      final left = math.max(0, (center.dx - radius).floor());
      final right = math.min(width - 1, (center.dx + radius).ceil());
      final top = math.max(0, (center.dy - radius).floor());
      final bottom = math.min(height - 1, (center.dy + radius).ceil());
      for (var y = top; y <= bottom; y++) {
        for (var x = left; x <= right; x++) {
          final dx = (x + 0.5) - center.dx;
          final dy = (y + 0.5) - center.dy;
          final distance = math.sqrt((dx * dx) + (dy * dy));
          if (distance > radius) {
            continue;
          }
          final coverage = distance <= hardRadius
              ? 1.0
              : (1 - ((distance - hardRadius) / featherSpan)).clamp(0.0, 1.0);
          final eased = coverage * coverage * (3 - (2 * coverage));
          final value = (eased * 255).round().clamp(0, 255);
          final maskIndex = (y * width) + x;
          if (value > mask[maskIndex]) {
            mask[maskIndex] = value;
          }
        }
      }
    }

    stamp(points.first);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final distance = (current - previous).distance;
      final steps = math.max(1, (distance / math.max(1, radius * 0.24)).ceil());
      for (var step = 1; step <= steps; step++) {
        stamp(Offset.lerp(previous, current, step / steps)!);
      }
    }

    final sampleOffsetX =
        ((stroke['sampleOffsetX'] as num?)?.toDouble() == null)
        ? sourceX - destinationX
        : (stroke['sampleOffsetX'] as num).toDouble() * width;
    final sampleOffsetY =
        ((stroke['sampleOffsetY'] as num?)?.toDouble() == null)
        ? sourceY - destinationY
        : (stroke['sampleOffsetY'] as num).toDouble() * height;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final coverage = (mask[(y * width) + x] / 255) * opacity;
        if (coverage <= 0) {
          continue;
        }
        final sampleX = x + sampleOffsetX;
        final sampleY = y + sampleOffsetY;
        if (sampleX < 0 ||
            sampleY < 0 ||
            sampleX > width - 1 ||
            sampleY > height - 1) {
          continue;
        }
        final source = _sampleClonePixelBilinear(original, sampleX, sampleY);
        final destination = output.getPixel(x, y);
        final sourceAlpha = (source.a / 255) * coverage;
        final destinationAlpha = destination.a.toDouble() / 255;
        final outputAlpha =
            sourceAlpha + (destinationAlpha * (1 - sourceAlpha));
        if (outputAlpha <= 0.000001) {
          output.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }
        int composite(num sourceChannel, num destinationChannel) {
          final value =
              ((sourceChannel.toDouble() * sourceAlpha) +
                  (destinationChannel.toDouble() *
                      destinationAlpha *
                      (1 - sourceAlpha))) /
              outputAlpha;
          return value.round().clamp(0, 255);
        }

        output.setPixelRgba(
          x,
          y,
          composite(source.r, destination.r),
          composite(source.g, destination.g),
          composite(source.b, destination.b),
          (outputAlpha * 255).round().clamp(0, 255),
        );
      }
    }
  }
  return Uint8List.fromList(img.encodePng(output));
}

({double r, double g, double b, double a}) _sampleClonePixelBilinear(
  img.Image image,
  double x,
  double y,
) {
  final width = image.width;
  final height = image.height;
  final x0 = x.floor().clamp(0, width - 1);
  final y0 = y.floor().clamp(0, height - 1);
  final x1 = (x0 + 1).clamp(0, width - 1);
  final y1 = (y0 + 1).clamp(0, height - 1);
  final tx = (x - x0).clamp(0.0, 1.0);
  final ty = (y - y0).clamp(0.0, 1.0);
  final p00 = image.getPixel(x0, y0);
  final p10 = image.getPixel(x1, y0);
  final p01 = image.getPixel(x0, y1);
  final p11 = image.getPixel(x1, y1);

  double mix(num a, num b, double t) => a + ((b - a) * t);
  double channel(num c00, num c10, num c01, num c11) {
    final top = mix(c00, c10, tx);
    final bottom = mix(c01, c11, tx);
    return mix(top, bottom, ty);
  }

  return (
    r: channel(p00.r, p10.r, p01.r, p11.r),
    g: channel(p00.g, p10.g, p01.g, p11.g),
    b: channel(p00.b, p10.b, p01.b, p11.b),
    a: channel(p00.a, p10.a, p01.a, p11.a),
  );
}
