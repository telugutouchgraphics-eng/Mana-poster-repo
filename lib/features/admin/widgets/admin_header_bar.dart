import 'package:flutter/material.dart';

class AdminHeaderBar extends StatelessWidget {
  const AdminHeaderBar({
    super.key,
    required this.title,
    this.onMenuTap,
    this.onLogout,
  });

  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool compact = width < 760;
    final String subtitle =
        'Manage landing content, preview state, and launch-ready app messaging.';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        16,
        compact ? 16 : 24,
        16,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFDFEFFFE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAF8)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1421418E),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (onMenuTap != null)
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF2E375A)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F4FD),
                ),
              ),
            if (onMenuTap != null) const SizedBox(width: 10),
            SizedBox(
              width: compact
                  ? width - 150
                  : width >= 1180
                  ? 520
                  : 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF67728E),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F2FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFEBE2FF)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: Color(0xFF6B46F8),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Local Draft Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4520B4),
                    ),
                  ),
                ],
              ),
            ),
            if (onLogout != null)
              OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
              ),
          ],
        ),
      ),
    );
  }
}
