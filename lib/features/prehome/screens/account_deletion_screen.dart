import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/account_deletion_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen>
    with AppLanguageStateMixin {
  final AccountDeletionService _accountDeletionService = AccountDeletionService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _busy = false;

  Future<void> _openDeletionPolicy() async {
    final uri = Uri.parse(AppPublicInfo.accountDeletionUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppPublicInfo.supportEmail,
      queryParameters: <String, String>{
        'subject': 'Mana Poster account deletion help',
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _localizedResultMessage(AccountDeletionResult result) {
    switch (result.message) {
      case 'No logged-in user found.':
        return context.strings.localized(
          telugu: 'లాగిన్ అయిన యూజర్ కనిపించలేదు.',
          english: 'No logged-in user found.',
        );
      case 'Account deleted successfully.':
        return context.strings.localized(
          telugu: 'అకౌంట్ డిలీట్ విజయవంతంగా పూర్తైంది.',
          english: 'Account deleted successfully.',
        );
      case 'Please log in again and retry account deletion.':
        return context.strings.localized(
          telugu: 'మళ్లీ లాగిన్ అయ్యి అకౌంట్ డిలీట్ ప్రయత్నించండి.',
          english: 'Please log in again and retry account deletion.',
        );
      case 'Account deletion failed.':
        return context.strings.localized(
          telugu: 'అకౌంట్ డిలీట్ విఫలమైంది.',
          english: 'Account deletion failed.',
        );
      default:
        return result.message;
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            context.strings.localized(
              telugu: 'అకౌంట్ డిలీట్ నిర్ధారణ',
              english: 'Confirm account deletion',
            ),
          ),
          content: Text(
            context.strings.localized(
              telugu:
                  'మీ లాగిన్, పోస్టర్ ప్రొఫైల్, సబ్‌స్క్రిప్షన్‌కు సంబంధించిన యాక్సెస్ రికార్డులు తొలగించబడతాయి. దీన్ని తిరిగి తీసుకురాలేము.',
              english:
                  'Your login, poster profile, and subscription-related access records will be removed. This cannot be undone.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                context.strings.localized(
                  telugu: 'రద్దు',
                  english: 'Cancel',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.strings.localized(
                  telugu: 'అకౌంట్ డిలీట్ చేయి',
                  english: 'Delete account',
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await _accountDeletionService.deleteCurrentAccount();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizedResultMessage(result))),
      );
      if (!result.success) {
        return;
      }
      await _authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          strings.localized(
            telugu: 'అకౌంట్ డిలీషన్',
            english: 'Account deletion',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB45309),
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  strings.localized(
                    telugu: 'అకౌంట్ డిలీట్ రిక్వెస్ట్‌ను ఇక్కడే పంపవచ్చు',
                    english: 'You can submit your account deletion request here',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.localized(
                    telugu:
                        'డిలీట్ రిక్వెస్ట్‌ను నిర్ధారించిన తర్వాత మీ సైన్-ఇన్ యాక్సెస్, ప్రొఫైల్ ఫోటో, పోస్టర్ ఐడెంటిటీ వివరాలు మరియు యాప్‌కు సంబంధించిన వ్యక్తిగత డేటా తొలగించే ప్రక్రియ ప్రారంభమవుతుంది. Play Store లేదా Apple బిల్లింగ్ రికార్డులు చట్టపరమైన లేదా అకౌంటింగ్ అవసరాల కోసం విడిగా నిల్వ ఉండవచ్చు.',
                    english:
                        'After you confirm deletion, the app starts removing your sign-in access, profile photo, poster identity details, and app-linked personal data. Play Store or Apple billing records may remain separately for legal or accounting purposes.',
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DeletionTile(
            title: strings.localized(
              telugu: 'డిలీషన్ పాలసీ చదవండి',
              english: 'Read deletion policy',
            ),
            subtitle: AppPublicInfo.accountDeletionUrl,
            icon: Icons.open_in_new_rounded,
            onTap: _openDeletionPolicy,
          ),
          const SizedBox(height: 12),
          _DeletionTile(
            title: strings.localized(
              telugu: 'సపోర్ట్ సహాయం కావాలా?',
              english: 'Need help from support?',
            ),
            subtitle: AppPublicInfo.supportEmail,
            icon: Icons.mail_outline_rounded,
            onTap: _emailSupport,
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _deleteAccount,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    strings.localized(
                      telugu: 'అకౌంట్ డిలీషన్ కొనసాగించండి',
                      english: 'Delete my account',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeletionTile extends StatelessWidget {
  const _DeletionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF334155)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
