import 'package:flutter/material.dart';

@immutable
class HomeCategoryCatalogEntry {
  const HomeCategoryCatalogEntry({
    required this.id,
    required this.label,
    required this.badge,
    required this.gradient,
    required this.sampleTitles,
    this.aliases = const <String>[],
    this.uploadable = true,
  });

  final String id;
  final String label;
  final String badge;
  final List<Color> gradient;
  final List<String> sampleTitles;
  final List<String> aliases;
  final bool uploadable;
}

class HomeCategoryCatalog {
  const HomeCategoryCatalog._();

  static const List<HomeCategoryCatalogEntry> all = <HomeCategoryCatalogEntry>[
    HomeCategoryCatalogEntry(
      id: 'all',
      label: 'All',
      badge: 'ALL',
      uploadable: false,
      gradient: <Color>[Color(0xFF111827), Color(0xFF6B7280)],
      sampleTitles: <String>['All posters', 'Mixed highlights', 'Latest uploads'],
      aliases: <String>['all posters', 'everything'],
    ),
    HomeCategoryCatalogEntry(
      id: 'good-night',
      label: 'Good Night',
      badge: 'PM',
      gradient: <Color>[Color(0xFF312E81), Color(0xFF818CF8)],
      sampleTitles: <String>['Night blessings', 'Moonlight wishes', 'Peaceful close'],
    ),
    HomeCategoryCatalogEntry(
      id: 'good-morning',
      label: 'Good Morning',
      badge: 'AM',
      gradient: <Color>[Color(0xFFFFB347), Color(0xFFFFE28A)],
      sampleTitles: <String>['Sunrise wishes', 'Daily good morning', 'Fresh start poster'],
    ),
    HomeCategoryCatalogEntry(
      id: 'motivational',
      label: 'Motivational',
      badge: 'GO',
      gradient: <Color>[Color(0xFF16A34A), Color(0xFFBBF7D0)],
      sampleTitles: <String>['Focus poster', 'Winning mindset', 'Daily motivation'],
    ),
    HomeCategoryCatalogEntry(
      id: 'love-quotes',
      label: 'Love Quotes',
      badge: 'LOVE',
      gradient: <Color>[Color(0xFFF43F5E), Color(0xFFFDA4AF)],
      sampleTitles: <String>['Romantic quote poster', 'Heartfelt messages', 'Love lines design'],
    ),
    HomeCategoryCatalogEntry(
      id: 'today-special',
      label: 'Today Special',
      badge: 'DAY',
      gradient: <Color>[Color(0xFF14B8A6), Color(0xFF99F6E4)],
      sampleTitles: <String>['Today event highlight', 'Special occasion card', 'Daily topic poster'],
    ),
    HomeCategoryCatalogEntry(
      id: 'birthdays',
      label: 'Birthdays',
      badge: 'BDAY',
      gradient: <Color>[Color(0xFFFB7185), Color(0xFFFBCFE8)],
      sampleTitles: <String>['Birthday surprise poster', 'Cake day wishes', 'Party celebration card'],
      aliases: <String>['birthday'],
    ),
    HomeCategoryCatalogEntry(
      id: 'life-advice',
      label: 'Life Advice',
      badge: 'LIFE',
      gradient: <Color>[Color(0xFF0F766E), Color(0xFF99F6E4)],
      sampleTitles: <String>['Life lesson poster', 'Thoughtful reminder', 'Everyday guidance'],
      aliases: <String>['life advice quotes', 'advice'],
    ),
    HomeCategoryCatalogEntry(
      id: 'gita-wisdom',
      label: 'Gita Wisdom',
      badge: 'GITA',
      gradient: <Color>[Color(0xFF0EA5E9), Color(0xFFBAE6FD)],
      sampleTitles: <String>['Gita wisdom poster', 'Spiritual verses', 'Daily gita quote'],
      aliases: <String>['bhagavad gita', 'gita', 'gita quotes'],
    ),
    HomeCategoryCatalogEntry(
      id: 'news',
      label: 'News',
      badge: 'NEWS',
      gradient: <Color>[Color(0xFF1D4ED8), Color(0xFF93C5FD)],
      sampleTitles: <String>['Breaking update', 'Headline story', 'Daily bulletin poster'],
    ),
    HomeCategoryCatalogEntry(
      id: 'devotional',
      label: 'Devotional',
      badge: 'BHAKTI',
      gradient: <Color>[Color(0xFFF97316), Color(0xFFFCD34D)],
      sampleTitles: <String>['Temple blessings', 'Bhakti wishes', 'Devotional art'],
      aliases: <String>['bhakti'],
    ),
    HomeCategoryCatalogEntry(
      id: 'mahabharata',
      label: 'Mahabharata',
      badge: 'EPIC',
      gradient: <Color>[Color(0xFF7C3AED), Color(0xFFC4B5FD)],
      sampleTitles: <String>['Epic dharma poster', 'Mahabharata quote', 'Warrior wisdom'],
      aliases: <String>['mahabharatam', 'maha bharatam'],
    ),
    HomeCategoryCatalogEntry(
      id: 'anniversary',
      label: 'Anniversary',
      badge: 'ANNI',
      gradient: <Color>[Color(0xFFE11D48), Color(0xFFFDA4AF)],
      sampleTitles: <String>['Anniversary wishes', 'Celebration couple card', 'Special memory poster'],
      aliases: <String>['anniversaries'],
    ),
    HomeCategoryCatalogEntry(
      id: 'good-thoughts',
      label: 'Good Thoughts',
      badge: 'THINK',
      gradient: <Color>[Color(0xFF0891B2), Color(0xFFCFFAFE)],
      sampleTitles: <String>['Positive thought card', 'Daily mind reset', 'Thoughtful poster'],
      aliases: <String>['good thought'],
    ),
    HomeCategoryCatalogEntry(
      id: 'bible',
      label: 'Bible',
      badge: 'WORD',
      gradient: <Color>[Color(0xFF92400E), Color(0xFFFDE68A)],
      sampleTitles: <String>['Bible verse poster', 'Faith message', 'Prayer artwork'],
    ),
    HomeCategoryCatalogEntry(
      id: 'islam',
      label: 'Islam',
      badge: 'NOOR',
      gradient: <Color>[Color(0xFF0F766E), Color(0xFF5EEAD4)],
      sampleTitles: <String>['Islamic wishes', 'Noor quote card', 'Prayer reminder'],
      aliases: <String>['islamic'],
    ),
    HomeCategoryCatalogEntry(
      id: 'new',
      label: 'New',
      badge: 'NEW',
      gradient: <Color>[Color(0xFF2563EB), Color(0xFFBFDBFE)],
      sampleTitles: <String>['Fresh upload', 'Latest collection', 'Just added poster'],
      aliases: <String>['latest'],
    ),
  ];

  static List<HomeCategoryCatalogEntry> get uploadable =>
      all.where((HomeCategoryCatalogEntry entry) => entry.uploadable).toList(
        growable: false,
      );

  static HomeCategoryCatalogEntry? byRawCategory(String raw) {
    final normalized = normalizeKey(raw);
    for (final HomeCategoryCatalogEntry entry in all) {
      if (entry.id == normalized) {
        return entry;
      }
      if (normalizeKey(entry.label) == normalized) {
        return entry;
      }
      for (final String alias in entry.aliases) {
        if (normalizeKey(alias) == normalized) {
          return entry;
        }
      }
    }
    return null;
  }

  static String canonicalLabel(String raw) {
    final entry = byRawCategory(raw);
    if (entry != null) {
      return entry.label;
    }
    return raw.replaceAll(_leadingDecorationsPattern, '').trim();
  }

  static String normalizeKey(String raw) {
    final sanitized = raw
        .replaceAll(_leadingDecorationsPattern, '')
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return sanitized;
  }

  static final RegExp _leadingDecorationsPattern = RegExp(
    r'^[^A-Za-z0-9]+',
    unicode: true,
  );
}
