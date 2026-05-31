import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';

class First150TrialClaimResult {
  const First150TrialClaimResult({
    required this.claimed,
    this.alreadyClaimed = false,
    this.expiryTime,
    this.message,
  });

  final bool claimed;
  final bool alreadyClaimed;
  final DateTime? expiryTime;
  final String? message;
}

class First150TrialService {
  First150TrialService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const String _claimUrl = String.fromEnvironment(
    'MANA_POSTER_FIRST150_TRIAL_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/claimFirst150Trial',
  );

  final FirebaseAuth _firebaseAuth;

  Future<First150TrialClaimResult> claimIfEligible() async {
    if (_claimUrl.isEmpty) {
      return const First150TrialClaimResult(claimed: false);
    }

    HttpClient? client;
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const First150TrialClaimResult(claimed: false);
      }

      client = HttpClient();
      final request = await client.postUrl(Uri.parse(_claimUrl));
      request.headers.contentType = ContentType.json;
      final idToken = await user.getIdToken(true);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.add(utf8.encode(jsonEncode(<String, dynamic>{'uid': user.uid})));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return First150TrialClaimResult(
          claimed: false,
          message: _extractMessage(responseBody),
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return const First150TrialClaimResult(claimed: false);
      }

      final result = First150TrialClaimResult(
        claimed: decoded['claimed'] == true,
        alreadyClaimed: decoded['alreadyClaimed'] == true,
        expiryTime: _parseDateTime(decoded['expiryTime']),
        message: decoded['message']?.toString(),
      );

      if (result.claimed) {
        await SubscriptionBackendService(
          firebaseAuth: _firebaseAuth,
        ).fetchFreshEntitlementWithRetry(retryDelay: Duration.zero);
      }
      return result;
    } catch (_) {
      return const First150TrialClaimResult(claimed: false);
    } finally {
      client?.close(force: true);
    }
  }

  String? _extractMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString();
      }
    } catch (_) {
      return responseBody.trim();
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }
}
