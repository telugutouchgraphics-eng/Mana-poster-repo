part of 'image_editor_screen.dart';

const int _designImportLargeWarningBytes = 50 * 1024 * 1024;
const int _designImportMaxBytes = 100 * 1024 * 1024;

extension _EditorLayersState on _ImageEditorScreenState {
  Future<void> _openLayerStyleDesignOnlySheet(_CanvasLayer layer) {
    final layerId = layer.id;
    void updateStyle({
      Color? strokeColor,
      double? strokeWidth,
      double? strokeOpacity,
      int? strokePosition,
      Color? shadowColor,
      double? shadowOpacity,
      double? shadowBlur,
      double? shadowSpread,
      double? shadowOffsetX,
      double? shadowOffsetY,
      Color? innerShadowColor,
      double? innerShadowOpacity,
      double? innerShadowBlur,
      double? innerShadowChoke,
      double? innerShadowDistance,
      double? innerShadowAngle,
      Color? outerGlowColor,
      double? outerGlowOpacity,
      double? outerGlowSize,
      double? outerGlowSpread,
      Color? overlayColor,
      double? overlayOpacity,
      bool? gradientOverlayEnabled,
      int? gradientOverlayIndex,
      double? gradientOverlayOpacity,
      double? gradientOverlayAngle,
      double? gradientOverlayScale,
      bool? gradientOverlayReversed,
    }) {
      final index = _layers.indexWhere((item) => item.id == layerId);
      if (index == -1 || _layers[index].isLocked) {
        return;
      }
      setState(() {
        _layers[index] = _layers[index].copyWith(
          layerStyleStrokeColor: strokeColor,
          layerStyleStrokeWidth: strokeWidth?.clamp(0.0, 20.0),
          layerStyleStrokeOpacity: strokeOpacity?.clamp(0.0, 1.0),
          layerStyleStrokePosition: strokePosition?.clamp(0, 2),
          layerStyleStrokeBlendMode: 0,
          layerStyleShadowColor: shadowColor,
          layerStyleShadowOpacity: shadowOpacity?.clamp(0.0, 1.0),
          layerStyleShadowBlur: shadowBlur?.clamp(0.0, 80.0),
          layerStyleShadowSpread: shadowSpread?.clamp(0.0, 80.0),
          layerStyleShadowOffsetX: shadowOffsetX?.clamp(-80.0, 80.0),
          layerStyleShadowOffsetY: shadowOffsetY?.clamp(-80.0, 80.0),
          layerStyleShadowBlendMode: 0,
          layerStyleShadowNoise: 0,
          layerStyleInnerShadowColor: innerShadowColor,
          layerStyleInnerShadowOpacity: innerShadowOpacity?.clamp(0.0, 1.0),
          layerStyleInnerShadowBlur: innerShadowBlur?.clamp(0.0, 80.0),
          layerStyleInnerShadowChoke: innerShadowChoke?.clamp(0.0, 100.0),
          layerStyleInnerShadowDistance: innerShadowDistance?.clamp(0.0, 120.0),
          layerStyleInnerShadowAngle: innerShadowAngle?.clamp(0.0, 360.0),
          layerStyleInnerShadowBlendMode: 0,
          layerStyleInnerShadowNoise: 0,
          layerStyleOuterGlowColor: outerGlowColor,
          layerStyleOuterGlowOpacity: outerGlowOpacity?.clamp(0.0, 1.0),
          layerStyleOuterGlowSize: outerGlowSize?.clamp(0.0, 120.0),
          layerStyleOuterGlowSpread: outerGlowSpread?.clamp(0.0, 60.0),
          layerStyleOuterGlowBlendMode: 0,
          layerStyleOuterGlowNoise: 0,
          layerStyleOverlayColor: overlayColor,
          layerStyleOverlayOpacity: overlayOpacity?.clamp(0.0, 1.0),
          layerStyleColorOverlayBlendMode: 0,
          layerStyleGradientOverlayEnabled: gradientOverlayEnabled,
          layerStyleGradientOverlayIndex: gradientOverlayIndex?.clamp(
            0,
            math.max(0, _textGradients.length - 1),
          ),
          layerStyleGradientOverlayOpacity: gradientOverlayOpacity?.clamp(
            0.0,
            1.0,
          ),
          layerStyleGradientOverlayAngle: gradientOverlayAngle?.clamp(
            0.0,
            360.0,
          ),
          layerStyleGradientOverlayScale: gradientOverlayScale?.clamp(
            10.0,
            200.0,
          ),
          layerStyleGradientOverlayReversed: gradientOverlayReversed,
          layerStyleGradientOverlayBlendMode: 0,
          layerStyleBevelEnabled: false,
          layerStyleTextureEnabled: false,
          layerStylePatternOverlayEnabled: false,
          layerStylePatternOverlayOpacity: 0,
          layerStyleInnerGlowOpacity: 0,
          layerStyleSatinOpacity: 0,
        );
      });
    }

    Color defaultStrokeColor(_CanvasLayer target) {
      final baseColor = target.isText
          ? target.textColor
          : target.isSticker
          ? target.stickerColor
          : Colors.black;
      return baseColor.computeLuminance() < 0.45 ? Colors.white : Colors.black;
    }

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final current = _layers.cast<_CanvasLayer?>().firstWhere(
              (item) => item?.id == layerId,
              orElse: () => null,
            );
            if (current == null) {
              return const SizedBox.shrink();
            }
            final layerName = current.layerName.trim().isEmpty
                ? (current.isText
                      ? 'Text Layer'
                      : current.isSticker
                      ? 'Sticker Layer'
                      : 'Photo Layer')
                : current.layerName.trim();

            Widget slider(
              String label,
              double value,
              double min,
              double max,
              ValueChanged<double> onChanged,
            ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _editorChromeTextPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        value.round().toString(),
                        style: const TextStyle(
                          color: _editorChromeTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: value.clamp(min, max),
                    min: min,
                    max: max,
                    divisions: math.max(1, (max - min).round()),
                    onChanged: (next) {
                      if (next == value) {
                        return;
                      }
                      onChanged(next);
                      setSheetState(() {});
                    },
                  ),
                ],
              );
            }

            Widget colorControls(
              Color selectedColor,
              ValueChanged<Color> onColor, {
              bool commitOnDragEnd = false,
            }) {
              final selectedHsv = HSVColor.fromColor(selectedColor);
              final neutralBlack = selectedHsv.value <= 0.02;
              final neutralWhite =
                  selectedHsv.saturation <= 0.04 && selectedHsv.value >= 0.96;
              void setHue(double hue) {
                final saturation = selectedHsv.saturation <= 0.04
                    ? 1.0
                    : selectedHsv.saturation;
                final value = selectedHsv.value <= 0.02
                    ? 1.0
                    : selectedHsv.value;
                onColor(HSVColor.fromAHSV(1, hue, saturation, value).toColor());
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _NeutralColorBubble(
                          label: 'Black',
                          color: Colors.black,
                          selected: neutralBlack,
                          onTap: () {
                            onColor(Colors.black);
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        _NeutralColorBubble(
                          label: 'White',
                          color: Colors.white,
                          selected: neutralWhite,
                          onTap: () {
                            onColor(Colors.white);
                            setSheetState(() {});
                          },
                        ),
                        const Spacer(),
                        Container(
                          width: 42,
                          height: 28,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _LayerStyleHueSlider(
                      hue: selectedHsv.hue,
                      color: selectedColor,
                      onChanged: (hue) {
                        if (commitOnDragEnd) {
                          return;
                        }
                        setHue(hue);
                        setSheetState(() {});
                      },
                      onChangeEnd: commitOnDragEnd
                          ? (hue) {
                              setHue(hue);
                              setSheetState(() {});
                            }
                          : null,
                    ),
                  ],
                ),
              );
            }

            Widget gradientChips(int selectedIndex) {
              if (_textGradients.isEmpty) {
                return const SizedBox.shrink();
              }
              final safeIndex = selectedIndex
                  .clamp(0, _textGradients.length - 1)
                  .toInt();
              return Container(
                height: 116,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 0.56,
                  ),
                  itemCount: _textGradients.length,
                  itemBuilder: (context, index) {
                    final selected = index == safeIndex;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: 'Gradient ${index + 1}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            updateStyle(
                              gradientOverlayEnabled: true,
                              gradientOverlayIndex: index,
                              gradientOverlayOpacity:
                                  current.layerStyleGradientOverlayOpacity <=
                                      0.001
                                  ? 0.65
                                  : null,
                            );
                            setSheetState(() {});
                            HapticFeedback.selectionClick();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _textGradients[index],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.16),
                                width: selected ? 2.5 : 1,
                              ),
                              boxShadow: selected
                                  ? const <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 7,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: Colors.white,
                                      shadows: <Shadow>[
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            Widget effectCard({
              required IconData icon,
              required String title,
              required bool enabled,
              required ValueChanged<bool> onToggle,
              required List<Widget> children,
            }) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.white.withValues(alpha: 0.06),
                    highlightColor: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: enabled,
                    iconColor: _editorChromeTextPrimary,
                    collapsedIconColor: _editorChromeTextSecondary,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    title: Row(
                      children: [
                        Icon(icon, color: const Color(0xFF7DD3FC), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: _editorChromeTextPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: enabled,
                          onChanged: (next) {
                            onToggle(next);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    children: children,
                  ),
                ),
              );
            }

            Widget previewCard(_CanvasLayer previewLayer) {
              final gradientIndex = previewLayer.layerStyleGradientOverlayIndex
                  .clamp(0, math.max(0, _textGradients.length - 1))
                  .toInt();
              final gradientColors = _textGradients.isEmpty
                  ? const <Color>[Color(0xFFFFFFFF), Color(0xFF000000)]
                  : _textGradients[gradientIndex];
              final Widget layerPreviewChild;
              if (previewLayer.isPhoto && previewLayer.bytes != null) {
                layerPreviewChild = SizedBox(
                  width: 170,
                  height: 112,
                  child: Image.memory(
                    previewLayer.bytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
                );
              } else if (previewLayer.isText) {
                layerPreviewChild = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: _CanvasTextLayerView(
                    text: _resolveLayerRenderText(previewLayer).trim().isEmpty
                        ? 'Text'
                        : _resolveLayerRenderText(previewLayer),
                    textColor: _layerStyleTextColor(previewLayer),
                    textAlign: previewLayer.textAlign,
                    fontSize: previewLayer.fontSize.clamp(18.0, 96.0),
                    textOpacity: previewLayer.textOpacity,
                    fontFamily: _resolveLayerRenderFontFamily(previewLayer),
                    textLineHeight: previewLayer.textLineHeight,
                    textLetterSpacing: previewLayer.textLetterSpacing,
                    textShadowOpacity: _layerStyleTextShadowOpacity(
                      previewLayer,
                    ),
                    textShadowColor: _layerStyleTextShadowColor(previewLayer),
                    textShadowBlur: _layerStyleTextShadowBlur(previewLayer),
                    textShadowOffsetX: _layerStyleTextShadowOffset(
                      previewLayer,
                    ).dx,
                    textShadowOffsetY: _layerStyleTextShadowOffset(
                      previewLayer,
                    ).dy,
                    textOuterGlowColor: previewLayer.layerStyleOuterGlowColor,
                    textOuterGlowOpacity:
                        previewLayer.layerStyleOuterGlowOpacity,
                    textOuterGlowSize: previewLayer.layerStyleOuterGlowSize,
                    textOuterGlowSpread: previewLayer.layerStyleOuterGlowSpread,
                    isTextBold: previewLayer.isTextBold,
                    isTextItalic: previewLayer.isTextItalic,
                    isTextUnderline: previewLayer.isTextUnderline,
                    textStrokeColor: previewLayer.layerStyleStrokeWidth > 0.001
                        ? previewLayer.layerStyleStrokeColor.withValues(
                            alpha: previewLayer.layerStyleStrokeOpacity.clamp(
                              0.0,
                              1.0,
                            ),
                          )
                        : previewLayer.textStrokeColor,
                    textStrokeWidth: math.max(
                      previewLayer.textStrokeWidth,
                      previewLayer.layerStyleStrokeWidth,
                    ),
                    textBackgroundColor: previewLayer.textBackgroundColor,
                    textBackgroundOpacity: previewLayer.textBackgroundOpacity,
                    textBackgroundRadius: previewLayer.textBackgroundRadius,
                    textBackgroundTopPadding:
                        previewLayer.textBackgroundTopPadding,
                    textBackgroundBottomPadding:
                        previewLayer.textBackgroundBottomPadding,
                    maxWidth: previewLayer.isParagraphText ? 220 : null,
                    textGradient: _layerStyleTextGradient(
                      previewLayer,
                      _textGradients,
                    ),
                    textGradientAngle:
                        previewLayer.layerStyleGradientOverlayEnabled
                        ? previewLayer.layerStyleGradientOverlayAngle
                        : 0,
                    textGradientScale:
                        previewLayer.layerStyleGradientOverlayEnabled
                        ? previewLayer.layerStyleGradientOverlayScale
                        : 100,
                  ),
                );
              } else if (_EditorTextState._isImageLikeSticker(
                previewLayer.sticker,
              )) {
                layerPreviewChild = SizedBox(
                  width: 118,
                  height: 118,
                  child: _EditorTextState._buildStickerVisual(
                    previewLayer.sticker,
                    fontSize: 92,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                );
              } else {
                layerPreviewChild = Text(
                  previewLayer.sticker ?? '★',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: previewLayer.stickerColor,
                    fontSize: previewLayer.fontSize.clamp(32.0, 96.0),
                    fontWeight: FontWeight.w800,
                  ),
                );
              }

              final styledPreview = _EditorUniversalLayerStyle(
                overlayColor: previewLayer.layerStyleOverlayColor,
                overlayOpacity: previewLayer.isText
                    ? 0
                    : previewLayer.layerStyleOverlayOpacity,
                colorOverlayBlendMode:
                    previewLayer.layerStyleColorOverlayBlendMode,
                strokeColor: previewLayer.layerStyleStrokeColor,
                strokeWidth: previewLayer.isText
                    ? 0
                    : previewLayer.layerStyleStrokeWidth,
                shadowColor: previewLayer.layerStyleShadowColor,
                shadowOpacity: previewLayer.isText
                    ? 0
                    : previewLayer.layerStyleShadowOpacity,
                shadowBlur: previewLayer.layerStyleShadowBlur,
                shadowSpread: previewLayer.layerStyleShadowSpread,
                shadowOffset: Offset(
                  previewLayer.layerStyleShadowOffsetX,
                  previewLayer.layerStyleShadowOffsetY,
                ),
                shadowBlendMode: previewLayer.layerStyleShadowBlendMode,
                shadowContour: previewLayer.layerStyleShadowContour,
                shadowNoise: previewLayer.layerStyleShadowNoise,
                useGlobalLight: previewLayer.layerStyleUseGlobalLight,
                globalLightAngle: previewLayer.layerStyleGlobalLightAngle,
                globalLightAltitude: previewLayer.layerStyleGlobalLightAltitude,
                bevelEnabled: false,
                bevelStyle: 0,
                bevelTechnique: 0,
                bevelDirection: 0,
                bevelDepth: 0,
                bevelSize: 0,
                bevelSoften: 0,
                bevelAngle: 120,
                bevelAltitude: 30,
                bevelHighlightColor: Colors.white,
                bevelHighlightOpacity: 0,
                bevelShadowColor: Colors.black,
                bevelShadowOpacity: 0,
                contour: 0,
                textureEnabled: false,
                textureScale: 36,
                textureDepth: 0,
                strokeOpacity: previewLayer.layerStyleStrokeOpacity,
                strokePosition: previewLayer.layerStyleStrokePosition,
                strokeBlendMode: previewLayer.layerStyleStrokeBlendMode,
                innerShadowColor: previewLayer.layerStyleInnerShadowColor,
                innerShadowOpacity: previewLayer.isText
                    ? 0
                    : previewLayer.layerStyleInnerShadowOpacity,
                innerShadowBlur: previewLayer.layerStyleInnerShadowBlur,
                innerShadowChoke: previewLayer.layerStyleInnerShadowChoke,
                innerShadowDistance: previewLayer.layerStyleInnerShadowDistance,
                innerShadowAngle: previewLayer.layerStyleInnerShadowAngle,
                innerShadowBlendMode:
                    previewLayer.layerStyleInnerShadowBlendMode,
                innerShadowContour: previewLayer.layerStyleInnerShadowContour,
                innerShadowNoise: previewLayer.layerStyleInnerShadowNoise,
                gradientOverlayEnabled: previewLayer.isText
                    ? false
                    : previewLayer.layerStyleGradientOverlayEnabled,
                gradientOverlayColors: gradientColors,
                gradientOverlayOpacity:
                    previewLayer.layerStyleGradientOverlayOpacity,
                gradientOverlayAngle:
                    previewLayer.layerStyleGradientOverlayAngle,
                gradientOverlayStyle:
                    previewLayer.layerStyleGradientOverlayStyle,
                gradientOverlayScale:
                    previewLayer.layerStyleGradientOverlayScale,
                gradientOverlayBlendMode:
                    previewLayer.layerStyleGradientOverlayBlendMode,
                gradientOverlayReversed:
                    previewLayer.layerStyleGradientOverlayReversed,
                gradientOverlayDither:
                    previewLayer.layerStyleGradientOverlayDither,
                outerGlowColor: previewLayer.layerStyleOuterGlowColor,
                outerGlowOpacity: previewLayer.isText
                    ? 0
                    : previewLayer.layerStyleOuterGlowOpacity,
                outerGlowSize: previewLayer.layerStyleOuterGlowSize,
                outerGlowSpread: previewLayer.layerStyleOuterGlowSpread,
                outerGlowNoise: previewLayer.layerStyleOuterGlowNoise,
                outerGlowContour: previewLayer.layerStyleOuterGlowContour,
                outerGlowRange: previewLayer.layerStyleOuterGlowRange,
                outerGlowJitter: previewLayer.layerStyleOuterGlowJitter,
                outerGlowBlendMode: previewLayer.layerStyleOuterGlowBlendMode,
                innerGlowColor: Colors.white,
                innerGlowOpacity: 0,
                innerGlowSize: 0,
                innerGlowSpread: 0,
                innerGlowNoise: 0,
                innerGlowSource: 0,
                innerGlowContour: 0,
                innerGlowRange: 50,
                innerGlowJitter: 0,
                innerGlowBlendMode: 0,
                satinColor: Colors.black,
                satinOpacity: 0,
                satinAngle: 0,
                satinDistance: 0,
                satinSize: 1,
                satinInverted: false,
                satinBlendMode: 0,
                patternOverlayEnabled: false,
                patternOverlayOpacity: 0,
                patternOverlayScale: 36,
                patternOverlayBlendMode: 0,
                patternOverlayPreset: 0,
                child: layerPreviewChild,
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 138,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF263447)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LayerStylePreviewGridPainter(),
                          ),
                        ),
                        Center(
                          child: OverflowBox(
                            minWidth: 0,
                            minHeight: 0,
                            maxWidth: double.infinity,
                            maxHeight: double.infinity,
                            child: styledPreview,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.84,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111724),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF263447)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 34,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_motion_rounded,
                            color: Color(0xFF7DD3FC),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Layer Styles',
                                  style: TextStyle(
                                    color: _editorChromeTextPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  layerName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _editorChromeTextSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
                    previewCard(current),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            effectCard(
                              icon: Icons.border_outer_rounded,
                              title: 'Stroke',
                              enabled: current.layerStyleStrokeWidth > 0.001,
                              onToggle: (next) => updateStyle(
                                strokeColor: next
                                    ? defaultStrokeColor(current)
                                    : null,
                                strokeWidth: next ? 8 : 0,
                                strokeOpacity: next ? 1 : 0,
                              ),
                              children: [
                                colorControls(
                                  current.layerStyleStrokeColor,
                                  (color) => updateStyle(strokeColor: color),
                                ),
                                slider(
                                  'Size',
                                  current.layerStyleStrokeWidth,
                                  0,
                                  20,
                                  (value) => updateStyle(strokeWidth: value),
                                ),
                                slider(
                                  'Opacity',
                                  current.layerStyleStrokeOpacity * 100,
                                  0,
                                  100,
                                  (value) =>
                                      updateStyle(strokeOpacity: value / 100),
                                ),
                              ],
                            ),
                            effectCard(
                              icon: Icons.wb_twilight_rounded,
                              title: 'Shadow',
                              enabled: current.layerStyleShadowOpacity > 0.001,
                              onToggle: (next) => updateStyle(
                                shadowOpacity: next ? 0.55 : 0,
                                shadowBlur: next ? 16 : null,
                                shadowOffsetY: next ? 8 : null,
                              ),
                              children: [
                                colorControls(
                                  current.layerStyleShadowColor,
                                  (color) => updateStyle(shadowColor: color),
                                ),
                                slider(
                                  'Opacity',
                                  current.layerStyleShadowOpacity * 100,
                                  0,
                                  100,
                                  (value) =>
                                      updateStyle(shadowOpacity: value / 100),
                                ),
                                slider(
                                  'Blur',
                                  current.layerStyleShadowBlur,
                                  0,
                                  80,
                                  (value) => updateStyle(shadowBlur: value),
                                ),
                                slider(
                                  'Spread',
                                  current.layerStyleShadowSpread,
                                  0,
                                  80,
                                  (value) => updateStyle(shadowSpread: value),
                                ),
                                slider(
                                  'X',
                                  current.layerStyleShadowOffsetX,
                                  -80,
                                  80,
                                  (value) => updateStyle(shadowOffsetX: value),
                                ),
                                slider(
                                  'Y',
                                  current.layerStyleShadowOffsetY,
                                  -80,
                                  80,
                                  (value) => updateStyle(shadowOffsetY: value),
                                ),
                              ],
                            ),
                            effectCard(
                              icon: Icons.dark_mode_rounded,
                              title: 'Inner Shadow',
                              enabled:
                                  current.layerStyleInnerShadowOpacity > 0.001,
                              onToggle: (next) => updateStyle(
                                innerShadowOpacity: next ? 0.42 : 0,
                                innerShadowBlur: next ? 14 : null,
                                innerShadowDistance: next ? 8 : null,
                              ),
                              children: [
                                colorControls(
                                  current.layerStyleInnerShadowColor,
                                  (color) =>
                                      updateStyle(innerShadowColor: color),
                                ),
                                slider(
                                  'Opacity',
                                  current.layerStyleInnerShadowOpacity * 100,
                                  0,
                                  100,
                                  (value) => updateStyle(
                                    innerShadowOpacity: value / 100,
                                  ),
                                ),
                                slider(
                                  'Blur',
                                  current.layerStyleInnerShadowBlur,
                                  0,
                                  80,
                                  (value) =>
                                      updateStyle(innerShadowBlur: value),
                                ),
                                slider(
                                  'Distance',
                                  current.layerStyleInnerShadowDistance,
                                  0,
                                  120,
                                  (value) =>
                                      updateStyle(innerShadowDistance: value),
                                ),
                                slider(
                                  'Choke',
                                  current.layerStyleInnerShadowChoke,
                                  0,
                                  100,
                                  (value) =>
                                      updateStyle(innerShadowChoke: value),
                                ),
                                slider(
                                  'Angle',
                                  current.layerStyleInnerShadowAngle,
                                  0,
                                  360,
                                  (value) =>
                                      updateStyle(innerShadowAngle: value),
                                ),
                              ],
                            ),
                            effectCard(
                              icon: Icons.blur_on_rounded,
                              title: 'Outer Glow',
                              enabled:
                                  current.layerStyleOuterGlowOpacity > 0.001,
                              onToggle: (next) => updateStyle(
                                outerGlowOpacity: next ? 0.65 : 0,
                                outerGlowSize: next ? 20 : null,
                              ),
                              children: [
                                colorControls(
                                  current.layerStyleOuterGlowColor,
                                  (color) => updateStyle(outerGlowColor: color),
                                ),
                                slider(
                                  'Opacity',
                                  current.layerStyleOuterGlowOpacity * 100,
                                  0,
                                  100,
                                  (value) => updateStyle(
                                    outerGlowOpacity: value / 100,
                                  ),
                                ),
                                slider(
                                  'Size',
                                  current.layerStyleOuterGlowSize,
                                  0,
                                  120,
                                  (value) => updateStyle(outerGlowSize: value),
                                ),
                                slider(
                                  'Spread',
                                  current.layerStyleOuterGlowSpread,
                                  0,
                                  60,
                                  (value) =>
                                      updateStyle(outerGlowSpread: value),
                                ),
                              ],
                            ),
                            effectCard(
                              icon: Icons.invert_colors_rounded,
                              title: 'Color Overlay',
                              enabled: current.layerStyleOverlayOpacity > 0.001,
                              onToggle: (next) => updateStyle(
                                overlayOpacity: next ? 0.45 : 0,
                                overlayColor: next ? Colors.white : null,
                              ),
                              children: [
                                colorControls(
                                  current.layerStyleOverlayColor,
                                  (color) => updateStyle(overlayColor: color),
                                ),
                                slider(
                                  'Opacity',
                                  current.layerStyleOverlayOpacity * 100,
                                  0,
                                  100,
                                  (value) =>
                                      updateStyle(overlayOpacity: value / 100),
                                ),
                              ],
                            ),
                            effectCard(
                              icon: Icons.gradient_rounded,
                              title: 'Gradient Overlay',
                              enabled: current.layerStyleGradientOverlayEnabled,
                              onToggle: (next) => updateStyle(
                                gradientOverlayEnabled: next,
                                gradientOverlayOpacity: next ? 0.65 : 0,
                              ),
                              children: [
                                gradientChips(
                                  current.layerStyleGradientOverlayIndex,
                                ),
                                slider(
                                  'Opacity',
                                  current.layerStyleGradientOverlayOpacity *
                                      100,
                                  0,
                                  100,
                                  (value) => updateStyle(
                                    gradientOverlayOpacity: value / 100,
                                  ),
                                ),
                                slider(
                                  'Angle',
                                  current.layerStyleGradientOverlayAngle,
                                  0,
                                  360,
                                  (value) =>
                                      updateStyle(gradientOverlayAngle: value),
                                ),
                                slider(
                                  'Scale',
                                  current.layerStyleGradientOverlayScale,
                                  10,
                                  200,
                                  (value) =>
                                      updateStyle(gradientOverlayScale: value),
                                ),
                                FilterChip(
                                  label: const Text('Reverse'),
                                  selected:
                                      current.layerStyleGradientOverlayReversed,
                                  onSelected: (value) {
                                    updateStyle(gradientOverlayReversed: value);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleCanvasAutoSelectLayer() {
    setState(() {
      _autoSelectCanvasLayer = !_autoSelectCanvasLayer;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _openUniversalLayerStyleSheet() async {
    final selected = _selectedLayer;
    if (selected == null || selected.isLocked) {
      return;
    }
    final layerId = selected.id;
    final beforeLayer = _cloneLayer(selected);
    await _openLayerStyleDesignOnlySheet(selected);
    await Future<void>.delayed(kThemeAnimationDuration);
    if (!mounted) {
      return;
    }
    final afterIndex = _layers.indexWhere((layer) => layer.id == layerId);
    final afterLayer = afterIndex == -1 ? null : _layers[afterIndex];
    if (afterLayer != null && _didLayerChange(beforeLayer, afterLayer)) {
      final committedLayer = _cloneLayer(afterLayer);
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: committedLayer,
      );
      setState(() => _layers[afterIndex] = committedLayer);
      _scheduleAutosave();
    }
  }

  void _handleLayerSelected(String id) {
    if (_isCropMode) {
      return;
    }
    if (_selectedLayerId != id && _selectedTextFocusNode.hasFocus) {
      _selectedTextFocusNode.unfocus();
    }
    _commitSelectedTextContentEdit();
    if (_selectedLayerId != id) {
      _lastSelectedTextTapAt = null;
      _lastSelectedTextTapLayerId = null;
    }
    if (_selectedLayerId == id) {
      if (_isTextPlacementMode) {
        setState(() => _isTextPlacementMode = false);
      }
      if (_hasSelectedTextLayer) {
        _syncSelectedTextEditor();
        if (_activeBottomPrimaryTool != _BottomPrimaryTool.text ||
            _activeMainToolLabel != 'Text') {
          setState(() {
            _activeBottomPrimaryTool = _BottomPrimaryTool.text;
            _activeMainToolLabel = 'Text';
          });
        }
      }
      if (!_showSelectedLayerHandles) {
        setState(() => _showSelectedLayerHandles = true);
      }
      return;
    }

    final index = _layers.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    final layer = _layers[index];
    if (layer.isHidden || layer.isLocked) {
      return;
    }
    final selectedTransform = Matrix4.copy(layer.transform);
    if (!_isMatrixFinite(selectedTransform)) {
      selectedTransform.setIdentity();
    }
    _transformationController.value = selectedTransform;
    setState(() {
      _selectedLayerId = id;
      _showSelectedLayerHandles = true;
      _isTextPlacementMode = false;
      _showTextControls = false;
      if (layer.isText) {
        _activeBottomPrimaryTool = _BottomPrimaryTool.text;
        _activeMainToolLabel = 'Text';
      } else if (layer.isPhoto) {
        _activeBottomPrimaryTool = _BottomPrimaryTool.photo;
        _activeMainToolLabel = 'Photo';
      } else if (layer.isSticker) {
        _activeBottomPrimaryTool = _BottomPrimaryTool.none;
        _activeMainToolLabel = 'Stickers';
      }
      if (_adjustSessionLayerId != id) {
        _isAdjustMode = false;
        _adjustSessionLayerId = null;
      }
      if (!layer.isPhoto) {
        _isPhotoEraserMode = false;
        _isPhotoStretchMode = false;
        _isContentAwareMode = false;
        _isPhotoCloneMode = false;
        _eraserStrokePoints.clear();
        _contentAwareStrokePoints.clear();
        _cloneStrokePoints = <Offset>[];
        _clonePreviewStampPoints = <Offset>[];
        _stretchStrokePoints.clear();
        _eraserStrokeLayerId = null;
        _contentAwareStrokeLayerId = null;
        _cloneStrokeLayerId = null;
        _stretchStrokeLayerId = null;
        _eraserStrokeLayerSize = Size.zero;
        _contentAwareStrokeLayerSize = Size.zero;
        _cloneStrokeLayerSize = Size.zero;
        _cloneSourcePoint = null;
        _cloneAlignedSampleOffset = null;
        _stretchStrokeLayerSize = Size.zero;
        _eraserPreviewNotifier.value = null;
      }
    });
    _syncSelectedTextEditor();
  }

  void _showSelectedLayerSelection() {
    if (_selectedLayer == null) {
      return;
    }
    if (_selectedTextFocusNode.hasFocus) {
      _selectedTextFocusNode.unfocus();
    }
    setState(() {
      _showSelectedLayerHandles = !_showSelectedLayerHandles;
    });
  }

  void _handleCanvasTapDown(
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  ) {
    if (_isCropMode ||
        _isInlineTextEditing ||
        _isPhotoEraserMode ||
        _isContentAwareMode ||
        _isPhotoCloneMode ||
        _isPhotoStretchMode ||
        _isLayerMaskBrushMode ||
        _isDrawBrushMode) {
      _canvasTapResolvedLayer = true;
      return;
    }
    if (_suppressCanvasTapDown) {
      _suppressCanvasTapDown = false;
      return;
    }
    if (_isMagicWandMode) {
      _canvasTapResolvedLayer = true;
      unawaited(
        _handleMagicWandTap(
          localPosition: localPosition,
          pageRect: pageRect,
          pageSize: pageSize,
        ),
      );
      return;
    }
    if (_shouldPlaceTextAtCanvasTap(
      localPosition: localPosition,
      pageRect: pageRect,
    )) {
      _canvasTapResolvedLayer = true;
      unawaited(
        _handleCanvasTextPlacementTap(
          localPosition: localPosition,
          pageRect: pageRect,
          pageSize: pageSize,
        ),
      );
      return;
    }
    if (!_autoSelectCanvasLayer) {
      _canvasTapResolvedLayer = true;
      return;
    }
    final resolvedId = _resolveTopLayerAtPoint(
      localPosition: localPosition,
      pageRect: pageRect,
      pageSize: pageSize,
    );
    if (resolvedId == null) {
      _canvasTapResolvedLayer = false;
      _clearSelection();
      return;
    }
    _canvasTapResolvedLayer = true;
    _handleLayerSelected(resolvedId);
  }

  void _handleCanvasTap() {
    if (_isInlineTextEditing) {
      _canvasTapResolvedLayer = false;
      return;
    }
    if (!_autoSelectCanvasLayer) {
      _canvasTapResolvedLayer = false;
      return;
    }
    if (_canvasTapResolvedLayer) {
      _canvasTapResolvedLayer = false;
      return;
    }
    _clearSelection();
  }

  Future<void> _handleCanvasLongPressStart(
    Offset globalPosition,
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  ) async {
    if (_isCropMode ||
        _isPhotoEraserMode ||
        _isLayerMaskBrushMode ||
        _isDrawBrushMode ||
        _isTextPlacementMode ||
        _isInlineTextEditing ||
        _isExporting ||
        _isCapturingStage ||
        _layers.isEmpty) {
      return;
    }
    final longPressedLayerId = _resolveTopLayerAtPoint(
      localPosition: localPosition,
      pageRect: pageRect,
      pageSize: pageSize,
    );
    if (longPressedLayerId != null) {
      final longPressedLayer = _layers.cast<_CanvasLayer?>().firstWhere(
        (layer) => layer?.id == longPressedLayerId,
        orElse: () => null,
      );
      if (longPressedLayer != null &&
          (longPressedLayer.isText ||
              ((longPressedLayer.psdEditableText ?? '').trim().isNotEmpty))) {
        _editLayerTextById(longPressedLayerId);
        return;
      }
    }
    _cancelSelectedTextLongPress();
    HapticFeedback.mediumImpact();
    _canvasLayerPickerEntry?.remove();
    _canvasLayerPickerEntry = null;

    final overlayState = Overlay.maybeOf(context);
    final overlay = overlayState?.context.findRenderObject();
    if (overlayState == null || overlay is! RenderBox || !overlay.hasSize) {
      return;
    }

    final popupWidth = math.min(340.0, overlay.size.width - 20).toDouble();
    final popupLeft = (globalPosition.dx - (popupWidth / 2))
        .clamp(10.0, math.max(10.0, overlay.size.width - popupWidth - 10))
        .toDouble();
    final popupTop = (globalPosition.dy + 10)
        .clamp(10.0, math.max(10.0, overlay.size.height - 480))
        .toDouble();

    late final OverlayEntry pickerEntry;
    var isRemoved = false;
    void closePicker() {
      if (isRemoved) {
        return;
      }
      isRemoved = true;
      pickerEntry.remove();
      if (_canvasLayerPickerEntry == pickerEntry) {
        _canvasLayerPickerEntry = null;
      }
    }

    final collapsedGroupIds = <String>{};
    pickerEntry = OverlayEntry(
      builder: (overlayContext) {
        return StatefulBuilder(
          builder: (pickerContext, setPickerState) {
            final selectableLayers = _layers.reversed.toList(growable: false);
            final groupCounts = <String, int>{};
            final groupNames = <String, String>{};
            for (final layer in selectableLayers) {
              final groupId = layer.groupId.trim();
              if (groupId.isEmpty) {
                continue;
              }
              groupCounts[groupId] = (groupCounts[groupId] ?? 0) + 1;
              groupNames.putIfAbsent(
                groupId,
                () => layer.groupName.trim().isEmpty
                    ? 'Group'
                    : layer.groupName.trim(),
              );
            }
            final emittedGroups = <String>{};
            final displayItems = <_CanvasLayerPickerDisplayItem>[];
            for (final layer in selectableLayers) {
              final groupId = layer.groupId.trim();
              if (groupId.isNotEmpty && emittedGroups.add(groupId)) {
                displayItems.add(
                  _CanvasLayerPickerDisplayItem.group(
                    groupId: groupId,
                    groupName: groupNames[groupId] ?? 'Group',
                    groupCount: groupCounts[groupId] ?? 1,
                  ),
                );
              }
              if (groupId.isNotEmpty && collapsedGroupIds.contains(groupId)) {
                continue;
              }
              displayItems.add(_CanvasLayerPickerDisplayItem.layer(layer));
            }
            final selectedLayer = _selectedLayerId == null
                ? null
                : _layers.cast<_CanvasLayer?>().firstWhere(
                    (layer) => layer?.id == _selectedLayerId,
                    orElse: () => null,
                  );
            final canDeleteSelected =
                selectedLayer != null && !selectedLayer.isLocked;

            void deleteSelectedLayer() {
              final layerId = selectedLayer?.id;
              if (layerId == null || !canDeleteSelected) {
                return;
              }
              HapticFeedback.selectionClick();
              _deleteLayerById(layerId);
              if (_layers.isEmpty) {
                closePicker();
                return;
              }
              if (mounted && !isRemoved) {
                setPickerState(() {});
              }
            }

            void reorderLayers(int oldIndex, int newIndex) {
              if (oldIndex < 0 || oldIndex >= displayItems.length) {
                return;
              }
              final movedLayer = displayItems[oldIndex].layer;
              if (movedLayer == null || movedLayer.isLocked) {
                return;
              }
              final reordered = List<_CanvasLayer>.of(selectableLayers);
              final previousTopIndex = reordered.indexWhere(
                (layer) => layer.id == movedLayer.id,
              );
              if (previousTopIndex == -1) {
                return;
              }
              reordered.removeAt(previousTopIndex);

              var insertTopIndex = reordered.length;
              if (newIndex < displayItems.length) {
                final targetItem =
                    displayItems[newIndex.clamp(0, displayItems.length - 1)];
                final targetLayer = targetItem.layer;
                if (targetLayer != null) {
                  insertTopIndex = reordered.indexWhere(
                    (layer) => layer.id == targetLayer.id,
                  );
                } else {
                  insertTopIndex = reordered.indexWhere(
                    (layer) => layer.groupId.trim() == targetItem.groupId,
                  );
                }
                if (insertTopIndex == -1) {
                  insertTopIndex = reordered.length;
                }
              }
              insertTopIndex = insertTopIndex
                  .clamp(0, reordered.length)
                  .toInt();
              reordered.insert(insertTopIndex, movedLayer);

              final oldCanvasIndex = _layers.indexWhere(
                (layer) => layer.id == movedLayer.id,
              );
              final desiredCanvasOrder = reordered.reversed.toList(
                growable: false,
              );
              final newCanvasIndex = desiredCanvasOrder.indexWhere(
                (layer) => layer.id == movedLayer.id,
              );
              if (oldCanvasIndex == -1 || newCanvasIndex == -1) {
                return;
              }
              HapticFeedback.selectionClick();
              _reorderLayersFromAdvancedView(oldCanvasIndex, newCanvasIndex);
              if (mounted && !isRemoved) {
                setPickerState(() {});
              }
            }

            void runLayerAction(String type, String layerId) {
              if (!mounted) {
                closePicker();
                return;
              }
              HapticFeedback.selectionClick();
              switch (type) {
                case 'select':
                  _canvasTapResolvedLayer = true;
                  _handleLayerSelected(layerId);
                case 'visibility':
                  _toggleLayerVisibilityById(layerId);
                case 'lock':
                  _toggleLayerLockById(layerId);
              }
              if (mounted && !isRemoved) {
                setPickerState(() {});
              }
            }

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: closePicker,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: popupLeft,
                  top: popupTop,
                  width: popupWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: math.min(430, overlay.size.height - 24),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xC8202227),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.layers_rounded,
                                  color: Color(0xFFE2E8F0),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Layers',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const Spacer(),
                                _buildCanvasLayerPickerActionButton(
                                  icon: _autoSelectCanvasLayer
                                      ? Icons.touch_app_rounded
                                      : Icons.pan_tool_alt_outlined,
                                  color: _autoSelectCanvasLayer
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFFCBD5E1),
                                  onTap: () {
                                    _toggleCanvasAutoSelectLayer();
                                    if (mounted && !isRemoved) {
                                      setPickerState(() {});
                                    }
                                  },
                                ),
                                const SizedBox(width: 2),
                                _buildCanvasLayerPickerActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  color: const Color(0xFFF87171),
                                  enabled: canDeleteSelected,
                                  onTap: deleteSelectedLayer,
                                ),
                                const SizedBox(width: 2),
                                _buildCanvasLayerPickerActionButton(
                                  icon: Icons.close_rounded,
                                  color: const Color(0xFFCBD5E1),
                                  onTap: closePicker,
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          Flexible(
                            child: ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              padding: const EdgeInsets.fromLTRB(7, 5, 7, 7),
                              itemCount: displayItems.length,
                              onReorderItem: reorderLayers,
                              itemBuilder: (itemContext, index) {
                                final displayItem = displayItems[index];
                                final groupId = displayItem.groupId;
                                if (displayItem.layer == null) {
                                  return _CanvasLayerPickerGroupHeader(
                                    key: ValueKey<String>(
                                      'group_header_$groupId',
                                    ),
                                    groupName: displayItem.groupName,
                                    groupCount: displayItem.groupCount,
                                    collapsed: collapsedGroupIds.contains(
                                      groupId,
                                    ),
                                    selected:
                                        selectedLayer?.groupId.trim() ==
                                        groupId,
                                    onToggle: () {
                                      HapticFeedback.selectionClick();
                                      setPickerState(() {
                                        if (!collapsedGroupIds.add(groupId)) {
                                          collapsedGroupIds.remove(groupId);
                                        }
                                      });
                                    },
                                  );
                                }
                                final layer = displayItem.layer!;
                                final canSelect =
                                    !layer.isHidden && !layer.isLocked;
                                final selected = layer.id == _selectedLayerId;
                                return _CanvasLayerPickerSimpleRow(
                                  key: ValueKey<String>(layer.id),
                                  layer: layer,
                                  selected: selected,
                                  canSelect: canSelect,
                                  title: _canvasLayerPickerTitle(layer),
                                  preview: _buildCanvasLayerPickerPreview(
                                    layer,
                                  ),
                                  onSelect: () =>
                                      runLayerAction('select', layer.id),
                                  onVisibilityTap: () =>
                                      runLayerAction('visibility', layer.id),
                                  onLockTap: () =>
                                      runLayerAction('lock', layer.id),
                                  onMoreTap: () async {
                                    _canvasTapResolvedLayer = true;
                                    _handleLayerSelected(layer.id);
                                    // The picker is an OverlayEntry and otherwise
                                    // remains above the modal, intercepting taps.
                                    closePicker();
                                    // Let the overlay subtree finish deactivating
                                    // before mounting a route that depends on the
                                    // same inherited Navigator/Theme elements.
                                    await WidgetsBinding.instance.endOfFrame;
                                    if (!mounted) {
                                      return;
                                    }
                                    await _openCanvasLayerOptionsSheet(
                                      layer.id,
                                    );
                                  },
                                  dragHandle: layer.isLocked
                                      ? const Padding(
                                          padding: EdgeInsets.only(left: 3),
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                            color: Color(0xFF64748B),
                                            size: 17,
                                          ),
                                        )
                                      : ReorderableDragStartListener(
                                          index: index,
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: 3),
                                            child: Icon(
                                              Icons.drag_handle_rounded,
                                              color: Color(0xFFE2E8F0),
                                              size: 17,
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
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    overlayState.insert(pickerEntry);
    _canvasLayerPickerEntry = pickerEntry;
  }

  bool _hasVisibleLayerBelow(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index <= 0) {
      return false;
    }
    return _layers.take(index).any((layer) => !layer.isHidden);
  }

  void _setLayerClipsToBelowById(String layerId, {required bool enabled}) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    if (enabled && !_hasVisibleLayerBelow(layerId)) {
      return;
    }
    final beforeLayer = _layers[index];
    if (beforeLayer.clipsToLayerBelow == enabled) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(clipsToLayerBelow: enabled);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _renameLayerById(String layerId, String name) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    final beforeLayer = _layers[index];
    final normalizedName = name.trim();
    if (beforeLayer.layerName == normalizedName) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(layerName: normalizedName);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  Future<void> _openRenameLayerDialog(String layerId) async {
    final layer = _layers.cast<_CanvasLayer?>().firstWhere(
      (item) => item?.id == layerId,
      orElse: () => null,
    );
    if (layer == null || layer.isLocked) {
      return;
    }
    final controller = TextEditingController(
      text: layer.layerName.trim().isEmpty
          ? _canvasLayerPickerTitle(layer)
          : layer.layerName,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Layer'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Layer name',
              hintText: 'Photo, Title, Logo...',
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    // The dialog future resolves when pop starts, while its text field can
    // remain mounted during the reverse transition. Keep its controller and
    // inherited dependencies alive until that route has finished leaving.
    await Future<void>.delayed(kThemeAnimationDuration);
    controller.dispose();
    if (!mounted || result == null) {
      return;
    }
    _renameLayerById(layerId, result);
  }

  void _setLayerMaskById(
    String layerId, {
    bool? enabled,
    String? shape,
    bool? inverted,
    double? feather,
  }) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    final beforeLayer = _layers[index];
    final nextShape = shape ?? beforeLayer.layerMaskShape;
    final afterLayer = beforeLayer.copyWith(
      layerMaskEnabled:
          enabled ??
          (nextShape.trim().isNotEmpty || beforeLayer.layerMaskEnabled),
      layerMaskShape: nextShape,
      layerMaskInverted: inverted ?? beforeLayer.layerMaskInverted,
      layerMaskFeather: feather?.clamp(0.0, 60.0).toDouble(),
    );
    if (afterLayer.layerMaskEnabled == beforeLayer.layerMaskEnabled &&
        afterLayer.layerMaskShape == beforeLayer.layerMaskShape &&
        afterLayer.layerMaskInverted == beforeLayer.layerMaskInverted &&
        (afterLayer.layerMaskFeather - beforeLayer.layerMaskFeather).abs() <
            0.0001) {
      return;
    }
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _clearLayerMaskById(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    final beforeLayer = _layers[index];
    if (beforeLayer.layerMaskShape.trim().isEmpty) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      layerMaskEnabled: beforeLayer.layerMaskBrushStrokes.isNotEmpty,
      layerMaskShape: '',
      layerMaskInverted: false,
      layerMaskFeather: 0,
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _activateLayerMaskBrushMode(String layerId, {bool restore = false}) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked || _layers[index].isText) {
      return;
    }
    setState(() {
      _selectedLayerId = layerId;
      _syncControllerFromSelection();
      _isLayerMaskBrushMode = true;
      _isLayerMaskBrushRestoreMode = restore;
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isMagicWandMode = false;
      _isAdjustMode = false;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
      _activeMainToolLabel = 'Mask Brush';
      _layers[index] = _layers[index].copyWith(layerMaskEnabled: true);
      _layerMaskStrokePoints.clear();
      _layerMaskStrokeLayerId = null;
      _layerMaskStrokeLayerSize = Size.zero;
    });
    _showLayerMaskBrushCursorPreview();
  }

  void _closeLayerMaskBrushMode() {
    setState(() {
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _layerMaskStrokePoints.clear();
      _layerMaskStrokeLayerId = null;
      _layerMaskStrokeLayerSize = Size.zero;
      _eraserPreviewNotifier.value = null;
      _restoreSelectedLayerToolContextFields();
    });
  }

  void _handleLayerMaskBrushStart(Offset localPosition, Size layerSize) {
    if (!_isLayerMaskBrushMode || layerSize.isEmpty) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null || _isSelectedLayerLocked) {
      return;
    }
    _layerMaskStrokeLayerId = selectedId;
    _layerMaskStrokeLayerSize = layerSize;
    _layerMaskStrokePoints
      ..clear()
      ..add(_normalizeEraserPoint(localPosition, layerSize));
    _publishLayerMaskBrushPreview();
  }

  void _handleLayerMaskBrushUpdate(Offset localPosition, Size layerSize) {
    if (!_isLayerMaskBrushMode ||
        _layerMaskStrokeLayerId == null ||
        layerSize.isEmpty) {
      return;
    }
    final nextPoint = _normalizeEraserPoint(localPosition, layerSize);
    final previousPoint = _layerMaskStrokePoints.isEmpty
        ? null
        : _layerMaskStrokePoints.last;
    if (previousPoint != null) {
      final brushSize = _workspaceBrushSize(_layerMaskBrushSize);
      final minStep =
          (brushSize / math.max(layerSize.width, layerSize.height)) * 0.035;
      if ((nextPoint - previousPoint).distance < minStep.clamp(0.0006, 0.006)) {
        return;
      }
    }
    _layerMaskStrokePoints.add(nextPoint);
    _publishLayerMaskBrushPreview();
  }

  void _handleLayerMaskBrushEnd() {
    if (!_isLayerMaskBrushMode) {
      _layerMaskStrokePoints.clear();
      _layerMaskStrokeLayerId = null;
      _layerMaskStrokeLayerSize = Size.zero;
      _eraserPreviewNotifier.value = null;
      return;
    }
    final layerId = _layerMaskStrokeLayerId;
    final strokePoints = List<Offset>.of(_layerMaskStrokePoints);
    _layerMaskStrokePoints.clear();
    _layerMaskStrokeLayerId = null;
    _layerMaskStrokeLayerSize = Size.zero;
    _eraserPreviewNotifier.value = null;
    if (layerId == null || strokePoints.isEmpty) {
      return;
    }
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    final beforeLayer = _layers[index];
    final brushSize = _workspaceBrushSize(_layerMaskBrushSize);
    final strokes = <_LayerMaskBrushStroke>[
      ...beforeLayer.layerMaskBrushStrokes,
      _LayerMaskBrushStroke(
        points: List<Offset>.unmodifiable(strokePoints),
        brushSize: brushSize,
        hardness: _layerMaskBrushHardness,
        restores: _isLayerMaskBrushRestoreMode,
      ),
    ];
    final afterLayer = beforeLayer.copyWith(
      layerMaskEnabled: true,
      layerMaskBrushStrokes: List<_LayerMaskBrushStroke>.unmodifiable(strokes),
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _clearLayerMaskBrushStrokesById(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    final beforeLayer = _layers[index];
    if (beforeLayer.layerMaskBrushStrokes.isEmpty) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      layerMaskBrushStrokes: const <_LayerMaskBrushStroke>[],
      layerMaskEnabled: beforeLayer.layerMaskShape.trim().isNotEmpty,
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _cancelLayerMaskBrushStroke() {
    _layerMaskStrokePoints.clear();
    _layerMaskStrokeLayerId = null;
    _layerMaskStrokeLayerSize = Size.zero;
    _eraserPreviewNotifier.value = null;
  }

  void _publishLayerMaskBrushPreview() {
    final layerId = _layerMaskStrokeLayerId;
    if (layerId == null || _layerMaskStrokePoints.isEmpty) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: layerId,
      points: List<Offset>.of(_layerMaskStrokePoints),
      brushSize: _layerMaskBrushSize,
      hardness: _layerMaskBrushHardness,
    );
  }

  void _showLayerMaskBrushCursorPreview([
    Offset point = const Offset(0.5, 0.5),
  ]) {
    if (!_isLayerMaskBrushMode) {
      return;
    }
    final layerId = _selectedLayerId;
    if (layerId == null) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: layerId,
      points: <Offset>[
        Offset(point.dx.clamp(0.0, 1.0), point.dy.clamp(0.0, 1.0)),
      ],
      brushSize: _layerMaskBrushSize,
      hardness: _layerMaskBrushHardness,
    );
  }

  void _toggleLayerMaskBrushRestoreMode() {
    if (!_isLayerMaskBrushMode) {
      return;
    }
    setState(() {
      _isLayerMaskBrushRestoreMode = !_isLayerMaskBrushRestoreMode;
    });
    _showLayerMaskBrushCursorPreview();
  }

  Future<void> _openLayerMaskOptionsSheet(String layerId) async {
    const masks = <({String label, String shape, IconData icon})>[
      (label: 'Circle', shape: 'circle', icon: Icons.circle_outlined),
      (label: 'Square', shape: 'square', icon: Icons.crop_square_rounded),
      (label: 'Rounded', shape: 'rounded', icon: Icons.rounded_corner_rounded),
      (label: 'Oval', shape: 'oval', icon: Icons.egg_outlined),
      (label: 'Heart', shape: 'heart', icon: Icons.favorite_border_rounded),
      (label: 'Star', shape: 'star', icon: Icons.star_border_rounded),
      (label: 'Hexagon', shape: 'hexagon', icon: Icons.hexagon_outlined),
      (label: 'Diamond', shape: 'diamond', icon: Icons.diamond_outlined),
      (label: 'Arch', shape: 'arch', icon: Icons.architecture_rounded),
      (label: 'Blob', shape: 'blob', icon: Icons.blur_on_rounded),
    ];

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final layer = _layers.cast<_CanvasLayer?>().firstWhere(
              (item) => item?.id == layerId,
              orElse: () => null,
            );
            if (layer == null) {
              return const SizedBox.shrink();
            }
            final canEdit = !layer.isLocked;
            final canBrush = canEdit && !layer.isText;
            final selectedShape = layer.layerMaskShape.trim();

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: _EditorGlassSurface(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.filter_b_and_w_rounded,
                              color: _editorChromeTextPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Layer Mask',
                                style: TextStyle(
                                  color: _editorChromeTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
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
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final mask in masks)
                              ChoiceChip(
                                avatar: Icon(mask.icon, size: 16),
                                label: Text(mask.label),
                                selected: selectedShape == mask.shape,
                                onSelected: canEdit
                                    ? (_) {
                                        HapticFeedback.selectionClick();
                                        _setLayerMaskById(
                                          layerId,
                                          enabled: true,
                                          shape: mask.shape,
                                        );
                                        setSheetState(() {});
                                      }
                                    : null,
                              ),
                            ActionChip(
                              avatar: const Icon(
                                Icons.photo_library_rounded,
                                size: 16,
                              ),
                              label: const Text('Gallery'),
                              onPressed: canEdit
                                  ? () => Navigator.of(context).pop('gallery')
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile.adaptive(
                            value: layer.layerMaskEnabled,
                            onChanged: canEdit && selectedShape.isNotEmpty
                                ? (value) {
                                    _setLayerMaskById(layerId, enabled: value);
                                    setSheetState(() {});
                                  }
                                : null,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(
                              Icons.visibility_rounded,
                              color: _editorChromeTextPrimary,
                            ),
                            title: const Text(
                              'Enable mask',
                              style: TextStyle(
                                color: _editorChromeTextPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile.adaptive(
                            value: layer.layerMaskInverted,
                            onChanged: canEdit && selectedShape.isNotEmpty
                                ? (value) {
                                    _setLayerMaskById(layerId, inverted: value);
                                    setSheetState(() {});
                                  }
                                : null,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(
                              Icons.flip_to_back_rounded,
                              color: _editorChromeTextPrimary,
                            ),
                            title: const Text(
                              'Invert mask',
                              style: TextStyle(
                                color: _editorChromeTextPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            const Text(
                              'Feather',
                              style: TextStyle(
                                color: _editorChromeTextPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              layer.layerMaskFeather.round().toString(),
                              style: const TextStyle(
                                color: _editorChromeTextSecondary,
                                fontWeight: FontWeight.w800,
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: layer.layerMaskFeather.clamp(0.0, 60.0),
                          min: 0,
                          max: 60,
                          divisions: 60,
                          onChanged: canEdit && selectedShape.isNotEmpty
                              ? (value) {
                                  _setLayerMaskById(layerId, feather: value);
                                  setSheetState(() {});
                                }
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.brush_rounded,
                                label: 'Hide Brush',
                                enabled: canBrush,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _activateLayerMaskBrushMode(layerId);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.auto_fix_high_rounded,
                                label: 'Restore Brush',
                                enabled: canBrush,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _activateLayerMaskBrushMode(
                                    layerId,
                                    restore: true,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.cleaning_services_rounded,
                                label: 'Clear Brush',
                                danger: true,
                                enabled:
                                    canEdit &&
                                    layer.layerMaskBrushStrokes.isNotEmpty,
                                onTap: () {
                                  _clearLayerMaskBrushStrokesById(layerId);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.delete_sweep_rounded,
                                label: 'Clear Shape',
                                danger: true,
                                enabled: canEdit && selectedShape.isNotEmpty,
                                onTap: () {
                                  _clearLayerMaskById(layerId);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || action != 'gallery') {
      return;
    }
    await Future<void>.delayed(kThemeAnimationDuration);
    if (mounted) {
      await _addGalleryPhotoToLayerMask(layerId);
    }
  }

  Future<void> _addGalleryPhotoToLayerMask(String sourceLayerId) async {
    if (_isPickingMedia) {
      return;
    }
    final sourceLayer = _layers.cast<_CanvasLayer?>().firstWhere(
      (layer) => layer?.id == sourceLayerId,
      orElse: () => null,
    );
    if (sourceLayer == null || sourceLayer.isLocked) {
      return;
    }
    final shape = sourceLayer.layerMaskShape.trim().isEmpty
        ? 'blob'
        : sourceLayer.layerMaskShape.trim();
    _isPickingMedia = true;
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted || picked == null) {
        return;
      }
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: 'Crop Mask Photo',
            toolbarColor: Colors.white,
            toolbarWidgetColor: const Color(0xFF0F172A),
            backgroundColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF2563EB),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Mask Photo',
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (!mounted || cropped == null) {
        return;
      }
      final rawBytes = await XFile(cropped.path).readAsBytes();
      final optimized = await compute(_optimizeEditorPhotoPayload, rawBytes);
      if (!mounted) {
        return;
      }
      final layer = _CanvasLayer(
        id: 'layer_${_layerSeed++}',
        type: _CanvasLayerType.photo,
        bytes: optimized.bytes,
        originalPhotoBytes: optimized.bytes,
        photoAspectRatio: optimized.aspectRatio,
        photoMaskShape: shape,
        transform: Matrix4.copy(sourceLayer.transform),
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
        _isPhotoMaskPositionMode = true;
        _activeMainToolLabel = 'Mask Position';
      });
    } finally {
      _isPickingMedia = false;
    }
  }

  void _convertPhotoLayerToSmartObject(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked || !_layers[index].isPhoto) {
      return;
    }
    final beforeLayer = _layers[index];
    final sourceBytes =
        beforeLayer.smartObjectSourceBytes ??
        beforeLayer.originalPhotoBytes ??
        beforeLayer.bytes;
    if (sourceBytes == null) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      isSmartObject: true,
      smartObjectSourceBytes: sourceBytes,
      originalPhotoBytes: beforeLayer.originalPhotoBytes ?? sourceBytes,
    );
    if (afterLayer.isSmartObject == beforeLayer.isSmartObject &&
        identical(
          afterLayer.smartObjectSourceBytes,
          beforeLayer.smartObjectSourceBytes,
        )) {
      return;
    }
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _resetSmartObjectSource(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked || !_layers[index].isPhoto) {
      return;
    }
    final beforeLayer = _layers[index];
    final sourceBytes = beforeLayer.smartObjectSourceBytes;
    if (!beforeLayer.isSmartObject || sourceBytes == null) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      bytes: sourceBytes,
      originalPhotoBytes: sourceBytes,
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  Future<void> _replaceSmartObjectSource(String layerId) async {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 ||
        _layers[index].isLocked ||
        !_layers[index].isPhoto ||
        !_layers[index].isSmartObject ||
        _isPickingMedia) {
      return;
    }
    _isPickingMedia = true;
    XFile? pickedFile;
    try {
      pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    } finally {
      _isPickingMedia = false;
    }
    if (!mounted || pickedFile == null) {
      return;
    }

    final beforeIndex = _layers.indexWhere((layer) => layer.id == layerId);
    if (beforeIndex == -1) {
      return;
    }
    final beforeLayer = _layers[beforeIndex];
    if (beforeLayer.isLocked ||
        !beforeLayer.isPhoto ||
        !beforeLayer.isSmartObject) {
      return;
    }

    final optimizedPhoto = await _runQueuedCommitJob<_OptimizedPhotoPayload>(
      jobKey: 'replace_smart_source_${DateTime.now().microsecondsSinceEpoch}',
      label: 'Replacing smart source',
      detail: 'Preparing the selected source photo',
      operation: () async {
        final rawBytes = await pickedFile!.readAsBytes();
        return compute(_optimizeEditorPhotoPayload, rawBytes);
      },
      showBusyMessage: false,
    );
    if (!mounted || optimizedPhoto == null) {
      return;
    }
    final layerIndex = _layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex == -1) {
      return;
    }
    final currentLayer = _layers[layerIndex];
    if (currentLayer.isLocked ||
        !currentLayer.isPhoto ||
        !currentLayer.isSmartObject) {
      return;
    }
    final afterLayer = currentLayer.copyWith(
      bytes: optimizedPhoto.bytes,
      originalPhotoBytes: optimizedPhoto.bytes,
      smartObjectSourceBytes: optimizedPhoto.bytes,
      photoAspectRatio: optimizedPhoto.aspectRatio,
    );
    _pushLayerHistoryEntry(beforeLayer: currentLayer, afterLayer: afterLayer);
    setState(() {
      _layers[layerIndex] = afterLayer;
    });
  }

  void _rasterizeSmartObject(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1 || _layers[index].isLocked) {
      return;
    }
    final beforeLayer = _layers[index];
    if (!beforeLayer.isSmartObject) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      isSmartObject: false,
      smartObjectSourceBytes: null,
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  bool _canGroupLayerWithBelow(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index <= 0 || _layers[index].isLocked) {
      return false;
    }
    final below = _layers[index - 1];
    return !below.isLocked;
  }

  void _groupLayerWithBelow(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index <= 0 || _layers[index].isLocked || _layers[index - 1].isLocked) {
      return;
    }
    final groupId = _layers[index].groupId.trim().isNotEmpty
        ? _layers[index].groupId
        : _layers[index - 1].groupId.trim().isNotEmpty
        ? _layers[index - 1].groupId
        : 'group_${DateTime.now().microsecondsSinceEpoch}';
    final groupName = _layers[index].groupName.trim().isNotEmpty
        ? _layers[index].groupName
        : _layers[index - 1].groupName.trim().isNotEmpty
        ? _layers[index - 1].groupName
        : 'Group';
    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(
        groupId: groupId,
        groupName: groupName,
      );
      _layers[index - 1] = _layers[index - 1].copyWith(
        groupId: groupId,
        groupName: groupName,
      );
    });
  }

  void _ungroupLayerById(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1) {
      return;
    }
    final groupId = _layers[index].groupId.trim();
    if (groupId.isEmpty) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      for (var i = 0; i < _layers.length; i++) {
        if (_layers[i].groupId == groupId && !_layers[i].isLocked) {
          _layers[i] = _layers[i].copyWith(groupId: '', groupName: '');
        }
      }
    });
  }

  bool _canLinkLayerWithBelow(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index <= 0 || _layers[index].isLocked) {
      return false;
    }
    final below = _layers[index - 1];
    return !below.isLocked;
  }

  void _linkLayerWithBelow(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index <= 0 || _layers[index].isLocked || _layers[index - 1].isLocked) {
      return;
    }
    final linkGroupId = _layers[index].linkGroupId.trim().isNotEmpty
        ? _layers[index].linkGroupId
        : _layers[index - 1].linkGroupId.trim().isNotEmpty
        ? _layers[index - 1].linkGroupId
        : 'link_${DateTime.now().microsecondsSinceEpoch}';
    _pushUndoSnapshot();
    setState(() {
      _layers[index] = _layers[index].copyWith(linkGroupId: linkGroupId);
      _layers[index - 1] = _layers[index - 1].copyWith(
        linkGroupId: linkGroupId,
      );
    });
  }

  void _unlinkLayerById(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1) {
      return;
    }
    final linkGroupId = _layers[index].linkGroupId.trim();
    if (linkGroupId.isEmpty) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      for (var i = 0; i < _layers.length; i++) {
        if (_layers[i].linkGroupId == linkGroupId && !_layers[i].isLocked) {
          _layers[i] = _layers[i].copyWith(linkGroupId: '');
        }
      }
    });
  }

  Future<void> _openSmartObjectOptionsSheet(String layerId) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final layer = _layers.cast<_CanvasLayer?>().firstWhere(
              (item) => item?.id == layerId,
              orElse: () => null,
            );
            if (layer == null) {
              return const SizedBox.shrink();
            }
            final canEdit = !layer.isLocked && layer.isPhoto;
            final canReset =
                canEdit &&
                layer.isSmartObject &&
                layer.smartObjectSourceBytes != null;
            final canReplace = canEdit && layer.isSmartObject;

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: _EditorGlassSurface(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.layers_clear_rounded,
                              color: _editorChromeTextPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                layer.isSmartObject
                                    ? 'Smart Object'
                                    : 'Convert to Smart Object',
                                style: const TextStyle(
                                  color: _editorChromeTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
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
                        const SizedBox(height: 8),
                        Text(
                          layer.isPhoto
                              ? 'Original photo is preserved for reset.'
                              : 'Smart Object is available for photo layers.',
                          style: const TextStyle(
                            color: _editorChromeTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.verified_outlined,
                                label: layer.isSmartObject
                                    ? 'Already Smart'
                                    : 'Convert',
                                enabled: canEdit && !layer.isSmartObject,
                                onTap: () {
                                  _convertPhotoLayerToSmartObject(layerId);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.restore_rounded,
                                label: 'Reset Source',
                                enabled: canReset,
                                onTap: () {
                                  _resetSmartObjectSource(layerId);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.photo_library_rounded,
                                label: 'Replace Source',
                                enabled: canReplace,
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await _replaceSmartObjectSource(layerId);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.layers_rounded,
                                label: 'Rasterize',
                                danger: true,
                                enabled: canEdit && layer.isSmartObject,
                                onTap: () {
                                  _rasterizeSmartObject(layerId);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCanvasLayerOptionsSheet(String layerId) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final layer = _layers.cast<_CanvasLayer?>().firstWhere(
              (item) => item?.id == layerId,
              orElse: () => null,
            );
            if (layer == null) {
              return const SizedBox.shrink();
            }
            final canEdit = !layer.isLocked;
            final canClip = canEdit && _hasVisibleLayerBelow(layerId);
            final canGroup = canEdit && _canGroupLayerWithBelow(layerId);
            final canLink = canEdit && _canLinkLayerWithBelow(layerId);
            final isGrouped = layer.groupId.isNotEmpty;
            final isLinked = layer.linkGroupId.isNotEmpty;

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: _EditorGlassSurface(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _buildCanvasLayerPickerPreview(layer),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _canvasLayerPickerTitle(layer),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _editorChromeTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
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
                        const SizedBox(height: 10),
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile.adaptive(
                            value: layer.clipsToLayerBelow && canClip,
                            onChanged: canClip
                                ? (value) {
                                    HapticFeedback.selectionClick();
                                    _setLayerClipsToBelowById(
                                      layerId,
                                      enabled: value,
                                    );
                                    setSheetState(() {});
                                  }
                                : null,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(
                              Icons.keyboard_tab_rounded,
                              color: _editorChromeTextPrimary,
                            ),
                            title: const Text(
                              'Insert Into Layer Below',
                              style: TextStyle(
                                color: _editorChromeTextPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              canClip
                                  ? 'Show this layer inside the layer below'
                                  : 'Needs a visible layer below',
                              style: const TextStyle(
                                color: _editorChromeTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.drive_file_rename_outline_rounded,
                                label: 'Rename',
                                enabled: canEdit,
                                onTap: () =>
                                    Navigator.of(context).pop('rename'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.copy_rounded,
                                label: 'Duplicate',
                                enabled: canEdit,
                                onTap: () =>
                                    Navigator.of(context).pop('duplicate'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: isGrouped
                                    ? Icons.folder_off_rounded
                                    : Icons.create_new_folder_rounded,
                                label: isGrouped ? 'Ungroup' : 'Group Below',
                                enabled: canEdit && (isGrouped || canGroup),
                                onTap: () {
                                  if (isGrouped) {
                                    _ungroupLayerById(layerId);
                                  } else {
                                    _groupLayerWithBelow(layerId);
                                  }
                                  setSheetState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: isLinked
                                    ? Icons.link_off_rounded
                                    : Icons.link_rounded,
                                label: isLinked ? 'Unlink' : 'Link Below',
                                enabled: canEdit && (isLinked || canLink),
                                onTap: () {
                                  if (isLinked) {
                                    _unlinkLayerById(layerId);
                                  } else {
                                    _linkLayerWithBelow(layerId);
                                  }
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _CanvasLayerSheetAction(
                                icon: Icons.filter_b_and_w_rounded,
                                label: 'Layer Mask',
                                enabled: canEdit,
                                onTap: () =>
                                    Navigator.of(context).pop('layer_mask'),
                              ),
                            ),
                            if (layer.isPhoto) ...<Widget>[
                              const SizedBox(width: 8),
                              Expanded(
                                child: _CanvasLayerSheetAction(
                                  icon: Icons.layers_clear_rounded,
                                  label: 'Smart Object',
                                  enabled: canEdit,
                                  onTap: () =>
                                      Navigator.of(context).pop('smart_object'),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        _CanvasLayerSheetAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete Layer',
                          danger: true,
                          enabled: canEdit,
                          onTap: () => Navigator.of(context).pop('delete'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    // Modal results arrive at the start of the reverse transition. Waiting
    // here prevents the next dialog/sheet or editor rebuild from overlapping
    // the route subtree that is still deactivating.
    await Future<void>.delayed(kThemeAnimationDuration);
    if (!mounted) {
      return;
    }
    switch (action) {
      case 'rename':
        await _openRenameLayerDialog(layerId);
      case 'duplicate':
        _duplicateLayerById(layerId);
      case 'layer_mask':
        await _openLayerMaskOptionsSheet(layerId);
      case 'smart_object':
        await _openSmartObjectOptionsSheet(layerId);
      case 'delete':
        _deleteLayerById(layerId);
    }
  }

  Widget _buildCanvasLayerPickerPreview(_CanvasLayer layer) {
    if (layer.isPhoto && layer.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Image.memory(
            layer.bytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            cacheWidth: 64,
          ),
        ),
      );
    }
    final icon = layer.isText
        ? Icons.text_fields_rounded
        : Icons.category_rounded;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: const Color(0xFFE2E8F0), size: 17),
    );
  }

  String _canvasLayerPickerTitle(_CanvasLayer layer) {
    final customName = layer.layerName.trim();
    if (customName.isNotEmpty) {
      return customName;
    }
    if (layer.isPhoto) {
      return 'Photo Layer';
    }
    if (layer.isText) {
      final text = layer.text?.trim();
      return text == null || text.isEmpty ? 'Text Layer' : text;
    }
    return 'Sticker Layer';
  }

  Widget _buildCanvasLayerPickerActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFFE2E8F0),
    bool enabled = true,
  }) {
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(
          icon,
          color: enabled ? color : const Color(0xFF64748B),
          size: 16,
        ),
      ),
    );
  }
}

class _LayerStylePreviewGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 14.0;
    final dark = Paint()..color = const Color(0xFF0B1220);
    final light = Paint()..color = const Color(0xFF101A2B);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final even = ((x / cell).floor() + (y / cell).floor()).isEven;
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), even ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LayerStylePreviewGridPainter oldDelegate) {
    return false;
  }
}

class _LayerStyleHueSlider extends StatefulWidget {
  const _LayerStyleHueSlider({
    required this.hue,
    required this.color,
    required this.onChanged,
    this.onChangeEnd,
  });

  final double hue;
  final Color color;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<_LayerStyleHueSlider> createState() => _LayerStyleHueSliderState();
}

class _LayerStyleHueSliderState extends State<_LayerStyleHueSlider> {
  double? _previewHue;
  double? _previewDx;

  @override
  Widget build(BuildContext context) {
    final hue = (_previewHue ?? widget.hue).clamp(0.0, 360.0).toDouble();
    final previewColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Color',
              style: TextStyle(
                color: _editorChromeTextPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              _hexFromColor(widget.color),
              style: const TextStyle(
                color: _editorChromeTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final previewLeft = ((_previewDx ?? 0) + 8).clamp(0.0, width - 66);
            return SizedBox(
              height: _previewHue == null ? 34 : 104,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _previewHue == null ? 0 : 70,
                    height: 34,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) =>
                          _handle(details.localPosition.dx, width),
                      onPanUpdate: (details) =>
                          _handle(details.localPosition.dx, width),
                      onPanEnd: (_) => _commitAndClearPreview(),
                      onPanCancel: _commitAndClearPreview,
                      onTapDown: (details) =>
                          _handle(details.localPosition.dx, width),
                      onTapUp: (_) => _commitAndClearPreview(),
                      onTapCancel: _commitAndClearPreview,
                      child: CustomPaint(
                        painter: _LayerStyleHueSliderPainter(hue: hue),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  if (_previewHue != null)
                    Positioned(
                      left: previewLeft,
                      top: 0,
                      child: _ColorMagnifierPreview(
                        color: previewColor,
                        hex: _hexFromColor(previewColor),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _handle(double dx, double width) {
    final normalized = (dx / math.max(1.0, width)).clamp(0.0, 1.0);
    final hue = normalized * 360;
    setState(() {
      _previewHue = hue;
      _previewDx = dx.clamp(0.0, width);
    });
    if (widget.onChangeEnd == null) {
      widget.onChanged(hue);
    }
  }

  void _commitAndClearPreview() {
    final hue = _previewHue;
    if (hue != null) {
      widget.onChangeEnd?.call(hue);
    }
    _clearPreview();
  }

  void _clearPreview() {
    if (_previewHue == null && _previewDx == null) {
      return;
    }
    setState(() {
      _previewHue = null;
      _previewDx = null;
    });
  }
}

class _LayerStyleHueSliderPainter extends CustomPainter {
  const _LayerStyleHueSliderPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final trackRect = Rect.fromLTWH(0, 9, size.width, 16);
    final radius = BorderRadius.circular(999);
    final gradient = LinearGradient(
      colors: List<Color>.generate(
        13,
        (index) => HSVColor.fromAHSV(1, index * 30.0, 1, 1).toColor(),
      ),
    );
    canvas.drawRRect(
      radius.toRRect(trackRect),
      Paint()..shader = gradient.createShader(trackRect),
    );
    canvas.drawRRect(
      radius.toRRect(trackRect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    final x = (hue.clamp(0.0, 360.0) / 360.0) * size.width;
    final handle = Offset(x.clamp(8.0, size.width - 8.0), trackRect.center.dy);
    canvas.drawCircle(
      handle,
      10,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      handle,
      8,
      Paint()
        ..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor()
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      handle,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LayerStyleHueSliderPainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

class _CanvasLayerPickerDisplayItem {
  const _CanvasLayerPickerDisplayItem.layer(this.layer)
    : groupId = '',
      groupName = '',
      groupCount = 0;

  const _CanvasLayerPickerDisplayItem.group({
    required this.groupId,
    required this.groupName,
    required this.groupCount,
  }) : layer = null;

  final _CanvasLayer? layer;
  final String groupId;
  final String groupName;
  final int groupCount;
}

class _CanvasLayerPickerGroupHeader extends StatelessWidget {
  const _CanvasLayerPickerGroupHeader({
    required this.groupName,
    required this.groupCount,
    required this.collapsed,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final String groupName;
  final int groupCount;
  final bool collapsed;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(11),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: <Widget>[
                Icon(
                  collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0xFFE2E8F0),
                  size: 18,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.folder_rounded,
                  color: Color(0xFFFACC15),
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    groupName.trim().isEmpty ? 'Group' : groupName.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$groupCount',
                  style: const TextStyle(
                    color: Color(0xFFB6BBC6),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'layers',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _CanvasLayerPickerSimpleRow extends StatelessWidget {
  const _CanvasLayerPickerSimpleRow({
    required this.layer,
    required this.selected,
    required this.canSelect,
    required this.title,
    required this.preview,
    required this.onSelect,
    required this.onVisibilityTap,
    required this.onLockTap,
    required this.onMoreTap,
    required this.dragHandle,
    super.key,
  });

  final _CanvasLayer layer;
  final bool selected;
  final bool canSelect;
  final String title;
  final Widget preview;
  final VoidCallback onSelect;
  final VoidCallback onVisibilityTap;
  final VoidCallback onLockTap;
  final VoidCallback onMoreTap;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final rowOpacity = layer.isLocked ? 0.62 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canSelect ? onSelect : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.13)
                : Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: Opacity(
              opacity: rowOpacity,
              child: Row(
                children: <Widget>[
                  preview,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          layer.isLocked
                              ? 'Locked'
                              : layer.isHidden
                              ? 'Hidden'
                              : layer.clipsToLayerBelow
                              ? 'Clipped'
                              : layer.layerMaskEnabled
                              ? 'Masked'
                              : layer.isSmartObject
                              ? 'Smart'
                              : (layer.isText &&
                                        (layer.textStrokeWidth > 0.001 ||
                                            layer.textShadowOpacity > 0.001 ||
                                            layer.textBackgroundOpacity >
                                                0.001)) ||
                                    (layer.isPhoto &&
                                        layer.photoShadowOpacity > 0.001)
                              ? 'Effects'
                              : layer.groupId.isNotEmpty
                              ? (layer.groupName.trim().isEmpty
                                    ? 'Grouped'
                                    : layer.groupName)
                              : layer.linkGroupId.isNotEmpty
                              ? 'Linked'
                              : selected
                              ? 'Selected'
                              : 'Layer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB6BBC6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LayerPickerRoundAction(
                    icon: layer.isHidden
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: layer.isHidden
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF38BDF8),
                    onTap: onVisibilityTap,
                  ),
                  _LayerPickerRoundAction(
                    icon: layer.isLocked
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    color: layer.isLocked
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFE2E8F0),
                    onTap: onLockTap,
                  ),
                  _LayerPickerRoundAction(
                    icon: Icons.more_vert_rounded,
                    color: const Color(0xFFE2E8F0),
                    onTap: onMoreTap,
                  ),
                  dragHandle,
                  if (selected && !layer.isLocked)
                    const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF38BDF8),
                        size: 16,
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

class _LayerPickerRoundAction extends StatelessWidget {
  const _LayerPickerRoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _CanvasLayerSheetAction extends StatelessWidget {
  const _CanvasLayerSheetAction({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? _editorChromeTextSecondary.withValues(alpha: 0.54)
        : danger
        ? const Color(0xFFF87171)
        : _editorChromeTextPrimary;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.075 : 0.035),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.11 : 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _EditorLayersActions on _ImageEditorScreenState {
  void _activateMagicWandMode() {
    if (_isCommitWorkerBusy) {
      return;
    }
    if (!_hasSelectedPhotoLayer || _isSelectedLayerLocked) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _isMagicWandMode = true;
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
    });
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          context.strings.localized(
            telugu: 'తొలగించాల్సిన రంగుపై ఒకసారి టాప్ చేయండి',
            english: 'Tap the color you want to remove',
          ),
        ),
      ),
    );
  }

  Future<void> _handleMagicWandTap({
    required Offset localPosition,
    required Rect pageRect,
    required Size pageSize,
  }) async {
    if (_isCommitWorkerBusy) {
      return;
    }
    final selectedId = _selectedLayerId;
    final layerIndex = _selectedLayerIndex;
    if (selectedId == null ||
        layerIndex == -1 ||
        !_layers[layerIndex].isPhoto ||
        _layers[layerIndex].isLocked) {
      setState(() => _isMagicWandMode = false);
      return;
    }

    final layer = _layers[layerIndex];
    final sourceBytes = layer.bytes;
    if (sourceBytes == null) {
      setState(() => _isMagicWandMode = false);
      return;
    }

    final layerSize = _layerVisualSize(layer, pageSize);
    final inverse = Matrix4.inverted(Matrix4.copy(layer.transform));
    final localToLayer = MatrixUtils.transformPoint(
      inverse,
      localPosition - pageRect.center,
    );
    final normalizedX =
        (localToLayer.dx + (layerSize.width / 2)) / layerSize.width;
    final normalizedY =
        (localToLayer.dy + (layerSize.height / 2)) / layerSize.height;
    if (normalizedX < 0 ||
        normalizedX > 1 ||
        normalizedY < 0 ||
        normalizedY > 1) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ఫోటో లోపల రంగుపై టాప్ చేయండి',
              english: 'Tap inside the selected photo',
            ),
          ),
        ),
      );
      return;
    }

    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      setState(() => _isMagicWandMode = false);
      return;
    }
    final sampleX =
        ((layer.flipPhotoHorizontally ? 1 - normalizedX : normalizedX) *
                (decoded.width - 1))
            .round()
            .clamp(0, decoded.width - 1);
    final sampleY =
        ((layer.flipPhotoVertically ? 1 - normalizedY : normalizedY) *
                (decoded.height - 1))
            .round()
            .clamp(0, decoded.height - 1);

    final resultBytes = await _runQueuedCommitJob<Uint8List>(
      jobKey: 'magic_wand_$selectedId',
      label: context.strings.localized(
        telugu: 'మ్యాజిక్ వాండ్ పని చేస్తోంది',
        english: 'Applying magic wand',
      ),
      detail: context.strings.localized(
        telugu: 'ఎంచుకున్న రంగు ప్రాంతాన్ని తొలగిస్తోంది',
        english: 'Removing the selected color region',
      ),
      operation: () => compute(_magicWandRemoveColorBytes, <String, Object?>{
        'bytes': sourceBytes,
        'x': sampleX,
        'y': sampleY,
        'tolerance': 42,
        'featherRadius': 3,
      }),
    );
    if (resultBytes == null || !mounted) {
      return;
    }
    final currentIndex = _layers.indexWhere((item) => item.id == selectedId);
    if (currentIndex == -1) {
      return;
    }
    final beforeLayer = _layers[currentIndex];
    final afterLayer = beforeLayer.copyWith(bytes: resultBytes);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[currentIndex] = afterLayer;
      _isMagicWandMode = false;
    });
    _selectedPhotoRenderNotifier.value = null;
  }

  void _activatePhotoEraserMode() {
    if (_isCommitWorkerBusy) {
      return;
    }
    if (!_hasSelectedPhotoLayer || _isSelectedLayerLocked) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _isPhotoEraserMode = true;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isMagicWandMode = false;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.photoEraser;
      _activeMainToolLabel = 'Erase';
    });
    _showEraserBrushCursorPreview();
  }

  void _closePhotoEraserMode() {
    setState(() {
      _isPhotoEraserMode = false;
      _activeInlineMode = _BottomInlineMode.none;
      _eraserStrokePoints.clear();
      _eraserStrokeLayerId = null;
      _eraserStrokeLayerSize = Size.zero;
      _eraserPreviewNotifier.value = null;
      _restoreSelectedLayerToolContextFields();
    });
  }

  void _handlePhotoEraserStart(Offset localPosition, Size layerSize) {
    if (!_isPhotoEraserMode || _isCommitWorkerBusy || layerSize.isEmpty) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null ||
        !_hasSelectedPhotoLayer ||
        _isSelectedLayerLocked) {
      return;
    }
    _eraserStrokeLayerId = selectedId;
    _eraserStrokeLayerSize = layerSize;
    _eraserStrokePoints
      ..clear()
      ..add(_normalizeEraserPoint(localPosition, layerSize));
    _publishEraserPreview();
  }

  void _handlePhotoEraserUpdate(Offset localPosition, Size layerSize) {
    if (!_isPhotoEraserMode ||
        _isCommitWorkerBusy ||
        _eraserStrokeLayerId == null ||
        layerSize.isEmpty) {
      return;
    }
    final nextPoint = _normalizeEraserPoint(localPosition, layerSize);
    final previousPoint = _eraserStrokePoints.isEmpty
        ? null
        : _eraserStrokePoints.last;
    if (previousPoint != null) {
      final pixelDelta = Offset(
        (nextPoint.dx - previousPoint.dx) * layerSize.width,
        (nextPoint.dy - previousPoint.dy) * layerSize.height,
      );
      final pixelDistance = pixelDelta.distance;
      if (pixelDistance < 0.45) {
        return;
      }
      final brushSize = _workspaceBrushSize(_eraserBrushSize);
      final spacing = (brushSize * 0.18).clamp(0.8, 6.0).toDouble();
      final steps = (pixelDistance / spacing).ceil().clamp(1, 96);
      for (var step = 1; step <= steps; step++) {
        _eraserStrokePoints.add(
          Offset.lerp(previousPoint, nextPoint, step / steps)!,
        );
      }
    } else {
      _eraserStrokePoints.add(nextPoint);
    }
    _publishEraserPreview();
  }

  Future<void> _handlePhotoEraserEnd() async {
    if (!_isPhotoEraserMode || _isCommitWorkerBusy) {
      _eraserStrokePoints.clear();
      _eraserStrokeLayerId = null;
      _eraserStrokeLayerSize = Size.zero;
      _eraserPreviewNotifier.value = null;
      return;
    }
    final layerId = _eraserStrokeLayerId;
    final strokePoints = List<Offset>.of(_eraserStrokePoints);
    final strokeLayerSize = _eraserStrokeLayerSize;
    _eraserStrokePoints.clear();
    _eraserStrokeLayerId = null;
    _eraserStrokeLayerSize = Size.zero;
    if (layerId == null || strokePoints.isEmpty) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final layerIndex = _layers.indexWhere((item) => item.id == layerId);
    if (layerIndex == -1 || !_layers[layerIndex].isPhoto) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final layer = _layers[layerIndex];
    final sourceBytes = layer.bytes;
    if (sourceBytes == null) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final flatPoints = <double>[];
    for (final point in strokePoints) {
      flatPoints
        ..add(point.dx.clamp(0.0, 1.0).toDouble())
        ..add(point.dy.clamp(0.0, 1.0).toDouble());
    }
    final brushSize = _workspaceBrushSize(_eraserBrushSize);
    final resultBytes = await _runQueuedCommitJob<Uint8List>(
      jobKey: 'photo_eraser_$layerId',
      label: context.strings.localized(
        telugu: 'ఎరేసర్ అప్లై అవుతోంది',
        english: 'Applying eraser',
      ),
      detail: context.strings.localized(
        telugu: 'ఫోటోలో ఎంచుకున్న భాగాన్ని softగా తొలగిస్తోంది',
        english: 'Softly removing the brushed photo area',
      ),
      operation: () => compute(_erasePhotoBrushBytes, <String, Object?>{
        'bytes': sourceBytes,
        'points': flatPoints,
        'brushSize': brushSize,
        'brushRadiusNormalized': strokeLayerSize.shortestSide <= 0
            ? null
            : (brushSize / 2) / strokeLayerSize.shortestSide,
        'hardness': _eraserHardness,
        'flipX': layer.flipPhotoHorizontally,
        'flipY': layer.flipPhotoVertically,
      }),
    );
    if (resultBytes == null || !mounted) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final currentIndex = _layers.indexWhere((item) => item.id == layerId);
    if (currentIndex == -1) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    final beforeLayer = _layers[currentIndex];
    final afterLayer = beforeLayer.copyWith(bytes: resultBytes);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[currentIndex] = afterLayer;
    });
    _eraserPreviewNotifier.value = null;
    _selectedPhotoRenderNotifier.value = null;
  }

  void _cancelPhotoEraserStroke() {
    _eraserStrokePoints.clear();
    _eraserStrokeLayerId = null;
    _eraserStrokeLayerSize = Size.zero;
    _eraserPreviewNotifier.value = null;
  }

  void _publishEraserPreview() {
    final layerId = _eraserStrokeLayerId;
    if (layerId == null || _eraserStrokePoints.isEmpty) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: layerId,
      points: _eraserStrokePoints,
      brushSize: _eraserBrushSize,
      hardness: _eraserHardness,
    );
  }

  void _showEraserBrushCursorPreview([Offset point = const Offset(0.5, 0.5)]) {
    if (!_isPhotoEraserMode || _isCommitWorkerBusy) {
      return;
    }
    final layerId = _selectedLayerId;
    if (layerId == null || !_hasSelectedPhotoLayer) {
      _eraserPreviewNotifier.value = null;
      return;
    }
    _eraserPreviewNotifier.value = _PhotoEraserPreviewState(
      layerId: layerId,
      points: <Offset>[
        Offset(point.dx.clamp(0.0, 1.0), point.dy.clamp(0.0, 1.0)),
      ],
      brushSize: _eraserBrushSize,
      hardness: _eraserHardness,
    );
  }

  Offset _normalizeEraserPoint(Offset localPosition, Size layerSize) {
    final dx = layerSize.width <= 0 ? 0.0 : localPosition.dx / layerSize.width;
    final dy = layerSize.height <= 0
        ? 0.0
        : localPosition.dy / layerSize.height;
    return Offset(dx.clamp(0.0, 1.0), dy.clamp(0.0, 1.0));
  }

  void _handleSelectedTransformHandlePointerDown() {
    _suppressCanvasTapDown = true;
    _suppressCanvasTapToken++;
    final tokenAtSchedule = _suppressCanvasTapToken;
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (!mounted || _suppressCanvasTapToken != tokenAtSchedule) {
        return;
      }
      _suppressCanvasTapDown = false;
    });
  }

  String? _resolveTopLayerAtPoint({
    required Offset localPosition,
    required Rect pageRect,
    required Size pageSize,
  }) {
    final center = pageRect.center;
    for (final layer in _layers.reversed) {
      if (layer.isHidden || layer.isLocked) {
        continue;
      }
      final layerSize = layer.isText
          ? _textSelectionHitSize(layer, pageSize)
          : _layerVisualSize(layer, pageSize);
      if (layerSize.width <= 0 || layerSize.height <= 0) {
        continue;
      }
      final paddedSize = layer.isText
          ? Size(layerSize.width + 8, layerSize.height + 8)
          : ((layer.isPhoto || layer.isSticker) && layer.id == _selectedLayerId)
          ? Size(layerSize.width + 28, layerSize.height + 28)
          : layerSize;
      final transform = Matrix4.copy(layer.transform);
      final inverse = Matrix4.inverted(transform);
      final localToLayer = MatrixUtils.transformPoint(
        inverse,
        localPosition - center,
      );
      if (layer.id == _selectedLayerId &&
          (layer.isPhoto || layer.isSticker || layer.isText)) {
        final handleHit = layer.isText
            ? ((localToLayer - Offset(0, -layerSize.height / 2)).distance <=
                      18 ||
                  (localToLayer -
                              Offset(
                                layerSize.width / 2,
                                -layerSize.height / 2,
                              ))
                          .distance <=
                      20 ||
                  (localToLayer -
                              Offset(layerSize.width / 2, layerSize.height / 2))
                          .distance <=
                      20)
            : (localToLayer -
                              Offset(
                                layerSize.width / 2,
                                -layerSize.height / 2,
                              ))
                          .distance <=
                      20 ||
                  (localToLayer -
                              Offset(layerSize.width / 2, layerSize.height / 2))
                          .distance <=
                      20 ||
                  (localToLayer - Offset(-layerSize.width / 2, 0)).distance <=
                      16 ||
                  (localToLayer - Offset(layerSize.width / 2, 0)).distance <=
                      16 ||
                  (localToLayer - Offset(0, -layerSize.height / 2)).distance <=
                      16 ||
                  (localToLayer - Offset(0, layerSize.height / 2)).distance <=
                      20;
        if (handleHit) {
          return layer.id;
        }
      }
      final halfWidth = paddedSize.width / 2;
      final halfHeight = paddedSize.height / 2;
      final hit =
          localToLayer.dx >= -halfWidth &&
          localToLayer.dx <= halfWidth &&
          localToLayer.dy >= -halfHeight &&
          localToLayer.dy <= halfHeight;
      if (hit) {
        return layer.id;
      }
    }
    return null;
  }

  Size _layerVisualSize(_CanvasLayer layer, Size pageSize) {
    if (layer.isPhoto) {
      if (layer.fillPageBounds) {
        return pageSize;
      }
      final fixedWidth = layer.photoFixedWidth;
      final fixedHeight = layer.photoFixedHeight;
      if (fixedWidth != null &&
          fixedHeight != null &&
          fixedWidth > 0 &&
          fixedHeight > 0) {
        return Size(fixedWidth, fixedHeight);
      }
      return _fitPhotoLayerSize(
        pageSize: pageSize,
        photoAspectRatio: layer.photoAspectRatio,
      );
    }
    if (layer.isText) {
      final renderFontFamily = _resolveLayerRenderFontFamily(layer);
      final textPadding = _textLayerVisualPadding(layer);
      final viewPadding = _textLayerViewPadding(layer);
      final renderText = _resolveLayerRenderText(layer);
      final renderLineHeight = _effectiveTextLineHeightForRender(
        fontFamily: layer.fontFamily,
        textLineHeight: layer.textLineHeight,
        text: renderText,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: renderText,
          style: TextStyle(
            fontFamily: renderFontFamily,
            fontSize: layer.fontSize,
            height: renderLineHeight,
            letterSpacing: layer.textLetterSpacing,
            fontWeight: layer.isTextBold ? FontWeight.w700 : FontWeight.w500,
            fontStyle: layer.isTextItalic ? FontStyle.italic : FontStyle.normal,
            decoration: layer.isTextUnderline
                ? TextDecoration.underline
                : TextDecoration.none,
            color: layer.textColor,
          ),
        ),
        textAlign: layer.textAlign,
        textDirection: _textDirectionForValue(_resolveLayerRenderText(layer)),
        textScaler: TextScaler.noScaling,
      )..layout();
      return Size(
        painter.size.width + textPadding.horizontal + viewPadding.horizontal,
        painter.size.height + textPadding.vertical + viewPadding.vertical,
      );
    }
    final sticker = layer.sticker;
    if (_EditorTextState._isImageLikeSticker(sticker)) {
      return Size.square(layer.fontSize);
    }
    return _textStickerVisualSize(sticker, layer.fontSize);
  }

  Size _textSelectionHitSize(_CanvasLayer layer, Size pageSize) {
    final visualSize = _layerVisualSize(layer, pageSize);
    return Size(
      math.max(24.0, visualSize.width),
      math.max(24.0, visualSize.height),
    );
  }

  Offset _selectionCenterOffsetForLayer(_CanvasLayer layer, Size pageSize) {
    if (layer.isText) {
      return _workspaceTextSelectionCenterOffset(layer, pageSize);
    }
    if (layer.isPhoto) {
      final photoSize = layer.fillPageBounds
          ? pageSize
          : _photoLayerVisualSize(layer, pageSize);
      final paintRect = _photoVisiblePaintRect(layer, photoSize);
      return paintRect.center -
          Offset(photoSize.width / 2, photoSize.height / 2);
    }
    return Offset.zero;
  }

  Size _selectionBoxSizeForLayer(_CanvasLayer layer, Size pageSize) {
    if (layer.isText) {
      return _workspaceTextSelectionBoxSize(layer, pageSize);
    }
    if (layer.isPhoto) {
      final photoSize = layer.fillPageBounds
          ? pageSize
          : _photoLayerVisualSize(layer, pageSize);
      return _photoVisiblePaintRect(layer, photoSize).size;
    }
    return _layerVisualSize(layer, pageSize);
  }

  Matrix4 _transformAroundLayerSelectionCenter(
    _CanvasLayer layer,
    Matrix4 base, {
    double scaleX = 1,
    double scaleY = 1,
    double rotation = 0,
  }) {
    final centerOffset = _selectionCenterOffsetForLayer(
      layer,
      _currentStageLogicalRect().size,
    );
    final updated = Matrix4.copy(base);
    if (centerOffset != Offset.zero) {
      updated.translateByDouble(centerOffset.dx, centerOffset.dy, 0, 1);
    }
    if (rotation.abs() > 0.0001) {
      updated.rotateZ(rotation);
    }
    if ((scaleX - 1).abs() > 0.0001 || (scaleY - 1).abs() > 0.0001) {
      updated.scaleByDouble(scaleX, scaleY, 1, 1);
    }
    if (centerOffset != Offset.zero) {
      updated.translateByDouble(-centerOffset.dx, -centerOffset.dy, 0, 1);
    }
    return updated;
  }

  void _beginNativeSelectionTransform(
    _CanvasLayer selected,
    Offset handleGlobalPosition,
  ) {
    _stopPhotoGlide(sync: false);
    _cancelSelectedTextLongPress();
    _gestureStartMatrix = Matrix4.copy(_transformationController.value);
    _transformHandleStartCenterGlobal = _selectedTransformCenterGlobal(
      layer: selected,
      matrix: _gestureStartMatrix,
    );
    final vector = handleGlobalPosition - _transformHandleStartCenterGlobal;
    _stickerHandleStartAngle = math.atan2(vector.dy, vector.dx);
    _stickerHandleStartDistance = math.max(vector.distance, 1).toDouble();
    _objectSideResizeAxisGlobal = _stickerHandleStartDistance <= 0.001
        ? Offset.zero
        : vector / _stickerHandleStartDistance;
    _textStretchStartGlobalPosition = handleGlobalPosition;
    _photoGestureVelocity = Offset.zero;
    _snapGuideNotifier.value = const _SnapGuideState.none();
    _beginGroupTransformSession(selected);
    _isLayerInteracting = true;
  }

  Matrix4? _nativeSelectionTransformFromDrag(
    _CanvasLayer selected,
    Offset handleGlobalPosition, {
    bool resizeUniform = false,
    bool resizeHorizontal = false,
    bool resizeVertical = false,
    Offset? resizeAxisGlobal,
    bool rotate = false,
    bool stretchVertical = false,
  }) {
    final base = _gestureStartMatrix ?? _transformationController.value;
    final center = _transformHandleStartCenterGlobal;
    if (center == Offset.zero) {
      return null;
    }
    if (rotate) {
      final vector = handleGlobalPosition - center;
      final angle = math.atan2(vector.dy, vector.dx);
      final angleDelta = _shortestAngleDelta(
        from: _stickerHandleStartAngle,
        to: angle,
      );
      final baseRotation = _matrixRotationZ(base);
      final snappedRotation = _softSnapRotation(baseRotation + angleDelta);
      final updated = _transformAroundLayerSelectionCenter(
        selected,
        base,
        rotation: snappedRotation - baseRotation,
      );
      return _isMatrixFinite(updated) ? updated : null;
    }

    var scaleX = 1.0;
    var scaleY = 1.0;
    if (stretchVertical) {
      scaleY =
          (1 +
                  ((_textStretchStartGlobalPosition.dy -
                          handleGlobalPosition.dy) /
                      140.0))
              .clamp(0.25, 5.0)
              .toDouble();
    } else {
      final vector = handleGlobalPosition - center;
      final axis = resizeAxisGlobal;
      final distance = axis == null || axis.distance <= 0.001
          ? math.max(vector.distance, 1)
          : math.max((vector.dx * axis.dx) + (vector.dy * axis.dy), 1);
      final ratio = (distance / _stickerHandleStartDistance)
          .clamp(0.25, 8.0)
          .toDouble();
      if (resizeUniform) {
        scaleX = ratio;
        scaleY = ratio;
      } else if (resizeHorizontal) {
        scaleX = ratio;
      } else if (resizeVertical) {
        scaleY = ratio;
      }
    }
    final updated = _transformAroundLayerSelectionCenter(
      selected,
      base,
      scaleX: scaleX,
      scaleY: scaleY,
    );
    return _isMatrixFinite(updated) ? updated : null;
  }

  Matrix4 _clampLayerTransformToPageBounds(
    _CanvasLayer layer,
    Matrix4 candidate,
  ) {
    final pageSize = _currentStageLogicalRect().size;
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      return candidate;
    }
    final layerSize = _selectionBoxSizeForLayer(layer, pageSize);
    if (layerSize.width <= 0 || layerSize.height <= 0) {
      return candidate;
    }
    final centerOffset = _selectionCenterOffsetForLayer(layer, pageSize);

    final pageRect = Rect.fromCenter(
      center: Offset.zero,
      width: pageSize.width,
      height: pageSize.height,
    );

    Rect transformedBounds(Matrix4 matrix) {
      final halfWidth = layerSize.width / 2;
      final halfHeight = layerSize.height / 2;
      final points =
          <Offset>[
            Offset(-halfWidth, -halfHeight),
            Offset(halfWidth, -halfHeight),
            Offset(halfWidth, halfHeight),
            Offset(-halfWidth, halfHeight),
          ].map(
            (point) => MatrixUtils.transformPoint(matrix, point + centerOffset),
          );
      var left = double.infinity;
      var top = double.infinity;
      var right = double.negativeInfinity;
      var bottom = double.negativeInfinity;
      for (final point in points) {
        left = math.min(left, point.dx);
        top = math.min(top, point.dy);
        right = math.max(right, point.dx);
        bottom = math.max(bottom, point.dy);
      }
      return Rect.fromLTRB(left, top, right, bottom);
    }

    var matrix = Matrix4.copy(candidate);
    var bounds = transformedBounds(matrix);
    final minVisibleWidth = math.min(
      bounds.width,
      math.min(36.0, pageRect.width * 0.18),
    );
    final minVisibleHeight = math.min(
      bounds.height,
      math.min(36.0, pageRect.height * 0.18),
    );
    var dx = 0.0;
    var dy = 0.0;
    if (bounds.right < pageRect.left + minVisibleWidth) {
      dx = (pageRect.left + minVisibleWidth) - bounds.right;
    } else if (bounds.left > pageRect.right - minVisibleWidth) {
      dx = (pageRect.right - minVisibleWidth) - bounds.left;
    }
    if (bounds.bottom < pageRect.top + minVisibleHeight) {
      dy = (pageRect.top + minVisibleHeight) - bounds.bottom;
    } else if (bounds.top > pageRect.bottom - minVisibleHeight) {
      dy = (pageRect.bottom - minVisibleHeight) - bounds.top;
    }
    if (dx.abs() > 0.0001 || dy.abs() > 0.0001) {
      matrix.setTranslationRaw(
        matrix.storage[12] + dx,
        matrix.storage[13] + dy,
        matrix.storage[14],
      );
    }
    return matrix;
  }

  Matrix4 _fitTextTransformToPageBounds(_CanvasLayer layer, Matrix4 candidate) {
    final pageSize = _currentStageLogicalRect().size;
    if (!layer.isText || pageSize.width <= 4 || pageSize.height <= 4) {
      return candidate;
    }
    final layerSize = _workspaceTextSelectionBoxSize(layer, pageSize);
    final centerOffset = _workspaceTextSelectionCenterOffset(layer, pageSize);
    if (layerSize.width <= 0 || layerSize.height <= 0) {
      return candidate;
    }
    final pageRect = Rect.fromCenter(
      center: Offset.zero,
      width: pageSize.width - 4,
      height: pageSize.height - 4,
    );

    Rect transformedBounds(Matrix4 matrix) {
      final halfWidth = layerSize.width / 2;
      final halfHeight = layerSize.height / 2;
      final points =
          <Offset>[
            Offset(-halfWidth, -halfHeight),
            Offset(halfWidth, -halfHeight),
            Offset(halfWidth, halfHeight),
            Offset(-halfWidth, halfHeight),
          ].map(
            (point) => MatrixUtils.transformPoint(matrix, point + centerOffset),
          );
      var left = double.infinity;
      var top = double.infinity;
      var right = double.negativeInfinity;
      var bottom = double.negativeInfinity;
      for (final point in points) {
        left = math.min(left, point.dx);
        top = math.min(top, point.dy);
        right = math.max(right, point.dx);
        bottom = math.max(bottom, point.dy);
      }
      return Rect.fromLTRB(left, top, right, bottom);
    }

    final matrix = Matrix4.copy(candidate);
    var bounds = transformedBounds(matrix);
    if (bounds.width > pageRect.width || bounds.height > pageRect.height) {
      final scale = math
          .min(pageRect.width / bounds.width, pageRect.height / bounds.height)
          .clamp(0.05, 1.0)
          .toDouble();
      matrix.scaleByDouble(scale, scale, 1, 1);
      bounds = transformedBounds(matrix);
    }

    var dx = 0.0;
    var dy = 0.0;
    if (bounds.left < pageRect.left) {
      dx = pageRect.left - bounds.left;
    } else if (bounds.right > pageRect.right) {
      dx = pageRect.right - bounds.right;
    }
    if (bounds.top < pageRect.top) {
      dy = pageRect.top - bounds.top;
    } else if (bounds.bottom > pageRect.bottom) {
      dy = pageRect.bottom - bounds.bottom;
    }
    if (dx.abs() > 0.0001 || dy.abs() > 0.0001) {
      matrix.setTranslationRaw(
        matrix.storage[12] + dx,
        matrix.storage[13] + dy,
        matrix.storage[14],
      );
    }
    return matrix;
  }

  void _clearSelection() {
    if (_selectedTextFocusNode.hasFocus) {
      _selectedTextFocusNode.unfocus();
    }
    _commitSelectedTextContentEdit();
    _cancelSelectedTextLongPress();
    _resetGroupTransformSession();
    _lastSelectedTextTapAt = null;
    _lastSelectedTextTapLayerId = null;
    if (_selectedLayerId == null &&
        !_isAdjustMode &&
        !_isPhotoEraserMode &&
        !_isContentAwareMode &&
        !_isPhotoCloneMode &&
        !_isLayerMaskBrushMode &&
        _activeBottomPrimaryTool == _BottomPrimaryTool.none &&
        !_snapGuides.isVisible) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    _snapGuideNotifier.value = const _SnapGuideState.none();
    setState(() {
      _selectedLayerId = null;
      _showSelectedLayerHandles = false;
      _isTextPlacementMode = false;
      _showTextControls = false;
      _isAdjustMode = false;
      _isPhotoEraserMode = false;
      _isPhotoStretchMode = false;
      _isContentAwareMode = false;
      _isPhotoCloneMode = false;
      _isDrawBrushMode = false;
      _isLayerMaskBrushMode = false;
      _isLayerMaskBrushRestoreMode = false;
      _adjustSessionLayerId = null;
      _eraserStrokePoints.clear();
      _contentAwareStrokePoints.clear();
      _cloneStrokePoints = <Offset>[];
      _clonePreviewStampPoints = <Offset>[];
      _stretchStrokePoints.clear();
      _layerMaskStrokePoints.clear();
      _drawStrokes.clear();
      _drawRedoStrokes.clear();
      _drawActivePoints = null;
      _eraserStrokeLayerId = null;
      _contentAwareStrokeLayerId = null;
      _cloneStrokeLayerId = null;
      _stretchStrokeLayerId = null;
      _layerMaskStrokeLayerId = null;
      _eraserStrokeLayerSize = Size.zero;
      _contentAwareStrokeLayerSize = Size.zero;
      _cloneStrokeLayerSize = Size.zero;
      _cloneSourcePoint = null;
      _cloneAlignedSampleOffset = null;
      _stretchStrokeLayerSize = Size.zero;
      _layerMaskStrokeLayerSize = Size.zero;
      _eraserPreviewNotifier.value = null;
      _drawPreviewNotifier.value = null;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _activeInlineMode = _BottomInlineMode.none;
    });
    _syncSelectedTextEditor();
  }

  void _updateSmartGuides(Matrix4 matrix) {
    final currentX = matrix.storage[12];
    final currentY = matrix.storage[13];
    final shouldSnapX =
        currentX.abs() <= _ImageEditorScreenState._snapThreshold;
    final shouldSnapY =
        currentY.abs() <= _ImageEditorScreenState._snapThreshold;

    final nextState = _SnapGuideState(
      showVerticalGuide: shouldSnapX,
      showHorizontalGuide: shouldSnapY,
    );
    if (_snapGuideNotifier.value != nextState) {
      _snapGuideNotifier.value = nextState;
    }
  }

  void _updateRotationSnapGuide(double rotationAngle) {
    final nextState = _SnapGuideState(
      showVerticalGuide: false,
      showHorizontalGuide: false,
      rotationGuideAngle: _rotationSnapGuideAngle(rotationAngle),
    );
    if (_snapGuideNotifier.value != nextState) {
      _snapGuideNotifier.value = nextState;
    }
  }

  void _applyLiveSelectedTransform(
    Matrix4 transform, {
    double? rotationGuideAngle,
    bool updateGuides = false,
  }) {
    _transformationController.value = transform;
    if (!updateGuides) {
      return;
    }
    if (rotationGuideAngle != null) {
      _updateRotationSnapGuide(rotationGuideAngle);
    } else {
      _updateSmartGuides(transform);
    }
  }

  void _resetGroupTransformSession() {
    _groupTransformStartTransforms.clear();
    _groupTransformUndoPushed = false;
    _groupTransformSessionId = null;
    _groupTransformSelectedLayerId = null;
  }

  String _transformCohortIdForLayer(_CanvasLayer layer) {
    final linkGroupId = layer.linkGroupId.trim();
    if (linkGroupId.isNotEmpty) {
      return 'link:$linkGroupId';
    }
    final groupId = layer.groupId.trim();
    if (groupId.isNotEmpty) {
      return 'group:$groupId';
    }
    return '';
  }

  bool _isLayerInTransformCohort(_CanvasLayer layer, String cohortId) =>
      !layer.isLocked && _transformCohortIdForLayer(layer) == cohortId;

  bool _beginGroupTransformSession(_CanvasLayer selectedLayer) {
    final cohortId = _transformCohortIdForLayer(selectedLayer);
    if (cohortId.isEmpty || selectedLayer.isLocked) {
      _resetGroupTransformSession();
      return false;
    }
    if (_groupTransformSessionId == cohortId &&
        _groupTransformSelectedLayerId == selectedLayer.id &&
        _groupTransformStartTransforms.isNotEmpty) {
      return true;
    }
    _groupTransformStartTransforms
      ..clear()
      ..addEntries(
        _layers
            .where((layer) => _isLayerInTransformCohort(layer, cohortId))
            .map(
              (layer) => MapEntry<String, Matrix4>(
                layer.id,
                Matrix4.copy(layer.transform),
              ),
            ),
      );
    if (!_groupTransformStartTransforms.containsKey(selectedLayer.id)) {
      _resetGroupTransformSession();
      return false;
    }
    _groupTransformUndoPushed = false;
    _groupTransformSessionId = cohortId;
    _groupTransformSelectedLayerId = selectedLayer.id;
    return _groupTransformStartTransforms.length > 1;
  }

  Matrix4? _groupTransformDeltaForSelected(
    _CanvasLayer selectedLayer,
    Matrix4 selectedTransform,
  ) {
    if (!_beginGroupTransformSession(selectedLayer)) {
      return null;
    }
    final selectedStart = _groupTransformStartTransforms[selectedLayer.id];
    if (selectedStart == null || !_isMatrixFinite(selectedTransform)) {
      return null;
    }
    try {
      final inverseStart = Matrix4.inverted(Matrix4.copy(selectedStart));
      final delta = Matrix4.copy(selectedTransform)..multiply(inverseStart);
      return _isMatrixFinite(delta) ? delta : null;
    } catch (_) {
      return null;
    }
  }

  bool _previewGroupedLayerTransform(
    _CanvasLayer selectedLayer,
    Matrix4 selectedTransform,
  ) {
    final delta = _groupTransformDeltaForSelected(
      selectedLayer,
      selectedTransform,
    );
    if (delta == null) {
      return false;
    }
    var changed = false;
    final nextLayers = List<_CanvasLayer>.of(_layers);
    for (var i = 0; i < nextLayers.length; i++) {
      final layer = nextLayers[i];
      if (layer.id == selectedLayer.id ||
          _groupTransformSessionId == null ||
          !_isLayerInTransformCohort(layer, _groupTransformSessionId!)) {
        continue;
      }
      final startTransform = _groupTransformStartTransforms[layer.id];
      if (startTransform == null) {
        continue;
      }
      final transformed = Matrix4.copy(delta)..multiply(startTransform);
      if (!_isMatrixFinite(transformed)) {
        continue;
      }
      final bounded = _clampLayerTransformToPageBounds(layer, transformed);
      if (_isSameMatrix(layer.transform, bounded)) {
        continue;
      }
      nextLayers[i] = layer.copyWith(transform: Matrix4.copy(bounded));
      changed = true;
    }
    if (!changed) {
      return false;
    }
    if (!_groupTransformUndoPushed) {
      _pushUndoSnapshot();
      _groupTransformUndoPushed = true;
    }
    setState(() {
      for (var i = 0; i < _layers.length; i++) {
        _layers[i] = nextLayers[i];
      }
    });
    return true;
  }

  bool _commitGroupedLayerTransform(
    _CanvasLayer selectedLayer,
    Matrix4 selectedTransform,
  ) {
    final delta = _groupTransformDeltaForSelected(
      selectedLayer,
      selectedTransform,
    );
    if (delta == null) {
      _resetGroupTransformSession();
      return false;
    }
    final selectedStart = _groupTransformStartTransforms[selectedLayer.id];
    final selectedChanged =
        selectedStart != null &&
        !_isSameMatrix(selectedStart, selectedTransform);
    var changed = selectedChanged;
    final nextLayers = List<_CanvasLayer>.of(_layers);
    for (var i = 0; i < nextLayers.length; i++) {
      final layer = nextLayers[i];
      if (_groupTransformSessionId == null ||
          !_isLayerInTransformCohort(layer, _groupTransformSessionId!)) {
        continue;
      }
      final startTransform = _groupTransformStartTransforms[layer.id];
      if (startTransform == null) {
        continue;
      }
      final nextTransform = layer.id == selectedLayer.id
          ? selectedTransform
          : (Matrix4.copy(delta)..multiply(startTransform));
      if (!_isMatrixFinite(nextTransform)) {
        continue;
      }
      final bounded = _clampLayerTransformToPageBounds(layer, nextTransform);
      if (!_isSameMatrix(layer.transform, bounded)) {
        changed = true;
      }
      nextLayers[i] = layer.copyWith(transform: Matrix4.copy(bounded));
    }
    if (!changed) {
      _resetGroupTransformSession();
      return false;
    }
    if (!_groupTransformUndoPushed) {
      _pushUndoSnapshot();
      _groupTransformUndoPushed = true;
    }
    setState(() {
      _isLayerInteracting = false;
      for (var i = 0; i < _layers.length; i++) {
        _layers[i] = nextLayers[i];
      }
    });
    _resetGroupTransformSession();
    return true;
  }

  void _syncSelectedLayerTransform() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      _resetGroupTransformSession();
      if (_isLayerInteracting) {
        setState(() {
          _isLayerInteracting = false;
        });
      }
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1) {
      _resetGroupTransformSession();
      if (_isLayerInteracting) {
        setState(() {
          _isLayerInteracting = false;
        });
      }
      return;
    }
    final beforeLayer = _layers[index];
    final current = beforeLayer.transform;
    final updated = _clampLayerTransformToPageBounds(
      beforeLayer,
      _transformationController.value,
    );
    if (!_isSameMatrix(_transformationController.value, updated)) {
      _transformationController.value = Matrix4.copy(updated);
    }
    if (_isSameMatrix(current, updated)) {
      if (_isLayerInteracting ||
          _snapGuideNotifier.value != const _SnapGuideState.none()) {
        _snapGuideNotifier.value = const _SnapGuideState.none();
        setState(() {
          _isLayerInteracting = false;
        });
      }
      _resetGroupTransformSession();
      return;
    }

    final afterLayer = beforeLayer.copyWith(transform: Matrix4.copy(updated));
    _snapGuideNotifier.value = const _SnapGuideState.none();
    final transformCohortId = _transformCohortIdForLayer(beforeLayer);
    if (transformCohortId.isNotEmpty) {
      if (_commitGroupedLayerTransform(beforeLayer, afterLayer.transform)) {
        return;
      }
    }
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _isLayerInteracting = false;
      _layers[index] = afterLayer;
    });
  }

  void _handleSelectedLayerInteractionStart(ScaleStartDetails details) {
    if (_isWorkspacePinching || _isSelectedLayerLocked) {
      return;
    }
    final selectedLayer = _selectedLayer;
    if (selectedLayer == null) {
      return;
    }
    if (_isPhotoMaskPositionMode &&
        selectedLayer.isPhoto &&
        selectedLayer.photoMaskShape.trim().isNotEmpty) {
      _photoMaskEditBeforeLayer = _cloneLayer(selectedLayer);
      _photoGestureLastFocalPoint = details.focalPoint;
      _photoGestureLastScale = 1;
      _isLayerInteracting = true;
      return;
    }
    if (_selectedTextFocusNode.hasFocus) {
      _selectedTextFocusNode.unfocus();
    }
    _stopPhotoGlide(sync: false);
    _cancelSelectedTextLongPress();
    _gestureStartMatrix = Matrix4.copy(_transformationController.value);
    _gestureStartFocalPoint = details.focalPoint;
    _gestureStartLocalFocalPoint = details.localFocalPoint;
    _photoGestureLastFocalPoint = details.focalPoint;
    _photoGestureLastScale = 1;
    _photoGestureLastRotation = 0;
    _photoGestureVelocity = Offset.zero;
    _photoGestureLastTimestampMicros = DateTime.now().microsecondsSinceEpoch;
    _beginGroupTransformSession(selectedLayer);
    if (!_isLayerInteracting) {
      setState(() {
        _isLayerInteracting = true;
      });
    }
  }

  Offset _selectedTransformCenterGlobal({
    _CanvasLayer? layer,
    Matrix4? matrix,
  }) {
    final renderObject = _stageRepaintKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return Offset.zero;
    }
    final selected = layer ?? _selectedLayer;
    if (selected == null) {
      return Offset.zero;
    }
    final stageRect = _currentStageLogicalRect();
    final effectiveMatrix = matrix ?? _transformationController.value;
    final centerOffset = _selectionCenterOffsetForLayer(
      selected,
      stageRect.size,
    );
    final centerInStage =
        stageRect.center +
        MatrixUtils.transformPoint(effectiveMatrix, centerOffset);
    return renderObject.localToGlobal(centerInStage);
  }

  void _handleSelectedStickerResizeHandleStart(DragStartDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto) ||
        _isSelectedLayerLocked) {
      return;
    }
    _beginNativeSelectionTransform(selected, details.globalPosition);
  }

  void _handleSelectedStickerResizeHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto) ||
        _isSelectedLayerLocked) {
      return;
    }
    final updated = _nativeSelectionTransformFromDrag(
      selected,
      details.globalPosition,
      resizeUniform: true,
      resizeAxisGlobal: _objectSideResizeAxisGlobal,
    );
    if (updated == null) {
      return;
    }
    _applyLiveSelectedTransform(updated);
  }

  void _handleSelectedObjectHorizontalResizeHandleStart(
    DragStartDetails details,
  ) {
    _handleSelectedObjectSideResizeHandleStart(details, resizeHorizontal: true);
  }

  void _handleSelectedObjectHorizontalResizeHandleUpdate(
    DragUpdateDetails details,
  ) {
    _handleSelectedObjectSideResizeHandleUpdate(details);
  }

  void _handleSelectedObjectVerticalResizeHandleStart(
    DragStartDetails details,
  ) {
    _handleSelectedObjectSideResizeHandleStart(
      details,
      resizeHorizontal: false,
    );
  }

  void _handleSelectedObjectVerticalResizeHandleUpdate(
    DragUpdateDetails details,
  ) {
    _handleSelectedObjectSideResizeHandleUpdate(details);
  }

  void _handleSelectedObjectSideResizeHandleStart(
    DragStartDetails details, {
    required bool resizeHorizontal,
  }) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto || selected.isText) ||
        _isSelectedLayerLocked) {
      return;
    }
    _objectSideResizeHorizontal = resizeHorizontal;
    _beginNativeSelectionTransform(selected, details.globalPosition);
    final center = _transformHandleStartCenterGlobal;
    final vector = details.globalPosition - center;
    final distance = math.max(vector.distance, 1).toDouble();
    _objectSideResizeAxisGlobal = vector / distance;
    _stickerHandleStartDistance = distance;
  }

  void _handleSelectedObjectSideResizeHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto || selected.isText) ||
        _isSelectedLayerLocked) {
      return;
    }
    final updated = _nativeSelectionTransformFromDrag(
      selected,
      details.globalPosition,
      resizeHorizontal: _objectSideResizeHorizontal,
      resizeVertical: !_objectSideResizeHorizontal,
      resizeAxisGlobal: _objectSideResizeAxisGlobal,
    );
    if (updated == null) {
      return;
    }
    _applyLiveSelectedTransform(updated);
  }

  void _handleSelectedStickerRotateHandleStart(DragStartDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto) ||
        _isSelectedLayerLocked) {
      return;
    }
    _beginNativeSelectionTransform(selected, details.globalPosition);
  }

  void _handleSelectedStickerRotateHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto) ||
        _isSelectedLayerLocked) {
      return;
    }
    final updated = _nativeSelectionTransformFromDrag(
      selected,
      details.globalPosition,
      rotate: true,
    );
    if (updated == null) {
      return;
    }
    final snappedRotation = _matrixRotationZ(updated);
    _applyLiveSelectedTransform(
      updated,
      rotationGuideAngle: snappedRotation,
      updateGuides: true,
    );
  }

  void _handleSelectedTextResizeHandleStart(DragStartDetails details) {
    final selected = _selectedLayer;
    if (selected == null || !selected.isText || _isSelectedLayerLocked) {
      return;
    }
    _beginNativeSelectionTransform(selected, details.globalPosition);
  }

  void _handleSelectedTextResizeHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null || !selected.isText || _isSelectedLayerLocked) {
      return;
    }
    final updated = _nativeSelectionTransformFromDrag(
      selected,
      details.globalPosition,
      resizeUniform: true,
      resizeAxisGlobal: _objectSideResizeAxisGlobal,
    );
    if (updated == null) {
      return;
    }
    _applyLiveSelectedTransform(updated);
  }

  void _handleSelectedTextRotateHandleStart(DragStartDetails details) {
    final selected = _selectedLayer;
    if (selected == null || !selected.isText || _isSelectedLayerLocked) {
      return;
    }
    _beginNativeSelectionTransform(selected, details.globalPosition);
  }

  void _handleSelectedTextRotateHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null || !selected.isText || _isSelectedLayerLocked) {
      return;
    }
    final updated = _nativeSelectionTransformFromDrag(
      selected,
      details.globalPosition,
      rotate: true,
    );
    if (updated == null) {
      return;
    }
    final snappedRotation = _matrixRotationZ(updated);
    _applyLiveSelectedTransform(
      updated,
      rotationGuideAngle: snappedRotation,
      updateGuides: true,
    );
  }

  void _handleSelectedTextStretchHandleStart(DragStartDetails details) {
    final selected = _selectedLayer;
    if (selected == null || !selected.isText || _isSelectedLayerLocked) {
      return;
    }
    _beginNativeSelectionTransform(selected, details.globalPosition);
  }

  void _handleSelectedTextStretchHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null || !selected.isText || _isSelectedLayerLocked) {
      return;
    }
    final updated = _nativeSelectionTransformFromDrag(
      selected,
      details.globalPosition,
      stretchVertical: true,
    );
    if (updated == null) {
      return;
    }
    _applyLiveSelectedTransform(updated);
  }

  void _handleSelectedStickerHandleEnd() {
    final selected = _selectedLayer;
    if (selected != null && selected.isText) {
      final fitted = _fitTextTransformToPageBounds(
        selected,
        _transformationController.value,
      );
      if (!_isSameMatrix(_transformationController.value, fitted)) {
        _transformationController.value = fitted;
        _previewGroupedLayerTransform(selected, fitted);
      }
    }
    _handleSelectedLayerInteractionEnd();
  }

  void _handleSelectedLayerScaleUpdate(ScaleUpdateDetails details) {
    if (_isWorkspacePinching ||
        _selectedLayerId == null ||
        _isSelectedLayerLocked) {
      return;
    }
    final selectedLayer = _selectedLayer;
    if (selectedLayer == null) {
      return;
    }
    if (_isPhotoMaskPositionMode &&
        selectedLayer.isPhoto &&
        selectedLayer.photoMaskShape.trim().isNotEmpty) {
      final index = _selectedLayerIndex;
      if (index == -1) {
        return;
      }
      final delta = details.focalPoint - _photoGestureLastFocalPoint;
      final scaleRatio =
          (_photoGestureLastScale <= 0
                  ? 1.0
                  : details.scale / _photoGestureLastScale)
              .clamp(0.5, 2.0)
              .toDouble();
      final current = _layers[index];
      setState(() {
        _layers[index] = current.copyWith(
          photoMaskOffsetX: (current.photoMaskOffsetX + (delta.dx * 0.45))
              .clamp(-100.0, 100.0)
              .toDouble(),
          photoMaskOffsetY: (current.photoMaskOffsetY + (delta.dy * 0.45))
              .clamp(-100.0, 100.0)
              .toDouble(),
          photoMaskScale: (current.photoMaskScale * scaleRatio)
              .clamp(0.5, 2.5)
              .toDouble(),
        );
      });
      _photoGestureLastFocalPoint = details.focalPoint;
      _photoGestureLastScale = details.scale;
      return;
    }
    final base = Matrix4.copy(
      _gestureStartMatrix ?? _transformationController.value,
    );
    final updated = Matrix4.copy(base);

    if (selectedLayer.isPhoto || selectedLayer.isSticker) {
      final incremental = Matrix4.copy(_transformationController.value);
      final moveDelta = details.focalPoint - _photoGestureLastFocalPoint;
      final nowMicros = DateTime.now().microsecondsSinceEpoch;
      final elapsedMicros = _photoGestureLastTimestampMicros == 0
          ? 0
          : nowMicros - _photoGestureLastTimestampMicros;
      _photoGestureLastTimestampMicros = nowMicros;

      // One-finger transform drag follows the finger in screen-space only.
      if (details.pointerCount < 2) {
        if (moveDelta.distanceSquared < 0.04) {
          _photoGestureLastFocalPoint = details.focalPoint;
          return;
        }
        incremental.setTranslationRaw(
          incremental.storage[12] + moveDelta.dx,
          incremental.storage[13] + moveDelta.dy,
          incremental.storage[14],
        );
        if (!_isMatrixFinite(incremental)) {
          return;
        }
        final clamped = _clampLayerTransformToPageBounds(
          selectedLayer,
          incremental,
        );
        _transformationController.value = clamped;
        _previewGroupedLayerTransform(selectedLayer, clamped);
        _updateSmartGuides(clamped);
        if (elapsedMicros > 0) {
          final dtSeconds = elapsedMicros / Duration.microsecondsPerSecond;
          final instantVelocity = Offset(
            moveDelta.dx / dtSeconds,
            moveDelta.dy / dtSeconds,
          );
          _photoGestureVelocity = Offset(
            (_photoGestureVelocity.dx * 0.72) + (instantVelocity.dx * 0.28),
            (_photoGestureVelocity.dy * 0.72) + (instantVelocity.dy * 0.28),
          );
        }
        _photoGestureLastFocalPoint = details.focalPoint;
        _photoGestureLastScale = details.scale;
        _photoGestureLastRotation = details.rotation;
        return;
      }

      // Two-finger transform uses incremental deltas to avoid jumps when
      // fingers are added/removed or focal point shifts between frames.
      final scaleDelta = (details.scale - _photoGestureLastScale).abs();
      final rotationDeltaRaw = (details.rotation - _photoGestureLastRotation)
          .abs();
      if (moveDelta.distanceSquared < 0.01 &&
          scaleDelta < 0.001 &&
          rotationDeltaRaw < 0.001) {
        _photoGestureLastFocalPoint = details.focalPoint;
        _photoGestureLastScale = details.scale;
        _photoGestureLastRotation = details.rotation;
        return;
      }
      final scaleRatio =
          (_photoGestureLastScale == 0
                  ? 1.0
                  : details.scale / _photoGestureLastScale)
              .clamp(0.2, 8.0)
              .toDouble();
      final rotationDelta = details.rotation - _photoGestureLastRotation;
      final currentRotation = _matrixRotationZ(incremental);
      final targetRotation = currentRotation + rotationDelta;
      final snappedRotation = _softSnapRotation(targetRotation);
      final appliedRotationDelta = snappedRotation - currentRotation;

      incremental.setTranslationRaw(
        incremental.storage[12] + moveDelta.dx,
        incremental.storage[13] + moveDelta.dy,
        incremental.storage[14],
      );
      final focal = details.localFocalPoint;
      incremental.translateByDouble(focal.dx, focal.dy, 0, 1);
      if (appliedRotationDelta.abs() > 0.0001) {
        incremental.rotateZ(appliedRotationDelta);
      }
      if ((scaleRatio - 1).abs() > 0.0001) {
        incremental.scaleByDouble(scaleRatio, scaleRatio, 1, 1);
      }
      incremental.translateByDouble(-focal.dx, -focal.dy, 0, 1);

      if (!_isMatrixFinite(incremental)) {
        return;
      }
      final clamped = _clampLayerTransformToPageBounds(
        selectedLayer,
        incremental,
      );
      _transformationController.value = clamped;
      _previewGroupedLayerTransform(selectedLayer, clamped);
      final rotationGuideAngle = _rotationSnapGuideAngle(targetRotation);
      if (rotationGuideAngle != null || rotationDelta.abs() > 0.0001) {
        _updateRotationSnapGuide(snappedRotation);
      } else {
        _updateSmartGuides(clamped);
      }
      _photoGestureLastFocalPoint = details.focalPoint;
      _photoGestureLastScale = details.scale;
      _photoGestureLastRotation = details.rotation;
      _photoGestureVelocity = Offset.zero;
      _photoGestureLastTimestampMicros = nowMicros;
      return;
    }

    if (selectedLayer.isText && details.pointerCount < 2) {
      final incremental = Matrix4.copy(_transformationController.value);
      final moveDelta = details.focalPoint - _photoGestureLastFocalPoint;
      if (moveDelta.distanceSquared < 0.04) {
        _photoGestureLastFocalPoint = details.focalPoint;
        return;
      }
      incremental.setTranslationRaw(
        incremental.storage[12] + moveDelta.dx,
        incremental.storage[13] + moveDelta.dy,
        incremental.storage[14],
      );
      if (!_isMatrixFinite(incremental)) {
        return;
      }
      final clamped = _clampLayerTransformToPageBounds(
        selectedLayer,
        incremental,
      );
      _transformationController.value = clamped;
      _previewGroupedLayerTransform(selectedLayer, clamped);
      _updateSmartGuides(clamped);
      _photoGestureLastFocalPoint = details.focalPoint;
      _photoGestureLastScale = details.scale;
      _photoGestureLastRotation = details.rotation;
      return;
    }

    // Non-transform layers keep the existing gesture flow.

    final effectiveBase = Matrix4.copy(
      _gestureStartMatrix ?? _transformationController.value,
    );
    final effectiveDelta = details.focalPoint - _gestureStartFocalPoint;
    updated.setFrom(effectiveBase);
    updated.translateByDouble(effectiveDelta.dx, effectiveDelta.dy, 0, 1);

    final focal = _gestureStartLocalFocalPoint;
    final baseRotation = _matrixRotationZ(effectiveBase);
    final targetRotation = baseRotation + details.rotation;
    final snappedRotation = _softSnapRotation(targetRotation);
    final deltaRotation = snappedRotation - baseRotation;

    updated.translateByDouble(focal.dx, focal.dy, 0, 1);
    if (deltaRotation.abs() > 0.0001) {
      updated.rotateZ(deltaRotation);
    }
    final scale = details.scale.clamp(0.2, 8.0).toDouble();
    if ((scale - 1).abs() > 0.0001) {
      updated.scaleByDouble(scale, scale, 1, 1);
    }
    updated.translateByDouble(-focal.dx, -focal.dy, 0, 1);

    if (!_isMatrixFinite(updated)) {
      return;
    }

    final clamped = _clampLayerTransformToPageBounds(selectedLayer, updated);
    _transformationController.value = clamped;
    _previewGroupedLayerTransform(selectedLayer, clamped);
    final rotationGuideAngle = _rotationSnapGuideAngle(targetRotation);
    if (rotationGuideAngle != null || details.rotation.abs() > 0.0001) {
      _updateRotationSnapGuide(snappedRotation);
    } else {
      _updateSmartGuides(clamped);
    }
  }

  void _handleSelectedLayerInteractionEnd() {
    if (_isSelectedLayerLocked) {
      _resetGroupTransformSession();
      if (_isLayerInteracting) {
        setState(() {
          _isLayerInteracting = false;
        });
      }
      return;
    }
    final selectedLayer = _selectedLayer;
    if (_isPhotoMaskPositionMode && selectedLayer?.isPhoto == true) {
      final beforeLayer = _photoMaskEditBeforeLayer;
      if (beforeLayer != null &&
          selectedLayer != null &&
          beforeLayer.id == selectedLayer.id &&
          _didLayerChange(beforeLayer, selectedLayer)) {
        _pushLayerHistoryEntry(
          beforeLayer: beforeLayer,
          afterLayer: _cloneLayer(selectedLayer),
        );
      }
      _photoMaskEditBeforeLayer = null;
      _photoGestureLastFocalPoint = Offset.zero;
      _photoGestureLastScale = 1;
      _isLayerInteracting = false;
      return;
    }
    if ((selectedLayer?.isPhoto ?? false) ||
        (selectedLayer?.isSticker ?? false)) {
      _photoGestureVelocity = Offset.zero;
      _photoGlideTotalTravel = Offset.zero;
      _photoGlideAppliedTravel = Offset.zero;
      _photoGlideController.stop();
      _syncSelectedLayerTransform();
    } else {
      _syncSelectedLayerTransform();
    }
    _gestureStartMatrix = null;
    _gestureStartFocalPoint = Offset.zero;
    _gestureStartLocalFocalPoint = Offset.zero;
    _photoGestureLastFocalPoint = Offset.zero;
    _photoGestureLastScale = 1;
    _photoGestureLastRotation = 0;
    _stickerHandleStartAngle = 0;
    _stickerHandleStartDistance = 1;
    _transformHandleStartCenterGlobal = Offset.zero;
    _textStretchStartGlobalPosition = Offset.zero;
    _objectSideResizeAxisGlobal = Offset.zero;
    _objectSideResizeHorizontal = true;
    _photoGestureVelocity = Offset.zero;
    _photoGestureLastTimestampMicros = 0;
    if (_pendingAutosave) {
      _scheduleAutosave();
    }
  }

  void _resetSelectedLayerToFit() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    _syncSelectedLayerTransform();
  }

  void _toggleSelectedPhotoFlip({required bool horizontal}) {
    if (_isSelectedLayerLocked) {
      return;
    }
    final index = _selectedLayerIndex;
    if (index == -1 || !_layers[index].isPhoto) {
      return;
    }
    final beforeLayer = _layers[index];
    final afterLayer = horizontal
        ? beforeLayer.copyWith(
            flipPhotoHorizontally: !beforeLayer.flipPhotoHorizontally,
          )
        : beforeLayer.copyWith(
            flipPhotoVertically: !beforeLayer.flipPhotoVertically,
          );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _flipSelectedPhotoHorizontal() {
    _toggleSelectedPhotoFlip(horizontal: true);
  }

  void _flipSelectedPhotoVertical() {
    _toggleSelectedPhotoFlip(horizontal: false);
  }

  void _rotateSelectedLayer90Degrees() {
    if (_isSelectedLayerLocked) {
      return;
    }
    final index = _selectedLayerIndex;
    if (index == -1) {
      return;
    }
    final beforeLayer = _layers[index];
    final nextTransform = Matrix4.copy(beforeLayer.transform)
      ..rotateZ(math.pi / 2);
    final clampedTransform = _clampLayerTransformToPageBounds(
      beforeLayer,
      nextTransform,
    );
    if (_isSameMatrix(beforeLayer.transform, clampedTransform)) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(transform: clampedTransform);
    if (_transformCohortIdForLayer(beforeLayer).isNotEmpty &&
        _commitGroupedLayerTransform(beforeLayer, afterLayer.transform)) {
      _transformationController.value = Matrix4.copy(clampedTransform);
      _snapGuideNotifier.value = const _SnapGuideState(
        showVerticalGuide: false,
        showHorizontalGuide: false,
        rotationGuideAngle: 0,
      );
      return;
    }
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
      _transformationController.value = Matrix4.copy(clampedTransform);
      _snapGuideNotifier.value = const _SnapGuideState(
        showVerticalGuide: false,
        showHorizontalGuide: false,
        rotationGuideAngle: 0,
      );
    });
  }

  void _setSelectedPhotoMaskShape(String shape) {
    if (_isSelectedLayerLocked) {
      return;
    }
    final index = _selectedLayerIndex;
    if (index == -1 || !_layers[index].isPhoto) {
      return;
    }
    final normalizedShape = shape.trim();
    final beforeLayer = _layers[index];
    if (beforeLayer.photoMaskShape == normalizedShape) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      photoMaskShape: normalizedShape,
      photoAspectRatio: normalizedShape.isEmpty
          ? beforeLayer.photoAspectRatio
          : _editorPhotoMaskAspectRatio(normalizedShape),
    );
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _beginSelectedPhotoMaskEdit(double _) {
    final layer = _selectedLayer;
    if (layer == null || !layer.isPhoto || _isSelectedLayerLocked) {
      return;
    }
    if (_photoMaskEditBeforeLayer?.id != layer.id) {
      _photoMaskEditBeforeLayer = _cloneLayer(layer);
    }
  }

  void _endSelectedPhotoMaskEdit(double _) {
    final beforeLayer = _photoMaskEditBeforeLayer;
    final selectedLayer = _selectedLayer;
    if (beforeLayer != null &&
        selectedLayer != null &&
        beforeLayer.id == selectedLayer.id &&
        _didLayerChange(beforeLayer, selectedLayer)) {
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: _cloneLayer(selectedLayer),
      );
    }
    _photoMaskEditBeforeLayer = null;
  }

  void _setSelectedPhotoMaskScale(double value) {
    _setSelectedPhotoMaskTuning(
      photoMaskScale: value.clamp(0.5, 2.5).toDouble(),
    );
  }

  void _setSelectedPhotoMaskOffsetX(double value) {
    _setSelectedPhotoMaskTuning(
      photoMaskOffsetX: value.clamp(-100, 100).toDouble(),
    );
  }

  void _setSelectedPhotoMaskOffsetY(double value) {
    _setSelectedPhotoMaskTuning(
      photoMaskOffsetY: value.clamp(-100, 100).toDouble(),
    );
  }

  void _setSelectedPhotoMaskFeather(double value) {
    _setSelectedPhotoMaskTuning(
      photoMaskFeather: value.clamp(0, 100).toDouble(),
    );
  }

  void _setSelectedPhotoMaskTuning({
    double? photoMaskScale,
    double? photoMaskOffsetX,
    double? photoMaskOffsetY,
    double? photoMaskFeather,
  }) {
    if (_isSelectedLayerLocked) {
      return;
    }
    final index = _selectedLayerIndex;
    if (index == -1 || !_layers[index].isPhoto) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        photoMaskScale: photoMaskScale,
        photoMaskOffsetX: photoMaskOffsetX,
        photoMaskOffsetY: photoMaskOffsetY,
        photoMaskFeather: photoMaskFeather,
      );
    });
  }

  Future<void> _openPhotoMaskPickerOverlay() async {
    if (!_hasSelectedPhotoLayer || _isSelectedLayerLocked) {
      return;
    }
    final masks = <({String label, String shape, IconData icon})>[
      (label: 'Original', shape: '', icon: Icons.image_outlined),
      (label: 'Circle', shape: 'circle', icon: Icons.circle_outlined),
      (label: 'Square', shape: 'square', icon: Icons.crop_square_rounded),
      (label: 'Rounded', shape: 'rounded', icon: Icons.rounded_corner_rounded),
      (label: 'Oval', shape: 'oval', icon: Icons.egg_outlined),
      (label: 'Heart', shape: 'heart', icon: Icons.favorite_border_rounded),
      (label: 'Star', shape: 'star', icon: Icons.star_border_rounded),
      (label: 'Hexagon', shape: 'hexagon', icon: Icons.hexagon_outlined),
      (label: 'Diamond', shape: 'diamond', icon: Icons.diamond_outlined),
      (label: 'Arch', shape: 'arch', icon: Icons.architecture_rounded),
      (label: 'Blob', shape: 'blob', icon: Icons.blur_on_rounded),
      (label: 'Fade', shape: 'transparent_bottom_fade', icon: Icons.gradient),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedLayer = _selectedLayer;
            final selectedShape = selectedLayer?.photoMaskShape.trim() ?? '';
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.crop_square_rounded,
                              color: _editorChromeTextPrimary,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Shape crop / Mask',
                              style: TextStyle(
                                color: _editorChromeTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            _EditorIconButton(
                              icon: Icons.close_rounded,
                              tooltip: 'Close',
                              onTap: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.94,
                              ),
                          itemCount: masks.length,
                          itemBuilder: (context, index) {
                            final mask = masks[index];
                            final selected = selectedShape == mask.shape;
                            final preview = Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    Color(0xFF38BDF8),
                                    Color(0xFF7C3AED),
                                    Color(0xFFF97316),
                                  ],
                                ),
                              ),
                            );
                            return _PressableSurface(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _setSelectedPhotoMaskShape(mask.shape);
                                setSheetState(() {});
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(
                                          0xFF6D5DFB,
                                        ).withValues(alpha: 0.26)
                                      : Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFC4B5FD)
                                        : Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: Center(
                                        child: mask.shape.isEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: preview,
                                              )
                                            : _EditorPhotoMaskFrame(
                                                shape: mask.shape,
                                                scale: 1,
                                                offsetX: 0,
                                                offsetY: 0,
                                                feather: 0,
                                                child: preview,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mask.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFFF5F3FF)
                                            : _editorChromeTextSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (selectedLayer != null &&
                            selectedShape.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Mask fine tune',
                            style: TextStyle(
                              color: _editorChromeTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _CompactLabeledSlider(
                            sliderId: 'mask-scale',
                            label: 'Scale',
                            value: (selectedLayer.photoMaskScale * 100)
                                .clamp(50, 250)
                                .toDouble(),
                            min: 50,
                            max: 250,
                            divisions: 200,
                            valueText:
                                '${(selectedLayer.photoMaskScale * 100).round()}%',
                            onChangeStart: _beginSelectedPhotoMaskEdit,
                            onChanged: (value) {
                              _setSelectedPhotoMaskScale(value / 100);
                              setSheetState(() {});
                            },
                            onChangeEnd: _endSelectedPhotoMaskEdit,
                          ),
                          const SizedBox(height: 8),
                          _CompactLabeledSlider(
                            sliderId: 'mask-offset-x',
                            label: 'Move X',
                            value: selectedLayer.photoMaskOffsetX
                                .clamp(-100, 100)
                                .toDouble(),
                            min: -100,
                            max: 100,
                            divisions: 200,
                            valueText: selectedLayer.photoMaskOffsetX
                                .round()
                                .toString(),
                            onChangeStart: _beginSelectedPhotoMaskEdit,
                            onChanged: (value) {
                              _setSelectedPhotoMaskOffsetX(value);
                              setSheetState(() {});
                            },
                            onChangeEnd: _endSelectedPhotoMaskEdit,
                          ),
                          const SizedBox(height: 8),
                          _CompactLabeledSlider(
                            sliderId: 'mask-offset-y',
                            label: 'Move Y',
                            value: selectedLayer.photoMaskOffsetY
                                .clamp(-100, 100)
                                .toDouble(),
                            min: -100,
                            max: 100,
                            divisions: 200,
                            valueText: selectedLayer.photoMaskOffsetY
                                .round()
                                .toString(),
                            onChangeStart: _beginSelectedPhotoMaskEdit,
                            onChanged: (value) {
                              _setSelectedPhotoMaskOffsetY(value);
                              setSheetState(() {});
                            },
                            onChangeEnd: _endSelectedPhotoMaskEdit,
                          ),
                          const SizedBox(height: 8),
                          _CompactLabeledSlider(
                            sliderId: 'mask-feather',
                            label: 'Feather',
                            value: selectedLayer.photoMaskFeather
                                .clamp(0, 100)
                                .toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            valueText: selectedLayer.photoMaskFeather
                                .round()
                                .toString(),
                            onChangeStart: _beginSelectedPhotoMaskEdit,
                            onChanged: (value) {
                              _setSelectedPhotoMaskFeather(value);
                              setSheetState(() {});
                            },
                            onChangeEnd: _endSelectedPhotoMaskEdit,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSelectedPhotoStyleOverlay() async {
    final selected = _selectedLayer;
    if (selected == null || !selected.isPhoto || selected.isLocked) {
      return;
    }
    final beforeLayer = _cloneLayer(selected);
    final layerId = selected.id;

    void updatePhotoStyle({
      double? opacity,
      double? shadowOpacity,
      double? shadowBlur,
      double? shadowOffsetY,
    }) {
      final index = _layers.indexWhere((item) => item.id == layerId);
      if (index == -1 || !_layers[index].isPhoto || _layers[index].isLocked) {
        return;
      }
      setState(() {
        _layers[index] = _layers[index].copyWith(
          photoOpacity: opacity?.clamp(0.0, 1.0).toDouble(),
          photoShadowOpacity: shadowOpacity?.clamp(0.0, 1.0).toDouble(),
          photoShadowBlur: shadowBlur?.clamp(0.0, 100.0).toDouble(),
          photoShadowOffsetY: shadowOffsetY?.clamp(-100.0, 100.0).toDouble(),
        );
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final current = _layers.cast<_CanvasLayer?>().firstWhere(
              (item) => item?.id == layerId,
              orElse: () => null,
            );
            if (current == null) {
              return const SizedBox.shrink();
            }

            Widget slider({
              required String label,
              required double value,
              required double min,
              required double max,
              required ValueChanged<double> onChanged,
            }) {
              return Row(
                children: <Widget>[
                  SizedBox(
                    width: 92,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _editorChromeTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: value.clamp(min, max).toDouble(),
                      min: min,
                      max: max,
                      divisions: 100,
                      onChanged: (next) {
                        onChanged(next);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      value.round().toString(),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _editorChromeTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            }

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
                            const Icon(
                              Icons.opacity_rounded,
                              color: _editorChromeTextPrimary,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Photo style',
                              style: TextStyle(
                                color: _editorChromeTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            _EditorIconButton(
                              icon: Icons.restart_alt_rounded,
                              tooltip: 'Reset',
                              onTap: () {
                                updatePhotoStyle(
                                  opacity: 1,
                                  shadowOpacity: 0,
                                  shadowBlur: 0,
                                  shadowOffsetY: 0,
                                );
                                setSheetState(() {});
                              },
                            ),
                            _EditorIconButton(
                              icon: Icons.close_rounded,
                              tooltip: 'Close',
                              onTap: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        slider(
                          label: 'Opacity',
                          value: current.photoOpacity * 100,
                          min: 0,
                          max: 100,
                          onChanged: (value) =>
                              updatePhotoStyle(opacity: value / 100),
                        ),
                        slider(
                          label: 'Shadow',
                          value: current.photoShadowOpacity * 100,
                          min: 0,
                          max: 100,
                          onChanged: (value) =>
                              updatePhotoStyle(shadowOpacity: value / 100),
                        ),
                        slider(
                          label: 'Blur',
                          value: current.photoShadowBlur,
                          min: 0,
                          max: 100,
                          onChanged: (value) =>
                              updatePhotoStyle(shadowBlur: value),
                        ),
                        slider(
                          label: 'Offset',
                          value: current.photoShadowOffsetY,
                          min: -100,
                          max: 100,
                          onChanged: (value) =>
                              updatePhotoStyle(shadowOffsetY: value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) {
      return;
    }
    final afterLayer = _layers[index];
    final changed =
        (beforeLayer.photoOpacity - afterLayer.photoOpacity).abs() > 0.0001 ||
        (beforeLayer.photoShadowOpacity - afterLayer.photoShadowOpacity).abs() >
            0.0001 ||
        (beforeLayer.photoShadowBlur - afterLayer.photoShadowBlur).abs() >
            0.0001 ||
        (beforeLayer.photoShadowOffsetY - afterLayer.photoShadowOffsetY).abs() >
            0.0001;
    if (changed) {
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: _cloneLayer(afterLayer),
      );
    }
  }

  Future<void> _openSelectedPhotoPerspectiveOverlay() async {
    final selected = _selectedLayer;
    if (selected == null || !selected.isPhoto || selected.isLocked) {
      return;
    }
    final beforeLayer = _cloneLayer(selected);
    final layerId = selected.id;
    _isLayerInteracting = true;

    void updatePerspective({double? horizontal, double? vertical}) {
      final index = _layers.indexWhere((item) => item.id == layerId);
      if (index == -1 || !_layers[index].isPhoto || _layers[index].isLocked) {
        return;
      }
      setState(() {
        _layers[index] = _layers[index].copyWith(
          photoPerspectiveX: horizontal?.clamp(-100.0, 100.0).toDouble(),
          photoPerspectiveY: vertical?.clamp(-100.0, 100.0).toDouble(),
        );
      });
    }

    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final current = _layers.cast<_CanvasLayer?>().firstWhere(
              (item) => item?.id == layerId,
              orElse: () => null,
            );
            if (current == null) {
              return const SizedBox.shrink();
            }

            Widget slider({
              required String label,
              required IconData icon,
              required double value,
              required ValueChanged<double> onChanged,
            }) {
              return Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: _editorChromeTextSecondary),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 76,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: _editorChromeTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: value.clamp(-100.0, 100.0).toDouble(),
                      min: -100,
                      max: 100,
                      divisions: 200,
                      onChanged: (next) {
                        onChanged(next);
                        setSheetState(() {});
                      },
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
                        fontWeight: FontWeight.w700,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

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
                            const Icon(
                              Icons.view_in_ar_outlined,
                              color: _editorChromeTextPrimary,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.strings.localized(
                                telugu: 'పర్స్పెక్టివ్',
                                english: 'Perspective',
                              ),
                              style: const TextStyle(
                                color: _editorChromeTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            _EditorIconButton(
                              icon: Icons.restart_alt_rounded,
                              tooltip: 'Reset',
                              onTap: () {
                                updatePerspective(horizontal: 0, vertical: 0);
                                setSheetState(() {});
                              },
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(false),
                              child: Text(
                                context.strings.localized(
                                  telugu: 'రద్దు',
                                  english: 'Cancel',
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(true),
                              child: Text(
                                context.strings.localized(
                                  telugu: 'అప్లై',
                                  english: 'Apply',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        slider(
                          label: context.strings.localized(
                            telugu: 'అడ్డంగా',
                            english: 'Horizontal',
                          ),
                          icon: Icons.swap_horiz_rounded,
                          value: current.photoPerspectiveX,
                          onChanged: (value) =>
                              updatePerspective(horizontal: value),
                        ),
                        slider(
                          label: context.strings.localized(
                            telugu: 'నిలువుగా',
                            english: 'Vertical',
                          ),
                          icon: Icons.swap_vert_rounded,
                          value: current.photoPerspectiveY,
                          onChanged: (value) =>
                              updatePerspective(vertical: value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _isLayerInteracting = false;
    if (!mounted) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) {
      return;
    }
    if (applied != true) {
      setState(() => _layers[index] = beforeLayer);
      return;
    }
    final afterLayer = _layers[index];
    final changed =
        (beforeLayer.photoPerspectiveX - afterLayer.photoPerspectiveX).abs() >
            0.0001 ||
        (beforeLayer.photoPerspectiveY - afterLayer.photoPerspectiveY).abs() >
            0.0001;
    if (changed) {
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: _cloneLayer(afterLayer),
      );
      _scheduleAutosave();
    }
  }

  void _handlePhotoGlideTick() {
    if (!_photoGlideController.isAnimating) {
      return;
    }
    final progress = Curves.easeOutCubic.transform(_photoGlideController.value);
    final nextTravel = Offset(
      _photoGlideTotalTravel.dx * progress,
      _photoGlideTotalTravel.dy * progress,
    );
    final delta = nextTravel - _photoGlideAppliedTravel;
    if (delta.distanceSquared <= 0) {
      return;
    }
    final incremental = Matrix4.copy(_transformationController.value);
    incremental.setTranslationRaw(
      incremental.storage[12] + delta.dx,
      incremental.storage[13] + delta.dy,
      incremental.storage[14],
    );
    if (!_isMatrixFinite(incremental)) {
      return;
    }
    _photoGlideAppliedTravel = nextTravel;
    final selected = _selectedLayer;
    _transformationController.value = selected == null
        ? incremental
        : _clampLayerTransformToPageBounds(selected, incremental);
  }

  void _stopPhotoGlide({required bool sync}) {
    if (!_photoGlideController.isAnimating &&
        _photoGlideAppliedTravel == Offset.zero &&
        _photoGlideTotalTravel == Offset.zero) {
      return;
    }
    _photoGlideController.stop();
    _photoGlideAppliedTravel = Offset.zero;
    _photoGlideTotalTravel = Offset.zero;
    if (sync) {
      _syncSelectedLayerTransform();
    }
  }

  void _handleDeleteSelectedLayer() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    _deleteLayerById(selectedId);
  }

  Future<BackgroundRemovalResult> _removeBackgroundForCurrentUser(
    Uint8List sourceBytes,
  ) async {
    await _backgroundRemoverInitialization;
    return _backgroundRemovalService.removeBackground(sourceBytes);
  }

  Future<void> _handleRemoveBackgroundTap() async {
    if (_isRemovingBackground || _isCommitWorkerBusy) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }
    if (!_hasSelectedPhotoLayer) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ముందు ఒక ఫోటో ఎంచుకోండి',
              english: 'Select a photo first',
            ),
          ),
        ),
      );
      return;
    }

    final taskId = ++_removeBackgroundTaskId;
    final initialLayerIndex = _layers.indexWhere(
      (item) => item.id == selectedId,
    );
    if (initialLayerIndex == -1) {
      return;
    }

    final layer = _layers[initialLayerIndex];
    final sourceBytes = layer.bytes;
    if (sourceBytes == null) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'బ్యాక్‌గ్రౌండ్ తీసేయడానికి సోర్స్ ఫోటో అందుబాటులో లేదు',
              english: 'Source photo unavailable for Remove BG',
            ),
          ),
        ),
      );
      return;
    }

    final rewardedAccessGranted = await _ensureRewardedAccessForFeature(
      _EditorRewardGateFeature.removeBackground,
    );
    if (!mounted || !rewardedAccessGranted) {
      return;
    }

    try {
      final result = await _runQueuedCommitJob<BackgroundRemovalResult>(
        jobKey: 'remove_bg_$taskId',
        label: context.strings.localized(
          telugu: 'బ్యాక్‌గ్రౌండ్ తొలగిస్తోంది',
          english: 'Removing background',
        ),
        detail: context.strings.localized(
          telugu: 'ఎంచుకున్న ఫోటో లేయర్‌ను ఏఐ ప్రాసెస్ చేస్తోంది',
          english: 'AI is processing the selected photo layer',
        ),
        onStart: () {
          _isRemovingBackground = true;
        },
        onFinish: () {
          _isRemovingBackground = false;
        },
        operation: () async {
          return _removeBackgroundForCurrentUser(sourceBytes);
        },
      );
      if (result == null || !mounted || taskId != _removeBackgroundTaskId) {
        return;
      }

      final layerIndex = _layers.indexWhere((item) => item.id == selectedId);
      if (layerIndex == -1) {
        return;
      }
      final beforeLayer = _layers[layerIndex];
      final afterLayer = beforeLayer.copyWith(bytes: result.pngBytes);
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
      setState(() {
        _layers[layerIndex] = afterLayer;
      });
      return;
    } catch (error) {
      if (!mounted || taskId != _removeBackgroundTaskId) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'బ్యాక్‌గ్రౌండ్ తీసేయడానికి సోర్స్ ఫోటో అందుబాటులో లేదు',
              english: 'Remove BG failed: ${error.toString()}',
            ),
          ),
        ),
      );
      return;
    }
  }

  void _handleDuplicateSelectedLayer() {
    final index = _selectedLayerIndex;
    if (index == -1) {
      return;
    }
    _duplicateLayerById(_layers[index].id);
  }

  void _duplicateLayerById(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index == -1) {
      return;
    }
    final current = _layers[index];
    if (current.isLocked) {
      return;
    }
    final duplicatedTransform = Matrix4.copy(current.transform);
    duplicatedTransform.storage[12] += 12;
    duplicatedTransform.storage[13] += 12;
    final clampedTransform = _clampLayerTransformToPageBounds(
      current,
      duplicatedTransform,
    );
    final duplicated = current.copyWith(
      id: 'layer_${_layerSeed++}',
      layerName: current.layerName.trim().isEmpty
          ? ''
          : '${current.layerName.trim()} copy',
      transform: clampedTransform,
    );

    _pushLayerInsertHistoryEntry(
      layer: duplicated,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: duplicated.id,
    );
    setState(() {
      _layers.add(duplicated);
      _selectedLayerId = duplicated.id;
      _transformationController.value = Matrix4.copy(duplicated.transform);
    });
  }

  void _alignSelectedLayerToPageCenter({required bool horizontal}) {
    if (_isSelectedLayerLocked) {
      return;
    }
    final index = _selectedLayerIndex;
    if (index == -1) {
      return;
    }
    final beforeLayer = _layers[index];
    final nextTransform = Matrix4.copy(beforeLayer.transform);
    if (horizontal) {
      nextTransform.storage[12] = 0;
    } else {
      nextTransform.storage[13] = 0;
    }
    final clampedTransform = _clampLayerTransformToPageBounds(
      beforeLayer,
      nextTransform,
    );
    if (_isSameMatrix(beforeLayer.transform, clampedTransform)) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(transform: clampedTransform);
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    setState(() {
      _layers[index] = afterLayer;
      _transformationController.value = Matrix4.copy(clampedTransform);
      _snapGuideNotifier.value = _SnapGuideState(
        showVerticalGuide: horizontal,
        showHorizontalGuide: !horizontal,
      );
    });
  }

  void _alignSelectedLayerHorizontalCenter() {
    _alignSelectedLayerToPageCenter(horizontal: true);
  }

  void _alignSelectedLayerVerticalCenter() {
    _alignSelectedLayerToPageCenter(horizontal: false);
  }

  void _moveSelectedLayerToFront() {
    final index = _selectedLayerIndex;
    if (index == -1 || index == _layers.length - 1) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null || _layers[index].isLocked) {
      return;
    }

    _pushLayerReorderHistoryEntry(
      layerId: selectedId,
      fromIndex: index,
      toIndex: _layers.length - 1,
      beforeSelectedLayerId: selectedId,
      afterSelectedLayerId: selectedId,
    );
    setState(() {
      final layer = _layers.removeAt(index);
      _layers.add(layer);
      _selectedLayerId = selectedId;
      _transformationController.value = Matrix4.copy(layer.transform);
    });
  }

  void _moveSelectedLayerToBack() {
    final index = _selectedLayerIndex;
    if (index <= 0) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null || _layers[index].isLocked) {
      return;
    }

    _pushLayerReorderHistoryEntry(
      layerId: selectedId,
      fromIndex: index,
      toIndex: 0,
      beforeSelectedLayerId: selectedId,
      afterSelectedLayerId: selectedId,
    );
    setState(() {
      final layer = _layers.removeAt(index);
      _layers.insert(0, layer);
      _selectedLayerId = selectedId;
      _transformationController.value = Matrix4.copy(layer.transform);
    });
  }

  void _deleteLayerById(String layerId) {
    final index = _layers.indexWhere((item) => item.id == layerId);
    if (index == -1) {
      return;
    }
    final layer = _layers[index];
    if (layer.isLocked) {
      return;
    }
    String? nextSelectedLayerId = _selectedLayerId;
    if (_selectedLayerId == layerId) {
      if (_layers.length == 1) {
        nextSelectedLayerId = null;
      } else {
        nextSelectedLayerId = index == _layers.length - 1
            ? _layers[_layers.length - 2].id
            : _layers.last.id;
      }
    }
    _pushLayerDeleteHistoryEntry(
      layer: layer,
      deletedIndex: index,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: nextSelectedLayerId,
    );
    setState(() {
      _layers.removeAt(index);
      if (_layers.isEmpty) {
        _selectedLayerId = null;
        _transformationController.value = Matrix4.identity();
      } else {
        if (_selectedLayerId == layerId) {
          _selectedLayerId = nextSelectedLayerId;
        }
        if (_selectedLayerId != null) {
          final currentIndex = _layers.indexWhere(
            (item) => item.id == _selectedLayerId,
          );
          if (currentIndex != -1) {
            _transformationController.value = Matrix4.copy(
              _layers[currentIndex].transform,
            );
            final selectedLayer = _layers[currentIndex];
            if (!selectedLayer.isText) {
              _showTextControls = false;
              if (_activeBottomPrimaryTool == _BottomPrimaryTool.text) {
                _activeBottomPrimaryTool = _BottomPrimaryTool.none;
              }
            }
          } else {
            final fallback = _layers.last;
            _selectedLayerId = fallback.id;
            _transformationController.value = Matrix4.copy(fallback.transform);
            if (!fallback.isText) {
              _showTextControls = false;
              if (_activeBottomPrimaryTool == _BottomPrimaryTool.text) {
                _activeBottomPrimaryTool = _BottomPrimaryTool.none;
              }
            }
          }
        } else {
          _transformationController.value = Matrix4.identity();
          _showTextControls = false;
          if (_activeBottomPrimaryTool == _BottomPrimaryTool.text) {
            _activeBottomPrimaryTool = _BottomPrimaryTool.none;
          }
        }
      }
    });
  }

  Future<void> _handleAddPhoto() async {
    if (_isPickingMedia) {
      return;
    }
    _isPickingMedia = true;
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (!mounted || pickedFiles.isEmpty) {
        return;
      }
      for (final pickedFile in pickedFiles) {
        if (!mounted) return;
        await _importPickedPhoto(pickedFile);
      }
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _handleAddPhotoFromCamera() async {
    await _handleAddPhotoFromSource(ImageSource.camera);
  }

  Future<void> _handleImportDesignFile() async {
    if (_isPickingMedia) {
      return;
    }
    _isPickingMedia = true;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: false,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final picked = result.files.single;
      final path = picked.path;
      final extension = (picked.extension ?? '')
          .trim()
          .toLowerCase()
          .replaceFirst('.', '');
      if (path == null || path.isEmpty) {
        return;
      }
      await _importDesignFilePath(path, extension: extension);
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _importInitialDesignFile(String path) async {
    if (!mounted || path.trim().isEmpty) {
      return;
    }
    final normalizedPath = path.trim();
    final extension = normalizedPath.split('.').last.toLowerCase();
    if (const <String>{
      'jpg',
      'jpeg',
      'png',
      'webp',
      'bmp',
      'gif',
      'heic',
      'heif',
    }.contains(extension)) {
      await _importPickedPhoto(XFile(normalizedPath), asFullPage: true);
      return;
    }
    await _importDesignFilePath(path);
  }

  Future<void> _importDesignFilePath(String path, {String? extension}) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return;
    }
    final pathParts = normalizedPath.split('.');
    final normalizedExtension = (extension ?? pathParts.last)
        .trim()
        .toLowerCase()
        .replaceFirst('.', '');
    if (normalizedExtension == 'psd') {
      await _importPsdFile(File(normalizedPath));
    }
  }

  Future<void> _importPsdFile(File file) async {
    if (!await _canImportDesignFile(file, label: 'PSD')) {
      return;
    }
    final decoded = await _runDesignImportTask<Map<String, Object?>?>(
      message: 'Importing PSD layers...',
      task: () async {
        final rawBytes = await file.readAsBytes();
        return compute(_decodePsdToEditorPayload, rawBytes);
      },
    );
    if (!mounted) {
      return;
    }
    final error = decoded?['error'] as String?;
    if (decoded == null || error != null) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(error ?? 'PSD file import failed. Try another PSD.'),
        ),
      );
      return;
    }
    final width = decoded['width'] as int? ?? 0;
    final height = decoded['height'] as int? ?? 0;
    final rawLayers = decoded['layers'] as List<Object?>? ?? const <Object?>[];
    if (width <= 0 || height <= 0 || rawLayers.isEmpty) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: const Text('PSD file has no readable layers.'),
        ),
      );
      return;
    }
    final importedLayers = <_CanvasLayer>[];
    for (final rawLayer in rawLayers) {
      if (rawLayer is! Map) {
        continue;
      }
      final bytes = rawLayer['bytes'];
      if (bytes is! Uint8List || bytes.isEmpty) {
        continue;
      }
      final name = (rawLayer['name'] as String? ?? '').trim();
      final opacity = (rawLayer['opacity'] as num?)?.toDouble() ?? 1.0;
      final layerAspectRatio = _psdLayerAspectRatioFromPayload(
        rawLayer,
        fallbackAspectRatio: width / height,
      );
      final layerSize = _psdLayerFixedSizeFromPayload(
        rawLayer,
        psdWidth: width,
        psdHeight: height,
      );
      importedLayers.add(
        _CanvasLayer(
          id: 'layer_${_layerSeed++}',
          type: _CanvasLayerType.photo,
          layerName: name.isEmpty ? 'PSD Layer' : name,
          bytes: bytes,
          originalPhotoBytes: bytes,
          photoAspectRatio: layerAspectRatio,
          photoFixedWidth: layerSize?.width,
          photoFixedHeight: layerSize?.height,
          psdEditableText: (rawLayer['psdEditableText'] as String?)?.trim(),
          psdEditableFontSize: _scalePsdTextFontSize(
            (rawLayer['psdEditableFontSize'] as num?)?.toDouble() ?? 40,
            psdWidth: width,
            psdHeight: height,
          ),
          psdEditableFontFamily: _resolvePsdEditableFontFamily(
            rawLayer['psdEditableFontFamily'],
          ),
          psdEditableTextAlign: _psdTextAlignFromPayload(
            rawLayer['psdEditableTextAlign'],
          ),
          photoOpacity: opacity.clamp(0.0, 1.0).toDouble(),
          isHidden: rawLayer['hidden'] == true,
          fillPageBounds: false,
          transform: _psdLayerTransformFromPayload(
            rawLayer,
            psdWidth: width,
            psdHeight: height,
          ),
        ),
      );
    }
    if (importedLayers.isEmpty) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: const Text('PSD layers could not be converted.'),
        ),
      );
      return;
    }
    _pushUndoSnapshot();
    _resetWorkspaceViewportToFit();
    _transformationController.value = Matrix4.identity();
    setState(() {
      _pageAspectRatio = width / height;
      _pageAspectRatioAutoFromImage = widget.pageConfig == null;
      _layers.addAll(importedLayers);
      _selectedLayerId = importedLayers.last.id;
      _syncControllerFromSelection();
      _isLayerInteracting = false;
    });
  }

  Future<bool> _canImportDesignFile(File file, {required String label}) async {
    int size;
    try {
      size = await file.length();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: Text('$label file could not be opened.')),
        );
      }
      return false;
    }
    if (size > _designImportMaxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              '$label file is ${_formatDesignImportSize(size)}. '
              'Files up to 100 MB are supported.',
            ),
          ),
        );
      }
      return false;
    }
    if (size < _designImportLargeWarningBytes || !mounted) {
      return true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _editorChromeSurfaceStrong.withValues(alpha: 0.75),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.24),
            ),
          ),
          title: Text('Import large $label file?'),
          titleTextStyle: const TextStyle(
            color: _editorChromeTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
          content: Text(
            'This file is ${_formatDesignImportSize(size)}. '
            'Large layered files can take a little time to import.',
          ),
          contentTextStyle: const TextStyle(
            color: _editorChromeTextSecondary,
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _editorChromeTextSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<T?> _runDesignImportTask<T>({
    required String message,
    required Future<T> Function() task,
  }) async {
    BuildContext? dialogContext;
    if (mounted) {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            dialogContext = context;
            return PopScope(
              canPop: false,
              child: Dialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 48),
                child: _EditorProcessingCard(
                  label: message,
                  detail: 'Please wait while the file is prepared',
                ),
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    try {
      return await task();
    } finally {
      final activeDialogContext = dialogContext;
      if (activeDialogContext != null && activeDialogContext.mounted) {
        try {
          Navigator.of(activeDialogContext).pop();
        } catch (_) {
          // The route may already be gone if the editor was closed mid-import.
        }
      }
    }
  }

  String _formatDesignImportSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 10) {
      return '${mb.toStringAsFixed(0)} MB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String? _resolvePsdEditableFontFamily(Object? rawValue) {
    final raw = (rawValue as String? ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    final normalizedRaw = normalize(raw);
    for (final family in _allTextFontFamilies) {
      if (normalize(family) == normalizedRaw) {
        return family;
      }
    }
    for (final family in _allTextFontFamilies) {
      final normalizedFamily = normalize(family);
      if (normalizedRaw.contains(normalizedFamily) ||
          normalizedFamily.contains(normalizedRaw)) {
        return family;
      }
    }
    return null;
  }

  TextAlign _psdTextAlignFromPayload(Object? rawValue) {
    return switch ((rawValue as String? ?? '').trim()) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };
  }

  double _scalePsdTextFontSize(
    double fontSize, {
    required int psdWidth,
    required int psdHeight,
  }) {
    final scale = _psdImportPageScale(psdWidth);
    return (fontSize * scale).clamp(1.0, 220.0).toDouble();
  }

  double _psdImportPageScale(int psdWidth) {
    final targetPageWidth = _lastCanvasSize.width > 0
        ? _lastCanvasSize.width
        : 360.0;
    return calculatePsdPageWidthScaleForTest(
      psdWidth: psdWidth,
      targetPageWidth: targetPageWidth,
    );
  }

  Matrix4 _psdLayerTransformFromPayload(
    Map rawLayer, {
    required int psdWidth,
    required int psdHeight,
  }) {
    final left = (rawLayer['left'] as num?)?.toDouble() ?? psdWidth / 2;
    final top = (rawLayer['top'] as num?)?.toDouble() ?? psdHeight / 2;
    final right = (rawLayer['right'] as num?)?.toDouble() ?? left;
    final bottom = (rawLayer['bottom'] as num?)?.toDouble() ?? top;
    final centerX = (left + right) / 2;
    final centerY = (top + bottom) / 2;
    final scale = _psdImportPageScale(psdWidth);
    final dx = (centerX - psdWidth / 2) * scale;
    final dy = (centerY - psdHeight / 2) * scale;
    return Matrix4.identity()..translateByDouble(dx, dy, 0, 1);
  }

  double _psdLayerAspectRatioFromPayload(
    Map rawLayer, {
    required double fallbackAspectRatio,
  }) {
    final left = (rawLayer['left'] as num?)?.toDouble();
    final top = (rawLayer['top'] as num?)?.toDouble();
    final right = (rawLayer['right'] as num?)?.toDouble();
    final bottom = (rawLayer['bottom'] as num?)?.toDouble();
    if (left == null || top == null || right == null || bottom == null) {
      return fallbackAspectRatio;
    }
    final layerWidth = (right - left).abs();
    final layerHeight = (bottom - top).abs();
    if (layerWidth <= 0 || layerHeight <= 0) {
      return fallbackAspectRatio;
    }
    return layerWidth / layerHeight;
  }

  Size? _psdLayerFixedSizeFromPayload(
    Map rawLayer, {
    required int psdWidth,
    required int psdHeight,
  }) {
    final left = (rawLayer['left'] as num?)?.toDouble();
    final top = (rawLayer['top'] as num?)?.toDouble();
    final right = (rawLayer['right'] as num?)?.toDouble();
    final bottom = (rawLayer['bottom'] as num?)?.toDouble();
    if (left == null || top == null || right == null || bottom == null) {
      return null;
    }
    final layerWidth = (right - left).abs();
    final layerHeight = (bottom - top).abs();
    if (layerWidth <= 0 || layerHeight <= 0) {
      return null;
    }
    final scale = _psdImportPageScale(psdWidth);
    return Size(layerWidth * scale, layerHeight * scale);
  }

  Future<void> _handleAddPhotoFromSource(ImageSource source) async {
    if (_isPickingMedia) {
      return;
    }
    _isPickingMedia = true;
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (!mounted || pickedFile == null) {
        return;
      }
      await _importPickedPhoto(pickedFile);
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _importPickedPhoto(
    XFile pickedFile, {
    bool asFullPage = false,
  }) async {
    final XFile effectiveFile;
    if (widget.autoProcessAddedPhotos) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: context.strings.localized(
              telugu: 'ఫోటో క్రాప్ చేయండి',
              english: 'Crop Photo',
            ),
            toolbarColor: Colors.white,
            toolbarWidgetColor: const Color(0xFF0F172A),
            backgroundColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF2563EB),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: context.strings.localized(
              telugu: 'ఫోటో క్రాప్ చేయండి',
              english: 'Crop Photo',
            ),
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (!mounted || cropped == null) {
        return;
      }
      effectiveFile = XFile(cropped.path);
    } else {
      effectiveFile = pickedFile;
    }

    late final _OptimizedPhotoPayload optimizedPhoto;
    Uint8List? processedBytes;
    if (widget.autoProcessAddedPhotos) {
      await _runQueuedCommitJob<void>(
        jobKey: 'import_photo_${DateTime.now().microsecondsSinceEpoch}',
        label: context.strings.localized(
          telugu: 'బ్యాక్‌గ్రౌండ్ రిమూవ్ ప్రాసెసింగ్',
          english: 'Background remove processing',
        ),
        detail: context.strings.localized(
          telugu: 'ఫోటో సిద్ధం అవుతోంది. దయచేసి వేచి ఉండండి',
          english: 'Preparing your photo. Please wait.',
        ),
        operation: () async {
          final rawBytes = await effectiveFile.readAsBytes();
          optimizedPhoto = await compute(_optimizeEditorPhotoPayload, rawBytes);
          processedBytes = optimizedPhoto.bytes;
          try {
            final result = await _removeBackgroundForCurrentUser(
              optimizedPhoto.bytes,
            );
            processedBytes = result.pngBytes;
          } catch (_) {}
        },
        showBusyMessage: false,
      );
    } else {
      final rawBytes = await effectiveFile.readAsBytes();
      optimizedPhoto = await compute(_optimizeEditorPhotoPayload, rawBytes);
      processedBytes = optimizedPhoto.bytes;
    }
    if (!mounted || processedBytes == null) {
      return;
    }
    final processedPhoto = asFullPage
        ? _OptimizedPhotoPayload(
            bytes: processedBytes!,
            aspectRatio: optimizedPhoto.aspectRatio,
          )
        : await compute(_trimTransparentEditorPhotoPayload, processedBytes!);
    if (!mounted) {
      return;
    }

    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.photo,
      bytes: processedPhoto.bytes,
      originalPhotoBytes: optimizedPhoto.bytes,
      photoAspectRatio:
          processedPhoto.aspectRatio ?? optimizedPhoto.aspectRatio,
      photoMaskShape: widget.defaultAddedPhotoMaskShape.trim(),
      fillPageBounds: asFullPage,
      transform: Matrix4.identity(),
    );

    _pushUndoSnapshot();
    _resetWorkspaceViewportToFit();
    _photoGestureVelocity = Offset.zero;
    _photoGlideTotalTravel = Offset.zero;
    _photoGlideAppliedTravel = Offset.zero;
    _photoGlideController.stop();
    _snapGuideNotifier.value = const _SnapGuideState.none();
    _transformationController.value = Matrix4.identity();
    setState(() {
      if (_pageAspectRatio == null && optimizedPhoto.aspectRatio != null) {
        _pageAspectRatio = optimizedPhoto.aspectRatio;
        _pageAspectRatioAutoFromImage = widget.pageConfig == null;
      }
      _layers.add(layer);
      _selectedLayerId = layer.id;
      _isLayerInteracting = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedLayerId != layer.id) {
        return;
      }
      _transformationController.value = Matrix4.identity();
    });
  }
}
