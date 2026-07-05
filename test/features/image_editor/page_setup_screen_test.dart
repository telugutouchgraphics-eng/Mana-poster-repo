import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/screens/page_setup_screen.dart';

void main() {
  Finder startButtonFinder() =>
      find.widgetWithText(FilledButton, 'Start Design');
  Finder scrollableFinder() => find
      .descendant(
        of: find.byKey(const ValueKey('page-setup-scroll')),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> openCustomMode(WidgetTester tester) async {
    await tester.tap(find.text('Empty Page'));
    await tester.pumpAndSettle();
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
    final controller = AppLanguageController(
      initialLanguage: AppLanguage.english,
    );
    return AppLanguageScope(
      language: controller.language,
      controller: controller,
      child: MaterialApp(home: child),
    );
  }

  testWidgets('no start source or page size is selected by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithLanguage(const PageSetupScreen()));

    expect(find.text('Custom'), findsNothing);
    expect(resolveStartButton(tester).onPressed, isNull);
  });

  testWidgets('gallery source enables the start action without a page size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapWithLanguage(const PageSetupScreen()));

    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Custom'), findsNothing);
    expect(resolveStartButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'restore draft source enables the start action without a page size',
    (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithLanguage(const PageSetupScreen()));

      await tester.tap(find.text('Restore Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Custom'), findsNothing);
      expect(resolveStartButton(tester).onPressed, isNotNull);
    },
  );

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

    await tester.enterText(
      find.byKey(const ValueKey('page-width-input')),
      '1080',
    );
    await tester.enterText(
      find.byKey(const ValueKey('page-height-input')),
      '1350',
    );
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

    await tester.enterText(find.byKey(const ValueKey('page-width-input')), '4');
    await tester.enterText(
      find.byKey(const ValueKey('page-height-input')),
      '6',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('page-dpi-input')),
      160,
      scrollable: scrollableFinder(),
    );
    final dpiField = tester.widget<TextField>(
      find.byKey(const ValueKey('page-dpi-input')),
    );
    dpiField.controller?.text = '10';
    await tester.pumpAndSettle();

    expect(dpiField.controller?.text, '10');
    expect(find.text('DPI must be between 72 and 600.'), findsOneWidget);

    await tester.scrollUntilVisible(
      startButtonFinder(),
      300,
      scrollable: scrollableFinder(),
    );
    final button = resolveStartButton(tester);
    expect(button.onPressed, isNull);
  });
}
