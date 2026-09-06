import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  static const String _supportEmail = AppPublicInfo.supportEmail;
  Future<PackageInfo>? _packageInfoFuture;

  Future<void> _openPublicUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          context.strings.localized(
            telugu: 'లింక్ తెరవలేకపోయాం. మళ్లీ ప్రయత్నించండి.',
            english: 'Could not open the link. Please try again.',
            hindi: 'लिंक नहीं खुल सका। कृपया पुनः प्रयास करें।',
            tamil: 'இணைப்பைத் திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
            kannada: 'ಲಿಂಕ್ ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
            malayalam: 'ലിങ്ക് തുറക്കാൻ കഴിഞ്ഞില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
            marathi: 'लिंक उघडता आली नाही. कृपया पुन्हा प्रयत्न करा.',
            gujarati: 'લિંક ખોલી શકાઈ નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
            bengali: 'লিঙ্ক খোলা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
            punjabi: 'ਲਿੰਕ ਖੋਲ੍ਹਿਆ ਨਹੀਂ ਜਾ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
            odia: 'ଲିଙ୍କ୍ ଖୋଲିପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
            assamese: 'লিংকটো খোলিব পৰা নগʼল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
            konkani: 'ಲಿಂಕ್ ಉಗ್ತೆಂ ಕರುಂಕ್ ಜಾಲೆಂ ನಾ. ಉಪಕಾರ ಕರ್ನ್ ಪರತ್ ಪ್ರಯತ್ನ್ ಕರಾ.',
            nepali: 'लिंक खोल्न सकिएन। कृपया फेरि प्रयास गर्नुहोस्।',
            meitei: 'লিঙ্ক হাংদোকপা ঙমদ্রে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
            mizo: 'Link hawn theih a ni lo. Khawngaihin tum leh rawh.',
            kashmiri: 'لنک نہ ہیکو کٔھتِتھ۔ مہربٲنی کٔرِتھ دۆبارٕ کوشش کٔریو۔',
            ladakhi: 'ལིངྐ་ཕྱེ་མ་ཐུབ། ཡང་བསྐྱར་འབད་རྩོལ་གནང་རོགས།',
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final copy = _AboutCopy(strings);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.screenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -90,
            right: -36,
            child: _BlurOrb(size: 180, color: const Color(0x1822C55E)),
          ),
          Positioned(
            top: 130,
            left: -56,
            child: _BlurOrb(size: 140, color: const Color(0x182563EB)),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFFE8F4EE), Color(0xFFFFFFFF)],
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x100F172A),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: const Color(0xD9E5EEF7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x100F172A),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/branding/mana_poster_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  copy.teluguFirstPill,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF166534),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                copy.appName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                copy.heroSubtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF475569),
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      copy.heroBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF334155),
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder<PackageInfo>(
                      future: _packageInfoFuture,
                      builder: (context, snapshot) {
                        final versionName =
                            snapshot.data?.version.trim().isNotEmpty == true
                            ? snapshot.data!.version.trim()
                            : 'Unknown';
                        final buildNumber =
                            snapshot.data?.buildNumber.trim().isNotEmpty == true
                            ? snapshot.data!.buildNumber.trim()
                            : 'Unknown';
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 340;
                            final cardWidth = stacked
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 10) / 2;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                SizedBox(
                                  width: cardWidth,
                                  child: _HeroStatCard(
                                    label: copy.versionPill,
                                    value: versionName,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _HeroStatCard(
                                    label: copy.buildPill,
                                    value: buildNumber,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: copy.whatIsTitle),
              const SizedBox(height: 8),
              _DetailSection(title: copy.whatIsTitle, body: copy.whatIsBody),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.whoForTitle),
              const SizedBox(height: 8),
              _DetailSection(title: copy.whoForTitle, body: copy.whoForBody),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.featuresTitle),
              const SizedBox(height: 8),
              _ChecklistSection(
                title: copy.featuresTitle,
                items: copy.featureItems,
              ),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.flowTitle),
              const SizedBox(height: 8),
              _ChecklistSection(title: copy.flowTitle, items: copy.flowItems),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.languagesTitle),
              const SizedBox(height: 8),
              _ChecklistSection(
                title: copy.languagesTitle,
                items: copy.languageItems,
              ),
              const SizedBox(height: 14),
              _SectionLabel(title: copy.supportTitle),
              const SizedBox(height: 8),
              _DetailSection(
                title: copy.supportTitle,
                body: '${copy.supportBody}\n\n$_supportEmail',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 360;
                  final buttonWidth = stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SizedBox(
                        width: buttonWidth,
                        child: _LegalActionButton(
                          label: copy.privacyButton,
                          icon: Icons.verified_user_outlined,
                          onTap: () =>
                              _openPublicUrl(AppPublicInfo.privacyPolicyUrl),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: _LegalActionButton(
                          label: copy.termsButton,
                          icon: Icons.article_outlined,
                          onTap: () => _openPublicUrl(AppPublicInfo.termsUrl),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.color});

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

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xD9E3ECF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.68,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.62,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalActionButton extends StatelessWidget {
  const _LegalActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E8F2)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCopy {
  const _AboutCopy(this.strings);

  final AppStrings strings;

  String get screenTitle => strings.localized(
    telugu: 'యాప్ గురించి',
    english: 'About App',
    hindi: 'ऐप के बारे में',
    tamil: 'செயலி பற்றி',
    kannada: 'ಅಪ್ಲಿಕೇಶನ್ ಬಗ್ಗೆ',
    malayalam: 'ആപ്പിനെക്കുറിച്ച്',
    marathi: 'अ‍ॅपबद्दल',
    gujarati: 'એપ વિશે',
    bengali: 'অ্যাপ সম্পর্কে',
    punjabi: 'ਐਪ ਬਾਰੇ',
    odia: 'ଆପ୍ ବିଷୟରେ',
    assamese: 'এপ সম্পৰ্কে',
    konkani: 'ಆ್ಯಪ್ ವಿಶಾಂತ್',
    nepali: 'एपको बारेमा',
    meitei: 'এপকী মরমদা',
    mizo: 'App chungchang',
    kashmiri: 'ایپھس مُتلِق',
    ladakhi: 'ཨེཔ་སྐོར།',
  );

  String get appName => AppPublicInfo.appName;

  String get heroSubtitle => strings.localized(
    telugu: 'పోస్టర్లు సులభంగా రూపొందించుకునే తెలుగు ప్రాధాన్య యాప్',
    english: 'A Telugu-first app for creating posters with ease',
    hindi: 'पोस्टर आसानी से बनाने के लिए तेलुगु-प्राथमिक ऐप',
    tamil: 'சுலபமாக போஸ்டர்களை உருவாக்கும் தெலுங்கு-முன்னுரிமை செயலி',
    kannada: 'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಸುಲಭವಾಗಿ ರಚಿಸಲು ತೆಲುಗು-ಪ್ರಧಾನ ಆ್ಯಪ್',
    malayalam: 'പോസ്റ്ററുകൾ എളുപ്പത്തിൽ ഉണ്ടാക്കാൻ തെലുങ്ക്-പ്രഥമ ആപ്പ്',
    marathi: 'सहजरीत्या पोस्टर्स तयार करण्यासाठी तेलगू-प्राधान्य अ‍ॅप',
    gujarati: 'સરળતાથી પોસ્ટર બનાવવા માટે તેલુગુ-પ્રાથમિક એપ',
    bengali: 'সহজে পোস্টার তৈরির জন্য তেলুগু-প্রথম অ্যাপ',
    punjabi: 'ਆਸਾਨੀ ਨਾਲ ਪੋਸਟਰ ਬਣਾਉਣ ਲਈ ਤੇਲਗੂ-ਪ੍ਰਮੁੱਖ ਐਪ',
    odia: 'ସହଜରେ ପୋଷ୍ଟର ତିଆରି କରିବା ପାଇଁ ତେଲୁଗୁ-ପ୍ରାଥମିକ ଆପ୍',
    assamese: 'সহজতে পোষ্টাৰ তৈয়াৰ কৰাৰ বাবে তেলেগু-প্ৰাথমিক এপ',
    konkani: 'ಸೊಂಪನ್ ಪೋಸ್ಟರ್ ತಯಾರ್ ಕರುಂಕ್ ತೆಲುಗು-ಪ್ರಾಥಮಿಕ್ ಆ್ಯಪ್',
    nepali: 'सजिलैसँग पोस्टरहरू बनाउनको लागि तेलुगु-प्राथमिक एप',
    meitei: 'পোস্তরশিং লাইনা শেম্বগীদমক তেলুগু-অহানবা এপ',
    mizo: 'Awlsam taka poster siamna tura Telugu-hmasa app',
    kashmiri: 'آسٲنی سان پوسٹر بناونہٕ باپتھ تیلگوٗ-گۄڈنیُک ایپھ',
    ladakhi: 'པོསྚར་ལས་སླ་མོར་བཟོ་བའི་ཏེ་ལུ་གུ་གཙོ་བོའི་ཨེཔ།',
  );

  String get heroBody => strings.localized(
    telugu: 'Mana Poster Ai ద్వారా శుభాకాంక్షలు, పండుగ పోస్టర్లు, వ్యాపార ప్రచార డిజైన్లు, భక్తి పోస్టర్లు, ప్రత్యేక సందర్భాల పోస్టర్లు వంటి వాటిని వేగంగా ఎంచుకుని మీ వివరాలతో వ్యక్తిగతంగా మార్చుకోవచ్చు. మొబైల్‌లోనే చూసి, ఎంపిక చేసి, సవరించి, ఇతరులతో పంచుకోవడానికి సరళమైన పని విధానం ఈ యాప్‌లో అందుబాటులో ఉంటుంది.',
    english: 'Mana Poster Ai helps users quickly choose, personalize, edit, export, and share greeting posters, festival designs, business promotions, devotional content, and other occasion-based posters. The app combines ready-made posters with a mobile editor, premium assets, Telugu fonts, background removal, and export tools in one place.',
    hindi: 'Mana Poster Ai की मदद से शुभकामना पोस्टर, त्योहार डिज़ाइन, बिज़नेस प्रमोशन, भक्ति पोस्टर और विशेष अवसरों के पोस्टर जल्दी चुनकर अपनी जानकारी के साथ कस्टमाइज़ किए जा सकते हैं। मोबाइल पर ही देखने, चुनने, एडिट करने और शेयर करने की आसान सुविधा इस ऐप में उपलब्ध है।',
    tamil: 'Mana Poster Ai மூலம் வாழ்த்து போஸ்டர்கள், பண்டிகை வடிவமைப்புகள், வணிக விளம்பரங்கள், பக்தி போஸ்டர்கள் மற்றும் சிறப்பு நிகழ்வு போஸ்டர்களை விரைவாகத் தேர்வுசெய்து உங்கள் தகவல்களுடன் தனிப்பயனாக்கலாம். மொபைலிலேயே பார்த்து, தேர்வு செய்து, திருத்தி, பகிர எளிய வழி இதில் உள்ளது.',
    kannada: 'Mana Poster Ai ಮೂಲಕ ಶುಭಾಶಯ ಪೋಸ್ಟರ್‌ಗಳು, ಹಬ್ಬದ ವಿನ್ಯಾಸಗಳು, ವ್ಯಾಪಾರ ಪ್ರಚಾರಗಳು, ಭಕ್ತಿ ಪೋಸ್ಟರ್‌ಗಳು ಮತ್ತು ವಿಶೇಷ ಸಂದರ್ಭಗಳ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ತ್ವರಿತವಾಗಿ ಆಯ್ಕೆಮಾಡಿ ನಿಮ್ಮ ವಿವರಗಳೊಂದಿಗೆ ವೈಯಕ್ತೀಕರಿಸಬಹುದು. ಮೊಬೈಲ್‌ನಲ್ಲೇ ವೀಕ್ಷಿಸಲು, ಆಯ್ಕೆಮಾಡಲು, ತಿದ್ದಿ, ಹಂಚಿಕೊಳ್ಳಲು ಸರಳ ವ್ಯವಸ್ಥೆ ಇಲ್ಲಿದೆ.',
    malayalam: 'Mana Poster Ai ഉപയോഗിച്ച് ആശംസാ പോസ്റ്ററുകൾ, ഉത്സവ ഡിസൈനുകൾ, ബിസിനസ് പ്രമോഷൻ, ഭക്തി പോസ്റ്ററുകൾ, വിശേഷ ദിവസങ്ങളിലെ പോസ്റ്ററുകൾ എന്നിവ വേഗത്തിൽ തിരഞ്ഞെടുത്ത് നിങ്ങളുടെ വിവരങ്ങൾ ചേർത്ത് തയ്യാറാക്കാം. മൊബൈലിൽ തന്നെ കണ്ട്, തിരുത്തി, പങ്കിടാനുള്ള എളുപ്പവഴിയാണിത്.',
    marathi: 'Mana Poster Ai द्वारे शुभेच्छा पोस्टर्स, सणांचे डिझाईन्स, व्यवसाय जाहिराती, भक्ती पोस्टर्स आणि विशेष प्रसंगांचे पोस्टर्स वेगाने निवडून आपल्या माहितीसह कस्टमाइझ करता येतात. मोबाईलवरच पाहून, निवडून, संपादित करून आणि शेअर करण्याची सोपी व्यवस्था यात उपलब्ध आहे.',
    gujarati: 'Mana Poster Ai ની મદદથી શુભેચ્છાઓ, તહેવાર ડિઝાઇન્સ, બિઝનેસ પ્રમોશન, ભક્તિ પોસ્ટર્સ અને વિશેષ પ્રસંગોના પોસ્ટર્સ ઝડપથી પસંદ કરી તમારી વિગતો સાથે કસ્ટમાઇઝ કરી શકાય છે. મોબાઇલ પર જ જોવા, પસંદ કરવા, એડિટ કરવા અને શેર કરવાની સરળ સુવિધા છે.',
    bengali: 'Mana Poster Ai-এর সাহায্যে শুভেচ্ছা পোস্টার, উৎসবের ডিজাইন, ব্যবসায়িক প্রচার, ভক্তি পোস্টার এবং বিশেষ অনুষ্ঠানের পোস্টার দ্রুত বেছে নিয়ে নিজের তথ্যের সাথে কাস্টমাইজ করা যায়। মোবাইলেই দেখা, নির্বাচন, সম্পাদনা এবং শেয়ার করার সহজ সুবিধা এতে রয়েছে।',
    punjabi: 'Mana Poster Ai ਰਾਹੀਂ ਸ਼ੁਭਕਾਮਨਾਵਾਂ, ਤਿਉਹਾਰਾਂ ਦੇ ਡਿਜ਼ਾਈਨ, ਵਪਾਰਕ ਪ੍ਰਚਾਰ, ਭਗਤੀ ਪੋਸਟਰ ਅਤੇ ਵਿਸ਼ੇਸ਼ ਮੌਕਿਆਂ ਦੇ ਪੋਸਟਰ ਜਲਦੀ ਚੁਣ ਕੇ ਆਪਣੇ ਵੇਰਵਿਆਂ ਨਾਲ ਨਿੱਜੀ ਬਣਾਏ ਜਾ ਸਕਦੇ ਹਨ। ਮੋਬਾਈਲ ਤੇ ਹੀ ਦੇਖਣ, ਚੁਣਨ, ਐਡਿਟ ਕਰਨ ਅਤੇ ਸਾਂਝਾ ਕਰਨ ਦੀ ਆਸਾਨ ਸਹੂਲਤ ਹੈ।',
    odia: 'Mana Poster Ai ମାଧ୍ୟମରେ ଶୁଭେଚ୍ଛା ପୋଷ୍ଟର, ପର୍ବପର୍ବାଣି ଡିଜାଇନ୍, ବ୍ୟବସାୟ ପ୍ରଚାର, ଭକ୍ତି ପୋଷ୍ଟର ଏବଂ ବିଶେଷ ଅବସରର ପୋଷ୍ଟର ଶୀଘ୍ର ବାଛି ନିଜ ବିବରଣୀ ସହିତ ବ୍ୟକ୍ତିଗତ କରାଯାଇପାରିବ। ମୋବାଇଲ୍‌ରେ ହିଁ ଦେଖିବା, ବାଛିବା, ଏଡିଟ୍ କରିବା ଓ ସେୟାର କରିବାର ସହଜ ସୁବିଧା ଏଥିରେ ଉପଲବ୍ଧ।',
    assamese: 'Mana Poster Ai-ৰ জৰিয়তে শুভেচ্ছা পোষ্টাৰ, উৎসৱৰ ডিজাইন, ব্যৱসায়িক প্ৰচাৰ, ভক্তি পোষ্টাৰ আৰু বিশেষ অনুষ্ঠানৰ পোষ্টাৰ ক্ষিপ্ৰতাৰে নিৰ্বাচন কৰি আপোনাৰ তথ্যৰে কাষ্টমাইজ কৰিব পাৰি। মʼবাইলতে চাই, বাছি, সম্পাদনা কৰি শ্বেয়াৰ কৰাৰ সহজ সুবিধা ইয়াত আছে।',
    konkani: 'Mana Poster Ai ಮುಖಾಂತ್ರ್ ಶುಭಾಶಯ್ ಪೋಸ್ಟರ್, ಪರ್ಬಾಂಚೆ ಡಿಸೈನ್, ವ್ಯವಹಾರಾಚೆ ಪ್ರಚಾರ್, ಭಕ್ತಿ ಪೋಸ್ಟರ್ ಆನಿ ವಿಶೇಸ್ ಸಂದರ್ಭಾಚೆ ಪೋಸ್ಟರ್ ವೇಗಾನ್ ವಿಂಚುನ್ ತುಮ್ಚ್ಯಾ ವಿವರಾಂ ಸಾಂಗಾತಾ ಕಸ್ಟಮೈಜ್ ಕರುಂಕ್ ಜಾತಾ. ಮೊಬೈಲಾರ್‌ಚ್ ಪಳೊವ್ನ್, ವಿಂಚುನ್, ಸಂಪಾದನ್ ಕರ್ನ್ ಆನಿ ಶೇರ್ ಕರುಂಕ್ ಸೊಂಪ್ ವ್ಯವಸ್ಥಾ ಆಸಾ.',
    nepali: 'Mana Poster Ai मार्फत शुभकामना पोस्टर, चाडपर्व डिजाइन, व्यापार प्रचार, भक्ति पोस्टर र विशेष अवसरका पोस्टरहरू चाँडै छानेर आफ्ना विवरणहरूसँग अनुकूलित गर्न सकिन्छ। मोबाइलमै हेर्न, छनोट गर्न, सम्पादन गर्न र सेयर गर्न सजिलो व्यवस्था यसमा उपलब्ध छ।',
    meitei: 'Mana Poster Ai গী মতেংনা য়াইফ-পাউজেল পোস্তরশিং, কুহ্মৈগী দিজাইনশিং, লল্লোন-ইতিক্কী প্রমোসন, শেবা-থাওইবগী পোস্তরশিং অমসুং অখন্নবা থৌরমশিংগী পোস্তরশিং য়াংনা খনগৎতুনা মশাগী ৱারোলশিংগা লোয়ননা শেমদোকপা য়াই। মোবাইলদগী য়েংবা, খনবা, শেমদোকপা অমসুং শিয়র তৌবগী লাইবা পাম্বৈ লৈ।',
    mizo: 'Mana Poster Ai hmangin chibai bukna poster, kut design, sumdawnna fakna, rinna lam poster leh hun bik poster-te rang takin thlangin i thuziak leh thlalak nen a siam danglam theih. Mobile-ah ngei en, thlan, siamrem leh thehdarh dan awlsam a awm a ni.',
    kashmiri: 'Mana Poster Ai ذٔریعہٕ ہیکیو تُہؠ مۆبارکبادی ہٕنٛدی پوسٹر، تیوہار ڈیزائن، کٲروبٲری پروموشن، بھکتِی پوسٹر تہٕ خاص موقَن ہٕنٛدی پوسٹر تیزی سان ژٲرِتھ پننؠن تفصیلاتن سٟتؠ کسٹمائز کٔرِتھ۔ موبائلَس پؠٹھٕے ؤچھُن، ژارُن، ایڈٹ کرُن تہٕ شیئر کرنٕچ سَہل سَہولت چھِ اَتھ مَنٛز دٔستیاب۔',
    ladakhi: 'Mana Poster Ai བརྒྱུད་ནས་བཀྲ་ཤིས་བདེ་ལེགས་ཀྱི་པོསྚར། དུས་སྟོན་གྱི་བཟོ་བཀོད། ཚོང་ལས་ཁྱབ་བསྒྲགས། དད་པའི་པོསྚར་དང་དམིགས་བསལ་དུས་སྐབས་ཀྱི་པོསྚར་རྣམས་མགྱོགས་པོར་འདེམས་ཏེ་རང་ཉིད་ཀྱི་གནས་ཚུལ་དང་བཅས་བཟོ་བཅོས་བྱེད་ཐུབ། ལག་ཐོགས་ཁ་པར་ནང་དུ་བལྟ་བ། འདེམས་པ། བཟོ་བཅོས་དང་བརྒྱུད་སྤེལ་བྱེད་པའི་ལས་སླ་མོའི་རིམ་པ་ཡོད།',
  );

  String get teluguFirstPill => strings.localized(
    telugu: 'తెలుగు ప్రధాన అనుభవం',
    english: 'Telugu-first experience',
    hindi: 'तेलुगु-प्राथमिक अनुभव',
    tamil: 'தெலுங்கு-முன்னுரிமை அனுபவம்',
    kannada: 'ತೆಲುಗು-ಪ್ರಧಾನ ಅನುಭವ',
    malayalam: 'തെലുങ്ക്-പ്രഥമ അനുഭവം',
    marathi: 'तेलगू-प्राधान्य अनुभव',
    gujarati: 'તેલુગુ-પ્રાથમિક અનુભવ',
    bengali: 'তেলুগু-প্রথম অভিজ্ঞতা',
    punjabi: 'ਤੇਲਗੂ-ਪ੍ਰਮੁੱਖ ਅਨੁਭਵ',
    odia: 'ତେଲୁଗୁ-ପ୍ରାଥମିକ ଅନୁଭୂତି',
    assamese: 'তেলেগু-প্ৰাথমিক অভিজ্ঞতা',
    konkani: 'ತೆಲುಗು-ಪ್ರಾಥಮಿಕ್ ಅನ್ಭವ್',
    nepali: 'तेलुगु-प्राथमिक अनुभव',
    meitei: 'তেলুগু-অহানবা এক্সপেরিএন্স',
    mizo: 'Telugu-hmasa tawn hriatna',
    kashmiri: 'تیلگوٗ-گۄڈنیُک تجربہٕ',
    ladakhi: 'ཏེ་ལུ་གུ་གཙོ་བོའི་ཉམས་མྱོང་།',
  );

  String get versionPill => strings.localized(
    telugu: 'ఆవృత్తి',
    english: 'Version',
    hindi: 'संस्करण',
    tamil: 'பதிப்பு',
    kannada: 'ಆವೃತ್ತಿ',
    malayalam: 'പതിപ്പ്',
    marathi: 'आवृत्ती',
    gujarati: 'આવૃત્તિ',
    bengali: 'সংস্করণ',
    punjabi: 'ਵਰਜਨ',
    odia: 'ସଂସ୍କରଣ',
    assamese: 'সংস্কৰণ',
    konkani: 'ಆವೃತ್ತಿ',
    nepali: 'संस्करण',
    meitei: 'ভর্সন',
    mizo: 'Version',
    kashmiri: 'ورژن',
    ladakhi: 'ཐོན་རིམ།',
  );

  String get buildPill => strings.localized(
    telugu: 'నిర్మాణ సంఖ్య',
    english: 'Build',
    hindi: 'बिल्ड',
    tamil: 'பில்ட்',
    kannada: 'ಬಿಲ್ಡ್',
    malayalam: 'ബിൽഡ്',
    marathi: 'बिल्ड',
    gujarati: 'બિલ્ડ',
    bengali: 'বিল্ড',
    punjabi: 'ਬਿਲਡ',
    odia: 'ବିଲ୍ଡ',
    assamese: 'বিল্ড',
    konkani: 'ಬಿಲ್ಡ್',
    nepali: 'बिल्ड',
    meitei: 'বিল্ড',
    mizo: 'Build',
    kashmiri: 'بِلٛڈ',
    ladakhi: 'བཟོ་བཀོད།',
  );

  String get whatIsTitle => strings.localized(
    telugu: 'ఈ యాప్ ఏమి చేస్తుంది',
    english: 'What this app does',
    hindi: 'यह ऐप क्या करता है',
    tamil: 'இந்த செயலி என்ன செய்கிறது',
    kannada: 'ಈ ಆ್ಯಪ್ ಏನು ಮಾಡುತ್ತದೆ',
    malayalam: 'ഈ ആപ്പ് എന്ത് ചെയ്യുന്നു',
    marathi: 'हे अ‍ॅप काय करते',
    gujarati: 'આ એપ શું કરે છે',
    bengali: 'এই অ্যাপটি কী করে',
    punjabi: 'ਇਹ ਐਪ ਕੀ ਕਰਦੀ ਹੈ',
    odia: 'ଏହି ଆପ୍ କ’ଣ କରେ',
    assamese: 'এই এপে কি কৰে',
    konkani: 'ಹೆಂ ಆ್ಯಪ್ ಕಿತೆಂ ಕರ್ತಾ',
    nepali: 'यो एपले के गर्छ',
    meitei: 'এপ অসিনা করি তৌরিবা',
    mizo: 'He app hian engnge a tih theih',
    kashmiri: 'یہِ ایپھ کیاہ چھُ کَران',
    ladakhi: 'ཨེཔ་འདིས་ཅི་བྱེད་དམ།',
  );

  String get whatIsBody => strings.localized(
    telugu: 'ఇది పోస్టర్ తయారీ యాప్. వినియోగదారులు సిద్ధంగా ఉన్న డిజైన్లను ఎంచుకుని, వాటిని తమ ఫోటో, వ్యాపార పేరు, వాట్సాప్ వివరాలు మరియు ఇతర సమాచారంతో మార్చుకోవచ్చు. ఎడిటర్ ద్వారా టెక్స్ట్ లేయర్లు, ఫోటో లేయర్లు, బ్రష్‌లు, లేయర్ ఎఫెక్ట్స్, పిఎస్‌డి/టిఫ్ ఇంపోర్ట్, ప్రీమియం అసెట్స్, తెలుగు ఫాంట్లు, బ్యాక్‌గ్రౌండ్ రిమూవల్, సేవ్/ఎక్స్‌పోర్ట్ వర్క్‌ఫ్లోలు, సబ్‌స్క్రిప్షన్ సమాచారం, సహాయం మరియు చట్టపరమైన నిబంధనలు అన్నీ ఒకే చోట లభిస్తాయి.',
    english: 'This is a poster creation app where users can choose ready-made designs and personalize them with their photo, business name, WhatsApp details, and other relevant information. The editor also supports text layers, photo layers, brushes, layer effects, PSD/TIFF import where supported, premium downloadable assets, Telugu font access, background removal, save/export workflows, subscription information, help, and legal access in one place.',
    hindi: 'यह एक पोस्टर निर्माण ऐप है जहां उपयोगकर्ता रेडी-मेड डिज़ाइन चुन सकते हैं और उन्हें अपनी फोटो, व्यावसायिक नाम, व्हाट्सएप विवरण और अन्य जानकारी के साथ कस्टमाइज़ कर सकते हैं। एडिटर में टेक्स्ट लेयर्स, फोटो लेयर्स, ब्रश, लेयर इफेक्ट्स, समर्थित PSD/TIFF इंपोर्ट, प्रीमियम एसेट्स, तेलुगु फॉन्ट, बैकग्राउंड रिमूवल, सेव/एक्सपोर्ट, सब्सक्रिप्शन और कानूनी नीतियां एक ही स्थान पर उपलब्ध हैं।',
    tamil: 'இது ஒரு போஸ்டர் தயாரிக்கும் செயலி. பயனர்கள் ஆயத்த வடிவமைப்புகளைத் தேர்ந்தெடுத்து, தங்கள் புகைப்படம், வணிகப் பெயர், வாட்ஸ்அப் விவரங்கள் மற்றும் தொடர்புடைய தகவல்களுடன் தனிப்பயனாக்கலாம். எடிட்டரில் உரை அடுக்குகள், புகைப்பட அடுக்குகள், பிரஷ்கள், விளைவுகள், PSD/TIFF இறக்குமதி, பிரீமியம் சொத்துகள், தெலுங்கு எழுத்துருக்கள், பின்னணி நீக்கம் மற்றும் சேமிப்பு/ஏற்றுமதி வசதிகள் ஒரே இடத்தில் உள்ளன.',
    kannada: 'ಇದು ಪೋಸ್ಟರ್ ರಚನಾ ಆ್ಯಪ್. ಬಳಕೆದಾರರು ಸಿದ್ಧ ವಿನ್ಯಾಸಗಳನ್ನು ಆರಿಸಿ, ತಮ್ಮ ಫೋಟೋ, ವ್ಯವಹಾರದ ಹೆಸರು, ವಾಟ್ಸಾಪ್ ವಿವರಗಳು ಮತ್ತು ಇತರ ಮಾಹಿತಿಯೊಂದಿಗೆ ಕಸ್ಟಮೈಸ್ ಮಾಡಬಹುದು. ಎಡಿಟರ್‌ನಲ್ಲಿ ಟೆಕ್ಸ್ಟ್ ಲೇಯರ್‌ಗಳು, ಫೋಟೋ ಲೇಯರ್‌ಗಳು, ಬ್ರಶ್‌ಗಳು, ಎಫೆಕ್ಟ್‌ಗಳು, PSD/TIFF ಇಂಪೋರ್ಟ್, ಪ್ರೀಮಿಯಂ ಅಸೆಟ್‌ಗಳು, ತೆಲುಗು ಫಾಂಟ್‌ಗಳು, ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ರಿಮೂವಲ್ ಮತ್ತು ಸೇವ್/ಎಕ್ಸ್‌ಪೋರ್ಟ್ ಸೌಲಭ್ಯಗಳು ಒಂದೇ ಕಡೆ ಲಭ್ಯವಿದೆ.',
    malayalam: 'ഇതൊരു പോസ്റ്റർ നിർമ്മാണ ആപ്പാണ്. ഉപയോക്താക്കൾക്ക് റെഡിമെയ്ഡ് ഡിസൈനുകൾ തിരഞ്ഞെടുത്ത് ഫോട്ടോ, ബിസിനസ്സ് പേര്, വാട്ട്‌സ്ആപ്പ് വിവരങ്ങൾ എന്നിവ നൽകി വ്യക്തിഗതമാക്കാം. എഡിറ്ററിൽ ടെക്സ്റ്റ് ലെയറുകൾ, ഫോട്ടോ ലെയറുകൾ, ബ്രഷുകൾ, ലെയർ ഇഫക്റ്റുകൾ, PSD/TIFF ഇമ്പോർട്ട്, പ്രീമിയം അസറ്റുകൾ, തെലുങ്ക് ഫോണ്ടുകൾ, ബാക്ക്ഗ്രൗണ്ട് റിമൂവൽ എന്നിവ ഒരിടത്ത് ലഭിക്കുന്നു.',
    marathi: 'हे एक पोस्टर निर्मिती अ‍ॅप आहे जिथे वापरकर्ते तयार डिझाईन्स निवडू शकतात आणि त्यांचा फोटो, व्यवसायाचे नाव, व्हॉट्सअ‍ॅप तपशील आणि इतर माहितीसह कस्टमाइझ करू शकतात. एडिटरमध्ये टेक्स्ट लेयर्स, फोटो लेयर्स, ब्रशेस, इफेक्ट्स, PSD/TIFF आयात, प्रीमियम अ‍ॅसेट्स, तेलगू फॉन्ट्स, बॅकग्राउंड काढणे आणि सेव्ह/एक्सपोर्ट एकाच ठिकाणी उपलब्ध आहेत.',
    gujarati: 'આ એક પોસ્ટર બનાવવાની એપ છે જ્યાં વપરાશકર્તાઓ તૈયાર ડિઝાઇન પસંદ કરી શકે છે અને તેમના ફોટો, વ્યવસાયનું નામ, વ્હોટ્સએપ વિગતો અને અન્ય માહિતી સાથે કસ્ટમાઇઝ કરી શકે છે. એડિટર ટેક્સ્ટ લેયર્સ, ફોટો લેયર્સ, બ્રશ, ઇફેક્ટ્સ, PSD/TIFF ઇમ્પોર્ટ, પ્રીમિયમ એસેટ્સ, તેલુગુ ફોન્ટ્સ અને બેકગ્રાઉન્ડ રિમૂવલ એક જ જગ્યાએ પ્રદાન કરે છે.',
    bengali: 'এটি একটি পোস্টার তৈরির অ্যাপ যেখানে ব্যবহারকারীরা তৈরি করা ডিজাইন বেছে নিয়ে নিজের ছবি, ব্যবসার নাম, হোয়াটসঅ্যাপ বিবরণ এবং অন্যান্য তথ্য দিয়ে কাস্টমাইজ করতে পারেন। এডিটরে টেক্সট লেয়ার, ফটো লেয়ার, ব্রাশ, লেয়ার এফেক্টস, PSD/TIFF ইম্পোর্ট, প্রিমিয়াম অ্যাসেট, তেলুগু ফন্ট এবং ব্যাকগ্রাউন্ড রিমুভাল এক জায়গায় উপলব্ধ।',
    punjabi: 'ਇਹ ਇੱਕ ਪੋਸਟਰ ਬਣਾਉਣ ਵਾਲੀ ਐਪ ਹੈ ਜਿੱਥੇ ਵਰਤੋਂਕਾਰ ਤਿਆਰ ਡਿਜ਼ਾਈਨ ਚੁਣ ਸਕਦੇ ਹਨ ਅਤੇ ਆਪਣੀ ਫੋਟੋ, ਕਾਰੋਬਾਰੀ ਨਾਮ, ਵਟਸਐਪ ਵੇਰਵੇ ਅਤੇ ਹੋਰ ਜਾਣਕਾਰੀ ਨਾਲ ਨਿੱਜੀ ਬਣਾ ਸਕਦੇ ਹਨ। ਐਡੀਟਰ ਵਿੱਚ ਟੈਕਸਟ ਲੇਅਰਾਂ, ਫੋਟੋ ਲੇਅਰਾਂ, ਬੁਰਸ਼, ਪ੍ਰਭਾਵ, PSD/TIFF ਇੰਪੋਰਟ, ਪ੍ਰੀਮੀਅਮ ਸੰਪਤੀਆਂ, ਤੇਲਗੂ ਫੌਂਟ ਅਤੇ ਬੈਕਗ੍ਰਾਊਂਡ ਹਟਾਉਣ ਦੀ ਸੁਵਿਧਾ ਇੱਕੋ ਥਾਂ ਮਿਲਦੀ ਹੈ।',
    odia: 'ଏହା ଏକ ପୋଷ୍ଟର ତିଆରି ଆପ୍ ଯେଉଁଥିରେ ବ୍ୟବହାରକାରୀମାନେ ପ୍ରସ୍ତୁତ ଡିଜାଇନ୍ ବାଛି ନିଜ ଫଟୋ, ବ୍ୟବସାୟ ନାମ, ହ୍ୱାଟ୍ସଆପ୍ ବିବରଣୀ ସହିତ କଷ୍ଟମାଇଜ୍ କରିପାରିବେ। ଏଡିଟର୍‌ରେ ଟେକ୍ସଟ୍ ଲେୟାର, ଫଟୋ ଲେୟାର, ବ୍ରସ୍, ଲେୟାର ଇଫେକ୍ଟସ୍, PSD/TIFF ଇମ୍ପୋର୍ଟ, ପ୍ରିମିୟମ୍ ଆସେଟ୍, ତେଲୁଗୁ ଫଣ୍ଟ୍ ଏବଂ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଇବା ସୁବିଧା ଗୋଟିଏ ସ୍ଥାନରେ ଉପଲବ୍ଧ।',
    assamese: 'এইটো এটা পোষ্টাৰ নিৰ্মাণৰ এপ যʼত ব্যৱহাৰকাৰীসকলে সাজু ডিজাইন বাছি নিজৰ ফটো, ব্যৱসায়িক নাম, হোৱাটছএপ তথ্য আৰু অন্যান্য তথ্যৰে কাষ্টমাইজ কৰিব পাৰে। এডিটৰত টেক্সট স্তৰ, ফটো স্তৰ, ব্ৰাছ, প্ৰভাৱ, PSD/TIFF আমদানি, প্ৰিমিয়াম সম্পদ, তেলেগু ফন্ট আৰু পটভূমি আঁতৰোৱাৰ সুবিধা একেলগে উপলব্ধ।',
    konkani: 'ಹೆಂ ಏಕ್ ಪೋಸ್ಟರ್ ತಯಾರ್ ಕರ್ಚೆಂ ಆ್ಯಪ್. ಬಳಕೆದಾರ್ ತಯಾರ್ ಆಸ್ಚೆ ಡಿಸೈನ್ ವಿಂಚುನ್ ಆಪ್ಲೊ ಫೋಟೋ, ವ್ಯವಹಾರಾಚೆಂ ನಾಂವ್, ವಾಟ್ಸಾಪ್ ವಿವರಾಂ ಸಾಂಗಾತಾ ಕಸ್ಟಮೈಜ್ ಕರುಂಕ್ ಸಕ್ತಾತ್. ಎಡಿಟರಾಂತ್ ಟೆಕ್ಸ್ಟ್ ಲೇಯರ್, ಫೋಟೋ ಲೇಯರ್, ಬ್ರಶ್, ಎಫೆಕ್ಟ್ಸ್, PSD/TIFF ಇಂಪೋರ್ಟ್, ಪ್ರೀಮಿಯಂ ಅಸೆಟ್ಸ್, ತೆಲುಗು ಫಾಂಟ್ಸ್ ಆನಿ ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ಕಾಡ್ಚೆಂ ಏಕಚ್ ಕಡೆನ್ ಮೆಳ್ತಾ.',
    nepali: 'यो पोस्टर बनाउने एप हो जहाँ प्रयोगकर्ताहरूले तयार डिजाइनहरू छानेर आफ्नो फोटो, व्यापारको नाम, व्हाट्सएप विवरण र अन्य जानकारीका साथ अनुकूलित गर्न सक्छन्। सम्पादकमा टेक्स्ट लेयर, फोटो लेयर, ब्रस, लेयर इफेक्ट, PSD/TIFF आयात, प्रिमियम सम्पत्ति, तेलुगु फन्ट र पृष्ठभूमि हटाउने सुविधा एकै ठाउँमा उपलब्ध छ।',
    meitei: 'মসি পোস্তর শেম্বগী এপ অমনি মফম অদুদা য়ুজরশিংনা শেম-শাবা দিজাইনশিং খনগৎতুনা মশাগী ফোতো, লল্লোন-ইতিক্কী মিং, ৱাত্সএপকী ৱারোলশিংগা লোয়ননা শেমদোকপা য়াই। এদিতরদা তেক্সত লেয়রশিং, ফোতো লেয়রশিং, ব্রসশিং, লেয়র ইফেক্তশিং, PSD/TIFF ইম্পোর্ত, প্রিমিয়ম এসেতশিং, তেলুগু ফোন্তশিং অমসুং বেকগ্রাউন্দ লৌথোকপা পুম্নমক মফম অমদা ফংই।',
    mizo: 'Hei hi poster siamna app niin, duansa design-te thlangin thlalak, sumdawnna hming, WhatsApp details leh thil dangte nen a siam theih a ni. Editor-ah text layers, photo layers, brushes, layer effects, PSD/TIFF lakluh theihna, premium assets, Telugu fonts, background paihna leh save/export zawng zawng hmun khatah a awm vek a ni.',
    kashmiri: 'یہِ چھُ اَکھ پوسٹر بناونُک ایپھ ییٚتہِ صارِف تیّار شُدٕ ڈیزائن ژٲرِتھ پنُن فوٹو، کٲروبٲری ناو، واٹس ایپ تفصیلات تہٕ باقٕے معلومات سٟتؠ تِم کسٹمائز کٔرِتھ ہؠکن۔ ایڈیٹرس مَنٛز چھِ ٹیکسٹ لیئرز، فوٹو لیئرز، برش، اِفیکٹس، PSD/TIFF اِمپورٹ، پریمیم اثاثہٕ، تیلگوٗ فونٛٹس تہٕ بیک گرٛاونٛڈ ہٹاوُن اکہِ جاے دٔستیاب۔',
    ladakhi: 'འདི་ནི་པོསྚར་བཟོ་བའི་ཨེཔ་ཞིག་ཡིན་ཞིང་། སྤྱོད་པ་པོ་རྣམས་ཀྱིས་བཟོས་ཟིན་པའི་བཀོད་པ་བདམས་ནས་རང་གི་འདྲ་པར། ཚོང་ལས་ཀྱི་མིང་། ཝཊས་ཨེཔ་གནས་ཚུལ་སོགས་ཀྱིས་བཟོ་བཅོས་བྱེད་ཐུབ། ཞུ་དག་ཆས་ནང་ཡིག་དེབ། འདྲ་པར། པིར། ཁྱད་ཆོས། PSD/TIFF ནང་འདྲེན། རིན་མེད་མ་ཡིན་པའི་རྒྱུ་ཆ། ཏེ་ལུ་གུ་ཡིག་གཟུགས། རྒྱབ་ལྗོངས་སེལ་བ་བཅས་གཅིག་ཏུ་འདུས་ཡོད།',
  );

  String get whoForTitle => strings.localized(
    telugu: 'ఇది ఎవరి కోసం',
    english: 'Who it is for',
    hindi: 'यह किसके लिए है',
    tamil: 'இது யாருக்கானது',
    kannada: 'ಇದು ಯಾರಿಗಾಗಿ',
    malayalam: 'ഇത് ആർക്കുവേണ്ടിയാണ്',
    marathi: 'हे कोणासाठी आहे',
    gujarati: 'આ કોના માટે છે',
    bengali: 'এটি কার জন্য',
    punjabi: 'ਇਹ ਕਿਸ ਲਈ ਹੈ',
    odia: 'ଏହା କାହା ପାଇଁ',
    assamese: 'এইটো কাৰ বাবে',
    konkani: 'ಹೆಂ ಕೊಣಾಕ್',
    nepali: 'यो कसको लागि हो',
    meitei: 'মসি কনানা শীজিন্ননবা',
    mizo: 'Tu tana siam nge a nih',
    kashmiri: 'یہِ کٲسؠ باپتھ چھُ',
    ladakhi: 'འདི་སུའི་དོན་དུ་ཡིན་ནམ།',
  );

  String get whoForBody => strings.localized(
    telugu: 'రోజువారీ శుభాకాంక్షలు పంచుకునే వారికి, చిన్న వ్యాపారాల కోసం పోస్టర్లు రూపొందించే వారికి, భక్తి లేదా ప్రత్యేక సందర్భాల పోస్టులు ప్రచురించే వారికి, లేదా తమ పేరు, వ్యాపార గుర్తింపుతో కూడిన పోస్టర్లు కోరుకునే ప్రతి ఒక్కరికీ ఈ యాప్ ఎంతగానో ఉపయోగపడుతుంది.',
    english: 'This app is useful for people who share daily greetings, create posters for small businesses, publish devotional or occasion-based posts, or want personalized posters with their own name or business identity.',
    hindi: 'यह ऐप उन लोगों के लिए उपयोगी है जो दैनिक शुभकामनाएं साझा करते हैं, छोटे व्यवसायों के लिए पोस्टर बनाते हैं, भक्ति या विशेष अवसरों के पोस्ट प्रकाशित करते हैं, या अपने नाम या व्यावसायिक पहचान के साथ व्यक्तिगत पोस्टर चाहते हैं।',
    tamil: 'தினசரி வாழ்த்துகளைப் பகிர்வோர், சிறு வணிகங்களுக்கான போஸ்டர்களை உருவாக்குவோர், பக்தி அல்லது சிறப்பு நாள் பதிவுகளை வெளியிடுவோர் மற்றும் தங்கள் பெயர், வணிக அடையாளத்துடன் தனிப்பயன் போஸ்டர்களை விரும்புவோர் அனைவருக்கும் இந்த செயலி மிகவும் பயனுள்ளதாக இருக்கும்.',
    kannada: 'ದೈನಂದಿನ ಶುಭಾಶಯಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳುವವರಿಗೆ, ಸಣ್ಣ ವ್ಯಾಪಾರಗಳಿಗೆ ಪೋಸ್ಟರ್ ರಚಿಸುವವರಿಗೆ, ಭಕ್ತಿ ಅಥವಾ ವಿಶೇಷ ಸಂದರ್ಭಗಳ ಪೋಸ್ಟ್‌ಗಳನ್ನು ಪ್ರಕಟಿಸುವವರಿಗೆ, ಅಥವಾ ತಮ್ಮ ಹೆಸರು, ವ್ಯವಹಾರದ ಗುರುತಿನೊಂದಿಗೆ ಪೋಸ್ಟರ್ ಬಯಸುವ ಪ್ರತಿಯೊಬ್ಬರಿಗೂ ಈ ಆ್ಯಪ್ ಉಪಯುಕ್ತವಾಗಿದೆ.',
    malayalam: 'ദിവസേനയുള്ള ആശംസകൾ പങ്കിടുന്നവർക്കും ചെറുകിട ബിസിനസുകൾക്കായി പോസ്റ്ററുകൾ നിർമ്മിക്കുന്നവർക്കും ഭക്തിസാന്ദ്രമായതോ വിശേഷ അവസരങ്ങളിലോ ഉള്ള പോസ്റ്റുകൾ ഇടുന്നവർക്കും സ്വന്തം പേരിലോ സ്ഥാപനത്തിന്റെ പേരിലോ പോസ്റ്ററുകൾ ആഗ്രഹിക്കുന്നവർക്കും ഈ ആപ്പ് വളരെ പ്രയോജനപ്രദമാണ്.',
    marathi: 'हे अ‍ॅप अशा लोकांसाठी उपयुक्त आहे जे रोजच्या शुभेच्छा शेअर करतात, छोट्या व्यवसायांसाठी पोस्टर्स बनवतात, भक्ती किंवा विशेष प्रसंगांच्या पोस्ट्स प्रकाशित करतात किंवा स्वतःच्या नावाच्या किंवा व्यावसायिक ओळखीच्या पोस्टर्सची इच्छा ठेवतात.',
    gujarati: 'આ એપ એવા લોકો માટે ઉપયોગી છે જેઓ દૈનિક શુભેચ્છાઓ શેર કરે છે, નાના વ્યવસાયો માટે પોસ્ટર બનાવે છે, ભક્તિ અથવા પ્રસંગ આધારિત પોસ્ટ્સ પ્રકાશિત કરે છે, અથવા પોતાના નામ કે વ્યવસાયિક ઓળખ સાથે પર્સનલાઇઝ્ડ પોસ્ટર ઇચ્છે છે.',
    bengali: 'এই অ্যাপটি তাদের জন্য অত্যন্ত দরকারী যারা প্রতিদিনের শুভেচ্ছা শেয়ার করেন, ছোট ব্যবসার জন্য পোস্টার তৈরি করেন, ভক্তি বা বিশেষ অনুষ্ঠানের পোস্ট প্রকাশ করেন, অথবা নিজের নাম ও ব্যবসায়িক পরিচয়ে ব্যক্তিগতকৃত পোস্টার চান।',
    punjabi: 'ਇਹ ਐਪ ਉਹਨਾਂ ਲੋਕਾਂ ਲਈ ਲਾਭਦਾਇਕ ਹੈ ਜੋ ਰੋਜ਼ਾਨਾ ਸ਼ੁਭਕਾਮਨਾਵਾਂ ਸਾਂਝੀਆਂ ਕਰਦੇ ਹਨ, ਛੋਟੇ ਕਾਰੋਬਾਰਾਂ ਲਈ ਪੋਸਟਰ ਬਣਾਉਂਦੇ ਹਨ, ਭਗਤੀ ਜਾਂ ਮੌਕੇ-ਅਧਾਰਿਤ ਪੋਸਟਾਂ ਪ੍ਰਕਾਸ਼ਿਤ ਕਰਦੇ ਹਨ, ਜਾਂ ਆਪਣੇ ਨਾਮ ਜਾਂ ਕਾਰੋਬਾਰੀ ਪਛਾਣ ਵਾਲੇ ਪੋਸਟਰ ਚਾਹੁੰਦੇ ਹਨ।',
    odia: 'ଦୈନନ୍ଦିନ ଶୁଭେଚ୍ଛା ସେୟାର କରୁଥିବା ଲୋକଙ୍କ ପାଇଁ, ଛୋଟ ବ୍ୟବସାୟ ପାଇଁ ପୋଷ୍ଟର ତିଆରି କରୁଥିବା ବ୍ୟକ୍ତିଙ୍କ ପାଇଁ, ଭକ୍ତି କିମ୍ବା ବିଶେଷ ଅବସରର ପୋଷ୍ଟ ପ୍ରକାଶ କରୁଥିବା ବ୍ୟକ୍ତିଙ୍କ ପାଇଁ କିମ୍ବା ନିଜ ନାମ ଓ ବ୍ୟବସାୟ ପରିଚୟ ସହିତ ପୋଷ୍ଟର ଚାହୁଁଥିବା ସମସ୍ତଙ୍କ ପାଇଁ ଏହି ଆପ୍ ଉପଯୋଗୀ।',
    assamese: 'দৈনন্দিন শুভেচ্ছা শ্বেয়াৰ কৰাসকলৰ বাবে, ক্ষুদ্ৰ ব্যৱসায়ৰ বাবে পোষ্টাৰ তৈয়াৰ কৰাসকলৰ বাবে, ভক্তি বা বিশেষ অনুষ্ঠানৰ পোষ্ট প্ৰকাশ কৰাসকলৰ বাবে নাইবা নিজৰ নাম আৰু ব্যৱসায়িক পৰিচয় সম্বলিত পোষ্টাৰ বিচৰা সকলোৰে বাবে এই এপটো অতি উপযোগী।',
    konkani: 'ದಿಸಾಳೆಂ ಶುಭಾಶಯ್ ಶೇರ್ ಕರ್ತೆಲ್ಯಾಂಕ್, ಲ್ಹಾನ್ ವ್ಯವಹಾರಾಂಕ್ ಪೋಸ್ಟರ್ ತಯಾರ್ ಕರ್ತೆಲ್ಯಾಂಕ್, ಭಕ್ತಿ ಯಾ ಸಂದರ್ಭಾಚೆ ಪೋಸ್ಟ್ ಪ್ರಕಟ್ ಕರ್ತೆಲ್ಯಾಂಕ್ ಆನಿ ಆಪ್ಲ್ಯಾ ನಾಂವಾನ್ ಪೋಸ್ಟರ್ ಜಾಯ್ ಮ್ಹಣ್ ಆಶೆತೆಲ್ಯಾಂಕ್ ಹೆಂ ಆ್ಯಪ್ ಭೋವ್ ಉಪಯುಕ್ತ್.',
    nepali: 'दैनिक शुभकामना सेयर गर्नेहरू, साना व्यवसायहरूका लागि पोस्टर बनाउनेहरू, भक्ति वा अवसरमा आधारित पोस्टहरू प्रकाशित गर्नेहरू, वा आफ्नै नाम वा व्यावसायिक पहिचानसहितको पोस्टर चाहनेहरूका लागि यो एप निकै उपयोगी छ।',
    meitei: 'নোংমগী য়াইফ-পাউজেল শিয়র তৌবা মীওইশিং, অপীকপা লল্লোন-ইতিক্কীদমক পোস্তর শেম্বা মীওইশিং, শেবা-থাওইবা নত্রগা থৌরমশিংগী পোস্তশিং ফোঙবা মীওইশিং নত্রগা মশাগী মিং অমসুং লল্লোন-ইতিক্কী শক্তাক্কা লোয়ননা পোস্তর পাম্বা পুম্নমক্কীদমক এপ অসিনা কান্নবা পীরি।',
    mizo: 'Ni tin chibai bukna thehdarh thinte, sumdawnna te tak te te tana poster siam thinte, Pathian thu leh hun pawimawh thuziak chhuah thinte, emaw mahni hming leh sumdawnna hming chuantir duh zawng zawng tan he app hi a tangkai em em a ni.',
    kashmiri: 'یہِ ایپھ چھُ تِمن لوٗکن باپتھ کارگر یِم پرٛؠتھ دۄہ مۆبارکبادی شیئر کَران چھِ، لۄکٹؠن کٲروبارن باپتھ پوسٹر بناوان چھِ، بھکتِی یا موقَس مُطٲبِق پوسٹ شایع کَران چھِ، یا پننِس ناوس یا کٲروبٲری پٔھچانَس سٟتؠ پوسٹر یژھان چھِ।',
    ladakhi: 'ཉིན་ལྟར་བཀྲ་ཤིས་བདེ་ལེགས་བརྒྱུད་སྤེལ་བྱེད་མཁན། ཚོང་ལས་ཆུང་ངུའི་དོན་དུ་པོསྚར་བཟོ་མཁན། ཆོས་ཕྱོགས་སམ་དུས་སྟོན་གྱི་པོསྚར་སྤེལ་མཁན། ཡང་ན་རང་གི་མིང་དང་ཚོང་རྟགས་ཅན་གྱི་པོསྚར་དགོས་མཁན་ཡོངས་ལ་ཨེཔ་འདི་ཤིན་ཏུ་ཕན་ཐོགས་ཆེ།',
  );

  String get featuresTitle => strings.localized(
    telugu: 'ప్రధాన ఫీచర్లు',
    english: 'Main features',
    hindi: 'मुख्य विशेषताएं',
    tamil: 'முக்கிய அம்சங்கள்',
    kannada: 'ಮುಖ್ಯ ವೈಶಿಷ್ಟ್ಯಗಳು',
    malayalam: 'പ്രധാന സവിശേഷതകൾ',
    marathi: 'मुख्य वैशिष्ट्ये',
    gujarati: 'મુખ્ય વિશેષતાઓ',
    bengali: 'প্রধান বৈশিষ্ট্যসমূহ',
    punjabi: 'ਮੁੱਖ ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ',
    odia: 'ମୁଖ୍ୟ ବୈଶିଷ୍ଟ୍ୟଗୁଡ଼ିକ',
    assamese: 'মুখ্য সুবিধাসমূহ',
    konkani: 'ಮುಖೆಲ್ ವೈಶಿಷ್ಟ್ಯಾಂ',
    nepali: 'मुख्य सुविधाहरू',
    meitei: 'মরুওইবা ফীচরশিং',
    mizo: 'Hmanraw pawimawhte',
    kashmiri: 'اہم خَصوصِیات',
    ladakhi: 'གཙོ་བོའི་ཁྱད་ཆོས།',
  );

  List<String> get featureItems => <String>[
    strings.localized(
      telugu: 'కేటగిరీల వారీగా పోస్టర్లను బ్రౌజ్ చేసి తగిన డిజైన్‌ను వేగంగా ఎంచుకోవచ్చు.',
      english: 'Browse posters by category and quickly choose a suitable design.',
      hindi: 'श्रेणी के अनुसार पोस्टर ब्राउज़ करें और जल्दी से उपयुक्त डिज़ाइन चुनें।',
      tamil: 'பிரிவுகளின்படி போஸ்டர்களைப் பார்த்து பொருத்தமான வடிவமைப்பை விரைவாகத் தேர்வுசெய்யலாம்.',
      kannada: 'ವರ್ಗಗಳ ಪ್ರಕಾರ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಬ್ರೌಸ್ ಮಾಡಿ ಸೂಕ್ತವಾದ ವಿನ್ಯಾಸವನ್ನು ತ್ವರಿತವಾಗಿ ಆಯ್ಕೆಮಾಡಿ.',
      malayalam: 'വിഭാഗങ്ങൾ തിരിച്ച് പോസ്റ്ററുകൾ ബ്രൗസ് ചെയ്ത് അനുയോജ്യമായ ഡിസൈൻ വേഗത്തിൽ തിരഞ്ഞെടുക്കാം.',
      marathi: 'वर्गवारीनुसार पोस्टर्स ब्राउझ करा आणि योग्य डिझाइन वेगाने निवडा.',
      gujarati: 'શ્રેણી મુજબ પોસ્ટર્સ બ્રાઉઝ કરો અને ઝડપથી યોગ્ય ડિઝાઇન પસંદ કરો.',
      bengali: 'বিভাগ অনুযায়ী পোস্টার ব্রাউজ করুন এবং দ্রুত উপযুক্ত ডিজাইন বেছে নিন।',
      punjabi: 'ਸ਼੍ਰੇਣੀ ਅਨੁਸਾਰ ਪੋਸਟਰ ਬ੍ਰਾਊਜ਼ ਕਰੋ ਅਤੇ ਜਲਦੀ ਢੁਕਵਾਂ ਡਿਜ਼ਾਈਨ ਚੁਣੋ।',
      odia: 'ବିଭାଗ ଅନୁଯାୟୀ ପୋଷ୍ଟର ବ୍ରାଉଜ୍ କରନ୍ତୁ ଏବଂ ଉପଯୁକ୍ତ ଡିଜାଇନ୍ ଶୀଘ୍ର ବାଛନ୍ତୁ।',
      assamese: 'শ্ৰেণী অনুসৰি পোষ্টাৰ ব্ৰাউজ কৰক আৰু দ্ৰুতভাৱে উপযুক্ত ডিজাইন বাছক।',
      konkani: 'ವರ್ಗಾಂ ಪರ್ಮಾಣೆಂ ಪೋಸ್ಟರ್ ಬ್ರೌಸ್ ಕರ್ನ್ ಸಾರ್ಕೆಂ ಡಿಸೈನ್ ವೆಗಿಂ ವಿಂಚಾ.',
      nepali: 'श्रेणी अनुसार पोस्टरहरू ब्राउज गर्नुहोस् र चाँडै उपयुक्त डिजाइन छनोट गर्नुहोस्।',
      meitei: 'কেটাগোরিগী মতুংඉন্না পোস্তরশিং য়েংথোক্তুনা চুম্বা দিজাইন য়াংনা খনগৎলু।',
      mizo: 'Chi hrang hrang zelah poster zawng la, duhthusam design rang takin thlang rawh.',
      kashmiri: 'زمرٕ وار پوسٹر برٛاوز کٔریو تہٕ مناسِب ڈیزائن تیزی سان ژٲریو۔',
      ladakhi: 'དབྱེ་བའི་ཐོག་ནས་པོསྚར་རྣམས་བལྟས་ཏེ་འོས་ཤིང་འཚམ་པའི་བཀོད་པ་མགྱོགས་པོར་འདེམས།',
    ),
    strings.localized(
      telugu: 'రాష్ట్రం లేదా కేంద్రపాలిత ప్రాంతాన్ని ఎంచుకున్న తర్వాత, యాప్ ఆ ప్రాంత భాషకు మారి రాజకీయ పార్టీలతో సహా సంబంధిత కేటగిరీలను చూపిస్తుంది.',
      english: 'After selecting a State or Union Territory, the app switches to the region language and shows relevant categories, including political party categories.',
      hindi: 'राज्य या केंद्र शासित प्रदेश चुनने के बाद, ऐप उस क्षेत्र की भाषा में बदल जाता है और राजनीतिक दलों सहित प्रासंगिक श्रेणियां दिखाता है।',
      tamil: 'மாநிலம் அல்லது யூனியன் பிரதேசத்தைத் தேர்ந்தெடுத்ததும், செயலி அந்த பிராந்திய மொழிக்கு மாறி அரசியல் கட்சிகள் உள்ளிட்ட பொருத்தமான பிரிவுகளைக் காட்டுகிறது.',
      kannada: 'ರಾಜ್ಯ ಅಥವಾ ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶವನ್ನು ಆಯ್ಕೆಮಾಡಿದ ನಂತರ, ಆ್ಯಪ್ ಆ ಪ್ರದೇಶದ ಭಾಷೆಗೆ ಬದಲಾಗಿ ರಾಜಕೀಯ ಪಕ್ಷಗಳ ವರ್ಗಗಳನ್ನೂ ಒಳಗೊಂಡಂತೆ ಸಂಬಂಧಿತ ವರ್ಗಗಳನ್ನು ತೋರಿಸುತ್ತದೆ.',
      malayalam: 'സംസ്ഥാനമോ കേന്ദ്രഭരണ പ്രദേശമോ തിരഞ്ഞെടുത്ത ശേഷം, ആപ്പ് പ്രസ്തുത പ്രാദേശിക ഭാഷയിലേക്ക് മാറുകയും രാഷ്ട്രീയ പാർട്ടികളുടെ വിഭാഗങ്ങൾ ഉൾപ്പെടെ കാണിക്കുകയും ചെയ്യുന്നു.',
      marathi: 'राज्य किंवा केंद्रशासित प्रदेश निवडल्यानंतर, अ‍ॅप प्रादेशिक भाषेत बदलते आणि राजकीय पक्षांच्या श्रेणींसह संबंधित श्रेणी दाखवते.',
      gujarati: 'રાજ્ય અથવા કેન્દ્રશાસિત પ્રદેશ પસંદ કર્યા પછી, એપ પ્રાદેશિક ભાષામાં ફેરવાય છે અને રાજકીય પક્ષો સહિત સંબંધિત શ્રેણીઓ દર્શાવે છે.',
      bengali: 'রাজ্য বা কেন্দ্রশাসিত অঞ্চল নির্বাচন করার পর অ্যাপটি আঞ্চলিক ভাষায় পরিবর্তিত হয় এবং রাজনৈতিক দল সহ প্রাসঙ্গিক বিভাগ দেখায়।',
      punjabi: 'ਰਾਜ ਜਾਂ ਕੇਂਦਰ ਸ਼ਾਸਿਤ ਪ੍ਰਦੇਸ਼ ਚੁਣਨ ਤੋਂ ਬਾਅਦ, ਐਪ ਖੇਤਰੀ ਭਾਸ਼ਾ ਵਿੱਚ ਬਦਲ ਜਾਂਦੀ ਹੈ ਅਤੇ ਸਿਆਸੀ ਪਾਰਟੀਆਂ ਸਮੇਤ ਸੰਬੰਧਿਤ ਸ਼੍ਰੇਣੀਆਂ ਦਿਖਾਉਂਦੀ ਹੈ।',
      odia: 'ରାଜ୍ୟ କିମ୍ବା କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ ବାଛିବା ପରେ, ଆପ୍ ସେହି ଅଞ୍ଚଳ ଭାଷାରେ ପରିବର୍ତ୍ତିତ ହୋଇ ରାଜନୈତିକ ଦଳ ସମେତ ପ୍ରାସଙ୍ଗିକ ବିଭାଗ ଦେଖାଏ।',
      assamese: 'ৰাজ্য বা কেন্দ্ৰীয় শাসিত অঞ্চল বাছনি কৰাৰ পাছত, এপে সেই অঞ্চলৰ ভাষালৈ সলনি হয় আৰু ৰাজনৈতিক দলসমূহকে ধৰি প্ৰাসংগিক শ্ৰেণীসমূহ দেখুৱায়।',
      konkani: 'ರಾಜ್ಯ್ ಯಾ ಕೇಂದ್ರ ಶಾಸಿತ್ ಪ್ರದೇಶ್ ವಿಂಚಿಲ್ಯಾ ಉಪ್ರಾಂತ್, ಆ್ಯಪ್ ತ್ಯಾ ಪ್ರಾಂತ್ಯಾಚ್ಯಾ ಭಾಶೆಕ್ ಬದ್ಲುನ್ ರಾಜಕೀಯ್ ಪಕ್ಷಾಂ ಸಾಂಗಾತಾ ಸಂಬಂಧಿತ್ ವರ್ಗಾಂ ದಾಕಯ್ತಾ.',
      nepali: 'राज्य वा केन्द्रशासित प्रदेश चयन गरेपछि, एप क्षेत्रीय भाषामा परिवर्तन हुन्छ र राजनीतिक दलहरू सहित सान्दर्भिक श्रेणीहरू देखाउँछ।',
      meitei: 'স্তেত নত্রগা য়ুনিয়ন তেরিতোরি খনরবা মতুংদা, এপ অসিনা মফমদুগী লোলদা ওনখিগনি অমসুং রাজনিতিক পার্তিশিং য়াওনা মরি লৈনবা কেটাগোরিশিং উৎলগনি।',
      mizo: 'State emaw Union Territory thlan hnuah, app chuan chumi bial tawng chu hmangin political party huam telin category pawimawhte a tilang ang.',
      kashmiri: 'رِیاسَت یا مرکز کِس زیرِ اِنتظام علاقَس ژارنہٕ پتہٕ چھُ ایپھ علاقٲیی زبانہِ مَنٛز تبدیٖل گَژھان تہٕ سیٲسی پارٹین سٟتؠ وابَستہٕ زمرٕ ہٲوان۔',
      ladakhi: 'མངའ་སྡེའམ་དབུས་གཞུང་ཁྱབ་ཁོངས་བདམས་རྗེས། ཨེཔ་དེ་ས་གནས་ཀྱི་སྐད་རིགས་སུ་འགྱུར་ཞིང་སྲིད་དོན་ཚོགས་པ་ཚུད་པའི་འབྲེལ་ཡོད་དབྱེ་བ་རྣམས་སྟོན།',
    ),
    strings.localized(
      telugu: 'కమ్యూనిటీ అప్‌లోడ్ ద్వారా ఇమేజ్ లేదా కొటేషన్‌ను మేనేజర్ సమీక్షకు పంపవచ్చు; ఆమోదించిన పోస్టర్లు సంబంధిత కేటగిరీలో కనిపిస్తాయి.',
      english: 'Community upload lets users send an image, quote, or both for manager review; approved posters appear in the appropriate category.',
      hindi: 'कम्युनिटी अपलोड उपयोगकर्ताओं को समीक्षा के लिए छवि या उद्धरण भेजने की सुविधा देता है; स्वीकृत पोस्टर संबंधित श्रेणी में दिखाई देते हैं।',
      tamil: 'சமூக பதிவேற்றம் மூலம் பயனர்கள் படம் அல்லது மேற்கோளை மேலாளர் மதிப்பாய்வுக்கு அனுப்பலாம்; அங்கீகரிக்கப்பட்டவை பொருத்தமான பிரிவில் தோன்றும்.',
      kannada: 'ಕಮ್ಯುನಿಟಿ ಅಪ್‌ಲೋಡ್ ಮೂಲಕ ಚಿತ್ರ ಅಥವಾ ಉಲ್ಲೇಖವನ್ನು ಪರಿಶೀಲನೆಗೆ ಕಳುಹಿಸಬಹುದು; ಅನುಮೋದಿತ ಪೋಸ್ಟರ್‌ಗಳು ಸೂಕ್ತ ವರ್ಗದಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.',
      malayalam: 'കമ്മ്യൂണിറ്റി അപ്‌ലോഡ് വഴി ചിത്രമോ ഉദ്ധരണിയോ മാനേജറുടെ പരിശോധനയ്ക്ക് അയയ്ക്കാം; അംഗീകരിച്ചവ ബന്ധപ്പെട്ട കാറ്റഗറിയിൽ ലഭ്യമാകും.',
      marathi: 'कम्युनिटी अपलोडद्वारे वापरकर्ते प्रतिमा किंवा कोट मॅनेजरच्या पुनरावलोकनासाठी पाठवू शकतात; मंजूर पोस्टर्स योग्य श्रेणीत दिसतात.',
      gujarati: 'કમ્યુનિટી અપલોડ વપરાશકર્તાઓને મેનેજર સમીક્ષા માટે છબી અથવા અવતરણ મોકલવા દે છે; મંજૂર પોસ્ટર્સ યોગ્ય શ્રેણીમાં દેખાય છે.',
      bengali: 'কমিউনিটি আপলোডের মাধ্যমে ছবি বা উদ্ধৃতি পর্যালোচনার জন্য পাঠানো যায়; অনুমোদিত পোস্টার সংশ্লিষ্ট বিভাগে প্রদর্শিত হয়।',
      punjabi: 'ਕਮਿਊਨਿਟੀ ਅੱਪਲੋਡ ਰਾਹੀਂ ਤਸਵੀਰ ਜਾਂ ਵਿਚਾਰ ਸਮੀਖਿਆ ਲਈ ਭੇਜੇ ਜਾ ਸਕਦੇ ਹਨ; ਮਨਜ਼ੂਰ ਪੋਸਟਰ ਸਹੀ ਸ਼੍ਰੇਣੀ ਵਿੱਚ ਦਿਖਾਈ ਦਿੰਦੇ ਹਨ।',
      odia: 'କମ୍ୟୁନିଟି ଅପଲୋଡ୍ ମାଧ୍ୟମରେ ଫଟୋ କିମ୍ବା ଉଦ୍ଧୃତି ସମୀକ୍ଷା ପାଇଁ ପଠାଯାଇପାରିବ; ଅନୁମୋଦିତ ପୋଷ୍ଟରଗୁଡ଼ିକ ସଠିକ୍ ବିଭାଗରେ ଦେଖାଯାଏ।',
      assamese: 'কমিউনিটি আপলোডৰ জৰিয়তে ছবি বা উদ্ধৃতি পৰ্যালোচনাৰ বাবে পঠিয়াব পাৰি; অনুমোদিত পোষ্টাৰসমূহ সঠিক শ্ৰেণীত দেখা যায়।',
      konkani: 'ಕಮ್ಯುನಿಟಿ ಅಪ್‌ಲೋಡ್ ಮುಖಾಂತ್ರ್ ಫೋಟೋ ಯಾ ಕೋಟ್ ತಪಾಸ್ಣೆಕ್ ಧಾಡುಂಕ್ ಜಾತಾ; ಮಂಜೂರ್ ಜಾಲ್ಲೆ ಪೋಸ್ಟರ್ ಸಾರ್ಕ್ಯಾ ವರ್ಗಾಂತ್ ದಿಸ್ತಾತ್.',
      nepali: 'समुदाय अपलोडले प्रयोगकर्ताहरूलाई समीक्षाको लागि छवि वा उद्धरण पठाउन दिन्छ; स्वीकृत पोस्टरहरू उपयुक्त श्रेणीमा देखिन्छन्।',
      meitei: 'কম্যুনিতি অপলোদনা য়ুজরশিংদা মমি নত্রগা কোত রিভ্যুগীদমক থাবা য়াহল্লি; অয়াবা পীরবা পোস্তরশিং চুনবা কেটাগোরিদা থেংনগনি।',
      mizo: 'Community upload hmangin thlalak emaw thu ziak manager endik turin a thehluh theih a; pawm tawhte chu category dik takah a lang ang.',
      kashmiri: 'کمیونٹی اَپلوڈ ذٔریعہٕ ہؠکن صارِف تصویر یا اَقوال ریویو باپتھ سوزِتھ؛ منظور گژھن وٲلؠ پوسٹر چھِ مُتعلقہٕ زمرَس مَنٛز ہٲوان۔',
      ladakhi: 'མི་སྡེའི་ཡར་འཇུག་བརྒྱུད་ནས་འདྲ་པར་རམ་ཚིག་དུམ་ཞིབ་བཤེར་དོན་དུ་གཏོང་ཐུབ། ཆོག་མཆན་ཐོབ་པའི་པོསྚར་རྣམས་འོས་པའི་དབྱེ་བའི་ནང་འཆར།',
    ),
    strings.localized(
      telugu: 'పోస్టర్ ప్రొఫైల్, వ్యాపార పేరు, ఫోటో మరియు వాట్సాప్ వివరాలను సేవ్ చేసుకోండి.',
      english: 'Save poster profile, business name, photo, and WhatsApp details.',
      hindi: 'पोस्टर प्रोफाइल, व्यावसायिक नाम, फोटो और व्हाट्सएप विवरण सहेजें।',
      tamil: 'போஸ்டர் சுயவிவரம், வணிகப் பெயர், புகைப்படம் மற்றும் வாட்ஸ்அப் விவரங்களைச் சேமிக்கவும்.',
      kannada: 'ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್, ವ್ಯಾಪಾರ ಹೆಸರು, ಫೋಟೋ ಮತ್ತು ವಾಟ್ಸಾಪ್ ವಿವರಗಳನ್ನು ಉಳಿಸಿ.',
      malayalam: 'പോസ്റ്റർ പ്രൊഫൈൽ, ബിസിനസ്സ് പേര്, ഫോട്ടോ, വാട്ട്‌സ്ആപ്പ് വിവരങ്ങൾ എന്നിവ സേവ് ചെയ്യുക.',
      marathi: 'पोस्टर प्रोफाइल, व्यवसायाचे नाव, फोटो आणि व्हॉट्सअ‍ॅप तपशील सेव्ह करा.',
      gujarati: 'પોસ્ટર પ્રોફાઇલ, વ્યવસાયનું નામ, ફોટો અને વ્હોટ્સએપ વિગતો સાચવો.',
      bengali: 'পোস্টার প্রোফাইল, ব্যবসার নাম, ছবি এবং হোয়াটসঅ্যাপ বিবরণ সংরক্ষণ করুন।',
      punjabi: 'ਪੋਸਟਰ ਪ੍ਰੋਫਾਈਲ, ਕਾਰੋਬਾਰੀ ਨਾਮ, ਫੋਟੋ ਅਤੇ ਵਟਸਐਪ ਵੇਰਵੇ ਸੁਰੱਖਿਅਤ ਕਰੋ।',
      odia: 'ପୋଷ୍ଟର ପ୍ରୋଫାଇଲ୍, ବ୍ୟବସାୟ ନାମ, ଫଟୋ ଏବଂ ହ୍ୱାଟ୍ସଆପ୍ ବିବରଣୀ ସେଭ୍ କରନ୍ତୁ।',
      assamese: 'পোষ্টাৰ প্ৰʼফাইল, ব্যৱসায়িক নাম, ফটো আৰু হোৱাটছএপৰ তথ্য সংৰক্ষণ কৰক।',
      konkani: 'ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್, ವ್ಯವಹಾರಾಚೆಂ ನಾಂವ್, ಫೋಟೋ ಆನಿ ವಾಟ್ಸಾಪ್ ವಿವರಾಂ ಸಾಂಭಾಳಾ.',
      nepali: 'पोस्टर प्रोफाइल, व्यापार नाम, फोटो र व्हाट्सएप विवरण सुरक्षित गर्नुहोस्।',
      meitei: 'পোস্তর প্রোফাইল, লল্লোন-ইতিক্কী মিং, ফোতো অমসুং ৱাত্সএপকী ৱারোলশিং সেভ তৌরো।',
      mizo: 'Poster profile, sumdawnna hming, thlalak leh WhatsApp details vawng tha rawh.',
      kashmiri: 'پوسٹر پروفائل، کٲروبٲری ناو، فوٹو تہٕ واٹس ایپ تفصیلات کٔریو مَحفوٗظ۔',
      ladakhi: 'པོསྚར་གྱི་གསལ་བཤད། ཚོང་ལས་ཀྱི་མིང་། འདྲ་པར་དང་ཝཊས་ཨེཔ་གནས་ཚུལ་ཉར་ཚགས་གྱིས།',
    ),
    strings.localized(
      telugu: 'ఎడిటర్‌లో ఎంచుకున్న టెంప్లేట్‌ను అనుకూలీకరించి, ఆపై సేవ్ చేయండి లేదా షేర్ చేయండి.',
      english: 'Customize the selected template in the editor, then save or share it.',
      hindi: 'एडिटर में चुने गए टेम्प्लेट को कस्टमाइज़ करें, फिर उसे सेव या शेयर करें।',
      tamil: 'எடிட்டரில் தேர்ந்தெடுக்கப்பட்ட டெம்ப்ளேட்டைத் தனிப்பயனாக்கி, பின் சேமிக்கவும் அல்லது பகிரவும்.',
      kannada: 'ಎಡಿಟರ್‌ನಲ್ಲಿ ಆಯ್ಕೆಮಾಡಿದ ಟೆಂಪ್ಲೇಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ, ನಂತರ ಅದನ್ನು ಉಳಿಸಿ ಅಥವಾ ಹಂಚಿಕೊಳ್ಳಿ.',
      malayalam: 'എഡിറ്ററിൽ തിരഞ്ഞെടുത്ത ടെംപ്ലേറ്റ് മാറ്റങ്ങൾ വരുത്തി സേവ് ചെയ്യുകയോ പങ്കിടുകയോ ചെയ്യുക.',
      marathi: 'एडिटरमध्ये निवडलेला टेम्पलेट कस्टमाइझ करा, नंतर सेव्ह किंवा शेअर करा.',
      gujarati: 'એડિટરમાં પસંદ કરેલ નમૂનાને કસ્ટમાઇઝ કરો, પછી તેને સાચવો અથવા શેર કરો.',
      bengali: 'এডিটরে নির্বাচিত টেমপ্লেটটি কাস্টমাইজ করুন, তারপর সংরক্ষণ বা শেয়ার করুন।',
      punjabi: 'ਐਡੀਟਰ ਵਿੱਚ ਚੁਣੇ ਹੋਏ ਟੈਂਪਲੇਟ ਨੂੰ ਅਨੁਕੂਲਿਤ ਕਰੋ, ਫਿਰ ਇਸਨੂੰ ਸੁਰੱਖਿਅਤ ਜਾਂ ਸਾਂਝਾ ਕਰੋ।',
      odia: 'ଏଡିଟର୍‌ରେ ମନୋନୀତ ଟେମ୍ପଲେଟ୍ କଷ୍ଟମାଇଜ୍ କରନ୍ତୁ, ତା’ପରେ ଏହାକୁ ସେଭ୍ କିମ୍ବା ସେୟାର କରନ୍ତୁ।',
      assamese: 'এডিটৰত নিৰ্বাচিত টেমপ্লেটটো কাষ্টমাইজ কৰক, তাৰ পাছত সংৰক্ষণ বা শ্বেয়াৰ কৰক।',
      konkani: 'ಎಡಿಟರಾಂತ್ ವಿಂಚ್ಲೊ ಟೆಂಪ್ಲೇಟ್ ಕಸ್ಟಮೈಜ್ ಕರಾ, ಉಪ್ರಾಂತ್ ಸಾಂಭಾಳಾ ಯಾ ಶೇರ್ ಕರಾ.',
      nepali: 'सम्पादकमा चयन गरिएको टेम्प्लेट अनुकूलित गर्नुहोस्, त्यसपछि यसलाई बचत वा सेयर गर्नुहोस्।',
      meitei: 'এদিতরদা খনরবা তেমপ্লেত অদু শেমদোক-শেমজিন তৌরো, অদুগা সেভ নত্রগা শিয়র তৌরো।',
      mizo: 'Editor-ah template thlan chu i duhdanin siamrem la, chumi hnuah save la emaw share rawh.',
      kashmiri: 'ایڈیٹرس مَنٛز کٔریو مُنتخَب ٹیمپلیٹ کسٹمائز، پتہٕ کٔریو مَحفوٗظ یا شیئر۔',
      ladakhi: 'ཞུ་དག་ཆས་ནང་བདམས་པའི་དཔེ་གཞི་ལ་བཟོ་བཅོས་གྱིས་ལ། དེ་ནས་ཉར་ཚགས་སམ་བརྒྱུད་སྤེལ་གྱིས།',
    ),
    strings.localized(
      telugu: 'నోటిఫికేషన్లు, అనుమతులు, సహాయం, ప్రైవసీ పాలసీ మరియు నిబంధనలు యాప్‌లోనే అందుబాటులో ఉంటాయి.',
      english: 'Notifications, permissions, help, privacy policy, and terms are available inside the app.',
      hindi: 'नोटिफिकेशन, अनुमतियां, सहायता, गोपनीयता नीति और शर्तें ऐप के अंदर उपलब्ध हैं।',
      tamil: 'அறிவிப்புகள், அனுமதிகள், உதவி, தனியுரிமைக் கொள்கை மற்றும் விதிமுறைகள் செயலியின் உள்ளே உள்ளன.',
      kannada: 'ಅಧಿಸೂಚನೆಗಳು, ಅನುಮತಿಗಳು, ಸಹಾಯ, ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ನಿಯಮಗಳು ಆ್ಯಪ್‌ನಲ್ಲಿ ಲಭ್ಯವಿವೆ.',
      malayalam: 'അറിയിപ്പുകൾ, അനുമതികൾ, സഹായം, സ്വകാര്യതാ നയം, നിബന്ധനകൾ എന്നിവ ആപ്പിൽ ലഭ്യമാണ്.',
      marathi: 'सूचना, परवानग्या, मदत, गोपनीयता धोरण आणि अटी अ‍ॅपमध्ये उपलब्ध आहेत.',
      gujarati: 'સૂચનાઓ, પરવાનગીઓ, સહાય, ગોપનીયતા નીતિ અને શરતો એપમાં ઉપલબ્ધ છે.',
      bengali: 'বিজ্ঞপ্তি, অনুমতি, সাহায্য, গোপনীয়তা নীতি এবং শর্তাবলী অ্যাপের ভিতরে উপলব্ধ।',
      punjabi: 'ਸੂਚਨਾਵਾਂ, ਇਜਾਜ਼ਤਾਂ, ਮਦਦ, ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਅਤੇ ਨਿਯਮ ਐਪ ਦੇ ਅੰਦਰ ਉਪਲਬਧ ਹਨ।',
      odia: 'ବିଜ୍ଞପ୍ତି, ଅନୁମତି, ସହାୟତା, ଗୋପନୀୟତା ନୀତି ଏବଂ ସର୍ତ୍ତାବଳୀ ଆପ୍ ମଧ୍ୟରେ ଉପଲବ୍ଧ।',
      assamese: 'বিজ্ঞপ্তি, অনুমতি, সহায়, গোপনীয়তা নীতি আৰু চৰ্তাৱলী এপৰ ভিতৰতে উপলব্ধ।',
      konkani: 'ನೋಟಿಫಿಕೇಶನ್ಸ್, ಪರ್ಮಿಶನ್ಸ್, ಆಧಾರ್, ಪ್ರೈವಸಿ ಪಾಲಿಸಿ ಆನಿ ನಿಬಂಧನಾಂ ಆ್ಯಪಾಂತ್ ಲಭ್ಯ್ ಆಸಾತ್.',
      nepali: 'सूचनाहरू, अनुमतिहरू, मद्दत, गोपनीयता नीति र सर्तहरू एप भित्र उपलब्ध छन्।',
      meitei: 'নোতিফিকেসনশিং, অয়াবশিং, মতেং, প্রাইভেসি পোলিসি অমসুং তর্মশিং এপ মনুংদা ফংই।',
      mizo: 'Hriattirnate, phalnate, tanpuina, privacy policy leh terms zawng zawng app chhungah a awm vek.',
      kashmiri: 'اطلاعات، اجازت نامہٕ، مَدَتھ، رازدٲری ہٕنٛز پالیسی تہٕ شرائط چھِ ایپس مَنٛز دٔستیاب۔',
      ladakhi: 'བརྡ་ཐོ། ཆོག་མཆན། རོགས་རམ། གསང་རྒྱའི་སྲིད་ཇུས་དང་ཆart་རྐྱེན་རྣམས་ཨེཔ་ནང་དུ་ཡོད།',
    ),
  ];

  String get flowTitle => strings.localized(
    telugu: 'యాప్ ఎలా పనిచేస్తుంది',
    english: 'How the app works',
    hindi: 'ऐप कैसे काम करता है',
    tamil: 'செயலி எவ்வாறு செயல்படுகிறது',
    kannada: 'ಆ್ಯಪ್ ಹೇಗೆ ಕಾರ್ಯನಿರ್ವಹಿಸುತ್ತದೆ',
    malayalam: 'ആപ്പ് എങ്ങനെ പ്രവർത്തിക്കുന്നു',
    marathi: 'अ‍ॅप कसे कार्य करते',
    gujarati: 'એપ કેવી રીતે કાર્ય કરે છે',
    bengali: 'অ্যাপটি কীভাবে কাজ করে',
    punjabi: 'ਐਪ ਕਿਵੇਂ ਕੰਮ ਕਰਦੀ ਹੈ',
    odia: 'ଆପ୍ କିପରି କାର୍ଯ୍ୟ କରେ',
    assamese: 'এপটোৱে কেনেকৈ কাম কৰে',
    konkani: 'ಆ್ಯಪ್ ಕಶೆಂ ಕಾಮ್ ಕರ್ತಾ',
    nepali: 'एपले कसरी काम गर्छ',
    meitei: 'এপ অসিনা করম্না থবক তৌরিবা',
    mizo: 'App kalhmang',
    kashmiri: 'ایپھ کِتھکٔن چھُ کٲم کَران',
    ladakhi: 'ཨེཔ་འདིས་ཇི་ལྟར་ཕྱག་ལས་གནང་ངམ།',
  );

  List<String> get flowItems => <String>[
    strings.localized(
      telugu: 'లాగిన్ అయిన తర్వాత, హోమ్ స్క్రీన్‌లో పోస్టర్ కేటగిరీలు మరియు డిజైన్లు కనిపిస్తాయి.',
      english: 'After login, the home screen shows poster categories and designs.',
      hindi: 'लॉगिन के बाद, होम स्क्रीन पर पोस्टर श्रेणियां और डिज़ाइन दिखाई देते हैं।',
      tamil: 'உள்நுழைந்ததும், முகப்புத் திரையில் போஸ்டர் பிரிவுகளும் வடிவமைப்புகளும் காட்டப்படும்.',
      kannada: 'ಲಾಗಿನ್ ಆದ ನಂತರ, ಮುಖಪುಟದಲ್ಲಿ ಪೋಸ್ಟರ್ ವರ್ಗಗಳು ಮತ್ತು ವಿನ್ಯಾಸಗಳು ಕಾಣಿಸುತ್ತವೆ.',
      malayalam: 'ലോഗിൻ ചെയ്ത ശേഷം ഹോം സ്ക്രീനിൽ പോസ്റ്റർ വിഭാഗങ്ങളും ഡിസൈനുകളും കാണാം.',
      marathi: 'लॉगिन केल्यानंतर, होम स्क्रीनवर पोस्टर श्रेणी आणि डिझाईन्स दिसतात.',
      gujarati: 'લૉગિન કર્યા પછી, હોમ સ્ક્રીન પોસ્ટર શ્રેણીઓ અને ડિઝાઇન દર્શાવે છે.',
      bengali: 'লগইন করার পরে, হোম স্ক্রিনে পোস্টার বিভাগ এবং ডিজাইন প্রদর্শিত হয়।',
      punjabi: 'ਲਾਗਇਨ ਕਰਨ ਤੋਂ ਬਾਅਦ, ਹੋਮ ਸਕ੍ਰੀਨ ਪੋਸਟਰ ਸ਼੍ਰੇਣੀਆਂ ਅਤੇ ਡਿਜ਼ਾਈਨ ਦਿਖਾਉਂਦੀ ਹੈ।',
      odia: 'ଲଗଇନ୍ କରିବା ପରେ, ହୋମ୍ ସ୍କ୍ରିନ୍‌ରେ ପୋଷ୍ଟର ବିଭାଗ ଏବଂ ଡିଜାଇନ୍ ଦେଖାଯାଏ।',
      assamese: 'লগইন কৰাৰ পাছত, হোম স্ক্ৰীণত পোষ্টাৰৰ শ্ৰেণী আৰু ডিজাইনসমূহ দেখা যায়।',
      konkani: 'ಲಾಗ್ ಇನ್ ಜಾಲ್ಯಾ ಉಪ್ರಾಂತ್, ಹೋಮ್ ಸ್ಕ್ರೀನಾರ್ ಪೋಸ್ಟರ್ ವರ್ಗಾಂ ಆನಿ ಡಿಸೈನ್ಸ್ ದಿಸ್ತಾತ್.',
      nepali: 'लगइन गरेपछि, गृह स्क्रिनले पोस्टर कोटिहरू र डिजाइनहरू देखाउँछ।',
      meitei: 'লগইন তৌরবা মতুংদা, হোম স্ক্রিনদা পোস্তর কেটাগোরিশিং অমসুং দিজাইনশিং উৎলি।',
      mizo: 'Login hnuah, home screen-ah poster category leh design-te a lang ang.',
      kashmiri: 'لاگ اِن گژھنہٕ پتہٕ چھِ ہوم سکرینَس پؠٹھ پوسٹر زمرٕ تہٕ ڈیزائن ہٲوان۔',
      ladakhi: 'ནང་འཛུལ་བྱས་རྗེས། གདོང་ཤོག་ནང་པོསྚར་གྱི་དབྱེ་བ་དང་བཀོད་པ་རྣམས་སྟོན།',
    ),
    strings.localized(
      telugu: 'మీరు ముందుగా ప్రొఫైల్ విభాగంలో మీ పేరు, ఫోటో మరియు వ్యాపార వివరాలను సేవ్ చేసుకోవచ్చు.',
      english: 'You can first save your name, photo, and business details in the profile section.',
      hindi: 'आप पहले प्रोफ़ाइल अनुभाग में अपना नाम, फ़ोटो और व्यावसायिक विवरण सहेज सकते हैं।',
      tamil: 'முதலில் சுயவிவரப் பகுதியில் உங்கள் பெயர், புகைப்படம் மற்றும் வணிக விவரங்களைச் சேமிக்கலாம்.',
      kannada: 'ನೀವು ಮೊದಲು ಪ್ರೊಫೈಲ್ ವಿಭಾಗದಲ್ಲಿ ನಿಮ್ಮ ಹೆಸರು, ಫೋಟೋ ಮತ್ತು ವ್ಯಾಪಾರದ ವಿವರಗಳನ್ನು ಉಳಿಸಬಹುದು.',
      malayalam: 'പ്രൊഫൈൽ വിഭാഗത്തിൽ നിങ്ങളുടെ പേര്, ഫോട്ടോ, ബിസിനസ്സ് വിവരങ്ങൾ എന്നിവ ആദ്യം സേവ് ചെയ്യാം.',
      marathi: 'तुम्ही प्रथम प्रोफाइल विभागात तुमचे नाव, फोटो आणि व्यवसायाचे तपशील सेव्ह करू शकता.',
      gujarati: 'તમે પહેલા પ્રોફાઇલ વિભાગમાં તમારું નામ, ફોટો અને વ્યવસાયની વિગતો સાચવી શકો છો.',
      bengali: 'আপনি প্রথমে প্রোফাইল বিভাগে আপনার নাম, ছবি এবং ব্যবসার বিবরণ সংরক্ষণ করতে পারেন।',
      punjabi: 'ਤੁਸੀਂ ਪਹਿਲਾਂ ਪ੍ਰੋਫਾਈਲ ਭਾਗ ਵਿੱਚ ਆਪਣਾ ਨਾਮ, ਫੋਟੋ ਅਤੇ ਕਾਰੋਬਾਰੀ ਵੇਰਵੇ ਸੁਰੱਖਿਅਤ ਕਰ ਸਕਦੇ ਹੋ।',
      odia: 'ଆପଣ ପ୍ରଥମେ ପ୍ରୋଫାଇଲ୍ ବିଭାଗରେ ନିଜ ନାମ, ଫଟୋ ଏବଂ ବ୍ୟବସାୟ ବିବରଣୀ ସେଭ୍ କରିପାରିବେ।',
      assamese: 'আপুনি প্ৰথমে প্ৰʼফাইল শাখাত আপোনাৰ নাম, ফটো আৰু ব্যৱসায়িক বিৱৰণ সংৰক্ষণ কৰিব পাৰে।',
      konkani: 'ತುಮಿ ಪಯ್ಲೆಂ ಪ್ರೊಫೈಲ್ ವಿಭಾಗಾಂತ್ ತುಮ್ಚೆಂ ನಾಂವ್, ಫೋಟೋ ಆನಿ ವ್ಯವಹಾರಾಚೆ ವಿವರಾಂ ಸಾಂಭಾಳುಂಕ್ ಸಕ್ತಾತ್.',
      nepali: 'तपाईंले पहिले प्रोफाइल खण्डमा आफ्नो नाम, फोटो र व्यापार विवरणहरू बचत गर्न सक्नुहुन्छ।',
      meitei: 'অহানবদা নহাক্না মশাগী মিং, ফোতো অমসুং লল্লোন-ইতিক্কী ৱারোলশিং প্রোফাইল সেক্সন্দা সেভ তৌবা য়াই।',
      mizo: 'Profile section-ah i hming, thlalak leh sumdawnna details i save hmasa thei ang.',
      kashmiri: 'تُہؠ ہیکیو ساروٕے کھۄتہٕ برٛونٛہہ پروفائل حِصَس مَنٛز پنُن ناو، فوٹو تہٕ کٲروبٲری تفصیلات مَحفوٗظ کٔرِتھ۔',
      ladakhi: 'ཐོག་མར་རང་གི་གསལ་བཤད་ནང་རང་གི་མིང་། འདྲ་པར་དང་ཚོང་ལས་ཀྱི་གནས་ཚུལ་ཉར་ཚགས་བྱེད་ཐུབ།',
    ),
    strings.localized(
      telugu: 'కమ్యూనిటీ కొటేషన్ లేదా ఇమేజ్ సమర్పణలను మేనేజర్ సమీక్షించి, సరైన కేటగిరీలో పోస్టర్‌ను ప్రచురిస్తారు.',
      english: 'Community quote/image submissions are reviewed by a manager, who may customize and publish the poster in the correct category.',
      hindi: 'कम्युनिटी कोट्स/छवि सबमिशन की समीक्षा मैनेजर द्वारा की जाती है, जो सही श्रेणी में पोस्टर प्रकाशित कर सकते हैं।',
      tamil: 'சமூக மேற்கோள்/பட சமர்ப்பிப்புகள் மேலாளரால் மதிப்பாய்வு செய்யப்பட்டு, சரியான பிரிவில் வெளியிடப்படும்.',
      kannada: 'ಕಮ್ಯುನಿಟಿ ಉಲ್ಲೇಖ/ಚಿತ್ರ ಸಲ್ಲಿಕೆಗಳನ್ನು ಮ್ಯಾನೇಜರ್ ಪರಿಶೀಲಿಸಿ, ಸರಿಯಾದ ವರ್ಗದಲ್ಲಿ ಪೋಸ್ಟರ್ ಪ್ರಕಟಿಸುತ್ತಾರೆ.',
      malayalam: 'കമ്മ്യൂണിറ്റി സമർപ്പണങ്ങൾ മാനേജർ പരിശോധിച്ച് ശരിയായ കാറ്റഗറിയിൽ പോസ്റ്റർ പ്രസിദ്ധീകരിക്കുന്നു.',
      marathi: 'कम्युनिटी कोट/प्रतिमा सबमिशनचे पुनरावलोकन मॅनेजरद्वारे केले जाते, जे योग्य श्रेणीत पोस्टर प्रकाशित करतात.',
      gujarati: 'કમ્યુનિટી ક્વોટ/ઇમેજ સબમિશનની મેનેજર દ્વારા સમીક્ષા કરવામાં આવે છે, જે યોગ્ય શ્રેણીમાં પોસ્ટર પ્રકાશિત કરે છે.',
      bengali: 'কমিউনিটি উদ্ধৃতি/ছবি জমা দেওয়া হলে ম্যানেজার তা পর্যালোচনা করে সঠিক বিভাগে প্রকাশ করেন।',
      punjabi: 'ਕਮਿਊਨਿਟੀ ਵਿਚਾਰ/ਤਸਵੀਰ ਦਰਜ ਕਰਨ ਤੇ ਮੈਨੇਜਰ ਵੱਲੋਂ ਸਮੀਖਿਆ ਕੀਤੀ ਜਾਂਦੀ ਹੈ ਅਤੇ ਸਹੀ ਸ਼੍ਰੇਣੀ ਵਿੱਚ ਪੋਸਟਰ ਪ੍ਰਕਾਸ਼ਿਤ ਕੀਤਾ ਜਾਂਦਾ ਹੈ।',
      odia: 'କମ୍ୟୁନିଟି ଉଦ୍ଧୃତି/ଫଟୋ ଦାଖଲକୁ ମ୍ୟାନେଜର ସମୀକ୍ଷା କରି ସଠିକ୍ ବିଭାଗରେ ପୋଷ୍ଟର ପ୍ରକାଶ କରନ୍ତି।',
      assamese: 'কমিউনিটি উদ্ধৃতি/ছবি জমাসমূহ মেনেজাৰে পৰ্যালোচনা কৰে আৰু সঠিক শ্ৰেণীত পোষ্টাৰ প্ৰকাশ কৰে।',
      konkani: 'ಕಮ್ಯುನಿಟಿ ಕೋಟ್/ಫೋಟೋ ಸಲ್ಲಿಕೆಂಕ್ ಮ್ಯಾನೇಜರ್ ತಪಾಸ್ತಾ ಆನಿ ಸಾರ್ಕ್ಯಾ ವರ್ಗಾಂತ್ ಪ್ರಕಟ್ ಕರ್ತಾ.',
      nepali: 'समुदाय उद्धरण/छवि सबमिशनहरू प्रबन्धकद्वारा समीक्षा गरिन्छ, जसले सही श्रेणीमा पोस्टर प्रकाशित गर्न सक्छन्।',
      meitei: 'কম্যুনিতিগী কোত/মমি থারকপশিং মেনেজর অমনা রিভ্যু তৌই অমসুং চুনবা কেটাগোরিদা ফোঙই।',
      mizo: 'Community thuziak/thlalak thehluhte chu manager-in a endik ang a, category dik takah a tlangzarh ang.',
      kashmiri: 'کمیونٹی اَقوال/تصویرٕ چھِ مینیجر سٕنٛدِ طرفہٕ ریویو یِوان کرنہٕ تہٕ صٔحیح زمرَس مَنٛز پبلش کَرنہٕ یِوان۔',
      ladakhi: 'མི་སྡེའི་ཚིག་དུམ་དང་འདྲ་པར་རྣམས་དོ་དམ་པས་ཞིབ་བཤེར་བྱས་ཏེ་དབྱེ་བ་དག་པའི་ནང་སྤེལ།',
    ),
    strings.localized(
      telugu: 'డిజైన్‌ను ఎంచుకున్న తర్వాత, ఎడిటర్‌లో లేయర్లు, టెక్స్ట్, ఫోటోలు, బ్రష్‌లు, ఎఫెక్ట్స్, బ్యాక్‌గ్రౌండ్ రిమూవల్ మరియు ఎక్స్‌పోర్ట్ టూల్స్‌తో ఎడిట్ చేసుకోవచ్చు.',
      english: 'Once a design is selected, it can be edited and personalized in the editor with layers, text, photos, brushes, effects, background removal, and export tools.',
      hindi: 'एक बार डिज़ाइन चुनने के बाद, इसे एडिटर में लेयर्स, टेक्स्ट, फोटो, ब्रश, इफेक्ट्स, बैकग्राउंड रिमूवल और एक्सपोर्ट टूल्स के साथ कस्टमाइज़ किया जा सकता है।',
      tamil: 'வடிவமைப்பைத் தேர்ந்தெடுத்த பிறகு, எடிட்டரில் அடுக்குகள், உரை, புகைப்படங்கள், பிரஷ்கள், விளைவுகள், பின்னணி நீக்கம் மற்றும் ஏற்றுமதி கருவிகள் மூலம் திருத்தலாம்.',
      kannada: 'ವಿನ್ಯಾಸವನ್ನು ಆಯ್ಕೆಮಾಡಿದ ನಂತರ, ಎಡಿಟರ್‌ನಲ್ಲಿ ಲೇಯರ್‌ಗಳು, ಟೆಕ್ಸ್ಟ್, ಫೋಟೋಗಳು, ಬ್ರಶ್‌ಗಳು, ಎಫೆಕ್ಟ್‌ಗಳು ಮತ್ತು ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ರಿಮೂವಲ್ ಮೂಲಕ ಎಡಿಟ್ ಮಾಡಬಹುದು.',
      malayalam: 'ഡിസൈൻ തിരഞ്ഞെടുത്ത ശേഷം എഡിറ്ററിൽ ലെയറുകൾ, ടെക്സ്റ്റ്, ഫോട്ടോകൾ, ബ്രഷുകൾ, ഇഫക്റ്റുകൾ, ബാക്ക്ഗ്രൗണ്ട് റിമൂവൽ എന്നിവ ഉപയോഗിച്ച് എഡിറ്റ് ചെയ്യാം.',
      marathi: 'एकदा डिझाइन निवडल्यानंतर, ते एडिटरमध्ये लेयर्स, टेक्स्ट, फोटो, ब्रशेस, इफेक्ट्स, बॅकग्राउंड काढणे आणि एक्सपोर्ट साधनांसह संपादित केले जाऊ शकते.',
      gujarati: 'એકવાર ડિઝાઇન પસંદ થઈ ગયા પછી, તેને એડિટરમાં લેયર્સ, ટેક્સ્ટ, ફોટા, બ્રશ, ઇફેક્ટ્સ અને બેકગ્રાઉન્ડ રિમૂવલ સાથે એડિટ કરી શકાય છે.',
      bengali: 'একবার ডিজাইন বেছে নেওয়ার পরে, এটি এডিটরে লেয়ার, টেক্সট, ফটো, ব্রাশ, এফেক্টস, ব্যাকগ্রাউন্ড রিমুভাল এবং এক্সপোর্ট টুলের সাহায্যে এডিট করা যায়।',
      punjabi: 'ਇੱਕ ਵਾਰ ਡਿਜ਼ਾਈਨ ਚੁਣੇ ਜਾਣ ਤੇ, ਇਸਨੂੰ ਐਡੀਟਰ ਵਿੱਚ ਲੇਅਰਾਂ, ਟੈਕਸਟ, ਫੋਟੋਆਂ, ਬੁਰਸ਼, ਪ੍ਰਭਾਵਾਂ ਅਤੇ ਬੈਕਗ੍ਰਾਊਂਡ ਹਟਾਉਣ ਨਾਲ ਸੰਪਾਦਿਤ ਕੀਤਾ ਜਾ ਸਕਦਾ ਹੈ।',
      odia: 'ଡିଜାଇନ୍ ବାଛିବା ପରେ, ଏହାକୁ ଏଡିଟର୍‌ରେ ଲେୟାର, ଟେକ୍ସଟ୍, ଫଟୋ, ବ୍ରସ୍, ଇଫେକ୍ଟସ୍ ଏବଂ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଇବା ଉପକରଣ ସହିତ ଏଡିଟ୍ କରାଯାଇପାରିବ।',
      assamese: 'ডিজাইন নিৰ্বাচন কৰাৰ পাছত, এডিটৰত স্তৰ, টেক্সট, ফটো, ব্ৰাছ, প্ৰভাৱ আৰু পটভূমি আঁতৰোৱা সঁজুলিৰে সম্পাদনা কৰিব পাৰি।',
      konkani: 'ಡಿಸೈನ್ ವಿಂಚ್ಲ್ಯಾ ಉಪ್ರಾಂತ್, ಎಡಿಟರಾಂತ್ ಲೇಯರ್ಸ್, ಟೆಕ್ಸ್ಟ್, ಫೋಟೋಸ್, ಬ್ರಶ್, ಎಫೆಕ್ಟ್ಸ್ ಆನಿ ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ರಿಮೂವಲ್ ಸವೆಂ ಎಡಿಟ್ ಕರುಂಕ್ ಜಾತಾ.',
      nepali: 'एक पटक डिजाइन चयन भएपछि, यसलाई सम्पादकमा लेयर, पाठ, फोटो, ब्रस, प्रभाव, पृष्ठभूमि हटाउने र निर्यात उपकरणहरूसँग सम्पादन गर्न सकिन्छ।',
      meitei: 'দিজাইন অমা খনরবা মতুংদা, মসি লেয়রশিং, তেক্সত, ফোতোশিং, ব্রসশিং, ইফেক্তশিং অমসুং বেকগ্রাউন্দ লৌথোকপগা লোয়ননা শেমদোকপা য়াই।',
      mizo: 'Design thlan hnuah, editor hmangin layers, text, thlalak, brushes, effects, background paihna leh export hmanraw hrang hrang hmangin a siamrem theih.',
      kashmiri: 'ڈیزائن ژارنہٕ پتہٕ چھُ ایڈیٹرس مَنٛز لیئرز، ٹیکسٹ، فوٹو، برش، اِفیکٹس تہٕ بیک گرٛاونٛڈ ہٹاونٕکؠ ٹولز سٟتؠ ایڈٹ کَرنہٕ یِوان।',
      ladakhi: 'བཀོད་པ་བདམས་རྗེས། ཞུ་དག་ཆས་ནང་ཡིག་དེབ། འདྲ་པར། པིར། ཁྱད་ཆོས། རྒྱབ་ལྗོངས་སེལ་བ་སོགས་ཀྱིས་བཟོ་བཅོས་བྱེད་ཐུབ།',
    ),
    strings.localized(
      telugu: 'అసెట్స్ టూల్ ద్వారా ప్రీమియం అసెట్స్ వర్గాలను చూడవచ్చు; డౌన్‌లోడ్ చేసిన తర్వాత మద్దతు ఉన్న అసెట్స్‌ను పోస్టర్‌పైకి ఇంపోర్ట్ చేసుకోవచ్చు.',
      english: 'The Assets tool can show app-provided premium asset categories; after download, supported assets can be imported onto the poster canvas.',
      hindi: 'एसेट्स टूल ऐप द्वारा प्रदान की गई प्रीमियम एसेट श्रेणियां दिखाता है; डाउनलोड के बाद समर्थित एसेट्स को पोस्टर कैनवास पर आयात किया जा सकता है।',
      tamil: 'சொத்துகள் கருவி பிரீமியம் வகைகளைக் காட்டுகிறது; பதிவிறக்கிய பிறகு பொருத்தமான சொத்துகளை போஸ்டரில் சேர்க்கலாம்.',
      kannada: 'ಅಸೆಟ್ಸ್ ಟೂಲ್ ಪ್ರೀಮಿಯಂ ವರ್ಗಗಳನ್ನು ತೋರಿಸುತ್ತದೆ; ಡೌನ್‌ಲೋಡ್ ಮಾಡಿದ ನಂತರ ಬೆಂಬಲಿತ ಅಸೆಟ್‌ಗಳನ್ನು ಪೋಸ್ಟರ್‌ಗೆ ಸೇರಿಸಬಹುದು.',
      malayalam: 'അസറ്റ് ടൂൾ പ്രീമിയം വിഭാഗങ്ങൾ കാണിക്കുന്നു; ഡൗൺലോഡ് ചെയ്ത ശേഷം പിന്തുണയ്ക്കുന്നവ ക്യാൻവാസിലേക്ക് ചേർക്കാം.',
      marathi: 'अ‍ॅसेट्स टूल प्रीमियम श्रेणी दाखवते; डाउनलोड केल्यानंतर समर्थित अ‍ॅसेट्स पोस्टर कॅनव्हासवर आणता येतात.',
      gujarati: 'એસેટ્સ ટૂલ પ્રીમિયમ કેટેગરીઝ દર્શાવે છે; ડાઉનલોડ કર્યા પછી સમર્થિત એસેટ્સને પોસ્ટર પર આયાત કરી શકાય છે.',
      bengali: 'অ্যাসেটস টুল প্রিমিয়াম বিভাগ প্রদর্শন করে; ডাউনলোডের পরে সমর্থিত উপাদানগুলি পোস্টার ক্যানভাসে যুক্ত করা যায়।',
      punjabi: 'ਸੰਪਤੀ ਟੂਲ ਪ੍ਰੀਮੀਅਮ ਸ਼੍ਰੇਣੀਆਂ ਦਿਖਾਉਂਦਾ ਹੈ; ਡਾਊਨਲੋਡ ਕਰਨ ਤੋਂ ਬਾਅਦ ਸੰਪਤੀਆਂ ਨੂੰ ਪੋਸਟਰ ਤੇ ਲਿਆਂਦਾ ਜਾ ਸਕਦਾ ਹੈ।',
      odia: 'ଆସେଟ୍ସ ଉପକରଣ ପ୍ରିମିୟମ୍ ବର୍ଗ ଦେଖାଏ; ଡାଉନଲୋଡ୍ ପରେ ସମର୍ଥିତ ଆସେଟ୍‌ଗୁଡ଼ିକୁ ପୋଷ୍ଟର କ୍ୟାନଭାସକୁ ଅଣାଯାଇପାରିବ।',
      assamese: 'সম্পদ সঁজুলিয়ে প্ৰিমিয়াম শ্ৰেণীসমূহ প্ৰদৰ্শন কৰে; ডাউনলোডৰ পাছত সমৰ্থিত সম্পদসমূহ পোষ্টাৰলৈ আনিব পাৰি।',
      konkani: 'ಅಸೆಟ್ಸ್ ಟೂಲ್ ಪ್ರೀಮಿಯಂ ವರ್ಗಾಂ ದಾಕಯ್ತಾ; ಡೌನ್‌ಲೋಡ್ ಕೆಲ್ಯಾ ಉಪ್ರಾಂತ್ ಪೋಸ್ಟರಾರ್ ಹಾಡುಂಕ್ ಜಾತಾ.',
      nepali: 'सम्पत्ति उपकरणले प्रिमियम कोटीहरू देखाउँछ; डाउनलोड गरेपछि समर्थित सम्पत्तिहरू पोस्टरमा आयात गर्न सकिन्छ।',
      meitei: 'এসেত তূল অসিনা প্রিমিয়ম কেটাগোরিশিং উৎলি; দাউনলোদ তৌরবা মতুংদা এসেতশিং পোস্তরদা পুরকপা য়াই।',
      mizo: 'Assets tool chuan app-in a pek premium asset categories a tilang thei a; download hnuah poster canvas-ah a dah luh theih.',
      kashmiri: 'اثاثہٕ ٹول چھُ پریمیم زمرٕ ہٲوان؛ ڈاون لوڈ پتہٕ ہیکیو سَہولت وٲلؠ اثاثہٕ پوسٹر کینوسَس پؠٹھ اِمپورٹ کٔرِتھ۔',
      ladakhi: 'རྒྱུ་ཆའི་ལག་ཆས་ཀྱིས་རིན་མེད་མ་ཡིན་པའི་དབྱེ་བ་རྣམས་སྟོན། ཕབ་ལེན་བྱས་རྗེས་པོསྚར་ཐོག་ནང་འདྲེན་བྱེད་ཐུབ།',
    ),
    strings.localized(
      telugu: 'చివరగా, పూర్తయిన పోస్టర్‌ను సేవ్ చేసుకోవచ్చు లేదా ఇతరులతో పంచుకోవచ్చు.',
      english: 'Finally, the completed poster can be saved or shared.',
      hindi: 'अंत में, तैयार पोस्टर को सहेजा या साझा किया जा सकता है।',
      tamil: 'இறுதியாக, உருவாக்கப்பட்ட போஸ்டரைச் சேமிக்கலாம் அல்லது பகிரலாம்.',
      kannada: 'ಅಂತಿಮವಾಗಿ, ಪೂರ್ಣಗೊಂಡ ಪೋಸ್ಟರ್ ಅನ್ನು ಉಳಿಸಬಹುದು ಅಥವಾ ಹಂಚಿಕೊಳ್ಳಬಹುದು.',
      malayalam: 'അവസാനം, പൂർത്തിയായ പോസ്റ്റർ സേവ് ചെയ്യുകയോ പങ്കിടുകയോ ചെയ്യാം.',
      marathi: 'शेवटी, पूर्ण झालेला पोस्टर सेव्ह किंवा शेअर केला जाऊ शकतो.',
      gujarati: 'અંતે, પૂર્ણ થયેલ પોસ્ટર સાચવી અથવા શેર કરી શકાય છે.',
      bengali: 'অবশেষে, সম্পূর্ণ পোস্টারটি সংরক্ষণ বা শেয়ার করা যেতে পারে।',
      punjabi: 'ਅੰਤ ਵਿੱਚ, ਮੁਕੰਮਲ ਹੋਏ ਪੋਸਟਰ ਨੂੰ ਸੁਰੱਖਿਅਤ ਜਾਂ ਸਾਂਝਾ ਕੀਤਾ ਜਾ ਸਕਦਾ ਹੈ।',
      odia: 'ଶେଷରେ, ସମ୍ପୂର୍ଣ୍ଣ ପୋଷ୍ଟରଟିକୁ ସେଭ୍ କିମ୍ବା ସେୟାର କରାଯାଇପାରିବ।',
      assamese: 'অৱশেষত, সম্পূৰ্ণ হোৱা পোষ্টাৰটো সংৰক্ষণ বা শ্বেয়াৰ কৰিব পাৰি।',
      konkani: 'ಆಖೇರಿಕ್, ಪೂರ್ಣ್ ಜಾಲ್ಲೊ ಪೋಸ್ಟರ್ ಸಾಂಭಾಳುಂಕ್ ಯಾ ಶೇರ್ ಕರುಂಕ್ ಜಾತಾ.',
      nepali: 'अन्तमा, पूरा भएको पोस्टर बचत वा सेयर गर्न सकिन्छ।',
      meitei: 'অরোইবদা, লোইশিনরবা পোস্তর অদু সেভ তৌবা নত্রগা শিয়র তৌবা য়াই।',
      mizo: 'A tawpah, poster peih tawh chu save emaw share theih a ni.',
      kashmiri: 'ٲخٕر کار، تیّار شُدٕ پوسٹر ہیکیو مَحفوٗظ یا شیئر کٔرِتھ۔',
      ladakhi: 'མཐའ་མར། གྲུབ་ཟིན་པའི་པོསྚར་དེ་ཉར་ཚགས་སམ་བརྒྱུད་སྤེལ་བྱེད་ཐུབ།',
    ),
  ];

  String get subscriptionTitle => strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ వివరాలు',
    english: 'Subscription details',
    hindi: 'सदस्यता विवरण',
    tamil: 'சந்தா விவரங்கள்',
    kannada: 'ಚಂದಾದಾರಿಕೆ ವಿವರಗಳು',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ വിവരങ്ങൾ',
    marathi: 'सदस्यता तपशील',
    gujarati: 'સબ્સ્ક્રિપ્શન વિગતો',
    bengali: 'সাবস্ক্রিপশন বিবরণ',
    punjabi: 'ਗਾਹਕੀ ਵੇਰਵੇ',
    odia: 'ସଦସ୍ୟତା ବିବରଣୀ',
    assamese: 'গ্ৰাহকভুক্তিৰ বিৱৰণ',
    konkani: 'ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ ವಿವರಾಂ',
    nepali: 'सदस्यता विवरण',
    meitei: 'সবস্ক্রিপ্সনগী ৱারোলশিং',
    mizo: 'Subscription chungchang',
    kashmiri: 'سبسکرپشن ہٕنٛز تفصیلات',
    ladakhi: 'མངགས་ཉོའི་གནས་ཚུལ།',
  );

  List<String> get subscriptionItems => <String>[
    strings.localized(
      telugu: 'యాప్ ప్రో ద్వారా పోస్టర్ యాక్సెస్, పోస్టర్ తయారీ మరియు ఎక్స్‌పోర్ట్ సదుపాయాలు లభిస్తాయి.',
      english: 'App Pro supports poster access, poster creation, and exports.',
      hindi: 'ऐप प्रो पोस्टर एक्सेस, पोस्टर निर्माण और निर्यात का समर्थन करता है।',
      tamil: 'ஆப் ப்ரோ போஸ்டர் அணுகல், போஸ்டர் உருவாக்கம் மற்றும் ஏற்றுமதியை ஆதரிக்கிறது.',
      kannada: 'ಆ್ಯಪ್ ಪ್ರೊ ಪೋಸ್ಟರ್ ಪ್ರವೇಶ, ಪೋಸ್ಟರ್ ರಚನೆ ಮತ್ತು ರಫ್ತುಗಳನ್ನು ಬೆಂಬಲಿಸುತ್ತದೆ.',
      malayalam: 'ആപ്പ് പ്രോ വഴി പോസ്റ്റർ ആക്സസ്, നിർമ്മാണം, എക്സ്പോർട്ട് എന്നിവ ലഭ്യമാണ്.',
      marathi: 'अ‍ॅप प्रो पोस्टर अ‍ॅक्सेस, पोस्टर निर्मिती आणि निर्यातीला सपोर्ट करते.',
      gujarati: 'એપ પ્રો પોસ્ટર એક્સેસ, પોસ્ટર બનાવટ અને નિકાસને સમર્થન આપે છે.',
      bengali: 'অ্যাপ প্রো পোস্টার অ্যাক্সেস, পোস্টার তৈরি এবং রপ্তানি সমর্থন করে।',
      punjabi: 'ਐਪ ਪ੍ਰੋ ਪੋਸਟਰ ਪਹੁੰਚ, ਪੋਸਟਰ ਨਿਰਮਾਣ ਅਤੇ ਨਿਰਯਾਤ ਦਾ ਸਮਰਥਨ ਕਰਦਾ ਹੈ।',
      odia: 'ଆପ୍ ପ୍ରୋ ପୋଷ୍ଟର ପ୍ରବେଶ, ପୋଷ୍ଟର ତିଆରି ଏବଂ ରପ୍ତାନିକୁ ସମର୍ଥନ କରେ।',
      assamese: 'এপ প্ৰʼই পোষ্টাৰ প্ৰৱেশ, পোষ্টাৰ নিৰ্মাণ আৰু ৰপ্তানি সমৰ্থন কৰে।',
      konkani: 'ಆ್ಯಪ್ ಪ್ರೊ ಪೋಸ್ಟರ್ ಪ್ರವೇಶ್, ಪೋಸ್ಟರ್ ತಯಾರಿ ಆನಿ ಎಕ್ಸ್‌ಪೋರ್ಟ್ಸ್ ಸಪೋರ್ಟ್ ಕರ್ತಾ.',
      nepali: 'एप प्रो ले पोस्टर पहुँच, पोस्टर निर्माण र निर्यात समर्थन गर्दछ।',
      meitei: 'এপ প্রোনা পোস্তর এক্সেস, পোস্তর শেম্বা অমসুং এক্সপোর্ত তৌবদা মতেং পাংই।',
      mizo: 'App Pro hian poster en theihna, siam theihna leh export theihna a pe.',
      kashmiri: 'ایپھ پرو چھُ پوسٹر اینٹری، پوسٹر بناونہٕ تہٕ برآمدَس سہارا دِوان۔',
      ladakhi: 'ཨེཔ་པྲོ་ཡིས་པོསྚར་ལྟ་ཀློག པོསྚར་བཟོ་སྐྲུན་དང་ཕྱིར་འདྲེན་ལ་རྒྱབ་སྐྱོར་བྱེད།',
    ),
    strings.localized(
      telugu: 'ట్రయల్ ప్లాన్: ${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay}.',
      english: 'Trial plan: ${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days.',
      hindi: 'ट्रायल प्लान: ${SubscriptionPlanConfig.trialDays} दिनों के लिए ${SubscriptionPlanConfig.trialPriceDisplay}।',
      tamil: 'சோதனைத் திட்டம்: ${SubscriptionPlanConfig.trialDays} நாட்களுக்கு ${SubscriptionPlanConfig.trialPriceDisplay}.',
      kannada: 'ಪ್ರಾಯೋಗಿಕ ಯೋಜನೆ: ${SubscriptionPlanConfig.trialDays} ದಿನಗಳಿಗೆ ${SubscriptionPlanConfig.trialPriceDisplay}.',
      malayalam: 'ട്രയൽ പ്ലാൻ: ${SubscriptionPlanConfig.trialDays} ദിവസത്തേക്ക് ${SubscriptionPlanConfig.trialPriceDisplay}.',
      marathi: 'चाचणी योजना: ${SubscriptionPlanConfig.trialDays} दिवसांसाठी ${SubscriptionPlanConfig.trialPriceDisplay}.',
      gujarati: 'ટ્રાયલ પ્લાન: ${SubscriptionPlanConfig.trialDays} દિવસ માટે ${SubscriptionPlanConfig.trialPriceDisplay}.',
      bengali: 'ট্রায়াল প্ল্যান: ${SubscriptionPlanConfig.trialDays} দিনের জন্য ${SubscriptionPlanConfig.trialPriceDisplay}।',
      punjabi: 'ਟਰਾਇਲ ਪਲਾਨ: ${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਲਈ ${SubscriptionPlanConfig.trialPriceDisplay}.',
      odia: 'ଟ୍ରାଏଲ୍ ପ୍ଲାନ୍: ${SubscriptionPlanConfig.trialDays} ଦିନ ପାଇଁ ${SubscriptionPlanConfig.trialPriceDisplay}।',
      assamese: 'পৰীক্ষামূলক আঁচনি: ${SubscriptionPlanConfig.trialDays} দিনৰ বাবে ${SubscriptionPlanConfig.trialPriceDisplay}।',
      konkani: 'ಟ್ರಯಲ್ ಪ್ಲಾನ್: ${SubscriptionPlanConfig.trialDays} ದಿಸಾಂಕ್ ${SubscriptionPlanConfig.trialPriceDisplay}.',
      nepali: 'परीक्षण योजना: ${SubscriptionPlanConfig.trialDays} दिनका लागि ${SubscriptionPlanConfig.trialPriceDisplay}।',
      meitei: 'ত্রায়েল প্লান: নুমিৎ ${SubscriptionPlanConfig.trialDays} গীদমক ${SubscriptionPlanConfig.trialPriceDisplay}।',
      mizo: 'Trial plan: Ni ${SubscriptionPlanConfig.trialDays} chhung tan ${SubscriptionPlanConfig.trialPriceDisplay}.',
      kashmiri: 'ٹرائل پلان: ${SubscriptionPlanConfig.trialDays} دۄہَن باپتھ ${SubscriptionPlanConfig.trialPriceDisplay}۔',
      ladakhi: 'ཚོད་ལྟའི་འཆར་གཞི། ཉིན་ ${SubscriptionPlanConfig.trialDays} ལ་ ${SubscriptionPlanConfig.trialPriceDisplay}།',
    ),
    strings.localized(
      telugu: '${SubscriptionPlanConfig.trialDays} రోజుల తర్వాత, రద్దు చేయకపోతే ఆటో-రెన్యూవల్‌తో నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} చొప్పున కొనసాగుతుంది.',
      english: 'After ${SubscriptionPlanConfig.trialDays} days, it continues at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month with auto-renewal unless cancelled.',
      hindi: '${SubscriptionPlanConfig.trialDays} दिनों के बाद, रद्द न किए जाने तक यह स्वतः नवीनीकरण के साथ प्रति माह ${SubscriptionPlanConfig.monthlyPriceDisplay} पर जारी रहेगा।',
      tamil: '${SubscriptionPlanConfig.trialDays} நாட்களுக்குப் பிறகு, ரத்து செய்யப்படாவிட்டால் தானியங்கி புதுப்பித்தலுடன் மாதம் ${SubscriptionPlanConfig.monthlyPriceDisplay} என்ற அளவில் தொடரும்.',
      kannada: '${SubscriptionPlanConfig.trialDays} ದಿನಗಳ ನಂತರ, ರದ್ದುಗೊಳಿಸದಿದ್ದರೆ ಸ್ವಯಂ ನವೀಕರಣದೊಂದಿಗೆ ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay} ದರದಲ್ಲಿ ಮುಂದುವರಿಯುತ್ತದೆ.',
      malayalam: '${SubscriptionPlanConfig.trialDays} ദിവസങ്ങൾക്ക് ശേഷം, റദ്ദാക്കിയില്ലെങ്കിൽ സ്വയം പുതുക്കലോടെ പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay} നിരക്കിൽ തുടരും.',
      marathi: '${SubscriptionPlanConfig.trialDays} दिवसांनंतर, रद्द न केल्यास स्वयं-नूतनीकरणासह दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay} वर सुरू राहील.',
      gujarati: '${SubscriptionPlanConfig.trialDays} દિવસ પછી, રદ ન કરવામાં આવે તો ઓટો-રીન્યુઅલ સાથે દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay} પર ચાલુ રહેશે.',
      bengali: '${SubscriptionPlanConfig.trialDays} দিন পরে, বাতিল না হলে এটি স্বয়ংক্রিয় পুনর্নবীকরণ সহ প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay} হারে অব্যাহত থাকবে।',
      punjabi: '${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਬਾਅਦ, ਰੱਦ ਨਾ ਕੀਤੇ ਜਾਣ ਤੇ ਇਹ ਸਵੈ-ਨਵੀਨੀਕਰਨ ਦੇ ਨਾਲ ਪ੍ਰਤੀ ਮਹੀਨਾ ${SubscriptionPlanConfig.monthlyPriceDisplay} ਤੇ ਜਾਰੀ ਰਹੇਗਾ।',
      odia: '${SubscriptionPlanConfig.trialDays} ଦିନ ପରେ, ବାତିଲ ନହେଲେ ସ୍ୱୟଂକ୍ରିୟ ନବୀକରଣ ସହିତ ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay} ଭାବରେ ଜାରି ରହିବ।',
      assamese: '${SubscriptionPlanConfig.trialDays} দিনৰ পাছত, বাতিল নকৰিলে স্বয়ংক্ৰিয় নবীকৰণৰ সৈতে প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay} কৈ অব্যাহত থাকিব।',
      konkani: '${SubscriptionPlanConfig.trialDays} ದಿಸಾಂ ಉಪ್ರಾಂತ್, ರದ್ದ್ ಕರ್ನಾತ್ಲ್ಯಾರ್ ಆಟೋ-ರಿನೀವಲ್ ಸವೆಂ ಮಯ್ನ್ಯಾಕ್ ${SubscriptionPlanConfig.monthlyPriceDisplay} ಜಾವ್ನ್ ಮುಂದುವರಿಯ್ತಾ.',
      nepali: '${SubscriptionPlanConfig.trialDays} दिनपछि, रद्द नगरिएमा यो स्वतः नवीकरणका साथ प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay} मा जारी रहन्छ।',
      meitei: 'নুমিৎ ${SubscriptionPlanConfig.trialDays} গী মতুংদা, কেন্সেল তৌদ্রবদি ওতো-রিনিউএলগা লোয়ননা থা অমদা ${SubscriptionPlanConfig.monthlyPriceDisplay} দা চত্থগনি।',
      mizo: 'Ni ${SubscriptionPlanConfig.trialDays} hnuah, tihtawp a nih loh chuan thla tin auto-renewal nen ${SubscriptionPlanConfig.monthlyPriceDisplay} a ni chhunzawm ang.',
      kashmiri: '${SubscriptionPlanConfig.trialDays} دۄہَن پتہٕ چھُ منسوخ نہٕ کَرنہٕ تام آٹو رِنیوول سٟتؠ پرٛؠتھ رؠتہٕ ${SubscriptionPlanConfig.monthlyPriceDisplay} پؠٹھ جٲری روزان۔',
      ladakhi: 'ཉིན་ ${SubscriptionPlanConfig.trialDays} རྗེས། ཕྱིར་འཐེན་མ་བྱས་ན་རང་འགུལ་གསར་བཟོ་དང་བཅས་ཟླ་རེར་ ${SubscriptionPlanConfig.monthlyPriceDisplay} ལ་མུ་མཐུད་དོ།',
    ),
    strings.localized(
      telugu: 'ప్రీమియం ఎడిటర్ అసెట్స్, తెలుగు ఫాంట్లు మరియు బ్యాక్‌గ్రౌండ్ రిమూవల్ కోసం ఎడిటర్ ప్రో నెలకు ₹99 చొప్పున విడిగా అందుబాటులో ఉంటుంది.',
      english: 'Editor Pro is available separately at ₹99 per month for premium editor assets, Telugu fonts, and background removal where available.',
      hindi: 'प्रीमियम एडिटर एसेट्स, तेलुगु फॉन्ट और बैकग्राउंड रिमूवल के लिए एडिटर प्रो ₹99 प्रति माह पर अलग से उपलब्ध है।',
      tamil: 'பிரீமியம் எடிட்டர் சொத்துகள், தெலுங்கு எழுத்துருக்கள் மற்றும் பின்னணி நீக்கத்திற்கு எடிட்டர் ப்ரோ மாதம் ₹99 விலையில் தனியாகக் கிடைக்கிறது.',
      kannada: 'ಪ್ರೀಮಿಯಂ ಎಡಿಟರ್ ಅಸೆಟ್‌ಗಳು, ತೆಲುಗು ಫಾಂಟ್‌ಗಳು ಮತ್ತು ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ರಿಮೂವಲ್‌ಗಾಗಿ ಎಡಿಟರ್ ಪ್ರೊ ತಿಂಗಳಿಗೆ ₹99 ದರದಲ್ಲಿ ಪ್ರತ್ಯೇಕವಾಗಿ ಲಭ್ಯವಿದೆ.',
      malayalam: 'പ്രീമിയം എഡിറ്റർ അസറ്റുകൾ, തെലുങ്ക് ഫോണ്ടുകൾ, ബാക്ക്ഗ്രൗണ്ട് റിമൂവൽ എന്നിവയ്ക്കായി എഡിറ്റർ പ്രോ പ്രതിമാസം ₹99 നിരക്കിൽ ലഭ്യമാണ്.',
      marathi: 'प्रीमियम एडिटर अ‍ॅसेट्स, तेलगू फॉन्ट्स आणि बॅकग्राउंड काढण्यासाठी एडिटर प्रो दरमहा ₹99 मध्ये स्वतंत्रपणे उपलब्ध आहे.',
      gujarati: 'પ્રીમિયમ એડિટર એસેટ્સ, તેલુગુ ફોન્ટ્સ અને બેકગ્રાઉન્ડ રિમૂવલ માટે એડિટર પ્રો દર મહિને ₹99 પર અલગથી ઉપલબ્ધ છે.',
      bengali: 'প্রিমিয়াম এডিটর উপাদান, তেলুগু ফন্ট এবং ব্যাকগ্রাউন্ড রিমুভালের জন্য এডিটর প্রো প্রতি মাসে ₹99 মূল্যে আলাদাভাবে উপলব্ধ।',
      punjabi: 'ਪ੍ਰੀਮੀਅਮ ਐਡੀਟਰ ਸੰਪਤੀਆਂ, ਤੇਲਗੂ ਫੌਂਟਾਂ ਅਤੇ ਬੈਕਗ੍ਰਾਊਂਡ ਹਟਾਉਣ ਲਈ ਐਡੀਟਰ ਪ੍ਰੋ ਪ੍ਰਤੀ ਮਹੀਨਾ ₹99 ਤੇ ਵੱਖਰੇ ਤੌਰ ਤੇ ਉਪਲਬਧ ਹੈ।',
      odia: 'ପ୍ରିମିୟମ୍ ଏଡିଟର୍ ଆସେଟ୍, ତେଲୁଗୁ ଫଣ୍ଟ୍ ଏବଂ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ହଟାଇବା ପାଇଁ ଏଡିଟର୍ ପ୍ରୋ ମାସକୁ ₹99 ରେ ପୃଥକ ଭାବରେ ଉପଲବ୍ଧ।',
      assamese: 'প্ৰিমিয়াম এডিটৰ সম্পদ, তেলেগু ফন্ট আৰু পটভূমি আঁতৰোৱাৰ বাবে এডিটৰ প্ৰʼ প্ৰতি মাহে ₹99 ত সুকীয়াকৈ উপলব্ধ।',
      konkani: 'ಪ್ರೀಮಿಯಂ ಎಡಿಟರ್ ಅಸೆಟ್ಸ್, ತೆಲುಗು ಫಾಂಟ್ಸ್ ಆನಿ ಬ್ಯಾಕ್‌ಗ್ರೌಂಡ್ ರಿಮೂವಲಾಕ್ ಎಡಿಟರ್ ಪ್ರೊ ಮಯ್ನ್ಯಾಕ್ ₹99 ದರಾನ್ ಪ್ರತ್ಯೇಕ್ ಮೆಳ್ತಾ.',
      nepali: 'प्रिमियम सम्पादक सम्पत्ति, तेलुगु फन्टहरू र पृष्ठभूमि हटाउनका लागि सम्पादक प्रो प्रति महिना ₹99 मा छुट्टै उपलब्ध छ।',
      meitei: 'প্রিমিয়ম এদিতর এসেতশিং, তেলুগু ফোন্তশিং অমসুং বেকগ্রাউন্দ লৌথোকপগীদমক এদিতর প্রো থা অমদা ₹99 দা তোঙান্না ফংই।',
      mizo: 'Premium editor assets, Telugu fonts leh background paihna tan Editor Pro hi thla tin ₹99-in a hrangin a awm bawk.',
      kashmiri: 'پریمیم ایڈیٹر اثاثہٕ، تیلگوٗ فونٛٹس تہٕ بیک گرٛاونٛڈ ہٹاونہٕ باپتھ چھُ ایڈیٹر پرو پرٛؠتھ رؠتہٕ ₹99 مَنٛز اَلگ دٔستیاب۔',
      ladakhi: 'རིན་མེད་མ་ཡིན་པའི་ཞུ་དག་ཆས་ཀྱི་རྒྱུ་ཆ། ཏེ་ལུ་གུ་ཡིག་གཟུགས་དང་རྒྱབ་ལྗོངས་སེལ་བའི་ཆེད་དུ་ཞུ་དག་ཆས་པྲོ་ཟླ་རེར་ ₹99 ལ་སོ་སོར་ཐོབ།',
    ),
    strings.localized(
      telugu: 'వార్షిక ప్లాన్ అందుబాటులో ఉన్న చోట ₹699 వార్షిక ఆల్-యాక్సెస్ ప్లాన్‌లో యాప్ ప్రో మరియు ఎడిటర్ ప్రో ప్రయోజనాలు రెండూ ఉంటాయి.',
      english: 'The ₹699 yearly all-access plan includes both App Pro and Editor Pro benefits where the yearly plan is available.',
      hindi: '₹699 का वार्षिक ऑल-एक्सेस प्लान ऐप प्रो और एडिटर प्रो दोनों लाभों को शामिल करता है जहाँ वार्षिक प्लान उपलब्ध है।',
      tamil: 'வருடாந்திர திட்டம் உள்ள இடங்களில் ₹699 வருடாந்திர ஆல்-ஆக்ஸஸ் திட்டம் ஆப் ப்ரோ மற்றும் எடிட்டர் ப்ரோ இரண்டின் பலன்களையும் உள்ளடக்கியது.',
      kannada: 'ವಾರ್ಷಿಕ ಯೋಜನೆ ಲಭ್ಯವಿರುವಲ್ಲಿ ₹699 ವಾರ್ಷಿಕ ಆಲ್-ಆಕ್ಸೆಸ್ ಯೋಜನೆಯು ಆ್ಯಪ್ ಪ್ರೊ ಮತ್ತು ಎಡಿಟರ್ ಪ್ರೊ ಎರಡರ ಪ್ರಯೋಜನಗಳನ್ನೂ ಒಳಗೊಂಡಿರುತ್ತದೆ.',
      malayalam: 'വാർഷിക പ്ലാൻ ലഭ്യമായ ഇടങ്ങളിൽ ₹699 വാർഷിക ഓൾ-ആക്സസ് പ്ലാനിൽ ആപ്പ് പ്രോ, എഡിറ്റർ പ്രോ ആനുകൂല്യങ്ങൾ ഉൾപ്പെടുന്നു.',
      marathi: 'वार्षिक योजना उपलब्ध असेल तिथे ₹699 च्या वार्षिक ऑल-अ‍ॅक्सेस प्लॅनमध्ये अ‍ॅप प्रो आणि एडिटर प्रो दोन्हीचे फायदे समाविष्ट आहेत.',
      gujarati: 'વાર્ષિક પ્લાન ઉપલબ્ધ હોય ત્યાં ₹699 ના વાર્ષિક ઓલ-એક્સેસ પ્લાનમાં એપ પ્રો અને એડિટર પ્રો બંનેના લાભો શામેલ છે.',
      bengali: 'যেখানে বার্ষিক প্ল্যান উপলব্ধ সেখানে ₹699 বার্ষিক অল-অ্যাক্সেস প্ল্যানে অ্যাপ প্রো এবং এডিটর প্রো উভয়ের সুবিধাই অন্তর্ভুক্ত রয়েছে।',
      punjabi: 'ਜਿੱਥੇ ਸਾਲਾਨਾ ਪਲਾਨ ਉਪਲਬਧ ਹੈ, ਉੱਥੇ ₹699 ਸਾਲਾਨਾ ਆਲ-ਐਕਸੈਸ ਪਲਾਨ ਵਿੱਚ ਐਪ ਪ੍ਰੋ ਅਤੇ ਐਡੀਟਰ ਪ੍ਰੋ ਦੋਵਾਂ ਦੇ ਲਾਭ ਸ਼ਾਮਲ ਹਨ।',
      odia: 'ଯେଉଁଠାରେ ବାର୍ଷିକ ଯୋଜନା ଉପଲବ୍ଧ, ସେଠାରେ ₹699 ବାର୍ଷିକ ଅଲ୍-ଆକ୍ସେସ୍ ଯୋଜନାରେ ଆପ୍ ପ୍ରୋ ଏବଂ ଏଡିଟର୍ ପ୍ରୋ ଉଭୟ ଲାଭ ଅନ୍ତର୍ଭୁକ୍ତ।',
      assamese: 'যʼত বাৰ্ষিক আঁচনি উপলব্ধ তাত ₹699 বাৰ্ষিক অল-এক্সেছ আঁচনিত এপ প্ৰʼ আৰু এডিটৰ প্ৰʼ দুয়োটাৰে সুবিধা অন্তৰ্ভুক্ত।',
      konkani: 'ವರ್ಸುಕೀ ಪ್ಲಾನ್ ಲಭ್ಯ್ ಆಸ್ಚೆ ಕಡೆನ್ ₹699 ವರ್ಸುಕೀ ಆಲ್-ಆಕ್ಸೆಸ್ ಪ್ಲಾನಾಂತ್ ಆ್ಯಪ್ ಪ್ರೊ ಆನಿ ಎಡಿಟರ್ ಪ್ರೊ ದೊನೀ ಫಾಯ್ದೆ ಆಸಾತ್.',
      nepali: 'वार्षिक योजना उपलब्ध भएको ठाउँमा ₹699 को वार्षिक अल-एक्सेस योजनामा एप प्रो र सम्पादक प्रो दुवैका फाइदाहरू समावेश छन्।',
      meitei: 'চহীগী প্লান ফংবা মফমদা ₹699 চহীগী ওল-এক্সেস প্লান অসিনা এপ প্রো অমসুং এদিতর প্রো অনিমক্কী কান্নবা য়াওরি।',
      mizo: 'Yearly plan a awmnaah ₹699 yearly all-access plan hian App Pro leh Editor Pro hlawkna a keng tel ve ve a ni.',
      kashmiri: 'وارشِک پلان دٔستیاب آسنہٕ وِزِ چھُ ₹699 سالانہٕ آل-ایکسیس پلانس مَنٛز ایپھ پرو تہٕ ایڈیٹر پرو دۄشوٕنی ہٕنٛدؠ فٲئدٕ شٲمِل۔',
      ladakhi: 'ལོ་རེའི་འཆར་གཞི་ཡོད་སར་ ₹699 གི་ལོ་རེའི་ཡོངས་ཁྱབ་འཆར་གཞི་ནང་ཨེཔ་པྲོ་དང་ཞུ་དག་ཆས་པྲོ་གཉིས་ཀའི་ཁེ་ཕན་ཚུད་ཡོད།',
    ),
  ];

  String get languagesTitle => strings.localized(
    telugu: 'అందుబాటులో ఉన్న భాషలు',
    english: 'Available languages',
    hindi: 'उपलब्ध भाषाएं',
    tamil: 'கிடைக்கும் மொழிகள்',
    kannada: 'ಲಭ್ಯವಿರುವ ಭಾಷೆಗಳು',
    malayalam: 'ലഭ്യമായ ഭാഷകൾ',
    marathi: 'उपलब्ध भाषा',
    gujarati: 'ઉપલબ્ધ ભાષાઓ',
    bengali: 'উপলব্ধ ভাষাসমূহ',
    punjabi: 'ਉਪਲਬਧ ਭਾਸ਼ਾਵਾਂ',
    odia: 'ଉପଲବ୍ଧ ଭାଷା',
    assamese: 'উপলব্ধ ভাষাসমূহ',
    konkani: 'ಲಭ್ಯ್ ಆಸ್ಚ್ಯೊ ಭಾಶೊ',
    nepali: 'उपलब्ध भाषाहरू',
    meitei: 'ফংলিবা লোলশিং',
    mizo: 'Tawng awmte',
    kashmiri: 'دٔستیاب زباننہٕ',
    ladakhi: 'ཐོབ་རུང་བའི་སྐད་རིགས།',
  );

  List<String> get languageItems => <String>[
    strings.localized(
      telugu: 'ఈ యాప్ తెలుగును ప్రాథమిక అనుభవంగా రూపొందించబడింది.',
      english: 'This app is designed with Telugu as the primary experience.',
      hindi: 'यह ऐप तेलुगु को प्राथमिक अनुभव मानकर डिज़ाइन किया गया है।',
      tamil: 'இந்த செயலி தெலுங்கை முதன்மை அனுபவமாகக் கொண்டு வடிவமைக்கப்பட்டுள்ளது.',
      kannada: 'ಈ ಆ್ಯಪ್ ಅನ್ನು ತೆಲುಗು ಪ್ರಾಥಮಿಕ ಅನುಭವವಾಗಿ ವಿನ್ಯಾಸಗೊಳಿಸಲಾಗಿದೆ.',
      malayalam: 'തെലുങ്ക് പ്രഥമ അനുഭവമായി ഈ ആപ്പ് രൂപകൽപ്പന ചെയ്തിരിക്കുന്നു.',
      marathi: 'हे अ‍ॅप तेलगूला प्राथमिक अनुभव मानून डिझाइन केलेले आहे.',
      gujarati: 'આ એપ તેલુગુને પ્રાથમિક અનુભવ તરીકે રાખીને ડિઝાઇન કરવામાં આવી છે.',
      bengali: 'এই অ্যাপটি তেলুগুকে প্রাথমিক অভিজ্ঞতা হিসেবে তৈরি করা হয়েছে।',
      punjabi: 'ਇਹ ਐਪ ਤੇਲਗੂ ਨੂੰ ਮੁੱਖ ਅਨੁਭਵ ਮੰਨ ਕੇ ਤਿਆਰ ਕੀਤੀ ਗਈ ਹੈ।',
      odia: 'ଏହି ଆପ୍ ତେଲୁଗୁକୁ ପ୍ରାଥମିକ ଅନୁଭୂତି ଭାବରେ ଡିଜାଇନ୍ କରାଯାଇଛି।',
      assamese: 'এই এপটো তেলেগুক প্ৰাথমিক অভিজ্ঞতা হিচাপে লৈ ডিজাইন কৰা হৈছে।',
      konkani: 'ಹೆಂ ಆ್ಯಪ್ ತೆಲುಗುಕ್ ಪ್ರಾಥಮಿಕ್ ಅನ್ಭವ್ ಜಾವ್ನ್ ಡಿಸೈನ್ ಕೆಲಾಂ.',
      nepali: 'यो एप तेलुगुलाई प्राथमिक अनुभवको रूपमा लिएर डिजाइन गरिएको हो।',
      meitei: 'এপ অসি তেলুগুবু অহানবা এক্সপেরিএন্স ওইনা শেম্বনি।',
      mizo: 'He app hi Telugu chu a bulthut ber tura duan a ni.',
      kashmiri: 'یہِ ایپھ چھُ تیلگوٗس گۄڈنیُک تجربہٕ مانِتھ ڈیزائن کَرنہٕ آمُت۔',
      ladakhi: 'ཨེཔ་འདི་ཏེ་ལུ་གུ་གཙོ་བོའི་ཉམས་མྱོང་ལ་དམིགས་ནས་བཟོས་པ་ཡིན།',
    ),
    strings.localized(
      telugu: 'దీనిని తెలుగు, హిందీ, ఇంగ్లీష్, తమిళం, కన్నడ, మలయాళం, అస్సామీ, కొంకణి, గుజరాతీ, మరాఠీ, మైతీ, మిజో, ఒడియా, పంజాబీ, నేపాలీ, బెంగాలీ, కాశ్మీరీ మరియు లడఖీ భాషలలో ఉపయోగించవచ్చు.',
      english: 'It can be used in Telugu, Hindi, English, Tamil, Kannada, Malayalam, Assamese, Konkani, Gujarati, Marathi, Meitei, Mizo, Odia, Punjabi, Nepali, Bengali, Kashmiri, and Ladakhi.',
      hindi: 'इसका उपयोग तेलुगु, हिंदी, अंग्रेजी, तमिल, कन्नड़, मलयालम, असमिया, कोंकणी, गुजराती, मराठी, मैतेई, मिज़ो, उड़िया, पंजाबी, नेपाली, बंगाली, कश्मीरी और लद्दाखी में किया जा सकता है।',
      tamil: 'இதை தெலுங்கு, இந்தி, ஆங்கிலம், தமிழ், கன்னடம், மலையாளம், அசாமி, கொங்கணி, குஜராத்தி, மராத்தி, மெய்தேய், மிசோரம், ஒடியா, பஞ்சாபி, நேபாளி, பெங்காலி, காஷ்மீரி மற்றும் லடாகி மொழிகளில் பயன்படுத்தலாம்.',
      kannada: 'ಇದನ್ನು ತೆಲುಗು, ಹಿಂದಿ, ಇಂಗ್ಲಿಷ್, ತಮಿಳು, ಕನ್ನಡ, ಮಲಯಾಳಂ, ಅಸ್ಸಾಮಿ, ಕೊಂಕಣಿ, ಗುಜರಾತಿ, ಮರಾಠಿ, ಮೈತೇಯಿ, ಮಿಜೋ, ಒಡಿಯಾ, ಪಂಜಾಬಿ, ನೇಪಾಳಿ, ಬೆಂಗಾಲಿ, ಕಾಶ್ಮೀರಿ ಮತ್ತು ಲಡಾಖಿ ಭಾಷೆಗಳಲ್ಲಿ ಬಳಸಬಹುದು.',
      malayalam: 'തെലുങ്ക്, ഹിന്ദി, ഇംഗ്ലീഷ്, തമിഴ്, കന്നഡ, മലയാളം, അസമീസ്, കൊങ്കണി, ഗുജറാത്തി, മറാത്തി, മെയ്തി, മിസോ, ഒഡിയ, പഞ്ചാബി, നേപ്പാളി, ബംഗാളി, കശ്മീരി, ലഡാക്കി ഭാഷകളിൽ ഇത് ഉപയോഗിക്കാം.',
      marathi: 'हे तेलगू, हिंदी, इंग्रजी, तमिळ, कन्नड, मल्याळम, आसामी, कोकणी, गुजराती, मराठी, मैतेई, मिझो, ओडिया, पंजाबी, नेपाळी, बंगाली, काश्मिरी आणि लडाखी भाषेत वापरता येते.',
      gujarati: 'તેનો ઉપયોગ તેલુગુ, હિન્દી, અંગ્રેજી, તમિલ, કન્નડ, મલયાલમ, આસામી, કોંકણી, ગુજરાતી, મરાઠી, મેઇતેઇ, મિઝો, ઓડિયા, પંજાબી, નેપાળી, બંગાળી, કાશ્મીરી અને લદ્દાખીમાં થઈ શકે છે.',
      bengali: 'এটি তেলুগু, হিন্দি, ইংরেজি, তামিল, কন্নড়, মালায়ালাম, অসমীয়া, কোঙ্কানি, গুজরাটি, মারাঠি, মৈতৈ, মিজো, ওড়িয়া, পাঞ্জাবি, নেপালি, বাংলা, কাশ্মীরি এবং লাদাখিতে ব্যবহার করা যেতে পারে।',
      punjabi: 'ਇਸਦੀ ਵਰਤੋਂ ਤੇਲਗੂ, ਹਿੰਦੀ, ਅੰਗਰੇਜ਼ੀ, ਤਾਮਿਲ, ਕੰਨੜ, ਮਲਿਆਲਮ, ਅਸਾਮੀ, ਕੋਂਕਣੀ, ਗੁਜਰਾਤੀ, ਮਰਾਠੀ, ਮੇਈਤੇਈ, ਮਿਜ਼ੋ, ਉੜੀਆ, ਪੰਜਾਬੀ, ਨੇਪਾਲੀ, ਬੰਗਾਲੀ, ਕਸ਼ਮੀਰੀ ਅਤੇ ਲਦਾਖੀ ਵਿੱਚ ਕੀਤੀ ਜਾ ਸਕਦੀ ਹੈ।',
      odia: 'ଏହାକୁ ତେଲୁଗୁ, ହିନ୍ଦୀ, ଇଂରାଜୀ, ତାମିଲ, କନ୍ନଡ, ମାଲାୟାଲମ୍, ଆସାମୀ, କୋଙ୍କଣୀ, ଗୁଜରାଟୀ, ମରାଠୀ, ମେଇତେଇ, ମିଜୋ, ଓଡ଼ିଆ, ପଞ୍ଜାବୀ, ନେପାଳୀ, ବଙ୍ଗାଳୀ, କାଶ୍ମୀରୀ ଏବଂ ଲଦାଖୀରେ ବ୍ୟବହାର କରାଯାଇପାରିବ।',
      assamese: 'ইয়াক তেলেগু, হিন্দী, ইংৰাজী, তামিল, কন্নড়, মালয়ালম, অসমীয়া, কোংকণী, গুজৰাটী, মাৰাঠী, মৈতৈ, মিজো, ওড়িয়া, পঞ্জাবী, নেপালী, বাংলা, কাশ্মীৰী আৰু লাডাখীত ব্যৱহাৰ কৰিব পাৰি।',
      konkani: 'ಹೆಂ ತೆಲುಗು, ಹಿಂದಿ, ಇಂಗ್ಲಿಷ್, ತಮಿಳು, ಕನ್ನಡ, ಮಲಯಾಳಂ, ಅಸ್ಸಾಮಿ, ಕೊಂಕಣಿ, ಗುಜರಾತಿ, ಮರಾಠಿ, ಮೈತೇಯಿ, ಮಿಜೋ, ಒಡಿಯಾ, ಪಂಜಾಬಿ, ನೇಪಾಳಿ, ಬೆಂಗಾಲಿ, ಕಾಶ್ಮೀರಿ ಆನಿ ಲಡಾಖಿಂತ್ ವಾಪರುಂಕ್ ಜಾತಾ.',
      nepali: 'यसलाई तेलुगु, हिन्दी, अंग्रेजी, तमिल, कन्नड, मलयालम, असमिया, कोंकणी, गुजराती, मराठी, मेइतेई, मिजो, ओडिया, पंजाबी, नेपाली, बंगाली, कश्मीरी र लद्दाखीमा प्रयोग गर्न सकिन्छ।',
      meitei: 'মসি তেলুগু, হিন্দি, ইংলিশ, তামিল, কন্নদ, মলয়ালম, অসমীয়া, কোঙ্কনি, গুজরাতি, মারাঠী, মৈতৈলোন্, মিজো, ওড়িয়া, পঞ্জাবী, নেপালী, বাংলা, কাশ্মীরী অমসুং লাদাখিগী লোলশিংদা শীজিন্নবা য়াই।',
      mizo: 'Telugu, Hindi, English, Tamil, Kannada, Malayalam, Assamese, Konkani, Gujarati, Marathi, Meitei, Mizo, Odia, Punjabi, Nepali, Bengali, Kashmiri leh Ladakhi tawngin a hman theih.',
      kashmiri: 'یہِ ہیکو تیلگوٗ، ہِندی، اَنٛگریٖزی، تَمِل، کَنَّڑ، مَلیالم، اَسامی، کونکَنی، گُجرٲتی، مَرٲٹھی، میتئی، میزو، اوڈِیا، پَنجٲبی، نیپٲلی، بَنٛگٲلی، کٲشُر تہٕ لَدّﺎخی مَنٛز اِستعمال کٔرِتھ۔',
      ladakhi: 'འདི་ཏེ་ལུ་གུ། ཧིན་དྷི། དབྱིན་ཇི། ཏ་མིལ། ཀན་ན་ཌ། མ་ལ་ཡ་ལམ། ཨ་ས་མིས། ཀོན་ཀ་ཎི། གུ་ཇ་ར་ཏི། མ་ར་ཋི། མེའི་ཏེའི། མི་ཛོ། ཨོ་ཌི་ཡ། པན་ཇ་བི། ནེ་པ་ལི། བངྒ་ལི། ཀཤྨི་རི་དང་ལ་དྭགས་སྐད་ཐོག་སྤྱོད་ཐུབ།',
    ),
    strings.localized(
      telugu: 'ఎంచుకున్న రాష్ట్రం లేదా కేంద్రపాలిత ప్రాంతం నుండి సరిపోలే భాష వర్తించబడుతుంది; ప్రధాన యాప్ స్క్రీన్లు ప్రాంతీయ అనువాదాలను ఉపయోగిస్తాయి, అయితే కొన్ని ఎడిటర్ లేదా సాంకేతిక లేబుల్స్ ఇంగ్లీష్‌లోనే ఉండవచ్చు.',
      english: 'The matching language is applied from the selected State or Union Territory; core app screens use regional translations, while some editor or file-format technical labels may remain in English.',
      hindi: 'चुने गए राज्य या केंद्र शासित प्रदेश से मिलान वाली भाषा लागू की जाती है; मुख्य ऐप स्क्रीन क्षेत्रीय अनुवादों का उपयोग करती हैं, जबकि कुछ संपादक या तकनीकी लेबल अंग्रेजी में रह सकते हैं।',
      tamil: 'தேர்ந்தெடுக்கப்பட்ட மாநிலம் அல்லது யூனியன் பிரதேசத்திலிருந்து பொருந்தும் மொழி பயன்படுத்தப்படுகிறது; முதன்மை திரைகள் பிராந்திய மொழியைப் பயன்படுத்துகின்றன, எடிட்டரின் சில தொழில்நுட்ப பெயர்கள் ஆங்கிலத்தில் இருக்கலாம்.',
      kannada: 'ಆಯ್ಕೆಮಾಡಿದ ರಾಜ್ಯ ಅಥವಾ ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶದಿಂದ ಹೊಂದಿಕೆಯಾಗುವ ಭಾಷೆಯನ್ನು ಅನ್ವಯಿಸಲಾಗುತ್ತದೆ; ಪ್ರಮುಖ ಪರದೆಗಳು ಪ್ರಾದೇಶಿಕ ಅನುವಾದಗಳನ್ನು ಬಳಸುತ್ತವೆ, ಕೆಲವು ತಾಂತ್ರಿಕ ಲೇಬಲ್‌ಗಳು ಇಂಗ್ಲಿಷ್‌ನಲ್ಲಿರಬಹುದು.',
      malayalam: 'തിരഞ്ഞെടുത്ത സംസ്ഥാനം അല്ലെങ്കിൽ കേന്ദ്രഭരണ പ്രദേശത്ത് നിന്നുള്ള അനുയോജ്യമായ ഭാഷ ബാധകമാക്കുന്നു; പ്രധാന സ്ക്രീനുകൾ പ്രാദേശിക വിവർത്തനങ്ങൾ ഉപയോഗിക്കുന്നു, ചില സാങ്കേതിക ലേബലുകൾ ഇംഗ്ലീഷിൽ തുടരാം.',
      marathi: 'निवडलेल्या राज्य किंवा केंद्रशासित प्रदेशातून जुळणारी भाषा लागू केली जाते; मुख्य स्क्रीन प्रादेशिक भाषा वापरतात, तर काही तांत्रिक लेबले इंग्रजीत राहू शकतात.',
      gujarati: 'પસંદ કરેલ રાજ્ય અથવા કેન્દ્રશાસિત પ્રદેશમાંથી મેળ ખાતી ભાષા લાગુ થાય છે; મુખ્ય એપ સ્ક્રીનો પ્રાદેશિક અનુવાદોનો ઉપયોગ કરે છે, જ્યારે કેટલાક તકનીકી લેબલ્સ અંગ્રેજીમાં રહી શકે છે.',
      bengali: 'নির্বাচিত রাজ্য বা কেন্দ্রশাসিত অঞ্চল থেকে উপযুক্ত ভাষা প্রয়োগ করা হয়; মূল অ্যাপ স্ক্রিনগুলিতে আঞ্চলিক অনুবাদ ব্যবহৃত হয়, তবে কিছু প্রযুক্তিগত লেবেল ইংরেজিতে থাকতে পারে।',
      punjabi: 'ਚੁਣੇ ਗਏ ਰਾਜ ਜਾਂ ਕੇਂਦਰ ਸ਼ਾਸਿਤ ਪ੍ਰਦੇਸ਼ ਤੋਂ ਮੇਲ ਖਾਂਦੀ ਭਾਸ਼ਾ ਲਾਗੂ ਕੀਤੀ ਜਾਂਦੀ ਹੈ; ਮੁੱਖ ਐਪ ਸਕ੍ਰੀਨਾਂ ਖੇਤਰੀ ਅਨੁਵਾਦਾਂ ਦੀ ਵਰਤੋਂ ਕਰਦੀਆਂ ਹਨ, ਜਦੋਂ ਕਿ ਕੁਝ ਤਕਨੀਕੀ ਲੇਬਲ ਅੰਗਰੇਜ਼ੀ ਵਿੱਚ ਰਹਿ ਸਕਦੇ ਹਨ।',
      odia: 'ମନୋନୀତ ରାଜ୍ୟ ବା କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳରୁ ମେଳ ଖାଉଥିବା ଭାଷା ପ୍ରୟୋଗ କରାଯାଏ; ମୁଖ୍ୟ ସ୍କ୍ରିନ୍ ଆଞ୍ଚଳିକ ଅନୁବାଦ ବ୍ୟବହାର କରେ, କିଛି ବୈଷୟିକ ଲେବଲ୍ ଇଂରାଜୀରେ ରହିପାରେ।',
      assamese: 'নিৰ্বাচিত ৰাজ্য বা কেন্দ্ৰীয় শাসিত অঞ্চলৰ পৰা মিল থকা ভাষা প্ৰয়োগ কৰা হয়; মূল এপ স্ক্ৰীণসমূহে আঞ্চলিক অনুবাদ ব্যৱহাৰ কৰে, কিন্তু কিছুমান কাৰিকৰী লেবেল ইংৰাজীতে থাকিব পাৰে।',
      konkani: 'ವಿಂಚ್ಲ್ಯಾ ರಾಜ್ಯಾ ಥಾವ್ನ್ ಸಾರ್ಕಿ ಭಾಸ್ ಅನ್ವಯ್ ಜಾತಾ; ಮುಕೆಲ್ ಸ್ಕ್ರೀನಾಂ ಪ್ರಾದೇಶಿಕ್ ಭಾಸ್ ವಾಪರ್ತಾತ್, ಜಾಲ್ಯಾರೀ ಥೊಡೆ ತಾಂತ್ರಿಕ್ ಲೇಬಲ್ಸ್ ಇಂಗ್ಲಿಷಾಂತ್ ಆಸುಂಕ್ ಸಕ್ತಾತ್.',
      nepali: 'चयन गरिएको राज्य वा केन्द्रशासित प्रदेशबाट मिल्दो भाषा लागू हुन्छ; मुख्य एप स्क्रिनहरूले क्षेत्रीय अनुवाद प्रयोग गर्छन्, जबकि केही प्राविधिक लेबलहरू अंग्रेजीमा रहन सक्छन्।',
      meitei: 'খনরবা স্তেত নত্রগা য়ুনিয়ন তেরিতোরিদগী চানবা লোল অদু চৎনহল্লি; মরুওইবা স্ক্রিনশিংনা মফমদুগী লোল শীজিন্নৈ, অদুবু তেক্নিকেল ওইবা লেবেল খরদি ইংলিশতা লৈবা য়াই।',
      mizo: 'State emaw Union Territory thlan atangin tawng inmil chu hman a ni a; app screen pawimawhte chuan regional translation an hmang a, editor technical label thenkhat erawh English-in a awm thei.',
      kashmiri: 'مُنتخَب رِیاسَت یا مرکز کِس زیرِ اِنتظام علاقہٕ پؠٹھٕ چھِ رَلان زَبان لاگوٗ گَژھان؛ اَہَم سکرین چھِ علاقٲیی ترجَمہٕ اِستعمال کَران، حالانکہِ کینٛہہ تکنیکی لیبل ہؠکن اَنٛگریٖزی مَنٛز رٲزِتھ۔',
      ladakhi: 'བདམས་པའི་མངའ་སྡེའམ་དབུས་གཞུང་ཁྱབ་ཁོངས་ནས་འོས་པའི་སྐད་རིགས་སྤྱོད་ཅིང་། གཙོ་བོའི་ཤོག་ངོས་རྣམས་སུ་ས་གནས་སྐད་རིགས་སྤྱོད་ཀྱང་འཕྲུལ་རིག་གི་མིང་བྱང་ལ་ལོ་དབྱིན་ཇིར་ལུས་སྲིད།',
    ),
  ];

  String get supportTitle => strings.localized(
    telugu: 'మద్దతు మరియు సంప్రదింపు',
    english: 'Support and contact',
    hindi: 'सहायता और संपर्क',
    tamil: 'ஆதரவு மற்றும் தொடர்பு',
    kannada: 'ಬೆಂಬಲ ಮತ್ತು ಸಂಪರ್ಕ',
    malayalam: 'സഹായവും ബന്ധപ്പെടലും',
    marathi: 'मदत आणि संपर्क',
    gujarati: 'સહાય અને સંપર્ક',
    bengali: 'সহায়তা এবং যোগাযোগ',
    punjabi: 'ਸਹਾਇਤਾ ਅਤੇ ਸੰਪਰਕ',
    odia: 'ସହାୟତା ଏବଂ ଯୋଗାଯୋଗ',
    assamese: 'সহায় আৰু যোগাযোগ',
    konkani: 'ಆಧಾರ್ ಆನಿ ಸಂಪರ್ಕ್',
    nepali: 'समर्थन र सम्पर्क',
    meitei: 'সপোর্ত অমসুং কন্টেক্ত',
    mizo: 'Tanpuina leh biak pawhna',
    kashmiri: 'مَدَتھ تہٕ ر رابطہٕ',
    ladakhi: 'རྒྱབ་སྐྱོར་དང་འབྲེལ་གཏུགས།',
  );

  String get supportBody => strings.localized(
    telugu: 'లాగిన్ సమస్యలు, ఫోటో ఎంపిక లేదా అప్‌లోడ్ సమస్యలు, సేవ్ లేదా ఎక్స్‌పోర్ట్ సమస్యలు, సబ్‌స్క్రిప్షన్ సందేహాలు లేదా సాధారణ యాప్ మద్దతు కోసం ఈ ఈమెయిల్‌ను ఉపయోగించండి. ప్రైవసీ పాలసీ మరియు నిబంధనలు కూడా యాప్‌లోనే అందుబాటులో ఉన్నాయి.',
    english: 'Use this email for login problems, photo selection or upload issues, save or export problems, subscription questions, or general app support. Privacy Policy and Terms & Conditions are also available inside the app.',
    hindi: 'लॉगिन समस्याओं, फोटो चयन या अपलोड समस्याओं, सेव या निर्यात समस्याओं, सदस्यता प्रश्नों या सामान्य ऐप सहायता के लिए इस ईमेल का उपयोग करें। गोपनीयता नीति और नियम व शर्तें भी ऐप के अंदर उपलब्ध हैं।',
    tamil: 'உள்நுழைவுச் சிக்கல்கள், புகைப்படத் தேர்வு அல்லது பதிவேற்றச் சிக்கல்கள், சேமிப்பு அல்லது ஏற்றுமதிச் சிக்கல்கள், சந்தா கேள்விகள் அல்லது பொதுவான செயலி ஆதரவுக்கு இந்த மின்னஞ்சலைப் பயன்படுத்தவும். தனியுரிமைக் கொள்கை மற்றும் விதிமுறைகளும் செயலியின் உள்ளே உள்ளன.',
    kannada: 'ಲಾಗಿನ್ ಸಮಸ್ಯೆಗಳು, ಫೋಟೋ ಆಯ್ಕೆ ಅಥವಾ ಅಪ್‌ಲೋಡ್ ಸಮಸ್ಯೆಗಳು, ಉಳಿಸುವ ಅಥವಾ ರಫ್ತು ಸಮಸ್ಯೆಗಳು, ಚಂದಾದಾರಿಕೆ ಪ್ರಶ್ನೆಗಳು ಅಥವಾ ಸಾಮಾನ್ಯ ಆ್ಯಪ್ ಬೆಂಬಲಕ್ಕಾಗಿ ಈ ಇಮೇಲ್ ಬಳಸಿ. ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ನಿಯಮಗಳು ಆ್ಯಪ್‌ನಲ್ಲಿ ಲಭ್ಯವಿವೆ.',
    malayalam: 'ലോഗിൻ പ്രശ്നങ്ങൾ, ഫോട്ടോ തിരഞ്ഞെടുക്കൽ അല്ലെങ്കിൽ അപ്‌ലോഡ് പ്രശ്നങ്ങൾ, സേവ് അല്ലെങ്കിൽ എക്സ്പോർട്ട് പ്രശ്നങ്ങൾ, സബ്‌സ്‌ക്രിപ്ഷൻ സംശയങ്ങൾ അല്ലെങ്കിൽ പൊതുവായ ആപ്പ് പിന്തുണ എന്നിവയ്ക്കായി ഈ ഇമെയിൽ ഉപയോഗിക്കുക. സ്വകാര്യതാ നയവും നിബന്ധനകളും ആപ്പിൽ ലഭ്യമാണ്.',
    marathi: 'लॉगिन समस्या, फोटो निवड किंवा अपलोड समस्या, सेव्ह किंवा निर्यात समस्या, सदस्यता प्रश्न किंवा सामान्य अ‍ॅप समर्थनासाठी हा ईमेल वापरा. गोपनीयता धोरण आणि नियम व अटी देखील अ‍ॅपमध्ये उपलब्ध आहेत.',
    gujarati: 'લૉગિન સમસ્યાઓ, ફોટો પસંદગી અથવા અપલોડ સમસ્યાઓ, સેવ અથવા નિકાસ સમસ્યાઓ, સબ્સ્ક્રિપ્શન પ્રશ્નો અથવા સામાન્ય એપ સપોર્ટ માટે આ ઇમેઇલનો ઉપયોગ કરો. ગોપનીયતા નીતિ અને નિયમો અને શરતો પણ એપની અંદર ઉપલબ્ધ છે.',
    bengali: 'লগইন সমস্যা, ছবি নির্বাচন বা আপলোড সমস্যা, সংরক্ষণ বা রপ্তানি সমস্যা, সাবস্ক্রিপশন প্রশ্ন বা সাধারণ অ্যাপ সহায়তার জন্য এই ইমেল ব্যবহার করুন। গোপনীয়তা নীতি এবং শর্তাবলীও অ্যাপের মধ্যে উপলব্ধ।',
    punjabi: 'ਲਾਗਇਨ ਸਮੱਸਿਆਵਾਂ, ਫੋਟੋ ਚੋਣ ਜਾਂ ਅੱਪਲੋਡ ਸਮੱਸਿਆਵਾਂ, ਸੁਰੱਖਿਅਤ ਜਾਂ ਨਿਰਯਾਤ ਸਮੱਸਿਆਵਾਂ, ਗਾਹਕੀ ਸਵਾਲਾਂ ਜਾਂ ਆਮ ਐਪ ਸਹਾਇਤਾ ਲਈ ਇਸ ਈਮੇਲ ਦੀ ਵਰਤੋਂ ਕਰੋ। ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਅਤੇ ਨਿਯਮ ਤੇ ਸ਼ਰਤਾਂ ਵੀ ਐਪ ਦੇ ਅੰਦਰ ਉਪਲਬਧ ਹਨ।',
    odia: 'ଲଗଇନ୍ ସମସ୍ୟା, ଫଟୋ ଚୟନ ବା ଅପଲୋଡ୍ ସମସ୍ୟା, ସେଭ୍ ବା ରପ୍ତାନି ସମସ୍ୟା, ସଦସ୍ୟତା ପ୍ରଶ୍ନ କିମ୍ବା ସାଧାରଣ ଆପ୍ ସହାୟତା ପାଇଁ ଏହି ଇମେଲ୍ ବ୍ୟବହାର କରନ୍ତୁ। ଗୋପନୀୟତା ନୀତି ଏବଂ ନିୟମାବଳୀ ମଧ୍ୟ ଆପ୍ ଭିତରେ ଉପଲବ୍ଧ।',
    assamese: 'লগইন সমস্যা, ফটো বাছনি বা আপলোডৰ সমস্যা, সংৰক্ষণ বা ৰপ্তানিৰ সমস্যা, গ্ৰাহকভুক্তি সম্পৰ্কীয় প্ৰশ্ন বা সাধাৰণ এপ সাহায্যৰ বাবে এই ইমেইল ব্যৱহাৰ কৰক। গোপনীয়তা নীতি আৰু নিয়ম-চৰ্তাৱলীও এপৰ ভিতৰতে উপলব্ধ।',
    konkani: 'ಲಾಗ್ ಇನ್ ತ್ರಾಸ್, ಫೋಟೋ ವಿಂಚುಂಕ್ ಯಾ ಅಪ್‌ಲೋಡ್ ಕರ್ಚೆ ತ್ರಾಸ್, ಸಾಂಭಾಳ್ಚೆ ಯಾ ಎಕ್ಸ್‌ಪೋರ್ಟ್ ಕರ್ಚೆ ತ್ರಾಸ್, ಸಬ್‌ಸ್ಕ್ರಿಪ್ಶನ್ ಸವಾಲಾಂ ಯಾ ಸಾಧಾರಣ್ ಆ್ಯಪ್ ಆಧಾರ್ ಖಾತೀರ್ ಹ್ಯಾ ಇಮೇಲಾಕ್ ಸಂಪರ್ಕ್ ಕರಾ. ಪ್ರೈವಸಿ ಪಾಲಿಸಿ ಆನಿ ನಿಬಂಧನಾಂ ಆ್ಯಪಾಂತ್ ಲಭ್ಯ್ ಆಸಾತ್.',
    nepali: 'लगइन समस्याहरू, फोटो चयन वा अपलोड समस्याहरू, बचत वा निर्यात समस्याहरू, सदस्यता प्रश्नहरू वा सामान्य एप समर्थनको लागि यो इमेल प्रयोग गर्नुहोस्। गोपनीयता नीति र नियम तथा सर्तहरू पनि एप भित्र उपलब्ध छन्।',
    meitei: 'লগইন সমস্যশিং, ফোতো খনবা নত্রগা অপলোদ সমস্যশিং, সেভ নত্রগা এক্সপোর্ত সমস্যশিং, সবস্ক্রিপ্সন ৱাহংশিং নত্রগা অপুনবা এপ সপোর্তকীদমক ইমেল অসি শীজিন্নবীয়ু। প্রাইভেসি পোলিসি অমসুং তর্মশিং এপ মনুংদা ফংই।',
    mizo: 'Login harsatna, thlalak thlan emaw upload harsatna, save emaw export harsatna, subscription zawhna emaw tlangpui app tanpuina tan he email hi hmang rawh. Privacy Policy leh Terms & Conditions pawh app chhungah a awm bawk.',
    kashmiri: 'لاگ اِن مُشکِلات، فوٹو اِنتخاب یا اَپلوڈ مَسلہٕ، مَحفوٗظ یا برآمد مَسلہٕ، سبسکرپشن سوالات، یا عام ایپھ مددِ باپتھ کٔریو یہِ اِی میل اِستعمال۔ رازدٲری ہٕنٛز پالیسی تہٕ شرائط چھِ ایپس اندر تہِ دٔستیاب۔',
    ladakhi: 'ནང་འཛུལ་དཀའ་ངལ། འདྲ་པར་འདེམས་པའམ་ཡར་འཇུག་གི་དཀའ་ངལ། ཉར་ཚགས་སམ་ཕྱིར་འདྲེན་གྱི་དཀའ་ངལ། མངགས་ཉོའི་དྲི་བའམ་སྤྱིར་བཏང་ཨེཔ་རོགས་རམ་གྱི་ཆེད་དུ་གློག་འཕྲིན་འདི་སྤྱོད། གསང་རྒྱའི་སྲིད་ཇུས་དང་ཆart་རྐྱེན་རྣམས་ཀྱང་ཨེཔ་ནང་དུ་ཡོད།',
  );

  String get privacyButton => strings.localized(
    telugu: 'గోప్యతా విధానం చూడండి',
    english: 'View Privacy Policy',
    hindi: 'गोपनीयता नीति देखें',
    tamil: 'தனியுரிமைக் கொள்கையைக் காண்க',
    kannada: 'ಗೌಪ್ಯತಾ ನೀತಿಯನ್ನು ವೀಕ್ಷಿಸಿ',
    malayalam: 'സ്വകാര്യതാ നയം കാണുക',
    marathi: 'गोपनीयता धोरण पहा',
    gujarati: 'ગોપનીયતા નીતિ જુઓ',
    bengali: 'গোপনীয়তা নীতি দেখুন',
    punjabi: 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਦੇਖੋ',
    odia: 'ଗୋପନୀୟତା ନୀତି ଦେଖନ୍ତୁ',
    assamese: 'গোপনীয়তা নীতি চাওক',
    konkani: 'ಗೌಪ್ಯತಾ ನೀತಿ ಪಳಯಾ',
    nepali: 'गोपनीयता नीति हेर्नुहोस्',
    meitei: 'প্রাইভেসি পোলিসি য়েংবীয়ু',
    mizo: 'Privacy Policy en rawh',
    kashmiri: 'رازدٲری ہٕنٛز پالیسی وُچھِو',
    ladakhi: 'གསང་རྒྱའི་སྲིད་ཇུས་ལྟོས།',
  );

  String get termsButton => strings.localized(
    telugu: 'నిబంధనలు మరియు షరతులు చూడండి',
    english: 'View Terms & Conditions',
    hindi: 'नियम और शर्तें देखें',
    tamil: 'விதிமுறைகள் மற்றும் நிபந்தனைகளைக் காண்க',
    kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
    malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും കാണുക',
    marathi: 'नियम आणि अटी पहा',
    gujarati: 'નિયમો અને શરતો જુઓ',
    bengali: 'শর্তাবলী দেখুন',
    punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ ਦੇਖੋ',
    odia: 'ନିୟମ ଏବଂ ସର୍ତ୍ତାବଳୀ ଦେଖନ୍ତୁ',
    assamese: 'নিয়ম আৰু চৰ্তাৱলী চাওক',
    konkani: 'ನಿಬಂಧನಾಂ ಆನಿ ಶರತಾಂ ಪಳಯಾ',
    nepali: 'नियम र सर्तहरू हेर्नुहोस्',
    meitei: 'তর্মস অমসুং কন্দিসনশিং য়েংবীয়ু',
    mizo: 'Terms & Conditions en rawh',
    kashmiri: 'شرائط و ضوابط وُچھِو',
    ladakhi: 'ཆart་རྐྱེན་རྣམས་ལྟོས།',
  );
}