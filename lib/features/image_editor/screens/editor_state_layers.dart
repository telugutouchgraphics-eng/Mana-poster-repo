part of 'image_editor_screen.dart';

extension _EditorLayersState on _ImageEditorScreenState {
  void _handleLayerSelected(String id) {
    if (_isCropMode) {
      return;
    }
    _commitSelectedTextContentEdit();
    if (_selectedLayerId != id) {
      _lastSelectedTextTapAt = null;
      _lastSelectedTextTapLayerId = null;
    }
    if (_selectedLayerId == id) {
      if (_hasSelectedTextLayer) {
        _syncSelectedTextEditor();
      }
      return;
    }

    final index = _layers.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    final layer = _layers[index];
    if (layer.isHidden) {
      return;
    }
    final selectedTransform = Matrix4.copy(layer.transform);
    if (!_isMatrixFinite(selectedTransform)) {
      selectedTransform.setIdentity();
    }
    _transformationController.value = selectedTransform;
    setState(() {
      _selectedLayerId = id;
      _showTextControls = layer.isText;
      if (layer.isText) {
        _activeBottomPrimaryTool = _BottomPrimaryTool.text;
        _activeMainToolLabel = 'Text';
      } else if (layer.isPhoto) {
        _activeBottomPrimaryTool = _BottomPrimaryTool.photo;
        _activeMainToolLabel = 'Photo';
      }
      if (_adjustSessionLayerId != id) {
        _isAdjustMode = false;
        _adjustSessionLayerId = null;
      }
    });
    _syncSelectedTextEditor();
  }

  void _handleCanvasTapDown(
    Offset localPosition,
    Rect pageRect,
    Size pageSize,
  ) {
    if (_isCropMode) {
      return;
    }
    if (_suppressCanvasTapDown) {
      _suppressCanvasTapDown = false;
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
    if (_canvasTapResolvedLayer) {
      _canvasTapResolvedLayer = false;
      return;
    }
    _clearSelection();
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
      if (layer.isHidden) {
        continue;
      }
      final layerSize = _layerVisualSize(layer, pageSize);
      if (layerSize.width <= 0 || layerSize.height <= 0) {
        continue;
      }
      final paddedSize = layer.isText
          ? Size(layerSize.width + 56, layerSize.height + 36)
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
        final handleCenter = layer.isText
            ? Offset((layerSize.width / 2) + 18, (layerSize.height / 2) + 16)
            : Offset((layerSize.width / 2) + 14, (layerSize.height / 2) + 14);
        final handleHit = (localToLayer - handleCenter).distance <= 24;
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
        textAlign: layer.textAlign,
        textDirection: TextDirection.ltr,
      )..layout();
      final hasBackground = layer.textBackgroundOpacity > 0.001;
      return hasBackground
          ? Size(painter.size.width + 24, painter.size.height + 16)
          : painter.size;
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

  void _clearSelection() {
    _commitSelectedTextContentEdit();
    _cancelSelectedTextLongPress();
    _lastSelectedTextTapAt = null;
    _lastSelectedTextTapLayerId = null;
    if (_selectedLayerId == null &&
        !_isAdjustMode &&
        _activeBottomPrimaryTool == _BottomPrimaryTool.none &&
        !_snapGuides.isVisible) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    _snapGuideNotifier.value = const _SnapGuideState.none();
    setState(() {
      _selectedLayerId = null;
      _showTextControls = false;
      _isAdjustMode = false;
      _adjustSessionLayerId = null;
      _activeBottomPrimaryTool = _BottomPrimaryTool.none;
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

  void _syncSelectedLayerTransform() {
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
      return;
    }
    final index = _layers.indexWhere((item) => item.id == selectedId);
    if (index == -1) {
      return;
    }
    final current = _layers[index].transform;
    final updated = _transformationController.value;
    if (_isSameMatrix(current, updated)) {
      return;
    }

    final beforeLayer = _layers[index];
    final afterLayer = beforeLayer.copyWith(transform: Matrix4.copy(updated));
    _pushLayerHistoryEntry(beforeLayer: beforeLayer, afterLayer: afterLayer);
    _isLayerInteracting = false;
    _snapGuideNotifier.value = const _SnapGuideState.none();
    setState(() {
      _layers[index] = afterLayer;
    });
  }

  void _handleSelectedLayerInteractionStart(ScaleStartDetails details) {
    if (_isSelectedLayerLocked) {
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
    if (_isLayerInteracting) {
      return;
    }
    _isLayerInteracting = true;
  }

  Offset _selectedTransformCenterGlobal() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return Offset.zero;
    }
    final stageRect = _currentStageLogicalRect();
    final matrix = _transformationController.value;
    final centerLocal = stageRect.center.translate(
      matrix.storage[12],
      matrix.storage[13],
    );
    return renderObject.localToGlobal(centerLocal);
  }

  void _handleSelectedStickerHandleStart(DragStartDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto || selected.isText) ||
        _isSelectedLayerLocked) {
      return;
    }
    _stopPhotoGlide(sync: false);
    _cancelSelectedTextLongPress();
    _gestureStartMatrix = Matrix4.copy(_transformationController.value);
    final center = _selectedTransformCenterGlobal();
    final vector = details.globalPosition - center;
    _stickerHandleStartAngle = math.atan2(vector.dy, vector.dx);
    _stickerHandleStartDistance = math.max(vector.distance, 1);
    _photoGestureVelocity = Offset.zero;
    if (_isLayerInteracting) {
      return;
    }
    _isLayerInteracting = true;
  }

  void _handleSelectedStickerHandleUpdate(DragUpdateDetails details) {
    final selected = _selectedLayer;
    if (selected == null ||
        !(selected.isSticker || selected.isPhoto || selected.isText) ||
        _isSelectedLayerLocked) {
      return;
    }
    final base = Matrix4.copy(
      _gestureStartMatrix ?? _transformationController.value,
    );
    final updated = Matrix4.copy(base);
    final center = _selectedTransformCenterGlobal();
    final vector = details.globalPosition - center;
    final angle = math.atan2(vector.dy, vector.dx);
    final distance = math.max(vector.distance, 1);
    final angleDelta = _shortestAngleDelta(
      from: _stickerHandleStartAngle,
      to: angle,
    );
    final scaleRatio = (distance / _stickerHandleStartDistance)
        .clamp(0.25, 8.0)
        .toDouble();
    if (angleDelta.abs() > 0.0001) {
      updated.rotateZ(angleDelta);
    }
    if ((scaleRatio - 1).abs() > 0.0001) {
      updated.scaleByDouble(scaleRatio, scaleRatio, 1, 1);
    }
    if (!_isMatrixFinite(updated)) {
      return;
    }
    _transformationController.value = updated;
    _updateSmartGuides(updated);
  }

  void _handleSelectedStickerHandleEnd() {
    _handleSelectedLayerInteractionEnd();
  }

  void _handleSelectedLayerScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedLayerId == null || _isSelectedLayerLocked) {
      return;
    }
    final selectedLayer = _selectedLayer;
    if (selectedLayer == null) {
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
        _transformationController.value = incremental;
        _updateSmartGuides(incremental);
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
      _transformationController.value = incremental;
      _updateSmartGuides(incremental);
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
      const dragSensitivity = 0.68;
      incremental.setTranslationRaw(
        incremental.storage[12] + (moveDelta.dx * dragSensitivity),
        incremental.storage[13] + (moveDelta.dy * dragSensitivity),
        incremental.storage[14],
      );
      if (!_isMatrixFinite(incremental)) {
        return;
      }
      _transformationController.value = incremental;
      _updateSmartGuides(incremental);
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

    _transformationController.value = updated;
    _updateSmartGuides(updated);
  }

  void _handleSelectedLayerInteractionEnd() {
    if (_isSelectedLayerLocked) {
      return;
    }
    final selectedLayer = _selectedLayer;
    if ((selectedLayer?.isPhoto ?? false) ||
        (selectedLayer?.isSticker ?? false)) {
      final speed = _photoGestureVelocity.distance;
      if (speed > 220) {
        final clampedSpeed = speed.clamp(0, 1800).toDouble();
        final direction = _photoGestureVelocity / speed;
        final travel = clampedSpeed * 0.09;
        _photoGlideTotalTravel = Offset(
          direction.dx * travel,
          direction.dy * travel,
        );
        _photoGlideAppliedTravel = Offset.zero;
        _photoGlideController
          ..stop()
          ..reset()
          ..forward();
      } else {
        _syncSelectedLayerTransform();
      }
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
    _transformationController.value = incremental;
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

  Future<void> _handleRemoveBackgroundTap() async {
    if (_isRemovingBackground || _isCommitWorkerBusy) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
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
    if (!_hasSelectedPhotoLayer) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Remove BG కోసం సోర్స్ ఫోటో అందుబాటులో లేదు',
              english: 'Source photo unavailable for Remove BG',
            ),
          ),
        ),
      );
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
          telugu: 'ఎంచుకున్న ఫోటో లేయర్‌ను AI ప్రాసెస్ చేస్తోంది',
          english: 'AI is processing the selected photo layer',
        ),
        onStart: () {
          _isRemovingBackground = true;
        },
        onFinish: () {
          _isRemovingBackground = false;
        },
        operation: () async {
          await _backgroundRemoverInitialization;
          return _backgroundRemovalService.removeBackground(sourceBytes);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Remove BG కాలేదు: ${error.toString()}',
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
    final current = _layers[index];
    final duplicatedTransform = Matrix4.copy(current.transform);
    duplicatedTransform.storage[12] += 12;
    duplicatedTransform.storage[13] += 12;
    final duplicated = current.copyWith(
      id: 'layer_${_layerSeed++}',
      transform: duplicatedTransform,
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

  void _moveSelectedLayerToFront() {
    final index = _selectedLayerIndex;
    if (index == -1 || index == _layers.length - 1) {
      return;
    }
    final selectedId = _selectedLayerId;
    if (selectedId == null) {
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
    if (selectedId == null) {
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
    await _handleAddPhotoFromSource(ImageSource.gallery);
  }

  Future<void> _handleAddPhotoFromCamera() async {
    await _handleAddPhotoFromSource(ImageSource.camera);
  }

  Future<void> _handleAddPhotoFromSource(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    if (!mounted || pickedFile == null) {
      return;
    }

    final rawBytes = await pickedFile.readAsBytes();
    final optimizedPhoto = await compute(_optimizeEditorPhotoPayload, rawBytes);
    final bytes = optimizedPhoto.bytes;
    if (!mounted) {
      return;
    }

    final layer = _CanvasLayer(
      id: 'layer_${_layerSeed++}',
      type: _CanvasLayerType.photo,
      bytes: bytes,
      originalPhotoBytes: bytes,
      photoAspectRatio: optimizedPhoto.aspectRatio,
      transform: Matrix4.identity(),
    );

    _pushUndoSnapshot();
    _transformationController.value = Matrix4.identity();
    setState(() {
      if (_pageAspectRatio == null && optimizedPhoto.aspectRatio != null) {
        _pageAspectRatio = optimizedPhoto.aspectRatio;
        _pageAspectRatioAutoFromImage = widget.pageConfig == null;
      }
      _layers.add(layer);
      _selectedLayerId = layer.id;
    });
  }
}
