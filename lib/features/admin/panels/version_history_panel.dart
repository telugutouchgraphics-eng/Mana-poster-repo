import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/data/models/backend_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class VersionHistoryPanel extends StatelessWidget {
  const VersionHistoryPanel({
    super.key,
    required this.versions,
    required this.loading,
    required this.restoringVersionId,
    required this.currentPublishedVersion,
    required this.onRefresh,
    required this.onViewDetails,
    required this.onRestore,
    this.statusText,
  });

  final List<LandingVersionSnapshot> versions;
  final bool loading;
  final String? restoringVersionId;
  final int currentPublishedVersion;
  final VoidCallback onRefresh;
  final ValueChanged<LandingVersionSnapshot> onViewDetails;
  final ValueChanged<LandingVersionSnapshot> onRestore;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Version History',
          subtitle:
              'Published snapshots are stored here. Restore a previous version back into draft for editing.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: loading ? null : onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh Versions'),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if ((statusText ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  statusText!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5D6783),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (versions.isEmpty)
          const AdminPanelCard(
            title: 'No Versions Yet',
            subtitle:
                'No published snapshots found. Publish at least once to create version history.',
            child: SizedBox.shrink(),
          )
        else
          ...versions.map(
            (LandingVersionSnapshot version) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VersionCard(
                version: version,
                restoring: restoringVersionId == version.versionId,
                isCurrentPublished:
                    version.versionNumber == currentPublishedVersion,
                onViewDetails: () => onViewDetails(version),
                onRestore: () => onRestore(version),
              ),
            ),
          ),
      ],
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.restoring,
    required this.isCurrentPublished,
    required this.onViewDetails,
    required this.onRestore,
  });

  final LandingVersionSnapshot version;
  final bool restoring;
  final bool isCurrentPublished;
  final VoidCallback onViewDetails;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final DateTime local = version.publishedAt.toLocal();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    final String date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

    return AdminPanelCard(
      title: 'Version v${version.versionNumber}',
      subtitle:
          '$date $hh:$mm • by ${version.publishedByUserId.isEmpty ? 'admin' : version.publishedByUserId}',
      trailing: isCurrentPublished
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Current Published',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D8A47),
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (version.note.trim().isNotEmpty)
            Text(
              version.note,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4E5875),
                height: 1.45,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Source Draft: ${version.sourceDraftId} (v${version.sourceDraftVersion})',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF66708B)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Details'),
              ),
              ElevatedButton.icon(
                onPressed: restoring ? null : onRestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A31E1),
                  foregroundColor: Colors.white,
                ),
                icon: restoring
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.restore_rounded),
                label: Text(restoring ? 'Restoring...' : 'Restore to Draft'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
