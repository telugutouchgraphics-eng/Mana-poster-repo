import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with AppLanguageStateMixin {
  AppLanguage _selected = AppLanguage.telugu;
  bool _hasSelectedManually = false;
  bool _isContinuing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasSelectedManually) {
      _selected = context.languageController.language;
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.strings.localized(
            telugu: 'భాష సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
            english: 'Could not save language. Please try again.',
            hindi: 'भाषा सेव नहीं हो सकी। कृपया पुनः प्रयास करें।',
            tamil: 'மொழியை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
            kannada: 'ಭಾಷೆಯನ್ನು ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
            malayalam: 'ഭാഷ സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
          ),
        ),
      ),
    );
  }

  void _openLoginScreen() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  Future<void> _continueToLogin() async {
    if (_isContinuing) {
      return;
    }
    setState(() => _isContinuing = true);
    try {
      final saved = await AppFlowService.persistLanguageSelection(_selected);
      if (!mounted) {
        return;
      }
      if (!saved) {
        _showSaveError();
        return;
      }
      context.languageController.setLanguage(_selected);
      await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);
      if (!mounted) {
        return;
      }
      _openLoginScreen();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSaveError();
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = context.strings;
    final languages = AppLanguage.values;
    final mediaQuery = MediaQuery.of(context);
    final safeViewportHeight = math.max(
      0,
      mediaQuery.size.height -
          mediaQuery.padding.vertical -
          mediaQuery.viewInsets.vertical,
    );

    return Scaffold(
      body: GradientShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final constrainedViewportHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : safeViewportHeight;
              final minScrollableHeight = math
                  .max(
                    0.0,
                    math.min(constrainedViewportHeight, safeViewportHeight) -
                        48,
                  )
                  .toDouble();
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minScrollableHeight),
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
                                    Color(0xFF14B8A6),
                                    Color(0xFF38BDF8),
                                    Color(0xFFA78BFA),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              strings.languageScreenTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.languageScreenSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ...languages.map((item) {
                              final selected = _selected == item;
                              final badgeColor = _languageBadgeColor(item);
                              final iconColor = _languageIconColor(item);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selected = item;
                                      _hasSelectedManually = true;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Ink(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFF8FAFC)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected
                                            ? iconColor
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
                                            color: badgeColor,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            strings
                                                .languageName(item)
                                                .substring(0, 1),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: iconColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            strings.languageName(item),
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
                                              ? iconColor
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
                              loading: _isContinuing,
                              onPressed: _isContinuing
                                  ? null
                                  : _continueToLogin,
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

  Color _languageBadgeColor(AppLanguage language) {
    return switch (language) {
      AppLanguage.telugu => const Color(0xFFCCFBF1),
      AppLanguage.hindi => const Color(0xFFFFEDD5),
      AppLanguage.english => const Color(0xFFE0F2FE),
      AppLanguage.tamil => const Color(0xFFFCE7F3),
      AppLanguage.kannada => const Color(0xFFEDE9FE),
      AppLanguage.malayalam => const Color(0xFFDCFCE7),
    };
  }

  Color _languageIconColor(AppLanguage language) {
    return switch (language) {
      AppLanguage.telugu => const Color(0xFF0F766E),
      AppLanguage.hindi => const Color(0xFFEA580C),
      AppLanguage.english => const Color(0xFF0284C7),
      AppLanguage.tamil => const Color(0xFFDB2777),
      AppLanguage.kannada => const Color(0xFF7C3AED),
      AppLanguage.malayalam => const Color(0xFF15803D),
    };
  }
}
