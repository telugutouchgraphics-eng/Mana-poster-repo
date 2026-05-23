import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mana_poster/app/config/home_category_catalog.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/features/prehome/models/user_poster_upload.dart';
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

  static final List<HomeCategoryCatalogEntry> _uploadableCategories =
      HomeCategoryCatalog.uploadable;
  static const DynamicCategoryService _dynamicCategoryService =
      DynamicCategoryService(daysBeforeEvent: 7);
  static const DynamicEventScheduleService _dynamicEventScheduleService =
      DynamicEventScheduleService();

  @override
  void initState() {
    super.initState();
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
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshUploads(forceServer: true));
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

    for (final entry in _uploadableCategories) {
      addOption(entry.id, entry.label);
    }
    for (final item in _dynamicCategoryService.categoriesForDate(
      IstTimeService.now(),
      language: language,
    )) {
      addOption(
        item.id,
        item.label,
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
    return switch (language) {
      AppLanguage.telugu => 'ఈవెంట్ డేట్: $formatted',
      AppLanguage.hindi => 'इवेंट डेट: $formatted',
      AppLanguage.english ||
      AppLanguage.tamil ||
      AppLanguage.kannada ||
      AppLanguage.malayalam => 'Event date: $formatted',
    };
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
                  'ఇది మీ My Uploads లిస్ట్ నుండి మాత్రమే తొలగుతుంది. ఇతర users కి ఇది delete కాదు.',
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
                strings.localized(telugu: 'డిలీట్', english: 'Delete'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.localized(
            telugu: 'ఈ ఐటమ్ మీ లిస్ట్ నుంచి తొలగించబడింది',
            english: 'This item was removed from your list',
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final strings = context.strings;
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) {
      return;
    }
    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.localized(
              telugu: 'అప్‌లోడ్ మొబైల్ యాప్‌లో మాత్రమే అందుబాటులో ఉంది',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.localized(
              telugu: 'ఇమేజ్ సైజ్ 500KB లేదా దానికంటే తక్కువ ఉండాలి',
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
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.localized(
              telugu: 'దయచేసి ఇమేజ్ ఎంపిక చేయండి',
              english: 'Please select image',
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
        categoryId: _selectedCategoryId,
        categoryLabel: _selectedCategoryLabel,
      );
      if (!mounted) {
        return;
      }
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_submitResultMessage(result.code))),
        );
        return;
      }
      setState(() {
        _selectedImageFile = null;
        _selectedImageBytes = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.localized(
              telugu: 'అప్‌లోడ్ రివ్యూ కోసం పంపబడింది',
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
      return strings.localized(telugu: 'ఆమోదించబడింది', english: 'Approved');
    }
    if (upload.isRejected) {
      return strings.localized(telugu: 'తిరస్కరించబడింది', english: 'Rejected');
    }
    return strings.localized(telugu: 'పెండింగ్', english: 'Pending');
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
      case UserPosterUploadSubmitCode.imageTooLarge:
        return strings.localized(
          telugu: 'ఇమేజ్ సైజ్ 500KB లేదా దానికంటే తక్కువ ఉండాలి',
          english: 'Image size must be 500KB or less',
        );
      case UserPosterUploadSubmitCode.uploadFailed:
        return strings.localized(
          telugu: 'అప్‌లోడ్ విఫలమైంది. మళ్లీ ప్రయత్నించండి.',
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
    final istNow = IstTimeService.now();
    if (istNow.hour < 22) {
      return strings.localized(
        telugu:
            'రాత్రి 10:00 IST ముందు -> అదే రోజు పబ్లిష్ డేట్ ($applicableDate)',
        english:
            'Before 10:00 PM IST -> same day publish date ($applicableDate)',
      );
    }
    return strings.localized(
      telugu:
          'రాత్రి 10:00 IST తర్వాత -> తదుపరి రోజు పబ్లిష్ డేట్ ($applicableDate)',
      english: 'After 10:00 PM IST -> next day publish date ($applicableDate)',
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
    final applicableDateLabel =
        UserPosterUploadsService.formatIstDateLabelFromMillis(
          UserPosterUploadsService.resolveApplicableFromMillis(),
        );
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
                  telugu: 'ఇమేజ్ ఎంపిక చేయండి',
                  english: 'Select Image',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.localized(
                  telugu: 'గరిష్ట సైజ్: 500KB',
                  english: 'Max size: 500KB',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                _uploadWindowMessage(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.localized(
                  telugu: 'యాప్‌లో కనిపించే డేట్: $applicableDateLabel',
                  english: 'App visible date: $applicableDateLabel',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_selectedImageFile != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  strings.localized(
                    telugu:
                        'ఎంపిక చేసినది: ${(_selectedImageBytes / 1024).toStringAsFixed(1)} KB',
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
                strings.localized(telugu: 'కేటగిరీ', english: 'Category'),
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
                                      telugu: 'కేటగిరీ ఎంపిక చేయండి',
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
                            telugu: 'సబ్మిట్ అవుతోంది...',
                            english: 'Submitting...',
                          )
                        : strings.localized(
                            telugu: 'సబ్మిట్',
                            english: 'Submit',
                          ),
                  ),
                ),
              ),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 74,
                        height: 110,
                        child: Image.network(
                          upload.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
                            color: const Color(0xFFF1F5F9),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFF64748B),
                            ),
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
                          Text(
                            strings.localized(
                              telugu:
                                  'యాప్‌లో కనిపించే డేట్: ${UserPosterUploadsService.formatIstDateLabelFromMillis(upload.appVisibleFromMillis)}',
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
                                telugu: 'కారణం: ${upload.rejectionReason}',
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
                          if (detailedStatusView &&
                              upload.isPending) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              strings.localized(
                                telugu: 'మేనేజర్ రివ్యూ కోసం వేచి ఉంది',
                                english: 'Waiting for manager review',
                              ),
                              style: const TextStyle(color: Color(0xFF92400E)),
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
                  telugu: 'కమ్యూనిటీ కాంట్రిబ్యూషన్',
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
            telugu: 'కేటగిరీ ఎంపిక చేయండి',
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
