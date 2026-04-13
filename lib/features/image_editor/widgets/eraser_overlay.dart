import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/eraser_controller.dart';

class EraserOverlay extends StatefulWidget {
  const EraserOverlay({
    super.key,
    required this.canvasSize,
    required this.topInset,
    required this.bottomInset,
    required this.pageAspectRatio,
    required this.brushSize,
    required this.brushCenterListenable,
    required this.mode,
    required this.isInitializing,
    required this.errorMessage,
    required this.onSingleFingerStart,
    required this.onSingleFingerUpdate,
    required this.onSingleFingerEnd,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final Size canvasSize;
  final double topInset;
  final double bottomInset;
  final double? pageAspectRatio;
  final double brushSize;
  final ValueListenable<Offset?> brushCenterListenable;
  final EraserBlendMode mode;
  final bool isInitializing;
  final String? errorMessage;
  final void Function(Offset localPosition, Rect pageRect, Size pageSize)
  onSingleFingerStart;
  final void Function(Offset localPosition, Rect pageRect, Size pageSize)
  onSingleFingerUpdate;
  final VoidCallback onSingleFingerEnd;
  final ValueChanged<ScaleStartDetails> onScaleStart;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;
  final VoidCallback onScaleEnd;

  @override
  State<EraserOverlay> createState() => _EraserOverlayState();
}

class _EraserOverlayState extends State<EraserOverlay> {
  int _activePointers = 0;
  bool _isSingleFingerStroke = false;

  @override
  Widget build(BuildContext context) {
    final workspaceHeight = math.max(
      0.0,
      widget.canvasSize.height - widget.topInset - widget.bottomInset,
    );
    final workspaceSize = Size(widget.canvasSize.width, workspaceHeight);
    final pageSize = widget.pageAspectRatio != null
        ? fitPageSize(
            workspaceSize: workspaceSize,
            aspectRatio: widget.pageAspectRatio!,
          )
        : workspaceSize;
    final pageRect = Rect.fromCenter(
      center: Offset(
        widget.canvasSize.width / 2,
        widget.topInset + (workspaceHeight / 2),
      ),
      width: pageSize.width,
      height: pageSize.height,
    );

    return Listener(
      onPointerDown: (_) => setState(() => _activePointers += 1),
      onPointerUp: (_) =>
          setState(() => _activePointers = math.max(0, _activePointers - 1)),
      onPointerCancel: (_) =>
          setState(() => _activePointers = math.max(0, _activePointers - 1)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          if (details.pointerCount >= 2) {
            _isSingleFingerStroke = false;
            widget.onScaleStart(details);
            return;
          }
          _isSingleFingerStroke = true;
          widget.onSingleFingerStart(
            details.localFocalPoint,
            pageRect,
            pageSize,
          );
        },
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2 || _activePointers >= 2) {
            if (_isSingleFingerStroke) {
              _isSingleFingerStroke = false;
              widget.onSingleFingerEnd();
            }
            widget.onScaleUpdate(details);
            return;
          }
          widget.onSingleFingerUpdate(
            details.localFocalPoint,
            pageRect,
            pageSize,
          );
        },
        onScaleEnd: (_) {
          if (_isSingleFingerStroke) {
            widget.onSingleFingerEnd();
          } else {
            widget.onScaleEnd();
          }
          _isSingleFingerStroke = false;
        },
        child: Stack(
          children: <Widget>[
            if (widget.isInitializing)
              const Center(
                child: IgnorePointer(
                  child: CircularProgressIndicator(strokeWidth: 2.8),
                ),
              ),
            if (widget.errorMessage != null)
              Positioned(
                left: 20,
                right: 20,
                top: widget.topInset + 14,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD91E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: ValueListenableBuilder<Offset?>(
                valueListenable: widget.brushCenterListenable,
                builder:
                    (BuildContext context, Offset? brushCenter, Widget? child) {
                      return CustomPaint(
                        painter: EraserBrushOverlayPainter(
                          imageRect: pageRect,
                          brushCenter: brushCenter,
                          brushSize: widget.brushSize,
                          mode: widget.mode,
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EraserBrushOverlayPainter extends CustomPainter {
  const EraserBrushOverlayPainter({
    required this.imageRect,
    required this.brushCenter,
    required this.brushSize,
    required this.mode,
  });

  final Rect imageRect;
  final Offset? brushCenter;
  final double brushSize;
  final EraserBlendMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final center = brushCenter;
    if (center == null ||
        !imageRect.inflate(brushSize * 0.5).contains(center)) {
      return;
    }
    final ringColor = mode == EraserBlendMode.erase
        ? const Color(0xFFF97316)
        : const Color(0xFF22C55E);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = ringColor.withValues(alpha: 0.16);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..color = ringColor.withValues(alpha: 0.96);
    canvas.drawCircle(center, brushSize / 2, fill);
    canvas.drawCircle(center, brushSize / 2, stroke);
  }

  @override
  bool shouldRepaint(covariant EraserBrushOverlayPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.brushCenter != brushCenter ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.mode != mode;
  }
}

Size fitPageSize({required Size workspaceSize, required double aspectRatio}) {
  if (workspaceSize.width <= 0 || workspaceSize.height <= 0) {
    return Size.zero;
  }
  final safeAspect = aspectRatio <= 0 ? 1.0 : aspectRatio;
  final maxWidth = workspaceSize.width;
  final maxHeight = workspaceSize.height;
  var width = maxWidth;
  var height = width / safeAspect;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * safeAspect;
  }
  return Size(width, height);
}
