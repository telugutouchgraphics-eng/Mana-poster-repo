import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';

abstract class SettingsRepository {
  Future<AppLinks?> loadAppLinks();

  Future<AppLinks> saveAppLinks(AppLinks links);

  Future<Settings?> loadSettings();

  Future<Settings> saveSettings(Settings settings);
}
