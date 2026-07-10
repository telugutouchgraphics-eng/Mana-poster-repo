import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

void main() {
  test('workspace gesture allows temporary zoom-out below fit', () {
    expect(debugNormalizeWorkspaceZoomForTest(0.1), 0.2);
    expect(debugNormalizeWorkspaceZoomForTest(0.6), 0.6);
    expect(debugNormalizeWorkspaceZoomForTest(0.999), 0.999);
    expect(debugNormalizeWorkspaceZoomForTest(double.nan), 1);
  });

  test('workspace zoom preserves zoom-in and caps unsafe extremes', () {
    expect(debugNormalizeWorkspaceZoomForTest(1.75), 1.75);
    expect(debugNormalizeWorkspaceZoomForTest(8), 8);
    expect(debugNormalizeWorkspaceZoomForTest(20), 8);
  });

  test('imported portrait page fits left and right edges', () {
    const workspace = Size(400, 600);

    expect(
      debugFitPageSizeForTest(
        workspaceSize: workspace,
        aspectRatio: 0.5,
        forceFullWidth: true,
      ),
      const Size(400, 800),
    );
    expect(
      debugFitPageSizeForTest(workspaceSize: workspace, aspectRatio: 0.5),
      const Size(300, 600),
    );
  });

  test('PSD coordinates scale to the actual edge-to-edge page width', () {
    expect(
      calculatePsdPageWidthScaleForTest(psdWidth: 1000, targetPageWidth: 400),
      0.4,
    );
    expect(
      1000 *
          calculatePsdPageWidthScaleForTest(
            psdWidth: 1000,
            targetPageWidth: 400,
          ),
      400,
    );
  });

  test('PSD imported design export preserves original pixel size', () {
    expect(
      debugCalculateExportTargetPixelSizeForTest(
        widthPx: 0,
        heightPx: 1400,
        shouldBoostRaster: true,
        preservePixels: true,
      ),
      (width: 1, height: 1),
    );
    expect(
      debugCalculateExportTargetPixelSizeForTest(
        widthPx: 1000,
        heightPx: 1400,
        shouldBoostRaster: true,
        preservePixels: true,
      ),
      (width: 1000, height: 1400),
    );
    expect(
      debugCalculateExportTargetPixelSizeForTest(
        widthPx: 1000,
        heightPx: 1400,
        shouldBoostRaster: true,
        preservePixels: false,
      ),
      (width: 2000, height: 2800),
    );
  });

  test('PSD export pixel ratio is not capped below original resolution', () {
    expect(
      debugCalculateExportPixelRatioForTest(
        logicalWidth: 360,
        logicalHeight: 360,
        devicePixelRatio: 3,
        targetSize: (width: 8000, height: 8000),
        preservePixels: true,
      ),
      closeTo(8000 / 360, 0.0001),
    );
    expect(
      debugCalculateExportPixelRatioForTest(
        logicalWidth: 360,
        logicalHeight: 360,
        devicePixelRatio: 3,
        targetSize: (width: 8000, height: 8000),
        preservePixels: false,
      ),
      16,
    );
  });

  test('top Edit is available for selected text and editable PSD text', () {
    expect(
      isTopTextEditContextForTest(
        isTextLayer: true,
        psdEditableText: null,
        isLocked: false,
      ),
      isTrue,
    );
    expect(
      isTopTextEditContextForTest(
        isTextLayer: false,
        psdEditableText: 'Editable PSD text',
        isLocked: false,
      ),
      isTrue,
    );
    expect(
      isTopTextEditContextForTest(
        isTextLayer: true,
        psdEditableText: null,
        isLocked: true,
      ),
      isFalse,
    );
  });
}
