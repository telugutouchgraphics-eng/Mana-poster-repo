import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class FaqPanel extends StatelessWidget {
  const FaqPanel({
    super.key,
    required this.faqItems,
    required this.visible,
    required this.onVisibilityChanged,
    required this.onAddFaq,
    required this.onRemoveFaq,
    required this.onMoveFaqUp,
    required this.onMoveFaqDown,
    required this.onQuestionChanged,
    required this.onAnswerChanged,
  });

  final List<FaqDraft> faqItems;
  final bool visible;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onAddFaq;
  final ValueChanged<int> onRemoveFaq;
  final ValueChanged<int> onMoveFaqUp;
  final ValueChanged<int> onMoveFaqDown;
  final void Function(int index, String value) onQuestionChanged;
  final void Function(int index, String value) onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'FAQ Management',
          subtitle: 'Edit question and answer list for landing FAQ section.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Visible',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF5E6884)),
              ),
              Switch(value: visible, onChanged: onVisibilityChanged),
            ],
          ),
          child: Column(
            children: <Widget>[
              ...faqItems.asMap().entries.map((MapEntry<int, FaqDraft> entry) {
                final int index = entry.key;
                final FaqDraft item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == faqItems.length - 1 ? 0 : 10,
                  ),
                  child: _FaqEditorCard(
                    item: item,
                    onQuestionChanged: (String value) =>
                        onQuestionChanged(index, value),
                    onAnswerChanged: (String value) =>
                        onAnswerChanged(index, value),
                    onRemove: () => onRemoveFaq(index),
                    onMoveUp: index > 0 ? () => onMoveFaqUp(index) : null,
                    onMoveDown: index < faqItems.length - 1
                        ? () => onMoveFaqDown(index)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddFaq,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add FAQ'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'FAQ Preview',
          subtitle:
              'Accordion-style preview generated from local draft values.',
          child: _FaqPreview(faqItems: faqItems),
        ),
      ],
    );
  }
}

class _FaqEditorCard extends StatelessWidget {
  const _FaqEditorCard({
    required this.item,
    required this.onQuestionChanged,
    required this.onAnswerChanged,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final FaqDraft item;
  final ValueChanged<String> onQuestionChanged;
  final ValueChanged<String> onAnswerChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFE3E9F7)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('faq-question-${item.question}'),
                  initialValue: item.question,
                  onChanged: onQuestionChanged,
                  decoration: _fieldDecoration('Question'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onMoveUp,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton(
                onPressed: onMoveDown,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFF9D3A4A),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey<String>('faq-answer-${item.answer}'),
            initialValue: item.answer,
            onChanged: onAnswerChanged,
            minLines: 2,
            maxLines: 3,
            decoration: _fieldDecoration('Answer'),
          ),
        ],
      ),
    );
  }
}

class _FaqPreview extends StatelessWidget {
  const _FaqPreview({required this.faqItems});

  final List<FaqDraft> faqItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: faqItems
          .map(
            (FaqDraft item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFF7F9FF),
                border: Border.all(color: const Color(0xFFE2E8F7)),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  item.question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2748),
                  ),
                ),
                children: <Widget>[
                  Text(
                    item.answer,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF606B89),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFDDE3F3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFDDE3F3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFF6A46F5)),
    ),
  );
}
