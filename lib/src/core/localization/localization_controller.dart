import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana_poster/src/core/localization/app_language.dart';

final localizationControllerProvider =
    NotifierProvider<LocalizationController, AppLanguage>(
  LocalizationController.new,
);

class LocalizationController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    return AppLanguage.telugu;
  }

  void setLanguage(AppLanguage language) {
    state = language;
  }
}
