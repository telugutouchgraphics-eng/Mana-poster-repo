class EditorStickerAsset {
  const EditorStickerAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.url,
    this.tags = const <String>[],
    this.isAnimated = false,
  });

  final String id;
  final String name;
  final String category;
  final String url;
  final List<String> tags;
  final bool isAnimated;
}
