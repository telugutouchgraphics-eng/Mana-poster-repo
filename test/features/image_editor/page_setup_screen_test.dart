import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/screens/page_setup_screen.dart';

void main() {
  Finder startButtonFinder() => find.widgetWithText(FilledButton, 'Start Design');
  Finder scrollableFinder() => find.byType(Scrollable).first;

  Future<void> openCustomMode(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Custom'),
      200,
      scrollable: scrollableFinder(),
    );
    await tester.tap(find.text('Custom').first);
    await tester.pumpAndSettle();
  }

  Future<void> ensureCustomInputsVisible(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byType(TextField).first,
      200,
      scrollable: scrollableFinder(),
    );
  }

  FilledButton resolveStartButton(WidgetTester tester) {
    final finder = startButtonFinder();
    expect(finder, findsOneWidget);
    return tester.widget<FilledButton>(finder);
  }

  AppLanguageScope wrapWithLanguage(Widget child) {
    final controller = AppLanguageController(initialLanguage: AppLanguage.english);
    return AppLanguageScope(
      language: controller.language,
      controller: controller,
      child: MaterialApp(home: child),
    );
  }

  testWidgets('start button disabled for custom with empty values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithLanguage(const PageSetupScreen()));

    await openCustomMode(tester);

    await tester.scrollUntilVisible(
      startButtonFinder(),
      300,
      scrollable: scrollableFinder(),
    );
    final button = resolveStartButton(tester);
    expect(button.onPressed, isNull);
  });

  testWidgets('start button enabled for valid custom pixel values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithLanguage(const PageSetupScreen()));

    await openCustomMode(tester);
    await ensureCustomInputsVisible(tester);

    await tester.enterText(find.byType(TextField).at(0), '1080');
    await tester.enterText(find.byType(TextField).at(1), '1350');
    await tester.pump();

    await tester.scrollUntilVisible(
      startButtonFinder(),
      300,
      scrollable: scrollableFinder(),
    );
    final button = resolveStartButton(tester);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('invalid DPI keeps start button disabled in inches mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithLanguage(const PageSetupScreen()));

    await openCustomMode(tester);
    await tester.scrollUntilVisible(
      find.text('Inches'),
      200,
      scrollable: scrollableFinder(),
    );
    await tester.tap(find.text('Inches').first);
    await tester.pumpAndSettle();
    await ensureCustomInputsVisible(tester);

    await tester.enterText(find.byType(TextField).at(0), '4');
    await tester.enterText(find.byType(TextField).at(1), '6');
    await tester.enterText(find.byType(TextField).at(2), '10');
    await tester.pump();

    await tester.scrollUntilVisible(
      startButtonFinder(),
      300,
      scrollable: scrollableFinder(),
    );
    final button = resolveStartButton(tester);
    expect(button.onPressed, isNull);
  });
}
