class AppPublicInfo {
  AppPublicInfo._();

  static const String appName = 'Mana Poster';
  static const String appTagline = 'Create Telugu Posters';

  static const String supportEmail = String.fromEnvironment(
    'MANA_POSTER_SUPPORT_EMAIL',
    defaultValue: 'manaposter2026@gmail.com',
  );
  static const String supportPhone = String.fromEnvironment(
    'MANA_POSTER_SUPPORT_PHONE',
    defaultValue: '',
  );
  static const String playStorePackageName = 'com.telugutouch.manaposter';
  static const String playStoreUrl = String.fromEnvironment(
    'MANA_POSTER_PLAY_STORE_URL',
    defaultValue:
        'https://play.google.com/store/apps/details?id=com.telugutouch.manaposter',
  );
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
