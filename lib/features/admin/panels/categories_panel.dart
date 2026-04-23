import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class CategoriesPanel extends StatelessWidget {
  const CategoriesPanel({
    super.key,
    required this.categories,
    required this.visible,
    required this.onVisibilityChanged,
    required this.onAddCategory,
    required this.onRemoveCategory,
    required this.onMoveCategoryUp,
    required this.onMoveCategoryDown,
    required this.onTitleChanged,
    required this.onSubtitleChanged,
    required this.onBadgeChanged,
  });

  final List<CategoryDraft> categories;
  final bool visible;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onAddCategory;
  final ValueChanged<int> onRemoveCategory;
  final ValueChanged<int> onMoveCategoryUp;
  final ValueChanged<int> onMoveCategoryDown;
  final void Function(int index, String value) onTitleChanged;
  final void Function(int index, String value) onSubtitleChanged;
  final void Function(int index, String value) onBadgeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Categories Management',
          subtitle: 'Manage landing category cards and badges.',
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
              ...categories.asMap().entries.map((
                MapEntry<int, CategoryDraft> entry,
              ) {
                final int index = entry.key;
                final CategoryDraft category = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == categories.length - 1 ? 0 : 10,
                  ),
                  child: _CategoryEditorCard(
                    category: category,
                    onTitleChanged: (String value) =>
                        onTitleChanged(index, value),
                    onSubtitleChanged: (String value) =>
                        onSubtitleChanged(index, value),
                    onBadgeChanged: (String value) =>
                        onBadgeChanged(index, value),
                    onRemove: () => onRemoveCategory(index),
                    onMoveUp: index > 0 ? () => onMoveCategoryUp(index) : null,
                    onMoveDown: index < categories.length - 1
                        ? () => onMoveCategoryDown(index)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddCategory,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Category'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Categories Preview',
          subtitle: 'Live card preview from local draft data.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories
                .map(
                  (CategoryDraft category) =>
                      _CategoryPreviewCard(category: category),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryEditorCard extends StatelessWidget {
  const _CategoryEditorCard({
    required this.category,
    required this.onTitleChanged,
    required this.onSubtitleChanged,
    required this.onBadgeChanged,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final CategoryDraft category;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSubtitleChanged;
  final ValueChanged<String> onBadgeChanged;
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
                  key: ValueKey<String>('category-title-${category.title}'),
                  initialValue: category.title,
                  onChanged: onTitleChanged,
                  decoration: _fieldDecoration('Category title'),
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
            key: ValueKey<String>('category-subtitle-${category.subtitle}'),
            initialValue: category.subtitle,
            onChanged: onSubtitleChanged,
            decoration: _fieldDecoration('Subtitle/description'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey<String>('category-badge-${category.badge}'),
            initialValue: category.badge,
            onChanged: onBadgeChanged,
            decoration: _fieldDecoration('Badge text'),
          ),
        ],
      ),
    );
  }
}

class _CategoryPreviewCard extends StatelessWidget {
  const _CategoryPreviewCard({required this.category});

  final CategoryDraft category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFF6FA), Color(0xFFF3F3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFE8E2F8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFECE7FF),
              ),
              child: Text(
                category.badge,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5030C8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2645),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.subtitle,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6A86)),
            ),
          ],
        ),
      ),
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
