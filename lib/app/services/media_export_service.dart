import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class MediaExportResult {
  const MediaExportResult({
    required this.success,
    this.code,
    this.message,
  });

  final bool success;
  final String? code;
  final String? message;

  factory MediaExportResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const MediaExportResult(
        success: false,
        code: 'empty_result',
        message: 'No result returned from native save operation.',
      );
    }
    return MediaExportResult(
      success: map['success'] == true,
      code: map['code']?.toString(),
      message: map['message']?.toString(),
    );
  }
}

class MediaShareException implements Exception {
  const MediaShareException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'MediaShareException(code: $code, message: $message)';
}

class MediaExportService {
  MediaExportService._();

  static const MethodChannel _channel = MethodChannel(
    'mana_poster/media_export',
  );

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void _debugLogStack(String message, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
    debugPrintStack(stackTrace: stackTrace);
  }

  static Future<bool> needsGalleryPermission() async {
    if (kIsWeb || !Platform.isAndroid) {
      return !kIsWeb && Platform.isIOS;
    }
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt <= 28;
    } catch (_) {
      return true;
    }
  }

  static Future<MediaExportResult> saveImageFileToGalleryDetailed(
    String filePath, {
    required String fileName,
    String mimeType = 'image/png',
  }) async {
    if (kIsWeb) {
      return const MediaExportResult(
        success: false,
        code: 'unsupported_platform',
        message: 'Gallery save is not supported on web.',
      );
    }
    if (Platform.isAndroid) {
      try {
        final saved = await _channel.invokeMapMethod<dynamic, dynamic>(
          'saveImageFileToGallery',
          <String, dynamic>{
            'filePath': filePath,
            'fileName': fileName,
            'mimeType': mimeType,
          },
        );
        return MediaExportResult.fromMap(saved);
      } catch (error, stackTrace) {
        _debugLogStack('saveImageFileToGallery native error: $error', stackTrace);
        return MediaExportResult(
          success: false,
          code: 'platform_exception',
          message: error.toString(),
        );
      }
    }
    return const MediaExportResult(
      success: false,
      code: 'unsupported_platform',
      message: 'Gallery save is not supported on this platform.',
    );
  }

  static Future<bool> saveImageFileToGallery(
    String filePath, {
    required String fileName,
    String mimeType = 'image/png',
  }) async {
    final result = await saveImageFileToGalleryDetailed(
      filePath,
      fileName: fileName,
      mimeType: mimeType,
    );
    return result.success;
  }

  static Future<void> shareImageFile(
    String filePath, {
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    bool result = false;
    try {
      await Share.shareXFiles(
        <XFile>[XFile(filePath)],
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      );
      result = true;
    } catch (error, stackTrace) {
      _debugLogStack('shareImageFile error: $error', stackTrace);
      result = false;
      throw MediaShareException(
        code: 'share_failed',
        message: error.toString(),
      );
    } finally {
      _debugLog('shareImageFile result=$result');
    }
  }
}
