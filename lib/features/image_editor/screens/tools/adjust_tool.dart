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
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: valueWidth,
              child: Text(
                display,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

double _brightnessToUi(double value) => (value / 0.55) * 50;

double _uiToBrightness(double value) => (value / 50) * 0.55;

double _contrastToUi(double value) => ((value - 1) / 0.75) * 50;

double _uiToContrast(double value) => (1 + ((value / 50) * 0.75)).clamp(
  0.25,
  1.75,
);

double _saturationToUi(double value) => ((value - 1) / 1.2) * 50;

double _uiToSaturation(double value) => (1 + ((value / 50) * 1.2)).clamp(
  0.0,
  2.2,
);

double _blurToUi(double value) => (value / 10) * 50;

double _uiToBlur(double value) => (value / 50) * 10;

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
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
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
                              color: Colors.white,
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
                      _AdjustSlider(
                        label: strings.localized(
                          telugu: 'బ్రైట్‌నెస్',
                          english: 'Brightness',
                        ),
                        value: _brightnessToUi(resolved.brightness),
                        min: -50,
                        max: 50,
                        display:
                            _brightnessToUi(resolved.brightness)
                                .round()
                                .toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(
                            brightness: _uiToBrightness(value),
                          ),
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
                        display:
                            _contrastToUi(resolved.contrast).round().toString(),
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
                        display:
                            _saturationToUi(
                              resolved.saturation,
                            ).round().toString(),
                        onChanged: (double value) => onSessionChanged(
                          resolved.copyWith(
                            saturation: _uiToSaturation(value),
                          ),
                        ),
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
