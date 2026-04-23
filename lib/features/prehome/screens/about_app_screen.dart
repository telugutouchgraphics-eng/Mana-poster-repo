import 'package:flutter/material.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const String _versionName = '1.0.0';
  static const String _buildNumber = '1';
  static const String _supportEmail = AppPublicInfo.supportEmail;

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
            top: -110,
            right: -40,
            child: _BlurOrb(size: 220, color: const Color(0x3322C55E)),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: _BlurOrb(size: 180, color: const Color(0x332563EB)),
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
                    colors: <Color>[
                      Color(0xFFE6F8EC),
                      Color(0xFFEAF1FF),
                      Color(0xFFFFFFFF),
                    ],
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x120F172A),
                      blurRadius: 30,
                      offset: Offset(0, 18),
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
                                color: Color(0x140F172A),
                                blurRadius: 16,
                                offset: Offset(0, 8),
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
                    LayoutBuilder(
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
                                value: _versionName,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _HeroStatCard(
                                label: copy.buildPill,
                                value: _buildNumber,
                              ),
                            ),
                          ],
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
              _SectionLabel(title: copy.subscriptionTitle),
              const SizedBox(height: 8),
              _ChecklistSection(
                title: copy.subscriptionTitle,
                items: copy.subscriptionItems,
              ),
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
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalDocumentScreen(
                                  documentType: LegalDocumentType.privacyPolicy,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: _LegalActionButton(
                          label: copy.termsButton,
                          icon: Icons.article_outlined,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalDocumentScreen(
                                  documentType:
                                      LegalDocumentType.termsAndConditions,
                                ),
                              ),
                            );
                          },
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
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
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
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
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
              color: Color(0x0D0F172A),
              blurRadius: 14,
              offset: Offset(0, 8),
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
    tamil: 'ஆப் பற்றி',
    kannada: 'ಅಪ್ ಬಗ್ಗೆ',
    malayalam: 'ആപ്പിനെക്കുറിച്ച്',
  );

  String get appName => 'Mana Poster';

  String get heroSubtitle => strings.localized(
    telugu: 'పోస్టర్లు సులభంగా రూపొందించుకునే తెలుగు-ఫస్ట్ యాప్',
    english: 'A Telugu-first app for creating posters with ease',
    hindi: 'पोस्टर आसानी से बनाने के लिए तेलुगु-फर्स्ट ऐप',
    tamil: 'போஸ்டர்களை எளிதாக உருவாக்கும் தெலுங்கு-முதல் ஆப்',
    kannada: 'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಸುಲಭವಾಗಿ ರಚಿಸಲು ತೆಲುಗು-ಫಸ್ಟ್ ಆಪ್',
    malayalam:
        'പോസ്റ്ററുകൾ എളുപ്പത്തിൽ തയ്യാറാക്കാൻ സഹായിക്കുന്ന തെലുങ്ക്-ഫസ്റ്റ് ആപ്പ്',
  );

  String get heroBody => strings.localized(
    telugu:
        'Mana Poster ద్వారా శుభాకాంక్షలు, పండుగ పోస్టర్లు, బిజినెస్ ప్రమోషన్ డిజైన్లు, భక్తి పోస్టర్లు, ప్రత్యేక సందర్భాల పోస్టర్లు వంటి వాటిని వేగంగా ఎంచుకుని మీ వివరాలతో వ్యక్తిగతంగా మార్చుకోవచ్చు. మొబైల్‌లోనే చూసి, ఎంపిక చేసి, సవరించి, షేర్ చేయడానికి సరళమైన పని విధానం ఈ యాప్‌లో అందుబాటులో ఉంటుంది.',
    english:
        'Mana Poster helps users quickly choose, personalize, and share greeting posters, festival designs, business promotions, devotional content, and other occasion-based posters. The app is built around a simple mobile workflow for browsing, editing, and sharing in one place.',
    hindi:
        'Mana Poster की मदद से शुभकामना पोस्टर, त्योहार डिज़ाइन, बिज़नेस प्रमोशन पोस्टर, भक्ति पोस्टर और खास मौकों के पोस्टर जल्दी चुनकर अपनी जानकारी के साथ निजी रूप में तैयार किए जा सकते हैं। मोबाइल पर ही देखना, चुनना, संपादित करना और साझा करना आसान बनाया गया है।',
    tamil:
        'Mana Poster மூலம் வாழ்த்து போஸ்டர்கள், திருவிழா வடிவங்கள், வணிக விளம்பர போஸ்டர்கள், பக்தி போஸ்டர்கள் மற்றும் சிறப்பு நாள் வடிவங்களை விரைவாக தேர்வு செய்து, உங்கள் விவரங்களுடன் தனிப்பயனாக்கலாம். மொபைலில் பார்த்து, தேர்வு செய்து, திருத்தி, பகிர்வதற்கான எளிய நடைமுறை இந்த ஆப்பில் உள்ளது.',
    kannada:
        'Mana Poster ಮೂಲಕ ಶುಭಾಶಯ ಪೋಸ್ಟರ್‌ಗಳು, ಹಬ್ಬದ ವಿನ್ಯಾಸಗಳು, ವ್ಯವಹಾರ ಪ್ರಚಾರ ಪೋಸ್ಟರ್‌ಗಳು, ಭಕ್ತಿಪರ ಪೋಸ್ಟರ್‌ಗಳು ಮತ್ತು ವಿಶೇಷ ಸಂದರ್ಭಗಳ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ವೇಗವಾಗಿ ಆಯ್ಕೆ ಮಾಡಿ ನಿಮ್ಮ ವಿವರಗಳೊಂದಿಗೆ ವೈಯಕ್ತಿಕಗೊಳಿಸಬಹುದು. ಮೊಬೈಲ್‌ನಲ್ಲೇ ನೋಡಲು, ಆಯ್ಕೆ ಮಾಡಲು, ತಿದ್ದುಪಡಿ ಮಾಡಲು ಮತ್ತು ಹಂಚಿಕೊಳ್ಳಲು ಸರಳವಾದ ಕ್ರಮವನ್ನು ಈ ಆಪ್ ನೀಡುತ್ತದೆ.',
    malayalam:
        'Mana Poster ഉപയോഗിച്ച് ആശംസാ പോസ്റ്ററുകൾ, ഉത്സവ ഡിസൈനുകൾ, ബിസിനസ് പ്രമോഷൻ പോസ്റ്ററുകൾ, ഭക്തിപരമായ പോസ്റ്ററുകൾ, പ്രത്യേക ദിവസങ്ങളിലെ പോസ്റ്ററുകൾ എന്നിവ വേഗത്തിൽ തിരഞ്ഞെടുക്കി നിങ്ങളുടെ വിവരങ്ങൾ ചേർത്ത് വ്യക്തിപരമാക്കാം. മൊബൈലിൽ തന്നെ കാണുക, തിരഞ്ഞെടുക്കുക, തിരുത്തുക, പങ്കിടുക എന്ന ലളിതമായ പ്രവൃത്തി രീതിയാണ് ഈ ആപ്പിന്റെ പ്രത്യേകത.',
  );

  String get teluguFirstPill => strings.localized(
    telugu: 'తెలుగు-ఫస్ట్ అనుభవం',
    english: 'Telugu-first experience',
    hindi: 'तेलुगु-फर्स्ट अनुभव',
    tamil: 'தெலுங்கு-முதல் அனுபவம்',
    kannada: 'ತೆಲುಗು-ಫಸ್ಟ್ ಅನುಭವ',
    malayalam: 'തെലുങ്ക്-ഫസ്റ്റ് അനുഭവം',
  );

  String get versionPill => strings.localized(
    telugu: 'వెర్షన్',
    english: 'Version',
    hindi: 'वर्ज़न',
    tamil: 'பதிப்பு',
    kannada: 'ಆವೃತ್ತಿ',
    malayalam: 'വർഷൻ',
  );

  String get buildPill => strings.localized(
    telugu: 'బిల్డ్',
    english: 'Build',
    hindi: 'बिल्ड',
    tamil: 'பில்ட்',
    kannada: 'ಬಿಲ್ಡ್',
    malayalam: 'ബിൽഡ്',
  );

  String get whatIsTitle => strings.localized(
    telugu: 'ఈ యాప్ ఏమి చేస్తుంది',
    english: 'What this app does',
    hindi: 'यह ऐप क्या करता है',
    tamil: 'இந்த ஆப் என்ன செய்கிறது',
    kannada: 'ಈ ಆಪ್ ಏನು ಮಾಡುತ್ತದೆ',
    malayalam: 'ഈ ആപ്പ് എന്ത് ചെയ്യുന്നു',
  );

  String get whatIsBody => strings.localized(
    telugu:
        'ఇది రెడీమేడ్ పోస్టర్లను చూసి, మీ ఫోటో, బిజినెస్ పేరు, వాట్సాప్ వివరాలు లేదా అవసరమైన వ్యక్తిగత వివరాలు జోడించి, మీ అవసరానికి తగ్గట్టుగా మార్చుకునే పోస్టర్ క్రియేషన్ యాప్. టెంప్లేట్లు, ప్రొఫైల్ వివరాలు, సబ్‌స్క్రిప్షన్ సమాచారం, సహాయం మరియు లీగల్ సమాచారం ఒకే చోట అందుబాటులో ఉంటాయి.',
    english:
        'This is a poster creation app where users can choose ready-made designs and personalize them with their photo, business name, WhatsApp details, and other relevant information. Templates, profile details, subscription information, help, and legal access are available in one place.',
    hindi:
        'यह एक पोस्टर क्रिएशन ऐप है जिसमें उपयोगकर्ता तैयार डिज़ाइन चुनकर अपनी फोटो, बिज़नेस नाम, व्हाट्सऐप जानकारी और अन्य ज़रूरी विवरण जोड़ सकते हैं। टेम्पलेट्स, प्रोफ़ाइल जानकारी, सब्सक्रिप्शन विवरण, सहायता और कानूनी जानकारी एक ही जगह मिलती है।',
    tamil:
        'இது தயாராக உள்ள போஸ்டர் வடிவங்களைத் தேர்வு செய்து, உங்கள் புகைப்படம், வணிகப் பெயர், வாட்ஸ்அப் விவரங்கள் மற்றும் தேவையான பிற தகவல்களைச் சேர்த்து தனிப்பயனாக்க உதவும் போஸ்டர் உருவாக்கும் ஆப். டெம்ப்ளேட்கள், சுயவிவர விவரங்கள், சந்தா தகவல், உதவி மற்றும் சட்ட தகவல் அனைத்தும் ஒரே இடத்தில் கிடைக்கும்.',
    kannada:
        'ಇದು ಸಿದ್ಧ ಪೋಸ್ಟರ್ ವಿನ್ಯಾಸಗಳನ್ನು ಆಯ್ಕೆ ಮಾಡಿ, ನಿಮ್ಮ ಫೋಟೋ, ವ್ಯವಹಾರದ ಹೆಸರು, ವಾಟ್ಸ್ಆಪ್ ವಿವರಗಳು ಮತ್ತು ಅಗತ್ಯವಾದ ಇತರೆ ಮಾಹಿತಿಯನ್ನು ಸೇರಿಸಿ ವೈಯಕ್ತಿಕಗೊಳಿಸಲು ಸಹಾಯ ಮಾಡುವ ಪೋಸ್ಟರ್ ಸೃಷ್ಟಿ ಆಪ್. ಟೆಂಪ್ಲೇಟ್‌ಗಳು, ಪ್ರೊಫೈಲ್ ವಿವರಗಳು, ಚಂದಾದಾರಿಕೆ ಮಾಹಿತಿ, ಸಹಾಯ ಮತ್ತು ಕಾನೂನು ಮಾಹಿತಿ ಎಲ್ಲವೂ ಒಂದೇ ಸ್ಥಳದಲ್ಲಿ ಲಭ್ಯವಿರುತ್ತವೆ.',
    malayalam:
        'ഇത് തയ്യാറായ പോസ്റ്റർ രൂപങ്ങൾ തിരഞ്ഞെടുക്കി, നിങ്ങളുടെ ഫോട്ടോ, ബിസിനസ് പേര്, വാട്‌സ്ആപ്പ് വിവരങ്ങൾ, ആവശ്യമായ മറ്റ് വിശദാംശങ്ങൾ എന്നിവ ചേർത്ത് വ്യക്തിപരമാക്കാൻ സഹായിക്കുന്ന പോസ്റ്റർ സൃഷ്ടി ആപ്പാണ്. ടെംപ്ലേറ്റുകൾ, പ്രൊഫൈൽ വിവരങ്ങൾ, സബ്സ്ക്രിപ്ഷൻ വിവരം, സഹായം, നിയമ വിവരങ്ങൾ എന്നിവ ഒറ്റ സ്ഥലത്ത് ലഭ്യമാണ്.',
  );

  String get whoForTitle => strings.localized(
    telugu: 'ఎవరికి ఉపయోగపడుతుంది',
    english: 'Who it is for',
    hindi: 'किसके लिए उपयोगी है',
    tamil: 'யாருக்கு பயன்படும்',
    kannada: 'ಯಾರಿಗೆ ಉಪಯುಕ್ತ',
    malayalam: 'ആർക്കാണ് ഉപകാരപ്പെടുന്നത്',
  );

  String get whoForBody => strings.localized(
    telugu:
        'రోజువారీ శుభాకాంక్షలు పంపే వారు, చిన్న వ్యాపారాల కోసం ప్రమోషనల్ పోస్టర్లు అవసరమైన వారు, భక్తి లేదా ప్రత్యేక దినోత్సవ పోస్టర్లు షేర్ చేసే వారు, తమ పేరు లేదా వ్యాపార గుర్తింపుతో పోస్టర్ తయారు చేయాలనుకునే వారు ఈ యాప్‌ను ఉపయోగించుకోవచ్చు.',
    english:
        'This app is useful for people who share daily greetings, create posters for small businesses, publish devotional or occasion-based posts, or want personalized posters with their own name or business identity.',
    hindi:
        'यह ऐप उन लोगों के लिए उपयोगी है जो रोज़ शुभकामनाएँ साझा करते हैं, छोटे व्यवसायों के लिए प्रमोशनल पोस्टर बनाना चाहते हैं, भक्ति या विशेष अवसरों के पोस्ट साझा करते हैं, या अपने नाम और व्यवसाय पहचान के साथ निजी पोस्टर तैयार करना चाहते हैं।',
    tamil:
        'தினசரி வாழ்த்துகளை பகிர்பவர்கள், சிறு வணிகங்களுக்கான விளம்பர போஸ்டர்கள் தேவைப்படுபவர்கள், பக்தி அல்லது சிறப்பு நாள் பதிவுகளைப் பகிர்பவர்கள், தங்கள் பெயர் அல்லது வணிக அடையாளத்துடன் தனிப்பயன் போஸ்டர்கள் உருவாக்க விரும்புபவர்கள் இந்த ஆப்பைப் பயன்படுத்தலாம்.',
    kannada:
        'ದೈನಂದಿನ ಶುಭಾಶಯಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳುವವರು, ಸಣ್ಣ ವ್ಯವಹಾರಗಳಿಗಾಗಿ ಪ್ರಚಾರ ಪೋಸ್ಟರ್ ಬೇಕಿರುವವರು, ಭಕ್ತಿಪರ ಅಥವಾ ವಿಶೇಷ ಸಂದರ್ಭದ ಪೋಸ್ಟ್‌ಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳುವವರು, ತಮ್ಮ ಹೆಸರು ಅಥವಾ ವ್ಯವಹಾರದ ಗುರುತಿನೊಂದಿಗೆ ವೈಯಕ್ತಿಕ ಪೋಸ್ಟರ್ ರಚಿಸಲು ಬಯಸುವವರು ಈ ಆಪ್ ಬಳಸಬಹುದು.',
    malayalam:
        'ദൈനംദിന ആശംസകൾ പങ്കിടുന്നവർ, ചെറിയ ബിസിനസുകൾക്ക് പ്രമോഷൻ പോസ്റ്ററുകൾ വേണ്ടവർ, ഭക്തിപരമായോ പ്രത്യേക ദിവസങ്ങളിലേയോ പോസ്റ്റുകൾ പങ്കിടുന്നവർ, സ്വന്തം പേര് അല്ലെങ്കിൽ ബിസിനസ് തിരിച്ചറിയലോടെ വ്യക്തിഗത പോസ്റ്ററുകൾ തയ്യാറാക്കാൻ ആഗ്രഹിക്കുന്നവർക്ക് ഈ ആപ്പ് ഉപകാരപ്പെടും.',
  );

  String get featuresTitle => strings.localized(
    telugu: 'ప్రధాన సౌకర్యాలు',
    english: 'Main features',
    hindi: 'मुख्य सुविधाएँ',
    tamil: 'முக்கிய அம்சங்கள்',
    kannada: 'ಮುಖ್ಯ ಸೌಲಭ್ಯಗಳು',
    malayalam: 'പ്രധാന സൗകര്യങ്ങൾ',
  );

  List<String> get featureItems => <String>[
    strings.localized(
      telugu:
          'విభాగాలవారీగా పోస్టర్లు చూసి, మీకు నచ్చిన డిజైన్‌ను త్వరగా ఎంచుకోవచ్చు.',
      english:
          'Browse posters by category and quickly choose a suitable design.',
      hindi:
          'श्रेणी के अनुसार पोस्टर देखकर, उपयुक्त डिज़ाइन जल्दी चुना जा सकता है।',
      tamil:
          'பிரிவுகளின்படி போஸ்டர்களைப் பார்த்து, பொருத்தமான வடிவத்தை விரைவாக தேர்வு செய்யலாம்.',
      kannada:
          'ವಿಭಾಗಗಳ ಪ್ರಕಾರ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ನೋಡಿ, ಸೂಕ್ತ ವಿನ್ಯಾಸವನ್ನು ಬೇಗ ಆಯ್ಕೆ ಮಾಡಬಹುದು.',
      malayalam:
          'വിഭാഗങ്ങൾ അനുസരിച്ച് പോസ്റ്ററുകൾ കണ്ടു, അനുയോജ്യമായ ഡിസൈൻ വേഗത്തിൽ തിരഞ്ഞെടുക്കാം.',
    ),
    strings.localized(
      telugu:
          'పోస్టర్ ప్రొఫైల్, బిజినెస్ పేరు, ఫోటో, వాట్సాప్ వివరాలు సేవ్ చేసుకోవచ్చు.',
      english:
          'Save poster profile, business name, photo, and WhatsApp details.',
      hindi:
          'पोस्टर प्रोफ़ाइल, बिज़नेस नाम, फोटो और व्हाट्सऐप विवरण सुरक्षित रखे जा सकते हैं।',
      tamil:
          'போஸ்டர் சுயவிவரம், வணிகப் பெயர், புகைப்படம் மற்றும் வாட்ஸ்அப் விவரங்களைச் சேமிக்கலாம்.',
      kannada:
          'ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್, ವ್ಯವಹಾರದ ಹೆಸರು, ಫೋಟೋ ಮತ್ತು ವಾಟ್ಸ್ಆಪ್ ವಿವರಗಳನ್ನು ಉಳಿಸಬಹುದು.',
      malayalam:
          'പോസ്റ്റർ പ്രൊഫൈൽ, ബിസിനസ് പേര്, ഫോട്ടോ, വാട്‌സ്ആപ്പ് വിവരങ്ങൾ എന്നിവ സംരക്ഷിക്കാം.',
    ),
    strings.localized(
      telugu:
          'ఎంచుకున్న టెంప్లేట్‌ను ఎడిటర్‌లో మార్చుకుని తుది రూపంలో సేవ్ లేదా షేర్ చేయవచ్చు.',
      english:
          'Customize the selected template in the editor, then save or share it.',
      hindi:
          'चुने गए टेम्पलेट को एडिटर में बदलकर अंतिम रूप में सेव या शेयर किया जा सकता है।',
      tamil:
          'தேர்ந்தெடுத்த டெம்ப்ளேட்டை எடிட்டரில் மாற்றி, இறுதியாக சேமிக்க அல்லது பகிரலாம்.',
      kannada:
          'ಆಯ್ದ ಟೆಂಪ್ಲೇಟ್ ಅನ್ನು ಎಡಿಟರ್‌ನಲ್ಲಿ ತಿದ್ದುಪಡಿ ಮಾಡಿ, ನಂತರ ಉಳಿಸಬಹುದು ಅಥವಾ ಹಂಚಿಕೊಳ್ಳಬಹುದು.',
      malayalam:
          'തിരഞ്ഞെടുത്ത ടെംപ്ലേറ്റ് എഡിറ്ററിൽ മാറ്റി, അവസാനം സേവ് ചെയ്യുകയോ ഷെയർ ചെയ്യുകയോ ചെയ്യാം.',
    ),
    strings.localized(
      telugu:
          'నోటిఫికేషన్లు, అనుమతులు, సహాయం, ప్రైవసీ పాలసీ, నిబంధనలు యాప్‌లోనే ఉంటాయి.',
      english:
          'Notifications, permissions, help, privacy policy, and terms are available inside the app.',
      hindi:
          'नोटिफिकेशन, परमिशन, सहायता, प्राइवेसी पॉलिसी और नियम ऐप के अंदर ही उपलब्ध हैं।',
      tamil:
          'அறிவிப்புகள், அனுமதிகள், உதவி, தனியுரிமைக் கொள்கை மற்றும் விதிமுறைகள் ஆப்பிலேயே கிடைக்கும்.',
      kannada:
          'ಅಧಿಸೂಚನೆಗಳು, ಅನುಮತಿಗಳು, ಸಹಾಯ, ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ನಿಯಮಗಳು ಆಪ್‌ನಲ್ಲೇ ಲಭ್ಯವಿವೆ.',
      malayalam:
          'നോട്ടിഫിക്കേഷനുകൾ, അനുമതികൾ, സഹായം, സ്വകാര്യതാ നയം, നിബന്ധനകൾ എന്നിവ ആപ്പിനുള്ളിൽ തന്നെ ലഭ്യമാണ്.',
    ),
  ];

  String get flowTitle => strings.localized(
    telugu: 'యాప్ పని విధానం',
    english: 'How the app works',
    hindi: 'ऐप कैसे काम करता है',
    tamil: 'ஆப் எப்படி செயல்படுகிறது',
    kannada: 'ಆಪ್ ಹೇಗೆ ಕೆಲಸ ಮಾಡುತ್ತದೆ',
    malayalam: 'ആപ്പ് എങ്ങനെ പ്രവർത്തിക്കുന്നു',
  );

  List<String> get flowItems => <String>[
    strings.localized(
      telugu:
          'లాగిన్ అయిన తర్వాత హోమ్ స్క్రీన్‌లో పోస్టర్ విభాగాలు మరియు డిజైన్లు కనిపిస్తాయి.',
      english:
          'After login, the home screen shows poster categories and designs.',
      hindi:
          'लॉगिन के बाद होम स्क्रीन पर पोस्टर श्रेणियाँ और डिज़ाइन दिखाई देते हैं।',
      tamil:
          'உள்நுழைந்த பிறகு ஹோம் திரையில் போஸ்டர் பிரிவுகள் மற்றும் வடிவங்கள் காட்டப்படும்.',
      kannada:
          'ಲಾಗಿನ್ ಆದ ನಂತರ ಹೋಮ್ ಪರದೆಯಲ್ಲಿ ಪೋಸ್ಟರ್ ವಿಭಾಗಗಳು ಮತ್ತು ವಿನ್ಯಾಸಗಳು ಕಾಣಿಸುತ್ತವೆ.',
      malayalam:
          'ലോഗിൻ ചെയ്ത ശേഷം ഹോം സ്ക്രീനിൽ പോസ്റ്റർ വിഭാഗങ്ങളും ഡിസൈനുകളും കാണാം.',
    ),
    strings.localized(
      telugu:
          'ప్రొఫైల్‌లో మీ పేరు, ఫోటో, బిజినెస్ వివరాలు వంటి సమాచారాన్ని ముందుగా సేవ్ చేసుకోవచ్చు.',
      english:
          'You can first save your name, photo, and business details in the profile section.',
      hindi:
          'प्रोफ़ाइल में पहले से अपना नाम, फोटो और बिज़नेस जानकारी सेव की जा सकती है।',
      tamil:
          'சுயவிவர பகுதியில் உங்கள் பெயர், புகைப்படம் மற்றும் வணிக விவரங்களை முன்பே சேமிக்கலாம்.',
      kannada:
          'ಪ್ರೊಫೈಲ್ ವಿಭಾಗದಲ್ಲಿ ನಿಮ್ಮ ಹೆಸರು, ಫೋಟೋ ಮತ್ತು ವ್ಯವಹಾರದ ವಿವರಗಳನ್ನು ಮೊದಲು ಉಳಿಸಬಹುದು.',
      malayalam:
          'പ്രൊഫൈൽ വിഭാഗത്തിൽ നിങ്ങളുടെ പേര്, ഫോട്ടോ, ബിസിനസ് വിവരങ്ങൾ എന്നിവ ആദ്യം സംരക്ഷിക്കാം.',
    ),
    strings.localized(
      telugu:
          'డిజైన్‌ను ఎంచుకున్న తర్వాత ఎడిటర్‌లో అవసరమైన మార్పులు చేసి వ్యక్తిగత రూపంలో మార్చుకోవచ్చు.',
      english:
          'Once a design is selected, it can be edited and personalized in the editor.',
      hindi:
          'डिज़ाइन चुनने के बाद उसे एडिटर में बदलकर व्यक्तिगत रूप दिया जा सकता है।',
      tamil:
          'ஒரு வடிவம் தேர்ந்தெடுக்கப்பட்டதும், எடிட்டரில் அதை மாற்றி தனிப்பயனாக்கலாம்.',
      kannada:
          'ವಿನ್ಯಾಸವನ್ನು ಆಯ್ಕೆ ಮಾಡಿದ ನಂತರ, ಅದನ್ನು ಎಡಿಟರ್‌ನಲ್ಲಿ ತಿದ್ದುಪಡಿ ಮಾಡಿ ವೈಯಕ್ತಿಕಗೊಳಿಸಬಹುದು.',
      malayalam:
          'ഒരു ഡിസൈൻ തിരഞ്ഞെടുക്കപ്പെട്ടാൽ, അത് എഡിറ്ററിൽ തിരുത്തി വ്യക്തിപരമാക്കാം.',
    ),
    strings.localized(
      telugu:
          'చివరగా తయారైన పోస్టర్‌ను సేవ్ చేయవచ్చు లేదా ఇతరులతో పంచుకోవచ్చు.',
      english: 'Finally, the completed poster can be saved or shared.',
      hindi: 'अंत में तैयार पोस्टर को सेव या शेयर किया जा सकता है।',
      tamil: 'இறுதியாக தயார் செய்யப்பட்ட போஸ்டரை சேமிக்க அல்லது பகிரலாம்.',
      kannada:
          'ಕೊನೆಯಲ್ಲಿ ಸಿದ್ಧವಾದ ಪೋಸ್ಟರ್ ಅನ್ನು ಉಳಿಸಬಹುದು ಅಥವಾ ಹಂಚಿಕೊಳ್ಳಬಹುದು.',
      malayalam:
          'അവസാനമായി തയ്യാറായ പോസ്റ്റർ സേവ് ചെയ്യുകയോ പങ്കിടുകയോ ചെയ്യാം.',
    ),
  ];

  String get subscriptionTitle => strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ మరియు ప్రీమియం వివరాలు',
    english: 'Subscription and premium details',
    hindi: 'सब्सक्रिप्शन और प्रीमियम विवरण',
    tamil: 'சந்தா மற்றும் பிரீமியம் விவரங்கள்',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಮತ್ತು ಪ್ರೀಮಿಯಂ ವಿವರಗಳು',
    malayalam: 'സബ്സ്ക്രിപ്ഷൻയും പ്രീമിയം വിവരങ്ങളും',
  );

  List<String> get subscriptionItems => <String>[
    strings.localized(
      telugu:
          'సబ్‌స్క్రిప్షన్ ప్లాన్ Free ట్యాబ్ పోస్టర్లకు మాత్రమే వర్తిస్తుంది.',
      english: 'The subscription plan applies only to Free-tab posters.',
      hindi: 'सब्सक्रिप्शन प्लान केवल Free टैब पोस्टरों पर लागू होता है।',
      tamil: 'சந்தா திட்டம் Free டாப் போஸ்டர்களுக்கு மட்டும் பொருந்தும்.',
      kannada:
          'ಚಂದಾದಾರಿಕೆ ಯೋಜನೆ Free ಟ್ಯಾಬ್ ಪೋಸ್ಟರ್‌ಗಳಿಗೆ ಮಾತ್ರ ಅನ್ವಯಿಸುತ್ತದೆ.',
      malayalam:
          'സബ്സ്ക്രിപ്ഷൻ പദ്ധതി Free ടാബിലെ പോസ്റ്ററുകൾക്ക് മാത്രമാണ് ബാധകമാകുന്നത്.',
    ),
    strings.localized(
      telugu: 'ట్రయల్ ప్లాన్: 3 రోజుల పాటు రూ.1.',
      english: 'Trial plan: Rs.1 for 3 days.',
      hindi: 'ट्रायल प्लान: 3 दिनों के लिए ₹1।',
      tamil: 'ட்ரயல் திட்டம்: 3 நாட்களுக்கு ₹1.',
      kannada: 'ಟ್ರಯಲ್ ಯೋಜನೆ: 3 ದಿನಗಳಿಗೆ ₹1.',
      malayalam: 'ട്രയൽ പദ്ധതി: 3 ദിവസത്തിന് ₹1.',
    ),
    strings.localized(
      telugu: 'ట్రయల్ తర్వాత నెలకు రూ.149 ఆటో రీన్యువల్‌గా కొనసాగుతుంది.',
      english:
          'After the trial, it continues at Rs.149 per month with auto-renewal.',
      hindi:
          'ट्रायल के बाद यह ₹149 प्रति माह ऑटो-रिन्यूअल के साथ जारी रहता है।',
      tamil: 'ட்ரயலுக்குப் பிறகு மாதத்திற்கு ₹149 ஆட்டோ ரினியூவலாக தொடரும்.',
      kannada: 'ಟ್ರಯಲ್ ನಂತರ ತಿಂಗಳಿಗೆ ₹149 ಆಟೋ-ರಿನ್ಯೂವಲ್ ಮೂಲಕ ಮುಂದುವರೆಯುತ್ತದೆ.',
      malayalam:
          'ട്രയലിന് ശേഷം മാസം ₹149 എന്ന നിരക്കിൽ ഓട്ടോ റിന്യൂവലോടെ തുടരും.',
    ),
    strings.localized(
      telugu: 'Premium పోస్టర్లు ఈ ప్లాన్‌లో రావు. అవి వేరుగా కొనాలి.',
      english:
          'Premium posters are not included in this plan. They must be purchased separately.',
      hindi:
          'Premium पोस्टर इस प्लान में शामिल नहीं हैं। उन्हें अलग से खरीदना होगा।',
      tamil:
          'Premium போஸ்டர்கள் இந்த திட்டத்தில் சேராது. அவை தனியாக வாங்கப்பட வேண்டும்.',
      kannada:
          'Premium ಪೋಸ್ಟರ್‌ಗಳು ಈ ಯೋಜನೆಯಲ್ಲಿ ಸೇರಿರುವುದಿಲ್ಲ. ಅವನ್ನು ಪ್ರತ್ಯೇಕವಾಗಿ ಖರೀದಿಸಬೇಕು.',
      malayalam:
          'Premium പോസ്റ്ററുകൾ ഈ പദ്ധതിയിൽ ഉൾപ്പെടുന്നില്ല. അവ വേർതിരിച്ച് വാങ്ങണം.',
    ),
    strings.localized(
      telugu:
          'ప్రీమియం పోస్టర్ కొనుగోలు చేసిన తర్వాత దాన్ని పూర్తిగా అనుకూలంగా మార్చుకోవచ్చు.',
      english: 'After purchasing a premium poster, it can be fully customized.',
      hindi:
          'Premium पोस्टर खरीदने के बाद उसे पूरी तरह से कस्टमाइज़ किया जा सकता है।',
      tamil: 'Premium போஸ்டரை வாங்கிய பிறகு அதை முழுமையாக தனிப்பயனாக்கலாம்.',
      kannada:
          'Premium ಪೋಸ್ಟರ್ ಖರೀದಿಸಿದ ನಂತರ ಅದನ್ನು ಪೂರ್ಣವಾಗಿ ವೈಯಕ್ತಿಕಗೊಳಿಸಬಹುದು.',
      malayalam:
          'Premium പോസ്റ്റർ വാങ്ങിയ ശേഷം അത് പൂർണ്ണമായി വ്യക്തിപരമാക്കാം.',
    ),
  ];

  String get languagesTitle => strings.localized(
    telugu: 'అందుబాటులో ఉన్న భాషలు',
    english: 'Available languages',
    hindi: 'उपलब्ध भाषाएँ',
    tamil: 'கிடைக்கும் மொழிகள்',
    kannada: 'ಲಭ್ಯವಿರುವ ಭಾಷೆಗಳು',
    malayalam: 'ലഭ്യമായ ഭാഷകൾ',
  );

  List<String> get languageItems => <String>[
    strings.localized(
      telugu: 'తెలుగు ప్రధాన అనుభవంగా ఈ యాప్ రూపుదిద్దుకుంది.',
      english: 'This app is designed with Telugu as the primary experience.',
      hindi: 'यह ऐप तेलुगु को प्राथमिक अनुभव मानकर तैयार किया गया है।',
      tamil:
          'இந்த ஆப் தெலுங்கை முதன்மை அனுபவமாகக் கொண்டு வடிவமைக்கப்பட்டுள்ளது.',
      kannada: 'ಈ ಆಪ್ ತೆಲುಗುವನ್ನು ಪ್ರಮುಖ ಅನುಭವವಾಗಿ ಇಟ್ಟು ರೂಪುಗೊಂಡಿದೆ.',
      malayalam:
          'ഈ ആപ്പ് തെലുങ്കിനെ പ്രധാന അനുഭവമായി കരുതി രൂപകൽപ്പന ചെയ്തതാണ്.',
    ),
    strings.localized(
      telugu:
          'ఇంగ్లీష్, హిందీ, తమిళం, కన్నడ, మలయాళం భాషల్లో కూడా ఉపయోగించవచ్చు.',
      english:
          'It can also be used in English, Hindi, Tamil, Kannada, and Malayalam.',
      hindi:
          'इसे अंग्रेज़ी, हिंदी, तमिल, कन्नड़ और मलयालम में भी उपयोग किया जा सकता है।',
      tamil:
          'இதை ஆங்கிலம், இந்தி, தமிழ், கன்னடம் மற்றும் மலையாளம் மொழிகளிலும் பயன்படுத்தலாம்.',
      kannada:
          'ಇದನ್ನು ಇಂಗ್ಲಿಷ್, ಹಿಂದಿ, ತಮಿಳು, ಕನ್ನಡ ಮತ್ತು ಮಲಯಾಳಂ ಭಾಷೆಗಳಲ್ಲಿಯೂ ಬಳಸಬಹುದು.',
      malayalam:
          'ഇത് ഇംഗ്ലീഷ്, ഹിന്ദി, തമിഴ്, ಕನ್ನಡ, മലയാളം ഭാഷകളിലും ഉപയോഗിക്കാം.',
    ),
  ];

  String get supportTitle => strings.localized(
    telugu: 'సహాయం మరియు సంప్రదింపు',
    english: 'Support and contact',
    hindi: 'सहायता और संपर्क',
    tamil: 'உதவி மற்றும் தொடர்பு',
    kannada: 'ಸಹಾಯ ಮತ್ತು ಸಂಪರ್ಕ',
    malayalam: 'സഹായവും ബന്ധപ്പെടൽ',
  );

  String get supportBody => strings.localized(
    telugu:
        'లాగిన్ సమస్యలు, ఫోటో ఎంపిక లేదా అప్‌లోడ్ ఇబ్బందులు, సేవ్ లేదా ఎగుమతి సమస్యలు, సబ్‌స్క్రిప్షన్ సందేహాలు లేదా యాప్ వినియోగానికి సంబంధించిన సహాయం కోసం ఈ మెయిల్‌ను ఉపయోగించవచ్చు. ప్రైవసీ పాలసీ మరియు నిబంధనలు కూడా యాప్‌లోనే చూడవచ్చు.',
    english:
        'Use this email for login problems, photo selection or upload issues, save or export problems, subscription questions, or general app support. Privacy Policy and Terms & Conditions are also available inside the app.',
    hindi:
        'लॉगिन समस्या, फोटो चुनने या अपलोड करने में दिक्कत, सेव या एक्सपोर्ट समस्या, सब्सक्रिप्शन से जुड़े प्रश्न, या सामान्य ऐप सहायता के लिए इस ईमेल का उपयोग किया जा सकता है। प्राइवेसी पॉलिसी और नियम भी ऐप में उपलब्ध हैं।',
    tamil:
        'உள்நுழைவு சிக்கல்கள், புகைப்படம் தேர்வு அல்லது பதிவேற்ற சிரமம், சேமிப்பு அல்லது ஏற்றுமதி பிரச்சினைகள், சந்தா தொடர்பான சந்தேகங்கள் அல்லது பொதுவான ஆப் உதவிக்காக இந்த மின்னஞ்சலை பயன்படுத்தலாம். தனியுரிமைக் கொள்கை மற்றும் விதிமுறைகளும் ஆப்பிலேயே கிடைக்கும்.',
    kannada:
        'ಲಾಗಿನ್ ಸಮಸ್ಯೆಗಳು, ಫೋಟೋ ಆಯ್ಕೆ ಅಥವಾ ಅಪ್‌ಲೋಡ್ ತೊಂದರೆಗಳು, ಉಳಿಸುವಿಕೆ ಅಥವಾ ಎಕ್ಸ್‌ಪೋರ್ಟ್ ಸಮಸ್ಯೆಗಳು, ಚಂದಾದಾರಿಕೆ ಪ್ರಶ್ನೆಗಳು ಅಥವಾ ಸಾಮಾನ್ಯ ಆಪ್ ಸಹಾಯಕ್ಕಾಗಿ ಈ ಇಮೇಲ್ ಬಳಸಬಹುದು. ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ನಿಯಮಗಳು ಕೂಡ ಆಪ್‌ನಲ್ಲೇ ಲಭ್ಯವಿವೆ.',
    malayalam:
        'ലോഗിൻ പ്രശ്നങ്ങൾ, ഫോട്ടോ തിരഞ്ഞെടുക്കൽ അല്ലെങ്കിൽ അപ്‌ലോഡ് ബുദ്ധിമുട്ടുകൾ, സേവ് ചെയ്യൽ അല്ലെങ്കിൽ എക്സ്പോർട്ട് പ്രശ്നങ്ങൾ, സബ്സ്ക്രിപ്ഷൻ സംബന്ധമായ സംശയങ്ങൾ, അല്ലെങ്കിൽ പൊതുവായ ആപ്പ് സഹായത്തിനായി ഈ ഇമെയിൽ ഉപയോഗിക്കാം. പ്രൈവസി പോളിസിയും നിബന്ധനകളും ആപ്പിനുള്ളിൽ ലഭ്യമാണ്.',
  );

  String get privacyButton => strings.localized(
    telugu: 'ప్రైవసీ పాలసీ చూడండి',
    english: 'View Privacy Policy',
    hindi: 'प्राइवेसी पॉलिसी देखें',
    tamil: 'தனியுரிமைக் கொள்கையை பார்க்கவும்',
    kannada: 'ಗೌಪ್ಯತಾ ನೀತಿಯನ್ನು ನೋಡಿ',
    malayalam: 'സ്വകാര്യതാ നയം കാണുക',
  );

  String get termsButton => strings.localized(
    telugu: 'నిబంధనలు చూడండి',
    english: 'View Terms & Conditions',
    hindi: 'नियम और शर्तें देखें',
    tamil: 'விதிமுறைகளை பார்க்கவும்',
    kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳನ್ನು ನೋಡಿ',
    malayalam: 'നിബന്ധനകൾ കാണുക',
  );
}
