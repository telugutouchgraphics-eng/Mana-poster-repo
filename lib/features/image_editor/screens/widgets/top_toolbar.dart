part of '../image_editor_screen.dart';

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.height,
    required this.onUndoTap,
    required this.onRedoTap,
    required this.onDraftsTap,
    required this.onExportTap,
    required this.onDeleteTap,
    required this.onDuplicateTap,
    required this.onBringFrontTap,
    required this.onSendBackTap,
    required this.canUndo,
    required this.canRedo,
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
  final VoidCallback onExportTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onDuplicateTap;
  final VoidCallback onBringFrontTap;
  final VoidCallback onSendBackTap;
  final bool canUndo;
  final bool canRedo;
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
        color: Color(0xF2101826),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
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
            SizedBox(
              width: 164,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    strings.localized(
                      telugu: 'ఇమేజ్ ఎడిటర్',
                      english: 'Image Editor',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF8FAFC),
                      letterSpacing: -0.2,
                      fontSize: 20,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    strings.localized(
                      telugu: 'పోస్టర్ వర్క్‌స్పేస్',
                      english: 'Poster workspace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.1,
                      color: Color(0xFFB8C4D6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
            const SizedBox(width: 8),
            _TopActionButton(
              label: strings.localized(
                telugu: isExporting ? 'సేవ్ అవుతోంది...' : 'ఎగుమతి',
                english: isExporting ? 'Saving...' : 'Export',
              ),
              onTap: isExporting ? null : onExportTap,
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
