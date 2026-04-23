part of 'image_editor_screen.dart';

extension _EditorAdjustState on _ImageEditorScreenState {
  void _openAdjustPanel() {
    final layer = _selectedLayer;
    if (layer == null || !layer.isPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      _isAdjustMode = true;
      _adjustSessionLayerId = layer.id;
      _adjustSessionBrightness = layer.photoBrightness;
      _adjustSessionContrast = layer.photoContrast;
      _adjustSessionSaturation = layer.photoSaturation;
      _adjustSessionBlur = layer.photoBlur;
      _adjustInitialBrightness = layer.photoBrightness;
      _adjustInitialContrast = layer.photoContrast;
      _adjustInitialSaturation = layer.photoSaturation;
      _adjustInitialBlur = layer.photoBlur;
      _showTextControls = false;
    });
    _adjustSessionNotifier.value = _AdjustSessionState(
      brightness: layer.photoBrightness,
      contrast: layer.photoContrast,
      saturation: layer.photoSaturation,
      blur: layer.photoBlur,
    );
  }

  void _discardAdjustSession() {
    if (!_isAdjustMode) {
      return;
    }
    setState(() {
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _adjustSessionBrightness = 0;
      _adjustSessionContrast = 1;
      _adjustSessionSaturation = 1;
      _adjustSessionBlur = 0;
      _adjustInitialBrightness = 0;
      _adjustInitialContrast = 1;
      _adjustInitialSaturation = 1;
      _adjustInitialBlur = 0;
    });
    _adjustSessionNotifier.value = null;
  }

  void _resetAdjustSession() {
    if (!_isAdjustMode) {
      return;
    }
    setState(() {
      _adjustSessionBrightness = _adjustInitialBrightness;
      _adjustSessionContrast = _adjustInitialContrast;
      _adjustSessionSaturation = _adjustInitialSaturation;
      _adjustSessionBlur = _adjustInitialBlur;
    });
    _adjustSessionNotifier.value = _AdjustSessionState(
      brightness: _adjustInitialBrightness,
      contrast: _adjustInitialContrast,
      saturation: _adjustInitialSaturation,
      blur: _adjustInitialBlur,
    );
  }

  void _updateAdjustSessionState(_AdjustSessionState nextState) {
    if (!_isAdjustMode || _adjustSessionLayerId == null) {
      return;
    }
    _adjustSessionBrightness = nextState.brightness;
    _adjustSessionContrast = nextState.contrast;
    _adjustSessionSaturation = nextState.saturation;
    _adjustSessionBlur = nextState.blur;
    if (_adjustSessionNotifier.value != nextState) {
      _adjustSessionNotifier.value = nextState;
    }
    _refreshSelectedPhotoRenderState();
  }

  void _applyAdjustSession() {
    final selectedId = _selectedLayerId;
    if (!_isAdjustMode ||
        selectedId == null ||
        _adjustSessionLayerId != selectedId) {
      _discardAdjustSession();
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1 || !_layers[index].isPhoto) {
      _discardAdjustSession();
      return;
    }
    final beforeLayer = _layers[index];
    final hasChanges =
        (beforeLayer.photoBrightness - _adjustSessionBrightness).abs() >
            0.0001 ||
        (beforeLayer.photoContrast - _adjustSessionContrast).abs() > 0.0001 ||
        (beforeLayer.photoSaturation - _adjustSessionSaturation).abs() >
            0.0001 ||
        (beforeLayer.photoBlur - _adjustSessionBlur).abs() > 0.0001;
    final afterLayer = beforeLayer.copyWith(
      photoBrightness: _adjustSessionBrightness,
      photoContrast: _adjustSessionContrast,
      photoSaturation: _adjustSessionSaturation,
      photoBlur: _adjustSessionBlur,
    );
    if (hasChanges) {
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    }
    setState(() {
      _layers[index] = afterLayer;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
    });
    _adjustSessionNotifier.value = null;
  }
}
