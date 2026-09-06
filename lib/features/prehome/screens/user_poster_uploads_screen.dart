import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import 'package:mana_poster/app/config/category_display_helper.dart';
import 'package:mana_poster/app/config/home_category_catalog.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/user_poster_upload.dart';
import 'package:mana_poster/features/prehome/screens/subscription_plan_screen.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_category_service.dart';
import 'package:mana_poster/features/prehome/services/dynamic_event_schedule_service.dart';
import 'package:mana_poster/features/prehome/services/poster_downloads_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
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

class _ApprovedTemplatePayload {
  const _ApprovedTemplatePayload({
    required this.template,
    required this.profile,
  });

  final ApprovedCreatorTemplate? template;
  final PosterProfileData profile;
}

class ApprovedUploadPosterRenderData {
  const ApprovedUploadPosterRenderData({
    required this.upload,
    required this.template,
    required this.profile,
    required this.language,
  });

  final UserPosterUpload upload;
  final ApprovedCreatorTemplate template;
  final PosterProfileData profile;
  final AppLanguage language;
}

typedef ApprovedUploadPosterBuilder =
    Widget Function(BuildContext context, ApprovedUploadPosterRenderData data);

class _ApprovedUploadPosterCard extends StatefulWidget {
  const _ApprovedUploadPosterCard({
    required this.upload,
    required this.language,
    required this.approvedPosterBuilder,
  });

  final UserPosterUpload upload;
  final AppLanguage language;
  final ApprovedUploadPosterBuilder? approvedPosterBuilder;

  @override
  State<_ApprovedUploadPosterCard> createState() =>
      _ApprovedUploadPosterCardState();
}

class _ApprovedUploadPosterCardState extends State<_ApprovedUploadPosterCard> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();
  final SubscriptionBackendService _subscriptionService =
      SubscriptionBackendService.app();
  final CloudFirstBackgroundRemovalService _backgroundRemovalService =
      const CloudFirstBackgroundRemovalService();
  Future<_ApprovedTemplatePayload>? _payloadFuture;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  double? _imageAspectRatio;
  String? _busyAction;
  String? _extraPhotoPath;

  @override
  void initState() {
    super.initState();
    _payloadFuture = _loadPayload();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _ApprovedUploadPosterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.upload.approvedPosterTemplateId !=
            widget.upload.approvedPosterTemplateId ||
        oldWidget.upload.imageUrl != widget.upload.imageUrl ||
        oldWidget.upload.updatedAtMillis != widget.upload.updatedAtMillis) {
      _payloadFuture = _loadPayload();
      _resolveAspectRatio();
    }
  }

  @override
  void dispose() {
    _detachImageStream();
    super.dispose();
  }

  Future<_ApprovedTemplatePayload> _loadPayload() async {
    final profile = await PosterProfileService.load();
    final posterId = widget.upload.approvedPosterTemplateId.trim();
    if (posterId.isEmpty) {
      return _ApprovedTemplatePayload(template: null, profile: profile);
    }
    try {
      final template = await ApprovedCreatorTemplateService()
          .fetchTemplateById(posterId, forceServer: true)
          .timeout(const Duration(seconds: 8));
      return _ApprovedTemplatePayload(template: template, profile: profile);
    } catch (error, stackTrace) {
      developer.log(
        'approved upload template load failed: $error',
        name: 'UserPosterUploadsScreen',
        stackTrace: stackTrace,
      );
      return _ApprovedTemplatePayload(template: null, profile: profile);
    }
  }

  String _imageUrl(ApprovedCreatorTemplate? template) {
    return (template?.imageUrl.trim().isNotEmpty == true
            ? template!.imageUrl
            : template?.thumbnailUrl.trim().isNotEmpty == true
            ? template!.thumbnailUrl
            : widget.upload.imageUrl)
        .trim();
  }

  CreatorPosterPersonalization _personalization(
    ApprovedCreatorTemplate? template,
  ) {
    return template?.personalizationConfig ??
        CreatorPosterPersonalization.defaults;
  }

  void _detachImageStream() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _resolveAspectRatio([ApprovedCreatorTemplate? template]) {
    _detachImageStream();
    final configured = template?.pageConfig?.aspectRatio;
    if (configured != null && configured.isFinite && configured > 0) {
      _imageAspectRatio = configured;
      return;
    }
    final url = _imageUrl(template);
    if (url.isEmpty) {
      _imageAspectRatio = 1.0;
      return;
    }
    final provider = NetworkImage(url);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final width = info.image.width;
      final height = info.image.height;
      if (!mounted || width <= 0 || height <= 0) {
        return;
      }
      setState(() => _imageAspectRatio = width / height);
      _detachImageStream();
    }, onError: (_, _) => _detachImageStream());
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  Future<bool> _ensureSubscriptionAccess() async {
    final cached = _subscriptionService.cachedEntitlement;
    if (cached?.hasAccess == true || cached?.isPro == true) {
      return true;
    }
    final result = await _subscriptionService.fetchEntitlement(
      forceRefresh: true,
    );
    if (result.hasAccess || result.isPro) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SubscriptionPlanScreen(startPurchaseOnOpen: true),
      ),
    );
    final refreshed = await _subscriptionService.fetchEntitlement(
      forceRefresh: true,
    );
    return refreshed.hasAccess || refreshed.isPro;
  }

  Future<String?> _capturePosterFile() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final bytes = await _screenshotController.capture(pixelRatio: 3);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}'
        'mana_approved_upload_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (error, stackTrace) {
      developer.log(
        'approved upload capture failed: $error',
        name: 'UserPosterUploadsScreen',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _download() async {
    if (_busyAction != null || !await _ensureSubscriptionAccess()) {
      return;
    }
    setState(() => _busyAction = 'download');
    try {
      final path = await _capturePosterFile();
      if (path == null) {
        return;
      }
      final result = await MediaExportService.saveImageFileToGalleryDetailed(
        path,
        fileName: 'mana_poster_${widget.upload.id}.png',
      );
      if (result.success) {
        unawaited(
          PosterDownloadsService.recordCopyFromFile(
            path,
            suggestedFileName: 'mana_poster_${widget.upload.id}.png',
          ),
        );
        unawaited(
          UserPosterUploadsService.instance
              .incrementApprovedContributionCountForPoster(
                approvedPosterTemplateId:
                    widget.upload.approvedPosterTemplateId,
                isShare: false,
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _share() async {
    if (_busyAction != null || !await _ensureSubscriptionAccess()) {
      return;
    }
    setState(() => _busyAction = 'share');
    try {
      final path = await _capturePosterFile();
      if (path == null || !mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await MediaExportService.shareImageFile(
        path,
        text:
            'Shared using ${AppPublicInfo.appName}\n${AppPublicInfo.playStoreUrl}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      unawaited(
        UserPosterUploadsService.instance
            .incrementApprovedContributionCountForPoster(
              approvedPosterTemplateId: widget.upload.approvedPosterTemplateId,
              isShare: true,
            ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<String?> _pickAndPreparePhoto(String prefix) async {
    final cropTitle = context.strings.localized(
      telugu: 'ఫోటో కత్తిరించండి',
      english: 'Crop Photo',
      hindi: 'फ़ोटो क्रॉप करें',
      tamil: 'புகைப்படத்தை செதுக்கு',
      kannada: 'ಫೋಟೋ ಕ್ರಾಪ್ ಮಾಡಿ',
      malayalam: 'ഫോട്ടോ ക്രോപ്പ് ചെയ്യുക',
      marathi: 'फोटो क्रॉप करा',
      gujarati: 'ફોટો ક્રોપ કરો',
      bengali: 'ছবি ক্রপ করুন',
      punjabi: 'ਫੋਟੋ ਕੱਟੋ',
      odia: 'ଫଟୋ କ୍ରପ୍ କରନ୍ତୁ',
      assamese: 'ফটো ক্ৰপ কৰক',
      konkani: 'फोटो क्रॉप करा',
      nepali: 'फोटो क्रप गर्नुहोस्',
      meitei: 'ফোতো ক্রপ তৌবীয়ু',
      mizo: 'Thlalak tan rawh',
      kashmiri: 'فوٹو کٹ کرِو',
      ladakhi: 'པར་བཅད་ཏེ་བཟོས།',
    );
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return null;
    }
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressFormat: ImageCompressFormat.png,
      compressQuality: 100,
      uiSettings: <PlatformUiSettings>[
        AndroidUiSettings(
          toolbarTitle: cropTitle,
          toolbarColor: const Color(0xFF0F172A),
          toolbarWidgetColor: Colors.white,
          backgroundColor: const Color(0xFF0F172A),
          activeControlsWidgetColor: const Color(0xFF2563EB),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: cropTitle, aspectRatioLockEnabled: false),
      ],
    );
    if (cropped == null) {
      return null;
    }
    final sourceBytes = await File(cropped.path).readAsBytes();
    Uint8List outputBytes = sourceBytes;
    try {
      await _backgroundRemovalService.ensureReady();
      final removed = await _backgroundRemovalService
          .removeBackground(sourceBytes)
          .timeout(const Duration(seconds: 25));
      outputBytes = removed.pngBytes;
    } catch (_) {
      outputBytes = sourceBytes;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(outputBytes, flush: true);
    return file.path;
  }

  Future<void> _pickExtraPhoto() async {
    if (_busyAction != null) {
      return;
    }
    setState(() => _busyAction = 'photo');
    try {
      final path = await _pickAndPreparePhoto('approved_upload_extra_photo');
      if (path != null && mounted) {
        setState(() => _extraPhotoPath = path);
      }
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String action,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final busy = _busyAction == action;
    return FilledButton.icon(
      onPressed: _busyAction == null ? onPressed : null,
      icon: busy
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _posterStage({
    required String imageUrl,
    required CreatorPosterPersonalization personalization,
    required double aspectRatio,
  }) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final extraSize =
              width *
              (personalization.videoExtraPhotoScale / 100).clamp(0.08, 0.7);
          final extraLeft =
              width * (personalization.videoExtraPhotoX / 100).clamp(0.0, 1.0) -
              extraSize / 2;
          final extraTop =
              height *
                  (personalization.videoExtraPhotoY / 100).clamp(0.0, 1.0) -
              extraSize / 2;
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: <Widget>[
              DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
              if (personalization.showVideoExtraPhoto)
                Positioned(
                  left: extraLeft,
                  top: extraTop,
                  width: extraSize,
                  height: extraSize,
                  child: GestureDetector(
                    onTap: _pickExtraPhoto,
                    child: ClipOval(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _extraPhotoPath == null
                            ? const Icon(Icons.add_a_photo_rounded)
                            : Image.file(
                                File(_extraPhotoPath!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ApprovedTemplatePayload>(
      future: _payloadFuture,
      builder: (context, snapshot) {
        final template = snapshot.data?.template;
        final profile = snapshot.data?.profile;
        final imageUrl = _imageUrl(template);
        if (imageUrl.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (imageUrl.isEmpty) {
          return Text(
            context.strings.localized(
              telugu: 'ఆమోదించబడిన పోస్టర్ సిద్ధం చేయబడుతోంది.',
              english: 'Approved poster is being prepared.',
              hindi: 'स्वीकृत पोस्टर तैयार किया जा रहा है।',
              tamil: 'அங்கீகரிக்கப்பட்ட போஸ்டர் தயாராகிறது.',
              kannada: 'ಅನುಮೋದಿತ ಪೋಸ್ಟರ್ ಸಿದ್ಧವಾಗುತ್ತಿದೆ.',
              malayalam: 'അംഗീകരിച്ച പോസ്റ്റർ തയ്യാറാക്കുന്നു.',
              marathi: 'मंजूर केलेले पोस्टर तयार केले जात आहे.',
              gujarati: 'મંજૂર કરેલ પોસ્ટર તૈયાર થઈ રહ્યું છે.',
              bengali: 'অনুমোদিত পোস্টার তৈরি করা হচ্ছে।',
              punjabi: 'ਮਨਜ਼ੂਰ ਕੀਤਾ ਪੋਸਟਰ ਤਿਆਰ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ।',
              odia: 'ଅନୁମୋଦିତ ପୋଷ୍ଟର ପ୍ରସ୍ତୁତ କରାଯାଉଛି।',
              assamese: 'অনুমোদিত পোষ্টাৰ প্ৰস্তুত কৰা হৈছে।',
              konkani: 'मान्यता मेळिल्लो पोस्टर तयार जाता.',
              nepali: 'स्वीकृत पोस्टर तयार गरिँदै छ।',
              meitei: 'য়ারেবা পোস্তর শেম-শারি।',
              mizo: 'Poster pawm tawh buatsaih mek a ni.',
              kashmiri: 'منظور شدہ پوسٹر چھُ تیار گژھان۔',
              ladakhi: 'བཀའ་འཁྲོལ་ཐོབ་པའི་པོ་སི་ཊར་བཟོ་བཞིན་ཡོད།',
            ),
          );
        }
        if (template != null && _imageAspectRatio == null) {
          _resolveAspectRatio(template);
        }
        final ratio =
            (_imageAspectRatio != null &&
                _imageAspectRatio!.isFinite &&
                _imageAspectRatio! > 0)
            ? _imageAspectRatio!
            : (template?.pageConfig?.aspectRatio ?? 1.0);
        final safeRatio = ratio.isFinite && ratio > 0 ? ratio : 1.0;
        final personalization = _personalization(template);
        final approvedPosterBuilder = widget.approvedPosterBuilder;
        if (approvedPosterBuilder != null &&
            template != null &&
            profile != null) {
          return approvedPosterBuilder(
            context,
            ApprovedUploadPosterRenderData(
              upload: widget.upload,
              template: template,
              profile: profile,
              language: widget.language,
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Screenshot(
              controller: _screenshotController,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _posterStage(
                  imageUrl: imageUrl,
                  personalization: personalization,
                  aspectRatio: safeRatio,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _actionButton(
                    icon: Icons.ios_share_rounded,
                    label: context.strings.localized(
                      telugu: 'Share',
                      english: 'Share',
                      hindi: 'Share',
                      tamil: 'Share',
                      kannada: 'Share',
                      malayalam: 'Share',
                      marathi: 'Share',
                      gujarati: 'Share',
                      bengali: 'Share',
                      punjabi: 'Share',
                      odia: 'Share',
                      assamese: 'Share',
                      konkani: 'Share',
                      nepali: 'Share',
                      meitei: 'Share',
                      mizo: 'Share',
                      kashmiri: 'Share',
                      ladakhi: 'Share',
                    ),
                    action: 'share',
                    color: const Color(0xFF25D366),
                    onPressed: () => unawaited(_share()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: Icons.download_rounded,
                    label: context.strings.localized(
                      telugu: 'Download',
                      english: 'Download',
                      hindi: 'Download',
                      tamil: 'Download',
                      kannada: 'Download',
                      malayalam: 'Download',
                      marathi: 'Download',
                      gujarati: 'Download',
                      bengali: 'Download',
                      punjabi: 'Download',
                      odia: 'Download',
                      assamese: 'Download',
                      konkani: 'Download',
                      nepali: 'Download',
                      meitei: 'Download',
                      mizo: 'Download',
                      kashmiri: 'Download',
                      ladakhi: 'Download',
                    ),
                    action: 'download',
                    color: const Color(0xFF64748B),
                    onPressed: () => unawaited(_download()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class UserPosterUploadsScreen extends StatefulWidget {
  const UserPosterUploadsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.profileOnly = false,
    this.approvedPosterBuilder,
  });

  final int initialTabIndex;
  final bool profileOnly;
  final ApprovedUploadPosterBuilder? approvedPosterBuilder;

  @override
  State<UserPosterUploadsScreen> createState() =>
      _UserPosterUploadsScreenState();
}

bool _isExpectedPickerException(PlatformException error) {
  return error.code == 'already_active' ||
      error.code == 'camera_access_denied' ||
      error.code == 'photo_access_denied' ||
      error.code == 'photo_access_denied_permanently';
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
    for (
      var index = 0;
      index < HomeCategoryCatalog.all.length && index < staticLabels.length;
      index += 1
    ) {
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
      hindi: 'इवेंट की तारीख: $formatted',
      tamil: 'நிகழ்வு தேதி: $formatted',
      kannada: 'ಕಾರ್ಯಕ್ರಮ ದಿನಾಂಕ: $formatted',
      malayalam: 'ഇവന്റ് തീയതി: $formatted',
      marathi: 'इव्हेंट तारीख: $formatted',
      gujarati: 'ઇવેન્ટ તારીખ: $formatted',
      bengali: 'ইভেন্টের তারিখ: $formatted',
      punjabi: 'ਇਵੈਂਟ ਮਿਤੀ: $formatted',
      odia: 'ଇଭେଣ୍ଟ ତାରିଖ: $formatted',
      assamese: 'অনুষ্ঠানৰ তাৰিখ: $formatted',
      konkani: 'कार्यावळ तारीख: $formatted',
      nepali: 'कार्यक्रम मिति: $formatted',
      meitei: 'থৌরমগী তাং: $formatted',
      mizo: 'Huna thil thlen hun: $formatted',
      kashmiri: 'تقریبچ تٲریخ: $formatted',
      ladakhi: 'མཛད་སྒོའི་ཚེས་གྲངས: $formatted',
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
              hindi: 'क्या इस आइटम को छिपाएं?',
              tamil: 'இந்த உருப்படியை மறைக்கவா?',
              kannada: 'ಈ ಅಂಶವನ್ನು ಮರೆಮಾಡಬೇಕೇ?',
              malayalam: 'ഈ ഇനം മറയ്ക്കണോ?',
              marathi: 'हा आयटम लपवायचा का?',
              gujarati: 'આ આઇટમ છુપાવવી છે?',
              bengali: 'এই আইটেমটি লুকাবেন?',
              punjabi: 'ਕੀ ਇਸ ਆਈਟਮ ਨੂੰ ਲੁਕਾਉਣਾ ਹੈ?',
              odia: 'ଏହି ଆଇଟମ୍ ଲୁଚାଇବେ କି?',
              assamese: 'এই বস্তুটো লুকুৱাবনে?',
              konkani: 'ही वस्त लिपवंची?',
              nepali: 'यो वस्तु लुकाउने?',
              meitei: 'মসিগী পোৎলমসি লোৎকদ্রা?',
              mizo: 'He thil hi thup tur em ni?',
              kashmiri: 'کیا یہ چُھ چھپاوُن؟',
              ladakhi: 'དངོས་པོ་འདི་སྦ་དགོས་སམ།',
            ),
          ),
          content: Text(
            strings.localized(
              telugu:
                  'ఇది మీ అప్‌లోడ్‌ల జాబితా నుండి మాత్రమే తొలగుతుంది. ఇతర వినియోగదారుల కోసం ఇది తొలగించబడదు.',
              english:
                  'This will be removed only from your My Uploads list. It will not be deleted for other users.',
              hindi:
                  'यह केवल आपकी My Uploads सूची से हटेगा। अन्य उपयोगकर्ताओं के लिए नहीं हटाया जाएगा।',
              tamil:
                  'இது உங்கள் My Uploads பட்டியலிலிருந்து மட்டுமே நீக்கப்படும். பிற பயனர்களுக்கு நீக்கப்படாது.',
              kannada:
                  'ಇದು ನಿಮ್ಮ My Uploads ಪಟ್ಟಿಯಿಂದ ಮಾತ್ರ ತೆಗೆದುಹಾಕಲ್ಪಡುತ್ತದೆ. ಇತರ ಬಳಕೆದಾರರಿಗೆ ಅಳಿಸಲಾಗುವುದಿಲ್ಲ.',
              malayalam:
                  'ഇത് നിങ്ങളുടെ My Uploads ലിസ്റ്റിൽ നിന്ന് മാത്രമേ ഒഴിവാക്കൂ. മറ്റ് ഉപയോക്താക്കൾക്കായി ഇല്ലാതാക്കില്ല.',
              marathi:
                  'हे केवळ तुमच्या My Uploads सूचीमधून काढले जाईल. इतर वापरकर्त्यांसाठी हटवले जाणार नाही.',
              gujarati:
                  'આ ફક્ત તમારી My Uploads સૂચિમાંથી દૂર કરવામાં આવશે. અન્ય વપરાશકર્તાઓ માટે કાઢી નાખવામાં આવશે નહીં.',
              bengali:
                  'এটি কেবল আপনার My Uploads তালিকা থেকে সরানো হবে। অন্য ব্যবহারকারীদের জন্য মোছা হবে না।',
              punjabi:
                  'ਇਹ ਸਿਰਫ਼ ਤੁਹਾਡੀ My Uploads ਸੂਚੀ ਵਿੱਚੋਂ ਹਟਾਇਆ ਜਾਵੇਗਾ। ਹੋਰ ਵਰਤੋਂਕਾਰਾਂ ਲਈ ਨਹੀਂ ਮਿਟਾਇਆ ਜਾਵੇਗਾ।',
              odia:
                  'ଏହା କେବଳ ଆପଣଙ୍କ My Uploads ତାଲିକାରୁ ହଟାଯିବ। ଅନ୍ୟ ୟୁଜର୍ସଙ୍କ ପାଇଁ ଡିଲିଟ୍ ହେବ ନାହିଁ।',
              assamese:
                  'এইটো কেৱল আপোনাৰ My Uploads তালিকাৰ পৰা আঁতৰোৱা হ’ব। আন ব্যৱহাৰকাৰীৰ বাবে ডিলিট কৰা নহ’ব।',
              konkani:
                  'हें फक्त तुमच्या My Uploads वळेरेंतल्यान काडटले. हेर वापरप्यां खातीर काडचें ना.',
              nepali:
                  'यो केवल तपाईंको My Uploads सूचीबाट हटाइनेछ। अन्य प्रयोगकर्ताहरूका लागि मेटाइने छैन।',
              meitei:
                  'মসি নহাক্কী My Uploads লিস্ততগীখক লৌথোক্কনি। অতোপ্পশিংগীদমক মুথৎলোই।',
              mizo:
                  'Hei hi i My Uploads list atang chauhva paih a ni ang. Mi dang tan paih a ni lo ang.',
              kashmiri:
                  'یہ یِیہہ صرف تُہندِ My Uploads فہرست منٛزٕ کڑنہٕ۔ باقین خٲطرٕ نہٕ کڑنہٕ۔',
              ladakhi:
                  'འདི་ཁྱེད་ཀྱི་ My Uploads ཐོ་ནས་མ་གཏོགས་བསུབ་མི་སྲིད། གཞན་གྱི་ཆེད་དུ་བསུབ་མི་ཐུབ།',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                strings.localized(
                  telugu: 'రద్దు',
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
                  konkani: 'रद्द करा',
                  nepali: 'रद्द गर्नुहोस्',
                  meitei: 'তৌদবা',
                  mizo: 'Sutna',
                  kashmiri: 'منسوخ',
                  ladakhi: 'ཕྱིར་འཐེན།',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                strings.localized(
                  telugu: 'డిలీట్',
                  english: 'Delete',
                  hindi: 'हटाएं',
                  tamil: 'நீக்கு',
                  kannada: 'ಅಳಿಸಿ',
                  malayalam: 'ഡിലീറ്റ് ചെയ്യുക',
                  marathi: 'हटवा',
                  gujarati: 'કાઢી નાખો',
                  bengali: 'মুছে ফেলুন',
                  punjabi: 'ਮਿਟਾਓ',
                  odia: 'ଡିଲିଟ୍ କରନ୍ତୁ',
                  assamese: 'ডিলিট কৰক',
                  konkani: 'काडून उडोवचें',
                  nepali: 'हटाउनुहोस्',
                  meitei: 'মুথৎপা',
                  mizo: 'Paihna',
                  kashmiri: 'مِٹٲوِو',
                  ladakhi: 'བསུབ་པ།',
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
            telugu: 'ఈ ఐటమ్ మీ లిస్ట్ నుంచి తొలగించబడింది',
            english: 'This item was removed from your list',
            hindi: 'यह आइटम आपकी सूची से हटा दिया गया है',
            tamil: 'இந்த உருப்படி உங்கள் பட்டியலிலிருந்து நீக்கப்பட்டது',
            kannada: 'ಈ ಅಂಶವನ್ನು ನಿಮ್ಮ ಪಟ್ಟಿಯಿಂದ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
            malayalam: 'ഈ ഇനം നിങ്ങളുടെ ലിസ്റ്റിൽ നിന്ന് നീക്കംചെയ്തു',
            marathi: 'हा आयटम तुमच्या सूचीमधून काढला गेला आहे',
            gujarati: 'આ આઇટમ તમારી સૂચિમાંથી દૂર કરવામાં આવી છે',
            bengali: 'এই আইটেমটি আপনার তালিকা থেকে সরানো হয়েছে',
            punjabi: 'ਇਹ ਆਈਟਮ ਤੁਹਾਡੀ ਸੂਚੀ ਵਿੱਚੋਂ ਹਟਾ ਦਿੱਤੀ ਗਈ ਹੈ',
            odia: 'ଏହି ଆଇଟମ୍ ଆପଣଙ୍କ ତାଲିକାରୁ ହଟାଯାଇଛି',
            assamese: 'এই বস্তুটো আপোনাৰ তালিকাৰ পৰা আঁতৰোৱা হ’ল',
            konkani: 'ही वस्त तुमच्या वळेरेंतल्यान काडली',
            nepali: 'यो वस्तु तपाईंको सूचीबाट हटाइयो',
            meitei: 'পোৎলমসি নহাক্কী লিস্ততগী লৌথোকখ্রে',
            mizo: 'He thil hi i list atanga paih a ni tawh',
            kashmiri: 'یہ چُھ تُہندِ فہرست منٛزٕ کڑنہٕ آمُت',
            ladakhi: 'དངོས་པོ་འདི་ཁྱེད་ཀྱི་ཐོ་ནས་ཕྱིར་བཏོན་ཟིན།',
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final strings = context.strings;
    final XFile? picked;
    try {
      picked = await _picker.pickImage(source: ImageSource.gallery);
    } on PlatformException catch (error) {
      if (!_isExpectedPickerException(error) && mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              strings.localized(
                telugu: 'చిత్రాన్ని ఎంచుకోలేకపోయాం',
                english: 'Could not select the image',
                hindi: 'छवि नहीं चुनी जा सकी',
                tamil: 'படத்தைத் தேர்ந்தெடுக்க முடியவில்லை',
                kannada: 'ಚಿತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ',
                malayalam: 'ചിത്രം തിരഞ്ഞെടുക്കാനായില്ല',
                marathi: 'प्रतिमा निवडता आली नाही',
                gujarati: 'છબી પસંદ કરી શકાઈ નથી',
                bengali: 'ছবি নির্বাচন করা যায়নি',
                punjabi: 'ਤਸਵੀਰ ਨਹੀਂ ਚੁਣੀ ਜਾ ਸਕੀ',
                odia: 'ଛବି ବାଛିବା ସମ୍ଭବ ହେଲାନାହିଁ',
                assamese: 'ছবি বাছনি কৰিব পৰা নগ’ল',
                konkani: 'चित्र वेंचून काडूंक जाಲೆಂ ना',
                nepali: 'तस्विर छनोट गर्न सकिएन',
                meitei: 'ফোতো খনব ঙমদে',
                mizo: 'Thlalak thlan theih a ni lo',
                kashmiri: 'تصویر ہیٚکہ نہٕ ژارِتھ',
                ladakhi: 'པར་འདེམས་མ་ཐུབ།',
              ),
            ),
          ),
        );
      }
      return;
    }
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
              telugu: 'అప్‌లోడ్ మొబైల్ యాప్‌లో మాత్రమే అందుబాటులో ఉంది',
              english: 'Upload is supported on mobile app only',
              hindi: 'अपलोड केवल मोबाइल ऐप पर उपलब्ध है',
              tamil: 'பதிவேற்றம் மொபைல் செயலியில் மட்டுமே கிடைக்கும்',
              kannada: 'ಅಪ್‌ಲೋಡ್ ಮೊಬೈಲ್ ಆ್ಯಪ್‌ನಲ್ಲಿ ಮಾತ್ರ ಲಭ್ಯವಿದೆ',
              malayalam: 'അപ്‌ലോഡ് മൊബൈൽ ആപ്പിൽ മാത്രമേ ലഭ്യമാകൂ',
              marathi: 'अपलोड केवळ मोबाइल ॲपवर उपलब्ध आहे',
              gujarati: 'અપલોડ ફક્ત મોબાઇલ ઍપ પર જ સમર્થિત છે',
              bengali: 'আপলোড কেবল মোবাইল অ্যাপে সমর্থিত',
              punjabi: 'ਅੱਪਲੋਡ ਸਿਰਫ਼ ਮੋਬਾਈਲ ਐਪ \'ਤੇ ਸਮਰਥਿਤ ਹੈ',
              odia: 'ଅପଲୋଡ୍ କେବଳ ମୋବାଇଲ୍ ଆପରେ ଉପଲବ୍ଧ',
              assamese: 'আপলোড কেৱল মোবাইল এপত সমৰ্থিত',
              konkani: 'अपलोड फक्त मोबाईल ॲपाचेर मेळटा',
              nepali: 'अपलोड मोबाइल एपमा मात्र उपलब्ध छ',
              meitei: 'অপলোদ অসি মোবাইল এপতখক য়াওই',
              mizo: 'Upload hi mobile app-ah chauh tih theih a ni',
              kashmiri: 'اپلوڈ چُھ صرف موبائل ایپَس پؠٹھ مُمکن',
              ladakhi: 'ཡར་འཇུག་འདི་ལག་ཐོགས་ཁ་པར་ནང་ལས་རྐྱང་པ་ཡིན།',
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
              telugu: 'చిత్ర పరిమాణం 500KB లేదా దానికంటే తక్కువ ఉండాలి',
              english: 'Image size must be 500KB or less',
              hindi: 'छवि का आकार 500KB या उससे कम होना चाहिए',
              tamil:
                  'படத்தின் அளவு 500KB அல்லது அதற்கும் குறைவாக இருக்க வேண்டும்',
              kannada: 'ಚಿತ್ರದ ಗಾತ್ರವು 500KB ಅಥವಾ ಅದಕ್ಕಿಂತ ಕಡಿಮೆ ಇರಬೇಕು',
              malayalam:
                  'ചിത്രത്തിന്റെ വലുപ്പം 500KB അല്ലെങ്കിൽ അതിൽ കുറവായിരിക്കണം',
              marathi: 'प्रतिमेचा आकार 500KB किंवा त्यापेक्षा कमी असावा',
              gujarati: 'છબીનું કદ 500KB અથવા તેનાથી ઓછું હોવું આવશ્યક છે',
              bengali: 'ছবির আকার অবশ্যই ৫০০ কেবি বা তার কম হতে হবে',
              punjabi: 'ਤਸਵੀਰ ਦਾ ਆਕਾਰ 500KB ਜਾਂ ਇਸ ਤੋਂ ਘੱਟ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ',
              odia: 'ଛବିର ଆକାର ୫୦୦KB କିମ୍ବା ତା\'ଠାରୁ କମ୍ ହେବା ଉଚିତ',
              assamese: 'ছবিৰ আকাৰ ৫০০কেবি বা তাতকৈ কম হ’ব লাগিব',
              konkani: 'चित्राचो आकार 500KB वा ताचे परस उणो आसचो',
              nepali: 'तस्विरको आकार ५००केबी वा कम हुनुपर्छ',
              meitei: 'ফোতোগী চাউবগী চাং 500KB নত্রগা মদগী তাবা ওইগদবনি',
              mizo: 'Thlalak len zawng hi 500KB aia te a ni tur a ni',
              kashmiri: 'تصویرُک سائز پَزِ 500KB یا تمِہ کھۄتہٕ کم آسُن',
              ladakhi: 'པར་གྱི་ཚད་ 500KB ཡང་ན་དེ་ལས་ཉུང་བ་དགོས།',
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
              telugu: 'దయచేసి చిత్రం ఎంచుకోండి లేదా సూక్తి రాయండి',
              english: 'Please select an image or write a quote',
              hindi: 'कृपया एक छवि चुनें या एक सुविचार लिखें',
              tamil:
                  'தயவுசெய்து ஒரு படத்தைத் தேர்ந்தெடுக்கவும் அல்லது மேற்கோளை எழுதவும்',
              kannada: 'ದಯವಿಟ್ಟು ಚಿತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ ಅಥವಾ ಉಲ್ಲೇಖವನ್ನು ಬರೆಯಿರಿ',
              malayalam:
                  'ദയവായി ഒരു ചിത്രം തിരഞ്ഞെടുക്കുക അല്ലെങ്കിൽ ഒരു ഉദ്ധരണി എഴുതുക',
              marathi: 'कृपया एक प्रतिमा निवडा किंवा विचार लिहा',
              gujarati: 'કૃપા કરીને છબી પસંદ કરો અથવા સુવિચાર લખો',
              bengali: 'অনুগ্রহ করে একটি ছবি নির্বাচন করুন বা একটি উক্তি লিখুন',
              punjabi: 'ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਤਸਵੀਰ ਚੁਣੋ ਜਾਂ ਇੱਕ ਵਿਚਾਰ ਲਿਖੋ',
              odia: 'ଦୟାକରି ଏକ ଛବି ବାଛନ୍ତୁ କିମ୍ବା ସୁବିଚାର ଲେଖନ୍ତୁ',
              assamese: 'অনুগ্ৰহ কৰি এখন ছবি বাছক বা এটা বাণী লিখক',
              konkani: 'उपकार करून चित्र वेंचून काढा वा विचार बरयात',
              nepali: 'कृपया तस्विर छान्नुहोस् वा सुविचार लेख्नुहोस्',
              meitei: 'চানবীদুনা ফোতো অমা খনবীয়ু নত্রগা ৱাফম অমা ইবীয়ু',
              mizo: 'Khawngaihin thlalak thlang rawh lehkha thu emaw ziak rawh',
              kashmiri: 'مہر Ships کٔرِتھ ژارِو اَکھ تصویر یا لؠکھِو اَکھ قول',
              ladakhi: 'སྐུ་མཁྱེན་པར་འདེམས་པའམ་གཏམ་དཔེ་ཞིག་བྲིས།',
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
              telugu: 'అప్‌లోడ్ రివ్యూ కోసం పంపబడింది',
              english: 'Upload submitted for review',
              hindi: 'अपलोड समीक्षा के लिए भेजा गया',
              tamil: 'பதிவேற்றம் ஆய்வுக்கு சமர்ப்பிக்கப்பட்டது',
              kannada: 'ಅಪ್‌ಲೋಡ್ ಅನ್ನು ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಲಾಗಿದೆ',
              malayalam: 'അപ്‌ലോഡ് പരിശോധനയ്ക്കായി സമർപ്പിച്ചു',
              marathi: 'अपलोड पुनरावलोकनासाठी पाठवले गेले',
              gujarati: 'અપલોડ સમીક્ષા માટે સબમિટ કર્યું',
              bengali: 'আপলোড পর্যালোচনার জন্য জমা দেওয়া হয়েছে',
              punjabi: 'ਅੱਪਲੋਡ ਸਮੀਖਿਆ ਲਈ ਜਮ੍ਹਾ ਕੀਤਾ ਗਿਆ',
              odia: 'ଅପଲୋଡ୍ ସମୀକ୍ଷା ପାଇଁ ପଠାଗଲା',
              assamese: 'আপলোড পৰ্যালোচনাৰ বাবে জমা দিয়া হ’ল',
              konkani: 'अपलोड तपासणी खातीर धाडलां',
              nepali: 'अपलोड समीक्षाको लागि पेश गरियो',
              meitei: 'য়েংশিন্নবগীদমক অপলোদ থাজিনখ্রে',
              mizo: 'Upload chu en dik tura thehluh a ni ta',
              kashmiri: 'اپلوڈ آو جانچ خٲطرٕ سوزنہٕ',
              ladakhi: 'ཡར་འཇུག་ཞིབ་བཤེར་ཆེད་དུ་བཏང་ཟིན།',
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
        hindi: 'स्वीकृत',
        tamil: 'அங்கீகரிக்கப்பட்டது',
        kannada: 'ಅನುಮೋದಿಸಲಾಗಿದೆ',
        malayalam: 'അംഗീകരിച്ചു',
        marathi: 'मंजूर',
        gujarati: 'મંજૂર',
        bengali: 'অনুমোদিত',
        punjabi: 'ਮਨਜ਼ੂਰ',
        odia: 'ଅନୁମୋଦିତ',
        assamese: 'অনুমোদিত',
        konkani: 'मान्यता मेळ्ळी',
        nepali: 'स्वीकृत',
        meitei: 'য়ারে',
        mizo: 'Pawm a ni',
        kashmiri: 'منظور',
        ladakhi: 'བཀའ་འཁྲོལ་ཐོབ།',
      );
    }
    if (upload.isRejected) {
      return strings.localized(
        telugu: 'తిరస్కరించబడింది',
        english: 'Rejected',
        hindi: 'अस्वीकृत',
        tamil: 'நிராகரிக்கப்பட்டது',
        kannada: 'ತಿರಸ್ಕರಿಸಲಾಗಿದೆ',
        malayalam: 'നിരസിച്ചു',
        marathi: 'नाकारले',
        gujarati: 'અસ્વીકાર્ય',
        bengali: 'প্রত্যাখ্যাত',
        punjabi: 'ਰੱਦ ਕੀਤਾ ਗਿਆ',
        odia: 'ପ୍ରତ୍ୟାଖ୍ୟାତ',
        assamese: 'প্ৰত্যাখ্যান কৰা হৈছে',
        konkani: 'नाकारलें',
        nepali: 'अस्वीकृत',
        meitei: 'য়াদে',
        mizo: 'Hnar a ni',
        kashmiri: 'مسترد',
        ladakhi: 'ཕྱིར་འཐེན་བྱས།',
      );
    }
    return strings.localized(
      telugu: 'పెండింగ్',
      english: 'Pending',
      hindi: 'लंबित',
      tamil: 'நிலுவையில் உள்ளது',
      kannada: 'ಬಾಕಿ ಇದೆ',
      malayalam: 'തീർപ്പുകൽപ്പിക്കാത്തത്',
      marathi: 'प्रलंबित',
      gujarati: 'બાકી',
      bengali: 'মুলতবি',
      punjabi: 'ਬਕਾਇਆ',
      odia: 'ବିଚାରାଧୀନ',
      assamese: 'বাকী আছে',
      konkani: 'उरिल्लें',
      nepali: 'विचाराधीन',
      meitei: 'লেমহৌরিবা',
      mizo: 'La ngaihtuah mek',
      kashmiri: 'زیرِ التوا',
      ladakhi: 'སྒུག་བཞིན་པ།',
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
          hindi: 'लॉगिन आवश्यक है',
          tamil: 'உள்நுழைவு தேவை',
          kannada: 'ಲಾಗಿನ್ ಅಗತ್ಯವಿದೆ',
          malayalam: 'ലോഗിൻ ആവശ്യമാണ്',
          marathi: 'लॉगिन आवश्यक आहे',
          gujarati: 'લૉગિન જરૂરી છે',
          bengali: 'লগইন প্রয়োজন',
          punjabi: 'ਲਾਗਇਨ ਲੋੜੀਂਦਾ ਹੈ',
          odia: 'ଲଗଇନ୍ ଆବଶ୍ୟକ',
          assamese: 'লগইন প্ৰয়োজন',
          konkani: 'लॉगिन जाय',
          nepali: 'लगइन आवश्यक छ',
          meitei: 'লগইন তৌবা মথৌ তাই',
          mizo: 'Luh a ngai',
          kashmiri: 'لاگ اِن ضۆروٗری',
          ladakhi: 'ནང་འཛུལ་དགོས།',
        );
      case UserPosterUploadSubmitCode.categoryRequired:
        return strings.localized(
          telugu: 'కేటగిరీ అవసరం',
          english: 'Category is required',
          hindi: 'श्रेणी आवश्यक है',
          tamil: 'பிரிவு தேவை',
          kannada: 'ವರ್ಗ ಅಗತ್ಯವಿದೆ',
          malayalam: 'വിഭാഗം ആവശ്യമാണ്',
          marathi: 'श्रेणी आवश्यक आहे',
          gujarati: 'શ્રેણી જરૂરી છે',
          bengali: 'বিভাগ প্রয়োজন',
          punjabi: 'ਸ਼੍ਰੇਣੀ ਲੋੜੀਂਦੀ ਹੈ',
          odia: 'ବିଭାଗ ଆବଶ୍ୟକ',
          assamese: 'শ্ৰেণী প্ৰয়োজন',
          konkani: 'वर्ग जाय',
          nepali: 'वर्ग आवश्यक छ',
          meitei: 'কাংলুপ মথৌ তাই',
          mizo: 'Pawl thlan a ngai',
          kashmiri: 'زمرٕ چُھ ضۆروٗری',
          ladakhi: 'སྡེ་ཚན་དགོས།',
        );
      case UserPosterUploadSubmitCode.contentRequired:
        return strings.localized(
          telugu: 'చిత్రం లేదా సూక్తి అవసరం',
          english: 'Image or quote is required',
          hindi: 'छवि या सुविचार आवश्यक है',
          tamil: 'படம் அல்லது மேற்கோள் தேவை',
          kannada: 'ಚಿತ್ರ ಅಥವಾ ಉಲ್ಲೇಖ ಅಗತ್ಯವಿದೆ',
          malayalam: 'ചിത്രം അല്ലെങ്കിൽ ഉദ്ധരണി ആവശ്യമാണ്',
          marathi: 'प्रतिमा किंवा विचार आवश्यक आहे',
          gujarati: 'છબી અથવા સુવિચાર જરૂરી છે',
          bengali: 'ছবি বা উক্তি প্রয়োজন',
          punjabi: 'ਤਸਵੀਰ ਜਾਂ ਵਿਚਾਰ ਲੋੜੀਂਦਾ ਹੈ',
          odia: 'ଛବି କିମ୍ବା ସୁବିଚାର ଆବଶ୍ୟକ',
          assamese: 'ছবি বা বাণী প্ৰয়োজন',
          konkani: 'चित्र वा विचार जाय',
          nepali: 'तस्विर वा सुविचार आवश्यक छ',
          meitei: 'ফোতো নত্রগা ৱাফম মথৌ তাই',
          mizo: 'Thlalak emaw thu emaw a ngai',
          kashmiri: 'تصویر یا قول چُھ ضۆروٗری',
          ladakhi: 'པར་ཡང་ན་གཏམ་དཔེ་དགོས།',
        );
      case UserPosterUploadSubmitCode.imageTooLarge:
        return strings.localized(
          telugu: 'చిత్ర పరిమాణం 500KB లేదా దానికంటే తక్కువ ఉండాలి',
          english: 'Image size must be 500KB or less',
          hindi: 'छवि का आकार 500KB या उससे कम होना चाहिए',
          tamil: 'படத்தின் அளவு 500KB அல்லது அதற்கும் குறைவாக இருக்க வேண்டும்',
          kannada: 'ಚಿತ್ರದ ಗಾತ್ರವು 500KB ಅಥವಾ ಅದಕ್ಕಿಂತ ಕಡಿಮೆ ಇರಬೇಕು',
          malayalam:
              'ചിത്രത്തിന്റെ വലുപ്പം 500KB അല്ലെങ്കിൽ അതിൽ കുറവായിരിക്കണം',
          marathi: 'प्रतिमेचा आकार 500KB किंवा त्यापेक्षा कमी असावा',
          gujarati: 'છબીનું કદ 500KB અથવા તેનાથી ઓછું હોવું આવશ્યક છે',
          bengali: 'ছবির আকার অবশ্যই ৫০০ কেবি বা তার কম হতে হবে',
          punjabi: 'ਤਸਵੀਰ ਦਾ ਆਕਾਰ 500KB ਜਾਂ ਇਸ ਤੋਂ ਘੱਟ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ',
          odia: 'ଛବିର ଆକାର ୫୦୦KB କିମ୍ବା ତା\'ଠାରୁ କମ୍ ହେବା ଉଚିତ',
          assamese: 'ছবিৰ আকাৰ ৫০০কেবি বা তাতকৈ কম হ’ব লাগিব',
          konkani: 'चित्राचो आकार 500KB वा ताचे परस उणो आसचो',
          nepali: 'तस्विरको आकार ५००केबी वा कम हुनुपर्छ',
          meitei: 'ফোতোগী চাউবগী চাং 500KB নত্রগা মদগী তাবা ওইগদবনি',
          mizo: 'Thlalak len zawng hi 500KB aia te a ni tur a ni',
          kashmiri: 'تصویرُک سائز پَزِ 500KB یا تمِہ کھۄتہٕ کم آسُن',
          ladakhi: 'པར་གྱི་ཚད་ 500KB ཡང་ན་དེ་ལས་ཉུང་བ་དགོས།',
        );
      case UserPosterUploadSubmitCode.quoteTooLong:
        return strings.localized(
          telugu: 'సూక్తి 600 అక్షరాల లోపు ఉండాలి',
          english: 'Quote must be 600 characters or less',
          hindi: 'सुविचार 600 अक्षरों से कम होना चाहिए',
          tamil: 'மேற்கோள் 600 எழுத்துகளுக்குள் இருக்க வேண்டும்',
          kannada: 'ಉಲ್ಲೇಖವು 600 ಅಕ್ಷರಗಳಿಗಿಂತ ಕಡಿಮೆ ಇರಬೇಕು',
          malayalam: 'ഉദ്ധരണി 600 പ്രതീകങ്ങളിൽ കുറവായിരിക്കണം',
          marathi: 'विचार 600 अक्षरांपेक्षा कमी असावा',
          gujarati: 'સુવિચાર 600 અક્ષરોથી ઓછો હોવો જોઈએ',
          bengali: 'উক্তিটি অবশ্যই ৬০০ অক্ষরের মধ্যে হতে হবে',
          punjabi: 'ਵਿਚਾਰ 600 ਅੱਖਰਾਂ ਤੋਂ ਘੱਟ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ',
          odia: 'ସୁବିଚାର ୬୦୦ ଅକ୍ଷର ମଧ୍ୟରେ ହେବା ଉଚିତ',
          assamese: 'বাণীটো ৬০০ আখৰৰ ভিতৰত হ’ব লাগিব',
          konkani: 'विचार 600 अक्षरां परस उणो आसचो',
          nepali: 'सुविचार ६०० अक्षर भन्दा कम हुनुपर्छ',
          meitei: 'ৱাফম অসি ময়েক 600 গী মনুংদা ওইগদবনি',
          mizo: 'Thu hi hawrawp 600 aia tlem a ni tur a ni',
          kashmiri: 'قول پَزِ 600 لَفزن منٛز آسُن',
          ladakhi: 'གཏམ་དཔེ་འདི་ཡི་གེ་ 600 ལས་ཉུང་བ་དགོས།',
        );
      case UserPosterUploadSubmitCode.uploadFailed:
        return strings.localized(
          telugu: 'అప్‌లోడ్ విఫలమైంది. మళ్లీ ప్రయత్నించండి.',
          english: 'Upload failed. Please try again.',
          hindi: 'अपलोड विफल रहा। कृपया पुन: प्रयास करें।',
          tamil: 'பதிவேற்றம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
          kannada: 'ಅಪ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          malayalam: 'അപ്‌ലോഡ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
          marathi: 'अपलोड अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
          gujarati: 'અપલોડ નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
          bengali: 'আপলোড ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
          punjabi: 'ਅੱਪਲੋਡ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
          odia: 'ଅପଲୋଡ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
          assamese: 'আপলোড ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
          konkani: 'अपलोड फसलो. उपकार करून परत यत्न करा.',
          nepali: 'अपलोड असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
          meitei: 'অপলোদ তৌবা য়ামদে। চানবীদুনা অমুক হন্না হোৎনবীয়ু।',
          mizo: 'Upload a hlawhchham. Khawngaihin ti nawn leh rawh.',
          kashmiri: 'اپلوڈ گوو ناکام۔ مہر Ships کٔرِتھ دُوبارٕ کوٗشِش کٔرِو۔',
          ladakhi: 'ཡར་འཇུག་མ་ཐུབ། སྐུ་མཁྱེན་ཡང་བསྐྱར་འབད་པ་གནང་།',
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
      telugu: 'అప్‌లోడ్ సమయం: రాత్రి 10:00 IST లోపు. తేదీ: $applicableDate',
      english: 'Upload timing: before 10:00 PM IST. Date: $applicableDate',
      hindi: 'अपलोड का समय: रात 10:00 IST से पहले। तारीख: $applicableDate',
      tamil: 'பதிவேற்ற நேரம்: இரவு 10:00 IST-க்கு முன். தேதி: $applicableDate',
      kannada: 'ಅಪ್‌ಲೋಡ್ ಸಮಯ: ರಾತ್ರಿ 10:00 IST ಒಳಗೆ. ದಿನಾಂಕ: $applicableDate',
      malayalam:
          'അപ്‌ലോഡ് സമയം: രാത്രി 10:00 IST-ന് മുമ്പ്. തീയതി: $applicableDate',
      marathi: 'अपलोड वेळ: रात्री 10:00 IST पूर्वी. तारीख: $applicableDate',
      gujarati: 'અપલોડ સમય: રાત્રે 10:00 IST પહેલાં. તારીખ: $applicableDate',
      bengali: 'আপলোডের সময়: রাত ১০:০০ IST এর আগে। তারিখ: $applicableDate',
      punjabi: 'ਅੱਪਲੋਡ ਸਮਾਂ: ਰਾਤ 10:00 IST ਤੋਂ ਪਹਿਲਾਂ। ਮਿਤੀ: $applicableDate',
      odia: 'ଅପଲୋଡ୍ ସମୟ: ରାତି ୧୦:୦୦ IST ପୂର୍ବରୁ। ତାରିଖ: $applicableDate',
      assamese: 'আপলোডৰ সময়: নিশা ১০:০০ IST ৰ আগতে। তাৰিখ: $applicableDate',
      konkani: 'अपलोड वेळ: रातच्या 10:00 IST पयलीं. तारीख: $applicableDate',
      nepali: 'अपलोड समय: राती १०:०० IST अघि। मिति: $applicableDate',
      meitei:
          'অপলোদকী মতম: নুমিদাংগী পুং 10:00 IST গী মমাংদা। তাং: $applicableDate',
      mizo: 'Upload hun: Zan dar 10:00 IST hma. Ni: $applicableDate',
      kashmiri: 'اپلوڈُک وقت: راتھ 10:00 IST برٛونٛہہ۔ تٲریخ: $applicableDate',
      ladakhi:
          'ཡར་འཇུག་དུས་ཚོད: དགོང་མོ་ 10:00 IST གོང་ལ། ཚེས་གྲངས: $applicableDate',
    );
  }

  String _communityUploadReviewNote(AppLanguage language) {
    return AppStrings(language).localized(
      telugu:
          'మీ ఫోటో, సూక్తి లేదా రూపకల్పన ఆలోచనను సమీక్ష కోసం పంపండి. మా బృందం దాన్ని పరిశీలించి, అవసరమైతే మెరుగుపరచవచ్చు. ఆమోదించిన విషయం మీ My Uploads లో మీకే కనిపిస్తుంది; ఇతర వినియోగదారులకు కనిపించదు. మీరు పంపే విషయానికి మీరే బాధ్యత వహించాలి. నిబంధనలు మరియు షరతులు వర్తిస్తాయి.',
      english:
          'Upload your photo, quote, or design idea for review. Our team may review, edit, and improve approved content. Approved content is visible only to you in My Uploads and is not shown to other users. You are responsible for the content you upload. Terms & Conditions apply.',
      hindi:
          'अपनी फोटो, सुविचार या डिज़ाइन विचार को समीक्षा के लिए भेजें। हमारी टीम उसे जाँचकर, आवश्यकता होने पर सुधार सकती है। स्वीकृत सामग्री केवल आपको My Uploads में दिखाई देगी; अन्य उपयोगकर्ताओं को नहीं दिखाई जाएगी। भेजी गई सामग्री की जिम्मेदारी आपकी होगी। नियम और शर्तें लागू होंगी।',
      tamil:
          'உங்கள் புகைப்படம், மேற்கோள் அல்லது வடிவமைப்பு யோசனையை ஆய்வுக்காக அனுப்புங்கள். எங்கள் குழு அதை பரிசீலித்து, தேவையெனில் மேம்படுத்தலாம். அங்கீகரிக்கப்பட்ட உள்ளடக்கம் My Uploads இல் உங்களுக்கு மட்டும் தெரியும்; பிற பயனர்களுக்கு காட்டப்படாது. நீங்கள் அனுப்பும் உள்ளடக்கத்திற்கு நீங்களே பொறுப்பு. விதிமுறைகள் மற்றும் நிபந்தனைகள் பொருந்தும்.',
      kannada:
          'ನಿಮ್ಮ ಫೋಟೋ, ಉಲ್ಲೇಖ ಅಥವಾ ವಿನ್ಯಾಸ ಕಲ್ಪನೆಯನ್ನು ಪರಿಶೀಲನೆಗಾಗಿ ಕಳುಹಿಸಿ. ನಮ್ಮ ತಂಡ ಅದನ್ನು ಪರಿಶೀಲಿಸಿ, ಅಗತ್ಯವಿದ್ದರೆ ಸುಧಾರಿಸಬಹುದು. ಅನುಮೋದಿತ ವಿಷಯವು My Uploads ನಲ್ಲಿ ನಿಮಗೆ ಮಾತ್ರ ಕಾಣಿಸುತ್ತದೆ; ಇತರ ಬಳಕೆದಾರರಿಗೆ ತೋರಿಸಲಾಗುವುದಿಲ್ಲ. ನೀವು ಕಳುಹಿಸುವ ವಿಷಯಕ್ಕೆ ನೀವೇ ಜವಾಬ್ದಾರರು. ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು ಅನ್ವಯಿಸುತ್ತವೆ.',
      malayalam:
          'നിങ്ങളുടെ ഫോട്ടോ, ഉദ്ധരണി അല്ലെങ്കിൽ രൂപകൽപ്പന ആശയം പരിശോധനയ്ക്കായി അയയ്ക്കുക. ഞങ്ങളുടെ സംഘം അത് പരിശോധിച്ച്, ആവശ്യമെങ്കിൽ മെച്ചപ്പെടുത്താം. അംഗീകരിച്ച ഉള്ളടക്കം My Uploads-ൽ നിങ്ങള്‍ക്ക് മാത്രമേ കാണൂ; മറ്റ് ഉപയോക്താക്കൾക്ക് കാണിക്കില്ല. നിങ്ങൾ അയക്കുന്ന ഉള്ളടക്കത്തിന് ഉത്തരവാദിത്തം നിങ്ങളുടേതാണ്. നിബന്ധനകളും വ്യവസ്ഥകളും ബാധകം.',
      marathi:
          'तुमचा फोटो, सुविचार किंवा डिझाइन कल्पना पुनरावलोकनासाठी पाठवा. आमची टीम त्याचे पुनरावलोकन करू शकते आणि आवश्यक असल्यास त्यात सुधारणा करू शकते. मंजूर केलेली सामग्री My Uploads मध्ये फक्त तुम्हालाच दिसेल; इतर वापरकर्त्यांना दिसणार नाही. तुम्ही अपलोड केलेल्या सामग्रीसाठी तुम्ही जबाबदार आहात. अटी आणि शर्ती लागू.',
      gujarati:
          'તમારો ફોટો, સુવિચાર અથવા ડિઝાઇન વિચાર સમીક્ષા માટે મોકલો. અમારી ટીમ તેની સમીક્ષા કરી શકે છે અને સુધારો કરી શકે છે. મંજૂર થયેલી સામગ्री My Uploads માં ફક્ત તમને જ દેખાશે; અન્ય વપરાશકર્તાઓને દેખાશે નહીં. તમે અપલોડ કરેલ સામગ્રી માટે તમે જવાબદાર છો. નિયમો અને શરતો લાગુ.',
      bengali:
          'পর্যালোচনার জন্য আপনার ছবি, উক্তি বা নকশার ধারণা আপলোড করুন। আমাদের দল তা পর্যালোচনা এবং সংশোধন করতে পারে। অনুমোদিত সামগ্রী কেবল আপনার My Uploads-এ দৃশ্যমান হবে; অন্য ব্যবহারকারীদের দেখানো হবে না। আপলোড করা সামগ্রীর জন্য আপনি দায়ী। শর্তাবলী প্রযোজ্য।',
      punjabi:
          'ਸਮੀਖਿਆ ਲਈ ਆਪਣੀ ਫੋਟੋ, ਵਿਚਾਰ ਜਾਂ ਡਿਜ਼ਾਈਨ ਵਿਚਾਰ ਅੱਪਲੋਡ ਕਰੋ। ਸਾਡੀ ਟੀਮ ਇਸਦੀ ਸਮੀਖਿਆ ਕਰ ਸਕਦੀ ਹੈ ਅਤੇ ਸੁਧਾਰ ਕਰ ਸਕਦੀ ਹੈ। ਮਨਜ਼ੂਰ ਸਮੱਗਰੀ My Uploads ਵਿੱਚ ਸਿਰਫ਼ ਤੁਹਾਨੂੰ ਦਿਖਾਈ ਦੇਵੇਗੀ; ਹੋਰ ਵਰਤੋਂਕਾਰਾਂ ਨੂੰ ਨਹੀਂ। ਅੱਪਲੋਡ ਲਈ ਤੁਸੀਂ ਜ਼ਿੰਮੇਵਾਰ ਹੋ। ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ ਲਾਗੂ।',
      odia:
          'ସମୀକ୍ଷା ପାଇଁ ଆପଣଙ୍କ ଫଟୋ, ସୁବିଚାର କିମ୍ବା ଡିଜାଇନ୍ ଧାରଣା ଅପଲୋଡ୍ କରନ୍ତୁ। ଆମ ଟିମ୍ ଏହାର ସମୀକ୍ଷା ଓ ଉନ୍ନତି କରିପାରେ। ଅନୁମୋଦିତ ବିଷୟବସ୍ତୁ My Uploads ରେ କେବଳ ଆପଣଙ୍କୁ ଦେଖାଯିବ। ଅପଲୋଡ୍ ବିଷୟବସ୍ତୁ ପାଇଁ ଆପଣ ନିଜେ ଦାୟୀ। ନିୟମ ଓ ସର୍ତ୍ତାବଳୀ ଲାଗୁ।',
      assamese:
          'পৰ্যালোচনাৰ বাবে আপোনাৰ ফটো, বাণী বা ডিজাইনৰ ধাৰণা আপলোড কৰক। আমাৰ দলে ইয়াক পৰ্যালোচনা আৰু উন্নত কৰিব পাৰে। অনুমোদিত বিষয়বস্তু কেৱল My Uploads-ত আপোনাক দেখুওৱা হ’ব। আপলোড কৰা বিষয়বস্তুৰ বাবে আপুনি নিজেই দায়বদ্ধ। নিয়ম আৰু চৰ্তসমূহ প্ৰযোজ্য।',
      konkani:
          'तपासणी खातीर तुमचो फोटो, विचार वा डिझाइन विचार अपलोड करात. आमचो पंगड तपासणी करून तातूंत बदल करूंक शकता. मान्यता मेळिल्ली वस्त My Uploads हातूंत फक्त तुमकां दिसतली. अपलोड केल्ल्या मजकुरा खातीर तुमीच जापसालदार. अटी आनी शर्ती लागू.',
      nepali:
          'समीक्षाको लागि आफ्नो फोटो, सुविचार वा डिजाइन विचार अपलोड गर्नुहोस्। हाम्रो टोलीले समीक्षा र सुधार गर्न सक्छ। स्वीकृत सामग्री My Uploads मा केवल तपाईंलाई देखिनेछ। अपलोड गरेको सामग्रीको लागि तपाईं जिम्मेवार हुनुहुन्छ। नियम तथा सर्तहरू लागू हुनेछन्।',
      meitei:
          'য়েংশিন্নবা নহাক্কী ফোতো, ৱাফম নত্রগা দিজাইনগী ৱাখল্লোন অপলোদ তৌবীয়ু। ঐখোয়গী তীমনা মসি য়েংশিন্দুনা ফগৎহনবা য়াই। য়ারেবা পোৎলম অসি My Uploads তা নহাক্তদা উবা ফংগনি। অপলোদ তৌরিবা পোৎলম অদুগী নহাক মশামক দায়ী ওই। নিয়ম অমসুং চৎন-পথাপশিং চৎনগনি।',
      mizo:
          'En dik turin i thlalak, thu emaw design idea upload rawh. Kan team-in an lo en dikin an siam tha thei ang. Thil pawm tawh chu My Uploads-ah nangmah chauhvin i hmu ang. I thil upload-ah nangmah ngei i mawhphur a ni. Terms & Conditions a hman theih ang.',
      kashmiri:
          'جانچ خٲطرٕ کٔرِو پنُن فوٹو، قول یا ڈیزائن خیال اپلوڈ۔ سٲنؠ ٹیم ہیٚکہ یہِ جانچِتھ تہٕ سُدھٲرِتھ۔ منظور شدہ مواد یِیہہ صرف تُہندِ My Uploads منٛز ہاونہٕ। پننہِ موادٕکؠ ذمہ دار چھِو تُہؠ پانے۔ شرائط لاگوٗ۔',
      ladakhi:
          'ཞིབ་བཤེར་ཆེད་དུ་ཁྱེད་ཀྱི་པར། གཏམ་དཔེའམ་འཆར་གཞི་ཡར་འཇུག་བྱོས། རུ་ཁག་གིས་ཞིབ་བཤེར་དང་ལེགས་བཅོས་བྱེད་སྲིད། བཀའ་འཁྲོལ་ཐོབ་པའི་དངོས་པོ་ My Uploads ནང་ཁྱེད་ལ་མ་གཏོགས་མི་མཐོང་། ཁྱེད་ཀྱིས་ཡར་འཇུག་བྱས་པར་ཁྱེད་རང་འགན་འཁུར་ཡོད། སྒྲིག་གཞི་དང་ཆ་རྐྱེན་རྣམས་ལག་བསྟར་བྱེད།',
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
                        telugu: 'సూచనలు చదవండి',
                        english: 'Read Instructions',
                        hindi: 'निर्देश पढ़ें',
                        tamil: 'வழிமுறைகளைப் படிக்கவும்',
                        kannada: 'ಸೂಚನೆಗಳನ್ನು ಓದಿ',
                        malayalam: 'നിർദ്ദേശങ്ങൾ വായിക്കുക',
                        marathi: 'सूचना वाचा',
                        gujarati: 'સૂચનાઓ વાંચો',
                        bengali: 'নির্দেশাবলী পড়ুন',
                        punjabi: 'ਨਿਰਦੇਸ਼ ਪੜ੍ਹੋ',
                        odia: 'ନିର୍ଦ୍ଦେଶାବଳୀ ପଢ଼ନ୍ତୁ',
                        assamese: 'নিৰ্দেশনাৱলী পঢ়ক',
                        konkani: 'सुचोवण्यो वाचा',
                        nepali: 'निर्देशनहरू पढ्नुहोस्',
                        meitei: 'লমজিং লাইরিক পাবীয়ু',
                        mizo: 'Kaihhruaina chhiar rawh',
                        kashmiri: 'ہدايات پر٘و',
                        ladakhi: 'ལམ་སྟོན་ཀློགས།',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.localized(
                        telugu: 'పంపే ముందు సమీక్ష నియమాలను తెలుసుకోండి.',
                        english:
                            'Check review rules before submitting your content.',
                        hindi: 'अपनी सामग्री भेजने से पहले समीक्षा नियम देखें।',
                        tamil:
                            'உங்கள் உள்ளடக்கத்தை அனுப்பும் முன் ஆய்வு விதிகளைப் பாருங்கள்.',
                        kannada:
                            'ನಿಮ್ಮ ವಿಷಯವನ್ನು ಕಳುಹಿಸುವ ಮೊದಲು ಪರಿಶೀಲನಾ ನಿಯಮಗಳನ್ನು ನೋಡಿ.',
                        malayalam:
                            'നിങ്ങളുടെ ഉള്ളടക്കം അയയ്ക്കുന്നതിന് മുമ്പ് പരിശോധനാ നിയമങ്ങൾ വായിക്കുക.',
                        marathi:
                            'तुमची सामग्री सबमिट करण्यापूर्वी पुनरावलोकन नियम तपासा.',
                        gujarati:
                            'તમારી સામગ્રી સબમિટ કરતા પહેલા સમીક્ષા નિયમો તપાસો.',
                        bengali:
                            'আপনার বিষয়বস্তু জমা দেওয়ার আগে পর্যালোচনার নিয়মগুলি দেখুন।',
                        punjabi:
                            'ਆਪਣੀ ਸਮੱਗਰੀ ਜਮ੍ਹਾ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਸਮੀਖਿਆ ਨਿਯਮਾਂ ਦੀ ਜਾਂਚ ਕਰੋ।',
                        odia:
                            'ଆପଣଙ୍କ ବିଷୟବସ୍ତୁ ଦାଖଲ କରିବା ପୂର୍ବରୁ ସମୀକ୍ଷା ନିୟମ ଯାଞ୍ଚ କରନ୍ତୁ।',
                        assamese:
                            'আপোনাৰ বিষয়বস্তু জমা দিয়াৰ আগতে পৰ্যালোচনাৰ নিয়মসমূহ পৰীক্ষা কৰক।',
                        konkani:
                            'तुमचो मजकूर सादर करचे पयलीं तपासणी नेम तपासात.',
                        nepali:
                            'आफ्नो सामग्री पेश गर्नु अघि समीक्षा नियमहरू हेर्नुहोस्।',
                        meitei:
                            'নহাক্কী পোৎলম থাজিনদ্রিঙৈ মমাংদা য়েংশিনবগী নিয়মশিং য়েংবীয়ু।',
                        mizo:
                            'I thil thehluh hmain en dik dan tur kaihhruaina en rawh.',
                        kashmiri:
                            'پنُن مواد جمع کرنہٕ برٛونٛہہ جانچ کین اصولن ہُنٛد جائزہ نِیو۔',
                        ladakhi:
                            'ཁྱེད་ཀྱི་དངོས་པོ་མ་ཕུལ་གོང་ཞིབ་བཤེར་སྒྲིག་གཞི་ལ་ལྟོས།',
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
                  hindi: 'छवि चुनें',
                  tamil: 'படத்தைத் தேர்ந்தெடுக்கவும்',
                  kannada: 'ಚಿತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
                  malayalam: 'ചിത്രം തിരഞ്ഞെടുക്കുക',
                  marathi: 'प्रतिमा निवडा',
                  gujarati: 'છબી પસંદ કરો',
                  bengali: 'ছবি নির্বাচন করুন',
                  punjabi: 'ਤਸਵੀਰ ਚੁਣੋ',
                  odia: 'ଛବି ବାଛନ୍ତୁ',
                  assamese: 'ছবি বাছক',
                  konkani: 'चित्र वेंचून काढा',
                  nepali: 'तस्विर छान्नुहोस्',
                  meitei: 'ফোতো খনবীয়ু',
                  mizo: 'Thlalak thlang rawh',
                  kashmiri: 'تصویر ژارِو',
                  ladakhi: 'པར་འདེམས།',
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
                    hindi:
                        'चुना गया: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    tamil:
                        'தேர்ந்தெடுக்கப்பட்டது: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    kannada:
                        'ಆಯ್ಕೆಮಾಡಲಾಗಿದೆ: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    malayalam:
                        'തിരഞ്ഞെടുത്തത്: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    marathi:
                        'निवडलेले: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    gujarati:
                        'પસંદ કરેલ: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    bengali:
                        'নির্বাচিত: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    punjabi:
                        'ਚੁਣਿਆ ਗਿਆ: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    odia:
                        'ଚୟନିତ: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    assamese:
                        'বাছনি কৰা হৈছে: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    konkani:
                        'वेंचिल्लें: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    nepali:
                        'चयन गरिएको: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    meitei:
                        'খল্লবা: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    mizo:
                        'Thlan tawh: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    kashmiri:
                        'ژارنہٕ آمُت: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
                    ladakhi:
                        'འདེམས་ཟིན་པ: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
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
                  hindi: 'अपना सुविचार लिखें (वैकल्पिक)',
                  tamil: 'உங்கள் மேற்கோளை எழுதுங்கள் (விருப்பத்தேர்வு)',
                  kannada: 'ನಿಮ್ಮ ಉಲ್ಲೇಖವನ್ನು ಬರೆಯಿರಿ (ಐಚ್ಛಿಕ)',
                  malayalam: 'നിങ്ങളുടെ ഉദ്ധരണി എഴുതുക (ഓപ്ഷണൽ)',
                  marathi: 'तुमचा विचार लिहा (पर्यायी)',
                  gujarati: 'તમારો સુવિચાર લખો (વૈકલ્પિક)',
                  bengali: 'আপনার উক্তি লিখুন (ঐচ্ছিক)',
                  punjabi: 'ਆਪਣਾ ਵਿਚਾਰ ਲਿਖੋ (ਵਿਕਲਪਿਕ)',
                  odia: 'ଆପଣଙ୍କ ସୁବିଚାର ଲେଖନ୍ତୁ (ଇଚ୍ଛାଧୀନ)',
                  assamese: 'আপোনাৰ বাণী লিখক (ঐচ্ছিক)',
                  konkani: 'तुमचो विचार बरयात (ऐच्छिक)',
                  nepali: 'आफ्नो सुविचार लेख्नुहोस् (वैकल्पिक)',
                  meitei: 'নহাক্কী ৱাফম ইবীয়ু (অপস্নেল)',
                  mizo: 'I thuchah ziak rawh (duhthlan theih)',
                  kashmiri: 'تُہند قول لؠکھِو (اختیاری)',
                  ladakhi: 'ཁྱེད་ཀྱི་གཏམ་དཔེ་བྲིས། (འདེམས་ཁ)',
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
                    hindi: 'यहाँ अपना सुविचार या संदेश लिखें...',
                    tamil:
                        'உங்கள் மேற்கோள் அல்லது செய்தியை இங்கே எழுதுங்கள்...',
                    kannada: 'ನಿಮ್ಮ ಉಲ್ಲೇಖ ಅಥವಾ ಸಂದೇಶವನ್ನು ಇಲ್ಲಿ ಬರೆಯಿರಿ...',
                    malayalam:
                        'നിങ്ങളുടെ ഉദ്ധരണി അല്ലെങ്കിൽ സന്ദേശം ഇവിടെ എഴുതുക...',
                    marathi: 'येथे तुमचा विचार किंवा संदेश लिहा...',
                    gujarati: 'અહીં તમારો સુવિચાર અથવા સંદેશ લખો...',
                    bengali: 'এখানে আপনার উক্তি বা বার্তা লিখুন...',
                    punjabi: 'ਇੱਥੇ ਆਪਣਾ ਵਿਚਾਰ ਜਾਂ ਸੁਨੇਹਾ ਲਿਖੋ...',
                    odia: 'ଏଠାରେ ଆପଣଙ୍କ ସୁବିଚାର କିମ୍ବା ବାର୍ତ୍ତା ଲେଖନ୍ତୁ...',
                    assamese: 'ইয়াত আপোনাৰ বাণী বা বাৰ্তা লিখক...',
                    konkani: 'हांगा तुमचो विचार वा संदेश बरयात...',
                    nepali: 'यहाँ आफ्नो सुविचार वा सन्देश लेख्नुहोस्...',
                    meitei: 'মফমসিদা নহাক্কী ৱাফম নত্রগা পাউজেল ইবীয়ু...',
                    mizo: 'He laiah hian i thu emaw thuchah emaw ziak rawh...',
                    kashmiri: 'یہتین لؠکھِو تُہند قول یا پیغام...',
                    ladakhi: 'འདིར་ཁྱེད་ཀྱི་གཏམ་དཔེའམ་འཕྲིན་ཡིག་བྲིས...',
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
                  hindi: 'श्रेणी',
                  tamil: 'பிரிவு',
                  kannada: 'ವರ್ಗ',
                  malayalam: 'വിഭാഗം',
                  marathi: 'श्रेणी',
                  gujarati: 'શ્રેણી',
                  bengali: 'বিভাগ',
                  punjabi: 'ਸ਼੍ਰੇਣੀ',
                  odia: 'ବିଭାଗ',
                  assamese: 'শ্ৰেণী',
                  konkani: 'वर्ग',
                  nepali: 'वर्ग',
                  meitei: 'কাংলুপ',
                  mizo: 'Pawl',
                  kashmiri: 'زمرٕ',
                  ladakhi: 'སྡེ་ཚན།',
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
                                      hindi: 'श्रेणी चुनें',
                                      tamil: 'பிரிவைத் தேர்ந்தெடுக்கவும்',
                                      kannada: 'ವರ್ಗವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
                                      malayalam: 'വിഭാഗം തിരഞ്ഞെടുക്കുക',
                                      marathi: 'श्रेणी निवडा',
                                      gujarati: 'શ્રેણી પસંદ કરો',
                                      bengali: 'বিভাগ নির্বাচন করুন',
                                      punjabi: 'ਸ਼੍ਰੇਣੀ ਚੁਣੋ',
                                      odia: 'ବିଭାଗ ବାଛନ୍ତୁ',
                                      assamese: 'শ্ৰেণী বাছক',
                                      konkani: 'वर्ग वेंचून काढा',
                                      nepali: 'वर्ग छान्नुहोस्',
                                      meitei: 'কাংলুপ খনবীয়ু',
                                      mizo: 'Pawl thlang rawh',
                                      kashmiri: 'زمرٕ ژارِو',
                                      ladakhi: 'སྡེ་ཚན་འདེམས།',
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
                            telugu: 'సబ్మిట్ అవుతోంది...',
                            english: 'Submitting...',
                            hindi: 'सबमिट हो रहा है...',
                            tamil: 'சமர்ப்பிக்கப்படுகிறது...',
                            kannada: 'ಸಲ್ಲಿಸಲಾಗುತ್ತಿದೆ...',
                            malayalam: 'സമർപ്പിക്കുന്നു...',
                            marathi: 'सबमिट करत आहे...',
                            gujarati: 'સબમિટ થઈ રહ્યું છે...',
                            bengali: 'জমা দেওয়া হচ্ছে...',
                            punjabi: 'ਜਮ੍ਹਾ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...',
                            odia: 'ଦାଖଲ ହେଉଛି...',
                            assamese: 'জমা দিয়া হৈছে...',
                            konkani: 'सादर जाता...',
                            nepali: 'पेश गरिँदै छ...',
                            meitei: 'থাজিনবগী থবক চত্থরি...',
                            mizo: 'Thehluh mek a ni...',
                            kashmiri: 'جمع گژھان...',
                            ladakhi: 'འབུལ་བཞིན་པ...',
                          )
                        : strings.localized(
                            telugu: 'సబ్మిట్',
                            english: 'Submit',
                            hindi: 'सबमिट करें',
                            tamil: 'சமர்ப்பி',
                            kannada: 'ಸಲ್ಲಿಸಿ',
                            malayalam: 'സമർപ്പിക്കുക',
                            marathi: 'सबमिट करा',
                            gujarati: 'સબમિટ કરો',
                            bengali: 'জমা দিন',
                            punjabi: 'ਜਮ੍ਹਾ ਕਰੋ',
                            odia: 'ଦାଖଲ କରନ୍ତୁ',
                            assamese: 'জমা দিয়ক',
                            konkani: 'सादर करा',
                            nepali: 'पेश गर्नुहोस्',
                            meitei: 'থাজিনবীয়ু',
                            mizo: 'Thehlut rawh',
                            kashmiri: 'جمع کٔرِو',
                            ladakhi: 'འབུལ་བ།',
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
                    telugu: 'ఇంకా అప్‌లోడ్లు లేవు',
                    english: 'No uploads yet',
                    hindi: 'अभी तक कोई अपलोड नहीं है',
                    tamil: 'இன்னும் பதிவேற்றங்கள் இல்லை',
                    kannada: 'ಇನ್ನೂ ಯಾವುದೇ ಅಪ್‌ಲೋಡ್‌ಗಳಿಲ್ಲ',
                    malayalam: 'ഇതുവരെ അപ്‌ലോഡുകളൊന്നുമില്ല',
                    marathi: 'अद्याप कोणतेही अपलोड नाहीत',
                    gujarati: 'હજુ સુધી કોઈ અપલોડ નથી',
                    bengali: 'এখনও কোনও আপলোড নেই',
                    punjabi: 'ਅਜੇ ਕੋਈ ਅੱਪਲੋਡ ਨਹੀਂ',
                    odia: 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ଅପଲୋଡ୍ ନାହିଁ',
                    assamese: 'এতিয়ালৈকে কোনো আপলোড নাই',
                    konkani: 'अजून कांयच अपलोड ना',
                    nepali: 'अहिलेसम्म कुनै अपलोड छैन',
                    meitei: 'হৌজিকফাওবা অপলোদ অমত্তা লৈত্রি',
                    mizo: 'Upload engmah a la awm lo',
                    kashmiri: 'تہِ کیٚنہہ اپلوڈ چھُنہٕ',
                    ladakhi: 'ད་དུང་ཡར་འཇུག་མེད།',
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
              if (upload.isApproved) {
                return OnboardingSurfaceCard(
                  maxWidth: 520,
                  padding: const EdgeInsets.all(12),
                  child: _ApprovedUploadPosterCard(
                    upload: upload,
                    language: context.currentLanguage,
                    approvedPosterBuilder: widget.approvedPosterBuilder,
                  ),
                );
              }
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
                                  telugu: 'నా లిస్ట్ నుండి తొలగించు',
                                  english: 'Remove from my list',
                                  hindi: 'मेरी सूची से हटाएं',
                                  tamil: 'என் பட்டியலிலிருந்து நீக்கு',
                                  kannada: 'ನನ್ನ ಪಟ್ಟಿಯಿಂದ ತೆಗೆದುಹಾಕಿ',
                                  malayalam:
                                      'എന്റെ ലിസ്റ്റിൽ നിന്ന് നീക്കംചെയ്യുക',
                                  marathi: 'माझ्या सूचीमधून काढा',
                                  gujarati: 'મારી સૂચિમાંથી દૂર કરો',
                                  bengali: 'আমার তালিকা থেকে সরান',
                                  punjabi: 'ਮੇਰੀ ਸੂਚੀ ਵਿੱਚੋਂ ਹਟਾਓ',
                                  odia: 'ମୋ ତାଲିକାରୁ ହଟାନ୍ତୁ',
                                  assamese: 'মোৰ তালিকাৰ পৰা আঁতৰাওক',
                                  konkani: 'म्हज्या वळेरेंतल्यान काडा',
                                  nepali: 'मेरो सूचीबाट हटाउनुहोस्',
                                  meitei: 'ঐগী লিস্ততগী লৌথোকউ',
                                  mizo: 'Ka list atanga paih rawh',
                                  kashmiri: 'مےٚنِہ فہرست منٛزٕ کڑِو',
                                  ladakhi: 'ངའི་ཐོ་ནས་ཕྱིར་ཐོན།',
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
                              hindi:
                                  'ऐप में दिखने की तारीख: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              tamil:
                                  'செயலியில் தெரியும் தேதி: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              kannada:
                                  'ಆ್ಯಪ್‌ನಲ್ಲಿ ಗೋಚರಿಸುವ ದಿನಾಂಕ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              malayalam:
                                  'ആപ്പിൽ കാണുന്ന തീയതി: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              marathi:
                                  'ॲपमध्ये दिसण्याची तारीख: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              gujarati:
                                  'ઍપમાં દેખાવાની તારીખ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              bengali:
                                  'অ্যাপে দৃশ্যমান হওয়ার তারিখ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              punjabi:
                                  'ਐਪ ਵਿੱਚ ਦਿਸਣ ਦੀ ਮਿਤੀ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              odia:
                                  'ଆପରେ ଦୃଶ୍ୟମାନ ହେବା ତାରିଖ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              assamese:
                                  'এপত দেখা পোৱাৰ তাৰিখ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              konkani:
                                  'ॲपाचेर दिसपाची तारीख: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              nepali:
                                  'एपमा देखिने मिति: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              meitei:
                                  'এপতা উবা ফংগদবা তাং: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              mizo:
                                  'App-a a lan hun tur: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              kashmiri:
                                  'ایپس پؠٹھ ہاونچ تٲریخ: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
                              ladakhi:
                                  'མཉེན་ཆས་ནང་མཐོང་བའི་ཚེས་གྲངས: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
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
                                telugu: 'కారణం: ${upload.rejectionReason}',
                                english: 'Reason: ${upload.rejectionReason}',
                                hindi: 'कारण: ${upload.rejectionReason}',
                                tamil: 'காரணம்: ${upload.rejectionReason}',
                                kannada: 'ಕಾರಣ: ${upload.rejectionReason}',
                                malayalam: 'കാരണം: ${upload.rejectionReason}',
                                marathi: 'कारण: ${upload.rejectionReason}',
                                gujarati: 'કારણ: ${upload.rejectionReason}',
                                bengali: 'কারণ: ${upload.rejectionReason}',
                                punjabi: 'ਕਾਰਨ: ${upload.rejectionReason}',
                                odia: 'କାରଣ: ${upload.rejectionReason}',
                                assamese: 'কাৰণ: ${upload.rejectionReason}',
                                konkani: 'कारण: ${upload.rejectionReason}',
                                nepali: 'कारण: ${upload.rejectionReason}',
                                meitei: 'মরম: ${upload.rejectionReason}',
                                mizo: 'A chhan: ${upload.rejectionReason}',
                                kashmiri: 'وجہ: ${upload.rejectionReason}',
                                ladakhi: 'རྒྱུ་མཚན: ${upload.rejectionReason}',
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
                  hindi: 'मेरे अपलोड',
                  tamil: 'என் பதிவேற்றங்கள்',
                  kannada: 'ನನ್ನ ಅಪ್‌ಲೋಡ್‌ಗಳು',
                  malayalam: 'എന്റെ അപ്‌ലോഡുകൾ',
                  marathi: 'माझे अपलोड्स',
                  gujarati: 'મારા અપલોડ્સ',
                  bengali: 'আমার আপলোডসমূহ',
                  punjabi: 'ਮੇਰੇ ਅੱਪਲੋਡ',
                  odia: 'ମୋର ଅପଲୋଡ୍',
                  assamese: 'মোৰ আপলোডসমূহ',
                  konkani: 'म्हजे अपलोड',
                  nepali: 'मेरो अपलोडहरू',
                  meitei: 'ঐগী অপলোদশিং',
                  mizo: 'Ka Upload-te',
                  kashmiri: 'مےٚنِہ اپلوڈ',
                  ladakhi: 'ངའི་ཡར་འཇུག',
                )
              : context.strings.localized(
                  telugu: 'కమ్యూనిటీ కాంట్రిబ్యూషన్',
                  english: 'Community Contribution',
                  hindi: 'सामुदायिक योगदान',
                  tamil: 'சமூகப் பங்களிப்பு',
                  kannada: 'ಸಮುದಾಯ ಕೊಡುಗೆ',
                  malayalam: 'കമ്മ്യൂണിറ്റി സംഭാവന',
                  marathi: 'सामुदायिक योगदान',
                  gujarati: 'સમુદાય યોગદાન',
                  bengali: 'সম্প্রদায়ের অবদান',
                  punjabi: 'ਭਾਈਚਾਰਕ ਯੋਗਦਾਨ',
                  odia: 'ସମ୍ପ୍ରଦାୟ ଯୋଗଦାନ',
                  assamese: 'সম্প্ৰদায়ৰ অৱদান',
                  konkani: 'समुदाय योगदान',
                  nepali: 'सामुदायिक योगदान',
                  meitei: 'কম্যুনিতিগী মতেং',
                  mizo: 'Khawtlang thawhhlawm',
                  kashmiri: 'کمیونٹی ہُنٛد حِصہٕ',
                  ladakhi: 'སྤྱི་ཚོགས་ཞབས་འདེགས།',
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
                      hindi: 'पोस्टर अपलोड करें',
                      tamil: 'போஸ்டர் பதிவேற்று',
                      kannada: 'ಪೋಸ್ಟರ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
                      malayalam: 'പോസ്റ്റർ അപ്‌ലോഡ് ചെയ്യുക',
                      marathi: 'पोस्टर अपलोड करा',
                      gujarati: 'પોસ્ટર અપલોડ કરો',
                      bengali: 'পোস্টার আপলোড করুন',
                      punjabi: 'ਪੋਸਟਰ ਅੱਪਲੋਡ ਕਰੋ',
                      odia: 'ପୋଷ୍ଟର ଅପଲୋଡ୍ କରନ୍ତୁ',
                      assamese: 'পোষ্টাৰ আপলোড কৰক',
                      konkani: 'पोस्टर अपलोड करा',
                      nepali: 'पोस्टर अपलोड गर्नुहोस्',
                      meitei: 'পোস্তর অপলোদ তৌবীয়ু',
                      mizo: 'Poster upload rawh',
                      kashmiri: 'پوسٹر اپلوڈ کٔرِو',
                      ladakhi: 'པོ་སི་ཊར་ཡར་འཇུག་བྱོས།',
                    ),
                  ),
                  Tab(
                    text: context.strings.localized(
                      telugu: 'నా అప్‌లోడ్లు',
                      english: 'My Uploads',
                      hindi: 'मेरे अपलोड',
                      tamil: 'என் பதிவேற்றங்கள்',
                      kannada: 'ನನ್ನ ಅಪ್‌ಲೋಡ್‌ಗಳು',
                      malayalam: 'എന്റെ അപ്‌ലോഡുകൾ',
                      marathi: 'माझे अपलोड्स',
                      gujarati: 'મારા અપલોડ્સ',
                      bengali: 'আমার আপলোডসমূহ',
                      punjabi: 'ਮੇਰੇ ਅੱਪਲੋਡ',
                      odia: 'ମୋର ଅପଲୋଡ୍',
                      assamese: 'মোৰ আপলোডসমূহ',
                      konkani: 'म्हजे अपलोड',
                      nepali: 'मेरो अपलोडहरू',
                      meitei: 'ঐগী অপলোদশিং',
                      mizo: 'Ka Upload-te',
                      kashmiri: 'مےٚنِہ اپلوڈ',
                      ladakhi: 'ངའི་ཡར་འཇུག',
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
                          telugu: 'అర్థమైంది',
                          english: 'Got it',
                          hindi: 'समझ गया',
                          tamil: 'புரிந்தது',
                          kannada: 'ಅರ್ಥವಾಯಿತು',
                          malayalam: 'മനസ്സിലായി',
                          marathi: 'समजले',
                          gujarati: 'સમજાયું',
                          bengali: 'বুঝেছি',
                          punjabi: 'ਸਮਝ ਗਿਆ',
                          odia: 'ବୁଝିଗଲି',
                          assamese: 'বুজি পালোঁ',
                          konkani: 'समजलें',
                          nepali: 'बुझे',
                          meitei: 'খঙলে',
                          mizo: 'Ka hrethiam e',
                          kashmiri: 'سمجھ آو',
                          ladakhi: 'ཧ་གོ་སོང་།',
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
      telugu: 'కమ్యూనిటీ అప్‌లోడ్ సూచనలు',
      english: 'Community Upload Instructions',
      hindi: 'कम्युनिटी अपलोड निर्देश',
      tamil: 'சமூக பதிவேற்ற வழிமுறைகள்',
      kannada: 'ಸಮುದಾಯ ಅಪ್ಲೋಡ್ ಸೂಚನೆಗಳು',
      malayalam: 'സമൂഹ അപ്‌ലോഡ് നിർദ്ദേശങ്ങൾ',
      marathi: 'सामुदायिक अपलोड सूचना',
      gujarati: 'સમુદાય અપલોડ સૂચનાઓ',
      bengali: 'কমিউনিটি আপলোড নির্দেশাবলী',
      punjabi: 'ਕਮਿਊਨਿਟੀ ਅੱਪਲੋਡ ਨਿਰਦੇਸ਼',
      odia: 'କମ୍ୟୁନିଟି ଅପଲୋଡ୍ ନିର୍ଦ୍ଦେଶାବଳୀ',
      assamese: 'কমিউনিটি আপলোড নিৰ্দেশনাৱলী',
      konkani: 'समुदाय अपलोड सुचोवण्यो',
      nepali: 'सामुदायिक अपलोड निर्देशनहरू',
      meitei: 'কম্যুনিতি অপলোদ লমজিং',
      mizo: 'Khawtlang upload kaihhruaina',
      kashmiri: 'کمیونٹی اپلوڈ ہدايات',
      ladakhi: 'སྤྱི་ཚོགས་ཡར་འཇུག་ལམ་སྟོན།',
    );
  }

  String _subtitle(AppStrings strings) {
    return strings.localized(
      telugu:
          'మీ సూక్తి, వచనం లేదా సూక్తి ఉన్న చిత్రాన్ని మన పోస్టర్ సమీక్షకు పంపవచ్చు.',
      english:
          'You can submit your quote, text, or a quote image for Mana Poster review.',
      hindi:
          'आप अपने सुविचार, पाठ या सुविचार वाली छवि को मन पोस्टर की समीक्षा के लिए भेज सकते हैं।',
      tamil:
          'உங்கள் மேற்கோள், உரை அல்லது மேற்கோள் உள்ள படத்தை மன போஸ்டர் ஆய்வுக்கு அனுப்பலாம்.',
      kannada:
          'ನಿಮ್ಮ ಉಲ್ಲೇಖ, ಪಠ್ಯ ಅಥವಾ ಉಲ್ಲೇಖ ಇರುವ ಚಿತ್ರವನ್ನು ಮನ ಪೋಸ್ಟರ್ ಪರಿಶೀಲನೆಗೆ ಕಳುಹಿಸಬಹುದು.',
      malayalam:
          'നിങ്ങളുടെ ഉദ്ധരണി, വാചകം അല്ലെങ്കിൽ ഉദ്ധരണിയുള്ള ചിത്രം മന പോസ്റ്ററിന്റെ പരിശോധനയ്ക്കായി അയയ്ക്കാം.',
      marathi:
          'तुम्ही तुमचे सुविचार, मजकूर किंवा विचार असलेली प्रतिमा मना पोस्टर पुनरावलोकनासाठी पाठवू शकता.',
      gujarati:
          'તમે તમારા સુવિચાર, લખાણ અથવા સુવિચારવાળી છબી માના પોસ્ટર સમીક્ષા માટે મોકલી શકો છો.',
      bengali:
          'আপনি আপনার উক্তি, টেক্সট বা উক্তিসমেত ছবি মানা পোস্টার পর্যালোচনার জন্য জমা দিতে পারেন।',
      punjabi:
          'ਤੁਸੀਂ ਆਪਣੇ ਵਿਚਾਰ, ਟੈਕਸਟ ਜਾਂ ਵਿਚਾਰ ਵਾਲੀ ਤਸਵੀਰ ਮਾਨਾ ਪੋਸਟਰ ਸਮੀਖਿਆ ਲਈ ਜਮ੍ਹਾ ਕਰ ਸਕਦੇ ਹੋ।',
      odia:
          'ଆପଣ ନିଜର ସୁବିଚାର, ପାଠ୍ୟ ବା ସୁବିଚାର ଥିବା ଛବି ମନା ପୋଷ୍ଟର ସମୀକ୍ଷା ପାଇଁ ଦାଖଲ କରିପାରିବେ।',
      assamese:
          'আপুনি আপোনাৰ বাণী, পাঠ বা বাণীযুক্ত ছবি মানা পোষ্টাৰ পৰ্যালোচনাৰ বাবে জমা দিব পাৰে।',
      konkani:
          'तुमी तुमचो विचार, मजकूर वा विचार आशिल्लें चित्र माना पोस्टर तपासणी खातीर धाडूं येतात.',
      nepali:
          'तपाईं आफ्नो सुविचार, पाठ वा सुविचार भएको तस्विर माना पोस्टर समीक्षाको लागि पठाउन सक्नुहुन्छ।',
      meitei:
          'নহাক্না নহাক্কী ৱাফম, ময়োক নত্রগা ৱাফম য়াওবা ফোতো মানা পোস্তর য়েংশিন্নবা থাজিনবা য়াই।',
      mizo:
          'I thuchah, thuziak emaw thuziak awmna thlalak chu Mana Poster en dik atan i thehlut thei.',
      kashmiri:
          'تُہؠ ہیٚکِو تُہند قول، تحریر یا قول آسَن وول تصویر مانا پوسٹر جانچ خٲطرٕ سوزِتھ۔',
      ladakhi:
          'ཁྱེད་ཀྱིས་གཏམ་དཔེའམ་གཏམ་དཔེ་ཡོད་པའི་པར་མཱ་ན་པོ་སི་ཊར་ཞིབ་བཤེར་ཆེད་དུ་བཏང་ཆོག',
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
      marathi:
          'तुम्ही अपलोड केलेल्या सामग्रीसाठी तुम्ही जबाबदार आहात. सबमिट करून, तुम्ही पुष्टी करता की तुमचे अपलोड मना पोस्टर अटी आणि समुदाय मार्गदर्शक तत्त्वांचे पालन करते.',
      gujarati:
          'તમે અપલોડ કરો છો તે સામગ્રી માટે તમે જવાબદાર છો. સબમિટ કરીને, તમે પુષ્ટિ કરો છો કે તમારું અપલોડ માના પોસ્ટર શરતો અને સમુદાય માર્ગદર્શિકાને અનુસરે છે.',
      bengali:
          'আপনার আপলোড করা সামগ্রীর জন্য আপনি নিজেই দায়ী। জমা দেওয়ার মাধ্যমে, আপনি নিশ্চিত করছেন যে আপনার আপলোড মানা পোস্টারের শর্তাবলী এবং সম্প্রদায়ের নির্দেশিকা মেনে চলে।',
      punjabi:
          'ਤੁਹਾਡੇ ਵੱਲੋਂ ਅੱਪਲੋਡ ਕੀਤੀ ਗਈ ਸਮੱਗਰੀ ਲਈ ਤੁਸੀਂ ਜ਼ਿੰਮੇਵਾਰ ਹੋ। ਜਮ੍ਹਾ ਕਰਕੇ, ਤੁਸੀਂ ਪੁਸ਼ਟੀ ਕਰਦੇ ਹੋ ਕਿ ਤੁਹਾਡਾ ਅੱਪਲੋਡ ਮਾਨਾ ਪੋਸਟਰ ਸ਼ਰਤਾਂ ਅਤੇ ਭਾਈਚਾਰਕ ਦਿਸ਼ਾ-ਨਿਰਦੇਸ਼ਾਂ ਦੀ ਪਾਲਣਾ ਕਰਦਾ ਹੈ।',
      odia:
          'ଆପଣ ଅପଲୋଡ୍ କରୁଥିବା ବିଷୟବସ୍ତୁ ପାଇଁ ଆପଣ ନିଜେ ଦାୟୀ। ଦାଖଲ କରିବା ଦ୍ୱାରା, ଆପଣ ନିଶ୍ଚିତ କରୁଛନ୍ତି ଯେ ଆପଣଙ୍କର ଅପଲୋଡ୍ ମନା ପୋଷ୍ଟର ନିୟମ ଏବଂ ସମ୍ପ୍ରଦାୟ ନିର୍ଦ୍ଦେଶାବଳୀ ପାଳନ କରେ।',
      assamese:
          'আপুনি আপলোড কৰা বিষয়বস্তুৰ বাবে আপুনি নিজেই দায়বদ্ধ। জমা দি, আপুনি নিশ্চিত কৰে যে আপোনাৰ আপলোডে মানা পোষ্টাৰৰ চৰ্ত আৰু সম্প্ৰদায়ৰ নীতি-নিৰ্দেশনা অনুসৰণ কৰে।',
      konkani:
          'तुमी अपलोड केल्ल्या मजकुरा खातीर तुमीच जापसालदार. सादर करून, तुमचें अपलोड माना पोस्टर अटी आनी समुदाय मार्गदर्शकांचें पालन करता म्हूण खात्री करतात.',
      nepali:
          'तपाईंले अपलोड गर्नुभएको सामग्रीको लागि तपाईं आफैं जिम्मेवार हुनुहुन्छ। पेश गरेर, तपाईं पुष्टि गर्नुहुन्छ कि तपाईंको अपलोडले माना पोस्टर सर्तहरू र समुदाय दिशानिर्देशहरू पछ्याउँछ।',
      meitei:
          'নহাক্না অপলোদ তৌরিবা পোৎলম অদুগী নহাক মশামক দায়ী ওই। থাজিনবদুগা লোয়ননা, নহাক্কী অপলোদ অদুনা মানা পোস্তরগী নিয়মশিং অমসুং কম্যুনিতিগী লমজিং ইল্লি হায়বা থাজবা পী।',
      mizo:
          'I thil upload-ah nangmah ngei i mawhphur a ni. Thehluh hian i upload chu Mana Poster thuthlung leh khawtlang kaihhruaina a zawm tih i nemnghet a ni.',
      kashmiri:
          'تُہؠ چھِو پننہِ اپلوڈ کٔرمژ موادٕکؠ ذمہ دار۔ جمع کٔرِتھ چھِو تُہؠ تصدیق کران زِ تُہند اپلوڈ چُھ مانا پوسٹر شرائط تہٕ کمیونٹی ہداياتن ہُنٛد پٲروی کران۔',
      ladakhi:
          'ཁྱེད་ཀྱིས་ཡར་འཇུག་བྱས་པའི་དངོས་པོར་ཁྱེད་རང་འགན་འཁུར་ཡོད། ཕུལ་བ་དེས་མཱ་ན་པོ་སི་ཊར་གྱི་སྒྲིག་གཞི་དང་སྤྱི་ཚོགས་ལམ་སྟོན་ལ་བརྩི་སྲུང་བྱེད་པར་ཁས་ལེན་བྱེད།',
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
          marathi: 'हे कसे कार्य करते',
          gujarati: 'આ કેવી રીતે કાર્ય કરે છે',
          bengali: 'এটি কিভাবে কাজ করে',
          punjabi: 'ਇਹ ਕਿਵੇਂ ਕੰਮ ਕਰਦਾ ਹੈ',
          odia: 'ଏହା କିପରି କାମ କରେ',
          assamese: 'ই কেনেদৰে কাম কৰে',
          konkani: 'हें कशें काम करता',
          nepali: 'यसले कसरी काम गर्छ',
          meitei: 'মসি করম্না থবক তৌবগে',
          mizo: 'Engtin nge a thawh',
          kashmiri: 'یہ کِتھکن چُھ کٲم کران',
          ladakhi: 'འདིས་ལས་ཀ་ཇི་ལྟར་བྱེད་དམ།',
        ),
        bullets: <String>[
          strings.localized(
            telugu: 'సూక్తి వచనం, సూక్తి చిత్రం లేదా రెండింటినీ పంపవచ్చు.',
            english: 'You can upload quote text, a quote image, or both.',
            hindi: 'आप सुविचार का पाठ, सुविचार वाली छवि या दोनों भेज सकते हैं।',
            tamil:
                'மேற்கோள் உரை, மேற்கோள் உள்ள படம் அல்லது இரண்டையும் அனுப்பலாம்.',
            kannada: 'ಉಲ್ಲೇಖ ಪಠ್ಯ, ಉಲ್ಲೇಖ ಇರುವ ಚಿತ್ರ ಅಥವಾ ಎರಡನ್ನೂ ಕಳುಹಿಸಬಹುದು.',
            malayalam:
                'ഉദ്ധരണി വാചകം, ഉദ്ധരണിയുള്ള ചിത്രം അല്ലെങ്കിൽ രണ്ടും അയയ്ക്കാം.',
            marathi:
                'तुम्ही सुविचार मजकूर, सुविचार प्रतिमा किंवा दोन्ही अपलोड करू शकता.',
            gujarati:
                'તમે સુવિચાર લખાણ, સુવિચાર છબી અથવા બંને અપલોડ કરી શકો છો.',
            bengali: 'আপনি উক্তি টেক্সট, উক্তি ছবি বা উভয়ই আপলোড করতে পারেন।',
            punjabi:
                'ਤੁਸੀਂ ਵਿਚਾਰ ਟੈਕਸਟ, ਵਿਚਾਰ ਤਸਵੀਰ ਜਾਂ ਦੋਵੇਂ ਅੱਪਲੋਡ ਕਰ ਸਕਦੇ ਹੋ।',
            odia: 'ଆପଣ ସୁବିଚାର ପାଠ୍ୟ, ସୁବିଚାର ଛବି କିମ୍ବା ଉଭୟ ଅପଲୋଡ୍ କରିପାରିବେ।',
            assamese: 'আপুনি বাণী পাঠ, বাণী ছবি বা দুয়োটা আপলোড কৰিব পাৰে।',
            konkani:
                'तुमी विचार मजकूर, विचार चित्र वा दोनूय अपलोड करूंक शकतात.',
            nepali:
                'तपाईं सुविचार पाठ, सुविचार तस्विर वा दुवै अपलोड गर्न सक्नुहुन्छ।',
            meitei:
                'নহাক্না ৱাফম ময়েক, ৱাফম ফোতো নত্রগা অনিমক অপলোদ তৌবা য়াই।',
            mizo:
                'I thuchah ziak, thuchah awmna thlalak emaw a pahnihin i upload thei.',
            kashmiri: 'تُہؠ ہیٚکِو قول متن، قول تصویر یا دۄشوے اپلوڈ کٔرِتھ۔',
            ladakhi:
                'ཁྱེད་ཀྱིས་གཏམ་དཔེའི་ཡི་གེ་དང་གཏམ་དཔེའི་པར་གཉིས་ཀ་ཡར་འཇུག་བྱེད་ཆོག',
          ),
          strings.localized(
            telugu: 'మీరు పంపినది ముందుగా నిర్వాహకుని సమీక్షకు వెళ్తుంది.',
            english: 'Your upload first goes to the manager review queue.',
            hindi: 'आपकी भेजी हुई सामग्री पहले प्रबंधक की समीक्षा में जाएगी।',
            tamil:
                'நீங்கள் அனுப்பியது முதலில் நிர்வாகியின் ஆய்வுக்கு செல்லும்.',
            kannada: 'ನೀವು ಕಳುಹಿಸಿದುದು ಮೊದಲು ನಿರ್ವಾಹಕರ ಪರಿಶೀಲನೆಗೆ ಹೋಗುತ್ತದೆ.',
            malayalam: 'നിങ്ങൾ അയച്ചത് ആദ്യം മാനേജറുടെ പരിശോധനയ്ക്കായി പോകും.',
            marathi: 'तुमचे अपलोड प्रथम व्यवस्थापक पुनरावलोकन रांगेत जाते.',
            gujarati: 'તમારું અપલોડ પહેલા મેનેજર સમીક્ષા કતારમાં જાય છે.',
            bengali: 'আপনার আপলোডটি প্রথমে ম্যানেজার পর্যালোচনা সারিতে যায়।',
            punjabi: 'ਤੁਹਾਡਾ ਅੱਪਲੋਡ ਪਹਿਲਾਂ ਪ੍ਰਬੰਧਕ ਸਮੀਖਿਆ ਕਤਾਰ ਵਿੱਚ ਜਾਂਦਾ ਹੈ।',
            odia: 'ଆପଣଙ୍କ ଅପଲୋଡ୍ ପ୍ରଥମେ ମ୍ୟାନେଜର୍ ସମୀକ୍ଷା ଧାଡ଼ିକୁ ଯାଏ।',
            assamese: 'আপোনাৰ আপলোড প্ৰথমে পৰিচালকৰ পৰ্যালোচনা শাৰীলৈ যায়।',
            konkani: 'तुमचें अपलोड पयलीं व्यवस्थापक तपासणी वळेरेंत वता.',
            nepali: 'तपाईंको अपलोड पहिले प्रबन्धक समीक्षा लाममा जान्छ।',
            meitei: 'নহাক্কী অপলোদ অসি হান্না মেনেজর য়েংশিনবগী পরিংদা চৎকনি।',
            mizo: 'I upload chu manager endik turah a kal hmasa phawt ang.',
            kashmiri: 'تُہند اپلوڈ چُھ گۄڈٕ مینیجر جائزہ قطارس منٛز گژھان۔',
            ladakhi:
                'ཁྱེད་ཀྱི་ཡར་འཇུག་འདི་ཐོག་མར་དོ་དམ་པའི་ཞིབ་བཤེར་ནང་འགྲོ་རྒྱུ།',
          ),
          strings.localized(
            telugu:
                'ఆమోదం లభిస్తే బృందం దాన్ని మెరుగుపరచవచ్చు; అది My Uploads లో మీకే కనిపిస్తుంది.',
            english:
                'If approved, the team may improve it; it will be visible only to you in My Uploads.',
            hindi:
                'स्वीकृति मिलने पर टीम उसे बेहतर बना सकती है; वह केवल आपको My Uploads में दिखाई देगा।',
            tamil:
                'அங்கீகாரம் கிடைத்தால் குழு அதை மேம்படுத்தலாம்; அது My Uploads இல் உங்களுக்கு மட்டும் தெரியும்.',
            kannada:
                'ಅನುಮೋದನೆ ಸಿಕ್ಕರೆ ತಂಡ ಅದನ್ನು ಸುಧಾರಿಸಬಹುದು; ಅದು My Uploads ನಲ್ಲಿ ನಿಮಗೆ ಮಾತ್ರ ಕಾಣಿಸುತ್ತದೆ.',
            malayalam:
                'അംഗീകാരം ലഭിച്ചാൽ സംഘം അത് മെച്ചപ്പെടുത്താം; അത് My Uploads-ൽ നിങ്ങള്‍ക്ക് മാത്രമേ കാണൂ.',
            marathi:
                'मंजूर झाल्यास, टीम त्यात सुधारणा करू शकते; ते तुम्हाला फक्त My Uploads मध्ये दिसेल.',
            gujarati:
                'જો મંજૂર થાય, તો ટીમ તેમાં સુધારો કરી શકે છે; તે ફક્ત તમને જ My Uploads માં દેખાશે.',
            bengali:
                'অনুমোদিত হলে, টিম এটি উন্নত করতে পারে; এটি কেবল আপনার My Uploads-এ দৃশ্যমান হবে।',
            punjabi:
                'ਜੇਕਰ ਮਨਜ਼ੂਰੀ ਮਿਲ ਜਾਂਦੀ ਹੈ, ਤਾਂ ਟੀਮ ਇਸਨੂੰ ਬਿਹਤਰ ਬਣਾ ਸਕਦੀ ਹੈ; ਇਹ ਸਿਰਫ਼ ਤੁਹਾਡੇ My Uploads ਵਿੱਚ ਦਿਖਾਈ ਦੇਵੇਗਾ।',
            odia:
                'ଅନୁମୋଦନ ମିଳିଲେ, ଟିମ୍ ଏହାକୁ ଉନ୍ନତ କରିପାରେ; ଏହା କେବଳ ଆପଣଙ୍କୁ My Uploads ରେ ଦେଖାଯିବ।',
            assamese:
                'অনুমোদিত হ’লে, দলে ইয়াক উন্নত কৰিব পাৰে; এইটো কেৱল আপোনাৰ My Uploads-ত দৃশ্যমান হ’ব।',
            konkani:
                'मान्यता मेळ्ळ्यार, पंगड तातूंत सुदारणा करूंक शकता; तें फक्त तुमकां My Uploads हातूंत दिसतಲೆಂ.',
            nepali:
                'स्वीकृत भएमा, टोलीले यसलाई सुधार गर्न सक्छ; यो तपाईंलाई मात्र My Uploads मा देखिनेछ।',
            meitei:
                'য়ারেবা তারবদি, তীমনা মসি ফগৎহনবা য়াই; মসি নহাক্কী My Uploads তাখক উবা ফংগনি।',
            mizo:
                'Pawm a nih chuan, team-in an tithatha thei ang; My Uploads-ah nangmah chauhvin i hmu thei ang.',
            kashmiri:
                'اگر منظور سپدی، ٹیم ہیٚکہ یہِ بہتر بَنٲوِتھ؛ یہِ وچھنہٕ یِیہہ صرف تُہؠ My Uploads منٛز۔',
            ladakhi:
                'བཀའ་འཁྲོལ་ཐོབ་ན་རུ་ཁག་གིས་ཡར་རྒྱས་གཏོང་སྲིད། འདི་ཁྱེད་ཀྱི་ My Uploads ནང་མ་གཏོགས་མི་མཐོང་།',
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
          marathi: 'काय मंजूर केले जाऊ शकते',
          gujarati: 'શું મંજૂર થઈ શકે છે',
          bengali: 'কি অনুমোদিত হতে পারে',
          punjabi: 'ਕੀ ਮਨਜ਼ੂਰ ਕੀਤਾ ਜਾ ਸਕਦਾ ਹੈ',
          odia: 'କ\'ଣ ଅନୁମୋଦିତ ହୋଇପାରେ',
          assamese: 'কি অনুমোদিত হ’ব পাৰে',
          konkani: 'कितें मान्यता मेळूंक शकता',
          nepali: 'के स्वीकृत हुन सक्छ',
          meitei: 'করি য়াবা য়াগনি',
          mizo: 'Eng nge pawm theih ang',
          kashmiri: 'کیاہ ہیٚکہِ منظور گژھِتھ',
          ladakhi: 'ཅི་ཞིག་ལ་བཀའ་འཁྲོལ་ཐོབ་ཐུབ་བམ།',
        ),
        bullets: <String>[
          strings.localized(
            telugu:
                'ఎంచుకున్న విభాగానికి సరిపోయే పరిశుభ్రమైన సూక్తి లేదా చిత్రం.',
            english: 'Clean quote or image that matches the selected category.',
            hindi: 'चुनी हुई श्रेणी से मेल खाने वाला साफ सुविचार या चित्र।',
            tamil:
                'தேர்ந்தெடுத்த பிரிவிற்கு பொருந்தும் தெளிவான மேற்கோள் அல்லது படம்.',
            kannada: 'ಆಯ್ದ ವಿಭಾಗಕ್ಕೆ ಹೊಂದುವ ಸ್ವಚ್ಛವಾದ ಉಲ್ಲೇಖ ಅಥವಾ ಚಿತ್ರ.',
            malayalam:
                'തിരഞ്ഞെടുത്ത വിഭാഗത്തിന് ചേരുന്ന ശുദ്ധമായ ഉദ്ധരണി അല്ലെങ്കിൽ ചിത്രം.',
            marathi: 'निवडलेल्या श्रेणीशी जुळणारा स्वच्छ विचार किंवा प्रतिमा.',
            gujarati: 'પસંદ કરેલ શ્રેણી સાથે મેળ ખાતો સ્પષ્ટ સુવિચાર અથવા છબી.',
            bengali: 'নির্বাচিত বিভাগের সাথে মেলে এমন পরিচ্ছন্ন উক্তি বা ছবি।',
            punjabi: 'ਚੁਣੀ ਗਈ ਸ਼੍ਰੇਣੀ ਨਾਲ ਮੇਲ ਖਾਂਦਾ ਸਾਫ਼ ਵਿਚਾਰ ਜਾਂ ਤਸਵੀਰ।',
            odia: 'ମନୋନୀତ ବିଭାଗ ସହିତ ମେଳ ଖାଉଥିବା ସ୍ପଷ୍ଟ ସୁବିଚାର ବା ଛବି।',
            assamese: 'নিৰ্বাচিত শ্ৰেণীৰ সৈতে মিলা স্পষ্ট বাণী বা ছবি।',
            konkani: 'वेंचून काडिल्ल्या वर्गाक जुळपी नितळ विचार वा चित्र.',
            nepali: 'चयन गरिएको वर्गसँग मेल खाने सफा सुविचार वा तस्विर।',
            meitei: 'খল্লবা কাংলুপকা চানবা শেংলবা ৱাফম নত্রগা ফোতো।',
            mizo: 'Pawl thlan nena inmil thu emaw thlalak thianghlim.',
            kashmiri: 'ژارنہٕ آمٕژ زمرٕ سٟتؠ رَلَن وول صاف قول یا تصویر۔',
            ladakhi: 'བདམས་པའི་སྡེ་ཚན་དང་མཐུན་པའི་གཙང་མའི་གཏམ་དཔེའམ་པར།',
          ),
          strings.localized(
            telugu:
                'మీరు స్వయంగా సృష్టించినది లేదా ఉపయోగించడానికి మీకు అనుమతి ఉన్న విషయం.',
            english:
                'Content created by you or content you have permission to use.',
            hindi:
                'आपके द्वारा बनाई गई सामग्री या जिसके उपयोग की अनुमति आपके पास है।',
            tamil:
                'நீங்கள் உருவாக்கியது அல்லது பயன்படுத்த அனுமதி உள்ள உள்ளடக்கம்.',
            kannada: 'ನೀವು ರಚಿಸಿದುದು ಅಥವಾ ಬಳಸಲು ನಿಮಗೆ ಅನುಮತಿ ಇರುವ ವಿಷಯ.',
            malayalam:
                'നിങ്ങൾ സൃഷ്ടിച്ചതോ ഉപയോഗിക്കാൻ അനുമതിയുള്ളതോ ആയ ഉള്ളടക്കം.',
            marathi:
                'तुमच्याद्वारे तयार केलेली सामग्री किंवा सामग्री वापरण्याची परवानगी तुमच्याकडे आहे.',
            gujarati:
                'તમારા દ્વારા બનાવેલ સામગ્રી અથવા સામગ્રી જેનો ઉપયોગ કરવાની તમારી પાસે પરવાનગી છે.',
            bengali:
                'আপনার তৈরি বিষয়বস্তু বা এমন বিষয়বস্তু যা ব্যবহার করার অনুমতি আপনার আছে।',
            punjabi:
                'ਤੁਹਾਡੇ ਦੁਆਰਾ ਬਣਾਈ ਗਈ ਸਮੱਗਰੀ ਜਾਂ ਸਮੱਗਰੀ ਜਿਸਨੂੰ ਵਰਤਣ ਦੀ ਤੁਹਾਡੇ ਕੋਲ ਇਜਾਜ਼ਤ ਹੈ।',
            odia:
                'ଆପଣଙ୍କ ଦ୍ୱାରା ପ୍ରସ୍ତୁତ ବିଷୟବସ୍ତୁ କିମ୍ବା ବ୍ୟବହାର କରିବାକୁ ଅନୁମତି ଥିବା ବିଷୟବସ୍ତୁ।',
            assamese:
                'আপোনাৰ দ্বাৰা সৃষ্টি কৰা বিষয়বস্তু বা আপোনাৰ ব্যৱহাৰ কৰাৰ অনুমতি থকা বিষয়বস্তু।',
            konkani:
                'तुमी तयार केल्लो मजकूर वा वापरपाची परवानगी आशिल्लो मजकूर.',
            nepali:
                'तपाईंले सिर्जना गर्नुभएको सामग्री वा प्रयोग गर्ने अनुमति भएको सामग्री।',
            meitei: 'নহাক্না শেম্বা পোৎলম নত্রগা শীজিন্নবগী অয়াবা লৈবা পোৎলম।',
            mizo: 'I siam ngei emaw hman theihna phalna i neih thil.',
            kashmiri:
                'تُہندِ طرفہٕ بناونہٕ آمُت مواد یا یَتھ اِستعمال کرنُک اجازت تُہؠ نِش آسہِ۔',
            ladakhi:
                'ཁྱེད་ཀྱིས་བཟོས་པའམ་བེད་སྤྱོད་གཏོང་བའི་ཆོག་མཆན་ཡོད་པའི་དངོས་པོ།',
          ),
          strings.localized(
            telugu: 'ఆమోదం తర్వాత అది మీ My Uploads లో మాత్రమే కనిపిస్తుంది.',
            english: 'After approval, it is visible only in your My Uploads.',
            hindi: 'स्वीकृति के बाद वह केवल आपके My Uploads में दिखाई देगा।',
            tamil:
                'அங்கீகாரத்திற்குப் பிறகு அது உங்கள் My Uploads இல் மட்டும் தெரியும்.',
            kannada:
                'ಅನುಮೋದನೆಯ ನಂತರ ಅದು ನಿಮ್ಮ My Uploads ನಲ್ಲಿ ಮಾತ್ರ ಕಾಣಿಸುತ್ತದೆ.',
            malayalam:
                'അംഗീകാരത്തിന് ശേഷം അത് നിങ്ങളുടെ My Uploads-ൽ മാത്രം കാണും.',
            marathi: 'मंजुरीनंतर, ते केवळ तुमच्या My Uploads मध्ये दिसेल.',
            gujarati: 'મંજૂરી પછી, તે ફક્ત તમારા My Uploads માં જ દેખાશે.',
            bengali: 'অনুমোদনের পরে, এটি কেবল আপনার My Uploads-এ দৃশ্যমান হবে।',
            punjabi:
                'ਮਨਜ਼ੂਰੀ ਤੋਂ ਬਾਅਦ, ਇਹ ਸਿਰਫ਼ ਤੁਹਾਡੇ My Uploads ਵਿੱਚ ਦਿਖਾਈ ਦੇਵੇਗਾ।',
            odia: 'ଅନୁମୋଦନ ପରେ, ଏହା କେବଳ ଆପଣଙ୍କ My Uploads ରେ ଦେଖାଯିବ।',
            assamese:
                'অনুমোদনৰ পিছত, এইটো কেৱল আপোনাৰ My Uploads-ত দৃশ্যমান হ’ব।',
            konkani:
                'मान्यता मेळ्ळ्या उपरांत, तें फक्त तुमच्या My Uploads हातूंत दिसतಲೆಂ.',
            nepali: 'स्वीकृति पछि, यो तपाईंको My Uploads मा मात्र देखिनेछ।',
            meitei: 'য়ারেবা মতুংদা, মসি নহাক্কী My Uploads তাখক উবা ফংগনি।',
            mizo: 'Pawm hnuah chuan, i My Uploads-ah chauh a lang ang.',
            kashmiri:
                'منظوری پتہٕ، یہِ یِیہہ صرف تُہندِ My Uploads منٛز ہاونہٕ।',
            ladakhi:
                'བཀའ་འཁྲོལ་ཐོབ་རྗེས་འདི་ཁྱེད་ཀྱི་ My Uploads ནང་མ་གཏོགས་མི་མཐོང་།',
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
          marathi: 'नकार देण्याची कारणे',
          gujarati: 'અસ્વીકારના કારણો',
          bengali: 'প্রত্যাখ্যানের কারণ',
          punjabi: 'ਰੱਦ ਕਰਨ ਦੇ ਕਾਰਨ',
          odia: 'ପ୍ରତ୍ୟାଖ୍ୟାନର କାରଣ',
          assamese: 'প্ৰত্যাখ্যানৰ কাৰণ',
          konkani: 'नाकारपाचीं कारणां',
          nepali: 'अस्वीकृतिका कारणहरू',
          meitei: 'য়াদবগী মরমশিং',
          mizo: 'Hnar a nih chhan te',
          kashmiri: 'مسترد گژھنٕچ وجوہات',
          ladakhi: 'ཕྱིར་འཐེན་བྱེད་པའི་རྒྱུ་མཚན།',
        ),
        bullets: <String>[
          strings.localized(
            telugu:
                'తప్పు విభాగం, సంబంధం లేని విషయం, నకిలీ విషయం లేదా నాణ్యత తక్కువగా ఉన్న చిత్రం.',
            english:
                'Wrong category, unrelated content, duplicate, or low quality image.',
            hindi:
                'गलत श्रेणी, असंबंधित सामग्री, दोहराई गई सामग्री या कम गुणवत्ता वाली छवि।',
            tamil:
                'தவறான பிரிவு, தொடர்பில்லாத உள்ளடக்கம், நகல் அல்லது குறைந்த தரமான படம்.',
            kannada:
                'ತಪ್ಪು ವಿಭಾಗ, ಸಂಬಂಧವಿಲ್ಲದ ವಿಷಯ, ನಕಲಿ ಅಥವಾ ಕಡಿಮೆ ಗುಣಮಟ್ಟದ ಚಿತ್ರ.',
            malayalam:
                'തെറ്റായ വിഭാഗം, ബന്ധമില്ലാത്ത ഉള്ളടക്കം, പകർപ്പ് അല്ലെങ്കിൽ കുറഞ്ഞ നിലവാരത്തിലുള്ള ചിത്രം.',
            marathi:
                'चुकीची श्रेणी, असंबंधित मजकूर, डुप्लिकेट किंवा कमी दर्जाची प्रतिमा.',
            gujarati:
                'ખોટી શ્રેણી, અસંબંધિત સામગ્રી, ડુપ્લિકેટ અથવા ઓછી ગુણવત્તાવાળી છબી.',
            bengali: 'ভুল বিভাগ, সম্পর্কহীন বিষয়বস্তু, নকল বা নিম্নমানের ছবি।',
            punjabi:
                'ਗਲਤ ਸ਼੍ਰੇਣੀ, ਅਸੰਬੰਧਿਤ ਸਮੱਗਰੀ, ਡੁਪਲੀਕੇਟ, ਜਾਂ ਘੱਟ ਕੁਆਲਿਟੀ ਵਾਲੀ ਤਸਵੀਰ।',
            odia:
                'ଭୁଲ୍ ବିଭାଗ, ଅସମ୍ପୃକ୍ତ ବିଷୟବସ୍ତୁ, ନକଲି, କିମ୍ବା ନିମ୍ନ ଗୁଣବତ୍ତା ଛବି।',
            assamese:
                'ভুল শ্ৰেণী, অপ্ৰাসংগিক বিষয়বস্তু, ডুপ্লিকেট বা নিম্ন মানৰ ছবি।',
            konkani:
                'चूक वर्ग, असंबंधित मजकूर, डुप्लिकेट वा उण्या दर्जाचें चित्र.',
            nepali:
                'गलत वर्ग, असम्बन्धित सामग्री, नक्कली, वा न्यून गुणस्तरको तस्विर।',
            meitei:
                'লল্লবা কাংলুপ, মরি লৈনদবা পোৎলম, কপিরোল নত্রগা ক্বালিতি তাথবা ফোতো।',
            mizo:
                'Pawl dik lo, inzawmna nei lo, copy chawp emaw thlalak tha tawk lo.',
            kashmiri: 'غلط زمرٕ، غٲر مُتعلق مواد، نَقٕل یا کم معیارٕچ تصویر۔',
            ladakhi:
                'ནོར་བའི་སྡེ་ཚན། འབྲེལ་མེད་དངོས་པོ། ཟློས་པའམ་སྤུས་ཀ་ཞན་པའི་པར།',
          ),
          strings.localized(
            telugu:
                'హక్కులు కలిగిన చిత్రం, కాపీ చేసిన సూక్తి, అభ్యంతరకరమైన లేదా తప్పుదారి పట్టించే విషయం.',
            english:
                'Copyright image, copied quote, offensive, or misleading content.',
            hindi:
                'कॉपीराइट वाली छवि, नकल किया गया सुविचार, आपत्तिजनक या भ्रामक सामग्री।',
            tamil:
                'பதிப்புரிமை உள்ள படம், நகலெடுத்த மேற்கோள், அவமதிப்பான அல்லது தவறாக வழிநடத்தும் உள்ளடக்கம்.',
            kannada:
                'ಹಕ್ಕುಸ್ವಾಮ್ಯ ಹೊಂದಿರುವ ಚಿತ್ರ, ನಕಲಿಸಿದ ಉಲ್ಲೇಖ, ಅವಮಾನಕಾರಿ ಅಥವಾ ತಪ್ಪು ದಾರಿಗೆಳೆಯುವ ವಿಷಯ.',
            malayalam:
                'പകർപ്പവകാശമുള്ള ചിത്രം, പകർത്തിയ ഉദ്ധരണി, അപമാനകരമോ തെറ്റിദ്ധരിപ്പിക്കുന്നതോ ആയ ഉള്ളടക്കം.',
            marathi:
                'कॉपीराइट प्रतिमा, कॉपी केलेला विचार, आक्षेपार्ह किंवा दिशाभूल करणारी सामग्री.',
            gujarati:
                'કૉપિરાઇટ છબી, કૉપિ કરેલ સુવિચાર, વાંધાજનક અથવા ભ્રામક સામગ્રી.',
            bengali:
                'কপিরাইটযুক্ত ছবি, অনুলিপি করা উক্তি, আপত্তিকর বা বিভ্রান্তিকর বিষয়বস্তু।',
            punjabi:
                'ਕਾਪੀਰਾਈਟ ਤਸਵੀਰ, ਕਾਪੀ ਕੀਤਾ ਵਿਚਾਰ, ਇਤਰਾਜ਼ਯੋਗ, ਜਾਂ ਗੁੰਮਰਾਹਕੁੰਨ ਸਮੱਗਰੀ।',
            odia:
                'କପିରାଇଟ୍ ଛବି, କପି ହୋଇଥିବା ସୁବିଚାର, ଆପତ୍ତିଜନକ, କିମ୍ବା ବିଭ୍ରାନ୍ତିକର ବିଷୟବସ୍ତୁ।',
            assamese:
                'কপিৰাইটযুক্ত ছবি, নকল কৰা বাণী, আপত্তিজনক বা বিভ্ৰান্তিকৰ বিষয়বস্তু।',
            konkani:
                'कॉपीराइट आशिल्लें चित्र, कॉपी केल्लो विचार, आपत्तीजनक वा दिशाभूल करपी मजकूर.',
            nepali:
                'प्रतिलिपि अधिकार तस्विर, कपी गरिएको सुविचार, आपत्तिजनक, वा भ्रामक सामग्री।',
            meitei:
                'কপিরাইত লৈবা ফোতো, কোপী তৌরবা ৱাফম, য়েংনিংঙাই ওইদবা নত্রগা লান্না য়ুমলোইরবা পোৎলম।',
            mizo:
                'Copyright nei thlalak, thu lak chhawn, mi pawi sawi thei emaw hruai sual thei thil.',
            kashmiri:
                'کاپی رائیٹ تصویر، نَقٕل کٔرمُت قول، ناگوار یا گمراہ کن مواد۔',
            ladakhi:
                'འདྲ་བཤུས་དབང་ཆ་ཡོད་པའི་པར། བཤུས་པའི་གཏམ་དཔེ། མི་འོས་པའམ་མགོ་སྐོར་གཏོང་བའི་དངོས་པོ།',
          ),
          strings.localized(
            telugu:
                'వ్యక్తిగత వివరాలు, రాజకీయ దుర్వినియోగం, అవాంఛిత ప్రచారం లేదా సురక్షితం కాని విషయం.',
            english:
                'Private details, political misuse, spam, or unsafe content.',
            hindi:
                'निजी विवरण, राजनीतिक दुरुपयोग, अवांछित प्रचार या असुरक्षित सामग्री।',
            tamil:
                'தனிப்பட்ட விவரங்கள், அரசியல் தவறான பயன்பாடு, தேவையற்ற விளம்பரம் அல்லது பாதுகாப்பற்ற உள்ளடக்கம்.',
            kannada:
                'ಖಾಸಗಿ ವಿವರಗಳು, ರಾಜಕೀಯ ದುರುಪಯೋಗ, ಅನಗತ್ಯ ಪ್ರಚಾರ ಅಥವಾ ಸುರಕ್ಷಿತವಲ್ಲದ ವಿಷಯ.',
            malayalam:
                'സ്വകാര്യ വിവരങ്ങൾ, രാഷ്ട്രീയ ദുരുപയോഗം, അനാവശ്യ പ്രചാരം അല്ലെങ്കിൽ സുരക്ഷിതമല്ലാത്ത ഉള്ളടക്കം.',
            marathi:
                'खाजगी तपशील, राजकीय गैरवापर, स्पॅम किंवा असुरक्षित सामग्री.',
            gujarati:
                'ખાનગી વિગતો, રાજકીય દુરુપયોગ, સ્પામ અથવા અસુરક્ષિત સામગ્રી.',
            bengali:
                'ব্যক্তিগত বিবরণ, রাজনৈতিক অপব্যবহার, স্প্যাম বা অনিরাপদ বিষয়বস্তু।',
            punjabi: 'ਨਿੱਜੀ ਵੇਰਵੇ, ਸਿਆਸੀ ਦੁਰਵਰਤੋਂ, ਸਪੈਮ, ਜਾਂ ਅਸੁਰੱਖਿਅਤ ਸਮੱਗਰੀ।',
            odia:
                'ବ୍ୟକ୍ତିଗତ ବିବରଣୀ, ରାଜନୈତିକ ଅପବ୍ୟବହାର, ସ୍ପାମ୍, କିମ୍ବା ଅସୁରକ୍ଷିତ ବିଷୟବସ୍ତୁ।',
            assamese:
                'ব্যক্তিগত বিৱৰণ, ৰাজনৈতিক অপব্যৱহাৰ, স্পেম বা অসুৰক্ষিত বিষয়বস্তু।',
            konkani: 'खाजगी तपशील, राजकीय गैरवापर, स्पॅम वा असुरक्षित मजकूर.',
            nepali:
                'निजी विवरण, राजनीतिक दुरुपयोग, स्प्याम, वा असुरक्षित सामग्री।',
            meitei:
                'লৈনরিবা মীওইগী ই-পাউ, রাজনিতিগী লান্না শীজিন্নবা, স্পাম নত্রগা অশুকপাবা পোৎলম।',
            mizo:
                'Mimal thuruk, politics lama hman dik loh, spam emaw him lo thil.',
            kashmiri:
                'ذاتی تفصیٖلات، سِیاسی غلط اِستعمال، سپیم یا غٲر محفوٗظ مواد۔',
            ladakhi:
                'སྒེར་གྱི་གནས་ཚུལ། ཆབ་སྲིད་ཀྱི་ལོག་སྤྱོད། མཁོ་མེད་དྲིལ་བསྒྲགས། ཉེན་ཁ་ཅན་གྱི་དངོས་པོ།',
          ),
        ],
      ),
    ];
  }
}

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
            english: 'Select category',
            hindi: 'श्रेणी चुनें',
            tamil: 'பிரிவைத் தேர்ந்தெடுக்கவும்',
            kannada: 'ವರ್ಗವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
            malayalam: 'വിഭാഗം തിരഞ്ഞെടുക്കുക',
            marathi: 'श्रेणी निवडा',
            gujarati: 'શ્રેણી પસંદ કરો',
            bengali: 'বিভাগ নির্বাচন করুন',
            punjabi: 'ਸ਼੍ਰੇਣੀ ਚੁਣੋ',
            odia: 'ବିଭାଗ ବାଛନ୍ତୁ',
            assamese: 'শ্ৰেণী বাছক',
            konkani: 'वर्ग वेंचून काढा',
            nepali: 'वर्ग छान्नुहोस्',
            meitei: 'কাংলুপ খনবীয়ু',
            mizo: 'Pawl thlang rawh',
            kashmiri: 'زمرٕ ژارِو',
            ladakhi: 'སྡེ་ཚན་འདེམས།',
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
