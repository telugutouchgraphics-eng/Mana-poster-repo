import 'package:flutter/material.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';

enum LegalDocumentType { privacyPolicy, termsAndConditions }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.documentType});

  final LegalDocumentType documentType;

  @override
  Widget build(BuildContext context) {
    final copy = _LegalCopy(context.strings, documentType);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          copy.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
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
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
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
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      copy.badge,
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.lastUpdated,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
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
              style: TextStyle(
                color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              color: cs.onSurfaceVariant,
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

  String get title => _isPrivacy
      ? strings.localized(
          telugu: 'ప్రైవసీ పాలసీ',
          english: 'Privacy Policy',
          hindi: 'प्राइवेसी पॉलिसी',
          tamil: 'தனியுரிமைக் கொள்கை',
          kannada: 'ಗೌಪ್ಯತಾ ನೀತಿ',
          malayalam: 'സ്വകാര്യതാ നയം',
          marathi: 'गोपनीयता धोरण',
          gujarati: 'ગોપનીયતા નીતિ',
          bengali: 'গোপনীয়তা নীতি',
          punjabi: 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ',
          odia: 'ଗୋପନୀୟତା ନୀତି',
          assamese: 'গোপনীয়তা নীতি',
          konkani: 'ಗೌಪ್ಯತಾ ನೀತಿ',
          nepali: 'गोपनीयता नीति',
          meitei: 'প্রাইভেসি পোলিসি',
          mizo: 'Privacy Policy',
          kashmiri: 'رازدٲری ہٕنٛز پالیسی',
          ladakhi: 'གསང་རྒྱའི་སྲིད་ཇུས།',
        )
      : strings.localized(
          telugu: 'నిబంధనలు మరియు షరతులు',
          english: 'Terms & Conditions',
          hindi: 'नियम और शर्तें',
          tamil: 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
          kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
          malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും',
          marathi: 'नियम आणि अटी',
          gujarati: 'નિયમો અને શરતો',
          bengali: 'শর্তাবলী',
          punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ',
          odia: 'ନିୟମ ଏବଂ ସର୍ତ୍ତାବଳୀ',
          assamese: 'নিয়ম আৰু চৰ্তাৱলী',
          konkani: 'ನಿಬಂಧನಾಂ ಆನಿ ಶರತಾಂ',
          nepali: 'नियम तथा सर्तहरू',
          meitei: 'তর্মস অমসুং কন্দিসনশিং',
          mizo: 'Terms & Conditions',
          kashmiri: 'شرائط و ضوابط',
          ladakhi: 'ཆart་རྐྱེན་རྣམས།',
        );

  String get badge => _isPrivacy
      ? strings.localized(
          telugu: 'డేటా రక్షణ',
          english: 'Data Protection',
          hindi: 'डेटा सुरक्षा',
          tamil: 'தரவு பாதுகாப்பு',
          kannada: 'ಡೇಟಾ ರಕ್ಷಣೆ',
          malayalam: 'ഡാറ്റാ സംരക്ഷണം',
          marathi: 'डेटा संरक्षण',
          gujarati: 'ડેટા સુરક્ષા',
          bengali: 'তথ্য সুরক্ষা',
          punjabi: 'ਡੇਟਾ ਸੁਰੱਖਿਆ',
          odia: 'ଡାଟା ସୁରକ୍ଷା',
          assamese: 'তথ্য সুৰক্ষা',
          konkani: 'ಡೇಟಾ ರಕ್ಷಣ್',
          nepali: 'डाटा सुरक्षा',
          meitei: 'দেতা ঙাক-শেনবা',
          mizo: 'Data venhimna',
          kashmiri: 'ڈیٹا ہٕنٛز حِفاظَت',
          ladakhi: 'གྲངས་གཞི་སྲུང་སྐྱོབ།',
        )
      : strings.localized(
          telugu: 'వినియోగ నియమాలు',
          english: 'Usage Terms',
          hindi: 'उपयोग नियम',
          tamil: 'பயன்பாட்டு விதிகள்',
          kannada: 'ಬಳಕೆ ನಿಯಮಗಳು',
          malayalam: 'ഉപയോഗ നിബന്ധനകൾ',
          marathi: 'वापर अटी',
          gujarati: 'વપરાશની શરતો',
          bengali: 'ব্যবহারের নিয়মাবলী',
          punjabi: 'ਵਰਤੋਂ ਦੇ ਨਿਯਮ',
          odia: 'ବ୍ୟବହାର ନିୟମାବଳୀ',
          assamese: 'ব্যৱহাৰৰ নিয়মসমূহ',
          konkani: 'ವಾಪರ್ಚಿಂ ನಿಬಂಧನಾಂ',
          nepali: 'प्रयोगका सर्तहरू',
          meitei: 'শীজিন্নবগী নিয়মশিং',
          mizo: 'Hman dan turte',
          kashmiri: 'اِستعمال کِس نِیَم',
          ladakhi: 'སྤྱོད་པའི་ཆart་རྐྱེན།',
        );

  String get summary => _isPrivacy
      ? strings.localized(
          telugu:
              'మీ డేటా, subscriptions, ప్రకటనలు, account deletion మరియు Firebase సేవల వినియోగం గురించి ఈ పేజీ వివరిస్తుంది.',
          english:
              'This page explains how Mana Poster Ai handles your data, subscriptions, editor assets, Telugu fonts, background removal, ads, account deletion, and Firebase-powered services.',
          hindi:
              'यह पृष्ठ बताता है कि Mana Poster Ai आपके डेटा, सदस्यता, संपादक एसेट्स, विज्ञापनों और सेवाओं को कैसे संभालता है।',
          tamil:
              'உங்கள் தரவு, சந்தாக்கள், எடிட்டர் அம்சங்கள், விளம்பரங்கள் மற்றும் சேவைகளை Mana Poster Ai எவ்வாறு கையாள்கிறது என்பதை இப்பக்கம் விளக்குகிறது.',
          kannada:
              'ನಿಮ್ಮ ಡೇಟಾ, ಚಂದಾದಾರಿಕೆಗಳು, ಎಡಿಟರ್ ಸೌಲಭ್ಯಗಳು, ಜಾಹೀರಾತುಗಳು ಮತ್ತು ಸೇವೆಗಳನ್ನು Mana Poster Ai ಹೇಗೆ ನಿರ್ವಹಿಸುತ್ತದೆ ಎಂಬುದನ್ನು ಈ ಪುಟ ವಿವರಿಸುತ್ತದೆ.',
          malayalam:
              'നിങ്ങളുടെ ഡാറ്റ, സബ്‌സ്‌ക്രിപ്ഷനുകൾ, എഡിറ്റർ ഫീച്ചറുകൾ, പരസ്യങ്ങൾ എന്നിവ മന പോസ്റ്റർ എഐ എങ്ങനെ കൈകാര്യം ചെയ്യുന്നുവെന്ന് ഈ പേജ് വിശദീകരിക്കുന്നു.',
          marathi:
              'हे पृष्ठ स्पष्ट करते की Mana Poster Ai तुमचा डेटा, सदस्यता, एडिटर अ‍ॅसेट्स, जाहिराती आणि सेवा कशा हाताळते.',
          gujarati:
              'આ પૃષ્ઠ સમજાવે છે કે Mana Poster Ai તમારા ડેટા, સબ્સ્ક્રિપ્શન્સ, એડિટર એસેટ્સ, જાહેરાતો અને સેવાઓને કેવી રીતે હેન્ડલ કરે છે.',
          bengali:
              'এই পৃষ্ঠাটি ব্যাখ্যা করে যে কীভাবে Mana Poster Ai আপনার তথ্য, সাবস্ক্রিপশন, এডিটর উপাদান, বিজ্ঞাপন এবং পরিষেবা পরিচালনা করে।',
          punjabi:
              'ਇਹ ਪੰਨਾ ਦੱਸਦਾ ਹੈ ਕਿ Mana Poster Ai ਤੁਹਾਡੇ ਡੇਟਾ, ਗਾਹਕੀਆਂ, ਐਡੀਟਰ ਸੰਪਤੀਆਂ, ਇਸ਼ਤਿਹਾਰਾਂ ਅਤੇ ਸੇਵਾਵਾਂ ਨੂੰ ਕਿਵੇਂ ਸੰਭਾਲਦਾ ਹੈ।',
          odia:
              'ଏହି ପୃଷ୍ଠା ବ୍ୟାଖ୍ୟା କରେ ଯେ Mana Poster Ai କିପରି ଆପଣଙ୍କ ଡାଟା, ସଦସ୍ୟତା, ଏଡିଟର୍ ଆସେଟ୍, ବିଜ୍ଞାପନ ଏବଂ ସେବା ପରିଚାଳନା କରେ।',
          assamese:
              'এই পৃষ্ঠাই ব্যাখ্যা কৰে যে Mana Poster Ai-এ আপোনাৰ তথ্য, গ্ৰাহকভুক্তি, এডিটৰ সম্পদ, বিজ্ঞাপন আৰু সেৱাসমূহ কেনেকৈ পৰিচালনা কৰে।',
          konkani:
              'ಹೆಂ ಪಾನ್ Mana Poster Ai ತುಮ್ಚೊ ಡೇಟಾ, ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ಸ್, ಎಡಿಟರ್ ಅಸೆಟ್ಸ್, ಜಾಹಿರಾತಾಂ ಆನಿ ಸೆವಾ ಕಶೆಂ ಸಾಂಭಾಳ್ತಾ ಮ್ಹಣ್ ವಿವರಿತಾ.',
          nepali:
              'यो पृष्ठले Mana Poster Ai ले तपाईंको डाटा, सदस्यता, सम्पादक सम्पत्ति, विज्ञापन र सेवाहरू कसरी ह्यान्डल गर्छ भनेर वर्णन गर्छ।',
          meitei:
              'লমাই অসিনা Mana Poster Ai না নহাক্কী দেতা, সবস্ক্রিপ্সন, এদিতর এসেতশিং, এদভর্তাইজমেন্তশিং অমসুং সর্ভিসশিং করম্না পায়রি হায়বা তাক্লি।',
          mizo:
              'He page hian Mana Poster Ai-in i data, subscription, editor hmanrua, ads leh service dangte a enkawl dan a hrilhfiah.',
          kashmiri:
              'یہِ صَفہٕ چھُ وضاحت کَران زِ Mana Poster Ai کِتھکٔن چھُ تُہنٛد ڈیٹا، سبسکرپشن، ایڈیٹر اثاثہٕ تہٕ باقٕے خدمات سَنبھالان۔',
          ladakhi:
              'ཤོག་ངོས་འདིས་ Mana Poster Ai ཡིས་ཁྱེད་ཀྱི་གྲངས་གཞི། མངགས་ཉོ། ཞུ་དག་ཆས་ཀྱི་རྒྱུ་ཆ། ཁྱབ་བསྒྲགས་དང་ཞབས་ཞུ་རྣམས་ཇི་ལྟར་བདག་གཉེར་བྱེད་མིན་གསལ་བཤད་བྱེད།',
        )
      : strings.localized(
          telugu:
              'Mana Poster Ai వాడకం, subscriptions, చెల్లింపులు, ప్రకటనలు, ఖాతా బాధ్యతలు మరియు సేవా పరిమితులకు సంబంధించిన నియమాలు ఇక్కడ ఉన్నాయి.',
          english:
              'This page contains the rules for using Mana Poster Ai, including subscriptions, editor tools, premium assets, payments, ads, account responsibility, and service limitations.',
          hindi:
              'इस पृष्ठ में सदस्यता, संपादक उपकरण, भुगतान, विज्ञापन और सेवा सीमाओं सहित Mana Poster Ai के उपयोग के नियम शामिल हैं।',
          tamil:
              'சந்தாக்கள், எடிட்டர் கருவிகள், கட்டணங்கள், விளம்பரங்கள் மற்றும் பொறுப்புகள் உட்பட Mana Poster Ai ஐப் பயன்படுத்துவதற்கான விதிகள் இதில் உள்ளன.',
          kannada:
              'ಚಂದಾದಾರಿಕೆಗಳು, ಎಡಿಟರ್ ಪರಿಕರಗಳು, ಪಾವತಿಗಳು ಮತ್ತು ಜಾಹೀರಾತುಗಳು ಸೇರಿದಂತೆ Mana Poster Ai ಬಳಸುವ ನಿಯಮಗಳು ಈ ಪುಟದಲ್ಲಿವೆ.',
          malayalam:
              'സബ്‌സ്‌ക്രിപ്ഷനുകൾ, എഡിറ്റർ ടൂളുകൾ, പേയ്‌മെന്റുകൾ, പരസ്യങ്ങൾ എന്നിവ ഉൾപ്പെടെയുള്ള മന പോസ്റ്റർ എഐ ഉപയോഗ നിബന്ധനകൾ ഇവിടെ നൽകുന്നു.',
          marathi:
              'या पृष्ठावर सदस्यता, एडिटर साधने, पेमेंट्स, जाहिराती आणि सेवा मर्यादांसह Mana Poster Ai वापरण्याचे नियम आहेत.',
          gujarati:
              'આ પૃષ્ઠ પર સબ્સ્ક્રિપ્શન્સ, એડિટર ટૂલ્સ, ચુકવણીઓ, જાહેરાતો અને સેવા મર્યાદાઓ સહિત Mana Poster Ai નો ઉપયોગ કરવાના નિયમો શામેલ છે.',
          bengali:
              'এই পৃষ্ঠায় সাবস্ক্রিপশন, এডিটর সরঞ্জাম, অর্থপ্রদান, বিজ্ঞাপন এবং দায়িত্ব সহ Mana Poster Ai ব্যবহারের নিয়ম রয়েছে।',
          punjabi:
              'ਇਸ ਪੰਨੇ ਤੇ ਗਾਹਕੀਆਂ, ਐਡੀਟਰ ਟੂਲ, ਭੁਗਤਾਨ, ਇਸ਼ਤਿਹਾਰ ਅਤੇ ਸੇਵਾ ਸੀਮਾਵਾਂ ਸਮੇਤ Mana Poster Ai ਦੀ ਵਰਤੋਂ ਦੇ ਨਿਯਮ ਹਨ।',
          odia:
              'ଏହି ପୃଷ୍ଠାରେ ସଦସ୍ୟତା, ଏଡିଟର୍ ଉପକରଣ, ଦେୟ, ବିଜ୍ଞାପନ ଏବଂ ସେବା ସୀମା ସହିତ Mana Poster Ai ବ୍ୟବହାର କରିବାର ନିୟମାବଳୀ ରହିଛି।',
          assamese:
              'এই পৃষ্ঠাত গ্ৰাহকভুক্তি, এডিটৰ সঁজুলি, পৰিশোধ, বিজ্ঞাপন আৰু সেৱাৰ সীমাবদ্ধতাকে ধৰি Mana Poster Ai ব্যৱহাৰৰ নিয়মসমূহ আছে।',
          konkani:
              'ಹ್ಯಾ ಪಾನಾರ್ ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ಸ್, ಎಡಿಟರ್ ಟೂಲ್ಸ್, ಪಾವತಿ, ಜಾಹಿರಾತಾಂ ಸಾಂಗಾತಾ Mana Poster Ai ವಾಪರ್ಚಿಂ ನಿಬಂಧನಾಂ ಆಸಾತ್.',
          nepali:
              'यस पृष्ठमा सदस्यता, सम्पादक उपकरण, भुक्तानी, विज्ञापन र सेवा सीमाहरू सहित Mana Poster Ai प्रयोग गर्ने नियमहरू छन्।',
          meitei:
              'লমাই অসিদা সবস্ক্রিপ্সন, এদিতর তুলশিং, পেমেন্ত, এদভর্তাইজমেন্ত অমসুং সর্ভিস লিমিৎশিং য়াওনা Mana Poster Ai শীজিন্নবগী নিয়মশিং য়াওরি।',
          mizo:
              'He page hian subscription, editor hmanrua, payment, ads leh mawhphurhna huam telin Mana Poster Ai hman dan tur dan a keng tel.',
          kashmiri:
              'اَتھ صَفَس مَنٛز چھِ سبسکرپشن، ایڈیٹر ٹولز، ادائیگی، اشتہارات تہٕ خدماتن ہٕنٛدی حدوٗد سٟتؠ وابَستہٕ نِیَم شٲمِل۔',
          ladakhi:
              'ཤོག་ངོས་འདིར་མངགས་ཉོ། ཞུ་དག་ཆས་ཀྱི་ལག་ཆ། དངུལ་སྤྲོད། ཁྱབ་བསྒྲགས་སོགས་ Mana Poster Ai སྤྱོད་པའི་ཆart་རྐྱེན་རྣམས་ཚུད་ཡོད།',
        );

  String get lastUpdated => strings.localized(
    telugu: 'చివరి నవీకరణ: 23 జూలై 2026',
    english: 'Last updated: July 23, 2026',
    hindi: 'अंतिम अपडेट: 23 जुलाई 2026',
    tamil: 'கடைசி புதுப்பிப்பு: ஜூலை 23, 2026',
    kannada: 'ಕೊನೆಯ ನವೀಕರಣ: ಜುಲೈ 23, 2026',
    malayalam: 'അവസാനം പുതുക്കിയത്: 23 ജൂലൈ 2026',
    marathi: 'शेवटचे अद्यतन: २३ जुलै २०२६',
    gujarati: 'છેલ્લે અપડેટ કર્યું: 23 જુલાઈ, 2026',
    bengali: 'সর্বশেষ আপডেট: ২৩ জুলাই, ২০২৬',
    punjabi: 'ਆਖਰੀ ਅੱਪਡੇਟ: 23 ਜੁਲਾਈ 2026',
    odia: 'ଶେଷ ଅପଡେଟ୍: ୨୩ ଜୁଲାଇ ୨୦୨୬',
    assamese: 'সৰ্বশেষ আপডেট: ২৩ জুলাই, ২০২৬',
    konkani: 'ಆಖೇರಿಕ್ ನವೀಕರಣ್: 23 ಜುಲೈ 2026',
    nepali: 'अन्तिम अपडेट: २३ जुलाई २०२६',
    meitei: 'অরোইবা অপদেত: ২৩ জুলাই, ২০২৬',
    mizo: 'Siamthat hnuhnun ber: July 23, 2026',
    kashmiri: 'ٲخری اَپڈیٹ: ۲۳ جولائی ۲۰۲۶',
    ladakhi: 'མཐའ་མའི་དུས་མཐུན་བཟོ་བ། སྤྱི་ལོ་ ༢༠༢༦ ཟླ་ ༧ ཚེས་ ༢༣',
  );

  List<_LegalSection> get sections =>
      _isPrivacy ? _privacySections : _termsSections;

  String get footer => strings.localized(
    telugu: 'ప్రశ్నలు ఉంటే ${AppPublicInfo.supportEmail} కి సంప్రదించండి.',
    english: 'For questions, contact ${AppPublicInfo.supportEmail}.',
    hindi: 'प्रश्नों के लिए ${AppPublicInfo.supportEmail} पर संपर्क करें।',
    tamil: 'கேள்விகளுக்கு ${AppPublicInfo.supportEmail}-ஐத் தொடர்பு கொள்ளவும்.',
    kannada: 'ಪ್ರಶ್ನೆಗಳಿದ್ದರೆ ${AppPublicInfo.supportEmail} ಅನ್ನು ಸಂಪರ್ಕಿಸಿ.',
    malayalam: 'ചോദ്യങ്ങൾക്ക് ${AppPublicInfo.supportEmail}-മായി ബന്ധപ്പെടുക.',
    marathi: 'प्रश्नांसाठी ${AppPublicInfo.supportEmail} वर संपर्क साधा.',
    gujarati: 'પ્રશ્નો માટે ${AppPublicInfo.supportEmail} પર સંપર્ક કરો.',
    bengali: 'প্রশ্নের জন্য ${AppPublicInfo.supportEmail}-এ যোগাযোগ করুন।',
    punjabi: 'ਸਵਾਲਾਂ ਲਈ ${AppPublicInfo.supportEmail} ਤੇ ਸੰਪਰਕ ਕਰੋ।',
    odia: 'ପ୍ରଶ୍ନ ପାଇଁ ${AppPublicInfo.supportEmail} ସହିତ ଯୋଗାଯୋଗ କରନ୍ତୁ।',
    assamese: 'প্ৰশ্নৰ বাবে ${AppPublicInfo.supportEmail} লৈ যোগাযোগ কৰক।',
    konkani: 'ಸವಾಲಾಂ ಖಾತೀರ್ ${AppPublicInfo.supportEmail} ಕಡೆನ್ ಸಂಪರ್ಕ್ ಕರಾ.',
    nepali:
        'प्रश्नहरूको लागि ${AppPublicInfo.supportEmail} मा सम्पर्क गर्नुहोस्।',
    meitei: 'ৱাহংশিংগীদমক ${AppPublicInfo.supportEmail} দা কন্তেক্ত তৌবীয়ু।',
    mizo:
        'Zawhna i neih chuan ${AppPublicInfo.supportEmail}-ah hian bia ang che.',
    kashmiri: 'سوالاتن باپتھ کٔریو ${AppPublicInfo.supportEmail} پؠٹھ رابطہٕ۔',
    ladakhi:
        'དྲི་བ་ཡོད་ན་ ${AppPublicInfo.supportEmail} ལ་འབྲེལ་གཏུགས་གནང་རོགས།',
  );

  List<_LegalSection> get _privacySections => <_LegalSection>[
    _LegalSection(
      strings.localized(
        telugu: 'మేము ఏమి సేకరిస్తాము',
        english: 'What We Collect',
        hindi: 'हम क्या एकत्र करते हैं',
        tamil: 'நாங்கள் எதைச் சேகரிக்கிறோம்',
        kannada: 'ನಾವು ಏನನ್ನು ಸಂಗ್ರಹಿಸುತ್ತೇವೆ',
        malayalam: 'ഞങ്ങൾ എന്താണ് ശേഖരിക്കുന്നത്',
        marathi: 'आम्ही काय गोळा करतो',
        gujarati: 'અમે શું એકત્રિત કરીએ છીએ',
        bengali: 'আমরা কী সংগ্রহ করি',
        punjabi: 'ਅਸੀਂ ਕੀ ਇਕੱਠਾ ਕਰਦੇ ਹਾਂ',
        odia: 'ଆମେ କ’ଣ ସଂଗ୍ରହ କରୁ',
        assamese: 'আমি কি সংগ্ৰহ কৰোঁ',
        konkani: 'ಆಮಿ ಕಿತೆಂ ಜಮೊ ಕರ್ತಾಂವ್',
        nepali: 'हामी के सङ्कलन गर्छौं',
        meitei: 'ঐখোয়না করি খোমগৎলিবা',
        mizo: 'Engte nge kan lakkhawm',
        kashmiri: 'أسی کیاہ چھِ جَمَہ کَران',
        ladakhi: 'ང་ཚོས་ཅི་ཞིག་བསྡུ་རུབ་བྱེད་དམ།',
      ),
      strings.localized(
        telugu:
            'మేము మీ ఇమెయిల్, పేరు, Firebase UID, Google సైన్-ఇన్ సమాచారం, పోస్టర్ ప్రొఫైల్ వివరాలు మరియు వినియోగ సమాచారాన్ని సేకరిస్తాము.',
        english:
            'We collect your email address, name, Firebase UID, Google Sign-In profile information, poster profile text, and app usage details to provide personalized services.',
        hindi:
            'हम आपकी ईमेल, नाम, Firebase UID, Google प्रोफ़ाइल जानकारी, पोस्टर प्रोफ़ाइल विवरण और उपयोग की जानकारी एकत्र करते हैं।',
        tamil:
            'உங்கள் மின்னஞ்சல், பெயர், Firebase UID, கூகிள் சுயவிவரத் தகவல், போஸ்டர் சுயவிவரம் மற்றும் பயன்பாட்டு விவரங்களைச் சேகரிக்கிறோம்.',
        kannada:
            'ನಿಮ್ಮ ಇಮೇಲ್, ಹೆಸರು, Firebase UID, Google ಪ್ರೊಫೈಲ್ ಮಾಹಿತಿ, ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್ ವಿವರಗಳು ಮತ್ತು ಬಳಕೆಯ ಮಾಹಿತಿಯನ್ನು ಸಂಗ್ರಹಿಸುತ್ತೇವೆ.',
        malayalam:
            'നിങ്ങളുടെ ഇമെയിൽ, പേര്, Firebase UID, ഗൂഗിൾ പ്രൊഫൈൽ വിവരങ്ങൾ, പോസ്റ്റർ പ്രൊഫൈൽ, ആപ്പ് ഉപയോഗ വിവരങ്ങൾ എന്നിവ ഞങ്ങൾ ശേഖരിക്കുന്നു.',
        marathi:
            'आम्ही तुमचा ईमेल, नाव, Firebase UID, Google प्रोफाइल माहिती, पोस्टर प्रोफाइल तपशील आणि अ‍ॅप वापर माहिती गोळा करतो.',
        gujarati:
            'અમે તમારું ઇમેઇલ, નામ, Firebase UID, Google પ્રોફાઇલ માહિતી, પોસ્ટર પ્રોફાઇલ વિગતો અને વપરાશ માહિતી એકત્રિત કરીએ છીએ.',
        bengali:
            'আমরা আপনার ইমেল, নাম, Firebase UID, Google প্রোফাইল তথ্য, পোস্টার প্রোফাইল বিবরণ এবং অ্যাপ ব্যবহারের তথ্য সংগ্রহ করি।',
        punjabi:
            'ਅਸੀਂ ਤੁਹਾਡਾ ਈਮੇਲ, ਨਾਮ, Firebase UID, Google ਪ੍ਰੋਫਾਈਲ ਜਾਣਕਾਰੀ, ਪੋਸਟਰ ਪ੍ਰੋਫਾਈਲ ਵੇਰਵੇ ਅਤੇ ਵਰਤੋਂ ਜਾਣਕਾਰੀ ਇਕੱਠੀ ਕਰਦੇ ਹਾਂ।',
        odia:
            'ଆମେ ଆପଣଙ୍କ ଇମେଲ୍, ନାମ, Firebase UID, Google ପ୍ରୋଫାଇଲ୍ ସୂଚନା, ପୋଷ୍ଟର ପ୍ରୋଫାଇଲ୍ ଏବଂ ବ୍ୟବହାର ବିବରଣୀ ସଂଗ୍ରହ କରୁ।',
        assamese:
            'আমি আপোনাৰ ইমেইল, নাম, Firebase UID, Google প্ৰʼফাইল তথ্য, পোষ্টাৰ প্ৰʼফাইল বিৱৰণ আৰু ব্যৱহাৰৰ তথ্য সংগ্ৰহ কৰোঁ।',
        konkani:
            'ಆಮಿ ತುಮ್ಚೊ ಇಮೇಲ್, ನಾಂವ್, Firebase UID, Google ಪ್ರೊಫೈಲ್ ಮಾಹಿತಿ, ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್ ವಿವರಾಂ ಜಮೊ ಕರ್ತಾಂವ್.',
        nepali:
            'हामी तपाईंको इमेल, नाम, Firebase UID, Google प्रोफाइल जानकारी, पोस्टर प्रोफाइल र प्रयोग विवरणहरू सङ्कलन गर्छौं।',
        meitei:
            'ঐখোয়না নহাক্কী ইমেল, মিং, Firebase UID, Google প্রোফাইল ইনফোর্মেসন, পোস্তর প্রোফাইল অমসুং য়ুসেজ দেতা খোমগৎলি।',
        mizo:
            'I email address, hming, Firebase UID, Google Sign-In profile information, poster profile text leh hman dan chanchinte kan la khawm.',
        kashmiri:
            'أسی چھِ تُہنٛز ای میل، ناو، Firebase UID، Google پروفائل معلومات، تہٕ اِستعمالٕچ تفصیلات جَمَہ کَران۔',
        ladakhi:
            'ང་ཚོས་ཁྱེད་ཀྱི་གློག་འཕྲིན། མིང་། Firebase UID། Google གསལ་བཤད་གནས་ཚུལ། པོསྚར་གསལ་བཤད་དང་སྤྱོད་པའི་གནས་ཚུལ་བསྡུ་རུབ་བྱེད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'మేము డేటాను ఎలా ఉపయోగిస్తాము',
        english: 'How We Use Data',
        hindi: 'हम डेटा का उपयोग कैसे करते हैं',
        tamil: 'தரவை நாங்கள் எவ்வாறு பயன்படுத்துகிறோம்',
        kannada: 'ನಾವು ಡೇಟಾವನ್ನು ಹೇಗೆ ಬಳಸುತ್ತೇವೆ',
        malayalam: 'ഞങ്ങൾ എങ്ങനെ ഡാറ്റ ഉപയോഗിക്കുന്നു',
        marathi: 'आम्ही डेटा कसा वापरतो',
        gujarati: 'અમે ડેટાનો ઉપયોગ કેવી રીતે કરીએ છીએ',
        bengali: 'আমরা কীভাবে তথ্য ব্যবহার করি',
        punjabi: 'ਅਸੀਂ ਡੇਟਾ ਦੀ ਵਰਤੋਂ ਕਿਵੇਂ ਕਰਦੇ ਹਾਂ',
        odia: 'ଆମେ ଡାଟା କିପରି ବ୍ୟବହାର କରୁ',
        assamese: 'আমি কেনেকৈ তথ্য ব্যৱহাৰ কৰোঁ',
        konkani: 'ಆಮಿ ಡೇಟಾ ಕಶೆಂ ವಾಪರ್ತಾಂವ್',
        nepali: 'हामी डाटा कसरी प्रयोग गर्छौं',
        meitei: 'ঐখোয়না দেতা করম্না শীজিন্নরিবা',
        mizo: 'Data kan hman dan',
        kashmiri: 'أسی کِتھکٔن چھِ ڈیٹا اِستعمال کَران',
        ladakhi: 'ང་ཚོས་གྲངས་གཞི་ཇི་ལྟར་སྤྱོད་དམ།',
      ),
      strings.localized(
        telugu:
            'లాగిన్, ఖాతా భద్రత, ప్రాంతీయ భాష అనుకూలత, కమ్యూనిటీ అప్‌లోడ్‌లు మరియు పోస్టర్ వ్యక్తిగతీకరణ కోసం మేము ఈ డేటాను ఉపయోగిస్తాము.',
        english:
            'We use this data for login, account security, region-based language adaptation, community uploads, and poster personalization workflows.',
        hindi:
            'हम इस डेटा का उपयोग लॉगिन, खाता सुरक्षा, क्षेत्रीय भाषा अनुकूलन, कम्युनिटी अपलोड और पोस्टर वैयक्तिकरण के लिए करते हैं।',
        tamil:
            'உள்நுழைவு, கணக்கு பாதுகாப்பு, பிராந்திய மொழி அமைப்புகள், சமூக பதிவேற்றங்கள் மற்றும் போஸ்டர் தனிப்பயனாக்கலுக்கு இந்தத் தரவைப் பயன்படுத்துகிறோம்.',
        kannada:
            'ಲಾಗಿನ್, ಖಾತೆ ಭದ್ರತೆ, ಪ್ರಾದೇಶಿಕ ಭಾಷೆ ಹೊಂದಾಣಿಕೆ, ಸಮುದಾಯ ಅಪ್‌ಲೋಡ್‌ಗಳು ಮತ್ತು ಪೋಸ್ಟರ್ ವೈಯಕ್ತೀಕರಣಕ್ಕಾಗಿ ನಾವು ಈ ಡೇಟಾವನ್ನು ಬಳಸುತ್ತೇವೆ.',
        malayalam:
            'ലോഗിൻ, അക്കൗണ്ട് സുരക്ഷ, പ്രാദേശിക ഭാഷാ മാറ്റങ്ങൾ, കമ്മ്യൂണിറ്റി അപ്‌ലോഡുകൾ, പോസ്റ്റർ നിർമ്മാണം എന്നിവയ്ക്കായി ഞങ്ങൾ ഈ ഡാറ്റ ഉപയോഗിക്കുന്നു.',
        marathi:
            'आम्ही हा डेटा लॉगिन, खाते सुरक्षा, प्रादेशिक भाषा अनुकूलन, कम्युनिटी अपलोड आणि पोस्टर कस्टमायझेशनसाठी वापरतो.',
        gujarati:
            'અમે આ ડેટાનો ઉપયોગ લૉગિન, એકાઉન્ટ સુરક્ષા, પ્રાદેશિક ભાષા અનુકૂલન, કમ્યુનિટી અપલોડ અને પોસ્ટર પર્સનલાઇઝેશન માટે કરીએ છીએ.',
        bengali:
            'আমরা লগইন, অ্যাকাউন্টের নিরাপত্তা, আঞ্চলিক ভাষার অভিযোজন, কমিউনিটি আপলোড এবং পোস্টার কাস্টমাইজেশনের জন্য এই তথ্য ব্যবহার করি।',
        punjabi:
            'ਅਸੀਂ ਇਸ ਡੇਟਾ ਦੀ ਵਰਤੋਂ ਲੌਗਇਨ, ਖਾਤਾ ਸੁਰੱਖਿਆ, ਖੇਤਰੀ ਭਾਸ਼ਾ ਅਨੁਕੂਲਤਾ, ਕਮਿਊਨਿਟੀ ਅੱਪਲੋਡ ਅਤੇ ਪੋਸਟਰ ਨਿੱਜੀਕਰਨ ਲਈ ਕਰਦੇ ਹਾਂ।',
        odia:
            'ଆମେ ଲଗଇନ୍, ଆକାଉଣ୍ଟ୍ ସୁରକ୍ଷା, ଆଞ୍ଚଳିକ ଭାଷା ଅନୁକୂଳତା, କମ୍ୟୁନିଟି ଅପଲୋଡ୍ ଏବଂ ପୋଷ୍ଟର ବ୍ୟକ୍ତିଗତକରଣ ପାଇଁ ଏହି ଡାଟା ବ୍ୟବହାର କରୁ।',
        assamese:
            'আমি লগইন, একাউণ্টৰ সুৰক্ষা, আঞ্চলিক ভাষা অভিযোজন, সম্প্ৰদায় আপলোড আৰু পোষ্টাৰ কাষ্টমাইজেচনৰ বাবে এই তথ্য ব্যৱহাৰ কৰোঁ।',
        konkani:
            'ಲಾಗ್ ಇನ್, ಖಾತೆಂ ಸುರಕ್ಷಾ, ಭಾಸ್ ಬದ್ಲಾವಣ್, ಕಮ್ಯುನಿಟಿ ಅಪ್‌ಲೋಡ್ ಆನಿ ಪೋಸ್ಟರ್ ಕಸ್ಟಮೈಜೇಶನಾಕ್ ಆಮಿ ಹೊ ಡೇಟಾ ವಾಪರ್ತಾಂವ್.',
        nepali:
            'हामी लगइन, खाता सुरक्षा, क्षेत्रीय भाषा अनुकूलन, समुदाय अपलोड र पोस्टर निजीकरणका लागि यो डाटा प्रयोग गर्छौं।',
        meitei:
            'লগইন, একাউন্ত সেক্যুরিতি, রিজনেল লোল ওনবা, কম্যুনিতি অপলোদশিং অমসুং পোস্তর শেম্বদা ঐখোয়না দেতা অসি শীজিন্নৈ।',
        mizo:
            'Login, account venhimna, bial tawng mil zela inthlakna, community uploads leh poster siamna atan he data hi kan hmang.',
        kashmiri:
            'أسی چھِ یہِ ڈیٹا لاگ اِن، کھاتہٕ حِفاظَت، علاقٲیی زبان، تہٕ پوسٹر کسٹمائز کَرنہٕ باپتھ اِستعمال کَران۔',
        ladakhi:
            'ང་ཚོས་ནང་འཛུལ། ཐོ་ཁའི་བདེ་འཇགས། ས་གནས་སྐད་རིགས། མི་སྡེའི་ཡར་འཇུག་དང་པོསྚར་བཟོ་བའི་ཆེད་དུ་གྲངས་གཞི་འདི་སྤྱོད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ప్రాంతం, భాష మరియు రాజకీయ కేటగిరీ ఎంపికలు',
        english: 'Region, Language, and Political Category Choices',
        hindi: 'क्षेत्र, भाषा और राजनीतिक श्रेणी के विकल्प',
        tamil: 'பிராந்தியம், மொழி மற்றும் அரசியல் பிரிவு தேர்வுகள்',
        kannada: 'ಪ್ರದೇಶ, ಭಾಷೆ ಮತ್ತು ರಾಜಕೀಯ ವರ್ಗ ಆಯ್ಕೆಗಳು',
        malayalam: 'പ്രദേശം, ഭാഷ, രാഷ്ട്രീയ വിഭാഗ തെരഞ്ഞെടുപ്പുകൾ',
        marathi: 'प्रदेश, भाषा आणि राजकीय श्रेणी निवडी',
        gujarati: 'પ્રદેશ, ભાષા અને રાજકીય શ્રેણી વિકલ્પો',
        bengali: 'অঞ্চল, ভাষা এবং রাজনৈতিক বিভাগের পছন্দ',
        punjabi: 'ਖੇਤਰ, ਭਾਸ਼ਾ ਅਤੇ ਸਿਆਸੀ ਸ਼੍ਰੇਣੀ ਚੋਣਾਂ',
        odia: 'ଅଞ୍ଚଳ, ଭାଷା ଏବଂ ରାଜନୈତିକ ବିଭାଗ ପସନ୍ଦ',
        assamese: 'অঞ্চল, ভাষা আৰু ৰাজনৈতিক শ্ৰেণীৰ পছন্দসমূহ',
        konkani: 'ಪ್ರದೇಶ್, ಭಾಸ್ ಆನಿ ರಾಜಕೀಯ್ ವರ್ಗಾಂಚಿ ವಿಂಚವ್ಣ್',
        nepali: 'क्षेत्र, भाषा र राजनीतिक श्रेणी छनोटहरू',
        meitei: 'রিজন, লোল অমসুং পোলিতিকেল কেটাগোরিগী অপাম্বশিং',
        mizo: 'Bial, tawng leh political category thlante',
        kashmiri: 'علاقہٕ، زبان تہٕ سیٲسی زمرٕ اِنتخابات',
        ladakhi: 'ས་གནས། སྐད་རིགས་དང་སྲིད་དོན་དབྱེ་བའི་འདེམས་ཁ།',
      ),
      strings.localized(
        telugu:
            'రాష్ట్రం లేదా కేంద్రపాలిత ప్రాంతాన్ని ఎంచుకున్నప్పుడు, యాప్ సంబంధిత ప్రాంతీయ భాషను మరియు రాజకీయ పార్టీ కేటగిరీలను వర్తింపజేస్తుంది. మీ అనుభవాన్ని మెరుగుపరచడానికి ఈ ఎంపికలు భద్రపరచబడతాయి.',
        english:
            'When you select a State or Union Territory, the app may apply the matching regional language and show relevant categories, including regional political party categories. These selections are stored to personalize your app experience.',
        hindi:
            'जब आप कोई राज्य या केंद्र शासित प्रदेश चुनते हैं, तो ऐप संबंधित क्षेत्रीय भाषा और राजनीतिक दल श्रेणियों को लागू कर सकता है।',
        tamil:
            'மாநிலம் அல்லது யூனியன் பிரதேசத்தைத் தேர்ந்தெடுக்கும்போது, செயலி பிராந்திய மொழி மற்றும் அரசியல் கட்சி பிரிவுகளைப் பயன்படுத்தலாம்.',
        kannada:
            'ರಾಜ್ಯ ಅಥವಾ ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶವನ್ನು ಆಯ್ಕೆ ಮಾಡಿದಾಗ, ಆ್ಯಪ್ ಪ್ರಾದೇಶಿಕ ಭಾಷೆ ಮತ್ತು ರಾಜಕೀಯ ಪಕ್ಷದ ವರ್ಗಗಳನ್ನು ತೋರಿಸುತ್ತದೆ.',
        malayalam:
            'സംസ്ഥാനമോ കേന്ദ്രഭരണ പ്രദേശമോ തിരഞ്ഞെടുക്കുമ്പോൾ, ആപ്പ് അനുയോജ്യമായ പ്രാദേശിക ഭാഷയും രാഷ്ട്രീയ വിഭാഗങ്ങളും നൽകുന്നു.',
        marathi:
            'जेव्हा तुम्ही राज्य किंवा केंद्रशासित प्रदेश निवडता, तेव्हा अ‍ॅप प्रादेशिक भाषा आणि राजकीय पक्ष श्रेणी लागू करू शकते.',
        gujarati:
            'જ્યારે તમે રાજ્ય અથવા કેન્દ્રશાસિત પ્રદેશ પસંદ કરો છો, ત્યારે એપ મેળ ખાતી પ્રાદેશિક ભાષા અને રાજકીય પક્ષ શ્રેણીઓ લાગુ કરી શકે છે.',
        bengali:
            'আপনি যখন রাজ্য বা কেন্দ্রশাসিত অঞ্চল নির্বাচন করেন, তখন অ্যাপটি আঞ্চলিক ভাষা এবং রাজনৈতিক দলের বিভাগ প্রয়োগ করতে পারে।',
        punjabi:
            'ਜਦੋਂ ਤੁਸੀਂ ਕੋਈ ਰਾਜ ਜਾਂ ਕੇਂਦਰ ਸ਼ਾਸਿਤ ਪ੍ਰਦੇਸ਼ ਚੁਣਦੇ ਹੋ, ਤਾਂ ਐਪ ਖੇਤਰੀ ਭਾਸ਼ਾ ਅਤੇ ਸਿਆਸੀ ਪਾਰਟੀ ਸ਼੍ਰੇਣੀਆਂ ਲਾਗੂ ਕਰ ਸਕਦੀ ਹੈ।',
        odia:
            'ଯେତେବେଳେ ଆପଣ ଏକ ରାଜ୍ୟ ବା କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ ବାଛନ୍ତି, ଆପ୍ ଆଞ୍ଚଳିକ ଭାଷା ଏବଂ ରାଜନୈତିକ ଦଳ ବିଭାଗ ଲାଗୁ କରିପାରେ।',
        assamese:
            'যেতিয়া আপুনি কোনো ৰাজ্য বা কেন্দ্ৰীয় শাসিত অঞ্চল বাছনি কৰে, এপে আঞ্চলিক ভাষা আৰু ৰাজনৈতিক দলৰ শ্ৰেণী প্ৰয়োগ কৰিব পাৰে।',
        konkani:
            'ರಾಜ್ಯ್ ಯಾ ಕೇಂದ್ರ ಶಾಸಿತ್ ಪ್ರದೇಶ್ ವಿಂಚ್ಲ್ಯಾರ್, ಆ್ಯಪ್ ಪ್ರಾದೇಶಿಕ್ ಭಾಸ್ ಆನಿ ರಾಜಕೀಯ್ ಪಕ್ಷಾಂಚೆ ವರ್ಗಾಂ ದಾಕಂವ್ಕ್ ಸಕ್ತಾ.',
        nepali:
            'जब तपाईं राज्य वा केन्द्रशासित प्रदेश चयन गर्नुहुन्छ, एपले सम्बन्धित क्षेत्रीय भाषा र राजनीतिक दल कोटिहरू लागू गर्न सक्छ।',
        meitei:
            'স্তেত নত্রগা য়ুনিয়ন তেরিতোরি খনবা মতমদা, এপ অসিনা মফমদুগী লোল অমসুং পোলিতিকেল পার্তিগী কেটাগোরিশিং চৎনহনবা য়াই।',
        mizo:
            'State emaw UT i thlan hian, app hian chumi bial tawng leh political party category-te a tilang thei.',
        kashmiri:
            'رِیاسَت یا مرکز کِس زیرِ اِنتظام علاقَس ژارنہٕ وِزِ ہیکہِ ایپھ علاقٲیی زبان تہٕ سیٲسی زمرٕ لاگوٗ کٔرِتھ۔',
        ladakhi:
            'མངའ་སྡེའམ་དབུས་གཞུང་ཁྱབ་ཁོངས་བདམས་སྐབས། ཨེཔ་དེས་འབྲེལ་ཡོད་ས་གནས་སྐད་རིགས་དང་སྲིད་དོན་ཚོགས་པའི་དབྱེ་བ་རྣམས་སྟོན་ཐུབ།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'కమ్యూనిటీ అప్‌లోడ్‌లు మరియు సమీక్ష',
        english: 'Community Uploads and Review',
        hindi: 'कम्युनिटी अपलोड और समीक्षा',
        tamil: 'சமூக பதிவேற்றங்கள் மற்றும் மதிப்பாய்வு',
        kannada: 'ಸಮುದಾಯ ಅಪ್‌ಲೋಡ್‌ಗಳು ಮತ್ತು ಪರಿಶೀಲನೆ',
        malayalam: 'കമ്മ്യൂണിറ്റി അപ്‌ലോഡുകളും പരിശോധനയും',
        marathi: 'कम्युनिटी अपलोड आणि पुनरावलोकन',
        gujarati: 'કમ્યુનિટી અપલોડ્સ અને સમીક્ષા',
        bengali: 'কমিউনিটি আপলোড এবং পর্যালোচনা',
        punjabi: 'ਕਮਿਊਨਿਟੀ ਅੱਪਲੋਡ ਅਤੇ ਸਮੀਖਿਆ',
        odia: 'କମ୍ୟୁନିଟି ଅପଲୋଡ୍ ଏବଂ ସମୀକ୍ଷା',
        assamese: 'সম্প্ৰদায় আপলোড আৰু পৰ্যালোচনা',
        konkani: 'ಕಮ್ಯುನಿಟಿ ಅಪ್‌ಲೋಡ್ಸ್ ಆನಿ ತಪಾಸ್ಣಿ',
        nepali: 'समुदाय अपलोड र समीक्षा',
        meitei: 'কম্যুনিতি অপলোদশিং অমসুং রিভ্যু',
        mizo: 'Community uploads leh endikna',
        kashmiri: 'کمیونٹی اَپلوڈ تہٕ ریویو',
        ladakhi: 'མི་སྡེའི་ཡར་འཇུག་དང་ཞིབ་བཤེར།',
      ),
      strings.localized(
        telugu:
            'వినియోగదారులు మేనేజర్ సమీక్ష కోసం ఇమేజ్ లేదా కొటేషన్‌ను పంపవచ్చు. సమర్పించిన కంటెంట్ సమీక్షించబడి, ఆమోదించబడి లేదా తిరస్కరించబడవచ్చు. మీకు హక్కు ఉన్న కంటెంట్‌ను మాత్రమే సమర్పించండి.',
        english:
            'Users may submit an image, quote text, or both for manager review. Submitted content may be reviewed, edited, approved, rejected, or published into app categories. Please submit only content you have the right to share.',
        hindi:
            'उपयोगकर्ता प्रबंधक समीक्षा के लिए छवि या उद्धरण भेज सकते हैं। कृपया केवल वही सामग्री सबमिट करें जिसे साझा करने का आपको अधिकार है।',
        tamil:
            'பயனர்கள் மதிப்பாய்வுக்காக படம் அல்லது மேற்கோளை சமர்ப்பிக்கலாம். உங்களுக்கு உரிமை உள்ள உள்ளடக்கத்தை மட்டுமே சமர்ப்பிக்கவும்.',
        kannada:
            'ಬಳಕೆದಾರರು ಪರಿಶೀಲನೆಗಾಗಿ ಚಿತ್ರ ಅಥವಾ ಉಲ್ಲೇಖವನ್ನು ಸಲ್ಲಿಸಬಹುದು. ಹಂಚಿಕೊಳ್ಳಲು ನಿಮಗೆ ಹಕ್ಕಿರುವ ವಿಷಯವನ್ನು ಮಾತ್ರ ಸಲ್ಲಿಸಿ.',
        malayalam:
            'ഉപയോക്താക്കൾക്ക് പരിശോധനയ്ക്കായി ചിത്രമോ ഉദ്ധരണിയോ സമർപ്പിക്കാം. പങ്കിടാൻ അവകാശമുള്ള ഉള്ളടക്കം മാത്രം നൽകുക.',
        marathi:
            'वापरकर्ते पुनरावलोकनासाठी प्रतिमा किंवा कोट पाठवू शकतात. कृपया केवळ अशी सामग्री सबमिट करा जी शेअर करण्याचा तुम्हाला अधिकार आहे.',
        gujarati:
            'વપરાશકર્તાઓ સમીક્ષા માટે છબી અથવા ક્વોટ સબમિટ કરી શકે છે. કૃપા કરીને ફક્ત એવી સામગ્રી સબમિટ કરો જે શેર કરવાનો તમને અધિકાર છે.',
        bengali:
            'ব্যবহারকারীরা পর্যালোচনার জন্য ছবি বা উদ্ধৃতি জমা দিতে পারেন। অনুগ্রহ করে কেবল সেই সামগ্রী জমা দিন যা ভাগ করার অধিকার আপনার আছে।',
        punjabi:
            'ਵਰਤੋਂਕਾਰ ਸਮੀਖਿਆ ਲਈ ਤਸਵੀਰ ਜਾਂ ਵਿਚਾਰ ਜਮ੍ਹਾਂ ਕਰ ਸਕਦੇ ਹਨ। ਕਿਰਪਾ ਕਰਕੇ ਸਿਰਫ਼ ਉਹੀ ਸਮੱਗਰੀ ਜਮ੍ਹਾਂ ਕਰੋ ਜਿਸਨੂੰ ਸਾਂਝਾ ਕਰਨ ਦਾ ਤੁਹਾਡੇ ਕੋਲ ਅਧਿਕਾਰ ਹੈ।',
        odia:
            'ବ୍ୟବହାରକାରୀମାନେ ସମୀକ୍ଷା ପାଇଁ ଫଟୋ ବା ଉଦ୍ଧୃତି ଦାଖଲ କରିପାରିବେ। ଦୟାକରି କେବଳ ସେହି ବିଷୟବସ୍ତୁ ଦାଖଲ କରନ୍ତୁ ଯାହାକୁ ସେୟାର କରିବାର ଅଧିକାର ଆପଣଙ୍କର ଅଛି।',
        assamese:
            'ব্যৱহাৰকাৰীসকলে পৰ্যালোচনাৰ বাবে ছবি বা উদ্ধৃতি জমা দিব পাৰে। অনুগ্ৰহ কৰি কেৱল আপোনাৰ অধিকাৰ থকা বিষয়বস্তুহে জমা দিব।',
        konkani:
            'ಬಳಕೆದಾರ್ ತಪಾಸ್ಣೆಕ್ ಫೋಟೋ ಯಾ ಕೋಟ್ ಧಾಡುಂಕ್ ಸಕ್ತಾತ್. ಶೇರ್ ಕರುಂಕ್ ಹಕ್ಕ್ ಆಸ್ಚೆಂ ಮಾತ್ರ್ ಧಾಡಾ.',
        nepali:
            'प्रयोगकर्ताहरूले समीक्षाको लागि छवि वा उद्धरण पेश गर्न सक्छन्। कृपया आफूलाई साझा गर्ने अधिकार भएको सामग्री मात्र पेश गर्नुहोस्।',
        meitei:
            'য়ুজরশিংনা রিভ্যুগীদমক মমি নত্রগা কোত থাবা য়াই। চানবীদুনা নহাক্না শিয়র তৌবগী হক লৈবা কন্তেন্তখক থাবীয়ু।',
        mizo:
            'Endik turin thlalak emaw thuziak thehluh theih a ni. Thehdarh tura dikna i neih chauh thehlut ang che.',
        kashmiri:
            'صارِف ہؠکن ریویو باپتھ تصویر یا اَقوال سوزِتھ۔ مہربٲنی کٔرِتھ سوزِو صرف سۄے مواد یَتھ شیئر کَرنُک تُہؠ اِختیار چھُ۔',
        ladakhi:
            'སྤྱོད་པ་པོ་རྣམས་ཀྱིས་ཞིབ་བཤེར་དོན་དུ་འདྲ་པར་རམ་ཚིག་དུམ་གཏོང་ཐུབ། རང་ཉིད་ལ་བརྒྱུད་སྤེལ་བྱེད་པའི་ཐོབ་ཐང་ཡོད་པ་ཁོ་ན་གཏོང་རོགས།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఫైర్‌బేస్, అనలిటిక్స్ మరియు ప్రకటనలు',
        english: 'Firebase, Analytics, and Ads',
        hindi: 'फ़ायरबेस, एनालिटिक्स और विज्ञापन',
        tamil: 'ஃபயர்பேஸ், அனலிட்டிக்ஸ் மற்றும் விளம்பரங்கள்',
        kannada: 'ಫೈರ್‌ಬೇಸ್, ಅನಾಲಿಟಿಕ್ಸ್ ಮತ್ತು ಜಾಹೀರಾತುಗಳು',
        malayalam: 'ഫയർബേസ്, അനലിറ്റിക്സ്, പരസ്യങ്ങൾ',
        marathi: 'फायरबेस, अ‍ॅनालिटिक्स आणि जाहिराती',
        gujarati: 'ફાયરબેઝ, એનાલિટિક્સ અને જાહેરાતો',
        bengali: 'ফায়ারবেস, অ্যানালিটিক্স এবং বিজ্ঞাপন',
        punjabi: 'ਫਾਇਰਬੇਸ, ਵਿਸ਼ਲੇਸ਼ਣ ਅਤੇ ਇਸ਼ਤਿਹਾਰ',
        odia: 'ଫାୟାରବେସ୍, ଆନାଲିଟିକ୍ସ ଏବଂ ବିଜ୍ଞାପନ',
        assamese: 'ফায়াৰবেছ, বিশ্লেষণ আৰু বিজ্ঞাপন',
        konkani: 'ಫೈರ್‌ಬೇಸ್, ಅನಲಿಟಿಕ್ಸ್ ಆನಿ ಜಾಹಿರಾತಾಂ',
        nepali: 'फायरबेस, एनालिटिक्स र विज्ञापनहरू',
        meitei: 'ফায়ারবেস, এনেলিতিক্স অমসুং এদভর্তাইজমেন্তশিং',
        mizo: 'Firebase, Analytics leh Ads',
        kashmiri: 'فائر بیس، اینالیٹکس تہٕ اشتہارات',
        ladakhi: 'ཕའེར་བེས། དབྱེ་ཞིབ་དང་ཁྱབ་བསྒྲགས།',
      ),
      strings.localized(
        telugu:
            'ఈ యాప్ Firebase ప్రమాణీకరణ, డేటాబేస్, నిల్వ మరియు క్రాష్ రిపోర్టింగ్‌ను ఉపయోగిస్తుంది. మేము AdMob ప్రకటనలను కూడా ప్రదర్శించవచ్చు.',
        english:
            'The app uses Firebase Authentication, Firestore, Storage, Messaging, and Crashlytics. We may also display AdMob ads, including rewarded ads that can unlock extra features.',
        hindi:
            'ऐप Firebase प्रमाणीकरण, Firestore, संग्रहण और Crashlytics का उपयोग करता है। हम अतिरिक्त सुविधाओं को अनलॉक करने वाले AdMob विज्ञापन भी प्रदर्शित कर सकते हैं।',
        tamil:
            'செயலி Firebase அங்கீகாரம், தரவுத்தளம் மற்றும் Crashlytics ஐப் பயன்படுத்துகிறது. கூடுதல் அம்சங்களை இயக்க AdMob விளம்பரங்களையும் நாங்கள் காட்டலாம்.',
        kannada:
            'ಆ್ಯಪ್ Firebase ದೃಢೀಕರಣ, Firestore ಮತ್ತು Crashlytics ಬಳಸುತ್ತದೆ. ಹೆಚ್ಚುವರಿ ವೈಶಿಷ್ಟ್ಯಗಳನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡುವ AdMob ಜಾಹೀರಾತುಗಳನ್ನು ನಾವು ತೋರಿಸಬಹುದು.',
        malayalam:
            'ആപ്പ് ഫയർബേസ് ഓതന്റിക്കേഷൻ, ഫയർസ്റ്റോർ, ക്രാഷ്‌ലിറ്റിക്സ് എന്നിവ ഉപയോഗിക്കുന്നു. അധിക ഫീച്ചറുകൾക്കായി ആഡ്‌മോബ് പരസ്യങ്ങളും കാണിച്ചേക്കാം.',
        marathi:
            'अ‍ॅप Firebase प्रमाणीकरण, Firestore, स्टोरेज आणि Crashlytics वापरते. अतिरिक्त वैशिष्ट्ये अनलॉक करण्यासाठी आम्ही AdMob जाहिराती देखील दाखवू शकतो.',
        gujarati:
            'એપ Firebase પ્રમાણીકરણ, Firestore અને Crashlytics નો ઉપયોગ કરે છે. વધારાની સુવિધાઓ માટે અમે AdMob જાહેરાતો પણ પ્રદર્શિત કરી શકીએ છીએ.',
        bengali:
            'অ্যাপটি Firebase প্রমাণীকরণ, Firestore এবং Crashlytics ব্যবহার করে। অতিরিক্ত সুবিধা আনলক করতে আমরা AdMob বিজ্ঞাপনও প্রদর্শন করতে পারি।',
        punjabi:
            'ਐਪ Firebase ਪ੍ਰਮਾਣੀਕਰਨ, Firestore ਅਤੇ Crashlytics ਦੀ ਵਰਤੋਂ ਕਰਦੀ ਹੈ। ਵਾਧੂ ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ ਲਈ ਅਸੀਂ AdMob ਇਸ਼ਤਿਹਾਰ ਵੀ ਦਿਖਾ ਸਕਦੇ ਹਾਂ।',
        odia:
            'ଆପ୍ Firebase ପ୍ରମାଣୀକରଣ, Firestore ଏବଂ Crashlytics ବ୍ୟବହାର କରେ। ଅତିରିକ୍ତ ସୁବିଧା ପାଇଁ ଆମେ AdMob ବିଜ୍ଞାପନ ମଧ୍ୟ ଦେଖାଇପାରୁ।',
        assamese:
            'এপে Firebase প্ৰমাণীকৰণ, Firestore আৰু Crashlytics ব্যৱহাৰ কৰে। অতিৰিক্ত সুবিধাৰ বাবে আমি AdMob বিজ্ঞাপনো প্ৰদৰ্শন কৰিব পাৰোঁ।',
        konkani:
            'ಆ್ಯಪ್ Firebase ಅಥೆಂಟಿಕೇಶನ್, Firestore ಆನಿ Crashlytics ವಾಪರ್ತಾ. ಚಡ್ ವೈಶಿಷ್ಟ್ಯಾಂಕ್ ಆಮಿ AdMob ಜಾಹಿರಾತಾಂಯ್ ದಾಕಂವ್ಕ್ ಸಕ್ Rozಾಂವ್.',
        nepali:
            'एपले Firebase प्रमाणीकरण, Firestore र Crashlytics प्रयोग गर्दछ। हामी अतिरिक्त सुविधाहरू अनलक गर्न AdMob विज्ञापनहरू पनि देखाउन सक्छौं।',
        meitei:
            'এপ অসিনা Firebase Authentication, Firestore অমসুং Crashlytics শীজিন্নৈ। ঐখোয়না অহেনবা ফীচরশিং হৌদোক্নবা AdMob এদশিং উৎপা য়াই।',
        mizo:
            'App hian Firebase Authentication, Firestore leh Crashlytics a hmang. Feature thar hawn theihna turin AdMob ads kan tilang thei bawk.',
        kashmiri:
            'ایپھ چھُ Firebase تصدیق، Firestore تہٕ Crashlytics اِستعمال کَران। أسی ہیکو اِضافی خَصوصِیات باپتھ AdMob اشتہارات تہِ ہٲوِتھ۔',
        ladakhi:
            'ཨེཔ་འདིས་ Firebase བདེན་དཔང་། Firestore དང་ Crashlytics སྤྱོད། ང་ཚོས་ཁྱད་ཆོས་གཞན་དག་འབྱེད་པའི་ཆེད་ AdMob ཁྱབ་བསྒྲགས་ཀྱང་སྟོན་སྲིད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'డేటా భాగస్వామ్యం',
        english: 'Data Sharing',
        hindi: 'डेटा साझा करना',
        tamil: 'தரவு பகிர்வு',
        kannada: 'ಡೇಟಾ ಹಂಚಿಕೆ',
        malayalam: 'ഡാറ്റ പങ്കിടൽ',
        marathi: 'डेटा शेअरिंग',
        gujarati: 'ડેટા શેરિંગ',
        bengali: 'তথ্য ভাগ করে নেওয়া',
        punjabi: 'ਡੇਟਾ ਸਾਂਝਾਕਰਨ',
        odia: 'ଡାଟା ସେୟାରିଂ',
        assamese: 'তথ্য ভাগ-বতৰা',
        konkani: 'ಡೇಟಾ ಶೇರಿಂಗ್',
        nepali: 'डाटा साझेदारी',
        meitei: 'দেতা শিয়র তৌবা',
        mizo: 'Data thehdarh dan',
        kashmiri: 'ڈیٹا شیئر کَرُن',
        ladakhi: 'གྲངས་གཞི་བརྒྱུད་སྤེལ།',
      ),
      strings.localized(
        telugu:
            'మేము వ్యక్తిగత డేటాను విక్రయించము. యాప్‌ను నిర్వహించడానికి Firebase, Google Play మరియు ప్రకటన భాగస్వాములతో మాత్రమే అవసరమైన మేరకు డేటా పంచుకోబడుతుంది.',
        english:
            'We do not sell personal data. Data may be shared only with essential service providers like Firebase, Google Play Billing, and ad networks as required to operate the app.',
        hindi:
            'हम व्यक्तिगत डेटा नहीं बेचते हैं। ऐप संचालित करने के लिए केवल Firebase, Google Play और विज्ञापन नेटवर्क जैसे आवश्यक सेवा प्रदाताओं के साथ डेटा साझा किया जा सकता है।',
        tamil:
            'தனிப்பட்ட தரவை நாங்கள் விற்பதில்லை. செயலியை இயக்க தேவையான இடங்களில் மட்டுமே சேவை வழங்குநர்களுடன் தரவு பகிரப்படுகிறது.',
        kannada:
            'ನಾವು ವೈಯಕ್ತಿಕ ಡೇಟಾವನ್ನು ಮಾರಾಟ ಮಾಡುವುದಿಲ್ಲ. ಆ್ಯಪ್ ಕಾರ್ಯನಿರ್ವಹಿಸಲು ಅಗತ್ಯವಿರುವ ಸೇವಾ ಪೂರೈಕೆದಾರರೊಂದಿಗೆ ಮಾತ್ರ ಡೇಟಾ ಹಂಚಿಕೊಳ್ಳಲಾಗುತ್ತದೆ.',
        malayalam:
            'ഞങ്ങൾ വ്യക്തിഗത ഡാറ്റ വിൽക്കില്ല. ആപ്പ് പ്രവർത്തിപ്പിക്കുന്നതിന് ആവശ്യമായ സേവന ദാതാക്കളുമായി മാത്രമേ ഡാറ്റ പങ്കിടൂ.',
        marathi:
            'आम्ही वैयक्तिक डेटा विकत नाही. केवळ अ‍ॅप चालवण्यासाठी आवश्यक असलेल्या सेवा प्रदात्यांसोबतच डेटा शेअर केला जाऊ शकतो.',
        gujarati:
            'અમે વ્યક્તિગત ડેટા વેચતા નથી. ફક્ત એપ ચલાવવા માટે જરૂરી સેવા પ્રદાતાઓ સાથે જ ડેટા શેર કરવામાં આવે છે.',
        bengali:
            'আমরা ব্যক্তিগত তথ্য বিক্রি করি না। অ্যাপ পরিচালনার জন্য প্রয়োজনীয় পরিষেবা প্রদানকারীদের সাথেই কেবল তথ্য ভাগ করা হতে পারে।',
        punjabi:
            'ਅਸੀਂ ਨਿੱਜੀ ਡੇਟਾ ਨਹੀਂ ਵੇਚਦੇ। ਸਿਰਫ਼ ਐਪ ਚਲਾਉਣ ਲਈ ਲੋੜੀਂਦੇ ਸੇਵਾ ਪ੍ਰਦਾਤਾਵਾਂ ਨਾਲ ਹੀ ਡੇਟਾ ਸਾਂਝਾ ਕੀਤਾ ਜਾਂਦਾ ਹੈ।',
        odia:
            'ଆମେ ବ୍ୟକ୍ତିଗତ ଡାଟା ବିକ୍ରୟ କରୁନାହୁଁ। କେବଳ ଆପ୍ ଚଳାଇବା ପାଇଁ ଆବଶ୍ୟକ ସେବା ପ୍ରଦାନକାରୀଙ୍କ ସହିତ ଡାଟା ସେୟାର କରାଯାଇପାରେ।',
        assamese:
            'আমি ব্যক্তিগত তথ্য বিক্ৰী নকৰোঁ। কেৱল এপটো চলাবলৈ প্ৰয়োজনীয় সেৱা প্ৰদানকাৰীৰ সৈতেহে তথ্য ভাগ কৰা হʼব পাৰে।',
        konkani:
            'ಆಮಿ ಖಾಸ್ಗಿ ಡೇಟಾ ವಿಕ್ನಾಂವ್. ಆ್ಯಪ್ ಚಲಂವ್ಕ್ ಗರ್ಜೆಚ್ಯಾ ಸರ್ವಿಸ್ ಪ್ರೊವೈಡರ್ಸ್ ಸಾಂಗಾತಾ ಮಾತ್ರ್ ಡೇಟಾ ಶೇರ್ ಜಾತಾ.',
        nepali:
            'हामी व्यक्तिगत डाटा बेच्दैनौं। केवल एप सञ्चालन गर्न आवश्यक सेवा प्रदायकहरूसँग मात्र डाटा साझा गर्न सकिन्छ।',
        meitei:
            'ঐখোয়না মীওই অমগী মশাগী দেতা য়োল্লোই। এপ অসি চলাইবদা তঙাইফদবা সর্ভিস প্রোভাইদরশিংগা খক্তমক দেতা শিয়র তৌবা য়াই।',
        mizo:
            'Mimal data kan hralh ngai lo. App enkawl nana tul service provider-te hnenah chauh data hi thehdarh theih a ni.',
        kashmiri:
            'أسی چھِ نہٕ ذٲتی ڈیٹا کٕنان۔ صِرَف ایپھ چلاونہٕ باپتھ ضروٗری سٔروِس پرووایڈَرَن سٟتؠ چھُ ڈیٹا شیئر یِوان کَرنہٕ۔',
        ladakhi:
            'ང་ཚོས་སྒེར་གྱི་གྲངས་གཞི་མི་འཚོང་། ཨེཔ་འདི་གཉེར་སྐྱོང་བྱེད་པར་མཁོ་བའི་ཞབས་ཞུ་སྤྲོད་མཁན་རྣམས་དང་ལྷན་དུ་མ་གཏོགས་གྲངས་གཞི་བརྒྱུད་སྤེལ་མི་བྱེད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'పిల్లల గోప్యత',
        english: 'Children\'s Privacy',
        hindi: 'बच्चों की गोपनीयता',
        tamil: 'குழந்தைகளின் தனியுரிமை',
        kannada: 'ಮಕ್ಕಳ ಗೌಪ್ಯತೆ',
        malayalam: 'കുട്ടികളുടെ സ്വകാര്യത',
        marathi: 'मुलांची गोपनीयता',
        gujarati: 'બાળકોની ગોપનીયતા',
        bengali: 'শিশুদের গোপনীয়তা',
        punjabi: 'ਬੱਚਿਆਂ ਦੀ ਗੋਪਨੀਯਤਾ',
        odia: 'ପିଲାମାନଙ୍କ ଗୋପନୀୟତା',
        assamese: 'শিশুসকলৰ গোপনীয়তা',
        konkani: 'ಭುರ್ಗ್ಯಾಂಚಿ ಗೌಪ್ಯತಾ',
        nepali: 'बालबालिकाको गोपनीयता',
        meitei: 'অঙাংগী প্রাইভেসি',
        mizo: 'Naupangte venhimna',
        kashmiri: 'شُرؠن ہٕنٛز رازدٲری',
        ladakhi: 'བྱིས་པའི་གསང་རྒྱ།',
      ),
      strings.localized(
        telugu:
            'ఈ యాప్ 13 సంవత్సరాల లోపు పిల్లల కోసం ఉద్దేశించినది కాదు. మేము వారి వ్యక్తిగత సమాచారాన్ని ఉద్దేశపూర్వకంగా సేకరించము.',
        english:
            'This app is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13.',
        hindi:
            'यह ऐप 13 वर्ष से कम उम्र के बच्चों के लिए नहीं है। हम 13 वर्ष से कम उम्र के बच्चों से जानबूझकर व्यक्तिगत जानकारी एकत्र नहीं करते हैं।',
        tamil:
            'இந்த செயலி 13 வயதுக்குட்பட்ட குழந்தைகளுக்கானது அல்ல. நாங்கள் அவர்களின் தகவல்களைத் தெரிந்தே சேகரிப்பதில்லை.',
        kannada:
            'ಈ ಆ್ಯಪ್ 13 ವರ್ಷದೊಳಗಿನ ಮಕ್ಕಳಿಗೆ ಉದ್ದೇಶಿಸಿಲ್ಲ. ನಾವು ಅವರ ಮಾಹಿತಿಯನ್ನು ಉದ್ದೇಶಪೂರ್ವಕವಾಗಿ ಸಂಗ್ರಹಿಸುವುದಿಲ್ಲ.',
        malayalam:
            'ഈ ആപ്പ് 13 വയസ്സിന് താഴെയുള്ള കുട്ടികൾക്കായി ഉദ്ദേശിച്ചുള്ളതല്ല. ഞങ്ങൾ അറിഞ്ഞുകൊണ്ട് കുട്ടികളുടെ വിവരങ്ങൾ ശേഖരിക്കാറില്ല.',
        marathi:
            'हे अ‍ॅप १३ वर्षांपेक्षा कमी वयाच्या मुलांसाठी नाही. आम्ही १३ वर्षांखालील मुलांकडून जाणीवपूर्वक वैयक्तिक माहिती गोळा करत नाही.',
        gujarati:
            'આ એપ 13 વર્ષથી ઓછી ઉંમરના બાળકો માટે નથી. અમે જાણીજોઈને 13 વર્ષથી ઓછી ઉંમરના બાળકો પાસેથી માહિતી એકત્રિત કરતા નથી.',
        bengali:
            'এই অ্যাপটি ১৩ বছরের কম বয়সী শিশুদের জন্য নয়। আমরা জেনেবুঝে ১৩ বছরের কম বয়সী শিশুদের ব্যক্তিগত তথ্য সংগ্রহ করি না।',
        punjabi:
            'ਇਹ ਐਪ 13 ਸਾਲ ਤੋਂ ਘੱਟ ਉਮਰ ਦੇ ਬੱਚਿਆਂ ਲਈ ਨਹੀਂ ਹੈ। ਅਸੀਂ ਜਾਣਬੁੱਝ ਕੇ 13 ਸਾਲ ਤੋਂ ਘੱਟ ਉਮਰ ਦੇ ਬੱਚਿਆਂ ਦੀ ਨਿੱਜੀ ਜਾਣਕਾਰੀ ਇਕੱਠੀ ਨਹੀਂ ਕਰਦੇ।',
        odia:
            'ଏହି ଆପ୍ ୧୩ ବର୍ଷରୁ କମ୍ ପିଲାମାନଙ୍କ ପାଇଁ ଉଦ୍ଦିଷ୍ଟ ନୁହେଁ। ଆମେ ଜାଣିଶୁଣି ପିଲାମାନଙ୍କଠାରୁ ବ୍ୟକ୍ତିଗତ ସୂଚନା ସଂଗ୍ରହ କରୁନାହୁଁ।',
        assamese:
            'এই এপটো ১৩ বছৰৰ তলৰ শিশুৰ বাবে নহয়। আমি জানি-বুজি ১৩ বছৰৰ তলৰ শিশুৰ ব্যক্তিগত তথ্য সংগ্ৰহ নকৰোঁ।',
        konkani:
            'ಹೆಂ ಆ್ಯಪ್ 13 ವರ್ಸಾಂ ಸಕಯ್ಲ್ಯಾ ಭುರ್ಗ್ಯಾಂಕ್ ನ್ಹಯ್. ಆಮಿ ಭುರ್ಗ್ಯಾಂಚಿ ಖಾಸ್ಗಿ ಮಾಹಿತಿ ಜಾಣಾಸುನ್ ಜಮೊ ಕರ್ನಾಂವ್.',
        nepali:
            'यो एप १३ वर्ष मुनिका बालबालिकाका लागि होइन। हामी जानीजानी बालबालिकाबाट व्यक्तिगत जानकारी सङ्कलन गर्दैनौं।',
        meitei:
            'এপ অসি চহী ১৩ গী মখাগী অঙাংগীদমক নত্তে। ঐখোয়না মখোয়গী পার্সনেল দেতা খংনা-খংনা খোমগত্তে।',
        mizo:
            'He app hi kum 13 hnuailam tan duan a ni lo. Kum 13 hnuailam mimal chanchin kan la khawm ngai lo.',
        kashmiri:
            'یہِ ایپھ چھُ نہٕ ۱۳ وُہُر کھۄتہٕ لۄکٹؠن شُرؠن باپتھ۔ أسی چھِ نہٕ جان بوجھ کٔرِتھ تِہنٛز معلومات جَمَہ کَران۔',
        ladakhi:
            'ཨེཔ་འདི་ལོ་ ༡༣ མན་གྱི་བྱིས་པའི་ཆེད་དུ་མིན། ང་ཚོས་བྱིས་པའི་སྒེར་གྱི་གནས་ཚུལ་ཤེས་བཞིན་དུ་མི་བསྡུ།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఫోటోలు, అనుమతులు మరియు నిల్వ',
        english: 'Photos, Permissions, and Storage',
        hindi: 'फ़ोटो, अनुमतियां और संग्रहण',
        tamil: 'புகைப்படங்கள், அனுமதிகள் மற்றும் சேமிப்பகம்',
        kannada: 'ಫೋಟೋಗಳು, ಅನುಮತಿಗಳು ಮತ್ತು ಸಂಗ್ರಹಣೆ',
        malayalam: 'ഫോട്ടോകൾ, അനുമതികൾ, സ്റ്റോറേജ്',
        marathi: 'फोटो, परवानग्या आणि स्टोरेज',
        gujarati: 'ફોટા, પરવાનગીઓ અને સંગ્રહ',
        bengali: 'ছবি, অনুমতি এবং স্টোরেজ',
        punjabi: 'ਫੋਟੋਆਂ, ਇਜਾਜ਼ਤਾਂ ਅਤੇ ਸਟੋਰੇਜ',
        odia: 'ଫଟୋ, ଅନୁମତି ଏବଂ ଷ୍ଟୋରେଜ୍',
        assamese: 'ফটো, অনুমতি আৰু সংৰক্ষণাগাৰ',
        konkani: 'ಫೋಟೋಸ್, ಪರ್ಮಿಶನ್ಸ್ ಆನಿ ಸ್ಟೋರೇಜ್',
        nepali: 'फोटोहरू, अनुमतिहरू र भण्डारण',
        meitei: 'ফোতোশিং, অয়াবশিং অমসুং স্তোরেজ',
        mizo: 'Thlalak, phalna leh storage',
        kashmiri: 'فوٹو، اجازت نامہٕ تہٕ سٹوریج',
        ladakhi: 'འདྲ་པར། ཆོག་མཆན་དང་གསོག་འཇོག',
      ),
      strings.localized(
        telugu:
            'ఫోటో ఎంపిక, పోస్టర్ సేవ్ చేయడం మరియు నోటిఫికేషన్ల కోసం మాత్రమే అనుమతులు కోరబడతాయి. మీరు ఎంచుకున్న ఇమేజ్‌లను ఇంపోర్ట్ చేయడానికి మరియు రూపొందించిన పోస్టర్లను సేవ్ చేయడానికి మాత్రమే స్టోరేజ్ ఉపయోగించబడుతుంది.',
        english:
            'Permissions are requested only for photo selection, poster saving, or notifications. Storage permissions or media pickers are used only to import images you select and to export posters you choose to save.',
        hindi:
            'अनुमतियां केवल फ़ोटो चयन, पोस्टर सहेजने या सूचनाओं के लिए मांगी जाती हैं। आपके द्वारा चुने गए चित्रों को आयात और निर्यात करने के लिए ही स्टोरेज का उपयोग किया जाता है।',
        tamil:
            'புகைப்படத் தேர்வு, போஸ்டர் சேமிப்பு அல்லது அறிவிப்புகளுக்கு மட்டுமே அனுமதிகள் கோரப்படுகின்றன. நீங்கள் தேர்ந்தெடுக்கும் படங்களை இறக்குமதி செய்ய மட்டுமே சேமிப்பகம் பயன்படுகிறது.',
        kannada:
            'ಫೋಟೋ ಆಯ್ಕೆ, ಪೋಸ್ಟರ್ ಉಳಿಸುವಿಕೆ ಅಥವಾ ಅಧಿಸೂಚನೆಗಳಿಗಾಗಿ ಮಾತ್ರ ಅನುಮತಿಗಳನ್ನು ವಿನಂತಿಸಲಾಗುತ್ತದೆ. ನೀವು ಆರಿಸಿದ ಚಿತ್ರಗಳನ್ನು ಬಳಸಲು ಮಾತ್ರ ಸಂಗ್ರಹಣೆಯನ್ನು ಬಳಸಲಾಗುತ್ತದೆ.',
        malayalam:
            'ഫോട്ടോ തിരഞ്ഞെടുക്കൽ, പോസ്റ്റർ സേവ് ചെയ്യൽ, അറിയിപ്പുകൾ എന്നിവയ്ക്ക് മാത്രമേ അനുമതികൾ ആവശ്യപ്പെടൂ. നിങ്ങൾ തിരഞ്ഞെടുക്കുന്ന ചിത്രങ്ങൾ ഉപയോഗിക്കാൻ മാത്രമേ സ്റ്റോറേജ് ഉപയോഗിക്കൂ.',
        marathi:
            'परवानग्या फक्त फोटो निवड, पोस्टर सेव्ह करणे किंवा सूचनांसाठी मागितल्या जातात. तुम्ही निवडलेल्या प्रतिमा वापरण्यासाठीच स्टोरेज वापरले जाते.',
        gujarati:
            'પરવાનગીઓ ફક્ત ફોટો પસંદગી, પોસ્ટર સાચવવા અથવા સૂચનાઓ માટે વિનંતી કરવામાં આવે છે. પસંદ કરેલી છબીઓ માટે જ સ્ટોરેજનો ઉપયોગ થાય છે.',
        bengali:
            'অনুমতি কেবল ছবি নির্বাচন, পোস্টার সংরক্ষণ বা বিজ্ঞপ্তির জন্য চাওয়া হয়। আপনি যে ছবিগুলি নির্বাচন করেন কেবল সেগুলি ব্যবহারের জন্যই স্টোরেজ ব্যবহৃত হয়।',
        punjabi:
            'ਇਜਾਜ਼ਤਾਂ ਸਿਰਫ਼ ਫੋਟੋ ਚੋਣ, ਪੋਸਟਰ ਸੁਰੱਖਿਅਤ ਕਰਨ ਜਾਂ ਸੂਚਨਾਵਾਂ ਲਈ ਮੰਗੀਆਂ ਜਾਂਦੀਆਂ ਹਨ। ਚੁਣੀਆਂ ਗਈਆਂ ਤਸਵੀਰਾਂ ਲਈ ਹੀ ਸਟੋਰੇਜ ਵਰਤੀ ਜਾਂਦੀ ਹੈ।',
        odia:
            'ଅନୁମତି କେବଳ ଫଟୋ ଚୟନ, ପୋଷ୍ଟର ସେଭ୍ କରିବା କିମ୍ବା ବିଜ୍ଞପ୍ତି ପାଇଁ ଅନୁରୋଧ କରାଯାଏ। ଆପଣ ବାଛିଥିବା ଫଟୋ ବ୍ୟବହାର ପାଇଁ ହିଁ ଷ୍ଟୋରେଜ୍ ବ୍ୟବହୃତ ହୁଏ।',
        assamese:
            'অনুমতি কেৱল ফটো বাছনি, পোষ্টাৰ সংৰক্ষণ বা জাননীৰ বাবে অনুৰোধ কৰা হয়। নিৰ্বাচিত ছবি ব্যৱহাৰৰ বাবেহে সংৰক্ষণাগাৰ ব্যৱহাৰ কৰা হয়।',
        konkani:
            'ಪರ್ಮಿಶನ್ಸ್ ಫೋಟೋ ವಿಂಚುಂಕ್, ಪೋಸ್ಟರ್ ಸಾಂಭಾಳುಂಕ್ ಆನಿ ನೋಟಿಫಿಕೇಶನ್ಸಾಕ್ ಮಾತ್ರ್ ಮಾಗ್ತಾಂವ್. ವಿಂಚ್ಲೆ ಫೋಟೋಸ್ ವಾಪರುಂಕ್ ಮಾತ್ರ್ ಸ್ಟೋರೇಜ್ ವಾಪರ್ತಾ.',
        nepali:
            'अनुमतिहरू केवल फोटो चयन, पोस्टर बचत वा सूचनाहरूको लागि अनुरोध गरिन्छ। तपाईंले छनोट गर्नुभएका तस्बिरहरूका लागि मात्र भण्डारण प्रयोग गरिन्छ।',
        meitei:
            'অয়াবশিং ফোতো খনবা, পোস্তর সেভ তৌবা নত্রগা নোতিফিকেসনগীদমক খক্তমক খোঙল্লি। নহাক্না খনরবা মমিশিংগীদমকখক স্তোরেজ শীজিন্নৈ।',
        mizo:
            'Thlalak thlan, poster save emaw hriattirna atan chauh phalna dil a ni. I thlalak thlan lakluh leh save nan chauh storage hman a ni.',
        kashmiri:
            'اجازت نامہٕ چھِ صِرَف فوٹو اِنتخاب، پوسٹر مَحفوٗظ کَرنہٕ یا اِطلاعَن باپتھ مَنٛگنہٕ یِوان। چُننہٕ آمٕژ تصویرن باپتھ چھُ سٹوریج اِستعمال گَژھان۔',
        ladakhi:
            'ཆོག་མཆན་ནི་འདྲ་པར་འདེམས་པ། པོསྚར་ཉར་ཚགས་དང་བརྡ་ཐོའི་དོན་དུ་ཁོ་ན་ཞུ། ཁྱེད་ཀྱིས་བདམས་པའི་འདྲ་པར་གྱི་ཆེད་དུ་གསོག་འཇོག་སྤྱོད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఎడిటర్ ప్రాసెసింగ్, అసెట్స్ మరియు డౌన్‌లోడ్లు',
        english: 'Editor Processing, Assets, and Downloads',
        hindi: 'एडिटर प्रोसेसिंग, एसेट्स और डाउनलोड',
        tamil: 'எடிட்டர் செயலாக்கம், சொத்துகள் மற்றும் பதிவிறக்கங்கள்',
        kannada: 'ಎಡಿಟರ್ ಪ್ರಕ್ರಿಯೆ, ಅಸೆಟ್‌ಗಳು ಮತ್ತು ಡೌನ್‌ಲೋಡ್‌ಗಳು',
        malayalam: 'എഡിറ്റർ പ്രോസസ്സിംഗ്, അസറ്റുകൾ, ഡൗൺലോഡുകൾ',
        marathi: 'एडिटर प्रोसेसिंग, अ‍ॅसेट्स आणि डाउनलोड्स',
        gujarati: 'એડિટર પ્રોસેસિંગ, એસેટ્સ અને ડાઉનલોડ્સ',
        bengali: 'এডিটর প্রক্রিয়াকরণ, অ্যাসেট এবং ডাউনলোড',
        punjabi: 'ਐਡੀਟਰ ਪ੍ਰੋਸੈਸਿੰਗ, ਸੰਪਤੀਆਂ ਅਤੇ ਡਾਊਨਲੋਡ',
        odia: 'ଏଡିଟର୍ ପ୍ରୋସେସିଂ, ଆସେଟ୍ ଏବଂ ଡାଉନଲୋଡ୍',
        assamese: 'এডিটৰ প্ৰক্ৰিয়াকৰণ, সম্পদ আৰু ডাউনলোড',
        konkani: 'ಎಡಿಟರ್ ಪ್ರೊಸೆಸಿಂಗ್, ಅಸೆಟ್ಸ್ ಆನಿ ಡೌನ್‌ಲೋಡ್ಸ್',
        nepali: 'सम्पादक प्रशोधन, सम्पत्ति र डाउनलोडहरू',
        meitei: 'এদিতর প্রোসেসিং, এসেতশিং অমসুং দাউনলোদশিং',
        mizo: 'Editor buatsaihna, assets leh download-te',
        kashmiri: 'ایڈیٹر پروسیسنگ، اثاثہٕ تہٕ ڈاون لوڈ',
        ladakhi: 'ཞུ་དག་ཆས་ཀྱི་ལས་སྣོན། རྒྱུ་ཆ་དང་ཕབ་ལེན།',
      ),
      strings.localized(
        telugu:
            'ఎడిటర్ PSD/TIFF ఇంపోర్ట్, ఫోటో ఎడిటింగ్, బ్రష్‌లు, లేయర్ ఎఫెక్ట్స్, బ్యాక్‌గ్రౌండ్ రిమూవల్ మరియు అసెట్ డౌన్‌లోడ్లకు మద్దతు ఇస్తుంది. వేగవంతమైన యాక్సెస్ కోసం డౌన్‌లోడ్ చేసిన అసెట్స్ పరికరంలో భద్రపరచబడతాయి.',
        english:
            'The editor may support PSD/TIFF import, photo editing, brushes, layer effects, background removal, and asset downloads. Downloaded assets are cached on device for faster access.',
        hindi:
            'एडिटर PSD/TIFF आयात, फ़ोटो संपादन, ब्रश, लेयर प्रभाव, बैकग्राउंड हटाने और एसेट डाउनलोड का समर्थन करता है। डाउनलोड किए गए एसेट्स तेजी से एक्सेस के लिए डिवाइस पर सहेजे जाते हैं।',
        tamil:
            'எடிட்டர் PSD/TIFF இறக்குமதி, புகைப்படத் திருத்தம், பிரஷ்கள், பின்னணி நீக்கம் மற்றும் சொத்து பதிவிறக்கங்களை ஆதரிக்கிறது. பதிவிறக்கப்பட்டவை சாதனத்தில் தற்காலிகமாக சேமிக்கப்படுகின்றன.',
        kannada:
            'ಎಡಿಟರ್ PSD/TIFF ಆಮದು, ಫೋಟೋ ಎಡಿಟಿಂಗ್, ಬ್ರಶ್‌ಗಳು, ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ರಿಮೂವಲ್ ಮತ್ತು ಅಸೆಟ್ ಡೌನ್‌ಲೋಡ್‌ಗಳನ್ನು ಬೆಂಬಲಿಸುತ್ತದೆ. ವೇಗದ ಪ್ರವೇಶಕ್ಕಾಗಿ ಅಸೆಟ್‌ಗಳನ್ನು ಸಂಗ್ರಹಿಸಲಾಗುತ್ತದೆ.',
        malayalam:
            'എഡിറ്റർ ഫോട്ടോ എഡിറ്റിംഗ്, ബ്രഷുകൾ, ലെയർ ഇഫക്റ്റുകൾ, ബാക്ക്ഗ്രൗണ്ട് റിമൂവൽ എന്നിവ പിന്തുണയ്ക്കുന്നു. ഡൗൺലോഡ് ചെയ്തവ വേഗത്തിലുള്ള ആക്സസിനായി സേവ് ചെയ്യപ്പെടുന്നു.',
        marathi:
            'एडिटर PSD/TIFF आयात, फोटो संपादन, ब्रशेस, लेयर इफेक्ट्स, बॅकग्राउंड काढणे आणि अ‍ॅसेट डाउनलोड्सना सपोर्ट करतो. डाउनलोड केलेले अ‍ॅसेट्स डिव्हाइसवर सेव्ह केले जातात.',
        gujarati:
            'એડિટર ફોટો એડિટિંગ, બ્રશ, લેયર ઇફેક્ટ્સ, બેકગ્રાઉન્ડ રિમૂવલ અને એસેટ ડાઉનલોડ્સને સપોર્ટ કરે છે. ઝડપી ઍક્સેસ માટે ડાઉનલોડ કરેલ એસેટ્સ સેવ થાય છે.',
        bengali:
            'এডিটর ছবি সম্পাদনা, ব্রাশ, লেয়ার এফেক্টস, ব্যাকগ্রাউন্ড রিমুভাল এবং অ্যাসেট ডাউনলোড সমর্থন করে। দ্রুত অ্যাক্সেসের জন্য উপাদানগুলি ডিভাইসে সংরক্ষিত থাকে।',
        punjabi:
            'ਐਡੀਟਰ ਫੋਟੋ ਸੰਪਾਦਨ, ਬੁਰਸ਼, ਲੇਅਰ ਪ੍ਰਭਾਵ, ਬੈਕਗ੍ਰਾਊਂਡ ਹਟਾਉਣ ਅਤੇ ਸੰਪਤੀ ਡਾਊਨਲੋਡ ਦਾ ਸਮਰਥਨ ਕਰਦਾ ਹੈ। ਤੇਜ਼ ਪਹੁੰਚ ਲਈ ਸੰਪਤੀਆਂ ਡਿਵਾਈਸ ਤੇ ਸੁਰੱਖਿਅਤ ਕੀਤੀਆਂ ਜਾਂਦੀਆਂ ਹਨ।',
        odia:
            'ଏଡିଟର୍ ଫଟୋ ଏଡିଟିଂ, ବ୍ରସ୍, ଲେୟାର ଇଫେକ୍ଟସ୍, ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଇବା ଏବଂ ଆସେଟ୍ ଡାଉନଲୋଡ୍ କୁ ସମର୍ଥନ କରେ। ଦ୍ରୁତ ପ୍ରବେଶ ପାଇଁ ଆସେଟ୍ ଡିଭାଇସରେ ସେଭ୍ ହୁଏ।',
        assamese:
            'এডিটৰে ফটো সম্পাদনা, ব্ৰাছ, স্তৰৰ প্ৰভাৱ, পটভূমি আঁতৰোৱা আৰু সম্পদ ডাউনলোডাক সমৰ্থন কৰে। দ্ৰুত প্ৰৱেশৰ বাবে সম্পদসমূহ ডিভাইচত সংৰক্ষণ কৰা হয়।',
        konkani:
            'ಎಡಿಟರ್ ಫೋಟೋ ಎಡಿಟಿಂಗ್, ಬ್ರಶ್, ಎಫೆಕ್ಟ್ಸ್, ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ಕಾಡ್ಚೆಂ ಆನಿ ಅಸೆಟ್ ಡೌನ್‌ಲೋಡ್ಸ್ ಸಪೋರ್ಟ್ ಕರ್ತಾ. ವೆಗಿಂ ಮೆಳೊಂಕ್ ಅಸೆಟ್ಸ್ ಮೊಬೈಲಾರ್ ಸಾಂಭಾಳ್ತಾತ್.',
        nepali:
            'सम्पादकले फोटो सम्पादन, ब्रस, लेयर प्रभाव, पृष्ठभूमि हटाउने र सम्पत्ति डाउनलोडहरू समर्थन गर्दछ। द्रुत पहुँचका लागि सम्पत्तिहरू उपकरणमा बचत गरिन्छ।',
        meitei:
            'এদিতর অসিনা ফোতো এদিতিং, ব্রসশিং, লেয়র ইফেক্তশিং, বেকগ্রাউন্দ লৌথোকপা অমসুং এসেত দাউনলোদ তৌবদা মতেং পাংই। য়াংনা এক্সেস তৌনবগীদমক এসেতশিং দিভাইসতা সেভ তৌই।',
        mizo:
            'Editor hian photo editing, brushes, layer effects, background paihna leh asset downloads a thlawp a. Rang taka hman theih nan device-ah dah that a ni.',
        kashmiri:
            'ایڈیٹر چھُ فوٹو ایڈیٹنگ، برش، بیک گرٛاونٛڈ ہٹاوُن تہٕ اثاثہٕ ڈاون لوڈَس سَہارا دِوان। تیزی سان اینٹری باپتھ چھِ اثاثہٕ ڈِوائسَس پؠٹھ مَحفوٗظ گَژھان۔',
        ladakhi:
            'ཞུ་དག་ཆས་ཀྱིས་འདྲ་པར་བཟོ་བཅོས། པིར། ཁྱད་ཆོས། རྒྱབ་ལྗོངས་སེལ་བ་དང་རྒྱུ་ཆ་ཕབ་ལེན་ལ་རྒྱབ་སྐྱོར་བྱེད། མགྱོགས་མྱུར་ལྟ་ཀློག་ཆེད་རྒྱུ་ཆ་རྣམས་ཉར་ཚགས་བྱེད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సబ్‌స్క్రిప్షన్లు మరియు బిల్లింగ్',
        english: 'Subscriptions and Billing',
        hindi: 'सदस्यता और बिलिंग',
        tamil: 'சந்தாக்கள் மற்றும் பில்லிங்',
        kannada: 'ಚಂದಾದಾರಿಕೆಗಳು ಮತ್ತು ಬಿಲ್ಲಿಂಗ್',
        malayalam: 'സബ്‌സ്‌ക്രിപ്ഷനുകളും ബില്ലിംഗും',
        marathi: 'सदस्यता आणि बिलिंग',
        gujarati: 'સબ્સ્ક્રિપ્શન્સ અને બિલિંગ',
        bengali: 'সাবস্ক্রিপশন এবং বিলিং',
        punjabi: 'ਗਾਹਕੀਆਂ ਅਤੇ ਬਿਲਿੰਗ',
        odia: 'ସଦସ୍ୟତା ଏବଂ ବିଲିଂ',
        assamese: 'গ্ৰাহকভুক্তি আৰু বিলিং',
        konkani: 'ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ಸ್ ಆನಿ ಬಿಲ್ಲಿಂಗ್',
        nepali: 'सदस्यता र बिलिङ',
        meitei: 'সবস্ক্রিপ্সনশিং অমসুং বিলিং',
        mizo: 'Subscriptions leh Billing',
        kashmiri: 'سبسکرپشن تہٕ بِلِنٛگ',
        ladakhi: 'མངགས་ཉོ་དང་རིན་བསྡུ།',
      ),
      strings.localized(
        telugu:
            'సబ్‌స్క్రిప్షన్ ధృవీకరణ కోసం కొనుగోలు టోకెన్లు, ఉత్పత్తి ఐడీలు, ఆర్డర్ ఐడీలు మరియు ఖాతా వివరాలు Google Play Billing ద్వారా సురక్షితంగా ప్రాసెస్ చేయబడతాయి.',
        english:
            'For subscription verification, purchase tokens, product IDs, order IDs, and account IDs are processed securely through Google Play Billing and Firebase functions.',
        hindi:
            'सदस्यता सत्यापन के लिए खरीदारी टोकन, उत्पाद आईडी, ऑर्डर आईडी Google Play Billing के माध्यम से सुरक्षित रूप से संसाधित किए जाते हैं।',
        tamil:
            'சந்தா சரிபார்ப்புக்கு கொள்முதல் டோக்கன்கள், தயாரிப்பு ஐடிகள் கூகிள் பிளே பில்லிங் மூலம் பாதுகாப்பாக செயல்படுத்தப்படுகின்றன.',
        kannada:
            'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆಗಾಗಿ ಖರೀದಿ ಟೋಕನ್‌ಗಳು ಮತ್ತು ಐಡಿಗಳನ್ನು Google Play Billing ಮೂಲಕ ಸುರಕ್ಷಿತವಾಗಿ ಪ್ರಕ್ರಿಯೆಗೊಳಿಸಲಾಗುತ್ತದೆ.',
        malayalam:
            'സബ്‌സ്‌ക്രിപ്ഷൻ പരിശോധനയ്ക്കായി പർച്ചേസ് ടോക്കണുകൾ, ഉൽപ്പന്ന ഐഡികൾ എന്നിവ ഗൂഗിൾ പ്ലേ ബില്ലിംഗ് വഴി സുരക്ഷിതമായി കൈകാര്യം ചെയ്യുന്നു.',
        marathi:
            'सदस्यता पडताळणीसाठी खरेदी टोकन्स आणि उत्पादन आयडी Google Play Billing द्वारे सुरक्षितपणे प्रक्रिया केली जातात.',
        gujarati:
            'સબ્સ્ક્રિપ્શન ચકાસણી માટે ખરીદી ટોકન અને પ્રોડક્ટ આઈડી Google Play Billing દ્વારા સુરક્ષિત રીતે પ્રક્રિયા કરવામાં આવે છે.',
        bengali:
            'সাবস্ক্রিপশন যাচাইকরণের জন্য কেনাকাটার টোকেন এবং পণ্য আইডি Google Play Billing-এর মাধ্যমে নিরাপদে প্রক্রিয়াজাত করা হয়।',
        punjabi:
            'ਗਾਹਕੀ ਪੁਸ਼ਟੀਕਰਨ ਲਈ ਖਰੀਦ ਟੋਕਨ ਅਤੇ ਉਤਪਾਦ ਆਈਡੀ Google Play Billing ਰਾਹੀਂ ਸੁਰੱਖਿਅਤ ਢੰਗ ਨਾਲ ਪ੍ਰੋਸੈਸ ਕੀਤੇ ਜਾਂਦੇ ਹਨ।',
        odia:
            'ସଦସ୍ୟତା ଯାଞ୍ଚ ପାଇଁ କ୍ରୟ ଟୋକନ୍ ଏବଂ ଉତ୍ପାଦ ଆଇଡି Google Play Billing ମାଧ୍ୟମରେ ସୁରକ୍ଷିତ ଭାବରେ ପ୍ରକ୍ରିୟାକରଣ କରାଯାଏ।',
        assamese:
            'গ্ৰাহকভুক্তি সত্যাপনৰ বাবে ক্ৰয় টোকেন আৰু সামগ্ৰী আইডি Google Play Billing-ৰ জৰিয়তে সুৰক্ষিতভাৱে প্ৰক্ৰিয়াকৰণ কৰা হয়।',
        konkani:
            'ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ ತಪಾಸ್ಣೆಕ್ ಖರೀದಿ ಟೋಕನ್ಸ್ ಆನಿ ಐಡಿ Google Play Billing ಮುಖಾಂತ್ರ್ ಸುರಕ್ಷಿತ್ ಜಾವ್ನ್ ಪ್ರೊಸೆಸ್ ಜಾತಾತ್.',
        nepali:
            'सदस्यता प्रमाणीकरणका लागि खरिद टोकनहरू र उत्पादन आईडीहरू Google Play Billing मार्फत सुरक्षित रूपमा प्रशोधन गरिन्छ।',
        meitei:
            'সবস্ক্রিপ্সন ভেরিফিকেসনগীদমক পর্চেস তোকেনশিং অমসুং প্রদক্ত আইদিশিং Google Play Billing গী মতেংনা চেকশින්না প্রোসেস তৌই।',
        mizo:
            'Subscription endik nan purchase token, product ID leh order ID-te chu Google Play Billing hmangin him takin buatsaih a ni.',
        kashmiri:
            'سبسکرپشن تصدیق باپتھ چھِ خٔریٖداری ٹوکن تہٕ پروڈکٹ آی ڈی Google Play Billing ذٔریعہٕ مَحفوٗظ طٔریٖقَس پؠٹھ پروسیس گَژھان۔',
        ladakhi:
            'མངགས་ཉོ་བདེན་དཔང་ཆེད་ཉོ་སྒྲུབ་ཀྱི་དཔང་རྟགས་དང་ཐོན་རྫས་ཨང་གྲངས་རྣམས་ Google Play Billing བརྒྱུད་ནས་བདེ་འཇགས་ངང་ལས་སྣོན་བྱེད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'మీ ఎంపికలు మరియు ఖాతా తొలగింపు',
        english: 'Your Choices and Account Deletion',
        hindi: 'आपके विकल्प और खाता हटाना',
        tamil: 'உங்கள் தேர்வுகள் மற்றும் கணக்கு நீக்கம்',
        kannada: 'ನಿಮ್ಮ ಆಯ್ಕೆಗಳು ಮತ್ತು ಖಾತೆ ಅಳಿಸುವಿಕೆ',
        malayalam: 'നിങ്ങളുടെ ചോയ്‌സുകളും അക്കൗണ്ട് ഇല്ലാതാക്കലും',
        marathi: 'तुमचे पर्याय आणि खाते हटवणे',
        gujarati: 'તમારા વિકલ્પો અને એકાઉન્ટ ડિલીટ કરવું',
        bengali: 'আপনার পছন্দ এবং অ্যাকাউন্ট মুছে ফেলা',
        punjabi: 'ਤੁਹਾਡੀਆਂ ਚੋਣਾਂ ਅਤੇ ਖਾਤਾ ਮਿਟਾਉਣਾ',
        odia: 'ଆପଣଙ୍କ ପସନ୍ଦ ଏବଂ ଆକାଉଣ୍ଟ୍ ବିଲୋପ',
        assamese: 'আপোনাৰ পছন্দ আৰু একাউণ্ট বিলোপ',
        konkani: 'ತುಮ್ಚ್ಯೊ ವಿಂಚವ್ಣ್ಯೊ ಆನಿ ಖಾತೆಂ ಕಾಡ್ಚೆಂ',
        nepali: 'तपाईंका विकल्पहरू र खाता मेटाउने',
        meitei: 'নহাক্কী ওপসনশিং অমসুং একাউন্ত মুথত্পা',
        mizo: 'I duhthlan theih leh account paihna',
        kashmiri: 'تُہنٛدؠ اِنتخابات تہٕ کھاتہٕ مِٹاوُن',
        ladakhi: 'ཁྱེད་ཀྱི་འདེམས་ཁ་དང་ཐོ་ཁ་སུབ་པ།',
      ),
      strings.localized(
        telugu:
            'మీరు నోటిఫికేషన్లు మరియు అనుమతులను నియంత్రించవచ్చు. యాప్ సెట్టింగ్స్‌లో ఖాతా తొలగింపు అభ్యర్థన సదుపాయం ఉంది, దీని ద్వారా ప్రొఫైల్ డేటా మరియు కంటెంట్ తొలగించబడుతుంది.',
        english:
            'You can turn off optional notifications and permissions. The app provides an account deletion option in settings that deletes profile data, uploaded content, and authentication details.',
        hindi:
            'आप सूचनाओं और अनुमतियों को नियंत्रित कर सकते हैं। ऐप सेटिंग्स में खाता हटाने का विकल्प प्रदान करता है जो प्रोफ़ाइल डेटा और सामग्री को हटा देता है।',
        tamil:
            'அறிவிப்புகள் மற்றும் அனுமதிகளை நீங்கள் கட்டுப்படுத்தலாம். சுயவிவரத் தரவை முழுமையாக நீக்க அமைப்புகளில் கணக்கு நீக்குதல் வசதி உள்ளது.',
        kannada:
            'ನೀವು ಅಧಿಸೂಚನೆಗಳು ಮತ್ತು ಅನುಮತಿಗಳನ್ನು ನಿಯಂತ್ರಿಸಬಹುದು. ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಖಾತೆ ಅಳಿಸುವ ಆಯ್ಕೆ ಲಭ್ಯವಿದ್ದು, ಅದು ಪ್ರೊಫೈಲ್ ಡೇಟಾವನ್ನು ಅಳಿಸುತ್ತದೆ.',
        malayalam:
            'അറിയിപ്പുകളും അനുമതികളും നിയന്ത്രിക്കാം. പ്രൊഫൈൽ വിവരങ്ങൾ നീക്കം ചെയ്യാൻ സെറ്റിംഗ്സിൽ അക്കൗണ്ട് ഡിലീറ്റ് ചെയ്യാനുള്ള സൗകര്യമുണ്ട്.',
        marathi:
            'तुम्ही सूचना आणि परवानग्या नियंत्रित करू शकता. अ‍ॅप सेटिंग्जमध्ये खाते हटवण्याचा पर्याय प्रदान करते जो प्रोफाइल डेटा हटवतो.',
        gujarati:
            'તમે સૂચનાઓ અને પરવાનગીઓ નિયંત્રિત કરી શકો છો. સેટિંગ્સમાં એકાઉન્ટ ડિલીટ કરવાનો વિકલ્પ છે જે પ્રોફાઇલ ડેટા કાઢી નાખે છે.',
        bengali:
            'আপনি বিজ্ঞপ্তি এবং অনুমতি নিয়ন্ত্রণ করতে পারেন। অ্যাপটি সেটিংসে অ্যাকাউন্ট মুছে ফেলার বিকল্প প্রদান করে যা প্রোফাইল তথ্য মুছে ফেলে।',
        punjabi:
            'ਤੁਸੀਂ ਸੂਚਨਾਵਾਂ ਅਤੇ ਇਜਾਜ਼ਤਾਂ ਨੂੰ ਨਿਯੰਤਰਿਤ ਕਰ ਸਕਦੇ ਹੋ। ਐਪ ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਖਾਤਾ ਮਿਟਾਉਣ ਦਾ ਵਿਕਲਪ ਪ੍ਰਦਾਨ ਕਰਦੀ ਹੈ ਜੋ ਪ੍ਰੋਫਾਈਲ ਡੇਟਾ ਮਿਟਾਉਂਦੀ ਹੈ।',
        odia:
            'ଆପଣ ବିଜ୍ଞପ୍ତି ଏବଂ ଅନୁମତି ନିୟନ୍ତ୍ରଣ କରିପାରିବେ। ଆପ୍ ସେଟିଂସରେ ଆକାଉଣ୍ଟ୍ ବିଲୋପ ବିକଳ୍ପ ପ୍ରଦାନ କରେ ଯାହା ପ୍ରୋଫାଇଲ୍ ଡାଟା ଡିଲିଟ୍ କରେ।',
        assamese:
            'আপুনি জাননী আৰু অনুমতি নিয়ন্ত্ৰণ কৰিব পাৰে। এপে ছেটিংছত একাউণ্ট বিলোপৰ বিকল্প প্ৰদান কৰে যিয়ে প্ৰʼফাইল তথ্য মচি পেলায়।',
        konkani:
            'ತುಮಿ ನೋಟಿಫಿಕೇಶನ್ಸ್ ಆನಿ ಪರ್ಮಿಶನ್ಸ್ ಕಂಟ್ರೋಲ್ ಕರುಂಕ್ ಸಕ್ತಾತ್. ಸೆಟ್ಟಿಂಗ್ಸಾಂತ್ ಖಾತೆಂ ಕಾಡ್ಚೊ ಆಯ್ಕೊ ಆಸಾ ಜೊ ಪ್ರೊಫೈಲ್ ಡೇಟಾ ಡಿಲೀಟ್ ಕರ್ತಾ.',
        nepali:
            'तपाईं सूचना र अनुमतिहरू नियन्त्रण गर्न सक्नुहुन्छ। एपले सेटिङहरूमा खाता मेटाउने विकल्प प्रदान गर्दछ जसले प्रोफाइल डाटा मेटाउँछ।',
        meitei:
            'নহাক্না নোতিফিকেসনশিং অমসুং অয়াবশিং কন্ত্রোল তৌবা য়াই। সেতিংসতা প্রোফাইল দেতা মুথত্নবা একাউন্ত দিলিত তৌবগী ওপসন লৈ।',
        mizo:
            'Hriattirna leh phalna i thunun thei. Settings-ah account paihna a awm a, profile data leh thil dangte a paih vek ang.',
        kashmiri:
            'تُہؠ ہیکیو اِطلاعات تہٕ اجازت نامہٕ کَنٹرول کٔرِتھ۔ سیٹنگس مَنٛز چھُ کھاتہٕ مِٹاونُک اِنتخاب دٔستیاب یُس ڈیٹا مِٹاوان چھُ۔',
        ladakhi:
            'ཁྱེད་ཀྱིས་བརྡ་ཐོ་དང་ཆོག་མཆན་རྣམས་སྟངས་འཛིན་བྱེད་ཐུབ། སྒྲིག་འཛུགས་ནང་ཐོ་ཁ་སུབ་པའི་འདེམས་ཁ་ཡོད་ཅིང་དེས་གསལ་བཤད་གྲངས་གཞི་རྣམས་སུབ་བོ།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఫిర్యాదు చేయడం మరియు అనుచిత కంటెంట్',
        english: 'Reporting and Abusive Content',
        hindi: 'रिपोर्टिंग और अपमानजनक सामग्री',
        tamil: 'புகாரளித்தல் மற்றும் தவறான உள்ளடக்கம்',
        kannada: 'ವರದಿ ಮಾಡುವುದು ಮತ್ತು ನಿಂದನೀಯ ವಿಷಯ',
        malayalam: 'റിപ്പോർട്ടിംഗും അനുചിത ഉള്ളടക്കവും',
        marathi: 'तक्रार करणे आणि आक्षेपार्ह सामग्री',
        gujarati: 'રિપોર્ટિંગ અને અપમાનજનક સામગ્રી',
        bengali: 'রিপোর্টিং এবং আপত্তিকর বিষয়বস্তু',
        punjabi: 'ਰਿਪੋਰਟਿੰਗ ਅਤੇ ਅਪਮਾਨਜਨਕ ਸਮੱਗਰੀ',
        odia: 'ରିପୋର୍ଟ ଏବଂ ଅପମାନଜନକ ବିଷୟବସ୍ତୁ',
        assamese: 'ৰিপৰ্ট কৰা আৰু আপত্তিজনক বিষয়বস্তু',
        konkani: 'ರಿಪೋರ್ಟ್ ಕರ್ಚೆಂ ಆನಿ ವಾಯ್ಟ್ ಕಂಟೆಂಟ್',
        nepali: 'रिपोर्टिङ र आपत्तिजनक सामग्री',
        meitei: 'রিপোর্ত তৌবা অমসুং ফত্তবা কন্তেন্ত',
        mizo: 'Report leh thil tha lo',
        kashmiri: 'رِپورٹ کَرُن تہٕ نازیبا مواد',
        ladakhi: 'སྙན་ཞུ་དང་མི་འོས་པའི་ནང་དོན།',
      ),
      strings.localized(
        telugu:
            'దుర్వినియోగం, ఉల్లంఘన లేదా తప్పుదారి పట్టించే కంటెంట్ కనిపిస్తే, తక్షణ చర్య తీసుకోవడానికి దయచేసి సపోర్ట్ ద్వారా నివేదించండి.',
        english:
            'If you see abusive, infringing, impersonating, deceptive, or policy-violating content, please report it immediately through support so we can take appropriate action.',
        hindi:
            'यदि आपको अपमानजनक, उल्लंघनकारी या भ्रामक सामग्री दिखाई देती है, तो कृपया तुरंत सहायता के माध्यम से रिपोर्ट करें ताकि हम उचित कार्रवाई कर सकें।',
        tamil:
            'தவறான, உரிமை மீறல் அல்லது கொள்கை மீறும் உள்ளடக்கத்தைக் கண்டால், நடவடிக்கை எடுக்க ஆதரவு மூலம் உடனடியாகப் புகாரளிக்கவும்.',
        kannada:
            'ದುರ್ಬಳಕೆ, ಉಲ್ಲಂಘನೆ ಅಥವಾ ವಂಚನೆಯ ವಿಷಯ ಕಂಡುಬಂದರೆ, ಸೂಕ್ತ ಕ್ರಮ ಕೈಗೊಳ್ಳಲು ದಯವಿಟ್ಟು ಬೆಂಬಲದ ಮೂಲಕ ವರದಿ ಮಾಡಿ.',
        malayalam:
            'അനുചിതമായതോ നയലംഘനമുള്ളതോ ആയ ഉള്ളടക്കം കണ്ടാൽ, ഉചിതമായ നടപടിയെടുക്കാൻ സപ്പോർട്ട് വഴി റിപ്പോർട്ട് ചെയ്യുക.',
        marathi:
            'आक्षेपार्ह, उल्लंघन करणारी किंवा दिशाभूल करणारी सामग्री आढळल्यास, कारवाईसाठी कृपया सपोर्टद्वारे ताबडतोब तक्रार करा.',
        gujarati:
            'જો તમને અપમાનજનક અથવા નીતિનું ઉલ્લંઘન કરતી સામગ્રી દેખાય, તો કૃપા કરીને યોગ્ય પગલાં લેવા માટે સપોર્ટ દ્વારા તરત જ જાણ કરો.',
        bengali:
            'আপত্তিকর বা নীতি লঙ্ঘনকারী সামগ্রী দেখলে ব্যবস্থা নেওয়ার জন্য অনুগ্রহ করে সহায়তার মাধ্যমে অবিলম্বে রিপোর্ট করুন।',
        punjabi:
            'ਜੇਕਰ ਤੁਹਾਨੂੰ ਕੋਈ ਅਪਮਾਨਜਨਕ ਜਾਂ ਨੀਤੀ ਦੀ ਉਲੰਘਣਾ ਕਰਨ ਵਾਲੀ ਸਮੱਗਰੀ ਦਿਖਾਈ ਦਿੰਦੀ ਹੈ, ਤਾਂ ਕਿਰਪਾ ਕਰਕੇ ਸਹਾਇਤਾ ਰਾਹੀਂ ਰਿਪੋਰਟ ਕਰੋ।',
        odia:
            'ଯଦି ଆପଣ ଅପମାନଜନକ ବା ନୀତି ଉଲ୍ଲଂଘନକାରୀ ବିଷୟବସ୍ତୁ ଦେଖନ୍ତି, ତେବେ ଉପଯୁକ୍ତ କାର୍ଯ୍ୟାନୁଷ୍ଠାନ ପାଇଁ ତୁରନ୍ତ ସହାୟତା ମାଧ୍ୟମରେ ରିପୋର୍ଟ କରନ୍ତୁ।',
        assamese:
            'যদি আপুনি আপত্তিজনক বা নীতি উলংঘনকাৰী বিষয়বস্তু দেখে, তেন্তে ব্যৱস্থা গ্ৰহণৰ বাবে অনুগ্ৰহ কৰি সাহায্যৰ জৰিয়তে ৰিপʼৰ্ট কৰক।',
        konkani:
            'ವಾಯ್ಟ್ ಯಾ ನಿಯಮ್ ಉಲ್ಲಂಘನ್ ಕರ್ಚೆಂ ಕಂಟೆಂಟ್ ದಿಸ್ಲ್ಯಾರ್, ಕ್ರಮ ಘೆಂವ್ಕ್ ದಯಾ ಕರ್ನ್ ಸಪೋರ್ಟಾ ಮುಖಾಂತ್ರ್ ರಿಪೋರ್ಟ್ ಕರಾ.',
        nepali:
            'यदि तपाईंले आपत्तिजनक वा नीति उल्लङ्घन गर्ने सामग्री देख्नुभयो भने, कृपया समर्थन मार्फत तुरुन्तै रिपोर्ट गर्नुहोस्।',
        meitei:
            'ফত্তবা নত্রগা পোলিসি কায়বা কন্তেন্ত উরবদি, চুনবা এক্সন লৌনবগীদমক সপোর্তকী মতেংনা য়াংনা রিপোর্ত তৌবীয়ু।',
        mizo:
            'Duhthusam lo leh dan kalh thil i hmuh chuan, hma lak theih nan support hmangin report vat ang che.',
        kashmiri:
            'اگر تُہؠ کانٛہہ نازیبا مواد وُچھِو، مہربٲنی کٔرِتھ کٔریو سَپورٹَس پؠٹھ رِپورٹ تاكہِ مَناصِب کاروٲیی کَرنہٕ یِیہِ۔',
        ladakhi:
            'མི་འོས་པའམ་སྲིད་ཇུས་འགལ་བའི་ནང་དོན་མཐོང་ཚེ། འོས་པའི་བྱ་ཐབས་སྤེལ་ཆེད་རོགས་རམ་བརྒྱུད་ནས་མགྱོགས་པོར་སྙན་ཞུ་གནང་རོགས།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సంప్రదింపు సమాచారం',
        english: 'Contact Information',
        hindi: 'संपर्क जानकारी',
        tamil: 'தொடர்பு தகவல்',
        kannada: 'ಸಂಪರ್ಕ ಮಾಹಿತಿ',
        malayalam: 'ബന്ധപ്പെടാനുള്ള വിവരങ്ങൾ',
        marathi: 'संपर्क माहिती',
        gujarati: 'સંપર્ક માહિતી',
        bengali: 'যোগাযোগের তথ্য',
        punjabi: 'ਸੰਪਰਕ ਜਾਣਕਾਰੀ',
        odia: 'ଯୋଗାଯୋଗ ସୂଚନା',
        assamese: 'যোগাযোগৰ তথ্য',
        konkani: 'ಸಂಪರ್ಕ್ ಮಾಹಿತಿ',
        nepali: 'सम्पर्क जानकारी',
        meitei: 'কন্তেক্তকী ৱারোল',
        mizo: 'Biak pawhna chanchin',
        kashmiri: 'رابطہٕ ہٕنٛز معلومات',
        ladakhi: 'འབྲེལ་གཏུགས་གནས་ཚུལ།',
      ),
      strings.localized(
        telugu:
            'గోప్యత, బిల్లింగ్, డేటా వినియోగం లేదా ఖాతా తొలగింపు సహాయం కోసం ${AppPublicInfo.supportEmail} ని సంప్రదించండి.',
        english:
            'For privacy, billing, data usage, or account deletion support, contact ${AppPublicInfo.supportEmail}.',
        hindi:
            'गोपनीयता, बिलिंग, डेटा उपयोग या खाता हटाने में सहायता के लिए ${AppPublicInfo.supportEmail} पर संपर्क करें।',
        tamil:
            'தனியுரிமை, பில்லிங், தரவு பயன்பாடு அல்லது கணக்கு நீக்க ஆதரவுக்கு ${AppPublicInfo.supportEmail}-ஐத் தொடர்பு கொள்ளவும்.',
        kannada:
            'ಗೌಪ್ಯತೆ, ಬಿಲ್ಲಿಂಗ್, ಡೇಟಾ ಬಳಕೆ ಅಥವಾ ಖಾತೆ ಅಳಿಸುವಿಕೆ ಬೆಂಬಲಕ್ಕಾಗಿ ${AppPublicInfo.supportEmail} ಅನ್ನು ಸಂಪರ್ಕಿಸಿ.',
        malayalam:
            'സ്വകാര്യത, ബില്ലിംഗ്, ഡാറ്റ ഉപയോഗം അല്ലെങ്കിൽ അക്കൗണ്ട് ഇല്ലാതാക്കൽ സഹായത്തിന് ${AppPublicInfo.supportEmail}-മായി ബന്ധപ്പെടുക.',
        marathi:
            'गोपनीयता, बिलिंग, डेटा वापर किंवा खाते हटवण्याच्या समर्थनासाठी ${AppPublicInfo.supportEmail} वर संपर्क साधा.',
        gujarati:
            'ગોપનીયતા, બિલિંગ, ડેટા વપરાશ અથવા એકાઉન્ટ ડિલીટ સપોર્ટ માટે ${AppPublicInfo.supportEmail} પર સંપર્ક કરો.',
        bengali:
            'গোপনীয়তা, বিলিং, ডেটা ব্যবহার বা অ্যাকাউন্ট মুছে ফেলার সহায়তার জন্য ${AppPublicInfo.supportEmail}-এ যোগাযোগ করুন।',
        punjabi:
            'ਗੋਪਨੀਯਤਾ, ਬਿਲਿੰਗ, ਡੇਟਾ ਵਰਤੋਂ ਜਾਂ ਖਾਤਾ ਮਿਟਾਉਣ ਦੀ ਸਹਾਇਤਾ ਲਈ ${AppPublicInfo.supportEmail} ਤੇ ਸੰਪਰਕ ਕਰੋ।',
        odia:
            'ଗୋପନୀୟତା, ବିଲିଂ, ଡାଟା ବ୍ୟବହାର ବା ଆକାଉଣ୍ଟ୍ ବିଲୋପ ସହାୟତା ପାଇଁ ${AppPublicInfo.supportEmail} ସହିତ ଯୋଗାଯୋଗ କରନ୍ତୁ।',
        assamese:
            'গোপনীয়তা, বিলিং, তথ্য ব্যৱহাৰ বা একাউণ্ট বিলোপ সাহায্যৰ বাবে ${AppPublicInfo.supportEmail} লৈ যোগাযোগ কৰক।',
        konkani:
            'ಗೌಪ್ಯತಾ, ಬಿಲ್ಲಿಂಗ್, ಡೇಟಾ ವಾಪರ್ಪ್ ಯಾ ಖಾತೆಂ ಕಾಡ್ಚ್ಯಾ ಆಧಾರ್ ಖಾತೀರ್ ${AppPublicInfo.supportEmail} ಕಡೆನ್ ಸಂಪರ್ಕ್ ಕರಾ.',
        nepali:
            'गोपनीयता, बिलिङ, डाटा प्रयोग वा खाता मेटाउने समर्थनका लागि ${AppPublicInfo.supportEmail} मा सम्पर्क गर्नुहोस्।',
        meitei:
            'প্রাইভেসি, বিলিং, দেতা য়ুসেজ নত্রগা একাউন্ত দিলিত তৌবগী সপোর্তকীদমক ${AppPublicInfo.supportEmail} দা কন্তেক্ত তৌবীয়ু।',
        mizo:
            'Privacy, billing, data hman dan emaw account paih chungchangah ${AppPublicInfo.supportEmail}-ah hian bia ang che.',
        kashmiri:
            'رازدٲری، بِلِنٛگ، یا کھاتہٕ مِٹاونہٕ باپتھ کٔریو ${AppPublicInfo.supportEmail} پؠٹھ رابطہٕ۔',
        ladakhi:
            'གསང་རྒྱ། རིན་བསྡུ། གྲངས་གཞི་སྤྱོད་པའམ་ཐོ་ཁ་སུབ་པའི་རོགས་རམ་ཆེད་ ${AppPublicInfo.supportEmail} ལ་འབྲེལ་གཏུགས་གནང་རོགས།',
      ),
    ),
  ];

  List<_LegalSection> get _termsSections => <_LegalSection>[
    _LegalSection(
      strings.localized(
        telugu: 'యాప్ వినియోగం',
        english: 'Using the App',
        hindi: 'ऐप का उपयोग',
        tamil: 'செயலியைப் பயன்படுத்துதல்',
        kannada: 'ಆ್ಯಪ್ ಬಳಕೆ',
        malayalam: 'ആപ്പ് ഉപയോഗം',
        marathi: 'अ‍ॅप वापरणे',
        gujarati: 'એપનો ઉપયોગ',
        bengali: 'অ্যাপ ব্যবহার করা',
        punjabi: 'ਐਪ ਦੀ ਵਰਤੋਂ',
        odia: 'ଆପ୍ ବ୍ୟବହାର',
        assamese: 'এপ ব্যৱহাৰ কৰা',
        konkani: 'ಆ್ಯಪ್ ವಾಪರ್ಚಿಂ',
        nepali: 'एपको प्रयोग',
        meitei: 'এপ শীজিন্নবা',
        mizo: 'App hman dan',
        kashmiri: 'ایپھُک اِستعمال',
        ladakhi: 'ཨེཔ་སྤྱོད་པ།',
      ),
      strings.localized(
        telugu:
            'Mana Poster Ai వ్యక్తిగత, వ్యాపార మరియు ప్రచార పోస్టర్ల తయారీ కోసం ఉద్దేశించబడింది. మీరు చట్టబద్ధంగా మరియు ఇతరుల హక్కులను గౌరవిస్తూ యాప్‌ను ఉపయోగించాలి.',
        english:
            'Mana Poster Ai is intended for personal, business, and promotional poster creation. You agree to use the service in compliance with all applicable laws and respect third-party rights.',
        hindi:
            'Mana Poster Ai व्यक्तिगत, व्यावसायिक और प्रचार पोस्टर निर्माण के लिए है। आप सभी लागू कानूनों का पालन करते हुए सेवा का उपयोग करने के लिए सहमत हैं।',
        tamil:
            'Mana Poster Ai தனிப்பட்ட, வணிக மற்றும் விளம்பர போஸ்டர் உருவாக்கத்திற்குப் பயன்படுகிறது. சட்டங்களுக்கு உட்பட்டுச் செயல்பட ஒப்புக்கொள்கிறீர்கள்.',
        kannada:
            'Mana Poster Ai ವೈಯಕ್ತಿಕ, ವ್ಯವಹಾರ ಮತ್ತು ಪ್ರಚಾರದ ಪೋಸ್ಟರ್ ರಚನೆಗೆ ಉದ್ದೇಶಿಸಲಾಗಿದೆ. ಅನ್ವಯವಾಗುವ ಕಾನೂನುಗಳನ್ನು ಗೌರವಿಸಿ ಬಳಸಲು ನೀವು ಒಪ್ಪುತ್ತೀರಿ.',
        malayalam:
            'മന പോസ്റ്റർ എഐ വ്യക്തിഗത, ബിസിനസ്സ്, പ്രമോഷണൽ പോസ്റ്റർ നിർമ്മാണത്തിനുള്ളതാണ്. ബാധകമായ നിയമങ്ങൾ പാലിച്ച് സേവനം ഉപയോഗിക്കാൻ സമ്മതിക്കുന്നു.',
        marathi:
            'Mana Poster Ai वैयक्तिक, व्यवसाय आणि प्रचारात्मक पोस्टर निर्मितीसाठी आहे. लागू कायद्यांचे पालन करून सेवा वापरण्यास तुम्ही सहमत आहात.',
        gujarati:
            'Mana Poster Ai વ્યક્તિગત, વ્યવસાયિક અને પ્રમોશનલ પોસ્ટર બનાવવા માટે છે. તમે લાગુ કાયદાઓનું પાલન કરીને ઉપયોગ કરવા સંમત થાઓ છો.',
        bengali:
            'Mana Poster Ai ব্যক্তিগত, ব্যবসায়িক এবং প্রচারমূলক পোস্টার তৈরির উদ্দেশ্যে তৈরি। আপনি সমস্ত আইন মেনে এটি ব্যবহার করতে সম্মত হচ্ছেন।',
        punjabi:
            'Mana Poster Ai ਨਿੱਜੀ, ਕਾਰੋਬਾਰੀ ਅਤੇ ਪ੍ਰਚਾਰਕ ਪੋਸਟਰ ਬਣਾਉਣ ਲਈ ਹੈ। ਤੁਸੀਂ ਕਾਨੂੰਨਾਂ ਦੀ ਪਾਲਣਾ ਕਰਦੇ ਹੋਏ ਸੇਵਾ ਦੀ ਵਰਤੋਂ ਕਰਨ ਲਈ ਸਹਿਮਤ ਹੋ।',
        odia:
            'Mana Poster Ai ବ୍ୟକ୍ତିଗତ, ବ୍ୟବସାୟ ଏବଂ ପ୍ରଚାରମୂଳକ ପୋଷ୍ଟର ତିଆରି ପାଇଁ ଉଦ୍ଦିଷ୍ଟ। ଆପଣ ସମସ୍ତ ଆଇନ ପାଳନ କରି ଏହା ବ୍ୟବହାର କରିବାକୁ ସହମତ ଅଟନ୍ତି।',
        assamese:
            'Mana Poster Ai ব্যক্তিগত, ব্যৱসায়িক আৰু প্ৰচাৰমূলক পোষ্টাৰ নিৰ্মাণৰ বাবে। আপুনি আইন মানি এই সেৱা ব্যৱহাৰ কৰিবলৈ সন্মত হৈছে।',
        konkani:
            'Mana Poster Ai ಖಾಸ್ಗಿ, ವ್ಯವಹಾರಾಚೆ ಆನಿ ಪ್ರಚಾರಾಚೆ ಪೋಸ್ಟರ್ ಕರುಂಕ್ ಆಸಾ. ಕಾಯ್ದೆ ಪಾಳುನ್ ಹೆಂ ವಾಪರುಂಕ್ ತುಮಿ ಒಪ್ತಾತ್.',
        nepali:
            'Mana Poster Ai व्यक्तिगत, व्यावसायिक र प्रचार पोस्टर निर्माणको लागि हो। तपाईं लागू कानूनको पालना गर्दै सेवा प्रयोग गर्न सहमत हुनुहुन्छ।',
        meitei:
            'Mana Poster Ai মীওই অমগী মশাগী, লল্লোন-ইতিক অমসুং প্রমোস্নেল পোস্তর শেম্বগীদমকনি। লোশিং ঙাক্না শীজিন্নবদা নহাক্না য়ানৈ।',
        mizo:
            'Mana Poster Ai hi mimal, sumdawnna leh fakna poster siam nana duan a ni. Dan ding lai zawm chungin he service hi hman i remti a ni.',
        kashmiri:
            'Mana Poster Ai چھُ ذٲتی، کٲروبٲری تہٕ پروموشنل پوسٹر بناونہٕ باپتھ۔ تُہؠ چھِو قونوٗنَس تَحَت اِستعمال کَرنَس رَضامَنٛد۔',
        ladakhi:
            'Mana Poster Ai ནི་སྒེར། ཚོང་ལས་དང་ཁྱབ་བསྒྲགས་པོསྚར་བཟོ་བའི་ཆེད་དུ་ཡིན། ཁྲིམས་མཐུན་ངང་ཞབས་ཞུ་འདི་སྤྱོད་པར་ཁྱེད་ཀྱིས་ཁས་ལེན།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఖాతా మరియు కంటెంట్ బాధ్యత',
        english: 'Account and Content Responsibility',
        hindi: 'खाता और सामग्री की ज़िम्मेदारी',
        tamil: 'கணக்கு மற்றும் உள்ளடக்கப் பொறுப்பு',
        kannada: 'ಖಾತೆ ಮತ್ತು ವಿಷಯದ ಜವಾಬ್ದಾರಿ',
        malayalam: 'അക്കൗണ്ട്, ഉള്ളടക്ക ഉത്തരവാദിത്തം',
        marathi: 'खाते आणि सामग्रीची जबाबदारी',
        gujarati: 'એકાઉન્ટ અને સામગ્રીની જવાબદારી',
        bengali: 'অ্যাকাউন্ট এবং বিষয়বস্তুর দায়িত্ব',
        punjabi: 'ਖਾਤਾ ਅਤੇ ਸਮੱਗਰੀ ਦੀ ਜ਼ਿੰਮੇਵਾਰੀ',
        odia: 'ଆକାଉଣ୍ଟ୍ ଏବଂ ବିଷୟବସ୍ତୁ ଦାୟିତ୍ୱ',
        assamese: 'একাউণ্ট আৰু বিষয়বস্তুৰ দায়িত্ব',
        konkani: 'ಖಾತೆಂ ಆನಿ ಕಂಟೆಂಟ್ ಜವಾಬ್ದಾರಿ',
        nepali: 'खाता र सामग्री जिम्मेवारी',
        meitei: 'একাউন্ত অমসুং কন্তেন্তকী থৌদাং',
        mizo: 'Account leh thil ziah mawhphurhna',
        kashmiri: 'کھاتہٕ تہٕ موادٕچ زِمہٕ وٲری',
        ladakhi: 'ཐོ་ཁ་དང་ནང་དོན་གྱི་འགན་འཁྲི།',
      ),
      strings.localized(
        telugu:
            'మీ లాగిన్ వివరాలను సురక్షితంగా ఉంచుకోవాలి. మీరు ఉపయోగించే ఫోటోలు, పేర్లు, లోగోలు లేదా టెక్స్ట్‌పై మీకు తగిన హక్కులు ఉండాలి.',
        english:
            'You must keep your login details secure. You must have the right to use any photo, text, logo, or trademark you include in your poster designs.',
        hindi:
            'आपको अपने लॉगिन विवरण सुरक्षित रखने होंगे। आपके पोस्टर डिज़ाइन में शामिल किसी भी फ़ोटो, टेक्स्ट या लोगो का उपयोग करने का अधिकार आपके पास होना चाहिए।',
        tamil:
            'உங்கள் உள்நுழைவு விவரங்களைப் பாதுகாப்பாக வைத்திருக்க வேண்டும். வடிவமைப்பில் பயன்படுத்தும் புகைப்படம் அல்லது லோகோவுக்கு உங்களுக்கு உரிமை இருக்க வேண்டும்.',
        kannada:
            'ನಿಮ್ಮ ಲಾಗಿನ್ ವಿವರಗಳನ್ನು ಸುರಕ್ಷಿತವಾಗಿರಿಸಿಕೊಳ್ಳಬೇಕು. ವಿನ್ಯಾಸಗಳಲ್ಲಿ ನೀವು ಬಳಸುವ ಫೋಟೋ ಅಥವಾ ಲೋಗೋ ಬಳಸಲು ನಿಮಗೆ ಹಕ್ಕಿರಬೇಕು.',
        malayalam:
            'ലോഗിൻ വിവരങ്ങൾ സുരക്ഷിതമായി സൂക്ഷിക്കണം. പോസ്റ്ററുകളിൽ ഉപയോഗിക്കുന്ന ഫോട്ടോ, ലോഗോ എന്നിവ ഉപയോഗിക്കാൻ നിങ്ങൾക്ക് അവകാശമുണ്ടായിരിക്കണം.',
        marathi:
            'तुम्ही तुमचे लॉगिन तपशील सुरक्षित ठेवले पाहिजेत. पोस्टर डिझाईन्समध्ये तुम्ही वापरत असलेल्या कोणत्याही फोटो किंवा लोगोचा वापर करण्याचा अधिकार तुमच्याकडे असावा.',
        gujarati:
            'તમારે તમારી લૉગિન વિગતો સુરક્ષિત રાખવી આવશ્યક છે. પોસ્ટર ડિઝાઇનમાં ઉપયોગમાં લેવાતા ફોટા કે લોગોનો ઉપયોગ કરવાનો અધિકાર તમારી પાસે હોવો જોઈએ.',
        bengali:
            'আপনাকে আপনার লগইন বিবরণ সুরক্ষিত রাখতে হবে। পোস্টার ডিজাইনে ব্যবহৃত ছবি বা লোগো ব্যবহারের অধিকার আপনার থাকতে হবে।',
        punjabi:
            'ਤੁਹਾਨੂੰ ਆਪਣੇ ਲੌਗਇਨ ਵੇਰਵੇ ਸੁਰੱਖਿਅਤ ਰੱਖਣੇ ਚਾਹੀਦੇ ਹਨ। ਪੋਸਟਰ ਡਿਜ਼ਾਈਨ ਵਿੱਚ ਵਰਤੀਆਂ ਜਾਣ ਵਾਲੀਆਂ ਫੋਟੋਆਂ ਜਾਂ ਲੋਗੋ ਦੀ ਵਰਤੋਂ ਕਰਨ ਦਾ ਅਧਿਕਾਰ ਤੁਹਾਡੇ ਕੋਲ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ।',
        odia:
            'ଆପଣ ନିଜ ଲଗଇନ୍ ବିବରଣୀ ସୁରକ୍ଷିତ ରଖିବା ଉଚିତ୍। ପୋଷ୍ଟର ଡିଜାଇନ୍‌ରେ ବ୍ୟବହୃତ ଫଟୋ ବା ଲୋଗୋ ବ୍ୟବହାର କରିବାର ଅଧିକାର ଆପଣଙ୍କର ଥିବା ଆବଶ୍ୟକ।',
        assamese:
            'আপুনি আপোনাৰ লগইন তথ্য সুৰক্ষিত ৰাখিব লাগিব। পোষ্টাৰ ডিজাইনত ব্যৱহাৰ কৰা যিকোনো ফটো বা লʼগʼ ব্যৱহাৰৰ অধিকাৰ আপোনাৰ থাকিব লাগিব।',
        konkani:
            'ತುಮ್ಚೆ ಲಾಗ್ ಇನ್ ವಿವರಾಂ ಸುರಕ್ಷಿತ್ ದವರಾ. ಪೋಸ್ಟರಾಂತ್ ವಾಪರ್ಚಿ ಫೋಟೋ ಯಾ ಲೋಗೋ ವಾಪರುಂಕ್ ತುಮ್ಕಾಂ ಹಕ್ಕ್ ಆಸೊಂಕ್ ಜಾಯ್.',
        nepali:
            'तपाईंले आफ्नो लगइन विवरणहरू सुरक्षित राख्नुपर्छ। पोस्टर डिजाइनहरूमा समावेश फोटो वा लोगो प्रयोग गर्ने अधिकार तपाईंसँग हुनुपर्छ।',
        meitei:
            'নহাক্কী লগইন দেতাশিং চেকশින්না থম্বীয়ু। পোস্তর দিজাইনদা য়াওরিবা ফোতো নত্রগা লোগো শীজিন্নবগী হক নহাক্কী লৈগদবনি।',
        mizo:
            'I login details i vawng him tur a ni. I poster design-a thlalak, text, logo emaw trademark i hman tura dikna i nei tur a ni.',
        kashmiri:
            'تُہؠ پَزِ پنُن لاگ اِن تفصیلات مَحفوٗظ تھَوُن۔ ڈیزائنَس مَنٛز کُنہِ تہِ فوٹو یا لوگو اِستعمال کَرنُک اِختیار پَزِ تُہؠ آسُن۔',
        ladakhi:
            'ཁྱེད་ཀྱི་ནང་འཛུལ་གནས་ཚུལ་བདེ་འཇགས་ངང་ཉར་དགོས། པོསྚར་ནང་སྤྱོད་པའི་འདྲ་པར་རམ་ཚོང་རྟགས་སྤྱོད་པའི་ཐོབ་ཐང་ཁྱེད་ལ་ཡོད་དགོས།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'రాజకీయ కేటగిరీలు మరియు పబ్లిక్ చిహ్నాలు',
        english: 'Political Categories and Public Symbols',
        hindi: 'राजनीतिक श्रेणियां और सार्वजनिक प्रतीक',
        tamil: 'அரசியல் பிரிவுகள் மற்றும் பொது சின்னங்கள்',
        kannada: 'ರಾಜಕೀಯ ವರ್ಗಗಳು ಮತ್ತು ಸಾರ್ವಜನಿಕ ಚಿಹ್ನೆಗಳು',
        malayalam: 'രാഷ്ട്രീയ വിഭാഗങ്ങളും പൊതു ചിഹ്നങ്ങളും',
        marathi: 'राजकीय श्रेणी आणि सार्वजनिक चिन्हे',
        gujarati: 'રાજકીય શ્રેણીઓ અને જાહેર પ્રતીકો',
        bengali: 'রাজনৈতিক বিভাগ এবং সর্বজনীন প্রতীক',
        punjabi: 'ਸਿਆਸੀ ਸ਼੍ਰੇਣੀਆਂ ਅਤੇ ਜਨਤਕ ਪ੍ਰਤੀਕ',
        odia: 'ରାଜନୈତିକ ବିଭାଗ ଏବଂ ସାର୍ବଜନୀନ ପ୍ରତୀକ',
        assamese: 'ৰাজনৈতিক শ্ৰেণী আৰু ৰাজহুৱা প্ৰতীকসমূহ',
        konkani: 'ರಾಜಕೀಯ್ ವರ್ಗಾಂ ಆನಿ ಸಾರ್ವಜನಿಕ್ ಚಿಹ್ನಾಂ',
        nepali: 'राजनीतिक कोटिहरू र सार्वजनिक प्रतीकहरू',
        meitei: 'পোলিতিকেল কেটাগোরিশিং অমসুং পব্লিক সিম্বলশিং',
        mizo: 'Political category leh hmanraw langsarte',
        kashmiri: 'سیٲسی زمرٕ تہٕ عوٲمی نِشانات',
        ladakhi: 'སྲིད་དོན་དབྱེ་བ་དང་མང་ཚོགས་མཚོན་རྟགས།',
      ),
      strings.localized(
        telugu:
            'రాజకీయ పార్టీ కేటగిరీలు, చిహ్నాలు మరియు నాయకుల చిత్రాలు కేవలం వినియోగదారుల శుభాకాంక్షల కోసం మాత్రమే అందించబడ్డాయి. ఈ యాప్‌కు ఏ రాజకీయ పార్టీతోనూ అనుబంధం లేదు.',
        english:
            'Political party categories, party names, party symbols/logos, and leader imagery are provided solely for user communication and greetings. Mana Poster Ai is not affiliated with any political party.',
        hindi:
            'राजनीतिक दल की श्रेणियां, नाम और प्रतीक केवल उपयोगकर्ता संचार और शुभकामनाओं के लिए प्रदान किए जाते हैं। ऐप किसी भी दल से संबद्ध नहीं है।',
        tamil:
            'அரசியல் கட்சிப் பிரிவுகள் மற்றும் தலைவர்களின் படங்கள் வாழ்த்துகளுக்காக மட்டுமே வழங்கப்படுகின்றன. செயலி எந்தக் கட்சியுடனும் இணைக்கப்படவில்லை.',
        kannada:
            'ರಾಜಕೀಯ ಪಕ್ಷಗಳ ವರ್ಗಗಳು ಮತ್ತು ಚಿಹ್ನೆಗಳನ್ನು ಕೇವಲ ಬಳಕೆದಾರರ ಶುಭಾಶಯಗಳಿಗಾಗಿ ನೀಡಲಾಗಿದೆ. ಆ್ಯಪ್ ಯಾವುದೇ ಪಕ್ಷದೊಂದಿಗೆ ಸಂಬಂಧ ಹೊಂದಿಲ್ಲ.',
        malayalam:
            'രാഷ്ട്രീയ പാർട്ടി വിഭാഗങ്ങളും ചിഹ്നങ്ങളും ആശംസകൾക്കായി മാത്രമാണ് നൽകുന്നത്. ആപ്പിന് ഒരു രാഷ്ട്രീയ പാർട്ടിയുമായും ബന്ധമില്ല.',
        marathi:
            'राजकीय पक्ष श्रेणी आणि चिन्हे केवळ वापरकर्त्यांच्या शुभेच्छांसाठी दिली आहेत. अ‍ॅपचा कोणत्याही राजकीय पक्षाशी संबंध नाही.',
        gujarati:
            'રાજકીય પક્ષની શ્રેણીઓ અને પ્રતીકો ફક્ત વપરાશકર્તાની શુભેચ્છાઓ માટે પ્રદાન કરવામાં આવે છે. એપ કોઈપણ પક્ષ સાથે જોડાયેલી નથી.',
        bengali:
            'রাজনৈতিক দলের বিভাগ এবং প্রতীক কেবল ব্যবহারকারীর যোগাযোগের জন্য সরবরাহ করা হয়। অ্যাপটি কোনো দলের সাথে সম্পর্কিত নয়।',
        punjabi:
            'ਸਿਆਸੀ ਪਾਰਟੀ ਦੀਆਂ ਸ਼੍ਰੇਣੀਆਂ ਅਤੇ ਪ੍ਰਤੀਕ ਸਿਰਫ਼ ਸ਼ੁਭਕਾਮਨਾਵਾਂ ਲਈ ਦਿੱਤੇ ਗਏ ਹਨ। ਐਪ ਦਾ ਕਿਸੇ ਵੀ ਪਾਰਟੀ ਨਾਲ ਕੋਈ ਸੰਬੰਧ ਨਹੀਂ ਹੈ।',
        odia:
            'ରାଜନୈତିକ ଦଳ ବିଭାଗ ଏବଂ ପ୍ରତୀକ କେବଳ ଶୁଭେଚ୍ଛା ପାଇଁ ପ୍ରଦାନ କରାଯାଇଛି। ଆପ୍ କୌଣସି ଦଳ ସହିତ ଜଡ଼ିତ ନୁହେଁ।',
        assamese:
            'ৰাজনৈতিক দলৰ শ্ৰেণী আৰু প্ৰতীকসমূহ কেৱল শুভেচ্ছাৰ বাবে প্ৰদান কৰা হৈছে। এপটো কোনো দলৰ সৈতে জড়িত নহয়।',
        konkani:
            'ರಾಜಕೀಯ್ ವರ್ಗಾಂ ಆನಿ ಚಿಹ್ನಾಂ ಕೇವಲ್ ಶುಭಾಶಯಾಂ ಖಾತೀರ್ ದಿಲ್ಯಾಂತ್. ಆ್ಯಪಾಕ್ ಕಸಲ್ಯಾಚ್ ಪಕ್ಷಾ ಸಾಂಗಾತಾ ಸಂಬಂಧ್ ನಾ.',
        nepali:
            'राजनीतिक दल कोटिहरू र प्रतीकहरू केवल प्रयोगकर्ताको शुभकामनाका लागि प्रदान गरिन्छ। एप कुनै पनि दलसँग सम्बद्ध छैन।',
        meitei:
            'পোলিতিকেল পার্তিগী কেটাগোরিশিং অমসুং সিম্বলশিং শুপ্নগী য়াইফ-পাউজেলগীদমক পীজরিবনি। এপ অসিনা অমত্তা ওইবা পার্তিগসু মরি লৈনদে।',
        mizo:
            'Political party category leh symbol-te chu chibai bukna atan chauhva pek a ni. App hian eng political party mah a zawm lo.',
        kashmiri:
            'سیٲسی زمرٕ تہٕ نِشانات چھِ صِرَف مۆبارکبادی باپتھ دِوان۔ ایپھُک کُنہِ تہِ سیٲسی پارٹِی سٟتؠ تَعَلُق چھُ نہٕ۔',
        ladakhi:
            'སྲིད་དོན་ཚོགས་པའི་དབྱེ་བ་དང་མཚོན་རྟགས་རྣམས་བཀྲ་ཤིས་བདེ་ལེགས་ཀྱི་དོན་དུ་ཁོ་ན་ཡིན། ཨེཔ་འདིས་སྲིད་དོན་ཚོགས་པ་གང་ལའང་འབྲེལ་བ་མེད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సబ్‌స్క్రిప్షన్లు మరియు ప్రీమియం యాక్సెస్',
        english: 'Subscriptions and Premium Access',
        hindi: 'सदस्यता और प्रीमियम एक्सेस',
        tamil: 'சந்தாக்கள் மற்றும் பிரீமியம் அணுகல்',
        kannada: 'ಚಂದಾದಾರಿಕೆಗಳು ಮತ್ತು ಪ್ರೀಮಿಯಂ ಪ್ರವೇಶ',
        malayalam: 'സബ്‌സ്‌ക്രിപ്ഷനുകളും പ്രീമിയം ആക്സസും',
        marathi: 'सदस्यता आणि प्रीमियम अ‍ॅक्सेस',
        gujarati: 'સબ્સ્ક્રિપ્શન્સ અને પ્રીમિયમ એક્સેસ',
        bengali: 'সাবস্ক্রিপশন এবং প্রিমিয়াম অ্যাক্সেস',
        punjabi: 'ਗਾਹਕੀਆਂ ਅਤੇ ਪ੍ਰੀਮੀਅਮ ਪਹੁੰਚ',
        odia: 'ସଦସ୍ୟତା ଏବଂ ପ୍ରିମିୟମ୍ ପ୍ରବେଶ',
        assamese: 'গ্ৰাহকভুক্তি আৰু প্ৰিমিয়াম প্ৰৱেশ',
        konkani: 'ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ಸ್ ಆನಿ ಪ್ರೀಮಿಯಂ ಪ್ರವೇಶ್',
        nepali: 'सदस्यता र प्रिमियम पहुँच',
        meitei: 'সবস্ক্রিপ্সনশিং অমসুং প্রিমিয়ম এক্সেস',
        mizo: 'Subscriptions leh Premium Access',
        kashmiri: 'سبسکرپشن تہٕ پریمیم اینٹری',
        ladakhi: 'མངགས་ཉོ་དང་རིན་མེད་མ་ཡིན་པའི་ལྟ་ཀློག',
      ),
      strings.localized(
        telugu:
            'యాప్ ప్రో పోస్టర్ యాక్సెస్, తయారీ మరియు ఎక్స్‌పోర్ట్‌ను అందిస్తుంది. ఎడిటర్ ప్రో ప్రీమియం అసెట్స్, తెలుగు ఫాంట్లు మరియు బ్యాక్‌గ్రౌండ్ రిమూవల్‌ను అందిస్తుంది.',
        english:
            'Mana Poster Ai may offer multiple subscription plans. App Pro supports poster access, poster creation, and exports. Editor Pro supports premium editor assets, Telugu fonts, and background removal. The yearly all-access plan combines benefits where available.',
        hindi:
            'ऐप प्रो पोस्टर एक्सेस, निर्माण और निर्यात का समर्थन करता है। एडिटर प्रो प्रीमियम एसेट्स, तेलुगु फॉन्ट और बैकग्राउंड रिमूवल का समर्थन करता है।',
        tamil:
            'ஆப் ப்ரோ போஸ்டர் அணுகல், உருவாக்கம் மற்றும் ஏற்றுமதியை வழங்குகிறது. எடிட்டர் ப்ரோ பிரீமியம் சொத்துகள், எழுத்துருக்கள் மற்றும் பின்னணி நீக்கத்தை வழங்குகிறது.',
        kannada:
            'ಆ್ಯಪ್ ಪ್ರೊ ಪೋಸ್ಟರ್ ಪ್ರವೇಶ, ರಚನೆ ಮತ್ತು ರಫ್ತುಗಳನ್ನು ಬೆಂಬಲಿಸುತ್ತದೆ. ಎಡಿಟರ್ ಪ್ರೊ ಪ್ರೀಮಿಯಂ ಅಸೆಟ್‌ಗಳು, ಫಾಂಟ್‌ಗಳು ಮತ್ತು ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ತೆಗೆಯುವಿಕೆಯನ್ನು ಬೆಂಬಲಿಸುತ್ತದೆ.',
        malayalam:
            'ആപ്പ് പ്രോ പോസ്റ്റർ ആക്സസ്, നിർമ്മാണം എന്നിവ നൽകുന്നു. എഡിറ്റർ പ്രോ പ്രീമിയം അസറ്റുകൾ, ഫോണ്ടുകൾ, ബാക്ക്ഗ്രൗണ്ട് റിമൂവൽ എന്നിവ നൽകുന്നു.',
        marathi:
            'अ‍ॅप प्रो पोस्टर अ‍ॅक्सेस, निर्मिती आणि निर्यातीला सपोर्ट करते. एडिटर प्रो प्रीमियम अ‍ॅसेट्स, तेलगू फॉन्ट्स आणि बॅकग्राउंड काढण्याला सपोर्ट करते.',
        gujarati:
            'એપ પ્રો પોસ્ટર એક્સેસ, નિર્માણ અને નિકાસને સપોર્ટ કરે છે. એડિટર પ્રો પ્રીમિયમ એસેટ્સ, તેલુગુ ફોન્ટ્સ અને બેકગ્રાઉન્ડ રિમૂવલને સપોર્ટ કરે છે.',
        bengali:
            'অ্যাপ প্রো পোস্টার অ্যাক্সেস, তৈরি এবং রপ্তানি সমর্থন করে। এডিটর প্রো প্রিমিয়াম উপাদান, তেলুগু ফন্ট এবং ব্যাকগ্রাউন্ড রিমুভাল সমর্থন করে।',
        punjabi:
            'ਐਪ ਪ੍ਰੋ ਪੋਸਟਰ ਪਹੁੰਚ, ਨਿਰਮਾਣ ਅਤੇ ਨਿਰਯਾਤ ਦਾ ਸਮਰਥਨ ਕਰਦਾ ਹੈ। ਐਡੀਟਰ ਪ੍ਰੋ ਪ੍ਰੀਮੀਅਮ ਸੰਪਤੀਆਂ, ਫੌਂਟਾਂ ਅਤੇ ਬੈਕਗ੍ਰਾਊਂਡ ਹਟਾਉਣ ਦਾ ਸਮਰਥਨ ਕਰਦਾ ਹੈ।',
        odia:
            'ଆପ୍ ପ୍ରୋ ପୋଷ୍ଟର ପ୍ରବେଶ, ନିର୍ମାଣ ଏବଂ ରପ୍ତାନିକୁ ସମର୍ଥନ କରେ। ଏଡିଟର୍ ପ୍ରୋ ପ୍ରିମିୟମ୍ ଆସେଟ୍ ଏବଂ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଇବାକୁ ସମର୍ଥନ କରେ।',
        assamese:
            'এপ প্ৰʼই পোষ্টাৰ প্ৰৱেশ, নিৰ্মাণ আৰু ৰপ্তানি সমৰ্থন কৰে। এডিটৰ প্ৰʼই প্ৰিমিয়াম সম্পদ, ফন্ট আৰু পটভূমি আঁতৰোৱা সমৰ্থন কৰে।',
        konkani:
            'ಆ್ಯಪ್ ಪ್ರೊ ಪೋಸ್ಟರ್ ಪ್ರವೇಶ್, ತಯಾರಿ ಆನಿ ಎಕ್ಸ್‌ಪೋರ್ಟ್ಸ್ ಸಪೋರ್ಟ್ ಕರ್ತಾ. ಎಡಿಟರ್ ಪ್ರೊ ಪ್ರೀಮಿಯಂ ಅಸೆಟ್ಸ್ ಆನಿ ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ಕಾಡ್ಚೆಂ ಸಪೋರ್ಟ್ ಕರ್ತಾ.',
        nepali:
            'एप प्रो ले पोस्टर पहुँच, निर्माण र निर्यात समर्थन गर्दछ। सम्पादक प्रो ले प्रिमियम सम्पत्ति, फन्ट र पृष्ठभूमि हटाउने समर्थन गर्दछ।',
        meitei:
            'এপ প্রোনা পোস্তর এক্সেস, শেম্বা অমসুং এক্সপোর্ত তৌবদা মতেং পাংই। এদিতর প্রোনা প্রিমিয়ম এসেতশিং অমসুং বেকগ্রাউন্দ লৌথোকপদা মতেং পাংই।',
        mizo:
            'App Pro hian poster en, siam leh export a pui. Editor Pro hian premium assets, Telugu fonts leh background paihna a pe.',
        kashmiri:
            'ایپھ پرو چھُ پوسٹر اینٹری، بناونہٕ تہٕ برآمدَس سَہارا دِوان۔ ایڈیٹر پرو چھُ پریمیم اثاثہٕ تہٕ بیک گرٛاونٛڈ ہٹاونَس سَہارا دِوان۔',
        ladakhi:
            'ཨེཔ་པྲོ་ཡིས་པོསྚར་ལྟ་ཀློག བཟོ་སྐྲུན་དང་ཕྱིར་འདྲེན་ལ་རྒྱབ་སྐྱོར་བྱེད། ཞུ་དག་ཆས་པྲོ་ཡིས་རྒྱུ་ཆ་དང་རྒྱབ་ལྗོངས་སེལ་བར་རྒྱབ་སྐྱོར་བྱེད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఎడిటర్ టూల్స్ మరియు అసెట్ లైసెన్స్',
        english: 'Editor Tools and Asset License',
        hindi: 'एडिटर टूल्स और एसेट लाइसेंस',
        tamil: 'எடிட்டர் கருவிகள் மற்றும் சொத்து உரிமம்',
        kannada: 'ಎಡಿಟರ್ ಪರಿಕರಗಳು ಮತ್ತು ಅಸೆಟ್ ಪರವಾನಗಿ',
        malayalam: 'എഡിറ്റർ ടൂളുകളും അസറ്റ് ലൈസൻസും',
        marathi: 'एडिटर साधने आणि अ‍ॅसेट परवाना',
        gujarati: 'એડિટર ટૂલ્સ અને એસેટ લાઇસન્સ',
        bengali: 'এডিটর সরঞ্জাম এবং উপাদান লাইসেন্স',
        punjabi: 'ਐਡੀਟਰ ਟੂਲ ਅਤੇ ਸੰਪਤੀ ਲਾਇਸੰਸ',
        odia: 'ଏଡିଟର୍ ଉପକରଣ ଏବଂ ଆସେଟ୍ ଲାଇସେନ୍ସ',
        assamese: 'এডিটৰ সঁজুলি আৰু সম্পদ অনুজ্ঞাপত্ৰ',
        konkani: 'ಎಡಿಟರ್ ಟೂಲ್ಸ್ ಆನಿ ಅಸೆಟ್ ಲೈಸೆನ್ಸ್',
        nepali: 'सम्पादक उपकरण र सम्पत्ति इजाजतपत्र',
        meitei: 'এদিতর তুলশিং অমসুং এসেত লাইসেন্স',
        mizo: 'Editor hmanrua leh asset license',
        kashmiri: 'ایڈیٹر ٹولز تہٕ اثاثہٕ لایسنس',
        ladakhi: 'ཞུ་དག་ཆས་ཀྱི་ལག་ཆ་དང་རྒྱུ་ཆའི་ཆོག་ཐམ།',
      ),
      strings.localized(
        telugu:
            'యాప్‌లోని ప్రీమియం అసెట్స్ మరియు ఫాంట్లు పోస్టర్ల తయారీ కోసం మాత్రమే ఉపయోగించాలి. వాటిని విడిగా సంగ్రహించడం లేదా పునఃపంపిణీ చేయడం నిషిద్ధం.',
        english:
            'The editor may include premium assets, Telugu fonts, background removal, layer effects, brushes, and format conversion tools. Assets are licensed for use within posters created in the app and may not be extracted or redistributed.',
        hindi:
            'संपादक में प्रीमियम एसेट्स, तेलुगु फॉन्ट और बैकग्राउंड रिमूवल शामिल हो सकते हैं। एसेट्स केवल ऐप में बनाए गए पोस्टरों में उपयोग के लिए लाइसेंस प्राप्त हैं।',
        tamil:
            'பிரீமியம் சொத்துகள் செயலியில் போஸ்டர்களை உருவாக்க மட்டுமே உரிமம் பெற்றுள்ளன. அவற்றை தனியாகப் பிரித்தெடுக்கவோ பகிரவோ கூடாது.',
        kannada:
            'ಪ್ರೀಮಿಯಂ ಅಸೆಟ್‌ಗಳು ಆ್ಯಪ್‌ನಲ್ಲಿ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ರಚಿಸಲು ಮಾತ್ರ ಪರವಾನಗಿ ಹೊಂದಿವೆ. ಅವುಗಳನ್ನು ಪ್ರತ್ಯೇಕವಾಗಿ ವಿತರಿಸುವುದನ್ನು ನಿಷೇಧಿಸಲಾಗಿದೆ.',
        malayalam:
            'പ്രീമിയം അസറ്റുകൾ ആപ്പിൽ പോസ്റ്ററുകൾ ഉണ്ടാക്കാൻ മാത്രമായി നൽകിയിട്ടുള്ളതാണ്. അവ വേർതിരിച്ചെടുക്കാനോ പുനർവിതരണം ചെയ്യാനോ പാടില്ല.',
        marathi:
            'प्रीमियम अ‍ॅसेट्स केवळ अ‍ॅपमध्ये पोस्टर्स तयार करण्यासाठी वापरण्याचा परवाना आहे. ते वेगळे काढले किंवा पुनर्वितरित केले जाऊ शकत नाहीत.',
        gujarati:
            'પ્રીમિયમ એસેટ્સ ફક્ત એપમાં પોસ્ટર બનાવવા માટે લાઇસન્સ પ્રાપ્ત છે. તેમને અલગથી કાઢવા અથવા પુનઃવિતરણ કરવાની મંજૂરી નથી.',
        bengali:
            'প্রিমিয়াম উপাদানগুলি কেবল অ্যাপে পোস্টার তৈরির জন্য ব্যবহারের লাইসেন্সপ্রাপ্ত। সেগুলি আলাদাভাবে বের করা বা পুনরায় বিতরণ করা যাবে না।',
        punjabi:
            'ਪ੍ਰੀਮੀਅਮ ਸੰਪਤੀਆਂ ਸਿਰਫ਼ ਐਪ ਵਿੱਚ ਪੋਸਟਰ ਬਣਾਉਣ ਲਈ ਵਰਤਣ ਲਈ ਲਾਇਸੰਸਸ਼ੁਦਾ ਹਨ। ਉਹਨਾਂ ਨੂੰ ਵੱਖਰੇ ਤੌਰ ਤੇ ਵੰਡਿਆ ਨਹੀਂ ਜਾ ਸਕਦਾ।',
        odia:
            'ପ୍ରିମିୟମ୍ ଆସେଟ୍ କେବଳ ଆପ୍‌ରେ ପୋଷ୍ଟର ତିଆରି ପାଇଁ ବ୍ୟବହାର କରିବାକୁ ଲାଇସେନ୍ସପ୍ରାପ୍ତ। ସେଗୁଡ଼ିକୁ ପୃଥକ ଭାବରେ ପୁନଃବଣ୍ଟନ କରାଯାଇପାରିବ ନାହିଁ।',
        assamese:
            'প্ৰিমিয়াম সম্পদসমূহ কেৱল এপৰ ভিতৰত পোষ্টাৰ তৈয়াৰ কৰাৰ বাবে অনুজ্ঞাপত্ৰপ্ৰাপ্ত। সেইবোৰ সুকীয়াকৈ পুনৰ বিতৰণ কৰিব নোৱাৰিব।',
        konkani:
            'ಪ್ರೀಮಿಯಂ ಅಸೆಟ್ಸ್ ಆ್ಯಪಾಂತ್ ಪೋಸ್ಟರ್ ಕರುಂಕ್ ಮಾತ್ರ್ ಲೈಸೆನ್ಸ್ ಆಸಾ. ತಾಂಕಾಂ ಪ್ರತ್ಯೇಕ್ ವಾಂಟುಂಕ್ ಜಾಯ್ನಾ.',
        nepali:
            'प्रिमियम सम्पत्तिहरू एप भित्र पोस्टरहरू सिर्जना गर्नका लागि मात्र इजाजतपत्र प्राप्त छन्। तिनीहरूलाई छुट्टै पुनर्वितरण गर्न पाइने छैन।',
        meitei:
            'প্রিমিয়ম এসেতশিং শুপ্নগী এপ অসিদা পোস্তর শেম্বদা শীজিন্ননবগী লাইসেন্স লৈ। মখোয়বু তোঙান্না শন্দোকপা য়ারোই।',
        mizo:
            'Assets-te hi app chhunga poster siam nan chauh phal a ni a, lakhran emaw thehdarh chhawn phal a ni lo.',
        kashmiri:
            'اثاثہٕ چھِ صِرَف ایپس اندر پوسٹر بناونہٕ باپتھ لایسنس شُدٕ۔ تِم ہیکو نہٕ اَلگ کٔرِتھ باگٔرِتھ۔',
        ladakhi:
            'རྒྱུ་ཆ་རྣམས་ཨེཔ་ནང་དུ་པོསྚར་བཟོ་བའི་ཆེད་དུ་ཁོ་ན་ཆོག་ཐམ་ཡོད་ཅིང་། སོ་སོར་བཀར་ནས་བསྐྱར་བགོ་བྱེད་མི་ཆོག',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'రీఫండ్, రద్దు మరియు ఆటో-రెన్యూవల్',
        english: 'Refund, Cancellation, and Auto-Renewal',
        hindi: 'रिफंड, रद्दीकरण और ऑटो-नवीनीकरण',
        tamil:
            'பணத்தைத் திரும்பப்பெறுதல், ரத்துசெய்தல் மற்றும் தானியங்கி புதுப்பித்தல்',
        kannada: 'ಮರುಪಾವತಿ, ರದ್ದತಿ ಮತ್ತು ಸ್ವಯಂ ನವೀಕರಣ',
        malayalam: 'റീഫണ്ട്, റദ്ദാക്കൽ, സ്വയം പുതുക്കൽ',
        marathi: 'परतावा, रद्द करणे आणि स्वयं-नूतनीकरण',
        gujarati: 'રિફંડ, રદ અને ઓટો-રીન્યુઅલ',
        bengali: 'ফেরত, বাতিলকরণ এবং স্বয়ংক্রিয় পুনর্নবীকরণ',
        punjabi: 'ਰਿਫੰਡ, ਰੱਦ ਕਰਨਾ ਅਤੇ ਸਵੈ-ਨਵੀਨੀਕਰਨ',
        odia: 'ଫେରସ୍ତ, ବାତିଲ୍ ଏବଂ ସ୍ୱୟଂକ୍ରିୟ ନବୀକରଣ',
        assamese: 'ধন ঘূৰাই পোৱা, বাতিল আৰু স্বয়ংক্ৰিয় নবীকৰণ',
        konkani: 'ರಿಫಂಡ್, ರದ್ದ್ ಕರ್ಚೆಂ ಆನಿ ಆಟೋ-ರಿನೀವಲ್',
        nepali: 'फिर्ता, रद्द र स्वतः नवीकरण',
        meitei: 'রিফন্দ, কেন্সেল অমসুং ওতো-রিনিউএল',
        mizo: 'Refund, Tihtawp leh Auto-Renewal',
        kashmiri: 'رِفَنٛڈ، منسوخی تہٕ آٹو رِنیوول',
        ladakhi: 'ཕྱིར་སློག ཕྱིར་འཐེན་དང་རང་འགུལ་གསར་བཟོ།',
      ),
      strings.localized(
        telugu:
            'సబ్‌స్క్రిప్షన్ రద్దు మీ Google Play Store ఖాతా సెట్టింగ్స్ ద్వారా నిర్వహించబడుతుంది. రద్దు భవిష్యత్ రెన్యూవల్స్‌ను ఆపుతుంది.',
        english:
            'Subscription cancellation is generally managed through your Google Play Store account settings. Cancellation stops future renewals but does not retroactively refund elapsed subscription periods unless required by applicable law or store policy.',
        hindi:
            'सदस्यता रद्द करना Google Play Store खाता सेटिंग्स के माध्यम से प्रबंधित किया जाता है। रद्दीकरण भविष्य के नवीनीकरण को रोकता है।',
        tamil:
            'சந்தா ரத்து உங்கள் கூகிள் பிளே ஸ்டோர் கணக்கு அமைப்புகள் மூலம் நிர்வகிக்கப்படுகிறது. ரத்துசெய்தல் எதிர்கால புதுப்பித்தலை நிறுத்தும்.',
        kannada:
            'ಚಂದಾದಾರಿಕೆ ರದ್ದತಿಯನ್ನು Google Play Store ಸೆಟ್ಟಿಂಗ್ಸ್ ಮೂಲಕ ನಿರ್ವಹಿಸಲಾಗುತ್ತದೆ. ರದ್ದತಿಯು ಮುಂದಿನ ನವೀಕರಣಗಳನ್ನು ನಿಲ್ಲಿಸುತ್ತದೆ.',
        malayalam:
            'സബ്‌സ്‌ക്രിപ്ഷൻ റദ്ദാക്കൽ ഗൂഗിൾ പ്ലേ സ്റ്റോർ അക്കൗണ്ട് ക്രമീകരണങ്ങൾ വഴി നിയന്ത്രിക്കാം. റദ്ദാക്കൽ ഭാവി പുതുക്കലുകൾ തടയുന്നു.',
        marathi:
            'सदस्यता रद्द करणे Google Play Store खाते सेटिंग्जद्वारे व्यवस्थापित केले जाते. रद्द केल्याने भविष्यातील नूतनीकरण थांबते.',
        gujarati:
            'સબ્સ્ક્રિપ્શન રદ કરવાનું Google Play Store એકાઉન્ટ સેટિંગ્સ દ્વારા સંચાલિત થાય છે. રદ કરવાથી ભવિષ્યના નવીકરણ બંધ થાય છે.',
        bengali:
            'সাবস্ক্রিপশন বাতিলকরণ Google Play Store অ্যাকাউন্ট সেটিংসের মাধ্যমে পরিচালিত হয়। বাতিলকরণ ভবিষ্যতের পুনর্নবীকরণ বন্ধ করে।',
        punjabi:
            'ਗਾਹਕੀ ਰੱਦ ਕਰਨਾ Google Play Store ਖਾਤਾ ਸੈਟਿੰਗਾਂ ਰਾਹੀਂ ਪ੍ਰਬੰਧਿਤ ਕੀਤਾ ਜਾਂਦਾ ਹੈ। ਰੱਦ ਕਰਨ ਨਾਲ ਭਵਿੱਖ ਦੇ ਨਵੀਨੀਕਰਨ ਰੁਕ ਜਾਂਦੇ ਹਨ।',
        odia:
            'ସଦସ୍ୟତା ବାତିଲ୍ Google Play Store ଆକାଉଣ୍ଟ୍ ସେଟିଂସ ମାଧ୍ୟମରେ ପରିଚାଳିତ ହୁଏ। ବାତିଲ୍ ଭବିଷ୍ୟତର ନବୀକରଣକୁ ବନ୍ଦ କରେ।',
        assamese:
            'গ্ৰাহকভুক্তি বাতিলকৰণ Google Play Store একাউণ্ট ছেটিংছৰ জৰিয়তে পৰিচালিত হয়। বাতিলে ভৱিষ্যতৰ নবীকৰণ বন্ধ কৰে।',
        konkani:
            'ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ ರದ್ದ್ ಕರ್ಚೆಂ Google Play Store ಖಾತೆಂ ಸೆಟ್ಟಿಂಗ್ಸ್ ಮುಖಾಂತ್ರ್ ಜಾತಾ. ರದ್ದ್ ಕೆಲ್ಯಾರ್ ಮುಕ್ಲೆಂ ರಿನೀವಲ್ ರಾವ್ತಾ.',
        nepali:
            'सदस्यता रद्द गर्ने कार्य Google Play Store खाता सेटिङहरू मार्फत व्यवस्थित गरिन्छ। रद्द गर्नाले भविष्यका नवीकरणहरू रोकिन्छ।',
        meitei:
            'সবস্ক্রিপ্সন কেন্সেল তৌবা অসি Google Play Store একাউন্ত সেতিংসকী মতেংনা তৌই। কেন্সেল তৌবনা তুংগী রিনিউএলশিং থিংই।',
        mizo:
            'Subscription tihtawp chu Google Play Store account settings atanga tih theih a ni. Tihtawp hian renewal a tihtawp rualin refund a keng tel lo.',
        kashmiri:
            'سبسکرپشن منسوخی چھِ Google Play Store کھاتہٕ سیٹنگس ذٔریعہٕ گَژھان۔ منسوخی سٟتؠ چھِ برٛونٛہِم رِنیوول رُکان।',
        ladakhi:
            'མངགས་ཉོ་ཕྱིར་འཐེན་ནི་ Google Play Store ཐོ་ཁའི་སྒྲིག་འཛུགས་བརྒྱུད་ནས་བྱེད། ཕྱིར་འཐེན་གྱིས་མ་འོངས་པའི་གསར་བཟོ་རྣམས་འགོག་གོ།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'రిఫరల్ రివార్డులు',
        english: 'Referral Rewards',
        hindi: 'रेफरल पुरस्कार',
        tamil: 'பரிந்துரை வெகுமதிகள்',
        kannada: 'ರೆಫರಲ್ ಬಹುಮಾನಗಳು',
        malayalam: 'റഫറൽ റിവാർഡുകൾ',
        marathi: 'रेफरल रिवॉर्ड्स',
        gujarati: 'રેફરલ પુરસ્કારો',
        bengali: 'রেফারেল পুরস্কার',
        punjabi: 'ਰੈਫਰਲ ਇਨਾਮ',
        odia: 'ରେଫରାଲ୍ ପୁରସ୍କାର',
        assamese: 'ৰেফাৰেল পুৰস্কাৰ',
        konkani: 'ರೆಫರಲ್ ಇನಾಮಾಂ',
        nepali: 'रेफरल पुरस्कारहरू',
        meitei: 'রিফরল রিৱার্দশিং',
        mizo: 'Referral lawmman',
        kashmiri: 'ریفرل اِنعامات',
        ladakhi: 'ངོ་སྤྲོད་བྱ་དགའ།',
      ),
      strings.localized(
        telugu:
            'Mana Poster Ai రిఫరల్ రివార్డ్ అనేది ఒక ప్రమోషనల్ ప్రయోజనం. దుర్వినియోగం లేదా మోసపూరిత రిఫరల్స్ జరిగినట్లు గుర్తిస్తే రివార్డులు రద్దు చేయబడతాయి.',
        english:
            'The Mana Poster Ai referral reward is a promotional benefit subject to change, eligibility rules, and withdrawal at our discretion. Abuse or fraudulent referrals will result in disqualification.',
        hindi:
            'Mana Poster Ai रेफरल इनाम एक प्रचार लाभ है। दुरुपयोग या धोखाधड़ी वाले रेफरल के परिणामस्वरूप अयोग्यता होगी।',
        tamil:
            'பரிந்துரை வெகுமதி என்பது ஒரு விளம்பர சலுகையாகும். முறைகேடு அல்லது மோசடி பரிந்துரைகள் தகுதி நீக்கத்திற்கு வழிவகுக்கும்.',
        kannada:
            'ರೆಫರಲ್ ಬಹುಮಾನವು ಒಂದು ಪ್ರಚಾರದ ಪ್ರಯೋಜನವಾಗಿದೆ. ದುರುಪಯೋಗ ಅಥವಾ ಮೋಸದ ರೆಫರಲ್‌ಗಳು ಅನರ್ಹತೆಗೆ ಕಾರಣವಾಗುತ್ತವೆ.',
        malayalam:
            'റഫറൽ റിവാർഡ് ഒരു പ്രമോഷണൽ ആനുകൂല്യമാണ്. ദുരുപയോഗം അല്ലെങ്കിൽ വ്യാജ റഫറലുകൾ അയോഗ്യതയ്ക്ക് കാരണമാകും.',
        marathi:
            'रेफरल रिवॉर्ड हा एक प्रचारात्मक लाभ आहे. गैरवापर किंवा फसव्या रेफरल्समुळे अपात्रता ठरवली जाईल.',
        gujarati:
            'રેફરલ પુરસ્કાર એ પ્રમોશનલ લાભ છે. દુરુપયોગ અથવા છેતરપિંડીવાળા રેફરલ્સ અયોગ્યતામાં પરિણમશે.',
        bengali:
            'রেফারেল পুরস্কার একটি প্রচারমূলক সুবিধা। অপব্যবহার বা প্রতারণামূলক রেফারেলের ফলে অযোগ্যতা হতে পারে।',
        punjabi:
            'ਰੈਫਰਲ ਇਨਾਮ ਇੱਕ ਪ੍ਰਚਾਰਕ ਲਾਭ ਹੈ। ਦੁਰਵਰਤੋਂ ਜਾਂ ਧੋਖਾਧੜੀ ਵਾਲੇ ਰੈਫਰਲ ਅਯੋਗਤਾ ਦਾ ਕਾਰਨ ਬਣਨਗੇ।',
        odia:
            'ରେଫରାଲ୍ ପୁରସ୍କାର ଏକ ପ୍ରଚାରମୂଳକ ଲାଭ। ଅପବ୍ୟବହାର ବା ପ୍ରତାରଣାମୂଳକ ରେଫରାଲ୍ ଅଯୋଗ୍ୟତା ହେବ।',
        assamese:
            'ৰেফাৰেল পুৰস্কাৰ হৈছে এক প্ৰচাৰমূলক সুবিধা। অপব্যৱহাৰ বা ভুৱা ৰেফাৰেলৰ ফলত অযোগ্য বিবেচিত হʼব।',
        konkani:
            'ರೆಫರಲ್ ಇನಾಮ್ ಏಕ್ ಪ್ರಚಾರಾಚೊ ಫಾಯ್ದೊ. ಫಟವ್ಣೆಚೆ ರೆಫರಲ್ಸ್ ಅನ್ಹರ್ಹ್ ಜಾತಾತ್.',
        nepali:
            'रेफरल पुरस्कार एक प्रचार लाभ हो। दुरुपयोग वा धोखाधडी रेफरलहरू अयोग्यतामा परिणत हुनेछ।',
        meitei:
            'রিফরল রিৱার্দ অসি প্রমোস্নেল কান্নবা অমনি। অরানবা মওংদা শীজিন্নরবদি মসি ককথৎকনি।',
        mizo:
            'Referral lawmman hi promotional benefit a ni a. Hman khawloh emaw bumna lakah hnawl a ni ang.',
        kashmiri:
            'ریفرل اِنعام چھُ اَکھ پروموشنل فٲئدٕ۔ غَلَط اِستعمال یا دھوکہ دہی پؠٹھ گَژھِ نا اَہل قرار دِنہٕ۔',
        ladakhi:
            'ངོ་སྤྲོད་བྱ་དགའ་ནི་ཁྱབ་བསྒྲགས་ཀྱི་ཁེ་ཕན་ཞིག་ཡིན། མགོ་སྐོར་གྱི་ངོ་སྤྲོད་བྱས་ན་ཐོབ་ཐང་མེད་པར་བཟོའོ།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ప్రకటనలు మరియు మూడవ పక్ష సేవలు',
        english: 'Ads and Third-Party Services',
        hindi: 'विज्ञापन और तृतीय-पक्ष सेवाएं',
        tamil: 'விளம்பரங்கள் மற்றும் மூன்றாம் தரப்பு சேவைகள்',
        kannada: 'ಜಾಹೀರಾತುಗಳು ಮತ್ತು ಮೂರನೇ ವ್ಯಕ್ತಿಯ ಸೇವೆಗಳು',
        malayalam: 'പരസ്യങ്ങളും മൂന്നാം കക്ഷി സേവനങ്ങളും',
        marathi: 'जाहिराती आणि तृतीय-पक्ष सेवा',
        gujarati: 'જાહેરાતો અને તૃતીય-પક્ષ સેવાઓ',
        bengali: 'বিজ্ঞাপন এবং তৃতীয় পক্ষের পরিষেবা',
        punjabi: 'ਇਸ਼ਤਿਹਾਰ ਅਤੇ ਤੀਜੀ-ਧਿਰ ਸੇਵਾਵਾਂ',
        odia: 'ବିଜ୍ଞାପନ ଏବଂ ତୃତୀୟ ପକ୍ଷ ସେବା',
        assamese: 'বিজ্ঞাপন আৰু তৃতীয় পক্ষৰ সেৱাসমূহ',
        konkani: 'ಜಾಹಿರಾತಾಂ ಆನಿ ತಿಸ್ರ್ಯಾ ಪಕ್ಷಾಚ್ಯೊ ಸೆವಾ',
        nepali: 'विज्ञापन र तेस्रो-पक्ष सेवाहरू',
        meitei: 'এদভর্তাইজমেন্তশিং অমসুং অহুমশুবা পার্তিগী সর্ভিসশিং',
        mizo: 'Ads leh Third-Party Services',
        kashmiri: 'اشتہارات تہٕ ترٛیٚیِم پارٹِی ہٕنٛز خدمات',
        ladakhi: 'ཁྱབ་བསྒྲགས་དང་ཕྱོགས་གསུམ་པའི་ཞབས་ཞུ།',
      ),
      strings.localized(
        telugu:
            'యాప్‌లో AdMob ప్రకటనలు కనిపించవచ్చు. మూడవ పక్ష ప్రకటనదారులు ప్రచారం చేసే ఉత్పత్తులు లేదా సేవలకు మేము బాధ్యత వహించము.',
        english:
            'The app may display AdMob ads, including rewarded ads that can unlock extra features. We are not responsible for the products, services, or claims advertised by third-party advertisers.',
        hindi:
            'ऐप AdMob विज्ञापन प्रदर्शित कर सकता है। हम तीसरे पक्ष के विज्ञापनदाताओं द्वारा विज्ञापित उत्पादों या सेवाओं के लिए ज़िम्मेदार नहीं हैं।',
        tamil:
            'செயலி AdMob விளம்பரங்களைக் காட்டலாம். விளம்பரதாரர்களின் தயாரிப்புகள் அல்லது சேவைகளுக்கு நாங்கள் பொறுப்பல்ல.',
        kannada:
            'ಆ್ಯಪ್ AdMob ಜಾಹೀರಾತುಗಳನ್ನು ಪ್ರದರ್ಶಿಸಬಹುದು. ಮೂರನೇ ವ್ಯಕ್ತಿಯ ಜಾಹೀರಾತುದಾರರ ಉತ್ಪನ್ನಗಳು ಅಥವಾ ಸೇವೆಗಳಿಗೆ ನಾವು ಜವಾಬ್ದಾರರಲ್ಲ.',
        malayalam:
            'ആപ്പിൽ ആഡ്‌മോബ് പരസ്യങ്ങൾ കാണിച്ചേക്കാം. മൂന്നാം കക്ഷി പരസ്യക്കാരുടെ ഉൽപ്പന്നങ്ങൾക്കോ സേവനങ്ങൾക്കോ ഞങ്ങൾ ഉത്തരവാദികളല്ല.',
        marathi:
            'अ‍ॅप AdMob जाहिराती प्रदर्शित करू शकते. तृतीय-पक्ष जाहिरातदारांच्या उत्पादनांसाठी आम्ही जबाबदार नाही.',
        gujarati:
            'એપ AdMob જાહેરાતો પ્રદર્શિત કરી શકે છે. અમે તૃતીય-પક્ષ જાહેરાતકર્તાઓના ઉત્પાદનો માટે જવાબદાર નથી.',
        bengali:
            'অ্যাপটি AdMob বিজ্ঞাপন প্রদর্শন করতে পারে। তৃতীয় পক্ষের বিজ্ঞাপনদাতাদের পণ্যের জন্য আমরা দায়ী নই।',
        punjabi:
            'ਐਪ AdMob ਇਸ਼ਤਿਹਾਰ ਦਿਖਾ ਸਕਦੀ ਹੈ। ਅਸੀਂ ਤੀਜੀ ਧਿਰ ਦੇ ਇਸ਼ਤਿਹਾਰ ਦੇਣ ਵਾਲਿਆਂ ਦੇ ਉਤਪਾਦਾਂ ਲਈ ਜ਼ਿੰਮੇਵਾਰ ਨਹੀਂ ਹਾਂ।',
        odia:
            'ଆପ୍ AdMob ବିଜ୍ଞାପନ ପ୍ରଦର୍ଶନ କରିପାରେ। ତୃତୀୟ ପକ୍ଷ ବିଜ୍ଞାପନଦାତାଙ୍କ ଉତ୍ପାଦ ପାଇଁ ଆମେ ଦାୟୀ ନୁହଁ।',
        assamese:
            'এপে AdMob বিজ্ঞাপন প্ৰদৰ্শন কৰিব পাৰে। তৃতীয় পক্ষৰ বিজ্ঞাপনদাতাসকলৰ সামগ্ৰীৰ বাবে আমি দায়ী নহয়।',
        konkani:
            'ಆ್ಯಪ್ AdMob ಜಾಹಿರಾತಾಂ ದಾಕಂವ್ಕ್ ಸಕ್ತಾ. ತಿಸ್ರ್ಯಾ ಪಕ್ಷಾಚ್ಯಾ ಜಾಹೀರಾತ್ ವಸ್ತುಂಕ್ ಆಮಿ ಜವಾಬ್ದಾರ್ ನ್ಹಯ್.',
        nepali:
            'एपले AdMob विज्ञापनहरू प्रदर्शन गर्न सक्छ। हामी तेस्रो-पक्ष विज्ञापनदाताहरूका उत्पादनहरूका लागि जिम्मेवार छैनौं।',
        meitei:
            'এপ অসিনা AdMob এদশিং উৎপা য়াই। অহুমশুবা পার্তিগী প্রমোসনশিংগীদমক ঐখোয়না থৌদাং লৌদে।',
        mizo:
            'App hian AdMob ads a tilang thei. Third-party advertiser-te thil zawrh chungchangah mawh kan phur lo.',
        kashmiri:
            'ایپھ ہیکہِ AdMob اشتہارات ہٲوِتھ। أسی چھِ نہٕ ترٛیٚیِمہِ پارٹِی ہٕنٛدی کُنہِ تہِ پروڈکٹَس باپتھ زِمہٕ دار۔',
        ladakhi:
            'ཨེཔ་འདིས་ AdMob ཁྱབ་བསྒྲགས་སྟོན་སྲིད། ང་ཚོས་ཕྱོགས་གསུམ་པའི་ཚོང་ཟོང་ལ་འགན་མི་ཁུར།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఖాతా తొలగింపు మరియు పరికర యాక్సెస్',
        english: 'Account Deletion and Device Access',
        hindi: 'खाता हटाना और डिवाइस एक्सेस',
        tamil: 'கணக்கு நீக்கம் மற்றும் சாதன அணுகல்',
        kannada: 'ಖಾತೆ ಅಳಿಸುವಿಕೆ ಮತ್ತು ಸಾಧನ ಪ್ರವೇಶ',
        malayalam: 'അക്കൗണ്ട് ഇല്ലാതാക്കലും ഉപകരണ ആക്സസും',
        marathi: 'खाते हटवणे आणि डिव्हाइस अ‍ॅक्सेस',
        gujarati: 'એકાઉન્ટ ડિલીટ અને ડિવાઇસ એક્સેસ',
        bengali: 'অ্যাকাউন্ট মুছে ফেলা এবং ডিভাইস অ্যাক্সেস',
        punjabi: 'ਖਾਤਾ ਮਿਟਾਉਣਾ ਅਤੇ ਡਿਵਾਈਸ ਪਹੁੰਚ',
        odia: 'ଆକାଉଣ୍ଟ୍ ବିଲୋପ ଏବଂ ଡିଭାଇସ୍ ପ୍ରବେଶ',
        assamese: 'একাউণ্ট বিলোপ আৰু ডিভাইচ প্ৰৱেশ',
        konkani: 'ಖಾತೆಂ ಕಾಡ್ಚೆಂ ಆನಿ ಡಿವೈಸ್ ಪ್ರವೇಶ್',
        nepali: 'खाता मेटाउने र उपकरण पहुँच',
        meitei: 'একাউন্ত মুথত্পা অমসুং দিভাইস এক্সেস',
        mizo: 'Account paihna leh device hman theihna',
        kashmiri: 'کھاتہٕ مِٹاوُن تہٕ ڈِوائس اینٹری',
        ladakhi: 'ཐོ་ཁ་སུབ་པ་དང་ཡོ་ཆས་ལྟ་ཀློག',
      ),
      strings.localized(
        telugu:
            'యాప్‌లో ఖాతా తొలగింపు అభ్యర్థన సదుపాయం ఉంది. తొలగింపు పూర్తయిన తర్వాత మీ ప్రొఫైల్ వివరాలు మరియు అప్‌లోడ్ డేటా తిరిగి పొందలేరు.',
        english:
            'The app provides an account deletion request option. After deletion is completed, your account access, profile text, cutout data, and upload history cannot be recovered.',
        hindi:
            'ऐप खाता हटाने का विकल्प प्रदान करता है। हटाए जाने के बाद आपका प्रोफ़ाइल विवरण और अपलोड इतिहास पुनर्પ્રાપ્ત नहीं किया जा सकता।',
        tamil:
            'செயலியில் கணக்கை நீக்கும் வசதி உள்ளது. நீக்கப்பட்ட பிறகு சுயவிவரத் தரவு மற்றும் பதிவேற்றங்களை மீட்டெடுக்க முடியாது.',
        kannada:
            'ಆ್ಯಪ್ ಖಾತೆ ಅಳಿಸುವ ಆಯ್ಕೆಯನ್ನು ಒದಗಿಸುತ್ತದೆ. ಅಳಿಸುವಿಕೆ ಪೂರ್ಣಗೊಂಡ ನಂತರ ಪ್ರೊಫೈಲ್ ಡೇಟಾವನ್ನು ಮರಳಿ ಪಡೆಯಲಾಗುವುದಿಲ್ಲ.',
        malayalam:
            'അക്കൗണ്ട് ഡിലീറ്റ് ചെയ്യാനുള്ള സൗകര്യം ആപ്പിലുണ്ട്. പൂർത്തിയായ ശേഷം പ്രൊഫൈൽ വിവരങ്ങൾ വീണ്ടെടുക്കാനാകില്ല.',
        marathi:
            'अ‍ॅप खाते हटवण्याचा पर्याय प्रदान करते. हटवल्यानंतर तुमचा प्रोफाइल डेटा पुनर्प्राप्त केला जाऊ शकत नाही.',
        gujarati:
            'એપ એકાઉન્ટ ડિલીટ કરવાનો વિકલ્પ પૂરો પાડે છે. ડિલીટ થયા પછી પ્રોફાઇલ ડેટા પુનઃપ્રાપ્ત કરી શકાતો નથી.',
        bengali:
            'অ্যাপটিতে অ্যাকাউন্ট মুছে ফেলার বিকল্প রয়েছে। মুছে ফেলার পরে প্রোফাইল ডেটা পুনরুদ্ধার করা যাবে না।',
        punjabi:
            'ਐਪ ਖਾਤਾ ਮਿਟਾਉਣ ਦਾ ਵਿਕਲਪ ਦਿੰਦੀ ਹੈ। ਮਿਟਾਉਣ ਤੋਂ ਬਾਅਦ ਪ੍ਰੋਫਾਈਲ ਡੇਟਾ ਮੁੜ ਪ੍ਰਾਪਤ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਦਾ।',
        odia:
            'ଆପ୍ ଆକାଉଣ୍ଟ୍ ବିଲୋପ ବିକଳ୍ପ ପ୍ରଦାନ କରେ। ବିଲୋପ ପରେ ପ୍ରୋଫାଇଲ୍ ଡାଟା ପୁନରୁଦ୍ଧାର କରାଯାଇପାରିବ ନାହିଁ।',
        assamese:
            'এপে একাউণ্ট বিলোপৰ বিকল্প প্ৰদান কৰে। বিলোপৰ পাছত প্ৰʼফাইল তথ্য পুনৰুদ্ধাৰ কৰিব নোৱাৰি।',
        konkani:
            'ಆ್ಯಪಾಂತ್ ಖಾತೆಂ ಕಾಡ್ಚೊ ಆಯ್ಕೊ ಆಸಾ. ಕಾಡ್ಲ್ಯಾ ಉಪ್ರಾಂತ್ ಪ್ರೊಫೈಲ್ ಡೇಟಾ ಪರತ್ ಮೆಳೊಂಕ್ ಸಾಧ್ಯ್ ನಾ.',
        nepali:
            'एपले खाता मेटाउने विकल्प प्रदान गर्दछ। मेटाएपछि प्रोफाइल डाटा पुन: प्राप्ति गर्न सकिँदैन।',
        meitei:
            'এপ অসিনা একাউন্ত মুথত্নবা ওপসন পীরি। মসি তৌরবা মতুংদা প্রোফাইল দেতা অমুক হন্না ফংবা ঙমলোই।',
        mizo:
            'Account paihna a awm a, paih a nih hnuah profile data leh upload-te laklet leh theih a ni tawh lo.',
        kashmiri:
            'ایپھ چھُ کھاتہٕ مِٹاونُک اِنتخاب دِوان। مِٹاونہٕ پتہٕ ہیکو نہٕ پروفائل ڈیٹا واپس ہؠتھ۔',
        ladakhi:
            'ཨེཔ་འདིར་ཐོ་ཁ་སུབ་པའི་འདེམས་ཁ་ཡོད། སུབ་ཟིན་རྗེས་གསལ་བཤད་གྲངས་གཞི་རྣམས་སླར་གསོ་བྱེད་མི་ཐུབ།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'కమ్యూనిటీ అప్‌లోడ్‌లు, మోడరేషన్ మరియు రిపోర్టింగ్',
        english: 'Community Uploads, Moderation, and Reporting',
        hindi: 'कम्युनिटी अपलोड, मॉडरेशन और रिपोर्टिंग',
        tamil: 'சமூக பதிவேற்றங்கள், தணிக்கை மற்றும் புகாரளித்தல்',
        kannada: 'ಸಮುದಾಯ ಅಪ್‌ಲೋಡ್‌ಗಳು, ಮಾಡರೇಶನ್ ಮತ್ತು ವರದಿ',
        malayalam: 'കമ്മ്യൂണിറ്റി അപ്‌ലോഡുകൾ, മോഡറേഷൻ, റിപ്പോർട്ടിംഗ്',
        marathi: 'कम्युनिटी अपलोड, मॉडरेशन आणि रिपोर्टिंग',
        gujarati: 'કમ્યુનિટી અપલોડ્સ, મોડરેશન અને રિપોર્ટિંગ',
        bengali: 'কমিউনিটি আপলোড, সংযম এবং রিপোর্টিং',
        punjabi: 'ਕਮਿਊਨਿਟੀ ਅੱਪਲੋਡ, ਸੰਜਮ ਅਤੇ ਰਿਪੋਰਟਿੰਗ',
        odia: 'କମ୍ୟୁନିଟି ଅପଲୋଡ୍, ମଡରେସନ୍ ଏବଂ ରିପୋର୍ଟିଂ',
        assamese: 'সম্প্ৰদায় আপলোড, সংযম আৰু ৰিপৰ্টিং',
        konkani: 'ಕಮ್ಯುನಿಟಿ ಅಪ್‌ಲೋಡ್ಸ್, ಮಾಡರೇಶನ್ ಆನಿ ರಿಪೋರ್ಟಿಂಗ್',
        nepali: 'समुदाय अपलोड, मध्यस्थता र रिपोर्टिङ',
        meitei: 'কম্যুনিতি অপলোদশিং, মোদরেসন অমসুং রিপোর্তিং',
        mizo: 'Community uploads, moderation leh reporting',
        kashmiri: 'کمیونٹی اَپلوڈ، نِگرانی تہٕ رِپورٹ کَرُن',
        ladakhi: 'མི་སྡེའི་ཡར་འཇུག དོ་དམ་དང་སྙན་ཞུ།',
      ),
      strings.localized(
        telugu:
            'కమ్యూనిటీ సమర్పణలను మేనేజర్లు సమీక్షించి ప్రచురిస్తారు. నిబంధనలను ఉల్లంఘించే కంటెంట్‌ను తొలగించే అధికారం మాకు ఉంది.',
        english:
            'Users may submit an image, quote text, or both for manager review. Managers may review, customize, approve, reject, or remove community content. Inappropriate submissions may result in suspension.',
        hindi:
            'उपयोगकर्ता समीक्षा के लिए सामग्री सबमिट कर सकते हैं। प्रबंधकों को अनुचित सामग्री को हटाने या अस्वीकार करने का अधिकार है।',
        tamil:
            'பயனர்கள் மதிப்பாய்வுக்கு உள்ளடக்கத்தை அனுப்பலாம். விதிமீறல் உள்ளடக்கத்தை அகற்ற மேலாளர்களுக்கு உரிமை உண்டு.',
        kannada:
            'ಬಳಕೆದಾರರು ಪರಿಶೀಲನೆಗೆ ವಿಷಯ ಸಲ್ಲಿಸಬಹುದು. ನಿಯಮಗಳನ್ನು ಉಲ್ಲಂಘಿಸುವ ವಿಷಯವನ್ನು ತೆಗೆದುಹಾಕುವ ಹಕ್ಕು ಮ್ಯಾನೇಜರ್‌ಗೆ ಇರುತ್ತದೆ.',
        malayalam:
            'പരിശോധനയ്ക്കായി ഉള്ളടക്കം സമർപ്പിക്കാം. നിബന്ധനകൾ ലംഘിക്കുന്നവ നീക്കം ചെയ്യാൻ മാനേജർമാർക്ക് അധികാരമുണ്ട്.',
        marathi:
            'वापरकर्ते पुनरावलोकनासाठी सामग्री सबमिट करू शकतात. नियम मोडणारी सामग्री काढून टाकण्याचा अधिकार व्यवस्थापकांकडे आहे.',
        gujarati:
            'વપરાશકર્તાઓ સમીક્ષા માટે સામગ્રી સબમિટ કરી શકે છે. અયોગ્ય સામગ્રી દૂર કરવાનો અધિકાર સંચાલકો પાસે છે.',
        bengali:
            'ব্যবহারকারীরা পর্যালোচনার জন্য সামগ্রী জমা দিতে পারেন। অনুপযুক্ত সামগ্রী প্রত্যাখ্যান করার অধিকার রয়েছে।',
        punjabi:
            'ਵਰਤੋਂਕਾਰ ਸਮੀਖਿਆ ਲਈ ਸਮੱਗਰੀ ਜਮ੍ਹਾਂ ਕਰ ਸਕਦੇ ਹਨ। ਨਿਯਮ ਤੋੜਨ ਵਾਲੀ ਸਮੱਗਰੀ ਨੂੰ ਹਟਾਉਣ ਦਾ ਅਧਿਕਾਰ ਹੈ।',
        odia:
            'ବ୍ୟବହାରକାରୀମାନେ ସମୀକ୍ଷା ପାଇଁ ବିଷୟବସ୍ତୁ ଦାଖଲ କରିପାରିବେ। ନିୟମ ଉଲ୍ଲଂଘନ କରୁଥିବା ବିଷୟବସ୍ତୁକୁ ହଟାଇବାକୁ ଅଧିକାର ଅଛି।',
        assamese:
            'ব্যৱহাৰকাৰীসকলে পৰ্যালোচনাৰ বাবে বিষয়বস্তু জমা দিব পাৰে। নিয়ম ভংগ কৰা বিষয়বস্তু আঁতৰোৱাৰ অধিকাৰ মেনেজাৰৰ আছে।',
        konkani:
            'ಬಳಕೆದಾರ್ ತಪಾಸ್ಣೆಕ್ ಕಂಟೆಂಟ್ ಧಾಡುಂಕ್ ಸಕ್ತಾತ್. ನಿಯಮ್ ಮೊಡ್ಚೆಂ ಕಂಟೆಂಟ್ ಕಾಡ್ಚೊ ಹಕ್ಕ್ ಆಸಾ.',
        nepali:
            'प्रयोगकर्ताहरूले समीक्षाको लागि सामग्री पेश गर्न सक्छन्। अनुपयुक्त सामग्री हटाउने अधिकार प्रबन्धकहरूसँग छ।',
        meitei:
            'য়ুজরশিংনা রিভ্যুগীদমক কন্তেন্ত থাবা য়াই। চুনদবা কন্তেন্তশিং লৌথোকপগী হক মেনেজরশিংদা লৈ।',
        mizo:
            'Manager endik turin thil thehluh theih a ni. Dan kalh thil chu paih emaw hnawl theih a ni.',
        kashmiri:
            'صارِف ہؠکن ریویو باپتھ مواد سوزِتھ۔ نازیبا مواد ہٹاونُک اِختیار چھُ مینیجرَن ہُنٛد۔',
        ladakhi:
            'སྤྱོད་པ་པོ་རྣམས་ཀྱིས་ཞིབ་བཤེར་དོན་དུ་ནང་དོན་གཏོང་ཐུབ། མི་འོས་པའི་ནང་དོན་རྣམས་ཕྱིར་འདོན་བྱེད་པའི་ཐོབ་ཐང་དོ་དམ་པར་ཡོད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'పరికర యాక్సెస్ మరియు సెషన్‌లు',
        english: 'Device Access and Sessions',
        hindi: 'डिवाइस एक्सेस और सत्र',
        tamil: 'சாதன அணுகல் மற்றும் அமர்வுகள்',
        kannada: 'ಸಾಧನ ಪ್ರವೇಶ ಮತ್ತು ಸೆಷನ್‌ಗಳು',
        malayalam: 'ഉപകരണ ആക്സസും സെഷനുകളും',
        marathi: 'डिव्हाइस अ‍ॅक्सेस आणि सेशन्स',
        gujarati: 'ડિવાઇસ એક્સેસ અને સત્રો',
        bengali: 'ডিভাইস অ্যাক্সেস এবং সেশন',
        punjabi: 'ਡਿਵਾਈਸ ਪਹੁੰਚ ਅਤੇ ਸੈਸ਼ਨ',
        odia: 'ଡିଭାଇସ୍ ପ୍ରବେଶ ଏବଂ ସେସନ୍',
        assamese: 'ডিভাইচ প্ৰৱেশ আৰু অধিৱেশন',
        konkani: 'ಡಿವೈಸ್ ಪ್ರವೇಶ್ ಆನಿ ಸೆಶನ್ಸ್',
        nepali: 'उपकरण पहुँच र सत्रहरू',
        meitei: 'দিভাইস এক্সেস অমসুং সেসনশিং',
        mizo: 'Device hman theihna leh session',
        kashmiri: 'ڈِوائس اینٹری تہٕ سیشن',
        ladakhi: 'ཡོ་ཆས་ལྟ་ཀློག་དང་དུས་ཡུན།',
      ),
      strings.localized(
        telugu:
            'ఖాతా భద్రత కోసం, ఒక ఖాతా ఒకేసారి ఒక పరికరంలో మాత్రమే యాక్టివ్‌గా ఉంటుంది. కొత్త పరికరంలో లాగిన్ అవ్వడం వల్ల పాత పరికరం నుండి లాగౌట్ అవుతుంది.',
        english:
            'For account security, one account may remain active on only one device at a time. Signing in on a new device may sign you out of earlier devices.',
        hindi:
            'खाता सुरक्षा के लिए, एक खाता एक समय में केवल एक डिवाइस पर सक्रिय रह सकता है। नए डिवाइस पर साइन इन करने से पुराने डिवाइस से लॉग आउट हो जाएगा।',
        tamil:
            'கணக்கு பாதுகாப்பிற்காக, ஒரு நேரத்தில் ஒரு சாதனத்தில் மட்டுமே கணக்கு செயலில் இருக்கும். புதிய சாதனத்தில் நுழைவது பழையதை வெளியேற்றும்.',
        kannada:
            'ಖಾತೆ ಸುರಕ್ಷತೆಗಾಗಿ, ಒಂದು ಖಾತೆಯು ಏಕಕಾಲದಲ್ಲಿ ಕೇವಲ ಒಂದು ಸಾಧನದಲ್ಲಿ ಮಾತ್ರ ಸಕ್ರಿಯವಾಗಿರುತ್ತದೆ.',
        malayalam:
            'അക്കൗണ്ട് സുരക്ഷയ്ക്കായി ഒരു അക്കൗണ്ട് ഒരു സമയം ഒരു ഉപകരണത്തിൽ മാത്രമേ സജീവമായിരിക്കൂ.',
        marathi:
            'खाते सुरक्षेसाठी, एका वेळी एकाच डिव्हाइसवर खाते सक्रिय राहू शकते. नवीन डिव्हाइसवर साइन इन केल्याने जुन्या डिव्हाइसवरून लॉग आउट होईल.',
        gujarati:
            'એકાઉન્ટ સુરક્ષા માટે, એક એકાઉન્ટ એક સમયે માત્ર એક જ ઉપકરણ પર સક્રિય રહી શકે છે.',
        bengali:
            'অ্যাকাউন্টের নিরাপত্তার জন্য, একটি অ্যাকাউন্ট এক সময়ে কেবল একটি ডিভাইসেই সক্রিয় থাকতে পারে।',
        punjabi:
            'ਖਾਤਾ ਸੁਰੱਖਿਆ ਲਈ, ਇੱਕ ਖਾਤਾ ਇੱਕ ਸਮੇਂ ਵਿੱਚ ਸਿਰਫ਼ ਇੱਕ ਡਿਵਾਈਸ ਤੇ ਕਿਰਿਆਸ਼ੀਲ ਰਹਿ ਸਕਦਾ ਹੈ।',
        odia:
            'ଆକାଉଣ୍ଟ୍ ସୁରକ୍ଷା ପାଇଁ, ଗୋଟିଏ ଆକାଉଣ୍ଟ୍ ଏକ ସମୟରେ କେବଳ ଗୋଟିଏ ଡିଭାଇସ୍‌ରେ ସକ୍ରିୟ ରହିପାରେ।',
        assamese:
            'একাউণ্ট সুৰক্ষাৰ বাবে, এটা একাউণ্ট একে সময়তে কেৱল এটা ডিভাইচতহে সক্ৰিয় থাকিব পাৰে।',
        konkani:
            'ಖಾತೆಂ ಸುರಕ್ಷಾ ಖಾತೀರ್, ಏಕ್ ಖಾತೆಂ ಏಕಾಚ್ ಡಿವೈಸಾರ್ ಆಕ್ಟಿವ್ ಆಸ್ತಾ.',
        nepali:
            'खाता सुरक्षाका लागि, एउटा खाता एक पटकमा एउटा उपकरणमा मात्र सक्रिय रहन सक्छ।',
        meitei:
            'একাউন্ত সেক্যুরিতিগীদমক, একাউন্ত অমনা অমুক্তদা দিভাইস অমদখক এক্তিব ওইগনি।',
        mizo:
            'Account him nan, account pakhat chu device pakhatah chauh a nung thei ang.',
        kashmiri:
            'کھاتہٕ حِفاظَت باپتھ ہیکہِ اَکھ کھاتہٕ صِرَف اکہِ وِزِ اکہِ ڈِوائسَس پؠٹھ چالوٗ رٲزِتھ۔',
        ladakhi:
            'ཐོ་ཁའི་བདེ་འཇགས་ཆེད། ཐོ་ཁ་གཅིག་དུས་གཅིག་ལ་ཡོ་ཆས་གཅིག་ཁོ་ནའི་ནང་སྤྱོད་ཐུབ།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సేవా మార్పులు మరియు బాధ్యత పరిమితి',
        english: 'Service Changes and Limitation of Liability',
        hindi: 'सेवा परिवर्तन और दायित्व की सीमा',
        tamil: 'சேவை மாற்றங்கள் மற்றும் பொறுப்பு வரம்பு',
        kannada: 'ಸೇವಾ ಬದಲಾವಣೆಗಳು ಮತ್ತು ಹೊಣೆಗಾರಿಕೆಯ ಮಿತಿ',
        malayalam: 'സേവന മാറ്റങ്ങളും ബാധ്യത പരിമിതിയും',
        marathi: 'सेवा बदल आणि दायित्वाची मर्यादा',
        gujarati: 'સેવા ફેરફારો અને જવાબદારીની મર્યાદા',
        bengali: 'পরিষেবা পরিবর্তন এবং দায়বদ্ধতার সীমাবদ্ধতা',
        punjabi: 'ਸੇਵਾ ਤਬਦੀਲੀਆਂ ਅਤੇ ਦੇਣਦਾਰੀ ਦੀ ਸੀਮਾ',
        odia: 'ସେବା ପରିବର୍ତ୍ତନ ଏବଂ ଦାୟିତ୍ୱର ସୀମା',
        assamese: 'সেৱা পৰিৱৰ্তন আৰু দায়বদ্ধতাৰ সীমাবদ্ধতা',
        konkani: 'ಸೆವಾ ಬದ್ಲಾವಣಾಂ ಆನಿ ಜವಾಬ್ದಾರಿಚಿ ಮರ್ಯಾದ್',
        nepali: 'सेवा परिवर्तन र दायित्वको सीमा',
        meitei: 'সর্ভিসকী অহোংবশিং অমসুং দায়িত্বর লিমিৎ',
        mizo: 'Service inthlak danglam leh mawhphurhna bituk',
        kashmiri: 'سٔروِس تبدیٖلی تہٕ زِمہٕ وٲری ہٕنٛز حد',
        ladakhi: 'ཞབས་ཞུའི་བཟོ་བཅོས་དང་འགན་འཁྲིའི་ཚད་གཞི།',
      ),
      strings.localized(
        telugu:
            'ఫీచర్లు, ధరలు, డిజైన్లు మరియు సేవల లభ్యత ఎప్పటికప్పుడు మారవచ్చు. చట్టం అనుమతించిన మేరకు, సర్వీస్ ఎటువంటి హామీలు లేకుండా అందించబడుతుంది.',
        english:
            'Features, pricing, designs, assets, fonts, ads, editor tools, and service availability may change, be updated, or be discontinued. To the maximum extent permitted by law, the service is provided as-is without warranties.',
        hindi:
            'सुविधाएं, मूल्य निर्धारण, डिज़ाइन और उपलब्धता बदल सकती हैं। कानून द्वारा अनुमत अधिकतम सीमा तक, सेवा बिना किसी वारंटी के प्रदान की जाती है।',
        tamil:
            'அம்சங்கள், விலைகள் மற்றும் வடிவமைப்புகள் மாறக்கூடும். சட்டப்படி அனுமதிக்கப்பட்ட அளவிற்கு, சேவை உத்தரவாதங்களின்றி வழங்கப்படுகிறது.',
        kannada:
            'ವೈಶಿಷ್ಟ್ಯಗಳು, ಬೆಲೆಗಳು ಮತ್ತು ವಿನ್ಯಾಸಗಳು ಬದಲಾಗಬಹುದು. ಕಾನೂನಿನ ಅನುಮತಿಯಂತೆ, ಸೇವೆಯನ್ನು ಯಾವುದೇ ಖಾತರಿಯಿಲ್ಲದೆ ನೀಡಲಾಗುತ್ತದೆ.',
        malayalam:
            'ഫീച്ചറുകൾ, നിരക്കുകൾ, ഡിസൈനുകൾ എന്നിവ മാറിയേക്കാം. നിയമപരമായ പരിധിയിൽ, സേവനം വാറന്റികളൊന്നുമില്ലാതെ നൽകുന്നു.',
        marathi:
            'वैशिष्ट्ये, किंमती आणि डिझाईन्स बदलू शकतात. कायद्याने परवानगी दिलेल्या मर्यादेपर्यंत, सेवा कोणत्याही हमीशिवाय दिली जाते.',
        gujarati:
            'સુવિધાઓ, કિંમતો અને ડિઝાઇન બદલાઈ શકે છે. કાયદા દ્વારા અનુમતિ મુજબ, સેવા કોઈપણ વોરંટી વિના પૂરી પાડવામાં આવે છે.',
        bengali:
            'বৈশিষ্ট্য, মূল্য এবং ডিজাইন পরিবর্তিত হতে পারে। আইন অনুযায়ী, পরিষেবাটি কোনো ওয়ারেন্টি ছাড়াই প্রদান করা হয়।',
        punjabi:
            'ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ, ਕੀਮਤਾਂ ਅਤੇ ਡਿਜ਼ਾਈਨ ਬਦਲ ਸਕਦੇ ਹਨ। ਕਾਨੂੰਨ ਅਨੁਸਾਰ, ਸੇਵਾ ਬਿਨਾਂ ਕਿਸੇ ਵਾਰੰਟੀ ਦੇ ਪ੍ਰਦਾਨ ਕੀਤੀ ਜਾਂਦੀ ਹੈ।',
        odia:
            'ବୈଶିଷ୍ଟ୍ୟ, ମୂଲ୍ୟ ଏବଂ ଡିଜାଇନ୍ ପରିବର୍ତ୍ତନ ହୋଇପାରେ। ଆଇନ ଅନୁଯାୟୀ, ସେବା କୌଣସି ୱାରେଣ୍ଟି ବିନା ପ୍ରଦାନ କରାଯାଏ।',
        assamese:
            'সুবিধাসমূহ, মূল্য আৰু ডিজাইন সলনি হʼব পাৰে। আইন অনুসৰি, এই সেৱা কোনো ৱাৰেণ্টি অবিহনে প্ৰদান কৰা হয়।',
        konkani:
            'ವೈಶಿಷ್ಟ್ಯಾಂ, ದರ್ ಆನಿ ಡಿಸೈನ್ಸ್ ಬದ್ಲುಂಕ್ ಸಕ್ತಾತ್. ಕಾಯ್ದ್ಯಾ ಪರ್ಮಾಣೆಂ, ಸರ್ವಿಸ್ ಖಾತರಿ ನಾಸ್ತಾನಾ ದಿಲಾ.',
        nepali:
            'सुविधाहरू, मूल्य निर्धारण र डिजाइनहरू परिवर्तन हुन सक्छन्। कानूनले अनुमति दिए अनुसार, सेवा कुनै वारेन्टी बिना प्रदान गरिन्छ।',
        meitei:
            'ফীচরশিং, মলশিং অমসুং দিজাইনশিং হোংবা য়াই। লোনা য়াবা মখাদা, সর্ভিস অসি ৱারেন্তি অমত্তা য়াওদনা পীরিবনি।',
        mizo:
            'Feature, man leh design-te a inthlak thei a. Danin a phal chinah, he service hi warranty awm loin pek a ni.',
        kashmiri:
            'خَصوصِیات، قیمت تہٕ ڈیزائن ہؠکن بَدلِتھ۔ قونوٗنی حدَس تَحَت છੁِ سٔروِس کُنہِ ضَمانَتہٕ وَرٲے فَراہَم کَرنہٕ یِوان۔',
        ladakhi:
            'ཁྱད་ཆོས། རིན་གོང་དང་བཀོད་པ་རྣམས་འགྱུར་སྲིད། ཁྲིམས་ལུགས་ལྟར་ཞབས་ཞུ་འདི་ཁས་ལེན་གང་ཡང་མེད་པར་སྤྲོད།',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సంప్రదింపు సమాచారం',
        english: 'Contact Information',
        hindi: 'संपर्क जानकारी',
        tamil: 'தொடர்பு தகவல்',
        kannada: 'ಸಂಪರ್ಕ ಮಾಹಿತಿ',
        malayalam: 'ബന്ധപ്പെടാനുള്ള വിവരങ്ങൾ',
        marathi: 'संपर्क माहिती',
        gujarati: 'સંપર્ક માહિતી',
        bengali: 'যোগাযোগের তথ্য',
        punjabi: 'ਸੰਪਰਕ ਜਾਣਕਾਰੀ',
        odia: 'ଯୋଗାଯୋଗ ସୂଚନା',
        assamese: 'যোগাযোগৰ তথ্য',
        konkani: 'ಸಂಪರ್ಕ್ ಮಾಹಿತಿ',
        nepali: 'सम्पर्क जानकारी',
        meitei: 'কন্তেক্তকী ৱারোল',
        mizo: 'Biak pawhna chanchin',
        kashmiri: 'رابطہٕ ہٕنٛز معلومات',
        ladakhi: 'འབྲེལ་གཏུགས་གནས་ཚུལ།',
      ),
      strings.localized(
        telugu:
            'నిబంధనలు, బిల్లింగ్, సబ్‌స్క్రిప్షన్లు, ఖాతా తొలగింపు లేదా చట్టపరమైన ప్రశ్నల కోసం ${AppPublicInfo.supportEmail} ని సంప్రదించండి.',
        english:
            'For terms, billing, subscriptions, account deletion, or legal questions, contact ${AppPublicInfo.supportEmail}.',
        hindi:
            'शर्तों, बिलिंग, सदस्यता, खाता हटाने या कानूनी प्रश्नों के लिए ${AppPublicInfo.supportEmail} पर संपर्क करें।',
        tamil:
            'விதிமுறைகள், பில்லிங், சந்தாக்கள், கணக்கு நீக்கம் அல்லது சட்டக் கேள்விகளுக்கு ${AppPublicInfo.supportEmail}-ஐத் தொடர்பு கொள்ளவும்.',
        kannada:
            'ನಿಯಮಗಳು, ಬಿಲ್ಲಿಂಗ್, ಚಂದಾದಾರಿಕೆಗಳು, ಖಾತೆ ಅಳಿಸುವಿಕೆ ಅಥವಾ ಕಾನೂನು ಪ್ರಶ್ನೆಗಳಿಗಾಗಿ ${AppPublicInfo.supportEmail} ಅನ್ನು ಸಂಪರ್ಕಿಸಿ.',
        malayalam:
            'വ്യവസ്ഥകൾ, ബില്ലിംഗ്, സബ്‌സ്‌ക്രിപ്ഷനുകൾ, നിയമപരമായ ചോദ്യങ്ങൾ എന്നിവയ്ക്ക് ${AppPublicInfo.supportEmail}-മായി ബന്ധപ്പെടുക.',
        marathi:
            'अटी, बिलिंग, सदस्यता, खाते हटवणे किंवा कायदेशीर प्रश्नांसाठी ${AppPublicInfo.supportEmail} वर संपर्क साधा.',
        gujarati:
            'શરતો, બિલિંગ, સબ્સ્ક્રિપ્શન્સ, એકાઉન્ટ ડિલીટ અથવા કાનૂની પ્રશ્નો માટે ${AppPublicInfo.supportEmail} પર સંપર્ક કરો.',
        bengali:
            'শর্তাবলী, বিলিং, সাবস্ক্রিপশন, অ্যাকাউন্ট মুছে ফেলা বা আইনি প্রশ্নের জন্য ${AppPublicInfo.supportEmail}-এ যোগাযোগ করুন।',
        punjabi:
            'ਨਿਯਮਾਂ, ਬਿਲਿੰਗ, ਗਾਹਕੀਆਂ, ਖਾਤਾ ਮਿਟਾਉਣ ਜਾਂ ਕਾਨੂੰਨੀ ਸਵਾਲਾਂ ਲਈ ${AppPublicInfo.supportEmail} ਤੇ ਸੰਪਰਕ ਕਰੋ।',
        odia:
            'ନିୟମାବଳୀ, ବିଲିଂ, ସଦସ୍ୟତା, ଆକାଉଣ୍ଟ୍ ବିଲୋପ କିମ୍ବା ଆଇନଗତ ପ୍ରଶ୍ନ ପାଇଁ ${AppPublicInfo.supportEmail} ସହିତ ଯୋଗାଯୋଗ କରନ୍ତୁ।',
        assamese:
            'নিয়মাৱলী, বিলিং, গ্ৰাহকভুক্তি, একাউণ্ট বিলোপ বা আইনী প্ৰশ্নৰ বাবে ${AppPublicInfo.supportEmail} লৈ যোগাযোগ কৰক।',
        konkani:
            'ನಿಬಂಧನಾಂ, ಬಿಲ್ಲಿಂಗ್, ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ಸ್, ಖಾತೆಂ ಕಾಡ್ಚೆಂ ಯಾ ಕಾಯ್ದ್ಯಾಚ್ಯಾ ಸವಾಲಾಂಕ್ ${AppPublicInfo.supportEmail} ಕಡೆನ್ ಸಂಪರ್ಕ್ ಕರಾ.',
        nepali:
            'सर्तहरू, बिलिङ, सदस्यता, खाता मेटाउने वा कानूनी प्रश्नहरूको लागि ${AppPublicInfo.supportEmail} मा सम्पर्क गर्नुहोस्।',
        meitei:
            'তর্মশিং, বিলিং, সবস্ক্রিপ্সনশিং, একাউন্ত মুথত্পা নত্রগা লো সংক্রান্ত ৱাহংশিংগীদমক ${AppPublicInfo.supportEmail} দা কন্তেক্ত তৌবীয়ু।',
        mizo:
            'Terms, billing, subscription, account paih emaw dan lam zawhna i neih chuan ${AppPublicInfo.supportEmail}-ah hian bia ang che.',
        kashmiri:
            'شرائط، بِلِنٛگ، سبسکرپشن، یا قونوٗنی سوالاتن باپتھ کٔریو ${AppPublicInfo.supportEmail} پؠٹھ رابطہٕ۔',
        ladakhi:
            'ཆart་རྐྱེན། རིན་བསྡུ། མངགས་ཉོ། ཐོ་ཁ་སུབ་པའམ་ཁྲིམས་ལུགས་ཀྱི་དྲི་བའི་ཆེད་ ${AppPublicInfo.supportEmail} ལ་འབྲེལ་གཏུགས་གནང་རོགས།',
      ),
    ),
  ];
}
