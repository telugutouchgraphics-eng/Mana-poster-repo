import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
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
  State<DigitalVisitingCardScreen> createState() =>
      _DigitalVisitingCardScreenState();
}

class _DigitalVisitingCardScreenState extends State<DigitalVisitingCardScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  late PosterProfileData _profile;
  VisitingCardStyle _selectedStyle = VisitingCardStyle.classicPearlGold;
  bool _saving = false;
  bool _sharing = false;
  bool _savingDetails = false;
  bool _isCapturing = false;
  bool _loading = true;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile!;
      _emailController.text = _profile.effectiveEmail;
      _addressController.text = _profile.address;
      _loading = false;
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final loaded = await PosterProfileService.load();
    if (mounted) {
      setState(() {
        _profile = loaded;
        _emailController.text = loaded.effectiveEmail;
        _addressController.text = loaded.address;
        _loading = false;
      });
    }
  }

  void _syncProfileFromControllers() {
    final newEmail = _emailController.text.trim();
    final newAddress = _addressController.text.trim();
    if (newEmail != _profile.email || newAddress != _profile.address) {
      _profile = _profile.copyWith(email: newEmail, address: newAddress);
      PosterProfileService.save(_profile);
    }
  }

  Future<String?> _captureCardToTempFile() async {
    try {
      if (mounted) {
        setState(() => _isCapturing = true);
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final boundary =
          _cardBoundaryKey.currentContext?.findRenderObject()
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
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    if (Platform.isAndroid &&
        !(await MediaExportService.needsGalleryPermission())) {
      return true;
    }
    final permission = Platform.isAndroid
        ? Permission.storage
        : Permission.photos;
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    final requested = await <Permission>[permission].request();
    return requested.values.any((s) => s.isGranted || s.isLimited);
  }

  Future<void> _saveToGallery() async {
    if (_saving || _sharing) return;
    _syncProfileFromControllers();
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
                  tamil:
                      'கார்டைச் சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
                  kannada:
                      'ಕಾರ್ಡ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                  malayalam:
                      'കാർഡ് സേവ് ചെയ്യുന്നത് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
                  marathi:
                      'कार्ड सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
                  gujarati:
                      'કાર્ડ સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
                  bengali:
                      'কার্ড সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
                  punjabi:
                      'ਕਾਰਡ ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                  odia: 'କାର୍ଡ ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
                  assamese:
                      'কাৰ্ড সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
                  konkani: 'कार्ड सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
                  nepali:
                      'कार्ड बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
                  meitei:
                      'কার্দ সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
                  mizo: 'Card save a hlawhchham. Khawngaihin ti nawn leh rawh.',
                  kashmiri:
                      'کارڈ محفوٗظ کرنس منٛز ناکام۔ مہر کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
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

      if (result.success) {
        _recordVisitingCardEngagement();
      }

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
                      tamil:
                          'சேமிப்பது தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
                      kannada: 'ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                      malayalam:
                          'സേവ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
                      marathi: 'सेव्ह करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
                      gujarati: 'સાચવવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.',
                      bengali:
                          'সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
                      punjabi:
                          'ਸੁਰੱਖਿਅਤ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                      odia: 'ସେଭ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
                      assamese:
                          'সংৰক্ষণ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
                      konkani: 'सांबाळप जावंक ना. उपकार करून परत यत्न करा.',
                      nepali: 'बचत गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
                      meitei:
                          'সেভ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
                      mizo: 'Save a hlawhchham. Khawngaihin ti nawn leh rawh.',
                      kashmiri:
                          'محفوٗظ کرنس منٛز ناکام۔ مہر کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
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
    _syncProfileFromControllers();
    setState(() => _sharing = true);

    try {
      final path = await _captureCardToTempFile();
      if (path == null) {
        return;
      }
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final appLink = AppPublicInfo.playStoreUrl;
      final shareText = context.strings.localized(
        telugu:
            'నా డిజిటల్ విజిటింగ్ కార్డ్ - మన పోస్టర్ యాప్ ద్వారా రూపొందించబడింది.\n\nయాప్ లింక్: $appLink',
        english:
            'My Digital Visiting Card - Created with Mana Poster App.\n\nApp Link: $appLink',
        hindi:
            'मेरा डिजिटल विजिटिंग कार्ड - मना पोस्टर ऐप द्वारा निर्मित।\n\nऐप लिंक: $appLink',
        tamil:
            'எனது டிஜிட்டல் விசிட்டிங் கார்டு - மனா போஸ்டர் ஆப் மூலம் உருவாக்கப்பட்டது.\n\nஆப் இணைப்பு: $appLink',
        kannada:
            'ನನ್ನ ಡಿಜಿಟಲ್ ವಿಸಿಟಿಂಗ್ ಕಾರ್ಡ್ - ಮನ ಪೋಸ್ಟರ್ ಆಪ್ ಮೂಲಕ ರಚಿಸಲಾಗಿದೆ.\n\nಆಪ್ ಲಿಂಕ್: $appLink',
        malayalam:
            'എന്റെ ഡിജിറ്റൽ വിസിറ്റിംഗ് കാർഡ് - മനാ പോസ്റ്റർ ആപ്പ് വഴി നിർമ്മിച്ചത്.\n\nആപ്പ് ലിങ്ക്: $appLink',
        marathi:
            'माझे डिजिटल व्हिजिटिंग कार्ड - मना पोस्टर ॲपद्वारे तयार केले.\n\nॲप लिंक: $appLink',
        gujarati:
            'મારું ડિજિટલ વિઝિટિંગ કાર્ડ - મના પોસ્ટર એપ દ્વારા બનાવેલ.\n\nએપ લિંક: $appLink',
        bengali:
            'আমার ডিজিটাল ভিজিটিং কার্ড - মানা পোস্টার অ্যাপ দ্বারা তৈরি।\n\nঅ্যাপ লিঙ্ক: $appLink',
        punjabi:
            'ਮੇਰਾ ਡਿਜੀਟਲ ਵਿਜ਼ਿਟਿੰਗ ਕਾਰਡ - ਮਨਾ ਪੋਸਟਰ ਐਪ ਦੁਆਰਾ ਬਣਾਇਆ ਗਿਆ।\n\nਐਪ ਲਿੰਕ: $appLink',
        odia:
            'ମୋର ଡିଜିଟାଲ୍ ଭିଜିଟିଂ କାର୍ଡ - ମନା ପୋଷ୍ଟର ଆପ୍ ଦ୍ୱାରା ନିର୍ମିତ।\n\nଆପ୍ ଲିଙ୍କ୍: $appLink',
        assamese:
            'মোৰ ডিজিটেল ভিজিটিং কাৰ্ড - মানা পোষ্টাৰ এপেৰে নিৰ্মিত।\n\nএপ লিংক: $appLink',
        konkani:
            'म्हजें डिजीटल विझिटींग कार्ड - मना पोस्टर ॲपा वरवीं तयार केल्लें.\n\nॲप लिंक: $appLink',
        nepali:
            'मेरो डिजिटल भिजिटिङ कार्ड - मना पोस्टर एपद्वारा सिर्जना गरिएको।\n\nएप लिङ्क: $appLink',
        meitei:
            'ইহাক্কী দিজিতেল বিজিতিং কার্দ - মনা পোস্তর এপ্তা শেম্বা।\n\nএপ লিঙ্ক: $appLink',
        mizo:
            'Ka Digital Visiting Card - Mana Poster App atanga siam.\n\nApp link: $appLink',
        kashmiri:
            'میٛون ڈِجیٹَل وزٹنگ کارڈ - مَنا پوسٹر اَیپہٕ ذٔریعہٕ بنٲومُت۔\n\nایپ لِنک: $appLink',
        ladakhi:
            'Nye Digital Visiting Card - Mana Poster App nangi bzos pa.\n\nApp link: $appLink',
      );
      await MediaExportService.shareImageFile(
        path,
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      _recordVisitingCardEngagement();
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  void _recordVisitingCardEngagement() {
    try {
      FirebaseFirestore.instance
          .collection('visitingCardStats')
          .doc('summary')
          .set(<String, dynamic>{
            'totalCount': FieldValue.increment(1),
            'lastActivityAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Visiting card engagement record error: $e');
      }
    }
  }

  Future<void> _saveCustomDetails() async {
    if (_savingDetails) return;
    setState(() => _savingDetails = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final cleanEmail = _emailController.text.trim();
      final cleanAddress = _addressController.text.trim();
      final updated = _profile.copyWith(
        email: cleanEmail,
        address: cleanAddress,
      );
      setState(() => _profile = updated);
      await PosterProfileService.save(updated);

      if (mounted) {
        messenger.showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'కార్డ్ వివరాలు సేవ్ చేయబడ్డాయి!',
                english: 'Card details saved!',
                hindi: 'कार्ड विवरण सहेज लिए गए!',
                tamil: 'கார்டு விவரங்கள் சேமிக்கப்பட்டன!',
                kannada: 'ಕಾರ್ಡ್ ವಿವರಗಳನ್ನು ಉಳಿಸಲಾಗಿದೆ!',
                malayalam: 'കാർഡ് വിശദാംശങ്ങൾ സംരക്ഷിച്ചു!',
                marathi: 'कार्ड तपशील जतन केले!',
                gujarati: 'કાર્ડ વિગતો સાચવવામાં આવી!',
                bengali: 'কার্ডের বিবরণ সংরক্ষিত হয়েছে!',
                punjabi: 'ਕਾਰਡ ਵੇਰਵੇ ਸੁਰੱਖਿਅਤ ਕੀਤੇ ਗਏ!',
                odia: 'କାର୍ଡ ବିବରଣୀ ସେଭ୍ ହୋଇଛି!',
                assamese: 'কাৰ্ডৰ বিৱৰণ সংৰক্ষণ কৰা হ’ল!',
                konkani: 'कार्ड तपशील सांबाळ्ळे!',
                nepali: 'कार्ड विवरणहरू सुरक्षित गरियो!',
                meitei: 'কার্দকী অকুপ্পা মরোল সেভ তৌরে!',
                mizo: 'Card details dahthat a ni ta!',
                kashmiri: 'کارڈ تفصیٖلات آیہِ محفوٗظ کَرنہٕ!',
                ladakhi: 'Card details save song!',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingDetails = false);
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
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // 5 Premium Card Style Switcher Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: <Widget>[
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'పెర్ల్ & గోల్డ్',
                              english: 'Pearl & Gold',
                              hindi: 'पर्ल और गोल्ड',
                              tamil: 'முத்து & தங்கம்',
                              kannada: 'ಪರ್ಲ್ & ಗೋಲ್ಡ್',
                              malayalam: 'പേൾ & ഗോൾഡ്',
                              marathi: 'पर्ल आणि गोल्ड',
                              gujarati: 'પર્લ અને ગોલ્ડ',
                              bengali: 'পার্ল ও গোল্ড',
                              punjabi: 'ਪਰਲ ਅਤੇ ਗੋਲਡ',
                              odia: 'ପର୍ଲ ଏବଂ ଗୋଲ୍ଡ',
                              assamese: 'পাৰ্ল আৰু গোল্ড',
                              konkani: 'पर्ल आनी गोल्ड',
                              nepali: 'पर्ल र सुनौलो',
                              meitei: 'মুক্তা অমসুং শনা',
                              mizo: 'Pearl & Gold',
                              kashmiri: 'پَرل تہٕ گولڈ',
                              ladakhi: 'Pearl & Gold',
                            ),
                            style: VisitingCardStyle.classicPearlGold,
                            activeColor: const Color(0xFFD4AF37),
                            activeTextColor: const Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 8),
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'డ్యూయల్-టోన్ గోల్డ్',
                              english: 'Dual-Tone Gold',
                              hindi: 'ड्यूल-टोन गोल्ड',
                              tamil: 'டூயல்-டோன் தங்கம்',
                              kannada: 'ಡ್ಯುಯಲ್-ಟೋನ್ ಗೋಲ್ಡ್',
                              malayalam: 'ഡ്യുവൽ-ടോൺ ಗೋಲ್ಡ್',
                              marathi: 'ड्युअल-टोन गोल्ड',
                              gujarati: 'ડ્યુઅલ-ટોન ગોલ્ડ',
                              bengali: 'ডুয়াল-টোন গোল্ড',
                              punjabi: 'ਡਿਊਲ-ਟੋਨ ਗੋਲਡ',
                              odia: 'ଡୁଆଲ୍-ଟୋନ୍ ଗୋଲ୍ଡ',
                              assamese: 'ডুৱেল-টোন গোল্ড',
                              konkani: 'ड्युअल-टोन गोल्ड',
                              nepali: 'डुअल-टोन सुनौलो',
                              meitei: 'দিয়ুয়েল-তোন শনা',
                              mizo: 'Dual-Tone Gold',
                              kashmiri: 'ڈیوٗل ٹون گولڈ',
                              ladakhi: 'Dual-Tone Gold',
                            ),
                            style: VisitingCardStyle.dualToneObsidian,
                            activeColor: const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 8),
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'రాయల్ సాఫైర్',
                              english: 'Royal Sapphire',
                              hindi: 'रॉयल नीलम',
                              tamil: 'ராயல் நீலக்கல்',
                              kannada: 'ರಾಯಲ್ ನೀಲಮಣಿ',
                              malayalam: 'റോയൽ സഫയർ',
                              marathi: 'रॉयल नीलम',
                              gujarati: 'રોયલ સેફાયર',
                              bengali: 'রয়্যাল স্যাফায়ার',
                              punjabi: 'ਰਾਇਲ ਨੀਲਮ',
                              odia: 'ରୟାଲ୍ ନୀଳମଣି',
                              assamese: 'ৰয়েল নীলামণি',
                              konkani: 'रॉयल नीलम',
                              nepali: 'रोयल नीलम',
                              meitei: 'রোয়ল সেফায়র',
                              mizo: 'Royal Sapphire',
                              kashmiri: 'رائل نیلم',
                              ladakhi: 'Royal Sapphire',
                            ),
                            style: VisitingCardStyle.royalSapphire,
                            activeColor: const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 8),
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'ఎమరాల్డ్ క్రెస్ట్',
                              english: 'Emerald Crest',
                              hindi: 'एमराल्ड क्रेस्ट',
                              tamil: 'எமரால்டு க்ரெஸ்ட்',
                              kannada: 'ಎಮರಾಲ್ಡ್ ಕ್ರೆಸ್ಟ್',
                              malayalam: 'എമറാൾഡ് ക്രസ്റ്റ്',
                              marathi: 'एमराल्ड क्रेस्ट',
                              gujarati: 'એમરાલ્ડ ક્રેસ્ટ',
                              bengali: 'এমরাল্ড ক্রেস্ট',
                              punjabi: 'ਐਮਰਾਲਡ ਕ੍ਰੈਸਟ',
                              odia: 'ଏମରାଲ୍ଡ କ୍ରେଷ୍ଟ',
                              assamese: 'এমৰাল্ড ক্ৰেষ্ট',
                              konkani: 'एमराल्ड क्रेस्ट',
                              nepali: 'एमराल्ड क्रेस्ट',
                              meitei: 'মরকত ক্রেস্ত',
                              mizo: 'Emerald Crest',
                              kashmiri: 'زمرد کریٛسٹ',
                              ladakhi: 'Emerald Crest',
                            ),
                            style: VisitingCardStyle.emeraldCrest,
                            activeColor: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          _buildStyleChip(
                            label: context.strings.localized(
                              telugu: 'మోడరన్ స్లేట్',
                              english: 'Modern Slate',
                              hindi: 'मॉडर्न स्लेट',
                              tamil: 'மாடர்ன் ஸ்லேட்',
                              kannada: 'ಮಾಡರ್ನ್ ಸ್ಲೇಟ್',
                              malayalam: 'മോഡേൺ സ്ലೇറ്റ്',
                              marathi: 'मॉडर्न स्लेट',
                              gujarati: 'મોડર્ન સ્લેಟ್',
                              bengali: 'মডার্ন স্লেট',
                              punjabi: 'ਮਾਡਰਨ ਸਲੇਟ',
                              odia: 'ମଡର୍ଣ୍ଣ ସ୍ଲେଟ୍',
                              assamese: 'মডাৰ্ন শ্লেট',
                              konkani: 'मॉडर्न स्लेट',
                              nepali: 'आधुनिक स्लेट',
                              meitei: 'মদর্ন স্লেত',
                              mizo: 'Modern Slate',
                              kashmiri: 'ماڈرن سلیٹ',
                              ladakhi: 'Modern Slate',
                            ),
                            style: VisitingCardStyle.modernTitaniumSlate,
                            activeColor: const Color(0xFFEA580C),
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
                        email: _emailController.text,
                        address: _addressController.text,
                        showAppLogo: true,
                        enableShineEffect: !_isCapturing,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons: Save to Gallery & Share
                    Row(
                      children: <Widget>[
                        // Gallery Download
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: (_saving || _sharing)
                                  ? null
                                  : _saveToGallery,
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
                              onPressed: (_saving || _sharing)
                                  ? null
                                  : _shareToWhatsApp,
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

                    // Customization Card
                    _buildCustomizationCard(),

                    // Primary Button: Go to Home (if from onboarding)
                    if (widget.fromOnboarding)
                      if (widget.fromOnboarding) ...<Widget>[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _continueToHome,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFF334155),
                                width: 1.5,
                              ),
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
    Color activeTextColor = Colors.white,
  }) {
    final selected = _selectedStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeColor : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFF334155),
            width: 1.2,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeTextColor : const Color(0xFF94A3B8),
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Email Field
          Text(
            context.strings.localized(
              telugu: 'ఈమెయిల్ ఐడి',
              english: 'Email ID',
              hindi: 'ईमेल आईडी',
              tamil: 'மின்னஞ்சல் ஐடி',
              kannada: 'ಇಮೇಲ್ ಐಡಿ',
              malayalam: 'ഇമെയിൽ ഐഡി',
              marathi: 'ईमेल आयडी',
              gujarati: 'ઇમેઇલ આઈડી',
              bengali: 'ইমেল আইডি',
              punjabi: 'ਈਮੇਲ ਆਈਡੀ',
              odia: 'ଇମେଲ୍ ଆଇଡି',
              assamese: 'ইমেইল আইডি',
              konkani: 'ईमेल आयडी',
              nepali: 'इमेल आईडी',
              meitei: 'ইমেল আইদি',
              mizo: 'Email ID',
              kashmiri: 'اِی میل آئی ڈی',
              ladakhi: 'Email ID',
            ),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: context.strings.localized(
                telugu: 'మీ ఈమెయిల్ ఎంటర్ చేయండి',
                english: 'Enter your email',
                hindi: 'अपना ईमेल दर्ज करें',
                tamil: 'உங்கள் மின்னஞ்சலை உள்ளிடவும்',
                kannada: 'ನಿಮ್ಮ ಇಮೇಲ್ ನಮೂದಿಸಿ',
                malayalam: 'നിങ്ങളുടെ ഇമെയിൽ നൽകുക',
                marathi: 'तुमचा ईमेल प्रविष्ट करा',
                gujarati: 'તમારો ઇમેઇલ દાખલ કરો',
                bengali: 'আপনার ইমেল লিখুন',
                punjabi: 'ਆਪਣਾ ਈਮੇਲ ਦਰਜ ਕਰੋ',
                odia: 'ଆପଣଙ୍କ ଇମେଲ୍ ପ୍ରବେଶ କରନ୍ତୁ',
                assamese: 'আপোনাৰ ইমেইল লিখক',
                konkani: 'तुमचो ईमेल बरयात',
                nepali: 'आफ्नो इमेल प्रविष्ट गर्नुहोस्',
                meitei: 'নহাক্কী ইমেল ইয়ু',
                mizo: 'I email chhu lut rawh',
                kashmiri: 'پَنُن اِی میل دَرٕج کٔرِو',
                ladakhi: 'Nye email thog',
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF38BDF8),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Address Field
          Text(
            context.strings.localized(
              telugu: 'చిరునామా',
              english: 'Address',
              hindi: 'पता',
              tamil: 'முகவரி',
              kannada: 'ವಿಳಾಸ',
              malayalam: 'വിലാസം',
              marathi: 'पत्ता',
              gujarati: 'સરનામું',
              bengali: 'ঠিকানা',
              punjabi: 'ਪਤਾ',
              odia: 'ଠିକଣା',
              assamese: 'ঠিকনা',
              konkani: 'पत्तो',
              nepali: 'ठेगाना',
              meitei: 'লৈফম',
              mizo: 'Address',
              kashmiri: 'پتہٕ',
              ladakhi: 'Address',
            ),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _addressController,
            keyboardType: TextInputType.multiline,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: context.strings.localized(
                telugu: 'షాప్ నం., వీధి, నగరం',
                english: 'Shop No., Street, City',
                hindi: 'दुकान नं., सड़क, शहर',
                tamil: 'கடை எண், தெரு, நகரம்',
                kannada: 'ಅಂಗಡಿ ನಂ., ರಸ್ತೆ, ನಗರ',
                malayalam: 'ഷോപ്പ് നമ്പർ, തെരുവ്, നഗരം',
                marathi: 'दुकान क्र., रस्ता, शहर',
                gujarati: 'દુકાન નં., શેરી, શહેર',
                bengali: 'দোকান নং, রাস্তা, শহর',
                punjabi: 'ਦੁਕਾਨ ਨੰ., ਗਲੀ, ਸ਼ਹਿਰ',
                odia: 'ଦୋକାନ ନଂ, ଗଳି, ସହର',
                assamese: 'দোকান নং, ৰাস্তা, চহৰ',
                konkani: 'दुकान क्र., रस्तो, शार',
                nepali: 'पसल नं., सडक, सहर',
                meitei: 'দোকান নম্বর, লম্বি, সহর',
                mizo: 'Dawr No., Veng, Khawpui',
                kashmiri: 'دُکان نمبر، سَڑک، شَہَر',
                ladakhi: 'Shop No., lam, shahr',
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF38BDF8),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Save Details Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _savingDetails ? null : _saveCustomDetails,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _savingDetails
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                context.strings.localized(
                  telugu: 'వివరాలు సేవ్ చేయండి',
                  english: 'Save Details',
                  hindi: 'विवरण सहेजें',
                  tamil: 'விவரங்களைச் சேமிக்கவும்',
                  kannada: 'ವಿವರಗಳನ್ನು ಉಳಿಸಿ',
                  malayalam: 'വിശദാംശങ്ങൾ സൂക്ഷിക്കുക',
                  marathi: 'तपशील जतन करा',
                  gujarati: 'વિગતો સાચવો',
                  bengali: 'বিবরণ সংরক্ষণ করুন',
                  punjabi: 'ਵੇਰਵੇ ਸੁਰੱਖਿਅਤ ਕਰੋ',
                  odia: 'ବିବରଣୀ ସେଭ୍ କରନ୍ତୁ',
                  assamese: 'বিৱৰণ সংৰক্ষণ কৰক',
                  konkani: 'तपशील सांबाळात',
                  nepali: 'विवरणहरू बचत गर्नुहोस्',
                  meitei: 'মরোলশিং সেভ তৌ',
                  mizo: 'Details dahtha rawh',
                  kashmiri: 'تفصیٖلات کٔرِو محفوٗظ',
                  ladakhi: 'Details save byed',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
