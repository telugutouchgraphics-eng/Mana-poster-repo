import 'package:flutter/material.dart';

import 'package:mana_poster/features/editor/controllers/editor_controller.dart';
import 'package:mana_poster/features/editor/models/editor_layer_entry.dart';
import 'package:mana_poster/features/editor/utils/editor_image_source.dart';

class EditorLayersSheet extends StatefulWidget {
  const EditorLayersSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  State<EditorLayersSheet> createState() => _EditorLayersSheetState();
}

class _EditorLayersSheetState extends State<EditorLayersSheet> {
  late List<String> _overlayOrder;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final entries = widget.controller.layerEntriesForPanel;
        final fixedEntries = entries.where((e) => !e.isMovable).toList();
        final overlayEntries = entries.where((e) => e.isMovable).toList();

        if (!_initialized) {
          _overlayOrder = overlayEntries.map((e) => e.entryId).toList();
          _initialized = true;
        } else {
          final latest = overlayEntries.map((e) => e.entryId).toList();
          if (latest.length != _overlayOrder.length ||
              latest.any((id) => !_overlayOrder.contains(id)) ||
              !_listEquals(latest, _overlayOrder)) {
            _overlayOrder = latest;
          }
        }

        final overlayById = {
          for (final item in overlayEntries) item.entryId: item,
        };

        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                Row(
                  children: <Widget>[
                    const Text(
                      'లేయర్స్',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      for (final entry in fixedEntries)
                        _LayerTile(
                          entry: entry,
                          controller: widget.controller,
                          onRename: _renameEntry,
                          reorderable: false,
                        ),
                      const Divider(height: 16),
                      Expanded(
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: _overlayOrder.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final moved = _overlayOrder.removeAt(oldIndex);
                              _overlayOrder.insert(newIndex, moved);
                            });
                            widget.controller.reorderOverlayLayersByPanelOrder(
                              _overlayOrder,
                            );
                          },
                          itemBuilder: (context, index) {
                            final entryId = _overlayOrder[index];
                            final entry = overlayById[entryId];
                            if (entry == null) {
                              return const SizedBox.shrink(
                                key: ValueKey('empty'),
                              );
                            }
                            return _LayerTile(
                              key: ValueKey(entry.entryId),
                              entry: entry,
                              controller: widget.controller,
                              onRename: _renameEntry,
                              reorderable: true,
                              reorderIndex: index,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _renameEntry(EditorLayerEntry entry) async {
    final controller = TextEditingController(text: entry.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Layer'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Layer name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) {
      return;
    }
    widget.controller.renameLayerFromEntry(entry.entryId, result);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.entry,
    required this.controller,
    required this.onRename,
    required this.reorderable,
    this.reorderIndex,
  });

  final EditorLayerEntry entry;
  final EditorController controller;
  final Future<void> Function(EditorLayerEntry entry) onRename;
  final bool reorderable;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final bg = entry.isSelected ? const Color(0xFFF1F5FF) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isSelected
              ? const Color(0x663B82F6)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: <Widget>[
          _thumb(entry),
          const SizedBox(width: 8),
          Icon(_typeIcon(entry.type), size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.selectLayerFromEntry(entry.entryId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            onPressed:
                entry.type == EditorLayerType.background ||
                    entry.type == EditorLayerType.surfacePhoto
                ? null
                : () => controller.toggleVisibilityForLayerEntry(entry.entryId),
            icon: Icon(
              entry.isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
            ),
          ),
          IconButton(
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            onPressed: entry.type == EditorLayerType.background
                ? null
                : () => controller.toggleLockForLayerEntry(entry.entryId),
            icon: Icon(
              entry.isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
              size: 18,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'front') {
                controller.bringLayerToFrontFromEntry(entry.entryId);
              } else if (value == 'back') {
                controller.sendLayerToBackFromEntry(entry.entryId);
              } else if (value == 'dup') {
                controller.duplicateLayerFromEntry(entry.entryId);
              } else if (value == 'del') {
                controller.deleteLayerFromEntry(entry.entryId);
              } else if (value == 'rename') {
                onRename(entry);
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              if (entry.isMovable)
                const PopupMenuItem(
                  value: 'front',
                  child: Text('Bring to front'),
                ),
              if (entry.isMovable)
                const PopupMenuItem(value: 'back', child: Text('Send to back')),
              if (entry.type != EditorLayerType.surfacePhoto &&
                  entry.type != EditorLayerType.background)
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(value: 'dup', child: Text('Duplicate')),
              const PopupMenuItem(value: 'del', child: Text('Delete')),
            ],
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
            splashRadius: 18,
          ),
          if (reorderable && reorderIndex != null)
            ReorderableDragStartListener(
              index: reorderIndex!,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.drag_indicator_rounded, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _thumb(EditorLayerEntry entry) {
    if (entry.thumbnailUrl != null && entry.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: buildEditorImage(
          entry.thumbnailUrl!,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: entry.type == EditorLayerType.background
            ? const Color(0xFFE2E8F0)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        entry.type == EditorLayerType.text
            ? 'T'
            : (entry.type == EditorLayerType.sticker
                  ? 'S'
                  : (entry.type == EditorLayerType.draw
                        ? 'D'
                        : (entry.type == EditorLayerType.shape ? 'G' : 'L'))),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  IconData _typeIcon(EditorLayerType type) {
    switch (type) {
      case EditorLayerType.background:
        return Icons.wallpaper_outlined;
      case EditorLayerType.surfacePhoto:
      case EditorLayerType.photo:
        return Icons.image_outlined;
      case EditorLayerType.text:
        return Icons.text_fields_rounded;
      case EditorLayerType.element:
        return Icons.auto_awesome_mosaic_outlined;
      case EditorLayerType.sticker:
        return Icons.emoji_emotions_outlined;
      case EditorLayerType.draw:
        return Icons.brush_outlined;
      case EditorLayerType.shape:
        return Icons.category_outlined;
    }
  }
}
