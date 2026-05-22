class IstTimeService {
  IstTimeService._();

  static const Duration offset = Duration(hours: 5, minutes: 30);
  static const int dayMillis = 24 * 60 * 60 * 1000;

  static DateTime now() => toIst(DateTime.now());

  static DateTime toIst(DateTime value) => value.toUtc().add(offset);

  static int nowEpochMillis() => DateTime.now().millisecondsSinceEpoch;

  static int startOfDayUtcMillis(DateTime value) {
    final ist = toIst(value);
    return DateTime.utc(
      ist.year,
      ist.month,
      ist.day,
    ).subtract(offset).millisecondsSinceEpoch;
  }
}
