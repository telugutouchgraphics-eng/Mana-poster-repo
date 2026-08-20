import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/quiz_prize_details_service.dart';

Future<bool?> showQuizPrizeDetailsSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const QuizPrizeDetailsScreen(isModal: true),
  );
}

class QuizPrizeDetailsScreen extends StatefulWidget {
  const QuizPrizeDetailsScreen({super.key, this.isModal = false});

  final bool isModal;

  @override
  State<QuizPrizeDetailsScreen> createState() => _QuizPrizeDetailsScreenState();
}

class _QuizPrizeDetailsScreenState extends State<QuizPrizeDetailsScreen> {
  final QuizPrizeDetailsService _service = QuizPrizeDetailsService();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  QuizPrizeDetailsData? _details;
  bool _loading = true;
  bool _saving = false;
  bool _consentAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_load());
      }
    });
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final details = await _service.buildDefault(context.currentLanguage);
      if (!mounted) {
        return;
      }
      setState(() {
        _details = details;
        _whatsappController.text = details.whatsappNumber;
        _bankNameController.text = details.bankAccountName;
        _bankAccountController.text = details.bankAccountNumber;
        _ifscController.text = details.bankIfscCode;
        _consentAccepted = details.consentAccepted;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _copy({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
    String? assamese,
    String? konkani,
    String? gujarati,
    String? marathi,
    String? meitei,
    String? mizo,
    String? odia,
    String? punjabi,
    String? nepali,
    String? bengali,
    String? kashmiri,
    String? ladakhi,
  }) {
    final translated = _quizPrizeTranslations[english];
    if (translated != null &&
        hindi == null &&
        tamil == null &&
        kannada == null &&
        malayalam == null &&
        assamese == null &&
        konkani == null &&
        gujarati == null &&
        marathi == null &&
        meitei == null &&
        mizo == null &&
        odia == null &&
        punjabi == null &&
        nepali == null &&
        bengali == null &&
        kashmiri == null &&
        ladakhi == null) {
      return context.strings.localized(
        telugu: translated.telugu,
        english: translated.english,
        hindi: translated.hindi,
        tamil: translated.tamil,
        kannada: translated.kannada,
        malayalam: translated.malayalam,
        assamese: translated.assamese,
        konkani: translated.konkani,
        gujarati: translated.gujarati,
        marathi: translated.marathi,
        meitei: translated.meitei,
        mizo: translated.mizo,
        odia: translated.odia,
        punjabi: translated.punjabi,
        nepali: translated.nepali,
        bengali: translated.bengali,
        kashmiri: translated.kashmiri,
        ladakhi: translated.ladakhi,
      );
    }
    return context.strings.localized(
      telugu: telugu,
      english: english,
      hindi: hindi,
      tamil: tamil,
      kannada: kannada,
      malayalam: malayalam,
      assamese: assamese,
      konkani: konkani,
      gujarati: gujarati,
      marathi: marathi,
      meitei: meitei,
      mizo: mizo,
      odia: odia,
      punjabi: punjabi,
      nepali: nepali,
      bengali: bengali,
      kashmiri: kashmiri,
      ladakhi: ladakhi,
    );
  }

  Future<void> _save() async {
    final whatsapp = _whatsappController.text.trim();
    final bankName = _bankNameController.text.trim();
    final bankAccount = _bankAccountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final digits = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              telugu: 'సరైన WhatsApp నంబర్ ఇవ్వండి.',
              english: 'Enter a valid WhatsApp number.',
            ),
          ),
        ),
      );
      return;
    }
    if (bankName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              telugu: 'Banking name ఇవ్వండి.',
              english: 'Enter the banking name.',
            ),
          ),
        ),
      );
      return;
    }
    if (bankAccount.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              telugu: 'Banking name ఇవ్వండి.',
              english: 'Enter the bank account number.',
            ),
          ),
        ),
      );
      return;
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              telugu: 'Valid IFSC code ivvandi.',
              english: 'Enter a valid IFSC code.',
            ),
          ),
        ),
      );
      return;
    }
    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              telugu: 'Prize verification కోసం consent ఇవ్వాలి.',
              english: 'Consent is required for prize verification.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.save(
        whatsappNumber: whatsapp,
        bankAccountName: bankName,
        bankAccountNumber: bankAccount,
        bankIfscCode: ifsc,
        language: context.currentLanguage,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              telugu: 'Prize details save అయ్యాయి.',
              english: 'Prize details saved.',
            ),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openQuizRules() async {
    final uri = Uri.parse('${AppPublicInfo.websiteUrl}/#daily-quiz');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              telugu: 'Rules link open కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
              english: 'Could not open the rules link. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _loading
        ? const Center(child: CircularProgressIndicator())
        : _PrizeDetailsContent(
            details: _details,
            whatsappController: _whatsappController,
            bankNameController: _bankNameController,
            bankAccountController: _bankAccountController,
            ifscController: _ifscController,
            consentAccepted: _consentAccepted,
            saving: _saving,
            copy: _copy,
            onOpenRules: _openQuizRules,
            onConsentChanged: (value) {
              setState(() => _consentAccepted = value ?? false);
            },
            onSave: _save,
            onLater: () => Navigator.of(context).pop(false),
          );

    if (!widget.isModal) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_copy(telugu: 'Prize Details', english: 'Prize Details')),
        ),
        body: SafeArea(child: child),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: child is _PrizeDetailsContent
              ? child.copyWith(scrollController: scrollController)
              : child,
        );
      },
    );
  }
}

class _PrizeDetailsContent extends StatelessWidget {
  const _PrizeDetailsContent({
    required this.details,
    required this.whatsappController,
    required this.bankNameController,
    required this.bankAccountController,
    required this.ifscController,
    required this.consentAccepted,
    required this.saving,
    required this.copy,
    required this.onOpenRules,
    required this.onConsentChanged,
    required this.onSave,
    required this.onLater,
    this.scrollController,
  });

  final QuizPrizeDetailsData? details;
  final TextEditingController whatsappController;
  final TextEditingController bankNameController;
  final TextEditingController bankAccountController;
  final TextEditingController ifscController;
  final bool consentAccepted;
  final bool saving;
  final String Function({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
    String? assamese,
    String? konkani,
    String? gujarati,
    String? marathi,
    String? meitei,
    String? mizo,
    String? odia,
    String? punjabi,
    String? nepali,
    String? bengali,
    String? kashmiri,
    String? ladakhi,
  })
  copy;
  final VoidCallback onOpenRules;
  final ValueChanged<bool?> onConsentChanged;
  final VoidCallback onSave;
  final VoidCallback onLater;
  final ScrollController? scrollController;

  _PrizeDetailsContent copyWith({ScrollController? scrollController}) {
    return _PrizeDetailsContent(
      details: details,
      whatsappController: whatsappController,
      bankNameController: bankNameController,
      bankAccountController: bankAccountController,
      ifscController: ifscController,
      consentAccepted: consentAccepted,
      saving: saving,
      copy: copy,
      onOpenRules: onOpenRules,
      onConsentChanged: onConsentChanged,
      onSave: onSave,
      onLater: onLater,
      scrollController: scrollController ?? this.scrollController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = details;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          copy(telugu: 'Quiz Prize Details', english: 'Quiz Prize Details'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          copy(
            telugu:
                'Winners verification మరియు prize payout కోసం మాత్రమే ఈ వివరాలు తీసుకుంటాం.',
            english:
                'These details are used only for winner verification and prize payout.',
          ),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE0F2FE),
                backgroundImage: data?.photoUrl.trim().isNotEmpty == true
                    ? NetworkImage(data!.photoUrl.trim())
                    : null,
                child: data?.photoUrl.trim().isNotEmpty == true
                    ? null
                    : const Icon(Icons.person_rounded, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data?.name.trim().isNotEmpty == true
                          ? data!.name.trim()
                          : copy(telugu: 'User', english: 'User'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data?.email.trim().isNotEmpty == true
                          ? data!.email.trim()
                          : copy(
                              telugu: 'Email not available',
                              english: 'Email not available',
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data?.stateName.trim().isNotEmpty == true
                          ? data!.stateName.trim()
                          : copy(
                              telugu: 'State not selected',
                              english: 'State not selected',
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: whatsappController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: copy(
              telugu: 'WhatsApp Number',
              english: 'WhatsApp Number',
            ),
            prefixIcon: const Icon(Icons.call_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: bankNameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: copy(
              telugu: 'Account Holder Name',
              english: 'Account Holder Name',
            ),
            prefixIcon: const Icon(Icons.badge_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: bankAccountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: copy(
              telugu: 'Bank Account Number',
              english: 'Bank Account Number',
            ),
            prefixIcon: const Icon(Icons.account_balance_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: ifscController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: copy(telugu: 'IFSC Code', english: 'IFSC Code'),
            prefixIcon: const Icon(Icons.confirmation_number_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: saving ? null : onOpenRules,
          icon: const Icon(Icons.policy_rounded),
          label: Text(
            copy(
              telugu: 'Quiz prize rules చదవండి',
              english: 'Read quiz prize rules',
            ),
          ),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          value: consentAccepted,
          onChanged: saving ? null : onConsentChanged,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            copy(
              telugu:
                  'నేను ఇచ్చిన వివరాలను quiz winner verification మరియు prize payout కోసం మాత్రమే ఉపయోగించడానికి అంగీకరిస్తున్నాను.',
              english:
                  'I agree that these details can be used only for quiz winner verification and prize payout.',
            ),
            style: const TextStyle(fontSize: 12.8, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    copy(telugu: 'Save Details', english: 'Save Details'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        TextButton(
          onPressed: saving ? null : onLater,
          child: Text(copy(telugu: 'Later', english: 'Later')),
        ),
      ],
    );
  }
}

class _PrizeTranslation {
  const _PrizeTranslation({
    required this.telugu,
    required this.english,
    required this.hindi,
    required this.tamil,
    required this.kannada,
    required this.malayalam,
    required this.assamese,
    required this.konkani,
    required this.gujarati,
    required this.marathi,
    required this.meitei,
    required this.mizo,
    required this.odia,
    required this.punjabi,
    required this.nepali,
    required this.bengali,
    required this.kashmiri,
    required this.ladakhi,
  });

  final String telugu;
  final String english;
  final String hindi;
  final String tamil;
  final String kannada;
  final String malayalam;
  final String assamese;
  final String konkani;
  final String gujarati;
  final String marathi;
  final String meitei;
  final String mizo;
  final String odia;
  final String punjabi;
  final String nepali;
  final String bengali;
  final String kashmiri;
  final String ladakhi;
}

const Map<String, _PrizeTranslation> _quizPrizeTranslations = {
  'Quiz Prize Details': _PrizeTranslation(
    telugu: 'క్విజ్ బహుమతి వివరాలు',
    english: 'Quiz Prize Details',
    hindi: 'क्विज पुरस्कार विवरण',
    tamil: 'வினாடி வினா பரிசு விவரங்கள்',
    kannada: 'ಕ್ವಿಜ್ ಬಹುಮಾನ ವಿವರಗಳು',
    malayalam: 'ക്വിസ് സമ്മാന വിവരങ്ങൾ',
    assamese: 'কুইজ পুৰস্কাৰৰ বিৱৰণ',
    konkani: 'क्विझ इनाम तपशील',
    gujarati: 'ક્વિઝ ઇનામ વિગતો',
    marathi: 'क्विझ बक्षीस तपशील',
    meitei: 'কুইজ মনা মপুং ফানা',
    mizo: 'Quiz lawmman kimchang',
    odia: 'କ୍ୱିଜ୍ ପୁରସ୍କାର ବିବରଣୀ',
    punjabi: 'ਕੁਇਜ਼ ਇਨਾਮ ਵੇਰਵੇ',
    nepali: 'क्विज पुरस्कार विवरण',
    bengali: 'কুইজ পুরস্কারের বিবরণ',
    kashmiri: 'کوئز انعام تفصیل',
    ladakhi: 'Quiz prize details',
  ),
  'These details are used only for winner verification and prize payout.': _PrizeTranslation(
    telugu:
        'ఈ వివరాలు విజేత ధృవీకరణ మరియు బహుమతి చెల్లింపు కోసం మాత్రమే ఉపయోగిస్తాం.',
    english:
        'These details are used only for winner verification and prize payout.',
    hindi:
        'इन विवरणों का उपयोग केवल विजेता सत्यापन और पुरस्कार भुगतान के लिए किया जाएगा।',
    tamil:
        'இந்த விவரங்கள் வெற்றியாளர் சரிபார்ப்பு மற்றும் பரிசு பணம் வழங்குவதற்காக மட்டுமே பயன்படுத்தப்படும்.',
    kannada:
        'ಈ ವಿವರಗಳನ್ನು ವಿಜೇತರ ಪರಿಶೀಲನೆ ಮತ್ತು ಬಹುಮಾನ ಪಾವತಿಗಾಗಿ ಮಾತ್ರ ಬಳಸಲಾಗುತ್ತದೆ.',
    malayalam:
        'ഈ വിവരങ്ങൾ വിജയി സ്ഥിരീകരണത്തിനും സമ്മാന തുക നൽകുന്നതിനുമാത്രം ഉപയോഗിക്കും.',
    assamese:
        'এই বিৱৰণসমূহ কেৱল বিজয়ী যাচাই আৰু পুৰস্কাৰ পৰিশোধৰ বাবে ব্যৱহাৰ কৰা হ’ব।',
    konkani: 'ही माहिती फकत जिंकपी तपासणी आनी इनाम दिवपा खातीर वापरतात.',
    gujarati: 'આ વિગતો ફક્ત વિજેતા ચકાસણી અને ઇનામ ચૂકવણી માટે જ વપરાશે.',
    marathi: 'ही माहिती फक्त विजेता पडताळणी आणि बक्षीस देयकासाठी वापरली जाईल.',
    meitei:
        'মসিগী অচুম্বা মশিংশিং অসি মনা ফংবগী অচুম্বা খঙদোকপা অমসুং মনা পীবগীদমকখক্তা শিজিন্নগনি.',
    mizo:
        'Heng kimchangte hi winner finfiahna leh lawmman pekna tan chauh hman a ni ang.',
    odia: 'ଏହି ବିବରଣୀ କେବଳ ବିଜେତା ଯାଞ୍ଚ ଏବଂ ପୁରସ୍କାର ପେମେଣ୍ଟ ପାଇଁ ବ୍ୟବହାର ହେବ।',
    punjabi: 'ਇਹ ਵੇਰਵੇ ਸਿਰਫ਼ ਵਿਜੇਤਾ ਤਸਦੀਕ ਅਤੇ ਇਨਾਮ ਭੁਗਤਾਨ ਲਈ ਵਰਤੇ ਜਾਣਗੇ।',
    nepali:
        'यी विवरणहरू विजेता प्रमाणीकरण र पुरस्कार भुक्तानीका लागि मात्र प्रयोग गरिनेछन्।',
    bengali:
        'এই তথ্যগুলি শুধুমাত্র বিজয়ী যাচাই এবং পুরস্কার প্রদানের জন্য ব্যবহার করা হবে।',
    kashmiri:
        'یہ تفصیلات صرف فاتح کی تصدیق اور انعام کی ادائیگی کے لیے استعمال ہوں گی۔',
    ladakhi:
        'These details are used only for winner verification and prize payout.',
  ),
  'Enter a valid WhatsApp number.': _PrizeTranslation(
    telugu: 'సరైన WhatsApp నంబర్ ఇవ్వండి.',
    english: 'Enter a valid WhatsApp number.',
    hindi: 'सही WhatsApp नंबर दर्ज करें।',
    tamil: 'சரியான WhatsApp எண்ணை உள்ளிடவும்.',
    kannada: 'ಸರಿಯಾದ WhatsApp ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ.',
    malayalam: 'ശരിയായ WhatsApp നമ്പർ നൽകുക.',
    assamese: 'সঠিক WhatsApp নম্বৰ দিয়ক।',
    konkani: 'बरोबर WhatsApp नंबर दिवचो.',
    gujarati: 'સાચો WhatsApp નંબર દાખલ કરો.',
    marathi: 'योग्य WhatsApp नंबर टाका.',
    meitei: 'অচুম্বা WhatsApp নম্বর পীয়ু.',
    mizo: 'WhatsApp number dik tak dah rawh.',
    odia: 'ଠିକ୍ WhatsApp ନମ୍ବର ଦିଅନ୍ତୁ।',
    punjabi: 'ਸਹੀ WhatsApp ਨੰਬਰ ਦਿਓ।',
    nepali: 'सही WhatsApp नम्बर दिनुहोस्।',
    bengali: 'সঠিক WhatsApp নম্বর দিন।',
    kashmiri: 'صحیح WhatsApp نمبر درج کریں۔',
    ladakhi: 'Enter a valid WhatsApp number.',
  ),
  'Enter the banking name.': _PrizeTranslation(
    telugu: 'బ్యాంక్ అకౌంట్ పేరు ఇవ్వండి.',
    english: 'Enter the banking name.',
    hindi: 'बैंक खाते का नाम दर्ज करें।',
    tamil: 'வங்கி கணக்கு பெயரை உள்ளிடவும்.',
    kannada: 'ಬ್ಯಾಂಕ್ ಖಾತೆಯ ಹೆಸರನ್ನು ನಮೂದಿಸಿ.',
    malayalam: 'ബാങ്ക് അക്കൗണ്ട് പേര് നൽകുക.',
    assamese: 'বেংক একাউণ্টৰ নাম দিয়ক।',
    konkani: 'बँक खात्याचें नांव दिवचें.',
    gujarati: 'બેંક ખાતાનું નામ દાખલ કરો.',
    marathi: 'बँक खात्याचे नाव टाका.',
    meitei: 'ব্যাংক একাউন্টকী মমিং পীয়ু.',
    mizo: 'Bank account hming dah rawh.',
    odia: 'ବ୍ୟାଙ୍କ ଖାତା ନାମ ଦିଅନ୍ତୁ।',
    punjabi: 'ਬੈਂਕ ਖਾਤੇ ਦਾ ਨਾਮ ਦਿਓ।',
    nepali: 'बैंक खाताको नाम दिनुहोस्।',
    bengali: 'ব্যাংক অ্যাকাউন্টের নাম দিন।',
    kashmiri: 'بینک اکاؤنٹ کا نام درج کریں۔',
    ladakhi: 'Enter the banking name.',
  ),
  'Enter the bank account number.': _PrizeTranslation(
    telugu: 'బ్యాంక్ అకౌంట్ నంబర్ ఇవ్వండి.',
    english: 'Enter the bank account number.',
    hindi: 'बैंक खाता नंबर दर्ज करें।',
    tamil: 'வங்கி கணக்கு எண்ணை உள்ளிடவும்.',
    kannada: 'ಬ್ಯಾಂಕ್ ಖಾತೆ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ.',
    malayalam: 'ബാങ്ക് അക്കൗണ്ട് നമ്പർ നൽകുക.',
    assamese: 'বেংক একাউণ্ট নম্বৰ দিয়ক।',
    konkani: 'बँक खात्याचो नंबर दिवचो.',
    gujarati: 'બેંક એકાઉન્ટ નંબર દાખલ કરો.',
    marathi: 'बँक खाते क्रमांक टाका.',
    meitei: 'ব্যাংক একাউন্ট নম্বর পীয়ু.',
    mizo: 'Bank account number dah rawh.',
    odia: 'ବ୍ୟାଙ୍କ ଖାତା ନମ୍ବର ଦିଅନ୍ତୁ।',
    punjabi: 'ਬੈਂਕ ਖਾਤਾ ਨੰਬਰ ਦਿਓ।',
    nepali: 'बैंक खाता नम्बर दिनुहोस्।',
    bengali: 'ব্যাংক অ্যাকাউন্ট নম্বর দিন।',
    kashmiri: 'بینک اکاؤنٹ نمبر درج کریں۔',
    ladakhi: 'Enter the bank account number.',
  ),
  'Enter a valid IFSC code.': _PrizeTranslation(
    telugu: 'సరైన IFSC కోడ్ ఇవ్వండి.',
    english: 'Enter a valid IFSC code.',
    hindi: 'सही IFSC कोड दर्ज करें।',
    tamil: 'சரியான IFSC குறியீட்டை உள்ளிடவும்.',
    kannada: 'ಸರಿಯಾದ IFSC ಕೋಡ್ ನಮೂದಿಸಿ.',
    malayalam: 'ശരിയായ IFSC കോഡ് നൽകുക.',
    assamese: 'সঠিক IFSC কোড দিয়ক।',
    konkani: 'बरोबर IFSC कोड दिवचो.',
    gujarati: 'સાચો IFSC કોડ દાખલ કરો.',
    marathi: 'योग्य IFSC कोड टाका.',
    meitei: 'অচুম্বা IFSC কোড পীয়ু.',
    mizo: 'IFSC code dik tak dah rawh.',
    odia: 'ଠିକ୍ IFSC କୋଡ୍ ଦିଅନ୍ତୁ।',
    punjabi: 'ਸਹੀ IFSC ਕੋਡ ਦਿਓ।',
    nepali: 'सही IFSC कोड दिनुहोस्।',
    bengali: 'সঠিক IFSC কোড দিন।',
    kashmiri: 'صحیح IFSC کوڈ درج کریں۔',
    ladakhi: 'Enter a valid IFSC code.',
  ),
  'Consent is required for prize verification.': _PrizeTranslation(
    telugu: 'బహుమతి ధృవీకరణ కోసం మీ సమ్మతి అవసరం.',
    english: 'Consent is required for prize verification.',
    hindi: 'पुरस्कार सत्यापन के लिए आपकी सहमति आवश्यक है।',
    tamil: 'பரிசு சரிபார்ப்புக்கு உங்கள் ஒப்புதல் அவசியம்.',
    kannada: 'ಬಹುಮಾನ ಪರಿಶೀಲನೆಗೆ ನಿಮ್ಮ ಒಪ್ಪಿಗೆ ಅಗತ್ಯ.',
    malayalam: 'സമ്മാന സ്ഥിരീകരണത്തിന് നിങ്ങളുടെ സമ്മതം ആവശ്യമാണ്.',
    assamese: 'পুৰস্কাৰ যাচাইৰ বাবে আপোনাৰ সন্মতি প্ৰয়োজন।',
    konkani: 'इनाम तपासपा खातीर तुमची संमती गरजेची आसा.',
    gujarati: 'ઇનામ ચકાસણી માટે તમારી સંમતિ જરૂરી છે.',
    marathi: 'बक्षीस पडताळणीसाठी तुमची संमती आवश्यक आहे.',
    meitei: 'মনা খঙদোকপগীদমক নঙগী অয়াবা দরকার ওই.',
    mizo: 'Lawmman finfiahna tan phalna a ngai.',
    odia: 'ପୁରସ୍କାର ଯାଞ୍ଚ ପାଇଁ ଆପଣଙ୍କ ସମ୍ମତି ଆବଶ୍ୟକ।',
    punjabi: 'ਇਨਾਮ ਤਸਦੀਕ ਲਈ ਤੁਹਾਡੀ ਸਹਿਮਤੀ ਲਾਜ਼ਮੀ ਹੈ।',
    nepali: 'पुरस्कार प्रमाणीकरणका लागि तपाईंको सहमति आवश्यक छ।',
    bengali: 'পুরস্কার যাচাইয়ের জন্য আপনার সম্মতি প্রয়োজন।',
    kashmiri: 'انعام کی تصدیق کے لیے آپ کی رضامندی ضروری ہے۔',
    ladakhi: 'Consent is required for prize verification.',
  ),
  'Prize details saved.': _PrizeTranslation(
    telugu: 'బహుమతి వివరాలు సేవ్ అయ్యాయి.',
    english: 'Prize details saved.',
    hindi: 'पुरस्कार विवरण सेव हो गए।',
    tamil: 'பரிசு விவரங்கள் சேமிக்கப்பட்டன.',
    kannada: 'ಬಹುಮಾನ ವಿವರಗಳು ಉಳಿಸಲಾಗಿದೆ.',
    malayalam: 'സമ്മാന വിവരങ്ങൾ സേവ് ചെയ്തു.',
    assamese: 'পুৰস্কাৰৰ বিৱৰণ সাঁচি থোৱা হ’ল।',
    konkani: 'इनाम तपशील सेव जाले.',
    gujarati: 'ઇનામ વિગતો સેવ થઈ.',
    marathi: 'बक्षीस तपशील सेव झाले.',
    meitei: 'মনা মপুং ফানা সেভ তৌরে.',
    mizo: 'Lawmman kimchang dahthat a ni.',
    odia: 'ପୁରସ୍କାର ବିବରଣୀ ସେଭ୍ ହୋଇଛି।',
    punjabi: 'ਇਨਾਮ ਵੇਰਵੇ ਸੇਵ ਹੋ ਗਏ।',
    nepali: 'पुरस्कार विवरण सेभ भयो।',
    bengali: 'পুরস্কারের বিবরণ সেভ হয়েছে।',
    kashmiri: 'انعام کی تفصیلات محفوظ ہو گئیں۔',
    ladakhi: 'Prize details saved.',
  ),
  'Could not open the rules link. Please try again.': _PrizeTranslation(
    telugu: 'Rules link open కాలేదు. మళ్లీ ప్రయత్నించండి.',
    english: 'Could not open the rules link. Please try again.',
    hindi: 'नियम लिंक नहीं खुला। कृपया फिर कोशिश करें।',
    tamil: 'விதிகள் இணைப்பு திறக்கவில்லை. மீண்டும் முயற்சிக்கவும்.',
    kannada: 'ನಿಯಮಗಳ ಲಿಂಕ್ ತೆರೆಯಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'നിയമങ്ങളുടെ ലിങ്ക് തുറക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
    assamese: 'নিয়মৰ লিংক খুলিব পৰা নগ’ল। পুনৰ চেষ্টা কৰক।',
    konkani: 'नियमांची लिंक उगडूंक शकली ना. परत प्रयत्न करात.',
    gujarati: 'નિયમોની લિંક ખુલતી નથી. ફરી પ્રયત્ન કરો.',
    marathi: 'नियमांची लिंक उघडली नाही. पुन्हा प्रयत्न करा.',
    meitei: 'নিয়মগী লিঙ্ক হাংদোকপা ঙমদে. অমুক হন্না হোৎনবিয়ু.',
    mizo: 'Rules link hawn theih a ni lo. Han tum leh rawh.',
    odia: 'ନିୟମ ଲିଙ୍କ୍ ଖୋଲିଲା ନାହିଁ। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
    punjabi: 'ਨਿਯਮਾਂ ਦਾ ਲਿੰਕ ਨਹੀਂ ਖੁੱਲਿਆ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    nepali: 'नियम लिंक खुल्न सकेन। फेरि प्रयास गर्नुहोस्।',
    bengali: 'নিয়মের লিংক খোলা যায়নি। আবার চেষ্টা করুন।',
    kashmiri: 'قواعد کا لنک نہیں کھل سکا۔ دوبارہ کوشش کریں۔',
    ladakhi: 'Could not open the rules link. Please try again.',
  ),
  'User': _PrizeTranslation(
    telugu: 'యూజర్',
    english: 'User',
    hindi: 'यूज़र',
    tamil: 'பயனர்',
    kannada: 'ಬಳಕೆದಾರ',
    malayalam: 'ഉപയോക്താവ്',
    assamese: 'ব্যৱহাৰকাৰী',
    konkani: 'वापरपी',
    gujarati: 'વપરાશકર્તા',
    marathi: 'वापरकर्ता',
    meitei: 'শিজিন্নরিবা',
    mizo: 'User',
    odia: 'ବ୍ୟବହାରକାରୀ',
    punjabi: 'ਯੂਜ਼ਰ',
    nepali: 'प्रयोगकर्ता',
    bengali: 'ব্যবহারকারী',
    kashmiri: 'صارف',
    ladakhi: 'User',
  ),
  'Email not available': _PrizeTranslation(
    telugu: 'Email లేదు',
    english: 'Email not available',
    hindi: 'ईमेल उपलब्ध नहीं है',
    tamil: 'மின்னஞ்சல் இல்லை',
    kannada: 'ಇಮೇಲ್ ಲಭ್ಯವಿಲ್ಲ',
    malayalam: 'ഇമെയിൽ ലഭ്യമല്ല',
    assamese: 'ইমেইল উপলব্ধ নহয়',
    konkani: 'ईमेल उपलब्ध ना',
    gujarati: 'ઇમેઇલ ઉપલબ્ધ નથી',
    marathi: 'ईमेल उपलब्ध नाही',
    meitei: 'ইমেল লৈতে',
    mizo: 'Email a awm lo',
    odia: 'ଇମେଲ୍ ଉପଲବ୍ଧ ନାହିଁ',
    punjabi: 'ਈਮੇਲ ਉਪਲਬਧ ਨਹੀਂ',
    nepali: 'इमेल उपलब्ध छैन',
    bengali: 'ইমেইল নেই',
    kashmiri: 'ای میل دستیاب نہیں',
    ladakhi: 'Email not available',
  ),
  'State not selected': _PrizeTranslation(
    telugu: 'రాష్ట్రం ఎంచుకోలేదు',
    english: 'State not selected',
    hindi: 'राज्य चुना नहीं गया',
    tamil: 'மாநிலம் தேர்ந்தெடுக்கப்படவில்லை',
    kannada: 'ರಾಜ್ಯ ಆಯ್ಕೆ ಮಾಡಿಲ್ಲ',
    malayalam: 'സംസ്ഥാനം തിരഞ്ഞെടുത്തിട്ടില്ല',
    assamese: 'ৰাজ্য বাছনি কৰা হোৱা নাই',
    konkani: 'राज्य निवडूंक ना',
    gujarati: 'રાજ્ય પસંદ નથી કર્યું',
    marathi: 'राज्य निवडलेले नाही',
    meitei: 'স্টেট খনদোক্তে',
    mizo: 'State thlan a ni lo',
    odia: 'ରାଜ୍ୟ ଚୟନ ହୋଇନାହିଁ',
    punjabi: 'ਰਾਜ ਚੁਣਿਆ ਨਹੀਂ',
    nepali: 'राज्य चयन गरिएको छैन',
    bengali: 'রাজ্য নির্বাচন করা হয়নি',
    kashmiri: 'ریاست منتخب نہیں',
    ladakhi: 'State not selected',
  ),
  'WhatsApp Number': _PrizeTranslation(
    telugu: 'WhatsApp నంబర్',
    english: 'WhatsApp Number',
    hindi: 'WhatsApp नंबर',
    tamil: 'WhatsApp எண்',
    kannada: 'WhatsApp ಸಂಖ್ಯೆ',
    malayalam: 'WhatsApp നമ്പർ',
    assamese: 'WhatsApp নম্বৰ',
    konkani: 'WhatsApp नंबर',
    gujarati: 'WhatsApp નંબર',
    marathi: 'WhatsApp नंबर',
    meitei: 'WhatsApp নম্বর',
    mizo: 'WhatsApp number',
    odia: 'WhatsApp ନମ୍ବର',
    punjabi: 'WhatsApp ਨੰਬਰ',
    nepali: 'WhatsApp नम्बर',
    bengali: 'WhatsApp নম্বর',
    kashmiri: 'WhatsApp نمبر',
    ladakhi: 'WhatsApp Number',
  ),
  'Account Holder Name': _PrizeTranslation(
    telugu: 'అకౌంట్ హోల్డర్ పేరు',
    english: 'Account Holder Name',
    hindi: 'खाता धारक का नाम',
    tamil: 'கணக்கு வைத்திருப்பவர் பெயர்',
    kannada: 'ಖಾತೆದಾರರ ಹೆಸರು',
    malayalam: 'അക്കൗണ്ട് ഉടമയുടെ പേര്',
    assamese: 'একাউণ্টধাৰীৰ নাম',
    konkani: 'खाते धारकाचें नांव',
    gujarati: 'એકાઉન્ટ ધારકનું નામ',
    marathi: 'खातेधारकाचे नाव',
    meitei: 'একাউন্ট হোল্ডরগী মমিং',
    mizo: 'Account neitu hming',
    odia: 'ଖାତାଧାରୀଙ୍କ ନାମ',
    punjabi: 'ਖਾਤਾ ਧਾਰਕ ਦਾ ਨਾਮ',
    nepali: 'खातावालाको नाम',
    bengali: 'অ্যাকাউন্ট হোল্ডারের নাম',
    kashmiri: 'اکاؤنٹ ہولڈر کا نام',
    ladakhi: 'Account Holder Name',
  ),
  'Bank Account Number': _PrizeTranslation(
    telugu: 'బ్యాంక్ అకౌంట్ నంబర్',
    english: 'Bank Account Number',
    hindi: 'बैंक खाता नंबर',
    tamil: 'வங்கி கணக்கு எண்',
    kannada: 'ಬ್ಯಾಂಕ್ ಖಾತೆ ಸಂಖ್ಯೆ',
    malayalam: 'ബാങ്ക് അക്കൗണ്ട് നമ്പർ',
    assamese: 'বেংক একাউণ্ট নম্বৰ',
    konkani: 'बँक खाते नंबर',
    gujarati: 'બેંક એકાઉન્ટ નંબર',
    marathi: 'बँक खाते क्रमांक',
    meitei: 'ব্যাংক একাউন্ট নম্বর',
    mizo: 'Bank account number',
    odia: 'ବ୍ୟାଙ୍କ ଖାତା ନମ୍ବର',
    punjabi: 'ਬੈਂਕ ਖਾਤਾ ਨੰਬਰ',
    nepali: 'बैंक खाता नम्बर',
    bengali: 'ব্যাংক অ্যাকাউন্ট নম্বর',
    kashmiri: 'بینک اکاؤنٹ نمبر',
    ladakhi: 'Bank Account Number',
  ),
  'IFSC Code': _PrizeTranslation(
    telugu: 'IFSC కోడ్',
    english: 'IFSC Code',
    hindi: 'IFSC कोड',
    tamil: 'IFSC குறியீடு',
    kannada: 'IFSC ಕೋಡ್',
    malayalam: 'IFSC കോഡ്',
    assamese: 'IFSC কোড',
    konkani: 'IFSC कोड',
    gujarati: 'IFSC કોડ',
    marathi: 'IFSC कोड',
    meitei: 'IFSC কোড',
    mizo: 'IFSC code',
    odia: 'IFSC କୋଡ୍',
    punjabi: 'IFSC ਕੋਡ',
    nepali: 'IFSC कोड',
    bengali: 'IFSC কোড',
    kashmiri: 'IFSC کوڈ',
    ladakhi: 'IFSC Code',
  ),
  'Read quiz prize rules': _PrizeTranslation(
    telugu: 'క్విజ్ బహుమతి నియమాలు చదవండి',
    english: 'Read quiz prize rules',
    hindi: 'क्विज पुरस्कार नियम पढ़ें',
    tamil: 'வினாடி வினா பரிசு விதிகளை படிக்கவும்',
    kannada: 'ಕ್ವಿಜ್ ಬಹುಮಾನ ನಿಯಮಗಳನ್ನು ಓದಿ',
    malayalam: 'ക്വിസ് സമ്മാന നിയമങ്ങൾ വായിക്കുക',
    assamese: 'কুইজ পুৰস্কাৰ নিয়ম পঢ়ক',
    konkani: 'क्विझ इनाम नियम वाचात',
    gujarati: 'ક્વિઝ ઇનામ નિયમો વાંચો',
    marathi: 'क्विझ बक्षीस नियम वाचा',
    meitei: 'কুইজ মনা নিয়মশিং পাবিয়ু',
    mizo: 'Quiz lawmman dan chhiar rawh',
    odia: 'କ୍ୱିଜ୍ ପୁରସ୍କାର ନିୟମ ପଢନ୍ତୁ',
    punjabi: 'ਕੁਇਜ਼ ਇਨਾਮ ਨਿਯਮ ਪੜ੍ਹੋ',
    nepali: 'क्विज पुरस्कार नियम पढ्नुहोस्',
    bengali: 'কুইজ পুরস্কারের নিয়ম পড়ুন',
    kashmiri: 'کوئز انعام کے قواعد پڑھیں',
    ladakhi: 'Read quiz prize rules',
  ),
  'I agree that these details can be used only for quiz winner verification and prize payout.': _PrizeTranslation(
    telugu:
        'ఈ వివరాలను క్విజ్ విజేత ధృవీకరణ మరియు బహుమతి చెల్లింపు కోసం మాత్రమే ఉపయోగించడానికి నేను అంగీకరిస్తున్నాను.',
    english:
        'I agree that these details can be used only for quiz winner verification and prize payout.',
    hindi:
        'मैं सहमत हूं कि इन विवरणों का उपयोग केवल क्विज विजेता सत्यापन और पुरस्कार भुगतान के लिए किया जा सकता है।',
    tamil:
        'இந்த விவரங்கள் வினாடி வினா வெற்றியாளர் சரிபார்ப்பு மற்றும் பரிசு வழங்குதலுக்காக மட்டுமே பயன்படுத்தப்படலாம் என்பதை நான் ஒப்புக்கொள்கிறேன்.',
    kannada:
        'ಈ ವಿವರಗಳನ್ನು ಕ್ವಿಜ್ ವಿಜೇತರ ಪರಿಶೀಲನೆ ಮತ್ತು ಬಹುಮಾನ ಪಾವತಿಗಾಗಿ ಮಾತ್ರ ಬಳಸಬಹುದು ಎಂದು ನಾನು ಒಪ್ಪುತ್ತೇನೆ.',
    malayalam:
        'ഈ വിവരങ്ങൾ ക്വിസ് വിജയി സ്ഥിരീകരണത്തിനും സമ്മാന തുക നൽകുന്നതിനുമാത്രം ഉപയോഗിക്കാമെന്ന് ഞാൻ സമ്മതിക്കുന്നു.',
    assamese:
        'এই বিৱৰণসমূহ কেৱল কুইজ বিজয়ী যাচাই আৰু পুৰস্কাৰ পৰিশোধৰ বাবে ব্যৱহাৰ হ’ব বুলি মই সন্মত।',
    konkani:
        'ही माहिती फकत क्विझ जिंकपी तपासणी आनी इनाम दिवपा खातीर वापरूंक शकतात हाका हांव संमती दितां.',
    gujarati:
        'હું સંમત છું કે આ વિગતો ફક્ત ક્વિઝ વિજેતા ચકાસણી અને ઇનામ ચૂકવણી માટે વાપરી શકાય.',
    marathi:
        'ही माहिती फक्त क्विझ विजेता पडताळणी आणि बक्षीस देयकासाठी वापरता येईल यास मी सहमत आहे.',
    meitei:
        'মসিগী অচুম্বা মশিংশিং অসি কুইজ মনা ফংবগী অচুম্বা খঙদোকপা অমসুং মনা পীবগীদমকখক্তা শিজিন্নবা য়ারে হায়না ঐ অয়াবা পীরি.',
    mizo:
        'Heng kimchangte hi quiz winner finfiahna leh lawmman pekna tan chauh hman theih a ni tih ka pawm.',
    odia:
        'ଏହି ବିବରଣୀ କେବଳ କ୍ୱିଜ୍ ବିଜେତା ଯାଞ୍ଚ ଏବଂ ପୁରସ୍କାର ପେମେଣ୍ଟ ପାଇଁ ବ୍ୟବହାର ହେବ ବୋଲି ମୁଁ ସମ୍ମତ।',
    punjabi:
        'ਮੈਂ ਸਹਿਮਤ ਹਾਂ ਕਿ ਇਹ ਵੇਰਵੇ ਸਿਰਫ਼ ਕੁਇਜ਼ ਵਿਜੇਤਾ ਤਸਦੀਕ ਅਤੇ ਇਨਾਮ ਭੁਗਤਾਨ ਲਈ ਵਰਤੇ ਜਾ ਸਕਦੇ ਹਨ।',
    nepali:
        'यी विवरणहरू क्विज विजेता प्रमाणीकरण र पुरस्कार भुक्तानीका लागि मात्र प्रयोग गर्न सकिन्छ भन्नेमा म सहमत छु।',
    bengali:
        'আমি সম্মত যে এই তথ্যগুলি শুধুমাত্র কুইজ বিজয়ী যাচাই এবং পুরস্কার প্রদানের জন্য ব্যবহার করা যাবে।',
    kashmiri:
        'میں متفق ہوں کہ یہ تفصیلات صرف کوئز فاتح کی تصدیق اور انعام کی ادائیگی کے لیے استعمال ہو سکتی ہیں۔',
    ladakhi:
        'I agree that these details can be used only for quiz winner verification and prize payout.',
  ),
  'Save Details': _PrizeTranslation(
    telugu: 'వివరాలు సేవ్ చేయండి',
    english: 'Save Details',
    hindi: 'विवरण सेव करें',
    tamil: 'விவரங்களை சேமிக்கவும்',
    kannada: 'ವಿವರಗಳನ್ನು ಉಳಿಸಿ',
    malayalam: 'വിവരങ്ങൾ സേവ് ചെയ്യുക',
    assamese: 'বিৱৰণ সাঁচক',
    konkani: 'तपशील सेव करात',
    gujarati: 'વિગતો સેવ કરો',
    marathi: 'तपशील सेव करा',
    meitei: 'মপুং ফানা সেভ তৌ',
    mizo: 'Kimchang dahthat rawh',
    odia: 'ବିବରଣୀ ସେଭ୍ କରନ୍ତୁ',
    punjabi: 'ਵੇਰਵੇ ਸੇਵ ਕਰੋ',
    nepali: 'विवरण सेभ गर्नुहोस्',
    bengali: 'বিবরণ সেভ করুন',
    kashmiri: 'تفصیلات محفوظ کریں',
    ladakhi: 'Save Details',
  ),
  'Later': _PrizeTranslation(
    telugu: 'తర్వాత',
    english: 'Later',
    hindi: 'बाद में',
    tamil: 'பிறகு',
    kannada: 'ನಂತರ',
    malayalam: 'പിന്നീട്',
    assamese: 'পিছত',
    konkani: 'मागीर',
    gujarati: 'પછી',
    marathi: 'नंतर',
    meitei: 'তুংদা',
    mizo: 'A hnuaiah',
    odia: 'ପରେ',
    punjabi: 'ਬਾਅਦ ਵਿੱਚ',
    nepali: 'पछि',
    bengali: 'পরে',
    kashmiri: 'بعد میں',
    ladakhi: 'Later',
  ),
};
