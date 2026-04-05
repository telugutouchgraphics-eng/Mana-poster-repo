import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/screens/page_setup_screen.dart';
import 'package:mana_poster/features/prehome/screens/profile_screen.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';

enum _HomeTab { free, premium }

class _TemplateItem {
  const _TemplateItem({
    required this.titleTe,
    required this.titleHi,
    required this.titleEn,
    required this.imageUrl,
    this.price,
  });

  final String titleTe;
  final String titleHi;
  final String titleEn;
  final String imageUrl;
  final int? price;

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
  bool _blinkOn = true;
  Timer? _blinkTimer;

  static const List<_TemplateItem> _freeTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'à°¶à±à°­à±‹à°¦à°¯à°‚ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤—à¥à¤¡ à¤®à¥‰à¤°à¥à¤¨à¤¿à¤‚à¤— à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Good Morning Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200',
    ),
    _TemplateItem(
      titleTe: 'à°¬à°°à±à°¤à±â€Œà°¡à±‡ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤¬à¤°à¥à¤¥à¤¡à¥‡ à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Birthday Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?w=1200',
    ),
    _TemplateItem(
      titleTe: 'à°¦à±ˆà°µà°­à°•à±à°¤à°¿ à°ªà±‹à°¸à±à°Ÿà°°à±',
      titleHi: 'à¤­à¤•à¥à¤¤à¤¿ à¤ªà¥‹à¤¸à¥à¤Ÿà¤°',
      titleEn: 'Devotional Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200',
    ),
  ];

  static const List<_TemplateItem> _premiumTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'à°ªà±à°°à±€à°®à°¿à°¯à°®à± à°ªà°¾à°²à°¿à°Ÿà°¿à°•à°²à± à°¡à°¿à°œà±ˆà°¨à±',
      titleHi: 'à¤ªà¥à¤°à¥€à¤®à¤¿à¤¯à¤® à¤ªà¥‰à¤²à¤¿à¤Ÿà¤¿à¤•à¤² à¤¡à¤¿à¤œà¤¼à¤¾à¤‡à¤¨',
      titleEn: 'Premium Political Design',
      imageUrl:
          'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?w=1200',
      price: 99,
    ),
    _TemplateItem(
      titleTe: 'à°ªà±à°°à±€à°®à°¿à°¯à°®à± à°«à±†à°¸à±à°Ÿà°¿à°µà°²à± à°—à±‹à°²à±à°¡à±',
      titleHi: 'à¤ªà¥à¤°à¥€à¤®à¤¿à¤¯à¤® à¤«à¥‡à¤¸à¥à¤Ÿà¤¿à¤µà¤² à¤—à¥‹à¤²à¥à¤¡',
      titleEn: 'Premium Festival Gold',
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200',
      price: 149,
    ),
    _TemplateItem(
      titleTe: 'à°ªà±à°°à±€à°®à°¿à°¯à°®à± à°ˆà°µà±†à°‚à°Ÿà± à°«à±à°²à°¯à°°à±',
      titleHi: 'à¤ªà¥à¤°à¥€à¤®à¤¿à¤¯à¤® à¤‡à¤µà¥‡à¤‚à¤Ÿ à¤«à¥à¤²à¤¾à¤¯à¤°',
      titleEn: 'Premium Event Flyer',
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200',
      price: 79,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _blinkOn = !_blinkOn);
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PageSetupScreen()),
    );
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final language = context.currentLanguage;
    final templates = _selectedTab == _HomeTab.free
        ? _freeTemplates
        : _premiumTemplates;

    final staticCategories = strings
        .homeCategories()
        .map((label) => _CategoryChipData(label: label))
        .toList(growable: false);
    final dynamicCategories = _buildDynamicCategories(DateTime.now(), language);
    final categories = <_CategoryChipData>[
      staticCategories.first,
      ...dynamicCategories,
      ...staticCategories.skip(1),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: Column(
        children: <Widget>[
          _HomeHeader(
            onCreateTap: _onCreateTap,
            onProfileTap: _openProfile,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
              children: <Widget>[
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => _CategoryChip(
                      data: categories[index],
                      blinkOn: _blinkOn,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HomeHeroBanner(title: strings.bannerTitle),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<_HomeTab>(
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
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.selected)
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                      side: const WidgetStatePropertyAll<BorderSide>(
                        BorderSide(color: Color(0xFFD9E2F1)),
                      ),
                      padding: const WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    onSelectionChanged: (value) {
                      setState(() => _selectedTab = value.first);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                ...templates.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _TemplateFeedItem(
                      item: item,
                      isPremium: _selectedTab == _HomeTab.premium,
                      language: language,
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
  });

  final VoidCallback onCreateTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF081C3A),
            Color(0xFF102B64),
            Color(0xFF1D4ED8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Mana Poster',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.homeTagline,
                      style: const TextStyle(
                        color: Color(0xFFD8E5FF),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onCreateTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F2C68),
                  minimumSize: const Size(94, 44),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  strings.createLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onProfileTap,
                icon: const Icon(Icons.person_outline_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x1FFFFFFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    hintText: strings.searchTemplates,
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFC7D7FF),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: <Widget>[
                    Expanded(
                      child: _HeaderStatCard(
                        value: 'HD',
                        label: 'Export',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _HeaderStatCard(
                        value: 'Fast',
                        label: 'Editor',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _HeaderStatCard(
                        value: 'Pro',
                        label: 'Layout',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeroBanner extends StatelessWidget {
  const _HomeHeroBanner({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1080 / 360,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x12233A76),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.network(
                'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1400',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xAA0F172A),
                      Color(0x663B82F6),
                      Color(0x220F172A),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Text(
                        'Premium Editor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fast canvas setup, clean editing tools, lightweight workflow.',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD8E5FF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
    final dynamicColor = data.isDynamic
        ? const Color(0xFFF59E0B)
        : const Color(0xFFE2E8F0);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: data.isBlinking ? (blinkOn ? 1.0 : 0.45) : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAll ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isAll ? const Color(0xFF0F172A) : dynamicColor,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          data.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isAll ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

class _TemplateFeedItem extends StatelessWidget {
  const _TemplateFeedItem({
    required this.item,
    required this.isPremium,
    required this.language,
  });

  final _TemplateItem item;
  final bool isPremium;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.network(item.imageUrl, fit: BoxFit.cover),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isPremium ? 'Premium' : 'Free',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.titleFor(language),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isPremium && item.price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'â‚¹${item.price}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9A6700),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isPremium)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          child: Text(strings.buyLabel),
                        ),
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
                                padding: const EdgeInsets.symmetric(vertical: 13),
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
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
