import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;

import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'pro_purchase_gateway.dart';

enum SubscriptionBackendState {
  verifiedPro,
  verifiedFree,
  failed,
  notConfigured,
}

enum SubscriptionPlanStatus { active, expired, inactive, unknown }

class SubscriptionBackendResult {
  const SubscriptionBackendResult({
    required this.state,
    this.message,
    this.status,
    this.startDate,
    this.expiryTime,
    this.autoRenewing,
    this.latestOrderId,
    this.subscriptionState,
    this.lastSyncedAt,
  });

  final SubscriptionBackendState state;
  final String? message;
  final SubscriptionPlanStatus? status;
  final DateTime? startDate;
  final DateTime? expiryTime;
  final bool? autoRenewing;
  final String? latestOrderId;
  final String? subscriptionState;
  final DateTime? lastSyncedAt;

  bool get isPro => state == SubscriptionBackendState.verifiedPro;
  bool get isConfigured => state != SubscriptionBackendState.notConfigured;
  bool get isSuccess =>
      state == SubscriptionBackendState.verifiedPro ||
      state == SubscriptionBackendState.verifiedFree;
  bool get isActive => status == SubscriptionPlanStatus.active;
  bool get isExpired => status == SubscriptionPlanStatus.expired;
  bool get hasAccess => isPro && isActive;
}

class SubscriptionBackendService {
  SubscriptionBackendService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

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
  static SubscriptionBackendResult? _cachedEntitlement;
  static DateTime? _cachedEntitlementAt;
  static final ValueNotifier<SubscriptionBackendResult?> entitlementNotifier =
      ValueNotifier<SubscriptionBackendResult?>(null);
  final FirebaseAuth _firebaseAuth;

  bool get isConfigured => _verifyUrl.isNotEmpty && _statusUrl.isNotEmpty;
  SubscriptionBackendResult? get cachedEntitlement => _cachedEntitlement;
  DateTime? get cachedEntitlementAt => _cachedEntitlementAt;
  bool get hasFreshEntitlementCache {
    final cachedAt = _cachedEntitlementAt;
    if (cachedAt == null || _cachedEntitlement == null) {
      return false;
    }
    return DateTime.now().difference(cachedAt) <=
        SubscriptionPlanConfig.entitlementCacheTtl;
  }

  void clearEntitlementCache() {
    _cachedEntitlement = null;
    _cachedEntitlementAt = null;
    entitlementNotifier.value = null;
  }

  /// Call when auth uid changes or user signs out so another account never
  /// inherits entitlement UI / cached Pro flags.
  static Future<void> resetLocalClientStateForAuthChange() async {
    _cachedEntitlement = null;
    _cachedEntitlementAt = null;
    entitlementNotifier.value = null;
    await InAppPurchaseGateway.syncBackendEntitlement(false);
  }

  Future<SubscriptionBackendResult> fetchEntitlementWithCache({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        hasFreshEntitlementCache &&
        _cachedEntitlement != null) {
      return _cachedEntitlement!;
    }
    return fetchEntitlement(forceRefresh: true);
  }

  Future<void> refreshEntitlementInBackground({
    bool forceRefresh = true,
    bool clearCacheFirst = false,
  }) async {
    try {
      if (clearCacheFirst) {
        clearEntitlementCache();
      }
      await fetchEntitlement(forceRefresh: forceRefresh);
    } catch (_) {
      // Ignore background refresh failures and preserve the last known cache.
    }
  }

  Future<SubscriptionBackendResult> fetchFreshEntitlement() async {
    clearEntitlementCache();
    return fetchEntitlement(forceRefresh: true);
  }

  Future<SubscriptionBackendResult> fetchFreshEntitlementWithRetry({
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    var result = await fetchFreshEntitlement();
    if (result.hasAccess || retryDelay <= Duration.zero) {
      return result;
    }
    await Future<void>.delayed(retryDelay);
    result = await fetchFreshEntitlement();
    return result;
  }

  Future<SubscriptionBackendResult> verifyPurchase({
    required PurchaseVerificationEvidence evidence,
  }) async {
    if (!isConfigured) {
      return const SubscriptionBackendResult(
        state: SubscriptionBackendState.notConfigured,
      );
    }

    final payload = <String, dynamic>{
      'platform': _platformLabel,
      'productId': evidence.productId,
      'verificationSource': evidence.source,
      'serverVerificationData': evidence.serverVerificationData,
      'localVerificationData': evidence.localVerificationData,
      'transactionId': evidence.transactionId,
      'transactionDate': evidence.transactionDate,
      'purchaseStatus': evidence.status,
      'uid': _firebaseAuth.currentUser?.uid,
    };

    return _postJson(
      url: _verifyUrl,
      payload: payload,
      requireFreshToken: true,
    );
  }

  Future<SubscriptionBackendResult> fetchEntitlement({
    bool forceRefresh = false,
  }) async {
    if (!isConfigured) {
      return const SubscriptionBackendResult(
        state: SubscriptionBackendState.notConfigured,
      );
    }

    if (!forceRefresh &&
        hasFreshEntitlementCache &&
        _cachedEntitlement != null) {
      return _cachedEntitlement!;
    }

    return _postJson(
      url: _statusUrl,
      payload: <String, dynamic>{
        'platform': _platformLabel,
        'uid': _firebaseAuth.currentUser?.uid,
      },
    );
  }

  Future<SubscriptionBackendResult> _postJson({
    required String url,
    required Map<String, dynamic> payload,
    bool requireFreshToken = false,
  }) async {
    SubscriptionBackendResult? firstFailure;
    final attempts = <bool>[requireFreshToken, true];
    for (var index = 0; index < attempts.length; index++) {
      final result = await _postJsonAttempt(
        url: url,
        payload: payload,
        forceRefreshToken: attempts[index],
      );
      if (result.isSuccess) {
        return result;
      }
      firstFailure ??= result;
      final shouldRetry =
          index == 0 &&
          result.state == SubscriptionBackendState.failed &&
          (result.message?.contains('Backend status 401') == true ||
              result.message?.toLowerCase().contains('token') == true ||
              result.message?.toLowerCase().contains('auth') == true ||
              result.message?.toLowerCase().contains('unauthorized') == true);
      if (!shouldRetry) {
        return result;
      }
    }
    return firstFailure ??
        const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Subscription verification failed',
        );
  }

  Future<SubscriptionBackendResult> _postJsonAttempt({
    required String url,
    required Map<String, dynamic> payload,
    required bool forceRefreshToken,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      final uri = Uri.parse(url);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final idToken = await _obtainIdToken(forceRefresh: forceRefreshToken);
      if (idToken != null && idToken.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      }

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final backendMessage = _extractBackendMessage(responseBody);
        return SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: backendMessage?.isNotEmpty == true
              ? '$backendMessage (status ${response.statusCode})'
              : 'Backend status ${response.statusCode}',
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

      final isProRaw =
          decoded['isPro'] ?? decoded['is_pro'] ?? decoded['active'];
      final message = decoded['message']?.toString();
      final isPro = isProRaw == true || isProRaw?.toString() == 'true';
      final expiryTime = _parseDateTime(
        decoded['expiryTime'] ?? decoded['expiryDate'],
      );
      final startDate = _parseDateTime(
        decoded['startDate'] ??
            decoded['startTime'] ??
            decoded['subscribedOn'] ??
            decoded['subscribedAt'],
      );

      final result = SubscriptionBackendResult(
        state: isPro
            ? SubscriptionBackendState.verifiedPro
            : SubscriptionBackendState.verifiedFree,
        message: message,
        status: _parsePlanStatus(
          rawStatus: decoded['status'],
          isPro: isPro,
          expiryTime: expiryTime,
          subscriptionState: decoded['subscriptionState'],
        ),
        startDate: startDate,
        expiryTime: expiryTime,
        autoRenewing: _parseBool(decoded['autoRenewing']),
        latestOrderId: decoded['latestOrderId']?.toString(),
        subscriptionState: decoded['subscriptionState']?.toString(),
        lastSyncedAt: _parseDateTime(decoded['lastSyncedAt']),
      );
      await InAppPurchaseGateway.syncBackendEntitlement(result.hasAccess);
      _cachedEntitlement = result;
      _cachedEntitlementAt = DateTime.now();
      entitlementNotifier.value = result;
      return result;
    } catch (error) {
      return SubscriptionBackendResult(
        state: SubscriptionBackendState.failed,
        message: error.toString(),
      );
    } finally {
      client?.close(force: true);
    }
  }

  Future<String?> _obtainIdToken({required bool forceRefresh}) async {
    var user = _firebaseAuth.currentUser;
    if (user == null) {
      try {
        user = await _firebaseAuth
            .authStateChanges()
            .firstWhere((item) => item != null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        user = _firebaseAuth.currentUser;
      }
    }
    if (user == null) {
      return null;
    }
    try {
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      if (!forceRefresh) {
        return user.getIdToken(true);
      }
      rethrow;
    }
  }

  String? _extractBackendMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      return responseBody.trim();
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  bool? _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final raw = value?.toString().trim().toLowerCase();
    if (raw == 'true') {
      return true;
    }
    if (raw == 'false') {
      return false;
    }
    return null;
  }

  SubscriptionPlanStatus _parsePlanStatus({
    required dynamic rawStatus,
    required bool isPro,
    required DateTime? expiryTime,
    required dynamic subscriptionState,
  }) {
    final normalizedStatus = rawStatus?.toString().trim().toLowerCase();
    if (normalizedStatus == 'active') {
      return SubscriptionPlanStatus.active;
    }
    if (normalizedStatus == 'expired') {
      return SubscriptionPlanStatus.expired;
    }
    if (normalizedStatus == 'inactive') {
      return expiryTime != null && expiryTime.isBefore(DateTime.now())
          ? SubscriptionPlanStatus.expired
          : SubscriptionPlanStatus.inactive;
    }

    final normalizedSubscriptionState =
        subscriptionState?.toString().trim().toLowerCase() ?? '';
    if (normalizedSubscriptionState.contains('expired') ||
        normalizedSubscriptionState.contains('canceled') ||
        normalizedSubscriptionState.contains('cancelled')) {
      return SubscriptionPlanStatus.expired;
    }
    if (expiryTime != null && expiryTime.isBefore(DateTime.now())) {
      return SubscriptionPlanStatus.expired;
    }
    if (isPro) {
      return SubscriptionPlanStatus.active;
    }
    return SubscriptionPlanStatus.inactive;
  }

  String get _platformLabel => kIsWeb ? 'web' : Platform.operatingSystem;
}
