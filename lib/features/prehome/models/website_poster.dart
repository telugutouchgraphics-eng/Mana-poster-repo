class WebsitePoster {
  const WebsitePoster({
    required this.id,
    required this.category,
    required this.imageUrl,
    required this.sortOrder,
    required this.active,
  });

  final String id;
  final String category;
  final String imageUrl;
  final int sortOrder;
  final bool active;

  factory WebsitePoster.fromMap(Map<String, dynamic> data, {required String id}) {
    final rawSortOrder = data['sortOrder'];
    return WebsitePoster(
      id: id,
      category: (data['category'] as String? ?? '').trim(),
      imageUrl: (data['imageUrl'] as String? ?? '').trim(),
      sortOrder: rawSortOrder is num ? rawSortOrder.toInt() : int.tryParse('${rawSortOrder ?? 0}') ?? 0,
      active: data['active'] is bool ? data['active'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'category': category,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'active': active,
    };
  }
}
