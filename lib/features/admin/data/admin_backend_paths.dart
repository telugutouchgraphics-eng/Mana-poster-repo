class AdminBackendPaths {
  const AdminBackendPaths._();

  static const String mainLandingDocumentId = 'main';

  static const String landingDraftsCollection = 'landingDrafts';
  static const String landingPublishedCollection = 'landingPublished';
  static const String landingVersionsCollection = 'landingVersions';
  static const String mediaLibraryCollection = 'mediaLibrary';
  static const String adminAuditLogsCollection = 'adminAuditLogs';

  static const String landingMediaStorageRoot = 'landing-media';

  static String landingMediaObjectPath({
    required String mediaId,
    required String fileName,
  }) {
    return '$landingMediaStorageRoot/$mediaId/$fileName';
  }
}
