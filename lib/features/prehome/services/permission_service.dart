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
  PermissionService();

  PermissionSnapshot defaultSnapshot() {
    return const PermissionSnapshot(
      photos: AppPermissionState(
        type: AppPermissionType.photos,
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
    final PermissionStatus photosStatus = await _safeStatus(photosPermission);
    final PermissionStatus notificationsStatus = await _safeStatus(
      Permission.notification,
    );

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
    final PermissionStatus photosStatus = await _safeRequest(photosPermission);
    final PermissionStatus notificationsStatus = await _safeRequest(
      Permission.notification,
    );

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

  Future<PermissionStatus> requestSingle(AppPermissionType type) async {
    final Permission permission = await _permissionFor(type);
    return _safeRequest(permission);
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
}
