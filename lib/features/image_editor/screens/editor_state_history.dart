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
  }) async {
    if (_activeCommitJobKey != null) {
      if (showBusyMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
    _setCommitState(label, detail: detail);

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
      _setCommitState(null);
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
    _pushLayerHistoryEntry(
      beforeLayer: beforeLayer,
      afterLayer: afterLayer,
      afterSelectedLayerId: afterSelectedLayerId,
    );
    setState(() {
      _layers[index] = afterLayer;
      if (afterSelectedLayerId != null) {
        _selectedLayerId = afterSelectedLayerId;
      }
      if (_selectedLayerId == afterLayer.id) {
        _transformationController.value = Matrix4.copy(afterLayer.transform);
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
    _transformationController.value = Matrix4.copy(layer.transform);
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
    _borderTargetLayerId = snapshot.borderTargetLayerId;
    _backgroundBlurAmount = snapshot.backgroundBlurAmount;
    _syncControllerFromSelection();
    _syncSelectedTextEditor();
  }

  void _handleUndo() {
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
      'bytes': layer.bytes == null ? null : base64Encode(layer.bytes!),
      'originalPhotoBytes': layer.originalPhotoBytes == null
          ? null
          : base64Encode(layer.originalPhotoBytes!),
      'text': layer.text,
      'legacyRenderText': layer.legacyRenderText,
      'sticker': layer.sticker,
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
      'flipPhotoHorizontally': layer.flipPhotoHorizontally,
      'flipPhotoVertically': layer.flipPhotoVertically,
      'isLocked': layer.isLocked,
      'isHidden': layer.isHidden,
      'textLineHeight': layer.textLineHeight,
      'textLetterSpacing': layer.textLetterSpacing,
      'textShadowOpacity': layer.textShadowOpacity,
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
      'photoAspectRatio': layer.photoAspectRatio,
      'transform': _matrixToList(layer.transform),
    };
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
      return _CanvasLayer(
        id:
            raw['id'] as String? ??
            'layer_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        bytes: raw['bytes'] == null
            ? null
            : base64Decode(raw['bytes'] as String),
        originalPhotoBytes: raw['originalPhotoBytes'] == null
            ? null
            : base64Decode(raw['originalPhotoBytes'] as String),
        text: raw['text'] as String?,
        legacyRenderText: raw['legacyRenderText'] as String?,
        sticker: raw['sticker'] as String?,
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
        flipPhotoHorizontally: (raw['flipPhotoHorizontally'] as bool?) ?? false,
        flipPhotoVertically: (raw['flipPhotoVertically'] as bool?) ?? false,
        isLocked: (raw['isLocked'] as bool?) ?? false,
        isHidden: (raw['isHidden'] as bool?) ?? false,
        textLineHeight: (raw['textLineHeight'] as num?)?.toDouble() ?? 1.15,
        textLetterSpacing: (raw['textLetterSpacing'] as num?)?.toDouble() ?? 0,
        textShadowOpacity: (raw['textShadowOpacity'] as num?)?.toDouble() ?? 0,
        textShadowBlur: (raw['textShadowBlur'] as num?)?.toDouble() ?? 0,
        textShadowOffsetY: (raw['textShadowOffsetY'] as num?)?.toDouble() ?? 0,
        isTextBold: (raw['isTextBold'] as bool?) ?? true,
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
        photoAspectRatio: (raw['photoAspectRatio'] as num?)?.toDouble(),
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
            title: Text(
              strings.localized(
                telugu: 'Recover Draft',
                english: 'Recover Draft',
              ),
            ),
            content: Text(
              strings.localized(
                telugu:
                    'Last autosaved project dorikindi. Danni restore cheyala?',
                english:
                    'A last autosaved project was found. Do you want to restore it?',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.localized(telugu: 'No', english: 'No')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  strings.localized(telugu: 'Restore', english: 'Restore'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Draft saved in app storage',
              english: 'Draft saved in app storage',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Draft save fail ayyindi',
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
