import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/services/install_source_service.dart';

class PlayEngagementService {
  PlayEngagementService._();

  static final PlayEngagementService instance = PlayEngagementService._();

  static const MethodChannel _channel = MethodChannel(
    'mana_poster/play_engagement',
  );

  static const String _reviewPromptCompletedKey =
      'play_review_prompt_completed_v1';
  static const String _reviewFirstSeenAtKey = 'play_review_first_seen_at_v1';
  static const String _reviewOpenCountKey = 'play_review_open_count_v1';
  static const String _reviewLastRequestedAtKey =
      'play_review_last_requested_at_v1';
  static const int _minimumReviewOpenCount = 5;
  static const Duration _minimumReviewAppAge = Duration(days: 7);
  static const Duration _minimumReviewRetryGap = Duration(days: 120);

  bool _startupHandledThisProcess = false;

  Future<void> handleHomeOpen({
    required bool hasRatedApp,
    required Future<void> Function() onReviewRecorded,
  }) async {
    if (!await _canUsePlayCore()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await _recordReviewEligibilityOpen(prefs);

    final updateAction = await _handleUpdateOnAppOpen();
    if (_startupHandledThisProcess) {
      return;
    }
    _startupHandledThisProcess = true;

    if (updateAction != _PlayUpdateAction.none) {
      return;
    }

    if (!await _shouldRequestInAppReview(prefs, hasRatedApp: hasRatedApp)) {
      return;
    }

    final launched = await _requestInAppReview();
    if (!launched) {
      return;
    }

    await prefs.setBool(_reviewPromptCompletedKey, true);
    await prefs.setInt(
      _reviewLastRequestedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await onReviewRecorded();
  }

  Future<void> handleAppResume() async {
    if (!await _canUsePlayCore()) {
      return;
    }
    final info = await _fetchUpdateInfo();
    if (info == null || info.installStatus != _androidInstallStatusDownloaded) {
      return;
    }
    await _completeFlexibleUpdate();
  }

  Future<bool> _canUsePlayCore() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return InstallSourceService.isTrustedPlayInstall();
  }

  Future<void> _recordReviewEligibilityOpen(SharedPreferences prefs) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!prefs.containsKey(_reviewFirstSeenAtKey)) {
      await prefs.setInt(_reviewFirstSeenAtKey, nowMs);
    }
    final currentCount = prefs.getInt(_reviewOpenCountKey) ?? 0;
    await prefs.setInt(_reviewOpenCountKey, currentCount + 1);
  }

  Future<bool> _shouldRequestInAppReview(
    SharedPreferences prefs, {
    required bool hasRatedApp,
  }) async {
    if (hasRatedApp || (prefs.getBool(_reviewPromptCompletedKey) ?? false)) {
      return false;
    }

    final openCount = prefs.getInt(_reviewOpenCountKey) ?? 0;
    if (openCount < _minimumReviewOpenCount) {
      return false;
    }

    final firstSeenAtMs = prefs.getInt(_reviewFirstSeenAtKey);
    if (firstSeenAtMs == null) {
      return false;
    }
    final appAge = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(firstSeenAtMs),
    );
    if (appAge < _minimumReviewAppAge) {
      return false;
    }

    final lastRequestedAtMs = prefs.getInt(_reviewLastRequestedAtKey);
    if (lastRequestedAtMs != null) {
      final sinceLastRequest = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastRequestedAtMs),
      );
      if (sinceLastRequest < _minimumReviewRetryGap) {
        return false;
      }
    }

    return true;
  }

  Future<_PlayUpdateAction> _handleUpdateOnAppOpen() async {
    final info = await _fetchUpdateInfo();
    if (info == null || !info.updateAvailable) {
      return _PlayUpdateAction.none;
    }

    if (info.installStatus == _androidInstallStatusDownloaded) {
      final completed = await _completeFlexibleUpdate();
      return completed
          ? _PlayUpdateAction.completeFlexible
          : _PlayUpdateAction.none;
    }

    final shouldUseImmediate =
        info.immediateAllowed &&
        (info.updateInProgress ||
            info.priority >= 4 ||
            (info.stalenessDays ?? 0) >= 7);
    if (shouldUseImmediate) {
      final started = await _startImmediateUpdate();
      return started
          ? _PlayUpdateAction.startImmediate
          : _PlayUpdateAction.none;
    }

    if (info.flexibleAllowed) {
      final started = await _startFlexibleUpdate();
      return started
          ? _PlayUpdateAction.startFlexible
          : _PlayUpdateAction.none;
    }

    return _PlayUpdateAction.none;
  }

  Future<_PlayUpdateInfo?> _fetchUpdateInfo() async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'checkForAppUpdate',
      );
      if (raw == null) {
        return null;
      }
      return _PlayUpdateInfo.fromChannelMap(raw);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> _startImmediateUpdate() async {
    try {
      return await _channel.invokeMethod<bool>('startImmediateUpdate') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> _startFlexibleUpdate() async {
    try {
      return await _channel.invokeMethod<bool>('startFlexibleUpdate') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> _completeFlexibleUpdate() async {
    try {
      return await _channel.invokeMethod<bool>('completeFlexibleUpdate') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> _requestInAppReview() async {
    try {
      return await _channel.invokeMethod<bool>('requestInAppReview') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

enum _PlayUpdateAction { none, startImmediate, startFlexible, completeFlexible }

const int _androidInstallStatusDownloaded = 11;

class _PlayUpdateInfo {
  const _PlayUpdateInfo({
    required this.updateAvailable,
    required this.updateInProgress,
    required this.immediateAllowed,
    required this.flexibleAllowed,
    required this.priority,
    required this.installStatus,
    this.stalenessDays,
  });

  final bool updateAvailable;
  final bool updateInProgress;
  final bool immediateAllowed;
  final bool flexibleAllowed;
  final int priority;
  final int installStatus;
  final int? stalenessDays;

  factory _PlayUpdateInfo.fromChannelMap(Map<Object?, Object?> raw) {
    int readInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

    return _PlayUpdateInfo(
      updateAvailable: raw['updateAvailable'] == true,
      updateInProgress: raw['updateInProgress'] == true,
      immediateAllowed: raw['immediateAllowed'] == true,
      flexibleAllowed: raw['flexibleAllowed'] == true,
      priority: readInt(raw['priority']),
      installStatus: readInt(raw['installStatus']),
      stalenessDays: raw['stalenessDays'] == null
          ? null
          : readInt(raw['stalenessDays']),
    );
  }
}
