import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_background_remover/image_background_remover.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/image_editor/services/background_removal_service.dart';
import 'package:mana_poster/features/prehome/screens/language_settings_screen.dart';
import 'package:mana_poster/features/prehome/screens/permission_settings_screen.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/auth_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final FirebaseAuthService _authService = FirebaseAuthService();
  static const OfflineBackgroundRemovalService _backgroundRemovalService =
      OfflineBackgroundRemovalService();

  PosterProfileData _posterProfile = const PosterProfileData(
    nameTelugu: 'Mana Poster User',
    nameEnglish: '',
    whatsappNumber: '',
    nameFontFamily: 'Anek Telugu Condensed Bold',
    displayNameMode: PosterDisplayNameMode.auto,
    photoPath: '',
    photoUrl: '',
  );
  bool _loadingProfile = true;
  bool _photoBusy = false;
  final ImagePicker _imagePicker = ImagePicker();
  late final Future<void> _backgroundRemoverInitialization;

  @override
  void initState() {
    super.initState();
    _backgroundRemoverInitialization = BackgroundRemover.instance.initializeOrt();
    _loadPosterProfile();
  }

  @override
  void dispose() {
    unawaited(BackgroundRemover.instance.dispose());
    super.dispose();
  }

  Future<void> _loadPosterProfile() async {
    final profile = await PosterProfileService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _posterProfile = profile;
      _loadingProfile = false;
    });
  }

  Future<void> _openPosterProfileEditor() async {
    String nameValue = _posterProfile.displayName;
    String whatsappValue = _posterProfile.whatsappNumber;

    final PosterProfileData? result =
        await showModalBottomSheet<PosterProfileData>(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFFF8FAFC),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Poster Profile Details',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Name and WhatsApp number changes poster lo automatic ga apply avuthayi.',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: nameValue,
                          onChanged: (value) {
                            setSheetState(() => nameValue = value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: whatsappValue,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            setSheetState(() => whatsappValue = value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Number',
                            hintText: '10-digit number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Preview: ${nameValue.trim().isEmpty ? PosterProfileService.defaultName : nameValue.trim()}',
                            style: TextStyle(
                              fontFamily: _posterProfile.nameFontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final sanitizedWhatsapp = whatsappValue
                                      .replaceAll(RegExp(r'\D'), '');
                                  final data = PosterProfileData(
                                    nameTelugu: nameValue.trim(),
                                    nameEnglish: '',
                                    whatsappNumber: sanitizedWhatsapp,
                                    nameFontFamily: _posterProfile.nameFontFamily,
                                    displayNameMode: PosterDisplayNameMode.auto,
                                    photoPath: _posterProfile.photoPath,
                                    photoUrl: _posterProfile.photoUrl,
                                  );
                                  Navigator.of(context).pop(data);
                                },
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

    if (result == null) {
      return;
    }
    await PosterProfileService.save(result);
    if (!mounted) {
      return;
    }
    setState(() => _posterProfile = result);
  }

  Future<void> _pickAndSaveProfilePhoto() async {
    if (_photoBusy) {
      return;
    }
    setState(() => _photoBusy = true);
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

      final updated = _posterProfile.copyWith(
        photoPath: targetPath,
        photoUrl: remoteUrl.isEmpty ? _posterProfile.photoUrl : remoteUrl,
        originalPhotoPath: originalTargetPath,
        originalPhotoUrl: originalRemoteUrl.isEmpty
            ? _posterProfile.originalPhotoUrl
            : originalRemoteUrl,
      );
      await PosterProfileService.save(updated);
      if (!mounted) {
        return;
      }
      setState(() => _posterProfile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated with BG removed')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo background remove failed. Try another photo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _photoBusy = false);
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    if (_photoBusy) {
      return;
    }
    setState(() => _photoBusy = true);
    try {
      final path = _posterProfile.photoPath.trim();
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      final originalPath = _posterProfile.originalPhotoPath.trim();
      if (originalPath.isNotEmpty) {
        final file = File(originalPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await PosterProfileService.deleteProfilePhoto(
        photoUrl: _posterProfile.photoUrl,
      );
      await PosterProfileService.deleteProfilePhoto(
        photoUrl: _posterProfile.originalPhotoUrl,
      );
      final updated = _posterProfile.copyWith(
        photoPath: '',
        photoUrl: '',
        originalPhotoPath: '',
        originalPhotoUrl: '',
      );
      await PosterProfileService.save(updated);
      if (!mounted) {
        return;
      }
      setState(() => _posterProfile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove photo right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _photoBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final user = _authService.currentUser;
    final profileResolvedName = _posterProfile.resolvedName(
      language: strings.language,
    );
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : profileResolvedName;
    final email = user?.email ?? 'user@manaposter.app';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          strings.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            _ProfileHeaderCard(name: displayName, email: email),
            const SizedBox(height: 18),
            _PosterProfileCard(
              profile: _posterProfile,
              isLoading: _loadingProfile,
              onEditTap: _openPosterProfileEditor,
              photoBusy: _photoBusy,
              onUploadPhotoTap: _pickAndSaveProfilePhoto,
              onRemovePhotoTap: _removeProfilePhoto,
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: strings.accountSection,
              items: <_ProfileItemData>[
                _ProfileItemData(
                  icon: Icons.language_rounded,
                  title: strings.languageOption,
                  subtitle: strings.languageOptionSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItemData(
                  icon: Icons.workspace_premium_outlined,
                  title: strings.subscriptionOption,
                  subtitle: strings.subscriptionSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: strings.appSettingsSection,
              items: <_ProfileItemData>[
                _ProfileItemData(
                  icon: Icons.verified_user_outlined,
                  title: strings.permissionsTitle,
                  subtitle: strings.permissionsOptionSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PermissionSettingsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItemData(
                  icon: Icons.notifications_none_rounded,
                  title: strings.notifications,
                  subtitle: strings.notificationsOptionSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: strings.supportSection,
              items: <_ProfileItemData>[
                _ProfileItemData(
                  icon: Icons.help_outline_rounded,
                  title: strings.helpSupport,
                  subtitle: strings.helpSupportSubtitle,
                ),
                _ProfileItemData(
                  icon: Icons.info_outline_rounded,
                  title: strings.aboutApp,
                  subtitle: strings.aboutAppSubtitle,
                ),
                _ProfileItemData(
                  icon: Icons.logout_rounded,
                  title: strings.logout,
                  subtitle: strings.logoutSubtitle,
                  isDestructive: true,
                  onTap: () async {
                    await _authService.signOut();
                    await AppFlowService.syncInitialSetupCompletion(
                      isAuthenticated: false,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF132A6B),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCE8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

class _PosterProfileCard extends StatelessWidget {
  const _PosterProfileCard({
    required this.profile,
    required this.isLoading,
    required this.onEditTap,
    required this.photoBusy,
    required this.onUploadPhotoTap,
    required this.onRemovePhotoTap,
  });

  final PosterProfileData profile;
  final bool isLoading;
  final VoidCallback onEditTap;
  final bool photoBusy;
  final VoidCallback onUploadPhotoTap;
  final VoidCallback onRemovePhotoTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final localPath = profile.photoPath.trim();
    final hasLocalPhoto = localPath.isNotEmpty && File(localPath).existsSync();
    final hasRemotePhoto = profile.photoUrl.trim().isNotEmpty;
    final ImageProvider<Object>? photoProvider = hasLocalPhoto
        ? FileImage(File(localPath))
        : (hasRemotePhoto ? NetworkImage(profile.photoUrl.trim()) : null);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Poster Profile',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : onEditTap,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else ...<Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                    image: photoProvider == null
                        ? null
                        : DecorationImage(
                            image: photoProvider,
                            fit: BoxFit.cover,
                          ),
                  ),
                  alignment: Alignment.center,
                  child: photoProvider == null
                      ? const Icon(Icons.person_rounded, color: Color(0xFF64748B))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: photoBusy ? null : onUploadPhotoTap,
                          child: Text(photoBusy ? 'Please wait...' : 'Upload Photo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              photoBusy || photoProvider == null ? null : onRemovePhotoTap,
                          child: const Text('Remove'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              profile.resolvedName(language: strings.language),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: profile.nameFontFamily,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.whatsappNumber.trim().isEmpty
                  ? 'WhatsApp: not added'
                  : 'WhatsApp: ${profile.whatsappNumber}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.items});

  final String title;
  final List<_ProfileItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => _ProfileOptionTile(
                    item: entry.value,
                    showDivider: entry.key != items.length - 1,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({required this.item, required this.showDivider});

  final _ProfileItemData item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.isDestructive
        ? const Color(0xFFB91C1C)
        : const Color(0xFF1E3A8A);
    final titleColor = item.isDestructive
        ? const Color(0xFFB91C1C)
        : const Color(0xFF0F172A);

    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isDestructive
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: iconColor, size: 21),
          ),
          title: Text(
            item.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
          ),
          onTap: item.onTap ?? () {},
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 14,
            color: Color(0xFFE2E8F0),
          ),
      ],
    );
  }
}

class _ProfileItemData {
  const _ProfileItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;
}

