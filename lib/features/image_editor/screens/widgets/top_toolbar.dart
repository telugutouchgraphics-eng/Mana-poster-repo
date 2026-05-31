part of '../image_editor_screen.dart';

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.height,
    required this.onUndoTap,
    required this.onRedoTap,
    required this.onDraftsTap,
    required this.onShareTap,
    required this.onExportTap,
    required this.onDeleteTap,
    required this.onDuplicateTap,
    required this.onBringFrontTap,
    required this.onSendBackTap,
    required this.canUndo,
    required this.canRedo,
    required this.isSharing,
    required this.isExporting,
    required this.canDelete,
    required this.canDuplicate,
    required this.canBringFront,
    required this.canSendBack,
  });

  final double height;
  final VoidCallback onUndoTap;
  final VoidCallback onRedoTap;
  final VoidCallback onDraftsTap;
  final VoidCallback onShareTap;
  final VoidCallback onExportTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onDuplicateTap;
  final VoidCallback onBringFrontTap;
  final VoidCallback onSendBackTap;
  final bool canUndo;
  final bool canRedo;
  final bool isSharing;
  final bool isExporting;
  final bool canDelete;
  final bool canDuplicate;
  final bool canBringFront;
  final bool canSendBack;

  VoidCallback? _withHaptic(VoidCallback? callback) {
    if (callback == null) {
      return null;
    }
    return () {
      HapticFeedback.selectionClick();
      callback();
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: _editorChromeSurfaceStrong,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _EditorIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: strings.localized(telugu: 'వెనక్కి', english: 'Back'),
              onTap: _withHaptic(() => Navigator.of(context).maybePop()),
            ),
            const SizedBox(width: 8),
            _TopPrimaryPillButton(
              label: strings.localized(
                telugu: isSharing ? 'షేర్ అవుతోంది...' : 'షేర్',
                english: isSharing ? 'Sharing...' : 'Share',
              ),
              onTap: isSharing ? null : onShareTap,
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              borderColor: const Color(0xFF25D366),
              icon: Image.asset(
                'assets/branding/whatsapp_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.whatshot_rounded, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            _TopPrimaryPillButton(
              label: strings.localized(
                telugu: isExporting ? 'సేవ్ అవుతోంది...' : 'డౌన్‌లోడ్',
                english: isExporting ? 'Saving...' : 'Download',
              ),
              onTap: isExporting ? null : onExportTap,
              backgroundColor: const Color(0xFF64748B),
              foregroundColor: Colors.white,
              borderColor: const Color(0xFF64748B),
              icon: const Icon(
                Icons.download_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            _TopActionButton(
              label: strings.localized(telugu: 'అండు', english: 'Undo'),
              onTap: canUndo ? onUndoTap : null,
            ),
            const SizedBox(width: 8),
            _TopActionButton(
              label: strings.localized(telugu: 'రీడో', english: 'Redo'),
              onTap: canRedo ? onRedoTap : null,
            ),
            const SizedBox(width: 8),
            _TopActionButton(
              label: strings.localized(telugu: 'డ్రాఫ్ట్స్', english: 'Drafts'),
              onTap: onDraftsTap,
            ),
            const SizedBox(width: 6),
            _EditorIconButton(
              icon: Icons.flip_to_back_rounded,
              tooltip: strings.localized(
                telugu: 'వెనక్కి పంపు',
                english: 'Send back',
              ),
              onTap: _withHaptic(canSendBack ? onSendBackTap : null),
            ),
            _EditorIconButton(
              icon: Icons.flip_to_front_rounded,
              tooltip: strings.localized(
                telugu: 'ముందుకు తెచ్చు',
                english: 'Bring front',
              ),
              onTap: _withHaptic(canBringFront ? onBringFrontTap : null),
            ),
            _EditorIconButton(
              icon: Icons.control_point_duplicate_rounded,
              tooltip: strings.localized(
                telugu: 'నకలు',
                english: 'Duplicate selected',
              ),
              onTap: _withHaptic(canDuplicate ? onDuplicateTap : null),
            ),
            _EditorIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: strings.localized(
                telugu: 'డిలీట్',
                english: 'Delete selected',
              ),
              onTap: _withHaptic(canDelete ? onDeleteTap : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPrimaryPillButton extends StatelessWidget {
  const _TopPrimaryPillButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      enabled: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
