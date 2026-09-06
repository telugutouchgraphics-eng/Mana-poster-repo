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
import 'package:mana_poster/features/prehome/screens/region_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/religion_selection_screen.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/onboarding_surface_card.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';
import 'package:mana_poster/features/prehome/widgets/subscription_exit_video_prompt.dart';
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
          hindi: 'लिंक नहीं खुल सका। कृपया पुन: प्रयास करें।',
          tamil: 'இணைப்பைத் திறக்க முடியவில்லை. மீண்டும் முயல்க.',
          kannada: 'ಲಿಂಕ್ ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'ലിങ്ക് തുറക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'लिंक उघडता आली नाही. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'લિંક ખોલી શકાઈ નથી. ફરી પ્રયાસ કરો.',
          bengali: 'লিঙ্ক খোলা যায়নি। আবার চেষ্টা করুন।',
          punjabi: 'ਲਿੰਕ ਨਹੀਂ ਖੁੱਲ੍ਹ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଲିଙ୍କ୍ ଖୋଲିପାରିଲା ନାହିଁ। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'লিংক খোল খাব নোৱাৰিলে। পুনৰ চেষ্টা কৰক।',
          konkani: 'लिंक उकती जाली ना. उपकार करून परत प्रयत्न करात.',
          nepali: 'लिङ्क खोल्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'Link hangdokpa ngamde. Amuk hanna hotnabiyu.',
          mizo: 'Link hawng thei lo. Khawngaihin ti nawn leh rawh.',
          kashmiri: 'لِنک نہ کھٔلِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
          ladakhi: 'Link ཁ་འབྱེད་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
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

  Future<void> _openLogin() async {
    await Navigator.of(context).pushNamed(AppRoutes.login);
    if (!mounted) {
      return;
    }
    setState(() {});
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
    final currentUser = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final accountLabel = currentUser?.email?.trim().isNotEmpty == true
        ? currentUser!.email!.trim()
        : currentUser?.phoneNumber?.trim() ??
              context.strings.localized(
                telugu: 'గెస్ట్ మోడ్',
                english: 'Guest mode',
                hindi: 'गेस्ट मोड',
                tamil: 'விருந்தினர் முறை',
                kannada: 'ಅತಿಥಿ ಮೋಡ್',
                malayalam: 'ഗസ്റ്റ് മോഡ്',
                marathi: 'गेस्ट मोड',
                gujarati: 'ગેસ્ટ મોડ',
                bengali: 'গেস্ট মোড',
                punjabi: 'ਗੈਸਟ ਮੋਡ',
                odia: 'ଗେଷ୍ଟ ମୋଡ୍',
                assamese: 'অতিথি ম’ড',
                konkani: 'गेस्ट मोड',
                nepali: 'अतिथि मोड',
                meitei: 'Guest mode',
                mizo: 'Guest mode',
                kashmiri: 'گیسٹ موڈ',
                ladakhi: 'མགྱོན་པོའི་རྣམ་པ།',
              );
    final isAuthenticated = currentUser != null;

    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return PopScope<PosterProfileData>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_posterProfile);
      },
      child: PosterProfileDetailsScreen(
        initialProfile: _posterProfile,
        accountEmail: accountLabel,
        accountSubtitle: _selectedRegionName,
        embeddedInProfileScreen: true,
        onSaved: (profile) {
          setState(() => _posterProfile = profile);
          _warmPosterProfileImage(profile);
        },
        appBarActions: <Widget>[
          if (!isAuthenticated)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: context.strings.localized(
                telugu: 'లాగిన్ చేయండి',
                english: 'Login',
                hindi: 'लॉगिन करें',
                tamil: 'உள்நுழைக',
                kannada: 'ಲಾಗಿನ್ ಮಾಡಿ',
                malayalam: 'ലോഗിൻ ചെയ്യുക',
                marathi: 'लॉगिन करा',
                gujarati: 'લૉગિન કરો',
                bengali: 'লগইন করুন',
                punjabi: 'ਲੌਗਇਨ ਕਰੋ',
                odia: 'ଲଗଇନ୍ କରନ୍ତୁ',
                assamese: 'লগইন কৰক',
                konkani: 'लॉगिन करात',
                nepali: 'लगइन गर्नुहोस्',
                meitei: 'Login toubiyu',
                mizo: 'Login rawh',
                kashmiri: 'لاگ اِن کٔریو',
                ladakhi: 'Login བྱོས།',
              ),
              icon: const Icon(
                Icons.login_rounded,
                size: 22,
                color: Color(0xFF0F172A),
              ),
              onPressed: () => unawaited(_openLogin()),
            ),
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
      ),
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

  @override
  Widget build(BuildContext context) {
    final copy = _ProfileCopy(context.currentLanguage, context.strings);
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;

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
                if (!isAuthenticated)
                  _ProfileItemData(
                    icon: Icons.login_rounded,
                    title: context.strings.localized(
                      telugu: 'లాగిన్ చేయండి',
                      english: 'Login',
                      hindi: 'लॉगिन करें',
                      tamil: 'உள்நுழைக',
                      kannada: 'ಲಾಗಿನ್ ಮಾಡಿ',
                      malayalam: 'ലോഗിൻ ചെയ്യുക',
                      marathi: 'लॉगिन करा',
                      gujarati: 'લૉગિન કરો',
                      bengali: 'লগইন করুন',
                      punjabi: 'ਲੌਗਇਨ ਕਰੋ',
                      odia: 'ଲଗଇନ୍ କରନ୍ତୁ',
                      assamese: 'লগইন কৰক',
                      konkani: 'लॉगिन करात',
                      nepali: 'लगइन गर्नुहोस्',
                      meitei: 'Login toubiyu',
                      mizo: 'Login rawh',
                      kashmiri: 'لاگ اِن کٔریو',
                      ladakhi: 'Login བྱོས།',
                    ),
                    subtitle: context.strings.localized(
                      telugu: 'పూర్తి ఫీచర్లు ఉపయోగించడానికి లాగిన్ చేయండి',
                      english: 'Login to use all features',
                      hindi: 'सभी सुविधाओं का उपयोग करने के लिए लॉगिन करें',
                      tamil: 'அனைத்து அம்சங்களையும் பயன்படுத்த உள்நுழைக',
                      kannada: 'ಎಲ್ಲಾ ವೈಶಿಷ್ಟ್ಯಗಳನ್ನು ಬಳಸಲು ಲಾಗಿನ್ ಮಾಡಿ',
                      malayalam: 'എല്ലാ സവിശേഷതകളും ഉപയോഗിക്കാൻ ലോഗിൻ ചെയ്യുക',
                      marathi: 'सर्व वैशिष्ट्ये वापरण्यासाठी लॉगिन करा',
                      gujarati: 'બધી સુવિધાઓ વાપરવા માટે લૉગિન કરો',
                      bengali: 'সমস্ত বৈশিষ্ট্য ব্যবহার করতে লগইন করুন',
                      punjabi: 'ਸਾਰੀਆਂ ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ ਵਰਤਣ ਲਈ ਲੌਗਇਨ ਕਰੋ',
                      odia: 'ସମସ୍ତ ସୁବିଧା ବ୍ୟବହାର କରିବାକୁ ଲଗଇନ୍ କରନ୍ତୁ',
                      assamese: 'সকলো সুবিধা ব্যৱহাৰ কৰিবলৈ লগইন কৰক',
                      konkani: 'सगळीं वैशिश्ट्यां वापरपा खातीर लॉगिन करात',
                      nepali: 'सबै सुविधाहरू प्रयोग गर्न लगइन गर्नुहोस्',
                      meitei: 'Khudingmak sijinaba yabagi login toubiyu',
                      mizo: 'Feature zawng zawng hmang turin login rawh',
                      kashmiri: 'سٲری فیچرز اِستعمال کرنہٕ باپتھ کٔریو لاگ اِن',
                      ladakhi: 'ཁྱད་ཆོས་ཚང་མ་བཀོལ་སྤྱོད་ཆེད་དུ་ login བྱོས།',
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.login);
                    },
                  ),
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
                  icon: Icons.card_membership_rounded,
                  title: copy.subscriptionTitle,
                  subtitle: copy.subscriptionSubtitle,
                  badge: _ProfileItemBadge.premium,
                  onTap: () => unawaited(_openSubscriptionPlan(context)),
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

  static const Map<String, String> _cleanTeluguOverrides = <String, String>{
    'Quick actions': 'త్వరిత ఎంపికలు',
    'Daily Quiz Stats': 'రోజువారీ క్విజ్ స్టాట్స్',
    'Personal & Business Details': 'వ్యక్తిగత & బిజినెస్ వివరాలు',
    'Update photo, personal, and business details':
        'ఫోటో, వ్యక్తిగత, బిజినెస్ వివరాలు అప్డేట్ చేయండి',
    'More': 'మరిన్ని',
    'Remaining options': 'మిగతా ఎంపికలు',
    'Change religion': 'మతం మార్చండి',
    'Update which categories appear in home':
        'హోమ్‌లో కనిపించే కేటగిరీలను మార్చండి',
    'Hindu preference saved': 'హిందూ ఎంపిక సేవ్ అయింది',
    'Muslim preference saved': 'ముస్లిం ఎంపిక సేవ్ అయింది',
    'Christian preference saved': 'క్రిస్టియన్ ఎంపిక సేవ్ అయింది',
    'All categories preference saved': 'అన్ని కేటగిరీల ఎంపిక సేవ్ అయింది',
    'Change State / UT': 'రాష్ట్రం / కేంద్ర పాలిత ప్రాంతం మార్చండి',
    'Update app language and state categories':
        'యాప్ భాష మరియు రాష్ట్ర కేటగిరీలను అప్డేట్ చేయండి',
    'State updated. Please review political parties':
        'రాష్ట్రం అప్డేట్ అయింది. దయచేసి రాజకీయ పార్టీలను చూసుకోండి',
    'Political parties': 'రాజకీయ పార్టీలు',
    'Update political party categories shown in home':
        'హోమ్‌లో కనిపించే రాజకీయ పార్టీ కేటగిరీలను అప్డేట్ చేయండి',
    'Political parties updated': 'రాజకీయ పార్టీలు అప్డేట్ అయ్యాయి',
    'View plan details': 'ప్లాన్ వివరాలు చూడండి',
    'Purchase invoices': 'కొనుగోలు ఇన్వాయిసులు',
    'View purchase details': 'కొనుగోలు వివరాలు చూడండి',
    'Referral rewards': 'రెఫరల్ రివార్డులు',
    'View referral code and current cycle':
        'రెఫరల్ కోడ్ మరియు ప్రస్తుత సైకిల్ చూడండి',
    'Copy code': 'కోడ్ కాపీ',
    'Share': 'షేర్',
    'View Terms & Conditions': 'నిబంధనలు & షరతులు చూడండి',
    'Enter referral code': 'రెఫరల్ కోడ్ నమోదు చేయండి',
    'Apply': 'అప్లై',
    'Referral code copied': 'రెఫరల్ కోడ్ కాపీ అయింది',
    'Referral code applied': 'రెఫరల్ కోడ్ అప్లై అయింది',
    'Referral already applied': 'రెఫరల్ ఇప్పటికే అప్లై అయింది',
    'Referral code apply failed. Please try again.':
        'రెఫరల్ కోడ్ అప్లై కాలేదు. మళ్లీ ప్రయత్నించండి.',
    'Referral details could not load. Please try again.':
        'రెఫరల్ వివరాలు లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    'Close': 'మూసివేయి',
    'Restore subscriptions': 'సబ్‌స్క్రిప్షన్‌లను రీస్టోర్ చేయండి',
    'Restore purchases for this account': 'ఈ ఖాతా కొనుగోళ్లను రీస్టోర్ చేయండి',
    'Share App': 'యాప్ షేర్ చేయండి',
    'Share the app icon and Play Store link':
        'యాప్ ఐకాన్ మరియు Play Store లింక్ షేర్ చేయండి',
    'App share failed. Please try again.':
        'యాప్ షేర్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    'Email not available for this account': 'ఈ ఖాతాకు ఇమెయిల్ అందుబాటులో లేదు',
    'Report a poster or issue': 'పోస్టర్ లేదా సమస్యను రిపోర్ట్ చేయండి',
    'Send an inappropriate poster or app issue report to support':
        'తగని పోస్టర్ లేదా యాప్ సమస్యను సపోర్ట్‌కి పంపండి',
    'Logout failed. Please try again.': 'లాగౌట్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    'Delete account': 'ఖాతా తొలగించండి',
    'Start your account and data removal request':
        'ఖాతా మరియు డేటా తొలగింపు అభ్యర్థన ప్రారంభించండి',
    'Privacy Policy': 'ప్రైవసీ పాలసీ',
    'Data usage and privacy': 'డేటా వినియోగం మరియు ప్రైవసీ',
    'Ad privacy choices': 'ప్రకటనల ప్రైవసీ ఎంపికలు',
    'Manage personalized ad settings':
        'పర్సనలైజ్డ్ యాడ్ సెట్టింగ్స్ నిర్వహించండి',
    'Terms & Conditions': 'నిబంధనలు & షరతులు',
    'Usage and subscription terms': 'వినియోగం మరియు సబ్‌స్క్రిప్షన్ నిబంధనలు',
  };

  String _localized({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
    String? assamese,
    String? konkani,
    String? gujarati,
    String? marathi,
    String? meitei,
    String? mizo,
    String? odia,
    String? punjabi,
    String? nepali,
    String? bengali,
    String? kashmiri,
    String? ladakhi,
  }) {
    if (language.supportedUiLanguage == SupportedUiLanguage.telugu) {
      final cleanTelugu = _cleanTeluguOverrides[english];
      if (cleanTelugu != null) {
        return cleanTelugu;
      }
    }
    return strings.localized(
      telugu: telugu,
      english: english,
      hindi: hindi,
      tamil: tamil,
      kannada: kannada,
      malayalam: malayalam,
      assamese: assamese,
      konkani: konkani,
      gujarati: gujarati,
      marathi: marathi,
      meitei: meitei,
      mizo: mizo,
      odia: odia,
      punjabi: punjabi,
      nepali: nepali,
      bengali: bengali,
      kashmiri: kashmiri,
      ladakhi: ladakhi,
    );
  }

  String get quickActionsTitle => _localized(
    telugu: 'త్వరిత ఎంపికలు',
    english: 'Quick actions',
    hindi: 'त्वरित विकल्प',
    tamil: 'விரைவு செயல்கள்',
    kannada: 'ತ್ವರಿತ ಆಯ್ಕೆಗಳು',
    malayalam: 'വേഗത്തിലുള്ള ഓപ്ഷനുകൾ',
    marathi: 'जलद पर्याय',
    gujarati: 'ઝડપી વિકલ્પો',
    bengali: 'দ্রুত বিকল্প',
    punjabi: 'ਤੁਰੰਤ ਵਿਕਲਪ',
    odia: 'ତ୍ୱରିତ ବିକଳ୍ପ',
    assamese: 'দ্ৰুত বিকল্প',
    konkani: 'रोखडे पर्याय',
    nepali: 'द्रुत विकल्पहरू',
    meitei: 'Thuna touba yaba option',
    mizo: 'Thil tih zung zungna',
    kashmiri: 'جلدی آپشن',
    ladakhi: 'མགྱོགས་མྱུར་བྱ་བ།',
  );
  String get supportTitle => strings.supportSection;

  String get quizStatsTitle => _localized(
    telugu: 'రోజువారీ క్విజ్ స్టాట్స్',
    english: 'Daily Quiz Stats',
    hindi: 'दैनिक क्विज़ आंकड़े',
    tamil: 'தினசரி வினாடி வினா புள்ளிவிவரங்கள்',
    kannada: 'ದೈನಂದಿನ ರಸಪ್ರಶ್ನೆ ಅಂಕಿಅಂಶಗಳು',
    malayalam: 'പ്രതിദിന ക്വിസ് സ്ഥിതിവിവരക്കണക്കുകൾ',
    marathi: 'दैनिक क्विझ आकडेवारी',
    gujarati: 'દૈનિક ક્વિઝ આંકડા',
    bengali: 'দৈনিক কুইজ পরিসংখ্যান',
    punjabi: 'ਰੋਜ਼ਾਨਾ ਕਵਿਜ਼ ਅੰਕੜੇ',
    odia: 'ଦୈନିକ କ୍ୱିଜ୍ ପରିସଂଖ୍ୟାନ',
    assamese: 'দৈনিক কুইজ পৰিসংখ্যা',
    konkani: 'दिसावडें क्विझ आंकडेवारी',
    nepali: 'दैनिक क्विज तथ्याङ्क',
    meitei: 'Daily quiz stats',
    mizo: 'Ni tin quiz dinhmun',
    kashmiri: 'روزانہ کوئز شماریات',
    ladakhi: 'ཉིན་རེའི་ quiz གྲངས་ཐོ།',
  );
  String quizStatsSubtitle(int correct, int total) => _localized(
    telugu: '$correct/$total సరైన సమాధానాలు',
    english: '$correct/$total correct answers',
    hindi: '$correct/$total सही उत्तर',
    tamil: '$correct/$total சரியான பதில்கள்',
    kannada: '$correct/$total ಸರಿಯಾದ ಉತ್ತರಗಳು',
    malayalam: '$correct/$total ശരിയായ ഉത്തരങ്ങൾ',
    marathi: '$correct/$total अचूक उत्तरे',
    gujarati: '$correct/$total સાચા જવાબો',
    bengali: '$correct/$total সঠিক উত্তর',
    punjabi: '$correct/$total ਸਹੀ ਉੱਤਰ',
    odia: '$correct/$total ସଠିକ୍ ଉତ୍ତର',
    assamese: '$correct/$total শুদ্ধ উত্তৰ',
    konkani: '$correct/$total सारक्यो जापो',
    nepali: '$correct/$total सही उत्तरहरू',
    meitei: '$correct/$total achumba paokhum',
    mizo: '$correct/$total chhanna dik',
    kashmiri: '$correct/$total صحیح جواب',
    ladakhi: '$correct/$total ལན་ཡང་དག',
  );

  String get posterProfileTitle => _localized(
    telugu: 'వ్యక్తిగత & బిజినెస్ వివరాలు',
    english: 'Personal & Business Details',
    hindi: 'व्यक्तिगत और व्यावसायिक विवरण',
    tamil: 'தனிப்பட்ட மற்றும் வணிக விவரங்கள்',
    kannada: 'ವೈಯಕ್ತಿಕ ಮತ್ತು ವ್ಯಾಪಾರ ವಿವರಗಳು',
    malayalam: 'വ്യക്തിഗത, ബിസിനസ്സ് വിശദാംശങ്ങൾ',
    marathi: 'वैयक्तिक आणि व्यवसाय तपशील',
    gujarati: 'વ્યક્તિગત અને વ્યવસાયિક વિગતો',
    bengali: 'ব্যক্তিগত এবং ব্যবসায়িক বিবরণ',
    punjabi: 'ਨਿੱਜੀ ਅਤੇ ਕਾਰੋਬਾਰੀ ਵੇਰਵੇ',
    odia: 'ବ୍ୟକ୍ତିଗତ ଏବଂ ବ୍ୟବସାୟିକ ବିବରଣୀ',
    assamese: 'ব্যক্তিগত আৰু ব্যৱসায়িক বিৱৰণ',
    konkani: 'खाजगी आनी वेवसायिक तपशील',
    nepali: 'व्यक्तिगत र व्यापार विवरणहरू',
    meitei: 'Mee-ot amasung Business details',
    mizo: 'Mahni leh sumdawnna chanchin',
    kashmiri: 'ذاتی تہٕ کاروباری تفصیلات',
    ladakhi: 'སྒེར་དང་ཚོང་ལས་ཀྱི་ཞིབ་ཕྲ།',
  );
  String get posterProfileSubtitle => _localized(
    telugu: 'ఫోటో, వ్యక్తిగత, బిజినెస్ వివరాలు అప్డేట్ చేయండి',
    english: 'Update photo, personal, and business details',
    hindi: 'फोटो, व्यक्तिगत और व्यावसायिक विवरण अपडेट करें',
    tamil: 'புகைப்படம், தனிப்பட்ட மற்றும் வணிக விவரங்களைப் புதுப்பிக்கவும்',
    kannada: 'ಫೋಟೋ, ವೈಯಕ್ತಿಕ ಮತ್ತು ವ್ಯಾಪಾರ ವಿವರಗಳನ್ನು ನವೀಕರಿಸಿ',
    malayalam: 'ഫോട്ടോ, വ്യക്തിഗത, ബിസിനസ്സ് വിവരങ്ങൾ അപ്ഡേറ്റ് ചെയ്യുക',
    marathi: 'फोटो, वैयक्तिक आणि व्यवसाय तपशील अपडेट करा',
    gujarati: 'ફોટો, વ્યક્તિગત અને વ્યવસાયિક વિગતો અપડેટ કરો',
    bengali: 'ছবি, ব্যক্তিগত এবং ব্যবসায়িক বিবরণ আপডেট করুন',
    punjabi: 'ਫੋਟੋ, ਨਿੱਜੀ ਅਤੇ ਕਾਰੋਬਾਰੀ ਵੇਰਵੇ ਅੱਪਡੇਟ ਕਰੋ',
    odia: 'ଫଟୋ, ବ୍ୟକ୍ତିଗତ ଏବଂ ବ୍ୟବସାୟ ବିବରଣୀ ଅଦ୍ୟତନ କରନ୍ତୁ',
    assamese: 'ফটো, ব্যক্তিগত আৰু ব্যৱসায়িক বিৱৰণ আপডেট কৰক',
    konkani: 'फोटो, खाजगी आनी वेवसायिक तपशील अपडेट करात',
    nepali: 'फोटो, व्यक्तिगत र व्यापार विवरणहरू अपडेट गर्नुहोस्',
    meitei: 'Photo, mee-ot amasung business details update toubiyu',
    mizo: 'Thlalak, mahni leh sumdawnna chanchin tidanglam rawh',
    kashmiri: 'فوٹو، ذاتی تہٕ کاروباری تفصیلات کٔریو اپ ڈیٹ',
    ladakhi: 'པར་དང་སྒེར། ཚོང་ལས་ཀྱི་ཞིབ་ཕྲ་གསར་སྒྱུར་བྱོས།',
  );
  String get moreTitle => _localized(
    telugu: 'మరిన్ని',
    english: 'More',
    hindi: 'अधिक',
    tamil: 'மேலும்',
    kannada: 'ಇನ್ನಷ್ಟು',
    malayalam: 'കൂടുതൽ',
    marathi: 'अधिक',
    gujarati: 'વધુ',
    bengali: 'আরও',
    punjabi: 'ਹੋਰ',
    odia: 'ଅଧିକ',
    assamese: 'অধিক',
    konkani: 'आनीक',
    nepali: 'थप',
    meitei: 'Ahenba',
    mizo: 'A dang',
    kashmiri: 'مزید',
    ladakhi: 'དེ་ལས་མང་བ།',
  );
  String get moreSubtitle => _localized(
    telugu: 'మిగతా ఎంపికలు',
    english: 'Remaining options',
    hindi: 'शेष विकल्प',
    tamil: 'மீதமுள்ள விருப்பங்கள்',
    kannada: 'ಉಳಿದ ಆಯ್ಕೆಗಳು',
    malayalam: 'ശേഷിക്കുന്ന ഓപ്ഷനുകൾ',
    marathi: 'उर्वरित पर्याय',
    gujarati: 'બાકીના વિકલ્પો',
    bengali: 'অবশিষ্ট বিকল্প',
    punjabi: 'ਬਾਕੀ ਵਿਕਲਪ',
    odia: 'ବାକି ଥିବା ବିକଳ୍ପ',
    assamese: 'বাকী থকা বিকল্পসমূহ',
    konkani: 'उरिल्ले पर्याय',
    nepali: 'बाँकी विकल्पहरू',
    meitei: 'Ahenba option-sing',
    mizo: 'Duhthlan dangte',
    kashmiri: 'باقی آپشن',
    ladakhi: 'ལྷག་མའི་གདམ་ཁ།',
  );
  String get settingsTitle => strings.appSettingsSection;
  String get religionTitle => _localized(
    telugu: 'మతం మార్చండి',
    english: 'Change religion',
    hindi: 'धर्म बदलें',
    tamil: 'மதத்தை மாற்றுக',
    kannada: 'ಧರ್ಮವನ್ನು ಬದಲಾಯಿಸಿ',
    malayalam: 'മതം മാറ്റുക',
    marathi: 'धर्म बदला',
    gujarati: 'ધર્મ બદલો',
    bengali: 'ধর্ম পরিবর্তন করুন',
    punjabi: 'ਧਰਮ ਬਦਲੋ',
    odia: 'ଧର୍ମ ବଦଳାନ୍ତୁ',
    assamese: 'ধৰ্ম সলনি কৰক',
    konkani: 'धर्म बदलो',
    nepali: 'धर्म परिवर्तन गर्नुहोस्',
    meitei: 'Laining hongdok-u',
    mizo: 'Sakhua thlak rawh',
    kashmiri: 'مذہب بٔدلیو',
    ladakhi: 'ཆོས་ལུགས་བརྗེ་བ།',
  );
  String get religionSubtitle => _localized(
    telugu: 'హోమ్‌లో కనిపించే కేటగిరీలను మార్చండి',
    english: 'Update which categories appear in home',
    hindi: 'होम में दिखाई देने वाली श्रेणियाँ अपडेट करें',
    tamil: 'முகப்புப் பக்கத்தில் தோன்றும் வகைகளைப் புதுப்பிக்கவும்',
    kannada: 'ಮುಖಪುಟದಲ್ಲಿ ಗೋಚರಿಸುವ ವರ್ಗಗಳನ್ನು ನವೀಕರಿಸಿ',
    malayalam: 'ഹോമിൽ കാണിക്കുന്ന വിഭാഗങ്ങൾ അപ്ഡേറ്റ് ചെയ്യുക',
    marathi: 'होमवर दिसणाऱ्या श्रेणी अपडेट करा',
    gujarati: 'હોમ પર દેખાતી કેટેગરીઓ અપડેટ કરો',
    bengali: 'হোমে প্রদর্শিত বিভাগগুলি আপডেট করুন',
    punjabi: 'ਹੋਮ ਵਿੱਚ ਦਿਖਾਈ ਦੇਣ ਵਾਲੀਆਂ ਸ਼੍ਰੇਣੀਆਂ ਅੱਪਡੇਟ ਕਰੋ',
    odia: 'ହୋମ୍‌ରେ ଦେଖାଯାଉଥିବା ବର୍ଗଗୁଡ଼ିକୁ ଅଦ୍ୟତନ କରନ୍ତୁ',
    assamese: 'হোমত দেখা বিভাগসমূহ আপডেট কৰক',
    konkani: 'होमाचेर दिसपी श्रेणी बदलून घेयात',
    nepali: 'गृहपृष्ठमा देखिने कोटीहरू अपडेट गर्नुहोस्',
    meitei: 'Home da utliba category sing update toubiyu',
    mizo: 'Home-a category langte tidanglam rawh',
    kashmiri: 'ہومس منز ہاونہٕ ینہٕ والیٚن زمرن منز تَبدیلی',
    ladakhi: 'Home ནང་མངོན་པའི་དབྱེ་ཁག་གསར་སྒྱུར་བྱོས།',
  );
  String get religionSavedHinduMessage => _localized(
    telugu: 'హిందూ ఎంపిక సేవ్ అయింది',
    english: 'Hindu preference saved',
    hindi: 'हिंदू प्राथमिकता सहेजी गई',
    tamil: 'இந்து விருப்பம் சேமிக்கப்பட்டது',
    kannada: 'ಹಿಂದೂ ಆದ್ಯತೆ ಉಳಿಸಲಾಗಿದೆ',
    malayalam: 'ഹിന്ദു മുൻഗണന സംരക്ഷിച്ചു',
    marathi: 'हिंदू पसंती सेव्ह केली',
    gujarati: 'હિન્દુ પસંદગી સાચવવામાં આવી',
    bengali: 'হিন্দু পছন্দ সংরক্ষিত হয়েছে',
    punjabi: 'ਹਿੰਦੂ ਤਰਜੀਹ ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਗਈ',
    odia: 'ହିନ୍ଦୁ ପସନ୍ଦ ସଂରକ୍ଷିତ ହେଲା',
    assamese: 'হিন্দু পছন্দ সংৰক্ষণ কৰা হ’ল',
    konkani: 'हिंदू पसंती सांबाळ्ळी',
    nepali: 'हिन्दू प्राथमिकता सुरक्षित गरियो',
    meitei: 'Hindu preference save toukhre',
    mizo: 'Hindu duhthlan save a ni',
    kashmiri: 'ہِندو ترجیح گیہٕ محفوٗظ',
    ladakhi: 'ཧིན་དྷུའི་གདམ་ཁ་ཉར་ཚགས།',
  );
  String get religionSavedMuslimMessage => _localized(
    telugu: 'ముస్లిం ఎంపిక సేవ్ అయింది',
    english: 'Muslim preference saved',
    hindi: 'मुस्लिम प्राथमिकता सहेजी गई',
    tamil: 'முஸ்லிம் விருப்பம் சேமிக்கப்பட்டது',
    kannada: 'ಮುಸ್ಲಿಂ ಆದ್ಯತೆ ಉಳಿಸಲಾಗಿದೆ',
    malayalam: 'മുസ്ലിം മുൻഗണന സംരക്ഷിച്ചു',
    marathi: 'मुस्लिम पसंती सेव्ह केली',
    gujarati: 'મુસ્લિમ પસંદગી સાચવવામાં આવી',
    bengali: 'মুসলিম পছন্দ সংরক্ষিত হয়েছে',
    punjabi: 'ਮੁਸਲਿਮ ਤਰਜੀਹ ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਗਈ',
    odia: 'ମୁସଲିମ୍ ପସନ୍ଦ ସଂରକ୍ଷିତ ହେଲା',
    assamese: 'মুছলিম পছন্দ সংৰক্ষণ কৰা হ’ল',
    konkani: 'मुस्लिम पसंती सांबाळ्ळी',
    nepali: 'मुस्लिम प्राथमिकता सुरक्षित गरियो',
    meitei: 'Muslim preference save toukhre',
    mizo: 'Muslim duhthlan save a ni',
    kashmiri: 'مُسلم ترجیح گیہٕ محفوٗظ',
    ladakhi: 'ཁ་ཆེའི་གདམ་ཁ་ཉར་ཚགས།',
  );
  String get religionSavedChristianMessage => _localized(
    telugu: 'క్రిస్టియన్ ఎంపిక సేవ్ అయింది',
    english: 'Christian preference saved',
    hindi: 'ईसाई प्राथमिकता सहेजी गई',
    tamil: 'கிறிஸ்தவ விருப்பம் சேமிக்கப்பட்டது',
    kannada: 'ಕ್ರಿಶ್ಚಿಯನ್ ಆದ್ಯತೆ ಉಳಿಸಲಾಗಿದೆ',
    malayalam: 'ക്രിസ്ത്യൻ മുൻഗണന സംരക്ഷിച്ചു',
    marathi: 'ख्रिश्चन पसंती सेव्ह केली',
    gujarati: 'ખ્રિસ્તી પસંદગી સાચવવામાં આવી',
    bengali: 'খ্রিস্টান পছন্দ সংরক্ষিত হয়েছে',
    punjabi: 'ਈਸਾਈ ਤਰਜੀਹ ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਗਈ',
    odia: 'ଖ୍ରୀଷ୍ଟିଆନ୍ ପସନ୍ଦ ସଂରକ୍ଷିତ ହେଲା',
    assamese: 'খ্ৰীষ্টান পছন্দ সংৰক্ষণ কৰা হ’ল',
    konkani: 'किरिस्तांव पसंती सांबाळ्ळी',
    nepali: 'ईसाई प्राथमिकता सुरक्षित गरियो',
    meitei: 'Christian preference save toukhre',
    mizo: 'Christian duhthlan save a ni',
    kashmiri: 'عیسائی ترجیح گیہٕ محفوٗظ',
    ladakhi: 'ཡེ་ཤུའི་ཆོས་ལུགས་གདམ་ཁ་ཉར་ཚགས།',
  );
  String get religionSavedAllMessage => _localized(
    telugu: 'అన్ని కేటగిరీల ఎంపిక సేవ్ అయింది',
    english: 'All categories preference saved',
    hindi: 'सभी श्रेणियों की प्राथमिकता सहेजी गई',
    tamil: 'அனைத்து வகைகளின் விருப்பம் சேமிக்கப்பட்டது',
    kannada: 'ಎಲ್ಲಾ ವರ್ಗಗಳ ಆದ್ಯತೆ ಉಳಿಸಲಾಗಿದೆ',
    malayalam: 'എല്ലാ വിഭാഗങ്ങളുടെയും മുൻഗണന സംരക്ഷിച്ചു',
    marathi: 'सर्व श्रेणींची पसंती सेव्ह केली',
    gujarati: 'બધી કેટેગરીઓની પસંદગી સાચવવામાં આવી',
    bengali: 'সমস্ত বিভাগের পছন্দ সংরক্ষিত হয়েছে',
    punjabi: 'ਸਾਰੀਆਂ ਸ਼੍ਰੇਣੀਆਂ ਦੀ ਤਰਜੀਹ ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਗਈ',
    odia: 'ସମସ୍ତ ବର୍ଗର ପସନ୍ଦ ସଂରକ୍ଷିତ ହେଲା',
    assamese: 'সকলো বিভাগৰ পছন্দ সংৰক্ষণ কৰা হ’ল',
    konkani: 'सगळ्यो श्रेणी पसंती सांबाळ्ळी',
    nepali: 'सबै कोटीहरूको प्राथमिकता सुरक्षित गरियो',
    meitei: 'Pumnamak category gi preference save toukhre',
    mizo: 'Category zawng zawng duhthlan save a ni',
    kashmiri: 'سٲری زمرن ہٕنٛز ترجیح گیہٕ محفوٗظ',
    ladakhi: 'དབྱེ་ཁག་ཚང་མའི་གདམ་ཁ་ཉར་ཚགས།',
  );

  String get languageTitle => strings.languageOption;
  String? get languageSubtitle => strings.languageOptionSubtitle;
  String get stateTitle => _localized(
    telugu: 'రాష్ట్రం / కేంద్ర పాలిత ప్రాంతం మార్చండి',
    english: 'Change State / UT',
    hindi: 'राज्य / केंद्र शासित प्रदेश बदलें',
    tamil: 'மாநிலம் / யூனியன் பிரதேசத்தை மாற்றுக',
    kannada: 'ರಾಜ್ಯ / ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶ ಬದಲಾಯಿಸಿ',
    malayalam: 'സംസ്ഥാനം / കേന്ദ്രഭരണ പ്രദേശം മാറ്റുക',
    marathi: 'राज्य / केंद्रशासित प्रदेश बदला',
    gujarati: 'રાજ્ય / કેન્દ્રશાસિત પ્રદેશ બદલો',
    bengali: 'রাজ্য / কেন্দ্রশাসিত অঞ্চল পরিবর্তন করুন',
    punjabi: 'ਰਾਜ / ਕੇਂਦਰ ਸ਼ਾਸਿਤ ਪ੍ਰਦੇਸ਼ ਬਦਲੋ',
    odia: 'ରାଜ୍ୟ / କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ ବଦଳାନ୍ତୁ',
    assamese: 'ৰাজ্য / কেন্দ্ৰীয় শাসিত অঞ্চল সলনি কৰক',
    konkani: 'राज्य / केंद्रशासित प्रदेश बदलो',
    nepali: 'राज्य / केन्द्र शासित प्रदेश परिवर्तन गर्नुहोस्',
    meitei: 'State / UT hongdok-u',
    mizo: 'State / UT thlak rawh',
    kashmiri: 'ریاست / یو ٹی بٔدلیو',
    ladakhi: 'མངའ་སྡེ་ / དབུས་གཞུང་ཁུལ་བརྗེ་བ།',
  );
  String get stateSubtitle => _localized(
    telugu: 'యాప్ భాష మరియు రాష్ట్ర కేటగిరీలను అప్డేట్ చేయండి',
    english: 'Update app language and state categories',
    hindi: 'ऐप भाषा और राज्य श्रेणियां अपडेट करें',
    tamil: 'செயலி மொழி மற்றும் மாநில வகைகளைப் புதுப்பிக்கவும்',
    kannada: 'ಆಪ್ ಭಾಷೆ ಮತ್ತು ರಾಜ್ಯ ವರ್ಗಗಳನ್ನು ನವೀಕರಿಸಿ',
    malayalam: 'ആപ്പ് ഭാഷയും സംസ്ഥാന വിഭാഗങ്ങളും അപ്ഡേറ്റ് ചെയ്യുക',
    marathi: 'अ‍ॅप भाषा आणि राज्य श्रेणी अपडेट करा',
    gujarati: 'એપ ભાષા અને રાજ્ય શ્રેણીઓ અપડેટ કરો',
    bengali: 'অ্যাপ ভাষা এবং রাজ্য বিভাগগুলি আপডেট করুন',
    punjabi: 'ਐਪ ਭਾਸ਼ਾ ਅਤੇ ਰਾਜ ਸ਼੍ਰੇਣੀਆਂ ਅੱਪਡੇਟ ਕਰੋ',
    odia: 'ଆପ୍ ଭାଷା ଏବଂ ରାଜ୍ୟ ବର୍ଗ ଅଦ୍ୟତନ କରନ୍ତୁ',
    assamese: 'এপৰ ভাষা আৰু ৰাজ্যিক বিভাগসমূহ আপডেট কৰক',
    konkani: 'अ‍ॅप भास आनी राज्य श्रेणी अपडेट करात',
    nepali: 'एप भाषा र राज्य कोटीहरू अपडेट गर्नुहोस्',
    meitei: 'App lon amasung state category sing update toubiyu',
    mizo: 'App tawng leh state category tidanglam rawh',
    kashmiri: 'ایپ زبان تہٕ ریاستی زمرہ جات کٔریو اپ ڈیٹ',
    ladakhi: 'App སྐད་རིགས་དང་མངའ་སྡེའི་དབྱེ་ཁག་གསར་སྒྱུར་བྱོས།',
  );
  String get stateSavedMessage => _localized(
    telugu: 'రాష్ట్రం అప్డేట్ అయింది. దయచేసి రాజకీయ పార్టీలను చూసుకోండి',
    english: 'State updated. Please review political parties',
    hindi: 'राज्य अपडेट हो गया। कृपया राजनीतिक दलों की समीक्षा करें',
    tamil: 'மாநிலம் புதுப்பிக்கப்பட்டது. அரசியல் கட்சிகளைச் சரிபார்க்கவும்',
    kannada: 'ರಾಜ್ಯ ನವೀಕರಿಸಲಾಗಿದೆ. ದಯವಿಟ್ಟು ರಾಜಕೀಯ ಪಕ್ಷಗಳನ್ನು ಪರಿಶೀಲಿಸಿ',
    malayalam: 'സംസ്ഥാനം അപ്ഡേറ്റ് ചെയ്തു. രാഷ്ട്രീയ പാർട്ടികൾ അവലോകനം ചെയ്യുക',
    marathi: 'राज्य अपडेट केले. कृपया राजकीय पक्षांचे पुनरावलोकन करा',
    gujarati: 'રાજ્ય અપડેટ થયું. કૃપા કરીને રાજકીય પક્ષોની સમીક્ષા કરો',
    bengali: 'রাজ্য আপডেট হয়েছে। অনুগ্রহ করে রাজনৈতিক দল পর্যালোচনা করুন',
    punjabi: 'ਰਾਜ ਅੱਪਡੇਟ ਹੋਇਆ। ਕਿਰਪਾ ਕਰਕੇ ਸਿਆਸੀ ਪਾਰਟੀਆਂ ਦੀ ਸਮੀਖਿਆ ਕਰੋ',
    odia: 'ରାଜ୍ୟ ଅଦ୍ୟତନ ହେଲା। ଦୟାକରି ରାଜନୈତିକ ଦଳଗୁଡ଼ିକର ସମୀକ୍ଷା କରନ୍ତୁ',
    assamese: 'ৰাজ্য আপডেট কৰা হ’ল। অনুগ্ৰহ কৰি ৰাজনৈতিক দলসমূহ পুনৰীক্ষণ কৰক',
    konkani: 'राज्य अपडेट जालें. उपकार करून राजकीय पक्षांची तपासणी करात',
    nepali: 'राज्य अपडेट भयो। कृपया राजनीतिक दलहरूको समीक्षा गर्नुहोस्',
    meitei: 'State update oikhre. Political party sing yengbiyu',
    mizo: 'State tidanglam a ni. Khawngaihin political party-te en nawn rawh',
    kashmiri: 'ریاست گٔیہٕ اپ ڈیٹ۔ مہربٲنی کٔرتھ کٔریو سیاسی پارٹین ہُنٛد جائزہ',
    ladakhi: 'མངའ་སྡེ་གསར་སྒྱུར་བྱས། སྲིད་དོན་ཚོགས་པ་བསྐྱར་ཞིབ་གནང།',
  );
  String get politicalPartyTitle => _localized(
    telugu: 'రాజకీయ పార్టీలు',
    english: 'Political parties',
    hindi: 'राजनीतिक दल',
    tamil: 'அரசியல் கட்சிகள்',
    kannada: 'ರಾಜಕೀಯ ಪಕ್ಷಗಳು',
    malayalam: 'രാഷ്ട്രീയ പാർട്ടികൾ',
    marathi: 'राजकीय पक्ष',
    gujarati: 'રાજકીય પક્ષો',
    bengali: 'রাজনৈতিক দল',
    punjabi: 'ਸਿਆਸੀ ਪਾਰਟੀਆਂ',
    odia: 'ରାଜନୈତିକ ଦଳ',
    assamese: 'ৰাজনৈতিক দলসমূহ',
    konkani: 'राजकीय पक्ष',
    nepali: 'राजनीतिक दलहरू',
    meitei: 'Political parties',
    mizo: 'Political party-te',
    kashmiri: 'سیاسی پارٹیاں',
    ladakhi: 'སྲིད་དོན་ཚོགས་པ།',
  );
  String get politicalPartySubtitle => _localized(
    telugu: 'హోమ్‌లో కనిపించే రాజకీయ పార్టీ కేటగిరీలను అప్డేట్ చేయండి',
    english: 'Update political party categories shown in home',
    hindi: 'होम में दिखाई देने वाले राजनीतिक दलों की श्रेणियां अपडेट करें',
    tamil: 'முகப்பில் காட்டப்படும் அரசியல் கட்சி வகைகளைப் புதுப்பிக்கவும்',
    kannada: 'ಮುಖಪುಟದಲ್ಲಿ ತೋರಿಸಲಾದ ರಾಜಕೀಯ ಪಕ್ಷದ ವರ್ಗಗಳನ್ನು ನವೀಕರಿಸಿ',
    malayalam: 'ഹോമിൽ കാണിക്കുന്ന രാഷ്ട്രീയ പാർട്ടി വിഭാഗങ്ങൾ അപ്ഡേറ്റ് ചെയ്യുക',
    marathi: 'होमवर दर्शविलेल्या राजकीय पक्षांच्या श्रेणी अपडेट करा',
    gujarati: 'હોમ પર દેખાતી રાજકીય પક્ષની કેટેગરીઓ અપડેટ કરો',
    bengali: 'হোমে দেখানো রাজনৈতিক দলের বিভাগগুলি আপডেট করুন',
    punjabi: 'ਹੋਮ ਵਿੱਚ ਦਿਖਾਈ ਦੇਣ ਵਾਲੀਆਂ ਸਿਆਸੀ ਪਾਰਟੀਆਂ ਦੀਆਂ ਸ਼੍ਰੇਣੀਆਂ ਅੱਪਡੇਟ ਕਰੋ',
    odia: 'ହୋମ୍‌ରେ ପ୍ରଦର୍ଶିତ ରାଜନୈତିକ ଦଳ ବର୍ଗ ଅଦ୍ୟତନ କରନ୍ତୁ',
    assamese: 'হোমত প্ৰদৰ্শিত ৰাজনৈতিক দলৰ বিভাগসমূহ আপডেট কৰক',
    konkani: 'होमाचेर दाखयिल्ल्या राजकीय पक्षांच्यो श्रेणी अपडेट करात',
    nepali: 'गृहपृष्ठमा देखाइएका राजनीतिक दलका कोटीहरू अपडेट गर्नुहोस्',
    meitei: 'Home da utliba political party category sing update toubiyu',
    mizo: 'Home-a political party category langte tidanglam rawh',
    kashmiri: 'ہومس منز ہاونہٕ آمٕژ سیاسی پارٹی ہٕنٛز کیٹیگری کٔریو اپ ڈیٹ',
    ladakhi: 'Home ནང་མངོན་པའི་སྲིད་དོན་ཚོགས་པའི་དབྱེ་ཁག་གསར་སྒྱུར་བྱོས།',
  );
  String get politicalPartySavedMessage => _localized(
    telugu: 'రాజకీయ పార్టీలు అప్డేట్ అయ్యాయి',
    english: 'Political parties updated',
    hindi: 'राजनीतिक दल अपडेट हो गए',
    tamil: 'அரசியல் கட்சிகள் புதுப்பிக்கப்பட்டன',
    kannada: 'ರಾಜಕೀಯ ಪಕ್ಷಗಳು ನವೀಕರಿಸಲಾಗಿದೆ',
    malayalam: 'രാഷ്ട്രീയ പാർട്ടികൾ അപ്ഡേറ്റ് ചെയ്തു',
    marathi: 'राजकीय पक्ष अपडेट केले',
    gujarati: 'રાજકીય પક્ષો અપડેટ થયા',
    bengali: 'রাজনৈতিক দল আপডেট করা হয়েছে',
    punjabi: 'ਸਿਆਸੀ ਪਾਰਟੀਆਂ ਅੱਪਡੇਟ ਕੀਤੀਆਂ ਗਈਆਂ',
    odia: 'ରାଜନୈତିକ ଦଳ ଅଦ୍ୟତନ ହେଲା',
    assamese: 'ৰাজনৈতিক দলসমূহ আপডেট কৰা হ’ল',
    konkani: 'राजकीय पक्ष अपडेट जाले',
    nepali: 'राजनीतिक दलहरू अपडेट गरियो',
    meitei: 'Political party sing update oikhre',
    mizo: 'Political party-te tidanglam a ni',
    kashmiri: 'سیاسی پارٹیاں گٔیہٕ اپ ڈیٹ',
    ladakhi: 'སྲིད་དོན་ཚོགས་པ་གསར་སྒྱུར་བྱས།',
  );
  String get subscriptionTitle => strings.subscriptionOption;
  String get subscriptionSubtitle => _localized(
    telugu: 'ప్లాన్ వివరాలు చూడండి',
    english: 'View plan details',
    hindi: 'प्लान विवरण देखें',
    tamil: 'திட்ட விவரங்களைக் காண்க',
    kannada: 'ಯೋಜನೆ ವಿವರಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
    malayalam: 'പ്ലാൻ വിവരങ്ങൾ കാണുക',
    marathi: 'प्लॅन तपशील पहा',
    gujarati: 'પ્લાનની વિગતો જુઓ',
    bengali: 'প্ল্যানের বিবরণ দেখুন',
    punjabi: 'ਪਲਾਨ ਵੇਰਵੇ ਵੇਖੋ',
    odia: 'ପ୍ଲାନ୍ ବିବରଣୀ ଦେଖନ୍ତୁ',
    assamese: 'প্লেনৰ বিৱৰণ চাওক',
    konkani: 'प्लॅन तपशील पळयात',
    nepali: 'योजना विवरण हेर्नुहोस्',
    meitei: 'Plan details yengbiyu',
    mizo: 'Plan chanchin en rawh',
    kashmiri: 'پلان تفصیلات وُچھِو',
    ladakhi: 'འཆར་གཞིའི་ཞིབ་ཕྲ་གཟིགས།',
  );
  String get purchaseInvoicesTitle => _localized(
    telugu: 'కొనుగోలు ఇన్వాయిసులు',
    english: 'Purchase invoices',
    hindi: 'खरीद इनवॉइस',
    tamil: 'வாங்கிய விலைப்பட்டியல்கள்',
    kannada: 'ಖರೀದಿ ಇನ್‌ವಾಯ್ಸ್‌ಗಳು',
    malayalam: 'വാങ്ങൽ ഇൻവോയ്‌സുകൾ',
    marathi: 'खरेदी इनव्हॉइस',
    gujarati: 'ખરીદી ઇનવૉઇસ',
    bengali: 'ক্রয় ইনভয়েস',
    punjabi: 'ਖਰੀਦ ਇਨਵੌਇਸ',
    odia: 'କ୍ରୟ ଇନଭଏସ୍',
    assamese: 'ক্ৰয় চালান',
    konkani: 'खरेदी इनव्हॉइस',
    nepali: 'खरिद इनभ्वाइसहरू',
    meitei: 'Purchase invoices',
    mizo: 'Leina invoice-te',
    kashmiri: 'خٔریٖداری انوائس',
    ladakhi: 'ཉོ་སྒྲུབ་འཛིན་ཤོག',
  );
  String get purchaseInvoicesSubtitle => _localized(
    telugu: 'కొనుగోలు వివరాలు చూడండి',
    english: 'View purchase details',
    hindi: 'खरीद विवरण देखें',
    tamil: 'கொள்முதல் விவரங்களைக் காண்க',
    kannada: 'ಖರೀದಿ ವಿವರಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
    malayalam: 'വാങ്ങൽ വിവരങ്ങൾ കാണുക',
    marathi: 'खरेदी तपशील पहा',
    gujarati: 'ખરીદીની વિગતો જુઓ',
    bengali: 'ক্রয়ের বিবরণ দেখুন',
    punjabi: 'ਖਰੀਦ ਵੇਰਵੇ ਵੇਖੋ',
    odia: 'କ୍ରୟ ବିବରଣୀ ଦେଖନ୍ତୁ',
    assamese: 'ক্ৰয়ৰ বিৱৰণ চাওক',
    konkani: 'खरेदी तपशील पळयात',
    nepali: 'खरिद विवरण हेर्नुहोस्',
    meitei: 'Leiraba details yengbiyu',
    mizo: 'Leina chanchin en rawh',
    kashmiri: 'خٔریٖداری تفصیلات وُچھِو',
    ladakhi: 'ཉོ་སྒྲུབ་ཞིབ་ཕྲ་གཟིགས།',
  );
  String get referralRewardsTitle => _localized(
    telugu: 'రెఫరల్ రివార్డులు',
    english: 'Referral rewards',
    hindi: 'रेफ़रल पुरस्कार',
    tamil: 'பரிந்துரை வெகுமதிகள்',
    kannada: 'ರೆಫರಲ್ ಬಹುಮಾನಗಳು',
    malayalam: 'റഫറൽ റിവാർഡുകൾ',
    marathi: 'रेफरल रिवॉर्ड्स',
    gujarati: 'રેફરલ પુરસ્કારો',
    bengali: 'রেফারেল পুরস্কার',
    punjabi: 'ਰੈਫਰਲ ਇਨਾਮ',
    odia: 'ରେଫରାଲ୍ ପୁରସ୍କାର',
    assamese: 'ৰেফাৰেল পুৰস্কাৰ',
    konkani: 'रेफरल पुरस्कार',
    nepali: 'रेफरल पुरस्कारहरू',
    meitei: 'Referral rewards',
    mizo: 'Referral lawmman',
    kashmiri: 'ریفرل انعامات',
    ladakhi: 'ངོ་སྤྲོད་བྱ་དགའ།',
  );
  String get referralRewardsSubtitle => _localized(
    telugu: 'రెఫరల్ కోడ్ మరియు ప్రస్తుత సైకిల్ చూడండి',
    english: 'View referral code and current cycle',
    hindi: 'रेफ़रल कोड और वर्तमान चक्र देखें',
    tamil: 'பரிந்துரைக் குறியீடு மற்றும் தற்போதைய சுழற்சியைக் காண்க',
    kannada: 'ರೆಫರಲ್ ಕೋಡ್ ಮತ್ತು ಪ್ರಸ್ತುತ ಸೈಕಲ್ ನೋಡಿ',
    malayalam: 'റഫറൽ കോഡും നിലവിലെ സൈക്കിളും കാണുക',
    marathi: 'रेफरल कोड आणि चालू सायकल पहा',
    gujarati: 'રેફરલ કોડ અને વર્તમાન સાયકલ જુઓ',
    bengali: 'রেফারেল কোড এবং বর্তমান চক্র দেখুন',
    punjabi: 'ਰੈਫਰਲ ਕੋਡ ਅਤੇ ਮੌਜੂਦਾ ਚੱਕਰ ਵੇਖੋ',
    odia: 'ରେଫରାଲ୍ କୋଡ୍ ଏବଂ ବର୍ତ୍ତମାନର ସାଇକଲ୍ ଦେଖନ୍ତୁ',
    assamese: 'ৰেফাৰেল ক’ড আৰু বৰ্তমান চক্ৰ চাওক',
    konkani: 'रेफरल कोड आनी चालू चक्र पळयात',
    nepali: 'रेफरल कोड र वर्तमान चक्र हेर्नुहोस्',
    meitei: 'Referral code amasung houjik cycle yengbiyu',
    mizo: 'Referral code leh kal mek dinhmun en rawh',
    kashmiri: 'ریفرل کوڈ تہٕ موجودٕ چکر وُچھِو',
    ladakhi: 'ངོ་སྤྲོད་གསང་རྟགས་དང་ད་ལྟའི་སྐོར་རིམ་གཟིགས།',
  );
  String referralProgressText(int current, int required) {
    return _localized(
      telugu: 'ప్రస్తుత చక్రం: $current / $required',
      english: 'Current cycle: $current / $required',
      hindi: 'वर्तमान चक्र: $current / $required',
      tamil: 'தற்போதைய சுழற்சி: $current / $required',
      kannada: 'ಪ್ರಸ್ತುತ ಸೈಕಲ್: $current / $required',
      malayalam: 'നിലവിലെ സൈക്കിൾ: $current / $required',
      marathi: 'चालू सायकल: $current / $required',
      gujarati: 'વર્તમાન સાયકલ: $current / $required',
      bengali: 'বর্তমান চক্র: $current / $required',
      punjabi: 'ਮੌਜੂਦਾ ਚੱਕਰ: $current / $required',
      odia: 'ବର୍ତ୍ତମାନର ସାଇକଲ୍: $current / $required',
      assamese: 'বৰ্তমান চক্ৰ: $current / $required',
      konkani: 'चालू चक्र: $current / $required',
      nepali: 'वर्तमान चक्र: $current / $required',
      meitei: 'Houjik cycle: $current / $required',
      mizo: 'Kal mek: $current / $required',
      kashmiri: 'موجودٕ چکر: $current / $required',
      ladakhi: 'ད་ལྟའི་སྐོར་རིམ: $current / $required',
    );
  }

  String get copyReferralCodeAction => _localized(
    telugu: 'కోడ్ కాపీ',
    english: 'Copy code',
    hindi: 'कोड कॉपी करें',
    tamil: 'குறியீட்டை நகலெடு',
    kannada: 'ಕೋಡ್ ನಕಲಿಸಿ',
    malayalam: 'കോഡ് പകർപ്പുക',
    marathi: 'कोड कॉपी करा',
    gujarati: 'કોડ કૉપિ કરો',
    bengali: 'কোড কপি করুন',
    punjabi: 'ਕੋਡ ਕਾਪੀ ਕਰੋ',
    odia: 'କୋଡ୍ କପି କରନ୍ତୁ',
    assamese: 'ক’ড কপি কৰক',
    konkani: 'कोड कॉपी करात',
    nepali: 'कोड प्रतिलिपि गर्नुहोस्',
    meitei: 'Code copy toubiyu',
    mizo: 'Code copy rawh',
    kashmiri: 'کوڈ کٔریو کاپی',
    ladakhi: 'གསང་རྟགས་འདྲ་བཤུས་བྱོས།',
  );
  String get shareReferralAction => _localized(
    telugu: 'షేర్',
    english: 'Share',
    hindi: 'शेयर',
    tamil: 'பகிர்',
    kannada: 'ಹಂಚಿಕೊಳ್ಳಿ',
    malayalam: 'പങ്കിടുക',
    marathi: 'शेअर',
    gujarati: 'શેર',
    bengali: 'শেয়ার',
    punjabi: 'ਸਾਂਝਾ ਕਰੋ',
    odia: 'ସେୟାର୍',
    assamese: 'শ্বেয়াৰ',
    konkani: 'शेअर',
    nepali: 'साझेदारी',
    meitei: 'Share',
    mizo: 'Thawn',
    kashmiri: 'شیئر',
    ladakhi: 'Share',
  );
  String get referralTermsAction => _localized(
    telugu: 'నిబంధనలు & షరతులు చూడండి',
    english: 'View Terms & Conditions',
    hindi: 'नियम एवं शर्तें देखें',
    tamil: 'விதிமுறைகள் & நிபந்தனைகளைக் காண்க',
    kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
    malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും കാണുക',
    marathi: 'अटी आणि शर्ती पहा',
    gujarati: 'નિયમો અને શરતો જુઓ',
    bengali: 'নিয়ম ও শর্তাবলী দেখুন',
    punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ ਵੇਖੋ',
    odia: 'ନିୟମାବଳୀ ଓ ସର୍ତ୍ତାବଳୀ ଦେଖନ୍ତୁ',
    assamese: 'নিয়ম আৰু চৰ্তাৱলী চাওক',
    konkani: 'अटी आनी शर्ती पळयात',
    nepali: 'नियम र सर्तहरू हेर्नुहोस्',
    meitei: 'Terms & Conditions yengbiyu',
    mizo: 'Hman dan tur leh Dan en rawh',
    kashmiri: 'شرائط و ضوابط وُچھِو',
    ladakhi: 'ཆ་རྐྱེན་དང་དོན་ཚན་གཟིགས།',
  );
  String get applyReferralCodeLabel => _localized(
    telugu: 'రెఫరల్ కోడ్ నమోదు చేయండి',
    english: 'Enter referral code',
    hindi: 'रेफ़रल कोड दर्ज करें',
    tamil: 'பரிந்துரைக் குறியீட்டை உள்ளிடவும்',
    kannada: 'ರೆಫರಲ್ ಕೋಡ್ ನಮೂದಿಸಿ',
    malayalam: 'റഫറൽ കോഡ് നൽകുക',
    marathi: 'रेफरल कोड प्रविष्ट करा',
    gujarati: 'રેફરલ કોડ દાખલ કરો',
    bengali: 'রেফারেল কোড লিখুন',
    punjabi: 'ਰੈਫਰਲ ਕੋਡ ਦਰਜ ਕਰੋ',
    odia: 'ରେଫରାଲ୍ କୋଡ୍ ଦାଖଲ କରନ୍ତୁ',
    assamese: 'ৰেফাৰেল ক’ড লিখক',
    konkani: 'रेफरल कोड घालात',
    nepali: 'रेफरल कोड प्रविष्ट गर्नुहोस्',
    meitei: 'Referral code hapchinbiyu',
    mizo: 'Referral code chhu lut rawh',
    kashmiri: 'ریفرل کوڈ دَرٕج کٔریو',
    ladakhi: 'ངོ་སྤྲོད་གསང་རྟགས་འཇུག་པ།',
  );
  String get applyReferralCodeAction => _localized(
    telugu: 'అప్లై',
    english: 'Apply',
    hindi: 'लागू करें',
    tamil: 'பயன்படுத்து',
    kannada: 'ಅನ್ವಯಿಸಿ',
    malayalam: 'പ്രയോഗിക്കുക',
    marathi: 'लागू करा',
    gujarati: 'લાગુ કરો',
    bengali: 'প্রয়োগ করুন',
    punjabi: 'ਲਾਗੂ ਕਰੋ',
    odia: 'ଲାଗୁ କରନ୍ତୁ',
    assamese: 'প্ৰয়োগ কৰক',
    konkani: 'लागू करात',
    nepali: 'लागू गर्नुहोस्',
    meitei: 'Apply toubiyu',
    mizo: 'Hman',
    kashmiri: 'لاگوٗ کٔریو',
    ladakhi: 'བཀོལ་སྤྱོད་བྱོས།',
  );
  String get referralCodeCopiedMessage => _localized(
    telugu: 'రెఫరల్ కోడ్ కాపీ అయింది',
    english: 'Referral code copied',
    hindi: 'रेफ़रल कोड कॉपी किया गया',
    tamil: 'பரிந்துரைக் குறியீடு நகலெடுக்கப்பட்டது',
    kannada: 'ರೆಫರಲ್ ಕೋಡ್ ನಕಲಿಸಲಾಗಿದೆ',
    malayalam: 'റഫറൽ കോഡ് പകർത്തി',
    marathi: 'रेफरल कोड कॉपी केला',
    gujarati: 'રેફરલ કોડ કૉપિ થયો',
    bengali: 'রেফারেল কোড কপি করা হয়েছে',
    punjabi: 'ਰੈਫਰਲ ਕੋਡ ਕਾਪੀ ਕੀਤਾ ਗਿਆ',
    odia: 'ରେଫରାଲ୍ କୋଡ୍ କପି ହେଲା',
    assamese: 'ৰেফাৰেল ক’ড কপি কৰা হ’ল',
    konkani: 'रेफरल कोड कॉपी जालो',
    nepali: 'रेफरल कोड प्रतिलिपि गरियो',
    meitei: 'Referral code copy toukhre',
    mizo: 'Referral code copy a ni',
    kashmiri: 'ریفرل کوڈ آو کاپی کرنہٕ',
    ladakhi: 'ངོ་སྤྲོད་གསང་རྟགས་འདྲ་བཤུས་བྱས།',
  );
  String get referralCodeAppliedMessage => _localized(
    telugu: 'రెఫరల్ కోడ్ అప్లై అయింది',
    english: 'Referral code applied',
    hindi: 'रेफ़रल कोड लागू किया गया',
    tamil: 'பரிந்துரைக் குறியீடு பயன்படுத்தப்பட்டது',
    kannada: 'ರೆಫರಲ್ ಕೋಡ್ ಅನ್ವಯಿಸಲಾಗಿದೆ',
    malayalam: 'റഫറൽ കോഡ് പ്രയോഗിച്ചു',
    marathi: 'रेफरल कोड लागू केला',
    gujarati: 'રેફરલ કોડ લાગુ કર્યો',
    bengali: 'রেফারেল কোড প্রয়োগ করা হয়েছে',
    punjabi: 'ਰੈਫਰਲ ਕੋਡ ਲਾਗੂ ਕੀਤਾ ਗਿਆ',
    odia: 'ରେଫରାଲ୍ କୋଡ୍ ଲାଗୁ ହେଲା',
    assamese: 'ৰেফাৰেল ক’ড প্ৰয়োগ কৰা হ’ল',
    konkani: 'रेफरल कोड लागू जालो',
    nepali: 'रेफरल कोड लागू गरियो',
    meitei: 'Referral code apply toukhre',
    mizo: 'Referral code hman a ni',
    kashmiri: 'ریفرل کوڈ آو لاگوٗ کرنہٕ',
    ladakhi: 'ངོ་སྤྲོད་གསང་རྟགས་བཀོལ་སྤྱོད་བྱས།',
  );
  String get referralCodeAlreadyAppliedMessage => _localized(
    telugu: 'రెఫరల్ ఇప్పటికే అప్లై అయింది',
    english: 'Referral already applied',
    hindi: 'रेफ़रल पहले से लागू है',
    tamil: 'பரிந்துரை ஏற்கனவே பயன்படுத்தப்பட்டது',
    kannada: 'ರೆಫರಲ್ ಈಗಾಗಲೇ ಅನ್ವಯಿಸಲಾಗಿದೆ',
    malayalam: 'റഫറൽ ഇതിനകം പ്രയോഗിച്ചു',
    marathi: 'रेफरल आधीच लागू केला आहे',
    gujarati: 'રેફરલ પહેલેથી જ લાગુ છે',
    bengali: 'রেফারেল ইতিমধ্যে প্রয়োগ করা হয়েছে',
    punjabi: 'ਰੈਫਰਲ ਪਹਿਲਾਂ ਹੀ ਲਾਗੂ ਕੀਤਾ ਗਿਆ ਹੈ',
    odia: 'ରେଫରାଲ୍ ପୂର୍ବରୁ ଲାଗୁ ହୋଇଛି',
    assamese: 'ৰেফাৰেল ইতিমধ্যে প্ৰয়োগ কৰা হৈছে',
    konkani: 'रेफरल पयलींच लागू जाला',
    nepali: 'रेफरल पहिले नै लागू गरिएको छ',
    meitei: 'Referral leithokna apply toukhraba',
    mizo: 'Referral hman a ni tawh',
    kashmiri: 'ریفرل چھُ گۄڈے لاگوٗ',
    ladakhi: 'ངོ་སྤྲོད་སྔོན་ནས་བཀོལ་སྤྱོད་བྱས།',
  );
  String get referralCodeApplyFailedMessage => _localized(
    telugu: 'రెఫరల్ కోడ్ అప్లై కాలేదు. మళ్లీ ప్రయత్నించండి.',
    english: 'Referral code apply failed. Please try again.',
    hindi: 'रेफ़रल कोड लागू नहीं हो सका। कृपया पुनः प्रयास करें।',
    tamil: 'பரிந்துரைக் குறியீட்டைப் பயன்படுத்த முடியவில்லை. மீண்டும் முயல்க.',
    kannada: 'ರೆಫರಲ್ ಕೋಡ್ ಅನ್ವಯಿಸಲು ವಿಫಲವಾಗಿದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'റഫറൽ കോഡ് പ്രയോഗിക്കുന്നതിൽ പരാജയപ്പെട്ടു. വീണ്ടും ശ്രമിക്കുക.',
    marathi: 'रेफरल कोड लागू करणे अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.',
    gujarati: 'રેફરલ કોડ લાગુ કરવામાં નિષ્ફળ. ફરી પ્રયાસ કરો.',
    bengali: 'রেফারেল কোড প্রয়োগ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
    punjabi: 'ਰੈਫਰਲ ਕੋਡ ਲਾਗੂ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    odia: 'ରେଫରାଲ୍ କୋଡ୍ ଲାଗୁ ବିଫଳ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
    assamese: 'ৰেফাৰেল ক’ড প্ৰয়োগ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
    konkani: 'रेफरल कोड लागू जालो ना. उपकार करून परत प्रयत्न करात.',
    nepali: 'रेफरल कोड लागू गर्न असफल। कृपया पुन: प्रयास गर्नुहोस्।',
    meitei: 'Referral code apply touba maipak-khide. Amuk hanna hotnabiyu.',
    mizo: 'Referral code hman a hlawhchham. Khawngaihin ti nawn leh rawh.',
    kashmiri: 'ریفرل کوڈ لاگوٗ کرنہٕ منز ناکامی۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
    ladakhi: 'ངོ་སྤྲོད་གསང་རྟགས་བཀོལ་སྤྱོད་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
  );
  String get referralLoadFailedMessage => _localized(
    telugu: 'రెఫరల్ వివరాలు లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    english: 'Referral details could not load. Please try again.',
    hindi: 'रेफ़रल विवरण लोड नहीं हो सके। कृपया पुनः प्रयास करें।',
    tamil: 'பரிந்துரை விவரங்களை ஏற்ற முடியவில்லை. மீண்டும் முயல்க.',
    kannada: 'ರೆಫರಲ್ ವಿವರಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'റഫറൽ വിശദാംശങ്ങൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
    marathi: 'रेफरल तपशील लोड करता आले नाहीत. कृपया पुन्हा प्रयत्न करा.',
    gujarati: 'રેફરલ વિગતો લોડ થઈ શકી નથી. ફરી પ્રયાસ કરો.',
    bengali: 'রেফারেল বিবরণ লোড করা যায়নি। আবার চেষ্টা করুন।',
    punjabi: 'ਰੈਫਰਲ ਵੇਰਵੇ ਲੋਡ ਨਹੀਂ ਹੋ ਸਕੇ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    odia: 'ରେଫରାଲ୍ ବିବରଣୀ ଲୋଡ୍ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
    assamese: 'ৰেফাৰেল বিৱৰণ ল’ড নহ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
    konkani: 'रेफरल तपशील लोड जाले नात. उपकार करून परत प्रयत्न करात.',
    nepali: 'रेफरल विवरण लोड गर्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
    meitei: 'Referral details load touba ngamde. Amuk hanna hotnabiyu.',
    mizo: 'Referral chanchin load thei lo. Khawngaihin ti nawn leh rawh.',
    kashmiri: 'ریفرل تفصیلات لوڈ نہ گٔژھِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
    ladakhi: 'ངོ་སྤྲོད་ཞིབ་ཕྲ་ load མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
  );
  String get closeAction => _localized(
    telugu: 'మూసివేయి',
    english: 'Close',
    hindi: 'बंद करें',
    tamil: 'மூடு',
    kannada: 'ಮುಚ್ಚಿ',
    malayalam: 'അടയ്ക്കുക',
    marathi: 'बंद करा',
    gujarati: 'બંધ કરો',
    bengali: 'বন্ধ করুন',
    punjabi: 'ਬੰਦ ਕਰੋ',
    odia: 'ବନ୍ଦ କରନ୍ତୁ',
    assamese: 'বন্ধ কৰক',
    konkani: 'बंद करात',
    nepali: 'बन्द गर्नुहोस्',
    meitei: 'Thinbiyu',
    mizo: 'Khar rawh',
    kashmiri: 'بند کٔریو',
    ladakhi: 'སྒོ་རྒྱག',
  );
  String get restoreSubscriptionTitle => _localized(
    telugu: 'సబ్‌స్క్రిప్షన్‌లను రీస్టోర్ చేయండి',
    english: 'Restore subscriptions',
    hindi: 'सदस्यता पुनर्स्थापित करें',
    tamil: 'சந்தாக்களை மீட்டெடுக்கவும்',
    kannada: 'ಚಂದಾದಾರಿಕೆಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಿ',
    malayalam: 'സബ്സ്ക്രിപ്ഷനുകൾ പുനഃസ്ഥാപിക്കുക',
    marathi: 'सदस्यता पुनर्संचयित करा',
    gujarati: 'સબ્સ્ક્રિપ્શન્સ પુનઃસ્થાપિત કરો',
    bengali: 'সাবস্ক্রিপশন পুনরুদ্ধার করুন',
    punjabi: 'ਗਾਹਕੀਆਂ ਰੀਸਟੋਰ ਕਰੋ',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ପୁନରୁଦ୍ଧାର କରନ୍ତୁ',
    assamese: 'চাবস্ক্ৰিপশ্বন পুনৰুদ্ধাৰ কৰক',
    konkani: 'वर्गणी परत मेळयात',
    nepali: 'सदस्यता पुनर्स्थापना गर्नुहोस्',
    meitei: 'Subscription restore toubiyu',
    mizo: 'Subscription la let leh rawh',
    kashmiri: 'سبسکرپشن کٔریو بحال',
    ladakhi: 'མངགས་ཉོ་ཕྱིར་གསོའི་བྱོས།',
  );
  String get restoreSubscriptionSubtitle => _localized(
    telugu: 'ఈ ఖాతా కొనుగోళ్లను రీస్టోర్ చేయండి',
    english: 'Restore purchases for this account',
    hindi: 'इस खाते के लिए खरीदारी पुनर्स्थापित करें',
    tamil: 'இந்த கணக்கிற்கான வாங்குதல்களை மீட்டெடுக்கவும்',
    kannada: 'ಈ ಖಾತೆಗಾಗಿ ಖರೀದಿಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಿ',
    malayalam: 'ഈ അക്കൗണ്ടിനായുള്ള വാങ്ങലുകൾ പുനഃസ്ഥാപിക്കുക',
    marathi: 'या खात्यासाठी खरेदी पुनर्संचयित करा',
    gujarati: 'આ એકાઉન્ટ માટે ખરીદીઓ પુનઃસ્થાપિત કરો',
    bengali: 'এই অ্যাকাউন্টের জন্য কেনাকাটা পুনরুদ্ধার করুন',
    punjabi: 'ਇਸ ਖਾਤੇ ਲਈ ਖਰੀਦਦਾਰੀ ਰੀਸਟੋਰ ਕਰੋ',
    odia: 'ଏହି ଖାତା ପାଇଁ କ୍ରୟ ପୁନରୁଦ୍ଧାର କରନ୍ତୁ',
    assamese: 'এই একাউণ্টৰ বাবে ক্ৰয় পুনৰুদ্ধাৰ কৰক',
    konkani: 'ह्या खात्या खातीर खरेदी परत मेळयात',
    nepali: 'यस खाताको लागि खरिदहरू पुनर्स्थापना गर्नुहोस्',
    meitei: 'Account asigi leiraba sing restore toubiyu',
    mizo: 'He account atan hian thil leite la let rawh',
    kashmiri: 'امِ اکاوُنٛٹ باپتھ خٔریٖداری کٔریو بحال',
    ladakhi: 'རྩིས་ཁྲ་འདིའི་ཉོ་སྒྲུབ་ཕྱིར་གསོའི་བྱོས།',
  );

  String get permissionsTitle => strings.permissionsTitle;
  String? get permissionsSubtitle => strings.permissionsOptionSubtitle;

  String get notificationsTitle => strings.notifications;
  String? get notificationsSubtitle => strings.notificationsOptionSubtitle;

  String get shareAppTitle => _localized(
    telugu: 'యాప్ షేర్ చేయండి',
    english: 'Share App',
    hindi: 'ऐप शेयर करें',
    tamil: 'செயலியைப் பகிரவும்',
    kannada: 'ಆಪ್ ಹಂಚಿಕೊಳ್ಳಿ',
    malayalam: 'ആപ്പ് പങ്കിടുക',
    marathi: 'अ‍ॅप शेअर करा',
    gujarati: 'એપ શેર કરો',
    bengali: 'অ্যাপ শেয়ার করুন',
    punjabi: 'ਐਪ ਸਾਂਝੀ ਕਰੋ',
    odia: 'ଆପ୍ ସେୟାର୍ କରନ୍ତୁ',
    assamese: 'এপ শ্বেয়াৰ কৰক',
    konkani: 'अ‍ॅप शेअर करात',
    nepali: 'एप सेयर गर्नुहोस्',
    meitei: 'App share toubiyu',
    mizo: 'App thawn rawh',
    kashmiri: 'ایپ کٔریو شیئر',
    ladakhi: 'App བགོ་འགྲེམས་བྱོས།',
  );
  String get shareAppSubtitle => _localized(
    telugu: 'యాప్ ఐకాన్ మరియు Play Store లింక్ షేర్ చేయండి',
    english: 'Share the app icon and Play Store link',
    hindi: 'ऐप आइकन और Play Store लिंक शेयर करें',
    tamil: 'செயலி ஐகான் மற்றும் Play Store இணைப்பைப் பகிரவும்',
    kannada: 'ಆಪ್ ಐಕಾನ್ ಮತ್ತು Play Store ಲಿಂಕ್ ಹಂಚಿಕೊಳ್ಳಿ',
    malayalam: 'ആപ്പ് ഐക്കണും Play Store ലിങ്കും പങ്കിടുക',
    marathi: 'अ‍ॅप आयकॉन आणि Play Store लिंक शेअर करा',
    gujarati: 'એપ આયકન અને Play Store લિંક શેર કરો',
    bengali: 'অ্যাপ আইকন এবং Play Store লিঙ্ক শেয়ার করুন',
    punjabi: 'ਐਪ ਆਈਕਨ ਅਤੇ Play Store ਲਿੰਕ ਸਾਂਝਾ ਕਰੋ',
    odia: 'ଆପ୍ ଆଇକନ୍ ଏବଂ Play Store ଲିଙ୍କ୍ ସେୟାର୍ କରନ୍ତୁ',
    assamese: 'এপ আইকন আৰু Play Store লিংক শ্বেয়াৰ কৰক',
    konkani: 'अ‍ॅप आयकॉन आनी Play Store लिंक शेअर करात',
    nepali: 'एप आइकन र Play Store लिङ्क सेयर गर्नुहोस्',
    meitei: 'App icon amasung Play Store link share toubiyu',
    mizo: 'App icon leh Play Store link thawn rawh',
    kashmiri: 'ایپ آئیکن تہٕ Play Store لِنک کٔریو شیئر',
    ladakhi: 'App icon དང་ Play Store link བགོ་འགྲེམས་བྱོས།',
  );
  String get shareAppFailedMessage => _localized(
    telugu: 'యాప్ షేర్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    english: 'App share failed. Please try again.',
    hindi: 'ऐप शेयर विफल रहा। कृपया पुनः प्रयास करें।',
    tamil: 'செயலியைப் பகிர முடியவில்லை. மீண்டும் முயல்க.',
    kannada: 'ಆಪ್ ಹಂಚಿಕೆ ವಿಫಲವಾಗಿದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'ആപ്പ് പങ്കിടൽ പരാജയപ്പെട്ടു. വീണ്ടും ശ്രമിക്കുക.',
    marathi: 'अ‍ॅप शेअर करणे अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.',
    gujarati: 'એપ શેર કરવામાં નિષ્ફળ. ફરી પ્રયાસ કરો.',
    bengali: 'অ্যাপ শেয়ার ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
    punjabi: 'ਐਪ ਸਾਂਝਾ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    odia: 'ଆପ୍ ସେୟାର୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
    assamese: 'এপ শ্বেয়াৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
    konkani: 'अ‍ॅप शेअर जालें ना. उपकार करून परत प्रयत्न करात.',
    nepali: 'एप सेयर असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
    meitei: 'App share touba maipak-khide. Amuk hanna hotnabiyu.',
    mizo: 'App thawn a hlawhchham. Khawngaihin ti nawn leh rawh.',
    kashmiri: 'ایپ شیئر کرنہٕ منز ناکامی۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
    ladakhi: 'App བགོ་འགྲེམས་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
  );
  String get accountEmailFallback => _localized(
    telugu: 'ఈ ఖాతాకు ఇమెయిల్ అందుబాటులో లేదు',
    english: 'Email not available for this account',
    hindi: 'इस खाते के लिए ईमेल उपलब्ध नहीं है',
    tamil: 'இந்த கணக்கிற்கு மின்னஞ்சல் கிடைக்கவில்லை',
    kannada: 'ಈ ಖಾತೆಗೆ ಇಮೇಲ್ ಲಭ್ಯವಿಲ್ಲ',
    malayalam: 'ഈ അക്കൗണ്ടിനായി ഇമെയിൽ ലഭ്യമല്ല',
    marathi: 'या खात्यासाठी ईमेल उपलब्ध नाही',
    gujarati: 'આ એકાઉન્ટ માટે ઇમેઇલ ઉપલબ્ધ નથી',
    bengali: 'এই অ্যাকাউন্টের জন্য ইমেল উপলব্ধ নেই',
    punjabi: 'ਇਸ ਖਾਤੇ ਲਈ ਈਮੇਲ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
    odia: 'ଏହି ଖାତା ପାଇଁ ଇମେଲ୍ ଉପଲବ୍ଧ ନାହିଁ',
    assamese: 'এই একাউণ্টৰ বাবে ইমেইল উপলব্ধ নহয়',
    konkani: 'ह्या खात्या खातीर ईमेल उपलब्ध ना',
    nepali: 'यस खाताको लागि इमेल उपलब्ध छैन',
    meitei: 'Account asigi email leite',
    mizo: 'He account tan hian email a awm lo',
    kashmiri: 'امِ اکاوُنٛٹ باپتھ چھُ نہٕ ای میل دستِیاب',
    ladakhi: 'རྩིས་ཁྲ་འདིར་ email མེད།',
  );

  String get helpTitle => strings.helpSupport;
  String? get helpSubtitle => strings.helpSupportSubtitle;
  String get reportIssueTitle => _localized(
    telugu: 'పోస్టర్ లేదా సమస్యను రిపోర్ట్ చేయండి',
    english: 'Report a poster or issue',
    hindi: 'पोस्टर या समस्या की रिपोर्ट करें',
    tamil: 'போஸ்டர் அல்லது சிக்கலைப் புகாரளிக்கவும்',
    kannada: 'ಪೋಸ್ಟರ್ ಅಥವಾ ಸಮಸ್ಯೆಯನ್ನು ವರದಿ ಮಾಡಿ',
    malayalam: 'പോസ്റ്ററോ പ്രശ്നമോ റിപ്പോർട്ട് ചെയ്യുക',
    marathi: 'पोस्टर किंवा समस्येची तक्रार करा',
    gujarati: 'પોસ્ટર અથવા સમસ્યાની જાણ કરો',
    bengali: 'পোস্টার বা সমস্যার রিপোর্ট করুন',
    punjabi: 'ਪੋਸਟਰ ਜਾਂ ਸਮੱਸਿਆ ਦੀ ਰਿਪੋਰਟ ਕਰੋ',
    odia: 'ପୋଷ୍ଟର କିମ୍ବା ସମସ୍ୟା ରିପୋର୍ଟ କରନ୍ତୁ',
    assamese: 'পোষ্টাৰ বা समस्या ৰিপ’ৰ্ট কৰক',
    konkani: 'पोस्टर वा समस्येची तक्रार करात',
    nepali: 'पोस्टर वा समस्या रिपोर्ट गर्नुहोस्',
    meitei: 'Poster natraga afaba nattaba report toubiyu',
    mizo: 'Poster emaw harsatna report rawh',
    kashmiri: 'پوسٹر یا مَسلہٕ کٔریو رپورٹ',
    ladakhi: 'Poster ཡང་ན་དཀའ་ངལ་སྙན་སེང་ཞུས།',
  );
  String get reportIssueSubtitle => _localized(
    telugu: 'తగని పోస్టర్ లేదా యాప్ సమస్యను సపోర్ట్‌కి పంపండి',
    english: 'Send an inappropriate poster or app issue report to support',
    hindi: 'अनुचित पोस्टर या ऐप समस्या की रिपोर्ट सहायता को भेजें',
    tamil: 'பொருத்தமற்ற போஸ்டர் அல்லது செயலி சிக்கல் அறிக்கையை ஆதரவுக்கு அனுப்பவும்',
    kannada: 'ಅನುಚಿತ ಪೋಸ್ಟರ್ ಅಥವಾ ಆಪ್ ಸಮಸ್ಯೆ ವರದಿಯನ್ನು ಬೆಂಬಲಕ್ಕೆ ಕಳುಹಿಸಿ',
    malayalam: 'അനുചിതമായ പോസ്റ്ററോ ആപ്പ് പ്രശ്ന റിപ്പോർട്ടോ പിന്തുണയ്ക്ക് അയയ്ക്കുക',
    marathi: 'अनुचित पोस्टर किंवा अ‍ॅप समस्या अहवाल सपोर्टला पाठवा',
    gujarati: 'અયોગ્ય પોસ્ટર અથવા એપ્લિકેશન સમસ્યાનો રિપોર્ટ સપોર્ટને મોકલો',
    bengali: 'অনুপযুক্ত পোস্টার বা অ্যাপ সমস্যার রিপোর্ট সহায়তায় পাঠান',
    punjabi: 'ਅਣਉਚਿਤ ਪੋਸਟਰ ਜਾਂ ਐਪ ਸਮੱਸਿਆ ਦੀ ਰਿਪੋਰਟ ਸਹਾਇਤਾ ਨੂੰ ਭੇਜੋ',
    odia: 'ଅନୁପଯୁକ୍ତ ପୋଷ୍ଟର କିମ୍ବା ଆପ୍ ସମସ୍ୟା ରିପୋର୍ଟ ସହାୟତାକୁ ପଠାନ୍ତୁ',
    assamese: 'অনুপযুক্ত পোষ্টাৰ বা এপৰ সমস্যাৰ ৰিপ’ৰ্ট সহায়ক দললৈ প্ৰেৰণ কৰক',
    konkani: 'अयोग्य पोस्टर वा अ‍ॅप समस्येचो अहवाल आधाराक धाडात',
    nepali: 'अनुपयुक्त पोस्टर वा एप समस्या रिपोर्ट सहायता टोलीलाई पठाउनुहोस्',
    meitei: 'Yadaba poster natraga app issue report support ta thabiyu',
    mizo: 'Poster tha lo emaw app buaina report support-ah thawn rawh',
    kashmiri: 'نا موزوں پوسٹر یا ایپ مسلہٕ رپورٹ کٔریو سپورٹس روانہٕ',
    ladakhi: 'འོས་མེད་ poster ཡང་ན་ app དཀའ་ངལ་སྙན་སེང་ support ལ་ཐོངས།',
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
    hindi: '''नमस्ते Mana Poster Ai टीम,

मैं एक पोस्टर या ऐप समस्या की रिपोर्ट करना चाहता हूँ।

विवरण:
- समस्या का प्रकार:
- पोस्टर शीर्षक या श्रेणी:
- क्रिएटर आईडी (यदि ज्ञात हो):
- क्या समस्या है:
''',
    tamil: '''வணக்கம் Mana Poster Ai குழு,

நான் ஒரு போஸ்டர் அல்லது செயலி சிக்கலைப் புகாரளிக்க விரும்புகிறேன்.

விவரங்கள்:
- சிக்கல் வகை:
- போஸ்டர் தலைப்பு அல்லது வகை:
- உருவாக்கியவர் ஐடி (தெரிந்தால்):
- என்ன பிரச்சனை:
''',
    kannada: '''ನಮಸ್ಕಾರ Mana Poster Ai ತಂಡ,

ನಾನು ಪೋಸ್ಟರ್ ಅಥವಾ ಆಪ್ ಸಮಸ್ಯೆಯನ್ನು ವರದಿ ಮಾಡಲು ಬಯಸುತ್ತೇನೆ.

ವಿವರಗಳು:
- ಸಮಸ್ಯೆಯ ಪ್ರಕಾರ:
- ಪೋಸ್ಟರ್ ಶೀರ್ಷಿಕೆ ಅಥವಾ ವರ್ಗ:
- ಕ್ರಿಯೇಟರ್ ಐಡಿ (ತಿಳಿದಿದ್ದರೆ):
- ಏನು ಸಮಸ್ಯೆ ಅನಿಸಿದೆ:
''',
    malayalam: '''ഹലോ Mana Poster Ai ടീം,

ഒരു പോസ്റ്ററോ ആപ്പ് പ്രശ്നമോ റിപ്പോർട്ട് ചെയ്യാൻ ഞാൻ ആഗ്രഹിക്കുന്നു.

വിശദാംശങ്ങൾ:
- പ്രശ്ന തരം:
- പോസ്റ്റർ ശീർഷകം അല്ലെങ്കിൽ വിഭാഗം:
- ക്രിയേറ്റർ ഐഡി (അറിയാമെങ്കിൽ):
- എന്താണ് പ്രശ്നം:
''',
    marathi: '''नमस्कार Mana Poster Ai टीम,

मला पोस्टर किंवा अ‍ॅप समस्येची तक्रार करायची आहे.

तपशील:
- समस्येचा प्रकार:
- पोस्टर शीर्षक किंवा श्रेणी:
- क्रिएटर आयडी (माहित असल्यास):
- काय अडचण आहे:
''',
    gujarati: '''નમસ્તે Mana Poster Ai ટીમ,

હું પોસ્ટર અથવા એપ્લિકેશન સમસ્યાની જાણ કરવા માંગુ છું.

વિગતો:
- સમસ્યાનો પ્રકાર:
- પોસ્ટર શીર્ષક અથવા કેટેગરી:
- સર્જક આઈડી (જો જાણીતી હોય તો):
- શું સમસ્યા છે:
''',
    bengali: '''নমস্কার Mana Poster Ai দল,

আমি একটি পোস্টার বা অ্যাপ সমস্যার রিপোর্ট করতে চাই।

বিবরণ:
- সমস্যার ধরন:
- পোস্টার শিরোনাম বা বিভাগ:
- ক্রিয়েটর আইডি (জানা থাকলে):
- সমস্যাটি কী:
''',
    punjabi: '''ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ Mana Poster Ai ਟੀਮ,

ਮੈਂ ਇੱਕ ਪੋਸਟਰ ਜਾਂ ਐਪ ਸਮੱਸਿਆ ਦੀ ਰਿਪੋਰਟ ਕਰਨਾ ਚਾਹੁੰਦਾ ਹਾਂ।

ਵੇਰਵੇ:
- ਸਮੱਸਿਆ ਦੀ ਕਿਸਮ:
- ਪੋਸਟਰ ਸਿਰਲੇਖ ਜਾਂ ਸ਼੍ਰੇਣੀ:
- ਸਿਰਜਣਹਾਰ ਆਈਡੀ (ਜੇਕਰ ਪਤਾ ਹੈ):
- ਕੀ ਸਮੱਸਿਆ ਹੈ:
''',
    odia: '''ନମସ୍କାର Mana Poster Ai ଟିମ୍,

ମୁଁ ଏକ ପୋଷ୍ଟର କିମ୍ବା ଆପ୍ ସମସ୍ୟା ରିପୋର୍ଟ କରିବାକୁ ଚାହୁଁଛି।

ବିବରଣୀ:
- ସମସ୍ୟାର ପ୍ରକାର:
- ପୋଷ୍ଟର ଶୀର୍ଷକ କିମ୍ବା ବର୍ଗ:
- କ୍ରିଏଟର୍ ଆଇଡି (ଯଦି ଜଣାଅଛି):
- କଣ ସମସ୍ୟା ହେଉଛି:
''',
    assamese: '''নমস্কাৰ Mana Poster Ai দল,

মই এটা পোষ্টাৰ বা এপৰ সমস্যা ৰিপ’ৰ্ট কৰিব বিচাৰো।

বিৱৰণ:
- সমস্যাৰ প্ৰকাৰ:
- পোষ্টাৰৰ শিৰোনাম বা বিভাগ:
- ক্ৰিয়েটৰ আইডি (যদি জনা থাকে):
- সমস্যাটো কি:
''',
    konkani: '''नमस्कार Mana Poster Ai टीम,

म्हակा एका पोस्टराची वा अ‍ॅप समस्येची तक्रार करूंक जाय.

तपशील:
- समस्येचो प्रकार:
- पोस्टर माथाळो वा श्रेणी:
- क्रिएटर आयडी (खबर आसल्यार):
- काय अडचण आसा:
''',
    nepali: '''नमस्ते Mana Poster Ai टोली,

म एउटा पोस्टर वा एप समस्या रिपोर्ट गर्न चाहन्छु।

विवरण:
- समस्या प्रकार:
- पोस्टर शीर्षक वा कोटी:
- सिर्जनाकर्ता आईडी (यदि थाहा छ भने):
- के समस्या छ:
''',
    meitei: '''Khurumjari Mana Poster Ai team,

Eina poster natraga app issue ama report touning-e.

Details:
- Issue type:
- Poster title natraga category:
- Creator ID (khanglabadi):
- Kari wathok leibage:
''',
    mizo: '''Chibai Mana Poster Ai team,

Poster emaw app buaina report ka duh e.

Details:
- Harsatna chi:
- Poster thupui emaw category:
- Creator ID (hriat a nih chuan):
- Harsatna awm:
''',
    kashmiri: '''سلام Mana Poster Ai ٹیم،

بہٕ چھُس اکھ پوسٹر یا ایپ مَسلہٕ رپورٹ کرُن یژھان۔

تفصیلات:
- مَسلہٕ کِس قٕسمُک چھُ:
- پوسٹر عنوان یا زمرہ:
- کریئٹر ائی ڈی (اگر معلوٗم آسہِ):
- اصل مَسلہٕ کیا چھُ:
''',
    ladakhi: '''འཚམས་འདྲི་ Mana Poster Ai ཚོགས་པ།

ངས་ poster ཡང་ན་ app དཀའ་ངལ་སྙན་སེང་ཞུ་འདོད།

ཞིབ་ཕྲ།:
- དཀའ་ངལ་རིགས:
- Poster མགོ་བརྗོད་དམ་དབྱེ་ཁག:
- Creator ID (ཤེས་ཚེ):
- དཀའ་ངལ་གང་ཡིན་པ:
''',
  );

  String get aboutTitle => strings.aboutApp;
  String get aboutSubtitle => strings.aboutAppSubtitle;
  String get logoutTitle => strings.logout;
  String get logoutSubtitle => strings.logoutSubtitle;
  String get logoutFailedMessage => _localized(
    telugu: 'లాగౌట్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    english: 'Logout failed. Please try again.',
    hindi: 'लॉगआउट विफल रहा। कृपया पुनः प्रयास करें।',
    tamil: 'வெளியேறுதல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
    kannada: 'ಲಾಗ್‌ಔಟ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'ലോഗൗട്ട് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
    marathi: 'लॉगआउट अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.',
    gujarati: 'લૉગઆઉટ નિષ્ફળ ગયું. ફરી પ્રયાસ કરો.',
    bengali: 'লগআউট ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
    punjabi: 'ਲੌਗਆਉਟ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    odia: 'ଲଗଆଉଟ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
    assamese: 'লগআউট ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
    konkani: 'लॉगआउट अपेशी जालें. उपकार करून परत प्रयत्न करात.',
    nepali: 'लगआउट असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
    meitei: 'Logout touba maipak-khide. Amuk hanna hotnabiyu.',
    mizo: 'Logout a hlawhchham. Khawngaihin ti nawn leh rawh.',
    kashmiri: 'لاگ آوٹ گوو ناکام۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
    ladakhi: 'Logout ཕམ་བྱུང། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
  );
  String get deleteAccountTitle => _localized(
    telugu: 'ఖాతా తొలగించండి',
    english: 'Delete account',
    hindi: 'खाता हटाएं',
    tamil: 'கணக்கை நீக்குக',
    kannada: 'ಖಾತೆ ಅಳಿಸಿ',
    malayalam: 'അക്കൗണ്ട് ഇല്ലാതാക്കുക',
    marathi: 'खाते हटवा',
    gujarati: 'એકાઉન્ટ કાઢી નાખો',
    bengali: 'অ্যাকাউন্ট মুছুন',
    punjabi: 'ਖਾਤਾ ਮਿਟਾਓ',
    odia: 'ଖାତା ବିଲୋପ କରନ୍ତୁ',
    assamese: 'একাউণ্ট মচক',
    konkani: 'खातें काडून उडयात',
    nepali: 'खाता मेटाउनुहोस्',
    meitei: 'Account muthat-u',
    mizo: 'Account thaibo rawh',
    kashmiri: 'اکاوُنٛٹ کٔریو ڈلیٖٹ',
    ladakhi: 'རྩིས་ཁྲ་སུབ་པ།',
  );
  String get deleteAccountSubtitle => _localized(
    telugu: 'ఖాతా మరియు డేటా తొలగింపు అభ్యర్థన ప్రారంభించండి',
    english: 'Start your account and data removal request',
    hindi: 'अपना खाता और डेटा हटाने का अनुरोध शुरू करें',
    tamil: 'உங்கள் கணக்கு மற்றும் தரவு நீக்குதல் கோரிக்கையைத் தொடங்குங்கள்',
    kannada: 'ನಿಮ್ಮ ಖಾತೆ ಮತ್ತು ಡೇಟಾ ತೆಗೆದುಹಾಕುವ ವಿನಂತಿಯನ್ನು ಪ್ರಾರಂಭಿಸಿ',
    malayalam: 'നിങ്ങളുടെ അക്കൗണ്ടും ഡാറ്റയും നീക്കംചെയ്യാനുള്ള അഭ്യർത്ഥന ആരംഭിക്കുക',
    marathi: 'तुमचे खाते आणि डेटा काढण्याची विनंती सुरू करा',
    gujarati: 'તમારું એકાઉન્ટ અને ડેટા દૂર કરવાની વિનંતી શરૂ કરો',
    bengali: 'আপনার অ্যাকাউন্ট এবং ডেটা অপসারণের অনুরোধ শুরু করুন',
    punjabi: 'ਆਪਣਾ ਖਾਤਾ ਅਤੇ ਡਾਟਾ ਹਟਾਉਣ ਦੀ ਬੇਨਤੀ ਸ਼ੁਰੂ ਕਰੋ',
    odia: 'ଆପଣଙ୍କ ଖାତା ଏବଂ ତଥ୍ୟ ହଟାଇବା ଅନୁରୋଧ ଆରମ୍ଭ କରନ୍ତୁ',
    assamese: 'আপোনাৰ একাউণ্ট আৰু তথ্য আঁতৰোৱাৰ অনুৰোধ আৰম্ভ কৰক',
    konkani: 'तुमचें खातें आनी डेटा काडपाची विनंती सुरू करात',
    nepali: 'आफ्नो खाता र डेटा हटाउने अनुरोध सुरु गर्नुहोस्',
    meitei: 'Nangi account amasung data muthatnaba haijaba houbiyu',
    mizo: 'I account leh data paih dilna tan rawh',
    kashmiri: 'پنُن اکاوُنٛٹ تہٕ ڈیٹا ہٹاونٕچ دَرخواست کٔریو شروع',
    ladakhi: 'ཁྱེད་ཀྱི་རྩིས་ཁྲ་དང་གཞི་གྲངས་སུབ་པའི་རེ་འདུན་འགོ་འཛུགས།',
  );
  String get privacyPolicyTitle => _localized(
    telugu: 'ప్రైవసీ పాలసీ',
    english: 'Privacy Policy',
    hindi: 'गोपनीयता नीति',
    tamil: 'தனியுரிமைக் கொள்கை',
    kannada: 'ಗೌಪ್ಯತಾ ನೀತಿ',
    malayalam: 'സ്വകാര്യതാ നയം',
    marathi: 'गोपनीयता धोरण',
    gujarati: 'ગોપનીયતા નીતિ',
    bengali: 'গোপনীয়তা নীতি',
    punjabi: 'ਪਰਦੇਦਾਰੀ ਨੀਤੀ',
    odia: 'ଗୋପନୀୟତା ନୀତି',
    assamese: 'গোপনীয়তা নীতি',
    konkani: 'गोपनीयता धोरण',
    nepali: 'गोपनीयता नीति',
    meitei: 'Privacy Policy',
    mizo: 'Hriattirna leh Dan',
    kashmiri: 'رازداری ہُنٛد اصول',
    ladakhi: 'གསང་རྒྱའི་སྲིད་ཇུས།',
  );
  String get privacyPolicySubtitle => _localized(
    telugu: 'డేటా వినియోగం మరియు ప్రైవసీ',
    english: 'Data usage and privacy',
    hindi: 'डेटा उपयोग और गोपनीयता',
    tamil: 'தரவுப் பயன்பாடு மற்றும் தனியுரிமை',
    kannada: 'ಡೇಟಾ ಬಳಕೆ ಮತ್ತು ಗೌಪ್ಯತೆ',
    malayalam: 'ഡാറ്റ ഉപയോഗവും സ്വകാര്യതയും',
    marathi: 'डेटा वापर आणि गोपनीयता',
    gujarati: 'ડેટા ઉપયોગ અને ગોપનીયતા',
    bengali: 'ডেটা ব্যবহার এবং গোপনীয়তা',
    punjabi: 'ਡਾਟਾ ਵਰਤੋਂ ਅਤੇ ਪਰਦੇਦਾਰੀ',
    odia: 'ତଥ୍ୟ ବ୍ୟବହାର ଏବଂ ଗୋପନୀୟତା',
    assamese: 'তথ্যৰ ব্যৱহাৰ আৰু গোপনীয়তা',
    konkani: 'डेटा वापर आनी गोपनीयता',
    nepali: 'डेटा प्रयोग र गोपनीयता',
    meitei: 'Data sijinaba amasung privacy',
    mizo: 'Data hman dan leh himna',
    kashmiri: 'ڈیٹا اِستعمال تہٕ رازداری',
    ladakhi: 'གཞི་གྲངས་བཀོལ་སྤྱོད་དང་གསང་རྒྱ།',
  );
  String get adPrivacyChoicesTitle => _localized(
    telugu: 'ప్రకటనల ప్రైవసీ ఎంపికలు',
    english: 'Ad privacy choices',
    hindi: 'विज्ञापन गोपनीयता विकल्प',
    tamil: 'விளம்பரத் தனியுரிமைத் தேர்வுகள்',
    kannada: 'ಜಾಹೀರಾತು ಗೌಪ್ಯತೆ ಆಯ್ಕೆಗಳು',
    malayalam: 'പരസ്യ സ്വകാര്യതാ തിരഞ്ഞെടുപ്പുകൾ',
    marathi: 'जाहिरात गोपनीयता पर्याय',
    gujarati: 'જાહેરાત ગોપનીયતા વિકલ્પો',
    bengali: 'বিজ্ঞাপন গোপনীয়তা পছন্দ',
    punjabi: 'ਇਸ਼ਤਿਹਾਰ ਪਰਦੇਦਾਰੀ ਵਿਕਲਪ',
    odia: 'ବିଜ୍ଞାପନ ଗୋପନୀୟତା ବିକଳ୍ପ',
    assamese: 'বিজ্ঞাপনৰ গোপনীয়তাৰ বিকল্প',
    konkani: 'जाहिरात गोपनीयता पर्याय',
    nepali: 'विज्ञापन गोपनीयता विकल्पहरू',
    meitei: 'Ad privacy choices',
    mizo: 'Ad himna duhthlante',
    kashmiri: 'اشتہار رازداری ہِنٛز ترجیحات',
    ladakhi: 'ཁྱབ་བསྒྲགས་གསང་རྒྱའི་གདམ་ཁ།',
  );
  String get adPrivacyChoicesSubtitle => _localized(
    telugu: 'పర్సనలైజ్డ్ యాడ్ సెట్టింగ్స్ నిర్వహించండి',
    english: 'Manage personalized ad settings',
    hindi: 'व्यक्तिगत विज्ञापन सेटिंग्स प्रबंधित करें',
    tamil: 'தனிப்பயனாக்கப்பட்ட விளம்பர அமைப்புகளை நிர்வகிக்கவும்',
    kannada: 'ವೈಯಕ್ತೀಕರಿಸಿದ ಜಾಹೀರಾತು ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ನಿರ್ವಹಿಸಿ',
    malayalam: 'വ്യക്തിഗതമാക്കിയ പരസ്യ ക്രമീകരണങ്ങൾ നിയന്ത്രിക്കുക',
    marathi: 'वैयक्तिकृत जाहिरात सेटिंग्ज व्यवस्थापित करा',
    gujarati: 'વ્યક્તિગત કરેલ જાહેરાત સેટિંગ્સનું સંચાલન કરો',
    bengali: 'ব্যক্তিগতকৃত বিজ্ঞাপন সেটিংস পরিচালনা করুন',
    punjabi: 'ਵਿਅਕਤੀਗਤ ਬਣਾਏ ਗਏ ਵਿਗਿਆਪਨ ਸੈਟਿੰਗਾਂ ਪ੍ਰਬੰਧਿਤ ਕਰੋ',
    odia: 'ବ୍ୟକ୍ତିଗତ ବିଜ୍ଞାପନ ସେଟିଙ୍ଗସ୍ ପରିଚାଳନା କରନ୍ତୁ',
    assamese: 'ব্যক্তিগতকৃত বিজ্ঞাপন ছেটিংছ পৰিচালনা কৰক',
    konkani: 'वैयक्तिक जाहिरात सेटिंग्स वेवस्थापीत करात',
    nepali: 'व्यक्तिगत विज्ञापन सेटिङहरू व्यवस्थापन गर्नुहोस्',
    meitei: 'Personalized ad settings manage toubiyu',
    mizo: 'Ad settings tidanglam rawh',
    kashmiri: 'ذاتی اشتہارات ترتیبات سنبھٲلیو',
    ladakhi: 'རང་གཤིས་ཅན་གྱི་ཁྱབ་བསྒྲགས་བཟོ་སྒྲིག་དོ་དམ་བྱོས།',
  );
  String get legalNoticesTitle => _localized(
    telugu: 'నిబంధనలు & షరతులు',
    english: 'Terms & Conditions',
    hindi: 'नियम एवं शर्तें',
    tamil: 'விதிமுறைகள் & நிபந்தனைகள்',
    kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
    malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും',
    marathi: 'अटी आणि शर्ती',
    gujarati: 'નિયમો અને શરતો',
    bengali: 'নিয়ম ও শর্তাবলী',
    punjabi: 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ ଓ ସର୍ତ୍ତାବଳୀ',
    assamese: 'নিয়ম আৰু চৰ্তাৱলী',
    konkani: 'अटी आनी शर्ती',
    nepali: 'नियम र सर्तहरू',
    meitei: 'Terms & Conditions',
    mizo: 'Hman dan tur leh Dan',
    kashmiri: 'شرائط و ضوابط',
    ladakhi: 'ཆ་རྐྱེན་དང་དོན་ཚན།',
  );
  String get legalNoticesSubtitle => _localized(
    telugu: 'వినియోగం మరియు సబ్‌స్క్రిప్షన్ నిబంధనలు',
    english: 'Usage and subscription terms',
    hindi: 'उपयोग और सदस्यता शर्तें',
    tamil: 'பயன்பாடு மற்றும் சந்தா விதிமுறைகள்',
    kannada: 'ಬಳಕೆ ಮತ್ತು ಚಂದಾದಾರಿಕೆ ನಿಯಮಗಳು',
    malayalam: 'ഉപയോഗ, സബ്സ്ക്രിപ്ഷൻ നിബന്ധനകൾ',
    marathi: 'वापर आणि सदस्यता अटी',
    gujarati: 'વપરાશ અને સબ્સ્ક્રિપ્શન શરતો',
    bengali: 'ব্যবহার এবং সাবস্ক্রিপশন শর্তাবলী',
    punjabi: 'ਵਰਤੋਂ ਅਤੇ ਗਾਹਕੀ ਦੀਆਂ ਸ਼ਰਤਾਂ',
    odia: 'ବ୍ୟବହାର ଏବଂ ସବସ୍କ୍ରିପସନ୍ ସର୍ତ୍ତାବଳୀ',
    assamese: 'ব্যৱহাৰ আৰু চাবস্ক্ৰিপশ্বনৰ নিয়মসমূহ',
    konkani: 'वापर आनी वर्गणी अटी',
    nepali: 'प्रयोग र सदस्यता सर्तहरू',
    meitei: 'Sijinaba amasung subscription terms',
    mizo: 'Hman dan leh subscription dan',
    kashmiri: 'اِستعمال تہٕ سبسکرپشن شرائط',
    ladakhi: 'བཀོལ་སྤྱོད་དང་མངགས་ཉོའི་ཆ་རྐྱེན།',
  );
}
