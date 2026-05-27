import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

class ReligionSelectionScreen extends StatefulWidget {
  const ReligionSelectionScreen({
    super.key,
    this.returnToPreviousOnSave = false,
  });

  final bool returnToPreviousOnSave;

  @override
  State<ReligionSelectionScreen> createState() =>
      _ReligionSelectionScreenState();
}

class _ReligionSelectionScreenState extends State<ReligionSelectionScreen>
    with AppLanguageStateMixin {
  AppReligionPreference _selected = AppReligionPreference.all;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialSelection());
  }

  Future<void> _loadInitialSelection() async {
    final selection = await AppReligionService.loadSelection();
    if (!mounted || selection == null) {
      return;
    }
    setState(() => _selected = selection);
  }

  Future<void> _continue() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await AppReligionService.persistSelection(_selected);
      if (!mounted) {
        return;
      }
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.localized(
                telugu: 'ఎంపిక సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
                english: 'Could not save your selection. Please try again.',
                hindi: 'चयन सेव नहीं हो सका। कृपया फिर से कोशिश करें।',
                tamil: 'தேர்வை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
                kannada: 'ಆಯ್ಕೆಯನ್ನು ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
                malayalam:
                    'തിരഞ്ഞെടുപ്പ് സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
              ),
            ),
          ),
        );
        return;
      }

      if (widget.returnToPreviousOnSave) {
        Navigator.of(context).pop(true);
        return;
      }

      await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
      final nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute(
        includeReligionGate: false,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(nextRoute);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'ఎంపిక సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
              english: 'Could not save your selection. Please try again.',
              hindi: 'चयन सेव नहीं हो सका। कृपया फिर से कोशिश करें।',
              tamil: 'தேர்வை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada: 'ಆಯ್ಕೆಯನ್ನು ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'തിരഞ്ഞെടുപ്പ് സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = context.strings;
    final options = <_ReligionOptionData>[
      _ReligionOptionData(
        preference: AppReligionPreference.hindu,
        title: strings.localized(
          telugu: 'హిందూ',
          english: 'Hindu',
          hindi: 'हिंदू',
          tamil: 'இந்து',
          kannada: 'ಹಿಂದು',
          malayalam: 'ഹിന്ദു',
        ),
        color: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF7ED),
      ),
      _ReligionOptionData(
        preference: AppReligionPreference.muslim,
        title: strings.localized(
          telugu: 'ముస్లిం',
          english: 'Muslim',
          hindi: 'मुस्लिम',
          tamil: 'முஸ்லிம்',
          kannada: 'ಮುಸ್ಲಿಂ',
          malayalam: 'മുസ്ലിം',
        ),
        color: const Color(0xFF10B981),
        background: const Color(0xFFECFDF5),
      ),
      _ReligionOptionData(
        preference: AppReligionPreference.christian,
        title: strings.localized(
          telugu: 'క్రిస్టియన్',
          english: 'Christian',
          hindi: 'क्रिश्चियन',
          tamil: 'கிறிஸ்துவர்',
          kannada: 'ಕ್ರಿಶ್ಚಿಯನ್',
          malayalam: 'ക്രിസ്ത്യൻ',
        ),
        color: const Color(0xFF3B82F6),
        background: const Color(0xFFEFF6FF),
      ),
      _ReligionOptionData(
        preference: AppReligionPreference.all,
        title: strings.localized(
          telugu: 'అన్ని',
          english: 'All',
          hindi: 'सभी',
          tamil: 'அனைத்தும்',
          kannada: 'ಎಲ್ಲಾ',
          malayalam: 'എല്ലാം',
        ),
        color: const Color(0xFF8B5CF6),
        background: const Color(0xFFF5F3FF),
      ),
    ];

    return Scaffold(
      body: GradientShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                    Color(0xFF10B981),
                                    Color(0xFF3B82F6),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              strings.localized(
                                telugu: 'మీ మతాన్ని ఎంచుకోండి',
                                english: 'Select your religion',
                                hindi: 'अपना धर्म चुनें',
                                tamil: 'உங்கள் மதத்தை தேர்வு செய்யவும்',
                                kannada: 'ನಿಮ್ಮ ಧರ್ಮವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
                                malayalam: 'നിങ്ങളുടെ മതം തിരഞ്ഞെടുക്കുക',
                              ),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.localized(
                                telugu:
                                    'మీరు ఎంచుకున్న దానికి సరిపోయే కేటగిరీలు మాత్రమే హోమ్‌లో కనిపిస్తాయి.',
                                english:
                                    'Home will show the categories that match your selection.',
                                hindi:
                                    'होम में आपकी पसंद के अनुसार कैटेगरी दिखाई जाएंगी।',
                                tamil:
                                    'நீங்கள் தேர்வு செய்ததற்கேற்ற வகைகள் மட்டும் ஹோமில் காணப்படும்.',
                                kannada:
                                    'ನೀವು ಆಯ್ಕೆ ಮಾಡಿದಕ್ಕೆ ಹೊಂದುವ ವರ್ಗಗಳು ಮಾತ್ರ ಹೋಮ್‌ನಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.',
                                malayalam:
                                    'നിങ്ങളുടെ തിരഞ്ഞെടുപ്പിന് അനുയോജ്യമായ വിഭാഗങ്ങൾ മാത്രം ഹോമിൽ കാണിക്കും.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ...options.map((item) {
                              final selected = item.preference == _selected;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _selected = item.preference,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Ink(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? item.background
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected
                                            ? item.color
                                            : const Color(0xFFE2E8F0),
                                        width: selected ? 1.4 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: item.background,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            item.title.substring(0, 1),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: item.color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                    .radio_button_unchecked_rounded,
                                          color: selected
                                              ? item.color
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            PrimaryButton(
                              label: strings.continueLabel,
                              loading: _saving,
                              onPressed: _saving ? null : _continue,
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
    );
  }
}

class _ReligionOptionData {
  const _ReligionOptionData({
    required this.preference,
    required this.title,
    required this.color,
    required this.background,
  });

  final AppReligionPreference preference;
  final String title;
  final Color color;
  final Color background;
}
