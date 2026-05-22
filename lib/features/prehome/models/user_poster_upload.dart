class UserPosterUpload {
  const UserPosterUpload({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    required this.imageUrl,
    required this.imagePath,
    required this.categoryId,
    required this.categoryLabel,
    required this.status,
    required this.rejectionReason,
    required this.approvedPosterTemplateId,
    required this.shareCount,
    required this.downloadCount,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.expiresAtMillis,
    required this.appVisibleFromMillis,
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userMobile;
  final String imageUrl;
  final String imagePath;
  final String categoryId;
  final String categoryLabel;
  final String status;
  final String rejectionReason;
  final String approvedPosterTemplateId;
  final int shareCount;
  final int downloadCount;
  final int createdAtMillis;
  final int updatedAtMillis;
  final int expiresAtMillis;
  final int appVisibleFromMillis;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value) => (value ?? '').toString().trim();

  factory UserPosterUpload.fromMap(String id, Map<String, dynamic> map) {
    return UserPosterUpload(
      id: id,
      userId: _readString(map['userId']),
      userName: _readString(map['userName']),
      userEmail: _readString(map['userEmail']),
      userMobile: _readString(map['userMobile']),
      imageUrl: _readString(map['imageUrl']),
      imagePath: _readString(map['imagePath']),
      categoryId: _readString(map['categoryId']),
      categoryLabel: _readString(map['categoryLabel']),
      status: _readString(map['status']),
      rejectionReason: _readString(map['rejectionReason']),
      approvedPosterTemplateId: _readString(map['approvedPosterTemplateId']),
      shareCount: _readInt(map['shareCount']),
      downloadCount: _readInt(map['downloadCount']),
      createdAtMillis: _readInt(map['createdAt']),
      updatedAtMillis: _readInt(map['updatedAt']),
      expiresAtMillis: _readInt(map['expiresAt']),
      appVisibleFromMillis: _readInt(map['appVisibleFromAt']),
    );
  }
}
