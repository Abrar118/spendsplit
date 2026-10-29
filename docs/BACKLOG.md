# Backlog

The 2026-10-28 review backlog is done (PR "feat/backlog"). What's left, plus
the limits of what shipped. In-flight work lives in `docs/superpowers/plans/`
(iOS widget + SMS: `2026-10-28-ios-widget-and-sms.md`).

## Open

- **iOS home-screen widget** — Phase 1 of the iOS plan; not started.

## Limits of what shipped

- **Recap category changes:** only categories with spend in the recap month.
  A category that dropped to zero isn't flagged.
- **Privacy cover on Android:** needs Android 13+. Older versions still show
  the app in recents.
- **SMS engine contention (Android):** WAL plus a busy timeout prevents
  "database is locked". Rows inserted by the background engine show up in a
  running app on its next resume, not instantly.
- **SMS import on iOS:** no background import. Rows land when the app next
  opens or resumes.
