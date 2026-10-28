# Backlog

Ideas from the 2026-10-28 app review, not yet scheduled. In-flight work lives
in `docs/superpowers/plans/` (iOS widget + SMS:
`2026-10-28-ios-widget-and-sms.md`).

## Features

1. **Upcoming section.** List future-dated entries with "Available after
   scheduled", so leaving them out of balances is visible instead of
   confusing. They're already excluded via `postedTransactionsProvider`.
2. **Safe to spend per day.** Available ÷ days until the next expected income,
   inferred from the income cadence or monthly templates. It's more actionable
   than runway, and one-off rent doesn't distort it.
3. **Budget pace marker.** On the monthly budget card and the category bars,
   mark where spending should be by today (budget × day ÷ days in month), as
   an early overspend warning.
4. **Reassign on category delete.** Offer to move the category's
   transactions, templates and dollar expenses to another category, and show
   how many rows are affected. Today they become uncategorized; dollar
   expenses keep a dead ID because their column is non-null.
5. **SMS parse-failure counter.** Count Trust Bank SMS that mention
   DEBIT/CREDIT but don't parse, and show the count in Settings. Today a bank
   format change skips messages silently and for good, because the watermark
   still advances.
6. **Privacy cover.** Hide balances in the app-switcher preview:
   `FLAG_SECURE` on Android, a blur on `inactive` on iOS. The widget already
   shows only the review count (iOS plan).
7. **Category changes in the recap.** Compare each category this month with
   its 3-month average ("Food +40% vs usual") on Monthly or in the month-end
   recap.
8. **Small UX fixes:**
   - The empty state notices active search, filters or review mode and says
     "No matches — clear filters" instead of "No transactions yet".
   - Changing a transaction's date keeps its time of day. `_pickDate` resets
     it to midnight, so re-dated entries show 12:00 am and sort wrongly within
     the day.
   - Deleting a goal gets an undo or hold-to-confirm. It silently unlinks
     every contribution.

## Known bugs (not fixed yet)

- **Template picker.** Deleted templates stay in the picker, which gets a
  fixed list (`add_transaction_sheet.dart:803`). `use_count` goes up when the
  dashboard "Log" opens the sheet, not when it saves (`:129`).
- **Haptics missing on save and swipe-delete.** AGENTS.md requires them; only
  the nav bar has any.
- **Lock screen copy says "fingerprint" / "Use Pattern" on Face ID.** If the
  device has no passcode, the screen is a dead end with no hint to set one.
- **Goal Detail says "Goal not found" while goals are still loading.** The
  dollar sheet's error state renders an empty sheet.
- **Save-as-template with an empty name does nothing.** The hint suggests the
  note is used as the default.
- **Menu "Mark complete" sets `currentAmount` to the target.** It does this
  even when the goal is underfunded, so the amount drifts from its linked
  transactions.
- **Android SMS: two engines can import at once.** The background and app
  engines race. There's no `busy_timeout`/WAL, and the app's drift streams
  don't see the other engine's inserts.
- **Keystore.** The migration leaves plaintext `initial_balance` /
  `card_number` copies in SharedPreferences. On iOS, Keychain items survive
  an app delete.
- **Upgrade from schema ≤ v4 fails.** The v5 step creates the templates
  table with the v7 columns, then v7 adds them again. Only old dev builds are
  affected.
- **Day-one runway is very pessimistic.** With one day of history, a single
  rent payment reads as the daily pace. Short history using observed days is
  deliberate (`20db1be`).
