import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/language_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/permission_settings_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          strings.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            const _ProfileHeaderCard(),
            const SizedBox(height: 18),
            _ProfileSection(
              title: strings.accountSection,
              items: <_ProfileItemData>[
                _ProfileItemData(
                  icon: Icons.language_rounded,
                  title: strings.languageOption,
                  subtitle: strings.languageOptionSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItemData(
                  icon: Icons.workspace_premium_outlined,
                  title: strings.subscriptionOption,
                  subtitle: strings.subscriptionSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: strings.appSettingsSection,
              items: <_ProfileItemData>[
                _ProfileItemData(
                  icon: Icons.verified_user_outlined,
                  title: strings.permissionsTitle,
                  subtitle: strings.permissionsOptionSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PermissionSettingsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItemData(
                  icon: Icons.notifications_none_rounded,
                  title: strings.notifications,
                  subtitle: strings.notificationsOptionSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: strings.supportSection,
              items: <_ProfileItemData>[
                _ProfileItemData(
                  icon: Icons.help_outline_rounded,
                  title: strings.helpSupport,
                  subtitle: strings.helpSupportSubtitle,
                ),
                _ProfileItemData(
                  icon: Icons.info_outline_rounded,
                  title: strings.aboutApp,
                  subtitle: strings.aboutAppSubtitle,
                ),
                _ProfileItemData(
                  icon: Icons.logout_rounded,
                  title: strings.logout,
                  subtitle: strings.logoutSubtitle,
                  isDestructive: true,
                  onTap: () async {
                    await _authService.signOut();
                    await AppFlowService.syncInitialSetupCompletion(
                      isAuthenticated: false,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF132A6B),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Mana Poster User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'user@manaposter.app',
                  style: TextStyle(
                    color: Color(0xFFDCE8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.items});

  final String title;
  final List<_ProfileItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => _ProfileOptionTile(
                    item: entry.value,
                    showDivider: entry.key != items.length - 1,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({required this.item, required this.showDivider});

  final _ProfileItemData item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.isDestructive
        ? const Color(0xFFB91C1C)
        : const Color(0xFF1E3A8A);
    final titleColor = item.isDestructive
        ? const Color(0xFFB91C1C)
        : const Color(0xFF0F172A);

    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isDestructive
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: iconColor, size: 21),
          ),
          title: Text(
            item.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
          ),
          onTap: item.onTap ?? () {},
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 14,
            color: Color(0xFFE2E8F0),
          ),
      ],
    );
  }
}

class _ProfileItemData {
  const _ProfileItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;
}
