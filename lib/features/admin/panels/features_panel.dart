import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

const List<String> _featureIconOptions = <String>[
  'edit',
  'language',
  'share',
  'calendar',
  'premium',
  'speed',
];

class FeaturesPanel extends StatelessWidget {
  const FeaturesPanel({
    super.key,
    required this.features,
    required this.visible,
    required this.onVisibilityChanged,
    required this.onAddFeature,
    required this.onRemoveFeature,
    required this.onMoveFeatureUp,
    required this.onMoveFeatureDown,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onIconChanged,
  });

  final List<FeatureDraft> features;
  final bool visible;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onAddFeature;
  final ValueChanged<int> onRemoveFeature;
  final ValueChanged<int> onMoveFeatureUp;
  final ValueChanged<int> onMoveFeatureDown;
  final void Function(int index, String value) onTitleChanged;
  final void Function(int index, String value) onDescriptionChanged;
  final void Function(int index, String value) onIconChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Features Management',
          subtitle: 'Edit feature cards shown in landing app highlights.',
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
              ...features.asMap().entries.map((
                MapEntry<int, FeatureDraft> entry,
              ) {
                final int index = entry.key;
                final FeatureDraft feature = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == features.length - 1 ? 0 : 10,
                  ),
                  child: _FeatureEditorCard(
                    feature: feature,
                    onTitleChanged: (String value) =>
                        onTitleChanged(index, value),
                    onDescriptionChanged: (String value) =>
                        onDescriptionChanged(index, value),
                    onIconChanged: (String value) =>
                        onIconChanged(index, value),
                    onRemove: () => onRemoveFeature(index),
                    onMoveUp: index > 0 ? () => onMoveFeatureUp(index) : null,
                    onMoveDown: index < features.length - 1
                        ? () => onMoveFeatureDown(index)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddFeature,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Feature'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Feature Preview',
          subtitle: 'Compact live preview from local draft state.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth < 700 ? 1 : 2;
              final double cardWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: features
                    .map(
                      (FeatureDraft feature) => SizedBox(
                        width: cardWidth,
                        child: _FeaturePreviewCard(feature: feature),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeatureEditorCard extends StatelessWidget {
  const _FeatureEditorCard({
    required this.feature,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onIconChanged,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final FeatureDraft feature;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onIconChanged;
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
                  key: ValueKey<String>('feature-title-${feature.title}'),
                  initialValue: feature.title,
                  onChanged: onTitleChanged,
                  decoration: _fieldDecoration('Feature title'),
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
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>(
                    'feature-description-${feature.description}',
                  ),
                  initialValue: feature.description,
                  onChanged: onDescriptionChanged,
                  decoration: _fieldDecoration('Short description'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: _featureIconOptions.contains(feature.iconKey)
                      ? feature.iconKey
                      : _featureIconOptions.first,
                  onChanged: (String? value) {
                    if (value != null) {
                      onIconChanged(value);
                    }
                  },
                  items: _featureIconOptions
                      .map(
                        (String option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  decoration: _fieldDecoration('Icon'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturePreviewCard extends StatelessWidget {
  const _FeaturePreviewCard({required this.feature});

  final FeatureDraft feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF9F8FF),
        border: Border.all(color: const Color(0xFFE7E2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            feature.iconKey.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A31E1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2543),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feature.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F6B88)),
          ),
        ],
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
