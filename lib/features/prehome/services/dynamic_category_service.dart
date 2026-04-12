import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_repository.dart';
import 'package:mana_poster/features/prehome/services/dynamic_lunar_event_dates.dart';

class DynamicCategoryService {
  const DynamicCategoryService({
    DynamicEventRepository repository = const LocalDynamicEventRepository(),
    this.daysBeforeEvent = 2,
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

    final activeEvents = _repository
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
    final resolved = kResolvedLunarEventDates[today.year]?[event.slug];
    if (resolved == null) {
      return false;
    }

    final eventStart = DateTime(today.year, resolved.month, resolved.day);
    final visibleStart = eventStart.subtract(Duration(days: daysBeforeEvent));
    final eventEnd = switch ((resolved.endMonth, resolved.endDay)) {
      (final int endMonth, final int endDay) => DateTime(today.year, endMonth, endDay),
      _ => eventStart.add(Duration(days: resolved.durationDays - 1)),
    };

    return !today.isBefore(visibleStart) && !today.isAfter(eventEnd);
  }

  bool _isGregorianEventActive(DynamicCalendarEvent event, DateTime today) {
    final startMonth = event.startMonth;
    final startDay = event.startDay;
    if (startMonth == null || startDay == null) {
      return false;
    }

    final eventStart = DateTime(today.year, startMonth, startDay);
    final visibleStart = eventStart.subtract(Duration(days: daysBeforeEvent));
    final eventEnd = switch ((event.endMonth, event.endDay)) {
      (final int endMonth, final int endDay) => DateTime(today.year, endMonth, endDay),
      _ => eventStart.add(Duration(days: event.durationDays - 1)),
    };

    if (eventEnd.isBefore(eventStart)) {
      return !today.isBefore(visibleStart) ||
          !today.isAfter(DateTime(today.year, 12, 31)) ||
          !today.isBefore(DateTime(today.year, 1, 1)) && !today.isAfter(eventEnd);
    }

    return !today.isBefore(visibleStart) && !today.isAfter(eventEnd);
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

  DynamicCategory _toCategory(DynamicCalendarEvent event, AppLanguage language) {
    return DynamicCategory(
      id: event.id,
      slug: event.slug,
      label: event.title.resolve(language),
      type: event.type,
      scope: event.scope,
      priority: event.priority,
      sortOrder: event.sortOrder,
      tags: <String>[event.slug, event.type.name, event.scope.name, ...event.tags],
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
      case AppLanguage.english:
      case AppLanguage.tamil:
      case AppLanguage.kannada:
      case AppLanguage.malayalam:
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
}
