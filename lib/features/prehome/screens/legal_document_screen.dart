import 'package:flutter/material.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';

enum LegalDocumentType { privacyPolicy, termsAndConditions }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.documentType});

  final LegalDocumentType documentType;

  @override
  Widget build(BuildContext context) {
    final copy = _LegalCopy(context.strings, documentType);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F6FB),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: GradientShell(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: copy.heroGradient,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      copy.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.summary,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.lastUpdated,
                    style: const TextStyle(
                      color: Color(0xFFBFDBFE),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...copy.sections.map((section) => _SectionCard(section: section)),
            const SizedBox(height: 8),
            Text(
              copy.footer,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

class _LegalCopy {
  const _LegalCopy(this.strings, this.documentType);

  final AppStrings strings;
  final LegalDocumentType documentType;

  bool get _isPrivacy => documentType == LegalDocumentType.privacyPolicy;

  List<Color> get heroGradient => _isPrivacy
      ? const <Color>[Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)]
      : const <Color>[Color(0xFF9A3412), Color(0xFFC2410C), Color(0xFFEA580C)];

  String get title => _isPrivacy
      ? strings.localized(
          telugu: 'ప్రైవసీ పాలసీ',
          english: 'Privacy Policy',
          hindi: 'प्राइवेसी पॉलिसी',
          tamil: 'தனியுரிமை கொள்கை',
          kannada: 'ಗೌಪ್ಯತಾ ನೀತಿ',
          malayalam: 'സ്വകാര്യതാ നയം',
        )
      : strings.localized(
          telugu: 'నిబంధనలు షరతులు',
          english: 'Terms & Conditions',
          hindi: 'नियम और शर्तें',
          tamil: 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
          kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
          malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും',
        );

  String get badge => _isPrivacy
      ? strings.localized(
          telugu: 'డేటా రక్షణ',
          english: 'Data Protection',
          hindi: 'डेटा सुरक्षा',
          tamil: 'தரவு பாதுகாப்பு',
          kannada: 'ಡೇಟಾ ರಕ್ಷಣೆ',
          malayalam: 'ഡാറ്റ സംരക്ഷണം',
        )
      : strings.localized(
          telugu: 'వినియోగ నియమాలు',
          english: 'Usage Terms',
          hindi: 'उपयोग नियम',
          tamil: 'பயன்பாட்டு விதிகள்',
          kannada: 'ಬಳಕೆ ನಿಯಮಗಳು',
          malayalam: 'ഉപയോഗ നിബന്ധനകൾ',
        );

  String get summary => _isPrivacy
      ? strings.localized(
          telugu:
              'మీ ఖాతా, ఫోటోలు, పోస్టర్ డేటా మరియు కొనుగోలు సమాచారం ఎలా వాడబడుతుందో ఈ పేజీ వివరిస్తుంది.',
          english:
              'This page explains how your account, photos, poster data, and purchase details are handled.',
          hindi:
              'यह पेज बताता है कि आपका अकाउंट, फोटो, पोस्टर डेटा और खरीद जानकारी कैसे उपयोग की जाती है।',
          tamil:
              'உங்கள் கணக்கு, புகைப்படங்கள், போஸ்டர் தரவு மற்றும் வாங்குதல் தகவல் எப்படி கையாளப்படுகிறது என்பதை இது விளக்குகிறது.',
          kannada:
              'ನಿಮ್ಮ ಖಾತೆ, ಫೋಟೋ, ಪೋಸ್ಟರ್ ಡೇಟಾ ಮತ್ತು ಖರೀದಿ ಮಾಹಿತಿಯನ್ನು ಹೇಗೆ ನಿರ್ವಹಿಸಲಾಗುತ್ತದೆ ಎಂಬುದನ್ನು ಇದು ವಿವರಿಸುತ್ತದೆ.',
          malayalam:
              'നിങ്ങളുടെ അക്കൗണ്ട്, ഫോട്ടോകൾ, പോസ്റ്റർ ഡാറ്റ, വാങ്ങൽ വിവരങ്ങൾ എങ്ങനെ കൈകാര്യം ചെയ്യുന്നു എന്ന് ഇത് വിശദീകരിക്കുന്നു.',
        )
      : strings.localized(
          telugu:
              'Mana Poster యాప్ వాడకం, ఖాతా, పోస్టర్ కంటెంట్ మరియు చెల్లింపులకు సంబంధించిన నియమాలు ఇక్కడ ఉన్నాయి.',
          english:
              'This page contains the rules for using Mana Poster, including accounts, poster content, and payments.',
          hindi:
              'इस पेज में Mana Poster के उपयोग, अकाउंट, पोस्टर सामग्री और भुगतान से जुड़े नियम दिए गए हैं।',
          tamil:
              'Mana Poster பயன்பாடு, கணக்கு, போஸ்டர் உள்ளடக்கம் மற்றும் கட்டணம் தொடர்பான விதிகள் இங்கே உள்ளன.',
          kannada:
              'Mana Poster ಬಳಕೆ, ಖಾತೆ, ಪೋಸ್ಟರ್ ವಿಷಯ ಮತ್ತು ಪಾವತಿ ಸಂಬಂಧಿತ ನಿಯಮಗಳು ಇಲ್ಲಿ ఉన్నాయి.',
          malayalam:
              'Mana Poster ഉപയോഗം, അക്കൗണ്ട്, പോസ്റ്റർ ഉള്ളടக்கம், പേയ്മെന്റ് എന്നിവയുമായി ബന്ധപ്പെട്ട നിബന്ധനകൾ ഇവിടെ നൽകിയിരിക്കുന്നു.',
        );

  String get lastUpdated => strings.localized(
    telugu: 'చివరి నవీకరణ: 13 ఏప్రిల్ 2026',
    english: 'Last updated: April 13, 2026',
    hindi: 'अंतिम अपडेट: 13 अप्रैल 2026',
    tamil: 'கடைசி புதுப்பிப்பு: 13 ஏப்ரல் 2026',
    kannada: 'ಕೊನೆಯ ನವೀಕರಣ: 13 ಏಪ್ರಿಲ್ 2026',
    malayalam: 'അവസാന പുതുക്കൽ: 13 ഏപ്രിൽ 2026',
  );

  List<_LegalSection> get sections =>
      _isPrivacy ? _privacySections : _termsSections;

  String get footer => strings.localized(
    telugu: 'ప్రశ్నలు ఉంటే ${AppPublicInfo.supportEmail} కి సంప్రదించండి.',
    english: 'For questions, contact ${AppPublicInfo.supportEmail}.',
    hindi: 'प्रश्न होने पर ${AppPublicInfo.supportEmail} पर संपर्क करें।',
    tamil:
        'கேள்விகள் இருந்தால் ${AppPublicInfo.supportEmail}-ஐ தொடர்பு கொள்ளுங்கள்.',
    kannada: 'ಪ್ರಶ್ನೆಗಳಿದ್ದರೆ ${AppPublicInfo.supportEmail} ಗೆ ಸಂಪರ್ಕಿಸಿ.',
    malayalam:
        'ചോദ്യങ്ങൾ ഉണ്ടെങ്കിൽ ${AppPublicInfo.supportEmail}-ൽ ബന്ധപ്പെടുക.',
  );

  List<_LegalSection> get _privacySections => <_LegalSection>[
    _LegalSection(
      strings.localized(
        telugu: 'ఏ సమాచారం సేకరిస్తాం',
        english: 'What We Collect',
        hindi: 'हम क्या जानकारी लेते हैं',
        tamil: 'எந்த தகவலை சேகரிக்கிறோம்',
        kannada: 'ಯಾವ ಮಾಹಿತಿ ಸಂಗ್ರಹಿಸುತ್ತೇವೆ',
        malayalam: 'ഏത് വിവരങ്ങൾ ശേഖരിക്കുന്നു',
      ),
      strings.localized(
        telugu:
            'ఇమెయిల్, పేరు, Google Sign-In వివరాలు, మీరు ఇచ్చే ఫోటోలు, పోస్టర్ ప్రొఫైల్ వివరాలు, వ్యాపార పేరు, WhatsApp నంబర్, అలాగే subscription లేదా purchase స్థితి వంటి సమాచారం.',
        english:
            'This may include your email, name, Google Sign-In details, uploaded photos, poster profile details, business name, WhatsApp number, and subscription or purchase status.',
        hindi:
            'इसमें आपका ईमेल, नाम, Google Sign-In विवरण, अपलोड की गई फोटो, पोस्टर प्रोफाइल, बिज़नेस नाम, WhatsApp नंबर और सब्सक्रिप्शन या खरीद स्थिति शामिल हो सकती है।',
        tamil:
            'இதில் உங்கள் மின்னஞ்சல், பெயர், Google Sign-In தகவல், பதிவேற்றிய புகைப்படங்கள், போஸ்டர் சுயவிவரத் தகவல், வணிக பெயர், WhatsApp எண் மற்றும் subscription அல்லது purchase நிலை அடங்கலாம்.',
        kannada:
            'ಇದಲ್ಲಿನಲ್ಲಿ ನಿಮ್ಮ ಇಮೇಲ್, ಹೆಸರು, Google Sign-In ವಿವರಗಳು, ಅಪ್‌ಲೋಡ್ ಮಾಡಿದ ಫೋಟೋಗಳು, ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್ ವಿವರಗಳು, ವ್ಯವಹಾರ ಹೆಸರು, WhatsApp ಸಂಖ್ಯೆ ಮತ್ತು subscription ಅಥವಾ purchase ಸ್ಥಿತಿ ಸೇರಬಹುದು.',
        malayalam:
            'ഇതിൽ നിങ്ങളുടെ ഇമെയിൽ, പേര്, Google Sign-In വിവരങ്ങൾ, അപ്‌ലോഡ് ചെയ്ത ഫോട്ടോകൾ, പോസ്റ്റർ പ്രൊഫൈൽ വിവരങ്ങൾ, ബിസിനസ് പേര്, WhatsApp നമ്പർ, subscription അല്ലെങ്കിൽ purchase നില ഉൾപ്പെടാം.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఎలా ఉపయోగిస్తాం',
        english: 'How We Use It',
        hindi: 'हम इसका उपयोग कैसे करते हैं',
        tamil: 'எப்படி பயன்படுத்துகிறோம்',
        kannada: 'ಇದನ್ನು ಹೇಗೆ ಬಳಸುತ್ತೇವೆ',
        malayalam: 'എങ്ങനെ ഉപയോഗിക്കുന്നു',
      ),
      strings.localized(
        telugu:
            'లాగిన్, ఖాతా భద్రత, పాస్‌వర్డ్ రీసెట్, పోస్టర్ personalization, save/export, subscription అర్హత చూపించడం కోసం ఈ సమాచారం ఉపయోగించబడుతుంది.',
        english:
            'We use this information for login, account security, password reset, poster personalization, save/export flows, and subscription eligibility.',
        hindi:
            'यह जानकारी लॉगिन, अकाउंट सुरक्षा, पासवर्ड रीसेट, पोस्टर personalization, save/export और subscription पात्रता दिखाने के लिए उपयोग की जाती है।',
        tamil:
            'இந்த தகவல் login, account security, password reset, poster personalization, save/export மற்றும் subscription தகுதிக்காக பயன்படுகிறது.',
        kannada:
            'ಈ ಮಾಹಿತಿ login, account security, password reset, poster personalization, save/export ಮತ್ತು subscription ಅರ್ಹತೆ ತೋರಿಸಲು ಬಳಸಲಾಗುತ್ತದೆ.',
        malayalam:
            'ഈ വിവരങ്ങൾ login, account security, password reset, poster personalization, save/export, subscription യോഗ്യത എന്നിവയ്ക്കായി ഉപയോഗിക്കുന്നു.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఫోటోలు మరియు అనుమతులు',
        english: 'Photos and Permissions',
        hindi: 'फोटो और अनुमतियां',
        tamil: 'புகைப்படங்கள் மற்றும் அனுமதிகள்',
        kannada: 'ಫೋಟೋ ಮತ್ತು ಅನುಮತಿಗಳು',
        malayalam: 'ഫോട്ടോകളും അനുമതികളും',
      ),
      strings.localized(
        telugu:
            'ఫోటో ఎంపిక, పోస్టర్ సేవ్ మరియు ఐచ్ఛిక notifications కోసం మాత్రమే అనుమతులు అడుగుతాం. మీరు settings లో వీటిని మార్చవచ్చు. మీరు export చేసే కంటెంట్‌కు మీరు బాధ్యులు.',
        english:
            'Permissions are requested only for photo selection, poster saving, and optional notifications. You can change them later in settings. You remain responsible for content you export or share.',
        hindi:
            'अनुमतियां केवल फोटो चुनने, पोस्टर सेव करने और वैकल्पिक notifications के लिए मांगी जाती हैं। आप इन्हें settings में बदल सकते हैं। जो content आप export या share करते हैं उसकी जिम्मेदारी आपकी है।',
        tamil:
            'அனுமதிகள் photo selection, poster save மற்றும் optional notifications க்காக மட்டுமே கேட்கப்படும். அவற்றை பின்னர் settings-ல் மாற்றலாம். நீங்கள் export அல்லது share செய்யும் content-க்கு நீங்கள் பொறுப்பு.',
        kannada:
            'ಅನುಮತಿಗಳನ್ನು photo selection, poster save ಮತ್ತು optional notifications ಗಾಗಿ ಮಾತ್ರ ಕೇಳಲಾಗುತ್ತದೆ. ನಂತರ settings ನಲ್ಲಿ ಬದಲಾಯಿಸಬಹುದು. ನೀವು export ಅಥವಾ share ಮಾಡುವ content ಗೆ ನೀವು ಹೊಣೆಗಾರರು.',
        malayalam:
            'അനുമതി photo selection, poster save, optional notifications എന്നിവയ്ക്കായി മാത്രം ചോദിക്കും. പിന്നീട് settings ൽ മാറ്റാം. നിങ്ങൾ export അല്ലെങ്കിൽ share ചെയ്യുന്ന content ന് നിങ്ങൾ ഉത്തരവാദിയാണ്.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'మూడో పక్ష సేవలు మరియు మీ ఎంపికలు',
        english: 'Third-Party Services and Your Choices',
        hindi: 'थर्ड-पार्टी सेवाएं और आपके विकल्प',
        tamil: 'மூன்றாம் தரப்பு சேவைகள் மற்றும் உங்கள் தேர்வுகள்',
        kannada: 'ತೃತೀಯ ಪಕ್ಷ ಸೇವೆಗಳು ಮತ್ತು ನಿಮ್ಮ ಆಯ್ಕೆಗಳು',
        malayalam: 'മൂന്നാം കക്ഷി സേവനങ്ങളും നിങ്ങളുടെ തിരഞ്ഞെടുപ്പുകളും',
      ),
      strings.localized(
        telugu:
            'యాప్ Firebase, Google Sign-In, స్టోరేజ్ మరియు నోటిఫికేషన్ సేవలను వాడవచ్చు. అవసరం లేని అనుమతులను ఆఫ్ చేయవచ్చు. ఖాతా లేదా డేటా సహాయం కోసం సపోర్ట్ ఇమెయిల్‌ను సంప్రదించండి.',
        english:
            'The app may use Firebase, Google Sign-In, storage, and notification services. Optional permissions can be turned off. Contact support if you need help with account or data-related issues.',
        hindi:
            'ऐप Firebase, Google Sign-In, storage और notification सेवाओं का उपयोग कर सकती है। optional permissions को बंद किया जा सकता है। अकाउंट या डेटा सहायता के लिए support से संपर्क करें।',
        tamil:
            'இந்த app Firebase, Google Sign-In, storage மற்றும் notification services-ஐ பயன்படுத்தலாம். optional permissions-ஐ off செய்யலாம். account அல்லது data உதவிக்கு support-ஐ தொடர்பு கொள்ளுங்கள்.',
        kannada:
            'ಈ app Firebase, Google Sign-In, storage ಮತ್ತು notification services ಬಳಸಬಹುದು. optional permissions ಅನ್ನು off ಮಾಡಬಹುದು. account ಅಥವಾ data ಸಹಾಯಕ್ಕಾಗಿ support ಸಂಪರ್ಕಿಸಿ.',
        malayalam:
            'ഈ app Firebase, Google Sign-In, storage, notification services ഉപയോഗിക്കാം. optional permissions ഓഫ് ചെയ്യാം. account അല്ലെങ്കിൽ data സഹായത്തിന് support-നെ ബന്ധപ്പെടുക.',
      ),
    ),
  ];

  List<_LegalSection> get _termsSections => <_LegalSection>[
    _LegalSection(
      strings.localized(
        telugu: 'యాప్ వాడకం',
        english: 'Using the App',
        hindi: 'ऐप का उपयोग',
        tamil: 'பயன்பாட்டைப் பயன்படுத்துதல்',
        kannada: 'ಆಪ್ ಬಳಕೆ',
        malayalam: 'ആപ്പ് ഉപയോഗം',
      ),
      strings.localized(
        telugu:
            'Mana Poster వ్యక్తిగత, వ్యాపార, ప్రచార పోస్టర్ల కోసం వాడే యాప్. చట్టబద్ధంగా, బాధ్యతతో మాత్రమే వాడాలి.',
        english:
            'Mana Poster is intended for personal, business, and promotional poster creation. You must use it lawfully and responsibly.',
        hindi:
            'Mana Poster व्यक्तिगत, व्यवसायिक और प्रचार पोस्टर बनाने के लिए है। इसका उपयोग कानूनी और जिम्मेदार तरीके से होना चाहिए।',
        tamil:
            'Mana Poster தனிப்பட்ட, வணிக மற்றும் விளம்பர போஸ்டர்கள் உருவாக்க பயன்படுகிறது. சட்டபூர்வமாகவும் பொறுப்புடனும் பயன்படுத்த வேண்டும்.',
        kannada:
            'Mana Poster ವೈಯಕ್ತಿಕ, ವ್ಯವಹಾರ ಮತ್ತು ಪ್ರಚಾರ ಪೋಸ್ಟರ್ ರಚನೆಗೆ ಉದ್ದೇಶಿಸಲಾಗಿದೆ. ಕಾನೂನುಬದ್ಧವಾಗಿ ಮತ್ತು ಜವಾಬ್ದಾರಿಯಿಂದ ಬಳಸಬೇಕು.',
        malayalam:
            'Mana Poster വ്യക്തിഗത, ബിസിനസ്, പ്രചാരണ പോസ്റ്റർ നിർമ്മാണത്തിന് ഉദ്ദേശിച്ചതാണ്. നിയമാനുസൃതമായും ഉത്തരവാദിത്തത്തോടെയും ഉപയോഗിക്കണം.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఖాతా మరియు కంటెంట్ బాధ్యత',
        english: 'Account and Content Responsibility',
        hindi: 'अकाउंट और सामग्री जिम्मेदारी',
        tamil: 'கணக்கு மற்றும் உள்ளடக்க பொறுப்பு',
        kannada: 'ಖಾತೆ ಮತ್ತು ವಿಷಯ ಹೊಣೆಗಾರಿಕೆ',
        malayalam: 'അക്കൗണ്ടും ഉള്ളടക്ക ഉത്തരവാദിത്വവും',
      ),
      strings.localized(
        telugu:
            'మీ login వివరాలు భద్రంగా ఉంచాలి. మీరు upload చేసే ఫోటోలు, text, logos పై వాడుక హక్కు మీకే ఉండాలి. చట్టవిరుద్ధం, మోసపూరితం, ద్వేషపూరితం లేదా ఇతరుల హక్కులు ఉల్లంఘించే కంటెంట్ నిషేధం.',
        english:
            'You must keep your login details secure. You must have the right to use any photos, text, or logos you upload. Illegal, deceptive, hateful, or infringing content is prohibited.',
        hindi:
            'आपको अपने login विवरण सुरक्षित रखने होंगे। आप जो photo, text या logo upload करते हैं, उनका उपयोग करने का अधिकार आपके पास होना चाहिए। गैरकानूनी, भ्रामक, घृणास्पद या अधिकारों का उल्लंघन करने वाली सामग्री निषिद्ध है।',
        tamil:
            'உங்கள் login விவரங்களை பாதுகாப்பாக வைத்திருக்க வேண்டும். நீங்கள் upload செய்யும் photo, text, logo ஆகியவற்றைப் பயன்படுத்த உரிமை உங்களிடம் இருக்க வேண்டும். சட்டவிரோதம், ஏமாற்றம், வெறுப்பு அல்லது உரிமை மீறும் content தடைசெய்யப்படுகிறது.',
        kannada:
            'ನಿಮ್ಮ login ವಿವರಗಳನ್ನು ಸುರಕ್ಷಿತವಾಗಿ ಇಡಬೇಕು. ನೀವು upload ಮಾಡುವ photo, text, logo ಗಳನ್ನು ಬಳಸುವ ಹಕ್ಕು ನಿಮಗಿರಬೇಕು. ಕಾನೂನುಬಾಹಿರ, ತಪ್ಪುಮಾರಿಗೆಳೆಯುವ, ದ್ವೇಷಪೂರಿತ ಅಥವಾ ಹಕ್ಕು ಉಲ್ಲಂಘಿಸುವ content ನಿಷೇಧಿತವಾಗಿದೆ.',
        malayalam:
            'നിങ്ങളുടെ login വിവരങ്ങൾ സുരക്ഷിതമായി സൂക്ഷിക്കണം. നിങ്ങൾ upload ചെയ്യുന്ന photo, text, logo എന്നിവ ഉപയോഗിക്കാൻ അവകാശം നിങ്ങള്ക്ക് ഉണ്ടായിരിക്കണം. നിയമവിരുദ്ധം, വഞ്ചനാപരമായ, വിദ്വേഷപരമായ അല്ലെങ്കിൽ അവകാശലംഘന ഉള്ള content നിരോധിതമാണ്.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సబ్స్క్రిప్షన్',
        english: 'Subscription',
        hindi: 'सब्सक्रिप्शन और प्रीमियम',
        tamil: 'சந்தா மற்றும் பிரீமியம்',
        kannada: 'ಸಬ್ಸ್ಕ್ರಿಪ್ಷನ್ ಮತ್ತು ಪ್ರೀಮಿಯಂ',
        malayalam: 'സബ്സ്ക്രിപ്ഷനും പ്രീമിയവും',
      ),
      strings.localized(
        telugu:
            'ఫ్రీ-ట్యాబ్ పోస్టర్లకు ${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay} ట్రయల్ ఉంటుంది. ఆ ${SubscriptionPlanConfig.trialDays} రోజుల లోపు మీరు రద్దు చేయవచ్చు. రద్దు చేయకపోతే, తర్వాత నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} చొప్పున ఆటో రీన్యువల్ అవుతుంది. ప్రీమియమ్ పోస్టర్లు సబ్‌స్క్రిప్షన్‌తో అన్‌లాక్ కావు; వాటికి ప్రత్యేకంగా ఒక్కో పోస్టర్ ధర ఉండవచ్చు.',
        english:
            'The subscription includes a ${SubscriptionPlanConfig.trialPriceDisplay} trial for ${SubscriptionPlanConfig.trialDays} days. You may cancel within those ${SubscriptionPlanConfig.trialDays} days. If not cancelled, the plan auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month.',
        hindi:
            'फ्री-टैब पोस्टर्स के लिए 3 दिनों का Rs.4 ट्रायल शामिल है। 3 दिन पूरे होने के बाद आप cancel नहीं करते हैं तो यह प्लान Rs.149 प्रति माह पर auto-renew हो जाएगा। प्रीमियम पोस्टर्स इस सदस्यता से अनलॉक नहीं होते; उनके लिए अलग प्रति-पोस्टर कीमत हो सकती है।',
        tamil:
            'ஃப்ரீ-டாப் போஸ்டர்களுக்கு 3 நாட்களுக்கு Rs.4 டிரயல் வழங்கப்படுகிறது. 3 நாட்கள் முடிந்த பிறகு நீங்கள் cancel செய்யாவிட்டால், இந்த திட்டம் Rs.149/மாதம் என auto-renew ஆகும். பிரீமியம் போஸ்டர்கள் இந்த சந்தாவால் unlock ஆகாது; அவற்றுக்கு தனியாக ஒவ்வொரு போஸ்டருக்கும் விலை இருக்கலாம்.',
        kannada:
            'ಫ್ರೀ-ಟ್ಯಾಬ್ ಪೋಸ್ಟರ್‌ಗಳಿಗೆ 3 ದಿನಗಳ Rs.4 ಟ್ರಯಲ್ ಒಳಗೊಂಡಿದೆ. 3 ದಿನಗಳ ನಂತರ ನೀವು cancel ಮಾಡದಿದ್ದರೆ, ಈ ಪ್ಲಾನ್ Rs.149 ಪ್ರತಿ ತಿಂಗಳು auto-renew ಆಗುತ್ತದೆ. ಪ್ರೀಮಿಯಂ ಪೋಸ್ಟರ್‌ಗಳು ಈ ಚಂದಾದಾರಿಕೆಯಿಂದ unlock ಆಗುವುದಿಲ್ಲ; ಅವುಗಳಿಗೆ ಪ್ರತಿ ಪೋಸ್ಟರ್‌ಗೆ ಪ್ರತ್ಯೇಕ ದರವಿರಬಹುದು.',
        malayalam:
            'ഫ്രീ-ടാബ് പോസ്റ്ററുകൾക്ക് 3 ദിവസത്തേക്ക് Rs.4 ട്രയൽ ലഭ്യമാണ്. 3 ദിവസം കഴിഞ്ഞിട്ടും നിങ്ങൾ cancel ചെയ്യാത്ത പക്ഷം ഈ പ്ലാൻ Rs.149/മാസം നിരക്കിൽ auto-renewal ആയി തുടരും. പ്രീമിയം പോസ്റ്ററുകൾ ഈ സബ്സ്ക്രിപ്ഷനിലൂടെ unlock ആവില്ല; അവയ്ക്ക് ഓരോ പോസ്റ്ററിനും വേറെ വില ഉണ്ടായിരിക്കാം.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'రీఫండ్, రద్దు, ఆటో రీన్యువల్',
        english: 'Refund, cancellation, and auto-renewal',
      ),
      strings.localized(
        telugu:
            'సబ్‌స్క్రిప్షన్ రద్దు సాధారణంగా మీ Play Store లేదా App Store సబ్‌స్క్రిప్షన్ సెట్టింగ్స్‌లో చేయాలి. రద్దు చేసిన తర్వాత ప్రస్తుత బిల్లింగ్ గడువు ముగిసే వరకు యాక్సెస్ కొనసాగవచ్చు. రీఫండ్ అర్హత Google Play లేదా Apple విధానాల ప్రకారం నిర్ణయించబడుతుంది.',
        english:
            'Subscription cancellation is generally managed through your Play Store or App Store subscription settings. After cancelling, access may continue until the current billing period ends. Refund eligibility is determined by Google Play or Apple policies.',
        hindi:
            'सब्सक्रिप्शन रद्द करना आमतौर पर आपके Play Store या App Store सब्सक्रिप्शन सेटिंग्स में करना होता है। रद्द करने के बाद, वर्तमान बिलिंग अवधि समाप्त होने तक एक्सेस जारी रह सकता है। रिफंड पात्रता Google Play या Apple नीतियों के अनुसार तय होती है।',
        tamil:
            'சந்தாவை ரத்து செய்வது பொதுவாக உங்கள் Play Store அல்லது App Store சந்தா அமைப்புகளில் செய்ய வேண்டும். ரத்து செய்த பிறகு, தற்போதைய பில்லிங் காலம் முடியும் வரை அணுகல் தொடரலாம். ரீஃபண்ட் தகுதி Google Play அல்லது Apple விதிகளின் அடிப்படையில் தீர்மானிக்கப்படும்.',
        kannada:
            'ಚಂದಾವನ್ನು ರದ್ದುಪಡಿಸುವುದು ಸಾಮಾನ್ಯವಾಗಿ ನಿಮ್ಮ Play Store ಅಥವಾ App Store ಚಂದಾ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಮಾಡಬೇಕು. ರದ್ದು ಮಾಡಿದ ನಂತರ, ಪ್ರಸ್ತುತ ಬಿಲ್ಲಿಂಗ್ ಅವಧಿ ಮುಗಿಯುವವರೆಗೆ ಪ್ರವೇಶ ಮುಂದುವರಿಯಬಹುದು. ರಿಫಂಡ್ ಅರ್ಹತೆ Google Play ಅಥವಾ Apple ನೀತಿಗಳ ಪ್ರಕಾರ ನಿರ್ಧರಿಸಲಾಗುತ್ತದೆ.',
        malayalam:
            'സബ്സ്ക്രിപ്ഷൻ റദ്ദാക്കുന്നത് സാധാരണയായി നിങ്ങളുടെ Play Store അല്ലെങ്കിൽ App Store സബ്സ്ക്രിപ്ഷൻ ക്രമീകരണങ്ങളിൽ ചെയ്യേണ്ടതാണ്. റദ്ദാക്കിയ ശേഷം, നിലവിലെ ബില്ലിംഗ് കാലയളവ് അവസാനിക്കുന്നതുവരെ ആക്സസ് തുടർന്നേക്കാം. റീഫണ്ട് അർഹത Google Play അല്ലെങ്കിൽ Apple നയങ്ങൾ പ്രകാരം തീരുമാനിക്കപ്പെടും.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఖాతా తొలగింపు మరియు డేటా తొలగింపు',
        english: 'Account deletion and data removal',
      ),
      strings.localized(
        telugu:
            'యాప్‌లో ఖాతా తొలగింపు అభ్యర్థన చేసే ఆప్షన్ అందుబాటులో ఉంటుంది. డిలీట్ అభ్యర్థన తర్వాత లాగిన్ యాక్సెస్, పోస్టర్ ప్రొఫైల్ వివరాలు మరియు అనుసంధానమైన యాప్ డేటా తొలగించబడవచ్చు. కొన్ని బిల్లింగ్ లేదా ప్లాట్‌ఫారమ్‌కు అవసరమైన రికార్డులు కొంతకాలం నిల్వ ఉండవచ్చు. పబ్లిక్ డిలీషన్ వివరాలు: ${AppPublicInfo.accountDeletionUrl}',
        english:
            'The app provides an in-app account deletion request option. After deletion, login access, poster profile details, and linked in-app data may be removed. Some billing or platform-required records may be retained for a limited period. Public deletion details: ${AppPublicInfo.accountDeletionUrl}',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఒకే పరికర ఖాతా యాక్సెస్',
        english: 'Single-device account access',
      ),
      strings.localized(
        telugu:
            'ఒకే ఖాతా ఒకేసారి ఒక ప్రధాన పరికరంలో మాత్రమే యాక్టివ్‌గా ఉండేలా సెషన్ నియంత్రణలు అమల్లో ఉండవచ్చు. అదే ఖాతాతో మరో పరికరంలో లాగిన్ అయితే, ముందున్న పరికరం ఆటోమేటిక్‌గా సైన్ అవుట్ కావచ్చు.',
        english:
            'Session controls may keep one account active on one primary device at a time. If the same account signs in on another device, the previous device session may be signed out automatically.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సేవ మార్పులు',
        english: 'Service Changes',
        hindi: 'सेवा परिवर्तन',
        tamil: 'சேவை மாற்றங்கள்',
        kannada: 'ಸೇವಾ ಬದಲಾವಣೆಗಳು',
        malayalam: 'സേവന മാറ്റങ്ങൾ',
      ),
      strings.localized(
        telugu:
            'యాప్ ఫీచర్లు, ధరలు, డిజైన్లు మరియు నిబంధనలు సమయానుసారం మారవచ్చు. సాంకేతిక లేదా మూడో పక్ష సేవల సమస్యల వల్ల కొన్ని ఫీచర్లు తాత్కాలికంగా అందుబాటులో లేకపోవచ్చు.',
        english:
            'Features, pricing, designs, and these terms may change over time. Some features may become temporarily unavailable due to technical or third-party service issues.',
        hindi:
            'फीचर, कीमत, डिज़ाइन और ये शर्तें समय के साथ बदल सकती हैं। तकनीकी या थर्ड-पार्टी समस्या के कारण कुछ फीचर अस्थायी रूप से उपलब्ध न हों।',
        tamil:
            'அம்சங்கள், விலை, வடிவமைப்புகள் மற்றும் இந்த விதிமுறைகள் காலப்போக்கில் மாறலாம். தொழில்நுட்ப அல்லது third-party பிரச்சினைகளால் சில அம்சங்கள் தற்காலிகமாக கிடைக்காமல் இருக்கலாம்.',
        kannada:
            'ವೈಶಿಷ್ಟ್ಯಗಳು, ಬೆಲೆ, ವಿನ್ಯಾಸಗಳು ಮತ್ತು ಈ ನಿಯಮಗಳು ಸಮಯದೊಂದಿಗೆ ಬದಲಾಗಬಹುದು. ತಾಂತ್ರಿಕ ಅಥವಾ third-party ಸಮಸ್ಯೆಯಿಂದ ಕೆಲವು ವೈಶಿಷ್ಟ್ಯಗಳು ತಾತ್ಕಾಲಿಕವಾಗಿ ಲಭ್ಯವಿರದಿರಬಹುದು.',
        malayalam:
            'ഫീച്ചറുകൾ, വില, ഡിസൈൻ, ഈ നിബന്ധനകൾ സമയം കഴിഞ്ഞ് മാറാം. സാങ്കേതിക അല്ലെങ്കിൽ third-party പ്രശ്നങ്ങളാൽ ചില ഫീച്ചറുകൾ താൽക്കാലികമായി ലഭ്യമാകാതിരിക്കാം.',
      ),
    ),
  ];
}
