part of 'image_editor_screen.dart';

// ignore_for_file: unused_element

extension _EditorBackgroundState on _ImageEditorScreenState {
  void _cycleCanvasBackgroundColor() {
    final currentIndex = editorBackgroundColors.indexWhere(
      (color) => color.toARGB32() == _canvasBackgroundColor.toARGB32(),
    );
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + 1) % editorBackgroundColors.length;
    _setCanvasBackgroundColor(editorBackgroundColors[nextIndex]);
  }

  void _cycleCanvasBackgroundGradient() {
    final nextIndex =
        (_canvasBackgroundGradientIndex + 1) % editorBackgroundGradients.length;
    _setCanvasBackgroundGradient(nextIndex);
  }

  void _applyInitialStageBackground(EditorStageBackground? background) {
    if (background == null) {
      return;
    }
    switch (background.type) {
      case EditorStageBackgroundType.white:
        _canvasBackgroundColor = const Color(0xFFFFFFFF);
        _canvasBackgroundGradientIndex = -1;
        _stageBackgroundImageBytes = null;
        _backgroundBlurAmount = 0;
        break;
      case EditorStageBackgroundType.transparent:
        _canvasBackgroundColor = Colors.transparent;
        _canvasBackgroundGradientIndex = -1;
        _stageBackgroundImageBytes = null;
        _backgroundBlurAmount = 0;
        break;
      case EditorStageBackgroundType.color:
        _canvasBackgroundColor = background.color ?? const Color(0xFF000000);
        _canvasBackgroundGradientIndex = -1;
        _stageBackgroundImageBytes = null;
        _backgroundBlurAmount = 0;
        break;
      case EditorStageBackgroundType.gradient:
        final selectedIndex = (background.gradientIndex ?? 17).clamp(
          0,
          editorBackgroundGradients.length - 1,
        );
        _canvasBackgroundGradientIndex = selectedIndex;
        _canvasBackgroundColor = const Color(0xFFFFFFFF);
        _stageBackgroundImageBytes = null;
        _backgroundBlurAmount = 0;
        break;
    }
  }

  void _setCanvasBackgroundColor(Color color) {
    if (_canvasBackgroundGradientIndex == -1 &&
        _stageBackgroundImageBytes == null &&
        _canvasBackgroundColor.toARGB32() == color.toARGB32()) {
      return;
    }

    _pushCanvasBackgroundHistoryEntry(
      beforeColor: _canvasBackgroundColor,
      beforeGradientIndex: _canvasBackgroundGradientIndex,
      beforeImageBytes: _stageBackgroundImageBytes,
      beforeBlurAmount: _backgroundBlurAmount,
      afterColor: color,
      afterGradientIndex: -1,
      afterImageBytes: null,
      afterBlurAmount: 0,
    );
    setState(() {
      _canvasBackgroundColor = color;
      _canvasBackgroundGradientIndex = -1;
      _stageBackgroundImageBytes = null;
      _backgroundBlurAmount = 0;
    });
  }

  void _setCanvasBackgroundGradient(int gradientIndex) {
    if (_canvasBackgroundGradientIndex == gradientIndex &&
        _stageBackgroundImageBytes == null) {
      return;
    }

    _pushCanvasBackgroundHistoryEntry(
      beforeColor: _canvasBackgroundColor,
      beforeGradientIndex: _canvasBackgroundGradientIndex,
      beforeImageBytes: _stageBackgroundImageBytes,
      beforeBlurAmount: _backgroundBlurAmount,
      afterColor: _canvasBackgroundColor,
      afterGradientIndex: gradientIndex,
      afterImageBytes: null,
      afterBlurAmount: 0,
    );
    setState(() {
      _canvasBackgroundGradientIndex = gradientIndex;
      _stageBackgroundImageBytes = null;
      _backgroundBlurAmount = 0;
    });
  }

  Future<bool> _setCanvasBackgroundImage() async {
    final selected = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (selected == null) {
      return false;
    }

    final bytes = await selected.readAsBytes();
    final optimized = _optimizeEditorPhotoPayload(bytes);
    _pushCanvasBackgroundHistoryEntry(
      beforeColor: _canvasBackgroundColor,
      beforeGradientIndex: _canvasBackgroundGradientIndex,
      beforeImageBytes: _stageBackgroundImageBytes,
      beforeBlurAmount: _backgroundBlurAmount,
      afterColor: _canvasBackgroundColor,
      afterGradientIndex: -1,
      afterImageBytes: optimized.bytes,
      afterBlurAmount: _backgroundBlurAmount.clamp(0, 40).toDouble(),
    );
    setState(() {
      _stageBackgroundImageBytes = optimized.bytes;
      _canvasBackgroundGradientIndex = -1;
      if (_backgroundBlurAmount > 40) {
        _backgroundBlurAmount = 40;
      }
    });
    return true;
  }
}
