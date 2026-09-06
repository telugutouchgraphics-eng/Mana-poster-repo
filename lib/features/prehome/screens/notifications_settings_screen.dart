import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/notification_preferences_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen>
    with AppLanguageStateMixin {
  NotificationPreferencesSnapshot _snapshot =
      const NotificationPreferencesSnapshot.defaults();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await NotificationPreferencesService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _update(NotificationPreferencesSnapshot next) async {
    setState(() {
      _snapshot = next;
      _saving = true;
    });
    try {
      await NotificationPreferencesService.save(next);
      await NotificationService.instance.syncCurrentPreferences();
    } catch (_) {
      // Keep the optimistic toggle state, but always release the saving UI.
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _NotificationsCopy(context.currentLanguage);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: -78,
            right: -34,
            child: _NotificationOrb(size: 165, color: Color(0x1822C55E)),
          ),
          const Positioned(
            top: 145,
            left: -52,
            child: _NotificationOrb(size: 130, color: Color(0x182563EB)),
          ),
          SafeArea(
            top: false,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFFEAF2FF),
                              Color(0xFFFFFFFF),
                            ],
                          ),
                          border: Border.all(color: const Color(0xD9E3EDF6)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x100F172A),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: Color(0xFF2563EB),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              copy.cardTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              copy.cardSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF475569),
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: SwitchListTile.adaptive(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 2,
                                  ),
                                  title: Text(
                                    copy.allNotificationsTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(copy.allNotificationsSubtitle),
                                  value: _snapshot.allNotifications,
                                  onChanged: (value) {
                                    _update(
                                      _snapshot.copyWith(
                                        allNotifications: value,
                                        newPosters: value
                                            ? _snapshot.newPosters
                                            : false,
                                        offersUpdates: value
                                            ? _snapshot.offersUpdates
                                            : false,
                                        subscriptionReminders: value
                                            ? _snapshot.subscriptionReminders
                                            : false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          copy.preferencesTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE3EAF3)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x0C0F172A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            _NotificationToggleTile(
                              title: copy.newPostersTitle,
                              subtitle: copy.newPostersSubtitle,
                              enabled: _snapshot.allNotifications,
                              value: _snapshot.newPosters,
                              onChanged: (value) => _update(
                                _snapshot.copyWith(newPosters: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 18, endIndent: 18),
                            _NotificationToggleTile(
                              title: copy.offersTitle,
                              subtitle: copy.offersSubtitle,
                              enabled: _snapshot.allNotifications,
                              value: _snapshot.offersUpdates,
                              onChanged: (value) => _update(
                                _snapshot.copyWith(offersUpdates: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 18, endIndent: 18),
                            _NotificationToggleTile(
                              title: copy.subscriptionTitle,
                              subtitle: copy.subscriptionSubtitle,
                              enabled: _snapshot.allNotifications,
                              value: _snapshot.subscriptionReminders,
                              onChanged: (value) => _update(
                                _snapshot.copyWith(
                                  subscriptionReminders: value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        opacity: _saving ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Row(
                          children: <Widget>[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              copy.savingLabel,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationOrb extends StatelessWidget {
  const _NotificationOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          value: enabled && value,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _NotificationsCopy {
  const _NotificationsCopy(this.language);

  final AppLanguage language;

  String _localized({
    required String telugu,
    required String english,
    required String hindi,
    required String tamil,
    required String kannada,
    required String malayalam,
    required String marathi,
    required String gujarati,
    required String bengali,
    required String punjabi,
    required String odia,
    required String assamese,
    required String konkani,
    required String nepali,
    required String meitei,
    required String mizo,
    required String kashmiri,
    required String ladakhi,
  }) =>
      AppStrings(language).localized(
        telugu: telugu,
        english: english,
        hindi: hindi,
        tamil: tamil,
        kannada: kannada,
        malayalam: malayalam,
        marathi: marathi,
        gujarati: gujarati,
        bengali: bengali,
        punjabi: punjabi,
        odia: odia,
        assamese: assamese,
        konkani: konkani,
        nepali: nepali,
        meitei: meitei,
        mizo: mizo,
        kashmiri: kashmiri,
        ladakhi: ladakhi,
      );

  String get title => _localized(
    telugu: 'నోటిఫికేషన్ సెట్టింగ్స్',
    english: 'Notification settings',
    hindi: 'अधिसूचना सेटिंग्स',
    tamil: 'அறிவிப்பு அமைப்புகள்',
    kannada: 'ಅಧಿಸೂಚನೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    malayalam: 'അറിയിപ്പ് ക്രമീകരണങ്ങൾ',
    marathi: 'सूचना सेटिंग्ज',
    gujarati: 'સૂચના સેટિંગ્સ',
    bengali: 'বিজ্ঞপ্তি সেটিংস',
    punjabi: 'ਸੂਚਨਾ ਸੈਟਿੰਗਾਂ',
    odia: 'ବିଜ୍ଞପ୍ତି ସେଟିଙ୍ଗ୍',
    assamese: 'অধিসূচনা ছেটিংছ',
    konkani: 'सूचना मांडणी',
    nepali: 'सूचना सेटिङहरू',
    meitei: 'Notification settings',
    mizo: 'Hriattirna siamthatna',
    kashmiri: 'اطلاع ترتیبات',
    ladakhi: 'བརྡ་ཐོ་སྒྲིག་བཀོད།',
  );

  String get cardTitle => _localized(
    telugu: 'నోటిఫికేషన్ల నియంత్రణ',
    english: 'Notification controls',
    hindi: 'अधिसूचना नियंत्रण',
    tamil: 'அறிவிப்புக் கட்டுப்பாடுகள்',
    kannada: 'ಅಧಿಸೂಚನೆ ನಿಯಂತ್ರಣಗಳು',
    malayalam: 'അറിയിപ്പ് നിയന്ത്രണങ്ങൾ',
    marathi: 'सूचना नियंत्रणे',
    gujarati: 'સૂચના નિયંત્રણો',
    bengali: 'বিজ্ঞপ্তি নিয়ন্ত্রণ',
    punjabi: 'ਸੂਚਨਾ ਕੰਟਰੋਲ',
    odia: 'ବିଜ୍ଞପ୍ତି ନିୟନ୍ତ୍ରଣ',
    assamese: 'অধিসূচনা নিয়ন্ত্ৰণ',
    konkani: 'सूचना नियंत्रण',
    nepali: 'सूचना नियन्त्रणहरू',
    meitei: 'Notification controls',
    mizo: 'Hriattirna thununna',
    kashmiri: 'اطلاع کَنٹرول',
    ladakhi: 'བརྡ་ཐོ་ཚོད་འཛིན།',
  );

  String get cardSubtitle => _localized(
    telugu: 'యాప్‌లో ఏ రకం అలర్ట్లు రావాలో ఇక్కడ నుంచి నియంత్రించవచ్చు.',
    english: 'Choose which app alerts you want to receive from here.',
    hindi: 'यहाँ से चुनें कि आप कौन से ऐप अलर्ट प्राप्त करना चाहते हैं।',
    tamil: 'எந்த செயலி விழிப்பூட்டல்களைப் பெற விரும்புகிறீர்கள் என்பதை இங்கிருந்து தேர்ந்தெடுக்கவும்.',
    kannada: 'ಇಲ್ಲಿಂದ ನೀವು ಯಾವ ಆಪ್ ಎಚ್ಚರಿಕೆಗಳನ್ನು ಸ್ವೀಕರಿಸಲು ಬಯಸುತ್ತೀರಿ ಎಂಬುದನ್ನು ಆಯ್ಕೆಮಾಡಿ.',
    malayalam: 'ഏതൊക്കെ ആപ്പ് അലേർട്ടുകൾ ലഭിക്കണമെന്ന് ഇവിടെ നിന്ന് തിരഞ്ഞെടുക്കുക.',
    marathi: 'तुम्हाला कोणते अ‍ॅप अलर्ट हवे आहेत ते येथून निवडा.',
    gujarati: 'તમે અહીંથી કયા એપ્લિકેશન ચેતવણીઓ પ્રાપ્ત કરવા માંગો છો તે પસંદ કરો.',
    bengali: 'আপনি এখান থেকে কোন অ্যাপ সতর্কতা পেতে চান তা চয়ন করুন।',
    punjabi: 'ਇੱਥੋਂ ਚੁਣੋ ਕਿ ਤੁਸੀਂ ਕਿਹੜੀਆਂ ਐਪ ਚੇਤਾਵਨੀਆਂ ਪ੍ਰਾਪਤ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ।',
    odia: 'ଆପଣ ଏଠାରୁ କେଉଁ ଆପ୍ ସତର୍କତା ଗ୍ରହଣ କରିବାକୁ ଚାହାଁନ୍ତି ତାହା ବାଛନ୍ତୁ।',
    assamese: 'আপুনি ইয়াত কি কি এপ সতৰ্কবাৰ্তা পাব বিচাৰে বাছক।',
    konkani: 'तुमी हांगाच्याਨ खंयचीं अ‍ॅप शिटकावणी मेळोवंक सोदतात तें वेंचून काडात.',
    nepali: 'यहाँबाट तपाईं कुन एप अलर्टहरू प्राप्त गर्न चाहनुहुन्छ छनौट गर्नुहोस्।',
    meitei: 'Nangna aphaba app alert sing khallu.',
    mizo: 'App alert i dawn duh tur heta tang hian thlang rawh.',
    kashmiri: 'ییٚتھ پیٹھہٕ کٔریو اِنتخاب زِ تۄہہِ کیتھ پٲٹھۍ نوٹیفکیشن چھِو یژھان۔',
    ladakhi: 'འདི་ནས་ཁྱེད་ཀྱིས་བརྡ་ཐོ་གང་ལེན་འདོད་པ་འདེམས་གནང།',
  );

  String get preferencesTitle => _localized(
    telugu: 'వ్యక్తిగత ప్రాధాన్యాలు',
    english: 'Preferences',
    hindi: 'प्राथमिकताएं',
    tamil: 'விருப்பத்தேர்வுகள்',
    kannada: 'ಆದ್ಯತೆಗಳು',
    malayalam: 'മുൻഗണനകൾ',
    marathi: 'प्राधान्ये',
    gujarati: 'પસંદગીઓ',
    bengali: 'পছন্দসমূহ',
    punjabi: 'ਤਰਜੀਹਾਂ',
    odia: 'ପସନ୍ଦ',
    assamese: 'পছন্দসমূহ',
    konkani: 'प्राधान्यां',
    nepali: 'प्राथमिकताहरू',
    meitei: 'Preferences',
    mizo: 'Duhthlanna',
    kashmiri: 'ترجیحات',
    ladakhi: 'འདེམས་ཁ།',
  );

  String get allNotificationsTitle => _localized(
    telugu: 'అన్ని నోటిఫికేషన్లు',
    english: 'All notifications',
    hindi: 'सभी सूचनाएं',
    tamil: 'அனைத்து அறிவிப்புகளும்',
    kannada: 'ಎಲ್ಲಾ ಅಧಿಸೂಚನೆಗಳು',
    malayalam: 'എല്ലാ അറിയിപ്പുകളും',
    marathi: 'सर्व सूचना',
    gujarati: 'તમામ સૂચનાઓ',
    bengali: 'সমস্ত বিজ্ঞপ্তি',
    punjabi: 'ਸਾਰੀਆਂ ਸੂਚਨਾਵਾਂ',
    odia: 'ସମସ୍ତ ବିଜ୍ଞପ୍ତି',
    assamese: 'সকলো অধিসূচনা',
    konkani: 'सगळ्यो सूचना',
    nepali: 'सबै सूचनाहरू',
    meitei: 'Pumnamak notifications',
    mizo: 'Hriattirna zawng zawng',
    kashmiri: 'سٲری اطلاع',
    ladakhi: 'བརྡ་ཐོ་ཡོངས་རྫོགས།',
  );

  String get allNotificationsSubtitle => _localized(
    telugu: 'దీన్ని ఆఫ్ చేస్తే క్రింద ఉన్న అన్ని ఎంపికలు కూడా ఆగిపోతాయి.',
    english: 'Turning this off also disables the options below.',
    hindi: 'इसे बंद करने से नीचे दिए गए विकल्प भी अक्षम हो जाएंगे।',
    tamil: 'இதை அணைத்தால் கீழே உள்ள விருப்பங்களும் முடக்கப்படும்.',
    kannada: 'ಇದನ್ನು ಆಫ್ ಮಾಡುವುದರಿಂದ ಕೆಳಗಿನ ಆಯ್ಕೆಗಳೂ ನಿಷ್ಕ್ರಿಯಗೊಳ್ಳುತ್ತವೆ.',
    malayalam: 'ഇത് ഓഫാക്കുന്നത് ചുവടെയുള്ള ഓപ്ഷനുകളും പ്രവർത്തനരഹിതമാക്കും.',
    marathi: 'हे बंद केल्याने खालील पर्याय देखील अक्षम होतील.',
    gujarati: 'આને બંધ કરવાથી નીચેના વિકલ્પો પણ અક્ષમ થઈ જશે.',
    bengali: 'এটি বন্ধ করলে নীচের বিকল্পগুলিও অক্ষম হয়ে যাবে।',
    punjabi: 'ਇਸਨੂੰ ਬੰਦ ਕਰਨ ਨਾਲ ਹੇਠਾਂ ਦਿੱਤੇ ਵਿਕਲਪ ਵੀ ਅਯੋਗ ਹੋ ਜਾਣਗੇ।',
    odia: 'ଏହା ବନ୍ଦ କଲେ ନିମ୍ନ ବିକଳ୍ପଗୁଡ଼ିକ ମଧ୍ୟ ନିଷ୍କ୍ରିୟ ହୋଇଯିବ।',
    assamese: 'ইয়াক বন্ধ কৰিলে তলৰ বিকল্পসমূহো নিষ্ক্ৰিয় হৈ পৰিব।',
    konkani: 'हें बंद केल्यार सकयल दिल्ले पर्यायय बंद जातले.',
    nepali: 'यसलाई बन्द गर्नाले तलका विकल्पहरू पनि असक्षम हुनेछन्।',
    meitei: 'Masi muthatlabadi makhaa gi options sing su muthangani.',
    mizo: 'Hei hi i tihtawp chuan a hnuaia thlante pawh a tawp ang.',
    kashmiri: 'یہِ بند کرنہٕ سٟتۍ گژھن بۄنِمِہ سٲری آپشن تہِ بند۔',
    ladakhi: 'འདི་བཀག་ན་འོག་གི་འདེམས་ཁ་རྣམས་ཀྱང་འགག་འགྲོ།',
  );

  String get newPostersTitle => _localized(
    telugu: 'కొత్త పోస్టర్లు',
    english: 'New posters',
    hindi: 'नए पोस्टर',
    tamil: 'புதிய போஸ்டர்கள்',
    kannada: 'ಹೊಸ ಪೋಸ್ಟರ್‌ಗಳು',
    malayalam: 'പുതിയ പോസ്റ്ററുകൾ',
    marathi: 'नवीन पोस्टर्स',
    gujarati: 'નવા પોસ્ટરો',
    bengali: 'নতুন পোস্টার',
    punjabi: 'ਨਵੇਂ ਪੋਸਟਰ',
    odia: 'ନୂଆ ପୋଷ୍ଟର',
    assamese: 'নতুন পোষ্টাৰ',
    konkani: 'नवीं पोस्टरां',
    nepali: 'नयाँ पोस्टरहरू',
    meitei: 'Anouba posters',
    mizo: 'Poster thar',
    kashmiri: 'نٔوۍ پوسٹر',
    ladakhi: 'པੋꯁཊར་གསར་པ།',
  );

  String get newPostersSubtitle => _localized(
    telugu: 'కొత్త డిజైన్లు లేదా టెంప్లేట్లు వచ్చినప్పుడు తెలియజేస్తుంది.',
    english: 'When new templates and poster designs are available.',
    hindi: 'जब नए टेम्पलेट और पोस्टर डिज़ाइन उपलब्ध हों।',
    tamil: 'புதிய வார்ப்புருக்கள் மற்றும் போஸ்டர் வடிவமைப்புகள் கிடைக்கும் போது.',
    kannada: 'ಹೊಸ ಟೆಂಪ್ಲೇಟ್‌ಗಳು ಮತ್ತು ಪೋಸ್ಟರ್ ವಿನ್ಯಾಸಗಳು ಲಭ್ಯವಿದ್ದಾಗ.',
    malayalam: 'പുതിയ ടെംപ്ലേറ്റുകളും പോസ്റ്റർ ഡിസൈനുകളും ലഭ്യമാകുമ്പോൾ.',
    marathi: 'जेव्हा नवीन टेम्पलेट्स आणि पोस्टर डिझाइन उपलब्ध असतील.',
    gujarati: 'જ્યારે નવા નમૂનાઓ અને પોસ્ટર ડિઝાઇન ઉપલબ્ધ હોય.',
    bengali: 'যখন নতুন টেমপ্লেট এবং পোস্টার ডিজাইন উপলব্ধ হবে।',
    punjabi: 'ਜਦੋਂ ਨਵੇਂ ਟੈਂਪਲੇਟ ਅਤੇ ਪੋਸਟਰ ਡਿਜ਼ਾਈਨ ਉਪਲਬਧ ਹੋਣ।',
    odia: 'ଯେତେବେଳେ ନୂତନ ଟେମ୍ପଲେଟ୍ ଏବଂ ପୋଷ୍ଟର ଡିଜାଇନ୍ ଉପଲବ୍ଧ ହେବ।',
    assamese: 'যেতিয়া নতুন টেমপ্লেট আৰু পোষ্টাৰ ডিজাইন উপলব্ধ হ’ব।',
    konkani: 'जेन्ना नवीं टेम्पलेट्स आनी पोस्टर डिझायनां मेळटलीं.',
    nepali: 'जब नयाँ टेम्प्लेट र पोस्टर डिजाइनहरू उपलब्ध हुन्छन्।',
    meitei: 'Anouba templates amasung designs phanglakpa matamda.',
    mizo: 'Template leh design thar a awm hunah.',
    kashmiri: 'ییلہِ نٔوۍ ڈیزائن تہٕ ٹیمپلیٹ دستِیاب گژھن۔',
    ladakhi: 'དཔེ་གཞི་དང་པོ་སཊར་གསར་པ་ཡོད་དུས།',
  );

  String get offersTitle => _localized(
    telugu: 'ఆఫర్లు & అప్‌డేట్లు',
    english: 'Offers & updates',
    hindi: 'ऑफ़र और अपडेट',
    tamil: 'சலுகைகள் & புதுப்பிப்புகள்',
    kannada: 'ಆಫರ್‌ಗಳು & ಅಪ್‌ಡೇಟ್‌ಗಳು',
    malayalam: 'ഓഫറുകളും അപ്‌ഡേറ്റുകളും',
    marathi: 'ऑफर्स आणि अपडेट्स',
    gujarati: 'ઑફર્સ અને અપડેટ્સ',
    bengali: 'অফার এবং আপডেট',
    punjabi: 'ਆਫ਼ਰਾਂ ਅਤੇ ਅੱਪਡੇਟ',
    odia: 'ଅଫର୍ ଏବଂ ଅପଡେଟ୍',
    assamese: 'অফাৰ আৰু আপডেট',
    konkani: 'ऑफर्स आनी अपडेट्स',
    nepali: 'अफर तथा अपडेटहरू',
    meitei: 'Offers & updates',
    mizo: 'Offer leh update',
    kashmiri: 'آفر تہٕ اپڈیٹ',
    ladakhi: 'ཡར་རྒྱས་དང་མཁོ་སྤྲོད།',
  );

  String get offersSubtitle => _localized(
    telugu: 'ప్రత్యేక ఆఫర్లు, ప్రోమోలు, ముఖ్యమైన యాప్ అప్‌డేట్లు.',
    english: 'Special offers, promos, and important app updates.',
    hindi: 'विशेष ऑफ़र, प्रोमो और महत्वपूर्ण ऐप अपडेट।',
    tamil: 'சிறப்பு சலுகைகள், விளம்பரங்கள் மற்றும் முக்கியமான செயலி புதுப்பிப்புகள்.',
    kannada: 'ವಿಶೇಷ ಕೊಡುಗೆಗಳು, ಪ್ರೋಮೋಗಳು ಮತ್ತು ಪ್ರಮುಖ ಆಪ್ ಅಪ್‌ಡೇಟ್‌ಗಳು.',
    malayalam: 'പ്രത്യേക ഓഫറുകൾ, പ്രൊമോകൾ, പ്രധാന ആപ്പ് അപ്‌ഡേറ്റുകൾ.',
    marathi: 'विशेष ऑफर्स, प्रोमोज आणि महत्त्वाचे अ‍ॅप अपडेट्स.',
    gujarati: 'ખાસ ઑફર્સ, પ્રોમો અને મહત્વપૂર્ણ એપ્લિકેશન અપડેટ્સ.',
    bengali: 'বিশেষ অফার, প্রচার এবং গুরুত্বপূর্ণ অ্যাপ আপডেট।',
    punjabi: 'ਵਿਸ਼ੇਸ਼ ਆਫ਼ਰਾਂ, ਪ੍ਰੋਮੋ ਅਤੇ ਮਹੱਤਵਪੂਰਨ ਐਪ ਅੱਪਡੇਟ।',
    odia: 'ବିଶେଷ ଅଫର୍, ପ୍ରୋମୋ ଏବଂ ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ ଆପ୍ ଅପଡେଟ୍।',
    assamese: 'বিশেষ অফাৰ, প্ৰ’ম’ আৰু গুৰুত্বপূৰ্ণ এপ আপডেট।',
    konkani: 'खाशेल्यो ऑफर्स, प्रोमोज आनी म्हत्वाचे अ‍ॅप अपडेट्स.',
    nepali: 'विशेष अफरहरू, प्रोमोहरू, र महत्त्वपूर्ण एप अपडेटहरू।',
    meitei: 'Special offers, promos amasung app updates.',
    mizo: 'Offer bik, promo, leh app update pawimawh.',
    kashmiri: 'خاص آفر، پرومو تہٕ اہم ایپ اپڈیٹ۔',
    ladakhi: 'དམིགས་བསལ་མཁོ་སྤྲོད་དང་བཅོས་བསྒྱུར།',
  );

  String get subscriptionTitle => _localized(
    telugu: 'సబ్‌స్క్రిప్షన్ గుర్తింపులు',
    english: 'Subscription reminders',
    hindi: 'सदस्यता अनुस्मारक',
    tamil: 'சந்தா நினைவூட்டல்கள்',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಜ್ಞಾಪನೆಗಳು',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ ഓർമ്മപ്പെടുത്തലുകൾ',
    marathi: 'सदस्यता स्मरणपत्रे',
    gujarati: 'સબ્સ્ક્રિપ્શન રીમાઇન્ડર્સ',
    bengali: 'সাবস্ক্রিপশন অনুস্মারক',
    punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਰੀਮਾਈਂਡਰ',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ସ୍ମାରକୀ',
    assamese: 'গ্ৰাহকভুক্তি সোঁৱৰণী',
    konkani: 'वर्गणी यादस्तिकां',
    nepali: 'सदस्यता रिमाइन्डरहरू',
    meitei: 'Subscription reminders',
    mizo: 'Subscription hriattirnawmna',
    kashmiri: 'سبسکرپشن یاد دہانی',
    ladakhi: 'མཁོ་སྤྲོད་དྲན་སྐུལ།',
  );

  String get subscriptionSubtitle => _localized(
    telugu: 'ట్రయల్ ముగింపు లేదా రీన్యూవల్ తేదీలకు గుర్తింపులు.',
    english: 'Trial end and renewal reminders.',
    hindi: 'परीक्षण समाप्ति और नवीनीकरण अनुस्मारक।',
    tamil: 'சோதனை முடிவு மற்றும் புதுப்பித்தல் நினைவூட்டல்கள்.',
    kannada: 'ಪ್ರಾಯೋಗಿಕ ಅಂತ್ಯ ಮತ್ತು ನವೀಕರಣ ಜ್ಞಾಪನೆಗಳು.',
    malayalam: 'ട്രയൽ അവസാനിക്കുന്നതും പുതുക്കുന്നതുമായ ഓർമ്മപ്പെടുത്തലുകൾ.',
    marathi: 'चाचणी समाप्त आणि नूतनीकरण स्मरणपत्रे.',
    gujarati: 'ટ્રાયલ સમાપ્તિ અને નવીકરણ રીમાઇન્ડર્સ.',
    bengali: 'ট্রায়াল শেষ এবং পুনর্নবীকরণ অনুস্মারক।',
    punjabi: 'ਟਰਾਇਲ ਸਮਾਪਤੀ ਅਤੇ ਨਵੀਨੀਕਰਨ ਰੀਮਾਈਂਡਰ।',
    odia: 'ଟ୍ରାଏଲ୍ ସମାପ୍ତି ଏବଂ ନବୀକରଣ ସ୍ମାରକୀ।',
    assamese: 'পৰীক্ষামূলক ম্যাদ শেষ আৰু নৱীকৰণৰ সোঁৱৰণী।',
    konkani: 'ट्रायल सोंपप आनी नूतनीकरण यादस्तिकां.',
    nepali: 'परीक्षण समाप्ति र नवीकरण रिमाइन्डरहरू।',
    meitei: 'Trial loinaba amasung renewal reminders.',
    mizo: 'Trial tawp leh renew tur hriattirna.',
    kashmiri: 'ٹرائل ختم گژھنُک تہٕ نٔو سرٕ کرنہٕ چہِ یاد دِہٲنی۔',
    ladakhi: 'ཚོད་ལྟ་རྫོགས་པ་དང་བསྐྱར་གསོའི་དྲན་སྐུལ།',
  );

  String get savingLabel => _localized(
    telugu: 'సేవ్ అవుతోంది...',
    english: 'Saving...',
    hindi: 'सहेज रहा है...',
    tamil: 'சேமிக்கிறது...',
    kannada: 'ಉಳಿಸಲಾಗುತ್ತಿದೆ...',
    malayalam: 'സംരക്ഷിക്കുന്നു...',
    marathi: 'जतन करत आहे...',
    gujarati: 'સાચવી રહ્યું છે...',
    bengali: 'সংরক্ষণ করা হচ্ছে...',
    punjabi: 'ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...',
    odia: 'ସଂରକ୍ଷଣ ହେଉଛି...',
    assamese: 'সংৰক্ষণ কৰা হৈছে...',
    konkani: 'सांबाळटा...',
    nepali: 'सुरक्षित हुँदैछ...',
    meitei: 'Save touri...',
    mizo: 'Save mek...',
    kashmiri: 'محفوٗظ گژھان...',
    ladakhi: 'ཉར་ཚགས་བྱེད་བཞིན་པ...',
  );
}
