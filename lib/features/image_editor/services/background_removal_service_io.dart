import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const int _cloudRemoveBgMaxUploadBytes = 14 * 1024 * 1024;

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

class CloudFirstBackgroundRemovalService {
  const CloudFirstBackgroundRemovalService();

  static const String _productionApiUrl =
      'https://mana-poster-rembg-lwqq2szeza-el.a.run.app/remove-bg';
  static const String _apiUrl = String.fromEnvironment(
    'MANA_POSTER_REMOVE_BG_API_URL',
    defaultValue: _productionApiUrl,
  );
  static const String _pixelcutApiUrl = String.fromEnvironment(
    'MANA_POSTER_PIXELCUT_REMOVE_BG_API_URL',
    defaultValue: _productionApiUrl,
  );
  static const String _backgroundRemoveApiUrl = String.fromEnvironment(
    'MANA_POSTER_BACKGROUND_REMOVE_API_URL',
    defaultValue: _productionApiUrl,
  );

  Future<void> ensureReady() {
    return Future<void>.value();
  }

  Future<BackgroundRemovalResult> removeBackground(
    Uint8List imageBytes, {
    bool preferCloud = true,
    String cloudPurpose = 'editor_remove_bg',
  }) async {
    final cloudUrls = _cloudRemoveBgUrls();
    if (!preferCloud || cloudUrls.isEmpty) {
      throw StateError('Cloud background removal endpoint is not configured.');
    }
    Object? lastError;
    StackTrace? lastStackTrace;
    for (final cloudUrl in cloudUrls) {
      try {
        return await _removeWithCloud(
          imageBytes,
          cloudUrl,
          cloudPurpose,
        ).timeout(const Duration(seconds: 75));
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }
    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  List<String> _cloudRemoveBgUrls() {
    final urls =
        <String>[
              _apiUrl,
              _pixelcutApiUrl,
              _backgroundRemoveApiUrl,
              _productionApiUrl,
            ]
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList(growable: false);
    return <String>{for (final url in urls) url}.toList(growable: false);
  }

  Future<BackgroundRemovalResult> _removeWithCloud(
    Uint8List imageBytes,
    String apiUrl,
    String cloudPurpose,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Background removal requires a signed-in user.');
    }
    final idToken = await user.getIdToken();
    final upload = _prepareCloudRemoveBgUpload(imageBytes);
    final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..headers[HttpHeaders.authorizationHeader] = 'Bearer $idToken'
      ..fields['purpose'] = cloudPurpose
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          upload.bytes,
          filename: upload.filename,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Cloud remove BG failed: ${response.statusCode} ${response.body}',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw StateError('Cloud remove BG returned an empty image.');
    }
    return BackgroundRemovalResult(
      pngBytes: response.bodyBytes,
      engineLabel:
          response.headers['x-remove-bg-engine']?.trim().isNotEmpty == true
          ? response.headers['x-remove-bg-engine']!.trim()
          : 'cloud',
      didRemoveBackground: true,
      outputFilePath: null,
    );
  }
}

({Uint8List bytes, String filename}) _prepareCloudRemoveBgUpload(
  Uint8List sourceBytes,
) {
  if (sourceBytes.length <= _cloudRemoveBgMaxUploadBytes) {
    return (bytes: sourceBytes, filename: 'input.png');
  }

  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    return (bytes: sourceBytes, filename: 'input.png');
  }

  var working = img.bakeOrientation(decoded);
  for (final quality in <int>[96, 92, 88]) {
    final encoded = Uint8List.fromList(
      img.encodeJpg(working, quality: quality),
    );
    if (encoded.length <= _cloudRemoveBgMaxUploadBytes) {
      return (bytes: encoded, filename: 'input.jpg');
    }
  }

  final longestSide = math.max(working.width, working.height);
  for (final targetSide in <int>[4096, 3200, 2560]) {
    if (longestSide > targetSide) {
      final scale = targetSide / longestSide;
      working = img.copyResize(
        working,
        width: math.max(1, (working.width * scale).round()),
        height: math.max(1, (working.height * scale).round()),
        interpolation: img.Interpolation.linear,
      );
    }
    for (final quality in <int>[94, 90, 86]) {
      final encoded = Uint8List.fromList(
        img.encodeJpg(working, quality: quality),
      );
      if (encoded.length <= _cloudRemoveBgMaxUploadBytes) {
        return (bytes: encoded, filename: 'input.jpg');
      }
    }
  }

  final encoded = Uint8List.fromList(img.encodeJpg(working, quality: 82));
  return (bytes: encoded, filename: 'input.jpg');
}
