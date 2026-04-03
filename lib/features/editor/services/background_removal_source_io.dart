import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadBackgroundRemovalFileBytes(String path) {
  return File(path).readAsBytes();
}
