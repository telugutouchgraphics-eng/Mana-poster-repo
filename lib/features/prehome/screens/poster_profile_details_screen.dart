import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_background_remover/image_background_remover.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/widgets/poster_identity_visual.dart';

class PosterProfileDetailsScreen extends StatefulWidget {
  const PosterProfileDetailsScreen({super.key, required this.initialProfile});

  final PosterProfileData initialProfile;

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
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessTaglineController;
  late final TextEditingController _businessWhatsappController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _saving = false;
  bool _personalPhotoBusy = false;
  bool _businessLogoBusy = false;
  late final Future<void> _backgroundRemoverInitialization;
  AppLanguageController? _languageController;

  @override
  void initState() {
    super.initState();
    _draftProfile = widget.initialProfile;
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
    _backgroundRemoverInitialization = BackgroundRemover.instance
        .initializeOrt();
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
    unawaited(BackgroundRemover.instance.dispose());
    super.dispose();
  }

  Future<void> _pickPersonalPhoto() async {
    if (_personalPhotoBusy) {
      return;
    }
    final strings = context.strings;
    setState(() => _personalPhotoBusy = true);
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );
      if (picked == null) {
        return;
      }
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 92,
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
      await _backgroundRemoverInitialization;
      final originalBytes = await File(cropped.path).readAsBytes();
      final removedResult = await _backgroundRemovalService.removeBackground(
        originalBytes,
      );
      final Directory dir = await getApplicationDocumentsDirectory();
      final String originalTargetPath =
          '${dir.path}${Platform.pathSeparator}poster_profile_original_photo.png';
      final File originalLocalFile = File(originalTargetPath);
      await originalLocalFile.writeAsBytes(originalBytes, flush: true);
      final String targetPath =
          '${dir.path}${Platform.pathSeparator}poster_profile_photo.png';
      final File localFile = File(targetPath);
      await localFile.writeAsBytes(removedResult.pngBytes, flush: true);
      final originalRemoteUrl = await PosterProfileService.uploadProfilePhoto(
        file: originalLocalFile,
        extension: 'png',
        isOriginal: true,
      );
      final remoteUrl = await PosterProfileService.uploadProfilePhoto(
        file: localFile,
        extension: 'png',
      );
      setState(() {
        _draftProfile = _draftProfile.copyWith(
          photoPath: targetPath,
          photoUrl: remoteUrl.isEmpty ? _draftProfile.photoUrl : remoteUrl,
          originalPhotoPath: originalTargetPath,
          originalPhotoUrl: originalRemoteUrl.isEmpty
              ? _draftProfile.originalPhotoUrl
              : originalRemoteUrl,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.localized(
              telugu: 'Personal photo update fail ayindi',
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
      if (mounted) {
        setState(() => _personalPhotoBusy = false);
      }
    }
  }

  Future<void> _pickBusinessLogo() async {
    if (_businessLogoBusy) {
      return;
    }
    final strings = context.strings;
    setState(() => _businessLogoBusy = true);
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 94,
      );
      if (picked == null) {
        return;
      }
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 94,
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
      final String targetPath =
          '${dir.path}${Platform.pathSeparator}poster_business_logo.png';
      final File localFile = File(targetPath);
      await localFile.writeAsBytes(logoBytes, flush: true);
      final remoteUrl = await PosterProfileService.uploadBusinessLogo(
        file: localFile,
        extension: 'png',
      );
      setState(() {
        _draftProfile = _draftProfile.copyWith(
          businessLogoPath: targetPath,
          businessLogoUrl: remoteUrl.isEmpty
              ? _draftProfile.businessLogoUrl
              : remoteUrl,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.localized(
              telugu: 'Business logo update fail ayindi',
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
      if (mounted) {
        setState(() => _businessLogoBusy = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) {
      return;
    }
    final updated = _draftProfile.copyWith(
      identityMode: _draftProfile.identityMode,
      nameTelugu: PosterProfileService.splitDisplayName(
        _nameController.text.trim(),
      ).$1,
      nameEnglish: PosterProfileService.splitDisplayName(
        _nameController.text.trim(),
      ).$2,
      whatsappNumber: _onlyDigits(_whatsappController.text),
      businessName: _businessNameController.text.trim(),
      businessTagline: _businessTaglineController.text.trim(),
      businessWhatsappNumber: _onlyDigits(_businessWhatsappController.text),
    );
    setState(() => _saving = true);
    try {
      await PosterProfileService.save(updated);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Profile details save kaaledu',
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

  @override
  Widget build(BuildContext context) {
    final isBusiness =
        _draftProfile.identityMode == PosterIdentityMode.business;
    final strings = context.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          strings.localized(
            telugu: 'Poster Profile',
            english: 'Poster Profile',
            hindi: 'पोस्टर प्रोफ़ाइल',
            tamil: 'போஸ்டர் ப்ரொஃபைல்',
            kannada: 'ಪೋಸ್ಟರ್ ಪ್ರೊಫೈಲ್',
            malayalam: 'പോസ്റ്റർ പ്രൊഫൈൽ',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _saveProfile,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6D28D9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _saving
                  ? strings.localized(
                      telugu: 'Saving...',
                      english: 'Saving...',
                      hindi: 'सेव हो रहा है...',
                      tamil: 'சேமிக்கப்படுகிறது...',
                      kannada: 'ಸೇವ್ ಆಗುತ್ತಿದೆ...',
                      malayalam: 'സേവ് ചെയ്യുന്നു...',
                    )
                  : strings.localized(
                      telugu: 'Save Changes',
                      english: 'Save Changes',
                      hindi: 'बदलाव सेव करें',
                      tamil: 'மாற்றங்களை சேமிக்கவும்',
                      kannada: 'ಬದಲಾವಣೆಗಳನ್ನು ಸೇವ್ ಮಾಡಿ',
                      malayalam: 'മാറ്റങ്ങൾ സേവ് ചെയ്യുക',
                    ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          Text(
            strings.localized(
              telugu: 'Mee poster identity ela kanipinchalo select cheyyandi.',
              english: 'Choose how your poster identity should appear.',
              hindi: 'पोस्टर पर आपकी पहचान कैसे दिखनी चाहिए, चुनें।',
              tamil:
                  'உங்கள் போஸ்டர் அடையாளம் எப்படி தோன்ற வேண்டும் என்பதை தேர்வு செய்யவும்.',
              kannada: 'ನಿಮ್ಮ ಪೋಸ್ಟರ್ ಗುರುತು ಹೇಗೆ ಕಾಣಬೇಕು ಎಂದು ಆಯ್ಕೆಮಾಡಿ.',
              malayalam:
                  'നിങ്ങളുടെ പോസ്റ്റർ ഐഡന്റിറ്റി എങ്ങനെ കാണണം എന്ന് തിരഞ്ഞെടുക്കുക.',
            ),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF5F3FF)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE9E5FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_emotions_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.localized(
                          telugu: 'Simple ga set cheyyandi.',
                          english: 'Keep it simple.',
                          hindi: 'इसे सरल रखें।',
                          tamil: 'எளிமையாக வைத்துக்கொள்ளுங்கள்.',
                          kannada: 'ಸರಳವಾಗಿ ಇಡಿ.',
                          malayalam: 'ലളിതമായി സൂക്ഷിക്കുക.',
                        ),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.localized(
                          telugu:
                              'Personal ki photo, Business ki logo. Ippude preview చూసి వెంటనే మార్చుకోండి.',
                          english:
                              'Use photo for Personal and logo for Business. Preview first, then edit.',
                          hindi:
                              'Personal के लिए photo और Business के लिए logo. Preview देखकर तुरंत बदलें.',
                          tamil:
                              'Personal-க்கு photo, Business-க்கு logo. Preview பார்த்து உடனே மாற்றலாம்.',
                          kannada:
                              'Personal ಗೆ photo, Business ಗೆ logo. Preview ನೋಡಿ ತಕ್ಷಣ ಬದಲಾಯಿಸಿ.',
                          malayalam:
                              'Personal ന് photo, Business ന് logo. Preview കണ്ട് ഉടനെ മാറ്റുക.',
                        ),
                        style: const TextStyle(
                          fontSize: 12.8,
                          height: 1.45,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<PosterIdentityMode>(
            showSelectedIcon: false,
            segments: <ButtonSegment<PosterIdentityMode>>[
              ButtonSegment<PosterIdentityMode>(
                value: PosterIdentityMode.personal,
                label: Text(
                  strings.localized(
                    telugu: 'Personal',
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
                    telugu: 'Business',
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
          const SizedBox(height: 18),
          _IdentityPreviewCard(
            title: isBusiness
                ? strings.localized(
                    telugu: 'Business preview',
                    english: 'Business preview',
                    hindi: 'बिजनेस प्रीव्यू',
                    tamil: 'பிஸினஸ் முன்னோட்டம்',
                    kannada: 'ಬಿಸಿನೆಸ್ ಪ್ರಿವ್ಯೂ',
                    malayalam: 'ബിസിനസ് പ്രിവ്യൂ',
                  )
                : strings.localized(
                    telugu: 'Profile preview',
                    english: 'Profile preview',
                    hindi: 'प्रोफ़ाइल प्रीव्यू',
                    tamil: 'ப்ரொஃபைல் முன்னோட்டம்',
                    kannada: 'ಪ್ರೊಫೈಲ್ ಪ್ರಿವ್ಯೂ',
                    malayalam: 'പ്രൊഫൈൽ പ്രിവ്യൂ',
                  ),
            subtitle: isBusiness
                ? strings.localized(
                    telugu:
                        'Business name mariyu logo posters meedha apply avuthayi.',
                    english:
                        'Business name and logo will be applied on posters.',
                    hindi: 'बिजनेस नाम और लोगो पोस्टरों पर लागू होंगे।',
                    tamil:
                        'பிஸினஸ் பெயரும் லோகோவும் போஸ்டர்களில் பயன்படுத்தப்படும்.',
                    kannada:
                        'ಬಿಸಿನೆಸ್ ಹೆಸರು ಮತ್ತು ಲೋಗೋ ಪೋಸ್ಟರ್‌ಗಳಲ್ಲಿ ಅನ್ವಯವಾಗುತ್ತವೆ.',
                    malayalam:
                        'ബിസിനസ് പേരും ലോഗോയും പോസ്റ്ററുകളിൽ പ്രയോഗിക്കും.',
                  )
                : strings.localized(
                    telugu:
                        'User photo mariyu details posters meedha apply avuthayi.',
                    english:
                        'User photo and details will be applied on posters.',
                    hindi: 'यूज़र फोटो और विवरण पोस्टरों पर लागू होंगे।',
                    tamil:
                        'யூசர் புகைப்படமும் விவரங்களும் போஸ்டர்களில் பயன்படுத்தப்படும்.',
                    kannada:
                        'ಯೂಸರ್ ಫೋಟೋ ಮತ್ತು ವಿವರಗಳು ಪೋಸ್ಟರ್‌ಗಳಲ್ಲಿ ಅನ್ವಯವಾಗುತ್ತವೆ.',
                    malayalam:
                        'യൂസർ ഫോട്ടോയും വിവരങ്ങളും പോസ്റ്ററുകളിൽ പ്രയോഗിക്കും.',
                  ),
            busy: isBusiness ? _businessLogoBusy : _personalPhotoBusy,
            onVisualTap: isBusiness ? _pickBusinessLogo : _pickPersonalPhoto,
            child: SizedBox(
              width: 88,
              height: 88,
              child: ClipOval(
                child: PosterIdentityVisual(
                  profile: _draftProfile,
                  textScale: 1.05,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (!isBusiness) ...<Widget>[
            _SectionTitle(
              strings.localized(
                telugu: 'Personal Details',
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
                telugu: 'Display Name',
                english: 'Display Name',
                hindi: 'डिस्प्ले नेम',
                tamil: 'டிஸ்ப்ளே பெயர்',
                kannada: 'ಡಿಸ್ಪ್ಲೇ ಹೆಸರು',
                malayalam: 'ഡിസ്‌പ്ലേ പേര്',
              ),
              hintText: strings.localized(
                telugu: 'Mee peru enter cheyyandi',
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
                telugu: 'WhatsApp Number',
                english: 'WhatsApp Number',
                hindi: 'व्हाट्सऐप नंबर',
                tamil: 'வாட்ஸ்அப் எண்',
                kannada: 'ವಾಟ್ಸಾಪ್ ನಂಬರ್',
                malayalam: 'വാട്ട്‌സ്ആപ്പ് നമ്പർ',
              ),
              hintText: strings.localized(
                telugu: '10-digit number',
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
                    whatsappNumber: _onlyDigits(value),
                  );
                });
              },
            ),
          ] else ...<Widget>[
            _SectionTitle(
              strings.localized(
                telugu: 'Business Details',
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
                telugu: 'Business Name',
                english: 'Business Name',
                hindi: 'बिजनेस नाम',
                tamil: 'பிஸினஸ் பெயர்',
                kannada: 'ಬಿಸಿನೆಸ್ ಹೆಸರು',
                malayalam: 'ബിസിനസ് പേര്',
              ),
              hintText: strings.localized(
                telugu: 'Business name enter cheyyandi',
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
                telugu: 'Business Tagline',
                english: 'Business Tagline',
                hindi: 'बिजनेस टैगलाइन',
                tamil: 'பிஸினஸ் டேக் லைன்',
                kannada: 'ಬಿಸಿನೆಸ್ ಟ್ಯಾಗ್‌ಲೈನ್',
                malayalam: 'ബിസിനസ് ടാഗ്‌ലൈൻ',
              ),
              hintText: strings.localized(
                telugu: 'Optional short line',
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
                telugu: 'Business WhatsApp Number',
                english: 'Business WhatsApp Number',
                hindi: 'बिजनेस व्हाट्सऐप नंबर',
                tamil: 'பிஸினஸ் வாட்ஸ்அப் எண்',
                kannada: 'ಬಿಸಿನೆಸ್ ವಾಟ್ಸಾಪ್ ನಂಬರ್',
                malayalam: 'ബിസിനസ് വാട്ട്‌സ്ആപ്പ് നമ്പർ',
              ),
              hintText: strings.localized(
                telugu: '10-digit number',
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
            const SizedBox(height: 18),
            _SectionTitle(
              strings.localized(
                telugu: 'Generate Creative Logo',
                english: 'Generate Creative Logo',
                hindi: 'क्रिएटिव लोगो बनाएं',
                tamil: 'கிரியேட்டிவ் லோகோ உருவாக்கவும்',
                kannada: 'ಕ್ರಿಯೇಟಿವ್ ಲೋಗೋ ತಯಾರಿಸಿ',
                malayalam: 'ക്രിയേറ്റീവ് ലോഗോ സൃഷ്ടിക്കുക',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.localized(
                telugu:
                    'Business logo upload cheyyachu leda business name tho ready-made logo style select cheyyachu.',
                english:
                    'Upload a business logo or select a ready-made logo style from the business name.',
                hindi:
                    'बिजनेस लोगो अपलोड करें या बिजनेस नाम से तैयार लोगो स्टाइल चुनें।',
                tamil:
                    'பிஸினஸ் லோகோவை அப்லோடு செய்யலாம் அல்லது பெயரிலிருந்து ரெடி-மேட் லோகோ ஸ்டைலை தேர்வு செய்யலாம்.',
                kannada:
                    'ಬಿಸಿನೆಸ್ ಲೋಗೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ ಅಥವಾ ಬಿಸಿನೆಸ್ ಹೆಸರಿನಿಂದ ರೆಡಿ ಲೋಗೋ ಸ್ಟೈಲ್ ಆಯ್ಕೆಮಾಡಿ.',
                malayalam:
                    'ബിസിനസ് ലോഗോ അപ്‌ലോഡ് ചെയ്യുകയോ ബിസിനസ് പേരിൽ നിന്ന് റെഡി-മേഡ് ലോഗോ സ്റ്റൈൽ തിരഞ്ഞെടുക്കുകയോ ചെയ്യാം.',
              ),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 156,
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
                    businessName: _businessNameController.text.trim().isEmpty
                        ? strings.localized(
                            telugu: 'మనా బిజినెస్',
                            english: 'Mana Business',
                            hindi: 'मना बिजनेस',
                            tamil: 'மனா பிஸினஸ்',
                            kannada: 'ಮನ ಬಿಸಿನೆಸ್',
                            malayalam: 'മന ബിസിനസ്',
                          )
                        : _businessNameController.text.trim(),
                    businessTagline: _businessTaglineController.text.trim(),
                    identityMode: PosterIdentityMode.business,
                  );
                  final isSelected =
                      _draftProfile.businessLogoStyleId == styleId &&
                      _draftProfile.businessLogoPath.trim().isEmpty &&
                      _draftProfile.businessLogoUrl.trim().isEmpty;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _draftProfile = _draftProfile.copyWith(
                          businessLogoStyleId: styleId,
                          businessLogoPath: '',
                          businessLogoUrl: '',
                        );
                      });
                    },
                    child: SizedBox(
                      width: 118,
                      child: Column(
                        children: <Widget>[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 110,
                            height: 110,
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
                              telugu: 'Style ${index + 1}',
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
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFF5F3FF), Color(0xFFFDFDFF)],
                      ),
                      shape: BoxShape.circle,
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
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x1A6D28D9),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.35,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
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
