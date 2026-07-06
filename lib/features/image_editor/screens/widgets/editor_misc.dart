part of '../image_editor_screen.dart';

class _TextStyleBar extends StatefulWidget {
  const _TextStyleBar({
    required this.visible,
    required this.focusedTab,
    required this.selectedLayer,
    required this.textController,
    required this.textFocusNode,
    required this.colors,
    required this.backgroundColors,
    required this.gradients,
    required this.savedEffectPresets,
    required this.copiedTextEffect,
    required this.onEditTap,
    required this.onTextChanged,
    required this.onFontsTap,
    required this.onColorWheelTap,
    required this.onColorSelected,
    required this.onBackgroundColorSelected,
    required this.onAlignSelected,
    required this.onGradientSelected,
    required this.onEffectPresetSelected,
    required this.onCopyTextEffect,
    required this.onPasteTextEffect,
    required this.onSaveTextEffectPreset,
    required this.onSavedTextEffectPresetSelected,
    required this.onSavedTextEffectPresetDeleted,
    required this.onTextOpacityChanged,
    required this.onFontSizeChanged,
    required this.onFontSizeChangeStart,
    required this.onFontSizeChangeEnd,
    required this.onBackgroundOpacityChanged,
    required this.onBackgroundOpacityChangeStart,
    required this.onBackgroundOpacityChangeEnd,
    required this.onBackgroundRadiusChanged,
    required this.onBackgroundRadiusChangeStart,
    required this.onBackgroundRadiusChangeEnd,
    required this.onBackgroundTopPaddingChanged,
    required this.onBackgroundTopPaddingChangeStart,
    required this.onBackgroundTopPaddingChangeEnd,
    required this.onBackgroundBottomPaddingChanged,
    required this.onBackgroundBottomPaddingChangeStart,
    required this.onBackgroundBottomPaddingChangeEnd,
    required this.onLineHeightChanged,
    required this.onLineHeightChangeStart,
    required this.onLineHeightChangeEnd,
    required this.onLetterSpacingChanged,
    required this.onLetterSpacingChangeStart,
    required this.onLetterSpacingChangeEnd,
    required this.onShadowOpacityChanged,
    required this.onShadowOpacityChangeStart,
    required this.onShadowOpacityChangeEnd,
    required this.onShadowBlurChanged,
    required this.onShadowBlurChangeStart,
    required this.onShadowBlurChangeEnd,
    required this.onShadowOffsetYChanged,
    required this.onShadowOffsetYChangeStart,
    required this.onShadowOffsetYChangeEnd,
    required this.onShadowColorSelected,
    required this.onShadowColorChangeStart,
    required this.onShadowColorChangeEnd,
    required this.onBoldToggle,
    required this.onItalicToggle,
    required this.onUnderlineToggle,
    required this.onStrokeColorSelected,
    required this.onStrokeColorChangeStart,
    required this.onStrokeColorChangeEnd,
    required this.onStrokeWidthChanged,
    required this.onStrokeWidthChangeStart,
    required this.onStrokeWidthChangeEnd,
  });

  final bool visible;
  final _TextToolTab focusedTab;
  final _CanvasLayer? selectedLayer;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final List<Color> colors;
  final List<Color> backgroundColors;
  final List<List<Color>> gradients;
  final List<_TextEffectSnapshot> savedEffectPresets;
  final _TextEffectSnapshot? copiedTextEffect;
  final VoidCallback onEditTap;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onFontsTap;
  final VoidCallback onColorWheelTap;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<Color> onBackgroundColorSelected;
  final ValueChanged<TextAlign> onAlignSelected;
  final ValueChanged<int> onGradientSelected;
  final ValueChanged<_TextEffectPreset> onEffectPresetSelected;
  final VoidCallback onCopyTextEffect;
  final VoidCallback onPasteTextEffect;
  final VoidCallback onSaveTextEffectPreset;
  final ValueChanged<_TextEffectSnapshot> onSavedTextEffectPresetSelected;
  final ValueChanged<_TextEffectSnapshot> onSavedTextEffectPresetDeleted;
  final ValueChanged<double> onTextOpacityChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onFontSizeChangeStart;
  final ValueChanged<double> onFontSizeChangeEnd;
  final ValueChanged<double> onBackgroundOpacityChanged;
  final ValueChanged<double> onBackgroundOpacityChangeStart;
  final ValueChanged<double> onBackgroundOpacityChangeEnd;
  final ValueChanged<double> onBackgroundRadiusChanged;
  final ValueChanged<double> onBackgroundRadiusChangeStart;
  final ValueChanged<double> onBackgroundRadiusChangeEnd;
  final ValueChanged<double> onBackgroundTopPaddingChanged;
  final ValueChanged<double> onBackgroundTopPaddingChangeStart;
  final ValueChanged<double> onBackgroundTopPaddingChangeEnd;
  final ValueChanged<double> onBackgroundBottomPaddingChanged;
  final ValueChanged<double> onBackgroundBottomPaddingChangeStart;
  final ValueChanged<double> onBackgroundBottomPaddingChangeEnd;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onLineHeightChangeStart;
  final ValueChanged<double> onLineHeightChangeEnd;
  final ValueChanged<double> onLetterSpacingChanged;
  final ValueChanged<double> onLetterSpacingChangeStart;
  final ValueChanged<double> onLetterSpacingChangeEnd;
  final ValueChanged<double> onShadowOpacityChanged;
  final ValueChanged<double> onShadowOpacityChangeStart;
  final ValueChanged<double> onShadowOpacityChangeEnd;
  final ValueChanged<double> onShadowBlurChanged;
  final ValueChanged<double> onShadowBlurChangeStart;
  final ValueChanged<double> onShadowBlurChangeEnd;
  final ValueChanged<double> onShadowOffsetYChanged;
  final ValueChanged<double> onShadowOffsetYChangeStart;
  final ValueChanged<double> onShadowOffsetYChangeEnd;
  final ValueChanged<Color> onShadowColorSelected;
  final ValueChanged<double> onShadowColorChangeStart;
  final ValueChanged<double> onShadowColorChangeEnd;
  final VoidCallback onBoldToggle;
  final VoidCallback onItalicToggle;
  final VoidCallback onUnderlineToggle;
  final ValueChanged<Color> onStrokeColorSelected;
  final ValueChanged<double> onStrokeColorChangeStart;
  final ValueChanged<double> onStrokeColorChangeEnd;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<double> onStrokeWidthChangeStart;
  final ValueChanged<double> onStrokeWidthChangeEnd;

  @override
  State<_TextStyleBar> createState() => _TextStyleBarState();
}

class _TextStyleBarState extends State<_TextStyleBar> {
  @override
  Widget build(BuildContext context) {
    final layer = widget.selectedLayer;
    if (!widget.visible || layer == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: _editorChromeSurfaceStrong.withValues(alpha: 0.25),
        image: const DecorationImage(
          image: AssetImage('assets/editor_ui/pattern_1.png'),
          fit: BoxFit.cover,
          opacity: 0.035,
        ),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildFocusedTab(layer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusedTab(_CanvasLayer layer) {
    return switch (widget.focusedTab) {
      _TextToolTab.color => _buildColorTab(layer),
      _TextToolTab.size => _buildSizeTab(layer),
      _TextToolTab.alignment => _buildAlignmentTab(layer),
      _TextToolTab.style => _buildStyleOnlyTab(layer),
      _TextToolTab.background => _buildBackgroundTab(layer),
    };
  }

  Widget _buildColorTab(_CanvasLayer layer) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionLabel(
          strings.localized(
            telugu: 'Ã Â°Â«Ã Â°Â¿Ã Â°Â²Ã Â±Â Ã Â°â€¢Ã Â°Â²Ã Â°Â°Ã Â±Â',
            english: 'Fill Color',
          ),
        ),
        const SizedBox(height: 10),
        _PressableSurface(
          onTap: widget.onColorWheelTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: <Color>[
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                    border: Border.all(color: Colors.white38),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.localized(
                      telugu: 'Color wheel & HEX code',
                      english: 'Color wheel & HEX code',
                    ),
                    style: const TextStyle(
                      color: _editorChromeTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _editorChromeTextSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildSectionLabel(
          strings.localized(
            telugu:
                'Ã Â°Å½Ã Â°â€šÃ Â°Å¡Ã Â±ÂÃ Â°â€¢Ã Â±ÂÃ Â°Â¨Ã Â±ÂÃ Â°Â¨ Ã Â°â€¢Ã Â°Â²Ã Â°Â°Ã Â±Â',
            english: 'Selected color',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: layer.textGradientIndex == -1 ? layer.textColor : null,
            gradient:
                layer.textGradientIndex >= 0 &&
                    layer.textGradientIndex < widget.gradients.length
                ? LinearGradient(
                    colors: widget.gradients[layer.textGradientIndex],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeTab(_CanvasLayer layer) {
    final strings = context.strings;
    return Column(
      children: <Widget>[
        _CompactLabeledSlider(
          sliderId: 'font-size',
          label: strings.localized(
            telugu: 'Ã Â°Â«Ã Â°Â¾Ã Â°â€šÃ Â°Å¸Ã Â±Â Ã Â°Â¸Ã Â±Ë†Ã Â°Å“Ã Â±Â',
            english: 'Font Size',
          ),
          value: layer.fontSize.clamp(18, 96).toDouble(),
          min: 18,
          max: 96,
          divisions: 78,
          valueText: layer.fontSize.toStringAsFixed(0),
          onChangeStart: widget.onFontSizeChangeStart,
          onChanged: widget.onFontSizeChanged,
          onChangeEnd: widget.onFontSizeChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'line-height',
          label: strings.localized(
            telugu:
                'Ã Â°Â²Ã Â±Ë†Ã Â°Â¨Ã Â±Â Ã Â°Â¸Ã Â±ÂÃ Â°ÂªÃ Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±Â',
            english: 'Line Spacing',
          ),
          value: layer.textLineHeight.clamp(0.8, 2.2).toDouble(),
          min: 0.8,
          max: 2.2,
          divisions: 14,
          valueText: layer.textLineHeight.toStringAsFixed(1),
          onChangeStart: widget.onLineHeightChangeStart,
          onChanged: widget.onLineHeightChanged,
          onChangeEnd: widget.onLineHeightChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'letter-spacing',
          label: strings.localized(
            telugu:
                'Ã Â°â€¦Ã Â°â€¢Ã Â±ÂÃ Â°Â·Ã Â°Â°Ã Â°Â¾Ã Â°Â² Ã Â°Â¦Ã Â±â€šÃ Â°Â°Ã Â°â€š',
            english: 'Letter Spacing',
          ),
          value: layer.textLetterSpacing.clamp(-100, 100).toDouble(),
          min: -100,
          max: 100,
          divisions: 40,
          valueText: layer.textLetterSpacing.toStringAsFixed(0),
          onChangeStart: widget.onLetterSpacingChangeStart,
          onChanged: widget.onLetterSpacingChanged,
          onChangeEnd: widget.onLetterSpacingChangeEnd,
        ),
      ],
    );
  }

  Widget _buildAlignmentTab(_CanvasLayer layer) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _AlignChip(
          icon: Icons.format_align_left_rounded,
          selected: layer.textAlign == TextAlign.left,
          onTap: () => widget.onAlignSelected(TextAlign.left),
        ),
        _AlignChip(
          icon: Icons.format_align_center_rounded,
          selected: layer.textAlign == TextAlign.center,
          onTap: () => widget.onAlignSelected(TextAlign.center),
        ),
        _AlignChip(
          icon: Icons.format_align_right_rounded,
          selected: layer.textAlign == TextAlign.right,
          onTap: () => widget.onAlignSelected(TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildStyleOnlyTab(_CanvasLayer layer) {
    final strings = context.strings;
    final styleItems = <Widget>[
      _TextStyleToggleChip(
        icon: Icons.format_bold_rounded,
        label: strings.localized(telugu: 'బోల్డ్', english: 'Bold'),
        selected: layer.isTextBold,
        onTap: widget.onBoldToggle,
      ),
      _TextStyleToggleChip(
        icon: Icons.format_italic_rounded,
        label: strings.localized(telugu: 'ఇటాలిక్', english: 'Italic'),
        selected: layer.isTextItalic,
        onTap: widget.onItalicToggle,
      ),
      _TextStyleToggleChip(
        icon: Icons.format_underline_rounded,
        label: strings.localized(telugu: 'అండర్‌లైన్', english: 'Underline'),
        selected: layer.isTextUnderline,
        onTap: widget.onUnderlineToggle,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: styleItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => styleItems[index],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _AlignChip(
              icon: Icons.format_align_left_rounded,
              selected: layer.textAlign == TextAlign.left,
              onTap: () => widget.onAlignSelected(TextAlign.left),
            ),
            _AlignChip(
              icon: Icons.format_align_center_rounded,
              selected: layer.textAlign == TextAlign.center,
              onTap: () => widget.onAlignSelected(TextAlign.center),
            ),
            _AlignChip(
              icon: Icons.format_align_right_rounded,
              selected: layer.textAlign == TextAlign.right,
              onTap: () => widget.onAlignSelected(TextAlign.right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundTab(_CanvasLayer layer) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CompactLabeledSlider(
          sliderId: 'background-opacity',
          label: strings.localized(
            telugu:
                'Ã Â°Â¬Ã Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°â€¢Ã Â±ÂÃ¢â‚¬Å’Ã Â°â€”Ã Â±ÂÃ Â°Â°Ã Â±Å’Ã Â°â€šÃ Â°Â¡Ã Â±Â Ã Â°â€¦Ã Â°ÂªÃ Â°Â¾Ã Â°Â¸Ã Â°Â¿Ã Â°Å¸Ã Â±â‚¬',
            english: 'Background Opacity',
          ),
          value: layer.textBackgroundOpacity.clamp(0, 1).toDouble(),
          min: 0,
          max: 1,
          valueText: layer.textBackgroundOpacity.toStringAsFixed(2),
          onChangeStart: widget.onBackgroundOpacityChangeStart,
          onChanged: widget.onBackgroundOpacityChanged,
          onChangeEnd: widget.onBackgroundOpacityChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'background-radius',
          label: strings.localized(
            telugu:
                'Ã Â°â€¢Ã Â±â€¹Ã Â°Â£Ã Â°Â¾Ã Â°Â² Ã Â°Â°Ã Â±â€¡Ã Â°Â¡Ã Â°Â¿Ã Â°Â¯Ã Â°Â¸Ã Â±Â',
            english: 'Corner Radius',
          ),
          value: layer.textBackgroundRadius.clamp(0, 100).toDouble(),
          min: 0,
          max: 100,
          valueText: layer.textBackgroundRadius.toStringAsFixed(0),
          onChangeStart: widget.onBackgroundRadiusChangeStart,
          onChanged: widget.onBackgroundRadiusChanged,
          onChangeEnd: widget.onBackgroundRadiusChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'background-top-width',
          label: strings.localized(
            telugu:
                'Ã Â°Å¸Ã Â°Â¾Ã Â°ÂªÃ Â±Â Ã Â°ÂµÃ Â±â€ Ã Â°Â¡Ã Â°Â²Ã Â±ÂÃ Â°ÂªÃ Â±Â',
            english: 'Top Width',
          ),
          value: layer.textBackgroundTopPadding.clamp(0, 100).toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          valueText: layer.textBackgroundTopPadding.toStringAsFixed(0),
          onChangeStart: widget.onBackgroundTopPaddingChangeStart,
          onChanged: widget.onBackgroundTopPaddingChanged,
          onChangeEnd: widget.onBackgroundTopPaddingChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'background-bottom-width',
          label: strings.localized(
            telugu:
                'Ã Â°Â¬Ã Â°Â¾Ã Â°Å¸Ã Â°Â®Ã Â±Â Ã Â°ÂµÃ Â±â€ Ã Â°Â¡Ã Â°Â²Ã Â±ÂÃ Â°ÂªÃ Â±Â',
            english: 'Bottom Width',
          ),
          value: layer.textBackgroundBottomPadding.clamp(0, 100).toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          valueText: layer.textBackgroundBottomPadding.toStringAsFixed(0),
          onChangeStart: widget.onBackgroundBottomPaddingChangeStart,
          onChanged: widget.onBackgroundBottomPaddingChanged,
          onChangeEnd: widget.onBackgroundBottomPaddingChangeEnd,
        ),
        const SizedBox(height: 10),
        _buildSectionLabel(
          strings.localized(
            telugu:
                'Ã Â°Â¬Ã Â±ÂÃ Â°Â¯Ã Â°Â¾Ã Â°â€¢Ã Â±ÂÃ¢â‚¬Å’Ã Â°â€”Ã Â±ÂÃ Â°Â°Ã Â±Å’Ã Â°â€šÃ Â°Â¡Ã Â±Â Ã Â°â€¢Ã Â°Â²Ã Â°Â°Ã Â±ÂÃ Â°Â¸Ã Â±Â',
            english: 'Background Colors',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.backgroundColors
              .map(
                (Color color) => _ColorDot(
                  color: color,
                  selected:
                      layer.textBackgroundColor.toARGB32() == color.toARGB32(),
                  onTap: () => widget.onBackgroundColorSelected(color),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

enum _TextEffectPreset { none, softShadow, hardShadow, outline, lift, poster }

class _CompactLabeledSlider extends StatelessWidget {
  const _CompactLabeledSlider({
    required this.sliderId,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    this.valueText,
    this.divisions,
  });

  final String sliderId;
  final String label;
  final double value;
  final double min;
  final double max;
  final String? valueText;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final snappedValue = _snapValue(value);
    final percentValue = _editorSliderToPercent(snappedValue, min, max);
    final displayValue = valueText ?? _formatSliderValue(snappedValue);
    void handleChangeStart(double percent) {
      onChangeStart(_valueFromPercent(percent));
    }

    void handleChanged(double percent) {
      onChanged(_valueFromPercent(percent));
    }

    void handleChangeEnd(double percent) {
      onChangeEnd(_valueFromPercent(percent));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF8B7FFF),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: Colors.white,
              overlayColor: const Color(0x338B7FFF),
            ),
            child: Slider(
              value: percentValue,
              min: 0,
              max: 100,
              divisions: divisions,
              onChangeStart: handleChangeStart,
              onChanged: handleChanged,
              onChangeEnd: handleChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  double _valueFromPercent(double percent) {
    return _snapValue(_editorPercentToSlider(percent, min, max));
  }

  double _snapValue(double rawValue) {
    final sliderDivisions = divisions;
    if (sliderDivisions == null || sliderDivisions <= 0) {
      return rawValue.clamp(min, max).toDouble();
    }
    return _snapEditorSliderValue(
      rawValue,
      min: min,
      max: max,
      step: (max - min) / sliderDivisions,
    );
  }

  String _formatSliderValue(double sliderValue) {
    final sliderDivisions = divisions;
    final step = sliderDivisions == null || sliderDivisions <= 0
        ? 1.0
        : (max - min).abs() / sliderDivisions;
    return step < 1
        ? sliderValue.toStringAsFixed(1)
        : sliderValue.toStringAsFixed(0);
  }
}

class _AlignChip extends StatelessWidget {
  const _AlignChip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1D4ED8).withValues(alpha: 0.28)
              : const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF60A5FA) : const Color(0xFF334155),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}

class _TextStyleToggleChip extends StatelessWidget {
  const _TextStyleToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: 108,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFFA78BFA).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.2 : 1,
          ),
          boxShadow: <BoxShadow>[
            if (selected)
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerActionButton extends StatelessWidget {
  const _LayerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedLayersFullscreenOverlay extends StatefulWidget {
  const _AdvancedLayersFullscreenOverlay({
    required this.layers,
    required this.selectedLayerId,
    required this.autoSelectCanvasLayer,
    required this.onAutoSelectCanvasLayerTap,
    required this.onSelectLayer,
    required this.onDeleteLayer,
    required this.onToggleLayerLock,
    required this.onToggleLayerVisibility,
    required this.onReorderLayers,
    required this.onMoveToFront,
    required this.onMoveToBack,
    required this.onEditText,
    required this.onBlendModeChanged,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final bool autoSelectCanvasLayer;
  final VoidCallback onAutoSelectCanvasLayerTap;
  final ValueChanged<String> onSelectLayer;
  final ValueChanged<String> onDeleteLayer;
  final ValueChanged<String> onToggleLayerLock;
  final ValueChanged<String> onToggleLayerVisibility;
  final void Function(int oldIndex, int newIndex) onReorderLayers;
  final ValueChanged<String> onMoveToFront;
  final ValueChanged<String> onMoveToBack;
  final ValueChanged<String> onEditText;
  final void Function(String layerId, BlendMode blendMode) onBlendModeChanged;

  @override
  State<_AdvancedLayersFullscreenOverlay> createState() =>
      _AdvancedLayersFullscreenOverlayState();
}

class _AdvancedLayersFullscreenOverlayState
    extends State<_AdvancedLayersFullscreenOverlay> {
  bool _blendOptionsExpanded = false;
  late String? _panelSelectedLayerId;
  late bool _panelAutoSelectCanvasLayer;

  static const List<(String, BlendMode)> _blendModes = <(String, BlendMode)>[
    ('Normal', BlendMode.srcOver),
    ('Multiply', BlendMode.multiply),
    ('Screen', BlendMode.screen),
    ('Overlay', BlendMode.overlay),
    ('Darken', BlendMode.darken),
    ('Lighten', BlendMode.lighten),
    ('Color Dodge', BlendMode.colorDodge),
    ('Color Burn', BlendMode.colorBurn),
    ('Soft Light', BlendMode.softLight),
    ('Hard Light', BlendMode.hardLight),
    ('Difference', BlendMode.difference),
  ];

  @override
  void initState() {
    super.initState();
    _panelSelectedLayerId = widget.selectedLayerId;
    _panelAutoSelectCanvasLayer = widget.autoSelectCanvasLayer;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final selectedLayerId = _panelSelectedLayerId;
    final selectedLayer = selectedLayerId == null
        ? null
        : widget.layers.cast<_CanvasLayer?>().firstWhere(
            (layer) => layer?.id == selectedLayerId,
            orElse: () => null,
          );
    final selectedBlendMode = selectedLayer?.blendMode ?? BlendMode.srcOver;
    final selectedBlend = _blendModes
        .firstWhere(
          (entry) => entry.$2 == selectedBlendMode,
          orElse: () => _blendModes.first,
        )
        .$1;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: ColoredBox(color: const Color(0xFF0B0D12)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: 0.58,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _editorChromeSurfaceStrong,
                  image: const DecorationImage(
                    image: AssetImage(
                      'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_layers_panel_bg.png',
                    ),
                    fit: BoxFit.cover,
                    opacity: 0,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: _editorChromeBorder.withValues(alpha: 0.45),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(top: 9, bottom: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 10, 6),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.layers_rounded,
                              color: Color(0xFFB8AEFF),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                strings.localized(
                                  telugu:
                                      'Ã Â°Â²Ã Â±â€¡Ã Â°Â¯Ã Â°Â°Ã Â±ÂÃ Â°Â¸Ã Â±Â',
                                  english: 'Layers',
                                ),
                                style: const TextStyle(
                                  color: _editorChromeTextPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _panelAutoSelectCanvasLayer
                                  ? 'Auto Select On'
                                  : 'Auto Select Off',
                              onPressed: () {
                                widget.onAutoSelectCanvasLayerTap();
                                setState(() {
                                  _panelAutoSelectCanvasLayer =
                                      !_panelAutoSelectCanvasLayer;
                                });
                              },
                              icon: Icon(
                                _panelAutoSelectCanvasLayer
                                    ? Icons.touch_app_rounded
                                    : Icons.pan_tool_alt_outlined,
                                color: _panelAutoSelectCanvasLayer
                                    ? const Color(0xFF38BDF8)
                                    : _editorChromeTextSecondary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _editorChromeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedLayerId != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                          child: Row(
                            children: <Widget>[
                              if (selectedLayer != null &&
                                  (selectedLayer.isText ||
                                      ((selectedLayer.psdEditableText ?? '')
                                          .trim()
                                          .isNotEmpty))) ...<Widget>[
                                _LayerActionButton(
                                  icon: Icons.edit_note_rounded,
                                  label: 'Edit text',
                                  onTap: () {
                                    widget.onEditText(selectedLayerId);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const SizedBox(width: 6),
                              ],
                              _LayerActionButton(
                                icon: Icons.vertical_align_top_rounded,
                                label: 'Front',
                                onTap: () =>
                                    widget.onMoveToFront(selectedLayerId),
                              ),
                              const SizedBox(width: 6),
                              _LayerActionButton(
                                icon: Icons.vertical_align_bottom_rounded,
                                label: 'Back',
                                onTap: () =>
                                    widget.onMoveToBack(selectedLayerId),
                              ),
                              const SizedBox(width: 6),
                              _LayerActionButton(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                onTap: () {
                                  widget.onDeleteLayer(selectedLayerId);
                                  setState(() {
                                    _panelSelectedLayerId = null;
                                    _blendOptionsExpanded = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                        child: _buildBlendModePicker(
                          selectedLayerId: selectedLayerId,
                          selectedBlend: selectedBlend,
                          selectedBlendMode: selectedBlendMode,
                        ),
                      ),
                      Expanded(child: _buildLayersList()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlendModePicker({
    required String? selectedLayerId,
    required String selectedBlend,
    required BlendMode selectedBlendMode,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181A20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _editorChromeBorder),
        ),
        child: Column(
          children: <Widget>[
            ListTile(
              dense: true,
              enabled: selectedLayerId != null,
              onTap: selectedLayerId == null
                  ? null
                  : () => setState(
                      () => _blendOptionsExpanded = !_blendOptionsExpanded,
                    ),
              leading: const Icon(
                Icons.auto_awesome_mosaic_outlined,
                color: Color(0xFFB8AEFF),
              ),
              title: const Text(
                'Blending options',
                style: TextStyle(
                  color: _editorChromeTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                selectedLayerId == null ? 'Select a layer' : selectedBlend,
                style: const TextStyle(color: _editorChromeTextSecondary),
              ),
              trailing: AnimatedRotation(
                turns: _blendOptionsExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _editorChromeTextSecondary,
                ),
              ),
            ),
            if (_blendOptionsExpanded && selectedLayerId != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 142),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  shrinkWrap: true,
                  itemCount: _blendModes.length,
                  itemBuilder: (context, index) {
                    final entry = _blendModes[index];
                    final label = entry.$1;
                    final mode = entry.$2;
                    final selected = mode == selectedBlendMode;
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      selected: selected,
                      selectedTileColor: const Color(0xFF34314F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFD8D3FF)
                              : _editorChromeTextPrimary,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFFB8AEFF),
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onBlendModeChanged(selectedLayerId, mode);
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayersList() {
    final displayLayers = widget.layers.reversed.toList(growable: false);
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: displayLayers.length,
      onReorderItem: (oldIndex, newIndex) {
        if (oldIndex < 0 || oldIndex >= displayLayers.length) return;
        final reordered = List<_CanvasLayer>.of(displayLayers);
        final displayInsertIndex = newIndex
            .clamp(0, reordered.length - 1)
            .toInt();
        if (displayInsertIndex == oldIndex) return;
        final movedLayer = reordered.removeAt(oldIndex);
        reordered.insert(displayInsertIndex, movedLayer);

        final oldCanvasIndex = widget.layers.indexWhere(
          (layer) => layer.id == movedLayer.id,
        );
        final desiredCanvasOrder = reordered.reversed.toList(growable: false);
        final newCanvasIndex = desiredCanvasOrder.indexWhere(
          (layer) => layer.id == movedLayer.id,
        );
        if (oldCanvasIndex == -1 || newCanvasIndex == -1) return;
        widget.onReorderLayers(oldCanvasIndex, newCanvasIndex);
        setState(() {});
      },
      buildDefaultDragHandles: false,
      itemBuilder: (BuildContext context, int index) {
        final layer = displayLayers[index];
        final selected = layer.id == _panelSelectedLayerId;
        final lockColor = layer.isLocked
            ? const Color(0xFFEF4444)
            : _editorChromeTextSecondary;
        return Container(
          key: ValueKey<String>(layer.id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2E3340) : const Color(0xFF181A20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFF30333C),
            ),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            onTap: () {
              widget.onSelectLayer(layer.id);
              setState(() {
                _panelSelectedLayerId = layer.id;
              });
            },
            contentPadding: const EdgeInsets.only(left: 12, right: 4),
            leading: _buildLayerPreview(layer),
            title: Text(
              _layerTitle(layer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _editorChromeTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              selected ? 'Selected' : 'Tap to select',
              style: const TextStyle(
                color: _editorChromeTextSecondary,
                fontSize: 11,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onToggleLayerVisibility(layer.id);
                    setState(() {});
                  },
                  icon: Icon(
                    layer.isHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _editorChromeTextSecondary,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: layer.isLocked ? 'Unlock layer' : 'Lock layer',
                  style: IconButton.styleFrom(
                    backgroundColor: layer.isLocked
                        ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                        : Colors.transparent,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onToggleLayerLock(layer.id);
                    setState(() {});
                  },
                  icon: Icon(
                    layer.isLocked
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    color: lockColor,
                  ),
                ),
                Opacity(
                  opacity: layer.isLocked ? 0.35 : 1,
                  child: layer.isLocked
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: _editorChromeTextSecondary,
                          ),
                        )
                      : ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: _editorChromeTextSecondary,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayerPreview(_CanvasLayer layer) {
    if (layer.isPhoto && layer.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Image.memory(
            layer.bytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      );
    }
    if (layer.isText) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.text_fields_rounded, color: Color(0xFFE2E8F0)),
      );
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: _EditorTextState._buildStickerVisual(
          layer.sticker,
          fontSize: 24,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.low,
          color: _EditorTextState._isImageLikeSticker(layer.sticker)
              ? null
              : layer.stickerColor,
        ),
      ),
    );
  }

  String _layerTitle(_CanvasLayer layer) {
    final customName = layer.layerName.trim();
    if (customName.isNotEmpty) {
      return customName;
    }
    if (layer.isPhoto) {
      return 'Photo Layer';
    }
    if (layer.isText) {
      return (layer.text?.trim().isNotEmpty ?? false)
          ? layer.text!.trim()
          : 'Text Layer';
    }
    return 'Sticker Layer';
  }
}

class _EditorCommitOverlay extends StatelessWidget {
  const _EditorCommitOverlay({required this.label, this.detail});

  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _EditorProcessingCard(label: label, detail: detail),
    );
  }
}

class _EditorProcessingCard extends StatelessWidget {
  const _EditorProcessingCard({required this.label, this.detail});

  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 248,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: _editorChromeSurfaceStrong.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.26),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox.square(
                dimension: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _editorChromeTextPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (detail != null && detail!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _editorChromeTextSecondary,
                    fontSize: 12,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StickerBrowserFullscreenOverlay extends StatefulWidget {
  const StickerBrowserFullscreenOverlay({
    super.key,
    required this.categories,
    required this.catalog,
    this.initialCategory,
  });

  final List<String> categories;
  final Map<String, List<String>> catalog;
  final String? initialCategory;

  @override
  State<StickerBrowserFullscreenOverlay> createState() =>
      _StickerBrowserFullscreenOverlayState();
}

class _StickerBrowserFullscreenOverlayState
    extends State<StickerBrowserFullscreenOverlay> {
  late String _selectedCategory =
      widget.initialCategory != null &&
          widget.categories.contains(widget.initialCategory)
      ? widget.initialCategory!
      : widget.categories.first;

  @override
  Widget build(BuildContext context) {
    final stickers = widget.catalog[_selectedCategory] ?? const <String>[];
    final strings = context.strings;
    return EditorFullscreenOverlay(
      title: strings.localized(
        telugu: 'Ã Â°Â¸Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€¢Ã Â°Â°Ã Â±ÂÃ Â°Â¸Ã Â±Â',
        english: 'Assets',
      ),
      doneLabel: strings.localized(
        telugu: 'Ã Â°Â®Ã Â±â€šÃ Â°Â¸Ã Â°Â¿Ã Â°ÂµÃ Â±â€¡Ã Â°Â¯Ã Â°Â¿',
        english: 'Close',
      ),
      onBack: () => Navigator.of(context).pop(),
      onDone: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final category = widget.categories[index];
                  final selected = category == _selectedCategory;
                  return _PressableSurface(
                    onTap: () => setState(() => _selectedCategory = category),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: stickers.length,
                itemBuilder: (BuildContext context, int index) {
                  final sticker = stickers[index];
                  final imageLike = _EditorTextState._isImageLikeSticker(
                    sticker,
                  );
                  return _PressableSurface(
                    onTap: () => Navigator.of(context).pop(sticker),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Center(
                        child: imageLike
                            ? _EditorTextState._buildStickerVisual(
                                sticker,
                                fontSize: 38,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                              )
                            : Text(
                                sticker,
                                style: const TextStyle(fontSize: 34, height: 1),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableSurface extends StatefulWidget {
  const _PressableSurface({
    required this.child,
    this.onTap,
    this.borderRadius,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  State<_PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<_PressableSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    return AnimatedScale(
      scale: _pressed && enabled ? 0.98 : 1,
      duration: const Duration(milliseconds: 90),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            highlightColor: const Color(0xFF7C6DFF).withValues(alpha: 0.18),
            splashColor: const Color(0xFF7C6DFF).withValues(alpha: 0.16),
            hoverColor: const Color(0xFF7C6DFF).withValues(alpha: 0.08),
            onTap: enabled ? widget.onTap : null,
            onHighlightChanged: _setPressed,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.assetIcon,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final String? assetIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 40.0;
    final safeAssetIcon = _isUsableEditorAssetIcon(assetIcon)
        ? assetIcon
        : null;
    return Tooltip(
      message: tooltip,
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        enabled: onTap != null,
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: onTap == null
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: safeAssetIcon == null
                ? Icon(
                    icon,
                    size: compact ? 18 : 20,
                    color: _editorChromeTextPrimary,
                  )
                : Image.asset(
                    safeAssetIcon,
                    width: compact ? 19 : 21,
                    height: compact ? 19 : 21,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => Icon(
                      icon,
                      size: compact ? 18 : 20,
                      color: _editorChromeTextPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

const Set<String> _placeholderEditorAssetIcons = <String>{
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_background.png',
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_crop_free.png',
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_draw.png',
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_feed_moretools.png',
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_border.png',
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_font_style_ab.png',
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_shapes.png',
  'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_text_format.png',
};

bool _isUsableEditorAssetIcon(String? assetIcon) {
  return assetIcon != null && !_placeholderEditorAssetIcons.contains(assetIcon);
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.88);
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.32);
    final rect = Offset.zero & size;
    canvas.drawRect(rect, framePaint);

    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;
    for (var i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(thirdWidth * i, 0),
        Offset(thirdWidth * i, size.height),
        guidePaint,
      );
      canvas.drawLine(
        Offset(0, thirdHeight * i),
        Offset(size.width, thirdHeight * i),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.assetIcon,
    this.active = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final String? assetIcon;
  final VoidCallback onTap;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final safeAssetIcon = _isUsableEditorAssetIcon(assetIcon)
        ? assetIcon
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideRailTile =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth >= 108 &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight <= 64;
        final iconWidget = SizedBox(
          width: sideRailTile ? 30 : (compact ? 25 : 27),
          height: sideRailTile ? 30 : (compact ? 25 : 27),
          child: safeAssetIcon == null
              ? Icon(
                  icon,
                  size: sideRailTile ? 25 : (compact ? 24 : 26),
                  color: active ? Colors.white : _editorChromeTextPrimary,
                )
              : Image.asset(
                  safeAssetIcon,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Icon(
                    icon,
                    size: sideRailTile ? 25 : (compact ? 24 : 26),
                    color: active ? Colors.white : _editorChromeTextPrimary,
                  ),
                ),
        );
        final labelWidget = Text(
          label,
          maxLines: sideRailTile ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: sideRailTile ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : _editorChromeTextPrimary,
            fontSize: sideRailTile ? 11.2 : (compact ? 9.0 : 9.5),
            height: 1.05,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
          ),
        );
        return _PressableSurface(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF7C6DFF).withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: sideRailTile ? 0.06 : 0),
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border.all(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.42),
                    )
                  : null,
            ),
            padding: sideRailTile
                ? const EdgeInsets.symmetric(horizontal: 9, vertical: 6)
                : EdgeInsets.symmetric(
                    vertical: compact ? 3 : 4,
                    horizontal: 2,
                  ),
            child: sideRailTile
                ? Row(
                    children: <Widget>[
                      iconWidget,
                      const SizedBox(width: 8),
                      Expanded(child: labelWidget),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: active ? 3 : 0,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6DFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      iconWidget,
                      const SizedBox(height: 5),
                      labelWidget,
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: active ? 18 : 0,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6DFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _DraftsScreen extends StatefulWidget {
  const _DraftsScreen({
    required this.storageService,
    required this.onSaveCurrentDraft,
    required this.onOpenDraft,
  });

  final EditorDraftStorageService storageService;
  final Future<void> Function() onSaveCurrentDraft;
  final Future<void> Function(Map<String, dynamic> draft) onOpenDraft;

  @override
  State<_DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<_DraftsScreen> {
  late Future<List<FileSystemEntity>> _draftsFuture = _loadDrafts();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.enableSecure());
  }

  @override
  void dispose() {
    unawaited(ScreenSecurityService.disableSecure());
    super.dispose();
  }

  Future<List<FileSystemEntity>> _loadDrafts() {
    return widget.storageService.listManualDraftFiles();
  }

  Future<void> _refresh() async {
    setState(() {
      _draftsFuture = _loadDrafts();
    });
  }

  Future<void> _saveCurrentDraft() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    await widget.onSaveCurrentDraft();
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    await _refresh();
  }

  Future<void> _openDraft(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    await widget.onOpenDraft(decoded);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _deleteDraft(File file) async {
    await file.delete();
    if (!mounted) {
      return;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      backgroundColor: _editorCanvasBackdrop,
      appBar: AppBar(
        backgroundColor: _editorChromeSurfaceStrong,
        elevation: 0,
        foregroundColor: _editorChromeTextPrimary,
        title: Text(
          strings.localized(
            telugu:
                'Ã Â°Â¡Ã Â±ÂÃ Â°Â°Ã Â°Â¾Ã Â°Â«Ã Â±ÂÃ Â°Å¸Ã Â±ÂÃ Â°Â¸Ã Â±Â',
            english: 'Drafts',
          ),
          style: const TextStyle(
            color: _editorChromeTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _saveCurrentDraft,
            child: Text(
              _saving
                  ? strings.localized(
                      telugu:
                          'Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°â€¦Ã Â°ÂµÃ Â±ÂÃ Â°Â¤Ã Â±â€¹Ã Â°â€šÃ Â°Â¦Ã Â°Â¿...',
                      english: 'Saving...',
                    )
                  : strings.localized(
                      telugu:
                          'Ã Â°ÂªÃ Â±ÂÃ Â°Â°Ã Â°Â¸Ã Â±ÂÃ Â°Â¤Ã Â±ÂÃ Â°Â¤Ã Â°Â¾Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¿ Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¯Ã Â°Â¿',
                      english: 'Save Current',
                    ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _draftsFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<FileSystemEntity>> snapshot,
            ) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final files =
                  snapshot.data?.whereType<File>().toList(growable: false) ??
                  const <File>[];
              if (files.isEmpty) {
                return Center(
                  child: Text(
                    strings.localized(
                      telugu:
                          'Ã Â°â€¡Ã Â°â€šÃ Â°â€¢Ã Â°Â¾ Ã Â°Â¸Ã Â±â€¡Ã Â°ÂµÃ Â±Â Ã Â°Å¡Ã Â±â€¡Ã Â°Â¸Ã Â°Â¿Ã Â°Â¨ Ã Â°Â¡Ã Â±ÂÃ Â°Â°Ã Â°Â¾Ã Â°Â«Ã Â±ÂÃ Â°Å¸Ã Â±ÂÃ Â°Â¸Ã Â±Â Ã Â°Â²Ã Â±â€¡Ã Â°ÂµÃ Â±Â',
                      english: 'No saved drafts yet',
                    ),
                    style: const TextStyle(color: _editorChromeTextSecondary),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: files.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final file = files[index];
                  final name = file.uri.pathSegments.isNotEmpty
                      ? file.uri.pathSegments.last.replaceAll('.json', '')
                      : 'draft';
                  final modified = file.lastModifiedSync();
                  return Container(
                    decoration: BoxDecoration(
                      color: _editorChromeSurfaceStrong,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _editorChromeBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => _openDraft(file),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: _editorChromeTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          modified.toLocal().toString(),
                          style: const TextStyle(
                            color: _editorChromeTextSecondary,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => _deleteDraft(file),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: _editorChromeTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
      ),
    );
  }
}
