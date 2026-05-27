import 'dart:async';

import 'package:flutter/widgets.dart';

class PostSplashStartupGate {
  PostSplashStartupGate._();

  static final Completer<void> _readyCompleter = Completer<void>();

  static Future<void> get whenReady => _readyCompleter.future;

  static bool get isReady => _readyCompleter.isCompleted;

  static void markReady() {
    if (_readyCompleter.isCompleted) {
      return;
    }
    _readyCompleter.complete();
  }
}

class PostSplashStartupReadyMarker extends StatefulWidget {
  const PostSplashStartupReadyMarker({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<PostSplashStartupReadyMarker> createState() =>
      _PostSplashStartupReadyMarkerState();
}

class _PostSplashStartupReadyMarkerState
    extends State<PostSplashStartupReadyMarker> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled || PostSplashStartupGate.isReady) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        if (!mounted) {
          return;
        }
        PostSplashStartupGate.markReady();
      }());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
