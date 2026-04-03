import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();

  PermissionSnapshot? _snapshot;
  bool _loading = true;
  bool _openingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSnapshot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSnapshot();
    }
  }

  Future<void> _loadSnapshot() async {
    setState(() => _loading = true);
    final PermissionSnapshot snapshot = await _permissionService.getSnapshot();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _requestPermission(AppPermissionType type) async {
    final PermissionStatus status = await _permissionService.requestSingle(
      type,
    );
    if (!mounted) {
      return;
    }
    await _loadSnapshot();
    if (!mounted) {
      return;
    }

    final _PermissionCopy copy = _copy(context);
    String message;
    if (status.isGranted || status.isLimited) {
      message = copy.permissionGranted(type);
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      message = copy.permissionNeedsSettings(type);
    } else {
      message = copy.permissionDenied(type);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSettings() async {
    setState(() => _openingSettings = true);
    final bool opened = await _permissionService.openSettings();
    if (!mounted) {
      return;
    }
    setState(() => _openingSettings = false);

    final _PermissionCopy copy = _copy(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(opened ? copy.settingsOpened : copy.settingsOpenFailed),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final _PermissionCopy copy = _copy(context);
    final PermissionSnapshot? snapshot = _snapshot;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(copy.settingsTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSnapshot,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: <Widget>[
                    _HeaderCard(copy: copy),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: <Widget>[
                          _PermissionTile(
                            icon: Icons.photo_library_outlined,
                            title: context.strings.photosGallery,
                            description: copy.photosDescription,
                            state: snapshot!.photos,
                            statusLabel: copy.statusLabel(snapshot.photos),
                            statusColor: copy.statusColor(snapshot.photos),
                            actionLabel: copy.actionLabel(snapshot.photos),
                            onAction: () =>
                                _requestPermission(AppPermissionType.photos),
                          ),
                          const Divider(
                            height: 1,
                            indent: 68,
                            endIndent: 14,
                            color: Color(0xFFE2E8F0),
                          ),
                          _PermissionTile(
                            icon: Icons.notifications_none_rounded,
                            title: context.strings.notifications,
                            description: copy.notificationsDescription,
                            state: snapshot.notifications,
                            statusLabel: copy.statusLabel(
                              snapshot.notifications,
                            ),
                            statusColor: copy.statusColor(
                              snapshot.notifications,
                            ),
                            actionLabel: copy.actionLabel(
                              snapshot.notifications,
                            ),
                            onAction: () => _requestPermission(
                              AppPermissionType.notifications,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      copy.settingsHint,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: copy.openSettingsLabel,
                      icon: Icons.settings_outlined,
                      loading: _openingSettings,
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.copy});

  final _PermissionCopy copy;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.security_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            copy.settingsTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            copy.settingsSubtitle,
            style: const TextStyle(
              color: Color(0xFFDCE8FF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
    required this.statusLabel,
    required this.statusColor,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final AppPermissionState state;
  final String statusLabel;
  final Color statusColor;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF1E3A8A), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  state.needsSettings
                      ? _copy(context).settingsRequiredHint
                      : _copy(context).requestHint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionCopy {
  const _PermissionCopy(this.language);

  final AppLanguage language;

  String get settingsTitle => switch (language) {
    AppLanguage.telugu => 'Permissions',
    AppLanguage.hindi => 'Permissions',
    AppLanguage.english => 'Permissions',
  };

  String get settingsSubtitle => switch (language) {
    AppLanguage.telugu =>
      'Gallery మరియు notifications access ని మీరు ఎప్పుడైనా ఇక్కడ నుంచే చూసుకుని update చేసుకోవచ్చు.',
    AppLanguage.hindi =>
      'Gallery और notifications access को आप यहां कभी भी देख और update कर सकते हैं.',
    AppLanguage.english =>
      'You can review and update gallery and notification access anytime from here.',
  };

  String get photosDescription => switch (language) {
    AppLanguage.telugu => 'ఫోటోలు ఎంచుకోవడం మరియు పోస్టర్లు సేవ్ చేయడం కోసం',
    AppLanguage.hindi => 'फोटो चुनने और पोस्टर सेव करने के लिए',
    AppLanguage.english => 'For selecting photos and saving posters',
  };

  String get notificationsDescription => switch (language) {
    AppLanguage.telugu => 'కొత్త టెంప్లేట్స్ మరియు ముఖ్యమైన అప్‌డేట్స్ కోసం',
    AppLanguage.hindi => 'नए टेम्पलेट्स और महत्वपूर्ण अपडेट्स के लिए',
    AppLanguage.english => 'For new templates and important updates',
  };

  String get openSettingsLabel => switch (language) {
    AppLanguage.telugu => 'App Settings ఓపెన్ చేయండి',
    AppLanguage.hindi => 'App Settings खोलें',
    AppLanguage.english => 'Open App Settings',
  };

  String get settingsHint => switch (language) {
    AppLanguage.telugu =>
      'Permissions block అయినా కూడా app continue అవుతుంది. అవసరమైనప్పుడు settings నుండి enable చేసుకోవచ్చు.',
    AppLanguage.hindi =>
      'Permissions block होने पर भी app जारी रहेगा. ज़रूरत पड़ने पर settings से enable कर सकते हैं.',
    AppLanguage.english =>
      'The app can continue even if permissions are off. You can enable them later from settings.',
  };

  String get settingsRequiredHint => switch (language) {
    AppLanguage.telugu =>
      'ఈ access ను మళ్లీ ఇవ్వాలంటే settings నుండి allow చేయాలి.',
    AppLanguage.hindi =>
      'इस access को फिर से देने के लिए settings से allow करना होगा.',
    AppLanguage.english =>
      'To enable this again, please allow it from system settings.',
  };

  String get requestHint => switch (language) {
    AppLanguage.telugu =>
      'ఇప్పుడు అవసరం లేకపోతే తర్వాత కూడా enable చేసుకోవచ్చు.',
    AppLanguage.hindi =>
      'अगर अभी ज़रूरत नहीं है तो बाद में भी enable कर सकते हैं.',
    AppLanguage.english =>
      'If you do not need it now, you can enable it later too.',
  };

  String get settingsOpened => switch (language) {
    AppLanguage.telugu => 'App settings ఓపెన్ అయ్యాయి.',
    AppLanguage.hindi => 'App settings खुल गई हैं.',
    AppLanguage.english => 'App settings opened.',
  };

  String get settingsOpenFailed => switch (language) {
    AppLanguage.telugu => 'Settings ఓపెన్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    AppLanguage.hindi => 'Settings नहीं खुलीं. फिर से कोशिश करें.',
    AppLanguage.english => 'Could not open settings. Please try again.',
  };

  String permissionGranted(AppPermissionType type) => switch (language) {
    AppLanguage.telugu =>
      type == AppPermissionType.photos
          ? 'Photos access అనుమతించబడింది.'
          : 'Notifications అనుమతించబడింది.',
    AppLanguage.hindi =>
      type == AppPermissionType.photos
          ? 'Photos access अनुमति मिल गई.'
          : 'Notifications की अनुमति मिल गई.',
    AppLanguage.english =>
      type == AppPermissionType.photos
          ? 'Photos access granted.'
          : 'Notifications permission granted.',
  };

  String permissionDenied(AppPermissionType type) => switch (language) {
    AppLanguage.telugu =>
      type == AppPermissionType.photos
          ? 'Photos access ఇప్పటికీ ఇవ్వలేదు. తర్వాత settings లో enable చేసుకోవచ్చు.'
          : 'Notifications ఇప్పటికీ off లో ఉన్నాయి. తర్వాత enable చేసుకోవచ్చు.',
    AppLanguage.hindi =>
      type == AppPermissionType.photos
          ? 'Photos access अभी नहीं मिला. बाद में settings से enable कर सकते हैं.'
          : 'Notifications अभी off हैं. बाद में enable कर सकते हैं.',
    AppLanguage.english =>
      type == AppPermissionType.photos
          ? 'Photos access is still off. You can enable it later from settings.'
          : 'Notifications are still off. You can enable them later from settings.',
  };

  String permissionNeedsSettings(AppPermissionType type) => switch (language) {
    AppLanguage.telugu =>
      type == AppPermissionType.photos
          ? 'Photos access settings నుండి allow చేయాలి.'
          : 'Notifications ను settings నుండి allow చేయాలి.',
    AppLanguage.hindi =>
      type == AppPermissionType.photos
          ? 'Photos access settings से allow करना होगा.'
          : 'Notifications को settings से allow करना होगा.',
    AppLanguage.english =>
      type == AppPermissionType.photos
          ? 'Photos access needs to be enabled from settings.'
          : 'Notifications need to be enabled from settings.',
  };

  String statusLabel(AppPermissionState state) {
    if (state.isGranted) {
      return switch (language) {
        AppLanguage.telugu => 'Allowed',
        AppLanguage.hindi => 'Allowed',
        AppLanguage.english => 'Allowed',
      };
    }
    if (state.needsSettings) {
      return switch (language) {
        AppLanguage.telugu => 'Settings అవసరం',
        AppLanguage.hindi => 'Settings ज़रूरी',
        AppLanguage.english => 'Needs Settings',
      };
    }
    return switch (language) {
      AppLanguage.telugu => 'Allow చేయలేదు',
      AppLanguage.hindi => 'Allow नहीं',
      AppLanguage.english => 'Not Allowed',
    };
  }

  Color statusColor(AppPermissionState state) {
    if (state.isGranted) {
      return const Color(0xFF15803D);
    }
    if (state.needsSettings) {
      return const Color(0xFFB45309);
    }
    return const Color(0xFFB91C1C);
  }

  String actionLabel(AppPermissionState state) {
    if (state.needsSettings) {
      return switch (language) {
        AppLanguage.telugu => 'మళ్లీ చూడండి',
        AppLanguage.hindi => 'फिर देखें',
        AppLanguage.english => 'Check Again',
      };
    }
    if (state.isGranted) {
      return switch (language) {
        AppLanguage.telugu => 'మళ్లీ చెక్ చేయండి',
        AppLanguage.hindi => 'फिर जांचें',
        AppLanguage.english => 'Check Again',
      };
    }
    return switch (language) {
      AppLanguage.telugu => 'Allow చేయండి',
      AppLanguage.hindi => 'Allow करें',
      AppLanguage.english => 'Allow',
    };
  }
}

_PermissionCopy _copy(BuildContext context) =>
    _PermissionCopy(context.currentLanguage);
