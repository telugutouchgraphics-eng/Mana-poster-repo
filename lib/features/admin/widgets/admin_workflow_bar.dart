import 'package:flutter/material.dart';

class AdminWorkflowBar extends StatelessWidget {
  const AdminWorkflowBar({
    super.key,
    required this.statusLabel,
    required this.unsavedChanges,
    required this.lastEditedText,
    required this.syncStatusLabel,
    required this.syncStatusColor,
    required this.syncStatusIsError,
    required this.isLoadingDraft,
    required this.isSavingDraft,
    required this.publishStatusLabel,
    required this.publishStatusColor,
    required this.publishStatusIsError,
    required this.isPublishing,
    required this.onPreview,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onRevertDraft,
  });

  final String statusLabel;
  final bool unsavedChanges;
  final String lastEditedText;
  final String syncStatusLabel;
  final Color syncStatusColor;
  final bool syncStatusIsError;
  final bool isLoadingDraft;
  final bool isSavingDraft;
  final String publishStatusLabel;
  final Color publishStatusColor;
  final bool publishStatusIsError;
  final bool isPublishing;
  final VoidCallback onPreview;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onRevertDraft;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool compact = width < 760;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAF8)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1421418E),
              blurRadius: 16,
              offset: Offset(0, 8),
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
                _StatusPill(
                  label: statusLabel,
                  color: _statusColor(statusLabel),
                ),
                _StatusPill(
                  label: unsavedChanges ? 'Unsaved changes' : 'Draft saved',
                  color: unsavedChanges
                      ? const Color(0xFFC14B2C)
                      : const Color(0xFF1D8A47),
                  icon: unsavedChanges
                      ? Icons.edit_note_rounded
                      : Icons.check_circle_rounded,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F3)),
                  ),
                  child: Text(
                    lastEditedText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF66708A),
                    ),
                  ),
                ),
                _StatusPill(
                  label: syncStatusLabel,
                  color: syncStatusColor,
                  icon: isSavingDraft
                      ? Icons.sync_rounded
                      : isLoadingDraft
                      ? Icons.cloud_download_rounded
                      : syncStatusIsError
                      ? Icons.error_outline_rounded
                      : Icons.cloud_done_rounded,
                ),
                _StatusPill(
                  label: publishStatusLabel,
                  color: publishStatusColor,
                  icon: isPublishing
                      ? Icons.publish_rounded
                      : publishStatusIsError
                      ? Icons.error_outline_rounded
                      : Icons.verified_rounded,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              unsavedChanges
                  ? 'Preview is connected to the current local draft. Save or publish only after reviewing changed sections.'
                  : 'Current preview matches the latest local draft. Publish still remains simulated in this frontend-only phase.',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64708B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.preview_rounded),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(compact ? 144 : 0, 44),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isLoadingDraft || isSavingDraft
                      ? null
                      : onSaveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isSavingDraft ? 'Saving...' : 'Save Draft'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(compact ? 144 : 0, 44),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isPublishing ? null : onPublish,
                  icon: const Icon(Icons.publish_rounded),
                  label: Text(isPublishing ? 'Publishing...' : 'Publish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A31E1),
                    foregroundColor: Colors.white,
                    minimumSize: Size(compact ? 144 : 0, 44),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRevertDraft,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Revert Draft'),
                  style: TextButton.styleFrom(
                    minimumSize: Size(compact ? 144 : 0, 44),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String statusLabel) {
  if (statusLabel.toLowerCase().contains('published')) {
    return const Color(0xFF177A3E);
  }
  if (statusLabel.toLowerCase().contains('draft')) {
    return const Color(0xFF5A31E1);
  }
  return const Color(0xFF2D3A66);
}
