import 'package:flutter/material.dart';

class AdminAccessDeniedScreen extends StatelessWidget {
  const AdminAccessDeniedScreen({
    super.key,
    required this.email,
    required this.onRetry,
    required this.onLogout,
    this.message,
  });

  final String? email;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5EAF8)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x1621418E),
                      blurRadius: 30,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[
                            Color(0xFFFF8A3D),
                            Color(0xFFFF3D8D),
                            Color(0xFF6B46F8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Admin Access Required',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17203D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message ??
                          'Your account is signed in but is not authorized to manage Mana Poster content.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF66708C),
                      ),
                    ),
                    if (email != null && email!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7EAF6)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 18,
                              color: Color(0xFF6B46F8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                email!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF293355),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Check Again'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(150, 46),
                            backgroundColor: const Color(0xFF6B46F8),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(130, 46),
                            foregroundColor: const Color(0xFF293355),
                            side: const BorderSide(color: Color(0xFFDDE3F2)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'If access was just granted, use Check Again after refreshing your Firebase ID token.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Color(0xFF7A849E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
