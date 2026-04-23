import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:mana_poster/features/prehome/models/landing_page_config.dart';
import 'package:mana_poster/features/prehome/models/website_poster.dart';

class WebsiteAdminContent {
  const WebsiteAdminContent({
    required this.config,
    required this.posters,
    required this.adminPrimaryEmail,
  });

  final LandingPageConfig config;
  final List<WebsitePoster> posters;
  final String adminPrimaryEmail;
}

class WebsiteAssetUploadResult {
  const WebsiteAssetUploadResult({
    required this.downloadUrl,
    required this.path,
    required this.contentType,
    required this.bytes,
  });

  final String downloadUrl;
  final String path;
  final String contentType;
  final int bytes;
}

class WebsiteAdminService {
  WebsiteAdminService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const String _baseFunctionsUrl = String.fromEnvironment(
    'MANA_POSTER_FUNCTIONS_BASE_URL',
    defaultValue: 'https://asia-south1-mana-poster-ap.cloudfunctions.net',
  );

  final FirebaseAuth _firebaseAuth;

  Uri get _getContentUri =>
      Uri.parse('$_baseFunctionsUrl/websiteAdminGetContent');
  Uri get _updateConfigUri =>
      Uri.parse('$_baseFunctionsUrl/websiteAdminUpdateConfig');
  Uri get _upsertPosterUri =>
      Uri.parse('$_baseFunctionsUrl/websiteAdminUpsertPoster');
  Uri get _deletePosterUri =>
      Uri.parse('$_baseFunctionsUrl/websiteAdminDeletePoster');
  Uri get _uploadAssetUri =>
      Uri.parse('$_baseFunctionsUrl/websiteAdminUploadAsset');
  Uri get _updateAccessUri =>
      Uri.parse('$_baseFunctionsUrl/websiteAdminUpdateAccess');

  Future<WebsiteAdminContent> loadContent() async {
    final decoded = await _postJson(
      _getContentUri,
      const <String, dynamic>{},
    );
    final configMap =
        decoded['config'] is Map<String, dynamic>
            ? decoded['config'] as Map<String, dynamic>
            : <String, dynamic>{};
    final postersRaw = decoded['posters'];
    final posters = postersRaw is List
        ? postersRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .map(
                (item) => WebsitePoster.fromMap(
                  item,
                  id: (item['id'] as String? ?? '').trim(),
                ),
              )
              .where(
                (poster) =>
                    poster.id.isNotEmpty &&
                    poster.category.isNotEmpty &&
                    poster.imageUrl.isNotEmpty,
              )
              .toList(growable: false)
        : const <WebsitePoster>[];
    return WebsiteAdminContent(
      config: LandingPageConfig.fromMap(configMap),
      posters: posters,
      adminPrimaryEmail: (decoded['adminPrimaryEmail'] as String? ?? '').trim(),
    );
  }

  Future<void> saveConfig(LandingPageConfig config) async {
    await _postJson(_updateConfigUri, config.toMap());
  }

  Future<WebsitePoster> upsertPoster({
    String? posterId,
    required String category,
    required String imageUrl,
    required int sortOrder,
    required bool active,
  }) async {
    final decoded = await _postJson(_upsertPosterUri, <String, dynamic>{
      'posterId': posterId,
      'category': category,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'active': active,
    });
    final posterMap =
        decoded['poster'] is Map<String, dynamic>
            ? decoded['poster'] as Map<String, dynamic>
            : <String, dynamic>{};
    return WebsitePoster.fromMap(
      posterMap,
      id: (posterMap['id'] as String? ?? posterId ?? '').trim(),
    );
  }

  Future<void> deletePoster(String posterId) async {
    await _postJson(_deletePosterUri, <String, dynamic>{'posterId': posterId});
  }

  Future<WebsiteAssetUploadResult> uploadPosterImage({
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) {
    return _uploadAsset(
      assetType: 'posterImage',
      fileName: fileName,
      contentType: contentType,
      bytes: bytes,
    );
  }

  Future<WebsiteAssetUploadResult> uploadDemoVideo({
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) {
    return _uploadAsset(
      assetType: 'demoVideo',
      fileName: fileName,
      contentType: contentType,
      bytes: bytes,
    );
  }

  Future<String> updateAdminCredentials({
    required String newEmail,
    required String newPassword,
  }) async {
    final decoded = await _postJson(_updateAccessUri, <String, dynamic>{
      'newEmail': newEmail.trim(),
      'newPassword': newPassword,
    });
    return (decoded['primaryEmail'] as String? ?? '').trim();
  }

  Future<WebsiteAssetUploadResult> _uploadAsset({
    required String assetType,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final decoded = await _postJson(_uploadAssetUri, <String, dynamic>{
      'assetType': assetType,
      'fileName': fileName,
      'contentType': contentType,
      'base64Data': base64Encode(bytes),
    });
    return WebsiteAssetUploadResult(
      downloadUrl: (decoded['downloadUrl'] as String? ?? '').trim(),
      path: (decoded['path'] as String? ?? '').trim(),
      contentType: (decoded['contentType'] as String? ?? '').trim(),
      bytes: decoded['bytes'] is num ? (decoded['bytes'] as num).toInt() : 0,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken != null && idToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebsiteAdminFailure(
        _extractMessage(response.body) ??
            'Request failed with status ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const WebsiteAdminFailure('Invalid backend response');
    }
    if (decoded['success'] == false) {
      throw WebsiteAdminFailure(
        decoded['message']?.toString() ?? 'Request failed',
      );
    }
    return decoded;
  }

  String? _extractMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }
    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        return message?.isNotEmpty == true ? message : null;
      }
    } catch (_) {
      return responseBody.trim();
    }
    return null;
  }
}

class WebsiteAdminFailure implements Exception {
  const WebsiteAdminFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
