import 'package:firebase_auth/firebase_auth.dart';

import 'package:mana_poster/features/admin/data/models/admin_audit_log.dart';
import 'package:mana_poster/features/admin/data/repositories/admin_audit_log_repository.dart';
import 'package:mana_poster/features/admin/data/repositories/firestore_admin_audit_log_repository.dart';

class AdminAuditLogService {
  AdminAuditLogService({AdminAuditLogRepository? repository})
    : _repository = repository ?? FirestoreAdminAuditLogRepository();

  static final AdminAuditLogService instance = AdminAuditLogService();

  final AdminAuditLogRepository _repository;

  Future<void> writeBestEffort({
    required String actionType,
    required String entityType,
    required String entityId,
    required String message,
    required String summary,
    required String status,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String? actorUserId,
    String? actorEmail,
    String? targetVersionId,
    String? targetMediaId,
    String? targetDraftId,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      await _repository.writeLog(
        AdminAuditLog(
          logId: '',
          actionType: actionType,
          entityType: entityType,
          entityId: entityId,
          message: message,
          summary: summary,
          actorUserId: actorUserId ?? user?.uid ?? '',
          actorEmail: actorEmail ?? user?.email ?? '',
          createdAt: DateTime.now().toUtc(),
          status: status,
          metadata: metadata,
          targetVersionId: targetVersionId,
          targetMediaId: targetMediaId,
          targetDraftId: targetDraftId,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block admin actions.
    }
  }

  Future<void> success({
    required String actionType,
    required String entityType,
    required String entityId,
    required String message,
    required String summary,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String? targetVersionId,
    String? targetMediaId,
    String? targetDraftId,
  }) {
    return writeBestEffort(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      message: message,
      summary: summary,
      status: AdminAuditStatus.success,
      metadata: metadata,
      targetVersionId: targetVersionId,
      targetMediaId: targetMediaId,
      targetDraftId: targetDraftId,
    );
  }

  Future<void> failure({
    required String actionType,
    required String entityType,
    required String entityId,
    required String message,
    required String summary,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String? targetVersionId,
    String? targetMediaId,
    String? targetDraftId,
  }) {
    return writeBestEffort(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      message: message,
      summary: summary,
      status: AdminAuditStatus.failed,
      metadata: metadata,
      targetVersionId: targetVersionId,
      targetMediaId: targetMediaId,
      targetDraftId: targetDraftId,
    );
  }

  Future<List<AdminAuditLog>> listLogs({
    int limit = 50,
    List<String> actionTypes = const <String>[],
  }) {
    return _repository.listLogs(limit: limit, actionTypes: actionTypes);
  }

  Future<List<AdminAuditLog>> listRecentLogs({int limit = 20}) {
    return _repository.listRecentLogs(limit: limit);
  }
}
