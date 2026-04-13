import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/notification_preferences_service.dart';

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
    await NotificationPreferencesService.save(next);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
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
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: -90,
            right: -40,
            child: _NotificationOrb(size: 210, color: Color(0x3322C55E)),
          ),
          const Positioned(
            top: 160,
            left: -60,
            child: _NotificationOrb(size: 170, color: Color(0x332563EB)),
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
                              Color(0xFFEAF5FF),
                              Color(0xFFF1FBF4),
                              Color(0xFFFFFFFF),
                            ],
                          ),
                          border: Border.all(color: const Color(0xD9E3EDF6)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x120F172A),
                              blurRadius: 28,
                              offset: Offset(0, 16),
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
                                fontWeight: FontWeight.w900,
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
                              child: SwitchListTile.adaptive(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                title: Text(
                                  copy.allNotificationsTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
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
                            fontWeight: FontWeight.w800,
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
                              color: Color(0x0F0F172A),
                              blurRadius: 18,
                              offset: Offset(0, 10),
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
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
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
    );
  }
}

class _NotificationsCopy {
  const _NotificationsCopy(this.language);

  final AppLanguage language;

  bool get _isTelugu => language == AppLanguage.telugu;

  String get title =>
      _isTelugu ? 'నోటిఫికేషన్ సెట్టింగ్స్' : 'Notification settings';
  String get cardTitle =>
      _isTelugu ? 'నోటిఫికేషన్ల నియంత్రణ' : 'Notification controls';
  String get cardSubtitle => _isTelugu
      ? 'యాప్‌లో ఏ రకం అలర్ట్‌లు రావాలో ఇక్కడ నుంచి నియంత్రించవచ్చు.'
      : 'Choose which app alerts you want to receive from here.';
  String get preferencesTitle =>
      _isTelugu ? 'వ్యక్తిగత ప్రాధాన్యాలు' : 'Preferences';
  String get allNotificationsTitle =>
      _isTelugu ? 'అన్ని నోటిఫికేషన్లు' : 'All notifications';
  String get allNotificationsSubtitle => _isTelugu
      ? 'దీన్ని ఆఫ్ చేస్తే క్రింద ఉన్న అన్ని ఎంపికలు కూడా ఆగిపోతాయి.'
      : 'Turning this off also disables the options below.';
  String get newPostersTitle => _isTelugu ? 'కొత్త పోస్టర్లు' : 'New posters';
  String get newPostersSubtitle => _isTelugu
      ? 'కొత్త డిజైన్లు లేదా టెంప్లేట్లు వచ్చినప్పుడు తెలియజేస్తుంది.'
      : 'When new templates and poster designs are available.';
  String get offersTitle =>
      _isTelugu ? 'ఆఫర్లు & అప్‌డేట్లు' : 'Offers & updates';
  String get offersSubtitle => _isTelugu
      ? 'ప్రత్యేక ఆఫర్లు, ప్లాన్ సమాచారం, ముఖ్యమైన యాప్ అప్‌డేట్లు.'
      : 'Special offers, promos, and important app updates.';
  String get subscriptionTitle =>
      _isTelugu ? 'సబ్‌స్క్రిప్షన్ గుర్తింపులు' : 'Subscription reminders';
  String get subscriptionSubtitle => _isTelugu
      ? 'ట్రయల్ ముగింపు లేదా రీన్యువల్ తేదీలకు గుర్తింపులు.'
      : 'Trial end and renewal reminders.';
  String get savingLabel => _isTelugu ? 'సేవ్ అవుతోంది...' : 'Saving...';
}
