// ignore_for_file: unused_element

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/home_category_catalog.dart';
import 'package:mana_poster/features/admin/data/services/firebase_admin_auth_service.dart';
import 'package:mana_poster/features/admin/screens/admin_access_denied_screen.dart';
import 'package:mana_poster/features/admin/screens/admin_login_screen.dart';
import 'package:mana_poster/features/prehome/models/landing_page_config.dart';
import 'package:mana_poster/features/prehome/models/website_poster.dart';
import 'package:mana_poster/features/prehome/screens/web_landing_screen.dart';
import 'package:mana_poster/features/prehome/services/website_admin_service.dart';

const String _websiteRecommendedBannerSize = '1920 x 700 px';

const Map<String, String> _websiteEditorDefaults = <String, String>{
  'customText.headerAppName': 'Mana Poster',
  'customText.navCategories': 'App',
  'customText.navPosters': 'Categories',
  'customText.navFeatures': 'Benefits',
  'customText.navSupport': 'Download',
  'heroEyebrow': 'Telugu poster app for every day',
  'heroTitle': 'Posters, wishes and festival creatives in one joyful app.',
  'heroSubtitle':
      'Mana Poster helps people find ready-to-share designs for daily wishes, festivals, devotional posts, birthdays, events, news and business promotions.',
  'heroPrimaryCtaLabel': 'Get the App',
  'heroSecondaryCtaLabel': 'Available on mobile',
  'categoriesEyebrow': 'POSTER COLLECTIONS',
  'categoriesTitle': 'A colorful library for every moment.',
  'categoriesSubtitle':
      'Festival wishes, daily posts, devotional messages, birthday designs and fresh collections stay easy to recognize.',
  'audienceEyebrow': 'MADE FOR REAL USE',
  'audienceTitle':
      'For greetings, local updates, promotions and personal wishes.',
  'audienceSubtitle':
      'Mana Poster is simple enough for everyday users and useful enough for people who post regularly for community, business and events.',
  'audienceCard1Title': 'Daily wishes',
  'audienceCard1Body': 'Morning, night and positive thought posters.',
  'audienceCard2Title': 'Festivals',
  'audienceCard2Body': 'Seasonal and devotional poster collections.',
  'audienceCard3Title': 'Promotions',
  'audienceCard3Body': 'Business, event and announcement creatives.',
  'audienceCard4Title': 'Personal moments',
  'audienceCard4Body': 'Birthday, anniversary and special day wishes.',
  'promiseEyebrow': 'CLEAR APP VALUE',
  'promiseTitle': 'Everything people need for daily social posting.',
  'promiseSubtitle':
      'The app keeps poster discovery simple: pick the occasion, choose a ready design, add profile details where needed and share it quickly.',
  'promiseCard1Title': 'Occasion-ready',
  'promiseCard1Body':
      'Good morning, birthdays, devotional, news, events and new collections are easy to browse.',
  'promiseCard2Title': 'Profile-friendly',
  'promiseCard2Body':
      'Names, contact details and branding can be used wherever the app supports personalized posters.',
  'promiseCard3Title': 'Share fast',
  'promiseCard3Body':
      'Download and share posters on social platforms without making the user feel lost.',
  'insideEyebrow': 'INSIDE THE APP',
  'insideTitle': 'Everything is arranged for fast poster discovery.',
  'insideSubtitle':
      'The app experience is focused on finding the right poster quickly, keeping useful details ready, and sharing without confusion.',
  'insideCard1Title': 'Saved profile details',
  'insideCard1Body':
      'Keep name, photo, phone and identity details ready for poster use.',
  'insideCard2Title': 'Easy category browsing',
  'insideCard2Body':
      'Daily, festival, devotional, birthday and special collections stay organized.',
  'insideCard3Title': 'Premium collections',
  'insideCard3Body':
      'Useful poster sets and polished designs can be surfaced for regular users.',
  'insideCard4Title': 'Telugu-first feel',
  'insideCard4Body':
      'The app is shaped around Telugu users, local occasions and daily sharing habits.',
  'insideCard5Title': 'Timely updates',
  'insideCard5Body':
      'Fresh posters and important occasion collections are easy to notice.',
  'insideCard6Title': 'Clean downloads',
  'insideCard6Body':
      'Save useful posters and share them on WhatsApp and social platforms.',
  'dailyFlowEyebrow': 'DAILY FLOW',
  'dailyFlowTitle': 'A poster routine that feels simple every morning.',
  'dailyFlowSubtitle':
      'People can open the app, scan today-friendly collections, pick a useful poster, and share it in a few taps.',
  'dailyFlowStep1Title': 'Open today collections',
  'dailyFlowStep1Body': 'Fresh and relevant categories are easy to scan.',
  'dailyFlowStep2Title': 'Select the right design',
  'dailyFlowStep2Body': 'Choose the poster that matches your message.',
  'dailyFlowStep3Title': 'Save and share',
  'dailyFlowStep3Body':
      'Use it for WhatsApp, status, groups or social pages.',
  'useCasesEyebrow': 'HOW PEOPLE USE IT',
  'useCasesTitle':
      'Open the app, find the right design, share with confidence.',
  'useCasesSubtitle':
      'Mana Poster is built for busy users who want clear categories, familiar Telugu-first content and quick sharing.',
  'useCasesStep1Title': 'Choose occasion',
  'useCasesStep1Body':
      'Browse the category that matches the day, festival, event or message.',
  'useCasesStep2Title': 'Pick a poster',
  'useCasesStep2Body':
      'Select a ready design that looks right for your audience.',
  'useCasesStep3Title': 'Download or share',
  'useCasesStep3Body':
      'Save the poster or share it directly wherever you need it.',
  'trustEyebrow': 'WHY IT FEELS EASY',
  'trustTitle': 'Clear categories, familiar content and quick actions.',
  'trustSubtitle':
      'The landing page now explains the app without confusing backend language. Visitors immediately understand what the app is for.',
  'trustPill1': 'Telugu audience',
  'trustPill2': 'Clear categories',
  'trustPill3': 'Poster library',
  'trustPill4': 'Mobile friendly',
  'trustPill5': 'Fast sharing',
  'faqEyebrow': 'COMMON QUESTIONS',
  'faqTitle': 'Visitors should understand the app before installing.',
  'faqSubtitle':
      'These quick answers make the landing page feel complete and reduce confusion for new users.',
  'faq1Question': 'What is Mana Poster?',
  'faq1Answer':
      'It is a Telugu poster app for daily wishes, festivals, devotional posts, birthdays, events and promotions.',
  'faq2Question': 'Can users share posters quickly?',
  'faq2Answer':
      'Yes. The app is designed for fast save and share flows for mobile-first users.',
  'faq3Question': 'Does it support personal details?',
  'faq3Answer':
      'Yes. Saved profile details help users keep identity information ready where the app supports it.',
  'faq4Question': 'Who is it useful for?',
  'faq4Answer':
      'Individuals, local businesses, event organizers, community pages and regular social media users.',
  'downloadEyebrow': 'GET STARTED',
  'downloadTitle':
      'Install Mana Poster and start sharing better creatives.',
  'downloadSubtitle':
      'Keep the public page clear, colorful and useful while the app does the work for posters, wishes and quick sharing.',
  'downloadButtonLabel': 'Install App',
  'footerTagline':
      'Colorful Telugu poster creation for every daily, devotional, festival, and campaign need.',
};

class WebsiteAdminScreen extends StatelessWidget {
  const WebsiteAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAdminAuthService.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WebsiteAdminLoading(message: 'Checking session...');
        }
        final User? user = snapshot.data;
        if (user == null) {
          return const AdminLoginScreen(
            title: 'Website Admin Login',
            subtitle: 'Sign in to edit the public website directly.',
            emailLabel: 'Website Admin Email',
            emailHint: 'website-admin@manaposter.in',
            buttonLabel: 'Open Website Editor',
            footerText: 'Text and images can be edited after login.',
            brandTitle: 'Mana Poster\nWebsite Editor',
            brandSubtitle: 'Live editing for the public landing page.',
            badgeText: 'Website Editor',
            authEmailResolver: _websiteAdminAuthEmail,
          );
        }
        return _WebsiteAdminAuthorization(user: user);
      },
    );
  }
}

String _websiteAdminAuthEmail(String email) {
  final String normalized = email.trim().toLowerCase();
  final int atIndex = normalized.indexOf('@');
  if (atIndex <= 0) {
    return normalized;
  }
  final String local = normalized.substring(0, atIndex);
  final String domain = normalized.substring(atIndex + 1);
  if (local.endsWith('+manaposter-landing')) {
    return normalized;
  }
  return '$local+manaposter-landing@$domain';
}

class _WebsiteAdminAuthorization extends StatefulWidget {
  const _WebsiteAdminAuthorization({required this.user});

  final User user;

  @override
  State<_WebsiteAdminAuthorization> createState() =>
      _WebsiteAdminAuthorizationState();
}

class _WebsiteAdminAuthorizationState
    extends State<_WebsiteAdminAuthorization> {
  final WebsiteAdminService _service = WebsiteAdminService();
  late Future<WebsiteAdminContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _service.loadContent();
  }

  void _retry() {
    setState(() {
      _contentFuture = _service.loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebsiteAdminContent>(
      future: _contentFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebsiteAdminContent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _WebsiteAdminLoading(
                message: 'Opening website editor...',
              );
            }
            if (snapshot.hasData) {
              return WebsiteAdminDashboard(
                initialContent: snapshot.data!,
                service: _service,
              );
            }
            final Object? error = snapshot.error;
            return AdminAccessDeniedScreen(
              email: widget.user.email,
              message: error is WebsiteAdminFailure
                  ? error.message
                  : 'This account is not allowed for Website Admin.',
              onRetry: _retry,
              onLogout: FirebaseAdminAuthService.instance.signOut,
            );
          },
    );
  }
}

class WebsiteAdminDashboard extends StatefulWidget {
  const WebsiteAdminDashboard({
    super.key,
    required this.initialContent,
    required this.service,
  });

  final WebsiteAdminContent initialContent;
  final WebsiteAdminService service;

  @override
  State<WebsiteAdminDashboard> createState() => _WebsiteAdminDashboardState();
}

class _WebsiteAdminDashboardState extends State<WebsiteAdminDashboard> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, bool> _switches = <String, bool>{};

  late WebsiteAdminContent _content;
  bool _saving = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _content = widget.initialContent;
    _emailController.text = _content.adminPrimaryEmail;
    _categoryController.text = HomeCategoryCatalog.uploadable.first.id;
    _hydrate(_content.config);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _categoryController.dispose();
    _sortOrderController.dispose();
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _hydrate(LandingPageConfig config) {
    final Map<String, dynamic> data = config.toMap();
    for (final _EditableTextField field in _editableTextFields) {
      final TextEditingController controller = _controllers.putIfAbsent(
        field.key,
        TextEditingController.new,
      );
      if (field.key.startsWith('customText.')) {
        final String customKey = field.key.substring('customText.'.length);
        final String fallback = _websiteEditorDefaults[customKey] ?? '';
        final String current = (config.customText[customKey] ?? '').trim();
        controller.text = current.isEmpty ? fallback : current;
      } else {
        final String fallback = _websiteEditorDefaults[field.key] ?? '';
        final String current = (data[field.key] as String? ?? '').trim();
        controller.text = current.isEmpty ? fallback : current;
      }
    }
    for (final _SwitchField field in _switchFields) {
      _switches[field.key] = data[field.key] as bool? ?? true;
    }
  }

  Future<void> _refresh() async {
    await _run('Website content refreshed.', () async {
      _content = await widget.service.loadContent();
      _emailController.text = _content.adminPrimaryEmail;
      _hydrate(_content.config);
      _sortOrderController.text = '${_nextSortOrderForCategory(_categoryId)}';
    });
  }

  Future<void> _saveConfig() async {
    await _run('Website edits saved.', () async {
      final Map<String, dynamic> data = _draftConfigMap();
      final LandingPageConfig nextConfig = LandingPageConfig.fromMap(data);
      await widget.service.saveConfig(nextConfig);
      _content = await widget.service.loadContent();
      _hydrate(_content.config);
    });
  }

  Future<void> _uploadConfigImage({
    required String key,
    required Future<WebsiteAssetUploadResult> Function({
      required String fileName,
      required String contentType,
      required Uint8List bytes,
    })
    upload,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 94,
    );
    if (file == null) {
      return;
    }
    await _run('Image uploaded.', () async {
      final Uint8List bytes = await file.readAsBytes();
      final WebsiteAssetUploadResult result = await upload(
        fileName: file.name,
        contentType: _contentType(file.name),
        bytes: bytes,
      );
      _controllers.putIfAbsent(key, TextEditingController.new).text =
          result.downloadUrl;
      final Map<String, dynamic> data = _draftConfigMap();
      await widget.service.saveConfig(LandingPageConfig.fromMap(data));
      _content = await widget.service.loadContent();
      _hydrate(_content.config);
    });
  }

  Future<void> _uploadPoster() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 96,
    );
    if (file == null) {
      return;
    }
    await _run('Poster uploaded.', () async {
      final Uint8List bytes = await file.readAsBytes();
      final WebsiteAssetUploadResult upload = await widget.service
          .uploadPosterImage(
            fileName: file.name,
            contentType: _contentType(file.name),
            bytes: bytes,
          );
      await widget.service.upsertPoster(
        category: _categoryId,
        imageUrl: upload.downloadUrl,
        sortOrder: _nextSortOrderForCategory(_categoryId),
        active: true,
      );
      _content = await widget.service.loadContent();
      _sortOrderController.text = '${_nextSortOrderForCategory(_categoryId)}';
    });
  }

  Future<void> _togglePoster(WebsitePoster poster) async {
    await _run(poster.active ? 'Poster hidden.' : 'Poster visible.', () async {
      await widget.service.upsertPoster(
        posterId: poster.id,
        category: poster.category,
        imageUrl: poster.imageUrl,
        sortOrder: poster.sortOrder,
        active: !poster.active,
      );
      _content = await widget.service.loadContent();
    });
  }

  Future<void> _replacePosterImage(WebsitePoster poster) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 96,
    );
    if (file == null) {
      return;
    }
    await _run('Poster updated.', () async {
      final Uint8List bytes = await file.readAsBytes();
      final WebsiteAssetUploadResult upload = await widget.service
          .uploadPosterImage(
            fileName: file.name,
            contentType: _contentType(file.name),
            bytes: bytes,
          );
      await widget.service.upsertPoster(
        posterId: poster.id,
        category: poster.category,
        imageUrl: upload.downloadUrl,
        sortOrder: poster.sortOrder,
        active: poster.active,
      );
      _content = await widget.service.loadContent();
    });
  }

  Future<void> _deletePoster(WebsitePoster poster) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete image?'),
          content: const Text('This removes the image from the website list.'),
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
    if (confirmed != true) {
      return;
    }
    await _run('Poster deleted.', () async {
      await widget.service.deletePoster(poster.id);
      _content = await widget.service.loadContent();
    });
  }

  Future<void> _updateCredentials() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    if (!email.contains('@') || password.length < 6) {
      setState(() {
        _statusText = 'Enter a valid email and at least 6 character password.';
      });
      return;
    }
    await _run('Website admin credentials updated.', () async {
      final String primaryEmail = await widget.service.updateAdminCredentials(
        newEmail: email,
        newPassword: password,
      );
      _passwordController.clear();
      _content = WebsiteAdminContent(
        config: _content.config,
        posters: _content.posters,
        adminPrimaryEmail: primaryEmail,
      );
    });
  }

  Future<void> _run(String success, Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _statusText = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() => _statusText = success);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusText = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String get _categoryId {
    final String value = _categoryController.text.trim();
    if (value.isNotEmpty) {
      return value;
    }
    return HomeCategoryCatalog.uploadable.first.id;
  }

  List<WebsitePoster> _postersForCategory(String categoryId) {
    return _content.posters
        .where((WebsitePoster poster) {
          final String posterCategory = HomeCategoryCatalog.normalizeKey(
            poster.category,
          );
          return posterCategory == categoryId ||
              poster.category.toLowerCase() == categoryId.toLowerCase();
        })
        .toList(growable: false)
      ..sort(
        (WebsitePoster a, WebsitePoster b) =>
            a.sortOrder.compareTo(b.sortOrder),
      );
  }

  int _nextSortOrderForCategory(String categoryId) {
    final List<WebsitePoster> posters = _postersForCategory(categoryId);
    if (posters.isEmpty) {
      return 1;
    }
    return posters
            .map((WebsitePoster item) => item.sortOrder)
            .reduce((int a, int b) => a > b ? a : b) +
        1;
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _categoryController.text = categoryId;
      _sortOrderController.text = '${_nextSortOrderForCategory(categoryId)}';
    });
  }

  LandingPageConfig _draftConfig() {
    return LandingPageConfig.fromMap(_draftConfigMap());
  }

  Map<String, dynamic> _draftConfigMap() {
    final Map<String, dynamic> data = _content.config.toMap();
    final Map<String, String> customText = Map<String, String>.from(
      _content.config.customText,
    );
    for (final MapEntry<String, TextEditingController> entry
        in _controllers.entries) {
      if (entry.key.startsWith('customText.')) {
        customText[entry.key.substring('customText.'.length)] = entry.value.text
            .trim();
      } else {
        data[entry.key] = entry.value.text.trim();
      }
    }
    for (final MapEntry<String, bool> entry in _switches.entries) {
      data[entry.key] = entry.value;
    }
    data['customText'] = customText;
    return data;
  }

  Future<void> _openContentEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        final bool compact = MediaQuery.sizeOf(context).width < 720;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            void changed() {
              modalSetState(() {});
              setState(() {});
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              minChildSize: 0.42,
              maxChildSize: 0.96,
              builder: (BuildContext context, ScrollController scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 24,
                    14,
                    compact ? 16 : 24,
                    24,
                  ),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Edit landing page content',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: Navigator.of(context).pop,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Live website editor',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'This screen mirrors manaposter.in. Edit here, save here, and the public landing page updates from the same CMS data.',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Banner upload recommended size: 1920 x 700 px',
                            style: TextStyle(
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _uploadConfigImage(
                                  key: 'heroImageUrl',
                                  upload: widget.service.uploadHeroImage,
                                ),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Hero image'),
                        ),
                        FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _uploadConfigImage(
                                  key: 'previewImageUrl',
                                  upload: widget.service.uploadPreviewImage,
                                ),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Preview image'),
                        ),
                        FilledButton.icon(
                          onPressed: _saving ? null : _uploadPoster,
                          icon: const Icon(Icons.upload_rounded),
                          label: const Text('Upload poster'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CategorySelector(
                      selectedId: _categoryId,
                      onSelected: (String id) {
                        _selectCategory(id);
                        changed();
                      },
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _editableTextFields
                          .map((field) {
                            return SizedBox(
                              width: compact || field.large
                                  ? double.infinity
                                  : 360,
                              child: TextField(
                                controller: _controllers[field.key],
                                minLines: field.large ? 2 : 1,
                                maxLines: field.large ? 5 : 1,
                                onChanged: (_) => changed(),
                                decoration: InputDecoration(
                                  labelText: field.label,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: _switchFields
                          .map((field) {
                            return SizedBox(
                              width: compact ? double.infinity : 260,
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(field.label),
                                value: _switches[field.key] ?? true,
                                onChanged: _saving
                                    ? null
                                    : (bool value) {
                                        _switches[field.key] = value;
                                        changed();
                                      },
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const Divider(height: 34),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Website admin email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New website admin password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _updateCredentials,
                        icon: const Icon(Icons.key_rounded),
                        label: const Text('Update Website Login'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _editableHeader(bool compact) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: compact ? 70 : 78,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 42),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFFFE0B2), width: 1),
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/branding/mana_poster_logo.png',
                  width: compact ? 42 : 48,
                  height: compact ? 42 : 48,
                  errorBuilder: (_, _, _) => Container(
                    width: compact ? 42 : 48,
                    height: compact ? 42 : 48,
                    color: const Color(0xFFFF5A5F),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: compact ? 138 : 182,
                child: _InlineTextField(
                  controller: _controllers['customText.headerAppName'],
                  hint: AppPublicInfo.appName,
                  title: false,
                ),
              ),
              const Spacer(),
              if (!compact) ...<Widget>[
                _HeaderInlineField(
                  controller: _controllers['customText.navCategories'],
                  hint: 'Categories',
                ),
                _HeaderInlineField(
                  controller: _controllers['customText.navPosters'],
                  hint: 'Posters',
                ),
                _HeaderInlineField(
                  controller: _controllers['customText.navFeatures'],
                  hint: 'Features',
                ),
                _HeaderInlineField(
                  controller: _controllers['customText.navSupport'],
                  hint: 'Support',
                ),
                const SizedBox(width: 12),
              ],
              SizedBox(
                width: compact ? 112 : 148,
                child: _InlineTextField(
                  controller: _controllers['heroPrimaryCtaLabel'],
                  hint: compact ? 'Install' : 'Install App',
                  buttonLike: true,
                  centered: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editableHero(bool compact) {
    return Column(
      children: <Widget>[
        _LiveHeroEditor(
          compact: compact,
          imageUrl: _controllers['heroImageUrl']?.text ?? '',
          primaryCta: _controllers['heroPrimaryCtaLabel'],
          secondaryCta: _controllers['heroSecondaryCtaLabel'],
          onUpload: _saving
              ? null
              : () => _uploadConfigImage(
                  key: 'heroImageUrl',
                  upload: widget.service.uploadHeroImage,
                ),
        ),
        _AdminPageBand(
          top: 24,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Banner upload recommended size: 1920 x 700 px',
                  style: TextStyle(
                    color: Color(0xFF6D28D9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _InlineTextField(
                  controller: _controllers['heroEyebrow'],
                  hint: 'Hero eyebrow',
                  small: true,
                ),
                const SizedBox(height: 8),
                _InlineTextField(
                  controller: _controllers['heroTitle'],
                  hint: 'Hero title',
                  title: true,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                _InlineTextField(
                  controller: _controllers['heroSubtitle'],
                  hint: 'Hero subtitle',
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _editableCategoryArea(bool compact) {
    final HomeCategoryCatalogEntry selectedCategory =
        HomeCategoryCatalog.byRawCategory(_categoryId) ??
        HomeCategoryCatalog.uploadable.first;
    final List<WebsitePoster> selectedPosters = _postersForCategory(
      selectedCategory.id,
    );
    return _AdminPageBand(
      top: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _EditableSectionHeading(
            eyebrow: _controllers['categoriesEyebrow'],
            title: _controllers['categoriesTitle'],
            subtitle: _controllers['categoriesSubtitle'],
          ),
          const SizedBox(height: 18),
          _CategorySelector(
            selectedId: selectedCategory.id,
            onSelected: _selectCategory,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Upload box ready for 1080 x 1080 posters',
              style: TextStyle(
                color: const Color(0xFF6D28D9),
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SquareUploadBox(
            label: selectedCategory.label,
            onUpload: _saving ? null : _uploadPoster,
          ),
          const SizedBox(height: 24),
          _CategoryTitleCardAdmin(category: selectedCategory),
          const SizedBox(height: 16),
          if (selectedPosters.isEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFB923C)),
              ),
              child: const Text(
                'Uploaded posters will appear here.',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Recent uploads',
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Uploaded posters stay ready here with original ratio preview, replace, hide, and delete actions.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: selectedPosters
                      .map((WebsitePoster poster) {
                        return _OriginalRatioPosterTile(
                          poster: poster,
                          onToggle: _saving
                              ? null
                              : () => _togglePoster(poster),
                          onReplace: _saving
                              ? null
                              : () => _replacePosterImage(poster),
                          onDelete: _saving
                              ? null
                              : () => _deletePoster(poster),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _editableFeatureArea() {
    return _AdminPageBand(
      top: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _EditableSectionHeading(
            eyebrow: _controllers['featuresEyebrow'],
            title: _controllers['featuresTitle'],
            subtitle: _controllers['featuresSubtitle'],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.4 : 1.45,
                children: <Widget>[
                  _EditableFeatureCard(
                    icon: Icons.collections_rounded,
                    title: _controllers['customText.feature1Title'],
                    body: _controllers['customText.feature1Body'],
                    titleHint: 'Ready-made poster library',
                    bodyHint:
                        'Festival, devotional, birthday, political, and daily-use posters are ready to browse.',
                    colors: const <Color>[Color(0xFF4C1D95), Color(0xFF6D28D9)],
                  ),
                  _EditableFeatureCard(
                    icon: Icons.account_circle_rounded,
                    title: _controllers['customText.feature2Title'],
                    body: _controllers['customText.feature2Body'],
                    titleHint: 'Profile-based auto fill',
                    bodyHint:
                        'Name, photo, designation, and phone number can be saved once and reused automatically on posters.',
                    colors: const <Color>[Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  _EditableFeatureCard(
                    icon: Icons.auto_awesome_rounded,
                    title: _controllers['customText.feature3Title'],
                    body: _controllers['customText.feature3Body'],
                    titleHint: 'Featured templates',
                    bodyHint:
                        'Polished poster collections are organized by category and ready to use.',
                    colors: const <Color>[Color(0xFF7C3AED), Color(0xFF60A5FA)],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _editableFlowArea(bool compact) {
    return _LivePreviewEditor(
      compact: compact,
      imageUrl: _controllers['previewImageUrl']?.text ?? '',
      eyebrow: _controllers['previewEyebrow'],
      title: _controllers['previewTitle'],
      subtitle: _controllers['previewSubtitle'],
      step1: _controllers['customText.flowStep1'],
      step2: _controllers['customText.flowStep2'],
      step3: _controllers['customText.flowStep3'],
      step4: _controllers['customText.flowStep4'],
      onUpload: _saving
          ? null
          : () => _uploadConfigImage(
              key: 'previewImageUrl',
              upload: widget.service.uploadPreviewImage,
            ),
    );
  }

  Widget _editableWhyArea() {
    return _AdminPageBand(
      top: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _EditableSectionHeading(
            eyebrow: _controllers['dynamicEventsEyebrow'],
            title: _controllers['dynamicEventsTitle'],
            subtitle: _controllers['dynamicEventsSubtitle'],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _ReasonPillAdmin(
                icon: Icons.bolt_rounded,
                label: 'Fast creation',
              ),
              _ReasonPillAdmin(
                icon: Icons.language_rounded,
                label: 'Telugu audience',
              ),
              _ReasonPillAdmin(
                icon: Icons.category_rounded,
                label: 'Category-first',
              ),
              _ReasonPillAdmin(
                icon: Icons.auto_awesome_rounded,
                label: 'Colorful templates',
              ),
              _ReasonPillAdmin(
                icon: Icons.mobile_friendly_rounded,
                label: 'Mobile focused',
              ),
              _ReasonPillAdmin(
                icon: Icons.campaign_rounded,
                label: 'Campaign ready',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editableDownloadArea() {
    return _LiveDownloadEditor(
      eyebrow: _controllers['downloadEyebrow'],
      title: _controllers['downloadTitle'],
      subtitle: _controllers['downloadSubtitle'],
      button: _controllers['downloadButtonLabel'],
    );
  }

  Widget _editableFooterArea() {
    return Container(
      margin: const EdgeInsets.only(top: 68),
      padding: const EdgeInsets.fromLTRB(24, 46, 24, 120),
      color: const Color(0xFF111827),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 24,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 440,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 260,
                      child: _InlineTextField(
                        controller: _controllers['customText.headerAppName'],
                        hint: AppPublicInfo.appName,
                        title: true,
                        dark: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InlineTextField(
                      controller: _controllers['footerTagline'],
                      hint:
                          'Colorful Telugu poster creation for every daily, devotional, festival, and campaign need.',
                      maxLines: 4,
                      dark: true,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 180,
                child: _InlineTextField(
                  controller: _controllers['downloadButtonLabel'],
                  hint: 'Install App',
                  buttonLike: true,
                  centered: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 720;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF3),
      body: Stack(
        children: <Widget>[
          WebsiteInlineEditableLandingPage(
            config: _draftConfig(),
            posters: _content.posters,
            controllers: _controllers,
            selectedCategoryId: _categoryId,
            onSelectedCategory: _selectCategory,
            onUploadBanner: _saving
                ? null
                : () => _uploadConfigImage(
                    key: 'heroImageUrl',
                    upload: widget.service.uploadHeroImage,
                  ),
            onUploadPoster: _saving ? null : _uploadPoster,
            onTogglePoster: (WebsitePoster poster) {
              if (_saving) {
                return;
              }
              _togglePoster(poster);
            },
            onReplacePoster: (WebsitePoster poster) {
              if (_saving) {
                return;
              }
              _replacePosterImage(poster);
            },
            onDeletePoster: (WebsitePoster poster) {
              if (_saving) {
                return;
              }
              _deletePoster(poster);
            },
            onInstall: () {},
            onDemo: () {},
            onPrivacy: () {},
            onTerms: () {},
            bannerSizeLabel: _websiteRecommendedBannerSize,
          ),
          Positioned(
            left: compact ? 10 : 24,
            right: compact ? 10 : 24,
            bottom: compact ? 10 : 18,
            child: _FloatingSaveBar(
              statusText: _statusText,
              saving: _saving,
              onRefresh: _refresh,
              onSave: _saveConfig,
              onLogout: FirebaseAdminAuthService.instance.signOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPublicHeader extends StatelessWidget {
  const _AdminPublicHeader({required this.compact, required this.installLabel});

  final bool compact;
  final String installLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 1,
      shadowColor: const Color(0x1A111827),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 30),
            child: Row(
              children: <Widget>[
                Image.asset(
                  'assets/branding/mana_poster_logo.png',
                  width: 42,
                  height: 42,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Color(0xFF6D28D9),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  AppPublicInfo.appName,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                if (!compact) ...const <Widget>[
                  _HeaderText(label: 'Categories'),
                  _HeaderText(label: 'Posters'),
                  _HeaderText(label: 'Features'),
                  _HeaderText(label: 'Support'),
                ],
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    compact
                        ? 'Install'
                        : installLabel.trim().isEmpty
                        ? 'Install App'
                        : installLabel,
                  ),
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: const Color(0xFFF97316),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderInlineField extends StatelessWidget {
  const _HeaderInlineField({required this.controller, required this.hint});

  final TextEditingController? controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: _InlineTextField(
        controller: controller,
        hint: hint,
        small: true,
        centered: true,
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SquareUploadBox extends StatelessWidget {
  const _SquareUploadBox({required this.label, required this.onUpload});

  final String label;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side = constraints.maxWidth >= 360
            ? 320
            : constraints.maxWidth;
        return SizedBox(
          width: side,
          height: side,
          child: OutlinedButton(
            onPressed: onUpload,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6D28D9),
              side: const BorderSide(color: Color(0xFFDDD6FE), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.add_photo_alternate_rounded, size: 42),
                const SizedBox(height: 10),
                Text(
                  '+ Upload $label poster\n1080 x 1080',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveHeroEditor extends StatelessWidget {
  const _LiveHeroEditor({
    required this.compact,
    required this.imageUrl,
    required this.primaryCta,
    required this.secondaryCta,
    required this.onUpload,
  });

  final bool compact;
  final String imageUrl;
  final TextEditingController? primaryCta;
  final TextEditingController? secondaryCta;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 320 : 560,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (imageUrl.trim().isEmpty)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFFFB703),
                    Color(0xFFFF7A00),
                    Color(0xFFE11D48),
                  ],
                ),
              ),
            )
          else
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFFFFB703),
                      Color(0xFFFF7A00),
                      Color(0xFFE11D48),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 14,
            right: 14,
            child: _UploadIconButton(onPressed: onUpload),
          ),
          Positioned(
            left: compact ? 16 : 42,
            right: compact ? 16 : 42,
            bottom: compact ? 18 : 34,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: compact ? 170 : 210,
                  child: _InlineTextField(
                    controller: primaryCta,
                    hint: 'Play Store',
                    buttonLike: true,
                    centered: true,
                  ),
                ),
                SizedBox(
                  width: compact ? 180 : 220,
                  child: _InlineTextField(
                    controller: secondaryCta,
                    hint: 'Watch Demo',
                    buttonLike: true,
                    outlined: true,
                    centered: true,
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

class _AdminPageBand extends StatelessWidget {
  const _AdminPageBand({required this.child, this.top = 0});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, top, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _EditableSectionHeading extends StatelessWidget {
  const _EditableSectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final TextEditingController? eyebrow;
  final TextEditingController? title;
  final TextEditingController? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InlineTextField(
          controller: eyebrow,
          hint: 'Section eyebrow',
          small: true,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _InlineTextField(
            controller: title,
            hint: 'Section title',
            title: true,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _InlineTextField(
            controller: subtitle,
            hint: 'Section subtitle',
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}

class _LiveFeatureEditor extends StatelessWidget {
  const _LiveFeatureEditor({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final TextEditingController? eyebrow;
  final TextEditingController? title;
  final TextEditingController? subtitle;

  @override
  Widget build(BuildContext context) {
    return _AdminPageBand(
      top: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _EditableSectionHeading(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.4 : 1.45,
                children: const <Widget>[
                  _AdminFeatureCard(
                    icon: Icons.collections_rounded,
                    title: 'Ready-made poster library',
                    body:
                        'Festival, devotional, birthday, political, and daily-use posters are ready to browse.',
                    colors: <Color>[Color(0xFF4C1D95), Color(0xFF6D28D9)],
                  ),
                  _AdminFeatureCard(
                    icon: Icons.account_circle_rounded,
                    title: 'Profile-based auto fill',
                    body:
                        'Name, photo, designation, and phone number can be saved once and reused automatically on posters.',
                    colors: <Color>[Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  _AdminFeatureCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Featured templates',
                    body:
                        'Polished poster collections are organized by category and ready to use.',
                    colors: <Color>[Color(0xFF7C3AED), Color(0xFF60A5FA)],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminFeatureCard extends StatelessWidget {
  const _AdminFeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableFeatureCard extends StatelessWidget {
  const _EditableFeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.titleHint,
    required this.bodyHint,
    required this.colors,
  });

  final IconData icon;
  final TextEditingController? title;
  final TextEditingController? body;
  final String titleHint;
  final String bodyHint;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          _InlineTextField(controller: title, hint: titleHint, maxLines: 2),
          const SizedBox(height: 8),
          _InlineTextField(controller: body, hint: bodyHint, maxLines: 4),
        ],
      ),
    );
  }
}

class _ReasonPillAdmin extends StatelessWidget {
  const _ReasonPillAdmin({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCategoryEditor extends StatelessWidget {
  const _LiveCategoryEditor({
    required this.compact,
    required this.selectedCategory,
    required this.selectedPosters,
    required this.onCategorySelected,
    required this.onUpload,
    required this.onTogglePoster,
    required this.onDeletePoster,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final bool compact;
  final HomeCategoryCatalogEntry selectedCategory;
  final List<WebsitePoster> selectedPosters;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onUpload;
  final ValueChanged<WebsitePoster>? onTogglePoster;
  final ValueChanged<WebsitePoster>? onDeletePoster;
  final TextEditingController? eyebrow;
  final TextEditingController? title;
  final TextEditingController? subtitle;

  @override
  Widget build(BuildContext context) {
    return _AdminPageBand(
      top: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _EditableSectionHeading(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 18),
          _CategorySelector(
            selectedId: selectedCategory.id,
            onSelected: onCategorySelected,
          ),
          const SizedBox(height: 38),
          _CategoryTitleCardAdmin(category: selectedCategory),
          const SizedBox(height: 16),
          if (selectedPosters.isEmpty)
            _UploadDropArea(label: selectedCategory.label, onUpload: onUpload)
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: <Widget>[
                _UploadPosterTile(
                  label: selectedCategory.label,
                  onUpload: onUpload,
                ),
                ...selectedPosters.map((WebsitePoster poster) {
                  return _OriginalRatioPosterTile(
                    poster: poster,
                    onToggle: onTogglePoster == null
                        ? null
                        : () => onTogglePoster!(poster),
                    onDelete: onDeletePoster == null
                        ? null
                        : () => onDeletePoster!(poster),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryTitleCardAdmin extends StatelessWidget {
  const _CategoryTitleCardAdmin({required this.category});

  final HomeCategoryCatalogEntry category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: category.gradient),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              category.badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${category.label} posters',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Unlimited poster uploads can live under each category.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveDownloadEditor extends StatelessWidget {
  const _LiveDownloadEditor({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.button,
  });

  final TextEditingController? eyebrow;
  final TextEditingController? title;
  final TextEditingController? subtitle;
  final TextEditingController? button;

  @override
  Widget build(BuildContext context) {
    return _AdminPageBand(
      top: 62,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFB923C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _EditableSectionHeading(
              eyebrow: eyebrow,
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              child: _InlineTextField(
                controller: button,
                hint: 'Download App',
                buttonLike: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePreviewEditor extends StatelessWidget {
  const _LivePreviewEditor({
    required this.compact,
    required this.imageUrl,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.step1,
    required this.step2,
    required this.step3,
    required this.step4,
    required this.onUpload,
  });

  final bool compact;
  final String imageUrl;
  final TextEditingController? eyebrow;
  final TextEditingController? title;
  final TextEditingController? subtitle;
  final TextEditingController? step1;
  final TextEditingController? step2;
  final TextEditingController? step3;
  final TextEditingController? step4;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return _AdminPageBand(
      top: 62,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF4C1D95),
              Color(0xFF6D28D9),
              Color(0xFF9333EA),
              Color(0xFF0EA5E9),
              Color(0xFFF97316),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: compact ? 0 : 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _InlineTextField(
                    controller: eyebrow,
                    hint: 'Preview eyebrow',
                    small: true,
                    dark: true,
                  ),
                  _InlineTextField(
                    controller: title,
                    hint: 'Preview title',
                    title: true,
                    dark: true,
                  ),
                  _InlineTextField(
                    controller: subtitle,
                    hint: 'Preview subtitle',
                    maxLines: 4,
                    dark: true,
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 0 : 26, height: compact ? 18 : 0),
            Expanded(
              flex: compact ? 0 : 4,
              child: Column(
                children: <Widget>[
                  _EditableImagePanel(
                    imageUrl: imageUrl,
                    compact: compact,
                    onUpload: onUpload,
                  ),
                  const SizedBox(height: 12),
                  _EditableFlowStepAdmin(
                    number: '01',
                    controller: step1,
                    hint: 'Select category',
                  ),
                  _EditableFlowStepAdmin(
                    number: '02',
                    controller: step2,
                    hint: 'Choose ready-made poster',
                  ),
                  _EditableFlowStepAdmin(
                    number: '03',
                    controller: step3,
                    hint: 'Use saved profile details',
                  ),
                  _EditableFlowStepAdmin(
                    number: '04',
                    controller: step4,
                    hint: 'Download/share',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableImagePanel extends StatelessWidget {
  const _EditableImagePanel({
    required this.imageUrl,
    required this.compact,
    required this.onUpload,
  });

  final String imageUrl;
  final bool compact;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: Color(0x33FFFFFF)),
            if (imageUrl.trim().isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Center(child: _UploadIconButton(onPressed: onUpload)),
          ],
        ),
      ),
    );
  }
}

class _FlowStepAdmin extends StatelessWidget {
  const _FlowStepAdmin({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: <Widget>[
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableFlowStepAdmin extends StatelessWidget {
  const _EditableFlowStepAdmin({
    required this.number,
    required this.controller,
    required this.hint,
  });

  final String number;
  final TextEditingController? controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: <Widget>[
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _InlineTextField(
              controller: controller,
              hint: hint,
              dark: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDropArea extends StatelessWidget {
  const _UploadDropArea({required this.label, required this.onUpload});

  final String label;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 260,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onUpload,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: Text('Upload $label image'),
      ),
    );
  }
}

class _UploadPosterTile extends StatelessWidget {
  const _UploadPosterTile({required this.label, required this.onUpload});

  final String label;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 180,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onUpload,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.add_rounded, size: 34),
            const SizedBox(height: 8),
            Text('Upload $label'),
          ],
        ),
      ),
    );
  }
}

class _AdvancedWebsiteSettings extends StatelessWidget {
  const _AdvancedWebsiteSettings({
    required this.compact,
    required this.controllers,
    required this.switches,
    required this.saving,
    required this.onSwitchChanged,
    required this.emailController,
    required this.passwordController,
    required this.onUpdateCredentials,
  });

  final bool compact;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> switches;
  final bool saving;
  final void Function(String key, bool value) onSwitchChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onUpdateCredentials;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 64,
          vertical: compact ? 24 : 40,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Advanced settings',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          childrenPadding: const EdgeInsets.only(top: 18, bottom: 8),
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _editableTextFields
                  .where((field) => !_primaryInlineKeys.contains(field.key))
                  .map((field) {
                    return SizedBox(
                      width: compact || field.large ? double.infinity : 360,
                      child: TextField(
                        controller: controllers[field.key],
                        minLines: field.large ? 2 : 1,
                        maxLines: field.large ? 5 : 1,
                        decoration: InputDecoration(
                          labelText: field.label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _switchFields
                  .map((field) {
                    return SizedBox(
                      width: compact ? double.infinity : 260,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(field.label),
                        value: switches[field.key] ?? true,
                        onChanged: saving
                            ? null
                            : (bool value) => onSwitchChanged(field.key, value),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
            const Divider(height: 34),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Website admin email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New website admin password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: saving ? null : onUpdateCredentials,
                icon: const Icon(Icons.key_rounded),
                label: const Text('Update Website Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingSaveBar extends StatelessWidget {
  const _FloatingSaveBar({
    required this.statusText,
    required this.saving,
    required this.onRefresh,
    required this.onSave,
    required this.onLogout,
  });

  final String? statusText;
  final bool saving;
  final VoidCallback onRefresh;
  final VoidCallback onSave;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 720;
        return Material(
          elevation: 12,
          shadowColor: const Color(0x330F172A),
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        statusText ??
                            'Tap text directly to edit. Use + upload boxes for images.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: saving
                              ? const Color(0xFFB45309)
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: saving ? null : onRefresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh'),
                          ),
                          FilledButton.icon(
                            onPressed: saving ? null : onSave,
                            icon: const Icon(Icons.save_rounded),
                            label: Text(saving ? 'Saving' : 'Save'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          statusText ??
                              'Tap text directly to edit. Use + upload boxes for images.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: saving
                                ? const Color(0xFFB45309)
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: saving ? null : onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      FilledButton.icon(
                        onPressed: saving ? null : onSave,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(saving ? 'Saving' : 'Save'),
                      ),
                      IconButton(
                        tooltip: 'Logout',
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _InlineTextField extends StatelessWidget {
  const _InlineTextField({
    required this.controller,
    required this.hint,
    this.title = false,
    this.small = false,
    this.buttonLike = false,
    this.outlined = false,
    this.dark = false,
    this.centered = false,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String hint;
  final bool title;
  final bool small;
  final bool buttonLike;
  final bool outlined;
  final bool dark;
  final bool centered;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      color: dark ? Colors.white : const Color(0xFF0F172A),
      fontSize: title
          ? 40
          : small
          ? 14
          : buttonLike
          ? 15
          : 16,
      fontWeight: title || small || buttonLike
          ? FontWeight.w900
          : FontWeight.w700,
      height: title ? 1.08 : 1.5,
    );
    final Color fill = buttonLike
        ? outlined
              ? Colors.white.withValues(alpha: 0.88)
              : const Color(0xFFF97316)
        : Colors.transparent;
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: TextField(
        controller: controller,
        minLines: maxLines > 1 ? 2 : 1,
        maxLines: maxLines,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        cursorColor: dark ? Colors.white : const Color(0xFF7C3AED),
        style: buttonLike && !outlined
            ? style.copyWith(color: Colors.white)
            : style,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: buttonLike,
          fillColor: fill,
          contentPadding: buttonLike
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
              : const EdgeInsets.symmetric(vertical: 6),
          border: buttonLike
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(
                    color: outlined
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFFF97316),
                  ),
                )
              : InputBorder.none,
          focusedBorder: buttonLike
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(
                    color: outlined
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFFF97316),
                  ),
                )
              : InputBorder.none,
          enabledBorder: buttonLike
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(
                    color: outlined
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFFF97316),
                  ),
                )
              : InputBorder.none,
          errorBorder: buttonLike ? null : InputBorder.none,
          focusedErrorBorder: buttonLike ? null : InputBorder.none,
        ),
      ),
    );
  }
}

class _UploadIconButton extends StatelessWidget {
  const _UploadIconButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        tooltip: 'Upload image',
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HomeCategoryCatalog.uploadable
          .map((entry) {
            final bool selected = entry.id == selectedId;
            return ChoiceChip(
              selected: selected,
              label: Text(entry.label),
              onSelected: (_) => onSelected(entry.id),
              selectedColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w800,
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _OriginalRatioPosterTile extends StatelessWidget {
  const _OriginalRatioPosterTile({
    required this.poster,
    required this.onToggle,
    this.onReplace,
    required this.onDelete,
  });

  final WebsitePoster poster;
  final VoidCallback? onToggle;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  poster.imageUrl,
                  width: 244,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 160,
                    child: ColoredBox(
                      color: Color(0xFFE5E7EB),
                      child: Center(child: Icon(Icons.broken_image_rounded)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      poster.active ? 'Visible' : 'Hidden',
                      style: TextStyle(
                        color: poster.active
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: poster.active ? 'Hide' : 'Show',
                    onPressed: onToggle,
                    icon: Icon(
                      poster.active
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Replace image',
                    onPressed: onReplace,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebsiteAdminLoading extends StatelessWidget {
  const _WebsiteAdminLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _EditableTextField {
  const _EditableTextField(this.key, this.label, {this.large = false});

  final String key;
  final String label;
  final bool large;
}

class _SwitchField {
  const _SwitchField(this.key, this.label);

  final String key;
  final String label;
}

const Set<String> _primaryInlineKeys = <String>{
  'heroEyebrow',
  'heroTitle',
  'heroSubtitle',
  'heroPrimaryCtaLabel',
  'heroSecondaryCtaLabel',
  'heroImageUrl',
  'featuresEyebrow',
  'featuresTitle',
  'featuresSubtitle',
  'previewEyebrow',
  'previewTitle',
  'previewSubtitle',
  'previewImageUrl',
};

const List<_EditableTextField> _editableTextFields = <_EditableTextField>[
  _EditableTextField('customText.headerAppName', 'Header App Name'),
  _EditableTextField('customText.navCategories', 'Nav Categories'),
  _EditableTextField('customText.navPosters', 'Nav Posters'),
  _EditableTextField('customText.navFeatures', 'Nav Features'),
  _EditableTextField('customText.navSupport', 'Nav Support'),
  _EditableTextField('downloadUrl', 'Download URL'),
  _EditableTextField('watchDemoUrl', 'Watch Demo URL'),
  _EditableTextField('supportEmail', 'Support Email'),
  _EditableTextField('facebookUrl', 'Facebook URL'),
  _EditableTextField('instagramUrl', 'Instagram URL'),
  _EditableTextField('youtubeUrl', 'YouTube URL'),
  _EditableTextField('heroEyebrow', 'Hero Eyebrow'),
  _EditableTextField('heroTitle', 'Hero Title'),
  _EditableTextField('heroSubtitle', 'Hero Subtitle', large: true),
  _EditableTextField('heroPrimaryCtaLabel', 'Hero Primary Button'),
  _EditableTextField('heroSecondaryCtaLabel', 'Hero Secondary Button'),
  _EditableTextField('heroHighlightLabel', 'Hero Highlight'),
  _EditableTextField('heroImageUrl', 'Hero Image URL', large: true),
  _EditableTextField('previewEyebrow', 'Preview Eyebrow'),
  _EditableTextField('previewTitle', 'Preview Title'),
  _EditableTextField('previewSubtitle', 'Preview Subtitle', large: true),
  _EditableTextField('previewImageUrl', 'Preview Image URL', large: true),
  _EditableTextField('featuresEyebrow', 'Features Eyebrow'),
  _EditableTextField('featuresTitle', 'Features Title'),
  _EditableTextField('featuresSubtitle', 'Features Subtitle', large: true),
  _EditableTextField('customText.feature1Title', 'Feature 1 Title'),
  _EditableTextField('customText.feature1Body', 'Feature 1 Body', large: true),
  _EditableTextField('customText.feature2Title', 'Feature 2 Title'),
  _EditableTextField('customText.feature2Body', 'Feature 2 Body', large: true),
  _EditableTextField('customText.feature3Title', 'Feature 3 Title'),
  _EditableTextField('customText.feature3Body', 'Feature 3 Body', large: true),
  _EditableTextField('customText.flowStep1', 'Flow Step 1'),
  _EditableTextField('customText.flowStep2', 'Flow Step 2'),
  _EditableTextField('customText.flowStep3', 'Flow Step 3'),
  _EditableTextField('customText.flowStep4', 'Flow Step 4'),
  _EditableTextField('categoriesEyebrow', 'Categories Eyebrow'),
  _EditableTextField('categoriesTitle', 'Categories Title'),
  _EditableTextField('categoriesSubtitle', 'Categories Subtitle', large: true),
  _EditableTextField('customText.audienceEyebrow', 'Audience Eyebrow'),
  _EditableTextField('customText.audienceTitle', 'Audience Title'),
  _EditableTextField('customText.audienceSubtitle', 'Audience Subtitle', large: true),
  _EditableTextField('customText.audienceCard1Title', 'Audience Card 1 Title'),
  _EditableTextField('customText.audienceCard1Body', 'Audience Card 1 Body', large: true),
  _EditableTextField('customText.audienceCard2Title', 'Audience Card 2 Title'),
  _EditableTextField('customText.audienceCard2Body', 'Audience Card 2 Body', large: true),
  _EditableTextField('customText.audienceCard3Title', 'Audience Card 3 Title'),
  _EditableTextField('customText.audienceCard3Body', 'Audience Card 3 Body', large: true),
  _EditableTextField('customText.audienceCard4Title', 'Audience Card 4 Title'),
  _EditableTextField('customText.audienceCard4Body', 'Audience Card 4 Body', large: true),
  _EditableTextField('customText.promiseEyebrow', 'Promise Eyebrow'),
  _EditableTextField('customText.promiseTitle', 'Promise Title'),
  _EditableTextField('customText.promiseSubtitle', 'Promise Subtitle', large: true),
  _EditableTextField('customText.promiseCard1Title', 'Promise Card 1 Title'),
  _EditableTextField('customText.promiseCard1Body', 'Promise Card 1 Body', large: true),
  _EditableTextField('customText.promiseCard2Title', 'Promise Card 2 Title'),
  _EditableTextField('customText.promiseCard2Body', 'Promise Card 2 Body', large: true),
  _EditableTextField('customText.promiseCard3Title', 'Promise Card 3 Title'),
  _EditableTextField('customText.promiseCard3Body', 'Promise Card 3 Body', large: true),
  _EditableTextField('customText.insideEyebrow', 'Inside App Eyebrow'),
  _EditableTextField('customText.insideTitle', 'Inside App Title'),
  _EditableTextField('customText.insideSubtitle', 'Inside App Subtitle', large: true),
  _EditableTextField('customText.insideCard1Title', 'Inside Card 1 Title'),
  _EditableTextField('customText.insideCard1Body', 'Inside Card 1 Body', large: true),
  _EditableTextField('customText.insideCard2Title', 'Inside Card 2 Title'),
  _EditableTextField('customText.insideCard2Body', 'Inside Card 2 Body', large: true),
  _EditableTextField('customText.insideCard3Title', 'Inside Card 3 Title'),
  _EditableTextField('customText.insideCard3Body', 'Inside Card 3 Body', large: true),
  _EditableTextField('customText.insideCard4Title', 'Inside Card 4 Title'),
  _EditableTextField('customText.insideCard4Body', 'Inside Card 4 Body', large: true),
  _EditableTextField('customText.insideCard5Title', 'Inside Card 5 Title'),
  _EditableTextField('customText.insideCard5Body', 'Inside Card 5 Body', large: true),
  _EditableTextField('customText.insideCard6Title', 'Inside Card 6 Title'),
  _EditableTextField('customText.insideCard6Body', 'Inside Card 6 Body', large: true),
  _EditableTextField('customText.dailyFlowEyebrow', 'Daily Flow Eyebrow'),
  _EditableTextField('customText.dailyFlowTitle', 'Daily Flow Title'),
  _EditableTextField('customText.dailyFlowSubtitle', 'Daily Flow Subtitle', large: true),
  _EditableTextField('customText.dailyFlowStep1Title', 'Daily Flow Step 1 Title'),
  _EditableTextField('customText.dailyFlowStep1Body', 'Daily Flow Step 1 Body', large: true),
  _EditableTextField('customText.dailyFlowStep2Title', 'Daily Flow Step 2 Title'),
  _EditableTextField('customText.dailyFlowStep2Body', 'Daily Flow Step 2 Body', large: true),
  _EditableTextField('customText.dailyFlowStep3Title', 'Daily Flow Step 3 Title'),
  _EditableTextField('customText.dailyFlowStep3Body', 'Daily Flow Step 3 Body', large: true),
  _EditableTextField('customText.useCasesEyebrow', 'Use Cases Eyebrow'),
  _EditableTextField('customText.useCasesTitle', 'Use Cases Title'),
  _EditableTextField('customText.useCasesSubtitle', 'Use Cases Subtitle', large: true),
  _EditableTextField('customText.useCasesStep1Title', 'Use Cases Step 1 Title'),
  _EditableTextField('customText.useCasesStep1Body', 'Use Cases Step 1 Body', large: true),
  _EditableTextField('customText.useCasesStep2Title', 'Use Cases Step 2 Title'),
  _EditableTextField('customText.useCasesStep2Body', 'Use Cases Step 2 Body', large: true),
  _EditableTextField('customText.useCasesStep3Title', 'Use Cases Step 3 Title'),
  _EditableTextField('customText.useCasesStep3Body', 'Use Cases Step 3 Body', large: true),
  _EditableTextField('customText.trustEyebrow', 'Trust Eyebrow'),
  _EditableTextField('customText.trustTitle', 'Trust Title'),
  _EditableTextField('customText.trustSubtitle', 'Trust Subtitle', large: true),
  _EditableTextField('customText.trustPill1', 'Trust Pill 1'),
  _EditableTextField('customText.trustPill2', 'Trust Pill 2'),
  _EditableTextField('customText.trustPill3', 'Trust Pill 3'),
  _EditableTextField('customText.trustPill4', 'Trust Pill 4'),
  _EditableTextField('customText.trustPill5', 'Trust Pill 5'),
  _EditableTextField('customText.faqEyebrow', 'FAQ Eyebrow'),
  _EditableTextField('customText.faqTitle', 'FAQ Title'),
  _EditableTextField('customText.faqSubtitle', 'FAQ Subtitle', large: true),
  _EditableTextField('customText.faq1Question', 'FAQ 1 Question'),
  _EditableTextField('customText.faq1Answer', 'FAQ 1 Answer', large: true),
  _EditableTextField('customText.faq2Question', 'FAQ 2 Question'),
  _EditableTextField('customText.faq2Answer', 'FAQ 2 Answer', large: true),
  _EditableTextField('customText.faq3Question', 'FAQ 3 Question'),
  _EditableTextField('customText.faq3Answer', 'FAQ 3 Answer', large: true),
  _EditableTextField('customText.faq4Question', 'FAQ 4 Question'),
  _EditableTextField('customText.faq4Answer', 'FAQ 4 Answer', large: true),
  _EditableTextField('dynamicEventsEyebrow', 'Dynamic Events Eyebrow'),
  _EditableTextField('dynamicEventsTitle', 'Dynamic Events Title'),
  _EditableTextField(
    'dynamicEventsSubtitle',
    'Dynamic Events Subtitle',
    large: true,
  ),
  _EditableTextField('plansEyebrow', 'Plans Eyebrow'),
  _EditableTextField('plansTitle', 'Plans Title'),
  _EditableTextField('plansSubtitle', 'Plans Subtitle', large: true),
  _EditableTextField('plansPrimaryCtaLabel', 'Plans Button'),
  _EditableTextField('faqEyebrow', 'FAQ Eyebrow'),
  _EditableTextField('faqTitle', 'FAQ Title'),
  _EditableTextField('faqSubtitle', 'FAQ Subtitle', large: true),
  _EditableTextField('downloadEyebrow', 'Download Eyebrow'),
  _EditableTextField('downloadTitle', 'Download Title'),
  _EditableTextField('downloadSubtitle', 'Download Subtitle', large: true),
  _EditableTextField('downloadButtonLabel', 'Download Button'),
  _EditableTextField('footerTagline', 'Footer Tagline', large: true),
];

const List<_SwitchField> _switchFields = <_SwitchField>[
  _SwitchField('showHero', 'Hero'),
  _SwitchField('showPreview', 'Preview'),
  _SwitchField('showFeatures', 'Features'),
  _SwitchField('showCategories', 'Categories'),
  _SwitchField('showDynamicEvents', 'Dynamic Events'),
  _SwitchField('showPlans', 'Plans'),
  _SwitchField('showTestimonials', 'Testimonials'),
  _SwitchField('showFaq', 'FAQ'),
  _SwitchField('showDownloadCta', 'Download CTA'),
];
