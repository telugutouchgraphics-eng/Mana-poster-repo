import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/widgets/digital_visiting_card_widget.dart';

class OnboardingVisitingCardDialog extends StatefulWidget {
  const OnboardingVisitingCardDialog({
    super.key,
    required this.profile,
  });

  final PosterProfileData profile;

  static Future<void> show(
    BuildContext context, {
    required PosterProfileData profile,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) => OnboardingVisitingCardDialog(profile: profile),
    );
  }

  @override
  State<OnboardingVisitingCardDialog> createState() =>
      _OnboardingVisitingCardDialogState();
}

class _OnboardingVisitingCardDialogState
    extends State<OnboardingVisitingCardDialog>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _downloading = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _recordVisitingCardEngagement() {
    try {
      FirebaseFirestore.instance
          .collection('visitingCardStats')
          .doc('summary')
          .set(<String, dynamic>{
        'totalCount': FieldValue.increment(1),
        'lastActivityAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Visiting card engagement record error: $e');
      }
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    if (Platform.isAndroid &&
        !(await MediaExportService.needsGalleryPermission())) {
      return true;
    }
    final permission =
        Platform.isAndroid ? Permission.storage : Permission.photos;
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    final requested = await <Permission>[permission].request();
    return requested.values.any((s) => s.isGranted || s.isLimited);
  }

  Future<String?> _captureCardToTempFile() async {
    setState(() => _isCapturing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/mana_visiting_card_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Card capture error: $e');
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _handleDownloadAndProceed() async {
    if (_downloading) return;
    setState(() => _downloading = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final hasPermission = await _ensureGallerySavePermission();
      if (!hasPermission) {
        if (mounted) {
          messenger.showTopSnackBar(
            AppSnackBar.build(
              content: Text(
                context.strings.localized(
                  telugu: 'గ్యాలరీ అనుమతి నిరాకరించబడింది.',
                  english: 'Gallery permission was denied.',
                  hindi: 'गैलरी की अनुमति अस्वीकार कर दी गई।',
                  tamil: 'கேலரி அனுமதி மறுக்கப்பட்டது.',
                  kannada: 'ಗ್ಯಾಲರಿ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ.',
                  malayalam: 'ഗ്യാലറി അനുമതി നിരസിച്ചു.',
                  marathi: 'गॅलरी परवानगी नाकारली गेली.',
                  gujarati: 'ગૅલેરી પરવાનગી નકારી દેવામાં આવી.',
                  bengali: 'গ্যালারির অনুমতি প্রত্যাখ্যান করা হয়েছে।',
                  punjabi: 'ਗੈਲਰੀ ਦੀ ਇਜਾਜ਼ਤ ਅਸਵੀਕਾਰ ਕਰ ਦਿੱਤੀ ਗਈ।',
                  odia: 'ଗ୍ୟାଲେରୀ ଅନୁମତି ପ୍ରତ୍ୟାଖ୍ୟାନ କରାଗଲା।',
                  assamese: 'গেলেৰীৰ অনুমতি নাকচ কৰা হ’ল।',
                  konkani: 'गॅलरीची परवानगी नाकारली.',
                  nepali: 'ग्यालरी अनुमति अस्वीकृत गरियो।',
                  meitei: 'গেলরিগী অয়াবা য়াদে।',
                  mizo: 'Gallery phalna hnar a ni.',
                  kashmiri: 'گیلری ہٕنٛز اِجازت آیہِ مسترد کَرنہٕ।',
                  ladakhi: 'པར་མཛོད་ཆོག་མཆན་ཕྱིར་འཐེན་བྱས།',
                ),
              ),
            ),
          );
        }
        await _proceedToHome();
        return;
      }

      final path = await _captureCardToTempFile();
      if (path != null) {
        final fileName =
            'mana_visiting_card_${DateTime.now().millisecondsSinceEpoch}.png';
        final result = await MediaExportService.saveImageFileToGalleryDetailed(
          path,
          fileName: fileName,
        );
        if (result.success) {
          _recordVisitingCardEngagement();
          if (mounted) {
            messenger.showTopSnackBar(
              AppSnackBar.build(
                content: Text(
                  context.strings.localized(
                    telugu: 'విజిటింగ్ కార్డ్ గ్యాలరీలో సేవ్ చేయబడింది!',
                    english: 'Visiting card saved to gallery!',
                    hindi: 'विजिटिंग कार्ड गैलरी में सहेजा गया!',
                    tamil: 'விசிட்டிங் கார்டு கேலரியில் சேமிக்கப்பட்டது!',
                    kannada: 'ವಿಸಿಟಿಂಗ್ ಕಾರ್ಡ್ ಗ್ಯಾಲರಿಯಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ!',
                    malayalam: 'വിസിറ്റിംഗ് കാർഡ് ഗ്യാലറിയിൽ സൂക്ഷിച്ചു!',
                    marathi: 'व्हिजिटिंग कार्ड गॅलरीमध्ये जतन केले!',
                    gujarati: 'વિઝિટિંગ કાર્ડ ગૅલેરીમાં સાચવવામાં આવ્યું!',
                    bengali: 'ভিজিটিং কার্ডটি গ্যালারিতে সংরক্ষিত হয়েছে!',
                    punjabi: 'ਵਿਜ਼ਿਟਿੰਗ ਕਾਰਡ ਗੈਲਰੀ ਵਿੱਚ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਗਿਆ!',
                    odia: 'ଭିଜିଟିଂ କାର୍ଡ ଗ୍ୟାଲେରୀରେ ସେଭ୍ ହୋଇଛି!',
                    assamese: 'ভিজিটিং কাৰ্ড গেলেৰীত সংৰক্ষণ কৰা হ’ল!',
                    konkani: 'व्हिजिटिंग कार्ड गॅलरींत सांबाळ्ळें!',
                    nepali: 'भिजिटिङ कार्ड ग्यालरीमा सुरक्षित गरियो!',
                    meitei: 'ভিজিতিং কার্দ গেলরিদা সেভ তৌরে!',
                    mizo: 'Visiting card chu gallery-ah save a ni ta!',
                    kashmiri: 'وِزِٹِنٛگ کارڈ آیہِ گیلری منٛز محفوٗظ کَرنہٕ!',
                    ladakhi: 'འགྲུལ་བཞུད་བྱང་བུ་པར་མཛོད་ནང་ཉར་ཚགས་བྱས།',
                  ),
                ),
              ),
            );
          }
        }
      }
    } catch (_) {
    } finally {
      await _proceedToHome();
    }
  }

  Future<void> _proceedToHome() async {
    try {
      final nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          nextRoute.isNotEmpty ? nextRoute : AppRoutes.home,
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _proceedToHome();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Celebration Title Banner (Floating)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFD97706), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x66F59E0B),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      context.strings.localized(
                        telugu: 'మీ విజిటింగ్ కార్డ్ సిద్ధమైంది! 🎊',
                        english: 'Your Visiting Card is Ready! 🎊',
                        hindi: 'आपका विजिटिंग कार्ड तैयार है! 🎊',
                        tamil: 'உங்கள் விசிட்டிங் கார்டு தயார்! 🎊',
                        kannada: 'ನಿಮ್ಮ ವಿಸಿಟಿಂಗ್ ಕಾರ್ಡ್ ಸಿದ್ಧವಾಗಿದೆ! 🎊',
                        malayalam: 'നിങ്ങളുടെ വിസിറ്റിംഗ് കാർഡ് തയ്യാറാണ്! 🎊',
                        marathi: 'तुमचे व्हिजिटिंग कार्ड तयार आहे! 🎊',
                        gujarati: 'તમારું વિઝિટિંગ કાર્ડ તૈયાર છે! 🎊',
                        bengali: 'আপনার ভিজিটিং কার্ড প্রস্তুত! 🎊',
                        punjabi: 'ਤੁਹਾਡਾ ਵਿਜ਼ਿਟਿੰਗ ਕਾਰਡ ਤਿਆਰ ਹੈ! 🎊',
                        odia: 'ଆପଣଙ୍କ ଭିଜିଟିଂ କାର୍ଡ ପ୍ରସ୍ତୁତ! 🎊',
                        assamese: 'আপোনাৰ ভিজিটিং কাৰ্ড প্ৰস্তুত! 🎊',
                        konkani: 'तुमचें व्हिजिटिंग कार्ड तयार आसा! 🎊',
                        nepali: 'तपाईंको भिजिटिङ कार्ड तयार छ! 🎊',
                        meitei: 'নহাক্কী ভিজিতিং কার্দ শেম্লে! 🎊',
                        mizo: 'I Visiting Card chu a peih e! 🎊',
                        kashmiri: 'تُہٕنٛز وِزِٹِنٛگ کارڈ چھِ تیار! 🎊',
                        ladakhi: 'ཁྱེད་རང་གི་འགྲུལ་བཞུད་བྱང་བུ་གྲ་སྒྲིག་ཟིན། 🎊',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // The Floating Single Visiting Card
                  RepaintBoundary(
                    key: _cardBoundaryKey,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: DigitalVisitingCardWidget(
                        profile: widget.profile,
                        style: VisitingCardStyle.classicPearlGold,
                        showAppLogo: true,
                        enableShineEffect: !_isCapturing,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "Download Free" Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x662563EB),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed:
                            _downloading ? null : _handleDownloadAndProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _downloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 24),
                        label: Text(
                          context.strings.localized(
                            telugu: 'ఉచితంగా డౌన్‌లోడ్ చేసుకోండి',
                            english: 'Download Free',
                            hindi: 'मुफ्त डाउनलोड करें',
                            tamil: 'இலவசமாக பதிவிறக்கவும்',
                            kannada: 'ಉಚಿತವಾಗಿ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ',
                            malayalam: 'സൗജന്യമായി ഡൗൺലോഡ് ചെയ്യുക',
                            marathi: 'मोफत डाउनलोड करा',
                            gujarati: 'મફત ડાઉનલોડ કરો',
                            bengali: 'বিনামূল্যে ডাউনলোড করুন',
                            punjabi: 'ਮੁਫ਼ਤ ਡਾਊਨਲੋਡ ਕਰੋ',
                            odia: 'ମାଗଣାରେ ଡାଉନଲୋଡ୍ କରନ୍ତୁ',
                            assamese: 'বিনামূলীয়াকৈ ডাউনলোড কৰক',
                            konkani: 'मुफत डाऊनलोड करा',
                            nepali: 'नि:शुल्क डाउनलोड गर्नुहोस्',
                            meitei: 'মরাং কায়না দাউনলোদ তৌবীয়ু',
                            mizo: 'A thlawnin download rawh',
                            kashmiri: 'مُفت ڈاوُنلوڈ کٔرِو',
                            ladakhi: 'རིན་མེད་ཕབ་ལེན་གནང་།',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary "Skip to Home" Action
                  TextButton(
                    onPressed: _downloading ? null : _proceedToHome,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      context.strings.localized(
                        telugu: 'హోమ్‌కి వెళ్లండి (Skip)',
                        english: 'Continue to Home',
                        hindi: 'होम पर जाएं',
                        tamil: 'முகப்புக்குச் செல்லவும்',
                        kannada: 'ಮುಖಪುಟಕ್ಕೆ ಹೋಗಿ',
                        malayalam: 'ഹോമിലേക്ക് പോകുക',
                        marathi: 'होमवर जा',
                        gujarati: 'હોમ પર જાઓ',
                        bengali: 'হোমে যান',
                        punjabi: 'ਹੋਮ ਤੇ ਜਾਓ',
                        odia: 'ହୋମକୁ ଯାଆନ୍ତୁ',
                        assamese: 'হোমলৈ যাওক',
                        konkani: 'होमाचेर वचात',
                        nepali: 'होममा जानुहोस्',
                        meitei: 'হোমদা চৎলু',
                        mizo: 'Home-ah kal rawh',
                        kashmiri: 'ہومس پؠٹھ گٔژھِو',
                        ladakhi: 'གདོང་ཤོག་ལ་སྐྱོད་པ།',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
