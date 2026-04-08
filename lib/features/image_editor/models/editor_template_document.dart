class EditorTemplateDocument {
  const EditorTemplateDocument({
    required this.templateId,
    required this.title,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.layers,
  });

  factory EditorTemplateDocument.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['layers'];
    return EditorTemplateDocument(
      templateId: json['templateId'] as String? ?? 'template',
      title: json['title'] as String? ?? 'Premium Template',
      sourceWidth: (json['sourceWidth'] as num?)?.toDouble() ?? 1080,
      sourceHeight: (json['sourceHeight'] as num?)?.toDouble() ?? 1080,
      layers: rawLayers is List
          ? rawLayers
                .whereType<Map>()
                .map(
                  (raw) => EditorTemplateLayer.fromJson(
                    raw.cast<String, dynamic>(),
                  ),
                )
                .toList(growable: false)
          : const <EditorTemplateLayer>[],
    );
  }

  final String templateId;
  final String title;
  final double sourceWidth;
  final double sourceHeight;
  final List<EditorTemplateLayer> layers;

  double get aspectRatio =>
      sourceHeight <= 0 ? 1 : sourceWidth / sourceHeight;
}

class EditorTemplateLayer {
  const EditorTemplateLayer({
    required this.id,
    required this.assetPath,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.visible,
  });

  factory EditorTemplateLayer.fromJson(Map<String, dynamic> json) {
    return EditorTemplateLayer(
      id: json['id'] as String? ?? 'layer',
      assetPath: json['assetPath'] as String? ?? '',
      left: (json['left'] as num?)?.toDouble() ?? 0,
      top: (json['top'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      opacity: ((json['opacity'] as num?)?.toDouble() ?? 1).clamp(0, 1),
      visible: json['visible'] as bool? ?? true,
    );
  }

  final String id;
  final String assetPath;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;
  final bool visible;
}
