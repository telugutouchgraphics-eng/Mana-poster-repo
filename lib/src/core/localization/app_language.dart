import 'package:flutter/material.dart';

enum AppLanguage {
  telugu,
  hindi,
  english,
}

extension AppLanguageX on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.telugu:
        return const Locale('te');
      case AppLanguage.hindi:
        return const Locale('hi');
      case AppLanguage.english:
        return const Locale('en');
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.telugu:
        return 'తెలుగు';
      case AppLanguage.hindi:
        return 'हिंदी';
      case AppLanguage.english:
        return 'English';
    }
  }
}
