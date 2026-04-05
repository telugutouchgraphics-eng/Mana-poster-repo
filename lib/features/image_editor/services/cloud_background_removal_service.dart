import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudBackgroundRemovalResult {
  const CloudBackgroundRemovalResult({
    required this.pngBytes,
    required this.outputPath,
  });

  final Uint8List pngBytes;
  final String outputPath;
}

class CloudBackgroundRemovalService {
  CloudBackgroundRemovalService({
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? storage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  static const String _apiUrl = String.fromEnvironment(
    'MANA_POSTER_REMOVE_BG_API_URL',
    defaultValue:
        'https://mana-poster-rembg-lwqq2szeza-el.a.run.app/remove-bg',
  );

  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _storage;

  bool get isConfigured => _apiUrl.isNotEmpty;

  Future<CloudBackgroundRemovalResult?> removeBackground(Uint8List imageBytes) async {
    if (!isConfigured) {
      return null;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1 << 30);
    final jobId = '${timestamp}_$random';
    final inputPath = 'users/${user.uid}/rembg_jobs/$jobId/input.jpg';
    final outputPath = 'users/${user.uid}/rembg_jobs/$jobId/output.png';

    final inputRef = _storage.ref(inputPath);
    await inputRef.putData(
      imageBytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: <String, String>{
          'uid': user.uid,
          'jobId': jobId,
        },
      ),
    );

    final response = await _callBackend(
      idToken: idToken,
      inputPath: inputPath,
      outputPath: outputPath,
    );

    final downloadUrl = response['downloadUrl']?.toString();
    Uint8List? bytes;
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      bytes = await _downloadBytes(downloadUrl);
    }
    bytes ??= await _storage.ref(outputPath).getData(30 * 1024 * 1024);

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Cloud output image empty');
    }

    return CloudBackgroundRemovalResult(
      pngBytes: bytes,
      outputPath: outputPath,
    );
  }

  Future<Map<String, dynamic>> _callBackend({
    required String idToken,
    required String inputPath,
    required String outputPath,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(_apiUrl));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.add(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'inputPath': inputPath,
            'outputPath': outputPath,
            'deleteInput': true,
          }),
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final parsed = body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          parsed['message']?.toString() ??
              'Cloud remove-bg failed (${response.statusCode})',
        );
      }

      if (parsed['success'] != true) {
        throw Exception(
          parsed['message']?.toString() ?? 'Cloud remove-bg unsuccessful',
        );
      }
      return parsed;
    } finally {
      client?.close(force: true);
    }
  }

  Future<Uint8List> _downloadBytes(String url) async {
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to download processed image');
      }
      final data = await response.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
      return Uint8List.fromList(data);
    } finally {
      client?.close(force: true);
    }
  }
}
