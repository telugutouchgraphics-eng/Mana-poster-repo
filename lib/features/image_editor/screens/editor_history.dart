part of 'image_editor_screen.dart';

abstract class _EditorHistoryEntry {
  const _EditorHistoryEntry();
}

class _SnapshotHistoryEntry extends _EditorHistoryEntry {
  const _SnapshotHistoryEntry(this.snapshot);

  final _EditorSnapshot snapshot;
}

class _LayerChangeHistoryEntry extends _EditorHistoryEntry {
  const _LayerChangeHistoryEntry({
    required this.layerId,
    required this.beforeLayer,
    required this.afterLayer,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final String layerId;
  final _CanvasLayer beforeLayer;
  final _CanvasLayer afterLayer;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _LayerInsertHistoryEntry extends _EditorHistoryEntry {
  const _LayerInsertHistoryEntry({
    required this.layer,
    required this.insertIndex,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final _CanvasLayer layer;
  final int insertIndex;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _LayerDeleteHistoryEntry extends _EditorHistoryEntry {
  const _LayerDeleteHistoryEntry({
    required this.layer,
    required this.deletedIndex,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final _CanvasLayer layer;
  final int deletedIndex;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _LayerReorderHistoryEntry extends _EditorHistoryEntry {
  const _LayerReorderHistoryEntry({
    required this.layerId,
    required this.fromIndex,
    required this.toIndex,
    required this.beforeSelectedLayerId,
    required this.afterSelectedLayerId,
  });

  final String layerId;
  final int fromIndex;
  final int toIndex;
  final String? beforeSelectedLayerId;
  final String? afterSelectedLayerId;
}

class _CanvasBackgroundHistoryEntry extends _EditorHistoryEntry {
  const _CanvasBackgroundHistoryEntry({
    required this.beforeColor,
    required this.beforeGradientIndex,
    required this.beforeImageBytes,
    required this.beforeBlurAmount,
    required this.afterColor,
    required this.afterGradientIndex,
    required this.afterImageBytes,
    required this.afterBlurAmount,
  });

  final Color beforeColor;
  final int beforeGradientIndex;
  final Uint8List? beforeImageBytes;
  final double beforeBlurAmount;
  final Color afterColor;
  final int afterGradientIndex;
  final Uint8List? afterImageBytes;
  final double afterBlurAmount;
}
