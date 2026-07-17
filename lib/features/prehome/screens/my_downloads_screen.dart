import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/features/prehome/services/poster_downloads_service.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/onboarding_surface_card.dart';

class MyDownloadsScreen extends StatefulWidget {
  const MyDownloadsScreen({super.key});

  @override
  State<MyDownloadsScreen> createState() => _MyDownloadsScreenState();
}

class _MyDownloadsScreenState extends State<MyDownloadsScreen> {
  Future<List<PosterDownloadListed>>? _itemsFuture;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
    _itemsFuture = PosterDownloadsService.listForDisplay();
  }

  @override
  void dispose() {
    unawaited(ScreenSecurityService.unprotectScreen());
    super.dispose();
  }

  Future<void> _reload() async {
    final next = PosterDownloadsService.listForDisplay();
    setState(() => _itemsFuture = next);
    await next;
  }

  Future<void> _shareListed(PosterDownloadListed item) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final strings = context.strings;
    final failed = strings.localized(
      telugu: 'షేర్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'Share failed. Please try again.',
      hindi: 'शेयर नहीं हुआ। फिर से कोशिश करें।',
      tamil: 'பகிர முடியவில்லை. மீண்டும் முயலவும்.',
      kannada: 'ಹಂಚಿಕೊಳ್ಳಲು ಸಾಧ್ಯವಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ഷെയർ ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
    );
    try {
      final path = item.absolutePath;
      if (path.trim().isEmpty) {
        messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
        return;
      }
      if (!await File(path).exists()) {
        messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
        return;
      }
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      final shareText =
          '✨ Shared using ${AppPublicInfo.appName}\n'
          'Download the app: ${AppPublicInfo.playStoreUrl}';
      await MediaExportService.shareImageFile(
        path,
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } on MediaShareException {
      messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
    } catch (_) {
      messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title = strings.localized(
      telugu: 'నా డౌన్‌లోడ్లు',
      english: 'My Downloads',
      hindi: 'मेरे डाउनलोड',
      tamil: 'எனது பதிவிறக்கங்கள்',
      kannada: 'ನನ್ನ ಡೌನ್‌ಲೋಡ್‌ಗಳು',
      malayalam: 'എന്റെ ഡൗൺലോഡുകൾ',
    );

    if (kIsWeb) {
      final msg = strings.localized(
        telugu: 'వెబ్‌లో అందుబాటులో లేదు.',
        english: 'Not available on web.',
        hindi: 'वेब पर उपलब्ध नहीं।',
        tamil: 'வலையில் இல்லை.',
        kannada: 'ವೆಬ್‌ನಲ್ಲಿ ಲಭ್ಯವಿಲ್ಲ.',
        malayalam: 'വെബിൽ ലഭ്യമല്ല.',
      );
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(title),
        ),
        body: GradientShell(
          child: OnboardingSurfaceCard(
            child: Text(msg, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: GradientShell(
        child: FutureBuilder<List<PosterDownloadListed>>(
          future: _itemsFuture,
          builder: (BuildContext context, AsyncSnapshot<List<PosterDownloadListed>> snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                (!snap.hasData || snap.data == null)) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return OnboardingSurfaceCard(
                child: Text(
                  strings.localized(
                    telugu: 'లోడ్ కాలేదు.',
                    english: 'Could not load downloads.',
                    hindi: 'लोड नहीं हो सका।',
                    tamil: 'ஏற்ற முடியவில்லை.',
                    kannada: 'ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ.',
                    malayalam: 'ലോഡ് ചെയ്യാനായില്ല.',
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final list = snap.data ?? <PosterDownloadListed>[];
            if (list.isEmpty) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                    OnboardingSurfaceCard(
                      child: Text(
                        strings.localized(
                          telugu:
                              'డౌన్‌లోడ్ చేసిన పోస్టర్లు ఇక్కడ కనిపిస్తాయి.'
                              '\nగ్యాలరీకి సేవ్ చేసిన ప్రతీ పోస్టరు ఇక్కడా దాఖలవుతుంది.',
                          english:
                              'Posters you download appear here.'
                              '\nEach poster saved to the gallery is stored here too.',
                          hindi:
                              'आपके डाउनलोड किए पोस्टर यहाँ दिखेंगे.'
                              '\nगैलेरी में सेव होने पर वह यहाँ भी रहेगा।',
                          tamil:
                              'பதிவிறக்கிய போஸ்டர்கள் இங்கே.'
                              '\nகேலரியில் சேமிக்கும்போது இங்கும் சேமிக்கப்படும்.',
                          kannada:
                              'ಡೌನ್‌ಲೋಡ್ ಮಾಡಿದ ಪೋಸ್ಟರುಗಳು ಇಲ್ಲಿ.'
                              '\nಗ್ಯಾಲರಿಗೆ ಸೇವ್ ಆದಾಗ ಇಲ್ಲೂ ಉಳಿಯುತ್ತದೆ.',
                          malayalam:
                              'ഡൗൺലോഡ് ചെയ്ത പോസ്റ്ററുകൾ ഇവിടെ.'
                              '\nഗാലറിയിൽ സേവ് ചെയ്യുമ്പോൾ ഇവിടെയും ഉണ്ടാകും.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  OnboardingSurfaceCard(
                    maxWidth: 520,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: list.length,
                      itemBuilder: (BuildContext _, int index) {
                        final PosterDownloadListed item = list[index];
                        final String path = item.absolutePath;
                        return ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(14),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ColoredBox(
                                color: const Color(0xFFE2E8F0),
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, Object error, StackTrace? st) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Material(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => _shareListed(item),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.share_rounded,
                                          size: 20,
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
