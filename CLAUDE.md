# CLAUDE.md — SpendSplit

## Project Overview

**SpendSplit** is a minimalist, offline-only mobile expense tracker built with Flutter. It splits a single bank account balance into Available (spendable) and Savings, with a dark glassmorphic UI, biometric lock, and an isolated USD spending tracker.

**Platform:** Flutter (Android-first, iOS compatible)
**State Management:** Riverpod
**Database:** Drift (SQLite)
**Architecture:** Feature-first with MVVM
**Navigation:** GoRouter

---

## Key Design References

All design assets live in `asset/`:

- **`asset/DESIGN.md`** — Full design system spec ("Luminous Depth" / "The Neon Observatory"). Read this before building ANY UI component. It defines colors, surfaces, typography, elevation, glassmorphism rules, and strict do's/don'ts.
- **`asset/SpendSplit_Flutter_Guide.md`** — Complete Flutter implementation guide with screen specs, database schema, navigation structure, calculated values, component details, and micro-interactions.
- **`asset/stitch_add_transaction_sheet/`** — Individual screen designs as PNG screenshots and HTML reference code. Each subfolder contains `screen.png` and `code.html`:
  - `spendsplit_dashboard_lucid_v2/` — Dashboard
  - `monthly_view_red_orange_gradient/` — Monthly View
  - `transactions_obsidian/` — Transactions list
  - `app_lock_clean/` — Lock Screen
  - `savings_goals_obsidian/` — Savings Goals
  - `dollar_tracker_obsidian/` — Dollar Tracker
  - `add_transaction_obsidian/` — Add Transaction sheet
  - `lucid_obsidian/DESIGN.md` — Additional design refinements
- **`asset/app-icon.png`** — Application icon

---

## Design System Rules (MUST follow)

Source of truth is `lib/core/theme/` (`app_colors.dart`, `app_typography.dart`,
`app_decorations.dart`, `app_spacing.dart`). The values below mirror it.

### Dark Theme Only
- Base void: pure black `#000000` (`AppColors.background`). The earlier
  "never use #000000" rule was deliberately overridden — the app is OLED black.
- Card surfaces: `#15131F` (`AppColors.surface`), elevated `#1E1A2C`
  (`AppColors.surfaceLight`). Faintly purple-tinted charcoal.
- All UI is dark theme. No light mode toggle.

### Glassmorphism
- Floating UI (sheets, the nav pill) uses a backdrop blur over a low-opacity
  tint. The nav additionally composes a saturation matrix onto the blur so it
  reads as frosted glass rather than grey haze (`AppDecorations.navFrost()`).
- No solid 1px borders for sectioning — use surface layering, a faint top
  highlight, and a soft drop shadow instead. Cards carry no stroke.

### Color Accents (see `lib/core/theme/app_colors.dart`)
- **Gold** `#ECBB7E` (`AppColors.teal`) — primary actions, available balance, active nav, chart bars
- **Coral** `#F26D3D` (`AppColors.coral`) — expenses, negative amounts, delete
- **Green** `#34D89C` (`AppColors.green`) — income, positive amounts
- **Purple** `#9B8BFF` (`AppColors.purple`) — savings, goal progress
- **Amber** `#ECB877` (`AppColors.amber`) — warnings, deadlines, dollar ring
- **Violet** `#7A46E0` (`AppColors.blue`) — charts, secondary highlights, links

### Typography
- Use Google Fonts **Manrope** (see `lib/core/theme/app_typography.dart`)
- Large balance numbers: bold with a subtle glow shadow
- Labels: all caps, tracked spacing (e.g., "TOTAL BALANCE", "ENTER AMOUNT")
- Muted text: `AppColors.textSecondary` / `textTertiary`

### Cards & Components
- No horizontal dividers between list items — use vertical spacing (16px)
- Hero cards: 16–24dp radius with a soft glow shadow (no border)
- Bottom nav: a floating frosted-glass pill (radius 28), no border — a strong
  backdrop blur with a saturation matrix composed on top, a faint white sheen,
  and a soft outer shadow. Tint `#16121F`. Content scrolls behind it; pages
  reserve `AppSpacing.navClearance` at the bottom.
- Progress bars: gradient fill on dark track, rounded ends

---

## Architecture & Project Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + GoRouter + Theme
├── core/
│   ├── theme/                        # app_theme, app_colors, app_typography, app_decorations
│   ├── constants/                    # categories, enums
│   ├── utils/                        # currency_formatter, date_utils, extensions
│   └── widgets/                      # glass_card, accent_chip, bottom_nav_bar, empty_state, amount_text
├── data/
│   ├── database/                     # Drift DB, tables/, daos/
│   ├── models/
│   └── repositories/
├── features/
│   ├── auth/                         # Lock screen, biometric
│   ├── dashboard/                    # Home screen with balance card, charts, previews
│   ├── transactions/                 # Transaction list, filters, add/edit sheet
│   ├── monthly/                      # Monthly breakdown, donut chart, category details
│   ├── goals/                        # Savings goals, progress rings
│   └── dollar_tracker/               # Isolated USD expense tracker
└── providers/                        # Global Riverpod providers
```

Each feature follows: `screens/`, `widgets/`, `providers/` structure.

---

## Tech Stack & Key Dependencies

```yaml
# State: flutter_riverpod, riverpod_annotation
# Database: drift, sqlite3_flutter_libs
# Navigation: go_router
# Charts: fl_chart
# Typography: google_fonts
# Animation: flutter_animate, shimmer
# Auth: local_auth
# Icons: lucide_icons
# Swipe: flutter_slidable
# Sheets: modal_bottom_sheet
# Settings: shared_preferences
# Spacing: gap
# Formatting: intl
# Haptics: vibration
```

---

## Navigation Structure

```
/ (ShellRoute with BottomNavBar)
├── /                    → DashboardScreen (tab 0)
├── /transactions        → TransactionsScreen (tab 1)
├── /monthly             → MonthlyScreen (tab 3)
├── /goals               → GoalsScreen (tab 4)
└── /dollar-tracker      → DollarTrackerScreen (push, not tab)

/goal/:id                → GoalDetailScreen (push)
/settings, /export, /manage-categories, /manage-templates  (push)
/lock                    → LockScreen (initial route if biometric enabled)
```

Tab indices: dashboard 0, transactions 1, add 2 (sheet — no route), monthly 3, goals 4.
Center "+" tab (index 2) triggers `showModalBottomSheet` for AddTransactionSheet — it does NOT navigate.

---

## Database Schema (Drift)

Six tables (`schemaVersion` 7): `transactions_table`, `categories_table`,
`savings_goals_table`, `dollar_expenses_table`, `transaction_templates_table`
(carries `use_count` + `is_monthly`), `category_budgets_table` (one
`monthly_limit` per `category_id`). The v6 → v7 migration is additive only.
Settings via SharedPreferences: `biometric_enabled`, `dollar_annual_limit`,
`dollar_limit_year`, `monthly_expense_budget`, `recap_dismissed_month`.
`initial_balance` and `card_number` live in the platform keystore
(`SecureStorageRepository`), not SharedPreferences.

### Calculated Values (derived, never stored)
- **Total Balance** = initial_balance + SUM(income) - SUM(expenses)
- **Savings Balance** = SUM(savings_deposits) - SUM(savings_withdrawals)
- **Available Balance** = Total Balance - Savings Balance
- **Dollar Remaining** = dollar_annual_limit - SUM(dollar_expenses for year)

---

## Critical Implementation Rules

1. **Dollar Tracker is completely isolated** — no cross-contamination with BDT graphs, monthly summaries, or balance calculations.
2. **Currency:** BDT (৳) for main tracker, USD ($) for dollar tracker only. No currency conversion.
3. **Transaction amounts are always stored positive** — sign/direction determined by type enum (`income`, `expense`, `savings_deposit`, `savings_withdrawal`).
4. **Categories:** 6 predefined (Food, Transport, Utilities, Health, Shopping, Other) + user-created custom categories. Dollar tracker has its own separate categories.
5. **Edit pattern:** Tap transaction → opens AddTransactionSheet pre-filled → "Update" button.
6. **Delete pattern:** Swipe left → red delete panel → snackbar with 3-second Undo.
7. **Empty states:** Each list screen has a centered illustration + message with fade-in + slide-up animation.

---

## Features

- **Runway** — dashboard shows how many days Available lasts at the trailing
  30-day expense burn rate.
- **Balance trend** — 6-month reconstructed Available/Savings area chart.
- **Spending Velocity** — rolling 12-month expense bars with an income overlay.
- **Category budgets** — optional per-category monthly limits, edited inline on
  the Monthly screen's Category Details rows.
- **Category editor** — custom categories can be renamed / re-iconed / recoloured
  (`_CategoryEditorSheet`); predefined categories stay fully locked.
- **Goal contributions** — "Add Contribution" from the goal menu logs a linked
  `savings_deposit` and bumps the goal; tapping a goal card opens the Goal
  Detail screen (`/goal/:id`) with contribution history and a completion
  projection.
- **Dollar pacing** — projected year-end USD spend vs. the annual limit.
- **Month-end recap** — dismissible dashboard card (days 1–5) summarising the
  prior month; the dismissed month key is stored in `recap_dismissed_month`.
- **Template quick-apply** — the three most-used templates show as chips in the
  add-transaction sheet; `use_count` increments on apply.
- **Template checklist** — templates toggled "Expected monthly" in Manage
  Templates that haven't been logged yet this month surface on the dashboard.
- **JSON snapshot backup** — full export/restore of all six tables plus settings
  (`SnapshotService`), restore behind a hold-to-confirm (Export screen).

---

## What NOT to Implement

- Cloud sync
- Multiple accounts
- Push notifications / reminders
- Recurring transactions
- Currency conversion
- Light mode
- Onboarding tutorial

> Recurring transactions remain unimplemented; the monthly-template checklist
> (see Features) is the lightweight substitute. CSV/PDF export, CSV import, and
> the Android home-screen widget are already built.

---

## Build & Run

```bash
cd spendsplit
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # Generate Drift & Riverpod code
flutter run
```

---

## When Building UI

1. The `asset/stitch_*` PNGs and `asset/DESIGN.md` are **historical** reference —
   the live design (pure-black, frosted glass, Manrope) has deliberately moved
   past them. Match the current in-app style; treat the mockups as directional.
2. Source of truth for theme is `lib/core/theme/`. Reuse `AppColors`,
   `AppDecorations`, `AppSpacing`, `AppTypography` — don't hand-roll colors.
3. `asset/SpendSplit_Flutter_Guide.md` is still useful for screen specs and
   calculated-value definitions.
4. Use `flutter_animate` for micro-interactions: number count-ups, shimmer loading, progress bar fills, chart bar stagger animations.
5. Add haptic feedback on: FAB tap, save button, swipe delete confirm.
