// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _EditablePoliticalProtocolOverlay extends StatefulWidget {
  const _EditablePoliticalProtocolOverlay({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.adminUrls,
    required this.defaultSlots,
    required this.manualPhotoPaths,
    required this.manualSlots,
    required this.hiddenDefaultPhotoUrls,
    required this.deleteArmedDefaultIndex,
    required this.deleteArmedManualIndex,
    required this.onDefaultSlotChanged,
    required this.onDefaultPhotoTap,
    required this.onManualSlotChanged,
    required this.onManualPhotoTap,
  });

  final double canvasWidth;
  final double canvasHeight;
  final List<String> adminUrls;
  final List<PoliticalProtocolSlot> defaultSlots;
  final List<String> manualPhotoPaths;
  final List<PoliticalProtocolSlot> manualSlots;
  final Set<String> hiddenDefaultPhotoUrls;
  final int? deleteArmedDefaultIndex;
  final int? deleteArmedManualIndex;
  final void Function(int index, PoliticalProtocolSlot slot)
  onDefaultSlotChanged;
  final void Function(int index, String url) onDefaultPhotoTap;
  final void Function(int index, PoliticalProtocolSlot slot)
  onManualSlotChanged;
  final ValueChanged<int> onManualPhotoTap;

  @override
  State<_EditablePoliticalProtocolOverlay> createState() =>
      _EditablePoliticalProtocolOverlayState();
}

class _EditablePoliticalProtocolOverlayState
    extends State<_EditablePoliticalProtocolOverlay> {
  late List<PoliticalProtocolSlot> _defaultSlots;
  late List<PoliticalProtocolSlot> _manualSlots;

  @override
  void initState() {
    super.initState();
    _defaultSlots = _copySlots(widget.defaultSlots);
    _manualSlots = _copySlots(widget.manualSlots);
  }

  @override
  void didUpdateWidget(covariant _EditablePoliticalProtocolOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultSlots.length != widget.defaultSlots.length ||
        oldWidget.adminUrls.length != widget.adminUrls.length) {
      _defaultSlots = _copySlots(widget.defaultSlots);
    } else {
      _defaultSlots = _copySlots(widget.defaultSlots);
    }
    if (oldWidget.manualSlots.length != widget.manualSlots.length ||
        oldWidget.manualPhotoPaths.length != widget.manualPhotoPaths.length) {
      _manualSlots = _copySlots(widget.manualSlots);
    } else {
      _manualSlots = _copySlots(widget.manualSlots);
    }
  }

  List<PoliticalProtocolSlot> _copySlots(List<PoliticalProtocolSlot> slots) {
    return slots
        .map(
          (slot) =>
              PoliticalProtocolSlot(x: slot.x, y: slot.y, scale: slot.scale),
        )
        .toList(growable: true);
  }

  Widget _buildPhotoSlot({required double side, required Widget child}) {
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.95),
        border: Border.all(color: Colors.white, width: 0.8),
      ),
      child: ClipOval(child: child),
    );
  }

  Widget _buildProtocolPhotoSource(String source) {
    final trimmed = source.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PoliticalProtocolFallback(),
        errorWidget: (_, _, _) => const _PoliticalProtocolFallback(),
      );
    }
    return Image.file(
      File(trimmed),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PoliticalProtocolFallback(),
    );
  }

  PoliticalProtocolSlot _defaultManualSlot(int index) {
    final row = index ~/ 4;
    final col = index % 4;
    return PoliticalProtocolSlot(
      x: (22 + (col * 18)).clamp(8, 92).toDouble(),
      y: (24 + (row * 14)).clamp(8, 92).toDouble(),
      scale: 100,
    );
  }

  PoliticalProtocolSlot _draggedSlot({
    required PoliticalProtocolSlot slot,
    required DragUpdateDetails details,
    required double side,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final nextX = (slot.x + (details.delta.dx / canvasWidth) * 100)
        .clamp((side / canvasWidth) * 50, 100 - ((side / canvasWidth) * 50))
        .toDouble();
    final nextY = (slot.y + (details.delta.dy / canvasHeight) * 100)
        .clamp((side / canvasHeight) * 50, 100 - ((side / canvasHeight) * 50))
        .toDouble();
    return PoliticalProtocolSlot(x: nextX, y: nextY, scale: slot.scale);
  }

  @override
  Widget build(BuildContext context) {
    final safeCanvasWidth = math.max(1.0, widget.canvasWidth);
    final safeCanvasHeight = math.max(1.0, widget.canvasHeight);
    final hiddenDefaultUrls = widget.hiddenDefaultPhotoUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (var index = 0; index < widget.adminUrls.length; index += 1)
          Builder(
            builder: (context) {
              final adminUrl = widget.adminUrls[index].trim();
              if (adminUrl.isEmpty || hiddenDefaultUrls.contains(adminUrl)) {
                return const SizedBox.shrink();
              }
              final slot = index < _defaultSlots.length
                  ? widget.defaultSlots[index]
                  : defaultPoliticalProtocolSlots[index %
                        defaultPoliticalProtocolSlots.length];
              final side = _PoliticalProtocolPhotoSlots._slotSide(
                canvasWidth: safeCanvasWidth,
                canvasHeight: safeCanvasHeight,
                scale: slot.scale,
              );
              final centerX = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.x,
                canvasExtent: safeCanvasWidth,
                side: side,
              );
              final centerY = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.y,
                canvasExtent: safeCanvasHeight,
                side: side,
              );
              final deleteArmed = widget.deleteArmedDefaultIndex == index;
              final child = Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CachedNetworkImage(
                    imageUrl: adminUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const Icon(Icons.person_rounded),
                  ),
                  if (deleteArmed)
                    ColoredBox(
                      color: Colors.red.withValues(alpha: 0.78),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              );
              return Positioned(
                left: (safeCanvasWidth * (centerX / 100)) - (side / 2),
                top: (safeCanvasHeight * (centerY / 100)) - (side / 2),
                width: side,
                height: side,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onDefaultPhotoTap(index, adminUrl),
                  onPanUpdate: (details) {
                    final nextSlot = _draggedSlot(
                      slot: index < widget.defaultSlots.length
                          ? widget.defaultSlots[index]
                          : slot,
                      details: details,
                      side: side,
                      canvasWidth: safeCanvasWidth,
                      canvasHeight: safeCanvasHeight,
                    );
                    setState(() {
                      if (index < _defaultSlots.length) {
                        _defaultSlots[index] = nextSlot;
                      }
                    });
                    if (index < widget.defaultSlots.length) {
                      widget.onDefaultSlotChanged(index, nextSlot);
                    }
                  },
                  child: _buildPhotoSlot(side: side, child: child),
                ),
              );
            },
          ),
        for (
          var manualIndex = 0;
          manualIndex < widget.manualPhotoPaths.length;
          manualIndex += 1
        )
          Builder(
            builder: (context) {
              final slot = manualIndex < _manualSlots.length
                  ? widget.manualSlots[manualIndex]
                  : _defaultManualSlot(manualIndex);
              final side = _PoliticalProtocolPhotoSlots._slotSide(
                canvasWidth: safeCanvasWidth,
                canvasHeight: safeCanvasHeight,
                scale: slot.scale,
              );
              final centerX = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.x,
                canvasExtent: safeCanvasWidth,
                side: side,
              );
              final centerY = _PoliticalProtocolPhotoSlots._slotCenter(
                value: slot.y,
                canvasExtent: safeCanvasHeight,
                side: side,
              );
              final deleteArmed = widget.deleteArmedManualIndex == manualIndex;
              final child = Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _buildProtocolPhotoSource(
                    widget.manualPhotoPaths[manualIndex],
                  ),
                  if (deleteArmed)
                    ColoredBox(
                      color: Colors.red.withValues(alpha: 0.78),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              );
              return Positioned(
                left: (safeCanvasWidth * (centerX / 100)) - (side / 2),
                top: (safeCanvasHeight * (centerY / 100)) - (side / 2),
                width: side,
                height: side,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onManualPhotoTap(manualIndex),
                  onPanUpdate: (details) {
                    final nextSlot = _draggedSlot(
                      slot: manualIndex < widget.manualSlots.length
                          ? widget.manualSlots[manualIndex]
                          : slot,
                      details: details,
                      side: side,
                      canvasWidth: safeCanvasWidth,
                      canvasHeight: safeCanvasHeight,
                    );
                    setState(() {
                      if (manualIndex < _manualSlots.length) {
                        _manualSlots[manualIndex] = nextSlot;
                      }
                    });
                    if (manualIndex < widget.manualSlots.length) {
                      widget.onManualSlotChanged(manualIndex, nextSlot);
                    }
                  },
                  child: _buildPhotoSlot(side: side, child: child),
                ),
              );
            },
          ),
      ],
    );
  }
}

enum _FreeExportChoice { none, subscribe, plainDownload, plainShare }

