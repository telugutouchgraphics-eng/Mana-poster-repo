import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
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

class _PermissionsScreenState extends State<PermissionsScreen>
    with AppLanguageStateMixin {
  final PermissionService _service = PermissionService();
  bool _loading = false;

  Future<void> _completeFlowAndGoHome() async {
    await AppFlowService.markPermissionsStepHandled();
    await AppFlowService.markInitialSetupCompleted();
    final String nextRoute =
        await AppFlowService.resolveAuthenticatedEntryRoute();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  Future<void> _grant() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    await _service.requestEssentialPermissions();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    await _completeFlowAndGoHome();
  }

  Future<void> _continueLater() async {
    await _completeFlowAndGoHome();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final cs = Theme.of(context).colorScheme;

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
                    Divider(height: 18, color: cs.outlineVariant),
                    _PermissionRow(
                      icon: Icons.photo_camera_outlined,
                      title: strings.localized(
                        telugu: 'కెమెరా',
                        english: 'Camera',
                      ),
                    ),
                    Divider(height: 18, color: cs.outlineVariant),
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
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
