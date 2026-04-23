import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class LandingPagePanel extends StatelessWidget {
  const LandingPagePanel({
    super.key,
    required this.sections,
    required this.onVisibilityChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onOpenPreview,
    required this.onResetChanges,
  });

  final List<LandingSectionDraft> sections;
  final void Function(String sectionId, bool visible) onVisibilityChanged;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;
  final VoidCallback onOpenPreview;
  final VoidCallback onResetChanges;

  @override
  Widget build(BuildContext context) {
    final int visibleCount = sections
        .where((LandingSectionDraft section) => section.visible)
        .length;

    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Landing Page Management',
          subtitle:
              'Control section visibility and order for Mana Poster landing flow. This is local draft state only.',
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SummaryChip(
                      label: 'Sections',
                      value: '${sections.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Visible',
                      value: '$visibleCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryChip(label: 'Draft Mode', value: 'Local'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: onOpenPreview,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B34E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onResetChanges,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Reset Changes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3A4570),
                      side: const BorderSide(color: Color(0xFFD5DDEE)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Section Visibility & Order',
          subtitle:
              'Use toggle and up/down controls to shape landing section sequence.',
          child: Column(
            children: sections.asMap().entries.map((
              MapEntry<int, LandingSectionDraft> entry,
            ) {
              final int index = entry.key;
              final LandingSectionDraft section = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == sections.length - 1 ? 0 : 10,
                ),
                child: _SectionRow(
                  section: section,
                  canMoveUp: index > 0,
                  canMoveDown: index < sections.length - 1,
                  onMoveUp: () => onMoveUp(index),
                  onMoveDown: () => onMoveDown(index),
                  onVisibilityChanged: (bool value) =>
                      onVisibilityChanged(section.id, value),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.section,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onVisibilityChanged,
  });

  final LandingSectionDraft section;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFE3E9F7)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              section.label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF283251),
              ),
            ),
          ),
          IconButton(
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            tooltip: 'Move up',
          ),
          IconButton(
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            tooltip: 'Move down',
          ),
          const SizedBox(width: 8),
          Switch(
            value: section.visible,
            activeThumbColor: const Color(0xFF5A31E1),
            onChanged: onVisibilityChanged,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DEFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6A7191)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D245E),
            ),
          ),
        ],
      ),
    );
  }
}
