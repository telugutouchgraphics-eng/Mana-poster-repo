import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) consent before AdMob ad requests.
class AdMobConsentService {
  AdMobConsentService._();

  static final AdMobConsentService instance = AdMobConsentService._();

  Future<void> prepareForAds() async {
    if (kIsWeb) {
      return;
    }

    final params = ConsentRequestParameters();
    await _requestConsentInfoUpdate(params);
    await _loadAndShowConsentFormIfRequired();
  }

  Future<bool> canRequestAds() async {
    if (kIsWeb) {
      return false;
    }
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPrivacyOptionsRequired() async {
    if (kIsWeb) {
      return false;
    }
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  Future<void> showPrivacyOptionsForm() async {
    if (kIsWeb) {
      return;
    }
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {},
    );
  }

  Future<void> _requestConsentInfoUpdate(ConsentRequestParameters params) async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (FormError error) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
  }

  Future<void> _loadAndShowConsentFormIfRequired() async {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {},
    );
  }
}
