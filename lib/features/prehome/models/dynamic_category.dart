import 'package:mana_poster/app/localization/app_language.dart';

enum DynamicCategoryType {
  festival,
  jayanthi,
  vardhanthi,
  importantDay,
  weekdaySpecial,
  regionalSpecial,
}

enum DynamicEventScope {
  india,
  andhraPradesh,
  telangana,
  bothTeluguStates,
  global,
}

enum DynamicCalendarType { gregorian, lunarPlaceholder }

class DynamicLocalizedTitle {
  const DynamicLocalizedTitle({
    required this.telugu,
    required this.english,
    required this.hindi,
  });

  final String telugu;
  final String english;
  final String hindi;

  String resolve(AppLanguage language) {
    return switch (language) {
      AppLanguage.telugu => telugu,
      AppLanguage.hindi => hindi,
      AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam => english,
    };
  }
}

class DynamicCategory {
  const DynamicCategory({
    required this.id,
    required this.slug,
    required this.label,
    required this.type,
    required this.scope,
    this.priority = 0,
    this.sortOrder = 0,
    this.tags = const <String>[],
    this.isBlinking = true,
  });

  final String id;
  final String slug;
  final String label;
  final DynamicCategoryType type;
  final DynamicEventScope scope;
  final int priority;
  final int sortOrder;
  final List<String> tags;
  final bool isBlinking;
}

class DynamicCalendarEvent {
  const DynamicCalendarEvent({
    required this.id,
    required this.slug,
    required this.type,
    required this.scope,
    required this.priority,
    required this.title,
    this.startMonth,
    this.startDay,
    this.endMonth,
    this.endDay,
    this.durationDays = 1,
    this.isRecurringYearly = true,
    this.calendarType = DynamicCalendarType.gregorian,
    this.tags = const <String>[],
    this.enabled = true,
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final DynamicCategoryType type;
  final DynamicEventScope scope;
  final int priority;
  final DynamicLocalizedTitle title;
  final int? startMonth;
  final int? startDay;
  final int? endMonth;
  final int? endDay;
  final int durationDays;
  final bool isRecurringYearly;
  final DynamicCalendarType calendarType;
  final List<String> tags;
  final bool enabled;
  final int sortOrder;
}



