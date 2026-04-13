import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/widgets/flow_screen_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final languageController = context.languageController;
    final languages = AppLanguage.values;

    if (!_hasSelectedManually) {
      _selected = languageController.language;
    }

    return Scaffold(
      body: GradientShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            FlowScreenHeader(
              title: strings.languageScreenTitle,
              subtitle: strings.languageScreenSubtitle,
              badge: '01',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ...languages.map((item) {
                    final selected = _selected == item;
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
                                ? const Color(0xFFE8EEFF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1E3A8A)
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
                                  color: selected
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  strings.languageName(item).substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF1E3A8A),
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
                              AnimatedOpacity(
                                opacity: selected ? 1 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF1E3A8A),
                                ),
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
            const SizedBox(height: 10),
            PrimaryButton(
              label: strings.continueLabel,
              onPressed: _hasSelectedManually
                  ? () async {
                      await AppFlowService.persistLanguageSelection(_selected);
                      if (!context.mounted) {
                        return;
                      }
                      languageController.setLanguage(_selected);
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.onboarding,
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
