import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/account_deletion_screen.dart';
import 'package:mana_poster/features/prehome/screens/about_app_screen.dart';
import 'package:mana_poster/features/prehome/screens/help_support_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';
import 'package:mana_poster/features/prehome/screens/notifications_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/permission_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/poster_profile_details_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/widgets/subscription_exit_video_prompt.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/referral_reward_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AppLanguageStateMixin {
  static final FirebaseAuthService _authService = FirebaseAuthService();

  PosterProfileData _posterProfile = const PosterProfileData(
    nameTelugu: 'Mana Poster Ai User',
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
    unawaited(_safePrecacheImage(imageProvider));
  }

  Future<void> _safePrecacheImage(ImageProvider<Object> imageProvider) async {
    if (!mounted) {
      return;
    }
    try {
      await precacheImage(imageProvider, context);
    } catch (error, stackTrace) {
      developer.log(
        'Profile image warmup skipped: $error',
        name: 'profile.screen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _logout(_ProfileCopy copy) async {
    try {
      await _authService.signOut();
      await AppFlowService.syncInitialSetupCompletion(isAuthenticated: false);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.logoutFailedMessage)));
    }
  }

  Future<void> _shareApp(_ProfileCopy copy) async {
    try {
      final user = _authService.currentUser;
      final userName = (user?.displayName?.trim().isNotEmpty ?? false)
          ? user!.displayName!.trim()
          : 'User';
      var shareText =
          'Shared by $userName using ${AppPublicInfo.appName}\n'
          'Download the app: ${AppPublicInfo.playStoreUrl}';
      try {
        final referralStatus = await ReferralRewardService().fetchStatus();
        shareText = ReferralRewardService().buildShareText(
          status: referralStatus,
          userName: userName,
        );
      } catch (_) {
        // Keep normal sharing available even if referral status is unavailable.
      }
      final assetData = await rootBundle.load(
        'assets/branding/mana_poster_logo.png',
      );
      final tempDirectory = await getTemporaryDirectory();
      final iconFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}mana_poster_share_app.png',
      );
      await iconFile.writeAsBytes(assetData.buffer.asUint8List(), flush: true);
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        <XFile>[XFile(iconFile.path)],
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.shareAppFailedMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final copy = _ProfileCopy(context.currentLanguage, strings);

    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return PosterProfileDetailsScreen(
      initialProfile: _posterProfile,
      embeddedInProfileScreen: true,
      onSaved: (profile) {
        setState(() => _posterProfile = profile);
        _warmPosterProfileImage(profile);
      },
      appBarActions: <Widget>[
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: copy.settingsTitle,
          icon: const Icon(
            Icons.settings_rounded,
            size: 22,
            color: Color(0xFF0F172A),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ProfileMoreScreen(
                  copy: copy,
                  onShareApp: () => _shareApp(copy),
                  onLogout: () => _logout(copy),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});

  final String title;
  final List<_ProfileItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
        : const Color(0xFF0F172A);
    final titleColor = item.isDestructive
        ? const Color(0xFFB91C1C)
        : const Color(0xFF0F172A);
    final iconBackground = item.isDestructive
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFF8FAFC);

    return Column(
      children: <Widget>[
        ListTile(
          minTileHeight: 52,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: _buildLeading(iconBackground, iconColor),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: titleColor,
              fontSize: 15,
            ),
          ),
          subtitle: null,
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
            indent: 62,
            endIndent: 14,
            color: Color(0x1A0F172A),
          ),
      ],
    );
  }

  Widget _buildLeading(Color iconBackground, Color iconColor) {
    switch (item.badge) {
      case _ProfileItemBadge.googlePlay:
        return Container(
          width: 48,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B0B),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/branding/google_logo.png',
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 4),
              const Flexible(
                child: Text(
                  'Play',
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      case _ProfileItemBadge.premium:
        return Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF7CC),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFB45309),
            size: 22,
          ),
        );
      case _ProfileItemBadge.bell:
        return Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF7CC),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.notifications_active_rounded,
            color: Color(0xFFEAB308),
            size: 21,
          ),
        );
      case null:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, color: iconColor, size: 20),
        );
    }
  }
}

class _ProfileMoreScreen extends StatelessWidget {
  const _ProfileMoreScreen({
    required this.copy,
    required this.onShareApp,
    required this.onLogout,
  });

  final _ProfileCopy copy;
  final Future<void> Function() onShareApp;
  final Future<void> Function() onLogout;

  Future<void> _openSubscriptionPlan(
    BuildContext context, {
    bool triggerRestoreOnOpen = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SubscriptionPlanScreen(triggerRestoreOnOpen: triggerRestoreOnOpen),
      ),
    );
    if (!context.mounted) {
      return;
    }
    final result = await SubscriptionBackendService().fetchFreshEntitlement();
    if (!context.mounted || result.hasAccess) {
      return;
    }
    await showSubscriptionExitVideoPromptIfAvailable(
      context,
      onSubscribe: (_) =>
          _openSubscriptionPlan(context, triggerRestoreOnOpen: false),
    );
  }

  Future<void> _openReferralRewards(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ReferralRewardsDialog(copy: copy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(copy.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          _SettingsGroup(
            title: copy.quickActionsTitle,
            items: <_ProfileItemData>[
              _ProfileItemData(
                icon: Icons.ios_share_rounded,
                title: copy.shareAppTitle,
                subtitle: copy.shareAppSubtitle,
                onTap: () => unawaited(onShareApp()),
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
                icon: Icons.card_membership_rounded,
                title: copy.subscriptionTitle,
                subtitle: copy.subscriptionSubtitle,
                badge: _ProfileItemBadge.premium,
                onTap: () => unawaited(_openSubscriptionPlan(context)),
              ),
              _ProfileItemData(
                icon: Icons.group_add_rounded,
                title: copy.referralRewardsTitle,
                subtitle: copy.referralRewardsSubtitle,
                onTap: () => unawaited(_openReferralRewards(context)),
              ),
              _ProfileItemData(
                icon: Icons.restore_rounded,
                title: copy.restoreSubscriptionTitle,
                subtitle: copy.restoreSubscriptionSubtitle,
                onTap: () => unawaited(
                  _openSubscriptionPlan(context, triggerRestoreOnOpen: true),
                ),
              ),
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
                badge: _ProfileItemBadge.bell,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsSettingsScreen(),
                    ),
                  );
                },
              ),
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
                icon: Icons.privacy_tip_outlined,
                title: copy.privacyPolicyTitle,
                subtitle: copy.privacyPolicySubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalDocumentScreen(
                        documentType: LegalDocumentType.privacyPolicy,
                      ),
                    ),
                  );
                },
              ),
              _ProfileItemData(
                icon: Icons.gavel_rounded,
                title: copy.legalNoticesTitle,
                subtitle: copy.legalNoticesSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalDocumentScreen(
                        documentType: LegalDocumentType.termsAndConditions,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: copy.supportTitle,
            items: <_ProfileItemData>[
              _ProfileItemData(
                icon: Icons.info_outline_rounded,
                title: copy.aboutTitle,
                subtitle: copy.aboutSubtitle,
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
                onTap: () => unawaited(onLogout()),
              ),
              _ProfileItemData(
                icon: Icons.delete_forever_outlined,
                title: copy.deleteAccountTitle,
                subtitle: copy.deleteAccountSubtitle,
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountDeletionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralRewardsDialog extends StatefulWidget {
  const _ReferralRewardsDialog({required this.copy});

  final _ProfileCopy copy;

  @override
  State<_ReferralRewardsDialog> createState() => _ReferralRewardsDialogState();
}

class _ReferralRewardsDialogState extends State<_ReferralRewardsDialog> {
  final ReferralRewardService _service = ReferralRewardService();
  final TextEditingController _codeController = TextEditingController();
  Future<ReferralRewardStatus>? _statusFuture;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = _service.fetchStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _share(ReferralRewardStatus status) async {
    final user = FirebaseAuthService().currentUser;
    final userName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'User';
    await Share.share(
      _service.buildShareText(status: status, userName: userName),
    );
  }

  Future<void> _copyCode(ReferralRewardStatus status) async {
    await Clipboard.setData(ClipboardData(text: status.code));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.copy.referralCodeCopiedMessage)),
    );
  }

  Future<void> _applyCode() async {
    if (_applying) {
      return;
    }
    setState(() => _applying = true);
    try {
      final result = await _service.applyCode(_codeController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _applying = false;
        _statusFuture = _service.fetchStatus();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.accepted
                ? widget.copy.referralCodeAppliedMessage
                : (result.message.isEmpty
                      ? widget.copy.referralCodeAlreadyAppliedMessage
                      : result.message),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.copy.referralCodeApplyFailedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final mediaQuery = MediaQuery.of(context);
    final maxDialogContentHeight =
        mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.padding.vertical -
        220;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(copy.referralRewardsTitle),
      content: FutureBuilder<ReferralRewardStatus>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 112,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData) {
            return SizedBox(
              width: 320,
              child: Text(copy.referralLoadFailedMessage),
            );
          }
          final status = snapshot.data!;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 360,
              maxHeight: maxDialogContentHeight.clamp(220, 520).toDouble(),
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SelectableText(
                    status.code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.referralProgressText(
                      status.currentCyclePaidCount,
                      status.requiredPaidReferrals,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => unawaited(_copyCode(status)),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(copy.copyReferralCodeAction),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => unawaited(_share(status)),
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: Text(copy.shareReferralAction),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: copy.applyReferralCodeLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _applying
                          ? null
                          : () => unawaited(_applyCode()),
                      child: _applying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(copy.applyReferralCodeAction),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LegalDocumentScreen(
                              documentType:
                                  LegalDocumentType.termsAndConditions,
                            ),
                          ),
                        );
                      },
                      child: Text(copy.referralTermsAction),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(copy.closeAction),
        ),
      ],
    );
  }
}

class _ProfileItemData {
  const _ProfileItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final _ProfileItemBadge? badge;
  final VoidCallback? onTap;
}

enum _ProfileItemBadge { googlePlay, premium, bell }

class _ProfileCopy {
  const _ProfileCopy(this.language, this.strings);

  final AppLanguage language;
  final AppStrings strings;

  bool get _isTelugu => language == AppLanguage.telugu;

  String get quickActionsTitle =>
      _isTelugu ? 'త్వరిత ఎంపికలు' : 'Quick actions';
  String get supportTitle =>
      _isTelugu ? '\u0c38\u0c39\u0c3e\u0c2f\u0c02' : strings.supportSection;

  String get posterProfileTitle => _isTelugu
      ? 'వ్యక్తిగత & బిజినెస్ వివరాలు'
      : 'Personal & Business Details';
  String get posterProfileSubtitle => _isTelugu
      ? 'ఫోటో, పేరు, బిజినెస్ వివరాలు అప్డేట్ చేయండి'
      : 'Update photo, personal, and business details';
  String get moreTitle => _isTelugu ? 'మరిన్ని' : 'More';
  String get moreSubtitle =>
      _isTelugu ? 'మిగతా అన్ని ఆప్షన్లు' : 'Remaining options';
  String get settingsTitle => _isTelugu ? 'సెట్టింగ్స్' : 'Settings';

  String get languageTitle =>
      _isTelugu ? '\u0c2d\u0c3e\u0c37' : strings.languageOption;
  String? get languageSubtitle =>
      _isTelugu ? 'యాప్ భాష మార్చండి' : 'Change app language';

  String get subscriptionTitle =>
      _isTelugu ? 'ప్లాన్ వివరాలు' : strings.subscriptionOption;
  String get subscriptionSubtitle =>
      _isTelugu ? 'సబ్‌స్క్రిప్షన్ ప్లాన్ చూడండి' : 'View plan details';
  String get referralRewardsTitle =>
      _isTelugu ? 'రిఫరల్ బహుమతులు' : 'Referral rewards';
  String get referralRewardsSubtitle => _isTelugu
      ? 'రిఫరల్ కోడ్ మరియు ప్రస్తుత చక్రం చూడండి'
      : 'View referral code and current cycle';
  String referralProgressText(int current, int required) {
    return _isTelugu
        ? 'ప్రస్తుత చక్రం: $current / $required'
        : 'Current cycle: $current / $required';
  }

  String get copyReferralCodeAction => _isTelugu ? 'కోడ్ కాపీ' : 'Copy code';
  String get shareReferralAction => _isTelugu ? 'షేర్' : 'Share';
  String get referralTermsAction =>
      _isTelugu ? 'నిబంధనలు మరియు షరతులు చూడండి' : 'View Terms & Conditions';
  String get applyReferralCodeLabel =>
      _isTelugu ? 'రిఫరల్ కోడ్ నమోదు చేయండి' : 'Enter referral code';
  String get applyReferralCodeAction => _isTelugu ? 'అప్లై' : 'Apply';
  String get referralCodeCopiedMessage =>
      _isTelugu ? 'రిఫరల్ కోడ్ కాపీ అయింది' : 'Referral code copied';
  String get referralCodeAppliedMessage =>
      _isTelugu ? 'రిఫరల్ కోడ్ అప్లై అయింది' : 'Referral code applied';
  String get referralCodeAlreadyAppliedMessage =>
      _isTelugu ? 'రిఫరల్ ఇప్పటికే అప్లై అయింది' : 'Referral already applied';
  String get referralCodeApplyFailedMessage => _isTelugu
      ? 'రిఫరల్ కోడ్ అప్లై కాలేదు. మళ్లీ ప్రయత్నించండి'
      : 'Referral code apply failed. Please try again.';
  String get referralLoadFailedMessage => _isTelugu
      ? 'రిఫరల్ వివరాలు లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి'
      : 'Referral details could not load. Please try again.';
  String get closeAction => _isTelugu ? 'మూసివేయండి' : 'Close';
  String get restoreSubscriptionTitle =>
      _isTelugu ? 'సబ్‌స్క్రిప్షన్ రీస్టోర్ చేయండి' : 'Restore subscriptions';
  String get restoreSubscriptionSubtitle => _isTelugu
      ? 'అదే అకౌంట్ కొనుగోళ్లు మళ్లీ తెచ్చుకోండి'
      : 'Restore purchases for this account';

  String get permissionsTitle => _isTelugu
      ? '\u0c2a\u0c30\u0c4d\u0c2e\u0c3f\u0c37\u0c28\u0c4d\u0c38\u0c4d'
      : strings.permissionsTitle;
  String? get permissionsSubtitle =>
      _isTelugu ? 'యాక్సెస్ అనుమతులు' : 'Access controls';

  String get notificationsTitle => _isTelugu
      ? '\u0c28\u0c4b\u0c1f\u0c3f\u0c2b\u0c3f\u0c15\u0c47\u0c37\u0c28\u0c4d\u0c38\u0c4d'
      : strings.notifications;
  String? get notificationsSubtitle =>
      _isTelugu ? 'అలర్ట్ సెట్టింగ్స్' : 'Notification preferences';

  String get shareAppTitle => _isTelugu ? 'యాప్ షేర్ చేయండి' : 'Share App';
  String get shareAppSubtitle => _isTelugu
      ? 'యాప్ ఐకాన్, ప్లే స్టోర్ లింక్‌ను పంచుకోండి'
      : 'Share the app icon and Play Store link';
  String get shareAppFailedMessage => _isTelugu
      ? 'యాప్ షేర్ కాలేదు. మళ్లీ ప్రయత్నించండి'
      : 'App share failed. Please try again.';
  String get accountEmailFallback => _isTelugu
      ? 'ఈ అకౌంట్‌కు ఇమెయిల్ అందుబాటులో లేదు'
      : 'Email not available for this account';

  String get helpTitle => _isTelugu
      ? '\u0c39\u0c46\u0c32\u0c4d\u0c2a\u0c4d \u0c38\u0c2a\u0c4b\u0c30\u0c4d\u0c1f\u0c4d'
      : strings.helpSupport;
  String? get helpSubtitle => _isTelugu ? 'సహాయం పొందండి' : 'Get help';

  String get aboutTitle => _isTelugu
      ? '\u0c2f\u0c3e\u0c2a\u0c4d \u0c17\u0c41\u0c30\u0c3f\u0c02\u0c1a\u0c3f'
      : strings.aboutApp;
  String get aboutSubtitle => _isTelugu ? 'యాప్ వివరాలు' : 'About the app';
  String get logoutTitle => _isTelugu
      ? '\u0c32\u0c3e\u0c17\u0c4d \u0c05\u0c35\u0c41\u0c1f\u0c4d'
      : strings.logout;
  String get logoutSubtitle => _isTelugu
      ? 'ఈ డివైస్‌లో మీ అకౌంట్ నుంచి బయటకు రండి'
      : 'Sign out from this device';
  String get logoutFailedMessage => _isTelugu
      ? 'లాగ్ అవుట్ కాలేదు. మళ్లీ ప్రయత్నించండి.'
      : 'Logout failed. Please try again.';
  String get deleteAccountTitle =>
      _isTelugu ? 'అకౌంట్ డిలీట్' : 'Delete account';
  String get deleteAccountSubtitle => _isTelugu
      ? 'మీ అకౌంట్ మరియు డేటా తొలగింపు రిక్వెస్ట్ ప్రారంభించండి'
      : 'Start your account and data removal request';
  String get privacyPolicyTitle =>
      _isTelugu ? 'ప్రైవసీ పాలసీ' : 'Privacy Policy';
  String get privacyPolicySubtitle =>
      _isTelugu ? 'డేటా వినియోగం చూడండి' : 'Data usage and privacy';
  String get legalNoticesTitle =>
      _isTelugu ? 'లీగల్ నోటీసెస్' : 'Legal Notices';
  String get legalNoticesSubtitle =>
      _isTelugu ? 'టెర్మ్స్ మరియు కండిషన్స్' : 'Terms and conditions';
}
