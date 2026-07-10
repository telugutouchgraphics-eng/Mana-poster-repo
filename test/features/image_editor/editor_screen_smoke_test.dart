import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

void main() {
  testWidgets('editor renders chrome for an empty page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ImageEditorScreen(
          pageConfig: EditorPageConfig(
            name: '1:1',
            widthPx: 1080,
            heightPx: 1080,
            dpi: 300,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(ImageEditorScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('main-strip')), findsOneWidget);

    await tester.pump(const Duration(seconds: 31));
  });
}
