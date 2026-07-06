part of 'image_editor_screen.dart';

// ignore_for_file: unused_element

extension _EditorTextState on _ImageEditorScreenState {
  bool _shouldPlaceTextAtCanvasTap({
    required Offset localPosition,
    required Rect pageRect,
  }) {
    if (!pageRect.contains(localPosition) || _isCropMode || _isMagicWandMode) {
      return false;
    }
    if (_isTextPlacementMode) {
      return true;
    }
    final selected = _selectedLayer;
    return selected != null && selected.isText && (selected.text ?? '').isEmpty;
  }

  Future<void> _handleCanvasTextPlacementTap({
    required Offset localPosition,
    required Rect pageRect,
    required Size pageSize,
  }) async {
    final pageOffset = _pageOffsetForCanvasTextPlacement(
      localPosition: localPosition,
      pageRect: pageRect,
      pageSize: pageSize,
    );
    if (!_isTextPlacementMode && _hasSelectedTextLayer) {
      _moveSelectedTextLayerToPageOffset(pageOffset);
      return;
    }
    final layer = _insertDefaultTextLayer(pageOffset: pageOffset);
    _syncSelectedTextEditor(requestFocus: true);
    _startInlineTextEditing(selectAll: true);
    unawaited(
      _hydrateInsertedTextLayerDefaults(
        layerId: layer.id,
        language: context.currentLanguage,
      ),
    );
  }

  Offset _pageOffsetForCanvasTextPlacement({
    required Offset localPosition,
    required Rect pageRect,
    required Size pageSize,
  }) {
    final clampedPoint = Offset(
      (localPosition.dx - pageRect.left).clamp(0.0, pageSize.width).toDouble(),
      (localPosition.dy - pageRect.top).clamp(0.0, pageSize.height).toDouble(),
    );
    return Offset(
      clampedPoint.dx - (pageSize.width / 2),
      clampedPoint.dy - (pageSize.height / 2),
    );
  }

  void _moveSelectedTextLayerToPageOffset(Offset pageOffset) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final beforeLayer = _layers[index];
    final nextTransform = Matrix4.copy(beforeLayer.transform);
    nextTransform.setTranslationRaw(
      pageOffset.dx,
      pageOffset.dy,
      nextTransform.storage[14],
    );
    final clampedTransform = _clampLayerTransformToPageBounds(
      beforeLayer,
      nextTransform,
    );
    final afterLayer = beforeLayer.copyWith(transform: clampedTransform);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
    _transformationController.value = Matrix4.copy(clampedTransform);
  }

  void _handleSelectedTextFocusChange() {
    if (_selectedTextFocusNode.hasFocus) {
      _beginSelectedTextContentEdit();
      if (mounted) {
        setState(() {
          _isInlineTextEditing = true;
          _showTextControls = false;
        });
      }
      return;
    }
    _commitSelectedTextContentEdit();
    if (mounted && _isInlineTextEditing) {
      setState(() {
        _isInlineTextEditing = false;
        _showSelectedLayerHandles = false;
      });
    }
  }

  Future<void> _handleAddText() async {
    if (_isCreatingTextLayer) {
      return;
    }
    _isCreatingTextLayer = true;

    try {
      _commitSelectedTextContentEdit();
      if (_selectedTextFocusNode.hasFocus) {
        _selectedTextFocusNode.unfocus();
      }
      setState(() {
        _isTextPlacementMode = true;
        _isInlineTextEditing = false;
        _selectedLayerId = null;
        _showTextControls = false;
        _activeBottomPrimaryTool = _BottomPrimaryTool.text;
        _activeMainToolLabel = 'Text';
      });
    } finally {
      _isCreatingTextLayer = false;
    }
  }

  Future<void> _hydrateInsertedTextLayerDefaults({
    required String layerId,
    required AppLanguage language,
  }) async {
    try {
      final posterProfile = await PosterProfileService.loadLocal().timeout(
        const Duration(milliseconds: 400),
      );
      if (!mounted) {
        return;
      }
      final index = _layers.indexWhere((item) => item.id == layerId);
      if (index == -1 || !_layers[index].isText) {
        return;
      }

      final currentLayer = _layers[index];
      final resolvedName = posterProfile
          .resolvedName(language: language)
          .trim();
      final bool shouldUpdateText =
          resolvedName.isNotEmpty &&
          !(_selectedLayerId == layerId && _isInlineTextEditing) &&
          (currentLayer.text ?? '').trim() ==
              _selectedTextController.text.trim();
      final bool shouldUpdateFont =
          shouldUpdateText &&
          _textFontFamilies.contains(posterProfile.nameFontFamily) &&
          currentLayer.fontFamily != posterProfile.nameFontFamily;
      if (!shouldUpdateText && !shouldUpdateFont) {
        return;
      }

      setState(() {
        _layers[index] = currentLayer.copyWith(
          text: shouldUpdateText ? resolvedName : currentLayer.text,
          legacyRenderText: null,
          fontFamily: shouldUpdateFont
              ? posterProfile.nameFontFamily
              : currentLayer.fontFamily,
        );
      });
      unawaited(_refreshLayerLegacyRenderText(layerId));

      if (_selectedLayerId == layerId) {
        _syncSelectedTextEditor(requestFocus: _selectedTextFocusNode.hasFocus);
      }
    } catch (_) {
      // Keep the inserted default text when profile lookup is unavailable.
    }
  }

  _CanvasLayer _insertDefaultTextLayer({Offset? pageOffset}) {
    final resolvedOffset = pageOffset ?? Offset.zero;
    final rawLayer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.text,
      text: '',
      isParagraphText: false,
      textColor: Colors.black,
      textAlign: TextAlign.left,
      textStrokeColor: Colors.black,
      textStrokeWidth: 0,
      fontFamily: 'Pallavi Bold',
      transform: Matrix4.identity()
        ..translateByDouble(resolvedOffset.dx, resolvedOffset.dy, 0, 1),
    );
    final layer = rawLayer.copyWith(
      transform: _clampLayerTransformToPageBounds(rawLayer, rawLayer.transform),
    );
    _pushLayerInsertHistoryEntry(
      layer: layer,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: layer.id,
    );
    _transformationController.value = Matrix4.copy(layer.transform);
    if (!mounted) {
      return layer;
    }
    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
      _isTextPlacementMode = false;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _showTextControls = false;
    });
    return layer;
  }

  void _handleAddSticker(String sticker) {
    final isImageSticker = _isImageLikeSticker(sticker);
    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.sticker,
      sticker: sticker,
      stickerColor: const Color(0xFF111827),
      fontSize: isImageSticker ? 112 : 72,
      blendMode: BlendMode.srcOver,
      transform: Matrix4.identity(),
    );
    _pushLayerInsertHistoryEntry(
      layer: layer,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: layer.id,
    );
    _transformationController.value = Matrix4.identity();
    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
      _showTextControls = false;
    });
  }

  static bool _isImageLikeSticker(String? value) {
    return _resolveStickerAssetPath(value) != null ||
        _resolveStickerFilePath(value) != null;
  }

  static String? _resolveStickerAssetPath(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return null;
    }
    final lower = normalized.toLowerCase();
    final isImage =
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg');
    if (!isImage) {
      return null;
    }
    if (normalized.startsWith('assets/')) {
      return normalized;
    }
    if (normalized.startsWith('elements/')) {
      return 'assets/$normalized';
    }
    return null;
  }

  static String? _resolveStickerFilePath(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return null;
    }
    final lower = normalized.toLowerCase();
    final isImage =
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
    if (!isImage) {
      return null;
    }
    final isAbsoluteWindows = RegExp(r'^[a-zA-Z]:/').hasMatch(normalized);
    final isAbsoluteUnix = normalized.startsWith('/');
    if (!isAbsoluteWindows && !isAbsoluteUnix) {
      return null;
    }
    return normalized;
  }

  static Widget _buildStickerVisual(
    String? sticker, {
    required double fontSize,
    required BoxFit fit,
    required FilterQuality filterQuality,
    Color? color,
  }) {
    final assetPath = _resolveStickerAssetPath(sticker);
    if (assetPath != null) {
      if (assetPath.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          assetPath,
          fit: fit,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color, BlendMode.srcIn),
        );
      }
      return Image.asset(
        assetPath,
        fit: fit,
        filterQuality: filterQuality,
        color: color,
        colorBlendMode: color == null ? null : BlendMode.srcIn,
        errorBuilder: (_, error, stackTrace) => Text(
          sticker ?? '*',
          style: TextStyle(fontSize: fontSize, color: color),
        ),
      );
    }
    final filePath = _resolveStickerFilePath(sticker);
    if (filePath != null) {
      return Image.file(
        File(filePath),
        fit: fit,
        filterQuality: filterQuality,
        color: color,
        colorBlendMode: color == null ? null : BlendMode.srcIn,
        errorBuilder: (_, error, stackTrace) => Text(
          sticker ?? '*',
          style: TextStyle(fontSize: fontSize, color: color),
        ),
      );
    }
    return Text(
      sticker ?? '*',
      style: TextStyle(fontSize: fontSize, height: 1.15, color: color),
    );
  }

  void _syncSelectedTextEditor({bool requestFocus = false}) {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      if (_selectedTextController.text.isNotEmpty &&
          !_selectedTextFocusNode.hasFocus) {
        _isSyncingSelectedTextField = true;
        _selectedTextController.clear();
        _isSyncingSelectedTextField = false;
      }
      return;
    }
    if (_textContentEditingLayerId != null &&
        _textContentEditingLayerId != layer.id &&
        _selectedTextFocusNode.hasFocus) {
      _commitSelectedTextContentEdit();
    }
    final nextText = layer.text ?? '';
    if (_selectedTextController.text != nextText ||
        _textContentEditingLayerId != layer.id) {
      _isSyncingSelectedTextField = true;
      _selectedTextController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
      _isSyncingSelectedTextField = false;
      _textContentEditingLayerId = layer.id;
    }
    if (requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hasSelectedTextLayer) {
          _selectedTextFocusNode.requestFocus();
        }
      });
    }
  }

  void _beginSelectedTextContentEdit() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      return;
    }
    if (_textContentEditBeforeLayer?.id == layer.id) {
      return;
    }
    _textContentEditBeforeLayer = _cloneLayer(layer);
    _textContentEditingLayerId = layer.id;
  }

  bool _didLayerChange(_CanvasLayer beforeLayer, _CanvasLayer afterLayer) {
    final beforeMap = _serializeLayer(beforeLayer);
    final afterMap = _serializeLayer(afterLayer);
    beforeMap.remove('id');
    afterMap.remove('id');
    beforeMap.remove('transform');
    afterMap.remove('transform');
    return beforeMap.toString() != afterMap.toString() ||
        !_isSameMatrix(beforeLayer.transform, afterLayer.transform);
  }

  void _commitSelectedTextContentEdit() {
    final beforeLayer = _textContentEditBeforeLayer;
    var selectedLayer = _selectedLayer;
    if (selectedLayer != null && selectedLayer.isText) {
      final index = _layers.indexWhere((item) => item.id == selectedLayer!.id);
      if (index != -1 && _layers[index].isText) {
        final committedLegacyRenderText = _legacyRenderTextForTextEdit(
          text: _layers[index].text ?? '',
          fontFamily: _layers[index].fontFamily,
        );
        if (_layers[index].legacyRenderText != committedLegacyRenderText) {
          final committedLayer = _layers[index].copyWith(
            legacyRenderText: committedLegacyRenderText,
          );
          _layers[index] = committedLayer;
          selectedLayer = committedLayer;
        }
      }
    }
    if (beforeLayer != null &&
        selectedLayer != null &&
        selectedLayer.isText &&
        beforeLayer.id == selectedLayer.id &&
        _didLayerChange(beforeLayer, selectedLayer)) {
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: _cloneLayer(selectedLayer),
      );
    }
    _textContentEditBeforeLayer = null;
    if (!_selectedTextFocusNode.hasFocus) {
      _textContentEditingLayerId = selectedLayer?.isText == true
          ? selectedLayer!.id
          : null;
    }
  }

  void _handleSelectedTextChanged(String value) {
    if (_isSyncingSelectedTextField) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    if (_textContentEditBeforeLayer == null ||
        _textContentEditBeforeLayer!.id != selectedId) {
      _beginSelectedTextContentEdit();
    }
    final beforeLayer = _layers[index];
    final nextLegacyRenderText = _legacyRenderTextForTextEdit(
      text: value,
      fontFamily: beforeLayer.fontFamily,
    );
    if ((beforeLayer.text ?? '') == value &&
        beforeLayer.legacyRenderText == nextLegacyRenderText) {
      return;
    }
    final nextLayer = beforeLayer.copyWith(
      text: value,
      legacyRenderText: nextLegacyRenderText,
    );
    setState(() {
      _layers[index] = nextLayer;
      if (_selectedLayerId == nextLayer.id) {
        _transformationController.value = Matrix4.copy(nextLayer.transform);
      }
    });
  }

  String? _legacyRenderTextForTextEdit({
    required String text,
    required String fontFamily,
  }) {
    if (!_isLegacyTeluguFontFamily(fontFamily)) {
      return null;
    }
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (normalized.trim().isEmpty) {
      return null;
    }
    if (_looksLikeLegacyPsdText(normalized)) {
      return normalized.trim();
    }
    return TeluguLegacyTextService.convertSync(
      normalized,
      fontFamily: fontFamily,
    );
  }

  void _beginSelectedTextStyleEdit(double _) {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) {
      return;
    }
    if (_textStyleEditBeforeLayer?.id != layer.id) {
      _textStyleEditBeforeLayer = _cloneLayer(layer);
    }
  }

  void _endSelectedTextStyleEdit(double _) {
    final beforeLayer = _textStyleEditBeforeLayer;
    final selectedLayer = _selectedLayer;
    if (beforeLayer != null &&
        selectedLayer != null &&
        selectedLayer.isText &&
        beforeLayer.id == selectedLayer.id &&
        _didLayerChange(beforeLayer, selectedLayer)) {
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: _cloneLayer(selectedLayer),
      );
    }
    _textStyleEditBeforeLayer = null;
  }

  void _handleTextAddQuickTap() {
    unawaited(_handleAddText());
  }

  void _handleMainTextToolTap() {
    _openBottomPrimaryTool(_BottomPrimaryTool.text, 'Text');
  }

  Future<void> _handleTextStyleQuickTap() async {
    if (!_hasSelectedTextLayer) {
      await _handleAddText();
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _activeBottomPrimaryTool = _BottomPrimaryTool.text;
      _activeMainToolLabel = 'Text';
      _activeTextToolTab = _TextToolTab.style;
      _showTextControls = true;
    });
  }

  Future<void> _openSelectedTextToolTab(_TextToolTab tab) async {
    if (!_hasSelectedTextLayer) {
      await _handleAddText();
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _activeBottomPrimaryTool = _BottomPrimaryTool.text;
      _activeMainToolLabel = 'Text';
      _activeTextToolTab = tab;
      _showTextControls = true;
    });
  }

  void _handleTextSizeQuickTap() {
    unawaited(_openSelectedTextToolTab(_TextToolTab.size));
  }

  void _handleTextAlignmentQuickTap() {
    unawaited(_openSelectedTextToolTab(_TextToolTab.alignment));
  }

  void _handleTextBackgroundQuickTap() {
    unawaited(_openSelectedTextToolTab(_TextToolTab.background));
  }

  void _handleTextEffectsQuickTap() {
    unawaited(_openUniversalLayerStyleSheet());
  }

  Future<void> _handleTextEditQuickTap({bool selectAll = false}) async {
    if (!_hasSelectedTextLayer) {
      await _handleAddText();
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
    }
    _startInlineTextEditing(selectAll: selectAll);
  }

  Future<void> _handleTextColorQuickTap() async {
    if (!_hasSelectedTextLayer) {
      await _handleAddText();
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
    }
    await _openTextColorPickerOverlay();
  }

  Future<void> _handleTextFontQuickTap() async {
    if (!_hasSelectedTextLayer) {
      await _handleAddText();
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
    }
    await _openFontPickerOverlay();
  }

  void _setSelectedTextColor(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final layer = _layers[index];
    if (layer.textGradientIndex == -1 &&
        layer.textColor.toARGB32() == color.toARGB32()) {
      return;
    }

    final afterLayer = layer.copyWith(textColor: color, textGradientIndex: -1);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextAlignment(TextAlign align) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    if (_layers[index].textAlign == align) {
      return;
    }

    final afterLayer = _layers[index].copyWith(textAlign: align);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextGradient(int gradientIndex) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    if (_layers[index].textGradientIndex == gradientIndex) {
      return;
    }

    final afterLayer = _layers[index].copyWith(
      textGradientIndex: gradientIndex,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextOpacity(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textOpacity: value.clamp(0, 1).toDouble(),
      );
    });
  }

  void _setSelectedTextFontSize(double fontSize) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final snappedFontSize = _snapEditorSliderValue(
      fontSize,
      min: 18,
      max: 96,
      step: 1,
    );
    setState(() {
      _layers[index] = _layers[index].copyWith(fontSize: snappedFontSize);
    });
  }

  void _handleTextFontSizeEditStart(double _) {
    final selectedLayer = _selectedLayer;
    _fontSizeEditBeforeLayer = selectedLayer == null
        ? null
        : _cloneLayer(selectedLayer);
  }

  void _handleTextFontSizeEditEnd(double _) {
    final beforeLayer = _fontSizeEditBeforeLayer;
    final selectedLayer = _selectedLayer;
    if (beforeLayer != null &&
        selectedLayer != null &&
        beforeLayer.id == selectedLayer.id &&
        (beforeLayer.fontSize - selectedLayer.fontSize).abs() > 0.0001) {
      _pushLayerHistoryEntry(
        beforeLayer: beforeLayer,
        afterLayer: _cloneLayer(selectedLayer),
      );
    }
    _fontSizeEditBeforeLayer = null;
  }

  void _setSelectedTextFontFamily(String fontFamily) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    if (_layers[index].fontFamily == fontFamily) {
      return;
    }

    final afterLayer = _layers[index].copyWith(fontFamily: fontFamily);
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextBackgroundColor(Color color) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    final beforeLayer = _layers[index];
    final nextOpacity = beforeLayer.textBackgroundOpacity <= 0.001
        ? 0.75
        : beforeLayer.textBackgroundOpacity;
    if (beforeLayer.textBackgroundColor.toARGB32() == color.toARGB32() &&
        (beforeLayer.textBackgroundOpacity - nextOpacity).abs() < 0.0001) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(
      textBackgroundColor: color,
      textBackgroundOpacity: nextOpacity,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _setSelectedTextBackgroundOpacity(double opacity) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    setState(() {
      _layers[index] = _layers[index].copyWith(
        textBackgroundOpacity: opacity.clamp(0, 1).toDouble(),
      );
    });
  }

  void _setSelectedTextBackgroundRadius(double radius) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    setState(() {
      _layers[index] = _layers[index].copyWith(
        textBackgroundRadius: radius.clamp(0, 100).toDouble(),
      );
    });
  }

  void _setSelectedTextBackgroundTopPadding(double padding) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    setState(() {
      _layers[index] = _layers[index].copyWith(
        textBackgroundTopPadding: padding.clamp(0, 100).toDouble(),
      );
    });
  }

  void _setSelectedTextBackgroundBottomPadding(double padding) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }

    setState(() {
      _layers[index] = _layers[index].copyWith(
        textBackgroundBottomPadding: padding.clamp(0, 100).toDouble(),
      );
    });
  }

  void _setSelectedTextLineHeight(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final snappedValue = _snapEditorSliderValue(
      value,
      min: 0.8,
      max: 2.2,
      step: 0.1,
    );
    setState(() {
      _layers[index] = _layers[index].copyWith(textLineHeight: snappedValue);
    });
  }

  void _setSelectedTextLetterSpacing(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final snappedValue = _snapEditorSliderValue(
      value,
      min: -100,
      max: 100,
      step: 1,
    );
    setState(() {
      _layers[index] = _layers[index].copyWith(textLetterSpacing: snappedValue);
    });
  }

  void _setSelectedTextShadowOpacity(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textShadowOpacity: value.clamp(0, 1).toDouble(),
      );
    });
  }

  void _setSelectedTextShadowBlur(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textShadowBlur: value.clamp(0, 100).toDouble(),
      );
    });
  }

  void _setSelectedTextShadowOffsetY(double value) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textShadowOffsetY: value.clamp(0, 100).toDouble(),
      );
    });
  }

  void _applySelectedTextEffectPreset(_TextEffectPreset preset) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) {
      return;
    }
    final beforeLayer = _layers[index];
    final afterLayer = switch (preset) {
      _TextEffectPreset.none => beforeLayer.copyWith(
        textOpacity: 1,
        textStrokeWidth: 0,
        textShadowOpacity: 0,
        textShadowColor: Colors.black,
        textShadowBlur: 0,
        textShadowOffsetY: 0,
      ),
      _TextEffectPreset.softShadow => beforeLayer.copyWith(
        textOpacity: 1,
        textStrokeWidth: 0,
        textShadowOpacity: 0.24,
        textShadowColor: const Color(0xFF020617),
        textShadowBlur: 18,
        textShadowOffsetY: 6,
      ),
      _TextEffectPreset.hardShadow => beforeLayer.copyWith(
        textOpacity: 1,
        textStrokeWidth: 0,
        textShadowOpacity: 0.72,
        textShadowColor: const Color(0xFF020617),
        textShadowBlur: 0.4,
        textShadowOffsetY: 6,
      ),
      _TextEffectPreset.outline => beforeLayer.copyWith(
        textOpacity: 1,
        textStrokeWidth: 2.2,
        textStrokeColor: Colors.black,
        textShadowOpacity: 0,
        textShadowColor: Colors.black,
        textShadowBlur: 0,
        textShadowOffsetY: 0,
      ),
      _TextEffectPreset.lift => beforeLayer.copyWith(
        textOpacity: 1,
        textStrokeWidth: 0,
        textShadowOpacity: 0.18,
        textShadowColor: const Color(0xFF020617),
        textShadowBlur: 28,
        textShadowOffsetY: 3,
      ),
      _TextEffectPreset.poster => beforeLayer.copyWith(
        textOpacity: 1,
        textStrokeWidth: 1.8,
        textStrokeColor: Colors.white,
        textShadowOpacity: 0.34,
        textShadowColor: const Color(0xFF111827),
        textShadowBlur: 10,
        textShadowOffsetY: 5,
      ),
    };
    if (_layersVisuallyEqual(beforeLayer, afterLayer)) {
      return;
    }
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  bool _layersVisuallyEqual(_CanvasLayer a, _CanvasLayer b) {
    return (a.textOpacity - b.textOpacity).abs() < 0.0001 &&
        (a.textStrokeWidth - b.textStrokeWidth).abs() < 0.0001 &&
        a.textStrokeColor.toARGB32() == b.textStrokeColor.toARGB32() &&
        (a.textShadowOpacity - b.textShadowOpacity).abs() < 0.0001 &&
        a.textShadowColor.toARGB32() == b.textShadowColor.toARGB32() &&
        (a.textShadowBlur - b.textShadowBlur).abs() < 0.0001 &&
        (a.textShadowOffsetY - b.textShadowOffsetY).abs() < 0.0001;
  }

  Future<void> _loadTextEffectPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawPresets =
          prefs.getStringList(_textEffectPresetsStorageKey) ?? const <String>[];
      final loadedPresets = <_TextEffectSnapshot>[];
      for (final rawPreset in rawPresets) {
        final decoded = jsonDecode(rawPreset);
        if (decoded is Map<String, Object?>) {
          loadedPresets.add(_TextEffectSnapshot.fromJson(decoded));
        } else if (decoded is Map) {
          loadedPresets.add(
            _TextEffectSnapshot.fromJson(
              decoded.map(
                (key, value) => MapEntry(key.toString(), value as Object?),
              ),
            ),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _savedTextEffectPresets
          ..clear()
          ..addAll(loadedPresets.take(16));
        _textEffectPresetSeed = _savedTextEffectPresets.length;
      });
    } catch (_) {
      // Keep the editor usable even if an older local preset payload is invalid.
    }
  }

  Future<void> _persistTextEffectPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _textEffectPresetsStorageKey,
      _savedTextEffectPresets
          .map((preset) => jsonEncode(preset.toJson()))
          .toList(growable: false),
    );
  }

  void _copySelectedTextEffect() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) return;
    setState(() {
      _copiedTextEffect = _TextEffectSnapshot.fromLayer(
        layer,
        id: 'copied-${DateTime.now().microsecondsSinceEpoch}',
        name: 'Copied Effect',
      );
    });
    HapticFeedback.selectionClick();
  }

  void _pasteCopiedTextEffect() {
    final effect = _copiedTextEffect;
    if (effect == null) return;
    _applyTextEffectSnapshot(effect);
  }

  void _saveSelectedTextEffectPreset() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isText) return;
    final nextSeed = _textEffectPresetSeed + 1;
    final preset = _TextEffectSnapshot.fromLayer(
      layer,
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Custom $nextSeed',
    );
    setState(() {
      _textEffectPresetSeed = nextSeed;
      _savedTextEffectPresets
        ..removeWhere((item) => item.visuallyEquals(preset))
        ..insert(0, preset);
      if (_savedTextEffectPresets.length > 16) {
        _savedTextEffectPresets.removeRange(16, _savedTextEffectPresets.length);
      }
    });
    HapticFeedback.mediumImpact();
    unawaited(_persistTextEffectPresets());
  }

  void _applySavedTextEffectPreset(_TextEffectSnapshot preset) {
    _applyTextEffectSnapshot(preset);
  }

  void _deleteSavedTextEffectPreset(_TextEffectSnapshot preset) {
    setState(() {
      _savedTextEffectPresets.removeWhere((item) => item.id == preset.id);
    });
    HapticFeedback.selectionClick();
    unawaited(_persistTextEffectPresets());
  }

  void _applyTextEffectSnapshot(_TextEffectSnapshot effect) {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    final afterLayer = effect.applyTo(beforeLayer);
    if (_layersVisuallyEqual(beforeLayer, afterLayer)) return;
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
    HapticFeedback.selectionClick();
  }

  void _toggleSelectedTextBold() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      isTextBold: !beforeLayer.isTextBold,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _toggleSelectedTextItalic() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      isTextItalic: !beforeLayer.isTextItalic,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }

  void _toggleSelectedTextUnderline() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) return;
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isText) return;
    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(
      isTextUnderline: !beforeLayer.isTextUnderline,
    );
    _replaceLayerWithHistory(index: index, afterLayer: afterLayer);
  }
}
