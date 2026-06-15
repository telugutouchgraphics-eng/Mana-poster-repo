import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image_lib;

import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/models/community_status.dart';
import 'package:mana_poster/features/prehome/services/app_location_service.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

enum CommunityStatusSubmitCode {
  success,
  loginRequired,
  regionRequired,
  contentRequired,
  textTooLong,
  imageTooLarge,
  uploadFailed,
}

class CommunityStatusSubmitResult {
  const CommunityStatusSubmitResult._({required this.ok, required this.code});

  final bool ok;
  final CommunityStatusSubmitCode code;

  static const CommunityStatusSubmitResult success =
      CommunityStatusSubmitResult._(
        ok: true,
        code: CommunityStatusSubmitCode.success,
      );

  static CommunityStatusSubmitResult failure(CommunityStatusSubmitCode code) {
    return CommunityStatusSubmitResult._(ok: false, code: code);
  }
}

class CommunityStatusService {
  CommunityStatusService._();

  static final CommunityStatusService instance = CommunityStatusService._();

  static const int targetImageBytes = 500 * 1024;
  static const int maxImageBytes = targetImageBytes;
  static const int maxSourceImageBytes = 12 * 1024 * 1024;
  static const int maxTextLength = 300;
  static const int maxCommentLength = 220;
  static const int maxReportDetailsLength = 500;
  static const int statusLifetimeMillis = 24 * 60 * 60 * 1000;
  static const List<int> _compressionDimensions = <int>[
    1920,
    1680,
    1440,
    1280,
    1080,
    960,
    840,
    720,
    640,
  ];
  static const List<int> _compressionQualities = <int>[
    92,
    90,
    88,
    86,
    84,
    82,
    80,
    78,
    76,
    74,
    72,
    70,
    68,
    66,
    64,
    62,
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static bool _sameText(String a, String b) {
    return a.trim().isNotEmpty &&
        b.trim().isNotEmpty &&
        a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static String _normalizedImageExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last.trim();
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }
    return switch (fileName.substring(dotIndex + 1).toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      'jpeg' => 'jpg',
      'jpg' => 'jpg',
      _ => 'jpg',
    };
  }

  static String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  static image_lib.Image _resizeForLongestSide(
    image_lib.Image image,
    int longestSide,
  ) {
    final width = image.width;
    final height = image.height;
    final currentLongestSide = width > height ? width : height;
    if (currentLongestSide <= longestSide) {
      return image;
    }
    final scale = longestSide / currentLongestSide;
    return image_lib.copyResize(
      image,
      width: (width * scale).round(),
      height: (height * scale).round(),
      interpolation: image_lib.Interpolation.linear,
    );
  }

  Future<({File file, String extension, bool temporary})> _prepareImageUpload(
    File imageFile,
  ) async {
    final originalBytes = await imageFile.readAsBytes();
    final originalExtension = _normalizedImageExtension(imageFile.path);
    if (originalBytes.length <= targetImageBytes) {
      return (file: imageFile, extension: originalExtension, temporary: false);
    }

    final decoded = image_lib.decodeImage(originalBytes);
    if (decoded == null) {
      return (file: imageFile, extension: originalExtension, temporary: false);
    }

    final oriented = image_lib.bakeOrientation(decoded);
    List<int>? bestBytes;
    for (final dimension in _compressionDimensions) {
      final resized = _resizeForLongestSide(oriented, dimension);
      for (final quality in _compressionQualities) {
        final encoded = image_lib.encodeJpg(resized, quality: quality);
        if (bestBytes == null || encoded.length < bestBytes.length) {
          bestBytes = encoded;
        }
        if (encoded.length <= targetImageBytes) {
          final tempFile = File(
            '${Directory.systemTemp.path}/mana_poster_status_'
            '${DateTime.now().microsecondsSinceEpoch}.jpg',
          );
          await tempFile.writeAsBytes(encoded, flush: true);
          return (file: tempFile, extension: 'jpg', temporary: true);
        }
      }
    }

    if (bestBytes == null) {
      return (file: imageFile, extension: originalExtension, temporary: false);
    }
    final tempFile = File(
      '${Directory.systemTemp.path}/mana_poster_status_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(bestBytes, flush: true);
    return (file: tempFile, extension: 'jpg', temporary: true);
  }

  static int _readCounter(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return fallback;
  }

  Future<({AppRegion region, AppReligionPreference religion})?>
  _currentVisibilityScope() async {
    final region = await AppRegionService.loadSelection();
    if (region == null) {
      return null;
    }
    final religion =
        await AppReligionService.loadSelection() ?? AppReligionPreference.all;
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
              'selectedRegion': region.id,
              'selectedRegionName': region.name,
              'selectedRegionLanguage': region.primaryLanguage,
              'selectedRegionLanguageCode': region.primaryLanguageCode,
              'religionPreference': religion.name,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Local scope still drives writes; remote sync will retry later.
      }
    }
    return (region: region, religion: religion);
  }

  Stream<List<CommunityStatus>> watchVisibleStatuses() async* {
    final scope = await _currentVisibilityScope();
    final user = _auth.currentUser;
    if (scope == null || user == null) {
      yield const <CommunityStatus>[];
      return;
    }
    final feedSeed = await AppLocationService.instance
        .getOrCreateStatusFeedSeed();
    final area = await AppLocationService.instance.loadLocationArea();
    final controller = StreamController<List<CommunityStatus>>();
    final byId = <String, CommunityStatus>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void publish() {
      if (controller.isClosed) {
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final latest =
          byId.values
              .where((status) => status.expiresAtMillis > now)
              .toList(growable: false)
            ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
      final ranked = <({CommunityStatus status, int score})>[];
      for (var index = 0; index < latest.length; index += 1) {
        final status = latest[index];
        var locationBoost = 0;
        if (area != null) {
          if (_sameText(status.locationCity, area.city)) {
            locationBoost = 30;
          } else if (_sameText(status.locationDistrict, area.district)) {
            locationBoost = 18;
          } else if (_sameText(status.locationState, area.state)) {
            locationBoost = 8;
          }
        }
        final jitter = _stableHash('$feedSeed:${status.id}') % 20;
        ranked.add((status: status, score: index + jitter - locationBoost));
      }
      ranked.sort((a, b) {
        final scoreCompare = a.score.compareTo(b.score);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return b.status.createdAtMillis.compareTo(a.status.createdAtMillis);
      });
      controller.add(
        ranked.map((item) => item.status).take(60).toList(growable: false),
      );
    }

    void listenForReligion(String religionName) {
      final query = _firestore
          .collection('communityStatuses')
          .where('regionId', isEqualTo: scope.region.id)
          .where('religionPreference', isEqualTo: religionName)
          .orderBy('createdAt', descending: true)
          .limit(150);
      subscriptions.add(
        query.snapshots().listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.removed) {
              byId.remove(change.doc.id);
            } else {
              byId[change.doc.id] = CommunityStatus.fromMap(
                change.doc.id,
                change.doc.data() ?? const <String, dynamic>{},
                viewerUserId: user.uid,
              );
            }
          }
          publish();
        }, onError: controller.addError),
      );
    }

    final religionName = scope.religion.name;
    if (religionName == AppReligionPreference.all.name) {
      for (final item in AppReligionPreference.values) {
        listenForReligion(item.name);
      }
    } else {
      listenForReligion(religionName);
      listenForReligion(AppReligionPreference.all.name);
    }

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    yield* controller.stream;
  }

  Future<CommunityStatusSubmitResult> submitStatus({
    required File? imageFile,
    required String text,
    required int backgroundColor,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return CommunityStatusSubmitResult.failure(
        CommunityStatusSubmitCode.loginRequired,
      );
    }
    final scope = await _currentVisibilityScope();
    if (scope == null) {
      return CommunityStatusSubmitResult.failure(
        CommunityStatusSubmitCode.regionRequired,
      );
    }
    final safeText = text.trim();
    if (imageFile == null && safeText.isEmpty) {
      return CommunityStatusSubmitResult.failure(
        CommunityStatusSubmitCode.contentRequired,
      );
    }
    if (safeText.length > maxTextLength) {
      return CommunityStatusSubmitResult.failure(
        CommunityStatusSubmitCode.textTooLong,
      );
    }
    final sourceImageSize = imageFile == null ? 0 : await imageFile.length();
    if (sourceImageSize > maxSourceImageBytes) {
      return CommunityStatusSubmitResult.failure(
        CommunityStatusSubmitCode.imageTooLarge,
      );
    }

    File? temporaryImageFile;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final doc = _firestore.collection('communityStatuses').doc();
      var imagePath = '';
      var imageUrl = '';
      if (imageFile != null) {
        final preparedImage = await _prepareImageUpload(imageFile);
        if (preparedImage.temporary) {
          temporaryImageFile = preparedImage.file;
        }
        final extension = preparedImage.extension;
        imagePath = 'users/${user.uid}/status_uploads/${doc.id}.$extension';
        final imageRef = _storage.ref(imagePath);
        await imageRef.putFile(
          preparedImage.file,
          SettableMetadata(contentType: _contentTypeForExtension(extension)),
        );
        imageUrl = await imageRef.getDownloadURL();
      }

      final profile = await PosterProfileService.load();
      final userName = profile.activeName.trim().isNotEmpty
          ? profile.activeName.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'User');
      final userPhotoUrl = profile.photoUrl.trim().isNotEmpty
          ? profile.photoUrl.trim()
          : (user.photoURL ?? '').trim();
      final statusType = imageUrl.isNotEmpty && safeText.isNotEmpty
          ? 'image_text'
          : imageUrl.isNotEmpty
          ? 'image'
          : 'text';
      final area = await AppLocationService.instance.loadLocationArea();

      await doc.set(<String, dynamic>{
        'id': doc.id,
        'userId': user.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'text': safeText,
        'statusType': statusType,
        'regionId': scope.region.id,
        'regionName': scope.region.name,
        'religionPreference': scope.religion.name,
        'locationState': area?.state.trim() ?? '',
        'locationDistrict': area?.district.trim() ?? '',
        'locationCity': area?.city.trim() ?? '',
        'backgroundColor': backgroundColor,
        'viewCount': 0,
        'likeCount': 0,
        'reactionCount': 0,
        'viewsByUser': <String, bool>{},
        'likesByUser': <String, bool>{},
        'reactionsByUser': <String, String>{},
        'createdAt': now,
        'updatedAt': now,
        'expiresAt': now + statusLifetimeMillis,
      });
      return CommunityStatusSubmitResult.success;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CommunityStatusService.submitStatus failed: $error');
      }
      return CommunityStatusSubmitResult.failure(
        CommunityStatusSubmitCode.uploadFailed,
      );
    } finally {
      final file = temporaryImageFile;
      if (file != null) {
        unawaited(file.delete().catchError((_) => file));
      }
    }
  }

  Stream<CommunityStatus?> watchStatus(String statusId) {
    final id = statusId.trim();
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (id.isEmpty) {
      return Stream<CommunityStatus?>.value(null);
    }
    return _firestore.collection('communityStatuses').doc(id).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return CommunityStatus.fromMap(snapshot.id, data, viewerUserId: uid);
    });
  }

  Future<void> recordView(String statusId) async {
    final id = statusId.trim();
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (id.isEmpty || uid.isEmpty) {
      return;
    }
    final ref = _firestore.collection('communityStatuses').doc(id);
    try {
      await _firestore
          .runTransaction((transaction) async {
            final snapshot = await transaction.get(ref);
            final data = snapshot.data() ?? const <String, dynamic>{};
            final viewsByUser = CommunityStatus.readStatusMap(
              data['viewsByUser'],
            );
            if (viewsByUser[uid] == true) {
              return;
            }
            final likesByUser = CommunityStatus.readStatusMap(
              data['likesByUser'],
            );
            final reactionsByUser = CommunityStatus.readStatusMap(
              data['reactionsByUser'],
            );
            final nextViewsByUser = Map<String, dynamic>.of(viewsByUser)
              ..[uid] = true;
            transaction.set(ref, <String, dynamic>{
              'viewsByUser': nextViewsByUser,
              'likesByUser': likesByUser,
              'reactionsByUser': reactionsByUser,
              'viewCount':
                  _readCounter(data['viewCount'], viewsByUser.length) + 1,
              'likeCount': _readCounter(data['likeCount'], likesByUser.length),
              'reactionCount': _readCounter(
                data['reactionCount'],
                reactionsByUser.length,
              ),
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            }, SetOptions(merge: true));
          })
          .timeout(const Duration(seconds: 4));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CommunityStatusService.recordView failed: $error');
      }
    }
  }

  Future<void> toggleLike(String statusId) async {
    final id = statusId.trim();
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (id.isEmpty || uid.isEmpty) {
      return;
    }
    final ref = _firestore.collection('communityStatuses').doc(id);
    try {
      await _firestore
          .runTransaction((transaction) async {
            final snapshot = await transaction.get(ref);
            final data = snapshot.data() ?? const <String, dynamic>{};
            final likesByUser = CommunityStatus.readStatusMap(
              data['likesByUser'],
            );
            final viewsByUser = CommunityStatus.readStatusMap(
              data['viewsByUser'],
            );
            final reactionsByUser = CommunityStatus.readStatusMap(
              data['reactionsByUser'],
            );
            final hasLiked = likesByUser[uid] == true;
            final nextLikesByUser = Map<String, dynamic>.of(likesByUser);
            if (hasLiked) {
              nextLikesByUser.remove(uid);
            } else {
              nextLikesByUser[uid] = true;
            }
            transaction.set(ref, <String, dynamic>{
              'viewsByUser': viewsByUser,
              'likesByUser': nextLikesByUser,
              'reactionsByUser': reactionsByUser,
              'viewCount': _readCounter(data['viewCount'], viewsByUser.length),
              'likeCount': nextLikesByUser.length,
              'reactionCount': _readCounter(
                data['reactionCount'],
                reactionsByUser.length,
              ),
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            }, SetOptions(merge: true));
          })
          .timeout(const Duration(seconds: 4));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CommunityStatusService.toggleLike failed: $error');
      }
    }
  }

  Future<void> setReaction(String statusId, String reaction) async {
    final id = statusId.trim();
    final uid = _auth.currentUser?.uid.trim() ?? '';
    final safeReaction = reaction.trim();
    if (id.isEmpty || uid.isEmpty || safeReaction.isEmpty) {
      return;
    }
    final ref = _firestore.collection('communityStatuses').doc(id);
    try {
      await _firestore
          .runTransaction((transaction) async {
            final snapshot = await transaction.get(ref);
            final data = snapshot.data() ?? const <String, dynamic>{};
            final reactionsByUser = CommunityStatus.readStatusMap(
              data['reactionsByUser'],
            );
            final viewsByUser = CommunityStatus.readStatusMap(
              data['viewsByUser'],
            );
            final likesByUser = CommunityStatus.readStatusMap(
              data['likesByUser'],
            );
            final previous = (reactionsByUser[uid] ?? '').toString().trim();
            final nextReactionsByUser = Map<String, dynamic>.of(
              reactionsByUser,
            );
            if (previous == safeReaction) {
              nextReactionsByUser.remove(uid);
            } else {
              nextReactionsByUser[uid] = safeReaction;
            }
            transaction.set(ref, <String, dynamic>{
              'viewsByUser': viewsByUser,
              'likesByUser': likesByUser,
              'reactionsByUser': nextReactionsByUser,
              'viewCount': _readCounter(data['viewCount'], viewsByUser.length),
              'likeCount': _readCounter(data['likeCount'], likesByUser.length),
              'reactionCount': nextReactionsByUser.length,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            }, SetOptions(merge: true));
          })
          .timeout(const Duration(seconds: 4));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CommunityStatusService.setReaction failed: $error');
      }
    }
  }

  Stream<List<CommunityStatusComment>> watchComments(String statusId) {
    final id = statusId.trim();
    if (id.isEmpty) {
      return Stream<List<CommunityStatusComment>>.value(
        const <CommunityStatusComment>[],
      );
    }
    return _firestore
        .collection('communityStatuses')
        .doc(id)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                return CommunityStatusComment.fromMap(doc.id, doc.data());
              })
              .toList(growable: false);
        });
  }

  Future<bool> submitComment(CommunityStatus status, String text) async {
    final user = _auth.currentUser;
    final statusId = status.id.trim();
    final safeText = text.trim();
    if (user == null ||
        statusId.isEmpty ||
        safeText.isEmpty ||
        safeText.length > maxCommentLength ||
        status.userId == user.uid) {
      return false;
    }
    try {
      final profile = await PosterProfileService.load();
      final userName = profile.activeName.trim().isNotEmpty
          ? profile.activeName.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'User');
      final now = DateTime.now().millisecondsSinceEpoch;
      final ref = _firestore
          .collection('communityStatuses')
          .doc(statusId)
          .collection('comments')
          .doc();
      await ref
          .set(<String, dynamic>{
            'id': ref.id,
            'statusId': statusId,
            'statusOwnerId': status.userId,
            'userId': user.uid,
            'userName': userName,
            'text': safeText,
            'createdAt': now,
          })
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CommunityStatusService.submitComment failed: $error');
      }
      return false;
    }
  }

  Future<bool> submitReport({
    required CommunityStatus status,
    CommunityStatusComment? comment,
    required String reason,
    required String details,
  }) async {
    final user = _auth.currentUser;
    final statusId = status.id.trim();
    final safeReason = reason.trim();
    final safeDetails = details.trim();
    final isCommentReport = comment != null;
    final reportedUserId = isCommentReport
        ? comment.userId.trim()
        : status.userId.trim();
    if (user == null ||
        statusId.isEmpty ||
        safeReason.isEmpty ||
        safeReason.length > 80 ||
        safeDetails.length > maxReportDetailsLength ||
        reportedUserId.isEmpty ||
        reportedUserId == user.uid) {
      return false;
    }
    try {
      final profile = await PosterProfileService.load();
      final reporterName = profile.activeName.trim().isNotEmpty
          ? profile.activeName.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'User');
      final now = DateTime.now().millisecondsSinceEpoch;
      final ref = _firestore.collection('communityContentReports').doc();
      await ref
          .set(<String, dynamic>{
            'id': ref.id,
            'contentType': isCommentReport ? 'comment' : 'status',
            'statusId': statusId,
            'commentId': comment?.id.trim() ?? '',
            'reportedUserId': reportedUserId,
            'reportedUserName': isCommentReport
                ? comment.userName.trim()
                : status.userName.trim(),
            'reporterUserId': user.uid,
            'reporterName': reporterName,
            'reporterEmail': user.email?.trim() ?? '',
            'reason': safeReason,
            'details': safeDetails,
            'statusTextPreview': status.text.trim(),
            'commentTextPreview': comment?.text.trim() ?? '',
            'statusImagePath': status.imagePath.trim(),
            'regionId': status.regionId.trim(),
            'regionName': status.regionName.trim(),
            'religionPreference': status.religionPreference.trim(),
            'locationState': status.locationState.trim(),
            'locationDistrict': status.locationDistrict.trim(),
            'locationCity': status.locationCity.trim(),
            'statusCreatedAt': status.createdAtMillis,
            'reportedAt': now,
            'reviewStatus': 'pending',
          })
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CommunityStatusService.submitReport failed: $error');
      }
      return false;
    }
  }

  Future<bool> deleteStatus(CommunityStatus status) async {
    final user = _auth.currentUser;
    final id = status.id.trim();
    if (user == null || id.isEmpty || status.userId != user.uid) {
      return false;
    }
    try {
      while (true) {
        final comments = await _firestore
            .collection('communityStatuses')
            .doc(id)
            .collection('comments')
            .limit(80)
            .get()
            .timeout(const Duration(seconds: 5));
        if (comments.docs.isEmpty) {
          break;
        }
        final batch = _firestore.batch();
        for (final doc in comments.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit().timeout(const Duration(seconds: 5));
        if (comments.docs.length < 80) {
          break;
        }
      }
      await _firestore
          .collection('communityStatuses')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 5));
      final imagePath = status.imagePath.trim();
      if (imagePath.isNotEmpty) {
        try {
          await _storage
              .ref(imagePath)
              .delete()
              .timeout(const Duration(seconds: 5));
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              'CommunityStatusService.deleteStatus image cleanup failed: $error',
            );
          }
        }
      }
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CommunityStatusService.deleteStatus failed: $error');
      }
      return false;
    }
  }
}
