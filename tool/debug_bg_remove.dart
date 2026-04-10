import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: flutter pub run tool/debug_bg_remove.dart <image>');
    exitCode = 64;
    return;
  }

  final inputFile = File(args.first);
  if (!await inputFile.exists()) {
    stderr.writeln('Input file not found: ${inputFile.path}');
    exitCode = 66;
    return;
  }

  final bytes = await inputFile.readAsBytes();
  final service = const OfflineBackgroundRemovalService();
  final result = await service.removeBackground(bytes);

  final outputFile = File(
    '${inputFile.parent.path}${Platform.pathSeparator}${inputFile.uri.pathSegments.last}.debug_remove.png',
  );
  await outputFile.writeAsBytes(result.pngBytes, flush: true);

  final decoded = img.decodeImage(result.pngBytes);
  final source = img.decodeImage(bytes);
  stdout.writeln('engine=${result.engineLabel}');
  stdout.writeln('didRemove=${result.didRemoveBackground}');
  stdout.writeln('out=${outputFile.path}');
  if (decoded == null || source == null) {
    stdout.writeln('decode_failed=true');
    return;
  }

  final alphaRatio = _transparentRatio(decoded);
  final changedRatio = _changedAlphaRatio(source, decoded);
  stdout.writeln('alphaRatio=${alphaRatio.toStringAsFixed(4)}');
  stdout.writeln('changedAlphaRatio=${changedRatio.toStringAsFixed(4)}');
}

double _transparentRatio(img.Image image) {
  var transparent = 0;
  final total = image.width * image.height;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a.toInt() < 245) {
        transparent++;
      }
    }
  }
  return transparent / total;
}

double _changedAlphaRatio(img.Image source, img.Image output) {
  if (source.width != output.width || source.height != output.height) {
    return 1.0;
  }
  var changed = 0;
  final total = source.width * source.height;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final a0 = source.getPixel(x, y).a.toInt();
      final a1 = output.getPixel(x, y).a.toInt();
      if ((a0 - a1).abs() >= 8) {
        changed++;
      }
    }
  }
  return changed / total;
}
