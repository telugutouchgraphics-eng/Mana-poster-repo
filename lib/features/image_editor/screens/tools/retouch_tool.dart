part of '../image_editor_screen.dart';

enum _RetouchBrushMode { smooth, blemish, whiten }

@immutable
class _RetouchStroke {
  const _RetouchStroke({
    required this.mode,
    required this.points,
    required this.radiusNormalized,
    required this.strength,
  });

  final _RetouchBrushMode mode;
  final List<Offset> points;
  final double radiusNormalized;
  final double strength;
}

extension _EditorRetouchToolState on _ImageEditorScreenState {
  Future<void> _openSelectedPhotoRetouchTool() async {
    final selected = _selectedLayer;
    if (selected == null ||
        !selected.isPhoto ||
        selected.isLocked ||
        selected.bytes == null ||
        _isCommitWorkerBusy) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }
    final layerId = selected.id;
    final sourceBytes = selected.bytes!;
    final strokes = await showGeneralDialog<List<_RetouchStroke>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _RetouchToolOverlay(bytes: sourceBytes),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
    if (!mounted || strokes == null || strokes.isEmpty) {
      return;
    }
    final encoded = strokes
        .map(
          (stroke) => <String, Object?>{
            'mode': stroke.mode.index,
            'radiusNormalized': stroke.radiusNormalized,
            'strength': stroke.strength,
            'points': <double>[
              for (final point in stroke.points) ...<double>[
                point.dx,
                point.dy,
              ],
            ],
          },
        )
        .toList(growable: false);
    final resultBytes = await _runQueuedCommitJob<Uint8List>(
      jobKey: 'retouch_$layerId',
      label: context.strings.localized(
        telugu: 'రిటచ్ అప్లై అవుతోంది',
        english: 'Applying retouch',
      ),
      detail: context.strings.localized(
        telugu: 'Brush ప్రాంతాలను సహజంగా blend చేస్తోంది',
        english: 'Naturally blending the brushed areas',
      ),
      operation: () => compute(_applyRetouchBytes, <String, Object?>{
        'bytes': sourceBytes,
        'strokes': encoded,
      }),
    );
    if (!mounted || resultBytes == null) {
      return;
    }
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || !_layers[index].isPhoto) {
      return;
    }
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(bytes: resultBytes);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() => _layers[index] = afterLayer);
    _selectedPhotoRenderNotifier.value = null;
  }
}

class _RetouchToolOverlay extends StatefulWidget {
  const _RetouchToolOverlay({required this.bytes});

  final Uint8List bytes;

  @override
  State<_RetouchToolOverlay> createState() => _RetouchToolOverlayState();
}

class _RetouchToolOverlayState extends State<_RetouchToolOverlay> {
  ui.Image? _image;
  final TransformationController _viewportController =
      TransformationController();
  final List<_RetouchStroke> _strokes = <_RetouchStroke>[];
  final List<_RetouchStroke> _redoStrokes = <_RetouchStroke>[];
  List<Offset>? _activePoints;
  _RetouchBrushMode _mode = _RetouchBrushMode.smooth;
  double _brushSize = 64;
  double _strength = 0.58;
  int _activePointerCount = 0;
  bool _suppressStroke = false;

  double get _viewportScale =>
      _viewportController.value.getMaxScaleOnAxis().clamp(1.0, 8.0);

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
    _viewportController.dispose();
    super.dispose();
  }

  Offset _normalized(Offset point, Size size) => Offset(
    (point.dx / size.width).clamp(0.0, 1.0),
    (point.dy / size.height).clamp(0.0, 1.0),
  );

  void _start(DragStartDetails details, Size size) {
    if (!_canStroke) {
      return;
    }
    final points = <Offset>[_normalized(details.localPosition, size)];
    setState(() {
      _redoStrokes.clear();
      _activePoints = points;
      _strokes.add(
        _RetouchStroke(
          mode: _mode,
          points: points,
          radiusNormalized:
              ((_brushSize / 2) / _viewportScale) / size.shortestSide,
          strength: _strength,
        ),
      );
    });
  }

  void _update(DragUpdateDetails details, Size size) {
    if (!_canStroke) {
      _cancelActiveStroke();
      return;
    }
    final points = _activePoints;
    if (points == null) {
      return;
    }
    final point = _normalized(details.localPosition, size);
    if ((points.last - point).distance < 0.002) {
      return;
    }
    setState(() => points.add(point));
  }

  void _end() => _activePoints = null;

  bool get _canStroke => !_suppressStroke && _activePointerCount == 1;

  void _cancelActiveStroke() {
    final active = _activePoints;
    if (active == null) {
      _end();
      return;
    }
    setState(() {
      if (_strokes.isNotEmpty && identical(_strokes.last.points, active)) {
        _strokes.removeLast();
      }
      _activePoints = null;
    });
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
                    strings.localized(telugu: 'రిటచ్', english: 'Retouch'),
                    style: const TextStyle(
                      color: _editorChromeTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Undo stroke',
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => setState(
                            () => _redoStrokes.add(_strokes.removeLast()),
                          ),
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Redo stroke',
                    onPressed: _redoStrokes.isEmpty
                        ? null
                        : () => setState(
                            () => _strokes.add(_redoStrokes.removeLast()),
                          ),
                    icon: const Icon(Icons.redo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => setState(() {
                            _strokes.clear();
                            _redoStrokes.clear();
                          }),
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                  FilledButton(
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pop(List<_RetouchStroke>.from(_strokes)),
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
                              return ClipRect(
                                child: Listener(
                                  onPointerDown: (_) {
                                    _activePointerCount++;
                                    if (_activePointerCount > 1) {
                                      _suppressStroke = true;
                                      _cancelActiveStroke();
                                    }
                                    setState(() {});
                                  },
                                  onPointerUp: (_) {
                                    _activePointerCount = math.max(
                                      0,
                                      _activePointerCount - 1,
                                    );
                                    if (_activePointerCount == 0) {
                                      _suppressStroke = false;
                                      _end();
                                    }
                                    setState(() {});
                                  },
                                  onPointerCancel: (_) {
                                    _activePointerCount = math.max(
                                      0,
                                      _activePointerCount - 1,
                                    );
                                    if (_activePointerCount == 0) {
                                      _suppressStroke = false;
                                      _end();
                                    }
                                    setState(() {});
                                  },
                                  child: InteractiveViewer(
                                    transformationController:
                                        _viewportController,
                                    constrained: true,
                                    minScale: 1,
                                    maxScale: 8,
                                    panEnabled: _activePointerCount > 1,
                                    scaleEnabled: _activePointerCount > 1,
                                    boundaryMargin: EdgeInsets.zero,
                                    clipBehavior: Clip.none,
                                    child: AnimatedBuilder(
                                      animation: _viewportController,
                                      builder: (context, child) {
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onPanStart: (details) =>
                                              _start(details, size),
                                          onPanUpdate: (details) =>
                                              _update(details, size),
                                          onPanEnd: (_) => _end(),
                                          onPanCancel: _cancelActiveStroke,
                                          child: CustomPaint(
                                            painter: _RetouchPreviewPainter(
                                              image: image,
                                              strokes: _strokes,
                                              activeRadius:
                                                  (_brushSize / 2) /
                                                  _viewportScale,
                                              displayScale: 1 / _viewportScale,
                                            ),
                                            size: Size.infinite,
                                          ),
                                        );
                                      },
                                    ),
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
                    children: _RetouchBrushMode.values
                        .map(
                          (mode) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: _SelectionModeButton(
                                label: _retouchModeLabel(context, mode),
                                icon: _retouchModeIcon(mode),
                                selected: _mode == mode,
                                onTap: () => setState(() => _mode = mode),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  _RetouchControlRow(
                    label: strings.localized(telugu: 'సైజు', english: 'Size'),
                    value: _brushSize,
                    min: 16,
                    max: 140,
                    onChanged: (value) => setState(() => _brushSize = value),
                  ),
                  _RetouchControlRow(
                    label: strings.localized(
                      telugu: 'స్ట్రెంగ్త్',
                      english: 'Strength',
                    ),
                    value: _strength * 100,
                    min: 10,
                    max: 100,
                    onChanged: (value) =>
                        setState(() => _strength = value / 100),
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

String _retouchModeLabel(BuildContext context, _RetouchBrushMode mode) {
  return switch (mode) {
    _RetouchBrushMode.smooth => context.strings.localized(
      telugu: 'స్మూత్',
      english: 'Smooth',
    ),
    _RetouchBrushMode.blemish => context.strings.localized(
      telugu: 'బ్లెమిష్',
      english: 'Blemish',
    ),
    _RetouchBrushMode.whiten => context.strings.localized(
      telugu: 'వైటెన్',
      english: 'Whiten',
    ),
  };
}

IconData _retouchModeIcon(_RetouchBrushMode mode) {
  return switch (mode) {
    _RetouchBrushMode.smooth => Icons.blur_on_rounded,
    _RetouchBrushMode.blemish => Icons.healing_rounded,
    _RetouchBrushMode.whiten => Icons.brightness_7_rounded,
  };
}

class _RetouchControlRow extends StatelessWidget {
  const _RetouchControlRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: _editorChromeTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              value.round().toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _editorChromeTextSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetouchPreviewPainter extends CustomPainter {
  const _RetouchPreviewPainter({
    required this.image,
    required this.strokes,
    required this.activeRadius,
    required this.displayScale,
  });

  final ui.Image image;
  final List<_RetouchStroke> strokes;
  final double activeRadius;
  final double displayScale;

  @override
  void paint(Canvas canvas, Size size) {
    final sourceRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final destinationRect = Offset.zero & size;
    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) {
        continue;
      }
      final radius = stroke.radiusNormalized * size.shortestSide;
      final clipPath = _retouchStrokePath(stroke.points, size, radius);
      canvas.save();
      canvas.clipPath(clipPath);
      if (stroke.mode == _RetouchBrushMode.whiten) {
        canvas.drawImageRect(
          image,
          sourceRect,
          destinationRect,
          Paint()
            ..filterQuality = FilterQuality.high
            ..colorFilter = ColorFilter.matrix(<double>[
              1,
              0,
              0,
              0,
              36 * stroke.strength,
              0,
              1,
              0,
              0,
              36 * stroke.strength,
              0,
              0,
              1,
              0,
              36 * stroke.strength,
              0,
              0,
              0,
              1,
              0,
            ]),
        );
      } else {
        canvas.saveLayer(
          destinationRect,
          Paint()
            ..imageFilter = ui.ImageFilter.blur(
              sigmaX:
                  (stroke.mode == _RetouchBrushMode.blemish ? 5 : 2.5) *
                  stroke.strength,
              sigmaY:
                  (stroke.mode == _RetouchBrushMode.blemish ? 5 : 2.5) *
                  stroke.strength,
            ),
        );
        canvas.drawImageRect(
          image,
          sourceRect,
          destinationRect,
          Paint()..filterQuality = FilterQuality.high,
        );
        canvas.restore();
      }
      canvas.restore();
    }
    if (strokes.isNotEmpty && strokes.last.points.isNotEmpty) {
      final last = strokes.last.points.last;
      canvas.drawCircle(
        Offset(last.dx * size.width, last.dy * size.height),
        activeRadius,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * displayScale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RetouchPreviewPainter oldDelegate) => true;
}

Path _retouchStrokePath(List<Offset> points, Size size, double radius) {
  final path = Path();
  for (final point in _interpolateRetouchPoints(points, size, radius)) {
    path.addOval(
      Rect.fromCircle(
        center: Offset(point.dx * size.width, point.dy * size.height),
        radius: radius,
      ),
    );
  }
  return path;
}

Iterable<Offset> _interpolateRetouchPoints(
  List<Offset> points,
  Size size,
  double radius,
) sync* {
  if (points.isEmpty) {
    return;
  }
  yield points.first;
  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final distance = Offset(
      (current.dx - previous.dx) * size.width,
      (current.dy - previous.dy) * size.height,
    ).distance;
    final steps = math.max(1, (distance / math.max(2, radius * 0.25)).ceil());
    for (var step = 1; step <= steps; step++) {
      yield Offset.lerp(previous, current, step / steps)!;
    }
  }
}

Uint8List _applyRetouchBytes(Map<String, Object?> input) {
  final bytes = input['bytes'] as Uint8List;
  final rawStrokes = input['strokes'] as List;
  final decoded = img.decodeImage(bytes);
  if (decoded == null || rawStrokes.isEmpty) {
    return bytes;
  }
  var output = img.Image.from(decoded).convert(numChannels: 4);
  final width = output.width;
  final height = output.height;

  for (final rawStroke in rawStrokes) {
    final stroke = Map<String, Object?>.from(rawStroke as Map);
    final modeIndex = (stroke['mode'] as int?) ?? 0;
    final mode = _RetouchBrushMode
        .values[modeIndex.clamp(0, _RetouchBrushMode.values.length - 1)];
    final radius =
        (((stroke['radiusNormalized'] as num?)?.toDouble() ?? 0.07) *
                math.min(width, height))
            .clamp(3.0, math.min(width, height) / 2)
            .toDouble();
    final strength = ((stroke['strength'] as num?)?.toDouble() ?? 0.58)
        .clamp(0.1, 1.0)
        .toDouble();
    final flat = (stroke['points'] as List)
        .cast<num>()
        .map((value) => value.toDouble())
        .toList(growable: false);
    if (flat.length < 2) {
      continue;
    }
    final points = <Offset>[
      for (var index = 0; index + 1 < flat.length; index += 2)
        Offset(flat[index] * width, flat[index + 1] * height),
    ];
    final mask = _buildRetouchMask(
      points: points,
      width: width,
      height: height,
      radius: radius,
      strength: strength,
    );
    if (mode == _RetouchBrushMode.whiten) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final coverage = mask[(y * width) + x] / 255;
          if (coverage <= 0) {
            continue;
          }
          final pixel = output.getPixel(x, y);
          int whiten(num channel) =>
              (channel + ((255 - channel.toDouble()) * 0.24 * coverage))
                  .round()
                  .clamp(0, 255);
          output.setPixelRgba(
            x,
            y,
            whiten(pixel.r),
            whiten(pixel.g),
            whiten(pixel.b),
            pixel.a,
          );
        }
      }
      continue;
    }

    final maskImage = img.Image(width: width, height: height, numChannels: 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final value = mask[(y * width) + x];
        maskImage.setPixelRgba(x, y, value, value, value, 255);
      }
    }
    final blurRadius = mode == _RetouchBrushMode.blemish
        ? (radius * 0.18).round().clamp(3, 24)
        : (radius * 0.07).round().clamp(2, 12);
    final preservedAlpha = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        preservedAlpha[(y * width) + x] = output.getPixel(x, y).a.toInt();
      }
    }
    output = img.gaussianBlur(output, radius: blurRadius, mask: maskImage);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = output.getPixel(x, y);
        output.setPixelRgba(
          x,
          y,
          pixel.r,
          pixel.g,
          pixel.b,
          preservedAlpha[(y * width) + x],
        );
      }
    }
  }
  return Uint8List.fromList(img.encodePng(output));
}

Uint8List _buildRetouchMask({
  required List<Offset> points,
  required int width,
  required int height,
  required double radius,
  required double strength,
}) {
  final mask = Uint8List(width * height);
  final hardRadius = radius * 0.62;
  final featherSpan = math.max(0.001, radius - hardRadius);

  void stamp(Offset center) {
    final left = math.max(0, (center.dx - radius).floor());
    final right = math.min(width - 1, (center.dx + radius).ceil());
    final top = math.max(0, (center.dy - radius).floor());
    final bottom = math.min(height - 1, (center.dy + radius).ceil());
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        final distance = Offset(
          (x + 0.5) - center.dx,
          (y + 0.5) - center.dy,
        ).distance;
        if (distance > radius) {
          continue;
        }
        final coverage = distance <= hardRadius
            ? 1.0
            : (1 - ((distance - hardRadius) / featherSpan)).clamp(0.0, 1.0);
        final eased = coverage * coverage * (3 - (2 * coverage));
        final value = (eased * strength * 255).round().clamp(0, 255);
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
    final steps = math.max(1, (distance / math.max(1, radius * 0.22)).ceil());
    for (var step = 1; step <= steps; step++) {
      stamp(Offset.lerp(previous, current, step / steps)!);
    }
  }
  return mask;
}
