part of '../image_editor_screen.dart';

// ignore_for_file: unused_element

class _AdjustSlider extends StatelessWidget {
  const _AdjustSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percentValue = _editorSliderToPercent(value, min, max);
    void handleChanged(double percent) {
      onChanged(_editorPercentToSlider(percent, min, max));
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final labelWidth = constraints.maxWidth < 360 ? 66.0 : 82.0;
        final valueWidth = constraints.maxWidth < 360 ? 34.0 : 42.0;
        return Row(
          children: <Widget>[
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: percentValue,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: handleChanged,
              ),
            ),
            SizedBox(
              width: valueWidth,
              child: Tooltip(
                message: display,
                child: Text(
                  percentValue.round().toString(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

double _brightnessToUi(double value) => (value / 0.42) * 50;

double _uiToBrightness(double value) => (value / 50) * 0.42;

double _contrastToUi(double value) => ((value - 1) / 0.62) * 50;

double _uiToContrast(double value) =>
    (1 + ((value / 50) * 0.62)).clamp(0.38, 1.62);

double _saturationToUi(double value) => ((value - 1) / 0.82) * 50;

double _uiToSaturation(double value) =>
    (1 + ((value / 50) * 0.82)).clamp(0.18, 1.82);

double _blurToUi(double value) => (value / 14) * 50;

double _uiToBlur(double value) => (value / 50) * 14;

@immutable
class _EnhancementPreset {
  const _EnhancementPreset({
    required this.tool,
    required this.label,
    required this.icon,
    required this.state,
  });

  final _PhotoEffectTool tool;
  final String label;
  final IconData icon;
  final _AdjustSessionState state;
}

enum _PhotoEffectTool {
  tune,
  auto,
  enhance,
  hdr,
  clarity,
  warm,
  blackWhite,
  filmGrain,
  motion,
  tiltShift,
}

const _AdjustSessionState _neutralAdjustState = _AdjustSessionState(
  brightness: 0,
  contrast: 1,
  saturation: 1,
  blur: 0,
  sharpen: 0,
  grain: 0,
  vignette: 0,
  motion: 0,
  tiltShift: 0,
  shadows: 0,
  highlights: 0,
  temperature: 0,
  tint: 0,
);

const List<_EnhancementPreset> _enhancementPresets = <_EnhancementPreset>[
  _EnhancementPreset(
    tool: _PhotoEffectTool.auto,
    label: 'Auto',
    icon: Icons.auto_fix_high_rounded,
    state: _AdjustSessionState(
      brightness: 0.025,
      contrast: 1.10,
      saturation: 1.07,
      blur: 0,
      sharpen: 12,
      grain: 0,
      vignette: 0,
      motion: 0,
      tiltShift: 0,
      shadows: 8,
      highlights: -6,
      temperature: 1,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.enhance,
    label: 'Enhance',
    icon: Icons.wb_sunny_rounded,
    state: _AdjustSessionState(
      brightness: 0.045,
      contrast: 1.16,
      saturation: 1.12,
      blur: 0,
      sharpen: 18,
      grain: 0,
      vignette: 2,
      motion: 0,
      tiltShift: 0,
      shadows: 12,
      highlights: -8,
      temperature: 3,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.hdr,
    label: 'HDR',
    icon: Icons.hdr_strong_rounded,
    state: _AdjustSessionState(
      brightness: -0.006,
      contrast: 1.30,
      saturation: 1.16,
      blur: 0,
      sharpen: 28,
      grain: 3,
      vignette: 10,
      motion: 0,
      tiltShift: 0,
      shadows: 24,
      highlights: -20,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.clarity,
    label: 'Clarity',
    icon: Icons.blur_on_rounded,
    state: _AdjustSessionState(
      brightness: 0.008,
      contrast: 1.22,
      saturation: 1.04,
      blur: 0,
      sharpen: 34,
      grain: 0,
      vignette: 0,
      motion: 0,
      tiltShift: 0,
      shadows: 10,
      highlights: -10,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.warm,
    label: 'Warm',
    icon: Icons.local_fire_department_rounded,
    state: _AdjustSessionState(
      brightness: 0.035,
      contrast: 1.08,
      saturation: 1.18,
      blur: 0,
      sharpen: 10,
      grain: 0,
      vignette: 3,
      motion: 0,
      tiltShift: 0,
      shadows: 8,
      highlights: -2,
      temperature: 28,
      tint: 3,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.blackWhite,
    label: 'B&W HDR',
    icon: Icons.contrast_rounded,
    state: _AdjustSessionState(
      brightness: 0.006,
      contrast: 1.34,
      saturation: 0,
      blur: 0,
      sharpen: 22,
      grain: 10,
      vignette: 14,
      motion: 0,
      tiltShift: 0,
      shadows: 0,
      highlights: 0,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.filmGrain,
    label: 'Film Grain',
    icon: Icons.grain_rounded,
    state: _AdjustSessionState(
      brightness: 0.006,
      contrast: 1.10,
      saturation: 0.96,
      blur: 0,
      sharpen: 4,
      grain: 22,
      vignette: 12,
      motion: 0,
      tiltShift: 0,
      shadows: 0,
      highlights: 0,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.motion,
    label: 'Motion',
    icon: Icons.blur_linear_rounded,
    state: _AdjustSessionState(
      brightness: 0,
      contrast: 1.04,
      saturation: 1.02,
      blur: 0,
      sharpen: 0,
      grain: 0,
      vignette: 5,
      motion: 34,
      tiltShift: 0,
      shadows: 0,
      highlights: 0,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    tool: _PhotoEffectTool.tiltShift,
    label: 'Tilt Shift',
    icon: Icons.filter_tilt_shift_rounded,
    state: _AdjustSessionState(
      brightness: 0.004,
      contrast: 1.10,
      saturation: 1.05,
      blur: 0,
      sharpen: 6,
      grain: 0,
      vignette: 8,
      motion: 0,
      tiltShift: 40,
      shadows: 0,
      highlights: 0,
      temperature: 0,
      tint: 0,
    ),
  ),
];

bool _isSameEnhancementState(
  _AdjustSessionState left,
  _AdjustSessionState right,
) {
  return (left.brightness - right.brightness).abs() < 0.002 &&
      (left.contrast - right.contrast).abs() < 0.002 &&
      (left.saturation - right.saturation).abs() < 0.002 &&
      (left.blur - right.blur).abs() < 0.002 &&
      (left.sharpen - right.sharpen).abs() < 0.002 &&
      (left.grain - right.grain).abs() < 0.002 &&
      (left.vignette - right.vignette).abs() < 0.002 &&
      (left.motion - right.motion).abs() < 0.002 &&
      (left.tiltShift - right.tiltShift).abs() < 0.002 &&
      (left.shadows - right.shadows).abs() < 0.002 &&
      (left.highlights - right.highlights).abs() < 0.002 &&
      (left.temperature - right.temperature).abs() < 0.002 &&
      (left.tint - right.tint).abs() < 0.002;
}

class _AdjustInlineStrip extends StatefulWidget {
  const _AdjustInlineStrip({
    required this.height,
    required this.sessionListenable,
    required this.onSessionChanged,
    required this.onBack,
    required this.onReset,
    required this.onApply,
  });

  final double height;
  final ValueListenable<_AdjustSessionState?> sessionListenable;
  final ValueChanged<_AdjustSessionState> onSessionChanged;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  State<_AdjustInlineStrip> createState() => _AdjustInlineStripState();
}

class _AdjustInlineStripState extends State<_AdjustInlineStrip> {
  _PhotoEffectTool _activeTool = _PhotoEffectTool.tune;

  _EnhancementPreset? get _activePreset {
    for (final preset in _enhancementPresets) {
      if (preset.tool == _activeTool) {
        return preset;
      }
    }
    return null;
  }

  double _presetAmount(_AdjustSessionState state, _AdjustSessionState preset) {
    final ratios = <double>[];
    void collect(double current, double target, double neutral) {
      final delta = target - neutral;
      if (delta.abs() < 0.0001) return;
      ratios.add(((current - neutral) / delta).clamp(0.0, 1.0).toDouble());
    }

    collect(
      state.brightness,
      preset.brightness,
      _neutralAdjustState.brightness,
    );
    collect(state.contrast, preset.contrast, _neutralAdjustState.contrast);
    collect(
      state.saturation,
      preset.saturation,
      _neutralAdjustState.saturation,
    );
    collect(state.blur, preset.blur, _neutralAdjustState.blur);
    collect(state.sharpen, preset.sharpen, _neutralAdjustState.sharpen);
    collect(state.grain, preset.grain, _neutralAdjustState.grain);
    collect(state.vignette, preset.vignette, _neutralAdjustState.vignette);
    collect(state.motion, preset.motion, _neutralAdjustState.motion);
    collect(state.tiltShift, preset.tiltShift, _neutralAdjustState.tiltShift);
    collect(state.shadows, preset.shadows, _neutralAdjustState.shadows);
    collect(
      state.highlights,
      preset.highlights,
      _neutralAdjustState.highlights,
    );
    collect(
      state.temperature,
      preset.temperature,
      _neutralAdjustState.temperature,
    );
    collect(state.tint, preset.tint, _neutralAdjustState.tint);
    if (ratios.isEmpty) return 0;
    return (ratios.reduce((a, b) => a + b) / ratios.length) * 100;
  }

  _AdjustSessionState _stateForPresetAmount(
    _AdjustSessionState preset,
    double amount,
  ) {
    final t = (amount / 100).clamp(0.0, 1.0).toDouble();
    double lerp(double start, double end) => start + ((end - start) * t);
    return _AdjustSessionState(
      brightness: lerp(_neutralAdjustState.brightness, preset.brightness),
      contrast: lerp(_neutralAdjustState.contrast, preset.contrast),
      saturation: lerp(_neutralAdjustState.saturation, preset.saturation),
      blur: lerp(_neutralAdjustState.blur, preset.blur),
      sharpen: lerp(_neutralAdjustState.sharpen, preset.sharpen),
      grain: lerp(_neutralAdjustState.grain, preset.grain),
      vignette: lerp(_neutralAdjustState.vignette, preset.vignette),
      motion: lerp(_neutralAdjustState.motion, preset.motion),
      tiltShift: lerp(_neutralAdjustState.tiltShift, preset.tiltShift),
      shadows: lerp(_neutralAdjustState.shadows, preset.shadows),
      highlights: lerp(_neutralAdjustState.highlights, preset.highlights),
      temperature: lerp(_neutralAdjustState.temperature, preset.temperature),
      tint: lerp(_neutralAdjustState.tint, preset.tint),
    );
  }

  void _selectTool(_PhotoEffectTool tool) {
    setState(() => _activeTool = tool);
    for (final preset in _enhancementPresets) {
      if (preset.tool == tool) {
        widget.onSessionChanged(preset.state);
        return;
      }
    }
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return _AdjustSlider(
      label: label,
      value: value,
      min: min,
      max: max,
      display: display,
      onChanged: onChanged,
    );
  }

  List<Widget> _controlsForTool(_AdjustSessionState state) {
    final widgets = <Widget>[];
    final preset = _activePreset;
    if (preset != null) {
      final amount = _presetAmount(state, preset.state);
      widgets.add(
        _slider(
          label: 'Amount',
          value: amount,
          min: 0,
          max: 100,
          display: amount.round().toString(),
          onChanged: (value) => widget.onSessionChanged(
            _stateForPresetAmount(preset.state, value),
          ),
        ),
      );
    }
    switch (_activeTool) {
      case _PhotoEffectTool.tune:
        widgets.addAll(_buildTuneControls(state));
      case _PhotoEffectTool.auto:
      case _PhotoEffectTool.enhance:
        widgets.addAll(_buildAutoEnhanceControls(state));
      case _PhotoEffectTool.hdr:
        widgets.addAll(_buildHdrControls(state));
      case _PhotoEffectTool.clarity:
        widgets.addAll(_buildClarityControls(state));
      case _PhotoEffectTool.warm:
        widgets.addAll(_buildWarmControls(state));
      case _PhotoEffectTool.blackWhite:
        widgets.addAll(_buildBlackWhiteControls(state));
      case _PhotoEffectTool.filmGrain:
        widgets.addAll(_buildFilmGrainControls(state));
      case _PhotoEffectTool.motion:
        widgets.addAll(_buildMotionControls(state));
      case _PhotoEffectTool.tiltShift:
        widgets.addAll(_buildTiltShiftControls(state));
    }
    return widgets;
  }

  List<Widget> _buildToneControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Exposure',
      value: _brightnessToUi(state.brightness),
      min: -50,
      max: 50,
      display: _brightnessToUi(state.brightness).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(brightness: _uiToBrightness(value)),
      ),
    ),
    _slider(
      label: 'Contrast',
      value: _contrastToUi(state.contrast),
      min: -50,
      max: 50,
      display: _contrastToUi(state.contrast).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(contrast: _uiToContrast(value)),
      ),
    ),
    _slider(
      label: 'Color',
      value: _saturationToUi(state.saturation),
      min: -50,
      max: 50,
      display: _saturationToUi(state.saturation).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(saturation: _uiToSaturation(value)),
      ),
    ),
  ];

  List<Widget> _buildTuneControls(_AdjustSessionState state) => <Widget>[
    ..._buildToneControls(state),
    _slider(
      label: 'Shadows',
      value: state.shadows,
      min: -100,
      max: 100,
      display: state.shadows.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(shadows: value)),
    ),
    _slider(
      label: 'Highlights',
      value: state.highlights,
      min: -100,
      max: 100,
      display: state.highlights.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(highlights: value)),
    ),
    _slider(
      label: 'Temperature',
      value: state.temperature,
      min: -100,
      max: 100,
      display: state.temperature.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(temperature: value)),
    ),
    _slider(
      label: 'Tint',
      value: state.tint,
      min: -100,
      max: 100,
      display: state.tint.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(tint: value)),
    ),
    _slider(
      label: 'Blur',
      value: _blurToUi(state.blur),
      min: 0,
      max: 50,
      display: _blurToUi(state.blur).round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(blur: _uiToBlur(value))),
    ),
    _slider(
      label: 'Sharpen',
      value: state.sharpen,
      min: 0,
      max: 100,
      display: state.sharpen.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(sharpen: value)),
    ),
    _slider(
      label: 'Grain',
      value: state.grain,
      min: 0,
      max: 100,
      display: state.grain.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(grain: value)),
    ),
    _slider(
      label: 'Vignette',
      value: state.vignette,
      min: 0,
      max: 100,
      display: state.vignette.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(vignette: value)),
    ),
  ];

  List<Widget> _buildAutoEnhanceControls(_AdjustSessionState state) => <Widget>[
    ..._buildToneControls(state),
    _slider(
      label: 'Detail',
      value: state.sharpen,
      min: 0,
      max: 100,
      display: state.sharpen.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(sharpen: value)),
    ),
  ];

  List<Widget> _buildHdrControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Detail',
      value: state.sharpen,
      min: 0,
      max: 100,
      display: state.sharpen.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(sharpen: value)),
    ),
    _slider(
      label: 'Shadows',
      value: state.shadows,
      min: -100,
      max: 100,
      display: state.shadows.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(shadows: value)),
    ),
    _slider(
      label: 'Highlights',
      value: state.highlights,
      min: -100,
      max: 100,
      display: state.highlights.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(highlights: value)),
    ),
    _slider(
      label: 'Depth',
      value: _contrastToUi(state.contrast),
      min: -50,
      max: 50,
      display: _contrastToUi(state.contrast).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(contrast: _uiToContrast(value)),
      ),
    ),
    _slider(
      label: 'Vignette',
      value: state.vignette,
      min: 0,
      max: 100,
      display: state.vignette.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(vignette: value)),
    ),
  ];

  List<Widget> _buildClarityControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Clarity',
      value: state.sharpen,
      min: 0,
      max: 100,
      display: state.sharpen.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(sharpen: value)),
    ),
    _slider(
      label: 'Contrast',
      value: _contrastToUi(state.contrast),
      min: -50,
      max: 50,
      display: _contrastToUi(state.contrast).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(contrast: _uiToContrast(value)),
      ),
    ),
    _slider(
      label: 'Shadows',
      value: state.shadows,
      min: -100,
      max: 100,
      display: state.shadows.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(shadows: value)),
    ),
    _slider(
      label: 'Highlights',
      value: state.highlights,
      min: -100,
      max: 100,
      display: state.highlights.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(highlights: value)),
    ),
  ];

  List<Widget> _buildWarmControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Warmth',
      value: state.temperature,
      min: -100,
      max: 100,
      display: state.temperature.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(temperature: value)),
    ),
    _slider(
      label: 'Tint',
      value: state.tint,
      min: -100,
      max: 100,
      display: state.tint.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(tint: value)),
    ),
    ..._buildToneControls(state),
  ];

  List<Widget> _buildBlackWhiteControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Contrast',
      value: _contrastToUi(state.contrast),
      min: -50,
      max: 50,
      display: _contrastToUi(state.contrast).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(contrast: _uiToContrast(value)),
      ),
    ),
    _slider(
      label: 'Detail',
      value: state.sharpen,
      min: 0,
      max: 100,
      display: state.sharpen.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(sharpen: value)),
    ),
    _slider(
      label: 'Grain',
      value: state.grain,
      min: 0,
      max: 100,
      display: state.grain.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(grain: value)),
    ),
    _slider(
      label: 'Vignette',
      value: state.vignette,
      min: 0,
      max: 100,
      display: state.vignette.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(vignette: value)),
    ),
  ];

  List<Widget> _buildFilmGrainControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Grain',
      value: state.grain,
      min: 0,
      max: 100,
      display: state.grain.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(grain: value)),
    ),
    _slider(
      label: 'Fade',
      value: _contrastToUi(state.contrast),
      min: -50,
      max: 50,
      display: _contrastToUi(state.contrast).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(contrast: _uiToContrast(value)),
      ),
    ),
    _slider(
      label: 'Color',
      value: _saturationToUi(state.saturation),
      min: -50,
      max: 50,
      display: _saturationToUi(state.saturation).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(saturation: _uiToSaturation(value)),
      ),
    ),
    _slider(
      label: 'Vignette',
      value: state.vignette,
      min: 0,
      max: 100,
      display: state.vignette.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(vignette: value)),
    ),
  ];

  List<Widget> _buildMotionControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Distance',
      value: state.motion,
      min: 0,
      max: 100,
      display: state.motion.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(motion: value)),
    ),
    _slider(
      label: 'Fade',
      value: state.vignette,
      min: 0,
      max: 100,
      display: state.vignette.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(vignette: value)),
    ),
    _slider(
      label: 'Contrast',
      value: _contrastToUi(state.contrast),
      min: -50,
      max: 50,
      display: _contrastToUi(state.contrast).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(contrast: _uiToContrast(value)),
      ),
    ),
  ];

  List<Widget> _buildTiltShiftControls(_AdjustSessionState state) => <Widget>[
    _slider(
      label: 'Focus',
      value: state.tiltShift,
      min: 0,
      max: 100,
      display: state.tiltShift.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(tiltShift: value)),
    ),
    _slider(
      label: 'Softness',
      value: _blurToUi(state.blur),
      min: 0,
      max: 50,
      display: _blurToUi(state.blur).round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(blur: _uiToBlur(value))),
    ),
    _slider(
      label: 'Vignette',
      value: state.vignette,
      min: 0,
      max: 100,
      display: state.vignette.round().toString(),
      onChanged: (value) =>
          widget.onSessionChanged(state.copyWith(vignette: value)),
    ),
    _slider(
      label: 'Contrast',
      value: _contrastToUi(state.contrast),
      min: -50,
      max: 50,
      display: _contrastToUi(state.contrast).round().toString(),
      onChanged: (value) => widget.onSessionChanged(
        state.copyWith(contrast: _uiToContrast(value)),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      decoration: BoxDecoration(
        color: _editorChromeSurfaceStrong.withValues(alpha: 0.25),
      ),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<_AdjustSessionState?>(
          valueListenable: widget.sessionListenable,
          builder: (context, session, child) {
            final strings = context.strings;
            final resolved = session ?? _neutralAdjustState;
            final controls = _controlsForTool(resolved);
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _EditorIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: strings.localized(
                          telugu: 'Back',
                          english: 'Back',
                        ),
                        compact: false,
                        onTap: widget.onBack,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        strings.localized(
                          telugu: 'Effects',
                          english: 'Effects',
                        ),
                        style: const TextStyle(
                          color: _editorChromeTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _PressableSurface(
                        onTap: widget.onApply,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 31,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            strings.localized(
                              telugu: 'Apply',
                              english: 'Apply',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _enhancementPresets.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildToolChip(
                            label: 'Tune',
                            icon: Icons.tune_rounded,
                            selected: _activeTool == _PhotoEffectTool.tune,
                            onTap: () => _selectTool(_PhotoEffectTool.tune),
                          );
                        }
                        final preset = _enhancementPresets[index - 1];
                        return _buildToolChip(
                          label: preset.label,
                          icon: preset.icon,
                          selected: _activeTool == preset.tool,
                          onTap: () => _selectTool(preset.tool),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 2),
                  ...controls,
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _PressableSurface(
                          onTap: widget.onReset,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              strings.localized(
                                telugu: 'Reset',
                                english: 'Reset',
                              ),
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8B7FFF)
              : Colors.white.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.13),
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF8B7FFF).withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFFE2E8F0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
