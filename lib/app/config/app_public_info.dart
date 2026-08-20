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
  static const String websiteUrl = String.fromEnvironment(
    'MANA_POSTER_WEBSITE_URL',
    defaultValue: 'https://manaposter.in',
  );
  static const String playStorePackageName = 'com.manaposter.app';
  static const String playStoreUrl = String.fromEnvironment(
    'MANA_POSTER_PLAY_STORE_URL',
    defaultValue:
        'https://play.google.com/store/apps/details?id=com.manaposter.app',
  );
  static const String latestPlayStoreVersion = String.fromEnvironment(
    'MANA_POSTER_LATEST_PLAY_STORE_VERSION',
    defaultValue: '1.1.39',
  );
  static const String adMobHomeBannerAdUnitId = String.fromEnvironment(
    'MANA_POSTER_HOME_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6393573098485696/9317248707',
  );
  static bool get hasHomeBannerAdUnitId => adMobHomeBannerAdUnitId.isNotEmpty;
  static const String adMobEditorBannerAdUnitId = String.fromEnvironment(
    'MANA_POSTER_EDITOR_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6393573098485696/1186695363',
  );
  static bool get hasEditorBannerAdUnitId =>
      adMobEditorBannerAdUnitId.isNotEmpty;
  static const String adMobEditorRewardedAdUnitId = String.fromEnvironment(
    'MANA_POSTER_EDITOR_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6393573098485696/4602988395',
  );
  static bool get hasEditorRewardedAdUnitId =>
      adMobEditorRewardedAdUnitId.isNotEmpty;
  static const String adMobHomeExportRewardedAdUnitId = String.fromEnvironment(
    'MANA_POSTER_HOME_EXPORT_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6393573098485696/7632608239',
  );
  static bool get hasHomeExportRewardedAdUnitId =>
      adMobHomeExportRewardedAdUnitId.isNotEmpty;
  static bool get hasAnyAdMobConfig =>
      hasHomeBannerAdUnitId ||
      hasEditorBannerAdUnitId ||
      hasEditorRewardedAdUnitId ||
      hasHomeExportRewardedAdUnitId;
  static const String demoUrl = String.fromEnvironment(
    'MANA_POSTER_DEMO_URL',
    defaultValue: '',
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'MANA_POSTER_PRIVACY_POLICY_URL',
    defaultValue: 'https://manaposter.in/privacy-policy',
  );

  static const String termsUrl = String.fromEnvironment(
    'MANA_POSTER_TERMS_URL',
    defaultValue: 'https://manaposter.in/terms-and-conditions',
  );

  static const String accountDeletionUrl = String.fromEnvironment(
    'MANA_POSTER_ACCOUNT_DELETION_URL',
    defaultValue: 'https://manaposter.in/account-deletion',
  );

  static const String aboutUsUrl = String.fromEnvironment(
    'MANA_POSTER_ABOUT_US_URL',
    defaultValue: 'https://manaposter.in/about-us',
  );

  static const String legalNoticesUrl = String.fromEnvironment(
    'MANA_POSTER_LEGAL_NOTICES_URL',
    defaultValue: 'https://manaposter.in/legal-notices',
  );

  static const String assetSearchUrl = String.fromEnvironment(
    'MANA_POSTER_ASSET_SEARCH_URL',
    defaultValue: 'https://manaposter.in/assets',
  );
}
