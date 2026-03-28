# SpendSplit Implementation Chronology

This sequence is optimized for **reviewable increments**, not for the screen numbering in the guide. The current repo is still a starter Flutter app, so the first milestones establish the foundation needed to build the rest cleanly.

## Review Strategy

Each phase should end in a state that can be run and reviewed in the simulator. Avoid starting multiple large screens before the shared primitives, data model, and routing shell are stable.

## Conflict Resolution Rule

When the Flutter guide and the stitched mockups (`screen.png` / `code.html`) differ slightly, **preserve the guide's functional behavior and the mockup's visual direction**. The guide is authoritative for routes, state, data flow, and interaction contracts. The mockups are authoritative for composition, spacing, and visual feel.

Additionally, [`asset/stitch_add_transaction_sheet/lucid_obsidian/DESIGN.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/lucid_obsidian/DESIGN.md) contains supplementary design refinements. Consult it when a screen's stitch reference implies visual treatment beyond what the base `DESIGN.md` covers.

**Note:** The design asset folder is `asset/stitch_add_transaction_sheet` (singular `asset`), not `assets/`.

## Phase 1: Foundation and App Shell

**Goal:** Replace the starter app with the permanent project skeleton.

**Scope**

- Add all dependencies from the Flutter guide (`pubspec.yaml`).
- Create the feature-first folder structure under `lib/`.
- Add `app.dart`, GoRouter shell with `ShellRoute`, and `ProviderScope`.
- Implement theme primitives in `core/theme/`:
  - `app_colors.dart` — all color constants. **Use the Flutter guide's hex values** (background `#0A0E1A`, surface `#141829`, surfaceLight `#1C2137`, navBar `#0F1322`). Where `DESIGN.md` disagrees, the Flutter guide takes precedence for implementation.
  - `app_typography.dart` — **use Manrope** via `google_fonts` (as specified in `DESIGN.md`). Note: the Flutter guide says Inter, but the design system spec and stitch references use Manrope. This chronology resolves the conflict in favor of Manrope.
  - `app_decorations.dart` — glassmorphic card decoration, gradient definitions, **plus named glow tokens**: Inner Glow (for hero cards: `inner-shadow 0 1px 1px rgba(255,255,255,0.1)`), Ambient Glow (tinted shadow at 5% opacity with 40px blur), Ghost Border (`outline_variant` at 20% opacity), and Contextual Glow (faint green outer glow for positive balance text). These are cross-cutting design primitives from `DESIGN.md` that multiple later phases depend on.
  - Spacing constants.
- Add reusable base widgets in `core/widgets/`:
  - `glass_card.dart` — reusable glassmorphic card container.
  - `accent_chip.dart` — filter/type chip.
  - `bottom_nav_bar.dart` — the full custom floating bottom nav: 5 items, pill shape (24dp radius), solid dark `#0F1322` background (per the Flutter guide, not glassmorphism), raised center FAB (48dp teal circle with white "+"), active state (teal icon + dot indicator), inactive state (gray icon). **The center item must NOT navigate** — it triggers `showModalBottomSheet`. This interaction contract must be established here because Phase 3 depends on it.
  - `empty_state.dart` — centered illustration + message with fade-in/slide-up animation.
  - `amount_text.dart` — colored amount display with optional glow.
- Register Manrope font and wire the app icon asset workflow.

**Primary references**

- [`asset/SpendSplit_Flutter_Guide.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/SpendSplit_Flutter_Guide.md)
- [`asset/DESIGN.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/DESIGN.md)
- [`asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/code.html)

**Design rules to internalize now (apply in every later phase)**

- **No-Divider Rule:** Never use horizontal lines between list items. Use vertical negative space (16px) instead.
- **No pure black:** Never use `#000000`. The darkest value is `#0A0E1A`.
- **No Material elevation shadows:** Use tonal shifts or tinted ambient glows.
- **Contextual Glow:** Positive balances get a faint green outer glow on the text.

**Review checkpoint**

- App launches into the dark branded shell.
- Bottom nav is fully styled with the raised center FAB. Tapping "+" opens an empty placeholder sheet.
- Placeholder screens exist for dashboard, transactions, monthly, goals, and dollar tracker (push route).

## Phase 2: Data and Settings Backbone

**Goal:** Put persistence and domain calculations in place before feature UI becomes dynamic.

**Scope**

- Set up Drift database initialization using `path_provider` and `path` for DB file location.
- Add all four Drift tables: `transactions_table`, `categories_table`, `savings_goals_table`, `dollar_expenses_table`.
- Add all four DAOs: `transaction_dao`, `category_dao`, `savings_goal_dao`, `dollar_expense_dao`. All four must exist now — Phase 3 needs `category_dao` for the category selector, and Phase 5 needs dollar data for the summary card.
- Add all four repositories: `transaction_repository`, `savings_repository`, `dollar_tracker_repository`, and a category repository. The dollar tracker repository is created here (not Phase 8) so that Phase 5's dashboard summary card can query it.
- Seed the 6 default BDT categories (`is_predefined = true`): Food, Transport, Utilities, Health, Shopping, Other. Dollar-specific categories (`is_dollar_category = true`) are **not** seeded — users create them in Phase 8's add-dollar-expense flow.
- Run `build_runner` to generate Drift code.
- Add SharedPreferences-backed settings: `biometric_enabled` (bool, default false), `initial_balance` (double, default 0.0), `dollar_annual_limit` (double, default 12000.0), `dollar_limit_year` (int, default current year). Note: when the year rolls over, the app should detect that `dollar_limit_year` differs from the current year and prompt the user to set a new limit — this behavior is built in Phase 8.
- Implement derived calculation helpers:
  - Total Balance = initial_balance + SUM(income) - SUM(expenses)
  - Savings Balance = SUM(savings_deposits) - SUM(savings_withdrawals)
  - Available Balance = Total Balance - Savings Balance
  - This Month Income / Expenses / Saved
  - Dollar Spent YTD and Dollar Remaining
  - Month-over-month savings delta (percentage change for the savings trend chip in Phase 7)
  - Average monthly savings (for the predictive text in Phase 7's overall progress ring)
- Add global Riverpod providers for database, all repositories, and settings.

**Spec gap — Category spend classification:** The Flutter guide shows "RECURRING" / "FLEXIBLE" / "VARIABLE" / "ONE-TIME" labels on monthly category detail rows (Phase 6), but the database schema has no column for this classification. Options: (a) add a `spend_type` enum column to `categories_table`, (b) derive it heuristically from transaction frequency, or (c) drop the labels. This must be decided before Phase 6.

**Primary references**

- Database schema and calculated values in
  [`asset/SpendSplit_Flutter_Guide.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/SpendSplit_Flutter_Guide.md)

**Review checkpoint**

- Local persistence works across app restarts.
- All 6 seed BDT categories exist.
- All four DAOs and repositories are functional.
- Derived balances can be verified with sample data inserted via DAO.

## Phase 3: Transaction Capture Vertical Slice

**Goal:** Deliver the first complete user flow: create and persist money movements.

**Scope**

- Build `AddTransactionSheet` (modal bottom sheet covering ~75% screen).
- Implement type selector: three pill tabs — EXPENSE (coral), INCOME (green), SAVINGS (purple).
- Implement category selection (expense type): horizontal scrollable row of category icons with colored selection state. Include a "+ Custom" item at the end that allows the user to create a new category and persist it to `categories_table` via `category_dao`.
- Implement income source chips: "Salary", "Freelance", "Other".
- Implement savings subtype toggle: "Deposit" | "Withdrawal".
- Implement amount input with large display (৳ symbol + number), date picker, and optional note field.
- Add create and edit flows using the same sheet. When editing, the sheet opens pre-filled with existing data and the save button label changes from "Save Transaction" to "Update". The edit entry point (tap on transaction tile) is wired in Phase 4; this phase builds the sheet's ability to accept and display existing transaction data.
- Add save feedback: haptic vibration and snackbar confirmation.

**Primary references**

- [`asset/stitch_add_transaction_sheet/add_transaction_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/add_transaction_obsidian/screen.png)
- [`asset/stitch_add_transaction_sheet/add_transaction_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/add_transaction_obsidian/code.html)
- Add Transaction section in
  [`asset/SpendSplit_Flutter_Guide.md`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/SpendSplit_Flutter_Guide.md)

**Review checkpoint**

- The center FAB in the nav bar opens the designed sheet.
- You can add income, expense, savings deposit, and savings withdrawal entries.
- Custom categories can be created from within the sheet.
- Saved entries persist and can be re-opened for edit (via a temporary test entry point until Phase 4 wires the tile tap).

## Phase 4: Transactions Screen

**Goal:** Make the recorded data browseable and manageable.

**Scope**

- Build grouped transaction history with sticky date headers (all caps, muted, 11sp, tracked: "TODAY", "YESTERDAY", "MARCH 25, 2026").
- Add filter chips row (All, Income, Expense, Savings) and advanced filter bottom sheet with type checkboxes, category chip grid, and date range pickers.
- Implement transaction tiles (glass card style) with:
  - **3dp colored vertical accent bar** on the left edge: coral for expense, green for income, purple for savings deposit, amber for savings withdrawal.
  - Category icon in a colored circle (40dp).
  - Amount with sign and color: `- ৳42.50` coral, `+ ৳850.00` green, `↓ ৳200.00` purple, `↑ ৳500.00` amber.
- Add slidable actions (`flutter_slidable`): swipe **left** → red Delete with trash icon, swipe **right** → blue Edit with pencil icon.
- **Wire the edit entry point:** Tapping a transaction tile opens `AddTransactionSheet` (from Phase 3) pre-filled with that transaction's data.
- Add delete with undo: snackbar "Deleted" with 3-second Undo action, then permanent delete.
- Add empty state: empty wallet line art + "No transactions yet. Tap + to add your first one."

**Primary references**

- [`asset/stitch_add_transaction_sheet/transactions_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/transactions_obsidian/screen.png)
- [`asset/stitch_add_transaction_sheet/transactions_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/transactions_obsidian/code.html)

**Review checkpoint**

- History is readable, filterable, and editable.
- Tapping a tile opens the edit sheet pre-filled; swiping works in both directions.
- Delete with undo works.
- The screen feels close to the stitched mockup.

## Phase 5: Dashboard with Live Calculations

**Goal:** Turn the home screen into the primary summary surface once transaction data exists.

**Scope**

- Build the **top bar**: hamburger icon (left), "SpendSplit" bold white (center-left), settings gear icon (right). The gear icon navigates to Settings (built in Phase 9); wire it as a placeholder tap target now.
- Build the **hero balance card** — styled as a credit/debit card with purple gradient background (`balanceCardGradient`):
  - "Trust Bank PLC" + "BANGLADESH" subtitle (top-left), card chip icon (top-right).
  - "TOTAL BALANCE" label → large bold amount (36sp) with Inner Glow decoration.
  - Masked card number `4532 •••• •••• 8291` (bottom-left), "Visa" text + contactless icon (bottom-right).
  - 20dp rounded corners. This is the most distinctive UI element — match the stitch reference closely.
- Build the **available/savings split** row below the card: "AVAILABLE" → teal amount (left), "SAVINGS" → purple amount (right), thin vertical divider.
- Add **this-month snapshot** cards: horizontally scrollable row of compact glass cards (Income/green, Spent/coral, Saved/purple) with colored icon circles.
- Implement **spending overview bar chart** (`fl_chart`): 12 bars for Jan–Dec, teal gradient fill, current month highlighted (brighter + bold teal label). Apply the chart vertex glow effect from `DESIGN.md` (4px blur circle behind data points). Empty months: short dark gray placeholder bars. Y-axis hidden; amounts shown on tap via tooltip.
- Add **active goal preview card**: glass card with left accent border, goal name, days remaining, amount/target, percentage in teal, gradient progress bar. **Note:** No goal data exists until Phase 7 builds the creation flow — show the empty state for this card ("Set your first savings goal!") until then.
- Add **dollar tracker summary card**: glass card with dollar icon, limit/spent/remaining values, progress bar. Data comes from `dollar_tracker_repository` (created in Phase 2). Tapping navigates to the full Dollar Tracker screen (built in Phase 8) — wire the navigation now even though the destination is a placeholder.
- Wire **pull-to-refresh** on the dashboard. This should invalidate/re-query all Riverpod providers that feed the dashboard.
- Add **loading states** (shimmer skeletons on glass cards) and **count-up animations** on balance amounts on screen load.

**Primary references**

- [`asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/screen.png)
- [`asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/spendsplit_dashboard_lucid_v2/code.html)

**Review checkpoint**

- Dashboard values are driven by persisted data.
- Available and savings balances are correctly derived.
- The balance card looks like a credit card, not a generic card.
- Goal preview shows empty state gracefully (no goals exist yet).
- Dollar summary card shows zeroes and navigates to placeholder.
- The home screen is visually strong enough to use as the design benchmark for the rest of the app.

## Phase 6: Monthly Analytics

**Goal:** Add historical month-level analysis after the primary transaction flow is stable.

**Scope**

- Build the top bar: hamburger (left), "SpendSplit" bold (center), settings gear (right).
- Build **month navigator**: "FISCAL PERIOD" muted label, ← Month Year → with arrow buttons, swipe gesture to change months.
- Add three **stacked summary cards** (full-width, colored gradient, 16dp radius):
  - Total Income (green gradient) — amount + "+X% FROM LAST MONTH" with trend icon.
  - Total Expenses (coral/red gradient) — amount + "-X% FROM LAST MONTH" with trend icon.
  - Amount Saved (purple gradient) — amount + "X% SAVINGS RATE" with shield icon.
- Implement **donut chart** (`fl_chart PieChart`): thick ring segments colored by category, hollow center showing "TOP CATEGORY" label + category name bold. Below: "N transactions this month" (muted) + "View all →" link (teal, navigates to Transactions screen filtered to the selected month).
- Build **sorted category detail rows** (glass card style): thick colored vertical bar (4dp), category name bold, amount + "X% OF TOTAL" (muted). Sorted descending by amount.
  - **Category classification labels** ("RECURRING" / "FLEXIBLE" / etc.): The Flutter guide shows these but the database schema has no field for them. **Resolution needed** (see Phase 2 spec gap note). If unresolved, omit these labels for now and use the category name only.
- Handle **empty months**: centered empty state "No data for this month." with empty calendar illustration.

**Primary references**

- [`asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/screen.png)
- [`asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/monthly_view_red_orange_gradient/code.html)

**Review checkpoint**

- Month switching updates all metrics correctly.
- Donut chart segments match transaction data; center shows top category.
- Category detail rows are sorted by amount and percentages are accurate.
- Empty and populated months both feel intentional.

## Phase 7: Savings Goals

**Goal:** Add the second major planning workflow after transactions and analytics are dependable.

**Scope**

- Build the top bar: hamburger (left), "Savings Goals" bold white (center-left), **"+ New Goal" text button** (teal, right) — this is the primary entry point for goal creation.
- Build the **total savings banner** (full-width glass card, purple tint):
  - "TOTAL SAVINGS RESERVED" (muted, caps) → large bold purple amount (32sp).
  - Green trend chip: "+X% this month" with trend arrow — uses the month-over-month savings delta helper from Phase 2.
  - "Across N active goals" subtitle (muted).
- Implement **active goals section** ("Active Ambitions" title + "PRIORITY VIEW" label):
  - Each goal card: goal name (18sp bold) + three-dot menu (⋮) + goal icon, deadline subtitle with clock icon, amount/target + percentage in teal, horizontal progress bar (teal/blue gradient on dark track).
  - Three-dot menu actions: Edit (opens goal sheet), Mark Complete, Delete (confirmation dialog).
- Build **completed goals section**: collapsible with green checkmark, count badge, chevron toggle. Completed goal cards are dimmed/muted.
- Build **overall progress ring** (large glass card):
  - Circular progress arc (teal gradient), center shows "OVERALL" label + large bold percentage.
  - Below: heading "On track for your milestones" + **predictive text**: "Based on your average monthly savings of ৳X, you'll reach your '[goal name]' goal in approximately N months." This uses the average monthly savings calculation helper from Phase 2. If no savings history exists, show a generic encouragement message.
  - "Adjust strategy" link in teal.
- Build **create/edit goal bottom sheet**: goal name input, target amount (৳ prefix), deadline toggle with date picker, optional icon picker, "Save Goal" button (purple).
- **Update the Dashboard** (Phase 5): now that goals exist, the active goal preview card on the dashboard should display the most recent active goal instead of the empty state.

**Primary references**

- [`asset/stitch_add_transaction_sheet/savings_goals_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/savings_goals_obsidian/screen.png)
- [`asset/stitch_add_transaction_sheet/savings_goals_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/savings_goals_obsidian/code.html)

**Review checkpoint**

- Goals can be created via "+ New Goal", edited via three-dot menu, completed, and deleted.
- Total savings banner shows accurate derived values with trend chip.
- Overall progress ring shows predictive text based on real savings data.
- Dashboard goal preview card now shows the active goal instead of empty state.
- Progress visuals feel polished and consistent with the core theme.

## Phase 8: Dollar Tracker

**Goal:** Add the isolated USD workflow once the main BDT experience is already solid.

**Scope**

- Build the **dollar tracker screen** with top bar: back arrow (←) + "Dollar Tracker" centered + year label.
- Build the **header card** (dark navy gradient): circular progress ring (amber/yellow, right side) showing "X% UTILIZED", left side shows "REMAINING BALANCE" label → large bold amount, "ANNUAL LIMIT" → limit value, "SPENT YTD" → spent value in teal.
- Add **"+ ADD EXPENSE" button** (outlined teal with plus icon).
- Build **recent dollar transactions list**: same card style as main transactions but with $ amounts, left colored accent bar, icon circle + title + category/date.
- Build **add dollar expense bottom sheet**: $ amount input, purpose text field, category chips. Include a **"+ New Category"** chip that creates a new category with `is_dollar_category = true` in `categories_table`. Suggested initial categories for user creation: Tuition, Software, Course, Hardware (these are not seeded — they are examples). Date picker, "Save" button (teal).
- Implement **yearly limit settings**: the dollar limit and year are stored in SharedPreferences. If `dollar_limit_year` differs from the current year on screen load, prompt the user to confirm or update their annual limit for the new year.
- **Isolation verification:** Confirm that no USD transaction data appears in the BDT dashboard balance, monthly summaries, spending chart, or any non-dollar-tracker surface. The `dollar_expenses_table` uses its own DAO/repository and is never queried by BDT-facing providers.
- Add empty state: globe with $ icon + "No foreign expenses tracked yet."

**Primary references**

- [`asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/screen.png)
- [`asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/dollar_tracker_obsidian/code.html)

**Review checkpoint**

- USD expenses persist and calculate independently.
- Custom dollar categories can be created and persist.
- Year rollover behavior works correctly.
- Dashboard dollar summary card navigates into the full tracker and values match.
- No USD data leaks into BDT surfaces.

## Phase 9: Lock Screen, Settings, and Final Polish

**Goal:** Finish launch gating, settings management, presentation polish, and release-readiness items last.

**Scope**

### Lock Screen
- Build biometric lock screen (`/lock` route) per the guide's Screen 0 spec:
  - "SPENDSPLIT" centered in teal, lock icon top-right.
  - Auth card (centered, glassmorphic): fingerprint icon with **animated pulse ring** (teal, radiating outward), "BIOMETRIC AUTHENTICATION" label, "Scan your fingerprint to unlock" heading.
  - 3×3 dot grid below the fingerprint icon (pattern fallback visual).
  - "Use Pattern" text button with grid icon (teal) at bottom.
- Use `local_auth` — prompt biometric on screen load. If biometric fails or is unavailable, show pattern/PIN fallback.
- Add startup route gating: if `biometric_enabled` is true in SharedPreferences, GoRouter redirects to `/lock` before allowing navigation to `/`.

### Settings Screen
- Build a **Settings screen** (push route from the gear icon on Dashboard and Monthly top bars). The Flutter guide does not specify a Settings screen layout, so use a simple glass-card list approach consistent with the design system:
  - **Biometric Lock** — toggle switch (enabled/disabled), updates `biometric_enabled` in SharedPreferences.
  - **Initial Balance** — tap to edit, numeric input for starting balance (৳), updates `initial_balance`.
  - **Dollar Annual Limit** — tap to edit, numeric input for USD limit ($), updates `dollar_annual_limit`. Shows current year.
- Add the `/settings` route to GoRouter (push, not a tab).

### Micro-interactions Inventory (Close the Loop)
Audit all screens and ensure the following effects from the Flutter guide are implemented. Check off any already done in earlier phases:
- [ ] **Number count-up animation** on Dashboard balance amounts (Phase 5).
- [ ] **Shimmer loading** skeletons on first data load (Phase 5).
- [ ] **Haptic feedback** on: FAB tap (Phase 1), save button (Phase 3), swipe delete confirm (Phase 4).
- [ ] **Spring physics** on bottom sheet open/close (`modal_bottom_sheet` handles this — verify it's configured).
- [ ] **Hero transitions** on the balance card if navigating to a detail view (add if applicable, skip if no navigation exists from the card).
- [ ] **Pull-to-refresh** on Dashboard (Phase 5).
- [ ] **Animated progress bar fills** — from 0 to current on screen appear, using `flutter_animate` (goals Phase 7, dollar tracker Phase 8).
- [ ] **Chart bar stagger animations** — bars grow upward with staggered delay (Phase 5, `fl_chart` built-in).

### Final Polish
- Replace generated launcher assets (Android + iOS) with `asset/app-icon.png`.
- Run `flutter analyze` and fix all lint warnings.
- Smoke test all screens end-to-end: create transactions, view history, filter, check dashboard calculations, create goals, add dollar expenses, toggle biometric lock.

**Primary references**

- [`asset/stitch_add_transaction_sheet/app_lock_clean/screen.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/app_lock_clean/screen.png)
- [`asset/stitch_add_transaction_sheet/app_lock_clean/code.html`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/stitch_add_transaction_sheet/app_lock_clean/code.html)
- [`asset/app-icon.png`](/Users/orion-abrar/Code/flutter_projects/spendsplit/asset/app-icon.png)

**Review checkpoint**

- App can launch with or without biometric protection based on settings.
- Settings screen is accessible from the gear icon and all three settings work.
- All micro-interactions from the checklist above are present.
- App icon is set on both platforms.
- No lint warnings remain.
- Visual polish is complete enough for a first full demo.

## Suggested Review Rhythm

Review after phases `1`, `3`, `5`, `7`, and `9`.

- Phase 1 review validates architecture and design direction.
- Phase 3 review validates the first end-to-end user flow.
- Phase 5 review validates the core product loop.
- Phase 7 review validates the planning experience.
- Phase 9 review validates release-readiness.

## Sequencing Rationale

- Foundation comes first because the repo has almost no app structure yet.
- **All four DAOs and repositories are created in Phase 2**, even for features built later (goals in Phase 7, dollar tracker in Phase 8). This ensures Phase 5's dashboard can query goal and dollar data without forward dependencies on unbuilt phases.
- Transaction capture comes before dashboard polish because summaries are only trustworthy after the write path works.
- The center FAB's non-navigation behavior is established in Phase 1 so that Phase 3's sheet trigger works immediately.
- Monthly analytics and goals depend on stable transaction data.
- The USD tracker is intentionally delayed because it must remain isolated and is easier to validate after the core BDT flow is finished.
- Biometric lock and settings are last because they are launch concerns, not dependencies for the financial workflows.
- Phase 5's dashboard gracefully handles forward dependencies: the goal preview card shows an empty state until Phase 7, and the dollar summary card shows zeroes until Phase 8 populates data.

## Unresolved Spec Gaps

These items are contradictions or gaps in the source design documents that need resolution during implementation:

1. **Font choice:** This chronology resolves to **Manrope** (per `DESIGN.md`). The Flutter guide says Inter. If the team prefers Inter, update Phase 1.
2. **Surface hex values:** This chronology uses the **Flutter guide's** `AppColors` values. `DESIGN.md` uses slightly different hex values for the same conceptual surface levels.
3. **Category spend classification:** The Flutter guide shows "RECURRING" / "FLEXIBLE" / "VARIABLE" / "ONE-TIME" labels on monthly category rows, but no database field supports this. Options: add a schema column, derive heuristically, or drop the labels.
4. **Settings screen:** No screen spec exists in the Flutter guide. Phase 9 defines a minimal implementation.
