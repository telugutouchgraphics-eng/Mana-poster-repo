part of '../image_editor_screen.dart';

enum _ProceduralFramePreset {
  classic,
  doubleLine,
  film,
  polaroid,
  neon,
  ornate,
}

extension _EditorFrameLensState on _ImageEditorScreenState {
  static const String _framePreviewLayerId = '__frame_preview__';

  Future<void> _openFramePickerOverlay() async {
    var previewRequest = 0;
    Future<void> updatePreview(_FramePickerResult preview) async {
      final request = ++previewRequest;
      final aspectRatio = (_pageAspectRatio ?? 1).clamp(0.2, 5).toDouble();
      final bytes = await _renderProceduralFrame(
        preset: preview.preset,
        color: preview.color,
        pageAspectRatio: aspectRatio,
        thickness: preview.thickness,
      );
      if (!mounted || request != previewRequest || bytes == null) {
        return;
      }
      final previewLayer = _createFrameLayer(
        id: _framePreviewLayerId,
        bytes: bytes,
        aspectRatio: aspectRatio,
        preset: preview.preset,
        color: preview.color,
        thickness: preview.thickness,
      );
      setState(() {
        final existingIndex = _layers.indexWhere(
          (layer) => layer.id == _framePreviewLayerId,
        );
        if (existingIndex >= 0) {
          _layers[existingIndex] = previewLayer;
        } else {
          _layers.add(previewLayer);
        }
        _selectedLayerId = _framePreviewLayerId;
        _transformationController.value = Matrix4.copy(previewLayer.transform);
      });
    }

    final result = await showModalBottomSheet<_FramePickerResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (sheetContext) => _FramePickerSheet(onPreview: updatePreview),
    );
    previewRequest++;
    if (!mounted || result == null) {
      _removeFramePreviewLayer();
      return;
    }
    final aspectRatio = (_pageAspectRatio ?? 1).clamp(0.2, 5).toDouble();
    final bytes = await _renderProceduralFrame(
      preset: result.preset,
      color: result.color,
      pageAspectRatio: aspectRatio,
      thickness: result.thickness,
    );
    if (!mounted || bytes == null) {
      _removeFramePreviewLayer();
      return;
    }
    _removeFramePreviewLayer(selectFallback: false);
    final layer = _createFrameLayer(
      id: 'layer_${_layerSeed++}',
      bytes: bytes,
      aspectRatio: aspectRatio,
      preset: result.preset,
      color: result.color,
      thickness: result.thickness,
    );
    _pushLayerInsertHistoryEntry(
      layer: layer,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: layer.id,
    );
    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
      _transformationController.value = Matrix4.copy(layer.transform);
      _activeMainToolLabel = '';
    });
  }

  _CanvasLayer _createFrameLayer({
    required String id,
    required Uint8List bytes,
    required double aspectRatio,
    required _ProceduralFramePreset preset,
    required Color color,
    required double thickness,
  }) {
    return _CanvasLayer(
      id: id,
      type: _CanvasLayerType.photo,
      bytes: bytes,
      originalPhotoBytes: bytes,
      photoAspectRatio: aspectRatio,
      photoFramePreset: preset.name,
      photoFrameColor: color,
      photoFrameThickness: thickness,
      fillPageBounds: true,
      transform: Matrix4.identity(),
    );
  }

  Future<void> _openSelectedFrameColorPickerOverlay() async {
    final selected = _selectedLayer;
    if (selected == null ||
        !selected.isPhoto ||
        selected.photoFramePreset.trim().isEmpty ||
        selected.isLocked) {
      return;
    }
    final result = await _pushPremiumOverlay<_TextColorSelection>(
      _TextColorPickerScreen(
        colors: _textColors.take(50).toList(growable: false),
        gradients: const <List<Color>>[],
        selectedColor: selected.photoFrameColor,
        selectedGradientIndex: -1,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    final preset = _ProceduralFramePreset.values.firstWhere(
      (item) => item.name == selected.photoFramePreset,
      orElse: () => _ProceduralFramePreset.classic,
    );
    final aspectRatio =
        (selected.photoAspectRatio ?? _pageAspectRatio ?? 1)
            .clamp(0.2, 5)
            .toDouble();
    final bytes = await _renderProceduralFrame(
      preset: preset,
      color: result.textColor,
      pageAspectRatio: aspectRatio,
      thickness: selected.photoFrameThickness,
    );
    if (!mounted || bytes == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selected.id);
    if (index == -1 || !_layers[index].isPhoto || _layers[index].isLocked) {
      return;
    }
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      bytes: bytes,
      originalPhotoBytes: bytes,
      photoFrameColor: result.textColor,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _removeFramePreviewLayer({bool selectFallback = true}) {
    final previewIndex = _layers.indexWhere(
      (layer) => layer.id == _framePreviewLayerId,
    );
    if (previewIndex < 0) {
      return;
    }
    setState(() {
      _layers.removeAt(previewIndex);
      if (selectFallback && _selectedLayerId == _framePreviewLayerId) {
        _selectedLayerId = _layers.isEmpty ? null : _layers.last.id;
        _syncControllerFromSelection();
      }
    });
  }

  Future<Uint8List?> _renderProceduralFrame({
    required _ProceduralFramePreset preset,
    required Color color,
    required double pageAspectRatio,
    required double thickness,
  }) async {
    const width = 1440;
    final height = (width / pageAspectRatio).round().clamp(288, 4096);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintProceduralFrame(
      canvas,
      Size(width.toDouble(), height.toDouble()),
      preset: preset,
      color: color,
      thickness: thickness,
    );
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(width, height);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}

@immutable
class _FramePickerResult {
  const _FramePickerResult({
    required this.preset,
    required this.color,
    required this.thickness,
  });

  final _ProceduralFramePreset preset;
  final Color color;
  final double thickness;
}

class _FramePickerSheet extends StatefulWidget {
  const _FramePickerSheet({required this.onPreview});

  final ValueChanged<_FramePickerResult> onPreview;

  @override
  State<_FramePickerSheet> createState() => _FramePickerSheetState();
}

class _FramePickerSheetState extends State<_FramePickerSheet> {
  _ProceduralFramePreset _preset = _ProceduralFramePreset.classic;
  Color _color = Colors.white;
  double _thickness = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preview());
  }

  void _preview() {
    if (!mounted) {
      return;
    }
    widget.onPreview(
      _FramePickerResult(preset: _preset, color: _color, thickness: _thickness),
    );
  }

  void _selectPreset(_ProceduralFramePreset preset) {
    setState(() => _preset = preset);
    _preview();
  }

  void _selectColor(Color color) {
    setState(() => _color = color);
    _preview();
  }

  void _setThickness(double value) {
    setState(() => _thickness = value);
    _preview();
  }

  static const colors = <Color>[
    Colors.white,
    Colors.black,
    Color(0xFFFFD166),
    Color(0xFFFF5E7A),
    Color(0xFF5AC8FA),
    Color(0xFF9B7BFF),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: _EditorGlassSurface(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.filter_frames_rounded, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      context.strings.localized(
                        telugu: 'ఫ్రేమ్స్',
                        english: 'Frames',
                      ),
                      style: const TextStyle(
                        color: _editorChromeTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(
                        _FramePickerResult(
                          preset: _preset,
                          color: _color,
                          thickness: _thickness,
                        ),
                      ),
                      child: Text(
                        context.strings.localized(
                          telugu: 'అప్లై',
                          english: 'Apply',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _ProceduralFramePreset.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 9),
                    itemBuilder: (context, index) {
                      final preset = _ProceduralFramePreset.values[index];
                      return _ProceduralFrameCard(
                        preset: preset,
                        color: _color,
                        selected: preset == _preset,
                        onTap: () => _selectPreset(preset),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: colors
                      .map(
                        (color) => Expanded(
                          child: Center(
                            child: InkResponse(
                              onTap: () => _selectColor(color),
                              radius: 22,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _color == color
                                        ? const Color(0xFF4DA3FF)
                                        : Colors.white38,
                                    width: _color == color ? 3 : 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                _FrameLensSlider(
                  label: context.strings.localized(
                    telugu: 'మందం',
                    english: 'Thickness',
                  ),
                  value: _thickness,
                  min: 10,
                  max: 100,
                  onChanged: _setThickness,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProceduralFrameCard extends StatelessWidget {
  const _ProceduralFrameCard({
    required this.preset,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final _ProceduralFramePreset preset;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 82,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB).withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF4DA3FF) : Colors.white12,
          ),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: CustomPaint(
                painter: _FrameThumbnailPainter(preset: preset, color: color),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _framePresetLabel(preset),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _editorChromeTextSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameLensSlider extends StatelessWidget {
  const _FrameLensSlider({
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
      height: 42,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 78,
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

class _FrameThumbnailPainter extends CustomPainter {
  const _FrameThumbnailPainter({required this.preset, required this.color});

  final _ProceduralFramePreset preset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF44464D),
    );
    _paintProceduralFrame(
      canvas,
      size,
      preset: preset,
      color: color,
      thickness: 42,
    );
  }

  @override
  bool shouldRepaint(covariant _FrameThumbnailPainter oldDelegate) =>
      oldDelegate.preset != preset || oldDelegate.color != color;
}

void _paintProceduralFrame(
  Canvas canvas,
  Size size, {
  required _ProceduralFramePreset preset,
  required Color color,
  required double thickness,
}) {
  final unit = math.min(size.width, size.height) / 1000;
  final stroke = (thickness * unit).clamp(1.5, 120.0).toDouble();
  final rect = Offset.zero & size;
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  switch (preset) {
    case _ProceduralFramePreset.classic:
      canvas.drawRect(rect.deflate(stroke / 2), paint..strokeWidth = stroke);
    case _ProceduralFramePreset.doubleLine:
      canvas.drawRect(
        rect.deflate(stroke * 0.55),
        paint..strokeWidth = stroke * 0.55,
      );
      canvas.drawRect(
        rect.deflate(stroke * 1.65),
        paint..strokeWidth = stroke * 0.24,
      );
    case _ProceduralFramePreset.film:
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.35,
      );
      final hole = math.max(3.0, stroke * 0.28);
      final spacing = hole * 1.8;
      for (double x = stroke * 0.75; x < size.width; x += spacing) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, stroke * 0.62),
              width: hole,
              height: hole * 0.72,
            ),
            Radius.circular(hole * 0.15),
          ),
          Paint()
            ..color = const Color(0x00000000)
            ..blendMode = BlendMode.clear,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, size.height - stroke * 0.62),
              width: hole,
              height: hole * 0.72,
            ),
            Radius.circular(hole * 0.15),
          ),
          Paint()
            ..color = const Color(0x00000000)
            ..blendMode = BlendMode.clear,
        );
      }
    case _ProceduralFramePreset.polaroid:
      final side = stroke * 1.1;
      final bottom = stroke * 2.8;
      final path = Path()
        ..addRect(Rect.fromLTRB(0, 0, size.width, side))
        ..addRect(
          Rect.fromLTRB(0, size.height - bottom, size.width, size.height),
        )
        ..addRect(Rect.fromLTRB(0, 0, side, size.height))
        ..addRect(Rect.fromLTRB(size.width - side, 0, size.width, size.height));
      canvas.drawPath(path, Paint()..color = color);
    case _ProceduralFramePreset.neon:
      for (final factor in <double>[2.8, 1.7, 0.72]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(stroke * 1.1),
            Radius.circular(stroke * 0.7),
          ),
          Paint()
            ..color = color.withValues(alpha: factor == 0.72 ? 1 : 0.26)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke * factor
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              factor == 0.72 ? 0 : stroke * factor,
            ),
        );
      }
    case _ProceduralFramePreset.ornate:
      canvas.drawRect(
        rect.deflate(stroke * 0.7),
        paint..strokeWidth = stroke * 0.35,
      );
      final cornerSize = stroke * 3.8;
      for (final alignment in <Alignment>[
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ]) {
        final center = alignment.alongSize(size);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(
          alignment == Alignment.topRight
              ? math.pi / 2
              : alignment == Alignment.bottomRight
              ? math.pi
              : alignment == Alignment.bottomLeft
              ? -math.pi / 2
              : 0,
        );
        final ornament = Path()
          ..moveTo(stroke * 0.6, cornerSize)
          ..quadraticBezierTo(
            stroke * 0.8,
            stroke * 0.8,
            cornerSize,
            stroke * 0.6,
          )
          ..moveTo(stroke, cornerSize * 0.65)
          ..quadraticBezierTo(
            cornerSize * 0.35,
            cornerSize * 0.35,
            cornerSize * 0.65,
            stroke,
          );
        canvas.drawPath(
          ornament,
          paint
            ..strokeWidth = stroke * 0.38
            ..strokeCap = StrokeCap.round,
        );
        canvas.restore();
      }
  }
}

String _framePresetLabel(_ProceduralFramePreset preset) {
  return switch (preset) {
    _ProceduralFramePreset.classic => 'Classic',
    _ProceduralFramePreset.doubleLine => 'Double',
    _ProceduralFramePreset.film => 'Film',
    _ProceduralFramePreset.polaroid => 'Polaroid',
    _ProceduralFramePreset.neon => 'Neon',
    _ProceduralFramePreset.ornate => 'Ornate',
  };
}
