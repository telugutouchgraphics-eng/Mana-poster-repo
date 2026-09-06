import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/services/onboarding_audio_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

class ReligionSelectionScreen extends StatefulWidget {
  const ReligionSelectionScreen({
    super.key,
    this.returnToPreviousOnSave = false,
  });

  final bool returnToPreviousOnSave;

  @override
  State<ReligionSelectionScreen> createState() =>
      _ReligionSelectionScreenState();
}

class _ReligionSelectionScreenState extends State<ReligionSelectionScreen>
    with AppLanguageStateMixin {
  final OnboardingAudioService _onboardingAudio = OnboardingAudioService();
  AppReligionPreference _selected = AppReligionPreference.all;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialSelection());
  }

  @override
  void dispose() {
    unawaited(_onboardingAudio.dispose());
    super.dispose();
  }

  Future<void> _loadInitialSelection() async {
    final selection = await AppReligionService.loadSelection();
    if (!mounted || selection == null) {
      return;
    }
    setState(() => _selected = selection);
  }

  Future<void> _continue() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await AppReligionService.persistSelection(_selected);
      if (!mounted) {
        return;
      }
      if (!saved) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'ఎంపిక సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
                english: 'Could not save your selection. Please try again.',
                hindi: 'चयन सेव नहीं हो सका। कृपया फिर से कोशिश करें।',
                tamil: 'தேர்வை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
                kannada: 'ಆಯ್ಕೆಯನ್ನು ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                malayalam:
                    'തിരഞ്ഞെടുപ്പ് സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
                marathi: 'निवड जतन करता आली नाही. कृपया पुन्हा प्रयत्न करा.',
                gujarati: 'પસંદગી સાચવી શકાઈ નથી. ફરી પ્રયાસ કરો.',
                bengali: 'পছন্দ সংরক্ষণ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
                punjabi: 'ਚੋਣ ਸੁਰੱਖਿਅਤ ਨਹੀਂ ਹੋ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                odia: 'ଚୟନ ସଂରକ୍ଷଣ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
                assamese: 'বাছনি সংৰক্ষণ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
                konkani: 'वेंचणूक सांबाळपाक जमली ना. उपकार करून परत यत्न करात.',
                nepali: 'छनोट सुरक्षित गर्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
                meitei: 'Khalbasi save touba ngamkhide. Amuk hanna hotnabiyu.',
                mizo: 'I thlan hi save theih a ni lo. Khawngaihin ti nawn leh rawh.',
                kashmiri: 'انتخاب ہیکہِ نہٕ محفوٗظ گژھِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
                ladakhi: 'འདེམས་ཁ་ཉར་ཚགས་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
              ),
            ),
          ),
        );
        return;
      }

      unawaited(NotificationService.instance.syncCurrentPreferences());

      if (widget.returnToPreviousOnSave) {
        Navigator.of(context).pop(true);
        return;
      }

      await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
      final nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute(
        includeReligionGate: false,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(nextRoute);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ఎంపిక సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
              english: 'Could not save your selection. Please try again.',
              hindi: 'चयन सेव नहीं हो सका। कृपया फिर से कोशिश करें।',
              tamil: 'தேர்வை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada: 'ಆಯ್ಕೆಯನ್ನು ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'തിരഞ്ഞെടുപ്പ് സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
              marathi: 'निवड जतन करता आली नाही. कृपया पुन्हा प्रयत्न करा.',
              gujarati: 'પસંદગી સાચવી શકાઈ નથી. ફરી પ્રયાસ કરો.',
              bengali: 'পছন্দ সংরক্ষণ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
              punjabi: 'ਚੋਣ ਸੁਰੱਖਿਅਤ ਨਹੀਂ ਹੋ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
              odia: 'ଚୟନ ସଂରକ୍ଷଣ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
              assamese: 'বাছনি সংৰক্ষণ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
              konkani: 'वेंचणूक सांबाळपाक जमली ना. उपकार करून परत यत्न करात.',
              nepali: 'छनोट सुरक्षित गर्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
              meitei: 'Khalbasi save touba ngamkhide. Amuk hanna hotnabiyu.',
              mizo: 'I thlan hi save theih a ni lo. Khawngaihin ti nawn leh rawh.',
              kashmiri: 'انتخاب ہیکہِ نہٕ محفوٗظ گژھِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
              ladakhi: 'འདེམས་ཁ་ཉར་ཚགས་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = context.strings;
    final showGuideAudio = context.currentLanguage == AppLanguage.telugu;
    final options = <_ReligionOptionData>[
      _ReligionOptionData(
        preference: AppReligionPreference.hindu,
        title: strings.localized(
          telugu: 'హిందూ',
          english: 'Hindu',
          hindi: 'हिंदू',
          tamil: 'இந்து',
          kannada: 'ಹಿಂದು',
          malayalam: 'ഹിന്ദു',
          marathi: 'हिंदू',
          gujarati: 'હિન્દુ',
          bengali: 'হিন্দু',
          punjabi: 'ਹਿੰਦੂ',
          odia: 'ହିନ୍ଦୁ',
          assamese: 'হিন্দু',
          konkani: 'हिंदू',
          nepali: 'हिन्दू',
          meitei: 'Hindu',
          mizo: 'Hindu',
          kashmiri: 'ہِندوٗ',
          ladakhi: 'ཧིན་དྷུ།',
        ),
        color: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF7ED),
      ),
      _ReligionOptionData(
        preference: AppReligionPreference.muslim,
        title: strings.localized(
          telugu: 'ముస్లిం',
          english: 'Muslim',
          hindi: 'मुस्लिम',
          tamil: 'முஸ்லிம்',
          kannada: 'ಮುಸ್ಲಿಂ',
          malayalam: 'മുസ്ലിം',
          marathi: 'मुस्लिम',
          gujarati: 'મુસ્લિમ',
          bengali: 'মুসলিম',
          punjabi: 'ਮੁਸਲਿਮ',
          odia: 'ମୁସଲିମ',
          assamese: 'মুছলিম',
          konkani: 'मुस्लिम',
          nepali: 'मुस्लिम',
          meitei: 'Muslim',
          mizo: 'Muslim',
          kashmiri: 'مُسلمان',
          ladakhi: 'ཁ་ཆེ།',
        ),
        color: const Color(0xFF10B981),
        background: const Color(0xFFECFDF5),
      ),
      _ReligionOptionData(
        preference: AppReligionPreference.christian,
        title: strings.localized(
          telugu: 'క్రిస్టియన్',
          english: 'Christian',
          hindi: 'क्रिश्चियन',
          tamil: 'கிறிஸ்துவர்',
          kannada: 'ಕ್ರಿಶ್ಚಿಯನ್',
          malayalam: 'ക്രിസ്ത്യൻ',
          marathi: 'ख्रिश्चन',
          gujarati: 'ખ્રિસ્તી',
          bengali: 'খ্রিস্টান',
          punjabi: 'ਈਸਾਈ',
          odia: 'ଖ୍ରୀଷ୍ଟିଆନ',
          assamese: 'খ্ৰীষ্টান',
          konkani: 'किरिस्तांव',
          nepali: 'ईसाई',
          meitei: 'Christian',
          mizo: 'Christian',
          kashmiri: 'عیسٲیی',
          ladakhi: 'ཡེ་ཤུའི་ཆོས་པ།',
        ),
        color: const Color(0xFF3B82F6),
        background: const Color(0xFFEFF6FF),
      ),
      _ReligionOptionData(
        preference: AppReligionPreference.all,
        title: strings.localized(
          telugu: 'అన్ని',
          english: 'All',
          hindi: 'सभी',
          tamil: 'அனைத்தும்',
          kannada: 'ಎಲ್ಲಾ',
          malayalam: 'എല്ലാം',
          marathi: 'सर्व',
          gujarati: 'બધા',
          bengali: 'সব',
          punjabi: 'ਸਾਰੇ',
          odia: 'ସମସ୍ତ',
          assamese: 'সকলো',
          konkani: 'सगळें',
          nepali: 'सबै',
          meitei: 'Pumnamak',
          mizo: 'A vaiin',
          kashmiri: 'سٲری',
          ladakhi: 'ཚང་མ།',
        ),
        color: const Color(0xFF8B5CF6),
        background: const Color(0xFFF5F3FF),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 96,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x120F172A),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFFF59E0B),
                                        Color(0xFF10B981),
                                        Color(0xFF3B82F6),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  strings.localized(
                                    telugu: 'మీ మతాన్ని ఎంచుకోండి',
                                    english: 'Select your religion',
                                    hindi: 'अपना धर्म चुनें',
                                    tamil: 'உங்கள் மதத்தை தேர்வு செய்யவும்',
                                    kannada: 'ನಿಮ್ಮ ಧರ್ಮವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
                                    malayalam: 'നിങ്ങളുടെ മതം തിരഞ്ഞെടുക്കുക',
                                    marathi: 'तुमचा धर्म निवडा',
                                    gujarati: 'તમારો ધર્મ પસંદ કરો',
                                    bengali: 'আপনার ধর্ম নির্বাচন করুন',
                                    punjabi: 'ਆਪਣਾ ਧਰਮ ਚੁਣੋ',
                                    odia: 'ଆପଣଙ୍କ ଧର୍ମ ବାଛନ୍ତୁ',
                                    assamese: 'আপোনাৰ ধৰ্ম বাছক',
                                    konkani: 'तुमचो धर्म वेंचून काडात',
                                    nepali: 'आफ्नो धर्म छान्नुहोस्',
                                    meitei: 'Nang-gi laining khallu',
                                    mizo: 'I sakhua thlang rawh',
                                    kashmiri: 'پَنُن مذہب ژٲریو',
                                    ladakhi: 'རང་གི་ཆོས་ལུགས་འདེམས།',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.localized(
                                    telugu:
                                        'మీరు ఎంచుకున్న దానికి సరిపోయే కేటగిరీలు మాత్రమే హోమ్‌లో కనిపిస్తాయి.',
                                    english:
                                        'Home will show the categories that match your selection.',
                                    hindi:
                                        'होम में आपकी पसंद के अनुसार कैटेगरी दिखाई जाएंगी।',
                                    tamil:
                                        'நீங்கள் தேர்வு செய்ததற்கேற்ற வகைகள் மட்டும் முகப்பில் தோன்றும்.',
                                    kannada:
                                        'ನೀವು ಆಯ್ಕೆ ಮಾಡಿದಕ್ಕೆ ಹೊಂದುವ ವರ್ಗಗಳು ಮಾತ್ರ ಹೋಮ್‌ನಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.',
                                    malayalam:
                                        'നിങ്ങളുടെ തിരഞ്ഞെടുപ്പിന് അനുയോജ്യമായ വിഭാഗങ്ങൾ മാത്രം ഹോമിൽ കാണിക്കും.',
                                    marathi:
                                        'तुम्ही निवडलेल्यानुसार श्रेणी मुख्यपृष्ठावर दिसतील.',
                                    gujarati:
                                        'તમે પસંદ કરેલ મુજબની કેટેગરીઝ હોમ પર દેખાશે.',
                                    bengali:
                                        'আপনি যা নির্বাচন করেছেন তার সাথে মিলিত বিভাগগুলি হোমে প্রদর্শিত হবে।',
                                    punjabi:
                                        'ਤੁਹਾਡੀ ਚੋਣ ਨਾਲ ਮੇਲ ਖਾਂਦੀਆਂ ਸ਼੍ਰੇਣੀਆਂ ਹੀ ਹੋਮ ਤੇ ਦਿਖਾਈ ਦੇਣਗੀਆਂ।',
                                    odia:
                                        'ଆପଣ ବାଛିଥିବା ଅନୁଯାୟୀ ବର୍ଗଗୁଡ଼ିକ ହୋମରେ ଦେଖାଯିବ।',
                                    assamese:
                                        'আপুনি বাছনি কৰা অনুসৰি শ্ৰেণীসমূহ হোম পৃষ্ঠাত দেখা যাব।',
                                    konkani:
                                        'तुमी वेंचिल्ल्या प्रमाणे वर्ग मुख्य पानाचेर दिसतले.',
                                    nepali:
                                        'गृहपृष्ठमा तपाईंको छनोटसँग मिल्ने वर्गहरू मात्र देखा पर्नेछन्।',
                                    meitei:
                                        'Home da nangna khallibaga channaba categories thambiragani.',
                                    mizo:
                                        'Home-ah hian i thlan mil chauh category a lang ang.',
                                    kashmiri:
                                        'ہومس پیٹھہٕ یِن صِرَف تِمے زٲژ ہاونہٕ یِم تہٕنٛزِ ژارنہٕ سٟتۍ رَلان آسَن।',
                                    ladakhi:
                                        'Home ནང་ཁྱེད་ཀྱིས་བདམས་པའི་དབྱེ་ཁག་རྣམས་སྟོན་རྒྱུ།',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                if (showGuideAudio) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        unawaited(
                                          _onboardingAudio.toggleIfSupported(
                                            language: context.currentLanguage,
                                            cue: OnboardingAudioCue
                                                .religionSelection,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.volume_up_rounded),
                                      label: Text(
                                        strings.localized(
                                          telugu: 'వాయిస్ గైడ్ మళ్లీ వినండి',
                                          english: 'Replay voice guide',
                                          hindi: 'वॉइस गाइड फिर से सुनें',
                                          tamil: 'குரல் வழிகாட்டியை மீண்டும் கேளுங்கள்',
                                          kannada: 'ಧ್ವನಿ ಮಾರ್ಗದರ್ಶನವನ್ನು ಮತ್ತೆ ಕೇಳಿ',
                                          malayalam: 'വോയ്‌സ് ഗൈഡ് വീണ്ടും കേൾക്കുക',
                                          marathi: 'व्हॉइस मार्गदर्शक पुन्हा ऐका',
                                          gujarati: 'વૉઇસ માર્ગદર્શિકા ફરી સાંભળો',
                                          bengali: 'ভয়েস গাইড আবার শুনুন',
                                          punjabi: 'ਵੌਇਸ ਗਾਈਡ ਦੁਬਾਰਾ ਸੁਣੋ',
                                          odia: 'ଭଏସ୍ ଗାଇଡ୍ ପୁଣି ଶୁଣନ୍ତୁ',
                                          assamese: 'ভইচ গাইড পুনৰ শুনক',
                                          konkani: 'व्हॉईस गाईड परत आयकात',
                                          nepali: 'आवाज गाइड फेरि सुन्नुहोस्',
                                          meitei: 'Voice guide amuk hanna tabiyu',
                                          mizo: 'Aw hriattirna ngaithla nawn leh rawh',
                                          kashmiri: 'آواز گائیڈ دۆبارٕ بوٗزِو',
                                          ladakhi: 'སྐད་ཀྱི་ལམ་སྟོན་ཡང་བསྐྱར་ཉོན།',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                ...options.map((item) {
                                  final selected = item.preference == _selected;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => setState(
                                        () => _selected = item.preference,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      child: Ink(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? item.background
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? item.color
                                                : const Color(0xFFE2E8F0),
                                            width: selected ? 1.4 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: item.background,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                item.title.substring(0, 1),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: item.color,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              selected
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                        .radio_button_unchecked_rounded,
                                              color: selected
                                                  ? item.color
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                PrimaryButton(
                                  label: strings.continueLabel,
                                  loading: _saving,
                                  onPressed: _saving ? null : _continue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Positioned(
            left: 16,
            top: 0,
            child: SafeArea(
              child: AppScreenBackButton(fallbackRoute: AppRoutes.login),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReligionOptionData {
  const _ReligionOptionData({
    required this.preference,
    required this.title,
    required this.color,
    required this.background,
  });

  final AppReligionPreference preference;
  final String title;
  final Color color;
  final Color background;
}
