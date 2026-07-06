import 'dart:typed_data';

class BackgroundRemovalResult {
  const BackgroundRemovalResult({
    required this.pngBytes,
    required this.engineLabel,
    required this.didRemoveBackground,
    this.outputFilePath,
  });

  final Uint8List pngBytes;
  final String engineLabel;
  final bool didRemoveBackground;
  final String? outputFilePath;
}

class OfflineBackgroundRemovalService {
  const OfflineBackgroundRemovalService();

  static Future<void> warmUp() async {}

  Future<void> ensureReady() async {}

  Future<BackgroundRemovalResult> removeBackground(Uint8List imageBytes) async {
    return BackgroundRemovalResult(
      pngBytes: imageBytes,
      engineLabel: 'web-noop',
      didRemoveBackground: false,
    );
  }

  Future<Uint8List> finalizeCutout(Uint8List pngBytes) async => pngBytes;
}

class CloudBackgroundRemovalService {
  const CloudBackgroundRemovalService();

  bool get isConfigured => false;

  Future<BackgroundRemovalResult> removeBackground(Uint8List imageBytes) async {
    throw UnsupportedError('Cloud Remove BG is not supported on web');
  }
}
