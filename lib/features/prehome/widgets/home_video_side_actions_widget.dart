// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _VideoSideActions extends StatelessWidget {
  const _VideoSideActions({
    required this.activeActionListenable,
    required this.videoExportReadyListenable,
    required this.onShareTap,
    required this.onDownloadTap,
  });

  final ValueListenable<String?> activeActionListenable;
  final ValueListenable<bool> videoExportReadyListenable;
  final VoidCallback onShareTap;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: activeActionListenable,
      builder: (context, activeAction, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: videoExportReadyListenable,
          builder: (context, videoReady, _) {
            final actionsEnabled = activeAction == null && videoReady;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _VideoSideActionButton(
                      icon: Image.asset(
                        'assets/branding/whatsapp_icon.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.share_rounded, size: 20),
                      ),
                      label: _posterShareLabel(context),
                      color: const Color(0xFF25D366),
                      busy: activeAction == 'share',
                      enabled: actionsEnabled,
                      onTap: onShareTap,
                    ),
                    const SizedBox(height: 12),
                    _VideoSideActionButton(
                      icon: const Icon(Icons.download_rounded, size: 23),
                      label: _posterDownloadLabel(context),
                      color: const Color(0xFF334155),
                      busy: activeAction == 'download',
                      enabled: actionsEnabled,
                      onTap: onDownloadTap,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VideoSideActionButton extends StatelessWidget {
  const _VideoSideActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color color;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? Colors.white : Colors.white70;
    return Opacity(
      opacity: enabled || busy ? 1 : 0.58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            child: InkWell(
              onTap: enabled ? onTap : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : IconTheme(
                          data: IconThemeData(color: foreground),
                          child: icon,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
              shadows: const <Shadow>[
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

