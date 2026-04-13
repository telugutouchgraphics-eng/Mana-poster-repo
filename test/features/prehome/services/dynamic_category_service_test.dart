import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_repository.dart';

class _FakeDynamicEventRepository implements DynamicEventRepository {
  const _FakeDynamicEventRepository(this.events);

  final List<DynamicCalendarEvent> events;

  @override
  List<DynamicCalendarEvent> loadEvents() => events;
}

void main() {
  group('DynamicCategoryService', () {
    test('returns priority ordered recurring events with weekday category', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'important',
            slug: 'important_event',
            type: DynamicCategoryType.importantDay,
            scope: DynamicEventScope.india,
            priority: 90,
            sortOrder: 2,
            startMonth: 8,
            startDay: 15,
            title: DynamicLocalizedTitle(
              telugu: 'ప్రాధాన్య దినం',
              english: 'Important Event',
              hindi: 'महत्वपूर्ण दिन',
            ),
          ),
          DynamicCalendarEvent(
            id: 'secondary',
            slug: 'secondary_event',
            type: DynamicCategoryType.festival,
            scope: DynamicEventScope.bothTeluguStates,
            priority: 80,
            sortOrder: 1,
            startMonth: 8,
            startDay: 15,
            title: DynamicLocalizedTitle(
              telugu: 'రెండో ఈవెంట్',
              english: 'Secondary Event',
              hindi: 'दूसरा इवेंट',
            ),
          ),
        ]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 8, 15),
        language: AppLanguage.english,
      );

      expect(categories.map((item) => item.slug), <String>[
        'important_event',
        'secondary_event',
        'weekday_saturday_special',
      ]);
    });

    test('supports recurring duration ranges', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'range',
            slug: 'sankranti_range',
            type: DynamicCategoryType.festival,
            scope: DynamicEventScope.bothTeluguStates,
            priority: 95,
            sortOrder: 1,
            startMonth: 1,
            startDay: 14,
            durationDays: 3,
            title: DynamicLocalizedTitle(
              telugu: 'సంక్రాంతి',
              english: 'Sankranti',
              hindi: 'संक्रांति',
            ),
          ),
        ]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 1, 16),
        language: AppLanguage.english,
      );

      expect(
        categories.any((item) => item.slug == 'sankranti_range'),
        isTrue,
      );
    });

    test('filters events by scope', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'india',
            slug: 'india_event',
            type: DynamicCategoryType.importantDay,
            scope: DynamicEventScope.india,
            priority: 70,
            sortOrder: 1,
            startMonth: 6,
            startDay: 2,
            title: DynamicLocalizedTitle(
              telugu: 'ఇండియా ఈవెంట్',
              english: 'India Event',
              hindi: 'इंडिया इवेंट',
            ),
          ),
          DynamicCalendarEvent(
            id: 'ts',
            slug: 'telangana_event',
            type: DynamicCategoryType.regionalSpecial,
            scope: DynamicEventScope.telangana,
            priority: 99,
            sortOrder: 1,
            startMonth: 6,
            startDay: 2,
            title: DynamicLocalizedTitle(
              telugu: 'తెలంగాణ ఈవెంట్',
              english: 'Telangana Event',
              hindi: 'तेलंगाना इवेंट',
            ),
          ),
        ]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 6, 2),
        language: AppLanguage.english,
        allowedScopes: <DynamicEventScope>{DynamicEventScope.india},
      );

      expect(
        categories.any((item) => item.slug == 'telangana_event'),
        isFalse,
      );
      expect(categories.any((item) => item.slug == 'india_event'), isTrue);
    });

    test('resolves localized labels for hindi', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'hindi_event',
            slug: 'hindi_event',
            type: DynamicCategoryType.jayanthi,
            scope: DynamicEventScope.india,
            priority: 90,
            sortOrder: 1,
            startMonth: 10,
            startDay: 2,
            title: DynamicLocalizedTitle(
              telugu: 'జయంతి',
              english: 'Jayanti',
              hindi: 'जयंती',
            ),
          ),
        ]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 10, 2),
        language: AppLanguage.hindi,
      );

      expect(categories.first.label, 'जयंती');
    });

    test('ignores duplicate slugs safely', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'one',
            slug: 'duplicate_event',
            type: DynamicCategoryType.importantDay,
            scope: DynamicEventScope.india,
            priority: 80,
            sortOrder: 1,
            startMonth: 1,
            startDay: 1,
            title: DynamicLocalizedTitle(
              telugu: 'మొదటి',
              english: 'First',
              hindi: 'पहला',
            ),
          ),
          DynamicCalendarEvent(
            id: 'two',
            slug: 'duplicate_event',
            type: DynamicCategoryType.importantDay,
            scope: DynamicEventScope.india,
            priority: 79,
            sortOrder: 2,
            startMonth: 1,
            startDay: 1,
            title: DynamicLocalizedTitle(
              telugu: 'రెండోది',
              english: 'Second',
              hindi: 'दूसरा',
            ),
          ),
        ]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 1, 1),
        language: AppLanguage.english,
      );

      expect(
        categories.where((item) => item.slug == 'duplicate_event').length,
        1,
      );
    });
  });
}
