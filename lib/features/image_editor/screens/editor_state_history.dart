part of 'image_editor_screen.dart';

extension _EditorHistoryState on _ImageEditorScreenState {
  _CanvasLayer _cloneLayer(_CanvasLayer layer) {
    return layer.copyWith(transform: Matrix4.copy(layer.transform));
  }

  _EditorSnapshot _takeSnapshot() {
    return _EditorSnapshot(
      layers: _layers.map(_cloneLayer).toList(growable: false),
      selectedLayerId: _selectedLayerId,
      canvasBackgroundColor: _canvasBackgroundColor,
      canvasBackgroundGradientIndex: _canvasBackgroundGradientIndex,
      stageBackgroundImageBytes: _stageBackgroundImageBytes == null
          ? null
          : Uint8List.fromList(_stageBackgroundImageBytes!),
      borderStyle: _borderStyle,
      borderWidth: _borderWidth,
      borderRadius: _borderRadius,
      borderColor: _borderColor,
      borderTargetLayerId: _borderTargetLayerId,
      backgroundBlurAmount: _backgroundBlurAmount,
    );
  }

  void _pushUndoSnapshot() {
    _undoStack.add(_SnapshotHistoryEntry(_takeSnapshot()));
    if (_undoStack.length > _ImageEditorScreenState._maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerHistoryEntry({
    required _CanvasLayer beforeLayer,
    required _CanvasLayer afterLayer,
    String? beforeSelectedLayerId,
    String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerChangeHistoryEntry(
        layerId: beforeLayer.id,
        beforeLayer: _cloneLayer(beforeLayer),
        afterLayer: _cloneLayer(afterLayer),
        beforeSelectedLayerId: beforeSelectedLayerId ?? _selectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId ?? _selectedLayerId,
      ),
    );
    if (_undoStack.length > _ImageEditorScreenState._maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerInsertHistoryEntry({
    required _CanvasLayer layer,
    required int insertIndex,
    required String? beforeSelectedLayerId,
    required String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerInsertHistoryEntry(
        layer: _cloneLayer(layer),
        insertIndex: insertIndex,
        beforeSelectedLayerId: beforeSelectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId,
      ),
    );
    if (_undoStack.length > _ImageEditorScreenState._maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerDeleteHistoryEntry({
    required _CanvasLayer layer,
    required int deletedIndex,
    required String? beforeSelectedLayerId,
    required String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerDeleteHistoryEntry(
        layer: _cloneLayer(layer),
        deletedIndex: deletedIndex,
        beforeSelectedLayerId: beforeSelectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId,
      ),
    );
    if (_undoStack.length > _ImageEditorScreenState._maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pushLayerReorderHistoryEntry({
    required String layerId,
    required int fromIndex,
    required int toIndex,
    required String? beforeSelectedLayerId,
    required String? afterSelectedLayerId,
  }) {
    _undoStack.add(
      _LayerReorderHistoryEntry(
        layerId: layerId,
        fromIndex: fromIndex,
        toIndex: toIndex,
        beforeSelectedLayerId: beforeSelectedLayerId,
        afterSelectedLayerId: afterSelectedLayerId,
      ),
    );
    if (_undoStack.length > _ImageEditorScreenState._maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _setCommitState(String? label, {String? detail}) {
    _commitStateNotifier.value = label == null
        ? null
        : _EditorCommitState(
            label: label,
            detail: detail ?? 'Please wait while the layer is updated',
          );
  }

  bool get _isCommitWorkerBusy => _activeCommitJobKey != null;

  Future<T?> _runQueuedCommitJob<T>({
    required String jobKey,
    required String label,
    required String detail,
    required Future<T> Function() operation,
    VoidCallback? onStart,
    VoidCallback? onFinish,
    bool showBusyMessage = true,
    bool showCommitState = true,
  }) async {
    if (_activeCommitJobKey != null) {
      if (showBusyMessage && mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'ప్రస్తుత ఎడిటర్ పని పూర్తయ్యే వరకు వేచి ఉండండి',
                english: 'Please wait, current editor job is still running',
              ),
            ),
          ),
        );
      }
      return null;
    }

    _activeCommitJobKey = jobKey;
    if (mounted && onStart != null) {
      setState(onStart);
    } else {
      onStart?.call();
    }
    if (showCommitState) {
      _setCommitState(label, detail: detail);
    }

    Future<T> runOperation() async => operation();

    final scheduled = _commitJobTail.then((_) => runOperation());
    _commitJobTail = scheduled.then<void>((_) {}, onError: (_, stackTrace) {});

    try {
      return await scheduled;
    } finally {
      if (mounted && onFinish != null) {
        setState(onFinish);
      } else {
        onFinish?.call();
      }
      if (_activeCommitJobKey == jobKey) {
        _activeCommitJobKey = null;
      }
      if (showCommitState) {
        _setCommitState(null);
      }
    }
  }

  void _pushCanvasBackgroundHistoryEntry({
    required Color beforeColor,
    required int beforeGradientIndex,
    required Uint8List? beforeImageBytes,
    required double beforeBlurAmount,
    required Color afterColor,
    required int afterGradientIndex,
    required Uint8List? afterImageBytes,
    required double afterBlurAmount,
  }) {
    _undoStack.add(
      _CanvasBackgroundHistoryEntry(
        beforeColor: beforeColor,
        beforeGradientIndex: beforeGradientIndex,
        beforeImageBytes: beforeImageBytes == null
            ? null
            : Uint8List.fromList(beforeImageBytes),
        beforeBlurAmount: beforeBlurAmount,
        afterColor: afterColor,
        afterGradientIndex: afterGradientIndex,
        afterImageBytes: afterImageBytes == null
            ? null
            : Uint8List.fromList(afterImageBytes),
        afterBlurAmount: afterBlurAmount,
      ),
    );
    if (_undoStack.length > _ImageEditorScreenState._maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _replaceLayerWithHistory({
    required int index,
    required _CanvasLayer afterLayer,
    String? afterSelectedLayerId,
  }) {
    final beforeLayer = _layers[index];
    if (beforeLayer.isLocked &&
        beforeLayer.isLocked == afterLayer.isLocked &&
        beforeLayer.isHidden == afterLayer.isHidden) {
      return;
    }
    final boundedAfterLayer = afterLayer.copyWith(
      transform: _clampLayerTransformToPageBounds(
        afterLayer,
        afterLayer.transform,
      ),
    );
    _pushLayerHistoryEntry(
      beforeLayer: beforeLayer,
      afterLayer: boundedAfterLayer,
      afterSelectedLayerId: afterSelectedLayerId,
    );
    setState(() {
      _layers[index] = boundedAfterLayer;
      if (afterSelectedLayerId != null) {
        _selectedLayerId = afterSelectedLayerId;
      }
      if (_selectedLayerId == boundedAfterLayer.id) {
        _transformationController.value = Matrix4.copy(
          boundedAfterLayer.transform,
        );
      }
    });
  }

  bool _isSameMatrix(Matrix4 a, Matrix4 b) {
    for (var i = 0; i < 16; i++) {
      if ((a.storage[i] - b.storage[i]).abs() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  void _syncControllerFromSelection() {
    final layer = _selectedLayer;
    if (layer == null) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    _transformationController.value = _clampLayerTransformToPageBounds(
      layer,
      layer.transform,
    );
  }

  void _restoreSnapshot(_EditorSnapshot snapshot) {
    _layers
      ..clear()
      ..addAll(snapshot.layers.map(_cloneLayer));
    _selectedLayerId = snapshot.selectedLayerId;
    _canvasBackgroundColor = snapshot.canvasBackgroundColor;
    _canvasBackgroundGradientIndex = snapshot.canvasBackgroundGradientIndex;
    _stageBackgroundImageBytes = snapshot.stageBackgroundImageBytes == null
        ? null
        : Uint8List.fromList(snapshot.stageBackgroundImageBytes!);
    _borderStyle = snapshot.borderStyle;
    _borderWidth = snapshot.borderWidth;
    _borderRadius = snapshot.borderRadius;
    _borderColor = snapshot.borderColor;
    _borderTargetLayerId = snapshot.borderTargetLayerId;
    _backgroundBlurAmount = snapshot.backgroundBlurAmount;
    _syncControllerFromSelection();
    _syncSelectedTextEditor();
  }

  void _handleUndo() {
    if (_isDrawBrushMode) {
      if (_drawStrokes.isNotEmpty) {
        _undoDrawStroke();
      }
      return;
    }
    if (_isPhotoStretchMode && _stretchLiveStrokes.isNotEmpty) {
      _undoStretchLiveStroke();
      return;
    }
    if (!_canUndo) {
      return;
    }

    _closeTransientSessionsForHistory();
    final previous = _undoStack.removeLast();
    if (previous is _SnapshotHistoryEntry) {
      _redoStack.add(_SnapshotHistoryEntry(_takeSnapshot()));
      setState(() {
        _restoreSnapshot(previous.snapshot);
      });
      return;
    }
    if (previous is _LayerChangeHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _LayerInsertHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerInsertHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _LayerDeleteHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerDeleteHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _LayerReorderHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyLayerReorderHistoryEntry(previous, useAfter: false);
      });
      return;
    }
    if (previous is _CanvasBackgroundHistoryEntry) {
      _redoStack.add(previous);
      setState(() {
        _applyCanvasBackgroundHistoryEntry(previous, useAfter: false);
      });
    }
  }

  void _handleRedo() {
    if (_isDrawBrushMode) {
      if (_drawRedoStrokes.isNotEmpty) {
        _redoDrawStroke();
      }
      return;
    }
    if (_isPhotoStretchMode && _stretchRedoStrokes.isNotEmpty) {
      _redoStretchLiveStroke();
      return;
    }
    if (!_canRedo) {
      return;
    }

    _closeTransientSessionsForHistory();
    final next = _redoStack.removeLast();
    if (next is _SnapshotHistoryEntry) {
      _undoStack.add(_SnapshotHistoryEntry(_takeSnapshot()));
      setState(() {
        _restoreSnapshot(next.snapshot);
      });
      return;
    }
    if (next is _LayerChangeHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _LayerInsertHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerInsertHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _LayerDeleteHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerDeleteHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _LayerReorderHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyLayerReorderHistoryEntry(next, useAfter: true);
      });
      return;
    }
    if (next is _CanvasBackgroundHistoryEntry) {
      _undoStack.add(next);
      setState(() {
        _applyCanvasBackgroundHistoryEntry(next, useAfter: true);
      });
    }
  }

  void _applyLayerHistoryEntry(
    _LayerChangeHistoryEntry entry, {
    required bool useAfter,
  }) {
    final targetLayer = useAfter ? entry.afterLayer : entry.beforeLayer;
    final targetSelectedLayerId = useAfter
        ? entry.afterSelectedLayerId
        : entry.beforeSelectedLayerId;
    final index = _layers.indexWhere((item) => item.id == entry.layerId);
    if (index == -1) {
      return;
    }
    _layers[index] = _cloneLayer(targetLayer);
    _selectedLayerId = targetSelectedLayerId;
    _syncControllerFromSelection();
    _syncSelectedTextEditor();
  }

  void _applyLayerInsertHistoryEntry(
    _LayerInsertHistoryEntry entry, {
    required bool useAfter,
  }) {
    if (useAfter) {
      final existingIndex = _layers.indexWhere(
        (item) => item.id == entry.layer.id,
      );
      if (existingIndex == -1) {
        final insertIndex = entry.insertIndex.clamp(0, _layers.length);
        _layers.insert(insertIndex, _cloneLayer(entry.layer));
      } else {
        final layer = _layers.removeAt(existingIndex);
        final insertIndex = entry.insertIndex.clamp(0, _layers.length);
        _layers.insert(insertIndex, layer);
      }
      _selectedLayerId = entry.afterSelectedLayerId;
    } else {
      _layers.removeWhere((item) => item.id == entry.layer.id);
      _selectedLayerId = entry.beforeSelectedLayerId;
    }
    _syncControllerFromSelection();
    _syncSelectedTextEditor();
  }

  void _applyLayerDeleteHistoryEntry(
    _LayerDeleteHistoryEntry entry, {
    required bool useAfter,
  }) {
    if (useAfter) {
      _layers.removeWhere((item) => item.id == entry.layer.id);
      _selectedLayerId = entry.afterSelectedLayerId;
    } else {
      final existingIndex = _layers.indexWhere(
        (item) => item.id == entry.layer.id,
      );
      if (existingIndex == -1) {
        final insertIndex = entry.deletedIndex.clamp(0, _layers.length);
        _layers.insert(insertIndex, _cloneLayer(entry.layer));
      }
      _selectedLayerId = entry.beforeSelectedLayerId;
    }
    _syncControllerFromSelection();
    _syncSelectedTextEditor();
  }

  void _applyLayerReorderHistoryEntry(
    _LayerReorderHistoryEntry entry, {
    required bool useAfter,
  }) {
    final currentIndex = _layers.indexWhere((item) => item.id == entry.layerId);
    if (currentIndex == -1) {
      return;
    }
    final targetIndex = useAfter ? entry.toIndex : entry.fromIndex;
    final boundedTargetIndex = targetIndex.clamp(0, _layers.length - 1);
    if (currentIndex != boundedTargetIndex) {
      final layer = _layers.removeAt(currentIndex);
      final insertIndex = boundedTargetIndex.clamp(0, _layers.length);
      _layers.insert(insertIndex, layer);
    }
    _selectedLayerId = useAfter
        ? entry.afterSelectedLayerId
        : entry.beforeSelectedLayerId;
    _syncControllerFromSelection();
    _syncSelectedTextEditor();
  }

  void _applyCanvasBackgroundHistoryEntry(
    _CanvasBackgroundHistoryEntry entry, {
    required bool useAfter,
  }) {
    _canvasBackgroundColor = useAfter ? entry.afterColor : entry.beforeColor;
    _canvasBackgroundGradientIndex = useAfter
        ? entry.afterGradientIndex
        : entry.beforeGradientIndex;
    final bytes = useAfter ? entry.afterImageBytes : entry.beforeImageBytes;
    _stageBackgroundImageBytes = bytes == null
        ? null
        : Uint8List.fromList(bytes);
    _backgroundBlurAmount = useAfter
        ? entry.afterBlurAmount
        : entry.beforeBlurAmount;
    _syncSelectedTextEditor();
  }

  void _closeTransientSessionsForHistory() {
    _commitSelectedTextContentEdit();
    if (_isCropMode) {
      _isCropMode = false;
      _isCropApplying = false;
      _cropSessionLayerId = null;
      _cropSessionImageBytes = null;
      _cropSessionAspectRatio = null;
      _cropSessionInitialAspectRatio = null;
      _cropTransformationController.value = Matrix4.identity();
    }
    if (_isAdjustMode) {
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _adjustSessionNotifier.value = null;
    }
    _setCommitState(null);
  }

  List<double> _matrixToList(Matrix4 matrix) =>
      matrix.storage.map((value) => value.toDouble()).toList(growable: false);

  Matrix4 _matrixFromList(dynamic value) {
    if (value is List && value.length == 16) {
      return Matrix4.fromList(
        value.map((item) => (item as num).toDouble()).toList(growable: false),
      );
    }
    return Matrix4.identity();
  }

  Map<String, dynamic> _serializeLayer(_CanvasLayer layer) {
    return <String, dynamic>{
      'id': layer.id,
      'type': layer.type.name,
      'layerName': layer.layerName,
      'bytes': layer.bytes == null ? null : base64Encode(layer.bytes!),
      'originalPhotoBytes': layer.originalPhotoBytes == null
          ? null
          : base64Encode(layer.originalPhotoBytes!),
      'text': layer.text,
      'legacyRenderText': layer.legacyRenderText,
      'isParagraphText': layer.isParagraphText,
      'sticker': layer.sticker,
      'stickerColor': layer.stickerColor.toARGB32(),
      'textColor': layer.textColor.toARGB32(),
      'textAlign': layer.textAlign.name,
      'textGradientIndex': layer.textGradientIndex,
      'textOpacity': layer.textOpacity,
      'fontSize': layer.fontSize,
      'fontFamily': layer.fontFamily,
      'photoOpacity': layer.photoOpacity,
      'photoBrightness': layer.photoBrightness,
      'photoContrast': layer.photoContrast,
      'photoSaturation': layer.photoSaturation,
      'photoBlur': layer.photoBlur,
      'photoSharpen': layer.photoSharpen,
      'photoGrain': layer.photoGrain,
      'photoVignette': layer.photoVignette,
      'photoMotion': layer.photoMotion,
      'photoTiltShift': layer.photoTiltShift,
      'photoShadows': layer.photoShadows,
      'photoHighlights': layer.photoHighlights,
      'photoTemperature': layer.photoTemperature,
      'photoTint': layer.photoTint,
      'photoPerspectiveX': layer.photoPerspectiveX,
      'photoPerspectiveY': layer.photoPerspectiveY,
      'photoShadowOpacity': layer.photoShadowOpacity,
      'photoShadowBlur': layer.photoShadowBlur,
      'photoShadowOffsetY': layer.photoShadowOffsetY,
      'photoShadowColor': layer.photoShadowColor.toARGB32(),
      'flipPhotoHorizontally': layer.flipPhotoHorizontally,
      'flipPhotoVertically': layer.flipPhotoVertically,
      'isLocked': layer.isLocked,
      'isHidden': layer.isHidden,
      'textLineHeight': layer.textLineHeight,
      'textLetterSpacing': layer.textLetterSpacing,
      'textShadowOpacity': layer.textShadowOpacity,
      'textShadowColor': layer.textShadowColor.toARGB32(),
      'textShadowBlur': layer.textShadowBlur,
      'textShadowOffsetY': layer.textShadowOffsetY,
      'isTextBold': layer.isTextBold,
      'isTextItalic': layer.isTextItalic,
      'isTextUnderline': layer.isTextUnderline,
      'textStrokeColor': layer.textStrokeColor.toARGB32(),
      'textStrokeWidth': layer.textStrokeWidth,
      'textStrokeGradientIndex': layer.textStrokeGradientIndex,
      'textBackgroundColor': layer.textBackgroundColor.toARGB32(),
      'textBackgroundOpacity': layer.textBackgroundOpacity,
      'textBackgroundRadius': layer.textBackgroundRadius,
      'textBackgroundTopPadding': layer.textBackgroundTopPadding,
      'textBackgroundBottomPadding': layer.textBackgroundBottomPadding,
      'photoAspectRatio': layer.photoAspectRatio,
      'photoFixedWidth': layer.photoFixedWidth,
      'photoFixedHeight': layer.photoFixedHeight,
      'psdEditableText': layer.psdEditableText,
      'psdEditableFontSize': layer.psdEditableFontSize,
      'psdEditableFontFamily': layer.psdEditableFontFamily,
      'psdEditableTextAlign': layer.psdEditableTextAlign?.name,
      'photoMaskShape': layer.photoMaskShape,
      'photoMaskScale': layer.photoMaskScale,
      'photoMaskOffsetX': layer.photoMaskOffsetX,
      'photoMaskOffsetY': layer.photoMaskOffsetY,
      'photoMaskFeather': layer.photoMaskFeather,
      'photoFramePreset': layer.photoFramePreset,
      'photoFrameColor': layer.photoFrameColor.toARGB32(),
      'photoFrameThickness': layer.photoFrameThickness,
      'fillPageBounds': layer.fillPageBounds,
      'clipsToLayerBelow': layer.clipsToLayerBelow,
      'layerMaskEnabled': layer.layerMaskEnabled,
      'layerMaskShape': layer.layerMaskShape,
      'layerMaskInverted': layer.layerMaskInverted,
      'layerMaskFeather': layer.layerMaskFeather,
      'layerMaskBrushStrokes': layer.layerMaskBrushStrokes
          .map(
            (stroke) => <String, dynamic>{
              'points': stroke.points
                  .map(
                    (point) => <double>[
                      point.dx.clamp(0.0, 1.0).toDouble(),
                      point.dy.clamp(0.0, 1.0).toDouble(),
                    ],
                  )
                  .toList(growable: false),
              'brushSize': stroke.brushSize,
              'hardness': stroke.hardness,
              'restores': stroke.restores,
            },
          )
          .toList(growable: false),
      'layerStyleOverlayColor': layer.layerStyleOverlayColor.toARGB32(),
      'layerStyleOverlayOpacity': layer.layerStyleOverlayOpacity,
      'layerStyleColorOverlayBlendMode': layer.layerStyleColorOverlayBlendMode,
      'layerStyleStrokeColor': layer.layerStyleStrokeColor.toARGB32(),
      'layerStyleStrokeWidth': layer.layerStyleStrokeWidth,
      'layerStyleShadowColor': layer.layerStyleShadowColor.toARGB32(),
      'layerStyleShadowOpacity': layer.layerStyleShadowOpacity,
      'layerStyleShadowBlur': layer.layerStyleShadowBlur,
      'layerStyleShadowSpread': layer.layerStyleShadowSpread,
      'layerStyleShadowOffsetX': layer.layerStyleShadowOffsetX,
      'layerStyleShadowOffsetY': layer.layerStyleShadowOffsetY,
      'layerStyleShadowBlendMode': layer.layerStyleShadowBlendMode,
      'layerStyleShadowContour': layer.layerStyleShadowContour,
      'layerStyleShadowNoise': layer.layerStyleShadowNoise,
      'layerStyleUseGlobalLight': layer.layerStyleUseGlobalLight,
      'layerStyleGlobalLightAngle': layer.layerStyleGlobalLightAngle,
      'layerStyleGlobalLightAltitude': layer.layerStyleGlobalLightAltitude,
      'layerStyleBevelEnabled': layer.layerStyleBevelEnabled,
      'layerStyleBevelStyle': layer.layerStyleBevelStyle,
      'layerStyleBevelTechnique': layer.layerStyleBevelTechnique,
      'layerStyleBevelDirection': layer.layerStyleBevelDirection,
      'layerStyleBevelDepth': layer.layerStyleBevelDepth,
      'layerStyleBevelSize': layer.layerStyleBevelSize,
      'layerStyleBevelSoften': layer.layerStyleBevelSoften,
      'layerStyleBevelAngle': layer.layerStyleBevelAngle,
      'layerStyleBevelAltitude': layer.layerStyleBevelAltitude,
      'layerStyleBevelHighlightColor': layer.layerStyleBevelHighlightColor
          .toARGB32(),
      'layerStyleBevelHighlightOpacity': layer.layerStyleBevelHighlightOpacity,
      'layerStyleBevelShadowColor': layer.layerStyleBevelShadowColor.toARGB32(),
      'layerStyleBevelShadowOpacity': layer.layerStyleBevelShadowOpacity,
      'layerStyleContour': layer.layerStyleContour,
      'layerStyleTextureEnabled': layer.layerStyleTextureEnabled,
      'layerStyleTextureScale': layer.layerStyleTextureScale,
      'layerStyleTextureDepth': layer.layerStyleTextureDepth,
      'layerStyleStrokeOpacity': layer.layerStyleStrokeOpacity,
      'layerStyleStrokePosition': layer.layerStyleStrokePosition,
      'layerStyleStrokeBlendMode': layer.layerStyleStrokeBlendMode,
      'layerStyleInnerShadowColor': layer.layerStyleInnerShadowColor.toARGB32(),
      'layerStyleInnerShadowOpacity': layer.layerStyleInnerShadowOpacity,
      'layerStyleInnerShadowBlur': layer.layerStyleInnerShadowBlur,
      'layerStyleInnerShadowChoke': layer.layerStyleInnerShadowChoke,
      'layerStyleInnerShadowDistance': layer.layerStyleInnerShadowDistance,
      'layerStyleInnerShadowAngle': layer.layerStyleInnerShadowAngle,
      'layerStyleInnerShadowBlendMode': layer.layerStyleInnerShadowBlendMode,
      'layerStyleInnerShadowContour': layer.layerStyleInnerShadowContour,
      'layerStyleInnerShadowNoise': layer.layerStyleInnerShadowNoise,
      'layerStyleGradientOverlayEnabled':
          layer.layerStyleGradientOverlayEnabled,
      'layerStyleGradientOverlayIndex': layer.layerStyleGradientOverlayIndex,
      'layerStyleGradientOverlayOpacity':
          layer.layerStyleGradientOverlayOpacity,
      'layerStyleGradientOverlayAngle': layer.layerStyleGradientOverlayAngle,
      'layerStyleGradientOverlayStyle': layer.layerStyleGradientOverlayStyle,
      'layerStyleGradientOverlayScale': layer.layerStyleGradientOverlayScale,
      'layerStyleGradientOverlayBlendMode':
          layer.layerStyleGradientOverlayBlendMode,
      'layerStyleGradientOverlayReversed':
          layer.layerStyleGradientOverlayReversed,
      'layerStyleGradientOverlayDither': layer.layerStyleGradientOverlayDither,
      'layerStyleOuterGlowColor': layer.layerStyleOuterGlowColor.toARGB32(),
      'layerStyleOuterGlowOpacity': layer.layerStyleOuterGlowOpacity,
      'layerStyleOuterGlowSize': layer.layerStyleOuterGlowSize,
      'layerStyleOuterGlowSpread': layer.layerStyleOuterGlowSpread,
      'layerStyleOuterGlowNoise': layer.layerStyleOuterGlowNoise,
      'layerStyleOuterGlowContour': layer.layerStyleOuterGlowContour,
      'layerStyleOuterGlowRange': layer.layerStyleOuterGlowRange,
      'layerStyleOuterGlowJitter': layer.layerStyleOuterGlowJitter,
      'layerStyleOuterGlowBlendMode': layer.layerStyleOuterGlowBlendMode,
      'layerStyleInnerGlowColor': layer.layerStyleInnerGlowColor.toARGB32(),
      'layerStyleInnerGlowOpacity': layer.layerStyleInnerGlowOpacity,
      'layerStyleInnerGlowSize': layer.layerStyleInnerGlowSize,
      'layerStyleInnerGlowSpread': layer.layerStyleInnerGlowSpread,
      'layerStyleInnerGlowNoise': layer.layerStyleInnerGlowNoise,
      'layerStyleInnerGlowSource': layer.layerStyleInnerGlowSource,
      'layerStyleInnerGlowContour': layer.layerStyleInnerGlowContour,
      'layerStyleInnerGlowRange': layer.layerStyleInnerGlowRange,
      'layerStyleInnerGlowJitter': layer.layerStyleInnerGlowJitter,
      'layerStyleInnerGlowBlendMode': layer.layerStyleInnerGlowBlendMode,
      'layerStyleSatinColor': layer.layerStyleSatinColor.toARGB32(),
      'layerStyleSatinOpacity': layer.layerStyleSatinOpacity,
      'layerStyleSatinAngle': layer.layerStyleSatinAngle,
      'layerStyleSatinDistance': layer.layerStyleSatinDistance,
      'layerStyleSatinSize': layer.layerStyleSatinSize,
      'layerStyleSatinInverted': layer.layerStyleSatinInverted,
      'layerStyleSatinBlendMode': layer.layerStyleSatinBlendMode,
      'layerStylePatternOverlayEnabled': layer.layerStylePatternOverlayEnabled,
      'layerStylePatternOverlayOpacity': layer.layerStylePatternOverlayOpacity,
      'layerStylePatternOverlayScale': layer.layerStylePatternOverlayScale,
      'layerStylePatternOverlayBlendMode':
          layer.layerStylePatternOverlayBlendMode,
      'layerStylePatternOverlayPreset': layer.layerStylePatternOverlayPreset,
      'isSmartObject': layer.isSmartObject,
      'smartObjectSourceBytes': layer.smartObjectSourceBytes == null
          ? null
          : base64Encode(layer.smartObjectSourceBytes!),
      'groupId': layer.groupId,
      'groupName': layer.groupName,
      'linkGroupId': layer.linkGroupId,
      'blendMode': layer.blendMode.name,
      'transform': _matrixToList(layer.transform),
    };
  }

  List<_LayerMaskBrushStroke> _deserializeLayerMaskBrushStrokes(dynamic raw) {
    if (raw is! List) {
      return const <_LayerMaskBrushStroke>[];
    }
    final strokes = <_LayerMaskBrushStroke>[];
    for (final strokeRaw in raw) {
      if (strokeRaw is! Map) {
        continue;
      }
      final rawPoints = strokeRaw['points'];
      if (rawPoints is! List) {
        continue;
      }
      final points = <Offset>[];
      for (final pointRaw in rawPoints) {
        if (pointRaw is List && pointRaw.length >= 2) {
          final dx = pointRaw[0];
          final dy = pointRaw[1];
          if (dx is num && dy is num) {
            points.add(
              Offset(
                dx.toDouble().clamp(0.0, 1.0),
                dy.toDouble().clamp(0.0, 1.0),
              ),
            );
          }
        }
      }
      if (points.isEmpty) {
        continue;
      }
      strokes.add(
        _LayerMaskBrushStroke(
          points: points,
          brushSize: ((strokeRaw['brushSize'] as num?)?.toDouble() ?? 42)
              .clamp(4.0, 220.0)
              .toDouble(),
          hardness: ((strokeRaw['hardness'] as num?)?.toDouble() ?? 0.35)
              .clamp(0.0, 1.0)
              .toDouble(),
          restores: (strokeRaw['restores'] as bool?) ?? false,
        ),
      );
    }
    return List<_LayerMaskBrushStroke>.unmodifiable(strokes);
  }

  _CanvasLayer? _deserializeLayer(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    try {
      final typeName = raw['type'] as String? ?? _CanvasLayerType.text.name;
      final type = _CanvasLayerType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => _CanvasLayerType.text,
      );
      final textAlignName =
          raw['textAlign'] as String? ?? TextAlign.center.name;
      final textAlign = TextAlign.values.firstWhere(
        (item) => item.name == textAlignName,
        orElse: () => TextAlign.center,
      );
      final psdTextAlignName = raw['psdEditableTextAlign'] as String?;
      final psdTextAlign = psdTextAlignName == null
          ? null
          : TextAlign.values.firstWhere(
              (item) => item.name == psdTextAlignName,
              orElse: () => TextAlign.center,
            );
      return _CanvasLayer(
        id:
            raw['id'] as String? ??
            'layer_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        layerName: raw['layerName'] as String? ?? '',
        bytes: raw['bytes'] == null
            ? null
            : base64Decode(raw['bytes'] as String),
        originalPhotoBytes: raw['originalPhotoBytes'] == null
            ? null
            : base64Decode(raw['originalPhotoBytes'] as String),
        text: raw['text'] as String?,
        legacyRenderText: raw['legacyRenderText'] as String?,
        isParagraphText: raw['isParagraphText'] as bool? ?? true,
        sticker: raw['sticker'] as String?,
        stickerColor: Color(
          (raw['stickerColor'] as num?)?.toInt() ?? 0xFF111827,
        ),
        textColor: Color((raw['textColor'] as num?)?.toInt() ?? 0xFF0F172A),
        textAlign: textAlign,
        textGradientIndex: (raw['textGradientIndex'] as num?)?.toInt() ?? -1,
        textOpacity: (raw['textOpacity'] as num?)?.toDouble() ?? 1,
        fontSize: (raw['fontSize'] as num?)?.toDouble() ?? 40,
        fontFamily:
            raw['fontFamily'] as String? ?? 'Anek Telugu Condensed Regular',
        photoOpacity: (raw['photoOpacity'] as num?)?.toDouble() ?? 1,
        photoBrightness: (raw['photoBrightness'] as num?)?.toDouble() ?? 0,
        photoContrast: (raw['photoContrast'] as num?)?.toDouble() ?? 1,
        photoSaturation: (raw['photoSaturation'] as num?)?.toDouble() ?? 1,
        photoBlur: (raw['photoBlur'] as num?)?.toDouble() ?? 0,
        photoSharpen: (raw['photoSharpen'] as num?)?.toDouble() ?? 0,
        photoGrain: (raw['photoGrain'] as num?)?.toDouble() ?? 0,
        photoVignette: (raw['photoVignette'] as num?)?.toDouble() ?? 0,
        photoMotion: (raw['photoMotion'] as num?)?.toDouble() ?? 0,
        photoTiltShift: (raw['photoTiltShift'] as num?)?.toDouble() ?? 0,
        photoShadows: (raw['photoShadows'] as num?)?.toDouble() ?? 0,
        photoHighlights: (raw['photoHighlights'] as num?)?.toDouble() ?? 0,
        photoTemperature: (raw['photoTemperature'] as num?)?.toDouble() ?? 0,
        photoTint: (raw['photoTint'] as num?)?.toDouble() ?? 0,
        photoPerspectiveX: (raw['photoPerspectiveX'] as num?)?.toDouble() ?? 0,
        photoPerspectiveY: (raw['photoPerspectiveY'] as num?)?.toDouble() ?? 0,
        photoShadowOpacity:
            (raw['photoShadowOpacity'] as num?)?.toDouble() ?? 0,
        photoShadowBlur: (raw['photoShadowBlur'] as num?)?.toDouble() ?? 0,
        photoShadowOffsetY:
            (raw['photoShadowOffsetY'] as num?)?.toDouble() ?? 0,
        photoShadowColor: Color(
          (raw['photoShadowColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        flipPhotoHorizontally: (raw['flipPhotoHorizontally'] as bool?) ?? false,
        flipPhotoVertically: (raw['flipPhotoVertically'] as bool?) ?? false,
        isLocked: (raw['isLocked'] as bool?) ?? false,
        isHidden: (raw['isHidden'] as bool?) ?? false,
        textLineHeight: (raw['textLineHeight'] as num?)?.toDouble() ?? 1.15,
        textLetterSpacing: (raw['textLetterSpacing'] as num?)?.toDouble() ?? 0,
        textShadowOpacity: (raw['textShadowOpacity'] as num?)?.toDouble() ?? 0,
        textShadowColor: Color(
          (raw['textShadowColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        textShadowBlur: (raw['textShadowBlur'] as num?)?.toDouble() ?? 0,
        textShadowOffsetY: (raw['textShadowOffsetY'] as num?)?.toDouble() ?? 0,
        isTextBold: (raw['isTextBold'] as bool?) ?? false,
        isTextItalic: (raw['isTextItalic'] as bool?) ?? false,
        isTextUnderline: (raw['isTextUnderline'] as bool?) ?? false,
        textStrokeColor: Color(
          (raw['textStrokeColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        textStrokeWidth: (raw['textStrokeWidth'] as num?)?.toDouble() ?? 0,
        textStrokeGradientIndex:
            (raw['textStrokeGradientIndex'] as num?)?.toInt() ?? -1,
        textBackgroundColor: Color(
          (raw['textBackgroundColor'] as num?)?.toInt() ?? 0x00000000,
        ),
        textBackgroundOpacity:
            (raw['textBackgroundOpacity'] as num?)?.toDouble() ?? 0,
        textBackgroundRadius:
            (raw['textBackgroundRadius'] as num?)?.toDouble() ?? 0,
        textBackgroundTopPadding:
            (raw['textBackgroundTopPadding'] as num?)?.toDouble() ?? 8,
        textBackgroundBottomPadding:
            (raw['textBackgroundBottomPadding'] as num?)?.toDouble() ?? 8,
        photoAspectRatio: (raw['photoAspectRatio'] as num?)?.toDouble(),
        photoFixedWidth: (raw['photoFixedWidth'] as num?)?.toDouble(),
        photoFixedHeight: (raw['photoFixedHeight'] as num?)?.toDouble(),
        psdEditableText: raw['psdEditableText'] as String?,
        psdEditableFontSize: (raw['psdEditableFontSize'] as num?)?.toDouble(),
        psdEditableFontFamily: raw['psdEditableFontFamily'] as String?,
        psdEditableTextAlign: psdTextAlign,
        photoMaskShape: raw['photoMaskShape'] as String? ?? '',
        photoMaskScale: (raw['photoMaskScale'] as num?)?.toDouble() ?? 1,
        photoMaskOffsetX: (raw['photoMaskOffsetX'] as num?)?.toDouble() ?? 0,
        photoMaskOffsetY: (raw['photoMaskOffsetY'] as num?)?.toDouble() ?? 0,
        photoMaskFeather: (raw['photoMaskFeather'] as num?)?.toDouble() ?? 0,
        photoFramePreset: raw['photoFramePreset'] as String? ?? '',
        photoFrameColor: Color(
          (raw['photoFrameColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        ),
        photoFrameThickness:
            (raw['photoFrameThickness'] as num?)?.toDouble() ?? 50,
        fillPageBounds: (raw['fillPageBounds'] as bool?) ?? false,
        clipsToLayerBelow: (raw['clipsToLayerBelow'] as bool?) ?? false,
        layerMaskEnabled: (raw['layerMaskEnabled'] as bool?) ?? false,
        layerMaskShape: raw['layerMaskShape'] as String? ?? '',
        layerMaskInverted: (raw['layerMaskInverted'] as bool?) ?? false,
        layerMaskFeather: (raw['layerMaskFeather'] as num?)?.toDouble() ?? 0,
        layerMaskBrushStrokes: _deserializeLayerMaskBrushStrokes(
          raw['layerMaskBrushStrokes'],
        ),
        layerStyleOverlayColor: Color(
          (raw['layerStyleOverlayColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        layerStyleOverlayOpacity:
            (raw['layerStyleOverlayOpacity'] as num?)?.toDouble() ?? 0,
        layerStyleColorOverlayBlendMode:
            (raw['layerStyleColorOverlayBlendMode'] as num?)?.toInt() ?? 0,
        layerStyleStrokeColor: Color(
          (raw['layerStyleStrokeColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        ),
        layerStyleStrokeWidth:
            (raw['layerStyleStrokeWidth'] as num?)?.toDouble() ?? 0,
        layerStyleShadowColor: Color(
          (raw['layerStyleShadowColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        layerStyleShadowOpacity:
            (raw['layerStyleShadowOpacity'] as num?)?.toDouble() ?? 0,
        layerStyleShadowBlur:
            (raw['layerStyleShadowBlur'] as num?)?.toDouble() ?? 12,
        layerStyleShadowSpread:
            (raw['layerStyleShadowSpread'] as num?)?.toDouble() ?? 0,
        layerStyleShadowOffsetX:
            (raw['layerStyleShadowOffsetX'] as num?)?.toDouble() ?? 0,
        layerStyleShadowOffsetY:
            (raw['layerStyleShadowOffsetY'] as num?)?.toDouble() ?? 6,
        layerStyleShadowBlendMode:
            (raw['layerStyleShadowBlendMode'] as num?)?.toInt() ?? 0,
        layerStyleShadowContour:
            (raw['layerStyleShadowContour'] as num?)?.toInt() ?? 0,
        layerStyleShadowNoise:
            (raw['layerStyleShadowNoise'] as num?)?.toDouble() ?? 0,
        layerStyleUseGlobalLight:
            (raw['layerStyleUseGlobalLight'] as bool?) ?? false,
        layerStyleGlobalLightAngle:
            (raw['layerStyleGlobalLightAngle'] as num?)?.toDouble() ?? 120,
        layerStyleGlobalLightAltitude:
            (raw['layerStyleGlobalLightAltitude'] as num?)?.toDouble() ?? 30,
        layerStyleBevelEnabled:
            (raw['layerStyleBevelEnabled'] as bool?) ?? false,
        layerStyleBevelStyle:
            (raw['layerStyleBevelStyle'] as num?)?.toInt() ?? 0,
        layerStyleBevelTechnique:
            (raw['layerStyleBevelTechnique'] as num?)?.toInt() ?? 0,
        layerStyleBevelDirection:
            (raw['layerStyleBevelDirection'] as num?)?.toInt() ?? 0,
        layerStyleBevelDepth:
            (raw['layerStyleBevelDepth'] as num?)?.toDouble() ?? 35,
        layerStyleBevelSize:
            (raw['layerStyleBevelSize'] as num?)?.toDouble() ?? 8,
        layerStyleBevelSoften:
            (raw['layerStyleBevelSoften'] as num?)?.toDouble() ?? 2,
        layerStyleBevelAngle:
            (raw['layerStyleBevelAngle'] as num?)?.toDouble() ?? 120,
        layerStyleBevelAltitude:
            (raw['layerStyleBevelAltitude'] as num?)?.toDouble() ?? 30,
        layerStyleBevelHighlightColor: Color(
          (raw['layerStyleBevelHighlightColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        ),
        layerStyleBevelHighlightOpacity:
            (raw['layerStyleBevelHighlightOpacity'] as num?)?.toDouble() ??
            0.75,
        layerStyleBevelShadowColor: Color(
          (raw['layerStyleBevelShadowColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        layerStyleBevelShadowOpacity:
            (raw['layerStyleBevelShadowOpacity'] as num?)?.toDouble() ?? 0.75,
        layerStyleContour: (raw['layerStyleContour'] as num?)?.toInt() ?? 0,
        layerStyleTextureEnabled:
            (raw['layerStyleTextureEnabled'] as bool?) ?? false,
        layerStyleTextureScale:
            (raw['layerStyleTextureScale'] as num?)?.toDouble() ?? 36,
        layerStyleTextureDepth:
            (raw['layerStyleTextureDepth'] as num?)?.toDouble() ?? 18,
        layerStyleStrokeOpacity:
            (raw['layerStyleStrokeOpacity'] as num?)?.toDouble() ?? 1,
        layerStyleStrokePosition:
            (raw['layerStyleStrokePosition'] as num?)?.toInt() ?? 0,
        layerStyleStrokeBlendMode:
            (raw['layerStyleStrokeBlendMode'] as num?)?.toInt() ?? 0,
        layerStyleInnerShadowColor: Color(
          (raw['layerStyleInnerShadowColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        layerStyleInnerShadowOpacity:
            (raw['layerStyleInnerShadowOpacity'] as num?)?.toDouble() ?? 0,
        layerStyleInnerShadowBlur:
            (raw['layerStyleInnerShadowBlur'] as num?)?.toDouble() ?? 12,
        layerStyleInnerShadowChoke:
            (raw['layerStyleInnerShadowChoke'] as num?)?.toDouble() ?? 0,
        layerStyleInnerShadowDistance:
            (raw['layerStyleInnerShadowDistance'] as num?)?.toDouble() ?? 8,
        layerStyleInnerShadowAngle:
            (raw['layerStyleInnerShadowAngle'] as num?)?.toDouble() ?? 120,
        layerStyleInnerShadowBlendMode:
            (raw['layerStyleInnerShadowBlendMode'] as num?)?.toInt() ?? 0,
        layerStyleInnerShadowContour:
            (raw['layerStyleInnerShadowContour'] as num?)?.toInt() ?? 0,
        layerStyleInnerShadowNoise:
            (raw['layerStyleInnerShadowNoise'] as num?)?.toDouble() ?? 0,
        layerStyleGradientOverlayEnabled:
            (raw['layerStyleGradientOverlayEnabled'] as bool?) ?? false,
        layerStyleGradientOverlayIndex:
            (raw['layerStyleGradientOverlayIndex'] as num?)?.toInt() ?? 0,
        layerStyleGradientOverlayOpacity:
            (raw['layerStyleGradientOverlayOpacity'] as num?)?.toDouble() ?? 0,
        layerStyleGradientOverlayAngle:
            (raw['layerStyleGradientOverlayAngle'] as num?)?.toDouble() ?? 0,
        layerStyleGradientOverlayStyle:
            (raw['layerStyleGradientOverlayStyle'] as num?)?.toInt() ?? 0,
        layerStyleGradientOverlayScale:
            (raw['layerStyleGradientOverlayScale'] as num?)?.toDouble() ?? 100,
        layerStyleGradientOverlayBlendMode:
            (raw['layerStyleGradientOverlayBlendMode'] as num?)?.toInt() ?? 0,
        layerStyleGradientOverlayReversed:
            (raw['layerStyleGradientOverlayReversed'] as bool?) ?? false,
        layerStyleGradientOverlayDither:
            (raw['layerStyleGradientOverlayDither'] as bool?) ?? false,
        layerStyleOuterGlowColor: Color(
          (raw['layerStyleOuterGlowColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        ),
        layerStyleOuterGlowOpacity:
            (raw['layerStyleOuterGlowOpacity'] as num?)?.toDouble() ?? 0,
        layerStyleOuterGlowSize:
            (raw['layerStyleOuterGlowSize'] as num?)?.toDouble() ?? 18,
        layerStyleOuterGlowSpread:
            (raw['layerStyleOuterGlowSpread'] as num?)?.toDouble() ?? 0,
        layerStyleOuterGlowNoise:
            (raw['layerStyleOuterGlowNoise'] as num?)?.toDouble() ?? 0,
        layerStyleOuterGlowContour:
            (raw['layerStyleOuterGlowContour'] as num?)?.toInt() ?? 0,
        layerStyleOuterGlowRange:
            (raw['layerStyleOuterGlowRange'] as num?)?.toDouble() ?? 50,
        layerStyleOuterGlowJitter:
            (raw['layerStyleOuterGlowJitter'] as num?)?.toDouble() ?? 0,
        layerStyleOuterGlowBlendMode:
            (raw['layerStyleOuterGlowBlendMode'] as num?)?.toInt() ?? 0,
        layerStyleInnerGlowColor: Color(
          (raw['layerStyleInnerGlowColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        ),
        layerStyleInnerGlowOpacity:
            (raw['layerStyleInnerGlowOpacity'] as num?)?.toDouble() ?? 0,
        layerStyleInnerGlowSize:
            (raw['layerStyleInnerGlowSize'] as num?)?.toDouble() ?? 18,
        layerStyleInnerGlowSpread:
            (raw['layerStyleInnerGlowSpread'] as num?)?.toDouble() ?? 0,
        layerStyleInnerGlowNoise:
            (raw['layerStyleInnerGlowNoise'] as num?)?.toDouble() ?? 0,
        layerStyleInnerGlowSource:
            (raw['layerStyleInnerGlowSource'] as num?)?.toInt() ?? 0,
        layerStyleInnerGlowContour:
            (raw['layerStyleInnerGlowContour'] as num?)?.toInt() ?? 0,
        layerStyleInnerGlowRange:
            (raw['layerStyleInnerGlowRange'] as num?)?.toDouble() ?? 50,
        layerStyleInnerGlowJitter:
            (raw['layerStyleInnerGlowJitter'] as num?)?.toDouble() ?? 0,
        layerStyleInnerGlowBlendMode:
            (raw['layerStyleInnerGlowBlendMode'] as num?)?.toInt() ?? 0,
        layerStyleSatinColor: Color(
          (raw['layerStyleSatinColor'] as num?)?.toInt() ?? 0xFF000000,
        ),
        layerStyleSatinOpacity:
            (raw['layerStyleSatinOpacity'] as num?)?.toDouble() ?? 0,
        layerStyleSatinAngle:
            (raw['layerStyleSatinAngle'] as num?)?.toDouble() ?? 20,
        layerStyleSatinDistance:
            (raw['layerStyleSatinDistance'] as num?)?.toDouble() ?? 12,
        layerStyleSatinSize:
            (raw['layerStyleSatinSize'] as num?)?.toDouble() ?? 18,
        layerStyleSatinInverted:
            (raw['layerStyleSatinInverted'] as bool?) ?? false,
        layerStyleSatinBlendMode:
            (raw['layerStyleSatinBlendMode'] as num?)?.toInt() ?? 0,
        layerStylePatternOverlayEnabled:
            (raw['layerStylePatternOverlayEnabled'] as bool?) ?? false,
        layerStylePatternOverlayOpacity:
            (raw['layerStylePatternOverlayOpacity'] as num?)?.toDouble() ?? 0,
        layerStylePatternOverlayScale:
            (raw['layerStylePatternOverlayScale'] as num?)?.toDouble() ?? 36,
        layerStylePatternOverlayBlendMode:
            (raw['layerStylePatternOverlayBlendMode'] as num?)?.toInt() ?? 0,
        layerStylePatternOverlayPreset:
            (raw['layerStylePatternOverlayPreset'] as num?)?.toInt() ?? 0,
        isSmartObject: (raw['isSmartObject'] as bool?) ?? false,
        smartObjectSourceBytes: raw['smartObjectSourceBytes'] == null
            ? null
            : base64Decode(raw['smartObjectSourceBytes'] as String),
        groupId: raw['groupId'] as String? ?? '',
        groupName: raw['groupName'] as String? ?? '',
        linkGroupId: raw['linkGroupId'] as String? ?? '',
        blendMode: BlendMode.values.firstWhere(
          (mode) => mode.name == raw['blendMode'],
          orElse: () => BlendMode.srcOver,
        ),
        transform: _matrixFromList(raw['transform']),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _serializeEditorDraft() {
    return <String, dynamic>{
      'layerSeed': _layerSeed,
      'selectedLayerId': _selectedLayerId,
      'canvasBackgroundColor': _canvasBackgroundColor.toARGB32(),
      'canvasBackgroundGradientIndex': _canvasBackgroundGradientIndex,
      'stageBackgroundImageBytes': _stageBackgroundImageBytes == null
          ? null
          : base64Encode(_stageBackgroundImageBytes!),
      'borderStyle': _borderStyle.name,
      'borderWidth': _borderWidth,
      'borderRadius': _borderRadius,
      'borderColor': _borderColor.toARGB32(),
      'borderTargetLayerId': _borderTargetLayerId,
      'backgroundBlurAmount': _backgroundBlurAmount,
      'pageAspectRatio': _pageAspectRatio,
      'pageAspectRatioAutoFromImage': _pageAspectRatioAutoFromImage,
      'layers': _layers.map(_serializeLayer).toList(growable: false),
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  void _scheduleAutosave() {
    _pendingAutosave = false;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () {
      unawaited(_persistAutosaveDraft());
    });
  }

  Future<void> _persistAutosaveDraft() async {
    try {
      final file = await _draftStorageService.getAutosaveFile();
      await file.writeAsString(jsonEncode(_serializeEditorDraft()));
    } catch (_) {}
  }

  Future<void> _restoreFromDecodedDraft(
    Map decoded, {
    bool resetHistory = true,
  }) async {
    final rawLayers = decoded['layers'];
    if (rawLayers is! List || rawLayers.isEmpty) {
      return;
    }
    final restoredLayers = rawLayers
        .map(_deserializeLayer)
        .whereType<_CanvasLayer>()
        .toList(growable: true);
    if (restoredLayers.isEmpty) {
      return;
    }
    _isRestoringDraft = true;
    setState(() {
      _layers
        ..clear()
        ..addAll(restoredLayers);
      _layerSeed =
          (decoded['layerSeed'] as num?)?.toInt() ?? restoredLayers.length;
      _selectedLayerId = decoded['selectedLayerId'] as String?;
      _canvasBackgroundColor = Color(
        (decoded['canvasBackgroundColor'] as num?)?.toInt() ?? 0xFF000000,
      );
      _canvasBackgroundGradientIndex =
          (decoded['canvasBackgroundGradientIndex'] as num?)?.toInt() ?? -1;
      _stageBackgroundImageBytes =
          decoded['stageBackgroundImageBytes'] is String
          ? base64Decode(decoded['stageBackgroundImageBytes'] as String)
          : null;
      _borderStyle = _BorderStyle.values.firstWhere(
        (item) => item.name == (decoded['borderStyle'] as String?),
        orElse: () => _BorderStyle.none,
      );
      _borderWidth = (decoded['borderWidth'] as num?)?.toDouble() ?? 1.5;
      _borderRadius = (decoded['borderRadius'] as num?)?.toDouble() ?? 0;
      _borderColor = Color(
        (decoded['borderColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      );
      _borderTargetLayerId = decoded['borderTargetLayerId'] as String?;
      _backgroundBlurAmount =
          (decoded['backgroundBlurAmount'] as num?)?.toDouble() ?? 0;
      _pageAspectRatio = (decoded['pageAspectRatio'] as num?)?.toDouble();
      _pageAspectRatioAutoFromImage =
          (decoded['pageAspectRatioAutoFromImage'] as bool?) ?? false;
      _syncControllerFromSelection();
      _syncSelectedTextEditor();
    });
    if (resetHistory) {
      _undoStack.clear();
      _redoStack.clear();
    }
    _isRestoringDraft = false;
  }

  Future<void> _restoreAutosavedDraftIfAvailable() async {
    if (widget.pageConfig != null) {
      return;
    }
    try {
      final file = await _draftStorageService.getAutosaveFile();
      if (!await file.exists()) {
        return;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return;
      }
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        return;
      }
      if (!mounted) {
        return;
      }
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final strings = context.strings;
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            title: Text(
              strings.localized(
                telugu: 'డ్రాఫ్ట్‌ను తిరిగి తెరవాలా',
                english: 'Recover Draft',
              ),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              strings.localized(
                telugu:
                    'చివరిసారి ఆటోసేవ్ అయిన ప్రాజెక్ట్ దొరికింది. దాన్ని తిరిగి తెరవాలా?',
                english:
                    'A last autosaved project was found. Do you want to restore it?',
              ),
              style: const TextStyle(color: Color(0xFF475569), height: 1.4),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  strings.localized(telugu: 'వద్దు', english: 'No'),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  strings.localized(
                    telugu: 'తిరిగి తెరవండి',
                    english: 'Restore',
                  ),
                ),
              ),
            ],
          );
        },
      );
      if (shouldRestore != true) {
        return;
      }
      await _restoreFromDecodedDraft(decoded);
    } catch (_) {}
  }

  Future<void> _saveCurrentManualDraft() async {
    try {
      final file = await _draftStorageService.createManualDraftFile();
      await file.writeAsString(jsonEncode(_serializeEditorDraft()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'డ్రాఫ్ట్ యాప్ స్టోరేజీలో సేవ్ అయింది',
              english: 'Draft saved in app storage',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'డ్రాఫ్ట్ సేవ్ కాలేదు',
              english: 'Draft save failed',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openDraftsScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => _DraftsScreen(
          storageService: _draftStorageService,
          onSaveCurrentDraft: _saveCurrentManualDraft,
          onOpenDraft: (Map<String, dynamic> draft) async {
            await _restoreFromDecodedDraft(draft);
          },
        ),
      ),
    );
  }
}
