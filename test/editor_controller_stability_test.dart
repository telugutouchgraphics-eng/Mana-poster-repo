import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:mana_poster/features/editor/controllers/editor_controller.dart';
import 'package:mana_poster/features/editor/models/editor_stage.dart';
import 'package:mana_poster/features/editor/models/editor_tool.dart';

void main() {
  group('EditorController stability', () {
    test('mixed layer workflow stays undoable and redoable', () async {
      final controller = EditorController();
      controller.setStageSize(const Size(1080, 1920));

      await controller.addPhotoToStage('https://example.com/surface.png');
      controller.addTextLayer();
      controller.addElementToStage(controller.elementAssets.first);
      controller.addStickerToStage(controller.stickerAssets.first);
      controller.addShapeToStage(ShapeKind.rectangle);
      controller.setStageSolidBackground(const Color(0xFFF8FAFF));

      final textCountBeforeUndo = controller.textLayers.length;
      final elementCountBeforeUndo = controller.elementLayers.length;
      final stickerCountBeforeUndo = controller.stickerLayers.length;
      final shapeCountBeforeUndo = controller.shapeLayers.length;

      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(
        controller.stageBackground.solidColor,
        isNot(const Color(0xFFF8FAFF)),
      );

      controller.undo();
      expect(controller.shapeLayers.length, shapeCountBeforeUndo - 1);

      controller.undo();
      expect(controller.stickerLayers.length, stickerCountBeforeUndo - 1);

      controller.undo();
      expect(controller.elementLayers.length, elementCountBeforeUndo - 1);

      controller.undo();
      expect(controller.textLayers.length, textCountBeforeUndo - 1);

      controller.redo();
      controller.redo();
      controller.redo();
      controller.redo();
      controller.redo();

      expect(controller.textLayers.length, textCountBeforeUndo);
      expect(controller.elementLayers.length, elementCountBeforeUndo);
      expect(controller.stickerLayers.length, stickerCountBeforeUndo);
      expect(controller.shapeLayers.length, shapeCountBeforeUndo);
      expect(controller.stageBackground.solidColor, const Color(0xFFF8FAFF));
    });

    test('draft restore sanitizes invalid selections safely', () {
      final controller = EditorController();
      controller.setStageSize(const Size(1080, 1920));
      controller.addTextLayer();

      final payload = controller.buildDraftPayload();
      payload['selection'] = <String, Object?>{
        'selectedExtraPhotoLayerId': 'missing_photo',
        'selectedTextLayerId': 'missing_text',
        'selectedElementLayerId': 'missing_element',
        'selectedStickerLayerId': 'missing_sticker',
        'selectedDrawLayerId': 'missing_draw',
        'selectedShapeLayerId': 'missing_shape',
        'isMainSurfaceSelected': true,
      };

      controller.applyDraftPayload(payload);

      expect(controller.selectedExtraPhotoLayerId, isNull);
      expect(controller.selectedTextLayerId, isNull);
      expect(controller.selectedElementLayerId, isNull);
      expect(controller.selectedStickerLayerId, isNull);
      expect(controller.selectedDrawLayerId, isNull);
      expect(controller.selectedShapeLayerId, isNull);
      expect(controller.isMainSurfaceSelected, isFalse);
      expect(controller.hasSelectedEditableLayer, isFalse);
    });

    test('text move completes with bounded snap and stable history', () {
      final controller = EditorController();
      controller.setStageSize(const Size(1080, 1920));
      controller.addTextLayer();
      final layerId = controller.selectedTextLayerId!;
      final initialOffset = controller.selectedTextLayer!.offset;

      controller.beginTextLayerMove(layerId);
      controller.moveTextLayerBy(layerId, const Offset(24, 18));
      controller.completeTextLayerMove(layerId);

      expect(controller.selectedTextLayerId, layerId);
      expect(controller.selectedTextLayer!.offset, isNot(initialOffset));
      expect(controller.showVerticalGuide, isFalse);
      expect(controller.showHorizontalGuide, isFalse);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.selectedTextLayer!.offset, initialOffset);
    });

    test('text add edit style and transform flow stays stable', () {
      final controller = EditorController();
      controller.setStageSize(const Size(1080, 1920));

      controller.addTextLayer();
      final layerId = controller.selectedTextLayerId!;

      expect(controller.selectedTextLayer!.offset, Offset.zero);

      controller.updateTextLayerContent(layerId, 'Mana Poster');
      controller.updateSelectedTextStyle(
        controller.selectedTextLayer!.style.copyWith(
          fontSize: 48,
          isBold: true,
          isItalic: true,
          color: const Color(0xFF2563EB),
          letterSpacing: 2,
          lineHeight: 1.4,
          strokeColor: const Color(0xFFFFFFFF),
          strokeWidth: 2,
          backgroundHighlightColor: const Color(0x22000000),
          gradientColors: const <Color>[Color(0xFF8B5CF6), Color(0xFF3B82F6)],
          curve: 0.2,
        ),
      );

      controller.onTextScaleStart(
        layerId,
        ScaleStartDetails(focalPoint: const Offset(100, 100)),
      );
      controller.onTextScaleUpdate(
        layerId,
        ScaleUpdateDetails(
          scale: 1.3,
          rotation: 0.2,
          focalPoint: const Offset(132, 138),
        ),
      );
      controller.completeTextLayerTransform(layerId);

      expect(controller.selectedTextLayer!.text, 'Mana Poster');
      expect(controller.selectedTextLayer!.style.fontSize, 48);
      expect(controller.selectedTextLayer!.style.isBold, isTrue);
      expect(controller.selectedTextLayer!.style.isItalic, isTrue);
      expect(controller.selectedTextLayer!.style.gradientColors, isNotNull);
      expect(controller.selectedTextLayer!.style.curve, 0.2);
      expect(controller.selectedTextLayer!.scale, greaterThan(1));
      expect(controller.canUndo, isTrue);

      controller.duplicateSelectedTextLayer();
      expect(controller.textLayers.length, 2);

      controller.undo();
      expect(controller.textLayers.length, 1);
    });

    test(
      'layer management keeps order selection and exact actions stable',
      () async {
        final controller = EditorController();
        controller.setStageSize(const Size(1080, 1920));

        await controller.addPhotoToStage('https://example.com/surface.png');
        await controller.addPhotoToStage('https://example.com/photo-2.png');
        controller.addTextLayer();
        controller.addElementToStage(controller.elementAssets.first);
        controller.addStickerToStage(controller.stickerAssets.first);
        controller.addShapeToStage(ShapeKind.rectangle);

        final initialPanel = controller.layerEntriesForPanel;
        final overlayIds = initialPanel
            .where((entry) => entry.isMovable)
            .map((entry) => entry.entryId)
            .toList(growable: false);

        expect(overlayIds.first, 'shape:${controller.selectedShapeLayerId}');

        controller.reorderOverlayLayersByPanelOrder(<String>[
          'text:${controller.textLayers.first.id}',
          'element:${controller.elementLayers.first.id}',
          'sticker:${controller.stickerLayers.first.id}',
          'shape:${controller.shapeLayers.first.id}',
          'photo:${controller.extraPhotoLayers.first.id}',
        ]);

        final reordered = controller.layerEntriesForPanel
            .where((entry) => entry.isMovable)
            .map((entry) => entry.entryId)
            .toList(growable: false);
        expect(reordered.first, 'text:${controller.textLayers.first.id}');

        controller.selectLayerFromEntry(
          'text:${controller.textLayers.first.id}',
        );
        expect(controller.selectedTextLayerId, controller.textLayers.first.id);

        controller.renameLayerFromEntry(
          'text:${controller.textLayers.first.id}',
          'Headline',
        );
        expect(controller.textLayers.first.name, 'Headline');

        controller.toggleVisibilityForLayerEntry(
          'text:${controller.textLayers.first.id}',
        );
        expect(controller.textLayers.first.isVisible, isFalse);

        controller.toggleVisibilityForLayerEntry(
          'text:${controller.textLayers.first.id}',
        );
        expect(controller.textLayers.first.isVisible, isTrue);

        controller.toggleLockForLayerEntry(
          'text:${controller.textLayers.first.id}',
        );
        expect(controller.textLayers.first.isLocked, isTrue);

        controller.toggleLockForLayerEntry(
          'text:${controller.textLayers.first.id}',
        );
        expect(controller.textLayers.first.isLocked, isFalse);

        controller.duplicateLayerFromEntry(
          'text:${controller.textLayers.first.id}',
        );
        expect(controller.textLayers.length, 2);
        expect(controller.selectedTextLayerId, isNotNull);

        controller.deleteLayerFromEntry(
          'text:${controller.selectedTextLayerId!}',
        );
        expect(controller.textLayers.length, 1);

        controller.bringLayerToFrontFromEntry(
          'photo:${controller.extraPhotoLayers.first.id}',
        );
        final topAfterBringFront = controller.layerEntriesForPanel
            .where((entry) => entry.isMovable)
            .first
            .entryId;
        expect(
          topAfterBringFront,
          'photo:${controller.extraPhotoLayers.first.id}',
        );

        controller.sendLayerToBackFromEntry(
          'photo:${controller.extraPhotoLayers.first.id}',
        );
        final bottomAfterSendBack = controller.layerEntriesForPanel
            .where((entry) => entry.isMovable)
            .last
            .entryId;
        expect(
          bottomAfterSendBack,
          'photo:${controller.extraPhotoLayers.first.id}',
        );
      },
    );

    test(
      'selected-layer quick actions affect only active selected layer',
      () async {
        final controller = EditorController();
        controller.setStageSize(const Size(1080, 1920));

        await controller.addPhotoToStage('https://example.com/surface.png');
        await controller.addPhotoToStage('https://example.com/photo-2.png');
        controller.addTextLayer();
        controller.addElementToStage(controller.elementAssets.first);
        controller.addStickerToStage(controller.stickerAssets.first);
        controller.addShapeToStage(ShapeKind.rectangle);

        final photoId = controller.extraPhotoLayers.first.id;
        final textId = controller.textLayers.first.id;
        final elementId = controller.elementLayers.first.id;
        final stickerId = controller.stickerLayers.first.id;
        final shapeId = controller.shapeLayers.first.id;

        controller.selectExtraPhotoLayer(photoId);
        controller.updateSelectedLayerOpacity(0.42);
        controller.updateSelectedLayerShadow(
          color: const Color(0xFF2563EB),
          blur: 0.4,
          distance: 0.3,
          opacity: 0.7,
        );
        controller.updateSelectedLayerBlendMode(LayerBlendModeOption.multiply);
        controller.flipSelectedLayerHorizontal();
        controller.updateSelectedLayerRotation(1.2);

        expect(controller.extraPhotoLayers.first.visuals.opacity, 0.42);
        expect(
          controller.extraPhotoLayers.first.visuals.blendMode,
          LayerBlendModeOption.multiply,
        );
        expect(controller.extraPhotoLayers.first.visuals.flipX, isTrue);
        expect(controller.extraPhotoLayers.first.rotation, isNot(0));
        expect(controller.textLayers.first.style.opacity, 1);

        controller.selectTextLayer(textId);
        controller.updateSelectedLayerOpacity(0.55);
        controller.updateSelectedLayerShadow(
          color: const Color(0xFF000000),
          blur: 0.5,
          distance: 0.2,
          opacity: 0.6,
        );
        controller.updateSelectedLayerBlendMode(LayerBlendModeOption.screen);
        controller.flipSelectedLayerVertical();
        controller.rotateSelectedLayerByQuarterTurn();

        expect(controller.textLayers.first.style.opacity, 0.55);
        expect(
          controller.textLayers.first.blendMode,
          LayerBlendModeOption.screen,
        );
        expect(controller.textLayers.first.isFlippedVertical, isTrue);

        controller.selectElementLayer(elementId);
        controller.toggleSelectedLayerLock();
        expect(controller.elementLayers.first.isLocked, isTrue);

        controller.selectStickerLayer(stickerId);
        controller.duplicateSelectedLayerInPlace();
        expect(controller.stickerLayers.length, 2);
        expect(controller.selectedStickerLayerId, isNotNull);

        controller.selectShapeLayer(shapeId);
        controller.updateSelectedLayerOpacity(0.33);
        expect(controller.shapeLayers.first.visuals.opacity, 0.33);
      },
    );

    test(
      'crop adjust filters and remove bg stay selected-photo only',
      () async {
        final controller = EditorController();
        controller.setStageSize(const Size(1080, 1920));

        final file = await _createTestImageFile();

        await controller.addPhotoToStage(file.path);
        await controller.addPhotoToStage(file.path);

        final extraPhotoId = controller.extraPhotoLayers.first.id;
        controller.selectExtraPhotoLayer(extraPhotoId);

        final cropTool = kEditorTools.firstWhere(
          (tool) => tool.id == EditorToolId.crop,
        );
        controller.openTool(cropTool);
        expect(controller.isCropSessionActive, isTrue);
        controller.updateCropRatio('1:1');
        expect(controller.selectedExtraPhotoLayer!.cropRatio, 1.0);
        controller.cancelCropSession();
        expect(controller.selectedExtraPhotoLayer!.cropRatio, isNull);

        controller.openTool(cropTool);
        controller.updateCropRatio('4:5');
        controller.rotateCropQuarter();
        controller.applyCropSession();
        expect(
          controller.selectedExtraPhotoLayer!.cropRatio,
          closeTo(4 / 5, 0.0001),
        );
        expect(controller.selectedExtraPhotoLayer!.cropTurns, 1);

        final adjustTool = kEditorTools.firstWhere(
          (tool) => tool.id == EditorToolId.adjust,
        );
        controller.openTool(adjustTool);
        controller.updateAdjustBrightness(0.4);
        controller.updateAdjustContrast(0.2);
        expect(controller.selectedExtraPhotoLayer!.adjustments.brightness, 0.4);
        controller.cancelAdjustSession();
        expect(
          controller.selectedExtraPhotoLayer!.adjustments,
          PhotoAdjustments.neutral,
        );

        controller.openTool(adjustTool);
        controller.updateAdjustWarmth(0.35);
        controller.updateAdjustSharpness(0.25);
        controller.applyAdjustSession();
        expect(controller.selectedExtraPhotoLayer!.adjustments.warmth, 0.35);
        expect(controller.selectedExtraPhotoLayer!.adjustments.sharpness, 0.25);

        final filterTool = kEditorTools.firstWhere(
          (tool) => tool.id == EditorToolId.filters,
        );
        controller.openTool(filterTool);
        controller.selectFilterPreset(PhotoFilterPreset.vintage);
        controller.updateFilterIntensity(0.6);
        expect(
          controller.selectedExtraPhotoLayer!.filter.preset,
          PhotoFilterPreset.vintage,
        );
        expect(controller.selectedExtraPhotoLayer!.filter.intensity, 0.6);
        controller.cancelFilterSession();
        expect(
          controller.selectedExtraPhotoLayer!.filter,
          PhotoFilterConfig.none,
        );

        controller.openTool(filterTool);
        controller.selectFilterPreset(PhotoFilterPreset.cool);
        controller.updateFilterIntensity(0.75);
        controller.applyFilterSession();
        expect(
          controller.selectedExtraPhotoLayer!.filter.preset,
          PhotoFilterPreset.cool,
        );
        expect(controller.selectedExtraPhotoLayer!.filter.intensity, 0.75);

        final removeBgTool = kEditorTools.firstWhere(
          (tool) => tool.id == EditorToolId.removeBg,
        );
        controller.openTool(removeBgTool);
        await controller.runAutoRemoveBackground();
        expect(controller.removeBgDraft.hasMask, isTrue);
        controller.setRemoveBgRefineMode(RemoveBgRefineMode.erase);
        controller.updateRemoveBgBrushSize(0.16);
        controller.updateRemoveBgSoftness(0.7);
        controller.startRemoveBgRefineStroke(const Offset(0.2, 0.2));
        controller.appendRemoveBgRefineStroke(const Offset(0.4, 0.4));
        controller.endRemoveBgRefineStroke();
        expect(controller.removeBgDraft.strokes, isNotEmpty);
        controller.applyRemoveBgSession();
        expect(
          controller.selectedExtraPhotoLayer!.removeBgState.hasMask,
          isTrue,
        );

        final surface = controller.mainSurfacePhoto!;
        expect(surface.adjustments, PhotoAdjustments.neutral);
        expect(surface.filter, PhotoFilterConfig.none);
        expect(surface.removeBgState, RemoveBgState.none);
      },
    );

    test(
      'element and sticker browsing keeps real category and recent flow',
      () {
        final controller = EditorController();

        final flowers = controller.filterElementAssets(
          category: 'Flowers',
          query: '',
        );
        expect(flowers, isNotEmpty);
        expect(flowers.every((asset) => asset.category == 'Flowers'), isTrue);

        final searchedFlower = controller.filterElementAssets(
          category: 'Flowers',
          query: 'rose',
        );
        expect(
          searchedFlower.map((asset) => asset.id),
          contains(flowers.first.id),
        );

        expect(
          controller.filterElementAssets(category: 'Recent', query: ''),
          isEmpty,
        );

        controller.addElementToStage(flowers.first);
        final recentElements = controller.filterElementAssets(
          category: 'Recent',
          query: '',
        );
        expect(recentElements.first.id, flowers.first.id);

        final emoji = controller.filterStickerAssets(
          category: 'Emoji',
          query: '',
        );
        expect(emoji, isNotEmpty);
        expect(emoji.every((asset) => asset.category == 'Emoji'), isTrue);

        expect(
          controller.filterStickerAssets(category: 'Recent', query: ''),
          isEmpty,
        );

        controller.addStickerToStage(emoji.first);
        final recentStickers = controller.filterStickerAssets(
          category: 'Recent',
          query: '',
        );
        expect(recentStickers.first.id, emoji.first.id);
      },
    );

    test(
      'draw border frame and draft reopen stay consistent in mixed workflow',
      () async {
        final controller = EditorController();
        controller.setStageSize(const Size(1080, 1920));

        final file = await _createTestImageFile();
        await controller.addPhotoToStage(file.path);
        await controller.addPhotoToStage(file.path);

        final drawTool = kEditorTools.firstWhere(
          (tool) => tool.id == EditorToolId.draw,
        );
        controller.openTool(drawTool);
        controller.beginDrawStroke(const Offset(0.1, 0.1));
        controller.appendDrawStrokePoint(const Offset(0.3, 0.3));
        controller.endDrawStroke();
        controller.beginDrawStroke(const Offset(0.6, 0.2));
        controller.appendDrawStrokePoint(const Offset(0.7, 0.4));
        controller.endDrawStroke();
        expect(controller.canUndoDrawStroke, isTrue);
        controller.undoDrawStroke();
        expect(controller.drawDraftStrokes.length, 1);
        controller.redoDrawStroke();
        expect(controller.drawDraftStrokes.length, 2);
        controller.applyDrawSession();
        expect(controller.drawLayers.length, 1);
        expect(controller.drawLayers.first.strokes.length, 2);

        controller.selectExtraPhotoLayer(controller.extraPhotoLayers.first.id);
        final borderFrameTool = kEditorTools.firstWhere(
          (tool) => tool.id == EditorToolId.borderFrame,
        );
        controller.openTool(borderFrameTool);
        controller.updateBorderStyle(BorderStylePreset.dashed);
        controller.updateBorderThickness(0.08);
        controller.updateBorderCornerRadius(0.18);
        controller.updateBorderOpacity(0.9);
        controller.applyBorderFrameSession();
        expect(
          controller.extraPhotoLayers.first.decoration.border.isVisible,
          isTrue,
        );
        expect(
          controller.extraPhotoLayers.first.decoration.border.style,
          BorderStylePreset.dashed,
        );

        controller.openTool(borderFrameTool);
        controller.setBorderFrameTarget(BorderFrameTarget.fullPoster);
        controller.selectFramePreset(controller.framePresets.first.id);
        controller.updateFrameOpacity(0.85);
        controller.applyBorderFrameSession();
        expect(
          controller.stageBackground.posterDecoration.frame.presetId,
          controller.framePresets.first.id,
        );

        final payload = controller.buildDraftPayload();
        final restored = EditorController()
          ..setStageSize(const Size(1080, 1920));
        restored.applyDraftPayload(payload);

        expect(restored.drawLayers.length, 1);
        expect(restored.drawLayers.first.strokes.length, 2);
        expect(
          restored.extraPhotoLayers.first.decoration.border.style,
          BorderStylePreset.dashed,
        );
        expect(
          restored.stageBackground.posterDecoration.frame.presetId,
          controller.framePresets.first.id,
        );
        expect(restored.canUndo, isTrue);
      },
    );
  });
}

Future<File> _createTestImageFile() async {
  final image = img.Image(width: 120, height: 160);
  img.fill(image, color: img.ColorRgb8(245, 245, 245));
  img.fillRect(
    image,
    x1: 30,
    y1: 20,
    x2: 90,
    y2: 145,
    color: img.ColorRgb8(212, 48, 64),
  );
  final bytes = img.encodePng(image);
  final file = File(
    '${Directory.systemTemp.path}/mana_poster_remove_bg_test_${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
