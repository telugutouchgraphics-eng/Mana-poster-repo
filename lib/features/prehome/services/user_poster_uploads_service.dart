import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/services/ist_time_service.dart';
import 'package:mana_poster/features/prehome/models/user_poster_upload.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class UserPosterUploadSubmitResult {
  const UserPosterUploadSubmitResult._({required this.ok, required this.code});

  final bool ok;
  final UserPosterUploadSubmitCode code;

  static UserPosterUploadSubmitResult success() =>
      const UserPosterUploadSubmitResult._(
        ok: true,
        code: UserPosterUploadSubmitCode.success,
      );

  static UserPosterUploadSubmitResult failure(
    UserPosterUploadSubmitCode code,
  ) => UserPosterUploadSubmitResult._(ok: false, code: code);
}

enum UserPosterUploadSubmitCode {
  success,
  loginRequired,
  categoryRequired,
  contentRequired,
  imageTooLarge,
  quoteTooLong,
  uploadFailed,
}

class UserPosterUploadsService {
  UserPosterUploadsService._();

  static const int maxUploadBytes = 500 * 1024;
  static const int maxQuoteLength = 600;
  static const int retentionMillis = 7 * 24 * 60 * 60 * 1000;
  static const int _uploadCutoffHourIst = 22;
  static final UserPosterUploadsService instance = UserPosterUploadsService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const List<Duration> _transientReadRetryDelays = <Duration>[
    Duration(milliseconds: 350),
    Duration(milliseconds: 900),
  ];

  static Future<(int width, int height)?> _readImageDimensions(
    Uint8List bytes,
  ) async {
    final completer = Completer<(int width, int height)?>();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      try {
        completer.complete((image.width, image.height));
      } finally {
        image.dispose();
      }
    });
    return completer.future;
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

  String _hiddenUploadsKey(String uid) =>
      'mana_poster_hidden_user_uploads_v1::$uid';

  Query<Map<String, dynamic>> _uploadsQueryForUser(String uid) {
    return _firestore
        .collection('userPosterUploads')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
  }

  List<UserPosterUpload> _mapUploadDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return docs
        .map((doc) => UserPosterUpload.fromMap(doc.id, doc.data()))
        .where(
          (item) => item.expiresAtMillis <= 0 || item.expiresAtMillis > now,
        )
        .toList(growable: false);
  }

  Stream<List<UserPosterUpload>> watchCurrentUserUploads() {
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return const Stream<List<UserPosterUpload>>.empty();
    }
    return _uploadsQueryForUser(uid)
        .snapshots()
        .map((snapshot) => _mapUploadDocs(snapshot.docs))
        .asBroadcastStream();
  }

  Future<List<UserPosterUpload>> fetchCurrentUserUploads({
    bool forceServer = false,
  }) async {
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return const <UserPosterUpload>[];
    }
    final query = _uploadsQueryForUser(uid);
    for (
      var attempt = 0;
      attempt <= _transientReadRetryDelays.length;
      attempt++
    ) {
      try {
        final snapshot = await query.get(
          GetOptions(
            source: forceServer ? Source.server : Source.serverAndCache,
          ),
        );
        return _mapUploadDocs(snapshot.docs);
      } on FirebaseException catch (error) {
        final canRetry =
            _isTransientFirestoreReadError(error) &&
            attempt < _transientReadRetryDelays.length;
        if (canRetry) {
          await Future<void>.delayed(_transientReadRetryDelays[attempt]);
          continue;
        }
        if (forceServer && _isTransientFirestoreReadError(error)) {
          try {
            final cachedSnapshot = await query.get(
              const GetOptions(source: Source.cache),
            );
            return _mapUploadDocs(cachedSnapshot.docs);
          } on FirebaseException {
            rethrow;
          }
        }
        rethrow;
      }
    }
    return const <UserPosterUpload>[];
  }

  bool _isTransientFirestoreReadError(FirebaseException error) {
    final code = error.code.trim().toLowerCase();
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'aborted' ||
        code == 'resource-exhausted';
  }

  Future<Set<String>> hiddenUploadIdsForCurrentUser() async {
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return <String>{};
    }
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_hiddenUploadsKey(uid)) ?? const <String>[])
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<void> hideUploadFromCurrentUserList(String uploadId) async {
    final uid = _auth.currentUser?.uid.trim() ?? '';
    final safeUploadId = uploadId.trim();
    if (uid.isEmpty || safeUploadId.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _hiddenUploadsKey(uid);
    final hidden = (prefs.getStringList(key) ?? const <String>[])
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    hidden.add(safeUploadId);
    await prefs.setStringList(key, hidden.toList(growable: false));
  }

  static DateTime _istDateTime([DateTime? now]) {
    return IstTimeService.toIst(now ?? DateTime.now());
  }

  static int resolveApplicableFromMillis([DateTime? now]) {
    final istNow = _istDateTime(now);
    final sameDayStartUtc = DateTime.utc(
      istNow.year,
      istNow.month,
      istNow.day,
    ).subtract(IstTimeService.offset);
    if (istNow.hour >= _uploadCutoffHourIst) {
      return sameDayStartUtc.millisecondsSinceEpoch + IstTimeService.dayMillis;
    }
    return sameDayStartUtc.millisecondsSinceEpoch;
  }

  static String formatIstDateLabelFromMillis(int epochMillis) {
    if (epochMillis <= 0) {
      return '';
    }
    final istDate = DateTime.fromMillisecondsSinceEpoch(
      epochMillis,
      isUtc: true,
    ).add(IstTimeService.offset);
    final day = istDate.day.toString().padLeft(2, '0');
    final month = istDate.month.toString().padLeft(2, '0');
    final year = istDate.year.toString();
    return '$day-$month-$year';
  }

  Future<UserPosterUploadSubmitResult> submitUpload({
    required File? imageFile,
    required String quoteText,
    required String categoryId,
    required String categoryLabel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return UserPosterUploadSubmitResult.failure(
        UserPosterUploadSubmitCode.loginRequired,
      );
    }
    final safeCategoryId = categoryId.trim();
    final safeCategoryLabel = categoryLabel.trim();
    if (safeCategoryId.isEmpty || safeCategoryLabel.isEmpty) {
      return UserPosterUploadSubmitResult.failure(
        UserPosterUploadSubmitCode.categoryRequired,
      );
    }
    final safeQuoteText = quoteText.trim();
    if (imageFile == null && safeQuoteText.isEmpty) {
      return UserPosterUploadSubmitResult.failure(
        UserPosterUploadSubmitCode.contentRequired,
      );
    }
    if (safeQuoteText.length > maxQuoteLength) {
      return UserPosterUploadSubmitResult.failure(
        UserPosterUploadSubmitCode.quoteTooLong,
      );
    }
    final fileSize = imageFile == null ? 0 : await imageFile.length();
    if (fileSize > maxUploadBytes) {
      return UserPosterUploadSubmitResult.failure(
        UserPosterUploadSubmitCode.imageTooLarge,
      );
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final appVisibleFromAt = resolveApplicableFromMillis();
      final profile = await PosterProfileService.load();
      final imageBytes = imageFile == null
          ? null
          : await imageFile.readAsBytes();
      final imageDimensions = imageBytes == null
          ? null
          : await _readImageDimensions(imageBytes);
      final userName = profile.activeName.trim().isNotEmpty
          ? profile.activeName.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'User');
      final userMobile = profile.activeWhatsappNumber.trim();
      final doc = _firestore.collection('userPosterUploads').doc();
      var imagePath = '';
      var imageUrl = '';
      if (imageFile != null) {
        final imageExtension = _normalizedImageExtension(imageFile.path);
        imagePath =
            'users/${user.uid}/community_uploads/${doc.id}.$imageExtension';
        final imageRef = _storage.ref(imagePath);
        await imageRef.putFile(
          imageFile,
          SettableMetadata(
            contentType: _contentTypeForExtension(imageExtension),
          ),
        );
        imageUrl = await imageRef.getDownloadURL();
      }
      final submissionType = imageUrl.isNotEmpty && safeQuoteText.isNotEmpty
          ? 'image_quote'
          : imageUrl.isNotEmpty
          ? 'image'
          : 'quote';

      await doc.set(<String, dynamic>{
        'id': doc.id,
        'contributionKind': 'user_upload',
        'userId': user.uid,
        'userName': userName,
        'userEmail': (user.email ?? '').trim(),
        'userMobile': userMobile,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'quoteText': safeQuoteText,
        'submissionType': submissionType,
        'hasImage': imageUrl.isNotEmpty,
        'categoryId': safeCategoryId,
        'categoryLabel': safeCategoryLabel,
        'status': 'pending',
        'rejectionReason': '',
        'approvedPosterTemplateId': '',
        'shareCount': 0,
        'downloadCount': 0,
        'createdAt': now,
        'updatedAt': now,
        'expiresAt': now + retentionMillis,
        'appVisibleFromAt': appVisibleFromAt,
        'widthPx': imageDimensions?.$1 ?? 0,
        'heightPx': imageDimensions?.$2 ?? 0,
      });
      return UserPosterUploadSubmitResult.success();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('UserPosterUploadsService.submitUpload failed: $error');
      }
      return UserPosterUploadSubmitResult.failure(
        UserPosterUploadSubmitCode.uploadFailed,
      );
    }
  }

  Future<void> incrementApprovedContributionCountForPoster({
    required String approvedPosterTemplateId,
    required bool isShare,
  }) async {
    final posterId = approvedPosterTemplateId.trim();
    final uid = _auth.currentUser?.uid.trim() ?? '';
    if (posterId.isEmpty || uid.isEmpty) {
      return;
    }
    final field = isShare ? 'shareCount' : 'downloadCount';
    try {
      final snapshot = await _uploadsQueryForUser(
        uid,
      ).get(const GetOptions(source: Source.serverAndCache));
      QueryDocumentSnapshot<Map<String, dynamic>>? matchedDoc;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] as String?)?.trim().toLowerCase() ?? '';
        final approvedId =
            (data['approvedPosterTemplateId'] as String?)?.trim() ?? '';
        if (status == 'approved' && approvedId == posterId) {
          matchedDoc = doc;
          break;
        }
      }
      if (matchedDoc == null) {
        return;
      }
      await matchedDoc.reference.update(<String, dynamic>{
        field: FieldValue.increment(1),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (error) {
      if (kDebugMode || kProfileMode) {
        debugPrint(
          'UserPosterUploadsService.incrementApprovedContributionCountForPoster failed: $error',
        );
      }
      // Best-effort metrics update only.
    }
  }
}
