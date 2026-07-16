import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/notification_preferences_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen>
    with AppLanguageStateMixin {
  NotificationPreferencesSnapshot _snapshot =
      const NotificationPreferencesSnapshot.defaults();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await NotificationPreferencesService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _update(NotificationPreferencesSnapshot next) async {
    setState(() {
      _snapshot = next;
      _saving = true;
    });
    try {
      await NotificationPreferencesService.save(next);
      await NotificationService.instance.syncCurrentPreferences();
    } catch (_) {
      // Keep the optimistic toggle state, but always release the saving UI.
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _NotificationsCopy(context.currentLanguage);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: -78,
            right: -34,
            child: _NotificationOrb(size: 165, color: Color(0x1822C55E)),
          ),
          const Positioned(
            top: 145,
            left: -52,
            child: _NotificationOrb(size: 130, color: Color(0x182563EB)),
          ),
          SafeArea(
            top: false,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFFEAF2FF),
                              Color(0xFFFFFFFF),
                            ],
                          ),
                          border: Border.all(color: const Color(0xD9E3EDF6)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x100F172A),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: Color(0xFF2563EB),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              copy.cardTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              copy.cardSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF475569),
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: SwitchListTile.adaptive(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 2,
                                  ),
                                  title: Text(
                                    copy.allNotificationsTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(copy.allNotificationsSubtitle),
                                  value: _snapshot.allNotifications,
                                  onChanged: (value) {
                                    _update(
                                      _snapshot.copyWith(
                                        allNotifications: value,
                                        newPosters: value
                                            ? _snapshot.newPosters
                                            : false,
                                        offersUpdates: value
                                            ? _snapshot.offersUpdates
                                            : false,
                                        subscriptionReminders: value
                                            ? _snapshot.subscriptionReminders
                                            : false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          copy.preferencesTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE3EAF3)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x0C0F172A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            _NotificationToggleTile(
                              title: copy.newPostersTitle,
                              subtitle: copy.newPostersSubtitle,
                              enabled: _snapshot.allNotifications,
                              value: _snapshot.newPosters,
                              onChanged: (value) => _update(
                                _snapshot.copyWith(newPosters: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 18, endIndent: 18),
                            _NotificationToggleTile(
                              title: copy.offersTitle,
                              subtitle: copy.offersSubtitle,
                              enabled: _snapshot.allNotifications,
                              value: _snapshot.offersUpdates,
                              onChanged: (value) => _update(
                                _snapshot.copyWith(offersUpdates: value),
                              ),
                            ),
                            const Divider(height: 1, indent: 18, endIndent: 18),
                            _NotificationToggleTile(
                              title: copy.subscriptionTitle,
                              subtitle: copy.subscriptionSubtitle,
                              enabled: _snapshot.allNotifications,
                              value: _snapshot.subscriptionReminders,
                              onChanged: (value) => _update(
                                _snapshot.copyWith(
                                  subscriptionReminders: value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        opacity: _saving ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Row(
                          children: <Widget>[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              copy.savingLabel,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationOrb extends StatelessWidget {
  const _NotificationOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          value: enabled && value,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _NotificationsCopy {
  const _NotificationsCopy(this.language);

  final AppLanguage language;

  String _localized({required String telugu, required String english}) =>
      AppStrings(language).localized(telugu: telugu, english: english);

  String get title => _localized(
    telugu:
        '\u0C28\u0C4B\u0C1F\u0C3F\u0C2B\u0C3F\u0C15\u0C47\u0C37\u0C28\u0C4D \u0C38\u0C46\u0C1F\u0C4D\u0C1F\u0C3F\u0C02\u0C17\u0C4D\u0C38\u0C4D',
    english: 'Notification settings',
  );

  String get cardTitle => _localized(
    telugu:
        '\u0C28\u0C4B\u0C1F\u0C3F\u0C2B\u0C3F\u0C15\u0C47\u0C37\u0C28\u0C4D\u0C32 \u0C28\u0C3F\u0C2F\u0C02\u0C24\u0C4D\u0C30\u0C23',
    english: 'Notification controls',
  );

  String get cardSubtitle => _localized(
    telugu:
        '\u0C2F\u0C3E\u0C2A\u0C4D\u0C32\u0C4B \u0C0F \u0C30\u0C15\u0C02 \u0C05\u0C32\u0C30\u0C4D\u0C1F\u0C4D\u0C32\u0C41 \u0C30\u0C3E\u0C35\u0C3E\u0C32\u0C4B \u0C07\u0C15\u0C4D\u0C15\u0C21 \u0C28\u0C41\u0C02\u0C1A\u0C3F \u0C28\u0C3F\u0C2F\u0C02\u0C24\u0C4D\u0C30\u0C3F\u0C02\u0C1A\u0C35\u0C1A\u0C4D\u0C1A\u0C41.',
    english: 'Choose which app alerts you want to receive from here.',
  );

  String get preferencesTitle => _localized(
    telugu:
        '\u0C35\u0C4D\u0C2F\u0C15\u0C4D\u0C24\u0C3F\u0C17\u0C24 \u0C2A\u0C4D\u0C30\u0C3E\u0C27\u0C3E\u0C28\u0C4D\u0C2F\u0C3E\u0C32\u0C41',
    english: 'Preferences',
  );

  String get allNotificationsTitle => _localized(
    telugu:
        '\u0C05\u0C28\u0C4D\u0C28\u0C3F \u0C28\u0C4B\u0C1F\u0C3F\u0C2B\u0C3F\u0C15\u0C47\u0C37\u0C28\u0C4D\u0C32\u0C41',
    english: 'All notifications',
  );

  String get allNotificationsSubtitle => _localized(
    telugu:
        '\u0C26\u0C40\u0C28\u0C4D\u0C28\u0C3F \u0C06\u0C2B\u0C4D \u0C1A\u0C47\u0C38\u0C4D\u0C24\u0C47 \u0C15\u0C4D\u0C30\u0C3F\u0C02\u0C26 \u0C09\u0C28\u0C4D\u0C28 \u0C05\u0C28\u0C4D\u0C28\u0C3F \u0C0E\u0C02\u0C2A\u0C3F\u0C15\u0C32\u0C41 \u0C15\u0C42\u0C21\u0C3E \u0C06\u0C17\u0C3F\u0C2A\u0C4B\u0C24\u0C3E\u0C2F\u0C3F.',
    english: 'Turning this off also disables the options below.',
  );

  String get newPostersTitle => _localized(
    telugu:
        '\u0C15\u0C4A\u0C24\u0C4D\u0C24 \u0C2A\u0C4B\u0C38\u0C4D\u0C1F\u0C30\u0C4D\u0C32\u0C41',
    english: 'New posters',
  );

  String get newPostersSubtitle => _localized(
    telugu:
        '\u0C15\u0C4A\u0C24\u0C4D\u0C24 \u0C21\u0C3F\u0C1C\u0C48\u0C28\u0C4D\u0C32\u0C41 \u0C32\u0C47\u0C26\u0C3E \u0C1F\u0C46\u0C02\u0C2A\u0C4D\u0C32\u0C47\u0C1F\u0C4D\u0C32\u0C41 \u0C35\u0C1A\u0C4D\u0C1A\u0C3F\u0C28\u0C2A\u0C4D\u0C2A\u0C41\u0C21\u0C41 \u0C24\u0C46\u0C32\u0C3F\u0C2F\u0C1C\u0C47\u0C38\u0C4D\u0C24\u0C41\u0C02\u0C26\u0C3F.',
    english: 'When new templates and poster designs are available.',
  );

  String get offersTitle => _localized(
    telugu:
        '\u0C06\u0C2B\u0C30\u0C4D\u0C32\u0C41 & \u0C05\u0C2A\u0C4D\u0C21\u0C47\u0C1F\u0C4D\u0C32\u0C41',
    english: 'Offers & updates',
  );

  String get offersSubtitle => _localized(
    telugu:
        '\u0C2A\u0C4D\u0C30\u0C24\u0C4D\u0C2F\u0C47\u0C15 \u0C06\u0C2B\u0C30\u0C4D\u0C32\u0C41, \u0C2A\u0C4D\u0C30\u0C4B\u0C2E\u0C4B\u0C32\u0C41, \u0C2E\u0C41\u0C16\u0C4D\u0C2F\u0C2E\u0C48\u0C28 \u0C2F\u0C3E\u0C2A\u0C4D \u0C05\u0C2A\u0C4D\u0C21\u0C47\u0C1F\u0C4D\u0C32\u0C41.',
    english: 'Special offers, promos, and important app updates.',
  );

  String get subscriptionTitle => _localized(
    telugu:
        '\u0C38\u0C2C\u0C4D\u0C38\u0C4D\u0C15\u0C4D\u0C30\u0C3F\u0C2A\u0C4D\u0C37\u0C28\u0C4D \u0C17\u0C41\u0C30\u0C4D\u0C24\u0C3F\u0C02\u0C2A\u0C41\u0C32\u0C41',
    english: 'Subscription reminders',
  );

  String get subscriptionSubtitle => _localized(
    telugu:
        '\u0C1F\u0C4D\u0C30\u0C2F\u0C32\u0C4D \u0C2E\u0C41\u0C17\u0C3F\u0C02\u0C2A\u0C41 \u0C32\u0C47\u0C26\u0C3E \u0C30\u0C40\u0C28\u0C4D\u0C2F\u0C41\u0C35\u0C32\u0C4D \u0C24\u0C47\u0C26\u0C40\u0C32\u0C15\u0C41 \u0C17\u0C41\u0C30\u0C4D\u0C24\u0C3F\u0C02\u0C2A\u0C41\u0C32\u0C41.',
    english: 'Trial end and renewal reminders.',
  );

  String get savingLabel => _localized(
    telugu:
        '\u0C38\u0C47\u0C35\u0C4D \u0C05\u0C35\u0C41\u0C24\u0C4B\u0C02\u0C26\u0C3F...',
    english: 'Saving...',
  );
}
