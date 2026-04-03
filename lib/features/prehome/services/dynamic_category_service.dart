import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/dynamic_category.dart';

class DynamicCategoryService {
  const DynamicCategoryService();

  static const List<DynamicCalendarEvent> defaultEvents =
      <DynamicCalendarEvent>[
        DynamicCalendarEvent(
          teluguTitle: 'శ్రీ రామ నవమి స్పెషల్',
          englishTitle: 'Sri Rama Navami Special',
          month: 4,
          day: 6,
          durationDays: 2,
        ),
        DynamicCalendarEvent(
          teluguTitle: 'స్వాతంత్ర్య దినోత్సవ స్పెషల్',
          englishTitle: 'Independence Day Special',
          month: 8,
          day: 15,
        ),
        DynamicCalendarEvent(
          teluguTitle: 'గాంధీ జయంతి',
          englishTitle: 'Gandhi Jayanti',
          month: 10,
          day: 2,
        ),
        DynamicCalendarEvent(
          teluguTitle: 'స్మారక వర్ధంతి స్పెషల్',
          englishTitle: 'Vardhanti Special',
          month: 11,
          day: 8,
        ),
      ];

  List<DynamicCategory> categoriesForDate(
    DateTime now, {
    AppLanguage language = AppLanguage.telugu,
    List<DynamicCalendarEvent> events = defaultEvents,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final output = <DynamicCategory>[
      DynamicCategory(label: _weekdayLabel(today.weekday, language)),
    ];

    for (final event in events) {
      if (!event.isRecurringYearly) {
        continue;
      }
      final eventStart = DateTime(today.year, event.month, event.day);
      final eventEnd = eventStart.add(Duration(days: event.durationDays - 1));
      final isActive = !today.isBefore(eventStart) && !today.isAfter(eventEnd);

      if (isActive) {
        output.add(DynamicCategory(label: _eventLabel(event, language)));
      }
    }

    return output;
  }

  String _weekdayLabel(int weekday, AppLanguage language) {
    switch (language) {
      case AppLanguage.telugu:
        return switch (weekday) {
          DateTime.monday => '✨ శుభ సోమవారం',
          DateTime.tuesday => '✨ శుభ మంగళవారం',
          DateTime.wednesday => '✨ శుభ బుధవారం',
          DateTime.thursday => '✨ శుభ గురువారం',
          DateTime.friday => '✨ శుభ శుక్రవారం',
          DateTime.saturday => '✨ శుభ శనివారం',
          _ => '✨ ఆదివారం స్పెషల్',
        };
      case AppLanguage.hindi:
        return switch (weekday) {
          DateTime.monday => '✨ शुभ सोमवार',
          DateTime.tuesday => '✨ शुभ मंगलवार',
          DateTime.wednesday => '✨ शुभ बुधवार',
          DateTime.thursday => '✨ शुभ गुरुवार',
          DateTime.friday => '✨ शुभ शुक्रवार',
          DateTime.saturday => '✨ शुभ शनिवार',
          _ => '✨ रविवार स्पेशल',
        };
      case AppLanguage.english:
        return switch (weekday) {
          DateTime.monday => '✨ Monday Special',
          DateTime.tuesday => '✨ Tuesday Special',
          DateTime.wednesday => '✨ Wednesday Special',
          DateTime.thursday => '✨ Thursday Special',
          DateTime.friday => '✨ Friday Special',
          DateTime.saturday => '✨ Saturday Special',
          _ => '✨ Sunday Special',
        };
    }
  }

  String _eventLabel(DynamicCalendarEvent event, AppLanguage language) {
    return switch (language) {
      AppLanguage.telugu => '📌 ${event.teluguTitle}',
      AppLanguage.hindi => '📌 ${event.englishTitle}',
      AppLanguage.english => '📌 ${event.englishTitle}',
    };
  }
}
