import 'package:flutter/material.dart';

class OnboardingSurfaceCard extends StatelessWidget {
  const OnboardingSurfaceCard({
    super.key,
    required this.child,
    this.maxWidth = 420,
    this.padding = const EdgeInsets.all(20),
    this.headerGradient,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final Gradient? headerGradient;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient:
                      headerGradient ??
                      const LinearGradient(
                        colors: <Color>[
                          Color(0xFF14B8A6),
                          Color(0xFF38BDF8),
                          Color(0xFFA78BFA),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
