part of '../image_editor_screen.dart';

class _TextStyleBar extends StatefulWidget {
  const _TextStyleBar({
    required this.visible,
    required this.selectedLayer,
    required this.textController,
    required this.textFocusNode,
    required this.colors,
    required this.backgroundColors,
    required this.gradients,
    required this.onEditTap,
    required this.onTextChanged,
    required this.onFontsTap,
    required this.onColorSelected,
    required this.onBackgroundColorSelected,
    required this.onAlignSelected,
    required this.onGradientSelected,
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
    required this.onBoldToggle,
    required this.onItalicToggle,
    required this.onUnderlineToggle,
    required this.onStrokeColorSelected,
    required this.onStrokeWidthChanged,
    required this.onStrokeWidthChangeStart,
    required this.onStrokeWidthChangeEnd,
  });

  final bool visible;
  final _CanvasLayer? selectedLayer;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final List<Color> colors;
  final List<Color> backgroundColors;
  final List<List<Color>> gradients;
  final VoidCallback onEditTap;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onFontsTap;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<Color> onBackgroundColorSelected;
  final ValueChanged<TextAlign> onAlignSelected;
  final ValueChanged<int> onGradientSelected;
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
  final VoidCallback onBoldToggle;
  final VoidCallback onItalicToggle;
  final VoidCallback onUnderlineToggle;
  final ValueChanged<Color> onStrokeColorSelected;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<double> onStrokeWidthChangeStart;
  final ValueChanged<double> onStrokeWidthChangeEnd;

  @override
  State<_TextStyleBar> createState() => _TextStyleBarState();
}

class _TextStyleBarState extends State<_TextStyleBar> {
  _TextToolTab _activeTab = _TextToolTab.style;

  @override
  Widget build(BuildContext context) {
    final layer = widget.selectedLayer;
    if (!widget.visible || layer == null) {
      return const SizedBox.shrink();
    }
    final strings = context.strings;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xE60F172A),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _TextQuickActionButton(
                  icon: Icons.edit_rounded,
                  label: strings.localized(
                    telugu: 'టెక్స్ట్ ఎడిట్',
                    english: 'Edit Text',
                  ),
                  onTap: widget.onEditTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TextQuickActionButton(
                  icon: Icons.font_download_rounded,
                  label: strings.localized(telugu: 'ఫాంట్స్', english: 'Fonts'),
                  onTap: widget.onFontsTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _TextTabChip(
                  label: strings.localized(telugu: 'స్టైల్', english: 'Style'),
                  selected: _activeTab == _TextToolTab.style,
                  onTap: () => setState(() => _activeTab = _TextToolTab.style),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TextTabChip(
                  label: strings.localized(
                    telugu: 'బ్యాక్‌గ్రౌండ్',
                    english: 'Background',
                  ),
                  selected: _activeTab == _TextToolTab.background,
                  onTap: () =>
                      setState(() => _activeTab = _TextToolTab.background),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TextTabChip(
                  label: strings.localized(telugu: 'ఎఫెక్ట్స్', english: 'Effects'),
                  selected: _activeTab == _TextToolTab.effects,
                  onTap: () =>
                      setState(() => _activeTab = _TextToolTab.effects),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: _buildActiveTab(layer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(_CanvasLayer layer) {
    return switch (_activeTab) {
      _TextToolTab.style => _buildStyleTab(layer),
      _TextToolTab.background => _buildBackgroundTab(layer),
      _TextToolTab.effects => _buildEffectsTab(layer),
    };
  }

  Widget _buildStyleTab(_CanvasLayer layer) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
            _AlignChip(
              icon: Icons.format_bold_rounded,
              selected: layer.isTextBold,
              onTap: widget.onBoldToggle,
            ),
            _AlignChip(
              icon: Icons.format_italic_rounded,
              selected: layer.isTextItalic,
              onTap: widget.onItalicToggle,
            ),
            _AlignChip(
              icon: Icons.format_underline_rounded,
              selected: layer.isTextUnderline,
              onTap: widget.onUnderlineToggle,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CompactLabeledSlider(
          sliderId: 'font-size',
          label: strings.localized(telugu: 'ఫాంట్ సైజ్', english: 'Font Size'),
          value: layer.fontSize.clamp(18, 96).toDouble(),
          min: 18,
          max: 96,
          valueText: layer.fontSize.toStringAsFixed(0),
          onChangeStart: widget.onFontSizeChangeStart,
          onChanged: widget.onFontSizeChanged,
          onChangeEnd: widget.onFontSizeChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'letter-spacing',
          label: strings.localized(
            telugu: 'అక్షరాల దూరం',
            english: 'Letter Spacing',
          ),
          value: layer.textLetterSpacing.clamp(-1, 12).toDouble(),
          min: -1,
          max: 12,
          valueText: layer.textLetterSpacing.toStringAsFixed(1),
          onChangeStart: widget.onLetterSpacingChangeStart,
          onChanged: widget.onLetterSpacingChanged,
          onChangeEnd: widget.onLetterSpacingChangeEnd,
        ),
        const SizedBox(height: 10),
        _buildSectionLabel(
          strings.localized(telugu: 'ఫిల్ కలర్స్', english: 'Fill Colors'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ...widget.colors.map(
              (Color color) => _ColorDot(
                color: color,
                selected:
                    layer.textGradientIndex == -1 &&
                    layer.textColor.toARGB32() == color.toARGB32(),
                onTap: () => widget.onColorSelected(color),
              ),
            ),
            ...List<Widget>.generate(
              widget.gradients.length,
              (int index) => _GradientDot(
                colors: widget.gradients[index],
                selected: layer.textGradientIndex == index,
                onTap: () => widget.onGradientSelected(index),
              ),
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
            telugu: 'బ్యాక్‌గ్రౌండ్ అపాసిటీ',
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
            telugu: 'కోణాల రేడియస్',
            english: 'Corner Radius',
          ),
          value: layer.textBackgroundRadius.clamp(0, 40).toDouble(),
          min: 0,
          max: 40,
          valueText: layer.textBackgroundRadius.toStringAsFixed(0),
          onChangeStart: widget.onBackgroundRadiusChangeStart,
          onChanged: widget.onBackgroundRadiusChanged,
          onChangeEnd: widget.onBackgroundRadiusChangeEnd,
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

  Widget _buildEffectsTab(_CanvasLayer layer) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CompactLabeledSlider(
          sliderId: 'text-opacity',
          label: strings.localized(
            telugu: 'టెక్స్ట్ అపాసిటీ',
            english: 'Text Opacity',
          ),
          value: layer.textOpacity.clamp(0.15, 1).toDouble(),
          min: 0.15,
          max: 1,
          valueText: layer.textOpacity.toStringAsFixed(2),
          onChangeStart: widget.onShadowOpacityChangeStart,
          onChanged: widget.onTextOpacityChanged,
          onChangeEnd: widget.onShadowOpacityChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'stroke-width',
          label: strings.localized(
            telugu: 'స్ట్రోక్ వెడల్పు',
            english: 'Stroke Width',
          ),
          value: layer.textStrokeWidth.clamp(0, 8).toDouble(),
          min: 0,
          max: 8,
          valueText: layer.textStrokeWidth.toStringAsFixed(1),
          onChangeStart: widget.onStrokeWidthChangeStart,
          onChanged: widget.onStrokeWidthChanged,
          onChangeEnd: widget.onStrokeWidthChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'shadow-opacity',
          label: strings.localized(
            telugu: 'షాడో అపాసిటీ',
            english: 'Shadow Opacity',
          ),
          value: layer.textShadowOpacity.clamp(0, 1).toDouble(),
          min: 0,
          max: 1,
          valueText: layer.textShadowOpacity.toStringAsFixed(2),
          onChangeStart: widget.onShadowOpacityChangeStart,
          onChanged: widget.onShadowOpacityChanged,
          onChangeEnd: widget.onShadowOpacityChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'shadow-blur',
          label: strings.localized(
            telugu: 'షాడో బ్లర్',
            english: 'Shadow Blur',
          ),
          value: layer.textShadowBlur.clamp(0, 24).toDouble(),
          min: 0,
          max: 24,
          valueText: layer.textShadowBlur.toStringAsFixed(0),
          onChangeStart: widget.onShadowBlurChangeStart,
          onChanged: widget.onShadowBlurChanged,
          onChangeEnd: widget.onShadowBlurChangeEnd,
        ),
        const SizedBox(height: 8),
        _CompactLabeledSlider(
          sliderId: 'shadow-offset',
          label: strings.localized(
            telugu: 'షాడో ఆఫ్‌సెట్ Y',
            english: 'Shadow Offset Y',
          ),
          value: layer.textShadowOffsetY.clamp(0, 20).toDouble(),
          min: 0,
          max: 20,
          valueText: layer.textShadowOffsetY.toStringAsFixed(0),
          onChangeStart: widget.onShadowOffsetYChangeStart,
          onChanged: widget.onShadowOffsetYChanged,
          onChangeEnd: widget.onShadowOffsetYChangeEnd,
        ),
        const SizedBox(height: 10),
        _buildSectionLabel(
          strings.localized(telugu: 'స్ట్రోక్ కలర్', english: 'Stroke Color'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.colors
              .map(
                (Color color) => _ColorDot(
                  color: color,
                  selected:
                      layer.textStrokeColor.toARGB32() == color.toARGB32(),
                  onTap: () => widget.onStrokeColorSelected(color),
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

class _TextQuickActionButton extends StatelessWidget {
  const _TextQuickActionButton({
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
  });

  final String sliderId;
  final String label;
  final double value;
  final double min;
  final double max;
  final String? valueText;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
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
                valueText ?? value.toStringAsFixed(2),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: const Color(0xFFE2E8F0),
              overlayColor: const Color(0x333B82F6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChangeStart: onChangeStart,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
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

class _TextTabChip extends StatelessWidget {
  const _TextTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
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
    required this.onSelectLayer,
    required this.onDeleteLayer,
    required this.onToggleLayerLock,
    required this.onToggleLayerVisibility,
    required this.onReorderLayers,
    required this.onMoveToFront,
    required this.onMoveToBack,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final ValueChanged<String> onSelectLayer;
  final ValueChanged<String> onDeleteLayer;
  final ValueChanged<String> onToggleLayerLock;
  final ValueChanged<String> onToggleLayerVisibility;
  final void Function(int oldIndex, int newIndex) onReorderLayers;
  final ValueChanged<String> onMoveToFront;
  final ValueChanged<String> onMoveToBack;

  @override
  State<_AdvancedLayersFullscreenOverlay> createState() =>
      _AdvancedLayersFullscreenOverlayState();
}

class _AdvancedLayersFullscreenOverlayState
    extends State<_AdvancedLayersFullscreenOverlay> {
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return EditorFullscreenOverlay(
      title: strings.localized(telugu: 'లేయర్స్', english: 'Layers'),
      onDone: () => Navigator.of(context).pop(),
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (widget.selectedLayerId != null) ...<Widget>[
                  _LayerActionButton(
                    icon: Icons.vertical_align_top_rounded,
                    label: strings.localized(telugu: 'ఫ్రంట్', english: 'Front'),
                    onTap: () => widget.onMoveToFront(widget.selectedLayerId!),
                  ),
                  _LayerActionButton(
                    icon: Icons.vertical_align_bottom_rounded,
                    label: strings.localized(telugu: 'బ్యాక్', english: 'Back'),
                    onTap: () => widget.onMoveToBack(widget.selectedLayerId!),
                  ),
                  _LayerActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: strings.localized(telugu: 'డిలీట్', english: 'Delete'),
                    onTap: () => widget.onDeleteLayer(widget.selectedLayerId!),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              itemCount: widget.layers.length,
              onReorder: widget.onReorderLayers,
              buildDefaultDragHandles: false,
              itemBuilder: (BuildContext context, int index) {
                final layer = widget.layers[index];
                final selected = layer.id == widget.selectedLayerId;
                return Container(
                  key: ValueKey<String>(layer.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF60A5FA)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      widget.onSelectLayer(layer.id);
                      setState(() {});
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: _buildLayerPreview(layer),
                    title: Text(
                      _layerTitle(layer),
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      selected ? 'Selected' : 'Tap to select',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          onPressed: () =>
                              widget.onToggleLayerVisibility(layer.id),
                          icon: Icon(
                            layer.isHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        IconButton(
                          onPressed: () => widget.onToggleLayerLock(layer.id),
                          icon: Icon(
                            layer.isLocked
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
        ),
      ),
    );
  }

  String _layerTitle(_CanvasLayer layer) {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xE6101726),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            if (detail != null && detail!.isNotEmpty)
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
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
  });

  final List<String> categories;
  final Map<String, List<String>> catalog;

  @override
  State<StickerBrowserFullscreenOverlay> createState() =>
      _StickerBrowserFullscreenOverlayState();
}

class _StickerBrowserFullscreenOverlayState
    extends State<StickerBrowserFullscreenOverlay> {
  late String _selectedCategory = widget.categories.first;

  @override
  Widget build(BuildContext context) {
    final stickers = widget.catalog[_selectedCategory] ?? const <String>[];
    final strings = context.strings;
    return EditorFullscreenOverlay(
      title: strings.localized(telugu: 'స్టికర్స్', english: 'Stickers'),
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
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 38.0;
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
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            icon,
            size: compact ? 16 : 18,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      enabled: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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
    this.active = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: compact ? 8 : 9, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: compact ? 17 : 18, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFE2E8F0),
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: Text(strings.localized(telugu: 'డ్రాఫ్ట్స్', english: 'Drafts')),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _saveCurrentDraft,
            child: Text(
              _saving
                  ? strings.localized(telugu: 'సేవ్ అవుతోంది...', english: 'Saving...')
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
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
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
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _openDraft(file),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        modified.toLocal().toString(),
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      trailing: IconButton(
                        onPressed: () => _deleteDraft(file),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFE2E8F0),
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
