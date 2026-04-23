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
    final String nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute();
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
                      icon: Icons.photo_camera_outlined,
                      title: strings.localized(
                        telugu: 'కెమెరా',
                        english: 'Camera',
                      ),
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
