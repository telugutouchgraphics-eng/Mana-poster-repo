import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/features/prehome/screens/language_selection_screen.dart';

void main() {
  testWidgets('app opens splash then language screen', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const ui.Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ManaPosterApp());

    expect(find.text('Mana Poster'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
  });
}
