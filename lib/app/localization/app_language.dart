import 'package:flutter/material.dart';

enum AppLanguage { telugu, hindi, english, tamil, kannada, malayalam }

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

  static AppLanguageScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found in widget tree.');
    return scope!;
  }

  AppLanguageController get controller => _controller;

  @override
  bool updateShouldNotify(covariant AppLanguageScope oldWidget) {
    return oldWidget.language != language || oldWidget._controller != _controller;
  }
}

extension AppLanguageContextX on BuildContext {
  AppLanguageController get languageController => AppLanguageScope.of(this).controller;
  AppLanguage get currentLanguage => AppLanguageScope.of(this).language;
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
    return switch (language) {
      AppLanguage.telugu => telugu,
      AppLanguage.hindi => hindi ?? _commonLocalizedFallback(english) ?? english,
      AppLanguage.english => english,
      AppLanguage.tamil => tamil ?? _commonLocalizedFallback(english) ?? english,
      AppLanguage.kannada => kannada ?? _commonLocalizedFallback(english) ?? english,
      AppLanguage.malayalam => malayalam ?? _commonLocalizedFallback(english) ?? english,
    };
  }

  String? _commonLocalizedFallback(String english) {
    switch (language) {
      case AppLanguage.hindi:
        return _commonHindiFallback(english);
      case AppLanguage.tamil:
        return _commonTamilFallback(english);
      case AppLanguage.kannada:
        return _commonKannadaFallback(english);
      case AppLanguage.malayalam:
        return _commonMalayalamFallback(english);
      case AppLanguage.telugu:
      case AppLanguage.english:
        return null;
    }
  }

  String? _commonHindiFallback(String english) {
    return switch (english) {
      'Add Photo' => 'फोटो जोड़ें',
      'Text' => 'टेक्स्ट',
      'Stickers' => 'स्टिकर्स',
      'Background' => 'बैकग्राउंड',
      'Layers' => 'लेयर्स',
      'Adjust' => 'एडजस्ट',
      'Crop' => 'क्रॉप',
      'Eraser' => 'इरेज़र',
      'Remove BG' => 'बीजी हटाएं',
      'Edit' => 'एडिट',
      'Fonts' => 'फॉन्ट्स',
      'Options' => 'ऑप्शन्स',
      'Style' => 'स्टाइल',
      'Effects' => 'इफेक्ट्स',
      'Size' => 'साइज़',
      'Line' => 'लाइन',
      'Letter' => 'लेटर',
      'Opacity' => 'ओपेसिटी',
      'Curve' => 'कर्व',
      'Stroke' => 'स्ट्रोक',
      'Shadow' => 'शैडो',
      'Blur' => 'ब्लर',
      'Offset' => 'ऑफसेट',
      'Back' => 'वापस',
      'Undo' => 'अनडू',
      'Redo' => 'रीडू',
      'Drafts' => 'ड्राफ्ट्स',
      'Export' => 'एक्सपोर्ट',
      'Saving...' => 'सेव हो रहा है...',
      'Send back' => 'पीछे भेजें',
      'Bring front' => 'आगे लाएं',
      'Duplicate selected' => 'डुप्लिकेट',
      'Delete selected' => 'डिलीट',
      'Photo quick actions' => 'फोटो क्विक ऐक्शन्स',
      'Selected photo' => 'चुनी हुई फोटो',
      'Text tools' => 'टेक्स्ट टूल्स',
      'Brush' => 'ब्रश',
      'Soft' => 'सॉफ्ट',
      'Strength' => 'स्ट्रेंथ',
      'Reset' => 'रीसेट',
      'Apply' => 'अप्लाई',
      'Applying...' => 'अप्लाई हो रहा है...',
      'Erase' => 'मिटाएं',
      'Restore' => 'रीस्टोर',
      'Brightness' => 'ब्राइटनेस',
      'Contrast' => 'कॉन्ट्रास्ट',
      'Saturation' => 'सैचुरेशन',
      'Free' => 'फ्री',
      'Elements' => 'एलिमेंट्स',
      'Search elements' => 'एलिमेंट्स खोजें',
      'Selected' => 'चुना गया',
      'Hidden' => 'छिपा हुआ',
      'Locked' => 'लॉक्ड',
      'Show' => 'दिखाएं',
      'Hide' => 'छिपाएं',
      'Unlock' => 'अनलॉक',
      'Lock' => 'लॉक',
      'Delete' => 'डिलीट',
      'Share' => 'शेयर',
      'Select a photo first' => 'पहले एक फोटो चुनें',
      'Selected image could not be loaded' => 'चुनी गई इमेज लोड नहीं हुई',
      'Canvas is empty' => 'कैनवास खाली है',
      'Cancel' => 'रद्द करें',
      'Yes, export' => 'हाँ, एक्सपोर्ट करें',
      'Crop mode' => 'क्रॉप मोड',
      'Eraser mode' => 'इरेज़र मोड',
      'Adjust mode' => 'एडजस्ट मोड',
      'Text styling' => 'टेक्स्ट स्टाइलिंग',
      'Text selected' => 'टेक्स्ट चुना गया',
      'Photo selected' => 'फोटो चुनी गई',
      'Object selected' => 'ऑब्जेक्ट चुना गया',
      _ => null,
    };
  }

  String? _commonTamilFallback(String english) {
    return switch (english) {
      'Add Photo' => 'புகைப்படம் சேர்க்க',
      'Text' => 'உரை',
      'Stickers' => 'ஸ்டிக்கர்கள்',
      'Background' => 'பின்னணி',
      'Layers' => 'லேயர்கள்',
      'Adjust' => 'அட்ஜஸ்ட்',
      'Crop' => 'கிராப்',
      'Eraser' => 'இரேசர்',
      'Remove BG' => 'பின்புலம் நீக்கு',
      'Edit' => 'திருத்து',
      'Fonts' => 'எழுத்துருக்கள்',
      'Options' => 'விருப்பங்கள்',
      'Style' => 'ஸ்டைல்',
      'Effects' => 'எஃபெக்ட்ஸ்',
      'Size' => 'அளவு',
      'Line' => 'வரி',
      'Letter' => 'எழுத்து',
      'Opacity' => 'ஒப்பாசிட்டி',
      'Curve' => 'வளைவு',
      'Stroke' => 'ஸ்ட்ரோக்',
      'Shadow' => 'நிழல்',
      'Blur' => 'ப்ளர்',
      'Offset' => 'ஆஃப்செட்',
      'Back' => 'பின்',
      'Undo' => 'அன்டூ',
      'Redo' => 'ரீடூ',
      'Drafts' => 'வரைவுகள்',
      'Export' => 'ஏற்றுமதி',
      'Saving...' => 'சேமிக்கிறது...',
      'Reset' => 'ரீசெட்',
      'Apply' => 'அப்ளை',
      'Applying...' => 'அப்ளை ஆகிறது...',
      'Erase' => 'அழி',
      'Restore' => 'மீட்டமை',
      'Brightness' => 'பிரைட்நஸ்',
      'Contrast' => 'கான்ட்ராஸ்ட்',
      'Saturation' => 'சாசுரேஷன்',
      'Share' => 'பகிர்',
      'Select a photo first' => 'முதலில் ஒரு புகைப்படத்தைத் தேர்ந்தெடுக்கவும்',
      'Canvas is empty' => 'கேன்வாஸ் காலியாக உள்ளது',
      'Cancel' => 'ரத்து',
      'Yes, export' => 'ஆம், ஏற்றுமதி செய்',
      _ => null,
    };
  }

  String? _commonKannadaFallback(String english) {
    return switch (english) {
      'Add Photo' => 'ಫೋಟೋ ಸೇರಿಸಿ',
      'Text' => 'ಪಠ್ಯ',
      'Stickers' => 'ಸ್ಟಿಕರ್ಸ್',
      'Background' => 'ಹಿನ್ನೆಲೆ',
      'Layers' => 'ಲೇಯರ್ಸ್',
      'Adjust' => 'ಅಡ್ಜಸ್ಟ್',
      'Crop' => 'ಕ್ರಾಪ್',
      'Eraser' => 'ಇರೇಸರ್',
      'Remove BG' => 'ಹಿನ್ನೆಲೆ ತೆಗೆಯಿರಿ',
      'Edit' => 'ಎಡಿಟ್',
      'Fonts' => 'ಫಾಂಟ್ಸ್',
      'Options' => 'ಆಯ್ಕೆಗಳು',
      'Style' => 'ಸ್ಟೈಲ್',
      'Effects' => 'ಇಫೆಕ್ಟ್ಸ್',
      'Size' => 'ಗಾತ್ರ',
      'Line' => 'ಲೈನ್',
      'Letter' => 'ಅಕ್ಷರ',
      'Opacity' => 'ಒಪಾಸಿಟಿ',
      'Curve' => 'ಕರ್ವ್',
      'Stroke' => 'ಸ್ಟ್ರೋಕ್',
      'Shadow' => 'ನೆರಳು',
      'Blur' => 'ಬ್ಲರ್',
      'Offset' => 'ಆಫ್‌ಸೆಟ್',
      'Back' => 'ಹಿಂದೆ',
      'Undo' => 'ಅನ್ಡೂ',
      'Redo' => 'ರೀಡೂ',
      'Drafts' => 'ಡ್ರಾಫ್ಟ್ಸ್',
      'Export' => 'ಎಕ್ಸ್‌ಪೋರ್ಟ್',
      'Saving...' => 'ಸೇವ್ ಆಗುತ್ತಿದೆ...',
      'Reset' => 'ರೀಸೆಟ್',
      'Apply' => 'ಅಪ್ಲೈ',
      'Applying...' => 'ಅಪ್ಲೈ ಆಗುತ್ತಿದೆ...',
      'Erase' => 'ಅಳಿಸಿ',
      'Restore' => 'ಮರುಸ್ಥಾಪನೆ',
      'Brightness' => 'ಬ್ರೈಟ್‌ನೆಸ್',
      'Contrast' => 'ಕಾನ್ಟ್ರಾಸ್ಟ್',
      'Saturation' => 'ಸ್ಯಾಚುರೇಶನ್',
      'Share' => 'ಹಂಚಿಕೆ',
      'Select a photo first' => 'ಮೊದಲು ಒಂದು ಫೋಟೋ ಆಯ್ಕೆಮಾಡಿ',
      'Canvas is empty' => 'ಕ್ಯಾನ್ವಾಸ್ ಖಾಲಿಯಾಗಿದೆ',
      'Cancel' => 'ರದ್ದು',
      'Yes, export' => 'ಹೌದು, ಎಕ್ಸ್‌ಪೋರ್ಟ್ ಮಾಡಿ',
      _ => null,
    };
  }

  String? _commonMalayalamFallback(String english) {
    return switch (english) {
      'Add Photo' => 'ഫോട്ടോ ചേർക്കുക',
      'Text' => 'ടെക്സ്റ്റ്',
      'Stickers' => 'സ്റ്റിക്കറുകൾ',
      'Background' => 'ബാക്ക്ഗ്രൗണ്ട്',
      'Layers' => 'ലെയേഴ്സ്',
      'Adjust' => 'അഡ്ജസ്റ്റ്',
      'Crop' => 'ക്രോപ്പ്',
      'Eraser' => 'ഇറേസർ',
      'Remove BG' => 'ബാക്ക്ഗ്രൗണ്ട് നീക്കുക',
      'Edit' => 'എഡിറ്റ്',
      'Fonts' => 'ഫോണ്ടുകൾ',
      'Options' => 'ഓപ്ഷനുകൾ',
      'Style' => 'സ്റ്റൈൽ',
      'Effects' => 'ഇഫക്റ്റ്സ്',
      'Size' => 'വലിപ്പം',
      'Line' => 'ലൈൻ',
      'Letter' => 'അക്ഷരം',
      'Opacity' => 'ഒപാസിറ്റി',
      'Curve' => 'കർവ്',
      'Stroke' => 'സ്ട്രോക്ക്',
      'Shadow' => 'നിഴൽ',
      'Blur' => 'ബ്ലർ',
      'Offset' => 'ഓഫ്‌സെറ്റ്',
      'Back' => 'പിന്നിലേക്ക്',
      'Undo' => 'അൺഡൂ',
      'Redo' => 'റീഡൂ',
      'Drafts' => 'ഡ്രാഫ്റ്റുകൾ',
      'Export' => 'എക്സ്പോർട്ട്',
      'Saving...' => 'സേവ് ചെയ്യുന്നു...',
      'Reset' => 'റീസെറ്റ്',
      'Apply' => 'അപ്ലൈ',
      'Applying...' => 'അപ്ലൈ ചെയ്യുന്നു...',
      'Erase' => 'മായ്ക്കുക',
      'Restore' => 'പുനഃസ്ഥാപിക്കുക',
      'Brightness' => 'ബ്രൈറ്റ്‌നസ്',
      'Contrast' => 'കോൺട്രാസ്റ്റ്',
      'Saturation' => 'സാചുറേഷൻ',
      'Share' => 'ഷെയർ',
      'Select a photo first' => 'ആദ്യം ഒരു ഫോട്ടോ തിരഞ്ഞെടുക്കുക',
      'Canvas is empty' => 'കാൻവാസ് കാലിയാണു',
      'Cancel' => 'റദ്ദാക്കുക',
      'Yes, export' => 'അതെ, എക്സ്പോർട്ട് ചെയ്യുക',
      _ => null,
    };
  }

  String get splashTagline => switch (language) {
    AppLanguage.telugu => 'ఎంచుకోండి, మీ పేరుతో షేర్ చేయండి',
    AppLanguage.hindi => 'चुनें, अपने नाम के साथ शेयर करें',
    AppLanguage.english => 'Choose and share with your name',
    AppLanguage.tamil => '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0baa\u0bc6\u0baf\u0bb0\u0bcd \u0b89\u0b9f\u0ba9\u0bcd \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bc1 \u0baa\u0b95\u0bbf\u0bb0\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => '\u0ca8\u0cbf\u0cae\u0ccd\u0cae \u0cb9\u0cc6\u0cb8\u0cb0\u0cbf\u0ca8 \u0c9c\u0cca\u0ca4\u0cc6 \u0c86\u0caf\u0ccd\u0c95\u0cc6 \u0cae\u0abe\u0ca1\u0cbf \u0cb9\u0c82\u0c9a\u0cbf',
    AppLanguage.malayalam => '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 \u0d2a\u0d47\u0d30\u0d3f\u0d28\u0d4a\u0d2a\u0dcd\u0d2a\u0d02 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d24\u0d4d \u0d36\u0d47\u0d2f\u0d7c \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d42',
  };

  String get languageScreenTitle => switch (language) {
    AppLanguage.telugu => 'మీ భాషను ఎంచుకోండి',
    AppLanguage.hindi => 'अपनी भाषा चुनें',
    AppLanguage.english => 'Choose your language',
    AppLanguage.tamil => '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0bae\u0bca\u0bb4\u0bbf\u0baf\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => '\u0ca8\u0cbf\u0cae\u0ccd\u0cae \u0cad\u0bbe\u0cb7\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0abe\u0ca1\u0cbf',
    AppLanguage.malayalam => '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 \u0d2d\u0d3e\u0d37 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d42',
  };

  String get languageScreenSubtitle => switch (language) {
    AppLanguage.telugu =>
      'యాప్‌లో మీకు కావాల్సిన భాషను ఎంచుకోండి. తర్వాత కూడా మార్చుకోవచ్చు.',
    AppLanguage.hindi =>
      'ऐप में अपनी पसंद की भाषा चुनें। बाद में भी बदल सकते हैं।',
    AppLanguage.english =>
      'Choose the language you want in the app. You can change it later too.',
    AppLanguage.tamil =>
      '\u0b86\u0baa\u0bcd\u0baa\u0bbf\u0bb2\u0bcd \u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0bb5\u0bc7\u0ba3\u0bcd\u0b9f\u0bbf\u0baf \u0bae\u0bca\u0bb4\u0bbf\u0baf\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd. \u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0bb0\u0bcd \u0bae\u0bbe\u0bb1\u0bcd\u0bb1\u0bb5\u0bc1\u0bae\u0bcd \u0bae\u0bc1\u0b9f\u0bbf\u0baf\u0bc1\u0bae\u0bcd.',
    AppLanguage.kannada =>
      '\u0c86\u0ccd\u0caf\u0ccd\u0caa\u0ccd\u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0ca8\u0cbf\u0cae\u0c97\u0cc6 \u0cac\u0cc7\u0c95\u0cbe\u0ca6 \u0cad\u0bbe\u0cb7\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0abe\u0ca1\u0cbf. \u0ca8\u0c82\u0ca4\u0cb0 \u0cb8\u0cb9 \u0cac\u0ca6\u0cb2\u0cbe\u0caf\u0cbf\u0cb8\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
    AppLanguage.malayalam =>
      '\u0d06\u0d2a\u0d4d\u0d2a\u0d3f\u0d32\u0d4d \u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d4d\u0d15\u0d4d\u0d15\u0d4d \u0d35\u0d47\u0d23\u0d4d\u0d1f \u0d2d\u0d3e\u0d37 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d42. \u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d40\u0d1f\u0d4d \u0d2e\u0d3e\u0d31\u0d4d\u0d31\u0d3e\u0d28\u0d41\u0d02 \u0d15\u0d34\u0d3f\u0d2f\u0d41\u0d02.',
  };

  String get continueLabel => switch (language) {
    AppLanguage.telugu => 'కొనసాగించండి',
    AppLanguage.hindi => 'जारी रखें',
    AppLanguage.english => 'Continue',
    AppLanguage.tamil => '\u0ba4\u0bca\u0b9f\u0bb0\u0bb5\u0bc1\u0bae\u0bcd',
    AppLanguage.kannada => '\u0bae\u0cc1\u0c82\u0ca6\u0cc1\u0cb5\u0cb0\u0cbf\u0cb8\u0cbf',
    AppLanguage.malayalam => '\u0d24\u0d41\u0d1f\u0d30\u0d41\u0d15',
  };

  String get onboardingNext => switch (language) {
    AppLanguage.telugu => 'తదుపరి',
    AppLanguage.hindi => 'आगे',
    AppLanguage.english => 'Next',
    AppLanguage.tamil => '\u0b85\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0ba4\u0bc1',
    AppLanguage.kannada => '\u0cae\u0cc1\u0c82\u0ca6\u0cc6',
    AppLanguage.malayalam => '\u0d05\u0d1f\u0d41\u0d24\u0d4d\u0d24\u0d24\u0d4d',
  };

  String get onboardingGetStarted => switch (language) {
    AppLanguage.telugu => 'ప్రారంభించండి',
    AppLanguage.hindi => 'शुरू करें',
    AppLanguage.english => 'Get Started',
    AppLanguage.tamil => '\u0ba4\u0bca\u0b9f\u0b99\u0bcd\u0b95\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => '\u0caa\u0ccd\u0cb0\u0cbe\u0cb0\u0c82\u0cad\u0cbf\u0cb8\u0cbf',
    AppLanguage.malayalam => '\u0d24\u0d41\u0d1f\u0d19\u0d4d\u0d19\u0d41\u0d15',
  };

  String get onboardingSkip => switch (language) {
    AppLanguage.telugu => 'స్కిప్',
    AppLanguage.hindi => 'स्किप',
    AppLanguage.english => 'Skip',
    AppLanguage.tamil => '\u0ba4\u0bb5\u0bbf\u0bb0\u0bcd',
    AppLanguage.kannada => '\u0cac\u0cbf\u0c9f\u0ccd\u0c9f\u0cc1\u0cac\u0cbf\u0ca1\u0cbf',
    AppLanguage.malayalam => '\u0d38\u0d4d\u0d15\u0d3f\u0d2a\u0d4d',
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
    AppLanguage.english => const <({IconData icon, String title, String desc, List<Color> colors})>[
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
    AppLanguage.tamil => const <({IconData icon, String title, String desc, List<Color> colors})>[
        (
          icon: Icons.auto_awesome_rounded,
          title: '\u0b85\u0bb4\u0b95\u0bbe\u0ba9 \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd\u0b95\u0bb3\u0bc8 \u0b8e\u0bb3\u0bbf\u0ba4\u0bbe\u0b95 \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
          desc:
              '\u0ba4\u0baf\u0bbe\u0bb0\u0bbe\u0ba9 templates-\u0b90 \u0baa\u0baf\u0ba9\u0bcd\u0baa\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0bbf, \u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd \u0baa\u0bc6\u0baf\u0bb0\u0bcd \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0ba4\u0bcd\u0ba4\u0bc8 \u0b9a\u0bc7\u0bb0\u0bcd\u0ba4\u0bcd\u0ba4\u0bc1 \u0b89\u0b9f\u0ba9\u0bc7 \u0b89\u0bb0\u0bc1\u0bb5\u0bbe\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd.',
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF2563EB)],
        ),
        (
          icon: Icons.style_rounded,
          title: '\u0b87\u0bb2\u0bb5\u0b9a \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd premium \u0b9f\u0bbf\u0b9a\u0bc8\u0ba9\u0bcd\u0b95\u0bb3\u0bcd \u0b92\u0bb0\u0bc7 \u0b87\u0b9f\u0ba4\u0bcd\u0ba4\u0bbf\u0bb2\u0bcd',
          desc:
              '\u0ba4\u0bbf\u0ba9\u0ba8\u0bcd\u0ba4\u0bcb\u0bb1\u0bc1\u0bae\u0bcd \u0baa\u0bc1\u0ba4\u0bbf\u0baf categories, festival posters \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0b9a\u0bbf\u0bb1\u0baa\u0bcd\u0baa\u0bbe\u0ba9 \u0b9f\u0bbf\u0b9a\u0bc8\u0ba9\u0bcd\u0b95\u0bb3\u0bc8 \u0b92\u0bb0\u0bc7 \u0b86\u0baa\u0bcd\u0baa\u0bbf\u0bb2\u0bcd \u0baa\u0bc6\u0bb1\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd.',
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF10B981)],
        ),
        (
          icon: Icons.share_rounded,
          title: '\u0baa\u0b95\u0bbf\u0bb0\u0bb5\u0bc1\u0bae\u0bcd download \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bb5\u0bc1\u0bae\u0bcd \u0b8e\u0bb3\u0bbf\u0ba4\u0bc1',
          desc:
              '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd poster-\u0b90 edit \u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bc1 WhatsApp, Facebook, Instagram-\u0bb2\u0bcd \u0b8e\u0bb3\u0bbf\u0ba4\u0bbe\u0b95 \u0baa\u0b95\u0bbf\u0bb0\u0bb2\u0bbe\u0bae\u0bcd.',
          colors: <Color>[Color(0xFFEC4899), Color(0xFFF97316)],
        ),
      ],
    AppLanguage.kannada => const <({IconData icon, String title, String desc, List<Color> colors})>[
        (
          icon: Icons.auto_awesome_rounded,
          title: '\u0cb8\u0cc1\u0ca6\u0ccd\u0ca6\u0cb0 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0cb8\u0cc1\u0cb2\u0cad\u0cb5\u0cbe\u0c97\u0cbf \u0cb8\u0cc3\u0cb7\u0ccd\u0c9f\u0cbf\u0cb8\u0cbf',
          desc:
              '\u0cb8\u0cbf\u0ca6\u0ccd\u0ca7 templates \u0c85\u0ca8\u0ccd\u0ca8\u0cc1 \u0cac\u0cb3\u0cb8\u0cbf, \u0ca8\u0cbf\u0cae\u0ccd\u0cae \u0cb9\u0cc6\u0cb8\u0cb0\u0cc1 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 photo \u0cb8\u0cc7\u0cb0\u0cbf\u0cb8\u0cbf \u0c95\u0ccd\u0cb7\u0ca3\u0ca6\u0cb2\u0ccd\u0cb2\u0cc7 \u0cb8\u0cc3\u0cb7\u0ccd\u0c9f\u0cbf\u0cb8\u0cbf.',
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF2563EB)],
        ),
        (
          icon: Icons.style_rounded,
          title: '\u0c89\u0c9a\u0cbf\u0ca4 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 premium \u0ca1\u0cbf\u0c9c\u0cc8\u0ca8\u0ccd\u0c97\u0cb3\u0cc1 \u0c92\u0c82\u0ca6\u0cc7 \u0c9c\u0cbe\u0c97\u0ca6\u0cb2\u0ccd\u0cb2\u0cbf',
          desc:
              '\u0ca6\u0cbf\u0ca8\u0ca8\u0cbf\u0ca4\u0ccd\u0caf categories, festival posters \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cb5\u0cbf\u0cb6\u0cc7\u0cb7 \u0ca1\u0cbf\u0c9c\u0cc8\u0ca8\u0ccd\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0c92\u0c82\u0ca6\u0cc7 app-\u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0caa\u0ca1\u0cc6\u0caf\u0cbf\u0cb0\u0cbf.',
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF10B981)],
        ),
        (
          icon: Icons.share_rounded,
          title: '\u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cca\u0cb3\u0ccd\u0cb3\u0cc1\u0cb5\u0cc1\u0ca6\u0cc1 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 download \u0cae\u0cbe\u0ca1\u0cc1\u0cb5\u0cc1\u0ca6\u0cc1 \u0cb8\u0cc1\u0cb2\u0cad',
          desc:
              '\u0ca8\u0cbf\u0cae\u0ccd\u0cae poster-\u0ca8\u0ccd\u0ca8\u0cc1 edit \u0cae\u0cbe\u0ca1\u0cbf WhatsApp, Facebook \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 Instagram-\u0cb2\u0ccd\u0cb2\u0cbf \u0cb8\u0cc1\u0cb2\u0cad\u0cb5\u0cbe\u0c97\u0cbf share \u0cae\u0cbe\u0ca1\u0cbf.',
          colors: <Color>[Color(0xFFEC4899), Color(0xFFF97316)],
        ),
      ],
    AppLanguage.malayalam => const <({IconData icon, String title, String desc, List<Color> colors})>[
        (
          icon: Icons.auto_awesome_rounded,
          title: '\u0d2d\u0d19\u0d4d\u0d17\u0d3f\u0d2f\u0d41\u0d33\u0d4d\u0d33 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d31\u0d41\u0d15\u0d33\u0d4d \u0d0e\u0d33\u0d41\u0daa\u0d4d\u0d2a\u0d24\u0d4d\u0d24\u0d3f\u0d32\u0d4d \u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d15\u0d4d\u0d15\u0d41',
          desc:
              '\u0d24\u0d2f\u0d4d\u0d2f\u0d3e\u0d31\u0d3e\u0d2f templates \u0d09\u0d2a\u0d2f\u0d4b\u0d17\u0d3f\u0d1a\u0d4d\u0d1a\u0d4d, \u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 \u0d2a\u0d47\u0d30\u0d41\u0d02 photo-\u0d2f\u0d41\u0d02 \u0d1a\u0d47\u0d30\u0d4d\u0d24\u0d4d \u0d09\u0d1f\u0d28\u0d4d \u0d38\u0d43\u0d37\u0d4d\u0d1f\u0d3f\u0d15\u0d4d\u0d15\u0d42.',
          colors: <Color>[Color(0xFF7C3AED), Color(0xFF2563EB)],
        ),
        (
          icon: Icons.style_rounded,
          title: '\u0d09\u0d1a\u0d3f\u0d24\u0d35\u0d41\u0d02 premium \u0d21\u0d3f\u0d38\u0d48\u0d28\u0d41\u0d15\u0d33\u0d41\u0d02 \u0d12\u0d30\u0d47 \u0d38\u0d4d\u0d25\u0d32\u0d24\u0d4d\u0d24\u0d4d',
          desc:
              '\u0d26\u0d3f\u0d28\u0d82\u0d24\u0d4b\u0d31\u0d41\u0d02 categories, festival posters, \u0d2a\u0d4d\u0d30\u0d24\u0d4d\u0d2f\u0d47\u0d15 \u0d21\u0d3f\u0d38\u0d48\u0d28\u0d41\u0d15\u0d33\u0d4d \u0d0e\u0d32\u0d4d\u0d32\u0d3e\u0d02 \u0d12\u0d30\u0d47 app-\u0d32\u0d4d \u0d32\u0d2d\u0d4d\u0d2f\u0d2e\u0d3e\u0d15\u0d41\u0d02.',
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF10B981)],
        ),
        (
          icon: Icons.share_rounded,
          title: '\u0d2a\u0d19\u0d4d\u0d15\u0d3f\u0d1f\u0d41\u0d15\u0d2f\u0d41\u0d02 download \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d41\u0d15\u0d2f\u0d41\u0d02 \u0d0e\u0d33\u0d41\u0daa\u0d4d\u0d2a\u0d02',
          desc:
              '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 poster edit \u0d1a\u0d46\u0d2f\u0d4d\u0d24\u0d4d WhatsApp, Facebook, Instagram-\u0d32\u0d4d \u0d35\u0d32\u0d30\u0d46 \u0d0e\u0d33\u0d41\u0daa\u0d4d\u0d2a\u0d24\u0d4d\u0d24\u0d3f\u0d32\u0d4d share \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0dbe\u0d02.',
          colors: <Color>[Color(0xFFEC4899), Color(0xFFF97316)],
        ),
      ],
  };

  String get loginWelcome => switch (language) {
    AppLanguage.telugu => 'Mana Poster కి స్వాగతం',
    AppLanguage.hindi => 'Mana Poster में आपका स्वागत है',
    AppLanguage.english => 'Welcome to Mana Poster',
    AppLanguage.tamil => '\u0bae\u0ba9\u0bbe \u0baa\u0bcb\u0bb8\u0bcd\u0b9f\u0bb0\u0bcd \u0b86\u0baa\u0bcd\u0baa\u0bc1\u00b95\u0bcd\u0b95\u0bc1 \u0bb5\u0bb0\u0bb5\u0bc7\u0bb1\u0bcd\u0baa\u0bc1',
    AppLanguage.kannada => '\u0cae\u0ca8 \u0caa\u0ccb\u0cb8\u0ccd\u0c9f\u0cb0\u0ccd\u200c\u0c97\u0cc6 \u0cb8\u0ccd\u0cb5\u0cbe\u0c97\u0ca4',
    AppLanguage.malayalam => '\u0d2e\u0d28 \u0d2a\u0d4b\u0d38\u0d4d\u0d31\u0d31\u0d3f\u0d32\u0d47\u0d15\u0d4d\u0d15\u0d4d \u0d38\u0d4d\u0d35\u0d3e\u0d17\u0d24\u0d02',
  };

  String get loginSubtitle => switch (language) {
    AppLanguage.telugu =>
      'Google లేదా Email తో login అయి మీ పోస్టర్ ప్రయాణాన్ని ప్రారంభించండి.',
    AppLanguage.hindi =>
      'Google या Email से login करके अपनी poster journey शुरू करें.',
    AppLanguage.english =>
      'Login with Google or Email and start your poster journey.',
    AppLanguage.tamil =>
      'Google \u0b85\u0bb2\u0bcd\u0bb2\u0ba4\u0bc1 Email \u0bae\u0bc2\u0bb2\u0bae\u0bcd login \u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bc1 \u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd poster \u0baa\u0baf\u0ba3\u0ba4\u0bcd\u0ba4\u0bc8 \u0ba4\u0bca\u0b9f\u0b99\u0bcd\u0b95\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd.',
    AppLanguage.kannada =>
      'Google \u0c85\u0ca5\u0cb5\u0cbe Email \u0cae\u0cc2\u0cb2\u0c95 login \u0c86\u0c97\u0cbf \u0ca8\u0cbf\u0cae\u0ccd\u0cae poster \u0caf\u0cbe\u0ca4\u0ccd\u0cb0\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0caa\u0ccd\u0cb0\u0cbe\u0cb0\u0c82\u0cad\u0cbf\u0cb8\u0cbf.',
    AppLanguage.malayalam =>
      'Google \u0d05\u0d32\u0d4d\u0d32\u0d46\u0d19\u0d4d\u0d15\u0d3f\u0d32\u0d4d Email \u0d35\u0d34\u0d3f login \u0d1a\u0d46\u0d2f\u0d4d\u0d24\u0d4d \u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 poster \u0d2f\u0d3e\u0d24\u0d4d\u0d30 \u0d24\u0d41\u0d1f\u0d19\u0d4d\u0d19\u0d42.',
  };

  String get loginLabel => switch (language) {
    AppLanguage.telugu => 'Login',
    AppLanguage.hindi => 'Login',
    AppLanguage.english => 'Login',
    AppLanguage.tamil => '\u0b89\u0bb3\u0bcd\u0ba8\u0bc1\u0bb4\u0bc8',
    AppLanguage.kannada => '\u0cb2\u0cbe\u0c97\u0cbf\u0ca8\u0ccd',
    AppLanguage.malayalam => '\u0d32\u0d4b\u0d17\u0d3f\u0d7b',
  };

  String get signUpLabel => switch (language) {
    AppLanguage.telugu => 'Sign Up',
    AppLanguage.hindi => 'Sign Up',
    AppLanguage.english => 'Sign Up',
    AppLanguage.tamil => '\u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd',
    AppLanguage.kannada => '\u0cb8\u0cc8\u0ca8\u0ccd \u0c85\u0baa\u0ccd',
    AppLanguage.malayalam => '\u0d38\u0d48\u0d7b \u0d05\u0d2a\u0d4d',
  };

  String get googleContinue => switch (language) {
    AppLanguage.telugu => 'Google తో కొనసాగించండి',
    AppLanguage.hindi => 'Google से जारी रखें',
    AppLanguage.english => 'Continue with Google',
    AppLanguage.tamil => 'Google \u0b89\u0b9f\u0ba9\u0bcd \u0ba4\u0bca\u0b9f\u0bb0\u0bb5\u0bc1\u0bae\u0bcd',
    AppLanguage.kannada => 'Google \u0c9c\u0cca\u0ca4\u0cc6 \u0bae\u0cc1\u0c82\u0ca6\u0cc1\u0cb5\u0cb0\u0cbf\u0cb8\u0cbf',
    AppLanguage.malayalam => 'Google \u0d09\u0d2e\u0d3e\u0d2f\u0d3f \u0d24\u0d41\u0d1f\u0d30\u0d41\u0d15',
  };

  String get emailAddress => switch (language) {
    AppLanguage.telugu => 'Email address',
    AppLanguage.hindi => 'Email address',
    AppLanguage.english => 'Email address',
    AppLanguage.tamil => 'Email address',
    AppLanguage.kannada => 'Email address',
    AppLanguage.malayalam => 'Email address',
  };

  String get password => switch (language) {
    AppLanguage.telugu => 'Password',
    AppLanguage.hindi => 'Password',
    AppLanguage.english => 'Password',
    AppLanguage.tamil => 'Password',
    AppLanguage.kannada => 'Password',
    AppLanguage.malayalam => 'Password',
  };

  String get forgotPassword => switch (language) {
    AppLanguage.telugu => 'Forgot Password',
    AppLanguage.hindi => 'Forgot Password',
    AppLanguage.english => 'Forgot Password',
    AppLanguage.tamil => 'Forgot Password',
    AppLanguage.kannada => 'Forgot Password',
    AppLanguage.malayalam => 'Forgot Password',
  };

  String get noAccount => switch (language) {
    AppLanguage.telugu => 'Account లేదా?',
    AppLanguage.hindi => 'Account नहीं है?',
    AppLanguage.english => 'Account or not?',
    AppLanguage.tamil => '\u0b95\u0ba3\u0b95\u0bcd\u0b95\u0bc1 \u0b87\u0bb2\u0bcd\u0bb2\u0bc8\u0baf\u0bbe?',
    AppLanguage.kannada => '\u0c96\u0cbe\u0ca4\u0cc6 \u0c87\u0cb2\u0ccd\u0cb5\u0cc7?',
    AppLanguage.malayalam => '\u0d05\u0d15\u0d4d\u0d15\u0d57\u0d23\u0d4d\u0d1f\u0d4d \u0d07\u0d32\u0d4d\u0d32\u0d47?',
  };

  String get alreadyHaveAccount => switch (language) {
    AppLanguage.telugu => 'ఇప్పటికే account ఉందా?',
    AppLanguage.hindi => 'Already have an account?',
    AppLanguage.english => 'Already have an account?',
    AppLanguage.tamil => '\u0b8f\u0bb1\u0bcd\u0b95\u0ba9\u0bb5\u0bc7 \u0b92\u0bb0\u0bc1 \u0b95\u0ba3\u0b95\u0bcd\u0b95\u0bc1 \u0b89\u0bb3\u0bcd\u0bb3\u0ba4\u0bbe?',
    AppLanguage.kannada => '\u0c88\u0c97\u0abe\u0cb2\u0cc7 \u0c92\u0c82\u0ca6\u0cc1 \u0c96\u0cbe\u0ca4\u0cc6 \u0c87\u0ca6\u0cc6\u0caf\u0cbe?',
    AppLanguage.malayalam => '\u0d07\u0d24\u0d3f\u0d28\u0d95\u0d02 \u0d12\u0d30\u0d41 \u0d05\u0d15\u0d4d\u0d15\u0d57\u0d23\u0d4d\u0d1f\u0d4d \u0d09\u0d23\u0d4d\u0d1f\u0d4b?',
  };

  String get loginWithEmail => switch (language) {
    AppLanguage.telugu => 'Email తో Login',
    AppLanguage.hindi => 'Email से Login',
    AppLanguage.english => 'Login with Email',
    AppLanguage.tamil => 'Email \u0bae\u0bc2\u0bb2\u0bae\u0bcd \u0b89\u0bb3\u0bcd\u0ba8\u0bc1\u0bb4\u0bc8',
    AppLanguage.kannada => 'Email \u0cae\u0cc2\u0cb2\u0c95 \u0cb2\u0cbe\u0c97\u0cbf\u0ca8\u0ccd',
    AppLanguage.malayalam => 'Email \u0d35\u0d34\u0d3f \u0d32\u0d4b\u0d17\u0d3f\u0d7b',
  };

  String get signUpWithEmail => switch (language) {
    AppLanguage.telugu => 'Email తో Sign Up',
    AppLanguage.hindi => 'Email से Sign Up',
    AppLanguage.english => 'Sign Up with Email',
    AppLanguage.tamil => 'Email \u0bae\u0bc2\u0bb2\u0bae\u0bcd \u0baa\u0ba4\u0bbf\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd',
    AppLanguage.kannada => 'Email \u0cae\u0cc2\u0cb2\u0c95 \u0cb8\u0cc8\u0ca8\u0ccd \u0c85\u0baa\u0ccd',
    AppLanguage.malayalam => 'Email \u0d35\u0d34\u0d3f \u0d38\u0d48\u0d7b \u0d05\u0d2a\u0d4d',
  };

  String get validEmailError => switch (language) {
    AppLanguage.telugu => 'సరైన email ఇవ్వండి',
    AppLanguage.hindi => 'सही email दर्ज करें',
    AppLanguage.english => 'Enter valid email',
    AppLanguage.tamil => '\u0b9a\u0bb0\u0bbf\u0baf\u0bbe\u0ba9 email \u0b89\u0bb3\u0bcd\u0bb3\u0bbf\u0b9f\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => '\u0cb8\u0cb0\u0cbf\u0caf\u0cbe\u0ca6 email \u0ca8\u0cae\u0cc2\u0ca6\u0cbf\u0cb8\u0cbf',
    AppLanguage.malayalam => '\u0d36\u0d30\u0d3f\u0d2f\u0d3e\u0d2f email \u0d28\u0d7d\u0d15\u0d42',
  };

  String get passwordError => switch (language) {
    AppLanguage.telugu => 'కనీసం 6 అక్షరాలు అవసరం',
    AppLanguage.hindi => 'कम से कम 6 अक्षर चाहिए',
    AppLanguage.english => 'Minimum 6 characters required',
    AppLanguage.tamil => '\u0b95\u0bc1\u0bb1\u0bc8\u0ba8\u0bcd\u0ba4\u0ba4\u0bc1 6 \u0b8e\u0bb4\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0b95\u0bb3\u0bcd \u0ba4\u0bc7\u0bb5\u0bc8',
    AppLanguage.kannada => '\u0c95\u0ca8\u0cbf\u0cb7\u0ccd\u0ca0 6 \u0c85\u0c95\u0ccd\u0cb7\u0cb0\u0c97\u0cb3\u0cc1 \u0cac\u0cc7\u0c95\u0cc1',
    AppLanguage.malayalam => '\u0d15\u0d41\u0d31\u0d1e\u0d4d\u0d1e\u0d24\u0d4d 6 \u0d05\u0d15\u0d4d\u0d37\u0d30\u0d19\u0d4d\u0d19\u0d33\u0d4d \u0d06\u0d35\u0d36\u0d4d\u0d2f\u0d2e\u0d3e\u0d23\u0d4d',
  };

  String get forgotPasswordPlaceholder => switch (language) {
    AppLanguage.telugu =>
      'Forgot Password flow backend integration తర్వాత activate అవుతుంది.',
    AppLanguage.hindi =>
      'Forgot Password flow backend integration के बाद activate होगा.',
    AppLanguage.english => 'Forgot Password flow will activate after backend integration.',
    AppLanguage.tamil =>
      'Forgot Password flow backend integration \u0bae\u0bc1\u0b9f\u0bbf\u0ba8\u0bcd\u0ba4\u0baa\u0bbf\u0ba9\u0bcd \u0b9a\u0bc6\u0baf\u0bb2\u0bcd\u0baa\u0b9f\u0bc1\u0bae\u0bcd.',
    AppLanguage.kannada =>
      'Forgot Password flow backend integration \u0c86\u0ca6 \u0cae\u0cc7\u0cb2\u0cc6 \u0cb8\u0c95\u0ccd\u0cb0\u0cbf\u0caf\u0c97\u0cca\u0cb3\u0ccd\u0cb3\u0cc1\u0ca4\u0ccd\u0ca4\u0ca6\u0cc6.',
    AppLanguage.malayalam =>
      'Forgot Password flow backend integration \u0d2a\u0d42\u0d7c\u0d24\u0d4d\u0d24\u0d3f\u0d2f\u0d3e\u0d2f\u0d3f \u0d15\u0d34\u0d3f\u0d1e\u0d4d\u0d1e\u0d3e\u0d32\u0d4d \u0d38\u0d1c\u0d40\u0d35\u0d2e\u0d3e\u0d15\u0d41\u0d02.',
  };

  String get permissionsTitle => switch (language) {
    AppLanguage.telugu => 'కొన్ని అనుమతులు అవసరం',
    AppLanguage.hindi => 'कुछ permissions आवश्यक हैं',
    AppLanguage.english => 'A few permissions are needed',
    AppLanguage.tamil => '\u0b9a\u0bbf\u0bb2 permissions \u0ba4\u0bc7\u0bb5\u0bc8',
    AppLanguage.kannada => '\u0c95\u0cc6\u0cb2\u0cb5\u0cc1 permissions \u0cac\u0cc7\u0c95\u0cbe\u0c97\u0cbf\u0cb5\u0cc6',
    AppLanguage.malayalam => '\u0d15\u0d41\u0d31\u0d1a\u0d4d\u0d1a\u0d4d permissions \u0d06\u0d35\u0d36\u0d4d\u0d2f\u0d2e\u0d3e\u0d23\u0d4d',
  };

  String get permissionsSubtitle => switch (language) {
    AppLanguage.telugu =>
      'ఫోటోలు ఎంచుకోవడానికి, పోస్టర్లు సేవ్ చేయడానికి, ముఖ్యమైన అప్‌డేట్స్ తెలుసుకోవడానికి permissions అవసరం.',
    AppLanguage.hindi =>
      'फोटो चुनने, पोस्टर सेव करने और महत्वपूर्ण अपडेट पाने के लिए permissions चाहिए.',
    AppLanguage.english =>
      'Permissions are needed to choose photos, save posters, and receive important updates.',
    AppLanguage.tamil =>
      '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf, posters-\u0b90 save \u0b9a\u0bc6\u0baf\u0bcd\u0baf, \u0bae\u0bc1\u0b95\u0bcd\u0b95\u0bbf\u0baf\u0bae\u0bbe\u0ba9 updates-\u0b90 \u0baa\u0bc6\u0bb1 permissions \u0ba4\u0bc7\u0bb5\u0bc8.',
    AppLanguage.kannada =>
      '\u0cab\u0ccb\u0c9f\u0ccb\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6 \u0cae\u0cbe\u0ca1\u0cb2\u0cc1, posters save \u0cae\u0cbe\u0ca1\u0cb2\u0cc1 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cae\u0cc1\u0c96\u0ccd\u0caf updates \u0caa\u0ca1\u0cc6\u0caf\u0cb2\u0cc1 permissions \u0cac\u0cc7\u0c95\u0cbe\u0c97\u0cbf\u0cb5\u0cc6.',
    AppLanguage.malayalam =>
      '\u0d2b\u0d4b\u0d1f\u0d4b\u0d15\u0d33\u0d4d \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d3e\u0d28\u0d41\u0d02 posters save \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d3e\u0d28\u0d41\u0d02 \u0d2a\u0d4d\u0d30\u0d27\u0d3e\u0d28 updates \u0d32\u0d2d\u0d3f\u0d15\u0d4d\u0d15\u0d3e\u0d28\u0d41\u0d02 permissions \u0d06\u0d35\u0d36\u0d4d\u0d2f\u0d2e\u0d3e\u0d23\u0d4d.',
  };

  String get photosGallery => switch (language) {
    AppLanguage.telugu => 'Photos/Gallery',
    AppLanguage.hindi => 'Photos/Gallery',
    AppLanguage.english => 'Photos/Gallery',
    AppLanguage.tamil => '\u0baa\u0bc1\u0b95\u0bc8\u0baa\u0bcd\u0baa\u0b9f\u0b99\u0bcd\u0b95\u0bb3\u0bcd/Gallery',
    AppLanguage.kannada => '\u0cab\u0ccb\u0c9f\u0ccb\u0c97\u0cb3\u0cc1/Gallery',
    AppLanguage.malayalam => '\u0d2b\u0d4b\u0d1f\u0d4b\u0d15\u0d33\u0d4d/Gallery',
  };

  String get notifications => switch (language) {
    AppLanguage.telugu => 'Notifications',
    AppLanguage.hindi => 'Notifications',
    AppLanguage.english => 'Notifications',
    AppLanguage.tamil => '\u0b85\u0bb1\u0bbf\u0bb5\u0bbf\u0baa\u0bcd\u0baa\u0bc1\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => '\u0c85\u0ca7\u0cbf\u0cb8\u0cc2\u0c9a\u0ca8\u0cc6\u0c97\u0cb3\u0cc1',
    AppLanguage.malayalam => '\u0d05\u0d31\u0d3f\u0d2f\u0d3f\u0d2a\u0d4d\u0d2a\u0d41\u0d15\u0d33\u0d4d',
  };

  String get enableLaterHint => switch (language) {
    AppLanguage.telugu =>
      'మీరు తర్వాత Settings లో కూడా permissions enable చేయవచ్చు.',
    AppLanguage.hindi =>
      'आप बाद में Settings में भी permissions enable कर सकते हैं.',
    AppLanguage.english => 'You can enable permissions later from Settings as well.',
    AppLanguage.tamil =>
      '\u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0bb0\u0bcd Settings-\u0bb2\u0bbf\u0bb0\u0bc1\u0ba8\u0bcd\u0ba4\u0bc1 permissions-\u0b90 enable \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bb2\u0bbe\u0bae\u0bcd.',
    AppLanguage.kannada =>
      '\u0ca8\u0cc0\u0cb5\u0cc1 \u0ca8\u0c82\u0ca4\u0cb0 Settings-\u0ca8\u0cbf\u0c82\u0ca6\u0cb2\u0cc2 permissions enable \u0cae\u0cbe\u0ca1\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
    AppLanguage.malayalam =>
      '\u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d40\u0d1f\u0d4d Settings-\u0d32\u0d4d \u0d28\u0d3f\u0d28\u0d4d\u0d28\u0d4d permissions enable \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0dbe\u0d35\u0d41\u0d28\u0d4d\u0d28\u0d24\u0d3e\u0d23\u0d4d.',
  };

  String get allowLabel => switch (language) {
    AppLanguage.telugu => 'అనుమతించండి',
    AppLanguage.hindi => 'अनुमति दें',
    AppLanguage.english => 'Allow',
    AppLanguage.tamil => '\u0b85\u0ba9\u0bc1\u0bae\u0ba4\u0bbf',
    AppLanguage.kannada => '\u0c85\u0ca8\u0cc1\u0cae\u0ca4\u0cbf\u0cb8\u0cbf',
    AppLanguage.malayalam => '\u0d05\u0d28\u0d41\u0d35\u0d26\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d15',
  };

  String get laterLabel => switch (language) {
    AppLanguage.telugu => 'తర్వాత చూద్దాం',
    AppLanguage.hindi => 'बाद में देखेंगे',
    AppLanguage.english => 'Later',
    AppLanguage.tamil => '\u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0bb0\u0bcd',
    AppLanguage.kannada => '\u0ca8\u0c82\u0ca4\u0cb0',
    AppLanguage.malayalam => '\u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d40\u0d1f\u0d4d',
  };

  String get homeTagline => switch (language) {
    AppLanguage.telugu => 'సృష్టించండి & పంచుకోండి',
    AppLanguage.hindi => 'बनाएं और साझा करें',
    AppLanguage.english => 'Create & Share',
    AppLanguage.tamil => 'உருவாக்கி பகிருங்கள்',
    AppLanguage.kannada => 'ರಚಿಸಿ ಮತ್ತು ಹಂಚಿಕೊಳ್ಳಿ',
    AppLanguage.malayalam => 'സൃഷ്ടിച്ച് പങ്കിടുക',
  };

  String get createLabel => switch (language) {
    AppLanguage.telugu => 'సృష్టించండి',
    AppLanguage.hindi => 'बनाएं',
    AppLanguage.english => 'Create',
    AppLanguage.tamil => 'உருவாக்கு',
    AppLanguage.kannada => 'ರಚಿಸಿ',
    AppLanguage.malayalam => 'സൃഷ്ടിക്കുക',
  };

  String get searchTemplates => switch (language) {
    AppLanguage.telugu => 'టెంప్లేట్లు వెతకండి',
    AppLanguage.hindi => 'टेम्पलेट खोजें',
    AppLanguage.english => 'Search templates',
    AppLanguage.tamil => 'டெம்ப்ளேட்களை தேடுங்கள்',
    AppLanguage.kannada => 'ಟೆಂಪ್ಲೇಟ್ ಹುಡುಕಿ',
    AppLanguage.malayalam => 'ടെംപ്ലേറ്റുകൾ തിരയുക',
  };

  String get bannerTitle => switch (language) {
    AppLanguage.telugu => 'మనా పోస్టర్ ఫీచర్డ్ బ్యానర్',
    AppLanguage.hindi => 'मना पोस्टर फीचर्ड बैनर',
    AppLanguage.english => 'Mana Poster Featured Banner',
    AppLanguage.tamil => 'Mana Poster \u0b9a\u0bbf\u0bb1\u0baa\u0bcd\u0baa\u0bc1 banner',
    AppLanguage.kannada => 'Mana Poster \u0cb5\u0cbf\u0cb6\u0cc7\u0cb7 banner',
    AppLanguage.malayalam => 'Mana Poster \u0d2a\u0d4d\u0d30\u0d24\u0d4d\u0d2f\u0d47\u0d15 banner',
  };

  String get freeTab => switch (language) {
    AppLanguage.telugu => 'ఉచితం',
    AppLanguage.hindi => 'फ्री',
    AppLanguage.english => 'Free',
    AppLanguage.tamil => 'இலவசம்',
    AppLanguage.kannada => 'ಉಚಿತ',
    AppLanguage.malayalam => 'സൗജന്യം',
  };

  String get premiumTab => switch (language) {
    AppLanguage.telugu => 'ప్రీమియం',
    AppLanguage.hindi => 'प्रीमियम',
    AppLanguage.english => 'Premium',
    AppLanguage.tamil => 'பிரீமியம்',
    AppLanguage.kannada => 'ಪ್ರೀಮಿಯಂ',
    AppLanguage.malayalam => 'പ്രീമിയം',
  };

  String get buyLabel => switch (language) {
    AppLanguage.telugu => 'కొనండి',
    AppLanguage.hindi => 'खरीदें',
    AppLanguage.english => 'Buy',
    AppLanguage.tamil => 'வாங்கு',
    AppLanguage.kannada => 'ಖರೀದಿಸಿ',
    AppLanguage.malayalam => 'വാങ്ങുക',
  };

  String get shareWhatsApp => switch (language) {
    AppLanguage.telugu => 'షేర్',
    AppLanguage.hindi => 'शेयर',
    AppLanguage.english => 'Share WhatsApp',
    AppLanguage.tamil => 'பகிர்',
    AppLanguage.kannada => 'ಹಂಚಿಕೆ',
    AppLanguage.malayalam => 'ഷെയർ',
  };

  String get downloadLabel => switch (language) {
    AppLanguage.telugu => 'డౌన్‌లోడ్',
    AppLanguage.hindi => 'डाउनलोड',
    AppLanguage.english => 'Download',
    AppLanguage.tamil => 'பதிவிறக்கு',
    AppLanguage.kannada => 'ಡೌನ್‌ಲೋಡ್',
    AppLanguage.malayalam => 'ഡൗൺലോഡ്',
  };

  String get profileTitle => switch (language) {
    AppLanguage.telugu => 'ప్రొఫైల్ & సెట్టింగ్స్',
    AppLanguage.hindi => 'प्रोफ़ाइल और सेटिंग्स',
    AppLanguage.english => 'Profile & Settings',
    AppLanguage.tamil => 'ப்ரொஃபைல் & அமைப்புகள்',
    AppLanguage.kannada => 'ಪ್ರೊಫೈಲ್ ಮತ್ತು ಸೆಟ್ಟಿಂಗ್ಸ್',
    AppLanguage.malayalam => 'പ്രൊഫൈൽ & സെറ്റിംഗ്സ്',
  };

  String get accountSection => switch (language) {
    AppLanguage.telugu => 'అకౌంట్',
    AppLanguage.hindi => 'अकाउंट',
    AppLanguage.english => 'Account',
    AppLanguage.tamil => 'அகௌಂಟ್',
    AppLanguage.kannada => 'ಅಕೌಂಟ್',
    AppLanguage.malayalam => 'അക്കൗണ്ട്',
  };

  String get appSettingsSection => switch (language) {
    AppLanguage.telugu => 'యాప్ సెట్టింగ్స్',
    AppLanguage.hindi => 'ऐप सेटिंग्स',
    AppLanguage.english => 'App Settings',
    AppLanguage.tamil => 'ஆப் அமைப்புகள்',
    AppLanguage.kannada => 'ಆಪ್ ಸೆಟ್ಟಿಂಗ್ಸ್',
    AppLanguage.malayalam => 'ആപ്പ് സെറ്റിംഗ്സ്',
  };

  String get supportSection => switch (language) {
    AppLanguage.telugu => 'సపోర్ట్',
    AppLanguage.hindi => 'सपोर्ट',
    AppLanguage.english => 'Support',
    AppLanguage.tamil => 'ஆதரவு',
    AppLanguage.kannada => 'ಬೆಂಬಲ',
    AppLanguage.malayalam => 'സഹായം',
  };

  String get languageOption => switch (language) {
    AppLanguage.telugu => 'భాష',
    AppLanguage.hindi => 'भाषा',
    AppLanguage.english => 'Language',
    AppLanguage.tamil => 'மொழி',
    AppLanguage.kannada => 'ಭಾಷೆ',
    AppLanguage.malayalam => 'ഭാഷ',
  };

  String get languageOptionSubtitle => switch (language) {
    AppLanguage.telugu => 'మీ app భాషను ఎంచుకోండి',
    AppLanguage.hindi => 'अपनी app language चुनें',
    AppLanguage.english => 'Choose your app language',
    AppLanguage.tamil => '\u0b89\u0b99\u0bcd\u0b95\u0bb3\u0bcd app \u0bae\u0bca\u0bb4\u0bbf\u0baf\u0bc8 \u0ba4\u0bc7\u0bb0\u0bcd\u0bb5\u0bc1 \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => '\u0ca8\u0cbf\u0cae\u0ccd\u0cae app \u0cad\u0bbe\u0cb7\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0abe\u0ca1\u0cbf',
    AppLanguage.malayalam => '\u0d28\u0d3f\u0d19\u0d4d\u0d19\u0d33\u0d41\u0d1f\u0d46 app \u0d2d\u0d3e\u0d37 \u0d24\u0d3f\u0d30\u0d1e\u0d4d\u0d1e\u0d46\u0d1f\u0d41\u0d15\u0d4d\u0d15\u0d42',
  };

  String get subscriptionOption => switch (language) {
    AppLanguage.telugu => 'సబ్‌స్క్రిప్షన్ / ప్లాన్లు',
    AppLanguage.hindi => 'सब्सक्रिप्शन / प्लान',
    AppLanguage.english => 'Subscription / Plans',
    AppLanguage.tamil => '\u0b9a\u0ba8\u0bcd\u0ba4\u0bbe / Plans',
    AppLanguage.kannada => '\u0c9a\u0c82\u0ca6\u0cbe / Plans',
    AppLanguage.malayalam => '\u0d38\u0d2c\u0d4d\u0d38\u0d4d\u0d15\u0d4d\u0d30\u0d3f\u0d2a\u0d4d\u0d37\u0d7b / Plans',
  };

  String get subscriptionSubtitle => switch (language) {
    AppLanguage.telugu => 'ప్రస్తుతం ఉన్న plan మరియు upgrades',
    AppLanguage.hindi => 'Current plan और upgrades manage करें',
    AppLanguage.english => 'Manage current plan and upgrades',
    AppLanguage.tamil => '\u0ba4\u0bb1\u0bcd\u0baa\u0bcb\u0ba4\u0bc1\u0baf plan \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd upgrades-\u0b90 manage \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bb5\u0bc1\u0bae\u0bcd',
    AppLanguage.kannada => '\u0cbf\u0caa\u0ccd\u0caa\u0cbf\u0ca8 current plan \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 upgrades \u0ca8\u0ccd\u0ca8\u0cc1 manage \u0cae\u0cbe\u0ca1\u0cbf',
    AppLanguage.malayalam => '\u0d28\u0d3f\u0d32\u0d35\u0d3f\u0d32\u0d41\u0d33\u0d4d\u0d33 plan \u0d09\u0d02 upgrades-\u0d09\u0d02 manage \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0d41\u0d15',
  };

  String get permissionsOptionSubtitle => switch (language) {
    AppLanguage.telugu => 'Photos, storage మరియు ఇతర access',
    AppLanguage.hindi => 'Photos, storage और other access',
    AppLanguage.english => 'Photos, storage and other access',
    AppLanguage.tamil => 'Photos, storage \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd \u0baa\u0bbf\u0bb1 access',
    AppLanguage.kannada => 'Photos, storage \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0c87\u0ca4\u0cb0 access',
    AppLanguage.malayalam => 'Photos, storage \u0d15\u0d42\u0d1f\u0d3e\u0d24\u0d46 \u0d2e\u0d31\u0d4d\u0d31 access',
  };

  String get notificationsOptionSubtitle => switch (language) {
    AppLanguage.telugu => 'Alerts మరియు updates నియంత్రించండి',
    AppLanguage.hindi => 'Alerts और updates नियंत्रित करें',
    AppLanguage.english => 'Control alerts and updates',
    AppLanguage.tamil => 'Alerts \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd updates-\u0b90 \u0b95\u0b9f\u0bcd\u0b9f\u0bc1\u0baa\u0bcd\u0baa\u0b9f\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => 'Alerts \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 updates \u0ca8\u0cbf\u0caf\u0c82\u0ca4\u0ccd\u0cb0\u0cbf\u0cb8\u0cbf',
    AppLanguage.malayalam => 'Alerts \u0d09\u0d02 updates-\u0d09\u0d02 \u0d28\u0d3f\u0d2f\u0d28\u0d4d\u0d24\u0d4d\u0d30\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d15',
  };

  String get helpSupport => switch (language) {
    AppLanguage.telugu => 'సహాయం & సపోర్ట్',
    AppLanguage.hindi => 'मदद और सपोर्ट',
    AppLanguage.english => 'Help & Support',
    AppLanguage.tamil => '\u0b89\u0ba4\u0bb5\u0bbf & Support',
    AppLanguage.kannada => '\u0cb8\u0cb9\u0cbe\u0caf & Support',
    AppLanguage.malayalam => '\u0d38\u0d39\u0d3e\u0d2f\u0d02 & Support',
  };

  String get helpSupportSubtitle => switch (language) {
    AppLanguage.telugu => 'సహాయం పొందండి మరియు support ను సంప్రదించండి',
    AppLanguage.hindi => 'मदद लें और support से संपर्क करें',
    AppLanguage.english => 'Get help and contact support',
    AppLanguage.tamil => '\u0b89\u0ba4\u0bb5\u0bbf \u0baa\u0bc6\u0bb1\u0bcd\u0bb1\u0bc1 support-\u0b90 \u0ba4\u0bca\u0b9f\u0bb0\u0bcd\u0baa\u0bc1 \u0b95\u0bca\u0bb3\u0bcd\u0bb3\u0bc1\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
    AppLanguage.kannada => '\u0cb8\u0cb9\u0cbe\u0caf \u0caa\u0ca1\u0cc6\u0ca6\u0cc1 support \u0ca8\u0cbf\u0c82\u0ca6 \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95 \u0cae\u0cbe\u0ca1\u0cbf',
    AppLanguage.malayalam => '\u0d38\u0d39\u0d3e\u0d2f\u0d02 \u0d32\u0d2d\u0d3f\u0d15\u0d4d\u0d15\u0d42 \u0d15\u0d42\u0d1f\u0d3e\u0d24\u0d46 support-\u0d28\u0d47\u0d1f\u0d4d\u0d1f\u0d3f \u0d2c\u0d28\u0d4d\u0d27\u0d2a\u0d46\u0d1f\u0d41\u0d15',
  };

  String get aboutApp => switch (language) {
    AppLanguage.telugu => 'యాప్ గురించి',
    AppLanguage.hindi => 'ऐप के बारे में',
    AppLanguage.english => 'About App',
    AppLanguage.tamil => 'App \u0baa\u0bb1\u0bcd\u0bb1\u0bbf',
    AppLanguage.kannada => 'App \u0cac\u0c97\u0ccd\u0c97\u0cc6',
    AppLanguage.malayalam => 'App-\u0d28\u0d46\u0d15\u0dcd\u0d15\u0d41\u0d31\u0d3f\u0d1a\u0d4d\u0d1a\u0d4d',
  };

  String get aboutAppSubtitle => switch (language) {
    AppLanguage.telugu => 'App వివరాలు మరియు version సమాచారం',
    AppLanguage.hindi => 'App details और version info',
    AppLanguage.english => 'App details and version info',
    AppLanguage.tamil => 'App details \u0bae\u0bb1\u0bcd\u0bb1\u0bc1\u0bae\u0bcd version info',
    AppLanguage.kannada => 'App details \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 version info',
    AppLanguage.malayalam => 'App details \u0d09\u0d02 version info-\u0d09\u0d02',
  };

  String get logout => switch (language) {
    AppLanguage.telugu => 'లాగ్ అవుట్',
    AppLanguage.hindi => 'लॉग आउट',
    AppLanguage.english => 'Logout',
    AppLanguage.tamil => '\u0bb5\u0bc6\u0bb3\u0bbf\u0baf\u0bc7\u0bb1\u0bc1',
    AppLanguage.kannada => '\u0cb2\u0cbe\u0c97\u0ccd\u0c85\u0cb5\u0cc1\u0c9f\u0ccd',
    AppLanguage.malayalam => '\u0d32\u0d4b\u0d17\u0d4d\u0d05\u0d57\u0d1f\u0d4d',
  };

  String get logoutSubtitle => switch (language) {
    AppLanguage.telugu => 'Sign out logic తర్వాత connect అవుతుంది',
    AppLanguage.hindi => 'Sign out logic बाद में connect होगी',
    AppLanguage.english => 'Sign out logic can be connected later',
    AppLanguage.tamil => 'Sign out logic \u0baa\u0bbf\u0ba9\u0bcd\u0ba9\u0bb0\u0bcd connect \u0b9a\u0bc6\u0baf\u0bcd\u0baf\u0bb2\u0bbe\u0bae\u0bcd.',
    AppLanguage.kannada => 'Sign out logic \u0ca8\u0c82\u0ca4\u0cb0 connect \u0cae\u0cbe\u0ca1\u0cac\u0cb9\u0cc1\u0ca6\u0cc1.',
    AppLanguage.malayalam => 'Sign out logic \u0d2a\u0d3f\u0d28\u0d4d\u0d28\u0d40\u0d1f\u0d4d connect \u0d1a\u0d46\u0d2f\u0d4d\u0d2f\u0dbe\u0d35\u0d41\u0d28\u0d4d\u0d28\u0d24\u0d3e\u0d23\u0d4d.',
  };

  String get languageSettingsTitle => switch (language) {
    AppLanguage.telugu => 'భాష సెట్టింగ్స్',
    AppLanguage.hindi => 'भाषा सेटिंग्स',
    AppLanguage.english => 'Language Settings',
    AppLanguage.tamil => '\u0bae\u0bca\u0bb4\u0bbf Settings',
    AppLanguage.kannada => '\u0cad\u0bbe\u0cb7\u0cc6 Settings',
    AppLanguage.malayalam => '\u0d2d\u0d3e\u0d37 Settings',
  };

  String get currentLanguageLabel => switch (language) {
    AppLanguage.telugu => 'ప్రస్తుత భాష',
    AppLanguage.hindi => 'वर्तमान भाषा',
    AppLanguage.english => 'Current language',
    AppLanguage.tamil => '\u0ba4\u0bb1\u0bcd\u0baa\u0bcb\u0ba4\u0bc8\u0baf \u0bae\u0bca\u0bb4\u0bbf',
    AppLanguage.kannada => '\u0caa\u0ccd\u0cb0\u0cb8\u0ccd\u0ca4\u0cc1\u0ca4 \u0cad\u0bbe\u0cb7\u0cc6',
    AppLanguage.malayalam => '\u0d28\u0d3f\u0d32\u0d35\u0d3f\u0d32\u0d46 \u0d2d\u0d3e\u0d37',
  };

  String get saveApply => switch (language) {
    AppLanguage.telugu => 'సేవ్ / అప్లై',
    AppLanguage.hindi => 'सेव / अप्लाई',
    AppLanguage.english => 'Save / Apply',
    AppLanguage.tamil => '\u0b9a\u0bc7\u0bae\u0bbf / Apply',
    AppLanguage.kannada => '\u0c89\u0cb3\u0cbf\u0cb8\u0cbf / Apply',
    AppLanguage.malayalam => '\u0d38\u0d47\u0d35\u0d4d / Apply',
  };

  String languageName(AppLanguage value) => switch (value) {
    AppLanguage.telugu => '\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41',
    AppLanguage.hindi => '\u0939\u093f\u0928\u094d\u0926\u0940',
    AppLanguage.english => 'English',
    AppLanguage.tamil => '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd',
    AppLanguage.kannada => '\u0c95\u0ca8\u0ccd\u0ca8\u0ca1',
    AppLanguage.malayalam => '\u0d2e\u0d32\u0d2f\u0d3e\u0d33\u0d02',
  };

  List<String> localizedHomeCategories() => switch (language) {
    AppLanguage.telugu => const <String>[
      'అన్నీ',
      '🌙 శుభరాత్రి',
      '🌅 శుభోదయం',
      '💪 ప్రేరణాత్మక',
      '❤️ ప్రేమ కోట్స్',
      '✨ ఈరోజు ప్రత్యేకం',
      '🎂 పుట్టినరోజులు',
      '🌿 జీవితం సలహాలు',
      '📖 గీతా జ్ఞానం',
      '📰 వార్తలు',
      '🙏 భక్తి',
      '🏹 మహాభారతం',
      '💍 వార్షికోత్సవం',
      '💭 మంచి ఆలోచనలు',
      '✝️ బైబిల్',
      '☪️ ఇస్లాం',
      '🆕 కొత్తవి',
    ],
    AppLanguage.hindi => const <String>[
      'सभी',
      '🌙 शुभ रात्रि',
      '🌅 सुप्रभात',
      '💪 प्रेरणादायक',
      '❤️ प्रेम उद्धरण',
      '✨ आज का विशेष',
      '🎂 जन्मदिन',
      '🌿 जीवन सलाह',
      '📖 गीता ज्ञान',
      '📰 समाचार',
      '🙏 भक्ति',
      '🏹 महाभारत',
      '💍 वर्षगांठ',
      '💭 अच्छे विचार',
      '✝️ बाइबल',
      '☪️ इस्लाम',
      '🆕 नया',
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
    AppLanguage.tamil => const <String>[
      'அனைத்தும்',
      '🌙 இனிய இரவு',
      '🌅 இனிய காலை',
      '💪 ஊக்கமளிப்பு',
      '❤️ காதல் மேற்கோள்கள்',
      '✨ இன்றைய சிறப்பு',
      '🎂 பிறந்தநாள்கள்',
      '🌿 வாழ்க்கை ஆலோசனை',
      '📖 கீதா ஞானம்',
      '📰 செய்திகள்',
      '🙏 பக்தி',
      '🏹 மகாபாரதம்',
      '💍 ஆண்டு விழா',
      '💭 நல்ல எண்ணங்கள்',
      '✝️ பைபிள்',
      '☪️ இஸ்லாம்',
      '🆕 புதியவை',
    ],
    AppLanguage.kannada => const <String>[
      'ಎಲ್ಲವೂ',
      '🌙 ಶುಭ ರಾತ್ರಿ',
      '🌅 ಶುಭೋದಯ',
      '💪 ಪ್ರೇರಣಾದಾಯಕ',
      '❤️ ಪ್ರೀತಿ ಉಕ್ತಿಗಳು',
      '✨ ಇಂದಿನ ವಿಶೇಷ',
      '🎂 ಜನ್ಮದಿನಗಳು',
      '🌿 ಜೀವನ ಸಲಹೆ',
      '📖 ಗೀತಾ ಜ್ಞಾನ',
      '📰 ಸುದ್ದಿ',
      '🙏 ಭಕ್ತಿ',
      '🏹 ಮಹಾಭಾರತ',
      '💍 ವಾರ್ಷಿಕೋತ್ಸವ',
      '💭 ಒಳ್ಳೆಯ ಆಲೋಚನೆಗಳು',
      '✝️ ಬೈಬಲ್',
      '☪️ ಇಸ್ಲಾಂ',
      '🆕 ಹೊಸದು',
    ],
    AppLanguage.malayalam => const <String>[
      'എല്ലാം',
      '🌙 ശുഭ രാത്രി',
      '🌅 ശുഭോദയം',
      '💪 പ്രചോദനാത്മകം',
      '❤️ പ്രണയ ഉദ്ധരണികൾ',
      '✨ ഇന്നത്തെ പ്രത്യേകത',
      '🎂 ജന്മദിനങ്ങൾ',
      '🌿 ജീവിത ഉപദേശം',
      '📖 ഗീതാ ജ്ഞാനം',
      '📰 വാർത്തകൾ',
      '🙏 ഭക്തി',
      '🏹 മഹാഭാരതം',
      '💍 വാർഷികം',
      '💭 നല്ല ചിന്തകൾ',
      '✝️ ബൈബിൾ',
      '☪️ ഇസ്ലാം',
      '🆕 പുതിയത്',
    ],
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
    AppLanguage.tamil => const <String>[
      '\u0b85\u0ba9\u0bc8\u0ba4\u0bcd\u0ba4\u0bc1\u0bae\u0bcd',
      '🌙 \u0b87\u0ba9\u0bbf\u0baf \u0b87\u0bb0\u0bb5\u0bc1 \u0bb5\u0ba3\u0b95\u0bcd\u0b95\u0bae\u0bcd',
      '🌅 \u0b87\u0ba9\u0bbf\u0baf \u0b95\u0bbe\u0bb2\u0bc8 \u0bb5\u0ba3\u0b95\u0bcd\u0b95\u0bae\u0bcd',
      '💪 \u0b8a\u0b95\u0b95\u0bcd \u0bb5\u0bbe\u0bb0\u0bcd\u0ba4\u0bcd\u0ba4\u0bc8\u0b95\u0bb3\u0bcd',
      '❤️ \u0b95\u0bbe\u0ba4\u0bb2\u0bcd \u0bae\u0bc6\u0bbe\u0bb4\u0bbf\u0b95\u0bb3\u0bcd',
      '✨ \u0b87\u0ba9\u0bcd\u0bb1\u0bc8\u0baf \u0b9a\u0bbf\u0bb1\u0baa\u0bcd\u0baa\u0bc1',
      '🎂 \u0baa\u0bbf\u0bb1\u0ba8\u0bcd\u0ba4\u0ba8\u0bbe\u0bb3\u0bcd\u0b95\u0bb3\u0bcd',
      '🌿 \u0bb5\u0bbe\u0bb4\u0bcd\u0b95\u0bcd\u0b95\u0bc8 \u0b85\u0bb1\u0bbf\u0bb5\u0bc1\u0bb0\u0bc8',
      '📖 \u0b95\u0bc0\u0ba4\u0bbe \u0b9e\u0bbe\u0ba9\u0bae\u0bcd',
      '📰 \u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bbf\u0b95\u0bb3\u0bcd',
      '🙏 \u0baa\u0b95\u0bcd\u0ba4\u0bbf',
      '🏹 \u0bae\u0b95\u0bbe\u0baa\u0bbe\u0bb0\u0ba4\u0bae\u0bcd',
      '💍 \u0ba4\u0bbf\u0bb0\u0bc1\u0bae\u0ba3 \u0ba8\u0bbe\u0bb3\u0bcd',
      '💭 \u0ba8\u0bb2\u0bcd\u0bb2 \u0b8e\u0ba3\u0bcd\u0ba3\u0b99\u0bcd\u0b95\u0bb3\u0bcd',
      '✝️ \u0baa\u0bc8\u0baa\u0bbf\u0bb3\u0bcd',
      '☪️ \u0b87\u0bb8\u0bcd\u0bb2\u0bbe\u0bae\u0bcd',
      '🆕 \u0baa\u0bc1\u0ba4\u0bbf\u0baf\u0ba4\u0bc1',
    ],
    AppLanguage.kannada => const <String>[
      '\u0c8e\u0cb2\u0ccd\u0cb2\u0cb5\u0cc2',
      '🌙 \u0cb6\u0cc1\u0cad \u0cb0\u0cbe\u0ca4\u0ccd\u0cb0\u0cbf',
      '🌅 \u0cb6\u0cc1\u0cad\u0cca\u0ca6\u0caf',
      '💪 \u0caa\u0ccd\u0cb0\u0cc7\u0cb0\u0ca3\u0cbe\u0ca4\u0ccd\u0cae\u0c95',
      '❤️ \u0caa\u0ccd\u0cb0\u0cc0\u0ca4\u0cbf \u0c89\u0ca6\u0ccd\u0ca7\u0cb0\u0ca3\u0cc6\u0c97\u0cb3\u0cc1',
      '✨ \u0c87\u0c82\u0ca6\u0cbf\u0ca8 \u0cb5\u0cbf\u0cb6\u0cc7\u0cb7',
      '🎂 \u0c9c\u0ca8\u0ccd\u0cae\u0ca6\u0cbf\u0ca8\u0c97\u0cb3\u0cc1',
      '🌿 \u0c9c\u0cc0\u0cb5\u0ca8 \u0cb8\u0cb2\u0cb9\u0cc6',
      '📖 \u0c97\u0cc0\u0ca4\u0cc6 \u0c9c\u0ccd\u0c9e\u0cbe\u0ca8',
      '📰 \u0cb8\u0cc1\u0ca6\u0ccd\u0ca6\u0cbf',
      '🙏 \u0cad\u0c95\u0ccd\u0ca4\u0cbf',
      '🏹 \u0cae\u0cb9\u0cbe\u0cad\u0cbe\u0cb0\u0ca4',
      '💍 \u0cb5\u0cbf\u0cb5\u0cbe\u0cb9 \u0cb5\u0cbe\u0cb0\u0ccd\u0cb7\u0cbf\u0c95\u0ccb\u0ca4\u0ccd\u0cb8\u0cb5',
      '💭 \u0c92\u0cb3\u0ccd\u0cb3\u0cc6\u0caf \u0c86\u0cb2\u0ccb\u0c9a\u0ca8\u0cc6\u0c97\u0cb3\u0cc1',
      '✝️ \u0cac\u0cc8\u0cac\u0cb2\u0ccd',
      '☪️ \u0c87\u0cb8\u0ccd\u0cb2\u0cbe\u0c82',
      '🆕 \u0cb9\u0cca\u0cb8\u0ca6\u0cc1',
    ],
    AppLanguage.malayalam => const <String>[
      '\u0d0e\u0d32\u0d4d\u0d32\u0d3e\u0d02',
      '🌙 \u0d36\u0d41\u0d2d\u0d30\u0d3e\u0d24\u0d4d\u0d30\u0d3f',
      '🌅 \u0d36\u0d41\u0d2d\u0d4b\u0d26\u0d2f\u0d02',
      '💪 \u0d2a\u0d4d\u0d30\u0d1a\u0d4b\u0d26\u0d28\u0d2a\u0d30\u0d2e\u0d3e\u0d2f',
      '❤️ \u0d38\u0d4d\u0d28\u0d47\u0d39 \u0d09\u0d26\u0d4d\u0d27\u0d30\u0d23\u0d3f\u0d15\u0d33\u0d4d',
      '✨ \u0d07\u0d28\u0d4d\u0d28\u0d24\u0d4d\u0d24\u0d46 \u0d2a\u0d4d\u0d30\u0d24\u0d4d\u0d2f\u0d47\u0d15\u0d24',
      '🎂 \u0d1c\u0d28\u0d4d\u0d2e\u0d26\u0d3f\u0d28\u0d19\u0d4d\u0d19\u0d33\u0d4d',
      '🌿 \u0d1c\u0d40\u0d35\u0d3f\u0d24 \u0d09\u0d2a\u0d26\u0d47\u0d36\u0d02',
      '📖 \u0d17\u0d40\u0d24\u0d3e \u0d1c\u0d4d\u0d1e\u0d3e\u0d28\u0d02',
      '📰 \u0d35\u0d3e\u0d7c\u0d24\u0d4d\u0d24\u0d15\u0d33\u0d4d',
      '🙏 \u0d2d\u0d15\u0d4d\u0d24\u0d3f',
      '🏹 \u0d2e\u0d39\u0d3e\u0d2d\u0d3e\u0d30\u0d24\u0d02',
      '💍 \u0d35\u0d3e\u0d7c\u0d37\u0d3f\u0d15\u0d02',
      '💭 \u0d28\u0d32\u0d4d\u0d32 \u0d1a\u0d3f\u0d28\u0d4d\u0d24\u0d15\u0d33\u0d4d',
      '✝️ \u0d2c\u0d48\u0d2c\u0d3f\u0d7e',
      '☪️ \u0d07\u0d38\u0d4d\u0d32\u0d3e\u0d02',
      '🆕 \u0d2a\u0d41\u0d24\u0d3f\u0d2f\u0d24\u0d4d',
    ],
  };
}



