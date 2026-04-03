import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType { photos, notifications }

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
  const PermissionSnapshot({required this.photos, required this.notifications});

  final AppPermissionState photos;
  final AppPermissionState notifications;

  List<AppPermissionState> get items => <AppPermissionState>[
    photos,
    notifications,
  ];

  bool get allGranted =>
      items.every((AppPermissionState item) => item.isGranted);
  bool get anyDenied => items.any((AppPermissionState item) => item.isDenied);
  bool get anyNeedsSettings =>
      items.any((AppPermissionState item) => item.needsSettings);
}

class PermissionService {
  PermissionService({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  Future<PermissionSnapshot> getSnapshot() async {
    final Permission photosPermission = await _resolvePhotosPermission();
    final PermissionStatus photosStatus = await photosPermission.status;
    final PermissionStatus notificationsStatus =
        await Permission.notification.status;

    return PermissionSnapshot(
      photos: AppPermissionState(
        type: AppPermissionType.photos,
        status: photosStatus,
      ),
      notifications: AppPermissionState(
        type: AppPermissionType.notifications,
        status: notificationsStatus,
      ),
    );
  }

  Future<PermissionSnapshot> requestEssentialPermissions() async {
    final Permission photosPermission = await _resolvePhotosPermission();

    final Map<Permission, PermissionStatus> result = await <Permission>[
      photosPermission,
      Permission.notification,
    ].request();

    return PermissionSnapshot(
      photos: AppPermissionState(
        type: AppPermissionType.photos,
        status: result[photosPermission] ?? PermissionStatus.denied,
      ),
      notifications: AppPermissionState(
        type: AppPermissionType.notifications,
        status: result[Permission.notification] ?? PermissionStatus.denied,
      ),
    );
  }

  Future<PermissionStatus> requestSingle(AppPermissionType type) async {
    final Permission permission = await _permissionFor(type);
    return permission.request();
  }

  Future<bool> openSettings() => openAppSettings();

  Future<Permission> _permissionFor(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.photos:
        return _resolvePhotosPermission();
      case AppPermissionType.notifications:
        return Future<Permission>.value(Permission.notification);
    }
  }

  Future<Permission> _resolvePhotosPermission() async {
    if (!Platform.isAndroid) {
      return Permission.photos;
    }

    final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
    if (info.version.sdkInt >= 33) {
      return Permission.photos;
    }
    return Permission.storage;
  }
}
