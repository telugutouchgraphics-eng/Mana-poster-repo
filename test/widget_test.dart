import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
void main() {
  testWidgets('app opens splash', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const ui.Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ManaPosterApp());

    expect(find.text(AppPublicInfo.appName), findsOneWidget);
    expect(find.text('లోడ్ అవుతోంది...'), findsOneWidget);
  });
}
