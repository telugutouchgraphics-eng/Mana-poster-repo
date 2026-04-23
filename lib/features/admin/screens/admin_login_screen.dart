import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/data/services/firebase_admin_auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

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
      await FirebaseAdminAuthService.instance.signInWithEmailAndPassword(
        email: _emailController.text,
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
                  ? _MobileLayout(form: _buildFormCard())
                  : _DesktopLayout(form: _buildFormCard()),
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
            const Text(
              'Admin Login',
              style: TextStyle(
                fontFamily: 'League Spartan',
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16203B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to access the Mana Poster admin dashboard, preview workflow, and future backend publishing tools.',
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF61708F),
              ),
            ),
            const SizedBox(height: 20),
            const _FormLabel(label: 'Admin Email'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.username],
              decoration: _inputDecoration(
                hintText: 'admin@manaposter.in',
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
                label: Text(_submitting ? 'Signing In...' : 'Login to Admin'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use a Firebase Authentication email/password admin account. Draft editing remains local until content save integration is added.',
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
  const _DesktopLayout({required this.form});

  final Widget form;

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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _BrandBadge(),
                SizedBox(height: 22),
                Text(
                  'Mana Poster\nAdmin Console',
                  style: TextStyle(
                    fontFamily: 'League Spartan',
                    fontSize: 54,
                    height: 0.95,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15203B),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Access the landing page editor, live preview, media references, app links, and future publish workflow from one controlled admin entry point.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF556481),
                  ),
                ),
                SizedBox(height: 20),
                _InfoBullet(text: 'Email/password login through Firebase Auth'),
                _InfoBullet(
                  text:
                      'Admin route protection for dashboard and preview access',
                ),
                _InfoBullet(
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
  const _MobileLayout({required this.form});

  final Widget form;

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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _BrandBadge(),
              SizedBox(height: 14),
              Text(
                'Mana Poster Admin Console',
                style: TextStyle(
                  fontFamily: 'League Spartan',
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15203B),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Secure admin access for dashboard editing and live preview.',
                style: TextStyle(
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
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E6F5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.admin_panel_settings_rounded,
            size: 18,
            color: Color(0xFF5A31E1),
          ),
          SizedBox(width: 8),
          Text(
            'Admin Access',
            style: TextStyle(
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
