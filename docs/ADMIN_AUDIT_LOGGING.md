# Mana Poster Admin Audit Logging

The admin dashboard now writes lightweight audit records for important backend-connected actions.

## Storage Location

Audit logs are stored in Firestore:

```text
adminAuditLogs/{logId}
```

The collection is admin-only. Public users cannot read or write activity history.

## Logged Actions

Current action types include:

- `draft_saved`
- `published`
- `version_restored`
- `media_uploaded`
- `media_deleted`
- `media_updated`
- `login_success`
- `logout`
- `publish_failed`
- `save_failed`
- `restore_failed`
- `upload_failed`
- `delete_failed`

Each log can include:

- action type
- entity type and entity id
- success or failed status
- short summary and message
- actor user id and email when available
- created timestamp
- small metadata map
- optional related draft, media, or version ids

## Best-Effort Behavior

Audit logging is intentionally best-effort:

- A failed log write never blocks draft save, publish, restore, media upload, media delete, login, or logout.
- The dashboard continues to work if Firestore audit logging is temporarily unavailable.
- Failed action logs are attempted from the same error handling path that shows admin feedback.

## Activity History UI

The admin dashboard includes an `Activity History` section with:

- recent activity list
- success/failed badges
- actor and timestamp
- filters for All, Saves, Publish, Media, Restore, and Auth
- refresh action
- detail dialog with metadata and related ids

## What Is Not Logged Yet

- Deep field-level diffs.
- Immutable/tamper-proof audit retention.
- Exportable audit reports.
- Advanced search.
- Notification alerts.
- Template/event/user/payment management actions.

## Rules Requirement

Deploy Firestore rules after this feature:

```bash
firebase deploy --only firestore:rules
```

Rules should keep `adminAuditLogs/*` limited to users with the Firebase custom claim:

```json
{
  "admin": true
}
```
