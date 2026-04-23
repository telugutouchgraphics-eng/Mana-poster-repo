part of '../image_editor_screen.dart';

// ignore_for_file: unused_element

class _CropSessionOverlay extends StatelessWidget {
  const _CropSessionOverlay({
    required this.boundaryKey,
    required this.imageBytes,
    required this.controller,
    required this.topInset,
    required this.bottomInset,
    required this.aspectRatio,
  });

  final GlobalKey boundaryKey;
  final Uint8List imageBytes;
  final TransformationController controller;
  final double topInset;
  final double bottomInset;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final frameAspectRatio = (aspectRatio != null && aspectRatio! > 0)
        ? aspectRatio!
        : 1.0;
    return Padding(
      padding: EdgeInsets.only(top: topInset + 8, bottom: bottomInset + 8),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final maxWidth = constraints.maxWidth * 0.98;
          final maxHeight = constraints.maxHeight * 0.98;
          var frameWidth = maxWidth;
          var frameHeight = frameWidth / frameAspectRatio;
          if (frameHeight > maxHeight) {
            frameHeight = maxHeight;
            frameWidth = frameHeight * frameAspectRatio;
          }
          final horizontalGap = (constraints.maxWidth - frameWidth) / 2;
          final verticalGap = (constraints.maxHeight - frameHeight) / 2;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: verticalGap,
                child: _buildCropScrim(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: verticalGap,
                child: _buildCropScrim(),
              ),
              Positioned(
                left: 0,
                top: verticalGap,
                bottom: verticalGap,
                width: horizontalGap,
                child: _buildCropScrim(),
              ),
              Positioned(
                right: 0,
                top: verticalGap,
                bottom: verticalGap,
                width: horizontalGap,
                child: _buildCropScrim(),
              ),
              Center(
                child: Container(
                  width: frameWidth,
                  height: frameHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF05070B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      RepaintBoundary(
                        key: boundaryKey,
                        child: ClipRect(
                          child: InteractiveViewer(
                            transformationController: controller,
                            minScale: 0.5,
                            maxScale: 6,
                            panEnabled: true,
                            scaleEnabled: true,
                            constrained: false,
                            clipBehavior: Clip.none,
                            boundaryMargin: const EdgeInsets.all(240),
                            child: SizedBox(
                              width: frameWidth,
                              height: frameHeight,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.memory(
                                  imageBytes,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: const _CropOverlayPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCropScrim() {
    return IgnorePointer(
      child: ColoredBox(color: Colors.black.withValues(alpha: 0.58)),
    );
  }
}

class _CropAspectChip extends StatelessWidget {
  const _CropAspectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: _PressableSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFDBEAFE)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _CropInlineStrip extends StatelessWidget {
  const _CropInlineStrip({
    required this.height,
    required this.isApplying,
    required this.selectedAspectRatio,
    required this.onBack,
    required this.onReset,
    required this.onApply,
    required this.onAspectRatioChanged,
  });

  final double height;
  final bool isApplying;
  final double? selectedAspectRatio;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final ValueChanged<double?> onAspectRatioChanged;

  bool _isSelected(double? ratio) {
    if (ratio == null && selectedAspectRatio == null) {
      return true;
    }
    if (ratio == null || selectedAspectRatio == null) {
      return false;
    }
    return (ratio - selectedAspectRatio!).abs() < 0.001;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final disabled = isApplying;
    return SafeArea(
      top: false,
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xCC0F172A),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _CropAspectChip(
                    label: strings.localized(telugu: 'ఫ్రీ', english: 'Free'),
                    selected: _isSelected(null),
                    onTap: disabled ? null : () => onAspectRatioChanged(null),
                  ),
                  _CropAspectChip(
                    label: '1:1',
                    selected: _isSelected(1),
                    onTap: disabled ? null : () => onAspectRatioChanged(1),
                  ),
                  _CropAspectChip(
                    label: '4:5',
                    selected: _isSelected(4 / 5),
                    onTap: disabled ? null : () => onAspectRatioChanged(4 / 5),
                  ),
                  _CropAspectChip(
                    label: '16:9',
                    selected: _isSelected(16 / 9),
                    onTap: disabled ? null : () => onAspectRatioChanged(16 / 9),
                  ),
                  _CropAspectChip(
                    label: '9:16',
                    selected: _isSelected(9 / 16),
                    onTap: disabled ? null : () => onAspectRatioChanged(9 / 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildActionButton(
                    label: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
                    onTap: onBack,
                    disabled: disabled,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    label: strings.localized(telugu: 'రిసెట్', english: 'Reset'),
                    onTap: onReset,
                    disabled: disabled,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    label: isApplying
                        ? strings.localized(
                            telugu: 'అప్లై అవుతోంది...',
                            english: 'Applying...',
                          )
                        : strings.localized(
                            telugu: 'అప్లై',
                            english: 'Apply',
                          ),
                    onTap: onApply,
                    disabled: disabled,
                    primary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required bool disabled,
    bool primary = false,
  }) {
    return _PressableSurface(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? const Color(0xFF2563EB).withValues(alpha: disabled ? 0.45 : 0.9)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary
                ? const Color(0xFF3B82F6).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: disabled ? 0.5 : 0.95),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
