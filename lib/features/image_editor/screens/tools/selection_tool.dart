part of '../image_editor_screen.dart';

enum _PixelSelectionMode { rectangle, ellipse, freehand }

extension _EditorPixelSelectionState on _ImageEditorScreenState {
  Future<void> _openSelectedPhotoSelectionTool() async {
    final selected = _selectedLayer;
    if (selected == null ||
        !selected.isPhoto ||
        selected.isLocked ||
        selected.bytes == null ||
        _isCommitWorkerBusy) {
      return;
    }
    final sourceLayerId = selected.id;
    final sourceBytes = selected.bytes!;
    final result = await showGeneralDialog<_PixelSelectionResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _PixelSelectionOverlay(bytes: sourceBytes),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }
    final processed = await _runQueuedCommitJob<Map<String, Object?>>(
      jobKey: 'pixel_selection_$sourceLayerId',
      label: context.strings.localized(
        telugu: 'సెలెక్షన్ సిద్ధమవుతోంది',
        english: 'Preparing selection',
      ),
      detail: context.strings.localized(
        telugu: 'Selected pixels ను కొత్త layer గా తయారు చేస్తోంది',
        english: 'Extracting selected pixels into a new layer',
      ),
      operation: () => compute(_extractPixelSelectionBytes, <String, Object?>{
        'bytes': sourceBytes,
        'mode': result.mode.index,
        'points': <double>[
          for (final point in result.points) ...<double>[point.dx, point.dy],
        ],
        'feather': result.featherNormalized,
      }),
    );
    if (!mounted || processed == null) {
      return;
    }
    final sourceIndex = _layers.indexWhere(
      (layer) => layer.id == sourceLayerId,
    );
    final extractedBytes = processed['selection'];
    if (sourceIndex == -1) {
      return;
    }
    if (extractedBytes is! Uint8List) {
      if (processed['empty'] == true) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: const Text('No visible pixels in the selection.'),
          ),
        );
      }
      return;
    }
    final sourceWidth = processed['sourceWidth'] as int? ?? 0;
    final sourceHeight = processed['sourceHeight'] as int? ?? 0;
    final cropLeft = processed['cropLeft'] as int? ?? 0;
    final cropTop = processed['cropTop'] as int? ?? 0;
    final cropWidth = processed['cropWidth'] as int? ?? 0;
    final cropHeight = processed['cropHeight'] as int? ?? 0;
    if (sourceWidth <= 0 ||
        sourceHeight <= 0 ||
        cropWidth <= 0 ||
        cropHeight <= 0) {
      return;
    }
    final currentSource = _layers[sourceIndex];
    final pageSize = _currentStageLogicalRect().size;
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      return;
    }
    final sourceVisualSize = currentSource.fillPageBounds
        ? pageSize
        : _photoLayerVisualSize(currentSource, pageSize);
    final extractedVisualSize = Size(
      sourceVisualSize.width * (cropWidth / sourceWidth),
      sourceVisualSize.height * (cropHeight / sourceHeight),
    );
    var cropCenterOffset = Offset(
      (((cropLeft + (cropWidth / 2)) / sourceWidth) - 0.5) *
          sourceVisualSize.width,
      (((cropTop + (cropHeight / 2)) / sourceHeight) - 0.5) *
          sourceVisualSize.height,
    );
    cropCenterOffset = Offset(
      currentSource.flipPhotoHorizontally
          ? -cropCenterOffset.dx
          : cropCenterOffset.dx,
      currentSource.flipPhotoVertically
          ? -cropCenterOffset.dy
          : cropCenterOffset.dy,
    );
    final transformedCenter = MatrixUtils.transformPoint(
      currentSource.transform,
      cropCenterOffset,
    );
    final extractedTransform = Matrix4.copy(currentSource.transform)
      ..setTranslationRaw(
        transformedCenter.dx,
        transformedCenter.dy,
        currentSource.transform.storage[14],
      );
    final extractedLayer = currentSource.copyWith(
      id: 'layer_${_layerSeed++}',
      bytes: extractedBytes,
      originalPhotoBytes: extractedBytes,
      photoAspectRatio: cropWidth / cropHeight,
      photoFixedWidth: extractedVisualSize.width,
      photoFixedHeight: extractedVisualSize.height,
      fillPageBounds: false,
      isLocked: false,
      isHidden: false,
      photoMaskShape: '',
      transform: extractedTransform,
    );
    _pushUndoSnapshot();
    setState(() {
      _layers.add(extractedLayer);
      _selectedLayerId = extractedLayer.id;
    });
    _selectedPhotoRenderNotifier.value = null;
  }
}

@immutable
class _PixelSelectionResult {
  const _PixelSelectionResult({
    required this.mode,
    required this.points,
    required this.featherNormalized,
  });

  final _PixelSelectionMode mode;
  final List<Offset> points;
  final double featherNormalized;
}

class _PixelSelectionOverlay extends StatefulWidget {
  const _PixelSelectionOverlay({required this.bytes});

  final Uint8List bytes;

  @override
  State<_PixelSelectionOverlay> createState() => _PixelSelectionOverlayState();
}

class _PixelSelectionOverlayState extends State<_PixelSelectionOverlay> {
  ui.Image? _image;
  _PixelSelectionMode _mode = _PixelSelectionMode.rectangle;
  final List<Offset> _points = <Offset>[];
  double _feather = 0;
  Size _previewSize = Size.zero;

  @override
  void initState() {
    super.initState();
    unawaited(_decodeImage());
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    try {
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Offset _normalized(Offset point, Size size) => Offset(
    (point.dx / size.width).clamp(0.0, 1.0),
    (point.dy / size.height).clamp(0.0, 1.0),
  );

  void _start(DragStartDetails details, Size size) {
    final point = _normalized(details.localPosition, size);
    setState(() {
      _points
        ..clear()
        ..add(point);
      if (_mode != _PixelSelectionMode.freehand) {
        _points.add(point);
      }
    });
  }

  void _update(DragUpdateDetails details, Size size) {
    if (_points.isEmpty) {
      return;
    }
    final point = _normalized(details.localPosition, size);
    setState(() {
      if (_mode == _PixelSelectionMode.freehand) {
        if ((_points.last - point).distance >= 0.002) {
          _points.add(point);
        }
      } else {
        _points[1] = point;
      }
    });
  }

  bool get _hasValidSelection {
    if (_mode == _PixelSelectionMode.freehand) {
      return _points.length >= 3;
    }
    return _points.length == 2 &&
        (_points.first.dx - _points.last.dx).abs() > 0.005 &&
        (_points.first.dy - _points.last.dy).abs() > 0.005;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final strings = context.strings;
    return Material(
      color: _editorCanvasBackdrop,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 54,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Text(
                    strings.localized(
                      telugu: 'సెలెక్షన్',
                      english: 'Selection',
                    ),
                    style: const TextStyle(
                      color: _editorChromeTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Clear selection',
                    onPressed: _points.isEmpty
                        ? null
                        : () => setState(() => _points.clear()),
                    icon: const Icon(Icons.deselect_rounded),
                  ),
                  FilledButton(
                    onPressed: !_hasValidSelection || _previewSize.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(
                            _PixelSelectionResult(
                              mode: _mode,
                              points: List<Offset>.from(_points),
                              featherNormalized:
                                  _feather / _previewSize.shortestSide,
                            ),
                          ),
                    child: Text(
                      strings.localized(telugu: 'అప్లై', english: 'Apply'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: image == null
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: image.width / image.height,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.biggest;
                              _previewSize = size;
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) => _start(details, size),
                                onPanUpdate: (details) =>
                                    _update(details, size),
                                child: ClipRect(
                                  child: CustomPaint(
                                    painter: _PixelSelectionPreviewPainter(
                                      image: image,
                                      mode: _mode,
                                      points: _points,
                                      feather: _feather,
                                    ),
                                    size: Size.infinite,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
              decoration: BoxDecoration(
                color: _editorChromeSurfaceStrong.withValues(alpha: 0.25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: _PixelSelectionMode.values
                        .map(
                          (mode) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: _SelectionModeButton(
                                label: _selectionModeLabel(context, mode),
                                icon: _selectionModeIcon(mode),
                                selected: _mode == mode,
                                onTap: () => setState(() {
                                  _mode = mode;
                                  _points.clear();
                                }),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 76,
                          child: Text(
                            strings.localized(
                              telugu: 'ఫెదర్',
                              english: 'Feather',
                            ),
                            style: const TextStyle(
                              color: _editorChromeTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _feather,
                            min: 0,
                            max: 40,
                            divisions: 40,
                            onChanged: (value) =>
                                setState(() => _feather = value),
                          ),
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            _feather.round().toString(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: _editorChromeTextSecondary,
                              fontSize: 11,
                            ),
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
    );
  }
}

class _SelectionModeButton extends StatelessWidget {
  const _SelectionModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _selectionModeLabel(BuildContext context, _PixelSelectionMode mode) {
  return switch (mode) {
    _PixelSelectionMode.rectangle => context.strings.localized(
      telugu: 'రెక్టాంగిల్',
      english: 'Rectangle',
    ),
    _PixelSelectionMode.ellipse => context.strings.localized(
      telugu: 'ఎలిప్స్',
      english: 'Ellipse',
    ),
    _PixelSelectionMode.freehand => context.strings.localized(
      telugu: 'ఫ్రీహ్యాండ్',
      english: 'Freehand',
    ),
  };
}

IconData _selectionModeIcon(_PixelSelectionMode mode) {
  return switch (mode) {
    _PixelSelectionMode.rectangle => Icons.crop_square_rounded,
    _PixelSelectionMode.ellipse => Icons.circle_outlined,
    _PixelSelectionMode.freehand => Icons.gesture_rounded,
  };
}

class _PixelSelectionPreviewPainter extends CustomPainter {
  const _PixelSelectionPreviewPainter({
    required this.image,
    required this.mode,
    required this.points,
    required this.feather,
  });

  final ui.Image image;
  final _PixelSelectionMode mode;
  final List<Offset> points;
  final double feather;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
    if (points.isEmpty) {
      return;
    }
    final selectionPath = _selectionPathForPreview(mode, points, size);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );
    canvas.drawPath(
      selectionPath,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill
        ..maskFilter = feather > 0
            ? MaskFilter.blur(BlurStyle.normal, feather * 0.45)
            : null,
    );
    canvas.restore();
    canvas.drawPath(
      selectionPath,
      Paint()
        ..color = const Color(0xFF4DA3FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelSelectionPreviewPainter oldDelegate) =>
      true;
}

Path _selectionPathForPreview(
  _PixelSelectionMode mode,
  List<Offset> points,
  Size size,
) {
  Offset denormalize(Offset point) =>
      Offset(point.dx * size.width, point.dy * size.height);
  if (mode != _PixelSelectionMode.freehand && points.length >= 2) {
    final rect = Rect.fromPoints(
      denormalize(points.first),
      denormalize(points.last),
    );
    return mode == _PixelSelectionMode.ellipse
        ? (Path()..addOval(rect))
        : (Path()..addRect(rect));
  }
  final path = Path();
  if (points.isNotEmpty) {
    final first = denormalize(points.first);
    path.moveTo(first.dx, first.dy);
    for (final point in points.skip(1)) {
      final resolved = denormalize(point);
      path.lineTo(resolved.dx, resolved.dy);
    }
    if (points.length >= 3) {
      path.close();
    }
  }
  return path;
}

@visibleForTesting
Map<String, Object?> extractPixelSelectionBytesForTesting(
  Map<String, Object?> input,
) => _extractPixelSelectionBytes(input);

Map<String, Object?> _extractPixelSelectionBytes(Map<String, Object?> input) {
  final bytes = input['bytes'] as Uint8List;
  final modeIndex = (input['mode'] as int?) ?? 0;
  final mode = _PixelSelectionMode
      .values[modeIndex.clamp(0, _PixelSelectionMode.values.length - 1)];
  final flatPoints = (input['points'] as List)
      .cast<num>()
      .map((value) => value.toDouble())
      .toList(growable: false);
  final decoded = img.decodeImage(bytes);
  if (decoded == null || flatPoints.length < 4) {
    return <String, Object?>{'selection': bytes};
  }
  final source = img.Image.from(decoded).convert(numChannels: 4);
  final width = source.width;
  final height = source.height;
  final points = <Offset>[
    for (var index = 0; index + 1 < flatPoints.length; index += 2)
      Offset(flatPoints[index] * width, flatPoints[index + 1] * height),
  ];
  final minX = points.map((point) => point.dx).reduce(math.min);
  final maxX = points.map((point) => point.dx).reduce(math.max);
  final minY = points.map((point) => point.dy).reduce(math.min);
  final maxY = points.map((point) => point.dy).reduce(math.max);
  final left = minX.floor().clamp(0, width - 1);
  final right = maxX.ceil().clamp(0, width - 1);
  final top = minY.floor().clamp(0, height - 1);
  final bottom = maxY.ceil().clamp(0, height - 1);
  var mask = Uint8List(width * height);

  bool selected(double x, double y) {
    if (mode == _PixelSelectionMode.rectangle) {
      return x >= minX && x <= maxX && y >= minY && y <= maxY;
    }
    if (mode == _PixelSelectionMode.ellipse) {
      final radiusX = math.max(0.5, (maxX - minX) / 2);
      final radiusY = math.max(0.5, (maxY - minY) / 2);
      final centerX = (minX + maxX) / 2;
      final centerY = (minY + maxY) / 2;
      final dx = (x - centerX) / radiusX;
      final dy = (y - centerY) / radiusY;
      return (dx * dx) + (dy * dy) <= 1;
    }
    var inside = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final a = points[i];
      final b = points[j];
      final intersects =
          ((a.dy > y) != (b.dy > y)) &&
          (x <
              ((b.dx - a.dx) * (y - a.dy) / ((b.dy - a.dy) + 0.000001)) + a.dx);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  for (var y = top; y <= bottom; y++) {
    for (var x = left; x <= right; x++) {
      if (selected(x + 0.5, y + 0.5)) {
        mask[(y * width) + x] = 255;
      }
    }
  }
  final featherNormalized = (input['feather'] as num?)?.toDouble() ?? 0;
  final featherRadius = (featherNormalized * math.min(width, height))
      .round()
      .clamp(0, 80);
  if (featherRadius > 0) {
    mask = _blurSelectionMask(mask, width, height, featherRadius);
  }

  final selection = img.Image(width: width, height: height, numChannels: 4);
  var alphaLeft = width;
  var alphaTop = height;
  var alphaRight = -1;
  var alphaBottom = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = source.getPixel(x, y);
      final coverage = mask[(y * width) + x] / 255;
      final selectedAlpha = (pixel.a * coverage).round().clamp(0, 255);
      selection.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, selectedAlpha);
      if (selectedAlpha > 0) {
        alphaLeft = math.min(alphaLeft, x);
        alphaTop = math.min(alphaTop, y);
        alphaRight = math.max(alphaRight, x);
        alphaBottom = math.max(alphaBottom, y);
      }
    }
  }
  if (alphaRight < alphaLeft || alphaBottom < alphaTop) {
    return <String, Object?>{'empty': true};
  }
  final cropWidth = alphaRight - alphaLeft + 1;
  final cropHeight = alphaBottom - alphaTop + 1;
  final croppedSelection = img.copyCrop(
    selection,
    x: alphaLeft,
    y: alphaTop,
    width: cropWidth,
    height: cropHeight,
  );
  return <String, Object?>{
    'selection': Uint8List.fromList(img.encodePng(croppedSelection)),
    'sourceWidth': width,
    'sourceHeight': height,
    'cropLeft': alphaLeft,
    'cropTop': alphaTop,
    'cropWidth': cropWidth,
    'cropHeight': cropHeight,
  };
}

Uint8List _blurSelectionMask(
  Uint8List source,
  int width,
  int height,
  int radius,
) {
  final horizontal = Uint8List(width * height);
  final window = (radius * 2) + 1;
  for (var y = 0; y < height; y++) {
    var sum = 0;
    for (var x = -radius; x <= radius; x++) {
      sum += source[(y * width) + x.clamp(0, width - 1)];
    }
    for (var x = 0; x < width; x++) {
      horizontal[(y * width) + x] = (sum / window).round();
      final removeX = (x - radius).clamp(0, width - 1);
      final addX = (x + radius + 1).clamp(0, width - 1);
      sum += source[(y * width) + addX] - source[(y * width) + removeX];
    }
  }
  final output = Uint8List(width * height);
  for (var x = 0; x < width; x++) {
    var sum = 0;
    for (var y = -radius; y <= radius; y++) {
      sum += horizontal[(y.clamp(0, height - 1) * width) + x];
    }
    for (var y = 0; y < height; y++) {
      output[(y * width) + x] = (sum / window).round();
      final removeY = (y - radius).clamp(0, height - 1);
      final addY = (y + radius + 1).clamp(0, height - 1);
      sum += horizontal[(addY * width) + x] - horizontal[(removeY * width) + x];
    }
  }
  return output;
}
