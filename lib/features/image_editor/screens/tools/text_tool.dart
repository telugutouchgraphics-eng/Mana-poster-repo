part of '../image_editor_screen.dart';

// ignore_for_file: unused_element

class _TextColorSelection {
  const _TextColorSelection({
    required this.textColor,
    required this.textGradientIndex,
  });

  final Color textColor;
  final int textGradientIndex;
}

class _TextColorPickerScreen extends StatefulWidget {
  const _TextColorPickerScreen({
    required this.colors,
    required this.gradients,
    required this.selectedColor,
    required this.selectedGradientIndex,
  });

  final List<Color> colors;
  final List<List<Color>> gradients;
  final Color selectedColor;
  final int selectedGradientIndex;

  @override
  State<_TextColorPickerScreen> createState() => _TextColorPickerScreenState();
}

class TextFontFullscreenOverlay extends StatefulWidget {
  const TextFontFullscreenOverlay({
    super.key,
    required this.selectedFontFamily,
    required this.teluguFonts,
    required this.englishFonts,
    required this.hindiFonts,
    required this.previewText,
  });

  final String selectedFontFamily;
  final List<String> teluguFonts;
  final List<String> englishFonts;
  final List<String> hindiFonts;
  final String previewText;

  @override
  State<TextFontFullscreenOverlay> createState() =>
      _TextFontFullscreenOverlayState();
}

class _TextFontFullscreenOverlayState extends State<TextFontFullscreenOverlay> {
  static const String _favoriteFontsStorageKey =
      'editor_font_picker_favorites_v1';
  static const String _recentFontsStorageKey = 'editor_font_picker_recent_v1';
  static const int _maxRecentFonts = 8;
  late final TextEditingController _searchController = TextEditingController();
  late String _selectedFont = widget.selectedFontFamily;
  final Set<String> _favoriteFonts = <String>{};
  final List<String> _recentFonts = <String>[];
  String _query = '';
  int _activeFontTab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.englishFonts.contains(widget.selectedFontFamily)) {
      _activeFontTab = 1;
    } else if (widget.hindiFonts.contains(widget.selectedFontFamily)) {
      _activeFontTab = 2;
    }
    _searchController.addListener(_handleSearchChanged);
    unawaited(_loadFavoriteFonts());
    unawaited(_loadRecentFonts());
    unawaited(_primeLegacyCacheState());
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _primeLegacyCacheState() async {
    await _ensureLegacyConversionCacheLoaded();
    unawaited(
      _prewarmLegacyFontsForText(
        widget.previewText,
        preferredFamilies: _favoriteFonts,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadFavoriteFonts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_favoriteFontsStorageKey)?.toSet() ?? <String>{};
    if (!mounted) {
      return;
    }
    setState(() {
      _favoriteFonts
        ..clear()
        ..addAll(
          stored.where((String family) => _allOverlayFonts.contains(family)),
        );
    });
    unawaited(
      _prewarmLegacyFontsForText(
        widget.previewText,
        preferredFamilies: _favoriteFonts,
      ),
    );
  }

  Future<void> _loadRecentFonts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_recentFontsStorageKey) ?? <String>[];
    final validFonts = _allOverlayFonts;
    if (!mounted) {
      return;
    }
    setState(() {
      _recentFonts
        ..clear()
        ..addAll(
          stored
              .where(validFonts.contains)
              .take(_maxRecentFonts)
              .toList(growable: false),
        );
    });
  }

  Future<void> _toggleFavoriteFont(String family) async {
    final nextFavorites = Set<String>.from(_favoriteFonts);
    if (!nextFavorites.add(family)) {
      nextFavorites.remove(family);
    }
    setState(() {
      _favoriteFonts
        ..clear()
        ..addAll(nextFavorites);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoriteFontsStorageKey,
      nextFavorites.toList()..sort(),
    );
  }

  Future<void> _rememberRecentFont(String family) async {
    final nextRecent = <String>[
      family,
      ..._recentFonts.where((String item) => item != family),
    ].take(_maxRecentFonts).toList(growable: false);
    if (mounted) {
      setState(() {
        _recentFonts
          ..clear()
          ..addAll(nextRecent);
      });
    } else {
      _recentFonts
        ..clear()
        ..addAll(nextRecent);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentFontsStorageKey, nextRecent);
  }

  List<String> _filteredFonts(List<String> source) {
    if (_query.isEmpty) {
      return source;
    }
    return source
        .where((String font) => font.toLowerCase().contains(_query))
        .toList(growable: false);
  }

  Set<String> get _allOverlayFonts => <String>{
    ...widget.teluguFonts,
    ...widget.englishFonts,
    ...widget.hindiFonts,
  };

  List<String> _fontsForActiveTab() {
    return switch (_activeFontTab) {
      1 => widget.englishFonts,
      2 => widget.hindiFonts,
      _ => widget.teluguFonts,
    };
  }

  String _activeTabLabel() {
    return switch (_activeFontTab) {
      1 => 'English Fonts',
      2 => 'Hindi Fonts',
      _ => 'Telugu Fonts',
    };
  }

  String _sampleForFontFamily(String family) {
    if (widget.hindiFonts.contains(family)) {
      return 'हिंदी नमस्ते 123';
    }
    if (widget.englishFonts.contains(family)) {
      return 'English Sample 123';
    }
    return 'తెలుగు శుభాకాంక్షలు 123';
  }

  @override
  Widget build(BuildContext context) {
    final tabFonts = _filteredFonts(_fontsForActiveTab());
    final recentFonts = _query.isEmpty
        ? _recentFonts.where(tabFonts.contains).toList(growable: false)
        : _filteredFonts(_recentFonts);
    final favoriteFonts = tabFonts
        .where((String family) => _favoriteFonts.contains(family))
        .toList(growable: false);
    final unicodeTeluguFonts = _activeFontTab == 0
        ? tabFonts
              .where(
                (String family) =>
                    _unicodeTeluguFontFamilies.contains(family) &&
                    !_favoriteFonts.contains(family) &&
                    !recentFonts.contains(family),
              )
              .toList(growable: false)
        : const <String>[];
    final legacyTeluguFonts = _activeFontTab == 0
        ? tabFonts
              .where(
                (String family) =>
                    _isLegacyTeluguFontFamily(family) &&
                    !_favoriteFonts.contains(family) &&
                    !recentFonts.contains(family),
              )
              .toList(growable: false)
        : const <String>[];
    final activeLanguageFonts = _activeFontTab == 0
        ? const <String>[]
        : tabFonts
              .where(
                (String family) =>
                    !_favoriteFonts.contains(family) &&
                    !recentFonts.contains(family),
              )
              .toList(growable: false);
    final teluguTabCount = _filteredFonts(widget.teluguFonts).length;
    final englishTabCount = _filteredFonts(widget.englishFonts).length;
    final hindiTabCount = _filteredFonts(widget.hindiFonts).length;
    return Material(
      color: Colors.transparent,
      child: EditorFullscreenOverlay(
        title: context.strings.localized(telugu: 'ఫాంట్స్', english: 'Fonts'),
        onBack: () => Navigator.of(context).pop(),
        onDone: () => Navigator.of(context).pop(_selectedFont),
        child: SafeArea(
          child: Container(
            color: const Color(0xFF2A2C31),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3D45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    cursorColor: const Color(0xFFE8EAED),
                    style: const TextStyle(
                      color: Color(0xFFE8EAED),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search font',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      prefixIconColor: const Color(0xFFCBD5E1),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _FontLanguageTabs(
                  activeIndex: _activeFontTab,
                  teluguCount: teluguTabCount,
                  englishCount: englishTabCount,
                  hindiCount: hindiTabCount,
                  onChanged: (index) => setState(() => _activeFontTab = index),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF202228),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF8B7FFF).withValues(alpha: 0.28),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        const Color(0xFF353842),
                        const Color(0xFF202228),
                      ],
                    ),
                  ),
                  child: Text(
                    widget.previewText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      fontFamily: _resolveTextRenderFontFamily(_selectedFont),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      if (recentFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Recent'),
                        ...recentFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      if (favoriteFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Favorites'),
                        ...favoriteFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      if (unicodeTeluguFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Unicode Telugu'),
                        ...unicodeTeluguFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      if (legacyTeluguFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel('Legacy Telugu'),
                        ...legacyTeluguFonts.map(_buildFontRow),
                        const SizedBox(height: 8),
                      ],
                      if (activeLanguageFonts.isNotEmpty) ...<Widget>[
                        _buildSectionLabel(_activeTabLabel()),
                        ...activeLanguageFonts.map(_buildFontRow),
                      ],
                      if (recentFonts.isEmpty &&
                          favoriteFonts.isEmpty &&
                          unicodeTeluguFonts.isEmpty &&
                          legacyTeluguFonts.isEmpty &&
                          activeLanguageFonts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Center(
                            child: Text(
                              'No fonts found',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF8B7FFF),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontRow(String family) {
    final selected = family == _selectedFont;
    final cachedReady = _hasCachedLegacyRenderText(
      text: widget.previewText,
      fontFamily: family,
    );
    final isFavorite = _favoriteFonts.contains(family);
    final secondaryLabel = _fontPickerSecondaryLabel(family);
    return _PressableSurface(
      onTap: () {
        setState(() {
          _selectedFont = family;
        });
        unawaited(_rememberRecentFont(family));
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF44475A) : const Color(0xFF33363D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF8B7FFF)
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.2 : 1,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF8B7FFF).withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF8B7FFF)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: _resolveTextRenderFontFamily(family),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    family,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: selected ? 0.98 : 0.84,
                      ),
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sampleForFontFamily(family),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _resolveTextRenderFontFamily(family),
                      fontSize: 16,
                      height: 1.05,
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (secondaryLabel.isNotEmpty)
              _FontMetaBadge(label: secondaryLabel),
            if (cachedReady) ...<Widget>[
              const SizedBox(width: 6),
              const _FontMetaBadge(label: 'Ready', accent: true),
            ],
            const SizedBox(width: 6),
            _PressableSurface(
              onTap: () => unawaited(_toggleFavoriteFont(family)),
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 26,
                height: 26,
                child: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 17,
                  color: isFavorite
                      ? const Color(0xFFFACC15)
                      : Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: Color(0xFFB6ADFF),
              ),
          ],
        ),
      ),
    );
  }
}

class _FontFilterPill extends StatelessWidget {
  const _FontFilterPill({
    required this.label,
    required this.count,
    required this.active,
  });

  final String label;
  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF4B4E56)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? const Color(0xFF8B7FFF).withValues(alpha: 0.36)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        '$label ${count > 0 ? count : ''}'.trim(),
        style: TextStyle(
          color: active
              ? const Color(0xFFF8FAFC)
              : Colors.white.withValues(alpha: 0.45),
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FontLanguageTabs extends StatelessWidget {
  const _FontLanguageTabs({
    required this.activeIndex,
    required this.teluguCount,
    required this.englishCount,
    required this.hindiCount,
    required this.onChanged,
  });

  final int activeIndex;
  final int teluguCount;
  final int englishCount;
  final int hindiCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <({String label, int count})>[
      (label: 'Telugu', count: teluguCount),
      (label: 'English', count: englishCount),
      (label: 'Hindi', count: hindiCount),
    ];
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF202228),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: _PressableSurface(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: activeIndex == index
                        ? const Color(0xFF7C3AED)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tabs[index].label} ${tabs[index].count}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: activeIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.58),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FontMetaBadge extends StatelessWidget {
  const _FontMetaBadge({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 94),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFF2563EB).withValues(alpha: 0.24)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent
              ? const Color(0xFF93C5FD).withValues(alpha: 0.26)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent
              ? const Color(0xFFBFDBFE)
              : Colors.white.withValues(alpha: 0.48),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TextColorPickerScreenState extends State<_TextColorPickerScreen> {
  late Color _selectedColor = widget.selectedColor;
  late int _selectedGradientIndex = widget.selectedGradientIndex;
  late HSVColor _selectedHsv = HSVColor.fromColor(widget.selectedColor);
  bool _isColorWheelDragging = false;
  late final TextEditingController _hexController = TextEditingController(
    text: _hexFromColor(widget.selectedColor),
  );

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setSolidColor(Color color, {bool syncHex = true}) {
    setState(() {
      _selectedColor = color;
      _selectedHsv = HSVColor.fromColor(color);
      _selectedGradientIndex = -1;
      if (syncHex) {
        _hexController.text = _hexFromColor(color);
      }
    });
  }

  void _setHsv(HSVColor hsv) {
    _setSolidColor(hsv.toColor());
  }

  void _applyHex() {
    final parsed = _parseHexColor(_hexController.text);
    if (parsed == null) {
      HapticFeedback.mediumImpact();
      return;
    }
    _setSolidColor(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return EditorFullscreenOverlay(
      title: context.strings.localized(
        telugu: 'టెక్స్ట్ కలర్స్',
        english: 'Text Colors',
      ),
      onDone: () {
        Navigator.of(context).pop(
          _TextColorSelection(
            textColor: _selectedColor,
            textGradientIndex: _selectedGradientIndex,
          ),
        );
      },
      onBack: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: ListView(
          physics: _isColorWheelDragging
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          children: <Widget>[
            _buildLabel('Solid color wheel'),
            const SizedBox(height: 12),
            Center(
              child: _ColorWheelPicker(
                hsvColor: _selectedHsv,
                onChanged: _setHsv,
                onInteractionChanged: (dragging) {
                  if (_isColorWheelDragging == dragging) {
                    return;
                  }
                  setState(() => _isColorWheelDragging = dragging);
                },
              ),
            ),
            const SizedBox(height: 14),
            _buildValueSlider(),
            const SizedBox(height: 14),
            _buildHexInput(),
            const SizedBox(height: 18),
            _buildPreview(),
            if (widget.gradients.isNotEmpty) ...<Widget>[
              const SizedBox(height: 22),
              _buildLabel('Gradient colors'),
              const SizedBox(height: 10),
              ...List<Widget>.generate(widget.gradients.length, (int index) {
                final selected = _selectedGradientIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PressableSurface(
                    onTap: () {
                      setState(() {
                        _selectedGradientIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.gradients[index],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.white24,
                          width: selected ? 2.2 : 1,
                        ),
                      ),
                      child: selected
                          ? const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedGradientIndex >= 0
                  ? 'Gradient ${_selectedGradientIndex + 1} selected'
                  : _hexFromColor(_selectedColor),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildLabel('Brightness'),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            min: 0,
            max: 100,
            divisions: 100,
            value: (_selectedHsv.value * 100).clamp(0, 100).toDouble(),
            activeColor: _selectedHsv.withValue(1).toColor(),
            inactiveColor: Colors.white24,
            onChanged: (value) =>
                _setHsv(_selectedHsv.withValue((value / 100).clamp(0.0, 1.0))),
          ),
        ),
      ],
    );
  }

  Widget _buildHexInput() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _hexController,
            cursorColor: Colors.white,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              labelText: 'HEX color code',
              hintText: '#FF3366',
              labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF93C5FD)),
              ),
            ),
            onSubmitted: (_) => _applyHex(),
          ),
        ),
        const SizedBox(width: 10),
        _PressableSurface(
          onTap: _applyHex,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF6D5DFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ColorWheelPicker extends StatefulWidget {
  const _ColorWheelPicker({
    required this.hsvColor,
    required this.onChanged,
    this.onInteractionChanged,
  });

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  final ValueChanged<bool>? onInteractionChanged;

  @override
  State<_ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<_ColorWheelPicker> {
  Offset? _previewPosition;
  HSVColor? _previewHsv;

  @override
  Widget build(BuildContext context) {
    const size = 248.0;
    const previewSize = 66.0;
    final preview = _previewPosition == null || _previewHsv == null
        ? null
        : _ColorMagnifierPreview(
            color: _previewHsv!.toColor(),
            hex: _hexFromColor(_previewHsv!.toColor()),
          );
    final previewLeft = _previewPosition == null
        ? 0.0
        : (_previewPosition!.dx + 18).clamp(0.0, size - previewSize);
    final previewTop = _previewPosition == null
        ? 0.0
        : (_previewPosition!.dy - previewSize - 16).clamp(
            0.0,
            size - previewSize,
          );

    return SizedBox(
      width: size,
      height: size + 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) {
              widget.onInteractionChanged?.call(true);
              _handle(details.localPosition, size);
            },
            onPanUpdate: (details) => _handle(details.localPosition, size),
            onPanEnd: (_) => _endInteraction(),
            onPanCancel: _endInteraction,
            onTapDown: (details) {
              widget.onInteractionChanged?.call(true);
              _handle(details.localPosition, size);
            },
            onTapUp: (_) => _endInteraction(),
            onTapCancel: _endInteraction,
            child: CustomPaint(
              size: const Size.square(size),
              painter: _ColorWheelPainter(widget.hsvColor),
            ),
          ),
          if (preview != null)
            Positioned(left: previewLeft, top: previewTop, child: preview),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _NeutralColorBubble(
                  label: 'Black',
                  color: Colors.black,
                  selected: widget.hsvColor.value <= 0.02,
                  onTap: () => _selectNeutral(Colors.black),
                ),
                const SizedBox(width: 14),
                _NeutralColorBubble(
                  label: 'White',
                  color: Colors.white,
                  selected:
                      widget.hsvColor.saturation <= 0.04 &&
                      widget.hsvColor.value >= 0.96,
                  onTap: () => _selectNeutral(Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handle(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    final vector = position - center;
    final radius = size / 2;
    final distance = vector.distance.clamp(0.0, radius);
    var hue = math.atan2(vector.dy, vector.dx) * 180 / math.pi;
    if (hue < 0) hue += 360;
    final saturation = (distance / radius).clamp(0.0, 1.0);
    final visibleValue = widget.hsvColor.value <= 0.001
        ? 1.0
        : widget.hsvColor.value;
    final next = widget.hsvColor
        .withHue(hue)
        .withSaturation(saturation)
        .withValue(visibleValue);
    setState(() {
      _previewPosition = Offset(
        position.dx.clamp(0.0, size),
        position.dy.clamp(0.0, size),
      );
      _previewHsv = next;
    });
    widget.onChanged(next);
  }

  void _selectNeutral(Color color) {
    HapticFeedback.selectionClick();
    widget.onInteractionChanged?.call(false);
    setState(() {
      _previewPosition = null;
      _previewHsv = null;
    });
    widget.onChanged(HSVColor.fromColor(color));
  }

  void _endInteraction() {
    widget.onInteractionChanged?.call(false);
    if (_previewPosition == null && _previewHsv == null) {
      return;
    }
    setState(() {
      _previewPosition = null;
      _previewHsv = null;
    });
  }
}

class _ColorMagnifierPreview extends StatelessWidget {
  const _ColorMagnifierPreview({required this.color, required this.hex});

  final Color color;
  final String hex;

  @override
  Widget build(BuildContext context) {
    final isLight = color.computeLuminance() > 0.72;
    return IgnorePointer(
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111827).withValues(alpha: 0.92),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.72),
            width: 2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.34)
                    : Colors.white.withValues(alpha: 0.55),
                width: 1.4,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              hex.substring(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeutralColorBubble extends StatelessWidget {
  const _NeutralColorBubble({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = color.toARGB32() == Colors.white.toARGB32();
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? const Color(0xFF38BDF8).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: selected
                ? const Color(0xFF38BDF8)
                : Colors.white.withValues(alpha: 0.18),
            width: selected ? 2 : 1,
          ),
        ),
        child: Tooltip(
          message: label,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isWhite
                    ? Colors.black.withValues(alpha: 0.40)
                    : Colors.white.withValues(alpha: 0.28),
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    color: isWhite ? Colors.black : Colors.white,
                    size: 19,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter(this.hsvColor);

  final HSVColor hsvColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final sweep = SweepGradient(
      colors: List<Color>.generate(
        361,
        (index) => HSVColor.fromAHSV(1, index.toDouble(), 1, 1).toColor(),
      ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = sweep.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          <Color>[Colors.white, Colors.white.withValues(alpha: 0)],
          <double>[0, 1],
        ),
    );
    final angle = hsvColor.hue * math.pi / 180;
    final handleRadius = hsvColor.saturation * radius;
    final handle = Offset(
      center.dx + (math.cos(angle) * handleRadius),
      center.dy + (math.sin(angle) * handleRadius),
    );
    canvas.drawCircle(
      handle,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      handle,
      6,
      Paint()
        ..color = hsvColor.toColor()
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) =>
      oldDelegate.hsvColor != hsvColor;
}

String _hexFromColor(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color? _parseHexColor(String input) {
  var value = input.trim().toUpperCase();
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 3) {
    value = value.split('').map((char) => '$char$char').join();
  }
  if (value.length != 6 && value.length != 8) {
    return null;
  }
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) {
    return null;
  }
  return Color(value.length == 6 ? (0xFF000000 | parsed) : parsed);
}
