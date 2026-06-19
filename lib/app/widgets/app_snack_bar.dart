import 'dart:async';

import 'package:flutter/material.dart';

enum AppSnackBarTone { success, error, warning, info }

OverlayEntry? _activeTopSnackBar;
Timer? _activeTopSnackBarTimer;

extension AppSnackBarMessenger on ScaffoldMessengerState {
  void showTopSnackBar(SnackBar snackBar) {
    hideCurrentTopSnackBar();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      showSnackBar(snackBar);
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopSnackOverlay(
        snackBar: snackBar,
        onDismiss: () {
          if (_activeTopSnackBar == entry) {
            hideCurrentTopSnackBar();
          }
        },
      ),
    );

    _activeTopSnackBar = entry;
    overlay.insert(entry);
    _activeTopSnackBarTimer = Timer(snackBar.duration, hideCurrentTopSnackBar);
  }

  void hideCurrentTopSnackBar() {
    _activeTopSnackBarTimer?.cancel();
    _activeTopSnackBarTimer = null;
    _activeTopSnackBar?.remove();
    _activeTopSnackBar = null;
  }
}

class AppSnackBar {
  const AppSnackBar._();

  static SnackBar build({
    required Widget content,
    Color? backgroundColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? width,
    ShapeBorder? shape,
    HitTestBehavior? hitTestBehavior,
    SnackBarBehavior? behavior,
    SnackBarAction? action,
    double? actionOverflowThreshold,
    bool? showCloseIcon,
    Color? closeIconColor,
    Duration duration = const Duration(seconds: 3),
    Animation<double>? animation,
    VoidCallback? onVisible,
    DismissDirection dismissDirection = DismissDirection.down,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    final text = _extractText(content);
    final tone = _toneFor(text);
    final palette = _paletteFor(tone);

    return SnackBar(
      content: _TopSnackContent(
        icon: palette.icon,
        iconBackground: palette.iconBackground,
        content: content,
      ),
      backgroundColor: backgroundColor ?? palette.background,
      elevation: elevation ?? 10,
      margin: margin ?? const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: padding ?? const EdgeInsets.fromLTRB(12, 10, 12, 10),
      width: width,
      shape:
          shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      hitTestBehavior: hitTestBehavior,
      behavior: SnackBarBehavior.floating,
      action: action,
      actionOverflowThreshold: actionOverflowThreshold,
      showCloseIcon: showCloseIcon,
      closeIconColor: closeIconColor ?? Colors.white,
      duration: duration,
      animation: animation,
      onVisible: onVisible,
      dismissDirection: dismissDirection,
      clipBehavior: clipBehavior,
    );
  }

  static String _extractText(Widget content) {
    if (content is Text) {
      final data = content.data;
      if (data != null) return data;
      final span = content.textSpan;
      if (span != null) return span.toPlainText();
    }
    return '';
  }

  static AppSnackBarTone _toneFor(String message) {
    final value = message.toLowerCase();
    if (value.contains('success') ||
        value.contains('saved') ||
        value.contains('copied') ||
        value.contains('complete') ||
        value.contains('uploaded') ||
        value.contains('applied') ||
        value.contains('done') ||
        value.contains('sent') ||
        value.contains('సేవ్') ||
        value.contains('కాపీ') ||
        value.contains('పూర్త') ||
        value.contains('అప్‌లోడ్') ||
        value.contains('పంప')) {
      return AppSnackBarTone.success;
    }
    if (value.contains('warning') ||
        value.contains('limit') ||
        value.contains('busy') ||
        value.contains('wait') ||
        value.contains('permission') ||
        value.contains('required') ||
        value.contains('లిమిట్') ||
        value.contains('వేచి') ||
        value.contains('అనుమతి') ||
        value.contains('అవసరం')) {
      return AppSnackBarTone.warning;
    }
    if (value.contains('fail') ||
        value.contains('error') ||
        value.contains('denied') ||
        value.contains('invalid') ||
        value.contains('not ') ||
        value.contains('could not') ||
        value.contains('unable') ||
        value.contains('missing') ||
        value.contains('విఫల') ||
        value.contains('లోపం') ||
        value.contains('లేదు') ||
        value.contains('కుదర') ||
        value.contains('దొరకలేదు')) {
      return AppSnackBarTone.error;
    }
    return AppSnackBarTone.info;
  }

  static _SnackPalette _paletteFor(AppSnackBarTone tone) {
    return switch (tone) {
      AppSnackBarTone.success => const _SnackPalette(
        icon: '✅',
        background: Color(0xFF0F9F6E),
        iconBackground: Color(0xFF057A55),
      ),
      AppSnackBarTone.error => const _SnackPalette(
        icon: '❌',
        background: Color(0xFFE11D48),
        iconBackground: Color(0xFFBE123C),
      ),
      AppSnackBarTone.warning => const _SnackPalette(
        icon: '⚠️',
        background: Color(0xFFF59E0B),
        iconBackground: Color(0xFFD97706),
      ),
      AppSnackBarTone.info => const _SnackPalette(
        icon: 'ℹ️',
        background: Color(0xFF2563EB),
        iconBackground: Color(0xFF1D4ED8),
      ),
    };
  }
}

class _TopSnackOverlay extends StatefulWidget {
  const _TopSnackOverlay({required this.snackBar, required this.onDismiss});

  final SnackBar snackBar;
  final VoidCallback onDismiss;

  @override
  State<_TopSnackOverlay> createState() => _TopSnackOverlayState();
}

class _TopSnackOverlayState extends State<_TopSnackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final snackBar = widget.snackBar;
    final action = snackBar.action;
    final horizontalMargin = _horizontalMargin(snackBar.margin);
    final topMargin = _topMargin(snackBar.margin);

    return Positioned(
      top: MediaQuery.paddingOf(context).top + topMargin,
      left: horizontalMargin,
      right: horizontalMargin,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const ValueKey<String>('app-top-snack-bar'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: snackBar.backgroundColor ?? const Color(0xFF2563EB),
                  shape:
                      snackBar.shape ??
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                  shadows: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: snackBar.elevation ?? 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      snackBar.padding ??
                      const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(child: snackBar.content),
                      if (action != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            action.onPressed();
                            _dismiss();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                action.textColor ?? const Color(0xFFFFF7AD),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(action.label),
                        ),
                      ],
                      if (snackBar.showCloseIcon == true) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _dismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            color: snackBar.closeIconColor ?? Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _horizontalMargin(EdgeInsetsGeometry? margin) {
    final resolved = margin?.resolve(TextDirection.ltr);
    return resolved?.left ?? 14;
  }

  double _topMargin(EdgeInsetsGeometry? margin) {
    final resolved = margin?.resolve(TextDirection.ltr);
    return resolved?.top ?? 14;
  }
}

class _TopSnackContent extends StatelessWidget {
  const _TopSnackContent({
    required this.icon,
    required this.iconBackground,
    required this.content,
  });

  final String icon;
  final Color iconBackground;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Text(icon, style: const TextStyle(fontSize: 17)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            child: content,
          ),
        ),
      ],
    );
  }
}

class _SnackPalette {
  const _SnackPalette({
    required this.icon,
    required this.background,
    required this.iconBackground,
  });

  final String icon;
  final Color background;
  final Color iconBackground;
}
