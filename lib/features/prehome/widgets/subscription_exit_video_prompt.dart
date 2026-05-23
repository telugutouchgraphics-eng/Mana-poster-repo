import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/subscription_exit_video_service.dart';

Future<void> prewarmSubscriptionVideoPrompts({
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
}) {
  return Future.wait<void>(<Future<void>>[
    _SubscriptionVideoPromptPreloadCache.prepare(
      fieldName: _SubscriptionVideoPromptPreloadCache.exitFieldName,
      service: service,
    ).then((_) {}),
    _SubscriptionVideoPromptPreloadCache.prepare(
      fieldName: _SubscriptionVideoPromptPreloadCache.thanksFieldName,
      service: service,
    ).then((_) {}),
  ]);
}

Future<void> showSubscriptionExitVideoPromptIfAvailable(
  BuildContext context, {
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
  required Future<void> Function(BuildContext context) onSubscribe,
}) async {
  final prepared = await _SubscriptionVideoPromptPreloadCache.take(
    fieldName: _SubscriptionVideoPromptPreloadCache.exitFieldName,
    service: service,
  );
  if (!context.mounted) {
    await prepared?.controller?.dispose();
    return;
  }
  final config = prepared?.config;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SubscriptionExitVideoDialog(
      parentContext: context,
      videoUrl: config?.canPlay == true ? config!.url : null,
      preloadedController: prepared?.controller,
      primaryLabel: context.strings.localized(
        telugu: 'ఇప్పుడే సబ్‌స్క్రైబ్ చేయండి',
        english: 'Subscribe Now',
      ),
      secondaryLabel: context.strings.localized(
        telugu: 'స్కిప్',
        english: 'Skip',
      ),
      fallbackTitle: context.strings.localized(
        telugu: 'ఇప్పుడే సబ్‌స్క్రైబ్ చేయండి',
        english: 'Subscribe Now',
      ),
      fallbackMessage: context.strings.localized(
        telugu:
            'అన్‌లిమిటెడ్ పోస్టర్లు క్రియేట్ చేసి షేర్ చేయడానికి సబ్‌స్క్రిప్షన్ తీసుకోండి.',
        english:
            'Subscribe now to create and share unlimited posters in the app.',
      ),
      onPrimaryTap: onSubscribe,
    ),
  );
}

Future<void> showSubscriptionThanksVideoPromptIfAvailable(
  BuildContext context, {
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
}) async {
  final prepared = await _SubscriptionVideoPromptPreloadCache.take(
    fieldName: _SubscriptionVideoPromptPreloadCache.thanksFieldName,
    service: service,
  );
  if (!context.mounted) {
    await prepared?.controller?.dispose();
    return;
  }
  final config = prepared?.config;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SubscriptionExitVideoDialog(
      parentContext: context,
      videoUrl: config?.canPlay == true ? config!.url : null,
      preloadedController: prepared?.controller,
      primaryLabel: context.strings.localized(
        telugu: 'ధన్యవాదాలు',
        english: 'Thanks',
      ),
      secondaryLabel: context.strings.localized(
        telugu: 'మూసివేయి',
        english: 'Close',
      ),
      fallbackTitle: context.strings.localized(
        telugu: 'ధన్యవాదాలు',
        english: 'Thank You',
      ),
      fallbackMessage: context.strings.localized(
        telugu:
            'మీ సబ్‌స్క్రిప్షన్ కన్ఫర్మ్ అయింది. ఇప్పుడు మీ పోస్టర్లను నమ్మకంగా క్రియేట్ చేయండి.',
        english:
            'Your subscription is confirmed. You can now create your posters with confidence.',
      ),
    ),
  );
}

class _SubscriptionExitVideoDialog extends StatefulWidget {
  const _SubscriptionExitVideoDialog({
    required this.parentContext,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.fallbackTitle,
    required this.fallbackMessage,
    this.videoUrl,
    this.onPrimaryTap,
    this.preloadedController,
  });

  final BuildContext parentContext;
  final String? videoUrl;
  final String primaryLabel;
  final String secondaryLabel;
  final String fallbackTitle;
  final String fallbackMessage;
  final Future<void> Function(BuildContext context)? onPrimaryTap;
  final VideoPlayerController? preloadedController;

  @override
  State<_SubscriptionExitVideoDialog> createState() =>
      _SubscriptionExitVideoDialogState();
}

class _SubscriptionExitVideoDialogState
    extends State<_SubscriptionExitVideoDialog> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final preloadedController = widget.preloadedController;
    if (preloadedController != null) {
      _controller = preloadedController;
      unawaited(_playPreloadedController(preloadedController));
    } else {
      unawaited(_initialize());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final rawUrl = widget.videoUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _playPreloadedController(
    VideoPlayerController controller,
  ) async {
    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      await controller.seekTo(Duration.zero);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _handlePrimaryTap() async {
    if (widget.onPrimaryTap == null) {
      Navigator.of(context).pop();
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!widget.parentContext.mounted) {
      return;
    }
    await widget.onPrimaryTap!(widget.parentContext);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final hasVideo = (widget.videoUrl?.trim().isNotEmpty ?? false);
    final ready = controller != null && controller.value.isInitialized;
    final showFallbackNote = !hasVideo || _hasError;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: showFallbackNote
                      ? 9 / 12
                      : (ready ? controller.value.aspectRatio : 9 / 16),
                  child: ColoredBox(
                    color: const Color(0xFF0F172A),
                    child: showFallbackNote
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 26,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  widget.fallbackTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  widget.fallbackMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ready
                        ? VideoPlayer(controller)
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _handlePrimaryTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(widget.primaryLabel),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedSubscriptionVideo {
  const _PreparedSubscriptionVideo({required this.config, this.controller});

  final SubscriptionExitVideoConfig? config;
  final VideoPlayerController? controller;
}

class _SubscriptionVideoPromptPreloadCache {
  static const String exitFieldName = 'subscriptionExitVideo';
  static const String thanksFieldName = 'subscriptionThanksVideo';
  static final Map<String, Future<_PreparedSubscriptionVideo?>> _pending =
      <String, Future<_PreparedSubscriptionVideo?>>{};

  static Future<_PreparedSubscriptionVideo?> prepare({
    required String fieldName,
    required SubscriptionExitVideoService service,
  }) {
    return _pending[fieldName] ??= _load(
      fieldName: fieldName,
      service: service,
    );
  }

  static Future<_PreparedSubscriptionVideo?> take({
    required String fieldName,
    required SubscriptionExitVideoService service,
  }) async {
    final prepared = await prepare(fieldName: fieldName, service: service);
    _pending.remove(fieldName);
    return prepared;
  }

  static Future<_PreparedSubscriptionVideo?> _load({
    required String fieldName,
    required SubscriptionExitVideoService service,
  }) async {
    final config = await service.fetchConfig(fieldName: fieldName);
    if (config?.canPlay != true) {
      return _PreparedSubscriptionVideo(config: config);
    }

    final uri = Uri.tryParse(config!.url.trim());
    if (uri == null || !uri.hasScheme) {
      return _PreparedSubscriptionVideo(config: config);
    }
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      return _PreparedSubscriptionVideo(config: config, controller: controller);
    } catch (_) {
      await controller.dispose();
      return _PreparedSubscriptionVideo(config: config);
    }
  }
}
