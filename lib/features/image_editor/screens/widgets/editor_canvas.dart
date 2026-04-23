part of '../image_editor_screen.dart';
double _mapAdjustBlurToSigma(double blur) {
  final normalized = (blur / 10).clamp(0.0, 1.0);
  final eased = math.pow(normalized, 1.65).toDouble();
  return (eased * 24).clamp(0.0, 24.0);
}

List<double> _brightnessContrastMatrix({
  required double brightness,
  required double contrast,
}) {
  final clampedContrast = contrast.clamp(0.4, 2.2);
  final clampedBrightness = brightness.clamp(-1.0, 1.0);
  final bias = (clampedBrightness * 255) + ((1 - clampedContrast) * 128);
  return <double>[
    clampedContrast,
    0,
    0,
    0,
    bias,
    0,
    clampedContrast,
    0,
    0,
    bias,
    0,
    0,
    clampedContrast,
    0,
    bias,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _saturationMatrix(double saturation) {
  final s = saturation.clamp(0.0, 2.5);
  const rw = 0.3086;
  const gw = 0.6094;
  const bw = 0.0820;
  final inv = 1 - s;
  final r = inv * rw;
  final g = inv * gw;
  final b = inv * bw;
  return <double>[
    r + s,
    g,
    b,
    0,
    0,
    r,
    g + s,
    b,
    0,
    0,
    r,
    g,
    b + s,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

double _normalizeAngle(double angle) {
  var normalized = angle % (2 * math.pi);
  if (normalized < 0) {
    normalized += 2 * math.pi;
  }
  return normalized;
}

double _shortestAngleDelta({required double from, required double to}) {
  var delta = to - from;
  while (delta > math.pi) {
    delta -= 2 * math.pi;
  }
  while (delta < -math.pi) {
    delta += 2 * math.pi;
  }
  return delta;
}

double _matrixRotationZ(Matrix4 matrix) {
  final m = matrix.storage;
  return math.atan2(m[1], m[0]);
}

double _softSnapRotation(double angle) {
  final normalized = _normalizeAngle(angle);
  const targets = <double>[
    0,
    math.pi / 2,
    math.pi,
    3 * math.pi / 2,
    2 * math.pi,
  ];

  var nearest = targets.first;
  var smallestDelta = double.infinity;
  for (final target in targets) {
    final delta = (normalized - target).abs();
    if (delta < smallestDelta) {
      smallestDelta = delta;
      nearest = target;
    }
  }

  if (smallestDelta >= _ImageEditorScreenState._rotationSnapThresholdRadians) {
    return angle;
  }

  final strength =
      1 -
      (smallestDelta / _ImageEditorScreenState._rotationSnapThresholdRadians);
  final snappedNormalized =
      normalized + ((nearest - normalized) * strength.clamp(0.0, 1.0));
  return angle + (snappedNormalized - normalized);
}

Uint8List _optimizeEditorPhotoBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  const targetMaxDimension = 1920;
  final longest = math.max(decoded.width, decoded.height);
  if (longest <= targetMaxDimension) {
    return bytes;
  }

  final scale = targetMaxDimension / longest;
  final width = math.max(320, (decoded.width * scale).round());
  final height = math.max(320, (decoded.height * scale).round());
  final resized = img.copyResize(decoded, width: width, height: height);
  if (resized.hasAlpha) {
    return Uint8List.fromList(img.encodePng(resized));
  }
  return Uint8List.fromList(img.encodeJpg(resized, quality: 92));
}

_OptimizedPhotoPayload _optimizeEditorPhotoPayload(Uint8List bytes) {
  final optimizedBytes = _optimizeEditorPhotoBytes(bytes);
  final decoded = img.decodeImage(optimizedBytes);
  final aspectRatio = decoded != null && decoded.height > 0
      ? decoded.width / decoded.height
      : null;
  return _OptimizedPhotoPayload(
    bytes: optimizedBytes,
    aspectRatio: aspectRatio,
  );
}

double? _extractImageAspectRatio(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.height == 0) {
    return null;
  }
  return decoded.width / decoded.height;
}

class _CanvasWorkspace extends StatelessWidget {
  const _CanvasWorkspace({
    required this.layers,
    required this.selectedLayerId,
    required this.canvasBackgroundColor,
    required this.canvasBackgroundGradientIndex,
    required this.stageBackgroundImageBytes,
    required this.backgroundBlurAmount,
    required this.borderStyle,
    required this.borderTargetLayerId,
    required this.canvasSize,
    required this.pageAspectRatio,
    required this.hideAutoPageFrame,
    required this.topInset,
    required this.bottomInset,
    required this.transformationController,
    required this.onSelectedLayerInteractionStart,
    required this.onSelectedLayerScaleUpdate,
    required this.onLayerSelected,
    required this.onSelectedLayerInteractionEnd,
    required this.onSelectedTransformHandlePointerDown,
    required this.onSelectedStickerHandleStart,
    required this.onSelectedStickerHandleUpdate,
    required this.onSelectedStickerHandleEnd,
    required this.onSelectedLayerDoubleTap,
    required this.onSelectedTextTap,
    required this.onSelectedTextDoubleTap,
    required this.onSelectedTextPointerDown,
    required this.onSelectedTextPointerMove,
    required this.onSelectedTextPointerCancel,
    required this.onCanvasTapDown,
    required this.onCanvasTap,
    required this.showCanvasBackground,
    required this.photoBrightnessForLayer,
    required this.photoContrastForLayer,
    required this.photoSaturationForLayer,
    required this.photoBlurForLayer,
    required this.showSelectionDecorations,
    required this.showPageFramePreview,
    required this.snapGuideListenable,
    required this.snapGuidesEnabled,
    required this.selectedPhotoRenderListenable,
  });

  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final Color canvasBackgroundColor;
  final int canvasBackgroundGradientIndex;
  final Uint8List? stageBackgroundImageBytes;
  final double backgroundBlurAmount;
  final _BorderStyle borderStyle;
  final String? borderTargetLayerId;
  final Size canvasSize;
  final double? pageAspectRatio;
  final bool hideAutoPageFrame;
  final double topInset;
  final double bottomInset;
  final TransformationController transformationController;
  final ValueChanged<ScaleStartDetails> onSelectedLayerInteractionStart;
  final ValueChanged<ScaleUpdateDetails> onSelectedLayerScaleUpdate;
  final ValueChanged<String> onLayerSelected;
  final VoidCallback onSelectedLayerInteractionEnd;
  final VoidCallback onSelectedTransformHandlePointerDown;
  final ValueChanged<DragStartDetails> onSelectedStickerHandleStart;
  final ValueChanged<DragUpdateDetails> onSelectedStickerHandleUpdate;
  final VoidCallback onSelectedStickerHandleEnd;
  final VoidCallback onSelectedLayerDoubleTap;
  final VoidCallback onSelectedTextTap;
  final VoidCallback onSelectedTextDoubleTap;
  final ValueChanged<PointerDownEvent> onSelectedTextPointerDown;
  final ValueChanged<PointerMoveEvent> onSelectedTextPointerMove;
  final VoidCallback onSelectedTextPointerCancel;
  final void Function(Offset localPosition, Rect pageRect, Size pageSize)
  onCanvasTapDown;
  final VoidCallback onCanvasTap;
  final bool showCanvasBackground;
  final double Function(_CanvasLayer layer) photoBrightnessForLayer;
  final double Function(_CanvasLayer layer) photoContrastForLayer;
  final double Function(_CanvasLayer layer) photoSaturationForLayer;
  final double Function(_CanvasLayer layer) photoBlurForLayer;
  final bool showSelectionDecorations;
  final bool showPageFramePreview;
  final ValueListenable<_SnapGuideState> snapGuideListenable;
  final bool snapGuidesEnabled;
  final ValueListenable<_SelectedPhotoRenderState?>
  selectedPhotoRenderListenable;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final unselectedPhotoCacheWidth =
        (canvasSize.width * devicePixelRatio * 1.5).round().clamp(720, 1600);
    final workspaceHeight = math.max(
      0.0,
      canvasSize.height - topInset - bottomInset,
    );
    final workspaceSize = Size(canvasSize.width, workspaceHeight);
    final hasPageSelection = pageAspectRatio != null;
    final showPageFrame =
        hasPageSelection && !hideAutoPageFrame && showPageFramePreview;
    final pageSize = hasPageSelection
        ? _fitPageSize(
            workspaceSize: workspaceSize,
            aspectRatio: pageAspectRatio!,
          )
        : workspaceSize;
    final pageRect = Rect.fromCenter(
      center: Offset(canvasSize.width / 2, topInset + (workspaceHeight / 2)),
      width: pageSize.width,
      height: pageSize.height,
    );
    final hasImageBorderTarget =
        borderStyle != _BorderStyle.none &&
        borderTargetLayerId != null &&
        layers.any((layer) => layer.id == borderTargetLayerId && layer.isPhoto);
    final applyStageBorder =
        borderStyle != _BorderStyle.none && !hasImageBorderTarget;
    final stageBorderRadius = borderStyle == _BorderStyle.rounded ? 16.0 : 2.0;
    final stageBorderSide = switch (borderStyle) {
      _BorderStyle.thinWhite => BorderSide(
        color: Colors.white.withValues(alpha: 0.95),
        width: 1.5,
      ),
      _BorderStyle.thinBlack => const BorderSide(
        color: Color(0xE20F172A),
        width: 1.5,
      ),
      _BorderStyle.rounded => BorderSide(
        color: Colors.white.withValues(alpha: 0.8),
        width: 1.5,
      ),
      _BorderStyle.glow => BorderSide(
        color: const Color(0xFF60A5FA).withValues(alpha: 0.7),
        width: 1.4,
      ),
      _BorderStyle.none => null,
    };
    final stageGlow = borderStyle == _BorderStyle.glow
        ? <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 1.2,
            ),
          ]
        : null;
    final resolvedBackgroundBlur = stageBackgroundImageBytes == null
        ? 0.0
        : backgroundBlurAmount.clamp(0, 40) / 6.5;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: showCanvasBackground
            ? const Color(0xFF000000)
            : Colors.transparent,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) =>
            onCanvasTapDown(details.localPosition, pageRect, pageSize),
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                  child: ClipRect(
                    child: Stack(
                      children: <Widget>[
                        Center(
                          child: RepaintBoundary(
                            child: Container(
                              width: pageSize.width,
                              height: pageSize.height,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                gradient:
                                    stageBackgroundImageBytes == null &&
                                        canvasBackgroundGradientIndex >= 0 &&
                                        canvasBackgroundGradientIndex <
                                            editorBackgroundGradients.length &&
                                        showCanvasBackground
                                    ? LinearGradient(
                                        colors:
                                            editorBackgroundGradients[canvasBackgroundGradientIndex],
                                      )
                                    : null,
                                color: showCanvasBackground
                                    ? canvasBackgroundColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  applyStageBorder ? stageBorderRadius : 2,
                                ),
                                border: applyStageBorder
                                    ? (stageBorderSide == null
                                          ? null
                                          : Border.fromBorderSide(
                                              stageBorderSide,
                                            ))
                                    : showPageFrame && showCanvasBackground
                                    ? Border.all(
                                        color: const Color(0x331E293B),
                                        width: 1,
                                      )
                                    : null,
                                boxShadow: applyStageBorder ? stageGlow : null,
                              ),
                              child:
                                  stageBackgroundImageBytes != null &&
                                      showCanvasBackground
                                  ? SizedBox.expand(
                                      child: ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(
                                          sigmaX: resolvedBackgroundBlur,
                                          sigmaY: resolvedBackgroundBlur,
                                        ),
                                        child: Image.memory(
                                          stageBackgroundImageBytes!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                          filterQuality: FilterQuality.medium,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (layers.isNotEmpty)
                          ...layers.where((layer) => !layer.isHidden).map((
                            layer,
                          ) {
                            final isSelected = layer.id == selectedLayerId;
                            final layerSize = _workspaceLayerVisualSize(
                              layer,
                              pageSize,
                            );
                            final photoSize = layer.isPhoto
                                ? _fitPhotoLayerSize(
                                    pageSize: pageSize,
                                    photoAspectRatio: layer.photoAspectRatio,
                                  )
                                : Size.zero;
                            final transformLayerSize = layer.isPhoto
                                ? photoSize
                                : layerSize;
                            final photoCacheWidth = layer.isPhoto
                                ? (photoSize.width * devicePixelRatio)
                                      .round()
                                      .clamp(512, 2048)
                                : null;
                            final effectiveBrightness = layer.isPhoto
                                ? photoBrightnessForLayer(layer)
                                : 0.0;
                            final effectiveContrast = layer.isPhoto
                                ? photoContrastForLayer(layer)
                                : 1.0;
                            final effectiveSaturation = layer.isPhoto
                                ? photoSaturationForLayer(layer)
                                : 1.0;
                            final effectiveBlur = layer.isPhoto
                                ? photoBlurForLayer(layer)
                                : 0.0;
                            Widget layerChild = layer.isPhoto
                                ? SizedBox(
                                    width: photoSize.width,
                                    height: photoSize.height,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        if (isSelected)
                                          ValueListenableBuilder<
                                            _SelectedPhotoRenderState?
                                          >(
                                            valueListenable:
                                                selectedPhotoRenderListenable,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  _SelectedPhotoRenderState?
                                                  renderState,
                                                  Widget? child,
                                                ) {
                                                  final resolvedState =
                                                      renderState != null &&
                                                          renderState.layerId ==
                                                              layer.id
                                                      ? renderState
                                                      : _SelectedPhotoRenderState(
                                                          layerId: layer.id,
                                                          bytes: layer.bytes!,
                                                          opacity: layer
                                                              .photoOpacity
                                                              .clamp(0.1, 1),
                                                          flipHorizontally: layer
                                                              .flipPhotoHorizontally,
                                                          flipVertically: layer
                                                              .flipPhotoVertically,
                                                          brightness:
                                                              effectiveBrightness,
                                                          contrast:
                                                              effectiveContrast,
                                                          saturation:
                                                              effectiveSaturation,
                                                          blur: effectiveBlur,
                                                        );
                                                  return Opacity(
                                                    opacity: resolvedState
                                                        .opacity
                                                        .clamp(0.1, 1),
                                                    child: Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: Matrix4.diagonal3Values(
                                                        resolvedState
                                                                .flipHorizontally
                                                            ? -1
                                                            : 1,
                                                        resolvedState
                                                                .flipVertically
                                                            ? -1
                                                            : 1,
                                                        1,
                                                      ),
                                                      child:
                                                          _buildAdjustedPhoto(
                                                            bytes: resolvedState
                                                                .bytes,
                                                            cacheKey:
                                                                resolvedState
                                                                    .cacheKey,
                                                            cacheWidth:
                                                                photoCacheWidth,
                                                            brightness:
                                                                resolvedState
                                                                    .brightness,
                                                            contrast:
                                                                resolvedState
                                                                    .contrast,
                                                            saturation:
                                                                resolvedState
                                                                    .saturation,
                                                            blur: resolvedState
                                                                .blur,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          )
                                        else
                                          Opacity(
                                            opacity: layer.photoOpacity.clamp(
                                              0.1,
                                              1,
                                            ),
                                            child: Transform(
                                              alignment: Alignment.center,
                                              transform:
                                                  Matrix4.diagonal3Values(
                                                    layer.flipPhotoHorizontally
                                                        ? -1
                                                        : 1,
                                                    layer.flipPhotoVertically
                                                        ? -1
                                                        : 1,
                                                    1,
                                                  ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 260,
                                                ),
                                                switchInCurve:
                                                    Curves.easeOutCubic,
                                                switchOutCurve:
                                                    Curves.easeInCubic,
                                                transitionBuilder:
                                                    (child, animation) =>
                                                        FadeTransition(
                                                          opacity: animation,
                                                          child: child,
                                                        ),
                                                child: _buildAdjustedPhoto(
                                                  bytes: layer.bytes!,
                                                  cacheKey:
                                                      '${_photoBytesSignature(layer.bytes!)}_'
                                                      '${effectiveBrightness.toStringAsFixed(3)}_'
                                                      '${effectiveContrast.toStringAsFixed(3)}_'
                                                      '${effectiveSaturation.toStringAsFixed(3)}_'
                                                      '${effectiveBlur.toStringAsFixed(3)}',
                                                  cacheWidth: isSelected
                                                      ? photoCacheWidth
                                                      : photoCacheWidth ??
                                                            unselectedPhotoCacheWidth,
                                                  brightness:
                                                      effectiveBrightness,
                                                  contrast: effectiveContrast,
                                                  saturation:
                                                      effectiveSaturation,
                                                  blur: effectiveBlur,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : layer.isText
                                ? _CanvasTextLayerView(
                                    text: _resolveLayerRenderText(layer),
                                    textColor: layer.textColor,
                                    textAlign: layer.textAlign,
                                    textOpacity: layer.textOpacity,
                                    fontFamily: _resolveLayerRenderFontFamily(
                                      layer,
                                    ),
                                    textLineHeight: layer.textLineHeight,
                                    textLetterSpacing: layer.textLetterSpacing,
                                    textShadowOpacity: layer.textShadowOpacity,
                                    textShadowBlur: layer.textShadowBlur,
                                    textShadowOffsetY: layer.textShadowOffsetY,
                                    isTextBold: layer.isTextBold,
                                    isTextItalic: layer.isTextItalic,
                                    isTextUnderline: layer.isTextUnderline,
                                    textStrokeColor: layer.textStrokeColor,
                                    textStrokeWidth: layer.textStrokeWidth,
                                    textStrokeGradient:
                                        layer.textStrokeGradientIndex >= 0 &&
                                            layer.textStrokeGradientIndex <
                                                _textGradients.length
                                        ? _textGradients[layer
                                              .textStrokeGradientIndex]
                                        : null,
                                    textBackgroundColor:
                                        layer.textBackgroundColor,
                                    textBackgroundOpacity:
                                        layer.textBackgroundOpacity,
                                    textBackgroundRadius:
                                        layer.textBackgroundRadius,
                                    textGradient:
                                        layer.textGradientIndex >= 0 &&
                                            layer.textGradientIndex <
                                                _textGradients.length
                                        ? _textGradients[layer
                                              .textGradientIndex]
                                        : null,
                                    fontSize: layer.fontSize,
                                  )
                                : Text(
                                    layer.sticker ?? '?',
                                    style: TextStyle(fontSize: layer.fontSize),
                                  );
                            if (layer.isPhoto &&
                                borderStyle != _BorderStyle.none &&
                                layer.id == borderTargetLayerId) {
                              final borderRadius =
                                  borderStyle == _BorderStyle.rounded
                                  ? 16.0
                                  : 0.0;
                              final borderSide = switch (borderStyle) {
                                _BorderStyle.thinWhite => BorderSide(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  width: 1.5,
                                ),
                                _BorderStyle.thinBlack => const BorderSide(
                                  color: Color(0xE20F172A),
                                  width: 1.5,
                                ),
                                _BorderStyle.rounded => BorderSide(
                                  color: Colors.white.withValues(alpha: 0.84),
                                  width: 1.5,
                                ),
                                _BorderStyle.glow => BorderSide(
                                  color: const Color(
                                    0xFF60A5FA,
                                  ).withValues(alpha: 0.75),
                                  width: 1.3,
                                ),
                                _BorderStyle.none => BorderSide.none,
                              };
                              final glowShadow =
                                  borderStyle == _BorderStyle.glow
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: const Color(
                                          0xFF60A5FA,
                                        ).withValues(alpha: 0.38),
                                        blurRadius: 20,
                                        spreadRadius: 1.3,
                                      ),
                                    ]
                                  : null;
                              layerChild = DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                  border: Border.fromBorderSide(borderSide),
                                  boxShadow: glowShadow,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                  child: layerChild,
                                ),
                              );
                            }
                            final stickerAsset =
                                _EditorTextState._isImageLikeSticker(
                                  layer.sticker,
                                );
                            final stickerOrTextChild =
                                layer.isSticker && stickerAsset
                                ? SizedBox(
                                    width: layerSize.width,
                                    height: layerSize.height,
                                    child: _EditorTextState._buildStickerVisual(
                                      layer.sticker,
                                      fontSize: layer.fontSize,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  )
                                : layerChild;

                            final decoratedChild =
                                showSelectionDecorations &&
                                    isSelected &&
                                    !layer.isText
                                ? DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withValues(alpha: 0.55),
                                        width: 1.25,
                                      ),
                                      borderRadius: null,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: RepaintBoundary(
                                        child: stickerOrTextChild,
                                      ),
                                    ),
                                  )
                                : RepaintBoundary(child: stickerOrTextChild);
                            final effectiveTextChild = layer.isText
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: decoratedChild,
                                  )
                                : decoratedChild;

                            final child = isSelected
                                ? (layer.isPhoto || layer.isSticker)
                                      ? SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: ValueListenableBuilder<Matrix4>(
                                            valueListenable:
                                                transformationController,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  Matrix4 matrix,
                                                  Widget? child,
                                                ) {
                                                  return Stack(
                                                    clipBehavior: Clip.none,
                                                    children: <Widget>[
                                                      Center(
                                                        child: Transform(
                                                          alignment:
                                                              Alignment.center,
                                                          transform: matrix,
                                                          child: SizedBox(
                                                            width:
                                                                transformLayerSize
                                                                    .width,
                                                            height:
                                                                transformLayerSize
                                                                    .height,
                                                            child:
                                                                GestureDetector(
                                                                  behavior:
                                                                      HitTestBehavior
                                                                          .translucent,
                                                                  onDoubleTap:
                                                                      onSelectedLayerDoubleTap,
                                                                  onScaleStart:
                                                                      onSelectedLayerInteractionStart,
                                                                  onScaleUpdate:
                                                                      onSelectedLayerScaleUpdate,
                                                                  onScaleEnd: (_) =>
                                                                      onSelectedLayerInteractionEnd(),
                                                                  child:
                                                                      decoratedChild,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (showSelectionDecorations &&
                                                          (layer.isSticker ||
                                                              layer.isPhoto))
                                                        _FixedSelectionHandleOverlay(
                                                          pageSize: pageSize,
                                                          matrix: matrix,
                                                          layerSize:
                                                              transformLayerSize,
                                                          handleOffset:
                                                              const Offset(
                                                                14,
                                                                14,
                                                              ),
                                                          onPointerDown:
                                                              onSelectedTransformHandlePointerDown,
                                                          onPanStart:
                                                              onSelectedStickerHandleStart,
                                                          onPanUpdate:
                                                              onSelectedStickerHandleUpdate,
                                                          onPanEnd: (_) =>
                                                              onSelectedStickerHandleEnd(),
                                                        ),
                                                    ],
                                                  );
                                                },
                                          ),
                                        )
                                      : layer.isText
                                      ? SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: ValueListenableBuilder<Matrix4>(
                                            valueListenable:
                                                transformationController,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  Matrix4 matrix,
                                                  Widget? child,
                                                ) {
                                                  return Stack(
                                                    clipBehavior: Clip.none,
                                                    children: <Widget>[
                                                      Center(
                                                        child: Transform(
                                                          alignment:
                                                              Alignment.center,
                                                          transform: matrix,
                                                          child: Listener(
                                                            onPointerDown:
                                                                onSelectedTextPointerDown,
                                                            onPointerMove:
                                                                onSelectedTextPointerMove,
                                                            onPointerUp: (_) =>
                                                                onSelectedTextPointerCancel(),
                                                            onPointerCancel:
                                                                (_) =>
                                                                    onSelectedTextPointerCancel(),
                                                            child:
                                                                GestureDetector(
                                                                  behavior:
                                                                      HitTestBehavior
                                                                          .opaque,
                                                                  onTap:
                                                                      onSelectedTextTap,
                                                                  onDoubleTap:
                                                                      onSelectedTextDoubleTap,
                                                                  onScaleStart:
                                                                      onSelectedLayerInteractionStart,
                                                                  onScaleUpdate:
                                                                      onSelectedLayerScaleUpdate,
                                                                  onScaleEnd:
                                                                      (_) => onSelectedLayerInteractionEnd(),
                                                                  child:
                                                                      effectiveTextChild,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (showSelectionDecorations)
                                                        _FixedSelectionHandleOverlay(
                                                          pageSize: pageSize,
                                                          matrix: matrix,
                                                          layerSize:
                                                              _workspaceLayerVisualSize(
                                                                layer,
                                                                pageSize,
                                                              ),
                                                          handleOffset:
                                                              const Offset(
                                                                12,
                                                                12,
                                                              ),
                                                          onPointerDown:
                                                              onSelectedTransformHandlePointerDown,
                                                          onPanStart:
                                                              onSelectedStickerHandleStart,
                                                          onPanUpdate:
                                                              onSelectedStickerHandleUpdate,
                                                          onPanEnd: (_) =>
                                                              onSelectedStickerHandleEnd(),
                                                        ),
                                                    ],
                                                  );
                                                },
                                          ),
                                        )
                                      : SizedBox(
                                          width: pageSize.width,
                                          height: pageSize.height,
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onDoubleTap:
                                                onSelectedLayerDoubleTap,
                                            child: InteractiveViewer(
                                              transformationController:
                                                  transformationController,
                                              minScale: 0.2,
                                              maxScale: 8.0,
                                              panEnabled: true,
                                              scaleEnabled: true,
                                              constrained: false,
                                              clipBehavior: Clip.none,
                                              boundaryMargin:
                                                  const EdgeInsets.all(2400),
                                              onInteractionStart:
                                                  onSelectedLayerInteractionStart,
                                              onInteractionUpdate:
                                                  onSelectedLayerScaleUpdate,
                                              onInteractionEnd: (_) =>
                                                  onSelectedLayerInteractionEnd(),
                                              child: Center(
                                                child: decoratedChild,
                                              ),
                                            ),
                                          ),
                                        )
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: layer.transform,
                                    child: layer.isSticker
                                        ? stickerOrTextChild
                                        : layerChild,
                                  );

                            return Center(
                              child: isSelected
                                  ? child
                                  : layer.isText
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: child,
                                    )
                                  : child,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: topInset,
                      bottom: bottomInset,
                    ),
                    child: ValueListenableBuilder<_SnapGuideState>(
                      valueListenable: snapGuideListenable,
                      builder:
                          (
                            BuildContext context,
                            _SnapGuideState snapGuides,
                            Widget? child,
                          ) {
                            return RepaintBoundary(
                              child: CustomPaint(
                                painter: _SnapGuidesPainter(
                                  showVerticalGuide:
                                      snapGuidesEnabled &&
                                      snapGuides.showVerticalGuide,
                                  showHorizontalGuide:
                                      snapGuidesEnabled &&
                                      snapGuides.showHorizontalGuide,
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    /*
    final background = canvasBackgroundGradientIndex >= 0 &&
            canvasBackgroundGradientIndex <
                editorBackgroundGradients.length
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: editorBackgroundGradients[canvasBackgroundGradientIndex],
            ),
          )
        : BoxDecoration(color: canvasBackgroundColor);

    return DecoratedBox(
      decoration: background,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onCanvasTap,
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
          if (layers.isEmpty)
            Center(
              child: Text(
                'Canvas Area',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
            )
          else
            ...layers.map((layer) {
              final isSelected = layer.id == selectedLayerId;
              final layerChild = layer.isPhoto
                  ? Image.memory(
                      layer.bytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      cacheWidth: isSelected ? null : unselectedPhotoCacheWidth,
                    )
                  : layer.isText
                      ? _CanvasTextLayerView(
                      text: _resolveLayerRenderText(layer),
                      textColor: layer.textColor,
                      textAlign: layer.textAlign,
                      fontFamily: _resolveLayerRenderFontFamily(layer),
                      textGradient: layer.textGradientIndex >= 0 &&
                              layer.textGradientIndex < _textGradients.length
                          ? _textGradients[layer.textGradientIndex]
                          : null,
                      fontSize: layer.fontSize,
                    )
                      : Text(
                          layer.sticker ?? '⭐',
                          style: TextStyle(fontSize: layer.fontSize),
                        );

              final child = isSelected
                  ? InteractiveViewer(
                      transformationController: transformationController,
                      minScale: 1,
                      maxScale: layer.isPhoto || layer.isSticker ? 5 : 1,
                      scaleEnabled: layer.isPhoto || layer.isSticker,
                      constrained: false,
                      clipBehavior: Clip.none,
                      boundaryMargin: const EdgeInsets.all(240),
                      onInteractionUpdate: (_) => onSelectedLayerInteractionUpdate(),
                      onInteractionEnd: (_) => onSelectedLayerInteractionEnd(),
                      child: showSelectionDecorations
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                              ),
                              child: layerChild,
                            )
                          : layerChild,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: layer.transform,
                      child: layerChild,
                    );

              return Center(
                child: isSelected
                    ? child
                    : GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTap: () => onLayerSelected(layer.id),
                        child: child,
                      ),
              );
            }),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                child: CustomPaint(
                  painter: _SnapGuidesPainter(
                    showVerticalGuide: showVerticalSnapGuide,
                    showHorizontalGuide: showHorizontalSnapGuide,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
*/
  }
}

Size _fitPageSize({required Size workspaceSize, required double aspectRatio}) {
  if (workspaceSize.width <= 0 || workspaceSize.height <= 0) {
    return Size.zero;
  }

  final safeAspect = aspectRatio <= 0 ? 1.0 : aspectRatio;
  final maxWidth = workspaceSize.width;
  final maxHeight = workspaceSize.height;

  var width = maxWidth;
  var height = width / safeAspect;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * safeAspect;
  }

  return Size(width, height);
}

Size _fitPhotoLayerSize({
  required Size pageSize,
  required double? photoAspectRatio,
}) {
  if (pageSize.width <= 0 || pageSize.height <= 0) {
    return Size.zero;
  }

  final ratio = (photoAspectRatio != null && photoAspectRatio > 0)
      ? photoAspectRatio
      : (pageSize.width / pageSize.height);

  final maxWidth = pageSize.width * 0.88;
  final maxHeight = pageSize.height * 0.88;
  var width = maxWidth;
  var height = width / ratio;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * ratio;
  }
  return Size(width, height);
}

Size _workspaceLayerVisualSize(_CanvasLayer layer, Size pageSize) {
  if (layer.isPhoto) {
    return _fitPhotoLayerSize(
      pageSize: pageSize,
      photoAspectRatio: layer.photoAspectRatio,
    );
  }
  if (layer.isText) {
    final painter = TextPainter(
      text: TextSpan(
        text: _resolveLayerRenderText(layer),
        style: TextStyle(
          fontFamily: _resolveLayerRenderFontFamily(layer),
          fontSize: layer.fontSize,
          height: layer.textLineHeight,
          letterSpacing: layer.textLetterSpacing,
          fontWeight: layer.isTextBold ? FontWeight.w800 : FontWeight.w500,
          fontStyle: layer.isTextItalic ? FontStyle.italic : FontStyle.normal,
          decoration: layer.isTextUnderline
              ? TextDecoration.underline
              : TextDecoration.none,
          color: layer.textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size;
  }
  final sticker = layer.sticker;
  if (_EditorTextState._isImageLikeSticker(sticker)) {
    return Size.square(layer.fontSize);
  }
  final painter = TextPainter(
    text: TextSpan(
      text: sticker ?? '*',
      style: TextStyle(fontSize: layer.fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.size;
}

class _FixedSelectionHandleOverlay extends StatelessWidget {
  const _FixedSelectionHandleOverlay({
    required this.pageSize,
    required this.matrix,
    required this.layerSize,
    required this.handleOffset,
    required this.onPointerDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final Size pageSize;
  final Matrix4 matrix;
  final Size layerSize;
  final Offset handleOffset;
  final VoidCallback onPointerDown;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    const handleSize = 36.0;
    final halfHandle = handleSize / 2;
    final transformedCorner = MatrixUtils.transformPoint(
      matrix,
      Offset(layerSize.width / 2, layerSize.height / 2),
    );
    final rawHandleCenter = Offset(
      pageSize.width / 2 + transformedCorner.dx + handleOffset.dx,
      pageSize.height / 2 + transformedCorner.dy + handleOffset.dy,
    );
    final handleCenter = Offset(
      rawHandleCenter.dx.clamp(halfHandle, pageSize.width - halfHandle),
      rawHandleCenter.dy.clamp(halfHandle, pageSize.height - halfHandle),
    );

    return Positioned(
      left: handleCenter.dx - halfHandle,
      top: handleCenter.dy - halfHandle,
      child: _StickerResizeRotateHandle(
        onPointerDown: onPointerDown,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
      ),
    );
  }
}

class _StickerResizeRotateHandle extends StatelessWidget {
  const _StickerResizeRotateHandle({
    required this.onPointerDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final VoidCallback onPointerDown;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPointerDown(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.rotate_right_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _SnapGuidesPainter extends CustomPainter {
  const _SnapGuidesPainter({
    required this.showVerticalGuide,
    required this.showHorizontalGuide,
  });

  final bool showVerticalGuide;
  final bool showHorizontalGuide;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    if (showVerticalGuide) {
      final x = size.width / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    if (showHorizontalGuide) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnapGuidesPainter oldDelegate) {
    return oldDelegate.showVerticalGuide != showVerticalGuide ||
        oldDelegate.showHorizontalGuide != showHorizontalGuide;
  }
}

class _CanvasTextLayerView extends StatelessWidget {
  const _CanvasTextLayerView({
    required this.text,
    required this.textColor,
    required this.textAlign,
    required this.fontSize,
    required this.textOpacity,
    required this.fontFamily,
    required this.textLineHeight,
    required this.textLetterSpacing,
    required this.textShadowOpacity,
    required this.textShadowBlur,
    required this.textShadowOffsetY,
    required this.isTextBold,
    required this.isTextItalic,
    required this.isTextUnderline,
    required this.textStrokeColor,
    required this.textStrokeWidth,
    this.textStrokeGradient,
    required this.textBackgroundColor,
    required this.textBackgroundOpacity,
    required this.textBackgroundRadius,
    this.textGradient,
    this.editorAssistShadowColor,
    this.editorAssistShadowBlur = 0,
  });

  final String text;
  final Color textColor;
  final TextAlign textAlign;
  final double fontSize;
  final double textOpacity;
  final String fontFamily;
  final double textLineHeight;
  final double textLetterSpacing;
  final double textShadowOpacity;
  final double textShadowBlur;
  final double textShadowOffsetY;
  final bool isTextBold;
  final bool isTextItalic;
  final bool isTextUnderline;
  final Color textStrokeColor;
  final double textStrokeWidth;
  final List<Color>? textStrokeGradient;
  final Color textBackgroundColor;
  final double textBackgroundOpacity;
  final double textBackgroundRadius;
  final List<Color>? textGradient;
  final Color? editorAssistShadowColor;
  final double editorAssistShadowBlur;

  @override
  Widget build(BuildContext context) {
    final fillForeground = textGradient == null
        ? null
        : (Paint()
            ..shader = LinearGradient(
              colors: textGradient!,
            ).createShader(
              Rect.fromLTWH(
                0,
                0,
                (fontSize * math.max(text.length, 3)).clamp(fontSize * 2, 2400),
                fontSize * math.max(text.split('\n').length, 1) * 2.4,
              ),
            ));
    final baseStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontSize: fontSize,
      height: textLineHeight,
      letterSpacing: textLetterSpacing,
      fontWeight: isTextBold ? FontWeight.w700 : FontWeight.w500,
      fontStyle: isTextItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isTextUnderline
          ? TextDecoration.underline
          : TextDecoration.none,
      fontFamily: fontFamily,
      color: fillForeground == null ? textColor : null,
      foreground: fillForeground,
      shadows: <Shadow>[
        if (textShadowOpacity > 0.001)
          Shadow(
            color: Colors.black.withValues(alpha: textShadowOpacity),
            blurRadius: textShadowBlur,
            offset: Offset(0, textShadowOffsetY),
          ),
        if (editorAssistShadowColor != null && editorAssistShadowBlur > 0.001)
          Shadow(
            color: editorAssistShadowColor!,
            blurRadius: editorAssistShadowBlur,
            offset: Offset.zero,
          ),
      ],
    );

    final strokeText = textStrokeWidth <= 0.001
        ? null
        : Text(
            text,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: fontSize,
              height: textLineHeight,
              letterSpacing: textLetterSpacing,
              fontWeight: isTextBold ? FontWeight.w700 : FontWeight.w500,
              fontStyle: isTextItalic ? FontStyle.italic : FontStyle.normal,
              decoration: isTextUnderline
                  ? TextDecoration.underline
                  : TextDecoration.none,
              fontFamily: fontFamily,
              shadows: <Shadow>[
                if (textShadowOpacity > 0.001)
                  Shadow(
                    color: Colors.black.withValues(alpha: textShadowOpacity),
                    blurRadius: textShadowBlur,
                    offset: Offset(0, textShadowOffsetY),
                  ),
                if (editorAssistShadowColor != null &&
                    editorAssistShadowBlur > 0.001)
                  Shadow(
                    color: editorAssistShadowColor!,
                    blurRadius: editorAssistShadowBlur,
                    offset: Offset.zero,
                  ),
              ],
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = textStrokeWidth
                ..color = textStrokeColor
                ..shader = (textStrokeGradient == null
                    ? null
                    : LinearGradient(colors: textStrokeGradient!).createShader(
                        Rect.fromLTWH(
                          0,
                          0,
                          (fontSize * math.max(text.length, 3)).clamp(
                            fontSize * 2,
                            2400,
                          ),
                          fontSize * 2.4,
                        ),
                      )),
            ),
          );

    final fillText = Text(text, textAlign: textAlign, style: baseStyle);

    final textView = strokeText == null
        ? fillText
        : Stack(
            alignment: Alignment.center,
            children: <Widget>[strokeText, fillText],
          );

    final hasBackground = textBackgroundOpacity > 0.001;
    final foreground = Opacity(
      opacity: textOpacity.clamp(0.15, 1),
      child: textView,
    );
    if (!hasBackground) {
      return foreground;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: textBackgroundColor.withValues(alpha: textBackgroundOpacity),
        borderRadius: BorderRadius.circular(textBackgroundRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: foreground,
      ),
    );
  }
}

enum _TextToolTab { style, background, effects }
