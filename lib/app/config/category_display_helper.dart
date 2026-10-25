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

    // 1. Political / Leadership Categories (Leadership Podium with Mic)
    if (key.contains('politic') ||
        text.contains('politic') ||
        text.contains('రాజకీయ')) {
      return '$_assetBase/politics.svg';
    }

    // 2. National / Flag / Patriotic Days (Waving Indian National Flag)
    if (key.contains('flag') ||
        key.contains('independence') ||
        key.contains('republic') ||
        key.contains('national') ||
        text.contains('తిరంగా') ||
        text.contains('జెండా') ||
        text.contains('జాతీయ')) {
      return '$_assetBase/indian_flag.svg';
    }

    // 3. Festivals & Ammavaru
    if (key.contains('ammavaru') ||
        key.contains('festival') ||
        text.contains('festival') ||
        text.contains('పండుగ') ||
        text.contains('దసరా') ||
        text.contains('నవరాత్రి')) {
      return '$_assetBase/festivals.svg';
    }

    // 4. Diwali / Deepam
    if (key.contains('diya') ||
        key.contains('diwali') ||
        key.contains('deepavali') ||
        text.contains('దీపావళి') ||
        text.contains('దీపం')) {
      return '$_assetBase/hindu_festival.svg';
    }

    // 5. Lord Ganesha
    if (key.contains('ganesh') ||
        key.contains('vinayak') ||
        text.contains('వినాయక') ||
        text.contains('గణపతి')) {
      return '$_assetBase/tuesday_special.svg';
    }

    // 6. Bonalu
    if (key.contains('bonalu') || text.contains('బోనాలు')) {
      return '$_assetBase/bonalu.svg';
    }

    // 7. Sankranti
    if (key.contains('sankranti') ||
        key.contains('pongal') ||
        text.contains('సంక్రాంతి') ||
        text.contains('పొంగల్')) {
      return '$_assetBase/sankranti.svg';
    }

    // 8. Devotional / Temple / Jayanthi
    if (key.contains('jayanthi') || text.contains('jayanthi')) {
      return '$_assetBase/devotional.svg';
    }
    if (key.contains('vardhanthi') || text.contains('vardhanthi')) {
      return '$_assetBase/devotional.svg';
    }
    if (text.contains('devotional') ||
        text.contains('bhakti') ||
        text.contains('భక్తి') ||
        text.contains('దేవాలయం')) {
      return '$_assetBase/devotional.svg';
    }

    // 9. Daily Greetings
    if (text.contains('morning') || text.contains('శుభోదయం')) {
      return '$_assetBase/good_morning.svg';
    }
    if (text.contains('afternoon') || text.contains('మధ్యాహ్నం')) {
      return '$_assetBase/good_afternoon.svg';
    }
    if (text.contains('evening') || text.contains('సాయంత్రం')) {
      return '$_assetBase/good_evening.svg';
    }
    if (text.contains('night') || text.contains('శుభరాత్రి')) {
      return '$_assetBase/good_night.svg';
    }

    // 10. Celebrations
    if (text.contains('birthday') || text.contains('పుట్టినరోజు')) {
      return '$_assetBase/birthdays.svg';
    }
    if (text.contains('anniversary') || text.contains('వివాహ')) {
      return '$_assetBase/anniversary.svg';
    }

    // 11. Scriptures & Faith
    if (text.contains('gita') || text.contains('గీత')) {
      return '$_assetBase/gita_wisdom.svg';
    }
    if (text.contains('mahabharata')) return '$_assetBase/mahabharata.svg';
    if (text.contains('bible')) return '$_assetBase/bible.svg';
    if (text.contains('islam')) return '$_assetBase/islam.svg';

    // 12. Entertainment & Motivation
    if (text.contains('joke') ||
        text.contains('fun') ||
        text.contains('హాస్యం')) {
      return '$_assetBase/jokes.svg';
    }
    if (text.contains('motivation') || text.contains('స్ఫూర్తి')) {
      return '$_assetBase/motivational.svg';
    }

    // 13. Special Days & Regional
    if (key.contains('important') ||
        text.contains('important') ||
        key.contains('regional') ||
        text.contains('regional')) {
      return '$_assetBase/today_special.svg';
    }

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
    'politics': 'politics',
    'political': 'politics',
    'indian_flag': 'indian_flag',
    'independence_day': 'indian_flag',
    'republic_day': 'indian_flag',
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
    'sankranti': 'sankranti',
    'ammavaru': 'festivals',
    'diya': 'hindu_festival',
    'ganesha': 'tuesday_special',
    'temple': 'devotional',
    'prayer': 'devotional',
    'birthday_cake': 'birthdays',
    'home': 'all',
  };

  static final RegExp _leadingEmojiPattern = RegExp(
    r'^(?:[\u2600-\u27BF]|[\uD83C-\uDBFF][\uDC00-\uDFFF]|\uFE0F|\u200D)+\s*',
    unicode: true,
  );
}
