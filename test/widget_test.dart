import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/app.dart';

void main() {
  testWidgets('app renders forced home shell', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const ui.Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    const homeKey = Key('test-home');
    await tester.pumpWidget(
      const ManaPosterApp(
        forcedHome: SizedBox(key: homeKey),
        forceSingleRoute: true,
      ),
    );
    await tester.pump();

    expect(find.byKey(homeKey), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 8));
  });
}
