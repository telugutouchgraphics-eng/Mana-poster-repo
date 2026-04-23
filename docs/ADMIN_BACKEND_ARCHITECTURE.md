# Mana Poster Admin Backend Architecture

## Scope

This document defines the backend architecture for the current Mana Poster landing page and admin dashboard.

The system now uses Firebase-backed admin auth, draft persistence, publish flow, media library, version history, public published reads, and audit logging using:

- Firebase Auth
- Cloud Firestore
- Firebase Storage
- optional Cloud Functions

## Goals

The backend should later support:

- admin login
- draft save
- publish landing content
- media upload and media metadata management
- version history
- future template/category/event/user/payment management

## Recommended Firebase Structure

### Core Collections

#### `landingDrafts`

One document per editable landing draft.

Recommended document shape:

```text
landingDrafts/{draftId}
  id
  version
  createdAt
  updatedAt
  createdByUserId
  updatedByUserId
  sections[]
  hero{}
  features[]
  categories[]
  showcaseItems[]
  faqItems[]
  footer{}
  appLinks{}
  settings{}
  mediaItems[]
```

Recommended approach:

- keep one active draft document for the current site
- allow future multi-draft support by adding status fields like `active`, `archived`, `published_source`

#### `landingPublished`

Published landing content snapshot used by the public site.

Recommended document shape:

```text
landingPublished/current
  id
  sourceDraftId
  version
  publishedAt
  createdAt
  updatedAt
  sections[]
  hero{}
  features[]
  categories[]
  showcaseItems[]
  faqItems[]
  footer{}
  appLinks{}
  settings{}
  mediaItems[]
```

This keeps public reads simple and fast.

#### `landingVersions`

Version history snapshots.

Recommended structure:

```text
landingVersions/{versionId}
  version
  sourceDraftId
  publishedAt
  publishedByUserId
  changeNote
  fullPublishedPayload{}
```

This allows rollback, audit review, and future publish history UI.

#### `mediaLibrary`

Metadata for uploaded assets.

Recommended structure:

```text
mediaLibrary/{mediaId}
  id
  name
  assetPath
  storagePath
  downloadUrl
  type
  width
  height
  createdAt
  updatedAt
  uploadedByUserId
```

In the current frontend, `assetPath` is local. Later this should map to Firebase Storage metadata.

#### `adminAuditLogs`

Admin activity history for important backend-connected actions.

Recommended document shape:

```text
adminAuditLogs/{logId}
  logId
  actionType
  entityType
  entityId
  message
  summary
  actorUserId
  actorEmail
  createdAt
  status
  metadata{}
```

Audit logging is best-effort and must not block primary admin actions.

#### `adminSettings`

Recommended split:

```text
adminSettings/appLinks
adminSettings/siteSettings
```

This keeps high-frequency landing content separate from lower-frequency settings.

## Firebase Storage Structure

Current landing media path:

```text
landing-media/{mediaId}/{filename}
```

Future app-wide buckets/folders may include:

```text
landing/hero/
landing/showcase/
landing/icons/
landing/footer/
landing/misc/
templates/
events/
```

Each file should also have a matching Firestore media document in `mediaLibrary`.

## Mapping From Current Local Models

Current local draft source:

- `lib/features/admin/models/admin_content_models.dart`

Backend-ready models:

- `lib/features/admin/data/models/backend_content_models.dart`

Mapper:

- `lib/features/admin/data/mappers/admin_backend_content_mapper.dart`

Mapping strategy:

- `AdminLandingDraft` -> `LandingDraft`
- `HeroContentDraft` -> `HeroContent`
- `FeatureDraft` -> `FeatureItem`
- `CategoryDraft` -> `CategoryItem`
- `ShowcasePosterDraft` -> `ShowcaseItem`
- `FaqDraft` -> `FAQItem`
- `FooterContentDraft` -> `FooterContent`
- `AppLinksDraft` -> `AppLinks`
- `AdminSettingsDraft` -> `Settings`
- `MediaItemDraft` -> `MediaItem`

This keeps current preview and admin editing flows intact while making future repository integration clean.

## Draft vs Published Approach

Recommended behavior:

1. Admin loads active draft from `landingDrafts`.
2. Admin edits locally in UI state.
3. Save Draft writes only to `landingDrafts`.
4. Publish copies active draft into `landingPublished/current`.
5. Publish also writes a snapshot into `landingVersions/{versionId}`.

Benefits:

- safe preview and editing without affecting public site
- clean separation between edit state and public state
- easy version history support

## Media Library Structure

Current frontend media panel connects to:

- Firestore metadata in `mediaLibrary`
- binary assets in Firebase Storage

Current lifecycle:

1. upload file to Storage
2. create metadata document in Firestore
3. bind selected `mediaId` or storage path into draft content
4. resolve URLs for preview/public rendering

## App Links and Settings

Recommended storage:

- `adminSettings/appLinks`
- `adminSettings/siteSettings`

These documents are stable and should not be mixed into operational data like users or payments.

## Version History Idea

Recommended version metadata:

- `version`
- `sourceDraftId`
- `publishedAt`
- `publishedByUserId`
- `changeNote`
- full published snapshot

This supports:

- rollback
- audit trail
- publish notes
- stakeholder review history

## Future Scalability

### Templates

Recommended collection:

```text
templates/{templateId}
```

Fields may include:

- categoryId
- title
- premium/free
- thumbnail
- editor document payload
- publish state

### Dynamic Events

Recommended collection:

```text
dynamicEvents/{eventId}
```

Fields may include:

- name
- date
- region
- category
- active flag
- linked templates

### Users

Recommended collection:

```text
users/{userId}
```

Fields may include:

- role
- name
- email
- access status
- lastLoginAt

### Payments

Recommended collection:

```text
payments/{paymentId}
```

This should remain separate from landing CMS content.

## Recommended Repository Layer

Repository contracts and Firebase implementations are prepared:

- `LandingContentRepository`
- `MediaRepository`
- `SettingsRepository`

Collection and storage path constants are centralized in:

- `lib/features/admin/data/admin_backend_paths.dart`

## Suggested Implementation Sequence

## Current Implemented Status

Implemented:

- Firebase initialization
- admin login
- admin-only custom claim gate
- Firestore draft load/save
- Firestore publish to `landingPublished/main`
- public landing read from published content with fallback
- Firebase Storage media upload/delete
- version snapshot creation and restore to draft
- best-effort audit logging

Still future-phase:

- multi-role permissions
- app template/category/event backend CRUD
- approval workflows
- analytics/reporting
- advanced audit search/export
