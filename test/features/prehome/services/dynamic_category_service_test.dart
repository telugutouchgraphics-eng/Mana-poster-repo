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

      expect(categories.any((item) => item.slug == 'sankranti_range'), isTrue);
    });

    test('weekday categories do not use broad today special tags', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 7, 20),
        language: AppLanguage.english,
      );
      final monday = categories.singleWhere(
        (item) => item.slug == 'weekday_monday_special',
      );

      expect(monday.tags, contains('weekday_monday_special'));
      expect(monday.tags, contains('weekday_special'));
      expect(monday.tags, isNot(contains('today_special')));
      expect(monday.tags, isNot(contains('important_day')));
    });

    test('dynamic event categories keep category tags exact', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'festival_exact',
            slug: 'festival_exact',
            type: DynamicCategoryType.festival,
            scope: DynamicEventScope.india,
            priority: 90,
            sortOrder: 1,
            startMonth: 7,
            startDay: 20,
            title: DynamicLocalizedTitle(
              telugu: 'Festival Exact',
              english: 'Festival Exact',
              hindi: 'Festival Exact',
            ),
          ),
          DynamicCalendarEvent(
            id: 'jayanthi_exact',
            slug: 'jayanthi_exact',
            type: DynamicCategoryType.jayanthi,
            scope: DynamicEventScope.india,
            priority: 89,
            sortOrder: 2,
            startMonth: 7,
            startDay: 20,
            title: DynamicLocalizedTitle(
              telugu: 'Jayanthi Exact',
              english: 'Jayanthi Exact',
              hindi: 'Jayanthi Exact',
            ),
          ),
        ]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 7, 20),
        language: AppLanguage.english,
      );
      final festival = categories.singleWhere(
        (item) => item.slug == 'festival_exact',
      );
      final jayanthi = categories.singleWhere(
        (item) => item.slug == 'jayanthi_exact',
      );

      expect(
        festival.tags,
        containsAll(<String>['festival_exact', 'festival']),
      );
      expect(festival.tags, isNot(contains('devotional')));
      expect(festival.tags, isNot(contains('today_special')));
      expect(
        jayanthi.tags,
        containsAll(<String>['jayanthi_exact', 'jayanthi']),
      );
      expect(jayanthi.tags, isNot(contains('important_day')));
      expect(jayanthi.tags, isNot(contains('today_special')));
    });

    test('living person birthdays are not shown as jayanthi', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'k_t_rama_rao_birthday',
            slug: 'k_t_rama_rao_birthday',
            type: DynamicCategoryType.birthday,
            scope: DynamicEventScope.telangana,
            priority: 90,
            sortOrder: 1,
            startMonth: 7,
            startDay: 24,
            title: DynamicLocalizedTitle(
              telugu: 'K.T. Rama Rao Jayanthi',
              english: 'K.T. Rama Rao Birthday',
              hindi: 'K.T. Rama Rao Birthday',
            ),
          ),
        ]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 7, 24),
        language: AppLanguage.telugu,
      );
      final birthday = categories.singleWhere(
        (item) => item.slug == 'k_t_rama_rao_birthday',
      );

      expect(
        birthday.label,
        '\u0c15\u0c46.\u0c1f\u0c3f. \u0c30\u0c3e\u0c2e\u0c3e\u0c30\u0c3e\u0c35\u0c41 \u0c2a\u0c41\u0c1f\u0c4d\u0c1f\u0c3f\u0c28\u0c30\u0c4b\u0c1c\u0c41',
      );
      expect(birthday.type, DynamicCategoryType.birthday);
      expect(birthday.tags, containsAll(<String>['birthday', 'birthdays']));
      expect(birthday.tags, isNot(contains('jayanthi')));
    });

    test('shows event categories only from the event date by default', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'same_day',
            slug: 'same_day_event',
            type: DynamicCategoryType.importantDay,
            scope: DynamicEventScope.india,
            priority: 90,
            sortOrder: 1,
            startMonth: 8,
            startDay: 15,
            title: DynamicLocalizedTitle(
              telugu: 'ఈవెంట్',
              english: 'Same Day Event',
              hindi: 'इवेंट',
            ),
          ),
        ]),
      );

      final dayBefore = service.categoriesForDate(
        DateTime(2026, 8, 14),
        language: AppLanguage.english,
      );
      final eventDay = service.categoriesForDate(
        DateTime(2026, 8, 15),
        language: AppLanguage.english,
      );

      expect(dayBefore.any((item) => item.slug == 'same_day_event'), isFalse);
      expect(eventDay.any((item) => item.slug == 'same_day_event'), isTrue);
    });

    test('supports three-day More popup preview through event end', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[
          DynamicCalendarEvent(
            id: 'preview_event',
            slug: 'preview_event',
            type: DynamicCategoryType.festival,
            scope: DynamicEventScope.india,
            priority: 90,
            sortOrder: 1,
            startMonth: 8,
            startDay: 15,
            durationDays: 2,
            title: DynamicLocalizedTitle(
              telugu: 'Preview Event',
              english: 'Preview Event',
              hindi: 'Preview Event',
            ),
          ),
        ]),
        daysBeforeEvent: 3,
      );

      bool hasPreviewEvent(DateTime day) {
        return service
            .categoriesForDate(day, language: AppLanguage.english)
            .any((item) => item.slug == 'preview_event');
      }

      expect(hasPreviewEvent(DateTime(2026, 8, 11)), isFalse);
      expect(hasPreviewEvent(DateTime(2026, 8, 12)), isTrue);
      expect(hasPreviewEvent(DateTime(2026, 8, 15)), isTrue);
      expect(hasPreviewEvent(DateTime(2026, 8, 16)), isTrue);
      expect(hasPreviewEvent(DateTime(2026, 8, 17)), isFalse);
    });

    test(
      'includes Bonalu and Gurram Jashuva for Andhra Pradesh on July 23',
      () {
        const service = DynamicCategoryService(daysBeforeEvent: 3);

        final slugs = service
            .categoriesForDate(
              DateTime(2026, 7, 23, 10),
              language: AppLanguage.telugu,
              selectedRegionId: 'andhra_pradesh',
            )
            .map((item) => item.slug)
            .toSet();

        expect(slugs, contains('bonalu'));
        expect(slugs, contains('gurram_jashuva_vardhanthi'));
      },
    );

    test('includes Chiranjeevi birthday for Telugu states on August 22', () {
      const service = DynamicCategoryService();

      Set<String> slugsForRegion(String regionId) {
        return service
            .categoriesForDate(
              DateTime(2026, 8, 22, 10),
              language: AppLanguage.english,
              selectedRegionId: regionId,
            )
            .map((item) => item.slug)
            .toSet();
      }

      expect(
        slugsForRegion('andhra_pradesh'),
        contains('chiranjeevi_birthday'),
      );
      expect(slugsForRegion('telangana'), contains('chiranjeevi_birthday'));
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

      expect(categories.any((item) => item.slug == 'telangana_event'), isFalse);
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

    test('uses readable Telugu for weekday dynamic categories', () {
      const service = DynamicCategoryService(
        repository: _FakeDynamicEventRepository(<DynamicCalendarEvent>[]),
      );

      final categories = service.categoriesForDate(
        DateTime(2026, 7, 22),
        language: AppLanguage.telugu,
      );

      expect(
        categories
            .singleWhere((item) => item.slug == 'weekday_wednesday_special')
            .label,
        'బుధవారం స్పెషల్',
      );
    });

    test('uses seeded Telugu labels for More preview event categories', () {
      const service = DynamicCategoryService();

      final categories = service.categoriesForDate(
        DateTime(2026, 7, 24),
        language: AppLanguage.telugu,
      );

      expect(
        categories
            .singleWhere((item) => item.slug == 'gurram_jashuva_vardhanthi')
            .label,
        'గుర్రం జాషువా వర్ధంతి',
      );
    });
  });
}
