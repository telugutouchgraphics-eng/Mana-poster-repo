class EditorElementAsset {
  const EditorElementAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.url,
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final String category;
  final String url;
  final List<String> tags;
}
