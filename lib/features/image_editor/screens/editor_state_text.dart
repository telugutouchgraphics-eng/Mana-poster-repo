part of 'image_editor_screen.dart';

// ignore_for_file: unused_element

extension _EditorTextState on _ImageEditorScreenState {
  void _handleSelectedTextFocusChange() {
    if (_selectedTextFocusNode.hasFocus) {
      _beginSelectedTextContentEdit();
      return;
    }
    _commitSelectedTextContentEdit();
  }

  Future<void> _handleAddText() async {
    if (_isCreatingTextLayer) {
      return;
    }
    _isCreatingTextLayer = true;
    final AppLanguage currentLanguage = context.currentLanguage;

    try {
      final layer = _insertDefaultTextLayer();
      unawaited(
        _hydrateInsertedTextLayerDefaults(
          layerId: layer.id,
          language: currentLanguage,
        ),
      );
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
          (currentLayer.text ?? '').trim() ==
              _selectedTextController.text.trim();
      final bool shouldUpdateFont =
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

  _CanvasLayer _insertDefaultTextLayer() {
    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.text,
      text: context.strings.localized(telugu: 'టెక్స్ట్', english: 'Text'),
      textColor: Colors.white,
      textStrokeColor: Colors.black,
      textStrokeWidth: 0,
      fontFamily: 'Anek Telugu Condensed Regular',
      transform: Matrix4.identity(),
    );
    _pushLayerInsertHistoryEntry(
      layer: layer,
      insertIndex: _layers.length,
      beforeSelectedLayerId: _selectedLayerId,
      afterSelectedLayerId: layer.id,
    );
    _transformationController.value = Matrix4.identity();
    if (!mounted) {
      return layer;
    }
    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
      _showTextControls = false;
    });
    return layer;
  }

  void _handleAddSticker(String sticker) {
    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.sticker,
      sticker: sticker,
      fontSize: _isImageLikeSticker(sticker) ? 112 : 72,
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
        lower.endsWith('.webp');
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
  }) {
    final assetPath = _resolveStickerAssetPath(sticker);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: fit,
        filterQuality: filterQuality,
        errorBuilder: (_, error, stackTrace) =>
            Text(sticker ?? '*', style: TextStyle(fontSize: fontSize)),
      );
    }
    final filePath = _resolveStickerFilePath(sticker);
    if (filePath != null) {
      return Image.file(
        File(filePath),
        fit: fit,
        filterQuality: filterQuality,
        errorBuilder: (_, error, stackTrace) =>
            Text(sticker ?? '*', style: TextStyle(fontSize: fontSize)),
      );
    }
    return Text(sticker ?? '*', style: TextStyle(fontSize: fontSize));
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
    if ((beforeLayer.text ?? '') == value) {
      return;
    }
    setState(() {
      _layers[index] = beforeLayer.copyWith(
        text: value,
        legacyRenderText: null,
      );
    });
    unawaited(
      _refreshLayerLegacyRenderText(selectedId, clearImmediately: false),
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
    unawaited(_handleTextEditQuickTap());
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
      _showTextControls = true;
    });
  }

  Future<void> _handleTextEditQuickTap() async {
    if (!_hasSelectedTextLayer) {
      await _handleAddText();
      if (!mounted || !_hasSelectedTextLayer) {
        return;
      }
    }
    await _openSelectedTextFullScreenEditor();
  }

  Future<void> _handleTextColorQuickTap() async {
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
      _showTextControls = true;
    });
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
        textOpacity: value.clamp(0.15, 1).toDouble(),
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
    setState(() {
      _layers[index] = _layers[index].copyWith(
        fontSize: fontSize.clamp(18, 96).toDouble(),
      );
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
    if (beforeLayer.textBackgroundColor.toARGB32() == color.toARGB32()) {
      return;
    }
    final afterLayer = beforeLayer.copyWith(textBackgroundColor: color);
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
        textBackgroundRadius: radius.clamp(0, 40).toDouble(),
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
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textLineHeight: value.clamp(0.8, 2.2).toDouble(),
      );
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
    setState(() {
      _layers[index] = _layers[index].copyWith(
        textLetterSpacing: value.clamp(-1, 12).toDouble(),
      );
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
        textShadowBlur: value.clamp(0, 24).toDouble(),
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
        textShadowOffsetY: value.clamp(0, 20).toDouble(),
      );
    });
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
