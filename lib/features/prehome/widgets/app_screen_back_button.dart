import 'package:flutter/material.dart';

class AppScreenBackButton extends StatelessWidget {
  const AppScreenBackButton({
    super.key,
    this.color = const Color(0xFF0F172A),
    this.fallbackRoute,
    this.fallbackRouteResolver,
  });

  final Color color;
  final String? fallbackRoute;
  final Future<String?> Function()? fallbackRouteResolver;

  Future<void> _handleBack(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final resolvedFallback =
        await fallbackRouteResolver?.call() ?? fallbackRoute;
    if (!context.mounted ||
        resolvedFallback == null ||
        resolvedFallback.isEmpty) {
      return;
    }
    navigator.pushNamedAndRemoveUntil(
      resolvedFallback,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: const Color(0x220F172A),
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: Icon(Icons.arrow_back_rounded, color: color),
        onPressed: () => _handleBack(context),
      ),
    );
  }
}
