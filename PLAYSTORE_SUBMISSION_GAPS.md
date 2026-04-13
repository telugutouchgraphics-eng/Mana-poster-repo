# PLAYSTORE SUBMISSION GAPS

## Store listing
| Item name | Why it matters | Current status | Who should fill it |
|---|---|---|---|
| Final app category selection | Mandatory Play listing field and discoverability | `MISSING` (suggested `Art & Design` only) | business |
| Content rating questionnaire submission | Required for test track approval and correct age rating | `MISSING` | business |

## App access / reviewer access
| Item name | Why it matters | Current status | Who should fill it |
|---|---|---|---|
| Reviewer access credentials decision | Reviewer must be able to enter app and test core flow | App supports Google + email login; demo account marked `<FILL_ME>` | developer + business |
| Demo email/password (if needed) | Required if reviewer cannot self-sign up/login | `MISSING` placeholders in reviewer doc | manual |
| OTP/login special note (if needed) | Prevents reviewer block if auth environment has restrictions | `MISSING` placeholder | developer |

## Privacy / legal
| Item name | Why it matters | Current status | Who should fill it |
|---|---|---|---|
| Privacy policy URL | Mandatory for Play and user transparency | `MISSING` | business |
| Support email | Required contact point in store/reviewer context | `MISSING` | business |
| Account/data deletion policy confirmation | Needed for policy compliance and Data Safety accuracy | `NEEDS CONFIRMATION` | business + manual |
| Final legal interpretation of “data shared” | Critical for correct Data Safety declaration | `NEEDS CONFIRMATION` | business + manual |

## Permissions
| Item name | Why it matters | Current status | Who should fill it |
|---|---|---|---|
| Legacy storage permission strategy (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`) | Medium Play review risk; may trigger scrutiny | Marked `REPLACE`/`REMOVE` in audit; not implemented yet | developer |
| Validate optional notifications UX (`POST_NOTIFICATIONS`) | Medium risk if permission ask appears mandatory/unclear | Optional flow exists, but final reviewer-safe verification pending | developer |
| Release merged manifest verification | Confirms transitive permissions actually shipped | `PENDING` (`NEEDS CONFIRMATION`) | developer |

## Data Safety
| Item name | Why it matters | Current status | Who should fill it |
|---|---|---|---|
| Final Data Safety form submission | Mandatory before release tracks | `MISSING` (draft exists only) | business + manual |
| Data-type category mapping finalization | Prevents inaccurate declarations/rejections | `NEEDS CONFIRMATION` for some fields (push token, purchase payload, WhatsApp fields) | business + manual |
| Encryption and backend retention confirmation | Needed to answer Data Safety questions accurately | `NEEDS CONFIRMATION` | developer + manual |
| Dependency-level hidden data collection check | Ensures no missed SDK collection/share declarations | `NEEDS CONFIRMATION` | developer |

## Technical / build / release
| Item name | Why it matters | Current status | Who should fill it |
|---|---|---|---|
| Release signing readiness (`android/key.properties` path) | Unsigned/mis-signed release blocks Play upload | Checklist notes debug fallback risk locally | developer |
| Permission regression test pass (Android 13+/12/legacy path) | Avoids runtime failures after permission hardening | `PENDING` | developer |
| Final reviewer instructions consistency check | Store submission must match actual app behavior | Docs exist, but final pre-submit verification pending | manual |

## Must finish before Closed Testing
- Privacy policy URL
- Support email
- Final app category and content rating submission
- Reviewer access path confirmation (self-signup vs demo credentials)
- Final Data Safety form submission (at least closed-testing-ready accuracy)
- Release signing readiness confirmation
- Merged release manifest verification

## Can finish before Production submission
- Legacy storage permission migration (`REMOVE`/`REPLACE` plan execution)
- Additional hardening of media permission flow and notification prompt wording
- Full dependency-level data collection validation and legal wording refinement
- Finalized deletion/retention policy detail improvements beyond minimum closed testing
