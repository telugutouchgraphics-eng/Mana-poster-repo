import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with AppLanguageStateMixin {
  final PermissionService _service = PermissionService();
  bool _loading = false;
  PermissionSnapshot _snapshot = const PermissionSnapshot(
    photos: AppPermissionState(
      type: AppPermissionType.photos,
      status: PermissionStatus.denied,
    ),
    camera: AppPermissionState(
      type: AppPermissionType.camera,
      status: PermissionStatus.denied,
    ),
    notifications: AppPermissionState(
      type: AppPermissionType.notifications,
      status: PermissionStatus.denied,
    ),
    location: AppPermissionState(
      type: AppPermissionType.location,
      status: PermissionStatus.denied,
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final snapshot = await _service.getSnapshot();
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = snapshot);
  }

  Future<void> _completeFlowAndGoHome() async {
    await AppFlowService.markPermissionsStepHandled();
    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final String nextRoute =
        await AppFlowService.resolveAuthenticatedEntryRoute();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  Future<void> _grant() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      final snapshot = await _service.requestEssentialPermissions();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
      await NotificationService.instance.syncCurrentPreferences();
      await _completeFlowAndGoHome();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'Permissions request పూర్తి కాలేదు. మళ్లీ ప్రయత్నించండి.',
              english:
                  'Permissions request could not be completed. Please try again.',
              hindi: 'अनुमति अनुरोध पूरा नहीं हो सका। कृपया पुन: प्रयास करें।',
              tamil: 'அனுமதி கோரிக்கையை முடிக்க முடியவில்லை. மீண்டும் முயல்க.',
              kannada: 'ಅನುಮತಿ ವಿನಂತಿಯನ್ನು ಪೂರ್ಣಗೊಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'അനുമതി അഭ്യർത്ഥന പൂർത്തിയാക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
              marathi: 'परवानगी विनंती पूर्ण होऊ शकली नाही. कृपया पुन्हा प्रयत्न करा.',
              gujarati: 'પરવાનગી વિનંતી પૂર્ણ થઈ શકી નથી. ફરી પ્રયાસ કરો.',
              bengali: 'অনুমতির অনুরোধ সম্পূর্ণ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
              punjabi: 'ਇਜਾਜ਼ਤ ਦੀ ਬੇਨਤੀ ਪੂਰੀ ਨਹੀਂ ਹੋ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
              odia: 'ଅନୁମତି ଅନୁରୋଧ ସମ୍ପୂର୍ଣ୍ଣ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
              assamese: 'অনুমতিৰ অনুৰোধ সম্পূৰ্ণ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
              konkani: 'परवांगी विनंती पूर्ण जाली ना. उपकार करून परत प्रयत्न करात.',
              nepali: 'अनुमति अनुरोध पूरा हुन सकेन। कृपया पुन: प्रयास गर्नुहोस्।',
              meitei: 'Permissions request loisinba ngamkhide. Amuk hanna hotnabiyu.',
              mizo: 'Phalna dilna tihpuitlin theih a ni lo. Khawngaihin ti nawn leh rawh.',
              kashmiri: 'اِجازتھ ہٕنٛز درخواست ہیکہِ نہٕ پوٗرٕ گژھِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
              ladakhi: 'ཆོག་མཆན་རེ་འདུན་ལེགས་གྲུབ་མ་བྱུང། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _continueLater() async {
    await _completeFlowAndGoHome();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final cs = Theme.of(context).colorScheme;
    final copy = _PermissionIntroCopy(context.currentLanguage);

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
                                        Color(0xFFEF4444),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  copy.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  copy.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _PermissionRow(
                                  icon: Icons.photo_library_outlined,
                                  iconColor: const Color(0xFF0EA5E9),
                                  badgeColor: const Color(0xFFE0F2FE),
                                  title: strings.photosGallery,
                                  subtitle: copy.photosSubtitle,
                                  granted: _snapshot.photos.isGranted,
                                ),
                                const SizedBox(height: 12),
                                _PermissionRow(
                                  icon: Icons.photo_camera_outlined,
                                  iconColor: const Color(0xFF8B5CF6),
                                  badgeColor: const Color(0xFFEDE9FE),
                                  title: strings.localized(
                                    telugu: 'కెమెరా',
                                    english: 'Camera',
                                    hindi: 'कैमरा',
                                    tamil: 'கேமரா',
                                    kannada: 'ಕ್ಯಾಮೆರಾ',
                                    malayalam: 'ക്യാമറ',
                                    marathi: 'कॅमेरा',
                                    gujarati: 'કેમેરા',
                                    bengali: 'ক্যামেরা',
                                    punjabi: 'ਕੈਮਰਾ',
                                    odia: 'କ୍ୟାମେରା',
                                    assamese: 'কেমেৰা',
                                    konkani: 'कॅमेरा',
                                    nepali: 'क्यामेरा',
                                    meitei: 'Camera',
                                    mizo: 'Camera',
                                    kashmiri: 'کیمرا',
                                    ladakhi: 'པར་ཆས།',
                                  ),
                                  subtitle: copy.cameraSubtitle,
                                  granted: _snapshot.camera.isGranted,
                                ),
                                const SizedBox(height: 12),
                                _PermissionRow(
                                  icon: Icons.notifications_none_rounded,
                                  iconColor: const Color(0xFF14B8A6),
                                  badgeColor: const Color(0xFFCCFBF1),
                                  title: strings.notifications,
                                  subtitle: copy.notificationsSubtitle,
                                  granted: _snapshot.notifications.isGranted,
                                ),
                                const SizedBox(height: 12),
                                _PermissionRow(
                                  icon: Icons.location_on_outlined,
                                  iconColor: const Color(0xFF16A34A),
                                  badgeColor: const Color(0xFFDCFCE7),
                                  title: strings.localized(
                                    telugu: 'లొకేషన్',
                                    english: 'Location',
                                    hindi: 'स्थान',
                                    tamil: 'இருப்பிடம்',
                                    kannada: 'ಸ್ಥಳ',
                                    malayalam: 'ലൊക്കേഷൻ',
                                    marathi: 'स्थान',
                                    gujarati: 'સ્થાન',
                                    bengali: 'অবস্থান',
                                    punjabi: 'ਟਿਕਾਣਾ',
                                    odia: 'ସ୍ଥାନ',
                                    assamese: 'স্থান',
                                    konkani: 'सुवात',
                                    nepali: 'स्थान',
                                    meitei: 'Location',
                                    mizo: 'Hmun awmna',
                                    kashmiri: 'جاے',
                                    ladakhi: 'གནས་ཡུལ།',
                                  ),
                                  subtitle: copy.locationSubtitle,
                                  granted: _snapshot.location.isGranted,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  copy.footerHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                PrimaryButton(
                                  label: strings.allowLabel,
                                  loading: _loading,
                                  onPressed: _grant,
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: _loading ? null : _continueLater,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(strings.laterLabel),
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
              child: AppScreenBackButton(fallbackRoute: AppRoutes.religion),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: granted
                ? const Color(0xFFDCFCE7)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            granted
                ? context.strings.localized(
                    telugu: 'అనుమతి ఉంది',
                    english: 'Allowed',
                    hindi: 'स्वीकृत',
                    tamil: 'அனுமதிக்கப்பட்டது',
                    kannada: 'ಅನುಮತಿಸಲಾಗಿದೆ',
                    malayalam: 'അനുവദിച്ചു',
                    marathi: 'परवानगी दिली',
                    gujarati: 'મંજૂરી આપી',
                    bengali: 'অনুমোদিত',
                    punjabi: 'ਇਜਾਜ਼ਤ ਦਿੱਤੀ',
                    odia: 'ଅନୁମୋଦିତ',
                    assamese: 'অনুমোদিত',
                    konkani: 'परवांगी दिली',
                    nepali: 'स्वीकृत',
                    meitei: 'Allowed',
                    mizo: 'Phal a ni',
                    kashmiri: 'منظوٗر',
                    ladakhi: 'ཆོག་མཆན་ཐོབ།',
                  )
                : context.strings.localized(
                    telugu: 'తరువాత కూడా చేయొచ్చు',
                    english: 'Optional now',
                    hindi: 'अभी वैकल्पिक है',
                    tamil: 'இப்போது விருப்பத்தேர்வு',
                    kannada: 'ಈಗ ಐಚ್ಛಿಕ',
                    malayalam: 'ഇപ്പോൾ നിർബന്ധമില്ല',
                    marathi: 'आता ऐच्छिक आहे',
                    gujarati: 'હવે વૈકલ્પિક છે',
                    bengali: 'এখন ঐচ্ছিক',
                    punjabi: 'ਹੁਣ ਵਿਕਲਪਿਕ ਹੈ',
                    odia: 'ବର୍ତ୍ତମାନ ଐଚ୍ଛିକ',
                    assamese: 'এতিয়া ঐচ্ছিক',
                    konkani: 'आतां ऐच्छिक',
                    nepali: 'अहिले ऐच्छिक छ',
                    meitei: 'Houdokpamuk oina thambiyu',
                    mizo: 'Tun atan chuan duhthlan a ni',
                    kashmiri: 'وؠن چھُ اِختیاری',
                    ladakhi: 'ད་ལྟ་འདེམས་ཁ་ཙམ་ཡིན།',
                  ),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: granted ? const Color(0xFF166534) : cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionIntroCopy {
  const _PermissionIntroCopy(this.language);

  final AppLanguage language;

  static const Map<String, Map<AppLanguage, String>> _dict = {
    'title': {
      AppLanguage.telugu: 'అనుమతులు',
      AppLanguage.english: 'Permissions',
      AppLanguage.hindi: 'अनुमतियाँ',
      AppLanguage.tamil: 'அனுமதிகள்',
      AppLanguage.kannada: 'ಅನುಮತಿಗಳು',
      AppLanguage.malayalam: 'അനുമതികൾ',
      AppLanguage.marathi: 'परवानग्या',
      AppLanguage.gujarati: 'પરવાનગીઓ',
      AppLanguage.bengali: 'অনুমতিসমূহ',
      AppLanguage.punjabi: 'ਇਜਾਜ਼ਤਾਂ',
      AppLanguage.odia: 'ଅନୁମତିଗୁଡ଼ିକ',
      AppLanguage.assamese: 'অনুমতিসমূহ',
      AppLanguage.konkani: 'परवांग्यो',
      AppLanguage.nepali: 'अनुमतिहरू',
      AppLanguage.meitei: 'Permissions',
      AppLanguage.mizo: 'Phalnate',
      AppLanguage.kashmiri: 'اِجازتھ',
      AppLanguage.ladakhi: 'ཆོག་མཆན།',
    },
    'subtitle': {
      AppLanguage.telugu: 'త్వరగా పూర్తిచేయండి',
      AppLanguage.english: 'Quick setup',
      AppLanguage.hindi: 'त्वरित सेटअप',
      AppLanguage.tamil: 'விரைவான அமைப்பு',
      AppLanguage.kannada: 'ತ್ವರಿತ ಸೆಟಪ್',
      AppLanguage.malayalam: 'ദ്രുത സജ്ജീകരണം',
      AppLanguage.marathi: 'जलद सेटअप',
      AppLanguage.gujarati: 'ઝડપી સેટઅપ',
      AppLanguage.bengali: 'দ্রুত সেটআপ',
      AppLanguage.punjabi: 'ਤੁਰੰਤ ਸੈੱਟਅੱਪ',
      AppLanguage.odia: 'ଶୀଘ୍ର ସେଟଅପ୍',
      AppLanguage.assamese: 'দ্ৰুত ছেটআপ',
      AppLanguage.konkani: 'रोकडी मांडणी',
      AppLanguage.nepali: 'द्रुत सेटअप',
      AppLanguage.meitei: 'Thouna semba',
      AppLanguage.mizo: 'Siam rang nan',
      AppLanguage.kashmiri: 'جلدی سیٹ اپ',
      AppLanguage.ladakhi: 'མགྱོགས་པོའི་སྒྲིག་བཀོད།',
    },
    'photosSubtitle': {
      AppLanguage.telugu: 'పోస్టర్లు సేవ్ చేయడానికి.',
      AppLanguage.english: 'To save posters.',
      AppLanguage.hindi: 'पोस्टर सहेजने के लिए।',
      AppLanguage.tamil: 'போஸ்டர்களைச் சேமிக்க.',
      AppLanguage.kannada: 'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಉಳಿಸಲು.',
      AppLanguage.malayalam: 'പോസ്റ്ററുകൾ സംരക്ഷിക്കാൻ.',
      AppLanguage.marathi: 'पोस्टर्स जतन करण्यासाठी.',
      AppLanguage.gujarati: 'પોસ્ટર્સ સાચવવા માટે.',
      AppLanguage.bengali: 'পোস্টার সংরক্ষণ করতে।',
      AppLanguage.punjabi: 'ਪੋਸਟਰ ਸੁਰੱਖਿਅਤ ਕਰਨ ਲਈ।',
      AppLanguage.odia: 'ପୋଷ୍ଟର ସଂରକ୍ଷଣ କରିବାକୁ।',
      AppLanguage.assamese: 'পোষ্টাৰ সংৰক্ষণ কৰিবলৈ।',
      AppLanguage.konkani: 'पोस्टरां सांबाळपाक.',
      AppLanguage.nepali: 'पोस्टरहरू सुरक्षित गर्नका लागि।',
      AppLanguage.meitei: 'Posters save tounaba.',
      AppLanguage.mizo: 'Poster dah ṭhat nan.',
      AppLanguage.kashmiri: 'پوسٹر محفوٗظ کرنہٕ خٲطرٕ।',
      AppLanguage.ladakhi: 'པོ་སཊར་ཉར་ཚགས་ལ།',
    },
    'cameraSubtitle': {
      AppLanguage.telugu: 'ఫోటో తీసుకోవడానికి.',
      AppLanguage.english: 'To capture your photo.',
      AppLanguage.hindi: 'अपनी फ़ोटो लेने के लिए।',
      AppLanguage.tamil: 'உங்கள் புகைப்படத்தை எடுக்க.',
      AppLanguage.kannada: 'ನಿಮ್ಮ ಫೋಟೋ ಸೆರೆಹಿಡಿಯಲು.',
      AppLanguage.malayalam: 'ನಿങ്ങളുടെ ഫോട്ടോ പകർത്താൻ.',
      AppLanguage.marathi: 'तुमचा फोटो काढण्यासाठी.',
      AppLanguage.gujarati: 'તમારો ફોટો પાડવા માટે.',
      AppLanguage.bengali: 'আপনার ছবি তুলতে।',
      AppLanguage.punjabi: 'ਆਪਣੀ ਫ਼ੋਟੋ ਖਿੱਚਣ ਲਈ।',
      AppLanguage.odia: 'ଆପଣଙ୍କ ଫଟୋ ଉଠାଇବାକୁ।',
      AppLanguage.assamese: 'আপোনাৰ ফটো তুলিবলৈ।',
      AppLanguage.konkani: 'तुमचो फोटो काडपाक.',
      AppLanguage.nepali: 'आफ्नो फोटो खिच्नका लागि।',
      AppLanguage.meitei: 'Photo lounaba.',
      AppLanguage.mizo: 'I thlalak la turin.',
      AppLanguage.kashmiri: 'پنہٕنۍ فوٹو تُلنہٕ خٲطرٕ।',
      AppLanguage.ladakhi: 'ཁྱེད་རང་གི་པར་རྒྱག་པར།',
    },
    'notificationsSubtitle': {
      AppLanguage.telugu: 'అప్‌డేట్స్ కోసం.',
      AppLanguage.english: 'For updates.',
      AppLanguage.hindi: 'अपडेट के लिए।',
      AppLanguage.tamil: 'புதுப்பிப்புகளுக்கு.',
      AppLanguage.kannada: 'ಅಪ್‌ಡೇಟ್‌ಗಳಿಗಾಗಿ.',
      AppLanguage.malayalam: 'അപ്‌ഡേറ്റുകൾക്കായി.',
      AppLanguage.marathi: 'अपडेट्ससाठी.',
      AppLanguage.gujarati: 'અપડેટ્સ માટે.',
      AppLanguage.bengali: 'আপডেটের জন্য।',
      AppLanguage.punjabi: 'ਅੱਪਡੇਟਾਂ ਲਈ।',
      AppLanguage.odia: 'ଅପଡେଟ୍ ପାଇଁ।',
      AppLanguage.assamese: 'আপডেটৰ বাবে।',
      AppLanguage.konkani: 'ताजी म्हायती मेळपाक.',
      AppLanguage.nepali: 'अपडेटहरूका लागि।',
      AppLanguage.meitei: 'Updates gi damak.',
      AppLanguage.mizo: 'Update hriat nan.',
      AppLanguage.kashmiri: 'اپڈیٹس خٲطرٕ।',
      AppLanguage.ladakhi: 'གསར་བསྒྱུར་ཆེད་དུ།',
    },
    'locationSubtitle': {
      AppLanguage.telugu: 'మీ ప్రాంతానికి సరిపోయే కంటెంట్ చూపడానికి.',
      AppLanguage.english: 'To show content relevant to your area.',
      AppLanguage.hindi: 'आपके क्षेत्र के लिए प्रासंगिक सामग्री दिखाने के लिए।',
      AppLanguage.tamil: 'உங்கள் பகுதிக்கு ஏற்ற உள்ளடக்கத்தைக் காட்ட.',
      AppLanguage.kannada: 'ನಿಮ್ಮ ಪ್ರದೇಶಕ್ಕೆ ಸೂಕ್ತವಾದ ವಿಷಯವನ್ನು ತೋರಿಸಲು.',
      AppLanguage.malayalam: 'നിങ്ങളുടെ പ്രദേശത്തിന് അനുയോജ്യമായ ഉള്ളടക്കം കാണിക്കാൻ.',
      AppLanguage.marathi: 'तुमच्या भागाशी संबंधित सामग्री दाखवण्यासाठी.',
      AppLanguage.gujarati: 'તમારા વિસ્તારને સંબંધિત સામગ્રી દર્શાવવા માટે.',
      AppLanguage.bengali: 'আপনার এলাকার প্রাসঙ্গিক বিষয়বস্তু দেখানোর জন্য।',
      AppLanguage.punjabi: 'ਤੁਹਾਡੇ ਖੇਤਰ ਨਾਲ ਸੰਬੰਧਿਤ ਸਮੱਗਰੀ ਦਿਖਾਉਣ ਲਈ।',
      AppLanguage.odia: 'ଆପଣଙ୍କ ଅଞ୍ଚଳ ଉପଯୋଗୀ ବିଷୟବସ୍ତୁ ଦେଖାଇବା ପାଇଁ।',
      AppLanguage.assamese: 'আপোনাৰ অঞ্চলৰ উপযোগী সমল দেখুৱাবলৈ।',
      AppLanguage.konkani: 'तुमच्या वाठाराक उपेगाचो आशय दाखोवपाक.',
      AppLanguage.nepali: 'तपाईंको क्षेत्रसँग सान्दर्भिक सामग्री देखाउनका लागि।',
      AppLanguage.meitei: 'Nang-gi area ga channaba content utnaba.',
      AppLanguage.mizo: 'I awmna hmun mil thil tih chhuah nan.',
      AppLanguage.kashmiri: 'تہٕنٛدِ علاقَس سٟتۍ متعلِق مو مواد ہاونہٕ خٲطرٕ।',
      AppLanguage.ladakhi: 'ཁྱེད་རང་གི་ས་ཁུལ་དང་འབྲེལ་བའི་ནང་དོན་སྟོན་པར།',
    },
    'footerHint': {
      AppLanguage.telugu: 'తర్వాత settings లో కూడా ఇవ్వొచ్చు.',
      AppLanguage.english: 'You can allow them later in settings.',
      AppLanguage.hindi: 'आप इन्हें बाद में सेटिंग्स में भी अनुमति दे सकते हैं।',
      AppLanguage.tamil: 'அமைப்புகளில் பின்னர் இவற்றை அனுமதிக்கலாம்.',
      AppLanguage.kannada: 'ನೀವು ಇವುಗಳನ್ನು ನಂತರ ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿಯೂ ಅನುಮತಿಸಬಹುದು.',
      AppLanguage.malayalam: 'സെറ്റിംഗ്സിൽ നിങ്ങൾക്ക് പിന്നീട് ഇവ അനുവദിക്കാം.',
      AppLanguage.marathi: 'तुम्ही नंतर सेटिंग्जमध्ये देखील परवानगी देऊ शकता.',
      AppLanguage.gujarati: 'તમે પછીથી સેટિંગ્સમાં પણ મંજૂરી આપી શકો છો.',
      AppLanguage.bengali: 'আপনি পরে সেটিংসে গিয়েও অনুমতি দিতে পারেন।',
      AppLanguage.punjabi: 'ਤੁਸੀਂ ਬਾਅਦ ਵਿੱਚ ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਵੀ ਇਜਾਜ਼ਤ ਦੇ ਸਕਦੇ ਹੋ।',
      AppLanguage.odia: 'ଆପଣ ଏହାକୁ ପରେ ସେଟିଙ୍ଗରେ ମଧ୍ୟ ଅନୁମତି ଦେଇପାରିବେ।',
      AppLanguage.assamese: 'আপুনি পিছত ছেটিংছতো অনুমতি দিব পাৰিব।',
      AppLanguage.konkani: 'उपरांत मांडणींत (Settings) वचूनय तुमी परवांग्यो दिवंक शकतात.',
      AppLanguage.nepali: 'तपाईं पछि सेटिङहरूमा पनि अनुमति दिन सक्नुहुन्छ।',
      AppLanguage.meitei: 'Matungda settings ta hairaga allow touba yai.',
      AppLanguage.mizo: 'A hnuah settings aṭangin i la phal thei ang.',
      AppLanguage.kashmiri: 'تۄہہِ ہیکیو پتہٕ ترتیباتس (Settings) منز تہِ اِجازتھ دِتھ।',
      AppLanguage.ladakhi: 'རྗེས་སུ་སྒྲིག་བཀོད་ནས་ཀྱང་ཆོག་མཆན་སྤྲོད་ཆོག',
    },
  };

  String _get(String key) {
    final entry = _dict[key];
    if (entry != null && entry.containsKey(language)) {
      return entry[language]!;
    }
    return entry?[AppLanguage.english] ?? '';
  }

  String get title => _get('title');
  String get subtitle => _get('subtitle');
  String get photosSubtitle => _get('photosSubtitle');
  String get cameraSubtitle => _get('cameraSubtitle');
  String get notificationsSubtitle => _get('notificationsSubtitle');
  String get locationSubtitle => _get('locationSubtitle');
  String get footerHint => _get('footerHint');
}
