class AdminAuditActionType {
  const AdminAuditActionType._();

  static const String draftSaved = 'draft_saved';
  static const String published = 'published';
  static const String versionRestored = 'version_restored';
  static const String mediaUploaded = 'media_uploaded';
  static const String mediaDeleted = 'media_deleted';
  static const String mediaUpdated = 'media_updated';
  static const String loginSuccess = 'login_success';
  static const String logout = 'logout';
  static const String publishFailed = 'publish_failed';
  static const String saveFailed = 'save_failed';
  static const String restoreFailed = 'restore_failed';
  static const String uploadFailed = 'upload_failed';
  static const String deleteFailed = 'delete_failed';
}

class AdminAuditStatus {
  const AdminAuditStatus._();

  static const String success = 'success';
  static const String failed = 'failed';
}

class AdminAuditEntityType {
  const AdminAuditEntityType._();

  static const String draft = 'draft';
  static const String publishedLanding = 'published_landing';
  static const String version = 'version';
  static const String media = 'media';
  static const String auth = 'auth';
}

class AdminAuditLog {
  const AdminAuditLog({
    required this.logId,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.summary,
    required this.actorUserId,
    required this.actorEmail,
    required this.createdAt,
    required this.status,
    this.metadata = const <String, dynamic>{},
    this.targetVersionId,
    this.targetMediaId,
    this.targetDraftId,
  });

  final String logId;
  final String actionType;
  final String entityType;
  final String entityId;
  final String message;
  final String summary;
  final String actorUserId;
  final String actorEmail;
  final DateTime createdAt;
  final String status;
  final Map<String, dynamic> metadata;
  final String? targetVersionId;
  final String? targetMediaId;
  final String? targetDraftId;

  AdminAuditLog copyWith({
    String? logId,
    String? actionType,
    String? entityType,
    String? entityId,
    String? message,
    String? summary,
    String? actorUserId,
    String? actorEmail,
    DateTime? createdAt,
    String? status,
    Map<String, dynamic>? metadata,
    String? targetVersionId,
    String? targetMediaId,
    String? targetDraftId,
  }) {
    return AdminAuditLog(
      logId: logId ?? this.logId,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      message: message ?? this.message,
      summary: summary ?? this.summary,
      actorUserId: actorUserId ?? this.actorUserId,
      actorEmail: actorEmail ?? this.actorEmail,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      targetVersionId: targetVersionId ?? this.targetVersionId,
      targetMediaId: targetMediaId ?? this.targetMediaId,
      targetDraftId: targetDraftId ?? this.targetDraftId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'logId': logId,
      'actionType': actionType,
      'entityType': entityType,
      'entityId': entityId,
      'message': message,
      'summary': summary,
      'actorUserId': actorUserId,
      'actorEmail': actorEmail,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'status': status,
      'metadata': metadata,
      'targetVersionId': targetVersionId,
      'targetMediaId': targetMediaId,
      'targetDraftId': targetDraftId,
    };
  }

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      logId: json['logId'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      actorUserId: json['actorUserId'] as String? ?? '',
      actorEmail: json['actorEmail'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: json['status'] as String? ?? AdminAuditStatus.success,
      metadata: _readMetadata(json['metadata']),
      targetVersionId: json['targetVersionId'] as String?,
      targetMediaId: json['targetMediaId'] as String?,
      targetDraftId: json['targetDraftId'] as String?,
    );
  }

  static Map<String, dynamic> _readMetadata(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map<dynamic, dynamic>) {
      return value.map(
        (dynamic key, dynamic innerValue) =>
            MapEntry<String, dynamic>(key.toString(), innerValue),
      );
    }
    return const <String, dynamic>{};
  }
}
