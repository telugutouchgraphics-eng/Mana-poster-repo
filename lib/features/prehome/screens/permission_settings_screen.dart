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
    final PermissionSnapshot effectiveSnapshot = _snapshot;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          copy.settingsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadSnapshot,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              if (_loadUsedFallback) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(
                    copy.fallbackInfo,
                    style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_loading) ...<Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ],
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
                      state: effectiveSnapshot.photos,
                      statusLabel: copy.statusLabel(effectiveSnapshot.photos),
                      statusColor: copy.statusColor(effectiveSnapshot.photos),
                      actionLabel: copy.actionLabel(effectiveSnapshot.photos),
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
                      icon: Icons.photo_camera_outlined,
                      title: context.strings.localized(
                        telugu: 'కెమెరా',
                        english: 'Camera',
                      ),
                      description: copy.cameraDescription,
                      state: effectiveSnapshot.camera,
                      statusLabel: copy.statusLabel(effectiveSnapshot.camera),
                      statusColor: copy.statusColor(effectiveSnapshot.camera),
                      actionLabel: copy.actionLabel(effectiveSnapshot.camera),
                      onAction: () =>
                          _requestPermission(AppPermissionType.camera),
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
                      state: effectiveSnapshot.notifications,
                      statusLabel: copy.statusLabel(
                        effectiveSnapshot.notifications,
                      ),
                      statusColor: copy.statusColor(
                        effectiveSnapshot.notifications,
                      ),
                      actionLabel: copy.actionLabel(
                        effectiveSnapshot.notifications,
                      ),
                      onAction: () =>
                          _requestPermission(AppPermissionType.notifications),
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
            Color(0xFF4C1D95),
            Color(0xFF6D28D9),
            Color(0xFF9333EA),
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

  String get settingsTitle => 'Permissions';
  String get settingsSubtitle =>
      'You can review and update gallery, camera, and notification access anytime from here.';
  String get photosDescription => 'For selecting photos and saving posters';
  String get cameraDescription => 'For directly capturing photos from camera';
  String get notificationsDescription =>
      'For new templates and important updates';
  String get openSettingsLabel => 'Open App Settings';
  String get settingsHint =>
      'The app can continue even if permissions are off. You can enable them later from settings.';
  String get fallbackInfo =>
      'Permission status took too long to load. Use the actions below to re-check permissions.';
  String get settingsRequiredHint =>
      'To enable this again, please allow it from system settings.';
  String get requestHint =>
      'If you do not need it now, you can enable it later too.';
  String get settingsOpened => 'App settings opened.';
  String get settingsOpenFailed => 'Could not open settings. Please try again.';

  String permissionGranted(AppPermissionType type) => switch (type) {
    AppPermissionType.photos => 'Photos access granted.',
    AppPermissionType.camera => 'Camera access granted.',
    AppPermissionType.notifications => 'Notifications permission granted.',
  };

  String permissionDenied(AppPermissionType type) => switch (type) {
    AppPermissionType.photos =>
      'Photos access is still off. You can enable it later from settings.',
    AppPermissionType.camera =>
      'Camera access is still off. You can enable it later from settings.',
    AppPermissionType.notifications =>
      'Notifications are still off. You can enable them later from settings.',
  };

  String permissionNeedsSettings(AppPermissionType type) => switch (type) {
    AppPermissionType.photos =>
      'Photos access needs to be enabled from settings.',
    AppPermissionType.camera =>
      'Camera access needs to be enabled from settings.',
    AppPermissionType.notifications =>
      'Notifications need to be enabled from settings.',
  };

  String statusLabel(AppPermissionState state) {
    if (state.isGranted) {
      return 'Allowed';
    }
    if (state.needsSettings) {
      return 'Needs Settings';
    }
    return 'Not Allowed';
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
      return 'Check Again';
    }
    return 'Allow';
  }
}

_PermissionCopy _copy(BuildContext context) =>
    _PermissionCopy(context.currentLanguage);
