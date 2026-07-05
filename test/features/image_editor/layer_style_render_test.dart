import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

Future<ByteData> _renderSurface(
  WidgetTester tester, {
  Color childColor = Colors.white,
  double strokeWidth = 0,
  double strokeOpacity = 1,
  double shadowOpacity = 0,
  double shadowBlur = 0,
  double shadowSpread = 0,
  Offset shadowOffset = Offset.zero,
  double innerShadowOpacity = 0,
  double innerShadowBlur = 0,
  double innerShadowChoke = 0,
  double innerShadowDistance = 0,
  double outerGlowOpacity = 0,
  double outerGlowSize = 0,
  double outerGlowSpread = 0,
  double overlayOpacity = 0,
  Color overlayColor = Colors.black,
  bool gradientOverlayEnabled = false,
  double gradientOverlayOpacity = 0,
}) async {
  const boundaryKey = Key('layer-style-pixel-test');
  await tester.pumpWidget(
    MaterialApp(
      home: ColoredBox(
        color: Colors.transparent,
        child: Center(
          child: buildEditorLayerStylePixelTestSurface(
            repaintBoundaryKey: boundaryKey,
            childColor: childColor,
            strokeWidth: strokeWidth,
            strokeOpacity: strokeOpacity,
            shadowOpacity: shadowOpacity,
            shadowBlur: shadowBlur,
            shadowSpread: shadowSpread,
            shadowOffset: shadowOffset,
            innerShadowOpacity: innerShadowOpacity,
            innerShadowBlur: innerShadowBlur,
            innerShadowChoke: innerShadowChoke,
            innerShadowDistance: innerShadowDistance,
            outerGlowOpacity: outerGlowOpacity,
            outerGlowSize: outerGlowSize,
            outerGlowSpread: outerGlowSpread,
            overlayOpacity: overlayOpacity,
            overlayColor: overlayColor,
            gradientOverlayEnabled: gradientOverlayEnabled,
            gradientOverlayOpacity: gradientOverlayOpacity,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final data = await tester.runAsync<ByteData>(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!;
  });
  return data!;
}

List<int> _pixel(ByteData data, int x, int y) {
  final offset = (y * 96 + x) * 4;
  return <int>[
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

int _luma(List<int> pixel) {
  return ((pixel[0] * 0.2126) + (pixel[1] * 0.7152) + (pixel[2] * 0.0722))
      .round();
}

void main() {
  testWidgets('stroke paints outside layer alpha', (tester) async {
    final data = await _renderSurface(
      tester,
      strokeWidth: 10,
      strokeOpacity: 1,
    );
    final strokePixel = _pixel(data, 23, 48);
    expect(strokePixel[0], greaterThan(150));
    expect(strokePixel[3], greaterThan(120));
  });

  testWidgets('shadow paints behind layer', (tester) async {
    final data = await _renderSurface(
      tester,
      shadowOpacity: 1,
      shadowBlur: 0,
      shadowSpread: 8,
      shadowOffset: const Offset(10, 0),
    );
    expect(_pixel(data, 83, 48)[3], greaterThan(100));
  });

  testWidgets('shadow does not flood the whole canvas', (tester) async {
    final data = await _renderSurface(
      tester,
      shadowOpacity: 1,
      shadowBlur: 18,
      shadowSpread: 8,
      shadowOffset: const Offset(10, 10),
    );
    expect(_pixel(data, 2, 2)[3], lessThan(20));
  });

  testWidgets('inner shadow darkens layer interior', (tester) async {
    final data = await _renderSurface(
      tester,
      childColor: const Color(0xFFFFFFFF),
      innerShadowOpacity: 1,
      innerShadowBlur: 8,
      innerShadowDistance: 8,
    );
    expect(_luma(_pixel(data, 31, 48)), lessThan(245));
  });

  testWidgets('outer glow paints blurred outside alpha', (tester) async {
    final data = await _renderSurface(
      tester,
      outerGlowOpacity: 1,
      outerGlowSize: 14,
      outerGlowSpread: 6,
    );
    expect(_pixel(data, 20, 48)[3], greaterThan(20));
  });

  testWidgets('color overlay tints only the layer', (tester) async {
    final data = await _renderSurface(
      tester,
      childColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.6,
    );
    expect(_luma(_pixel(data, 48, 48)), lessThan(180));
    expect(_pixel(data, 10, 10)[3], 0);
  });

  testWidgets('style updates repaint an existing canvas layer', (tester) async {
    final before = await _renderSurface(tester, childColor: Colors.white);
    expect(_luma(_pixel(before, 48, 48)), greaterThan(240));

    final after = await _renderSurface(
      tester,
      childColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.6,
    );
    expect(_luma(_pixel(after, 48, 48)), lessThan(180));
  });

  testWidgets('gradient overlay is clipped to layer alpha', (tester) async {
    final data = await _renderSurface(
      tester,
      childColor: const Color(0xFF808080),
      gradientOverlayEnabled: true,
      gradientOverlayOpacity: 1,
    );
    expect(_pixel(data, 10, 10)[3], 0);
    expect(_luma(_pixel(data, 34, 48)), isNot(_luma(_pixel(data, 62, 48))));
  });
}
