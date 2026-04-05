class EditorPageConfig {
  const EditorPageConfig({
    required this.name,
    required this.widthPx,
    required this.heightPx,
  });

  static const EditorPageConfig defaultConfig = EditorPageConfig(
    name: 'Instagram Post',
    widthPx: 1080,
    heightPx: 1080,
  );

  final String name;
  final int widthPx;
  final int heightPx;

  double get aspectRatio => widthPx / heightPx;

  EditorPageConfig copyWith({
    String? name,
    int? widthPx,
    int? heightPx,
  }) {
    return EditorPageConfig(
      name: name ?? this.name,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
    );
  }
}
