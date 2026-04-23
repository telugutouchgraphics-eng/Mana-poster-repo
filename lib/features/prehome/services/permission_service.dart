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
    final Permission photosPermission = await _resolvePhotosPermission();
    final Permission cameraPermission = await _resolveCameraPermission();
    final PermissionStatus photosStatus = await _safeStatus(photosPermission);
    final PermissionStatus cameraStatus = await _safeStatus(cameraPermission);
    final PermissionStatus notificationsStatus = await _safeStatus(
      Permission.notification,
    );

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
    final Permission photosPermission = await _resolvePhotosPermission();
    final Permission cameraPermission = await _resolveCameraPermission();
    final PermissionStatus photosStatus = await _safeRequest(photosPermission);
    final PermissionStatus cameraStatus = await _safeRequest(cameraPermission);
    final PermissionStatus notificationsStatus = await _safeRequest(
      Permission.notification,
    );

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
    final Permission permission = await _permissionFor(type);
    return _safeRequest(permission);
  }

  Future<bool> openSettings() => openAppSettings();

  Future<Permission> _permissionFor(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.photos:
        return _resolvePhotosPermission();
      case AppPermissionType.camera:
        return _resolveCameraPermission();
      case AppPermissionType.notifications:
        return Future<Permission>.value(Permission.notification);
    }
  }

  Future<Permission> _resolvePhotosPermission() async {
    if (kIsWeb) {
      return Permission.photos;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdkInt = await _loadAndroidSdkInt();
      return sdkInt != null && sdkInt >= 33
          ? Permission.photos
          : Permission.storage;
    }
    return Permission.photos;
  }

  Future<Permission> _resolveCameraPermission() async {
    return Permission.camera;
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
}
