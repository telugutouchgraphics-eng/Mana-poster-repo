import 'package:mana_poster/app/localization/app_language.dart';

enum AppRegionType { state, unionTerritory }

class AppRegion {
  const AppRegion({
    required this.id,
    required this.name,
    required this.primaryLanguage,
    required this.primaryLanguageCode,
    required this.type,
    required this.appLanguage,
  });

  final String id;
  final String name;
  final String primaryLanguage;
  final String primaryLanguageCode;
  final AppRegionType type;
  final AppLanguage appLanguage;

  String get logoAssetPath {
    final assetId = id == 'andaman_nicobar' ? 'andaman_nicobar_islands' : id;
    return 'assets/elements/regions/logos/$assetId.png';
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return name.toLowerCase().contains(normalized) ||
        primaryLanguage.toLowerCase().contains(normalized);
  }
}

const List<AppRegion> appRegions = <AppRegion>[
  AppRegion(
    id: 'andhra_pradesh',
    name: 'Andhra Pradesh',
    primaryLanguage: 'Telugu',
    primaryLanguageCode: 'te',
    type: AppRegionType.state,
    appLanguage: AppLanguage.telugu,
  ),
  AppRegion(
    id: 'arunachal_pradesh',
    name: 'Arunachal Pradesh',
    primaryLanguage: 'English',
    primaryLanguageCode: 'en',
    type: AppRegionType.state,
    appLanguage: AppLanguage.english,
  ),
  AppRegion(
    id: 'assam',
    name: 'Assam',
    primaryLanguage: 'Assamese',
    primaryLanguageCode: 'as',
    type: AppRegionType.state,
    appLanguage: AppLanguage.assamese,
  ),
  AppRegion(
    id: 'bihar',
    name: 'Bihar',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'chhattisgarh',
    name: 'Chhattisgarh',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'goa',
    name: 'Goa',
    primaryLanguage: 'Konkani',
    primaryLanguageCode: 'kok',
    type: AppRegionType.state,
    appLanguage: AppLanguage.konkani,
  ),
  AppRegion(
    id: 'gujarat',
    name: 'Gujarat',
    primaryLanguage: 'Gujarati',
    primaryLanguageCode: 'gu',
    type: AppRegionType.state,
    appLanguage: AppLanguage.gujarati,
  ),
  AppRegion(
    id: 'haryana',
    name: 'Haryana',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'himachal_pradesh',
    name: 'Himachal Pradesh',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'jharkhand',
    name: 'Jharkhand',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'karnataka',
    name: 'Karnataka',
    primaryLanguage: 'Kannada',
    primaryLanguageCode: 'kn',
    type: AppRegionType.state,
    appLanguage: AppLanguage.kannada,
  ),
  AppRegion(
    id: 'kerala',
    name: 'Kerala',
    primaryLanguage: 'Malayalam',
    primaryLanguageCode: 'ml',
    type: AppRegionType.state,
    appLanguage: AppLanguage.malayalam,
  ),
  AppRegion(
    id: 'madhya_pradesh',
    name: 'Madhya Pradesh',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'maharashtra',
    name: 'Maharashtra',
    primaryLanguage: 'Marathi',
    primaryLanguageCode: 'mr',
    type: AppRegionType.state,
    appLanguage: AppLanguage.marathi,
  ),
  AppRegion(
    id: 'manipur',
    name: 'Manipur',
    primaryLanguage: 'Meitei (Manipuri)',
    primaryLanguageCode: 'mni',
    type: AppRegionType.state,
    appLanguage: AppLanguage.meitei,
  ),
  AppRegion(
    id: 'meghalaya',
    name: 'Meghalaya',
    primaryLanguage: 'English',
    primaryLanguageCode: 'en',
    type: AppRegionType.state,
    appLanguage: AppLanguage.english,
  ),
  AppRegion(
    id: 'mizoram',
    name: 'Mizoram',
    primaryLanguage: 'Mizo',
    primaryLanguageCode: 'lus',
    type: AppRegionType.state,
    appLanguage: AppLanguage.mizo,
  ),
  AppRegion(
    id: 'nagaland',
    name: 'Nagaland',
    primaryLanguage: 'English',
    primaryLanguageCode: 'en',
    type: AppRegionType.state,
    appLanguage: AppLanguage.english,
  ),
  AppRegion(
    id: 'odisha',
    name: 'Odisha',
    primaryLanguage: 'Odia',
    primaryLanguageCode: 'or',
    type: AppRegionType.state,
    appLanguage: AppLanguage.odia,
  ),
  AppRegion(
    id: 'punjab',
    name: 'Punjab',
    primaryLanguage: 'Punjabi',
    primaryLanguageCode: 'pa',
    type: AppRegionType.state,
    appLanguage: AppLanguage.punjabi,
  ),
  AppRegion(
    id: 'rajasthan',
    name: 'Rajasthan',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'sikkim',
    name: 'Sikkim',
    primaryLanguage: 'Nepali',
    primaryLanguageCode: 'ne',
    type: AppRegionType.state,
    appLanguage: AppLanguage.nepali,
  ),
  AppRegion(
    id: 'tamil_nadu',
    name: 'Tamil Nadu',
    primaryLanguage: 'Tamil',
    primaryLanguageCode: 'ta',
    type: AppRegionType.state,
    appLanguage: AppLanguage.tamil,
  ),
  AppRegion(
    id: 'telangana',
    name: 'Telangana',
    primaryLanguage: 'Telugu',
    primaryLanguageCode: 'te',
    type: AppRegionType.state,
    appLanguage: AppLanguage.telugu,
  ),
  AppRegion(
    id: 'tripura',
    name: 'Tripura',
    primaryLanguage: 'Bengali',
    primaryLanguageCode: 'bn',
    type: AppRegionType.state,
    appLanguage: AppLanguage.bengali,
  ),
  AppRegion(
    id: 'uttar_pradesh',
    name: 'Uttar Pradesh',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'uttarakhand',
    name: 'Uttarakhand',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.state,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'west_bengal',
    name: 'West Bengal',
    primaryLanguage: 'Bengali',
    primaryLanguageCode: 'bn',
    type: AppRegionType.state,
    appLanguage: AppLanguage.bengali,
  ),
  AppRegion(
    id: 'delhi',
    name: 'Delhi',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'jammu_kashmir',
    name: 'Jammu & Kashmir',
    primaryLanguage: 'Kashmiri',
    primaryLanguageCode: 'ks',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.kashmiri,
  ),
  AppRegion(
    id: 'ladakh',
    name: 'Ladakh',
    primaryLanguage: 'Ladakhi',
    primaryLanguageCode: 'lbj',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.ladakhi,
  ),
  AppRegion(
    id: 'puducherry',
    name: 'Puducherry',
    primaryLanguage: 'Tamil',
    primaryLanguageCode: 'ta',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.tamil,
  ),
  AppRegion(
    id: 'chandigarh',
    name: 'Chandigarh',
    primaryLanguage: 'Punjabi',
    primaryLanguageCode: 'pa',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.punjabi,
  ),
  AppRegion(
    id: 'andaman_nicobar',
    name: 'Andaman & Nicobar Islands',
    primaryLanguage: 'Hindi',
    primaryLanguageCode: 'hi',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.hindi,
  ),
  AppRegion(
    id: 'lakshadweep',
    name: 'Lakshadweep',
    primaryLanguage: 'Malayalam',
    primaryLanguageCode: 'ml',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.malayalam,
  ),
  AppRegion(
    id: 'dadra_nagar_haveli_daman_diu',
    name: 'Dadra & Nagar Haveli and Daman & Diu',
    primaryLanguage: 'Gujarati',
    primaryLanguageCode: 'gu',
    type: AppRegionType.unionTerritory,
    appLanguage: AppLanguage.gujarati,
  ),
];

AppRegion? appRegionById(String? id) {
  final normalized = id?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }
  final canonicalId = normalized == 'andaman_nicobar_islands'
      ? 'andaman_nicobar'
      : normalized;
  for (final region in appRegions) {
    if (region.id == canonicalId) {
      return region;
    }
  }
  return null;
}
