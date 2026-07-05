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

double _brightnessToUi(double value) => (value / 0.75) * 50;

double _uiToBrightness(double value) => (value / 50) * 0.75;

double _contrastToUi(double value) => ((value - 1) / 0.95) * 50;

double _uiToContrast(double value) =>
    (1 + ((value / 50) * 0.95)).clamp(0.05, 1.95);

double _saturationToUi(double value) => ((value - 1) / 1.45) * 50;

double _uiToSaturation(double value) =>
    (1 + ((value / 50) * 1.45)).clamp(0.0, 2.45);

double _blurToUi(double value) => (value / 24) * 50;

double _uiToBlur(double value) => (value / 50) * 24;

@immutable
class _EnhancementPreset {
  const _EnhancementPreset({
    required this.label,
    required this.icon,
    required this.state,
  });

  final String label;
  final IconData icon;
  final _AdjustSessionState state;
}

const List<_EnhancementPreset> _enhancementPresets = <_EnhancementPreset>[
  _EnhancementPreset(
    label: 'Auto',
    icon: Icons.auto_fix_high_rounded,
    state: _AdjustSessionState(
      brightness: 0.045,
      contrast: 1.18,
      saturation: 1.14,
      blur: 0,
      sharpen: 18,
      grain: 0,
      vignette: 0,
      motion: 0,
      tiltShift: 0,
      shadows: 12,
      highlights: -8,
      temperature: 2,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    label: 'Enhance',
    icon: Icons.wb_sunny_rounded,
    state: _AdjustSessionState(
      brightness: 0.07,
      contrast: 1.26,
      saturation: 1.22,
      blur: 0,
      sharpen: 28,
      grain: 0,
      vignette: 4,
      motion: 0,
      tiltShift: 0,
      shadows: 18,
      highlights: -12,
      temperature: 4,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    label: 'HDR',
    icon: Icons.hdr_strong_rounded,
    state: _AdjustSessionState(
      brightness: -0.018,
      contrast: 1.46,
      saturation: 1.30,
      blur: 0,
      sharpen: 36,
      grain: 5,
      vignette: 16,
      motion: 0,
      tiltShift: 0,
      shadows: 34,
      highlights: -28,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    label: 'Clarity',
    icon: Icons.blur_on_rounded,
    state: _AdjustSessionState(
      brightness: 0.018,
      contrast: 1.36,
      saturation: 1.08,
      blur: 0,
      sharpen: 52,
      grain: 0,
      vignette: 0,
      motion: 0,
      tiltShift: 0,
      shadows: 14,
      highlights: -14,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    label: 'Warm',
    icon: Icons.local_fire_department_rounded,
    state: _AdjustSessionState(
      brightness: 0.055,
      contrast: 1.12,
      saturation: 1.34,
      blur: 0,
      sharpen: 16,
      grain: 0,
      vignette: 5,
      motion: 0,
      tiltShift: 0,
      shadows: 8,
      highlights: 4,
      temperature: 42,
      tint: 6,
    ),
  ),
  _EnhancementPreset(
    label: 'B&W HDR',
    icon: Icons.contrast_rounded,
    state: _AdjustSessionState(
      brightness: 0.018,
      contrast: 1.52,
      saturation: 0,
      blur: 0,
      sharpen: 32,
      grain: 18,
      vignette: 20,
      motion: 0,
      tiltShift: 0,
      shadows: 0,
      highlights: 0,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    label: 'Film Grain',
    icon: Icons.grain_rounded,
    state: _AdjustSessionState(
      brightness: 0.012,
      contrast: 1.16,
      saturation: 0.92,
      blur: 0,
      sharpen: 8,
      grain: 36,
      vignette: 18,
      motion: 0,
      tiltShift: 0,
      shadows: 0,
      highlights: 0,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    label: 'Motion',
    icon: Icons.blur_linear_rounded,
    state: _AdjustSessionState(
      brightness: 0,
      contrast: 1.08,
      saturation: 1.02,
      blur: 0,
      sharpen: 0,
      grain: 0,
      vignette: 8,
      motion: 48,
      tiltShift: 0,
      shadows: 0,
      highlights: 0,
      temperature: 0,
      tint: 0,
    ),
  ),
  _EnhancementPreset(
    label: 'Tilt Shift',
    icon: Icons.filter_tilt_shift_rounded,
    state: _AdjustSessionState(
      brightness: 0.01,
      contrast: 1.16,
      saturation: 1.10,
      blur: 0,
      sharpen: 12,
      grain: 0,
      vignette: 12,
      motion: 0,
      tiltShift: 54,
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

class _AdjustInlineStrip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      decoration: BoxDecoration(
        color: _editorChromeSurfaceStrong.withValues(alpha: 0.25),
      ),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<_AdjustSessionState?>(
          valueListenable: sessionListenable,
          builder:
              (
                BuildContext context,
                _AdjustSessionState? session,
                Widget? child,
              ) {
                final strings = context.strings;
                final resolved =
                    session ??
                    const _AdjustSessionState(
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
                              telugu: 'వెనక్కి',
                              english: 'Back',
                            ),
                            compact: false,
                            onTap: onBack,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            strings.localized(
                              telugu: 'అడ్జస్ట్',
                              english: 'Adjust',
                            ),
                            style: const TextStyle(
                              color: _editorChromeTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _PressableSurface(
                            onTap: onApply,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              height: 31,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                strings.localized(
                                  telugu: 'అప్లై',
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
                          itemCount: _enhancementPresets.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final preset = _enhancementPresets[index];
                            final selected = _isSameEnhancementState(
                              resolved,
                              preset.state,
                            );
                            return _PressableSurface(
                              onTap: () => onSessionChanged(preset.state),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                ),
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
                                            color: const Color(
                                              0xFF8B7FFF,
                                            ).withValues(alpha: 0.24),
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
                                      preset.icon,
                                      size: 15,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFFCBD5E1),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      preset.label,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFFE2E8F0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 2),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'బ్రైట్‌నెస్',
                          english: 'Brightness',
                        ),
                        value: _brightnessToUi(resolved.brightness),
                        min: -50,
                        max: 50,
                        display: _brightnessToUi(
                          resolved.brightness,
                        ).round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(brightness: _uiToBrightness(value)),
                        ),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'కాంట్రాస్ట్',
                          english: 'Contrast',
                        ),
                        value: _contrastToUi(resolved.contrast),
                        min: -50,
                        max: 50,
                        display: _contrastToUi(
                          resolved.contrast,
                        ).round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(contrast: _uiToContrast(value)),
                        ),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'సాచురేషన్',
                          english: 'Saturation',
                        ),
                        value: _saturationToUi(resolved.saturation),
                        min: -50,
                        max: 50,
                        display: _saturationToUi(
                          resolved.saturation,
                        ).round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(saturation: _uiToSaturation(value)),
                        ),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'షాడోస్',
                          english: 'Shadows',
                        ),
                        value: resolved.shadows,
                        min: -100,
                        max: 100,
                        display: resolved.shadows.round().toString(),
                        onChanged: (double value) =>
                            onSessionChanged(resolved.copyWith(shadows: value)),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'హైలైట్స్',
                          english: 'Highlights',
                        ),
                        value: resolved.highlights,
                        min: -100,
                        max: 100,
                        display: resolved.highlights.round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(highlights: value),
                        ),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'టెంపరేచర్',
                          english: 'Temperature',
                        ),
                        value: resolved.temperature,
                        min: -100,
                        max: 100,
                        display: resolved.temperature.round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(temperature: value),
                        ),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'టింట్',
                          english: 'Tint',
                        ),
                        value: resolved.tint,
                        min: -100,
                        max: 100,
                        display: resolved.tint.round().toString(),
                        onChanged: (double value) =>
                            onSessionChanged(resolved.copyWith(tint: value)),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'బ్లర్',
                          english: 'Blur',
                        ),
                        value: _blurToUi(resolved.blur),
                        min: 0,
                        max: 50,
                        display: _blurToUi(resolved.blur).round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(blur: _uiToBlur(value)),
                        ),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'షార్పెన్',
                          english: 'Sharpen',
                        ),
                        value: resolved.sharpen,
                        min: 0,
                        max: 100,
                        display: resolved.sharpen.round().toString(),
                        onChanged: (double value) =>
                            onSessionChanged(resolved.copyWith(sharpen: value)),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'గ్రెయిన్',
                          english: 'Grain',
                        ),
                        value: resolved.grain,
                        min: 0,
                        max: 100,
                        display: resolved.grain.round().toString(),
                        onChanged: (double value) =>
                            onSessionChanged(resolved.copyWith(grain: value)),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'విగ్నెట్',
                          english: 'Vignette',
                        ),
                        value: resolved.vignette,
                        min: 0,
                        max: 100,
                        display: resolved.vignette.round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(vignette: value),
                        ),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'మోషన్',
                          english: 'Motion',
                        ),
                        value: resolved.motion,
                        min: 0,
                        max: 100,
                        display: resolved.motion.round().toString(),
                        onChanged: (double value) =>
                            onSessionChanged(resolved.copyWith(motion: value)),
                      ),
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'టిల్ట్',
                          english: 'Tilt',
                        ),
                        value: resolved.tiltShift,
                        min: 0,
                        max: 100,
                        display: resolved.tiltShift.round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(tiltShift: value),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _PressableSurface(
                              onTap: onReset,
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
                                    telugu: 'రిసెట్',
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
}
