import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen>
    with WidgetsBindingObserver, AppLanguageStateMixin {
  final PermissionService _permissionService = PermissionService();

  PermissionSnapshot _snapshot = const PermissionSnapshot(
    photos: AppPermissionState(
      type: AppPermissionType.photos,
      status: PermissionStatus.denied,
    ),
    camera: AppPermissionState(
      type: AppPermissionType.camera,
      status: PermissionStatus.denied,
    ),
    notifications: AppPermissionState(
      type: AppPermissionType.notifications,
      status: PermissionStatus.denied,
    ),
  );
  bool _loading = true;
  bool _openingSettings = false;
  bool _loadUsedFallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _snapshot = _permissionService.defaultSnapshot();
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
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final PermissionSnapshot snapshot = await _permissionService
          .getSnapshot()
          .timeout(
            const Duration(seconds: 4),
            onTimeout: _permissionService.defaultSnapshot,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _loadUsedFallback = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = _permissionService.defaultSnapshot();
        _loading = false;
        _loadUsedFallback = true;
      });
    }
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          copy.settingsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadSnapshot,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: <Widget>[
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (_loadUsedFallback)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    copy.fallbackInfo,
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              _PermissionTile(
                icon: Icons.photo_library_outlined,
                title: context.strings.photosGallery,
                statusLabel: copy.statusLabel(_snapshot.photos),
                statusColor: copy.statusColor(_snapshot.photos),
                actionLabel: copy.actionLabel(_snapshot.photos),
                onAction: () => _requestPermission(AppPermissionType.photos),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.photo_camera_outlined,
                title: context.strings.localized(
                  telugu: 'కెమెరా',
                  english: 'Camera',
                ),
                statusLabel: copy.statusLabel(_snapshot.camera),
                statusColor: copy.statusColor(_snapshot.camera),
                actionLabel: copy.actionLabel(_snapshot.camera),
                onAction: () => _requestPermission(AppPermissionType.camera),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.notifications_none_rounded,
                title: context.strings.notifications,
                statusLabel: copy.statusLabel(_snapshot.notifications),
                statusColor: copy.statusColor(_snapshot.notifications),
                actionLabel: copy.actionLabel(_snapshot.notifications),
                onAction: () =>
                    _requestPermission(AppPermissionType.notifications),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openingSettings ? null : _openSettings,
                icon: _openingSettings
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.settings_outlined),
                label: Text(copy.openSettingsLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Icon(icon, color: const Color(0xFF334155), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          statusLabel,
          style: TextStyle(
            fontSize: 13.5,
            color: statusColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
    );
  }
}

class _PermissionCopy {
  const _PermissionCopy(this.language);

  final AppLanguage language;

  String get settingsTitle => switch (language) {
    AppLanguage.telugu => 'అనుమతులు',
    AppLanguage.hindi => 'अनुमतियां',
    AppLanguage.english => 'Permissions',
    AppLanguage.tamil => 'அனுமதிகள்',
    AppLanguage.kannada => 'ಅನುಮತಿಗಳು',
    AppLanguage.malayalam => 'അനുമതികൾ',
  };

  String get openSettingsLabel => switch (language) {
    AppLanguage.telugu => 'యాప్ సెట్టింగ్స్ తెరువు',
    AppLanguage.hindi => 'ऐप सेटिंग्स खोलें',
    AppLanguage.english => 'Open App Settings',
    AppLanguage.tamil => 'ஆப் அமைப்புகளை திற',
    AppLanguage.kannada => 'ಆಪ್ ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆಯಿರಿ',
    AppLanguage.malayalam => 'ആപ്പ് ക്രമീകരണങ്ങൾ തുറക്കുക',
  };

  String get fallbackInfo => switch (language) {
    AppLanguage.telugu =>
      'స్టేటస్ రిఫ్రెష్ కాలేదు. కిందికి లాగి మళ్లీ ప్రయత్నించండి.',
    AppLanguage.hindi => 'स्टेटस रीफ्रेश नहीं हुआ। नीचे खींचकर फिर कोशिश करें।',
    AppLanguage.english => 'Could not refresh status. Pull down to retry.',
    AppLanguage.tamil =>
      'நிலை புதுப்பிக்கப்படவில்லை. கீழே இழுத்து மீண்டும் முயற்சிக்கவும்.',
    AppLanguage.kannada => 'ಸ್ಥಿತಿ ನವೀಕರಿಸಲಿಲ್ಲ. ಕೆಳಗೆ ಎಳೆದು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    AppLanguage.malayalam =>
      'സ്ഥിതി പുതുക്കാനായില്ല. താഴേക്ക് വലിച്ച് വീണ്ടും ശ്രമിക്കുക.',
  };

  String get settingsOpened => switch (language) {
    AppLanguage.telugu => 'యాప్ సెట్టింగ్స్ తెరుచుకున్నాయి.',
    AppLanguage.hindi => 'ऐप सेटिंग्स खुल गई हैं।',
    AppLanguage.english => 'App settings opened.',
    AppLanguage.tamil => 'ஆப் அமைப்புகள் திறக்கப்பட்டன.',
    AppLanguage.kannada => 'ಆಪ್ ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆಯಲಾಗಿದೆ.',
    AppLanguage.malayalam => 'ആപ്പ് ക്രമീകരണങ്ങൾ തുറന്നു.',
  };

  String get settingsOpenFailed => switch (language) {
    AppLanguage.telugu => 'సెట్టింగ్స్ తెరవలేకపోయాం. ఇంకోసారి ప్రయత్నించండి.',
    AppLanguage.hindi => 'सेटिंग्स नहीं खुलीं। फिर कोशिश करें।',
    AppLanguage.english => 'Could not open settings. Please try again.',
    AppLanguage.tamil =>
      'அமைப்புகளை திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    AppLanguage.kannada => 'ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆಯಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    AppLanguage.malayalam => 'ക്രമീകരണങ്ങൾ തുറക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
  };

  String permissionGranted(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu: 'ఫోటోలు అనుమతి ఇచ్చారు.',
      english: 'Photos access granted.',
    ),
    AppPermissionType.camera => _localized(
      telugu: 'కెమెరా అనుమతి ఇచ్చారు.',
      english: 'Camera access granted.',
    ),
    AppPermissionType.notifications => _localized(
      telugu: 'నోటిఫికేషన్ అనుమతి ఇచ్చారు.',
      english: 'Notifications access granted.',
    ),
  };

  String permissionDenied(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu: 'ఫోటోలు అనుమతి ఆఫ్‌లో ఉంది.',
      english: 'Photos access is off.',
    ),
    AppPermissionType.camera => _localized(
      telugu: 'కెమెరా అనుమతి ఆఫ్‌లో ఉంది.',
      english: 'Camera access is off.',
    ),
    AppPermissionType.notifications => _localized(
      telugu: 'నోటిఫికేషన్లు ఆఫ్‌లో ఉన్నాయి.',
      english: 'Notifications are off.',
    ),
  };

  String permissionNeedsSettings(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu: 'సెట్టింగ్స్‌లో ఫోటోలు అనుమతించండి.',
      english: 'Allow photos from settings.',
    ),
    AppPermissionType.camera => _localized(
      telugu: 'సెట్టింగ్స్‌లో కెమెరా అనుమతించండి.',
      english: 'Allow camera from settings.',
    ),
    AppPermissionType.notifications => _localized(
      telugu: 'సెట్టింగ్స్‌లో నోటిఫికేషన్లు అనుమతించండి.',
      english: 'Allow notifications from settings.',
    ),
  };

  String statusLabel(AppPermissionState state) {
    if (state.isGranted) {
      return _localized(telugu: 'అనుమతించారు', english: 'Allowed');
    }
    if (state.needsSettings) {
      return _localized(
        telugu: 'సెట్టింగ్స్‌లో అనుమతించండి',
        english: 'Allow from Settings',
      );
    }
    return _localized(telugu: 'అనుమతి లేదు', english: 'Not allowed');
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
    if (state.needsSettings || state.isGranted) {
      return _localized(telugu: 'చూడు', english: 'Check');
    }
    return _localized(telugu: 'అనుమతించు', english: 'Allow');
  }

  String _localized({required String telugu, required String english}) =>
      switch (language) {
        AppLanguage.telugu => telugu,
        AppLanguage.hindi => english,
        AppLanguage.english => english,
        AppLanguage.tamil => english,
        AppLanguage.kannada => english,
        AppLanguage.malayalam => english,
      };
}

_PermissionCopy _copy(BuildContext context) =>
    _PermissionCopy(context.currentLanguage);
