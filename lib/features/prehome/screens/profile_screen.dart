import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/about_app_screen.dart';
import 'package:mana_poster/features/prehome/screens/help_support_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/notifications_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/permission_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/poster_profile_details_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/widgets/poster_identity_visual.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AppLanguageStateMixin {
  static final FirebaseAuthService _authService = FirebaseAuthService();

  PosterProfileData _posterProfile = const PosterProfileData(
    nameTelugu: 'Mana Poster User',
    nameEnglish: '',
    whatsappNumber: '',
    nameFontFamily: 'Anek Telugu Condensed Bold',
    displayNameMode: PosterDisplayNameMode.auto,
    photoPath: '',
    photoUrl: '',
  );
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadPosterProfile();
  }

  Future<void> _loadPosterProfile() async {
    final profile = await PosterProfileService.loadLocal();
    if (!mounted) {
      return;
    }
    setState(() {
      _posterProfile = profile;
      _loadingProfile = false;
    });
    _warmPosterProfileImage(profile);
    unawaited(_refreshPosterProfileRemote(profile));
  }

  Future<void> _refreshPosterProfileRemote(PosterProfileData local) async {
    final profile = await PosterProfileService.refreshFromRemote(
      localProfile: local,
    );
    if (!mounted || profile == null) {
      return;
    }
    setState(() => _posterProfile = profile);
    _warmPosterProfileImage(profile);
  }

  void _warmPosterProfileImage(PosterProfileData profile) {
    final imageProvider = PosterProfileService.resolveImageProvider(profile);
    if (imageProvider == null || !mounted) {
      return;
    }
    unawaited(precacheImage(imageProvider, context));
  }

  Future<void> _openPosterProfileScreen() async {
    final PosterProfileData? result = await Navigator.of(context).push(
      MaterialPageRoute<PosterProfileData>(
        builder: (_) =>
            PosterProfileDetailsScreen(initialProfile: _posterProfile),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _posterProfile = result);
    _warmPosterProfileImage(result);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final copy = _ProfileCopy(context.currentLanguage, strings);
    final user = _authService.currentUser;

    final profileResolvedName = _posterProfile.resolvedName(
      language: strings.language,
    );
    final fallbackUserName = user?.displayName?.trim() ?? '';
    final displayName = _posterProfile.activeName.trim().isNotEmpty
        ? profileResolvedName
        : (fallbackUserName.isNotEmpty
              ? _posterProfile
                    .copyWith(displayName: fallbackUserName)
                    .resolvedName(language: strings.language)
              : profileResolvedName);
    final email = user?.email ?? 'user@manaposter.app';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF3F6FB),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.screenTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF5F8FF),
              Color(0xFFF9FBFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
            children: <Widget>[
              if (_loadingProfile) ...<Widget>[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: _ProfileHeader(
                  appName: copy.appName,
                  name: displayName,
                  email: email,
                  profile: _posterProfile,
                  helperText: copy.headerSupportText,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: _SettingsGroup(
                  title: copy.accountTitle,
                  visual: const _SectionVisual(
                    start: Color(0xFFEEF4FF),
                    end: Color(0xFFFFFFFF),
                    iconTint: Color(0xFF1D4ED8),
                  ),
                  items: <_ProfileItemData>[
                    _ProfileItemData(
                      icon: Icons.badge_outlined,
                      title: copy.posterProfileTitle,
                      subtitle: copy.posterProfileSubtitle,
                      onTap: _openPosterProfileScreen,
                    ),
                    _ProfileItemData(
                      icon: Icons.language_rounded,
                      title: copy.languageTitle,
                      subtitle: copy.languageSubtitle,
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
                      title: copy.subscriptionTitle,
                      subtitle: copy.subscriptionSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SubscriptionPlanScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: _SettingsGroup(
                  title: copy.settingsTitle,
                  visual: const _SectionVisual(
                    start: Color(0xFFECFDF5),
                    end: Color(0xFFFFFFFF),
                    iconTint: Color(0xFF0F766E),
                  ),
                  items: <_ProfileItemData>[
                    _ProfileItemData(
                      icon: Icons.verified_user_outlined,
                      title: copy.permissionsTitle,
                      subtitle: copy.permissionsSubtitle,
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
                      title: copy.notificationsTitle,
                      subtitle: copy.notificationsSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: _SettingsGroup(
                  title: copy.supportTitle,
                  visual: const _SectionVisual(
                    start: Color(0xFFFFF7ED),
                    end: Color(0xFFFFFFFF),
                    iconTint: Color(0xFFB45309),
                  ),
                  items: <_ProfileItemData>[
                    _ProfileItemData(
                      icon: Icons.help_outline_rounded,
                      title: copy.helpTitle,
                      subtitle: copy.helpSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileItemData(
                      icon: Icons.info_outline_rounded,
                      title: copy.aboutTitle,
                      subtitle: null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AboutAppScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileItemData(
                      icon: Icons.logout_rounded,
                      title: copy.logoutTitle,
                      subtitle: copy.logoutSubtitle,
                      isDestructive: true,
                      onTap: () async {
                        try {
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
                        } catch (_) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(copy.logoutFailedMessage)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.appName,
    required this.name,
    required this.email,
    required this.helperText,
    this.profile,
  });

  final String appName;
  final String name;
  final String email;
  final String helperText;
  final PosterProfileData? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFEAF4FF),
            Color(0xFFF3F9FF),
            Color(0xFFFFFFFF),
          ],
        ),
        border: Border.all(color: const Color(0xD9E2ECFA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14223D70),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: profile == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: Color(0xFF1D4ED8),
                  )
                : PosterIdentityVisual(
                    profile: profile!,
                    fallbackBackground: const Color(0xFFE9F0FF),
                    fallbackIconColor: const Color(0xFF1D4ED8),
                  ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 21,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              helperText,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.items,
    required this.visual,
  });

  final String title;
  final List<_ProfileItemData> items;
  final _SectionVisual visual;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[visual.start, visual.end],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF8)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => _ProfileOptionTile(
                    item: entry.value,
                    showDivider: entry.key != items.length - 1,
                    accent: visual.iconTint,
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
  const _ProfileOptionTile({
    required this.item,
    required this.showDivider,
    required this.accent,
  });

  final _ProfileItemData item;
  final bool showDivider;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.isDestructive ? const Color(0xFFB91C1C) : accent;
    final titleColor = item.isDestructive
        ? const Color(0xFFB91C1C)
        : const Color(0xFF0F172A);
    final iconBackground = item.isDestructive
        ? const Color(0xFFFEE2E2)
        : accent.withValues(alpha: 0.14);

    return Column(
      children: <Widget>[
        ListTile(
          minTileHeight: 60,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 1,
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: iconColor, size: 19),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: titleColor,
              fontSize: 14.6,
            ),
          ),
          subtitle: item.subtitle == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.black.withValues(alpha: 0.32),
            size: 21,
          ),
          onTap: item.onTap ?? () {},
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 60,
            endIndent: 12,
            color: Color(0x1A0F172A),
          ),
      ],
    );
  }
}

class _SectionVisual {
  const _SectionVisual({
    required this.start,
    required this.end,
    required this.iconTint,
  });

  final Color start;
  final Color end;
  final Color iconTint;
}

class _ProfileItemData {
  const _ProfileItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;
}

class _ProfileCopy {
  const _ProfileCopy(this.language, this.strings);

  final AppLanguage language;
  final AppStrings strings;

  bool get _isTelugu => language == AppLanguage.telugu;

  String get screenTitle => _isTelugu
      ? '\u0c2a\u0c4d\u0c30\u0c4a\u0c2b\u0c48\u0c32\u0c4d \u0c38\u0c46\u0c1f\u0c4d\u0c1f\u0c3f\u0c02\u0c17\u0c4d\u0c38\u0c4d'
      : strings.profileTitle;
  String get appName => _isTelugu
      ? '\u0c2e\u0c28 \u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d'
      : strings.localized(
          telugu: 'మన పోస్టర్',
          english: 'Mana Poster',
          hindi: 'मना पोस्टर',
          tamil: 'மனா போஸ்டர்',
          kannada: 'ಮನ ಪೋಸ್ಟರ್',
          malayalam: 'മന പോസ്റ്റർ',
        );
  String get headerSupportText => strings.localized(
    telugu: 'మీ అకౌంట్, ప్లాన్, యాప్ సెట్టింగ్స్ ఇక్కడ నిర్వహించండి',
    english: 'Manage account, plan, and app settings here.',
    hindi: 'अपना अकाउंट, प्लान और ऐप सेटिंग्स यहां मैनेज करें।',
    tamil: 'உங்கள் கணக்கு, திட்டம், ஆப் அமைப்புகளை இங்கே நிர்வகிக்கவும்.',
    kannada:
        'ನಿಮ್ಮ ಅಕೌಂಟ್, ಪ್ಲಾನ್ ಮತ್ತು ಆಪ್ ಸೆಟ್ಟಿಂಗ್ಸ್ ಅನ್ನು ಇಲ್ಲಿ ನಿರ್ವಹಿಸಿ.',
    malayalam:
        'നിങ്ങളുടെ അക്കൗണ്ട്, പ്ലാൻ, ആപ്പ് സെറ്റിംഗ്സ് ഇവിടെ നിയന്ത്രിക്കുക.',
  );

  String get accountTitle => _isTelugu
      ? '\u0c05\u0c15\u0c4c\u0c02\u0c1f\u0c4d'
      : strings.accountSection;
  String get settingsTitle => _isTelugu
      ? '\u0c2f\u0c3e\u0c2a\u0c4d \u0c38\u0c46\u0c1f\u0c4d\u0c1f\u0c3f\u0c02\u0c17\u0c4d\u0c38\u0c4d'
      : strings.appSettingsSection;
  String get supportTitle =>
      _isTelugu ? '\u0c38\u0c39\u0c3e\u0c2f\u0c02' : strings.supportSection;

  String get posterProfileTitle => _isTelugu
      ? '\u0c2a\u0c4b\u0c38\u0c4d\u0c1f\u0c30\u0c4d \u0c2a\u0c4d\u0c30\u0c4a\u0c2b\u0c48\u0c32\u0c4d \u0c2c\u0c3f\u0c1c\u0c3f\u0c28\u0c46\u0c38\u0c4d'
      : 'Poster Profile & Business';
  String get posterProfileSubtitle => _isTelugu
      ? '\u0c2a\u0c47\u0c30\u0c41, \u0c2b\u0c4b\u0c1f\u0c4b, \u0c2c\u0c3f\u0c1c\u0c3f\u0c28\u0c46\u0c38\u0c4d \u0c35\u0c3f\u0c35\u0c30\u0c3e\u0c32\u0c41'
      : 'Profile and business details';

  String get languageTitle =>
      _isTelugu ? '\u0c2d\u0c3e\u0c37' : strings.languageOption;
  String? get languageSubtitle => _isTelugu
      ? '\u0c2f\u0c3e\u0c2a\u0c4d \u0c2d\u0c3e\u0c37 \u0c2e\u0c3e\u0c30\u0c4d\u0c1a\u0c02\u0c21\u0c3f'
      : strings.localized(
          telugu: 'యాప్ భాష మార్చండి',
          english: 'Change app language',
          hindi: 'ऐप की भाषा बदलें',
          tamil: 'ஆப் மொழியை மாற்றவும்',
          kannada: 'ಆಪ್ ಭಾಷೆ ಬದಲಿಸಿ',
          malayalam: 'ആപ്പ് ഭാഷ മാറ്റുക',
        );

  String get subscriptionTitle => _isTelugu
      ? '\u0c2a\u0c4d\u0c32\u0c3e\u0c28\u0c4d \u0c35\u0c3f\u0c35\u0c30\u0c3e\u0c32\u0c41'
      : strings.subscriptionOption;
  String get subscriptionSubtitle => _isTelugu
      ? '\u0c38\u0c2c\u0c4d\u0c38\u0c4d\u0c15\u0c4d\u0c30\u0c3f\u0c2a\u0c4d\u0c37\u0c28\u0c4d \u0c2a\u0c4d\u0c32\u0c3e\u0c28\u0c4d \u0c1a\u0c42\u0c21\u0c02\u0c21\u0c3f'
      : strings.localized(
          telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్ చూడండి',
          english: 'View plan details',
          hindi: 'प्लान विवरण देखें',
          tamil: 'பிளான் விவரங்களை பார்க்கவும்',
          kannada: 'ಪ್ಲಾನ್ ವಿವರಗಳನ್ನು ನೋಡಿ',
          malayalam: 'പ്ലാൻ വിവരങ്ങൾ കാണുക',
        );

  String get permissionsTitle => _isTelugu
      ? '\u0c2a\u0c30\u0c4d\u0c2e\u0c3f\u0c37\u0c28\u0c4d\u0c38\u0c4d'
      : strings.permissionsTitle;
  String? get permissionsSubtitle => _isTelugu
      ? '\u0c2f\u0c3e\u0c15\u0c4d\u0c38\u0c46\u0c38\u0c4d \u0c05\u0c28\u0c41\u0c2e\u0c24\u0c41\u0c32\u0c41'
      : strings.localized(
          telugu: 'యాక్సెస్ అనుమతులు',
          english: 'Access controls',
          hindi: 'एक्सेस नियंत्रण',
          tamil: 'அணுகல் கட்டுப்பாடுகள்',
          kannada: 'ಪ್ರವೇಶ ನಿಯಂತ್ರಣಗಳು',
          malayalam: 'ആക്സസ് നിയന്ത്രണങ്ങൾ',
        );

  String get notificationsTitle => _isTelugu
      ? '\u0c28\u0c4b\u0c1f\u0c3f\u0c2b\u0c3f\u0c15\u0c47\u0c37\u0c28\u0c4d\u0c38\u0c4d'
      : strings.notifications;
  String? get notificationsSubtitle => _isTelugu
      ? '\u0c05\u0c32\u0c30\u0c4d\u0c1f\u0c4d \u0c38\u0c46\u0c1f\u0c4d\u0c1f\u0c3f\u0c02\u0c17\u0c4d\u0c38\u0c4d'
      : strings.localized(
          telugu: 'నోటిఫికేషన్ ప్రాధాన్యతలు',
          english: 'Notification preferences',
          hindi: 'नोटिफिकेशन पसंद',
          tamil: 'அறிவிப்பு விருப்பங்கள்',
          kannada: 'ನೋಟಿಫಿಕೇಶನ್ ಆಯ್ಕೆಗಳು',
          malayalam: 'നോട്ടിഫിക്കേഷൻ മുൻഗണനകൾ',
        );

  String get helpTitle => _isTelugu
      ? '\u0c39\u0c46\u0c32\u0c4d\u0c2a\u0c4d \u0c38\u0c2a\u0c4b\u0c30\u0c4d\u0c1f\u0c4d'
      : strings.helpSupport;
  String? get helpSubtitle => _isTelugu
      ? '\u0c38\u0c2e\u0c38\u0c4d\u0c2f\u0c32\u0c15\u0c41 \u0c38\u0c39\u0c3e\u0c2f\u0c02'
      : strings.localized(
          telugu: 'సహాయం పొందండి',
          english: 'Get help',
          hindi: 'मदद लें',
          tamil: 'உதவி பெறுங்கள்',
          kannada: 'ಸಹಾಯ ಪಡೆಯಿರಿ',
          malayalam: 'സഹായം നേടുക',
        );

  String get aboutTitle => _isTelugu
      ? '\u0c2f\u0c3e\u0c2a\u0c4d \u0c17\u0c41\u0c30\u0c3f\u0c02\u0c1a\u0c3f'
      : strings.aboutApp;
  String get logoutTitle => _isTelugu
      ? '\u0c32\u0c3e\u0c17\u0c4d \u0c05\u0c35\u0c41\u0c1f\u0c4d'
      : strings.logout;
  String get logoutSubtitle => strings.localized(
    telugu: 'ఈ డివైస్‌లోని మీ అకౌంట్ సెషన్ నుంచి బయటకు రండి',
    english: 'Sign out from your account on this device',
    hindi: 'इस डिवाइस पर अपने अकाउंट से साइन आउट करें',
    tamil: 'இந்த சாதனத்தில் உங்கள் கணக்கிலிருந்து வெளியேறுங்கள்',
    kannada: 'ಈ ಸಾಧನದಲ್ಲಿನ ನಿಮ್ಮ ಖಾತೆಯಿಂದ ಸೈನ್ ಔಟ್ ಮಾಡಿ',
    malayalam: 'ഈ ഉപകരണത്തിലെ നിങ്ങളുടെ അക്കൗണ്ടിൽ നിന്ന് സൈൻ ഔട്ട് ചെയ്യുക',
  );
  String get logoutFailedMessage => strings.localized(
    telugu: 'లాగౌట్ పూర్తికాలేదు. మళ్లీ ప్రయత్నించండి.',
    english: 'Logout failed. Please try again.',
    hindi: 'लॉगआउट पूरा नहीं हुआ। फिर से कोशिश करें।',
    tamil: 'வெளியேற்றம் முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    kannada: 'ಲಾಗೌಟ್ ಪೂರ್ಣವಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'ലോഗ്ഔട്ട് പൂർത്തിയായില്ല. വീണ്ടും ശ്രമിക്കുക.',
  );
}
