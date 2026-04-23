import 'package:flutter/material.dart';

enum AdminPreviewDeviceMode { desktop, tablet, mobile }

class AdminPreviewToolbar extends StatelessWidget {
  const AdminPreviewToolbar({
    super.key,
    required this.deviceMode,
    required this.statusLabel,
    required this.unsavedChanges,
    required this.onBackToEditor,
    required this.onRefresh,
    required this.onDeviceModeChanged,
    required this.onOpenSection,
  });

  final AdminPreviewDeviceMode deviceMode;
  final String statusLabel;
  final bool unsavedChanges;
  final VoidCallback onBackToEditor;
  final VoidCallback onRefresh;
  final ValueChanged<AdminPreviewDeviceMode> onDeviceModeChanged;
  final ValueChanged<String> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool compact = width < 900;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E9F7)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12213A80),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onBackToEditor,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Editor'),
              ),
              SegmentedButton<AdminPreviewDeviceMode>(
                segments: const <ButtonSegment<AdminPreviewDeviceMode>>[
                  ButtonSegment<AdminPreviewDeviceMode>(
                    value: AdminPreviewDeviceMode.desktop,
                    icon: Icon(Icons.desktop_windows_rounded),
                    label: Text('Desktop'),
                  ),
                  ButtonSegment<AdminPreviewDeviceMode>(
                    value: AdminPreviewDeviceMode.tablet,
                    icon: Icon(Icons.tablet_mac_rounded),
                    label: Text('Tablet'),
                  ),
                  ButtonSegment<AdminPreviewDeviceMode>(
                    value: AdminPreviewDeviceMode.mobile,
                    icon: Icon(Icons.phone_android_rounded),
                    label: Text('Mobile'),
                  ),
                ],
                selected: <AdminPreviewDeviceMode>{deviceMode},
                showSelectedIcon: false,
                onSelectionChanged: (Set<AdminPreviewDeviceMode> values) {
                  final AdminPreviewDeviceMode? value = values.isNotEmpty
                      ? values.first
                      : null;
                  if (value != null) {
                    onDeviceModeChanged(value);
                  }
                },
              ),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
              PopupMenuButton<String>(
                onSelected: onOpenSection,
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'hero',
                        child: Text('Open Hero in Editor'),
                      ),
                      PopupMenuItem<String>(
                        value: 'features',
                        child: Text('Open Features in Editor'),
                      ),
                      PopupMenuItem<String>(
                        value: 'categories',
                        child: Text('Open Categories in Editor'),
                      ),
                      PopupMenuItem<String>(
                        value: 'showcase-posters',
                        child: Text('Open Showcase in Editor'),
                      ),
                      PopupMenuItem<String>(
                        value: 'faq',
                        child: Text('Open FAQ in Editor'),
                      ),
                      PopupMenuItem<String>(
                        value: 'footer-contact',
                        child: Text('Open Footer in Editor'),
                      ),
                    ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD8E1F0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.open_in_new_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Open Section',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _StatusChip(
                label: statusLabel,
                color: statusLabel.toLowerCase().contains('published')
                    ? const Color(0xFF1B8445)
                    : const Color(0xFF5A31E1),
              ),
              _StatusChip(
                label: unsavedChanges ? 'Unsaved draft' : 'Saved draft',
                color: unsavedChanges
                    ? const Color(0xFFC14B2C)
                    : const Color(0xFF1B8445),
              ),
              _StatusChip(
                label: compact
                    ? 'Live local preview'
                    : 'Live preview reflects current local draft instantly',
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
