import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';

enum TemplateEntitlementBackendState { verified, failed, notConfigured }

class TemplateEntitlementBackendResult {
  const TemplateEntitlementBackendResult({
    required this.state,
    this.message,
    this.unlockedTemplateIds = const <String>{},
  });

  final TemplateEntitlementBackendState state;
  final String? message;
  final Set<String> unlockedTemplateIds;

  bool get isConfigured =>
      state != TemplateEntitlementBackendState.notConfigured;
  bool get isSuccess => state == TemplateEntitlementBackendState.verified;
}

class TemplateEntitlementBackendService {
  TemplateEntitlementBackendService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const String _verifyUrl = String.fromEnvironment(
    'MANA_POSTER_TEMPLATE_VERIFY_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/verifyTemplatePurchase',
  );
  static const String _statusUrl = String.fromEnvironment(
    'MANA_POSTER_TEMPLATE_STATUS_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/templateEntitlementStatus',
  );

  final FirebaseAuth _firebaseAuth;

  bool get isConfigured => _verifyUrl.isNotEmpty && _statusUrl.isNotEmpty;

  Future<TemplateEntitlementBackendResult> verifyPurchase({
    required String templateId,
    required PurchaseVerificationEvidence evidence,
  }) async {
    if (!isConfigured) {
      return const TemplateEntitlementBackendResult(
        state: TemplateEntitlementBackendState.notConfigured,
      );
    }

    return _postJson(
      url: _verifyUrl,
      payload: <String, dynamic>{
        'platform': _platformLabel,
        'templateId': templateId,
        'productId': evidence.productId,
        'verificationSource': evidence.source,
        'serverVerificationData': evidence.serverVerificationData,
        'localVerificationData': evidence.localVerificationData,
        'transactionId': evidence.transactionId,
        'transactionDate': evidence.transactionDate,
        'purchaseStatus': evidence.status,
        'uid': _firebaseAuth.currentUser?.uid,
      },
    );
  }

  Future<TemplateEntitlementBackendResult> fetchEntitlements() async {
    if (!isConfigured) {
      return const TemplateEntitlementBackendResult(
        state: TemplateEntitlementBackendState.notConfigured,
      );
    }

    return _postJson(
      url: _statusUrl,
      payload: <String, dynamic>{
        'platform': _platformLabel,
        'uid': _firebaseAuth.currentUser?.uid,
      },
    );
  }

  Future<TemplateEntitlementBackendResult> _postJson({
    required String url,
    required Map<String, dynamic> payload,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;

      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      }

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return TemplateEntitlementBackendResult(
          state: TemplateEntitlementBackendState.failed,
          message: 'Backend status ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return const TemplateEntitlementBackendResult(
          state: TemplateEntitlementBackendState.failed,
          message: 'Invalid backend response',
        );
      }

      final rawIds = decoded['unlockedTemplateIds'] ?? decoded['templateIds'];
      final unlocked = rawIds is List
          ? rawIds
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toSet()
          : <String>{};

      return TemplateEntitlementBackendResult(
        state: TemplateEntitlementBackendState.verified,
        message: decoded['message']?.toString(),
        unlockedTemplateIds: unlocked,
      );
    } catch (error) {
      return TemplateEntitlementBackendResult(
        state: TemplateEntitlementBackendState.failed,
        message: error.toString(),
      );
    } finally {
      client?.close(force: true);
    }
  }

  String get _platformLabel => kIsWeb ? 'web' : Platform.operatingSystem;
}
