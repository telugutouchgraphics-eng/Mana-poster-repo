import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

enum _AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with AppLanguageStateMixin, WidgetsBindingObserver {
  final FirebaseAuthService _service = FirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _authBootstrapping = !FirebaseBootstrap.hasFirebaseApp;
  bool _loadingGoogle = false;
  bool _loadingEmail = false;
  bool _loadingReset = false;
  bool _skipping = false;
  bool _showOtherOptions = false;
  bool _showPassword = false;
  _AuthMode _authMode = _AuthMode.login;

  bool get _isBusy =>
      _authBootstrapping ||
      _loadingGoogle ||
      _loadingEmail ||
      _loadingReset ||
      _skipping;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ScreenSecurityService.disableSecure());
    _stabilizeBottomSystemUi();
    unawaited(_prepareAuthDependencies());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ScreenSecurityService.enableSecure());
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _stabilizeBottomSystemUi();
    }
  }

  Future<void> _prepareAuthDependencies() async {
    if (FirebaseBootstrap.hasFirebaseApp) {
      if (mounted && _authBootstrapping) {
        setState(() => _authBootstrapping = false);
      }
      return;
    }
    try {
      await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);
    } finally {
      if (mounted) {
        setState(() => _authBootstrapping = false);
      }
    }
  }

  Future<void> _stabilizeBottomSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 180), () async {
          if (!mounted) {
            return;
          }
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
        }),
      );
    });
  }

  Future<void> _continueWithGoogle() async {
    if (_isBusy) {
      return;
    }
    setState(() => _loadingGoogle = true);
    try {
      final AuthFlowResult authResult = await _service.signInWithGoogle();
      await _stabilizeBottomSystemUi();
      await _showFirst150TrialDialogIfNeeded(authResult);
      await _continueAfterAuth();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(_messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingGoogle = false);
      }
    }
  }

  Future<void> _continueWithEmail() async {
    if (_isBusy) {
      return;
    }
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    setState(() => _loadingEmail = true);
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      final AuthFlowResult authResult = _authMode == _AuthMode.login
          ? await _service.signInWithEmail(email: email, password: password)
          : await _service.signUpWithEmail(email: email, password: password);
      await _stabilizeBottomSystemUi();
      await _showFirst150TrialDialogIfNeeded(authResult);
      await _continueAfterAuth();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(_messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingEmail = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_isBusy) {
      return;
    }
    final String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError(context.strings.validEmailError);
      return;
    }
    setState(() => _loadingReset = true);
    try {
      await _service.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentTopSnackBar()
        ..showTopSnackBar(
          AppSnackBar.build(content: Text(_LoginUiCopy(context.currentLanguage).resetSent(email))),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(_messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingReset = false);
      }
    }
  }

  Future<void> _skipNow() async {
    if (_isBusy) {
      return;
    }
    setState(() => _skipping = true);
    try {
      await _service.signOut();
      await AppFlowService.persistLastKnownAuthUid(null);
      await AppFlowService.loadSnapshot();
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } finally {
      if (mounted) {
        setState(() => _skipping = false);
      }
    }
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  Future<void> _showFirst150TrialDialogIfNeeded(AuthFlowResult result) async {
    if (!result.first150TrialGranted || !mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            context.strings.localized(
              telugu: 'ప్రీమియం బహుమతి',
              english: 'Premium Gift',
              hindi: 'प्रीमियम उपहार',
              tamil: 'பிரீமியம் பரிசு',
              kannada: 'ಪ್ರೀಮಿಯಂ ಉಡುಗೊರೆ',
              malayalam: 'പ്രീമിയം സമ്മാനം',
              marathi: 'प्रीमियम भेट',
              gujarati: 'પ્રીમિયમ ભેટ',
              bengali: 'প্রিমিয়াম উপহার',
              punjabi: 'ਪ੍ਰੀਮੀਅਮ ਤੋਹਫ਼ਾ',
              odia: 'ପ୍ରିମିୟମ ଉପହାର',
              assamese: 'প্ৰিমিয়াম উপহাৰ',
              konkani: 'प्रीमियम भेट',
              nepali: 'प्रीमियम उपहार',
              meitei: 'Premium Gift',
              mizo: 'Premium thilpek',
              kashmiri: 'پریمیم تحفہ',
              ladakhi: 'Premium ལེགས་སྐྱེས།',
            ),
          ),
          content: Text(
            context.strings.localized(
              telugu: 'అభినందనలు! మీకు 30 రోజుల ప్రీమియం ఉచితంగా లభించింది.',
              english: 'Congratulations! You received 30 days Premium free.',
              hindi: 'बधाई हो! आपको 30 दिन का प्रीमियम मुफ़्त मिला है।',
              tamil: 'வாழ்த்துகள்! உங்களுக்கு 30 நாட்கள் இலவச பிரீமியம் கிடைத்துள்ளது.',
              kannada: 'ಅಭಿನಂದನೆಗಳು! ನಿಮಗೆ 30 ದಿನಗಳ ಉಚಿತ ಪ್ರೀಮಿಯಂ ಸಿಕ್ಕಿದೆ.',
              malayalam: 'അഭിനന്ദനങ്ങൾ! നിങ്ങൾക്ക് 30 ദിവസത്തെ പ്രീമിയം സൗജന്യമായി ലഭിച്ചു.',
              marathi: 'अभिनंदन! तुम्हाला ३० दिवसांचा मोफत प्रीमियम मिळाला आहे.',
              gujarati: 'અભિનંદન! તમને 30 દિવસનું પ્રીમિયમ મફત મળ્યું છે.',
              bengali: 'অভিনন্দন! আপনি ৩০ দিনের প্রিমিয়াম বিনামূল্যে পেয়েছেন।',
              punjabi: 'ਵਧਾਈਆਂ! ਤੁਹਾਨੂੰ 30 ਦਿਨਾਂ ਦਾ ਪ੍ਰੀਮੀਅਮ ਮੁਫ਼ਤ ਮਿਲਿਆ ਹੈ।',
              odia: 'ଅଭିନନ୍ଦନ! ଆପଣଙ୍କୁ ୩୦ ଦିନର ମାଗଣା ପ୍ରିମିୟମ ମିଳିଛି।',
              assamese: 'অভিনন্দন! আপুনি ৩০ দিনৰ বিনামূলীয়া প্ৰিমিয়াম পাইছে।',
              konkani: 'अभिनंदन! तुमकां 30 दिसांचें फुकट प्रीमियम मेळ्ळें.',
              nepali: 'बधाई छ! तपाईंले ३० दिनको प्रिमियम नि:शुल्क पाउनुभयो।',
              meitei: 'Yaifare! Nahak 30 ni Premium mahut leina phangkhre.',
              mizo: 'Lawmthu kan sawi! Ni 30 chhung Premium a thlawnin i dawng e.',
              kashmiri: 'مبارک! تۄہہِ میول ۳۰ دوہن ہُنٛد پریمیم مفت۔',
              ladakhi: 'བཀྲ་ཤིས་བདེ་ལེགས། ཉིན་ ༣༠ ཡི་ premium རིན་མེད་ཐོབ།',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.strings.localized(
                  telugu: 'సరే',
                  english: 'OK',
                  hindi: 'ठीक है',
                  tamil: 'சரி',
                  kannada: 'ಸರಿ',
                  malayalam: 'ശരി',
                  marathi: 'ठीक आहे',
                  gujarati: 'બરાબર',
                  bengali: 'ঠিক আছে',
                  punjabi: 'ਠੀਕ ਹੈ',
                  odia: 'ଠିକ୍ ଅଛି',
                  assamese: 'ঠিক আছে',
                  konkani: 'बरे',
                  nepali: 'हुन्छ',
                  meitei: 'Hoi',
                  mizo: 'Aw le',
                  kashmiri: 'صحیح',
                  ladakhi: 'འགྲིགས།',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _messageForError(Object error) {
    if (error is AuthFailure) {
      return _localizedAuthError(error);
    }
    return context.strings.localized(
      telugu: 'ఇంకోసారి ప్రయత్నించండి.',
      english: 'Please try again.',
      hindi: 'कृपया पुनः प्रयास करें।',
      tamil: 'மீண்டும் முயற்சிக்கவும்.',
      kannada: 'ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'કૃપા કરીને ફરી પ્રયાસ કરો.',
      bengali: 'অনুগ্রহ করে আবার চেষ্টা করুন।',
      punjabi: 'ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'उपकार करून परत प्रयत्न करात.',
      nepali: 'कृपया पुन: प्रयास गर्नुहोस्।',
      meitei: 'Chanbiduna amuk hanna hotnabiyu.',
      mizo: 'Khawngaihin ti nawn leh rawh.',
      kashmiri: 'مہربٲنی کٔرتھ دۆبارٕ کوشِش کٔریو۔',
      ladakhi: 'ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
    );
  }

  String _localizedAuthError(AuthFailure error) {
    final AppStrings strings = context.strings;
    switch (error.code) {
      case 'invalid-email':
        return strings.validEmailError;
      case 'user-disabled':
        return strings.localized(
          telugu: 'ఈ ఖాతా నిలిపివేయబడింది.',
          english: 'This account has been disabled.',
          hindi: 'यह खाता अक्षम कर दिया गया है।',
          tamil: 'இந்த கணக்கு முடக்கப்பட்டுள்ளது.',
          kannada: 'ಈ ಖಾತೆಯನ್ನು ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ.',
          malayalam: 'ഈ അക്കൗണ്ട് അപ്രാപ്തമാക്കിയിരിക്കുന്നു.',
          marathi: 'हे खाते अक्षम केले गेले आहे.',
          gujarati: 'આ એકાઉન્ટ નિષ્ક્રિય કરવામાં આવ્યું છે.',
          bengali: 'এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।',
          punjabi: 'ਇਹ ਖਾਤਾ ਅਯੋਗ ਕਰ ਦਿੱਤਾ ਗਿਆ ਹੈ।',
          odia: 'ଏହି ଖାତା ନିଷ୍କ୍ରିୟ କରାଯାଇଛି।',
          assamese: 'এই একাউণ্টটো নিষ্ক্ৰিয় কৰা হৈছে।',
          konkani: 'हें खातें बंद केलां.',
          nepali: 'यो खाता असक्षम पारिएको छ।',
          meitei: 'Ashi account asi thadok-khraba.',
          mizo: 'He account hi tihtawp a ni.',
          kashmiri: 'یہِ اکاوُنٛٹ چھُ بند کرنہٕ آمُت۔',
          ladakhi: 'རྩིས་ཁྲ་འདི་བཀག་ཡོད།',
        );
      case 'user-not-found':
        return strings.localized(
          telugu: 'ఈ ఇమెయిల్‌కు ఖాతా కనిపించలేదు.',
          english: 'No account found for this email.',
          hindi: 'इस ईमेल के लिए कोई खाता नहीं मिला।',
          tamil: 'இந்த மின்னஞ்சலுக்கு எந்த கணக்கும் காணப்படவில்லை.',
          kannada: 'ಈ ಇಮೇಲ್‌ಗೆ ಯಾವುದೇ ಖಾತೆ ಕಂಡುಬಂದಿಲ್ಲ.',
          malayalam: 'ഈ ഇമെയിലിനായി ഒരു അക്കൗണ്ടും കണ്ടെത്തിയില്ല.',
          marathi: 'या ईमेलसाठी कोणतेही खाते सापडले नाही.',
          gujarati: 'આ ઇમેઇલ માટે કોઈ એકાઉન્ટ મળ્યું નથી.',
          bengali: 'এই ইমেলের জন্য কোনো অ্যাকাউন্ট পাওয়া যায়নি।',
          punjabi: 'ਇਸ ਈਮੇਲ ਲਈ ਕੋਈ ਖਾਤਾ ਨਹੀਂ ਮਿਲਿਆ।',
          odia: 'ଏହି ଇମେଲ୍ ପାଇଁ କୌଣସି ଖାତା ମିଳିଲା ନାହିଁ।',
          assamese: 'এই ইমেইলৰ বাবে কোনো একাউণ্ট পোৱা নগ’ল।',
          konkani: 'ह्या ईमेला खातीर खातें मेळ्ळें ना.',
          nepali: 'यस इमेलको लागि कुनै खाता भेटिएन।',
          meitei: 'Email asigi account thengnakhide.',
          mizo: 'He email tan hian account a awm lo.',
          kashmiri: 'امِ ای میل باپتھ میول نہ کانہہ اکاوُنٛٹ۔',
          ladakhi: 'email འདིར་རྩིས་ཁྲ་མ་རྙེད།',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return strings.localized(
          telugu: 'ఇమెయిల్ లేదా పాస్‌వర్డ్ సరైనది కాదు.',
          english: 'Incorrect email or password.',
          hindi: 'गलत ईमेल या पासवर्ड।',
          tamil: 'தவறான மின்னஞ்சல் அல்லது கடவுச்சொல்.',
          kannada: 'ತಪ್ಪಾದ ಇಮೇಲ್ ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್.',
          malayalam: 'തെറ്റായ ഇമെയിൽ അല്ലെങ്കിൽ പാസ്‌വേഡ്.',
          marathi: 'चुकीचा ईमेल किंवा पासवर्ड.',
          gujarati: 'ખોટો ઇમેઇલ અથવા પાસવર્ડ.',
          bengali: 'ভুল ইমেল বা পাসওয়ার্ড।',
          punjabi: 'ਗਲਤ ਈਮੇਲ ਜਾਂ ਪਾਸਵਰਡ।',
          odia: 'ଭୁଲ୍ ଇମେଲ୍ କିମ୍ବା ପାସୱାର୍ଡ।',
          assamese: 'ভুল ইমেইল বা পাছৱৰ্ড।',
          konkani: 'चूक ईमेल वा पासवर्ड.',
          nepali: 'गलत इमेल वा पासवर्ड।',
          meitei: 'Email natraga password aranba.',
          mizo: 'Email emaw password emaw a dik lo.',
          kashmiri: 'غلط ای میل یا پاس ورڈ۔',
          ladakhi: 'email ཡང་ན་ password མི་འགྲིག',
        );
      case 'email-already-in-use':
        return strings.localized(
          telugu: 'ఈ ఇమెయిల్‌తో ఇప్పటికే ఖాతా ఉంది.',
          english: 'An account already exists with this email.',
          hindi: 'इस ईमेल से पहले से एक खाता मौजूद है।',
          tamil: 'இந்த மின்னஞ்சலில் ஏற்கனவே ஒரு கணக்கு உள்ளது.',
          kannada: 'ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಈಗಾಗಲೇ ಖಾತೆಯಿದೆ.',
          malayalam: 'ഈ ഇമെയിലിൽ ഇതിനകം ഒരു അക്കൗണ്ട് ഉണ്ട്.',
          marathi: 'या ईमेलवर आधीच एक खाते अस्तित्वात आहे.',
          gujarati: 'આ ઇમેઇલ સાથે પહેલેથી જ એક એકાઉન્ટ છે.',
          bengali: 'এই ইমেলের সাথে ইতিমধ্যে একটি অ্যাকাউন্ট রয়েছে।',
          punjabi: 'ਇਸ ਈਮੇਲ ਨਾਲ ਪਹਿਲਾਂ ਹੀ ਇੱਕ ਖਾਤਾ ਮੌਜੂਦ ਹੈ।',
          odia: 'ଏହି ଇମେଲ୍ ସହିତ ପୂର୍ବରୁ ଏକ ଖାତା ରହିଛି।',
          assamese: 'এই ইমেইলৰ সৈতে ইতিমধ্যে এটা একাউণ্ট আছে।',
          konkani: 'ह्या ईमेलाचेर पयलींच खातें आसा.',
          nepali: 'यस इमेलसँग पहिले नै एउटा खाता अवस्थित छ।',
          meitei: 'Email asida account ama leitheng leire.',
          mizo: 'He email-ah hian account a awm tawh.',
          kashmiri: 'امِ ای میل سۭتۍ چھُ گۄڈے اکھ اکاوُنٛٹ موجود۔',
          ladakhi: 'email འདིར་རྩིས་ཁྲ་སྔོན་ནས་ཡོད།',
        );
      case 'email-already-in-use-google':
      case 'use-google-for-this-email':
        return strings.localized(
          telugu: 'ఈ ఖాతాకు Google తోనే continue చేయాలి.',
          english: 'Continue with Google for this account.',
          hindi: 'इस खाते के लिए Google के साथ जारी रखें।',
          tamil: 'இந்த கணக்கிற்கு Google மூலம் தொடரவும்.',
          kannada: 'ಈ ಖಾತೆಗಾಗಿ Google ನೊಂದಿಗೆ ಮುಂದುವರಿಯಿರಿ.',
          malayalam: 'ഈ അക്കൗണ്ടിനായി Google ഉപയോഗിച്ച് തുടരുക.',
          marathi: 'या खात्यासाठी Google सह सुरू ठेवा.',
          gujarati: 'આ એકાઉન્ટ માટે Google સાથે આગળ વધો.',
          bengali: 'এই অ্যাকাউন্টের জন্য Google দিয়ে চালিয়ে যান।',
          punjabi: 'ਇਸ ਖਾਤੇ ਲਈ Google ਨਾਲ ਜਾਰੀ ਰੱਖੋ।',
          odia: 'ଏହି ଖାତା ପାଇଁ Google ସହିତ ଜାରି ରଖନ୍ତୁ।',
          assamese: 'এই একাউণ্টৰ বাবে Google-ৰ সৈতে আগবাঢ়ক।',
          konkani: 'ह्या खात्या खातीर Google वरवीं फुडें वचात.',
          nepali: 'यस खाताको लागि Google बाट जारी राख्नुहोस्।',
          meitei: 'Account asigi Google gi mathou tari.',
          mizo: 'He account tan hian Google hmangin chhunzawm rawh.',
          kashmiri: 'امِ اکاوُنٛٹ باپتھ کٔریو گوگل سۭتۍ جٲری۔',
          ladakhi: 'རྩིས་ཁྲ་འདིའི་ཆེད་དུ་ Google མཉམ་དུ་མུ་མཐུད།',
        );
      case 'weak-password':
        return strings.passwordError;
      case 'popup-blocked':
        return strings.localized(
          telugu: 'Google login popup block అయింది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In popup was blocked. Try again.',
          hindi: 'Google साइन-इन पॉपअप ब्लॉक हो गया था। पुन: प्रयास करें।',
          tamil: 'Google உள்நுழைவு பாப்அப் தடுக்கப்பட்டது. மீண்டும் முயல்க.',
          kannada: 'Google ಸೈನ್-ಇನ್ ಪಾಪ್‌ಅಪ್ ನಿರ್ಬಂಧಿಸಲಾಗಿದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'Google സൈൻ-ഇൻ പോപ്പ്അപ്പ് തടഞ്ഞു. വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'Google साइन-इन पॉपअप ब्लॉक केले होते. पुन्हा प्रयत्न करा.',
          gujarati: 'Google સાઇન-ઇન પોપઅપ બ્લોક થઈ ગયું. ફરી પ્રયાસ કરો.',
          bengali: 'Google সাইন-ইন পপআপ ব্লক করা হয়েছে। আবার চেষ্টা করুন।',
          punjabi: 'Google ਸਾਈਨ-ਇਨ ਪੌਪਅੱਪ ਬਲੌਕ ਹੋ ਗਿਆ ਸੀ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'Google ସାଇନ୍-ଇନ୍ ପପ୍ଅପ୍ ବ୍ଲକ୍ ହୋଇଛି। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'Google ছাইন-ইন পপআপ ব্লক কৰা হ’ল। পুনৰ চেষ্টা কৰক।',
          konkani: 'Google साइन-इन पॉपअप ब्लॉक जालो. परत प्रयत्न करात.',
          nepali: 'Google साइन-इन पपअप अवरुद्ध भयो। पुन: प्रयास गर्नुहोस्।',
          meitei: 'Google Sign-In popup block toukhraba. Amuk hanna hotnabiyu.',
          mizo: 'Google Sign-In popup block a ni. Ti nawn leh rawh.',
          kashmiri: 'گوگل سائن اِن پاپ اپ روٗد بلاک۔ دۆبارٕ کٔریو کوشِش۔',
          ladakhi: 'Google sign-in popup བཀག་ཡོད། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
        );
      case 'popup-closed-by-user':
      case 'google-canceled':
        return strings.localized(
          telugu: 'Google login cancel అయింది.',
          english: 'Google Sign-In was canceled.',
          hindi: 'Google साइन-इन रद्द कर दिया गया था।',
          tamil: 'Google உள்நுழைவு ரத்து செய்யப்பட்டது.',
          kannada: 'Google ಸೈನ್-ಇನ್ ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ.',
          malayalam: 'Google സൈൻ-ഇൻ റദ്ദാക്കി.',
          marathi: 'Google साइन-इन रद्द केले गेले.',
          gujarati: 'Google સાઇન-ઇન રદ કરવામાં આવ્યું.',
          bengali: 'Google সাইন-ইন বাতিল করা হয়েছে।',
          punjabi: 'Google ਸਾਈਨ-ਇਨ ਰੱਦ ਕਰ ਦਿੱਤਾ ਗਿਆ ਸੀ।',
          odia: 'Google ସାଇନ୍-ଇନ୍ ବାତିଲ୍ ହେଲା।',
          assamese: 'Google ছাইন-ইন বাতিল কৰা হ’ল।',
          konkani: 'Google साइन-इन रद्द जाला.',
          nepali: 'Google साइन-इन रद्द गरियो।',
          meitei: 'Google Sign-In cancel toukhraba.',
          mizo: 'Google Sign-In sut a ni.',
          kashmiri: 'گوگل سائن اِن آو منسوخ کرنہٕ۔',
          ladakhi: 'Google sign-in ཕྱིར་འཐེན་བྱས།',
        );
      case 'google-interrupted':
      case 'cancelled-popup-request':
        return strings.localized(
          telugu: 'Google login మధ్యలో ఆగింది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In was interrupted. Please try again.',
          hindi: 'Google साइन-इन बाधित हुआ। कृपया पुनः प्रयास करें।',
          tamil: 'Google உள்நுழைவு தடைபட்டது. மீண்டும் முயற்சிக்கவும்.',
          kannada: 'Google ಸೈನ್-ಇನ್ ಅಡಚಣೆಯಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'Google സൈൻ-ഇൻ തടസ്സപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'Google साइन-इन व्यत्यय आला. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'Google સાઇન-ઇનમાં વિક્ષેપ પડ્યો. ફરી પ્રયાસ કરો.',
          bengali: 'Google সাইন-ইন ব্যাহত হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi: 'Google ਸਾਈਨ-ਇਨ ਵਿੱਚ ਰੁਕਾਵਟ ਆਈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'Google ସାଇନ୍-ଇନ୍ ବାଧାପ୍ରାପ୍ତ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'Google ছাইন-ইন বাধাপ্ৰাপ্ত হৈছে। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'Google साइन-इनांत अडचण आयली. उपकार करून परत प्रयत्न करात.',
          nepali: 'Google साइन-इन अवरुद्ध भयो। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'Google Sign-In thabakta athiba thok-e. Amuk hanna hotnabiyu.',
          mizo: 'Google Sign-In a tikhawpa. Khawngaihin ti nawn leh rawh.',
          kashmiri: 'گوگل سائن اِنس منز رُکاوٹ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
          ladakhi: 'Google sign-in བར་ཆད་བྱུང། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
        );
      case 'network-request-failed':
        return strings.localized(
          telugu: 'ఇంటర్నెట్ సమస్య ఉంది. కనెక్షన్ చెక్ చేయండి.',
          english: 'Network issue. Please check your internet connection.',
          hindi: 'नेटवर्क समस्या। कृपया अपना इंटरनेट कनेक्शन जांचें।',
          tamil: 'நெட்வொர்க் பிரச்சனை. உங்கள் இணைய இணைப்பைச் சரிபார்க்கவும்.',
          kannada: 'ನೆಟ್‌ವರ್ಕ್ ಸಮಸ್ಯೆ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.',
          malayalam: 'നെറ്റ്‌വർക്ക് പ്രശ്നം. നിങ്ങളുടെ ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിക്കുക.',
          marathi: 'नेटवर्क समस्या. कृपया तुमचे इंटरनेट कनेक्शन तपासा.',
          gujarati: 'નેટવર્ક સમસ્યા. કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો.',
          bengali: 'নেটওয়ার্ক সমস্যা। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
          punjabi: 'ਨੈੱਟਵਰਕ ਸਮੱਸਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਇੰਟਰਨੈਟ ਕਨੈਕਸ਼ਨ ਜਾਂਚੋ।',
          odia: 'ନେଟୱାର୍କ ସମସ୍ୟା। ଦୟାକରି ଆପଣଙ୍କ ଇଣ୍ଟରନେଟ୍ ସଂଯୋଗ ଯାଞ୍ଚ କରନ୍ତୁ।',
          assamese: 'নেটৱৰ্ক সমস্যা। অনুগ্ৰহ কৰি আপোনাৰ ইন্টাৰনেট সংযোগ পৰীক্ষা কৰক।',
          konkani: 'नेटवर्क समस्या. उपकार करून तुमचें इंटरनेट कनेक्शन तपासात.',
          nepali: 'नेटवर्क समस्या। कृपया आफ्नो इन्टरनेट जडान जाँच गर्नुहोस्।',
          meitei: 'Network problem leiri. Internet connection check toubiyu.',
          mizo: 'Network buaina a awm. Khawngaihin internet connection en rawh.',
          kashmiri: 'نیٹ ورک مَسلہٕ۔ مہربٲنی کٔرتھ پنُن اِنٹرنیٹ کنکشن چیک کٔریو۔',
          ladakhi: 'Network དཀའ་ངལ། ཁྱེད་ཀྱི་ internet ཞིབ་བཤེར་གནང།',
        );
      case 'too-many-requests':
        return strings.localized(
          telugu: 'చాలా ప్రయత్నాలు అయ్యాయి. కొంచెం తర్వాత మళ్లీ ప్రయత్నించండి.',
          english: 'Too many attempts. Please wait and try again.',
          hindi: 'बहुत सारे प्रयास किए गए। कृपया थोड़ी देर बाद पुनः प्रयास करें।',
          tamil: 'பல முயற்சிகள் செய்யப்பட்டன. சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ಬಹಳಷ್ಟು ಪ್ರಯತ್ನಗಳು ನಡೆದಿವೆ. ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯ ಕಾಯಿರಿ ಮತ್ತು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'നിരവധി ശ്രമങ്ങൾ നടന്നു. ദയവായി കുറച്ച് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'बरेच प्रयत्न झाले. कृपया थोडा वेळ थांबून पुन्हा प्रयत्न करा.',
          gujarati: 'ઘણા પ્રયાસો થયા. કૃપા કરીને થોડીવાર પછી ફરી પ્રયાસ કરો.',
          bengali: 'অনেক প্রচেষ্টা করা হয়েছে। অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করে আবার চেষ্টা করুন।',
          punjabi: 'ਬਹੁਤ ਸਾਰੀਆਂ ਕੋਸ਼ਿਸ਼ਾਂ ਹੋ ਚੁੱਕੀਆਂ ਹਨ। ਕਿਰਪਾ ਕਰਕੇ ਥੋੜ੍ਹੀ ਦੇਰ ਬਾਅਦ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଅତ୍ୟଧିକ ପ୍ରୟାସ ହୋଇଛି। ଦୟାକରି କିଛି ସମୟ ପରେ ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'বহুতো চেষ্টা কৰা হৈছে। অনুগ্ৰহ কৰি কিছু সময় অপেক্ষা কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'खूब प्रयत्न जाले. उपकार करून थोड्या वेळान परत प्रयत्न करात.',
          nepali: 'धेरै प्रयासहरू भए। कृपया केही बेर पर्खनुहोस् र पुन: प्रयास गर्नुहोस्।',
          meitei: 'Yamnaba hotnarak-e. Khara ngairaga amuk hanna hotnabiyu.',
          mizo: 'Beih a tam lutuk. Khawngaihin nghak lawk la ti nawn leh rawh.',
          kashmiri: 'واریاہ کوشِشہٕ گٔیہٕ۔ مہربٲنی کٔرتھ کینٛژھہ کالہٕ پتہٕ دۆبارٕ کٔریو کوشِش۔',
          ladakhi: 'ཐེངས་མང་འབད་བརྩོན་བྱས། ཅུང་ཙམ་སྒུག་ནས་ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
        );
      case 'google-sign-in-incomplete':
      case 'google-client-configuration-error':
      case 'google-provider-configuration-error':
        return strings.localized(
          telugu: 'Google login setup పూర్తి కాలేదు.',
          english: 'Google Sign-In setup is incomplete.',
          hindi: 'Google साइन-इन सेटअप अधूरा है।',
          tamil: 'Google உள்நுழைவு அமைப்பு முழுமையடையவில்லை.',
          kannada: 'Google ಸೈನ್-ಇನ್ ಸೆಟಪ್ ಅಪೂರ್ಣವಾಗಿದೆ.',
          malayalam: 'Google സൈൻ-ഇൻ സജ്ജീകരണം അപൂർണ്ണമാണ്.',
          marathi: 'Google साइन-इन सेटअप अपूर्ण आहे.',
          gujarati: 'Google સાઇન-ઇન સેટઅપ અધૂરું છે.',
          bengali: 'Google সাইন-ইন সেটআপ অসম্পূর্ণ।',
          punjabi: 'Google ਸਾਈਨ-ਇਨ ਸੈੱਟਅੱਪ ਅਧੂਰਾ ਹੈ।',
          odia: 'Google ସାଇନ୍-ଇନ୍ ସେଟଅପ୍ ଅସମ୍ପୂର୍ଣ୍ଣ।',
          assamese: 'Google ছাইন-ইন ছেটআপ অসম্পূৰ্ণ।',
          konkani: 'Google साइन-इन सेटअप अपूर्ण आसा.',
          nepali: 'Google साइन-इन सेटअप अपूर्ण छ।',
          meitei: 'Google Sign-In setup mapung phade.',
          mizo: 'Google Sign-In setup a la zo lo.',
          kashmiri: 'گوگل سائن اِن سیٹ اپ چھُ نامکمل۔',
          ladakhi: 'Google sign-in བཟོ་སྒྲིག་ཆ་མ་ཚང།',
        );
      case 'google-ui-unavailable':
      case 'unsupported-platform':
        return strings.localized(
          telugu: 'ఈ డివైస్‌లో Google login ప్రస్తుతం అందుబాటులో లేదు.',
          english: 'Google Sign-In is not available on this device right now.',
          hindi: 'इस डिवाइस पर अभी Google साइन-इन उपलब्ध नहीं है।',
          tamil: 'இந்த சாதனத்தில் தற்போது Google உள்நுழைவு கிடைக்கவில்லை.',
          kannada: 'ಈ ಸಾಧನದಲ್ಲಿ ಪ್ರಸ್ತುತ Google ಸೈನ್-ಇನ್ ಲಭ್ಯವಿಲ್ಲ.',
          malayalam: 'ഈ ഉപകരണത്തിൽ ഇപ്പോൾ Google സൈൻ-ഇൻ ലഭ്യമല്ല.',
          marathi: 'या डिव्हाइसवर सध्या Google साइन-इन उपलब्ध नाही.',
          gujarati: 'આ ઉપકરણ પર હાલમાં Google સાઇન-ઇન ઉપલબ્ધ નથી.',
          bengali: 'এই ডিভাইসে বর্তমানে Google সাইন-ইন উপলব্ধ নেই।',
          punjabi: 'ਇਸ ਡਿਵਾਈਸ ਤੇ ਇਸ ਵੇਲੇ Google ਸਾਈਨ-ਇਨ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
          odia: 'ଏହି ଡିଭାଇସ୍‌ରେ ବର୍ତ୍ତମାନ Google ସାଇନ୍-ଇନ୍ ଉପଲବ୍ଧ ନାହିଁ।',
          assamese: 'এই ডিভাইচত বৰ্তমান Google ছাইন-ইন উপলব্ধ নহয়।',
          konkani: 'ह्या उपकरणाचेर सध्या Google साइन-इन उपलब्ध ना.',
          nepali: 'यस उपकरणमा हाल Google साइन-इन उपलब्ध छैन।',
          meitei: 'Device asida houjik Google Sign-In leite.',
          mizo: 'He device-ah hian tunah Google Sign-In a hman theih loh.',
          kashmiri: 'امِ ڈیوائسس پؠٹھ چھُ نہٕ فی الحال گوگل سائن اِن دستِیاب۔',
          ladakhi: 'ལག་ཆས་འདིར་ Google sign-in མི་ཐོབ།',
        );
      case 'not-configured':
        return strings.localized(
          telugu: 'ఈ build లో authentication setup పూర్తి కాలేదు.',
          english: 'Authentication is not configured on this build.',
          hindi: 'इस बिल्ड पर प्रमाणीकरण कॉन्फ़िगर नहीं है।',
          tamil: 'இந்த உருவாக்கத்தில் அங்கீகரிப்பு கட்டமைக்கப்படவில்லை.',
          kannada: 'ಈ ಬಿಲ್ಡ್‌ನಲ್ಲಿ ದೃಢೀಕರಣವನ್ನು ಕಾನ್ಫಿಗರ್ ಮಾಡಲಾಗಿಲ್ಲ.',
          malayalam: 'ഈ ബിൽഡിൽ പ്രാമാണീകരണം കോൺഫിഗർ ചെയ്തിട്ടില്ല.',
          marathi: 'या बिल्डवर प्रमाणीकरण कॉन्फिगर केलेले नाही.',
          gujarati: 'આ બિલ્ડ પર ઓથેન્ટિકેશન રૂપરેખાંકિત નથી.',
          bengali: 'এই বিল্ডে প্রমাণীকরণ কনফিগার করা নেই।',
          punjabi: 'ਇਸ ਬਿਲਡ ਤੇ ਪ੍ਰਮਾਣੀਕਰਨ ਕੌਂਫਿਗਰ ਨਹੀਂ ਹੈ।',
          odia: 'ଏହି ବିଲ୍ଡରେ ପ୍ରମାଣୀକରଣ କନଫିଗର୍ ହୋଇନାହିଁ।',
          assamese: 'এই বিল্ডত প্ৰমাণীকৰণ বিন্যাস কৰা হোৱা নাই।',
          konkani: 'ह्या बिल्डाचेर प्रमाणीकरण संरचित ना.',
          nepali: 'यस निर्माणमा प्रमाणीकरण कन्फिगर गरिएको छैन।',
          meitei: 'Build asida authentication configure toude.',
          mizo: 'He build-ah hian authentication buatsaih a ni lo.',
          kashmiri: 'امِ بلڈس پؠٹھ چھُ نہٕ تصدیق ترتیب دِتھ۔',
          ladakhi: 'build འདིར་ authentication བཟོ་སྒྲིག་མེད།',
        );
      case 'google-timeout':
        return strings.localized(
          telugu: 'Google login ఎక్కువ సమయం తీసుకుంది. మళ్లీ ప్రయత్నించండి.',
          english: 'Google Sign-In timed out. Please try again.',
          hindi: 'Google साइन-इन का समय समाप्त हो गया। कृपया पुनः प्रयास करें।',
          tamil: 'Google உள்நுழைவு காலாவதியானது. மீண்டும் முயற்சிக்கவும்.',
          kannada: 'Google ಸೈನ್-ಇನ್ ಸಮಯ ಮೀರಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'Google സൈൻ-ഇൻ സമയം കഴിഞ്ഞു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'Google साइन-इन कालबाह्य झाले. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'Google સાઇન-ઇન સમય સમાપ્ત થયો. ફરી પ્રયાસ કરો.',
          bengali: 'Google সাইন-ইনের সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
          punjabi: 'Google ਸਾਈਨ-ਇਨ ਦਾ ਸਮਾਂ ਸਮਾਪਤ ਹੋ ਗਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'Google ସାଇନ୍-ଇନ୍ ସମୟ ସମାପ୍ତ ହୋଇଛି। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'Google ছাইন-ইনৰ সময় শেষ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'Google साइन-इनाचो वेळ सोंपलो. उपकार करून परत प्रयत्न करात.',
          nepali: 'Google साइन-इन समय समाप्त भयो। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'Google Sign-In time out oikhre. Amuk hanna hotnabiyu.',
          mizo: 'Google Sign-In hun a ral. Khawngaihin ti nawn leh rawh.',
          kashmiri: 'گوگل سائن اِنُک وقت گوو ختم۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
          ladakhi: 'Google sign-in དུས་ཚོད་རྫོགས། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
        );
      case 'google-sign-in-failed':
      case 'google-unknown-error':
      default:
        return error.message.trim().isNotEmpty
            ? error.message.trim()
            : strings.localized(
                telugu: 'Google login విఫలమైంది. మళ్లీ ప్రయత్నించండి.',
                english: 'Google Sign-In failed. Please try again.',
                hindi: 'Google साइन-इन विफल रहा। कृपया पुनः प्रयास करें।',
                tamil: 'Google உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
                kannada: 'Google ಸೈನ್-ಇನ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                malayalam: 'Google സൈൻ-ഇൻ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
                marathi: 'Google साइन-इन अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.',
                gujarati: 'Google સાઇન-ઇન નિષ્ફળ ગયું. ફરી પ્રયાસ કરો.',
                bengali: 'Google সাইন-ইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
                punjabi: 'Google ਸਾਈਨ-ਇਨ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                odia: 'Google ସାଇନ୍-ଇନ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
                assamese: 'Google ছাইন-ইন ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
                konkani: 'Google साइन-इन अपेशी जालें. उपकार करून परत प्रयत्न करात.',
                nepali: 'Google साइन-इन असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
                meitei: 'Google Sign-In maipak-khide. Amuk hanna hotnabiyu.',
                mizo: 'Google Sign-In a tlawlh. Khawngaihin ti nawn leh rawh.',
                kashmiri: 'گوگل سائن اِن گوو ناکام۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
                ladakhi: 'Google sign-in ཕམ་བྱུང། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
              );
    }
  }

  Future<void> _continueAfterAuth() async {
    await _stabilizeBottomSystemUi();
    await AppFlowService.persistLastKnownAuthUid(_service.currentUser?.uid);
    unawaited(AppRegionService.ensureRemoteSelectionSynced());
    unawaited(AppPartyPreferenceService.syncStoredSelectionToRemote());
    await AppFlowService.loadSnapshot();
    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final String nextRoute =
        await AppFlowService.resolveAuthenticatedEntryRoute();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  Future<void> _openLegalDocument(LegalDocumentType type) async {
    final String url = type == LegalDocumentType.privacyPolicy
        ? AppPublicInfo.privacyPolicyUrl
        : AppPublicInfo.termsUrl;
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      final bool openedExternally = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternally) {
        return;
      }
      final bool openedInDefaultMode = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (openedInDefaultMode) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          context.strings.localized(
            telugu: 'లీగల్ పేజీ తెరవలేకపోయాము. మళ్లీ ప్రయత్నించండి.',
            english: 'Unable to open legal page. Please try again.',
            hindi: 'कानूनी पृष्ठ खोलने में असमर्थ। कृपया पुनः प्रयास करें।',
            tamil: 'சட்டப் பக்கத்தைத் திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
            kannada: 'ಕಾನೂನು ಪುಟವನ್ನು ತೆರೆಯಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
            malayalam: 'നിയമപരമായ പേജ് തുറക്കാൻ കഴിഞ്ഞില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
            marathi: 'कायदेशीर पृष्ठ उघडण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.',
            gujarati: 'કાનૂની પૃષ્ઠ ખોલવામાં અસમર્થ. ફરી પ્રયાસ કરો.',
            bengali: 'আইনি পৃষ্ঠা খোলা যাচ্ছে না। আবার চেষ্টা করুন।',
            punjabi: 'ਕਾਨੂੰਨੀ ਪੰਨਾ ਖੋਲ੍ਹਣ ਵਿੱਚ ਅਸਮਰੱਥ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
            odia: 'ଆଇନଗତ ପୃଷ୍ଠା ଖୋଲିବାରେ ଅସମର୍ଥ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
            assamese: 'আইনী পৃষ্ঠা খুলিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
            konkani: 'कायद्याचें पान उकतें करूंक शकलें ना. उपकार करून परत प्रयत्न करात.',
            nepali: 'कानूनी पृष्ठ खोल्न असमर्थ। कृपया पुन: प्रयास गर्नुहोस्।',
            meitei: 'Legal page hangdokpa ngamde. Amuk hanna hotnabiyu.',
            mizo: 'Legal page hawng thei lo. Khawngaihin ti nawn leh rawh.',
            kashmiri: 'قانونی صفحہ کھوٗلنس منز ناکامی۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
            ladakhi: 'ཁྲིམས་མཐུན་ཤོག་ལྷེ་ཁ་འབྱེད་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _LoginUiCopy copy = _LoginUiCopy(context.currentLanguage);
    final String screenTitle = context.strings.localized(
      telugu: 'మన పోస్టర్ AI',
      english: 'Mana Poster AI',
      hindi: 'माना पोस्टर AI',
      tamil: 'மனா போஸ்டர் AI',
      kannada: 'ಮನ ಪೋಸ್ಟರ್ AI',
      malayalam: 'മന പോസ്റ്റർ AI',
      marathi: 'मना पोस्टर AI',
      gujarati: 'મના પોસ્ટર AI',
      bengali: 'মনা পোস্টার AI',
      punjabi: 'ਮਨਾ ਪੋਸਟਰ AI',
      odia: 'ମନା ପୋଷ୍ଟର AI',
      assamese: 'মনা পোষ্টাৰ AI',
      konkani: 'मना पोस्टर AI',
      nepali: 'मना पोस्टर AI',
      meitei: 'Mana Poster AI',
      mizo: 'Mana Poster AI',
      kashmiri: 'منا پوسٹر AI',
      ladakhi: 'མན་ན་པོ་སི་ཊར་ AI',
    );
    final String screenSubtitle = context.strings.localized(
      telugu:
          'రోజువారీ పోస్టర్లు, కస్టమైజేషన్, షేర్ మరియు డౌన్‌లోడ్‌ల కోసం సురక్షితంగా కొనసాగండి.',
      english:
          'Continue securely to access daily posters, customization, sharing, and downloads.',
      hindi:
          'दैनिक पोस्टर, कस्टमाइज़ेशन, शेयर और डाउनलोड के लिए सुरक्षित रूप से जारी रखें।',
      tamil:
          'தினசரி போஸ்டர்கள், தனிப்பயனாக்கம், பகிர்வு மற்றும் பதிவிறக்கங்களுக்குப் பாதுகாப்பாகத் தொடரவும்.',
      kannada:
          'ದೈನಂದಿನ ಪೋಸ್ಟರ್‌ಗಳು, ಗ್ರಾಹಕೀಕರಣ, ಹಂಚಿಕೆ ಮತ್ತು ಡೌನ್‌ಲೋಡ್‌ಗಳಿಗಾಗಿ ಸುರಕ್ಷಿತವಾಗಿ ಮುಂದುವರಿಯಿರಿ.',
      malayalam:
          'ദൈനംദിന പോസ്റ്ററുകൾ, ഇഷ്‌ടാനുസൃതമാക്കൽ, പങ്കിടൽ, ഡൗൺലോഡുകൾ എന്നിവയ്‌ക്കായി സുരക്ഷിതമായി തുടരുക.',
      marathi:
          'दैनंदिन पोस्टर्स, कस्टमायझेशन, शेअर आणि डाउनलोडसाठी सुरक्षितपणे सुरू ठेवा.',
      gujarati:
          'દૈનિક પોસ્ટરો, કસ્ટમાઇઝેશન, શેરિંગ અને ડાઉનલોડ માટે સુરક્ષિત રીતે આગળ વધો.',
      bengali:
          'দৈনিক পোস্টার, কাস্টমাইজেশন, শেয়ার এবং ডাউনলোডের জন্য নিরাপদে চালিয়ে যান।',
      punjabi:
          'ਰੋਜ਼ਾਨਾ ਪੋਸਟਰਾਂ, ਅਨੁਕੂਲਤਾ, ਸਾਂਝਾਕਰਨ ਅਤੇ ਡਾਊਨਲੋਡਾਂ ਲਈ ਸੁਰੱਖਿਅਤ ਢੰਗ ਨਾਲ ਜਾਰੀ ਰੱਖੋ।',
      odia:
          'ଦୈନିକ ପୋଷ୍ଟର, କଷ୍ଟମାଇଜେସନ୍, ସେୟାର ଏବଂ ଡାଉନଲୋଡ୍ ପାଇଁ ସୁରକ୍ଷିତ ଭାବେ ଜାରି ରଖନ୍ତୁ।',
      assamese:
          'দৈনিক পোষ্টাৰ, অনুকূলন, শ্বেয়াৰ আৰু ডাউনলোডৰ বাবে সুৰক্ষিতভাৱে আগবাঢ়ক।',
      konkani:
          'दिसावडे पोस्टर्स, कस्टमायझेशन, शेअर आनी डाऊनलोड खातीर सुरक्षीतपणान फुडें वचात.',
      nepali:
          'दैनिक पोस्टरहरू, अनुकूलन, साझेदारी र डाउनलोडहरूको लागि सुरक्षित रूपमा जारी राख्नुहोस्।',
      meitei:
          'Daily poster, customization, share amasung download gi su-rekhiphana makha chatbiyu.',
      mizo:
          'Ni tin poster, siam danglam, thawn leh download atan him takin chhunzawm rawh.',
      kashmiri:
          'روزانہ پوسٹر، کسٹمائزیشن، شیئر تہٕ ڈاؤنلوڈ باپتھ کٔریو حفاظت سان جٲری۔',
      ladakhi:
          'ཉིན་རེའི་ poster དང་ customization, share, download ཆེད་དུ་བདེ་འཇགས་ངང་མུ་མཐུད།',
    );
    final String googleButtonLabel = context.strings.localized(
      telugu: 'Google తో కొనసాగండి',
      english: 'Continue with Google',
      hindi: 'Google के साथ जारी रखें',
      tamil: 'Google மூலம் தொடரவும்',
      kannada: 'Google ನೊಂದಿಗೆ ಮುಂದುವರಿಯಿರಿ',
      malayalam: 'Google ഉപയോഗിച്ച് തുടരുക',
      marathi: 'Google সহ सुरू ठेवा',
      gujarati: 'Google સાથે આગળ વધો',
      bengali: 'Google দিয়ে চালিয়ে যান',
      punjabi: 'Google ਨਾਲ ਜਾਰੀ ਰੱਖੋ',
      odia: 'Google ସହିତ ଜାରି ରଖନ୍ତୁ',
      assamese: 'Google-ৰ সৈতে আগবাঢ়ক',
      konkani: 'Google वरवीं फुडें वचात',
      nepali: 'Google बाट जारी राख्नुहोस्',
      meitei: 'Google ga loinana chatbiyu',
      mizo: 'Google hmangin chhunzawm rawh',
      kashmiri: 'گوگل سۭتۍ کٔریو جٲری',
      ladakhi: 'Google མཉམ་དུ་མུ་མཐུད།',
    );
    final String otherOptionsLabel = context.strings.localized(
      telugu: 'ఇతర ఎంపికలు',
      english: 'Other options',
      hindi: 'अन्य विकल्प',
      tamil: 'பிற விருப்பங்கள்',
      kannada: 'ಇತರ ಆಯ್ಕೆಗಳು',
      malayalam: 'മറ്റ് ഓപ്ഷനുകൾ',
      marathi: 'इतर पर्याय',
      gujarati: 'અન્ય વિકલ્પો',
      bengali: 'অন্যান্য বিকল্প',
      punjabi: 'ਹੋਰ ਵਿਕਲਪ',
      odia: 'ଅନ୍ୟାନ୍ୟ ବିକଳ୍ପ',
      assamese: 'অন্যান্য বিকল্প',
      konkani: 'हेर पर्याय',
      nepali: 'अन्य विकल्पहरू',
      meitei: 'Atekey option-sing',
      mizo: 'Duhthlan dangte',
      kashmiri: 'باقی آپشن',
      ladakhi: 'གདམ་ཁ་གཞན་དག',
    );
    final String skipNowLabel = context.strings.localized(
      telugu: 'ప్రస్తుతం దాటవేయండి',
      english: 'Skip now',
      hindi: 'अभी छोड़ें',
      tamil: 'இப்போது தவிர்க்கவும்',
      kannada: 'ಈಗ ಬಿಟ್ಟುಬಿಡಿ',
      malayalam: 'ഇപ്പോൾ ഒഴിവാക്കുക',
      marathi: 'आत्ता वगळा',
      gujarati: 'હમણાં છોડો',
      bengali: 'এখন এড়িয়ে যান',
      punjabi: 'ਹੁਣੇ ਛੱਡੋ',
      odia: 'ବର୍ତ୍ତମାନ ଛାଡନ୍ତୁ',
      assamese: 'এতিয়া বাদ দিয়ক',
      konkani: 'आतांच वगळात',
      nepali: 'अहिले छोड्नुहोस्',
      meitei: 'Houjik thadok-u',
      mizo: 'Kan rih rawh',
      kashmiri: 'فی الحال ترکہِ کٔریو',
      ladakhi: 'ད་ལྟ་འདོར་བ།',
    );
    final String disclaimerLabel = context.strings.localized(
      telugu: 'షేర్, డౌన్‌లోడ్ వంటి కొన్ని చర్యలకు తర్వాత లాగిన్ అవసరం కావచ్చు.',
      english: 'Some actions like sharing and downloading may require login later.',
      hindi: 'शेयर और डाउनलोड जैसी कुछ क्रियाओं के लिए बाद में लॉगिन की आवश्यकता हो सकती है।',
      tamil: 'பகிர்தல், பதிவிறக்குதல் போன்ற சில செயல்களுக்குப் பின்னர் உள்நுழைவு தேவைப்படலாம்.',
      kannada: 'ಹಂಚಿಕೆ ಮತ್ತು ಡೌನ್‌ಲೋಡ್‌ನಂತಹ ಕೆಲವು ಕ್ರಿಯೆಗಳಿಗೆ ನಂತರ ಲಾಗಿನ್ ಅಗತ್ಯವಿರಬಹುದು.',
      malayalam: 'പങ്കിടൽ, ഡൗൺലോഡ് ചെയ്യൽ തുടങ്ങിയ ചില പ്രവർത്തനങ്ങൾക്ക് പിന്നീട് ലോഗിൻ ആവശ്യമായി വന്നേക്കാം.',
      marathi: 'शेअर करणे आणि डाउनलोड करणे यासारख्या काही क्रियांसाठी नंतर लॉगिन आवश्यक असू शकते.',
      gujarati: 'શેરિંગ અને ડાઉનલોડ કરવા જેવી કેટલીક ક્રિયાઓ માટે પછીથી લૉગિન કરવું જરૂરી પડી શકે છે.',
      bengali: 'শেয়ারিং এবং ডাউনলোডের মতো কিছু ক্রিয়াকলাপের জন্য পরবর্তীতে লগইন করার প্রয়োজন হতে পারে।',
      punjabi: 'ਸਾਂਝਾ ਕਰਨ ਅਤੇ ਡਾਊਨਲੋਡ ਕਰਨ ਵਰਗੀਆਂ ਕੁਝ ਕਾਰਵਾਈਆਂ ਲਈ ਬਾਅਦ ਵਿੱਚ ਲੌਗਇਨ ਦੀ ਲੋੜ ਹੋ ਸਕਦੀ ਹੈ।',
      odia: 'ସେୟାର୍ ଏବଂ ଡାଉନଲୋଡ୍ ଭଳି କିଛି କାର୍ଯ୍ୟ ପାଇଁ ପରେ ଲଗଇନ୍ ଆବଶ୍ୟକ ହୋଇପାରେ।',
      assamese: 'শ্বেয়াৰিং আৰু ডাউনলোডৰ দৰে কিছুমান কাৰ্যৰ বাবে পিছত লগইনৰ প্ৰয়োজন হ’ব পাৰে।',
      konkani: 'शेअरिंग आनी डाऊनलोड सारक्या कांय क्रियां खातीर उपरांत लॉगिन गरजेचें आसूं येता.',
      nepali: 'साझेदारी र डाउनलोड जस्ता केही कार्यहरूका लागि पछि लगइन आवश्यक पर्न सक्छ।',
      meitei: 'Share amasung download toubada tungda login touba mathou tarakpa yai.',
      mizo: 'Thawn leh download ang chi hian nakinah login a phut thei.',
      kashmiri: 'شیئر تہٕ ڈاؤنلوڈ ہِوین کامین باپتھ ہیکہٕ پتہٕ لاگ اِن ضرورت پٔتھ۔',
      ladakhi: 'share དང་ download སོགས་ལ་རྗེས་སུ་ login དགོས་སྲིད།',
    );
    final String privacyLabel = context.strings.localized(
      telugu: 'గోప్యతా విధానం',
      english: 'Privacy Policy',
      hindi: 'गोपनीयता नीति',
      tamil: 'தனியுரிமைக் கொள்கை',
      kannada: 'ಗೌಪ್ಯತಾ ನೀತಿ',
      malayalam: 'സ്വകാര്യതാ നയം',
      marathi: 'गोपनीयता धोरण',
      gujarati: 'ગોપનીયતા નીતિ',
      bengali: 'গোপনীয়তা নীতি',
      punjabi: 'ਪਰਦੇਦਾਰੀ ਨੀਤੀ',
      odia: 'ଗୋପନୀୟତା ନୀତି',
      assamese: 'গোপনীয়তা নীতি',
      konkani: 'गोपनीयता धोरण',
      nepali: 'गोपनीयता नीति',
      meitei: 'Privacy Policy',
      mizo: 'Hriattirna leh Dan',
      kashmiri: 'رازداری ہُنٛد اصول',
      ladakhi: 'གསང་རྒྱའི་སྲིད་ཇུས།',
    );
    final String termsLabel = context.strings.localized(
      telugu: 'నిబంధనలు',
      english: 'Terms & Conditions',
      hindi: 'नियम एवं शर्तें',
      tamil: 'விதிமுறைகள் & நிபந்தனைகள்',
      kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
      malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും',
      marathi: 'अटी आणि शर्ती',
      gujarati: 'નિયમો અને શરતો',
      bengali: 'নিয়ম ও শর্তাবলী',
      punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ',
      odia: 'ନିୟମାବଳୀ ଓ ସର୍ତ୍ତାବଳୀ',
      assamese: 'নিয়ম আৰু চৰ্তাৱলী',
      konkani: 'अटी आनी शर्ती',
      nepali: 'नियम र सर्तहरू',
      meitei: 'Terms & Conditions',
      mizo: 'Hman dan tur leh Dan',
      kashmiri: 'شرائط و ضوابط',
      ladakhi: 'ཆ་རྐྱེན་དང་དོན་ཚན།',
    );
    final String andLabel = context.strings.localized(
      telugu: 'మరియు',
      english: 'and',
      hindi: 'और',
      tamil: 'மற்றும்',
      kannada: 'ಮತ್ತು',
      malayalam: 'കൂടാതെ',
      marathi: 'आणि',
      gujarati: 'અને',
      bengali: 'এবং',
      punjabi: 'ਅਤੇ',
      odia: 'ଏବଂ',
      assamese: 'আৰু',
      konkani: 'आनी',
      nepali: 'र',
      meitei: 'amasung',
      mizo: 'leh',
      kashmiri: 'تہٕ',
      ladakhi: 'དང།',
    );

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 88, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            screenTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            screenSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_authBootstrapping) ...<Widget>[
                            const LinearProgressIndicator(minHeight: 2),
                            const SizedBox(height: 20),
                          ],
                          FilledButton(
                            onPressed: _isBusy ? null : _continueWithGoogle,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                if (_loadingGoogle)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                else ...<Widget>[
                                  Container(
                                    width: 34,
                                    height: 34,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: const <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x1F000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/branding/google_logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    googleButtonLabel,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _isBusy
                                ? null
                                : () {
                                    setState(() {
                                      _showOtherOptions = !_showOtherOptions;
                                    });
                                  },
                            icon: Icon(
                              _showOtherOptions
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                            label: Text(
                              otherOptionsLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF0F766E),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 180),
                            crossFadeState: _showOtherOptions
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              children: <Widget>[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: _ModeChip(
                                          label: copy.signInLabel,
                                          selected: _authMode == _AuthMode.login,
                                          onTap: _isBusy
                                              ? null
                                              : () {
                                                  setState(
                                                    () => _authMode = _AuthMode.login,
                                                  );
                                                },
                                        ),
                                      ),
                                      Expanded(
                                        child: _ModeChip(
                                          label: copy.signUpLabel,
                                          selected: _authMode == _AuthMode.signup,
                                          onTap: _isBusy
                                              ? null
                                              : () {
                                                  setState(
                                                    () => _authMode = _AuthMode.signup,
                                                  );
                                                },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const <String>[AutofillHints.email],
                                  decoration: InputDecoration(
                                    hintText: copy.emailHint,
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (String? value) {
                                    if (!_showOtherOptions) {
                                      return null;
                                    }
                                    final String safeValue = (value ?? '').trim();
                                    if (safeValue.isEmpty || !safeValue.contains('@')) {
                                      return context.strings.validEmailError;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: _authMode == _AuthMode.login
                                      ? const <String>[AutofillHints.password]
                                      : const <String>[AutofillHints.newPassword],
                                  onFieldSubmitted: (_) => _continueWithEmail(),
                                  decoration: InputDecoration(
                                    hintText: copy.passwordHint,
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _showPassword = !_showPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                      ),
                                    ),
                                  ),
                                  validator: (String? value) {
                                    if (!_showOtherOptions) {
                                      return null;
                                    }
                                    final String safeValue = value ?? '';
                                    if (safeValue.trim().isEmpty) {
                                      return copy.passwordRequired;
                                    }
                                    if (safeValue.length < 6) {
                                      return context.strings.passwordError;
                                    }
                                    return null;
                                  },
                                ),
                                if (_authMode == _AuthMode.login) ...<Widget>[
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _loadingReset ? null : _sendPasswordReset,
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF0F766E),
                                      ),
                                      child: Text(copy.forgotPasswordLabel),
                                    ),
                                  ),
                                ],
                                PrimaryButton(
                                  label: _authMode == _AuthMode.login
                                      ? copy.signInLabel
                                      : copy.signUpLabel,
                                  icon: Icons.arrow_forward_rounded,
                                  loading: _loadingEmail,
                                  onPressed: _isBusy ? null : _continueWithEmail,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _isBusy ? null : _skipNow,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: const Color(0x330F172A),
                              ),
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                            child: _skipping
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(skipNowLabel),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            disclaimerLabel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 2,
                            children: <Widget>[
                              TextButton(
                                onPressed: () => _openLegalDocument(
                                  LegalDocumentType.privacyPolicy,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                ),
                                child: Text(privacyLabel),
                              ),
                              Text(
                                andLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openLegalDocument(
                                  LegalDocumentType.termsAndConditions,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                ),
                                child: Text(termsLabel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 0,
            child: SafeArea(
              child: AppScreenBackButton(
                fallbackRouteResolver: _resolveBackRoute,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _resolveBackRoute() async {
    final bool hasRegion = await AppRegionService.hasSelection();
    final AppFlowSnapshot snapshot = await AppFlowService.loadSnapshot();
    if (!hasRegion) {
      return AppRoutes.language;
    }
    return snapshot.languageSelected
        ? AppRoutes.appLanguage
        : AppRoutes.language;
  }
}

class _LoginUiCopy {
  const _LoginUiCopy(this.language);

  final AppLanguage language;

  String _localized({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
    String? marathi,
    String? gujarati,
    String? bengali,
    String? punjabi,
    String? odia,
    String? assamese,
    String? konkani,
    String? nepali,
    String? meitei,
    String? mizo,
    String? kashmiri,
    String? ladakhi,
  }) =>
      AppStrings(language).localized(
        telugu: telugu,
        english: english,
        hindi: hindi,
        tamil: tamil,
        kannada: kannada,
        malayalam: malayalam,
        marathi: marathi,
        gujarati: gujarati,
        bengali: bengali,
        punjabi: punjabi,
        odia: odia,
        assamese: assamese,
        konkani: konkani,
        nepali: nepali,
        meitei: meitei,
        mizo: mizo,
        kashmiri: kashmiri,
        ladakhi: ladakhi,
      );

  String get title => _localized(
    telugu: 'Mana Poster లోకి రండి',
    english: 'Continue to Mana Poster',
    hindi: 'Mana Poster में जारी रखें',
    tamil: 'Mana Poster-ல் தொடரவும்',
    kannada: 'Mana Poster ಗೆ ಮುಂದುವರಿಯಿರಿ',
    malayalam: 'Mana Poster-ലേക്ക് തുടരുക',
    marathi: 'Mana Poster मध्ये पुढे जा',
    gujarati: 'Mana Poster માં આગળ વધો',
    bengali: 'Mana Poster-এ এগিয়ে চলুন',
    punjabi: 'Mana Poster ਵਿੱਚ ਜਾਰੀ ਰੱਖੋ',
    odia: 'Mana Poster କୁ ଆଗକୁ ବଢ଼ନ୍ତୁ',
    assamese: 'Mana Poster-লৈ আগবাঢ়ক',
    konkani: 'Mana Poster-आंत फुडें वचात',
    nepali: 'Mana Poster मा जारी राख्नुहोस्',
    meitei: 'Mana Poster da changbiyu',
    mizo: 'Mana Poster-ah chhunzawm rawh',
    kashmiri: 'Mana Poster منز کٔریو جٲری',
    ladakhi: 'Mana Poster ལ་མུ་མཐུད།',
  );

  String get subtitle => _localized(
    telugu: 'Google account తో వెంటనే login అవ్వండి లేదా ఇప్పటికైతే skip చేయండి.',
    english: 'Continue with Google or skip for now.',
    hindi: 'Google खाते से तुरंत लॉगिन करें या अभी छोड़ें।',
    tamil: 'Google கணக்குடன் உள்நுழையவும் அல்லது இப்போது தவிர்க்கவும்.',
    kannada: 'Google ಖಾತೆಯೊಂದಿಗೆ ಲಾಗಿನ್ ಮಾಡಿ ಅಥವಾ ಈಗ ಬಿಟ್ಟುಬಿಡಿ.',
    malayalam: 'Google അക്കൗണ്ട് ഉപയോഗിച്ച് ലോഗിൻ ചെയ്യുക അല്ലെങ്കിൽ ഇപ്പോൾ ഒഴിവാക്കുക.',
    marathi: 'Google खात्यासह लॉगिन करा किंवा आत्ता वगळा.',
    gujarati: 'Google એકાઉન્ટ વડે લૉગિન કરો અથવા હમણાં છોડો.',
    bengali: 'Google অ্যাকাউন্ট দিয়ে লগইন করুন অথবা এখন এড়িয়ে যান।',
    punjabi: 'Google ਖਾਤੇ ਨਾਲ ਲੌਗਇਨ ਕਰੋ ਜਾਂ ਹੁਣੇ ਛੱਡੋ।',
    odia: 'Google ଖାତା ସହିତ ଲଗଇନ୍ କରନ୍ତୁ କିମ୍ବା ବର୍ତ୍ତମାନ ଛାଡନ୍ତୁ।',
    assamese: 'Google একাউণ্টেৰে লগইন কৰক বা এতিয়া বাদ দিয়ক।',
    konkani: 'Google खात्यान लॉगिन करात वा आतांच वगळात.',
    nepali: 'Google खाताबाट लगइन गर्नुहोस् वा अहिले छोड्नुहोस्।',
    meitei: 'Google account na login toubiyu natraga houjik thadok-u.',
    mizo: 'Google account hmangin login la, a nih loh pawhin kan rih rawh.',
    kashmiri: 'گوگل اکاوُنٛٹ سۭتۍ کٔریو لاگ اِن یا فی الحال ترکہِ کٔریو۔',
    ladakhi: 'Google རྩིས་ཁྲས་ login བྱེད་པའམ་ད་ལྟ་འདོར་བ།',
  );

  String get otherOptionsLabel => _localized(
    telugu: 'ఇతర ఎంపికలు',
    english: 'Other options',
    hindi: 'अन्य विकल्प',
    tamil: 'பிற விருப்பங்கள்',
    kannada: 'ಇತರ ಆಯ್ಕೆಗಳು',
    malayalam: 'മറ്റ് ഓപ്ഷനുകൾ',
    marathi: 'इतर पर्याय',
    gujarati: 'અન્ય વિકલ્પો',
    bengali: 'অন্যান্য বিকল্প',
    punjabi: 'ਹੋਰ ਵਿਕਲਪ',
    odia: 'ଅନ୍ୟାନ୍ୟ ବିକଳ୍ପ',
    assamese: 'অন্যান্য বিকল্প',
    konkani: 'हेर पर्याय',
    nepali: 'अन्य विकल्पहरू',
    meitei: 'Atekey option-sing',
    mizo: 'Duhthlan dangte',
    kashmiri: 'باقی آپشن',
    ladakhi: 'གདམ་ཁ་གཞན་དག',
  );

  String get signInLabel => _localized(
    telugu: 'సైన్ ఇన్',
    english: 'Sign in',
    hindi: 'साइन इन',
    tamil: 'உள்நுழைக',
    kannada: 'ಸೈನ್ ಇನ್',
    malayalam: 'സൈൻ ഇൻ',
    marathi: 'साइन इन',
    gujarati: 'સાઇન ઇન',
    bengali: 'সাইন ইন',
    punjabi: 'ਸਾਈਨ ਇਨ',
    odia: 'ସାଇନ୍ ଇନ୍',
    assamese: 'ছাইন ইন',
    konkani: 'साइन इन',
    nepali: 'साइन इन',
    meitei: 'Sign in',
    mizo: 'Sign in',
    kashmiri: 'سائن اِن',
    ladakhi: 'Sign in',
  );

  String get signUpLabel => _localized(
    telugu: 'సైన్ అప్',
    english: 'Sign up',
    hindi: 'साइन अप',
    tamil: 'பதிவு செய்க',
    kannada: 'ಸೈನ್ ಅಪ್',
    malayalam: 'സൈൻ അപ്പ്',
    marathi: 'साइन अप',
    gujarati: 'સાઇન અપ',
    bengali: 'সাইন আপ',
    punjabi: 'ਸਾਈਨ ਅੱਪ',
    odia: 'ସାଇନ୍ ଅପ୍',
    assamese: 'চাইন আপ',
    konkani: 'साइन अप',
    nepali: 'साइन अप',
    meitei: 'Sign up',
    mizo: 'Sign up',
    kashmiri: 'سائن اَپ',
    ladakhi: 'Sign up',
  );

  String get emailHint => _localized(
    telugu: 'ఈమెయిల్ చిరునామా',
    english: 'Email address',
    hindi: 'ईमेल पता',
    tamil: 'மின்னஞ்சல் முகவரி',
    kannada: 'ಇಮೇಲ್ ವಿಳಾಸ',
    malayalam: 'ഇമെയിൽ വിലാസം',
    marathi: 'ईमेल पत्ता',
    gujarati: 'ઇમેઇલ સરનામું',
    bengali: 'ইমেল ঠিকানা',
    punjabi: 'ਈਮੇਲ ਪਤਾ',
    odia: 'ଇମେଲ୍ ଠିକଣା',
    assamese: 'ইমেইল ঠিকনা',
    konkani: 'ईमेल पत्તો',
    nepali: 'इमेल ठेगाना',
    meitei: 'Email address',
    mizo: 'Email address',
    kashmiri: 'ای میل پتہ',
    ladakhi: 'Email ཁ་བྱང༌།',
  );

  String get passwordHint => _localized(
    telugu: 'పాస్‌వర్డ్',
    english: 'Password',
    hindi: 'पासवर्ड',
    tamil: 'கடவுச்சொல்',
    kannada: 'ಪಾಸ್‌ವರ್ಡ್',
    malayalam: 'പാസ്‌വേഡ്',
    marathi: 'पासवर्ड',
    gujarati: 'પાસવર્ડ',
    bengali: 'পাসওয়ার্ড',
    punjabi: 'ਪਾਸਵਰਡ',
    odia: 'ପାସୱାର୍ଡ',
    assamese: 'পাছৱৰ্ড',
    konkani: 'पासवर्ड',
    nepali: 'पासवर्ड',
    meitei: 'Password',
    mizo: 'Password',
    kashmiri: 'پاس ورڈ',
    ladakhi: 'Password',
  );

  String get forgotPasswordLabel => _localized(
    telugu: 'పాస్‌వర్డ్ మర్చిపోయారా?',
    english: 'Forgot password?',
    hindi: 'पासवर्ड भूल गए?',
    tamil: 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?',
    kannada: 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರಾ?',
    malayalam: 'പാസ്‌വേഡ് മറന്നോ?',
    marathi: 'पासवर्ड विसरलात?',
    gujarati: 'પાસવર્ડ ભૂલી ગયા?',
    bengali: 'পাসওয়ার্ড ভুলে গেছেন?',
    punjabi: 'ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?',
    odia: 'ପାସୱାର୍ଡ ଭୁଲିଗଲେ କି?',
    assamese: 'পাছৱৰ্ড পাহৰিলে?',
    konkani: 'पासवर्ड विसरले?',
    nepali: 'पासवर्ड बिर्सनुभयो?',
    meitei: 'Password ningshingdribra?',
    mizo: 'Password i theihnghilh em?',
    kashmiri: 'پاس ورڈ مَشیو؟',
    ladakhi: 'Password བརྗེད་དམ།',
  );

  String get passwordRequired => _localized(
    telugu: 'పాస్‌వర్డ్ అవసరం',
    english: 'Password is required',
    hindi: 'पासवर्ड आवश्यक है',
    tamil: 'கடவுச்சொல் தேவை',
    kannada: 'ಪಾಸ್‌ವರ್ಡ್ ಅಗತ್ಯವಿದೆ',
    malayalam: 'പാസ്‌വേഡ് ആവശ്യമാണ്',
    marathi: 'पासवर्ड आवश्यक आहे',
    gujarati: 'પાસવર્ડ જરૂરી છે',
    bengali: 'পাসওয়ার্ড প্রয়োজন',
    punjabi: 'ਪਾਸਵਰਡ ਲੋੜੀਂਦਾ ਹੈ',
    odia: 'ପାସୱାର୍ଡ ଆବଶ୍ୟକ',
    assamese: 'পাছৱৰ্ড প্ৰয়োজন',
    konkani: 'पासवर्ड जाय',
    nepali: 'पासवर्ड आवश्यक छ',
    meitei: 'Password darkar oire',
    mizo: 'Password a ngai',
    kashmiri: 'پاس ورڈ چھُ ضرورت',
    ladakhi: 'Password དགོས།',
  );

  String get skipNowLabel => _localized(
    telugu: 'ఇప్పటికైతే Skip',
    english: 'Skip now',
    hindi: 'अभी छोड़ें',
    tamil: 'இப்போது தவிர்க்கவும்',
    kannada: 'ಈಗ ಬಿಟ್ಟುಬಿಡಿ',
    malayalam: 'ഇപ്പോൾ ഒഴിവാക്കുക',
    marathi: 'आत्ता वगळा',
    gujarati: 'હમણાં છોડો',
    bengali: 'এখন এড়িয়ে যান',
    punjabi: 'ਹੁਣੇ ਛੱਡੋ',
    odia: 'ବର୍ତ୍ତମାନ ଛାଡନ୍ତୁ',
    assamese: 'এতিয়া বাদ দিয়ক',
    konkani: 'आतांच वगळात',
    nepali: 'अहिले छोड्नुहोस्',
    meitei: 'Houjik thadok-u',
    mizo: 'Kan rih rawh',
    kashmiri: 'فی الحال ترکہِ کٔریو',
    ladakhi: 'ད་ལྟ་འདོར་བ།',
  );

  String get disclaimer => _localized(
    telugu: 'Share, download లాంటి actions కి తర్వాత login అవసరం కావచ్చు.',
    english: 'Some actions like share and download may require login later.',
    hindi: 'शेयर और डाउनलोड जैसी कुछ क्रियाओं के लिए बाद में लॉगिन आवश्यक हो सकता है।',
    tamil: 'பகிர்வு மற்றும் பதிவிறக்கம் போன்ற செயல்களுக்கு பின்னர் உள்நுழைவு தேவைப்படலாம்.',
    kannada: 'ಹಂಚಿಕೆ ಮತ್ತು ಡೌನ್‌ಲೋಡ್‌ನಂತಹ ಕ್ರಿಯೆಗಳಿಗೆ ನಂತರ ಲಾಗಿನ್ ಅಗತ್ಯವಿರಬಹುದು.',
    malayalam: 'പങ്കിടൽ, ഡൗൺലോഡ് തുടങ്ങിയ പ്രവർത്തനങ്ങൾക്ക് പിന്നീട് ലോഗിൻ ആവശ്യമായി വന്നേക്കാം.',
    marathi: 'शेअर आणि डाउनलोड सारख्या क्रियांसाठी नंतर लॉगिन आवश्यक असू शकते.',
    gujarati: 'શેર અને ડાઉનલોડ જેવી ક્રિયાઓ માટે પછીથી લૉગિનની જરૂર પડી શકે છે.',
    bengali: 'শেয়ার এবং ডাউনলোডের মতো কাজের জন্য পরবর্তীতে লগইন প্রয়োজন হতে পারে।',
    punjabi: 'ਸ਼ੇਅਰ ਅਤੇ ਡਾਊਨਲੋਡ ਵਰਗੀਆਂ ਕਾਰਵਾਈਆਂ ਲਈ ਬਾਅਦ ਵਿੱਚ ਲੌਗਇਨ ਦੀ ਲੋੜ ਹੋ ਸਕਦੀ ਹੈ।',
    odia: 'ସେୟାର ଏବଂ ଡାଉନଲୋଡ୍ ଭଳି କାର୍ଯ୍ୟ ପାଇଁ ପରେ ଲଗଇନ୍ ଆବଶ୍ୟକ ହୋଇପାରେ।',
    assamese: 'শ্বেয়াৰ আৰু ডাউনলোডৰ দৰে কামৰ বাবে পিছত লগইনৰ প্ৰয়োজন হ’ব পাৰে।',
    konkani: 'शेअर आनी डाऊनलोड सारक्या क्रियां खातीर उपरांत लॉगिन गरजेचें आसूं येता.',
    nepali: 'साझेदारी र डाउनलोड जस्ता कार्यहरूको लागि पछि लगइन आवश्यक हुन सक्छ।',
    meitei: 'Share amasung download toubada tungda login touba darkar oiba yai.',
    mizo: 'Share leh download te hian nakinah login a phut thei.',
    kashmiri: 'شیئر تہٕ ڈاؤنلوڈ باپتھ ہیکہٕ پتہٕ لاگ اِن ضرورت پٔتھ۔',
    ladakhi: 'share དང་ download ལ་རྗེས་སུ་ login དགོས་སྲིད།',
  );

  String get privacyLabel => _localized(
    telugu: 'గోప్యతా విధానం',
    english: 'Privacy Policy',
    hindi: 'गोपनीयता नीति',
    tamil: 'தனியுரிமைக் கொள்கை',
    kannada: 'ಗೌಪ್ಯತಾ ನೀತಿ',
    malayalam: 'സ്വകാര്യതാ നയം',
    marathi: 'गोपनीयता धोरण',
    gujarati: 'ગોપનીયતા નીતિ',
    bengali: 'গোপনীয়তা নীতি',
    punjabi: 'ਪਰਦੇਦਾਰੀ ਨੀਤੀ',
    odia: 'ଗୋପନୀୟତା ନୀତି',
    assamese: 'গোপনীয়তা নীতি',
    konkani: 'गोपनीयता धोरण',
    nepali: 'गोपनीयता नीति',
    meitei: 'Privacy Policy',
    mizo: 'Hriattirna leh Dan',
    kashmiri: 'رازداری ہُنٛد اصول',
    ladakhi: 'གསང་རྒྱའི་སྲིད་ཇུས།',
  );

  String get termsLabel => _localized(
    telugu: 'నిబంధనలు',
    english: 'Terms & Conditions',
    hindi: 'नियम एवं शर्तें',
    tamil: 'விதிமுறைகள் & நிபந்தனைகள்',
    kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
    malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും',
    marathi: 'अटी आणि शर्ती',
    gujarati: 'નિયમો અને શરતો',
    bengali: 'নিয়ম ও শর্তাবলী',
    punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ ଓ ସର୍ତ୍ତାବଳୀ',
    assamese: 'নিয়ম আৰু চৰ্তাৱলী',
    konkani: 'अटी आनी शर्ती',
    nepali: 'नियम र सर्तहरू',
    meitei: 'Terms & Conditions',
    mizo: 'Hman dan tur leh Dan',
    kashmiri: 'شرائط و ضوابط',
    ladakhi: 'ཆ་རྐྱེན་དང་དོན་ཚན།',
  );

  String get andLabel => _localized(
    telugu: 'మరియు',
    english: 'and',
    hindi: 'और',
    tamil: 'மற்றும்',
    kannada: 'ಮತ್ತು',
    malayalam: 'കൂടാതെ',
    marathi: 'आणि',
    gujarati: 'અને',
    bengali: 'এবং',
    punjabi: 'ਅਤੇ',
    odia: 'ଏବଂ',
    assamese: 'আৰু',
    konkani: 'आनी',
    nepali: 'र',
    meitei: 'amasung',
    mizo: 'leh',
    kashmiri: 'تہٕ',
    ladakhi: 'དང།',
  );

  String resetSent(String email) => _localized(
    telugu: '$email కి password reset mail పంపించాం.',
    english: 'Password reset email sent to $email.',
    hindi: '$email पर पासवर्ड रीसेट ईमेल भेजा गया।',
    tamil: '$email முகவரிக்கு கடவுச்சொல் மீட்டமைப்பு மின்னஞ்சல் அனுப்பப்பட்டது.',
    kannada: '$email ಗೆ ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಇಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ.',
    malayalam: '$email-ലേക്ക് പാസ്‌വേഡ് പുനഃസജ്ജീകരണ ഇമെയിൽ അയച്ചു.',
    marathi: '$email वर पासवर्ड रीसेट ईमेल पाठवला आहे.',
    gujarati: '$email પર પાસવર્ડ રીસેટ ઇમેઇલ મોકલ્યો છે.',
    bengali: '$email-এ পাসওয়ার্ড রিসেট ইমেল পাঠানো হয়েছে।',
    punjabi: '$email ਤੇ ਪਾਸਵਰਡ ਰੀਸੈੱਟ ਈਮੇਲ ਭੇਜੀ ਗਈ।',
    odia: '$email କୁ ପାସୱାର୍ଡ ପୁନଃସେଟ୍ ଇମେଲ୍ ପଠାଗଲା।',
    assamese: '$email-লৈ পাছৱৰ্ড ৰিছেট ইমেইল প্ৰেৰণ কৰা হ’ল।',
    konkani: '$email चेर पासवर्ड रीसेट ईमेल धाडला.',
    nepali: '$email मा पासवर्ड रिसेट इमेल पठाइयो।',
    meitei: '$email da password reset email thakhre.',
    mizo: '$email-ah password reset email thawn a ni.',
    kashmiri: '$email پؠٹھ سوزنہٕ آو پاس ورڈ ری سیٹ ای میل۔',
    ladakhi: '$email ལ་ password reset email བཏང་ཚར།',
  );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? cs.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}
