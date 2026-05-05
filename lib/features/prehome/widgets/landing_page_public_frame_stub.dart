import 'package:flutter/material.dart';

class LandingPagePublicFrame extends StatelessWidget {
  const LandingPagePublicFrame({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Text(
          url,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
