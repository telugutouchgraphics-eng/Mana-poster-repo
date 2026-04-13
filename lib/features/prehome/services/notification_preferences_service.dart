import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesSnapshot {
  const NotificationPreferencesSnapshot({
    required this.allNotifications,
    required this.newPosters,
    required this.offersUpdates,
    required this.subscriptionReminders,
  });

  const NotificationPreferencesSnapshot.defaults()
    : allNotifications = true,
      newPosters = true,
      offersUpdates = true,
      subscriptionReminders = true;

  final bool allNotifications;
  final bool newPosters;
  final bool offersUpdates;
  final bool subscriptionReminders;

  NotificationPreferencesSnapshot copyWith({
    bool? allNotifications,
    bool? newPosters,
    bool? offersUpdates,
    bool? subscriptionReminders,
  }) {
    return NotificationPreferencesSnapshot(
      allNotifications: allNotifications ?? this.allNotifications,
      newPosters: newPosters ?? this.newPosters,
      offersUpdates: offersUpdates ?? this.offersUpdates,
      subscriptionReminders:
          subscriptionReminders ?? this.subscriptionReminders,
    );
  }
}

class NotificationPreferencesService {
  NotificationPreferencesService._();

  static const String _allKey = 'notif_pref_all_enabled_v1';
  static const String _newPostersKey = 'notif_pref_new_posters_v1';
  static const String _offersKey = 'notif_pref_offers_updates_v1';
  static const String _subscriptionKey = 'notif_pref_subscription_reminders_v1';

  static Future<NotificationPreferencesSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferencesSnapshot(
      allNotifications: prefs.getBool(_allKey) ?? true,
      newPosters: prefs.getBool(_newPostersKey) ?? true,
      offersUpdates: prefs.getBool(_offersKey) ?? true,
      subscriptionReminders: prefs.getBool(_subscriptionKey) ?? true,
    );
  }

  static Future<void> save(NotificationPreferencesSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allKey, snapshot.allNotifications);
    await prefs.setBool(_newPostersKey, snapshot.newPosters);
    await prefs.setBool(_offersKey, snapshot.offersUpdates);
    await prefs.setBool(_subscriptionKey, snapshot.subscriptionReminders);
  }
}
