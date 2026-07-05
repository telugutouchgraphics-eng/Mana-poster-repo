part of '../image_editor_screen.dart';

extension _EditorReplayState on _ImageEditorScreenState {
  Future<void> _openHistoryReplay() async {
    if (_isHistoryReplayRunning || _undoStack.isEmpty) {
      if (_undoStack.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'రీప్లే చేయడానికి edits లేవు',
                english: 'No edits available to replay',
              ),
            ),
          ),
        );
      }
      return;
    }
    _closeTransientSessionsForHistory();
    final finalSnapshot = _takeSnapshot();
    final entries = _undoStack.reversed.take(24).toList(growable: false);
    final reverseTimeline = <_EditorSnapshot>[
      _snapshotWithoutSelection(finalSnapshot),
    ];

    for (final entry in entries) {
      _applyHistoryEntryForReplay(entry, useAfter: false);
      reverseTimeline.add(_snapshotWithoutSelection(_takeSnapshot()));
    }
    _restoreSnapshot(finalSnapshot);
    final timeline = reverseTimeline.reversed.toList(growable: false);
    final progress = ValueNotifier<double>(0);
    _isHistoryReplayRunning = true;
    _isLayerInteracting = true;

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.14),
        transitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return _HistoryReplayOverlay(
            progress: progress,
            stepCount: timeline.length,
            onStart: () async {
              for (var index = 0; index < timeline.length; index++) {
                if (!mounted) {
                  return;
                }
                setState(() => _restoreSnapshot(timeline[index]));
                progress.value = timeline.length <= 1
                    ? 1
                    : index / (timeline.length - 1);
                await Future<void>.delayed(const Duration(milliseconds: 145));
              }
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
          );
        },
      );
    } finally {
      progress.dispose();
      _isLayerInteracting = false;
      _isHistoryReplayRunning = false;
      if (mounted) {
        setState(() {
          _restoreSnapshot(finalSnapshot);
          _activeMainToolLabel = '';
        });
      }
    }
  }

  _EditorSnapshot _snapshotWithoutSelection(_EditorSnapshot source) {
    return _EditorSnapshot(
      layers: source.layers.map(_cloneLayer).toList(growable: false),
      selectedLayerId: null,
      canvasBackgroundColor: source.canvasBackgroundColor,
      canvasBackgroundGradientIndex: source.canvasBackgroundGradientIndex,
      stageBackgroundImageBytes: source.stageBackgroundImageBytes == null
          ? null
          : Uint8List.fromList(source.stageBackgroundImageBytes!),
      borderStyle: source.borderStyle,
      borderWidth: source.borderWidth,
      borderRadius: source.borderRadius,
      borderColor: source.borderColor,
      borderTargetLayerId: source.borderTargetLayerId,
      backgroundBlurAmount: source.backgroundBlurAmount,
    );
  }

  void _applyHistoryEntryForReplay(
    _EditorHistoryEntry entry, {
    required bool useAfter,
  }) {
    if (entry is _SnapshotHistoryEntry) {
      if (!useAfter) {
        _restoreSnapshot(entry.snapshot);
      }
      return;
    }
    if (entry is _LayerChangeHistoryEntry) {
      _applyLayerHistoryEntry(entry, useAfter: useAfter);
      return;
    }
    if (entry is _LayerInsertHistoryEntry) {
      _applyLayerInsertHistoryEntry(entry, useAfter: useAfter);
      return;
    }
    if (entry is _LayerDeleteHistoryEntry) {
      _applyLayerDeleteHistoryEntry(entry, useAfter: useAfter);
      return;
    }
    if (entry is _LayerReorderHistoryEntry) {
      _applyLayerReorderHistoryEntry(entry, useAfter: useAfter);
      return;
    }
    if (entry is _CanvasBackgroundHistoryEntry) {
      _applyCanvasBackgroundHistoryEntry(entry, useAfter: useAfter);
    }
  }
}

class _HistoryReplayOverlay extends StatefulWidget {
  const _HistoryReplayOverlay({
    required this.progress,
    required this.stepCount,
    required this.onStart,
  });

  final ValueListenable<double> progress;
  final int stepCount;
  final Future<void> Function() onStart;

  @override
  State<_HistoryReplayOverlay> createState() => _HistoryReplayOverlayState();
}

class _HistoryReplayOverlayState extends State<_HistoryReplayOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.onStart());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
            child: _EditorGlassSurface(
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.progress,
                  builder: (context, value, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Color(0xFF4DA3FF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.strings.localized(
                                telugu: 'ఎడిట్ రీప్లే',
                                english: 'Edit Replay',
                              ),
                              style: const TextStyle(
                                color: _editorChromeTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(value * widget.stepCount).ceil().clamp(0, widget.stepCount)}/${widget.stepCount}',
                              style: const TextStyle(
                                color: _editorChromeTextSecondary,
                                fontSize: 11,
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: value.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            color: const Color(0xFF4DA3FF),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
