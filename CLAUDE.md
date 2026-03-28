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

### Dark Theme Only
- Base void: `#0A0E1A` (deep dark navy) — NEVER use pure black `#000000`
- Card surfaces: `#141829`, elevated: `#1C2137`
- All UI is dark theme. No light mode toggle.

### Glassmorphism
- All floating UI (modals, navbars, sheets) use: surface at 80% opacity + backdrop blur 12px
- No solid 1px borders for sectioning — use surface layering and whitespace instead
- Ghost borders only: white at ~6% opacity when a stroke is truly needed

### Color Accents
- **Teal** `#00E5BF` — Primary actions, available balance, active nav
- **Coral** `#FF6B6B` — Expenses, negative amounts, delete actions
- **Green** `#34D399` — Income, positive amounts
- **Purple** `#9C7CFF` — Savings, goal progress
- **Amber** `#FBBF24` — Warnings, deadlines, dollar tracker ring
- **Blue** `#60A5FA` — Charts, secondary highlights

### Typography
- Use Google Fonts **Inter** for clean modern look
- Large balance numbers: Bold 28-36sp with subtle glow effect
- Labels: All caps, tracked spacing (e.g., "TOTAL BALANCE", "ENTER AMOUNT")
- Muted text: `#8892A7`

### Cards & Components
- No horizontal dividers between list items — use vertical spacing (16px)
- Hero cards: 16-20dp radius with glow border
- Pill-shaped bottom nav bar: floating, 24dp radius, dark `#0F1322` background
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

/lock                    → LockScreen (initial route if biometric enabled)
```

Center "+" tab (index 2) triggers `showModalBottomSheet` for AddTransactionSheet — it does NOT navigate.

---

## Database Schema (Drift)

Four tables: `transactions_table`, `categories_table`, `savings_goals_table`, `dollar_expenses_table`
Settings via SharedPreferences: `biometric_enabled`, `dollar_annual_limit`, `dollar_limit_year`, `initial_balance`

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

## What NOT to Implement

- Cloud sync / backup
- Multiple accounts
- Notifications / reminders
- Recurring transactions
- Currency conversion
- Light mode
- Onboarding tutorial
- Export to CSV/PDF
- Home screen widgets

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

1. **Always read the screen's PNG** in `asset/stitch_add_transaction_sheet/` and its `code.html` for reference before implementing.
2. **Always follow `asset/DESIGN.md`** for the design system (Luminous Depth).
3. **Always follow `asset/SpendSplit_Flutter_Guide.md`** for component specs, spacing, and interaction details.
4. Use `flutter_animate` for micro-interactions: number count-ups, shimmer loading, progress bar fills, chart bar stagger animations.
5. Add haptic feedback on: FAB tap, save button, swipe delete confirm.
