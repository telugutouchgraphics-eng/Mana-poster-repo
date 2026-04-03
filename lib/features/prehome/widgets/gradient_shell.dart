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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFEAF2FF), Color(0xFFF4F7FC)],
        ),
      ),
      child: SafeArea(
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
