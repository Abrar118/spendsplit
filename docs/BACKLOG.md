# Backlog

The 2026-10-28 review backlog is done (PR "feat/backlog"). What's left, plus
the limits of what shipped. In-flight work lives in `docs/superpowers/plans/`
(iOS widget + SMS: `2026-10-28-ios-widget-and-sms.md`).

## Open

- **Day-one runway is very pessimistic.** With one day of history, a single
  rent payment reads as the daily pace. Short history using observed days is
  deliberate (`20db1be`); revisit if it bothers in practice.

## Limits of what shipped

- **Safe to spend:** payday detection needs the largest income to land in at
  least two of the last three months. Irregular income falls back to month
  end.
- **Recap category changes:** only categories with spend in the recap month.
  A category that dropped to zero isn't flagged.
- **Privacy cover on Android:** needs Android 13+. Older versions still show
  the app in recents.
- **SMS engine contention (Android):** WAL plus a busy timeout prevents
  "database is locked". Rows inserted by the background engine show up in a
  running app on its next resume, not instantly.
