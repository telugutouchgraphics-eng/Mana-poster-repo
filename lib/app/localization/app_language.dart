import 'dart:convert';

import 'package:flutter/material.dart';

enum AppLanguage {
  telugu,
  hindi,
  english,
  tamil,
  kannada,
  malayalam,
  assamese,
  konkani,
  gujarati,
  marathi,
  meitei,
  mizo,
  odia,
  punjabi,
  nepali,
  bengali,
  kashmiri,
  ladakhi,
}

enum SupportedUiLanguage { telugu, hindi, english, tamil, kannada, malayalam }

extension AppLanguageSupportX on AppLanguage {
  SupportedUiLanguage get supportedUiLanguage {
    return switch (this) {
      AppLanguage.telugu => SupportedUiLanguage.telugu,
      AppLanguage.hindi => SupportedUiLanguage.hindi,
      AppLanguage.english => SupportedUiLanguage.english,
      AppLanguage.tamil => SupportedUiLanguage.tamil,
      AppLanguage.kannada => SupportedUiLanguage.kannada,
      AppLanguage.malayalam => SupportedUiLanguage.malayalam,
      AppLanguage.assamese ||
      AppLanguage.konkani ||
      AppLanguage.meitei ||
      AppLanguage.mizo ||
      AppLanguage.odia ||
      AppLanguage.bengali => SupportedUiLanguage.english,
      AppLanguage.gujarati ||
      AppLanguage.marathi ||
      AppLanguage.punjabi ||
      AppLanguage.nepali ||
      AppLanguage.kashmiri ||
      AppLanguage.ladakhi => SupportedUiLanguage.hindi,
    };
  }
}

const Map<AppLanguage, Map<String, String>>
_regionalCommonFallbacks = <AppLanguage, Map<String, String>>{
  AppLanguage.assamese: <String, String>{
    'Select State / Union Territory': 'ৰাজ্য / কেন্দ্ৰীয় শাসিত অঞ্চল বাছক',
    'Search State, UT or language':
        'ৰাজ্য, কেন্দ্ৰীয় অঞ্চল বা ভাষা সন্ধান কৰক',
    'No matching region found.': 'মিল থকা অঞ্চল পোৱা নগল।',
    'Political Parties': 'ৰাজনৈতিক দলসমূহ',
    'National': 'ৰাষ্ট্ৰীয়',
    'State': 'ৰাজ্য',
    'Continue': 'আগবাঢ়ক',
    'Login': 'লগইন',
    'Sign Up': 'চাইন আপ',
    'Continue with Google': 'Google-ৰ সৈতে আগবাঢ়ক',
    'Email address': 'ইমেইল ঠিকনা',
    'Password': 'পাছৱৰ্ড',
    'Forgot Password': 'পাছৱৰ্ড পাহৰিলে?',
    "Don't have an account?": 'একাউণ্ট নাই?',
    'Already have an account?': 'আগতে একাউণ্ট আছে?',
    'Login with Email': 'ইমেইলেৰে লগইন কৰক',
    'Sign Up with Email': 'ইমেইলেৰে চাইন আপ কৰক',
    'Create & Share': 'সৃষ্টি কৰক আৰু শ্বেয়াৰ কৰক',
    'Create': 'সৃষ্টি কৰক',
    'Search templates': 'টেমপ্লেট সন্ধান কৰক',
    'Profile & Settings': 'প্ৰফাইল আৰু ছেটিংছ',
    'Language': 'ভাষা',
    'Logout': 'লগআউট',
    'Download': 'ডাউনলোড',
    'Share': 'শ্বেয়াৰ',
  },
  AppLanguage.konkani: <String, String>{
    'Select State / Union Territory': 'राज्य / केंद्रशासित प्रदेश निवडात',
    'Search State, UT or language': 'राज्य, प्रदेश वा भास सोदात',
    'No matching region found.': 'जुळपी प्रदेश मेळूंक ना.',
    'Political Parties': 'राजकीय पक्ष',
    'National': 'राष्ट्रीय',
    'State': 'राज्य',
    'Continue': 'फुडें वचात',
    'Login': 'लॉगिन',
    'Sign Up': 'साइन अप',
    'Continue with Google': 'Google वरवीं फुडें वचात',
    'Email address': 'ईमेल पत्तो',
    'Password': 'पासवर्ड',
    'Forgot Password': 'पासवर्ड विसरलात?',
    "Don't have an account?": 'खातें ना?',
    'Already have an account?': 'आदिंच खातें आसा?',
    'Login with Email': 'ईमेल वरवीं लॉगिन करात',
    'Sign Up with Email': 'ईमेल वरवीं साइन अप करात',
    'Create & Share': 'तयार करात आनी शेअर करात',
    'Create': 'तयार करात',
    'Search templates': 'टेम्प्लेट सोदात',
    'Profile & Settings': 'प्रोफाइल आनी सेटिंग्स',
    'Language': 'भास',
    'Logout': 'लॉगआउट',
    'Download': 'डाउनलोड',
    'Share': 'शेअर',
  },
  AppLanguage.gujarati: <String, String>{
    'Select State / Union Territory': 'રાજ્ય / કેન્દ્રશાસિત પ્રદેશ પસંદ કરો',
    'Search State, UT or language': 'રાજ્ય, પ્રદેશ અથવા ભાષા શોધો',
    'No matching region found.': 'મેળ ખાતો પ્રદેશ મળ્યો નથી.',
    'Political Parties': 'રાજકીય પક્ષો',
    'National': 'રાષ્ટ્રીય',
    'State': 'રાજ્ય',
    'Continue': 'આગળ વધો',
    'Login': 'લોગિન',
    'Sign Up': 'સાઇન અપ',
    'Continue with Google': 'Google સાથે આગળ વધો',
    'Email address': 'ઇમેઇલ સરનામું',
    'Password': 'પાસવર્ડ',
    'Forgot Password': 'પાસવર્ડ ભૂલી ગયા?',
    "Don't have an account?": 'એકાઉન્ટ નથી?',
    'Already have an account?': 'પહેલેથી એકાઉન્ટ છે?',
    'Login with Email': 'ઇમેઇલથી લોગિન કરો',
    'Sign Up with Email': 'ઇમેઇલથી સાઇન અપ કરો',
    'Create & Share': 'બનાવો અને શેર કરો',
    'Create': 'બનાવો',
    'Search templates': 'ટેમ્પ્લેટ શોધો',
    'Profile & Settings': 'પ્રોફાઇલ અને સેટિંગ્સ',
    'Language': 'ભાષા',
    'Logout': 'લોગઆઉટ',
    'Download': 'ડાઉનલોડ',
    'Share': 'શેર',
  },
  AppLanguage.marathi: <String, String>{
    'Select State / Union Territory': 'राज्य / केंद्रशासित प्रदेश निवडा',
    'Search State, UT or language': 'राज्य, प्रदेश किंवा भाषा शोधा',
    'No matching region found.': 'जुळणारा प्रदेश सापडला नाही.',
    'Political Parties': 'राजकीय पक्ष',
    'National': 'राष्ट्रीय',
    'State': 'राज्य',
    'Continue': 'पुढे जा',
    'Login': 'लॉगिन',
    'Sign Up': 'साइन अप',
    'Continue with Google': 'Google सह पुढे जा',
    'Email address': 'ईमेल पत्ता',
    'Password': 'पासवर्ड',
    'Forgot Password': 'पासवर्ड विसरलात?',
    "Don't have an account?": 'खाते नाही?',
    'Already have an account?': 'आधीच खाते आहे?',
    'Login with Email': 'ईमेलने लॉगिन करा',
    'Sign Up with Email': 'ईमेलने साइन अप करा',
    'Create & Share': 'तयार करा आणि शेअर करा',
    'Create': 'तयार करा',
    'Search templates': 'टेम्प्लेट शोधा',
    'Profile & Settings': 'प्रोफाइल आणि सेटिंग्स',
    'Language': 'भाषा',
    'Logout': 'लॉगआउट',
    'Download': 'डाउनलोड',
    'Share': 'शेअर',
  },
  AppLanguage.meitei: <String, String>{
    'Select State / Union Territory': 'State / Union Territory খনবিয়ু',
    'Search State, UT or language': 'State, UT নত্রগা লোল থিয়ু',
    'No matching region found.': 'চপ মান্নবা region ফংদ্রে।',
    'Political Parties': 'Political Parties',
    'National': 'National',
    'State': 'State',
    'Continue': 'মখা চত্থরো',
    'Login': 'লগইন',
    'Sign Up': 'সাইন আপ',
    'Continue with Google': 'Google গা মখা চত্থরো',
    'Email address': 'ইমেইল এড্রেস',
    'Password': 'পাসৱার্ড',
    'Forgot Password': 'পাসৱার্ড কাউখ্রে?',
    "Don't have an account?": 'একাউন্ট লৈত্রা?',
    'Already have an account?': 'একাউন্ট লৈরে?',
    'Login with Email': 'ইমেইলদা লগইন তৌরো',
    'Sign Up with Email': 'ইমেইলদা সাইন আপ তৌরো',
    'Create & Share': 'শেম্মু অমসুং share তৌরো',
    'Create': 'শেম্মু',
    'Search templates': 'Template থিয়ু',
    'Profile & Settings': 'Profile অমসুং Settings',
    'Language': 'লোল',
    'Logout': 'লগআউট',
    'Download': 'ডাউনলোড',
    'Share': 'শেয়ার',
  },
  AppLanguage.mizo: <String, String>{
    'Select State / Union Territory': 'State / Union Territory thlang rawh',
    'Search State, UT or language': 'State, UT emaw tawng zawng rawh',
    'No matching region found.': 'Region inang a awm lo.',
    'Political Parties': 'Political Parties',
    'National': 'National',
    'State': 'State',
    'Continue': 'Chhunzawm rawh',
    'Login': 'Login',
    'Sign Up': 'Sign Up',
    'Continue with Google': 'Google hmangin chhunzawm rawh',
    'Email address': 'Email address',
    'Password': 'Password',
    'Forgot Password': 'Password i theihnghilh?',
    "Don't have an account?": 'Account i nei lo?',
    'Already have an account?': 'Account i nei tawh?',
    'Login with Email': 'Email hmangin login rawh',
    'Sign Up with Email': 'Email hmangin sign up rawh',
    'Create & Share': 'Siam la share rawh',
    'Create': 'Siam',
    'Search templates': 'Template zawng rawh',
    'Profile & Settings': 'Profile & Settings',
    'Language': 'Tawng',
    'Logout': 'Logout',
    'Download': 'Download',
    'Share': 'Share',
  },
  AppLanguage.odia: <String, String>{
    'Select State / Union Territory': 'ରାଜ୍ୟ / କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ ବାଛନ୍ତୁ',
    'Search State, UT or language': 'ରାଜ୍ୟ, ଅଞ୍ଚଳ କିମ୍ବା ଭାଷା ଖୋଜନ୍ତୁ',
    'No matching region found.': 'ମେଳ ଥିବା ଅଞ୍ଚଳ ମିଳିଲା ନାହିଁ।',
    'Political Parties': 'ରାଜନୈତିକ ଦଳ',
    'National': 'ଜାତୀୟ',
    'State': 'ରାଜ୍ୟ',
    'Continue': 'ଜାରି ରଖନ୍ତୁ',
    'Login': 'ଲଗଇନ',
    'Sign Up': 'ସାଇନ୍ ଅପ୍',
    'Continue with Google': 'Google ସହିତ ଜାରି ରଖନ୍ତୁ',
    'Email address': 'ଇମେଲ୍ ଠିକଣା',
    'Password': 'ପାସୱାର୍ଡ',
    'Forgot Password': 'ପାସୱାର୍ଡ ଭୁଲିଗଲେ?',
    "Don't have an account?": 'ଆକାଉଣ୍ଟ ନାହିଁ?',
    'Already have an account?': 'ପୂର୍ବରୁ ଆକାଉଣ୍ଟ ଅଛି?',
    'Login with Email': 'ଇମେଲ୍ ସହିତ ଲଗଇନ କରନ୍ତୁ',
    'Sign Up with Email': 'ଇମେଲ୍ ସହିତ ସାଇନ୍ ଅପ୍ କରନ୍ତୁ',
    'Create & Share': 'ତିଆରି କରନ୍ତୁ ଓ ସେୟାର କରନ୍ତୁ',
    'Create': 'ତିଆରି କରନ୍ତୁ',
    'Search templates': 'ଟେମ୍ପଲେଟ୍ ଖୋଜନ୍ତୁ',
    'Profile & Settings': 'ପ୍ରୋଫାଇଲ୍ ଓ ସେଟିଂସ୍',
    'Language': 'ଭାଷା',
    'Logout': 'ଲଗଆଉଟ୍',
    'Download': 'ଡାଉନଲୋଡ୍',
    'Share': 'ସେୟାର',
  },
  AppLanguage.punjabi: <String, String>{
    'Select State / Union Territory': 'ਰਾਜ / ਕੇਂਦਰ ਸ਼ਾਸਿਤ ਪ੍ਰਦੇਸ਼ ਚੁਣੋ',
    'Search State, UT or language': 'ਰਾਜ, ਪ੍ਰਦੇਸ਼ ਜਾਂ ਭਾਸ਼ਾ ਖੋਜੋ',
    'No matching region found.': 'ਮਿਲਦਾ ਖੇਤਰ ਨਹੀਂ ਮਿਲਿਆ।',
    'Political Parties': 'ਰਾਜਨੀਤਿਕ ਪਾਰਟੀਆਂ',
    'National': 'ਰਾਸ਼ਟਰੀ',
    'State': 'ਰਾਜ',
    'Continue': 'ਜਾਰੀ ਰੱਖੋ',
    'Login': 'ਲਾਗਇਨ',
    'Sign Up': 'ਸਾਇਨ ਅਪ',
    'Continue with Google': 'Google ਨਾਲ ਜਾਰੀ ਰੱਖੋ',
    'Email address': 'ਈਮੇਲ ਪਤਾ',
    'Password': 'ਪਾਸਵਰਡ',
    'Forgot Password': 'ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?',
    "Don't have an account?": 'ਖਾਤਾ ਨਹੀਂ ਹੈ?',
    'Already have an account?': 'ਪਹਿਲਾਂ ਹੀ ਖਾਤਾ ਹੈ?',
    'Login with Email': 'ਈਮੇਲ ਨਾਲ ਲਾਗਇਨ ਕਰੋ',
    'Sign Up with Email': 'ਈਮੇਲ ਨਾਲ ਸਾਇਨ ਅਪ ਕਰੋ',
    'Create & Share': 'ਬਣਾਓ ਅਤੇ ਸਾਂਝਾ ਕਰੋ',
    'Create': 'ਬਣਾਓ',
    'Search templates': 'ਟੈਂਪਲੇਟ ਖੋਜੋ',
    'Profile & Settings': 'ਪ੍ਰੋਫਾਈਲ ਅਤੇ ਸੈਟਿੰਗਾਂ',
    'Language': 'ਭਾਸ਼ਾ',
    'Logout': 'ਲਾਗਆਉਟ',
    'Download': 'ਡਾਊਨਲੋਡ',
    'Share': 'ਸਾਂਝਾ ਕਰੋ',
  },
  AppLanguage.nepali: <String, String>{
    'Select State / Union Territory': 'राज्य / केन्द्र शासित प्रदेश छान्नुहोस्',
    'Search State, UT or language': 'राज्य, प्रदेश वा भाषा खोज्नुहोस्',
    'No matching region found.': 'मिल्दो क्षेत्र भेटिएन।',
    'Political Parties': 'राजनीतिक दलहरू',
    'National': 'राष्ट्रिय',
    'State': 'राज्य',
    'Continue': 'जारी राख्नुहोस्',
    'Login': 'लगइन',
    'Sign Up': 'साइन अप',
    'Continue with Google': 'Google सँग जारी राख्नुहोस्',
    'Email address': 'इमेल ठेगाना',
    'Password': 'पासवर्ड',
    'Forgot Password': 'पासवर्ड बिर्सनुभयो?',
    "Don't have an account?": 'खाता छैन?',
    'Already have an account?': 'पहिले नै खाता छ?',
    'Login with Email': 'इमेलबाट लगइन गर्नुहोस्',
    'Sign Up with Email': 'इमेलबाट साइन अप गर्नुहोस्',
    'Create & Share': 'बनाउनुहोस् र शेयर गर्नुहोस्',
    'Create': 'बनाउनुहोस्',
    'Search templates': 'टेम्प्लेट खोज्नुहोस्',
    'Profile & Settings': 'प्रोफाइल र सेटिङहरू',
    'Language': 'भाषा',
    'Logout': 'लगआउट',
    'Download': 'डाउनलोड',
    'Share': 'शेयर',
  },
  AppLanguage.bengali: <String, String>{
    'Select State / Union Territory':
        'রাজ্য / কেন্দ্রশাসিত অঞ্চল নির্বাচন করুন',
    'Search State, UT or language': 'রাজ্য, কেন্দ্রশাসিত অঞ্চল বা ভাষা খুঁজুন',
    'No matching region found.': 'মিল থাকা অঞ্চল পাওয়া যায়নি।',
    'Political Parties': 'রাজনৈতিক দল',
    'National': 'জাতীয়',
    'State': 'রাজ্য',
    'Continue': 'চালিয়ে যান',
    'Login': 'লগইন',
    'Sign Up': 'সাইন আপ',
    'Continue with Google': 'Google দিয়ে চালিয়ে যান',
    'Email address': 'ইমেল ঠিকানা',
    'Password': 'পাসওয়ার্ড',
    'Forgot Password': 'পাসওয়ার্ড ভুলে গেছেন?',
    "Don't have an account?": 'অ্যাকাউন্ট নেই?',
    'Already have an account?': 'আগেই অ্যাকাউন্ট আছে?',
    'Login with Email': 'ইমেল দিয়ে লগইন করুন',
    'Sign Up with Email': 'ইমেল দিয়ে সাইন আপ করুন',
    'Create & Share': 'তৈরি করুন ও শেয়ার করুন',
    'Create': 'তৈরি করুন',
    'Search templates': 'টেমপ্লেট খুঁজুন',
    'Profile & Settings': 'প্রোফাইল ও সেটিংস',
    'Language': 'ভাষা',
    'Logout': 'লগআউট',
    'Download': 'ডাউনলোড',
    'Share': 'শেয়ার',
  },
  AppLanguage.kashmiri: <String, String>{
    'Select State / Union Territory': 'ریاست / یونین ٹیریٹری منتخب کریں',
    'Search State, UT or language': 'ریاست، علاقہ یا زبان تلاش کریں',
    'No matching region found.': 'کوئی ملتا جلتا علاقہ نہیں ملا۔',
    'Political Parties': 'سیاسی جماعتیں',
    'National': 'قومی',
    'State': 'ریاست',
    'Continue': 'جاری رکھیں',
    'Login': 'لاگ ان',
    'Sign Up': 'سائن اپ',
    'Continue with Google': 'Google کے ساتھ جاری رکھیں',
    'Email address': 'ای میل پتہ',
    'Password': 'پاس ورڈ',
    'Forgot Password': 'پاس ورڈ بھول گئے؟',
    "Don't have an account?": 'اکاؤنٹ نہیں ہے؟',
    'Already have an account?': 'پہلے سے اکاؤنٹ ہے؟',
    'Login with Email': 'ای میل سے لاگ ان کریں',
    'Sign Up with Email': 'ای میل سے سائن اپ کریں',
    'Create & Share': 'بنائیں اور شیئر کریں',
    'Create': 'بنائیں',
    'Search templates': 'ٹیمپلیٹس تلاش کریں',
    'Profile & Settings': 'پروفائل اور سیٹنگز',
    'Language': 'زبان',
    'Logout': 'لاگ آؤٹ',
    'Download': 'ڈاؤن لوڈ',
    'Share': 'شیئر',
  },
  AppLanguage.ladakhi: <String, String>{
    'Select State / Union Territory': 'State / Union Territory འདེམས',
    'Search State, UT or language': 'State, UT ཡང་ན language འཚོལ',
    'No matching region found.': 'མཐུན་པའི་ས་ཁུལ་མ་རྙེད།',
    'Political Parties': 'Political Parties',
    'National': 'National',
    'State': 'State',
    'Continue': 'མུ་མཐུད',
    'Login': 'Login',
    'Sign Up': 'Sign Up',
    'Continue with Google': 'Google དང་མུ་མཐུད',
    'Email address': 'Email address',
    'Password': 'Password',
    'Forgot Password': 'Password བརྗེད་སོང?',
    "Don't have an account?": 'Account མེད?',
    'Already have an account?': 'Account ཡོད?',
    'Login with Email': 'Email གིས login',
    'Sign Up with Email': 'Email གིས sign up',
    'Create & Share': 'Create & Share',
    'Create': 'Create',
    'Search templates': 'Template འཚོལ',
    'Profile & Settings': 'Profile & Settings',
    'Language': 'Language',
    'Logout': 'Logout',
    'Download': 'Download',
    'Share': 'Share',
  },
};

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

class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.language,
    required AppLanguageController controller,
    required super.child,
  }) : _controller = controller;

  final AppLanguage language;
  final AppLanguageController _controller;

  static final AppLanguageController _fallbackController =
      AppLanguageController();

  static AppLanguageScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found in widget tree.');
    return scope!;
  }

  static AppLanguageScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
  }

  AppLanguageController get controller => _controller;

  @override
  bool updateShouldNotify(covariant AppLanguageScope oldWidget) {
    return oldWidget.language != language ||
        oldWidget._controller != _controller;
  }
}

extension AppLanguageContextX on BuildContext {
  AppLanguageController get languageController =>
      AppLanguageScope.maybeOf(this)?.controller ??
      AppLanguageScope._fallbackController;
  AppLanguage get currentLanguage =>
      AppLanguageScope.maybeOf(this)?.language ?? AppLanguage.telugu;
  AppStrings get strings => AppStrings(currentLanguage);
}

mixin AppLanguageStateMixin<T extends StatefulWidget> on State<T> {
  AppLanguageController? _appLanguageController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.languageController;
    if (_appLanguageController == controller) {
      return;
    }
    _appLanguageController?.removeListener(_handleAppLanguageChanged);
    _appLanguageController = controller;
    _appLanguageController?.addListener(_handleAppLanguageChanged);
  }

  void _handleAppLanguageChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _appLanguageController?.removeListener(_handleAppLanguageChanged);
    super.dispose();
  }
}

const Map<String, String> _landingHindiFallbacks = <String, String>{
  'Home': '\u0939\u094b\u092e',
  'Features': '\u092b\u093c\u0940\u091a\u0930\u094d\u0938',
  'Categories': '\u0915\u0948\u091f\u0947\u0917\u0930\u0940',
  'Download': '\u0921\u093e\u0909\u0928\u0932\u094b\u0921',
  'Admin Login':
      '\u090f\u0921\u092e\u093f\u0928 \u0932\u0949\u0917\u093f\u0928',
  'Sign Out': '\u0938\u093e\u0907\u0928 \u0906\u0909\u091f',
  'Get App': '\u0910\u092a \u092a\u093e\u090f\u0902',
  'Ready Telugu templates':
      '\u0924\u0948\u092f\u093e\u0930 \u0924\u0947\u0932\u0941\u0917\u0941 \u091f\u0947\u092e\u094d\u092a\u0932\u0947\u091f\u094d\u0938',
  'Start fast with reusable layouts for daily poster needs.':
      '\u0930\u094b\u091c\u093c\u093e\u0928\u093e \u092a\u094b\u0938\u094d\u091f\u0930 \u091c\u093c\u0930\u0942\u0930\u0924\u094b\u0902 \u0915\u0947 \u0932\u093f\u090f reusable layouts \u0915\u0947 \u0938\u093e\u0925 \u091c\u0932\u094d\u0926\u0940 \u0936\u0941\u0930\u0942 \u0915\u0930\u0947\u0902\u0964',
  'Photo + name personalization':
      '\u092b\u094b\u091f\u094b + \u0928\u093e\u092e \u092a\u0930\u094d\u0938\u0928\u0932\u093e\u0907\u091c\u093c\u0947\u0936\u0928',
  'Update poster identity quickly without redesigning everything.':
      '\u092a\u0942\u0930\u093e \u0921\u093f\u091c\u093c\u093e\u0907\u0928 \u092c\u0926\u0932\u0947 \u092c\u093f\u0928\u093e \u092a\u094b\u0938\u094d\u091f\u0930 \u0935\u093f\u0935\u0930\u0923 \u091c\u0932\u094d\u0926\u0940 \u0905\u092a\u0921\u0947\u091f \u0915\u0930\u0947\u0902\u0964',
  'Fast sharing flow':
      '\u0924\u0947\u091c\u093c \u0936\u0947\u092f\u0930\u093f\u0902\u0917 \u092b\u094d\u0932\u094b',
  'Export and share in a few taps for WhatsApp-first usage.':
      'WhatsApp-first \u0909\u092a\u092f\u094b\u0917 \u0915\u0947 \u0932\u093f\u090f \u0915\u0941\u091b taps \u092e\u0947\u0902 export \u0914\u0930 share \u0915\u0930\u0947\u0902\u0964',
  'Poster design mix':
      '\u092b\u094d\u0930\u0940 \u0914\u0930 \u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u092e\u093f\u0915\u094d\u0938',
  'Keep poster discovery open while design quality stays clear.':
      '\u092b\u094d\u0930\u0940 \u0921\u093f\u0938\u094d\u0915\u0935\u0930\u0940 \u0916\u0941\u0932\u0940 \u0930\u0916\u0947\u0902 \u0914\u0930 \u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u0921\u093f\u091c\u093c\u093e\u0907\u0928 \u0915\u094d\u0935\u093e\u0932\u093f\u091f\u0940 \u0938\u093e\u092b\u093c \u0926\u093f\u0916\u093e\u090f\u0901\u0964',
  'Festival posters':
      '\u0924\u094d\u092f\u094b\u0939\u093e\u0930 \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938',
  'Date-based festival content can stay discoverable without manual browsing.':
      '\u0924\u093e\u0930\u0940\u0916\u093c \u0915\u0947 \u0939\u093f\u0938\u093e\u092c \u0938\u0947 \u0924\u094d\u092f\u094b\u0939\u093e\u0930 \u0915\u0902\u091f\u0947\u0902\u091f \u092c\u093f\u0928\u093e manual browsing \u0915\u0947 \u0926\u093f\u0916 \u0938\u0915\u0924\u093e \u0939\u0948\u0964',
  'National days':
      '\u0930\u093e\u0937\u094d\u091f\u094d\u0930\u0940\u092f \u0926\u093f\u0935\u0938',
  'Important observances are easier to surface when the day matters.':
      '\u091c\u093c\u0930\u0942\u0930\u0940 observances \u0938\u0939\u0940 \u0926\u093f\u0928 \u092a\u0930 \u0906\u0938\u093e\u0928\u0940 \u0938\u0947 \u0926\u093f\u0916\u0924\u0947 \u0939\u0948\u0902\u0964',
  'Local event updates':
      '\u0932\u094b\u0915\u0932 \u0907\u0935\u0947\u0902\u091f \u0905\u092a\u0921\u0947\u091f\u094d\u0938',
  'Telugu state relevance stays visible in one dedicated block.':
      '\u0924\u0947\u0932\u0941\u0917\u0941 \u0930\u093e\u091c\u094d\u092f\u094b\u0902 \u0938\u0947 \u091c\u0941\u0921\u093c\u093e \u0915\u0902\u091f\u0947\u0902\u091f \u090f\u0915 dedicated block \u092e\u0947\u0902 \u0926\u093f\u0916\u0924\u093e \u0930\u0939\u0924\u093e \u0939\u0948\u0964',
  'Free Posters':
      '\u092b\u094d\u0930\u0940 \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938',
  'Starter': '\u0938\u094d\u091f\u093e\u0930\u094d\u091f\u0930',
  'Basic templates':
      '\u092c\u0947\u0938\u093f\u0915 \u091f\u0947\u092e\u094d\u092a\u0932\u0947\u091f\u094d\u0938',
  'Quick sharing':
      '\u0915\u094d\u0935\u093f\u0915 \u0936\u0947\u092f\u0930\u093f\u0902\u0917',
  'Simple export':
      '\u0938\u093f\u0902\u092a\u0932 \u090f\u0915\u094d\u0938\u092a\u094b\u0930\u094d\u091f',
  'Featured Posters':
      '\u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938',
  'Pro Access': '\u092a\u094d\u0930\u094b \u090f\u0915\u094d\u0938\u0947\u0938',
  'Fully editable posters':
      '\u092a\u0942\u0930\u0940 \u0924\u0930\u0939 editable \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938',
  'More templates':
      '\u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u091f\u0947\u092e\u094d\u092a\u0932\u0947\u091f\u094d\u0938',
  'Unlimited customization':
      '\u0905\u0928\u0932\u093f\u092e\u093f\u091f\u0947\u0921 \u0915\u0938\u094d\u091f\u092e\u093e\u0907\u091c\u093c\u0947\u0936\u0928',
  'HD export': 'HD \u090f\u0915\u094d\u0938\u092a\u094b\u0930\u094d\u091f',
  'Is Mana Poster Ai AI free?': 'क्या Mana Poster Ai AI फ्री है?',
  'Posters are available with stronger templates and deeper editing inside the app.':
      '\u0906\u092a \u092e\u0947\u0902 posters \u092c\u0928\u093e\u0928\u0947, personalize \u0915\u0930\u0928\u0947 \u0914\u0930 share \u0915\u0930\u0928\u0947 \u0915\u0947 \u0938\u0930\u0932 options \u0909\u092a\u0932\u092c\u094d\u0927 \u0939\u0948\u0902\u0964',
  'Can I add photo and name?': 'क्या मैं फोटो और नाम जोड़ सकता हूँ?',
  'Yes. Personal details can be placed directly on poster templates.':
      '\u0939\u093e\u0901\u0964 \u0935\u094d\u092f\u0915\u094d\u0924\u093f\u0917\u0924 \u0935\u093f\u0935\u0930\u0923 \u0938\u0940\u0927\u0947 \u092a\u094b\u0938\u094d\u091f\u0930 \u091f\u0947\u092e\u094d\u092a\u0932\u0947\u091f\u094d\u0938 \u092a\u0930 \u0930\u0916\u0947 \u091c\u093e \u0938\u0915\u0924\u0947 \u0939\u0948\u0902\u0964',
  'Are daily categories updated?': 'क्या daily categories अपडेट होती हैं?',
  'The landing page and app can surface time-based categories and special poster needs.':
      '\u0906\u092a \u0938\u092e\u092f-\u0906\u0927\u093e\u0930\u093f\u0924 categories \u0914\u0930 daily poster needs \u0926\u093f\u0916\u093e \u0938\u0915\u0924\u093e \u0939\u0948\u0964',
  'Can I export posters?': 'क्या मैं पोस्टर्स export कर सकता हूँ?',
  'Yes. Export and share flows stay simple for daily usage.':
      '\u0939\u093e\u0901\u0964 \u0930\u094b\u091c\u093c\u093e\u0928\u093e \u0909\u092a\u092f\u094b\u0917 \u0915\u0947 \u0932\u093f\u090f export \u0914\u0930 share flow \u0938\u0930\u0932 \u0930\u0939\u0924\u093e \u0939\u0948\u0964',
  'Quick Links':
      '\u0915\u094d\u0935\u093f\u0915 \u0932\u093f\u0902\u0915\u094d\u0938',
  'Legal': '\u0932\u0940\u0917\u0932',
  'Privacy Policy':
      '\u092a\u094d\u0930\u093e\u0907\u0935\u0947\u0938\u0940 \u092a\u0949\u0932\u093f\u0938\u0940',
  'Terms & Conditions':
      '\u0928\u093f\u092f\u092e \u0914\u0930 \u0936\u0930\u094d\u0924\u0947\u0902',
  'Contact': '\u0938\u0902\u092a\u0930\u094d\u0915',
  'Telugu-first poster creation':
      '\u0924\u0947\u0932\u0941\u0917\u0941-\u092b\u0930\u094d\u0938\u094d\u091f \u092a\u094b\u0938\u094d\u091f\u0930 \u0915\u094d\u0930\u093f\u090f\u0936\u0928',
  'Create Telugu Posters in Seconds':
      '\u0938\u0947\u0915\u0902\u0921\u094b\u0902 \u092e\u0947\u0902 \u0924\u0947\u0932\u0941\u0917\u0941 \u092a\u094b\u0938\u094d\u091f\u0930 \u092c\u0928\u093e\u090f\u0902',
  'Mana Poster Ai lets users create, customize, and share Telugu posters instantly with a simple, fast workflow.':
      'Mana Poster Ai \u092f\u0942\u091c\u093c\u0930\u094d\u0938 \u0915\u094b simple \u0914\u0930 fast workflow \u0915\u0947 \u0938\u093e\u0925 \u0924\u0947\u0932\u0941\u0917\u0941 \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938 \u0924\u0941\u0930\u0902\u0924 create, customize \u0914\u0930 share \u0915\u0930\u0928\u0947 \u0926\u0947\u0924\u093e \u0939\u0948\u0964',
  'Watch Demo': '\u0921\u0947\u092e\u094b \u0926\u0947\u0916\u0947\u0902',
  'Poster Collections Available':
      '\u092b\u094d\u0930\u0940 \u0914\u0930 \u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938 \u0909\u092a\u0932\u092c\u094d\u0927',
  'App Preview':
      '\u0910\u092a \u092a\u094d\u0930\u0940\u0935\u094d\u092f\u0942',
  'A clear view of how poster flow looks inside the app':
      '\u0910\u092a \u0915\u0947 \u0905\u0902\u0926\u0930 \u092a\u094b\u0938\u094d\u091f\u0930 \u092b\u094d\u0932\u094b \u0915\u0948\u0938\u093e \u0926\u093f\u0916\u0924\u093e \u0939\u0948, \u0907\u0938\u0915\u093e \u0938\u094d\u092a\u0937\u094d\u091f \u0926\u0943\u0936\u094d\u092f',
  'The flow is designed to stay simple from category selection to preview, personalization, and final sharing.':
      'Category selection \u0938\u0947 preview, personalization \u0914\u0930 final sharing \u0924\u0915 flow \u0938\u0930\u0932 \u0930\u0916\u093e \u0917\u092f\u093e \u0939\u0948\u0964',
  'Built for fast Telugu poster creation':
      '\u0924\u0947\u091c\u093c \u0924\u0947\u0932\u0941\u0917\u0941 \u092a\u094b\u0938\u094d\u091f\u0930 \u0915\u094d\u0930\u093f\u090f\u0936\u0928 \u0915\u0947 \u0932\u093f\u090f \u092c\u0928\u093e\u092f\u093e \u0917\u092f\u093e',
  'Templates, sharing, personalization, and daily-use category flows are organized to keep poster making quick and repeatable.':
      'Templates, sharing, personalization \u0914\u0930 daily-use category flows \u092a\u094b\u0938\u094d\u091f\u0930 \u092c\u0928\u093e\u0928\u093e \u0924\u0947\u091c\u093c \u0914\u0930 repeatable \u0930\u0916\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f organized \u0939\u0948\u0902\u0964',
  'Colorful Category Gallery':
      '\u0930\u0902\u0917\u0940\u0928 \u0915\u0948\u091f\u0947\u0917\u0930\u0940 \u0917\u0948\u0932\u0930\u0940',
  'Each category opens like a poster wall so the landing page feels rich, bold, and closer to a real creative marketplace.':
      '\u0939\u0930 category poster wall \u0915\u0940 \u0924\u0930\u0939 \u0916\u0941\u0932\u0924\u0940 \u0939\u0948, \u0907\u0938\u0932\u093f\u090f landing page rich, bold \u0914\u0930 creative marketplace \u091c\u0948\u0938\u093e \u0932\u0917\u0924\u093e \u0939\u0948\u0964',
  'Today\'s Special Posters':
      '\u0906\u091c \u0915\u0947 \u0938\u094d\u092a\u0947\u0936\u0932 \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938',
  'Every Day New Posters Automatically':
      '\u0939\u0930 \u0926\u093f\u0928 \u0928\u090f \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938 \u0905\u092a\u0928\u0947 \u0906\u092a',
  'Mana Poster Ai automatically shows posters for Festivals, Jayanthi, Vardhanthi, National Days and Telugu State Events based on the selected date.':
      'Mana Poster Ai \u091a\u0941\u0928\u0940 \u0939\u0941\u0908 \u0924\u093e\u0930\u0940\u0916\u093c \u0915\u0947 \u0906\u0927\u093e\u0930 \u092a\u0930 Festivals, Jayanthi, Vardhanthi, National Days \u0914\u0930 Telugu State Events \u0915\u0947 \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938 \u0905\u092a\u0928\u0947 \u0906\u092a \u0926\u093f\u0916\u093e\u0924\u093e \u0939\u0948\u0964',
  'Poster Options':
      '\u092b\u094d\u0930\u0940 \u092c\u0928\u093e\u092e \u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e',
  'Choose the plan that fits your poster workflow':
      '\u0905\u092a\u0928\u0947 \u092a\u094b\u0938\u094d\u091f\u0930 workflow \u0915\u0947 \u0932\u093f\u090f \u0938\u0939\u0940 \u092a\u094d\u0932\u093e\u0928 \u091a\u0941\u0928\u0947\u0902',
  'Choose from quick daily posters and fully editable poster options with better exports and faster personalization.':
      '\u091c\u0932\u094d\u0926 daily posters, export options \u0914\u0930 simple personalization flows \u092e\u0947\u0902 \u0938\u0947 choose \u0915\u0930\u0947\u0902\u0964',
  'Frequently asked questions':
      '\u0905\u0915\u094d\u0938\u0930 \u092a\u0942\u091b\u0947 \u091c\u093e\u0928\u0947 \u0935\u093e\u0932\u0947 \u0938\u0935\u093e\u0932',
  'Common doubts about templates, photos, HD downloads, and daily Telugu poster updates.':
      'Templates, photos, HD downloads \u0914\u0930 daily Telugu poster updates \u0938\u0947 \u091c\u0941\u0921\u093c\u0947 \u0938\u093e\u092e\u093e\u0928\u094d\u092f \u0938\u0935\u093e\u0932\u0964',
  'Final CTA': '\u0905\u0902\u0924\u093f\u092e CTA',
  'Start Creating Beautiful Telugu Posters Today':
      '\u0906\u091c \u0939\u0940 \u0938\u0941\u0902\u0926\u0930 \u0924\u0947\u0932\u0941\u0917\u0941 \u092a\u094b\u0938\u094d\u091f\u0930 \u092c\u0928\u093e\u0928\u093e \u0936\u0941\u0930\u0942 \u0915\u0930\u0947\u0902',
  'Ready templates, Telugu-friendly typing, photo placement, and fast sharing come together in one app.':
      'Ready templates, Telugu-friendly typing, photo placement \u0914\u0930 fast sharing \u090f\u0915 \u0939\u0940 app \u092e\u0947\u0902 \u092e\u093f\u0932\u0924\u0947 \u0939\u0948\u0902\u0964',
  'Mana Poster Ai is a simple way to create and share Telugu posters every day.':
      'Mana Poster Ai \u0930\u094b\u091c\u093c \u0924\u0947\u0932\u0941\u0917\u0941 \u092a\u094b\u0938\u094d\u091f\u0930\u094d\u0938 create \u0914\u0930 share \u0915\u0930\u0928\u0947 \u0915\u093e \u0906\u0938\u093e\u0928 \u0924\u0930\u0940\u0915\u093e \u0939\u0948\u0964',
};

const Map<String, String> _landingTamilFallbacks = <String, String>{
  'Home': '\u0bae\u0bc1\u0b95\u0baa\u0bcd\u0baa\u0bc1',
  'Features': '\u0b85\u0bae\u0bcd\u0b9a\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
  'Categories': '\u0bb5\u0b95\u0bc8\u0b95\u0bb3\u0bcd',
  'Download':
      '\u0baa\u0ba4\u0bbf\u0bb5\u0bbf\u0bb1\u0b95\u0bcd\u0b95\u0bae\u0bcd',
  'Admin Login':
      '\u0b85\u0b9f\u0bcd\u0bae\u0bbf\u0ba9\u0bcd \u0b89\u0bb3\u0bcd\u0ba8\u0bc1\u0bb4\u0bc8\u0bb5\u0bc1',
  'Sign Out': '\u0bb5\u0bc6\u0bb3\u0bbf\u0baf\u0bc7\u0bb1\u0bc1',
  'Get App':
      '\u0b86\u0baa\u0bcd\u0baa\u0bc8\u0baa\u0bcd \u0baa\u0bc6\u0bb1\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
  'Ready Telugu templates':
      '\u0ba4\u0baf\u0bbe\u0bb0\u0bcd \u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1 \u0b9f\u0bc6\u0bae\u0bcd\u0baa\u0bcd\u0bb3\u0bc7\u0b9f\u0bcd\u0b9f\u0bc1\u0b95\u0bb3\u0bcd',
  'Start fast with reusable layouts for daily poster needs.':
      '\u0ba4\u0bbf\u0ba9\u0b9a\u0bb0\u0bbf \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8\u0b95\u0bb3\u0bc1\u0b95\u0bcd\u0b95\u0bc1 reusable layouts \u0b89\u0b9f\u0ba9\u0bcd \u0bb5\u0bbf\u0bb0\u0bc8\u0bb5\u0bbe\u0b95 \u0ba4\u0bca\u0b9f\u0b99\u0bcd\u0b95\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd.',
  'Photo + name personalization':
      '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0bae\u0bcd + \u0baa\u0bc6\u0baf\u0bb0\u0bcd \u0ba4\u0ba9\u0bbf\u0baa\u0bcd\u0baa\u0baf\u0ba9\u0bbe\u0b95\u0bcd\u0b95\u0bae\u0bcd',
  'Update poster identity quickly without redesigning everything.':
      '\u0bae\u0bc1\u0bb4\u0bc1 \u0bb5\u0b9f\u0bbf\u0bb5\u0bae\u0bc8\u0baa\u0bcd\u0baa\u0bc8 \u0bae\u0bbe\u0bb1\u0bcd\u0bb1\u0bbe\u0bae\u0bb2\u0bcd \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0bb5\u0bbf\u0bb5\u0bb0\u0b99\u0bcd\u0b95\u0bb3\u0bc8 \u0bb5\u0bbf\u0bb0\u0bc8\u0bb5\u0bbe\u0b95 \u0baa\u0bc1\u0ba4\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd.',
  'Fast sharing flow':
      '\u0bb5\u0bc7\u0b95\u0bae\u0bbe\u0ba9 \u0baa\u0b95\u0bbf\u0bb0\u0bcd\u0bb5\u0bc1 \u0b93\u0b9f\u0bcd\u0b9f\u0bae\u0bcd',
  'Export and share in a few taps for WhatsApp-first usage.':
      'WhatsApp-first \u0baa\u0baf\u0ba9\u0bcd\u0baa\u0bbe\u0b9f\u0bcd\u0b9f\u0bbf\u0bb1\u0bcd\u0b95\u0bc1 \u0b9a\u0bbf\u0bb2 taps-\u0bb2\u0bcd export \u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bc1 share \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd.',
  'Poster design mix':
      '\u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0b9f\u0bbf\u0b9a\u0bc8\u0ba9\u0bcd \u0b95\u0bb2\u0bb5\u0bc8',
  'Keep poster discovery open while design quality stays clear.':
      '\u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0ba4\u0bc7\u0b9f\u0bb2\u0bc8 \u0ba4\u0bbf\u0bb1\u0ba8\u0bcd\u0ba4\u0bc1 \u0bb5\u0bc8\u0ba4\u0bcd\u0ba4\u0bc1, \u0b9f\u0bbf\u0b9a\u0bc8\u0ba9\u0bcd \u0ba4\u0bb0\u0bae\u0bcd \u0ba4\u0bc6\u0bb3\u0bbf\u0bb5\u0bbe\u0b95 \u0ba4\u0bc6\u0bb0\u0bbf\u0baf\u0b9f\u0bcd\u0b9f\u0bc1\u0bae\u0bcd.',
  'Festival posters':
      '\u0ba4\u0bbf\u0bb0\u0bc1\u0bb5\u0bbf\u0bb4\u0bbe \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd',
  'Date-based festival content can stay discoverable without manual browsing.':
      '\u0ba4\u0bc7\u0ba4\u0bbf \u0b85\u0b9f\u0bbf\u0baa\u0bcd\u0baa\u0b9f\u0bc8\u0baf\u0bbf\u0bb2\u0bbe\u0ba9 \u0ba4\u0bbf\u0bb0\u0bc1\u0bb5\u0bbf\u0bb4\u0bbe \u0b89\u0bb3\u0bcd\u0bb3\u0b9f\u0b95\u0bcd\u0b95\u0bae\u0bcd manual browsing \u0b87\u0ba9\u0bcd\u0bb1\u0bbf\u0baf\u0bc1\u0bae\u0bcd \u0b95\u0bbe\u0ba3\u0baa\u0bcd\u0baa\u0b9f\u0bb2\u0bbe\u0bae\u0bcd.',
  'National days':
      '\u0ba4\u0bc7\u0b9a\u0bbf\u0baf \u0ba8\u0bbe\u0b9f\u0bcd\u0b95\u0bb3\u0bcd',
  'Important observances are easier to surface when the day matters.':
      '\u0bae\u0bc1\u0b95\u0bcd\u0b95\u0bbf\u0baf observances \u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 \u0ba8\u0bbe\u0bb3\u0bbf\u0bb2\u0bcd \u0b8e\u0bb3\u0bbf\u0ba4\u0bbe\u0b95 \u0ba4\u0bc6\u0bb0\u0bbf\u0baf \u0bb5\u0bb0\u0bc1\u0bae\u0bcd.',
  'Local event updates':
      '\u0b89\u0bb3\u0bcd\u0bb3\u0bc2\u0bb0\u0bcd \u0ba8\u0bbf\u0b95\u0bb4\u0bcd\u0bb5\u0bc1 \u0baa\u0bc1\u0ba4\u0bc1\u0baa\u0bcd\u0baa\u0bbf\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
  'Telugu state relevance stays visible in one dedicated block.':
      '\u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1 \u0bae\u0bbe\u0ba8\u0bbf\u0bb2\u0b99\u0bcd\u0b95\u0bb3\u0bc1\u0b95\u0bcd\u0b95\u0bc1 \u0ba4\u0bca\u0b9f\u0bb0\u0bcd\u0baa\u0bbe\u0ba9\u0bb5\u0bc8 \u0b92\u0bb0\u0bc1 dedicated block-\u0bb2\u0bcd \u0ba4\u0bc6\u0bb3\u0bbf\u0bb5\u0bbe\u0b95 \u0b87\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bc1\u0bae\u0bcd.',
  'Free Posters':
      '\u0b87\u0bb2\u0bb5\u0b9a \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd',
  'Starter': '\u0bb8\u0bcd\u0b9f\u0bbe\u0bb0\u0bcd\u0b9f\u0bb0\u0bcd',
  'Basic templates':
      '\u0b85\u0b9f\u0bbf\u0baa\u0bcd\u0baa\u0b9f\u0bc8 \u0b9f\u0bc6\u0bae\u0bcd\u0baa\u0bcd\u0bb3\u0bc7\u0b9f\u0bcd\u0b9f\u0bc1\u0b95\u0bb3\u0bcd',
  'Quick sharing':
      '\u0bb5\u0bc7\u0b95\u0bae\u0bbe\u0ba9 \u0baa\u0b95\u0bbf\u0bb0\u0bcd\u0bb5\u0bc1',
  'Simple export': '\u0b8e\u0bb3\u0bbf\u0baf export',
  'Featured Posters':
      '\u0baa\u0bbf\u0bb0\u0bc0\u0bae\u0bbf\u0baf\u0bae\u0bcd \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd',
  'Pro Access': '\u0baa\u0bcd\u0bb0\u0bcb \u0b85\u0ba3\u0bc1\u0b95\u0bb2\u0bcd',
  'Fully editable posters':
      '\u0bae\u0bc1\u0bb4\u0bc1\u0bae\u0bc8\u0baf\u0bbe\u0b95 editable \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd',
  'More templates':
      '\u0baa\u0bbf\u0bb0\u0bc0\u0bae\u0bbf\u0baf\u0bae\u0bcd \u0b9f\u0bc6\u0bae\u0bcd\u0baa\u0bcd\u0bb3\u0bc7\u0b9f\u0bcd\u0b9f\u0bc1\u0b95\u0bb3\u0bcd',
  'Unlimited customization':
      '\u0bb5\u0bb0\u0bae\u0bcd\u0baa\u0bb1\u0bcd\u0bb1 customization',
  'HD export': 'HD export',
  'Is Mana Poster Ai AI free?': 'Mana Poster Ai AI இலவசமா?',
  'Posters are available with stronger templates and deeper editing inside the app.':
      '\u0b86\u0baa\u0bcd\u0baa\u0bbf\u0bb2\u0bcd posters create, personalize \u0baa\u0ba3\u0bcd\u0ba3\u0bb5\u0bc1\u0bae\u0bcd share \u0baa\u0ba3\u0bcd\u0ba3\u0bb5\u0bc1\u0bae\u0bcd simple options \u0b95\u0bbf\u0b9f\u0bc8\u0b95\u0bcd\u0b95\u0bc1\u0bae\u0bcd.',
  'Can I add photo and name?': 'நான் புகைப்படம் மற்றும் பெயரை சேர்க்கலாமா?',
  'Yes. Personal details can be placed directly on poster templates.':
      '\u0b86\u0bae\u0bcd. \u0ba4\u0ba9\u0bbf\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f \u0bb5\u0bbf\u0bb5\u0bb0\u0b99\u0bcd\u0b95\u0bb3\u0bc8 \u0ba8\u0bc7\u0bb0\u0b9f\u0bbf\u0baf\u0bbe\u0b95 poster templates-\u0bb2\u0bcd \u0b9a\u0bc7\u0bb0\u0bcd\u0b95\u0bcd\u0b95\u0bb2\u0bbe\u0bae\u0bcd.',
  'Are daily categories updated?': 'தினசரி categories புதுப்பிக்கப்படுமா?',
  'The landing page and app can surface time-based categories and special poster needs.':
      '\u0b86\u0baa\u0bcd\u0baa\u0bbf\u0bb2\u0bcd time-based categories \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd daily poster needs \u0b95\u0bbe\u0b9f\u0bcd\u0b9f \u0bae\u0bc1\u0b9f\u0bbf\u0baf\u0bc1\u0bae\u0bcd.',
  'Can I export posters?': 'நான் போஸ்டர்களை export செய்யலாமா?',
  'Yes. Export and share flows stay simple for daily usage.':
      '\u0b86\u0bae\u0bcd. \u0ba4\u0bbf\u0ba9\u0b9a\u0bb0\u0bbf \u0baa\u0baf\u0ba9\u0bcd\u0baa\u0bbe\u0b9f\u0bcd\u0b9f\u0bbf\u0bb1\u0bcd\u0b95\u0bc1 export \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd share flow \u0b8e\u0bb3\u0bbf\u0bae\u0bc8\u0baf\u0bbe\u0b95 \u0b87\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bc1\u0bae\u0bcd.',
  'Quick Links':
      '\u0bb5\u0bbf\u0bb0\u0bc8\u0bb5\u0bc1 \u0b87\u0ba3\u0bc8\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
  'Legal': '\u0b9a\u0b9f\u0bcd\u0b9f\u0bae\u0bcd',
  'Privacy Policy':
      '\u0ba4\u0ba9\u0bbf\u0baf\u0bc1\u0bb0\u0bbf\u0bae\u0bc8\u0b95\u0bcd \u0b95\u0bca\u0bb3\u0bcd\u0b95\u0bc8',
  'Terms & Conditions':
      '\u0bb5\u0bbf\u0ba4\u0bbf\u0bae\u0bc1\u0bb1\u0bc8\u0b95\u0bb3\u0bcd \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0ba8\u0bbf\u0baa\u0ba8\u0bcd\u0ba4\u0ba9\u0bc8\u0b95\u0bb3\u0bcd',
  'Contact': '\u0ba4\u0bca\u0b9f\u0bb0\u0bcd\u0baa\u0bc1',
  'Telugu-first poster creation':
      '\u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1-\u0bae\u0bc1\u0ba4\u0ba9\u0bcd\u0bae\u0bc8 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0bae\u0bcd',
  'Create Telugu Posters in Seconds':
      '\u0bb5\u0bbf\u0ba8\u0bbe\u0b9f\u0bbf\u0b95\u0bb3\u0bbf\u0bb2\u0bcd \u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
  'Mana Poster Ai lets users create, customize, and share Telugu posters instantly with a simple, fast workflow.':
      'Mana Poster Ai \u0b8e\u0bb3\u0bbf\u0baf, \u0bb5\u0bc7\u0b95\u0bae\u0bbe\u0ba9 workflow \u0bae\u0bc2\u0bb2\u0bae\u0bcd \u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bc8 \u0b89\u0b9f\u0ba9\u0bc7 create, customize \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd share \u0b9a\u0bc6\u0baf\u0bcd\u0baf \u0b89\u0ba4\u0bb5\u0bc1\u0b95\u0bbf\u0bb1\u0ba4\u0bc1.',
  'Watch Demo':
      '\u0b9f\u0bc6\u0bae\u0bcb \u0baa\u0bbe\u0bb0\u0bcd\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
  'Poster Collections Available':
      '\u0b87\u0bb2\u0bb5\u0b9a \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0baa\u0bbf\u0bb0\u0bc0\u0bae\u0bbf\u0baf\u0bae\u0bcd \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd \u0b95\u0bbf\u0b9f\u0bc8\u0b95\u0bcd\u0b95\u0bc1\u0bae\u0bcd',
  'App Preview':
      '\u0b86\u0baa\u0bcd \u0bae\u0bc1\u0ba9\u0bcd\u0ba9\u0bcb\u0b9f\u0bcd\u0b9f\u0bae\u0bcd',
  'A clear view of how poster flow looks inside the app':
      '\u0b86\u0baa\u0bcd\u0baa\u0bbf\u0bb1\u0bcd\u0b95\u0bc1\u0bb3\u0bcd poster flow \u0b8e\u0baa\u0bcd\u0baa\u0b9f\u0bbf \u0b87\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bbf\u0bb1\u0ba4\u0bc1 \u0b8e\u0ba9\u0bcd\u0baa\u0ba4\u0bb1\u0bcd\u0b95\u0bbe\u0ba9 \u0ba4\u0bc6\u0bb3\u0bbf\u0bb5\u0bbe\u0ba9 \u0baa\u0bbe\u0bb0\u0bcd\u0bb5\u0bc8',
  'The flow is designed to stay simple from category selection to preview, personalization, and final sharing.':
      'Category selection \u0bae\u0bc1\u0ba4\u0bb2\u0bcd preview, personalization, final sharing \u0bb5\u0bb0\u0bc8 flow \u0b8e\u0bb3\u0bbf\u0bae\u0bc8\u0baf\u0bbe\u0b95 \u0bb5\u0b9f\u0bbf\u0bb5\u0bae\u0bc8\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f\u0bc1\u0bb3\u0bcd\u0bb3\u0ba4\u0bc1.',
  'Built for fast Telugu poster creation':
      '\u0bb5\u0bc7\u0b95\u0bae\u0bbe\u0ba9 \u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0ba4\u0bcd\u0ba4\u0bbf\u0bb1\u0bcd\u0b95\u0bbe\u0b95 \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f\u0ba4\u0bc1',
  'Templates, sharing, personalization, and daily-use category flows are organized to keep poster making quick and repeatable.':
      'Templates, sharing, personalization \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd daily-use category flows, poster making-\u0b90 \u0bb5\u0bc7\u0b95\u0bae\u0bbe\u0b95\u0bb5\u0bc1\u0bae\u0bcd repeatable-\u0b86\u0b95\u0bb5\u0bc1\u0bae\u0bcd \u0bb5\u0bc8\u0ba4\u0bcd\u0ba4\u0bbf\u0bb0\u0bc1\u0b95\u0bcd\u0b95 \u0b92\u0bb4\u0bc1\u0b99\u0bcd\u0b95\u0bc1\u0baa\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0baa\u0bcd\u0baa\u0b9f\u0bcd\u0b9f\u0bc1\u0bb3\u0bcd\u0bb3\u0ba9.',
  'Colorful Category Gallery':
      '\u0ba8\u0bbf\u0bb1\u0bae\u0bc1\u0bb3\u0bcd\u0bb3 \u0bb5\u0b95\u0bc8 \u0b95\u0bbe\u0b9f\u0bcd\u0b9a\u0bbf',
  'Each category opens like a poster wall so the landing page feels rich, bold, and closer to a real creative marketplace.':
      '\u0b92\u0bb5\u0bcd\u0bb5\u0bca\u0bb0\u0bc1 category-\u0baf\u0bc1\u0bae\u0bcd poster wall \u0baa\u0bcb\u0bb2 \u0ba4\u0bbf\u0bb1\u0b95\u0bcd\u0b95\u0bbf\u0bb1\u0ba4\u0bc1; \u0b85\u0ba4\u0ba9\u0bbe\u0bb2\u0bcd landing page \u0b9a\u0bc6\u0bb4\u0bc1\u0bae\u0bc8\u0baf\u0bbe\u0b95\u0bb5\u0bc1\u0bae\u0bcd bold-\u0b86\u0b95\u0bb5\u0bc1\u0bae\u0bcd creative marketplace \u0baa\u0bcb\u0bb2\u0bb5\u0bc1\u0bae\u0bcd \u0ba4\u0bcb\u0ba9\u0bcd\u0bb1\u0bc1\u0b95\u0bbf\u0bb1\u0ba4\u0bc1.',
  'Today\'s Special Posters':
      '\u0b87\u0ba9\u0bcd\u0bb1\u0bc8\u0baf \u0b9a\u0bbf\u0bb1\u0baa\u0bcd\u0baa\u0bc1 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd',
  'Every Day New Posters Automatically':
      '\u0b92\u0bb5\u0bcd\u0bb5\u0bca\u0bb0\u0bc1 \u0ba8\u0bbe\u0bb3\u0bc1\u0bae\u0bcd \u0baa\u0bc1\u0ba4\u0bbf\u0baf \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd \u0ba4\u0bbe\u0ba9\u0bbe\u0b95',
  'Mana Poster Ai automatically shows posters for Festivals, Jayanthi, Vardhanthi, National Days and Telugu State Events based on the selected date.':
      '\u0ba4\u0bc7\u0bb0\u0bcd\u0ba8\u0bcd\u0ba4\u0bc6\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4 \u0ba4\u0bc7\u0ba4\u0bbf\u0baf\u0bbf\u0ba9\u0bcd \u0b85\u0b9f\u0bbf\u0baa\u0bcd\u0baa\u0b9f\u0bc8\u0baf\u0bbf\u0bb2\u0bcd Festivals, Jayanthi, Vardhanthi, National Days \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd Telugu State Events \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bc8 Mana Poster Ai \u0ba4\u0bbe\u0ba9\u0bbe\u0b95 \u0b95\u0bbe\u0b9f\u0bcd\u0b9f\u0bc1\u0bae\u0bcd.',
  'Poster Options':
      '\u0b87\u0bb2\u0bb5\u0b9a\u0bae\u0bcd vs \u0baa\u0bbf\u0bb0\u0bc0\u0bae\u0bbf\u0baf\u0bae\u0bcd',
  'Choose the plan that fits your poster workflow':
      '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd poster workflow-\u0b95\u0bcd\u0b95\u0bc1 \u0baa\u0bca\u0bb0\u0bc1\u0ba4\u0bcd\u0ba4\u0bae\u0bbe\u0ba9 \u0ba4\u0bbf\u0b9f\u0bcd\u0b9f\u0ba4\u0bcd\u0ba4\u0bc8\u0ba4\u0bcd \u0ba4\u0bc7\u0bb0\u0bcd\u0ba8\u0bcd\u0ba4\u0bc6\u0b9f\u0bc1\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
  'Choose from quick daily posters and fully editable poster options with better exports and faster personalization.':
      '\u0bb5\u0bc7\u0b95\u0bae\u0bbe\u0ba9 daily posters, export options \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd simple personalization flows-\u0bb2\u0bbf\u0bb0\u0bc1\u0ba8\u0bcd\u0ba4\u0bc1 choose \u0baa\u0ba3\u0bcd\u0ba3\u0bb2\u0bbe\u0bae\u0bcd.',
  'Frequently asked questions':
      '\u0b85\u0b9f\u0bbf\u0b95\u0bcd\u0b95\u0b9f\u0bbf \u0b95\u0bc7\u0b9f\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0bae\u0bcd \u0b95\u0bc7\u0bb3\u0bcd\u0bb5\u0bbf\u0b95\u0bb3\u0bcd',
  'Common doubts about templates, photos, HD downloads, and daily Telugu poster updates.':
      'Templates, photos, HD downloads \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0ba4\u0bbf\u0ba9\u0b9a\u0bb0\u0bbf Telugu poster updates \u0baa\u0bb1\u0bcd\u0bb1\u0bbf\u0baf \u0baa\u0bca\u0ba4\u0bc1\u0bb5\u0bbe\u0ba9 \u0b95\u0bc7\u0bb3\u0bcd\u0bb5\u0bbf\u0b95\u0bb3\u0bcd.',
  'Final CTA': '\u0b87\u0bb1\u0bc1\u0ba4\u0bbf CTA',
  'Start Creating Beautiful Telugu Posters Today':
      '\u0b87\u0ba9\u0bcd\u0bb1\u0bc7 \u0b85\u0bb4\u0b95\u0bbe\u0ba9 \u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bcd \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0ba4\u0bcd \u0ba4\u0bca\u0b9f\u0b99\u0bcd\u0b95\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
  'Ready templates, Telugu-friendly typing, photo placement, and fast sharing come together in one app.':
      'Ready templates, Telugu-friendly typing, photo placement \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd fast sharing \u0b85\u0ba9\u0bc8\u0ba4\u0bcd\u0ba4\u0bc1\u0bae\u0bcd \u0b92\u0bb0\u0bc7 app-\u0bb2\u0bcd \u0b95\u0bbf\u0b9f\u0bc8\u0b95\u0bcd\u0b95\u0bbf\u0ba9\u0bcd\u0bb1\u0ba9.',
  'Mana Poster Ai is a simple way to create and share Telugu posters every day.':
      'Mana Poster Ai \u0ba4\u0bbf\u0ba9\u0bae\u0bc1\u0bae\u0bcd \u0ba4\u0bc6\u0bb2\u0bc1\u0b99\u0bcd\u0b95\u0bc1 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bc8 \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd \u0baa\u0b95\u0bbf\u0bb0\u0bb5\u0bc1\u0bae\u0bcd \u0b8e\u0bb3\u0bbf\u0baf \u0bb5\u0bb4\u0bbf.',
};

const Map<String, String> _landingKannadaFallbacks = <String, String>{
  'Home': '\u0cae\u0cc1\u0c96\u0caa\u0cc1\u0c9f',
  'Features':
      '\u0cb5\u0cc8\u0cb6\u0cbf\u0cb7\u0ccd\u0c9f\u0ccd\u0caf\u0c97\u0cb3\u0cc1',
  'Categories': '\u0cb5\u0cb0\u0ccd\u0c97\u0c97\u0cb3\u0cc1',
  'Download': '\u0ca1\u0ccc\u0ca8\u0ccd\u200c\u0cb2\u0ccb\u0ca1\u0ccd',
  'Admin Login':
      '\u0c85\u0ca1\u0ccd\u0cae\u0cbf\u0ca8\u0ccd \u0cb2\u0cbe\u0c97\u0cbf\u0ca8\u0ccd',
  'Sign Out': '\u0cb8\u0cc8\u0ca8\u0ccd \u0c94\u0c9f\u0ccd',
  'Get App': '\u0c86\u0caa\u0ccd \u0caa\u0ca1\u0cc6\u0caf\u0cbf\u0cb0\u0cbf',
  'Ready Telugu templates':
      '\u0cb8\u0cbf\u0ca6\u0ccd\u0ca7 \u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1 \u0c9f\u0cc6\u0c82\u0caa\u0ccd\u0cb2\u0cc7\u0c9f\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Start fast with reusable layouts for daily poster needs.':
      '\u0ca6\u0cc8\u0ca8\u0c82\u0ca6\u0cbf\u0ca8 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd \u0c85\u0c97\u0ca4\u0ccd\u0caf\u0c97\u0cb3\u0cbf\u0c97\u0cc6 reusable layouts \u0c9c\u0cca\u0ca4\u0cc6\u0c97\u0cc6 \u0cac\u0cc7\u0c97 \u0c86\u0cb0\u0c82\u0cad\u0cbf\u0cb8\u0cbf.',
  'Photo + name personalization':
      '\u0cab\u0ccb\u0c9f\u0ccb + \u0cb9\u0cc6\u0cb8\u0cb0\u0cc1 \u0cb5\u0cc8\u0caf\u0c95\u0ccd\u0ca4\u0cc0\u0c95\u0cb0\u0ca3',
  'Update poster identity quickly without redesigning everything.':
      '\u0caa\u0cc2\u0cb0\u0ccd\u0ca4\u0cbf \u0ca1\u0cbf\u0cb8\u0cc8\u0ca8\u0ccd \u0cac\u0ca6\u0cb2\u0cbf\u0cb8\u0ca6\u0cc6 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd \u0cb5\u0cbf\u0cb5\u0cb0\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0cac\u0cc7\u0c97 \u0c85\u0caa\u0ccd\u200c\u0ca1\u0cc7\u0c9f\u0ccd \u0cae\u0cbe\u0ca1\u0cbf.',
  'Fast sharing flow':
      '\u0cb5\u0cc7\u0c97\u0cb5\u0cbe\u0ca6 \u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cc6 \u0caa\u0ccd\u0cb0\u0cb5\u0cbe\u0cb9',
  'Export and share in a few taps for WhatsApp-first usage.':
      'WhatsApp-first \u0cac\u0cb3\u0c95\u0cc6\u0c97\u0cbe\u0c97\u0cbf \u0c95\u0cc6\u0cb2\u0cb5\u0cc1 taps-\u0c97\u0cb3\u0cb2\u0ccd\u0cb2\u0cbf export \u0cae\u0cbe\u0ca1\u0cbf share \u0cae\u0cbe\u0ca1\u0cbf.',
  'Poster design mix':
      '\u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd \u0ca1\u0cbf\u0c9c\u0cc8\u0ca8\u0ccd \u0cae\u0cbf\u0c95\u0ccd\u0cb8\u0ccd',
  'Keep poster discovery open while design quality stays clear.':
      '\u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd \u0ca4\u0cc6\u0cb0\u0cb5\u0ca8\u0ccd\u0ca8\u0cc1 \u0ca4\u0cc6\u0cb0\u0cc6\u0ca6\u0cbf\u0c9f\u0ccd\u0c9f\u0cc1, \u0ca1\u0cbf\u0c9c\u0cc8\u0ca8\u0ccd \u0ca4\u0cb0 \u0cb8\u0ccd\u0caa\u0cb7\u0ccd\u0c9f\u0cb5\u0cbe\u0c97\u0cbf \u0c95\u0cbe\u0ca3\u0cbf\u0cb8\u0cc1\u0cb5\u0c82\u0ca4\u0cc6 \u0cae\u0cbe\u0ca1\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6.',
  'Festival posters':
      '\u0cb9\u0cac\u0ccd\u0cac\u0ca6 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Date-based festival content can stay discoverable without manual browsing.':
      '\u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95 \u0c86\u0ca7\u0cbe\u0cb0\u0cbf\u0ca4 \u0cb9\u0cac\u0ccd\u0cac\u0ca6 \u0cb5\u0cbf\u0cb7\u0caf manual browsing \u0c87\u0cb2\u0ccd\u0cb2\u0ca6\u0cc6 \u0c95\u0cbe\u0ca3\u0cbf\u0cb8\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
  'National days':
      '\u0cb0\u0cbe\u0cb7\u0ccd\u0c9f\u0ccd\u0cb0\u0cc0\u0caf \u0ca6\u0cbf\u0ca8\u0c97\u0cb3\u0cc1',
  'Important observances are easier to surface when the day matters.':
      '\u0cae\u0cc1\u0c96\u0ccd\u0caf observances \u0cb8\u0cb0\u0cbf\u0caf\u0cbe\u0ca6 \u0ca6\u0cbf\u0ca8\u0ca6\u0cb2\u0ccd\u0cb2\u0cbf \u0cb8\u0cc1\u0cb2\u0cad\u0cb5\u0cbe\u0c97\u0cbf \u0c95\u0cbe\u0ca3\u0cc1\u0ca4\u0ccd\u0ca4\u0cb5\u0cc6.',
  'Local event updates':
      '\u0cb8\u0ccd\u0ca5\u0cb3\u0cc0\u0caf \u0c88\u0cb5\u0cc6\u0c82\u0c9f\u0ccd \u0c85\u0caa\u0ccd\u200c\u0ca1\u0cc7\u0c9f\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Telugu state relevance stays visible in one dedicated block.':
      '\u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1 \u0cb0\u0cbe\u0c9c\u0ccd\u0caf\u0c97\u0cb3\u0cbf\u0c97\u0cc6 \u0cb8\u0c82\u0cac\u0c82\u0ca7\u0cbf\u0cb8\u0cbf\u0ca6 \u0cb5\u0cbf\u0cb7\u0caf \u0c92\u0c82\u0ca6\u0cc1 dedicated block-\u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0c95\u0cbe\u0ca3\u0cbf\u0cb8\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6.',
  'Free Posters':
      '\u0c89\u0c9a\u0cbf\u0ca4 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Starter': '\u0cb8\u0ccd\u0c9f\u0cbe\u0cb0\u0ccd\u0c9f\u0cb0\u0ccd',
  'Basic templates':
      '\u0cae\u0cc2\u0cb2\u0cad\u0cc2\u0ca4 \u0c9f\u0cc6\u0c82\u0caa\u0ccd\u0cb2\u0cc7\u0c9f\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Quick sharing':
      '\u0c95\u0ccd\u0cb5\u0cbf\u0c95\u0ccd \u0cb6\u0cc7\u0cb0\u0cbf\u0c82\u0c97\u0ccd',
  'Simple export': '\u0cb8\u0cb0\u0cb3 export',
  'Featured Posters':
      '\u0caa\u0ccd\u0cb0\u0cc0\u0cae\u0cbf\u0caf\u0c82 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Pro Access':
      '\u0caa\u0ccd\u0cb0\u0ccb \u0c86\u0c95\u0ccd\u0cb8\u0cc6\u0cb8\u0ccd',
  'Fully editable posters':
      '\u0caa\u0cc2\u0cb0\u0ccd\u0ca3 editable \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'More templates':
      '\u0caa\u0ccd\u0cb0\u0cc0\u0cae\u0cbf\u0caf\u0c82 \u0c9f\u0cc6\u0c82\u0caa\u0ccd\u0cb2\u0cc7\u0c9f\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Unlimited customization':
      '\u0c85\u0ca8\u0cbf\u0caf\u0cae\u0cbf\u0ca4 customization',
  'HD export': 'HD export',
  'Is Mana Poster Ai AI free?': 'Mana Poster Ai AI ಉಚಿತವೇ?',
  'Posters are available with stronger templates and deeper editing inside the app.':
      '\u0c86\u0caa\u0ccd\u0ca8\u0cb2\u0ccd\u0cb2\u0cbf posters create, personalize \u0cae\u0cbe\u0ca1\u0cb2\u0cc1 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 share \u0cae\u0cbe\u0ca1\u0cb2\u0cc1 simple options \u0cb8\u0cbf\u0c97\u0cc1\u0ca4\u0ccd\u0ca4\u0cb5\u0cc6.',
  'Can I add photo and name?': 'ನಾನು ಫೋಟೋ ಮತ್ತು ಹೆಸರು ಸೇರಿಸಬಹುದೇ?',
  'Yes. Personal details can be placed directly on poster templates.':
      '\u0cb9\u0ccc\u0ca6\u0cc1. \u0cb5\u0cc8\u0caf\u0c95\u0ccd\u0ca4\u0cbf\u0c95 \u0cb5\u0cbf\u0cb5\u0cb0\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0ca8\u0cc7\u0cb0\u0cb5\u0cbe\u0c97\u0cbf poster templates \u0cae\u0cc7\u0cb2\u0cc6 \u0c87\u0cb0\u0cbf\u0cb8\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
  'Are daily categories updated?': 'ದೈನಂದಿನ categories update ಆಗುತ್ತವೆಯೇ?',
  'The landing page and app can surface time-based categories and special poster needs.':
      '\u0c86\u0caa\u0ccd time-based categories \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 daily poster needs \u0ca4\u0ccb\u0cb0\u0cbf\u0cb8\u0cb2\u0cc1 \u0cb8\u0cbe\u0ca7\u0ccd\u0caf.',
  'Can I export posters?': 'ನಾನು ಪೋಸ್ಟರ್‌ಗಳನ್ನು export ಮಾಡಬಹುದೇ?',
  'Yes. Export and share flows stay simple for daily usage.':
      '\u0cb9\u0ccc\u0ca6\u0cc1. \u0ca6\u0cc8\u0ca8\u0c82\u0ca6\u0cbf\u0ca8 \u0cac\u0cb3\u0c95\u0cc6\u0c97\u0cc6 export \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 share flow \u0cb8\u0cb0\u0cb3\u0cb5\u0cbe\u0c97\u0cbf\u0cb0\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6.',
  'Quick Links':
      '\u0c95\u0ccd\u0cb5\u0cbf\u0c95\u0ccd \u0cb2\u0cbf\u0c82\u0c95\u0ccd\u0cb8\u0ccd',
  'Legal': '\u0c95\u0cbe\u0ca8\u0cc2\u0ca8\u0cc1',
  'Privacy Policy':
      '\u0c97\u0ccc\u0caa\u0ccd\u0caf\u0ca4\u0cbe \u0ca8\u0cc0\u0ca4\u0cbf',
  'Terms & Conditions':
      '\u0ca8\u0cbf\u0caf\u0cae\u0c97\u0cb3\u0cc1 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cb7\u0cb0\u0ca4\u0ccd\u0ca4\u0cc1\u0c97\u0cb3\u0cc1',
  'Contact': '\u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95',
  'Telugu-first poster creation':
      '\u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1-\u0cae\u0cca\u0ca6\u0cb2 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd \u0ca8\u0cbf\u0cb0\u0ccd\u0cae\u0cbe\u0ca3',
  'Create Telugu Posters in Seconds':
      '\u0cb8\u0cc6\u0c95\u0cc6\u0c82\u0ca1\u0cc1\u0c97\u0cb3\u0cb2\u0ccd\u0cb2\u0cbf \u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0cb0\u0c9a\u0cbf\u0cb8\u0cbf',
  'Mana Poster Ai lets users create, customize, and share Telugu posters instantly with a simple, fast workflow.':
      'Mana Poster Ai \u0cb8\u0cb0\u0cb3 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cb5\u0cc7\u0c97\u0cb5\u0cbe\u0ca6 workflow \u0c9c\u0cca\u0ca4\u0cc6 \u0cac\u0cb3\u0c95\u0cc6\u0ca6\u0cbe\u0cb0\u0cb0\u0cbf\u0c97\u0cc6 \u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0ca4\u0c95\u0ccd\u0cb7\u0ca3 create, customize \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 share \u0cae\u0cbe\u0ca1\u0cb2\u0cc1 \u0cb8\u0cb9\u0cbe\u0caf \u0cae\u0cbe\u0ca1\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6.',
  'Watch Demo': '\u0ca1\u0cc6\u0cae\u0ccb \u0ca8\u0ccb\u0ca1\u0cbf',
  'Poster Collections Available':
      '\u0c89\u0c9a\u0cbf\u0ca4 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0caa\u0ccd\u0cb0\u0cc0\u0cae\u0cbf\u0caf\u0c82 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0cc1 \u0cb2\u0cad\u0ccd\u0caf',
  'App Preview':
      '\u0c86\u0caa\u0ccd \u0caa\u0cc2\u0cb0\u0ccd\u0cb5\u0cb5\u0cc0\u0c95\u0ccd\u0cb7\u0ca3\u0cc6',
  'A clear view of how poster flow looks inside the app':
      '\u0c86\u0caa\u0ccd \u0c92\u0cb3\u0c97\u0cc6 poster flow \u0cb9\u0cc7\u0c97\u0cc6 \u0c95\u0cbe\u0ca3\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6 \u0c8e\u0c82\u0cac\u0cc1\u0ca6\u0cb0 \u0cb8\u0ccd\u0caa\u0cb7\u0ccd\u0c9f \u0ca8\u0ccb\u0c9f',
  'The flow is designed to stay simple from category selection to preview, personalization, and final sharing.':
      'Category selection \u0c87\u0c82\u0ca6 preview, personalization \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 final sharing \u0cb5\u0cb0\u0cc6\u0c97\u0cc6 flow \u0cb8\u0cb0\u0cb3\u0cb5\u0cbe\u0c97\u0cbf\u0cb0\u0cb2\u0cc1 \u0cb5\u0cbf\u0ca8\u0ccd\u0caf\u0cbe\u0cb8\u0c97\u0cca\u0cb3\u0cbf\u0cb8\u0cb2\u0cbe\u0c97\u0cbf\u0ca6\u0cc6.',
  'Built for fast Telugu poster creation':
      '\u0cb5\u0cc7\u0c97\u0cb5\u0cbe\u0ca6 \u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd \u0ca8\u0cbf\u0cb0\u0ccd\u0cae\u0cbe\u0ca3\u0c95\u0ccd\u0c95\u0cbe\u0c97\u0cbf \u0ca8\u0cbf\u0cb0\u0ccd\u0cae\u0cbf\u0cb8\u0cb2\u0cbe\u0c97\u0cbf\u0ca6\u0cc6',
  'Templates, sharing, personalization, and daily-use category flows are organized to keep poster making quick and repeatable.':
      'Templates, sharing, personalization \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 daily-use category flows \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd \u0cae\u0cbe\u0ca1\u0cc1\u0cb5\u0cc1\u0ca6\u0ca8\u0ccd\u0ca8\u0cc1 \u0cb5\u0cc7\u0c97\u0cb5\u0cbe\u0c97\u0cbf \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 repeatable \u0c86\u0c97\u0cbf\u0cb0\u0cb2\u0cc1 \u0cb5\u0ccd\u0caf\u0cb5\u0cb8\u0ccd\u0ca5\u0cbf\u0ca4\u0cb5\u0cbe\u0c97\u0cbf\u0cb5\u0cc6.',
  'Colorful Category Gallery':
      '\u0cac\u0ca3\u0ccd\u0ca3\u0cac\u0ca3\u0ccd\u0ca3\u0ca6 \u0cb5\u0cb0\u0ccd\u0c97 \u0c97\u0ccd\u0caf\u0cbe\u0cb2\u0cb0\u0cbf',
  'Each category opens like a poster wall so the landing page feels rich, bold, and closer to a real creative marketplace.':
      '\u0caa\u0ccd\u0cb0\u0ca4\u0cbf category poster wall \u0cb9\u0cbe\u0c97\u0cc6 \u0ca4\u0cc6\u0cb0\u0cc6\u0ca6\u0cc1 landing page rich, bold \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 creative marketplace \u0cb9\u0ca4\u0ccd\u0ca4\u0cbf\u0cb0\u0cb5\u0cbe\u0c97\u0cbf\u0cb0\u0cc1\u0cb5\u0c82\u0ca4\u0cc6 \u0c95\u0cbe\u0ca3\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6.',
  'Today\'s Special Posters':
      '\u0c87\u0c82\u0ca6\u0cbf\u0ca8 \u0cb5\u0cbf\u0cb6\u0cc7\u0cb7 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0cc1',
  'Every Day New Posters Automatically':
      '\u0caa\u0ccd\u0cb0\u0ca4\u0cbf \u0ca6\u0cbf\u0ca8 \u0cb9\u0cca\u0cb8 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0cc1 \u0cb8\u0ccd\u0cb5\u0caf\u0c82\u0c9a\u0cbe\u0cb2\u0cbf\u0ca4\u0cb5\u0cbe\u0c97\u0cbf',
  'Mana Poster Ai automatically shows posters for Festivals, Jayanthi, Vardhanthi, National Days and Telugu State Events based on the selected date.':
      '\u0c86\u0caf\u0ccd\u0c95\u0cc6 \u0cae\u0cbe\u0ca1\u0cbf\u0ca6 \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95\u0ca6 \u0c86\u0ca7\u0cbe\u0cb0\u0ca6 \u0cae\u0cc7\u0cb2\u0cc6 Festivals, Jayanthi, Vardhanthi, National Days \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 Telugu State Events \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 Mana Poster Ai \u0cb8\u0ccd\u0cb5\u0caf\u0c82\u0c9a\u0cbe\u0cb2\u0cbf\u0ca4\u0cb5\u0cbe\u0c97\u0cbf \u0ca4\u0ccb\u0cb0\u0cbf\u0cb8\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6.',
  'Poster Options':
      '\u0c89\u0c9a\u0cbf\u0ca4 vs \u0caa\u0ccd\u0cb0\u0cc0\u0cae\u0cbf\u0caf\u0c82',
  'Choose the plan that fits your poster workflow':
      '\u0ca8\u0cbf\u0cae\u0ccd\u0cae poster workflow \u0c97\u0cc6 \u0cb8\u0cb0\u0cbf\u0cb9\u0cca\u0c82\u0ca6\u0cc1\u0cb5 \u0caf\u0ccb\u0c9c\u0ca8\u0cc6 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0cbe\u0ca1\u0cbf',
  'Choose from quick daily posters and fully editable poster options with better exports and faster personalization.':
      '\u0cb5\u0cc7\u0c97\u0cb5\u0cbe\u0ca6 daily posters, export options \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 simple personalization flows \u0cae\u0cc2\u0cb2\u0c95 choose \u0cae\u0cbe\u0ca1\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
  'Frequently asked questions':
      '\u0c85\u0ca8\u0cc7\u0c95\u0cb0\u0cbe\u0c97\u0cbf \u0c95\u0cc7\u0cb3\u0cb2\u0cbe\u0c97\u0cc1\u0cb5 \u0caa\u0ccd\u0cb0\u0cb6\u0ccd\u0ca8\u0cc6\u0c97\u0cb3\u0cc1',
  'Common doubts about templates, photos, HD downloads, and daily Telugu poster updates.':
      'Templates, photos, HD downloads \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 daily Telugu poster updates \u0cac\u0c97\u0ccd\u0c97\u0cc6 \u0cb8\u0cbe\u0cae\u0cbe\u0ca8\u0ccd\u0caf \u0caa\u0ccd\u0cb0\u0cb6\u0ccd\u0ca8\u0cc6\u0c97\u0cb3\u0cc1.',
  'Final CTA': '\u0c85\u0c82\u0ca4\u0cbf\u0cae CTA',
  'Start Creating Beautiful Telugu Posters Today':
      '\u0c87\u0c82\u0ca6\u0cc7 \u0cb8\u0cc1\u0c82\u0ca6\u0cb0 \u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0cb0\u0c9a\u0cbf\u0cb8\u0cb2\u0cc1 \u0c86\u0cb0\u0c82\u0cad\u0cbf\u0cb8\u0cbf',
  'Ready templates, Telugu-friendly typing, photo placement, and fast sharing come together in one app.':
      'Ready templates, Telugu-friendly typing, photo placement \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 fast sharing \u0c8e\u0cb2\u0ccd\u0cb2\u0cb5\u0cc2 \u0c92\u0c82\u0ca6\u0cc7 app \u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0ca6\u0cca\u0cb0\u0cc6\u0caf\u0cc1\u0ca4\u0ccd\u0ca4\u0cb5\u0cc6.',
  'Mana Poster Ai is a simple way to create and share Telugu posters every day.':
      'Mana Poster Ai \u0caa\u0ccd\u0cb0\u0ca4\u0cbf\u0ca6\u0cbf\u0ca8 \u0ca4\u0cc6\u0cb2\u0cc1\u0c97\u0cc1 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0cb0\u0c9a\u0cbf\u0cb8\u0cbf share \u0cae\u0cbe\u0ca1\u0cc1\u0cb5 \u0cb8\u0cb0\u0cb3 \u0cae\u0cbe\u0cb0\u0ccd\u0c97.',
};

const Map<String, String> _landingMalayalamFallbacks = <String, String>{
  'Home': '\u0d39\u0d4b\u0d02',
  'Features': '\u0d2b\u0d40\u0d1a\u0d4d\u0d1a\u0d31\u0d41\u0d15\u0d7e',
  'Categories': '\u0d15\u0d3e\u0d31\u0d4d\u0d31\u0d17\u0d31\u0d3f\u0d15\u0d7e',
  'Download': '\u0d21\u0d57\u0d7a\u0d32\u0d4b\u0d21\u0d4d',
  'Admin Login':
      '\u0d05\u0d21\u0d4d\u0d2e\u0d3f\u0d7b \u0d32\u0d4b\u0d17\u0d3f\u0d7b',
  'Sign Out': '\u0d38\u0d48\u0d7b \u0d14\u0d1f\u0d4d\u0d1f\u0d4d',
  'Get App': '\u0d06\u0d2a\u0d4d\u0d2a\u0d4d \u0d28\u0d47\u0d1f\u0d42',
  'Ready Telugu templates':
      '\u0d24\u0d2f\u0d4d\u0d2f\u0d3e\u0d7c \u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d \u0d1f\u0d46\u0d02\u0d2a\u0d4d\u0d32\u0d47\u0d31\u0d4d\u0d31\u0d41\u0d15\u0d7e',
  'Start fast with reusable layouts for daily poster needs.':
      '\u0d26\u0d48\u0d28\u0d02\u0d26\u0d3f\u0d28 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d7c \u0d06\u0d35\u0d36\u0d4d\u0d2f\u0d19\u0d4d\u0d19\u0d7e\u0d15\u0d4d\u0d15\u0d4d reusable layouts \u0d09\u0d2a\u0d2f\u0d4b\u0d17\u0d3f\u0d1a\u0d4d\u0d1a\u0d4d \u0d35\u0d47\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d7d \u0d24\u0d41\u0d1f\u0d19\u0d4d\u0d19\u0d42.',
  'Photo + name personalization':
      '\u0d2b\u0d4b\u0d1f\u0d4d\u0d1f\u0d4b + \u0d2a\u0d47\u0d30\u0d4d \u0d35\u0d4d\u0d2f\u0d15\u0d4d\u0d24\u0d3f\u0d17\u0d24\u0d2e\u0d3e\u0d15\u0d4d\u0d15\u0d7d',
  'Update poster identity quickly without redesigning everything.':
      '\u0d2e\u0d41\u0d34\u0d41\u0d35\u0d7b \u0d21\u0d3f\u0d38\u0d48\u0d7b \u0d2e\u0d3e\u0d31\u0d4d\u0d31\u0d3e\u0d24\u0d46 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d3f\u0d32\u0d46 \u0d35\u0d3f\u0d35\u0d30\u0d19\u0d4d\u0d19\u0d7e \u0d35\u0d47\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d7d \u0d05\u0d2a\u0d4d\u200c\u0d21\u0d47\u0d31\u0d4d\u0d31\u0d4d \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d42.',
  'Fast sharing flow':
      '\u0d35\u0d47\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d32\u0d41\u0d33\u0d4d\u0d33 \u0d37\u0d46\u0d2f\u0d31\u0d3f\u0d02\u0d17\u0d4d \u0d2b\u0d4d\u0d32\u0d4b',
  'Export and share in a few taps for WhatsApp-first usage.':
      'WhatsApp-first \u0d09\u0d2a\u0d2f\u0d4b\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d28\u0d4d \u0d15\u0d41\u0d31\u0d1a\u0d4d\u0d1a\u0d4d taps-\u0d7d export \u0d1a\u0d46\u0d2f\u0d4d\u0d24\u0d4d share \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d42.',
  'Poster design mix':
      '\u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d31\u0d4d \u0d21\u0d3f\u0d38\u0d48\u0d28\u0d4d \u0d2e\u0d3f\u0d15\u0d4d\u0d38\u0d4d',
  'Keep poster discovery open while design quality stays clear.':
      '\u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d31\u0d4d \u0d15\u0d23\u0d4d\u0d1f\u0d46\u0d24\u0d4d\u0d24\u0d7d \u0d24\u0d41\u0d31\u0d28\u0d4d\u0d28\u0d41 \u0d35\u0d46\u0d1a\u0d4d\u0d1a\u0d4d, \u0d21\u0d3f\u0d38\u0d48\u0d28\u0d4d \u0d17\u0d41\u0d23\u0d28\u0d3f\u0d32\u0d35\u0d3e\u0d30\u0d02 \u0d35\u0d4d\u0d2f\u0d15\u0d4d\u0d24\u0d2e\u0d3e\u0d15\u0d41\u0d28\u0d4d\u0d28 \u0d30\u0d40\u0d24\u0d3f\u0d2f\u0d3f\u0d32\u0d3e\u0d23\u0d4d.',
  'Festival posters':
      '\u0d09\u0d24\u0d4d\u0d38\u0d35 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e',
  'Date-based festival content can stay discoverable without manual browsing.':
      '\u0d24\u0d40\u0d2f\u0d24\u0d3f \u0d05\u0d1f\u0d3f\u0d38\u0d4d\u0d25\u0d3e\u0d28\u0d24\u0d4d\u0d24\u0d3f\u0d32\u0d41\u0d33\u0d4d\u0d33 \u0d09\u0d24\u0d4d\u0d38\u0d35 content manual browsing \u0d07\u0d32\u0d4d\u0d32\u0d3e\u0d24\u0d46\u0d2f\u0d41\u0d02 \u0d15\u0d3e\u0d23\u0d3e\u0d28\u0d3e\u0d15\u0d41\u0d02.',
  'National days':
      '\u0d26\u0d47\u0d36\u0d40\u0d2f \u0d26\u0d3f\u0d28\u0d19\u0d4d\u0d19\u0d7e',
  'Important observances are easier to surface when the day matters.':
      '\u0d2a\u0d4d\u0d30\u0d27\u0d3e\u0d28 observances \u0d36\u0d30\u0d3f\u0d2f\u0d3e\u0d2f \u0d26\u0d3f\u0d35\u0d38\u0d02 \u0d0e\u0d33\u0d41\u0d2a\u0d4d\u0d2a\u0d24\u0d4d\u0d24\u0d3f\u0d7d \u0d15\u0d3e\u0d23\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d02.',
  'Local event updates':
      '\u0d32\u0d4b\u0d15\u0d4d\u0d15\u0d7d \u0d07\u0d35\u0d28\u0d4d\u0d31\u0d4d \u0d05\u0d2a\u0d4d\u200c\u0d21\u0d47\u0d31\u0d4d\u0d31\u0d41\u0d15\u0d7e',
  'Telugu state relevance stays visible in one dedicated block.':
      '\u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d \u0d38\u0d02\u0d38\u0d4d\u0d25\u0d3e\u0d28\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d2e\u0d3e\u0d2f\u0d3f \u0d2c\u0d28\u0d4d\u0d27\u0d2a\u0d4d\u0d2a\u0d46\u0d1f\u0d4d\u0d1f\u0d24\u0d4d \u0d12\u0d30\u0d41 dedicated block-\u0d7d \u0d35\u0d4d\u0d2f\u0d15\u0d4d\u0d24\u0d2e\u0d3e\u0d2f\u0d3f \u0d15\u0d3e\u0d23\u0d3e\u0d02.',
  'Free Posters':
      '\u0d2b\u0d4d\u0d30\u0d40 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e',
  'Starter':
      '\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d3e\u0d7c\u0d1f\u0d4d\u0d1f\u0d7c',
  'Basic templates':
      '\u0d2c\u0d47\u0d38\u0d3f\u0d15\u0d4d \u0d1f\u0d46\u0d02\u0d2a\u0d4d\u0d32\u0d47\u0d31\u0d4d\u0d31\u0d41\u0d15\u0d7e',
  'Quick sharing':
      '\u0d15\u0d4d\u0d35\u0d3f\u0d15\u0d4d\u0d15\u0d4d \u0d37\u0d46\u0d2f\u0d31\u0d3f\u0d02\u0d17\u0d4d',
  'Simple export': '\u0d32\u0d33\u0d3f\u0d24\u0d2e\u0d3e\u0d2f export',
  'Featured Posters':
      '\u0d2a\u0d4d\u0d30\u0d40\u0d2e\u0d3f\u0d2f\u0d02 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e',
  'Pro Access': '\u0d2a\u0d4d\u0d30\u0d4b \u0d06\u0d15\u0d4d\u0d38\u0d38\u0d4d',
  'Fully editable posters':
      '\u0d2a\u0d42\u0d7c\u0d23\u0d4d\u0d23\u0d2e\u0d3e\u0d2f\u0d3f editable \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e',
  'More templates':
      '\u0d2a\u0d4d\u0d30\u0d40\u0d2e\u0d3f\u0d2f\u0d02 \u0d1f\u0d46\u0d02\u0d2a\u0d4d\u0d32\u0d47\u0d31\u0d4d\u0d31\u0d41\u0d15\u0d7e',
  'Unlimited customization':
      '\u0d05\u0d7a\u0d32\u0d3f\u0d2e\u0d3f\u0d31\u0d4d\u0d31\u0d21\u0d4d customization',
  'HD export': 'HD export',
  'Is Mana Poster Ai AI free?': 'Mana Poster Ai AI ഫ്രീ ആണോ?',
  'Posters are available with stronger templates and deeper editing inside the app.':
      '\u0d06\u0d2a\u0d4d\u0d2a\u0d3f\u0d32\u0d4d posters create, personalize \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d3e\u0d28\u0d41\u0d02 share \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d3e\u0d28\u0d41\u0d02 simple options \u0d32\u0d2d\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d02.',
  'Can I add photo and name?': 'ഫോട്ടോയും പേരും ചേർക്കാനാകുമോ?',
  'Yes. Personal details can be placed directly on poster templates.':
      '\u0d05\u0d24\u0d46. \u0d35\u0d4d\u0d2f\u0d15\u0d4d\u0d24\u0d3f\u0d17\u0d24 \u0d35\u0d3f\u0d35\u0d30\u0d19\u0d4d\u0d19\u0d7e poster templates-\u0d3f\u0d7d \u0d28\u0d47\u0d30\u0d3f\u0d1f\u0d4d\u0d1f\u0d4d \u0d1a\u0d47\u0d7c\u0d15\u0d4d\u0d15\u0d3e\u0d02.',
  'Are daily categories updated?': 'ദൈനംദിന categories update ആവുമോ?',
  'The landing page and app can surface time-based categories and special poster needs.':
      '\u0d06\u0d2a\u0d4d\u0d2a\u0d3f\u0d32\u0d4d time-based categories \u0d09\u0d02 daily poster needs \u0d09\u0d02 \u0d15\u0d3e\u0d23\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d02.',
  'Can I export posters?': 'എനിക്ക് പോസ്റ്ററുകൾ export ചെയ്യാനാകുമോ?',
  'Yes. Export and share flows stay simple for daily usage.':
      '\u0d05\u0d24\u0d46. \u0d26\u0d48\u0d28\u0d02\u0d26\u0d3f\u0d28 \u0d09\u0d2a\u0d2f\u0d4b\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d28\u0d4d export, share flow \u0d32\u0d33\u0d3f\u0d24\u0d2e\u0d3e\u0d2f\u0d3f\u0d30\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d02.',
  'Quick Links':
      '\u0d15\u0d4d\u0d35\u0d3f\u0d15\u0d4d\u0d15\u0d4d \u0d32\u0d3f\u0d19\u0d4d\u0d15\u0d41\u0d15\u0d7e',
  'Legal': '\u0d32\u0d40\u0d17\u0d7d',
  'Privacy Policy':
      '\u0d2a\u0d4d\u0d30\u0d48\u0d35\u0d38\u0d3f \u0d2a\u0d4b\u0d33\u0d3f\u0d38\u0d3f',
  'Terms & Conditions':
      '\u0d28\u0d3f\u0d2c\u0d28\u0d4d\u0d27\u0d28\u0d15\u0d33\u0d41\u0d02 \u0d35\u0d4d\u0d2f\u0d35\u0d38\u0d4d\u0d25\u0d15\u0d33\u0d41\u0d02',
  'Contact':
      '\u0d2c\u0d28\u0d4d\u0d27\u0d2a\u0d4d\u0d2a\u0d46\u0d1f\u0d41\u0d15',
  'Telugu-first poster creation':
      '\u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d-\u0d2b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d4d \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d7c \u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f',
  'Create Telugu Posters in Seconds':
      '\u0d38\u0d46\u0d15\u0d4d\u0d15\u0d7b\u0d21\u0d41\u0d15\u0d7e\u0d15\u0d4d\u0d15\u0d15\u0d02 \u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e \u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d15\u0d4d\u0d15\u0d42',
  'Mana Poster Ai lets users create, customize, and share Telugu posters instantly with a simple, fast workflow.':
      '\u0d38\u0d30\u0d33\u0d35\u0d41\u0d02 \u0d35\u0d47\u0d17\u0d2e\u0d41\u0d33\u0d4d\u0d33 workflow \u0d09\u0d2a\u0d2f\u0d4b\u0d17\u0d3f\u0d1a\u0d4d\u0d1a\u0d4d \u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e \u0d09\u0d1f\u0d7b create, customize, share \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d3e\u0d7b Mana Poster Ai \u0d38\u0d39\u0d3e\u0d2f\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d28\u0d4d\u0d28\u0d41.',
  'Watch Demo': '\u0d21\u0d46\u0d2e\u0d4b \u0d15\u0d3e\u0d23\u0d42',
  'Poster Collections Available':
      '\u0d2b\u0d4d\u0d30\u0d40\u0d2f\u0d41\u0d02 \u0d2a\u0d4d\u0d30\u0d40\u0d2e\u0d3f\u0d2f\u0d35\u0d41\u0d02 \u0d09\u0d33\u0d4d\u0d33 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e \u0d32\u0d2d\u0d4d\u0d2f\u0d2e\u0d3e\u0d23\u0d4d',
  'App Preview':
      '\u0d06\u0d2a\u0d4d\u0d2a\u0d4d \u0d2a\u0d4d\u0d30\u0d3f\u0d35\u0d4d\u0d2f\u0d42',
  'A clear view of how poster flow looks inside the app':
      '\u0d06\u0d2a\u0d4d\u0d2a\u0d3f\u0d28\u0d41\u0d33\u0d4d\u0d33\u0d3f\u0d32\u0d46 poster flow \u0d0e\u0d19\u0d4d\u0d19\u0d28\u0d46 \u0d15\u0d3e\u0d23\u0d2a\u0d4d\u0d2a\u0d46\u0d1f\u0d41\u0d28\u0d4d\u0d28\u0d41 \u0d0e\u0d28\u0d4d\u0d28\u0d24\u0d3f\u0d28\u0d4d\u0d31\u0d46 \u0d35\u0d4d\u0d2f\u0d15\u0d4d\u0d24\u0d2e\u0d3e\u0d2f \u0d26\u0d43\u0d36\u0d4d\u0d2f\u0d02',
  'The flow is designed to stay simple from category selection to preview, personalization, and final sharing.':
      'Category selection \u0d2e\u0d41\u0d24\u0d7d preview, personalization, final sharing \u0d35\u0d30\u0d46 flow \u0d32\u0d33\u0d3f\u0d24\u0d2e\u0d3e\u0d2f\u0d3f \u0d30\u0d42\u0d2a\u0d15\u0d7d\u0d2a\u0d4d\u0d2a\u0d28 \u0d1a\u0d46\u0d2f\u0d4d\u0d24\u0d3f\u0d30\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d28\u0d4d\u0d28\u0d41.',
  'Built for fast Telugu poster creation':
      '\u0d35\u0d47\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d32\u0d41\u0d33\u0d4d\u0d33 \u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d7c \u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d15\u0d4d\u0d15\u0d3e\u0d2f\u0d3f \u0d28\u0d3f\u0d7c\u0d2e\u0d4d\u0d2e\u0d3f\u0d1a\u0d4d\u0d1a\u0d24\u0d4d',
  'Templates, sharing, personalization, and daily-use category flows are organized to keep poster making quick and repeatable.':
      'Templates, sharing, personalization, daily-use category flows \u0d0e\u0d28\u0d4d\u0d28\u0d3f\u0d35 poster making \u0d35\u0d47\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d32\u0d41\u0d02 repeatable \u0d06\u0d2f\u0d41\u0d02 \u0d28\u0d3f\u0d32\u0d28\u0d3f\u0d7c\u0d24\u0d4d\u0d24\u0d3e\u0d7b \u0d15\u0d4d\u0d30\u0d2e\u0d40\u0d15\u0d30\u0d3f\u0d1a\u0d4d\u0d1a\u0d3f\u0d30\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d28\u0d4d\u0d28\u0d41.',
  'Colorful Category Gallery':
      '\u0d28\u0d3f\u0d31\u0d2e\u0d41\u0d33\u0d4d\u0d33 \u0d15\u0d3e\u0d31\u0d4d\u0d31\u0d17\u0d31\u0d3f \u0d17\u0d3e\u0d32\u0d31\u0d3f',
  'Each category opens like a poster wall so the landing page feels rich, bold, and closer to a real creative marketplace.':
      '\u0d13\u0d30\u0d4b category-\u0d2f\u0d41\u0d02 poster wall \u0d2a\u0d4b\u0d32\u0d46 \u0d24\u0d41\u0d31\u0d15\u0d4d\u0d15\u0d41\u0d28\u0d4d\u0d28\u0d24\u0d3f\u0d28\u0d3e\u0d7d landing page \u0d38\u0d2e\u0d4d\u0d2a\u0d28\u0d4d\u0d28\u0d35\u0d41\u0d02 bold-\u0d09\u0d02 creative marketplace \u0d2a\u0d4b\u0d32\u0d46 \u0d05\u0d28\u0d41\u0d2d\u0d35\u0d2a\u0d4d\u0d2a\u0d46\u0d1f\u0d41\u0d02.',
  'Today\'s Special Posters':
      '\u0d07\u0d28\u0d4d\u0d28\u0d24\u0d4d\u0d24\u0d46 \u0d38\u0d4d\u0d2a\u0d46\u0d37\u0d4d\u0d2f\u0d7d \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e',
  'Every Day New Posters Automatically':
      '\u0d2a\u0d4d\u0d30\u0d24\u0d3f\u0d26\u0d3f\u0d28\u0d02 \u0d2a\u0d41\u0d24\u0d3f\u0d2f \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e \u0d38\u0d4d\u0d35\u0d2f\u0d02',
  'Mana Poster Ai automatically shows posters for Festivals, Jayanthi, Vardhanthi, National Days and Telugu State Events based on the selected date.':
      '\u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d24\u0d4d\u0d24 \u0d24\u0d40\u0d2f\u0d24\u0d3f\u0d2f\u0d41\u0d1f\u0d46 \u0d05\u0d1f\u0d3f\u0d38\u0d4d\u0d25\u0d3e\u0d28\u0d24\u0d4d\u0d24\u0d3f\u0d7d Festivals, Jayanthi, Vardhanthi, National Days, Telugu State Events \u0d0e\u0d28\u0d4d\u0d28\u0d40 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e Mana Poster Ai \u0d38\u0d4d\u0d35\u0d2e\u0d47\u0d27\u0d2f\u0d3e \u0d15\u0d3e\u0d23\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d02.',
  'Poster Options':
      '\u0d2b\u0d4d\u0d30\u0d40 vs \u0d2a\u0d4d\u0d30\u0d40\u0d2e\u0d3f\u0d2f\u0d02',
  'Choose the plan that fits your poster workflow':
      '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 poster workflow-\u0d2f\u0d4d\u0d15\u0d4d\u0d15\u0d4d \u0d1a\u0d47\u0d30\u0d41\u0d28\u0d4d\u0d28 \u0d2a\u0d4d\u0d32\u0d3e\u0d7b \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d42',
  'Choose from quick daily posters and fully editable poster options with better exports and faster personalization.':
      '\u0d35\u0d47\u0d17\u0d24\u0d4d\u0d24\u0d3f\u0d32\u0d41\u0d33\u0d4d\u0d33 daily posters, export options \u0d09\u0d02 simple personalization flows \u0d09\u0d02 choose \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d3e\u0d02.',
  'Frequently asked questions':
      '\u0d2a\u0d24\u0d3f\u0d35\u0d4d \u0d1a\u0d4b\u0d26\u0d4d\u0d2f\u0d19\u0d4d\u0d19\u0d7e',
  'Common doubts about templates, photos, HD downloads, and daily Telugu poster updates.':
      'Templates, photos, HD downloads, daily Telugu poster updates \u0d0e\u0d28\u0d4d\u0d28\u0d3f\u0d35\u0d2f\u0d46\u0d15\u0d4d\u0d15\u0d41\u0d31\u0d3f\u0d1a\u0d4d\u0d1a\u0d41\u0d33\u0d4d\u0d33 \u0d2a\u0d4a\u0d24\u0d41\u0d35\u0d3e\u0d2f \u0d38\u0d02\u0d36\u0d2f\u0d19\u0d4d\u0d19\u0d7e.',
  'Final CTA': '\u0d05\u0d35\u0d38\u0d3e\u0d28 CTA',
  'Start Creating Beautiful Telugu Posters Today':
      '\u0d07\u0d28\u0d4d\u0d28\u0d41\u0d24\u0d28\u0d4d\u0d28\u0d46 \u0d2e\u0d28\u0d4b\u0d39\u0d30\u0d2e\u0d3e\u0d2f \u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e \u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d15\u0d4d\u0d15\u0d3e\u0d7b \u0d24\u0d41\u0d1f\u0d19\u0d4d\u0d19\u0d42',
  'Ready templates, Telugu-friendly typing, photo placement, and fast sharing come together in one app.':
      'Ready templates, Telugu-friendly typing, photo placement, fast sharing \u0d0e\u0d28\u0d4d\u0d28\u0d3f\u0d35 \u0d0e\u0d32\u0d4d\u0d32\u0d3e\u0d02 \u0d12\u0d30\u0d4a\u0d31\u0d4d\u0d31 app-\u0d7d \u0d12\u0d28\u0d4d\u0d28\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d28\u0d4d\u0d28\u0d41.',
  'Mana Poster Ai is a simple way to create and share Telugu posters every day.':
      '\u0d2a\u0d4d\u0d30\u0d24\u0d3f\u0d26\u0d3f\u0d28\u0d02 \u0d24\u0d46\u0d32\u0d41\u0d19\u0d4d\u0d15\u0d4d \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d7e \u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d15\u0d4d\u0d15\u0d3e\u0d28\u0d41\u0d02 share \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d3e\u0d28\u0d41\u0d02 Mana Poster Ai \u0d12\u0d30\u0d41 \u0d32\u0d33\u0d3f\u0d24\u0d2e\u0d3e\u0d2f \u0d2e\u0d3e\u0d7c\u0d17\u0d2e\u0d3e\u0d23\u0d4d.',
};

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isTelugu => language == AppLanguage.telugu;
  bool get isHindi => language == AppLanguage.hindi;
  bool get isEnglish => language == AppLanguage.english;
  bool get isTamil => language == AppLanguage.tamil;
  bool get isKannada => language == AppLanguage.kannada;
  bool get isMalayalam => language == AppLanguage.malayalam;

  String localized({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
  }) {
    final fallback = _sanitizeDisplayText(english);
    final regionalFallback = _regionalFallback(english);
    if (regionalFallback != null) {
      return _sanitizeDisplayText(regionalFallback, fallback: fallback);
    }
    final preferred = switch (language.supportedUiLanguage) {
      SupportedUiLanguage.telugu => telugu,
      SupportedUiLanguage.hindi =>
        hindi ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.english => english,
      SupportedUiLanguage.tamil =>
        tamil ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.kannada =>
        kannada ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.malayalam =>
        malayalam ?? _commonLocalizedFallback(english) ?? english,
    };
    return _sanitizeDisplayText(preferred, fallback: fallback);
  }

  String _sanitizeDisplayText(String value, {String? fallback}) {
    final normalized = _decodeMojibake(value)
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00e2\u201e\u00a2", "'")
        .replaceAll("\u00e2\u20ac\u02dc", "'")
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00c5\u201c", '"')
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00c2\u009d", '"')
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00e2\u20ac\u0153", "-")
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00e2\u20ac\u009d", "-")
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00c2\u00a6", "...")
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00c5\u2019", "")
        .replaceAll("\u00c3\u00a2\u00e2\u201a\u00ac\u00c2\u008d", "")
        .replaceAll("\u00c3\u00a2\u20ac\u0161\u00c2\u00b9", "Rs.")
        .replaceAll(
          RegExp(r"^(?:\u00c3\u00b0\u00c5\u00b8[^\s]*|\u00c3\u00a2[^\s]*)\s*"),
          "",
        )
        .trim();
    if (_looksCorrupted(normalized)) {
      return (fallback == null || fallback.trim().isEmpty)
          ? normalized
          : fallback.trim();
    }
    return normalized;
  }

  String _decodeMojibake(String value) {
    if (!_looksCorrupted(value) && !_containsPlainMojibakeLeadBytes(value)) {
      return value;
    }
    try {
      final decoded = utf8.decode(latin1.encode(value), allowMalformed: true);
      return decoded.trim().isEmpty ? value : decoded;
    } catch (_) {
      return value;
    }
  }

  bool _containsPlainMojibakeLeadBytes(String value) {
    return value.contains('à°') ||
        value.contains('à¤') ||
        value.contains('à®') ||
        value.contains('à²') ||
        value.contains('à´');
  }

  bool _looksCorrupted(String value) {
    if (value.contains('à°') ||
        value.contains('à¤') ||
        value.contains('à®') ||
        value.contains('à²') ||
        value.contains('à´')) {
      return true;
    }
    return value.contains("\u00c3\u00a0") ||
        value.contains("\u00c3\u00a2\u00e2\u201a\u00ac") ||
        value.contains("\u00c3\u00a2\u00c5\u201c") ||
        value.contains("\u00c3\u00b0\u00c5\u00b8") ||
        value.contains("\u00c3\u00af\u00c2\u00b8") ||
        value.contains("\u00c3\u00a2\u00c2\u009d") ||
        value.contains('à°') ||
        value.contains('à¤') ||
        value.contains('à®') ||
        value.contains('à²') ||
        value.contains('à´') ||
        value.contains('â€') ||
        value.contains('â€™') ||
        value.contains('â€œ') ||
        value.contains('â€');
  }

  String? _commonLocalizedFallback(String english) {
    switch (language.supportedUiLanguage) {
      case SupportedUiLanguage.hindi:
        return _commonHindiFallback(english);
      case SupportedUiLanguage.tamil:
        return _commonTamilFallback(english);
      case SupportedUiLanguage.kannada:
        return _commonKannadaFallback(english);
      case SupportedUiLanguage.malayalam:
        return _commonMalayalamFallback(english);
      case SupportedUiLanguage.telugu:
      case SupportedUiLanguage.english:
        return null;
    }
  }

  String? _regionalFallback(String english) {
    if (language == AppLanguage.bengali) {
      return _regionalCommonFallbacks[language]?[english] ??
          _commonBengaliFallback(english);
    }
    return _regionalCommonFallbacks[language]?[english];
  }

  String? _commonBengaliFallback(String english) {
    return switch (english) {
      'Select State / Union Territory' =>
        'রাজ্য / কেন্দ্রশাসিত অঞ্চল নির্বাচন করুন',
      'Search State, UT or language' =>
        'রাজ্য, কেন্দ্রশাসিত অঞ্চল বা ভাষা খুঁজুন',
      'No matching region found.' => 'মিল থাকা অঞ্চল পাওয়া যায়নি।',
      'Political Parties' => 'রাজনৈতিক দল',
      'National' => 'জাতীয়',
      'State' => 'রাজ্য',
      'Continue' => 'চালিয়ে যান',
      'Login' => 'লগইন',
      'Sign Up' => 'সাইন আপ',
      'Continue with Google' => 'Google দিয়ে চালিয়ে যান',
      'Email address' => 'ইমেল ঠিকানা',
      'Password' => 'পাসওয়ার্ড',
      'Forgot Password' => 'পাসওয়ার্ড ভুলে গেছেন?',
      "Don't have an account?" => 'অ্যাকাউন্ট নেই?',
      'Already have an account?' => 'আগেই অ্যাকাউন্ট আছে?',
      'Login with Email' => 'ইমেল দিয়ে লগইন করুন',
      'Sign Up with Email' => 'ইমেল দিয়ে সাইন আপ করুন',
      'Enter valid email' => 'সঠিক ইমেল লিখুন',
      'Minimum 6 characters required' => 'কমপক্ষে ৬টি অক্ষর প্রয়োজন',
      'Password reset will be available soon.' =>
        'পাসওয়ার্ড রিসেট শীঘ্রই পাওয়া যাবে।',
      'A few permissions are needed' => 'কিছু অনুমতি প্রয়োজন',
      'Photos/Gallery' => 'ফটো / গ্যালারি',
      'Notifications' => 'নোটিফিকেশন',
      'Allow' => 'অনুমতি দিন',
      'Later' => 'পরে',
      'Create & Share' => 'তৈরি করুন ও শেয়ার করুন',
      'Create' => 'তৈরি করুন',
      'Search templates' => 'টেমপ্লেট খুঁজুন',
      'Ready' => 'প্রস্তুত',
      'Special' => 'বিশেষ',
      'Buy' => 'কিনুন',
      'Share WhatsApp' => 'WhatsApp এ শেয়ার',
      'Download' => 'ডাউনলোড',
      'Profile & Settings' => 'প্রোফাইল ও সেটিংস',
      'Account' => 'অ্যাকাউন্ট',
      'App Settings' => 'অ্যাপ সেটিংস',
      'Support' => 'সহায়তা',
      'Language' => 'ভাষা',
      'Subscription' => 'সাবস্ক্রিপশন',
      'Help & Support' => 'সাহায্য ও সহায়তা',
      'About App' => 'অ্যাপ সম্পর্কে',
      'Logout' => 'লগআউট',
      'Language Settings' => 'ভাষা সেটিংস',
      'Current language' => 'বর্তমান ভাষা',
      'Save / Apply' => 'সেভ / প্রয়োগ করুন',
      'Add Photo' => 'ফটো যোগ করুন',
      'Text' => 'টেক্সট',
      'Stickers' => 'স্টিকার',
      'Background' => 'ব্যাকগ্রাউন্ড',
      'Layers' => 'লেয়ার',
      'Adjust' => 'অ্যাডজাস্ট',
      'Crop' => 'ক্রপ',
      'Eraser' => 'ইরেজার',
      'Remove BG' => 'BG সরান',
      'Edit' => 'এডিট',
      'Fonts' => 'ফন্ট',
      'Options' => 'অপশন',
      'Style' => 'স্টাইল',
      'Effects' => 'ইফেক্ট',
      'Size' => 'সাইজ',
      'Line' => 'লাইন',
      'Letter' => 'অক্ষর',
      'Opacity' => 'অপাসিটি',
      'Curve' => 'কার্ভ',
      'Stroke' => 'স্ট্রোক',
      'Shadow' => 'শ্যাডো',
      'Blur' => 'ব্লার',
      'Offset' => 'অফসেট',
      'Back' => 'পিছনে',
      'Undo' => 'আনডু',
      'Redo' => 'রিডু',
      'Drafts' => 'ড্রাফট',
      'Export' => 'এক্সপোর্ট',
      'Saving...' => 'সেভ হচ্ছে...',
      'Reset' => 'রিসেট',
      'Apply' => 'প্রয়োগ করুন',
      'Applying...' => 'প্রয়োগ হচ্ছে...',
      'Erase' => 'মুছুন',
      'Restore' => 'রিস্টোর',
      'Brightness' => 'ব্রাইটনেস',
      'Contrast' => 'কনট্রাস্ট',
      'Saturation' => 'স্যাচুরেশন',
      'Share' => 'শেয়ার',
      'Select a photo first' => 'প্রথমে একটি ফটো নির্বাচন করুন',
      'Canvas is empty' => 'ক্যানভাস খালি',
      'Cancel' => 'বাতিল',
      'Yes, export' => 'হ্যাঁ, এক্সপোর্ট করুন',
      _ => null,
    };
  }

  String? _commonHindiFallback(String english) {
    final landing = _landingHindiFallbacks[english];
    if (landing != null) {
      return landing;
    }
    return switch (english) {
      'Add Photo' =>
        '\u092b\u094b\u091f\u094b \u091c\u094b\u0921\u093c\u0947\u0902',
      'Text' => '\u091f\u0947\u0915\u094d\u0938\u094d\u091f',
      'Stickers' => '\u0938\u094d\u091f\u093f\u0915\u0930\u094d\u0938',
      'Background' =>
        '\u092c\u0948\u0915\u0917\u094d\u0930\u093e\u0909\u0902\u0921',
      'Layers' => '\u0932\u0947\u092f\u0930\u094d\u0938',
      'Adjust' => '\u090f\u0921\u091c\u0938\u094d\u091f',
      'Crop' => '\u0915\u094d\u0930\u0949\u092a',
      'Eraser' => '\u0907\u0930\u0947\u091c\u093c\u0930',
      'Remove BG' => '\u092c\u0940\u091c\u0940 \u0939\u091f\u093e\u090f\u0902',
      'Edit' => '\u090f\u0921\u093f\u091f',
      'Fonts' => '\u092b\u0949\u0928\u094d\u091f\u094d\u0938',
      'Options' => '\u0911\u092a\u094d\u0936\u0928\u094d\u0938',
      'Style' => '\u0938\u094d\u091f\u093e\u0907\u0932',
      'Effects' => '\u0907\u092b\u0947\u0915\u094d\u091f\u094d\u0938',
      'Size' => '\u0938\u093e\u0907\u091c\u093c',
      'Line' => '\u0932\u093e\u0907\u0928',
      'Letter' => '\u0932\u0947\u091f\u0930',
      'Opacity' => '\u0913\u092a\u0947\u0938\u093f\u091f\u0940',
      'Curve' => '\u0915\u0930\u094d\u0935',
      'Stroke' => '\u0938\u094d\u091f\u094d\u0930\u094b\u0915',
      'Shadow' => '\u0936\u0948\u0921\u094b',
      'Blur' => '\u092c\u094d\u0932\u0930',
      'Offset' => '\u0911\u092b\u0938\u0947\u091f',
      'Back' => '\u0935\u093e\u092a\u0938',
      'Undo' => '\u0905\u0928\u0921\u0942',
      'Redo' => '\u0930\u0940\u0921\u0942',
      'Drafts' => '\u0921\u094d\u0930\u093e\u092b\u094d\u091f\u094d\u0938',
      'Export' => '\u090f\u0915\u094d\u0938\u092a\u094b\u0930\u094d\u091f',
      'Saving...' =>
        '\u0938\u0947\u0935 \u0939\u094b \u0930\u0939\u093e \u0939\u0948...',
      'Send back' => '\u092a\u0940\u091b\u0947 \u092d\u0947\u091c\u0947\u0902',
      'Bring front' => '\u0906\u0917\u0947 \u0932\u093e\u090f\u0902',
      'Duplicate selected' =>
        '\u0921\u0941\u092a\u094d\u0932\u093f\u0915\u0947\u091f',
      'Delete selected' => '\u0921\u093f\u0932\u0940\u091f',
      'Photo quick actions' =>
        '\u092b\u094b\u091f\u094b \u0915\u094d\u0935\u093f\u0915 \u0910\u0915\u094d\u0936\u0928\u094d\u0938',
      'Selected photo' =>
        '\u091a\u0941\u0928\u0940 \u0939\u0941\u0908 \u092b\u094b\u091f\u094b',
      'Text tools' =>
        '\u091f\u0947\u0915\u094d\u0938\u094d\u091f \u091f\u0942\u0932\u094d\u0938',
      'Brush' => '\u092c\u094d\u0930\u0936',
      'Soft' => '\u0938\u0949\u092b\u094d\u091f',
      'Strength' => '\u0938\u094d\u091f\u094d\u0930\u0947\u0902\u0925',
      'Reset' => '\u0930\u0940\u0938\u0947\u091f',
      'Apply' => '\u0905\u092a\u094d\u0932\u093e\u0908',
      'Applying...' =>
        '\u0905\u092a\u094d\u0932\u093e\u0908 \u0939\u094b \u0930\u0939\u093e \u0939\u0948...',
      'Erase' => '\u092e\u093f\u091f\u093e\u090f\u0902',
      'Restore' => '\u0930\u0940\u0938\u094d\u091f\u094b\u0930',
      'Brightness' => '\u092c\u094d\u0930\u093e\u0907\u091f\u0928\u0947\u0938',
      'Contrast' =>
        '\u0915\u0949\u0928\u094d\u091f\u094d\u0930\u093e\u0938\u094d\u091f',
      'Saturation' => '\u0938\u0948\u091a\u0941\u0930\u0947\u0936\u0928',
      'Free' => '\u092b\u094d\u0930\u0940',
      'Elements' => '\u090f\u0932\u093f\u092e\u0947\u0902\u091f\u094d\u0938',
      'Search elements' =>
        '\u090f\u0932\u093f\u092e\u0947\u0902\u091f\u094d\u0938 \u0916\u094b\u091c\u0947\u0902',
      'Selected' => '\u091a\u0941\u0928\u093e \u0917\u092f\u093e',
      'Hidden' => '\u091b\u093f\u092a\u093e \u0939\u0941\u0906',
      'Locked' => '\u0932\u0949\u0915\u094d\u0921',
      'Show' => '\u0926\u093f\u0916\u093e\u090f\u0902',
      'Hide' => '\u091b\u093f\u092a\u093e\u090f\u0902',
      'Unlock' => '\u0905\u0928\u0932\u0949\u0915',
      'Lock' => '\u0932\u0949\u0915',
      'Delete' => '\u0921\u093f\u0932\u0940\u091f',
      'Share' => '\u0936\u0947\u092f\u0930',
      'Select a photo first' =>
        '\u092a\u0939\u0932\u0947 \u090f\u0915 \u092b\u094b\u091f\u094b \u091a\u0941\u0928\u0947\u0902',
      'Selected image could not be loaded' =>
        '\u091a\u0941\u0928\u0940 \u0917\u0908 \u0907\u092e\u0947\u091c \u0932\u094b\u0921 \u0928\u0939\u0940\u0902 \u0939\u0941\u0908',
      'Canvas is empty' =>
        '\u0915\u0948\u0928\u0935\u093e\u0938 \u0916\u093e\u0932\u0940 \u0939\u0948',
      'Cancel' => '\u0930\u0926\u094d\u0926 \u0915\u0930\u0947\u0902',
      'Yes, export' =>
        '\u0939\u093e\u0901, \u090f\u0915\u094d\u0938\u092a\u094b\u0930\u094d\u091f \u0915\u0930\u0947\u0902',
      'Crop mode' => '\u0915\u094d\u0930\u0949\u092a \u092e\u094b\u0921',
      'Eraser mode' =>
        '\u0907\u0930\u0947\u091c\u093c\u0930 \u092e\u094b\u0921',
      'Adjust mode' =>
        '\u090f\u0921\u091c\u0938\u094d\u091f \u092e\u094b\u0921',
      'Text styling' =>
        '\u091f\u0947\u0915\u094d\u0938\u094d\u091f \u0938\u094d\u091f\u093e\u0907\u0932\u093f\u0902\u0917',
      'Text selected' =>
        '\u091f\u0947\u0915\u094d\u0938\u094d\u091f \u091a\u0941\u0928\u093e \u0917\u092f\u093e',
      'Photo selected' =>
        '\u092b\u094b\u091f\u094b \u091a\u0941\u0928\u0940 \u0917\u0908',
      'Object selected' =>
        '\u0911\u092c\u094d\u091c\u0947\u0915\u094d\u091f \u091a\u0941\u0928\u093e \u0917\u092f\u093e',
      _ => null,
    };
  }

  String? _commonTamilFallback(String english) {
    final landing = _landingTamilFallbacks[english];
    if (landing != null) {
      return landing;
    }
    return switch (english) {
      'Add Photo' =>
        '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0bae\u0bcd \u0b9a\u0bc7\u0bb0\u0bcd\u0b95\u0bcd\u0b95',
      'Text' => '\u0b89\u0bb0\u0bc8',
      'Stickers' =>
        '\u0bb8\u0bcd\u0b9f\u0bbf\u0b95\u0bcd\u0b95\u0bb0\u0bcd\u0b95\u0bb3\u0bcd',
      'Background' => '\u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0ba3\u0bbf',
      'Layers' => '\u0bb2\u0bc7\u0baf\u0bb0\u0bcd\u0b95\u0bb3\u0bcd',
      'Adjust' => '\u0b85\u0b9f\u0bcd\u0b9c\u0bb8\u0bcd\u0b9f\u0bcd',
      'Crop' => '\u0b95\u0bbf\u0bb0\u0bbe\u0baa\u0bcd',
      'Eraser' => '\u0b87\u0bb0\u0bc7\u0b9a\u0bb0\u0bcd',
      'Remove BG' =>
        '\u0baa\u0bbf\u0ba9\u0bcd\u0baa\u0bc1\u0bb2\u0bae\u0bcd \u0ba8\u0bc0\u0b95\u0bcd\u0b95\u0bc1',
      'Edit' => '\u0ba4\u0bbf\u0bb0\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1',
      'Fonts' =>
        '\u0b8e\u0bb4\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0bb0\u0bc1\u0b95\u0bcd\u0b95\u0bb3\u0bcd',
      'Options' =>
        '\u0bb5\u0bbf\u0bb0\u0bc1\u0baa\u0bcd\u0baa\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
      'Style' => '\u0bb8\u0bcd\u0b9f\u0bc8\u0bb2\u0bcd',
      'Effects' =>
        '\u0b8e\u0b83\u0baa\u0bc6\u0b95\u0bcd\u0b9f\u0bcd\u0bb8\u0bcd',
      'Size' => '\u0b85\u0bb3\u0bb5\u0bc1',
      'Line' => '\u0bb5\u0bb0\u0bbf',
      'Letter' => '\u0b8e\u0bb4\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1',
      'Opacity' =>
        '\u0b92\u0baa\u0bcd\u0baa\u0bbe\u0b9a\u0bbf\u0b9f\u0bcd\u0b9f\u0bbf',
      'Curve' => '\u0bb5\u0bb3\u0bc8\u0bb5\u0bc1',
      'Stroke' => '\u0bb8\u0bcd\u0b9f\u0bcd\u0bb0\u0bcb\u0b95\u0bcd',
      'Shadow' => '\u0ba8\u0bbf\u0bb4\u0bb2\u0bcd',
      'Blur' => '\u0baa\u0bcd\u0bb3\u0bb0\u0bcd',
      'Offset' => '\u0b86\u0b83\u0baa\u0bcd\u0b9a\u0bc6\u0b9f\u0bcd',
      'Back' => '\u0baa\u0bbf\u0ba9\u0bcd',
      'Undo' => '\u0b85\u0ba9\u0bcd\u0b9f\u0bc2',
      'Redo' => '\u0bb0\u0bc0\u0b9f\u0bc2',
      'Drafts' => '\u0bb5\u0bb0\u0bc8\u0bb5\u0bc1\u0b95\u0bb3\u0bcd',
      'Export' => '\u0b8f\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0ba4\u0bbf',
      'Saving...' =>
        '\u0b9a\u0bc7\u0bae\u0bbf\u0b95\u0bcd\u0b95\u0bbf\u0bb1\u0ba4\u0bc1...',
      'Reset' => '\u0bb0\u0bc0\u0b9a\u0bc6\u0b9f\u0bcd',
      'Apply' => '\u0b85\u0baa\u0bcd\u0bb3\u0bc8',
      'Applying...' =>
        '\u0b85\u0baa\u0bcd\u0bb3\u0bc8 \u0b86\u0b95\u0bbf\u0bb1\u0ba4\u0bc1...',
      'Erase' => '\u0b85\u0bb4\u0bbf',
      'Restore' => '\u0bae\u0bc0\u0b9f\u0bcd\u0b9f\u0bae\u0bc8',
      'Brightness' => '\u0baa\u0bbf\u0bb0\u0bc8\u0b9f\u0bcd\u0ba8\u0bb8\u0bcd',
      'Contrast' =>
        '\u0b95\u0bbe\u0ba9\u0bcd\u0b9f\u0bcd\u0bb0\u0bbe\u0bb8\u0bcd\u0b9f\u0bcd',
      'Saturation' => '\u0b9a\u0bbe\u0b9a\u0bc1\u0bb0\u0bc7\u0bb7\u0ba9\u0bcd',
      'Share' => '\u0baa\u0b95\u0bbf\u0bb0\u0bcd',
      'Select a photo first' =>
        '\u0bae\u0bc1\u0ba4\u0bb2\u0bbf\u0bb2\u0bcd \u0b92\u0bb0\u0bc1 \u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0ba4\u0bcd\u0ba4\u0bc8\u0ba4\u0bcd \u0ba4\u0bc7\u0bb0\u0bcd\u0ba8\u0bcd\u0ba4\u0bc6\u0b9f\u0bc1\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
      'Canvas is empty' =>
        '\u0b95\u0bc7\u0ba9\u0bcd\u0bb5\u0bbe\u0bb8\u0bcd \u0b95\u0bbe\u0bb2\u0bbf\u0baf\u0bbe\u0b95 \u0b89\u0bb3\u0bcd\u0bb3\u0ba4\u0bc1',
      'Cancel' => '\u0bb0\u0ba4\u0bcd\u0ba4\u0bc1',
      'Yes, export' =>
        '\u0b86\u0bae\u0bcd, \u0b8f\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0ba4\u0bbf \u0b9a\u0bc6\u0baf\u0bcd',
      _ => null,
    };
  }

  String? _commonKannadaFallback(String english) {
    final landing = _landingKannadaFallbacks[english];
    if (landing != null) {
      return landing;
    }
    return switch (english) {
      'Add Photo' =>
        '\u0cab\u0ccb\u0c9f\u0ccb \u0cb8\u0cc7\u0cb0\u0cbf\u0cb8\u0cbf',
      'Text' => '\u0caa\u0ca0\u0ccd\u0caf',
      'Stickers' => '\u0cb8\u0ccd\u0c9f\u0cbf\u0c95\u0cb0\u0ccd\u0cb8\u0ccd',
      'Background' => '\u0cb9\u0cbf\u0ca8\u0ccd\u0ca8\u0cc6\u0cb2\u0cc6',
      'Layers' => '\u0cb2\u0cc7\u0caf\u0cb0\u0ccd\u0cb8\u0ccd',
      'Adjust' => '\u0c85\u0ca1\u0ccd\u0c9c\u0cb8\u0ccd\u0c9f\u0ccd',
      'Crop' => '\u0c95\u0ccd\u0cb0\u0cbe\u0caa\u0ccd',
      'Eraser' => '\u0c87\u0cb0\u0cc6\u0cd5\u0cb8\u0cb0\u0ccd',
      'Remove BG' =>
        '\u0cb9\u0cbf\u0ca8\u0ccd\u0ca8\u0cc6\u0cb2\u0cc6 \u0ca4\u0cc6\u0c97\u0cc6\u0caf\u0cbf\u0cb0\u0cbf',
      'Edit' => '\u0c8e\u0ca1\u0cbf\u0c9f\u0ccd',
      'Fonts' => '\u0cab\u0cbe\u0c82\u0c9f\u0ccd\u0cb8\u0ccd',
      'Options' => '\u0c86\u0caf\u0ccd\u0c95\u0cc6\u0c97\u0cb3\u0cc1',
      'Style' => '\u0cb8\u0ccd\u0c9f\u0cc8\u0cb2\u0ccd',
      'Effects' => '\u0c87\u0cab\u0cc6\u0c95\u0ccd\u0c9f\u0ccd\u0cb8\u0ccd',
      'Size' => '\u0c97\u0cbe\u0ca4\u0ccd\u0cb0',
      'Line' => '\u0cb2\u0cc8\u0ca8\u0ccd',
      'Letter' => '\u0c85\u0c95\u0ccd\u0cb7\u0cb0',
      'Opacity' => '\u0c92\u0caa\u0cbe\u0cb8\u0cbf\u0c9f\u0cbf',
      'Curve' => '\u0c95\u0cb0\u0ccd\u0cb5\u0ccd',
      'Stroke' => '\u0cb8\u0ccd\u0c9f\u0ccd\u0cb0\u0ccb\u0c95\u0ccd',
      'Shadow' => '\u0ca8\u0cc6\u0cb0\u0cb3\u0cc1',
      'Blur' => '\u0cac\u0ccd\u0cb2\u0cb0\u0ccd',
      'Offset' => '\u0c86\u0cab\u0ccd\u200c\u0cb8\u0cc6\u0c9f\u0ccd',
      'Back' => '\u0cb9\u0cbf\u0c82\u0ca6\u0cc6',
      'Undo' => '\u0c85\u0ca8\u0ccd\u0ca1\u0cc2',
      'Redo' => '\u0cb0\u0cc0\u0ca1\u0cc2',
      'Drafts' =>
        '\u0ca1\u0ccd\u0cb0\u0cbe\u0cab\u0ccd\u0c9f\u0ccd\u0cb8\u0ccd',
      'Export' =>
        '\u0c8e\u0c95\u0ccd\u0cb8\u0ccd\u200c\u0caa\u0ccb\u0cb0\u0ccd\u0c9f\u0ccd',
      'Saving...' =>
        '\u0cb8\u0cc7\u0cb5\u0ccd \u0c86\u0c97\u0cc1\u0ca4\u0ccd\u0ca4\u0cbf\u0ca6\u0cc6...',
      'Reset' => '\u0cb0\u0cc0\u0cb8\u0cc6\u0c9f\u0ccd',
      'Apply' => '\u0c85\u0caa\u0ccd\u0cb2\u0cc8',
      'Applying...' =>
        '\u0c85\u0caa\u0ccd\u0cb2\u0cc8 \u0c86\u0c97\u0cc1\u0ca4\u0ccd\u0ca4\u0cbf\u0ca6\u0cc6...',
      'Erase' => '\u0c85\u0cb3\u0cbf\u0cb8\u0cbf',
      'Restore' =>
        '\u0cae\u0cb0\u0cc1\u0cb8\u0ccd\u0ca5\u0cbe\u0caa\u0ca8\u0cc6',
      'Brightness' =>
        '\u0cac\u0ccd\u0cb0\u0cc8\u0c9f\u0ccd\u200c\u0ca8\u0cc6\u0cb8\u0ccd',
      'Contrast' =>
        '\u0c95\u0cbe\u0ca8\u0ccd\u0c9f\u0ccd\u0cb0\u0cbe\u0cb8\u0ccd\u0c9f\u0ccd',
      'Saturation' =>
        '\u0cb8\u0ccd\u0caf\u0cbe\u0c9a\u0cc1\u0cb0\u0cc7\u0cb6\u0ca8\u0ccd',
      'Share' => '\u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cc6',
      'Select a photo first' =>
        '\u0cae\u0cca\u0ca6\u0cb2\u0cc1 \u0c92\u0c82\u0ca6\u0cc1 \u0cab\u0ccb\u0c9f\u0ccb \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0cbe\u0ca1\u0cbf',
      'Canvas is empty' =>
        '\u0c95\u0ccd\u0caf\u0cbe\u0ca8\u0ccd\u0cb5\u0cbe\u0cb8\u0ccd \u0c96\u0cbe\u0cb2\u0cbf\u0caf\u0cbe\u0c97\u0cbf\u0ca6\u0cc6',
      'Cancel' => '\u0cb0\u0ca6\u0ccd\u0ca6\u0cc1',
      'Yes, export' =>
        '\u0cb9\u0ccc\u0ca6\u0cc1, \u0c8e\u0c95\u0ccd\u0cb8\u0ccd\u200c\u0caa\u0ccb\u0cb0\u0ccd\u0c9f\u0ccd \u0cae\u0cbe\u0ca1\u0cbf',
      _ => null,
    };
  }

  String? _commonMalayalamFallback(String english) {
    final landing = _landingMalayalamFallbacks[english];
    if (landing != null) {
      return landing;
    }
    return switch (english) {
      'Add Photo' =>
        '\u0d2b\u0d4b\u0d1f\u0d4d\u0d1f\u0d4b \u0d1a\u0d47\u0d7c\u0d15\u0d4d\u0d15\u0d41\u0d15',
      'Text' => '\u0d1f\u0d46\u0d15\u0d4d\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d4d',
      'Stickers' =>
        '\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d3f\u0d15\u0d4d\u0d15\u0d31\u0d41\u0d15\u0d7e',
      'Background' =>
        '\u0d2c\u0d3e\u0d15\u0d4d\u0d15\u0d4d\u0d17\u0d4d\u0d30\u0d57\u0d23\u0d4d\u0d1f\u0d4d',
      'Layers' => '\u0d32\u0d46\u0d2f\u0d47\u0d34\u0d4d\u0d38\u0d4d',
      'Adjust' =>
        '\u0d05\u0d21\u0d4d\u0d1c\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d4d',
      'Crop' => '\u0d15\u0d4d\u0d30\u0d4b\u0d2a\u0d4d\u0d2a\u0d4d',
      'Eraser' => '\u0d07\u0d31\u0d47\u0d38\u0d7c',
      'Remove BG' =>
        '\u0d2c\u0d3e\u0d15\u0d4d\u0d15\u0d4d\u0d17\u0d4d\u0d30\u0d57\u0d23\u0d4d\u0d1f\u0d4d \u0d28\u0d40\u0d15\u0d4d\u0d15\u0d41\u0d15',
      'Edit' => '\u0d0e\u0d21\u0d3f\u0d31\u0d4d\u0d31\u0d4d',
      'Fonts' => '\u0d2b\u0d4b\u0d23\u0d4d\u0d1f\u0d41\u0d15\u0d7e',
      'Options' => '\u0d13\u0d2a\u0d4d\u0d37\u0d28\u0d41\u0d15\u0d7e',
      'Style' => '\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d48\u0d7d',
      'Effects' =>
        '\u0d07\u0d2b\u0d15\u0d4d\u0d31\u0d4d\u0d31\u0d4d\u0d38\u0d4d',
      'Size' => '\u0d35\u0d32\u0d3f\u0d2a\u0d4d\u0d2a\u0d02',
      'Line' => '\u0d32\u0d48\u0d7b',
      'Letter' => '\u0d05\u0d15\u0d4d\u0d37\u0d30\u0d02',
      'Opacity' => '\u0d12\u0d2a\u0d3e\u0d38\u0d3f\u0d31\u0d4d\u0d31\u0d3f',
      'Curve' => '\u0d15\u0d7c\u0d35\u0d4d',
      'Stroke' =>
        '\u0d38\u0d4d\u0d1f\u0d4d\u0d30\u0d4b\u0d15\u0d4d\u0d15\u0d4d',
      'Shadow' => '\u0d28\u0d3f\u0d34\u0d7d',
      'Blur' => '\u0d2c\u0d4d\u0d32\u0d7c',
      'Offset' =>
        '\u0d13\u0d2b\u0d4d\u200c\u0d38\u0d46\u0d31\u0d4d\u0d31\u0d4d',
      'Back' =>
        '\u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d3f\u0d32\u0d47\u0d15\u0d4d\u0d15\u0d4d',
      'Undo' => '\u0d05\u0d7a\u0d21\u0d42',
      'Redo' => '\u0d31\u0d40\u0d21\u0d42',
      'Drafts' =>
        '\u0d21\u0d4d\u0d30\u0d3e\u0d2b\u0d4d\u0d31\u0d4d\u0d31\u0d41\u0d15\u0d7e',
      'Export' =>
        '\u0d0e\u0d15\u0d4d\u0d38\u0d4d\u0d2a\u0d4b\u0d7c\u0d1f\u0d4d\u0d1f\u0d4d',
      'Saving...' =>
        '\u0d38\u0d47\u0d35\u0d4d \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d41\u0d28\u0d4d\u0d28\u0d41...',
      'Reset' => '\u0d31\u0d40\u0d38\u0d46\u0d31\u0d4d\u0d31\u0d4d',
      'Apply' => '\u0d05\u0d2a\u0d4d\u0d32\u0d48',
      'Applying...' =>
        '\u0d05\u0d2a\u0d4d\u0d32\u0d48 \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d41\u0d28\u0d4d\u0d28\u0d41...',
      'Erase' => '\u0d2e\u0d3e\u0d2f\u0d4d\u0d15\u0d4d\u0d15\u0d41\u0d15',
      'Restore' =>
        '\u0d2a\u0d41\u0d28\u0d03\u0d38\u0d4d\u0d25\u0d3e\u0d2a\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d15',
      'Brightness' =>
        '\u0d2c\u0d4d\u0d30\u0d48\u0d31\u0d4d\u0d31\u0d4d\u200c\u0d28\u0d38\u0d4d',
      'Contrast' =>
        '\u0d15\u0d4b\u0d7a\u0d1f\u0d4d\u0d30\u0d3e\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d4d',
      'Saturation' => '\u0d38\u0d3e\u0d1a\u0d41\u0d31\u0d47\u0d37\u0d7b',
      'Share' => '\u0d37\u0d46\u0d2f\u0d7c',
      'Select a photo first' =>
        '\u0d06\u0d26\u0d4d\u0d2f\u0d02 \u0d12\u0d30\u0d41 \u0d2b\u0d4b\u0d1f\u0d4d\u0d1f\u0d4b \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d41\u0d15',
      'Canvas is empty' =>
        '\u0d15\u0d3e\u0d7b\u0d35\u0d3e\u0d38\u0d4d \u0d15\u0d3e\u0d32\u0d3f\u0d2f\u0d3e\u0d23\u0d41',
      'Cancel' =>
        '\u0d31\u0d26\u0d4d\u0d26\u0d3e\u0d15\u0d4d\u0d15\u0d41\u0d15',
      'Yes, export' =>
        '\u0d05\u0d24\u0d46, \u0d0e\u0d15\u0d4d\u0d38\u0d4d\u0d2a\u0d4b\u0d7c\u0d1f\u0d4d\u0d1f\u0d4d \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d41\u0d15',
      _ => null,
    };
  }

  String get splashTagline => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      '\u0c0e\u0c02\u0c1a\u0c41\u0c15\u0c4b\u0c02\u0c21\u0c3f, \u0c2e\u0c40 \u0c2a\u0c47\u0c30\u0c41\u0c24\u0c4b \u0c37\u0c47\u0c30\u0c4d \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f',
    SupportedUiLanguage.hindi =>
      '\u091a\u0941\u0928\u0947\u0902, \u0905\u092a\u0928\u0947 \u0928\u093e\u092e \u0915\u0947 \u0938\u093e\u0925 \u0936\u0947\u092f\u0930 \u0915\u0930\u0947\u0902',
    SupportedUiLanguage.english => 'Choose and share with your name',
    SupportedUiLanguage.tamil =>
      '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0baa\u0bc6\u0baf\u0bb0\u0bcd \u0b89\u0b9f\u0ba9\u0bcd \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bc1 \u0baa\u0b95\u0bbf\u0bb0\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    SupportedUiLanguage.kannada =>
      '\u0ca8\u0cbf\u0cae\u0ccd\u0cae \u0cb9\u0cc6\u0cb8\u0cb0\u0cbf\u0ca8 \u0c9c\u0cca\u0ca4\u0cc6 \u0c86\u0caf\u0ccd\u0c95\u0cc6 \u0cae\u0abe\u0ca1\u0cbf \u0cb9\u0c82\u0c9a\u0cbf',
    SupportedUiLanguage.malayalam =>
      '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 \u0d2a\u0d47\u0d30\u0d3f\u0d28\u0d4a\u0d2a\u0dcd\u0d2a\u0d02 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d24\u0d4d \u0d36\u0d47\u0d2f\u0d7c \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d42',
  };

  String get languageScreenTitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      '\u0c2e\u0c40 \u0c2d\u0c3e\u0c37\u0c28\u0c41 \u0c0e\u0c02\u0c1a\u0c41\u0c15\u0c4b\u0c02\u0c21\u0c3f',
    SupportedUiLanguage.hindi =>
      '\u0905\u092a\u0928\u0940 \u092d\u093e\u0937\u093e \u091a\u0941\u0928\u0947\u0902',
    SupportedUiLanguage.english => 'Choose your language',
    SupportedUiLanguage.tamil =>
      '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0bae\u0bca\u0bb4\u0bbf\u0baf\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    SupportedUiLanguage.kannada =>
      '\u0ca8\u0cbf\u0cae\u0ccd\u0cae \u0cad\u0bbe\u0cb7\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0abe\u0ca1\u0cbf',
    SupportedUiLanguage.malayalam =>
      '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 \u0d2d\u0d3e\u0d37 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d42',
  };

  String get languageScreenSubtitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      '\u0c2f\u0c3e\u0c2a\u0c4d\u200c\u0c32\u0c4b \u0c2e\u0c40\u0c15\u0c41 \u0c15\u0c3e\u0c35\u0c3e\u0c32\u0c4d\u0c38\u0c3f\u0c28 \u0c2d\u0c3e\u0c37\u0c28\u0c41 \u0c0e\u0c02\u0c1a\u0c41\u0c15\u0c4b\u0c02\u0c21\u0c3f. \u0c24\u0c30\u0c4d\u0c35\u0c3e\u0c24 \u0c15\u0c42\u0c21\u0c3e \u0c2e\u0c3e\u0c30\u0c4d\u0c1a\u0c41\u0c15\u0c4b\u0c35\u0c1a\u0c4d\u0c1a\u0c41.',
    SupportedUiLanguage.hindi =>
      '\u0910\u092a \u092e\u0947\u0902 \u0905\u092a\u0928\u0940 \u092a\u0938\u0902\u0926 \u0915\u0940 \u092d\u093e\u0937\u093e \u091a\u0941\u0928\u0947\u0902\u0964 \u092c\u093e\u0926 \u092e\u0947\u0902 \u092d\u0940 \u092c\u0926\u0932 \u0938\u0915\u0924\u0947 \u0939\u0948\u0902\u0964',
    SupportedUiLanguage.english =>
      'Choose the language you want in the app. You can change it later too.',
    SupportedUiLanguage.tamil =>
      '\u0b86\u0baa\u0bcd\u0baa\u0bbf\u0bb2\u0bcd \u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0bb5\u0bc7\u0ba3\u0bcd\u0b9f\u0bbf\u0baf \u0bae\u0bca\u0bb4\u0bbf\u0baf\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd. \u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0bb0\u0bcd \u0bae\u0bbe\u0bb1\u0bcd\u0bb1\u0bb5\u0bc1\u0bae\u0bcd \u0bae\u0bc1\u0b9f\u0bbf\u0baf\u0bc1\u0bae\u0bcd.',
    SupportedUiLanguage.kannada =>
      '\u0c86\u0ccd\u0caf\u0ccd\u0caa\u0ccd\u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0ca8\u0cbf\u0cae\u0c97\u0cc6 \u0cac\u0cc7\u0c95\u0cbe\u0ca6 \u0cad\u0bbe\u0cb7\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0abe\u0ca1\u0cbf. \u0ca8\u0c82\u0ca4\u0cb0 \u0cb8\u0cb9 \u0cac\u0ca6\u0cb2\u0cbe\u0caf\u0cbf\u0cb8\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
    SupportedUiLanguage.malayalam =>
      '\u0d06\u0d2a\u0d4d\u0d2a\u0d3f\u0d32\u0d4d \u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d4d\u0d15\u0d4d\u0d15\u0d4d \u0d35\u0d47\u0d23\u0d4d\u0d1f \u0d2d\u0d3e\u0d37 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d42. \u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d40\u0d1f\u0d4d \u0d2e\u0d3e\u0d31\u0d4d\u0d31\u0d3e\u0d28\u0d41\u0d02 \u0d15\u0d34\u0d3f\u0d2f\u0d41\u0d02.',
  };

  String get continueLabel =>
      _regionalFallback('Continue') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c15\u0c4a\u0c28\u0c38\u0c3e\u0c17\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u091c\u093e\u0930\u0940 \u0930\u0916\u0947\u0902',
        SupportedUiLanguage.english => 'Continue',
        SupportedUiLanguage.tamil =>
          '\u0ba4\u0bca\u0b9f\u0bb0\u0bb5\u0bc1\u0bae\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0bae\u0cc1\u0c82\u0ca6\u0cc1\u0cb5\u0cb0\u0cbf\u0cb8\u0cbf',
        SupportedUiLanguage.malayalam => '\u0d24\u0d41\u0d1f\u0d30\u0d41\u0d15',
      };

  String get homeEmptyPostersTitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'ఈ విభాగంలో పోస్టర్లు అందుబాటులో లేవు',
    SupportedUiLanguage.hindi => 'इस सेक्शन में पोस्टर उपलब्ध नहीं हैं',
    SupportedUiLanguage.english => 'No posters are available in this section',
    SupportedUiLanguage.tamil => 'இந்த பகுதியில் போஸ்டர்கள் இல்லை',
    SupportedUiLanguage.kannada => 'ಈ ವಿಭಾಗದಲ್ಲಿ ಪೋಸ್ಟರ್‌ಗಳು ಲಭ್ಯವಿಲ್ಲ',
    SupportedUiLanguage.malayalam => 'ഈ വിഭാഗത്തിൽ പോസ്റ്ററുകൾ ലഭ്യമല്ല',
  };

  String get homeEmptyPostersSubtitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      'ఈ కేటగిరీలో ప్రస్తుతం పోస్టర్లు లేవు. రిఫ్రెష్ చేసి మళ్లీ చూడండి.',
    SupportedUiLanguage.hindi =>
      'इस कैटेगरी में अभी पोस्टर नहीं हैं। रिफ्रेश करके फिर देखें।',
    SupportedUiLanguage.english =>
      'There are no posters for this category right now. Pull down to refresh and check again.',
    SupportedUiLanguage.tamil =>
      'இந்த வகையில் தற்போது போஸ்டர்கள் இல்லை. ரிப்ரெஷ் செய்து மீண்டும் பார்க்கவும்.',
    SupportedUiLanguage.kannada =>
      'ಈ ವರ್ಗದಲ್ಲಿ ಈಗ ಪೋಸ್ಟರ್‌ಗಳು ಇಲ್ಲ. ರಿಫ್ರೆಶ್ ಮಾಡಿ ಮತ್ತೆ ನೋಡಿ.',
    SupportedUiLanguage.malayalam =>
      'ഈ വിഭാഗത്തിൽ ഇപ്പോൾ പോസ്റ്ററുകൾ ഇല്ല. റിഫ്രെഷ് ചെയ്ത് വീണ്ടും നോക്കൂ.',
  };

  String get loginWelcome =>
      _regionalFallback('Welcome to Mana Poster Ai') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'Mana Poster Ai \u0c15\u0c3f \u0c38\u0c4d\u0c35\u0c3e\u0c17\u0c24\u0c02',
        SupportedUiLanguage.hindi =>
          'Mana Poster Ai \u092e\u0947\u0902 \u0906\u092a\u0915\u093e \u0938\u094d\u0935\u093e\u0917\u0924 \u0939\u0948',
        SupportedUiLanguage.english => 'Welcome to Mana Poster Ai',
        SupportedUiLanguage.tamil =>
          '\u0bae\u0ba9\u0bbe \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0b86\u0baa\u0bcd\u0baa\u0bc1\u00b95\u0bcd\u0b95\u0bc1 \u0bb5\u0bb0\u0bb5\u0bc7\u0bb1\u0bcd\u0baa\u0bc1',
        SupportedUiLanguage.kannada =>
          '\u0cae\u0ca8 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cc6 \u0cb8\u0ccd\u0cb5\u0cbe\u0c97\u0ca4',
        SupportedUiLanguage.malayalam =>
          '\u0d2e\u0d28 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d31\u0d3f\u0d32\u0d47\u0d15\u0d4d\u0d15\u0d4d \u0d38\u0d4d\u0d35\u0d3e\u0d17\u0d24\u0d02',
      };

  String get loginSubtitle =>
      _regionalFallback(
        'Login with Google or Email and start your poster journey.',
      ) ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'Google \u0c32\u0c47\u0c26\u0c3e Email \u0c24\u0c4b login \u0c05\u0c2f\u0c3f \u0c2e\u0c40 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c2a\u0c4d\u0c30\u0c2f\u0c3e\u0c23\u0c3e\u0c28\u0c4d\u0c28\u0c3f \u0c2a\u0c4d\u0c30\u0c3e\u0c30\u0c02\u0c2d\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f.',
        SupportedUiLanguage.hindi =>
          'Google \u092f\u093e Email \u0938\u0947 login \u0915\u0930\u0915\u0947 \u0905\u092a\u0928\u0940 poster journey \u0936\u0941\u0930\u0942 \u0915\u0930\u0947\u0902.',
        SupportedUiLanguage.english =>
          'Login with Google or Email and start your poster journey.',
        SupportedUiLanguage.tamil =>
          'Google \u0b85\u0bb2\u0bcd\u0bb2\u0ba4\u0bc1 Email \u0bae\u0bc2\u0bb2\u0bae\u0bcd login \u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bc1 \u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd poster \u0baa\u0baf\u0ba3\u0ba4\u0bcd\u0ba4\u0bc8 \u0ba4\u0bca\u0b9f\u0b99\u0bcd\u0b95\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd.',
        SupportedUiLanguage.kannada =>
          'Google \u0c85\u0ca5\u0cb5\u0cbe Email \u0cae\u0cc2\u0cb2\u0c95 login \u0c86\u0c97\u0cbf \u0ca8\u0cbf\u0cae\u0ccd\u0cae poster \u0caf\u0cbe\u0ca4\u0ccd\u0cb0\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0caa\u0ccd\u0cb0\u0cbe\u0cb0\u0c82\u0cad\u0cbf\u0cb8\u0cbf.',
        SupportedUiLanguage.malayalam =>
          'Google \u0d05\u0d32\u0d4d\u0d32\u0d46\u0d19\u0d4d\u0d15\u0d3f\u0d32\u0d4d Email \u0d35\u0d34\u0d3f login \u0d1a\u0d46\u0d2f\u0d4d\u0d24\u0d4d \u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 poster \u0d2f\u0d3e\u0d24\u0d4d\u0d30 \u0d24\u0d41\u0d1f\u0d19\u0d4d\u0d19\u0d42.',
      };

  String get loginLabel =>
      _regionalFallback('Login') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'Login',
        SupportedUiLanguage.hindi => 'Login',
        SupportedUiLanguage.english => 'Login',
        SupportedUiLanguage.tamil =>
          '\u0b89\u0bb3\u0bcd\u0ba8\u0bc1\u0bb4\u0bc8',
        SupportedUiLanguage.kannada => '\u0cb2\u0cbe\u0c97\u0cbf\u0ca8\u0ccd',
        SupportedUiLanguage.malayalam => '\u0d32\u0d4b\u0d17\u0d3f\u0d7b',
      };

  String get signUpLabel =>
      _regionalFallback('Sign Up') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'Sign Up',
        SupportedUiLanguage.hindi => 'Sign Up',
        SupportedUiLanguage.english => 'Sign Up',
        SupportedUiLanguage.tamil =>
          '\u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0cb8\u0cc8\u0ca8\u0ccd \u0c85\u0baa\u0ccd',
        SupportedUiLanguage.malayalam =>
          '\u0d38\u0d48\u0d7b \u0d05\u0d2a\u0d4d',
      };

  String get googleContinue =>
      _regionalFallback('Continue with Google') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'Google \u0c24\u0c4b \u0c15\u0c4a\u0c28\u0c38\u0c3e\u0c17\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          'Google \u0938\u0947 \u091c\u093e\u0930\u0940 \u0930\u0916\u0947\u0902',
        SupportedUiLanguage.english => 'Continue with Google',
        SupportedUiLanguage.tamil =>
          'Google \u0b89\u0b9f\u0ba9\u0bcd \u0ba4\u0bca\u0b9f\u0bb0\u0bb5\u0bc1\u0bae\u0bcd',
        SupportedUiLanguage.kannada =>
          'Google \u0c9c\u0cca\u0ca4\u0cc6 \u0bae\u0cc1\u0c82\u0ca6\u0cc1\u0cb5\u0cb0\u0cbf\u0cb8\u0cbf',
        SupportedUiLanguage.malayalam =>
          'Google \u0d09\u0d2e\u0d3e\u0d2f\u0d3f \u0d24\u0d41\u0d1f\u0d30\u0d41\u0d15',
      };

  String get emailAddress =>
      _regionalFallback('Email address') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'ఈమెయిల్ చిరునామా',
        SupportedUiLanguage.hindi => 'ईमेल पता',
        SupportedUiLanguage.english => 'Email address',
        SupportedUiLanguage.tamil => 'மின்னஞ்சல் முகவரி',
        SupportedUiLanguage.kannada => 'ಇಮೇಲ್ ವಿಳಾಸ',
        SupportedUiLanguage.malayalam => 'ഇമെയിൽ വിലാസം',
      };

  String get password =>
      _regionalFallback('Password') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'పాస్‌వర్డ్',
        SupportedUiLanguage.hindi => 'पासवर्ड',
        SupportedUiLanguage.english => 'Password',
        SupportedUiLanguage.tamil => 'கடவுச்சொல்',
        SupportedUiLanguage.kannada => 'ಪಾಸ್‌ವರ್ಡ್',
        SupportedUiLanguage.malayalam => 'പാസ്‌വേഡ്',
      };

  String get forgotPassword =>
      _regionalFallback('Forgot Password') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'పాస్‌వర్డ్ మర్చిపోయారా?',
        SupportedUiLanguage.hindi => 'पासवर्ड भूल गए?',
        SupportedUiLanguage.english => 'Forgot Password',
        SupportedUiLanguage.tamil => 'கடவுச்சொல் மறந்துவிட்டதா?',
        SupportedUiLanguage.kannada => 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರಾ?',
        SupportedUiLanguage.malayalam => 'പാസ്‌വേഡ് മറന്നോ?',
      };

  String get noAccount =>
      _regionalFallback("Don't have an account?") ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'ఖాతా లేదా?',
        SupportedUiLanguage.hindi => 'खाता नहीं है?',
        SupportedUiLanguage.english => "Don't have an account?",
        SupportedUiLanguage.tamil =>
          '\u0b95\u0ba3\u0b95\u0bcd\u0b95\u0bc1 \u0b87\u0bb2\u0bcd\u0bb2\u0bc8\u0baf\u0bbe?',
        SupportedUiLanguage.kannada =>
          '\u0c96\u0cbe\u0ca4\u0cc6 \u0c87\u0cb2\u0ccd\u0cb5\u0cc7?',
        SupportedUiLanguage.malayalam =>
          '\u0d05\u0d15\u0d4d\u0d15\u0d57\u0d23\u0d4d\u0d1f\u0d4d \u0d07\u0d32\u0d4d\u0d32\u0d47?',
      };

  String get alreadyHaveAccount =>
      _regionalFallback('Already have an account?') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'ఇప్పటికే ఖాతా ఉందా?',
        SupportedUiLanguage.hindi => 'क्या पहले से खाता है?',
        SupportedUiLanguage.english => 'Already have an account?',
        SupportedUiLanguage.tamil =>
          '\u0b8f\u0bb1\u0bcd\u0b95\u0ba9\u0bb5\u0bc7 \u0b92\u0bb0\u0bc1 \u0b95\u0ba3\u0b95\u0bcd\u0b95\u0bc1 \u0b89\u0bb3\u0bcd\u0bb3\u0ba4\u0bbe?',
        SupportedUiLanguage.kannada =>
          '\u0c88\u0c97\u0abe\u0cb2\u0cc7 \u0c92\u0c82\u0ca6\u0cc1 \u0c96\u0cbe\u0ca4\u0cc6 \u0c87\u0ca6\u0cc6\u0caf\u0cbe?',
        SupportedUiLanguage.malayalam =>
          '\u0d07\u0d24\u0d3f\u0d28\u0d95\u0d02 \u0d12\u0d30\u0d41 \u0d05\u0d15\u0d4d\u0d15\u0d57\u0d23\u0d4d\u0d1f\u0d4d \u0d09\u0d23\u0d4d\u0d1f\u0d4b?',
      };

  String get loginWithEmail =>
      _regionalFallback('Login with Email') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'ఈమెయిల్‌తో లాగిన్ అవ్వండి',
        SupportedUiLanguage.hindi => 'ईमेल से लॉग इन करें',
        SupportedUiLanguage.english => 'Login with Email',
        SupportedUiLanguage.tamil =>
          'Email \u0bae\u0bc2\u0bb2\u0bae\u0bcd \u0b89\u0bb3\u0bcd\u0ba8\u0bc1\u0bb4\u0bc8',
        SupportedUiLanguage.kannada =>
          'Email \u0cae\u0cc2\u0cb2\u0c95 \u0cb2\u0cbe\u0c97\u0cbf\u0ca8\u0ccd',
        SupportedUiLanguage.malayalam =>
          'Email \u0d35\u0d34\u0d3f \u0d32\u0d4b\u0d17\u0d3f\u0d7b',
      };

  String get signUpWithEmail =>
      _regionalFallback('Sign Up with Email') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'ఈమెయిల్‌తో నమోదు చేసుకోండి',
        SupportedUiLanguage.hindi => 'ईमेल से साइन अप करें',
        SupportedUiLanguage.english => 'Sign Up with Email',
        SupportedUiLanguage.tamil =>
          'Email \u0bae\u0bc2\u0bb2\u0bae\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd',
        SupportedUiLanguage.kannada =>
          'Email \u0cae\u0cc2\u0cb2\u0c95 \u0cb8\u0cc8\u0ca8\u0ccd \u0c85\u0baa\u0ccd',
        SupportedUiLanguage.malayalam =>
          'Email \u0d35\u0d34\u0d3f \u0d38\u0d48\u0d7b \u0d05\u0d2a\u0d4d',
      };

  String get validEmailError =>
      _regionalFallback('Enter valid email') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c30\u0c48\u0c28 email \u0c07\u0c35\u0c4d\u0c35\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u0938\u0939\u0940 email \u0926\u0930\u094d\u091c \u0915\u0930\u0947\u0902',
        SupportedUiLanguage.english => 'Enter valid email',
        SupportedUiLanguage.tamil =>
          '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 email \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0cb8\u0cb0\u0cbf\u0caf\u0cbe\u0ca6 email \u0ca8\u0cae\u0cc2\u0ca6\u0cbf\u0cb8\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d36\u0d30\u0d3f\u0d2f\u0d3e\u0d2f email \u0d28\u0d7d\u0d15\u0d42',
      };

  String get passwordError =>
      _regionalFallback('Minimum 6 characters required') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c15\u0c28\u0c40\u0c38\u0c02 6 \u0c05\u0c15\u0c4d\u0c37\u0c30\u0c3e\u0c32\u0c41 \u0c05\u0c35\u0c38\u0c30\u0c02',
        SupportedUiLanguage.hindi =>
          '\u0915\u092e \u0938\u0947 \u0915\u092e 6 \u0905\u0915\u094d\u0937\u0930 \u091a\u093e\u0939\u093f\u090f',
        SupportedUiLanguage.english => 'Minimum 6 characters required',
        SupportedUiLanguage.tamil =>
          '\u0b95\u0bc1\u0bb1\u0bc8\u0ba8\u0bcd\u0ba4\u0ba4\u0bc1 6 \u0b8e\u0bb4\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0b95\u0bb3\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8',
        SupportedUiLanguage.kannada =>
          '\u0c95\u0ca8\u0cbf\u0cb7\u0ccd\u0ca0 6 \u0c85\u0c95\u0ccd\u0cb7\u0cb0\u0c97\u0cb3\u0cc1 \u0cac\u0cc7\u0c95\u0cc1',
        SupportedUiLanguage.malayalam =>
          '\u0d15\u0d41\u0d31\u0d1e\u0d4d\u0d1e\u0d24\u0d4d 6 \u0d05\u0d15\u0d4d\u0d37\u0d30\u0d19\u0d4d\u0d19\u0d33\u0d4d \u0d06\u0d35\u0d36\u0d4d\u0d2f\u0d2e\u0d3e\u0d23\u0d4d',
      };

  String get forgotPasswordPlaceholder =>
      _regionalFallback('Password reset will be available soon.') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'పాస్‌వర్డ్ రీసెట్ సదుపాయం త్వరలో అందుబాటులోకి వస్తుంది.',
        SupportedUiLanguage.hindi => 'पासवर्ड रीसेट सुविधा जल्द उपलब्ध होगी।',
        SupportedUiLanguage.english => 'Password reset will be available soon.',
        SupportedUiLanguage.tamil =>
          'கடவுச்சொல் மீட்டமைப்பு வசதி விரைவில் கிடைக்கும்.',
        SupportedUiLanguage.kannada =>
          'ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಸೌಲಭ್ಯ ಶೀಘ್ರದಲ್ಲೇ ಬರುತ್ತದೆ.',
        SupportedUiLanguage.malayalam =>
          'പാസ്‌വേഡ് റീസെറ്റ് സൗകര്യം ഉടൻ ലഭ്യമാകും.',
      };

  String get permissionsTitle =>
      _regionalFallback('A few permissions are needed') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c15\u0c4a\u0c28\u0c4d\u0c28\u0c3f \u0c05\u0c28\u0c41\u0c2e\u0c24\u0c41\u0c32\u0c41 \u0c05\u0c35\u0c38\u0c30\u0c02',
        SupportedUiLanguage.hindi => 'कुछ अनुमतियां जरूरी हैं',
        SupportedUiLanguage.english => 'A few permissions are needed',
        SupportedUiLanguage.tamil => 'சில அனுமதிகள் தேவை',
        SupportedUiLanguage.kannada => 'ಕೆಲವು ಅನುಮತಿಗಳು ಬೇಕಾಗಿವೆ',
        SupportedUiLanguage.malayalam => 'ചില അനുമതികൾ ആവശ്യമാണ്',
      };

  String get permissionsSubtitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      '\u0c2b\u0c4b\u0c1f\u0c4b\u0c32\u0c41 \u0c0e\u0c02\u0c1a\u0c41\u0c15\u0c4b\u0c35\u0c21\u0c3e\u0c28\u0c3f\u0c15\u0c3f, \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d\u0c32\u0c41 \u0c38\u0c47\u0c35\u0c4d \u0c1a\u0c47\u0c2f\u0c21\u0c3e\u0c28\u0c3f\u0c15\u0c3f, \u0c2e\u0c41\u0c16\u0c4d\u0c2f\u0c2e\u0c48\u0c28 \u0c05\u0c2a\u0c4d\u200c\u0c21\u0c47\u0c1f\u0c4d\u0c38\u0c4d \u0c24\u0c46\u0c32\u0c41\u0c38\u0c41\u0c15\u0c4b\u0c35\u0c21\u0c3e\u0c28\u0c3f\u0c15\u0c3f permissions \u0c05\u0c35\u0c38\u0c30\u0c02.',
    SupportedUiLanguage.hindi =>
      '\u092b\u094b\u091f\u094b \u091a\u0941\u0928\u0928\u0947, \u092a\u094b\u0938\u094d\u091f\u0930 \u0938\u0947\u0935 \u0915\u0930\u0928\u0947 \u0914\u0930 \u092e\u0939\u0924\u094d\u0935\u092a\u0942\u0930\u094d\u0923 \u0905\u092a\u0921\u0947\u091f \u092a\u093e\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f permissions \u091a\u093e\u0939\u093f\u090f.',
    SupportedUiLanguage.english =>
      'Permissions are needed to choose photos, save posters, and receive important updates.',
    SupportedUiLanguage.tamil =>
      '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf, posters-\u0b90 save \u0b9a\u0bc6\u0baf\u0bcd\u0baf, \u0bae\u0bc1\u0b95\u0bcd\u0b95\u0bbf\u0baf\u0bae\u0bbe\u0ba9 updates-\u0b90 \u0baa\u0bc6\u0bb1 permissions \u0ba4\u0bc7\u0bb5\u0bc8.',
    SupportedUiLanguage.kannada =>
      '\u0cab\u0ccb\u0c9f\u0ccb\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6 \u0cae\u0cbe\u0ca1\u0cb2\u0cc1, posters save \u0cae\u0cbe\u0ca1\u0cb2\u0cc1 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cae\u0cc1\u0c96\u0ccd\u0caf updates \u0caa\u0ca1\u0cc6\u0caf\u0cb2\u0cc1 permissions \u0cac\u0cc7\u0c95\u0cbe\u0c97\u0cbf\u0cb5\u0cc6.',
    SupportedUiLanguage.malayalam =>
      '\u0d2b\u0d4b\u0d1f\u0d4b\u0d15\u0d33\u0d4d \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d3e\u0d28\u0d41\u0d02 posters save \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d3e\u0d28\u0d41\u0d02 \u0d2a\u0d4d\u0d30\u0d27\u0d3e\u0d28 updates \u0d32\u0d2d\u0d3f\u0d15\u0d4d\u0d15\u0d3e\u0d28\u0d41\u0d02 permissions \u0d06\u0d35\u0d36\u0d4d\u0d2f\u0d2e\u0d3e\u0d23\u0d4d.',
  };

  String get photosGallery =>
      _regionalFallback('Photos/Gallery') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'ఫోటోలు / గ్యాలరీ',
        SupportedUiLanguage.hindi => 'फोटो / गैलरी',
        SupportedUiLanguage.english => 'Photos/Gallery',
        SupportedUiLanguage.tamil => 'புகைப்படங்கள் / கேலரி',
        SupportedUiLanguage.kannada => 'ಫೋಟోలు / ಗ್ಯಾಲರಿ',
        SupportedUiLanguage.malayalam => 'ഫോട്ടോകൾ / ഗാലറി',
      };

  String get notifications =>
      _regionalFallback('Notifications') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'నోటిఫికేషన్లు',
        SupportedUiLanguage.hindi => 'सूचनाएं',
        SupportedUiLanguage.english => 'Notifications',
        SupportedUiLanguage.tamil =>
          '\u0b85\u0bb1\u0bbf\u0bb5\u0bbf\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0c85\u0ca7\u0cbf\u0cb8\u0cc2\u0c9a\u0ca8\u0cc6\u0c97\u0cb3\u0cc1',
        SupportedUiLanguage.malayalam =>
          '\u0d05\u0d31\u0d3f\u0d2f\u0d3f\u0d2a\u0d4d\u0d2a\u0d41\u0d15\u0d33\u0d4d',
      };

  String get enableLaterHint => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      'ఈ అనుమతులను తరువాత సెట్టింగ్స్‌లో కూడా ఆన్ చేయవచ్చు.',
    SupportedUiLanguage.hindi =>
      'इन अनुमतियों को बाद में सेटिंग्स में भी चालू कर सकते हैं।',
    SupportedUiLanguage.english =>
      'You can enable permissions later from Settings as well.',
    SupportedUiLanguage.tamil =>
      'இந்த அனுமதிகளை பிறகு அமைப்புகளில் இருந்து இயக்கலாம்.',
    SupportedUiLanguage.kannada =>
      'ಈ ಅನುಮತಿಗಳನ್ನು ನಂತರ ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಿಂದಲೂ ಆನ್ ಮಾಡಬಹುದು.',
    SupportedUiLanguage.malayalam =>
      'ഈ അനുമതികൾ പിന്നീട് സെറ്റിംഗ്സിൽ നിന്നും ഓൺ ചെയ്യാം.',
  };

  String get allowLabel =>
      _regionalFallback('Allow') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c05\u0c28\u0c41\u0c2e\u0c24\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u0905\u0928\u0941\u092e\u0924\u093f \u0926\u0947\u0902',
        SupportedUiLanguage.english => 'Allow',
        SupportedUiLanguage.tamil => '\u0b85\u0ba9\u0bc1\u0bae\u0ba4\u0bbf',
        SupportedUiLanguage.kannada =>
          '\u0c85\u0ca8\u0cc1\u0cae\u0ca4\u0cbf\u0cb8\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d05\u0d28\u0d41\u0d35\u0d26\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d15',
      };

  String get laterLabel =>
      _regionalFallback('Later') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c24\u0c30\u0c4d\u0c35\u0c3e\u0c24 \u0c1a\u0c42\u0c26\u0c4d\u0c26\u0c3e\u0c02',
        SupportedUiLanguage.hindi =>
          '\u092c\u093e\u0926 \u092e\u0947\u0902 \u0926\u0947\u0916\u0947\u0902\u0917\u0947',
        SupportedUiLanguage.english => 'Later',
        SupportedUiLanguage.tamil =>
          '\u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0bb0\u0bcd',
        SupportedUiLanguage.kannada => '\u0ca8\u0c82\u0ca4\u0cb0',
        SupportedUiLanguage.malayalam =>
          '\u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d40\u0d1f\u0d4d',
      };

  String get homeTagline =>
      _regionalFallback('Create & Share') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c43\u0c37\u0c4d\u0c1f\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f & \u0c2a\u0c02\u0c1a\u0c41\u0c15\u0c4b\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u092c\u0928\u093e\u090f\u0902 \u0914\u0930 \u0938\u093e\u091d\u093e \u0915\u0930\u0947\u0902',
        SupportedUiLanguage.english => 'Create & Share',
        SupportedUiLanguage.tamil =>
          '\u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0bbf \u0baa\u0b95\u0bbf\u0bb0\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0cb0\u0c9a\u0cbf\u0cb8\u0cbf \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cca\u0cb3\u0ccd\u0cb3\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d1a\u0d4d\u0d1a\u0d4d \u0d2a\u0d19\u0d4d\u0d15\u0d3f\u0d1f\u0d41\u0d15',
      };

  String get createLabel =>
      _regionalFallback('Create') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c43\u0c37\u0c4d\u0c1f\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi => '\u092c\u0928\u093e\u090f\u0902',
        SupportedUiLanguage.english => 'Create',
        SupportedUiLanguage.tamil =>
          '\u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0bc1',
        SupportedUiLanguage.kannada => '\u0cb0\u0c9a\u0cbf\u0cb8\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d15',
      };

  String get searchTemplates =>
      _regionalFallback('Search templates') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c1f\u0c46\u0c02\u0c2a\u0c4d\u0c32\u0c47\u0c1f\u0c4d\u0c32\u0c41 \u0c35\u0c46\u0c24\u0c15\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u091f\u0947\u092e\u094d\u092a\u0932\u0947\u091f \u0916\u094b\u091c\u0947\u0902',
        SupportedUiLanguage.english => 'Search templates',
        SupportedUiLanguage.tamil =>
          '\u0b9f\u0bc6\u0bae\u0bcd\u0baa\u0bcd\u0bb3\u0bc7\u0b9f\u0bcd\u0b95\u0bb3\u0bc8 \u0ba4\u0bc7\u0b9f\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0c9f\u0cc6\u0c82\u0caa\u0ccd\u0cb2\u0cc7\u0c9f\u0ccd \u0cb9\u0cc1\u0ca1\u0cc1\u0c95\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d1f\u0d46\u0d02\u0d2a\u0d4d\u0d32\u0d47\u0d31\u0d4d\u0d31\u0d41\u0d15\u0d7e \u0d24\u0d3f\u0d30\u0d2f\u0d41\u0d15',
      };

  String get bannerTitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu =>
      '\u0c2e\u0c28\u0c3e \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c2b\u0c40\u0c1a\u0c30\u0c4d\u0c21\u0c4d \u0c2c\u0c4d\u0c2f\u0c3e\u0c28\u0c30\u0c4d',
    SupportedUiLanguage.hindi =>
      '\u092e\u0928\u093e \u092a\u094b\u0938\u094d\u091f\u0930 \u092b\u0940\u091a\u0930\u094d\u0921 \u092c\u0948\u0928\u0930',
    SupportedUiLanguage.english => 'Mana Poster Ai Featured Banner',
    SupportedUiLanguage.tamil =>
      'Mana Poster Ai \u0b9a\u0bbf\u0bb1\u0baa\u0bcd\u0baa\u0bc1 banner',
    SupportedUiLanguage.kannada =>
      'Mana Poster Ai \u0cb5\u0cbf\u0cb6\u0cc7\u0cb7 banner',
    SupportedUiLanguage.malayalam =>
      'Mana Poster Ai \u0d2a\u0d4d\u0d30\u0d24\u0d4d\u0d2f\u0d47\u0d15 banner',
  };

  String get freeTab =>
      _regionalFallback('Ready') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => '\u0c09\u0c1a\u0c3f\u0c24\u0c02',
        SupportedUiLanguage.hindi => '\u092e\u0941\u095e\u094d\u0924',
        SupportedUiLanguage.english => 'Ready',
        SupportedUiLanguage.tamil => '\u0b87\u0bb2\u0bb5\u0b9a\u0bae\u0bcd',
        SupportedUiLanguage.kannada => '\u0c89\u0c9a\u0cbf\u0ca4',
        SupportedUiLanguage.malayalam =>
          '\u0d38\u0d57\u0d1c\u0d28\u0d4d\u0d2f\u0d02',
      };

  String get premiumTab =>
      _regionalFallback('Special') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2a\u0c4d\u0c30\u0c24\u0c4d\u0c2f\u0c47\u0c15\u0c02',
        SupportedUiLanguage.hindi => '\u0935\u093f\u0936\u0947\u0937',
        SupportedUiLanguage.english => 'Special',
        SupportedUiLanguage.tamil =>
          '\u0b9a\u0bbf\u0bb1\u0baa\u0bcd\u0baa\u0bc1',
        SupportedUiLanguage.kannada => '\u0cb5\u0cbf\u0cb6\u0cc7\u0cb7',
        SupportedUiLanguage.malayalam =>
          '\u0d2a\u0d4d\u0d30\u0d24\u0d4d\u0d2f\u0d47\u0d15\u0d02',
      };

  String get buyLabel =>
      _regionalFallback('Buy') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => '\u0c15\u0c4a\u0c28\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi => '\u0916\u0930\u0940\u0926\u0947\u0902',
        SupportedUiLanguage.english => 'Buy',
        SupportedUiLanguage.tamil => '\u0bb5\u0bbe\u0b99\u0bcd\u0b95\u0bc1',
        SupportedUiLanguage.kannada =>
          '\u0c96\u0cb0\u0cc0\u0ca6\u0cbf\u0cb8\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d35\u0d3e\u0d19\u0d4d\u0d19\u0d41\u0d15',
      };

  String get shareWhatsApp =>
      _regionalFallback('Share WhatsApp') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => '\u0c37\u0c47\u0c30\u0c4d',
        SupportedUiLanguage.hindi => '\u0936\u0947\u092f\u0930',
        SupportedUiLanguage.english => 'Share WhatsApp',
        SupportedUiLanguage.tamil => '\u0baa\u0b95\u0bbf\u0bb0\u0bcd',
        SupportedUiLanguage.kannada => '\u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cc6',
        SupportedUiLanguage.malayalam => '\u0d37\u0d46\u0d2f\u0d7c',
      };

  String get downloadLabel =>
      _regionalFallback('Download') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c21\u0c4c\u0c28\u0c4d\u0c32\u0c4b\u0c21\u0c4d',
        SupportedUiLanguage.hindi =>
          '\u0921\u093e\u0909\u0928\u0932\u094b\u0921',
        SupportedUiLanguage.english => 'Download',
        SupportedUiLanguage.tamil =>
          '\u0baa\u0ba4\u0bbf\u0bb5\u0bbf\u0bb1\u0b95\u0bcd\u0b95\u0bc1',
        SupportedUiLanguage.kannada =>
          '\u0ca1\u0ccc\u0ca8\u0ccd\u200c\u0cb2\u0ccb\u0ca1\u0ccd',
        SupportedUiLanguage.malayalam =>
          '\u0d21\u0d57\u0d7a\u0d32\u0d4b\u0d21\u0d4d',
      };

  String get profileTitle =>
      _regionalFallback('Profile & Settings') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2a\u0c4d\u0c30\u0c4a\u0c2b\u0c48\u0c32\u0c4d & \u0c38\u0c46\u0c1f\u0c4d\u0c1f\u0c3f\u0c02\u0c17\u0c4d\u0c38\u0c4d',
        SupportedUiLanguage.hindi =>
          '\u092a\u094d\u0930\u094b\u092b\u093e\u0907\u0932 \u0914\u0930 \u0938\u0947\u091f\u093f\u0902\u0917\u094d\u0938',
        SupportedUiLanguage.english => 'Profile & Settings',
        SupportedUiLanguage.tamil =>
          '\u0b9a\u0bc1\u0baf\u0bb5\u0bbf\u0bb5\u0bb0\u0bae\u0bcd & \u0b85\u0bae\u0bc8\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0caa\u0ccd\u0cb0\u0cca\u0cab\u0cc8\u0cb2\u0ccd \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cb8\u0cc6\u0c9f\u0ccd\u0c9f\u0cbf\u0c82\u0c97\u0ccd\u0cb8\u0ccd',
        SupportedUiLanguage.malayalam =>
          '\u0d2a\u0d4d\u0d30\u0d4a\u0d2b\u0d48\u0d7d & \u0d38\u0d46\u0d31\u0d4d\u0d31\u0d3f\u0d02\u0d17\u0d4d\u0d38\u0d4d',
      };

  String get accountSection =>
      _regionalFallback('Account') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => '\u0c05\u0c15\u0c4c\u0c02\u0c1f\u0c4d',
        SupportedUiLanguage.hindi => '\u0905\u0915\u093e\u0909\u0902\u091f',
        SupportedUiLanguage.english => 'Account',
        SupportedUiLanguage.tamil => '\u0b95\u0ba3\u0b95\u0bcd\u0b95\u0bc1',
        SupportedUiLanguage.kannada => '\u0c96\u0cbe\u0ca4\u0cc6',
        SupportedUiLanguage.malayalam =>
          '\u0d05\u0d15\u0d4d\u0d15\u0d57\u0d23\u0d4d\u0d1f\u0d4d',
      };

  String get appSettingsSection =>
      _regionalFallback('App Settings') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2f\u0c3e\u0c2a\u0c4d \u0c38\u0c46\u0c1f\u0c4d\u0c1f\u0c3f\u0c02\u0c17\u0c4d\u0c38\u0c4d',
        SupportedUiLanguage.hindi =>
          '\u090f\u092a \u0938\u0947\u091f\u093f\u0902\u0917\u094d\u0938',
        SupportedUiLanguage.english => 'App Settings',
        SupportedUiLanguage.tamil =>
          '\u0b86\u0baa\u0bcd \u0b85\u0bae\u0bc8\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0c86\u0caa\u0ccd \u0cb8\u0cc6\u0c9f\u0ccd\u0c9f\u0cbf\u0c82\u0c97\u0ccd\u0cb8\u0ccd',
        SupportedUiLanguage.malayalam =>
          '\u0d06\u0d2a\u0d4d\u0d2a\u0d4d \u0d38\u0d46\u0d31\u0d4d\u0d31\u0d3f\u0d02\u0d17\u0d4d\u0d38\u0d4d',
      };

  String get supportSection =>
      _regionalFallback('Support') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c2a\u0c4b\u0c30\u0c4d\u0c1f\u0c4d',
        SupportedUiLanguage.hindi => '\u0938\u092a\u094b\u0930\u094d\u091f',
        SupportedUiLanguage.english => 'Support',
        SupportedUiLanguage.tamil => '\u0b86\u0ba4\u0bb0\u0bb5\u0bc1',
        SupportedUiLanguage.kannada => '\u0cb8\u0cb9\u0cbe\u0caf',
        SupportedUiLanguage.malayalam => '\u0d38\u0d39\u0d3e\u0d2f\u0d02',
      };

  String get languageOption =>
      _regionalFallback('Language') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => '\u0c2d\u0c3e\u0c37',
        SupportedUiLanguage.hindi => '\u092d\u093e\u0937\u093e',
        SupportedUiLanguage.english => 'Language',
        SupportedUiLanguage.tamil => '\u0bae\u0bca\u0bb4\u0bbf',
        SupportedUiLanguage.kannada => '\u0cad\u0cbe\u0cb7\u0cc6',
        SupportedUiLanguage.malayalam => '\u0d2d\u0d3e\u0d37',
      };

  String get languageOptionSubtitle =>
      _regionalFallback('Choose your app language') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2e\u0c40 app \u0c2d\u0c3e\u0c37\u0c28\u0c41 \u0c0e\u0c02\u0c1a\u0c41\u0c15\u0c4b\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u0905\u092a\u0928\u0940 app language \u091a\u0941\u0928\u0947\u0902',
        SupportedUiLanguage.english => 'Choose your app language',
        SupportedUiLanguage.tamil =>
          '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd app \u0bae\u0bca\u0bb4\u0bbf\u0baf\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0ca8\u0cbf\u0cae\u0ccd\u0cae app \u0cad\u0bbe\u0cb7\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0abe\u0ca1\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 app \u0d2d\u0d3e\u0d37 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d42',
      };

  String get subscriptionOption =>
      _regionalFallback('Subscription') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c2c\u0c4d\u200c\u0c38\u0c4d\u0c15\u0c4d\u0c30\u0c3f\u0c2a\u0c4d\u0c37\u0c28\u0c4d / \u0c2a\u0c4d\u0c32\u0c3e\u0c28\u0c4d\u0c32\u0c41',
        SupportedUiLanguage.hindi =>
          '\u0938\u092c\u094d\u0938\u094d\u0915\u094d\u0930\u093f\u092a\u094d\u0936\u0928 / \u092a\u094d\u0932\u093e\u0928',
        SupportedUiLanguage.english => 'Subscription / Plans',
        SupportedUiLanguage.tamil => '\u0b9a\u0ba8\u0bcd\u0ba4\u0bbe / Plans',
        SupportedUiLanguage.kannada => '\u0c9a\u0c82\u0ca6\u0cbe / Plans',
        SupportedUiLanguage.malayalam =>
          '\u0d38\u0d2c\u0d4d\u0d38\u0d4d\u0d15\u0d4d\u0d30\u0d3f\u0d2a\u0d4d\u0d37\u0d7b / Plans',
      };

  String get subscriptionSubtitle =>
      _regionalFallback('Manage current plan and upgrades') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2a\u0c4d\u0c30\u0c38\u0c4d\u0c24\u0c41\u0c24\u0c02 \u0c09\u0c28\u0c4d\u0c28 plan \u0c2e\u0c30\u0c3f\u0c2f\u0c41 upgrades',
        SupportedUiLanguage.hindi =>
          'Current plan \u0914\u0930 upgrades manage \u0915\u0930\u0947\u0902',
        SupportedUiLanguage.english => 'Manage current plan and upgrades',
        SupportedUiLanguage.tamil =>
          '\u0ba4\u0bb1\u0bcd\u0baa\u0bcb\u0ba4\u0bc1\u0baf plan \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd upgrades-\u0b90 manage \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bb5\u0bc1\u0bae\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0cbf\u0caa\u0ccd\u0caa\u0cbf\u0ca8 current plan \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 upgrades \u0ca8\u0ccd\u0ca8\u0cc1 manage \u0cae\u0cbe\u0ca1\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d28\u0d3f\u0d32\u0d35\u0d3f\u0d32\u0d41\u0d33\u0d4d\u0d33 plan \u0d09\u0d02 upgrades-\u0d09\u0d02 manage \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d41\u0d15',
      };

  String get permissionsOptionSubtitle =>
      _regionalFallback('Photos, storage and other access') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'Photos, storage \u0c2e\u0c30\u0c3f\u0c2f\u0c41 \u0c07\u0c24\u0c30 access',
        SupportedUiLanguage.hindi =>
          'Photos, storage \u0914\u0930 other access',
        SupportedUiLanguage.english => 'Photos, storage and other access',
        SupportedUiLanguage.tamil =>
          'Photos, storage \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0baa\u0bbf\u0bb1 access',
        SupportedUiLanguage.kannada =>
          'Photos, storage \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0c87\u0ca4\u0cb0 access',
        SupportedUiLanguage.malayalam =>
          'Photos, storage \u0d15\u0d42\u0d1f\u0d3e\u0d24\u0d46 \u0d2e\u0d31\u0d4d\u0d31 access',
      };

  String get notificationsOptionSubtitle =>
      _regionalFallback('Control alerts and updates') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'Alerts \u0c2e\u0c30\u0c3f\u0c2f\u0c41 updates \u0c28\u0c3f\u0c2f\u0c02\u0c24\u0c4d\u0c30\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          'Alerts \u0914\u0930 updates \u0928\u093f\u092f\u0902\u0924\u094d\u0930\u093f\u0924 \u0915\u0930\u0947\u0902',
        SupportedUiLanguage.english => 'Control alerts and updates',
        SupportedUiLanguage.tamil =>
          'Alerts \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd updates-\u0b90 \u0b95\u0b9f\u0bcd\u0b9f\u0bc1\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          'Alerts \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 updates \u0ca8\u0cbf\u0caf\u0c82\u0ca4\u0ccd\u0cb0\u0cbf\u0cb8\u0cbf',
        SupportedUiLanguage.malayalam =>
          'Alerts \u0d09\u0d02 updates-\u0d09\u0d02 \u0d28\u0d3f\u0d2f\u0d28\u0d4d\u0d24\u0d4d\u0d30\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d15',
      };

  String get helpSupport =>
      _regionalFallback('Help & Support') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c39\u0c3e\u0c2f\u0c02 & \u0c38\u0c2a\u0c4b\u0c30\u0c4d\u0c1f\u0c4d',
        SupportedUiLanguage.hindi =>
          '\u092e\u0926\u0926 \u0914\u0930 \u0938\u092a\u094b\u0930\u094d\u091f',
        SupportedUiLanguage.english => 'Help & Support',
        SupportedUiLanguage.tamil => '\u0b89\u0ba4\u0bb5\u0bbf & Support',
        SupportedUiLanguage.kannada => '\u0cb8\u0cb9\u0cbe\u0caf & Support',
        SupportedUiLanguage.malayalam =>
          '\u0d38\u0d39\u0d3e\u0d2f\u0d02 & Support',
      };

  String get helpSupportSubtitle =>
      _regionalFallback('Get help and contact support') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c39\u0c3e\u0c2f\u0c02 \u0c2a\u0c4a\u0c02\u0c26\u0c02\u0c21\u0c3f \u0c2e\u0c30\u0c3f\u0c2f\u0c41 support \u0c28\u0c41 \u0c38\u0c02\u0c2a\u0c4d\u0c30\u0c26\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u092e\u0926\u0926 \u0932\u0947\u0902 \u0914\u0930 support \u0938\u0947 \u0938\u0902\u092a\u0930\u094d\u0915 \u0915\u0930\u0947\u0902',
        SupportedUiLanguage.english => 'Get help and contact support',
        SupportedUiLanguage.tamil =>
          '\u0b89\u0ba4\u0bb5\u0bbf \u0baa\u0bc6\u0bb1\u0bcd\u0bb1\u0bc1 support-\u0b90 \u0ba4\u0bca\u0b9f\u0bb0\u0bcd\u0baa\u0bc1 \u0b95\u0bca\u0bb3\u0bcd\u0bb3\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
        SupportedUiLanguage.kannada =>
          '\u0cb8\u0cb9\u0cbe\u0caf \u0caa\u0ca1\u0cc6\u0ca6\u0cc1 support \u0ca8\u0cbf\u0c82\u0ca6 \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95 \u0cae\u0cbe\u0ca1\u0cbf',
        SupportedUiLanguage.malayalam =>
          '\u0d38\u0d39\u0d3e\u0d2f\u0d02 \u0d32\u0d2d\u0d3f\u0d15\u0d4d\u0d15\u0d42 \u0d15\u0d42\u0d1f\u0d3e\u0d24\u0d46 support-\u0d28\u0d47\u0d1f\u0d4d\u0d1f\u0d3f \u0d2c\u0d28\u0d4d\u0d27\u0d2a\u0d46\u0d1f\u0d41\u0d15',
      };

  String get aboutApp =>
      _regionalFallback('About App') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2f\u0c3e\u0c2a\u0c4d \u0c17\u0c41\u0c30\u0c3f\u0c02\u0c1a\u0c3f',
        SupportedUiLanguage.hindi =>
          '\u090f\u092a \u0915\u0947 \u092c\u093e\u0930\u0947 \u092e\u0947\u0902',
        SupportedUiLanguage.english => 'About App',
        SupportedUiLanguage.tamil => 'App \u0baa\u0bb1\u0bcd\u0bb1\u0bbf',
        SupportedUiLanguage.kannada => 'App \u0cac\u0c97\u0ccd\u0c97\u0cc6',
        SupportedUiLanguage.malayalam =>
          'App-\u0d28\u0d46\u0d15\u0dcd\u0d15\u0d41\u0d31\u0d3f\u0d1a\u0d4d\u0d1a\u0d4d',
      };

  String get aboutAppSubtitle =>
      _regionalFallback('App details and version info') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'App \u0c35\u0c3f\u0c35\u0c30\u0c3e\u0c32\u0c41 \u0c2e\u0c30\u0c3f\u0c2f\u0c41 version \u0c38\u0c2e\u0c3e\u0c1a\u0c3e\u0c30\u0c02',
        SupportedUiLanguage.hindi => 'App details \u0914\u0930 version info',
        SupportedUiLanguage.english => 'App details and version info',
        SupportedUiLanguage.tamil =>
          'App details \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd version info',
        SupportedUiLanguage.kannada =>
          'App details \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 version info',
        SupportedUiLanguage.malayalam =>
          'App details \u0d09\u0d02 version info-\u0d09\u0d02',
      };

  String get logout =>
      _regionalFallback('Logout') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c32\u0c3e\u0c17\u0c4d \u0c05\u0c35\u0c41\u0c1f\u0c4d',
        SupportedUiLanguage.hindi => '\u0932\u0949\u0917 \u0906\u0909\u091f',
        SupportedUiLanguage.english => 'Logout',
        SupportedUiLanguage.tamil =>
          '\u0bb5\u0bc6\u0bb3\u0bbf\u0baf\u0bc7\u0bb1\u0bc1',
        SupportedUiLanguage.kannada =>
          '\u0cb2\u0cbe\u0c97\u0ccd\u0c85\u0cb5\u0cc1\u0c9f\u0ccd',
        SupportedUiLanguage.malayalam =>
          '\u0d32\u0d4b\u0d17\u0d4d\u0d05\u0d57\u0d1f\u0d4d',
      };

  String get logoutSubtitle =>
      _regionalFallback('Sign out logic can be connected later') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          'Sign out logic \u0c24\u0c30\u0c4d\u0c35\u0c3e\u0c24 connect \u0c05\u0c35\u0c41\u0c24\u0c41\u0c02\u0c26\u0c3f',
        SupportedUiLanguage.hindi =>
          'Sign out logic \u092c\u093e\u0926 \u092e\u0947\u0902 connect \u0939\u094b\u0917\u0940',
        SupportedUiLanguage.english => 'Sign out logic can be connected later',
        SupportedUiLanguage.tamil =>
          'Sign out logic \u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0bb0\u0bcd connect \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bb2\u0bbe\u0bae\u0bcd.',
        SupportedUiLanguage.kannada =>
          'Sign out logic \u0ca8\u0c82\u0ca4\u0cb0 connect \u0cae\u0cbe\u0ca1\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
        SupportedUiLanguage.malayalam =>
          'Sign out logic \u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d40\u0d1f\u0d4d connect \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0dbe\u0d35\u0d41\u0d28\u0d4d\u0d28\u0d24\u0d3e\u0d23\u0d4d.',
      };

  String get languageSettingsTitle =>
      _regionalFallback('Language Settings') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2d\u0c3e\u0c37 \u0c38\u0c46\u0c1f\u0c4d\u0c1f\u0c3f\u0c02\u0c17\u0c4d\u0c38\u0c4d',
        SupportedUiLanguage.hindi =>
          '\u092d\u093e\u0937\u093e \u0938\u0947\u091f\u093f\u0902\u0917\u094d\u0938',
        SupportedUiLanguage.english => 'Language Settings',
        SupportedUiLanguage.tamil => '\u0bae\u0bca\u0bb4\u0bbf Settings',
        SupportedUiLanguage.kannada => '\u0cad\u0bbe\u0cb7\u0cc6 Settings',
        SupportedUiLanguage.malayalam => '\u0d2d\u0d3e\u0d37 Settings',
      };

  String get currentLanguageLabel =>
      _regionalFallback('Current language') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c2a\u0c4d\u0c30\u0c38\u0c4d\u0c24\u0c41\u0c24 \u0c2d\u0c3e\u0c37',
        SupportedUiLanguage.hindi =>
          '\u0935\u0930\u094d\u0924\u092e\u093e\u0928 \u092d\u093e\u0937\u093e',
        SupportedUiLanguage.english => 'Current language',
        SupportedUiLanguage.tamil =>
          '\u0ba4\u0bb1\u0bcd\u0baa\u0bcb\u0ba4\u0bc8\u0baf \u0bae\u0bca\u0bb4\u0bbf',
        SupportedUiLanguage.kannada =>
          '\u0caa\u0ccd\u0cb0\u0cb8\u0ccd\u0ca4\u0cc1\u0ca4 \u0cad\u0bbe\u0cb7\u0cc6',
        SupportedUiLanguage.malayalam =>
          '\u0d28\u0d3f\u0d32\u0d35\u0d3f\u0d32\u0d46 \u0d2d\u0d3e\u0d37',
      };

  String get saveApply =>
      _regionalFallback('Save / Apply') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu =>
          '\u0c38\u0c47\u0c35\u0c4d / \u0c05\u0c2a\u0c4d\u0c32\u0c48',
        SupportedUiLanguage.hindi =>
          '\u0938\u0947\u0935 / \u0905\u092a\u094d\u0932\u093e\u0908',
        SupportedUiLanguage.english => 'Save / Apply',
        SupportedUiLanguage.tamil => '\u0b9a\u0bc7\u0bae\u0bbf / Apply',
        SupportedUiLanguage.kannada => '\u0c89\u0cb3\u0cbf\u0cb8\u0cbf / Apply',
        SupportedUiLanguage.malayalam => '\u0d38\u0d47\u0d35\u0d4d / Apply',
      };

  String languageName(AppLanguage value) => switch (value) {
    AppLanguage.telugu => '\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41',
    AppLanguage.hindi => '\u0939\u093f\u0928\u094d\u0926\u0940',
    AppLanguage.english => 'English',
    AppLanguage.tamil => '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd',
    AppLanguage.kannada => '\u0c95\u0ca8\u0ccd\u0ca8\u0ca1',
    AppLanguage.malayalam => '\u0d2e\u0d32\u0d2f\u0d3e\u0d33\u0d02',
    AppLanguage.assamese => 'Assamese',
    AppLanguage.konkani => 'Konkani',
    AppLanguage.gujarati => 'Gujarati',
    AppLanguage.marathi => 'Marathi',
    AppLanguage.meitei => 'Meitei (Manipuri)',
    AppLanguage.mizo => 'Mizo',
    AppLanguage.odia => 'Odia',
    AppLanguage.punjabi => 'Punjabi',
    AppLanguage.nepali => 'Nepali',
    AppLanguage.bengali => 'Bengali',
    AppLanguage.kashmiri => 'Kashmiri',
    AppLanguage.ladakhi => 'Ladakhi',
  };

  List<String> localizedHomeCategories() => (switch (language
      .supportedUiLanguage) {
    SupportedUiLanguage.telugu => const <String>[
      '\u0c05\u0c28\u0c4d\u0c28\u0c40',
      '\u0c36\u0c41\u0c2d\u0c4b\u0c26\u0c2f\u0c02',
      '\u0c36\u0c41\u0c2d \u0c2e\u0c27\u0c4d\u0c2f\u0c3e\u0c39\u0c4d\u0c28\u0c02',
      '\u0c36\u0c41\u0c2d\u0c30\u0c3e\u0c24\u0c4d\u0c30\u0c3f',
      '\u0c2a\u0c4d\u0c30\u0c47\u0c30\u0c23\u0c3e\u0c24\u0c4d\u0c2e\u0c15',
      '\u0c2a\u0c4d\u0c30\u0c47\u0c2e \u0c15\u0c4b\u0c1f\u0c4d\u0c38\u0c4d',
      '\u0c08\u0c30\u0c4b\u0c1c\u0c41 \u0c2a\u0c4d\u0c30\u0c24\u0c4d\u0c2f\u0c47\u0c15\u0c02',
      '\u0c2a\u0c41\u0c1f\u0c4d\u0c1f\u0c3f\u0c28\u0c30\u0c4b\u0c1c\u0c41\u0c32\u0c41',
      '\u0c1c\u0c40\u0c35\u0c3f\u0c24 \u0c38\u0c32\u0c39\u0c3e\u0c32\u0c41',
      '\u0c17\u0c40\u0c24\u0c3e \u0c1c\u0c4d\u0c1e\u0c3e\u0c28\u0c02',
      '\u0c2d\u0c15\u0c4d\u0c24\u0c3f',
      '\u0c2e\u0c39\u0c3e\u0c2d\u0c3e\u0c30\u0c24\u0c02',
      '\u0c35\u0c3e\u0c30\u0c4d\u0c37\u0c3f\u0c15\u0c4b\u0c24\u0c4d\u0c38\u0c35\u0c02',
      '\u0c2e\u0c02\u0c1a\u0c3f \u0c06\u0c32\u0c4b\u0c1a\u0c28\u0c32\u0c41',
      '\u0c2c\u0c48\u0c2c\u0c3f\u0c32\u0c4d',
      '\u0c07\u0c38\u0c4d\u0c32\u0c3e\u0c02',
      'జోక్స్',
      'మరిన్ని',
    ],
    SupportedUiLanguage.hindi => const <String>[
      '\u0938\u092d\u0940',
      '\u0938\u0941\u092a\u094d\u0930\u092d\u093e\u0924',
      '\u0936\u0941\u092d \u0926\u094b\u092a\u0939\u0930',
      '\u0936\u0941\u092d \u0930\u093e\u0924\u094d\u0930\u093f',
      '\u092a\u094d\u0930\u0947\u0930\u0923\u093e\u0926\u093e\u092f\u0915',
      '\u092a\u094d\u0930\u0947\u092e \u0909\u0926\u094d\u0927\u0930\u0923',
      '\u0906\u091c \u0915\u093e \u0935\u093f\u0936\u0947\u0937',
      '\u091c\u0928\u094d\u092e\u0926\u093f\u0928',
      '\u091c\u0940\u0935\u0928 \u0938\u0932\u093e\u0939',
      '\u0917\u0940\u0924\u093e \u091c\u094d\u091e\u093e\u0928',
      '\u092d\u0915\u094d\u0924\u093f',
      '\u092e\u0939\u093e\u092d\u093e\u0930\u0924',
      '\u0935\u0930\u094d\u0937\u0917\u093e\u0901\u0920',
      '\u0905\u091a\u094d\u091b\u0947 \u0935\u093f\u091a\u093e\u0930',
      '\u092c\u093e\u0907\u092c\u0932',
      '\u0907\u0938\u094d\u0932\u093e\u092e',
      'चुटकुले',
      'और',
    ],
    SupportedUiLanguage.english => const <String>[
      'All',
      'Good Morning',
      'Good Afternoon',
      'Good Night',
      'Motivational',
      'Love Quotes',
      'Today Special',
      'Birthdays',
      'Life Advice',
      'Gita Wisdom',
      'Devotional',
      'Mahabharata',
      'Anniversary',
      'Good Thoughts',
      'Bible',
      'Islam',
      'Jokes',
      'More',
    ],
    SupportedUiLanguage.tamil => const <String>[
      '\u0b85\u0ba9\u0bc8\u0ba4\u0bcd\u0ba4\u0bc1\u0bae\u0bcd',
      '\u0b87\u0ba9\u0bbf\u0baf \u0b95\u0bbe\u0bb2\u0bc8',
      '\u0b87\u0ba9\u0bbf\u0baf \u0bae\u0ba4\u0bbf\u0baf\u0bae\u0bcd',
      '\u0b87\u0ba9\u0bbf\u0baf \u0b87\u0bb0\u0bb5\u0bc1',
      '\u0b8a\u0b95\u0bcd\u0b95\u0bae\u0bb3\u0bbf\u0baa\u0bcd\u0baa\u0bc1',
      '\u0b95\u0bbe\u0ba4\u0bb2\u0bcd \u0bae\u0bc7\u0bb1\u0bcd\u0b95\u0bcb\u0bb3\u0bcd\u0b95\u0bb3\u0bcd',
      '\u0b87\u0ba9\u0bcd\u0bb1\u0bc8\u0baf \u0b9a\u0bbf\u0bb1\u0baa\u0bcd\u0baa\u0bc1',
      '\u0baa\u0bbf\u0bb1\u0ba8\u0bcd\u0ba4\u0ba8\u0bbe\u0bb3\u0bcd\u0b95\u0bb3\u0bcd',
      '\u0bb5\u0bbe\u0bb4\u0bcd\u0b95\u0bcd\u0b95\u0bc8 \u0b86\u0bb2\u0bcb\u0b9a\u0ba9\u0bc8',
      '\u0b95\u0bc0\u0ba4\u0bbe \u0b9e\u0bbe\u0ba9\u0bae\u0bcd',
      '\u0baa\u0b95\u0bcd\u0ba4\u0bbf',
      '\u0bae\u0b95\u0bbe\u0baa\u0bbe\u0bb0\u0ba4\u0bae\u0bcd',
      '\u0b86\u0ba3\u0bcd\u0b9f\u0bc1 \u0bb5\u0bbf\u0bb4\u0bbe',
      '\u0ba8\u0bb2\u0bcd\u0bb2 \u0b8e\u0ba3\u0bcd\u0ba3\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
      '\u0baa\u0bc8\u0baa\u0bbf\u0bb3\u0bcd',
      '\u0b87\u0bb8\u0bcd\u0bb2\u0bbe\u0bae\u0bcd',
      'நகைச்சுவை',
      'மேலும்',
    ],
    SupportedUiLanguage.kannada => const <String>[
      '\u0c8e\u0cb2\u0ccd\u0cb2\u0cb5\u0cc2',
      '\u0cb6\u0cc1\u0cad\u0ccb\u0ca6\u0caf',
      '\u0cb6\u0cc1\u0cad \u0cae\u0ca7\u0ccd\u0caf\u0cbe\u0cb9\u0ccd\u0ca8',
      '\u0cb6\u0cc1\u0cad \u0cb0\u0cbe\u0ca4\u0ccd\u0cb0\u0cbf',
      '\u0caa\u0ccd\u0cb0\u0cc7\u0cb0\u0ca3\u0cbe\u0ca6\u0cbe\u0caf\u0c95',
      '\u0caa\u0ccd\u0cb0\u0cc0\u0ca4\u0cbf \u0c89\u0c95\u0ccd\u0ca4\u0cbf\u0c97\u0cb3\u0cc1',
      '\u0c87\u0c82\u0ca6\u0cbf\u0ca8 \u0cb5\u0cbf\u0cb6\u0cc7\u0cb7',
      '\u0c9c\u0ca8\u0ccd\u0cae\u0ca6\u0cbf\u0ca8\u0c97\u0cb3\u0cc1',
      '\u0c9c\u0cc0\u0cb5\u0ca8 \u0cb8\u0cb2\u0cb9\u0cc6',
      '\u0c97\u0cc0\u0ca4\u0cbe \u0c9c\u0ccd\u0c9e\u0cbe\u0ca8',
      '\u0cad\u0c95\u0ccd\u0ca4\u0cbf',
      '\u0cae\u0cb9\u0cbe\u0cad\u0cbe\u0cb0\u0ca4',
      '\u0cb5\u0cbe\u0cb0\u0ccd\u0cb7\u0cbf\u0c95\u0ccb\u0ca4\u0ccd\u0cb8\u0cb5',
      '\u0c92\u0cb3\u0ccd\u0cb3\u0cc6\u0caf \u0c86\u0cb2\u0ccb\u0c9a\u0ca8\u0cc6\u0c97\u0cb3\u0cc1',
      '\u0cac\u0cc8\u0cac\u0cb2\u0ccd',
      '\u0c87\u0cb8\u0ccd\u0cb2\u0cbe\u0c82',
      'ಜೋಕ್ಸ್',
      'ಇನ್ನಷ್ಟು',
    ],
    SupportedUiLanguage.malayalam => const <String>[
      '\u0d0e\u0d32\u0d4d\u0d32\u0d3e\u0d02',
      '\u0d36\u0d41\u0d2d\u0d4b\u0d26\u0d2f\u0d02',
      '\u0d36\u0d41\u0d2d \u0d09\u0d1a\u0d4d\u0d1a\u0d15\u0d4d\u0d15\u0d4d',
      '\u0d36\u0d41\u0d2d \u0d30\u0d3e\u0d24\u0d4d\u0d30\u0d3f',
      '\u0d2a\u0d4d\u0d30\u0d1a\u0d4b\u0d26\u0d28\u0d3e\u0d24\u0d4d\u0d2e\u0d15\u0d02',
      '\u0d2a\u0d4d\u0d30\u0d23\u0d2f \u0d09\u0d26\u0d4d\u0d27\u0d30\u0d23\u0d3f\u0d15\u0d7e',
      '\u0d07\u0d28\u0d4d\u0d28\u0d24\u0d4d\u0d24\u0d46 \u0d2a\u0d4d\u0d30\u0d24\u0d4d\u0d2f\u0d47\u0d15\u0d24',
      '\u0d1c\u0d28\u0d4d\u0d2e\u0d26\u0d3f\u0d28\u0d19\u0d4d\u0d19\u0d7e',
      '\u0d1c\u0d40\u0d35\u0d3f\u0d24 \u0d09\u0d2a\u0d26\u0d47\u0d36\u0d02',
      '\u0d17\u0d40\u0d24\u0d3e \u0d1c\u0d4d\u0d1e\u0d3e\u0d28\u0d02',
      '\u0d2d\u0d15\u0d4d\u0d24\u0d3f',
      '\u0d2e\u0d39\u0d3e\u0d2d\u0d3e\u0d30\u0d24\u0d02',
      '\u0d35\u0d3e\u0d30\u0d4d\u0d37\u0d3f\u0d15\u0d02',
      '\u0d28\u0d32\u0d4d\u0d32 \u0d1a\u0d3f\u0d28\u0d4d\u0d24\u0d15\u0d7e',
      '\u0d2c\u0d48\u0d2c\u0d3f\u0d7d',
      '\u0d07\u0d38\u0d4d\u0d32\u0d3e\u0d02',
      'തമാശകൾ',
      'കൂടുതൽ',
    ],
  }).map((item) => _sanitizeDisplayText(item)).toList(growable: false);

  List<String> homeCategories() => localizedHomeCategories();
}
