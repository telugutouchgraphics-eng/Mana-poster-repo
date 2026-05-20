import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

class PendingSubscriptionPurchaseBinding {
  const PendingSubscriptionPurchaseBinding({
    required this.initiatingUid,
    required this.sessionId,
    required this.productId,
    required this.startedAt,
  });

  final String initiatingUid;
  final String sessionId;
  final String productId;
  final DateTime startedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'initiatingUid': initiatingUid,
      'sessionId': sessionId,
      'productId': productId,
      'startedAtMs': startedAt.millisecondsSinceEpoch,
    };
  }

  static PendingSubscriptionPurchaseBinding? fromRawJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final initiatingUid = decoded['initiatingUid']?.toString().trim() ?? '';
      final sessionId = decoded['sessionId']?.toString().trim() ?? '';
      final productId = decoded['productId']?.toString().trim() ?? '';
      final startedAtMs = decoded['startedAtMs'];
      final millis = startedAtMs is int
          ? startedAtMs
          : int.tryParse(startedAtMs?.toString() ?? '');
      if (initiatingUid.isEmpty ||
          sessionId.isEmpty ||
          productId.isEmpty ||
          millis == null) {
        return null;
      }
      return PendingSubscriptionPurchaseBinding(
        initiatingUid: initiatingUid,
        sessionId: sessionId,
        productId: productId,
        startedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      );
    } catch (_) {
      return null;
    }
  }
}

enum PendingSubscriptionBindingDecision {
  allowed,
  noBinding,
  noAuthenticatedUser,
  uidMismatch,
  productMismatch,
  staleBinding,
  transactionTooOld,
}

class PendingSubscriptionBindingCheckResult {
  const PendingSubscriptionBindingCheckResult({
    required this.decision,
    this.binding,
    this.currentUid,
  });

  final PendingSubscriptionBindingDecision decision;
  final PendingSubscriptionPurchaseBinding? binding;
  final String? currentUid;

  bool get isAllowed =>
      decision == PendingSubscriptionBindingDecision.allowed;
}

class PlayBillingAccountBindingService {
  PlayBillingAccountBindingService._();

  static const String _pendingSubscriptionBindingKey =
      'mana_poster_pending_subscription_binding_v1';
  static const Duration _bindingMaxAge = Duration(hours: 24);
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final PlayBillingAccountBindingService instance =
      PlayBillingAccountBindingService._();
  static final Random _random = Random.secure();

  Future<PendingSubscriptionPurchaseBinding?> loadPendingSubscriptionBinding()
      async {
    final raw = await _loadRawBinding();
    return PendingSubscriptionPurchaseBinding.fromRawJson(raw);
  }

  Future<PendingSubscriptionPurchaseBinding?> bindSubscriptionPurchaseToUid({
    required String productId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      _logSecurityWarning(
        action: 'purchase_initiation_without_uid',
        details: <String, Object?>{'productId': productId},
      );
      return null;
    }
    final binding = PendingSubscriptionPurchaseBinding(
      initiatingUid: uid,
      sessionId: _generateSessionId(),
      productId: productId,
      startedAt: DateTime.now(),
    );
    await _secureStorage.write(
      key: _pendingSubscriptionBindingKey,
      value: jsonEncode(binding.toJson()),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSubscriptionBindingKey);
    return binding;
  }

  Future<String?> _loadRawBinding() async {
    final secureValue = await _secureStorage.read(key: _pendingSubscriptionBindingKey);
    if (secureValue != null && secureValue.trim().isNotEmpty) {
      return secureValue;
    }
    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(_pendingSubscriptionBindingKey);
    if (legacyValue != null && legacyValue.trim().isNotEmpty) {
      await _secureStorage.write(
        key: _pendingSubscriptionBindingKey,
        value: legacyValue,
      );
      await prefs.remove(_pendingSubscriptionBindingKey);
      return legacyValue;
    }
    return null;
  }

  Future<void> clearPendingSubscriptionBinding({
    String reason = 'cleared',
  }) async {
    final existing = PendingSubscriptionPurchaseBinding.fromRawJson(
      await _loadRawBinding(),
    );
    if (existing != null) {
      _logSecurityWarning(
        action: 'pending_purchase_binding_removed',
        details: <String, Object?>{
          'reason': reason,
          'initiatingUid': existing.initiatingUid,
          'sessionId': existing.sessionId,
          'productId': existing.productId,
        },
      );
    }
    await _secureStorage.delete(key: _pendingSubscriptionBindingKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSubscriptionBindingKey);
  }

  Future<void> clearPendingSubscriptionBindingIfOwnedByDifferentUid({
    required String? nextUid,
    required String reason,
  }) async {
    final binding = await loadPendingSubscriptionBinding();
    if (binding == null) {
      return;
    }
    final normalizedNextUid = nextUid?.trim() ?? '';
    if (normalizedNextUid.isEmpty) {
      return;
    }
    if (normalizedNextUid == binding.initiatingUid) {
      return;
    }
    _logSecurityWarning(
      action: 'pending_purchase_abandoned_due_to_account_switch',
      details: <String, Object?>{
        'reason': reason,
        'initiatingUid': binding.initiatingUid,
        'nextUid': normalizedNextUid.isEmpty ? null : normalizedNextUid,
        'sessionId': binding.sessionId,
        'productId': binding.productId,
      },
    );
    await clearPendingSubscriptionBinding(reason: reason);
  }

  Future<PendingSubscriptionBindingCheckResult>
  ensureCurrentUserCanClaimPendingSubscription({
    required String productId,
    required String trigger,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (currentUid.isEmpty) {
      _logSecurityWarning(
        action: 'pending_purchase_claim_blocked_no_uid',
        details: <String, Object?>{
          'trigger': trigger,
          'productId': productId,
        },
      );
      return const PendingSubscriptionBindingCheckResult(
        decision: PendingSubscriptionBindingDecision.noAuthenticatedUser,
      );
    }

    final binding = await loadPendingSubscriptionBinding();
    if (binding == null) {
      _logSecurityWarning(
        action: 'pending_purchase_claim_blocked_no_binding',
        details: <String, Object?>{
          'trigger': trigger,
          'uid': currentUid,
          'productId': productId,
        },
      );
      return PendingSubscriptionBindingCheckResult(
        decision: PendingSubscriptionBindingDecision.noBinding,
        currentUid: currentUid,
      );
    }

    if (DateTime.now().difference(binding.startedAt) > _bindingMaxAge) {
      _logSecurityWarning(
        action: 'pending_purchase_claim_blocked_stale_binding',
        details: <String, Object?>{
          'trigger': trigger,
          'uid': currentUid,
          'initiatingUid': binding.initiatingUid,
          'sessionId': binding.sessionId,
          'productId': binding.productId,
        },
      );
      await clearPendingSubscriptionBinding(reason: 'stale_binding');
      return PendingSubscriptionBindingCheckResult(
        decision: PendingSubscriptionBindingDecision.staleBinding,
        binding: binding,
        currentUid: currentUid,
      );
    }

    if (binding.initiatingUid != currentUid) {
      _logSecurityWarning(
        action: 'pending_purchase_claim_blocked_uid_mismatch',
        details: <String, Object?>{
          'trigger': trigger,
          'currentUid': currentUid,
          'initiatingUid': binding.initiatingUid,
          'sessionId': binding.sessionId,
          'productId': binding.productId,
        },
      );
      await clearPendingSubscriptionBinding(reason: 'uid_mismatch');
      return PendingSubscriptionBindingCheckResult(
        decision: PendingSubscriptionBindingDecision.uidMismatch,
        binding: binding,
        currentUid: currentUid,
      );
    }

    if (binding.productId != productId) {
      _logSecurityWarning(
        action: 'pending_purchase_claim_blocked_product_mismatch',
        details: <String, Object?>{
          'trigger': trigger,
          'uid': currentUid,
          'initiatingUid': binding.initiatingUid,
          'sessionId': binding.sessionId,
          'expectedProductId': binding.productId,
          'actualProductId': productId,
        },
      );
      return PendingSubscriptionBindingCheckResult(
        decision: PendingSubscriptionBindingDecision.productMismatch,
        binding: binding,
        currentUid: currentUid,
      );
    }

    return PendingSubscriptionBindingCheckResult(
      decision: PendingSubscriptionBindingDecision.allowed,
      binding: binding,
      currentUid: currentUid,
    );
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final randomPart = List<String>.generate(
      4,
      (_) => _random.nextInt(0x7fffffff).toRadixString(16),
      growable: false,
    ).join();
    return '$timestamp-$randomPart';
  }

  void _logSecurityWarning({
    required String action,
    required Map<String, Object?> details,
  }) {
    final serialized = details.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    if (kDebugMode) {
      debugPrint('[billing-security] $action $serialized');
    }
  }
}
