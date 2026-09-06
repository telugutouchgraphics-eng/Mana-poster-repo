import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, this.initialSubject, this.initialBody});

  final String? initialSubject;
  final String? initialBody;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with AppLanguageStateMixin {
  static const String _supportEmail = AppPublicInfo.supportEmail;
  int? _expandedIndex;

  Future<void> _contactSupport(_HelpSupportCopy copy) async {
    final selected = _expandedIndex != null ? copy.faqs[_expandedIndex!] : null;
    final defaultSubject = selected == null
        ? copy.defaultSubject
        : '${copy.defaultSubject} - ${selected.question}';
    final defaultBody = selected == null
        ? copy.defaultBody
        : '${copy.defaultBody}\n\n${copy.contextLabel}: ${selected.question}\n';
    final subject = widget.initialSubject?.trim().isNotEmpty == true
        ? widget.initialSubject!.trim()
        : defaultSubject;
    final body = widget.initialBody?.trim().isNotEmpty == true
        ? widget.initialBody!.trim()
        : defaultBody;

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: <String, String>{'subject': subject, 'body': body},
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) {
      return;
    }
    if (!launched) {
      ScaffoldMessenger.of(
        context,
      ).showTopSnackBar(AppSnackBar.build(content: Text(copy.emailOpenFailed)));
    }
  }

  Future<void> _openLegalDocument(LegalDocumentType type) async {
    final url = type == LegalDocumentType.privacyPolicy
        ? AppPublicInfo.privacyPolicyUrl
        : AppPublicInfo.termsUrl;
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
        ),
      ),
    );
  }

  Future<void> _copySupportEmail(_HelpSupportCopy copy) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showTopSnackBar(AppSnackBar.build(content: Text(copy.emailCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final copy = _HelpSupportCopy(context.currentLanguage);
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
            top: -72,
            right: -28,
            child: _SupportOrb(size: 160, color: Color(0x1822C55E)),
          ),
          const Positioned(
            top: 140,
            left: -52,
            child: _SupportOrb(size: 130, color: Color(0x182563EB)),
          ),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFEAF2FF), Color(0xFFFFFFFF)],
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
                          Icons.support_agent_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        copy.headerTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.headerSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475569),
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SupportSectionLabel(title: copy.faqLabel),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionPanelList.radio(
                        elevation: 0,
                        expandedHeaderPadding: EdgeInsets.zero,
                        initialOpenPanelValue: _expandedIndex == null
                            ? null
                            : 'faq_${_expandedIndex!}',
                        expansionCallback: (panelIndex, isExpanded) {
                          setState(
                            () =>
                                _expandedIndex = isExpanded ? null : panelIndex,
                          );
                        },
                        children: <ExpansionPanelRadio>[
                          for (int i = 0; i < copy.faqs.length; i++)
                            ExpansionPanelRadio(
                              value: 'faq_$i',
                              canTapOnHeader: true,
                              backgroundColor: Colors.transparent,
                              headerBuilder: (context, isExpanded) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  title: Text(
                                    copy.faqs[i].question,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                );
                              },
                              body: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Text(
                                  copy.faqs[i].answer,
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SupportSectionLabel(title: copy.legalTitle),
                const SizedBox(height: 8),
                _InfoCard(
                  title: copy.legalTitle,
                  subtitle: copy.legalSubtitle,
                  child: LayoutBuilder(
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
                            child: _ActionTileButton(
                              icon: Icons.privacy_tip_outlined,
                              label: copy.privacyLabel,
                              onTap: () => _openLegalDocument(
                                LegalDocumentType.privacyPolicy,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            child: _ActionTileButton(
                              icon: Icons.gavel_rounded,
                              label: copy.termsLabel,
                              onTap: () => _openLegalDocument(
                                LegalDocumentType.termsAndConditions,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SupportSectionLabel(title: copy.stillNeedHelpTitle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFEEF4FB), Color(0xFFFFFFFF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFDDE6F2)),
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
                        copy.stillNeedHelpTitle,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.stillNeedHelpSubtitle,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const SelectableText(
                          _supportEmail,
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _contactSupport(copy),
                          icon: const Icon(Icons.email_outlined),
                          label: Text(copy.contactButton),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _copySupportEmail(copy),
                          icon: const Icon(Icons.copy_rounded),
                          label: Text(copy.copyEmailButton),
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

class _SupportOrb extends StatelessWidget {
  const _SupportOrb({required this.size, required this.color});

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

class _SupportSectionLabel extends StatelessWidget {
  const _SupportSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle, this.child});

  final String title;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.8,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          if (child != null) ...<Widget>[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

class _ActionTileButton extends StatelessWidget {
  const _ActionTileButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpFaqItem {
  const _HelpFaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _HelpSupportCopy {
  const _HelpSupportCopy(this.language);

  final AppLanguage language;

  bool get _isTelugu => language == AppLanguage.telugu;

  static const Map<String, Map<AppLanguage, String>> _helpDictionary = {
    'Help & Support': {
      AppLanguage.hindi: 'सहायता और समर्थन',
      AppLanguage.tamil: 'உதவி & ஆதரவு',
      AppLanguage.kannada: 'ಸಹಾಯ & ಬೆಂಬಲ',
      AppLanguage.malayalam: 'സഹായവും പിന്തുണയും',
      AppLanguage.marathi: 'मदत आणि समर्थन',
      AppLanguage.gujarati: 'મદદ અને સપોર્ટ',
      AppLanguage.bengali: 'সাহায্য ও সমর্থন',
      AppLanguage.punjabi: 'ਮਦਦ ਅਤੇ ਸਹਾਇਤਾ',
      AppLanguage.odia: 'ସହାୟତା ଏବଂ ସମର୍ଥନ',
      AppLanguage.assamese: 'সহায় আৰু সমৰ্থন',
      AppLanguage.konkani: 'मदत आनी तेंको',
      AppLanguage.nepali: 'मद्दत र समर्थन',
      AppLanguage.meitei: 'Help & Support',
      AppLanguage.mizo: 'Taimakna leh ṭanpuina',
      AppLanguage.kashmiri: 'مدد تہٕ حِمایت',
      AppLanguage.ladakhi: 'རོགས་རམ་དང་རྒྱབ་སྐྱོར།',
    },
    'Frequently asked questions': {
      AppLanguage.hindi: 'अक्सर पूछे जाने वाले प्रश्न',
      AppLanguage.tamil: 'அடிக்கடி கேட்கப்படும் கேள்விகள்',
      AppLanguage.kannada: 'ಪದೇ ಪದೇ ಕೇಳಲಾಗುವ ಪ್ರಶ್ನೆಗಳು',
      AppLanguage.malayalam: 'പതിവായി ചോദിക്കുന്ന ചോദ്യങ്ങൾ',
      AppLanguage.marathi: 'सतत विचारले जाणारे प्रश्न',
      AppLanguage.gujarati: 'વારંવાર પૂછાતા પ્રશ્નો',
      AppLanguage.bengali: 'প্রায়শই জিজ্ঞাসিত প্রশ্নাবলী',
      AppLanguage.punjabi: 'ਅਕਸਰ ਪੁੱਛੇ ਜਾਂਦੇ ਸਵਾਲ',
      AppLanguage.odia: 'ବାରମ୍ବାର ପଚରାଯାଉଥିବା ପ୍ରଶ୍ନ',
      AppLanguage.assamese: 'সঘনাই সোধা প্ৰশ্নসমূহ',
      AppLanguage.konkani: 'परत परत विचारिल्ले प्रस्न',
      AppLanguage.nepali: 'प्रायः सोधिने प्रश्नहरू',
      AppLanguage.meitei: 'Frequently asked questions',
      AppLanguage.mizo: 'Zawhna zawh fo thinte',
      AppLanguage.kashmiri: 'اکثر پرژھنہٕ ینہٕ والیٚن سوالن',
      AppLanguage.ladakhi: 'རྒྱུན་དྲིས་དྲི་བ།',
    },
    'Quick guidance for common issues': {
      AppLanguage.hindi: 'सामान्य समस्याओं के लिए त्वरित मार्गदर्शन',
      AppLanguage.tamil: 'பொதுவான சிக்கல்களுக்கான விரைவான வழிகாட்டுதல்',
      AppLanguage.kannada: 'ಸಾಮಾನ್ಯ ಸಮಸ್ಯೆಗಳಿಗೆ ತ್ವರಿತ ಮಾರ್ಗದರ್ಶನ',
      AppLanguage.malayalam: 'സാധാരണ പ്രശ്നങ്ങൾക്കുള്ള ദ്രുത മാർഗ്ഗനിർദ്ദേശം',
      AppLanguage.marathi: 'सामान्य समस्यांसाठी जलद मार्गदर्शन',
      AppLanguage.gujarati: 'સામાન્ય સમસ્યાઓ માટે ઝડપી માર્ગદર્શન',
      AppLanguage.bengali: 'সাধারণ সমস্যার দ্রুত সমাধান নির্দেশিকা',
      AppLanguage.punjabi: 'ਆਮ ਸਮੱਸਿਆਵਾਂ ਲਈ ਤੁਰੰਤ ਮਾਰਗਦਰਸ਼ਨ',
      AppLanguage.odia: 'ସାଧାରଣ ସମସ୍ୟା ପାଇଁ ଶୀଘ୍ର ମାର୍ଗଦର୍ଶନ',
      AppLanguage.assamese: 'সাধাৰণ সমস্যাৰ তাৎক্ষণিক নিৰ্দেশনা',
      AppLanguage.konkani: 'ಸಾಮಾನ್ ಪ್ರೊಬ್ಲೆಮಾಂಕ್ ಬೇಗ್ ಮಾರ್ಗದರ್ಶನ್',
      AppLanguage.nepali: 'सामान्य समस्याहरूको द्रुत मार्गदर्शन',
      AppLanguage.meitei: 'Chongkhatlakpa awabasinggi thuna upai',
      AppLanguage.mizo: 'Harsatna tlangpui chinfel dan awlsam',
      AppLanguage.kashmiri: 'عام مسلن خٲطرٕ فوری رَہنمٲیی',
      AppLanguage.ladakhi: 'དཀའ་ངལ་རྣམས་ཀྱི་མྱུར་ལམ།',
    },
    'Find quick answers for login, photo import, save/export, subscription, and other common app issues. Posters shown in the app are reviewed before publishing.': {
      AppLanguage.hindi: 'लॉगिन, फ़ोटो चयन, सहेजें/निर्यात, सदस्यता और अन्य ऐप समस्याओं के त्वरित उत्तर यहाँ पाएँ। ऐप में दिखाए गए पोस्टर प्रकाशन से पहले समीक्षित होते हैं।',
      AppLanguage.tamil: 'உள்நுழைவு, புகைப்படத் தேர்வு, சேமி/ஏற்றுமதி, சந்தா மற்றும் பிற சிக்கல்களுக்கு விரைவான பதில்கள். பயன்பாட்டில் காட்டப்படும் போஸ்டர்கள் வெளியீட்டிற்கு முன் மதிப்பாய்வு செய்யப்படுகின்றன.',
      AppLanguage.kannada: 'ಲಾಗಿನ್, ಫೋಟೋ ಆಯ್ಕೆ, ಸೇವ್/ರಫ್ತು, ಚಂದಾದಾರಿಕೆ ಮತ್ತು ಇತರ ಸಾಮಾನ್ಯ ಸಮಸ್ಯೆಗಳಿಗೆ ತ್ವರಿತ ಉತ್ತರಗಳನ್ನು ಇಲ್ಲಿ ಹುಡುಕಿ. ಆಪ್‌ನಲ್ಲಿ ತೋರಿಸುವ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಪ್ರಕಟಣೆಗೆ ಮೊದಲು ಪರಿಶೀಲಿಸಲಾಗುತ್ತದೆ.',
      AppLanguage.malayalam: 'ലോഗിൻ, ഫോട്ടോ ഇറക്കുമതി, സേവ്/എക്‌സ്‌പോർട്ട്, സബ്‌സ്‌ക്രിപ്ഷൻ, മറ്റ് ആപ്പ് പ്രശ്നങ്ങൾ എന്നിവയ്ക്കുള്ള ദ്രുത ഉത്തരങ്ങൾ കണ്ടെത്തുക. ആപ്പിലെ പോസ്റ്ററുകൾ പ്രസിദ്ധീകരിക്കുന്നതിന് മുമ്പ് അവലോകനം ചെയ്യപ്പെടുന്നു.',
      AppLanguage.marathi: 'लॉगिन, फोटो आयात, जतन/निर्यात, सदस्यता आणि इतर अ‍ॅप समस्यांसाठी जलद उत्तरे मिळवा. अ‍ॅपमधील पोस्टर्स प्रकाशनापूर्वी तपासले जातात.',
      AppLanguage.gujarati: 'લૉગિન, ફોટો આયાત, સાચવો/નિકાસ, સબ્સ્ક્રિપ્શન અને અન્ય એપ્લિકેશન સમસ્યાઓ માટે ઝડપી જવાબો શોધો. એપ્લિકેશનમાં દર્શાવેલ પોસ્ટર્સ પ્રકાશન પહેલાં સમીક્ષા કરવામાં આવે છે.',
      AppLanguage.bengali: 'লগইন, ফটো আমদানি, সেভ/এক্সপোর্ট, সাবস্ক্রিপশন এবং অন্যান্য সাধারণ সমস্যার দ্রুত উত্তর খুঁজুন। অ্যাপে প্রদর্শিত পোস্টার প্রকাশের আগে পর্যালোচনা করা হয়।',
      AppLanguage.punjabi: 'ਲੌਗਇਨ, ਫੋਟੋ ਆਯਾਤ, ਸੇਵ/ਨਿਰਯਾਤ, ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਅਤੇ ਹੋਰ ਐਪ ਮੁੱਦਿਆਂ ਲਈ ਤੁਰੰਤ ਜਵਾਬ ਲੱਭੋ। ਐਪ ਵਿੱਚ ਦਿਖਾਏ ਗਏ ਪੋਸਟਰ ਪ੍ਰਕਾਸ਼ਨ ਤੋਂ ਪਹਿਲਾਂ ਸਮੀਖਿਆ ਕੀਤੇ ਜਾਂਦੇ ਹਨ।',
      AppLanguage.odia: 'ଲଗଇନ୍, ଫଟୋ ଚୟନ, ସେଭ୍/ରପ୍ତାନି, ସବସ୍କ୍ରିପସନ୍ ଏବଂ ଅନ୍ୟାନ୍ୟ ସମସ୍ୟା ପାଇଁ ଶୀଘ୍ର ଉତ୍ତର ଖୋଜନ୍ତୁ। ପ୍ରକାଶନ ପୂର୍ବରୁ ପୋଷ୍ଟରଗୁଡ଼ିକ ସମୀକ୍ଷା କରାଯାଏ।',
      AppLanguage.assamese: 'লগইন, ফটো আমদানি, সংৰক্ষণ/ৰপ্তানি, গ্ৰাহকভুক্তি আৰু অন্যান্য সমস্যাৰ তাৎক্ষণিক উত্তৰ লাভ কৰক। প্ৰকাশৰ পূৰ্বে পোষ্টাৰসমূহ পৰ্যালোচনা কৰা হয়।',
      AppLanguage.konkani: 'लॉगिन, फोटो आयात, सांबाळप/निर्यात, वर्गणी आनी हेर अडचणींक बेगीन जाप मेळोवच्यो. अ‍ॅपांत दाखयिल्लीं पोस्टरां छापने पयलीं तपासतात.',
      AppLanguage.nepali: 'लगइन, फोटो आयात, सुरक्षित/निर्यात, सदस्यता र अन्य एप समस्याहरूको द्रुत जवाफ खोज्नुहोस्। एपमा देखाइएका पोस्टरहरू प्रकाशन अघि समीक्षा गरिन्छ।',
      AppLanguage.meitei: 'Login, photo import, save/export, subscription amasung atei awabasinggi thuna paokhum thengnasi. App da phongba postering publish toudringeida review tou-i.',
      AppLanguage.mizo: 'Login, thlalak lakluh, save/export, subscription leh harsatna dang chhanna heta tang hian hmu rawh. Poster zawng zawng chhuah hma in endik vek a ni.',
      AppLanguage.kashmiri: 'لاگ اِن، فوٹو اِمپورٹ، سیو/ایکسپورٹ، سبسکرپشن تہٕ باقٕے عام مسلن ہٕندِ فوری جواب لبِو ییٚتھ۔ شایع گژھنہٕ برونٛٹھ گژھن پوسٹر چیک۔',
      AppLanguage.ladakhi: 'Login དང་ པར་ལེན་པ། ཉར་ཚགས། ཕྱིར་འདྲེན། མཁོ་སྤྲོད་སོགས་ཀྱི་དཀའ་ངལ་གྱི་ལན་མགྱོགས་མྱུར་དུ་འཚོལ།',
    },
    'Privacy and terms': {
      AppLanguage.hindi: 'गोपनीयता और शर्तें',
      AppLanguage.tamil: 'தனியுரிமை மற்றும் விதிமுறைகள்',
      AppLanguage.kannada: 'ಗೌಪ್ಯತೆ ಮತ್ತು ನಿಯಮಗಳು',
      AppLanguage.malayalam: 'സ്വകാര്യതയും നിబంధനകളും',
      AppLanguage.marathi: 'गोपनीयता आणि अटी',
      AppLanguage.gujarati: 'ગોપનીયતા અને શરતો',
      AppLanguage.bengali: 'গোপনীয়তা এবং শর্তাবলী',
      AppLanguage.punjabi: 'ਗੋਪਨੀਯਤਾ ਅਤੇ ਸ਼ਰਤਾਂ',
      AppLanguage.odia: 'ଗୋପନୀୟତା ଏବଂ ସର୍ତ୍ତାବଳୀ',
      AppLanguage.assamese: 'গোপনীয়তা আৰু চৰ্তাৱলী',
      AppLanguage.konkani: 'गोपनीयता आनी अटी',
      AppLanguage.nepali: 'गोपनीयता र सर्तहरू',
      AppLanguage.meitei: 'Privacy & Terms',
      AppLanguage.mizo: 'Privacy leh dan zawng zawng',
      AppLanguage.kashmiri: 'پرائیویسی تہٕ شرائط',
      AppLanguage.ladakhi: 'གསང་རྒྱ་དང་ཆ་རྐྱེན།',
    },
    'Read the app privacy policy and terms of use here.': {
      AppLanguage.hindi: 'ऐप गोपनीयता नीति और उपयोग की शर्तें यहाँ पढ़ें।',
      AppLanguage.tamil: 'செயலி தனியுரிமைக் கொள்கை மற்றும் பயன்பாட்டு விதிமுறைகளை இங்கே படிக்கவும்.',
      AppLanguage.kannada: 'ಆಪ್ ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ಬಳಕೆಯ ನಿಯಮಗಳನ್ನು ಇಲ್ಲಿ ಓದಿ.',
      AppLanguage.malayalam: 'ആപ്പ് സ്വകാര്യതാ നയവും ഉപയോഗ നിబంధനകളും ഇവിടെ വായിക്കുക.',
      AppLanguage.marathi: 'अ‍ॅप गोपनीयता धोरण आणि वापराच्या अटी येथे वाचा.',
      AppLanguage.gujarati: 'એપ્લિકેશન ગોપનીયતા નીતિ અને ઉપયોગની શરતો અહીં વાંચો.',
      AppLanguage.bengali: 'অ্যাপ গোপনীয়তা নীতি এবং ব্যবহারের শর্তাবলী এখানে পড়ুন।',
      AppLanguage.punjabi: 'ਐਪ ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਅਤੇ ਵਰਤੋਂ ਦੀਆਂ ਸ਼ਰਤਾਂ ਇੱਥੇ ਪੜ੍ਹੋ।',
      AppLanguage.odia: 'ଆପ୍ ଗୋପନୀୟତା ନୀତି ଏବଂ ବ୍ୟବହାର ନିୟମାବଳୀ ଏଠାରେ ପଢ଼ନ୍ତୁ।',
      AppLanguage.assamese: 'এপ গোপনীয়তা নীতি আৰু ব্যৱহাৰৰ চৰ্তাৱলী ইয়াত পঢ়ক।',
      AppLanguage.konkani: 'अ‍ॅप गोपनीयता नेम आनी वापर अटी हांगा वाच्यात.',
      AppLanguage.nepali: 'एप गोपनीयता नीति र प्रयोगका सर्तहरू यहाँ पढ्नुहोस्।',
      AppLanguage.meitei: 'App privacy policy amasung terms of use asi khallu.',
      AppLanguage.mizo: 'App privacy policy leh hman dan tur dan te heta tang hian chhiar rawh.',
      AppLanguage.kashmiri: 'ایپ پرائیویسی پالیسی تہٕ شرائط پٔریو ییٚتھ۔',
      AppLanguage.ladakhi: 'ཉེར་སྤྱོད་གསང་རྒྱ་དང་ཆ་རྐྱེན་འདི་ནས་ཀློགས།',
    },
    'Privacy Policy': {
      AppLanguage.hindi: 'गोपनीयता नीति',
      AppLanguage.tamil: 'தனியுரிமைக் கொள்கை',
      AppLanguage.kannada: 'ಗೌಪ್ಯತಾ ನೀತಿ',
      AppLanguage.malayalam: 'സ്വകാര്യതാ നയം',
      AppLanguage.marathi: 'गोपनीयता धोरण',
      AppLanguage.gujarati: 'ગોપનીયતા નીતિ',
      AppLanguage.bengali: 'গোপনীয়তা নীতি',
      AppLanguage.punjabi: 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ',
      AppLanguage.odia: 'ଗୋପନୀୟତା ନୀତି',
      AppLanguage.assamese: 'গোপনীয়তা নীতি',
      AppLanguage.konkani: 'गोपनीयता धोरण',
      AppLanguage.nepali: 'गोपनीयता नीति',
      AppLanguage.meitei: 'Privacy Policy',
      AppLanguage.mizo: 'Privacy Policy',
      AppLanguage.kashmiri: 'پرائیویسی پالیسی',
      AppLanguage.ladakhi: 'གསང་རྒྱའི་སྲིད་ཇུས།',
    },
    'Terms & Conditions': {
      AppLanguage.hindi: 'नियम और शर्तें',
      AppLanguage.tamil: 'விதிமுறைகள் & நிபந்தனைகள்',
      AppLanguage.kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
      AppLanguage.malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും',
      AppLanguage.marathi: 'नियम आणि अटी',
      AppLanguage.gujarati: 'નિયમો અને શરતો',
      AppLanguage.bengali: 'নিয়ম ও শর্তাবলী',
      AppLanguage.punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ',
      AppLanguage.odia: 'ନିୟମ ଏବଂ ସର୍ତ୍ତାବଳୀ',
      AppLanguage.assamese: 'নিয়ম আৰু চৰ্তাৱলী',
      AppLanguage.konkani: 'नेम आनी अटी',
      AppLanguage.nepali: 'नियम तथा सर्तहरू',
      AppLanguage.meitei: 'Terms & Conditions',
      AppLanguage.mizo: 'Dan leh Hrai',
      AppLanguage.kashmiri: 'شرائط و ضوابط',
      AppLanguage.ladakhi: 'ཆ་རྐྱེན་དང་ཁྲིམས་ལུགས།',
    },
    'Still need help?': {
      AppLanguage.hindi: 'क्या अभी भी सहायता चाहिए?',
      AppLanguage.tamil: 'இன்னும் உதவி தேவையா?',
      AppLanguage.kannada: 'ಇನ್ನೂ ಸಹಾಯ ಬೇಕೇ?',
      AppLanguage.malayalam: 'ഇപ്പോഴും സഹായം ആവശ്യമുണ്ടോ?',
      AppLanguage.marathi: 'अजूनही मदत हवी आहे का?',
      AppLanguage.gujarati: 'હજુ પણ મદદની જરૂર છે?',
      AppLanguage.bengali: 'এখনও সাহায্য প্রয়োজন?',
      AppLanguage.punjabi: 'ਕੀ ਅਜੇ ਵੀ ਮਦਦ ਚਾਹੀਦੀ ਹੈ?',
      AppLanguage.odia: 'ଏବେ ବି ସାହାଯ୍ୟ ଆବଶ୍ୟକ କି?',
      AppLanguage.assamese: 'এতিয়াও সহায়ৰ প্ৰয়োজন নেকি?',
      AppLanguage.konkani: 'अजूनय मदत जाय?',
      AppLanguage.nepali: 'अझै मद्दत चाहिन्छ?',
      AppLanguage.meitei: 'Atei mateng mathou tari-ba?',
      AppLanguage.mizo: 'Tanpuina i la mamawh cheu em?',
      AppLanguage.kashmiri: 'کٔریو ژھانٛڈَن مددٕچ ضروٗرتھ چھا؟',
      AppLanguage.ladakhi: 'ད་དུང་རོགས་རམ་དགོས་སམ།',
    },
    'Email us with the issue details. If you opened a question above, that context will also be added to the draft email.': {
      AppLanguage.hindi: 'समस्या विवरण के साथ हमें ईमेल करें। यदि आपने ऊपर कोई प्रश्न खोला है, तो वह संदर्भ भी ड्राफ्ट ईमेल में जुड़ जाएगा।',
      AppLanguage.tamil: 'சிக்கல் விவரங்களுடன் எங்களுக்கு மின்னஞ்சல் அனுப்பவும். மேலே ஒரு கேள்வியைத் திறந்திருந்தால், அந்த விவரமும் சேர்க்கப்படும்.',
      AppLanguage.kannada: 'ಸಮಸ್ಯೆಯ ವಿವರಗಳೊಂದಿಗೆ ನಮಗೆ ಇಮೇಲ್ ಮಾಡಿ. ನೀವು ಮೇಲೆ ಪ್ರಶ್ನೆಯನ್ನು ತೆರೆದಿದ್ದರೆ, ಆ ವಿವರವೂ ಡ್ರಾಫ್ಟ್ ಇಮೇಲ್‌ನಲ್ಲಿ ಸೇರಿಸಲ್ಪಡುತ್ತದೆ.',
      AppLanguage.malayalam: 'പ്രശ്ന വിവരങ്ങളുമായി ഞങ്ങൾക്ക് ഇമെയിൽ ചെയ്യുക. മുകളിലുള്ള ചോദ്യം തുറന്നിട്ടുണ്ടെങ്കിൽ, ആ സന്ദർഭവും ചേർക്കും.',
      AppLanguage.marathi: 'समस्येच्या तपशीलासह आम्हाला ईमेल करा. तुम्ही वरील प्रश्न उघडल्यास, तो संदर्भ मसुदा ईमेलमध्ये जोडला जाईल.',
      AppLanguage.gujarati: 'સમસ્યાની વિગતો સાથે અમને ઇમેઇલ કરો. જો તમે ઉપર પ્રશ્ન ખોલ્યો હોય, તો તે સંદર્ભ પણ ડ્રાફ્ટ ઇમેઇલમાં ઉમેરવામાં આવશે.',
      AppLanguage.bengali: 'সমস্যার বিবরণ সহ আমাদের ইমেল করুন। আপনি উপরে কোনো প্রশ্ন খুললে তা ড্রাফ্ট ইমেলে যুক্ত হবে।',
      AppLanguage.punjabi: 'ਮੁੱਦੇ ਦੇ ਵੇਰਵਿਆਂ ਨਾਲ ਸਾਨੂੰ ਈਮੇਲ ਕਰੋ। ਜੇਕਰ ਤੁਸੀਂ ਉੱਪਰ ਕੋਈ ਸਵਾਲ ਖੋਲ੍ਹਿਆ ਹੈ, ਤਾਂ ਉਹ ਡਰਾਫਟ ਈਮੇਲ ਵਿੱਚ ਸ਼ਾਮਲ ਹੋਵੇਗਾ।',
      AppLanguage.odia: 'ସମସ୍ୟା ବିବରଣୀ ସହିତ ଆମକୁ ଇମେଲ୍ କରନ୍ତୁ। ଯଦି ଆପଣ ଉପରେ ଏକ ପ୍ରଶ୍ନ ଖୋଲିଛନ୍ତି, ତେବେ ତାହା ଡ୍ରାଫ୍ଟ ଇମେଲରେ ଯୋଡ଼ାଯିବ।',
      AppLanguage.assamese: 'সমস্যাৰ বিৱৰণ সহ আমালৈ ইমেইল কৰক। আপুনি ওপৰত প্ৰশ্ন বাছিলে সেয়া ড্ৰাফ্ট ইমেইলত যোগ হ’ব।',
      AppLanguage.konkani: 'समस्येच्या तपशीलांसयत आमकां ईमेल करात. तुमी वयलो प्रस्न उकत केल्यार, तो संदर्भ ड्राफ्ट ईमेलांत जोडटलो.',
      AppLanguage.nepali: 'समस्याको विवरण सहित हामीलाई इमेल गर्नुहोस्। यदि तपाईंले माथिको प्रश्न खोल्नुभयो भने, त्यो मस्यौदा इमेलमा थपिनेछ।',
      AppLanguage.meitei: 'Awabagi details ga loina email toubiyu. Mathaktagi wahang khallabadi draft email da yapkhatkani.',
      AppLanguage.mizo: 'I harsatna min rawn email rawh. Chanchin i thlan kha email draft-ah a lo tel bawk ang.',
      AppLanguage.kashmiri: 'مسلہٕ کس تفصیلات سٟتۍ کٔریو سانہِ ای میل۔ برونٛٹھ سوالُک سیاق و سباق تہِ گژھہِ شامل۔',
      AppLanguage.ladakhi: 'དཀའ་ངལ་གྱི་གནས་ཚུལ་དང་བཅས་ཏེ་ང་ཚོར་ email གཏོང་གནང།',
    },
    'Email support': {
      AppLanguage.hindi: 'सपोर्ट को ईमेल करें',
      AppLanguage.tamil: 'ஆதரவுக்கு மின்னஞ்சல் அனுப்பவும்',
      AppLanguage.kannada: 'ಬೆಂಬಲಕ್ಕೆ ಇಮೇಲ್ ಮಾಡಿ',
      AppLanguage.malayalam: 'പിന്തുണയ്ക്ക് ഇമെയിൽ ചെയ്യുക',
      AppLanguage.marathi: 'सपोर्टला ईमेल करा',
      AppLanguage.gujarati: 'સપોર્ટને ઇમેઇલ કરો',
      AppLanguage.bengali: 'সাপোর্টে ইমেল করুন',
      AppLanguage.punjabi: 'ਸਹਾਇਤਾ ਲਈ ਈਮੇਲ ਕਰੋ',
      AppLanguage.odia: 'ସମର୍ଥନକୁ ଇମେଲ୍ କରନ୍ତୁ',
      AppLanguage.assamese: 'সমৰ্থনলৈ ইমেইল কৰক',
      AppLanguage.konkani: 'सपोर्टाक ईमेल धाडात',
      AppLanguage.nepali: 'सपोर्टलाई इमेल गर्नुहोस्',
      AppLanguage.meitei: 'Email support',
      AppLanguage.mizo: 'Support email rawh',
      AppLanguage.kashmiri: 'سپورٹَس کٔریو ای میل',
      AppLanguage.ladakhi: 'རྒྱབ་སྐྱོར་ལ་ email ཐོངས།',
    },
    'Copy support email': {
      AppLanguage.hindi: 'सपोर्ट ईमेल कॉपी करें',
      AppLanguage.tamil: 'ஆதரவு மின்னஞ்சலை நகலெடுக்கவும்',
      AppLanguage.kannada: 'ಬೆಂಬಲ ಇಮೇಲ್ ನಕಲಿಸಿ',
      AppLanguage.malayalam: 'പിന്തുണ ഇമെയിൽ പകർത്തുക',
      AppLanguage.marathi: 'सपोर्ट ईमेल कॉपी करा',
      AppLanguage.gujarati: 'સપોર્ટ ઇમેઇલ કૉપિ કરો',
      AppLanguage.bengali: 'সাপোর্ট ইমেল কপি করুন',
      AppLanguage.punjabi: 'ਸਹਾਇਤਾ ਈਮੇਲ ਕਾਪੀ ਕਰੋ',
      AppLanguage.odia: 'ସମର୍ଥନ ଇମେଲ୍ କପି କରନ୍ତୁ',
      AppLanguage.assamese: 'সমৰ্থন ইমেইল কপি কৰক',
      AppLanguage.konkani: 'सपोर्ट ईमेल कॉपी करात',
      AppLanguage.nepali: 'सपोर्ट इमेल प्रतिलिपि गर्नुहोस्',
      AppLanguage.meitei: 'Support email copy toubiyu',
      AppLanguage.mizo: 'Support email copy rawh',
      AppLanguage.kashmiri: 'سپورٹ ای میل کٔریو کاپی',
      AppLanguage.ladakhi: 'རྒྱབ་སྐྱོར་ email འདྲ་བཤུས་བྱོས།',
    },
    'Hello Mana Poster Ai team,\n\nIssue details:\n-': {
      AppLanguage.hindi: 'नमस्ते Mana Poster Ai टीम,\n\nमेरी समस्या का विवरण:\n-',
      AppLanguage.tamil: 'வணக்கம் Mana Poster Ai குழு,\n\nசிக்கல் விவரங்கள்:\n-',
      AppLanguage.kannada: 'ನಮಸ್ಕಾರ Mana Poster Ai ತಂಡ,\n\nನನ್ನ ಸಮಸ್ಯೆಯ ವಿವರಗಳು:\n-',
      AppLanguage.malayalam: 'നമസ്കാരം Mana Poster Ai ടീം,\n\nഎന്റെ പ്രശ്ന വിവരങ്ങൾ:\n-',
      AppLanguage.marathi: 'नमस्कार Mana Poster Ai टीम,\n\nमाझ्या समस्येचे तपशील:\n-',
      AppLanguage.gujarati: 'નમસ્તે Mana Poster Ai ટીમ,\n\nમારી સમસ્યાની વિગતો:\n-',
      AppLanguage.bengali: 'নমস্কার Mana Poster Ai টিম,\n\nআমার সমস্যার বিবরণ:\n-',
      AppLanguage.punjabi: 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ Mana Poster Ai ਟੀਮ,\n\nਮੇਰੀ ਸਮੱਸਿਆ ਦੇ ਵੇਰਵੇ:\n-',
      AppLanguage.odia: 'ନମସ୍କାର Mana Poster Ai ଟିମ୍,\n\nମୋ ସମସ୍ୟାର ବିବରଣୀ:\n-',
      AppLanguage.assamese: 'নমস্কাৰ Mana Poster Ai দল,\n\nমোৰ সমস্যাৰ বিৱৰণ:\n-',
      AppLanguage.konkani: 'नमस्कार Mana Poster Ai टिम,\n\nम्हज्या समस्येचो तपशील:\n-',
      AppLanguage.nepali: 'नमस्ते Mana Poster Ai टोली,\n\nमेरो समस्याको विवरण:\n-',
      AppLanguage.meitei: 'Khurumjari Mana Poster Ai team,\n\nEigi awabagi details:\n-',
      AppLanguage.mizo: 'Chibai Mana Poster Ai team,\n\nKa harsatna details:\n-',
      AppLanguage.kashmiri: 'سلام Mana Poster Ai ٹیم،\n\nمیٚأنۍ مسلہٕ کِس تفصیلات:\n-',
      AppLanguage.ladakhi: 'འཚམས་འདྲི་ཞུའོ Mana Poster Ai རུ་ཁག\n\nངའི་དཀའ་ངལ་གྱི་གནས་ཚུལ།\n-',
    },
    'Selected topic': {
      AppLanguage.hindi: 'चयनित विषय',
      AppLanguage.tamil: 'தேர்ந்தெடுக்கப்பட்ட தலைப்பு',
      AppLanguage.kannada: 'ಆಯ್ಕೆಮಾಡಿದ ವಿಷಯ',
      AppLanguage.malayalam: 'തിരഞ്ഞെടുത്ത വിഷയം',
      AppLanguage.marathi: 'निवडलेला विषय',
      AppLanguage.gujarati: 'પસંદ કરેલ વિષય',
      AppLanguage.bengali: 'নির্বাচিত বিষয়',
      AppLanguage.punjabi: 'ਚੁਣਿਆ ਵਿਸ਼ਾ',
      AppLanguage.odia: 'ଚୟନିତ ବିଷୟ',
      AppLanguage.assamese: 'নিৰ্বাচিত বিষয়',
      AppLanguage.konkani: 'वेंचून കാડिल्लो विशय',
      AppLanguage.nepali: 'चयनित विषय',
      AppLanguage.meitei: 'Selected topic',
      AppLanguage.mizo: 'Thupui thlan',
      AppLanguage.kashmiri: 'مُنتخب موضوٗع',
      AppLanguage.ladakhi: 'འདེམས་པའི་བརྗོད་གཞི།',
    },
    'Could not open the email app. Please use the support email manually.': {
      AppLanguage.hindi: 'ईमेल ऐप नहीं खुला। कृपया मैन्युअल रूप से सपोर्ट ईमेल का उपयोग करें।',
      AppLanguage.tamil: 'மின்னஞ்சல் செயலி திறக்கப்படவில்லை. ஆதரவு மின்னஞ்சலை கைமுறையாகப் பயன்படுத்தவும்.',
      AppLanguage.kannada: 'ಇಮೇಲ್ ಅಪ್ಲಿಕೇಶನ್ ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಬೆಂಬಲ ಇಮೇಲ್ ಅನ್ನು ಹಸ್ತಚಾಲಿತವಾಗಿ ಬಳಸಿ.',
      AppLanguage.malayalam: 'ഇമെയിൽ ആപ്പ് തുറക്കാൻ കഴിഞ്ഞില്ല. പിന്തുണാ ഇമെയിൽ നേരിട്ട് ഉപയോഗിക്കുക.',
      AppLanguage.marathi: 'ईमेल अ‍ॅप उघडता आले नाही. कृपया सपोर्ट ईमेल व्यक्तिचलितपणे वापरा.',
      AppLanguage.gujarati: 'ઇમેઇલ એપ્લિકેશન ખોલી શકાઈ નથી. કૃપા કરીને સપોર્ટ ઇમેઇલનો ઉપયોગ કરો.',
      AppLanguage.bengali: 'ইমেল অ্যাপ খোলা যায়নি। অনুগ্রহ করে সাপোর্ট ইমেল ব্যবহার করুন।',
      AppLanguage.punjabi: 'ਈਮੇਲ ਐਪ ਨਹੀਂ ਖੁੱਲ੍ਹ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਸਹਾਇਤਾ ਈਮੇਲ ਦੀ ਵਰਤੋਂ ਕਰੋ।',
      AppLanguage.odia: 'ଇମେଲ୍ ଆପ୍ ଖୋଲିପାରିଲା ନାହିଁ। ଦୟାକରି ସମର୍ଥନ ଇମେଲ୍ ବ୍ୟବହାର କରନ୍ତୁ।',
      AppLanguage.assamese: 'ইমেইল এপ খোল খাব নোৱাৰিলে। অনুগ্ৰহ কৰি সমৰ্থন ইমেইল ব্যৱহাৰ কৰক।',
      AppLanguage.konkani: 'ईमेल अ‍ॅप उकतें जालें ना. उपकार करून सपोर्ट ईमेल वापरात.',
      AppLanguage.nepali: 'इमेल एप खोल्न सकिएन। कृपया म्यानुअल रूपमा सपोर्ट इमेल प्रयोग गर्नुहोस्।',
      AppLanguage.meitei: 'Email app hangdokpa ngamde. Support email manually sijinnabiyu.',
      AppLanguage.mizo: 'Email app hawng thei lo. Khawngaihin support email hi mahni in hmang mai rawh.',
      AppLanguage.kashmiri: 'ای میل ایپ نہ کھٔلِتھ۔ مہربٲنی کٔرتھ کٔریو سَپورٹ ای میل پانے اِستعمال۔',
      AppLanguage.ladakhi: 'Email app ཁ་འབྱེད་མ་ཐུབ། ལག་པས་ support email བེད་སྤྱོད་གནང།',
    },
    'Support email copied.': {
      AppLanguage.hindi: 'सपोर्ट ईमेल कॉपी किया गया।',
      AppLanguage.tamil: 'ஆதரவு மின்னஞ்சல் நகலெடுக்கப்பட்டது.',
      AppLanguage.kannada: 'ಬೆಂಬಲ ಇಮೇಲ್ ನಕಲಿಸಲಾಗಿದೆ.',
      AppLanguage.malayalam: 'പിന്തുണ ഇമെയിൽ പകർത്തി.',
      AppLanguage.marathi: 'सपोर्ट ईमेल कॉपी केले.',
      AppLanguage.gujarati: 'સપોર્ટ ઇમેઇલ કૉપિ થયો.',
      AppLanguage.bengali: 'সাপোর্ট ইমেল কপি করা হয়েছে।',
      AppLanguage.punjabi: 'ਸਹਾਇਤਾ ਈਮੇਲ ਕਾਪੀ ਕੀਤੀ ਗਈ।',
      AppLanguage.odia: 'ସମର୍ଥନ ଇମେଲ୍ କପି ହୋଇଛି।',
      AppLanguage.assamese: 'সমৰ্থন ইমেইল কপি কৰা হ’ল।',
      AppLanguage.konkani: 'सपोर्ट ईमेल कॉपी जाली.',
      AppLanguage.nepali: 'सपोर्ट इमेल प्रतिलिपि गरियो।',
      AppLanguage.meitei: 'Support email copy toukhraba.',
      AppLanguage.mizo: 'Support email copy fel a ni.',
      AppLanguage.kashmiri: 'سپورٹ ای میل آو کاپی کرنہٕ۔',
      AppLanguage.ladakhi: 'རྒྱབ་སྐྱོར་ email འདྲ་བཤུས་བྱས་ཚར།',
    },
  };

  String _localized({required String telugu, required String english}) {
    final dict = _helpDictionary[english];
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

  String get title => _localized(
    telugu:
        '\u0C38\u0C39\u0C3E\u0C2F\u0C02 & \u0C38\u0C2A\u0C4B\u0C30\u0C4D\u0C1F\u0C4D',
    english: 'Help & Support',
  );

  String get faqLabel => _localized(
    telugu:
        '\u0C24\u0C30\u0C1A\u0C41\u0C17\u0C3E \u0C35\u0C1A\u0C4D\u0C1A\u0C47 \u0C2A\u0C4D\u0C30\u0C36\u0C4D\u0C28\u0C32\u0C41',
    english: 'Frequently asked questions',
  );

  String get headerTitle => _localized(
    telugu:
        '\u0C38\u0C2E\u0C38\u0C4D\u0C2F\u0C15\u0C3F \u0C35\u0C46\u0C02\u0C1F\u0C28\u0C47 \u0C2E\u0C3E\u0C30\u0C4D\u0C17\u0C26\u0C30\u0C4D\u0C36\u0C15\u0C02',
    english: 'Quick guidance for common issues',
  );

  String get headerSubtitle => _localized(
    telugu:
        '\u0C32\u0C3E\u0C17\u0C3F\u0C28\u0C4D, \u0C2B\u0C4B\u0C1F\u0C4B \u0C0E\u0C02\u0C2A\u0C3F\u0C15, \u0C38\u0C47\u0C35\u0C4D, \u0C0E\u0C17\u0C41\u0C2E\u0C24\u0C3F, \u0C38\u0C2C\u0C4D\u0C38\u0C4D\u0C15\u0C4D\u0C30\u0C3F\u0C2A\u0C4D\u0C37\u0C28\u0C4D \u0C32\u0C47\u0C26\u0C3E \u0C38\u0C3E\u0C27\u0C3E\u0C30\u0C23 \u0C2F\u0C3E\u0C2A\u0C4D \u0C35\u0C3F\u0C28\u0C3F\u0C2F\u0C4B\u0C17\u0C3E\u0C28\u0C3F\u0C15\u0C3F \u0C38\u0C02\u0C2C\u0C02\u0C27\u0C3F\u0C02\u0C1A\u0C3F\u0C28 \u0C38\u0C3E\u0C27\u0C3E\u0C30\u0C23 \u0C2A\u0C4D\u0C30\u0C36\u0C4D\u0C28\u0C32\u0C15\u0C41 \u0C07\u0C15\u0C4D\u0C15\u0C21\u0C47 \u0C38\u0C2E\u0C3E\u0C27\u0C3E\u0C28\u0C3E\u0C32\u0C41 \u0C09\u0C28\u0C4D\u0C28\u0C3E\u0C2F\u0C3F. \u0C2F\u0C3E\u0C2A\u0C4D\u0C32\u0C4B \u0C15\u0C28\u0C3F\u0C2A\u0C3F\u0C02\u0C1A\u0C47 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D\u0C32\u0C41 \u0C2A\u0C4D\u0C30\u0C1A\u0C41\u0C30\u0C23\u0C15\u0C41 \u0C2E\u0C41\u0C02\u0C26\u0C41 review \u0C1A\u0C47\u0C2F\u0C2C\u0C21\u0C24\u0C3E\u0C2F\u0C3F.',
    english:
        'Find quick answers for login, photo import, save/export, subscription, and other common app issues. Posters shown in the app are reviewed before publishing.',
  );

  String get legalTitle => _localized(
    telugu:
        '\u0C2A\u0C4D\u0C30\u0C48\u0C35\u0C38\u0C40 \u0C2E\u0C30\u0C3F\u0C2F\u0C41 \u0C28\u0C3F\u0C2C\u0C02\u0C27\u0C28\u0C32\u0C41',
    english: 'Privacy and terms',
  );

  String get legalSubtitle => _localized(
    telugu:
        '\u0C2F\u0C3E\u0C2A\u0C4D \u0C35\u0C3F\u0C28\u0C3F\u0C2F\u0C4B\u0C17\u0C02, \u0C21\u0C47\u0C1F\u0C3E \u0C28\u0C3F\u0C30\u0C4D\u0C35\u0C39\u0C23 \u0C2E\u0C30\u0C3F\u0C2F\u0C41 \u0C28\u0C3F\u0C2C\u0C02\u0C27\u0C28\u0C32 \u0C35\u0C3F\u0C35\u0C30\u0C3E\u0C32\u0C41 \u0C07\u0C15\u0C4D\u0C15\u0C21 \u0C1A\u0C42\u0C21\u0C35\u0C1A\u0C4D\u0C1A\u0C41.',
    english: 'Read the app privacy policy and terms of use here.',
  );

  String get privacyLabel => _localized(
    telugu:
        '\u0C2A\u0C4D\u0C30\u0C48\u0C35\u0C38\u0C40 \u0C2A\u0C3E\u0C32\u0C38\u0C40',
    english: 'Privacy Policy',
  );

  String get termsLabel => _localized(
    telugu: '\u0C28\u0C3F\u0C2C\u0C02\u0C27\u0C28\u0C32\u0C41',
    english: 'Terms & Conditions',
  );

  String get stillNeedHelpTitle => _localized(
    telugu:
        '\u0C07\u0C02\u0C15\u0C3E \u0C38\u0C39\u0C3E\u0C2F\u0C02 \u0C15\u0C3E\u0C35\u0C3E\u0C32\u0C3E?',
    english: 'Still need help?',
  );

  String get stillNeedHelpSubtitle => _localized(
    telugu:
        '\u0C2E\u0C40 \u0C38\u0C2E\u0C38\u0C4D\u0C2F \u0C35\u0C3F\u0C35\u0C30\u0C3E\u0C32\u0C28\u0C41 \u0C2E\u0C3E\u0C15\u0C41 \u0C2E\u0C46\u0C2F\u0C3F\u0C32\u0C4D \u0C1A\u0C47\u0C2F\u0C02\u0C21\u0C3F. \u0C2E\u0C40\u0C30\u0C41 \u0C0E\u0C02\u0C1A\u0C41\u0C15\u0C41\u0C28\u0C4D\u0C28 \u0C2A\u0C4D\u0C30\u0C36\u0C4D\u0C28\u0C15\u0C41 \u0C38\u0C02\u0C2C\u0C02\u0C27\u0C3F\u0C02\u0C1A\u0C3F\u0C28 \u0C35\u0C3F\u0C35\u0C30\u0C3E\u0C32\u0C41 \u0C15\u0C42\u0C21\u0C3E \u0C06\u0C1F\u0C4B\u0C2E\u0C47\u0C1F\u0C3F\u0C15\u0C4D\u0C17\u0C3E \u0C1C\u0C4B\u0C21\u0C3F\u0C02\u0C1A\u0C2C\u0C21\u0C24\u0C3E\u0C2F\u0C3F.',
    english:
        'Email us with the issue details. If you opened a question above, that context will also be added to the draft email.',
  );

  String get contactButton => _localized(
    telugu:
        '\u0C38\u0C2A\u0C4B\u0C30\u0C4D\u0C1F\u0C4D\u0C15\u0C41 \u0C07\u0C2E\u0C46\u0C2F\u0C3F\u0C32\u0C4D \u0C2A\u0C02\u0C2A\u0C02\u0C21\u0C3F',
    english: 'Email support',
  );

  String get copyEmailButton => _localized(
    telugu:
        '\u0C38\u0C2A\u0C4B\u0C30\u0C4D\u0C1F\u0C4D \u0C07\u0C2E\u0C46\u0C2F\u0C3F\u0C32\u0C4D \u0C15\u0C3E\u0C2A\u0C40 \u0C1A\u0C47\u0C2F\u0C02\u0C21\u0C3F',
    english: 'Copy support email',
  );

  String get defaultSubject => 'Mana Poster Ai Support Request';

  String get defaultBody => _localized(
    telugu:
        '\u0C28\u0C2E\u0C38\u0C4D\u0C15\u0C3E\u0C30\u0C02 Mana Poster Ai \u0C1F\u0C40\u0C2E\u0C4D,\n\n\u0C28\u0C3E \u0C38\u0C2E\u0C38\u0C4D\u0C2F \u0C35\u0C3F\u0C35\u0C30\u0C3E\u0C32\u0C41:\n-',
    english: 'Hello Mana Poster Ai team,\n\nIssue details:\n-',
  );

  String get contextLabel => _localized(
    telugu:
        '\u0C0E\u0C02\u0C1A\u0C41\u0C15\u0C41\u0C28\u0C4D\u0C28 \u0C35\u0C3F\u0C37\u0C2F\u0C02',
    english: 'Selected topic',
  );

  String get emailOpenFailed => _localized(
    telugu:
        '\u0C07\u0C2E\u0C46\u0C2F\u0C3F\u0C32\u0C4D \u0C2F\u0C3E\u0C2A\u0C4D \u0C13\u0C2A\u0C46\u0C28\u0C4D \u0C15\u0C3E\u0C32\u0C47\u0C26\u0C41. \u0C26\u0C2F\u0C1A\u0C47\u0C38\u0C3F \u0C38\u0C2A\u0C4B\u0C30\u0C4D\u0C1F\u0C4D \u0C07\u0C2E\u0C46\u0C2F\u0C3F\u0C32\u0C4D\u0C28\u0C41 \u0C2E\u0C3E\u0C28\u0C4D\u0C2F\u0C41\u0C35\u0C32\u0C4D\u0C17\u0C3E \u0C09\u0C2A\u0C2F\u0C4B\u0C17\u0C3F\u0C02\u0C1A\u0C02\u0C21\u0C3F.',
    english:
        'Could not open the email app. Please use the support email manually.',
  );

  String get emailCopied => _localized(
    telugu:
        '\u0C38\u0C2A\u0C4B\u0C30\u0C4D\u0C1F\u0C4D \u0C07\u0C2E\u0C46\u0C2F\u0C3F\u0C32\u0C4D \u0C15\u0C3E\u0C2A\u0C40 \u0C05\u0C2F\u0C3F\u0C02\u0C26\u0C3F.',
    english: 'Support email copied.',
  );
  List<_HelpFaqItem> get faqs => _isTelugu
      ? const <_HelpFaqItem>[
          _HelpFaqItem(
            question:
                'à°²à°¾à°—à°¿à°¨à± à°ªà°¨à°¿à°šà±‡à°¯à°•à°ªà±‹à°¤à±‡ à°à°®à°¿ à°šà±‡à°¯à°¾à°²à°¿?',
            answer:
                '1) à°‡à°‚à°Ÿà°°à±à°¨à±†à°Ÿà± à°•à°¨à±†à°•à±à°·à°¨à± à°¸à°°à°¿à°—à±à°—à°¾ à°‰à°‚à°¦à±‹ à°šà±‚à°¡à°‚à°¡à°¿.\n2) à°‡à°®à±†à°¯à°¿à°²à±, à°ªà°¾à°¸à±â€Œà°µà°°à±à°¡à± à°¸à°°à°¿à°—à°¾ à°‡à°šà±à°šà°¾à°°à±‹ à°ªà°°à°¿à°¶à±€à°²à°¿à°‚à°šà°‚à°¡à°¿.\n3) à°…à°µà°¸à°°à°®à±ˆà°¤à±‡ Forgot Password à°‰à°ªà°¯à±‹à°—à°¿à°‚à°šà°‚à°¡à°¿.\n4) Google Sign-In à°…à°¯à°¿à°¤à±‡ account permission à°‡à°µà±à°µà°¬à°¡à°¿à°‚à°¦à±‹ à°šà±‚à°¡à°‚à°¡à°¿.',
          ),
          _HelpFaqItem(
            question:
                'Community image/quote upload పనిచేయకపోతే?',
            answer:
                '1) Image upload à°…à°¯à°¿à°¤à±‡ Photos à°²à±‡à°¦à°¾ media permission à°‡à°šà±à°šà°¾à°°à±‹ à°šà±‚à°¡à°‚à°¡à°¿.\n2) Quote-only à°…à°¯à°¿à°¤à±‡ text à°–à°¾à°³à±€à°—à°¾ à°²à±‡à°•à±à°‚à°¡à°¾ à°‰à°‚à°¦à±‹ à°šà±‚à°¡à°‚à°¡à°¿.\n3) à°šà°¾à°²à°¾ à°ªà±†à°¦à±à°¦ image à°…à°¯à°¿à°¤à±‡ à°šà°¿à°¨à±à°¨ à°«à±ˆà°²à±â€Œà°¤à±‹ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.\n4) Submit à°…à°¯à°¿à°¨ à°¤à°°à±à°µà°¾à°¤ manager review à°ªà±‚à°°à±à°¤à°¯à±à°¯à°¾à°• à°®à°¾à°¤à±à°°à°®à±‡ poster app category à°²à±‹ à°•à°¨à°¿à°ªà°¿à°¸à±à°¤à±à°‚à°¦à°¿.',
          ),
          _HelpFaqItem(
            question:
                'à°ªà±‹à°¸à±à°Ÿà°°à± à°¸à±‡à°µà± à°²à±‡à°¦à°¾ à°Žà°—à±à°®à°¤à°¿ à°µà°¿à°«à°²à°®à±ˆà°¤à±‡?',
            answer:
                '1) à°«à±‹à°¨à±â€Œà°²à±‹ à°–à°¾à°³à±€ à°¸à±à°Ÿà±‹à°°à±‡à°œà± à°‰à°‚à°¦à±‹ à°šà±‚à°¡à°‚à°¡à°¿.\n2) à°¸à±‡à°µà± à°²à±‡à°¦à°¾ à°Žà°—à±à°®à°¤à°¿ à°œà°°à±à°—à±à°¤à±à°¨à±à°¨ à°¸à°®à°¯à°‚à°²à±‹ à°¯à°¾à°ªà±â€Œà°¨à± à°µà±†à°¨à±à°•à°•à± à°ªà°‚à°ªà°•à°‚à°¡à°¿.\n3) à°®à°°à±‹à°¸à°¾à°°à°¿ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.\n4) à°¸à°®à°¸à±à°¯ à°…à°²à°¾à°—à±‡ à°‰à°‚à°Ÿà±‡ à°¸à±à°•à±à°°à±€à°¨à±â€Œà°·à°¾à°Ÿà±â€Œà°¤à±‹ à°¸à°ªà±‹à°°à±à°Ÿà±â€Œà°•à± à°®à±†à°¯à°¿à°²à± à°ªà°‚à°ªà°‚à°¡à°¿.',
          ),
          _HelpFaqItem(
            question:
                'à°¸à°¬à±â€Œà°¸à±à°•à±à°°à°¿à°ªà±à°·à°¨à± à°—à±à°°à°¿à°‚à°šà°¿ à°¸à°‚à°¦à±‡à°¹à°‚ à°‰à°‚à°Ÿà±‡?',
            answer:
                'à°Ÿà±à°°à°¯à°²à± à°ªà±à°²à°¾à°¨à± ${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°²à°•à± ${SubscriptionPlanConfig.trialPriceDisplay}. ${SubscriptionPlanConfig.trialDays} à°°à±‹à°œà±à°² à°²à±‹à°ªà± à°•à±à°¯à°¾à°¨à±à°¸à°¿à°²à± à°šà±‡à°¯à°•à°ªà±‹à°¤à±‡ à°¨à±†à°²à°•à± ${SubscriptionPlanConfig.monthlyPriceDisplay} à°†à°Ÿà±‹ à°°à°¿à°¨à±à°¯à±à°µà°²à± à°‰à°‚à°Ÿà±à°‚à°¦à°¿. à°ˆ à°ªà±à°²à°¾à°¨à± à°ªà±‹à°¸à±à°Ÿà°°à± à°•à±à°°à°¿à°¯à±‡à°·à°¨à± à°®à°°à°¿à°¯à± à°Žà°—à±à°®à°¤à±à°²à°•à± à°‰à°ªà°¯à±‹à°—à°ªà°¡à±à°¤à±à°‚à°¦à°¿.',
          ),
          _HelpFaqItem(
            question:
                'à°¯à°¾à°ªà± à°¸à±à°²à±‹à°—à°¾ à°‰à°‚à°Ÿà±‡ à°²à±‡à°¦à°¾ à°µà°¿à°‚à°¤à°—à°¾ à°ªà±à°°à°µà°°à±à°¤à°¿à°¸à±à°¤à±‡?',
            answer:
                '1) à°¯à°¾à°ªà±â€Œà°¨à± à°ªà±‚à°°à±à°¤à°¿à°—à°¾ à°®à±‚à°¸à°¿ à°®à°³à±à°²à±€ à°¤à±†à°°à°µà°‚à°¡à°¿.\n2) à°«à±‹à°¨à±â€Œà°¨à± à°°à±€à°¸à±à°Ÿà°¾à°°à±à°Ÿà± à°šà±‡à°¯à°‚à°¡à°¿.\n3) à°µà±†à°¨à±à°• à°­à°¾à°—à°‚à°²à±‹ à°¨à°¡à±à°¸à±à°¤à±à°¨à±à°¨ à°ªà±†à°¦à±à°¦ apps à°¨à± à°®à±‚à°¸à°¿à°µà±‡à°¯à°‚à°¡à°¿.\n4) à°¸à°®à°¸à±à°¯ à° à°¦à°¶à°²à±‹ à°µà°¸à±à°¤à±à°‚à°¦à±‹ à°¸à°ªà±‹à°°à±à°Ÿà±â€Œà°•à± à°ªà°‚à°ªà°‚à°¡à°¿.',
          ),
        ]
      : const <_HelpFaqItem>[
          _HelpFaqItem(
            question: 'What should I do if login fails?',
            answer:
                '1) Check your internet connection.\n2) Confirm the email and password.\n3) Use Forgot Password if needed.\n4) For Google Sign-In, make sure account permissions are granted.',
          ),
          _HelpFaqItem(
            question: 'What if community image/quote upload is not working?',
            answer:
                '1) For image upload, check photos or media permission.\n2) For quote-only upload, make sure the text is not empty.\n3) Try a smaller image file if needed.\n4) After submit, the poster appears in the app category only after manager review.',
          ),
          _HelpFaqItem(
            question: 'What if save or export fails?',
            answer:
                '1) Make sure the device has enough free storage.\n2) Keep the app in the foreground while exporting.\n3) Try again once.\n4) If the issue continues, email support with a screenshot.',
          ),
          _HelpFaqItem(
            question: 'What if I have subscription-related doubts?',
            answer:
                'The trial plan is ${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days. If not cancelled within ${SubscriptionPlanConfig.trialDays} days, the subscription auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month. The plan supports poster creation and exports.',
          ),
          _HelpFaqItem(
            question: 'What if the app is slow or behaving unexpectedly?',
            answer:
                '1) Fully close and reopen the app.\n2) Restart the device.\n3) Close heavy background apps.\n4) Send the exact steps of the issue to support.',
          ),
        ];
}
