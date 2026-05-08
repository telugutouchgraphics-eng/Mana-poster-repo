import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class NetworkImageWebFrame extends StatefulWidget {
  const NetworkImageWebFrame({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  final String url;
  final BoxFit fit;

  @override
  State<NetworkImageWebFrame> createState() => _NetworkImageWebFrameState();
}

class _NetworkImageWebFrameState extends State<NetworkImageWebFrame> {
  late final String _viewType =
      'network-image-web-frame-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final element = web.HTMLImageElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.border = '0'
        ..style.objectFit = _cssObjectFit(widget.fit)
        ..style.backgroundColor = 'transparent';
      return element;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }

  String _cssObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitHeight:
        return 'contain';
      case BoxFit.fitWidth:
        return 'contain';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }
}
