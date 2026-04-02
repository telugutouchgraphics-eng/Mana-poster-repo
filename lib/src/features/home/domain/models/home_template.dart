class HomeTemplate {
  const HomeTemplate({
    required this.id,
    required this.title,
    required this.isPremium,
    this.priceLabel,
  });

  final String id;
  final String title;
  final bool isPremium;
  final String? priceLabel;
}
