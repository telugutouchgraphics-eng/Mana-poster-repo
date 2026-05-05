import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/data/services/firebase_admin_auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
    this.title = 'Admin Login',
    this.subtitle =
        'Sign in to access the Mana Poster admin dashboard, preview workflow, and future backend publishing tools.',
    this.emailLabel = 'Admin Email',
    this.emailHint = 'admin@manaposter.in',
    this.buttonLabel = 'Login to Admin',
    this.footerText =
        'Use a Firebase Authentication email/password admin account. Draft editing remains local until content save integration is added.',
    this.brandTitle = 'Mana Poster\nAdmin Console',
    this.brandSubtitle =
        'Access the landing page editor, live preview, media references, app links, and future publish workflow from one controlled admin entry point.',
    this.badgeText = 'Admin Access',
    this.authEmailResolver,
  });

  final String title;
  final String subtitle;
  final String emailLabel;
  final String emailHint;
  final String buttonLabel;
  final String footerText;
  final String brandTitle;
  final String brandSubtitle;
  final String badgeText;
  final String Function(String email)? authEmailResolver;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final String email = _emailController.text.trim();
      await FirebaseAdminAuthService.instance.signInWithEmailAndPassword(
        email: widget.authEmailResolver?.call(email) ?? email,
        password: _passwordController.text,
      );
    } on AdminAuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool compact = width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: compact
                  ? _MobileLayout(
                      form: _buildFormCard(),
                      badgeText: widget.badgeText,
                      brandTitle: widget.brandTitle,
                      brandSubtitle: widget.brandSubtitle,
                    )
                  : _DesktopLayout(
                      form: _buildFormCard(),
                      badgeText: widget.badgeText,
                      brandTitle: widget.brandTitle,
                      brandSubtitle: widget.brandSubtitle,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4E8F5)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14213A80),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'League Spartan',
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16203B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF61708F),
              ),
            ),
            const SizedBox(height: 20),
            _FormLabel(label: widget.emailLabel),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.username],
              decoration: _inputDecoration(
                hintText: widget.emailHint,
                icon: Icons.alternate_email_rounded,
              ),
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Enter admin email.';
                }
                if (!text.contains('@') || !text.contains('.')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            const _FormLabel(label: 'Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              onFieldSubmitted: (_) => _submitting ? null : _submit(),
              decoration: _inputDecoration(
                hintText: 'Enter password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (String? value) {
                if ((value ?? '').isEmpty) {
                  return 'Enter password.';
                }
                if ((value ?? '').length < 6) {
                  return 'Password should be at least 6 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (_errorText != null) ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF2C4C0)),
                ),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9C2F2B),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5A31E1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(_submitting ? 'Signing In...' : widget.buttonLabel),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.footerText,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF68758F),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.form,
    required this.badgeText,
    required this.brandTitle,
    required this.brandSubtitle,
  });

  final Widget form;
  final String badgeText;
  final String brandTitle;
  final String brandSubtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 11,
          child: Container(
            padding: const EdgeInsets.all(34),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFFFF1E6),
                  Color(0xFFFFEEF7),
                  Color(0xFFEDEBFF),
                  Color(0xFFEAF4FF),
                ],
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x12213A80),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _BrandBadge(text: badgeText),
                const SizedBox(height: 22),
                Text(
                  brandTitle,
                  style: const TextStyle(
                    fontFamily: 'League Spartan',
                    fontSize: 54,
                    height: 0.95,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15203B),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  brandSubtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF556481),
                  ),
                ),
                const SizedBox(height: 20),
                const _InfoBullet(
                  text: 'Email/password login through Firebase Auth',
                ),
                const _InfoBullet(
                  text:
                      'Admin route protection for dashboard and preview access',
                ),
                const _InfoBullet(
                  text:
                      'Current draft editor remains local until Firestore save is added',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(flex: 9, child: form),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.form,
    required this.badgeText,
    required this.brandTitle,
    required this.brandSubtitle,
  });

  final Widget form;
  final String badgeText;
  final String brandTitle;
  final String brandSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFFFFF1E6),
                Color(0xFFFFEEF7),
                Color(0xFFEDEBFF),
                Color(0xFFEAF4FF),
              ],
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x12213A80),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _BrandBadge(text: badgeText),
              const SizedBox(height: 14),
              Text(
                brandTitle.replaceAll('\n', ' '),
                style: const TextStyle(
                  fontFamily: 'League Spartan',
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15203B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                brandSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: Color(0xFF5A6885),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        form,
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E6F5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.admin_panel_settings_rounded,
            size: 18,
            color: Color(0xFF5A31E1),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF372E68),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF51607E),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4E5B77),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    filled: true,
    fillColor: const Color(0xFFF9FBFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDDE4F2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDDE4F2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6A46F5), width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD65A52)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD65A52), width: 1.2),
    ),
  );
}
