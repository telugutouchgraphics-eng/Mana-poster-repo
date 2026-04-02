import 'package:mana_poster/src/core/localization/app_language.dart';

class AppStrings {
  static const String splashTitle = 'splashTitle';
  static const String splashSubtitle = 'splashSubtitle';
  static const String loginTitle = 'loginTitle';
  static const String loginContinue = 'loginContinue';
  static const String loginWithGoogle = 'loginWithGoogle';
  static const String loginWithEmail = 'loginWithEmail';
  static const String createAccount = 'createAccount';
  static const String emailHint = 'emailHint';
  static const String passwordHint = 'passwordHint';
  static const String authInProgress = 'authInProgress';
  static const String permissionsTitle = 'permissionsTitle';
  static const String permissionsDescription = 'permissionsDescription';
  static const String permissionsPhotosTitle = 'permissionsPhotosTitle';
  static const String permissionsPhotosSubtitle = 'permissionsPhotosSubtitle';
  static const String permissionsNotificationsTitle =
      'permissionsNotificationsTitle';
  static const String permissionsNotificationsSubtitle =
      'permissionsNotificationsSubtitle';
  static const String continueLabel = 'continueLabel';
  static const String homeTitle = 'homeTitle';
  static const String homeHeaderTitle = 'homeHeaderTitle';
  static const String homeHeaderSubtitle = 'homeHeaderSubtitle';
  static const String homeCategoriesTitle = 'homeCategoriesTitle';
  static const String homeTemplatesTitle = 'homeTemplatesTitle';
  static const String profileTitle = 'profileTitle';
  static const String profileUserInfo = 'profileUserInfo';
  static const String profileLanguage = 'profileLanguage';

  static const Map<AppLanguage, Map<String, String>> _values =
      <AppLanguage, Map<String, String>>{
    AppLanguage.telugu: <String, String>{
      splashTitle: 'మనా పోస్టర్',
      splashSubtitle: 'మీ సృజనాత్మక పోస్టర్ ప్రపంచం',
      loginTitle: 'లాగిన్',
      loginContinue: 'కొనసాగించండి',
      loginWithGoogle: 'Google తో కొనసాగించండి',
      loginWithEmail: 'Email తో లాగిన్',
      createAccount: 'కొత్త అకౌంట్ సృష్టించండి',
      emailHint: 'ఇమెయిల్',
      passwordHint: 'పాస్వర్డ్',
      authInProgress: 'దయచేసి వేచి ఉండండి...',
      permissionsTitle: 'అనుమతులు',
      permissionsDescription:
          'మెరుగైన అనుభవం కోసం ఈ అనుమతులను అనుమతించండి.',
      permissionsPhotosTitle: 'గ్యాలరీ / ఫోటోలు',
      permissionsPhotosSubtitle: 'పోస్టర్లు సృష్టించడానికి ఫోటోలు ఉపయోగించండి.',
      permissionsNotificationsTitle: 'నోటిఫికేషన్స్',
      permissionsNotificationsSubtitle: 'అప్డేట్స్ మరియు రిమైండర్లు పొందండి.',
      continueLabel: 'కొనసాగించండి',
      homeTitle: 'హోమ్',
      homeHeaderTitle: 'మళ్లీ స్వాగతం!',
      homeHeaderSubtitle: 'మీ తదుపరి పోస్టర్‌ను సిద్ధం చేద్దాం.',
      homeCategoriesTitle: 'కేటగిరీలు',
      homeTemplatesTitle: 'టెంప్లేట్లు',
      profileTitle: 'ప్రొఫైల్',
      profileUserInfo: 'వాడుకరి సమాచారం',
      profileLanguage: 'భాష',
    },
    AppLanguage.hindi: <String, String>{
      splashTitle: 'मना पोस्टर',
      splashSubtitle: 'आपकी रचनात्मक पोस्टर दुनिया',
      loginTitle: 'लॉगिन',
      loginContinue: 'जारी रखें',
      loginWithGoogle: 'Google से जारी रखें',
      loginWithEmail: 'ईमेल से लॉगिन',
      createAccount: 'नया अकाउंट बनाएं',
      emailHint: 'ईमेल',
      passwordHint: 'पासवर्ड',
      authInProgress: 'कृपया प्रतीक्षा करें...',
      permissionsTitle: 'अनुमतियाँ',
      permissionsDescription: 'बेहतर अनुभव के लिए इन अनुमतियों को दें।',
      permissionsPhotosTitle: 'गैलरी / फोटो',
      permissionsPhotosSubtitle: 'पोस्टर बनाते समय फोटो उपयोग करें।',
      permissionsNotificationsTitle: 'सूचनाएँ',
      permissionsNotificationsSubtitle: 'अपडेट और रिमाइंडर प्राप्त करें।',
      continueLabel: 'जारी रखें',
      homeTitle: 'होम',
      homeHeaderTitle: 'फिर से स्वागत है!',
      homeHeaderSubtitle: 'आइए आपका अगला पोस्टर बनाते हैं।',
      homeCategoriesTitle: 'कैटेगरी',
      homeTemplatesTitle: 'टेम्पलेट्स',
      profileTitle: 'प्रोफाइल',
      profileUserInfo: 'यूज़र जानकारी',
      profileLanguage: 'भाषा',
    },
    AppLanguage.english: <String, String>{
      splashTitle: 'Mana Poster',
      splashSubtitle: 'Your creative poster world',
      loginTitle: 'Login',
      loginContinue: 'Continue',
      loginWithGoogle: 'Continue with Google',
      loginWithEmail: 'Login with Email',
      createAccount: 'Create New Account',
      emailHint: 'Email',
      passwordHint: 'Password',
      authInProgress: 'Please wait...',
      permissionsTitle: 'Permissions',
      permissionsDescription: 'Allow these permissions for a better experience.',
      permissionsPhotosTitle: 'Gallery / Photos',
      permissionsPhotosSubtitle: 'Use photos while creating posters.',
      permissionsNotificationsTitle: 'Notifications',
      permissionsNotificationsSubtitle: 'Get updates and reminders.',
      continueLabel: 'Continue',
      homeTitle: 'Home',
      homeHeaderTitle: 'Welcome back!',
      homeHeaderSubtitle: 'Let us build your next poster.',
      homeCategoriesTitle: 'Categories',
      homeTemplatesTitle: 'Templates',
      profileTitle: 'Profile',
      profileUserInfo: 'User Info',
      profileLanguage: 'Language',
    },
  };

  static String text(AppLanguage language, String key) {
    return _values[language]?[key] ??
        _values[AppLanguage.english]?[key] ??
        key;
  }
}
