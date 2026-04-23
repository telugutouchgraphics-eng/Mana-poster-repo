# Mana Poster Backend Handoff Architecture Summary

This is a concise handoff overview for the current Mana Poster landing page and admin dashboard backend.

## Main Flow

```text
Firebase Auth
  -> Admin custom claim check
  -> Admin dashboard
  -> Local draft editor state
  -> Save Draft to Firestore
  -> Publish to public Firestore document
  -> Public landing reads published document
  -> Versions support restore to draft
  -> Audit logs record key admin actions
```

## Important Files

- Backend paths/constants: `lib/features/admin/data/admin_backend_paths.dart`
- Backend content models: `lib/features/admin/data/models/backend_content_models.dart`
- Admin-to-backend mapper: `lib/features/admin/data/mappers/admin_backend_content_mapper.dart`
- Draft/publish/version repository: `lib/features/admin/data/repositories/firestore_landing_content_repository.dart`
- Media repository: `lib/features/admin/data/repositories/firestore_media_repository.dart`
- Audit repository: `lib/features/admin/data/repositories/firestore_admin_audit_log_repository.dart`
- Auth service: `lib/features/admin/data/services/firebase_admin_auth_service.dart`
- Draft coordinator: `lib/features/admin/data/services/admin_draft_persistence_coordinator.dart`
- Media coordinator: `lib/features/admin/data/services/admin_media_library_coordinator.dart`
- Public published read service: `lib/features/prehome/services/public_published_landing_service.dart`

## Firestore Collections

- `landingDrafts/main`: current editable admin draft
- `landingPublished/main`: public published landing content
- `landingVersions/{versionId}`: publish snapshots
- `mediaLibrary/{mediaId}`: media metadata
- `adminAuditLogs/{logId}`: admin activity history

## Storage Paths

- `landing-media/{mediaId}/{filename}`: landing/admin media assets

## Security Model

- Public landing content is readable publicly from `landingPublished/main`.
- Published media under `landing-media/*` is publicly readable.
- Admin writes require Firebase custom claim `admin: true`.
- Admin dashboard route checks the same claim before rendering the dashboard.

## Fallback Behavior

- Admin draft load failure keeps local fallback draft usable.
- Public published read failure falls back to local landing seed content.
- Audit logging is best-effort and never blocks primary actions.

## Handoff Notes

- Deploy rules before testing backend features.
- Assign admin custom claims before expecting dashboard access.
- Replace remaining support/app/legal links before public release.
- Run controlled staging QA before production rollout.
