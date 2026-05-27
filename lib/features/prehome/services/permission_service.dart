import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType { photos, camera, notifications }

class AppPermissionState {
  const AppPermissionState({required this.type, required this.status});

  final AppPermissionType type;
  final PermissionStatus status;

  bool get isGranted => status.isGranted || status.isLimited;
  bool get isDenied => status.isDenied;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;
  bool get isRestricted => status.isRestricted;
  bool get needsSettings => isPermanentlyDenied || isRestricted;
}

class PermissionSnapshot {
  const PermissionSnapshot({
    required this.photos,
    required this.camera,
    required this.notifications,
  });

  final AppPermissionState photos;
  final AppPermissionState camera;
  final AppPermissionState notifications;

  List<AppPermissionState> get items => <AppPermissionState>[
    photos,
    camera,
    notifications,
  ];

  bool get allGranted =>
      items.every((AppPermissionState item) => item.isGranted);
  bool get anyDenied => items.any((AppPermissionState item) => item.isDenied);
  bool get anyNeedsSettings =>
      items.any((AppPermissionState item) => item.needsSettings);
}

class PermissionService {
  PermissionService({
    DeviceInfoPlugin? deviceInfo,
    Future<int?> Function()? androidSdkIntLoader,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _androidSdkIntLoader = androidSdkIntLoader;

  final DeviceInfoPlugin _deviceInfo;
  final Future<int?> Function()? _androidSdkIntLoader;

  PermissionSnapshot defaultSnapshot() {
    return const PermissionSnapshot(
      photos: AppPermissionState(
        type: AppPermissionType.photos,
        status: PermissionStatus.denied,
      ),
      camera: AppPermissionState(
        type: AppPermissionType.camera,
        status: PermissionStatus.denied,
      ),
      notifications: AppPermissionState(
        type: AppPermissionType.notifications,
        status: PermissionStatus.denied,
      ),
    );
  }

  Future<PermissionSnapshot> getSnapshot() async {
    final PermissionStatus photosStatus = await _resolvePhotosStatus();
    final Permission cameraPermission = await _resolveCameraPermission();
    final PermissionStatus cameraStatus = await _safeStatus(cameraPermission);
    final PermissionStatus notificationsStatus =
        await _resolveNotificationStatus();

    return PermissionSnapshot(
      photos: AppPermissionState(
        type: AppPermissionType.photos,
        status: photosStatus,
      ),
      camera: AppPermissionState(
        type: AppPermissionType.camera,
        status: cameraStatus,
      ),
      notifications: AppPermissionState(
        type: AppPermissionType.notifications,
        status: notificationsStatus,
      ),
    );
  }

  Future<PermissionSnapshot> requestEssentialPermissions() async {
    final PermissionStatus photosStatus = await _requestPhotosStatus();
    final Permission cameraPermission = await _resolveCameraPermission();
    final PermissionStatus cameraStatus = await _safeRequest(cameraPermission);
    final PermissionStatus notificationsStatus =
        await _requestNotificationStatus();

    return PermissionSnapshot(
      photos: AppPermissionState(
        type: AppPermissionType.photos,
        status: photosStatus,
      ),
      camera: AppPermissionState(
        type: AppPermissionType.camera,
        status: cameraStatus,
      ),
      notifications: AppPermissionState(
        type: AppPermissionType.notifications,
        status: notificationsStatus,
      ),
    );
  }

  Future<PermissionStatus> requestSingle(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.photos:
        return _requestPhotosStatus();
      case AppPermissionType.camera:
        return _safeRequest(await _resolveCameraPermission());
      case AppPermissionType.notifications:
        return _requestNotificationStatus();
    }
  }

  Future<bool> openSettings() => openAppSettings();

  Future<Permission> _resolveCameraPermission() async {
    return Permission.camera;
  }

  Future<Permission> _resolveNotificationPermission() async {
    return Permission.notification;
  }

  Future<int?> _loadAndroidSdkInt() async {
    final override = _androidSdkIntLoader;
    if (override != null) {
      return override();
    }
    try {
      final info = await _deviceInfo.androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _needsPhotosPermission() async {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final sdkInt = await _loadAndroidSdkInt();
    return sdkInt == null || sdkInt <= 28;
  }

  Future<PermissionStatus> _resolvePhotosStatus() async {
    if (!(await _needsPhotosPermission())) {
      return PermissionStatus.granted;
    }
    final permission = await _resolvePhotosPermission();
    return _safeStatus(permission);
  }

  Future<PermissionStatus> _requestPhotosStatus() async {
    if (!(await _needsPhotosPermission())) {
      return PermissionStatus.granted;
    }
    final permission = await _resolvePhotosPermission();
    return _safeRequest(permission);
  }

  Future<Permission> _resolvePhotosPermission() async {
    if (kIsWeb) {
      return Permission.photos;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Permission.storage;
    }
    return Permission.photos;
  }

  Future<PermissionStatus> _safeStatus(Permission permission) async {
    try {
      return await permission.status;
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  Future<PermissionStatus> _safeRequest(Permission permission) async {
    try {
      return await permission.request();
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  Future<PermissionStatus> _resolveNotificationStatus() async {
    if (kIsWeb) {
      return PermissionStatus.granted;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final int? sdkInt = await _loadAndroidSdkInt();
      if (sdkInt != null && sdkInt < 33) {
        return PermissionStatus.granted;
      }
    }
    return _safeStatus(await _resolveNotificationPermission());
  }

  Future<PermissionStatus> _requestNotificationStatus() async {
    if (kIsWeb) {
      return PermissionStatus.granted;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final int? sdkInt = await _loadAndroidSdkInt();
      if (sdkInt != null && sdkInt < 33) {
        return PermissionStatus.granted;
      }
    }
    return _safeRequest(await _resolveNotificationPermission());
  }
}
