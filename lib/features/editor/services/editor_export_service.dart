import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mana_poster/features/editor/models/editor_export_models.dart';

class EditorExportService {
  const EditorExportService();

  Future<EditorExportResult> exportStage({
    required RenderRepaintBoundary boundary,
    required EditorExportOptions options,
  }) async {
    final image = await boundary.toImage(pixelRatio: options.pixelRatio);
    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) {
      throw StateError('Failed to capture stage image.');
    }

    Uint8List bytes = pngBytes.buffer.asUint8List();
    var extension = 'png';
    var mimeType = 'image/png';

    if (options.format == EditorExportFormat.jpg) {
      final decoded = img.decodePng(bytes);
      if (decoded == null) {
        throw StateError('Failed to prepare JPG export.');
      }
      bytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 96));
      extension = 'jpg';
      mimeType = 'image/jpeg';
    }

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/mana_poster_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(bytes, flush: true);

    return EditorExportResult(
      filePath: file.path,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  Future<void> saveToDevice(EditorExportResult result) async {
    await ImageGallerySaverPlus.saveFile(result.filePath);
  }

  Future<void> share(EditorExportResult result) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(result.filePath, mimeType: result.mimeType)],
      ),
    );
  }
}
