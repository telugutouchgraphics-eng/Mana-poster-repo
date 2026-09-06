import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/models/political_party.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/political_party_logo_service.dart';
import 'package:mana_poster/features/prehome/services/political_party_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

class PoliticalPartiesScreen extends StatefulWidget {
  const PoliticalPartiesScreen({
    super.key,
    this.returnToPreviousOnSave = false,
  });

  final bool returnToPreviousOnSave;

  @override
  State<PoliticalPartiesScreen> createState() => _PoliticalPartiesScreenState();
}

class _PoliticalPartiesScreenState extends State<PoliticalPartiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  AppRegion? _region;
  Set<String> _selectedPartyIds = <String>{};
  List<PoliticalParty> _politicalParties = politicalParties;
  StreamSubscription<List<PoliticalParty>>? _partySubscription;
  StreamSubscription<Map<String, String>>? _partyLogoSubscription;
  Map<String, String> _partyLogoOverridesByPartyId = const <String, String>{};
  String _searchQuery = '';
  bool _loading = true;
  bool _continuing = false;
  bool _skipping = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRegion());
    unawaited(_loadParties());
    _partySubscription = const PoliticalPartyService().watchParties().listen(
      _applyParties,
      onError: (_) {},
    );
    unawaited(_loadPartyLogos());
    _partyLogoSubscription = const PoliticalPartyLogoService()
        .watchLogoUrlsByPartyId()
        .listen(_applyPartyLogos, onError: (_) {});
  }

  Future<void> _loadPartyLogos() async {
    final logos = await const PoliticalPartyLogoService()
        .fetchLogoUrlsByPartyId();
    _applyPartyLogos(logos);
  }

  Future<void> _loadParties() async {
    final parties = await const PoliticalPartyService().fetchParties();
    _applyParties(parties);
  }

  void _applyParties(List<PoliticalParty> parties) {
    if (!mounted) {
      return;
    }
    final currentSignature = _partySignature(_politicalParties);
    final nextSignature = _partySignature(parties);
    if (currentSignature == nextSignature) {
      return;
    }
    setState(() => _politicalParties = parties);
  }

  String _partySignature(List<PoliticalParty> parties) {
    return parties
        .map(
          (party) =>
              '${party.id}:${party.name}:${party.shortName}:${party.regionIds.join(",")}:${party.logoAssetPath ?? ""}:${party.localizedNamesSignature}',
        )
        .join('|');
  }

  void _applyPartyLogos(Map<String, String> logos) {
    if (!mounted) {
      return;
    }
    if (mapEquals(_partyLogoOverridesByPartyId, logos)) {
      return;
    }
    setState(() => _partyLogoOverridesByPartyId = logos);
  }

  @override
  void dispose() {
    _partySubscription?.cancel();
    _partyLogoSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegion() async {
    final region = await AppRegionService.loadSelection();
    final selectedPartyIds = await AppPartyPreferenceService.loadSelection();
    if (!mounted) {
      return;
    }
    if (region == null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.language,
        (Route<dynamic> route) => false,
      );
      return;
    }
    setState(() {
      _region = region;
      _selectedPartyIds = widget.returnToPreviousOnSave
          ? _singleSelectedPartyIds(selectedPartyIds)
          : selectedPartyIds;
      _loading = false;
    });
  }

  Future<void> _continue() async {
    if (_continuing || _skipping) {
      return;
    }
    setState(() => _continuing = true);
    final visiblePartyIds = _visibleSelectedPartyIds();
    final saved = await AppPartyPreferenceService.persistSelection(
      visiblePartyIds,
    );
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() => _continuing = false);
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'పార్టీలు సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
              english: 'Could not save parties. Please try again.',
              hindi: 'पार्टियां सेव नहीं हो सकीं। फिर कोशिश करें।',
              tamil: 'கட்சிகளை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada: 'ಪಕ್ಷಗಳನ್ನು ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'പാർട്ടികൾ സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
              marathi: 'पक्ष जतन करता आले नाहीत. कृपया पुन्हा प्रयत्न करा.',
              gujarati: 'પાર્ટીઓ સાચવી શકાઈ નથી. ફરી પ્રયાસ કરો.',
              bengali: 'দলগুলি সংরক্ষণ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
              punjabi: 'ਪਾਰਟੀਆਂ ਸੁਰੱਖਿਅਤ ਨਹੀਂ ਹੋ ਸਕੀਆਂ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
              odia: 'ଦଳଗୁଡ଼ିକ ସଂରକ୍ଷଣ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
              assamese: 'দলসমূহ সংৰক্ষণ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
              konkani: 'पक्ष सांबाळपाक जमले नात. उपकार करून परत यत्न करात.',
              nepali: 'दलहरू सुरक्षित गर्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
              meitei: 'Parties save touba ngamkhide. Amuk hanna hotnabiyu.',
              mizo: 'Party-te save theih a ni lo. Khawngaihin ti nawn leh rawh.',
              kashmiri: 'پارٹیاں ہیکہِ نہٕ محفوٗظ گژھِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
              ladakhi: 'སྲིད་དོན་ཚོགས་པ་རྣམས་ཉར་ཚགས་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
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
    final route = await AppFlowService.resolvePostRegionEntryRoute();
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(route, (Route<dynamic> route) => false);
  }

  Future<void> _skip() async {
    if (_continuing || _skipping) {
      return;
    }
    setState(() => _skipping = true);
    await AppPartyPreferenceService.persistSelection(<String>{});
    if (!mounted) {
      return;
    }
    if (widget.returnToPreviousOnSave) {
      Navigator.of(context).pop(false);
      return;
    }
    final route = await AppFlowService.resolvePostRegionEntryRoute();
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(route, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final region = _region;
    final parties = _visibleParties();

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      slivers: <Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
                          sliver: SliverToBoxAdapter(
                            child: _PartySearchHeader(
                              controller: _searchController,
                              region: region!,
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                          sliver: SliverList.separated(
                            itemCount: parties.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final party = parties[index];
                              return _PartyTile(
                                party: party,
                                logoOverrideUrl:
                                    _partyLogoOverridesByPartyId[party.id],
                                selected: _selectedPartyIds.contains(party.id),
                                onTap: () {
                                  setState(() {
                                    if (widget.returnToPreviousOnSave) {
                                      _selectedPartyIds = <String>{party.id};
                                    } else {
                                      if (_selectedPartyIds.contains(
                                        party.id,
                                      )) {
                                        _selectedPartyIds.remove(party.id);
                                      } else {
                                        _selectedPartyIds.add(party.id);
                                      }
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            left: 16,
            top: 0,
            child: SafeArea(
              child: AppScreenBackButton(
                fallbackRoute: widget.returnToPreviousOnSave
                    ? null
                    : AppRoutes.appLanguage,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    PrimaryButton(
                      label: widget.returnToPreviousOnSave
                          ? context.strings.saveApply
                          : context.strings.continueLabel,
                      loading: _continuing,
                      onPressed: (_continuing || _skipping) ? null : _continue,
                    ),
                    if (!widget.returnToPreviousOnSave) ...<Widget>[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: (_continuing || _skipping) ? null : _skip,
                        child: _skipping
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                context.strings.localized(
                                  telugu: 'దాటవేయి',
                                  english: 'Skip',
                                  hindi: 'छोड़ें',
                                  tamil: 'தவிர்க்கவும்',
                                  kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
                                  malayalam: 'ഒഴിവാക്കുക',
                                  marathi: 'वगळा',
                                  gujarati: 'છોડો',
                                  bengali: 'এড়িয়ে যান',
                                  punjabi: 'ਛੱਡੋ',
                                  odia: 'ଛାଡ଼ିଦିଅନ୍ତୁ',
                                  assamese: 'এৰাই চলক',
                                  konkani: 'सोडून दियात',
                                  nepali: 'छोड्नुहोस्',
                                  meitei: 'Houdokpidana thambiyu',
                                  mizo: 'Kalsan rawh',
                                  kashmiri: 'ترٛٲవిو',
                                  ladakhi: 'ཕྱིར་འཐེན།',
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Set<String> _visibleSelectedPartyIds() {
    final region = _region;
    if (region == null) {
      return <String>{};
    }
    if (widget.returnToPreviousOnSave) {
      for (final party in _allRankedPartiesForSelection(region)) {
        if (_selectedPartyIds.contains(party.id)) {
          return <String>{party.id};
        }
      }
      return <String>{};
    }
    final partyIds = _partiesForRegion(
      region.id,
    ).map((party) => party.id).toSet();
    return _selectedPartyIds.where(partyIds.contains).toSet();
  }

  Set<String> _singleSelectedPartyIds(Set<String> source) {
    final region = _region;
    if (region == null || source.isEmpty) {
      return <String>{};
    }
    for (final party in _allRankedPartiesForSelection(region)) {
      if (source.contains(party.id)) {
        return <String>{party.id};
      }
    }
    return <String>{};
  }

  List<PoliticalParty> _allRankedPartiesForSelection(AppRegion region) {
    final sorted = List<PoliticalParty>.of(_politicalParties);
    int rank(PoliticalParty party) {
      if (party.regionIds.contains(region.id)) {
        return 0;
      }
      if (party.regionIds.isEmpty) {
        return 1;
      }
      return 2;
    }

    sorted.sort((left, right) {
      final rankCompare = rank(left).compareTo(rank(right));
      if (rankCompare != 0) {
        return rankCompare;
      }
      return left.name.compareTo(right.name);
    });
    return sorted;
  }

  List<PoliticalParty> _visibleParties() {
    final region = _region;
    if (region == null) {
      return const <PoliticalParty>[];
    }
    final sorted = !widget.returnToPreviousOnSave
        ? _partiesForRegion(region.id)
        : _allRankedPartiesForSelection(region);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return sorted;
    }
    return sorted
        .where((party) {
          return party.id.toLowerCase().contains(query) ||
              party.shortName.toLowerCase().contains(query) ||
              party.name.toLowerCase().contains(query) ||
              party.nameFor(AppLanguage.telugu).toLowerCase().contains(query) ||
              party
                  .nameFor(context.currentLanguage)
                  .toLowerCase()
                  .contains(query);
        })
        .toList(growable: false);
  }

  List<PoliticalParty> _partiesForRegion(String regionId) {
    return _politicalParties
        .where((party) => party.isRelevantTo(regionId))
        .toList(growable: false);
  }
}

class _PartySearchHeader extends StatelessWidget {
  const _PartySearchHeader({
    required this.controller,
    required this.region,
    required this.onChanged,
  });

  final TextEditingController controller;
  final AppRegion region;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: strings.localized(
                      telugu: 'క్లియర్ చేయండి',
                      english: 'Clear',
                      hindi: 'साफ़ करें',
                      tamil: 'அழி',
                      kannada: 'ತೆರವುಗೊಳಿಸಿ',
                      malayalam: 'മായ്ക്കുക',
                      marathi: 'साफ करा',
                      gujarati: 'સાફ કરો',
                      bengali: 'মুছুন',
                      punjabi: 'ਸਾਫ਼ ਕਰੋ',
                      odia: 'ସଫା କରନ୍ତୁ',
                      assamese: 'মচি পেলাওক',
                      konkani: 'नितळ करात',
                      nepali: 'हटाउनुहोस्',
                      meitei: 'Sengdok-u',
                      mizo: 'Tifai rawh',
                      kashmiri: 'صاف کٔریو',
                      ladakhi: 'གཙང་མ་བཟོས།',
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            hintText: strings.localized(
              telugu: 'పార్టీని వెతకండి',
              english: 'Search party',
              hindi: 'पार्टी खोजें',
              tamil: 'கட்சியைத் தேடுங்கள்',
              kannada: 'ಪಕ್ಷವನ್ನು ಹುಡುಕಿ',
              malayalam: 'പാർട്ടി തിരയുക',
              marathi: 'पक्ष शोधा',
              gujarati: 'પાર્ટી શોધો',
              bengali: 'দল অনুসন্ধান করুন',
              punjabi: 'ਪਾਰਟੀ ਖੋਜੋ',
              odia: 'ଦଳ ଖୋଜନ୍ତୁ',
              assamese: 'দল সন্ধান কৰক',
              konkani: 'पक्ष सोदात',
              nepali: 'दल खोज्नुहोस्',
              meitei: 'Party thiba',
              mizo: 'Party zawng rawh',
              kashmiri: 'پارٹی ژھانٛڈیو',
              ladakhi: 'སྲིད་དོན་ཚོགས་པ་འཚོལ།',
            ),
            helperText: region.name,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF0F766E),
                width: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UnusedPartiesHeader extends StatelessWidget {
  const UnusedPartiesHeader({super.key, required this.region});

  final AppRegion region;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.how_to_vote_rounded,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.localized(
                          telugu: 'రాజకీయ పార్టీలు',
                          english: 'Political Parties',
                          hindi: 'राजनीतिक पार्टियां',
                          tamil: 'அரசியல் கட்சிகள்',
                          kannada: 'ರಾಜಕೀಯ ಪಕ್ಷಗಳು',
                          malayalam: 'രാഷ്ട്രീയ പാർട്ടികൾ',
                          marathi: 'राजकीय पक्ष',
                          gujarati: 'રાજકીય પક્ષો',
                          bengali: 'রাজনৈতিক দলগুলি',
                          punjabi: 'ਰਾਜਨੀਤਿਕ ਪਾਰਟੀਆਂ',
                          odia: 'ରାଜନୈତିକ ଦଳଗୁଡ଼ିକ',
                          assamese: 'ৰাজনৈতিক দলসমূহ',
                          konkani: 'राजकीय पक्ष',
                          nepali: 'राजनीतिक दलहरू',
                          meitei: 'Political Parties',
                          mizo: 'Political Parties',
                          kashmiri: 'سیاسی پارٹیاں',
                          ladakhi: 'སྲིད་དོན་ཚོགས་པ།',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${region.name} • ${region.primaryLanguage}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyTile extends StatelessWidget {
  const _PartyTile({
    required this.party,
    required this.logoOverrideUrl,
    required this.selected,
    required this.onTap,
  });

  final PoliticalParty party;
  final String? logoOverrideUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final partyName = party.nameFor(context.currentLanguage);
    final isNational = party.regionIds.isEmpty;
    final color = isNational
        ? const Color(0xFF2563EB)
        : const Color(0xFF0F766E);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : const Color(0xFFE2E8F0),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              _PartyLogo(
                party: party,
                color: color,
                logoOverrideUrl: logoOverrideUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      partyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      party.shortName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? color : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isNational
                      ? strings.localized(
                          telugu: 'జాతీయ',
                          english: 'National',
                          hindi: 'राष्ट्रीय',
                          tamil: 'தேசிய',
                          kannada: 'ರಾಷ್ಟ್ರೀಯ',
                          malayalam: 'ദേശീയ',
                          marathi: 'राष्ट्रीय',
                          gujarati: 'રાષ્ટ્રીય',
                          bengali: 'জাতীয়',
                          punjabi: 'ਰਾਸ਼ਟਰੀ',
                          odia: 'ଜାତୀୟ',
                          assamese: 'ৰাষ্ট্ৰীয়',
                          konkani: 'राष्ट्रीय',
                          nepali: 'राष्ट्रिय',
                          meitei: 'National',
                          mizo: 'Ram chhung huap',
                          kashmiri: 'قومی',
                          ladakhi: 'རྒྱལ་ཡོངས།',
                        )
                      : strings.localized(
                          telugu: 'రాష్ట్ర',
                          english: 'State',
                          hindi: 'राज्य',
                          tamil: 'மாநில',
                          kannada: 'ರಾಜ್ಯ',
                          malayalam: 'സംസ്ഥാനം',
                          marathi: 'राज्य',
                          gujarati: 'રાજ્ય',
                          bengali: 'রাজ্য',
                          punjabi: 'ਰਾਜ',
                          odia: 'ରାଜ୍ୟ',
                          assamese: 'ৰাজ্যিক',
                          konkani: 'राज्य',
                          nepali: 'राज्य',
                          meitei: 'State',
                          mizo: 'State',
                          kashmiri: 'ریاستی',
                          ladakhi: 'མངའ་སྡེ།',
                        ),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyLogo extends StatelessWidget {
  const _PartyLogo({
    required this.party,
    required this.color,
    this.logoOverrideUrl,
  });

  final PoliticalParty party;
  final Color color;
  final String? logoOverrideUrl;

  @override
  Widget build(BuildContext context) {
    final logoPath = (logoOverrideUrl?.trim().isNotEmpty ?? false)
        ? logoOverrideUrl!.trim()
        : party.logoAssetPath;
    final lowerLogoPath = logoPath?.toLowerCase() ?? '';
    final isNetwork =
        lowerLogoPath.startsWith('https://') ||
        lowerLogoPath.startsWith('http://');
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.16), width: 0.8),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: logoPath == null
          ? Text(
              party.shortName.characters.first,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            )
          : ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child:
                    lowerLogoPath.endsWith('.svg') ||
                        lowerLogoPath.contains('.svg?')
                    ? (isNetwork
                          ? SvgPicture.network(
                              logoPath,
                              fit: BoxFit.contain,
                              placeholderBuilder: (_) => _PartyLogoFallback(
                                party: party,
                                color: color,
                              ),
                            )
                          : SvgPicture.asset(
                              logoPath,
                              fit: BoxFit.contain,
                              placeholderBuilder: (_) => _PartyLogoFallback(
                                party: party,
                                color: color,
                              ),
                            ))
                    : (isNetwork
                          ? CachedNetworkImage(
                              imageUrl: logoPath,
                              fit: BoxFit.contain,
                              placeholder: (_, _) => _PartyLogoFallback(
                                party: party,
                                color: color,
                              ),
                              errorWidget: (_, _, _) => _PartyLogoFallback(
                                party: party,
                                color: color,
                              ),
                            )
                          : Image.asset(
                              logoPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => _PartyLogoFallback(
                                party: party,
                                color: color,
                              ),
                            )),
              ),
            ),
    );
  }
}

class _PartyLogoFallback extends StatelessWidget {
  const _PartyLogoFallback({required this.party, required this.color});

  final PoliticalParty party;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      party.shortName.characters.first,
      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22),
    );
  }
}
