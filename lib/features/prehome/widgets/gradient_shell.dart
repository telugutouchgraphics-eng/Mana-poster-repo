import 'package:flutter/material.dart';

class GradientShell extends StatelessWidget {
  const GradientShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Color bg = Theme.of(context).colorScheme.surface;
    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
