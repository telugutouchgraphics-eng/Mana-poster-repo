enum HomeFeedTimeSlot {
  morning,
  afternoon,
  evening,
  funEvening,
  night,
}

class TimeSlotService {
  TimeSlotService._();

  static const int _debugHomeHourOverride = int.fromEnvironment(
    'MANA_POSTER_DEBUG_HOME_HOUR',
    defaultValue: -1,
  );

  static HomeFeedTimeSlot homeFeedSlot([DateTime? now]) {
    final reference = now ?? DateTime.now();
    final hour = _debugHomeHourOverride >= 0 && _debugHomeHourOverride <= 23
        ? _debugHomeHourOverride
        : reference.hour;
    if (hour >= 4 && hour < 12) {
      return HomeFeedTimeSlot.morning;
    }
    if (hour >= 12 && hour < 15) {
      return HomeFeedTimeSlot.afternoon;
    }
    if (hour >= 15 && hour < 18) {
      return HomeFeedTimeSlot.evening;
    }
    if (hour >= 18 && hour < 20) {
      return HomeFeedTimeSlot.funEvening;
    }
    return HomeFeedTimeSlot.night;
  }

  static List<String> prioritizedCategoryTagsForHomeFeed([
    DateTime? now,
  ]) {
    return switch (homeFeedSlot(now)) {
      HomeFeedTimeSlot.morning => const <String>[
        'good_morning',
        'motivational',
        'jokes',
      ],
      HomeFeedTimeSlot.afternoon => const <String>[
        'good_afternoon',
        'motivational',
        'jokes',
      ],
      HomeFeedTimeSlot.evening => const <String>[
        'good_evening',
        'motivational',
        'jokes',
      ],
      HomeFeedTimeSlot.funEvening => const <String>[
        'jokes',
        'motivational',
      ],
      HomeFeedTimeSlot.night => const <String>[
        'good_night',
        'jokes',
        'motivational',
      ],
    };
  }
}
