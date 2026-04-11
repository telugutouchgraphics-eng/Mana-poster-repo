class ApprovedCreatorTemplate {
  const ApprovedCreatorTemplate({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryLabel,
    required this.createdAtMillis,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String categoryId;
  final String categoryLabel;
  final int createdAtMillis;
}
