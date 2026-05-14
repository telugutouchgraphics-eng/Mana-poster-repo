import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';

class NotificationUnavailableScreen extends StatelessWidget {
  const NotificationUnavailableScreen({
    super.key,
    this.title,
    this.message,
  });

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final resolvedTitle =
        title ??
        strings.localized(
          telugu: 'ఈ నోటిఫికేషన్ కంటెంట్ అందుబాటులో లేదు',
          english: 'This notification content is unavailable',
        );
    final resolvedMessage =
        message ??
        strings.localized(
          telugu: 'ఈ కంటెంట్ తీసివేయబడింది లేదా ఇక అందుబాటులో లేదు. హోమ్‌కి వెళ్లి తాజా పోస్టర్లు చూడండి.',
          english:
              'This content was removed or is no longer available. Open Home to see the latest posters.',
        );

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text(strings.localized(telugu: 'నోటిఫికేషన్', english: 'Notification'))),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.notifications_off_rounded,
                  size: 68,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 18),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  resolvedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: AppNavigator.openHome,
                  child: Text(
                    strings.localized(
                      telugu: 'హోమ్‌కి వెళ్లండి',
                      english: 'Open Home',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
