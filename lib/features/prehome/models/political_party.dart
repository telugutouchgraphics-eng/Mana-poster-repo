import 'package:mana_poster/app/localization/app_language.dart';

class PoliticalParty {
  const PoliticalParty({
    required this.id,
    required this.name,
    required this.shortName,
    required this.scope,
    required this.regionIds,
  });

  final String id;
  final String name;
  final String shortName;
  final String scope;
  final Set<String> regionIds;

  bool isRelevantTo(String regionId) {
    return regionIds.isEmpty || regionIds.contains(regionId);
  }

  String nameFor(AppLanguage language) {
    return _localizedPartyNames[id]?[language] ?? name;
  }

  String? get logoAssetPath => _partyLogoAssetPaths[id];
}

const Map<String, String> _partyLogoAssetPaths = <String, String>{
  'bjp': 'assets/elements/political/party_logos/bjp.png',
  'inc': 'assets/elements/political/party_logos/inc.png',
  'aap': 'assets/elements/political/party_logos/aap.png',
  'bsp': 'assets/elements/political/party_logos/bsp.png',
  'cpi_m': 'assets/elements/political/party_logos/cpi_m.png',
  'cpi': 'assets/elements/political/party_logos/cpi.png',
  'npp': 'assets/elements/political/party_logos/npp.png',
  'tdp': 'assets/elements/political/party_logos/tdp.png',
  'ysrcp': 'assets/elements/political/party_logos/ysrcp.jpg',
  'brs': 'assets/elements/political/party_logos/brs.png',
  'aitc': 'assets/elements/political/party_logos/aitc.png',
  'dmk': 'assets/elements/political/party_logos/dmk.png',
  'aiadmk': 'assets/elements/political/party_logos/aiadmk.png',
  'jds': 'assets/elements/political/party_logos/jds.png',
  'shiv_sena': 'assets/elements/political/party_logos/shiv_sena.png',
  'ncp': 'assets/elements/political/party_logos/ncp.png',
  'rjd': 'assets/elements/political/party_logos/rjd.jpg',
  'jdu': 'assets/elements/political/party_logos/jdu.png',
  'sp': 'assets/elements/political/party_logos/sp.png',
  'rld': 'assets/elements/political/party_logos/rld.jpg',
  'sad': 'assets/elements/political/party_logos/sad.png',
  'bjd': 'assets/elements/political/party_logos/bjd.png',
  'jmm': 'assets/elements/political/party_logos/jmm.png',
  'skm': 'assets/elements/political/party_logos/skm.png',
  'mnf': 'assets/elements/political/party_logos/mnf.jpg',
  'npf': 'assets/elements/political/party_logos/npf.png',
  'jknc': 'assets/elements/political/party_logos/jknc.png',
  'pdp': 'assets/elements/political/party_logos/pdp.png',
  'agp': 'assets/elements/political/party_logos/agp.png',
  'udp': 'assets/elements/political/party_logos/udp.jpg',
  'tmp': 'assets/elements/political/party_logos/tmp.jpg',
  'mgp': 'assets/elements/political/party_logos/mgp.jpg',
  'inld': 'assets/elements/political/party_logos/inld.png',
  'jjp': 'assets/elements/political/party_logos/jjp.jpg',
};

const Map<String, Map<AppLanguage, String>> _localizedPartyNames =
    <String, Map<AppLanguage, String>>{
      'bjp': <AppLanguage, String>{
        AppLanguage.telugu: 'భారతీయ జనతా పార్టీ',
        AppLanguage.hindi: 'भारतीय जनता पार्टी',
        AppLanguage.tamil: 'பாரதிய ஜனதா கட்சி',
        AppLanguage.kannada: 'ಭಾರತೀಯ ಜನತಾ ಪಕ್ಷ',
        AppLanguage.malayalam: 'ഭാരതീയ ജനതാ പാർട്ടി',
      },
      'inc': <AppLanguage, String>{
        AppLanguage.telugu: 'భారత జాతీయ కాంగ్రెస్',
        AppLanguage.hindi: 'भारतीय राष्ट्रीय कांग्रेस',
        AppLanguage.tamil: 'இந்திய தேசிய காங்கிரஸ்',
        AppLanguage.kannada: 'ಭಾರತೀಯ ರಾಷ್ಟ್ರೀಯ ಕಾಂಗ್ರೆಸ್',
        AppLanguage.malayalam: 'ഇന്ത്യൻ നാഷണൽ കോൺഗ്രസ്',
      },
      'aap': <AppLanguage, String>{
        AppLanguage.telugu: 'ఆమ్ ఆద్మీ పార్టీ',
        AppLanguage.hindi: 'आम आदमी पार्टी',
        AppLanguage.tamil: 'ஆம் ஆத்மி கட்சி',
        AppLanguage.kannada: 'ಆಮ್ ಆದ್ಮಿ ಪಕ್ಷ',
        AppLanguage.malayalam: 'ആം ആദ്മി പാർട്ടി',
      },
      'bsp': <AppLanguage, String>{
        AppLanguage.telugu: 'బహుజన్ సమాజ్ పార్టీ',
        AppLanguage.hindi: 'बहुजन समाज पार्टी',
        AppLanguage.tamil: 'பகுஜன் சமாஜ் கட்சி',
        AppLanguage.kannada: 'ಬಹುಜನ ಸಮಾಜ ಪಕ್ಷ',
        AppLanguage.malayalam: 'ബഹുജൻ സമാജ് പാർട്ടി',
      },
      'tdp': <AppLanguage, String>{
        AppLanguage.telugu: 'తెలుగు దేశం పార్టీ',
        AppLanguage.hindi: 'तेलुगु देशम पार्टी',
        AppLanguage.tamil: 'தெலுங்கு தேசம் கட்சி',
        AppLanguage.kannada: 'ತೆಲುಗು ದೇಶಂ ಪಕ್ಷ',
        AppLanguage.malayalam: 'തെലുങ്കു ദേശം പാർട്ടി',
      },
      'ysrcp': <AppLanguage, String>{
        AppLanguage.telugu: 'వైఎస్ఆర్ కాంగ్రెస్ పార్టీ',
        AppLanguage.hindi: 'वाईएसआर कांग्रेस पार्टी',
        AppLanguage.tamil: 'ஒய்எஸ்ஆர் காங்கிரஸ் கட்சி',
        AppLanguage.kannada: 'ವೈಎಸ್‌ಆರ್ ಕಾಂಗ್ರೆಸ್ ಪಕ್ಷ',
        AppLanguage.malayalam: 'വൈഎസ്ആർ കോൺഗ്രസ് പാർട്ടി',
      },
      'brs': <AppLanguage, String>{
        AppLanguage.telugu: 'భారత్ రాష్ట్ర సమితి',
        AppLanguage.hindi: 'भारत राष्ट्र समिति',
        AppLanguage.tamil: 'பாரத் ராஷ்ட்ர சமிதி',
        AppLanguage.kannada: 'ಭಾರತ್ ರಾಷ್ಟ್ರ ಸಮಿತಿ',
        AppLanguage.malayalam: 'ഭാരത് രാഷ്ട്ര സമിതി',
      },
      'aitc': <AppLanguage, String>{
        AppLanguage.telugu: 'ఆల్ ఇండియా తృణమూల్ కాంగ్రెస్',
        AppLanguage.hindi: 'ऑल इंडिया तृणमूल कांग्रेस',
        AppLanguage.bengali: 'সর্বভারতীয় তৃণমূল কংগ্রেস',
      },
      'dmk': <AppLanguage, String>{
        AppLanguage.telugu: 'ద్రావిడ మున్నేత్ర కళగం',
        AppLanguage.tamil: 'திராவிட முன்னேற்றக் கழகம்',
      },
      'aiadmk': <AppLanguage, String>{
        AppLanguage.telugu: 'ఆల్ ఇండియా అన్నా ద్రావిడ మున్నేత్ర కళగం',
        AppLanguage.tamil: 'அனைத்திந்திய அண்ணா திராவிட முன்னேற்றக் கழகம்',
      },
      'jds': <AppLanguage, String>{
        AppLanguage.telugu: 'జనతా దళ్ (సెక్యులర్)',
        AppLanguage.hindi: 'जनता दल (सेक्युलर)',
        AppLanguage.kannada: 'ಜನತಾ ದಳ (ಜಾತ್ಯತೀತ)',
      },
      'shiv_sena': <AppLanguage, String>{
        AppLanguage.telugu: 'శివసేన',
        AppLanguage.hindi: 'शिवसेना',
        AppLanguage.marathi: 'शिवसेना',
      },
      'ncp': <AppLanguage, String>{
        AppLanguage.telugu: 'నేషనలిస్ట్ కాంగ్రెస్ పార్టీ',
        AppLanguage.hindi: 'राष्ट्रवादी कांग्रेस पार्टी',
        AppLanguage.marathi: 'राष्ट्रवादी काँग्रेस पक्ष',
      },
      'rjd': <AppLanguage, String>{
        AppLanguage.telugu: 'రాష్ట్రీయ జనతా దళ్',
        AppLanguage.hindi: 'राष्ट्रीय जनता दल',
      },
      'jdu': <AppLanguage, String>{
        AppLanguage.telugu: 'జనతా దళ్ (యునైటెడ్)',
        AppLanguage.hindi: 'जनता दल (यूनाइटेड)',
      },
      'sp': <AppLanguage, String>{
        AppLanguage.telugu: 'సమాజ్‌వాది పార్టీ',
        AppLanguage.hindi: 'समाजवादी पार्टी',
      },
      'rld': <AppLanguage, String>{
        AppLanguage.telugu: 'రాష్ట్రీయ లోక్ దళ్',
        AppLanguage.hindi: 'राष्ट्रीय लोक दल',
      },
      'sad': <AppLanguage, String>{
        AppLanguage.telugu: 'శిరోమణి అకాలీ దళ్',
        AppLanguage.hindi: 'शिरोमणि अकाली दल',
        AppLanguage.punjabi: 'ਸ਼੍ਰੋਮਣੀ ਅਕਾਲੀ ਦਲ',
      },
      'bjd': <AppLanguage, String>{
        AppLanguage.telugu: 'బిజూ జనతా దళ్',
        AppLanguage.hindi: 'बीजू जनता दल',
        AppLanguage.odia: 'ବିଜୁ ଜନତା ଦଳ',
      },
      'jmm': <AppLanguage, String>{
        AppLanguage.telugu: 'జార్ఖండ్ ముక్తి మోర్చా',
        AppLanguage.hindi: 'झारखंड मुक्ति मोर्चा',
      },
      'skm': <AppLanguage, String>{
        AppLanguage.telugu: 'సిక్కిం క్రాంతికారి మోర్చా',
        AppLanguage.hindi: 'सिक्किम क्रांतिकारी मोर्चा',
        AppLanguage.nepali: 'सिक्किम क्रान्तिकारी मोर्चा',
      },
      'mnf': <AppLanguage, String>{
        AppLanguage.telugu: 'మిజో నేషనల్ ఫ్రంట్',
        AppLanguage.hindi: 'मिजो नेशनल फ्रंट',
        AppLanguage.mizo: 'Mizo National Front',
      },
      'npf': <AppLanguage, String>{
        AppLanguage.telugu: 'నాగా పీపుల్స్ ఫ్రంట్',
        AppLanguage.hindi: 'नागा पीपुल्स फ्रंट',
      },
      'jknc': <AppLanguage, String>{
        AppLanguage.telugu: 'నేషనల్ కాన్ఫరెన్స్',
        AppLanguage.hindi: 'नेशनल कॉन्फ्रेंस',
      },
      'pdp': <AppLanguage, String>{
        AppLanguage.telugu: 'పీపుల్స్ డెమోక్రటిక్ పార్టీ',
        AppLanguage.hindi: 'पीपुल्स डेमोक्रेटिक पार्टी',
      },
      'agp': <AppLanguage, String>{
        AppLanguage.telugu: 'అసోం గణ పరిషద్',
        AppLanguage.hindi: 'असम गण परिषद',
        AppLanguage.assamese: 'অসম গণ পৰিষদ',
      },
      'udp': <AppLanguage, String>{
        AppLanguage.telugu: 'యునైటెడ్ డెమోక్రటిక్ పార్టీ',
        AppLanguage.hindi: 'यूनाइटेड डेमोक्रेटिक पार्टी',
      },
      'tmp': <AppLanguage, String>{
        AppLanguage.telugu: 'టిప్రా మోతా పార్టీ',
        AppLanguage.hindi: 'टिपरा मोथा पार्टी',
        AppLanguage.bengali: 'টিপ্রা মথা পার্টি',
      },
      'mgp': <AppLanguage, String>{
        AppLanguage.telugu: 'మహారాష్ట్రవాది గోమంతక్ పార్టీ',
        AppLanguage.hindi: 'महाराष्ट्रवादी गोमांतक पार्टी',
        AppLanguage.konkani: 'महाराष्ट्रवादी गोमंतक पक्ष',
      },
      'inld': <AppLanguage, String>{
        AppLanguage.telugu: 'ఇండియన్ నేషనల్ లోక్ దళ్',
        AppLanguage.hindi: 'इंडियन नेशनल लोक दल',
      },
      'jjp': <AppLanguage, String>{
        AppLanguage.telugu: 'జననాయక్ జనతా పార్టీ',
        AppLanguage.hindi: 'जननायक जनता पार्टी',
      },
      'cpi_m': <AppLanguage, String>{
        AppLanguage.telugu: 'భారత కమ్యూనిస్టు పార్టీ (మార్క్సిస్టు)',
        AppLanguage.hindi: 'भारतीय कम्युनिस्ट पार्टी (मार्क्सवादी)',
        AppLanguage.malayalam:
            'കമ്മ്യൂണിസ്റ്റ് പാർട്ടി ഓഫ് ഇന്ത്യ (മാർക്സിസ്റ്റ്)',
      },
      'cpi': <AppLanguage, String>{
        AppLanguage.telugu: 'భారత కమ్యూనిస్టు పార్టీ',
        AppLanguage.hindi: 'भारतीय कम्युनिस्ट पार्टी',
        AppLanguage.tamil: 'இந்திய கம்யூனிஸ்ட் கட்சி',
        AppLanguage.kannada: 'ಭಾರತ ಕಮ್ಯುನಿಸ್ಟ್ ಪಕ್ಷ',
        AppLanguage.malayalam: 'കമ്മ്യൂണിസ്റ്റ് പാർട്ടി ഓഫ് ഇന്ത്യ',
        AppLanguage.bengali: 'ভারতীয় কমিউনিস্ট পার্টি',
      },
      'npp': <AppLanguage, String>{
        AppLanguage.telugu: 'నేషనల్ పీపుల్స్ పార్టీ',
        AppLanguage.hindi: 'नेशनल पीपुल्स पार्टी',
      },
    };

const List<PoliticalParty> politicalParties = <PoliticalParty>[
  PoliticalParty(
    id: 'bjp',
    name: 'Bharatiya Janata Party',
    shortName: 'BJP',
    scope: 'National Party',
    regionIds: <String>{},
  ),
  PoliticalParty(
    id: 'inc',
    name: 'Indian National Congress',
    shortName: 'INC',
    scope: 'National Party',
    regionIds: <String>{},
  ),
  PoliticalParty(
    id: 'aap',
    name: 'Aam Aadmi Party',
    shortName: 'AAP',
    scope: 'National Party',
    regionIds: <String>{},
  ),
  PoliticalParty(
    id: 'bsp',
    name: 'Bahujan Samaj Party',
    shortName: 'BSP',
    scope: 'National Party',
    regionIds: <String>{},
  ),
  PoliticalParty(
    id: 'cpi_m',
    name: 'Communist Party of India (Marxist)',
    shortName: 'CPI(M)',
    scope: 'National Party',
    regionIds: <String>{},
  ),
  PoliticalParty(
    id: 'cpi',
    name: 'Communist Party of India',
    shortName: 'CPI',
    scope: 'National Party',
    regionIds: <String>{},
  ),
  PoliticalParty(
    id: 'npp',
    name: 'National People\'s Party',
    shortName: 'NPP',
    scope: 'National Party',
    regionIds: <String>{},
  ),
  PoliticalParty(
    id: 'tdp',
    name: 'Telugu Desam Party',
    shortName: 'TDP',
    scope: 'Regional Party',
    regionIds: <String>{'andhra_pradesh', 'telangana'},
  ),
  PoliticalParty(
    id: 'ysrcp',
    name: 'YSR Congress Party',
    shortName: 'YSRCP',
    scope: 'Regional Party',
    regionIds: <String>{'andhra_pradesh'},
  ),
  PoliticalParty(
    id: 'brs',
    name: 'Bharat Rashtra Samithi',
    shortName: 'BRS',
    scope: 'Regional Party',
    regionIds: <String>{'telangana'},
  ),
  PoliticalParty(
    id: 'aitc',
    name: 'All India Trinamool Congress',
    shortName: 'AITC',
    scope: 'Regional Party',
    regionIds: <String>{'west_bengal', 'tripura', 'meghalaya'},
  ),
  PoliticalParty(
    id: 'dmk',
    name: 'Dravida Munnetra Kazhagam',
    shortName: 'DMK',
    scope: 'Regional Party',
    regionIds: <String>{'tamil_nadu', 'puducherry'},
  ),
  PoliticalParty(
    id: 'aiadmk',
    name: 'All India Anna Dravida Munnetra Kazhagam',
    shortName: 'AIADMK',
    scope: 'Regional Party',
    regionIds: <String>{'tamil_nadu', 'puducherry'},
  ),
  PoliticalParty(
    id: 'jds',
    name: 'Janata Dal (Secular)',
    shortName: 'JD(S)',
    scope: 'Regional Party',
    regionIds: <String>{'karnataka'},
  ),
  PoliticalParty(
    id: 'shiv_sena',
    name: 'Shiv Sena',
    shortName: 'SS',
    scope: 'Regional Party',
    regionIds: <String>{'maharashtra'},
  ),
  PoliticalParty(
    id: 'ncp',
    name: 'Nationalist Congress Party',
    shortName: 'NCP',
    scope: 'Regional Party',
    regionIds: <String>{'maharashtra'},
  ),
  PoliticalParty(
    id: 'rjd',
    name: 'Rashtriya Janata Dal',
    shortName: 'RJD',
    scope: 'Regional Party',
    regionIds: <String>{'bihar', 'jharkhand'},
  ),
  PoliticalParty(
    id: 'jdu',
    name: 'Janata Dal (United)',
    shortName: 'JD(U)',
    scope: 'Regional Party',
    regionIds: <String>{'bihar'},
  ),
  PoliticalParty(
    id: 'sp',
    name: 'Samajwadi Party',
    shortName: 'SP',
    scope: 'Regional Party',
    regionIds: <String>{'uttar_pradesh', 'uttarakhand'},
  ),
  PoliticalParty(
    id: 'rld',
    name: 'Rashtriya Lok Dal',
    shortName: 'RLD',
    scope: 'Regional Party',
    regionIds: <String>{'uttar_pradesh'},
  ),
  PoliticalParty(
    id: 'sad',
    name: 'Shiromani Akali Dal',
    shortName: 'SAD',
    scope: 'Regional Party',
    regionIds: <String>{'punjab', 'chandigarh'},
  ),
  PoliticalParty(
    id: 'bjd',
    name: 'Biju Janata Dal',
    shortName: 'BJD',
    scope: 'Regional Party',
    regionIds: <String>{'odisha'},
  ),
  PoliticalParty(
    id: 'jmm',
    name: 'Jharkhand Mukti Morcha',
    shortName: 'JMM',
    scope: 'Regional Party',
    regionIds: <String>{'jharkhand'},
  ),
  PoliticalParty(
    id: 'skm',
    name: 'Sikkim Krantikari Morcha',
    shortName: 'SKM',
    scope: 'Regional Party',
    regionIds: <String>{'sikkim'},
  ),
  PoliticalParty(
    id: 'mnf',
    name: 'Mizo National Front',
    shortName: 'MNF',
    scope: 'Regional Party',
    regionIds: <String>{'mizoram'},
  ),
  PoliticalParty(
    id: 'npf',
    name: 'Naga People\'s Front',
    shortName: 'NPF',
    scope: 'Regional Party',
    regionIds: <String>{'nagaland', 'manipur'},
  ),
  PoliticalParty(
    id: 'jknc',
    name: 'National Conference',
    shortName: 'JKNC',
    scope: 'Regional Party',
    regionIds: <String>{'jammu_kashmir', 'ladakh'},
  ),
  PoliticalParty(
    id: 'pdp',
    name: 'Peoples Democratic Party',
    shortName: 'PDP',
    scope: 'Regional Party',
    regionIds: <String>{'jammu_kashmir'},
  ),
  PoliticalParty(
    id: 'agp',
    name: 'Asom Gana Parishad',
    shortName: 'AGP',
    scope: 'Regional Party',
    regionIds: <String>{'assam'},
  ),
  PoliticalParty(
    id: 'udp',
    name: 'United Democratic Party',
    shortName: 'UDP',
    scope: 'Regional Party',
    regionIds: <String>{'meghalaya'},
  ),
  PoliticalParty(
    id: 'tmp',
    name: 'Tipra Motha Party',
    shortName: 'TMP',
    scope: 'Regional Party',
    regionIds: <String>{'tripura'},
  ),
  PoliticalParty(
    id: 'mgp',
    name: 'Maharashtrawadi Gomantak Party',
    shortName: 'MGP',
    scope: 'Regional Party',
    regionIds: <String>{'goa'},
  ),
  PoliticalParty(
    id: 'inld',
    name: 'Indian National Lok Dal',
    shortName: 'INLD',
    scope: 'Regional Party',
    regionIds: <String>{'haryana'},
  ),
  PoliticalParty(
    id: 'jjp',
    name: 'Jannayak Janta Party',
    shortName: 'JJP',
    scope: 'Regional Party',
    regionIds: <String>{'haryana'},
  ),
];

List<PoliticalParty> partiesForRegion(String regionId) {
  return politicalParties
      .where((party) => party.isRelevantTo(regionId))
      .toList(growable: false);
}
