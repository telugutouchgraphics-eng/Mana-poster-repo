import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mana_poster/app/config/category_display_helper.dart';
import 'package:mana_poster/app/config/home_category_catalog.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/features/prehome/models/user_poster_upload.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_schedule_service.dart';
import 'package:mana_poster/features/prehome/services/user_poster_uploads_service.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/onboarding_surface_card.dart';

class _UploadCategoryOption {
  const _UploadCategoryOption({
    required this.id,
    required this.label,
    this.eventDateLabel,
  });

  final String id;
  final String label;
  final String? eventDateLabel;
}

class UserPosterUploadsScreen extends StatefulWidget {
  const UserPosterUploadsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.profileOnly = false,
  });

  final int initialTabIndex;
  final bool profileOnly;

  @override
  State<UserPosterUploadsScreen> createState() =>
      _UserPosterUploadsScreenState();
}

class _UserPosterUploadsScreenState extends State<UserPosterUploadsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _quoteController = TextEditingController();
  late final TabController _tabController;
  late final Stream<List<UserPosterUpload>> _uploadsStream;
  List<UserPosterUpload> _lastVisibleUploads = const <UserPosterUpload>[];
  List<UserPosterUpload> _serverFreshUploads = const <UserPosterUpload>[];
  Set<String> _hiddenUploadIds = const <String>{};
  Timer? _refreshTimer;

  File? _selectedImageFile;
  int _selectedImageBytes = 0;
  String _selectedCategoryId = '';
  String _selectedCategoryLabel = '';
  bool _submitting = false;
  String _selectedRegionId = '';
  Future<void>? _regionSelectionLoadFuture;

  static final List<HomeCategoryCatalogEntry> _uploadableCategories =
      HomeCategoryCatalog.uploadable;
  static const DynamicCategoryService _dynamicCategoryService =
      DynamicCategoryService(daysBeforeEvent: 7);
  static const DynamicEventScheduleService _dynamicEventScheduleService =
      DynamicEventScheduleService();

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(
      length: widget.profileOnly ? 1 : 2,
      vsync: this,
      initialIndex: widget.profileOnly ? 0 : widget.initialTabIndex.clamp(0, 1),
    );
    _uploadsStream = UserPosterUploadsService.instance
        .watchCurrentUserUploads();
    if (_uploadableCategories.isNotEmpty) {
      _selectedCategoryId = _normalizeCategoryId(
        _uploadableCategories.first.id,
      );
      _selectedCategoryLabel = _uploadableCategories.first.label;
    }
    unawaited(_loadLocalHiddenUploads());
    unawaited(_loadRegionSelection());
    unawaited(_refreshUploads(forceServer: true));
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) {
        return;
      }
      unawaited(_refreshUploads(forceServer: true));
    });
  }

  @override
  void dispose() {
    unawaited(ScreenSecurityService.unprotectScreen());
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _quoteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadRegionSelection());
      unawaited(_refreshUploads(forceServer: true));
    }
  }

  Future<void> _loadRegionSelection() async {
    final inFlight = _regionSelectionLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      final region = await AppRegionService.loadSelection();
      final regionId = region?.id ?? '';
      if (!mounted || _selectedRegionId == regionId) {
        return;
      }
      setState(() {
        _selectedRegionId = regionId;
      });
    }();
    _regionSelectionLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_regionSelectionLoadFuture, future)) {
        _regionSelectionLoadFuture = null;
      }
    }
  }

  String _normalizeCategoryId(String raw) {
    return raw.trim().toLowerCase().replaceAll('-', '_');
  }

  List<_UploadCategoryOption> _categoryOptions(AppLanguage language) {
    final seen = <String>{};
    final output = <_UploadCategoryOption>[];
    final dynamicEventDateById = _dynamicEventDateLabels(language);
    void addOption(String id, String label, {String? eventDateLabel}) {
      final normalizedId = _normalizeCategoryId(id);
      final safeLabel = label.trim();
      if (normalizedId.isEmpty ||
          safeLabel.isEmpty ||
          !seen.add(normalizedId)) {
        return;
      }
      output.add(
        _UploadCategoryOption(
          id: normalizedId,
          label: safeLabel,
          eventDateLabel: eventDateLabel,
        ),
      );
    }

    final staticLabels = AppStrings(language).localizedHomeCategories();
    final staticLabelById = <String, String>{};
    for (var index = 0;
        index < HomeCategoryCatalog.all.length && index < staticLabels.length;
        index += 1) {
      staticLabelById[_normalizeCategoryId(HomeCategoryCatalog.all[index].id)] =
          staticLabels[index];
    }
    for (final entry in _uploadableCategories) {
      // HomeCategoryCatalog keeps canonical English labels for IDs/search.
      // UI must use the selected app language.
      final localizedLabel =
          staticLabelById[_normalizeCategoryId(entry.id)] ?? entry.label;
      addOption(
        entry.id,
        CategoryDisplayHelper.withIcon(entry.id, localizedLabel),
      );
    }
    for (final item in _dynamicCategoryService.categoriesForDate(
      IstTimeService.now(),
      language: language,
      selectedRegionId: _selectedRegionId,
    )) {
      addOption(
        item.id,
        CategoryDisplayHelper.withIcon(item.id, item.label),
        eventDateLabel: dynamicEventDateById[_normalizeCategoryId(item.id)],
      );
    }
    return output;
  }

  Map<String, String> _dynamicEventDateLabels(AppLanguage language) {
    final schedules = _dynamicEventScheduleService.schedulesForYear(
      IstTimeService.now().year,
      daysBeforeEvent: 7,
    );
    final output = <String, String>{};
    for (final item in schedules) {
      final eventId = _normalizeCategoryId(item.event.id);
      output[eventId] = _formatEventDateLabel(item.startDate, language);
    }
    return output;
  }

  String _formatEventDateLabel(DateTime date, AppLanguage language) {
    final formatted = UserPosterUploadsService.formatIstDateLabelFromMillis(
      date.millisecondsSinceEpoch,
    );
    return AppStrings(language).localized(
      telugu: 'ఈవెంట్ డేట్: $formatted',
      english: 'Event date: $formatted',
      hindi: 'इवेंट डेट: $formatted',
    );
  }

  Future<void> _openCategorySelectionScreen(
    List<_UploadCategoryOption> options,
  ) async {
    final selected = await Navigator.of(context).push<_UploadCategoryOption>(
      MaterialPageRoute<_UploadCategoryOption>(
        builder: (_) => _UploadCategorySelectionScreen(
          options: options,
          selectedCategoryId: _selectedCategoryId,
        ),
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _selectedCategoryId = selected.id;
      _selectedCategoryLabel = selected.label;
    });
  }

  _UploadCategoryOption? _selectedCategoryOptionFor(
    List<_UploadCategoryOption> options,
  ) {
    for (final option in options) {
      if (option.id == _selectedCategoryId) {
        return option;
      }
    }
    return null;
  }

  Future<void> _loadLocalHiddenUploads() async {
    final hidden = await UserPosterUploadsService.instance
        .hiddenUploadIdsForCurrentUser();
    if (!mounted) {
      return;
    }
    setState(() {
      _hiddenUploadIds = hidden;
    });
  }

  List<UserPosterUpload> _applyLocalVisibility(List<UserPosterUpload> uploads) {
    if (_hiddenUploadIds.isEmpty) {
      return uploads;
    }
    return uploads
        .where((item) => !_hiddenUploadIds.contains(item.id))
        .toList(growable: false);
  }

  List<UserPosterUpload> _mergeUploads(
    List<UserPosterUpload> primary,
    List<UserPosterUpload> secondary,
  ) {
    final byId = <String, UserPosterUpload>{};
    for (final upload in secondary) {
      byId[upload.id] = upload;
    }
    for (final upload in primary) {
      final existing = byId[upload.id];
      if (existing == null) {
        byId[upload.id] = upload;
        continue;
      }
      final primaryScore = upload.updatedAtMillis;
      final existingScore = existing.updatedAtMillis;
      if (primaryScore > existingScore ||
          (primaryScore == existingScore &&
              upload.status != existing.status &&
              upload.status != 'pending')) {
        byId[upload.id] = upload;
      }
    }
    final merged = byId.values.toList(growable: false);
    merged.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return merged;
  }

  Future<void> _refreshUploads({bool forceServer = false}) async {
    try {
      final uploads = await UserPosterUploadsService.instance
          .fetchCurrentUserUploads(forceServer: forceServer);
      if (!mounted) {
        return;
      }
      final visible = _applyLocalVisibility(uploads);
      setState(() {
        _serverFreshUploads = visible;
        _lastVisibleUploads = visible;
      });
    } catch (error, stackTrace) {
      developer.log(
        'User uploads refresh skipped: $error',
        name: 'user_uploads.refresh',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _hideUploadLocally(UserPosterUpload upload) async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            strings.localized(
              telugu: 'ఈ ఐటమ్‌ను దాచాలా?',
              english: 'Hide this item?',
            ),
          ),
          content: Text(
            strings.localized(
              telugu:
                  'ఇది మీ అప్‌లోడ్‌ల జాబితా నుండి మాత్రమే తొలగుతుంది. ఇతర వినియోగదారుల కోసం ఇది తొలగించబడదు.',
              english:
                  'This will be removed only from your My Uploads list. It will not be deleted for other users.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                strings.localized(telugu: 'రద్దు', english: 'Cancel'),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                strings.localized(
                  telugu: 'డిలీట్',
                  english: 'Delete',
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await UserPosterUploadsService.instance.hideUploadFromCurrentUserList(
      upload.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _hiddenUploadIds = <String>{..._hiddenUploadIds, upload.id};
      _serverFreshUploads = _applyLocalVisibility(_serverFreshUploads);
      _lastVisibleUploads = _applyLocalVisibility(_lastVisibleUploads);
    });
    ScaffoldMessenger.of(context).showTopSnackBar(
      AppSnackBar.build(
        content: Text(
          strings.localized(
            telugu:
                'ఈ ఐటమ్ మీ లిస్ట్ నుంచి తొలగించబడింది',
            english: 'This item was removed from your list',
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final strings = context.strings;
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  'అప్‌లోడ్ మొబైల్ యాప్‌లో మాత్రమే అందుబాటులో ఉంది',
              english: 'Upload is supported on mobile app only',
            ),
          ),
        ),
      );
      return;
    }
    final file = File(picked.path);
    final bytes = await file.length();
    if (bytes > UserPosterUploadsService.maxUploadBytes) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  'చిత్ర పరిమాణం 500KB లేదా దానికంటే తక్కువ ఉండాలి',
              english: 'Image size must be 500KB or less',
            ),
          ),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImageFile = file;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final strings = context.strings;
    final image = _selectedImageFile;
    final quoteText = _quoteController.text.trim();
    if (image == null && quoteText.isEmpty) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  'దయచేసి చిత్రం ఎంచుకోండి లేదా సూక్తి రాయండి',
              english: 'Please select an image or write a quote',
            ),
          ),
        ),
      );
      return;
    }
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await UserPosterUploadsService.instance.submitUpload(
        imageFile: image,
        quoteText: quoteText,
        categoryId: _selectedCategoryId,
        categoryLabel: _selectedCategoryLabel,
      );
      if (!mounted) {
        return;
      }
      if (!result.ok) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: Text(_submitResultMessage(result.code))),
        );
        return;
      }
      setState(() {
        _selectedImageFile = null;
        _selectedImageBytes = 0;
        _quoteController.clear();
      });
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  'అప్‌లోడ్ రివ్యూ కోసం పంపబడింది',
              english: 'Upload submitted for review',
            ),
          ),
        ),
      );
      unawaited(_refreshUploads(forceServer: true));
      _tabController.animateTo(1);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _statusLabel(UserPosterUpload upload) {
    final strings = context.strings;
    if (upload.isApproved) {
      return strings.localized(
        telugu: 'ఆమోదించబడింది',
        english: 'Approved',
      );
    }
    if (upload.isRejected) {
      return strings.localized(
        telugu: 'తిరస్కరించబడింది',
        english: 'Rejected',
      );
    }
    return strings.localized(
      telugu: 'పెండింగ్',
      english: 'Pending',
    );
  }

  Color _statusColor(UserPosterUpload upload) {
    if (upload.isApproved) {
      return const Color(0xFF15803D);
    }
    if (upload.isRejected) {
      return const Color(0xFFB91C1C);
    }
    return const Color(0xFFA16207);
  }

  String _submitResultMessage(UserPosterUploadSubmitCode code) {
    final strings = context.strings;
    switch (code) {
      case UserPosterUploadSubmitCode.success:
        return '';
      case UserPosterUploadSubmitCode.loginRequired:
        return strings.localized(
          telugu: 'లాగిన్ అవసరం',
          english: 'Login required',
        );
      case UserPosterUploadSubmitCode.categoryRequired:
        return strings.localized(
          telugu: 'కేటగిరీ అవసరం',
          english: 'Category is required',
        );
      case UserPosterUploadSubmitCode.contentRequired:
        return strings.localized(
          telugu: 'చిత్రం లేదా సూక్తి అవసరం',
          english: 'Image or quote is required',
        );
      case UserPosterUploadSubmitCode.imageTooLarge:
        return strings.localized(
          telugu:
              'చిత్ర పరిమాణం 500KB లేదా దానికంటే తక్కువ ఉండాలి',
          english: 'Image size must be 500KB or less',
        );
      case UserPosterUploadSubmitCode.quoteTooLong:
        return strings.localized(
          telugu:
              'సూక్తి 600 అక్షరాల లోపు ఉండాలి',
          english: 'Quote must be 600 characters or less',
        );
      case UserPosterUploadSubmitCode.uploadFailed:
        return strings.localized(
          telugu:
              'అప్‌లోడ్ విఫలమైంది. మళ్లీ ప్రయత్నించండి.',
          english: 'Upload failed. Please try again.',
        );
    }
  }

  String _uploadWindowMessage() {
    final strings = context.strings;
    final applicableDate =
        UserPosterUploadsService.formatIstDateLabelFromMillis(
          UserPosterUploadsService.resolveApplicableFromMillis(),
        );
    return strings.localized(
      telugu:
          '\u0c05\u0c2a\u0c4d\u200c\u0c32\u0c4b\u0c21\u0c4d \u0c38\u0c2e\u0c2f\u0c02: \u0c30\u0c3e\u0c24\u0c4d\u0c30\u0c3f 10:00 IST \u0c32\u0c4b\u0c2a\u0c41. \u0c24\u0c47\u0c26\u0c40: $applicableDate',
      english: 'Upload timing: before 10:00 PM IST. Date: $applicableDate',
    );
  }

  String _communityUploadReviewNote(AppLanguage language) {
    return AppStrings(language).localized(
      telugu:
          'మీ ఫోటో, సూక్తి లేదా రూపకల్పన ఆలోచనను సమీక్ష కోసం పంపండి. మా బృందం దాన్ని పరిశీలించి, అవసరమైతే మెరుగుపరిచి సరైన అనువర్తన విభాగంలో ప్రచురించవచ్చు. ఆమోదించిన విషయం మీకూ, ఇతర వినియోగదారులకూ కనిపించవచ్చు. మీరు పంపే విషయానికి మీరే బాధ్యత వహించాలి. నిబంధనలు మరియు షరతులు వర్తిస్తాయి.',
      english:
          'Upload your photo, quote, or design idea for review. Our team may review, edit, improve, and publish approved content in the matching app category. Published content can be visible to you and other users. You are responsible for the content you upload. Terms & Conditions apply.',
      hindi:
          'अपनी फोटो, सुविचार या डिज़ाइन विचार को समीक्षा के लिए भेजें। हमारी टीम उसे जाँचकर, आवश्यकता होने पर सुधारकर सही ऐप श्रेणी में प्रकाशित कर सकती है। स्वीकृत सामग्री आपको और अन्य उपयोगकर्ताओं को दिखाई दे सकती है। भेजी गई सामग्री की जिम्मेदारी आपकी होगी। नियम और शर्तें लागू होंगी।',
      tamil:
          'உங்கள் புகைப்படம், மேற்கோள் அல்லது வடிவமைப்பு யோசனையை ஆய்வுக்காக அனுப்புங்கள். எங்கள் குழு அதை பரிசீலித்து, தேவையெனில் மேம்படுத்தி சரியான செயலி பிரிவில் வெளியிடலாம். அங்கீகரிக்கப்பட்ட உள்ளடக்கம் உங்களுக்கும் பிற பயனர்களுக்கும் தெரியலாம். நீங்கள் அனுப்பும் உள்ளடக்கத்திற்கு நீங்களே பொறுப்பு. விதிமுறைகள் மற்றும் நிபந்தனைகள் பொருந்தும்.',
      kannada:
          'ನಿಮ್ಮ ಫೋಟೋ, ಉಲ್ಲೇಖ ಅಥವಾ ವಿನ್ಯಾಸ ಕಲ್ಪನೆಯನ್ನು ಪರಿಶೀಲನೆಗಾಗಿ ಕಳುಹಿಸಿ. ನಮ್ಮ ತಂಡ ಅದನ್ನು ಪರಿಶೀಲಿಸಿ, ಅಗತ್ಯವಿದ್ದರೆ ಸುಧಾರಿಸಿ ಸರಿಯಾದ ಆಪ್ ವಿಭಾಗದಲ್ಲಿ ಪ್ರಕಟಿಸಬಹುದು. ಅನುಮೋದಿತ ವಿಷಯವು ನಿಮಗೂ ಇತರ ಬಳಕೆದಾರರಿಗೂ ಕಾಣಿಸಬಹುದು. ನೀವು ಕಳುಹಿಸುವ ವಿಷಯಕ್ಕೆ ನೀವೇ ಜವಾಬ್ದಾರರು. ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು ಅನ್ವಯಿಸುತ್ತವೆ.',
      malayalam:
          'നിങ്ങളുടെ ഫോട്ടോ, ഉദ്ധരണി അല്ലെങ്കിൽ രൂപകൽപ്പന ആശയം പരിശോധനയ്ക്കായി അയയ്ക്കുക. ഞങ്ങളുടെ സംഘം അത് പരിശോധിച്ച്, ആവശ്യമെങ്കിൽ മെച്ചപ്പെടുത്തി ശരിയായ ആപ്പ് വിഭാഗത്തിൽ പ്രസിദ്ധീകരിക്കാം. അംഗീകരിച്ച ഉള്ളടക്കം നിങ്ങളും മറ്റ് ഉപയോക്താക്കളും കാണാനിടയുണ്ട്. നിങ്ങൾ അയക്കുന്ന ഉള്ളടക്കത്തിന് ഉത്തരവാദിത്തം നിങ്ങളുടേതാണ്. നിബന്ധനകളും വ്യവസ്ഥകളും ബാധകം.',
    );
  }

  // ignore: unused_element
  Widget _buildCommunityUploadReviewNote(AppLanguage language) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: Color(0xFFD81B60),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _communityUploadReviewNote(language),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCommunityUploadInstructions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _CommunityUploadInstructionsScreen(),
      ),
    );
  }

  Widget _buildCommunityUploadInstructionsEntry() {
    final strings = context.strings;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: InkWell(
        onTap: _openCommunityUploadInstructions,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.menu_book_outlined,
                size: 20,
                color: Color(0xFFD81B60),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.localized(
                        telugu:
                            '\u0c38\u0c42\u0c1a\u0c28\u0c32\u0c41 \u0c1a\u0c26\u0c35\u0c02\u0c21\u0c3f',
                        english: 'Read Instructions',
                        hindi:
                            '\u0928\u093f\u0930\u094d\u0926\u0947\u0936 \u092a\u0922\u093c\u0947\u0902',
                        tamil:
                            '\u0bb5\u0bb4\u0bbf\u0bae\u0bc1\u0bb1\u0bc8\u0b95\u0bb3\u0bc8 \u0baa\u0b9f\u0bbf\u0b95\u0bcd\u0b95\u0bb5\u0bc1\u0bae\u0bcd',
                        kannada:
                            '\u0cb8\u0cc2\u0c9a\u0ca8\u0cc6\u0c97\u0cb3\u0ca8\u0ccd\u0ca8\u0cc1 \u0c93\u0ca6\u0cbf',
                        malayalam:
                            '\u0d28\u0d3f\u0d30\u0d4d\u0d26\u0d4d\u0d26\u0d47\u0d36\u0d19\u0d4d\u0d19\u0d7e \u0d35\u0d3e\u0d2f\u0d3f\u0d15\u0d4d\u0d15\u0d41\u0d15',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.localized(
                        telugu:
                            'పంపే ముందు సమీక్ష నియమాలను తెలుసుకోండి.',
                        english:
                            'Check review rules before submitting your content.',
                        hindi:
                            'अपनी सामग्री भेजने से पहले समीक्षा नियम देखें।',
                        tamil:
                            'உங்கள் உள்ளடக்கத்தை அனுப்பும் முன் ஆய்வு விதிகளைப் பாருங்கள்.',
                        kannada:
                            'ನಿಮ್ಮ ವಿಷಯವನ್ನು ಕಳುಹಿಸುವ ಮೊದಲು ಪರಿಶೀಲನಾ ನಿಯಮಗಳನ್ನು ನೋಡಿ.',
                        malayalam:
                            'നിങ്ങളുടെ ഉള്ളടക്കം അയയ്ക്കുന്നതിന് മുമ്പ് പരിശോധനാ നിയമങ്ങൾ വായിക്കുക.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundActionButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    Color backgroundColor = const Color(0xFFD81B60),
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: const StadiumBorder(),
        ),
        icon: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18),
        ),
        label: Text(label),
      ),
    );
  }

  Widget _buildUploadTab() {
    final strings = context.strings;
    final language = context.currentLanguage;
    final categoryOptions = _categoryOptions(language);
    if (categoryOptions.isNotEmpty &&
        !categoryOptions.any((item) => item.id == _selectedCategoryId)) {
      _selectedCategoryId = categoryOptions.first.id;
      _selectedCategoryLabel = categoryOptions.first.label;
    }
    final selectedCategoryOption = _selectedCategoryOptionFor(categoryOptions);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        OnboardingSurfaceCard(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildRoundActionButton(
                onPressed: _submitting ? null : _pickImage,
                icon: Icons.add_rounded,
                label: strings.localized(
                  telugu: 'చిత్రం ఎంచుకోండి',
                  english: 'Select Image',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _uploadWindowMessage(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
              ),
              if (_selectedImageFile != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  strings.localized(
                    telugu:
                        'ఎంచుకున్నది: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    english:
                        'Selected: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_selectedImageFile!, fit: BoxFit.contain),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                strings.localized(
                  telugu: 'మీ సూక్తి రాయండి (ఐచ్ఛికం)',
                  english: 'Write your quote (optional)',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quoteController,
                enabled: !_submitting,
                minLines: 4,
                maxLines: 7,
                maxLength: UserPosterUploadsService.maxQuoteLength,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: strings.localized(
                    telugu: 'ఇక్కడ మీ సూక్తి లేదా సందేశం రాయండి...',
                    english: 'Write your quote or message here...',
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.localized(
                  telugu: 'విభాగం',
                  english: 'Category',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _submitting
                    ? null
                    : () => _openCategorySelectionScreen(categoryOptions),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _selectedCategoryLabel.isNotEmpty
                                  ? _selectedCategoryLabel
                                  : strings.localized(
                                      telugu: 'విభాగం ఎంచుకోండి',
                                      english: 'Select category',
                                    ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (selectedCategoryOption?.eventDateLabel
                                case final String eventDateLabel)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  eventDateLabel,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF64748B),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(
                    _submitting
                        ? strings.localized(
                            telugu:
                                '\u0c38\u0c2c\u0c4d\u0c2e\u0c3f\u0c1f\u0c4d \u0c05\u0c35\u0c41\u0c24\u0c4b\u0c02\u0c26\u0c3f...',
                            english: 'Submitting...',
                          )
                        : strings.localized(
                            telugu:
                                '\u0c38\u0c2c\u0c4d\u0c2e\u0c3f\u0c1f\u0c4d',
                            english: 'Submit',
                          ),
                  ),
                ),
              ),
              _buildCommunityUploadInstructionsEntry(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadList({required bool detailedStatusView}) {
    final strings = context.strings;
    Future<void> refreshUploads() async {
      await _refreshUploads(forceServer: true);
    }

    return StreamBuilder<List<UserPosterUpload>>(
      stream: _uploadsStream,
      initialData: _lastVisibleUploads,
      builder: (context, snapshot) {
        final hasFreshData = snapshot.hasData;
        final streamUploads = hasFreshData
            ? _applyLocalVisibility(snapshot.data!)
            : _lastVisibleUploads;
        if (hasFreshData) {
          _lastVisibleUploads = streamUploads;
        }
        final uploads = _mergeUploads(_serverFreshUploads, streamUploads);
        if (snapshot.connectionState == ConnectionState.waiting &&
            uploads.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        Widget child;
        if (uploads.isEmpty) {
          child = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const SizedBox(height: 120),
              OnboardingSurfaceCard(
                child: Text(
                  strings.localized(
                    telugu:
                        '\u0c07\u0c02\u0c15\u0c3e \u0c05\u0c2a\u0c4d\u200c\u0c32\u0c4b\u0c21\u0c4d\u0c32\u0c41 \u0c32\u0c47\u0c35\u0c41',
                    english: 'No uploads yet',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        } else {
          child = ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final upload = uploads[index];
              return OnboardingSurfaceCard(
                maxWidth: 520,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 74,
                      height: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: upload.imageUrl.isNotEmpty
                            ? Image.network(
                                upload.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stackTrace) =>
                                    Container(
                                      color: const Color(0xFFF1F5F9),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                              )
                            : Container(
                                color: const Color(0xFFF8FAFC),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.format_quote_rounded,
                                  color: Color(0xFF64748B),
                                  size: 30,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  upload.categoryLabel.isNotEmpty
                                      ? upload.categoryLabel
                                      : upload.categoryId,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                _statusLabel(upload),
                                style: TextStyle(
                                  color: _statusColor(upload),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                tooltip: strings.localized(
                                  telugu:
                                      'నా లిస్ట్ నుండి తొలగించు',
                                  english: 'Remove from my list',
                                ),
                                onPressed: () => _hideUploadLocally(upload),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateTime.fromMillisecondsSinceEpoch(
                              upload.createdAtMillis,
                            ).toLocal().toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          if (upload.quoteText.isNotEmpty) ...<Widget>[
                            Text(
                              upload.quoteText,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF334155),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            strings.localized(
                              telugu:
                                  'యాప్‌లో కనిపించే తేదీ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              english:
                                  'App visible date: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (upload.isRejected &&
                              upload.rejectionReason.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              strings.localized(
                                telugu:
                                    'కారణం: ${upload.rejectionReason}',
                                english: 'Reason: ${upload.rejectionReason}',
                              ),
                              style: const TextStyle(color: Color(0xFFB91C1C)),
                            ),
                          ],
                          if (upload.isApproved) ...<Widget>[
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                const Icon(Icons.download_outlined, size: 18),
                                const SizedBox(width: 4),
                                Text('${upload.downloadCount}'),
                                const SizedBox(width: 16),
                                const Icon(Icons.share_outlined, size: 18),
                                const SizedBox(width: 4),
                                Text('${upload.shareCount}'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: uploads.length,
          );
        }

        return RefreshIndicator(onRefresh: refreshUploads, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileOnly = widget.profileOnly;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: const Color(0xFF0F172A),
        automaticallyImplyLeading: true,
        leading: const BackButton(),
        title: Text(
          profileOnly
              ? context.strings.localized(
                  telugu: 'నా అప్‌లోడ్లు',
                  english: 'My Uploads',
                )
              : context.strings.localized(
                  telugu:
                      'కమ్యూనిటీ కాంట్రిబ్యూషన్',
                  english: 'Community Contribution',
                ),
        ),
        bottom: profileOnly
            ? null
            : TabBar(
                controller: _tabController,
                tabs: <Tab>[
                  Tab(
                    text: context.strings.localized(
                      telugu: 'పోస్టర్ అప్‌లోడ్',
                      english: 'Upload Poster',
                    ),
                  ),
                  Tab(
                    text: context.strings.localized(
                      telugu: 'నా అప్‌లోడ్లు',
                      english: 'My Uploads',
                    ),
                  ),
                ],
              ),
      ),
      body: GradientShell(
        child: TabBarView(
          controller: _tabController,
          children: profileOnly
              ? <Widget>[_buildUploadList(detailedStatusView: false)]
              : <Widget>[
                  _buildUploadTab(),
                  _buildUploadList(detailedStatusView: false),
                ],
        ),
      ),
    );
  }
}

class _CommunityUploadInstructionsScreen extends StatelessWidget {
  const _CommunityUploadInstructionsScreen();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final sections = _sections(strings);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: const BackButton(),
        title: Text(_title(strings)),
      ),
      body: GradientShell(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            OnboardingSurfaceCard(
              maxWidth: 620,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE4EF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _title(strings),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle(strings),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final section in sections) ...<Widget>[
                    _CommunityInstructionSection(section: section),
                    const SizedBox(height: 14),
                  ],
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFEA580C),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _responsibility(strings),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    height: 1.4,
                                    color: const Color(0xFF7C2D12),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        strings.localized(
                          telugu:
                              '\u0c05\u0c30\u0c4d\u0c25\u0c2e\u0c48\u0c02\u0c26\u0c3f',
                          english: 'Got it',
                          hindi: '\u0938\u092e\u091d \u0917\u092f\u093e',
                          tamil:
                              '\u0baa\u0bc1\u0bb0\u0bbf\u0ba8\u0bcd\u0ba4\u0ba4\u0bc1',
                          kannada:
                              '\u0c85\u0cb0\u0ccd\u0ca5\u0cb5\u0cbe\u0caf\u0cbf\u0ca4\u0cc1',
                          malayalam:
                              '\u0d2e\u0d28\u0d38\u0d4d\u0d38\u0d3f\u0d32\u0d3e\u0d2f\u0d3f',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppStrings strings) {
    return strings.localized(
      telugu:
          '\u0c15\u0c2e\u0c4d\u0c2f\u0c42\u0c28\u0c3f\u0c1f\u0c40 \u0c05\u0c2a\u0c4d\u200c\u0c32\u0c4b\u0c21\u0c4d \u0c38\u0c42\u0c1a\u0c28\u0c32\u0c41',
      english: 'Community Upload Instructions',
      hindi:
          '\u0915\u092e\u094d\u092f\u0941\u0928\u093f\u091f\u0940 \u0905\u092a\u0932\u094b\u0921 \u0928\u093f\u0930\u094d\u0926\u0947\u0936',
      tamil: 'சமூக பதிவேற்ற வழிமுறைகள்',
      kannada: 'ಸಮುದಾಯ ಅಪ್ಲೋಡ್ ಸೂಚನೆಗಳು',
      malayalam: 'സമൂഹ അപ്‌ലോഡ് നിർദ്ദേശങ്ങൾ',
    );
  }

  String _subtitle(AppStrings strings) {
    return strings.localized(
      telugu:
          'మీ సూక్తి, వచనం లేదా సూక్తి ఉన్న చిత్రాన్ని మన పోస్టర్ సమీక్ష బృందానికి పంపండి.',
      english:
          'Send your quote, text, or quote image to the Mana Poster review team.',
      hindi:
          'अपना सुविचार, पाठ या सुविचार वाली छवि मन पोस्टर समीक्षा टीम को भेजें।',
      tamil:
          'உங்கள் மேற்கோள், உரை அல்லது மேற்கோள் உள்ள படத்தை மன போஸ்டர் ஆய்வுக் குழுவிற்கு அனுப்புங்கள்.',
      kannada:
          'ನಿಮ್ಮ ಉಲ್ಲೇಖ, ಪಠ್ಯ ಅಥವಾ ಉಲ್ಲೇಖ ಇರುವ ಚಿತ್ರವನ್ನು ಮನ ಪೋಸ್ಟರ್ ಪರಿಶೀಲನಾ ತಂಡಕ್ಕೆ ಕಳುಹಿಸಿ.',
      malayalam:
          'നിങ്ങളുടെ ഉദ്ധരണി, വാചകം അല്ലെങ്കിൽ ഉദ്ധരണിയുള്ള ചിത്രം മന പോസ്റ്റർ പരിശോധനാ സംഘത്തിന് അയയ്ക്കുക.',
    );
  }

  String _responsibility(AppStrings strings) {
    return strings.localized(
      telugu:
          'మీరు పంపే విషయానికి మీరే బాధ్యులు. పంపినప్పుడు మన పోస్టర్ నిబంధనలు మరియు సమాజ మార్గదర్శకాలను అంగీకరించినట్లుగా పరిగణిస్తాము.',
      english:
          'You are responsible for the content you upload. By submitting, you confirm that your upload follows Mana Poster terms and community guidelines.',
      hindi:
          'आपके द्वारा भेजी गई सामग्री की जिम्मेदारी आपकी है। भेजने पर यह माना जाएगा कि आप मन पोस्टर के नियमों और सामुदायिक दिशानिर्देशों को स्वीकार करते हैं।',
      tamil:
          'நீங்கள் அனுப்பும் உள்ளடக்கத்திற்கு நீங்களே பொறுப்பு. அனுப்புவதன் மூலம் மன போஸ்டர் விதிமுறைகளையும் சமூக வழிகாட்டுதல்களையும் ஏற்றுக்கொள்கிறீர்கள் என்று கருதப்படும்.',
      kannada:
          'ನೀವು ಕಳುಹಿಸುವ ವಿಷಯಕ್ಕೆ ನೀವೇ ಜವಾಬ್ದಾರರು. ಕಳುಹಿಸಿದಾಗ ಮನ ಪೋಸ್ಟರ್ ನಿಯಮಗಳು ಮತ್ತು ಸಮುದಾಯ ಮಾರ್ಗಸೂಚಿಗಳನ್ನು ಒಪ್ಪಿಕೊಂಡಂತೆ ಪರಿಗಣಿಸಲಾಗುತ್ತದೆ.',
      malayalam:
          'നിങ്ങൾ അയക്കുന്ന ഉള്ളടക്കത്തിന് ഉത്തരവാദിത്തം നിങ്ങളുടേതാണ്. അയയ്ക്കുന്നതിലൂടെ മന പോസ്റ്ററിന്റെ നിബന്ധനകളും സമൂഹ മാർഗ്ഗനിർദ്ദേശങ്ങളും അംഗീകരിക്കുന്നതായി കണക്കാക്കും.',
    );
  }

  List<_CommunityInstructionSectionData> _sections(AppStrings strings) {
    return <_CommunityInstructionSectionData>[
      _CommunityInstructionSectionData(
        title: strings.localized(
          telugu: 'ఇది ఎలా పనిచేస్తుంది',
          english: 'How it works',
          hindi: 'यह कैसे काम करता है',
          tamil: 'இது எப்படி செயல்படும்',
          kannada: 'ಇದು ಹೇಗೆ ಕೆಲಸ ಮಾಡುತ್ತದೆ',
          malayalam: 'ഇത് എങ്ങനെ പ്രവർത്തിക്കും',
        ),
        bullets: <String>[
          strings.localized(
            telugu: 'సూక్తి వచనం, సూక్తి చిత్రం లేదా రెండింటినీ పంపవచ్చు.',
            english: 'You can upload quote text, a quote image, or both.',
            hindi: 'आप सुविचार का पाठ, सुविचार वाली छवि या दोनों भेज सकते हैं।',
            tamil: 'மேற்கோள் உரை, மேற்கோள் உள்ள படம் அல்லது இரண்டையும் அனுப்பலாம்.',
            kannada: 'ಉಲ್ಲೇಖ ಪಠ್ಯ, ಉಲ್ಲೇಖ ಇರುವ ಚಿತ್ರ ಅಥವಾ ಎರಡನ್ನೂ ಕಳುಹಿಸಬಹುದು.',
            malayalam: 'ഉദ്ധരണി വാചകം, ഉദ്ധരണിയുള്ള ചിത്രം അല്ലെങ്കിൽ രണ്ടും അയയ്ക്കാം.',
          ),
          strings.localized(
            telugu: 'మీరు పంపినది ముందుగా నిర్వాహకుని సమీక్షకు వెళ్తుంది.',
            english: 'Your upload first goes to the manager review queue.',
            hindi: 'आपकी भेजी हुई सामग्री पहले प्रबंधक की समीक्षा में जाएगी।',
            tamil: 'நீங்கள் அனுப்பியது முதலில் நிர்வாகியின் ஆய்வுக்கு செல்லும்.',
            kannada: 'ನೀವು ಕಳುಹಿಸಿದುದು ಮೊದಲು ನಿರ್ವಾಹಕರ ಪರಿಶೀಲನೆಗೆ ಹೋಗುತ್ತದೆ.',
            malayalam: 'നിങ്ങൾ അയച്ചത് ആദ്യം മാനേജറുടെ പരിശോധനയ്ക്കായി പോകും.',
          ),
          strings.localized(
            telugu: 'ఆమోదం లభిస్తే బృందం దాన్ని మెరుగుపరిచి సంబంధిత విభాగంలో ప్రచురించవచ్చు.',
            english: 'If approved, the team may redesign it and publish it in the related category.',
            hindi: 'स्वीकृति मिलने पर टीम उसे बेहतर बनाकर संबंधित श्रेणी में प्रकाशित कर सकती है।',
            tamil: 'அங்கீகாரம் கிடைத்தால் குழு அதை மேம்படுத்தி தொடர்புடைய பிரிவில் வெளியிடலாம்.',
            kannada: 'ಅನುಮೋದನೆ ಸಿಕ್ಕರೆ ತಂಡ ಅದನ್ನು ಸುಧಾರಿಸಿ ಸಂಬಂಧಿತ ವಿಭಾಗದಲ್ಲಿ ಪ್ರಕಟಿಸಬಹುದು.',
            malayalam: 'അംഗീകാരം ലഭിച്ചാൽ സംഘം അത് മെച്ചപ്പെടുത്തി ബന്ധപ്പെട്ട വിഭാഗത്തിൽ പ്രസിദ്ധീകരിക്കാം.',
          ),
        ],
      ),
      _CommunityInstructionSectionData(
        title: strings.localized(
          telugu: 'ఏవి ఆమోదించబడతాయి',
          english: 'What can be approved',
          hindi: 'क्या स्वीकृत हो सकता है',
          tamil: 'எவை அங்கீகரிக்கப்படலாம்',
          kannada: 'ಯಾವುದು ಅನುಮೋದನೆ ಪಡೆಯಬಹುದು',
          malayalam: 'എന്തൊക്കെ അംഗീകരിക്കാം',
        ),
        bullets: <String>[
          strings.localized(
            telugu: 'ఎంచుకున్న విభాగానికి సరిపోయే పరిశుభ్రమైన సూక్తి లేదా చిత్రం.',
            english: 'Clean quote or image that matches the selected category.',
            hindi: 'चुनी हुई श्रेणी से मेल खाने वाला साफ सुविचार या चित्र।',
            tamil: 'தேர்ந்தெடுத்த பிரிவிற்கு பொருந்தும் தெளிவான மேற்கோள் அல்லது படம்.',
            kannada: 'ಆಯ್ದ ವಿಭಾಗಕ್ಕೆ ಹೊಂದುವ ಸ್ವಚ್ಛವಾದ ಉಲ್ಲೇಖ ಅಥವಾ ಚಿತ್ರ.',
            malayalam: 'തിരഞ്ഞെടുത്ത വിഭാഗത്തിന് ചേരുന്ന ശുദ്ധമായ ഉദ്ധരണി അല്ലെങ്കിൽ ചിത്രം.',
          ),
          strings.localized(
            telugu: 'మీరు స్వయంగా సృష్టించినది లేదా ఉపయోగించడానికి మీకు అనుమతి ఉన్న విషయం.',
            english: 'Content created by you or content you have permission to use.',
            hindi: 'आपके द्वारा बनाई गई सामग्री या जिसके उपयोग की अनुमति आपके पास है।',
            tamil: 'நீங்கள் உருவாக்கியது அல்லது பயன்படுத்த அனுமதி உள்ள உள்ளடக்கம்.',
            kannada: 'ನೀವು ರಚಿಸಿದುದು ಅಥವಾ ಬಳಸಲು ನಿಮಗೆ ಅನುಮತಿ ಇರುವ ವಿಷಯ.',
            malayalam: 'നിങ്ങൾ സൃഷ്ടിച്ചതോ ഉപയോഗിക്കാൻ അനുമതിയുള്ളതോ ആയ ഉള്ളടക്കം.',
          ),
          strings.localized(
            telugu: 'ప్రచురించిన తర్వాత అది మీకూ, ఆ విభాగంలోని వినియోగదారులకూ కనిపించవచ్చు.',
            english: 'After publishing, it may be visible to you and all users in that category.',
            hindi: 'प्रकाशित होने के बाद वह आपको और उस श्रेणी के उपयोगकर्ताओं को दिखाई दे सकता है।',
            tamil: 'வெளியிடப்பட்ட பிறகு அது உங்களுக்கும் அந்த பிரிவின் பயனர்களுக்கும் தெரியலாம்.',
            kannada: 'ಪ್ರಕಟಿಸಿದ ನಂತರ ಅದು ನಿಮಗೂ ಆ ವಿಭಾಗದ ಬಳಕೆದಾರರಿಗೂ ಕಾಣಿಸಬಹುದು.',
            malayalam: 'പ്രസിദ്ധീകരിച്ചതിന് ശേഷം അത് നിങ്ങളും ആ വിഭാഗത്തിലെ ഉപയോക്താക്കളും കാണാനിടയുണ്ട്.',
          ),
        ],
      ),
      _CommunityInstructionSectionData(
        title: strings.localized(
          telugu: 'తిరస్కరణకు కారణాలు',
          english: 'Rejection reasons',
          hindi: 'अस्वीकृति के कारण',
          tamil: 'நிராகரிப்பு காரணங்கள்',
          kannada: 'ತಿರಸ್ಕಾರದ ಕಾರಣಗಳು',
          malayalam: 'നിരസിക്കുന്നതിനുള്ള കാരണങ്ങൾ',
        ),
        bullets: <String>[
          strings.localized(
            telugu: 'తప్పు విభాగం, సంబంధం లేని విషయం, నకిలీ విషయం లేదా నాణ్యత తక్కువగా ఉన్న చిత్రం.',
            english: 'Wrong category, unrelated content, duplicate, or low quality image.',
            hindi: 'गलत श्रेणी, असंबंधित सामग्री, दोहराई गई सामग्री या कम गुणवत्ता वाली छवि।',
            tamil: 'தவறான பிரிவு, தொடர்பில்லாத உள்ளடக்கம், நகல் அல்லது குறைந்த தரமான படம்.',
            kannada: 'ತಪ್ಪು ವಿಭಾಗ, ಸಂಬಂಧವಿಲ್ಲದ ವಿಷಯ, ನಕಲಿ ಅಥವಾ ಕಡಿಮೆ ಗುಣಮಟ್ಟದ ಚಿತ್ರ.',
            malayalam: 'തെറ്റായ വിഭാഗം, ബന്ധമില്ലാത്ത ഉള്ളടക്കം, പകർപ്പ് അല്ലെങ്കിൽ കുറഞ്ഞ നിലവാരത്തിലുള്ള ചിത്രം.',
          ),
          strings.localized(
            telugu: 'హక్కులు కలిగిన చిత్రం, కాపీ చేసిన సూక్తి, అభ్యంతరకరమైన లేదా తప్పుదారి పట్టించే విషయం.',
            english: 'Copyright image, copied quote, offensive, or misleading content.',
            hindi: 'कॉपीराइट वाली छवि, नकल किया गया सुविचार, आपत्तिजनक या भ्रामक सामग्री।',
            tamil: 'பதிப்புரிமை உள்ள படம், நகலெடுத்த மேற்கோள், அவமதிப்பான அல்லது தவறாக வழிநடத்தும் உள்ளடக்கம்.',
            kannada: 'ಹಕ್ಕುಸ್ವಾಮ್ಯ ಹೊಂದಿರುವ ಚಿತ್ರ, ನಕಲಿಸಿದ ಉಲ್ಲೇಖ, ಅವಮಾನಕಾರಿ ಅಥವಾ ತಪ್ಪು ದಾರಿಗೆಳೆಯುವ ವಿಷಯ.',
            malayalam: 'പകർപ്പവകാശമുള്ള ചിത്രം, പകർത്തിയ ഉദ്ധരണി, അപമാനകരമോ തെറ്റിദ്ധരിപ്പിക്കുന്നതോ ആയ ഉള്ളടക്കം.',
          ),
          strings.localized(
            telugu: 'వ్యక్తిగత వివరాలు, రాజకీయ దుర్వినియోగం, అవాంఛిత ప్రచారం లేదా సురక్షితం కాని విషయం.',
            english: 'Private details, political misuse, spam, or unsafe content.',
            hindi: 'निजी विवरण, राजनीतिक दुरुपयोग, अवांछित प्रचार या असुरक्षित सामग्री।',
            tamil: 'தனிப்பட்ட விவரங்கள், அரசியல் தவறான பயன்பாடு, தேவையற்ற விளம்பரம் அல்லது பாதுகாப்பற்ற உள்ளடக்கம்.',
            kannada: 'ಖಾಸಗಿ ವಿವರಗಳು, ರಾಜಕೀಯ ದುರುಪಯೋಗ, ಅನಗತ್ಯ ಪ್ರಚಾರ ಅಥವಾ ಸುರಕ್ಷಿತವಲ್ಲದ ವಿಷಯ.',
            malayalam: 'സ്വകാര്യ വിവരങ്ങൾ, രാഷ്ട്രീയ ദുരുപയോഗം, അനാവശ്യ പ്രചാരം അല്ലെങ്കിൽ സുരക്ഷിതമല്ലാത്ത ഉള്ളടക്കം.',
          ),
        ],
      ),
    ];
  }}

class _CommunityInstructionSectionData {
  const _CommunityInstructionSectionData({
    required this.title,
    required this.bullets,
  });

  final String title;
  final List<String> bullets;
}

class _CommunityInstructionSection extends StatelessWidget {
  const _CommunityInstructionSection({required this.section});

  final _CommunityInstructionSectionData section;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final bullet in section.bullets) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFD81B60),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.38,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (!identical(bullet, section.bullets.last))
                const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadCategorySelectionScreen extends StatelessWidget {
  const _UploadCategorySelectionScreen({
    required this.options,
    required this.selectedCategoryId,
  });

  final List<_UploadCategoryOption> options;
  final String selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: const BackButton(),
        title: Text(
          strings.localized(
            telugu: 'విభాగం ఎంచుకోండి',
            english: 'Select Category',
          ),
        ),
      ),
      body: GradientShell(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: options.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option.id == selectedCategoryId;
            return OnboardingSurfaceCard(
              maxWidth: 520,
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(option),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              option.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (option.eventDateLabel
                                case final String eventDate)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  eventDate,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF64748B),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? const Color(0xFFD81B60)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
