part of '../image_editor_screen.dart';

// ignore_for_file: unused_element

class _EditorModeBadge extends StatelessWidget {
  const _EditorModeBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey<String>(label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF303236).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: _editorChromeTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorQuickHint extends StatelessWidget {
  const _EditorQuickHint({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      offset: Offset.zero,
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF303236).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xE4DCE8F8)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x070F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF60A5FA), Color(0xFFF472B6)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.tips_and_updates_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.localized(
                  telugu:
                      'సూచన: ఒక లేయర్ ఎంచుకుంటే టూల్స్ యాక్టివ్ అవుతాయి. ఖాళీ క్యాన్వాస్‌పై టాప్ చేస్తే ఎంపిక తొలగుతుంది.',
                  english:
                      'Tip: Select a layer to unlock tool actions. Tap empty canvas to deselect.',
                ),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _editorChromeTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _PressableSurface(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C3FB8).withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: _editorChromeTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorMainToolsStrip extends StatelessWidget {
  const _EditorMainToolsStrip({
    required this.height,
    required this.activeToolLabel,
    required this.onPhotoTap,
    required this.onTextTap,
    required this.onBackgroundTap,
    required this.onEffectsTap,
    required this.onEraserTap,
    required this.onContentAwareTap,
    required this.onRemoveBgTap,
    required this.onFitTap,
    required this.onBrushesTap,
    required this.onFramesTap,
    required this.onReplayTap,
    required this.onCropTap,
    required this.onStickersTap,
    required this.onBorderTap,
    this.vertical = false,
  });

  final double height;
  final bool vertical;
  final String activeToolLabel;
  final VoidCallback onPhotoTap;
  final VoidCallback onTextTap;
  final VoidCallback onBackgroundTap;
  final VoidCallback onEffectsTap;
  final VoidCallback onEraserTap;
  final VoidCallback onContentAwareTap;
  final VoidCallback onRemoveBgTap;
  final VoidCallback onFitTap;
  final VoidCallback onBrushesTap;
  final VoidCallback onFramesTap;
  final VoidCallback onReplayTap;
  final Future<void> Function() onCropTap;
  final VoidCallback onStickersTap;
  final VoidCallback onBorderTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = vertical || MediaQuery.sizeOf(context).width < 370;
    final items = <Widget>[
      _ToolItem(
        label: strings.localized(telugu: 'ఫోటో', english: 'Add Photo'),
        icon: Icons.add_photo_alternate_outlined,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_menu_add_photo_bitmap.webp',
        active: activeToolLabel == 'Photo',
        compact: compact,
        onTap: onPhotoTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'బ్యాక్‌గ్రౌండ్', english: 'BG'),
        icon: Icons.wallpaper_outlined,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_background.png',
        active: activeToolLabel == 'Background',
        compact: compact,
        onTap: onBackgroundTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'క్రాప్', english: 'Crop'),
        icon: Icons.crop_rounded,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_crop_free.png',
        active: activeToolLabel == 'Crop',
        compact: compact,
        onTap: () => unawaited(onCropTap()),
      ),
      _ToolItem(
        label: strings.localized(telugu: 'ఫిట్', english: 'Fit'),
        icon: Icons.fit_screen_rounded,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_menu_fit.png',
        active: activeToolLabel == 'Fit',
        compact: compact,
        onTap: onFitTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'టెక్స్ట్', english: 'Text'),
        icon: Icons.text_fields_rounded,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_text_format.png',
        active: activeToolLabel == 'Text',
        compact: compact,
        onTap: onTextTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'అసెట్స్', english: 'Assets'),
        icon: Icons.emoji_emotions_outlined,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_menu_sticker_bigsize.png',
        active: activeToolLabel == 'Stickers',
        compact: compact,
        premium: true,
        onTap: onStickersTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'బార్డర్', english: 'Border'),
        icon: Icons.border_all_rounded,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_border.png',
        active: activeToolLabel == 'Border',
        compact: compact,
        onTap: onBorderTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'బ్రషెస్', english: 'Brushes'),
        icon: Icons.gesture_rounded,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_dotted_brush.png',
        active: activeToolLabel == 'Brushes',
        compact: compact,
        onTap: onBrushesTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'ఎరేజ్', english: 'Erase'),
        icon: Icons.cleaning_services_outlined,
        active: activeToolLabel == 'Erase',
        compact: compact,
        onTap: onEraserTap,
      ),
      _ToolItem(
        label: 'Content Aware',
        icon: Icons.healing_rounded,
        active: activeToolLabel == 'Content Aware',
        compact: compact,
        onTap: onContentAwareTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'రిమూవ్ BG', english: 'Remove BG'),
        icon: Icons.auto_fix_high_outlined,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_menu_remove_background.png',
        active: activeToolLabel == 'Remove BG',
        compact: compact,
        premium: true,
        onTap: onRemoveBgTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'ఎఫెక్ట్స్', english: 'Effects'),
        icon: Icons.auto_awesome_rounded,
        assetIcon:
            'assets/designpro_reference_full/res/drawable-xxhdpi-v4/widget_icon_effects.webp',
        active: activeToolLabel == 'Effects',
        compact: compact,
        onTap: onEffectsTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'ఫ్రేమ్స్', english: 'Frames'),
        icon: Icons.filter_frames_rounded,
        active: activeToolLabel == 'Frames',
        compact: compact,
        onTap: onFramesTap,
      ),
      _ToolItem(
        label: strings.localized(telugu: 'రీప్లే', english: 'Replay'),
        icon: Icons.play_circle_outline_rounded,
        active: activeToolLabel == 'Replay',
        compact: compact,
        onTap: onReplayTap,
      ),
    ];
    return Container(
      height: vertical ? double.infinity : height,
      width: vertical ? 136 : null,
      padding: vertical
          ? const EdgeInsets.fromLTRB(4, 4, 4, 4)
          : const EdgeInsets.fromLTRB(0, 3, 0, 4),
      decoration: BoxDecoration(
        color: _editorChromeSurfaceStrong.withValues(
          alpha: vertical ? 0.78 : 0.25,
        ),
        image: const DecorationImage(
          image: AssetImage('assets/editor_ui/pattern_1.png'),
          fit: BoxFit.cover,
          opacity: 0.045,
        ),
      ),
      child: ListView.separated(
        scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            vertical ? const SizedBox(height: 3) : const SizedBox(width: 1),
        itemBuilder: (context, index) => SizedBox(
          width: vertical ? double.infinity : (compact ? 61 : 66),
          height: vertical ? 54 : null,
          child: items[index],
        ),
      ),
    );
  }
}

class _EditorSubToolsStrip extends StatelessWidget {
  const _EditorSubToolsStrip({
    required this.height,
    required this.tool,
    required this.onBack,
    required this.onPhotoGalleryTap,
    required this.onPhotoCameraTap,
    required this.onPhotoFileImportTap,
    required this.onPhotoMagicWandTap,
    required this.hasSelectedPhotoLayer,
    required this.onPhotoCropTap,
    required this.onPhotoFitTap,
    required this.onPhotoEraserTap,
    required this.onPhotoContentAwareTap,
    required this.onPhotoAdjustTap,
    required this.onPhotoRemoveBgTap,
    required this.onPhotoStyleTap,
    required this.onPhotoFlipHorizontalTap,
    required this.onPhotoFlipVerticalTap,
    required this.onPhotoMaskTap,
    required this.onPhotoPerspectiveTap,
    required this.onPhotoCloneTap,
    required this.onPhotoStretchTap,
    required this.onPhotoSelectionTap,
    required this.onTextAddTap,
    required this.onTextFontTap,
    required this.onTextSizeTap,
    required this.onTextBackgroundTap,
    required this.onBackgroundTransparentTap,
    required this.onBackgroundColorTap,
    required this.onBackgroundGradientTap,
    required this.onBackgroundImageTap,
    this.vertical = false,
  });

  final double height;
  final bool vertical;
  final _BottomPrimaryTool tool;
  final VoidCallback onBack;
  final Future<void> Function() onPhotoGalleryTap;
  final Future<void> Function() onPhotoCameraTap;
  final Future<void> Function() onPhotoFileImportTap;
  final void Function() onPhotoMagicWandTap;
  final bool hasSelectedPhotoLayer;
  final VoidCallback onPhotoCropTap;
  final VoidCallback onPhotoFitTap;
  final VoidCallback onPhotoEraserTap;
  final VoidCallback onPhotoContentAwareTap;
  final VoidCallback onPhotoAdjustTap;
  final VoidCallback onPhotoRemoveBgTap;
  final VoidCallback onPhotoStyleTap;
  final VoidCallback onPhotoFlipHorizontalTap;
  final VoidCallback onPhotoFlipVerticalTap;
  final VoidCallback onPhotoMaskTap;
  final VoidCallback onPhotoPerspectiveTap;
  final VoidCallback onPhotoCloneTap;
  final VoidCallback onPhotoStretchTap;
  final VoidCallback onPhotoSelectionTap;
  final void Function() onTextAddTap;
  final void Function() onTextFontTap;
  final void Function() onTextSizeTap;
  final void Function() onTextBackgroundTap;
  final void Function() onBackgroundTransparentTap;
  final void Function() onBackgroundColorTap;
  final void Function() onBackgroundGradientTap;
  final Future<void> Function() onBackgroundImageTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = vertical || MediaQuery.sizeOf(context).width < 370;
    final items = switch (tool) {
      _BottomPrimaryTool.photo =>
        hasSelectedPhotoLayer
            ? <Widget>[
                _ToolItem(
                  label: 'Crop',
                  icon: Icons.crop_rounded,
                  compact: compact,
                  onTap: onPhotoCropTap,
                ),
                _ToolItem(
                  label: 'Remove BG',
                  icon: Icons.auto_fix_high_outlined,
                  compact: compact,
                  premium: true,
                  onTap: onPhotoRemoveBgTap,
                ),
                _ToolItem(
                  label: 'Fit',
                  icon: Icons.fit_screen_rounded,
                  compact: compact,
                  onTap: onPhotoFitTap,
                ),
                _ToolItem(
                  label: 'Erase',
                  icon: Icons.cleaning_services_outlined,
                  compact: compact,
                  onTap: onPhotoEraserTap,
                ),
                _ToolItem(
                  label: 'Content',
                  icon: Icons.healing_rounded,
                  compact: compact,
                  onTap: onPhotoContentAwareTap,
                ),
                _ToolItem(
                  label: 'Adjust',
                  icon: Icons.tune_rounded,
                  compact: compact,
                  onTap: onPhotoAdjustTap,
                ),
                _ToolItem(
                  label: 'Style',
                  icon: Icons.opacity_rounded,
                  compact: compact,
                  onTap: onPhotoStyleTap,
                ),
                _ToolItem(
                  label: 'Flip H',
                  icon: Icons.flip_rounded,
                  compact: compact,
                  onTap: onPhotoFlipHorizontalTap,
                ),
                _ToolItem(
                  label: 'Flip V',
                  icon: Icons.flip_rounded,
                  compact: compact,
                  onTap: onPhotoFlipVerticalTap,
                ),
                _ToolItem(
                  label: 'Mask',
                  icon: Icons.crop_square_rounded,
                  compact: compact,
                  onTap: onPhotoMaskTap,
                ),
                _ToolItem(
                  label: 'Perspective',
                  icon: Icons.view_in_ar_outlined,
                  compact: compact,
                  onTap: onPhotoPerspectiveTap,
                ),
                _ToolItem(
                  label: 'Clone',
                  icon: Icons.control_point_duplicate_outlined,
                  compact: compact,
                  onTap: onPhotoCloneTap,
                ),
                _ToolItem(
                  label: 'Smudge',
                  icon: Icons.gesture_rounded,
                  compact: compact,
                  onTap: onPhotoStretchTap,
                ),
                _ToolItem(
                  label: 'Selection',
                  icon: Icons.select_all_rounded,
                  compact: compact,
                  onTap: onPhotoSelectionTap,
                ),
              ]
            : <Widget>[
                _ToolItem(
                  label: strings.localized(
                    telugu: 'గ్యాలరీ',
                    english: 'Gallery',
                  ),
                  icon: Icons.photo_library_outlined,
                  assetIcon:
                      'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_menu_add_photo_bitmap.webp',
                  compact: compact,
                  onTap: () => unawaited(onPhotoGalleryTap()),
                ),
                _ToolItem(
                  label: strings.localized(telugu: 'కెమెరా', english: 'Camera'),
                  icon: Icons.photo_camera_outlined,
                  compact: compact,
                  onTap: () => unawaited(onPhotoCameraTap()),
                ),
                _ToolItem(
                  label: 'PSD',
                  icon: Icons.upload_file_rounded,
                  compact: compact,
                  onTap: () => unawaited(onPhotoFileImportTap()),
                ),
                _ToolItem(
                  label: strings.localized(
                    telugu: 'మ్యాజిక్',
                    english: 'Magic',
                  ),
                  icon: Icons.auto_fix_normal_rounded,
                  assetIcon:
                      'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_effects_ab.png',
                  compact: compact,
                  onTap: onPhotoMagicWandTap,
                ),
              ],
      _BottomPrimaryTool.text => <Widget>[
        _ToolItem(
          label: strings.localized(
            telugu: 'టెక్స్ట్ జోడించు',
            english: 'Add Text',
          ),
          icon: Icons.add_comment_outlined,
          assetIcon:
              'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_text_format.png',
          compact: compact,
          onTap: onTextAddTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'ఫాంట్', english: 'Font'),
          icon: Icons.font_download_rounded,
          assetIcon:
              'assets/designpro_reference_full/res/drawable-xxhdpi-v4/icon_font_style_ab.png',
          compact: compact,
          premium: true,
          onTap: onTextFontTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'సైజ్', english: 'Size'),
          icon: Icons.format_shapes_rounded,
          assetIcon: '',
          compact: compact,
          onTap: onTextSizeTap,
        ),
        _ToolItem(
          label: strings.localized(
            telugu: 'బ్యాక్‌గ్రౌండ్',
            english: 'Background',
          ),
          icon: Icons.branding_watermark_rounded,
          assetIcon: '',
          compact: compact,
          onTap: onTextBackgroundTap,
        ),
      ],
      _BottomPrimaryTool.background => <Widget>[
        _ToolItem(
          label: strings.localized(
            telugu: 'ట్రాన్స్‌పరెంట్',
            english: 'Transparent',
          ),
          icon: Icons.grid_on_rounded,
          compact: compact,
          onTap: onBackgroundTransparentTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'కలర్', english: 'Color'),
          icon: Icons.format_color_fill_rounded,
          assetIcon:
              'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_background.png',
          compact: compact,
          onTap: onBackgroundColorTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'గ్రేడియంట్', english: 'Gradient'),
          icon: Icons.gradient_rounded,
          compact: compact,
          onTap: onBackgroundGradientTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'ఇమేజ్', english: 'Image'),
          icon: Icons.image_outlined,
          compact: compact,
          onTap: () => unawaited(onBackgroundImageTap()),
        ),
      ],
      _BottomPrimaryTool.none => const <Widget>[],
    };

    return Container(
      height: vertical ? double.infinity : height,
      width: vertical ? 136 : null,
      padding: vertical
          ? const EdgeInsets.fromLTRB(4, 4, 4, 4)
          : const EdgeInsets.fromLTRB(0, 4, 0, 5),
      decoration: BoxDecoration(
        color: _editorChromeSurfaceStrong.withValues(
          alpha: vertical ? 0.78 : 0.25,
        ),
        image: const DecorationImage(
          image: AssetImage('assets/editor_ui/pattern_1.png'),
          fit: BoxFit.cover,
          opacity: 0.045,
        ),
      ),
      child: vertical
          ? Column(
              children: <Widget>[
                _EditorIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: strings.localized(
                    telugu: 'వెనక్కి',
                    english: 'Back',
                  ),
                  compact: true,
                  onTap: onBack,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 3),
                    itemBuilder: (BuildContext context, int index) =>
                        SizedBox(height: 54, child: items[index]),
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                _EditorIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: strings.localized(
                    telugu: 'వెనక్కి',
                    english: 'Back',
                  ),
                  compact: compact,
                  onTap: onBack,
                ),
                SizedBox(width: compact ? 1 : 2),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: compact ? 1 : 2),
                    itemBuilder: (BuildContext context, int index) =>
                        SizedBox(width: compact ? 56 : 60, child: items[index]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PhotoEraserInlineStrip extends StatelessWidget {
  const _PhotoEraserInlineStrip({
    required this.height,
    required this.brushSize,
    required this.hardness,
    required this.isBusy,
    required this.onBack,
    required this.onBrushSizeChanged,
    required this.onHardnessChanged,
    this.message,
    this.modeLabel,
    this.hardnessLabel,
    this.opacity,
    this.onOpacityChanged,
    this.onModeToggle,
  });

  final double height;
  final double brushSize;
  final double hardness;
  final bool isBusy;
  final VoidCallback onBack;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onHardnessChanged;
  final String? message;
  final String? modeLabel;
  final String? hardnessLabel;
  final double? opacity;
  final ValueChanged<double>? onOpacityChanged;
  final VoidCallback? onModeToggle;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = MediaQuery.sizeOf(context).width < 370;
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(compact ? 8 : 10, 8, compact ? 8 : 10, 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _EditorIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
                compact: compact,
                onTap: isBusy ? null : onBack,
              ),
              const SizedBox(width: 8),
              Container(
                width: (brushSize / 4).clamp(10, 28).toDouble(),
                height: (brushSize / 4).clamp(10, 28).toDouble(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0),
                  border: Border.all(color: const Color(0xFF60A5FA)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.22),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message ??
                      strings.localized(
                        telugu: 'ఫోటోపై డ్రాగ్ చేస్తే erase అవుతుంది',
                        english: 'Drag on the photo to erase',
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _editorChromeTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                  ),
                ),
              if (modeLabel != null && onModeToggle != null) ...<Widget>[
                const SizedBox(width: 8),
                _PressableSurface(
                  onTap: isBusy ? null : onModeToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.38),
                      ),
                    ),
                    child: Text(
                      modeLabel!,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          _EraserSliderRow(
            label: strings.localized(telugu: 'సైజు', english: 'Size'),
            valueLabel: brushSize.round().toString(),
            value: brushSize,
            min: 8,
            max: 160,
            onChanged: isBusy ? null : onBrushSizeChanged,
          ),
          _EraserSliderRow(
            label: strings.localized(
              telugu: 'హార్డ్‌నెస్',
              english: hardnessLabel ?? 'Hardness',
            ),
            valueLabel: '${(hardness * 100).round()}%',
            value: hardness,
            min: 0,
            max: 1,
            onChanged: isBusy ? null : onHardnessChanged,
          ),
          if (opacity != null && onOpacityChanged != null)
            _EraserSliderRow(
              label: strings.localized(telugu: 'ఒపాసిటీ', english: 'Opacity'),
              valueLabel: '${(opacity!.clamp(0.0, 1.0) * 100).round()}%',
              value: opacity!.clamp(0.0, 1.0).toDouble(),
              min: 0,
              max: 1,
              onChanged: isBusy ? null : onOpacityChanged,
            ),
          if (opacity != null && onOpacityChanged != null)
            _EraserSliderRow(
              label: strings.localized(telugu: 'ఒపాసిటీ', english: 'Opacity'),
              valueLabel: '${(opacity!.clamp(0.0, 1.0) * 100).round()}%',
              value: opacity!.clamp(0.0, 1.0).toDouble(),
              min: 0,
              max: 1,
              onChanged: isBusy ? null : onOpacityChanged,
            ),
        ],
      ),
    );
  }
}

class _EraserSliderRow extends StatelessWidget {
  const _EraserSliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final percentValue = _editorSliderToPercent(value, min, max);
    void handleChanged(double percent) {
      final callback = onChanged;
      if (callback == null) {
        return;
      }
      callback(_editorPercentToSlider(percent, min, max));
    }

    return Row(
      children: <Widget>[
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
              color: _editorChromeTextSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: percentValue,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: const Color(0xFF2563EB),
              inactiveColor: const Color(0xFFCBD5E1),
              onChanged: onChanged == null ? null : handleChanged,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Tooltip(
            message: valueLabel,
            child: Text(
              percentValue.round().toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _editorChromeTextPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoStretchInlineStrip extends StatelessWidget {
  const _PhotoStretchInlineStrip({
    required this.height,
    required this.brushSize,
    required this.strength,
    required this.opacity,
    required this.isBusy,
    required this.onBack,
    required this.onBrushSizeChanged,
    required this.onStrengthChanged,
    required this.onOpacityChanged,
  });

  final double height;
  final double brushSize;
  final double strength;
  final double opacity;
  final bool isBusy;
  final VoidCallback onBack;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onStrengthChanged;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = MediaQuery.sizeOf(context).width < 370;
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(compact ? 8 : 10, 8, compact ? 8 : 10, 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _EditorIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
                compact: compact,
                onTap: isBusy ? null : onBack,
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDBEAFE).withValues(alpha: 0.78),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.localized(
                    telugu: 'ఫోటో మీద drag చేస్తే stretch అవుతుంది',
                    english: 'Drag on the photo to smudge pixels',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _editorChromeTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _EraserSliderRow(
            label: strings.localized(
              telugu: 'బ్రష్ సైజ్',
              english: 'Brush Size',
            ),
            valueLabel: brushSize.round().toString(),
            value: brushSize,
            min: 4,
            max: 180,
            onChanged: isBusy ? null : onBrushSizeChanged,
          ),
          _EraserSliderRow(
            label: strings.localized(telugu: 'బలం', english: 'Strength'),
            valueLabel: '${(strength * 100).round()}%',
            value: strength,
            min: 0.1,
            max: 1,
            onChanged: isBusy ? null : onStrengthChanged,
          ),
          _EraserSliderRow(
            label: 'Opacity',
            valueLabel: '${(opacity * 100).round()}%',
            value: opacity,
            min: 0,
            max: 1,
            onChanged: isBusy ? null : onOpacityChanged,
          ),
        ],
      ),
    );
  }
}

class _LayersInlineStrip extends StatelessWidget {
  const _LayersInlineStrip({
    required this.height,
    required this.layers,
    required this.selectedLayerId,
    required this.onBack,
    required this.onSelectLayer,
    required this.onMoveToFront,
    required this.onMoveToBack,
    required this.onMoveForward,
    required this.onMoveBackward,
    required this.onDeleteSelected,
  });

  final double height;
  final List<_CanvasLayer> layers;
  final String? selectedLayerId;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectLayer;
  final VoidCallback onMoveToFront;
  final VoidCallback onMoveToBack;
  final VoidCallback onMoveForward;
  final VoidCallback onMoveBackward;
  final VoidCallback onDeleteSelected;

  String _layerTypeLabel(_CanvasLayer layer) {
    if (layer.isPhoto) {
      return 'Photo';
    }
    if (layer.isText) {
      return 'Text';
    }
    return 'Sticker';
  }

  Widget _layerPreview(_CanvasLayer layer) {
    if (layer.isPhoto && layer.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.memory(
          layer.bytes!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          cacheWidth: 72,
          gaplessPlayback: true,
        ),
      );
    }
    if (layer.isText) {
      return const Icon(
        Icons.text_fields_rounded,
        size: 14,
        color: Color(0xFFE2E8F0),
      );
    }
    return Center(
      child: _EditorTextState._buildStickerVisual(
        layer.sticker,
        fontSize: 14,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        color: _EditorTextState._isImageLikeSticker(layer.sticker)
            ? null
            : layer.stickerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final strings = context.strings;
    final orderedLayers = layers.reversed.toList(growable: false);
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      decoration: BoxDecoration(
        color: _editorChromeSurfaceStrong.withValues(alpha: 0.25),
        image: const DecorationImage(
          image: AssetImage('assets/editor_ui/pattern_1.png'),
          fit: BoxFit.cover,
          opacity: 0.045,
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _EditorIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
                compact: compact,
                onTap: onBack,
              ),
              const SizedBox(width: 4),
              _EditorIconButton(
                icon: Icons.vertical_align_top_rounded,
                assetIcon:
                    'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_layer_move_up.png',
                tooltip: strings.localized(
                  telugu: 'ముందుకు తీసుకురా',
                  english: 'Move to front',
                ),
                compact: true,
                onTap: selectedLayerId == null ? null : onMoveToFront,
              ),
              _EditorIconButton(
                icon: Icons.vertical_align_bottom_rounded,
                assetIcon:
                    'assets/designpro_reference_full/res/drawable-xxhdpi-v4/ic_layer_move_down.png',
                tooltip: strings.localized(
                  telugu: 'వెనక్కి పంపు',
                  english: 'Move to back',
                ),
                compact: true,
                onTap: selectedLayerId == null ? null : onMoveToBack,
              ),
              _EditorIconButton(
                icon: Icons.arrow_downward_rounded,
                tooltip: strings.localized(
                  telugu: 'ఒక మెట్టు వెనక్కి',
                  english: 'Move backward',
                ),
                compact: true,
                onTap: selectedLayerId == null ? null : onMoveBackward,
              ),
              _EditorIconButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: strings.localized(
                  telugu: 'ఒక మెట్టు ముందుకు',
                  english: 'Move forward',
                ),
                compact: true,
                onTap: selectedLayerId == null ? null : onMoveForward,
              ),
              _EditorIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: strings.localized(
                  telugu: 'లేయర్ డిలీట్ చేయి',
                  english: 'Delete layer',
                ),
                compact: true,
                onTap: selectedLayerId == null ? null : onDeleteSelected,
              ),
              const Spacer(),
              Text(
                strings.localized(telugu: 'లేయర్లు', english: 'Layers'),
                style: TextStyle(
                  color: _editorChromeTextPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: orderedLayers.length,
              separatorBuilder: (_, _) => SizedBox(width: compact ? 4 : 6),
              itemBuilder: (BuildContext context, int index) {
                final layer = orderedLayers[index];
                final selected = layer.id == selectedLayerId;
                return _PressableSurface(
                  onTap: () => onSelectLayer(layer.id),
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: compact ? 82 : 92,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: compact ? 26 : 30,
                          height: compact ? 26 : 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18191D),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : _editorChromeBorder,
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: _layerPreview(layer),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _layerTypeLabel(layer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 9.8 : 10.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : _editorChromeTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: selected ? 16 : 8,
                          height: 2,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFF2FB3)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
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
      ),
    );
  }
}

class _StickerCategoryStrip extends StatelessWidget {
  const _StickerCategoryStrip({
    required this.height,
    required this.categories,
    required this.onBack,
    required this.onCategoryTap,
  });

  final double height;
  final List<String> categories;
  final VoidCallback onBack;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final strings = context.strings;
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 8),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: <Widget>[
          _EditorIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
            compact: compact,
            onTap: onBack,
          ),
          SizedBox(width: compact ? 2 : 4),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => SizedBox(width: compact ? 4 : 6),
              itemBuilder: (BuildContext context, int index) {
                final label = categories[index];
                return _InlineActionChip(
                  label: label,
                  active: false,
                  compact: compact,
                  onTap: () => onCategoryTap(label),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerItemsStrip extends StatelessWidget {
  const _StickerItemsStrip({
    required this.height,
    required this.category,
    required this.stickers,
    required this.onBack,
    required this.onStickerTap,
  });

  final double height;
  final String category;
  final List<String> stickers;
  final VoidCallback onBack;
  final ValueChanged<String> onStickerTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final strings = context.strings;
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 8),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _EditorIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
                compact: compact,
                onTap: onBack,
              ),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  color: _editorChromeTextPrimary,
                  fontSize: compact ? 10.5 : 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stickers.length,
              separatorBuilder: (_, _) => SizedBox(width: compact ? 4 : 6),
              itemBuilder: (BuildContext context, int index) {
                final sticker = stickers[index];
                final imageLike = _EditorTextState._isImageLikeSticker(sticker);
                return _PressableSurface(
                  onTap: () => onStickerTap(sticker),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: compact ? 52 : 58,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C3FB8).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _editorChromeBorder),
                    ),
                    child: Center(
                      child: imageLike
                          ? _EditorTextState._buildStickerVisual(
                              sticker,
                              fontSize: compact ? 24 : 28,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            )
                          : Text(
                              sticker,
                              style: TextStyle(
                                fontSize: compact ? 22 : 26,
                                height: 1,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BorderInlineStrip extends StatelessWidget {
  const _BorderInlineStrip({
    required this.height,
    required this.borderWidth,
    required this.borderRadius,
    required this.onBack,
    required this.onWidthChangeStart,
    required this.onWidthChanged,
    required this.onWidthChangeEnd,
    required this.onRadiusChangeStart,
    required this.onRadiusChanged,
    required this.onRadiusChangeEnd,
  });

  final double height;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback onBack;
  final ValueChanged<double> onWidthChangeStart;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onWidthChangeEnd;
  final ValueChanged<double> onRadiusChangeStart;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onRadiusChangeEnd;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final strings = context.strings;
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 8),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: <Widget>[
          _EditorIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
            compact: compact,
            onTap: onBack,
          ),
          SizedBox(width: compact ? 2 : 4),
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: _InlineSliderControl(
                    label: strings.localized(telugu: 'సైజ్', english: 'Size'),
                    valueLabel: borderWidth.toStringAsFixed(1),
                    value: borderWidth.clamp(0.5, 100).toDouble(),
                    min: 0.5,
                    max: 100,
                    divisions: 100,
                    onChangeStart: onWidthChangeStart,
                    onChanged: onWidthChanged,
                    onChangeEnd: onWidthChangeEnd,
                  ),
                ),
                Expanded(
                  child: _InlineSliderControl(
                    label: strings.localized(
                      telugu: 'రేడియస్',
                      english: 'Radius',
                    ),
                    valueLabel: borderRadius.toStringAsFixed(0),
                    value: borderRadius.clamp(0, 100).toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChangeStart: onRadiusChangeStart,
                    onChanged: onRadiusChanged,
                    onChangeEnd: onRadiusChangeEnd,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineActionChip extends StatelessWidget {
  const _InlineActionChip({
    required this.label,
    required this.onTap,
    this.active = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: compact ? 84 : 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 10 : 10.8,
                fontWeight: FontWeight.w700,
                color: !enabled
                    ? const Color(0xFF64748B)
                    : active
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: active ? 18 : 8,
              height: 2,
              decoration: BoxDecoration(
                color: !enabled
                    ? Colors.white.withValues(alpha: 0.12)
                    : active
                    ? const Color(0xFF8B5CF6)
                    : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSliderControl extends StatelessWidget {
  const _InlineSliderControl({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
    this.divisions,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final percentValue = _editorSliderToPercent(value, min, max);
    final percentLabel = percentValue.round().toString();
    void handleChangeStart(double percent) {
      onChangeStart(_editorPercentToSlider(percent, min, max));
    }

    void handleChanged(double percent) {
      onChanged(_editorPercentToSlider(percent, min, max));
    }

    void handleChangeEnd(double percent) {
      onChangeEnd(_editorPercentToSlider(percent, min, max));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 94,
            child: Tooltip(
              message: valueLabel,
              child: Text(
                '$label\n$percentLabel',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: const Color(0xFF60A5FA),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                thumbColor: const Color(0xFFF8FAFC),
                overlayColor: const Color(0x3360A5FA),
              ),
              child: Slider(
                value: percentValue,
                min: 0,
                max: 100,
                divisions: divisions == null ? 100 : 100,
                onChangeStart: handleChangeStart,
                onChanged: handleChanged,
                onChangeEnd: handleChangeEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
