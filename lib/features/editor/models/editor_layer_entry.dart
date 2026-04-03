enum EditorLayerType {
  background,
  surfacePhoto,
  photo,
  shape,
  text,
  element,
  sticker,
  draw,
}

class EditorLayerEntry {
  const EditorLayerEntry({
    required this.entryId,
    required this.layerId,
    required this.type,
    required this.name,
    required this.isVisible,
    required this.isLocked,
    required this.isSelected,
    required this.isMovable,
    required this.zIndex,
    this.thumbnailUrl,
  });

  final String entryId;
  final String layerId;
  final EditorLayerType type;
  final String name;
  final bool isVisible;
  final bool isLocked;
  final bool isSelected;
  final bool isMovable;
  final int zIndex;
  final String? thumbnailUrl;
}
