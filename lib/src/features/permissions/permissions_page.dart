import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mana_poster/src/core/constants/app_routes.dart';
import 'package:mana_poster/src/core/localization/app_strings.dart';
import 'package:mana_poster/src/core/localization/localization_controller.dart';
import 'package:mana_poster/src/core/session/session_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsPage extends ConsumerStatefulWidget {
  const PermissionsPage({super.key});

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage> {
  bool _isRequesting = false;

  Future<void> _requestAndContinue() async {
    if (_isRequesting) {
      return;
    }
    setState(() => _isRequesting = true);
    try {
      await Permission.photos.request();
      await Permission.notification.request();
    } catch (_) {
      // Ignore errors and continue safely.
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
        ref.read(sessionControllerProvider.notifier).completePermissions();
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(localizationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.text(language, AppStrings.permissionsTitle)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.text(language, AppStrings.permissionsDescription),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _PermissionItem(
              icon: Icons.photo_library_outlined,
              title: AppStrings.text(
                language,
                AppStrings.permissionsPhotosTitle,
              ),
              subtitle: AppStrings.text(
                language,
                AppStrings.permissionsPhotosSubtitle,
              ),
            ),
            const SizedBox(height: 12),
            _PermissionItem(
              icon: Icons.notifications_none,
              title: AppStrings.text(
                language,
                AppStrings.permissionsNotificationsTitle,
              ),
              subtitle: AppStrings.text(
                language,
                AppStrings.permissionsNotificationsSubtitle,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestAndContinue,
                child: Text(
                  _isRequesting
                      ? 'Please wait...'
                      : AppStrings.text(language, AppStrings.continueLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
