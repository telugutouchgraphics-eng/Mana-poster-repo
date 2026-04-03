import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/editor/screens/editor_screen.dart';
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
      titleTe: 'దైవభక్తి పోస్టర్',
      titleHi: 'भक्ति पोस्टर',
      titleEn: 'Devotional Poster',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200',
    ),
  ];

  static const List<_TemplateItem> _premiumTemplates = <_TemplateItem>[
    _TemplateItem(
      titleTe: 'ప్రీమియమ్ పాలిటికల్ డిజైన్',
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

  void _openEditor() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditorScreen()));
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
      body: Column(
        children: <Widget>[
          _HomeHeader(onCreateTap: _openEditor, onProfileTap: _openProfile),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
              children: <Widget>[
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => _CategoryChip(
                      data: categories[index],
                      blinkOn: _blinkOn,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1080 / 300,
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
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: <Color>[
                              Color(0x88000000),
                              Color(0x11000000),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Text(
                          strings.bannerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    onSelectionChanged: (value) {
                      setState(() => _selectedTab = value.first);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ...templates.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
  const _HomeHeader({required this.onCreateTap, required this.onProfileTap});

  final VoidCallback onCreateTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, topInset + 16, 12, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF132A6B),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.homeTagline,
                      style: const TextStyle(
                        color: Color(0xFFDCE8FF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onCreateTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  minimumSize: const Size(72, 42),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(strings.createLabel),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: onProfileTap,
                icon: const Icon(Icons.person_outline_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x26FFFFFF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: strings.searchTemplates,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFC7D7FF),
                  width: 1.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAll ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isAll ? const Color(0xFF1E3A8A) : dynamicColor,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x110F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.network(item.imageUrl, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.titleFor(language),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isPremium && item.price != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '₹${item.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A6700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isPremium)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {},
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded),
                    label: Text(strings.downloadLabel),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
