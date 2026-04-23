import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

const List<String> _accessOptions = <String>['Free', 'Premium'];

class ShowcasePostersPanel extends StatelessWidget {
  const ShowcasePostersPanel({
    super.key,
    required this.posters,
    required this.visible,
    required this.onVisibilityChanged,
    required this.onAddPoster,
    required this.onRemovePoster,
    required this.onMovePosterUp,
    required this.onMovePosterDown,
    required this.onTitleChanged,
    required this.onSubtitleChanged,
    required this.onCategoryChanged,
    required this.onAccessChanged,
    required this.onImagePathChanged,
    required this.onSelectImageFromMedia,
  });

  final List<ShowcasePosterDraft> posters;
  final bool visible;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onAddPoster;
  final ValueChanged<int> onRemovePoster;
  final ValueChanged<int> onMovePosterUp;
  final ValueChanged<int> onMovePosterDown;
  final void Function(int index, String value) onTitleChanged;
  final void Function(int index, String value) onSubtitleChanged;
  final void Function(int index, String value) onCategoryChanged;
  final void Function(int index, String value) onAccessChanged;
  final void Function(int index, String value) onImagePathChanged;
  final ValueChanged<int> onSelectImageFromMedia;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Showcase Posters Management',
          subtitle:
              'Manage poster title, tag, free/premium label and image asset path.',
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
              ...posters.asMap().entries.map((
                MapEntry<int, ShowcasePosterDraft> entry,
              ) {
                final int index = entry.key;
                final ShowcasePosterDraft poster = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == posters.length - 1 ? 0 : 10,
                  ),
                  child: _PosterEditorCard(
                    poster: poster,
                    onTitleChanged: (String value) =>
                        onTitleChanged(index, value),
                    onSubtitleChanged: (String value) =>
                        onSubtitleChanged(index, value),
                    onCategoryChanged: (String value) =>
                        onCategoryChanged(index, value),
                    onAccessChanged: (String value) =>
                        onAccessChanged(index, value),
                    onImagePathChanged: (String value) =>
                        onImagePathChanged(index, value),
                    onSelectImageFromMedia: () => onSelectImageFromMedia(index),
                    onRemove: () => onRemovePoster(index),
                    onMoveUp: index > 0 ? () => onMovePosterUp(index) : null,
                    onMoveDown: index < posters.length - 1
                        ? () => onMovePosterDown(index)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddPoster,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Showcase Poster'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Showcase Preview',
          subtitle: 'Gallery-style live preview from local draft data.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth < 720 ? 1 : 2;
              final double cardWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: posters
                    .map(
                      (ShowcasePosterDraft poster) => SizedBox(
                        width: cardWidth,
                        child: _PosterPreviewCard(poster: poster),
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

class _PosterEditorCard extends StatelessWidget {
  const _PosterEditorCard({
    required this.poster,
    required this.onTitleChanged,
    required this.onSubtitleChanged,
    required this.onCategoryChanged,
    required this.onAccessChanged,
    required this.onImagePathChanged,
    required this.onSelectImageFromMedia,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ShowcasePosterDraft poster;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSubtitleChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onAccessChanged;
  final ValueChanged<String> onImagePathChanged;
  final VoidCallback onSelectImageFromMedia;
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
                  key: ValueKey<String>('showcase-title-${poster.title}'),
                  initialValue: poster.title,
                  onChanged: onTitleChanged,
                  decoration: _fieldDecoration('Poster title'),
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
            key: ValueKey<String>('showcase-subtitle-${poster.subtitle}'),
            initialValue: poster.subtitle,
            onChanged: onSubtitleChanged,
            decoration: _fieldDecoration('Subtitle'),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>(
                    'showcase-category-${poster.categoryTag}',
                  ),
                  initialValue: poster.categoryTag,
                  onChanged: onCategoryChanged,
                  decoration: _fieldDecoration('Category tag'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: _accessOptions.contains(poster.accessLabel)
                      ? poster.accessLabel
                      : _accessOptions.first,
                  onChanged: (String? value) {
                    if (value != null) {
                      onAccessChanged(value);
                    }
                  },
                  items: _accessOptions
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  decoration: _fieldDecoration('Label'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey<String>('showcase-image-${poster.imageAssetPath}'),
            initialValue: poster.imageAssetPath,
            onChanged: onImagePathChanged,
            decoration: _fieldDecoration('Image asset path'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onSelectImageFromMedia,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Select from Media Library'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterPreviewCard extends StatelessWidget {
  const _PosterPreviewCard({required this.poster});

  final ShowcasePosterDraft poster;

  @override
  Widget build(BuildContext context) {
    final bool premium = poster.accessLabel.toLowerCase() == 'premium';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E9F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 120,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                colors: <Color>[
                  Color(0xFFFFE6EE),
                  Color(0xFFEAE9FF),
                  Color(0xFFE2F3FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                poster.imageAssetPath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF425176)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFEFF3FF),
                      ),
                      child: Text(
                        poster.categoryTag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3558AA),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: premium
                            ? const Color(0xFFFFF1DA)
                            : const Color(0xFFE8F8EE),
                      ),
                      child: Text(
                        poster.accessLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: premium
                              ? const Color(0xFF8C5B04)
                              : const Color(0xFF1C7B42),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  poster.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2646),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  poster.subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5D6886),
                  ),
                ),
              ],
            ),
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
