import 'package:flutter/material.dart';

class EditorTopBar extends StatelessWidget {
  const EditorTopBar({
    super.key,
    required this.onBack,
    required this.onUndo,
    required this.onRedo,
    required this.onLayers,
    required this.onDelete,
    required this.onSave,
    required this.canUndo,
    required this.canRedo,
    required this.hasSelection,
  });

  final VoidCallback onBack;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onLayers;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final bool canUndo;
  final bool canRedo;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    const iconColor = Color(0xFF0F172A);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: <Widget>[
          _TopBarIconButton(
            onPressed: onBack,
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            color: iconColor,
          ),
          _TopBarIconButton(
            onPressed: canUndo ? onUndo : null,
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            color: iconColor,
          ),
          _TopBarIconButton(
            onPressed: canRedo ? onRedo : null,
            icon: Icons.redo_rounded,
            tooltip: 'Redo',
            color: iconColor,
          ),
          _TopBarIconButton(
            onPressed: onLayers,
            icon: Icons.layers_outlined,
            tooltip: 'Layers',
            color: iconColor,
          ),
          if (hasSelection)
            _TopBarIconButton(
              onPressed: onDelete,
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              color: const Color(0xFFB91C1C),
            )
          else
            const SizedBox(width: 44),
          const Spacer(),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_alt_rounded, size: 18),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.color,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 22,
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon, size: 22, color: color),
    );
  }
}
