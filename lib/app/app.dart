import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/theme/app_theme.dart';

class ManaPosterApp extends StatefulWidget {
  const ManaPosterApp({super.key, this.initialLanguage = AppLanguage.telugu});

  final AppLanguage initialLanguage;

  @override
  State<ManaPosterApp> createState() => _ManaPosterAppState();
}

class _ManaPosterAppState extends State<ManaPosterApp> {
  late final AppLanguageController _languageController;

  @override
  void initState() {
    super.initState();
    _languageController = AppLanguageController(
      initialLanguage: widget.initialLanguage,
    );
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      controller: _languageController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mana Poster',
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.map,
      ),
    );
  }
}
