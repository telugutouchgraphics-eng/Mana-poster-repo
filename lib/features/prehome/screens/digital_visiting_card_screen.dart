import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/widgets/digital_visiting_card_widget.dart';

class DigitalVisitingCardScreen extends StatefulWidget {
  const DigitalVisitingCardScreen({
    super.key,
    this.initialProfile,
    this.fromOnboarding = false,
  });

  final PosterProfileData? initialProfile;
  final bool fromOnboarding;

  @override
  State<DigitalVisitingCardScreen> createState() => _DigitalVisitingCardScreenState();
}

class _DigitalVisitingCardScreenState extends State<DigitalVisitingCardScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  late PosterProfileData _profile;
  VisitingCardStyle _selectedStyle = VisitingCardStyle.royalBlue;
  bool _saving = false;
  bool _sharing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile!;
      _loading = false;
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final loaded = await PosterProfileService.load();
    if (mounted) {
      setState(() {
        _profile = loaded;
        _loading = false;
      });
    }
  }

  Future<String?> _captureCardToTempFile() async {
    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }
      final image = await boundary.toImage(pixelRatio: 3.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/mana_visiting_card_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Card capture error: $e');
      }
      return null;
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    if (Platform.isAndroid &&
        !(await MediaExportService.needsGalleryPermission())) {
      return true;
    }
    final permission =
        Platform.isAndroid ? Permission.storage : Permission.photos;
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    final requested = await <Permission>[permission].request();
    return requested.values.any((s) => s.isGranted || s.isLimited);
  }

  Future<void> _saveToGallery() async {
    if (_saving || _sharing) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        if (mounted) {
          messenger.showTopSnackBar(
            AppSnackBar.build(
              content: Text(
                context.strings.localized(
                  telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
                  english: 'Gallery permission was denied.',
                  hindi: 'गैलरी की अनुमति अस्वीकार कर दी गई।',
                  tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
                  kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ.',
                  malayalam: 'ഗ്യാലറി അനുമതി നിരസിച്ചു.',
                  marathi: 'गॅलरी परवानगी नाकारली गेली.',
                  gujarati: 'ગૅલેરી પરવાનગી નકારી દેવામાં આવી.',
                  bengali: 'গ্যালারির অনুমতি প্রত্যাখ্যান করা হয়েছে।',
                  punjabi: 'ਗੈਲਰੀ ਦੀ ਇਜਾਜ਼ਤ ਅਸਵੀਕਾਰ ਕਰ ਦਿੱਤੀ ਗਈ।',
                  odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଗଲା।',
                  assamese: 'গেলেৰীৰ অনুমতি নাকচ কৰা হ’ল।',
                  konkani: 'गॅलरीची परवानगी नाकारली.',
                  nepali: 'ग्यालरी अनुमति अस्वीकृत गरियो।',
                  meitei: 'গেলরিগী অয়াবা য়াদে।',
                  mizo: 'Gallery phalna hnar a ni.',
                  kashmiri: 'گیلری ہٕنٛز اِجازت آیہِ مسترد کَرنہٕ।',
                  ladakhi: 'པར་མཛོད་ཆོག་མཆན་ཕྱིར་འཐེན་བྱས།',
                ),
              ),
            ),
          );
        }
        return;
      }

      final path = await _captureCardToTempFile();
      if (path == null) {
        if (mounted) {
          messenger.showTopSnackBar(
            AppSnackBar.build(
              content: Text(
                context.strings.localized(
                  telugu: 'కార్డ్ సేవ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
                  english: 'Card save failed. Please try again.',
                  hindi: 'कार्ड सहेजना विफल रहा। कृपया पुनः प्रयास करें।',
                  tamil: 'கார்டைச் சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
                  kannada: 'ಕಾರ್ಡ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                  malayalam: 'കാർഡ് സേവ് ചെയ്യുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
                  marathi: 'कार्ड सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
                  gujarati: 'કાર્ડ સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
                  bengali: 'কার্ড সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
                  punjabi: 'ਕਾਰਡ ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                  odia: 'କାର୍ଡ ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
                  assamese: 'কাৰ্ড সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
                  konkani: 'कार्ड सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
                  nepali: 'कार्ड बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
                  meitei: 'কার্দ সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
                  mizo: 'Card save a hlawhchham. Khawngaihin ti nawn leh rawh.',
                  kashmiri: 'کارڈ محفوٗظ کرنس منٛز ناکام۔ مہر کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
                  ladakhi: 'Card save ma thub. Yang try byed.',
                ),
              ),
            ),
          );
        }
        return;
      }

      final fileName =
          'mana_visiting_card_${DateTime.now().millisecondsSinceEpoch}.png';
      final result = await MediaExportService.saveImageFileToGalleryDetailed(
        path,
        fileName: fileName,
      );

      if (mounted) {
        messenger.showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              result.success
                  ? context.strings.localized(
                      telugu: 'విజిటింగ్ కార్డ్ గ్యాలరీలో సేవ్ చేయబడింది!',
                      english: 'Visiting card saved to gallery!',
                      hindi: 'विजिटिंग कार्ड गैलरी में सहेजा गया!',
                      tamil: 'விசிட்டிங் கார்டு கேலரியில் சேமிக்கப்பட்டது!',
                      kannada: 'ವಿಸಿಟಿಂಗ್ ಕಾರ್ಡ್ ಗ್ಯಾಲರಿಯಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ!',
                      malayalam: 'വിസിറ്റിംഗ് കാർഡ് ഗ്യാലറിയിൽ സൂക്ഷിച്ചു!',
                      marathi: 'व्हिजिटिंग कार्ड गॅलरीमध्ये जतन केले!',
                      gujarati: 'વિઝિટિંગ કાર્ડ ગૅલેરીમાં સાચવવામાં આવ્યું!',
                      bengali: 'ভিজিটিং কার্ডটি গ্যালারিতে সংরক্ষিত হয়েছে!',
                      punjabi: 'ਵਿਜ਼ਿਟਿੰਗ ਕਾਰਡ ਗੈਲਰੀ ਵਿੱਚ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਗਿਆ!',
                      odia: 'ଭିଜିଟିଂ କାର୍ଡ ଗ୍ୟାଲେରୀରେ ସେଭ୍ ହୋଇଛି!',
                      assamese: 'ভিজিটিং কাৰ্ড গেলেৰীত সংৰক্ষণ কৰা হ’ল!',
                      konkani: 'विझिटींग कार्ड गॅलरींत सांबाळ्ळें!',
                      nepali: 'भिजिटिङ कार्ड ग्यालरीमा सुरक्षित गरियो!',
                      meitei: 'বিজিতিং কার্দ অসি গেলরিদা সেভ তৌখ্রে!',
                      mizo: 'Visiting card gallery-ah dahthat a ni ta!',
                      kashmiri: 'وزٹنگ کارڈ آو گیلری منٛز محفوٗظ کَرنہٕ!',
                      ladakhi: 'Visiting card par mdzod nang save song!',
                    )
                  : context.strings.localized(
                      telugu: 'సేవ్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
                      english: 'Save failed. Please try again.',
                      hindi: 'सहेजना विफल रहा। कृपया पुनः प्रयास करें।',
                      tamil: 'சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
                      kannada: 'ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                      malayalam: 'സേവ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
                      marathi: 'सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
                      gujarati: 'સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
                      bengali: 'সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
                      punjabi: 'ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                      odia: 'ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
                      assamese: 'সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
                      konkani: 'सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
                      nepali: 'बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
                      meitei: 'সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
                      mizo: 'Save a hlawhchham. Khawngaihin ti nawn leh rawh.',
                      kashmiri: 'محفوٗظ کرنس منٛز ناکام۔ مہر کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
                      ladakhi: 'Save ma thub. Yang try byed.',
                    ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _shareToWhatsApp() async {
    if (_sharing || _saving) return;
    setState(() => _sharing = true);

    try {
      final path = await _captureCardToTempFile();
      if (path == null) {
        return;
      }
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final shareText = context.strings.localized(
          telugu: 'నా డిజిటల్ విజిటింగ్ కార్డ్ - మన పోస్టర్ యాప్ ద్వారా రూపొందించబడింది.',
          english: 'My Digital Visiting Card - Created with Mana Poster App.',
          hindi: 'मेरा डिजिटल विजिटिंग कार्ड - मना पोस्टर ऐप द्वारा निर्मित।',
          tamil: 'எனது டிஜிட்டல் விசிட்டிங் கார்டு - மனா போஸ்டர் ஆப் மூலம் உருவாக்கப்பட்டது.',
          kannada: 'ನನ್ನ ಡಿಜಿಟಲ್ ವಿಸಿಟಿಂಗ್ ಕಾರ್ಡ್ - ಮನ ಪೋಸ್ಟರ್ ಆಪ್ ಮೂಲಕ ರಚಿಸಲಾಗಿದೆ.',
          malayalam: 'എന്റെ ഡിജിറ്റൽ വിസിറ്റിംഗ് കാർഡ് - മനാ പോസ്റ്റർ ആപ്പ് വഴി നിർമ്മിച്ചത്.',
          marathi: 'माझे डिजिटल व्हिजिटिंग कार्ड - मना पोस्टर ॲपद्वारे तयार केले.',
          gujarati: 'મારું ડિજિટલ વિઝિટિંગ કાર્ડ - મના પોસ્ટર એપ દ્વારા બનાવેલ.',
          bengali: 'আমার ডিজিটাল ভিজিটিং কার্ড - মানা পোস্টার অ্যাপ দ্বারা তৈরি।',
          punjabi: 'ਮੇਰਾ ਡਿਜੀਟਲ ਵਿਜ਼ਿਟਿੰਗ ਕਾਰਡ - ਮਨਾ ਪੋਸਟਰ ਐਪ ਦੁਆਰਾ ਬਣਾਇਆ ਗਿਆ।',
          odia: 'ମୋର ଡିଜିଟାଲ୍ ଭିଜିଟିଂ କାର୍ଡ - ମନା ପୋଷ୍ଟର ଆପ୍ ଦ୍ୱାରା ନିର୍ମିତ।',
          assamese: 'মোৰ ডিজিটেল ভিজিটিং কাৰ্ড - মানা পোষ্টাৰ এপেৰে নিৰ্মিত।',
          konkani: 'म्हजें डिजीटल विझिटींग कार्ड - मना पोस्टर ॲपा वरवीं तयार केल्लें.',
          nepali: 'मेरो डिजिटल भिजिटिङ कार्ड - मना पोस्टर एपद्वारा सिर्जना गरिएको।',
          meitei: 'ইহাক্কী দিজিতেল বিজিতিং কার্দ - মনা পোস্তর এপ্তা শেম্বা।',
          mizo: 'Ka Digital Visiting Card - Mana Poster App atanga siam.',
          kashmiri: 'میٛون ڈِجیٹَل وزٹنگ کارڈ - مَنا پوسٹر اَیپہٕ ذٔریعہٕ بنٲومُت۔',
          ladakhi: 'Nye Digital Visiting Card - Mana Poster App nangi bzos pa.',
        );
      await MediaExportService.shareImageFile(
        path,
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  Future<void> _continueToHome() async {
    if (widget.fromOnboarding) {
      final nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(nextRoute);
      }
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        AppNavigator.openHome();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // Header Bar
            Container(
              padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _continueToHome,
                    icon: Icon(
                      widget.fromOnboarding
                          ? Icons.close_rounded
                          : Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.strings.localized(
                            telugu: 'మీ డిజిటల్ విజిటింగ్ కార్డ్',
                            english: 'Your Digital Visiting Card',
                            hindi: 'आपका डिजिटल विजिटिंग कार्ड',
                            tamil: 'உங்கள் டிஜிட்டல் விசிட்டிங் கார்டு',
                            kannada: 'ನಿಮ್ಮ ಡಿಜಿಟಲ್ ವಿಸಿಟಿಂಗ್ ಕಾರ್ಡ್',
                            malayalam: 'നിങ്ങളുടെ ഡിജിറ്റൽ വിസിറ്റിംഗ് കാർഡ്',
                            marathi: 'तुमचे डिजिटल व्हिजिटिंग कार्ड',
                            gujarati: 'તમારું ડિજિટલ વિઝિટિંગ કાર્ડ',
                            bengali: 'আপনার ডিজিটাল ভিজিটিং কার্ড',
                            punjabi: 'ਤੁਹਾਡਾ ਡਿਜੀਟਲ ਵਿਜ਼ਿਟਿੰਗ ਕਾਰਡ',
                            odia: 'ଆପଣଙ୍କ ଡିଜିଟାଲ୍ ଭିଜିଟିଂ କାର୍ଡ',
                            assamese: 'আপোনাৰ ডিজিটেল ভিজিটিং কাৰ্ড',
                            konkani: 'तुमचें डिजीटल विझिटींग कार्ड',
                            nepali: 'तपाईंको डिजिटल भिजिटिङ कार्ड',
                            meitei: 'নহাক্কী দিজিতেল বিজিতিং কার্দ',
                            mizo: 'I Digital Visiting Card',
                            kashmiri: 'تہُند ڈِجیٹَل وزٹنگ کارڈ',
                            ladakhi: 'Nye Digital Visiting Card',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          context.strings.localized(
                            telugu: 'ప్రింటబుల్ సైజ్ (3.5" × 2.0")',
                            english: 'Printable Size (3.5" × 2.0")',
                            hindi: 'प्रिंट करने योग्य आकार (3.5" × 2.0")',
                            tamil: 'அச்சிடக்கூடிய அளவு (3.5" × 2.0")',
                            kannada: 'ಮುದ್ರಿಸಬಹುದಾದ ಗಾತ್ರ (3.5" × 2.0")',
                            malayalam: 'പ്രിന്റ് ചെയ്യാവുന്ന വലുപ്പം (3.5" × 2.0")',
                            marathi: 'मुद्रणयोग्य आकार (3.5" × 2.0")',
                            gujarati: 'પ્રિન્ટ કરી શકાય તેવું કદ (3.5" × 2.0")',
                            bengali: 'প্রিন্টযোগ্য আকার (3.5" × 2.0")',
                            punjabi: 'ਛਪਣਯੋਗ ਆਕਾਰ (3.5" × 2.0")',
                            odia: 'ମୁଦ୍ରଣଯୋଗ୍ୟ ଆକାର (3.5" × 2.0")',
                            assamese: 'প্ৰিণ্টযোগ্য আকাৰ (3.5" × 2.0")',
                            konkani: 'छापपा सारकें माप (3.5" × 2.0")',
                            nepali: 'मुद्रणयोग्य आकार (3.5" × 2.0")',
                            meitei: 'নমবা য়াবা অকক (3.5" × 2.0")',
                            mizo: 'Chhut theih chin (3.5" × 2.0")',
                            kashmiri: 'پرِنٛٹ کَرنہٕ لائق سائز (3.5" × 2.0")',
                            ladakhi: 'Par thub pa’i thad (3.5" × 2.0")',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.fromOnboarding)
                    TextButton(
                      onPressed: _continueToHome,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        context.strings.localized(
                          telugu: 'హోమ్ కి వెళ్లండి',
                          english: 'Go to Home',
                          hindi: 'होम पर जाएं',
                          tamil: 'முகப்புக்குச் செல்',
                          kannada: 'ಮುಖಪುಟಕ್ಕೆ ಹೋಗಿ',
                          malayalam: 'ഹോമിലേക്ക് പോകുക',
                          marathi: 'मुख्यपृष्ठावर जा',
                          gujarati: 'હોમ પર જાઓ',
                          bengali: 'হোমে যান',
                          punjabi: 'ਹੋਮ ਤੇ ਜਾਓ',
                          odia: 'ହୋମ୍ କୁ ଯାଆନ୍ତୁ',
                          assamese: 'হোমলৈ যাওক',
                          konkani: 'घरा वचात',
                          nepali: 'गृहपृष्ठमा जानुहोस्',
                          meitei: 'হোমদা চৎলু',
                          mizo: 'Home-ah kal rawh',
                          kashmiri: 'ہومس پیٚٹھ گژھِو',
                          ladakhi: 'Home la song',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Card Style Switcher Chips
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: <Widget>[
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'రాయల్ బ్లూ',
                              english: 'Royal Blue',
                              hindi: 'रॉयल ब्लू',
                              tamil: 'ராயல் நீலம்',
                              kannada: 'ರಾಯಲ್ ಬ್ಲೂ',
                              malayalam: 'റോയൽ ബ്ലൂ',
                              marathi: 'रॉयल ब्लू',
                              gujarati: 'રોયલ બ્લુ',
                              bengali: 'রয়্যাল ব্লু',
                              punjabi: 'ਰਾਇਲ ਬਲੂ',
                              odia: 'ରୟାଲ୍ ବ୍ଲୁ',
                              assamese: 'ৰয়েল ব্লু',
                              konkani: 'रॉयल ब्लू',
                              nepali: 'रोयल निलो',
                              meitei: 'রোয়ল ব্লু',
                              mizo: 'Royal Blue',
                              kashmiri: 'رائل بلیو',
                              ladakhi: 'Royal Blue',
                            ),
                            style: VisitingCardStyle.royalBlue,
                            activeColor: const Color(0xFF2563EB),
                          ),
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'రాయల్ గోల్డ్',
                              english: 'Royal Gold',
                              hindi: 'रॉयल गोल्ड',
                              tamil: 'ராயல் தங்கம்',
                              kannada: 'ರಾಯಲ್ ಗೋಲ್ಡ್',
                              malayalam: 'റോയൽ ഗോൾഡ്',
                              marathi: 'रॉयल गोल्ड',
                              gujarati: 'રોયલ ગોલ્ડ',
                              bengali: 'রয়্যাল গোল্ড',
                              punjabi: 'ਰਾਇਲ ਗੋਲਡ',
                              odia: 'ରୟାଲ୍ ଗୋଲ୍ଡ',
                              assamese: 'ৰয়েল গোল্ড',
                              konkani: 'रॉयल गोल्ड',
                              nepali: 'रोयल सुनौलो',
                              meitei: 'রোয়ল শনা',
                              mizo: 'Royal Gold',
                              kashmiri: 'رائل گولڈ',
                              ladakhi: 'Royal Gold',
                            ),
                            style: VisitingCardStyle.royalGold,
                            activeColor: const Color(0xFF800020),
                          ),
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'ఎమరాల్డ్',
                              english: 'Emerald',
                              hindi: 'एमराल्ड',
                              tamil: 'மரகதம்',
                              kannada: 'ಎಮರಾಲ್ಡ್',
                              malayalam: 'എമറാൾഡ്',
                              marathi: 'एमराल्ड',
                              gujarati: 'એમરાલ્ડ',
                              bengali: 'এমরাল্ড',
                              punjabi: 'ਐਮਰਾਲਡ',
                              odia: 'ଏମରାଲ୍ଡ',
                              assamese: 'এমৰাল্ড',
                              konkani: 'पाचवो',
                              nepali: 'पन्ना',
                              meitei: 'মরকত',
                              mizo: 'Emerald',
                              kashmiri: 'زمرد',
                              ladakhi: 'Emerald',
                            ),
                            style: VisitingCardStyle.emeraldTech,
                            activeColor: const Color(0xFF059669),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card Display with RepaintBoundary for capture
                    RepaintBoundary(
                      key: _cardBoundaryKey,
                      child: DigitalVisitingCardWidget(
                        profile: _profile,
                        style: _selectedStyle,
                        showAppLogo: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Prompt Hint
                    Center(
                      child: Text(
                        context.strings.localized(
                          telugu: '💡 మీ ప్రొఫైల్ వివరాలతో ఆటోమేటిక్‌గా రూపొందించబడింది',
                          english: '💡 Automatically generated with your profile details',
                          hindi: '💡 आपके प्रोफाइल विवरण के साथ स्वचालित रूप से तैयार',
                          tamil: '💡 உங்கள் சுயவிவர விவரங்களுடன் தானாக உருவாக்கப்பட்டது',
                          kannada: '💡 ನಿಮ್ಮ ಪ್ರೊಫೈಲ್ ವಿವರಗಳೊಂದಿಗೆ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ರಚಿಸಲಾಗಿದೆ',
                          malayalam: '💡 നിങ്ങളുടെ പ്രൊഫൈൽ വിശദാംശങ്ങൾ ഉപയോഗിച്ച് സ്വയമേവ സൃഷ്ടിച്ചു',
                          marathi: '💡 तुमच्या प्रोफाइल तपशीलांसह स्वयंचलितपणे तयार केले',
                          gujarati: '💡 તમારી પ્રોફાઇલ વિગતો સાથે આપમેળે જનરેટ થયેલ',
                          bengali: '💡 আপনার প্রোফাইলের তথ্যের সাথে স্বয়ংক্রিয়ভাবে তৈরি',
                          punjabi: '💡 ਤੁਹਾਡੇ ਪ੍ਰੋਫਾਈਲ ਵੇਰਵਿਆਂ ਨਾਲ ਆਟੋਮੈਟਿਕ ਤਿਆਰ ਕੀਤਾ ਗਿਆ',
                          odia: '💡 ଆପଣଙ୍କ ପ୍ରୋଫାଇଲ୍ ବିବରଣୀ ସହିତ ସ୍ୱତଃ ପ୍ରସ୍ତୁତ',
                          assamese: '💡 আপোনাৰ প্ৰ’ফাইল বিৱৰণৰ সৈতে স্বয়ংক্ৰিয়ভাৱে সৃষ্টি কৰা হৈছে',
                          konkani: '💡 तुमच्या प्रोफायल तपशीलां सयत आपशींच तयार केल्लें',
                          nepali: '💡 तपाईंको प्रोफाइल विवरणसहित स्वतः सिर्जना गरिएको',
                          meitei: '💡 নহাক্কী প্রোফাইল মরোলগা লোয়ননা অচুম্বা মওংদা শেম্বা',
                          mizo: '💡 I profile kimchang hmanga mahni intihpuitlinna',
                          kashmiri: '💡 تہٕنٛزِ پروفائل تفصیٖلاتَن سٟتؠ پانہٕ بَنٲومُت',
                          ladakhi: '💡 Nye profile thad dang mnyam du bzos pa',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Action Buttons: Save to Gallery & Share
                    Row(
                      children: <Widget>[
                        // Gallery Download
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: (_saving || _sharing) ? null : _saveToGallery,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.download_rounded),
                              label: Text(
                                context.strings.localized(
                                  telugu: 'గ్యాలరీలో సేవ్',
                                  english: 'Save to Gallery',
                                  hindi: 'गैलरी में सहेजें',
                                  tamil: 'கேலரியில் சேமி',
                                  kannada: 'ಗ್ಯಾಲರಿಯಲ್ಲಿ ಉಳಿಸಿ',
                                  malayalam: 'ഗ്യാലറിയിൽ സൂക്ഷിക്കുക',
                                  marathi: 'गॅलरीमध्ये सेव्ह करा',
                                  gujarati: 'ગૅલેરીમાં સાચવો',
                                  bengali: 'গ্যালারিতে সংরক্ষণ',
                                  punjabi: 'ਗੈਲਰੀ ਵਿੱਚ ਸੁਰੱਖਿਅਤ',
                                  odia: 'ଗ୍ୟାଲେରୀରେ ସେଭ୍ କରନ୍ତୁ',
                                  assamese: 'গেলেৰীত সংৰক্ষণ',
                                  konkani: 'गॅलरींत सांबाळा',
                                  nepali: 'ग्यालरीमा बचत गर्नुहोस्',
                                  meitei: 'গেলরিদা সেভ তৌ',
                                  mizo: 'Gallery-ah save rawh',
                                  kashmiri: 'گیلری منٛز محفوٗظ کٔرِو',
                                  ladakhi: 'Par mdzod nang save byed',
                                ),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // WhatsApp Share
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: (_saving || _sharing) ? null : _shareToWhatsApp,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _sharing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.share_rounded),
                              label: Text(
                                context.strings.localized(
                                  telugu: 'షేర్ చేయండి',
                                  english: 'Share Card',
                                  hindi: 'शेयर करें',
                                  tamil: 'பகிரவும்',
                                  kannada: 'ಹಂಚಿಕೊಳ್ಳಿ',
                                  malayalam: 'പങ്കിടുക',
                                  marathi: 'शेअर करा',
                                  gujarati: 'શેર કરો',
                                  bengali: 'শেয়ার করুন',
                                  punjabi: 'ਸਾਂਝਾ ਕਰੋ',
                                  odia: 'ସେୟାର୍ କରନ୍ତୁ',
                                  assamese: 'শ্বেয়াৰ কৰক',
                                  konkani: 'वांटा',
                                  nepali: 'साझा गर्नुहोस्',
                                  meitei: 'শিয়র তৌ',
                                  mizo: 'Share rawh',
                                  kashmiri: 'شیئر کٔرِو',
                                  ladakhi: 'Share byed',
                                ),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Primary Button: Go to Home (if from onboarding)
                    if (widget.fromOnboarding)
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _continueToHome,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            context.strings.localized(
                              telugu: 'యాప్ లోకి వెళ్లండి (Home)',
                              english: 'Continue to Home',
                              hindi: 'होम पर आगे बढ़ें',
                              tamil: 'முகப்புக்குத் தொடரவும்',
                              kannada: 'ಮುಖಪುಟಕ್ಕೆ ಮುಂದುವರಿಯಿರಿ',
                              malayalam: 'ഹോമിലേക്ക് തുടരുക',
                              marathi: 'मुख्यपृष्ठावर पुढे जा',
                              gujarati: 'હોમ પર આગળ વધો',
                              bengali: 'হোমে এগিয়ে যান',
                              punjabi: 'ਹੋਮ ਤੇ ਅੱਗੇ ਵਧੋ',
                              odia: 'ହୋମ୍ କୁ ଆଗକୁ ଯାଆନ୍ତୁ',
                              assamese: 'হোমলৈ অগ্ৰসৰ হওক',
                              konkani: 'घरा मुखार वचात',
                              nepali: 'गृहपृष्ठमा अगाडि बढ्नुहोस्',
                              meitei: 'হোমদা চৎথরো',
                              mizo: 'Home-ah kal chhunzawm rawh',
                              kashmiri: 'ہومس کُن برٛونٛہہ پَکِو',
                              ladakhi: 'Home la don',
                            ),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleChip({
    required String label,
    required VisitingCardStyle style,
    required Color activeColor,
  }) {
    final selected = _selectedStyle == style;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStyle = style),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
