import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/config/app_public_info.dart';

class ReferralRewardStatus {
  const ReferralRewardStatus({
    required this.code,
    required this.link,
    required this.requiredPaidReferrals,
    required this.rewardDays,
    required this.currentCyclePaidCount,
    required this.currentCycleNumber,
    required this.totalPaidReferralCount,
    required this.rewardActive,
    this.rewardExpiresAt,
  });

  final String code;
  final String link;
  final int requiredPaidReferrals;
  final int rewardDays;
  final int currentCyclePaidCount;
  final int currentCycleNumber;
  final int totalPaidReferralCount;
  final bool rewardActive;
  final DateTime? rewardExpiresAt;

  int get remainingPaidReferrals {
    final remaining = requiredPaidReferrals - currentCyclePaidCount;
    return remaining < 0 ? 0 : remaining;
  }

  factory ReferralRewardStatus.fromJson(Map<String, dynamic> json) {
    return ReferralRewardStatus(
      code: (json['code'] ?? '').toString(),
      link: (json['link'] ?? AppPublicInfo.playStoreUrl).toString(),
      requiredPaidReferrals: _readInt(json['requiredPaidReferrals'], 15),
      rewardDays: _readInt(json['rewardDays'], 30),
      currentCyclePaidCount: _readInt(json['currentCyclePaidCount'], 0),
      currentCycleNumber: _readInt(json['currentCycleNumber'], 1),
      totalPaidReferralCount: _readInt(json['totalPaidReferralCount'], 0),
      rewardActive:
          json['rewardActive'] == true ||
          json['rewardActive']?.toString() == 'true',
      rewardExpiresAt: DateTime.tryParse(
        (json['rewardExpiresAt'] ?? '').toString(),
      )?.toLocal(),
    );
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class ReferralRewardApplyResult {
  const ReferralRewardApplyResult({
    required this.accepted,
    required this.message,
  });

  final bool accepted;
  final String message;
}

class ReferralRewardService {
  ReferralRewardService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const String _statusUrl = String.fromEnvironment(
    'MANA_POSTER_REFERRAL_STATUS_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/referralStatus',
  );
  static const String _applyUrl = String.fromEnvironment(
    'MANA_POSTER_REFERRAL_APPLY_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/applyReferralCode',
  );
  static const String _installReferrerAppliedKey =
      'mana_poster_referral_install_referrer_applied';
  static const String _installReferrerAttemptCountKey =
      'mana_poster_referral_install_referrer_attempt_count';
  static const String _pendingInstallReferralCodeKey =
      'mana_poster_pending_install_referral_code';

  final FirebaseAuth _firebaseAuth;

  Future<ReferralRewardStatus> fetchStatus() async {
    final body = await _postJson(_statusUrl, const <String, dynamic>{});
    return ReferralRewardStatus.fromJson(body);
  }

  Future<ReferralRewardApplyResult> applyCode(String code) async {
    final normalized = normalizeCode(code);
    if (normalized.isEmpty) {
      return const ReferralRewardApplyResult(
        accepted: false,
        message: 'Referral code is required',
      );
    }
    final body = await _postJson(_applyUrl, <String, dynamic>{
      'referralCode': normalized,
    });
    return ReferralRewardApplyResult(
      accepted:
          body['accepted'] == true || body['accepted']?.toString() == 'true',
      message: (body['message'] ?? '').toString(),
    );
  }

  Future<void> applyInstallReferrerIfAvailable() async {
    if (!Platform.isAndroid) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_installReferrerAppliedKey) == true) {
      return;
    }

    var code = normalizeCode(
      prefs.getString(_pendingInstallReferralCodeKey) ?? '',
    );
    if (code.isEmpty) {
      try {
        final details = await PlayInstallReferrer.installReferrer.timeout(
          const Duration(seconds: 4),
        );
        code = _extractReferralCode(details.installReferrer ?? '');
      } catch (_) {
        return;
      }
    }
    if (code.isEmpty) {
      final attempts = prefs.getInt(_installReferrerAttemptCountKey) ?? 0;
      if (attempts >= 2) {
        await prefs.setBool(_installReferrerAppliedKey, true);
      } else {
        await prefs.setInt(_installReferrerAttemptCountKey, attempts + 1);
      }
      return;
    }
    if (_firebaseAuth.currentUser == null) {
      await prefs.setString(_pendingInstallReferralCodeKey, code);
      return;
    }

    try {
      final result = await applyCode(code);
      if (result.accepted ||
          result.message.toLowerCase().contains('already applied')) {
        await prefs.setBool(_installReferrerAppliedKey, true);
        await prefs.remove(_installReferrerAttemptCountKey);
        await prefs.remove(_pendingInstallReferralCodeKey);
      }
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('cannot be used') ||
          message.contains('not found') ||
          message.contains('already applied')) {
        await prefs.setBool(_installReferrerAppliedKey, true);
        await prefs.remove(_installReferrerAttemptCountKey);
        await prefs.remove(_pendingInstallReferralCodeKey);
        return;
      }
      await prefs.setString(_pendingInstallReferralCodeKey, code);
    }
  }

  String buildShareText({
    required ReferralRewardStatus status,
    required String userName,
  }) {
    return '$userName invited you to ${AppPublicInfo.appName}\n'
        'Use referral code: ${status.code}\n'
        'Subscribe after joining. When 15 paid friends join, the inviter gets ${status.rewardDays} days free premium.\n'
        'Download: ${status.link}';
  }

  static String normalizeCode(String value) {
    final normalized = value.trim().toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );
    return normalized.length <= 24 ? normalized : normalized.substring(0, 24);
  }

  static String _extractReferralCode(String rawReferrer) {
    final candidates = <String>{rawReferrer};
    try {
      candidates.add(Uri.decodeFull(rawReferrer));
    } catch (_) {}
    for (final candidate in candidates) {
      final fromQuery = _readReferralCodeFromQuery(candidate);
      if (fromQuery.isNotEmpty) {
        return fromQuery;
      }
      final asUri = Uri.tryParse(candidate);
      if (asUri != null) {
        final fromUri = _readReferralCodeFromQuery(asUri.query);
        if (fromUri.isNotEmpty) {
          return fromUri;
        }
      }
    }
    return '';
  }

  static String _readReferralCodeFromQuery(String rawQuery) {
    try {
      final params = Uri.splitQueryString(rawQuery);
      return normalizeCode(
        params['mp_ref'] ??
            params['referralCode'] ??
            params['referral_code'] ??
            params['code'] ??
            '',
      );
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Login required');
    }
    final idToken = await user.getIdToken(true);
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(responseBody);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : const <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = (body['message'] ?? 'Referral request failed')
            .toString();
        throw StateError(message);
      }
      return body;
    } finally {
      client?.close(force: true);
    }
  }
}
