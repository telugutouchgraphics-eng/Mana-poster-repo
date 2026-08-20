import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/prehome/screens/my_downloads_screen.dart';
import 'package:mana_poster/features/prehome/screens/user_poster_uploads_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/onboarding_audio_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/onboarding_surface_card.dart';
import 'package:mana_poster/features/prehome/widgets/poster_identity_visual.dart';

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
    this.openMyUploads,
    this.onSaved,
  });

  final PosterProfileData initialProfile;
  final String accountEmail;
  final String accountSubtitle;
  final bool completeToHomeOnSave;
  final bool openPersonalPhotoPickerOnStart;
  final bool embeddedInProfileScreen;
  final List<Widget> appBarActions;
  final Future<void> Function(BuildContext context)? openMyUploads;
  final ValueChanged<PosterProfileData>? onSaved;

  @override
  State<PosterProfileDetailsScreen> createState() =>
      _PosterProfileDetailsScreenState();
}

class _PosterProfileDetailsScreenState
    extends State<PosterProfileDetailsScreen> {
  static const OfflineBackgroundRemovalService _backgroundRemovalService =
      OfflineBackgroundRemovalService();
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
    if (widget.openPersonalPhotoPickerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_pickPersonalPhoto());
        }
      });
    }
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
    _languageController?.removeListener(_handleLanguageChanged);
    unawaited(_onboardingAudio.dispose());
    super.dispose();
  }

  Future<void> _ensureBackgroundRemoverReady() {
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

  Future<void> _pickPersonalPhoto() async {
    if (_personalPhotoBusy || _pickerBusy) {
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
      final personalPhotoRevision = DateTime.now().millisecondsSinceEpoch;
      final finalPhotoBytes = await _removePersonalPhotoBackground(
        optimizedOriginalBytes,
      );
      if (finalPhotoBytes == null) {
        throw StateError('Personal photo background removal failed');
      }
      final Directory dir = await getApplicationDocumentsDirectory();
      final String stamp = personalPhotoRevision.toString();
      final String originalTargetPath =
          '${dir.path}${Platform.pathSeparator}poster_profile_original_photo_$stamp.png';
      final String cutoutTargetPath =
          '${dir.path}${Platform.pathSeparator}poster_profile_photo_$stamp.png';
      final File originalLocalFile = File(originalTargetPath);
      final File cutoutLocalFile = File(cutoutTargetPath);
      await originalLocalFile.writeAsBytes(optimizedOriginalBytes, flush: true);
      await cutoutLocalFile.writeAsBytes(finalPhotoBytes, flush: true);
      final Set<String> keepNewPersonalAssets = <String>{
        originalTargetPath,
        cutoutTargetPath,
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
        photoPath: cutoutTargetPath,
        photoUrl: '',
        originalPhotoPath: originalTargetPath,
        originalPhotoUrl: '',
        personalPhotoRevision: personalPhotoRevision,
      );
      try {
        await PosterProfileService.savePersonalPhotoAssets(
          photoPath: updatedLocalProfile.photoPath,
          originalPhotoPath: updatedLocalProfile.originalPhotoPath,
          photoUrl: '',
          originalPhotoUrl: '',
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
      }
      unawaited(
        _syncPersonalPhotoUploads(
          baseProfile: updatedLocalProfile,
          originalLocalFile: originalLocalFile,
          cutoutLocalFile: cutoutLocalFile,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu: 'వ్యక్తిగత ఫోటో అప్‌డేట్ కాలేదు',
              english: 'Personal photo update failed',
              hindi: 'पर्सनल फोटो अपडेट नहीं हुआ',
              tamil: 'தனிப்பட்ட புகைப்படம் அப்டேட் ஆகவில்லை',
              kannada: 'ಪರ್ಸನಲ್ ಫೋಟೋ ಅಪ್ಡೇಟ್ ಆಗಲಿಲ್ಲ',
              malayalam: 'സ്വകാര്യ ഫോട്ടോ അപ്‌ഡേറ്റ് ചെയ്തില്ല',
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
      debugPrint('Profile photo cloud sync failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<Uint8List?> _removePersonalPhotoBackground(
    Uint8List optimizedOriginalBytes,
  ) async {
    Future<Uint8List?> attempt(Uint8List sourceBytes, Duration timeout) async {
      await _ensureBackgroundRemoverReady();
      final removedResult = await _backgroundRemovalService
          .removeBackground(sourceBytes)
          .timeout(timeout);
      return removedResult.pngBytes;
    }

    try {
      return await attempt(optimizedOriginalBytes, const Duration(seconds: 30));
    } catch (_) {
      try {
        final smallerBytes = await compute(
          _prepareProfilePhotoRemovalBytes,
          optimizedOriginalBytes,
        );
        return await attempt(smallerBytes, const Duration(seconds: 30));
      } catch (_) {
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
              hindi: 'बिजनेस लोगो अपडेट नहीं हुआ',
              tamil: 'பிஸினஸ் லோகோ அப்டேட் ஆகவில்லை',
              kannada: 'ಬಿಸಿನೆಸ್ ಲೋಗೋ ಅಪ್ಡೇಟ್ ಆಗಲಿಲ್ಲ',
              malayalam: 'ബിസിനസ് ലോഗോ അപ്‌ഡേറ്റ് ചെയ്തില്ല',
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
                hindi: 'प्रोफ़ाइल सेव हो गई',
                tamil: 'ப்ரொஃபைல் சேமிக்கப்பட்டது',
                kannada: 'ಪ್ರೊಫೈಲ್ ಸೇವ್ ಆಯಿತು',
                malayalam: 'പ്രൊഫൈൽ സേവ് ചെയ്തു',
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
              hindi: 'प्रोफ़ाइल विवरण सेव नहीं हुए',
              tamil: 'ப்ரொஃபைல் விவரங்களை சேமிக்க முடியவில்லை',
              kannada: 'ಪ್ರೊಫೈಲ್ ವಿವರಗಳನ್ನು ಸೇವ್ ಮಾಡಲಾಗಲಿಲ್ಲ',
              malayalam: 'പ്രൊഫൈൽ വിവരങ്ങൾ സേവ് ചെയ്യാനായില്ല',
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
        automaticallyImplyLeading: !widget.embeddedInProfileScreen,
        iconTheme: IconThemeData(
          color: minimalSetup ? cs.onSurface : const Color(0xFF0F172A),
        ),
        title: Text(
          strings.localized(
            telugu: 'పోస్టర్ ప్రొఫైల్',
            english: 'Poster Profile',
            hindi: 'पोस्टर प्रोफ़ाइल',
            tamil: 'போஸ்டர் ப்ரொஃபைல்',
            kannada: 'ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್',
            malayalam: 'പോസ്റ്റർ പ്രൊഫൈൽ',
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
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          final openMyUploads = widget.openMyUploads;
                          if (openMyUploads != null) {
                            unawaited(openMyUploads(context));
                            return;
                          }
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const UserPosterUploadsScreen(
                                profileOnly: true,
                              ),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFF99F6E4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    strings.localized(
                      telugu: 'నా అప్‌లోడ్లు',
                      english: 'My Uploads',
                      hindi: 'मेरे अपलोड',
                      tamil: 'எனது அப்லோட்கள்',
                      kannada: 'ನನ್ನ ಅಪ್‌ಲೋಡ್‌ಗಳು',
                      malayalam: 'എന്റെ അപ്‌ലോഡുകൾ',
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
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: GradientShell(
        child: ListView(
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
                            hindi: 'पर्सनल',
                            tamil: 'பர்சனல்',
                            kannada: 'ಪರ್ಸನಲ್',
                            malayalam: 'പേഴ്സണൽ',
                          ),
                        ),
                      ),
                      ButtonSegment<PosterIdentityMode>(
                        value: PosterIdentityMode.business,
                        label: Text(
                          strings.localized(
                            telugu: 'వ్యాపారం',
                            english: 'Business',
                            hindi: 'बिजनेस',
                            tamil: 'பிஸினஸ்',
                            kannada: 'ಬಿಸಿನೆಸ್',
                            malayalam: 'ബിസിനസ്',
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
                            hindi: 'बिजनेस प्रीव्यू',
                            tamil: 'பிஸினஸ் முன்னோட்டம்',
                            kannada: 'ಬಿಸಿನೆಸ್ ಪ್ರಿವ್ಯೂ',
                            malayalam: 'ബിസിനസ് പ്രിവ്യൂ',
                          )
                        : strings.localized(
                            telugu: 'ప్రొఫైల్ ప్రివ్యూ',
                            english: 'Profile preview',
                            hindi: 'प्रोफ़ाइल प्रीव्यू',
                            tamil: 'ப்ரொஃபைல் முன்னோட்டம்',
                            kannada: 'ಪ್ರೊಫೈಲ್ ಪ್ರಿವ್ಯೂ',
                            malayalam: 'പ്രൊഫൈൽ പ്രിവ്യൂ',
                          ),
                    subtitle: isBusiness
                        ? strings.localized(
                            telugu: 'లోగో మార్చండి',
                            english: 'Change logo',
                            hindi: 'बिजनेस नाम और लोगो पोस्टरों पर लागू होंगे।',
                            tamil:
                                'பிஸினஸ் பெயரும் லோகோவும் போஸ்டர்களில் பயன்படுத்தப்படும்.',
                            kannada:
                                'ಬಿಸಿನೆಸ್ ಹೆಸರು ಮತ್ತು ಲೋಗೋ ಪೋಸ್ಟರ್‌ಗಳಲ್ಲಿ ಅನ್ವಯವಾಗುತ್ತವೆ.',
                            malayalam:
                                'ബിസിനസ് പേരും ലോഗോയും പോസ്റ്ററുകളിൽ പ്രയോഗിക്കും.',
                          )
                        : strings.localized(
                            telugu: 'ఫోటో మార్చండి',
                            english: 'Change photo',
                            hindi:
                                'यूज़र फोटो और विवरण पोस्टरों पर लागू होंगे।',
                            tamil:
                                'யூசர் புகைப்படமும் விவரங்களும் போஸ்டர்களில் பயன்படுத்தப்படும்.',
                            kannada:
                                'ಯೂಸರ್ ಫೋಟೋ ಮತ್ತು ವಿವರಗಳು ಪೋಸ್ಟರ್‌ಗಳಲ್ಲಿ ಅನ್ವಯವಾಗುತ್ತವೆ.',
                            malayalam:
                                'യൂസർ ഫോട്ടോയും വിവരങ്ങളും പോസ്റ്ററുകളിൽ പ്രയോഗിക്കും.',
                          ),
                    busy: isBusiness ? _businessLogoBusy : _personalPhotoBusy,
                    onVisualTap: isBusiness
                        ? _pickBusinessLogo
                        : _pickPersonalPhoto,
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
                          preferOriginalPersonalPhoto: false,
                          allowOriginalFallbackWhenCutoutUnavailable:
                              isBusiness,
                          textScale: 1.18,
                        ),
                      ),
                    ),
                  ),
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
                            hindi: 'वॉइस गाइड फिर सुनें',
                            tamil: 'வாய்ஸ் கையேட்டை மீண்டும் கேளுங்கள்',
                            kannada: 'ವಾಯ್ಸ್ ಗೈಡ್ ಮತ್ತೆ ಕೇಳಿ',
                            malayalam: 'വോയ്സ് ഗൈഡ് വീണ്ടും കേൾക്കുക',
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
                        hindi: 'पर्सनल विवरण',
                        tamil: 'பர்சனல் விவரங்கள்',
                        kannada: 'ಪರ್ಸನಲ್ ವಿವರಗಳು',
                        malayalam: 'പേഴ്സണൽ വിവരങ്ങൾ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CleanInputField(
                      controller: _nameController,
                      label: strings.localized(
                        telugu: 'పేరు',
                        english: 'Display Name',
                        hindi: 'डिस्प्ले नेम',
                        tamil: 'டிஸ்ப்ளே பெயர்',
                        kannada: 'ಡಿಸ್ಪ್ಲೇ ಹೆಸರು',
                        malayalam: 'ഡിസ്‌പ്ലേ പേര്',
                      ),
                      hintText: strings.localized(
                        telugu: 'మీ పేరు నమోదు చేయండి',
                        english: 'Enter your name',
                        hindi: 'अपना नाम दर्ज करें',
                        tamil: 'உங்கள் பெயரை உள்ளிடவும்',
                        kannada: 'ನಿಮ್ಮ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
                        malayalam: 'നിങ്ങളുടെ പേര് നൽകുക',
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
                        hindi: 'व्हाट्सऐप नंबर',
                        tamil: 'வாட்ஸ்அப் எண்',
                        kannada: 'ವಾಟ್ಸಾಪ್ ನಂಬರ್',
                        malayalam: 'വാട്ട്‌സ്ആപ്പ് നമ്പർ',
                      ),
                      hintText: strings.localized(
                        telugu: 'మీ హోదా నమోదు చేయండి',
                        english: 'Enter your designation',
                        hindi: '10 अंकों का नंबर',
                        tamil: '10 இலக்க எண்',
                        kannada: '10 ಅಂಕೆಯ ಸಂಖ್ಯೆ',
                        malayalam: '10 അക്ക നമ്പർ',
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
                        hindi: 'बिजनेस विवरण',
                        tamil: 'பிஸினஸ் விவரங்கள்',
                        kannada: 'ಬಿಸಿನೆಸ್ ವಿವರಗಳು',
                        malayalam: 'ബിസിനസ് വിവരങ്ങൾ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CleanInputField(
                      controller: _businessNameController,
                      label: strings.localized(
                        telugu: 'వ్యాపార పేరు',
                        english: 'Business Name',
                        hindi: 'बिजनेस नाम',
                        tamil: 'பிஸினஸ் பெயர்',
                        kannada: 'ಬಿಸಿನೆಸ್ ಹೆಸರು',
                        malayalam: 'ബിസിനസ് പേര്',
                      ),
                      hintText: strings.localized(
                        telugu: 'వ్యాపార పేరు నమోదు చేయండి',
                        english: 'Enter business name',
                        hindi: 'बिजनेस नाम दर्ज करें',
                        tamil: 'பிஸினஸ் பெயரை உள்ளிடவும்',
                        kannada: 'ಬಿಸಿನೆಸ್ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
                        malayalam: 'ബിസിനസ് പേര് നൽകുക',
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
                        hindi: 'बिजनेस टैगलाइन',
                        tamil: 'பிஸினஸ் டேக் லைன்',
                        kannada: 'ಬಿಸಿನೆಸ್ ಟ್ಯಾಗ್‌ಲೈನ್',
                        malayalam: 'ബിസിനസ് ടാഗ്‌ലൈൻ',
                      ),
                      hintText: strings.localized(
                        telugu: 'ఐచ్ఛిక చిన్న వాక్యం',
                        english: 'Optional short line',
                        hindi: 'वैकल्पिक छोटी पंक्ति',
                        tamil: 'விருப்பமான குறும் வரி',
                        kannada: 'ಐಚ್ಛಿಕ ಚಿಕ್ಕ ಸಾಲು',
                        malayalam: 'ഓപ്ഷണൽ ചെറിയ വരി',
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
                        hindi: 'बिजनेस व्हाट्सऐप नंबर',
                        tamil: 'பிஸினஸ் வாட்ஸ்அப் எண்',
                        kannada: 'ಬಿಸಿನೆಸ್ ವಾಟ್ಸಾಪ್ ನಂಬರ್',
                        malayalam: 'ബിസിനസ് വാട്ട്‌സ്ആപ്പ് നമ്പർ',
                      ),
                      hintText: strings.localized(
                        telugu: '10 అంకెల నంబర్',
                        english: '10-digit number',
                        hindi: '10 अंकों का नंबर',
                        tamil: '10 இலக்க எண்',
                        kannada: '10 ಅಂಕೆಯ ಸಂಖ್ಯೆ',
                        malayalam: '10 അക്ക നമ്പർ',
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
                        hindi: 'क्रिएटिव लोगो बनाएं',
                        tamil: 'கிரியேட்டிவ் லோகோ உருவாக்கவும்',
                        kannada: 'ಕ್ರಿಯೇಟಿವ್ ಲೋಗೋ ತಯಾರಿಸಿ',
                        malayalam: 'ക്രിയേറ്റീവ് ലോഗോ സൃഷ്ടിക്കുക',
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
                                    hindi: 'मना बिजनेस',
                                    tamil: 'மனா பிஸினஸ்',
                                    kannada: 'ಮನ ಬಿಸಿನೆಸ್',
                                    malayalam: 'മന ബിസിനസ്',
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
                                      hindi: 'स्टाइल ${index + 1}',
                                      tamil: 'ஸ்டைல் ${index + 1}',
                                      kannada: 'ಸ್ಟೈಲ್ ${index + 1}',
                                      malayalam: 'സ്റ്റൈൽ ${index + 1}',
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
