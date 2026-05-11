import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_repository.dart';
import 'package:mana_poster/features/prehome/services/dynamic_lunar_event_dates.dart';

class DynamicCategoryService {
  const DynamicCategoryService({
    DynamicEventRepository repository = const LocalDynamicEventRepository(),
    this.daysBeforeEvent = 0,
  }) : _repository = repository;

  final DynamicEventRepository _repository;
  final int daysBeforeEvent;

  List<DynamicCategory> categoriesForDate(
    DateTime now, {
    AppLanguage language = AppLanguage.telugu,
    Set<DynamicEventScope>? allowedScopes,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final scopes = allowedScopes ?? DynamicEventScope.values.toSet();
    final seenSlugs = <String>{};
    final output = <DynamicCategory>[];

    _addUnique(output, seenSlugs, _weekdayCategory(today.weekday, language));

    final activeEvents =
        _repository
            .loadEvents()
            .where((event) => event.enabled)
            .where((event) => scopes.contains(event.scope))
            .where((event) => _isEventActive(event, today))
            .toList(growable: false)
          ..sort(_compareEvents);

    for (final event in activeEvents) {
      _addUnique(output, seenSlugs, _toCategory(event, language));
    }

    output.sort(_compareCategories);
    return output;
  }

  List<DynamicCategory> categoriesForSlugs(
    Iterable<String> slugs, {
    AppLanguage language = AppLanguage.telugu,
  }) {
    final normalizedSlugs = slugs
        .map(_normalizeToken)
        .where((item) => item.isNotEmpty)
        .toSet();
    if (normalizedSlugs.isEmpty) {
      return const <DynamicCategory>[];
    }

    final seenSlugs = <String>{};
    final output = <DynamicCategory>[];
    for (final event in _repository.loadEvents()) {
      final eventKeys = <String>{
        _normalizeToken(event.id),
        _normalizeToken(event.slug),
        ...event.tags.map(_normalizeToken),
      };
      if (eventKeys.any(normalizedSlugs.contains)) {
        _addUnique(output, seenSlugs, _toCategory(event, language));
      }
    }

    output.sort(_compareCategories);
    return output;
  }

  bool _isEventActive(DynamicCalendarEvent event, DateTime today) {
    if (!event.enabled) {
      return false;
    }
    switch (event.calendarType) {
      case DynamicCalendarType.gregorian:
        return _isGregorianEventActive(event, today);
      case DynamicCalendarType.lunarPlaceholder:
        return _isResolvedLunarEventActive(event, today);
    }
  }

  bool _isResolvedLunarEventActive(DynamicCalendarEvent event, DateTime today) {
    final resolved = resolvedLunarEventDatesForYear(today.year)[event.slug];
    if (resolved == null) {
      return false;
    }

    final eventStart = DateTime(today.year, resolved.month, resolved.day);
    final visibleStart = eventStart.subtract(Duration(days: daysBeforeEvent));
    final eventEnd = switch ((resolved.endMonth, resolved.endDay)) {
      (final int endMonth, final int endDay) => DateTime(
        today.year,
        endMonth,
        endDay,
      ),
      _ => eventStart.add(Duration(days: resolved.durationDays - 1)),
    };

    return !today.isBefore(visibleStart) && !today.isAfter(eventEnd);
  }

  bool _isGregorianEventActive(DynamicCalendarEvent event, DateTime today) {
    final eventStart = _resolveGregorianStartDate(event, today.year);
    if (eventStart == null) {
      return false;
    }
    final visibleStart = eventStart.subtract(Duration(days: daysBeforeEvent));
    final eventEnd = switch ((event.endMonth, event.endDay)) {
      (final int endMonth, final int endDay) => DateTime(
        today.year,
        endMonth,
        endDay,
      ),
      _ => eventStart.add(Duration(days: event.durationDays - 1)),
    };

    if (eventEnd.isBefore(eventStart)) {
      return !today.isBefore(visibleStart) ||
          !today.isAfter(DateTime(today.year, 12, 31)) ||
          !today.isBefore(DateTime(today.year, 1, 1)) &&
              !today.isAfter(eventEnd);
    }

    return !today.isBefore(visibleStart) && !today.isAfter(eventEnd);
  }

  DateTime? _resolveGregorianStartDate(DynamicCalendarEvent event, int year) {
    if (event.startMonth != null && event.startDay != null) {
      return DateTime(year, event.startMonth!, event.startDay!);
    }

    final weekOfMonth = event.weekOfMonth;
    final weekdayOfMonth = event.weekdayOfMonth;
    final startMonth = event.startMonth;
    if (startMonth == null || weekOfMonth == null || weekdayOfMonth == null) {
      return null;
    }

    final firstDay = DateTime(year, startMonth, 1);
    final offset = (weekdayOfMonth - firstDay.weekday + 7) % 7;
    final day = 1 + offset + ((weekOfMonth - 1) * 7);
    final resolved = DateTime(year, startMonth, day);
    return resolved.month == startMonth ? resolved : null;
  }

  int _compareEvents(DynamicCalendarEvent a, DynamicCalendarEvent b) {
    final priorityCompare = b.priority.compareTo(a.priority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortOrderCompare != 0) {
      return sortOrderCompare;
    }
    return a.slug.compareTo(b.slug);
  }

  int _compareCategories(DynamicCategory a, DynamicCategory b) {
    final priorityCompare = b.priority.compareTo(a.priority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortOrderCompare != 0) {
      return sortOrderCompare;
    }
    return a.slug.compareTo(b.slug);
  }

  void _addUnique(
    List<DynamicCategory> output,
    Set<String> seenSlugs,
    DynamicCategory category,
  ) {
    if (seenSlugs.add(category.slug)) {
      output.add(category);
    }
  }

  DynamicCategory _weekdayCategory(int weekday, AppLanguage language) {
    final slug = switch (weekday) {
      DateTime.monday => 'weekday_monday_special',
      DateTime.tuesday => 'weekday_tuesday_special',
      DateTime.wednesday => 'weekday_wednesday_special',
      DateTime.thursday => 'weekday_thursday_special',
      DateTime.friday => 'weekday_friday_special',
      DateTime.saturday => 'weekday_saturday_special',
      _ => 'weekday_sunday_special',
    };

    return DynamicCategory(
      id: slug,
      slug: slug,
      label: _weekdayLabel(weekday, language),
      type: DynamicCategoryType.weekdaySpecial,
      scope: DynamicEventScope.global,
      priority: 10,
      sortOrder: 10000,
      tags: <String>['weekday_special', 'today_special', slug],
    );
  }

  DynamicCategory _toCategory(
    DynamicCalendarEvent event,
    AppLanguage language,
  ) {
    final tags = <String>{
      event.slug,
      _normalizeToken(event.slug),
      ..._categoryTypeTags(event.type),
      ..._scopeTags(event.scope),
      ...event.tags.expand((tag) => <String>{tag, _normalizeToken(tag)}),
      ..._titleTags(event.title),
    }.where((value) => value.isNotEmpty).toList(growable: false);

    return DynamicCategory(
      id: event.id,
      slug: event.slug,
      label: event.title.resolve(language),
      type: event.type,
      scope: event.scope,
      priority: event.priority,
      sortOrder: event.sortOrder,
      tags: tags,
    );
  }

  String _weekdayLabel(int weekday, AppLanguage language) {
    switch (language) {
      case AppLanguage.telugu:
        return switch (weekday) {
          DateTime.monday => 'సోమవారం స్పెషల్',
          DateTime.tuesday => 'మంగళవారం స్పెషల్',
          DateTime.wednesday => 'బుధవారం స్పెషల్',
          DateTime.thursday => 'గురువారం స్పెషల్',
          DateTime.friday => 'శుక్రవారం స్పెషల్',
          DateTime.saturday => 'శనివారం స్పెషల్',
          _ => 'ఆదివారం స్పెషల్',
        };
      case AppLanguage.hindi:
        return switch (weekday) {
          DateTime.monday => 'सोमवार स्पेशल',
          DateTime.tuesday => 'मंगलवार स्पेशल',
          DateTime.wednesday => 'बुधवार स्पेशल',
          DateTime.thursday => 'गुरुवार स्पेशल',
          DateTime.friday => 'शुक्रवार स्पेशल',
          DateTime.saturday => 'शनिवार स्पेशल',
          _ => 'रविवार स्पेशल',
        };
      case AppLanguage.tamil:
        return switch (weekday) {
          DateTime.monday => 'திங்கட்கிழமை சிறப்பு',
          DateTime.tuesday => 'செவ்வாய்க்கிழமை சிறப்பு',
          DateTime.wednesday => 'புதன்கிழமை சிறப்பு',
          DateTime.thursday => 'வியாழக்கிழமை சிறப்பு',
          DateTime.friday => 'வெள்ளிக்கிழமை சிறப்பு',
          DateTime.saturday => 'சனிக்கிழமை சிறப்பு',
          _ => 'ஞாயிற்றுக்கிழமை சிறப்பு',
        };
      case AppLanguage.kannada:
        return switch (weekday) {
          DateTime.monday => 'ಸೋಮವಾರ ವಿಶೇಷ',
          DateTime.tuesday => 'ಮಂಗಳವಾರ ವಿಶೇಷ',
          DateTime.wednesday => 'ಬುಧವಾರ ವಿಶೇಷ',
          DateTime.thursday => 'ಗುರುವಾರ ವಿಶೇಷ',
          DateTime.friday => 'ಶುಕ್ರವಾರ ವಿಶೇಷ',
          DateTime.saturday => 'ಶನಿವಾರ ವಿಶೇಷ',
          _ => 'ಭಾನುವಾರ ವಿಶೇಷ',
        };
      case AppLanguage.malayalam:
        return switch (weekday) {
          DateTime.monday => 'തിങ്കളാഴ്ച സ്പെഷ്യൽ',
          DateTime.tuesday => 'ചൊവ്വാഴ്ച സ്പെഷ്യൽ',
          DateTime.wednesday => 'ബുധനാഴ്ച സ്പെഷ്യൽ',
          DateTime.thursday => 'വ്യാഴാഴ്ച സ്പെഷ്യൽ',
          DateTime.friday => 'വെള്ളിയാഴ്ച സ്പെഷ്യൽ',
          DateTime.saturday => 'ശനിയാഴ്ച സ്പെഷ്യൽ',
          _ => 'ഞായറാഴ്ച സ്പെഷ്യൽ',
        };
      case AppLanguage.english:
        return switch (weekday) {
          DateTime.monday => 'Monday Special',
          DateTime.tuesday => 'Tuesday Special',
          DateTime.wednesday => 'Wednesday Special',
          DateTime.thursday => 'Thursday Special',
          DateTime.friday => 'Friday Special',
          DateTime.saturday => 'Saturday Special',
          _ => 'Sunday Special',
        };
    }
  }

  String _normalizeToken(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Iterable<String> _categoryTypeTags(DynamicCategoryType type) {
    return switch (type) {
      DynamicCategoryType.festival => const <String>['festival', 'devotional'],
      DynamicCategoryType.jayanthi => const <String>[
        'jayanthi',
        'important_day',
        'today_special',
      ],
      DynamicCategoryType.vardhanthi => const <String>[
        'vardhanthi',
        'important_day',
        'today_special',
      ],
      DynamicCategoryType.importantDay => const <String>[
        'important_day',
        'today_special',
      ],
      DynamicCategoryType.weekdaySpecial => const <String>[
        'weekday_special',
        'today_special',
      ],
      DynamicCategoryType.regionalSpecial => const <String>[
        'regional_special',
        'important_day',
        'today_special',
      ],
    };
  }

  Iterable<String> _scopeTags(DynamicEventScope scope) {
    return switch (scope) {
      DynamicEventScope.india => const <String>['india'],
      DynamicEventScope.andhraPradesh => const <String>[
        'andhra_pradesh',
        'regional_special',
      ],
      DynamicEventScope.telangana => const <String>[
        'telangana',
        'regional_special',
      ],
      DynamicEventScope.bothTeluguStates => const <String>[
        'both_telugu_states',
        'regional_special',
      ],
      DynamicEventScope.global => const <String>['global'],
    };
  }

  Iterable<String> _titleTags(DynamicLocalizedTitle title) sync* {
    for (final value in <String>[title.telugu, title.english, title.hindi]) {
      final normalized = _normalizeToken(value);
      if (normalized.isNotEmpty) {
        yield normalized;
      }

      final words = value
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim()
          .split(RegExp(r'\s+'))
          .where((item) => item.isNotEmpty);
      for (final word in words) {
        final normalizedWord = _normalizeToken(word);
        if (normalizedWord.isNotEmpty) {
          yield normalizedWord;
        }
      }
    }
  }
}
