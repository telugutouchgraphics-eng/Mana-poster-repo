part of 'image_editor_screen.dart';

extension _EditorCropState on _ImageEditorScreenState {
  Future<void> _handleCropPhotoTap() async {
    final strings = context.strings;
    final selectPhotoMessage = strings.localized(
      telugu: 'క్రాప్ కోసం ఒక ఫోటో లేయర్ ఎంచుకోండి',
      english: 'Select a photo layer for crop',
    );
    final cropTitle = strings.localized(
      telugu: 'ఫోటో క్రాప్ చేయండి',
      english: 'Crop Photo',
    );
    final cropFailedPrefix = strings.localized(
      telugu: 'క్రాప్ కాలేదు',
      english: 'Crop failed',
    );

    final selectedId = _selectedLayerId;
    if (selectedId == null || !_hasSelectedPhotoLayer || _isCropApplying) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(selectPhotoMessage)));
      return;
    }

    final layerIndex = _layers.indexWhere((item) => item.id == selectedId);
    if (layerIndex == -1) {
      return;
    }

    final beforeLayer = _layers[layerIndex];
    final sourceBytes = beforeLayer.bytes;
    if (sourceBytes == null || sourceBytes.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isCropApplying = true;
      });

      final tempDir = await getTemporaryDirectory();
      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}editor_crop_${beforeLayer.id}.png',
      );
      await sourceFile.writeAsBytes(sourceBytes, flush: true);

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourceFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            toolbarColor: const Color(0xFF000000),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF000000),
            activeControlsWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white54,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            aspectRatioPresets: <CropAspectRatioPreset>[
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: cropTitle,
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (!mounted || croppedFile == null) {
        return;
      }

      final croppedBytes = await File(croppedFile.path).readAsBytes();
      if (!mounted || croppedBytes.isEmpty) {
        return;
      }

      final afterLayer = beforeLayer.copyWith(
        bytes: Uint8List.fromList(croppedBytes),
        photoAspectRatio: _extractImageAspectRatio(croppedBytes),
      );
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);

      setState(() {
        _layers[layerIndex] = afterLayer;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$cropFailedPrefix: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isCropApplying = false;
          _isCropMode = false;
          _cropSessionLayerId = null;
          _cropSessionImageBytes = null;
          _cropSessionAspectRatio = null;
          _cropSessionInitialAspectRatio = null;
          _cropTransformationController.value = Matrix4.identity();
        });
      } else {
        _cropTransformationController.value = Matrix4.identity();
      }
    }
  }

  void _discardCropSession() {
    if (_isCropApplying) {
      return;
    }
    setState(() {
      _isCropMode = false;
      _cropSessionLayerId = null;
      _cropSessionImageBytes = null;
      _cropSessionAspectRatio = null;
      _cropSessionInitialAspectRatio = null;
      _cropTransformationController.value = Matrix4.identity();
    });
  }

  void _resetCropSession() {
    _discardCropSession();
  }

  void _setCropAspectRatio(double? ratio) {}

  Future<void> _applyCropSession() async {}
}
