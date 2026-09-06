import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';

class NotificationUnavailableScreen extends StatelessWidget {
  const NotificationUnavailableScreen({
    super.key,
    this.title,
    this.message,
  });

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final resolvedTitle =
        title ??
        strings.localized(
          telugu: 'ఈ నోటిఫికేషన్ కంటెంట్ అందుబాటులో లేదు',
          english: 'This notification content is unavailable',
          hindi: 'यह अधिसूचना सामग्री अनुपलब्ध है',
          tamil: 'இந்த அறிவிப்பு உள்ளடக்கம் கிடைக்கவில்லை',
          kannada: 'ಈ ಅಧಿಸೂಚನೆ ವಿಷಯ ಲಭ್ಯವಿಲ್ಲ',
          malayalam: 'ഈ അറിയിപ്പ് ഉള്ളടക്കം ലഭ്യമല്ല',
          marathi: 'ही सूचना सामग्री अनुपलब्ध आहे',
          gujarati: 'આ સૂચના સામગ્રી અનુપલબ્ધ છે',
          bengali: 'এই বিজ্ঞপ্তির বিষয়বস্তু অনুপলബ്ধ',
          punjabi: 'ਇਹ ਸੂਚਨਾ ਸਮੱਗਰੀ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
          odia: 'ଏହି ବିଜ୍ଞପ୍ତି ବିଷୟବସ୍ତୁ ଉପଲବ୍ଧ ନାହିଁ',
          assamese: 'এই অধিসূচনা বিষয়বস্তু উপলব্ধ নহয়',
          konkani: 'ही सूचना सामग्री उपलब्ध ना',
          nepali: 'यो सूचना सामग्री अनुपलब्ध छ',
          meitei: 'Notification content asi phangde',
          mizo: 'He hriattirna thupui hi hmuh theih a ni lo',
          kashmiri: 'یہِ اطلاع مواد چھُنہٕ دستِیاب',
          ladakhi: 'བརྡ་ཐོའི་ནང་དོན་འདི་མི་འདུག',
        );
    final resolvedMessage =
        message ??
        strings.localized(
          telugu: 'ఈ కంటెంట్ తీసివేయబడింది లేదా ఇక అందుబాటులో లేదు. హోమ్‌కి వెళ్లి తాజా పోస్టర్లు చూడండి.',
          english:
              'This content was removed or is no longer available. Open Home to see the latest posters.',
          hindi:
              'यह सामग्री हटा दी गई है या अब उपलब्ध नहीं है। नवीनतम पोस्टर देखने के लिए होम खोलें।',
          tamil:
              'இந்த உள்ளடக்கம் அகற்றப்பட்டது அல்லது இனி கிடைக்காது. சமீபத்திய போஸ்டர்களைக் காண முகப்புப் பக்கத்தைத் திறக்கவும்.',
          kannada:
              'ಈ ವಿಷಯವನ್ನು ತೆಗೆದುಹಾಕಲಾಗಿದೆ ಅಥವಾ ಇನ್ನು ಮುಂದೆ ಲಭ್ಯವಿಲ್ಲ. ಇತ್ತೀಚಿನ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ನೋಡಲು ಹೋಮ್ ತೆರೆಯಿರಿ.',
          malayalam:
              'ഈ ഉള്ളടക്കം നീക്കംചെയ്‌തു അല്ലെങ്കിൽ ഇനി ലഭ്യമല്ല. ഏറ്റവും പുതിയ പോസ്റ്ററുകൾ കാണാൻ ഹോം തുറക്കുക.',
          marathi:
              'ही सामग्री काढली गेली आहे किंवा यापुढे उपलब्ध नाही. नवीनतम पोस्टर्स पाहण्यासाठी होम उघडा.',
          gujarati:
              'આ સામગ્રી દૂર કરવામાં આવી છે અથવા હવે ઉપલબ્ધ નથી. નવીનતમ પોસ્ટરો જોવા માટે હોમ ખોલો.',
          bengali:
              'এই বিষয়বস্তুটি মুছে ফেলা হয়েছে বা আর উপলব্ধ নেই। সর্বশেষ পোস্টার দেখতে হোম খুলুন।',
          punjabi:
              'ਇਹ ਸਮੱਗਰੀ ਹਟਾ ਦਿੱਤੀ ਗਈ ਹੈ ਜਾਂ ਹੁਣ ਉਪਲਬਧ ਨਹੀਂ ਹੈ। ਨਵੀਨਤਮ ਪੋਸਟਰ ਦੇਖਣ ਲਈ ਹੋਮ ਖੋਲ੍ਹੋ।',
          odia:
              'ଏହି ବିଷୟବସ୍ତୁ ହଟାଇ ଦିଆଯାଇଛି କିମ୍ବା ଆଉ ଉପଲବ୍ଧ ନାହିଁ। ନୂତନ ପୋଷ୍ଟର ଦେଖିବାକୁ ହୋମ୍ ଖୋଲନ୍ତୁ।',
          assamese:
              'এই বিষয়বস্তু আঁতৰোৱা হৈছে বা এতিয়া উপলব্ধ নহয়। শেহতীয়া পোষ্টাৰ চাবলৈ হোম খোলক।',
          konkani:
              'ही सामग्री काडून उडयल्या वा आतां उपलब्ध ना. ताजीं पोस्टरां पळोवंक होम उकते करात.',
          nepali:
              'यो सामग्री हटाइएको छ वा अब उपलब्ध छैन। नवीनतम पोस्टरहरू हेर्न होम खोल्नुहोस्।',
          meitei:
              'Content asi louthok-khraba nattraga phangjadre. Latest posters yengnaba Home hangdok-u.',
          mizo:
              'He thil hi paih a ni tawh emaw a awm tawh lo. Poster thar ber ber en turin Home hawng rawh.',
          kashmiri:
              'یہِ مواد آو ہٹاونہٕ یا چھُنہٕ وؠن دستِیاب۔ تروتازہ پوسٹر وُچھنہٕ خٲطرٕ کٔریو ہوم اوپن۔',
          ladakhi:
              'ནང་དོན་འདི་སུབས་ཚར་བའམ་མི་འདུག གསར་ཤོས་པོ་སཊར་བལྟ་བར་ Home ཁ་ཕྱེད།',
        );

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          strings.localized(
            telugu: 'నోటిఫికేషన్',
            english: 'Notification',
            hindi: 'अधिसूचना',
            tamil: 'அறிவிப்பு',
            kannada: 'ಅಧಿಸೂಚನೆ',
            malayalam: 'അറിയിപ്പ്',
            marathi: 'सूचना',
            gujarati: 'સૂચના',
            bengali: 'বিজ্ঞপ্তি',
            punjabi: 'ਸੂਚਨਾ',
            odia: 'ବିଜ୍ଞପ୍ତି',
            assamese: 'অধিসূচনা',
            konkani: 'सूचना',
            nepali: 'सूचना',
            meitei: 'Notification',
            mizo: 'Hriattirna',
            kashmiri: 'اطلاع',
            ladakhi: 'བརྡ་ཐོ།',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.notifications_off_rounded,
                  size: 68,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 18),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  resolvedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: AppNavigator.openHome,
                  child: Text(
                    strings.localized(
                      telugu: 'హోమ్‌కి వెళ్లండి',
                      english: 'Open Home',
                      hindi: 'होम पर जाएँ',
                      tamil: 'முகப்புக்குச் செல்க',
                      kannada: 'ಹೋಮ್‌ಗೆ ಹೋಗಿ',
                      malayalam: 'ഹോമിലേക്ക് പോകുക',
                      marathi: 'होमवर जा',
                      gujarati: 'હોમ પર જાઓ',
                      bengali: 'হোমে যান',
                      punjabi: 'ਹੋਮ ਤੇ ਜਾਓ',
                      odia: 'ହୋମ୍‌କୁ ଯାଆନ୍ତୁ',
                      assamese: 'হোমলৈ যাওক',
                      konkani: 'होमाचेर वचात',
                      nepali: 'होममा जानुहोस्',
                      meitei: 'Home da chatlu',
                      mizo: 'Home-ah kal rawh',
                      kashmiri: 'ہومَس گژھیو',
                      ladakhi: 'Home ལ་སྐྱོད།',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
