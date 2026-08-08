import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/daily_quiz_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

enum _QuizSvgIconKind {
  quiz,
  timer,
  trophy,
  success,
  info,
  correct,
  wrong,
  selected,
  empty,
}

class _QuizCopy {
  const _QuizCopy._();

  static String dailyQuiz(AppStrings strings) => strings.localized(
    telugu: 'రోజువారీ క్విజ్',
    english: 'Daily Quiz',
    hindi: 'दैनिक क्विज़',
    tamil: 'தினசரி வினாடி வினா',
    kannada: 'ದೈನಂದಿನ ಕ್ವಿಜ್',
    malayalam: 'ദൈനംദിന ക്വിസ്',
    assamese: 'দৈনিক কুইজ',
    konkani: 'दिसाची क्विझ',
    gujarati: 'દૈનિક ક્વિઝ',
    marathi: 'दैनिक क्विझ',
    meitei: 'নুমিৎখুদিংগী কুইজ',
    mizo: 'Ni tin quiz',
    odia: 'ଦୈନିକ କୁଇଜ୍',
    punjabi: 'ਰੋਜ਼ਾਨਾ ਕਵਿਜ਼',
    nepali: 'दैनिक क्विज',
    bengali: 'দৈনিক কুইজ',
    kashmiri: 'روزانہ کوئز',
    ladakhi: 'ཉིན་རེའི་དྲི་བ།',
  );

  static String answerAll(AppStrings strings) => strings.localized(
    telugu: 'సబ్మిట్ చేయడానికి అన్ని ప్రశ్నలకు సమాధానం ఇవ్వండి.',
    english: 'Answer every question before submitting.',
    hindi: 'सबमिट करने से पहले हर प्रश्न का उत्तर दें।',
    tamil: 'சமர்ப்பிக்கும் முன் எல்லா கேள்விகளுக்கும் பதில் அளிக்கவும்.',
    kannada: 'ಸಲ್ಲಿಸುವ ಮೊದಲು ಎಲ್ಲಾ ಪ್ರಶ್ನೆಗಳಿಗೆ ಉತ್ತರಿಸಿ.',
    malayalam: 'സമർപ്പിക്കുന്നതിന് മുമ്പ് എല്ലാ ചോദ്യങ്ങൾക്കും ഉത്തരം നൽകുക.',
    assamese: 'জমা দিয়াৰ আগতে সকলো প্ৰশ্নৰ উত্তৰ দিয়ক।',
    konkani: 'सादर करपा आदीं सगळ्या प्रस्नांक जाप दिवची.',
    gujarati: 'સબમિટ કરતા પહેલા બધા પ્રશ્નોના જવાબ આપો.',
    marathi: 'सबमिट करण्यापूर्वी सर्व प्रश्नांची उत्तरे द्या.',
    meitei: 'Submit touba matungda wahang pumnamak khangbiyu.',
    mizo: 'Submit hmain zawhna zawng zawng chhang rawh.',
    odia: 'ସବମିଟ୍ କରିବା ପୂର୍ବରୁ ସମସ୍ତ ପ୍ରଶ୍ନର ଉତ୍ତର ଦିଅନ୍ତୁ।',
    punjabi: 'ਸਬਮਿਟ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਹਰ ਸਵਾਲ ਦਾ ਜਵਾਬ ਦਿਓ।',
    nepali: 'पेश गर्नुअघि सबै प्रश्नको उत्तर दिनुहोस्।',
    bengali: 'জমা দেওয়ার আগে সব প্রশ্নের উত্তর দিন।',
    kashmiri: 'جمع کرنہٕ برونٛہہ سارنی سوالن ہُند جواب دیو۔',
    ladakhi: 'སྤྲོད་པའི་སྔོན་ལ་དྲི་བ་ཚང་མར་ལན་སྤྲོད།',
  );

  static String submitted(AppStrings strings) => strings.localized(
    telugu: 'సబ్మిట్ అయింది',
    english: 'Submitted',
    hindi: 'सबमिट हो गया',
    tamil: 'சமர்ப்பிக்கப்பட்டது',
    kannada: 'ಸಲ್ಲಿಸಲಾಗಿದೆ',
    malayalam: 'സമർപ്പിച്ചു',
    assamese: 'জমা দিয়া হ’ল',
    konkani: 'सादर जालें',
    gujarati: 'સબમિટ થયું',
    marathi: 'सबमिट झाले',
    meitei: 'Submit toure',
    mizo: 'Submit a ni',
    odia: 'ସବମିଟ୍ ହେଲା',
    punjabi: 'ਸਬਮਿਟ ਹੋ ਗਿਆ',
    nepali: 'पेश भयो',
    bengali: 'জমা হয়েছে',
    kashmiri: 'جمع گۆو',
    ladakhi: 'སྤྲད་ཟིན།',
  );

  static String resultUpdated(AppStrings strings) => strings.localized(
    telugu: 'మీ ఫలితం ప్రొఫైల్‌లో అప్డేట్ అయింది.',
    english: 'Your result is updated in profile.',
    hindi: 'आपका परिणाम प्रोफाइल में अपडेट हो गया है।',
    tamil: 'உங்கள் முடிவு சுயவிவரத்தில் புதுப்பிக்கப்பட்டது.',
    kannada: 'ನಿಮ್ಮ ಫಲಿತಾಂಶ ಪ್ರೊಫೈಲ್‌ನಲ್ಲಿ ನವೀಕರಿಸಲಾಗಿದೆ.',
    malayalam: 'നിങ്ങളുടെ ഫലം പ്രൊഫൈലിൽ പുതുക്കി.',
    assamese: 'আপোনাৰ ফলাফল প্ৰফাইলত আপডেট কৰা হৈছে।',
    konkani: 'तुमचो निकाल प्रोफायलांत अपडेट जाला.',
    gujarati: 'તમારું પરિણામ પ્રોફાઇલમાં અપડેટ થયું છે.',
    marathi: 'तुमचा निकाल प्रोफाइलमध्ये अपडेट झाला आहे.',
    meitei: 'Nakhoigi result profile-da update toure.',
    mizo: 'I result chu profile-ah update tawh a ni.',
    odia: 'ଆପଣଙ୍କ ଫଳାଫଳ ପ୍ରୋଫାଇଲରେ ଅପଡେଟ୍ ହୋଇଛି।',
    punjabi: 'ਤੁਹਾਡਾ ਨਤੀਜਾ ਪ੍ਰੋਫਾਈਲ ਵਿੱਚ ਅਪਡੇਟ ਹੋ ਗਿਆ ਹੈ।',
    nepali: 'तपाईंको नतिजा प्रोफाइलमा अपडेट भयो।',
    bengali: 'আপনার ফলাফল প্রোফাইলে আপডেট হয়েছে।',
    kashmiri: 'تُہند نتیجہ پروفائلس منز اپڈیٹ گۆو۔',
    ladakhi: 'ཁྱེད་ཀྱི་འབྲས་བུ་སྤྱི་ཁོངས་ནང་གསར་སྒྱུར་བྱས།',
  );

  static String close(AppStrings strings) => strings.localized(
    telugu: 'మూసివేయి',
    english: 'Close',
    hindi: 'बंद करें',
    tamil: 'மூடு',
    kannada: 'ಮುಚ್ಚಿ',
    malayalam: 'അടയ്ക്കുക',
    assamese: 'বন্ধ কৰক',
    konkani: 'बंद करात',
    gujarati: 'બંધ કરો',
    marathi: 'बंद करा',
    meitei: 'Thing-u',
    mizo: 'Khar rawh',
    odia: 'ବନ୍ଦ କରନ୍ତୁ',
    punjabi: 'ਬੰਦ ਕਰੋ',
    nepali: 'बन्द गर्नुहोस्',
    bengali: 'বন্ধ করুন',
    kashmiri: 'بند کریو',
    ladakhi: 'སྒོ་རྒྱག',
  );

  static String share(AppStrings strings) =>
      strings.localized(telugu: 'షేర్', english: 'Share');

  static String shareMessage(AppStrings strings, String score, String appLink) =>
      strings.localized(
        telugu:
            'Mana Poster AI లో ప్రతిరోజూ కొత్త పోస్టర్లు, సరదా క్విజ్‌లు మీకోసం.\n'
            'నా క్విజ్ స్కోర్: $score\n'
            'యాప్ డౌన్‌లోడ్: $appLink',
        english:
            'New posters and fun quizzes every day on Mana Poster AI.\n'
            'My quiz score: $score\n'
            'Download app: $appLink',
        hindi:
            'Mana Poster AI ऐप में रोज़ाना पोस्टर बनाएं और क्विज़ खेलें.\n'
            'मेरा क्विज़ स्कोर: $score\n'
            'ऐप डाउनलोड: $appLink',
        tamil:
            'Mana Poster AI செயலியில் தினசரி போஸ்டர்கள் உருவாக்கி வினாடி வினா விளையாடுங்கள்.\n'
            'என் வினாடி வினா மதிப்பெண்: $score\n'
            'செயலி பதிவிறக்கம்: $appLink',
        kannada:
            'Mana Poster AI ಆಪ್‌ನಲ್ಲಿ ದೈನಂದಿನ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ರಚಿಸಿ, ಕ್ವಿಜ್ ಆಡಿ.\n'
            'ನನ್ನ ಕ್ವಿಜ್ ಸ್ಕೋರ್: $score\n'
            'ಆಪ್ ಡೌನ್‌ಲೋಡ್: $appLink',
        malayalam:
            'Mana Poster AI ആപ്പിൽ ദിനംപ്രതി പോസ്റ്ററുകൾ സൃഷ്ടിച്ച് ക്വിസ് കളിക്കൂ.\n'
            'എന്റെ ക്വിസ് സ്കോർ: $score\n'
            'ആപ്പ് ഡൗൺലോഡ്: $appLink',
        assamese:
            'Mana Poster AI এপত দৈনিক পোষ্টাৰ বনাওক আৰু কুইজ খেলক.\n'
            'মোৰ কুইজ স্ক’ৰ: $score\n'
            'এপ ডাউনলোড: $appLink',
        konkani:
            'Mana Poster AI अ‍ॅपांत रोजचे पोस्टर तयार करात आनी क्विझ खेळात.\n'
            'म्हजो क्विझ स्कोर: $score\n'
            'अ‍ॅप डाउनलोड: $appLink',
        gujarati:
            'Mana Poster AI એપમાં રોજના પોસ્ટર બનાવો અને ક્વિઝ રમો.\n'
            'મારો ક્વિઝ સ્કોર: $score\n'
            'એપ ડાઉનલોડ: $appLink',
        marathi:
            'Mana Poster AI अ‍ॅपमध्ये रोजचे पोस्टर तयार करा आणि क्विझ खेळा.\n'
            'माझा क्विझ स्कोर: $score\n'
            'अ‍ॅप डाउनलोड: $appLink',
        meitei:
            'Mana Poster AI app-da daily poster sem-u amasung quiz saan-u.\n'
            'Eigi quiz score: $score\n'
            'App download: $appLink',
        mizo:
            'Mana Poster AI app-ah daily poster siam la, quiz khel rawh.\n'
            'Ka quiz score: $score\n'
            'App download: $appLink',
        odia:
            'Mana Poster AI ଆପ୍‌ରେ ଦୈନିକ ପୋଷ୍ଟର ତିଆରି କରନ୍ତୁ ଏବଂ କ୍ୱିଜ୍ ଖେଳନ୍ତୁ.\n'
            'ମୋ କ୍ୱିଜ୍ ସ୍କୋର: $score\n'
            'ଆପ୍ ଡାଉନଲୋଡ୍: $appLink',
        punjabi:
            'Mana Poster AI ਐਪ ਵਿੱਚ ਰੋਜ਼ਾਨਾ ਪੋਸਟਰ ਬਣਾਓ ਅਤੇ ਕਵਿਜ਼ ਖੇਡੋ.\n'
            'ਮੇਰਾ ਕਵਿਜ਼ ਸਕੋਰ: $score\n'
            'ਐਪ ਡਾਊਨਲੋਡ: $appLink',
        nepali:
            'Mana Poster AI एपमा दैनिक पोस्टर बनाउनुहोस् र क्विज खेल्नुहोस्.\n'
            'मेरो क्विज स्कोर: $score\n'
            'एप डाउनलोड: $appLink',
        bengali:
            'Mana Poster AI অ্যাপে প্রতিদিনের পোস্টার তৈরি করুন এবং কুইজ খেলুন.\n'
            'আমার কুইজ স্কোর: $score\n'
            'অ্যাপ ডাউনলোড: $appLink',
        kashmiri:
            'Mana Poster AI ایپ منز روزانہ پوسٹر بنٲویو تہ کوئز کھیلیو.\n'
            'میون کوئز سکور: $score\n'
            'ایپ ڈاؤنلوڈ: $appLink',
        ladakhi:
            'Mana Poster AI app ནང་ཉིན་རེའི་ poster བཟོས་ནས quiz རྩེད།\n'
            'ངའི quiz score: $score\n'
            'App download: $appLink',
      );

  static String download(AppStrings strings) =>
      strings.localized(telugu: 'డౌన్లోడ్', english: 'Download');

  static String savedToGallery(AppStrings strings) => strings.localized(
    telugu: 'టికెట్ గ్యాలరీలో సేవ్ అయింది.',
    english: 'Ticket saved to gallery.',
  );

  static String ticketActionFailed(AppStrings strings) => strings.localized(
    telugu: 'టికెట్ సిద్ధం చేయలేకపోయాం. మళ్లీ ప్రయత్నించండి.',
    english: 'Unable to prepare ticket. Please try again.',
  );

  static String loadFailed(AppStrings strings) => strings.localized(
    telugu: 'క్విజ్ లోడ్ కాలేదు',
    english: 'Quiz could not load',
    hindi: 'क्विज़ लोड नहीं हुआ',
    tamil: 'வினாடி வினா ஏற்றப்படவில்லை',
    kannada: 'ಕ್ವಿಜ್ ಲೋಡ್ ಆಗಲಿಲ್ಲ',
    malayalam: 'ക്വിസ് ലോഡ് ആയില്ല',
    assamese: 'কুইজ লোড নহ’ল',
    konkani: 'क्विझ लोड जावंक ना',
    gujarati: 'ક્વિઝ લોડ થઈ નથી',
    marathi: 'क्विझ लोड झाली नाही',
    meitei: 'Quiz load toude',
    mizo: 'Quiz a load lo',
    odia: 'କୁଇଜ୍ ଲୋଡ୍ ହେଲା ନାହିଁ',
    punjabi: 'ਕਵਿਜ਼ ਲੋਡ ਨਹੀਂ ਹੋਈ',
    nepali: 'क्विज लोड भएन',
    bengali: 'কুইজ লোড হয়নি',
    kashmiri: 'کوئز لوڈ نہ گۆو',
    ladakhi: 'དྲི་བ་འཇུག་མ་ཐུབ།',
  );

  static String retry(AppStrings strings) => strings.localized(
    telugu: 'మళ్లీ ప్రయత్నించండి',
    english: 'Retry',
    hindi: 'फिर कोशिश करें',
    tamil: 'மீண்டும் முயற்சி',
    kannada: 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    malayalam: 'വീണ്ടും ശ്രമിക്കുക',
    assamese: 'পুনৰ চেষ্টা কৰক',
    konkani: 'परत यत्न करात',
    gujarati: 'ફરી પ્રયાસ કરો',
    marathi: 'पुन्हा प्रयत्न करा',
    meitei: 'Amuk hotnou',
    mizo: 'Beisei leh rawh',
    odia: 'ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ',
    punjabi: 'ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ',
    nepali: 'फेरि प्रयास गर्नुहोस्',
    bengali: 'আবার চেষ্টা করুন',
    kashmiri: 'دوبار کوشش کریو',
    ladakhi: 'ཡང་བསྐྱར་ཚོད་ལྟ།',
  );

  static String noQuizToday(AppStrings strings) => strings.localized(
    telugu: 'ఈరోజు క్విజ్ లేదు',
    english: 'No quiz today',
    hindi: 'आज कोई क्विज़ नहीं है',
    tamil: 'இன்று வினாடி வினா இல்லை',
    kannada: 'ಇಂದು ಕ್ವಿಜ್ ಇಲ್ಲ',
    malayalam: 'ഇന്ന് ക്വിസ് ഇല്ല',
    assamese: 'আজি কোনো কুইজ নাই',
    konkani: 'आयज क्विझ ना',
    gujarati: 'આજે ક્વિઝ નથી',
    marathi: 'आज क्विझ नाही',
    meitei: 'Ngasi quiz leite',
    mizo: 'Vawiin quiz a awm lo',
    odia: 'ଆଜି କୁଇଜ୍ ନାହିଁ',
    punjabi: 'ਅੱਜ ਕੋਈ ਕਵਿਜ਼ ਨਹੀਂ',
    nepali: 'आज क्विज छैन',
    bengali: 'আজ কোনো কুইজ নেই',
    kashmiri: 'از چھُ نہٕ کوئز',
    ladakhi: 'དེ་རིང་དྲི་བ་མེད།',
  );

  static String noQuizMessage(AppStrings strings) => strings.localized(
    telugu: 'మీ రాష్ట్రానికి క్విజ్ ప్రచురించిన తర్వాత ఇక్కడ కనిపిస్తుంది.',
    english: 'A quiz will appear here after it is published for your state.',
    hindi: 'आपके राज्य के लिए क्विज़ प्रकाशित होने के बाद यहां दिखेगा।',
    tamil:
        'உங்கள் மாநிலத்திற்கு வெளியிடப்பட்ட பிறகு இங்கே வினாடி வினா தெரியும்.',
    kannada: 'ನಿಮ್ಮ ರಾಜ್ಯಕ್ಕೆ ಪ್ರಕಟಿಸಿದ ನಂತರ ಕ್ವಿಜ್ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ.',
    malayalam:
        'നിങ്ങളുടെ സംസ്ഥാനത്തിന് പ്രസിദ്ധീകരിച്ച ശേഷം ക്വിസ് ഇവിടെ കാണിക്കും.',
    assamese: 'আপোনাৰ ৰাজ্যৰ বাবে প্ৰকাশ কৰাৰ পাছত কুইজ ইয়াত দেখা যাব।',
    konkani: 'तुमच्या राज्याखातीर प्रकाशित जाल्यार क्विझ हांगा दिसतली.',
    gujarati: 'તમારા રાજ્ય માટે પ્રકાશિત થયા પછી ક્વિઝ અહીં દેખાશે.',
    marathi: 'तुमच्या राज्यासाठी प्रकाशित झाल्यावर क्विझ येथे दिसेल.',
    meitei: 'Nakhoigi state-gi quiz publish tourabadi mapham asida uigani.',
    mizo: 'I state tana quiz publish a nih hnuah heta a lang ang.',
    odia: 'ଆପଣଙ୍କ ରାଜ୍ୟ ପାଇଁ ପ୍ରକାଶ ପରେ କୁଇଜ୍ ଏଠାରେ ଦେଖାଯିବ।',
    punjabi: 'ਤੁਹਾਡੇ ਰਾਜ ਲਈ ਪ੍ਰਕਾਸ਼ਿਤ ਹੋਣ ਤੋਂ ਬਾਅਦ ਕਵਿਜ਼ ਇੱਥੇ ਦਿਖੇਗੀ।',
    nepali: 'तपाईंको राज्यका लागि प्रकाशित भएपछि क्विज यहाँ देखिनेछ।',
    bengali: 'আপনার রাজ্যের জন্য প্রকাশিত হলে কুইজ এখানে দেখা যাবে।',
    kashmiri: 'تُہند ریاست خٲطرٕ شایع گژھنہٕ پتہٕ کوئز یتھ منز وُچھنہٕ یِیہ۔',
    ladakhi: 'ཁྱེད་ཀྱི་མངའ་སྡེར་སྤེལ་རྗེས་དྲི་བ་འདིར་མངོན།',
  );

  static String refresh(AppStrings strings) => strings.localized(
    telugu: 'రిఫ్రెష్',
    english: 'Refresh',
    hindi: 'रीफ्रेश',
    tamil: 'புதுப்பி',
    kannada: 'ರಿಫ್ರೆಶ್',
    malayalam: 'റിഫ്രെഷ്',
    assamese: 'ৰিফ্ৰেশ',
    konkani: 'रिफ्रेश',
    gujarati: 'રીફ્રેશ',
    marathi: 'रिफ्रेश',
    meitei: 'Refresh',
    mizo: 'Refresh',
    odia: 'ରିଫ୍ରେଶ୍',
    punjabi: 'ਰੀਫ੍ਰੈਸ਼',
    nepali: 'रिफ्रेश',
    bengali: 'রিফ্রেশ',
    kashmiri: 'ریفریش',
    ladakhi: 'རི་ཕྲེཤ།',
  );

  static String questionOf(AppStrings strings, int current, int total) =>
      strings.localized(
        telugu: 'ప్రశ్న $current / $total',
        english: 'Question $current of $total',
        hindi: 'प्रश्न $current / $total',
        tamil: 'கேள்வி $current / $total',
        kannada: 'ಪ್ರಶ್ನೆ $current / $total',
        malayalam: 'ചോദ്യം $current / $total',
        assamese: 'প্ৰশ্ন $current / $total',
        konkani: 'प्रस्न $current / $total',
        gujarati: 'પ્રશ્ન $current / $total',
        marathi: 'प्रश्न $current / $total',
        meitei: 'Wahang $current / $total',
        mizo: 'Zawhna $current / $total',
        odia: 'ପ୍ରଶ୍ନ $current / $total',
        punjabi: 'ਸਵਾਲ $current / $total',
        nepali: 'प्रश्न $current / $total',
        bengali: 'প্রশ্ন $current / $total',
        kashmiri: 'سوال $current / $total',
        ladakhi: 'དྲི་བ་ $current / $total',
      );

  static String answered(AppStrings strings, int selected, int total) =>
      strings.localized(
        telugu: '$selected/$total సమాధానాలు',
        english: '$selected/$total answered',
        hindi: '$selected/$total उत्तर दिए',
        tamil: '$selected/$total பதில்கள்',
        kannada: '$selected/$total ಉತ್ತರಿಸಲಾಗಿದೆ',
        malayalam: '$selected/$total ഉത്തരം നൽകി',
        assamese: '$selected/$total উত্তৰ দিয়া হৈছে',
        konkani: '$selected/$total जाप दिल्या',
        gujarati: '$selected/$total જવાબ આપ્યા',
        marathi: '$selected/$total उत्तरे दिली',
        meitei: '$selected/$total paokhum pire',
        mizo: '$selected/$total chhan tawh',
        odia: '$selected/$total ଉତ୍ତର ଦିଆଗଲା',
        punjabi: '$selected/$total ਜਵਾਬ ਦਿੱਤੇ',
        nepali: '$selected/$total उत्तर दिए',
        bengali: '$selected/$total উত্তর দেওয়া হয়েছে',
        kashmiri: '$selected/$total جواب دِت',
        ladakhi: '$selected/$total ལན་སྤྲད།',
      );

  static String seconds(AppStrings strings, int seconds) => strings.localized(
    telugu: '$seconds సెకన్లు',
    english: '${seconds}s',
    hindi: '$seconds सेकंड',
    tamil: '$seconds விநாடி',
    kannada: '$seconds ಸೆಕೆಂಡು',
    malayalam: '$seconds സെക്കൻഡ്',
    assamese: '$seconds ছেকেণ্ড',
    konkani: '$seconds सेकंद',
    gujarati: '$seconds સેકન્ડ',
    marathi: '$seconds सेकंद',
    meitei: '$seconds second',
    mizo: '$seconds second',
    odia: '$seconds ସେକେଣ୍ଡ',
    punjabi: '$seconds ਸਕਿੰਟ',
    nepali: '$seconds सेकेन्ड',
    bengali: '$seconds সেকেন্ড',
    kashmiri: '$seconds سیکنڈ',
    ladakhi: '$seconds སྐར་ཆ།',
  );

  static String congratulations(AppStrings strings) => strings.localized(
    telugu: 'అభినందనలు',
    english: 'Congratulations',
    hindi: 'बधाई हो',
    tamil: 'வாழ்த்துகள்',
    kannada: 'ಅಭಿನಂದನೆಗಳು',
    malayalam: 'അഭിനന്ദനങ്ങൾ',
    assamese: 'অভিনন্দন',
    konkani: 'अभिनंदन',
    gujarati: 'અભિનંદન',
    marathi: 'अभिनंदन',
    meitei: 'Nungairaba yaifare',
    mizo: 'Lawmthu kan sawi',
    odia: 'ଅଭିନନ୍ଦନ',
    punjabi: 'ਵਧਾਈਆਂ',
    nepali: 'बधाई छ',
    bengali: 'অভিনন্দন',
    kashmiri: 'مبارک',
    ladakhi: 'བཀྲ་ཤིས་བདེ་ལེགས།',
  );

  static String correctHighlighted(AppStrings strings) => strings.localized(
    telugu: 'సరైన సమాధానం ఆకుపచ్చ రంగులో చూపించబడింది.',
    english: 'Correct answer is highlighted in green.',
    hindi: 'सही उत्तर हरे रंग में दिखाया गया है।',
    tamil: 'சரியான பதில் பச்சை நிறத்தில் காட்டப்பட்டுள்ளது.',
    kannada: 'ಸರಿಯಾದ ಉತ್ತರವನ್ನು ಹಸಿರು ಬಣ್ಣದಲ್ಲಿ ತೋರಿಸಲಾಗಿದೆ.',
    malayalam: 'ശരിയായ ഉത്തരം പച്ച നിറത്തിൽ കാണിച്ചിരിക്കുന്നു.',
    assamese: 'শুদ্ধ উত্তৰ সেউজীয়া ৰঙত দেখুওৱা হৈছে।',
    konkani: 'बरोबर जाप हिरव्या रंगान दाखयल्या.',
    gujarati: 'સાચો જવાબ લીલા રંગમાં બતાવ્યો છે.',
    marathi: 'बरोबर उत्तर हिरव्या रंगात दाखवले आहे.',
    meitei: 'Achumba paokhum green machuda utle.',
    mizo: 'Chhanna dik chu green color-ah lantir a ni.',
    odia: 'ଠିକ୍ ଉତ୍ତର ସବୁଜ ରଙ୍ଗରେ ଦେଖାଯାଇଛି।',
    punjabi: 'ਸਹੀ ਜਵਾਬ ਹਰੇ ਰੰਗ ਵਿੱਚ ਦਿਖਾਇਆ ਗਿਆ ਹੈ।',
    nepali: 'सही उत्तर हरियो रंगमा देखाइएको छ।',
    bengali: 'সঠিক উত্তর সবুজ রঙে দেখানো হয়েছে।',
    kashmiri: 'صحیح جواب سبز رنگس منز ہاوُنہٕ آو۔',
    ladakhi: 'ལན་ཡང་དག་པ་ལྗང་ཁུར་བསྟན་ཡོད།',
  );

  static String startHint(AppStrings strings) => strings.localized(
    telugu: 'ప్రారంభం నొక్కిన తర్వాత టైమర్ మొదలవుతుంది.',
    english: 'Timer starts after you tap Start.',
    hindi: 'शुरू करें दबाने के बाद टाइमर शुरू होगा।',
    tamil: 'தொடங்கு அழுத்திய பிறகு நேரம் தொடங்கும்.',
    kannada: 'ಪ್ರಾರಂಭಿಸಿ ಒತ್ತಿದ ನಂತರ ಟೈಮರ್ ಆರಂಭವಾಗುತ್ತದೆ.',
    malayalam: 'തുടങ്ങുക അമർത്തിയ ശേഷം ടൈമർ തുടങ്ങും.',
    assamese: 'আৰম্ভ টিপিলে টাইমাৰ আৰম্ভ হ’ব।',
    konkani: 'सुरू करात दामल्यार टाइमर सुरू जातलो.',
    gujarati: 'શરૂ કરો દબાવ્યા પછી ટાઈમર શરૂ થશે.',
    marathi: 'सुरू करा दाबल्यानंतर टाइमर सुरू होईल.',
    meitei: 'Start namlaba matungda timer hougani.',
    mizo: 'Start i hmet hnuah timer a tan ang.',
    odia: 'ଆରମ୍ଭ ଦବାଇବା ପରେ ଟାଇମର ଆରମ୍ଭ ହେବ।',
    punjabi: 'ਸ਼ੁਰੂ ਦਬਾਉਣ ਤੋਂ ਬਾਅਦ ਟਾਈਮਰ ਚੱਲੇਗਾ।',
    nepali: 'सुरु थिचेपछि टाइमर सुरु हुन्छ।',
    bengali: 'শুরু চাপার পরে টাইমার শুরু হবে।',
    kashmiri: 'شروع دباؤنہٕ پتہٕ ٹائمر شروع گژھِ۔',
    ladakhi: 'འགོ་འཛུགས་མནན་རྗེས་དུས་ཚོད་འགོ་འཛུགས།',
  );

  static String start(AppStrings strings) => strings.localized(
    telugu: 'ప్రారంభం',
    english: 'Start',
    hindi: 'शुरू करें',
    tamil: 'தொடங்கு',
    kannada: 'ಪ್ರಾರಂಭಿಸಿ',
    malayalam: 'തുടങ്ങുക',
    assamese: 'আৰম্ভ',
    konkani: 'सुरू',
    gujarati: 'શરૂ કરો',
    marathi: 'सुरू करा',
    meitei: 'Houjik',
    mizo: 'Tan rawh',
    odia: 'ଆରମ୍ଭ',
    punjabi: 'ਸ਼ੁਰੂ ਕਰੋ',
    nepali: 'सुरु गर्नुहोस्',
    bengali: 'শুরু করুন',
    kashmiri: 'شروع کریو',
    ladakhi: 'འགོ་འཛུགས།',
  );

  static String check(AppStrings strings) => strings.localized(
    telugu: 'చెక్',
    english: 'Check',
    hindi: 'देखें',
    tamil: 'சரி பார்க்க',
    kannada: 'ಪರಿಶೀಲಿಸಿ',
    malayalam: 'പരിശോധിക്കുക',
  );

  static String attemptedQuiz(AppStrings strings) => strings.localized(
    telugu: 'మీ క్విజ్ ఫలితం',
    english: 'Your quiz result',
    hindi: 'आपका क्विज़ परिणाम',
    tamil: 'உங்கள் வினாடி வினா முடிவு',
    kannada: 'ನಿಮ್ಮ ಕ್ವಿಜ್ ಫಲಿತಾಂಶ',
    malayalam: 'നിങ്ങളുടെ ക്വിസ് ഫലം',
  );

  static String checkAttemptedQuestions(AppStrings strings) =>
      strings.localized(
        telugu: 'మీరు ప్రయత్నించిన ప్రశ్నలు చూడండి',
        english: 'Check your attempted questions',
        hindi: 'अपने उत्तर दिए गए प्रश्न देखें',
        tamil: 'நீங்கள் முயன்ற கேள்விகளை பாருங்கள்',
        kannada: 'ನೀವು ಪ್ರಯತ್ನಿಸಿದ ಪ್ರಶ್ನೆಗಳನ್ನು ನೋಡಿ',
        malayalam: 'നിങ്ങൾ ശ്രമിച്ച ചോദ്യങ്ങൾ കാണുക',
      );

  static String submitting(AppStrings strings) => strings.localized(
    telugu: 'సబ్మిట్ అవుతోంది',
    english: 'Submitting',
    hindi: 'सबमिट हो रहा है',
    tamil: 'சமர்ப்பிக்கிறது',
    kannada: 'ಸಲ್ಲಿಸಲಾಗುತ್ತಿದೆ',
    malayalam: 'സമർപ്പിക്കുന്നു',
    assamese: 'জমা দিয়া হৈছে',
    konkani: 'सादर जाता',
    gujarati: 'સબમિટ થઈ રહ્યું છે',
    marathi: 'सबमिट होत आहे',
    meitei: 'Submit touri',
    mizo: 'Submit mek',
    odia: 'ସବମିଟ୍ ହେଉଛି',
    punjabi: 'ਸਬਮਿਟ ਹੋ ਰਿਹਾ ਹੈ',
    nepali: 'पेश हुँदैछ',
    bengali: 'জমা হচ্ছে',
    kashmiri: 'جمع گژھان چھُ',
    ladakhi: 'སྤྲོད་བཞིན་ཡོད།',
  );

  static String submit(AppStrings strings) => strings.localized(
    telugu: 'సబ్మిట్',
    english: 'Submit',
    hindi: 'सबमिट',
    tamil: 'சமர்ப்பி',
    kannada: 'ಸಲ್ಲಿಸಿ',
    malayalam: 'സമർപ്പിക്കുക',
    assamese: 'জমা দিয়ক',
    konkani: 'सादर',
    gujarati: 'સબમિટ',
    marathi: 'सबमिट',
    meitei: 'Submit',
    mizo: 'Submit',
    odia: 'ସବମିଟ୍',
    punjabi: 'ਸਬਮਿਟ',
    nepali: 'पेश गर्नुहोस्',
    bengali: 'জমা দিন',
    kashmiri: 'جمع کریو',
    ladakhi: 'སྤྲོད།',
  );

  static String next(AppStrings strings) => strings.localized(
    telugu: 'తర్వాత',
    english: 'Next',
    hindi: 'अगला',
    tamil: 'அடுத்து',
    kannada: 'ಮುಂದೆ',
    malayalam: 'അടുത്തത്',
    assamese: 'পৰৱৰ্তী',
    konkani: 'फुडें',
    gujarati: 'આગળ',
    marathi: 'पुढे',
    meitei: 'Mathang',
    mizo: 'Dawt leh',
    odia: 'ପରବର୍ତ୍ତୀ',
    punjabi: 'ਅਗਲਾ',
    nepali: 'अर्को',
    bengali: 'পরবর্তী',
    kashmiri: 'اگُر',
    ladakhi: 'རྗེས་མ།',
  );
}

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  static const int _secondsPerQuestion = 30;
  static const String _skippedOptionId = '__skipped__';

  final DailyQuizService _service = DailyQuizService();
  final PageController _pageController = PageController();
  final Map<String, String> _selectedOptionIds = <String, String>{};
  DailyQuizFeed? _feed;
  Timer? _timer;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  bool _quizStarted = false;
  bool _showAttemptReview = false;
  int _currentIndex = 0;
  int _remainingSeconds = _secondsPerQuestion;
  DateTime? _quizStartedAt;

  @override
  void initState() {
    super.initState();
    unawaited(_loadQuiz());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _currentIndex = 0;
      _remainingSeconds = _secondsPerQuestion;
      _quizStarted = false;
      _showAttemptReview = false;
      _quizStartedAt = null;
      _selectedOptionIds.clear();
    });
    try {
      final feed = await _service.loadTodayQuiz(context.currentLanguage);
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _selectedOptionIds.addEntries(
          feed.attempt.answers.values.map(
            (answer) => MapEntry(answer.questionId, answer.selectedOptionId),
          ),
        );
        _quizStarted = feed.attempt.completed;
      });
      if (_quizStarted && !feed.attempt.completed) {
        _startQuestionTimer();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    final quiz = _feed?.quiz;
    final answered = _feed?.attempt.completed ?? false;
    if (quiz == null ||
        quiz.questions.isEmpty ||
        answered ||
        _submitting ||
        !_quizStarted) {
      return;
    }
    setState(() => _remainingSeconds = _secondsPerQuestion);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _handleQuestionTimeout();
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  void _handleQuestionTimeout() {
    final quiz = _feed?.quiz;
    if (quiz == null ||
        _submitting ||
        !_quizStarted ||
        _feed?.attempt.completed == true ||
        _currentIndex >= quiz.questions.length) {
      return;
    }
    final question = quiz.questions[_currentIndex];
    setState(() {
      _remainingSeconds = 0;
      _selectedOptionIds.putIfAbsent(question.id, () => _skippedOptionId);
    });
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || _submitting || _feed?.attempt.completed == true) {
        return;
      }
      final latestQuiz = _feed?.quiz;
      if (latestQuiz == null) return;
      if (_currentIndex < latestQuiz.questions.length - 1) {
        _goNext();
      }
    });
  }

  void _selectOption(DailyQuizQuestion question, DailyQuizOption option) {
    if (_feed?.attempt.completed == true ||
        _submitting ||
        !_quizStarted ||
        _selectedOptionIds.containsKey(question.id)) {
      return;
    }
    setState(() => _selectedOptionIds[question.id] = option.id);
  }

  void _startQuiz() {
    if (_quizStarted || _submitting) {
      return;
    }
    setState(() {
      _quizStarted = true;
      _quizStartedAt = DateTime.now();
      _remainingSeconds = _secondsPerQuestion;
    });
    _startQuestionTimer();
  }

  void _showAttemptedReview() {
    _timer?.cancel();
    setState(() {
      _currentIndex = 0;
      _showAttemptReview = true;
      _quizStarted = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      _pageController.jumpToPage(0);
    });
  }

  int _quizDurationSeconds(DailyQuiz quiz) {
    final startedAt = _quizStartedAt;
    if (startedAt == null) {
      return 0;
    }
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    final maxDuration = quiz.questions.length * _secondsPerQuestion;
    return elapsed.clamp(1, maxDuration);
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _goPrevious() {
    if (_currentIndex == 0 || _submitting || _feed?.attempt.completed != true) {
      return;
    }
    final nextIndex = _currentIndex - 1;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentIndex = nextIndex);
    _startQuestionTimer();
  }

  void _goNext() {
    final quiz = _feed?.quiz;
    if (quiz == null || _submitting) {
      return;
    }
    if (_currentIndex >= quiz.questions.length - 1) {
      return;
    }
    final currentQuestion = quiz.questions[_currentIndex];
    if (_feed?.attempt.completed != true &&
        !_selectedOptionIds.containsKey(currentQuestion.id)) {
      return;
    }
    final nextIndex = _currentIndex + 1;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentIndex = nextIndex);
    _startQuestionTimer();
  }

  Future<void> _submitQuiz(DailyQuiz quiz) async {
    if (_submitting || _feed == null) {
      return;
    }
    final unanswered = quiz.questions
        .where((question) => !_selectedOptionIds.containsKey(question.id))
        .length;
    if (unanswered > 0) {
      final strings = context.strings;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_QuizCopy.answerAll(strings))));
      return;
    }
    _timer?.cancel();
    setState(() => _submitting = true);
    try {
      final durationSeconds = _quizDurationSeconds(quiz);
      final submittedAnswers = <String, DailyQuizAnswerState>{
        ..._feed!.attempt.answers,
      };
      for (final question in quiz.questions) {
        if (submittedAnswers.containsKey(question.id)) {
          continue;
        }
        final optionId = _selectedOptionIds[question.id];
        if (optionId == null || optionId.isEmpty) {
          continue;
        }
        final result = await _service.submitAnswer(
          quizId: quiz.id,
          questionId: question.id,
          optionId: optionId,
          language: context.currentLanguage,
          durationSeconds: durationSeconds,
        );
        submittedAnswers[question.id] = result.answer;
      }
      if (!mounted) return;
      final correctCount = submittedAnswers.values
          .where((answer) => answer.isCorrect)
          .length;
      setState(() {
        _feed = DailyQuizFeed(
          quiz: quiz,
          attempt: DailyQuizAttempt(
            answers: submittedAnswers,
            correctCount: correctCount,
            totalAnswered: submittedAnswers.length,
            completed: true,
          ),
        );
      });
      _showSubmittedDialogAndReturnHome(
        correctCount: correctCount,
        totalQuestions: quiz.questions.length,
        quizDateKey: quiz.dateKey,
        submittedAt: DateTime.now(),
        durationLabel: _formatDuration(durationSeconds),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showSubmittedDialogAndReturnHome({
    required int correctCount,
    required int totalQuestions,
    required String quizDateKey,
    required DateTime submittedAt,
    required String durationLabel,
  }) {
    final strings = context.strings;
    final navigator = Navigator.of(context);
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xF2FFFFFF),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final dialogNavigator = Navigator.of(dialogContext);
          return _SubmittedScoreOverlay(
            title: _QuizCopy.congratulations(strings),
            subtitle: _QuizCopy.resultUpdated(strings),
            score: '$correctCount/$totalQuestions',
            correctCount: correctCount,
            totalQuestions: totalQuestions,
            quizDateKey: quizDateKey,
            submittedAt: submittedAt,
            durationLabel: durationLabel,
            closeLabel: _QuizCopy.close(strings),
            onClose: () {
              if (dialogNavigator.canPop()) {
                dialogNavigator.pop();
              }
              if (mounted && navigator.canPop()) {
                navigator.pop();
              }
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: curved, child: child),
          );
        },
      ),
    );
  }

  String _resolvedQuizTitle(AppStrings strings, String rawTitle) {
    final title = rawTitle.trim();
    if (title.isEmpty || title.toLowerCase() == 'daily quiz') {
      return _QuizCopy.dailyQuiz(strings);
    }
    return title;
  }

  String _localizedErrorMessage(AppStrings strings, String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('login required')) {
      return strings.localized(
        telugu: 'క్విజ్ ఆడటానికి లాగిన్ కావాలి.',
        english: 'Login is required to play the quiz.',
        hindi: 'क्विज़ खेलने के लिए लॉगिन जरूरी है।',
        tamil: 'வினாடி வினா விளையாட உள்நுழைவு அவசியம்.',
        kannada: 'ಕ್ವಿಜ್ ಆಡಲು ಲಾಗಿನ್ ಅಗತ್ಯ.',
        malayalam: 'ക്വിസ് കളിക്കാൻ ലോഗിൻ ആവശ്യമാണ്.',
        assamese: 'কুইজ খেলিবলৈ লগইন প্ৰয়োজন।',
        konkani: 'क्विझ खेळपाक लॉगिन जाय.',
        gujarati: 'ક્વિઝ રમવા માટે લોગિન જરૂરી છે.',
        marathi: 'क्विझ खेळण्यासाठी लॉगिन आवश्यक आहे.',
        meitei: 'Quiz sannaba login touba mathou tai.',
        mizo: 'Quiz khelh nan login a ngai.',
        odia: 'କୁଇଜ୍ ଖେଳିବା ପାଇଁ ଲଗଇନ୍ ଆବଶ୍ୟକ।',
        punjabi: 'ਕਵਿਜ਼ ਖੇਡਣ ਲਈ ਲਾਗਇਨ ਲਾਜ਼ਮੀ ਹੈ।',
        nepali: 'क्विज खेल्न लगइन आवश्यक छ।',
        bengali: 'কুইজ খেলতে লগইন প্রয়োজন।',
        kashmiri: 'کوئز کھیلنہٕ خٲطرٕ لاگ اِن ضروری چھُ۔',
        ladakhi: 'དྲི་བ་རྩེད་པར་ནང་འཛུལ་དགོས།',
      );
    }
    return strings.localized(
      telugu: 'క్విజ్ లోడ్ చేయడంలో సమస్య వచ్చింది. మళ్లీ ప్రయత్నించండి.',
      english: 'Unable to load quiz. Please try again.',
      hindi: 'क्विज़ लोड नहीं हो पाया। फिर कोशिश करें।',
      tamil: 'வினாடி வினா ஏற்ற முடியவில்லை. மீண்டும் முயற்சி செய்யவும்.',
      kannada: 'ಕ್ವಿಜ್ ಲೋಡ್ ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ക്വിസ് ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
      assamese: 'কুইজ লোড কৰিব পৰা নগ’ল। পুনৰ চেষ্টা কৰক।',
      konkani: 'क्विझ लोड जावंक शकना. परत यत्न करात.',
      gujarati: 'ક્વિઝ લોડ થઈ નથી. ફરી પ્રયાસ કરો.',
      marathi: 'क्विझ लोड झाली नाही. पुन्हा प्रयत्न करा.',
      meitei: 'Quiz load touba ngamde. Amuk hotnou.',
      mizo: 'Quiz load theih a ni lo. Beisei leh rawh.',
      odia: 'କୁଇଜ୍ ଲୋଡ୍ ହେଲା ନାହିଁ। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
      punjabi: 'ਕਵਿਜ਼ ਲੋਡ ਨਹੀਂ ਹੋਈ। ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      nepali: 'क्विज लोड भएन। फेरि प्रयास गर्नुहोस्।',
      bengali: 'কুইজ লোড করা যায়নি। আবার চেষ্টা করুন।',
      kashmiri: 'کوئز لوڈ نہٕ گۆو۔ دوبار کوشش کریو۔',
      ladakhi: 'དྲི་བ་འཇུག་མ་ཐུབ། ཡང་བསྐྱར་ཚོད་ལྟ།',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title = _QuizCopy.dailyQuiz(strings);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        titleTextStyle: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        elevation: 0.6,
        shadowColor: const Color(0x1A0F172A),
        surfaceTintColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFFFFFFF),
              Color(0xFFF8FAFC),
              Color(0xFFF5F7FB),
              Color(0xFFFFFFFF),
            ],
            stops: <double>[0, 0.18, 0.58, 1],
          ),
        ),
        child: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final strings = context.strings;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _QuizEmptyState(
        title: _QuizCopy.loadFailed(strings),
        message: _localizedErrorMessage(strings, _error!),
        buttonLabel: _QuizCopy.retry(strings),
        onPressed: _loadQuiz,
      );
    }
    final feed = _feed;
    final quiz = feed?.quiz;
    if (feed == null || quiz == null || quiz.questions.isEmpty) {
      return _QuizEmptyState(
        title: _QuizCopy.noQuizToday(strings),
        message: _QuizCopy.noQuizMessage(strings),
        buttonLabel: _QuizCopy.refresh(strings),
        onPressed: _loadQuiz,
      );
    }
    final submitted = feed.attempt.completed;
    final totalQuestions = quiz.questions.length;
    if (submitted && !_showAttemptReview) {
      return _AttemptSummaryCard(
        title: _resolvedQuizTitle(strings, quiz.title),
        score: '${feed.attempt.correctCount}/$totalQuestions',
        correctCount: feed.attempt.correctCount,
        totalQuestions: totalQuestions,
        onCheck: _showAttemptedReview,
      );
    }
    final currentQuestion = quiz.questions[_currentIndex];
    final progress = submitted
        ? 1.0
        : (_remainingSeconds / _secondsPerQuestion).clamp(0.0, 1.0);
    return Column(
      children: [
        _QuizTopBar(
          title: _resolvedQuizTitle(strings, quiz.title),
          currentIndex: _currentIndex,
          totalQuestions: totalQuestions,
          selectedCount: _selectedOptionIds.length,
          remainingSeconds: submitted ? 0 : _remainingSeconds,
          progress: progress,
          correctCount: feed.attempt.correctCount,
          submitted: submitted,
          quizStarted: _quizStarted,
          onStart: _startQuiz,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalQuestions,
            itemBuilder: (context, index) {
              final question = quiz.questions[index];
              return _QuestionViewport(
                key: ValueKey(question.id),
                question: question,
                index: index + 1,
                selectedOptionId: _selectedOptionIds[question.id],
                answer: feed.attempt.answers[question.id],
                submitted: submitted,
                quizStarted: _quizStarted,
                onOptionTap: (option) => _selectOption(question, option),
              );
            },
          ),
        ),
        _QuizFooter(
          currentIndex: _currentIndex,
          totalQuestions: totalQuestions,
          selectedCount: _selectedOptionIds.length,
          submitted: submitted,
          submitting: _submitting,
          quizStarted: _quizStarted,
          canGoPrevious: submitted && _currentIndex > 0,
          canGoNext: _currentIndex < totalQuestions - 1,
          currentAnswered:
              submitted || _selectedOptionIds.containsKey(currentQuestion.id),
          onPrevious: _goPrevious,
          onNext: _goNext,
          onSubmit: () => _submitQuiz(quiz),
        ),
      ],
    );
  }
}

class _AttemptSummaryCard extends StatelessWidget {
  const _AttemptSummaryCard({
    required this.title,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.onCheck,
  });

  final String title;
  final String score;
  final int correctCount;
  final int totalQuestions;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _QuizSvgIcon(
                kind: _QuizSvgIconKind.trophy,
                size: 58,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(height: 14),
              Text(
                _QuizCopy.attemptedQuiz(strings),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      score,
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$correctCount / $totalQuestions',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _QuizCopy.checkAttemptedQuestions(strings),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCheck,
                  icon: const Icon(Icons.fact_check_rounded),
                  label: Text(_QuizCopy.check(strings)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizTopBar extends StatelessWidget {
  const _QuizTopBar({
    required this.title,
    required this.currentIndex,
    required this.totalQuestions,
    required this.selectedCount,
    required this.remainingSeconds,
    required this.progress,
    required this.correctCount,
    required this.submitted,
    required this.quizStarted,
    required this.onStart,
  });

  final String title;
  final int currentIndex;
  final int totalQuestions;
  final int selectedCount;
  final int remainingSeconds;
  final double progress;
  final int correctCount;
  final bool submitted;
  final bool quizStarted;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final showStart = !submitted && !quizStarted;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 0,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (showStart)
                Tooltip(
                  message: _QuizCopy.startHint(strings),
                  child: _AnimatedStartButton(
                    label: _QuizCopy.start(strings),
                    onPressed: onStart,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TimerBubble(
                label: '$totalQuestions/$totalQuestions',
                icon: _QuizSvgIconKind.quiz,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _TimerBubble(
                    label: submitted
                        ? '$correctCount/$totalQuestions'
                        : _QuizCopy.seconds(strings, remainingSeconds),
                    icon: submitted
                        ? _QuizSvgIconKind.trophy
                        : _QuizSvgIconKind.timer,
                    color: submitted
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: submitted ? 1 : progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                submitted
                    ? const Color(0xFF22C55E)
                    : remainingSeconds <= 5
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _QuizCopy.questionOf(
                    strings,
                    currentIndex + 1,
                    totalQuestions,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _QuizCopy.answered(strings, selectedCount, totalQuestions),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedStartButton extends StatefulWidget {
  const _AnimatedStartButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_AnimatedStartButton> createState() => _AnimatedStartButtonState();
}

class _AnimatedStartButtonState extends State<_AnimatedStartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(begin: 1, end: 1.045)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FilledButton.icon(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(widget.label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _QuizSvgIcon extends StatelessWidget {
  const _QuizSvgIcon({required this.kind, required this.size, this.color});

  final _QuizSvgIconKind? kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svgForKind(kind),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  String _svgForKind(_QuizSvgIconKind? value) {
    return switch (value) {
      _QuizSvgIconKind.quiz =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="quizA" x1="8" y1="6" x2="58" y2="62"><stop stop-color="#A78BFA"/><stop offset="1" stop-color="#4F46E5"/></linearGradient>
    <linearGradient id="quizB" x1="16" y1="14" x2="48" y2="52"><stop stop-color="#FFFFFF"/><stop offset="1" stop-color="#EEF2FF"/></linearGradient>
  </defs>
  <rect x="10" y="8" width="44" height="50" rx="12" fill="url(#quizA)"/>
  <rect x="16" y="15" width="32" height="36" rx="8" fill="url(#quizB)" opacity=".96"/>
  <circle cx="25" cy="26" r="3.2" fill="#22C55E"/>
  <path d="M30.5 26h11" stroke="#4338CA" stroke-width="4" stroke-linecap="round"/>
  <circle cx="25" cy="36" r="3.2" fill="#F59E0B"/>
  <path d="M30.5 36h11" stroke="#4338CA" stroke-width="4" stroke-linecap="round"/>
  <path d="M22 47l3 3 6-7" fill="none" stroke="#16A34A" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M34 47h8" stroke="#4338CA" stroke-width="4" stroke-linecap="round"/>
</svg>''',
      _QuizSvgIconKind.timer =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="timerA" x1="14" y1="8" x2="50" y2="58"><stop stop-color="#60A5FA"/><stop offset="1" stop-color="#2563EB"/></linearGradient></defs>
  <rect x="25" y="5" width="14" height="7" rx="3" fill="#1E3A8A"/>
  <circle cx="32" cy="34" r="24" fill="url(#timerA)"/>
  <circle cx="32" cy="34" r="17" fill="#EFF6FF"/>
  <path d="M32 21v13l9 6" stroke="#1D4ED8" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M18 16l-4-4M46 16l4-4" stroke="#38BDF8" stroke-width="5" stroke-linecap="round"/>
</svg>''',
      _QuizSvgIconKind.trophy =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="cupA" x1="16" y1="7" x2="48" y2="54"><stop stop-color="#FDE68A"/><stop offset=".55" stop-color="#F59E0B"/><stop offset="1" stop-color="#B45309"/></linearGradient></defs>
  <path d="M20 12h24v15c0 8-5 14-12 14s-12-6-12-14V12z" fill="url(#cupA)"/>
  <path d="M20 17h-8v7c0 7 5 12 12 12M44 17h8v7c0 7-5 12-12 12" fill="none" stroke="#FBBF24" stroke-width="5" stroke-linecap="round"/>
  <path d="M32 41v8" stroke="#92400E" stroke-width="5" stroke-linecap="round"/>
  <rect x="22" y="49" width="20" height="7" rx="3" fill="#78350F"/>
  <path d="M28 20l4-3 4 3-1.4 4.8h-5.2L28 20z" fill="#FFF7ED"/>
</svg>''',
      _QuizSvgIconKind.success =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="okA" x1="8" y1="8" x2="56" y2="56"><stop stop-color="#86EFAC"/><stop offset="1" stop-color="#16A34A"/></linearGradient></defs>
  <circle cx="32" cy="32" r="26" fill="url(#okA)"/>
  <path d="M20 33.5l8 8L45 23" fill="none" stroke="#FFFFFF" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="23" cy="18" r="4" fill="#DCFCE7" opacity=".75"/>
</svg>''',
      _QuizSvgIconKind.info =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="infoA" x1="8" y1="8" x2="56" y2="56"><stop stop-color="#FCA5A5"/><stop offset="1" stop-color="#DC2626"/></linearGradient></defs>
  <circle cx="32" cy="32" r="26" fill="url(#infoA)"/>
  <rect x="29" y="28" width="6" height="18" rx="3" fill="#FFFFFF"/>
  <circle cx="32" cy="20" r="4" fill="#FFFFFF"/>
</svg>''',
      _QuizSvgIconKind.correct =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="25" fill="#DCFCE7" stroke="#22C55E" stroke-width="5"/>
  <path d="M20 33l8 8 17-18" fill="none" stroke="#16A34A" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
      _QuizSvgIconKind.wrong =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="25" fill="#FEE2E2" stroke="#EF4444" stroke-width="5"/>
  <path d="M23 23l18 18M41 23L23 41" stroke="#DC2626" stroke-width="7" stroke-linecap="round"/>
</svg>''',
      _QuizSvgIconKind.selected =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="25" fill="#FEF3C7" stroke="#F59E0B" stroke-width="5"/>
  <circle cx="32" cy="32" r="11" fill="#F59E0B"/>
</svg>''',
      _QuizSvgIconKind.empty =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="emptyA" x1="10" y1="7" x2="55" y2="58"><stop stop-color="#93C5FD"/><stop offset="1" stop-color="#2563EB"/></linearGradient></defs>
  <rect x="12" y="10" width="40" height="48" rx="12" fill="url(#emptyA)"/>
  <rect x="18" y="17" width="28" height="30" rx="7" fill="#FFFFFF" opacity=".94"/>
  <path d="M26 29c.1-3.3 2.4-5.5 5.8-5.5 3.3 0 5.7 2 5.7 4.8 0 2-.9 3.2-2.9 4.4-1.5.9-2 1.5-2 2.9v.6h-4v-.8c0-2.7 1-4 3.2-5.3 1.2-.8 1.7-1.2 1.7-2 0-.9-.8-1.5-1.9-1.5-1.3 0-2.2.9-2.3 2.5H26z" fill="#2563EB"/>
  <circle cx="30.7" cy="42" r="2.6" fill="#F59E0B"/>
</svg>''',
      null =>
        '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="24" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="5"/>
</svg>''',
    };
  }
}

class _QuestionViewport extends StatelessWidget {
  const _QuestionViewport({
    super.key,
    required this.question,
    required this.index,
    required this.selectedOptionId,
    required this.answer,
    required this.submitted,
    required this.quizStarted,
    required this.onOptionTap,
  });

  final DailyQuizQuestion question;
  final int index;
  final String? selectedOptionId;
  final DailyQuizAnswerState? answer;
  final bool submitted;
  final bool quizStarted;
  final ValueChanged<DailyQuizOption> onOptionTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFBEB),
                        Color(0xFFEFF6FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 1.4),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x220F172A),
                        blurRadius: 0,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF8B5CF6),
                              Color(0xFF2563EB),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.28),
                              blurRadius: 0,
                              offset: Offset.zero,
                            ),
                          ],
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (
                  int optionIndex = 0;
                  optionIndex < question.options.length;
                  optionIndex++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuizOptionBubble(
                      option: question.options[optionIndex],
                      optionIndex: optionIndex,
                      selectedOptionId: selectedOptionId,
                      correctOptionId: question.correctOptionId,
                      answer: answer,
                      submitted: submitted || !quizStarted,
                      onTap: () => onOptionTap(question.options[optionIndex]),
                    ),
                  ),
                if (answer != null) ...[
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _ResultBubble(
                      key: ValueKey(answer!.isCorrect),
                      text: answer!.isCorrect
                          ? _QuizCopy.congratulations(strings)
                          : _QuizCopy.correctHighlighted(strings),
                      success: answer!.isCorrect,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuizOptionBubble extends StatelessWidget {
  const _QuizOptionBubble({
    required this.option,
    required this.optionIndex,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.answer,
    required this.submitted,
    required this.onTap,
  });

  final DailyQuizOption option;
  final int optionIndex;
  final String? selectedOptionId;
  final String correctOptionId;
  final DailyQuizAnswerState? answer;
  final bool submitted;
  final VoidCallback onTap;

  static const List<Color> _baseColors = <Color>[
    Color(0xFFEFF6FF),
    Color(0xFFFDF2F8),
    Color(0xFFECFDF5),
    Color(0xFFFFF7ED),
  ];

  static const List<Color> _borderColors = <Color>[
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFB923C),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = selectedOptionId == option.id;
    final revealAnswer = answer != null || selectedOptionId != null;
    final resolvedCorrectOptionId = answer?.correctOptionId.isNotEmpty == true
        ? answer!.correctOptionId
        : correctOptionId;
    final correct = revealAnswer && resolvedCorrectOptionId == option.id;
    final incorrect = revealAnswer && !correct;
    final background = correct
        ? const Color(0xFF059669)
        : incorrect
        ? const Color(0xFFE11D48)
        : selected
        ? const Color(0xFFEFF6FF)
        : _baseColors[optionIndex % _baseColors.length];
    final borderColor = correct
        ? const Color(0xFF15803D)
        : incorrect
        ? const Color(0xFFB91C1C)
        : selected
        ? const Color(0xFF2563EB)
        : _borderColors[optionIndex % _borderColors.length];
    final foregroundColor = correct || incorrect
        ? Colors.white
        : const Color(0xFF111827);
    final avatarBackgroundColor = correct || incorrect
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white;
    final avatarTextColor = correct || incorrect ? Colors.white : borderColor;
    final icon = correct
        ? _QuizSvgIconKind.correct
        : incorrect
        ? _QuizSvgIconKind.wrong
        : selected
        ? _QuizSvgIconKind.selected
        : null;
    return InkWell(
      onTap: submitted ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: revealAnswer ? 1.6 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarBackgroundColor,
              child: Text(
                String.fromCharCode(65 + optionIndex),
                style: TextStyle(
                  color: avatarTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _QuizSvgIcon(kind: icon, color: foregroundColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _QuizFooter extends StatelessWidget {
  const _QuizFooter({
    required this.currentIndex,
    required this.totalQuestions,
    required this.selectedCount,
    required this.submitted,
    required this.submitting,
    required this.quizStarted,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.currentAnswered,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final int currentIndex;
  final int totalQuestions;
  final int selectedCount;
  final bool submitted;
  final bool submitting;
  final bool quizStarted;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool currentAnswered;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final isLast = currentIndex == totalQuestions - 1;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: quizStarted && canGoPrevious && !submitting
                ? onPrevious
                : null,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _QuizCopy.answered(strings, selectedCount, totalQuestions),
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: totalQuestions == 0
                        ? 0
                        : (selectedCount / totalQuestions).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isLast)
            FilledButton.icon(
              onPressed:
                  submitted ||
                      submitting ||
                      !quizStarted ||
                      selectedCount < totalQuestions ||
                      !currentAnswered
                  ? null
                  : onSubmit,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                submitting
                    ? _QuizCopy.submitting(strings)
                    : _QuizCopy.submit(strings),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed:
                  quizStarted && canGoNext && currentAnswered && !submitting
                  ? onNext
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_QuizCopy.next(strings)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimerBubble extends StatelessWidget {
  const _TimerBubble({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final _QuizSvgIconKind icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuizSvgIcon(kind: icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBubble extends StatelessWidget {
  const _ResultBubble({super.key, required this.text, required this.success});

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.34), width: 1.4),
      ),
      child: Row(
        children: [
          _QuizSvgIcon(
            kind: success ? _QuizSvgIconKind.success : _QuizSvgIconKind.info,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizTicketDetails {
  const _QuizTicketDetails({
    required this.userName,
    required this.userPhotoPath,
    required this.userPhotoUrl,
    required this.regionName,
  });

  final String userName;
  final String userPhotoPath;
  final String userPhotoUrl;
  final String regionName;
}

class _SubmittedScoreOverlay extends StatefulWidget {
  const _SubmittedScoreOverlay({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.quizDateKey,
    required this.submittedAt,
    required this.durationLabel,
    required this.closeLabel,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final String score;
  final int correctCount;
  final int totalQuestions;
  final String quizDateKey;
  final DateTime submittedAt;
  final String durationLabel;
  final String closeLabel;
  final VoidCallback onClose;

  @override
  State<_SubmittedScoreOverlay> createState() => _SubmittedScoreOverlayState();
}

class _SubmittedScoreOverlayState extends State<_SubmittedScoreOverlay> {
  final GlobalKey _ticketKey = GlobalKey();
  late final Future<_QuizTicketDetails> _detailsFuture = _loadDetails();
  bool _sharing = false;
  bool _downloading = false;

  Future<_QuizTicketDetails> _loadDetails() async {
    final language = context.currentLanguage;
    final profile = await PosterProfileService.load();
    final region = await AppRegionService.loadSelection();
    final name = profile.resolvedName(language: language).trim();
    return _QuizTicketDetails(
      userName: name.isEmpty ? PosterProfileService.defaultName : name,
      userPhotoPath: profile.photoPath.trim().isNotEmpty
          ? profile.photoPath.trim()
          : profile.originalPhotoPath.trim(),
      userPhotoUrl: profile.photoUrl.trim().isNotEmpty
          ? profile.photoUrl.trim()
          : profile.originalPhotoUrl.trim(),
      regionName: region?.nativeName ?? region?.name ?? '',
    );
  }

  Future<Uint8List> _captureTicketBytes() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final boundary =
        _ticketKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Quiz ticket is not ready.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    image.dispose();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Unable to capture quiz ticket.');
    }
    return bytes;
  }

  Future<File> _writeTicketFile(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/mana_poster_quiz_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _shareTicket(AppStrings strings) async {
    if (_sharing || _downloading) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureTicketBytes();
      final file = await _writeTicketFile(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'image/png')],
          text: _QuizCopy.shareMessage(
            strings,
            widget.score,
            AppPublicInfo.playStoreUrl,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_QuizCopy.ticketActionFailed(strings))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _downloadTicket(AppStrings strings) async {
    if (_sharing || _downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await _captureTicketBytes();
      await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'mana_poster_quiz_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_QuizCopy.savedToGallery(strings))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_QuizCopy.ticketActionFailed(strings))),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _formatSubmittedAt(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-${value.year} '
        '$hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF4C1D95),
              Color(0xFF6D28D9),
              Color(0xFF9333EA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<_QuizTicketDetails>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            final details =
                snapshot.data ??
                const _QuizTicketDetails(
                  userName: 'Mana Poster User',
                  userPhotoPath: '',
                  userPhotoUrl: '',
                  regionName: '',
                );
            return SafeArea(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 4),
                  const Image(
                    image: AssetImage('assets/branding/mana_poster_logo.png'),
                    height: 42,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mana Poster AI Daily Quiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const ticketRatio = 1.5;
                          final maxWidthByHeight =
                              constraints.maxHeight / ticketRatio;
                          var width = constraints.maxWidth.clamp(240.0, 360.0);
                          if (width > maxWidthByHeight) {
                            width = maxWidthByHeight.clamp(240.0, 360.0);
                          }
                          return SizedBox(
                            width: width,
                            child: RepaintBoundary(
                              key: _ticketKey,
                              child: _QuizResultTicket(
                                title: widget.title,
                                subtitle: widget.subtitle,
                                score: widget.score,
                                correctCount: widget.correctCount,
                                totalQuestions: widget.totalQuestions,
                                quizDateKey: widget.quizDateKey,
                                submittedAt: _formatSubmittedAt(
                                  widget.submittedAt,
                                ),
                                durationLabel: widget.durationLabel,
                                details: details,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sharing
                              ? null
                              : () => _shareTicket(strings),
                          icon: _sharing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF047857),
                                  ),
                                )
                              : const Icon(Icons.ios_share_rounded),
                          label: Text(_QuizCopy.share(strings)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _downloading
                              ? null
                              : () => _downloadTicket(strings),
                          icon: _downloading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF047857),
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(_QuizCopy.download(strings)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(widget.closeLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6D28D9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuizResultTicket extends StatelessWidget {
  const _QuizResultTicket({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.quizDateKey,
    required this.submittedAt,
    required this.durationLabel,
    required this.details,
  });

  final String title;
  final String subtitle;
  final String score;
  final int correctCount;
  final int totalQuestions;
  final String quizDateKey;
  final String submittedAt;
  final String durationLabel;
  final _QuizTicketDetails details;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: width * 1.5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9D5FF), width: 1.4),
            ),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF6D28D9), Color(0xFFEC4899)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Image(
                        image: AssetImage(
                          'assets/branding/mana_poster_logo.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Mana Poster AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'DAILY QUIZ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _TicketStars(),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4C1D95),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _QuizTicketAvatar(details: details, size: 56),
              const SizedBox(height: 8),
              Text(
                details.userName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              _TicketScoreBadge(score: score),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE9D5FF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _TicketMiniStat(
                              label: 'Correct',
                              value: '$correctCount',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TicketMiniStat(
                              label: 'Total',
                              value: '$totalQuestions',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TicketMiniStat(
                              label: 'Time',
                              value: durationLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TicketInfoRow(
                        label: 'State',
                        value: details.regionName.isEmpty
                            ? '-'
                            : details.regionName,
                        dense: true,
                      ),
                      _TicketInfoRow(
                        label: 'Quiz Date',
                        value: quizDateKey,
                        dense: true,
                      ),
                      _TicketInfoRow(
                        label: _QuizCopy.submitted(context.strings),
                        value: submittedAt,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuizTicketAvatar extends StatelessWidget {
  const _QuizTicketAvatar({required this.details, this.size = 76});

  final _QuizTicketDetails details;
  final double size;

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    if (details.userPhotoPath.isNotEmpty &&
        File(details.userPhotoPath).existsSync()) {
      provider = FileImage(File(details.userPhotoPath));
    } else if (details.userPhotoUrl.isNotEmpty) {
      provider = NetworkImage(details.userPhotoUrl);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF5F3FF),
        border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
        image: provider == null
            ? null
            : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: provider == null
          ? const Icon(Icons.person_rounded, color: Color(0xFF065F46), size: 38)
          : null,
    );
  }
}

class _TicketStars extends StatelessWidget {
  const _TicketStars();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(
        5,
        (index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: Icon(Icons.star_rounded, color: Color(0xFFFFD95A), size: 25),
        ),
      ),
    );
  }
}

class _TicketScoreBadge extends StatelessWidget {
  const _TicketScoreBadge({required this.score});

  final String score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 86,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF10B981), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            score,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'SCORE',
            style: TextStyle(
              color: Color(0xFF047857),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({
    required this.label,
    required this.value,
    this.dense = false,
  });

  final String label;
  final String value;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 2 : 5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: dense ? 11 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: dense ? 11 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketMiniStat extends StatelessWidget {
  const _TicketMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9D5FF),
        ),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF047857),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizEmptyState extends StatelessWidget {
  const _QuizEmptyState({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _QuizSvgIcon(
              kind: _QuizSvgIconKind.empty,
              size: 58,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4B5563), height: 1.35),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
