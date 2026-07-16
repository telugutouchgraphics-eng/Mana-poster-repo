import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

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
    location: AppPermissionState(
      type: AppPermissionType.location,
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
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(AppSnackBar.build(content: Text(message)));
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
      ..hideCurrentTopSnackBar()
      ..showTopSnackBar(
        AppSnackBar.build(
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
                onAction: () => _handlePermissionAction(_snapshot.photos),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.photo_camera_outlined,
                title: context.strings.localized(
                  telugu: 'Ã Â°â€¢Ã Â±â€ Ã Â°Â®Ã Â±â€ Ã Â°Â°Ã Â°Â¾',
                  english: 'Camera',
                ),
                statusLabel: copy.statusLabel(_snapshot.camera),
                statusColor: copy.statusColor(_snapshot.camera),
                actionLabel: copy.actionLabel(_snapshot.camera),
                onAction: () => _handlePermissionAction(_snapshot.camera),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.notifications_none_rounded,
                title: context.strings.notifications,
                statusLabel: copy.statusLabel(_snapshot.notifications),
                statusColor: copy.statusColor(_snapshot.notifications),
                actionLabel: copy.actionLabel(_snapshot.notifications),
                onAction: () =>
                    _handlePermissionAction(_snapshot.notifications),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _PermissionTile(
                icon: Icons.location_on_outlined,
                title: context.strings.localized(
                  telugu: 'Ã Â°Â²Ã Â±Å Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±Â',
                  english: 'Location',
                ),
                statusLabel: copy.statusLabel(_snapshot.location),
                statusColor: copy.statusColor(_snapshot.location),
                actionLabel: copy.actionLabel(_snapshot.location),
                onAction: () => _handlePermissionAction(_snapshot.location),
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

  Future<void> _handlePermissionAction(AppPermissionState state) async {
    if (state.needsSettings) {
      await _openSettings();
      return;
    }
    if (state.isGranted) {
      await _loadSnapshot();
      return;
    }
    await _requestPermission(state.type);
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

  String get settingsTitle =>
      _localized(telugu: 'à°…à°¨à±à°®à°¤à±à°²à±', english: 'Permissions');

  String get openSettingsLabel => _localized(
    telugu:
        'à°¯à°¾à°ªà± à°¸à±†à°Ÿà±à°Ÿà°¿à°‚à°—à±à°¸à± à°¤à±†à°°à°µà°‚à°¡à°¿',
    english: 'Open App Settings',
  );

  String get fallbackInfo => _localized(
    telugu: 'స్టేటస్ రిఫ్రెష్ కాలేదు. కిందికి లాగి మళ్లీ ప్రయత్నించండి.',
    english: 'Could not refresh status. Pull down to retry.',
  );

  String get settingsOpened => _localized(
    telugu: 'యాప్ సెట్టింగ్స్ తెరుచుకున్నాయి.',
    english: 'App settings opened.',
  );

  String get settingsOpenFailed => _localized(
    telugu: 'సెట్టింగ్స్ తెరవలేకపోయాం. ఇంకోసారి ప్రయత్నించండి.',
    english: 'Could not open settings. Please try again.',
  );

  String permissionGranted(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu:
          'Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹Ã Â°Â²Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°â€¡Ã Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â±Â.',
      english: 'Photos access granted.',
    ),
    AppPermissionType.camera => _localized(
      telugu:
          'Ã Â°â€¢Ã Â±â€ Ã Â°Â®Ã Â±â€ Ã Â°Â°Ã Â°Â¾ Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°â€¡Ã Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â±Â.',
      english: 'Camera access granted.',
    ),
    AppPermissionType.notifications => _localized(
      telugu:
          'Ã Â°Â¨Ã Â±â€¹Ã Â°Å¸Ã Â°Â¿Ã Â°Â«Ã Â°Â¿Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°â€¡Ã Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â±Â.',
      english: 'Notifications access granted.',
    ),
    AppPermissionType.location => _localized(
      telugu:
          'Ã Â°Â²Ã Â±Å Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°â€¡Ã Â°Å¡Ã Â±ÂÃ Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â±Â.',
      english: 'Location access granted.',
    ),
  };

  String permissionDenied(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu:
          'Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹Ã Â°Â²Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°â€ Ã Â°Â«Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english: 'Photos access is off.',
    ),
    AppPermissionType.camera => _localized(
      telugu:
          'Ã Â°â€¢Ã Â±â€ Ã Â°Â®Ã Â±â€ Ã Â°Â°Ã Â°Â¾ Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°â€ Ã Â°Â«Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english: 'Camera access is off.',
    ),
    AppPermissionType.notifications => _localized(
      telugu:
          'Ã Â°Â¨Ã Â±â€¹Ã Â°Å¸Ã Â°Â¿Ã Â°Â«Ã Â°Â¿Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°â€ Ã Â°Â«Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°Â¨Ã Â±ÂÃ Â°Â¨Ã Â°Â¾Ã Â°Â¯Ã Â°Â¿.',
      english: 'Notifications are off.',
    ),
    AppPermissionType.location => _localized(
      telugu:
          'Ã Â°Â²Ã Â±Å Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°â€ Ã Â°Â«Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€°Ã Â°â€šÃ Â°Â¦Ã Â°Â¿.',
      english: 'Location access is off.',
    ),
  };

  String permissionNeedsSettings(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => _localized(
      telugu:
          'Ã Â°Â¸Ã Â±â€ Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±ÂÃ Â°Â¸Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°Â«Ã Â±â€¹Ã Â°Å¸Ã Â±â€¹Ã Â°Â²Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
      english: 'Allow photos from settings.',
    ),
    AppPermissionType.camera => _localized(
      telugu:
          'Ã Â°Â¸Ã Â±â€ Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±ÂÃ Â°Â¸Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€¢Ã Â±â€ Ã Â°Â®Ã Â±â€ Ã Â°Â°Ã Â°Â¾ Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
      english: 'Allow camera from settings.',
    ),
    AppPermissionType.notifications => _localized(
      telugu:
          'Ã Â°Â¸Ã Â±â€ Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±ÂÃ Â°Â¸Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°Â¨Ã Â±â€¹Ã Â°Å¸Ã Â°Â¿Ã Â°Â«Ã Â°Â¿Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±ÂÃ Â°Â²Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
      english: 'Allow notifications from settings.',
    ),
    AppPermissionType.location => _localized(
      telugu:
          'Ã Â°Â¸Ã Â±â€ Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±ÂÃ Â°Â¸Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°Â²Ã Â±Å Ã Â°â€¢Ã Â±â€¡Ã Â°Â·Ã Â°Â¨Ã Â±Â Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿.',
      english: 'Allow location from settings.',
    ),
  };

  String statusLabel(AppPermissionState state) {
    if (state.isGranted) {
      return _localized(
        telugu:
            'Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°Â¾Ã Â°Â°Ã Â±Â',
        english: 'Allowed',
      );
    }
    if (state.needsSettings) {
      return _localized(
        telugu:
            'Ã Â°Â¸Ã Â±â€ Ã Â°Å¸Ã Â±ÂÃ Â°Å¸Ã Â°Â¿Ã Â°â€šÃ Â°â€”Ã Â±ÂÃ Â°Â¸Ã Â±ÂÃ¢â‚¬Å’Ã Â°Â²Ã Â±â€¹ Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â°â€šÃ Â°Â¡Ã Â°Â¿',
        english: 'Allow from Settings',
      );
    }
    return _localized(
      telugu: 'Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿ Ã Â°Â²Ã Â±â€¡Ã Â°Â¦Ã Â±Â',
      english: 'Not allowed',
    );
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
      return _localized(telugu: 'Ã Â°Å¡Ã Â±â€šÃ Â°Â¡Ã Â±Â', english: 'Check');
    }
    return _localized(
      telugu: 'Ã Â°â€¦Ã Â°Â¨Ã Â±ÂÃ Â°Â®Ã Â°Â¤Ã Â°Â¿Ã Â°â€šÃ Â°Å¡Ã Â±Â',
      english: 'Allow',
    );
  }

  String _localized({required String telugu, required String english}) =>
      AppStrings(language).localized(telugu: telugu, english: english);
}

_PermissionCopy _copy(BuildContext context) =>
    _PermissionCopy(context.currentLanguage);
