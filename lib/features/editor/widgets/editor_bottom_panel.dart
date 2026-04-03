import 'package:flutter/material.dart';

import 'package:mana_poster/features/editor/controllers/editor_controller.dart';
import 'package:mana_poster/features/editor/models/editor_stage.dart';
import 'package:mana_poster/features/editor/models/editor_text.dart';
import 'package:mana_poster/features/editor/models/editor_tool.dart';
import 'package:mana_poster/features/editor/utils/editor_image_source.dart';

class EditorBottomPanel extends StatelessWidget {
  const EditorBottomPanel({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final activeTool = controller.activeTool;
        final showTextPanel = controller.isTextEditingContext;
        final showPhotoPanel =
            !showTextPanel &&
            activeTool?.id == EditorToolId.photo &&
            controller.isPhotoLayerEditingContext;
        final showBackgroundPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            activeTool?.id == EditorToolId.background;
        final showElementsPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            activeTool?.id == EditorToolId.elements;
        final showStickersPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            activeTool?.id == EditorToolId.stickers;
        final showDrawPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            !showStickersPanel &&
            activeTool?.id == EditorToolId.draw;
        final showShapesPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            !showStickersPanel &&
            !showDrawPanel &&
            activeTool?.id == EditorToolId.shapes;
        final showCropPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            !showStickersPanel &&
            !showShapesPanel &&
            !showDrawPanel &&
            activeTool?.id == EditorToolId.crop;
        final showAdjustPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            !showStickersPanel &&
            !showCropPanel &&
            activeTool?.id == EditorToolId.adjust;
        final showFiltersPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            !showStickersPanel &&
            !showCropPanel &&
            !showAdjustPanel &&
            activeTool?.id == EditorToolId.filters;
        final showBorderFramePanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            !showStickersPanel &&
            !showCropPanel &&
            !showAdjustPanel &&
            !showFiltersPanel &&
            activeTool?.id == EditorToolId.borderFrame;
        final showRemoveBgPanel =
            !showTextPanel &&
            !showPhotoPanel &&
            !showBackgroundPanel &&
            !showElementsPanel &&
            !showStickersPanel &&
            !showCropPanel &&
            !showAdjustPanel &&
            !showFiltersPanel &&
            !showBorderFramePanel &&
            activeTool?.id == EditorToolId.removeBg;
        final showQuickActionPanel =
            controller.isSelectedLayerQuickActionOpen &&
            controller.selectedLayerQuickActionTool != null;

        final panelHeight = showQuickActionPanel
            ? 208.0
            : showTextPanel
            ? 188.0
            : showPhotoPanel
            ? 188.0
            : showBackgroundPanel
            ? 242.0
            : showElementsPanel
            ? 256.0
            : showStickersPanel
            ? 256.0
            : showShapesPanel
            ? 294.0
            : showDrawPanel
            ? 248.0
            : showCropPanel
            ? 176.0
            : showAdjustPanel
            ? 280.0
            : showFiltersPanel
            ? 220.0
            : showBorderFramePanel
            ? 320.0
            : showRemoveBgPanel
            ? 220.0
            : activeTool == null
            ? 112.0
            : 148.0;

        final panelChild = showQuickActionPanel
            ? _SelectedLayerQuickActionPanel(controller: controller)
            : showTextPanel
            ? _TextToolPanel(controller: controller)
            : showPhotoPanel
            ? _PhotoToolPanel(controller: controller)
            : showBackgroundPanel
            ? _BackgroundToolPanel(controller: controller)
            : showElementsPanel
            ? _ElementsToolPanel(controller: controller)
            : showStickersPanel
            ? _StickersToolPanel(controller: controller)
            : showShapesPanel
            ? _ShapesToolPanel(controller: controller)
            : showDrawPanel
            ? _DrawToolPanel(controller: controller)
            : showCropPanel
            ? _CropToolPanel(controller: controller)
            : showAdjustPanel
            ? _AdjustToolPanel(controller: controller)
            : showFiltersPanel
            ? _FiltersToolPanel(controller: controller)
            : showBorderFramePanel
            ? _BorderFrameToolPanel(controller: controller)
            : showRemoveBgPanel
            ? _RemoveBgToolPanel(controller: controller)
            : activeTool == null
            ? _MainToolsView(controller: controller)
            : _SubToolPanel(controller: controller, activeTool: activeTool);

        return Container(
          height: panelHeight,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: panelChild,
        );
      },
    );
  }
}

class _PhotoToolPanel extends StatelessWidget {
  const _PhotoToolPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedExtraPhotoLayer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.closeTool,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back to tools',
            ),
            const Text(
              'ఫోటో లేయర్స్',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () => controller.onToolOptionTap(
                kEditorTools.firstWhere(
                  (tool) => tool.id == EditorToolId.photo,
                ),
                'గ్యాలరీ',
              ),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add Photo'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(102, 36),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (controller.hasSelectedEditableLayer) ...<Widget>[
          const SizedBox(height: 6),
          _SelectedLayerQuickActionsRow(controller: controller),
        ],
        if (selected == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              'లేయర్ ఎంపిక కాలేదు. స్టేజ్‌లో ఫోటోపై ట్యాప్ చేయండి.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: 4),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                ActionChip(
                  label: const Text('Send Back'),
                  onPressed: controller.reorderSelectedExtraPhotoBackward,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Bring Forward'),
                  onPressed: controller.reorderSelectedExtraPhotoForward,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('To Front'),
                  onPressed: controller.bringSelectedExtraPhotoToFront,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(selected.isLocked ? 'Unlock' : 'Lock'),
                  onPressed: controller.toggleSelectedExtraPhotoLock,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(selected.isVisible ? 'Hide' : 'Show'),
                  onPressed: controller.toggleSelectedExtraPhotoVisibility,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Duplicate'),
                  onPressed: controller.duplicateSelectedExtraPhotoLayer,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Delete'),
                  onPressed: controller.deleteSelectedExtraPhotoLayer,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CropToolPanel extends StatelessWidget {
  const _CropToolPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasCropTargetForSession) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: controller.closeTool,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Text(
                'Crop',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Text(
              'Crop కోసం ముందు ఒక photo layer ని select చేయండి.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.cancelCropSession,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back',
            ),
            TextButton(
              onPressed: controller.resetCropSession,
              child: const Text('Reset'),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: controller.updateCropRatio,
              itemBuilder: (_) {
                return controller.cropRatioOptions
                    .map(
                      (entry) => PopupMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.aspect_ratio_rounded, size: 16),
                    SizedBox(width: 4),
                    Text('Ratio'),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: controller.rotateCropQuarter,
              icon: const Icon(Icons.rotate_90_degrees_ccw_rounded, size: 16),
              label: const Text('Rotate'),
            ),
            const SizedBox(width: 2),
            FilledButton(
              onPressed: controller.applyCropSession,
              child: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.cropRatioOptions.length,
            itemBuilder: (_, index) {
              final item = controller.cropRatioOptions[index];
              final selected = controller.cropDraftRatioKey == item.key;
              return ChoiceChip(
                label: Text(item.value),
                selected: selected,
                onSelected: (_) => controller.updateCropRatio(item.key),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
          ),
        ),
      ],
    );
  }
}

class _AdjustToolPanel extends StatelessWidget {
  const _AdjustToolPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasAdjustTargetForSession) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: controller.closeTool,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Text(
                'Adjust',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Text(
              'Adjust కోసం ముందుగా ఒక photo layer ని select చేయండి.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final values = controller.adjustDraft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.cancelAdjustSession,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back',
            ),
            TextButton(
              onPressed: controller.resetAdjustSession,
              child: const Text('Reset'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: controller.applyAdjustSession,
              child: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            children: <Widget>[
              _AdjustSliderRow(
                label: 'Brightness',
                value: values.brightness,
                onChanged: controller.updateAdjustBrightness,
              ),
              _AdjustSliderRow(
                label: 'Contrast',
                value: values.contrast,
                onChanged: controller.updateAdjustContrast,
              ),
              _AdjustSliderRow(
                label: 'Saturation',
                value: values.saturation,
                onChanged: controller.updateAdjustSaturation,
              ),
              _AdjustSliderRow(
                label: 'Warmth',
                value: values.warmth,
                onChanged: controller.updateAdjustWarmth,
              ),
              _AdjustSliderRow(
                label: 'Tint',
                value: values.tint,
                onChanged: controller.updateAdjustTint,
              ),
              _AdjustSliderRow(
                label: 'Highlights',
                value: values.highlights,
                onChanged: controller.updateAdjustHighlights,
              ),
              _AdjustSliderRow(
                label: 'Shadows',
                value: values.shadows,
                onChanged: controller.updateAdjustShadows,
              ),
              _AdjustSliderRow(
                label: 'Sharpness',
                value: values.sharpness,
                onChanged: controller.updateAdjustSharpness,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdjustSliderRow extends StatelessWidget {
  const _AdjustSliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = -1.0,
    this.max = 1.0,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersToolPanel extends StatelessWidget {
  const _FiltersToolPanel({required this.controller});

  final EditorController controller;

  static const List<(PhotoFilterPreset, String)> _presets =
      <(PhotoFilterPreset, String)>[
        (PhotoFilterPreset.natural, 'Natural'),
        (PhotoFilterPreset.warm, 'Warm'),
        (PhotoFilterPreset.cool, 'Cool'),
        (PhotoFilterPreset.bright, 'Bright'),
        (PhotoFilterPreset.vintage, 'Vintage'),
        (PhotoFilterPreset.blackWhite, 'Black & White'),
        (PhotoFilterPreset.cinematic, 'Cinematic'),
        (PhotoFilterPreset.soft, 'Soft'),
        (PhotoFilterPreset.vivid, 'Vivid'),
        (PhotoFilterPreset.matte, 'Matte'),
      ];

  @override
  Widget build(BuildContext context) {
    if (!controller.hasFilterTargetForSession) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: controller.closeTool,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Text(
                'Filters',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Text(
              'Filters కోసం ముందుగా ఒక photo layer ని select చేయండి.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final draft = controller.filterDraft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.cancelFilterSession,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back',
            ),
            TextButton(
              onPressed: controller.resetFilterSession,
              child: const Text('Reset'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: controller.applyFilterSession,
              child: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            itemBuilder: (_, index) {
              final preset = _presets[index];
              final selected = draft.preset == preset.$1 && !draft.isNeutral;
              return ChoiceChip(
                label: Text(preset.$2),
                selected: selected,
                onSelected: (_) => controller.selectFilterPreset(preset.$1),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const SizedBox(
              width: 62,
              child: Text(
                'Intensity',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Slider(
                value: draft.intensity.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                onChanged: controller.updateFilterIntensity,
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${(draft.intensity * 100).round()}%',
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BorderFrameToolPanel extends StatefulWidget {
  const _BorderFrameToolPanel({required this.controller});

  final EditorController controller;

  @override
  State<_BorderFrameToolPanel> createState() => _BorderFrameToolPanelState();
}

class _BorderFrameToolPanelState extends State<_BorderFrameToolPanel> {
  FramePresetCategory _activeCategory = FramePresetCategory.devotional;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final draft = controller.borderFrameDraft;
    final favoriteIds = controller.favoriteFramePresetIds.toSet();
    final recentIds = controller.recentFramePresetIds;
    final filteredPresets = controller.framePresets
        .where((preset) => preset.category == _activeCategory)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.cancelBorderFrameSession,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back',
            ),
            TextButton(
              onPressed: controller.resetBorderFrameSession,
              child: const Text('Reset'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: controller.applyBorderFrameSession,
              child: const Text('Apply'),
            ),
          ],
        ),
        SizedBox(
          height: 34,
          child: Row(
            children: <Widget>[
              ChoiceChip(
                label: const Text('Border'),
                selected:
                    controller.borderFrameSection == BorderFrameSection.border,
                onSelected: (_) =>
                    controller.setBorderFrameSection(BorderFrameSection.border),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Frame'),
                selected:
                    controller.borderFrameSection == BorderFrameSection.frame,
                onSelected: (_) =>
                    controller.setBorderFrameSection(BorderFrameSection.frame),
              ),
              const Spacer(),
              ChoiceChip(
                label: const Text('Photo'),
                selected:
                    controller.borderFrameTarget ==
                    BorderFrameTarget.selectedPhoto,
                onSelected: (_) => controller.setBorderFrameTarget(
                  BorderFrameTarget.selectedPhoto,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Poster'),
                selected:
                    controller.borderFrameTarget ==
                    BorderFrameTarget.fullPoster,
                onSelected: (_) => controller.setBorderFrameTarget(
                  BorderFrameTarget.fullPoster,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: controller.borderFrameSection == BorderFrameSection.border
              ? ListView(
                  children: <Widget>[
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('Solid'),
                            selected:
                                draft.border.style == BorderStylePreset.solid,
                            onSelected: (_) => controller.updateBorderStyle(
                              BorderStylePreset.solid,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Gradient'),
                            selected:
                                draft.border.style ==
                                BorderStylePreset.gradient,
                            onSelected: (_) => controller.updateBorderStyle(
                              BorderStylePreset.gradient,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Dashed'),
                            selected:
                                draft.border.style == BorderStylePreset.dashed,
                            onSelected: (_) => controller.updateBorderStyle(
                              BorderStylePreset.dashed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AdjustSliderRow(
                      label: 'Thickness',
                      value: draft.border.thickness,
                      onChanged: controller.updateBorderThickness,
                      min: 0,
                      max: 0.18,
                    ),
                    _AdjustSliderRow(
                      label: 'Radius',
                      value: draft.border.cornerRadius,
                      onChanged: controller.updateBorderCornerRadius,
                      min: 0,
                      max: 0.30,
                    ),
                    _AdjustSliderRow(
                      label: 'Opacity',
                      value: draft.border.opacity,
                      onChanged: controller.updateBorderOpacity,
                      min: 0,
                      max: 1,
                    ),
                    _AdjustSliderRow(
                      label: 'Shadow',
                      value: draft.border.shadow,
                      onChanged: controller.updateBorderShadow,
                      min: 0,
                      max: 1,
                    ),
                  ],
                )
              : ListView(
                  children: <Widget>[
                    if (favoriteIds.isNotEmpty) ...<Widget>[
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, index) {
                            final preset = controller.framePresets.firstWhere(
                              (item) => item.id == favoriteIds.elementAt(index),
                            );
                            return ActionChip(
                              label: Text(preset.name),
                              onPressed: () =>
                                  controller.selectFramePreset(preset.id),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemCount: favoriteIds.length,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (recentIds.isNotEmpty) ...<Widget>[
                      const Text(
                        'Recent',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, index) {
                            final preset = controller.framePresets.firstWhere(
                              (item) => item.id == recentIds[index],
                            );
                            return ActionChip(
                              label: Text(preset.name),
                              onPressed: () =>
                                  controller.selectFramePreset(preset.id),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemCount: recentIds.length,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) {
                          final category = FramePresetCategory.values[index];
                          return ChoiceChip(
                            label: Text(_frameCategoryLabel(category)),
                            selected: _activeCategory == category,
                            onSelected: (_) =>
                                setState(() => _activeCategory = category),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: FramePresetCategory.values.length,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) {
                          final preset = filteredPresets[index];
                          final selected = draft.frame.presetId == preset.id;
                          return InkWell(
                            onTap: () =>
                                controller.selectFramePreset(preset.id),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              width: 94,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: <Color>[
                                            preset.primaryColor,
                                            preset.secondaryColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => controller
                                              .toggleFavoriteFramePreset(
                                                preset.id,
                                              ),
                                          icon: Icon(
                                            favoriteIds.contains(preset.id)
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    preset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: filteredPresets.length,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AdjustSliderRow(
                      label: 'Size',
                      value: draft.frame.size,
                      onChanged: controller.updateFrameSize,
                      min: 0.05,
                      max: 0.24,
                    ),
                    _AdjustSliderRow(
                      label: 'Opacity',
                      value: draft.frame.opacity,
                      onChanged: controller.updateFrameOpacity,
                      min: 0,
                      max: 1,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _frameCategoryLabel(FramePresetCategory category) {
    switch (category) {
      case FramePresetCategory.devotional:
        return 'Devotional';
      case FramePresetCategory.floral:
        return 'Floral';
      case FramePresetCategory.birthday:
        return 'Birthday';
      case FramePresetCategory.wedding:
        return 'Wedding';
      case FramePresetCategory.festive:
        return 'Festive';
    }
  }
}

class _RemoveBgToolPanel extends StatelessWidget {
  const _RemoveBgToolPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasRemoveBgTargetForSession) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: controller.closeTool,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Text(
                'Remove BG',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Text(
              'Remove BG కోసం ముందుగా ఒక photo layer ని select చేయండి.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.cancelRemoveBgSession,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back',
            ),
            ActionChip(
              label: Text(
                controller.isRemoveBgProcessing
                    ? 'Processing...'
                    : 'Auto Remove',
              ),
              onPressed: controller.isRemoveBgProcessing
                  ? null
                  : controller.runAutoRemoveBackground,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('Refine'),
              onPressed: () =>
                  controller.setRemoveBgRefineMode(RemoveBgRefineMode.erase),
            ),
            const Spacer(),
            TextButton(
              onPressed: controller.resetRemoveBgSession,
              child: const Text('Reset'),
            ),
            FilledButton(
              onPressed: controller.applyRemoveBgSession,
              child: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: Row(
            children: <Widget>[
              ChoiceChip(
                label: const Text('Erase'),
                selected:
                    controller.removeBgRefineMode == RemoveBgRefineMode.erase,
                onSelected: (_) =>
                    controller.setRemoveBgRefineMode(RemoveBgRefineMode.erase),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Restore'),
                selected:
                    controller.removeBgRefineMode == RemoveBgRefineMode.restore,
                onSelected: (_) => controller.setRemoveBgRefineMode(
                  RemoveBgRefineMode.restore,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Refine mode lo photo pai drag cheyyandi',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _RemoveBgSliderRow(
          title: 'Brush',
          value: controller.removeBgBrushSize,
          min: 0.04,
          max: 0.28,
          onChanged: controller.updateRemoveBgBrushSize,
        ),
        _RemoveBgSliderRow(
          title: 'Softness',
          value: controller.removeBgSoftness,
          min: 0,
          max: 1,
          onChanged: controller.updateRemoveBgSoftness,
        ),
      ],
    );
  }
}

class _RemoveBgSliderRow extends StatelessWidget {
  const _RemoveBgSliderRow({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 58,
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

enum _BackgroundTab { color, gradient, image }

class _BackgroundToolPanel extends StatefulWidget {
  const _BackgroundToolPanel({required this.controller});

  final EditorController controller;

  @override
  State<_BackgroundToolPanel> createState() => _BackgroundToolPanelState();
}

class _BackgroundToolPanelState extends State<_BackgroundToolPanel> {
  _BackgroundTab _tab = _BackgroundTab.color;
  final TextEditingController _hexController = TextEditingController(
    text: '#FFFFFF',
  );
  double _r = 255;
  double _g = 255;
  double _b = 255;
  double _gradientAngle = 270;
  bool _customThreeColor = false;
  Color _gradientColor1 = const Color(0xFFF8FAFF);
  Color _gradientColor2 = const Color(0xFFEAF1FF);
  Color _gradientColor3 = const Color(0xFFDDEAFE);

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final background = controller.stageBackground;
    final selectedSolid = background.solidColor ?? Colors.white;
    if (_tab == _BackgroundTab.color) {
      _syncRgbWithColor(selectedSolid);
    }
    if (_tab == _BackgroundTab.gradient) {
      _syncGradientWithBackground(background);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.closeTool,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back to tools',
            ),
            const Text(
              'Background',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              _tabChip(_BackgroundTab.color, 'Color'),
              const SizedBox(width: 8),
              _tabChip(_BackgroundTab.gradient, 'Gradient'),
              const SizedBox(width: 8),
              _tabChip(_BackgroundTab.image, 'Image'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: switch (_tab) {
            _BackgroundTab.color => _buildColorTab(controller, background),
            _BackgroundTab.gradient => _buildGradientTab(
              controller,
              background,
            ),
            _BackgroundTab.image => _buildImageTab(controller, background),
          },
        ),
      ],
    );
  }

  Widget _tabChip(_BackgroundTab tab, String text) {
    final selected = _tab == tab;
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => setState(() => _tab = tab),
    );
  }

  Widget _buildColorTab(
    EditorController controller,
    StageBackgroundConfig background,
  ) {
    final selected = background.solidColor ?? Colors.white;
    final selectedHex =
        '#${selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    if (_hexController.text != selectedHex) {
      _hexController.text = selectedHex;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, index) {
              final color = _colorPalette[index];
              return _colorDot(
                color,
                isSelected: selected.toARGB32() == color.toARGB32(),
                onTap: () => controller.setStageSolidBackground(color),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemCount: _colorPalette.length,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Recent Colors',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, index) {
              final color = controller.recentBackgroundColors[index];
              return _colorDot(
                color,
                isSelected: selected.toARGB32() == color.toARGB32(),
                size: 26,
                onTap: () => controller.setStageSolidBackground(color),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemCount: controller.recentBackgroundColors.length,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _hexController,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '#FFFFFF',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  final color = _colorFromHex(_hexController.text);
                  if (color != null) {
                    controller.setStageSolidBackground(color);
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _channelSlider(
          label: 'R',
          value: _r,
          onChanged: (v) => setState(() => _r = v),
          onChangeEnd: (_) => _applyRgbColor(controller),
        ),
        _channelSlider(
          label: 'G',
          value: _g,
          onChanged: (v) => setState(() => _g = v),
          onChangeEnd: (_) => _applyRgbColor(controller),
        ),
        _channelSlider(
          label: 'B',
          value: _b,
          onChanged: (v) => setState(() => _b = v),
          onChangeEnd: (_) => _applyRgbColor(controller),
        ),
      ],
    );
  }

  Widget _buildGradientTab(
    EditorController controller,
    StageBackgroundConfig background,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.backgroundGradientPresets.length,
            itemBuilder: (_, index) {
              final colors = controller.backgroundGradientPresets[index];
              return InkWell(
                onTap: () => controller.setStageGradientBackground(
                  colors,
                  angle: background.gradientAngle,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  width: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(colors: colors),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Switch(
              value: _customThreeColor,
              onChanged: (v) {
                setState(() => _customThreeColor = v);
                _applyCustomGradient(controller);
              },
            ),
            const Text('3-color gradient'),
          ],
        ),
        SizedBox(
          height: 34,
          child: Row(
            children: <Widget>[
              _colorDot(
                _gradientColor1,
                onTap: () => _cycleGradientColor(controller, 1),
                isSelected: false,
              ),
              const SizedBox(width: 8),
              _colorDot(
                _gradientColor2,
                onTap: () => _cycleGradientColor(controller, 2),
                isSelected: false,
              ),
              if (_customThreeColor) ...<Widget>[
                const SizedBox(width: 8),
                _colorDot(
                  _gradientColor3,
                  onTap: () => _cycleGradientColor(controller, 3),
                  isSelected: false,
                ),
              ],
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => _applyCustomGradient(controller),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            const SizedBox(width: 54, child: Text('Angle')),
            Expanded(
              child: Slider(
                value: _gradientAngle,
                min: 0,
                max: 360,
                onChanged: (v) {
                  setState(() => _gradientAngle = v);
                  _applyCustomGradient(controller);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageTab(
    EditorController controller,
    StageBackgroundConfig background,
  ) {
    final imageFit = background.imageFit;
    final blur = background.imageBlur;
    final opacity = background.imageOpacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: controller.requestBackgroundImagePicker,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Gallery'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    background.type == StageBackgroundType.image &&
                        (background.imageUrl?.isNotEmpty ?? false)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            buildEditorImage(
                              background.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              color: Colors.black.withAlpha(50),
                              alignment: Alignment.bottomLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: const Text(
                                'Current background',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Pick a background image',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Fit'),
              selected: imageFit == StageBackgroundImageFit.fit,
              onSelected: (_) =>
                  controller.setBackgroundImageFit(StageBackgroundImageFit.fit),
            ),
            ChoiceChip(
              label: const Text('Fill'),
              selected: imageFit == StageBackgroundImageFit.fill,
              onSelected: (_) => controller.setBackgroundImageFit(
                StageBackgroundImageFit.fill,
              ),
            ),
            ChoiceChip(
              label: const Text('Stretch'),
              selected: imageFit == StageBackgroundImageFit.stretch,
              onSelected: (_) => controller.setBackgroundImageFit(
                StageBackgroundImageFit.stretch,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            const SizedBox(width: 54, child: Text('Blur')),
            Expanded(
              child: Slider(
                value: blur,
                min: 0,
                max: 20,
                onChanged: controller.setBackgroundImageBlur,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            const SizedBox(width: 54, child: Text('Opacity')),
            Expanded(
              child: Slider(
                value: opacity,
                min: 0.1,
                max: 1,
                onChanged: controller.setBackgroundImageOpacity,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _channelSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(width: 18, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  Widget _colorDot(
    Color color, {
    required bool isSelected,
    required VoidCallback onTap,
    double size = 30,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  void _syncRgbWithColor(Color color) {
    _r = color.r.toDouble();
    _g = color.g.toDouble();
    _b = color.b.toDouble();
  }

  void _syncGradientWithBackground(StageBackgroundConfig background) {
    final colors = background.gradientColors;
    if (background.type != StageBackgroundType.gradient ||
        colors == null ||
        colors.length < 2) {
      return;
    }
    _gradientAngle = background.gradientAngle;
    _gradientColor1 = colors[0];
    _gradientColor2 = colors[1];
    if (colors.length >= 3) {
      _customThreeColor = true;
      _gradientColor3 = colors[2];
    } else {
      _customThreeColor = false;
    }
  }

  void _applyRgbColor(EditorController controller) {
    final color = Color.fromARGB(255, _r.round(), _g.round(), _b.round());
    controller.setStageSolidBackground(color);
    _hexController.text =
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  void _applyCustomGradient(EditorController controller) {
    final colors = _customThreeColor
        ? <Color>[_gradientColor1, _gradientColor2, _gradientColor3]
        : <Color>[_gradientColor1, _gradientColor2];
    controller.setStageGradientBackground(colors, angle: _gradientAngle);
  }

  void _cycleGradientColor(EditorController controller, int slot) {
    final palette = _colorPalette;
    Color next(Color current) {
      final index = palette.indexWhere(
        (color) => color.toARGB32() == current.toARGB32(),
      );
      if (index < 0) {
        return palette.first;
      }
      return palette[(index + 1) % palette.length];
    }

    setState(() {
      if (slot == 1) {
        _gradientColor1 = next(_gradientColor1);
      } else if (slot == 2) {
        _gradientColor2 = next(_gradientColor2);
      } else {
        _gradientColor3 = next(_gradientColor3);
      }
    });
    _applyCustomGradient(controller);
  }

  Color? _colorFromHex(String raw) {
    final value = raw.trim().replaceAll('#', '');
    if (value.length != 6) {
      return null;
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return null;
    }
    return Color(0xFF000000 | parsed);
  }

  static const List<Color> _colorPalette = <Color>[
    Colors.white,
    Color(0xFFF8FAFC),
    Color(0xFFE2E8F0),
    Color(0xFFCBD5E1),
    Color(0xFF111827),
    Color(0xFF1D4ED8),
    Color(0xFF059669),
    Color(0xFFF97316),
    Color(0xFFDC2626),
    Color(0xFFA855F7),
  ];
}

class _ElementsToolPanel extends StatefulWidget {
  const _ElementsToolPanel({required this.controller});

  final EditorController controller;

  @override
  State<_ElementsToolPanel> createState() => _ElementsToolPanelState();
}

class _ElementsToolPanelState extends State<_ElementsToolPanel> {
  String _selectedCategory = 'Trending';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final assets = controller.filterElementAssets(
      category: _selectedCategory,
      query: _query,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EditorPanelHeader(
          title: 'Elements / PNG',
          onBack: controller.closeTool,
        ),
        if (controller.hasSelectedEditableLayer) ...<Widget>[
          const SizedBox(height: 6),
          _SelectedLayerQuickActionsRow(controller: controller),
        ],
        _ToolSearchField(
          hintText: 'Search elements',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.elementCategories.length,
            itemBuilder: (_, index) {
              final category = controller.elementCategories[index];
              return ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: assets.isEmpty
              ? const _ToolEmptyState(
                  icon: Icons.image_not_supported_outlined,
                  title: 'No PNG found',
                  subtitle: 'Try another keyword or category.',
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (_, index) {
                    final asset = assets[index];
                    return InkWell(
                      onTap: () => controller.addElementToStage(asset),
                      borderRadius: BorderRadius.circular(8),
                      child: _AssetGridTile(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: buildEditorImage(
                            asset.url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StickersToolPanel extends StatefulWidget {
  const _StickersToolPanel({required this.controller});

  final EditorController controller;

  @override
  State<_StickersToolPanel> createState() => _StickersToolPanelState();
}

class _StickersToolPanelState extends State<_StickersToolPanel> {
  String _selectedCategory = 'Trending';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final assets = controller.filterStickerAssets(
      category: _selectedCategory,
      query: _query,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EditorPanelHeader(title: 'Stickers', onBack: controller.closeTool),
        if (controller.hasSelectedEditableLayer) ...<Widget>[
          const SizedBox(height: 6),
          _SelectedLayerQuickActionsRow(controller: controller),
        ],
        _ToolSearchField(
          hintText: 'Search stickers',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.stickerCategories.length,
            itemBuilder: (_, index) {
              final category = controller.stickerCategories[index];
              return ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: assets.isEmpty
              ? const _ToolEmptyState(
                  icon: Icons.emoji_emotions_outlined,
                  title: 'No stickers found',
                  subtitle: 'Try another keyword or category.',
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (_, index) {
                    final asset = assets[index];
                    return InkWell(
                      onTap: () => controller.addStickerToStage(asset),
                      borderRadius: BorderRadius.circular(8),
                      child: _AssetGridTile(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: buildEditorImage(
                            asset.url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ShapesToolPanel extends StatelessWidget {
  const _ShapesToolPanel({required this.controller});

  final EditorController controller;

  static const List<({ShapeKind kind, String label, IconData icon})>
  _shapes = <({ShapeKind kind, String label, IconData icon})>[
    (
      kind: ShapeKind.rectangle,
      label: 'Rectangle',
      icon: Icons.rectangle_outlined,
    ),
    (
      kind: ShapeKind.roundedRectangle,
      label: 'Rounded',
      icon: Icons.rounded_corner,
    ),
    (kind: ShapeKind.circle, label: 'Circle', icon: Icons.circle_outlined),
    (kind: ShapeKind.oval, label: 'Oval', icon: Icons.egg_outlined),
    (kind: ShapeKind.line, label: 'Line', icon: Icons.horizontal_rule_rounded),
    (
      kind: ShapeKind.triangle,
      label: 'Triangle',
      icon: Icons.change_history_outlined,
    ),
    (kind: ShapeKind.polygon, label: 'Polygon', icon: Icons.hexagon_outlined),
    (kind: ShapeKind.star, label: 'Star', icon: Icons.star_outline_rounded),
    (
      kind: ShapeKind.heart,
      label: 'Heart',
      icon: Icons.favorite_border_rounded,
    ),
    (
      kind: ShapeKind.arrow,
      label: 'Arrow',
      icon: Icons.arrow_right_alt_rounded,
    ),
  ];

  static const List<Color> _palette = <Color>[
    Color(0xFF111827),
    Color(0xFFFFFFFF),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
  ];

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFF6366F1), Color(0xFF06B6D4)],
    <Color>[Color(0xFFF97316), Color(0xFFEF4444)],
    <Color>[Color(0xFF16A34A), Color(0xFF22D3EE)],
  ];

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedShapeLayer;
    final shadow = controller.selectedLayerShadow;
    final allowCornerRadius =
        selected != null &&
        (selected.kind == ShapeKind.rectangle ||
            selected.kind == ShapeKind.roundedRectangle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.closeTool,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back to tools',
            ),
            const Text(
              'Shapes',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (controller.hasSelectedEditableLayer) ...<Widget>[
          const SizedBox(height: 4),
          _SelectedLayerQuickActionsRow(controller: controller),
        ],
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _shapes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = _shapes[index];
              return ActionChip(
                avatar: Icon(item.icon, size: 16),
                label: Text(item.label),
                onPressed: () => controller.addShapeToStage(item.kind),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: selected == null
              ? const Center(
                  child: Text(
                    'ఒక shape select చేయండి లేదా కొత్తది add చేయండి',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView(
                  children: <Widget>[
                    const Text(
                      'Fill',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _palette.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final color = _palette[index];
                          final selectedColor =
                              selected.fillColor.toARGB32() ==
                                  color.toARGB32() &&
                              !selected.useGradientFill;
                          return InkWell(
                            onTap: () {
                              controller.updateSelectedShapeGradient(
                                enabled: false,
                              );
                              controller.updateSelectedShapeFillColor(color);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  width: selectedColor ? 2 : 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _gradients.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return ChoiceChip(
                              label: const Text('Solid'),
                              selected: !selected.useGradientFill,
                              onSelected: (_) => controller
                                  .updateSelectedShapeGradient(enabled: false),
                            );
                          }
                          final gradient = _gradients[index - 1];
                          final isSelected =
                              selected.useGradientFill &&
                              selected.gradientColors.length ==
                                  gradient.length &&
                              _matchGradient(selected.gradientColors, gradient);
                          return InkWell(
                            onTap: () => controller.updateSelectedShapeGradient(
                              enabled: true,
                              colors: gradient,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: gradient),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFD1D5DB),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stroke',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _palette.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final color = _palette[index];
                          final selectedColor =
                              selected.strokeColor.toARGB32() ==
                              color.toARGB32();
                          return InkWell(
                            onTap: () => controller
                                .updateSelectedShapeStrokeColor(color),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  width: selectedColor ? 2 : 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _SliderRow(
                      title: 'Stroke',
                      value: selected.strokeWidth,
                      min: 0,
                      max: 0.18,
                      onChanged: controller.updateSelectedShapeStrokeWidth,
                    ),
                    _SliderRow(
                      title: 'Opacity',
                      value: selected.opacity,
                      min: 0.05,
                      max: 1,
                      onChanged: controller.updateSelectedShapeOpacity,
                    ),
                    if (allowCornerRadius)
                      _SliderRow(
                        title: 'Radius',
                        value: selected.cornerRadius,
                        min: 0,
                        max: 0.5,
                        onChanged: controller.updateSelectedShapeCornerRadius,
                      ),
                    _SliderRow(
                      title: 'Shadow',
                      value: shadow.opacity,
                      min: 0,
                      max: 1,
                      onChanged: (value) =>
                          controller.updateSelectedLayerShadow(opacity: value),
                    ),
                    _SliderRow(
                      title: 'Blur',
                      value: shadow.blur,
                      min: 0,
                      max: 1,
                      onChanged: (value) =>
                          controller.updateSelectedLayerShadow(blur: value),
                    ),
                    _SliderRow(
                      title: 'Dist',
                      value: shadow.distance,
                      min: 0,
                      max: 1,
                      onChanged: (value) =>
                          controller.updateSelectedLayerShadow(distance: value),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  bool _matchGradient(List<Color> a, List<Color> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i].toARGB32() != b[i].toARGB32()) {
        return false;
      }
    }
    return true;
  }
}

class _DrawToolPanel extends StatelessWidget {
  const _DrawToolPanel({required this.controller});

  final EditorController controller;

  static const List<Color> _palette = <Color>[
    Color(0xFF111827),
    Color(0xFFFFFFFF),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.closeTool,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            const Text(
              'Draw',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton(
              onPressed: controller.canUndoDrawStroke
                  ? controller.undoDrawStroke
                  : null,
              child: const Text('Undo'),
            ),
            TextButton(
              onPressed: controller.canRedoDrawStroke
                  ? controller.redoDrawStroke
                  : null,
              child: const Text('Redo'),
            ),
          ],
        ),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: DrawToolMode.values
                .map((mode) {
                  final label = switch (mode) {
                    DrawToolMode.pen => 'Pen',
                    DrawToolMode.brush => 'Brush',
                    DrawToolMode.highlighter => 'Highlighter',
                    DrawToolMode.eraser => 'Eraser',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: controller.drawMode == mode,
                      onSelected: (_) => controller.setDrawMode(mode),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: DrawBrushStyle.values
                .map((style) {
                  final label = switch (style) {
                    DrawBrushStyle.smoothPen => 'Smooth',
                    DrawBrushStyle.softBrush => 'Soft',
                    DrawBrushStyle.neonHighlighter => 'Neon',
                    DrawBrushStyle.dottedLine => 'Dotted',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label),
                      selected: controller.drawBrushStyle == style,
                      onSelected: (_) => controller.setDrawBrushStyle(style),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _palette.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final color = _palette[index];
              final selected =
                  controller.drawColor.toARGB32() == color.toARGB32();
              return InkWell(
                onTap: () => controller.setDrawColor(color),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: _SliderRow(
                title: 'Size',
                value: controller.drawSize,
                min: 0.004,
                max: 0.06,
                onChanged: controller.setDrawSize,
              ),
            ),
            Expanded(
              child: _SliderRow(
                title: 'Opacity',
                value: controller.drawOpacity,
                min: 0.08,
                max: 1,
                onChanged: controller.setDrawOpacity,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            FilledButton.tonal(
              onPressed: controller.clearDrawSession,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: controller.applyDrawSession,
              child: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MainToolsView extends StatelessWidget {
  const _MainToolsView({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (controller.hasSelectedEditableLayer) ...<Widget>[
          _SelectedLayerQuickActionsRow(controller: controller),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kEditorTools.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final tool = kEditorTools[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => controller.openTool(tool),
                child: Ink(
                  width: 76,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(tool.icon, size: 22, color: const Color(0xFF1E3A8A)),
                      const SizedBox(height: 6),
                      Text(
                        tool.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EditorPanelHeader extends StatelessWidget {
  const _EditorPanelHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            splashRadius: 20,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Back to tools',
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolSearchField extends StatelessWidget {
  const _ToolSearchField({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF93C5FD)),
          ),
        ),
      ),
    );
  }
}

class _ToolEmptyState extends StatelessWidget {
  const _ToolEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 26, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetGridTile extends StatelessWidget {
  const _AssetGridTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _SelectedLayerQuickActionsRow extends StatelessWidget {
  const _SelectedLayerQuickActionsRow({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final locked = controller.isSelectedLayerLocked;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _QuickActionChip(
            label: 'Transparency',
            icon: Icons.opacity_outlined,
            onTap: () => controller.openSelectedLayerQuickAction(
              EditorToolId.transparency,
            ),
          ),
          _QuickActionChip(
            label: 'Shadow',
            icon: Icons.gradient_outlined,
            onTap: () =>
                controller.openSelectedLayerQuickAction(EditorToolId.shadow),
          ),
          _QuickActionChip(
            label: 'Blend',
            icon: Icons.blur_on_outlined,
            onTap: () =>
                controller.openSelectedLayerQuickAction(EditorToolId.blend),
          ),
          _QuickActionChip(
            label: 'Flip',
            icon: Icons.flip_outlined,
            onTap: () =>
                controller.openSelectedLayerQuickAction(EditorToolId.flip),
          ),
          _QuickActionChip(
            label: 'Rotate',
            icon: Icons.rotate_right_outlined,
            onTap: () =>
                controller.openSelectedLayerQuickAction(EditorToolId.rotate),
          ),
          _QuickActionChip(
            label: 'Duplicate',
            icon: Icons.copy_all_outlined,
            onTap: controller.duplicateSelectedLayerInPlace,
          ),
          _QuickActionChip(
            label: locked ? 'Unlock' : 'Lock',
            icon: locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            onTap: controller.toggleSelectedLayerLock,
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: const Color(0xFF334155)),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: const Color(0xFFF8FAFC),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SelectedLayerQuickActionPanel extends StatelessWidget {
  const _SelectedLayerQuickActionPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final tool = controller.selectedLayerQuickActionTool;
    final title = switch (tool) {
      EditorToolId.transparency => 'Transparency',
      EditorToolId.shadow => 'Shadow',
      EditorToolId.blend => 'Blend',
      EditorToolId.flip => 'Flip',
      EditorToolId.rotate => 'Rotate',
      _ => 'Quick Action',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.closeSelectedLayerQuickAction,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (controller.isSelectedLayerLocked)
              const Text(
                'Locked',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        Expanded(
          child: switch (tool) {
            EditorToolId.transparency => _TransparencyQuickPanel(
              controller: controller,
            ),
            EditorToolId.shadow => _ShadowQuickPanel(controller: controller),
            EditorToolId.blend => _BlendQuickPanel(controller: controller),
            EditorToolId.flip => _FlipQuickPanel(controller: controller),
            EditorToolId.rotate => _RotateQuickPanel(controller: controller),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class _TransparencyQuickPanel extends StatelessWidget {
  const _TransparencyQuickPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _SliderRow(
        title: 'Opacity',
        value: controller.selectedLayerOpacity,
        min: 0,
        max: 1,
        onChanged: controller.isSelectedLayerLocked
            ? (_) {}
            : controller.updateSelectedLayerOpacity,
      ),
    );
  }
}

class _ShadowQuickPanel extends StatelessWidget {
  const _ShadowQuickPanel({required this.controller});

  final EditorController controller;

  static const List<Color> _colors = <Color>[
    Color(0xFF000000),
    Color(0xFF1E293B),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
  ];

  @override
  Widget build(BuildContext context) {
    final shadow = controller.selectedLayerShadow;
    return ListView(
      children: <Widget>[
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _colors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final color = _colors[index];
              final selected = shadow.color.toARGB32() == color.toARGB32();
              return InkWell(
                onTap: controller.isSelectedLayerLocked
                    ? null
                    : () => controller.updateSelectedLayerShadow(color: color),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _SliderRow(
          title: 'Blur',
          value: shadow.blur,
          min: 0,
          max: 1,
          onChanged: controller.isSelectedLayerLocked
              ? (_) {}
              : (value) => controller.updateSelectedLayerShadow(blur: value),
        ),
        _SliderRow(
          title: 'Distance',
          value: shadow.distance,
          min: 0,
          max: 1,
          onChanged: controller.isSelectedLayerLocked
              ? (_) {}
              : (value) =>
                    controller.updateSelectedLayerShadow(distance: value),
        ),
        _SliderRow(
          title: 'Opacity',
          value: shadow.opacity,
          min: 0,
          max: 1,
          onChanged: controller.isSelectedLayerLocked
              ? (_) {}
              : (value) => controller.updateSelectedLayerShadow(opacity: value),
        ),
      ],
    );
  }
}

class _BlendQuickPanel extends StatelessWidget {
  const _BlendQuickPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedLayerBlendMode;
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: LayerBlendModeOption.values
            .map((mode) {
              final label = switch (mode) {
                LayerBlendModeOption.normal => 'Normal',
                LayerBlendModeOption.multiply => 'Multiply',
                LayerBlendModeOption.screen => 'Screen',
                LayerBlendModeOption.overlay => 'Overlay',
              };
              return ChoiceChip(
                label: Text(label),
                selected: selected == mode,
                onSelected: controller.isSelectedLayerLocked
                    ? null
                    : (_) => controller.updateSelectedLayerBlendMode(mode),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _FlipQuickPanel extends StatelessWidget {
  const _FlipQuickPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton.tonalIcon(
            onPressed: controller.isSelectedLayerLocked
                ? null
                : controller.flipSelectedLayerHorizontal,
            icon: const Icon(Icons.flip_rounded, size: 18),
            label: Text(controller.selectedLayerFlipX ? 'Unflip H' : 'Flip H'),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: controller.isSelectedLayerLocked
                ? null
                : controller.flipSelectedLayerVertical,
            icon: const Icon(Icons.flip_camera_android_outlined, size: 18),
            label: Text(controller.selectedLayerFlipY ? 'Unflip V' : 'Flip V'),
          ),
        ],
      ),
    );
  }
}

class _RotateQuickPanel extends StatelessWidget {
  const _RotateQuickPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final degrees =
        ((controller.selectedLayerRotation * 180 / 3.141592653589793) % 360 +
            360) %
        360;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: controller.isSelectedLayerLocked
                  ? null
                  : controller.rotateSelectedLayerByQuarterTurn,
              icon: const Icon(Icons.rotate_90_degrees_cw_rounded, size: 18),
              label: const Text('Rotate 90°'),
            ),
            const Spacer(),
            Text(
              '${degrees.round()}°',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        _SliderRow(
          title: 'Angle',
          value: degrees,
          min: 0,
          max: 360,
          onChanged: controller.isSelectedLayerLocked
              ? (_) {}
              : (value) => controller.updateSelectedLayerRotation(
                  value * 3.141592653589793 / 180,
                ),
        ),
      ],
    );
  }
}

class _SubToolPanel extends StatelessWidget {
  const _SubToolPanel({required this.controller, required this.activeTool});

  final EditorController controller;
  final EditorToolDefinition activeTool;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.closeTool,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back to tools',
            ),
            Text(
              activeTool.label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Text(
              'ఫౌండేషన్ మోడ్',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activeTool.subOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final option = activeTool.subOptions[index];
              return ActionChip(
                label: Text(option),
                onPressed: () => controller.onToolOptionTap(activeTool, option),
                backgroundColor: const Color(0xFFF1F5F9),
                side: const BorderSide(color: Color(0xFFDDE3EC)),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _TextOptionGroup { content, font, style, spacing, effects, layer }

class _TextToolPanel extends StatefulWidget {
  const _TextToolPanel({required this.controller});

  final EditorController controller;

  @override
  State<_TextToolPanel> createState() => _TextToolPanelState();
}

class _TextToolPanelState extends State<_TextToolPanel> {
  _TextOptionGroup _activeGroup = _TextOptionGroup.content;

  static const Map<_TextOptionGroup, String> _groupTitles =
      <_TextOptionGroup, String>{
        _TextOptionGroup.content: 'టెక్స్ట్',
        _TextOptionGroup.font: 'ఫాంట్స్',
        _TextOptionGroup.style: 'స్టైల్',
        _TextOptionGroup.spacing: 'స్పేసింగ్',
        _TextOptionGroup.effects: 'ఎఫెక్ట్స్',
        _TextOptionGroup.layer: 'లేయర్',
      };

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final selectedLayer = controller.selectedTextLayer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: controller.exitTextToolToMainTools,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back to tools',
            ),
            const Text(
              'టెక్స్ట్ టూల్',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: controller.addTextLayer,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Text'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(92, 36),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (controller.hasSelectedEditableLayer) ...<Widget>[
          _SelectedLayerQuickActionsRow(controller: controller),
          const SizedBox(height: 6),
        ],
        if (selectedLayer == null)
          const Expanded(
            child: Center(
              child: Text(
                'టెక్స్ట్ లేయర్ కోసం Add Text నొక్కండి',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else ...<Widget>[
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _TextOptionGroup.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final group = _TextOptionGroup.values[index];
                final selected = group == _activeGroup;
                return ChoiceChip(
                  label: Text(_groupTitles[group] ?? ''),
                  selected: selected,
                  onSelected: (_) => setState(() => _activeGroup = group),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _TextOptionsContent(
              group: _activeGroup,
              controller: controller,
              layer: selectedLayer,
            ),
          ),
        ],
      ],
    );
  }
}

class _TextOptionsContent extends StatelessWidget {
  const _TextOptionsContent({
    required this.group,
    required this.controller,
    required this.layer,
  });

  final _TextOptionGroup group;
  final EditorController controller;
  final EditorTextLayer layer;

  @override
  Widget build(BuildContext context) {
    final style = layer.style;
    switch (group) {
      case _TextOptionGroup.content:
        return ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            ActionChip(
              label: const Text('ఎడిట్ టెక్స్ట్'),
              onPressed: () => controller.requestFullScreenTextEditor(layer.id),
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('ప్రీసెట్: ప్రీమియమ్'),
              onPressed: () {
                controller.updateSelectedTextStyle(
                  style.copyWith(
                    isBold: true,
                    fontSize: 38,
                    letterSpacing: 0.8,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('ప్రీసెట్: ఫెస్టివల్'),
              onPressed: () {
                controller.updateSelectedTextStyle(
                  style.copyWith(
                    isBold: true,
                    gradientColors: const <Color>[
                      Color(0xFFF97316),
                      Color(0xFFEF4444),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      case _TextOptionGroup.font:
        return ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            ...controller.fontCatalog.teluguFonts.map(
              (font) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('తెలుగు: $font'),
                  selected: style.fontFamily == font,
                  onSelected: (_) {
                    controller.updateSelectedTextStyle(
                      style.copyWith(fontFamily: font),
                    );
                  },
                ),
              ),
            ),
            ...controller.fontCatalog.englishFonts.map(
              (font) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('English: $font'),
                  selected: style.fontFamily == font,
                  onSelected: (_) {
                    controller.updateSelectedTextStyle(
                      style.copyWith(fontFamily: font),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      case _TextOptionGroup.style:
        return ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            FilterChip(
              label: const Text('Bold'),
              selected: style.isBold,
              onSelected: (_) => controller.updateSelectedTextStyle(
                style.copyWith(isBold: !style.isBold),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Italic'),
              selected: style.isItalic,
              onSelected: (_) => controller.updateSelectedTextStyle(
                style.copyWith(isItalic: !style.isItalic),
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('ఎడమ'),
              onPressed: () => controller.updateSelectedTextStyle(
                style.copyWith(alignment: TextAlign.left),
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('మధ్య'),
              onPressed: () => controller.updateSelectedTextStyle(
                style.copyWith(alignment: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('కుడి'),
              onPressed: () => controller.updateSelectedTextStyle(
                style.copyWith(alignment: TextAlign.right),
              ),
            ),
          ],
        );
      case _TextOptionGroup.spacing:
        return Column(
          children: <Widget>[
            _SliderRow(
              title: 'Size',
              value: style.fontSize,
              min: 14,
              max: 96,
              onChanged: (value) => controller.updateSelectedTextStyle(
                style.copyWith(fontSize: value),
              ),
            ),
            _SliderRow(
              title: 'Letter',
              value: style.letterSpacing,
              min: -1,
              max: 12,
              onChanged: (value) => controller.updateSelectedTextStyle(
                style.copyWith(letterSpacing: value),
              ),
            ),
            _SliderRow(
              title: 'Line',
              value: style.lineHeight,
              min: 0.8,
              max: 2.6,
              onChanged: (value) => controller.updateSelectedTextStyle(
                style.copyWith(lineHeight: value),
              ),
            ),
          ],
        );
      case _TextOptionGroup.effects:
        return ListView(
          children: <Widget>[
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  ..._colorPalette.map(
                    (color) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => controller.updateSelectedTextStyle(
                          style.copyWith(color: color, clearGradient: true),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ActionChip(
                    label: const Text('Gradient'),
                    onPressed: () => controller.updateSelectedTextStyle(
                      style.copyWith(
                        gradientColors: const <Color>[
                          Color(0xFF8B5CF6),
                          Color(0xFF3B82F6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Shadow'),
                    onPressed: () => controller.updateSelectedTextStyle(
                      style.copyWith(
                        shadow: style.shadow.color == Colors.transparent
                            ? const Shadow(
                                color: Color(0x66000000),
                                blurRadius: 8,
                                offset: Offset(1, 2),
                              )
                            : const Shadow(color: Colors.transparent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Stroke'),
                    onPressed: () => controller.updateSelectedTextStyle(
                      style.copyWith(
                        strokeColor: const Color(0xFFFFFFFF),
                        strokeWidth: style.strokeWidth > 0 ? 0 : 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Highlight'),
                    onPressed: () => controller.updateSelectedTextStyle(
                      style.copyWith(
                        backgroundHighlightColor:
                            style.backgroundHighlightColor == null
                            ? const Color(0x22F59E0B)
                            : null,
                        clearBackgroundHighlight:
                            style.backgroundHighlightColor != null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                SizedBox(
                  width: 180,
                  child: _SliderRow(
                    title: 'Opacity',
                    value: style.opacity,
                    min: 0.1,
                    max: 1,
                    onChanged: (value) => controller.updateSelectedTextStyle(
                      style.copyWith(opacity: value),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: _SliderRow(
                    title: 'Stroke',
                    value: style.strokeWidth,
                    min: 0,
                    max: 8,
                    onChanged: (value) => controller.updateSelectedTextStyle(
                      style.copyWith(
                        strokeColor:
                            style.strokeColor ?? const Color(0xFFFFFFFF),
                        strokeWidth: value,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: _SliderRow(
                    title: 'Curve',
                    value: style.curve,
                    min: -0.45,
                    max: 0.45,
                    onChanged: (value) => controller.updateSelectedTextStyle(
                      style.copyWith(curve: value),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: _SliderRow(
                    title: 'Shadow',
                    value: style.shadow.color == Colors.transparent
                        ? 0
                        : style.shadow.blurRadius.clamp(0.0, 20.0),
                    min: 0,
                    max: 20,
                    onChanged: (value) => controller.updateSelectedTextStyle(
                      style.copyWith(
                        shadow: value <= 0
                            ? const Shadow(color: Colors.transparent)
                            : Shadow(
                                color: style.shadow.color == Colors.transparent
                                    ? const Color(0x66000000)
                                    : style.shadow.color,
                                blurRadius: value,
                                offset: Offset(1, (value / 6).clamp(1, 4)),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case _TextOptionGroup.layer:
        return ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            ActionChip(
              label: const Text('Duplicate'),
              onPressed: controller.duplicateSelectedTextLayer,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: Text(layer.isLocked ? 'Unlock' : 'Lock'),
              onPressed: controller.toggleSelectedTextLock,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('Rotate'),
              onPressed: controller.rotateSelectedTextByQuarterTurn,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('Flip'),
              onPressed: controller.flipSelectedText,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('To Front'),
              onPressed: controller.bringSelectedTextToFront,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('To Back'),
              onPressed: controller.sendSelectedTextToBack,
            ),
          ],
        );
    }
  }

  static const List<Color> _colorPalette = <Color>[
    Color(0xFF111827),
    Color(0xFFFFFFFF),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
  ];
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 42,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
