import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class LandingPagePublicFrame extends StatefulWidget {
  const LandingPagePublicFrame({super.key, required this.url});

  final String url;

  @override
  State<LandingPagePublicFrame> createState() => _LandingPagePublicFrameState();
}

class _LandingPagePublicFrameState extends State<LandingPagePublicFrame> {
  late final String _viewType =
      'landing-page-public-frame-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return web.HTMLIFrameElement()
        ..src = widget.url
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#fbf7ff'
        ..allow = 'clipboard-write; fullscreen';
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
