import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/models/political_party.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
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
  AppRegion? _region;
  Set<String> _selectedPartyIds = <String>{};
  bool _loading = true;
  bool _continuing = false;
  bool _skipping = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRegion());
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
      _selectedPartyIds = selectedPartyIds;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'పార్టీలు సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
              hindi: 'पार्टियां सेव नहीं हो सकीं। फिर कोशिश करें।',
              english: 'Could not save parties. Please try again.',
              tamil: 'கட்சிகளை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada: 'ಪಕ್ಷಗಳನ್ನು ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'പാർട്ടികൾ സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
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
    final parties = region == null
        ? const <PoliticalParty>[]
        : partiesForRegion(region.id);

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
                            child: _PartiesHeader(region: region!),
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
                                selected: _selectedPartyIds.contains(party.id),
                                onTap: () {
                                  setState(() {
                                    if (_selectedPartyIds.contains(party.id)) {
                                      _selectedPartyIds.remove(party.id);
                                    } else {
                                      _selectedPartyIds.add(party.id);
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
                    : AppRoutes.language,
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
                                  hindi: 'छोड़ें',
                                  english: 'Skip',
                                  tamil: 'தவிர்க்கவும்',
                                  kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
                                  malayalam: 'ഒഴിവാക്കുക',
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
    final partyIds = partiesForRegion(
      region.id,
    ).map((party) => party.id).toSet();
    return _selectedPartyIds.where(partyIds.contains).toSet();
  }
}

class _PartiesHeader extends StatelessWidget {
  const _PartiesHeader({required this.region});

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
                          hindi: 'राजनीतिक पार्टियां',
                          english: 'Political Parties',
                          tamil: 'அரசியல் கட்சிகள்',
                          kannada: 'ರಾಜಕೀಯ ಪಕ್ಷಗಳು',
                          malayalam: 'രാഷ്ട്രീയ പാർട്ടികൾ',
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
    required this.selected,
    required this.onTap,
  });

  final PoliticalParty party;
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
              _PartyLogo(party: party, color: color),
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
                          hindi: 'राष्ट्रीय',
                          english: 'National',
                          tamil: 'தேசிய',
                          kannada: 'ರಾಷ್ಟ್ರೀಯ',
                          malayalam: 'ദേശീയ',
                        )
                      : strings.localized(
                          telugu: 'రాష్ట్ర',
                          hindi: 'राज्य',
                          english: 'State',
                          tamil: 'மாநில',
                          kannada: 'ರಾಜ್ಯ',
                          malayalam: 'സംസ്ഥാനം',
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
  const _PartyLogo({required this.party, required this.color});

  final PoliticalParty party;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final logoAssetPath = party.logoAssetPath;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.28), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: logoAssetPath == null
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
                padding: const EdgeInsets.all(8),
                child: logoAssetPath.endsWith('.svg')
                    ? SvgPicture.asset(
                        logoAssetPath,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => Text(
                          party.shortName.characters.first,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      )
                    : Image.asset(
                        logoAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Text(
                          party.shortName.characters.first,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
              ),
            ),
    );
  }
}
