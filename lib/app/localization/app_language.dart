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

enum SupportedUiLanguage {
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

extension AppLanguageSupportX on AppLanguage {
  SupportedUiLanguage get supportedUiLanguage {
    return switch (this) {
      AppLanguage.telugu => SupportedUiLanguage.telugu,
      AppLanguage.hindi => SupportedUiLanguage.hindi,
      AppLanguage.english => SupportedUiLanguage.english,
      AppLanguage.tamil => SupportedUiLanguage.tamil,
      AppLanguage.kannada => SupportedUiLanguage.kannada,
      AppLanguage.malayalam => SupportedUiLanguage.malayalam,
      AppLanguage.assamese => SupportedUiLanguage.assamese,
      AppLanguage.konkani => SupportedUiLanguage.konkani,
      AppLanguage.gujarati => SupportedUiLanguage.gujarati,
      AppLanguage.marathi => SupportedUiLanguage.marathi,
      AppLanguage.meitei => SupportedUiLanguage.meitei,
      AppLanguage.mizo => SupportedUiLanguage.mizo,
      AppLanguage.odia => SupportedUiLanguage.odia,
      AppLanguage.punjabi => SupportedUiLanguage.punjabi,
      AppLanguage.nepali => SupportedUiLanguage.nepali,
      AppLanguage.bengali => SupportedUiLanguage.bengali,
      AppLanguage.kashmiri => SupportedUiLanguage.kashmiri,
      AppLanguage.ladakhi => SupportedUiLanguage.ladakhi,
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
    'No matching region found.':
        'Ú©ÙˆØ¦ÛŒ Ù…Ù„ØªØ§ Ø¬Ù„ØªØ§ Ø¹Ù„Ø§Ù‚Û Ù†ÛÛŒÚº Ù…Ù„Ø§Û”',
    'Political Parties': 'Ø³ÛŒØ§Ø³ÛŒ Ø¬Ù…Ø§Ø¹ØªÛŒÚº',
    'National': 'Ù‚ÙˆÙ…ÛŒ',
    'State': 'Ø±ÛŒØ§Ø³Øª',
    'Continue': 'Ø¬Ø§Ø±ÛŒ Ø±Ú©Ú¾ÛŒÚº',
    'Login': 'Ù„Ø§Ú¯ Ø§Ù†',
    'Sign Up': 'Ø³Ø§Ø¦Ù† Ø§Ù¾',
    'Continue with Google': 'Google Ú©Û’ Ø³Ø§ØªÚ¾ Ø¬Ø§Ø±ÛŒ Ø±Ú©Ú¾ÛŒÚº',
    'Email address': 'Ø§ÛŒ Ù…ÛŒÙ„ Ù¾ØªÛ',
    'Password': 'Ù¾Ø§Ø³ ÙˆØ±Úˆ',
    'Forgot Password': 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø¨Ú¾ÙˆÙ„ Ú¯Ø¦Û’ØŸ',
    "Don't have an account?": 'اکاؤنٹ نہیں ہے؟',
    'Already have an account?': 'پہلے سے اکاؤنٹ ہے؟',
    'Login with Email': 'Ø§ÛŒ Ù…ÛŒÙ„ Ø³Û’ Ù„Ø§Ú¯ Ø§Ù† Ú©Ø±ÛŒÚº',
    'Sign Up with Email': 'Ø§ÛŒ Ù…ÛŒÙ„ Ø³Û’ Ø³Ø§Ø¦Ù† Ø§Ù¾ Ú©Ø±ÛŒÚº',
    'Create & Share': 'بنائیں اور شیئر کریں',
    'Create': 'Ø¨Ù†Ø§Ø¦ÛŒÚº',
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

const Map<AppLanguage, Map<String, String>>
_regionalCommunityUploadFallbacks = <AppLanguage, Map<String, String>>{
  AppLanguage.assamese: <String, String>{
    'Check review rules before submitting your content.':
        'বিষয়বস্তু পঠিওৱাৰ আগতে পৰ্যালোচনা নিয়ম চাওক।',
    'Community Upload Instructions': 'সমাজ আপলোড নিৰ্দেশনা',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'আপোনাৰ উদ্ধৃতি, লিখনি বা উদ্ধৃতি থকা ছবি Mana Poster পৰ্যালোচনা দললৈ পঠিয়াওক।',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'আপুনি পঠিওৱা বিষয়বস্তুৰ দায়িত্ব আপোনাৰ। পঠিওৱাৰ অৰ্থ হৈছে সেয়া Mana Poster ৰ নিয়ম আৰু সমাজ নীতি মানি চলে বুলি আপুনি নিশ্চিত কৰিছে।',
    'How it works': 'ই কেনেকৈ কাম কৰে',
    'You can upload quote text, a quote image, or both.':
        'আপুনি উদ্ধৃতি লিখনি, উদ্ধৃতি ছবি বা দুয়োটাই পঠিয়াব পাৰে।',
    'Your upload first goes to the manager review queue.':
        'আপোনাৰ আপলোড প্ৰথমে মেনেজাৰ পৰ্যালোচনা শাৰীত যায়।',
    'What can be approved': 'কি অনুমোদিত হব পাৰে',
    'Clean quote or image that matches the selected category.':
        'বাছনি কৰা শ্ৰেণীৰ সৈতে মিলা পৰিষ্কাৰ উদ্ধৃতি বা ছবি।',
    'Content created by you or content you have permission to use.':
        'আপুনি নিজে সৃষ্টি কৰা বা ব্যৱহাৰৰ অনুমতি থকা বিষয়বস্তু।',
    'Rejection reasons': 'নাকচ কৰাৰ কাৰণ',
    'Wrong category, unrelated content, duplicate, or low quality image.':
        'ভুল শ্ৰেণী, অসংলগ্ন বিষয়বস্তু, পুনৰাবৃত্তি বা নিম্ন মানৰ ছবি।',
    'Copyright image, copied quote, offensive, or misleading content.':
        'কপিৰাইট ছবি, নকল উদ্ধৃতি, অপমানজনক বা ভ্ৰান্তিকৰ বিষয়বস্তু।',
    'Private details, political misuse, spam, or unsafe content.':
        'ব্যক্তিগত তথ্য, ৰাজনৈতিক অপব্যৱহাৰ, স্পেম বা অসুৰক্ষিত বিষয়বস্তু।',
  },
  AppLanguage.gujarati: <String, String>{
    'Check review rules before submitting your content.':
        'કન્ટેન્ટ મોકલતા પહેલાં સમીક્ષા નિયમો વાંચો.',
    'Community Upload Instructions': 'સમુદાય અપલોડ સૂચનાઓ',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'તમારું સુવાક્ય, લખાણ અથવા સુવાક્યવાળો ફોટો Mana Poster સમીક્ષા ટીમને મોકલો.',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'તમે અપલોડ કરેલા કન્ટેન્ટ માટે તમે જવાબદાર છો. મોકલવાથી તમે ખાતરી આપો છો કે તમારું અપલોડ Mana Poster નિયમો અને સમુદાય માર્ગદર્શિકા અનુસરે છે.',
    'How it works': 'આ કેવી રીતે કામ કરે છે',
    'You can upload quote text, a quote image, or both.':
        'તમે સુવાક્ય લખાણ, સુવાક્યવાળો ફોટો અથવા બંને મોકલી શકો છો.',
    'Your upload first goes to the manager review queue.':
        'તમારું અપલોડ પહેલા મેનેજર સમીક્ષા કતારમાં જશે.',
    'What can be approved': 'શું મંજૂર થઈ શકે',
    'Clean quote or image that matches the selected category.':
        'પસંદ કરેલી કેટેગરીને મેળ ખાતું સ્વચ્છ સુવાક્ય અથવા ફોટો.',
    'Content created by you or content you have permission to use.':
        'તમારા દ્વારા બનાવેલું અથવા ઉપયોગની પરવાનગી ધરાવતું કન્ટેન્ટ.',
    'Rejection reasons': 'નકારવાના કારણો',
    'Wrong category, unrelated content, duplicate, or low quality image.':
        'ખોટી કેટેગરી, અસંબંધિત કન્ટેન્ટ, ડુપ્લિકેટ અથવા ઓછી ગુણવત્તાનો ફોટો.',
    'Copyright image, copied quote, offensive, or misleading content.':
        'કૉપિરાઇટ ફોટો, નકલ કરેલું સુવાક્ય, અપમાનજનક અથવા ભ્રામક કન્ટેન્ટ.',
    'Private details, political misuse, spam, or unsafe content.':
        'ખાનગી માહિતી, રાજકીય દુરુપયોગ, સ્પામ અથવા અસુરક્ષિત કન્ટેન્ટ.',
  },
  AppLanguage.marathi: <String, String>{
    'Check review rules before submitting your content.':
        'कंटेंट पाठवण्यापूर्वी पुनरावलोकन नियम वाचा.',
    'Community Upload Instructions': 'समुदाय अपलोड सूचना',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'तुमचा सुविचार, मजकूर किंवा सुविचार असलेला फोटो Mana Poster पुनरावलोकन टीमकडे पाठवा.',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'तुम्ही अपलोड केलेल्या कंटेंटची जबाबदारी तुमची आहे. पाठवल्यानंतर तुम्ही ते Mana Poster नियम आणि समुदाय मार्गदर्शक तत्त्वांनुसार आहे याची खात्री देता.',
    'How it works': 'हे कसे काम करते',
    'You can upload quote text, a quote image, or both.':
        'तुम्ही सुविचार मजकूर, सुविचार असलेला फोटो किंवा दोन्ही पाठवू शकता.',
    'Your upload first goes to the manager review queue.':
        'तुमचे अपलोड आधी व्यवस्थापक पुनरावलोकन रांगेत जाते.',
    'What can be approved': 'काय मंजूर होऊ शकते',
    'Clean quote or image that matches the selected category.':
        'निवडलेल्या श्रेणीशी जुळणारा स्वच्छ सुविचार किंवा फोटो.',
    'Content created by you or content you have permission to use.':
        'तुम्ही तयार केलेले किंवा वापरण्याची परवानगी असलेले कंटेंट.',
    'Rejection reasons': 'नाकारण्याची कारणे',
    'Wrong category, unrelated content, duplicate, or low quality image.':
        'चुकीची श्रेणी, असंबंधित कंटेंट, डुप्लिकेट किंवा कमी गुणवत्तेचा फोटो.',
    'Copyright image, copied quote, offensive, or misleading content.':
        'कॉपीराइट फोटो, कॉपी केलेला सुविचार, आक्षेपार्ह किंवा दिशाभूल करणारे कंटेंट.',
    'Private details, political misuse, spam, or unsafe content.':
        'खाजगी माहिती, राजकीय गैरवापर, स्पॅम किंवा असुरक्षित कंटेंट.',
  },
  AppLanguage.odia: <String, String>{
    'Check review rules before submitting your content.':
        'ବିଷୟବସ୍ତୁ ପଠାଇବା ପୂର୍ବରୁ ସମୀକ୍ଷା ନିୟମ ଦେଖନ୍ତୁ।',
    'Community Upload Instructions': 'ସମୁଦାୟ ଅପଲୋଡ୍ ନିର୍ଦ୍ଦେଶ',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'ଆପଣଙ୍କ ଉକ୍ତି, ଲେଖା କିମ୍ବା ଉକ୍ତି ଥିବା ଫଟୋକୁ Mana Poster ସମୀକ୍ଷା ଦଳକୁ ପଠାନ୍ତୁ।',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'ଆପଣ ଅପଲୋଡ୍ କରୁଥିବା ବିଷୟବସ୍ତୁ ପାଇଁ ଆପଣ ଦାୟୀ। ପଠାଇବା ମାଧ୍ୟମରେ ଏହା Mana Poster ନିୟମ ଓ ସମୁଦାୟ ନିର୍ଦ୍ଦେଶିକା ମାନୁଛି ବୋଲି ଆପଣ ନିଶ୍ଚିତ କରୁଛନ୍ତି।',
  },
  AppLanguage.punjabi: <String, String>{
    'Check review rules before submitting your content.':
        'ਸਮੱਗਰੀ ਭੇਜਣ ਤੋਂ ਪਹਿਲਾਂ ਸਮੀਖਿਆ ਨਿਯਮ ਵੇਖੋ।',
    'Community Upload Instructions': 'ਕਮਿਊਨਿਟੀ ਅਪਲੋਡ ਹਦਾਇਤਾਂ',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'ਆਪਣਾ ਵਿਚਾਰ-ਵਾਕ, ਲਿਖਤ ਜਾਂ ਵਿਚਾਰ-ਵਾਕ ਵਾਲੀ ਫੋਟੋ Mana Poster ਸਮੀਖਿਆ ਟੀਮ ਨੂੰ ਭੇਜੋ।',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'ਤੁਸੀਂ ਅਪਲੋਡ ਕੀਤੀ ਸਮੱਗਰੀ ਲਈ ਜ਼ਿੰਮੇਵਾਰ ਹੋ। ਭੇਜਣ ਨਾਲ ਤੁਸੀਂ ਪੁਸ਼ਟੀ ਕਰਦੇ ਹੋ ਕਿ ਇਹ Mana Poster ਨਿਯਮਾਂ ਅਤੇ ਕਮਿਊਨਿਟੀ ਹਦਾਇਤਾਂ ਦੀ ਪਾਲਣਾ ਕਰਦੀ ਹੈ।',
  },
  AppLanguage.bengali: <String, String>{
    'Check review rules before submitting your content.':
        'কনটেন্ট পাঠানোর আগে পর্যালোচনা নিয়ম দেখুন।',
    'Community Upload Instructions': 'কমিউনিটি আপলোড নির্দেশনা',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'আপনার উক্তি, লেখা বা উক্তিসহ ছবি Mana Poster পর্যালোচনা দলে পাঠান।',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'আপনি যে কনটেন্ট আপলোড করছেন তার দায়িত্ব আপনার। পাঠানোর মাধ্যমে আপনি নিশ্চিত করছেন যে এটি Mana Poster নিয়ম ও কমিউনিটি নির্দেশিকা মেনে চলছে।',
  },
  AppLanguage.konkani: <String, String>{
    'Check review rules before submitting your content.':
        'सामग्री धाडचे पयलीं तपासणी नियम वाचात.',
    'Community Upload Instructions': 'समुदाय अपलोड सूचना',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'तुमचो सुविचार, मजकूर वा सुविचाराचो फोटो Mana Poster तपासणी टीमक धाडात.',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'तुमी अपलोड केल्ल्या सामग्रीची जबाबदारी तुमची. धाडल्यार ती Mana Poster नियम आनी समुदाय मार्गदर्शक तत्त्वां प्रमाणें आसा हाची खात्री तुमी दिता.',
  },
  AppLanguage.meitei: <String, String>{
    'Check review rules before submitting your content.':
        'ꯀꯟꯇꯦꯟꯇ ꯊꯥꯕꯒꯤ ꯃꯃꯥꯡꯗ ꯌꯦꯡꯁꯤꯟ ꯅꯤꯌꯝꯁꯤꯡ ꯌꯦꯡꯕꯤꯌꯨ।',
    'Community Upload Instructions': 'ꯀꯝꯌꯨꯅꯤꯇꯤ ꯑꯄꯂꯣꯗ ꯋꯥꯌꯦꯜ',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'ꯅꯍꯥꯛꯀꯤ ꯋꯥꯍꯩ, ꯇꯦꯛꯁꯇ ꯅꯠꯠꯔꯒꯥ ꯋꯥꯍꯩ ꯐꯣꯇꯣ Mana Poster ꯌꯦꯡꯁꯤꯟ ꯇꯤꯝꯗ ꯊꯥꯕꯤꯌꯨ।',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'ꯅꯍꯥꯛꯅ ꯊꯥꯕ ꯀꯟꯇꯦꯟꯇꯀꯤ ꯃꯁꯤꯡ ꯅꯍꯥꯛꯀꯤ ꯃꯊꯧꯅꯤ। ꯊꯥꯕꯗꯨꯅ ꯃꯁꯤ Mana Poster ꯅꯤꯌꯝ ꯑꯃꯁꯨꯡ ꯀꯝꯌꯨꯅꯤꯇꯤ ꯒꯥꯏꯗꯂꯥꯏꯟ ꯏꯅꯕꯅꯤ ꯍꯥꯌꯕ ꯅꯍꯥꯛꯅ ꯌꯥꯏꯐꯕꯤ।',
  },
  AppLanguage.mizo: <String, String>{
    'Check review rules before submitting your content.':
        'Content i thawn hmain review dan te en rawh.',
    'Community Upload Instructions': 'Community Upload Kaihhruaina',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'I quote, text, emaw quote thlalak chu Mana Poster review team hnenah thawn rawh.',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'I upload content chungchangah nangmah i mawhphurh. I thawn chuan Mana Poster terms leh community guidelines i zawm tih i nemnghet a ni.',
  },
  AppLanguage.nepali: <String, String>{
    'Check review rules before submitting your content.':
        'सामग्री पठाउनु अघि समीक्षा नियमहरू पढ्नुहोस्।',
    'Community Upload Instructions': 'समुदाय अपलोड निर्देशन',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'आफ्नो उद्धरण, पाठ वा उद्धरण भएको फोटो Mana Poster समीक्षा टोलीलाई पठाउनुहोस्।',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'तपाईंले अपलोड गरेको सामग्रीको जिम्मेवारी तपाईंको हो। पठाउँदा तपाईंले यो Mana Poster का नियम र समुदाय दिशानिर्देशअनुसार छ भनी पुष्टि गर्नुहुन्छ।',
  },
  AppLanguage.kashmiri: <String, String>{
    'Check review rules before submitting your content.':
        'مواد بھیزنہٕ برونہہ جائزہ ضابطہ چیک کریو۔',
    'Community Upload Instructions': 'Ú©Ù…ÛŒÙˆÙ†Ù¹ÛŒ Ø§Ù¾Ù„ÙˆÚˆ ÛØ¯Ø§ÛŒØ§Øª',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'پنن قول، متن یا قول والی تصویر Mana Poster جائزہ ٹیمس بھیزو۔',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'تہندۍ اپلوڈ کردٕ موادس خٲطرٕ تہیہ ذمہ دار چھو۔ بھیزنٕ سٕتۍ تہیہ تصدیق کران چھو ز یہٕ Mana Poster شرطٕ تٕ کمیونٹی ہدایاتن مطابق چھ۔',
  },
  AppLanguage.ladakhi: <String, String>{
    'Check review rules before submitting your content.':
        'ནང་དོན་སྐུར་གོང་ཞིབ་བཤེར་སྒྲིག་གཞི་ལྟ་རོགས།',
    'Community Upload Instructions': 'སྤྱི་ཚོགས་ནང་སྐུར་སྟངས་ཀྱི་ལམ་སྟོན',
    'Send your quote, text, or quote image to the Mana Poster review team.':
        'ཁྱེད་ཀྱི་ཚིག་བརྗོད། ཡི་གེ། ཡང་ན་ཚིག་བརྗོད་ཡོད་པའི་པར་ Mana Poster ཞིབ་བཤེར་ཚོགས་པར་སྐུར་རོགས།',
    'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.':
        'ཁྱེད་རང་གིས་སྐུར་བའི་ནང་དོན་ལ་ཁྱེད་རང་འགན་འཁུར་དགོས། སྐུར་བའི་སྐབས་སུ་དེ་ Mana Poster སྒྲིག་གཞི་དང་སྤྱི་ཚོགས་ལམ་སྟོན་ལ་མཐུན་པ་ཡིན་པ་ཁྱེད་རང་གིས་ངེས་བརྟན་བྱེད།',
  },
};

const Map<AppLanguage, Map<String, String>>
_regionalExtraFallbacks = <AppLanguage, Map<String, String>>{
  AppLanguage.assamese: <String, String>{
    'A few permissions are needed': 'কিছুমান অনুমতি প্ৰয়োজন',
    'About App': 'এপৰ বিষয়ে',
    'Account': 'একাউণ্ট',
    'Allow': 'অনুমতি দিয়ক',
    'App details and version info': 'এপৰ বিৱৰণ আৰু সংস্কৰণৰ তথ্য',
    'App Settings': 'এপ ছেটিংছ',
    'Buy': 'কিনক',
    'Choose your app language': 'আপোনাৰ এপৰ ভাষা বাছক',
    'Control alerts and updates': 'সতৰ্কবাণী আৰু আপডেট নিয়ন্ত্ৰণ কৰক',
    'Current language': 'বৰ্তমান ভাষা',
    'Enter valid email': 'সঠিক ইমেইল দিয়ক',
    'Get help and contact support': 'সহায় লওক আৰু সমৰ্থনৰ সৈতে যোগাযোগ কৰক',
    'Help & Support': 'সহায় আৰু সমৰ্থন',
    'Language Settings': 'ভাষা ছেটিংছ',
    'Later': 'পিছত',
    'Manage current plan and upgrades':
        'বৰ্তমান প্লেন আৰু আপগ্ৰেড নিয়ন্ত্ৰণ কৰক',
    'Minimum 6 characters required': 'কমেও ৬টা আখৰ প্ৰয়োজন',
    'Notifications': 'জাননীসমূহ',
    'Password reset will be available soon.':
        'পাছৱৰ্ড ৰিছেট শীঘ্ৰে উপলব্ধ হ’ব।',
    'Photos, storage and other access': 'ফটো, সংৰক্ষণ আৰু আন প্ৰৱেশাধিকাৰ',
    'Photos/Gallery': 'ফটো / গেলাৰী',
    'Ready': 'সাজু',
    'Save / Apply': 'সংৰক্ষণ / প্ৰয়োগ',
    'Share WhatsApp': 'WhatsAppত শ্বেয়াৰ কৰক',
    'Sign out logic can be connected later':
        'ছাইন আউট ব্যৱস্থা পাছত সংযোগ কৰিব পাৰি',
    'Special': 'বিশেষ',
    'Subscription': 'চাবস্ক্ৰিপচন',
    'Support': 'সমৰ্থন',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai লৈ স্বাগতম',
  },
  AppLanguage.konkani: <String, String>{
    'A few permissions are needed': 'कांय अनुमती गरजेची आसात',
    'About App': 'ऍप विशीं',
    'Account': 'खातें',
    'Allow': 'परवानगी दियात',
    'App details and version info': 'ऍप तपशील आनी आवृत्ती माहिती',
    'App Settings': 'ऍप सेटिंग्स',
    'Buy': 'विकत घेवप',
    'Choose your app language': 'तुमची ऍप भास निवडात',
    'Control alerts and updates': 'सूचना आनी अपडेट नियंत्रण करात',
    'Current language': 'सध्याची भास',
    'Enter valid email': 'वैध ईमेल दियात',
    'Get help and contact support': 'मदत घेवची आनी सपोर्टाक संपर्क करात',
    'Help & Support': 'मदत आनी सपोर्ट',
    'Language Settings': 'भास सेटिंग्स',
    'Later': 'उपरांत',
    'Manage current plan and upgrades': 'सध्याचो प्लॅन आनी अपग्रेड सांभाळात',
    'Minimum 6 characters required': 'किमान ६ अक्षरां गरजेची',
    'Notifications': 'सूचना',
    'Password reset will be available soon.':
        'पासवर्ड रीसेट लवकरच उपलब्ध जातलो.',
    'Photos, storage and other access': 'फोटो, स्टोरेज आनी हेर प्रवेश',
    'Photos/Gallery': 'फोटो / गॅलरी',
    'Ready': 'तयार',
    'Save / Apply': 'सेव्ह / लागू करात',
    'Share WhatsApp': 'WhatsApp चेर शेअर करात',
    'Sign out logic can be connected later':
        'साइन आउट व्यवस्था उपरांत जोडूं शकता',
    'Special': 'खास',
    'Subscription': 'सदस्यता',
    'Support': 'सपोर्ट',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai क स्वागत',
  },
  AppLanguage.gujarati: <String, String>{
    'A few permissions are needed': 'થોડી પરવાનગીઓ જરૂરી છે',
    'About App': 'એપ વિશે',
    'Account': 'એકાઉન્ટ',
    'Allow': 'મંજૂરી આપો',
    'App details and version info': 'એપ વિગતો અને વર્ઝન માહિતી',
    'App Settings': 'એપ સેટિંગ્સ',
    'Buy': 'ખરીદો',
    'Choose your app language': 'તમારી એપ ભાષા પસંદ કરો',
    'Control alerts and updates': 'ચેતવણીઓ અને અપડેટ્સ નિયંત્રિત કરો',
    'Current language': 'હાલની ભાષા',
    'Enter valid email': 'માન્ય ઈમેલ દાખલ કરો',
    'Get help and contact support': 'મદદ મેળવો અને સપોર્ટનો સંપર્ક કરો',
    'Help & Support': 'મદદ અને સપોર્ટ',
    'Language Settings': 'ભાષા સેટિંગ્સ',
    'Later': 'પછી',
    'Manage current plan and upgrades': 'હાલનો પ્લાન અને અપગ્રેડ મેનેજ કરો',
    'Minimum 6 characters required': 'ઓછામાં ઓછા ૬ અક્ષરો જરૂરી છે',
    'Notifications': 'સૂચનાઓ',
    'Password reset will be available soon.':
        'પાસવર્ડ રીસેટ ટૂંક સમયમાં ઉપલબ્ધ થશે.',
    'Photos, storage and other access': 'ફોટા, સ્ટોરેજ અને અન્ય ઍક્સેસ',
    'Photos/Gallery': 'ફોટા / ગેલેરી',
    'Ready': 'તૈયાર',
    'Save / Apply': 'સાચવો / લાગુ કરો',
    'Share WhatsApp': 'WhatsApp પર શેર કરો',
    'Sign out logic can be connected later':
        'સાઇન આઉટ વ્યવસ્થા પછી જોડાઈ શકે છે',
    'Special': 'ખાસ',
    'Subscription': 'સબ્સ્ક્રિપ્શન',
    'Support': 'સપોર્ટ',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai માં આપનું સ્વાગત છે',
  },
  AppLanguage.marathi: <String, String>{
    'A few permissions are needed': 'काही परवानग्या आवश्यक आहेत',
    'About App': 'अ‍ॅप बद्दल',
    'Account': 'खाते',
    'Allow': 'परवानगी द्या',
    'App details and version info': 'अ‍ॅप तपशील आणि आवृत्ती माहिती',
    'App Settings': 'अ‍ॅप सेटिंग्ज',
    'Buy': 'खरेदी करा',
    'Choose your app language': 'तुमची अ‍ॅप भाषा निवडा',
    'Control alerts and updates': 'सूचना आणि अपडेट्स नियंत्रित करा',
    'Current language': 'सध्याची भाषा',
    'Enter valid email': 'वैध ईमेल टाका',
    'Get help and contact support': 'मदत घ्या आणि सपोर्टशी संपर्क करा',
    'Help & Support': 'मदत आणि सपोर्ट',
    'Language Settings': 'भाषा सेटिंग्ज',
    'Later': 'नंतर',
    'Manage current plan and upgrades':
        'सध्याचा प्लॅन आणि अपग्रेड्स व्यवस्थापित करा',
    'Minimum 6 characters required': 'किमान ६ अक्षरे आवश्यक आहेत',
    'Notifications': 'सूचना',
    'Password reset will be available soon.':
        'पासवर्ड रीसेट लवकरच उपलब्ध होईल.',
    'Photos, storage and other access': 'फोटो, स्टोरेज आणि इतर प्रवेश',
    'Photos/Gallery': 'फोटो / गॅलरी',
    'Ready': 'तयार',
    'Save / Apply': 'जतन करा / लागू करा',
    'Share WhatsApp': 'WhatsApp वर शेअर करा',
    'Sign out logic can be connected later':
        'साइन आउट व्यवस्था नंतर जोडता येईल',
    'Special': 'विशेष',
    'Subscription': 'सदस्यता',
    'Support': 'सपोर्ट',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai मध्ये स्वागत',
  },
  AppLanguage.meitei: <String, String>{
    'A few permissions are needed': 'খরা অনুমতি দরকার অই',
    'About App': 'এপকী মরমদা',
    'Account': 'একাউন্ট',
    'Allow': 'অনুমতি পীয়ু',
    'App details and version info': 'এপকী মচাক অমসুং ভার্সনগী তথ্য',
    'App Settings': 'এপ সেটিংস',
    'Buy': 'লৌবিয়ু',
    'Choose your app language': 'নহাক্কী এপ লোল খনবিয়ু',
    'Control alerts and updates': 'এলার্ট অমসুং আপডেট কন্ট্রোল তৌবিয়ু',
    'Current language': 'হৌজিক্কী লোল',
    'Enter valid email': 'চুম্বা ইমেইল পীবিয়ু',
    'Get help and contact support': 'মতেং লৌবিয়ু অমসুং সাপোর্টদা পাও ফাওবিয়ু',
    'Help & Support': 'মতেং অমসুং সাপোর্ট',
    'Language Settings': 'লোল সেটিংস',
    'Later': 'তুংদা',
    'Manage current plan and upgrades':
        'হৌজিক্কী প্লান অমসুং আপগ্রেড মেনেজ তৌবিয়ু',
    'Minimum 6 characters required': 'অচমবা ৬ character দরকার',
    'Notifications': 'নোটিফিকেশনশিং',
    'Password reset will be available soon.': 'পাসৱার্ড রিসেট থুনা ফংগনি।',
    'Photos, storage and other access': 'ফোটো, স্টোরেজ অমসুং অতোপ্পা এক্সেস',
    'Photos/Gallery': 'ফোটো / গ্যালারি',
    'Ready': 'রেডি',
    'Save / Apply': 'সেভ / এপ্লাই',
    'Share WhatsApp': 'WhatsApp দা শেয়ার তৌবিয়ু',
    'Sign out logic can be connected later':
        'সাইন আউট ব্যবস্থা তুংদা কানেক্ট তৌবা যায়',
    'Special': 'অখন্নবা',
    'Subscription': 'সাবস্ক্রিপশন',
    'Support': 'সাপোর্ট',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai দা তরাম্না অকৌবা',
  },
  AppLanguage.mizo: <String, String>{
    'A few permissions are needed': 'Permission thenkhat a ngai',
    'About App': 'App chungchang',
    'Account': 'Account',
    'Allow': 'Phal',
    'App details and version info': 'App details leh version info',
    'App Settings': 'App settings',
    'Buy': 'Lei',
    'Choose your app language': 'I app tawng thlang rawh',
    'Control alerts and updates': 'Alerts leh updates control rawh',
    'Current language': 'Tuna tawng',
    'Enter valid email': 'Email dik tak ziak rawh',
    'Get help and contact support': 'Tanpuina la la, support biak rawh',
    'Help & Support': 'Tanpuina leh support',
    'Language Settings': 'Tawng settings',
    'Later': 'Nakinah',
    'Manage current plan and upgrades': 'Tuna plan leh upgrades enkawl rawh',
    'Minimum 6 characters required': 'Character 6 tal a ngai',
    'Notifications': 'Notifications',
    'Password reset will be available soon.':
        'Password reset chu rei lo teah a awm ang.',
    'Photos, storage and other access': 'Photos, storage leh access dangte',
    'Photos/Gallery': 'Photos / Gallery',
    'Ready': 'Ready',
    'Save / Apply': 'Save / Apply',
    'Share WhatsApp': 'WhatsApp-ah share rawh',
    'Sign out logic can be connected later':
        'Sign out system chu nakinah connect theih a ni',
    'Special': 'Special',
    'Subscription': 'Subscription',
    'Support': 'Support',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai-ah kan lo lawm a che',
  },
  AppLanguage.odia: <String, String>{
    'A few permissions are needed': 'କିଛି ଅନୁମତି ଆବଶ୍ୟକ',
    'About App': 'ଆପ୍ ବିଷୟରେ',
    'Account': 'ଆକାଉଣ୍ଟ',
    'Allow': 'ଅନୁମତି ଦିଅନ୍ତୁ',
    'App details and version info': 'ଆପ୍ ବିବରଣୀ ଏବଂ ଭର୍ସନ ସୂଚନା',
    'App Settings': 'ଆପ୍ ସେଟିଂସ୍',
    'Buy': 'କିଣନ୍ତୁ',
    'Choose your app language': 'ଆପଣଙ୍କ ଆପ୍ ଭାଷା ବାଛନ୍ତୁ',
    'Control alerts and updates': 'ସତର୍କତା ଏବଂ ଅପଡେଟ୍ ନିୟନ୍ତ୍ରଣ କରନ୍ତୁ',
    'Current language': 'ବର୍ତ୍ତମାନ ଭାଷା',
    'Enter valid email': 'ଠିକ୍ ଇମେଲ୍ ଦିଅନ୍ତୁ',
    'Get help and contact support':
        'ସହାୟତା ନିଅନ୍ତୁ ଏବଂ ସପୋର୍ଟ ସହିତ ଯୋଗାଯୋଗ କରନ୍ତୁ',
    'Help & Support': 'ସହାୟତା ଏବଂ ସପୋର୍ଟ',
    'Language Settings': 'ଭାଷା ସେଟିଂସ୍',
    'Later': 'ପରେ',
    'Manage current plan and upgrades':
        'ବର୍ତ୍ତମାନ ପ୍ଲାନ୍ ଏବଂ ଅପଗ୍ରେଡ୍ ପରିଚାଳନା କରନ୍ତୁ',
    'Minimum 6 characters required': 'କମରେ କମ ୬ଟି ଅକ୍ଷର ଆବଶ୍ୟକ',
    'Notifications': 'ସୂଚନା',
    'Password reset will be available soon.':
        'ପାସୱାର୍ଡ ରିସେଟ୍ ଶୀଘ୍ର ଉପଲବ୍ଧ ହେବ।',
    'Photos, storage and other access': 'ଫଟୋ, ଷ୍ଟୋରେଜ୍ ଏବଂ ଅନ୍ୟ ଆକ୍ସେସ୍',
    'Photos/Gallery': 'ଫଟୋ / ଗ୍ୟାଲେରୀ',
    'Ready': 'ପ୍ରସ୍ତୁତ',
    'Save / Apply': 'ସେଭ୍ / ପ୍ରୟୋଗ',
    'Share WhatsApp': 'WhatsApp ରେ ସେୟାର୍ କରନ୍ତୁ',
    'Sign out logic can be connected later':
        'ସାଇନ୍ ଆଉଟ୍ ବ୍ୟବସ୍ଥା ପରେ ଯୋଡାଯାଇପାରିବ',
    'Special': 'ବିଶେଷ',
    'Subscription': 'ସବସ୍କ୍ରିପସନ୍',
    'Support': 'ସପୋର୍ଟ',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai କୁ ସ୍ୱାଗତ',
  },
  AppLanguage.punjabi: <String, String>{
    'A few permissions are needed': 'ਕੁਝ ਇਜਾਜ਼ਤਾਂ ਦੀ ਲੋੜ ਹੈ',
    'About App': 'ਐਪ ਬਾਰੇ',
    'Account': 'ਖਾਤਾ',
    'Allow': 'ਇਜਾਜ਼ਤ ਦਿਓ',
    'App details and version info': 'ਐਪ ਵੇਰਵੇ ਅਤੇ ਵਰਜਨ ਜਾਣਕਾਰੀ',
    'App Settings': 'ਐਪ ਸੈਟਿੰਗਾਂ',
    'Buy': 'ਖਰੀਦੋ',
    'Choose your app language': 'ਆਪਣੀ ਐਪ ਭਾਸ਼ਾ ਚੁਣੋ',
    'Control alerts and updates': 'ਅਲਰਟ ਅਤੇ ਅਪਡੇਟ ਕੰਟਰੋਲ ਕਰੋ',
    'Current language': 'ਮੌਜੂਦਾ ਭਾਸ਼ਾ',
    'Enter valid email': 'ਸਹੀ ਈਮੇਲ ਦਰਜ ਕਰੋ',
    'Get help and contact support': 'ਮਦਦ ਲਵੋ ਅਤੇ ਸਪੋਰਟ ਨਾਲ ਸੰਪਰਕ ਕਰੋ',
    'Help & Support': 'ਮਦਦ ਅਤੇ ਸਪੋਰਟ',
    'Language Settings': 'ਭਾਸ਼ਾ ਸੈਟਿੰਗਾਂ',
    'Later': 'ਬਾਅਦ ਵਿੱਚ',
    'Manage current plan and upgrades': 'ਮੌਜੂਦਾ ਪਲਾਨ ਅਤੇ ਅਪਗ੍ਰੇਡ ਮੈਨੇਜ ਕਰੋ',
    'Minimum 6 characters required': 'ਘੱਟੋ-ਘੱਟ ੬ ਅੱਖਰ ਲੋੜੀਂਦੇ ਹਨ',
    'Notifications': 'ਸੂਚਨਾਵਾਂ',
    'Password reset will be available soon.': 'ਪਾਸਵਰਡ ਰੀਸੈਟ ਜਲਦੀ ਉਪਲਬਧ ਹੋਵੇਗਾ।',
    'Photos, storage and other access': 'ਫੋਟੋਆਂ, ਸਟੋਰੇਜ ਅਤੇ ਹੋਰ ਪਹੁੰਚ',
    'Photos/Gallery': 'ਫੋਟੋਆਂ / ਗੈਲਰੀ',
    'Ready': 'ਤਿਆਰ',
    'Save / Apply': 'ਸੇਵ / ਲਾਗੂ ਕਰੋ',
    'Share WhatsApp': 'WhatsApp ਤੇ ਸ਼ੇਅਰ ਕਰੋ',
    'Sign out logic can be connected later':
        'ਸਾਈਨ ਆਉਟ ਪ੍ਰਬੰਧ ਬਾਅਦ ਵਿੱਚ ਜੋੜਿਆ ਜਾ ਸਕਦਾ ਹੈ',
    'Special': 'ਖਾਸ',
    'Subscription': 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ',
    'Support': 'ਸਪੋਰਟ',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai ਵਿੱਚ ਸੁਆਗਤ ਹੈ',
  },
  AppLanguage.nepali: <String, String>{
    'A few permissions are needed': 'केही अनुमतिहरू आवश्यक छन्',
    'About App': 'एपको बारेमा',
    'Account': 'खाता',
    'Allow': 'अनुमति दिनुहोस्',
    'App details and version info': 'एप विवरण र संस्करण जानकारी',
    'App Settings': 'एप सेटिङहरू',
    'Buy': 'किन्नुहोस्',
    'Choose your app language': 'आफ्नो एप भाषा छान्नुहोस्',
    'Control alerts and updates': 'सूचना र अपडेट नियन्त्रण गर्नुहोस्',
    'Current language': 'हालको भाषा',
    'Enter valid email': 'मान्य इमेल लेख्नुहोस्',
    'Get help and contact support':
        'मद्दत लिनुहोस् र सपोर्टमा सम्पर्क गर्नुहोस्',
    'Help & Support': 'मद्दत र सपोर्ट',
    'Language Settings': 'भाषा सेटिङहरू',
    'Later': 'पछि',
    'Manage current plan and upgrades':
        'हालको प्लान र अपग्रेड व्यवस्थापन गर्नुहोस्',
    'Minimum 6 characters required': 'कम्तीमा ६ अक्षर आवश्यक छ',
    'Notifications': 'सूचनाहरू',
    'Password reset will be available soon.':
        'पासवर्ड रिसेट छिट्टै उपलब्ध हुनेछ।',
    'Photos, storage and other access': 'फोटो, स्टोरेज र अन्य पहुँच',
    'Photos/Gallery': 'फोटो / ग्यालरी',
    'Ready': 'तयार',
    'Save / Apply': 'सेभ / लागू गर्नुहोस्',
    'Share WhatsApp': 'WhatsApp मा शेयर गर्नुहोस्',
    'Sign out logic can be connected later':
        'साइन आउट व्यवस्था पछि जोड्न सकिन्छ',
    'Special': 'विशेष',
    'Subscription': 'सदस्यता',
    'Support': 'सपोर्ट',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai मा स्वागत छ',
  },
  AppLanguage.bengali: <String, String>{
    'A few permissions are needed': 'কিছু অনুমতি প্রয়োজন',
    'About App': 'অ্যাপ সম্পর্কে',
    'Account': 'অ্যাকাউন্ট',
    'Allow': 'অনুমতি দিন',
    'App details and version info': 'অ্যাপের বিবরণ ও সংস্করণ তথ্য',
    'App Settings': 'অ্যাপ সেটিংস',
    'Buy': 'কিনুন',
    'Choose your app language': 'আপনার অ্যাপের ভাষা বেছে নিন',
    'Control alerts and updates': 'সতর্কতা ও আপডেট নিয়ন্ত্রণ করুন',
    'Current language': 'বর্তমান ভাষা',
    'Enter valid email': 'সঠিক ইমেল লিখুন',
    'Get help and contact support': 'সহায়তা নিন এবং সাপোর্টে যোগাযোগ করুন',
    'Help & Support': 'সহায়তা ও সাপোর্ট',
    'Language Settings': 'ভাষা সেটিংস',
    'Later': 'পরে',
    'Manage current plan and upgrades':
        'বর্তমান প্ল্যান ও আপগ্রেড পরিচালনা করুন',
    'Minimum 6 characters required': 'কমপক্ষে ৬টি অক্ষর প্রয়োজন',
    'Notifications': 'নোটিফিকেশন',
    'Password reset will be available soon.':
        'পাসওয়ার্ড রিসেট শীঘ্রই পাওয়া যাবে।',
    'Photos, storage and other access': 'ফটো, স্টোরেজ এবং অন্যান্য অ্যাক্সেস',
    'Photos/Gallery': 'ফটো / গ্যালারি',
    'Ready': 'প্রস্তুত',
    'Save / Apply': 'সেভ / প্রয়োগ',
    'Share WhatsApp': 'WhatsApp-এ শেয়ার করুন',
    'Sign out logic can be connected later':
        'সাইন আউট ব্যবস্থা পরে যুক্ত করা যাবে',
    'Special': 'বিশেষ',
    'Subscription': 'সাবস্ক্রিপশন',
    'Support': 'সাপোর্ট',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai-এ স্বাগতম',
  },
  AppLanguage.kashmiri: <String, String>{
    'A few permissions are needed': 'کچھ اجازتیں ضروری ہیں',
    'About App': 'Ø§ÛŒÙ¾ Ú©Û’ Ø¨Ø§Ø±Û’ Ù…ÛŒÚº',
    'Account': 'اکاؤنٹ',
    'Allow': 'اجازت دیں',
    'App details and version info':
        'Ø§ÛŒÙ¾ Ú©ÛŒ ØªÙØµÛŒÙ„ Ø§ÙˆØ± ÙˆØ±Ú˜Ù† Ù…Ø¹Ù„ÙˆÙ…Ø§Øª',
    'App Settings': 'ایپ سیٹنگز',
    'Buy': 'خریدیں',
    'Choose your app language': 'اپنی ایپ زبان منتخب کریں',
    'Control alerts and updates':
        'Ø§Ù„Ø±Ù¹Ø³ Ø§ÙˆØ± Ø§Ù¾ ÚˆÛŒÙ¹Ø³ Ú©Ù†Ù¹Ø±ÙˆÙ„ Ú©Ø±ÛŒÚº',
    'Current language': 'موجودہ زبان',
    'Enter valid email': 'Ø¯Ø±Ø³Øª Ø§ÛŒ Ù…ÛŒÙ„ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº',
    'Get help and contact support':
        'Ù…Ø¯Ø¯ Ø­Ø§ØµÙ„ Ú©Ø±ÛŒÚº Ø§ÙˆØ± Ø³Ù¾ÙˆØ±Ù¹ Ø³Û’ Ø±Ø§Ø¨Ø·Û Ú©Ø±ÛŒÚº',
    'Help & Support': 'Ù…Ø¯Ø¯ Ø§ÙˆØ± Ø³Ù¾ÙˆØ±Ù¹',
    'Language Settings': 'زبان کی سیٹنگز',
    'Later': 'Ø¨Ø¹Ø¯ Ù…ÛŒÚº',
    'Manage current plan and upgrades':
        'موجودہ پلان اور اپ گریڈز کا انتظام کریں',
    'Minimum 6 characters required': 'کم از کم ۶ حروف ضروری ہیں',
    'Notifications': 'Ø§Ø·Ù„Ø§Ø¹Ø§Øª',
    'Password reset will be available soon.':
        'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø±ÛŒ Ø³ÛŒÙ¹ Ø¬Ù„Ø¯ Ø¯Ø³ØªÛŒØ§Ø¨ ÛÙˆÚ¯Ø§Û”',
    'Photos, storage and other access': 'فوٹوز، اسٹوریج اور دیگر رسائی',
    'Photos/Gallery': 'فوٹوز / گیلری',
    'Ready': 'ØªÛŒØ§Ø±',
    'Save / Apply': 'Ù…Ø­ÙÙˆØ¸ / Ù„Ø§Ú¯Ùˆ Ú©Ø±ÛŒÚº',
    'Share WhatsApp': 'WhatsApp پر شیئر کریں',
    'Sign out logic can be connected later':
        'سائن آؤٹ نظام بعد میں جوڑا جا سکتا ہے',
    'Special': 'خاص',
    'Subscription': 'سبسکرپشن',
    'Support': 'Ø³Ù¾ÙˆØ±Ù¹',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai میں خوش آمدید',
  },
  AppLanguage.ladakhi: <String, String>{
    'A few permissions are needed': 'Permission ཁ་ཤས་དགོས།',
    'About App': 'App སྐོར།',
    'Account': 'Account',
    'Allow': 'ཆོག',
    'App details and version info': 'App details དང version info',
    'App Settings': 'App settings',
    'Buy': 'ཉོ',
    'Choose your app language': 'App language འདེམས།',
    'Control alerts and updates': 'Alerts དང updates སྟངས་འཛིན།',
    'Current language': 'ད་ལྟའི language',
    'Enter valid email': 'Valid email འཇུག',
    'Get help and contact support': 'Help ལེན། support ལ་འབྲེལ།',
    'Help & Support': 'Help & Support',
    'Language Settings': 'Language settings',
    'Later': 'རྗེས་ལ',
    'Manage current plan and upgrades': 'Current plan དང upgrades སྟངས་འཛིན།',
    'Minimum 6 characters required': 'Character 6 ཉུང་མཐའ་དགོས།',
    'Notifications': 'Notifications',
    'Password reset will be available soon.':
        'Password reset མགྱོགས་པོར་ཡོང་རྒྱུ།',
    'Photos, storage and other access': 'Photos, storage དང access གཞན།',
    'Photos/Gallery': 'Photos / Gallery',
    'Ready': 'Ready',
    'Save / Apply': 'Save / Apply',
    'Share WhatsApp': 'WhatsApp ནང share',
    'Sign out logic can be connected later':
        'Sign out system རྗེས་ལ connect བྱེད་ཆོག',
    'Special': 'Special',
    'Subscription': 'Subscription',
    'Support': 'Support',
    'Welcome to Mana Poster Ai': 'Mana Poster Ai-la julley',
  },
};

const Map<AppLanguage, Map<String, String>>
_regionalProfileFallbacks = <AppLanguage, Map<String, String>>{
  AppLanguage.assamese: <String, String>{
    'Quick actions': 'দ্ৰুত বিকল্প',
    'More': 'অধিক',
    'Remaining options': 'বাকী বিকল্পসমূহ',
    'Change State / UT': 'ৰাজ্য / কেন্দ্ৰীয় শাসিত অঞ্চল সলনি কৰক',
    'Update app language and state categories':
        'এপৰ ভাষা আৰু ৰাজ্যৰ কেটেগৰী আপডেট কৰক',
    'Political parties': 'ৰাজনৈতিক দলসমূহ',
    'Update political party categories shown in home':
        'হোমত দেখা ৰাজনৈতিক দলৰ কেটেগৰী আপডেট কৰক',
    'Change religion': 'ধৰ্ম সলনি কৰক',
    'Update which categories appear in home':
        'হোমত কোনবোৰ কেটেগৰী দেখাব আপডেট কৰক',
    'Location-based status': 'স্থানভিত্তিক ষ্টেটাছ',
    'View plan details': 'প্লেনৰ বিৱৰণ চাওক',
    'Referral rewards': 'ৰেফাৰেল পুৰস্কাৰ',
    'Restore subscriptions': 'চাবস্ক্ৰিপচন পুনৰুদ্ধাৰ কৰক',
    'Share App': 'এপ শ্বেয়াৰ কৰক',
    'Report a poster or issue': 'পোষ্টাৰ বা সমস্যা ৰিপোৰ্ট কৰক',
    'Delete account': 'একাউণ্ট ডিলিট কৰক',
    'Privacy Policy': 'গোপনীয়তা নীতি',
    'Ad privacy choices': 'বিজ্ঞাপন গোপনীয়তা বিকল্প',
    'Terms & Conditions': 'নিয়ম আৰু চৰ্তসমূহ',
  },
  AppLanguage.konkani: <String, String>{
    'Quick actions': 'वेगळीं कृतीं',
    'More': 'आनीक',
    'Remaining options': 'उरिल्लीं पर्याय',
    'Change State / UT': 'राज्य / केंद्रशासित प्रदेश बदलात',
    'Update app language and state categories':
        'ऍप भास आनी राज्य कॅटेगरी अपडेट करात',
    'Political parties': 'राजकीय पक्ष',
    'Update political party categories shown in home':
        'होमांत दिसपी पक्ष कॅटेगरी अपडेट करात',
    'Change religion': 'धर्म बदलात',
    'Update which categories appear in home': 'होमांत दिसपी कॅटेगरी अपडेट करात',
    'Location-based status': 'स्थानाचेर आधारित स्टेटस',
    'View plan details': 'प्लॅन तपशील पळयात',
    'Referral rewards': 'रेफरल बक्षिसां',
    'Restore subscriptions': 'सदस्यता रिस्टोर करात',
    'Share App': 'ऍप शेअर करात',
    'Report a poster or issue': 'पोस्टर वा समस्या रिपोर्ट करात',
    'Delete account': 'खातें डिलीट करात',
    'Privacy Policy': 'गोपनीयता धोरण',
    'Ad privacy choices': 'जाहिरात गोपनीयता पर्याय',
    'Terms & Conditions': 'नियम आनी अटी',
  },
  AppLanguage.gujarati: <String, String>{
    'Quick actions': 'ઝડપી વિકલ્પો',
    'More': 'વધુ',
    'Remaining options': 'બાકી વિકલ્પો',
    'Change State / UT': 'રાજ્ય / કેન્દ્રશાસિત પ્રદેશ બદલો',
    'Update app language and state categories':
        'એપ ભાષા અને રાજ્ય કેટેગરી અપડેટ કરો',
    'Political parties': 'રાજકીય પક્ષો',
    'Update political party categories shown in home':
        'હોમમાં દેખાતી પક્ષ કેટેગરી અપડેટ કરો',
    'Change religion': 'ધર્મ બદલો',
    'Update which categories appear in home': 'હોમમાં દેખાતી કેટેગરી અપડેટ કરો',
    'Location-based status': 'સ્થાન આધારિત સ્ટેટસ',
    'View plan details': 'પ્લાન વિગતો જુઓ',
    'Referral rewards': 'રેફરલ રિવોર્ડ્સ',
    'Restore subscriptions': 'સબ્સ્ક્રિપ્શન રિસ્ટોર કરો',
    'Share App': 'એપ શેર કરો',
    'Report a poster or issue': 'પોસ્ટર અથવા સમસ્યા રિપોર્ટ કરો',
    'Delete account': 'એકાઉન્ટ ડિલીટ કરો',
    'Privacy Policy': 'પ્રાઇવસી પોલિસી',
    'Ad privacy choices': 'જાહેરાત પ્રાઇવસી વિકલ્પો',
    'Terms & Conditions': 'નિયમો અને શરતો',
  },
  AppLanguage.marathi: <String, String>{
    'Quick actions': 'झटपट पर्याय',
    'More': 'अधिक',
    'Remaining options': 'उरलेले पर्याय',
    'Change State / UT': 'राज्य / केंद्रशासित प्रदेश बदला',
    'Update app language and state categories':
        'अ‍ॅप भाषा आणि राज्य कॅटेगरी अपडेट करा',
    'Political parties': 'राजकीय पक्ष',
    'Update political party categories shown in home':
        'होममध्ये दिसणाऱ्या पक्ष कॅटेगरी अपडेट करा',
    'Change religion': 'धर्म बदला',
    'Update which categories appear in home':
        'होममध्ये दिसणाऱ्या कॅटेगरी अपडेट करा',
    'Location-based status': 'स्थानावर आधारित स्टेटस',
    'View plan details': 'प्लॅन तपशील पहा',
    'Referral rewards': 'रेफरल बक्षिसे',
    'Restore subscriptions': 'सदस्यता रिस्टोर करा',
    'Share App': 'अ‍ॅप शेअर करा',
    'Report a poster or issue': 'पोस्टर किंवा समस्या रिपोर्ट करा',
    'Delete account': 'खाते डिलीट करा',
    'Privacy Policy': 'गोपनीयता धोरण',
    'Ad privacy choices': 'जाहिरात गोपनीयता पर्याय',
    'Terms & Conditions': 'नियम आणि अटी',
  },
  AppLanguage.meitei: <String, String>{
    'Quick actions': 'থুনা তৌবা অপশনশিং',
    'More': 'হেন্না',
    'Remaining options': 'লৈরিবা অপশনশিং',
    'Change State / UT': 'স্টেট / UT হোংদোকউ',
    'Update app language and state categories':
        'এপ লোল অমসুং স্টেট কেটেগরি আপডেট তৌবিয়ু',
    'Political parties': 'পোলিটিকেল পার্টিশিং',
    'Update political party categories shown in home':
        'হোমদা উৎলিবা পার্টি কেটেগরি আপডেট তৌবিয়ু',
    'Change religion': 'ধর্ম হোংদোকউ',
    'Update which categories appear in home':
        'হোমদা উৎকদবা কেটেগরি আপডেট তৌবিয়ু',
    'Location-based status': 'লোকেশনগী স্টেটস',
    'View plan details': 'প্লান ডিটেলস ইয়েংবিয়ু',
    'Referral rewards': 'রেফারেল রিওয়ার্ডশিং',
    'Restore subscriptions': 'সাবস্ক্রিপশন রিস্টোর তৌবিয়ু',
    'Share App': 'এপ শেয়ার তৌবিয়ু',
    'Report a poster or issue': 'পোস্টার নত্রগা ইস্যু রিপোর্ট তৌবিয়ু',
    'Delete account': 'একাউন্ট ডিলিট তৌবিয়ু',
    'Privacy Policy': 'প্রাইভেসি পলিসি',
    'Ad privacy choices': 'এড প্রাইভেসি অপশনশিং',
    'Terms & Conditions': 'নিয়ম অমসুং শর্তশিং',
  },
  AppLanguage.mizo: <String, String>{
    'Quick actions': 'Action rang',
    'More': 'Tam zawk',
    'Remaining options': 'Option la awmte',
    'Change State / UT': 'State / UT thlak',
    'Update app language and state categories':
        'App tawng leh state category update rawh',
    'Political parties': 'Political party-te',
    'Update political party categories shown in home':
        'Home-a party category langte update rawh',
    'Change religion': 'Sakhua thlak',
    'Update which categories appear in home':
        'Home-a category lang tur update rawh',
    'Location-based status': 'Location status',
    'View plan details': 'Plan details en rawh',
    'Referral rewards': 'Referral reward',
    'Restore subscriptions': 'Subscription restore rawh',
    'Share App': 'App share rawh',
    'Report a poster or issue': 'Poster emaw issue report rawh',
    'Delete account': 'Account delete rawh',
    'Privacy Policy': 'Privacy Policy',
    'Ad privacy choices': 'Ad privacy choices',
    'Terms & Conditions': 'Terms & Conditions',
  },
  AppLanguage.odia: <String, String>{
    'Quick actions': 'ଦ୍ରୁତ ବିକଳ୍ପ',
    'More': 'ଅଧିକ',
    'Remaining options': 'ଅବଶିଷ୍ଟ ବିକଳ୍ପ',
    'Change State / UT': 'ରାଜ୍ୟ / କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ ବଦଳାନ୍ତୁ',
    'Update app language and state categories':
        'ଆପ୍ ଭାଷା ଏବଂ ରାଜ୍ୟ କ୍ୟାଟେଗୋରୀ ଅପଡେଟ୍ କରନ୍ତୁ',
    'Political parties': 'ରାଜନୈତିକ ଦଳ',
    'Update political party categories shown in home':
        'ହୋମ୍‌ରେ ଦେଖାଯାଉଥିବା ଦଳ କ୍ୟାଟେଗୋରୀ ଅପଡେଟ୍ କରନ୍ତୁ',
    'Change religion': 'ଧର୍ମ ବଦଳାନ୍ତୁ',
    'Update which categories appear in home':
        'ହୋମ୍‌ରେ ଦେଖାଯାଉଥିବା କ୍ୟାଟେଗୋରୀ ଅପଡେଟ୍ କରନ୍ତୁ',
    'Location-based status': 'ସ୍ଥାନ ଆଧାରିତ ଷ୍ଟେଟସ୍',
    'View plan details': 'ପ୍ଲାନ୍ ବିବରଣୀ ଦେଖନ୍ତୁ',
    'Referral rewards': 'ରେଫରାଲ୍ ପୁରସ୍କାର',
    'Restore subscriptions': 'ସବସ୍କ୍ରିପସନ୍ ରିଷ୍ଟୋର୍ କରନ୍ତୁ',
    'Share App': 'ଆପ୍ ସେୟାର୍ କରନ୍ତୁ',
    'Report a poster or issue': 'ପୋଷ୍ଟର୍ କିମ୍ବା ସମସ୍ୟା ରିପୋର୍ଟ କରନ୍ତୁ',
    'Delete account': 'ଆକାଉଣ୍ଟ ଡିଲିଟ୍ କରନ୍ତୁ',
    'Privacy Policy': 'ଗୋପନୀୟତା ନୀତି',
    'Ad privacy choices': 'ବିଜ୍ଞାପନ ଗୋପନୀୟତା ବିକଳ୍ପ',
    'Terms & Conditions': 'ନିୟମ ଏବଂ ସର୍ତ୍ତାବଳୀ',
  },
  AppLanguage.punjabi: <String, String>{
    'Quick actions': 'ਤੇਜ਼ ਵਿਕਲਪ',
    'More': 'ਹੋਰ',
    'Remaining options': 'ਬਾਕੀ ਵਿਕਲਪ',
    'Change State / UT': 'ਰਾਜ / ਕੇਂਦਰ ਸ਼ਾਸਿਤ ਪ੍ਰਦੇਸ਼ ਬਦਲੋ',
    'Update app language and state categories':
        'ਐਪ ਭਾਸ਼ਾ ਅਤੇ ਰਾਜ ਕੈਟੇਗਰੀ ਅਪਡੇਟ ਕਰੋ',
    'Political parties': 'ਰਾਜਨੀਤਿਕ ਪਾਰਟੀਆਂ',
    'Update political party categories shown in home':
        'ਹੋਮ ਵਿੱਚ ਦਿਖਣ ਵਾਲੀਆਂ ਪਾਰਟੀ ਕੈਟੇਗਰੀਆਂ ਅਪਡੇਟ ਕਰੋ',
    'Change religion': 'ਧਰਮ ਬਦਲੋ',
    'Update which categories appear in home':
        'ਹੋਮ ਵਿੱਚ ਦਿਖਣ ਵਾਲੀਆਂ ਕੈਟੇਗਰੀਆਂ ਅਪਡੇਟ ਕਰੋ',
    'Location-based status': 'ਸਥਾਨ ਆਧਾਰਿਤ ਸਟੇਟਸ',
    'View plan details': 'ਪਲਾਨ ਵੇਰਵੇ ਵੇਖੋ',
    'Referral rewards': 'ਰੇਫਰਲ ਇਨਾਮ',
    'Restore subscriptions': 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਰੀਸਟੋਰ ਕਰੋ',
    'Share App': 'ਐਪ ਸ਼ੇਅਰ ਕਰੋ',
    'Report a poster or issue': 'ਪੋਸਟਰ ਜਾਂ ਸਮੱਸਿਆ ਰਿਪੋਰਟ ਕਰੋ',
    'Delete account': 'ਖਾਤਾ ਡਿਲੀਟ ਕਰੋ',
    'Privacy Policy': 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ',
    'Ad privacy choices': 'ਵਿਗਿਆਪਨ ਗੋਪਨੀਯਤਾ ਵਿਕਲਪ',
    'Terms & Conditions': 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ',
  },
  AppLanguage.nepali: <String, String>{
    'Quick actions': 'छिटो विकल्पहरू',
    'More': 'थप',
    'Remaining options': 'बाँकी विकल्पहरू',
    'Change State / UT': 'राज्य / केन्द्र शासित क्षेत्र परिवर्तन गर्नुहोस्',
    'Update app language and state categories':
        'एप भाषा र राज्य क्याटेगरी अपडेट गर्नुहोस्',
    'Political parties': 'राजनीतिक पार्टीहरू',
    'Update political party categories shown in home':
        'होममा देखिने पार्टी क्याटेगरी अपडेट गर्नुहोस्',
    'Change religion': 'धर्म परिवर्तन गर्नुहोस्',
    'Update which categories appear in home':
        'होममा देखिने क्याटेगरी अपडेट गर्नुहोस्',
    'Location-based status': 'स्थान आधारित स्टेटस',
    'View plan details': 'प्लान विवरण हेर्नुहोस्',
    'Referral rewards': 'रेफरल पुरस्कार',
    'Restore subscriptions': 'सब्स्क्रिप्सन रिस्टोर गर्नुहोस्',
    'Share App': 'एप शेयर गर्नुहोस्',
    'Report a poster or issue': 'पोस्टर वा समस्या रिपोर्ट गर्नुहोस्',
    'Delete account': 'खाता डिलिट गर्नुहोस्',
    'Privacy Policy': 'गोपनीयता नीति',
    'Ad privacy choices': 'विज्ञापन गोपनीयता विकल्प',
    'Terms & Conditions': 'नियम र सर्तहरू',
  },
  AppLanguage.bengali: <String, String>{
    'Quick actions': 'দ্রুত বিকল্প',
    'More': 'আরও',
    'Remaining options': 'বাকি বিকল্প',
    'Change State / UT': 'রাজ্য / কেন্দ্রশাসিত অঞ্চল বদলান',
    'Update app language and state categories':
        'অ্যাপ ভাষা এবং রাজ্য ক্যাটেগরি আপডেট করুন',
    'Political parties': 'রাজনৈতিক দল',
    'Update political party categories shown in home':
        'হোমে দেখা রাজনৈতিক দলের ক্যাটেগরি আপডেট করুন',
    'Change religion': 'ধর্ম বদলান',
    'Update which categories appear in home':
        'হোমে কোন ক্যাটেগরি দেখা যাবে আপডেট করুন',
    'Location-based status': 'লোকেশন ভিত্তিক স্টেটাস',
    'View plan details': 'প্ল্যানের বিবরণ দেখুন',
    'Referral rewards': 'রেফারেল পুরস্কার',
    'Restore subscriptions': 'সাবস্ক্রিপশন রিস্টোর করুন',
    'Share App': 'অ্যাপ শেয়ার করুন',
    'Report a poster or issue': 'পোস্টার বা সমস্যা রিপোর্ট করুন',
    'Delete account': 'অ্যাকাউন্ট ডিলিট করুন',
    'Privacy Policy': 'প্রাইভেসি পলিসি',
    'Ad privacy choices': 'বিজ্ঞাপন প্রাইভেসি বিকল্প',
    'Terms & Conditions': 'নিয়ম ও শর্তাবলী',
  },
  AppLanguage.kashmiri: <String, String>{
    'Quick actions': 'جلدی اختیار',
    'More': 'مزید',
    'Remaining options': 'باقی اختیار',
    'Change State / UT': 'ریاست / UT بدلاؤ',
    'Update app language and state categories':
        'ایپ زبان تہ ریاست کیٹگری اپڈیٹ کرو',
    'Political parties': 'Ø³ÛŒØ§Ø³ÛŒ Ù¾Ø§Ø±Ù¹ÛŒØ§Úº',
    'Update political party categories shown in home':
        'ہومس منز دکھن وٲل پارٹۍ کیٹگری اپڈیٹ کرو',
    'Change religion': 'مذہب بدلاؤ',
    'Update which categories appear in home':
        'ہومس منز دکھن وٲل کیٹگری اپڈیٹ کرو',
    'Location-based status': 'لوکیشن بنیاد سٹیٹس',
    'View plan details': 'Ù¾Ù„Ø§Ù† ØªÙØµÛŒÙ„ ÙˆÚ†Ú¾ÛŒÙˆ',
    'Referral rewards': 'Ø±ÛŒÙØ±Ù„ Ø§Ù†Ø¹Ø§Ù…',
    'Restore subscriptions': 'سبسکرپشن بحال کرو',
    'Share App': 'ایپ شیئر کرو',
    'Report a poster or issue': 'Ù¾ÙˆØ³Ù¹Ø± ÛŒØ§ Ù…Ø³Ø¦Ù„Û Ø±Ù¾ÙˆØ±Ù¹ Ú©Ø±Ùˆ',
    'Delete account': 'اکاؤنٹ ڈیلیٹ کرو',
    'Privacy Policy': 'رازداری پالیسی',
    'Ad privacy choices': 'ایڈ رازداری اختیار',
    'Terms & Conditions': 'شرائط و ضوابط',
  },
  AppLanguage.ladakhi: <String, String>{
    'Quick actions': 'མགྱོགས་པོའི་གདམ་ཁ།',
    'More': 'མང་བ།',
    'Remaining options': 'ལྷག་མའི་གདམ་ཁ།',
    'Change State / UT': 'State / UT བསྒྱུར།',
    'Update app language and state categories':
        'App language དང state category update བྱེད།',
    'Political parties': 'Political parties',
    'Update political party categories shown in home':
        'Home ནང་གི party category update བྱེད།',
    'Change religion': 'Religion བསྒྱུར།',
    'Update which categories appear in home':
        'Home ནང་གི category update བྱེད།',
    'Location-based status': 'Location status',
    'View plan details': 'Plan details ལྟ།',
    'Referral rewards': 'Referral rewards',
    'Restore subscriptions': 'Subscriptions restore',
    'Share App': 'App share',
    'Report a poster or issue': 'Poster ཡང་ན issue report',
    'Delete account': 'Account delete',
    'Privacy Policy': 'Privacy Policy',
    'Ad privacy choices': 'Ad privacy choices',
    'Terms & Conditions': 'Terms & Conditions',
  },
};

const Map<String, String> _cleanTeluguUiFallbacks = <String, String>{
  'Preparing...': 'సిద్ధం...',
  'Share': 'షేర్',
  'Photo': 'ఫోటో',
  'Edit': 'ఎడిట్',
  'Add Photo': 'ఫోటో జోడించండి',
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

  bool get _usesEditorEnglishUi {
    var isEditorContext = false;
    void inspect(Element element) {
      final typeName = element.widget.runtimeType.toString();
      if (typeName == 'ImageEditorScreen' || typeName == 'PageSetupScreen') {
        isEditorContext = true;
      }
    }

    if (this is Element) {
      inspect(this as Element);
      if (!isEditorContext) {
        (this as Element).visitAncestorElements((Element ancestor) {
          inspect(ancestor);
          return !isEditorContext;
        });
      }
    }
    return isEditorContext;
  }

  AppLanguage get currentLanguage => _usesEditorEnglishUi
      ? AppLanguage.english
      : AppLanguageScope.maybeOf(this)?.language ?? AppLanguage.english;
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
    String? assamese,
    String? konkani,
    String? gujarati,
    String? marathi,
    String? meitei,
    String? mizo,
    String? odia,
    String? punjabi,
    String? nepali,
    String? bengali,
    String? kashmiri,
    String? ladakhi,
  }) {
    final fallback = _sanitizeDisplayText(english);
    if (language.supportedUiLanguage == SupportedUiLanguage.telugu) {
      final cleanTelugu = _cleanTeluguUiFallbacks[english];
      if (cleanTelugu != null) {
        return cleanTelugu;
      }
    }
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
      SupportedUiLanguage.assamese =>
        assamese ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.konkani =>
        konkani ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.gujarati =>
        gujarati ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.marathi =>
        marathi ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.meitei =>
        meitei ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.mizo =>
        mizo ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.odia =>
        odia ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.punjabi =>
        punjabi ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.nepali =>
        nepali ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.bengali =>
        bengali ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.kashmiri =>
        kashmiri ?? _commonLocalizedFallback(english) ?? english,
      SupportedUiLanguage.ladakhi =>
        ladakhi ?? _commonLocalizedFallback(english) ?? english,
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
    var repaired = value;
    try {
      for (var index = 0; index < 3; index++) {
        final decoded = utf8.decode(
          latin1.encode(repaired),
          allowMalformed: true,
        );
        if (decoded == repaired || decoded.trim().isEmpty) {
          break;
        }
        repaired = decoded;
      }
      return repaired;
    } catch (_) {
      return repaired;
    }
  }

  bool _containsPlainMojibakeLeadBytes(String value) {
    return value.contains('\u00E0\u00B0') ||
        value.contains('\u00E0\u00A4') ||
        value.contains('\u00E0\u00AE') ||
        value.contains('\u00E0\u00B2') ||
        value.contains('\u00E0\u00B4');
  }

  bool _looksCorrupted(String value) {
    if (value.contains('\u00E0\u00B0') ||
        value.contains('\u00E0\u00A4') ||
        value.contains('\u00E0\u00AE') ||
        value.contains('\u00E0\u00B2') ||
        value.contains('\u00E0\u00B4')) {
      return true;
    }
    return value.contains("\u00c3\u00a0") ||
        value.contains("\u00c3\u00a2\u00e2\u201a\u00ac") ||
        value.contains("\u00c3\u00a2\u00c5\u201c") ||
        value.contains("\u00c3\u00b0\u00c5\u00b8") ||
        value.contains("\u00c3\u00af\u00c2\u00b8") ||
        value.contains("\u00c3\u00a2\u00c2\u009d") ||
        value.contains('\u00E0\u00B0') ||
        value.contains('\u00E0\u00A4') ||
        value.contains('\u00E0\u00AE') ||
        value.contains('\u00E0\u00B2') ||
        value.contains('\u00E0\u00B4') ||
        value.contains('\u00E2\u20AC') ||
        value.contains('\u2019') ||
        value.contains('\u201C') ||
        value.contains('\u201D');
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
      case SupportedUiLanguage.assamese:
      case SupportedUiLanguage.konkani:
      case SupportedUiLanguage.gujarati:
      case SupportedUiLanguage.marathi:
      case SupportedUiLanguage.meitei:
      case SupportedUiLanguage.mizo:
      case SupportedUiLanguage.odia:
      case SupportedUiLanguage.punjabi:
      case SupportedUiLanguage.nepali:
      case SupportedUiLanguage.bengali:
      case SupportedUiLanguage.kashmiri:
      case SupportedUiLanguage.ladakhi:
        return _regionalCommonFallbacks[language]?[english] ??
            (language == AppLanguage.bengali
                ? _commonBengaliFallback(english)
                : null) ??
            _regionalCommonPhraseFallback(english);
      case SupportedUiLanguage.telugu:
      case SupportedUiLanguage.english:
        return null;
    }
  }

  String? _regionalFallback(String english) {
    // Regional languages without complete reviewed coverage use one consistent
    // English UI only when the selected language itself is English.
    if (language == AppLanguage.english) {
      return null;
    }
    final profileFallback = _regionalProfileFallbacks[language]?[english];
    if (profileFallback != null) {
      return profileFallback;
    }
    final communityUploadFallback =
        _regionalCommunityUploadFallbacks[language]?[english];
    if (communityUploadFallback != null) {
      return communityUploadFallback;
    }
    final extraFallback = _regionalExtraFallbacks[language]?[english];
    if (extraFallback != null) {
      return extraFallback;
    }
    final quickUiFallback = _regionalQuickUiFallback(english);
    if (quickUiFallback != null) {
      return quickUiFallback;
    }
    if (language == AppLanguage.bengali) {
      return _regionalCommonFallbacks[language]?[english] ??
          _commonBengaliFallback(english) ??
          _regionalCommonPhraseFallback(english);
    }
    return _regionalCommonFallbacks[language]?[english] ??
        _regionalCommonPhraseFallback(english);
  }

  String? _regionalQuickUiFallback(String english) {
    final map = switch (language) {
      AppLanguage.assamese => const <String, String>{
        'OK': 'ঠিক আছে',
        'Cancel': 'বাতিল',
        'Close': 'বন্ধ কৰক',
        'Apply': 'প্ৰয়োগ কৰক',
        'Share': 'শ্বেয়াৰ',
        'Download': 'ডাউনলোড',
        'More': 'অধিক',
        'Remaining options': 'বাকী বিকল্পসমূহ',
        'Change religion': 'ধৰ্ম সলনি কৰক',
        'Referral rewards': 'ৰেফাৰেল পুৰস্কাৰ',
        'Copy code': 'কোড কপি কৰক',
        'Delete account': 'একাউণ্ট মচক',
        'Privacy Policy': 'গোপনীয়তা নীতি',
        'Ad privacy choices': 'বিজ্ঞাপন গোপনীয়তা পছন্দ',
        'Permissions': 'অনুমতিসমূহ',
        'Check': 'চাওক',
        'Subscription Required': 'সদস্যতা প্ৰয়োজন',
        '3-day trial plan': '৩ দিনৰ পৰীক্ষামূলক প্লেন',
        'Monthly plan': 'মাহেকীয়া প্লেন',
        'Terms': 'নিয়মসমূহ',
        'Skip': 'এৰি যাওক',
        'Subscribe': 'সদস্যতা লওক',
        'Trial': 'পৰীক্ষামূলক',
        'Select Category': 'শ্ৰেণী বাছক',
      },
      AppLanguage.konkani => const <String, String>{
        'OK': 'बरें',
        'Cancel': 'रद्द',
        'Close': 'बंद करात',
        'Apply': 'लागू करात',
        'Share': 'शेअर',
        'Download': 'डाउनलोड',
        'More': 'आनीक',
        'Remaining options': 'उरिल्ले पर्याय',
        'Change religion': 'धर्म बदलात',
        'Referral rewards': 'रेफरल इनाम',
        'Copy code': 'कोड कॉपी करात',
        'Delete account': 'खातें काडून उडोवप',
        'Privacy Policy': 'गोपनीयता धोरण',
        'Ad privacy choices': 'जाहिरात गोपनीयता पर्याय',
        'Permissions': 'परवानग्यो',
        'Check': 'तपासात',
        'Subscription Required': 'सदस्यता गरजेची',
        '3-day trial plan': '३ दिसांचो ट्रायल प्लॅन',
        'Monthly plan': 'म्हयन्याचो प्लॅन',
        'Terms': 'अटी',
        'Skip': 'सोडात',
        'Subscribe': 'सदस्यता घेवप',
        'Trial': 'ट्रायल',
        'Select Category': 'विभाग निवडात',
      },
      AppLanguage.gujarati => const <String, String>{
        'OK': 'બરાબર',
        'Cancel': 'રદ કરો',
        'Close': 'બંધ કરો',
        'Apply': 'લાગુ કરો',
        'Share': 'શેર',
        'Download': 'ડાઉનલોડ',
        'More': 'વધુ',
        'Remaining options': 'બાકીના વિકલ્પો',
        'Change religion': 'ધર્મ બદલો',
        'Referral rewards': 'રેફરલ ઈનામ',
        'Copy code': 'કોડ કૉપી કરો',
        'Delete account': 'એકાઉન્ટ કાઢી નાખો',
        'Privacy Policy': 'ગોપનીયતા નીતિ',
        'Ad privacy choices': 'જાહેરાત ગોપનીયતા પસંદગીઓ',
        'Permissions': 'પરવાનગીઓ',
        'Check': 'ચકાસો',
        'Subscription Required': 'સબ્સ્ક્રિપ્શન જરૂરી',
        '3-day trial plan': '૩ દિવસનો ટ્રાયલ પ્લાન',
        'Monthly plan': 'માસિક પ્લાન',
        'Terms': 'નિયમો',
        'Skip': 'છોડી દો',
        'Subscribe': 'સબ્સ્ક્રાઇબ કરો',
        'Trial': 'ટ્રાયલ',
        'Select Category': 'કેટેગરી પસંદ કરો',
      },
      AppLanguage.marathi => const <String, String>{
        'OK': 'ठीक आहे',
        'Cancel': 'रद्द',
        'Close': 'बंद करा',
        'Apply': 'लागू करा',
        'Share': 'शेअर',
        'Download': 'डाउनलोड',
        'More': 'अधिक',
        'Remaining options': 'उरलेले पर्याय',
        'Change religion': 'धर्म बदला',
        'Referral rewards': 'रेफरल बक्षिसे',
        'Copy code': 'कोड कॉपी करा',
        'Delete account': 'खाते हटवा',
        'Privacy Policy': 'गोपनीयता धोरण',
        'Ad privacy choices': 'जाहिरात गोपनीयता पर्याय',
        'Permissions': 'परवानग्या',
        'Check': 'तपासा',
        'Subscription Required': 'सदस्यता आवश्यक',
        '3-day trial plan': '३ दिवसांचा ट्रायल प्लॅन',
        'Monthly plan': 'मासिक प्लॅन',
        'Terms': 'अटी',
        'Skip': 'वगळा',
        'Subscribe': 'सदस्यता घ्या',
        'Trial': 'ट्रायल',
        'Select Category': 'श्रेणी निवडा',
      },
      AppLanguage.meitei => const <String, String>{
        'OK': 'ê¯Œê¯¥ê¯”ê¯¦',
        'Cancel': 'ê¯‡ê¯£ê¯›ê¯Ž',
        'Close': 'ꯂꯣꯏꯁꯤꯟꯕꯤꯌꯨ',
        'Apply': 'ꯑꯦꯞꯂꯥꯏ ꯇꯧꯕꯤꯌꯨ',
        'Share': 'ê¯ê¯¦ê¯Œê¯”',
        'Download': 'ê¯—ê¯¥ê¯Žê¯Ÿê¯‚ê¯£ê¯—',
        'More': 'ê¯ê¯¦ê¯Ÿê¯…',
        'Remaining options': 'ꯂꯩꯔꯤꯕ ꯑꯣꯞꯁꯟꯁꯤꯡ',
        'Change religion': 'ꯂꯥꯢꯅꯤꯡ ꯍꯣꯡꯗꯣꯛꯎ',
        'Referral rewards': 'ê¯”ê¯¦ê¯ê¯”ê¯¦ê¯œ ê¯ƒê¯…ê¯¥',
        'Copy code': 'ꯀꯣꯗ ꯀꯣꯄꯤ ꯇꯧꯕꯤꯌꯨ',
        'Delete account': 'ê¯‘ê¯¦ê¯€ê¯¥ê¯Žê¯Ÿê¯‡ ê¯ƒê¯¨ê¯ ê¯Šê¯ ê¯Ž',
        'Privacy Policy': 'ꯄ꯭ꯔꯥꯏꯚꯦꯁꯤ ꯄꯣꯂꯤꯁꯤ',
        'Ad privacy choices': 'ꯑꯦꯗ ꯄ꯭ꯔꯥꯏꯚꯦꯁꯤ ꯈꯟꯅꯕꯁꯤꯡ',
        'Permissions': 'ꯑꯌꯥꯕꯁꯤꯡ',
        'Check': 'ꯌꯦꯡꯕꯤꯌꯨ',
        'Subscription Required': 'ꯁꯕꯁ꯭ꯛꯔꯤꯞꯁꯟ ꯃꯊꯧ ꯇꯥꯏ',
        '3-day trial plan': 'ꯅꯨꯃꯤꯠ ꯳ ꯇ꯭ꯔꯥꯏꯌꯜ ꯄ꯭ꯂꯥꯟ',
        'Monthly plan': 'ꯊꯥꯒꯤ ꯄ꯭ꯂꯥꯟ',
        'Terms': 'ꯅꯤꯌꯝꯁꯤꯡ',
        'Skip': 'ê¯Šê¯¥ê¯—ê¯£ê¯›ê¯Ž',
        'Subscribe': 'ꯁꯕꯁ꯭ꯛꯔꯥꯏꯕ ꯇꯧꯕꯤꯌꯨ',
        'Trial': 'ê¯‡ê¯­ê¯”ê¯¥ê¯ê¯Œê¯œ',
        'Select Category': 'ꯀꯦꯇꯦꯒꯣꯔꯤ ꯈꯟꯕꯤꯌꯨ',
      },
      AppLanguage.mizo => const <String, String>{
        'OK': 'A tha',
        'Cancel': 'Sût',
        'Close': 'Khâr rawh',
        'Apply': 'Hmang rawh',
        'Share': 'Sem rawh',
        'Download': 'Download rawh',
        'More': 'Tam zawk',
        'Remaining options': 'Option dangte',
        'Change religion': 'Sakhua thlak rawh',
        'Referral rewards': 'Referral lawmman',
        'Copy code': 'Code copy rawh',
        'Delete account': 'Account paih rawh',
        'Privacy Policy': 'Privacy policy',
        'Ad privacy choices': 'Ad privacy thlan theih',
        'Permissions': 'Phalna',
        'Check': 'En rawh',
        'Subscription Required': 'Subscription a ngai',
        '3-day trial plan': 'Ni 3 trial plan',
        'Monthly plan': 'Thla tin plan',
        'Terms': 'Terms',
        'Skip': 'Kalsan rawh',
        'Subscribe': 'Subscribe rawh',
        'Trial': 'Trial',
        'Select Category': 'Category thlang rawh',
      },
      AppLanguage.odia => const <String, String>{
        'OK': 'ଠିକ୍ ଅଛି',
        'Cancel': 'ବାତିଲ୍',
        'Close': 'ବନ୍ଦ କରନ୍ତୁ',
        'Apply': 'ଲାଗୁ କରନ୍ତୁ',
        'Share': 'ସେୟାର',
        'Download': 'ଡାଉନଲୋଡ୍',
        'More': 'ଅଧିକ',
        'Remaining options': 'ଅବଶିଷ୍ଟ ବିକଳ୍ପ',
        'Change religion': 'ଧର୍ମ ବଦଳାନ୍ତୁ',
        'Referral rewards': 'ରେଫରାଲ୍ ପୁରସ୍କାର',
        'Copy code': 'କୋଡ୍ କପି କରନ୍ତୁ',
        'Delete account': 'ଖାତା ବିଲୋପ କରନ୍ତୁ',
        'Privacy Policy': 'ଗୋପନୀୟତା ନୀତି',
        'Ad privacy choices': 'ବିଜ୍ଞାପନ ଗୋପନୀୟତା ପସନ୍ଦ',
        'Permissions': 'ଅନୁମତି',
        'Check': 'ଯାଞ୍ଚ କରନ୍ତୁ',
        'Subscription Required': 'ସବସ୍କ୍ରିପସନ୍ ଆବଶ୍ୟକ',
        '3-day trial plan': '୩ ଦିନର ଟ୍ରାୟାଲ୍ ପ୍ଲାନ୍',
        'Monthly plan': 'ମାସିକ ପ୍ଲାନ୍',
        'Terms': 'ନିୟମ',
        'Skip': 'ଛାଡ଼ନ୍ତୁ',
        'Subscribe': 'ସବସ୍କ୍ରାଇବ୍ କରନ୍ତୁ',
        'Trial': 'ଟ୍ରାୟାଲ୍',
        'Select Category': 'ଶ୍ରେଣୀ ବାଛନ୍ତୁ',
      },
      AppLanguage.punjabi => const <String, String>{
        'OK': 'ਠੀਕ ਹੈ',
        'Cancel': 'ਰੱਦ ਕਰੋ',
        'Close': 'ਬੰਦ ਕਰੋ',
        'Apply': 'ਲਾਗੂ ਕਰੋ',
        'Share': 'ਸਾਂਝਾ ਕਰੋ',
        'Download': 'ਡਾਊਨਲੋਡ',
        'More': 'ਹੋਰ',
        'Remaining options': 'ਬਾਕੀ ਵਿਕਲਪ',
        'Change religion': 'ਧਰਮ ਬਦਲੋ',
        'Referral rewards': 'ਰੈਫਰਲ ਇਨਾਮ',
        'Copy code': 'ਕੋਡ ਕਾਪੀ ਕਰੋ',
        'Delete account': 'ਖਾਤਾ ਮਿਟਾਓ',
        'Privacy Policy': 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ',
        'Ad privacy choices': 'ਵਿਗਿਆਪਨ ਗੋਪਨੀਯਤਾ ਚੋਣਾਂ',
        'Permissions': 'ਇਜਾਜ਼ਤਾਂ',
        'Check': 'ਜਾਂਚੋ',
        'Subscription Required': 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਲੋੜੀਂਦੀ ਹੈ',
        '3-day trial plan': '੩ ਦਿਨਾਂ ਦਾ ਟ੍ਰਾਇਲ ਪਲਾਨ',
        'Monthly plan': 'ਮਹੀਨਾਵਾਰ ਪਲਾਨ',
        'Terms': 'ਨਿਯਮ',
        'Skip': 'ਛੱਡੋ',
        'Subscribe': 'ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ',
        'Trial': 'ਟ੍ਰਾਇਲ',
        'Select Category': 'ਕੈਟੇਗਰੀ ਚੁਣੋ',
      },
      AppLanguage.nepali => const <String, String>{
        'OK': 'ठीक छ',
        'Cancel': 'रद्द गर्नुहोस्',
        'Close': 'बन्द गर्नुहोस्',
        'Apply': 'लागू गर्नुहोस्',
        'Share': 'शेयर',
        'Download': 'डाउनलोड',
        'More': 'थप',
        'Remaining options': 'बाँकी विकल्पहरू',
        'Change religion': 'धर्म परिवर्तन गर्नुहोस्',
        'Referral rewards': 'रेफरल पुरस्कार',
        'Copy code': 'कोड कपी गर्नुहोस्',
        'Delete account': 'खाता मेटाउनुहोस्',
        'Privacy Policy': 'गोपनीयता नीति',
        'Ad privacy choices': 'विज्ञापन गोपनीयता विकल्प',
        'Permissions': 'अनुमतिहरू',
        'Check': 'जाँच गर्नुहोस्',
        'Subscription Required': 'सदस्यता आवश्यक',
        '3-day trial plan': '३ दिनको ट्रायल योजना',
        'Monthly plan': 'मासिक योजना',
        'Terms': 'सर्तहरू',
        'Skip': 'छोड्नुहोस्',
        'Subscribe': 'सदस्यता लिनुहोस्',
        'Trial': 'ट्रायल',
        'Select Category': 'श्रेणी छान्नुहोस्',
      },
      AppLanguage.bengali => const <String, String>{
        'OK': 'ঠিক আছে',
        'Cancel': 'বাতিল',
        'Close': 'বন্ধ করুন',
        'Apply': 'প্রয়োগ করুন',
        'Share': 'শেয়ার',
        'Download': 'ডাউনলোড',
        'More': 'আরও',
        'Remaining options': 'বাকি বিকল্প',
        'Change religion': 'ধর্ম পরিবর্তন করুন',
        'Referral rewards': 'রেফারেল পুরস্কার',
        'Copy code': 'কোড কপি করুন',
        'Delete account': 'অ্যাকাউন্ট মুছুন',
        'Privacy Policy': 'গোপনীয়তা নীতি',
        'Ad privacy choices': 'বিজ্ঞাপন গোপনীয়তা পছন্দ',
        'Permissions': 'অনুমতি',
        'Check': 'পরীক্ষা করুন',
        'Subscription Required': 'সাবস্ক্রিপশন প্রয়োজন',
        '3-day trial plan': '৩ দিনের ট্রায়াল প্ল্যান',
        'Monthly plan': 'মাসিক প্ল্যান',
        'Terms': 'শর্তাবলী',
        'Skip': 'এড়িয়ে যান',
        'Subscribe': 'সাবস্ক্রাইব করুন',
        'Trial': 'ট্রায়াল',
        'Select Category': 'বিভাগ নির্বাচন করুন',
      },
      AppLanguage.kashmiri => const <String, String>{
        'OK': 'Ù¹Ú¾ÛŒÚ© Ú†Ú¾',
        'Cancel': 'منسوخ',
        'Close': 'Ø¨Ù†Ø¯ Ú©Ø±ÛŒÙˆ',
        'Apply': 'Ù„Ø§Ú¯Ùˆ Ú©Ø±ÛŒÙˆ',
        'Share': 'شیئر',
        'Download': 'ڈاؤن لوڈ',
        'More': 'مزید',
        'Remaining options': 'باقی اختیار',
        'Change religion': 'مذہب بدلٲو',
        'Referral rewards': 'Ø±ÛŒÙØ±Ù„ Ø§Ù†Ø¹Ø§Ù…',
        'Copy code': 'Ú©ÙˆÚˆ Ú©Ø§Ù¾ÛŒ Ú©Ø±ÛŒÙˆ',
        'Delete account': 'اکاؤنٹ مٹٲو',
        'Privacy Policy': 'رازداری پالیسی',
        'Ad privacy choices': 'اشتہار رازداری اختیار',
        'Permissions': 'اجازت',
        'Check': 'Ú†ÛŒÚ© Ú©Ø±ÛŒÙˆ',
        'Subscription Required': 'سبسکرپشن ضروری چھ',
        '3-day trial plan': 'Û³ Ø¯Ù† Ù¹Ø±Ø§Ø¦Ù„ Ù¾Ù„Ø§Ù†',
        'Monthly plan': 'Ù…Ø§ÛÙˆØ§Ø± Ù¾Ù„Ø§Ù†',
        'Terms': 'شرطٕ',
        'Skip': 'چھوڈٲو',
        'Subscribe': 'Ø³Ø¨Ø³Ú©Ø±Ø§Ø¦Ø¨ Ú©Ø±ÛŒÙˆ',
        'Trial': 'Ù¹Ø±Ø§Ø¦Ù„',
        'Select Category': 'زمرہ چنٲو',
      },
      AppLanguage.ladakhi => const <String, String>{
        'OK': 'འགྲིགས།',
        'Cancel': 'ཕྱིར་འཐེན།',
        'Close': 'ཁ་རྒྱག',
        'Apply': 'ལག་ལེན་བྱེད།',
        'Share': 'བགོ་སྤྲོད།',
        'Download': 'ཕབ་ལེན།',
        'More': 'མང་བ།',
        'Remaining options': 'ལྷག་མའི་གདམ་ག',
        'Change religion': 'ཆོས་ལུགས་བསྒྱུར།',
        'Referral rewards': 'ངོ་སྤྲོད་བྱ་དགའ',
        'Copy code': 'ཨང་རྟགས་འདྲ་བཤུས།',
        'Delete account': 'རྩིས་ཐོ་སུབ།',
        'Privacy Policy': 'གསང་བའི་སྲིད་བྱུས།',
        'Ad privacy choices': 'བརྡ་ཁྱབ་གསང་བའི་གདམ་ག',
        'Permissions': 'ཆོག་མཆན།',
        'Check': 'ཞིབ་བཤེར།',
        'Subscription Required': 'མངགས་ཉོ་དགོས།',
        '3-day trial plan': 'ཉིན་༣ ཚོད་ལྟའི་འཆར་གཞི',
        'Monthly plan': 'ཟླ་རེའི་འཆར་གཞི',
        'Terms': 'ཆ་རྐྱེན།',
        'Skip': 'མཆོང།',
        'Subscribe': 'མངགས་ཉོ་བྱེད།',
        'Trial': 'ཚོད་ལྟ།',
        'Select Category': 'སྡེ་ཚན་འདེམས།',
      },
      AppLanguage.telugu ||
      AppLanguage.hindi ||
      AppLanguage.english ||
      AppLanguage.tamil ||
      AppLanguage.kannada ||
      AppLanguage.malayalam => null,
    };
    return map?[english];
  }

  String? _regionalCommonPhraseFallback(String english) {
    final map = switch (language) {
      AppLanguage.assamese => const <String, String>{
        'Choose and share with your name':
            'আপোনাৰ নামেৰে বাছক আৰু শ্বেয়াৰ কৰক',
        'Choose your language': 'আপোনাৰ ভাষা বাছক',
        'Choose the language you want in the app. You can change it later too.':
            'এপত ব্যৱহাৰ কৰিব বিচৰা ভাষা বাছক। পিছতো সলনি কৰিব পাৰিব।',
        'No posters are available in this section':
            'এই বিভাগত কোনো পোস্টাৰ উপলব্ধ নাই',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'এই কেটেগৰীত এতিয়া কোনো পোস্টাৰ নাই। ৰিফ্ৰেশ কৰি পুনৰ চাওক।',
      },
      AppLanguage.konkani => const <String, String>{
        'Choose and share with your name': 'तुमच्या नावान निवडात आनी शेअर करात',
        'Choose your language': 'तुमची भास निवडात',
        'Choose the language you want in the app. You can change it later too.':
            'एपांत वापरपाची भास निवडात. उपरांत बदलूंक मेळटलें.',
        'No posters are available in this section':
            'ह्या विभागांत पोस्टर उपलब्ध ना',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'ह्या कॅटेगरींत आतां पोस्टर ना. रिफ्रेश करून परत पळयात.',
      },
      AppLanguage.gujarati => const <String, String>{
        'Choose and share with your name':
            'તમારા નામ સાથે પસંદ કરો અને શેર કરો',
        'Choose your language': 'તમારી ભાષા પસંદ કરો',
        'Choose the language you want in the app. You can change it later too.':
            'એપમાં જોઈતી ભાષા પસંદ કરો. પછીથી પણ બદલી શકો છો.',
        'No posters are available in this section':
            'આ વિભાગમાં કોઈ પોસ્ટર ઉપલબ્ધ નથી',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'આ કેટેગરીમાં હાલ કોઈ પોસ્ટર નથી. રિફ્રેશ કરીને ફરી તપાસો.',
      },
      AppLanguage.marathi => const <String, String>{
        'Choose and share with your name': 'तुमच्या नावासह निवडा आणि शेअर करा',
        'Choose your language': 'तुमची भाषा निवडा',
        'Choose the language you want in the app. You can change it later too.':
            'अ‍ॅपमध्ये हवी असलेली भाषा निवडा. नंतरही बदलू शकता.',
        'No posters are available in this section':
            'या विभागात पोस्टर उपलब्ध नाहीत',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'या कॅटेगरीत सध्या पोस्टर नाहीत. रिफ्रेश करून पुन्हा तपासा.',
      },
      AppLanguage.meitei => const <String, String>{
        'Choose and share with your name':
            'ꯅꯍꯥꯛꯀꯤ ꯃꯃꯤꯡꯒꯥ ꯂꯣꯌꯅꯅꯥ ꯈꯅꯕꯤꯌꯨ ꯑꯃꯁꯨꯡ ꯁꯦꯌꯥꯔ ꯇꯧꯕꯤꯌꯨ',
        'Choose your language': 'ꯅꯍꯥꯛꯀꯤ ꯂꯣꯜ ꯈꯅꯕꯤꯌꯨ',
        'Choose the language you want in the app. You can change it later too.':
            'ꯑꯦꯞꯇꯥ ꯄꯥꯝꯂꯤꯕꯥ ꯂꯣꯜ ꯈꯅꯕꯤꯌꯨ। ꯇꯨꯡꯗꯥ ꯑꯃꯨꯛ ꯍꯣꯡꯗꯣꯛꯄꯥ ꯌꯥꯏ।',
        'No posters are available in this section': 'ꯃꯁꯤꯒꯤ ꯁꯦꯛꯁꯅꯗꯥ ꯄꯣꯁ꯭ꯇꯔ ꯂꯩꯇꯦ',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'ꯃꯁꯤꯒꯤ ꯀꯦꯇꯦꯒꯣꯔꯤꯗꯥ ꯍꯧꯖꯤꯛ ꯄꯣꯁ꯭ꯇꯔ ꯂꯩꯇꯦ। ꯔꯤꯐ꯭ꯔꯦꯁ ꯇꯧꯗꯨꯅꯥ ꯑꯃꯨꯛ ꯌꯦꯡꯕꯤꯌꯨ।',
      },
      AppLanguage.mizo => const <String, String>{
        'Choose and share with your name': 'I hming nen thlang la share rawh',
        'Choose your language': 'I tawng thlang rawh',
        'Choose the language you want in the app. You can change it later too.':
            'App-a i duh tawng thlang rawh. A hnuaiah pawh i thlak thei.',
        'No posters are available in this section':
            'He section-ah poster a awm lo',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'He category-ah tunah poster a awm lo. Refresh la en leh rawh.',
      },
      AppLanguage.odia => const <String, String>{
        'Choose and share with your name':
            'ଆପଣଙ୍କ ନାମ ସହିତ ବାଛନ୍ତୁ ଏବଂ ସେୟାର କରନ୍ତୁ',
        'Choose your language': 'ଆପଣଙ୍କ ଭାଷା ବାଛନ୍ତୁ',
        'Choose the language you want in the app. You can change it later too.':
            'ଆପ୍‌ରେ ଚାହୁଁଥିବା ଭାଷା ବାଛନ୍ତୁ। ପରେ ମଧ୍ୟ ବଦଳାଇପାରିବେ।',
        'No posters are available in this section':
            'ଏହି ବିଭାଗରେ କୌଣସି ପୋଷ୍ଟର ଉପଲବ୍ଧ ନାହିଁ',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'ଏହି କ୍ୟାଟେଗୋରୀରେ ଏବେ ପୋଷ୍ଟର ନାହିଁ। ରିଫ୍ରେଶ କରି ପୁଣି ଦେଖନ୍ତୁ।',
      },
      AppLanguage.punjabi => const <String, String>{
        'Choose and share with your name': 'ਆਪਣੇ ਨਾਮ ਨਾਲ ਚੁਣੋ ਅਤੇ ਸ਼ੇਅਰ ਕਰੋ',
        'Choose your language': 'ਆਪਣੀ ਭਾਸ਼ਾ ਚੁਣੋ',
        'Choose the language you want in the app. You can change it later too.':
            'ਐਪ ਵਿੱਚ ਆਪਣੀ ਚਾਹੀਦੀ ਭਾਸ਼ਾ ਚੁਣੋ। ਬਾਅਦ ਵਿੱਚ ਵੀ ਬਦਲ ਸਕਦੇ ਹੋ।',
        'No posters are available in this section':
            'ਇਸ ਭਾਗ ਵਿੱਚ ਕੋਈ ਪੋਸਟਰ ਉਪਲਬਧ ਨਹੀਂ',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'ਇਸ ਕੈਟੇਗਰੀ ਵਿੱਚ ਇਸ ਵੇਲੇ ਕੋਈ ਪੋਸਟਰ ਨਹੀਂ। ਰਿਫ੍ਰੈਸ਼ ਕਰਕੇ ਫਿਰ ਵੇਖੋ।',
      },
      AppLanguage.nepali => const <String, String>{
        'Choose and share with your name':
            'आफ्नो नामसहित छान्नुहोस् र शेयर गर्नुहोस्',
        'Choose your language': 'आफ्नो भाषा छान्नुहोस्',
        'Choose the language you want in the app. You can change it later too.':
            'एपमा चाहिएको भाषा छान्नुहोस्। पछि पनि परिवर्तन गर्न सक्नुहुन्छ।',
        'No posters are available in this section':
            'यस खण्डमा कुनै पोस्टर उपलब्ध छैन',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'यस क्याटेगोरीमा अहिले पोस्टर छैन। रिफ्रेश गरेर फेरि हेर्नुहोस्।',
      },
      AppLanguage.bengali => const <String, String>{
        'Choose and share with your name': 'আপনার নাম দিয়ে বেছে শেয়ার করুন',
        'Choose your language': 'আপনার ভাষা বেছে নিন',
        'Choose the language you want in the app. You can change it later too.':
            'অ্যাপে যে ভাষা চান তা বেছে নিন। পরে এটিও পরিবর্তন করতে পারবেন।',
        'No posters are available in this section':
            'এই বিভাগে কোনো পোস্টার উপলব্ধ নেই',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'এই ক্যাটেগরিতে এখন কোনো পোস্টার নেই। রিফ্রেশ করে আবার দেখুন।',
      },
      AppLanguage.kashmiri => const <String, String>{
        'Choose and share with your name':
            'پنُن ناو لگایِتھ ژارِو تہ شیئر کَریو',
        'Choose your language': 'پنُن زبان ژارِو',
        'Choose the language you want in the app. You can change it later too.':
            'ایپ منز پنُن پسند زبان ژارِو۔ پتہ تہ بدلٲوِتھ ہیکیو۔',
        'No posters are available in this section':
            'یمس حصس منز کانہہ پوسٹر دستیاب چھُنہ',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'یمس کیٹگری منز وۄنہ پوسٹر چھُنہ۔ ریفریش کَریتھ بیاکھ لٹہ وُچھو۔',
      },
      AppLanguage.ladakhi => const <String, String>{
        'Choose and share with your name':
            'རང་གི་མིང་དང་མཉམ་དུ་འདེམས་ནས་བགོ་སྤྲོད་བྱེད།',
        'Choose your language': 'རང་གི་སྐད་ཡིག་འདེམས།',
        'Choose the language you want in the app. You can change it later too.':
            'App ནང་དགོས་པའི་སྐད་ཡིག་འདེམས། རྗེས་སུ་ཡང་བསྒྱུར་ཆོག',
        'No posters are available in this section':
            'འདིའི་སྡེ་ཚན་ནང་པོསྟར་མེད།',
        'There are no posters for this category right now. Pull down to refresh and check again.':
            'འདིའི་རིགས་ནང་ད་ལྟ་པོསྟར་མེད། རི་ཕྲེཤ་བྱས་ནས་ཡང་ལྟོས།',
      },
      AppLanguage.telugu ||
      AppLanguage.hindi ||
      AppLanguage.english ||
      AppLanguage.tamil ||
      AppLanguage.kannada ||
      AppLanguage.malayalam => null,
    };
    return map?[english];
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

  String get splashTagline =>
      _regionalFallback('Choose and share with your name') ??
      switch (language.supportedUiLanguage) {
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
        _ => 'Choose and share with your name',
      };

  String get languageScreenTitle =>
      _regionalFallback('Choose your language') ??
      switch (language.supportedUiLanguage) {
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
        _ => 'Choose your language',
      };

  String get languageScreenSubtitle =>
      _regionalFallback(
        'Choose the language you want in the app. You can change it later too.',
      ) ??
      switch (language.supportedUiLanguage) {
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
        _ =>
          'Choose the language you want in the app. You can change it later too.',
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
        _ => 'Continue',
      };

  String get homeEmptyPostersTitle =>
      _regionalFallback('No posters are available in this section') ??
      switch (language.supportedUiLanguage) {
        SupportedUiLanguage.telugu => 'ఈ విభాగంలో పోస్టర్లు అందుబాటులో లేవు',
        SupportedUiLanguage.hindi => 'इस सेक्शन में पोस्टर उपलब्ध नहीं हैं',
        SupportedUiLanguage.english =>
          'No posters are available in this section',
        SupportedUiLanguage.tamil => 'இந்த பகுதியில் போஸ்டர்கள் இல்லை',
        SupportedUiLanguage.kannada => 'ಈ ವಿಭಾಗದಲ್ಲಿ ಪೋಸ್ಟರ್‌ಗಳು ಲಭ್ಯವಿಲ್ಲ',
        SupportedUiLanguage.malayalam => 'ഈ വിഭാഗത്തിൽ പോസ്റ്ററുകൾ ലഭ്യമല്ല',
        _ => 'No posters are available in this section',
      };

  String get homeEmptyPostersSubtitle =>
      _regionalFallback(
        'There are no posters for this category right now. Pull down to refresh and check again.',
      ) ??
      switch (language.supportedUiLanguage) {
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
        _ =>
          'There are no posters for this category right now. Pull down to refresh and check again.',
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
        _ => 'Welcome to Mana Poster Ai',
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
        _ => 'Login with Google or Email and start your poster journey.',
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
        _ => 'Login',
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
        _ => 'Sign Up',
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
        _ => 'Continue with Google',
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
        _ => 'Email address',
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
        _ => 'Password',
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
        _ => 'Forgot Password',
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
        _ => "Don't have an account?",
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
        _ => 'Already have an account?',
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
        _ => 'Login with Email',
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
        _ => 'Sign Up with Email',
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
        _ => 'Enter valid email',
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
        _ => 'Minimum 6 characters required',
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
        _ => 'Password reset will be available soon.',
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
        _ => 'A few permissions are needed',
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
    _ =>
      'Permissions are needed to choose photos, save posters, and receive important updates.',
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
        _ => 'Photos/Gallery',
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
        _ => 'Notifications',
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
    _ => 'You can enable permissions later from Settings as well.',
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
        _ => 'Allow',
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
        _ => 'Later',
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
        _ => 'Create & Share',
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
        _ => 'Create',
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
        _ => 'Search templates',
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
    _ => 'Mana Poster Ai Featured Banner',
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
        _ => 'Ready',
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
        _ => 'Special',
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
        _ => 'Buy',
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
        _ => 'Share WhatsApp',
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
        _ => 'Download',
      };

  String get addPoliticalPhotos => localized(
    telugu: 'పొలిటికల్ ఫోటోలు జోడించండి',
    english: 'Add Political Photos',
    hindi: 'राजनीतिक फोटो जोड़ें',
    tamil: 'அரசியல் புகைப்படங்களை சேர்க்கவும்',
    kannada: 'ರಾಜಕೀಯ ಫೋಟೋಗಳನ್ನು ಸೇರಿಸಿ',
    malayalam: 'രാഷ്ട്രീയ ഫോട്ടോകൾ ചേർക്കുക',
    assamese: 'ৰাজনৈতিক ফটো যোগ কৰক',
    konkani: 'राजकीय फोटो जोडात',
    gujarati: 'રાજકીય ફોટા ઉમેરો',
    marathi: 'राजकीय फोटो जोडा',
    meitei: 'Political photo hapchinbiyu',
    mizo: 'Political photo dah rawh',
    odia: 'ରାଜନୈତିକ ଫଟୋ ଯୋଡନ୍ତୁ',
    punjabi: 'ਰਾਜਨੀਤਿਕ ਫੋਟੋਆਂ ਜੋੜੋ',
    nepali: 'राजनीतिक फोटो थप्नुहोस्',
    bengali: 'রাজনৈতিক ছবি যোগ করুন',
    kashmiri: 'سیاسی فوٹو شامل کریں',
    ladakhi: 'Political photo ཁ་སྣོན་བྱེད།',
  );

  String get addPartyLeaderPhotos => localized(
    telugu: 'పార్టీ లీడర్ ఫోటోలు జోడించండి',
    english: 'Add party leader photos',
    hindi: 'पार्टी नेता फोटो जोड़ें',
    tamil: 'கட்சி தலைவர் புகைப்படங்களை சேர்க்கவும்',
    kannada: 'ಪಾರ್ಟಿ ನಾಯಕ ಫೋಟೋಗಳನ್ನು ಸೇರಿಸಿ',
    malayalam: 'പാർട്ടി നേതാക്കളുടെ ഫോട്ടോകൾ ചേർക്കുക',
    assamese: 'দলৰ নেতাৰ ফটো যোগ কৰক',
    konkani: 'पक्ष नेत्यांचे फोटो जोडात',
    gujarati: 'પાર્ટી નેતા ફોટા ઉમેરો',
    marathi: 'पक्ष नेत्यांचे फोटो जोडा',
    meitei: 'Party leader photo hapchinbiyu',
    mizo: 'Party leader photo dah rawh',
    odia: 'ପାର୍ଟି ନେତାଙ୍କ ଫଟୋ ଯୋଡନ୍ତୁ',
    punjabi: 'ਪਾਰਟੀ ਲੀਡਰ ਫੋਟੋਆਂ ਜੋੜੋ',
    nepali: 'पार्टी नेता फोटो थप्नुहोस्',
    bengali: 'দলীয় নেতার ছবি যোগ করুন',
    kashmiri: 'پارٹی لیڈر فوٹو شامل کریں',
    ladakhi: 'Party leader photo ཁ་སྣོན་བྱེད།',
  );

  String get addYourPoster => localized(
    telugu: 'మీ పోస్టర్ జోడించండి',
    english: 'Add your poster',
    hindi: 'अपना पोस्टर जोड़ें',
    tamil: 'உங்கள் போஸ்டரை சேர்க்கவும்',
    kannada: 'ನಿಮ್ಮ ಪೋಸ್ಟರ್ ಸೇರಿಸಿ',
    malayalam: 'നിങ്ങളുടെ പോസ്റ്റർ ചേർക്കുക',
    assamese: 'আপোনাৰ পোষ্টাৰ যোগ কৰক',
    konkani: 'तुमचो पोस्टर जोडात',
    gujarati: 'તમારો પોસ્ટર ઉમેરો',
    marathi: 'तुमचा पोस्टर जोडा',
    meitei: 'Nonggi poster hapchinbiyu',
    mizo: 'I poster dah rawh',
    odia: 'ଆପଣଙ୍କ ପୋଷ୍ଟର ଯୋଡନ୍ତୁ',
    punjabi: 'ਆਪਣਾ ਪੋਸਟਰ ਜੋੜੋ',
    nepali: 'आफ्नो पोस्टर थप्नुहोस्',
    bengali: 'আপনার পোস্টার যোগ করুন',
    kashmiri: 'اپنا پوسٹر شامل کریں',
    ladakhi: 'ཁྱེད་ཀྱི poster ཁ་སྣོན་བྱེད།',
  );

  String get changeYourPoster => localized(
    telugu: 'మీ పోస్టర్ మార్చండి',
    english: 'Change your poster',
    hindi: 'अपना पोस्टर बदलें',
    tamil: 'உங்கள் போஸ்டரை மாற்றவும்',
    kannada: 'ನಿಮ್ಮ ಪೋಸ್ಟರ್ ಬದಲಿಸಿ',
    malayalam: 'നിങ്ങളുടെ പോസ്റ്റർ മാറ്റുക',
    assamese: 'আপোনাৰ পোষ্টাৰ সলনি কৰক',
    konkani: 'तुमचो पोस्टर बदलात',
    gujarati: 'તમારો પોસ્ટર બદલો',
    marathi: 'तुमचा पोस्टर बदला',
    meitei: 'Nonggi poster hongdok-u',
    mizo: 'I poster thlak rawh',
    odia: 'ଆପଣଙ୍କ ପୋଷ୍ଟର ବଦଳାନ୍ତୁ',
    punjabi: 'ਆਪਣਾ ਪੋਸਟਰ ਬਦਲੋ',
    nepali: 'आफ्नो पोस्टर बदल्नुहोस्',
    bengali: 'আপনার পোস্টার বদলান',
    kashmiri: 'اپنا پوسٹر تبدیل کریں',
    ladakhi: 'ཁྱེད་ཀྱི poster བརྗེ་བ།',
  );

  String get tapPhotoToPlaceOnPoster => localized(
    telugu: 'పోస్టర్ మీద పెట్టడానికి ఫోటోను ట్యాప్ చేయండి.',
    english: 'Tap a photo to place it on the poster.',
    hindi: 'पोस्टर पर लगाने के लिए फोटो टैप करें।',
    tamil: 'போஸ்டரில் வைக்க புகைப்படத்தை தட்டவும்.',
    kannada: 'ಪೋಸ್ಟರ್ ಮೇಲೆ ಇಡಲು ಫೋಟೋ ಟ್ಯಾಪ್ ಮಾಡಿ.',
    malayalam: 'പോസ്റ്ററിൽ വയ്ക്കാൻ ഫോട്ടോ ടാപ്പ് ചെയ്യുക.',
    assamese: 'পোষ্টাৰত ৰাখিবলৈ ফটো টেপ কৰক।',
    konkani: 'पोस्टरार दवरपाक फोटो टॅप करात.',
    gujarati: 'પોસ્ટર પર મૂકવા ફોટો ટેપ કરો.',
    marathi: 'पोस्टरवर ठेवण्यासाठी फोटो टॅप करा.',
    meitei: 'Poster-da thamnanaba photo tap tou.',
    mizo: 'Poster-ah dah tur photo tap rawh.',
    odia: 'ପୋଷ୍ଟରରେ ରଖିବାକୁ ଫଟୋ ଟ୍ୟାପ୍ କରନ୍ତୁ।',
    punjabi: 'ਪੋਸਟਰ ਤੇ ਰੱਖਣ ਲਈ ਫੋਟੋ ਟੈਪ ਕਰੋ।',
    nepali: 'पोस्टरमा राख्न फोटो ट्याप गर्नुहोस्।',
    bengali: 'পোস্টারে বসাতে ছবি ট্যাপ করুন।',
    kashmiri: 'پوسٹر پؠٹھ رکھنس خٲطرٕ فوٹو ٹیپ کریں۔',
    ladakhi: 'Poster ནང་འཇོག་པར photo ལ tap བྱེད།',
  );

  String get couldNotAddPoster => localized(
    telugu: 'మీ పోస్టర్ జోడించలేకపోయాం. మళ్లీ ప్రయత్నించండి.',
    english: 'Could not add your poster. Please try again.',
    hindi: 'आपका पोस्टर नहीं जोड़ा जा सका। फिर कोशिश करें।',
    tamil: 'உங்கள் போஸ்டரை சேர்க்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    kannada: 'ನಿಮ್ಮ ಪೋಸ್ಟರ್ ಸೇರಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'നിങ്ങളുടെ പോസ്റ്റർ ചേർക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
    assamese: 'আপোনাৰ পোষ্টাৰ যোগ কৰিব পৰা নগল। পুনৰ চেষ্টা কৰক।',
    konkani: 'तुमचो पोस्टर जोडूंक जालो ना. परत प्रयत्न करात.',
    gujarati: 'તમારો પોસ્ટર ઉમેરી શકાયો નહીં. ફરી પ્રયાસ કરો.',
    marathi: 'तुमचा पोस्टर जोडता आला नाही. पुन्हा प्रयत्न करा.',
    meitei: 'Nonggi poster hapchinba ngamdre. Amuk hotnou.',
    mizo: 'I poster dah theih loh. Ti leh rawh.',
    odia: 'ଆପଣଙ୍କ ପୋଷ୍ଟର ଯୋଡାଯାଇପାରିଲା ନାହିଁ। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
    punjabi: 'ਤੁਹਾਡਾ ਪੋਸਟਰ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    nepali: 'तपाईंको पोस्टर थप्न सकिएन। फेरि प्रयास गर्नुहोस्।',
    bengali: 'আপনার পোস্টার যোগ করা যায়নি। আবার চেষ্টা করুন।',
    kashmiri: 'تہند پوسٹر شامل نہ ہو سکیو۔ دوبارہ کوشش کریں۔',
    ladakhi: 'ཁྱེད་ཀྱི poster ཁ་སྣོན་མ་ཐུབ། ཡང་སྐྱར་ཚོད་ལྟ་བྱེད།',
  );

  String get doneLabel => localized(
    telugu: 'పూర్తయింది',
    english: 'Done',
    hindi: 'हो गया',
    tamil: 'முடிந்தது',
    kannada: 'ಮುಗಿದಿದೆ',
    malayalam: 'പൂർത്തിയായി',
    assamese: 'সম্পূৰ্ণ',
    konkani: 'जालें',
    gujarati: 'પૂર્ણ',
    marathi: 'झाले',
    meitei: 'Loire',
    mizo: 'Zo tawh',
    odia: 'ସମ୍ପୂର୍ଣ୍ଣ',
    punjabi: 'ਹੋ ਗਿਆ',
    nepali: 'सकियो',
    bengali: 'সম্পন্ন',
    kashmiri: 'مکمل',
    ladakhi: 'ཚར།',
  );

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
        _ => 'Profile & Settings',
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
        _ => 'Account',
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
        _ => 'App Settings',
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
        _ => 'Support',
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
        _ => 'Language',
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
        _ => 'Choose your app language',
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
        _ => 'Subscription / Plans',
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
        _ => 'Manage current plan and upgrades',
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
        _ => 'Photos, storage and other access',
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
        _ => 'Control alerts and updates',
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
        _ => 'Help & Support',
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
        _ => 'Get help and contact support',
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
        _ => 'About App',
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
        _ => 'App details and version info',
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
        _ => 'Logout',
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
        _ => 'Sign out logic can be connected later',
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
        _ => 'Language Settings',
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
        _ => 'Current language',
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
        _ => 'Save / Apply',
      };

  String languageName(AppLanguage value) =>
      _sanitizeDisplayText(switch (value) {
        AppLanguage.telugu => '\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41',
        AppLanguage.hindi => '\u0939\u093f\u0928\u094d\u0926\u0940',
        AppLanguage.english => 'English',
        AppLanguage.tamil => '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd',
        AppLanguage.kannada => '\u0c95\u0ca8\u0ccd\u0ca8\u0ca1',
        AppLanguage.malayalam => '\u0d2e\u0d32\u0d2f\u0d3e\u0d33\u0d02',
        AppLanguage.assamese => 'অসমীয়া',
        AppLanguage.konkani => 'कोंकणी',
        AppLanguage.gujarati => 'ગુજરાતી',
        AppLanguage.marathi => 'मराठी',
        AppLanguage.meitei => 'ꯃꯤꯇꯩꯂꯣꯟ',
        AppLanguage.mizo => 'Mizo',
        AppLanguage.odia => 'ଓଡ଼ିଆ',
        AppLanguage.punjabi => 'ਪੰਜਾਬੀ',
        AppLanguage.nepali => 'नेपाली',
        AppLanguage.bengali => 'বাংলা',
        AppLanguage.kashmiri => 'کٲشُر',
        AppLanguage.ladakhi => 'ལ་དྭགས་སྐད',
      });

  static const Map<AppLanguage, List<String>> _regionalHomeCategories =
      <AppLanguage, List<String>>{
        AppLanguage.assamese: <String>[
          'সকলো',
          'সুপ্ৰভাত',
          'শুভ দুপৰীয়া',
          'শুভ ৰাতি',
          'প্ৰেৰণাদায়ক',
          'প্ৰেমৰ উদ্ধৃতি',
          'আজিৰ বিশেষ',
          'জন্মদিন',
          'জীৱনৰ পৰামৰ্শ',
          'গীতা জ্ঞান',
          'ভক্তি',
          'মহাভাৰত',
          'বৰ্ষপূৰ্তি',
          'ভাল চিন্তা',
          'বাইবেল',
          'ইছলাম',
          'হাস্যকৌতুক',
          'অধিক',
        ],
        AppLanguage.konkani: <String>[
          'सगळें',
          'सुप्रभात',
          'शुभ दुपार',
          'शुभ रात',
          'प्रेरणादायी',
          'मोगाचे उद्धरण',
          'आयचें खास',
          'जन्मदीस',
          'जीवन सल्लो',
          'गीता ज्ञान',
          'भक्ती',
          'महाभारत',
          'वर्धापन दीस',
          'बरे विचार',
          'बायबल',
          'इस्लाम',
          'विनोद',
          'आनीक',
        ],
        AppLanguage.gujarati: <String>[
          'બધું',
          'સુપ્રભાત',
          'શુભ બપોર',
          'શુભ રાત્રી',
          'પ્રેરણાત્મક',
          'પ્રેમ કોટ્સ',
          'આજનું ખાસ',
          'જન્મદિવસ',
          'જીવન સલાહ',
          'ગીતા જ્ઞાન',
          'ભક્તિ',
          'મહાભારત',
          'વર્ષગાંઠ',
          'સારા વિચારો',
          'બાઇબલ',
          'ઇસ્લામ',
          'જોક્સ',
          'વધુ',
        ],
        AppLanguage.marathi: <String>[
          'सर्व',
          'सुप्रभात',
          'शुभ दुपार',
          'शुभ रात्री',
          'प्रेरणादायी',
          'प्रेम कोट्स',
          'आजचे विशेष',
          'वाढदिवस',
          'जीवन सल्ला',
          'गीता ज्ञान',
          'भक्ती',
          'महाभारत',
          'वर्धापनदिन',
          'चांगले विचार',
          'बायबल',
          'इस्लाम',
          'विनोद',
          'अधिक',
        ],
        AppLanguage.meitei: <String>[
          'ê¯„ê¯¨ê¯ê¯…ê¯ƒê¯›',
          'ꯒꯨꯗ ꯃꯣꯔꯅꯤꯡ',
          'ê¯’ê¯¨ê¯— ê¯‘ê¯ê¯‡ê¯”ê¯…ê¯¨ê¯Ÿ',
          'ê¯’ê¯¨ê¯— ê¯…ê¯¥ê¯ê¯ ',
          'ê¯Šê¯§ê¯’ê¯ ê¯‚ê¯›ê¯„',
          'ꯅꯨꯡꯁꯤ ꯀꯣꯠꯁ',
          'ꯉꯁꯤꯒꯤ ꯑꯈꯟꯅꯕ',
          'ꯄꯣꯛꯄ ꯅꯨꯃꯤꯠ',
          'ꯄꯨꯟꯁꯤ ꯄꯥꯎꯇꯥꯛ',
          'ꯒꯤꯇꯥ ꯈꯪꯅꯕ',
          'ꯚꯛꯇꯤ',
          'ê¯ƒê¯ê¯¥ê¯šê¯¥ê¯”ê¯‡',
          'ꯆꯍꯤ ꯃꯥꯏꯂꯥꯏ',
          'ê¯ê¯• ê¯‹ê¯¥ê¯ˆê¯œ',
          'ê¯•ê¯¥ê¯ê¯•ê¯¦ê¯œ',
          'ê¯ê¯ê¯­ê¯‚ê¯¥ê¯',
          'ê¯–ê¯£ê¯›ê¯',
          'ê¯ê¯¦ê¯Ÿê¯…',
        ],
        AppLanguage.mizo: <String>[
          'Zawng zawng',
          'Good Morning',
          'Good Afternoon',
          'Good Night',
          'Thlahlelna',
          'Hmangaihna thu',
          'Vawiin bik',
          'Piancham',
          'Nun thurawn',
          'Gita hriatna',
          'Pathian thu',
          'Mahabharata',
          'Kum cham',
          'Ngaihtuahna tha',
          'Bible',
          'Islam',
          'Nuihza',
          'Tam zawk',
        ],
        AppLanguage.odia: <String>[
          'ସବୁ',
          'ସୁପ୍ରଭାତ',
          'ଶୁଭ ଅପରାହ୍ନ',
          'ଶୁଭ ରାତ୍ରି',
          'ପ୍ରେରଣାଦାୟକ',
          'ପ୍ରେମ ଉକ୍ତି',
          'ଆଜିର ବିଶେଷ',
          'ଜନ୍ମଦିନ',
          'ଜୀବନ ପରାମର୍ଶ',
          'ଗୀତା ଜ୍ଞାନ',
          'ଭକ୍ତି',
          'ମହାଭାରତ',
          'ବାର୍ଷିକୀ',
          'ଭଲ ଚିନ୍ତା',
          'ବାଇବେଲ',
          'ଇସ୍ଲାମ',
          'ଜୋକ୍ସ',
          'ଅଧିକ',
        ],
        AppLanguage.punjabi: <String>[
          'ਸਭ',
          'ਸਤ ਸ੍ਰੀ ਅਕਾਲ ਸਵੇਰ',
          'ਸ਼ੁਭ ਦੁਪਹਿਰ',
          'ਸ਼ੁਭ ਰਾਤ',
          'ਪ੍ਰੇਰਣਾਦਾਇਕ',
          'ਪਿਆਰ ਦੇ ਕੋਟਸ',
          'ਅੱਜ ਦਾ ਖਾਸ',
          'ਜਨਮਦਿਨ',
          'ਜੀਵਨ ਸਲਾਹ',
          'ਗੀਤਾ ਗਿਆਨ',
          'ਭਗਤੀ',
          'ਮਹਾਭਾਰਤ',
          'ਵਰ੍ਹੇਗੰਢ',
          'ਚੰਗੇ ਵਿਚਾਰ',
          'ਬਾਈਬਲ',
          'ਇਸਲਾਮ',
          'ਜੋਕਸ',
          'ਹੋਰ',
        ],
        AppLanguage.nepali: <String>[
          'सबै',
          'शुभ प्रभात',
          'शुभ दिउँसो',
          'शुभ रात्री',
          'प्रेरणादायी',
          'प्रेम उद्धरण',
          'आजको विशेष',
          'जन्मदिन',
          'जीवन सल्लाह',
          'गीता ज्ञान',
          'भक्ति',
          'महाभारत',
          'वार्षिकोत्सव',
          'राम्रा विचार',
          'बाइबल',
          'इस्लाम',
          'जोक्स',
          'थप',
        ],
        AppLanguage.bengali: <String>[
          'সব',
          'সুপ্রভাত',
          'শুভ অপরাহ্ন',
          'শুভ রাত্রি',
          'অনুপ্রেরণামূলক',
          'প্রেমের উক্তি',
          'আজকের বিশেষ',
          'জন্মদিন',
          'জীবনের পরামর্শ',
          'গীতা জ্ঞান',
          'ভক্তি',
          'মহাভারত',
          'বার্ষিকী',
          'ভালো চিন্তা',
          'বাইবেল',
          'ইসলাম',
          'জোকস',
          'আরও',
        ],
        AppLanguage.kashmiri: <String>[
          'Ø³Ø§Ø±Û’',
          'صبح بخیر',
          'دوپہر بخیر',
          'شب بخیر',
          'حوصلہ افزا',
          'Ù…Ø­Ø¨Øª Ú©Û’ Ø§Ù‚ÙˆØ§Ù„',
          'آج کا خاص',
          'Ø³Ø§Ù„Ú¯Ø±Û',
          'زندگی مشورہ',
          'Ú¯ÛŒØªØ§ Ú¯ÛŒØ§Ù†',
          'Ø¹Ù‚ÛŒØ¯Øª',
          'Ù…ÛØ§Ø¨Ú¾Ø§Ø±Øª',
          'Ø³Ø§Ù„Ú¯Ø±Û ØªÙ‚Ø±ÛŒØ¨',
          'اچھے خیالات',
          'Ø¨Ø§Ø¦Ø¨Ù„',
          'Ø§Ø³Ù„Ø§Ù…',
          'Ù„Ø·ÛŒÙÛ’',
          'مزید',
        ],
        AppLanguage.ladakhi: <String>[
          'ཐམས་ཅད',
          'སྔ་དྲོ་བདེ་ལེགས',
          'ཉིན་གུང་བདེ་ལེགས',
          'མཚན་མོ་བདེ་ལེགས',
          'སེམས་ཤུགས',
          'བརྩེ་བའི་ཚིག',
          'དེ་རིང་གི་ཁྱད་པར',
          'སྐྱེས་སྐར',
          'མི་ཚེའི་སློབ་སྟོན',
          'གི་ཏཱ་ཤེས་རབ',
          'དད་པ',
          'མ་ཧཱ་བྷཱ་ར་ཏ',
          'ལོ་འཁོར',
          'བསམ་བློ་བཟང་པོ',
          'བཱའི་བལ',
          'ཨིས་ལཱམ',
          'ཀུ་རེ',
          'མང་བ',
        ],
      };

  List<String> localizedHomeCategories() =>
      (_regionalHomeCategories[language] ??
              (switch (language.supportedUiLanguage) {
                SupportedUiLanguage.telugu => const <String>[
                  '\u0c05\u0c28\u0c4d\u0c28\u0c40',
                  '\u0c36\u0c41\u0c2d\u0c4b\u0c26\u0c2f\u0c02',
                  '\u0c36\u0c41\u0c2d \u0c2e\u0c27\u0c4d\u0c2f\u0c3e\u0c39\u0c4d\u0c28\u0c02',
                  '\u0c36\u0c41\u0c2d\u0c30\u0c3e\u0c24\u0c4d\u0c30\u0c3f',
                  '\u0c2a\u0c4d\u0c30\u0c47\u0c30\u0c23\u0c3e\u0c24\u0c4d\u0c2e\u0c15',
                  '\u0c36\u0c41\u0c2d \u0c38\u0c3e\u0c2f\u0c02\u0c24\u0c4d\u0c30\u0c02',
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
                  '\u0936\u0941\u092d \u0938\u0902\u0927\u094d\u092f\u093e',
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
                  'Good Evening',
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
                  '\u0b87\u0ba9\u0bbf\u0baf \u0bae\u0bbe\u0bb2\u0bc8',
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
                  '\u0cb6\u0cc1\u0cad \u0cb8\u0c82\u0c9c\u0cc6',
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
                  '\u0d36\u0d41\u0d2d \u0d38\u0d3e\u0d2f\u0d3e\u0d39\u0d4d\u0d28\u0d02',
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
                _ => const <String>[
                  'All',
                  'Good Morning',
                  'Good Afternoon',
                  'Good Night',
                  'Motivational',
                  'Good Evening',
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
              }))
          .map((item) => _sanitizeDisplayText(item))
          .toList(growable: false);

  List<String> homeCategories() => localizedHomeCategories();
}
