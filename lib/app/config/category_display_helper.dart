class CategoryDisplayHelper {
  const CategoryDisplayHelper._();

  static String withIcon(String id, String label) {
    final cleanLabel = stripIcon(label).trim();
    if (cleanLabel.isEmpty) {
      return cleanLabel;
    }
    if (_isPoliticalPartyCategory(id)) {
      return cleanLabel;
    }
    final icon = iconFor(id, cleanLabel);
    return '$icon $cleanLabel';
  }

  static String stripIcon(String label) {
    return label.replaceFirst(_leadingIconPattern, '').trim();
  }

  static String iconFor(String id, String label) {
    final key = id.trim().toLowerCase().replaceAll('-', '_');
    final text = label.toLowerCase();
    if (key.startsWith('party_')) return '';
    if (_iconsById.containsKey(key)) return _iconsById[key]!;
    if (key.startsWith('weekday_')) return '📅';
    if (key.contains('jayanthi') || text.contains('jayanthi')) return '🙏';
    if (key.contains('vardhanthi') || text.contains('vardhanthi')) return '🕯️';
    if (key.contains('festival') || text.contains('festival')) return '🎉';
    if (key.contains('regional') || text.contains('regional')) return '📍';
    if (key.contains('important') || text.contains('important')) return '⭐';
    if (text.contains('birthday')) return '🎂';
    if (text.contains('anniversary')) return '💞';
    if (text.contains('morning')) return '🌅';
    if (text.contains('afternoon')) return '☀️';
    if (text.contains('night')) return '🌙';
    if (text.contains('devotional') || text.contains('bhakti')) return '🙏';
    if (text.contains('bible')) return '✝️';
    if (text.contains('islam')) return '☪️';
    if (text.contains('joke') || text.contains('fun')) return '😂';
    return '✨';
  }

  static const Map<String, String> _iconsById = <String, String>{
    'all': '🏠',
    'good_morning': '🌅',
    'good_afternoon': '☀️',
    'good_night': '🌙',
    'motivational': '🔥',
    'love_quotes': '❤️',
    'today_special': '⭐',
    'birthdays': '🎂',
    'life_advice': '🧭',
    'gita_wisdom': '📖',
    'devotional': '🙏',
    'mahabharata': '🏹',
    'anniversary': '💞',
    'good_thoughts': '💡',
    'bible': '✝️',
    'islam': '☪️',
    'jokes': '😂',
    'new': '✨',
    'festival': '🎉',
    'jayanthi': '🙏',
    'vardhanthi': '🕯️',
    'important_day': '⭐',
    'regional_special': '📍',
    'weekday_special': '📅',
  };

  static final RegExp _leadingIconPattern = RegExp(
    r'^(?:🏠|🌅|☀️|🌙|🔥|❤️|⭐|🎂|🧭|📖|🙏|🏹|💞|💡|✝️|☪️|😂|✨|🎉|🕯️|📍|📅|🗳️)\s*',
    unicode: true,
  );

  static bool _isPoliticalPartyCategory(String id) {
    return id.trim().toLowerCase().replaceAll('-', '_').startsWith('party_');
  }
}
