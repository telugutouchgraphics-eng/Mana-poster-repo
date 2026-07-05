part of '../image_editor_screen.dart';

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.height,
    required this.onUndoTap,
    required this.onRedoTap,
    required this.onDraftsTap,
    required this.onShareTap,
    required this.onDownloadTap,
    required this.onExportTap,
    required this.onDeleteTap,
    required this.onDuplicateTap,
    required this.onBringFrontTap,
    required this.onSendBackTap,
    required this.onLayersTap,
    required this.onUniversalLayerStyleTap,
    required this.autoSelectCanvasLayer,
    required this.onAutoSelectCanvasLayerTap,
    required this.selectionHandlesVisible,
    required this.onSelectLayerTap,
    required this.onShowMainToolsTap,
    required this.onAlignHorizontalCenterTap,
    required this.onAlignVerticalCenterTap,
    required this.canUndo,
    required this.canRedo,
    required this.isSharing,
    required this.isExporting,
    required this.canDelete,
    required this.canDuplicate,
    required this.canBringFront,
    required this.canSendBack,
    required this.canAlignSelectedLayer,
    required this.hasSelectedTextLayer,
    required this.hasSelectedPhotoLayer,
    required this.hasSelectedStickerLayer,
    required this.isBorderToolActive,
    required this.activeBorderStyle,
    required this.activeBorderColor,
    required this.activeTextToolTab,
    required this.activeMainToolLabel,
    required this.selectedLayer,
    required this.savedEffectPresets,
    required this.copiedTextEffect,
    required this.onTextEditTap,
    required this.onTextStyleTap,
    required this.onTextFontTap,
    required this.onTextColorTap,
    required this.onTextEffectsTap,
    required this.onTextAlignLeftTap,
    required this.onTextAlignCenterTap,
    required this.onTextAlignRightTap,
    required this.onEffectPresetSelected,
    required this.onCopyTextEffect,
    required this.onPasteTextEffect,
    required this.onSaveTextEffectPreset,
    required this.onSavedTextEffectPresetSelected,
    required this.onPhotoCropTap,
    required this.onPhotoFitTap,
    required this.onPhotoEraserTap,
    required this.onPhotoContentAwareTap,
    required this.onPhotoAdjustTap,
    required this.onPhotoRetouchTap,
    required this.onPhotoRemoveBgTap,
    required this.onPhotoStyleTap,
    required this.onPhotoFlipHorizontalTap,
    required this.onPhotoFlipVerticalTap,
    required this.onPhotoMaskTap,
    required this.onPhotoPerspectiveTap,
    required this.onPhotoCloneTap,
    required this.onPhotoStretchTap,
    required this.onPhotoSelectionTap,
    required this.onSelectedRotate90Tap,
    required this.onStickerColorTap,
    required this.onFrameColorTap,
    required this.onBorderColorTap,
    required this.onBorderRemoveTap,
    this.vertical = false,
  });

  final double height;
  final VoidCallback onUndoTap;
  final VoidCallback onRedoTap;
  final VoidCallback onDraftsTap;
  final VoidCallback onShareTap;
  final VoidCallback onDownloadTap;
  final VoidCallback onExportTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onDuplicateTap;
  final VoidCallback onBringFrontTap;
  final VoidCallback onSendBackTap;
  final VoidCallback onLayersTap;
  final VoidCallback onUniversalLayerStyleTap;
  final bool autoSelectCanvasLayer;
  final VoidCallback onAutoSelectCanvasLayerTap;
  final bool selectionHandlesVisible;
  final VoidCallback onSelectLayerTap;
  final VoidCallback onShowMainToolsTap;
  final VoidCallback onAlignHorizontalCenterTap;
  final VoidCallback onAlignVerticalCenterTap;
  final bool canUndo;
  final bool canRedo;
  final bool isSharing;
  final bool isExporting;
  final bool canDelete;
  final bool canDuplicate;
  final bool canBringFront;
  final bool canSendBack;
  final bool canAlignSelectedLayer;
  final bool hasSelectedTextLayer;
  final bool hasSelectedPhotoLayer;
  final bool hasSelectedStickerLayer;
  final bool isBorderToolActive;
  final _BorderStyle activeBorderStyle;
  final Color activeBorderColor;
  final _TextToolTab activeTextToolTab;
  final String activeMainToolLabel;
  final _CanvasLayer? selectedLayer;
  final List<_TextEffectSnapshot> savedEffectPresets;
  final _TextEffectSnapshot? copiedTextEffect;
  final VoidCallback onTextEditTap;
  final VoidCallback onTextStyleTap;
  final VoidCallback onTextFontTap;
  final VoidCallback onTextColorTap;
  final VoidCallback onTextEffectsTap;
  final VoidCallback onTextAlignLeftTap;
  final VoidCallback onTextAlignCenterTap;
  final VoidCallback onTextAlignRightTap;
  final ValueChanged<_TextEffectPreset> onEffectPresetSelected;
  final VoidCallback onCopyTextEffect;
  final VoidCallback onPasteTextEffect;
  final VoidCallback onSaveTextEffectPreset;
  final ValueChanged<_TextEffectSnapshot> onSavedTextEffectPresetSelected;
  final VoidCallback onPhotoCropTap;
  final VoidCallback onPhotoFitTap;
  final VoidCallback onPhotoEraserTap;
  final VoidCallback onPhotoContentAwareTap;
  final VoidCallback onPhotoAdjustTap;
  final VoidCallback onPhotoRetouchTap;
  final VoidCallback onPhotoRemoveBgTap;
  final VoidCallback onPhotoStyleTap;
  final VoidCallback onPhotoFlipHorizontalTap;
  final VoidCallback onPhotoFlipVerticalTap;
  final VoidCallback onPhotoMaskTap;
  final VoidCallback onPhotoPerspectiveTap;
  final VoidCallback onPhotoCloneTap;
  final VoidCallback onPhotoStretchTap;
  final VoidCallback onPhotoSelectionTap;
  final VoidCallback onSelectedRotate90Tap;
  final VoidCallback onStickerColorTap;
  final VoidCallback onFrameColorTap;
  final VoidCallback onBorderColorTap;
  final VoidCallback onBorderRemoveTap;
  final bool vertical;

  VoidCallback? _withHaptic(VoidCallback? callback) {
    if (callback == null) {
      return null;
    }
    return () {
      HapticFeedback.selectionClick();
      callback();
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = vertical || MediaQuery.sizeOf(context).width < 400;
    final activeTool = activeMainToolLabel;
    final showTextToolContext = hasSelectedTextLayer;
    final showPhotoToolContext = hasSelectedPhotoLayer;
    final showFrameToolContext =
        hasSelectedPhotoLayer &&
        (selectedLayer?.photoFramePreset.trim().isNotEmpty ?? false);
    final showStickerToolContext = hasSelectedStickerLayer;
    final showLayerActionTools =
        showTextToolContext || showPhotoToolContext || showStickerToolContext;
    final contextTools = <Widget>[
      if (isBorderToolActive) ...[
        _TopContextChip(
          icon: Icons.palette_outlined,
          label: 'Color',
          selected: activeBorderStyle != _BorderStyle.none,
          color: activeBorderColor,
          onTap: _withHaptic(onBorderColorTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.remove_circle_outline_rounded,
          label: 'Remove',
          selected: activeBorderStyle == _BorderStyle.none,
          onTap: _withHaptic(onBorderRemoveTap),
          vertical: vertical,
        ),
      ] else if (showTextToolContext) ...[
        _TopContextChip(
          icon: Icons.edit_rounded,
          label: 'Edit',
          onTap: _withHaptic(onTextEditTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.tune_rounded,
          label: 'Style',
          onTap: _withHaptic(onTextStyleTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.font_download_rounded,
          label: 'Fonts',
          onTap: _withHaptic(onTextFontTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.palette_outlined,
          label: 'Color',
          onTap: _withHaptic(onTextColorTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.auto_awesome_rounded,
          label: 'Effects',
          onTap: _withHaptic(onTextEffectsTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.format_align_left_rounded,
          label: 'Left',
          onTap: _withHaptic(onTextAlignLeftTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.format_align_center_rounded,
          label: 'Center',
          onTap: _withHaptic(onTextAlignCenterTap),
          vertical: vertical,
        ),
        _TopContextChip(
          icon: Icons.format_align_right_rounded,
          label: 'Right',
          onTap: _withHaptic(onTextAlignRightTap),
          vertical: vertical,
        ),
      ],
      if (showPhotoToolContext) ...[
        _TopContextChip(
          icon: Icons.crop_rounded,
          label: 'Crop',
          selected: activeTool == 'Crop',
          onTap: _withHaptic(onPhotoCropTap),
        ),
        _TopContextChip(
          icon: Icons.fit_screen_rounded,
          label: 'Fit',
          selected: activeTool == 'Fit',
          onTap: _withHaptic(onPhotoFitTap),
        ),
        _TopContextChip(
          icon: Icons.cleaning_services_outlined,
          label: 'Erase',
          selected: activeTool == 'Erase',
          onTap: _withHaptic(onPhotoEraserTap),
        ),
        _TopContextChip(
          icon: Icons.healing_rounded,
          label: 'Content',
          selected: activeTool == 'Content Aware',
          onTap: _withHaptic(onPhotoContentAwareTap),
        ),
        _TopContextChip(
          icon: Icons.tune_rounded,
          label: 'Adjust',
          selected: activeTool == 'Effects',
          onTap: _withHaptic(onPhotoAdjustTap),
        ),
        _TopContextChip(
          icon: Icons.face_retouching_natural_rounded,
          label: 'Retouch',
          selected: activeTool == 'Retouch',
          onTap: _withHaptic(onPhotoRetouchTap),
        ),
        _TopContextChip(
          icon: Icons.auto_fix_high_outlined,
          label: 'Remove BG',
          selected: activeTool == 'Remove BG',
          onTap: _withHaptic(onPhotoRemoveBgTap),
        ),
        _TopContextChip(
          icon: Icons.opacity_rounded,
          label: 'Style',
          selected:
              (selectedLayer?.photoOpacity ?? 1) < 0.999 ||
              (selectedLayer?.photoShadowOpacity ?? 0) > 0.001,
          onTap: _withHaptic(onPhotoStyleTap),
        ),
        _TopContextChip(
          icon: Icons.flip_rounded,
          label: 'Flip H',
          selected: selectedLayer?.flipPhotoHorizontally ?? false,
          onTap: _withHaptic(onPhotoFlipHorizontalTap),
        ),
        _TopContextChip(
          icon: Icons.flip_rounded,
          label: 'Flip V',
          selected: selectedLayer?.flipPhotoVertically ?? false,
          onTap: _withHaptic(onPhotoFlipVerticalTap),
        ),
        _TopContextChip(
          icon: Icons.crop_square_rounded,
          label: 'Mask',
          selected: selectedLayer?.photoMaskShape.trim().isNotEmpty ?? false,
          onTap: _withHaptic(onPhotoMaskTap),
        ),
        _TopContextChip(
          icon: Icons.view_in_ar_outlined,
          label: 'Perspective',
          selected:
              (selectedLayer?.photoPerspectiveX ?? 0).abs() > 0.01 ||
              (selectedLayer?.photoPerspectiveY ?? 0).abs() > 0.01,
          onTap: _withHaptic(onPhotoPerspectiveTap),
        ),
        _TopContextChip(
          icon: Icons.control_point_duplicate_outlined,
          label: 'Clone',
          onTap: _withHaptic(onPhotoCloneTap),
        ),
        _TopContextChip(
          icon: Icons.gesture_rounded,
          label: 'Smudge',
          selected: activeTool == 'Smudge',
          onTap: _withHaptic(onPhotoStretchTap),
        ),
        _TopContextChip(
          icon: Icons.select_all_rounded,
          label: 'Selection',
          onTap: _withHaptic(onPhotoSelectionTap),
        ),
      ],
      if (showLayerActionTools) ...[
        _TopContextChip(
          icon: Icons.auto_awesome_rounded,
          label: 'Style',
          onTap: _withHaptic(onUniversalLayerStyleTap),
        ),
        _TopContextChip(
          icon: Icons.rotate_90_degrees_ccw_rounded,
          label: 'Rotate',
          onTap: _withHaptic(onSelectedRotate90Tap),
        ),
      ],
      if (showStickerToolContext && selectedLayer != null) ...[
        _TopContextChip(
          icon: Icons.palette_outlined,
          label: 'Color',
          color: selectedLayer!.stickerColor,
          onTap: _withHaptic(onStickerColorTap),
        ),
      ],
      if (showFrameToolContext && selectedLayer != null) ...[
        _TopContextChip(
          icon: Icons.palette_outlined,
          label: 'Color',
          color: selectedLayer!.photoFrameColor,
          onTap: _withHaptic(onFrameColorTap),
        ),
      ],
      if (showLayerActionTools) ...[
        _TopContextDivider(),
        _TopContextChip(
          icon: Icons.align_horizontal_center_rounded,
          label: 'Align H',
          onTap: _withHaptic(
            canAlignSelectedLayer ? onAlignHorizontalCenterTap : null,
          ),
        ),
        _TopContextChip(
          icon: Icons.align_vertical_center_rounded,
          label: 'Align V',
          onTap: _withHaptic(
            canAlignSelectedLayer ? onAlignVerticalCenterTap : null,
          ),
        ),
        _TopContextChip(
          icon: Icons.flip_to_front_rounded,
          label: 'Front',
          onTap: _withHaptic(canBringFront ? onBringFrontTap : null),
        ),
        _TopContextChip(
          icon: Icons.flip_to_back_rounded,
          label: 'Back',
          onTap: _withHaptic(canSendBack ? onSendBackTap : null),
        ),
        _TopContextChip(
          icon: Icons.drag_handle_rounded,
          label: 'Tools',
          onTap: _withHaptic(onShowMainToolsTap),
        ),
        _TopContextChip(
          icon: Icons.control_point_duplicate_rounded,
          label: 'Duplicate',
          onTap: _withHaptic(canDuplicate ? onDuplicateTap : null),
        ),
        _TopContextChip(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          onTap: _withHaptic(canDelete ? onDeleteTap : null),
        ),
      ],
    ];
    final showContextTools = contextTools.isNotEmpty;
    if (vertical) {
      return _EditorGlassSurface(
        borderRadius: BorderRadius.circular(18),
        surfaceColor: _editorChromeSurfaceStrong.withValues(alpha: 0.78),
        child: SizedBox(
          width: 78,
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
            child: Column(
              children: <Widget>[
                _EditorIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: strings.localized(
                    telugu: 'Ã Â°ÂµÃ Â±â€ Ã Â°Â¨Ã Â°â€¢Ã Â±ÂÃ Â°â€¢Ã Â°Â¿',
                    english: 'Back',
                  ),
                  compact: true,
                  onTap: _withHaptic(() => Navigator.of(context).maybePop()),
                ),
                _EditorIconButton(
                  icon: Icons.undo_rounded,
                  tooltip: strings.localized(
                    telugu: 'Ã Â°â€¦Ã Â°â€šÃ Â°Â¡Ã Â±Â',
                    english: 'Undo',
                  ),
                  compact: true,
                  onTap: _withHaptic(canUndo ? onUndoTap : null),
                ),
                _EditorIconButton(
                  icon: Icons.redo_rounded,
                  tooltip: strings.localized(
                    telugu: 'Ã Â°Â°Ã Â±â‚¬Ã Â°Â¡Ã Â±â€¹',
                    english: 'Redo',
                  ),
                  compact: true,
                  onTap: _withHaptic(canRedo ? onRedoTap : null),
                ),
                _EditorIconButton(
                  icon: isExporting
                      ? Icons.hourglass_top_rounded
                      : Icons.download_rounded,
                  tooltip: isExporting ? 'Downloading' : 'Download',
                  compact: true,
                  onTap: isExporting ? null : onDownloadTap,
                ),
                _EditorIconButton(
                  icon: Icons.file_upload_outlined,
                  tooltip: 'Export',
                  compact: true,
                  onTap: isExporting ? null : onExportTap,
                ),
                _EditorIconButton(
                  icon: Icons.layers_rounded,
                  assetIcon:
                      'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_layer.png',
                  tooltip: 'Layers',
                  compact: true,
                  onTap: _withHaptic(onLayersTap),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                _EditorIconButton(
                  icon: autoSelectCanvasLayer
                      ? Icons.touch_app_rounded
                      : Icons.pan_tool_alt_outlined,
                  tooltip: autoSelectCanvasLayer
                      ? 'Auto Select On'
                      : 'Auto Select Off',
                  compact: true,
                  onTap: _withHaptic(onAutoSelectCanvasLayerTap),
                ),
                if (selectedLayer != null)
                  _EditorIconButton(
                    icon: Icons.select_all_rounded,
                    tooltip: selectionHandlesVisible ? 'Deselect' : 'Select',
                    compact: true,
                    onTap: _withHaptic(onSelectLayerTap),
                  ),
                Expanded(
                  child: showContextTools
                      ? ListView.separated(
                          scrollDirection: Axis.vertical,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: contextTools.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (_, index) => contextTools[index],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _EditorGlassSurface(
      borderRadius: BorderRadius.circular(22),
      surfaceColor: _editorChromeSurfaceStrong.withValues(alpha: 0.25),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 44,
                child: Row(
                  children: <Widget>[
                    _EditorIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: strings.localized(
                        telugu: 'à°µà±†à°¨à°•à±à°•à°¿',
                        english: 'Back',
                      ),
                      onTap: _withHaptic(
                        () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const Spacer(),
                    ...[
                      _EditorIconButton(
                        icon: Icons.undo_rounded,
                        tooltip: strings.localized(
                          telugu: 'à°…à°‚à°¡à±',
                          english: 'Undo',
                        ),
                        onTap: _withHaptic(canUndo ? onUndoTap : null),
                      ),
                      _EditorIconButton(
                        icon: Icons.redo_rounded,
                        tooltip: strings.localized(
                          telugu: 'à°°à±€à°¡à±‹',
                          english: 'Redo',
                        ),
                        onTap: _withHaptic(canRedo ? onRedoTap : null),
                      ),
                      const SizedBox(width: 4),
                      if (compact)
                        _EditorIconButton(
                          icon: isExporting
                              ? Icons.hourglass_top_rounded
                              : Icons.download_rounded,
                          tooltip: strings.localized(
                            telugu: isExporting
                                ? 'à°¸à±‡à°µà± à°…à°µà±à°¤à±‹à°‚à°¦à°¿'
                                : 'à°¸à±‡à°µà±',
                            english: isExporting ? 'Downloading' : 'Download',
                          ),
                          onTap: isExporting ? null : onDownloadTap,
                        )
                      else
                        _TopPrimaryPillButton(
                          label: strings.localized(
                            telugu: isExporting
                                ? 'à°¸à±‡à°µà±...'
                                : 'à°¸à±‡à°µà±',
                            english: isExporting
                                ? 'Downloading...'
                                : 'Download',
                          ),
                          onTap: isExporting ? null : onDownloadTap,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          borderColor: Colors.white,
                          icon: isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.download_rounded,
                                  size: 17,
                                  color: Colors.black,
                                ),
                        ),
                      if (!compact) ...<Widget>[
                        const SizedBox(width: 6),
                        _TopPrimaryPillButton(
                          label: 'Export',
                          onTap: isExporting ? null : onExportTap,
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          borderColor: const Color(0xFF38BDF8),
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            size: 17,
                            color: Colors.black,
                          ),
                        ),
                      ] else
                        _EditorIconButton(
                          icon: Icons.file_upload_outlined,
                          tooltip: 'Export',
                          onTap: isExporting ? null : onExportTap,
                        ),
                      PopupMenuButton<String>(
                        tooltip: strings.localized(
                          telugu: 'à°®à°°à°¿à°¨à±à°¨à°¿',
                          english: 'More',
                        ),
                        color: const Color(0xFF303236),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: _editorChromeTextPrimary,
                        ),
                        onSelected: (value) {
                          HapticFeedback.selectionClick();
                          if (value == 'share') onShareTap();
                          if (value == 'drafts') onDraftsTap();
                        },
                        itemBuilder: (_) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'share',
                            enabled: !isSharing,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.share_rounded,
                                color: _editorChromeTextPrimary,
                              ),
                              title: Text(
                                isSharing ? 'Sharing...' : 'Share',
                                style: const TextStyle(
                                  color: _editorChromeTextPrimary,
                                ),
                              ),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'drafts',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.folder_copy_outlined,
                                color: _editorChromeTextPrimary,
                              ),
                              title: Text(
                                'Drafts',
                                style: TextStyle(
                                  color: _editorChromeTextPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    _EditorIconButton(
                      icon: Icons.layers_rounded,
                      assetIcon:
                          'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_layer.png',
                      tooltip: strings.localized(
                        telugu: 'à°²à±‡à°¯à°°à±à°¸à±',
                        english: 'Layers',
                      ),
                      onTap: _withHaptic(onLayersTap),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.white.withValues(alpha: 0.12),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    _EditorIconButton(
                      icon: autoSelectCanvasLayer
                          ? Icons.touch_app_rounded
                          : Icons.pan_tool_alt_outlined,
                      tooltip: autoSelectCanvasLayer
                          ? 'Auto Select On'
                          : 'Auto Select Off',
                      onTap: _withHaptic(onAutoSelectCanvasLayerTap),
                    ),
                    if (selectedLayer != null)
                      _EditorIconButton(
                        icon: Icons.select_all_rounded,
                        tooltip: selectionHandlesVisible
                            ? 'Deselect'
                            : 'Select',
                        onTap: _withHaptic(onSelectLayerTap),
                      ),
                    Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.only(right: 4),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    Expanded(
                      child: showContextTools
                          ? ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              itemCount: contextTools.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (_, index) => contextTools[index],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorGlassSurface extends StatelessWidget {
  const _EditorGlassSurface({
    required this.child,
    required this.borderRadius,
    this.surfaceColor,
    this.showBorder = true,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final BorderRadius borderRadius;
  final Color? surfaceColor;
  final bool showBorder;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            surfaceColor ?? _editorChromeSurfaceStrong.withValues(alpha: 0.25),
        borderRadius: borderRadius,
        border: showBorder ? Border.all(color: _editorChromeBorder) : null,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TopContextDivider extends StatelessWidget {
  const _TopContextDivider();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1,
        height: 24,
        color: Colors.white.withValues(alpha: 0.14),
      ),
    );
  }
}

class _TopContextChip extends StatelessWidget {
  const _TopContextChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
    this.vertical = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactVertical =
            !vertical &&
            constraints.maxWidth.isFinite &&
            constraints.maxWidth < 96;
        return _PressableSurface(
          onTap: onTap,
          enabled: enabled,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: useCompactVertical ? 58 : 42,
            width: vertical || useCompactVertical ? double.infinity : null,
            padding: useCompactVertical
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 5)
                : EdgeInsets.symmetric(horizontal: vertical ? 10 : 12),
            decoration: BoxDecoration(
              color: enabled
                  ? selected
                        ? const Color(0xFF6D5DFB).withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFFC4B5FD)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: useCompactVertical
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        icon,
                        size: 18,
                        color: enabled
                            ? selected
                                  ? const Color(0xFFF5F3FF)
                                  : _editorChromeTextPrimary
                            : _editorChromeTextSecondary.withValues(alpha: 0.5),
                      ),
                      if (color != null) ...[
                        const SizedBox(height: 3),
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70, width: 1),
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: enabled
                              ? selected
                                    ? const Color(0xFFF5F3FF)
                                    : _editorChromeTextPrimary
                              : _editorChromeTextSecondary.withValues(
                                  alpha: 0.5,
                                ),
                          fontSize: 9.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: vertical
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        icon,
                        size: 18,
                        color: enabled
                            ? selected
                                  ? const Color(0xFFF5F3FF)
                                  : _editorChromeTextPrimary
                            : _editorChromeTextSecondary.withValues(alpha: 0.5),
                      ),
                      if (color != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70, width: 1),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: enabled
                                ? selected
                                      ? const Color(0xFFF5F3FF)
                                      : _editorChromeTextPrimary
                                : _editorChromeTextSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                            fontSize: 11.6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _TopPrimaryPillButton extends StatelessWidget {
  const _TopPrimaryPillButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      enabled: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
