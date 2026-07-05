part of '../image_editor_screen.dart';

@immutable
class _DrawStroke {
  const _DrawStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
    required this.brush,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final double opacity;
  final _EditorBrushPreset brush;
}

@immutable
class _EditorBrushPreset {
  const _EditorBrushPreset({
    required this.name,
    required this.label,
    required this.diameter,
    required this.spacing,
    required this.scatter,
    required this.opacity,
    required this.varyOpacity,
    this.maskAsset,
  });

  final String name;
  final String label;
  final double diameter;
  final double spacing;
  final double scatter;
  final double opacity;
  final bool varyOpacity;
  final String? maskAsset;

  static const _EditorBrushPreset marker = _EditorBrushPreset(
    name: 'marker',
    label: 'Marker',
    diameter: 12,
    spacing: 2,
    scatter: 0,
    opacity: 100,
    varyOpacity: true,
  );
}

@immutable
class _EditorBrushMask {
  const _EditorBrushMask({required this.image, required this.size});

  final ui.Image image;
  final Size size;
}

@immutable
class _DrawPreviewState {
  const _DrawPreviewState({required this.strokes, required this.brushMasks});

  final List<_DrawStroke> strokes;
  final Map<String, _EditorBrushMask> brushMasks;
}

extension _EditorDrawToolState on _ImageEditorScreenState {
  void _openDrawTool() {
    _openFreehandStrokeTool(
      activeLabel: 'Draw',
      titleTelugu: 'డ్రా',
      titleEnglish: 'Draw',
      enableBrushPresets: false,
    );
  }

  void _openBrushesTool() {
    _openFreehandStrokeTool(
      activeLabel: 'Brushes',
      titleTelugu: 'బ్రషెస్',
      titleEnglish: 'Brushes',
      enableBrushPresets: true,
    );
  }

  void _openFreehandStrokeTool({
    required String activeLabel,
    required String titleTelugu,
    required String titleEnglish,
    required bool enableBrushPresets,
  }) {
    if (_isCommitWorkerBusy || _lastCanvasSize.isEmpty) {
      return;
    }
    _commitSelectedTextContentEdit();
    _clearSelection();
    setState(() {
      _isDrawBrushMode = true;
      _drawBrushPresetsEnabled = enableBrushPresets;
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _isMagicWandMode = false;
      _isAdjustMode = false;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
      _activeMainToolLabel = activeLabel;
      _selectedLayerId = null;
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
    });
    _publishDrawPreview();
    if (enableBrushPresets) {
      unawaited(_loadDrawBrushPresets());
    }
  }

  Future<void> _applyDrawBrushStrokes() async {
    if (_isCommitWorkerBusy || _drawStrokes.isEmpty) {
      return;
    }

    final pageAspectRatio = (_pageAspectRatio ?? 1).clamp(0.2, 5).toDouble();
    final pngBytes = await _renderDrawStrokes(
      strokes: List<_DrawStroke>.unmodifiable(_drawStrokes),
      pageAspectRatio: pageAspectRatio,
    );
    if (!mounted || pngBytes == null) {
      return;
    }
    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.photo,
      bytes: pngBytes,
      originalPhotoBytes: pngBytes,
      photoAspectRatio: pageAspectRatio,
      fillPageBounds: true,
      transform: Matrix4.identity(),
    );
    final previousSelection = _selectedLayerId;
    _pushLayerInsertHistoryEntry(
      layer: layer,
      insertIndex: _layers.length,
      beforeSelectedLayerId: previousSelection,
      afterSelectedLayerId: layer.id,
    );
    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
      _isDrawBrushMode = false;
      _isPhotoStretchMode = false;
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
      _restoreSelectedLayerToolContextFields();
    });
    _drawPreviewNotifier.value = null;
    _scheduleAutosave();
  }

  void _closeDrawBrushMode() {
    setState(() {
      _isDrawBrushMode = false;
      _isPhotoStretchMode = false;
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
      _restoreSelectedLayerToolContextFields();
    });
    _drawPreviewNotifier.value = null;
  }

  void _handleDrawBrushStart(Offset localPosition, Size pageSize) {
    if (!_isDrawBrushMode || pageSize.isEmpty) {
      return;
    }
    setState(() {
      _drawRedoStrokes.clear();
      _drawActivePoints = <Offset>[
        _normalizeDrawPoint(localPosition, pageSize),
      ];
      _drawStrokes.add(
        _DrawStroke(
          points: _drawActivePoints!,
          color: _drawColor,
          width: _workspaceBrushSize(_drawBrushSize),
          opacity: _drawOpacity,
          brush: _selectedDrawBrush,
        ),
      );
    });
    _publishDrawPreview();
  }

  void _handleDrawBrushUpdate(Offset localPosition, Size pageSize) {
    if (!_isDrawBrushMode || pageSize.isEmpty) {
      return;
    }
    final points = _drawActivePoints;
    if (points == null || points.isEmpty) {
      return;
    }
    final nextPoint = _normalizeDrawPoint(localPosition, pageSize);
    final lastPoint = points.last;
    final pixelDistance = Offset(
      (nextPoint.dx - lastPoint.dx) * pageSize.width,
      (nextPoint.dy - lastPoint.dy) * pageSize.height,
    ).distance;
    if (pixelDistance < 0.45) {
      return;
    }
    final activeWidth = _drawStrokes.isEmpty
        ? _workspaceBrushSize(_drawBrushSize)
        : _drawStrokes.last.width;
    final spacing = (activeWidth * (_selectedDrawBrush.spacing / 100))
        .clamp(0.8, 7.0)
        .toDouble();
    final steps = (pixelDistance / spacing).ceil().clamp(1, 96);
    setState(() {
      for (var step = 1; step <= steps; step++) {
        points.add(Offset.lerp(lastPoint, nextPoint, step / steps)!);
      }
    });
    _publishDrawPreview();
  }

  void _handleDrawBrushEnd() {
    if (!_isDrawBrushMode) {
      return;
    }
    setState(() => _drawActivePoints = null);
    _publishDrawPreview();
  }

  void _undoDrawStroke() {
    if (_drawStrokes.isEmpty) {
      return;
    }
    setState(() {
      _drawRedoStrokes.add(_drawStrokes.removeLast());
      _drawActivePoints = null;
    });
    _publishDrawPreview();
  }

  void _redoDrawStroke() {
    if (_drawRedoStrokes.isEmpty) {
      return;
    }
    setState(() {
      _drawStrokes.add(_drawRedoStrokes.removeLast());
      _drawActivePoints = null;
    });
    _publishDrawPreview();
  }

  void _clearDrawStrokes() {
    setState(() {
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
    });
    _publishDrawPreview();
  }

  void _setDrawBrushColor(Color color) {
    setState(() => _drawColor = color);
  }

  void _setDrawBrushHue(double hue) {
    setState(() {
      _drawHue = hue;
      _drawColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    });
  }

  void _setDrawBrushSize(double size) {
    setState(() => _drawBrushSize = size);
  }

  void _setDrawBrushOpacity(double opacity) {
    setState(() => _drawOpacity = opacity);
  }

  void _selectDrawBrushPreset(_EditorBrushPreset preset) {
    setState(() {
      _selectedDrawBrush = preset;
      _drawBrushSize = preset.diameter.clamp(1, 160).toDouble();
      _drawOpacity = (preset.opacity / 100).clamp(0.05, 1).toDouble();
    });
    unawaited(_ensureDrawBrushMaskLoaded(preset));
  }

  void _publishDrawPreview() {
    if (!_isDrawBrushMode || _drawStrokes.isEmpty) {
      _drawPreviewNotifier.value = null;
      return;
    }
    _drawPreviewNotifier.value = _DrawPreviewState(
      strokes: List<_DrawStroke>.unmodifiable(_drawStrokes),
      brushMasks: Map<String, _EditorBrushMask>.unmodifiable(_drawBrushMasks),
    );
  }

  Offset _normalizeDrawPoint(Offset point, Size size) {
    return Offset(
      (point.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (point.dy / size.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  Future<void> _loadDrawBrushPresets() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/editor_brushes/draw/local_drawing_brushes.json',
      );
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return;
      }
      final brushes = decoded['brushes'];
      if (brushes is! List) {
        return;
      }
      final presets = <_EditorBrushPreset>[];
      for (final item in brushes) {
        if (item is! Map<String, Object?> || item['hidden'] == true) {
          continue;
        }
        final name = (item['name'] as String?)?.trim();
        if (name == null || name.isEmpty) {
          continue;
        }
        final settings = item['settings_parameters'];
        if (settings is! Map<String, Object?>) {
          continue;
        }
        final maskAsset = await _brushMaskAssetFor(name);
        presets.add(
          _EditorBrushPreset(
            name: name,
            label: _prettyBrushLabel(name),
            diameter: _drawNumSetting(settings, 'diameter', 24),
            spacing: _drawNumSetting(settings, 'spacing', 4),
            scatter: _drawNumSetting(settings, 'scatter', 0),
            opacity: _drawNumSetting(settings, 'opacity', 100),
            varyOpacity: settings['vary_opacity'] != false,
            maskAsset: maskAsset,
          ),
        );
      }
      if (!mounted || presets.isEmpty) {
        return;
      }
      setState(() {
        _drawBrushPresets = List<_EditorBrushPreset>.unmodifiable(presets);
        _selectedDrawBrush = _drawBrushPresets.first;
        _drawBrushSize = _selectedDrawBrush.diameter.clamp(1, 160).toDouble();
        _drawOpacity = (_selectedDrawBrush.opacity / 100)
            .clamp(0.05, 1)
            .toDouble();
      });
      for (final preset in presets.take(18)) {
        unawaited(_ensureDrawBrushMaskLoaded(preset));
      }
    } catch (_) {
      // Keep the default marker brush if bundled metadata is unavailable.
    }
  }

  Future<String?> _brushMaskAssetFor(String name) async {
    final candidate = 'assets/editor_brushes/brushes/$name.ast';
    try {
      await rootBundle.load(candidate);
      return candidate;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureDrawBrushMaskLoaded(_EditorBrushPreset preset) async {
    final asset = preset.maskAsset;
    if (asset == null || _drawBrushMasks.containsKey(asset)) {
      return;
    }
    final mask = await _loadAstBrushMask(asset);
    if (!mounted || mask == null) {
      return;
    }
    setState(() => _drawBrushMasks[asset] = mask);
    _publishDrawPreview();
  }

  Future<Uint8List?> _renderDrawStrokes({
    required List<_DrawStroke> strokes,
    required double pageAspectRatio,
  }) async {
    const outputWidth = 1440;
    final outputHeight = (outputWidth / pageAspectRatio).round().clamp(
      288,
      4096,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final outputSize = Size(outputWidth.toDouble(), outputHeight.toDouble());
    final brushMasks = await _loadBrushMasksForStrokes(strokes);
    _paintDrawStrokes(canvas, outputSize, strokes, brushMasks: brushMasks);
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(outputWidth, outputHeight);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}

class _DrawLiveInlineStrip extends StatelessWidget {
  const _DrawLiveInlineStrip({
    required this.height,
    required this.enableBrushPresets,
    required this.brushPresets,
    required this.selectedBrush,
    required this.brushMasks,
    required this.color,
    required this.hue,
    required this.brushSize,
    required this.opacity,
    required this.canUndo,
    required this.canRedo,
    required this.canApply,
    required this.onBack,
    required this.onApply,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onBrushSelected,
    required this.onBlackTap,
    required this.onWhiteTap,
    required this.onHueChanged,
    required this.onBrushSizeChanged,
    required this.onOpacityChanged,
  });

  final double height;
  final bool enableBrushPresets;
  final List<_EditorBrushPreset> brushPresets;
  final _EditorBrushPreset selectedBrush;
  final Map<String, _EditorBrushMask> brushMasks;
  final Color color;
  final double hue;
  final double brushSize;
  final double opacity;
  final bool canUndo;
  final bool canRedo;
  final bool canApply;
  final VoidCallback onBack;
  final Future<void> Function() onApply;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final ValueChanged<_EditorBrushPreset> onBrushSelected;
  final VoidCallback onBlackTap;
  final VoidCallback onWhiteTap;
  final ValueChanged<double> onHueChanged;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = MediaQuery.sizeOf(context).width < 370;
    return SizedBox(
      height: height,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: Row(
              children: <Widget>[
                _EditorIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: strings.localized(
                    telugu: 'వెనక్కి',
                    english: 'Back',
                  ),
                  compact: compact,
                  onTap: onBack,
                ),
                _EditorIconButton(
                  icon: Icons.undo_rounded,
                  tooltip: 'Undo stroke',
                  compact: true,
                  onTap: canUndo ? onUndo : null,
                ),
                _EditorIconButton(
                  icon: Icons.redo_rounded,
                  tooltip: 'Redo stroke',
                  compact: true,
                  onTap: canRedo ? onRedo : null,
                ),
                _EditorIconButton(
                  icon: Icons.delete_sweep_outlined,
                  tooltip: 'Clear',
                  compact: true,
                  onTap: canUndo ? onClear : null,
                ),
                const Spacer(),
                _InlineActionChip(
                  label: strings.localized(telugu: 'అప్లై', english: 'Apply'),
                  active: canApply,
                  compact: compact,
                  onTap: canApply ? () => unawaited(onApply()) : null,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          if (enableBrushPresets)
            _BrushPresetStrip(
              presets: brushPresets,
              selected: selectedBrush,
              masks: brushMasks,
              color: color,
              onSelected: onBrushSelected,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _DrawColorButton(
                        color: Colors.black,
                        selected: color == Colors.black,
                        onTap: onBlackTap,
                      ),
                      const SizedBox(width: 8),
                      _DrawColorButton(
                        color: Colors.white,
                        selected: color == Colors.white,
                        onTap: onWhiteTap,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DrawHueSlider(
                          value: hue,
                          onChanged: onHueChanged,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _DrawControlRow(
                      label: strings.localized(telugu: 'సైజు', english: 'Size'),
                      value: brushSize,
                      min: 1,
                      max: 80,
                      onChanged: onBrushSizeChanged,
                    ),
                  ),
                  Expanded(
                    child: _DrawControlRow(
                      label: strings.localized(
                        telugu: 'ఒపాసిటీ',
                        english: 'Opacity',
                      ),
                      value: opacity,
                      min: 0.05,
                      max: 1,
                      onChanged: onOpacityChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawToolOverlay extends StatefulWidget {
  const _DrawToolOverlay({
    required this.pageAspectRatio,
    required this.titleTelugu,
    required this.titleEnglish,
    required this.enableBrushPresets,
  });

  final double pageAspectRatio;
  final String titleTelugu;
  final String titleEnglish;
  final bool enableBrushPresets;

  @override
  State<_DrawToolOverlay> createState() => _DrawToolOverlayState();
}

class _DrawToolOverlayState extends State<_DrawToolOverlay> {
  final TransformationController _viewportController =
      TransformationController();
  final List<_DrawStroke> _strokes = <_DrawStroke>[];
  final List<_DrawStroke> _redoStrokes = <_DrawStroke>[];
  final Map<String, _EditorBrushMask> _brushMasks =
      <String, _EditorBrushMask>{};
  List<_EditorBrushPreset> _brushPresets = const <_EditorBrushPreset>[
    _EditorBrushPreset.marker,
  ];
  List<Offset>? _activePoints;
  Color _color = Colors.black;
  double _brushSize = 12;
  double _opacity = 1;
  double _hue = 0;
  _EditorBrushPreset _selectedBrush = _EditorBrushPreset.marker;
  int _activePointerCount = 0;
  bool _suppressStroke = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableBrushPresets) {
      unawaited(_loadBrushPresets());
    }
  }

  Future<void> _loadBrushPresets() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/editor_brushes/draw/local_drawing_brushes.json',
      );
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return;
      }
      final brushes = decoded['brushes'];
      if (brushes is! List) {
        return;
      }
      final presets = <_EditorBrushPreset>[];
      for (final item in brushes) {
        if (item is! Map<String, Object?> || item['hidden'] == true) {
          continue;
        }
        final name = (item['name'] as String?)?.trim();
        if (name == null || name.isEmpty) {
          continue;
        }
        final settings = item['settings_parameters'];
        if (settings is! Map<String, Object?>) {
          continue;
        }
        final maskAsset = await _brushMaskAssetFor(name);
        presets.add(
          _EditorBrushPreset(
            name: name,
            label: _prettyBrushLabel(name),
            diameter: _numSetting(settings, 'diameter', 24),
            spacing: _numSetting(settings, 'spacing', 4),
            scatter: _numSetting(settings, 'scatter', 0),
            opacity: _numSetting(settings, 'opacity', 100),
            varyOpacity: settings['vary_opacity'] != false,
            maskAsset: maskAsset,
          ),
        );
      }
      if (!mounted || presets.isEmpty) {
        return;
      }
      setState(() {
        _brushPresets = List<_EditorBrushPreset>.unmodifiable(presets);
        _selectedBrush = _brushPresets.first;
        _brushSize = _selectedBrush.diameter.clamp(1, 160).toDouble();
        _opacity = (_selectedBrush.opacity / 100).clamp(0.05, 1).toDouble();
      });
      for (final preset in presets.take(18)) {
        unawaited(_ensureBrushMaskLoaded(preset));
      }
    } catch (_) {
      // Keep the default marker brush if bundled metadata is unavailable.
    }
  }

  static double _numSetting(
    Map<String, Object?> settings,
    String key,
    double fallback,
  ) {
    return (settings[key] as num?)?.toDouble() ?? fallback;
  }

  Future<String?> _brushMaskAssetFor(String name) async {
    final candidate = 'assets/editor_brushes/brushes/$name.ast';
    try {
      await rootBundle.load(candidate);
      return candidate;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureBrushMaskLoaded(_EditorBrushPreset preset) async {
    final asset = preset.maskAsset;
    if (asset == null || _brushMasks.containsKey(asset)) {
      return;
    }
    final mask = await _loadAstBrushMask(asset);
    if (!mounted || mask == null) {
      return;
    }
    setState(() => _brushMasks[asset] = mask);
  }

  @override
  void dispose() {
    _viewportController.dispose();
    super.dispose();
  }

  void _startStroke(Offset point) {
    if (!_canStroke) {
      return;
    }
    setState(() {
      _redoStrokes.clear();
      _activePoints = <Offset>[point];
      _strokes.add(
        _DrawStroke(
          points: _activePoints!,
          color: _color,
          width: _brushSize,
          opacity: _opacity,
          brush: _selectedBrush,
        ),
      );
    });
  }

  void _extendStroke(Offset point, Size canvasSize) {
    if (!_canStroke) {
      _cancelActiveStroke();
      return;
    }
    final points = _activePoints;
    if (points == null || points.isEmpty) {
      return;
    }

    final lastPoint = points.last;
    final pixelDistance = Offset(
      (point.dx - lastPoint.dx) * canvasSize.width,
      (point.dy - lastPoint.dy) * canvasSize.height,
    ).distance;
    if (pixelDistance < 0.45) {
      return;
    }

    final spacing = (_brushSize * (_selectedBrush.spacing / 100))
        .clamp(0.8, 7.0)
        .toDouble();
    final steps = (pixelDistance / spacing).ceil().clamp(1, 96);
    setState(() {
      for (var step = 1; step <= steps; step++) {
        points.add(Offset.lerp(lastPoint, point, step / steps)!);
      }
    });
  }

  void _endStroke() {
    _activePoints = null;
  }

  bool get _canStroke => !_suppressStroke && _activePointerCount == 1;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerCount++;
    if (_activePointerCount > 1) {
      _suppressStroke = true;
      _cancelActiveStroke();
    }
    setState(() {});
  }

  void _handlePointerEnd(PointerEvent event) {
    _activePointerCount = math.max(0, _activePointerCount - 1);
    if (_activePointerCount == 0) {
      _suppressStroke = false;
      _endStroke();
    }
    setState(() {});
  }

  void _cancelActiveStroke() {
    final active = _activePoints;
    if (active == null) {
      _endStroke();
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
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).cancelButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Text(
                    strings.localized(
                      telugu: widget.titleTelugu,
                      english: widget.titleEnglish,
                    ),
                    style: const TextStyle(
                      color: _editorChromeTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Undo stroke',
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => setState(() {
                            _redoStrokes.add(_strokes.removeLast());
                            _activePoints = null;
                          }),
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Redo stroke',
                    onPressed: _redoStrokes.isEmpty
                        ? null
                        : () => setState(() {
                            _strokes.add(_redoStrokes.removeLast());
                            _activePoints = null;
                          }),
                    icon: const Icon(Icons.redo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => setState(() {
                            _strokes.clear();
                            _redoStrokes.clear();
                            _activePoints = null;
                          }),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  TextButton(
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pop(List<_DrawStroke>.from(_strokes)),
                    child: Text(
                      strings.localized(telugu: 'వర్తించు', english: 'Apply'),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: widget.pageAspectRatio,
                    child: ClipRect(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            return Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: _handlePointerDown,
                              onPointerUp: _handlePointerEnd,
                              onPointerCancel: _handlePointerEnd,
                              child: InteractiveViewer(
                                transformationController: _viewportController,
                                constrained: true,
                                minScale: 1,
                                maxScale: 8,
                                panEnabled: _activePointerCount > 1,
                                scaleEnabled: _activePointerCount > 1,
                                boundaryMargin: EdgeInsets.zero,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: (details) => _startStroke(
                                    _normalizePoint(
                                      details.localPosition,
                                      size,
                                    ),
                                  ),
                                  onPanUpdate: (details) => _extendStroke(
                                    _normalizePoint(
                                      details.localPosition,
                                      size,
                                    ),
                                    size,
                                  ),
                                  onPanEnd: (_) => _endStroke(),
                                  onPanCancel: _cancelActiveStroke,
                                  child: CustomPaint(
                                    painter: _DrawStrokesPainter(
                                      strokes: _strokes,
                                      brushMasks: _brushMasks,
                                    ),
                                    size: Size.infinite,
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
              ),
            ),
            if (widget.enableBrushPresets)
              _BrushPresetStrip(
                presets: _brushPresets,
                selected: _selectedBrush,
                masks: _brushMasks,
                color: _color,
                onSelected: (preset) {
                  setState(() {
                    _selectedBrush = preset;
                    _brushSize = preset.diameter.clamp(1, 160).toDouble();
                    _opacity = (preset.opacity / 100).clamp(0.05, 1).toDouble();
                  });
                  unawaited(_ensureBrushMaskLoaded(preset));
                },
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                color: _editorChromeSurfaceStrong.withValues(alpha: 0.25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _DrawColorButton(
                        color: Colors.black,
                        selected: _color == Colors.black,
                        onTap: () => setState(() => _color = Colors.black),
                      ),
                      const SizedBox(width: 8),
                      _DrawColorButton(
                        color: Colors.white,
                        selected: _color == Colors.white,
                        onTap: () => setState(() => _color = Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DrawHueSlider(
                          value: _hue,
                          onChanged: (value) => setState(() {
                            _hue = value;
                            _color = HSVColor.fromAHSV(
                              1,
                              value,
                              1,
                              1,
                            ).toColor();
                          }),
                        ),
                      ),
                    ],
                  ),
                  _DrawControlRow(
                    label: strings.localized(telugu: 'సైజు', english: 'Size'),
                    value: _brushSize,
                    min: 1,
                    max: 80,
                    onChanged: (value) => setState(() => _brushSize = value),
                  ),
                  _DrawControlRow(
                    label: strings.localized(
                      telugu: 'ఒపాసిటీ',
                      english: 'Opacity',
                    ),
                    value: _opacity,
                    min: 0.05,
                    max: 1,
                    onChanged: (value) => setState(() => _opacity = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Offset _normalizePoint(Offset point, Size size) {
    return Offset(
      (point.dx / size.width).clamp(0, 1),
      (point.dy / size.height).clamp(0, 1),
    );
  }
}

class _DrawControlRow extends StatelessWidget {
  const _DrawControlRow({
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
      height: 38,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(
                color: _editorChromeTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              max <= 1 ? '${(value * 100).round()}' : '${value.round()}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _editorChromeTextPrimary,
                fontSize: 11,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawColorButton extends StatelessWidget {
  const _DrawColorButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF4DA3FF) : Colors.white54,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _DrawHueSlider extends StatelessWidget {
  const _DrawHueSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => onChanged(
            (details.localPosition.dx / constraints.maxWidth * 360).clamp(
              0,
              360,
            ),
          ),
          onHorizontalDragUpdate: (details) => onChanged(
            (details.localPosition.dx / constraints.maxWidth * 360).clamp(
              0,
              360,
            ),
          ),
          child: SizedBox(
            height: 32,
            child: CustomPaint(
              painter: _DrawHuePainter(value: value),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _DrawHuePainter extends CustomPainter {
  const _DrawHuePainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = <Color>[
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ];
    final rect = Rect.fromLTWH(0, 8, size.width, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..shader = const LinearGradient(colors: colors).createShader(rect),
    );
    final x = (value / 360) * size.width;
    canvas.drawCircle(
      Offset(x.clamp(5, size.width - 5), 16),
      7,
      Paint()
        ..color = HSVColor.fromAHSV(1, value, 1, 1).toColor()
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x.clamp(5, size.width - 5), 16),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _DrawHuePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _BrushPresetStrip extends StatelessWidget {
  const _BrushPresetStrip({
    required this.presets,
    required this.selected,
    required this.masks,
    required this.color,
    required this.onSelected,
  });

  final List<_EditorBrushPreset> presets;
  final _EditorBrushPreset selected;
  final Map<String, _EditorBrushMask> masks;
  final Color color;
  final ValueChanged<_EditorBrushPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: _editorChromeSurface.withValues(alpha: 0.25),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final active = preset.name == selected.name;
          final mask = preset.maskAsset == null
              ? null
              : masks[preset.maskAsset];
          return InkResponse(
            onTap: () => onSelected(preset),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 66,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.28)
                    : const Color(0xFF2F3238),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? const Color(0xFFA78BFA) : _editorChromeBorder,
                  width: active ? 1.6 : 1,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: CustomPaint(
                      painter: _BrushPresetPreviewPainter(
                        preset: preset,
                        mask: mask,
                        color: color,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _editorChromeTextPrimary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrushPresetPreviewPainter extends CustomPainter {
  const _BrushPresetPreviewPainter({
    required this.preset,
    required this.mask,
    required this.color,
  });

  final _EditorBrushPreset preset;
  final _EditorBrushMask? mask;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final diameter = (preset.diameter / 2).clamp(10, size.shortestSide - 4);
    final rect = Rect.fromCenter(
      center: center,
      width: diameter.toDouble(),
      height: diameter.toDouble(),
    );
    final maskImage = mask?.image;
    if (maskImage != null) {
      canvas.drawImageRect(
        maskImage,
        Rect.fromLTWH(
          0,
          0,
          maskImage.width.toDouble(),
          maskImage.height.toDouble(),
        ),
        rect,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high
          ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
      );
      return;
    }
    canvas.drawCircle(
      center,
      rect.width / 2,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _BrushPresetPreviewPainter oldDelegate) {
    return oldDelegate.preset != preset ||
        oldDelegate.mask != mask ||
        oldDelegate.color != color;
  }
}

class _DrawStrokesPainter extends CustomPainter {
  const _DrawStrokesPainter({required this.strokes, required this.brushMasks});

  final List<_DrawStroke> strokes;
  final Map<String, _EditorBrushMask> brushMasks;

  @override
  void paint(Canvas canvas, Size size) {
    _paintDrawStrokes(canvas, size, strokes, brushMasks: brushMasks);
  }

  @override
  bool shouldRepaint(covariant _DrawStrokesPainter oldDelegate) => true;
}

void _paintDrawStrokes(
  Canvas canvas,
  Size size,
  List<_DrawStroke> strokes, {
  Map<String, _EditorBrushMask> brushMasks = const <String, _EditorBrushMask>{},
}) {
  for (final stroke in strokes) {
    if (stroke.points.isEmpty) {
      continue;
    }
    final maskAsset = stroke.brush.maskAsset;
    final mask = maskAsset == null ? null : brushMasks[maskAsset];
    if (mask != null) {
      _paintTexturedBrushStroke(canvas, size, stroke, mask);
      continue;
    }
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.width * (size.width / 400)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    Offset denormalize(Offset point) =>
        Offset(point.dx * size.width, point.dy * size.height);
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        denormalize(stroke.points.first),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      continue;
    }
    final path = Path()
      ..moveTo(
        denormalize(stroke.points.first).dx,
        denormalize(stroke.points.first).dy,
      );
    for (var index = 1; index < stroke.points.length - 1; index++) {
      final current = denormalize(stroke.points[index]);
      final next = denormalize(stroke.points[index + 1]);
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }
    final last = denormalize(stroke.points.last);
    path.lineTo(last.dx, last.dy);
    canvas.drawPath(path, paint);
  }
}

void _paintTexturedBrushStroke(
  Canvas canvas,
  Size size,
  _DrawStroke stroke,
  _EditorBrushMask mask,
) {
  final image = mask.image;
  final source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  final paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..colorFilter = ColorFilter.mode(
      stroke.color.withValues(alpha: stroke.opacity),
      BlendMode.srcIn,
    );
  final diameter = stroke.width * (size.width / 400);
  final scatterRadius = diameter * (stroke.brush.scatter / 100) * 0.32;
  Offset denormalize(Offset point) =>
      Offset(point.dx * size.width, point.dy * size.height);

  for (var index = 0; index < stroke.points.length; index++) {
    final center = denormalize(stroke.points[index]);
    final scatter = scatterRadius <= 0
        ? Offset.zero
        : Offset(
            math.sin(index * 12.9898) * scatterRadius,
            math.cos(index * 78.233) * scatterRadius,
          );
    final stampCenter = center + scatter;
    final rect = Rect.fromCenter(
      center: stampCenter,
      width: diameter,
      height: diameter,
    );
    canvas.drawImageRect(image, source, rect, paint);
  }
}

Future<Map<String, _EditorBrushMask>> _loadBrushMasksForStrokes(
  List<_DrawStroke> strokes,
) async {
  final masks = <String, _EditorBrushMask>{};
  for (final stroke in strokes) {
    final asset = stroke.brush.maskAsset;
    if (asset == null || masks.containsKey(asset)) {
      continue;
    }
    final mask = await _loadAstBrushMask(asset);
    if (mask != null) {
      masks[asset] = mask;
    }
  }
  return masks;
}

double _drawNumSetting(
  Map<String, Object?> settings,
  String key,
  double fallback,
) {
  return (settings[key] as num?)?.toDouble() ?? fallback;
}

Future<_EditorBrushMask?> _loadAstBrushMask(String asset) async {
  try {
    final data = await rootBundle.load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final side = math.sqrt(bytes.length).round();
    if (side <= 0 || side * side != bytes.length) {
      return null;
    }
    final rgba = Uint8List(side * side * 4);
    for (var index = 0; index < bytes.length; index++) {
      final target = index * 4;
      rgba[target] = 255;
      rgba[target + 1] = 255;
      rgba[target + 2] = 255;
      rgba[target + 3] = bytes[index];
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      side,
      side,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    return _EditorBrushMask(
      image: image,
      size: Size(side.toDouble(), side.toDouble()),
    );
  } catch (_) {
    return null;
  }
}

String _prettyBrushLabel(String name) {
  if (name == 'marker') {
    return 'Marker';
  }
  return name
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
