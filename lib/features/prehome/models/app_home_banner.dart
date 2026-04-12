class AppHomeBanner {
  const AppHomeBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.ctaLabel,
    required this.ctaTarget,
    required this.placement,
    required this.sortOrder,
    required this.active,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String ctaLabel;
  final String ctaTarget;
  final String placement;
  final int sortOrder;
  final bool active;
}
