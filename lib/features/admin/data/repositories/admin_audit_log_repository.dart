import 'package:mana_poster/features/admin/data/models/admin_audit_log.dart';

abstract class AdminAuditLogRepository {
  Future<AdminAuditLog> writeLog(AdminAuditLog log);

  Future<List<AdminAuditLog>> listLogs({
    int limit = 50,
    List<String> actionTypes = const <String>[],
  });

  Future<List<AdminAuditLog>> listRecentLogs({int limit = 20});
}
