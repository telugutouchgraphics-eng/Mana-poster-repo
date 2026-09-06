import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/prehome/screens/my_downloads_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/onboarding_audio_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/profile_photo_guide_service.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/onboarding_surface_card.dart';
import 'package:mana_poster/features/prehome/widgets/poster_identity_visual.dart';
import 'package:mana_poster/features/prehome/widgets/profile_photo_style_picker_sheet.dart';

class PosterProfileDetailsScreen extends StatefulWidget {
  const PosterProfileDetailsScreen({
    super.key,
    required this.initialProfile,
    this.accountEmail = '',
    this.accountSubtitle = '',
    this.completeToHomeOnSave = false,
    this.openPersonalPhotoPickerOnStart = false,
    this.embeddedInProfileScreen = false,
    this.appBarActions = const <Widget>[],
    this.onSaved,
  });

  final PosterProfileData initialProfile;
  final String accountEmail;
  final String accountSubtitle;
  final bool completeToHomeOnSave;
  final bool openPersonalPhotoPickerOnStart;
  final bool embeddedInProfileScreen;
  final List<Widget> appBarActions;
  final ValueChanged<PosterProfileData>? onSaved;

  @override
  State<PosterProfileDetailsScreen> createState() =>
      _PosterProfileDetailsScreenState();
}

class _PosterProfileDetailsScreenState
    extends State<PosterProfileDetailsScreen> {
  static const CloudFirstBackgroundRemovalService _backgroundRemovalService =
      CloudFirstBackgroundRemovalService();
  static const ProfilePhotoGuideService _profilePhotoGuideService =
      ProfilePhotoGuideService();
  static const List<String> _businessLogoStyles = <String>[
    'style_1',
    'style_2',
    'style_3',
    'style_4',
    'style_5',
    'style_6',
    'style_7',
    'style_8',
    'style_9',
    'style_10',
  ];

  late PosterProfileData _draftProfile;
  late PosterProfileData _savedProfile;
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessTaglineController;
  late final TextEditingController _businessWhatsappController;
  final ImagePicker _imagePicker = ImagePicker();
  final OnboardingAudioService _onboardingAudio = OnboardingAudioService();
  final ScrollController _scrollController = ScrollController();
  bool _saving = false;
  bool _personalPhotoBusy = false;
  bool _businessLogoBusy = false;
  bool _pickerBusy = false;
  Future<void>? _backgroundRemoverInitialization;
  AppLanguageController? _languageController;

  @override
  void initState() {
    super.initState();
    _draftProfile = widget.initialProfile;
    _savedProfile = widget.initialProfile;
    _nameController = TextEditingController(
      text: widget.initialProfile.displayName,
    );
    _whatsappController = TextEditingController(
      text: widget.initialProfile.whatsappNumber,
    );
    _businessNameController = TextEditingController(
      text: widget.initialProfile.businessName,
    );
    _businessTaglineController = TextEditingController(
      text: widget.initialProfile.businessTagline,
    );
    _businessWhatsappController = TextEditingController(
      text: widget.initialProfile.businessWhatsappNumber,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ProfilePhotoStylePickerSheet.prewarmTemplate(context: context),
        );
        unawaited(_sanitizeActivePhotoIntegrity());
        // Auto-scroll from top → bottom so user sees all fields
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
    if (widget.openPersonalPhotoPickerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_pickPersonalPhoto());
        }
      });
    }
  }

  Future<void> _sanitizeActivePhotoIntegrity() async {
    try {
      final remoteCutouts =
          await PosterProfileService.fetchReusableCutoutPhotos();
      if (!mounted) return;
      final currentUrl = _draftProfile.photoUrl.trim();
      if (currentUrl.isEmpty) return;
      for (final cutout in remoteCutouts) {
        final key = cutout.downloadUrl.trim();
        if (key == currentUrl) {
          if (cutout.originalUrl.trim().isEmpty &&
              (_draftProfile.originalPhotoUrl.trim().isNotEmpty ||
                  _draftProfile.originalPhotoPath.trim().isNotEmpty)) {
            final cleaned = _draftProfile.copyWith(
              originalPhotoPath: '',
              originalPhotoUrl: '',
              preferOriginalPersonalPhoto: false,
            );
            if (mounted) {
              setState(() => _draftProfile = cleaned);
            }
            widget.onSaved?.call(cleaned);
            await PosterProfileService.savePersonalPhotoAssets(
              photoPath: cleaned.photoPath,
              originalPhotoPath: '',
              photoUrl: cleaned.photoUrl,
              originalPhotoUrl: '',
              preferOriginalPersonalPhoto: false,
              saveRemoteUrls: true,
            );
          }
          break;
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.languageController;
    if (_languageController == controller) {
      return;
    }
    _languageController?.removeListener(_handleLanguageChanged);
    _languageController = controller;
    _languageController?.addListener(_handleLanguageChanged);
  }

  void _handleLanguageChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _businessNameController.dispose();
    _businessTaglineController.dispose();
    _businessWhatsappController.dispose();
    _scrollController.dispose();
    _languageController?.removeListener(_handleLanguageChanged);
    unawaited(_onboardingAudio.dispose());
    super.dispose();
  }

  Future<void> _ensureBackgroundRemovalReady() {
    return _backgroundRemoverInitialization ??= _backgroundRemovalService
        .ensureReady();
  }

  Future<void> _deleteLocalAssetUnlessKept(
    String? path,
    Set<String> keep,
  ) async {
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty || keep.contains(trimmed)) {
      return;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return;
    }
    try {
      final file = File(trimmed);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  String _stagedImageExtension(XFile file) {
    final source = file.name.trim().isNotEmpty ? file.name : file.path;
    final dotIndex = source.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == source.length - 1) {
      return 'jpg';
    }
    final extension = source.substring(dotIndex + 1).toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return extension;
      default:
        return 'jpg';
    }
  }

  Future<File> _stagePickedImageForCrop(
    XFile picked, {
    required String filePrefix,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final stagedFile = File(
      '${tempDir.path}${Platform.pathSeparator}'
      '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.'
      '${_stagedImageExtension(picked)}',
    );
    await stagedFile.writeAsBytes(await picked.readAsBytes(), flush: true);
    return stagedFile;
  }

  Future<void> _deleteFileSilently(File? file) async {
    if (file == null) {
      return;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _openPersonalPhotoPicker() async {
    if (_personalPhotoBusy || _pickerBusy) {
      return;
    }
    final shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FutureBuilder<ProfilePhotoGuideConfig>(
        future: _profilePhotoGuideService.fetchConfig(),
        builder: (context, snapshot) => _ProfilePhotoUploadGuideSheet(
          strings: sheetContext.strings,
          config: snapshot.data ?? const ProfilePhotoGuideConfig(),
          loading: snapshot.connectionState == ConnectionState.waiting,
        ),
      ),
    );
    if (!mounted || shouldContinue != true) {
      return;
    }
    try {
      final remoteCutouts =
          await PosterProfileService.fetchReusableCutoutPhotos();
      final cutouts = _profileCutoutsIncludingCurrent(remoteCutouts);
      if (!mounted) {
        return;
      }
      final action = await Navigator.of(context).push<_ProfilePhotoPickAction>(
        MaterialPageRoute<_ProfilePhotoPickAction>(
          builder: (_) => _ProfilePhotoPickerScreen(
            cutouts: cutouts,
            currentPhotoUrl: _draftProfile.photoUrl,
            currentPhotoPath: _draftProfile.photoPath,
          ),
        ),
      );
      if (!mounted || action == null) {
        return;
      }
      if (action.uploadNew) {
        await _pickPersonalPhoto();
        return;
      }
      final croppedPath = action.croppedPath?.trim() ?? '';
      if (croppedPath.isNotEmpty) {
        await _setPersonalPhotoFromCroppedSavedCutout(
          croppedPath,
          selectedCutout: action.cutout,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Saved profile cutout crop failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'సేవ్ చేసిన ప్రొఫైల్ ఫోటోలు తెరవలేకపోయాం.',
                english: 'Could not open saved profile photos.',
                hindi: 'सहेजे गए प्रोफ़ाइल फ़ोटो नहीं खोले जा सके।',
                tamil:
                    'சேமிக்கப்பட்ட சுயவிவர புகைப்படங்களைத் திறக்க முடியவில்லை.',
                kannada: 'ಉಳಿಸಲಾದ ಪ್ರೊಫೈಲ್ ಫೋಟೋಗಳನ್ನು ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
                malayalam: 'സേവ് ചെയ്ത പ്രൊഫൈൽ ഫോട്ടോകൾ തുറക്കാൻ കഴിഞ്ഞില്ല.',
                marathi: 'सेव्ह केलेले प्रोफाइल फोटो उघडता आले नाहीत.',
                gujarati: 'સાચવેલા પ્રોફાઇલ ફોટા ખોલી શકાયા નથી.',
                bengali: 'সংরক্ষিত প্রোফাইল ছবি খোলা যায়নি।',
                punjabi:
                    'ਸੁਰੱਖਿਅਤ ਕੀਤੀਆਂ ਪ੍ਰੋਫਾਈਲ ਫੋਟੋਆਂ ਖੋਲ੍ਹੀਆਂ ਨਹੀਂ ਜਾ ਸਕੀਆਂ।',
                odia: 'ସେଭ୍ ହୋଇଥିବା ପ୍ରୋଫାଇଲ୍ ଫଟୋ ଖୋଲିପାରିଲା ନାହିଁ।',
                assamese: 'সংৰক্ষিত প্ৰʼফাইল ফটোসমূহ খোলিব পৰা নগʼল।',
                konkani: 'ಸಾಂಭಾಳ್ಳೆ ಪ್ರೊಫೈಲ್ ಫೋಟೋ ಉಗ್ತೆಂ ಕರುಂಕ್ ಜಾಲೆಂ ನಾ.',
                nepali: 'सुरक्षित गरिएका प्रोफाइल तस्बिरहरू खोल्न सकिएन।',
                meitei: 'সেভ তৌবা প্রোফাইল ফোতোশিং হাংদোকপা ঙমদ্রে।',
                mizo: 'Profile thlalak save tawhte hawn theih a ni lo.',
                kashmiri: 'مَحفوٗظ کٔرِتھ پروفائل فوٹو ہیکؠ نہٕ کھٔلِتھ۔',
                ladakhi: 'ཉར་ཚགས་བྱས་པའི་གསལ་བཤད་འདྲ་པར་རྣམས་ཕྱེ་མ་ཐུབ།',
              ),
            ),
          ),
        );
      }
    }
  }

  List<UserSavedCutoutPhoto> _profileCutoutsIncludingCurrent(
    List<UserSavedCutoutPhoto> remoteCutouts,
  ) {
    final currentPhotoPath = _draftProfile.photoPath.trim();
    final currentPhotoUrl = _draftProfile.photoUrl.trim();
    if (currentPhotoPath.isEmpty && currentPhotoUrl.isEmpty) {
      return remoteCutouts;
    }
    final currentKey = currentPhotoUrl.isNotEmpty
        ? currentPhotoUrl
        : currentPhotoPath;
    UserSavedCutoutPhoto? matchingRemote;
    for (final cutout in remoteCutouts) {
      final key = cutout.downloadUrl.trim().isNotEmpty
          ? cutout.downloadUrl.trim()
          : cutout.localPath.trim();
      if (key.isNotEmpty && key == currentKey) {
        matchingRemote = cutout;
        break;
      }
    }
    final current = UserSavedCutoutPhoto(
      id:
          matchingRemote?.id ??
          'current_profile_${_draftProfile.personalPhotoRevision}',
      downloadUrl: currentPhotoUrl,
      localPath: currentPhotoPath,
      originalUrl: matchingRemote != null
          ? matchingRemote.originalUrl.trim()
          : _draftProfile.originalPhotoUrl.trim(),
      originalLocalPath: matchingRemote != null
          ? matchingRemote.originalLocalPath.trim()
          : _draftProfile.originalPhotoPath.trim(),
      source: 'current_profile',
      createdAt: matchingRemote?.createdAt,
    );
    final merged = <UserSavedCutoutPhoto>[current];
    for (final cutout in remoteCutouts) {
      final key = cutout.downloadUrl.trim().isNotEmpty
          ? cutout.downloadUrl.trim()
          : cutout.localPath.trim();
      if (key.isEmpty || key == currentKey) {
        continue;
      }
      merged.add(cutout);
    }
    return merged;
  }

  Future<void> _setPersonalPhotoFromCroppedSavedCutout(
    String croppedPath, {
    UserSavedCutoutPhoto? selectedCutout,
  }) async {
    if (_personalPhotoBusy) {
      return;
    }
    setState(() {
      _personalPhotoBusy = true;
      _pickerBusy = true;
    });
    try {
      final croppedBytes = await File(croppedPath).readAsBytes();
      final Directory dir = await getApplicationDocumentsDirectory();
      final revision = DateTime.now().millisecondsSinceEpoch;
      final targetPath =
          '${dir.path}${Platform.pathSeparator}poster_profile_photo_$revision.png';
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(croppedBytes, flush: true);

      final String targetOriginalPath =
          selectedCutout?.originalLocalPath.trim() ?? '';
      final String targetOriginalUrl = selectedCutout?.originalUrl.trim() ?? '';
      final bool hasOriginal =
          targetOriginalPath.isNotEmpty || targetOriginalUrl.isNotEmpty;

      final keepNewPersonalAssets = <String>{
        targetPath,
        if (targetOriginalPath.isNotEmpty) targetOriginalPath,
      };
      await _deleteLocalAssetUnlessKept(
        _draftProfile.photoPath,
        keepNewPersonalAssets,
      );
      if (_draftProfile.originalPhotoPath != targetOriginalPath &&
          _draftProfile.originalPhotoPath.trim().isNotEmpty) {
        await _deleteLocalAssetUnlessKept(
          _draftProfile.originalPhotoPath,
          keepNewPersonalAssets,
        );
      }
      final previousProfile = _draftProfile;
      await PosterProfileService.evictRemoteProfilePhotoCache(previousProfile);
      final updatedProfile = _draftProfile.copyWith(
        photoPath: targetPath,
        photoUrl: '',
        originalPhotoPath: targetOriginalPath,
        originalPhotoUrl: targetOriginalUrl,
        preferOriginalPersonalPhoto: hasOriginal
            ? _draftProfile.preferOriginalPersonalPhoto
            : false,
        personalPhotoRevision: revision,
      );
      await PosterProfileService.savePersonalPhotoAssets(
        photoPath: updatedProfile.photoPath,
        originalPhotoPath: updatedProfile.originalPhotoPath,
        photoUrl: updatedProfile.photoUrl,
        originalPhotoUrl: updatedProfile.originalPhotoUrl,
        preferOriginalPersonalPhoto: updatedProfile.preferOriginalPersonalPhoto,
        saveRemoteUrls: true,
        personalPhotoRevision: revision,
      );
      if (mounted) {
        setState(() {
          _draftProfile = updatedProfile;
        });
      }
      unawaited(
        _syncSavedCutoutProfileUpload(
          baseProfile: updatedProfile,
          cutoutLocalFile: targetFile,
          selectedCutout: selectedCutout,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Set saved profile cutout failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'సేవ్ చేసిన ప్రొఫైల్ ఫోటో సెట్ చేయలేకపోయాం.',
                english: 'Could not set saved profile photo.',
                hindi: 'सहेजे गए प्रोफ़ाइल फ़ोटो को सेट नहीं किया जा सका।',
                tamil: 'சேமித்த சுயவிவரப் புகைப்படத்தை அமைக்க முடியவில்லை.',
                kannada: 'ಉಳಿಸಲಾದ ಪ್ರೊಫೈಲ್ ಫೋಟೋ ಹೊಂದಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
                malayalam:
                    'സേവ് ചെയ്ത പ്രൊഫൈൽ ഫോട്ടോ സെറ്റ് ചെയ്യാൻ കഴിഞ്ഞില്ല.',
                marathi: 'सेव्ह केलेला प्रोफाइल फोटो सेट करता आला नाही.',
                gujarati: 'સાચવેલ પ્રોફાઇલ ફોટો સેટ કરી શકાયો નથી.',
                bengali: 'সংরক্ষিত প্রোফাইল ছবি সেট করা যায়নি।',
                punjabi: 'ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਪ੍ਰੋਫਾਈਲ ਫੋਟੋ ਸੈੱਟ ਨਹੀਂ ਕੀਤੀ ਜਾ ਸਕੀ।',
                odia: 'ସେଭ୍ ହୋଇଥିବା ପ୍ରୋଫାଇଲ୍ ଫଟୋ ସେଟ୍ କରିପାରିଲା ନାହିଁ।',
                assamese: 'সংৰক্ষিত প্ৰʼফাইল ফটো ছেট কৰিব পৰা নগʼল।',
                konkani: 'ಸಾಂಭಾಳ್ಳೊ ಪ್ರೊಫೈಲ್ ಫೋಟೋ ಸೆಟ್ ಕರುಂಕ್ ಜಾಲೆಂ ನಾ.',
                nepali: 'सुरक्षित गरिएको प्रोफाइल तस्बिर सेट गर्न सकिएन।',
                meitei: 'সেভ তৌবা প্রোফাইল ফোতো সেত তৌবা ঙমদ্রে।',
                mizo: 'Profile thlalak save tawh set theih a ni lo.',
                kashmiri: 'مَحفوٗظ شُدٕ پروفائل فوٹو ہیۆک نہٕ سیٹ کٔرِتھ۔',
                ladakhi: 'ཉར་ཚགས་བྱས་པའི་གསལ་བཤད་འདྲ་པར་གཏན་འབེབས་བྱེད་མ་ཐུབ།',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _personalPhotoBusy = false;
          _pickerBusy = false;
        });
      }
    }
  }

  Future<bool> _syncSavedCutoutProfileUpload({
    required PosterProfileData baseProfile,
    required File cutoutLocalFile,
    UserSavedCutoutPhoto? selectedCutout,
  }) async {
    try {
      final cutoutRemoteUrl = await PosterProfileService.uploadProfilePhoto(
        file: cutoutLocalFile,
        extension: 'png',
      );
      if (cutoutRemoteUrl.trim().isNotEmpty) {
        await PosterProfileService.saveReusableCutoutPhoto(
          cutoutFile: cutoutLocalFile,
          downloadUrl: cutoutRemoteUrl,
          originalUrl: baseProfile.originalPhotoUrl,
          originalLocalPath: baseProfile.originalPhotoPath,
          personalPhotoRevision: baseProfile.personalPhotoRevision,
        );
      }
      final updatedProfile = baseProfile.copyWith(
        photoUrl: cutoutRemoteUrl.isEmpty
            ? baseProfile.photoUrl
            : cutoutRemoteUrl,
        personalPhotoRevision: DateTime.now().millisecondsSinceEpoch,
      );
      await PosterProfileService.savePersonalPhotoAssets(
        photoPath: updatedProfile.photoPath,
        originalPhotoPath: updatedProfile.originalPhotoPath,
        photoUrl: updatedProfile.photoUrl,
        originalPhotoUrl: updatedProfile.originalPhotoUrl,
        preferOriginalPersonalPhoto: updatedProfile.preferOriginalPersonalPhoto,
        saveRemoteUrls: true,
        personalPhotoRevision: updatedProfile.personalPhotoRevision,
      );
      if (!mounted) {
        return true;
      }
      setState(() {
        _draftProfile = updatedProfile;
        if (_isSameProfileChangeIgnoringRemoteUrls(
          _savedProfile,
          updatedProfile,
        )) {
          _savedProfile = updatedProfile;
        }
      });
      return true;
    } catch (error, stackTrace) {
      debugPrint('Saved cutout profile sync failed: $error\n$stackTrace');
      return false;
    }
  }

  void _showPhotoLimitReachedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFEAB308)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.strings.localized(
                    telugu: 'పరిమితి పూర్తయింది',
                    english: 'Limit Reached',
                    hindi: 'सीमा समाप्त',
                    tamil: 'வரம்பு முடிந்தது',
                    kannada: 'ಮಿತಿ ಮೀರಿದೆ',
                    malayalam: 'പരിധി കഴിഞ്ഞു',
                    marathi: 'मर्यादा संपली',
                    gujarati: 'મર્યાદા પૂર્ણ',
                    bengali: 'সীমা সমাপ্ত',
                    punjabi: 'ਸੀਮਾ ਪੂਰੀ ਹੋ ਗਈ',
                    odia: 'ସୀମା ସମାପ୍ତ',
                    assamese: 'সীমা সমাপ্ত',
                    konkani: 'ಮರ್ಯಾದಾ ಸಂಪ್ಲಿ',
                    nepali: 'सीमा समाप्त',
                    meitei: 'Limit Reached',
                    mizo: 'Limit Reached',
                    kashmiri: 'حد ختم',
                    ladakhi: 'Limit Reached',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            context.strings.localized(
              telugu:
                  'గరిష్టంగా 5 ఫోటోలు మాత్రమే సేవ్ చేయవచ్చు. కొత్త ఫోటో అప్‌లోడ్ చేయడానికి దయచేసి పాత ఫోటోలలో ఒకదాన్ని తొలగించండి.',
              english:
                  'You can save a maximum of 5 photos. Please delete an older photo to upload a new one.',
              hindi:
                  'आप अधिकतम 5 फ़ोटो ही सहेज सकते हैं। नई फ़ोटो अपलोड करने के लिए कृपया पुरानी फ़ोटो में से एक हटाएं।',
              tamil:
                  'நீங்கள் அதிகபட்சமாக 5 புகைப்படங்களை மட்டுமே சேமிக்க முடியும். புதிய புகைப்படத்தைப் பதிவேற்ற பழைய புகைப்படங்களில் ஒன்றை நீக்கவும்.',
              kannada:
                  'ನೀವು ಗರಿಷ್ಠ 5 ಫೋಟೋಗಳನ್ನು ಮಾತ್ರ ಉಳಿಸಬಹುದು. ಹೊಸ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಲು ದಯವಿಟ್ಟು ಹಳೆಯ ಫೋಟೋಗಳಲ್ಲಿ ಒಂದನ್ನು ಅಳಿಸಿ.',
              malayalam:
                  'നിങ്ങൾക്ക് പരമാവധി 5 ഫോട്ടോകൾ മാത്രമേ സംരക്ഷിക്കാനാകൂ. പുതിയ ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യാൻ പഴയ ഫോട്ടോകളിൽ ഒന്ന് ഇല്ലാതാക്കുക.',
              marathi:
                  'तुम्ही जास्तीत जास्त 5 फोटो सेव्ह करू शकता. नवीन फोटो अपलोड करण्यासाठी कृपया जुना फोटो हटवा.',
              gujarati:
                  'તમે વધુમાં વધુ 5 ફોટા સાચવી શકો છો. નવો ફોટો અપલોડ કરવા માટે જૂનો ફોટો કાઢી નાખો.',
              bengali:
                  'আপনি সর্বোচ্চ ৫টি ছবি সংরক্ষণ করতে পারেন। নতুন ছবি আপলোড করতে পুরানো ছবি মুছুন।',
              punjabi:
                  'ਤੁਸੀਂ ਵੱਧ ਤੋਂ ਵੱਧ 5 ਫੋਟੋਆਂ ਸੁਰੱਖਿਅਤ ਕਰ ਸਕਦੇ ਹੋ। ਨਵੀਂ ਫੋਟੋ ਅੱਪਲੋਡ ਕਰਨ ਲਈ ਪੁਰਾਣੀ ਫੋਟੋ ਮਿਟਾਓ।',
              odia:
                  'ଆପଣ ସର୍ବାଧିକ 5 ଫଟୋ ସଂରକ୍ଷଣ କରିପାରିବେ। ନୂଆ ଫଟୋ ଅପଲୋଡ୍ କରିବାକୁ ପୁରୁଣା ଫଟୋ ବିଲୋପ କରନ୍ତୁ।',
              assamese:
                  'আপুনি সৰ্বাধিক ৫ খন ফটো সংৰক্ষণ কৰিব পাৰে। নতুন ফটো আপলোড কৰিবলৈ পুৰণি ফটো বিলোপ কৰক।',
              konkani:
                  'ತುಮಿ ಚಡಾಂತ್ ಚಡ್ 5 ಫೋಟೋ ಸಾಂಪಾಳ್ನ್ ದವರಿಂಕ್ ಜಾತಾ. ನವೋ ಫೋಟೋ ಅಪ್ಲೋಡ್ ಕರುಂಕ್ ಪರನೊ ಫೋಟೋ ಕಾಡ್ನ್ ಉಡಯಾ.',
              nepali:
                  'तपाईं अधिकतम ५ वटा तस्बिर मात्र सुरक्षित गर्न सक्नुहुन्छ। नयाँ तस्बिर अपलोड गर्न पुरानो तस्बिर मेटाउनुहोस्।',
              meitei:
                  'You can only save up to 5 photos. Please delete an older photo before uploading a new one.',
              mizo:
                  'You can only save up to 5 photos. Please delete an older photo before uploading a new one.',
              kashmiri:
                  'تہہ ہیکیو صرف 5 فوٹو محفوظ کٔرتھ۔ نٔو فوٹو اپلوڈ کرنہٕ باپتھ کٔریو پرٛون فوٹو ڈیلیٹ۔',
              ladakhi:
                  'You can only save up to 5 photos. Please delete an older photo before uploading a new one.',
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                context.strings.localized(
                  telugu: 'సరే',
                  english: 'OK',
                  hindi: 'ठीक है',
                  tamil: 'சரி',
                  kannada: 'ಸರಿ',
                  malayalam: 'ശരി',
                  marathi: 'ठीक आहे',
                  gujarati: 'બરાબર',
                  bengali: 'ঠিক আছে',
                  punjabi: 'ਠੀਕ ਹੈ',
                  odia: 'ଠିକ୍ ଅଛି',
                  assamese: 'ঠিক আছে',
                  konkani: 'ಬರೆಂ',
                  nepali: 'हुन्छ',
                  meitei: 'OK',
                  mizo: 'Awle',
                  kashmiri: 'ٹھیک چھُ',
                  ladakhi: 'OK',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickPersonalPhoto() async {
    if (_personalPhotoBusy || _pickerBusy) {
      return;
    }
    final existingCutouts =
        await PosterProfileService.fetchReusableCutoutPhotos();
    if (!mounted) {
      return;
    }
    if (existingCutouts.length >= 5) {
      _showPhotoLimitReachedDialog();
      return;
    }
    final strings = context.strings;
    setState(() {
      _personalPhotoBusy = true;
      _pickerBusy = true;
    });
    File? stagedCropSourceFile;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) {
        return;
      }
      stagedCropSourceFile = await _stagePickedImageForCrop(
        picked,
        filePrefix: 'poster_profile_pick',
      );
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: stagedCropSourceFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: strings.localized(
              telugu: 'ఫోటో క్రాప్ చేయండి',
              english: 'Crop Photo',
              hindi: 'फोटो क्रॉप करें',
              tamil: 'புகைப்படத்தை கிராப் செய்யவும்',
              kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'फोटो क्रॉप करा',
              gujarati: 'ફોટો ક્રોપ કરો',
              bengali: 'ছবি ক্রপ করুন',
              punjabi: 'ਫੋਟੋ ਕੱਟੋ',
              odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'ফটো ক্ৰপ কৰক',
              konkani: 'ಫೋಟೋ ಕ್ರಾಪ್ ಕರಾ',
              nepali: 'फोटो क्रप गर्नुहोस्',
              meitei: 'ফোতো ক্রোপ তৌরো',
              mizo: 'Thlalak kual rawh',
              kashmiri: 'فوٹو کٔریو کراپ',
              ladakhi: 'འདྲ་པར་དྲ་བཅད་གྱིས།',
            ),
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF0F172A),
            activeControlsWidgetColor: const Color(0xFF2563EB),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: strings.localized(
              telugu: 'ఫోటో క్రాప్ చేయండి',
              english: 'Crop Photo',
              hindi: 'फोटो क्रॉप करें',
              tamil: 'புகைப்படத்தை கிராப் செய்யவும்',
              kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'फोटो क्रॉप करा',
              gujarati: 'ફોટો ક્રોપ કરો',
              bengali: 'ছবি ক্রপ করুন',
              punjabi: 'ਫੋਟੋ ਕੱਟੋ',
              odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'ফটো ক্ৰপ কৰক',
              konkani: 'ಫೋಟೋ ಕ್ರಾಪ್ ಕರಾ',
              nepali: 'फोटो क्रप गर्नुहोस्',
              meitei: 'ফোতো ক্রোপ তৌরো',
              mizo: 'Thlalak kual rawh',
              kashmiri: 'فوٹو کٔریو کراپ',
              ladakhi: 'འདྲ་པར་དྲ་བཅད་གྱིས།',
            ),
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (cropped == null) {
        return;
      }
      final originalBytes = await File(cropped.path).readAsBytes();
      final optimizedOriginalBytes = await compute(
        _optimizeProfilePhotoBytes,
        originalBytes,
      );
      if (!mounted) {
        return;
      }
      final personalPhotoRevision = DateTime.now().millisecondsSinceEpoch;
      // Pre-warm template in parallel while background removal is running!
      final templatePrewarmFuture =
          ProfilePhotoStylePickerSheet.prewarmTemplate(context: context);
      // Wait for BG removal to fully finish (success or null = failed) before
      // showing the choice screen — user should never see a loading spinner.
      final Uint8List? resolvedCutoutBytes =
          await _removePersonalPhotoBackground(optimizedOriginalBytes);
      final prewarmedTemplate = await templatePrewarmFuture;

      final Directory dir = await getApplicationDocumentsDirectory();
      final String stamp = personalPhotoRevision.toString();
      final String originalTargetPath =
          '${dir.path}${Platform.pathSeparator}poster_profile_original_photo_$stamp.png';
      final String cutoutTargetPath =
          '${dir.path}${Platform.pathSeparator}poster_profile_photo_$stamp.png';
      final File originalLocalFile = File(originalTargetPath);
      final File cutoutLocalFile = File(cutoutTargetPath);

      // Save original always; save cutout only if BG removal succeeded
      await originalLocalFile.writeAsBytes(optimizedOriginalBytes, flush: true);
      if (resolvedCutoutBytes != null && resolvedCutoutBytes.isNotEmpty) {
        await cutoutLocalFile.writeAsBytes(resolvedCutoutBytes, flush: true);
      }

      if (!mounted) {
        return;
      }

      final bool hasCutout =
          resolvedCutoutBytes != null && resolvedCutoutBytes.isNotEmpty;

      // Show the style picker sheet with pre-resolved bytes & instant pre-warmed template!
      final styleResult = await ProfilePhotoStylePickerSheet.show(
        context: context,
        originalBytes: optimizedOriginalBytes,
        cutoutBytes: resolvedCutoutBytes,
        originalPhotoPath: originalTargetPath,
        cutoutPhotoPath: hasCutout ? cutoutTargetPath : null,
        profile: _draftProfile,
        initialTemplate: prewarmedTemplate,
        initialPreferOriginal: _draftProfile.preferOriginalPersonalPhoto,
      );

      // If user dismissed sheet without choosing, default: cutout if available, else original
      final bool preferOriginal =
          styleResult?.preferOriginal ??
          (resolvedCutoutBytes == null || resolvedCutoutBytes.isEmpty);
      final Uint8List? finalCutoutBytes = resolvedCutoutBytes;

      final hasValidCutout =
          finalCutoutBytes != null && finalCutoutBytes.isNotEmpty;
      final effectivePreferOriginal = preferOriginal || !hasValidCutout;

      if (hasValidCutout) {
        await cutoutLocalFile.writeAsBytes(finalCutoutBytes, flush: true);
      }

      final Set<String> keepNewPersonalAssets = <String>{
        originalTargetPath,
        cutoutTargetPath,
        if (hasValidCutout) cutoutTargetPath,
      };
      await _deleteLocalAssetUnlessKept(
        _draftProfile.photoPath,
        keepNewPersonalAssets,
      );
      await _deleteLocalAssetUnlessKept(
        _draftProfile.originalPhotoPath,
        keepNewPersonalAssets,
      );
      final previousProfile = _draftProfile;
      await PosterProfileService.evictRemoteProfilePhotoCache(previousProfile);
      final updatedLocalProfile = _draftProfile.copyWith(
        photoPath: hasValidCutout ? cutoutTargetPath : originalTargetPath,
        photoUrl: '',
        originalPhotoPath: originalTargetPath,
        originalPhotoUrl: '',
        preferOriginalPersonalPhoto: effectivePreferOriginal,
        personalPhotoRevision: personalPhotoRevision,
      );
      try {
        await PosterProfileService.savePersonalPhotoAssets(
          photoPath: updatedLocalProfile.photoPath,
          originalPhotoPath: updatedLocalProfile.originalPhotoPath,
          photoUrl: '',
          originalPhotoUrl: '',
          preferOriginalPersonalPhoto: effectivePreferOriginal,
          saveRemoteUrls: false,
          personalPhotoRevision: personalPhotoRevision,
        );
      } catch (_) {}
      if (mounted) {
        setState(() {
          _draftProfile = updatedLocalProfile;
          _personalPhotoBusy = false;
          _pickerBusy = false;
        });
        widget.onSaved?.call(updatedLocalProfile);
      }
      unawaited(
        _syncPersonalPhotoUploads(
          baseProfile: updatedLocalProfile,
          originalLocalFile: originalLocalFile,
          cutoutLocalFile: hasValidCutout ? cutoutLocalFile : null,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Personal photo update failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu: 'వ్యక్తిగత ఫోటో అప్‌డేట్ కాలేదు',
              english: 'Personal photo update failed',
              hindi: 'व्यक्तिगत फ़ोटो अपडेट विफल रहा',
              tamil: 'தனிப்பட்ட புகைப்படம் புதுப்பிப்பு தோல்வியடைந்தது',
              kannada: 'ವೈಯಕ್ತಿಕ ಫೋಟೋ ಅಪ್‌ಡೇಟ್ ವಿಫಲವಾಗಿದೆ',
              malayalam: 'വ്യക്തിഗത ഫോട്ടോ അപ്‌ഡേറ്റ് പരാജയപ്പെട്ടു',
              marathi: 'वैयक्तिक फोटो अपडेट अयशस्वी',
              gujarati: 'વ્યક્તિગત ફોટો અપડેટ નિષ્ફળ',
              bengali: 'ব্যক্তিগত ছবি আপডেট ব্যর্থ হয়েছে',
              punjabi: 'ਨਿੱਜੀ ਫੋਟੋ ਅੱਪਡੇਟ ਅਸਫਲ ਰਿਹਾ',
              odia: 'ବ୍ୟକ୍ତିଗତ ଫଟୋ ଅପଡେଟ୍ ବିଫଳ ହେଲା',
              assamese: 'ব্যক্তিগত ফটো আপডেট বিফল হʼল',
              konkani: 'ಖಾಸ್ಗಿ ಫೋಟೋ ಅಪ್‌ಡೇಟ್ ಅಸಫಲ್ ಜಾಲೆಂ',
              nepali: 'व्यक्तिगत फोटो अपडेट असफल भयो',
              meitei: 'ব্যক্তিগত ফোতো অপদেত মায় পাকখিদ্রে',
              mizo: 'Mahni thlalak thar siam theih a ni lo',
              kashmiri: 'ذٲتی فوٹو اَپڈیٹ گۆو نا کامیاب',
              ladakhi: 'སྒེར་གྱི་འདྲ་པར་དུས་ཐོག་མཐུན་བཟོ་མ་ཐུབ།',
            ),
          ),
        ),
      );
    } finally {
      if (stagedCropSourceFile != null) {
        unawaited(_deleteFileSilently(stagedCropSourceFile));
      }
      if (mounted) {
        setState(() {
          _personalPhotoBusy = false;
          _pickerBusy = false;
        });
      }
    }
  }

  Future<bool> _syncPersonalPhotoUploads({
    required PosterProfileData baseProfile,
    required File originalLocalFile,
    required File? cutoutLocalFile,
  }) async {
    try {
      final originalRemoteUrl = await PosterProfileService.uploadProfilePhoto(
        file: originalLocalFile,
        extension: 'png',
        isOriginal: true,
      );
      String cutoutRemoteUrl = '';
      if (cutoutLocalFile != null) {
        cutoutRemoteUrl = await PosterProfileService.uploadProfilePhoto(
          file: cutoutLocalFile,
          extension: 'png',
        );
        if (cutoutRemoteUrl.trim().isNotEmpty) {
          await PosterProfileService.saveReusableCutoutPhoto(
            cutoutFile: cutoutLocalFile,
            downloadUrl: cutoutRemoteUrl,
            originalUrl: originalRemoteUrl,
            originalLocalPath: originalLocalFile.path,
            personalPhotoRevision: baseProfile.personalPhotoRevision,
          );
        }
      }

      final updatedProfile = baseProfile.copyWith(
        photoUrl: cutoutRemoteUrl.isEmpty
            ? baseProfile.photoUrl
            : cutoutRemoteUrl,
        originalPhotoUrl: originalRemoteUrl.isEmpty
            ? baseProfile.originalPhotoUrl
            : originalRemoteUrl,
        personalPhotoRevision: DateTime.now().millisecondsSinceEpoch,
      );
      await PosterProfileService.savePersonalPhotoAssets(
        photoPath: updatedProfile.photoPath,
        originalPhotoPath: updatedProfile.originalPhotoPath,
        photoUrl: updatedProfile.photoUrl,
        originalPhotoUrl: updatedProfile.originalPhotoUrl,
        preferOriginalPersonalPhoto: updatedProfile.preferOriginalPersonalPhoto,
        saveRemoteUrls: true,
        personalPhotoRevision: updatedProfile.personalPhotoRevision,
      );

      if (!mounted) {
        return true;
      }
      setState(() {
        _draftProfile = updatedProfile;
        if (_isSameProfileChangeIgnoringRemoteUrls(
          _savedProfile,
          updatedProfile,
        )) {
          _savedProfile = updatedProfile;
        }
      });
      widget.onSaved?.call(updatedProfile);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Profile photo cloud sync failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<Uint8List?> _removePersonalPhotoBackground(
    Uint8List optimizedOriginalBytes,
  ) async {
    Future<Uint8List?> attempt(Uint8List sourceBytes, Duration timeout) async {
      await _ensureBackgroundRemovalReady();
      final removedResult = await _backgroundRemovalService
          .removeBackground(sourceBytes, cloudPurpose: 'profile_photo')
          .timeout(timeout);
      return removedResult.pngBytes;
    }

    try {
      return await attempt(optimizedOriginalBytes, const Duration(seconds: 75));
    } catch (error, stackTrace) {
      debugPrint(
        'Profile photo background removal failed: $error\n$stackTrace',
      );
      try {
        final smallerBytes = await compute(
          _prepareProfilePhotoRemovalBytes,
          optimizedOriginalBytes,
        );
        return await attempt(smallerBytes, const Duration(seconds: 75));
      } catch (fallbackError, fallbackStackTrace) {
        debugPrint(
          'Profile photo background removal fallback failed: '
          '$fallbackError\n$fallbackStackTrace',
        );
        return null;
      }
    }
  }

  Future<void> _pickBusinessLogo() async {
    if (_businessLogoBusy || _pickerBusy) {
      return;
    }
    final strings = context.strings;
    setState(() {
      _businessLogoBusy = true;
      _pickerBusy = true;
    });
    File? stagedCropSourceFile;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) {
        return;
      }
      stagedCropSourceFile = await _stagePickedImageForCrop(
        picked,
        filePrefix: 'poster_business_logo_pick',
      );
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: stagedCropSourceFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: strings.localized(
              telugu: 'లోగో క్రాప్ చేయండి',
              english: 'Crop Logo',
              hindi: 'लोगो क्रॉप करें',
              tamil: 'லோகோவை கிராப் செய்யவும்',
              kannada: 'ಲೋಗೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ലോഗോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'लोगो क्रॉप करा',
              gujarati: 'લોગો ક્રોપ કરો',
              bengali: 'লোগো ক্রপ করুন',
              punjabi: 'ਲੋਗੋ ਕੱਟੋ',
              odia: 'ଲୋଗୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'লগʼ ক্ৰপ কৰক',
              konkani: 'ಲೋಗೋ ಕ್ರಾಪ್ ಕರಾ',
              nepali: 'लोगो क्रप गर्नुहोस्',
              meitei: 'লোগো ক্রোপ তৌরো',
              mizo: 'Logo kual rawh',
              kashmiri: 'لوگو کٔریو کراپ',
              ladakhi: 'ཚོང་རྟགས་དྲ་བཅད་གྱིས།',
            ),
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF0F172A),
            activeControlsWidgetColor: const Color(0xFF2563EB),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: strings.localized(
              telugu: 'లోగో క్రాప్ చేయండి',
              english: 'Crop Logo',
              hindi: 'लोगो क्रॉप करें',
              tamil: 'லோகோவை கிராப் செய்யவும்',
              kannada: 'ಲೋಗೋ ಕ್ರಾಪ್ ಮಾಡಿ',
              malayalam: 'ലോഗോ ക്രോപ്പ് ചെയ്യുക',
              marathi: 'लोगो क्रॉप करा',
              gujarati: 'લોગો ક્રોપ કરો',
              bengali: 'লোগো ক্রপ করুন',
              punjabi: 'ਲੋਗੋ ਕੱਟੋ',
              odia: 'ଲୋଗୋ କ୍ରପ୍ କରନ୍ତୁ',
              assamese: 'লগʼ ক্ৰপ কৰক',
              konkani: 'ಲೋಗೋ ಕ್ರಾಪ್ ಕರಾ',
              nepali: 'लोगो क्रप गर्नुहोस्',
              meitei: 'লোগো ক্রোপ তৌরো',
              mizo: 'Logo kual rawh',
              kashmiri: 'لوگو کٔریو کراپ',
              ladakhi: 'ཚོང་རྟགས་དྲ་བཅད་གྱིས།',
            ),
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (cropped == null) {
        return;
      }
      final logoBytes = await File(cropped.path).readAsBytes();
      final Directory dir = await getApplicationDocumentsDirectory();
      final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String targetPath =
          '${dir.path}${Platform.pathSeparator}poster_business_logo_$stamp.png';
      final File localFile = File(targetPath);
      await localFile.writeAsBytes(logoBytes, flush: true);
      await _deleteLocalAssetUnlessKept(
        _draftProfile.businessLogoPath,
        <String>{targetPath},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _draftProfile = _draftProfile.copyWith(
          identityMode: PosterIdentityMode.business,
          businessLogoPath: targetPath,
          businessLogoUrl: '',
        );
      });
      await PosterProfileService.saveBusinessLogoAssets(
        businessLogoPath: targetPath,
        identityMode: PosterIdentityMode.business,
      );
      unawaited(_syncBusinessLogoUpload(localFile));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu: 'వ్యాపార లోగో అప్‌డేట్ కాలేదు',
              english: 'Business logo update failed',
              hindi: 'व्यावसायिक लोगो अपडेट विफल रहा',
              tamil: 'வணிக லோகோ புதுப்பிப்பு தோல்வியடைந்தது',
              kannada: 'ವ್ಯವಹಾರ ಲೋಗೋ ಅಪ್‌ಡೇಟ್ ವಿಫಲವಾಗಿದೆ',
              malayalam: 'ബിസിനസ്സ് ലോഗോ അപ്‌ഡേറ്റ് പരാജയപ്പെട്ടു',
              marathi: 'व्यवसाय लोगो अपडेट अयशस्वी',
              gujarati: 'વ્યવસાયિક લોગો અપડેટ નિષ્ફળ',
              bengali: 'ব্যবসায়িক লোগো আপডেট ব্যর্থ হয়েছে',
              punjabi: 'ਕਾਰੋਬਾਰੀ ਲੋਗੋ ਅੱਪਡੇਟ ਅਸਫਲ ਰਿਹਾ',
              odia: 'ବ୍ୟବସାୟ ଲୋଗୋ ଅପଡେଟ୍ ବିଫଳ ହେଲା',
              assamese: 'ব্যৱসায়িক লʼগʼ আপডেট বিফল হʼল',
              konkani: 'ವ್ಯವಹಾರಾಚೆಂ ಲೋಗೋ ಅಪ್‌ಡೇಟ್ ಅಸಫಲ್ ಜಾಲೆಂ',
              nepali: 'व्यापार लोगो अपडेट असफल भयो',
              meitei: 'লল্লোন-ইতিক্কী লোগো অপদেত মায় পাকখিদ্রে',
              mizo: 'Sumdawnna logo siam thar theih a ni lo',
              kashmiri: 'کٲروبٲری لوگو اَپڈیٹ گۆو نا کامیاب',
              ladakhi: 'ཚོང་ལས་རྟགས་དུས་ཐོག་མཐུན་བཟོ་མ་ཐུབ།',
            ),
          ),
        ),
      );
    } finally {
      if (stagedCropSourceFile != null) {
        unawaited(_deleteFileSilently(stagedCropSourceFile));
      }
      if (mounted) {
        setState(() {
          _businessLogoBusy = false;
          _pickerBusy = false;
        });
      }
    }
  }

  Future<void> _syncBusinessLogoUpload(File localFile) async {
    try {
      final remoteUrl = await PosterProfileService.uploadBusinessLogo(
        file: localFile,
        extension: 'png',
      );
      if (remoteUrl.trim().isEmpty) {
        return;
      }
      final updatedProfile = _draftProfile.copyWith(
        identityMode: PosterIdentityMode.business,
        businessLogoUrl: remoteUrl,
      );
      await PosterProfileService.saveBusinessLogoAssets(
        businessLogoPath: updatedProfile.businessLogoPath,
        businessLogoUrl: updatedProfile.businessLogoUrl,
        identityMode: PosterIdentityMode.business,
        saveRemoteUrl: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _draftProfile = updatedProfile;
        if (_isSameProfileChangeIgnoringRemoteUrls(
          _savedProfile,
          updatedProfile,
        )) {
          _savedProfile = updatedProfile;
        }
      });
    } catch (_) {
      // Local business logo preview is already ready; remote sync can retry later.
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) {
      return;
    }
    final updated = _currentProfileFromInputs();
    if (!_hasUnsavedChanges) {
      if (widget.completeToHomeOnSave) {
        final nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed(nextRoute);
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await PosterProfileService.save(updated);
      if (!mounted) {
        return;
      }
      if (widget.completeToHomeOnSave) {
        final nextRoute = await AppFlowService.resolveAuthenticatedEntryRoute();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed(nextRoute);
      } else if (widget.embeddedInProfileScreen) {
        widget.onSaved?.call(updated);
        setState(() {
          _draftProfile = updated;
          _savedProfile = updated;
        });
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'ప్రొఫైల్ సేవ్ అయింది',
                english: 'Profile saved',
                hindi: 'प्रोफ़ाइल सहेजी गई',
                tamil: 'சுயவிவரம் சேமிக்கப்பட்டது',
                kannada: 'ಪ್ರೊಫೈಲ್ ಉಳಿಸಲಾಗಿದೆ',
                malayalam: 'പ്രൊഫൈൽ സേവ് ചെയ്തു',
                marathi: 'प्रोफाइल सेव्ह केली',
                gujarati: 'પ્રોફાઇલ સાચવી',
                bengali: 'প্রোফাইল সংরক্ষিত হয়েছে',
                punjabi: 'ਪ੍ਰੋਫਾਈਲ ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਗਈ',
                odia: 'ପ୍ରୋଫାଇଲ୍ ସେଭ୍ ହେଲା',
                assamese: 'প্ৰʼফাইল সংৰক্ষণ কৰা হʼল',
                konkani: 'ಪ್ರೊಫೈಲ್ ಸಾಂಭಾಳ್ಳೆಂ',
                nepali: 'प्रोफाइल सुरक्षित भयो',
                meitei: 'প্রোফাইল সেভ তৌরে',
                mizo: 'Profile save a ni ta',
                kashmiri: 'پروفائل گۆو مَحفوٗظ',
                ladakhi: 'གསལ་བཤད་ཉར་ཚགས་བྱས།',
              ),
            ),
          ),
        );
      } else {
        Navigator.of(context).pop(updated);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ప్రొఫైల్ వివరాలు సేవ్ కాలేదు',
              english: 'Profile details could not be saved',
              hindi: 'प्रोफ़ाइल विवरण सहेजे नहीं जा सके',
              tamil: 'சுயவிவர விவரங்களைச் சேமிக்க முடியவில்லை',
              kannada: 'ಪ್ರೊಫೈಲ್ ವಿವರಗಳನ್ನು ಉಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ',
              malayalam: 'പ്രൊഫൈൽ വിവരങ്ങൾ സേവ് ചെയ്യാൻ കഴിഞ്ഞില്ല',
              marathi: 'प्रोफाइल तपशील सेव्ह करता आले नाहीत',
              gujarati: 'પ્રોફાઇલ વિગતો સાચવી શકાઈ નથી',
              bengali: 'প্রোফাইল বিবরণ সংরক্ষণ করা যায়নি',
              punjabi: 'ਪ੍ਰੋਫਾਈਲ ਵੇਰਵੇ ਸੁਰੱਖਿਅਤ ਨਹੀਂ ਕੀਤੇ ਜਾ ਸਕੇ',
              odia: 'ପ୍ରୋଫାଇଲ୍ ବିବରଣୀ ସେଭ୍ ହୋଇପାରିଲା ନାହିଁ',
              assamese: 'প্ৰʼফাইলৰ বিৱৰণ সংৰক্ষণ কৰিব পৰা নগʼল',
              konkani: 'ಪ್ರೊಫೈಲ್ ವಿವರಾಂ ಸಾಂಭಾಳುಂಕ್ ಜಾಲೆಂ ನಾ',
              nepali: 'प्रोफाइल विवरणहरू सुरक्षित गर्न सकिएन',
              meitei: 'প্রোফাইলগী ৱারোলশিং সেভ তৌবা ঙমদ্রে',
              mizo: 'Profile details save theih a ni lo',
              kashmiri: 'پروفائل تفصیلات ہیکؠ نہٕ مَحفوٗظ کٔرِتھ',
              ladakhi: 'གསལ་བཤད་གནས་ཚུལ་ཉར་ཚགས་བྱེད་མ་ཐུབ།',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool get _isOnboardingFlow =>
      widget.completeToHomeOnSave && !widget.embeddedInProfileScreen;

  PosterProfileData _currentProfileFromInputs() {
    final splitName = PosterProfileService.splitDisplayName(
      _nameController.text.trim(),
    );
    return _draftProfile.copyWith(
      identityMode: _draftProfile.identityMode,
      nameTelugu: splitName.$1,
      nameEnglish: splitName.$2,
      whatsappNumber: _whatsappController.text.trim(),
      businessName: _businessNameController.text.trim(),
      businessTagline: _businessTaglineController.text.trim(),
      businessWhatsappNumber: _onlyDigits(_businessWhatsappController.text),
    );
  }

  bool get _hasUnsavedChanges {
    return !_isSameProfileChange(_savedProfile, _currentProfileFromInputs());
  }

  bool _isSameProfileChange(PosterProfileData first, PosterProfileData second) {
    return _profileChangeSignature(first) == _profileChangeSignature(second);
  }

  bool _isSameProfileChangeIgnoringRemoteUrls(
    PosterProfileData first,
    PosterProfileData second,
  ) {
    return _profileChangeSignature(first, includeRemoteUrls: false) ==
        _profileChangeSignature(second, includeRemoteUrls: false);
  }

  String _profileChangeSignature(
    PosterProfileData profile, {
    bool includeRemoteUrls = true,
  }) {
    return <String>[
      profile.identityMode.name,
      profile.nameTelugu.trim(),
      profile.nameEnglish.trim(),
      profile.whatsappNumber.trim(),
      profile.nameFontFamily.trim(),
      profile.displayNameMode.name,
      profile.photoPath.trim(),
      if (includeRemoteUrls) profile.photoUrl.trim(),
      profile.originalPhotoPath.trim(),
      if (includeRemoteUrls) profile.originalPhotoUrl.trim(),
      profile.preferOriginalPersonalPhoto.toString(),
      profile.businessName.trim(),
      profile.businessTagline.trim(),
      _onlyDigits(profile.businessWhatsappNumber),
      profile.businessLogoPath.trim(),
      if (includeRemoteUrls) profile.businessLogoUrl.trim(),
      profile.businessLogoStyleId.trim(),
    ].join('\u001F');
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness =
        _draftProfile.identityMode == PosterIdentityMode.business;
    final strings = context.strings;
    final hasUnsavedChanges = _hasUnsavedChanges;
    final cs = Theme.of(context).colorScheme;
    final minimalSetup = _isOnboardingFlow;
    final canSubmitProfile = minimalSetup || hasUnsavedChanges;
    final showGuideAudio = context.currentLanguage == AppLanguage.telugu;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading:
            (!widget.embeddedInProfileScreen && Navigator.of(context).canPop())
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: minimalSetup ? cs.onSurface : const Color(0xFF0F172A),
                onPressed: () => Navigator.of(context).maybePop(_draftProfile),
              )
            : null,
        iconTheme: IconThemeData(
          color: minimalSetup ? cs.onSurface : const Color(0xFF0F172A),
        ),
        title: Text(
          strings.localized(
            telugu: 'పోస్టర్ ప్రొఫైల్',
            english: 'Poster Profile',
            hindi: 'पोस्टर प्रोफ़ाइल',
            tamil: 'போஸ்டர் சுயவிவரம்',
            kannada: 'ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್',
            malayalam: 'പോസ്റ്റർ പ്രൊഫൈൽ',
            marathi: 'पोस्टर प्रोफाइल',
            gujarati: 'પોસ્ટર પ્રોફાઇલ',
            bengali: 'পোস্টার প্রোফাইল',
            punjabi: 'ਪੋਸਟਰ ਪ੍ਰੋਫਾਈਲ',
            odia: 'ପୋଷ୍ଟର ପ୍ରୋଫାଇଲ୍',
            assamese: 'পোষ্টাৰ প্ৰʼফাইল',
            konkani: 'ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್',
            nepali: 'पोस्टर प्रोफाइल',
            meitei: 'পোস্তর প্রোফাইল',
            mizo: 'Poster Profile',
            kashmiri: 'پوسٹر پروفائل',
            ladakhi: 'པོསྚར་གསལ་བཤད།',
          ),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: minimalSetup ? cs.onSurface : const Color(0xFF0F172A),
          ),
        ),
        actions: widget.appBarActions,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.embeddedInProfileScreen) ...<Widget>[
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const MyDownloadsScreen(),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D28D9),
                    side: const BorderSide(color: Color(0xFFC4B5FD)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    strings.localized(
                      telugu: 'నా డౌన్‌లోడ్లు',
                      english: 'My Downloads',
                      hindi: 'मेरे डाउनलोड',
                      tamil: 'எனது பதிவிறக்கங்கள்',
                      kannada: 'ನನ್ನ ಡೌನ್‌ಲೋಡ್‌ಗಳು',
                      malayalam: 'എന്റെ ഡൗൺലോഡുകൾ',
                      marathi: 'माझे डाउनलोड्स',
                      gujarati: 'મારા ડાઉનલોડ્સ',
                      bengali: 'আমার ডাউনলোড',
                      punjabi: 'ਮੇਰੇ ਡਾਊਨਲੋਡ',
                      odia: 'ମୋ ଡାଉନଲୋଡ୍ସ',
                      assamese: 'মোৰ ডাউনলোডসমূহ',
                      konkani: 'ಮ್ಹಜೆ ಡೌನ್‌ಲೋಡ್ಸ್',
                      nepali: 'मेरो डाउनलोडहरू',
                      meitei: 'ঐগী দাউনলোদশিং',
                      mizo: 'Ka Download-te',
                      kashmiri: 'مےٚ ڈاون لوڈ کٔرِتھ',
                      ladakhi: 'ངའི་ཕབ་ལེན་རྣམས།',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                onPressed: _saving || !canSubmitProfile ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: canSubmitProfile
                      ? const Color(0xFF6D28D9)
                      : const Color(0xFFE2E8F0),
                  foregroundColor: canSubmitProfile
                      ? Colors.white
                      : const Color(0xFF64748B),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _saving
                      ? strings.localized(
                          telugu: 'సేవ్ అవుతోంది...',
                          english: 'Saving...',
                          hindi: 'सेव हो रहा है...',
                          tamil: 'சேமிக்கப்படுகிறது...',
                          kannada: 'ಸೇವ್ ಆಗುತ್ತಿದೆ...',
                          malayalam: 'സേവ് ചെയ്യുന്നു...',
                          marathi: 'सेव्ह होत आहे...',
                          gujarati: 'સાચવી રહ્યું છે...',
                          bengali: 'সংরক্ষণ করা হচ্ছে...',
                          punjabi: 'ਸੁਰੱਖਿਅਤ ਹੋ ਰਿਹਾ ਹੈ...',
                          odia: 'ସେଭ୍ ହେଉଛି...',
                          assamese: 'সংৰক্ষণ কৰা হৈছে...',
                          konkani: 'ಸಾಂಭಾಳ್ತಾ...',
                          nepali: 'बचत हुँदैछ...',
                          meitei: 'সেভ তৌরি...',
                          mizo: 'Save mek a ni...',
                          kashmiri: 'مَحفوٗظ گژھان چھُ...',
                          ladakhi: 'ཉར་ཚགས་བྱེད་བཞིན་པ...',
                        )
                      : strings.localized(
                          telugu: minimalSetup
                              ? 'కొనసాగండి'
                              : 'మార్పులు సేవ్ చేయండి',
                          english: minimalSetup ? 'Continue' : 'Save Changes',
                          hindi: minimalSetup ? 'जारी रखें' : 'बदलाव सेव करें',
                          tamil: minimalSetup
                              ? 'தொடரவும்'
                              : 'மாற்றங்களை சேமிக்கவும்',
                          kannada: minimalSetup
                              ? 'ಮುಂದುವರಿಸಿ'
                              : 'ಬದಲಾವಣೆಗಳನ್ನು ಸೇವ್ ಮಾಡಿ',
                          malayalam: minimalSetup
                              ? 'തുടരുക'
                              : 'മാറ്റങ്ങൾ സേവ് ചെയ്യുക',
                          marathi: minimalSetup
                              ? 'पुढे चालू ठेवा'
                              : 'बदल सेव्ह करा',
                          gujarati: minimalSetup
                              ? 'ચાલુ રાખો'
                              : 'ફેરફારો સાચવો',
                          bengali: minimalSetup
                              ? 'চালিয়ে যান'
                              : 'পরিবর্তন সংরক্ষণ করুন',
                          punjabi: minimalSetup
                              ? 'ਜਾਰੀ ਰੱਖੋ'
                              : 'ਤਬਦੀਲੀਆਂ ਸੁਰੱਖਿਅਤ ਕਰੋ',
                          odia: minimalSetup
                              ? 'ଜାରି ରଖନ୍ତୁ'
                              : 'ପରିବର୍ତ୍ତନଗୁଡ଼ିକ ସେଭ୍ କରନ୍ତୁ',
                          assamese: minimalSetup
                              ? 'অব্যাহত ৰাখক'
                              : 'পৰিৱৰ্তনসমূহ সংৰক্ষণ কৰক',
                          konkani: minimalSetup
                              ? 'ಮುಕಾರುನ್ ವ್ಹರಾ'
                              : 'ಬದ್ಲಾವಣಾಂ ಸಾಂಭಾಳಾ',
                          nepali: minimalSetup
                              ? 'जारी राख्नुहोस्'
                              : 'परिवर्तनहरू सुरक्षित गर्नुहोस्',
                          meitei: minimalSetup
                              ? 'মখা চত্থবীয়ু'
                              : 'অহোংবশিং সেভ তৌরো',
                          mizo: minimalSetup
                              ? 'Chhunzawm rawh'
                              : 'Danglamnate vawng tha rawh',
                          kashmiri: minimalSetup
                              ? 'جٲری تھٲویو'
                              : 'تبدیٖلی کٔریو مَحفوٗظ',
                          ladakhi: minimalSetup
                              ? 'མུ་མཐུད་དོ།'
                              : 'བཟོ་བཅོས་རྣམས་ཉར་ཚགས་གྱིས།',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: GradientShell(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: <Widget>[
            OnboardingSurfaceCard(
              maxWidth: 460,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SegmentedButton<PosterIdentityMode>(
                    showSelectedIcon: false,
                    segments: <ButtonSegment<PosterIdentityMode>>[
                      ButtonSegment<PosterIdentityMode>(
                        value: PosterIdentityMode.personal,
                        label: Text(
                          strings.localized(
                            telugu: 'వ్యక్తిగతం',
                            english: 'Personal',
                            hindi: 'व्यक्तिगत',
                            tamil: 'தனிப்பட்ட',
                            kannada: 'ವೈಯಕ್ತಿಕ',
                            malayalam: 'വ്യക്തിഗതം',
                            marathi: 'वैयक्तिक',
                            gujarati: 'વ્યક્તિગત',
                            bengali: 'ব্যক্তিগত',
                            punjabi: 'ਨਿੱਜੀ',
                            odia: 'ବ୍ୟକ୍ତିଗତ',
                            assamese: 'ব্যক্তিগত',
                            konkani: 'ಖಾಸ್ಗಿ',
                            nepali: 'व्यक्तिगत',
                            meitei: 'ব্যক্তিগত',
                            mizo: 'Mimal',
                            kashmiri: 'ذٲتی',
                            ladakhi: 'སྒེར་གྱི།',
                          ),
                        ),
                      ),
                      ButtonSegment<PosterIdentityMode>(
                        value: PosterIdentityMode.business,
                        label: Text(
                          strings.localized(
                            telugu: 'వ్యాపారం',
                            english: 'Business',
                            hindi: 'व्यापार',
                            tamil: 'வணிகம்',
                            kannada: 'ವ್ಯವಹಾರ',
                            malayalam: 'ബിസിനസ്സ്',
                            marathi: 'व्यवसाय',
                            gujarati: 'વ્યવસાય',
                            bengali: 'ব্যবসা',
                            punjabi: 'ਕਾਰੋਬਾਰ',
                            odia: 'ବ୍ୟବସାୟ',
                            assamese: 'ব্যৱসায়',
                            konkani: 'ವ್ಯವಹಾರ್',
                            nepali: 'व्यापार',
                            meitei: 'লল্লোন-ইতিক',
                            mizo: 'Sumdawnna',
                            kashmiri: 'کٲروبار',
                            ladakhi: 'ཚོང་ལས།',
                          ),
                        ),
                      ),
                    ],
                    selected: <PosterIdentityMode>{_draftProfile.identityMode},
                    onSelectionChanged: (values) {
                      setState(() {
                        _draftProfile = _draftProfile.copyWith(
                          identityMode: values.first,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _IdentityPreviewCard(
                    title: isBusiness
                        ? strings.localized(
                            telugu: 'వ్యాపార ప్రివ్యూ',
                            english: 'Business preview',
                            hindi: 'व्यापार पूर्वावलोकन',
                            tamil: 'வணிக முன்னோட்டம்',
                            kannada: 'ವ್ಯವಹಾರ ಮುನ್ನೋಟ',
                            malayalam: 'ബിസിനസ്സ് പ്രിവ്യൂ',
                            marathi: 'व्यवसाय पूर्वावलोकन',
                            gujarati: 'વ્યવસાય પૂર્વાવલોકન',
                            bengali: 'ব্যবসায়িক পূর্বরূপ',
                            punjabi: 'ਕਾਰੋਬਾਰੀ ਝਲਕ',
                            odia: 'ବ୍ୟବସାୟ ପୂର୍ବାବଲୋକନ',
                            assamese: 'ব্যৱসায়িক পূৰ্বদৰ্শন',
                            konkani: 'ವ್ಯವಹಾರಾಚೆಂ ಪ್ರಿವ್ಯೂ',
                            nepali: 'व्यापार पूर्वावलोकन',
                            meitei: 'লল্লোন-ইতিক্কী প্রিভ্যু',
                            mizo: 'Sumdawnna thlalak lang tur',
                            kashmiri: 'کٲروبٲری پرٛیویو',
                            ladakhi: 'ཚོང་ལས་སྔོན་ལྟ།',
                          )
                        : strings.localized(
                            telugu: 'ప్రొఫైల్ ప్రివ్యూ',
                            english: 'Profile preview',
                            hindi: 'प्रोफ़ाइल पूर्वावलोकन',
                            tamil: 'சுயவிவர முன்னோட்டம்',
                            kannada: 'ಪ್ರೊಫೈಲ್ ಮುನ್ನೋಟ',
                            malayalam: 'പ്രൊഫൈൽ പ്രിവ്യൂ',
                            marathi: 'प्रोफाइल पूर्वावलोकन',
                            gujarati: 'પ્રોફાઇલ પૂર્વાવલોકન',
                            bengali: 'প্রোফাইল পূর্বরূপ',
                            punjabi: 'ਪ੍ਰੋਫਾਈਲ ਝਲਕ',
                            odia: 'ପ୍ରୋଫାଇଲ୍ ପୂର୍ବାବଲୋକନ',
                            assamese: 'প্ৰʼফাইল পূৰ্বদৰ্শন',
                            konkani: 'ಪ್ರೊಫೈಲ್ ಪ್ರಿವ್ಯೂ',
                            nepali: 'प्रोफाइल पूर्वावलोकन',
                            meitei: 'প্রোফাইল প্রিভ্যু',
                            mizo: 'Profile thlalak lang tur',
                            kashmiri: 'پروفائل پرٛیویو',
                            ladakhi: 'གསལ་བཤད་སྔོན་ལྟ།',
                          ),
                    subtitle: isBusiness
                        ? strings.localized(
                            telugu: 'లోగో మార్చండి',
                            english: 'Change logo',
                            hindi: 'लोगो बदलें',
                            tamil: 'லோகோவை மாற்றவும்',
                            kannada: 'ಲೋಗೋ ಬದಲಾಯಿಸಿ',
                            malayalam: 'ലോഗോ മാറ്റുക',
                            marathi: 'लोगो बदला',
                            gujarati: 'લોગો બદલો',
                            bengali: 'লোগো পরিবর্তন করুন',
                            punjabi: 'ਲੋਗੋ ਬਦਲੋ',
                            odia: 'ଲୋଗୋ ବଦଳାନ୍ତୁ',
                            assamese: 'লʼগʼ সলনি কৰক',
                            konkani: 'ಲೋಗೋ ಬದ್ಲಾ',
                            nepali: 'लोगो बदल्नुहोस्',
                            meitei: 'লোগো হোংদোকউ',
                            mizo: 'Logo thlak rawh',
                            kashmiri: 'لوگو بَدلاوِیو',
                            ladakhi: 'ཚོང་རྟགས་བརྗེ་བཅོས་གྱིས།',
                          )
                        : strings.localized(
                            telugu: 'ఫోటో మార్చండి',
                            english: 'Change photo',
                            hindi: 'फ़ोटो बदलें',
                            tamil: 'புகைப்படத்தை மாற்றவும்',
                            kannada: 'ಫೋಟೋ ಬದಲಾಯಿಸಿ',
                            malayalam: 'ഫോട്ടോ മാറ്റുക',
                            marathi: 'फोटो बदला',
                            gujarati: 'ફોટો બદલો',
                            bengali: 'ছবি পরিবর্তন করুন',
                            punjabi: 'ਫੋਟੋ ਬਦਲੋ',
                            odia: 'ଫଟୋ ବଦଳାନ୍ତୁ',
                            assamese: 'ফটো সলনি কৰক',
                            konkani: 'ಫೋಟೋ ಬದ್ಲಾ',
                            nepali: 'फोटो बदल्नुहोस्',
                            meitei: 'ফোতো হোংদোকউ',
                            mizo: 'Thlalak thlak rawh',
                            kashmiri: 'فوٹو بَدلاوِیو',
                            ladakhi: 'འདྲ་པར་བརྗེ་བཅོས་གྱིས།',
                          ),
                    busy: isBusiness ? _businessLogoBusy : _personalPhotoBusy,
                    onVisualTap: isBusiness
                        ? _pickBusinessLogo
                        : _openPersonalPhotoPicker,
                    child: SizedBox(
                      width: 148,
                      height: 148,
                      child: ClipOval(
                        child: PosterIdentityVisual(
                          key: ValueKey<String>(
                            [
                              _draftProfile.identityMode.name,
                              _draftProfile.photoPath,
                              _draftProfile.photoUrl,
                              _draftProfile.originalPhotoPath,
                              _draftProfile.originalPhotoUrl,
                              _draftProfile.businessLogoPath,
                              _draftProfile.businessLogoUrl,
                              _draftProfile.businessLogoStyleId,
                              _draftProfile.businessName,
                              _draftProfile.businessTagline,
                            ].join('|'),
                          ),
                          profile: _draftProfile,
                          fit: isBusiness ? BoxFit.contain : BoxFit.cover,
                          preferOriginalPersonalPhoto:
                              (_draftProfile.originalPhotoPath
                                      .trim()
                                      .isNotEmpty ||
                                  _draftProfile.originalPhotoUrl
                                      .trim()
                                      .isNotEmpty)
                              ? _draftProfile.preferOriginalPersonalPhoto
                              : false,
                          allowOriginalFallbackWhenCutoutUnavailable: true,
                          textScale: 1.18,
                        ),
                      ),
                    ),
                  ),
                  if (!isBusiness &&
                      (_draftProfile.photoPath.trim().isNotEmpty ||
                          _draftProfile.originalPhotoPath.trim().isNotEmpty ||
                          _draftProfile.photoUrl.trim().isNotEmpty ||
                          _draftProfile.originalPhotoUrl
                              .trim()
                              .isNotEmpty)) ...<Widget>[
                    const SizedBox(height: 14),
                    _ProfilePhotoStyleSegmentedSwitch(
                      isOriginal: _draftProfile.preferOriginalPersonalPhoto,
                      hasOriginal:
                          _draftProfile.originalPhotoPath.trim().isNotEmpty ||
                          _draftProfile.originalPhotoUrl.trim().isNotEmpty,
                      onStyleChanged: (preferOriginal) async {
                        final newRevision =
                            DateTime.now().millisecondsSinceEpoch;
                        final updated = _draftProfile.copyWith(
                          preferOriginalPersonalPhoto: preferOriginal,
                          personalPhotoRevision: newRevision,
                        );
                        setState(() => _draftProfile = updated);
                        widget.onSaved?.call(updated);
                        await PosterProfileService.savePersonalPhotoAssets(
                          photoPath: updated.photoPath,
                          originalPhotoPath: updated.originalPhotoPath,
                          photoUrl: updated.photoUrl,
                          originalPhotoUrl: updated.originalPhotoUrl,
                          preferOriginalPersonalPhoto: preferOriginal,
                          saveRemoteUrls: true,
                          personalPhotoRevision: newRevision,
                        );
                      },
                      onOriginalUnavailable: () {
                        ScaffoldMessenger.of(context).showTopSnackBar(
                          AppSnackBar.build(
                            content: Text(
                              strings.localized(
                                telugu:
                                    'ఈ ఫోటోకు ఒరిజినల్ వెర్షన్ అందుబాటులో లేదు.',
                                english:
                                    'Original version is not available for this photo.',
                                hindi:
                                    'इस फ़ोटो के लिए मूल संस्करण उपलब्ध नहीं है।',
                                tamil:
                                    'இந்த புகைப்படத்திற்கு அசல் பதிப்பு கிடைக்கவில்லை.',
                                kannada: 'ಈ ಫೋಟೋಗೆ ಮೂಲ ಆವೃತ್ತಿ ಲಭ್ಯವಿಲ್ಲ.',
                                malayalam:
                                    'ഈ ഫോട്ടോയ്ക്ക് യഥാർത്ഥ പതിപ്പ് ലഭ്യമല്ല.',
                                marathi: 'या फोटोसाठी मूळ आवृत्ती उपलब्ध नाही.',
                                gujarati:
                                    'આ ફોટો માટે ઓરિજિનલ વર્ઝન ઉપલબ્ધ નથી.',
                                bengali: 'এই ছবির জন্য আসল সংস্করণ উপলব্ধ নেই।',
                                punjabi: 'ਇਸ ਫੋਟੋ ਲਈ ਅਸਲ ਸੰਸਕਰਣ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
                                odia: 'ଏହି ଫଟୋ ପାଇଁ ମୂଳ ସଂସ୍କରଣ ଉପଲବ୍ଧ ନାହିଁ।',
                                assamese:
                                    'এই ফটোখনৰ বাবে আচল সংস্কৰণ উপলব্ধ নহয়।',
                                konkani: 'ಹ್ಯಾ ಫೋಟೋಕ್ ಮೂಳ್ ಆವೃತ್ತಿ ಲಭ್ಯ್ ನಾ.',
                                nepali:
                                    'यो तस्बिरको लागि मौलिक संस्करण उपलब्ध छैन।',
                                meitei: 'মসিগী ফোতো অসিগী অশেংবা মওং ফংদে।',
                                mizo:
                                    'He photo tan hian a nihna tak hman theih a ni lo.',
                                kashmiri:
                                    'اَتھ فوٹوئَس باپتھ چھُنہٕ اصلی ورجَن دٔستیاب۔',
                                ladakhi: 'འདྲ་པར་འདི་ལ་ངོ་མ་རྣམ་པ་མི་འདུག',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (widget.accountEmail.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      widget.accountEmail.trim(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (widget.accountSubtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        widget.accountSubtitle.trim(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 22),
                  if (showGuideAudio) ...<Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () {
                          unawaited(
                            _onboardingAudio.toggleIfSupported(
                              language: context.currentLanguage,
                              cue: OnboardingAudioCue.profileSetup,
                            ),
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                        label: Text(
                          strings.localized(
                            telugu: 'వాయిస్ గైడ్ మళ్లీ వినండి',
                            english: 'Replay voice guide',
                            hindi: 'वॉयस गाइड फिर से सुनें',
                            tamil: 'குரல் வழிகாட்டியை மீண்டும் கேட்கவும்',
                            kannada: 'ಧ್ವನಿ ಮಾರ್ಗದರ್ಶನವನ್ನು ಮತ್ತೆ ಆಲಿಸಿ',
                            malayalam: 'വോയ്‌സ് ഗൈഡ് വീണ്ടും കേൾക്കുക',
                            marathi: 'व्हॉईस गाईड पुन्हा ऐका',
                            gujarati: 'વૉઇસ માર્ગદર્શિકા ફરી સાંભળો',
                            bengali: 'ভয়েস গাইড আবার শুনুন',
                            punjabi: 'ਵੌਇਸ ਗਾਈਡ ਦੁਬਾਰਾ ਸੁਣੋ',
                            odia: 'ଭଏସ୍ ଗାଇଡ୍ ପୁନର୍ବାର ଶୁଣନ୍ତୁ',
                            assamese: 'ভইচ গাইড পুনৰ শুনক',
                            konkani: 'ವಾಯ್ಸ್ ಗೈಡ್ ಪರತ್ ಆಯ್ಕಾ',
                            nepali: 'आवाज मार्गदर्शन फेरि सुन्नुहोस्',
                            meitei: 'খোন্থাগী লমজিং অমুক হন্না তারো',
                            mizo: 'Awka hruaina ngaithla nawn rawh',
                            kashmiri: 'آوازٕ ہُنٛد رہنما دۆبارٕ بوٗزِو',
                            ladakhi: 'སྐད་ཀྱི་ལམ་སྟོན་ཡང་བསྐྱར་ཉོན།',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            if (!isBusiness) ...<Widget>[
              const SizedBox(height: 16),
              OnboardingSurfaceCard(
                maxWidth: 460,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SectionTitle(
                      strings.localized(
                        telugu: 'వ్యక్తిగత వివరాలు',
                        english: 'Personal Details',
                        hindi: 'व्यक्तिगत विवरण',
                        tamil: 'தனிப்பட்ட விவரங்கள்',
                        kannada: 'ವೈಯಕ್ತಿಕ ವಿವರಗಳು',
                        malayalam: 'വ്യക്തിഗത വിവരങ്ങൾ',
                        marathi: 'वैयक्तिक तपशील',
                        gujarati: 'વ્યક્તિગત વિગતો',
                        bengali: 'ব্যক্তিগত বিবরণ',
                        punjabi: 'ਨਿੱਜੀ ਵੇਰਵੇ',
                        odia: 'ବ୍ୟକ୍ତିଗତ ବିବରଣୀ',
                        assamese: 'ব্যক্তিগত বিৱৰণ',
                        konkani: 'ಖಾಸ್ಗಿ ವಿವರಾಂ',
                        nepali: 'व्यक्तिगत विवरण',
                        meitei: 'ব্যক্তিগত ৱারোলশিং',
                        mizo: 'Mimal chanchin',
                        kashmiri: 'ذٲتی تفصیلات',
                        ladakhi: 'སྒེར་གྱི་གནས་ཚུལ།',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CleanInputField(
                      controller: _nameController,
                      label: strings.localized(
                        telugu: 'పేరు',
                        english: 'Display Name',
                        hindi: 'प्रदर्शित नाम',
                        tamil: 'காட்சிப் பெயர்',
                        kannada: 'ಪ್ರದರ್ಶನ ಹೆಸರು',
                        malayalam: 'പ്രദർശിപ്പിക്കുന്ന പേര്',
                        marathi: 'प्रदर्शित नाव',
                        gujarati: 'પ્રદર્શિત નામ',
                        bengali: 'প্রদর্শনের নাম',
                        punjabi: 'ਦਿਖਾਉਣ ਵਾਲਾ ਨਾਮ',
                        odia: 'ପ୍ରଦର୍ଶିତ ନାମ',
                        assamese: 'প্ৰদৰ্শিত নাম',
                        konkani: 'ದಾಕಂವ್ಚೆಂ ನಾಂವ್',
                        nepali: 'प्रदर्शन नाम',
                        meitei: 'উৎলিবা মিং',
                        mizo: 'Lan chhuah tur hming',
                        kashmiri: 'ظٲہِر گژھن وول ناو',
                        ladakhi: 'སྟོན་པའི་མིང་།',
                      ),
                      hintText: strings.localized(
                        telugu: 'మీ పేరు నమోదు చేయండి',
                        english: 'Enter your name',
                        hindi: 'अपना नाम दर्ज करें',
                        tamil: 'உங்கள் பெயரை உள்ளிடவும்',
                        kannada: 'ನಿಮ್ಮ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
                        malayalam: 'നിങ്ങളുടെ പേര് നൽകുക',
                        marathi: 'तुमचे नाव प्रविष्ट करा',
                        gujarati: 'તમારું નામ દાખલ કરો',
                        bengali: 'আপনার নাম লিখুন',
                        punjabi: 'ਆਪਣਾ ਨਾਮ ਦਰਜ ਕਰੋ',
                        odia: 'ଆପଣଙ୍କ ନାମ ଲେଖନ୍ତୁ',
                        assamese: 'আপোনাৰ নাম দিয়ক',
                        konkani: 'ತುಮ್ಚೆಂ ನಾಂವ್ ಬರಯಾ',
                        nepali: 'आफ्नो नाम प्रविष्ट गर्नुहोस्',
                        meitei: 'নহাক্কী মিং ইয়ু',
                        mizo: 'I hming ziak rawh',
                        kashmiri: 'پنُن ناو دَرٕج کٔریو',
                        ladakhi: 'ཁྱེད་ཀྱི་མིང་བྲིས།',
                      ),
                      onChanged: (value) {
                        setState(() {
                          final split = PosterProfileService.splitDisplayName(
                            value.trim(),
                          );
                          _draftProfile = _draftProfile.copyWith(
                            nameTelugu: split.$1,
                            nameEnglish: split.$2,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _CleanInputField(
                      controller: _whatsappController,
                      label: strings.localized(
                        telugu: 'హోదా',
                        english: 'Designation',
                        hindi: 'पद',
                        tamil: 'பதவி',
                        kannada: 'ಹುದ್ದೆ',
                        malayalam: 'സ്ഥാനപ്പേര്',
                        marathi: 'पद',
                        gujarati: 'હોદ્દો',
                        bengali: 'পদবি',
                        punjabi: 'ਅਹੁਦਾ',
                        odia: 'ପଦବୀ',
                        assamese: 'পদবী',
                        konkani: 'ಹುದ್ದೊ',
                        nepali: 'पद',
                        meitei: 'ফম',
                        mizo: 'Nihna',
                        kashmiri: 'عُہدٕ',
                        ladakhi: 'གོ་གནས།',
                      ),
                      hintText: strings.localized(
                        telugu: 'మీ హోదా నమోదు చేయండి',
                        english: 'Enter your designation',
                        hindi: 'अपना पद दर्ज करें',
                        tamil: 'உங்கள் பதவியை உள்ளிடவும்',
                        kannada: 'ನಿಮ್ಮ ಹುದ್ದೆಯನ್ನು ನಮೂದಿಸಿ',
                        malayalam: 'നിങ്ങളുടെ പദവി നൽകുക',
                        marathi: 'तुमचे पद प्रविष्ट करा',
                        gujarati: 'તમારો હોદ્દો દાખલ કરો',
                        bengali: 'আপনার পদবি লিখুন',
                        punjabi: 'ਆਪਣਾ ਅਹੁਦਾ ਦਰਜ ਕਰੋ',
                        odia: 'ଆପଣଙ୍କ ପଦବୀ ଲେଖନ୍ତୁ',
                        assamese: 'আপোনাৰ পদবী দিয়ক',
                        konkani: 'ತುಮ್ಚೊ ಹುದ್ದೊ ಬರಯಾ',
                        nepali: 'आफ्नो पद प्रविष्ट गर्नुहोस्',
                        meitei: 'নহাক্কী ফম ইয়ু',
                        mizo: 'I nihna ziak rawh',
                        kashmiri: 'پنُن عُہدٕ دَرٕج کٔریو',
                        ladakhi: 'ཁྱེད་ཀྱི་གོ་གནས་བྲིས།',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _draftProfile = _draftProfile.copyWith(
                            whatsappNumber: value.trim(),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
              OnboardingSurfaceCard(
                maxWidth: 460,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SectionTitle(
                      strings.localized(
                        telugu: 'వ్యాపార వివరాలు',
                        english: 'Business Details',
                        hindi: 'व्यावसायिक विवरण',
                        tamil: 'வணிக விவரங்கள்',
                        kannada: 'ವ್ಯವಹಾರದ ವಿವರಗಳು',
                        malayalam: 'ബിസിനസ്സ് വിവരങ്ങൾ',
                        marathi: 'व्यवसाय तपशील',
                        gujarati: 'વ્યવસાયની વિગતો',
                        bengali: 'ব্যবসায়িক বিবরণ',
                        punjabi: 'ਕਾਰੋਬਾਰੀ ਵੇਰਵੇ',
                        odia: 'ବ୍ୟବସାୟ ବିବରଣୀ',
                        assamese: 'ব্যৱসায়িক বিৱৰণ',
                        konkani: 'ವ್ಯವಹಾರಾಚೆ ವಿವರಾಂ',
                        nepali: 'व्यापार विवरण',
                        meitei: 'লল্লোন-ইতিক্কী ৱারোলশিং',
                        mizo: 'Sumdawnna chanchin',
                        kashmiri: 'کٲروبٲری تفصیلات',
                        ladakhi: 'ཚོང་ལས་ཀྱི་གནས་ཚུལ།',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CleanInputField(
                      controller: _businessNameController,
                      label: strings.localized(
                        telugu: 'వ్యాపార పేరు',
                        english: 'Business Name',
                        hindi: 'व्यापार का नाम',
                        tamil: 'வணிகப் பெயர்',
                        kannada: 'ವ್ಯವಹಾರದ ಹೆಸರು',
                        malayalam: 'ബിസിനസ്സ് പേര്',
                        marathi: 'व्यवसायाचे नाव',
                        gujarati: 'વ્યવસાયનું નામ',
                        bengali: 'ব্যবসার নাম',
                        punjabi: 'ਕਾਰੋਬਾਰ ਦਾ ਨਾਮ',
                        odia: 'ବ୍ୟବସାୟ ନାମ',
                        assamese: 'ব্যৱসায়ৰ নাম',
                        konkani: 'ವ್ಯವಹಾರಾಚೆಂ ನಾಂವ್',
                        nepali: 'व्यापारको नाम',
                        meitei: 'লল্লোন-ইতিক্কী মিং',
                        mizo: 'Sumdawnna hming',
                        kashmiri: 'کٲروبارُک ناو',
                        ladakhi: 'ཚོང་ལས་ཀྱི་མིང་།',
                      ),
                      hintText: strings.localized(
                        telugu: 'వ్యాపార పేరు నమోదు చేయండి',
                        english: 'Enter business name',
                        hindi: 'व्यापार का नाम दर्ज करें',
                        tamil: 'வணிகப் பெயரை உள்ளிடவும்',
                        kannada: 'ವ್ಯವಹಾರದ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
                        malayalam: 'ബിസിനസ്സ് പേര് നൽകുക',
                        marathi: 'व्यवसायाचे नाव प्रविष्ट करा',
                        gujarati: 'વ્યવસાયનું નામ દાખલ કરો',
                        bengali: 'ব্যবসার নাম লিখুন',
                        punjabi: 'ਕਾਰੋਬਾਰ ਦਾ ਨਾਮ ਦਰਜ ਕਰੋ',
                        odia: 'ବ୍ୟବସାୟ ନାମ ଲେଖନ୍ତୁ',
                        assamese: 'ব্যৱসায়ৰ নাম দিয়ক',
                        konkani: 'ವ್ಯವಹಾರಾಚೆಂ ನಾಂವ್ ಬರಯಾ',
                        nepali: 'व्यापारको नाम प्रविष्ट गर्नुहोस्',
                        meitei: 'লল্লোন-ইতিক্কী মিং ইয়ু',
                        mizo: 'Sumdawnna hming ziak rawh',
                        kashmiri: 'کٲروبارُک ناو دَرٕج کٔریو',
                        ladakhi: 'ཚོང་ལས་ཀྱི་མིང་བྲིས།',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _draftProfile = _draftProfile.copyWith(
                            businessName: value.trim(),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _CleanInputField(
                      controller: _businessTaglineController,
                      label: strings.localized(
                        telugu: 'వ్యాపార ట్యాగ్‌లైన్',
                        english: 'Business Tagline',
                        hindi: 'व्यापार टैगलाइन',
                        tamil: 'வணிக வாசகம்',
                        kannada: 'ವ್ಯವಹಾರದ ಟ್ಯಾಗ್‌ಲೈನ್',
                        malayalam: 'ബിസിനസ്സ് ടാഗ്‌లైൻ',
                        marathi: 'व्यवसाय टॅगलाइन',
                        gujarati: 'વ્યવસાય ટેગલાઇન',
                        bengali: 'ব্যবসার ট্যাগলাইন',
                        punjabi: 'ਕਾਰੋਬਾਰੀ ਟੈਗਲਾਈਨ',
                        odia: 'ବ୍ୟବସାୟ ଟ୍ୟାଗ୍‌ଲାଇନ୍',
                        assamese: 'ব্যৱসায়িক টেগলাইন',
                        konkani: 'ವ್ಯವಹಾರಾಚೆಂ ಟ್ಯಾಗ್‌ಲೈನ್',
                        nepali: 'व्यापार ट्यागलाइन',
                        meitei: 'লল্লোন-ইতিক্কী তেগলাইন',
                        mizo: 'Sumdawnna thupui',
                        kashmiri: 'کٲروبٲری ٹیگ لائن',
                        ladakhi: 'ཚོང་ལས་ཀྱི་ཚིག་རྟགས།',
                      ),
                      hintText: strings.localized(
                        telugu: 'ఐచ్ఛిక చిన్న వాక్యం',
                        english: 'Optional short line',
                        hindi: 'वैकल्पिक संक्षिप्त पंक्ति',
                        tamil: 'விருப்பத்திற்குரிய சிறு வரி',
                        kannada: 'ಐಚ್ಛಿಕ ಸಣ್ಣ ಸಾಲು',
                        malayalam: 'ഓപ്ഷണൽ ചെറിയ വരി',
                        marathi: 'पर्यायी लहान ओळ',
                        gujarati: 'વૈકલ્પિક ટૂંકી લાઇન',
                        bengali: 'ঐচ্ছিক সংক্ষিপ্ত বাক্য',
                        punjabi: 'ਵਿਕਲਪਿਕ ਛੋਟੀ ਲਾਈਨ',
                        odia: 'ଇଚ୍ଛାଧୀନ ଛୋଟ ଧାଡ଼ି',
                        assamese: 'ঐচ্ছিক চমু শাৰী',
                        konkani: 'ಖುಶೆಚಿ ಲ್ಹಾನ್ ಸಾಲ್',
                        nepali: 'वैकल्पिक छोटो रेखा',
                        meitei: 'অপশনাল ওইবা অপীকপা লাইন',
                        mizo: 'Duhthlan theih thu tawi',
                        kashmiri: 'اِختیاری لۄکُٹ جملہٕ',
                        ladakhi: 'འདེམས་ཁའི་ཚིག་ཐུང་།',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _draftProfile = _draftProfile.copyWith(
                            businessTagline: value.trim(),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _CleanInputField(
                      controller: _businessWhatsappController,
                      label: strings.localized(
                        telugu: 'వ్యాపార వాట్సాప్ నంబర్',
                        english: 'Business WhatsApp Number',
                        hindi: 'व्यापार व्हाट्सएप नंबर',
                        tamil: 'வணிக வாட்ஸ்அப் எண்',
                        kannada: 'ವ್ಯವಹಾರದ ವಾಟ್ಸಾಪ್ ಸಂಖ್ಯೆ',
                        malayalam: 'ബിസിനസ്സ് വാട്ട്‌സ്ആപ്പ് നമ്പർ',
                        marathi: 'व्यवसाय व्हॉट्सअ‍ॅप क्रमांक',
                        gujarati: 'વ્યવસાય વ્હોટ્સએપ નંબર',
                        bengali: 'ব্যবসায়িক হোয়াটসঅ্যাপ নম্বর',
                        punjabi: 'ਕਾਰੋਬਾਰੀ ਵਟਸਐਪ ਨੰਬਰ',
                        odia: 'ବ୍ୟବସାୟ ହ୍ୱାଟ୍ସଆପ୍ ନମ୍ବର',
                        assamese: 'ব্যৱসায়িক হোৱাটছএপ নম্বৰ',
                        konkani: 'ವ್ಯವಹಾರಾಚೆಂ ವಾಟ್ಸಾಪ್ ನಂಬರ್',
                        nepali: 'व्यापार व्हाट्सएप नम्बर',
                        meitei: 'লল্লোন-ইতিক্কী ৱাত্সএপ নম্বর',
                        mizo: 'Sumdawnna WhatsApp Number',
                        kashmiri: 'کٲروبٲری واٹس ایپ نَمبَر',
                        ladakhi: 'ཚོང་ལས་ཝཊས་ཨེཔ་ཨང་གྲངས།',
                      ),
                      hintText: strings.localized(
                        telugu: '10 అంకెల నంబర్',
                        english: '10-digit number',
                        hindi: '10-अंकों का नंबर',
                        tamil: '10 இலக்க எண்',
                        kannada: '10-ಅಂಕಿಯ ಸಂಖ್ಯೆ',
                        malayalam: '10 അക്ക നമ്പർ',
                        marathi: '१०-अंकी क्रमांक',
                        gujarati: '10-અંકનો નંબર',
                        bengali: '১০-সংখ্যার নম্বর',
                        punjabi: '10-ਅੰਕਾਂ ਦਾ ਨੰਬਰ',
                        odia: '୧୦ ଅଙ୍କ ବିଶିଷ୍ଟ ନମ୍ବର',
                        assamese: '১০টা সংখ্যাৰ নম্বৰ',
                        konkani: '10-ಅಂಕ್ಯಾಂಚೊ ನಂಬರ್',
                        nepali: '१०-अङ्कको नम्बर',
                        meitei: 'দিজিৎ ১০ গী নম্বর',
                        mizo: 'Digit 10 number',
                        kashmiri: '۱۰ ہِندسَن ہُنٛد نَمبَر',
                        ladakhi: 'ཨང་གྲངས་ ༡༠ ཅན།',
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        setState(() {
                          _draftProfile = _draftProfile.copyWith(
                            businessWhatsappNumber: _onlyDigits(value),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      strings.localized(
                        telugu: 'లోగో స్టైల్',
                        english: 'Logo Style',
                        hindi: 'लोगो शैली',
                        tamil: 'லோகோ பாணி',
                        kannada: 'ಲೋಗೋ ಶೈಲಿ',
                        malayalam: 'ലോഗോ ശൈലി',
                        marathi: 'लोगो शैली',
                        gujarati: 'લોગો શૈલી',
                        bengali: 'লোগোর ধরন',
                        punjabi: 'ਲੋਗੋ ਸ਼ੈਲੀ',
                        odia: 'ଲୋଗୋ ଶୈଳୀ',
                        assamese: 'লʼগʼ শৈলী',
                        konkani: 'ಲೋಗೋ ಶೈಲಿ',
                        nepali: 'लोगो शैली',
                        meitei: 'লোগো স্তাইল',
                        mizo: 'Logo Style',
                        kashmiri: 'لوگو انداز',
                        ladakhi: 'ཚོང་རྟགས་བཟོ་ལྟ།',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 132,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _businessLogoStyles.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final styleId = _businessLogoStyles[index];
                          final previewProfile = _draftProfile.copyWith(
                            businessLogoStyleId: styleId,
                            businessLogoPath: '',
                            businessLogoUrl: '',
                            businessName:
                                _businessNameController.text.trim().isEmpty
                                ? strings.localized(
                                    telugu: 'మన బిజినెస్',
                                    english: 'Mana Business',
                                    hindi: 'माना बिज़नेस',
                                    tamil: 'மானா வணிகம்',
                                    kannada: 'ಮಾನಾ ಬಿಸಿನೆಸ್',
                                    malayalam: 'മന ബിസിനസ്സ്',
                                    marathi: 'माना बिझनेस',
                                    gujarati: 'માના બિઝનેસ',
                                    bengali: 'মানা বিজনেস',
                                    punjabi: 'ਮਾਨਾ ਬਿਜ਼ਨਸ',
                                    odia: 'ମାନା ବିଜନେସ୍',
                                    assamese: 'মানা বিজনেছ',
                                    konkani: 'ಮಾನಾ ಬಿಸಿನೆಸ್',
                                    nepali: 'माना बिजनेस',
                                    meitei: 'মানা বিজিনেস',
                                    mizo: 'Mana Business',
                                    kashmiri: 'مانا بٕزنَس',
                                    ladakhi: 'མ་ན་ཚོང་ལས།',
                                  )
                                : _businessNameController.text.trim(),
                            businessTagline: _businessTaglineController.text
                                .trim(),
                            identityMode: PosterIdentityMode.business,
                          );
                          final isSelected =
                              _draftProfile.businessLogoStyleId == styleId &&
                              _draftProfile.businessLogoPath.trim().isEmpty &&
                              _draftProfile.businessLogoUrl.trim().isEmpty;
                          return GestureDetector(
                            onTap: () {
                              final previousLogoPath =
                                  _draftProfile.businessLogoPath;
                              unawaited(
                                _deleteLocalAssetUnlessKept(
                                  previousLogoPath,
                                  <String>{},
                                ),
                              );
                              final updatedProfile = _draftProfile.copyWith(
                                identityMode: PosterIdentityMode.business,
                                businessLogoStyleId: styleId,
                                businessLogoPath: '',
                                businessLogoUrl: '',
                              );
                              setState(() {
                                _draftProfile = updatedProfile;
                              });
                              unawaited(
                                PosterProfileService.saveBusinessLogoAssets(
                                  businessLogoPath: '',
                                  businessLogoUrl: '',
                                  businessLogoStyleId: styleId,
                                  identityMode: PosterIdentityMode.business,
                                  saveRemoteUrl: true,
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 96,
                              child: Column(
                                children: <Widget>[
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 88,
                                    height: 88,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF6D28D9)
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? const <BoxShadow>[
                                              BoxShadow(
                                                color: Color(0x146D28D9),
                                                blurRadius: 10,
                                                offset: Offset(0, 3),
                                              ),
                                            ]
                                          : const <BoxShadow>[],
                                    ),
                                    child: ClipOval(
                                      child: PosterIdentityVisual(
                                        profile: previewProfile,
                                        textScale: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    strings.localized(
                                      telugu: 'స్టైల్ ${index + 1}',
                                      english: 'Style ${index + 1}',
                                      hindi: 'शैली ${index + 1}',
                                      tamil: 'பாணி ${index + 1}',
                                      kannada: 'ಶೈಲಿ ${index + 1}',
                                      malayalam: 'ശൈലി ${index + 1}',
                                      marathi: 'शैली ${index + 1}',
                                      gujarati: 'શૈલી ${index + 1}',
                                      bengali: 'ধরন ${index + 1}',
                                      punjabi: 'ਸ਼ੈਲੀ ${index + 1}',
                                      odia: 'ଶୈଳୀ ${index + 1}',
                                      assamese: 'শৈলী ${index + 1}',
                                      konkani: 'ಶೈಲಿ ${index + 1}',
                                      nepali: 'शैली ${index + 1}',
                                      meitei: 'স্তাইল ${index + 1}',
                                      mizo: 'Style ${index + 1}',
                                      kashmiri: 'انداز ${index + 1}',
                                      ladakhi: 'བཟོ་ལྟ་ ${index + 1}',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFF6D28D9)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Uint8List _optimizeProfilePhotoBytes(Uint8List bytes) {
  return bytes;
}

Uint8List _prepareProfilePhotoRemovalBytes(Uint8List bytes) {
  return bytes;
}

class _ProfilePhotoPickAction {
  const _ProfilePhotoPickAction.upload()
    : uploadNew = true,
      croppedPath = null,
      cutout = null;

  const _ProfilePhotoPickAction.cropped(this.croppedPath, {this.cutout})
    : uploadNew = false;

  final bool uploadNew;
  final String? croppedPath;
  final UserSavedCutoutPhoto? cutout;
}

class _ProfilePhotoPickerScreen extends StatefulWidget {
  const _ProfilePhotoPickerScreen({
    required this.cutouts,
    this.currentPhotoUrl = '',
    this.currentPhotoPath = '',
  });

  final List<UserSavedCutoutPhoto> cutouts;
  final String currentPhotoUrl;
  final String currentPhotoPath;

  @override
  State<_ProfilePhotoPickerScreen> createState() =>
      _ProfilePhotoPickerScreenState();
}

class _ProfilePhotoPickerScreenState extends State<_ProfilePhotoPickerScreen> {
  late List<UserSavedCutoutPhoto> _cutouts;
  static const int _maxPhotosLimit = 5;

  @override
  void initState() {
    super.initState();
    _cutouts = List<UserSavedCutoutPhoto>.from(widget.cutouts);
  }

  bool _isCutoutActive(UserSavedCutoutPhoto cutout) {
    final curUrl = widget.currentPhotoUrl.trim();
    final curPath = widget.currentPhotoPath.trim();
    final cutoutUrl = cutout.downloadUrl.trim();
    final cutoutPath = cutout.localPath.trim();

    if (curUrl.isNotEmpty && cutoutUrl.isNotEmpty && curUrl == cutoutUrl) {
      return true;
    }
    if (curPath.isNotEmpty && cutoutPath.isNotEmpty && curPath == cutoutPath) {
      return true;
    }
    return false;
  }

  void _onUploadTapped() {
    if (_cutouts.length >= _maxPhotosLimit) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            dialogContext.strings.localized(
              telugu: 'పరిమితి పూర్తయింది',
              english: 'Limit Reached',
              hindi: 'सीमा समाप्त',
              tamil: 'வரம்பு முடிந்தது',
              kannada: 'ಮಿತಿ ಮೀರಿದೆ',
              malayalam: 'പരിധി കഴിഞ്ഞു',
              marathi: 'मर्यादा संपली',
              gujarati: 'મર્યાદા પૂર્ણ',
              bengali: 'সীমা সমাপ্ত',
              punjabi: 'ਸੀਮਾ ਪੂਰੀ ਹੋ ਗਈ',
              odia: 'ସୀମା ସମାପ୍ତ',
              assamese: 'সীমা সমাপ্ত',
              konkani: 'ಮರ್ಯಾದಾ ಸಂಪ್ಲಿ',
              nepali: 'सीमा समाप्त',
              meitei: 'Limit Reached',
              mizo: 'Limit Reached',
              kashmiri: 'حد ختم',
              ladakhi: 'Limit Reached',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            dialogContext.strings.localized(
              telugu:
                  'గరిష్టంగా 5 ఫోటోలు మాత్రమే సేవ్ చేయగలరు. కొత్త ఫోటో అప్‌లోడ్ చేయడానికి దయచేసి పాత ఫోటోను తొలగించండి.',
              english:
                  'You can only save up to 5 photos. Please delete an older photo before uploading a new one.',
              hindi:
                  'आप अधिकतम 5 फ़ोटो ही सहेज सकते हैं। नई फ़ोटो अपलोड करने के लिए कृपया पुरानी फ़ोटो हटाएं।',
              tamil:
                  'நீங்கள் அதிகபட்சமாக 5 புகைப்படங்களை மட்டுமே சேமிக்க முடியும். புதிய புகைப்படத்தைப் பதிவேற்ற பழைய புகைப்படத்தை நீக்கவும்.',
              kannada:
                  'ನೀವು ಗರಿಷ್ಠ 5 ಫೋಟೋಗಳನ್ನು ಮಾತ್ರ ಉಳಿಸಬಹುದು. ಹೊಸ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಲು ಹಳೆಯ ಫೋಟೋವನ್ನು ಅಳಿಸಿ.',
              malayalam:
                  'നിങ്ങൾക്ക് പരമാവധി 5 ഫോട്ടോകൾ മാത്രമേ സംരക്ഷിക്കാനാകൂ. പുതിയ ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യാൻ പഴയ ഫോട്ടോ ഇല്ലാതാക്കുക.',
              marathi:
                  'तुम्ही जास्तीत जास्त 5 फोटो सेव्ह करू शकता. नवीन फोटो अपलोड करण्यासाठी कृपया जुना फोटो हटवा.',
              gujarati:
                  'તમે વધુમાં વધુ 5 ફોટા સાચવી શકો છો. નવો ફોટો અપલોડ કરવા માટે જૂનો ફોટો કાઢી નાખો.',
              bengali:
                  'আপনি সর্বোচ্চ ৫টি ছবি সংরক্ষণ করতে পারেন। নতুন ছবি আপলোড করতে পুরানো ছবি মুছুন।',
              punjabi:
                  'ਤੁਸੀਂ ਵੱਧ ਤੋਂ ਵੱਧ 5 ਫੋਟੋਆਂ ਸੁਰੱਖਿਅਤ ਕਰ ਸਕਦੇ ਹੋ। ਨਵੀਂ ਫੋਟੋ ਅੱਪਲੋਡ ਕਰਨ ਲਈ ਪੁਰਾਣੀ ਫੋਟੋ ਮਿਟਾਓ।',
              odia:
                  'ଆପଣ ସର୍ବାଧିକ 5 ଫଟୋ ସଂରକ୍ଷଣ କରିପାରିବେ। ନୂଆ ଫଟୋ ଅପଲୋଡ୍ କରିବାକୁ ପୁରୁଣା ଫଟୋ ବିଲୋପ କରନ୍ତୁ।',
              assamese:
                  'আপুনি সৰ্বাধিক ৫ খন ফটো সংৰক্ষণ কৰিব পাৰে। নতুন ফটো আপলোড কৰিবলৈ পুৰণি ফটো বিলোপ কৰক।',
              konkani:
                  'ತುಮಿ ಚಡಾಂತ್ ಚಡ್ 5 ಫೋಟೋ ಸಾಂಪಾಳ್ನ್ ದವರಿಂಕ್ ಜಾತಾ. ನವೋ ಫೋಟೋ ಅಪ್ಲೋಡ್ ಕರುಂಕ್ ಪರನೊ ಫೋಟೋ ಕಾಡ್ನ್ ಉಡಯಾ.',
              nepali:
                  'तपाईं अधिकतम ५ वटा तस्बिर मात्र सुरक्षित गर्न सक्नुहुन्छ। नयाँ तस्बिर अपलोड गर्न पुरानो तस्बिर मेटाउनुहोस्।',
              meitei:
                  'You can only save up to 5 photos. Please delete an older photo before uploading a new one.',
              mizo:
                  'You can only save up to 5 photos. Please delete an older photo before uploading a new one.',
              kashmiri:
                  'تہہ ہیکیو صرف 5 فوٹو محفوظ کٔرتھ۔ نٔو فوٹو اپلوڈ کرنہٕ باپتھ کٔریو پرٛون فوٹو ڈیلیٹ۔',
              ladakhi:
                  'You can only save up to 5 photos. Please delete an older photo before uploading a new one.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                dialogContext.strings.localized(
                  telugu: 'సరే',
                  english: 'OK',
                  hindi: 'ठीक है',
                  tamil: 'சரி',
                  kannada: 'ಸರಿ',
                  malayalam: 'ശരി',
                  marathi: 'ठीक आहे',
                  gujarati: 'બરાબર',
                  bengali: 'ঠিক আছে',
                  punjabi: 'ਠੀਕ ਹੈ',
                  odia: 'ଠିକ୍ ଅଛି',
                  assamese: 'ঠিক আছে',
                  konkani: 'ಬರೆಂ',
                  nepali: 'हुन्छ',
                  meitei: 'OK',
                  mizo: 'Awle',
                  kashmiri: 'ٹھیک چھُ',
                  ladakhi: 'OK',
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.of(context).pop(const _ProfilePhotoPickAction.upload());
  }

  Future<void> _deleteCutout(UserSavedCutoutPhoto cutout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          dialogContext.strings.localized(
            telugu: 'ఫోటోను తొలగించాలా?',
            english: 'Delete Photo?',
            hindi: 'फ़ोटो हटाएं?',
            tamil: 'புகைப்படத்தை நீக்கவா?',
            kannada: 'ಫೋಟೋ ಅಳಿಸಬೇಕೇ?',
            malayalam: 'ഫോട്ടോ ഇല്ലാതാക്കണോ?',
            marathi: 'फोटो हटवायचा?',
            gujarati: 'ફોટો કાઢી નાખવો છે?',
            bengali: 'ছবি মুছবেন?',
            punjabi: 'ਫੋਟੋ ਮਿਟਾਉਣੀ ਹੈ?',
            odia: 'ଫଟୋ ବିଲୋପ କରିବେ କି?',
            assamese: 'ফটোখন ডিলিট কৰিবনে?',
            konkani: 'ಫೋಟೋ ಕಾಡ್ನ್ ಉಡಂವ್ಚೊಗೀ?',
            nepali: 'तस्बिर मेटाउने?',
            meitei: 'Delete Photo?',
            mizo: 'Photo paih em?',
            kashmiri: 'فوٹو مٹاوون؟',
            ladakhi: 'Delete Photo?',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          dialogContext.strings.localized(
            telugu: 'ఈ సేవ్ చేసిన ఫోటో మీ లిస్ట్ నుండి తొలగించబడుతుంది.',
            english:
                'This photo will be permanently deleted from your saved list.',
            hindi: 'यह सहेजी गई फ़ोटो आपकी सूची से हटा दी जाएगी।',
            tamil:
                'இந்த சேமிக்கப்பட்ட புகைப்படம் உங்கள் பட்டியலிலிருந்து நீக்கப்படும்.',
            kannada: 'ಈ ಉಳಿಸಲಾದ ಫೋಟೋ ನಿಮ್ಮ ಪಟ್ಟಿಯಿಂದ ಅಳಿಸಲ್ಪಡುತ್ತದೆ.',
            malayalam:
                'ഈ സംരക്ഷിച്ച ഫോട്ടോ നിങ്ങളുടെ ലിസ്റ്റിൽ നിന്ന് നീക്കംചെയ്യപ്പെടും.',
            marathi: 'हा जतन केलेला फोटो तुमच्या सूचीमधून काढून टाकला जाईल.',
            gujarati: 'આ સાચવેલો ફોટો તમારી યાદીમાંથી કાઢી નાખવામાં આવશે.',
            bengali: 'এই সংরক্ষিত ছবিটি আপনার তালিকা থেকে মুছে ফেলা হবে।',
            punjabi:
                'ਇਹ ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਫੋਟੋ ਤੁਹਾਡੀ ਸੂਚੀ ਵਿੱਚੋਂ ਹਟਾ ਦਿੱਤੀ ਜਾਵੇਗੀ।',
            odia: 'ଏହି ସଂରକ୍ଷିତ ଫଟୋ ଆପଣଙ୍କ ତାଲିକାରୁ ବିଲୋପ କରାଯିବ।',
            assamese: 'এই সংৰক্ষিত ফটোখন আপোনাৰ তালিকাৰ পৰা বিলোপ কৰা হ’ব।',
            konkani:
                'ಹೊ ಸಾಂಪಾಳ್ಳೊ ಫೋಟೋ ತುಮ್ಚ್ಯಾ ವಳೆರಿಂತ್ಲ್ಯಾನ್ ಕಾಡ್ನ್ ಉಡಯ್ತಲೆಂ.',
            nepali: 'यो सुरक्षित गरिएको तस्बिर तपाईंको सूचीबाट हटाइनेछ।',
            meitei:
                'This photo will be permanently deleted from your saved list.',
            mizo: 'He saved photo hi i list atangin paih a ni ang.',
            kashmiri: 'یہ محفوظ کٔرمُت فوٹو ییہٕ تۄہندِ لِسٹہِ منٛزٕ کڑنہٕ۔',
            ladakhi:
                'This photo will be permanently deleted from your saved list.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              dialogContext.strings.localized(
                telugu: 'రద్దు చేయి',
                english: 'Cancel',
                hindi: 'रद्द करें',
                tamil: 'ரத்துசெய்',
                kannada: 'ರದ್ದುಮಾಡಿ',
                malayalam: 'റദ്ദാക്കുക',
                marathi: 'रद्द करा',
                gujarati: 'રદ કરો',
                bengali: 'বাতিল',
                punjabi: 'ਰੱਦ ਕਰੋ',
                odia: 'ବାତିଲ୍ କରନ୍ତୁ',
                assamese: 'বাতিল কৰক',
                konkani: 'ರದ್ದ್ ಕರಾ',
                nepali: 'रद्द गर्नुहोस्',
                meitei: 'Cancel',
                mizo: 'Thulh',
                kashmiri: 'منسوخ',
                ladakhi: 'Cancel',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              dialogContext.strings.localized(
                telugu: 'తొలగించు',
                english: 'Delete',
                hindi: 'हटाएं',
                tamil: 'நீக்கு',
                kannada: 'ಅಳಿಸಿ',
                malayalam: 'ഇല്ലാതാക്കുക',
                marathi: 'हटवा',
                gujarati: 'કાઢી નાખો',
                bengali: 'মুছুন',
                punjabi: 'ਮਿਟਾਓ',
                odia: 'ବିଲୋପ କରନ୍ତୁ',
                assamese: 'বিলোপ কৰক',
                konkani: 'ಕಾಡ್ನ್ ಉಡಯಾ',
                nepali: 'मेटाउनुहोस्',
                meitei: 'Delete',
                mizo: 'Paih',
                kashmiri: 'مٹاو',
                ladakhi: 'Delete',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await PosterProfileService.deleteReusableCutoutPhoto(
      id: cutout.id,
      downloadUrl: cutout.downloadUrl,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      final wasActive = _isCutoutActive(cutout);
      setState(() {
        _cutouts.removeWhere((item) => item.id == cutout.id);
      });
      if (wasActive) {
        await PosterProfileService.savePersonalPhotoAssets(
          photoPath: '',
          originalPhotoPath: '',
          photoUrl: '',
          originalPhotoUrl: '',
          preferOriginalPersonalPhoto: false,
          saveRemoteUrls: true,
          personalPhotoRevision: DateTime.now().millisecondsSinceEpoch,
        );
        if (!mounted) {
          return;
        }
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ఫోటో తొలగించబడింది.',
              english: 'Photo deleted successfully.',
              hindi: 'फ़ोटो सफलतापूर्वक हटा दी गई।',
              tamil: 'புகைப்படம் வெற்றிகரமாக நீக்கப்பட்டது.',
              kannada: 'ಫೋಟೋ ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ.',
              malayalam: 'ഫോട്ടോ വിജയകരമായി ഇല്ലാതാക്കി.',
              marathi: 'फोटो यशस्वीरित्या हटवला.',
              gujarati: 'ફોટો સફળતાપૂર્વક કાઢી નાખવામાં આવ્યો.',
              bengali: 'ছবি সফলভাবে মুছে ফেলা হয়েছে।',
              punjabi: 'ਫੋਟੋ ਸਫਲਤਾਪੂਰਵਕ ਮਿਟਾਈ ਗਈ।',
              odia: 'ଫଟୋ ସଫଳତାର ସହିତ ବିଲୋପ କରାଗଲା।',
              assamese: 'ফটো সফলতাৰে বিলোপ কৰা হ’ল।',
              konkani: 'ಫೋಟೋ ಯಶಸ್ವೆಸ್ವಿಕ್ ಜಾವ್ನ್ ಕಾಡ್ನ್ ಉಡಯ್ಲೊ.',
              nepali: 'तस्बिर सफलतापूर्वक मेटाइयो।',
              meitei: 'Photo deleted successfully.',
              mizo: 'Photo paih fel a ni.',
              kashmiri: 'فوٹو آو کامیابی سان مٹاونہٕ۔',
              ladakhi: 'Photo deleted successfully.',
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'ఫోటోను తొలగించడం సాధ్యం కాలేదు.',
              english: 'Failed to delete photo.',
              hindi: 'फ़ोटो हटाने में विफल।',
              tamil: 'புகைப்படத்தை நீக்க முடியவில்லை.',
              kannada: 'ಫೋಟೋ ಅಳಿಸಲು ವಿಫಲವಾಗಿದೆ.',
              malayalam: 'ഫോട്ടോ ഇല്ലാതാക്കാൻ കഴിഞ്ഞില്ല.',
              marathi: 'फोटो हटवण्यात अयशस्वी.',
              gujarati: 'ફોટો કાઢી નાખવામાં નિષ્ફળ.',
              bengali: 'ছবি মুছতে ব্যর্থ হয়েছে।',
              punjabi: 'ਫੋਟੋ ਮਿਟਾਉਣ ਵਿੱਚ ਅਸਫਲ।',
              odia: 'ଫଟୋ ବିଲୋପ କରିବାରେ ବିଫଳ।',
              assamese: 'ফটো বিলোপ কৰাত ব্যৰ্থ হ’ল।',
              konkani: 'ಫೋಟೋ ಕಾಡ್ನ್ ಉಡಂವ್ಕ್ ಜಾವ್ನಾ.',
              nepali: 'तस्बिर मेटाउन असफल भयो।',
              meitei: 'Failed to delete photo.',
              mizo: 'Photo paih theih loh.',
              kashmiri: 'فوٹو مٹاونَس منٛز ناکامی۔',
              ladakhi: 'Failed to delete photo.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.localized(
                telugu: 'ప్రొఫైల్ ఫోటోలు',
                english: 'Profile Photos',
                hindi: 'प्रोफ़ाइल फ़ोटो',
                tamil: 'சுயவிவரப் படங்கள்',
                kannada: 'ಪ್ರೊಫೈಲ್ ಫೋಟೋಗಳು',
                malayalam: 'പ്രൊഫൈൽ ഫോട്ടോകൾ',
                marathi: 'प्रोफाइल फोटो',
                gujarati: 'પ્રોફાઇલ ફોટા',
                bengali: 'প্রোফাইল ছবি',
                punjabi: 'ਪ੍ਰੋਫਾਈਲ ਫੋਟੋਆਂ',
                odia: 'ପ୍ରୋଫାଇଲ୍ ଫଟୋ',
                assamese: 'প্ৰফাইল ফটো',
                konkani: 'ಪ್ರೊಫೈಲ್ ಫೋಟೋ',
                nepali: 'प्रोफाइल तस्बिरहरू',
                meitei: 'Profile Photos',
                mizo: 'Profile Photos',
                kashmiri: 'پروفائل فوٹو',
                ladakhi: 'Profile Photos',
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              context.strings.localized(
                telugu: 'సేవ్ చేసినవి: ${_cutouts.length}/$_maxPhotosLimit',
                english: 'Saved: ${_cutouts.length}/$_maxPhotosLimit',
                hindi: 'सहेजे गए: ${_cutouts.length}/$_maxPhotosLimit',
                tamil: 'சேமிக்கப்பட்டவை: ${_cutouts.length}/$_maxPhotosLimit',
                kannada: 'ಉಳಿಸಲಾಗಿದೆ: ${_cutouts.length}/$_maxPhotosLimit',
                malayalam: 'സംരക്ഷിച്ചവ: ${_cutouts.length}/$_maxPhotosLimit',
                marathi: 'जतन केलेले: ${_cutouts.length}/$_maxPhotosLimit',
                gujarati: 'સાચવેલ: ${_cutouts.length}/$_maxPhotosLimit',
                bengali: 'সংরক্ষিত: ${_cutouts.length}/$_maxPhotosLimit',
                punjabi: 'ਸੁਰੱਖਿਅਤ: ${_cutouts.length}/$_maxPhotosLimit',
                odia: 'ସଂରକ୍ଷିତ: ${_cutouts.length}/$_maxPhotosLimit',
                assamese: 'সংৰক্ষিত: ${_cutouts.length}/$_maxPhotosLimit',
                konkani: 'ಸಾಂಪಾಳ್ಳೆಂ: ${_cutouts.length}/$_maxPhotosLimit',
                nepali: 'सुरक्षित: ${_cutouts.length}/$_maxPhotosLimit',
                meitei: 'Saved: ${_cutouts.length}/$_maxPhotosLimit',
                mizo: 'Dahthat: ${_cutouts.length}/$_maxPhotosLimit',
                kashmiri: 'محفوظ: ${_cutouts.length}/$_maxPhotosLimit',
                ladakhi: 'Saved: ${_cutouts.length}/$_maxPhotosLimit',
              ),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _onUploadTapped,
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(
                    context.strings.localized(
                      telugu: 'ఫోటో అప్‌లోడ్',
                      english: 'Upload Photo',
                      hindi: 'फ़ोटो अपलोड करें',
                      tamil: 'புகைப்படம் பதிவேற்றுக',
                      kannada: 'ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
                      malayalam: 'ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യുക',
                      marathi: 'फोटो अपलोड करा',
                      gujarati: 'ફોટો અપલોડ કરો',
                      bengali: 'ছবি আপলোড করুন',
                      punjabi: 'ਫੋਟੋ ਅੱਪਲੋਡ ਕਰੋ',
                      odia: 'ଫଟୋ ଅପଲୋଡ୍ କରନ୍ତୁ',
                      assamese: 'ফটো আপলোড কৰক',
                      konkani: 'ಫೋಟೋ ಅಪ್ಲೋಡ್ ಕರಾ',
                      nepali: 'तस्बिर अपलोड गर्नुहोस्',
                      meitei: 'Photo Upload',
                      mizo: 'Photo Dah lut',
                      kashmiri: 'فوٹو اپلوڈ کٔریو',
                      ladakhi: 'Photo Upload',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            if (_cutouts.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    context.strings.localized(
                      telugu: 'ఇంకా సేవ్ చేసిన PNG ఫోటోలు లేవు.',
                      english: 'No saved PNG photos yet.',
                      hindi: 'अभी तक कोई सहेजी गई PNG फ़ोटो नहीं है।',
                      tamil: 'இன்னும் சேமிக்கப்பட்ட PNG புகைப்படங்கள் இல்லை.',
                      kannada: 'ಇನ್ನೂ ಯಾವುದೇ ಉಳಿಸಲಾದ PNG ಫೋಟೋಗಳಿಲ್ಲ.',
                      malayalam: 'സംരക്ഷിച്ച PNG ഫോട്ടോകളൊന്നും ഇതുവരെ ഇല്ല.',
                      marathi: 'अद्याप कोणतेही जतन केलेले PNG फोटो नाहीत.',
                      gujarati: 'હજુ સુધી કોઈ સાચવેલા PNG ફોટા નથી.',
                      bengali: 'এখনও কোনো সংরক্ষিত PNG ছবি নেই।',
                      punjabi: 'ਅਜੇ ਤੱਕ ਕੋਈ ਸੁਰੱਖਿਅਤ ਕੀਤੀ PNG ਫੋਟੋ ਨਹੀਂ ਹੈ।',
                      odia: 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ସଂରକ୍ଷିତ PNG ଫଟୋ ନାହିଁ।',
                      assamese: 'এতিয়ালৈকে কোনো সংৰক্ষিত PNG ফটো নাই।',
                      konkani: 'ಅಜೂನ್ ಸಾಂಪಾಳ್ಳೆ PNG ಫೋಟೋ ನಾಂತ್.',
                      nepali: 'अहिलेसम्म कुनै सुरक्षित PNG तस्बिर छैन।',
                      meitei: 'No saved PNG photos yet.',
                      mizo: 'PNG photo dahthat a la awm lo.',
                      kashmiri: 'کینہہ محفوظ PNG فوٹو چھُنہٕ ونہٕ۔',
                      ladakhi: 'No saved PNG photos yet.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _cutouts.length,
                  itemBuilder: (context, index) {
                    final item = _cutouts[index];
                    final isActive = _isCutoutActive(item);
                    return _ProfileSavedCutoutTile(
                      cutout: item,
                      isActive: isActive,
                      onDelete: () => _deleteCutout(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSavedCutoutTile extends StatefulWidget {
  const _ProfileSavedCutoutTile({
    required this.cutout,
    required this.isActive,
    required this.onDelete,
  });

  final UserSavedCutoutPhoto cutout;
  final bool isActive;
  final VoidCallback onDelete;

  @override
  State<_ProfileSavedCutoutTile> createState() =>
      _ProfileSavedCutoutTileState();
}

class _ProfileSavedCutoutTileState extends State<_ProfileSavedCutoutTile> {
  bool _busy = false;

  Future<void> _cropSavedCutout() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
    });
    File? stagedCropSourceFile;
    try {
      stagedCropSourceFile = await _materializeProfileCutoutForCrop(
        widget.cutout,
      );
      if (!mounted) {
        return;
      }
      final cropped = await ImageCropper().cropImage(
        sourcePath: stagedCropSourceFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF0F172A),
            activeControlsWidgetColor: const Color(0xFF2563EB),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (!mounted || cropped == null) {
        return;
      }
      Navigator.of(context).pop(
        _ProfilePhotoPickAction.cropped(cropped.path, cutout: widget.cutout),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Profile saved cutout crop picker failed: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              context.strings.localized(
                telugu: 'సేవ్ చేసిన ప్రొఫైల్ ఫోటో క్రాప్ చేయలేకపోయాం.',
                english: 'Could not crop saved profile photo.',
                hindi: 'सहेजे गए प्रोफ़ाइल फ़ोटो को क्रॉप नहीं किया जा सका।',
                tamil:
                    'சேமிக்கப்பட்ட சுயவிவர புகைப்படத்தை கிராப் செய்ய முடியவில்லை.',
                kannada: 'ಉಳಿಸಲಾದ ಪ್ರೊಫೈಲ್ ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
                malayalam:
                    'സേവ് ചെയ്ത പ്രൊഫൈൽ ഫോട്ടോ ക്രോപ്പ് ചെയ്യാൻ കഴിഞ്ഞില്ല.',
                marathi: 'सेव्ह केलेला प्रोफाइल फोटो क्रॉप करता आला नाही.',
                gujarati: 'સાચવેલ પ્રોફાઇલ ફોટો ક્રોપ કરી શકાયો નથી.',
                bengali: 'সংরক্ষিত প্রোফাইল ছবি ক্রপ করা যায়নি।',
                punjabi: 'ਸੁਰੱਖਿਅਤ ਕੀਤੀ ਪ੍ਰੋਫਾਈਲ ਫੋਟੋ ਕੱਟੀ ਨਹੀਂ ਜਾ ਸਕੀ।',
                odia: 'ସେଭ୍ ହୋଇଥିବା ପ୍ରୋଫାଇଲ୍ ଫଟୋ କ୍ରପ୍ କରିପାରିଲା ନାହିଁ।',
                assamese: 'সংৰক্ষিত প্ৰʼফাইল ফটো ক্ৰপ কৰিব পৰা নগʼল।',
                konkani: 'ಸಾಂಭಾಳ್ಳೊ ಪ್ರೊಫೈಲ್ ಫೋಟೋ ಕ್ರಾಪ್ ಕರುಂಕ್ ಜಾಲೆಂ ನಾ.',
                nepali: 'सुरक्षित गरिएको प्रोफाइल तस्बिर क्रप गर्न सकिएन।',
                meitei: 'সেভ তৌবা প্রোফাইল ফোতো ক্রোপ তৌবা ঙমদ্রে।',
                mizo: 'Profile thlalak save tawh tan kual theih a ni lo.',
                kashmiri: 'مَحفوٗظ شُدٕ پروفائل فوٹو ہیۆک نہٕ کراپ کٔرِتھ۔',
                ladakhi: 'ཉར་ཚགས་བྱས་པའི་གསལ་བཤད་འདྲ་པར་དྲ་བཅད་བྱེད་མ་ཐུབ།',
              ),
            ),
          ),
        );
      }
    } finally {
      if (stagedCropSourceFile != null) {
        unawaited(_deleteStagedFileSilently(stagedCropSourceFile));
      }
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _deleteStagedFileSilently(File? file) async {
    if (file == null) {
      return;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final localPath = widget.cutout.localPath.trim();
    final localFile = localPath.isEmpty ? null : File(localPath);
    final image = localFile != null && localFile.existsSync()
        ? Image.file(localFile, fit: BoxFit.contain)
        : Image.network(widget.cutout.downloadUrl, fit: BoxFit.contain);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isActive
                ? const Color(0xFF16A34A)
                : const Color(0xFFE2E8F0),
            width: widget.isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            InkWell(
              onTap: _busy ? null : _cropSavedCutout,
              child: Padding(padding: const EdgeInsets.all(8), child: image),
            ),
            if (widget.isActive)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.strings.localized(
                          telugu: 'యాక్టివ్',
                          english: 'Active',
                          hindi: 'सक्रिय',
                          tamil: 'செயலில்',
                          kannada: 'ಸಕ್ರಿಯ',
                          malayalam: 'സജീവം',
                          marathi: 'सक्रिय',
                          gujarati: 'સક્રિય',
                          bengali: 'সক্রিয়',
                          punjabi: 'ਸਰਗਰਮ',
                          odia: 'ସକ୍ରିୟ',
                          assamese: 'সক্ৰিয়',
                          konkani: 'ಸಕ್ರಿಯ',
                          nepali: 'सक्रिय',
                          meitei: 'Active',
                          mizo: 'Active',
                          kashmiri: 'سرگرم',
                          ladakhi: 'Active',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!widget.isActive)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _busy ? null : widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xE6FFFFFF),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ),
            if (_busy)
              const ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<File> _materializeProfileCutoutForCrop(
  UserSavedCutoutPhoto cutout,
) async {
  final tempDir = await getTemporaryDirectory();
  final tempFile = File(
    '${tempDir.path}${Platform.pathSeparator}'
    'poster_profile_saved_cutout_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  final localPath = cutout.localPath.trim();
  if (localPath.isNotEmpty) {
    final localFile = File(localPath);
    if (await localFile.exists() && await localFile.length() > 0) {
      return localFile.copy(tempFile.path);
    }
  }
  final url = cutout.downloadUrl.trim();
  if (url.isEmpty) {
    throw StateError('Saved cutout has no image source.');
  }
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Cutout download failed: ${response.statusCode}');
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile;
  } finally {
    client.close(force: true);
  }
}

class _ProfilePhotoUploadGuideSheet extends StatelessWidget {
  const _ProfilePhotoUploadGuideSheet({
    required this.strings,
    required this.config,
    required this.loading,
  });

  final AppStrings strings;
  final ProfilePhotoGuideConfig config;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final title = strings.localized(
      telugu: 'పోస్టర్ కోసం సరైన ఫోటో ఎంచుకోండి',
      english: 'Choose the right photo for posters',
      hindi: 'पोस्टर के लिए सही फ़ोटो चुनें',
      tamil: 'போஸ்டருக்கு சரியான புகைப்படத்தைத் தேர்வுசெய்யவும்',
      kannada: 'ಪೋಸ್ಟರ್‌ಗಾಗಿ ಸರಿಯಾದ ಫೋಟೋ ಆಯ್ಕೆಮಾಡಿ',
      malayalam: 'പോസ്റ്ററുകൾക്കായി അനുയോജ്യമായ ഫോട്ടോ തിരഞ്ഞെടുക്കുക',
      marathi: 'पोस्टरसाठी योग्य फोटो निवडा',
      gujarati: 'પોસ્ટર માટે યોગ્ય ફોટો પસંદ કરો',
      bengali: 'পোস্টারের জন্য সঠিক ছবি বেছে নিন',
      punjabi: 'ਪੋਸਟਰ ਲਈ ਸਹੀ ਫੋਟੋ ਚੁਣੋ',
      odia: 'ପୋଷ୍ଟର ପାଇଁ ସଠିକ୍ ଫଟୋ ବାଛନ୍ତୁ',
      assamese: 'পোষ্টাৰৰ বাবে সঠিক ফটো বাছক',
      konkani: 'ಪೋಸ್ಟರಾಕ್ ಸಾರ್ಕೊ ಫೋಟೋ ವಿಂಚಾ',
      nepali: 'पोस्टरका लागि सही फोटो छनोट गर्नुहोस्',
      meitei: 'পোস্তরগীদমক চুম্বা ফোতো খনগৎলু',
      mizo: 'Poster tana thlalak tha thlang rawh',
      kashmiri: 'پوسٹر باپتھ ژٲریو صٔحیح فوٹو',
      ladakhi: 'པོསྚར་གྱི་ཆེད་དུ་འོས་པའི་འདྲ་པར་འདེམས།',
    );
    final guidance = strings.localized(
      telugu:
          'ముందు వైపు ముఖం క్లియర్‌గా, తల పూర్తిగా, భుజాలు కనిపించే ఫోటో వాడండి.',
      english: 'Use a clear front photo with full head and shoulders visible.',
      hindi:
          'सामने का स्पष्ट चेहरा, पूरा सिर और कंधे दिखने वाली फ़ोटो का उपयोग करें।',
      tamil:
          'முன்பக்க முகம் தெளிவாக, தலை முழுமையாகவும் தோள்கள் தெரியும்படியும் உள்ள புகைப்படத்தைப் பயன்படுத்தவும்.',
      kannada:
          'ಮುಂಭಾಗದ ಮುಖ ಸ್ಪಷ್ಟವಾಗಿ, ತಲೆ ಪೂರ್ಣವಾಗಿ, ಭುಜಗಳು ಕಾಣಿಸುವ ಫೋಟೋ ಬಳಸಿ.',
      malayalam:
          'മുൻവശത്തെ മുഖം വ്യക്തമായും, തല പൂർണ്ണമായും, തോളുകൾ കാണുന്നതുമായ ഫോട്ടോ ഉപയോഗിക്കുക.',
      marathi: 'समोरचा चेहरा स्पष्ट, पूर्ण डोके आणि खांदे दिसणारा फोटो वापरा.',
      gujarati:
          'સામેનો ચહેરો સ્પષ્ટ, સંપૂર્ણ માથું અને ખભા દેખાતા હોય તેવો ફોટો વાપરો.',
      bengali:
          'সামনের মুখ পরিষ্কার, পুরো মাথা ও কাঁধ দেখা যায় এমন ছবি ব্যবহার করুন।',
      punjabi:
          'ਸਾਹਮਣੇ ਦਾ ਚਿਹਰਾ ਸਾਫ਼, ਪੂਰਾ ਸਿਰ ਅਤੇ ਮੋਢੇ ਦਿਖਾਈ ਦੇਣ ਵਾਲੀ ਫੋਟੋ ਵਰਤੋ।',
      odia:
          'ସାମ୍ନା ମୁହଁ ସ୍ପଷ୍ଟ, ସମ୍ପୂର୍ଣ୍ଣ ମୁଣ୍ଡ ଏବଂ କାନ୍ଧ ଦେଖାଯାଉଥିବା ଫଟୋ ବ୍ୟବହାର କରନ୍ତୁ।',
      assamese:
          'সন্মূখৰ মুখ স্পষ্ট, সম্পূৰ্ণ মূৰ আৰু কান্ধ দেখা পোৱা ফটো ব্যৱহাৰ কৰক।',
      konkani: 'ಮುಖ್ಲೆಂ ತೋಂಡ್ ನಿತಳ್, ಮಸ್ತಕ್ ಆನಿ ಭುಜಾಂ ದಿಸ್ಚೊ ಫೋಟೋ ವಾಪರಾ.',
      nepali:
          'अगाडिको अनुहार स्पष्ट, पूरा टाउको र काँध देखिने फोटो प्रयोग गर्नुहोस्।',
      meitei:
          'মমাংগী মাইথোং শেংনা, মকোক মপুং ফানা অমসুং লেনবান উবা ফোতো শীজিন্নবীয়ু।',
      mizo: 'Hma lam chiang tak, lu pum leh dar lang vek thlalak hmang rawh.',
      kashmiri:
          'بُتھ صَفٲیی سان، پوٗرٕ کَلَہ تہٕ شانہٕ ظٲہِر گژھن وول فوٹو کٔریو اِستعمال۔',
      ladakhi:
          'གདོང་ངོས་གསལ་པོ། མགོ་ཡོངས་རྫོགས་དང་དཔུང་པ་མཐོང་བའི་འདྲ་པར་སྤྱོད།',
    );
    final avoid = strings.localized(
      telugu: 'తల కట్, బ్లర్, గ్రూప్ ఫోటో వద్దు.',
      english: 'Avoid cut heads, blur, and group photos.',
      hindi: 'कटा हुआ सिर, धुंधली और समूह फ़ोटो से बचें।',
      tamil:
          'தலை வெட்டப்பட்ட, தெளிவற்ற மற்றும் குழு புகைப்படங்களைத் தவிர்க்கவும்.',
      kannada: 'ತಲೆ ಕತ್ತರಿಸಿದ, ಮಸುಕಾದ ಮತ್ತು ಗುಂಪು ಫೋಟೋಗಳನ್ನು ತಪ್ಪಿಸಿ.',
      malayalam: 'തല മുറിഞ്ഞതോ, മങ്ങിയതോ, ഗ്രൂപ്പ് ഫോട്ടോകളോ ഒഴിവാക്കുക.',
      marathi: 'डोके कापलेले, अस्पष्ट आणि ग्रुप फोटो टाळा.',
      gujarati: 'કપાયેલું માથું, અસ્પષ્ટ અને ગ્રૂપ ફોટા ટાળો.',
      bengali: 'মাথা কাটা, অস্পষ্ট এবং গ্রুপ ছবি এড়িয়ে চলুন।',
      punjabi: 'ਕੱਟਿਆ ਹੋਇਆ ਸਿਰ, ਧੁੰਦਲੀ ਅਤੇ ਸਮੂਹ ਫੋਟੋ ਤੋਂ ਬਚੋ।',
      odia: 'ମୁଣ୍ଡ କଟିଥିବା, ଅସ୍ପଷ୍ଟ ଏବଂ ଗ୍ରୁପ୍ ଫଟୋ ବାରଣ କରନ୍ତୁ।',
      assamese: 'মূৰ কটা, অস্পষ্ট আৰু গোটৰ ফটো এৰাই চলক।',
      konkani: 'ಮಸ್ತಕ್ ಕಾತ್ಲಲ್ಲೆಂ, ಅಸ್ಪಷ್ಟ್ ಆನಿ ಗ್ರೂಪ್ ಫೋಟೋ ನಕಾ.',
      nepali: 'टाउको काटिएको, धमिलो र समूह फोटोहरू नराख्नुहोस्।',
      meitei: 'মকোক ককপা, ময়েক শেংদবা অমসুং কাংলুপকী ফোতো থিংবীয়ু।',
      mizo: 'Lu bung, fiah lo leh thlalak hoinate chu hmang suh.',
      kashmiri: 'تَرٛاٹ کٔرِتھ کَلَہ، دُھنٛدلہٕ تہٕ گروپ فوٹو نِش پرہیز کٔریو۔',
      ladakhi: 'མགོ་བཅད་པ། མི་གསལ་བ། མི་མང་འདྲ་པར་རྣམས་སྤོངས།',
    );
    final goodLabel = strings.localized(
      telugu: 'ఇలా ఉండాలి',
      english: 'Use this type',
      hindi: 'इस प्रकार का उपयोग करें',
      tamil: 'இந்த வகையைப் பயன்படுத்தவும்',
      kannada: 'ಈ ಪ್ರಕಾರವನ್ನು ಬಳಸಿ',
      malayalam: 'ഇത്തരം ഉപയോഗിക്കുക',
      marathi: 'हा प्रकार वापरा',
      gujarati: 'આ પ્રકારનો ઉપયોગ કરો',
      bengali: 'এই ধরনের ব্যবহার করুন',
      punjabi: 'ਇਸ ਕਿਸਮ ਦੀ ਵਰਤੋਂ ਕਰੋ',
      odia: 'ଏହି ପ୍ରକାର ବ୍ୟବହାର କରନ୍ତୁ',
      assamese: 'এই ধৰণৰ ব্যৱহাৰ কৰক',
      konkani: 'ಹ್ಯಾ ನಮೂನ್ಯಾಚೆಂ ವಾಪರಾ',
      nepali: 'यो प्रकार प्रयोग गर्नुहोस्',
      meitei: 'মসিগী মখল অসি শীজিন্নউ',
      mizo: 'Hetiang chi hi hmang rawh',
      kashmiri: 'یِتھ قٕسمُک کٔریو اِستعمال',
      ladakhi: 'རིགས་འདི་སྤྱོད།',
    );
    final badLabel = strings.localized(
      telugu: 'ఇలా ఉండకూడదు',
      english: 'Avoid this type',
      hindi: 'इस प्रकार से बचें',
      tamil: 'இந்த வகையைத் தவிர்க்கவும்',
      kannada: 'ಈ ಪ್ರಕಾರವನ್ನು ತಪ್ಪಿಸಿ',
      malayalam: 'ഇത്തരം ഒഴിവാക്കുക',
      marathi: 'हा प्रकार टाळा',
      gujarati: 'આ પ્રકાર ટાળો',
      bengali: 'এই ধরনের এড়িয়ে চলুন',
      punjabi: 'ਇਸ ਕਿਸਮ ਤੋਂ ਬਚੋ',
      odia: 'ଏହି ପ୍ରକାର ବାରଣ କରନ୍ତୁ',
      assamese: 'এই ধৰণৰ এৰাই চলক',
      konkani: 'ಹ್ಯಾ ನಮೂನ್ಯಾಚೆಂ ನಕಾ',
      nepali: 'यो प्रकार नगर्नुहोस्',
      meitei: 'মসিগী মখল অসি থিংবীয়ু',
      mizo: 'Hetiang chi hi pumpelh rawh',
      kashmiri: 'یِتھ قٕسمہٕ نِش پرہیز کٔریو',
      ladakhi: 'རིགས་འདི་སྤོངས།',
    );
    final continueLabel = strings.localized(
      telugu: 'ఫోటో ఎంచుకోండి',
      english: 'Choose photo',
      hindi: 'फ़ोटो चुनें',
      tamil: 'புகைப்படத்தைத் தேர்ந்தெடுக்கவும்',
      kannada: 'ಫೋಟೋ ಆಯ್ಕೆಮಾಡಿ',
      malayalam: 'ഫോട്ടോ തിരഞ്ഞെടുക്കുക',
      marathi: 'फोटो निवडा',
      gujarati: 'ફોટો પસંદ કરો',
      bengali: 'ছবি নির্বাচন করুন',
      punjabi: 'ਫੋਟੋ ਚੁਣੋ',
      odia: 'ଫଟୋ ବାଛନ୍ତୁ',
      assamese: 'ফটো বাছক',
      konkani: 'ಫೋಟೋ ವಿಂಚಾ',
      nepali: 'फोटो छनोट गर्नुहोस्',
      meitei: 'ফোতো খনগৎলু',
      mizo: 'Thlalak thlang rawh',
      kashmiri: 'فوٹو ژٲریو',
      ladakhi: 'འདྲ་པར་འདེམས།',
    );

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.56,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _ProfilePhotoExampleTile(
                        label: goodLabel,
                        caption: guidance,
                        imageUrl: config.goodImage?.url ?? '',
                        missingText: strings.localized(
                          telugu: 'గైడ్ ఫోటో అప్‌లోడ్ కాలేదు',
                          english: 'Guide photo not uploaded',
                          hindi: 'मार्गदर्शक फ़ोटो अपलोड नहीं हुआ',
                          tamil: 'வழிகாட்டி புகைப்படம் பதிவேற்றப்படவில்லை',
                          kannada: 'ಮಾರ್ಗದರ್ಶಿ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಆಗಿಲ್ಲ',
                          malayalam: 'ഗൈഡ് ഫോട്ടോ അപ്‌ലോഡ് ചെയ്തിട്ടില്ല',
                          marathi: 'मार्गदर्शक फोटो अपलोड झाला नाही',
                          gujarati: 'માર્ગદર્શક ફોટો અપલોડ થયો નથી',
                          bengali: 'গাইড ছবি আপলোড করা হয়নি',
                          punjabi: 'ਗਾਈਡ ਫੋਟੋ ਅੱਪਲੋਡ ਨਹੀਂ ਹੋਈ',
                          odia: 'ଗାଇଡ୍ ଫଟୋ ଅପଲୋଡ୍ ହୋଇନାହିଁ',
                          assamese: 'গাইড ফটো আপলোড হোৱা নাই',
                          konkani: 'ಮಾರ್ಗದರ್ಶಿ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಜಾಂವ್ಕ್ ನಾ',
                          nepali: 'मार्गदर्शक फोटो अपलोड भएन',
                          meitei: 'লমজিং ফোতো অপলোদ তৌদ্রে',
                          mizo: 'Entirna thlalak upload a ni lo',
                          kashmiri: 'گائیڈ فوٹو گۆو نہٕ اَپلوڈ',
                          ladakhi: 'ལམ་སྟོན་འདྲ་པར་ཡར་འཇུག་མ་བྱས།',
                        ),
                        good: true,
                        loading: loading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfilePhotoExampleTile(
                        label: badLabel,
                        caption: avoid,
                        imageUrl: config.badImage?.url ?? '',
                        missingText: strings.localized(
                          telugu: 'గైడ్ ఫోటో అప్‌లోడ్ కాలేదు',
                          english: 'Guide photo not uploaded',
                          hindi: 'मार्गदर्शक फ़ोटो अपलोड नहीं हुआ',
                          tamil: 'வழிகாட்டி புகைப்படம் பதிவேற்றப்படவில்லை',
                          kannada: 'ಮಾರ್ಗದರ್ಶಿ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಆಗಿಲ್ಲ',
                          malayalam: 'ഗൈഡ് ഫോട്ടോ അപ്‌ലോഡ് ചെയ്തിട്ടില്ല',
                          marathi: 'मार्गदर्शक फोटो अपलोड झाला नाही',
                          gujarati: 'માર્ગદર્શક ફોટો અપલોડ થયો નથી',
                          bengali: 'গাইড ছবি আপলোড করা হয়নি',
                          punjabi: 'ਗਾਈਡ ਫੋਟੋ ਅੱਪਲੋਡ ਨਹੀਂ ਹੋਈ',
                          odia: 'ଗାଇଡ୍ ଫଟୋ ଅପଲୋଡ୍ ହୋଇନାହିଁ',
                          assamese: 'গাইড ফটো আপলোড হোৱা নাই',
                          konkani: 'ಮಾರ್ಗದರ್ಶಿ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಜಾಂವ್ಕ್ ನಾ',
                          nepali: 'मार्गदर्शक फोटो अपलोड भएन',
                          meitei: 'লমজিং ফোতো অপলোদ তৌদ্রে',
                          mizo: 'Entirna thlalak upload a ni lo',
                          kashmiri: 'گائیڈ فوٹو گۆو نہٕ اَپلوڈ',
                          ladakhi: 'ལམ་སྟོན་འདྲ་པར་ཡར་འཇུག་མ་བྱས།',
                        ),
                        good: false,
                        loading: loading,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(
                    continueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoExampleTile extends StatelessWidget {
  const _ProfilePhotoExampleTile({
    required this.label,
    required this.caption,
    required this.imageUrl,
    required this.missingText,
    required this.good,
    required this.loading,
  });

  final String label;
  final String caption;
  final String imageUrl;
  final String missingText;
  final bool good;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final accent = good ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon = good ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final hasImage = imageUrl.trim().isNotEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (loading)
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                else if (hasImage)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    errorWidget: (context, url, error) =>
                        _ProfilePhotoGuideMissing(message: missingText),
                  )
                else
                  _ProfilePhotoGuideMissing(message: missingText),
                if (!good && hasImage)
                  ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: accent, size: 25),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoGuideMissing extends StatelessWidget {
  const _ProfilePhotoGuideMissing({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _IdentityPreviewCard extends StatelessWidget {
  const _IdentityPreviewCard({
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onVisualTap,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onVisualTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: busy ? null : onVisualTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: child,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: busy
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6D28D9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          if (subtitle.trim().isNotEmpty)
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                height: 1.25,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _CleanInputField extends StatelessWidget {
  const _CleanInputField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 1.4),
        ),
      ),
    );
  }
}

class _ProfilePhotoStyleSegmentedSwitch extends StatelessWidget {
  const _ProfilePhotoStyleSegmentedSwitch({
    required this.isOriginal,
    required this.hasOriginal,
    required this.onStyleChanged,
    required this.onOriginalUnavailable,
  });

  final bool isOriginal;
  final bool hasOriginal;
  final ValueChanged<bool> onStyleChanged;
  final VoidCallback onOriginalUnavailable;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final effectiveIsOriginal = hasOriginal && isOriginal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refined Title Row with glowing badge
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 11,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(width: 6),
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
                konkani: 'ಫೋಟೋ ಪ್ರಕಾರ ವಿಂಚಾ',
                nepali: 'फोटो शैली छान्नुहोस्',
                meitei: 'ফোতো শৈলী খনগৎলু',
                mizo: 'Thlalak style thlang rawh',
                kashmiri: 'فوٹو انداز ژٲریو',
                ladakhi: 'པར་གྱི་བཟོ་རྣམ་འདེམས།',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Modern Segmented Control with Smooth Sliding Thumb
        Container(
          width: 250,
          height: 44,
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155), width: 1.2),
          ),
          child: Stack(
            children: [
              // Sliding Animated Thumb with Rich Brand Gradient
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: effectiveIsOriginal
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Interactive Segment Row
              Row(
                children: [
                  // Cutout Segment
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onStyleChanged(false);
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              size: 15,
                              color: !effectiveIsOriginal
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              strings.localized(
                                telugu: 'కటౌట్',
                                english: 'Cutout',
                                hindi: 'कटआउट',
                                tamil: 'கட்அவுட்',
                                kannada: 'ಕಟೌಟ್',
                                malayalam: 'കട്ടൗട്ട്',
                                marathi: 'कटआउट',
                                gujarati: 'કટઆઉટ',
                                bengali: 'কাটআউট',
                                punjabi: 'ਕੱਟਆਊਟ',
                                odia: 'କଟ୍‌ଆଉଟ୍',
                                assamese: 'কাটআউট',
                                konkani: 'ಕಟೌಟ್',
                                nepali: 'कटआउट',
                                meitei: 'কতআউত',
                                mizo: 'Cutout',
                                kashmiri: 'کٹ آوُٹ',
                                ladakhi: 'དྲ་བཅད་རྣམ་པ།',
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !effectiveIsOriginal
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: !effectiveIsOriginal
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Original Segment
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (!hasOriginal) {
                          HapticFeedback.lightImpact();
                          onOriginalUnavailable();
                          return;
                        }
                        HapticFeedback.selectionClick();
                        onStyleChanged(true);
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasOriginal
                                  ? Icons.portrait_rounded
                                  : Icons.lock_outline_rounded,
                              size: 15,
                              color: hasOriginal
                                  ? (effectiveIsOriginal
                                        ? Colors.white
                                        : const Color(0xFF94A3B8))
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              strings.localized(
                                telugu: 'ఒరిజినల్',
                                english: 'Original',
                                hindi: 'मूल',
                                tamil: 'அசல்',
                                kannada: 'ಮೂಲ',
                                malayalam: 'യഥാർത്ഥം',
                                marathi: 'मूळ',
                                gujarati: 'ઓરિજિનલ',
                                bengali: 'আসল',
                                punjabi: 'ਅਸਲ',
                                odia: 'ମୂଳ',
                                assamese: 'আচল',
                                konkani: 'ಮೂಳ್',
                                nepali: 'मौलिक',
                                meitei: 'অশেংবা',
                                mizo: 'A nihna tak',
                                kashmiri: 'اصلی',
                                ladakhi: 'ངོ་མ།',
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: effectiveIsOriginal
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: hasOriginal
                                    ? (effectiveIsOriginal
                                          ? Colors.white
                                          : const Color(0xFF94A3B8))
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Explanatory Micro Hint
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            effectiveIsOriginal
                ? strings.localized(
                    telugu:
                        'పోస్టర్‌పై పూర్తి ఫోటో గుండ్రని ఫ్రేమ్‌లో కనిపిస్తుంది',
                    english: 'Full photo in round frame on poster',
                    hindi: 'पोस्टर पर गोल फ़्रेम में पूरी फ़ोटो दिखेगी',
                    tamil: 'போஸ்டரில் வட்ட சட்டத்தில் முழு புகைப்படம் தெரியும்',
                    kannada:
                        'ಪೋಸ್ಟರ್‌ನಲ್ಲಿ ದುಂಡಗಿನ ಫ್ರೇಮ್‌ನಲ್ಲಿ ಪೂರ್ಣ ಫೋಟೋ ಕಾಣಿಸುತ್ತದೆ',
                    malayalam:
                        'പോസ്റ്ററിൽ വൃത്താകൃതിയിലുള്ള ഫ്രെയിമിൽ ഫോട്ടോ ദൃശ്യമാകും',
                    marathi: 'पोस्टरवर गोल फ्रेममध्ये पूर्ण फोटो दिसेल',
                    gujarati: 'પોસ્ટર પર ગોળાકાર ફ્રેમમાં સંપૂર્ણ ફોટો દેખાશે',
                    bengali: 'পোস্টারে গোল ফ্রেমে সম্পূর্ণ ছবি দেখা যাবে',
                    punjabi: 'ਪੋਸਟਰ ਤੇ ਗੋਲ ਫਰੇਮ ਵਿੱਚ ਪੂਰੀ ਫੋਟੋ ਦਿਖੇਗੀ',
                    odia: 'ପୋଷ୍ଟରରେ ଗୋଲାକାର ଫ୍ରେମରେ ସମ୍ପୂର୍ଣ୍ଣ ଫଟୋ ଦେଖାଯିବ',
                    assamese: 'পোষ্টাৰত ঘূৰণীয়া ফ্ৰেমত সম্পূৰ্ণ ফটো দেখা যাব',
                    konkani: 'ಪೋಸ್ಟರಾರ್ ಗೋಲ್ ಫ್ರೇಮಾಂತ್ ಪೂರ್ಣ್ ಫೋಟೋ ದಿಸ್ತಲಿ',
                    nepali: 'पोस्टरमा गोलो फ्रेममा पूरै तस्बिर देखिनेछ',
                    meitei: 'পোস্তরদা বোইবা ফ্রেমদা অপুনবা ফোতো উবা ফংগনি',
                    mizo:
                        'Poster-ah bial khung chhungah a nihna ang takin a lang ang',
                    kashmiri:
                        'پوسٹرس پؠٹھ گول فریمَس مَنٛز کٔریو مکمل فوٹو ظٲہِر',
                    ladakhi: 'སྦྱར་ཡིག་ཐོག་སྒོར་མོའི་པར་སྒྲོམ་ནང་པར་ཆົບསྟོན།',
                  )
                : strings.localized(
                    telugu:
                        'పోస్టర్‌పై బ్యాక్‌గ్రౌండ్ తొలగించిన కటౌట్ కనిపిస్తుంది',
                    english: 'Clean cutout without background on poster',
                    hindi: 'पोस्टर पर बिना बैकग्राउंड वाला कटआउट दिखेगा',
                    tamil: 'போஸ்டரில் பின்னணி நீக்கப்பட்ட கட்அவுட் தெரியும்',
                    kannada: 'ಪೋಸ್ಟರ್‌ನಲ್ಲಿ ಹಿನ್ನೆಲೆ ತೆಗೆದ ಕಟೌಟ್ ಕಾಣಿಸುತ್ತದೆ',
                    malayalam:
                        'പോസ്റ്ററിൽ പശ്ചാത്തലം നീക്കം ചെയ്ത കട്ടൗട്ട് ദൃശ്യമാകും',
                    marathi: 'पोस्टरवर बॅकग्राउंड काढलेला कटआउट दिसेल',
                    gujarati: 'પોસ્ટર પર બેકગ્રાઉન્ડ હટાવેલ કટઆઉટ દેખાશે',
                    bengali: 'পোস্টারে ব্যাকগ্রাউন্ড ছাড়া কাটআউট দেখা যাবে',
                    punjabi: 'ਪੋਸਟਰ ਤੇ ਬਿਨਾਂ ਬੈਕਗ੍ਰਾਊਂਡ ਵਾਲਾ ਕੱਟਆਊਟ ਦਿਖੇਗਾ',
                    odia: 'ପୋଷ୍ଟରରେ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ ହଟିଥିବା କଟ୍‌ଆଉଟ୍ ଦେଖାଯିବ',
                    assamese: 'পোষ্টাৰত পটভূমি নোহোৱা কাটআউট দেখা যাব',
                    konkani: 'ಪೋಸ್ಟರಾರ್ ಪಾಟ್ಲೊ ಆಂಗಣ್ ಕಾಡ್ಲೆಲೆಂ ಕಟೌಟ್ ದಿಸ್ತಲೆಂ',
                    nepali: 'पोस्टरमा पृष्ठभूमि हटाइएको कटआउट देखिनेछ',
                    meitei: 'পোস্তরদা বেকগ্রাউন্দ লৌথোক্লবা কতআউত উবা ফংগনি',
                    mizo: 'Poster-ah a hnung zawk tel loin cutout a lang ang',
                    kashmiri:
                        'پوسٹرس پؠٹھ کٔریو بیک گراوُنڈ بغیر کٹ آوُٹ ظٲہِر',
                    ladakhi: 'སྦྱར་ཡིག་ཐོག་རྒྱབ་ལྗོངས་མེད་པའི་དྲ་བཅད་པར་སྟོན།',
                  ),
            key: ValueKey<bool>(effectiveIsOriginal),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
