import 'package:shared_preferences/shared_preferences.dart';

class PremiumTemplateAccessService {
  const PremiumTemplateAccessService();

  static const String _storageKey = 'premium_template_unlocked_ids_v1';
  static const String _productMapStorageKey =
      'premium_template_product_map_v1';

  Future<Set<String>> loadUnlockedTemplateIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey)?.toSet() ?? <String>{};
  }

  Future<bool> isTemplateUnlocked(String templateId) async {
    final unlocked = await loadUnlockedTemplateIds();
    return unlocked.contains(templateId);
  }

  Future<Set<String>> unlockTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList(_storageKey)?.toSet() ?? <String>{};
    unlocked.add(templateId);
    await prefs.setStringList(_storageKey, unlocked.toList()..sort());
    return unlocked;
  }

  Future<Set<String>> unlockTemplateForProduct({
    required String templateId,
    required String productId,
  }) async {
    final unlocked = await unlockTemplate(templateId);
    final prefs = await SharedPreferences.getInstance();
    final productMap = prefs.getStringList(_productMapStorageKey) ?? <String>[];
    final normalized = '$productId::$templateId';
    if (!productMap.contains(normalized)) {
      productMap.add(normalized);
      productMap.sort();
      await prefs.setStringList(_productMapStorageKey, productMap);
    }
    return unlocked;
  }

  Future<Map<String, String>> loadProductToTemplateMap() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_productMapStorageKey) ?? <String>[];
    final result = <String, String>{};
    for (final entry in values) {
      final parts = entry.split('::');
      if (parts.length != 2) {
        continue;
      }
      result[parts.first] = parts.last;
    }
    return result;
  }

  Future<Set<String>> unlockTemplates(Set<String> templateIds) async {
    if (templateIds.isEmpty) {
      return loadUnlockedTemplateIds();
    }
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList(_storageKey)?.toSet() ?? <String>{};
    unlocked.addAll(templateIds);
    await prefs.setStringList(_storageKey, unlocked.toList()..sort());
    return unlocked;
  }
}
