import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_schedule_service.dart';

void main() {
  test('DynamicEventScheduleService resolves lunar event schedules including Dasara and Deepavali', () {
    final service = const DynamicEventScheduleService();
    final schedules = service.schedulesByTagForYear(2026);
    expect(schedules.containsKey('dasara_vijayadashami'), isTrue);
    final dasara = schedules['dasara_vijayadashami']!;
    expect(dasara.startDate.month, equals(10));
    expect(dasara.startDate.day, equals(20));
    final today = DateTime(2026, 10, 24);
    expect(today.isAfter(dasara.endDate), isTrue);

    expect(schedules.containsKey('deepavali'), isTrue);
    final deepavali = schedules['deepavali']!;
    expect(today.isAfter(deepavali.endDate), isFalse);
  });
}

