import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_seed.dart';

abstract class DynamicEventRepository {
  const DynamicEventRepository();

  List<DynamicCalendarEvent> loadEvents();
}

class LocalDynamicEventRepository implements DynamicEventRepository {
  const LocalDynamicEventRepository();

  static List<DynamicCalendarEvent>? _cachedEvents;

  @override
  List<DynamicCalendarEvent> loadEvents() {
    final cached = _cachedEvents;
    if (cached != null) {
      return cached;
    }
    final seen = <String>{};
    final output = <DynamicCalendarEvent>[];
    for (final event in buildCsvBackedDynamicEvents()) {
      if (seen.add(event.slug)) {
        output.add(event);
      }
    }
    return _cachedEvents = List<DynamicCalendarEvent>.unmodifiable(output);
  }
}
