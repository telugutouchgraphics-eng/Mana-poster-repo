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
          strings.localized(telugu: 'ఫిల్ కలర్', english: 'Fill Color'),
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
            telugu: 'ఎంచుకున్న కలర్',
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
          label: strings.localized(telugu: 'ఫాంట్ సైజ్', english: 'Font Size'),
          value: layer.fontSize.clamp(1, 220).toDouble(),
          min: 1,
          max: 220,
          divisions: 219,
          valueText: layer.fontSize.toStringAsFixed(0),
          onChangeStart: widget.onFontSizeChangeStart,
          onChanged: widget.onFontSizeChanged,
          onChangeEnd: widget.onFontSizeChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'line-height',
          label: strings.localized(
            telugu: 'లైన్ స్పేసింగ్',
            english: 'Line Spacing',
          ),
          value: layer.textLineHeight.clamp(0.2, 5.0).toDouble(),
          min: 0.2,
          max: 5.0,
          divisions: 96,
          valueText: layer.textLineHeight.toStringAsFixed(2),
          onChangeStart: widget.onLineHeightChangeStart,
          onChanged: widget.onLineHeightChanged,
          onChangeEnd: widget.onLineHeightChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'letter-spacing',
          label: strings.localized(
            telugu: 'అక్షరాల దూరం',
            english: 'Letter Spacing',
          ),
          value: layer.textLetterSpacing.clamp(-200, 200).toDouble(),
          min: -200,
          max: 200,
          divisions: 160,
          valueText: layer.textLetterSpacing.toStringAsFixed(1),
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
    final effectiveOpacity = layer.textBackgroundOpacity.clamp(0, 1).toDouble();
    final effectiveRadius = layer.textBackgroundRadius.clamp(0, 100).toDouble();
    final effectiveTopPadding = layer.textBackgroundTopPadding
        .clamp(0, 100)
        .toDouble();
    final effectiveBottomPadding = layer.textBackgroundBottomPadding
        .clamp(0, 100)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildBackgroundPreview(layer),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildBackgroundActionChip(
                icon: Icons.block_rounded,
                label: 'Transparent',
                onTap: () => _applyBackgroundPreset(
                  opacity: 0,
                  radius: effectiveRadius,
                  topPadding: effectiveTopPadding,
                  bottomPadding: effectiveBottomPadding,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBackgroundActionChip(
                icon: Icons.restart_alt_rounded,
                label: 'Reset',
                onTap: () => _applyBackgroundPreset(
                  opacity: 0.72,
                  radius: 18,
                  topPadding: 18,
                  bottomPadding: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionLabel('Quick Styles'),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              _buildBackgroundPresetChip(
                label: 'Soft',
                selected:
                    effectiveOpacity >= 0.68 &&
                    effectiveOpacity <= 0.82 &&
                    effectiveRadius >= 14 &&
                    effectiveRadius <= 28,
                onTap: () => _applyBackgroundPreset(
                  opacity: 0.74,
                  radius: 20,
                  topPadding: 18,
                  bottomPadding: 18,
                ),
              ),
              _buildBackgroundPresetChip(
                label: 'Pill',
                selected: effectiveRadius >= 60,
                onTap: () => _applyBackgroundPreset(
                  opacity: 0.82,
                  radius: 86,
                  topPadding: 14,
                  bottomPadding: 14,
                ),
              ),
              _buildBackgroundPresetChip(
                label: 'Label',
                selected:
                    effectiveRadius <= 10 &&
                    effectiveTopPadding <= 14 &&
                    effectiveBottomPadding <= 14,
                onTap: () => _applyBackgroundPreset(
                  opacity: 0.9,
                  radius: 8,
                  topPadding: 10,
                  bottomPadding: 10,
                ),
              ),
              _buildBackgroundPresetChip(
                label: 'Poster',
                selected:
                    effectiveOpacity >= 0.9 &&
                    effectiveTopPadding >= 26 &&
                    effectiveBottomPadding >= 26,
                onTap: () => _applyBackgroundPreset(
                  opacity: 0.96,
                  radius: 26,
                  topPadding: 30,
                  bottomPadding: 30,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CompactLabeledSlider(
          sliderId: 'background-opacity',
          label: strings.localized(
            telugu: 'బ్యాక్‌గ్రౌండ్ అపాసిటీ',
            english: 'Background Opacity',
          ),
          value: effectiveOpacity,
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
            telugu: 'కోణాల రేడియస్',
            english: 'Corner Radius',
          ),
          value: effectiveRadius,
          min: 0,
          max: 100,
          divisions: 100,
          valueText: layer.textBackgroundRadius.toStringAsFixed(0),
          onChangeStart: widget.onBackgroundRadiusChangeStart,
          onChanged: widget.onBackgroundRadiusChanged,
          onChangeEnd: widget.onBackgroundRadiusChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'background-top-width',
          label: strings.localized(
            telugu: 'టాప్ వెడల్పు',
            english: 'Top Width',
          ),
          value: effectiveTopPadding,
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
            telugu: 'బాటమ్ వెడల్పు',
            english: 'Bottom Width',
          ),
          value: effectiveBottomPadding,
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
            telugu: 'బ్యాక్‌గ్రౌండ్ కలర్స్',
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

  void _applyBackgroundPreset({
    required double opacity,
    required double radius,
    required double topPadding,
    required double bottomPadding,
  }) {
    widget.onBackgroundOpacityChanged(opacity);
    widget.onBackgroundRadiusChanged(radius);
    widget.onBackgroundTopPaddingChanged(topPadding);
    widget.onBackgroundBottomPaddingChanged(bottomPadding);
  }

  Widget _buildBackgroundPreview(_CanvasLayer layer) {
    final previewText = (_resolveLayerRenderText(layer).trim().isEmpty)
        ? 'Text Background'
        : _resolveLayerRenderText(layer).trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: EdgeInsets.fromLTRB(
            18,
            layer.textBackgroundTopPadding.clamp(0, 100).toDouble() * 0.42,
            18,
            layer.textBackgroundBottomPadding.clamp(0, 100).toDouble() * 0.42,
          ),
          decoration: BoxDecoration(
            color: layer.textBackgroundColor.withValues(
              alpha: layer.textBackgroundOpacity.clamp(0, 1).toDouble(),
            ),
            borderRadius: BorderRadius.circular(
              layer.textBackgroundRadius.clamp(0, 100).toDouble() * 0.72,
            ),
          ),
          child: Text(
            previewText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: layer.textColor,
              fontSize: 17,
              fontWeight: layer.isTextBold ? FontWeight.w800 : FontWeight.w700,
              height: 1.18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPresetChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.72)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFFE0F2FE)
                  : const Color(0xFFCBD5E1),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
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

class _TextTypingResult {
  const _TextTypingResult({
    required this.text,
    required this.textAlign,
    required this.textColor,
  });

  final String text;
  final TextAlign textAlign;
  final Color textColor;
}

class _NativeTextTypingScreen extends StatefulWidget {
  const _NativeTextTypingScreen({
    required this.initialText,
    required this.initialTextAlign,
    required this.initialTextColor,
    required this.colors,
    required this.selectAll,
  });

  final String initialText;
  final TextAlign initialTextAlign;
  final Color initialTextColor;
  final List<Color> colors;
  final bool selectAll;

  @override
  State<_NativeTextTypingScreen> createState() =>
      _NativeTextTypingScreenState();
}

class _NativeTextTypingScreenState extends State<_NativeTextTypingScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late TextAlign _textAlign;
  late Color _textColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _textAlign = widget.initialTextAlign;
    _textColor = widget.initialTextColor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
      final length = _controller.text.length;
      _controller.selection = widget.selectAll
          ? TextSelection(baseOffset: 0, extentOffset: length)
          : TextSelection.collapsed(offset: length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _closeWithText() {
    Navigator.of(context).pop(
      _TextTypingResult(
        text: _controller.text,
        textAlign: _textAlign,
        textColor: _textColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: Colors.black.withValues(alpha: 0.25),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, viewInsets.bottom + 12),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 46,
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        _TypingAlignButton(
                          icon: Icons.format_align_left_rounded,
                          selected: _textAlign == TextAlign.left,
                          onTap: () => setState(() {
                            _textAlign = TextAlign.left;
                          }),
                        ),
                        _TypingAlignButton(
                          icon: Icons.format_align_center_rounded,
                          selected: _textAlign == TextAlign.center,
                          onTap: () => setState(() {
                            _textAlign = TextAlign.center;
                          }),
                        ),
                        _TypingAlignButton(
                          icon: Icons.format_align_right_rounded,
                          selected: _textAlign == TextAlign.right,
                          onTap: () => setState(() {
                            _textAlign = TextAlign.right;
                          }),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _closeWithText,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF111827),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      enableInteractiveSelection: true,
                      autocorrect: true,
                      enableSuggestions: true,
                      cursorColor: Colors.white,
                      cursorWidth: 2,
                      textAlign: _textAlign,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 28,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.28),
                        hintText: 'Type text',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding: const EdgeInsets.all(18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.72),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: widget.colors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final color = widget.colors[index];
                        return _TypingColorBubble(
                          color: color,
                          selected: color.toARGB32() == _textColor.toARGB32(),
                          onTap: () => setState(() {
                            _textColor = color;
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingAlignButton extends StatelessWidget {
  const _TypingAlignButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Align',
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.transparent,
      ),
      icon: Icon(icon, color: Colors.white, size: 21),
    );
  }
}

class _TypingColorBubble extends StatelessWidget {
  const _TypingColorBubble({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = color.toARGB32() == Colors.white.toARGB32();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 38,
        height: 38,
        padding: EdgeInsets.all(selected ? 3 : 5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isWhite
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingLayerNudgeControl extends StatelessWidget {
  const _FloatingLayerNudgeControl({
    required this.expanded,
    required this.canNudge,
    required this.isAtEdge,
    required this.onToggle,
    required this.onNudge,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final bool expanded;
  final bool canNudge;
  final bool isAtEdge;
  final VoidCallback onToggle;
  final ValueChanged<Offset> onNudge;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  static const double collapsedSize = 42;
  static const double expandedSize = 138;

  @override
  Widget build(BuildContext context) {
    final opacity = expanded ? 0.94 : (isAtEdge ? 0.34 : 0.62);
    final size = expanded ? expandedSize : collapsedSize;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      onTap: onToggle,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(expanded ? 22 : 999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: expanded
              ? _LayerNudgePad(canNudge: canNudge, onNudge: onNudge)
              : Icon(
                  Icons.open_with_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 21,
                ),
        ),
      ),
    );
  }
}

class _LayerNudgePad extends StatelessWidget {
  const _LayerNudgePad({required this.canNudge, required this.onNudge});

  final bool canNudge;
  final ValueChanged<Offset> onNudge;

  @override
  Widget build(BuildContext context) {
    const step = 2.0;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: _LayerNudgeButton(
              icon: Icons.keyboard_arrow_up_rounded,
              enabled: canNudge,
              onTap: () => onNudge(const Offset(0, -step)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _LayerNudgeButton(
              icon: Icons.keyboard_arrow_left_rounded,
              enabled: canNudge,
              onTap: () => onNudge(const Offset(-step, 0)),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.control_camera_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: canNudge ? 0.9 : 0.34),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _LayerNudgeButton(
              icon: Icons.keyboard_arrow_right_rounded,
              enabled: canNudge,
              onTap: () => onNudge(const Offset(step, 0)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _LayerNudgeButton(
              icon: Icons.keyboard_arrow_down_rounded,
              enabled: canNudge,
              onTap: () => onNudge(const Offset(0, step)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerNudgeButton extends StatefulWidget {
  const _LayerNudgeButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_LayerNudgeButton> createState() => _LayerNudgeButtonState();
}

class _LayerNudgeButtonState extends State<_LayerNudgeButton> {
  Timer? _repeatTimer;

  void _startRepeating() {
    if (!widget.enabled) {
      return;
    }
    _stopRepeating();
    widget.onTap();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (widget.enabled) {
        widget.onTap();
      } else {
        _stopRepeating();
      }
    });
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void didUpdateWidget(covariant _LayerNudgeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _stopRepeating();
    }
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPressStart: widget.enabled ? (_) => _startRepeating() : null,
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.enabled
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
        ),
        child: Icon(
          widget.icon,
          size: 28,
          color: Colors.white.withValues(alpha: widget.enabled ? 0.95 : 0.32),
        ),
      ),
    );
  }
}

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
    required this.onClose,
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
  final VoidCallback onClose;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = math.min(
          390.0,
          math.max(292.0, constraints.maxWidth * 0.82),
        );
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onClose,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.06)),
            ),
            AnimatedAlign(
              alignment: Alignment.centerRight,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: panelWidth,
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
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: _editorChromeBorder.withValues(alpha: 0.45),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 26,
                        offset: Offset(-8, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    left: false,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 4,
                          height: 36,
                          margin: const EdgeInsets.only(top: 10, bottom: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            border: Border(
                              bottom: BorderSide(
                                color: _editorChromeBorder.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
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
                                    telugu: 'లేయర్స్',
                                    english: 'Layers',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF),
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
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              IconButton(
                                onPressed: widget.onClose,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFFFFFFF),
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
                                      widget.onClose();
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
          ],
        );
      },
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
  const _EditorCommitOverlay({
    required this.label,
    this.detail,
    this.compact = false,
  });

  final String label;
  final String? detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF020617).withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.22),
            ),
          ),
          child: const SizedBox.square(
            dimension: 46,
            child: Padding(
              padding: EdgeInsets.all(11),
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xEFFFFFFF)),
              ),
            ),
          ),
        ),
      );
    }
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
    required this.remoteCatalog,
    required this.localAssetPath,
    required this.requestRemoteAssetAccess,
    required this.downloadAsset,
    this.initialCategory,
  });

  final List<String> categories;
  final Map<String, List<String>> catalog;
  final EditorAssetCatalog remoteCatalog;
  final Future<String?> Function(EditorRemoteAsset asset) localAssetPath;
  final Future<bool> Function() requestRemoteAssetAccess;
  final Future<String> Function(
    EditorRemoteAsset asset,
    void Function(double progress) onProgress,
  )
  downloadAsset;
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
  String? _downloadingAssetId;
  double _downloadProgress = 0;
  final Map<String, String> _downloadedAssetPaths = <String, String>{};
  final Set<String> _checkingAssetIds = <String>{};

  List<EditorRemoteAsset> get _remoteAssets {
    final categoryIds = widget.remoteCatalog.categories
        .where((item) => item.name == _selectedCategory)
        .map((item) => item.id)
        .toSet();
    return widget.remoteCatalog.assets
        .where((item) => categoryIds.contains(item.categoryId))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVisibleRemoteAssets();
    });
  }

  @override
  void didUpdateWidget(covariant StickerBrowserFullscreenOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remoteCatalog != widget.remoteCatalog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkVisibleRemoteAssets();
      });
    }
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVisibleRemoteAssets();
    });
  }

  void _checkVisibleRemoteAssets() {
    for (final asset in _remoteAssets) {
      if (asset.kind == 'text' ||
          _downloadedAssetPaths.containsKey(asset.id) ||
          _checkingAssetIds.contains(asset.id)) {
        continue;
      }
      _checkingAssetIds.add(asset.id);
      unawaited(_checkRemoteAsset(asset));
    }
  }

  Future<void> _checkRemoteAsset(EditorRemoteAsset asset) async {
    final path = await widget.localAssetPath(asset);
    if (!mounted) return;
    setState(() {
      _checkingAssetIds.remove(asset.id);
      if (path == null) {
        _downloadedAssetPaths.remove(asset.id);
      } else {
        _downloadedAssetPaths[asset.id] = path;
      }
    });
  }

  Future<void> _selectRemoteAsset(EditorRemoteAsset asset) async {
    if (_downloadingAssetId != null) return;
    if (asset.kind == 'text') {
      Navigator.of(context).pop(asset.value);
      return;
    }
    final accessGranted = await widget.requestRemoteAssetAccess();
    if (!mounted || !accessGranted) return;
    final downloadedPath = _downloadedAssetPaths[asset.id];
    if (downloadedPath != null) {
      Navigator.of(context).pop(downloadedPath);
      return;
    }
    final existingPath = await widget.localAssetPath(asset);
    if (!mounted) return;
    if (existingPath != null) {
      _downloadedAssetPaths[asset.id] = existingPath;
      Navigator.of(context).pop(existingPath);
      return;
    }
    setState(() {
      _downloadingAssetId = asset.id;
      _downloadProgress = 0;
    });
    try {
      final path = await widget.downloadAsset(asset, (progress) {
        if (mounted) setState(() => _downloadProgress = progress);
      });
      if (!mounted) return;
      setState(() {
        _downloadedAssetPaths[asset.id] = path;
        _downloadingAssetId = null;
        _downloadProgress = 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _downloadingAssetId = null);
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: const Text('Asset download failed. Please try again.'),
        ),
      );
    }
  }

  Widget _buildRemoteAssetThumbnail(EditorRemoteAsset asset) {
    final thumbnailUrl = asset.thumbnailUrl;
    final lower = thumbnailUrl.toLowerCase();
    final isSvg =
        asset.extension == 'svg' ||
        Uri.tryParse(thumbnailUrl)?.path.toLowerCase().endsWith('.svg') ==
            true ||
        lower.contains('.svg?');
    if (isSvg) {
      return SvgPicture.network(
        thumbnailUrl,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
      cacheManager: PosterNetworkImageCache.instance,
      memCacheWidth: 384,
      memCacheHeight: 384,
      maxWidthDiskCache: 512,
      maxHeightDiskCache: 512,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      placeholder: (_, _) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      ),
      errorWidget: (_, _, _) =>
          const Icon(Icons.broken_image_outlined, color: Colors.white54),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stickers = widget.catalog[_selectedCategory] ?? const <String>[];
    final remoteAssets = _remoteAssets;
    final strings = context.strings;
    return EditorFullscreenOverlay(
      title: strings.localized(telugu: 'స్టికర్స్', english: 'Assets'),
      doneLabel: strings.localized(telugu: 'మూసివేయి', english: 'Close'),
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
                    onTap: () => _selectCategory(category),
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
                itemCount: stickers.length + remoteAssets.length,
                itemBuilder: (BuildContext context, int index) {
                  if (index >= stickers.length) {
                    final asset = remoteAssets[index - stickers.length];
                    final downloading = _downloadingAssetId == asset.id;
                    final downloaded = _downloadedAssetPaths.containsKey(
                      asset.id,
                    );
                    return _PressableSurface(
                      enabled: _downloadingAssetId == null,
                      onTap: () => _selectRemoteAsset(asset),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            if (asset.kind == 'text')
                              Center(
                                child: Text(
                                  asset.value,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    height: 1,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: _buildRemoteAssetThumbnail(asset),
                              ),
                            if (asset.kind != 'text')
                              Positioned(
                                right: 5,
                                bottom: 5,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: const Color(0xDD111827),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: downloading
                                      ? Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: CircularProgressIndicator(
                                            value: _downloadProgress > 0
                                                ? _downloadProgress
                                                : null,
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          downloaded
                                              ? Icons.add_rounded
                                              : Icons.download_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  final sticker = stickers[index];
                  final imageLike = _EditorTextState._isImageLikeSticker(
                    sticker,
                  );
                  return _PressableSurface(
                    onTap: () => Navigator.of(context).pop(sticker),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
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
    this.premium = false,
  });

  final String label;
  final IconData icon;
  final String? assetIcon;
  final VoidCallback onTap;
  final bool active;
  final bool compact;
  final bool premium;

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
        final displayLabel = icon == Icons.format_shapes_rounded
            ? 'Typography'
            : label;
        final iconSize = sideRailTile ? 30.0 : (compact ? 25.0 : 27.0);
        final baseIcon = SizedBox(
          width: iconSize,
          height: iconSize,
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
        final iconWidget = SizedBox(
          width: iconSize + (premium ? 12 : 0),
          height: iconSize + (premium ? 9 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(left: 0, bottom: 0, child: baseIcon),
              if (premium)
                const Positioned(
                  right: -3,
                  top: -3,
                  child: _EditorPremiumBadge(),
                ),
            ],
          ),
        );
        final labelWidget = Text(
          displayLabel,
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

class _EditorPremiumBadge extends StatelessWidget {
  const _EditorPremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFF3EA5),
            Color(0xFFB832FF),
            Color(0xFF6D28D9),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFFF3EA5).withValues(alpha: 0.38),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        size: 13,
        color: Colors.white,
      ),
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
          strings.localized(telugu: 'డ్రాఫ్ట్స్', english: 'Drafts'),
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
                      telugu: 'సేవ్ అవుతోంది...',
                      english: 'Saving...',
                    )
                  : strings.localized(
                      telugu: 'ప్రస్తుతాన్ని సేవ్ చేయి',
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
                      telugu: 'ఇంకా సేవ్ చేసిన డ్రాఫ్ట్స్ లేవు',
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
