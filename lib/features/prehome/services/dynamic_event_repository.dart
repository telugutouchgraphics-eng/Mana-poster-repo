import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_seed.dart';

abstract class DynamicEventRepository {
  const DynamicEventRepository();

  List<DynamicCalendarEvent> loadEvents();
}

class LocalDynamicEventRepository implements DynamicEventRepository {
  const LocalDynamicEventRepository();

  @override
  List<DynamicCalendarEvent> loadEvents() {
    final seen = <String>{};
    final output = <DynamicCalendarEvent>[];
    for (final event in buildCsvBackedDynamicEvents()) {
      if (seen.add(event.slug)) {
        output.add(event);
      }
    }
    return output;
  }
}
