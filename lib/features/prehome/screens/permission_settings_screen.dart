import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen>
    with WidgetsBindingObserver, AppLanguageStateMixin {
  final PermissionService _permissionService = PermissionService();

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
  bool _loading = true;
  bool _openingSettings = false;
  bool _loadUsedFallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _snapshot = _permissionService.defaultSnapshot();
    _loadSnapshot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSnapshot();
    }
  }

  Future<void> _loadSnapshot() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final PermissionSnapshot snapshot = await _permissionService
          .getSnapshot()
          .timeout(
            const Duration(seconds: 4),
            onTimeout: _permissionService.defaultSnapshot,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _loadUsedFallback = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = _permissionService.defaultSnapshot();
        _loading = false;
        _loadUsedFallback = true;
      });
    }
  }

  Future<void> _requestPermission(AppPermissionType type) async {
    final PermissionStatus status = await _permissionService.requestSingle(
      type,
    );
    if (!mounted) {
      return;
    }
    await _loadSnapshot();
    if (!mounted) {
      return;
    }

    final _PermissionCopy copy = _copy(context);
    String message;
    if (status.isGranted || status.isLimited) {
      message = copy.permissionGranted(type);
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      message = copy.permissionNeedsSettings(type);
    } else {
      message = copy.permissionDenied(type);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  Future<void> _openSettings() async {
    setState(() => _openingSettings = true);
    final bool opened = await _permissionService.openSettings();
    if (!mounted) {
      return;
    }
    setState(() => _openingSettings = false);

    final _PermissionCopy copy = _copy(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(
        AppSnackBar.build(
          content: Text(opened ? copy.settingsOpened : copy.settingsOpenFailed),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final _PermissionCopy copy = _copy(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          copy.settingsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadSnapshot,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: <Widget>[
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (_loadUsedFallback)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    copy.fallbackInfo,
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              _PermissionTile(
                icon: Icons.photo_library_outlined,
                title: context.strings.photosGallery,
                statusLabel: copy.statusLabel(_snapshot.photos),
                statusColor: copy.statusColor(_snapshot.photos),
                actionLabel: copy.actionLabel(_snapshot.photos),
                onAction: () => _handlePermissionAction(_snapshot.photos),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.photo_camera_outlined,
                title: context.strings.localized(
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
                statusLabel: copy.statusLabel(_snapshot.camera),
                statusColor: copy.statusColor(_snapshot.camera),
                actionLabel: copy.actionLabel(_snapshot.camera),
                onAction: () => _handlePermissionAction(_snapshot.camera),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.notifications_none_rounded,
                title: context.strings.notifications,
                statusLabel: copy.statusLabel(_snapshot.notifications),
                statusColor: copy.statusColor(_snapshot.notifications),
                actionLabel: copy.actionLabel(_snapshot.notifications),
                onAction: () =>
                    _handlePermissionAction(_snapshot.notifications),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.location_on_outlined,
                title: context.strings.localized(
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
                statusLabel: copy.statusLabel(_snapshot.location),
                statusColor: copy.statusColor(_snapshot.location),
                actionLabel: copy.actionLabel(_snapshot.location),
                onAction: () => _handlePermissionAction(_snapshot.location),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openingSettings ? null : _openSettings,
                icon: _openingSettings
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.settings_outlined),
                label: Text(copy.openSettingsLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePermissionAction(AppPermissionState state) async {
    if (state.needsSettings) {
      await _openSettings();
      return;
    }
    if (state.isGranted) {
      await _loadSnapshot();
      return;
    }
    await _requestPermission(state.type);
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Icon(icon, color: const Color(0xFF334155), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          statusLabel,
          style: TextStyle(
            fontSize: 13.5,
            color: statusColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
    );
  }
}

class _PermissionCopy {
  const _PermissionCopy(this.language);

  final AppLanguage language;

  String get settingsTitle =>
      _localized(telugu: 'అనుమతులు', english: 'Permissions');

  String get openSettingsLabel => _localized(
    telugu: 'యాప్ సెట్టింగ్స్ తెరవండి',
    english: 'Open App Settings',
  );

  String get fallbackInfo => _localized(
    telugu: 'స్టేటస్ రిఫ్రెష్ కాలేదు. కిందికి లాగి మళ్లీ ప్రయత్నించండి.',
    english: 'Could not refresh status. Pull down to retry.',
  );

  String get settingsOpened => _localized(
    telugu: 'యాప్ సెట్టింగ్స్ తెరుచుకున్నాయి.',
    english: 'App settings opened.',
  );

  String get settingsOpenFailed => _localized(
    telugu: 'సెట్టింగ్స్ తెరవలేకపోయాం. ఇంకోసారి ప్రయత్నించండి.',
    english: 'Could not open settings. Please try again.',
  );

  String permissionGranted(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu: 'ఫోటోలు అనుమతి ఇచ్చారు.',
      english: 'Photos access granted.',
    ),
    AppPermissionType.camera => _localized(
      telugu: 'కెమెరా అనుమతి ఇచ్చారు.',
      english: 'Camera access granted.',
    ),
    AppPermissionType.notifications => _localized(
      telugu: 'నోటిఫికేషన్ అనుమతి ఇచ్చారు.',
      english: 'Notifications access granted.',
    ),
    AppPermissionType.location => _localized(
      telugu: 'లొకేషన్ అనుమతి ఇచ్చారు.',
      english: 'Location access granted.',
    ),
  };

  String permissionDenied(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu: 'ఫోటోలు అనుమతి ఆఫ్‌లో ఉంది.',
      english: 'Photos access is off.',
    ),
    AppPermissionType.camera => _localized(
      telugu: 'కెమెరా అనుమతి ఆఫ్‌లో ఉంది.',
      english: 'Camera access is off.',
    ),
    AppPermissionType.notifications => _localized(
      telugu: 'నోటిఫికేషన్లు ఆఫ్‌లో ఉన్నాయి.',
      english: 'Notifications are off.',
    ),
    AppPermissionType.location => _localized(
      telugu: 'లొకేషన్ అనుమతి ఆఫ్‌లో ఉంది.',
      english: 'Location access is off.',
    ),
  };

  String permissionNeedsSettings(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu: 'సెట్టింగ్స్‌లో ఫోటోలు అనుమతించండి.',
      english: 'Allow photos from settings.',
    ),
    AppPermissionType.camera => _localized(
      telugu: 'సెట్టింగ్స్‌లో కెమెరా అనుమతించండి.',
      english: 'Allow camera from settings.',
    ),
    AppPermissionType.notifications => _localized(
      telugu: 'సెట్టింగ్స్‌లో నోటిఫికేషన్లు అనుమతించండి.',
      english: 'Allow notifications from settings.',
    ),
    AppPermissionType.location => _localized(
      telugu: 'సెట్టింగ్స్‌లో లొకేషన్ అనుమతించండి.',
      english: 'Allow location from settings.',
    ),
  };

  String statusLabel(AppPermissionState state) {
    if (state.isGranted) {
      return _localized(telugu: 'అనుమతించారు', english: 'Allowed');
    }
    if (state.needsSettings) {
      return _localized(
        telugu: 'సెట్టింగ్స్‌లో అనుమతించండి',
        english: 'Allow from Settings',
      );
    }
    return _localized(telugu: 'అనుమతి లేదు', english: 'Not allowed');
  }

  Color statusColor(AppPermissionState state) {
    if (state.isGranted) {
      return const Color(0xFF15803D);
    }
    if (state.needsSettings) {
      return const Color(0xFFB45309);
    }
    return const Color(0xFFB91C1C);
  }

  String actionLabel(AppPermissionState state) {
    if (state.needsSettings || state.isGranted) {
      return _localized(telugu: 'చూడు', english: 'Check');
    }
    return _localized(telugu: 'అనుమతించు', english: 'Allow');
  }

  static const Map<String, Map<AppLanguage, String>> _permDict = {
    'Permissions': {
      AppLanguage.hindi: 'अनुमतियाँ',
      AppLanguage.tamil: 'அனுமதிகள்',
      AppLanguage.kannada: 'ಅನುಮತಿಗಳು',
      AppLanguage.malayalam: 'അനുമതികൾ',
      AppLanguage.marathi: 'परवानग्या',
      AppLanguage.gujarati: 'પરવાનગીઓ',
      AppLanguage.bengali: 'অনুমতিসমূহ',
      AppLanguage.punjabi: 'ਇਜਾਜ਼ਤਾਂ',
      AppLanguage.odia: 'ଅନୁମତି',
      AppLanguage.assamese: 'অনুমতিসমূহ',
      AppLanguage.konkani: 'परवानग्यो',
      AppLanguage.nepali: 'अनुमतिहरू',
      AppLanguage.meitei: 'Permissions',
      AppLanguage.mizo: 'Phalna',
      AppLanguage.kashmiri: 'اِجازتھ',
      AppLanguage.ladakhi: 'ཆོག་མཆན།',
    },
    'Open App Settings': {
      AppLanguage.hindi: 'ऐप सेटिंग्स खोलें',
      AppLanguage.tamil: 'செயலி அமைப்புகளைத் திறக்கவும்',
      AppLanguage.kannada: 'ಆಪ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ',
      AppLanguage.malayalam: 'ആപ്പ് ക്രമീകരണങ്ങൾ തുറക്കുക',
      AppLanguage.marathi: 'अ‍ॅप सेटिंग्ज उघडा',
      AppLanguage.gujarati: 'એપ્લિકેશન સેટિંગ્સ ખોલો',
      AppLanguage.bengali: 'অ্যাপ সেটিংস খুলুন',
      AppLanguage.punjabi: 'ਐਪ ਸੈਟਿੰਗਾਂ ਖੋਲ੍ਹੋ',
      AppLanguage.odia: 'ଆପ୍ ସେଟିଙ୍ଗ୍ ଖୋଲନ୍ତୁ',
      AppLanguage.assamese: 'এপ ছেটিং খোলক',
      AppLanguage.konkani: 'अ‍ॅप मांडणी उकती करात',
      AppLanguage.nepali: 'एप सेटिङहरू खोल्नुहोस्',
      AppLanguage.meitei: 'App settings hangdok-u',
      AppLanguage.mizo: 'App settings hawng rawh',
      AppLanguage.kashmiri: 'ایپ ترتیبات کٔریو اوپن',
      AppLanguage.ladakhi: 'App སྒྲིག་བཀོད་ཁ་ཕྱེད།',
    },
    'Could not refresh status. Pull down to retry.': {
      AppLanguage.hindi: 'स्थिति रीफ़्रेश नहीं हो सकी। पुनः प्रयास करने के लिए नीचे खींचें।',
      AppLanguage.tamil: 'நிலையைப் புதுப்பிக்க முடியவில்லை. மீண்டும் முயற்சிக்க கீழே இழுக்கவும்.',
      AppLanguage.kannada: 'ಸ್ಥಿತಿಯನ್ನು ರಿಫ್ರೆಶ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಮರುಪ್ರಯತ್ನಿಸಲು ಕೆಳಗೆ ಎಳೆಯಿರಿ.',
      AppLanguage.malayalam: 'നില പുതുക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കാൻ താഴേക്ക് വലിക്കുക.',
      AppLanguage.marathi: 'स्थिती रिफ्रेश करता आली नाही. पुन्हा प्रयत्न करण्यासाठी खाली ओढा.',
      AppLanguage.gujarati: 'સ્થિતિ રિફ્રેશ કરી શકાઈ નથી. ફરી પ્રયાસ કરવા માટે નીચે ખેંચો.',
      AppLanguage.bengali: 'স্থিতি রিফ্রেশ করা যায়নি। পুনরায় চেষ্টা করতে নিচে টানুন।',
      AppLanguage.punjabi: 'ਸਥਿਤੀ ਤਾਜ਼ਾ ਨਹੀਂ ਹੋ ਸਕੀ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰਨ ਲਈ ਹੇਠਾਂ ਖਿੱਚੋ।',
      AppLanguage.odia: 'ସ୍ଥିତି ରିଫ୍ରେସ୍ ହୋଇପାରିଲା ନାହିଁ। ପୁଣି ଚେଷ୍ଟା କରିବାକୁ ତଳକୁ ଟାଣନ୍ତୁ।',
      AppLanguage.assamese: 'স্থিতি সতেজ কৰিব পৰা নগ’ল। পুনৰ চেষ্টা কৰিবলৈ তললৈ টানক।',
      AppLanguage.konkani: 'स्थिती ताजी करूंक जमली ना. परत प्रयत्न करपाक सकयल ओडात.',
      AppLanguage.nepali: 'स्थिति रिफ्रेस गर्न सकिएन। पुन: प्रयास गर्न तल तान्नुहोस्।',
      AppLanguage.meitei: 'Status refresh touba ngamde. Hanna hotnanaba chingthabiyu.',
      AppLanguage.mizo: 'Status tihtharlam theih a ni lo. Ti nawn leh turin hnuk hniam rawh.',
      AppLanguage.kashmiri: 'حیثیت ہیکہِ نہٕ ریفریش کٔرِتھ۔ دۆبارٕ کوشِش خٲطرٕ کٔریو بۄن کُن پُل۔',
      AppLanguage.ladakhi: 'གནས་སྟངས་གསར་བཟོ་མ་ཐུབ། འོག་ཏུ་འཐེན་ནས་ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
    },
    'App settings opened.': {
      AppLanguage.hindi: 'ऐप सेटिंग्स खुल गई।',
      AppLanguage.tamil: 'செயலி அமைப்புகள் திறக்கப்பட்டன.',
      AppLanguage.kannada: 'ಆಪ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳು ತೆರೆದಿವೆ.',
      AppLanguage.malayalam: 'ആപ്പ് ക്രമീകരണങ്ങൾ തുറന്നു.',
      AppLanguage.marathi: 'अ‍ॅप सेटिंग्ज उघडल्या.',
      AppLanguage.gujarati: 'એપ્લિકેશન સેટિંગ્સ ખોલી.',
      AppLanguage.bengali: 'অ্যাপ সেটিংস খোলা হয়েছে।',
      AppLanguage.punjabi: 'ਐਪ ਸੈਟਿੰਗਾਂ ਖੁੱਲ੍ਹ ਗਈਆਂ।',
      AppLanguage.odia: 'ଆପ୍ ସେଟିଙ୍ଗ୍ ଖୋଲିଗଲା।',
      AppLanguage.assamese: 'এপ ছেটিং খোলা হ’ল।',
      AppLanguage.konkani: 'अ‍ॅप मांडणी उकती जाली.',
      AppLanguage.nepali: 'एप सेटिङहरू खोलियो।',
      AppLanguage.meitei: 'App settings hangdokkhraba.',
      AppLanguage.mizo: 'App settings hawn a ni.',
      AppLanguage.kashmiri: 'ایپ ترتیبات آو اوپن کرنہٕ۔',
      AppLanguage.ladakhi: 'App སྒྲིག་བཀོད་ཁ་ཕྱེ་ཚར།',
    },
    'Could not open settings. Please try again.': {
      AppLanguage.hindi: 'सेटिंग्स नहीं खुलीं। कृपया पुनः प्रयास करें।',
      AppLanguage.tamil: 'அமைப்புகளைத் திறக்க முடியவில்லை. மீண்டும் முயல்க.',
      AppLanguage.kannada: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      AppLanguage.malayalam: 'ക്രമീകരണങ്ങൾ തുറക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കുക.',
      AppLanguage.marathi: 'सेटिंग्ज उघडता आल्या नाहीत. कृपया पुन्हा प्रयत्न करा.',
      AppLanguage.gujarati: 'સેટિંગ્સ ખોલી શકાઈ નથી. ફરી પ્રયાસ કરો.',
      AppLanguage.bengali: 'সেটিংস খোলা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
      AppLanguage.punjabi: 'ਸੈਟਿੰਗਾਂ ਨਹੀਂ ਖੁੱਲ੍ਹ ਸਕੀਆਂ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      AppLanguage.odia: 'ସେଟିଙ୍ଗ୍ ଖୋଲିପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
      AppLanguage.assamese: 'ছেটিং খোল খাব নোৱাৰিলে। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      AppLanguage.konkani: 'मांडणी उकती जाली ना. उपकार करून परत प्रयत्न करात.',
      AppLanguage.nepali: 'सेटिङहरू खोल्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
      AppLanguage.meitei: 'Settings hangdokpa ngamde. Amuk hanna hotnabiyu.',
      AppLanguage.mizo: 'Settings hawng thei lo. Khawngaihin ti nawn leh rawh.',
      AppLanguage.kashmiri: 'ترتیبات ہیکہِ نہٕ کھٔلِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
      AppLanguage.ladakhi: 'སྒྲིག་བཀོད་ཁ་འབྱེད་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
    },
    'Photos access granted.': {
      AppLanguage.hindi: 'फ़ोटो अनुमति दी गई।',
      AppLanguage.tamil: 'புகைப்பட அனுமதி வழங்கப்பட்டது.',
      AppLanguage.kannada: 'ಫೋಟೋಗಳ ಪ್ರವೇಶ ನೀಡಲಾಗಿದೆ.',
      AppLanguage.malayalam: 'ഫോട്ടോ അനുമതി നൽകി.',
      AppLanguage.marathi: 'फोटो परवानगी दिली.',
      AppLanguage.gujarati: 'ફોટાની પરવાનગી અપાઈ.',
      AppLanguage.bengali: 'ফটো ব্যবহারের অনুমতি দেওয়া হয়েছে।',
      AppLanguage.punjabi: 'ਫੋਟੋਆਂ ਦੀ ਇਜਾਜ਼ਤ ਦਿੱਤੀ ਗਈ।',
      AppLanguage.odia: 'ଫଟୋ ଅନୁମତି ଦିଆଗଲା।',
      AppLanguage.assamese: 'ফটোৰ অনুমতি দিয়া হ’ল।',
      AppLanguage.konkani: 'फोटो परवांगी दिली.',
      AppLanguage.nepali: 'फोटो अनुमति दिइयो।',
      AppLanguage.meitei: 'Photos access granted.',
      AppLanguage.mizo: 'Thlalak phalna pek a ni.',
      AppLanguage.kashmiri: 'فوٹو اِجازتھ آو دِنہٕ۔',
      AppLanguage.ladakhi: 'པར་གྱི་ཆོག་མཆན་སྤྲད་ཚར།',
    },
    'Camera access granted.': {
      AppLanguage.hindi: 'कैमरा अनुमति दी गई।',
      AppLanguage.tamil: 'கேமரா அனுமதி வழங்கப்பட்டது.',
      AppLanguage.kannada: 'ಕ್ಯಾಮೆರಾ ಪ್ರವೇಶ ನೀಡಲಾಗಿದೆ.',
      AppLanguage.malayalam: 'ക്യാമറ അനുമതി നൽകി.',
      AppLanguage.marathi: 'कॅमेरा परवानगी दिली.',
      AppLanguage.gujarati: 'કેમેરાની પરવાનગી અપાઈ.',
      AppLanguage.bengali: 'ক্যামেরা ব্যবহারের অনুমতি দেওয়া হয়েছে।',
      AppLanguage.punjabi: 'ਕੈਮਰਾ ਇਜਾਜ਼ਤ ਦਿੱਤੀ ਗਈ।',
      AppLanguage.odia: 'କ୍ୟାମେରା ଅନୁମତି ଦିଆଗଲା।',
      AppLanguage.assamese: 'কেমেৰাৰ অনুমতি দিয়া হ’ল।',
      AppLanguage.konkani: 'कॅमेरा परवांगी दिली.',
      AppLanguage.nepali: 'क्यामेरा अनुमति दिइयो।',
      AppLanguage.meitei: 'Camera access granted.',
      AppLanguage.mizo: 'Camera phalna pek a ni.',
      AppLanguage.kashmiri: 'کیمرا اِجازتھ آو دِنہٕ۔',
      AppLanguage.ladakhi: 'པར་ཆས་ཆོག་མཆན་སྤྲད་ཚར།',
    },
    'Notifications access granted.': {
      AppLanguage.hindi: 'अधिसूचना अनुमति दी गई।',
      AppLanguage.tamil: 'அறிவிப்பு அனுமதி வழங்கப்பட்டது.',
      AppLanguage.kannada: 'ಅಧಿಸೂಚನೆ ಪ್ರವೇಶ ನೀಡಲಾಗಿದೆ.',
      AppLanguage.malayalam: 'അറിയിപ്പ് അനുമതി നൽകി.',
      AppLanguage.marathi: 'सूचना परवानगी दिली.',
      AppLanguage.gujarati: 'સૂચનાની પરવાનગી અપાઈ.',
      AppLanguage.bengali: 'বিজ্ঞপ্তি ব্যবহারের অনুমতি দেওয়া হয়েছে।',
      AppLanguage.punjabi: 'ਸੂਚਨਾ ਇਜਾਜ਼ਤ ਦਿੱਤੀ ਗਈ।',
      AppLanguage.odia: 'ବିଜ୍ଞପ୍ତି ଅନୁମତି ଦିଆଗଲା।',
      AppLanguage.assamese: 'অধিসূচনাৰ অনুমতি দিয়া হ’ল।',
      AppLanguage.konkani: 'सूचना परवांगी दिली.',
      AppLanguage.nepali: 'सूचना अनुमति दिइयो।',
      AppLanguage.meitei: 'Notifications access granted.',
      AppLanguage.mizo: 'Hriattirna phalna pek a ni.',
      AppLanguage.kashmiri: 'اطلاع اِجازتھ آو دِنہٕ۔',
      AppLanguage.ladakhi: 'བརྡ་ཐོའི་ཆོག་མཆན་སྤྲད་ཚར།',
    },
    'Location access granted.': {
      AppLanguage.hindi: 'स्थान अनुमति दी गई।',
      AppLanguage.tamil: 'இருப்பிட அனுமதி வழங்கப்பட்டது.',
      AppLanguage.kannada: 'ಸ್ಥಳ ಪ್ರವೇಶ ನೀಡಲಾಗಿದೆ.',
      AppLanguage.malayalam: 'ലൊക്കേഷൻ അനുമതി നൽകി.',
      AppLanguage.marathi: 'स्थान परवानगी दिली.',
      AppLanguage.gujarati: 'સ્થાનની પરવાનગી અપાઈ.',
      AppLanguage.bengali: 'অবস্থান ব্যবহারের অনুমতি দেওয়া হয়েছে।',
      AppLanguage.punjabi: 'ਟਿਕਾਣਾ ਇਜਾਜ਼ਤ ਦਿੱਤੀ ਗਈ।',
      AppLanguage.odia: 'ସ୍ଥାନ ଅନୁମତି ଦିଆଗଲା।',
      AppLanguage.assamese: 'স্থানৰ অনুমতি দিয়া হ’ল।',
      AppLanguage.konkani: 'सुवात परवांगी दिली.',
      AppLanguage.nepali: 'स्थान अनुमति दिइयो।',
      AppLanguage.meitei: 'Location access granted.',
      AppLanguage.mizo: 'Hmun awmna phalna pek a ni.',
      AppLanguage.kashmiri: 'جاے اِجازتھ آو دِنہٕ۔',
      AppLanguage.ladakhi: 'གནས་ཡུལ་ཆོག་མཆན་སྤྲད་ཚར།',
    },
    'Photos access is off.': {
      AppLanguage.hindi: 'फ़ोटो एक्सेस बंद है।',
      AppLanguage.tamil: 'புகைப்பட அணுகல் முடக்கப்பட்டுள்ளது.',
      AppLanguage.kannada: 'ಫೋಟೋಗಳ ಪ್ರವೇಶ ಆಫ್ ಆಗಿದೆ.',
      AppLanguage.malayalam: 'ഫോട്ടോ ആക്‌സസ് ഓഫാണ്.',
      AppLanguage.marathi: 'फोटो अ‍ॅक्सेस बंद आहे.',
      AppLanguage.gujarati: 'ફોટા ઍક્સેસ બંધ છે.',
      AppLanguage.bengali: 'ফটো অ্যাক্সেস বন্ধ রয়েছে।',
      AppLanguage.punjabi: 'ਫੋਟੋਆਂ ਦੀ ਪਹੁੰਚ ਬੰਦ ਹੈ।',
      AppLanguage.odia: 'ଫଟୋ ପ୍ରବେଶ ବନ୍ଦ ଅଛି।',
      AppLanguage.assamese: 'ফটো প্ৰৱেশাধিকাৰ বন্ধ আছে।',
      AppLanguage.konkani: 'फोटो अ‍ॅक्सेस बंद आसा.',
      AppLanguage.nepali: 'फोटो पहुँच बन्द छ।',
      AppLanguage.meitei: 'Photos access is off.',
      AppLanguage.mizo: 'Thlalak en theihna a inhawng lo.',
      AppLanguage.kashmiri: 'فوٹو اِجازتھ چھُ بند۔',
      AppLanguage.ladakhi: 'པར་གྱི་ཆོག་མཆན་བཀག་ཡོད།',
    },
    'Camera access is off.': {
      AppLanguage.hindi: 'कैमरा एक्सेस बंद है।',
      AppLanguage.tamil: 'கேமரா அணுகல் முடக்கப்பட்டுள்ளது.',
      AppLanguage.kannada: 'ಕ್ಯಾಮೆರಾ ಪ್ರವೇಶ ಆಫ್ ಆಗಿದೆ.',
      AppLanguage.malayalam: 'ക്യാമറ ആക്‌സസ് ഓഫാണ്.',
      AppLanguage.marathi: 'कॅमेरा अ‍ॅक्सेस बंद आहे.',
      AppLanguage.gujarati: 'કેમેરા ઍક્સેસ બંધ છે.',
      AppLanguage.bengali: 'ক্যামেরা অ্যাক্সেস বন্ধ রয়েছে।',
      AppLanguage.punjabi: 'ਕੈਮਰਾ ਪਹੁੰਚ ਬੰਦ ਹੈ।',
      AppLanguage.odia: 'କ୍ୟାମେରା ପ୍ରବେଶ ବନ୍ଦ ଅଛି।',
      AppLanguage.assamese: 'কেমেৰা প্ৰৱেশাধিকাৰ বন্ধ আছে।',
      AppLanguage.konkani: 'कॅमेरा अ‍ॅक्सेस बंद आसा.',
      AppLanguage.nepali: 'क्यामेरा पहुँच बन्द छ।',
      AppLanguage.meitei: 'Camera access is off.',
      AppLanguage.mizo: 'Camera en theihna a inhawng lo.',
      AppLanguage.kashmiri: 'کیمرا اِجازتھ چھُ بند۔',
      AppLanguage.ladakhi: 'པར་ཆས་ཆོག་མཆན་བཀག་ཡོད།',
    },
    'Notifications are off.': {
      AppLanguage.hindi: 'सूचनाएं बंद हैं।',
      AppLanguage.tamil: 'அறிவிப்புகள் முடக்கப்பட்டுள்ளன.',
      AppLanguage.kannada: 'ಅಧಿಸೂಚನೆಗಳು ಆಫ್ ಆಗಿವೆ.',
      AppLanguage.malayalam: 'അറിയിപ്പുകൾ ഓഫാണ്.',
      AppLanguage.marathi: 'सूचना बंद आहेत.',
      AppLanguage.gujarati: 'સૂચનાઓ બંધ છે.',
      AppLanguage.bengali: 'বিজ্ঞপ্তিগুলি বন্ধ রয়েছে।',
      AppLanguage.punjabi: 'ਸੂਚਨਾਵਾਂ ਬੰਦ ਹਨ।',
      AppLanguage.odia: 'ବିଜ୍ଞପ୍ତି ବନ୍ଦ ଅଛି।',
      AppLanguage.assamese: 'অধিসূচনাসমূহ বন্ধ আছে।',
      AppLanguage.konkani: 'सूचना बंद आसात.',
      AppLanguage.nepali: 'सूचनाहरू बन्द छन्।',
      AppLanguage.meitei: 'Notifications are off.',
      AppLanguage.mizo: 'Hriattirna a inhawng lo.',
      AppLanguage.kashmiri: 'اطلاع چھِ بند۔',
      AppLanguage.ladakhi: 'བརྡ་ཐོ་བཀག་ཡོད།',
    },
    'Location access is off.': {
      AppLanguage.hindi: 'स्थान एक्सेस बंद है।',
      AppLanguage.tamil: 'இருப்பிட அணுகல் முடக்கப்பட்டுள்ளது.',
      AppLanguage.kannada: 'ಸ್ಥಳ ಪ್ರವೇಶ ಆಫ್ ಆಗಿದೆ.',
      AppLanguage.malayalam: 'ലൊക്കേഷൻ ആക്‌സസ് ഓഫാണ്.',
      AppLanguage.marathi: 'स्थान अ‍ॅक्सेस बंद आहे.',
      AppLanguage.gujarati: 'સ્થાન ઍક્સેસ બંધ છે.',
      AppLanguage.bengali: 'অবস্থান অ্যাক্সেস বন্ধ রয়েছে।',
      AppLanguage.punjabi: 'ਟਿਕਾਣਾ ਪਹੁੰਚ ਬੰਦ ਹੈ।',
      AppLanguage.odia: 'ସ୍ଥାନ ପ୍ରବେଶ ବନ୍ଦ ଅଛି।',
      AppLanguage.assamese: 'স্থান প্ৰৱেশাধিকাৰ বন্ধ আছে।',
      AppLanguage.konkani: 'सुवात अ‍ॅक्सेस बंद आसा.',
      AppLanguage.nepali: 'स्थान पहुँच बन्द छ।',
      AppLanguage.meitei: 'Location access is off.',
      AppLanguage.mizo: 'Hmun awmna a inhawng lo.',
      AppLanguage.kashmiri: 'جاے اِجازتھ چھُ بند۔',
      AppLanguage.ladakhi: 'གནས་ཡུལ་ཆོག་མཆན་བཀག་ཡོད།',
    },
    'Allow photos from settings.': {
      AppLanguage.hindi: 'सेटिंग्स से फ़ोटो की अनुमति दें।',
      AppLanguage.tamil: 'அமைப்புகளில் புகைப்படங்களை அனுமதிக்கவும்.',
      AppLanguage.kannada: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳಿಂದ ಫೋಟೋಗಳನ್ನು ಅನುಮತಿಸಿ.',
      AppLanguage.malayalam: 'ക്രമീകരണങ്ങളിൽ നിന്ന് ഫോട്ടോകൾ അനുവദിക്കുക.',
      AppLanguage.marathi: 'सेटिंग्जमधून फोटोंना अनुमती द्या.',
      AppLanguage.gujarati: 'સેટિંગ્સમાંથી ફોટાને મંજૂરી આપો.',
      AppLanguage.bengali: 'সেটিংস থেকে ফটো ব্যবহারের অনুমতি দিন।',
      AppLanguage.punjabi: 'ਸੈਟਿੰਗਾਂ ਤੋਂ ਫੋਟੋਆਂ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ।',
      AppLanguage.odia: 'ସେଟିଙ୍ଗରୁ ଫଟୋ ଅନୁମତି ଦିଅନ୍ତୁ।',
      AppLanguage.assamese: 'ছেটিংছৰ পৰা ফটোৰ অনুমতি দিয়ক।',
      AppLanguage.konkani: 'मांडणींतल्याન फोटोंक परवांगी दियात.',
      AppLanguage.nepali: 'सेटिङबाट फोटोहरूलाई अनुमति दिनुहोस्।',
      AppLanguage.meitei: 'Settings tagi photos allow toubiyu.',
      AppLanguage.mizo: 'Settings aṭangin thlalak phalna pe rawh.',
      AppLanguage.kashmiri: 'ترتیبات پیٹھہٕ دیو فوٹو اِجازتھ۔',
      AppLanguage.ladakhi: 'སྒྲིག་བཀོད་ནས་པར་ཆོག་མཆན་སྤྲོད།',
    },
    'Allow camera from settings.': {
      AppLanguage.hindi: 'सेटिंग्स से कैमरा की अनुमति दें।',
      AppLanguage.tamil: 'அமைப்புகளில் கேமராவை அனுமதிக்கவும்.',
      AppLanguage.kannada: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳಿಂದ ಕ್ಯಾಮೆರಾವನ್ನು ಅನುಮತಿಸಿ.',
      AppLanguage.malayalam: 'ക്രമീകരണങ്ങളിൽ നിന്ന് ക്യാമറ അനുവദിക്കുക.',
      AppLanguage.marathi: 'सेटिंग्जमधून कॅमेऱ्याला अनुमती द्या.',
      AppLanguage.gujarati: 'સેટિંગ્સમાંથી કેમેરાને મંજૂરી આપો.',
      AppLanguage.bengali: 'সেটিংস থেকে ক্যামেরা ব্যবহারের অনুমতি দিন।',
      AppLanguage.punjabi: 'ਸੈਟਿੰਗਾਂ ਤੋਂ ਕੈਮਰੇ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ।',
      AppLanguage.odia: 'ସେଟିଙ୍ଗରୁ କ୍ୟାମେରା ଅନୁମତି ଦିଅନ୍ତୁ।',
      AppLanguage.assamese: 'ছেটিংছৰ পৰা কেমেৰাৰ অনুমতি দিয়ক।',
      AppLanguage.konkani: 'मांडणींतल्यान कॅमेऱ्याक परवांगी दियात.',
      AppLanguage.nepali: 'सेटिङबाट क्यामेरालाई अनुमति दिनुहोस्।',
      AppLanguage.meitei: 'Settings tagi camera allow toubiyu.',
      AppLanguage.mizo: 'Settings aṭangin camera phalna pe rawh.',
      AppLanguage.kashmiri: 'ترتیبات پیٹھہٕ دیو کیمرا اِجازتھ۔',
      AppLanguage.ladakhi: 'སྒྲིག་བཀོད་ནས་པར་ཆས་ཆོག་མཆན་སྤྲོད།',
    },
    'Allow notifications from settings.': {
      AppLanguage.hindi: 'सेटिंग्स से सूचनाओं की अनुमति दें।',
      AppLanguage.tamil: 'அமைப்புகளில் அறிவிப்புகளை அனுமதிக்கவும்.',
      AppLanguage.kannada: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳಿಂದ ಅಧಿಸೂಚನೆಗಳನ್ನು ಅನುಮತಿಸಿ.',
      AppLanguage.malayalam: 'ക്രമീകരണങ്ങളിൽ നിന്ന് അറിയിപ്പുകൾ അനുവദിക്കുക.',
      AppLanguage.marathi: 'सेटिंग्जमधून सूचनांना अनुमती द्या.',
      AppLanguage.gujarati: 'સેટિંગ્સમાંથી સૂચનાઓને મંજૂરી આપો.',
      AppLanguage.bengali: 'সেটিংস থেকে বিজ্ঞপ্তি ব্যবহারের অনুমতি দিন।',
      AppLanguage.punjabi: 'ਸੈਟਿੰਗਾਂ ਤੋਂ ਸੂਚਨਾਵਾਂ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ।',
      AppLanguage.odia: 'ସେଟିଙ୍ଗରୁ ବିଜ୍ଞପ୍ତି ଅନୁମତି ଦିଅନ୍ତୁ।',
      AppLanguage.assamese: 'ছেটিংছৰ পৰা অধিসূচনাৰ অনুমতি দিয়ক।',
      AppLanguage.konkani: 'मांडणींतल्यान सूचनांक परवांगी दियात.',
      AppLanguage.nepali: 'सेटिङबाट सूचनाहरूलाई अनुमति दिनुहोस्।',
      AppLanguage.meitei: 'Settings tagi notifications allow toubiyu.',
      AppLanguage.mizo: 'Settings aṭangin hriattirna phalna pe rawh.',
      AppLanguage.kashmiri: 'ترتیبات پیٹھہٕ دیو اطلاع اِجازتھ۔',
      AppLanguage.ladakhi: 'སྒྲིག་བཀོད་ནས་བརྡ་ཐོའི་ཆོག་མཆན་སྤྲོད།',
    },
    'Allow location from settings.': {
      AppLanguage.hindi: 'सेटिंग्स से स्थान की अनुमति दें।',
      AppLanguage.tamil: 'அமைப்புகளில் இருப்பிடத்தை அனுமதிக்கவும்.',
      AppLanguage.kannada: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳಿಂದ ಸ್ಥಳವನ್ನು ಅನುಮತಿಸಿ.',
      AppLanguage.malayalam: 'ക്രമീകരണങ്ങളിൽ നിന്ന് ലൊക്കേഷൻ അനുവദിക്കുക.',
      AppLanguage.marathi: 'सेटिंग्जमधून स्थानाला अनुमती द्या.',
      AppLanguage.gujarati: 'સેટિંગ્સમાંથી સ્થાનને મંજૂરી આપો.',
      AppLanguage.bengali: 'সেটিংস থেকে অবস্থান ব্যবহারের অনুমতি দিন।',
      AppLanguage.punjabi: 'ਸੈਟਿੰਗਾਂ ਤੋਂ ਟਿਕਾਣੇ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ।',
      AppLanguage.odia: 'ସେଟିଙ୍ଗରୁ ସ୍ଥାନ ଅନୁମତି ଦିଅନ୍ତୁ।',
      AppLanguage.assamese: 'ছেটিংছৰ পৰা স্থানৰ অনুমতি দিয়ক।',
      AppLanguage.konkani: 'मांडणींतल्यान सुवातेक परवांगी दियात.',
      AppLanguage.nepali: 'सेटिङबाट स्थानलाई अनुमति दिनुहोस्।',
      AppLanguage.meitei: 'Settings tagi location allow toubiyu.',
      AppLanguage.mizo: 'Settings aṭangin hmun awmna phalna pe rawh.',
      AppLanguage.kashmiri: 'ترتیبات پیٹھہٕ دیو جاے اِجازتھ۔',
      AppLanguage.ladakhi: 'སྒྲིག་བཀོད་ནས་གནས་ཡུལ་ཆོག་མཆན་སྤྲོད།',
    },
    'Allowed': {
      AppLanguage.hindi: 'स्वीकृत',
      AppLanguage.tamil: 'அனுமதிக்கப்பட்டது',
      AppLanguage.kannada: 'ಅನುಮತಿಸಲಾಗಿದೆ',
      AppLanguage.malayalam: 'അനുവദിച്ചു',
      AppLanguage.marathi: 'परवानगी दिली',
      AppLanguage.gujarati: 'મંજૂરી આપી',
      AppLanguage.bengali: 'অনুমোদিত',
      AppLanguage.punjabi: 'ਇਜਾਜ਼ਤ ਦਿੱਤੀ',
      AppLanguage.odia: 'ଅନୁମୋଦିତ',
      AppLanguage.assamese: 'অনুমোদিত',
      AppLanguage.konkani: 'परवांगी दिली',
      AppLanguage.nepali: 'स्वीकृत',
      AppLanguage.meitei: 'Allowed',
      AppLanguage.mizo: 'Phal a ni',
      AppLanguage.kashmiri: 'منظوٗر',
      AppLanguage.ladakhi: 'ཆོག་མཆན་ཐོབ།',
    },
    'Allow from Settings': {
      AppLanguage.hindi: 'सेटिंग्स से अनुमति दें',
      AppLanguage.tamil: 'அமைப்புகளில் அனுமதிக்கவும்',
      AppLanguage.kannada: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳಿಂದ ಅನುಮತಿಸಿ',
      AppLanguage.malayalam: 'ക്രമീകരണങ്ങളിൽ നിന്ന് അനുവദിക്കുക',
      AppLanguage.marathi: 'सेटिंग्जमधून अनुमती द्या',
      AppLanguage.gujarati: 'સેટિંગ્સમાંથી મંજૂરી આપો',
      AppLanguage.bengali: 'সেটিংস থেকে অনুমতি দিন',
      AppLanguage.punjabi: 'ਸੈਟਿੰਗਾਂ ਤੋਂ ਇਜਾਜ਼ਤ ਦਿਓ',
      AppLanguage.odia: 'ସେଟିଙ୍ଗରୁ ଅନୁମତି ଦିଅନ୍ତୁ',
      AppLanguage.assamese: 'ছেটিংছৰ পৰা অনুমতি দিয়ক',
      AppLanguage.konkani: 'मांडणींतल्यान परवांगी दियात',
      AppLanguage.nepali: 'सेटिङबाट अनुमति दिनुहोस्',
      AppLanguage.meitei: 'Settings tagi allow toubiyu',
      AppLanguage.mizo: 'Settings aṭangin phalna pe rawh',
      AppLanguage.kashmiri: 'ترتیبات پیٹھہٕ دیو اِجازتھ',
      AppLanguage.ladakhi: 'སྒྲིག་བཀོད་ནས་ཆོག་མཆན་སྤྲོད།',
    },
    'Not allowed': {
      AppLanguage.hindi: 'अनुमति नहीं है',
      AppLanguage.tamil: 'அனுமதிக்கப்படவில்லை',
      AppLanguage.kannada: 'ಅನುಮತಿಸಲಾಗಿಲ್ಲ',
      AppLanguage.malayalam: 'അനുവദിച്ചിട്ടില്ല',
      AppLanguage.marathi: 'परवानगी नाही',
      AppLanguage.gujarati: 'મંજૂરી નથી',
      AppLanguage.bengali: 'অনুমতি নেই',
      AppLanguage.punjabi: 'ਇਜਾਜ਼ਤ ਨਹੀਂ ਹੈ',
      AppLanguage.odia: 'ଅନୁମତି ନାହିଁ',
      AppLanguage.assamese: 'অনুমতি নাই',
      AppLanguage.konkani: 'परवांगी ना',
      AppLanguage.nepali: 'अनुमति छैन',
      AppLanguage.meitei: 'Not allowed',
      AppLanguage.mizo: 'Phal a ni lo',
      AppLanguage.kashmiri: 'اِجازتھ چھُنہٕ',
      AppLanguage.ladakhi: 'ཆོག་མཆན་མེད།',
    },
    'Check': {
      AppLanguage.hindi: 'जाँचें',
      AppLanguage.tamil: 'சரிபார்க்கவும்',
      AppLanguage.kannada: 'ಪರಿಶೀಲಿಸಿ',
      AppLanguage.malayalam: 'പരിശോധിക്കുക',
      AppLanguage.marathi: 'तपासा',
      AppLanguage.gujarati: 'તપાસો',
      AppLanguage.bengali: 'যাচাই করুন',
      AppLanguage.punjabi: 'ਜਾਂਚੋ',
      AppLanguage.odia: 'ଯାଞ୍ଚ କରନ୍ତୁ',
      AppLanguage.assamese: 'পৰীক্ষা কৰক',
      AppLanguage.konkani: 'तपासात',
      AppLanguage.nepali: 'जाँच्नुहोस्',
      AppLanguage.meitei: 'Check toubiyu',
      AppLanguage.mizo: 'Enfiah rawh',
      AppLanguage.kashmiri: 'چیک کٔریو',
      AppLanguage.ladakhi: 'བརྟག་དཔྱད་བྱོས།',
    },
    'Allow': {
      AppLanguage.hindi: 'अनुमति दें',
      AppLanguage.tamil: 'அனுமதி',
      AppLanguage.kannada: 'ಅನುಮತಿಸಿ',
      AppLanguage.malayalam: 'അനുവദിക്കുക',
      AppLanguage.marathi: 'अनुमती द्या',
      AppLanguage.gujarati: 'મંજૂરી આપો',
      AppLanguage.bengali: 'অনুমতি দিন',
      AppLanguage.punjabi: 'ਇਜਾਜ਼ਤ ਦਿਓ',
      AppLanguage.odia: 'ଅନୁମତି ଦିଅନ୍ତୁ',
      AppLanguage.assamese: 'অনুমতি দিয়ক',
      AppLanguage.konkani: 'परवांगी दियात',
      AppLanguage.nepali: 'अनुमति दिनुहोस्',
      AppLanguage.meitei: 'Allow toubiyu',
      AppLanguage.mizo: 'Phal rawh',
      AppLanguage.kashmiri: 'اِجازتھ دیو',
      AppLanguage.ladakhi: 'ཆོག་མཆན་སྤྲོད།',
    },
  };

  String _localized({required String telugu, required String english}) {
    final dict = _permDict[english];
    return AppStrings(language).localized(
      telugu: telugu,
      english: english,
      hindi: dict?[AppLanguage.hindi],
      tamil: dict?[AppLanguage.tamil],
      kannada: dict?[AppLanguage.kannada],
      malayalam: dict?[AppLanguage.malayalam],
      marathi: dict?[AppLanguage.marathi],
      gujarati: dict?[AppLanguage.gujarati],
      bengali: dict?[AppLanguage.bengali],
      punjabi: dict?[AppLanguage.punjabi],
      odia: dict?[AppLanguage.odia],
      assamese: dict?[AppLanguage.assamese],
      konkani: dict?[AppLanguage.konkani],
      nepali: dict?[AppLanguage.nepali],
      meitei: dict?[AppLanguage.meitei],
      mizo: dict?[AppLanguage.mizo],
      kashmiri: dict?[AppLanguage.kashmiri],
      ladakhi: dict?[AppLanguage.ladakhi],
    );
  }
}

_PermissionCopy _copy(BuildContext context) =>
    _PermissionCopy(context.currentLanguage);
