import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'pro_purchase_gateway.dart';

enum SubscriptionBackendState {
  verifiedPro,
  verifiedFree,
  failed,
  notConfigured,
}

class SubscriptionBackendResult {
  const SubscriptionBackendResult({
    required this.state,
    this.message,
  });

  final SubscriptionBackendState state;
  final String? message;

  bool get isPro => state == SubscriptionBackendState.verifiedPro;
  bool get isConfigured => state != SubscriptionBackendState.notConfigured;
  bool get isSuccess =>
      state == SubscriptionBackendState.verifiedPro ||
      state == SubscriptionBackendState.verifiedFree;
}

class SubscriptionBackendService {
  SubscriptionBackendService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const String _verifyUrl = String.fromEnvironment(
    'MANA_POSTER_SUBSCRIPTION_VERIFY_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/verifySubscription',
  );
  static const String _statusUrl = String.fromEnvironment(
    'MANA_POSTER_SUBSCRIPTION_STATUS_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/subscriptionStatus',
  );
  final FirebaseAuth _firebaseAuth;

  bool get isConfigured => _verifyUrl.isNotEmpty && _statusUrl.isNotEmpty;

  Future<SubscriptionBackendResult> verifyPurchase({
    required PurchaseVerificationEvidence evidence,
  }) async {
    if (!isConfigured) {
      return const SubscriptionBackendResult(
        state: SubscriptionBackendState.notConfigured,
      );
    }

    final payload = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'productId': evidence.productId,
      'verificationSource': evidence.source,
      'serverVerificationData': evidence.serverVerificationData,
      'localVerificationData': evidence.localVerificationData,
      'transactionId': evidence.transactionId,
      'transactionDate': evidence.transactionDate,
      'purchaseStatus': evidence.status,
      'uid': _firebaseAuth.currentUser?.uid,
    };

    return _postJson(url: _verifyUrl, payload: payload);
  }

  Future<SubscriptionBackendResult> fetchEntitlement() async {
    if (!isConfigured) {
      return const SubscriptionBackendResult(
        state: SubscriptionBackendState.notConfigured,
      );
    }

    return _postJson(
      url: _statusUrl,
      payload: <String, dynamic>{
        'platform': Platform.operatingSystem,
        'uid': _firebaseAuth.currentUser?.uid,
      },
    );
  }

  Future<SubscriptionBackendResult> _postJson({
    required String url,
    required Map<String, dynamic> payload,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      final uri = Uri.parse(url);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      }

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Backend status ${response.statusCode}',
        );
      }

      if (responseBody.isEmpty) {
        return const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Empty backend response',
        );
      }

      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Invalid backend response',
        );
      }

      final isProRaw = decoded['isPro'] ?? decoded['is_pro'] ?? decoded['active'];
      final message = decoded['message']?.toString();
      final isPro = isProRaw == true || isProRaw?.toString() == 'true';

      return SubscriptionBackendResult(
        state: isPro
            ? SubscriptionBackendState.verifiedPro
            : SubscriptionBackendState.verifiedFree,
        message: message,
      );
    } catch (error) {
      return SubscriptionBackendResult(
        state: SubscriptionBackendState.failed,
        message: error.toString(),
      );
    } finally {
      client?.close(force: true);
    }
  }
}
