import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';
import 'package:mana_poster/features/image_editor/screens/page_setup_screen.dart';
import 'package:mana_poster/features/prehome/models/premium_template_catalog.dart';
import 'package:mana_poster/features/prehome/models/remote_premium_template.dart';
import 'package:mana_poster/features/prehome/screens/profile_screen.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/premium_template_access_service.dart';
import 'package:mana_poster/features/prehome/services/premium_template_remote_service.dart';
import 'package:mana_poster/features/prehome/services/template_entitlement_backend_service.dart';
import 'package:mana_poster/features/prehome/services/template_purchase_gateway.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';

enum _HomeTab { free, premium }

class _TemplateItem {
  const _TemplateItem({
    required this.titleTe,
    required this.titleHi,
    required this.titleEn,
    this.imageUrl,
    this.imageAssetPath,
    this.price,
    this.templateId,
    this.templateDocumentSource,
    this.productId,
    this.fallbackProductIds = const <String>[],
    this.pageConfig,
  });

  final String titleTe;
  final String titleHi;
  final String titleEn;
  final String? imageUrl;
  final String? imageAssetPath;
  final int? price;
  final String? templateId;
  final String? templateDocumentSource;
  final String? productId;
  final List<String> fallbackProductIds;
  final EditorPageConfig? pageConfig;

  String titleFor(AppLanguage language) => switch (language) {
    AppLanguage.telugu => titleTe,
    AppLanguage.hindi => titleHi,
    AppLanguage.english => titleEn,
  };
}

class _CategoryChipData {
  const _CategoryChipData({
    required this.label,
    this.isDynamic = false,
    this.isBlinking = false,
  });

  final String label;
  final bool isDynamic;
  final bool isBlinking;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _HomeTab _selectedTab = _HomeTab.free;
  final DynamicCategoryService _dynamicCategoryService =
      const DynamicCategoryService();
  final PremiumTemplateAccessService _premiumTemplateAccessService =
      const PremiumTemplateAccessService();
  final PremiumTemplateRemoteService _premiumTemplateRemoteService =
      const PremiumTemplateRemoteService();
  final TemplateEntitlementBackendService _templateEntitlementBackendService =
      TemplateEntitlementBackendService();
  final TemplatePurchaseGateway _templatePurchaseGateway =
      TemplatePurchaseGateway();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _blinkOn = true;
  Timer? _blinkTimer;
  Set<String> _unlockedPremiumTemplateIds = <String>{};
  List<RemotePremiumTemplate> _remotePremiumTemplates =
      const <RemotePremiumTemplate>[];

  static const List<_TemplateItem> _freeTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'శుభోదయం పోస్టర్',
      titleHi: 'गुड मॉर्निंग पोस्टर',
      titleEn: 'Good Morning Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200',
    ),
    _TemplateItem(
      titleTe: 'బర్త్‌డే పోస్టర్',
      titleHi: 'बर्थडे पोस्टर',
      titleEn: 'Birthday Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?w=1200',
    ),
    _TemplateItem(
      titleTe: 'భక్తి పోస్టర్',
      titleHi: 'भक्ति पोस्टर',
      titleEn: 'Devotional Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200',
    ),
  ];

  // ignore: unused_field
  static const List<_TemplateItem> _premiumTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'ప్రీమియమ్ పొలిటికల్ డిజైన్',
      titleHi: 'प्रीमियम पॉलिटिकल डिज़ाइन',
      titleEn: 'Premium Political Design',
      imageUrl:
          'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?w=1200',
      price: 99,
    ),
    _TemplateItem(
      titleTe: 'ప్రీమియమ్ ఫెస్టివల్ గోల్డ్',
      titleHi: 'प्रीमियम फेस्टिवल गोल्ड',
      titleEn: 'Premium Festival Gold',
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200',
      price: 149,
    ),
    _TemplateItem(
      titleTe: 'ప్రీమియమ్ ఈవెంట్ ఫ్లయర్',
      titleHi: 'प्रीमियम इवेंट फ्लायर',
      titleEn: 'Premium Event Flyer',
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200',
      price: 79,
    ),
  ];

  List<_TemplateItem> get _premiumTemplateItems => premiumPoliticalTemplates
      .map(_mapLocalPremiumTemplate)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _blinkOn = !_blinkOn);
    });
    unawaited(_loadUnlockedPremiumTemplates());
    unawaited(_loadRemotePremiumTemplates());
    unawaited(_syncUnlockedTemplatesFromBackend());
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _matchesTemplate(_TemplateItem item, AppLanguage language) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final searchable = <String>[
      item.titleEn,
      item.titleHi,
      item.titleTe,
      item.titleFor(language),
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  List<_CategoryChipData> _buildDynamicCategories(
    DateTime now,
    AppLanguage language,
  ) {
    final generated = _dynamicCategoryService.categoriesForDate(
      now,
      language: language,
    );
    return generated
        .map(
          (item) => _CategoryChipData(
            label: item.label,
            isDynamic: true,
            isBlinking: item.isBlinking,
          ),
        )
        .toList();
  }

  void _onCreateTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PageSetupScreen()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  Future<void> _loadUnlockedPremiumTemplates() async {
    final unlocked = await _premiumTemplateAccessService
        .loadUnlockedTemplateIds();
    if (!mounted) {
      return;
    }
    setState(() => _unlockedPremiumTemplateIds = unlocked);
  }

  Future<void> _loadRemotePremiumTemplates() async {
    final remoteTemplates = await _premiumTemplateRemoteService
        .fetchPoliticalTemplates();
    if (!mounted || remoteTemplates.isEmpty) {
      return;
    }
    setState(() => _remotePremiumTemplates = remoteTemplates);
  }

  Future<void> _syncUnlockedTemplatesFromBackend() async {
    final result = await _templateEntitlementBackendService.fetchEntitlements();
    if (!mounted || !result.isSuccess || result.unlockedTemplateIds.isEmpty) {
      return;
    }
    final unlocked = await _premiumTemplateAccessService.unlockTemplates(
      result.unlockedTemplateIds,
    );
    if (!mounted) {
      return;
    }
    setState(() => _unlockedPremiumTemplateIds = unlocked);
  }

  _TemplateItem _mapLocalPremiumTemplate(PremiumTemplateDefinition template) {
    return _TemplateItem(
      titleTe: template.titleTe,
      titleHi: template.titleHi,
      titleEn: template.titleEn,
      imageAssetPath: template.previewAssetPath,
      price: template.priceInr,
      templateId: template.id,
      templateDocumentSource: template.templateDocumentAssetPath,
      productId: template.productId,
      pageConfig: template.pageConfig,
    );
  }

  _TemplateItem _mapRemotePremiumTemplate(RemotePremiumTemplate template) {
    return _TemplateItem(
      titleTe: template.titleTe,
      titleHi: template.titleHi,
      titleEn: template.titleEn,
      imageUrl: template.previewUrl,
      price: template.priceInr,
      templateId: template.id,
      templateDocumentSource: template.templateDocumentSource,
      productId: template.productId,
      fallbackProductIds: template.fallbackProductIds,
      pageConfig: template.pageConfig,
    );
  }

  bool _isTemplateUnlocked(_TemplateItem item) {
    final templateId = item.templateId;
    if (templateId == null || templateId.isEmpty) {
      return false;
    }
    return _unlockedPremiumTemplateIds.contains(templateId);
  }

  Future<void> _openPremiumTemplate(_TemplateItem item) async {
    final documentAsset = item.templateDocumentSource;
    final pageConfig = item.pageConfig;
    if (documentAsset == null || pageConfig == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageEditorScreen(
          pageConfig: pageConfig,
          templateDocumentSource: documentAsset,
        ),
      ),
    );
  }

  Future<void> _handlePremiumTemplateAction(_TemplateItem item) async {
    final templateId = item.templateId;
    final productId = item.productId;
    if (templateId == null || templateId.isEmpty) {
      return;
    }

    if (_isTemplateUnlocked(item)) {
      await _openPremiumTemplate(item);
      return;
    }
    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template product id configure cheyyali')),
      );
      return;
    }

    final outcome = await _templatePurchaseGateway.purchaseTemplate(
      productId: productId,
      fallbackProductIds: item.fallbackProductIds,
    );
    if (!mounted) {
      return;
    }
    switch (outcome.result) {
      case PurchaseFlowResult.success:
        final purchasedProductId = outcome.evidence?.productId ?? productId;
        Set<String> unlocked;
        final evidence = outcome.evidence;
        if (evidence != null && _templateEntitlementBackendService.isConfigured) {
          final verifyResult = await _templateEntitlementBackendService
              .verifyPurchase(templateId: templateId, evidence: evidence);
          if (!mounted) {
            return;
          }
          if (verifyResult.isSuccess) {
            unlocked = await _premiumTemplateAccessService.unlockTemplates(
              verifyResult.unlockedTemplateIds.isEmpty
                  ? <String>{templateId}
                  : verifyResult.unlockedTemplateIds,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  verifyResult.message?.isNotEmpty == true
                      ? 'Verification fail: ${verifyResult.message}'
                      : 'Payment verify avvaledu',
                ),
              ),
            );
            return;
          }
        } else {
          unlocked = await _premiumTemplateAccessService.unlockTemplateForProduct(
            templateId: templateId,
            productId: purchasedProductId,
          );
        }
        if (!mounted) {
          return;
        }
        setState(() => _unlockedPremiumTemplateIds = unlocked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment success. Edit unlocked.')),
        );
        await _openPremiumTemplate(item);
      case PurchaseFlowResult.cancelled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancel chesaru')),
        );
      case PurchaseFlowResult.billingUnavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Billing service available ledu')),
        );
      case PurchaseFlowResult.productNotFound:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Play Console product dorakaledu')),
        );
      case PurchaseFlowResult.timedOut:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment response timeout ayyindi')),
        );
      case PurchaseFlowResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment fail ayyindi')),
        );
      case PurchaseFlowResult.nothingToRestore:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase restore avvaledu')),
        );
    }
  }

  Future<void> _handleRestorePremiumPurchases(
    List<_TemplateItem> premiumTemplates,
  ) async {
    final productToTemplateId = <String, String>{};
    for (final item in premiumTemplates) {
      final templateId = item.templateId;
      final productId = item.productId;
      if (templateId == null ||
          templateId.isEmpty ||
          productId == null ||
          productId.isEmpty) {
        continue;
      }
      productToTemplateId[productId] = templateId;
      for (final fallbackProductId in item.fallbackProductIds) {
        if (fallbackProductId.isNotEmpty) {
          productToTemplateId[fallbackProductId] = templateId;
        }
      }
    }

    if (productToTemplateId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore cheyadaniki products levu')),
      );
      return;
    }

    final restoredProductIds = await _templatePurchaseGateway
        .restoreTemplateProductIds(productToTemplateId.keys.toSet());
    if (!mounted) {
      return;
    }
    if (restoredProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore purchases dorakaledu')),
      );
      return;
    }

    final restoredTemplateIds = restoredProductIds
        .map((productId) => productToTemplateId[productId])
        .whereType<String>()
        .toSet();
    final unlocked = await _premiumTemplateAccessService.unlockTemplates(
      restoredTemplateIds,
    );
    if (!mounted) {
      return;
    }
    setState(() => _unlockedPremiumTemplateIds = unlocked);
    unawaited(_syncUnlockedTemplatesFromBackend());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${restoredTemplateIds.length} premium design(s) restore ayyayi',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final language = context.currentLanguage;
    final isPremiumTab = _selectedTab == _HomeTab.premium;
    final premiumTemplates = _remotePremiumTemplates.isNotEmpty
        ? _remotePremiumTemplates
              .map(_mapRemotePremiumTemplate)
              .toList(growable: false)
        : _premiumTemplateItems;
    final templates = (isPremiumTab ? premiumTemplates : _freeTemplates)
        .where((item) => _matchesTemplate(item, language))
        .toList(growable: false);

    final staticCategories = strings
        .homeCategories()
        .map((label) => _CategoryChipData(label: label))
        .toList(growable: false);
    final dynamicCategories = _buildDynamicCategories(DateTime.now(), language);
    final leadingCategory = staticCategories.isNotEmpty
        ? staticCategories.first
        : const _CategoryChipData(label: 'All');
    final categories = <_CategoryChipData>[
      leadingCategory,
      ...dynamicCategories,
      ...staticCategories.skip(1),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: Column(
        children: <Widget>[
          RepaintBoundary(
            child: _HomeHeader(
              onCreateTap: _onCreateTap,
              onProfileTap: _openProfile,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
              children: <Widget>[
                RepaintBoundary(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (_, index) => _CategoryChip(
                        data: categories[index],
                        blinkOn: _blinkOn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                RepaintBoundary(
                  child: const _HomeHeroBanner(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E2F1)),
                    ),
                    child: SegmentedButton<_HomeTab>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<_HomeTab>>[
                        ButtonSegment<_HomeTab>(
                          value: _HomeTab.free,
                          label: Text(strings.freeTab),
                        ),
                        ButtonSegment<_HomeTab>(
                          value: _HomeTab.premium,
                          label: Text(strings.premiumTab),
                        ),
                      ],
                      selected: <_HomeTab>{_selectedTab},
                      style: ButtonStyle(
                        animationDuration: const Duration(milliseconds: 180),
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>(
                              (states) => states.contains(WidgetState.selected)
                                  ? const Color(0xFF0F172A)
                                  : const Color(0x00000000),
                            ),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color?>(
                              (states) => states.contains(WidgetState.selected)
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                        side: const WidgetStatePropertyAll<BorderSide>(
                          BorderSide(color: Colors.transparent),
                        ),
                        shape: WidgetStatePropertyAll<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        textStyle: const WidgetStatePropertyAll<TextStyle>(
                          TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        padding: const WidgetStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      onSelectionChanged: (value) {
                        final nextTab = value.first;
                        if (nextTab == _selectedTab) {
                          return;
                        }
                        setState(() => _selectedTab = nextTab);
                      },
                    ),
                  ),
                ),
                if (isPremiumTab)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            _handleRestorePremiumPurchases(premiumTemplates),
                        icon: const Icon(Icons.restore_rounded),
                        label: const Text('Restore Purchases'),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                if (templates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _HomeFeedState(
                      icon: Icons.search_off_rounded,
                      title: 'No templates found',
                      subtitle:
                          'Try another keyword or switch between Free and Premium.',
                    ),
                  )
                else
                  ...templates.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RepaintBoundary(
                        child: _TemplateFeedItem(
                          key: ValueKey<String>(
                            '${item.titleEn}-${item.imageUrl ?? item.imageAssetPath}-$isPremiumTab',
                          ),
                          item: item,
                          isPremium: isPremiumTab,
                          isUnlocked: !isPremiumTab || _isTemplateUnlocked(item),
                          language: language,
                          onPrimaryAction: isPremiumTab
                              ? () => _handlePremiumTemplateAction(item)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onCreateTap,
    required this.onProfileTap,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
  });

  final VoidCallback onCreateTap;
  final VoidCallback onProfileTap;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF4C1D95),
            Color(0xFF6D28D9),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mana Poster',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: IconButton(
                  onPressed: onProfileTap,
                  icon: const Icon(Icons.person_outline_rounded),
                  color: Colors.white,
                  iconSize: 20,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.homeTagline,
            style: const TextStyle(
              color: Color(0xFFF3E8FF),
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  onTapOutside: (_) => searchFocusNode.unfocus(),
                  decoration: InputDecoration(
                    hintText: strings.searchTemplates,
                    hintStyle: const TextStyle(
                      color: Color(0xFF7C6AA9),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF6B5CA3),
                    ),
                    fillColor: Colors.white.withValues(alpha: 0.96),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFE9D5FF),
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onCreateTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5B21B6),
                  minimumSize: const Size(96, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  strings.createLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerSlideData {
  const _BannerSlideData({
    required this.imageUrl,
  });

  final String imageUrl;
}

class _HomeHeroBanner extends StatefulWidget {
  const _HomeHeroBanner();

  @override
  State<_HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<_HomeHeroBanner> {
  static const List<_BannerSlideData> _slides = <_BannerSlideData>[
    _BannerSlideData(
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1400',
    ),
    _BannerSlideData(
      imageUrl:
          'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?w=1400',
    ),
    _BannerSlideData(
      imageUrl:
          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=1400',
    ),
  ];

  late final PageController _pageController = PageController();
  Timer? _autoSwipeTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients || _slides.length <= 1) {
        return;
      }
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 360;
        final bannerHeight = compact ? 106.0 : 112.0;

        return SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                PageView.builder(
                  controller: _pageController,
                  padEnds: false,
                  itemCount: _slides.length,
                  onPageChanged: (int index) {
                    if (_currentPage == index) {
                      return;
                    }
                    _currentPage = index;
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final slide = _slides[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image.network(
                          slide.imageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          loadingBuilder:
                              (
                                BuildContext context,
                                Widget child,
                                ImageChunkEvent? loadingProgress,
                              ) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return const _ImageLoadingState();
                              },
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) {
                                return const _ImageErrorState(
                                  compact: true,
                                  title: 'Banner unavailable',
                                  subtitle: 'Please try again shortly.',
                                );
                              },
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: <Color>[
                                Color(0x260F172A),
                                Color(0x1A1E293B),
                                Color(0x0A1E293B),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.data, required this.blinkOn});

  final _CategoryChipData data;
  final bool blinkOn;

  @override
  Widget build(BuildContext context) {
    final isAll = data.label == 'All';
    final chipTint = isAll
        ? const Color(0xFF0F172A)
        : data.isDynamic
        ? const Color(0xFFFFF4DB)
        : Colors.white;
    final borderColor = isAll
        ? const Color(0xFF0F172A)
        : data.isDynamic
        ? const Color(0xFFF2C66D)
        : const Color(0xFFDCE6F3);
    final textColor = isAll
        ? Colors.white
        : data.isDynamic
        ? const Color(0xFF8A5A00)
        : const Color(0xFF334155);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: data.isBlinking ? (blinkOn ? 1.0 : 0.45) : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipTint,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isAll ? const Color(0x140F172A) : const Color(0x0A0F172A),
              blurRadius: isAll ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          data.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isAll ? FontWeight.w700 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _TemplateFeedItem extends StatelessWidget {
  const _TemplateFeedItem({
    super.key,
    required this.item,
    required this.isPremium,
    required this.isUnlocked,
    required this.language,
    this.onPrimaryAction,
  });

  final _TemplateItem item;
  final bool isPremium;
  final bool isUnlocked;
  final AppLanguage language;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRect(
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: item.imageAssetPath != null
                  ? Image.asset(
                      item.imageAssetPath!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const _ImageErrorState(
                        title: 'Template image unavailable',
                        subtitle: 'Please refresh or try another template.',
                      ),
                    )
                  : Image.network(
                      item.imageUrl ?? '',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      loadingBuilder:
                          (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const _ImageLoadingState();
                          },
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return const _ImageErrorState(
                              title: 'Template image unavailable',
                              subtitle:
                                  'Please refresh or try another template.',
                            );
                          },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.titleFor(language),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          if (isPremium)
            Row(
              children: <Widget>[
                if (item.price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD89A)),
                    ),
                    child: Text(
                      '\u20B9${item.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A6700),
                      ),
                    ),
                  ),
                if (item.price != null) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isUnlocked
                          ? 'Edit'
                          : 'Buy ₹${item.price ?? 499}',
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.whatshot_rounded),
                    label: Text(strings.shareWhatsApp),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFD8E2F0)),
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded),
                    label: Text(strings.downloadLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HomeFeedState extends StatelessWidget {
  const _HomeFeedState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageLoadingState extends StatelessWidget {
  const _ImageLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3F8),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }
}

class _ImageErrorState extends StatelessWidget {
  const _ImageErrorState({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 20,
        vertical: compact ? 10 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.image_not_supported_outlined,
            color: const Color(0xFF94A3B8),
            size: compact ? 22 : 28,
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12.5 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              height: 1.35,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
