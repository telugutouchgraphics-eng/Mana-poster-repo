// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HomeExportManualAdDialog extends StatefulWidget {
  const _HomeExportManualAdDialog({required this.ad});

  final HomeExportManualAd ad;

  @override
  State<_HomeExportManualAdDialog> createState() =>
      _HomeExportManualAdDialogState();
}

class _HomeExportManualAdDialogState extends State<_HomeExportManualAdDialog> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.ad.isVideo) {
      unawaited(_loadVideo());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    final uri = Uri.tryParse(widget.ad.url.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _videoFailed = true);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _videoFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showVideo =
        widget.ad.isVideo &&
        !_videoFailed &&
        controller != null &&
        controller.value.isInitialized;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: showVideo
                  ? controller.value.aspectRatio
                  : widget.ad.isVideo
                  ? 9 / 16
                  : 4 / 5,
              child: ColoredBox(
                color: const Color(0xFF0F172A),
                child: widget.ad.isVideo
                    ? showVideo
                          ? VideoPlayer(controller)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                    : CachedNetworkImage(
                        imageUrl: widget.ad.url,
                        cacheManager: PosterNetworkImageCache.instance,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.strings.localized(
                      telugu: 'కొనసాగించండి',
                      english: 'Continue',
                      hindi: 'जारी रखें',
                      tamil: 'தொடரவும்',
                      kannada: 'ಮುಂದುವರಿಸಿ',
                      malayalam: 'തുടരുക',
                      marathi: 'पुढे चालू ठेवा',
                      gujarati: 'ચાલુ રાખો',
                      bengali: 'চালিয়ে যান',
                      punjabi: 'ਜਾਰੀ ਰੱਖੋ',
                      odia: 'ଜାରି ରଖନ୍ତୁ',
                      assamese: 'অব্যাহত ৰাখক',
                      konkani: 'चालू दवरात',
                      nepali: 'जारी राख्नुहोस्',
                      meitei: 'মখা চত্থবীয়ু',
                      mizo: 'Chhunzawm rawh',
                      kashmiri: 'جٲری تھٲوِو',
                      ladakhi: 'མུ་མཐུད་དུ་བྱོས།',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

