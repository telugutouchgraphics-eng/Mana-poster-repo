// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HomeReferralCodeDialog extends StatefulWidget {
  const _HomeReferralCodeDialog();

  @override
  State<_HomeReferralCodeDialog> createState() =>
      _HomeReferralCodeDialogState();
}

class _HomeReferralCodeDialogState extends State<_HomeReferralCodeDialog> {
  final ReferralRewardService _service = ReferralRewardService();
  final TextEditingController _controller = TextEditingController();
  bool _applying = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_applying) {
      return;
    }
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorText = context.strings.localized(
          telugu: 'రిఫరల్ కోడ్‌ను నమోదు చేయండి',
          english: 'Enter referral code',
          hindi: 'रेफ़रल कोड दर्ज करें',
          tamil: 'பரிந்துரை குறியீட்டை உள்ளிடவும்',
          kannada: 'ರೆಫರಲ್ ಕೋಡ್ ನಮೂದಿಸಿ',
          malayalam: 'റഫറൽ കോഡ് നൽകുക',
          marathi: 'रेफरल कोड प्रविष्ट करा',
          gujarati: 'રેફરલ કોડ દાખલ કરો',
          bengali: 'রেফারেল কোড লিখুন',
          punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ ਦਾਖਲ ਕਰੋ',
          odia: 'ରେଫରାଲ୍ କୋଡ୍ ପ୍ରବେଶ କରନ୍ତୁ',
          assamese: 'ৰেফাৰেল কোড দিয়ক',
          konkani: 'रेफरल कोड घालात',
          nepali: 'रेफरल कोड प्रविष्ट गर्नुहोस्',
          meitei: 'রিফরল কোদ ইবীয়ু',
          mizo: 'Referral code chhu rawh',
          kashmiri: 'ریفَرل کوڈ دَرٕج کٔرِو',
          ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས་བཅུག',
        );
      });
      return;
    }
    setState(() {
      _applying = true;
      _errorText = null;
    });
    try {
      final result = await _service.applyCode(code);
      if (!mounted) {
        return;
      }
      final alreadyApplied = result.message.toLowerCase().contains(
        'already applied',
      );
      if (result.accepted || alreadyApplied) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _applying = false;
        _errorText = result.message.isEmpty
            ? context.strings.localized(
                telugu: 'రిఫరల్ కోడ్ వర్తించలేదు',
                english: 'Referral code could not be applied',
                hindi: 'रेफ़रल कोड लागू नहीं किया जा सका',
                tamil: 'பரிந்துரை குறியீட்டைப் பயன்படுத்த முடியவில்லை',
                kannada: 'ರೆಫರಲ್ ಕೋಡ್ ಅನ್ವಯಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ',
                malayalam: 'റഫറൽ കോഡ് പ്രയോഗിക്കാനായില്ല',
                marathi: 'रेफरल कोड लागू केला जाऊ शकला नाही',
                gujarati: 'રેફરલ કોડ લાગુ કરી શકાયો નથી',
                bengali: 'রেফারেল কোড প্রয়োগ করা যায়নি',
                punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ ਲਾਗੂ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਿਆ',
                odia: 'ରେଫରାଲ୍ କୋଡ୍ ଲାଗୁ ହୋଇପାରିଲା ନାହିଁ',
                assamese: 'ৰেফাৰেল কোড প্ৰয়োগ কৰিব পৰা নগ’ল',
                konkani: 'रेफरल कोड लागू करूंक जालो ना',
                nepali: 'रेफरल कोड लागू गर्न सकिएन',
                meitei: 'রিফরল কোদ চৎনহনবা ঙমদে',
                mizo: 'Referral code hman theih a ni lo',
                kashmiri: 'ریفَرل کوڈ ہیٚکہ نہٕ لاگوٗ گژھِتھ',
                ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས་ལག་ལེན་བསྟར་མ་ཐུབ།',
              )
            : result.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _applying = false;
        _errorText = context.strings.localized(
          telugu: 'రిఫరల్ కోడ్ దరఖాస్తు విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
          english: 'Referral code apply failed. Please try again.',
          hindi: 'रेफ़रल कोड लागू करना विफल रहा। कृपया पुन: प्रयास करें।',
          tamil:
              'பரிந்துரை குறியீட்டைப் பயன்படுத்துவது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
          kannada:
              'ರೆಫರಲ್ ಕೋಡ್ ಅನ್ವಯಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam:
              'റഫറൽ കോഡ് പ്രയോഗിക്കുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi:
              'रेफरल कोड लागू करणे अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'રેફરલ કોડ લાગુ કરવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali:
              'রেফারেল কোড প্রয়োগ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi:
              'ਰੈਫ਼ਰਲ ਕੋਡ ਲਾਗੂ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ରେଫରାଲ୍ କୋଡ୍ ପ୍ରୟୋଗ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese:
              'ৰেফাৰেল কোড প্ৰয়োগ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'रेफरल कोड लागू जावंक ना. उपकार करून परत यत्न करा.',
          nepali: 'रेफरल कोड लागू गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'রিফরল কোদ চৎনহনবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
          mizo:
              'Referral code hman a hlawhchham. Khawngaihin ti nawn leh rawh.',
          kashmiri:
              'ریفَرل کوڈ لاگوٗ گژھنس منٛز ناکام۔ مہر بانی کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
          ladakhi:
              'ངོ་སྤྲོད་ཨང་གྲངས་ལག་ལེན་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      insetPadding: EdgeInsets.fromLTRB(28, 16, 28, keyboardInset + 16),
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: <Color>[
                            Color(0xFF14B8A6),
                            Color(0xFF38BDF8),
                            Color(0xFFA78BFA),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.localized(
                        telugu: 'రిఫరల్ కోడ్',
                        english: 'Referral code',
                        hindi: 'रेफ़रल कोड',
                        tamil: 'பரிந்துரை குறியீடு',
                        kannada: 'ರೆಫರಲ್ ಕೋಡ್',
                        malayalam: 'റഫറൽ കോഡ്',
                        marathi: 'रेफरल कोड',
                        gujarati: 'રેફરલ કોડ',
                        bengali: 'রেফারেল কোড',
                        punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ',
                        odia: 'ରେଫରାଲ୍ କୋଡ୍',
                        assamese: 'ৰেফাৰেল কোড',
                        konkani: 'रेफरल कोड',
                        nepali: 'रेफरल कोड',
                        meitei: 'রিফরল কোদ',
                        mizo: 'Referral code',
                        kashmiri: 'ریفَرل کوڈ',
                        ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས།',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.localized(
                        telugu: 'మీ వద్ద రిఫరల్ కోడ్ ఉంటే నమోదు చేయండి.',
                        english: 'Enter a referral code if you have one.',
                        hindi: 'यदि आपके पास रेफ़रल कोड है तो दर्ज करें।',
                        tamil:
                            'உங்களிடம் பரிந்துரை குறியீடு இருந்தால் உள்ளிடவும்.',
                        kannada: 'ನಿಮ್ಮ ಬಳಿ ರೆಫರಲ್ ಕೋಡ್ ಇದ್ದರೆ ನಮೂದಿಸಿ.',
                        malayalam:
                            'നിങ്ങളുടെ പക്കൽ റഫറൽ കോഡ് ഉണ്ടെങ്കിൽ നൽകുക.',
                        marathi: 'तुमच्याकडे असल्यास रेफरल कोड प्रविष्ट करा.',
                        gujarati: 'જો તમારી પાસે રેફરલ કોડ હોય તો દાખલ કરો.',
                        bengali: 'আপনার কাছে রেফারেল কোড থাকলে তা লিখুন।',
                        punjabi: 'ਜੇਕਰ ਤੁਹਾਡੇ ਕੋਲ ਰੈਫ਼ਰਲ ਕੋਡ ਹੈ ਤਾਂ ਦਾਖਲ ਕਰੋ।',
                        odia:
                            'ଯଦି ଆପଣଙ୍କ ପାଖରେ ରେଫରାଲ୍ କୋଡ୍ ଅଛି ତେବେ ପ୍ରବେଶ କରନ୍ତୁ।',
                        assamese:
                            'যদি আপোনাৰ হাতত ৰেফাৰেল কোড আছে তেন্তে দিয়ক।',
                        konkani: 'तुमच्या कडेन रेफरल कोड आसल्यार घालात.',
                        nepali:
                            'यदि तपाईंसँग रेफरल कोड छ भने प्रविष्ट गर्नुहोस्।',
                        meitei: 'নহাক্কীদা রিফরল কোদ লৈরবদি ইবীয়ু।',
                        mizo: 'Referral code i neih chuan chhu rawh.',
                        kashmiri:
                            'اگر تُہؠ نِش ریفَرل کوڈ آسہِ تیٚلہِ دَرٕج کٔرِو۔',
                        ladakhi: 'ཁྱེད་ལ་ངོ་སྤྲོད་ཨང་གྲངས་ཡོད་ན་འདིར་བཅུག',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: strings.localized(
                          telugu: 'రిఫరల్ కోడ్',
                          english: 'Referral code',
                          hindi: 'रेफ़रल कोड',
                          tamil: 'பரிந்துரை குறியீடு',
                          kannada: 'ರೆಫರಲ್ ಕೋಡ್',
                          malayalam: 'റഫറൽ കോഡ്',
                          marathi: 'रेफरल कोड',
                          gujarati: 'રેફરલ કોડ',
                          bengali: 'রেফারেল কোড',
                          punjabi: 'ਰੈਫ਼ਰਲ ਕੋਡ',
                          odia: 'ରେଫରାଲ୍ କୋଡ୍',
                          assamese: 'ৰেফাৰেল কোড',
                          konkani: 'रेफरल कोड',
                          nepali: 'रेफरल कोड',
                          meitei: 'রিফরল কোদ',
                          mizo: 'Referral code',
                          kashmiri: 'ریفَرل کوڈ',
                          ladakhi: 'ངོ་སྤྲོད་ཨང་གྲངས།',
                        ),
                        errorText: _errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => unawaited(_apply()),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => _openExternalPublicUrl(
                        context,
                        AppPublicInfo.termsUrl,
                      ),
                      child: Text(
                        strings.localized(
                          telugu: 'నిబంధనలు మరియు షరతులను చూడండి',
                          english: 'View Terms & Conditions',
                          hindi: 'नियम और शर्तें देखें',
                          tamil: 'விதிமுறைகள் மற்றும் நிபந்தனைகளைக் காண்க',
                          kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
                          malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും കാണുക',
                          marathi: 'अटी आणि शर्ती पहा',
                          gujarati: 'નિયમો અને શરતો જુઓ',
                          bengali: 'শর্তাবলী দেখুন',
                          punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ ਦੇਖੋ',
                          odia: 'ନିୟମ ଓ ସର୍ତ୍ତାବଳୀ ଦେଖନ୍ତୁ',
                          assamese: 'নিয়ম আৰু চৰ্তসমূহ চাওক',
                          konkani: 'अटी आनी शर्ती पळयात',
                          nepali: 'नियम तथा सर्तहरू हेर्नुहोस्',
                          meitei: 'নিয়ম অমসুং চৎন-পথাপশিং য়েংবীয়ু',
                          mizo: 'Terms & Conditions en rawh',
                          kashmiri: 'شرائط تہٕ ضوابط وُچھِو',
                          ladakhi: 'ཆ་རྐྱེན་དང་སྒྲིག་གཞི་ལ་ལྟོས།',
                        ),
                      ),
                    ),
                    PrimaryButton(
                      label: strings.localized(
                        telugu: 'వర్తింపజేయి',
                        english: 'Apply',
                        hindi: 'लागू करें',
                        tamil: 'பயன்படுத்து',
                        kannada: 'ಅನ್ವಯಿಸಿ',
                        malayalam: 'ബാധകമാക്കുക',
                        marathi: 'लागू करा',
                        gujarati: 'લાગુ કરો',
                        bengali: 'প্রয়োগ করুন',
                        punjabi: 'ਲਾਗੂ ਕਰੋ',
                        odia: 'ପ୍ରୟୋଗ କରନ୍ତୁ',
                        assamese: 'প্ৰয়োগ কৰক',
                        konkani: 'लागू करा',
                        nepali: 'लागू गर्नुहोस्',
                        meitei: 'চৎনহনবীয়ু',
                        mizo: 'Hman rawh',
                        kashmiri: 'لاگوٗ کٔرِو',
                        ladakhi: 'ལག་ལེན་བསྟར།',
                      ),
                      loading: _applying,
                      onPressed: () => unawaited(_apply()),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _applying
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        strings.localized(
                          telugu: 'దాటవేయి',
                          english: 'Skip',
                          hindi: 'छोड़ें',
                          tamil: 'தவிர்',
                          kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
                          malayalam: 'ഒഴിവാക്കുക',
                          marathi: 'वगळा',
                          gujarati: 'છોડો',
                          bengali: 'এড়িয়ে যান',
                          punjabi: 'ਛੱਡੋ',
                          odia: 'ଛାଡ଼ନ୍ତୁ',
                          assamese: 'এৰক',
                          konkani: 'सोडून दियात',
                          nepali: 'छोड्नुहोस्',
                          meitei: 'থাংদোইথোকউ',
                          mizo: 'Kalsan rawh',
                          kashmiri: 'ترک کٔرِو',
                          ladakhi: 'མཆོང་།',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

