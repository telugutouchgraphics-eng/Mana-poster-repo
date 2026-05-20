class AppPublicInfo {
  AppPublicInfo._();

  static const String appName = 'Mana Poster Ai';
  static const String appTagline = 'Your Daily Telugu Poster App';

  static const String supportEmail = String.fromEnvironment(
    'MANA_POSTER_SUPPORT_EMAIL',
    defaultValue: 'manaposter2026@gmail.com',
  );
  static const String supportPhone = String.fromEnvironment(
    'MANA_POSTER_SUPPORT_PHONE',
    defaultValue: '',
  );
  static const String playStorePackageName = 'com.manaposter.app';
  static const String playStoreUrl = String.fromEnvironment(
    'MANA_POSTER_PLAY_STORE_URL',
    defaultValue:
        'https://play.google.com/store/apps/details?id=com.manaposter.app',
  );
  static const String latestPlayStoreVersion = String.fromEnvironment(
    'MANA_POSTER_LATEST_PLAY_STORE_VERSION',
    defaultValue: '1.0.72',
  );
  static const String adMobHomeBannerAdUnitId = String.fromEnvironment(
    'MANA_POSTER_HOME_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6393573098485696/9317248707',
  );
  static bool get hasHomeBannerAdUnitId => adMobHomeBannerAdUnitId.isNotEmpty;
  static const String adMobEditorRewardedAdUnitId = String.fromEnvironment(
    'MANA_POSTER_EDITOR_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6393573098485696/4602988395',
  );
  static bool get hasEditorRewardedAdUnitId =>
      adMobEditorRewardedAdUnitId.isNotEmpty;
  static bool get hasAnyAdMobConfig =>
      hasHomeBannerAdUnitId || hasEditorRewardedAdUnitId;
  static const String demoUrl = String.fromEnvironment(
    'MANA_POSTER_DEMO_URL',
    defaultValue: '',
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'MANA_POSTER_PRIVACY_POLICY_URL',
    defaultValue: 'https://manaposter.in/legal/privacy-policy.html',
  );

  static const String termsUrl = String.fromEnvironment(
    'MANA_POSTER_TERMS_URL',
    defaultValue: 'https://manaposter.in/legal/terms-and-conditions.html',
  );

  static const String accountDeletionUrl = String.fromEnvironment(
    'MANA_POSTER_ACCOUNT_DELETION_URL',
    defaultValue: 'https://manaposter.in/legal/account-deletion.html',
  );
}
