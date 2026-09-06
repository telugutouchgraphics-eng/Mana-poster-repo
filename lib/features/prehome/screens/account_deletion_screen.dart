import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/account_deletion_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen>
    with AppLanguageStateMixin {
  final AccountDeletionService _accountDeletionService =
      AccountDeletionService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _busy = false;

  Future<void> _openDeletionPolicy() async {
    final uri = Uri.parse(AppPublicInfo.accountDeletionUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || opened) {
      return;
    }
    _showSnackBar(
      context.strings.localized(
        telugu: 'లింక్ తెరవలేకపోయాం. ఇంకోసారి ప్రయత్నించండి.',
        english: 'Could not open the link. Please try again.',
        hindi: 'लिंक नहीं खुल सका। कृपया पुनः प्रयास करें।',
        tamil: 'இணைப்பைத் திறக்க முடியவில்லை. மீண்டும் முயல்க.',
        kannada: 'ಲಿಂಕ್ ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
        malayalam: 'ലിങ്ക് തുറക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കുക.',
        marathi: 'लिंक उघडता आली नाही. कृपया पुन्हा प्रयत्न करा.',
        gujarati: 'લિંક ખોલી શકાઈ નથી. ફરી પ્રયાસ કરો.',
        bengali: 'লিঙ্ক খোলা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
        punjabi: 'ਲਿੰਕ ਨਹੀਂ ਖੁੱਲ੍ਹ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
        odia: 'ଲିଙ୍କ୍ ଖୋଲିପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
        assamese: 'লিংক খোল খাব নোৱাৰিলে। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
        konkani: 'लिंक उकती जाली ना. उपकार करून परत प्रयत्न करात.',
        nepali: 'लिङ्क खोल्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
        meitei: 'Link hangdokpa ngamde. Amuk hanna hotnabiyu.',
        mizo: 'Link hawng thei lo. Khawngaihin ti nawn leh rawh.',
        kashmiri: 'لِنک نہ کھٔلِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
        ladakhi: 'Link ཁ་འབྱེད་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
      ),
    );
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppPublicInfo.supportEmail,
      queryParameters: <String, String>{
        'subject': 'Mana Poster Ai account deletion help',
      },
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || opened) {
      return;
    }
    _showSnackBar(
      context.strings.localized(
        telugu: 'మెయిల్ యాప్ తెరవలేకపోయాం. ఇంకోసారి ప్రయత్నించండి.',
        english: 'Could not open the mail app. Please try again.',
        hindi: 'मेल ऐप नहीं खुला। कृपया पुनः प्रयास करें।',
        tamil: 'அஞ்சல் செயலியைத் திறக்க முடியவில்லை. மீண்டும் முயல்க.',
        kannada: 'ಮೇಲ್ ಅಪ್ಲಿಕೇಶನ್ ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
        malayalam: 'മെയിൽ ആപ്പ് തുറക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കുക.',
        marathi: 'मेल अ‍ॅप उघडता आले नाही. कृपया पुन्हा प्रयत्न करा.',
        gujarati: 'મેઇલ એપ્લિકેશન ખોલી શકાઈ નથી. ફરી પ્રયાસ કરો.',
        bengali: 'মেল অ্যাপ খোলা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
        punjabi: 'ਮੇਲ ਐਪ ਨਹੀਂ ਖੁੱਲ੍ਹ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
        odia: 'ମେଲ୍ ଆପ୍ ଖୋଲିପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
        assamese: 'মেইল এপ খোল খাব নোৱাৰিলে। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
        konkani: 'मेल अ‍ॅप उकतें जालें ना. उपकार करून परत प्रयत्न करात.',
        nepali: 'मेल एप खोल्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
        meitei: 'Mail app hangdokpa ngamde. Amuk hanna hotnabiyu.',
        mizo: 'Mail app hawng thei lo. Khawngaihin ti nawn leh rawh.',
        kashmiri: 'میل ایپ نہ کھٔلِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
        ladakhi: 'Mail app ཁ་འབྱེད་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  String _localizedResultMessage(AccountDeletionResult result) {
    switch (result.message) {
      case 'No logged-in user found.':
        return context.strings.localized(
          telugu: 'లాగిన్ అయిన యూజర్ కనిపించలేదు.',
          english: 'No logged-in user found.',
          hindi: 'कोई लॉग इन किया हुआ उपयोगकर्ता नहीं मिला।',
          tamil: 'உள்நுழைந்த பயனர் எவரும் காணப்படவில்லை.',
          kannada: 'ಯಾವುದೇ ಲಾಗಿನ್ ಆದ ಬಳಕೆದಾರರು ಕಂಡುಬಂದಿಲ್ಲ.',
          malayalam: 'ലോഗിൻ ചെയ്ത ഉപയോക്താവിനെ കണ്ടെത്തിയില്ല.',
          marathi: 'लॉग इन केलेला वापरकर्ता आढळला नाही.',
          gujarati: 'કોઈ લૉગ ઇન થયેલ વપરાશકર્તા મળ્યા નથી.',
          bengali: 'লগ ইন করা কোনো ব্যবহারকারী পাওয়া যায়নি।',
          punjabi: 'ਕੋਈ ਲੌਗ-ਇਨ ਕੀਤਾ ਉਪਭੋਗਤਾ ਨਹੀਂ ਮਿਲਿਆ।',
          odia: 'କୌଣସି ଲଗଇନ୍ ବ୍ୟବହାରକାରୀ ମିଳିଲେ ନାହିଁ।',
          assamese: 'কোনো লগ-ইন কৰা ব্যৱহাৰকাৰী পোৱা নগ’ল।',
          konkani: 'लॉग इन केल्लो वापरपी मेळ्ळो ना.',
          nepali: 'कुनै लग-इन प्रयोगकर्ता भेटिएन।',
          meitei: 'Login touba user thengnakhide.',
          mizo: 'Login hmangtu hmuh a ni lo.',
          kashmiri: 'کانٛہہ لاگ اِن یوزر میول نہ۔',
          ladakhi: 'Login བྱས་པའི་སྤྱོད་མི་མ་རྙེད།',
        );
      case 'Account deleted successfully.':
        return context.strings.localized(
          telugu: 'అకౌంట్ డిలీట్ విజయవంతంగా పూర్తైంది.',
          english: 'Account deleted successfully.',
          hindi: 'खाता सफलतापूर्वक हटा दिया गया।',
          tamil: 'கணக்கு வெற்றிகரமாக நீக்கப்பட்டது.',
          kannada: 'ಖಾತೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ.',
          malayalam: 'അക്കൗണ്ട് വിജയകരമായി ഇല്ലാതാക്കി.',
          marathi: 'खाते यशस्वीरित्या हटवले.',
          gujarati: 'એકાઉન્ટ સફળતાપૂર્વક કાઢી નાખવામાં આવ્યું.',
          bengali: 'অ্যাকাউন্ট সফলভাবে মুছে ফেলা হয়েছে।',
          punjabi: 'ਖਾਤਾ ਸਫਲਤਾਪੂਰਵਕ ਮਿਟਾ ਦਿੱਤਾ ਗਿਆ।',
          odia: 'ଖାତା ସଫଳତାର ସହ ବିଲୋପ ହେଲା।',
          assamese: 'একাউণ্ট সফলতাৰে মচি পেলোৱা হ’ল।',
          konkani: 'खातें यशस्वीपणान काडून उडयलें.',
          nepali: 'खाता सफलतापूर्वक मेटाइयो।',
          meitei: 'Account mai-pakna muthatkhraba.',
          mizo: 'Account hlawhtling takin thaibo a ni.',
          kashmiri: 'اکاوُنٛٹ آو کامیابی سان ڈلیٖٹ کرنہٕ۔',
          ladakhi: 'རྩིས་ཁྲ་ལེགས་གྲུབ་ངང་སུབས།',
        );
      case 'Please log in again and retry account deletion.':
        return context.strings.localized(
          telugu: 'మళ్లీ లాగిన్ అయ్యి అకౌంట్ డిలీట్ ప్రయత్నించండి.',
          english: 'Please log in again and retry account deletion.',
          hindi: 'कृपया फिर से लॉगिन करें और खाता हटाने का प्रयास करें।',
          tamil: 'மீண்டும் உள்நுழைந்து கணக்கு நீக்கத்தை முயற்சிக்கவும்.',
          kannada: 'ದಯವಿಟ್ಟು ಮತ್ತೆ ಲಾಗಿನ್ ಮಾಡಿ ಮತ್ತು ಖಾತೆ ಅಳಿಸಲು ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'ദയവായി വീണ്ടും ലോഗിൻ ചെയ്ത് അക്കൗണ്ട് ഇല്ലാതാക്കാൻ ശ്രമിക്കുക.',
          marathi: 'कृपया पुन्हा लॉगिन करा आणि खाते हटवण्याचा प्रयत्न करा.',
          gujarati: 'કૃપા કરીને ફરીથી લૉગિન કરો અને એકાઉન્ટ કાઢી નાખવાનો પ્રયાસ કરો.',
          bengali: 'অনুগ্রহ করে আবার লগইন করুন এবং অ্যাকাউন্ট মুছে ফেলার চেষ্টা করুন।',
          punjabi: 'ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਲੌਗਇਨ ਕਰੋ ਅਤੇ ਖਾਤਾ ਮਿਟਾਉਣ ਦੀ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଦୟାକରି ପୁଣି ଲଗଇନ୍ କରନ୍ତୁ ଏବଂ ଖାତା ବିଲୋପ ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'অনুগ্ৰহ কৰি পুনৰ লগইন কৰক আৰু একাউণ্ট মচি পেলোৱাৰ চেষ্টা কৰক।',
          konkani: 'उपकार करून परत लॉगिन करात आनी खातें काडपाचो प्रयत्न करात.',
          nepali: 'कृपया पुन: लगइन गर्नुहोस् र खाता हटाउने प्रयास गर्नुहोस्।',
          meitei: 'Chanbiduna amuk login toubiyu amasung account muthatnaba hotnabiyu.',
          mizo: 'Khawngaihin login nawn la account thaibo leh rawh.',
          kashmiri: 'مہربٲنی کٔرتھ دۆبارٕ کٔریو لاگ اِن تہٕ اکاوُنٛٹ ڈلیٖٹ ہٕنٛز کٔریو کوشِش۔',
          ladakhi: 'ཡང་བསྐྱར་ login བྱས་ནས་རྩིས་ཁྲ་སུབ་པའི་འབད་བརྩོན་གནང།',
        );
      case 'Account deletion failed.':
        return context.strings.localized(
          telugu: 'అకౌంట్ డిలీట్ విఫలమైంది.',
          english: 'Account deletion failed.',
          hindi: 'खाता हटाना विफल रहा।',
          tamil: 'கணக்கு நீக்குதல் தோல்வியடைந்தது.',
          kannada: 'ಖಾತೆ ಅಳಿಸುವಿಕೆ ವಿಫಲವಾಗಿದೆ.',
          malayalam: 'അക്കൗണ്ട് ഇല്ലാതാക്കൽ പരാജയപ്പെട്ടു.',
          marathi: 'खाते हटवणे अयशस्वी झाले.',
          gujarati: 'એકાઉન્ટ કાઢી નાખવામાં નિષ્ફળ.',
          bengali: 'অ্যাকাউন্ট মুছে ফেলা ব্যর্থ হয়েছে।',
          punjabi: 'ਖਾਤਾ ਮਿਟਾਉਣਾ ਅਸਫਲ ਰਿਹਾ।',
          odia: 'ଖାତା ବିଲୋପ ବିଫଳ ହେଲା।',
          assamese: 'একাউণ্ট মচি পেলোৱা ব্যৰ্থ হ’ল।',
          konkani: 'खातें काडप अपेशी जालें.',
          nepali: 'खाता हटाउन असफल भयो।',
          meitei: 'Account muthatpa maipak-khide.',
          mizo: 'Account thaibo a hlawhchham.',
          kashmiri: 'اکاوُنٛٹ ڈلیٖٹ کرُن گوو ناکام۔',
          ladakhi: 'རྩིས་ཁྲ་སུབ་མ་ཐུབ།',
        );
      default:
        return result.message;
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            context.strings.localized(
              telugu: 'అకౌంట్ డిలీట్ నిర్ధారణ',
              english: 'Confirm account deletion',
              hindi: 'खाता हटाने की पुष्टि करें',
              tamil: 'கணக்கு நீக்குதலை உறுதிப்படுத்தவும்',
              kannada: 'ಖಾತೆ ಅಳಿಸುವಿಕೆಯನ್ನು ದೃಢೀಕರಿಸಿ',
              malayalam: 'അക്കൗണ്ട് ഇല്ലാതാക്കൽ സ്ഥിരീകരിക്കുക',
              marathi: 'खाते हटवण्याची पुष्टी करा',
              gujarati: 'એકાઉન્ટ કાઢી નાખવાની પુષ્ટિ કરો',
              bengali: 'অ্যাকাউন্ট মুছে ফেলা নিশ্চিত করুন',
              punjabi: 'ਖਾਤਾ ਮਿਟਾਉਣ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ',
              odia: 'ଖାତା ବିଲୋପ ନିଶ୍ଚିତ କରନ୍ତୁ',
              assamese: 'একাউণ্ট মচি পেলোৱাটো নিশ্চিত কৰক',
              konkani: 'खातें काडपाची खात्री करात',
              nepali: 'खाता हटाउने पुष्टि गर्नुहोस्',
              meitei: 'Account muthatpa confirm toubiyu',
              mizo: 'Account thaibo chian rawh',
              kashmiri: 'اکاوُنٛٹ ڈلیٖٹ کرُن کٔریو تصدیق',
              ladakhi: 'རྩིས་ཁྲ་སུབ་རྒྱུ་གཏན་འཁེལ་བྱོས།',
            ),
          ),
          content: Text(
            context.strings.localized(
              telugu:
                  'మీ లాగిన్, పోస్టర్ ప్రొఫైల్, సబ్‌స్క్రిప్షన్‌కు సంబంధించిన యాక్సెస్ రికార్డులు తొలగించబడతాయి. దీన్ని తిరిగి తీసుకురాలేము.',
              english:
                  'Your login, poster profile, and subscription-related access records will be removed. This cannot be undone.',
              hindi:
                  'आपका लॉगिन, पोस्टर प्रोफ़ाइल और सदस्यता रिकॉर्ड हटा दिए जाएंगे। इसे पूर्ववत नहीं किया जा सकता।',
              tamil:
                  'உங்கள் உள்நுழைவு, போஸ்டர் சுயவிவரம் மற்றும் சந்தா பதிவுகள் அகற்றப்படும். இதை மீட்டெடுக்க முடியாது.',
              kannada:
                  'ನಿಮ್ಮ ಲಾಗಿನ್, ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್ ಮತ್ತು ಚಂದಾದಾರಿಕೆ ದಾಖಲೆಗಳನ್ನು ತೆಗೆದುಹಾಕಲಾಗುತ್ತದೆ. ಇದನ್ನು ರದ್ದುಗೊಳಿಸಲಾಗುವುದಿಲ್ಲ.',
              malayalam:
                  'നിങ്ങളുടെ ലോഗിൻ, പോസ്റ്റർ പ്രൊഫൈൽ, സബ്‌സ്‌ക്രിപ്ഷൻ രേഖകൾ നീക്കംചെയ്യും. ഇത് മാറ്റാനാകില്ല.',
              marathi:
                  'तुमचे लॉगिन, पोस्टर प्रोफाईल आणि सदस्यता नोंदी काढल्या जातील. हे पूर्ववत केले जाऊ शकत नाही.',
              gujarati:
                  'તમારું લૉગિન, પોસ્ટર પ્રોફાઇલ અને સબ્સ્ક્રિપ્શન રેકોર્ડ્સ દૂર કરવામાં આવશે. આ પૂર્વવત્ કરી શકાતું નથી.',
              bengali:
                  'আপনার লগইন, পোস্টার প্রোফাইল এবং সাবস্ক্রিপশন রেকর্ড মুছে ফেলা হবে। এটি ফিরিয়ে আনা যাবে না।',
              punjabi:
                  'ਤੁਹਾਡਾ ਲੌਗਇਨ, ਪੋਸਟਰ ਪ੍ਰੋਫਾਈਲ ਅਤੇ ਗਾਹਕੀ ਰਿਕਾਰਡ ਹਟਾ ਦਿੱਤੇ ਜਾਣਗੇ। ਇਸਨੂੰ ਵਾਪਸ ਨਹੀਂ ਲਿਆ ਜਾ ਸਕਦਾ।',
              odia:
                  'ଆପଣଙ୍କ ଲଗଇନ୍, ପୋଷ୍ଟର ପ୍ରୋଫାଇଲ୍ ଏବଂ ସବସ୍କ୍ରିପସନ୍ ରେକର୍ଡଗୁଡ଼ିକ ହଟାଯିବ। ଏହା ପୁନରୁଦ୍ଧାର ହୋଇପାରିବ ନାହିଁ।',
              assamese:
                  'আপোনাৰ লগইন, পোষ্টাৰ প্ৰ’ফাইল আৰু চাবস্ক্ৰিপশ্বন ৰেকৰ্ড আঁতৰোৱা হ’ব। ইয়াক পুনৰুদ্ধাৰ কৰিব নোৱাৰি।',
              konkani:
                  'तुमचें लॉगिन, पोस्टर प्रोफाईल आनी वर्गणी नोंदी काडून उडयतले. हें परत मेळोवंक येना.',
              nepali:
                  'तपाईंको लगइन, पोस्टर प्रोफाइल, र सदस्यता रेकर्डहरू हटाइनेछ। यसलाई पूर्ववत गर्न सकिँदैन।',
              meitei:
                  'Nangi login, poster profile amasung subscription record sing muthatkani. Asi amuk hanna phangba ngamlaroi.',
              mizo:
                  'I login, poster profile, leh subscription record-te paih a ni ang. Siam that leh theih a ni tawh lo ang.',
              kashmiri:
                  'تہنٛد لاگ اِن، پوسٹر پروفائل تہٕ سبسکرپشن ریکارڈ یِن ہٹاونہٕ۔ یہِ ہیکہِ نہٕ واپس انِتھ۔',
              ladakhi:
                  'ཁྱེད་ཀྱི་ login དང་ poster profile, subscription ཡིག་ཆ་རྣམས་སུབ་རྒྱུ་ཡིན། འདི་ཕྱིར་ལོག་མི་ཐུབ།',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                context.strings.localized(
                  telugu: 'రద్దు',
                  english: 'Cancel',
                  hindi: 'रद्द करें',
                  tamil: 'ரத்து',
                  kannada: 'ರದ್ದು',
                  malayalam: 'റദ്ദാക്കുക',
                  marathi: 'रद्द करा',
                  gujarati: 'રદ કરો',
                  bengali: 'বাতিল',
                  punjabi: 'ਰੱਦ ਕਰੋ',
                  odia: 'ବାତିଲ୍',
                  assamese: 'বাতিল',
                  konkani: 'रद्द',
                  nepali: 'रद्द गर्नुहोस्',
                  meitei: 'Cancel',
                  mizo: 'Sut rawh',
                  kashmiri: 'منسوخ',
                  ladakhi: 'ཕྱིར་འཐེན།',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.strings.localized(
                  telugu: 'అకౌంట్ డిలీట్ చేయి',
                  english: 'Delete account',
                  hindi: 'खाता हटाएं',
                  tamil: 'கணக்கை நீக்கு',
                  kannada: 'ಖಾತೆ ಅಳಿಸಿ',
                  malayalam: 'അക്കൗണ്ട് ഇല്ലാതാക്കുക',
                  marathi: 'खाते हटवा',
                  gujarati: 'એકાઉન્ટ કાઢી નાખો',
                  bengali: 'অ্যাকাউন্ট মুছুন',
                  punjabi: 'ਖਾਤਾ ਮਿਟਾਓ',
                  odia: 'ଖାତା ବିଲୋପ କରନ୍ତୁ',
                  assamese: 'একাউণ্ট মচক',
                  konkani: 'खातें काडून उडयात',
                  nepali: 'खाता मेटाउनुहोस्',
                  meitei: 'Account muthat-u',
                  mizo: 'Account thaibo rawh',
                  kashmiri: 'اکاوُنٛٹ کٔریو ڈلیٖٹ',
                  ladakhi: 'རྩིས་ཁྲ་སུབ་པ།',
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await _accountDeletionService.deleteCurrentAccount();
      if (!mounted) {
        return;
      }
      _showSnackBar(_localizedResultMessage(result));
      if (!result.success) {
        return;
      }
      await _authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          strings.localized(
            telugu: 'అకౌంట్ డిలీషన్',
            english: 'Account deletion',
            hindi: 'खाता हटाना',
            tamil: 'கணக்கு நீக்கம்',
            kannada: 'ಖಾತೆ ಅಳಿಸುವಿಕೆ',
            malayalam: 'അക്കൗണ്ട് ഇല്ലാതാക്കൽ',
            marathi: 'खाते हटवणे',
            gujarati: 'એકાઉન્ટ કાઢી નાખવું',
            bengali: 'অ্যাকাউন্ট মুছে ফেলা',
            punjabi: 'ਖਾਤਾ ਮਿਟਾਉਣਾ',
            odia: 'ଖାତା ବିଲୋପ',
            assamese: 'একাউণ্ট মচি পেলোৱা',
            konkani: 'खातें काडप',
            nepali: 'खाता हटाउने कार्य',
            meitei: 'Account muthatpa',
            mizo: 'Account thaibo',
            kashmiri: 'اکاوُنٛٹ ڈلیٖٹ کرُن',
            ladakhi: 'རྩིས་ཁྲ་སུབ་པ།',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB45309),
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  strings.localized(
                    telugu: 'అకౌంట్ డిలీట్ రిక్వెస్ట్‌ను ఇక్కడే పంపవచ్చు',
                    english:
                        'You can submit your account deletion request here',
                    hindi:
                        'आप यहाँ अपना खाता हटाने का अनुरोध सबमिट कर सकते हैं',
                    tamil:
                        'உங்கள் கணக்கு நீக்குதல் கோரிக்கையை இங்கே சமர்ப்பிக்கலாம்',
                    kannada:
                        'ನಿಮ್ಮ ಖಾತೆ ಅಳಿಸುವಿಕೆಯ ವಿನಂತಿಯನ್ನು ನೀವು ಇಲ್ಲಿ ಸಲ್ಲಿಸಬಹುದು',
                    malayalam:
                        'നിങ്ങളുടെ അക്കൗണ്ട് ഇല്ലാതാക്കൽ അഭ്യർത്ഥന ഇവിടെ സമർപ്പിക്കാം',
                    marathi:
                        'तुम्ही तुमची खाते हटवण्याची विनंती येथे सबमिट करू शकता',
                    gujarati:
                        'તમે તમારી એકાઉન્ટ કાઢી નાખવાની વિનંતી અહીં સબમિટ કરી શકો છો',
                    bengali:
                        'আপনি এখানে আপনার অ্যাকাউন্ট মুছে ফেলার অনুরোধ জমা দিতে পারেন',
                    punjabi:
                        'ਤੁਸੀਂ ਇੱਥੇ ਆਪਣੀ ਖਾਤਾ ਮਿਟਾਉਣ ਦੀ ਬੇਨਤੀ ਦਰਜ ਕਰ ਸਕਦੇ ਹੋ',
                    odia:
                        'ଆପଣ ଏଠାରେ ଆପଣଙ୍କ ଖାତା ବିଲୋପ ଅନୁରୋଧ ଦାଖଲ କରିପାରିବେ',
                    assamese:
                        'আপুনি ইয়াত আপোনাৰ একাউণ্ট মচি পেলোৱাৰ অনুৰোধ জমা দিব পাৰে',
                    konkani:
                        'तुमी तुमची खातें काडपाची विनंती हांगा सादर करूंक शकतात',
                    nepali:
                        'तपाईं यहाँ आफ्नो खाता हटाउने अनुरोध पेश गर्न सक्नुहुन्छ',
                    meitei:
                        'Nangi account muthatnaba haijaba masi phamda submit touba yai',
                    mizo:
                        'Heta tang hian i account thaibo dilna i thehlut thei',
                    kashmiri:
                        'تۄہہِ ہیکیو ییٚتھ پنُن اکاوُنٛٹ ڈلیٖٹ کرُنُک دَرخواست دِتھ',
                    ladakhi:
                        'ཁྱེད་ཀྱིས་འདི་ནས་རྩིས་ཁྲ་སུབ་པའི་རེ་འདུན་སྤྲོད་ཆོག',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.localized(
                    telugu:
                        'డిలీట్ రిక్వెస్ట్‌ను నిర్ధారించిన తర్వాత మీ సైన్-ఇన్ యాక్సెస్, ప్రొఫైల్ ఫోటో, పోస్టర్ ఐడెంటిటీ వివరాలు మరియు యాప్‌కు సంబంధించిన వ్యక్తిగత డేటా తొలగించే ప్రక్రియ ప్రారంభమవుతుంది. Play Store లేదా Apple బిల్లింగ్ రికార్డులు చట్టపరమైన లేదా అకౌంటింగ్ అవసరాల కోసం విడిగా నిల్వ ఉండవచ్చు.',
                    english:
                        'After you confirm deletion, the app starts removing your sign-in access, profile photo, poster identity details, and app-linked personal data. Play Store or Apple billing records may remain separately for legal or accounting purposes.',
                    hindi:
                        'हटाने की पुष्टि करने के बाद, ऐप आपके साइन-इन एक्सेस, प्रोफ़ाइल फ़ोटो, पोस्टर पहचान विवरण और ऐप से जुड़े व्यक्तिगत डेटा को हटाना शुरू कर देता है। Play Store या Apple बिलिंग रिकॉर्ड कानूनी या लेखा उद्देश्यों के लिए अलग से संग्रहीत रह सकते हैं।',
                    tamil:
                        'நீக்குதலை உறுதிசெய்த பிறகு, உங்கள் உள்நுழைவு அணுகல், சுயவிவரப் படம், போஸ்டர் அடையாள விவரங்கள் மற்றும் செயலி சார்ந்த தனிப்பட்ட தரவை நீக்கும் பணி தொடங்கும். Play Store அல்லது Apple பில்லிங் பதிவுகள் சட்ட அல்லது கணக்குத் தேவைகளுக்காகத் தனியாக வைக்கப்படலாம்.',
                    kannada:
                        'ಅಳಿಸುವಿಕೆಯನ್ನು ದೃಢಪಡಿಸಿದ ನಂತರ, ನಿಮ್ಮ ಸೈನ್-ಇನ್ ಪ್ರವೇಶ, ಪ್ರೊಫೈಲ್ ಫೋಟೋ, ಪೋಸ್ಟರ್ ಗುರುತಿನ ವಿವರಗಳು ಮತ್ತು ಆಪ್-ಸಂಬಂಧಿತ ವೈಯಕ್ತಿಕ ಡೇಟಾವನ್ನು ತೆಗೆದುಹಾಕುವ ಪ್ರಕ್ರಿಯೆ ಪ್ರಾರಂಭವಾಗುತ್ತದೆ. Play Store ಅಥವಾ Apple ಬಿಲ್ಲಿಂಗ್ ದಾಖಲೆಗಳು ಕಾನೂನು ಅಥವಾ ಲೆಕ್ಕಪತ್ರ ಉದ್ದೇಶಗಳಿಗಾಗಿ ಪ್ರತ್ಯೇಕವಾಗಿ ಉಳಿಯಬಹುದು.',
                    malayalam:
                        'ഇല്ലാതാക്കൽ സ്ഥിരീകരിച്ച ശേഷം, നിങ്ങളുടെ സൈൻ-ഇൻ ആക്‌സസ്, പ്രൊഫൈൽ ഫോട്ടോ, പോസ്റ്റർ ഐഡന്റിറ്റി വിശദാംശങ്ങൾ, വ്യക്തിഗത ഡാറ്റ എന്നിവ നീക്കംചെയ്യാൻ തുടങ്ങും. Play Store അല്ലെങ്കിൽ Apple ബില്ലിംഗ് റെക്കോർഡുകൾ നിയമപരമോ അക്കൗണ്ടിംഗോ ആവശ്യങ്ങൾക്കായി പ്രത്യേകം സൂക്ഷിച്ചേക്കാം.',
                    marathi:
                        'हटवण्याची पुष्टी केल्यानंतर, अ‍ॅप तुमचा साइन-इन अ‍ॅक्सेस, प्रोफाईल फोटो, पोस्टर ओळख तपशील आणि अ‍ॅप-संबंधित वैयक्तिक डेटा काढून टाकण्यास सुरुवात करते. Play Store किंवा Apple बिलिंग नोंदी कायदेशीर किंवा लेखा हेतूंसाठी स्वतंत्रपणे राहू शकतात.',
                    gujarati:
                        'કાઢી નાખવાની પુષ્ટિ કર્યા પછી, એપ્લિકેશન તમારા સાઇન-ઇન ઍક્સેસ, પ્રોફાઇલ ફોટો, પોસ્ટર ઓળખ વિગતો અને એપ્લિકેશન-સંબંધિત વ્યક્તિગત ડેટાને દૂર કરવાનું શરૂ કરે છે. Play Store અથવા Apple બિલિંગ રેકોર્ડ્સ કાનૂની અથવા એકાઉન્ટિંગ હેતુઓ માટે અલગથી રહી શકે છે.',
                    bengali:
                        'মুছে ফেলা নিশ্চিত করার পরে, অ্যাপটি আপনার সাইন-ইন অ্যাক্সেস, প্রোফাইল ছবি, পোস্টার পরিচয়ের বিবরণ এবং ব্যক্তিগত ডেটা অপসারণ শুরু করে। Play Store বা Apple বিলিং রেকর্ড আইনি বা অ্যাকাউন্টিং উদ্দেশ্যে আলাদাভাবে থাকতে পারে।',
                    punjabi:
                        'ਮਿਟਾਉਣ ਦੀ ਪੁਸ਼ਟੀ ਕਰਨ ਤੋਂ ਬਾਅਦ, ਐਪ ਤੁਹਾਡੀ ਸਾਈਨ-ਇਨ ਪਹੁੰਚ, ਪ੍ਰੋਫਾਈਲ ਫੋਟੋ, ਪੋਸਟਰ ਪਛਾਣ ਵੇਰਵੇ ਅਤੇ ਐਪ ਨਾਲ ਲਿੰਕ ਕੀਤੇ ਨਿੱਜੀ ਡੇਟਾ ਨੂੰ ਹਟਾਉਣਾ ਸ਼ੁਰੂ ਕਰਦੀ ਹੈ। Play Store ਜਾਂ Apple ਬਿਲਿੰਗ ਰਿਕਾਰਡ ਕਾਨੂੰਨੀ ਜਾਂ ਲੇਖਾਕਾਰੀ ਉਦੇਸ਼ਾਂ ਲਈ ਵੱਖਰੇ ਤੌਰ ਤੇ ਰਹਿ ਸਕਦੇ ਹਨ।',
                    odia:
                        'ବିଲୋପ ନିଶ୍ଚିତ କରିବା ପରେ, ଆପ୍ ଆପଣଙ୍କ ସାଇନ୍-ଇନ୍ ପ୍ରବେଶ, ପ୍ରୋଫାଇଲ୍ ଫଟୋ, ପୋଷ୍ଟର ପରିଚୟ ବିବରଣୀ ଏବଂ ଆପ୍-ସଂଲଗ୍ନ ବ୍ୟକ୍ତିଗତ ତଥ୍ୟ ହଟାଇବା ଆରମ୍ଭ କରେ। Play Store କିମ୍ବା Apple ବିଲିଂ ରେକର୍ଡଗୁଡ଼ିକ ଆଇନଗତ କିମ୍ବା ଆକାଉଣ୍ଟିଂ ଉଦ୍ଦେଶ୍ୟରେ ପୃଥକ ଭାବେ ରହିପାରେ।',
                    assamese:
                        'মচি পেলোৱাটো নিশ্চিত কৰাৰ পিছত, এপে আপোনাৰ ছাইন-ইন প্ৰৱেশাধিকাৰ, প্ৰ’ফাইল ফটো, পোষ্টাৰ পৰিচয়ৰ বিৱৰণ আৰু এপ-সংলগ্ন ব্যক্তিগত তথ্য আঁতৰোৱা আৰম্ভ কৰে। Play Store বা Apple বিলিং ৰেকৰ্ডসমূহ আইনী বা একাউণ্টিং উদ্দেশ্যে পৃথকভাৱে থাকিব পাৰে।',
                    konkani:
                        'काडपाची खात्री करतच, अ‍ॅप तुमचो साइन-इन प्रवेश, प्रोफाईल फोटो, पोस्टर वळख तपशील आनी अ‍ॅप-जोडिल्लो खाजगी डेटा काडपाक सुरू करता. Play Store वा Apple बिलिंग नोंदी कायदेशीर वा हिशोबी कारणां खातीर वेगळ्यो उरूंक शकतात.',
                    nepali:
                        'हटाउने पुष्टि गरेपछि, एपले तपाईंको साइन-इन पहुँच, प्रोफाइल फोटो, पोस्टर पहिचान विवरण र व्यक्तिगत डेटा हटाउन सुरु गर्छ। Play Store वा Apple बिलिङ रेकर्डहरू कानुनी वा लेखा उद्देश्यका लागि छुट्टै रहन सक्छन्।',
                    meitei:
                        'Muthatpa confirm touba matungda, app na nangi sign-in access, profile photo, poster identity amasung personal data muthatpa hougani. Play Store natraga Apple billing record di ain natraga accounting gi loinana thamba yai.',
                    mizo:
                        'Thaibo i chian hnuah, app hian i sign-in access, profile photo, poster identity details, leh app data a paih tan ang. Play Store emaw Apple billing record-te chu dan emaw accounting atan hrangin a awm thei.',
                    kashmiri:
                        'ڈلیٖٹ کرُن تصدیق کرنہٕ پتہٕ چھُ ایپ تہنٛد سائن اِن ایکسس، پروفائل فوٹو، پوسٹر شناخت تہٕ ذاتی ڈیٹا ہٹاون شۆروٗع کران۔ Play Store یا Apple بلنگ ریکارڈ ہیکن قانونی یا اکاؤنٹنگ مقاصدن باپتھ الگ روزِتھ۔',
                    ladakhi:
                        'སུབ་རྒྱུ་གཏན་འཁེལ་བྱས་རྗེས། app ཡིས་ཁྱེད་ཀྱི་ sign-in access དང་ profile photo, poster ངོ་རྟགས་ཞིབ་ཕྲ། སྒེར་གྱི་གཞི་གྲངས་རྣམས་སུབ་འགོ་འཛུགས། Play Store ཡང་ན་ Apple billing ཡིག་ཆ་ཁྲིམས་མཐུན་ཆེད་དུ་ལོགས་སུ་ལུས་སྲིད།',
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DeletionTile(
            title: strings.localized(
              telugu: 'డిలీషన్ పాలసీ చదవండి',
              english: 'Read deletion policy',
              hindi: 'हटाने की नीति पढ़ें',
              tamil: 'நீக்குதல் கொள்கையைப் படிக்கவும்',
              kannada: 'ಅಳಿಸುವಿಕೆ ನೀತಿಯನ್ನು ಓದಿ',
              malayalam: 'ഇല്ലാതാക്കൽ നയം വായിക്കുക',
              marathi: 'हटवण्याचे धोरण वाचा',
              gujarati: 'કાઢી નાખવાની નીતિ વાંચો',
              bengali: 'মুছে ফেলার নীতি পড়ুন',
              punjabi: 'ਮਿਟਾਉਣ ਦੀ ਨੀਤੀ ਪੜ੍ਹੋ',
              odia: 'ବିଲୋପ ନୀତି ପଢ଼ନ୍ତୁ',
              assamese: 'মচি পেলোৱাৰ নীতি পঢ়ক',
              konkani: 'काडपाचें धोरण वाचात',
              nepali: 'हटाउने नीति पढ्नुहोस्',
              meitei: 'Deletion policy pabiyu',
              mizo: 'Paih dan hriattirna chhiar rawh',
              kashmiri: 'ڈلیٖٹ پالیسی پَرِو',
              ladakhi: 'སུབ་པའི་སྲིད་ཇུས་ཀློགས།',
            ),
            subtitle: AppPublicInfo.accountDeletionUrl,
            icon: Icons.open_in_new_rounded,
            onTap: _openDeletionPolicy,
          ),
          const SizedBox(height: 12),
          _DeletionTile(
            title: strings.localized(
              telugu: 'సపోర్ట్ సహాయం కావాలా?',
              english: 'Need help from support?',
              hindi: 'सहायता से मदद चाहिए?',
              tamil: 'ஆதரவிடமிருந்து உதவி தேவையா?',
              kannada: 'ಬೆಂಬಲದಿಂದ ಸಹಾಯ ಬೇಕೇ?',
              malayalam: 'പിന്തുണയിൽ നിന്ന് സഹായം വേണോ?',
              marathi: 'सपोर्टकडून मदत हवी आहे?',
              gujarati: 'સપોર્ટ તરફથી મદદ જોઈએ છે?',
              bengali: 'সহায়তা থেকে সাহায্য প্রয়োজন?',
              punjabi: 'ਸਹਾਇਤਾ ਤੋਂ ਮਦਦ ਚਾਹੀਦੀ ਹੈ?',
              odia: 'ସହାୟତା ଠାରୁ ସାହାଯ୍ୟ ଆବଶ୍ୟକ କି?',
              assamese: 'সহায়তাৰ পৰা সহায় লাগিবনে?',
              konkani: 'आधाराची मदत जाय?',
              nepali: 'सहायताबाट मद्दत चाहिन्छ?',
              meitei: 'Support tagi mateng darkar oibra?',
              mizo: 'Support atangin puihna i mamawh em?',
              kashmiri: 'سپورٹ پؠٹھہٕ مدد چھی ضرورتہٕ؟',
              ladakhi: 'Support ནས་རོགས་རམ་དགོས་སམ།',
            ),
            subtitle: AppPublicInfo.supportEmail,
            icon: Icons.mail_outline_rounded,
            onTap: _emailSupport,
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _deleteAccount,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    strings.localized(
                      telugu: 'అకౌంట్ డిలీషన్ కొనసాగించండి',
                      english: 'Delete my account',
                      hindi: 'मेरा खाता हटाएं',
                      tamil: 'என் கணக்கை நீக்கு',
                      kannada: 'ನನ್ನ ಖಾತೆಯನ್ನು ಅಳಿಸಿ',
                      malayalam: 'എന്റെ അക്കൗണ്ട് ഇല്ലാതാക്കുക',
                      marathi: 'माझे खाते हटवा',
                      gujarati: 'મારું એકાઉન્ટ કાઢી નાખો',
                      bengali: 'আমার অ্যাকাউন্ট মুছুন',
                      punjabi: 'ਮੇਰਾ ਖਾਤਾ ਮਿਟਾਓ',
                      odia: 'ମୋ ଖାତା ବିଲୋପ କରନ୍ତୁ',
                      assamese: 'মোৰ একাউণ্ট মচক',
                      konkani: 'म्हजें खातें काडून उडयात',
                      nepali: 'मेरो खाता मेटाउनुहोस्',
                      meitei: 'Eigi account muthatlu',
                      mizo: 'Ka account thaibo rawh',
                      kashmiri: 'میون اکاوُنٛٹ کٔریو ڈلیٖٹ',
                      ladakhi: 'ངའི་རྩིས་ཁྲ་སུབས།',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeletionTile extends StatelessWidget {
  const _DeletionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF334155)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
