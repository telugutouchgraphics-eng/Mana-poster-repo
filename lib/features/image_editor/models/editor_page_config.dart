class EditorPageConfig {
  const EditorPageConfig({
    required this.name,
    required this.widthPx,
    required this.heightPx,
    this.dpi = 300,
  });

  static const EditorPageConfig defaultConfig = EditorPageConfig(
    name: 'Instagram Post',
    widthPx: 1080,
    heightPx: 1080,
    dpi: 300,
  );

  final String name;
  final int widthPx;
  final int heightPx;
  final int dpi;

  double get aspectRatio => widthPx / heightPx;
  double get widthInches => widthPx / dpi;
  double get heightInches => heightPx / dpi;

  String get printSummary =>
      '$widthPx×$heightPx px • ${widthInches.toStringAsFixed(2)}×${heightInches.toStringAsFixed(2)} in • $dpi DPI';

  EditorPageConfig copyWith({
    String? name,
    int? widthPx,
    int? heightPx,
    int? dpi,
  }) {
    return EditorPageConfig(
      name: name ?? this.name,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      dpi: dpi ?? this.dpi,
    );
  }
}
