import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mana_poster/app/config/home_category_catalog.dart';
import 'package:mana_poster/features/admin/data/services/firebase_admin_auth_service.dart';
import 'package:mana_poster/features/prehome/models/landing_site_content.dart';
import 'package:mana_poster/features/prehome/services/landing_site_content_service.dart';

const Color _adminPrimary = Color(0xFF6D28D9);
const Color _adminPrimaryDark = Color(0xFF4C1D95);
const Color _adminAccent = Color(0xFF38BDF8);
const Color _adminPage = Color(0xFFFBF7FF);
const Color _adminInk = Color(0xFF172033);
const Color _adminMuted = Color(0xFF52607A);
const Color _adminBorder = Color(0xFFDDD6FE);
const String _recommendedBannerSize = '1920 x 700 px';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final LandingSiteContentService _contentService = LandingSiteContentService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _posterTitleController = TextEditingController();

  LandingSiteContent _content = LandingSiteContent.empty();
  String _selectedCategoryId = HomeCategoryCatalog.uploadable.first.id;
  bool _loading = true;
  bool _saving = false;
  String? _statusText;
  Uint8List? _bannerPreviewBytes;
  Uint8List? _sectionMediaPreviewBytes;
  final Map<String, Uint8List> _posterPreviewBytes = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _posterTitleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _statusText = null;
    });
    final LandingSiteContent content = await _contentService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _content = content;
      _loading = false;
      _bannerPreviewBytes = null;
      _sectionMediaPreviewBytes = null;
      _posterPreviewBytes.clear();
    });
  }

  Future<void> _uploadBanner() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 94,
    );
    if (file == null) {
      return;
    }
    await _runSave(
      success: 'Banner updated. Refresh the public landing page to see it.',
      action: () async {
        final Uint8List bytes = await file.readAsBytes();
        setState(() => _bannerPreviewBytes = bytes);
        _content = await _contentService.saveBanner(
          fileName: file.name,
          bytes: bytes,
          contentType: _contentType(file.name),
        );
      },
    );
  }

  Future<void> _deleteBanner() async {
    if (_content.bannerImageUrl.isEmpty && _content.bannerStoragePath.isEmpty) {
      setState(() => _statusText = 'No banner to delete.');
      return;
    }
    final bool confirmed = await _confirmDeleteBanner();
    if (!confirmed) {
      return;
    }
    await _runSave(
      success: 'Banner deleted.',
      action: () async {
        _content = await _contentService.deleteBanner();
        _bannerPreviewBytes = null;
      },
    );
  }

  Future<void> _uploadSectionImage() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 94,
    );
    if (file == null) {
      return;
    }
    await _runSave(
      success: 'Section image updated.',
      action: () async {
        final Uint8List bytes = await file.readAsBytes();
        setState(() => _sectionMediaPreviewBytes = bytes);
        _content = await _contentService.saveSectionMedia(
          fileName: file.name,
          bytes: bytes,
          contentType: _contentType(file.name),
          mediaType: 'image',
        );
      },
    );
  }

  Future<void> _uploadSectionVideo() async {
    final XFile? file = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
    );
    if (file == null) {
      return;
    }
    await _runSave(
      success: 'Section video updated.',
      action: () async {
        final Uint8List bytes = await file.readAsBytes();
        _content = await _contentService.saveSectionMedia(
          fileName: file.name,
          bytes: bytes,
          contentType: _videoContentType(file.name),
          mediaType: 'video',
        );
        _sectionMediaPreviewBytes = null;
      },
    );
  }

  Future<void> _deleteSectionMedia() async {
    if (_content.sectionMediaUrl.isEmpty &&
        _content.sectionMediaStoragePath.isEmpty) {
      setState(() => _statusText = 'No section media to delete.');
      return;
    }
    final bool confirmed = await _confirmDeleteSectionMedia();
    if (!confirmed) {
      return;
    }
    await _runSave(
      success: 'Section media deleted.',
      action: () async {
        _content = await _contentService.deleteSectionMedia();
        _sectionMediaPreviewBytes = null;
      },
    );
  }

  Future<void> _uploadPoster() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 94,
    );
    if (file == null) {
      return;
    }
    await _runSave(
      success: 'Poster uploaded. It is now available on the landing page.',
      action: () async {
        final Uint8List bytes = await file.readAsBytes();
        final Set<String> oldPosterIds = _content.posters
            .map((LandingSitePoster poster) => poster.id)
            .toSet();
        final LandingSiteContent nextContent = await _contentService.addPoster(
          categoryId: _selectedCategoryId,
          title: _posterTitleController.text,
          fileName: file.name,
          bytes: bytes,
          contentType: _contentType(file.name),
        );
        _content = nextContent;
        for (final LandingSitePoster poster in nextContent.posters) {
          if (!oldPosterIds.contains(poster.id)) {
            _posterPreviewBytes[poster.id] = bytes;
            break;
          }
        }
        _posterTitleController.clear();
      },
    );
  }

  Future<void> _deletePoster(LandingSitePoster poster) async {
    final bool confirmed = await _confirmDeletePoster(poster);
    if (!confirmed) {
      return;
    }
    await _runSave(
      success: 'Poster deleted.',
      action: () async {
        _content = await _contentService.deletePoster(poster.id);
        _posterPreviewBytes.remove(poster.id);
      },
    );
  }

  Future<bool> _confirmDeletePoster(LandingSitePoster poster) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete poster?'),
          content: Text(
            'This will remove "${poster.title}" from the landing page and Storage.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<bool> _confirmDeleteBanner() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete banner?'),
          content: const Text(
            'This will remove the current landing page banner from the public site and Storage.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<bool> _confirmDeleteSectionMedia() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete section media?'),
          content: const Text(
            'This will remove the image/video from this landing page section and Storage.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _runSave({
    required String success,
    required Future<void> Function() action,
  }) async {
    setState(() {
      _saving = true;
      _statusText = null;
    });
    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = success;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _contentType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _videoContentType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.webm')) {
      return 'video/webm';
    }
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    return 'video/mp4';
  }

  @override
  Widget build(BuildContext context) {
    final List<LandingSitePoster> selectedPosters = _content.posters
        .where(
          (LandingSitePoster item) => item.categoryId == _selectedCategoryId,
        )
        .toList(growable: false);
    final Map<String, int> categoryCounts = <String, int>{};
    for (final LandingSitePoster poster in _content.posters) {
      categoryCounts[poster.categoryId] =
          (categoryCounts[poster.categoryId] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: _adminPage,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Landing Page Admin',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _saving ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: FirebaseAdminAuthService.instance.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: <Widget>[
                _StatusBanner(saving: _saving, text: _statusText),
                const SizedBox(height: 14),
                _Panel(
                  title: 'Banner',
                  subtitle:
                      'Top landing page banner. Perfect size: $_recommendedBannerSize. Upload one wide image; no text or buttons will be placed on top of it.',
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _saving ? null : _uploadBanner,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Upload Banner'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _adminPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _saving ||
                                (_content.bannerImageUrl.isEmpty &&
                                    _content.bannerStoragePath.isEmpty)
                            ? null
                            : _deleteBanner,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete Banner'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  child: _BannerPreview(
                    imageUrl: _content.bannerImageUrl,
                    previewBytes: _bannerPreviewBytes,
                  ),
                ),
                const SizedBox(height: 14),
                _Panel(
                  title: 'Middle Section Media',
                  subtitle:
                      'This is separate from the top banner. Upload image or video for the section shown near app details.',
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _saving ? null : _uploadSectionImage,
                        icon: const Icon(Icons.image_rounded),
                        label: const Text('Upload Image'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _adminPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _uploadSectionVideo,
                        icon: const Icon(Icons.videocam_rounded),
                        label: const Text('Upload Video'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _adminAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _saving ||
                                (_content.sectionMediaUrl.isEmpty &&
                                    _content.sectionMediaStoragePath.isEmpty)
                            ? null
                            : _deleteSectionMedia,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  child: _SectionMediaPreview(
                    mediaUrl: _content.sectionMediaUrl,
                    mediaType: _content.sectionMediaType,
                    previewBytes: _sectionMediaPreviewBytes,
                  ),
                ),
                const SizedBox(height: 14),
                _Panel(
                  title: 'Category Posters',
                  subtitle:
                      'Select a category and upload unlimited posters. Portrait, square, landscape and custom sizes will fit on the landing page.',
                  action: FilledButton.icon(
                    onPressed: _saving ? null : _uploadPoster,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Upload Poster'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _adminAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CategorySelector(
                        selectedId: _selectedCategoryId,
                        counts: categoryCounts,
                        onSelected: (String id) {
                          setState(() => _selectedCategoryId = id);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _posterTitleController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Poster title',
                          hintText: 'Example: Morning wishes poster',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PosterAdminGrid(
                        posters: selectedPosters,
                        previewBytes: _posterPreviewBytes,
                        onDelete: _saving ? null : _deletePoster,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.saving, required this.text});

  final bool saving;
  final String? text;

  @override
  Widget build(BuildContext context) {
    if (!saving && (text == null || text!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final bool error =
        (text ?? '').toLowerCase().contains('exception') ||
        (text ?? '').toLowerCase().contains('error') ||
        (text ?? '').toLowerCase().contains('failed');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: saving
            ? const Color(0xFFF5F3FF)
            : error
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: saving
              ? const Color(0xFFDDD6FE)
              : error
              ? const Color(0xFFFECACA)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (saving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              error ? Icons.error_rounded : Icons.check_circle_rounded,
              color: error ? const Color(0xFFDC2626) : _adminPrimary,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              saving ? 'Saving...' : text!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x184C1D95),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _adminInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({required this.imageUrl, required this.previewBytes});

  final String imageUrl;
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Admin preview',
            style: TextStyle(
              color: _adminPrimaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1920 / 700,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    border: Border.all(color: _adminBorder),
                  ),
                  child: previewBytes != null
                      ? Image.memory(
                          previewBytes!,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        )
                      : imageUrl.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Perfect banner size',
                                style: TextStyle(
                                  color: _adminPrimaryDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                _recommendedBannerSize,
                                style: TextStyle(
                                  color: _adminInk,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'No custom banner uploaded yet',
                                style: TextStyle(
                                  color: _adminMuted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Text(
                                  'Banner preview could not load. Upload again or refresh.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionMediaPreview extends StatelessWidget {
  const _SectionMediaPreview({
    required this.mediaUrl,
    required this.mediaType,
    required this.previewBytes,
  });

  final String mediaUrl;
  final String mediaType;
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    final bool hasMedia = mediaUrl.isNotEmpty || previewBytes != null;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: previewBytes != null
          ? Image.memory(
              previewBytes!,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            )
          : !hasMedia
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No middle section image/video uploaded yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _adminPrimaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          : mediaType == 'video'
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: _adminPrimary,
                      size: 54,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Video uploaded. Preview it on the public page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _adminPrimaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Image.network(
              mediaUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Section media preview could not load. Upload again or refresh.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selectedId,
    required this.counts,
    required this.onSelected,
  });

  final String selectedId;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: HomeCategoryCatalog.uploadable
          .map((HomeCategoryCatalogEntry item) {
            final bool selected = selectedId == item.id;
            final int count = counts[item.id] ?? 0;
            return ChoiceChip(
              selected: selected,
              label: Text(count > 0 ? '${item.label} ($count)' : item.label),
              selectedColor: _adminPrimary,
              backgroundColor: const Color(0xFFF5F3FF),
              labelStyle: TextStyle(
                color: selected ? Colors.white : _adminPrimaryDark,
                fontWeight: FontWeight.w900,
              ),
              onSelected: (_) => onSelected(item.id),
            );
          })
          .toList(growable: false),
    );
  }
}

class _PosterAdminGrid extends StatelessWidget {
  const _PosterAdminGrid({
    required this.posters,
    required this.previewBytes,
    required this.onDelete,
  });

  final List<LandingSitePoster> posters;
  final Map<String, Uint8List> previewBytes;
  final ValueChanged<LandingSitePoster>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (posters.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: const Text(
          'No uploaded posters in this category yet.',
          style: TextStyle(
            color: _adminPrimaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 520
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posters.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (BuildContext context, int index) {
            final LandingSitePoster poster = posters[index];
            return _PosterAdminCard(
              poster: poster,
              previewBytes: previewBytes[poster.id],
              onDelete: onDelete,
            );
          },
        );
      },
    );
  }
}

class _PosterAdminCard extends StatelessWidget {
  const _PosterAdminCard({
    required this.poster,
    required this.previewBytes,
    required this.onDelete,
  });

  final LandingSitePoster poster;
  final Uint8List? previewBytes;
  final ValueChanged<LandingSitePoster>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF0FDFA),
              child: Center(
                child: previewBytes != null
                    ? Image.memory(
                        previewBytes!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.network(
                        poster.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        errorBuilder: (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Preview failed',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    poster.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete poster',
                  onPressed: onDelete == null ? null : () => onDelete!(poster),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
