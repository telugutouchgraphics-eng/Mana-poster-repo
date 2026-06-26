import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';

class RegionSelectionScreen extends StatefulWidget {
  const RegionSelectionScreen({super.key, this.returnToPreviousOnSave = false});

  final bool returnToPreviousOnSave;

  @override
  State<RegionSelectionScreen> createState() => _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends State<RegionSelectionScreen>
    with AppLanguageStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _savingRegionId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectRegion(AppRegion region) async {
    if (_savingRegionId != null) {
      return;
    }
    setState(() => _savingRegionId = region.id);
    final saved = await AppRegionService.persistSelection(region);
    final languageSaved = saved
        ? await AppFlowService.persistLanguageSelection(region.appLanguage)
        : false;
    if (!mounted) {
      return;
    }
    if (!saved || !languageSaved) {
      setState(() => _savingRegionId = null);
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text('Could not save region. Please try again.'),
        ),
      );
      return;
    }
    context.languageController.setLanguage(region.appLanguage);
    unawaited(NotificationService.instance.syncCurrentPreferences());
    if (widget.returnToPreviousOnSave) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.politicalParties,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final regions = appRegions
        .where((region) => region.matches(_query))
        .toList(growable: false);
    final stateCount = appRegions
        .where((item) => item.type == AppRegionType.state)
        .length;
    final unionTerritoryCount = appRegions.length - stateCount;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height;
                  return CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: _RegionHeader(
                            stateCount: stateCount,
                            unionTerritoryCount: unionTerritoryCount,
                            controller: _searchController,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          math.max(20, viewportHeight * 0.04),
                        ),
                        sliver: regions.isEmpty
                            ? const SliverToBoxAdapter(child: _EmptyRegions())
                            : SliverList.separated(
                                itemCount: regions.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final region = regions[index];
                                  return _RegionTile(
                                    region: region,
                                    loading: _savingRegionId == region.id,
                                    disabled: _savingRegionId != null,
                                    onTap: () =>
                                        unawaited(_selectRegion(region)),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Positioned(
            left: 16,
            top: 0,
            child: SafeArea(child: AppScreenBackButton()),
          ),
        ],
      ),
    );
  }
}

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({
    required this.stateCount,
    required this.unionTerritoryCount,
    required this.controller,
  });

  final int stateCount;
  final int unionTerritoryCount;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Select State / Union Territory',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$stateCount States • $unionTerritoryCount Union Territories',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search State, UT or language',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  final AppRegion region;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _regionColor(region);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    region.logoAssetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        region.name.characters.first,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      region.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      region.primaryLanguage,
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
              loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRegions extends StatelessWidget {
  const _EmptyRegions();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        strings.localized(
          telugu: 'సరిపోయే ప్రాంతం లేదు.',
          hindi: 'कोई मिलता-जुलता क्षेत्र नहीं मिला।',
          english: 'No matching region found.',
          tamil: 'பொருந்தும் பகுதி இல்லை.',
          kannada: 'ಹೊಂದುವ ಪ್ರದೇಶ ಕಂಡುಬಂದಿಲ್ಲ.',
          malayalam: 'ചേരുന്ന പ്രദേശം കണ്ടെത്തിയില്ല.',
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

Color _regionColor(AppRegion region) {
  return switch (region.appLanguage.supportedUiLanguage) {
    SupportedUiLanguage.telugu => const Color(0xFF0F766E),
    SupportedUiLanguage.hindi => const Color(0xFFB45309),
    SupportedUiLanguage.english => const Color(0xFF2563EB),
    SupportedUiLanguage.tamil => const Color(0xFFBE123C),
    SupportedUiLanguage.kannada => const Color(0xFF7C3AED),
    SupportedUiLanguage.malayalam => const Color(0xFF15803D),
  };
}
