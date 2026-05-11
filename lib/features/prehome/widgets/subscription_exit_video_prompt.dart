import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/subscription_exit_video_service.dart';

Future<void> showSubscriptionExitVideoPromptIfAvailable(
  BuildContext context, {
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
  required Future<void> Function(BuildContext context) onSubscribe,
}) async {
  final config = await service.fetchConfig();
  if (!context.mounted || config?.canPlay != true) {
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SubscriptionExitVideoDialog(
      videoUrl: config!.url,
      primaryLabel: context.strings.localized(
        telugu: 'ఇప్పుడే సబ్‌స్క్రైబ్ చేయండి',
        english: 'Subscribe Now',
      ),
      secondaryLabel: context.strings.localized(telugu: 'స్కిప్', english: 'Skip'),
      onPrimaryTap: onSubscribe,
    ),
  );
}

Future<void> showSubscriptionThanksVideoPromptIfAvailable(
  BuildContext context, {
  SubscriptionExitVideoService service = const SubscriptionExitVideoService(),
}) async {
  final config = await service.fetchThanksConfig();
  if (!context.mounted || config?.canPlay != true) {
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SubscriptionExitVideoDialog(
      videoUrl: config!.url,
      primaryLabel: context.strings.localized(telugu: 'ధన్యవాదాలు', english: 'Thanks'),
      secondaryLabel: context.strings.localized(telugu: 'మూసివేయి', english: 'Close'),
    ),
  );
}

class _SubscriptionExitVideoDialog extends StatefulWidget {
  const _SubscriptionExitVideoDialog({
    required this.videoUrl,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.onPrimaryTap,
  });

  final String videoUrl;
  final String primaryLabel;
  final String secondaryLabel;
  final Future<void> Function(BuildContext context)? onPrimaryTap;

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
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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

  Future<void> _handlePrimaryTap() async {
    if (widget.onPrimaryTap == null) {
      Navigator.of(context).pop();
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    await widget.onPrimaryTap!(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
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
              child: AspectRatio(
                aspectRatio: ready ? controller.value.aspectRatio : 9 / 16,
                child: ColoredBox(
                  color: const Color(0xFF0F172A),
                  child: _hasError
                      ? Center(
                          child: Text(
                            strings.localized(
                              telugu: 'వీడియో లోడ్ కాలేదు',
                              english: 'Video could not load',
                            ),
                            style: const TextStyle(color: Colors.white),
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
                child: Text(
                  widget.primaryLabel,
                ),
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
