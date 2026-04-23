import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/data/models/admin_audit_log.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class ActivityHistoryPanel extends StatelessWidget {
  const ActivityHistoryPanel({
    super.key,
    required this.logs,
    required this.loading,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onViewDetails,
    this.statusText,
  });

  final List<AdminAuditLog> logs;
  final bool loading;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onRefresh;
  final ValueChanged<AdminAuditLog> onViewDetails;
  final String? statusText;

  static const Map<String, List<String>> filterActionTypes =
      <String, List<String>>{
        'all': <String>[],
        'saves': <String>[
          AdminAuditActionType.draftSaved,
          AdminAuditActionType.saveFailed,
        ],
        'publish': <String>[
          AdminAuditActionType.published,
          AdminAuditActionType.publishFailed,
        ],
        'media': <String>[
          AdminAuditActionType.mediaUploaded,
          AdminAuditActionType.mediaDeleted,
          AdminAuditActionType.mediaUpdated,
          AdminAuditActionType.uploadFailed,
          AdminAuditActionType.deleteFailed,
        ],
        'restore': <String>[
          AdminAuditActionType.versionRestored,
          AdminAuditActionType.restoreFailed,
        ],
        'auth': <String>[
          AdminAuditActionType.loginSuccess,
          AdminAuditActionType.logout,
        ],
      };

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Activity History',
          subtitle:
              'Recent admin actions recorded from Firebase-backed save, publish, media, restore, and auth flows.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ...filterActionTypes.keys.map(
                    (String filter) => ChoiceChip(
                      label: Text(_filterLabel(filter)),
                      selected: selectedFilter == filter,
                      onSelected: (_) => onFilterChanged(filter),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
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
                const SizedBox(height: 10),
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
        if (logs.isEmpty)
          const AdminPanelCard(
            title: 'No Activity Yet',
            subtitle:
                'Admin actions will appear here after saves, publishes, media changes, restores, and auth events.',
            child: SizedBox.shrink(),
          )
        else
          ...logs.map(
            (AdminAuditLog log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityLogCard(
                log: log,
                onViewDetails: () => onViewDetails(log),
              ),
            ),
          ),
      ],
    );
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case 'saves':
        return 'Saves';
      case 'publish':
        return 'Publish';
      case 'media':
        return 'Media';
      case 'restore':
        return 'Restore';
      case 'auth':
        return 'Auth';
      default:
        return 'All';
    }
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.log, required this.onViewDetails});

  final AdminAuditLog log;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return AdminPanelCard(
      title: _actionLabel(log.actionType),
      subtitle: '${_formatDateTime(log.createdAt)} by ${_actorLabel(log)}',
      trailing: _StatusBadge(status: log.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            log.summary.trim().isEmpty ? log.message : log.summary,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF4E5875),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _MetaPill(label: log.entityType),
              if (log.entityId.trim().isNotEmpty)
                _MetaPill(label: log.entityId),
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _actionLabel(String actionType) {
    return actionType
        .split('_')
        .where((String part) => part.isNotEmpty)
        .map((String part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _actorLabel(AdminAuditLog log) {
    if (log.actorEmail.trim().isNotEmpty) {
      return log.actorEmail;
    }
    if (log.actorUserId.trim().isNotEmpty) {
      return log.actorUserId;
    }
    return 'admin';
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String yyyy = local.year.toString();
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String min = local.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool failed = status == AdminAuditStatus.failed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: failed ? const Color(0xFFFFEEEE) : const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        failed ? 'Failed' : 'Success',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: failed ? const Color(0xFFC43D3D) : const Color(0xFF1D8A47),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5EAF8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5D6783),
        ),
      ),
    );
  }
}
