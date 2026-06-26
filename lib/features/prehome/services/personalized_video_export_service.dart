import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';
import 'package:mana_poster/features/prehome/services/telugu_legacy_text_service.dart';

class PersonalizedVideoExportException implements Exception {
  const PersonalizedVideoExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _FfmpegExportAttempt {
  const _FfmpegExportAttempt(this.name, this.args);

  final String name;
  final List<String> args;
}

class _PreparedOverlayPhoto {
  const _PreparedOverlayPhoto({
    required this.file,
    required this.x,
    required this.y,
    required this.scale,
    required this.animation,
  });

  final File file;
  final double x;
  final double y;
  final double scale;
  final String animation;
}

class _PhotoMaskConfig {
  const _PhotoMaskConfig({
    required this.shape,
    required this.renderMode,
    required this.edgeStyle,
  });

  final String shape;
  final String renderMode;
  final String edgeStyle;
}

class PersonalizedVideoExportService {
  const PersonalizedVideoExportService();

  static const int outputWidth = 1080;
  static const int outputHeight = 1920;
  static const double _animationSeconds = 1.15;
  static const int _exportLayoutVersion = 5;
  static final Map<String, Future<File>> _remoteVideoCache =
      <String, Future<File>>{};
  static final Map<String, Future<String>> _exportCache =
      <String, Future<String>>{};
  static final RegExp _teluguTextPattern = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _latinTextPattern = RegExp(r'[A-Za-z]');
  static const List<String> _randomPosterNameFonts = <String>[
    'Pragathi',
    'Brahma',
    'Kranthi',
    'Reshma',
    'Tejafont',
  ];
  static const List<String> _randomEnglishPosterNameFonts = <String>[
    'Montserrat',
    'Oswald',
    'Cinzel',
    'Raleway',
    'Rubik',
  ];

  Future<String> export({
    required String videoUrl,
    required PosterProfileData profile,
    required CreatorPosterPersonalization personalization,
    required AppLanguage language,
    PosterProfileData? extraPhotoProfile,
    String title = 'Mana Poster',
    String previewSeed = 'poster',
    int stripGradientTapOffset = 0,
  }) async {
    final cacheKey = _exportCacheKey(
      videoUrl: videoUrl,
      profile: profile,
      extraPhotoProfile: extraPhotoProfile,
      personalization: personalization,
      language: language,
      title: title,
      previewSeed: previewSeed,
      stripGradientTapOffset: stripGradientTapOffset,
    );
    final diskCachedFile = await _cachedOutputFile(cacheKey);
    if (await diskCachedFile.exists() && await diskCachedFile.length() > 0) {
      if (kDebugMode) {
        debugPrint(
          'Personalized video export disk cache hit: ${diskCachedFile.path}',
        );
      }
      return diskCachedFile.path;
    }
    final cached = _exportCache[cacheKey];
    if (cached != null) {
      final path = await cached;
      final file = File(path);
      if (await file.exists() && await file.length() > 0) {
        return path;
      }
      _exportCache.remove(cacheKey);
    }
    final future = _exportUncached(
      videoUrl: videoUrl,
      profile: profile,
      extraPhotoProfile: extraPhotoProfile,
      personalization: personalization,
      language: language,
      title: title,
      previewSeed: previewSeed,
      stripGradientTapOffset: stripGradientTapOffset,
      outputPath: diskCachedFile.path,
    );
    _exportCache[cacheKey] = future;
    try {
      return await future;
    } catch (_) {
      _exportCache.remove(cacheKey);
      rethrow;
    }
  }

  Future<String> _exportUncached({
    required String videoUrl,
    required PosterProfileData profile,
    required PosterProfileData? extraPhotoProfile,
    required CreatorPosterPersonalization personalization,
    required AppLanguage language,
    required String title,
    required String previewSeed,
    required int stripGradientTapOffset,
    required String outputPath,
  }) async {
    final workDir = await _createWorkDir();
    final inputVideo = await _prepareVideoFile(videoUrl, workDir);
    final photoFile = await _preparePhotoFile(
      profile,
      _PhotoMaskConfig(
        shape: personalization.photoShape,
        renderMode: personalization.photoRenderMode,
        edgeStyle: personalization.edgeStyle,
      ),
      workDir,
    );
    final extraPhotoFile =
        personalization.showVideoExtraPhoto && extraPhotoProfile != null
        ? await _preparePhotoFile(
            extraPhotoProfile,
            _PhotoMaskConfig(
              shape: personalization.videoExtraPhotoShape,
              renderMode: personalization.videoExtraPhotoRenderMode,
              edgeStyle: personalization.videoExtraPhotoEdgeStyle,
            ),
            workDir,
            outputName: 'extra_profile.png',
          )
        : null;
    final stripFile = personalization.showBottomStrip
        ? await _buildNameStrip(
            profile: profile,
            language: language,
            personalization: personalization,
            workDir: workDir,
            title: title,
            previewSeed: previewSeed,
            stripGradientTapOffset: stripGradientTapOffset,
          )
        : null;
    final outputFile = File(outputPath);

    String? lastLogs;
    int? lastCode;
    final startedAt = DateTime.now();
    for (final attempt in _buildFfmpegAttempts(
      inputVideoPath: inputVideo.path,
      mainPhoto: photoFile == null
          ? null
          : _PreparedOverlayPhoto(
              file: photoFile,
              x: personalization.photoX,
              y: personalization.photoY,
              scale: personalization.photoScale,
              animation: personalization.photoAnimation,
            ),
      extraPhoto: extraPhotoFile == null
          ? null
          : _PreparedOverlayPhoto(
              file: extraPhotoFile,
              x: personalization.videoExtraPhotoX,
              y: personalization.videoExtraPhotoY,
              scale: personalization.videoExtraPhotoScale,
              animation: personalization.videoExtraPhotoAnimation,
            ),
      stripPath: stripFile?.path,
      outputPath: outputFile.path,
    )) {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      final attemptStartedAt = DateTime.now();
      final session = await FFmpegKit.executeWithArguments(attempt.args);
      final returnCode = await session.getReturnCode();
      final elapsedMs = DateTime.now()
          .difference(attemptStartedAt)
          .inMilliseconds;
      if (ReturnCode.isSuccess(returnCode) &&
          await outputFile.exists() &&
          await outputFile.length() > 0) {
        if (kDebugMode) {
          debugPrint(
            'Personalized video export ${attempt.name} succeeded in ${elapsedMs}ms '
            'total=${DateTime.now().difference(startedAt).inMilliseconds}ms',
          );
        }
        return outputFile.path;
      }
      lastCode = returnCode?.getValue();
      lastLogs = await session.getAllLogsAsString();
      if (kDebugMode) {
        debugPrint(
          'Personalized video export ${attempt.name} failed in ${elapsedMs}ms '
          'code=${lastCode ?? 'unknown'}',
        );
        final logs = lastLogs?.trim();
        if (logs != null && logs.isNotEmpty) {
          final excerpt = logs.length > 1800
              ? logs.substring(logs.length - 1800)
              : logs;
          debugPrint(
            'Personalized video export ${attempt.name} logs: $excerpt',
          );
        }
      }
    }
    if (kDebugMode && lastLogs != null) {
      debugPrint('Personalized video export failed: $lastLogs');
    }
    throw PersonalizedVideoExportException(
      'Video export failed. Code: ${lastCode ?? 'unknown'}',
    );
  }

  String _exportCacheKey({
    required String videoUrl,
    required PosterProfileData profile,
    required PosterProfileData? extraPhotoProfile,
    required CreatorPosterPersonalization personalization,
    required AppLanguage language,
    required String title,
    required String previewSeed,
    required int stripGradientTapOffset,
  }) {
    return <Object?>[
      videoUrl.trim(),
      _stableProfileKey(profile),
      extraPhotoProfile == null ? '' : _stableProfileKey(extraPhotoProfile),
      _stablePersonalizationKey(personalization),
      language.name,
      title,
      previewSeed,
      stripGradientTapOffset,
      outputWidth,
      outputHeight,
      _exportLayoutVersion,
    ].join('\u001F');
  }

  Future<File> _cachedOutputFile(String cacheKey) async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(
      '${tempDir.path}${Platform.pathSeparator}mana_poster_video_export_cache',
    );
    await dir.create(recursive: true);
    return File(
      '${dir.path}${Platform.pathSeparator}'
      'export_${_stableCacheId(cacheKey)}.mp4',
    );
  }

  String _stableCacheId(String value) {
    var h1 = 0x811C9DC5;
    var h2 = 0x9747B28C;
    for (final codeUnit in value.codeUnits) {
      h1 = ((h1 ^ codeUnit) * 0x01000193) & 0xFFFFFFFF;
      h2 = ((h2 + codeUnit) * 0x5BD1E995) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}';
  }

  String _stableProfileKey(PosterProfileData profile) {
    return <Object?>[
      profile.nameTelugu.trim(),
      profile.nameEnglish.trim(),
      profile.whatsappNumber.trim(),
      profile.nameFontFamily.trim(),
      profile.displayNameMode.name,
      profile.photoPath.trim(),
      profile.photoUrl.trim(),
      profile.identityMode.name,
      profile.businessName.trim(),
      profile.businessTagline.trim(),
      profile.businessWhatsappNumber.trim(),
      profile.businessLogoPath.trim(),
      profile.businessLogoUrl.trim(),
      profile.businessLogoStyleId.trim(),
      profile.originalPhotoPath.trim(),
      profile.originalPhotoUrl.trim(),
    ].join('\u001E');
  }

  String _stablePersonalizationKey(
    CreatorPosterPersonalization personalization,
  ) {
    return <Object?>[
      personalization.photoShape,
      personalization.photoX,
      personalization.photoY,
      personalization.photoScale,
      personalization.photoAnimation,
      personalization.showVideoExtraPhoto,
      personalization.videoExtraPhotoShape,
      personalization.videoExtraPhotoRenderMode,
      personalization.videoExtraPhotoEdgeStyle,
      personalization.videoExtraPhotoAnimation,
      personalization.videoExtraPhotoX,
      personalization.videoExtraPhotoY,
      personalization.videoExtraPhotoScale,
      personalization.nameX,
      personalization.nameY,
      personalization.showBottomStrip,
      personalization.stripHeight,
      personalization.showWhatsapp,
      personalization.sampleName,
      personalization.nameScale,
      personalization.showStyledNameStrip,
      personalization.showStyledDesignationStrip,
      personalization.sampleDesignation,
      personalization.designationScale,
      personalization.phoneScale,
      personalization.nameStripColor,
      personalization.designationStripColor,
      personalization.boardVariant,
      personalization.photoRenderMode,
      personalization.edgeStyle,
      personalization.showSafeAreas,
    ].join('\u001E');
  }

  Future<Directory> _createWorkDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(
      '${tempDir.path}${Platform.pathSeparator}'
      'mana_poster_video_export_${DateTime.now().microsecondsSinceEpoch}',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> _prepareVideoFile(String videoUrl, Directory workDir) async {
    final trimmed = videoUrl.trim();
    if (trimmed.isEmpty) {
      throw const PersonalizedVideoExportException('Video URL is empty.');
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final file = File(trimmed);
      if (await file.exists()) {
        return file;
      }
      throw PersonalizedVideoExportException('Video file missing: $trimmed');
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      throw const PersonalizedVideoExportException('Invalid video URL.');
    }
    final cached = _remoteVideoCache[trimmed];
    if (cached != null) {
      final file = await cached;
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
      _remoteVideoCache.remove(trimmed);
    }
    final future = _downloadRemoteVideo(uri, trimmed);
    _remoteVideoCache[trimmed] = future;
    try {
      return await future;
    } catch (_) {
      _remoteVideoCache.remove(trimmed);
      rethrow;
    }
  }

  Future<File> _downloadRemoteVideo(Uri uri, String cacheKey) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}mana_poster_video_source_cache',
    );
    await cacheDir.create(recursive: true);
    final file = File(
      '${cacheDir.path}${Platform.pathSeparator}'
      'source_${_stableCacheId(cacheKey)}.mp4',
    );
    if (await file.exists() && await file.length() > 0) {
      if (kDebugMode) {
        debugPrint('Personalized video source disk cache hit: ${file.path}');
      }
      return file;
    }
    final response = await http.get(uri).timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PersonalizedVideoExportException(
        'Video download failed: ${response.statusCode}',
      );
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  Future<File?> _preparePhotoFile(
    PosterProfileData profile,
    _PhotoMaskConfig maskConfig,
    Directory workDir, {
    String outputName = 'profile.png',
  }) async {
    final preferOriginal = maskConfig.renderMode == 'original';
    final localPath = preferOriginal
        ? _firstNonEmpty(<String>[
            profile.originalPhotoPath,
            profile.photoPath,
            profile.businessLogoPath,
          ])
        : _firstNonEmpty(<String>[
            profile.photoPath,
            profile.originalPhotoPath,
            profile.businessLogoPath,
          ]);
    if (localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        return _applyPhotoMaskIfNeeded(file, maskConfig, workDir, outputName);
      }
    }

    final url = preferOriginal
        ? _firstNonEmpty(<String>[
            profile.originalPhotoUrl,
            profile.photoUrl,
            profile.businessLogoUrl,
          ])
        : _firstNonEmpty(<String>[
            profile.photoUrl,
            profile.originalPhotoUrl,
            profile.businessLogoUrl,
          ]);
    if (url.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    final response = await http.get(uri).timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final file = File('${workDir.path}${Platform.pathSeparator}$outputName');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return _applyPhotoMaskIfNeeded(file, maskConfig, workDir, outputName);
  }

  Future<File> _applyPhotoMaskIfNeeded(
    File source,
    _PhotoMaskConfig maskConfig,
    Directory workDir,
    String outputName,
  ) async {
    final shape = maskConfig.shape.trim().toLowerCase();
    final renderMode = _isTransparentPhotoShape(shape)
        ? 'cutout'
        : maskConfig.renderMode.trim().toLowerCase();
    final edgeStyle = maskConfig.edgeStyle.trim().toLowerCase();
    final needsCircleMask =
        shape == 'circle' ||
        shape == 'transparent_soft_round' ||
        shape == 'transparent_sharp_round';
    final needsBottomFade =
        shape == 'transparent_bottom_fade' ||
        (!needsCircleMask &&
            renderMode != 'original' &&
            (edgeStyle == 'soft_fade' || edgeStyle == 'bottom_fade'));
    if (!needsCircleMask && !needsBottomFade) {
      return source;
    }

    final decoded = img.decodeImage(await source.readAsBytes());
    if (decoded == null) {
      return source;
    }
    var working = _normalizePhotoToPreviewFrame(
      decoded,
      shape: shape,
      renderMode: renderMode,
    );

    final centerX = (working.width - 1) / 2;
    final centerY = (working.height - 1) / 2;
    final radius = working.width < working.height
        ? working.width / 2
        : working.height / 2;
    for (var y = 0; y < working.height; y += 1) {
      final vertical = working.height <= 1 ? 0.0 : y / (working.height - 1);
      final fadeAlpha = needsBottomFade ? _bottomFadeAlpha(vertical) : 1.0;
      for (var x = 0; x < working.width; x += 1) {
        var maskAlpha = fadeAlpha;
        if (needsCircleMask) {
          final dx = x - centerX;
          final dy = y - centerY;
          final distance = (dx * dx + dy * dy);
          final hardRadius = radius - 1.2;
          final softRadius = radius;
          final hardRadiusSquared = hardRadius * hardRadius;
          final softRadiusSquared = softRadius * softRadius;
          if (distance >= softRadiusSquared) {
            maskAlpha = 0;
          } else if (distance > hardRadiusSquared) {
            final edgeProgress =
                (distance - hardRadiusSquared) /
                (softRadiusSquared - hardRadiusSquared);
            maskAlpha *= (1 - edgeProgress).clamp(0.0, 1.0);
          }
        }
        if (maskAlpha >= 0.999) {
          continue;
        }
        final pixel = working.getPixel(x, y);
        final alpha = (pixel.a * maskAlpha).round().clamp(0, 255);
        working.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
      }
    }

    final file = File(
      '${workDir.path}${Platform.pathSeparator}'
      '${outputName.replaceAll(RegExp(r'\.[^.]+$'), '')}_masked.png',
    );
    await file.writeAsBytes(img.encodePng(working), flush: true);
    return file;
  }

  img.Image _normalizePhotoToPreviewFrame(
    img.Image source, {
    required String shape,
    required String renderMode,
  }) {
    final frameAspectRatio = _photoMaskAspectRatio(shape);
    final targetWidth = source.width.clamp(480, 1600);
    final targetHeight = (targetWidth / frameAspectRatio).round().clamp(
      480,
      2000,
    );
    final frame = img.Image(
      width: targetWidth,
      height: targetHeight,
      numChannels: 4,
    );
    img.fill(frame, color: img.ColorRgba8(0, 0, 0, 0));

    final sourceAspectRatio = source.width / source.height;
    final scale = sourceAspectRatio > frameAspectRatio
        ? targetWidth / source.width
        : targetHeight / source.height;
    final resizedWidth = (source.width * scale).round().clamp(1, targetWidth);
    final resizedHeight = (source.height * scale).round().clamp(
      1,
      targetHeight,
    );
    final resized = img.copyResize(
      source.convert(numChannels: 4),
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.linear,
    );
    final alignmentY = renderMode == 'cutout' ? _cutoutAlignmentY(shape) : 0.0;
    final dx = ((targetWidth - resizedWidth) / 2).round();
    final dy = (((targetHeight - resizedHeight) / 2) * (1 + alignmentY))
        .round()
        .clamp(0, targetHeight - resizedHeight);
    img.compositeImage(frame, resized, dstX: dx, dstY: dy);
    return frame.convert(numChannels: 4);
  }

  double _photoMaskAspectRatio(String shape) {
    switch (shape) {
      case 'transparent_bottom_fade':
      case 'transparent_clean':
      case 'vertical_rectangle':
      case 'oval':
      case 'blob':
      case 'wave_bottom':
      case 'arch':
      case 'parallelogram':
        return 4 / 5;
      case 'custom_screen_fit':
        return 16 / 9;
      case 'custom_board_fit':
        return 16 / 7;
      case 'custom_frame_fit':
        return 4 / 5;
      case 'custom_polygon_fit':
        return 4 / 3;
      default:
        return 1;
    }
  }

  bool _isTransparentPhotoShape(String shape) {
    return shape == 'transparent_bottom_fade' ||
        shape == 'transparent_clean' ||
        shape == 'transparent_soft_round' ||
        shape == 'transparent_sharp_round';
  }

  double _cutoutAlignmentY(String shape) {
    switch (shape) {
      case 'flower':
      case 'scallop_circle':
      case 'soft_burst':
      case 'sunburst':
        return -0.16;
      case 'badge':
        return -0.14;
      case 'oval':
        return -0.20;
      case 'circle':
      case 'square':
        return 0.12;
      default:
        return 0.12;
    }
  }

  double _bottomFadeAlpha(double position) {
    const stops = <double>[0.0, 0.4, 0.52, 0.62, 0.72, 0.8, 0.86, 0.9, 1.0];
    const values = <double>[1.0, 1.0, 0.95, 0.8, 0.48, 0.19, 0.03, 0.0, 0.0];
    for (var index = 0; index < stops.length - 1; index += 1) {
      final start = stops[index];
      final end = stops[index + 1];
      if (position <= end) {
        final range = end - start;
        final progress = range <= 0 ? 0.0 : ((position - start) / range);
        return values[index] + ((values[index + 1] - values[index]) * progress);
      }
    }
    return 0.0;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  Future<File> _buildNameStrip({
    required PosterProfileData profile,
    required AppLanguage language,
    required CreatorPosterPersonalization personalization,
    required Directory workDir,
    required String title,
    required String previewSeed,
    required int stripGradientTapOffset,
  }) async {
    final stripHeight =
        (outputHeight * (personalization.stripHeight / 100) * 0.5)
            .round()
            .clamp(72, 168);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, outputWidth.toDouble(), stripHeight.toDouble()),
    );
    final stripGradient = _resolvePosterStripGradient(
      previewSeed: previewSeed,
      stripHeight: personalization.stripHeight,
      resolvedName: profile.resolvedName(language: language),
      stripGradientTapOffset: stripGradientTapOffset,
    );
    final stripModel = _resolvePosterStripModel(
      previewSeed: previewSeed,
      stripHeight: personalization.stripHeight,
      resolvedName: profile.resolvedName(language: language),
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, outputWidth.toDouble(), stripHeight.toDouble()),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          stripModel == 1
              ? ui.Offset(outputWidth.toDouble(), stripHeight.toDouble())
              : ui.Offset(outputWidth.toDouble(), 0),
          stripGradient,
        ),
    );
    _drawStripAccent(
      canvas: canvas,
      width: outputWidth.toDouble(),
      height: stripHeight.toDouble(),
      model: stripModel,
      gradient: stripGradient,
    );

    final rawName = profile.resolvedName(language: language).trim();
    final isBusinessProfile =
        profile.identityMode == PosterIdentityMode.business;
    final rawDesignation = isBusinessProfile
        ? profile.businessTagline.trim()
        : profile.whatsappNumber.trim();
    final rawPhone = isBusinessProfile
        ? profile.activeWhatsappNumber.trim()
        : '';
    final displayNameSource = rawName.isEmpty ? 'Mana Poster' : rawName;
    final displayNameFontFamily = _resolveDisplayNameFontFamily(
      displayNameSource,
      previewSeed: previewSeed,
      personalization: personalization,
    );
    final designationFontFamily = _resolveDesignationFontFamily(rawDesignation);
    final displayName = await _legacyTextForExport(
      displayNameSource,
      displayNameFontFamily,
    );
    final displayDesignation = await _legacyTextForExport(
      rawDesignation,
      designationFontFamily,
    );
    final displayTrailing = displayDesignation.isNotEmpty
        ? displayDesignation
        : rawPhone;
    final nameUsesTeluguLayout = _containsTelugu(displayNameSource);
    final trailingUsesTeluguLayout =
        _containsTelugu(rawDesignation) ||
        (displayDesignation.isEmpty && _containsTelugu(rawPhone));
    final trailingFontFamily = displayDesignation.isNotEmpty
        ? designationFontFamily
        : (_containsTelugu(displayTrailing)
              ? 'Anek Telugu Condensed Medium'
              : 'Montserrat');
    final nameFontSize = isBusinessProfile
        ? (nameUsesTeluguLayout ? 96.0 : 82.0)
        : (nameUsesTeluguLayout ? 126.0 : 108.0);
    final trailingFontSize = isBusinessProfile
        ? (trailingUsesTeluguLayout ? 54.0 : 40.5)
        : (trailingUsesTeluguLayout ? 60.0 : 40.5);
    final horizontalInset = stripModel == 3 ? 0.058 : 0.039;
    final leftPadding = outputWidth * horizontalInset;
    final rightPadding = outputWidth * horizontalInset;
    final gap = outputWidth * 0.028;
    final dividerWidth = 4.5;
    final dividerX = outputWidth * 0.5;
    final nameMaxWidth = displayTrailing.isEmpty
        ? outputWidth - leftPadding - rightPadding
        : dividerX - leftPadding - gap;
    final trailingMaxWidth = outputWidth - dividerX - gap - rightPadding;
    final availableTextHeight = stripHeight * 0.82;
    final nameStyle = _fitTextStyle(
      displayName,
      baseFontSize: nameFontSize,
      minFontSize: nameUsesTeluguLayout ? 48 : 42,
      styleForFontSize: (fontSize) => ui.TextStyle(
        color: const ui.Color(0xFFFFFFFF),
        fontSize: fontSize,
        fontWeight: nameUsesTeluguLayout
            ? ui.FontWeight.w500
            : ui.FontWeight.w700,
        fontFamily: displayNameFontFamily,
        height: nameUsesTeluguLayout ? 0.82 : 1.0,
      ),
      maxWidth: nameMaxWidth,
      maxHeight: availableTextHeight,
      textAlign: displayTrailing.isEmpty
          ? ui.TextAlign.center
          : ui.TextAlign.left,
    );
    final nameParagraph = _paragraph(
      displayName,
      style: nameStyle,
      maxWidth: nameMaxWidth,
      textAlign: displayTrailing.isEmpty
          ? ui.TextAlign.center
          : ui.TextAlign.left,
    );
    final nameY = (stripHeight - nameParagraph.height) / 2;
    canvas.drawParagraph(nameParagraph, ui.Offset(leftPadding, nameY));

    if (displayTrailing.isNotEmpty) {
      final dividerPaint = ui.Paint()..color = const ui.Color(0xFFEDE7E0);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(
            dividerX - (dividerWidth / 2),
            stripHeight * 0.24,
            dividerWidth,
            stripHeight * 0.52,
          ),
          const ui.Radius.circular(8),
        ),
        dividerPaint,
      );
      final trailingParagraph = _paragraph(
        displayTrailing,
        style: _fitTextStyle(
          displayTrailing,
          baseFontSize: trailingFontSize,
          minFontSize: trailingUsesTeluguLayout ? 28 : 24,
          styleForFontSize: (fontSize) => ui.TextStyle(
            color: const ui.Color(0xFFEDE7E0),
            fontSize: fontSize,
            fontWeight: trailingUsesTeluguLayout
                ? ui.FontWeight.w400
                : ui.FontWeight.w600,
            fontFamily: trailingFontFamily,
            height: trailingUsesTeluguLayout ? 0.82 : 1.0,
          ),
          maxWidth: trailingMaxWidth,
          maxHeight: availableTextHeight,
          textAlign: ui.TextAlign.right,
        ),
        maxWidth: trailingMaxWidth,
        textAlign: ui.TextAlign.right,
      );
      final trailingY = (stripHeight - trailingParagraph.height) / 2;
      canvas.drawParagraph(
        trailingParagraph,
        ui.Offset(dividerX + gap, trailingY),
      );
    }

    final image = await recorder.endRecording().toImage(
      outputWidth,
      stripHeight,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${workDir.path}${Platform.pathSeparator}strip.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    return file;
  }

  ui.TextStyle _fitTextStyle(
    String text, {
    required double baseFontSize,
    required double minFontSize,
    required ui.TextStyle Function(double fontSize) styleForFontSize,
    required double maxWidth,
    required double maxHeight,
    required ui.TextAlign textAlign,
  }) {
    var fontSize = baseFontSize;
    while (fontSize > minFontSize) {
      final candidate = styleForFontSize(fontSize);
      final paragraph = _paragraph(
        text,
        style: candidate,
        maxWidth: maxWidth,
        textAlign: textAlign,
      );
      if (paragraph.height <= maxHeight &&
          paragraph.maxIntrinsicWidth <= maxWidth) {
        return candidate;
      }
      fontSize -= 3;
    }
    return styleForFontSize(minFontSize);
  }

  ui.Paragraph _paragraph(
    String text, {
    required ui.TextStyle style,
    required double maxWidth,
    ui.TextAlign textAlign = ui.TextAlign.left,
  }) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              maxLines: 1,
              ellipsis: '...',
              textAlign: textAlign,
            ),
          )
          ..pushStyle(style)
          ..addText(text);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    return paragraph;
  }

  bool _containsTelugu(String text) => _teluguTextPattern.hasMatch(text);

  String _resolvePosterNameFontFamily(
    String resolvedName, {
    required String previewSeed,
    required CreatorPosterPersonalization personalization,
  }) {
    final seedSource =
        '$previewSeed|${personalization.nameX}|${personalization.nameY}|'
        '${personalization.stripHeight}|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    return _randomPosterNameFonts[hash.abs() % _randomPosterNameFonts.length];
  }

  String _resolveEnglishPosterNameFontFamily(
    String resolvedName, {
    required String previewSeed,
    required CreatorPosterPersonalization personalization,
  }) {
    final seedSource =
        '$previewSeed|${personalization.nameX}|${personalization.nameY}|'
        '${personalization.stripHeight}|english|$resolvedName';
    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    return _randomEnglishPosterNameFonts[hash.abs() %
        _randomEnglishPosterNameFonts.length];
  }

  String? _resolveDisplayNameFontFamily(
    String text, {
    required String previewSeed,
    required CreatorPosterPersonalization personalization,
  }) {
    if (_teluguTextPattern.hasMatch(text)) {
      return _resolvePosterNameFontFamily(
        text,
        previewSeed: previewSeed,
        personalization: personalization,
      );
    }
    if (_latinTextPattern.hasMatch(text)) {
      return _resolveEnglishPosterNameFontFamily(
        text,
        previewSeed: previewSeed,
        personalization: personalization,
      );
    }
    return null;
  }

  List<ui.Color> _resolvePosterStripGradient({
    required String previewSeed,
    required double stripHeight,
    required String resolvedName,
    required int stripGradientTapOffset,
  }) {
    const gradients = <List<ui.Color>>[
      <ui.Color>[
        ui.Color(0xFF7C2D12),
        ui.Color(0xFFEA580C),
        ui.Color(0xFFC2410C),
      ],
      <ui.Color>[
        ui.Color(0xFF581C87),
        ui.Color(0xFFBE185D),
        ui.Color(0xFF9D174D),
      ],
      <ui.Color>[
        ui.Color(0xFF064E3B),
        ui.Color(0xFF059669),
        ui.Color(0xFF047857),
      ],
      <ui.Color>[
        ui.Color(0xFF7F1D1D),
        ui.Color(0xFFDC2626),
        ui.Color(0xFF991B1B),
      ],
      <ui.Color>[
        ui.Color(0xFF082F49),
        ui.Color(0xFF0891B2),
        ui.Color(0xFF0F766E),
      ],
      <ui.Color>[
        ui.Color(0xFF831843),
        ui.Color(0xFFDB2777),
        ui.Color(0xFFBE185D),
      ],
      <ui.Color>[
        ui.Color(0xFF4C1D95),
        ui.Color(0xFF7C3AED),
        ui.Color(0xFF5B21B6),
      ],
      <ui.Color>[
        ui.Color(0xFF134E4A),
        ui.Color(0xFF0D9488),
        ui.Color(0xFF115E59),
      ],
      <ui.Color>[
        ui.Color(0xFF3F1D38),
        ui.Color(0xFFC026D3),
        ui.Color(0xFFDB2777),
      ],
      <ui.Color>[
        ui.Color(0xFF3B0764),
        ui.Color(0xFF9333EA),
        ui.Color(0xFF7E22CE),
      ],
    ];
    final seedSource = '$previewSeed|$stripHeight|$resolvedName';
    var hash = 23;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 41 * hash + codeUnit;
    }
    final baseIndex = hash.abs() % gradients.length;
    final resolvedIndex =
        (baseIndex + stripGradientTapOffset) % gradients.length;
    return gradients[resolvedIndex];
  }

  int _resolvePosterStripModel({
    required String previewSeed,
    required double stripHeight,
    required String resolvedName,
  }) {
    final seedSource = '$previewSeed|$stripHeight|model|$resolvedName';
    var hash = 29;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 43 * hash + codeUnit;
    }
    return hash.abs() % 10;
  }

  void _drawStripAccent({
    required ui.Canvas canvas,
    required double width,
    required double height,
    required int model,
    required List<ui.Color> gradient,
  }) {
    switch (model) {
      case 0:
        final topPaint = ui.Paint()
          ..color = const ui.Color(0x58FFFFFF)
          ..strokeWidth = 4;
        final bottomPaint = ui.Paint()
          ..color = const ui.Color(0x33000000)
          ..strokeWidth = 4;
        canvas.drawLine(ui.Offset.zero, ui.Offset(width, 0), topPaint);
        canvas.drawLine(
          ui.Offset(0, height),
          ui.Offset(width, height),
          bottomPaint,
        );
        break;
      case 1:
        final paint = ui.Paint()..color = const ui.Color(0x2EFFFFFF);
        final stripeWidth = width * 0.18;
        for (
          var start = -width;
          start < width * 1.4;
          start += stripeWidth * 1.55
        ) {
          final path = ui.Path()
            ..moveTo(start, height)
            ..lineTo(start + stripeWidth, height)
            ..lineTo(start + stripeWidth + height * 0.7, 0)
            ..lineTo(start + height * 0.7, 0)
            ..close();
          canvas.drawPath(path, paint);
        }
        break;
      case 2:
        final paint = ui.Paint()
          ..color = gradient.last.withAlpha(220)
          ..strokeWidth = 7;
        canvas.drawLine(ui.Offset.zero, ui.Offset(width, 0), paint);
        break;
      case 3:
        final paint = ui.Paint()..color = const ui.Color(0x1FFFFFFF);
        final strokePaint = ui.Paint()
          ..color = const ui.Color(0x3DFFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2;
        final card = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(34, 12, width - 68, height - 24),
          const ui.Radius.circular(30),
        );
        canvas.drawRRect(card, paint);
        canvas.drawRRect(card, strokePaint);
        break;
      case 4:
        final paint = ui.Paint()..color = const ui.Color(0x29FFFFFF);
        canvas.drawRRect(
          ui.RRect.fromRectAndCorners(
            ui.Rect.fromLTWH(width * 0.58, 0, width * 0.42, height),
            topLeft: const ui.Radius.circular(999),
            bottomLeft: const ui.Radius.circular(999),
          ),
          paint,
        );
        break;
      case 5:
        final paint = ui.Paint()..color = const ui.Color(0x2EFFFFFF);
        final gap = height * 0.36;
        final radius = height * 0.035;
        for (var x = gap * 0.8; x < width; x += gap) {
          canvas.drawCircle(ui.Offset(x, height * 0.28), radius, paint);
          canvas.drawCircle(
            ui.Offset(x + gap * 0.45, height * 0.72),
            radius,
            paint,
          );
        }
        break;
      case 6:
        final paint = ui.Paint()
          ..color = const ui.Color(0x80FFFFFF)
          ..strokeWidth = 5;
        canvas.drawLine(ui.Offset(0, height), ui.Offset(width, height), paint);
        break;
      case 7:
        final paint = ui.Paint()..color = const ui.Color(0x1F000000);
        canvas.drawRRect(
          ui.RRect.fromRectAndCorners(
            ui.Rect.fromLTWH(0, 0, width * 0.34, height),
            topRight: const ui.Radius.circular(999),
            bottomRight: const ui.Radius.circular(999),
          ),
          paint,
        );
        break;
      case 8:
        final paint = ui.Paint()
          ..color = const ui.Color(0x29FFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 4;
        final path = ui.Path()..moveTo(0, height * 0.55);
        for (var x = 0.0; x <= width; x += width / 8) {
          path.quadraticBezierTo(
            x + width / 16,
            height * 0.35,
            x + width / 8,
            height * 0.55,
          );
        }
        canvas.drawPath(path, paint);
        break;
      default:
        final paint = ui.Paint()
          ..color = const ui.Color(0x38FFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3;
        final outline = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(26, 10, width - 52, height - 20),
          const ui.Radius.circular(999),
        );
        canvas.drawRRect(outline, paint);
    }
  }

  String _resolveDesignationFontFamily(String text) {
    if (_teluguTextPattern.hasMatch(text)) {
      return 'Pallavi Medium';
    }
    if (_latinTextPattern.hasMatch(text)) {
      return 'Montserrat';
    }
    return 'Poppins';
  }

  bool _shouldConvertForLegacyTelugu(String text, String? fontFamily) {
    return fontFamily != null &&
        _teluguTextPattern.hasMatch(text) &&
        (_randomPosterNameFonts.contains(fontFamily) ||
            fontFamily == 'Pallavi Medium');
  }

  Future<String> _legacyTextForExport(String text, String? fontFamily) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty ||
        !_shouldConvertForLegacyTelugu(trimmed, fontFamily)) {
      return text;
    }
    final cached = TeluguLegacyTextService.cachedValue(
      trimmed,
      fontFamily: fontFamily!,
    );
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final converted = await TeluguLegacyTextService.convert(
      trimmed,
      fontFamily: fontFamily,
    );
    return converted != null && converted.isNotEmpty ? converted : text;
  }

  List<_FfmpegExportAttempt> _buildFfmpegAttempts({
    required String inputVideoPath,
    required _PreparedOverlayPhoto? mainPhoto,
    required _PreparedOverlayPhoto? extraPhoto,
    required String? stripPath,
    required String outputPath,
  }) {
    var nextInputIndex = 1;
    final mainPhotoInputIndex = mainPhoto == null ? null : nextInputIndex++;
    final extraPhotoInputIndex = extraPhoto == null ? null : nextInputIndex++;
    final stripInputIndex = stripPath == null ? null : nextInputIndex++;
    final filter = _filterWithOverlays(
      mainPhoto: mainPhoto,
      mainPhotoInputIndex: mainPhotoInputIndex,
      extraPhoto: extraPhoto,
      extraPhotoInputIndex: extraPhotoInputIndex,
      stripInputIndex: stripInputIndex,
    );
    List<String> baseInputs() => <String>[
      '-y',
      '-i',
      inputVideoPath,
      if (mainPhoto != null) ...<String>[
        '-loop',
        '1',
        '-i',
        mainPhoto.file.path,
      ],
      if (extraPhoto != null) ...<String>[
        '-loop',
        '1',
        '-i',
        extraPhoto.file.path,
      ],
      if (stripPath != null) ...<String>['-loop', '1', '-i', stripPath],
      '-filter_complex',
      filter,
      '-map',
      '[v]',
      '-map',
      '0:a?',
    ];
    List<String> tail({required bool copyAudio}) => <String>[
      '-shortest',
      '-avoid_negative_ts',
      'make_zero',
      if (copyAudio) ...<String>['-c:a', 'copy'] else ...<String>[
        '-c:a',
        'aac',
        '-b:a',
        '128k',
      ],
      outputPath,
    ];

    return <_FfmpegExportAttempt>[
      _FfmpegExportAttempt('h264_mediacodec', <String>[
        ...baseInputs(),
        '-c:v',
        'h264_mediacodec',
        '-b:v',
        '8500k',
        '-pix_fmt',
        'yuv420p',
        ...tail(copyAudio: true),
      ]),
      _FfmpegExportAttempt('libx264_copy_audio', <String>[
        ...baseInputs(),
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-tune',
        'zerolatency',
        '-crf',
        '28',
        '-threads',
        '0',
        '-pix_fmt',
        'yuv420p',
        ...tail(copyAudio: true),
      ]),
      _FfmpegExportAttempt('libx264_aac', <String>[
        ...baseInputs(),
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-tune',
        'zerolatency',
        '-crf',
        '28',
        '-threads',
        '0',
        '-pix_fmt',
        'yuv420p',
        ...tail(copyAudio: false),
      ]),
    ];
  }

  String _baseVideoFilter() {
    return '[0:v]scale=$outputWidth:$outputHeight:force_original_aspect_ratio=decrease,'
        'pad=$outputWidth:$outputHeight:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1[base];';
  }

  String _filterWithoutPhoto({required int? stripInputIndex}) {
    final base = _baseVideoFilter();
    if (stripInputIndex == null) {
      return '$base[base]null[v]';
    }
    return '$base[base][$stripInputIndex:v]overlay=0:H-h:format=auto[v]';
  }

  String _filterWithOverlays({
    required _PreparedOverlayPhoto? mainPhoto,
    required int? mainPhotoInputIndex,
    required _PreparedOverlayPhoto? extraPhoto,
    required int? extraPhotoInputIndex,
    required int? stripInputIndex,
  }) {
    if (mainPhoto == null && extraPhoto == null) {
      return _filterWithoutPhoto(stripInputIndex: stripInputIndex);
    }
    final buffer = StringBuffer(_baseVideoFilter());
    var currentLabel = 'base';
    if (mainPhoto != null && mainPhotoInputIndex != null) {
      buffer.write(
        _photoOverlayFilter(
          overlay: mainPhoto,
          inputIndex: mainPhotoInputIndex,
          inputLabel: currentLabel,
          outputLabel: 'main_photo_out',
          scaledLabel: 'main_photo',
        ),
      );
      currentLabel = 'main_photo_out';
    }
    if (extraPhoto != null && extraPhotoInputIndex != null) {
      buffer.write(
        _photoOverlayFilter(
          overlay: extraPhoto,
          inputIndex: extraPhotoInputIndex,
          inputLabel: currentLabel,
          outputLabel: 'extra_photo_out',
          scaledLabel: 'extra_photo',
        ),
      );
      currentLabel = 'extra_photo_out';
    }
    if (stripInputIndex == null) {
      buffer.write('[$currentLabel]null[v]');
    } else {
      buffer.write(
        '[$currentLabel][$stripInputIndex:v]overlay=0:H-h:format=auto[v]',
      );
    }
    return buffer.toString();
  }

  String _photoOverlayFilter({
    required _PreparedOverlayPhoto overlay,
    required int inputIndex,
    required String inputLabel,
    required String outputLabel,
    required String scaledLabel,
  }) {
    final targetWidth = (outputWidth * (overlay.scale / 100)).clamp(
      96.0,
      820.0,
    );
    final targetCenterX = (outputWidth * (overlay.x / 100)).clamp(
      0.0,
      outputWidth.toDouble(),
    );
    final targetCenterY = (outputHeight * (overlay.y / 100)).clamp(
      0.0,
      outputHeight.toDouble(),
    );
    final animation = _normalizeVideoPhotoAnimation(overlay.animation);
    final progress = '(min(t,$_animationSeconds)/$_animationSeconds)';
    String animatedCenterX = '$targetCenterX';
    String animatedCenterY = '$targetCenterY';
    String animatedWidth = '$targetWidth';
    if (_isDirectionalAnimation(animation)) {
      final start = _startPointForAnimation(
        animation,
        targetCenterX,
        targetCenterY,
        targetWidth,
      );
      animatedCenterX = _ffExpr(
        'if(lt(t,$_animationSeconds),${start.dx}+($targetCenterX-${start.dx})*$progress,$targetCenterX)',
      );
      animatedCenterY = _ffExpr(
        'if(lt(t,$_animationSeconds),${start.dy}+($targetCenterY-${start.dy})*$progress,$targetCenterY)',
      );
    } else if (animation == 'zoom_in') {
      animatedWidth = _ffExpr(
        'if(lt(t,$_animationSeconds),$targetWidth*(0.22+0.78*$progress),$targetWidth)',
      );
    } else if (animation == 'zoom_out') {
      animatedWidth = _ffExpr(
        'if(lt(t,$_animationSeconds),$targetWidth*(1.35-0.35*$progress),$targetWidth)',
      );
    }
    return '[$inputIndex:v]scale=w=$animatedWidth:h=-1:eval=frame[$scaledLabel];'
        '[$inputLabel][$scaledLabel]overlay='
        'x=$animatedCenterX-overlay_w/2:'
        'y=$animatedCenterY-overlay_h/2:'
        'format=auto[$outputLabel];';
  }

  String _ffExpr(String expression) => expression.replaceAll(',', r'\,');

  bool _isDirectionalAnimation(String animation) {
    return animation == 'top_to_place' ||
        animation == 'bottom_to_place' ||
        animation == 'left_to_place' ||
        animation == 'right_to_place';
  }

  String _normalizeVideoPhotoAnimation(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'top_to_place':
      case 'bottom_to_place':
      case 'left_to_place':
      case 'right_to_place':
      case 'zoom_in':
      case 'zoom_out':
        return raw.trim().toLowerCase();
      default:
        return 'none';
    }
  }

  ui.Offset _startPointForAnimation(
    String animation,
    double targetX,
    double targetY,
    double targetWidth,
  ) {
    switch (animation) {
      case 'top_to_place':
        return ui.Offset(targetX, -targetWidth);
      case 'bottom_to_place':
        return ui.Offset(targetX, outputHeight + targetWidth);
      case 'left_to_place':
        return ui.Offset(-targetWidth, targetY);
      case 'right_to_place':
        return ui.Offset(outputWidth + targetWidth, targetY);
      default:
        return ui.Offset(targetX, targetY);
    }
  }
}
