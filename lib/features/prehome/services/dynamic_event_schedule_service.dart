import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_repository.dart';
import 'package:mana_poster/features/prehome/services/dynamic_lunar_event_dates.dart';

class ResolvedDynamicEventSchedule {
  const ResolvedDynamicEventSchedule({
    required this.event,
    required this.startDate,
    required this.endDate,
    required this.visibleStart,
  });

  final DynamicCalendarEvent event;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime visibleStart;

  bool isVisibleOn(DateTime day) =>
      !day.isBefore(visibleStart) && !day.isAfter(endDate);

  bool occursInMonth(int month) =>
      startDate.month == month || endDate.month == month;
}

class DynamicEventScheduleService {
  const DynamicEventScheduleService({
    DynamicEventRepository repository = const LocalDynamicEventRepository(),
  }) : _repository = repository;

  final DynamicEventRepository _repository;

  List<ResolvedDynamicEventSchedule> schedulesForYear(
    int year, {
    int daysBeforeEvent = 0,
    Set<DynamicEventScope>? allowedScopes,
  }) {
    final scopes = allowedScopes ?? DynamicEventScope.values.toSet();
    final output = <ResolvedDynamicEventSchedule>[];

    for (final event in _repository.loadEvents()) {
      if (!event.enabled || !scopes.contains(event.scope)) {
        continue;
      }
      final resolved = _resolveEvent(event, year, daysBeforeEvent);
      if (resolved != null) {
        output.add(resolved);
      }
    }

    output.sort((a, b) {
      final dateCompare = a.startDate.compareTo(b.startDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      final priorityCompare = b.event.priority.compareTo(a.event.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.event.slug.compareTo(b.event.slug);
    });
    return output;
  }

  ResolvedDynamicEventSchedule? _resolveEvent(
    DynamicCalendarEvent event,
    int year,
    int daysBeforeEvent,
  ) {
    switch (event.calendarType) {
      case DynamicCalendarType.gregorian:
        final startDate = _resolveGregorianStartDate(event, year);
        if (startDate == null) {
          return null;
        }
        final endDate = switch ((event.endMonth, event.endDay)) {
          (final int endMonth, final int endDay) => DateTime(
            year,
            endMonth,
            endDay,
          ),
          _ => startDate.add(Duration(days: event.durationDays - 1)),
        };
        return ResolvedDynamicEventSchedule(
          event: event,
          startDate: startDate,
          endDate: endDate,
          visibleStart: startDate.subtract(Duration(days: daysBeforeEvent)),
        );
      case DynamicCalendarType.lunarPlaceholder:
        final resolved = resolvedLunarEventDatesForYear(year)[event.slug];
        if (resolved == null) {
          return null;
        }
        final startDate = DateTime(year, resolved.month, resolved.day);
        final endDate = switch ((resolved.endMonth, resolved.endDay)) {
          (final int endMonth, final int endDay) => DateTime(
            year,
            endMonth,
            endDay,
          ),
          _ => startDate.add(Duration(days: resolved.durationDays - 1)),
        };
        return ResolvedDynamicEventSchedule(
          event: event,
          startDate: startDate,
          endDate: endDate,
          visibleStart: startDate.subtract(Duration(days: daysBeforeEvent)),
        );
    }
  }

  DateTime? _resolveGregorianStartDate(DynamicCalendarEvent event, int year) {
    final startMonth = event.startMonth;
    final startDay = event.startDay;
    if (startMonth != null && startDay != null) {
      return DateTime(year, startMonth, startDay);
    }

    final weekOfMonth = event.weekOfMonth;
    final weekdayOfMonth = event.weekdayOfMonth;
    if (startMonth == null || weekOfMonth == null || weekdayOfMonth == null) {
      return null;
    }

    final firstDay = DateTime(year, startMonth, 1);
    final offset = (weekdayOfMonth - firstDay.weekday + 7) % 7;
    final day = 1 + offset + ((weekOfMonth - 1) * 7);
    final resolved = DateTime(year, startMonth, day);
    return resolved.month == startMonth ? resolved : null;
  }
}
