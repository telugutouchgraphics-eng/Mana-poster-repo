import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;

import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/features/image_editor/services/play_billing_account_binding_service.dart';
import 'package:mana_poster/features/prehome/services/premium_template_access_service.dart';
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
    this.productId,
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
  final String? productId;
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
    : _firebaseAuthOverride = firebaseAuth;

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
  static Future<void>? _pendingRecoveryFuture;
  static final ValueNotifier<SubscriptionBackendResult?> entitlementNotifier =
      ValueNotifier<SubscriptionBackendResult?>(null);
  final FirebaseAuth? _firebaseAuthOverride;
  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;

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
    await PlayBillingAccountBindingService.instance
        .clearPendingSubscriptionBindingIfOwnedByDifferentUid(
          nextUid: FirebaseAuth.instance.currentUser?.uid,
          reason: 'auth_change',
        );
    await PremiumTemplateAccessService.clearLegacyLocalPremiumState();
    await InAppPurchaseGateway.syncBackendEntitlement(false);
  }

  Future<SubscriptionBackendResult> fetchEntitlementWithCache({
    bool forceRefresh = false,
  }) async {
    final cached = _cachedEntitlement;
    if (!forceRefresh && hasFreshEntitlementCache && cached != null) {
      return cached;
    }
    return _fetchEntitlementFromBackend();
  }

  Future<SubscriptionBackendResult> _fetchEntitlementFromBackend() async {
    if (!isConfigured) {
      return const SubscriptionBackendResult(
        state: SubscriptionBackendState.notConfigured,
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

  Future<SubscriptionBackendResult> fetchEntitlement({
    bool forceRefresh = false,
  }) async {
    final cached = _cachedEntitlement;
    if (!forceRefresh && hasFreshEntitlementCache && cached != null) {
      return _cachedEntitlement!;
    }
    return _fetchEntitlementFromBackend();
  }

  Future<void> refreshEntitlementInBackground({
    bool forceRefresh = true,
    bool clearCacheFirst = false,
  }) async {
    try {
      if (clearCacheFirst) {
        clearEntitlementCache();
      }
      final previousCached = _cachedEntitlement;
      final previousCachedAt = _cachedEntitlementAt;
      final result = await fetchEntitlement(forceRefresh: forceRefresh);
      if (result.state == SubscriptionBackendState.failed &&
          previousCached != null) {
        _cachedEntitlement = previousCached;
        _cachedEntitlementAt = previousCachedAt;
        entitlementNotifier.value = previousCached;
      }
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
    // Avoid clearing entitlement twice — keeps UI/cache stable during retries.
    var result = await fetchEntitlement(forceRefresh: true);
    if (result.hasAccess || retryDelay <= Duration.zero) {
      return result;
    }
    await Future<void>.delayed(retryDelay);
    result = await fetchEntitlement(forceRefresh: true);
    return result;
  }

  Future<void> recoverPendingPurchaseInBackground() async {
    final existing = _pendingRecoveryFuture;
    if (existing != null) {
      return existing;
    }
    final future = _recoverPendingPurchaseInBackgroundOnce();
    _pendingRecoveryFuture = future;
    try {
      await future;
    } catch (_) {
      // Keep recovery best-effort; Play will continue surfacing unfinished
      // purchases until they are verified and completed.
    } finally {
      if (identical(_pendingRecoveryFuture, future)) {
        _pendingRecoveryFuture = null;
      }
    }
  }

  Future<void> _recoverPendingPurchaseInBackgroundOnce() async {
    final evidence = await InAppPurchaseGateway().recoverUnfinishedPurchase();
    if (evidence == null) {
      return;
    }
    final verification = await verifyPurchase(evidence: evidence);
    if (!verification.hasAccess) {
      return;
    }
    await evidence.completeStorePurchase();
    await PlayBillingAccountBindingService.instance
        .clearPendingSubscriptionBinding(reason: 'pending_purchase_recovered');
    await fetchFreshEntitlementWithRetry();
  }

  Future<SubscriptionBackendResult> verifyPurchase({
    required PurchaseVerificationEvidence evidence,
  }) async {
    if (!isConfigured) {
      return const SubscriptionBackendResult(
        state: SubscriptionBackendState.notConfigured,
      );
    }
    final bindingCheck = await PlayBillingAccountBindingService.instance
        .ensureCurrentUserCanClaimPendingSubscription(
          productId: evidence.productId,
          trigger: 'verify_purchase_request',
        );
    if (!bindingCheck.isAllowed) {
      return SubscriptionBackendResult(
        state: SubscriptionBackendState.failed,
        message:
            'Purchase verification blocked for current account (${bindingCheck.decision.name})',
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
          subscriptionState: decoded['subscriptionState'],
        ),
        productId: decoded['productId']?.toString(),
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
      if (result.hasAccess) {
        await PlayBillingAccountBindingService.instance
            .clearPendingSubscriptionBinding(
              reason: 'backend_verification_success',
            );
      }
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
      return SubscriptionPlanStatus.inactive;
    }

    final normalizedSubscriptionState =
        subscriptionState?.toString().trim().toLowerCase() ?? '';
    if (normalizedSubscriptionState.contains('expired') ||
        normalizedSubscriptionState.contains('canceled') ||
        normalizedSubscriptionState.contains('cancelled')) {
      return SubscriptionPlanStatus.expired;
    }
    if (isPro) {
      return SubscriptionPlanStatus.active;
    }
    return SubscriptionPlanStatus.inactive;
  }

  String get _platformLabel => kIsWeb ? 'web' : Platform.operatingSystem;
}
