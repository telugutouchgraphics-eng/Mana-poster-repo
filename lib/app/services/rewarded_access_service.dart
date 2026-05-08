import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAccessService {
  const RewardedAccessService();

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

  Future<bool> showRewardedAccessAd({
    required String adUnitId,
    required String debugLabel,
  }) async {
    if (kIsWeb || adUnitId.trim().isEmpty) {
      _debugLog(
        'RewardedAccessService: no rewarded ad configured for $debugLabel, allowing access',
      );
      return true;
    }

    final completer = Completer<bool>();
    RewardedAd? rewardedAd;
    var rewardEarned = false;
    var adShown = false;

    void complete(bool value) {
      if (completer.isCompleted) {
        return;
      }
      _debugLog(
        'RewardedAccessService complete for $debugLabel: value=$value rewardEarned=$rewardEarned adShown=$adShown',
      );
      completer.complete(value);
      rewardedAd?.dispose();
      rewardedAd = null;
    }

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _debugLog('RewardedAccessService ad loaded for $debugLabel');
            rewardedAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) {
                adShown = true;
                _debugLog('RewardedAccessService ad shown for $debugLabel');
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) async {
                await Future<void>.delayed(const Duration(milliseconds: 350));
                complete(rewardEarned || adShown);
              },
              onAdFailedToShowFullScreenContent: (
                RewardedAd ad,
                AdError error,
              ) {
                _debugLog(
                  'RewardedAccessService show failed for $debugLabel: $error',
                );
                complete(false);
              },
            );
            ad.show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                rewardEarned = true;
                _debugLog(
                  'RewardedAccessService reward earned for $debugLabel: amount=${reward.amount} type=${reward.type}',
                );
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            _debugLog(
              'RewardedAccessService load failed for $debugLabel: $error',
            );
            complete(false);
          },
        ),
      );
    } catch (error, stackTrace) {
      _debugLogStack(
        'RewardedAccessService exception for $debugLabel: $error',
        stackTrace,
      );
      complete(false);
    }

    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _debugLog('RewardedAccessService timeout for $debugLabel');
        final fallbackValue = rewardEarned || adShown;
        complete(fallbackValue);
        return fallbackValue;
      },
    );
  }
}
