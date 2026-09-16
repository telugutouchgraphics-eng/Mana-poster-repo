// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HomePinnedFeedControls extends StatelessWidget {
  const _HomePinnedFeedControls({
    required this.categories,
    required this.activeCategorySlug,
    required this.scrollController,
    required this.onCategoryTap,
    required this.banners,
    required this.onBannerViewed,
    required this.showAdFallback,
    required this.shouldShowAdFallback,
    required this.homeRefreshing,
    required this.compact,
  });

  final List<_CategoryChipData> categories;
  final String activeCategorySlug;
  final ScrollController scrollController;
  final ValueChanged<String> onCategoryTap;
  final List<AppHomeBanner> banners;
  final ValueChanged<String> onBannerViewed;
  final bool showAdFallback;
  final bool shouldShowAdFallback;
  final bool homeRefreshing;
  final bool compact;
  static const double _categoryPanelHeight = 94;
  static const double _compactCategoryPanelHeight = 36;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF3F6FB)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: RepaintBoundary(
              child: SizedBox(
                height: compact
                    ? _compactCategoryPanelHeight
                    : _categoryPanelHeight,
                width: double.infinity,
                child: ClipRect(
                  child: _CategoryRowsScroller(
                    categories: categories,
                    activeCategorySlug: activeCategorySlug,
                    scrollController: scrollController,
                    onCategoryTap: onCategoryTap,
                    compact: compact,
                  ),
                ),
              ),
            ),
          ),
          if (!compact && banners.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            RepaintBoundary(
              child: _HomeHeroBanner(
                banners: banners,
                onBannerViewed: onBannerViewed,
              ),
            ),
          ] else if (!compact &&
              showAdFallback &&
              shouldShowAdFallback) ...<Widget>[
            const RepaintBoundary(
              child: _HomeBannerAdFallback(
                key: ValueKey<String>('home_banner_ad_fallback'),
              ),
            ),
          ],
          if (homeRefreshing)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }
}

class _CategoryRowsScroller extends StatefulWidget {
  const _CategoryRowsScroller({
    required this.categories,
    required this.activeCategorySlug,
    required this.scrollController,
    required this.onCategoryTap,
    required this.compact,
  });

  static const int _rowCount = 3;
  static const double _minChipWidth = 38;
  static const double _maxChipWidth = 184;
  static const double _maxSelectedMoreChipWidth = 132;
  static const double _maxDynamicChipWidth = 268;
  static const double _rowHeight = 30;
  static const double _rowGap = 1;
  static const double _columnGap = 3;
  static const int _layoutStrategyVersion = 3;

  final List<_CategoryChipData> categories;
  final String activeCategorySlug;
  final ScrollController scrollController;
  final ValueChanged<String> onCategoryTap;
  final bool compact;

  @override
  State<_CategoryRowsScroller> createState() => _CategoryRowsScrollerState();
}

class _CategoryRowsScrollerState extends State<_CategoryRowsScroller> {
  final Map<String, _CategoryChipSlot> _slotsBySlug =
      <String, _CategoryChipSlot>{};
  final Map<String, double> _slotWidthBySlug = <String, double>{};
  final List<List<String>> _slugRows = List<List<String>>.generate(
    _CategoryRowsScroller._rowCount,
    (_) => <String>[],
  );
  int _appliedLayoutStrategyVersion = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      final chips = _buildCompactRow();
      return SingleChildScrollView(
        key: const PageStorageKey<String>('home-category-horizontal-scroll'),
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          children: <Widget>[
            for (var index = 0; index < chips.length; index++) ...<Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: _CategoryRowsScroller._minChipWidth,
                  maxWidth: _CategoryRowsScroller._maxChipWidth,
                ),
                child: _CategoryChip(
                  data: chips[index],
                  isSelected:
                      chips[index].effectiveSelectionSlug ==
                      widget.activeCategorySlug,
                  onTap: () =>
                      widget.onCategoryTap(chips[index].effectiveSelectionSlug),
                ),
              ),
              if (index != chips.length - 1)
                const SizedBox(width: _CategoryRowsScroller._columnGap),
            ],
          ],
        ),
      );
    }
    final rows = _buildStableRows();
    return SingleChildScrollView(
      key: const PageStorageKey<String>('home-category-horizontal-scroll'),
      controller: widget.scrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
            Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == rows.length - 1
                    ? 0
                    : _CategoryRowsScroller._rowGap,
              ),
              child: SizedBox(
                height: _CategoryRowsScroller._rowHeight,
                child: Row(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < rows[rowIndex].length;
                      index++
                    ) ...<Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: _CategoryRowsScroller._minChipWidth,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: rows[rowIndex][index].isDynamic
                                ? _CategoryRowsScroller._maxDynamicChipWidth
                                : rows[rowIndex][index].slug ==
                                      _HomeScreenState
                                          ._selectedMoreCategorySlotSlug
                                ? _CategoryRowsScroller
                                      ._maxSelectedMoreChipWidth
                                : _CategoryRowsScroller._maxChipWidth,
                          ),
                          child: _CategoryChip(
                            key: ValueKey<String>(
                              'home-category-${rows[rowIndex][index].slug}',
                            ),
                            data: rows[rowIndex][index],
                            isSelected:
                                rows[rowIndex][index].effectiveSelectionSlug ==
                                widget.activeCategorySlug,
                            onTap: () => widget.onCategoryTap(
                              rows[rowIndex][index].effectiveSelectionSlug,
                            ),
                          ),
                        ),
                      ),
                      if (index != rows[rowIndex].length - 1)
                        const SizedBox(width: _CategoryRowsScroller._columnGap),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_CategoryChipData> _buildCompactRow() {
    final utility = <_CategoryChipData>[];
    final normal = <_CategoryChipData>[];
    final dynamic = <_CategoryChipData>[];
    for (final category in widget.categories) {
      if (category.slug == _HomeScreenState._moreCategorySlug ||
          category.selectionSlug != null ||
          category.slug == 'today_special' ||
          _HomeScreenState._morePopupCategorySlugs.contains(category.slug)) {
        utility.add(category);
      } else if (category.isDynamic) {
        dynamic.add(category);
      } else {
        normal.add(category);
      }
    }
    return <_CategoryChipData>[...normal, ...dynamic, ...utility];
  }

  List<List<_CategoryChipData>> _buildStableRows() {
    if (_appliedLayoutStrategyVersion !=
        _CategoryRowsScroller._layoutStrategyVersion) {
      _slotsBySlug.clear();
      _slotWidthBySlug.clear();
      for (final row in _slugRows) {
        row.clear();
      }
      _appliedLayoutStrategyVersion =
          _CategoryRowsScroller._layoutStrategyVersion;
    }
    final bySlug = <String, _CategoryChipData>{
      for (final category in widget.categories) category.slug: category,
    };
    _removeMissingSlugs(bySlug.keys.toSet());
    final newChips = widget.categories
        .where((category) => !_slotsBySlug.containsKey(category.slug))
        .toList(growable: false);
    _assignNewChips(newChips);
    _moveSelectedMoreSlotBeforeMore();
    return <List<_CategoryChipData>>[
      for (final row in _slugRows)
        <_CategoryChipData>[
          for (final slug in row)
            if (bySlug[slug] != null) bySlug[slug]!,
        ],
    ];
  }

  void _removeMissingSlugs(Set<String> visibleSlugs) {
    final missing = _slotsBySlug.keys
        .where((slug) => !visibleSlugs.contains(slug))
        .toList(growable: false);
    for (final slug in missing) {
      final slot = _slotsBySlug.remove(slug);
      _slotWidthBySlug.remove(slug);
      if (slot == null) {
        continue;
      }
      _slugRows[slot.row].remove(slug);
    }
    for (var rowIndex = 0; rowIndex < _slugRows.length; rowIndex++) {
      for (var index = 0; index < _slugRows[rowIndex].length; index++) {
        _slotsBySlug[_slugRows[rowIndex][index]] = _CategoryChipSlot(
          row: rowIndex,
          index: index,
        );
      }
    }
  }

  void _moveSelectedMoreSlotBeforeMore() {
    const selectedSlotSlug = _HomeScreenState._selectedMoreCategorySlotSlug;
    const moreSlotSlug = _HomeScreenState._moreCategorySlug;
    final selectedSlot = _slotsBySlug[selectedSlotSlug];
    final moreSlot = _slotsBySlug[moreSlotSlug];
    if (selectedSlot == null || moreSlot == null) {
      return;
    }
    final selectedRow = _slugRows[selectedSlot.row];
    final moreRow = _slugRows[moreSlot.row];
    final selectedIndex = selectedRow.indexOf(selectedSlotSlug);
    final moreIndex = moreRow.indexOf(moreSlotSlug);
    if (selectedIndex < 0 || moreIndex < 0) {
      return;
    }
    if (selectedSlot.row == moreSlot.row && selectedIndex == moreIndex - 1) {
      return;
    }
    selectedRow.removeAt(selectedIndex);
    final adjustedMoreIndex =
        selectedSlot.row == moreSlot.row && selectedIndex < moreIndex
        ? moreIndex - 1
        : moreIndex;
    moreRow.insert(adjustedMoreIndex, selectedSlotSlug);
    for (var rowIndex = 0; rowIndex < _slugRows.length; rowIndex++) {
      for (var index = 0; index < _slugRows[rowIndex].length; index++) {
        _slotsBySlug[_slugRows[rowIndex][index]] = _CategoryChipSlot(
          row: rowIndex,
          index: index,
        );
      }
    }
  }

  void _assignNewChips(List<_CategoryChipData> newChips) {
    if (newChips.isEmpty) {
      return;
    }
    _CategoryChipData? moreChip;
    final beforeMoreChips = <_CategoryChipData>[];
    final regularChips = <_CategoryChipData>[];

    for (final category in newChips) {
      if (category.slug == _HomeScreenState._moreCategorySlug) {
        moreChip = category;
      } else if (category.selectionSlug != null) {
        beforeMoreChips.add(category);
      } else if (_HomeScreenState._morePopupCategorySlugs.contains(
        category.slug,
      )) {
        beforeMoreChips.add(category);
      } else {
        regularChips.add(category);
      }
    }

    void appendToRow(int rowIndex, _CategoryChipData chip) {
      if (_slotsBySlug.containsKey(chip.slug)) {
        return;
      }
      final safeRowIndex = rowIndex.clamp(0, _slugRows.length - 1);
      final row = _slugRows[safeRowIndex];
      _slotsBySlug[chip.slug] = _CategoryChipSlot(
        row: safeRowIndex,
        index: row.length,
      );
      _slotWidthBySlug[chip.slug] = _estimatedChipWidth(chip);
      row.add(chip.slug);
    }

    void insertBeforeSlug(
      String targetSlug,
      int fallbackRowIndex,
      _CategoryChipData chip,
    ) {
      if (_slotsBySlug.containsKey(chip.slug)) {
        return;
      }
      final targetSlot = _slotsBySlug[targetSlug];
      if (targetSlot == null) {
        appendToRow(fallbackRowIndex, chip);
        return;
      }
      final row = _slugRows[targetSlot.row];
      final insertIndex = row.indexOf(targetSlug);
      if (insertIndex < 0) {
        appendToRow(fallbackRowIndex, chip);
        return;
      }
      row.insert(insertIndex, chip.slug);
      _slotWidthBySlug[chip.slug] = _estimatedChipWidth(chip);
      for (var index = insertIndex; index < row.length; index++) {
        _slotsBySlug[row[index]] = _CategoryChipSlot(
          row: targetSlot.row,
          index: index,
        );
      }
    }

    int shortestRowIndex() {
      var bestRow = 0;
      var bestWidth = double.infinity;
      for (var rowIndex = 0; rowIndex < _slugRows.length; rowIndex++) {
        final width = _rowEstimatedWidth(_slugRows[rowIndex]);
        if (width < bestWidth) {
          bestWidth = width;
          bestRow = rowIndex;
        }
      }
      return bestRow;
    }

    for (final chip in regularChips) {
      appendToRow(shortestRowIndex(), chip);
    }
    for (final chip in beforeMoreChips) {
      insertBeforeSlug(
        _HomeScreenState._moreCategorySlug,
        shortestRowIndex(),
        chip,
      );
    }
    if (moreChip != null) {
      appendToRow(shortestRowIndex(), moreChip);
    }
  }

  double _rowEstimatedWidth(List<String> row) {
    if (row.isEmpty) {
      return 0;
    }
    return row.fold<double>(
          0,
          (total, slug) => total + (_slotWidthBySlug[slug] ?? 96),
        ) +
        ((row.length - 1) * _CategoryRowsScroller._columnGap);
  }

  double _estimatedChipWidth(_CategoryChipData chip) {
    final cleanLabel = CategoryDisplayHelper.stripIcon(chip.label).trim();
    final dateExtra = (chip.dateLabel?.trim().isNotEmpty ?? false) ? 28 : 0;
    final iconExtra =
        chip.iconAssetPath != null ||
            CategoryDisplayHelper.assetPathFor(
                  chip.selectionSlug ?? chip.slug,
                  chip.label,
                ) !=
                null
        ? 22
        : 0;
    final rawWidth = 26 + iconExtra + dateExtra + (cleanLabel.length * 8.5);
    final maxWidth = chip.isDynamic
        ? _CategoryRowsScroller._maxDynamicChipWidth
        : chip.slug == _HomeScreenState._selectedMoreCategorySlotSlug
        ? _CategoryRowsScroller._maxSelectedMoreChipWidth
        : _CategoryRowsScroller._maxChipWidth;
    return rawWidth.clamp(_CategoryRowsScroller._minChipWidth, maxWidth);
  }
}

