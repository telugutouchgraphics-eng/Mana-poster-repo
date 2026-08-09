import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mana_poster/app/services/admob_consent_service.dart';

class RewardedAccessService {
  RewardedAccessService();

  static const Duration _loadTimeout = Duration(seconds: 12);
  static const Duration _showTimeout = Duration(seconds: 75);

  RewardedAd? _preloadedAd;
  String? _preloadedAdUnitId;
  bool _isPreloading = false;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _debugLogStack(String message, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<void> preloadRewardedAd({required String adUnitId}) async {
    if (kIsWeb ||
        adUnitId.trim().isEmpty ||
        _isPreloading ||
        (_preloadedAd != null && _preloadedAdUnitId == adUnitId)) {
      return;
    }
    _isPreloading = true;
    try {
      if (!await AdMobConsentService.instance.canRequestAds()) {
        await AdMobConsentService.instance.prepareForAds();
      }
      if (!await AdMobConsentService.instance.canRequestAds()) {
        return;
      }
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _preloadedAd?.dispose();
            _preloadedAd = ad;
            _preloadedAdUnitId = adUnitId;
            _debugLog('RewardedAccessService preloaded rewarded ad');
          },
          onAdFailedToLoad: (LoadAdError error) {
            _debugLog('RewardedAccessService preload failed: $error');
          },
        ),
      );
    } catch (error, stackTrace) {
      _debugLogStack(
        'RewardedAccessService preload exception: $error',
        stackTrace,
      );
    } finally {
      _isPreloading = false;
    }
  }

  Future<bool> showRewardedAccessAd({
    required String adUnitId,
    required String debugLabel,
  }) async {
    if (kIsWeb) {
      _debugLog(
        'RewardedAccessService: rewarded ads are not supported on web for $debugLabel',
      );
      return true;
    }
    if (adUnitId.trim().isEmpty) {
      _debugLog(
        'RewardedAccessService: no rewarded ad configured for $debugLabel, allowing access',
      );
      return true;
    }
    if (!await AdMobConsentService.instance.canRequestAds()) {
      await AdMobConsentService.instance.prepareForAds();
    }
    if (!await AdMobConsentService.instance.canRequestAds()) {
      _debugLog(
        'RewardedAccessService: ads unavailable for $debugLabel, allowing access',
      );
      return true;
    }

    final completer = Completer<bool>();
    RewardedAd? rewardedAd = _preloadedAdUnitId == adUnitId
        ? _preloadedAd
        : null;
    if (rewardedAd != null) {
      _preloadedAd = null;
      _preloadedAdUnitId = null;
    }
    var rewardEarned = false;
    var adShown = false;
    Timer? loadTimer;
    Timer? showTimer;

    void complete(bool value) {
      if (completer.isCompleted) {
        return;
      }
      loadTimer?.cancel();
      showTimer?.cancel();
      _debugLog(
        'RewardedAccessService complete for $debugLabel: value=$value rewardEarned=$rewardEarned adShown=$adShown',
      );
      completer.complete(value);
      rewardedAd?.dispose();
      rewardedAd = null;
    }

    void showAd(RewardedAd ad) {
      loadTimer?.cancel();
      _debugLog('RewardedAccessService ad ready for $debugLabel');
      rewardedAd = ad;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          adShown = true;
          showTimer?.cancel();
          showTimer = Timer(_showTimeout, () {
            _debugLog('RewardedAccessService show timeout for $debugLabel');
            complete(rewardEarned);
          });
          _debugLog('RewardedAccessService ad shown for $debugLabel');
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) async {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          complete(rewardEarned);
          unawaited(preloadRewardedAd(adUnitId: adUnitId));
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          _debugLog(
            'RewardedAccessService show failed for $debugLabel: $error',
          );
          complete(true);
          unawaited(preloadRewardedAd(adUnitId: adUnitId));
        },
      );
      unawaited(
        ad
            .show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                rewardEarned = true;
                _debugLog(
                  'RewardedAccessService reward earned for $debugLabel: amount=${reward.amount} type=${reward.type}',
                );
              },
            )
            .catchError((Object error, StackTrace stackTrace) {
              _debugLogStack(
                'RewardedAccessService show exception for $debugLabel: $error',
                stackTrace,
              );
              complete(true);
              unawaited(preloadRewardedAd(adUnitId: adUnitId));
            }),
      );
    }

    try {
      if (rewardedAd != null) {
        showAd(rewardedAd!);
      } else {
        loadTimer = Timer(_loadTimeout, () {
          _debugLog('RewardedAccessService load timeout for $debugLabel');
          complete(true);
        });
        await RewardedAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (RewardedAd ad) {
              _debugLog('RewardedAccessService ad loaded for $debugLabel');
              showAd(ad);
            },
            onAdFailedToLoad: (LoadAdError error) {
              _debugLog(
                'RewardedAccessService load failed for $debugLabel: $error',
              );
              complete(true);
            },
          ),
        );
      }
    } catch (error, stackTrace) {
      _debugLogStack(
        'RewardedAccessService exception for $debugLabel: $error',
        stackTrace,
      );
      complete(true);
    }

    return completer.future.timeout(
      _loadTimeout + _showTimeout + const Duration(seconds: 5),
      onTimeout: () {
        _debugLog('RewardedAccessService timeout for $debugLabel');
        final fallbackValue = rewardEarned || !adShown;
        complete(fallbackValue);
        return fallbackValue;
      },
    );
  }

  void dispose() {
    _preloadedAd?.dispose();
    _preloadedAd = null;
    _preloadedAdUnitId = null;
  }
}
