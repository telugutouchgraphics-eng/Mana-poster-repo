part of 'image_editor_screen.dart';

extension _EditorCropState on _ImageEditorScreenState {
  Future<void> _handleCropPhotoTap() async {
    final strings = context.strings;
    final selectPhotoMessage = strings.localized(
      telugu: 'క్రాప్ కోసం ఒక ఫోటో లేయర్ ఎంచుకోండి',
      english: 'Select a photo layer for crop',
    );

    final selectedId = _selectedLayerId;
    if (selectedId == null ||
        !_hasSelectedPhotoLayer ||
        _isSelectedLayerLocked ||
        _isCropApplying) {
      ScaffoldMessenger.of(
        context,
      ).showTopSnackBar(AppSnackBar.build(content: Text(selectPhotoMessage)));
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

    await _openNativeCropperForLayer(
      beforeLayer: beforeLayer,
      layerIndex: layerIndex,
      sourceBytes: sourceBytes,
    );
  }

  Future<void> _openNativeCropperForLayer({
    required _CanvasLayer beforeLayer,
    required int layerIndex,
    required Uint8List sourceBytes,
  }) async {
    final strings = context.strings;
    final cropTitle = strings.localized(
      telugu: 'ఫోటో క్రాప్ చేయండి',
      english: 'Crop Photo',
    );
    final cropFailedPrefix = strings.localized(
      telugu: 'క్రాప్ కాలేదు',
      english: 'Crop failed',
    );

    File? cropSourceTempFile;
    try {
      setState(() {
        _isCropApplying = true;
        _isCropMode = false;
        _cropSessionLayerId = null;
        _cropSessionImageBytes = null;
        _cropSessionAspectRatio = null;
        _cropSessionInitialAspectRatio = null;
        _cropTransformationController.value = Matrix4.identity();
      });

      final tempDir = await getTemporaryDirectory();
      cropSourceTempFile = File(
        '${tempDir.path}${Platform.pathSeparator}editor_crop_${beforeLayer.id}_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await cropSourceTempFile.writeAsBytes(sourceBytes, flush: true);

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: cropSourceTempFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFF7C6DFF),
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

      if (!mounted) {
        return;
      }
      if (croppedFile == null) {
        setState(() => _isCropApplying = false);
        return;
      }

      final croppedBytes = await File(croppedFile.path).readAsBytes();
      if (!mounted || croppedBytes.isEmpty) {
        return;
      }

      final latestIndex = _layers.indexWhere((item) => item.id == beforeLayer.id);
      if (latestIndex == -1) {
        return;
      }
      final latestBeforeLayer = _layers[latestIndex];
      final afterLayer = latestBeforeLayer.copyWith(
        bytes: Uint8List.fromList(croppedBytes),
        photoAspectRatio: _extractImageAspectRatio(croppedBytes),
      );
      _pushLayerHistoryEntry(
        beforeLayer: latestBeforeLayer,
        afterLayer: afterLayer,
      );
      _transformationController.value = Matrix4.copy(afterLayer.transform);

      setState(() {
        _layers[latestIndex] = afterLayer;
        _selectedLayerId = afterLayer.id;
        _isCropApplying = false;
        _activeMainToolLabel = 'Photo';
        _activeBottomPrimaryTool = _BottomPrimaryTool.photo;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCropApplying = false);
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(content: Text('$cropFailedPrefix: $error')),
      );
    } finally {
      final File? toRemove = cropSourceTempFile;
      if (toRemove != null) {
        unawaited(() async {
          try {
            if (await toRemove.exists()) {
              await toRemove.delete();
            }
          } catch (_) {}
        }());
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
    if (_isCropApplying) {
      return;
    }
    setState(() {
      _cropSessionAspectRatio = _cropSessionInitialAspectRatio;
      _cropTransformationController.value = Matrix4.identity();
    });
  }

  void _setCropAspectRatio(double? ratio) {
    if (_isCropApplying) {
      return;
    }
    setState(() {
      _cropSessionAspectRatio = ratio ?? _cropSessionInitialAspectRatio;
      _cropTransformationController.value = Matrix4.identity();
    });
  }

  Future<void> _applyCropSession() async {
    final strings = context.strings;
    final cropFailedPrefix = strings.localized(
      telugu: 'క్రాప్ కాలేదు',
      english: 'Crop failed',
    );
    final selectedId = _cropSessionLayerId;
    final sourceBytes = _cropSessionImageBytes;
    if (!_isCropMode ||
        selectedId == null ||
        sourceBytes == null ||
        sourceBytes.isEmpty ||
        _isCropApplying) {
      return;
    }

    final layerIndex = _layers.indexWhere((item) => item.id == selectedId);
    if (layerIndex == -1) {
      _discardCropSession();
      return;
    }
    final beforeLayer = _layers[layerIndex];

    try {
      setState(() {
        _isCropApplying = true;
      });
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _cropBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || boundary.size.isEmpty) {
        throw StateError('Crop frame is not ready');
      }

      final decoded = img.decodeImage(sourceBytes);
      final widthRatio = decoded == null || boundary.size.width <= 0
          ? 1.0
          : decoded.width / boundary.size.width;
      final heightRatio = decoded == null || boundary.size.height <= 0
          ? 1.0
          : decoded.height / boundary.size.height;
      final pixelRatio = math.max(widthRatio, heightRatio).clamp(1.0, 4.0);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final croppedBytes = byteData?.buffer.asUint8List();
      if (!mounted || croppedBytes == null || croppedBytes.isEmpty) {
        return;
      }

      final afterLayer = beforeLayer.copyWith(
        bytes: Uint8List.fromList(croppedBytes),
        photoAspectRatio: _extractImageAspectRatio(croppedBytes),
      );
      _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);

      setState(() {
        _layers[layerIndex] = afterLayer;
        _selectedLayerId = afterLayer.id;
        _isCropApplying = false;
        _isCropMode = false;
        _cropSessionLayerId = null;
        _cropSessionImageBytes = null;
        _cropSessionAspectRatio = null;
        _cropSessionInitialAspectRatio = null;
        _cropTransformationController.value = Matrix4.identity();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCropApplying = false;
      });
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(content: Text('$cropFailedPrefix: $error')),
      );
    }
  }
}
