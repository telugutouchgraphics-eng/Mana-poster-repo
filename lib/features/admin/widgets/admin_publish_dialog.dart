import 'package:flutter/material.dart';

Future<bool?> showAdminPublishDialog({
  required BuildContext context,
  required List<String> changedSections,
  required List<String> summaryLines,
  required bool hasUnsavedChanges,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Publish Local Draft'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                hasUnsavedChanges
                    ? 'Review local draft updates before publish simulation.'
                    : 'No pending edits detected. You can still publish current draft state.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF5A6582),
                ),
              ),
              const SizedBox(height: 12),
              if (changedSections.isNotEmpty) ...<Widget>[
                const Text(
                  'Changed Sections',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: changedSections
                      .map(
                        (String section) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EEFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            section,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B2BC2),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              const Text(
                'Change Notes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...summaryLines
                  .take(6)
                  .map(
                    (String line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $line',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF4F5B79),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Confirm Publish'),
          ),
        ],
      );
    },
  );
}

Future<bool?> showAdminRevertDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Revert Draft'),
        content: const Text(
          'This will reset current local draft changes to seed content. Continue?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF5A6582)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revert'),
          ),
        ],
      );
    },
  );
}
