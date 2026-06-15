class CommunityStatus {
  const CommunityStatus({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.imageUrl,
    required this.imagePath,
    required this.text,
    required this.statusType,
    required this.regionId,
    required this.regionName,
    required this.religionPreference,
    required this.locationState,
    required this.locationDistrict,
    required this.locationCity,
    required this.backgroundColor,
    required this.createdAtMillis,
    required this.expiresAtMillis,
    required this.viewCount,
    required this.likeCount,
    required this.reactionCount,
    required this.viewerReaction,
    required this.viewerHasLiked,
  });

  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String imageUrl;
  final String imagePath;
  final String text;
  final String statusType;
  final String regionId;
  final String regionName;
  final String religionPreference;
  final String locationState;
  final String locationDistrict;
  final String locationCity;
  final int backgroundColor;
  final int createdAtMillis;
  final int expiresAtMillis;
  final int viewCount;
  final int likeCount;
  final int reactionCount;
  final String viewerReaction;
  final bool viewerHasLiked;

  bool get hasImage => imageUrl.isNotEmpty;
  bool get hasText => text.isNotEmpty;

  static String _readString(dynamic value) => (value ?? '').toString().trim();

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> readStatusMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  factory CommunityStatus.fromMap(
    String id,
    Map<String, dynamic> map, {
    String viewerUserId = '',
  }) {
    final viewsByUser = readStatusMap(map['viewsByUser']);
    final likesByUser = readStatusMap(map['likesByUser']);
    final reactionsByUser = readStatusMap(map['reactionsByUser']);
    final safeViewerUserId = viewerUserId.trim();
    final viewerReaction = safeViewerUserId.isEmpty
        ? ''
        : _readString(reactionsByUser[safeViewerUserId]);
    return CommunityStatus(
      id: id,
      userId: _readString(map['userId']),
      userName: _readString(map['userName']),
      userPhotoUrl: _readString(map['userPhotoUrl']),
      imageUrl: _readString(map['imageUrl']),
      imagePath: _readString(map['imagePath']),
      text: _readString(map['text']),
      statusType: _readString(map['statusType']),
      regionId: _readString(map['regionId']),
      regionName: _readString(map['regionName']),
      religionPreference: _readString(map['religionPreference']),
      locationState: _readString(map['locationState']),
      locationDistrict: _readString(map['locationDistrict']),
      locationCity: _readString(map['locationCity']),
      backgroundColor: _readInt(map['backgroundColor']),
      createdAtMillis: _readInt(map['createdAt']),
      expiresAtMillis: _readInt(map['expiresAt']),
      viewCount: _readInt(map['viewCount'] ?? viewsByUser.length),
      likeCount: _readInt(map['likeCount'] ?? likesByUser.length),
      reactionCount: _readInt(map['reactionCount'] ?? reactionsByUser.length),
      viewerReaction: viewerReaction,
      viewerHasLiked:
          safeViewerUserId.isNotEmpty && likesByUser[safeViewerUserId] == true,
    );
  }
}

class CommunityStatusComment {
  const CommunityStatusComment({
    required this.id,
    required this.statusId,
    required this.statusOwnerId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAtMillis,
  });

  final String id;
  final String statusId;
  final String statusOwnerId;
  final String userId;
  final String userName;
  final String text;
  final int createdAtMillis;

  static String _readString(dynamic value) => (value ?? '').toString().trim();

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory CommunityStatusComment.fromMap(String id, Map<String, dynamic> map) {
    return CommunityStatusComment(
      id: id,
      statusId: _readString(map['statusId']),
      statusOwnerId: _readString(map['statusOwnerId']),
      userId: _readString(map['userId']),
      userName: _readString(map['userName']),
      text: _readString(map['text']),
      createdAtMillis: _readInt(map['createdAt']),
    );
  }
}
