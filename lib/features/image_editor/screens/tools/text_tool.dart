part of '../image_editor_screen.dart';

// ignore_for_file: unused_element

class _TextEditResult {
  const _TextEditResult({
    required this.text,
    required this.textColor,
    required this.textGradientIndex,
    required this.fontFamily,
    required this.fontSize,
    required this.textLineHeight,
    required this.textLetterSpacing,
    required this.textAlign,
    required this.textShadowOpacity,
    required this.textShadowBlur,
    required this.textShadowOffsetY,
    required this.textOpacity,
    required this.isTextBold,
    required this.isTextItalic,
    required this.isTextUnderline,
    required this.textStrokeColor,
    required this.textStrokeWidth,
    required this.textStrokeGradientIndex,
  });

  final String text;
  final Color textColor;
  final int textGradientIndex;
  final String fontFamily;
  final double fontSize;
  final double textLineHeight;
  final double textLetterSpacing;
  final TextAlign textAlign;
  final double textShadowOpacity;
  final double textShadowBlur;
  final double textShadowOffsetY;
  final double textOpacity;
  final bool isTextBold;
  final bool isTextItalic;
  final bool isTextUnderline;
  final Color textStrokeColor;
  final double textStrokeWidth;
  final int textStrokeGradientIndex;
}

class _TextColorSelection {
  const _TextColorSelection({
    required this.textColor,
    required this.textGradientIndex,
  });

  final Color textColor;
  final int textGradientIndex;
}

enum _TextEditorTab { text, colors, gradient, font }

enum _TextPaintTarget { fill, stroke }

class TextEditorFullscreenOverlay extends StatefulWidget {
  const TextEditorFullscreenOverlay({
    super.key,
    required this.initialText,
    required this.fontFamily,
    required this.textColor,
    required this.textGradientIndex,
    required this.textOpacity,
    required this.fontSize,
    required this.textLineHeight,
    required this.textLetterSpacing,
    required this.textAlign,
    required this.textShadowOpacity,
    required this.textShadowBlur,
    required this.textShadowOffsetY,
    required this.isTextBold,
    required this.isTextItalic,
    required this.isTextUnderline,
    required this.textStrokeColor,
    required this.textStrokeWidth,
    required this.textStrokeGradientIndex,
    required this.textBackgroundColor,
    required this.textBackgroundOpacity,
    required this.textBackgroundRadius,
    required this.colors,
    required this.gradients,
    required this.fontFamilies,
  });

  final String initialText;
  final String fontFamily;
  final Color textColor;
  final int textGradientIndex;
  final double textOpacity;
  final double fontSize;
  final double textLineHeight;
  final double textLetterSpacing;
  final TextAlign textAlign;
  final double textShadowOpacity;
  final double textShadowBlur;
  final double textShadowOffsetY;
  final bool isTextBold;
  final bool isTextItalic;
  final bool isTextUnderline;
  final Color textStrokeColor;
  final double textStrokeWidth;
  final int textStrokeGradientIndex;
  final Color textBackgroundColor;
  final double textBackgroundOpacity;
  final double textBackgroundRadius;
  final List<Color> colors;
  final List<List<Color>> gradients;
  final List<String> fontFamilies;

  @override
  State<TextEditorFullscreenOverlay> createState() =>
      _TextEditorFullscreenOverlayState();
}

class _TextEditorFullscreenOverlayState
    extends State<TextEditorFullscreenOverlay> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  late final FocusNode _inputFocusNode = FocusNode();

  late Color _selectedColor = widget.textColor;
  late int _selectedGradientIndex = widget.textGradientIndex;
  late String _selectedFontFamily = widget.fontFamily;
  late double _fontSize = widget.fontSize.clamp(18, 96).toDouble();
  late final double _lineHeight = widget.textLineHeight
      .clamp(0.8, 2.2)
      .toDouble();
  late double _letterSpacing = widget.textLetterSpacing
      .clamp(-1, 12)
      .toDouble();
  late TextAlign _textAlign = widget.textAlign;
  late bool _shadowEnabled = widget.textShadowOpacity > 0.001;
  late double _shadowOpacity = widget.textShadowOpacity.clamp(0, 1).toDouble();
  late double _shadowBlur = widget.textShadowBlur.clamp(0, 24).toDouble();
  late double _shadowOffsetY = widget.textShadowOffsetY.clamp(0, 20).toDouble();
  late double _textOpacity = widget.textOpacity.clamp(0.15, 1).toDouble();
  late bool _isTextBold = widget.isTextBold;
  late bool _isTextItalic = widget.isTextItalic;
  late bool _isTextUnderline = widget.isTextUnderline;
  late Color _strokeColor = widget.textStrokeColor;
  late double _strokeWidth = widget.textStrokeWidth.clamp(0, 8).toDouble();
  late int _strokeGradientIndex = widget.textStrokeGradientIndex;
  Timer? _legacyPreviewDebounce;
  int _legacyPreviewRevision = 0;
  String? _legacyPreviewText;
  _TextPaintTarget _paintTarget = _TextPaintTarget.fill;
  _TextEditorTab _activeTab = _TextEditorTab.text;

  List<Color>? get _activeGradient =>
      _selectedGradientIndex >= 0 &&
          _selectedGradientIndex < widget.gradients.length
      ? widget.gradients[_selectedGradientIndex]
      : null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handlePreviewSourceChanged);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _scheduleLegacyPreviewRefresh();
  }

  @override
  void dispose() {
    _legacyPreviewDebounce?.cancel();
    _controller.removeListener(_handlePreviewSourceChanged);
    _inputFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handlePreviewSourceChanged() {
    _scheduleLegacyPreviewRefresh();
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleLegacyPreviewRefresh() {
    _legacyPreviewDebounce?.cancel();
    final text = _controller.text;
    final fontFamily = _selectedFontFamily;
    if (!_isLegacyTeluguFontFamily(fontFamily) || text.trim().isEmpty) {
      if (_legacyPreviewText != null && mounted) {
        setState(() {
          _legacyPreviewText = null;
        });
      } else {
        _legacyPreviewText = null;
      }
      return;
    }
    final revision = ++_legacyPreviewRevision;
    _legacyPreviewDebounce = Timer(const Duration(milliseconds: 260), () async {
      final converted = await _resolveLegacyRenderTextFor(
        text: text,
        fontFamily: fontFamily,
      );
      if (!mounted ||
          revision != _legacyPreviewRevision ||
          _selectedFontFamily != fontFamily ||
          _controller.text != text) {
        return;
      }
      setState(() {
        _legacyPreviewText = converted;
      });
    });
  }

  void _saveAndClose() {
    Navigator.of(context).pop(
      _TextEditResult(
        text: _controller.text,
        textColor: _selectedColor,
        textGradientIndex: _selectedGradientIndex,
        fontFamily: _selectedFontFamily,
        fontSize: _fontSize.clamp(18, 96).toDouble(),
        textLineHeight: _lineHeight.clamp(0.8, 2.2).toDouble(),
        textLetterSpacing: _letterSpacing.clamp(-1, 12).toDouble(),
        textAlign: _textAlign,
        textShadowOpacity: _shadowEnabled
            ? _shadowOpacity.clamp(0, 1).toDouble()
            : 0,
        textShadowBlur: _shadowBlur.clamp(0, 24).toDouble(),
        textShadowOffsetY: _shadowOffsetY.clamp(0, 20).toDouble(),
        textOpacity: _textOpacity.clamp(0.15, 1).toDouble(),
        isTextBold: _isTextBold,
        isTextItalic: _isTextItalic,
        isTextUnderline: _isTextUnderline,
        textStrokeColor: _strokeColor,
        textStrokeWidth: _strokeWidth.clamp(0, 8).toDouble(),
        textStrokeGradientIndex: _strokeGradientIndex,
      ),
    );
  }

  Widget _buildRowLabel(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildControlRow({
    required String label,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[_buildRowLabel(label), child],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return _buildControlRow(
      label: label,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 46,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
              ),
              child: Slider(
                value: value.clamp(min, max).toDouble(),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignAndEffectsRow(BuildContext context) {
    final strings = context.strings;
    Widget alignmentButton({
      required IconData icon,
      required TextAlign align,
      required String tooltip,
    }) {
      final selected = _textAlign == align;
      return Tooltip(
        message: tooltip,
        child: _PressableSurface(
          onTap: () => setState(() {
            _textAlign = align;
          }),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.62)
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: selected ? 0.98 : 0.72),
              size: 18,
            ),
          ),
        ),
      );
    }

    return _buildControlRow(
      label: strings.localized(
        telugu: 'అలైన్‌మెంట్ & షాడో',
        english: 'Alignment & Shadow',
      ),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            alignmentButton(
              icon: Icons.format_align_left_rounded,
              align: TextAlign.left,
              tooltip: strings.localized(telugu: 'ఎడమ', english: 'Left'),
            ),
            const SizedBox(width: 8),
            alignmentButton(
              icon: Icons.format_align_center_rounded,
              align: TextAlign.center,
              tooltip: strings.localized(telugu: 'మధ్య', english: 'Center'),
            ),
            const SizedBox(width: 8),
            alignmentButton(
              icon: Icons.format_align_right_rounded,
              align: TextAlign.right,
              tooltip: strings.localized(telugu: 'కుడి', english: 'Right'),
            ),
            const SizedBox(width: 14),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    strings.localized(telugu: 'షాడో', english: 'Shadow'),
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: _shadowEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _shadowEnabled = value;
                        if (_shadowEnabled && _shadowOpacity <= 0.001) {
                          _shadowOpacity = 0.35;
                          _shadowBlur = _shadowBlur <= 0.1 ? 8 : _shadowBlur;
                          _shadowOffsetY = _shadowOffsetY <= 0.1
                              ? 3
                              : _shadowOffsetY;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(_TextEditorTab tab, String label) {
    final selected = _activeTab == tab;
    return SizedBox(
      width: 92,
      child: _PressableSurface(
        onTap: () {
          if (tab == _TextEditorTab.font) {
            unawaited(_openFontOverlay());
            return;
          }
          setState(() {
            _activeTab = tab;
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: selected ? 0.96 : 0.75),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFontOverlay() async {
    final previewText = _controller.text.trim().isEmpty
        ? 'తెలుగు Poster Title'
        : _controller.text.trim();
    final selected = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return TextFontFullscreenOverlay(
                selectedFontFamily: _selectedFontFamily,
                teluguFonts: widget.fontFamilies,
                englishFonts: _englishTextFontFamilies,
                previewText: previewText,
              );
            },
      ),
    );
    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }
    setState(() {
      _selectedFontFamily = selected;
    });
    _scheduleLegacyPreviewRefresh();
  }

  Widget _buildTextTab() {
    final strings = context.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildSliderRow(
          label: strings.localized(telugu: 'ఫాంట్ సైజ్', english: 'Font Size'),
          valueText: _fontSize.toStringAsFixed(0),
          value: _fontSize,
          min: 18,
          max: 96,
          onChanged: (double value) {
            setState(() {
              _fontSize = value;
            });
          },
        ),
        _buildSliderRow(
          label: strings.localized(
            telugu: 'అక్షరాల అంతరం',
            english: 'Letter Spacing',
          ),
          valueText: _letterSpacing.toStringAsFixed(1),
          value: _letterSpacing,
          min: -1,
          max: 12,
          onChanged: (double value) {
            setState(() {
              _letterSpacing = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLivePreviewText(String text, double maxWidth) {
    final previewText = text.isEmpty
        ? context.strings.localized(
            telugu: 'ఇక్కడ టెక్స్ట్ టైప్ చేయండి',
            english: 'Type text here',
          )
        : text;
    final renderText = text.isEmpty
        ? previewText
        : (_legacyPreviewText ??
              _resolveTextRenderValue(
                text: previewText,
                fontFamily: _selectedFontFamily,
              ));
    final previewOpacity = text.isEmpty
        ? 0.52
        : _textOpacity.clamp(0.15, 1).toDouble();
    final previewColor = text.isEmpty
        ? Colors.white
        : (_activeGradient == null && _selectedColor.computeLuminance() < 0.25
              ? Colors.white
              : _selectedColor);
    final previewGradient = text.isEmpty ? null : _activeGradient;
    final previewStrokeWidth = text.isEmpty ? 0.0 : _strokeWidth;
    final previewStrokeGradient = text.isEmpty
        ? null
        : (_strokeGradientIndex >= 0 &&
                  _strokeGradientIndex < widget.gradients.length
              ? widget.gradients[_strokeGradientIndex]
              : null);
    final previewNeedsLift =
        text.isNotEmpty &&
        previewGradient == null &&
        _selectedColor.computeLuminance() < 0.18;

    return Align(
      alignment: switch (_textAlign) {
        TextAlign.left ||
        TextAlign.start ||
        TextAlign.justify => Alignment.centerLeft,
        TextAlign.right || TextAlign.end => Alignment.centerRight,
        TextAlign.center => Alignment.center,
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _CanvasTextLayerView(
          text: renderText,
          textColor: previewColor,
          textAlign: _textAlign,
          fontSize: _fontSize.clamp(18, 96).toDouble(),
          textOpacity: previewOpacity,
          fontFamily: _resolveTextRenderFontFamily(_selectedFontFamily),
          textLineHeight: _lineHeight,
          textLetterSpacing: _letterSpacing,
          textShadowOpacity: _shadowEnabled ? _shadowOpacity : 0.0,
          textShadowBlur: _shadowBlur,
          textShadowOffsetY: _shadowOffsetY,
          isTextBold: _isTextBold,
          isTextItalic: _isTextItalic,
          isTextUnderline: _isTextUnderline,
          textStrokeColor: _strokeColor,
          textStrokeWidth: previewStrokeWidth,
          textStrokeGradient: previewStrokeGradient,
          textBackgroundColor: widget.textBackgroundColor,
          textBackgroundOpacity: widget.textBackgroundOpacity,
          textBackgroundRadius: widget.textBackgroundRadius,
          textGradient: previewGradient,
          editorAssistShadowColor: previewNeedsLift
              ? Colors.white.withValues(alpha: 0.55)
              : null,
          editorAssistShadowBlur: previewNeedsLift ? 10 : 0,
        ),
      ),
    );
  }

  double _measureEditableTextWidth(double maxWidth) {
    final sampleText = _controller.text.isEmpty
        ? context.strings.localized(
            telugu: 'ఇక్కడ టెక్స్ట్ టైప్ చేయండి',
            english: 'Type text here',
          )
        : _controller.text;
    final painter = TextPainter(
      text: TextSpan(
        text: sampleText,
        style: TextStyle(
          fontSize: _fontSize.clamp(18, 96).toDouble(),
          height: _lineHeight,
          letterSpacing: _letterSpacing,
          fontFamily: _resolveTextRenderFontFamily(_selectedFontFamily),
          fontWeight: _isTextBold ? FontWeight.w700 : FontWeight.w500,
          fontStyle: _isTextItalic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      textAlign: _textAlign,
      textDirection: TextDirection.ltr,
      maxLines: 8,
    )..layout(maxWidth: maxWidth);
    return (painter.width + 20).clamp(72.0, maxWidth).toDouble();
  }

  Widget _buildColorsTab() {
    final colors = widget.colors.take(50).toList(growable: false);
    return SizedBox(
      height: 88,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: colors.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemBuilder: (BuildContext context, int index) {
          final color = colors[index];
          final selected = _paintTarget == _TextPaintTarget.fill
              ? (_selectedGradientIndex == -1 &&
                    _selectedColor.toARGB32() == color.toARGB32())
              : (_strokeGradientIndex == -1 &&
                    _strokeColor.toARGB32() == color.toARGB32());
          return _PressableSurface(
            onTap: () {
              setState(() {
                if (_paintTarget == _TextPaintTarget.fill) {
                  _selectedColor = color;
                  _selectedGradientIndex = -1;
                } else {
                  _strokeColor = color;
                  _strokeGradientIndex = -1;
                  if (_strokeWidth < 0.5) {
                    _strokeWidth = 1;
                  }
                }
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 2.2 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientTab() {
    final gradients = widget.gradients.take(50).toList(growable: false);
    return SizedBox(
      height: 92,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: gradients.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.8,
        ),
        itemBuilder: (BuildContext context, int index) {
          final selected = _paintTarget == _TextPaintTarget.fill
              ? _selectedGradientIndex == index
              : _strokeGradientIndex == index;
          return _PressableSurface(
            onTap: () {
              setState(() {
                if (_paintTarget == _TextPaintTarget.fill) {
                  _selectedGradientIndex = index;
                } else {
                  _strokeGradientIndex = index;
                  if (_strokeWidth < 0.5) {
                    _strokeWidth = 1;
                  }
                }
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradients[index]),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.62)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 0.96 : 0.72),
            fontWeight: FontWeight.w700,
            fontStyle: label == 'I' ? FontStyle.italic : FontStyle.normal,
            decoration: label == 'U'
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStyleTab() {
    final strings = context.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildSliderRow(
          label: strings.localized(telugu: 'ఒపాసిటీ', english: 'Opacity'),
          valueText: _textOpacity.toStringAsFixed(2),
          value: _textOpacity,
          min: 0.15,
          max: 1,
          onChanged: (double value) {
            setState(() {
              _textOpacity = value;
            });
          },
        ),
        _buildAlignAndEffectsRow(context),
        _buildControlRow(
          label: strings.localized(
            telugu: 'పెయింట్ టార్గెట్',
            english: 'Paint Target',
          ),
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Row(
            children: <Widget>[
              _buildPaintTargetButton(
                label: strings.localized(telugu: 'ఫిల్', english: 'Fill'),
                selected: _paintTarget == _TextPaintTarget.fill,
                onTap: () => setState(() {
                  _paintTarget = _TextPaintTarget.fill;
                }),
              ),
              const SizedBox(width: 8),
              _buildPaintTargetButton(
                label: strings.localized(telugu: 'స్ట్రోక్', english: 'Stroke'),
                selected: _paintTarget == _TextPaintTarget.stroke,
                onTap: () => setState(() {
                  _paintTarget = _TextPaintTarget.stroke;
                }),
              ),
            ],
          ),
        ),
        _buildSliderRow(
          label: strings.localized(
            telugu: 'స్ట్రోక్ వెడల్పు',
            english: 'Stroke Width',
          ),
          valueText: _strokeWidth.toStringAsFixed(1),
          value: _strokeWidth,
          min: 0,
          max: 8,
          onChanged: (double value) {
            setState(() {
              _strokeWidth = value;
              if (_strokeWidth > 0.01 && _strokeGradientIndex >= 0) {
                _strokeColor = const Color(0xFFFFFFFF);
              }
            });
          },
        ),
        _buildControlRow(
          label: strings.localized(
            telugu: 'టెక్స్ట్ స్టైల్',
            english: 'Text Style',
          ),
          padding: EdgeInsets.zero,
          child: Row(
            children: <Widget>[
              _buildStyleToggle(
                label: 'B',
                selected: _isTextBold,
                onTap: () => setState(() {
                  _isTextBold = !_isTextBold;
                }),
              ),
              const SizedBox(width: 8),
              _buildStyleToggle(
                label: 'I',
                selected: _isTextItalic,
                onTap: () => setState(() {
                  _isTextItalic = !_isTextItalic;
                }),
              ),
              const SizedBox(width: 8),
              _buildStyleToggle(
                label: 'U',
                selected: _isTextUnderline,
                onTap: () => setState(() {
                  _isTextUnderline = !_isTextUnderline;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaintTargetButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.56)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 0.98 : 0.74),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case _TextEditorTab.text:
        return _buildTextTab();
      case _TextEditorTab.colors:
        return _buildColorsTab();
      case _TextEditorTab.gradient:
        return _buildGradientTab();
      case _TextEditorTab.font:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final screenSize = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: EditorFullscreenOverlay(
        title: context.strings.localized(telugu: 'టెక్స్ట్', english: 'Text'),
        onBack: () {
          Navigator.of(context).pop();
        },
        onDone: _saveAndClose,
        bottom: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white.withValues(alpha: 0.03),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      _buildTabButton(_TextEditorTab.text, 'Text'),
                      const SizedBox(width: 6),
                      _buildTabButton(_TextEditorTab.colors, 'Colors'),
                      const SizedBox(width: 6),
                      _buildTabButton(_TextEditorTab.gradient, 'Gradient'),
                      const SizedBox(width: 6),
                      _buildTabButton(_TextEditorTab.font, 'Font'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey<String>(_activeTab.name),
                    child: _buildTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenSize.width * 0.9,
                      ),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, Widget? child) {
                          final editableWidth = _measureEditableTextWidth(
                            screenSize.width * 0.9,
                          );
                          return Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              IgnorePointer(
                                child: _buildLivePreviewText(
                                  _controller.text,
                                  screenSize.width * 0.9,
                                ),
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  textSelectionTheme:
                                      const TextSelectionThemeData(
                                        selectionColor: Colors.transparent,
                                        selectionHandleColor: Colors.white,
                                        cursorColor: Colors.transparent,
                                      ),
                                ),
                                child: SizedBox(
                                  width: editableWidth,
                                  child: EditableText(
                                    controller: _controller,
                                    focusNode: _inputFocusNode,
                                    autofocus: true,
                                    minLines: 1,
                                    maxLines: 8,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    keyboardAppearance: Brightness.dark,
                                    textAlign: _textAlign,
                                    enableInteractiveSelection: false,
                                    enableSuggestions: true,
                                    autocorrect: true,
                                    showCursor: false,
                                    cursorWidth: 0,
                                    style: TextStyle(
                                      color: Colors.transparent,
                                      fontSize: _fontSize.clamp(18, 96),
                                      height: _lineHeight,
                                      letterSpacing: _letterSpacing,
                                      fontFamily: _resolveTextRenderFontFamily(
                                        _selectedFontFamily,
                                      ),
                                      fontWeight: _isTextBold
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontStyle: _isTextItalic
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      decoration: TextDecoration.none,
                                    ),
                                    cursorColor: Colors.transparent,
                                    backgroundCursorColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: 0.96,
                  child: Text(
                    'Style controls are now in the text subtool panel after selecting text on canvas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextColorPickerScreen extends StatefulWidget {
  const _TextColorPickerScreen({
    required this.colors,
    required this.gradients,
    required this.selectedColor,
    required this.selectedGradientIndex,
  });

  final List<Color> colors;
  final List<List<Color>> gradients;
  final Color selectedColor;
  final int selectedGradientIndex;

  @override
  State<_TextColorPickerScreen> createState() => _TextColorPickerScreenState();
}

class TextFontFullscreenOverlay extends StatefulWidget {
  const TextFontFullscreenOverlay({
    super.key,
    required this.selectedFontFamily,
    required this.teluguFonts,
    required this.englishFonts,
    required this.previewText,
  });

  final String selectedFontFamily;
  final List<String> teluguFonts;
  final List<String> englishFonts;
  final String previewText;

  @override
  State<TextFontFullscreenOverlay> createState() =>
      _TextFontFullscreenOverlayState();
}

class _TextFontFullscreenOverlayState extends State<TextFontFullscreenOverlay> {
  static const String _favoriteFontsStorageKey =
      'editor_font_picker_favorites_v1';
  static const String _recentFontsStorageKey = 'editor_font_picker_recent_v1';
  static const int _maxRecentFonts = 8;
  late final TextEditingController _searchController = TextEditingController();
  late String _selectedFont = widget.selectedFontFamily;
  final Set<String> _favoriteFonts = <String>{};
  final List<String> _recentFonts = <String>[];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    unawaited(_loadFavoriteFonts());
    unawaited(_loadRecentFonts());
    unawaited(_primeLegacyCacheState());
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _primeLegacyCacheState() async {
    await _ensureLegacyConversionCacheLoaded();
    unawaited(
      _prewarmLegacyFontsForText(
        widget.previewText,
        preferredFamilies: _favoriteFonts,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadFavoriteFonts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_favoriteFontsStorageKey)?.toSet() ?? <String>{};
    if (!mounted) {
      return;
    }
    setState(() {
      _favoriteFonts
        ..clear()
        ..addAll(
          stored.where((String family) => widget.teluguFonts.contains(family)),
        );
    });
    unawaited(
      _prewarmLegacyFontsForText(
        widget.previewText,
        preferredFamilies: _favoriteFonts,
      ),
    );
  }

  Future<void> _loadRecentFonts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_recentFontsStorageKey) ?? <String>[];
    final validFonts = <String>{...widget.teluguFonts, ...widget.englishFonts};
    if (!mounted) {
      return;
    }
    setState(() {
      _recentFonts
        ..clear()
        ..addAll(
          stored
              .where(validFonts.contains)
              .take(_maxRecentFonts)
              .toList(growable: false),
        );
    });
  }

  Future<void> _toggleFavoriteFont(String family) async {
    final nextFavorites = Set<String>.from(_favoriteFonts);
    if (!nextFavorites.add(family)) {
      nextFavorites.remove(family);
    }
    setState(() {
      _favoriteFonts
        ..clear()
        ..addAll(nextFavorites);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoriteFontsStorageKey,
      nextFavorites.toList()..sort(),
    );
  }

  Future<void> _rememberRecentFont(String family) async {
    final nextRecent = <String>[
      family,
      ..._recentFonts.where((String item) => item != family),
    ].take(_maxRecentFonts).toList(growable: false);
    if (mounted) {
      setState(() {
        _recentFonts
          ..clear()
          ..addAll(nextRecent);
      });
    } else {
      _recentFonts
        ..clear()
        ..addAll(nextRecent);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentFontsStorageKey, nextRecent);
  }

  List<String> _filteredFonts(List<String> source) {
    if (_query.isEmpty) {
      return source;
    }
    return source
        .where((String font) => font.toLowerCase().contains(_query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final teluguFonts = _filteredFonts(widget.teluguFonts);
    final recentFonts = _query.isEmpty
        ? _recentFonts
              .where(
                (String family) =>
                    teluguFonts.contains(family) ||
                    widget.englishFonts.contains(family),
              )
              .toList(growable: false)
        : _filteredFonts(_recentFonts);
    final favoriteFonts = teluguFonts
        .where((String family) => _favoriteFonts.contains(family))
        .toList(growable: false);
    final unicodeTeluguFonts = teluguFonts
        .where(
          (String family) =>
              _unicodeTeluguFontFamilies.contains(family) &&
              !_favoriteFonts.contains(family) &&
              !recentFonts.contains(family),
        )
        .toList(growable: false);
    final legacyTeluguFonts = teluguFonts
        .where(
          (String family) =>
              _isLegacyTeluguFontFamily(family) &&
              !_favoriteFonts.contains(family) &&
              !recentFonts.contains(family),
        )
        .toList(growable: false);
    final englishFonts = _filteredFonts(widget.englishFonts)
        .where((String family) => !recentFonts.contains(family))
        .toList(growable: false);
    return Material(
      color: Colors.transparent,
      child: EditorFullscreenOverlay(
        title: context.strings.localized(telugu: 'ఫాంట్స్', english: 'Fonts'),
        onBack: () => Navigator.of(context).pop(),
        onDone: () => Navigator.of(context).pop(_selectedFont),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search font',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      prefixIconColor: const Color(0xFFCBD5E1),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    widget.previewText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      fontFamily: _resolveTextRenderFontFamily(_selectedFont),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      if (recentFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Recent'),
                        ...recentFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      if (favoriteFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Favorites'),
                        ...favoriteFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      if (unicodeTeluguFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Unicode Telugu'),
                        ...unicodeTeluguFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      if (legacyTeluguFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Legacy Telugu'),
                        ...legacyTeluguFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      _buildSectionLabel('English Fonts'),
                      ...englishFonts.map(_buildFontRow),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildFontRow(String family) {
    final selected = family == _selectedFont;
    final cachedReady = _hasCachedLegacyRenderText(
      text: widget.previewText,
      fontFamily: family,
    );
    final isFavorite = _favoriteFonts.contains(family);
    return _PressableSurface(
      onTap: () {
        setState(() {
          _selectedFont = family;
        });
        unawaited(_rememberRecentFont(family));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Aa తెలుగు  $family',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _resolveTextRenderFontFamily(family),
                  fontSize: 17,
                  height: 1.1,
                  color: Colors.white.withValues(alpha: selected ? 0.98 : 0.82),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (_fontPickerSecondaryLabel(family).isNotEmpty)
              Text(
                _fontPickerSecondaryLabel(family),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (cachedReady) ...<Widget>[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Text(
                  'Ready',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            _PressableSurface(
              onTap: () => unawaited(_toggleFavoriteFont(family)),
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 26,
                height: 26,
                child: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 17,
                  color: isFavorite
                      ? const Color(0xFFFACC15)
                      : Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF93C5FD),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextColorPickerScreenState extends State<_TextColorPickerScreen> {
  late Color _selectedColor = widget.selectedColor;
  late int _selectedGradientIndex = widget.selectedGradientIndex;

  @override
  Widget build(BuildContext context) {
    return EditorFullscreenOverlay(
      title: context.strings.localized(
        telugu: 'టెక్స్ట్ కలర్స్',
        english: 'Text Colors',
      ),
      onDone: () {
        Navigator.of(context).pop(
          _TextColorSelection(
            textColor: _selectedColor,
            textGradientIndex: _selectedGradientIndex,
          ),
        );
      },
      onBack: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildLabel('Solid'),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                itemCount: widget.colors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final color = widget.colors[index];
                  final selected =
                      _selectedGradientIndex == -1 &&
                      _selectedColor.toARGB32() == color.toARGB32();
                  return _PressableSurface(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        _selectedGradientIndex = -1;
                      });
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.white24,
                          width: selected ? 2.2 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildLabel('Gradient'),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                itemCount: widget.gradients.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.7,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final selected = _selectedGradientIndex == index;
                  return _PressableSurface(
                    onTap: () {
                      setState(() {
                        _selectedGradientIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.gradients[index],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.white24,
                          width: selected ? 2 : 1,
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

  Widget _buildLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
