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

class CloudBackgroundRemovalService {
  const CloudBackgroundRemovalService();

  bool get isConfigured => false;

  Future<BackgroundRemovalResult> removeBackground(Uint8List imageBytes) async {
    throw UnsupportedError('Cloud Remove BG is not supported on web');
  }
}

class CloudFirstBackgroundRemovalService {
  const CloudFirstBackgroundRemovalService();

  Future<void> ensureReady() {
    return Future<void>.value();
  }

  Future<BackgroundRemovalResult> removeBackground(
    Uint8List imageBytes, {
    bool preferCloud = true,
    String cloudPurpose = 'editor_remove_bg',
  }) {
    throw UnsupportedError('Cloud Remove BG is not supported on web');
  }

  Future<Uint8List> finalizeCutout(Uint8List pngBytes) {
    return Future<Uint8List>.value(pngBytes);
  }
}
