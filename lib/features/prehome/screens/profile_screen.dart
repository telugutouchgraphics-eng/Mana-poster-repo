import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/services/admob_consent_service.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/screens/account_deletion_screen.dart';
import 'package:mana_poster/features/prehome/screens/about_app_screen.dart';
import 'package:mana_poster/features/prehome/screens/help_support_screen.dart';
import 'package:mana_poster/features/prehome/screens/language_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/notifications_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/permission_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/poster_profile_details_screen.dart';
import 'package:mana_poster/features/prehome/screens/purchase_invoices_screen.dart';
import 'package:mana_poster/features/prehome/screens/quiz_prize_details_screen.dart';
import 'package:mana_poster/features/prehome/screens/region_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/religion_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/onboarding_surface_card.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';
import 'package:mana_poster/features/prehome/widgets/subscription_exit_video_prompt.dart';
import 'package:mana_poster/features/prehome/services/app_location_service.dart';
import 'package:mana_poster/features/prehome/services/app_party_preference_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
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

Future<void> _openExternalPublicUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) {
      return;
    }
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showTopSnackBar(
    AppSnackBar.build(
      content: Text(
        context.strings.localized(
          telugu: 'లింక్ తెరవలేకపోయాం. మళ్లీ ప్రయత్నించండి.',
          english: 'Could not open the link. Please try again.',
        ),
      ),
    ),
  );
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
  bool _privacyChoicesVisible = false;
  String _selectedRegionName = '';

  @override
  void initState() {
    super.initState();
    _loadPosterProfile();
    unawaited(_loadSelectedRegionName());
    unawaited(_loadPrivacyChoicesVisibility());
  }

  Future<void> _loadSelectedRegionName() async {
    final selection = await AppRegionService.loadSelection();
    if (!mounted) {
      return;
    }
    setState(() => _selectedRegionName = selection?.name ?? '');
  }

  Future<void> _loadPrivacyChoicesVisibility() async {
    final required = await AdMobConsentService.instance
        .isPrivacyOptionsRequired();
    if (!mounted) {
      return;
    }
    setState(() => _privacyChoicesVisible = required);
  }

  Future<void> _loadPosterProfile() async {
    try {
      final localProfile = await PosterProfileService.loadLocal();
      if (!mounted) {
        return;
      }
      setState(() {
        _posterProfile = localProfile;
        _loadingProfile = false;
      });
      _warmPosterProfileImage(localProfile);
      unawaited(_refreshPosterProfileInBackground(localProfile));
    } catch (error, stackTrace) {
      developer.log(
        'Profile load failed: $error',
        name: 'profile.screen',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _refreshPosterProfileInBackground(
    PosterProfileData currentProfile,
  ) async {
    try {
      final refreshedProfile = await PosterProfileService.load();
      if (!mounted) {
        return;
      }
      if (refreshedProfile == currentProfile) {
        _warmPosterProfileImage(refreshedProfile);
        return;
      }
      setState(() {
        _posterProfile = refreshedProfile;
      });
      _warmPosterProfileImage(refreshedProfile);
    } catch (error, stackTrace) {
      developer.log(
        'Profile background refresh skipped: $error',
        name: 'profile.screen',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _warmPosterProfileImage(PosterProfileData profile) {
    final imageProvider = PosterProfileService.resolveImageProvider(
      profile,
      preferOriginalPersonalPhoto:
          profile.identityMode == PosterIdentityMode.personal,
    );
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
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(content: Text(copy.logoutFailedMessage)),
      );
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
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(iconFile.path)],
          text: shareText,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(content: Text(copy.shareAppFailedMessage)),
      );
    }
  }

  Future<void> _openReligionSelection(_ProfileCopy copy) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            const ReligionSelectionScreen(returnToPreviousOnSave: true),
      ),
    );
    if (!mounted || changed != true) {
      return;
    }

    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final selection = await AppReligionService.loadSelection();
    if (!mounted || selection == null) {
      return;
    }

    final message = switch (selection) {
      AppReligionPreference.hindu => copy.religionSavedHinduMessage,
      AppReligionPreference.muslim => copy.religionSavedMuslimMessage,
      AppReligionPreference.christian => copy.religionSavedChristianMessage,
      AppReligionPreference.all => copy.religionSavedAllMessage,
    };

    ScaffoldMessenger.of(
      context,
    ).showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  Future<void> _openRegionSelection(_ProfileCopy copy) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            const RegionSelectionScreen(returnToPreviousOnSave: true),
      ),
    );
    if (!mounted || changed != true) {
      return;
    }

    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final selection = await AppRegionService.loadSelection();
    if (!mounted || selection == null) {
      return;
    }

    final snapshot = await AppFlowService.loadSnapshot();
    if (!mounted) {
      return;
    }
    context.languageController.setLanguage(snapshot.language);
    setState(() => _selectedRegionName = selection.name);
    await AppPartyPreferenceService.persistSelection(<String>{});
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showTopSnackBar(AppSnackBar.build(content: Text(copy.stateSavedMessage)));
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
      accountEmail: Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser?.email?.trim() ?? ''
          : '',
      accountSubtitle: _selectedRegionName,
      embeddedInProfileScreen: true,
      onSaved: (profile) {
        setState(() => _posterProfile = profile);
        _warmPosterProfileImage(profile);
      },
      appBarActions: <Widget>[
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: copy.religionTitle,
          icon: const Icon(
            Icons.account_balance_rounded,
            size: 22,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => unawaited(_openReligionSelection(copy)),
        ),
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
                  onShareApp: _shareApp,
                  onOpenRegionSelection: _openRegionSelection,
                  onOpenReligionSelection: _openReligionSelection,
                  onLogout: _logout,
                  showAdPrivacyChoices: _privacyChoicesVisible,
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

class _DailyQuizStatsSummary {
  const _DailyQuizStatsSummary({
    required this.totalCorrect,
    required this.totalAnswered,
  });

  final int totalCorrect;
  final int totalAnswered;
}

class _DailyQuizStatsCard extends StatelessWidget {
  const _DailyQuizStatsCard({required this.copy});

  final _ProfileCopy copy;

  Future<_DailyQuizStatsSummary> _loadStats() async {
    if (Firebase.apps.isEmpty) {
      return const _DailyQuizStatsSummary(totalCorrect: 0, totalAnswered: 0);
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _DailyQuizStatsSummary(totalCorrect: 0, totalAnswered: 0);
    }
    final snap = await FirebaseFirestore.instance
        .collection('userQuizStats')
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 6));
    final data = snap.data() ?? const <String, dynamic>{};
    return _DailyQuizStatsSummary(
      totalCorrect: (data['totalCorrect'] as num?)?.toInt() ?? 0,
      totalAnswered: (data['totalAnswered'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DailyQuizStatsSummary>(
      future: _loadStats(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            const _DailyQuizStatsSummary(totalCorrect: 0, totalAnswered: 0);
        return OnboardingSurfaceCard(
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.quiz_rounded, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.quizStatsTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      copy.quizStatsSubtitle(
                        stats.totalCorrect,
                        stats.totalAnswered,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({required this.item, required this.showDivider});

  final _ProfileItemData item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final enabled = item.onTap != null && !item.isBusy;
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
        Material(
          color: Colors.transparent,
          child: ListTile(
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
            trailing: item.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black.withValues(alpha: 0.32),
                    size: 21,
                  ),
            enabled: enabled,
            onTap: enabled ? item.onTap : null,
          ),
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

class _ProfileMoreScreen extends StatefulWidget {
  const _ProfileMoreScreen({
    required this.onShareApp,
    required this.onOpenRegionSelection,
    required this.onOpenReligionSelection,
    required this.onLogout,
    required this.showAdPrivacyChoices,
  });

  final Future<void> Function(_ProfileCopy copy) onShareApp;
  final Future<void> Function(_ProfileCopy copy) onOpenRegionSelection;
  final Future<void> Function(_ProfileCopy copy) onOpenReligionSelection;
  final Future<void> Function(_ProfileCopy copy) onLogout;
  final bool showAdPrivacyChoices;

  @override
  State<_ProfileMoreScreen> createState() => _ProfileMoreScreenState();
}

class _ProfileMoreScreenState extends State<_ProfileMoreScreen> {
  bool _loggingOut = false;

  Future<void> _handleLogout(_ProfileCopy copy) async {
    if (_loggingOut) {
      return;
    }
    setState(() => _loggingOut = true);
    try {
      await widget.onLogout(copy);
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

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

  Future<void> _openReferralRewards(
    BuildContext context,
    _ProfileCopy copy,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ReferralRewardsDialog(copy: copy),
    );
  }

  Future<void> _enableLocationSuggestions(
    BuildContext context,
    _ProfileCopy copy,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(copy.locationTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(copy.locationDialogMessage),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  _openExternalPublicUrl(
                    dialogContext,
                    AppPublicInfo.privacyPolicyUrl,
                  );
                },
                child: Text(copy.privacyPolicyTitle),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(copy.cancelAction),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(copy.allowAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final result = await AppLocationService.instance
        .requestAndSyncApproxLocation();
    if (!context.mounted) {
      return;
    }
    final message = switch (result) {
      AppLocationSyncResult.synced => copy.locationSavedMessage,
      AppLocationSyncResult.serviceDisabled =>
        copy.locationServiceDisabledMessage,
      AppLocationSyncResult.permissionDenied ||
      AppLocationSyncResult.permanentlyDenied =>
        copy.locationPermissionDeniedMessage,
      AppLocationSyncResult.failed => copy.locationFailedMessage,
    };
    ScaffoldMessenger.of(
      context,
    ).showTopSnackBar(AppSnackBar.build(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final copy = _ProfileCopy(context.currentLanguage, context.strings);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(copy.settingsTitle),
      ),
      body: GradientShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: <Widget>[
            OnboardingSurfaceCard(
              child: Column(
                children: <Widget>[
                  Text(
                    copy.settingsTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.quickActionsTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DailyQuizStatsCard(copy: copy),
            const SizedBox(height: 18),
            _SettingsGroup(
              title: copy.quickActionsTitle,
              items: <_ProfileItemData>[
                _ProfileItemData(
                  icon: Icons.ios_share_rounded,
                  title: copy.shareAppTitle,
                  subtitle: copy.shareAppSubtitle,
                  onTap: () => unawaited(widget.onShareApp(copy)),
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
                  icon: Icons.map_rounded,
                  title: copy.stateTitle,
                  subtitle: copy.stateSubtitle,
                  onTap: () => unawaited(widget.onOpenRegionSelection(copy)),
                ),
                _ProfileItemData(
                  icon: Icons.location_on_outlined,
                  title: copy.locationTitle,
                  subtitle: copy.locationSubtitle,
                  onTap: () =>
                      unawaited(_enableLocationSuggestions(context, copy)),
                ),
                _ProfileItemData(
                  icon: Icons.card_membership_rounded,
                  title: copy.subscriptionTitle,
                  subtitle: copy.subscriptionSubtitle,
                  badge: _ProfileItemBadge.premium,
                  onTap: () => unawaited(_openSubscriptionPlan(context)),
                ),
                _ProfileItemData(
                  icon: Icons.emoji_events_rounded,
                  title: copy.quizPrizeDetailsTitle,
                  subtitle: copy.quizPrizeDetailsSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QuizPrizeDetailsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItemData(
                  icon: Icons.receipt_long_rounded,
                  title: copy.purchaseInvoicesTitle,
                  subtitle: copy.purchaseInvoicesSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PurchaseInvoicesScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItemData(
                  icon: Icons.group_add_rounded,
                  title: copy.referralRewardsTitle,
                  subtitle: copy.referralRewardsSubtitle,
                  onTap: () => unawaited(_openReferralRewards(context, copy)),
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
                  onTap: () => _openExternalPublicUrl(
                    context,
                    AppPublicInfo.privacyPolicyUrl,
                  ),
                ),
                if (widget.showAdPrivacyChoices)
                  _ProfileItemData(
                    icon: Icons.ads_click_outlined,
                    title: copy.adPrivacyChoicesTitle,
                    subtitle: copy.adPrivacyChoicesSubtitle,
                    onTap: () {
                      unawaited(
                        AdMobConsentService.instance.showPrivacyOptionsForm(),
                      );
                    },
                  ),
                _ProfileItemData(
                  icon: Icons.gavel_rounded,
                  title: copy.legalNoticesTitle,
                  subtitle: copy.legalNoticesSubtitle,
                  onTap: () => _openExternalPublicUrl(
                    context,
                    AppPublicInfo.legalNoticesUrl,
                  ),
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
                  icon: Icons.flag_outlined,
                  title: copy.reportIssueTitle,
                  subtitle: copy.reportIssueSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => HelpSupportScreen(
                          initialSubject: copy.reportIssueEmailSubject,
                          initialBody: copy.reportIssueEmailBody,
                        ),
                      ),
                    );
                  },
                ),
                _ProfileItemData(
                  icon: Icons.logout_rounded,
                  title: copy.logoutTitle,
                  subtitle: copy.logoutSubtitle,
                  isDestructive: true,
                  isBusy: _loggingOut,
                  onTap: _loggingOut
                      ? null
                      : () => unawaited(_handleLogout(copy)),
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
    await SharePlus.instance.share(
      ShareParams(
        text: _service.buildShareText(status: status, userName: userName),
      ),
    );
  }

  Future<void> _copyCode(ReferralRewardStatus status) async {
    await Clipboard.setData(ClipboardData(text: status.code));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(content: Text(widget.copy.referralCodeCopiedMessage)),
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
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
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
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(widget.copy.referralCodeApplyFailedMessage),
        ),
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: GradientShell(
        padding: EdgeInsets.zero,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: maxDialogContentHeight.clamp(260, 560).toDouble(),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: FutureBuilder<ReferralRewardStatus>(
                future: _statusFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData) {
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(copy.referralLoadFailedMessage),
                      ),
                    );
                  }
                  final status = snapshot.data!;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF14B8A6),
                                Color(0xFF38BDF8),
                                Color(0xFFA78BFA),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          copy.referralRewardsTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          copy.referralProgressText(
                            status.currentCyclePaidCount,
                            status.requiredPaidReferrals,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SelectableText(
                                status.code,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          unawaited(_copyCode(status)),
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 18,
                                      ),
                                      label: Text(copy.copyReferralCodeAction),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          unawaited(_share(status)),
                                      icon: const Icon(
                                        Icons.ios_share_rounded,
                                        size: 18,
                                      ),
                                      label: Text(copy.shareReferralAction),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: copy.applyReferralCodeLabel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: copy.applyReferralCodeAction,
                          loading: _applying,
                          onPressed: () => unawaited(_applyCode()),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => _openExternalPublicUrl(
                            context,
                            AppPublicInfo.termsUrl,
                          ),
                          child: Text(copy.referralTermsAction),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(copy.closeAction),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileItemData {
  const _ProfileItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.isBusy = false,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final bool isBusy;
  final _ProfileItemBadge? badge;
  final VoidCallback? onTap;
}

enum _ProfileItemBadge { googlePlay, premium, bell }

class _ProfileCopy {
  const _ProfileCopy(this.language, this.strings);

  final AppLanguage language;
  final AppStrings strings;

  String _localized({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
  }) {
    return strings.localized(
      telugu: telugu,
      english: english,
      hindi: hindi,
      tamil: tamil,
      kannada: kannada,
      malayalam: malayalam,
    );
  }

  String get quickActionsTitle => _localized(
    telugu: 'త్వరిత ఎంపికలు',
    english: 'Quick actions',
    hindi: 'त्वरित विकल्प',
    tamil: 'விரைவு செயல்கள்',
    kannada: 'ತ್ವರಿತ ಆಯ್ಕೆಗಳು',
    malayalam: 'വേഗത്തിലുള്ള ഓപ്ഷനുകൾ',
  );
  String get supportTitle => strings.supportSection;

  String get quizStatsTitle => _localized(
    telugu:
        '\u0c21\u0c48\u0c32\u0c40 \u0c15\u0c4d\u0c35\u0c3f\u0c1c\u0c4d \u0c38\u0c4d\u0c1f\u0c3e\u0c1f\u0c4d\u0c38\u0c4d',
    english: 'Daily Quiz Stats',
  );
  String quizStatsSubtitle(int correct, int total) => _localized(
    telugu:
        '$correct/$total \u0c38\u0c30\u0c48\u0c28 \u0c38\u0c2e\u0c3e\u0c27\u0c3e\u0c28\u0c3e\u0c32\u0c41',
    english: '$correct/$total correct answers',
  );

  String get posterProfileTitle => _localized(
    telugu: 'వ్యక్తిగత & బిజినెస్ వివరాలు',
    english: 'Personal & Business Details',
  );
  String get posterProfileSubtitle => _localized(
    telugu: 'ఫోటో, పేరు, బిజినెస్ వివరాలు అప్‌డేట్ చేయండి',
    english: 'Update photo, personal, and business details',
  );
  String get moreTitle => _localized(telugu: 'మరిన్ని', english: 'More');
  String get moreSubtitle =>
      _localized(telugu: 'మిగతా అన్ని ఆప్షన్లు', english: 'Remaining options');
  String get settingsTitle => strings.appSettingsSection;
  String get religionTitle =>
      _localized(telugu: 'మతం మార్చండి', english: 'Change religion');
  String get religionSubtitle => _localized(
    telugu: 'హోమ్‌లో కనిపించే కేటగిరీలను మార్చండి',
    english: 'Update which categories appear in home',
  );
  String get religionSavedHinduMessage => _localized(
    telugu: 'హిందూ ఎంపిక సేవ్ అయింది',
    english: 'Hindu preference saved',
  );
  String get religionSavedMuslimMessage => _localized(
    telugu: 'ముస్లిం ఎంపిక సేవ్ అయింది',
    english: 'Muslim preference saved',
  );
  String get religionSavedChristianMessage => _localized(
    telugu: 'క్రిస్టియన్ ఎంపిక సేవ్ అయింది',
    english: 'Christian preference saved',
  );
  String get religionSavedAllMessage => _localized(
    telugu: 'అన్ని కేటగిరీల ఎంపిక సేవ్ అయింది',
    english: 'All categories preference saved',
  );

  String get languageTitle => strings.languageOption;
  String? get languageSubtitle => strings.languageOptionSubtitle;
  String get stateTitle => _localized(
    telugu: 'రాష్ట్రం / కేంద్ర పాలిత ప్రాంతం మార్చండి',
    english: 'Change State / UT',
    hindi: 'राज्य / केंद्र शासित प्रदेश बदलें',
    tamil: 'மாநிலம் / யூனியன் பிரதேசம் மாற்றவும்',
    kannada: 'ರಾಜ್ಯ / ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶ ಬದಲಿಸಿ',
    malayalam: 'സംസ്ഥാനം / കേന്ദ്രഭരണ പ്രദേശം മാറ്റുക',
  );
  String get stateSubtitle => _localized(
    telugu: 'యాప్ భాష మరియు రాష్ట్ర కేటగిరీలు అప్డేట్ అవుతాయి',
    english: 'Update app language and state categories',
    hindi: 'ऐप भाषा और राज्य कैटेगरी अपडेट करें',
    tamil: 'ஆப் மொழி மற்றும் மாநில வகைகளை புதுப்பிக்கவும்',
    kannada: 'ಆಪ್ ಭಾಷೆ ಮತ್ತು ರಾಜ್ಯ ವಿಭಾಗಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಿ',
    malayalam: 'ആപ്പ് ഭാഷയും സംസ്ഥാന വിഭാഗങ്ങളും അപ്ഡേറ്റ് ചെയ്യുക',
  );
  String get stateSavedMessage => _localized(
    telugu: 'రాష్ట్రం అప్‌డేట్ అయింది. రాజకీయ పార్టీలను మళ్లీ ఎంచుకోండి',
    english: 'State updated. Please review political parties',
  );
  String get politicalPartyTitle => _localized(
    telugu: 'రాజకీయ పార్టీలు',
    english: 'Political parties',
    hindi: 'राजनीतिक पार्टियां',
    tamil: 'அரசியல் கட்சிகள்',
    kannada: 'ರಾಜಕೀಯ ಪಕ್ಷಗಳು',
    malayalam: 'രാഷ്ട്രീയ പാർട്ടികൾ',
  );
  String get politicalPartySubtitle => _localized(
    telugu: 'హోమ్‌లో కనిపించే పార్టీ కేటగిరీలను మార్చండి',
    english: 'Update political party categories shown in home',
    hindi: 'होम में दिखने वाली पार्टी कैटेगरी अपडेट करें',
    tamil: 'ஹோமில் காணப்படும் கட்சி வகைகளை புதுப்பிக்கவும்',
    kannada: 'ಹೋಮ್‌ನಲ್ಲಿ ಕಾಣುವ ಪಕ್ಷ ವಿಭಾಗಗಳನ್ನು ಅಪ್ಡೇಟ್ ಮಾಡಿ',
    malayalam: 'ഹോമിൽ കാണുന്ന പാർട്ടി വിഭാഗങ്ങൾ അപ്ഡേറ്റ് ചെയ്യുക',
  );
  String get politicalPartySavedMessage => _localized(
    telugu: 'రాజకీయ పార్టీలు అప్‌డేట్ అయ్యాయి',
    english: 'Political parties updated',
  );
  String get locationTitle => _localized(
    telugu: 'లొకేషన్ ఆధారిత స్టేటస్',
    english: 'Location-based status',
  );
  String get locationSubtitle => _localized(
    telugu: 'మీ city/district ఆధారంగా దగ్గరలోని స్టేటస్‌లకు ప్రాధాన్యం ఇవ్వండి',
    english: 'Prioritize nearby city/district statuses',
  );
  String get locationDialogMessage => _localized(
    telugu: 'దగ్గరలోని స్టేటస్‌ల కోసం లొకేషన్ అనుమతి ఇవ్వండి.',
    english: 'Allow location to show nearby statuses.',
  );
  String get locationSavedMessage => _localized(
    telugu: 'లొకేషన్ స్టేటస్ సూచనలు ఆన్ అయ్యాయి',
    english: 'Location-based status suggestions enabled',
  );
  String get locationPermissionDeniedMessage => _localized(
    telugu: 'లొకేషన్ అనుమతి ఇవ్వలేదు. Settings నుంచి తర్వాత ఆన్ చేయవచ్చు.',
    english:
        'Location permission was not allowed. You can enable it later from settings.',
  );
  String get locationServiceDisabledMessage => _localized(
    telugu: 'ఈ ఫోన్‌లో లొకేషన్ సర్వీస్ ఆఫ్‌లో ఉంది.',
    english: 'Location service is turned off on this phone.',
  );
  String get locationFailedMessage => _localized(
    telugu: 'లొకేషన్ అప్‌డేట్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
    english: 'Location could not be updated. Please try again.',
  );
  String get cancelAction => _localized(telugu: 'వద్దు', english: 'Cancel');
  String get allowAction =>
      _localized(telugu: 'Allow చేయండి', english: 'Allow');

  String get subscriptionTitle => strings.subscriptionOption;
  String get subscriptionSubtitle => _localized(
    telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్ చూడండి',
    english: 'View plan details',
    hindi: 'प्लान विवरण देखें',
    tamil: 'பிளான் விவரங்களை பார்க்கவும்',
    kannada: 'ಪ್ಲಾನ್ ವಿವರಗಳನ್ನು ನೋಡಿ',
    malayalam: 'പ്ലാൻ വിവരങ്ങൾ കാണുക',
  );
  String get quizPrizeDetailsTitle =>
      _localized(telugu: 'Quiz Prize Details', english: 'Quiz Prize Details');
  String get quizPrizeDetailsSubtitle => _localized(
    telugu: 'Winners verification కోసం WhatsApp మరియు bank details',
    english: 'WhatsApp and bank details for winner verification',
  );
  String get purchaseInvoicesTitle => _localized(
    telugu: 'కొనుగోలు ఇన్వాయిసులు',
    english: 'Purchase invoices',
    hindi: 'खरीद इनवॉइस',
    tamil: 'வாங்கிய ரசீதுகள்',
    kannada: 'ಖರೀದಿ ಇನ್ವಾಯ್ಸ್',
    malayalam: 'വാങ്ങൽ ഇൻവോയിസുകൾ',
  );
  String get purchaseInvoicesSubtitle => _localized(
    telugu: 'కొనుగోలు వివరాలు చూడండి',
    english: 'View purchase details',
    hindi: 'खरीद विवरण देखें',
    tamil: 'வாங்கிய விவரங்களை பார்க்கவும்',
    kannada: 'ಖರೀದಿ ವಿವರಗಳನ್ನು ನೋಡಿ',
    malayalam: 'വാങ്ങൽ വിവരങ്ങൾ കാണുക',
  );
  String get referralRewardsTitle =>
      _localized(telugu: 'రిఫరల్ బహుమతులు', english: 'Referral rewards');
  String get referralRewardsSubtitle => _localized(
    telugu: 'రిఫరల్ కోడ్ మరియు ప్రస్తుత చక్రం చూడండి',
    english: 'View referral code and current cycle',
  );
  String referralProgressText(int current, int required) {
    return _localized(
      telugu: 'ప్రస్తుత చక్రం: $current / $required',
      english: 'Current cycle: $current / $required',
    );
  }

  String get copyReferralCodeAction =>
      _localized(telugu: 'కోడ్ కాపీ', english: 'Copy code');
  String get shareReferralAction =>
      _localized(telugu: 'షేర్', english: 'Share');
  String get referralTermsAction => _localized(
    telugu: 'నిబంధనలు మరియు షరతులు చూడండి',
    english: 'View Terms & Conditions',
  );
  String get applyReferralCodeLabel => _localized(
    telugu: 'రిఫరల్ కోడ్ నమోదు చేయండి',
    english: 'Enter referral code',
  );
  String get applyReferralCodeAction =>
      _localized(telugu: 'అప్లై', english: 'Apply');
  String get referralCodeCopiedMessage => _localized(
    telugu: 'రిఫరల్ కోడ్ కాపీ అయింది',
    english: 'Referral code copied',
  );
  String get referralCodeAppliedMessage => _localized(
    telugu: 'రిఫరల్ కోడ్ అప్లై అయింది',
    english: 'Referral code applied',
  );
  String get referralCodeAlreadyAppliedMessage => _localized(
    telugu: 'రిఫరల్ ఇప్పటికే అప్లై అయింది',
    english: 'Referral already applied',
  );
  String get referralCodeApplyFailedMessage => _localized(
    telugu: 'రిఫరల్ కోడ్ అప్లై కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
    english: 'Referral code apply failed. Please try again.',
  );
  String get referralLoadFailedMessage => _localized(
    telugu: 'రిఫరల్ వివరాలు లోడ్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
    english: 'Referral details could not load. Please try again.',
  );
  String get closeAction => _localized(telugu: 'మూసివేయండి', english: 'Close');
  String get restoreSubscriptionTitle => _localized(
    telugu: 'సబ్‌స్క్రిప్షన్ రీస్టోర్ చేయండి',
    english: 'Restore subscriptions',
  );
  String get restoreSubscriptionSubtitle => _localized(
    telugu: 'ఈ అకౌంట్ కొనుగోళ్లను మళ్లీ తెచ్చుకోండి',
    english: 'Restore purchases for this account',
  );

  String get permissionsTitle => strings.permissionsTitle;
  String? get permissionsSubtitle => strings.permissionsOptionSubtitle;

  String get notificationsTitle => strings.notifications;
  String? get notificationsSubtitle => strings.notificationsOptionSubtitle;

  String get shareAppTitle => _localized(
    telugu: 'యాప్ షేర్ చేయండి',
    english: 'Share App',
    hindi: 'ऐप शेयर करें',
    tamil: 'ஆப்பை பகிரவும்',
    kannada: 'ಆಪ್ ಹಂಚಿಕೊಳ್ಳಿ',
    malayalam: 'ആപ്പ് പങ്കിടുക',
  );
  String get shareAppSubtitle => _localized(
    telugu: 'యాప్ ఐకాన్, ప్లే స్టోర్ లింక్‌ను పంచుకోండి',
    english: 'Share the app icon and Play Store link',
    hindi: 'ऐप आइकन और Play Store लिंक शेयर करें',
    tamil: 'ஆப் ஐகான் மற்றும் Play Store இணைப்பை பகிரவும்',
    kannada: 'ಆಪ್ ಐಕಾನ್ ಮತ್ತು Play Store ಲಿಂಕ್ ಹಂಚಿಕೊಳ್ಳಿ',
    malayalam: 'ആപ്പ് ഐകണും Play Store ലിങ്കും പങ്കിടുക',
  );
  String get shareAppFailedMessage => _localized(
    telugu: 'యాప్ షేర్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
    english: 'App share failed. Please try again.',
  );
  String get accountEmailFallback => _localized(
    telugu: 'ఈ అకౌంట్‌కు ఇమెయిల్ అందుబాటులో లేదు',
    english: 'Email not available for this account',
  );

  String get helpTitle => strings.helpSupport;
  String? get helpSubtitle => strings.helpSupportSubtitle;
  String get reportIssueTitle => _localized(
    telugu: 'పోస్టర్ లేదా సమస్యను రిపోర్ట్ చేయండి',
    english: 'Report a poster or issue',
  );
  String get reportIssueSubtitle => _localized(
    telugu: 'అనుచిత పోస్టర్ లేదా యాప్ సమస్యను సపోర్ట్‌కు పంపండి',
    english: 'Send an inappropriate poster or app issue report to support',
  );
  String get reportIssueEmailSubject => 'Mana Poster Ai Poster Report';
  String get reportIssueEmailBody => _localized(
    telugu: '''నమస్కారం Mana Poster Ai టీమ్,

నేను ఒక పోస్టర్ లేదా యాప్ సమస్యను రిపోర్ట్ చేయాలనుకుంటున్నాను.

వివరాలు:
- సమస్య రకం:
- పోస్టర్ పేరు లేదా కేటగిరీ:
- Creator ID (తెలిస్తే):
- ఏమి సమస్యగా అనిపించింది:
''',
    english: '''Hello Mana Poster Ai team,

I want to report a poster or app issue.

Details:
- Issue type:
- Poster title or category:
- Creator ID (if known):
- What seems to be the problem:
''',
  );

  String get aboutTitle => strings.aboutApp;
  String get aboutSubtitle => strings.aboutAppSubtitle;
  String get logoutTitle => strings.logout;
  String get logoutSubtitle => strings.logoutSubtitle;
  String get logoutFailedMessage => _localized(
    telugu: 'లాగ్ అవుట్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
    english: 'Logout failed. Please try again.',
  );
  String get deleteAccountTitle =>
      _localized(telugu: 'అకౌంట్ డిలీట్', english: 'Delete account');
  String get deleteAccountSubtitle => _localized(
    telugu: 'మీ అకౌంట్ మరియు డేటా తొలగింపు రిక్వెస్ట్ ప్రారంభించండి',
    english: 'Start your account and data removal request',
  );
  String get privacyPolicyTitle =>
      _localized(telugu: 'ప్రైవసీ పాలసీ', english: 'Privacy Policy');
  String get privacyPolicySubtitle => _localized(
    telugu: 'డేటా వినియోగం మరియు ప్రైవసీ',
    english: 'Data usage and privacy',
  );
  String get adPrivacyChoicesTitle =>
      _localized(telugu: 'యాడ్ ప్రైవసీ ఎంపికలు', english: 'Ad privacy choices');
  String get adPrivacyChoicesSubtitle => _localized(
    telugu: 'పర్సనలైజ్డ్ యాడ్స్ సెట్టింగ్స్ మార్చండి',
    english: 'Manage personalized ad settings',
  );
  String get legalNoticesTitle => _localized(
    telugu: 'నిబంధనలు మరియు షరతులు',
    english: 'Terms & Conditions',
  );
  String get legalNoticesSubtitle => _localized(
    telugu: 'యాప్ వాడకం మరియు సభ్యత్వ నియమాలు',
    english: 'Usage and subscription terms',
  );
}
