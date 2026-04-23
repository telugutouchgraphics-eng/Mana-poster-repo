import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/widgets/export_paywall_screen.dart';

void main() {
  Widget wrap(Widget child) {
    final controller = AppLanguageController(initialLanguage: AppLanguage.english);
    return AppLanguageScope(
      language: controller.language,
      controller: controller,
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows clean export paywall copy', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const ExportPaywallScreen(
          previewBytes: null,
          isProUser: false,
          forExport: true,
        ),
      ),
    );

    expect(find.text('Export Options'), findsOneWidget);
    expect(find.text('Free export preview'), findsOneWidget);
    expect(find.text('Continue Free (Watermark)'), findsOneWidget);
    expect(find.text('Upgrade to Pro (Rs.20/month)'), findsOneWidget);
    expect(find.text('Restore Existing Plan'), findsOneWidget);
    expect(
      find.text(
        'Note: A Play/App Store tester account is required for live billing tests.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('returns restore decision when tapped', (WidgetTester tester) async {
    ExportPaywallDecision? result;

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<ExportPaywallDecision>(
                      MaterialPageRoute<ExportPaywallDecision>(
                        builder: (_) => const ExportPaywallScreen(
                          previewBytes: null,
                          isProUser: false,
                          forExport: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore Existing Plan'));
    await tester.pumpAndSettle();

    expect(result, ExportPaywallDecision.restorePurchase);
  });
}
