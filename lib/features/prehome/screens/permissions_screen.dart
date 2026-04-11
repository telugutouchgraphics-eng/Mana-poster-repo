import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/widgets/flow_screen_header.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _service = PermissionService();
  bool _loading = false;

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _grant() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    final PermissionSnapshot snapshot = await _service
        .requestEssentialPermissions();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    final _PermissionFlowCopy copy = _PermissionFlowCopy(
      context.currentLanguage,
    );

    if (snapshot.allGranted) {
      await AppFlowService.markPermissionsStepHandled();
      await AppFlowService.markInitialSetupCompleted();
      _showMessage(copy.grantedMessage);
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    if (snapshot.anyNeedsSettings) {
      _showMessage(copy.settingsRequiredMessage);
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  copy.settingsBottomSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copy.settingsBottomSheetSubtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: copy.openSettingsLabel,
                  icon: Icons.settings_outlined,
                  onPressed: () async {
                    final bool opened = await _service.openSettings();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                    _showMessage(
                      opened
                          ? copy.settingsOpenedMessage
                          : copy.settingsOpenFailedMessage,
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(copy.notNowLabel),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    _showMessage(copy.deniedMessage);
  }

  Future<void> _continueLater() async {
    await AppFlowService.markPermissionsStepHandled();
    await AppFlowService.markInitialSetupCompleted();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      body: GradientShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            FlowScreenHeader(
              title: strings.permissionsTitle,
              subtitle: strings.permissionsSubtitle,
              badge: '04',
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    _PermissionRow(
                      icon: Icons.photo_library_outlined,
                      title: strings.photosGallery,
                    ),
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _PermissionRow(
                      icon: Icons.notifications_none_rounded,
                      title: strings.notifications,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.enableLaterHint,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: strings.allowLabel,
              loading: _loading,
              onPressed: _grant,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _loading ? null : _continueLater,
              child: Text(strings.laterLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionFlowCopy {
  const _PermissionFlowCopy(this.language);

  final AppLanguage language;

  String get grantedMessage => switch (language) {
    AppLanguage.telugu =>
      'Permissions allow అయ్యాయి. ఇప్పుడు app continue అవుతుంది.',
    AppLanguage.hindi => 'Permissions allow हो गईं. अब app जारी रहेगा.',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam => 'Permissions granted. The app will continue now.',
  };

  String get deniedMessage => switch (language) {
    AppLanguage.telugu =>
      'ఇప్పుడే permissions ఇవ్వకపోయినా పరవాలేదు. తర్వాత settings లో enable చేసుకోవచ్చు.',
    AppLanguage.hindi =>
      'अभी permissions नहीं दीं तो भी ठीक है. बाद में settings से enable कर सकते हैं.',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam =>
      'That is okay. You can enable permissions later from settings.',
  };

  String get settingsRequiredMessage => switch (language) {
    AppLanguage.telugu => 'కొన్ని permissions settings నుండి allow చేయాలి.',
    AppLanguage.hindi => 'कुछ permissions को settings से allow करना होगा.',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam =>
      'Some permissions now need to be enabled from settings.',
  };

  String get settingsBottomSheetTitle => switch (language) {
    AppLanguage.telugu => 'Settings నుండి allow చేయండి',
    AppLanguage.hindi => 'Settings से allow करें',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam => 'Allow from Settings',
  };

  String get settingsBottomSheetSubtitle => switch (language) {
    AppLanguage.telugu =>
      'మీరు permission ను block చేసినట్లుంది. Gallery లేదా notifications access కావాలంటే app settings లో enable చేయండి.',
    AppLanguage.hindi =>
      'लगता है permission block हो गई है. Gallery या notifications के लिए app settings में enable करें.',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam =>
      'It looks like a permission was blocked. Enable it from app settings whenever you need gallery or notifications.',
  };

  String get openSettingsLabel => switch (language) {
    AppLanguage.telugu => 'App Settings ఓపెన్ చేయండి',
    AppLanguage.hindi => 'App Settings खोलें',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam => 'Open App Settings',
  };

  String get settingsOpenedMessage => switch (language) {
    AppLanguage.telugu => 'App settings ఓపెన్ అయ్యాయి.',
    AppLanguage.hindi => 'App settings खुल गई हैं.',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam => 'App settings opened.',
  };

  String get settingsOpenFailedMessage => switch (language) {
    AppLanguage.telugu => 'Settings ఓపెన్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
    AppLanguage.hindi => 'Settings नहीं खुलीं. फिर से कोशिश करें.',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam => 'Could not open settings. Please try again.',
  };

  String get notNowLabel => switch (language) {
    AppLanguage.telugu => 'ఇప్పుడు వద్దు',
    AppLanguage.hindi => 'अभी नहीं',
    AppLanguage.english || AppLanguage.tamil || AppLanguage.kannada || AppLanguage.malayalam => 'Not Now',
  };
}



