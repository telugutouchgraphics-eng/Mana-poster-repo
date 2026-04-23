import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mana_poster/features/admin/data/admin_backend_paths.dart';
import 'package:mana_poster/features/admin/data/models/admin_audit_log.dart';
import 'package:mana_poster/features/admin/data/repositories/admin_audit_log_repository.dart';

class FirestoreAdminAuditLogRepository implements AdminAuditLogRepository {
  FirestoreAdminAuditLogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String auditLogsCollection =
      AdminBackendPaths.adminAuditLogsCollection;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection(auditLogsCollection);

  @override
  Future<AdminAuditLog> writeLog(AdminAuditLog log) async {
    _ensureFirebaseConfigured();
    try {
      final DocumentReference<Map<String, dynamic>> ref = log.logId.isEmpty
          ? _logs.doc()
          : _logs.doc(log.logId);
      final AdminAuditLog logToStore = log.copyWith(logId: ref.id);
      await ref.set(logToStore.toJson(), SetOptions(merge: false));
      return logToStore;
    } on FirebaseException catch (error) {
      throw AdminAuditLogException(_messageForError(error));
    } catch (_) {
      throw const AdminAuditLogException('Unable to write audit log.');
    }
  }

  @override
  Future<List<AdminAuditLog>> listLogs({
    int limit = 50,
    List<String> actionTypes = const <String>[],
  }) async {
    _ensureFirebaseConfigured();
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _logs
          .orderBy('createdAt', descending: true)
          .limit(limit.clamp(1, 100))
          .get();
      final Set<String> allowedTypes = actionTypes
          .where((String item) => item.trim().isNotEmpty)
          .toSet();
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                _decodeLog(doc.id, doc.data()),
          )
          .where(
            (AdminAuditLog log) =>
                allowedTypes.isEmpty || allowedTypes.contains(log.actionType),
          )
          .toList();
    } on FirebaseException catch (error) {
      throw AdminAuditLogException(_messageForError(error));
    } catch (_) {
      throw const AdminAuditLogException('Unable to load activity history.');
    }
  }

  @override
  Future<List<AdminAuditLog>> listRecentLogs({int limit = 20}) {
    return listLogs(limit: limit);
  }

  AdminAuditLog _decodeLog(String id, Map<String, dynamic> data) {
    final Map<String, dynamic> normalized = _normalizeMap(data);
    normalized['logId'] = id;
    return AdminAuditLog.fromJson(normalized);
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> source) {
    final Map<String, dynamic> output = <String, dynamic>{};
    source.forEach((String key, dynamic value) {
      output[key] = _normalizeValue(value);
    });
    return output;
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map<dynamic, dynamic>) {
      return value.map(
        (dynamic key, dynamic innerValue) => MapEntry<String, dynamic>(
          key.toString(),
          _normalizeValue(innerValue),
        ),
      );
    }
    if (value is List<dynamic>) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  void _ensureFirebaseConfigured() {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    throw const AdminAuditLogException('Firebase is not configured.');
  }

  String _messageForError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to access admin activity logs.';
      case 'unavailable':
        return 'Activity history is temporarily unavailable.';
      case 'failed-precondition':
        return 'Firestore needs an index or rules update for activity history.';
      default:
        return 'Activity history request failed (${error.code}).';
    }
  }
}

class AdminAuditLogException implements Exception {
  const AdminAuditLogException(this.message);

  final String message;

  @override
  String toString() => message;
}
