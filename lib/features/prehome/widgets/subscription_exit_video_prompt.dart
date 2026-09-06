import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/subscription_exit_video_service.dart';

Future<void> prewarmSubscriptionVideoPrompts({
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
}) {
  return Future.wait<void>(<Future<void>>[
    _SubscriptionVideoPromptPreloadCache.prepare(
      fieldName: _SubscriptionVideoPromptPreloadCache.exitFieldName,
      service: service,
    ).then((_) {}),
    _SubscriptionVideoPromptPreloadCache.prepare(
      fieldName: _SubscriptionVideoPromptPreloadCache.thanksFieldName,
      service: service,
    ).then((_) {}),
  ]);
}

Future<void> showSubscriptionExitVideoPromptIfAvailable(
  BuildContext context, {
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
  required Future<void> Function(BuildContext context) onSubscribe,
}) async {
  final prepared = await _SubscriptionVideoPromptPreloadCache.take(
    fieldName: _SubscriptionVideoPromptPreloadCache.exitFieldName,
    service: service,
  );
  if (!context.mounted) {
    await prepared?.controller?.dispose();
    return;
  }
  final config = prepared?.config;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SubscriptionExitVideoDialog(
      parentContext: context,
      videoUrl: config?.canPlay == true ? config!.url : null,
      preloadedController: prepared?.controller,
      primaryLabel: context.strings.localized(
        telugu: 'ఇప్పుడే సబ్‌స్క్రైబ్ చేయండి',
        english: 'Subscribe Now',
        hindi: 'अभी सब्सक्राइब करें',
        tamil: 'இப்போதே குழுசேரவும்',
        kannada: 'ಈಗಲೇ ಚಂದಾದಾರರಾಗಿ',
        malayalam: 'ഇപ്പോൾ സബ്‌സ്‌ക്രൈബ് ചെയ്യുക',
        marathi: 'आता सबस्क्राइब करा',
        gujarati: 'હમણાં સબ્સ્ક્રાઇબ કરો',
        bengali: 'এখনই সাবস্ক্রাইব করুন',
        punjabi: 'ਹੁਣੇ ਗਾਹਕ ਬਣੋ',
        odia: 'ବର୍ତ୍ତମାନ ସବସ୍କ୍ରାଇବ କରନ୍ତୁ',
        assamese: 'এতিয়াই সদস্যতা লওক',
        konkani: 'आतांच सबस्क्रायब करात',
        nepali: 'अहिले सदस्यता लिनुहोस्',
        meitei: 'Houdokpamuk Subscribe toubiyu',
        mizo: 'Subscribe nghal rawh',
        kashmiri: 'وؠن کٔریو سبسکرايب',
        ladakhi: 'ད་ལྟ་ subscribe མཛོད།',
      ),
      secondaryLabel: context.strings.localized(
        telugu: 'స్కిప్',
        english: 'Skip',
        hindi: 'छोड़ें',
        tamil: 'தவிர்க்கவும்',
        kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
        malayalam: 'ഒഴിവാക്കുക',
        marathi: 'वगळा',
        gujarati: 'છોડો',
        bengali: 'এড়িয়ে যান',
        punjabi: 'ਛੱਡੋ',
        odia: 'ଛାଡ଼ିଦିଅନ୍ତୁ',
        assamese: 'এৰাই চলক',
        konkani: 'सोडून दियात',
        nepali: 'छोड्नुहोस्',
        meitei: 'Houdokpidana thambiyu',
        mizo: 'Kalsan rawh',
        kashmiri: 'ترٛٲవిو',
        ladakhi: 'ཕྱིར་འཐེན།',
      ),
      fallbackTitle: context.strings.localized(
        telugu: 'ఇప్పుడే సబ్‌స్క్రైబ్ చేయండి',
        english: 'Subscribe Now',
        hindi: 'अभी सब्सक्राइब करें',
        tamil: 'இப்போதே குழுசேரவும்',
        kannada: 'ಈಗಲೇ ಚಂದಾದಾರರಾಗಿ',
        malayalam: 'ഇപ്പോൾ സബ്‌സ്‌ക്രൈബ് ചെയ്യുക',
        marathi: 'आता सबस्क्राइब करा',
        gujarati: 'હમણાં સબ્સ્ક્રાઇબ કરો',
        bengali: 'এখনই সাবস্ক্রাইব করুন',
        punjabi: 'ਹੁਣੇ ਗਾਹਕ ਬਣੋ',
        odia: 'ବର୍ତ୍ତମାନ ସବସ୍କ୍ରାଇବ କରନ୍ତୁ',
        assamese: 'এতিয়াই সদস্যতা লওক',
        konkani: 'आतांच सबस्क्रायब करात',
        nepali: 'अहिले सदस्यता लिनुहोस्',
        meitei: 'Houdokpamuk Subscribe toubiyu',
        mizo: 'Subscribe nghal rawh',
        kashmiri: 'وؠن کٔریو سبسکرايب',
        ladakhi: 'ད་ལྟ་ subscribe མཛོད།',
      ),
      fallbackMessage: context.strings.localized(
        telugu:
            'అన్‌లిమిటెడ్ పోస్టర్లు క్రియేట్ చేసి షేర్ చేయడానికి సబ్‌స్క్రిప్షన్ తీసుకోండి.',
        english:
            'Subscribe now to create and share unlimited posters in the app.',
        hindi:
            'ऐप में असीमित पोस्टर बनाने और साझा करने के लिए अभी सब्सक्राइब करें।',
        tamil:
            'செயலியில் வரம்பற்ற போஸ்டர்களை உருவாக்கி பகிர இப்போதே குழுசேரவும்.',
        kannada:
            'ಆ್ಯಪ್‌ನಲ್ಲಿ ಅನಿಯಮಿತ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ರಚಿಸಲು ಮತ್ತು ಹಂಚಿಕೊಳ್ಳಲು ಈಗಲೇ ಚಂದಾದಾರರಾಗಿ.',
        malayalam:
            'ആപ്പിൽ അൺലിമിറ്റഡ് പോസ്റ്ററുകൾ സൃഷ്ടിക്കാനും പങ്കിടാനും ഇപ്പോൾ സബ്‌സ്‌ക്രൈബ് ചെയ്യുക.',
        marathi:
            'अ‍ॅपमध्ये अमर्यादित पोस्टर्स तयार करण्यासाठी आणि शेअर करण्यासाठी आता सबस्क्राइब करा.',
        gujarati:
            'એપમાં અમર્યાદિત પોસ્ટર્સ બનાવવા અને શેર કરવા માટે હમણાં સબ્સ્ક્રાઇબ કરો.',
        bengali:
            'অ্যাপে সীমাহীন পোস্টার তৈরি এবং শেয়ার করতে এখনই সাবস্ক্রাইব করুন।',
        punjabi:
            'ਐਪ ਵਿੱਚ ਅਸੀਮਤ ਪੋਸਟਰ ਬਣਾਉਣ ਅਤੇ ਸਾਂਝੇ ਕਰਨ ਲਈ ਹੁਣੇ ਗਾਹਕ ਬਣੋ।',
        odia:
            'ଆପରେ ଅସୀମିତ ପୋଷ୍ଟର ତିଆରି ଏବଂ ସେୟାର କରିବା ପାଇଁ ବର୍ତ୍ତମାନ ସବସ୍କ୍ରାଇବ କରନ୍ତୁ।',
        assamese:
            'এপত সীমাহীন পোষ্টাৰ সৃষ্টি আৰু শ্বেয়াৰ কৰিবলৈ এতিয়াই সদস্যতা লওক।',
        konkani:
            'अ‍ॅपामध्ये अमर्यादित पोस्टरां तयार करूंक आनी शेअर करूंक आतांच सबस्क्रायब करात.',
        nepali:
            'एपमा असीमित पोस्टरहरू सिर्जना गर्न र साझेदारी गर्न अहिले सदस्यता लिनुहोस्।',
        meitei:
            'App sida aroiba yaodana postering semduna share tounaba subscribe toubiyu.',
        mizo:
            'App chhunga poster duhtawka siam a share theih nan subscribe rawh.',
        kashmiri:
            'ایپس منز لا محدود پوسٹر بنٲوِتھ شیئر کرنہٕ خٲطرٕ وؠن کٔریو سبسکرايب۔',
        ladakhi:
            'App ནང་ཚད་མེད་པའི་པོ་སཊར་བཟོས་ཏེ་བགོ་འགྲེམས་བྱེད་པར་ subscribe མཛོད།',
      ),
      onPrimaryTap: onSubscribe,
    ),
  );
}

Future<void> showSubscriptionThanksVideoPromptIfAvailable(
  BuildContext context, {
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
}) async {
  final prepared = await _SubscriptionVideoPromptPreloadCache.take(
    fieldName: _SubscriptionVideoPromptPreloadCache.thanksFieldName,
    service: service,
  );
  if (!context.mounted) {
    await prepared?.controller?.dispose();
    return;
  }
  final config = prepared?.config;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SubscriptionExitVideoDialog(
      parentContext: context,
      videoUrl: config?.canPlay == true ? config!.url : null,
      preloadedController: prepared?.controller,
      primaryLabel: context.strings.localized(
        telugu: 'ధన్యవాదాలు',
        english: 'Thanks',
        hindi: 'धन्यवाद',
        tamil: 'நன்றி',
        kannada: 'ಧನ್ಯವಾದಗಳು',
        malayalam: 'നന്ദി',
        marathi: 'धन्यवाद',
        gujarati: 'આભાર',
        bengali: 'ধন্যবাদ',
        punjabi: 'ਧੰਨਵਾਦ',
        odia: 'ଧନ୍ୟବାଦ',
        assamese: 'ধন্যবাদ',
        konkani: 'देव बरें करूं',
        nepali: 'धन्यवाद',
        meitei: 'Thagatchari',
        mizo: 'Ka lawm e',
        kashmiri: 'شُکریہ',
        ladakhi: 'ཐུགས་རྗེ་ཆེ།',
      ),
      secondaryLabel: context.strings.localized(
        telugu: 'మూసివేయి',
        english: 'Close',
        hindi: 'बंद करें',
        tamil: 'மூடு',
        kannada: 'ಮುಚ್ಚಿ',
        malayalam: 'അടയ്ക്കുക',
        marathi: 'बंद करा',
        gujarati: 'બંધ કરો',
        bengali: 'বন্ধ করুন',
        punjabi: 'ਬੰਦ ਕਰੋ',
        odia: 'ବନ୍ଦ କରନ୍ତୁ',
        assamese: 'বন্ধ কৰক',
        konkani: 'बंद करात',
        nepali: 'बन्द गर्नुहोस्',
        meitei: 'Thinbi-u',
        mizo: 'Kharh rawh',
        kashmiri: 'بَند کٔریو',
        ladakhi: 'ཁ་རྒྱབ།',
      ),
      fallbackTitle: context.strings.localized(
        telugu: 'ధన్యవాదాలు',
        english: 'Thank You',
        hindi: 'धन्यवाद',
        tamil: 'நன்றி',
        kannada: 'ಧನ್ಯವಾದಗಳು',
        malayalam: 'നന്ദി',
        marathi: 'धन्यवाद',
        gujarati: 'આભાર',
        bengali: 'ধন্যবাদ',
        punjabi: 'ਧੰਨਵਾਦ',
        odia: 'ଧନ୍ୟବାଦ',
        assamese: 'ধন্যবাদ',
        konkani: 'देव बरें करूं',
        nepali: 'धन्यवाद',
        meitei: 'Thagatchari',
        mizo: 'Ka lawm e',
        kashmiri: 'شُکریہ',
        ladakhi: 'ཐུགས་རྗེ་ཆེ།',
      ),
      fallbackMessage: context.strings.localized(
        telugu:
            'మీ సబ్‌స్క్రిప్షన్ కన్ఫర్మ్ అయింది. ఇప్పుడు మీ పోస్టర్లను నమ్మకంగా క్రియేట్ చేయండి.',
        english:
            'Your subscription is confirmed. You can now create your posters with confidence.',
        hindi:
            'आपकी सदस्यता की पुष्टि हो गई है। अब आप विश्वास के साथ अपने पोस्टर बना सकते हैं।',
        tamil:
            'உங்கள் சந்தா உறுதிப்படுத்தப்பட்டது. இப்போது உங்கள் போஸ்டர்களை நம்பிக்கையுடன் உருவாக்கலாம்.',
        kannada:
            'ನಿಮ್ಮ ಚಂದಾದಾರಿಕೆ ದೃಢೀಕರಿಸಲ್ಪಟ್ಟಿದೆ. ಈಗ ನೀವು ವಿಶ್ವಾಸದಿಂದ ನಿಮ್ಮ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ರಚಿಸಬಹುದು.',
        malayalam:
            'നിങ്ങളുടെ സബ്‌സ്‌ക്രിപ്‌ഷൻ സ്ഥിരീകരിച്ചു. ഇപ്പോൾ നിങ്ങൾക്ക് ആത്മവിശ്വാസത്തോടെ നിങ്ങളുടെ പോസ്റ്ററുകൾ നിർമ്മിക്കാം.',
        marathi:
            'तुमचे सबस्क्रिप्शन निश्चित झाले आहे. आता तुम्ही आत्मविश्वासाने तुमचे पोस्टर्स तयार करू शकता.',
        gujarati:
            'તમારું સબ્સ્ક્રિપ્શન કન્ફર્મ થઈ ગયું છે. હવે તમે વિશ્વાસપૂર્વક તમારા પોસ્ટર્સ બનાવી શકો છો.',
        bengali:
            'আপনার সাবস্ক্রিপশন নিশ্চিত করা হয়েছে। এখন আপনি আত্মবিশ্বাসের সাথে আপনার পোস্টার তৈরি করতে পারেন।',
        punjabi:
            'ਤੁਹਾਡੀ ਗਾਹਕੀ ਦੀ ਪੁਸ਼ਟੀ ਹੋ ਗਈ ਹੈ। ਹੁਣ ਤੁਸੀਂ ਭਰੋਸੇ ਨਾਲ ਆਪਣੇ ਪੋਸਟਰ ਬਣਾ ਸਕਦੇ ਹੋ।',
        odia:
            'ଆପଣଙ୍କ ସବସ୍କ୍ରିପସନ୍ ନିଶ୍ଚିତ ହୋଇଛି। ବର୍ତ୍ତମାନ ଆପଣ ଆତ୍ମବିଶ୍ୱାସର ସହିତ ଆପଣଙ୍କ ପୋଷ୍ଟର ତିଆରି କରିପାରିବେ।',
        assamese:
            'আপোনাৰ সদস্যতা নিশ্চিত কৰা হৈছে। এতিয়া আপুনি আত্মবিশ্বাসেৰে নিজৰ পোষ্টাৰ সৃষ্টি কৰিব পাৰিব।',
        konkani:
            'तुमचें सबस्क्रिप्शन निश्चित जालें. आतां तुमी आत्मविस्वासान तुमचीं पोस्टरां तयार करूंक शकतात.',
        nepali:
            'तपाईंको सदस्यता पुष्टि भएको छ। अब तपाईं आत्मविश्वासका साथ आफ्ना पोस्टरहरू सिर्जना गर्न सक्नुहुन्छ।',
        meitei:
            'Nanggidamak subscription confirm toure. Ashimuk nanggidamak posters thouna louna semba yabani.',
        mizo:
            'I subscription chu tihchian a ni ta. Rintlak takin i poster-te i siam thei tawh ang.',
        kashmiri:
            'تہٕنٛز سَبسکِرِپشَن چھِ پکی گٔمٕژ۔ وؠن ہیکیو تۄہہِ پنہٕنۍ پوسٹر اعتماد سان بنٲوِتھ۔',
        ladakhi:
            'ཁྱེད་ཀྱི་ subscription གཏན་འཁེལ་བྱུང། ད་ལྟ་གདེང་ཚོད་ཆེན་པོས་པོ་སཊར་བཟོ་ཐུབ།',
      ),
    ),
  );
}

class _SubscriptionExitVideoDialog extends StatefulWidget {
  const _SubscriptionExitVideoDialog({
    required this.parentContext,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.fallbackTitle,
    required this.fallbackMessage,
    this.videoUrl,
    this.onPrimaryTap,
    this.preloadedController,
  });

  final BuildContext parentContext;
  final String? videoUrl;
  final String primaryLabel;
  final String secondaryLabel;
  final String fallbackTitle;
  final String fallbackMessage;
  final Future<void> Function(BuildContext context)? onPrimaryTap;
  final VideoPlayerController? preloadedController;

  @override
  State<_SubscriptionExitVideoDialog> createState() =>
      _SubscriptionExitVideoDialogState();
}

class _SubscriptionExitVideoDialogState
    extends State<_SubscriptionExitVideoDialog> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final preloadedController = widget.preloadedController;
    if (preloadedController != null) {
      _controller = preloadedController;
      unawaited(_playPreloadedController(preloadedController));
    } else {
      unawaited(_initialize());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final rawUrl = widget.videoUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _playPreloadedController(
    VideoPlayerController controller,
  ) async {
    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      await controller.seekTo(Duration.zero);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _handlePrimaryTap() async {
    if (widget.onPrimaryTap == null) {
      Navigator.of(context).pop();
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!widget.parentContext.mounted) {
      return;
    }
    await widget.onPrimaryTap!(widget.parentContext);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final hasVideo = (widget.videoUrl?.trim().isNotEmpty ?? false);
    final ready = controller != null && controller.value.isInitialized;
    final showFallbackNote = !hasVideo || _hasError;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: showFallbackNote
                      ? 9 / 12
                      : (ready ? controller.value.aspectRatio : 9 / 16),
                  child: ColoredBox(
                    color: const Color(0xFF0F172A),
                    child: showFallbackNote
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 26,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  widget.fallbackTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  widget.fallbackMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ready
                        ? VideoPlayer(controller)
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _handlePrimaryTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(widget.primaryLabel),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedSubscriptionVideo {
  const _PreparedSubscriptionVideo({required this.config, this.controller});

  final SubscriptionExitVideoConfig? config;
  final VideoPlayerController? controller;
}

class _SubscriptionVideoPromptPreloadCache {
  static const String exitFieldName = 'subscriptionExitVideo';
  static const String thanksFieldName = 'subscriptionThanksVideo';
  static final Map<String, Future<_PreparedSubscriptionVideo?>> _pending =
      <String, Future<_PreparedSubscriptionVideo?>>{};

  static Future<_PreparedSubscriptionVideo?> prepare({
    required String fieldName,
    required SubscriptionExitVideoService service,
  }) {
    return _pending[fieldName] ??= _load(
      fieldName: fieldName,
      service: service,
    );
  }

  static Future<_PreparedSubscriptionVideo?> take({
    required String fieldName,
    required SubscriptionExitVideoService service,
  }) async {
    final prepared = await prepare(fieldName: fieldName, service: service);
    _pending.remove(fieldName);
    return prepared;
  }

  static Future<_PreparedSubscriptionVideo?> _load({
    required String fieldName,
    required SubscriptionExitVideoService service,
  }) async {
    final config = await service.fetchConfig(fieldName: fieldName);
    if (config?.canPlay != true) {
      return _PreparedSubscriptionVideo(config: config);
    }

    final uri = Uri.tryParse(config!.url.trim());
    if (uri == null || !uri.hasScheme) {
      return _PreparedSubscriptionVideo(config: config);
    }
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      return _PreparedSubscriptionVideo(config: config, controller: controller);
    } catch (_) {
      await controller.dispose();
      return _PreparedSubscriptionVideo(config: config);
    }
  }
}
