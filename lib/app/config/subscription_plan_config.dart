class SubscriptionPlanConfig {
  const SubscriptionPlanConfig._();

  static const String primaryMonthlyProductId = String.fromEnvironment(
    'MANA_POSTER_PREMIUM_PLAN_PRODUCT_ID',
    defaultValue: 'mana_poster_premium_monthly_149',
  );

  static const String trialPriceDisplay = '₹4';
  static const int trialDays = 3;
  static const String monthlyPriceDisplay = '₹149';
  static const Duration entitlementCacheTtl = Duration(minutes: 10);
  /// Must cover cold billing + Firebase entitlement fetch on slower networks.
  static const Duration paywallTimeout = Duration(seconds: 28);
  static const String playPackageName = 'com.manaposter.app';

  /// Every SKU we query Billling / restore / verify against (compile-time IDs).
  static Set<String> resolvedPremiumProductIds() {
    const legacyAlias = String.fromEnvironment(
      'MANA_POSTER_PRO_PRODUCT_ID',
      defaultValue: '',
    );
    final ids = <String>{
      primaryMonthlyProductId,
      if (legacyAlias.isNotEmpty) legacyAlias,
    };
    ids.removeWhere((id) => id.trim().isEmpty);
    return ids;
  }

  static String get trialValueDisplay => '$trialPriceDisplay / $trialDays days';

  static String manageSubscriptionUrl({
    String packageName = playPackageName,
    String productId = primaryMonthlyProductId,
  }) {
    return 'https://play.google.com/store/account/subscriptions'
        '?sku=$productId&package=$packageName';
  }
}
