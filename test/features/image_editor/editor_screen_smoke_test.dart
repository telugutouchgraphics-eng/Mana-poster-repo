import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

void main() {
  testWidgets('editor renders chrome for an empty page', (tester) async {
    final controller = AppLanguageController(
      initialLanguage: AppLanguage.telugu,
    );
    await tester.pumpWidget(
      AppLanguageScope(
        language: controller.language,
        controller: controller,
        child: const MaterialApp(
          home: ImageEditorScreen(
            pageConfig: EditorPageConfig(
              name: '1:1',
              widthPx: 1080,
              heightPx: 1080,
              dpi: 300,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(ImageEditorScreen), findsOneWidget);
    expect(
      tester.element(find.byType(ImageEditorScreen)).currentLanguage,
      AppLanguage.english,
    );
    expect(find.byKey(const ValueKey<String>('main-strip')), findsOneWidget);

    await tester.pump(const Duration(seconds: 31));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
