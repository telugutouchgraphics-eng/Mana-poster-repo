import 'dart:typed_data';

Future<Uint8List> loadBackgroundRemovalFileBytes(String path) async {
  throw UnsupportedError(
    'Local file background removal is not supported on web in this build.',
  );
}
