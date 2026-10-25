import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';

void main() {
  group('NotificationService Personalization Tests', () {
    test('Telugu personalized body with user name (సురేష్)', () {
      final label = NotificationService.categoryLabelForLanguage(
        category: 'morning',
        language: AppLanguage.telugu,
      );
      expect(label, equals('గుడ్ మార్నింగ్'));

      final body = NotificationService.formatPersonalizedNotificationBody(
        language: AppLanguage.telugu,
        userName: 'సురేష్',
        label: label,
        fallbackBody: 'మీ గుడ్ మార్నింగ్ పోస్టర్ సిద్ధంగా ఉంది.',
      );
      expect(body, equals('సురేష్ గారు, మీ గుడ్ మార్నింగ్ పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది.'));
    });

    test('Telugu personalized body without user name', () {
      final label = NotificationService.categoryLabelForLanguage(
        category: 'morning',
        language: AppLanguage.telugu,
      );
      final body = NotificationService.formatPersonalizedNotificationBody(
        language: AppLanguage.telugu,
        userName: '',
        label: label,
        fallbackBody: 'మీ గుడ్ మార్నింగ్ పోస్టర్ సిద్ధంగా ఉంది.',
      );
      expect(body, equals('మీ గుడ్ మార్నింగ్ పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది.'));
    });

    test('Dynamic Event personalization with user name', () {
      const eventName = 'దీపావళి';
      final body = NotificationService.formatPersonalizedNotificationBody(
        language: AppLanguage.telugu,
        userName: 'రమేష్',
        label: eventName,
        fallbackBody: 'దీపావళి పోస్టర్ సిద్ధంగా ఉంది.',
      );
      expect(body, equals('రమేష్ గారు, మీ దీపావళి పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది.'));
    });

    test('Tips category personalization in Telugu', () {
      final label = NotificationService.categoryLabelForLanguage(
        category: 'tips',
        language: AppLanguage.telugu,
      );
      expect(label, equals('డైలీ టిప్స్'));

      final body = NotificationService.formatPersonalizedNotificationBody(
        language: AppLanguage.telugu,
        userName: 'సురేష్',
        label: label,
        fallbackBody: 'డైలీ టిప్స్ పోస్టర్ సిద్ధం',
      );
      expect(body, equals('సురేష్ గారు, మీ డైలీ టిప్స్ పోస్టర్ షేర్ చేయడానికి సిద్ధంగా ఉంది.'));
    });

    test('All 18 languages produce valid non-empty personalized bodies', () {
      for (final language in AppLanguage.values) {
        final bodyWithName = NotificationService.formatPersonalizedNotificationBody(
          language: language,
          userName: 'User',
          label: 'Special',
          fallbackBody: 'Your poster is ready',
        );
        expect(bodyWithName.isNotEmpty, isTrue, reason: 'Failed for language ${language.name}');
        expect(bodyWithName.contains('User'), isTrue, reason: 'User name missing for ${language.name}');

        final bodyWithoutName = NotificationService.formatPersonalizedNotificationBody(
          language: language,
          userName: '',
          label: 'Special',
          fallbackBody: 'Your poster is ready',
        );
        expect(bodyWithoutName.isNotEmpty, isTrue, reason: 'Empty fallback failed for ${language.name}');
        expect(bodyWithoutName.contains('User'), isFalse, reason: 'Unexpected User for ${language.name}');
      }
    });
  });
}

