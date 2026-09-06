import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/screens/home_screen.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class ProfilePhotoStyleResult {
  const ProfilePhotoStyleResult({
    required this.preferOriginal,
    this.cutoutBytes,
  });

  final bool preferOriginal;
  final Uint8List? cutoutBytes;
}

class ProfilePhotoStylePickerSheet extends StatefulWidget {
  const ProfilePhotoStylePickerSheet({
    super.key,
    required this.originalBytes,
    required this.cutoutBytes,
    required this.profile,
    this.originalPhotoPath,
    this.cutoutPhotoPath,
    this.initialTemplate,
    this.initialPreferOriginal = false,
  });

  /// The original (full) photo bytes.
  final Uint8List originalBytes;

  /// Already-resolved cutout bytes, or null if BG removal failed/was skipped.
  final Uint8List? cutoutBytes;

  /// Local path to original photo file on disk, if available.
  final String? originalPhotoPath;

  /// Local path to cutout photo file on disk, if available.
  final String? cutoutPhotoPath;

  /// User's poster profile (used for real name/designation in the preview).
  final PosterProfileData profile;

  final ApprovedCreatorTemplate? initialTemplate;

  final bool initialPreferOriginal;

  /// In-memory cached template to ensure instant 0ms rendering of poster preview.
  static ApprovedCreatorTemplate? cachedTemplate;

  /// Pre-warm template and precache its image in memory.
  static Future<ApprovedCreatorTemplate?> prewarmTemplate({
    BuildContext? context,
  }) async {
    if (cachedTemplate != null) {
      if (context != null &&
          context.mounted &&
          cachedTemplate!.imageUrl.trim().isNotEmpty) {
        unawaited(
          precacheImage(
            CachedNetworkImageProvider(cachedTemplate!.imageUrl.trim()),
            context,
          ),
        );
      }
      return cachedTemplate;
    }
    try {
      final service = ApprovedCreatorTemplateService();
      // 1. First attempt: Quick single query from window
      final window = await service.fetchApprovedTemplatesWindow(
        scanLimit: 5,
        source: Source.serverAndCache,
      );
      if (window.isNotEmpty) {
        cachedTemplate = window.first;
        if (context != null &&
            context.mounted &&
            cachedTemplate!.imageUrl.trim().isNotEmpty) {
          unawaited(
            precacheImage(
              CachedNetworkImageProvider(cachedTemplate!.imageUrl.trim()),
              context,
            ),
          );
        }
        return cachedTemplate;
      }

      // 2. Second attempt: Check first 2 categories in parallel
      final now = DateTime.now();
      final dynamicCats = DynamicCategoryService().categoriesForDate(now);
      if (dynamicCats.isNotEmpty) {
        final futures = dynamicCats
            .take(2)
            .map(
              (cat) => service.fetchAllApprovedTemplatesForCategory(
                categoryId: cat.slug,
                scanLimit: 3,
                source: Source.serverAndCache,
              ),
            );
        final results = await Future.wait(futures);
        for (final list in results) {
          if (list.isNotEmpty) {
            cachedTemplate = list.first;
            if (context != null &&
                context.mounted &&
                cachedTemplate!.imageUrl.trim().isNotEmpty) {
              unawaited(
                precacheImage(
                  CachedNetworkImageProvider(cachedTemplate!.imageUrl.trim()),
                  context,
                ),
              );
            }
            return cachedTemplate;
          }
        }
      }
    } catch (e) {
      debugPrint('ProfilePhotoStylePickerSheet prewarmTemplate: $e');
    }
    return cachedTemplate;
  }

  static Future<ProfilePhotoStyleResult?> show({
    required BuildContext context,
    required Uint8List originalBytes,
    required Uint8List? cutoutBytes,
    required PosterProfileData profile,
    String? originalPhotoPath,
    String? cutoutPhotoPath,
    ApprovedCreatorTemplate? initialTemplate,
    bool initialPreferOriginal = false,
  }) {
    return showModalBottomSheet<ProfilePhotoStyleResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfilePhotoStylePickerSheet(
        originalBytes: originalBytes,
        cutoutBytes: cutoutBytes,
        profile: profile,
        originalPhotoPath: originalPhotoPath,
        cutoutPhotoPath: cutoutPhotoPath,
        initialTemplate: initialTemplate ?? cachedTemplate,
        initialPreferOriginal: initialPreferOriginal,
      ),
    );
  }

  @override
  State<ProfilePhotoStylePickerSheet> createState() =>
      _ProfilePhotoStylePickerSheetState();
}

class _ProfilePhotoStylePickerSheetState
    extends State<ProfilePhotoStylePickerSheet> {
  ApprovedCreatorTemplate? _template;
  String? _effectiveOriginalPath;
  String? _effectiveCutoutPath;

  @override
  void initState() {
    super.initState();
    _effectiveOriginalPath = widget.originalPhotoPath;
    _effectiveCutoutPath = widget.cutoutPhotoPath;
    _initTempFilesIfNeeded();
    _template =
        widget.initialTemplate ?? ProfilePhotoStylePickerSheet.cachedTemplate;
    if (_template == null) {
      _loadTemplate();
    } else if (_template!.imageUrl.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            precacheImage(
              CachedNetworkImageProvider(_template!.imageUrl.trim()),
              context,
            ),
          );
        }
      });
    }
  }

  Future<void> _initTempFilesIfNeeded() async {
    if (_effectiveOriginalPath == null ||
        !File(_effectiveOriginalPath!).existsSync()) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}${Platform.pathSeparator}temp_picker_original_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(widget.originalBytes, flush: true);
        if (mounted) {
          setState(() => _effectiveOriginalPath = file.path);
        }
      } catch (_) {}
    }
    if (widget.cutoutBytes != null &&
        widget.cutoutBytes!.isNotEmpty &&
        (_effectiveCutoutPath == null ||
            !File(_effectiveCutoutPath!).existsSync())) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}${Platform.pathSeparator}temp_picker_cutout_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(widget.cutoutBytes!, flush: true);
        if (mounted) {
          setState(() => _effectiveCutoutPath = file.path);
        }
      } catch (_) {}
    }
  }

  PosterProfileData get _cutoutProfile {
    return widget.profile.copyWith(
      photoPath: _effectiveCutoutPath ?? widget.profile.photoPath,
      photoUrl: '',
      originalPhotoPath:
          _effectiveOriginalPath ?? widget.profile.originalPhotoPath,
      originalPhotoUrl: '',
      preferOriginalPersonalPhoto: false,
    );
  }

  PosterProfileData get _originalProfile {
    return widget.profile.copyWith(
      photoPath: _effectiveCutoutPath ?? widget.profile.photoPath,
      photoUrl: '',
      originalPhotoPath:
          _effectiveOriginalPath ?? widget.profile.originalPhotoPath,
      originalPhotoUrl: '',
      preferOriginalPersonalPhoto: true,
    );
  }

  Future<void> _loadTemplate() async {
    final prewarmed = await ProfilePhotoStylePickerSheet.prewarmTemplate(
      context: mounted ? context : null,
    );
    if (prewarmed != null && mounted) {
      setState(() => _template = prewarmed);
      return;
    }
    try {
      final now = DateTime.now();
      final dynamicCats = DynamicCategoryService().categoriesForDate(now);
      final service = ApprovedCreatorTemplateService();

      for (final cat in dynamicCats) {
        final templates = await service.fetchAllApprovedTemplatesForCategory(
          categoryId: cat.slug,
          scanLimit: 5,
          source: Source.serverAndCache,
        );
        if (templates.isNotEmpty && mounted) {
          setState(() {
            _template = templates.first;
            ProfilePhotoStylePickerSheet.cachedTemplate = templates.first;
          });
          return;
        }
      }

      final window = await service.fetchApprovedTemplatesWindow(
        scanLimit: 5,
        source: Source.serverAndCache,
      );
      if (window.isNotEmpty && mounted) {
        setState(() {
          _template = window.first;
          ProfilePhotoStylePickerSheet.cachedTemplate = window.first;
        });
      }
    } catch (e) {
      debugPrint('ProfilePhotoStylePickerSheet template fetch: $e');
    }
  }

  void _chooseCutout() {
    Navigator.of(context).pop(
      ProfilePhotoStyleResult(
        preferOriginal: false,
        cutoutBytes: widget.cutoutBytes,
      ),
    );
  }

  void _chooseOriginal() {
    Navigator.of(context).pop(
      ProfilePhotoStyleResult(
        preferOriginal: true,
        cutoutBytes: widget.cutoutBytes,
      ),
    );
  }

  bool get _cutoutAvailable =>
      widget.cutoutBytes != null && widget.cutoutBytes!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title row with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Text(
                  strings.localized(
                    telugu: 'ఫోటో శైలి ఎంచుకోండి',
                    english: 'Choose Photo Style',
                    hindi: 'फ़ोटो शैली चुनें',
                    tamil: 'புகைப்பட பாணியைத் தேர்ந்தெடுக்கவும்',
                    kannada: 'ಫೋಟೋ ಶೈಲಿಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
                    malayalam: 'ഫോട്ടോ ശൈലി തിരഞ്ഞെടുക്കുക',
                    marathi: 'फोटो शैली निवडा',
                    gujarati: 'ફોટો શૈલી પસંદ કરો',
                    bengali: 'ছবির শৈলী নির্বাচন করুন',
                    punjabi: 'ਫੋਟੋ ਸ਼ੈਲੀ ਚੁਣੋ',
                    odia: 'ଫଟୋ ଶୈଳୀ ବାଛନ୍ତୁ',
                    assamese: 'ফটো শৈলী বাছক',
                    konkani: 'फोटो प्रकार वेंचून काडात',
                    nepali: 'फोटो शैली छान्नुहोस्',
                    meitei: 'Photo style khallu',
                    mizo: 'Thlalak style thlang rawh',
                    kashmiri: 'فوٹو انداز ژٲریو',
                    ladakhi: 'པར་གྱི་བཟོ་རྣམ་འདེམས།',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(
                    ProfilePhotoStyleResult(
                      preferOriginal:
                          widget.initialPreferOriginal || !_cutoutAvailable,
                      cutoutBytes: widget.cutoutBytes,
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // Two poster previews
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (_cutoutAvailable) ...<Widget>[
                  _buildOptionCard(isCutout: true, onSelect: _chooseCutout),
                  const SizedBox(height: 16),
                ],
                _buildOptionCard(isCutout: false, onSelect: _chooseOriginal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required bool isCutout,
    required VoidCallback onSelect,
  }) {
    final strings = context.strings;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCutout
              ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
              : const Color(0xFF34D399).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poster preview matching HomeScreen exactly
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AspectRatio(
              aspectRatio: _template?.pageConfig?.aspectRatio ?? 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _template == null
                    ? _buildPosterPlaceholder()
                    : CreatorPosterPreview(
                        imageUrl: _template!.imageUrl.trim().isNotEmpty
                            ? _template!.imageUrl.trim()
                            : null,
                        imageStoragePath: _template!.imageStoragePath,
                        thumbnailStoragePath: _template!.thumbnailStoragePath,
                        thumbnailUrl: _template!.thumbnailUrl,
                        pageConfig: _template!.pageConfig,
                        personalizationConfig:
                            _template!.personalizationConfig,
                        viewerPosterProfile:
                            isCutout ? _cutoutProfile : _originalProfile,
                        language: context.currentLanguage,
                        photoRenderModeOverride:
                            isCutout ? 'cutout' : 'original',
                        photoShapeOverride: '',
                        showPoliticalProtocolOverlay: false,
                        showProfilePhoto: true,
                        interactivePhotoEnabled: false,
                        deferLegacyTextPrime: false,
                        posterRenderCycle: 0,
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSelect,
                icon: Icon(
                  isCutout
                      ? Icons.auto_fix_high_rounded
                      : Icons.portrait_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCutout
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                label: Text(
                  isCutout
                      ? strings.localized(
                          telugu: 'కటౌట్ ఫోటో సెట్ చేయండి',
                          english: 'Set Cutout Photo',
                          hindi: 'कटआउट फ़ोटो सेट करें',
                          tamil: 'கட்டவுட் புகைப்படத்தை அமைக்கவும்',
                          kannada: 'ಕಟೌಟ್ ಫೋಟೋ ಹೊಂದಿಸಿ',
                          malayalam: 'കട്ടൗട്ട് ഫോട്ടോ സജ്ജമാക്കുക',
                          marathi: 'कटआउट फोटो सेट करा',
                          gujarati: 'કટઆઉટ ફોટો સેટ કરો',
                          bengali: 'কাটআউট ছবি সেট করুন',
                          punjabi: 'ਕੱਟਆਊਟ ਫੋਟੋ ਸੈੱਟ ਕਰੋ',
                          odia: 'କଟଆଉଟ୍ ଫଟୋ ସେଟ୍ କରନ୍ତୁ',
                          assamese: 'কাটআউট ফটো ছেট কৰক',
                          konkani: 'कटआउट फोटो सेट करात',
                          nepali: 'कटआउट फोटो सेट गर्नुहोस्',
                          meitei: 'Cutout photo set toubiyu',
                          mizo: 'Cutout thlalak dah rawh',
                          kashmiri: 'کٹ آوُٹ فوٹو تھاویو',
                          ladakhi: 'Cutout པར་སྒྲིག',
                        )
                      : strings.localized(
                          telugu: 'ఒరిజినల్ ఫోటో సెట్ చేయండి',
                          english: 'Set Original Photo',
                          hindi: 'मूल फ़ोटो सेट करें',
                          tamil: 'அசல் புகைப்படத்தை அமைக்கவும்',
                          kannada: 'ಮೂಲ ಫೋಟೋ ಹೊಂದಿಸಿ',
                          malayalam: 'യഥാർത്ഥ ഫോട്ടോ സജ്ജമാക്കുക',
                          marathi: 'मूळ फोटो सेट करा',
                          gujarati: 'મૂળ ફોટો સેટ કરો',
                          bengali: 'মূল ছবি সেট করুন',
                          punjabi: 'ਅਸਲ ਫੋਟੋ ਸੈੱਟ ਕਰੋ',
                          odia: 'ମୂଳ ଫଟୋ ସେଟ୍ କରନ୍ତୁ',
                          assamese: 'মূল ফটো ছেট কৰক',
                          konkani: 'मूळ फोटो सेट करात',
                          nepali: 'मूल फोटो सेट गर्नुहोस्',
                          meitei: 'Original photo set toubiyu',
                          mizo: 'Original thlalak dah rawh',
                          kashmiri: 'اصلی فوٹو تھاویو',
                          ladakhi: 'ངོ་མའི་པར་སྒྲིག',
                        ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPosterPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.white.withValues(alpha: 0.3),
          size: 48,
        ),
      ),
    );
  }

}
