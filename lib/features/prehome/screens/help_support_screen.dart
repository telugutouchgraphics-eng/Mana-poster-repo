import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with AppLanguageStateMixin {
  static const String _supportEmail = 'telugutouchgraphics@gmail.com';
  int? _expandedIndex;

  Future<void> _contactSupport(_HelpSupportCopy copy) async {
    final selected = _expandedIndex != null ? copy.faqs[_expandedIndex!] : null;
    final subject = selected == null
        ? copy.defaultSubject
        : '${copy.defaultSubject} - ${selected.question}';
    final body = selected == null
        ? copy.defaultBody
        : '${copy.defaultBody}\n\n${copy.contextLabel}: ${selected.question}\n';

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
      ).showSnackBar(SnackBar(content: Text(copy.emailOpenFailed)));
    }
  }

  Future<void> _openLegalDocument(LegalDocumentType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(documentType: type),
      ),
    );
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
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: -80,
            right: -30,
            child: _SupportOrb(size: 200, color: Color(0x3322C55E)),
          ),
          const Positioned(
            top: 150,
            left: -60,
            child: _SupportOrb(size: 170, color: Color(0x332563EB)),
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
                      colors: <Color>[
                        Color(0xFFEAF5FF),
                        Color(0xFFF2FBF4),
                        Color(0xFFFFFFFF),
                      ],
                    ),
                    border: Border.all(color: const Color(0xD9E3EDF6)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 28,
                        offset: Offset(0, 16),
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
                          fontWeight: FontWeight.w900,
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
                        color: Color(0x0F0F172A),
                        blurRadius: 18,
                        offset: Offset(0, 10),
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
                                      fontWeight: FontWeight.w700,
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
                      colors: <Color>[
                        Color(0xFFEAF1FF),
                        Color(0xFFF3F7FC),
                        Color(0xFFFFFFFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFDDE6F2)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x100F172A),
                        blurRadius: 18,
                        offset: Offset(0, 10),
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
                          fontWeight: FontWeight.w800,
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
                            fontWeight: FontWeight.w700,
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
          fontWeight: FontWeight.w800,
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
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w700,
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

  String get title => _isTelugu ? 'సహాయం & సపోర్ట్' : 'Help & support';
  String get faqLabel =>
      _isTelugu ? 'తరచుగా వచ్చే ప్రశ్నలు' : 'Frequently asked questions';
  String get headerTitle => _isTelugu
      ? 'సమస్యకి వెంటనే మార్గదర్శకం'
      : 'Quick guidance for common issues';
  String get headerSubtitle => _isTelugu
      ? 'లాగిన్, ఫోటో ఎంపిక, సేవ్, ఎగుమతి, సబ్‌స్క్రిప్షన్ లేదా సాధారణ యాప్ వినియోగానికి సంబంధించిన సాధారణ ప్రశ్నలకు ఇక్కడే సమాధానాలు ఉన్నాయి.'
      : 'Find quick answers for login, photo import, save/export, subscription, and other common app issues.';
  String get legalTitle =>
      _isTelugu ? 'ప్రైవసీ మరియు నిబంధనలు' : 'Privacy and terms';
  String get legalSubtitle => _isTelugu
      ? 'యాప్ వినియోగం, డేటా నిర్వహణ మరియు నిబంధనల వివరాలు ఇక్కడ చూడవచ్చు.'
      : 'Read the app privacy policy and terms of use here.';
  String get privacyLabel => _isTelugu ? 'ప్రైవసీ పాలసీ' : 'Privacy Policy';
  String get termsLabel => _isTelugu ? 'నిబంధనలు' : 'Terms & Conditions';
  String get stillNeedHelpTitle =>
      _isTelugu ? 'ఇంకా సహాయం కావాలా?' : 'Still need help?';
  String get stillNeedHelpSubtitle => _isTelugu
      ? 'మీ సమస్య వివరాలను మాకు మెయిల్ చేయండి. మీరు ఎంచుకున్న ప్రశ్నకు సంబంధించిన వివరాలు కూడా ఆటోమేటిక్‌గా జోడించబడతాయి.'
      : 'Email us with the issue details. If you opened a question above, that context will also be added to the draft email.';
  String get contactButton =>
      _isTelugu ? 'సపోర్ట్‌కు ఇమెయిల్ పంపండి' : 'Email support';
  String get defaultSubject => 'Mana Poster Support Request';
  String get defaultBody => _isTelugu
      ? 'నమస్కారం Mana Poster టీమ్,\n\nనా సమస్య వివరాలు:\n-'
      : 'Hello Mana Poster team,\n\nIssue details:\n-';
  String get contextLabel => _isTelugu ? 'ఎంచుకున్న విషయం' : 'Selected topic';
  String get emailOpenFailed => _isTelugu
      ? 'ఇమెయిల్ యాప్ ఓపెన్ కాలేదు. దయచేసి సపోర్ట్ ఇమెయిల్‌ను మాన్యువల్‌గా ఉపయోగించండి.'
      : 'Could not open the email app. Please use the support email manually.';

  List<_HelpFaqItem> get faqs => _isTelugu
      ? const <_HelpFaqItem>[
          _HelpFaqItem(
            question: 'లాగిన్ పనిచేయకపోతే ఏమి చేయాలి?',
            answer:
                '1) ఇంటర్నెట్ కనెక్షన్ సరిగ్గా ఉందో చూడండి.\n2) ఇమెయిల్, పాస్‌వర్డ్ సరిగా ఇచ్చారో పరిశీలించండి.\n3) అవసరమైతే Forgot Password ఉపయోగించండి.\n4) Google Sign-In అయితే account permission ఇవ్వబడిందో చూడండి.',
          ),
          _HelpFaqItem(
            question: 'ఫోటో ఎంపిక లేదా అప్‌లోడ్ కావడం లేకపోతే?',
            answer:
                '1) Photos లేదా media permission ఇచ్చారో చూడండి.\n2) Permission deny చేసి ఉంటే App Settings నుంచి enable చేయండి.\n3) చాలా పెద్ద image అయితే మరో చిన్న ఫైల్‌తో ప్రయత్నించండి.\n4) యాప్‌ను మళ్లీ ఓపెన్ చేసి మరోసారి ప్రయత్నించండి.',
          ),
          _HelpFaqItem(
            question: 'పోస్టర్ సేవ్ లేదా ఎగుమతి విఫలమైతే?',
            answer:
                '1) ఫోన్‌లో ఖాళీ స్టోరేజ్ ఉందో చూడండి.\n2) సేవ్ లేదా ఎగుమతి జరుగుతున్న సమయంలో యాప్‌ను minimize చేయకండి.\n3) మరోసారి ప్రయత్నించండి.\n4) సమస్య అలాగే ఉంటే screenshot తో support కు మెయిల్ పంపండి.',
          ),
          _HelpFaqItem(
            question: 'సబ్‌స్క్రిప్షన్ గురించి సందేహం ఉంటే?',
            answer:
                'Trial ప్లాన్ రూ.1 కు 3 రోజులు. Trial తర్వాత నెలకు రూ.149 auto-renewal ఉంటుంది. Free ట్యాబ్ పోస్టర్లకు మాత్రమే ప్లాన్ వర్తిస్తుంది. Premium పోస్టర్లు వేరుగా కొనాలి.',
          ),
          _HelpFaqItem(
            question: 'యాప్ స్లోగా ఉంటే లేదా వింతగా ప్రవర్తిస్తే?',
            answer:
                '1) యాప్‌ను పూర్తిగా close చేసి మళ్లీ తెరవండి.\n2) ఫోన్‌ను restart చేయండి.\n3) background లో ఉన్న heavy apps close చేయండి.\n4) సమస్య ఏ step లో వస్తుందో support కు పంపండి.',
          ),
        ]
      : const <_HelpFaqItem>[
          _HelpFaqItem(
            question: 'What should I do if login fails?',
            answer:
                '1) Check your internet connection.\n2) Confirm the email and password.\n3) Use Forgot Password if needed.\n4) For Google Sign-In, make sure account permissions are granted.',
          ),
          _HelpFaqItem(
            question: 'What if image upload or import is not working?',
            answer:
                '1) Check photos or media permission.\n2) If permission was denied, enable it from App Settings.\n3) Try a smaller image file.\n4) Reopen the app and try again.',
          ),
          _HelpFaqItem(
            question: 'What if save or export fails?',
            answer:
                '1) Make sure the device has enough free storage.\n2) Keep the app in the foreground while exporting.\n3) Try again once.\n4) If the issue continues, email support with a screenshot.',
          ),
          _HelpFaqItem(
            question: 'What if I have subscription-related doubts?',
            answer:
                'The trial plan is Rs.1 for 3 days. After the trial, the monthly plan renews at Rs.149. The plan applies only to Free-tab posters. Premium posters must be purchased separately.',
          ),
          _HelpFaqItem(
            question: 'What if the app is slow or behaving unexpectedly?',
            answer:
                '1) Fully close and reopen the app.\n2) Restart the device.\n3) Close heavy background apps.\n4) Send the exact steps of the issue to support.',
          ),
        ];
}
