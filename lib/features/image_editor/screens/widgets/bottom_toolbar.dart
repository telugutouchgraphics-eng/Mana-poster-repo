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
          color: Colors.white.withValues(alpha: 0.84),
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
                color: Color(0xFF334155),
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
          color: Colors.white.withValues(alpha: 0.9),
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
                  color: Color(0xFF475569),
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFF64748B),
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
    required this.onToolsTap,
  });

  final double height;
  final String activeToolLabel;
  final VoidCallback onPhotoTap;
  final VoidCallback onTextTap;
  final VoidCallback onBackgroundTap;
  final VoidCallback onToolsTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = MediaQuery.sizeOf(context).width < 370;
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        6,
        compact ? 8 : 10,
        compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ToolItem(
              label: strings.localized(telugu: 'ఫోటో', english: 'Photo'),
              icon: Icons.add_photo_alternate_outlined,
              active: activeToolLabel == 'Photo',
              compact: compact,
              onTap: onPhotoTap,
            ),
          ),
          Expanded(
            child: _ToolItem(
              label: strings.localized(telugu: 'టెక్స్ట్', english: 'Text'),
              icon: Icons.text_fields_rounded,
              active: activeToolLabel == 'Text',
              compact: compact,
              onTap: onTextTap,
            ),
          ),
          Expanded(
            child: _ToolItem(
              label: strings.localized(
                telugu: 'బ్యాక్‌గ్రౌండ్',
                english: 'Background',
              ),
              icon: Icons.wallpaper_outlined,
              active: activeToolLabel == 'Background',
              compact: compact,
              onTap: onBackgroundTap,
            ),
          ),
          Expanded(
            child: _ToolItem(
              label: strings.localized(telugu: 'టూల్స్', english: 'Tools'),
              icon: Icons.tune_rounded,
              active: activeToolLabel == 'Tools',
              compact: compact,
              onTap: onToolsTap,
            ),
          ),
        ],
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
    required this.onPhotoRemoveBgTap,
    required this.onPhotoCropTap,
    required this.onPhotoAdjustTap,
    required this.onTextAddTap,
    required this.onTextEditTap,
    required this.onTextStyleTap,
    required this.onTextColorTap,
    required this.onTextFontTap,
    required this.onBackgroundWhiteTap,
    required this.onBackgroundTransparentTap,
    required this.onBackgroundColorTap,
    required this.onBackgroundGradientTap,
    required this.onBackgroundImageTap,
    required this.onBackgroundBlurTap,
    required this.onToolsCropTap,
    required this.onToolsLayersTap,
    required this.onToolsStickersTap,
    required this.onToolsBorderTap,
    required this.onToolsFiltersTap,
  });

  final double height;
  final _BottomPrimaryTool tool;
  final VoidCallback onBack;
  final Future<void> Function() onPhotoGalleryTap;
  final Future<void> Function() onPhotoCameraTap;
  final Future<void> Function() onPhotoRemoveBgTap;
  final Future<void> Function() onPhotoCropTap;
  final void Function() onPhotoAdjustTap;
  final void Function() onTextAddTap;
  final Future<void> Function() onTextEditTap;
  final void Function() onTextStyleTap;
  final void Function() onTextColorTap;
  final void Function() onTextFontTap;
  final void Function() onBackgroundWhiteTap;
  final void Function() onBackgroundTransparentTap;
  final void Function() onBackgroundColorTap;
  final void Function() onBackgroundGradientTap;
  final Future<void> Function() onBackgroundImageTap;
  final void Function() onBackgroundBlurTap;
  final Future<void> Function() onToolsCropTap;
  final void Function() onToolsLayersTap;
  final void Function() onToolsStickersTap;
  final void Function() onToolsBorderTap;
  final void Function() onToolsFiltersTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = MediaQuery.sizeOf(context).width < 370;
    final items = switch (tool) {
      _BottomPrimaryTool.photo => <Widget>[
        _ToolItem(
          label: strings.localized(telugu: 'గ్యాలరీ', english: 'Gallery'),
          icon: Icons.photo_library_outlined,
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
          label: strings.localized(
            telugu: 'బీజీ తొలగింపు',
            english: 'Remove BG',
          ),
          icon: Icons.auto_fix_high_outlined,
          compact: compact,
          onTap: () => unawaited(onPhotoRemoveBgTap()),
        ),
        _ToolItem(
          label: strings.localized(telugu: 'క్రాప్', english: 'Crop'),
          icon: Icons.crop_rounded,
          compact: compact,
          onTap: () => unawaited(onPhotoCropTap()),
        ),
        _ToolItem(
          label: strings.localized(telugu: 'అడ్జస్ట్', english: 'Adjust'),
          icon: Icons.tune_rounded,
          compact: compact,
          onTap: onPhotoAdjustTap,
        ),
      ],
      _BottomPrimaryTool.text => <Widget>[
        _ToolItem(
          label: strings.localized(telugu: 'టెక్స్ట్ జోడించు', english: 'Add Text'),
          icon: Icons.add_comment_outlined,
          compact: compact,
          onTap: onTextAddTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'ఎడిట్', english: 'Edit'),
          icon: Icons.edit_rounded,
          compact: compact,
          onTap: () => unawaited(onTextEditTap()),
        ),
        _ToolItem(
          label: strings.localized(telugu: 'ఫాంట్', english: 'Font'),
          icon: Icons.font_download_rounded,
          compact: compact,
          onTap: onTextFontTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'కలర్', english: 'Color'),
          icon: Icons.palette_outlined,
          compact: compact,
          onTap: onTextColorTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'స్టైల్', english: 'Style'),
          icon: Icons.tune_rounded,
          compact: compact,
          onTap: onTextStyleTap,
        ),
      ],
      _BottomPrimaryTool.background => <Widget>[
        _ToolItem(
          label: strings.localized(telugu: 'వైట్', english: 'White'),
          icon: Icons.crop_square_rounded,
          compact: compact,
          onTap: onBackgroundWhiteTap,
        ),
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
        _ToolItem(
          label: strings.localized(telugu: 'బ్లర్', english: 'Blur'),
          icon: Icons.blur_on_rounded,
          compact: compact,
          onTap: onBackgroundBlurTap,
        ),
      ],
      _BottomPrimaryTool.tools => <Widget>[
        _ToolItem(
          label: strings.localized(telugu: 'క్రాప్', english: 'Crop'),
          icon: Icons.crop_rounded,
          compact: compact,
          onTap: () => unawaited(onToolsCropTap()),
        ),
        _ToolItem(
          label: strings.localized(telugu: 'లేయర్స్', english: 'Layers'),
          icon: Icons.layers_outlined,
          compact: compact,
          onTap: onToolsLayersTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'స్టికర్స్', english: 'Stickers'),
          icon: Icons.emoji_emotions_outlined,
          compact: compact,
          onTap: onToolsStickersTap,
        ),
        _ToolItem(
          label: strings.localized(telugu: 'బార్డర్', english: 'Border'),
          icon: Icons.border_all_rounded,
          compact: compact,
          onTap: onToolsBorderTap,
        ),
      ],
      _BottomPrimaryTool.none => const <Widget>[],
    };

    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(
        compact ? 6 : 8,
        6,
        compact ? 6 : 8,
        compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
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
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(width: compact ? 2 : 4),
              itemBuilder: (BuildContext context, int index) =>
                  SizedBox(width: compact ? 70 : 78, child: items[index]),
            ),
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
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                tooltip: strings.localized(
                  telugu: 'ముందుకు తీసుకురా',
                  english: 'Move to front',
                ),
                compact: true,
                onTap: selectedLayerId == null ? null : onMoveToFront,
              ),
              _EditorIconButton(
                icon: Icons.vertical_align_bottom_rounded,
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
                  color: Colors.white.withValues(alpha: 0.78),
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
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
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
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: selected ? 16 : 8,
                          height: 2,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withValues(alpha: 0.18),
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
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
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
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
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
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
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
    required this.selectedStyle,
    required this.onBack,
    required this.onStyleTap,
  });

  final double height;
  final _BorderStyle selectedStyle;
  final VoidCallback onBack;
  final ValueChanged<_BorderStyle> onStyleTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final strings = context.strings;
    final options = <(_BorderStyle, String)>[
      (
        _BorderStyle.none,
        strings.localized(telugu: 'ఏదీ కాదు', english: 'None'),
      ),
      (
        _BorderStyle.thinWhite,
        strings.localized(telugu: 'తెలుపు పలుచని', english: 'Thin White'),
      ),
      (
        _BorderStyle.thinBlack,
        strings.localized(telugu: 'నలుపు పలుచని', english: 'Thin Black'),
      ),
      (
        _BorderStyle.rounded,
        strings.localized(telugu: 'రౌండెడ్', english: 'Rounded'),
      ),
      (
        _BorderStyle.glow,
        strings.localized(telugu: 'గ్లో', english: 'Glow'),
      ),
    ];
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
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
              itemCount: options.length,
              separatorBuilder: (_, _) => SizedBox(width: compact ? 4 : 6),
              itemBuilder: (BuildContext context, int index) {
                final entry = options[index];
                return _InlineActionChip(
                  label: entry.$2,
                  active: selectedStyle == entry.$1,
                  compact: compact,
                  onTap: () => onStyleTap(entry.$1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBlurInlineStrip extends StatelessWidget {
  const _BackgroundBlurInlineStrip({
    required this.height,
    required this.value,
    required this.enabled,
    required this.onBack,
    required this.onValueTap,
  });

  final double height;
  final double value;
  final bool enabled;
  final VoidCallback onBack;
  final ValueChanged<double> onValueTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final strings = context.strings;
    const options = <double>[0, 5, 10, 20, 40];
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
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
              itemCount: options.length,
              separatorBuilder: (_, _) => SizedBox(width: compact ? 4 : 6),
              itemBuilder: (BuildContext context, int index) {
                final blurValue = options[index];
                final selected = (value - blurValue).abs() < 0.001;
                return _InlineActionChip(
                  label: blurValue.round().toString(),
                  active: selected,
                  compact: compact,
                  enabled: enabled,
                  onTap: enabled ? () => onValueTap(blurValue) : null,
                );
              },
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
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = enabled ? onTap : null;
    return _PressableSurface(
      onTap: effectiveOnTap,
      enabled: enabled,
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
