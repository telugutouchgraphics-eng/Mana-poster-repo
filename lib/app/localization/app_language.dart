import 'package:flutter/material.dart';

enum AppLanguage { telugu, hindi, english }

class AppLanguageController extends ChangeNotifier {
  AppLanguageController({AppLanguage initialLanguage = AppLanguage.telugu})
    : _language = initialLanguage;

  AppLanguage _language;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found in widget tree.');
    return scope!.notifier!;
  }
}

extension AppLanguageContextX on BuildContext {
  AppLanguageController get languageController => AppLanguageScope.of(this);
  AppLanguage get currentLanguage => languageController.language;
  AppStrings get strings => AppStrings(currentLanguage);
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isTelugu => language == AppLanguage.telugu;
  bool get isHindi => language == AppLanguage.hindi;
  bool get isEnglish => language == AppLanguage.english;

  String get splashTagline => switch (language) {
    AppLanguage.telugu => 'ఎంచుకోండి, మీ పేరుతో షేర్ చేయండి',
    AppLanguage.hindi => 'चुनें, अपने नाम के साथ शेयर करें',
    AppLanguage.english => 'Choose and share with your name',
  };

  String get languageScreenTitle => switch (language) {
    AppLanguage.telugu => 'మీ భాషను ఎంచుకోండి',
    AppLanguage.hindi => 'अपनी भाषा चुनें',
    AppLanguage.english => 'Choose your language',
  };

  String get languageScreenSubtitle => switch (language) {
    AppLanguage.telugu =>
      'యాప్‌లో మీకు కావాల్సిన భాషను ఎంచుకోండి. తర్వాత కూడా మార్చుకోవచ్చు.',
    AppLanguage.hindi =>
      'ऐप में अपनी पसंद की भाषा चुनें। बाद में भी बदल सकते हैं।',
    AppLanguage.english =>
      'Choose the language you want in the app. You can change it later too.',
  };

  String get continueLabel => switch (language) {
    AppLanguage.telugu => 'కొనసాగించండి',
    AppLanguage.hindi => 'जारी रखें',
    AppLanguage.english => 'Continue',
  };

  String get onboardingNext => switch (language) {
    AppLanguage.telugu => 'తదుపరి',
    AppLanguage.hindi => 'आगे',
    AppLanguage.english => 'Next',
  };

  String get onboardingGetStarted => switch (language) {
    AppLanguage.telugu => 'ప్రారంభించండి',
    AppLanguage.hindi => 'शुरू करें',
    AppLanguage.english => 'Get Started',
  };

  String get onboardingSkip => switch (language) {
    AppLanguage.telugu => 'స్కిప్',
    AppLanguage.hindi => 'स्किप',
    AppLanguage.english => 'Skip',
  };

  List<({IconData icon, String title, String desc, List<Color> colors})>
  get onboardingItems => switch (language) {
    AppLanguage.telugu =>
      const <({IconData icon, String title, String desc, List<Color> colors})>[
        (
          icon: Icons.auto_awesome_rounded,
          title: 'అందమైన పోస్టర్లు సులభంగా తయారు చేయండి',
          desc:
              'రెడీమేడ్ టెంప్లేట్స్‌తో మీ పేరు, ఫోటో జోడించి వెంటనే పోస్టర్ తయారు చేయండి.',
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF2563EB)],
        ),
        (
          icon: Icons.style_rounded,
          title: 'ఫ్రీ & ప్రీమియమ్ డిజైన్స్ ఒకేచోట',
          desc:
              'ప్రతి రోజు కొత్త కేటగిరీలు, పండుగ పోస్టర్లు, స్పెషల్ డిజైన్స్ పొందండి.',
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF10B981)],
        ),
        (
          icon: Icons.share_rounded,
          title: 'షేర్ చేయండి, డౌన్‌లోడ్ చేసుకోండి',
          desc:
              'మీ పోస్టర్‌ను ఎడిట్ చేసి WhatsApp, Facebook, Instagramలో సులభంగా షేర్ చేయండి.',
          colors: <Color>[Color(0xFFEC4899), Color(0xFFF97316)],
        ),
      ],
    AppLanguage.hindi =>
      const <({IconData icon, String title, String desc, List<Color> colors})>[
        (
          icon: Icons.auto_awesome_rounded,
          title: 'सुंदर पोस्टर आसानी से बनाएं',
          desc:
              'रेडीमेड टेम्पलेट्स में अपना नाम और फोटो जोड़कर तुरंत पोस्टर बनाएं।',
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF2563EB)],
        ),
        (
          icon: Icons.style_rounded,
          title: 'फ्री और प्रीमियम डिज़ाइन एक ही जगह',
          desc: 'हर दिन नई कैटेगरी, फेस्टिवल पोस्टर और खास डिज़ाइन पाएं।',
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF10B981)],
        ),
        (
          icon: Icons.share_rounded,
          title: 'शेयर करें, डाउनलोड करें',
          desc:
              'अपने पोस्टर को एडिट करके WhatsApp, Facebook और Instagram पर आसानी से शेयर करें।',
          colors: <Color>[Color(0xFFEC4899), Color(0xFFF97316)],
        ),
      ],
    AppLanguage.english =>
      const <({IconData icon, String title, String desc, List<Color> colors})>[
        (
          icon: Icons.auto_awesome_rounded,
          title: 'Create beautiful posters easily',
          desc:
              'Use ready-made templates, add your name and photo, and create instantly.',
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF2563EB)],
        ),
        (
          icon: Icons.style_rounded,
          title: 'Free & premium designs in one place',
          desc:
              'Get daily categories, festival posters, and special designs in one app.',
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF10B981)],
        ),
        (
          icon: Icons.share_rounded,
          title: 'Share and download easily',
          desc:
              'Edit your poster and share it easily on WhatsApp, Facebook, and Instagram.',
          colors: <Color>[Color(0xFFEC4899), Color(0xFFF97316)],
        ),
      ],
  };

  String get loginWelcome => switch (language) {
    AppLanguage.telugu => 'Mana Poster కి స్వాగతం',
    AppLanguage.hindi => 'Mana Poster में आपका स्वागत है',
    AppLanguage.english => 'Welcome to Mana Poster',
  };

  String get loginSubtitle => switch (language) {
    AppLanguage.telugu =>
      'Google లేదా Email తో login అయి మీ పోస్టర్ ప్రయాణాన్ని ప్రారంభించండి.',
    AppLanguage.hindi =>
      'Google या Email से login करके अपनी poster journey शुरू करें.',
    AppLanguage.english =>
      'Login with Google or Email and start your poster journey.',
  };

  String get loginLabel => switch (language) {
    AppLanguage.telugu => 'Login',
    AppLanguage.hindi => 'Login',
    AppLanguage.english => 'Login',
  };

  String get signUpLabel => switch (language) {
    AppLanguage.telugu => 'Sign Up',
    AppLanguage.hindi => 'Sign Up',
    AppLanguage.english => 'Sign Up',
  };

  String get googleContinue => switch (language) {
    AppLanguage.telugu => 'Google తో కొనసాగించండి',
    AppLanguage.hindi => 'Google से जारी रखें',
    AppLanguage.english => 'Continue with Google',
  };

  String get emailAddress => switch (language) {
    AppLanguage.telugu => 'Email address',
    AppLanguage.hindi => 'Email address',
    AppLanguage.english => 'Email address',
  };

  String get password => switch (language) {
    AppLanguage.telugu => 'Password',
    AppLanguage.hindi => 'Password',
    AppLanguage.english => 'Password',
  };

  String get forgotPassword => switch (language) {
    AppLanguage.telugu => 'Forgot Password',
    AppLanguage.hindi => 'Forgot Password',
    AppLanguage.english => 'Forgot Password',
  };

  String get noAccount => switch (language) {
    AppLanguage.telugu => 'Account లేదా?',
    AppLanguage.hindi => 'Account नहीं है?',
    AppLanguage.english => 'Account or not?',
  };

  String get alreadyHaveAccount => switch (language) {
    AppLanguage.telugu => 'ఇప్పటికే account ఉందా?',
    AppLanguage.hindi => 'Already have an account?',
    AppLanguage.english => 'Already have an account?',
  };

  String get loginWithEmail => switch (language) {
    AppLanguage.telugu => 'Email తో Login',
    AppLanguage.hindi => 'Email से Login',
    AppLanguage.english => 'Login with Email',
  };

  String get signUpWithEmail => switch (language) {
    AppLanguage.telugu => 'Email తో Sign Up',
    AppLanguage.hindi => 'Email से Sign Up',
    AppLanguage.english => 'Sign Up with Email',
  };

  String get validEmailError => switch (language) {
    AppLanguage.telugu => 'సరైన email ఇవ్వండి',
    AppLanguage.hindi => 'सही email दर्ज करें',
    AppLanguage.english => 'Enter valid email',
  };

  String get passwordError => switch (language) {
    AppLanguage.telugu => 'కనీసం 6 అక్షరాలు అవసరం',
    AppLanguage.hindi => 'कम से कम 6 अक्षर चाहिए',
    AppLanguage.english => 'Minimum 6 characters required',
  };

  String get forgotPasswordPlaceholder => switch (language) {
    AppLanguage.telugu =>
      'Forgot Password flow backend integration తర్వాత activate అవుతుంది.',
    AppLanguage.hindi =>
      'Forgot Password flow backend integration के बाद activate होगा.',
    AppLanguage.english =>
      'Forgot Password flow will activate after backend integration.',
  };

  String get permissionsTitle => switch (language) {
    AppLanguage.telugu => 'కొన్ని అనుమతులు అవసరం',
    AppLanguage.hindi => 'कुछ permissions आवश्यक हैं',
    AppLanguage.english => 'A few permissions are needed',
  };

  String get permissionsSubtitle => switch (language) {
    AppLanguage.telugu =>
      'ఫోటోలు ఎంచుకోవడానికి, పోస్టర్లు సేవ్ చేయడానికి, ముఖ్యమైన అప్‌డేట్స్ తెలుసుకోవడానికి permissions అవసరం.',
    AppLanguage.hindi =>
      'फोटो चुनने, पोस्टर सेव करने और महत्वपूर्ण अपडेट पाने के लिए permissions चाहिए.',
    AppLanguage.english =>
      'Permissions are needed to choose photos, save posters, and receive important updates.',
  };

  String get photosGallery => switch (language) {
    AppLanguage.telugu => 'Photos/Gallery',
    AppLanguage.hindi => 'Photos/Gallery',
    AppLanguage.english => 'Photos/Gallery',
  };

  String get notifications => switch (language) {
    AppLanguage.telugu => 'Notifications',
    AppLanguage.hindi => 'Notifications',
    AppLanguage.english => 'Notifications',
  };

  String get enableLaterHint => switch (language) {
    AppLanguage.telugu =>
      'మీరు తర్వాత Settings లో కూడా permissions enable చేయవచ్చు.',
    AppLanguage.hindi =>
      'आप बाद में Settings में भी permissions enable कर सकते हैं.',
    AppLanguage.english =>
      'You can enable permissions later from Settings as well.',
  };

  String get allowLabel => switch (language) {
    AppLanguage.telugu => 'అనుమతించండి',
    AppLanguage.hindi => 'अनुमति दें',
    AppLanguage.english => 'Allow',
  };

  String get laterLabel => switch (language) {
    AppLanguage.telugu => 'తర్వాత చూద్దాం',
    AppLanguage.hindi => 'बाद में देखेंगे',
    AppLanguage.english => 'Later',
  };

  String get homeTagline => switch (language) {
    AppLanguage.telugu => 'Create & Share',
    AppLanguage.hindi => 'Create & Share',
    AppLanguage.english => 'Create & Share',
  };

  String get createLabel => switch (language) {
    AppLanguage.telugu => 'Create',
    AppLanguage.hindi => 'Create',
    AppLanguage.english => 'Create',
  };

  String get searchTemplates => switch (language) {
    AppLanguage.telugu => 'Search templates',
    AppLanguage.hindi => 'Search templates',
    AppLanguage.english => 'Search templates',
  };

  String get bannerTitle => switch (language) {
    AppLanguage.telugu => 'Mana Poster Featured Banner',
    AppLanguage.hindi => 'Mana Poster Featured Banner',
    AppLanguage.english => 'Mana Poster Featured Banner',
  };

  String get freeTab => switch (language) {
    AppLanguage.telugu => 'Free',
    AppLanguage.hindi => 'Free',
    AppLanguage.english => 'Free',
  };

  String get premiumTab => switch (language) {
    AppLanguage.telugu => 'Premium',
    AppLanguage.hindi => 'Premium',
    AppLanguage.english => 'Premium',
  };

  String get buyLabel => switch (language) {
    AppLanguage.telugu => 'Buy',
    AppLanguage.hindi => 'Buy',
    AppLanguage.english => 'Buy',
  };

  String get shareWhatsApp => switch (language) {
    AppLanguage.telugu => 'Share WhatsApp',
    AppLanguage.hindi => 'Share WhatsApp',
    AppLanguage.english => 'Share WhatsApp',
  };

  String get downloadLabel => switch (language) {
    AppLanguage.telugu => 'Download',
    AppLanguage.hindi => 'Download',
    AppLanguage.english => 'Download',
  };

  String get profileTitle => switch (language) {
    AppLanguage.telugu => 'Profile & Settings',
    AppLanguage.hindi => 'Profile & Settings',
    AppLanguage.english => 'Profile & Settings',
  };

  String get accountSection => switch (language) {
    AppLanguage.telugu => 'Account',
    AppLanguage.hindi => 'Account',
    AppLanguage.english => 'Account',
  };

  String get appSettingsSection => switch (language) {
    AppLanguage.telugu => 'App Settings',
    AppLanguage.hindi => 'App Settings',
    AppLanguage.english => 'App Settings',
  };

  String get supportSection => switch (language) {
    AppLanguage.telugu => 'Support',
    AppLanguage.hindi => 'Support',
    AppLanguage.english => 'Support',
  };

  String get languageOption => switch (language) {
    AppLanguage.telugu => 'Language',
    AppLanguage.hindi => 'Language',
    AppLanguage.english => 'Language',
  };

  String get languageOptionSubtitle => switch (language) {
    AppLanguage.telugu => 'మీ app భాషను ఎంచుకోండి',
    AppLanguage.hindi => 'अपनी app language चुनें',
    AppLanguage.english => 'Choose your app language',
  };

  String get subscriptionOption => switch (language) {
    AppLanguage.telugu => 'Subscription / Plans',
    AppLanguage.hindi => 'Subscription / Plans',
    AppLanguage.english => 'Subscription / Plans',
  };

  String get subscriptionSubtitle => switch (language) {
    AppLanguage.telugu => 'ప్రస్తుతం ఉన్న plan మరియు upgrades',
    AppLanguage.hindi => 'Current plan और upgrades manage करें',
    AppLanguage.english => 'Manage current plan and upgrades',
  };

  String get permissionsOptionSubtitle => switch (language) {
    AppLanguage.telugu => 'Photos, storage మరియు ఇతర access',
    AppLanguage.hindi => 'Photos, storage और other access',
    AppLanguage.english => 'Photos, storage and other access',
  };

  String get notificationsOptionSubtitle => switch (language) {
    AppLanguage.telugu => 'Alerts మరియు updates నియంత్రించండి',
    AppLanguage.hindi => 'Alerts और updates नियंत्रित करें',
    AppLanguage.english => 'Control alerts and updates',
  };

  String get helpSupport => switch (language) {
    AppLanguage.telugu => 'Help & Support',
    AppLanguage.hindi => 'Help & Support',
    AppLanguage.english => 'Help & Support',
  };

  String get helpSupportSubtitle => switch (language) {
    AppLanguage.telugu => 'సహాయం పొందండి మరియు support ను సంప్రదించండి',
    AppLanguage.hindi => 'मदद लें और support से संपर्क करें',
    AppLanguage.english => 'Get help and contact support',
  };

  String get aboutApp => switch (language) {
    AppLanguage.telugu => 'About App',
    AppLanguage.hindi => 'About App',
    AppLanguage.english => 'About App',
  };

  String get aboutAppSubtitle => switch (language) {
    AppLanguage.telugu => 'App వివరాలు మరియు version సమాచారం',
    AppLanguage.hindi => 'App details और version info',
    AppLanguage.english => 'App details and version info',
  };

  String get logout => switch (language) {
    AppLanguage.telugu => 'Logout',
    AppLanguage.hindi => 'Logout',
    AppLanguage.english => 'Logout',
  };

  String get logoutSubtitle => switch (language) {
    AppLanguage.telugu => 'Sign out logic తర్వాత connect అవుతుంది',
    AppLanguage.hindi => 'Sign out logic बाद में connect होगी',
    AppLanguage.english => 'Sign out logic can be connected later',
  };

  String get languageSettingsTitle => switch (language) {
    AppLanguage.telugu => 'Language Settings',
    AppLanguage.hindi => 'Language Settings',
    AppLanguage.english => 'Language Settings',
  };

  String get currentLanguageLabel => switch (language) {
    AppLanguage.telugu => 'Current language',
    AppLanguage.hindi => 'Current language',
    AppLanguage.english => 'Current language',
  };

  String get saveApply => switch (language) {
    AppLanguage.telugu => 'Save / Apply',
    AppLanguage.hindi => 'Save / Apply',
    AppLanguage.english => 'Save / Apply',
  };

  String languageName(AppLanguage value) => switch (value) {
    AppLanguage.telugu => 'తెలుగు',
    AppLanguage.hindi => 'हिन्दी',
    AppLanguage.english => 'English',
  };

  List<String> homeCategories() => switch (language) {
    AppLanguage.telugu => const <String>[
      'All',
      '🌙 Good Night',
      '🌅 Good Morning',
      '💪 Motivational',
      '❤️ Love Quotes',
      '✨ Today Special',
      '🎂 Birthdays',
      '🌿 జీవిత సలహాలు',
      '📖 గీతోపదేశం',
      '📰 News',
      '🙏 Devotional',
      '🏹 మహా భారతం',
      '💍 వార్షికోత్సవం',
      '💭 మంచి ఆలోచనలు',
      '✝️ బైబిల్',
      '☪️ ఇస్లాం',
      '🆕 New',
    ],
    AppLanguage.hindi => const <String>[
      'All',
      '🌙 Good Night',
      '🌅 Good Morning',
      '💪 Motivational',
      '❤️ Love Quotes',
      '✨ Today Special',
      '🎂 Birthdays',
      '🌿 जीवन सलाह',
      '📖 गीता उपदेश',
      '📰 News',
      '🙏 Devotional',
      '🏹 महाभारत',
      '💍 वर्षगाँठ',
      '💭 अच्छे विचार',
      '✝️ बाइबल',
      '☪️ इस्लाम',
      '🆕 New',
    ],
    AppLanguage.english => const <String>[
      'All',
      '🌙 Good Night',
      '🌅 Good Morning',
      '💪 Motivational',
      '❤️ Love Quotes',
      '✨ Today Special',
      '🎂 Birthdays',
      '🌿 Life Advice',
      '📖 Gita Wisdom',
      '📰 News',
      '🙏 Devotional',
      '🏹 Mahabharata',
      '💍 Anniversary',
      '💭 Good Thoughts',
      '✝️ Bible',
      '☪️ Islam',
      '🆕 New',
    ],
  };
}
