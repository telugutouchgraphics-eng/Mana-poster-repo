class CategoryDisplayHelper {
  const CategoryDisplayHelper._();

  static const String _assetBase = 'assets/category_icons';

  static String withIcon(String id, String label) {
    return stripIcon(label).trim();
  }

  static String stripIcon(String label) {
    return label.replaceFirst(_leadingEmojiPattern, '').trim();
  }

  static String? assetPathFor(String id, String label) {
    final key = _normalize(id);
    final text = label.toLowerCase();
    if (key.startsWith('party_')) return null;
    final direct = _assetById[key];
    if (direct != null) return '$_assetBase/$direct.svg';
    if (key.startsWith('weekday_')) return '$_assetBase/tuesday_special.svg';
    if (key.contains('jayanthi') || text.contains('jayanthi')) {
      return '$_assetBase/devotional.svg';
    }
    if (key.contains('vardhanthi') || text.contains('vardhanthi')) {
      return '$_assetBase/devotional.svg';
    }
    if (key.contains('festival') || text.contains('festival')) {
      return '$_assetBase/festivals.svg';
    }
    if (key.contains('regional') || text.contains('regional')) {
      return '$_assetBase/today_special.svg';
    }
    if (key.contains('important') || text.contains('important')) {
      return '$_assetBase/today_special.svg';
    }
    if (text.contains('birthday')) return '$_assetBase/birthdays.svg';
    if (text.contains('anniversary')) return '$_assetBase/anniversary.svg';
    if (text.contains('morning')) return '$_assetBase/good_morning.svg';
    if (text.contains('afternoon')) return '$_assetBase/good_afternoon.svg';
    if (text.contains('evening')) return '$_assetBase/good_evening.svg';
    if (text.contains('night')) return '$_assetBase/good_night.svg';
    if (text.contains('devotional') || text.contains('bhakti')) {
      return '$_assetBase/devotional.svg';
    }
    if (text.contains('gita')) return '$_assetBase/gita_wisdom.svg';
    if (text.contains('mahabharata')) return '$_assetBase/mahabharata.svg';
    if (text.contains('bible')) return '$_assetBase/bible.svg';
    if (text.contains('islam')) return '$_assetBase/islam.svg';
    if (text.contains('joke') || text.contains('fun')) {
      return '$_assetBase/jokes.svg';
    }
    if (text.contains('motivation')) return '$_assetBase/motivational.svg';
    return '$_assetBase/today_special.svg';
  }

  static String iconFor(String id, String label) {
    return assetPathFor(id, label) ?? '';
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_');
  }

  static const Map<String, String> _assetById = <String, String>{
    'all': 'all',
    'good_morning': 'good_morning',
    'good_afternoon': 'good_afternoon',
    'good_evening': 'good_evening',
    'good_night': 'good_night',
    'motivational': 'motivational',
    'today_special': 'today_special',
    'birthdays': 'birthdays',
    'life_advice': 'life_advice',
    'gita_wisdom': 'gita_wisdom',
    'devotional': 'devotional',
    'mahabharata': 'mahabharata',
    'anniversary': 'anniversary',
    'good_thoughts': 'good_thoughts',
    'bible': 'bible',
    'islam': 'islam',
    'jokes': 'jokes',
    'new': 'more',
    'more': 'more',
    'festival': 'festivals',
    'festivals': 'festivals',
    'hindu_festival': 'hindu_festival',
    'bonalu': 'bonalu',
    'holidays': 'holidays',
    'jayanthi': 'devotional',
    'vardhanthi': 'devotional',
    'important_day': 'today_special',
    'regional_special': 'today_special',
    'weekday_special': 'tuesday_special',
  };

  static final RegExp _leadingEmojiPattern = RegExp(
    '^(?:[\\u2600-\\u27BF]|[\\uD83C-\\uDBFF][\\uDC00-\\uDFFF]|\\uFE0F|\\u200D)+\\s*',
    unicode: true,
  );
}
