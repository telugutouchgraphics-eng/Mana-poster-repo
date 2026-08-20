import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class QuizPrizeDetailsData {
  const QuizPrizeDetailsData({
    required this.uid,
    required this.name,
    required this.email,
    required this.stateId,
    required this.stateName,
    required this.photoUrl,
    required this.whatsappNumber,
    required this.bankAccountName,
    required this.bankAccountNumber,
    required this.bankIfscCode,
    required this.consentAccepted,
  });

  final String uid;
  final String name;
  final String email;
  final String stateId;
  final String stateName;
  final String photoUrl;
  final String whatsappNumber;
  final String bankAccountName;
  final String bankAccountNumber;
  final String bankIfscCode;
  final bool consentAccepted;

  bool get isComplete {
    return consentAccepted &&
        whatsappNumber.trim().isNotEmpty &&
        bankAccountName.trim().isNotEmpty &&
        bankAccountNumber.trim().isNotEmpty &&
        bankIfscCode.trim().isNotEmpty;
  }

  QuizPrizeDetailsData copyWith({
    String? uid,
    String? name,
    String? email,
    String? stateId,
    String? stateName,
    String? photoUrl,
    String? whatsappNumber,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankIfscCode,
    bool? consentAccepted,
  }) {
    return QuizPrizeDetailsData(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      photoUrl: photoUrl ?? this.photoUrl,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfscCode: bankIfscCode ?? this.bankIfscCode,
      consentAccepted: consentAccepted ?? this.consentAccepted,
    );
  }

  factory QuizPrizeDetailsData.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return QuizPrizeDetailsData(
      uid: (data['uid'] ?? snapshot.id).toString(),
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      stateId: (data['stateId'] ?? '').toString(),
      stateName: (data['stateName'] ?? '').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      whatsappNumber: (data['whatsappNumber'] ?? '').toString(),
      bankAccountName: (data['bankAccountName'] ?? '').toString(),
      bankAccountNumber: (data['bankAccountNumber'] ?? '').toString(),
      bankIfscCode: (data['bankIfscCode'] ?? '').toString(),
      consentAccepted: data['consentAccepted'] == true,
    );
  }
}

class QuizPrizeDetailsService {
  QuizPrizeDetailsService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const String consentVersion = 'quiz_prize_v1';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('quizPrizeProfiles');
  }

  Future<QuizPrizeDetailsData?> load() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }
    final snapshot = await _collection.doc(user.uid).get();
    if (!snapshot.exists) {
      return null;
    }
    return QuizPrizeDetailsData.fromSnapshot(snapshot);
  }

  Future<bool> hasCompleteDetails() async {
    final details = await load();
    return details?.isComplete == true;
  }

  Future<QuizPrizeDetailsData> buildDefault(AppLanguage language) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Please login again to save prize details.');
    }
    final region = await AppRegionService.loadSelection();
    final profile = await PosterProfileService.load();
    final saved = await load();
    final name = profile.translatedName(language: language).trim();
    final photoUrl = profile.photoUrl.trim().isNotEmpty
        ? profile.photoUrl.trim()
        : profile.originalPhotoUrl.trim();
    return QuizPrizeDetailsData(
      uid: user.uid,
      name: name.isNotEmpty ? name : user.displayName ?? '',
      email: user.email ?? '',
      stateId: saved?.stateId.trim().isNotEmpty == true
          ? saved!.stateId
          : region?.id ?? AppRegionService.fallbackRegionId,
      stateName: saved?.stateName.trim().isNotEmpty == true
          ? saved!.stateName
          : (region ?? appRegionById(AppRegionService.fallbackRegionId))
                    ?.name ??
                '',
      photoUrl: photoUrl.isNotEmpty ? photoUrl : user.photoURL ?? '',
      whatsappNumber: saved?.whatsappNumber ?? profile.activeWhatsappNumber,
      bankAccountName: saved?.bankAccountName ?? '',
      bankAccountNumber: saved?.bankAccountNumber ?? '',
      bankIfscCode: saved?.bankIfscCode ?? '',
      consentAccepted: saved?.consentAccepted ?? false,
    );
  }

  Future<void> save({
    required String whatsappNumber,
    required String bankAccountName,
    required String bankAccountNumber,
    required String bankIfscCode,
    required AppLanguage language,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Please login again to save prize details.');
    }
    final base = await buildDefault(language);
    await _collection.doc(user.uid).set(<String, dynamic>{
      'uid': user.uid,
      'name': base.name,
      'email': base.email,
      'stateId': base.stateId,
      'stateName': base.stateName,
      'photoUrl': base.photoUrl,
      'whatsappNumber': whatsappNumber.trim(),
      'upiIdOrNumber': FieldValue.delete(),
      'bankAccountName': bankAccountName.trim(),
      'bankAccountNumber': bankAccountNumber.trim(),
      'bankIfscCode': bankIfscCode.trim().toUpperCase(),
      'consentAccepted': true,
      'consentVersion': consentVersion,
      'source': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
