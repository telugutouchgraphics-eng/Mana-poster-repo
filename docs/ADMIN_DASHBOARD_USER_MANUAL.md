# Mana Poster Admin Dashboard User Manual

## Purpose

The current admin dashboard is a frontend-only content control panel for the Mana Poster landing page. It is designed for local editing, previewing, review demos, and backend handoff preparation.

It does **not** save to a server yet.

## Current Admin Sections

### Overview

Use this screen to quickly review template counts, section status, and shortcuts into editing flows.

### Landing Page

Use this panel to:

- enable or disable landing sections
- reorder visible sections
- open preview
- reset the local draft

This controls section order and visibility for preview mode.

### Hero Section

Use this panel to edit:

- badge text
- main heading
- subheading
- CTA labels
- trust bullets
- hero screenshot references

Changes appear immediately in preview mode.

### Features

Use this panel to manage feature cards:

- title
- description
- icon key
- add/remove
- reorder

### Categories

Use this panel to manage landing category cards:

- title
- subtitle
- badge text
- add/remove
- reorder

### Showcase Posters

Use this panel to manage showcase gallery entries:

- poster title
- subtitle
- category tag
- free or premium label
- image asset path
- add/remove
- reorder

### FAQ

Use this panel to manage question and answer items:

- question
- answer
- add/remove
- reorder

### Footer / Contact

Use this panel to edit:

- footer description
- support values
- privacy/terms/download references
- quick links

### Media Library

Use this panel for local asset metadata management:

- media item title
- asset path
- type
- search/filter
- quick copy path

This is metadata-only right now. No upload integration exists yet.

### App Links

Use this panel to manage:

- Play Store URL
- Watch Demo URL
- Privacy Policy URL
- Terms URL
- Support email
- Support phone
- WhatsApp link
- canonical website URL

### Settings

Use this panel to manage local configuration such as:

- brand/app name
- short tagline
- accent theme
- support visibility
- compact card preference
- preview animation preference

## How Local Draft Editing Works

All admin edits currently live in local in-memory state inside the dashboard session.

That means:

- changes are visible immediately in dashboard panels
- preview reflects current draft values
- refresh or restart can reset local state
- there is no backend persistence yet

## How Preview Works

Preview mode opens a cleaner full-screen landing preview without admin clutter.

Preview currently supports:

- Hero
- Features
- Categories
- How It Works
- Showcase
- FAQ
- Footer
- app links
- settings-driven brand/accent details
- section order and visibility

Preview controls include:

- `Back to Editor`
- device mode toggle: desktop, tablet, mobile
- `Refresh`
- `Open Section`

## What Publish Means Right Now

`Publish` is a local simulation only.

It currently:

- opens a confirmation dialog
- shows changed sections and change notes
- marks the local workflow state as published
- clears pending local change summary

It does **not**:

- deploy anything
- write to a backend
- update the public website

## What Is Still Simulated

The following areas remain simulated or local-only:

- save draft persistence
- publish persistence
- live server preview
- media upload
- auth
- role control
- analytics
- audit history
- remote content fetch

## Values To Replace Before Real Launch

Review and finalize:

- support email
- support phone
- Play Store URL
- demo URL
- WhatsApp/contact URL
- privacy policy URL
- terms URL
- canonical website URL
- real hero screenshots
- real showcase assets

## Where Content, Assets, and Links Are Configured

Main admin draft models:

- `lib/features/admin/models/admin_content_models.dart`

Preview mapping layer:

- `lib/features/admin/mappers/admin_landing_preview_mapper.dart`

Preview models:

- `lib/features/admin/models/admin_landing_preview_models.dart`

Main dashboard screen/state owner:

- `lib/features/admin/screens/admin_dashboard_screen.dart`

Preview screen:

- `lib/features/admin/screens/admin_landing_preview_screen.dart`

Preview UI widgets:

- `lib/features/admin/widgets/admin_landing_live_preview.dart`
- `lib/features/admin/widgets/admin_preview_toolbar.dart`

Public landing widgets:

- `lib/features/prehome/screens/web_landing_screen.dart`
- `lib/features/prehome/widgets/landing/`

## Recommended Local Workflow

1. Open the admin dashboard.
2. Edit one section at a time.
3. Watch the change summary update.
4. Open preview and verify desktop/tablet/mobile modes.
5. Save draft locally when the content looks stable.
6. Use publish simulation only as a workflow checkpoint, not as a real deployment step.

## Before Backend Work

Backend integration should later connect:

- draft fetch/save
- publish API
- media upload pipeline
- auth and admin access
- deployment status
- content version history
