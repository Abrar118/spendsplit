# SpendSplit Agent Context

## Objective

Build **SpendSplit**, an offline-only Flutter expense tracker with a dark, glassmorphic interface. The app manages one BDT balance split into **Available** and **Savings**, includes a separate **USD tracker**, and optionally gates launch with **biometric lock**.

## Current Project State

- The repository is still near the default Flutter scaffold.
- [`lib/main.dart`](/Users/orion-abrar/Code/flutter_projects/spendsplit/lib/main.dart) currently renders a `Hello World` app.
- [`pubspec.yaml`](/Users/orion-abrar/Code/flutter_projects/spendsplit/pubspec.yaml) does not yet contain the implementation dependencies from the guide.
- The design and implementation documents should be treated as the current source of truth.

## Source Documents

Use these files in this order when implementing:

1. [`asset/SpendSplit_Flutter_Guide.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/SpendSplit_Flutter_Guide.md)
   Defines the target architecture, package choices, routes, screen behavior, database schema, derived calculations, and feature boundaries.
2. [`asset/DESIGN.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/DESIGN.md)
   Defines the visual system: "Luminous Depth" / "The Neon Observatory".
3. [`asset/app-icon.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/app-icon.png)
   Source artwork for the application icon.
4. Screen-level mockups under [`asset/stitch_add_transaction_sheet`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet)
   Each folder contains `screen.png` and `code.html` for visual reference.
5. [`asset/stitch_add_transaction_sheet/lucid_obsidian/DESIGN.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/lucid_obsidian/DESIGN.md)
   Additional design refinements that should be treated as supporting visual guidance.

Note: the actual folder in this repo is `asset/stitch_add_transaction_sheet`, not `assets/stitch_add_transaction_sheet`.

## Visual Reference Map

- Dashboard:
  [`asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/screen.png)
  [`asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/code.html)
- Transactions:
  [`asset/stitch_add_transaction_sheet/transactions_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/transactions_obsidian/screen.png)
  [`asset/stitch_add_transaction_sheet/transactions_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/transactions_obsidian/code.html)
- Add transaction sheet:
  [`asset/stitch_add_transaction_sheet/add_transaction_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/add_transaction_obsidian/screen.png)
  [`asset/stitch_add_transaction_sheet/add_transaction_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/add_transaction_obsidian/code.html)
- Monthly view:
  [`asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/screen.png)
  [`asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/code.html)
- Savings goals:
  [`asset/stitch_add_transaction_sheet/savings_goals_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/savings_goals_obsidian/screen.png)
  [`asset/stitch_add_transaction_sheet/savings_goals_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/savings_goals_obsidian/code.html)
- Dollar tracker:
  [`asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/screen.png)
  [`asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/code.html)
- Lock screen:
  [`asset/stitch_add_transaction_sheet/app_lock_clean/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/app_lock_clean/screen.png)
  [`asset/stitch_add_transaction_sheet/app_lock_clean/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/app_lock_clean/code.html)

## Implementation Constraints

- Flutter app, Android-first, iOS-compatible.
- State management: `flutter_riverpod` / Riverpod generators.
- Local persistence: Drift + SQLite.
- Routing: `go_router`.
- Dark mode only.
- Offline only.
- USD tracker must stay isolated from BDT balance, monthly summaries, and core calculations.
- Biometric lock is optional and controlled via local settings.

## Project Structure Target

Use the feature-first MVVM structure from the guide:

- `lib/app.dart` for app shell, theme, and router
- `lib/core/` for theme, constants, utilities, and reusable widgets
- `lib/data/` for Drift database, tables, DAOs, models, and repositories
- `lib/features/auth/`
- `lib/features/dashboard/`
- `lib/features/transactions/`
- `lib/features/monthly/`
- `lib/features/goals/`
- `lib/features/dollar_tracker/`
- `lib/providers/` for global Riverpod providers

Each feature should generally use `screens/`, `widgets/`, and `providers/`.

## Navigation Contract

- `/` is the ShellRoute-backed main app container.
- `/transactions` is tab 1.
- `/monthly` is tab 3.
- `/goals` is tab 4.
- `/dollar-tracker` is pushed from the dashboard, not part of bottom-tab navigation.
- `/lock` is the launch route when biometric protection is enabled.
- The center `+` item does not navigate; it opens `AddTransactionSheet`.

## Design Rules That Should Not Drift

- Use the dark navy "Void" surfaces from the design docs. Do not use pure black.
- Prefer tonal layering and ambient glow over standard Material shadow stacks.
- Use glassmorphism for floating surfaces such as sheets, nav bars, and modals.
- Avoid visible dividers when spacing can separate sections.
- Keep the UI asymmetrical and editorial, not generic Material boilerplate.
- Typography precedence: prefer **Manrope** because the primary design spec in [`asset/DESIGN.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/DESIGN.md) defines it as the editorial type system. `Inter` appears in secondary guidance and can be treated as fallback only if implementation constraints force it.
- Primary accent colors should remain consistent:
  teal for primary actions and available balance, coral for expenses, green for income, purple for savings, amber for warnings and USD utilization, blue for chart highlights.

## Feature Boundaries

Implement:

- Dashboard
- Transactions history
- Add transaction sheet
- Monthly analytics
- Savings goals
- Dollar tracker
- Biometric lock
- Shared theme primitives, reusable widgets, repositories, and derived calculations

Do not implement in the initial scope:

- Cloud sync or backup
- Multiple bank accounts
- Notifications or reminders
- Recurring transactions
- Currency conversion
- Light mode
- Onboarding
- Export to CSV/PDF
- Home screen widgets

## Data and Domain Rules

- Main ledger currency is BDT (`৳`); USD (`$`) is only for the isolated dollar tracker.
- No currency conversion.
- Main transaction amounts are stored as positive values; direction is determined by transaction type.
- Core transaction types:
  `income`, `expense`, `savings_deposit`, `savings_withdrawal`
- Seed 6 predefined categories:
  Food, Transport, Utilities, Health, Shopping, Other
- Support user-created custom categories for the main tracker.
- Dollar tracker categories are separate from the main BDT tracker categories.
- Derived values are never stored directly when they can be calculated from source data and settings.

## Core Interaction Patterns

- Edit transaction:
  open `AddTransactionSheet` prefilled and switch the primary action to `Update`
- Delete transaction:
  swipe left, confirm delete state, then show snackbar with 3-second undo
- Empty states:
  use centered illustration/message treatment with subtle fade-in and slide-up
- Add/save actions:
  include haptic feedback on FAB tap, save button, and swipe delete confirm

## Build Workflow

- Run `flutter pub get` after dependency changes.
- Run `dart run build_runner build --delete-conflicting-outputs` after adding or changing Drift or Riverpod generated code.
- Use `flutter run` for milestone review in the simulator/device.

## Implementation Guidance

- Use the guide for behavior, architecture, routes, persistence, and calculations.
- Use the stitched `screen.png` and `code.html` files for composition, spacing, and component feel.
- Read the target screen’s PNG and HTML before implementing that screen.
- Use the additional stitched design note in [`asset/stitch_add_transaction_sheet/lucid_obsidian/DESIGN.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/lucid_obsidian/DESIGN.md) when the screen pack implies refinements beyond the base design doc.
- When the guide and stitched visuals differ slightly, preserve the guide’s functional behavior and the mockup’s visual direction.
- Build reusable theme and widget primitives before feature screens.
- Favor incremental vertical slices that can be reviewed in the simulator after each milestone.
- Apply motion intentionally:
  shimmer for first-load placeholders, animated progress fills, chart growth, and subtle count-up effects on dashboard totals.
