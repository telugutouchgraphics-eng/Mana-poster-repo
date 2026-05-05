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
        final startMonth = event.startMonth;
        final startDay = event.startDay;
        if (startMonth == null || startDay == null) {
          return null;
        }
        final startDate = DateTime(year, startMonth, startDay);
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
}
