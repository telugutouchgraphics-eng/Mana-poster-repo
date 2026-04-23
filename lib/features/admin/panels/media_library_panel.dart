import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

const List<String> _mediaTypes = <String>[
  'all',
  'hero',
  'showcase',
  'icon',
  'banner',
  'footer',
  'misc',
];

class MediaLibraryPanel extends StatelessWidget {
  const MediaLibraryPanel({
    super.key,
    required this.items,
    required this.searchQuery,
    required this.selectedType,
    required this.selectedIndex,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onSelectItem,
    required this.onUploadMedia,
    required this.onRefreshMedia,
    required this.onRemoveItem,
    required this.onCopyPath,
    required this.onNameChanged,
    required this.onPathChanged,
    required this.onItemTypeChanged,
    required this.isUploading,
    required this.isRefreshing,
    this.statusText,
  });

  final List<MediaItemDraft> items;
  final String searchQuery;
  final String selectedType;
  final int selectedIndex;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onSelectItem;
  final VoidCallback onUploadMedia;
  final VoidCallback onRefreshMedia;
  final ValueChanged<int> onRemoveItem;
  final ValueChanged<String> onCopyPath;
  final void Function(int index, String value) onNameChanged;
  final void Function(int index, String value) onPathChanged;
  final void Function(int index, String value) onItemTypeChanged;
  final bool isUploading;
  final bool isRefreshing;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final List<_MappedMediaItem> filteredItems = items
        .asMap()
        .entries
        .where((MapEntry<int, MediaItemDraft> entry) {
          final MediaItemDraft item = entry.value;
          final String query = searchQuery.trim().toLowerCase();
          final bool matchesQuery =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.assetPath.toLowerCase().contains(query);
          final bool matchesType =
              selectedType == 'all' || item.type == selectedType;
          return matchesQuery && matchesType;
        })
        .map((MapEntry<int, MediaItemDraft> entry) {
          return _MappedMediaItem(index: entry.key, item: entry.value);
        })
        .toList();

    final MediaItemDraft? activeItem =
        selectedIndex >= 0 && selectedIndex < items.length
        ? items[selectedIndex]
        : null;

    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Media Library',
          subtitle:
              'Manage uploaded Storage media for hero, showcase and landing visuals.',
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: searchQuery,
                onChanged: onSearchChanged,
                decoration: _fieldDecoration(
                  'Search by name or asset path',
                  icon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaTypes.length,
                  separatorBuilder: (_, int index) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final String type = _mediaTypes[index];
                    final bool selected = type == selectedType;
                    return ChoiceChip(
                      label: Text(type.toUpperCase()),
                      selected: selected,
                      onSelected: (_) => onTypeChanged(type),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xFF4426B8)
                            : const Color(0xFF4D5876),
                      ),
                      selectedColor: const Color(0xFFECE6FF),
                      backgroundColor: const Color(0xFFF2F5FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFFDDD0FF)
                              : const Color(0xFFE2E8F7),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: isUploading ? null : onUploadMedia,
                      icon: isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        isUploading ? 'Uploading...' : 'Upload Media',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isRefreshing ? null : onRefreshMedia,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              if ((statusText ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    statusText!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF5D6783),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 980;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: _MediaGridCard(
                      items: filteredItems,
                      selectedIndex: selectedIndex,
                      onSelectItem: onSelectItem,
                      onRemoveItem: onRemoveItem,
                      onCopyPath: onCopyPath,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: _MediaPreviewCard(
                      activeItem: activeItem,
                      onNameChanged: (String value) =>
                          onNameChanged(selectedIndex, value),
                      onPathChanged: (String value) =>
                          onPathChanged(selectedIndex, value),
                      onTypeChanged: (String value) =>
                          onItemTypeChanged(selectedIndex, value),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: <Widget>[
                _MediaGridCard(
                  items: filteredItems,
                  selectedIndex: selectedIndex,
                  onSelectItem: onSelectItem,
                  onRemoveItem: onRemoveItem,
                  onCopyPath: onCopyPath,
                ),
                const SizedBox(height: 12),
                _MediaPreviewCard(
                  activeItem: activeItem,
                  onNameChanged: (String value) =>
                      onNameChanged(selectedIndex, value),
                  onPathChanged: (String value) =>
                      onPathChanged(selectedIndex, value),
                  onTypeChanged: (String value) =>
                      onItemTypeChanged(selectedIndex, value),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MediaGridCard extends StatelessWidget {
  const _MediaGridCard({
    required this.items,
    required this.selectedIndex,
    required this.onSelectItem,
    required this.onRemoveItem,
    required this.onCopyPath,
  });

  final List<_MappedMediaItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelectItem;
  final ValueChanged<int> onRemoveItem;
  final ValueChanged<String> onCopyPath;

  @override
  Widget build(BuildContext context) {
    return AdminPanelCard(
      title: 'Media Items',
      subtitle: 'Storage-backed media catalog.',
      child: items.isEmpty
          ? const _EmptyMediaState()
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth < 620 ? 1 : 2;
                final double width = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: items
                      .map(
                        (_MappedMediaItem mapped) => SizedBox(
                          width: width,
                          child: _MediaItemCard(
                            mapped: mapped,
                            selected: mapped.index == selectedIndex,
                            onSelect: () => onSelectItem(mapped.index),
                            onRemove: () => onRemoveItem(mapped.index),
                            onCopyPath: () => onCopyPath(mapped.item.assetPath),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }
}

class _MediaItemCard extends StatelessWidget {
  const _MediaItemCard({
    required this.mapped,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    required this.onCopyPath,
  });

  final _MappedMediaItem mapped;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final VoidCallback onCopyPath;

  @override
  Widget build(BuildContext context) {
    final MediaItemDraft item = mapped.item;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? const Color(0xFFF3F0FF) : const Color(0xFFF8FAFF),
          border: Border.all(
            color: selected ? const Color(0xFFD8CAFF) : const Color(0xFFE2E8F7),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF4F6FD),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.assetPath.startsWith('http')
                  ? Image.network(
                      item.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => const Icon(
                            Icons.image_rounded,
                            color: Color(0xFF5A31E1),
                          ),
                    )
                  : const Icon(Icons.image_rounded, color: Color(0xFF5A31E1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2645),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.assetPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF5E6A87),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF2FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF36528D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                IconButton(
                  onPressed: onCopyPath,
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy path',
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFA13C4C),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPreviewCard extends StatelessWidget {
  const _MediaPreviewCard({
    required this.activeItem,
    required this.onNameChanged,
    required this.onPathChanged,
    required this.onTypeChanged,
  });

  final MediaItemDraft? activeItem;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPathChanged;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return AdminPanelCard(
      title: 'Media Preview',
      subtitle: 'Selected media item details and quick edits.',
      child: activeItem == null
          ? const Text(
              'Select a media item to inspect and edit its metadata.',
              style: TextStyle(fontSize: 13, color: Color(0xFF606B88)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFFFFEDF1),
                        Color(0xFFF0EDFF),
                        Color(0xFFE7F5FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFE0E6F6)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: activeItem!.assetPath.startsWith('http')
                      ? Image.network(
                          activeItem!.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) => const Center(
                                child: Icon(
                                  Icons.collections_rounded,
                                  color: Color(0xFF5A31E1),
                                  size: 32,
                                ),
                              ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.collections_rounded,
                            color: Color(0xFF5A31E1),
                            size: 32,
                          ),
                        ),
                ),
                if (activeItem!.downloadUrl.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'URL: ${activeItem!.downloadUrl}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF66708A),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey<String>('media-name-${activeItem!.name}'),
                  initialValue: activeItem!.name,
                  onChanged: onNameChanged,
                  decoration: _fieldDecoration('Media name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey<String>('media-path-${activeItem!.assetPath}'),
                  initialValue: activeItem!.assetPath,
                  onChanged: onPathChanged,
                  decoration: _fieldDecoration('Asset path'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _mediaTypes.contains(activeItem!.type)
                      ? activeItem!.type
                      : 'misc',
                  items: _mediaTypes
                      .where((String type) => type != 'all')
                      .map(
                        (String type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      onTypeChanged(value);
                    }
                  },
                  decoration: _fieldDecoration('Type'),
                ),
              ],
            ),
    );
  }
}

class _EmptyMediaState extends StatelessWidget {
  const _EmptyMediaState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: const Text(
        'No media items match current filters. Add a new media item to continue.',
        style: TextStyle(fontSize: 13, color: Color(0xFF5F6B89)),
      ),
    );
  }
}

class _MappedMediaItem {
  _MappedMediaItem({required this.index, required this.item});

  final int index;
  final MediaItemDraft item;
}

InputDecoration _fieldDecoration(String hint, {IconData? icon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 18),
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
