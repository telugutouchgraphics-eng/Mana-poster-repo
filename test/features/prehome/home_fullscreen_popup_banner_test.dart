import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/app_home_banner.dart';
import 'package:mana_poster/features/prehome/screens/home_screen.dart';

class ControlledImage extends ImageProvider<ControlledImage> {
  final ready = Completer<ImageInfo>();
  @override
  Future<ControlledImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<ControlledImage>(this);
  @override
  ImageStreamCompleter loadImage(
    ControlledImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(ready.future);
}

const banner = AppHomeBanner(
  id: 'popup-one',
  title: '',
  subtitle: '',
  imageUrl: 'https://example.com/banner.png',
  ctaLabel: '',
  ctaTarget: 'https://example.com',
  placement: 'home_fullscreen_popup',
  targetState: '',
  targetDistrict: '',
  targetCity: '',
  sortOrder: 0,
  active: true,
);

Widget host({
  required ImageProvider provider,
  required ValueChanged<String> onViewed,
  required VoidCallback onClose,
  VoidCallback? onTap,
  AppLanguage language = AppLanguage.english,
}) => AppLanguageScope(
  language: language,
  controller: AppLanguageController(),
  child: MaterialApp(
    home: Scaffold(
      body: Stack(
        children: <Widget>[
          HomeFullscreenPopupBanner(
            banner: banner,
            imageProvider: provider,
            onViewed: onViewed,
            onClose: onClose,
            onTap: onTap,
          ),
        ],
      ),
    ),
  ),
);

Future<ui.Image> fixtureImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(Colors.blue, ui.BlendMode.src);
  return recorder.endRecording().toImage(1, 1);
}

void main() {
  testWidgets(
    'view is counted only after the image frame loads, and only once',
    (tester) async {
      final provider = ControlledImage();
      var views = 0;
      final widget = host(
        provider: provider,
        onViewed: (_) => views++,
        onClose: () {},
      );
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(seconds: 1));
      expect(views, 0);
      provider.ready.complete(ImageInfo(image: await fixtureImage()));
      await tester.pump();
      await tester.pump();
      expect(views, 1);
      await tester.pumpWidget(
        host(provider: provider, onViewed: (_) => views++, onClose: () {}),
      );
      await tester.pumpAndSettle();
      expect(views, 1);
    },
  );

  testWidgets('broken image closes the popup and is not counted as a view', (
    tester,
  ) async {
    final provider = ControlledImage();
    var views = 0;
    var closed = 0;
    await tester.pumpWidget(
      host(
        provider: provider,
        onViewed: (_) => views++,
        onClose: () => closed++,
      ),
    );
    provider.ready.completeError(StateError('broken image'));
    await tester.pumpAndSettle();
    expect(views, 0);
    expect(closed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loaded banner tap and close button invoke their actions', (
    tester,
  ) async {
    final provider = ControlledImage();
    provider.ready.complete(ImageInfo(image: await fixtureImage()));
    var tapped = 0;
    var closed = 0;
    await tester.pumpWidget(
      host(
        provider: provider,
        onViewed: (_) {},
        onClose: () => closed++,
        onTap: () => tapped++,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Image));
    expect(tapped, 1);
    await tester.tap(find.byTooltip('Close'));
    expect(closed, 1);
  });

  testWidgets('close tooltip is available in every supported language', (
    tester,
  ) async {
    final provider = ControlledImage();
    provider.ready.complete(ImageInfo(image: await fixtureImage()));
    for (final language in AppLanguage.values) {
      await tester.pumpWidget(
        host(
          provider: provider,
          language: language,
          onViewed: (_) {},
          onClose: () {},
        ),
      );
      await tester.pumpAndSettle();
      final tooltip = tester
          .widget<IconButton>(find.byType(IconButton))
          .tooltip;
      expect(tooltip, isNotEmpty);
      if (language != AppLanguage.english) expect(tooltip, isNot('Close'));
    }
  });
}
