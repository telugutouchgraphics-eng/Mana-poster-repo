import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key, this.onboardingMode = false});

  final bool onboardingMode;

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen>
    with AppLanguageStateMixin {
  late AppLanguage _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected = context.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final currentLanguage = context.currentLanguage;
    final languages = AppLanguage.values;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.onboardingMode,
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          strings.languageSettingsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: <Widget>[
                    Text(
                      '${strings.currentLanguageLabel}: ${strings.languageName(currentLanguage)}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...languages.map((language) {
                      final selected = _selected == language;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setState(() => _selected = language),
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE8F0FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    strings.languageName(language),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF1E3A8A),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final saved = await AppFlowService.persistLanguageSelection(
                    _selected,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  if (!saved) {
                    ScaffoldMessenger.of(context).showTopSnackBar(
                      AppSnackBar.build(
                        content: Text(
                          strings.localized(
                            telugu: 'భాష సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
                            english:
                                'Could not save language. Please try again.',
                            hindi: 'भाषा सहेजी नहीं जा सकी। कृपया पुनः प्रयास करें।',
                            tamil: 'மொழியைச் சேமிக்க முடியவில்லை. மீண்டும் முயல்க.',
                            kannada: 'ಭಾಷೆಯನ್ನು ಉಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                            malayalam: 'ഭാഷ സംരക്ഷിക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കുക.',
                            marathi: 'भाषा जतन करता आली नाही. कृपया पुन्हा प्रयत्न करा.',
                            gujarati: 'ભાષા સાચવી શકાઈ નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
                            bengali: 'ভাষা সংরক্ষণ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
                            punjabi: 'ਭਾਸ਼ਾ ਸੁਰੱਖਿਅਤ ਨਹੀਂ ਹੋ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
                            odia: 'ଭାଷା ସଂରକ୍ଷଣ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
                            assamese: 'ভাষা সংৰক্ষণ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
                            konkani: 'भास सांबाळपाक जमली ना. उपकार करून परत प्रयत्न करात.',
                            nepali: 'भाषा सुरक्षित गर्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
                            meitei: 'Lon save touba ngamkhide. Chanbiduna amuk hanna hotnabiyu.',
                            mizo: 'Ṭawng save thei lo. Khawngaihin ti nawn leh rawh.',
                            kashmiri: 'زبٲن ہیکہِ نہٕ محفوٗظ کٔرِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
                            ladakhi: 'སྐད་རིགས་ཉར་ཚགས་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  context.languageController.setLanguage(_selected);
                  if (widget.onboardingMode) {
                    final nextRoute =
                        await AppFlowService.resolvePostSplashEntryRoute();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      nextRoute,
                      (Route<dynamic> route) => false,
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(strings.saveApply),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
