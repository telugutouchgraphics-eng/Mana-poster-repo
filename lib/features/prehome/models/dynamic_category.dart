class DynamicCategory {
  const DynamicCategory({required this.label, this.isBlinking = true});

  final String label;
  final bool isBlinking;
}

class DynamicCalendarEvent {
  const DynamicCalendarEvent({
    required this.teluguTitle,
    required this.englishTitle,
    required this.month,
    required this.day,
    this.durationDays = 1,
    this.isRecurringYearly = true,
  });

  final String teluguTitle;
  final String englishTitle;
  final int month;
  final int day;
  final int durationDays;
  final bool isRecurringYearly;
}
