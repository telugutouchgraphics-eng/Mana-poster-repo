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
    required this.sizeJitter,
    required this.angleJitter,
    required this.hueJitter,
    this.atlasColumns = 1,
    this.atlasRows = 1,
    this.atlasCount = 1,
    this.maskAsset,
  });

  final String name;
  final String label;
  final double diameter;
  final double spacing;
  final double scatter;
  final double opacity;
  final bool varyOpacity;
  final double sizeJitter;
  final double angleJitter;
  final double hueJitter;
  final int atlasColumns;
  final int atlasRows;
  final int atlasCount;
  final String? maskAsset;

  static const _EditorBrushPreset marker = _EditorBrushPreset(
    name: 'marker',
    label: 'Marker',
    diameter: 12,
    spacing: 2,
    scatter: 0,
    opacity: 100,
    varyOpacity: true,
    sizeJitter: 0,
    angleJitter: 0,
    hueJitter: 0,
  );
}

@immutable
class _EditorBrushMask {
  const _EditorBrushMask({
    required this.image,
    required this.size,
    required this.usesSourceColors,
  });

  final ui.Image image;
  final Size size;
  final bool usesSourceColors;
}

@immutable
class _DrawPreviewState {
  const _DrawPreviewState({required this.strokes, required this.brushMasks});

  final List<_DrawStroke> strokes;
  final Map<String, _EditorBrushMask> brushMasks;
}

extension _EditorDrawToolState on _ImageEditorScreenState {
  void _openBrushesTool() {
    _openFreehandStrokeTool(
      activeLabel: 'Brushes',
      titleTelugu: 'బ్రషెస్',
      titleEnglish: 'Brushes',
    );
  }

  void _openFreehandStrokeTool({
    required String activeLabel,
    required String titleTelugu,
    required String titleEnglish,
  }) {
    if (_isCommitWorkerBusy || _lastCanvasSize.isEmpty) {
      return;
    }
    _commitSelectedTextContentEdit();
    _clearSelection();
    setState(() {
      _isDrawBrushMode = true;
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
      _showDrawBrushSettings = false;
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
    });
    _publishDrawPreview();
    unawaited(_loadDrawBrushPresets());
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
      _showDrawBrushSettings = false;
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
      _showDrawBrushSettings = false;
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
    final spacing = _drawStampSpacing(activeWidth, _selectedDrawBrush);
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

  void _cancelDrawBrushStroke() {
    if (!_isDrawBrushMode) {
      return;
    }
    final activePoints = _drawActivePoints;
    setState(() {
      if (activePoints != null &&
          _drawStrokes.isNotEmpty &&
          identical(_drawStrokes.last.points, activePoints)) {
        _drawStrokes.removeLast();
      }
      _drawActivePoints = null;
    });
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

  void _setDrawBrushSize(double size) {
    setState(() => _drawBrushSize = size);
  }

  void _setDrawBrushOpacity(double opacity) {
    setState(() => _drawOpacity = opacity);
  }

  void _selectDrawBrushPreset(_EditorBrushPreset preset) {
    setState(() {
      _selectedDrawBrush = preset;
      _drawBrushSize = preset.diameter.clamp(1, 240).toDouble();
      _drawOpacity = (preset.opacity / 100).clamp(0.05, 1).toDouble();
      _showDrawBrushSettings = false;
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
            sizeJitter: _drawNumSetting(settings, 'size_jitter', 0),
            angleJitter: _drawNumSetting(settings, 'angle_jitter', 0),
            hueJitter: _drawNumSetting(settings, 'hue_jitter', 0),
            atlasColumns: _drawIntSetting(settings, 'atlas_columns', 1),
            atlasRows: _drawIntSetting(settings, 'atlas_rows', 1),
            atlasCount: _drawIntSetting(settings, 'atlas_count', 1),
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
        _drawBrushSize = _selectedDrawBrush.diameter.clamp(1, 240).toDouble();
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
    for (final extension in const <String>['png', 'ast']) {
      final candidate = 'assets/editor_brushes/brushes/$name.$extension';
      try {
        await rootBundle.load(candidate);
        return candidate;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static int _drawIntSetting(
    Map<String, Object?> settings,
    String key,
    int fallback,
  ) {
    return (settings[key] as num?)?.toInt() ?? fallback;
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
    required this.brushPresets,
    required this.selectedBrush,
    required this.brushMasks,
    required this.color,
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
    required this.showBrushSettings,
    required this.onBrushSettingsChanged,
    required this.onBrushSizeChanged,
    required this.onOpacityChanged,
  });

  final double height;
  final List<_EditorBrushPreset> brushPresets;
  final _EditorBrushPreset selectedBrush;
  final Map<String, _EditorBrushMask> brushMasks;
  final Color color;
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
  final bool showBrushSettings;
  final ValueChanged<bool> onBrushSettingsChanged;
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
            height: 42,
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
          Expanded(
            child: _DrawBrushPanel(
              presets: brushPresets,
              selectedBrush: selectedBrush,
              brushMasks: brushMasks,
              color: color,
              brushSize: brushSize,
              opacity: opacity,
              onBrushSelected: onBrushSelected,
              showSettings: showBrushSettings,
              onSettingsChanged: onBrushSettingsChanged,
              onBrushSizeChanged: onBrushSizeChanged,
              onOpacityChanged: onOpacityChanged,
            ),
          ),
        ],
      ),
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

class _DrawBrushPanel extends StatefulWidget {
  const _DrawBrushPanel({
    required this.presets,
    required this.selectedBrush,
    required this.brushMasks,
    required this.color,
    required this.brushSize,
    required this.opacity,
    required this.onBrushSelected,
    required this.onBrushSizeChanged,
    required this.onOpacityChanged,
    this.showSettings,
    this.onSettingsChanged,
  });

  final List<_EditorBrushPreset> presets;
  final _EditorBrushPreset selectedBrush;
  final Map<String, _EditorBrushMask> brushMasks;
  final Color color;
  final double brushSize;
  final double opacity;
  final ValueChanged<_EditorBrushPreset> onBrushSelected;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onOpacityChanged;
  final bool? showSettings;
  final ValueChanged<bool>? onSettingsChanged;

  @override
  State<_DrawBrushPanel> createState() => _DrawBrushPanelState();
}

class _DrawBrushPanelState extends State<_DrawBrushPanel> {
  bool _localShowSettings = false;

  bool get _showSettings => widget.showSettings ?? _localShowSettings;

  void _toggleSettings() {
    final next = !_showSettings;
    final onSettingsChanged = widget.onSettingsChanged;
    if (onSettingsChanged == null) {
      setState(() => _localShowSettings = next);
      return;
    }
    onSettingsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: _BrushPresetStrip(
        presets: widget.presets,
        selected: widget.selectedBrush,
        masks: widget.brushMasks,
        color: widget.color,
        showSettings: _showSettings,
        onSettingsTap: _toggleSettings,
        onSelected: widget.onBrushSelected,
      ),
    );
  }
}

class _DrawBrushSettingsOverlay extends StatelessWidget {
  const _DrawBrushSettingsOverlay({
    required this.brushSize,
    required this.opacity,
    required this.onBrushSizeChanged,
    required this.onOpacityChanged,
  });

  final double brushSize;
  final double opacity;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DrawControlRow(
            label: 'Size',
            value: brushSize,
            min: 1,
            max: 240,
            onChanged: onBrushSizeChanged,
          ),
          _DrawControlRow(
            label: 'Opacity',
            value: opacity,
            min: 0.05,
            max: 1,
            onChanged: onOpacityChanged,
          ),
        ],
      ),
    );
  }
}

class _BrushPresetStrip extends StatelessWidget {
  const _BrushPresetStrip({
    required this.presets,
    required this.selected,
    required this.masks,
    required this.color,
    required this.showSettings,
    required this.onSettingsTap,
    required this.onSelected,
  });

  final List<_EditorBrushPreset> presets;
  final _EditorBrushPreset selected;
  final Map<String, _EditorBrushMask> masks;
  final Color color;
  final bool showSettings;
  final VoidCallback onSettingsTap;
  final ValueChanged<_EditorBrushPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Color(0xFF111111)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final active = preset.name == selected.name;
          final mask = preset.maskAsset == null
              ? null
              : masks[preset.maskAsset];
          return SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: InkResponse(
                    onTap: () => onSelected(preset),
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF29C7A5)
                              : const Color(0xFF333333),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _BrushPresetPreviewPainter(
                          preset: preset,
                          mask: mask,
                          color: color,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: InkResponse(
                    onTap: () {
                      if (active) {
                        onSettingsTap();
                      } else {
                        onSelected(preset);
                      }
                    },
                    radius: 26,
                    child: Center(
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: showSettings && active
                              ? const Color(0x9929C7A5)
                              : const Color(0x66111111),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
    final previewSide = size.shortestSide - 6;
    canvas.clipRect(Offset.zero & size);
    final maskImage = mask?.image;
    if (maskImage != null) {
      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..colorFilter = mask?.usesSourceColors == true
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn);
      final isParticleStamp = mask?.usesSourceColors == true;
      final count = isParticleStamp ? 9 : 1;
      for (var index = 0; index < count; index++) {
        final noiseA = _brushNoise(index, preset.name.hashCode * 0.013 + 8.31);
        final noiseB = _brushNoise(index, preset.name.hashCode * 0.021 + 5.77);
        final noiseC = _brushNoise(index, preset.name.hashCode * 0.037 + 2.93);
        final source = _brushAtlasSourceRect(maskImage, preset, noiseC);
        final particleSide = isParticleStamp
            ? previewSide * (0.34 + noiseC * 0.22)
            : previewSide;
        final radius = isParticleStamp ? previewSide * 0.31 : 0.0;
        final offset = isParticleStamp
            ? _polarScatter(noiseA, noiseB, radius)
            : Offset.zero;
        final rect = Rect.fromCenter(
          center: center + offset,
          width: particleSide,
          height: particleSide,
        );
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        if (isParticleStamp) {
          canvas.rotate((noiseA * 2 - 1) * math.pi * 0.42);
        }
        canvas.drawImageRect(
          maskImage,
          source,
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSide,
            height: particleSide,
          ),
          paint,
        );
        canvas.restore();
      }
      return;
    }
    canvas.drawCircle(
      center,
      previewSide / 2,
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
  final paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high;
  final diameter = _drawRenderDiameter(stroke.width, size, stroke.brush);
  final scatterScale = mask.usesSourceColors ? 1.25 : 0.32;
  final scatterRadius = diameter * (stroke.brush.scatter / 100) * scatterScale;
  final sizeJitter = (stroke.brush.sizeJitter / 100).clamp(0.0, 0.85);
  final angleJitter = stroke.brush.angleJitter.clamp(0.0, 360.0);
  final hueJitter = (stroke.brush.hueJitter / 100).clamp(0.0, 1.0);
  final baseHsv = HSVColor.fromColor(stroke.color);
  final strokeSeed = stroke.points.isEmpty
      ? 0.0
      : (stroke.points.first.dx * 9973.0) + (stroke.points.first.dy * 7919.0);
  Offset denormalize(Offset point) =>
      Offset(point.dx * size.width, point.dy * size.height);

  for (var index = 0; index < stroke.points.length; index++) {
    final center = denormalize(stroke.points[index]);
    final noiseA = _brushNoise(index, 12.9898 + strokeSeed);
    final noiseB = _brushNoise(index, 78.233 + strokeSeed);
    final noiseC = _brushNoise(index, 37.719 + strokeSeed);
    final noiseD = _brushNoise(index, 93.173 + strokeSeed);
    final source = _brushAtlasSourceRect(image, stroke.brush, noiseD);
    final scatter = scatterRadius <= 0
        ? Offset.zero
        : _polarScatter(noiseA, noiseB, scatterRadius);
    final stampCenter = center + scatter;
    final stampDiameter = diameter * (1 - (sizeJitter * noiseC));
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: stampDiameter,
      height: stampDiameter,
    );
    final stampOpacity = stroke.brush.varyOpacity
        ? stroke.opacity * (0.72 + 0.28 * noiseD)
        : stroke.opacity;
    if (mask.usesSourceColors) {
      paint.colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: stampOpacity.clamp(0.0, 1.0)),
        BlendMode.modulate,
      );
    } else {
      final stampColor = hueJitter <= 0
          ? stroke.color
          : baseHsv
                .withHue(
                  (baseHsv.hue + ((noiseA * 2 - 1) * 42 * hueJitter)) % 360,
                )
                .withSaturation(
                  (baseHsv.saturation * (0.82 + 0.28 * noiseB)).clamp(0.0, 1.0),
                )
                .withValue(
                  (baseHsv.value * (0.88 + 0.18 * noiseC)).clamp(0.0, 1.0),
                )
                .toColor();
      paint.colorFilter = ColorFilter.mode(
        stampColor.withValues(alpha: stampOpacity.clamp(0.0, 1.0)),
        BlendMode.srcIn,
      );
    }
    canvas.save();
    canvas.translate(stampCenter.dx, stampCenter.dy);
    if (angleJitter > 0) {
      canvas.rotate((noiseB * 2 - 1) * angleJitter * math.pi / 180);
    }
    canvas.drawImageRect(image, source, rect, paint);
    canvas.restore();
  }
}

Rect _brushAtlasSourceRect(
  ui.Image image,
  _EditorBrushPreset preset,
  double variantNoise,
) {
  final columns = preset.atlasColumns.clamp(1, 16);
  final rows = preset.atlasRows.clamp(1, 16);
  final capacity = columns * rows;
  final count = preset.atlasCount.clamp(1, capacity);
  final variant = (variantNoise.clamp(0.0, 0.999999) * count).floor();
  final column = variant % columns;
  final row = variant ~/ columns;
  final cellWidth = image.width / columns;
  final cellHeight = image.height / rows;
  return Rect.fromLTWH(
    column * cellWidth,
    row * cellHeight,
    cellWidth,
    cellHeight,
  );
}

double _brushNoise(int index, double seed) {
  final value = math.sin((index + 1) * seed) * 43758.5453123;
  return value - value.floorToDouble();
}

Offset _polarScatter(double angleNoise, double radiusNoise, double radius) {
  final angle = angleNoise * math.pi * 2;
  final distance = math.sqrt(radiusNoise.clamp(0.0, 1.0)) * radius;
  return Offset(math.cos(angle) * distance, math.sin(angle) * distance);
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

double _drawStampSpacing(double brushWidth, _EditorBrushPreset brush) {
  final raw = brushWidth * (brush.spacing / 100);
  final isColorStamp = brush.maskAsset?.toLowerCase().endsWith('.png') == true;
  if (isColorStamp) {
    return raw.clamp(brushWidth * 0.82, brushWidth * 2.4).toDouble();
  }
  return raw.clamp(0.8, 7.0).toDouble();
}

double _drawRenderDiameter(
  double brushWidth,
  Size canvasSize,
  _EditorBrushPreset brush,
) {
  final base = brushWidth * (canvasSize.width / 400);
  final isColorStamp = brush.maskAsset?.toLowerCase().endsWith('.png') == true;
  if (!isColorStamp) {
    return base;
  }
  return base * 1.75;
}

Future<_EditorBrushMask?> _loadAstBrushMask(String asset) async {
  try {
    final data = await rootBundle.load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (asset.toLowerCase().endsWith('.png')) {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1024,
        targetHeight: 1024,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      return _EditorBrushMask(
        image: image,
        size: Size(image.width.toDouble(), image.height.toDouble()),
        usesSourceColors: true,
      );
    }
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
      usesSourceColors: false,
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
