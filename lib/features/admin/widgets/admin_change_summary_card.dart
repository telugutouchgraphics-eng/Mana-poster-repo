import 'package:flutter/material.dart';

class AdminChangeSummaryCard extends StatelessWidget {
  const AdminChangeSummaryCard({
    super.key,
    required this.changedSections,
    required this.changeSummaryLines,
    required this.unsavedChanges,
  });

  final List<String> changedSections;
  final List<String> changeSummaryLines;
  final bool unsavedChanges;

  @override
  Widget build(BuildContext context) {
    final int visibleLines = changeSummaryLines
        .where((String line) => line.trim().isNotEmpty)
        .length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF8)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12213A80),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Change Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2646),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unsavedChanges
                ? 'Recent draft updates are listed here before preview or publish simulation.'
                : 'No pending edits. This summary will fill as sections are changed.',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64708B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _SummaryPill(
                label:
                    '${changedSections.length} section${changedSections.length == 1 ? '' : 's'}',
                color: const Color(0xFF4B2BC2),
              ),
              _SummaryPill(
                label: '$visibleLines note${visibleLines == 1 ? '' : 's'}',
                color: const Color(0xFF2563EB),
              ),
              _SummaryPill(
                label: unsavedChanges ? 'Needs review' : 'Clean state',
                color: unsavedChanges
                    ? const Color(0xFFC14B2C)
                    : const Color(0xFF1D8A47),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (changedSections.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFF8FAFF),
                border: Border.all(color: const Color(0xFFE5EAF5)),
              ),
              child: const Text(
                'Start editing any panel to see meaningful section-level change notes here.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF65718B),
                  height: 1.45,
                ),
              ),
            )
          else ...<Widget>[
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE8ECF7)),
            const SizedBox(height: 10),
            ...changeSummaryLines.map(
              (String line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6A46F5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF4C5878),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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
