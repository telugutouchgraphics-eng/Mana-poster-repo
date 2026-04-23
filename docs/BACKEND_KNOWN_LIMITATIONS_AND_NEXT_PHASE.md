# Backend Known Limitations And Next Phase

This document lists current backend limitations after the landing/admin Firebase integration pass.

## Current Limitations

- No multi-role permission system. Access is currently admin-only using Firebase custom claim `admin: true`.
- No editor/reviewer/publisher workflow.
- No granular section permissions.
- No autosave history timeline.
- No real-time collaboration.
- No template/category/event backend CRUD for the Android app content catalog.
- No user management dashboard beyond Firebase Auth users.
- No payments dashboard integration.
- No analytics or reporting dashboard.
- No advanced audit export, retention policy, or search.
- No immutable/tamper-proof audit log design.
- No bulk media upload/delete workflow.
- No dashboard image cropping or optimization workflow.
- No CDN/image optimization strategy beyond Firebase Storage download URLs.
- No offline admin support.
- No Cloud Functions automation for claims, publish validation, cleanup, or audit enforcement.
- No formal backup/restore automation for Firestore collections.

## Recommended Next-Phase Order

1. Backend hardening pass:
   - introduce Cloud Functions for admin role assignment
   - move sensitive admin operations that need stronger validation behind callable functions
   - add structured operational logging

2. Template/category/event backend:
   - build Firestore models for app templates
   - build category/event CRUD
   - connect Android app content feed to managed backend data

3. Media improvements:
   - add bulk upload
   - add image dimension extraction
   - add thumbnail generation
   - add stale media cleanup

4. Audit and operations:
   - add audit search/export
   - define retention policy
   - add activity filters by actor/entity/date

5. Workflow and permissions:
   - add roles such as editor, publisher, reviewer
   - add publish approval flow
   - add section-level permission rules if needed

6. Analytics:
   - add landing CTA analytics
   - add admin operation metrics
   - add app template usage/reporting later

7. Production reliability:
   - define Firestore backup process
   - add monitoring alerts
   - document incident rollback steps

## Current Production Position

The current backend is suitable for staging, stakeholder review, and controlled production rollout of the landing/admin CMS after Firebase project setup, rules deployment, domain setup, and real content QA are completed.

It is not yet a full enterprise CMS or app-wide content operations backend.
