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

  String get title => _isTelugu ? 'సహాయం & సపోర్ట్' : 'Help & support';
  String get faqLabel =>
      _isTelugu ? 'తరచుగా వచ్చే ప్రశ్నలు' : 'Frequently asked questions';
  String get headerTitle => _isTelugu
      ? 'సమస్యకి వెంటనే మార్గదర్శకం'
      : 'Quick guidance for common issues';
  String get headerSubtitle => _isTelugu
      ? 'లాగిన్, ఫోటో ఎంపిక, సేవ్, ఎగుమతి, సబ్‌స్క్రిప్షన్ లేదా సాధారణ యాప్ వినియోగానికి సంబంధించిన సాధారణ ప్రశ్నలకు ఇక్కడే సమాధానాలు ఉన్నాయి. యాప్‌లో కనిపించే పోస్టర్లు ప్రచురణకు ముందు review చేయబడతాయి.'
      : 'Find quick answers for login, photo import, save/export, subscription, and other common app issues. Posters shown in the app are reviewed before publishing.';
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
  String get copyEmailButton =>
      _isTelugu ? 'సపోర్ట్ ఇమెయిల్ కాపీ చేయండి' : 'Copy support email';
  String get defaultSubject => 'Mana Poster Ai Support Request';
  String get defaultBody => _isTelugu
      ? 'నమస్కారం Mana Poster Ai టీమ్,\n\nనా సమస్య వివరాలు:\n-'
      : 'Hello Mana Poster Ai team,\n\nIssue details:\n-';
  String get contextLabel => _isTelugu ? 'ఎంచుకున్న విషయం' : 'Selected topic';
  String get emailOpenFailed => _isTelugu
      ? 'ఇమెయిల్ యాప్ ఓపెన్ కాలేదు. దయచేసి సపోర్ట్ ఇమెయిల్‌ను మాన్యువల్‌గా ఉపయోగించండి.'
      : 'Could not open the email app. Please use the support email manually.';
  String get emailCopied =>
      _isTelugu ? 'సపోర్ట్ ఇమెయిల్ కాపీ అయింది.' : 'Support email copied.';

  List<_HelpFaqItem> get faqs => _isTelugu
      ? const <_HelpFaqItem>[
          _HelpFaqItem(
            question: 'లాగిన్ పనిచేయకపోతే ఏమి చేయాలి?',
            answer:
                '1) ఇంటర్నెట్ కనెక్షన్ సరిగ్గా ఉందో చూడండి.\n2) ఇమెయిల్, పాస్‌వర్డ్ సరిగా ఇచ్చారో పరిశీలించండి.\n3) అవసరమైతే Forgot Password ఉపయోగించండి.\n4) Google Sign-In అయితే account permission ఇవ్వబడిందో చూడండి.',
          ),
          _HelpFaqItem(
            question: 'Community image/quote upload పనిచేయకపోతే?',
            answer:
                '1) Image upload అయితే Photos లేదా media permission ఇచ్చారో చూడండి.\n2) Quote-only అయితే text ఖాళీగా లేకుండా ఉందో చూడండి.\n3) చాలా పెద్ద image అయితే చిన్న ఫైల్‌తో ప్రయత్నించండి.\n4) Submit అయిన తర్వాత manager review పూర్తయ్యాక మాత్రమే poster app category లో కనిపిస్తుంది.',
          ),
          _HelpFaqItem(
            question: 'Status upload/replies ఎలా పని చేస్తాయి?',
            answer:
                '1) Status లో text, image లేదా image + caption upload చేయవచ్చు.\n'
                '2) 24 గంటల్లో 5 text statuses మరియు 2 image/image + caption statuses వరకు active గా ఉంచవచ్చు. పాత active status delete చేస్తే లేదా expire అయితే మళ్లీ limit లోపల upload చేయవచ్చు.\n'
                '3) Status same State/Union Territory మరియు matching religion scope users కు మాత్రమే చూపబడుతుంది.\n'
                '4) Image status upload ముందు file size తగ్గించడానికి compress అవుతుంది.\n'
                '5) Other users reply/comment పంపవచ్చు; status owner status screen లో up swipe చేస్తే replies చూడవచ్చు.\n'
                '6) Status, image, replies/comments 24 గంటల expiry తర్వాత backend cleanup ద్వారా delete అవుతాయి. Cleanup scheduled కాబట్టి exact second కు delete కాకపోవచ్చు.\n'
                '7) Private information, OTP, passwords, addresses, hateful/illegal/spam content status లేదా reply లో పెట్టకండి.',
          ),
          _HelpFaqItem(
            question: 'పోస్టర్ సేవ్ లేదా ఎగుమతి విఫలమైతే?',
            answer:
                '1) ఫోన్‌లో ఖాళీ స్టోరేజ్ ఉందో చూడండి.\n2) సేవ్ లేదా ఎగుమతి జరుగుతున్న సమయంలో యాప్‌ను వెనుకకు పంపకండి.\n3) మరోసారి ప్రయత్నించండి.\n4) సమస్య అలాగే ఉంటే స్క్రీన్‌షాట్‌తో సపోర్ట్‌కు మెయిల్ పంపండి.',
          ),
          _HelpFaqItem(
            question: 'సబ్‌స్క్రిప్షన్ గురించి సందేహం ఉంటే?',
            answer:
                'ట్రయల్ ప్లాన్ ${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay}. ${SubscriptionPlanConfig.trialDays} రోజుల లోపు క్యాన్సిల్ చేయకపోతే నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} ఆటో రిన్యువల్ ఉంటుంది. ఈ ప్లాన్ పోస్టర్ క్రియేషన్ మరియు ఎగుమతులకు ఉపయోగపడుతుంది.',
          ),
          _HelpFaqItem(
            question: 'యాప్ స్లోగా ఉంటే లేదా వింతగా ప్రవర్తిస్తే?',
            answer:
                '1) యాప్‌ను పూర్తిగా మూసి మళ్లీ తెరవండి.\n2) ఫోన్‌ను రీస్టార్ట్ చేయండి.\n3) వెనుక భాగంలో నడుస్తున్న పెద్ద apps ను మూసివేయండి.\n4) సమస్య ఏ దశలో వస్తుందో సపోర్ట్‌కు పంపండి.',
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
            question: 'How do Status uploads and replies work?',
            answer:
                '1) A status can be text, image, or image with caption.\n'
                '2) A user can keep up to 5 text statuses and 2 image/image + caption statuses active in 24 hours. Deleting an old active status or waiting for expiry frees the limit again.\n'
                '3) Status visibility is limited to users in the same State/Union Territory and matching religion scope.\n'
                '4) Image status files are compressed before upload to reduce file size.\n'
                '5) Other users can reply/comment; the status owner can swipe up on the status screen to read replies.\n'
                '6) Statuses, images, and replies/comments are deleted by backend cleanup after the 24-hour expiry. Because cleanup is scheduled, deletion may not happen at the exact second.\n'
                '7) Do not post private information, OTPs, passwords, addresses, hateful/illegal/spam content in a status or reply.',
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
