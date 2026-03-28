# SpendSplit — Flutter Implementation Guide

## Overview

**SpendSplit** is a minimalist, offline-only mobile expense tracker. Single bank account balance split into Available (spendable) and Savings. Dark theme, modern glassmorphic UI, biometric lock, and a separate USD spending tracker.

**Platform:** Flutter (Android-first, iOS compatible)
**State Management:** Riverpod
**Database:** Drift (SQLite)
**Architecture:** Feature-first with MVVM

---

## Tech Stack & Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Database (SQLite)
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.21
  path_provider: ^2.1.3
  path: ^1.9.0

  # Navigation
  go_router: ^14.2.0

  # UI & Charts
  fl_chart: ^0.68.0              # Bar charts, pie/donut charts, line charts
  google_fonts: ^6.2.1           # Inter or custom typography
  flutter_animate: ^4.5.0        # Micro-interactions, shimmer, transitions
  shimmer: ^3.0.0                # Skeleton loading
  gap: ^3.0.1                    # Spacing widget
  intl: ^0.19.0                  # Date/number formatting

  # Biometric Auth
  local_auth: ^2.2.0             # Fingerprint + face + pattern fallback

  # Icons
  lucide_icons: ^0.257.0         # Clean rounded icon set (or use flutter_icons)

  # Haptics & Feedback
  vibration: ^2.0.0              # Haptic feedback on actions

  # Swipe Actions
  flutter_slidable: ^3.1.0       # Swipe-to-delete/edit on transaction cards

  # Bottom Sheet
  modal_bottom_sheet: ^3.0.0     # Smooth modal bottom sheets

  # Storage (simple key-value for settings)
  shared_preferences: ^2.2.3     # App lock toggle, dollar limit, preferences

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.18.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  flutter_linter: ^3.0.0
```

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + GoRouter + Theme
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData, dark theme
│   │   ├── app_colors.dart           # All color constants
│   │   ├── app_typography.dart       # Text styles
│   │   └── app_decorations.dart      # Card decorations, gradients, glassmorphism
│   ├── constants/
│   │   ├── categories.dart           # Predefined categories + icons + colors
│   │   └── enums.dart                # TransactionType, GoalStatus, etc.
│   ├── utils/
│   │   ├── currency_formatter.dart   # ৳ and $ formatting
│   │   ├── date_utils.dart           # Month names, relative dates
│   │   └── extensions.dart           # Helpful extensions
│   └── widgets/
│       ├── glass_card.dart           # Reusable glassmorphic card
│       ├── accent_chip.dart          # Filter/type chips
│       ├── bottom_nav_bar.dart       # Floating bottom navbar
│       ├── empty_state.dart          # Empty state illustrations
│       └── amount_text.dart          # Colored amount display widget
│
├── data/
│   ├── database/
│   │   ├── app_database.dart         # Drift database class
│   │   ├── tables/
│   │   │   ├── transactions_table.dart
│   │   │   ├── categories_table.dart
│   │   │   ├── savings_goals_table.dart
│   │   │   └── dollar_expenses_table.dart
│   │   └── daos/
│   │       ├── transaction_dao.dart
│   │       ├── category_dao.dart
│   │       ├── savings_goal_dao.dart
│   │       └── dollar_expense_dao.dart
│   ├── models/                       # Data classes / freezed models if needed
│   └── repositories/
│       ├── transaction_repository.dart
│       ├── savings_repository.dart
│       └── dollar_tracker_repository.dart
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   └── lock_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── dashboard/
│   │   ├── screens/
│   │   │   └── dashboard_screen.dart
│   │   ├── widgets/
│   │   │   ├── balance_card.dart           # Hero card with total/available/savings
│   │   │   ├── monthly_snapshot_row.dart   # Income/Spent/Saved compact cards
│   │   │   ├── spending_chart.dart         # 12-month bar chart
│   │   │   ├── active_goal_card.dart       # Goal progress preview
│   │   │   └── dollar_summary_card.dart    # Dollar tracker mini card
│   │   └── providers/
│   │       └── dashboard_provider.dart
│   │
│   ├── transactions/
│   │   ├── screens/
│   │   │   └── transactions_screen.dart
│   │   ├── widgets/
│   │   │   ├── transaction_tile.dart       # Single transaction row
│   │   │   ├── filter_chips_row.dart       # All/Income/Expense/Savings
│   │   │   ├── filter_bottom_sheet.dart    # Advanced filters
│   │   │   └── add_transaction_sheet.dart  # New Entry bottom sheet
│   │   └── providers/
│   │       └── transactions_provider.dart
│   │
│   ├── monthly/
│   │   ├── screens/
│   │   │   └── monthly_screen.dart
│   │   ├── widgets/
│   │   │   ├── month_selector.dart         # ← March 2026 →
│   │   │   ├── summary_cards.dart          # Colored income/expense/saved cards
│   │   │   ├── category_donut_chart.dart   # Donut with top category label
│   │   │   └── category_detail_list.dart   # Sorted category breakdown rows
│   │   └── providers/
│   │       └── monthly_provider.dart
│   │
│   ├── goals/
│   │   ├── screens/
│   │   │   └── goals_screen.dart
│   │   ├── widgets/
│   │   │   ├── savings_banner.dart         # Total savings reserved card
│   │   │   ├── goal_card.dart              # Active goal with progress bar
│   │   │   ├── overall_progress_ring.dart  # 54% overall ring + milestone text
│   │   │   ├── completed_goals_section.dart
│   │   │   └── create_goal_sheet.dart      # New/edit goal bottom sheet
│   │   └── providers/
│   │       └── goals_provider.dart
│   │
│   └── dollar_tracker/
│       ├── screens/
│       │   └── dollar_tracker_screen.dart
│       ├── widgets/
│       │   ├── dollar_header_card.dart     # Limit/Spent/Remaining + ring
│       │   ├── dollar_transaction_tile.dart
│       │   └── add_dollar_expense_sheet.dart
│       └── providers/
│           └── dollar_tracker_provider.dart
│
└── providers/
    └── providers.dart                # Global Riverpod providers (database, repos)
```

---

## Design System — Dark Theme

### Colors (`app_colors.dart`)

```dart
abstract class AppColors {
  // Backgrounds
  static const background = Color(0xFF0A0E1A);        // Deep dark navy
  static const surface = Color(0xFF141829);            // Card surfaces
  static const surfaceLight = Color(0xFF1C2137);       // Elevated surfaces, sheets
  static const navBar = Color(0xFF0F1322);             // Bottom nav background

  // Primary Accents
  static const teal = Color(0xFF00E5BF);               // Primary actions, available balance
  static const coral = Color(0xFFFF6B6B);              // Expenses, negative, delete
  static const green = Color(0xFF34D399);              // Income, positive amounts
  static const purple = Color(0xFF9C7CFF);             // Savings, goal progress
  static const amber = Color(0xFFFBBF24);              // Warnings, deadlines, dollar ring
  static const blue = Color(0xFF60A5FA);               // Charts, secondary highlights

  // Text
  static const textPrimary = Color(0xFFF1F5F9);       // White text
  static const textSecondary = Color(0xFF8892A7);      // Muted labels
  static const textTertiary = Color(0xFF4A5568);       // Captions, timestamps

  // Borders & Dividers
  static const border = Color(0x0FFFFFFF);             // ~6% white
  static const divider = Color(0x0AFFFFFF);            // ~4% white

  // Category Colors
  static const catFood = Color(0xFFFF6B6B);            // Coral
  static const catTransport = Color(0xFF60A5FA);       // Blue
  static const catUtilities = Color(0xFFFBBF24);       // Amber
  static const catHealth = Color(0xFFF472B6);          // Pink
  static const catShopping = Color(0xFF9C7CFF);        // Purple
  static const catOther = Color(0xFF8892A7);           // Gray

  // Gradients
  static const balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1B69), Color(0xFF1A1040)],    // Purple gradient (credit card)
  );

  static const incomeCardGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
  );

  static const expenseCardGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  static const savingsCardGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  );
}
```

### Typography (`app_typography.dart`)

```dart
// Use Google Fonts — Inter for clean modern look
// Headlines: Bold, 24–32sp for balance amounts
// Subheadings: SemiBold, 16–18sp for section titles
// Body: Regular, 14sp for details
// Caption: Regular, 11–12sp for dates, labels
// All caps tracking: 1.5 for labels like "TOTAL BALANCE", "ENTER AMOUNT"
```

### Card Decorations (`app_decorations.dart`)

```dart
// Glassmorphic card decoration
BoxDecoration glassCard({Color? glowColor}) => BoxDecoration(
  color: AppColors.surface.withOpacity(0.8),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.border),
  boxShadow: [
    BoxShadow(
      color: (glowColor ?? Colors.black).withOpacity(0.15),
      blurRadius: 24,
      offset: Offset(0, 4),
    ),
  ],
);
```

---

## Screen Specifications

---

### Screen 0: Lock Screen (Biometric Auth)

**Route:** `/lock` — shown on app launch if biometric is enabled

**Layout (top to bottom):**
1. **Top bar:** "SPENDSPLIT" centered in teal, lock icon top-right
2. **Auth card** (centered, glassmorphic):
   - Fingerprint icon (teal, animated pulse ring around it)
   - Label: "BIOMETRIC AUTHENTICATION" (all caps, muted, tracked)
   - Heading: "Scan your fingerprint to unlock" (white, bold, 20sp)
   - 3×3 dot grid below (for pattern fallback visual)
3. **Bottom:** "Use Pattern" text button with grid icon (teal)

**Behavior:**
- Uses `local_auth` package — prompt biometric on screen load
- If biometric fails or unavailable → show pattern/PIN fallback
- Auth toggle lives in settings (stored in SharedPreferences)
- First launch: no auth, user can enable it later

---

### Screen 1: Dashboard (Home)

**Route:** `/` — default tab

**Layout (top to bottom, scrollable):**

#### 1.1 — Top Bar
- Left: Hamburger menu icon (☰) — opens a minimal drawer or does nothing for MVP
- Center-left: "SpendSplit" in bold white (18sp)
- Right: Settings gear icon

#### 1.2 — Balance Card (Hero)
A full-width card with **purple gradient** background styled like a bank/credit card:
- Top-left: Bank name placeholder "Trust Bank PLC" + "BANGLADESH" subtitle (muted)
- Top-right: Gold/yellow card chip icon
- Center: "TOTAL BALANCE" label (all caps, muted, tracked) → `৳ 84,250` (bold white, 36sp)
- Bottom-left: Masked card number `4532 •••• •••• 8291`
- Bottom-right: "Visa" logo text + contactless icon
- Card has rounded 20dp corners and subtle inner shadow

#### 1.3 — Available / Savings Split
Directly below the card, two columns separated by a thin vertical divider:
- **Left:** "AVAILABLE" label (muted, caps) → `৳ 52,100` in teal
- **Right:** "SAVINGS" label (muted, caps) → `৳ 32,150` in purple

#### 1.4 — This Month Snapshot Row
Horizontally scrollable row of compact glass cards:
- **Income:** Green up-arrow icon in a circle → "INCOME" label → `৳ 42k`
- **Spent:** Coral down-arrow icon → "SPENT" label → `৳ 18k`
- **Saved:** Purple piggy/arrow icon → "SAVED" label → `৳ 24k` (or calculated)

Each card: ~120w × 100h, rounded 16dp, glass surface, colored icon circle

#### 1.5 — Spending Overview (Bar Chart)
Glass card containing:
- Header row: "Spending Overview" (bold white, left) + "DETAILS" link (teal, right)
- **fl_chart BarChart:** 12 bars for Jan–Dec
- Bar color: Teal gradient, current month highlighted (brighter + slightly taller visual weight)
- X-axis: J F M A M J J A S O N D — current month label in **bold teal**
- Y-axis: Hidden (clean look) — amounts shown on tap via tooltip
- Empty months: Very short dark gray placeholder bars

#### 1.6 — Active Goal Preview Card
Glass card with left teal/purple accent border:
- Goal name bold (e.g., "New Home Fund")
- "45 DAYS LEFT" muted label with clock icon
- `৳ 34,000 / ৳ 50,000` with **68%** in teal on the right
- Horizontal progress bar: teal/purple gradient fill, rounded, on dark track

#### 1.7 — Dollar Tracker Summary Card
Glass card with a **dollar icon** in a teal circle:
- "Travel Allowance" title + "Limit: $12,000" subtitle
- Two columns: **SPENT** `$2,500` in coral | **REMAINING** `$9,500` in green
- Thin horizontal progress bar (blue fill on dark track)
- Tapping navigates to full Dollar Tracker screen

---

### Screen 2: Transactions (History)

**Route:** `/transactions` — second tab

**Layout:**

#### 2.1 — Top Bar
- Left: Hamburger icon
- Center: "Transactions" (bold, white, 20sp)
- Right: Filter funnel icon → opens filter bottom sheet

#### 2.2 — Filter Chips Row
Horizontal scroll, chips:
- **All** (filled teal bg, white text when selected)
- **Income** (outlined gray when unselected)
- **Expense**
- **Savings**

#### 2.3 — Transaction List (grouped by date)
Sticky date headers: "TODAY", "YESTERDAY", "MARCH 25, 2026" (all caps, muted, 11sp, tracked)

Each transaction tile (glass card style, full width):
- **Left edge:** 3dp thick colored vertical accent bar (coral for expense, green for income, purple for savings, amber for savings withdrawal)
- **Icon:** Colored circle with category icon (40dp)
- **Title:** Transaction name/description (bold white, 16sp)
- **Subtitle:** Category • Date • Time (muted, 12sp)
- **Right:** Amount with sign and color:
  - Expense: `- $42.50` in coral
  - Income: `+ $850.00` in green
  - Savings deposit: `↓ $200.00` in purple
  - Savings withdrawal: `↑ $500.00` in amber

**Swipe actions** (flutter_slidable):
- Swipe left → red Delete action with trash icon
- Swipe right → blue Edit action with pencil icon

#### 2.4 — Filter Bottom Sheet
Triggered by funnel icon:
- **Type:** Checkboxes — Income, Expense, Savings
- **Category:** Chip grid of all categories (predefined + custom)
- **Date Range:** Two date pickers (From / To)
- **Apply** button (teal, full width) + **Reset** text link

---

### Screen 3: Add Transaction (Bottom Sheet)

**Trigger:** Center "+" FAB in navbar — opens `modal_bottom_sheet` covering ~75% screen

#### 3.1 — Sheet Header
- "New Entry" title (bold white, 22sp, left-aligned)
- Close button (X icon) top-right
- Drag handle bar centered at top

#### 3.2 — Transaction Type Selector
Three pill tabs in a row inside a dark rounded container:
- **EXPENSE** — coral fill when selected, white text
- **INCOME** — green fill when selected
- **SAVINGS** — purple fill when selected
- Unselected: transparent, muted text, subtle border

#### 3.3 — Amount Input
- "ENTER AMOUNT" label (all caps, muted, tracked, centered)
- Large amount display: `৳` symbol (teal, 28sp) + amount number (bold white, 48sp)
- Tapping opens numeric keyboard
- Amount has a subtle glow effect matching the selected type color

#### 3.4 — Category Selector (Expense type only)
- "SELECT CATEGORY" label (left) + "VIEW ALL" link (teal, right)
- Horizontal scrollable row of category icons:
  - Each: rounded square (56dp) with icon inside, label below
  - Selected: filled with category color, slight glow
  - Unselected: dark surface with gray icon
  - Categories: Food (🍴), Transport (🚗), Utilities (⚡), Health (🏥), Shopping (🛍), Other (+)
  - Last item: "+ Custom" to add new category

**Income type:** Source chips — "Salary", "Freelance", "Other"
**Savings type:** Sub-type toggle — "Deposit" | "Withdrawal"

#### 3.5 — Date Picker
Glass card row:
- Calendar icon (left)
- "DATE" label (muted) + "Today, Oct 24 2023" value (white)
- Chevron right (→)
- Tapping opens date picker dialog

#### 3.6 — Note Field (below date, optional)
- Simple text input with hint "Add a note..." (muted)
- Single line, minimal styling

#### 3.7 — Save Button
- Full-width rounded button at sheet bottom
- Color matches selected type (coral/green/purple)
- Text: "Save Transaction" (white, bold)
- On save: dismiss sheet + haptic feedback + snackbar confirmation

---

### Screen 4: Monthly View

**Route:** `/monthly` — fourth tab

#### 4.1 — Top Bar
- Left: Hamburger
- Center: "SpendSplit" in bold
- Right: Settings gear

#### 4.2 — Month Navigator
- "FISCAL PERIOD" muted label (centered, caps, tracked)
- **← March 2026 →** with left/right arrow buttons
- Swipe gesture to change months

#### 4.3 — Summary Cards (stacked vertically, full width each)
Three cards, each full width with colored gradient background and rounded 16dp:

| Card | Gradient | Content |
|------|----------|---------|
| **Total Income** | Green gradient | `৳ 84,500` bold white + `+12% FROM LAST MONTH` with up-trend icon |
| **Total Expenses** | Coral/red gradient | `৳ 32,180` bold white + `-4% FROM LAST MONTH` with down-trend icon |
| **Amount Saved** | Purple gradient | `৳ 52,320` bold white + `62% SAVINGS RATE` with shield icon |

Each card ~100h, amount is 28sp bold, percentage comparison in small chip/badge

#### 4.4 — Category Donut Chart
Section title: "Where your money went" with a teal left accent bar

Glass card containing:
- **fl_chart PieChart** — donut style (thick ring, hollow center)
- Center text: "TOP CATEGORY" label (muted) + category name bold (e.g., "Housing")
- Ring segments colored by category colors
- Teal as the dominant segment color for the largest category

Below chart: "42 transactions this month" (muted) + "View all →" link (teal)

#### 4.5 — Category Details List
Section title: "Category Details" (left) + "SORTED BY VOLUME" (muted, right)

Each row (glass card style):
- Left: thick colored vertical bar (4dp) matching category color
- **Category name** bold (16sp)
- Subtitle: "RECURRING" / "FLEXIBLE" / "VARIABLE" / "ONE-TIME" (muted, caps)
- Right: `৳ 15,000` amount (white, bold) + `48.6% OF TOTAL` (muted, below)

Sorted descending by amount.

---

### Screen 5: Savings Goals

**Route:** `/goals` — fifth tab

#### 5.1 — Top Bar
- Left: Hamburger icon
- Center-left: "Savings Goals" bold white
- Right: "+ New Goal" text button in teal

#### 5.2 — Total Savings Banner
Full-width glass card with purple tint:
- "TOTAL SAVINGS RESERVED" (muted, caps, tracked)
- `৳ 84,200` large bold purple text (32sp)
- Green chip/badge: `+12% this month` with trend arrow
- "Across 5 active goals" subtitle (muted)

#### 5.3 — Active Goals Section
Section title: "Active Ambitions" (bold, left) + "PRIORITY VIEW" (muted, right)

Each goal card (glass card, full width):
- **Top row:** Goal name bold (18sp) + three-dot menu (⋮) + goal icon (colored square)
- Subtitle: Clock icon + "45 days remaining" or calendar icon + "Summer 2024" (muted)
- **Amount row:** `৳ 34,000` bold white + `/ ৳ 50,000` muted + **68%** in teal (right-aligned)
- **Progress bar:** Horizontal, rounded, teal/blue gradient fill on dark track

#### 5.4 — Completed Goals
Collapsible section:
- Green checkmark icon + "Completed Goals" + count badge + chevron (▾ / ▸)
- When expanded: muted goal cards with strikethrough or dimmed styling

#### 5.5 — Overall Progress Ring
Large glass card at bottom:
- **fl_chart** or custom painted arc — circular progress ring (teal gradient)
- Center: "OVERALL" label (muted) + **54%** large bold teal (36sp)
- Below the ring: "On track for your milestones" heading (bold white)
- Body text: "Based on your average monthly savings of ৳ 8,500, you'll reach your 'New Mac Pro' goal in approximately 2 months." (muted, 14sp)
- "Adjust strategy" link in teal

#### 5.6 — Create/Edit Goal Bottom Sheet
Fields:
- Goal name text input
- Target amount (numeric, ৳ prefix)
- Deadline toggle ("Set deadline" switch) → date picker if on
- Icon picker (optional, grid of emoji/icons)
- **Save Goal** button (purple, full width)

---

### Screen 6: Dollar Tracker

**Route:** `/dollar-tracker` — navigated from Dashboard dollar card tap

**IMPORTANT:** This is completely isolated from main BDT calculations. No cross-contamination with graphs, monthly summaries, or balance calculations.

#### 6.1 — Top Bar
- Back arrow (←) + "Dollar Tracker" centered + year label "2026"

#### 6.2 — Header Card
Dark navy gradient card with circular progress ring:
- **Circular ring** (right side): amber/yellow fill showing % used, dark track
- Center of ring: **21%** "UTILIZED" (or percentage used)
- Left side of card:
  - "REMAINING BALANCE" label (muted, caps)
  - `9,500` large bold white (no $ needed, context is clear)
  - Below: "ANNUAL LIMIT" → `$12,000` | "SPENT YTD" → `$2,500` in teal

#### 6.3 — Add Dollar Expense
"+ ADD EXPENSE" button — outlined teal with plus icon, or teal FAB

#### 6.4 — Recent Dollar Transactions
Same card style as main transactions but amounts in `$`:
- Left colored accent bar (category-based)
- Icon circle + title + category/date
- Amount right-aligned: `$184.50`

#### 6.5 — Add Dollar Expense Bottom Sheet
Fields:
- Amount in USD ($ prefix, numeric input)
- Purpose (text input — e.g., "Figma subscription")
- Category chips (custom categories: "Tuition", "Software", "Course", "Hardware", etc.)
- "+ New Category" chip to add custom
- Date picker
- **Save** button (teal)

---

## Floating Bottom Navigation Bar

**Widget:** Custom `BottomNavBar` — not the default Material `BottomNavigationBar`

**Appearance:**
- Floating above content with 16dp horizontal margin, 12dp bottom margin
- Solid dark background (`#0F1322`) with rounded 24dp corners (pill shape)
- Subtle top border: `rgba(255,255,255,0.06)`
- Shadow: `0 -4px 20px rgba(0,0,0,0.3)`

**5 Items:**

| Position | Icon | Label | Active Color |
|----------|------|-------|-------------|
| 1 | Home (filled) | HOME | Teal |
| 2 | Receipt/list | HISTORY | Teal |
| 3 | **+ (raised circle)** | ADD | Teal bg, white icon |
| 4 | Calendar/grid | MONTHLY | Teal |
| 5 | Flag | GOALS | Teal |

- **Center FAB:** Raised circular button (48dp), teal filled, white "+" icon, slightly overlaps top edge of navbar
- **Active tab:** Teal icon + label visible + small teal dot below icon
- **Inactive tab:** Gray icon, label in muted gray
- Labels: All caps, 10sp, tracked

---

## Database Schema (Drift Tables)

### transactions_table

| Column | Type | Notes |
|--------|------|-------|
| id | int (auto-increment) | Primary key |
| type | text (enum) | 'income', 'expense', 'savings_deposit', 'savings_withdrawal' |
| amount | real | Always positive, sign determined by type |
| category_id | int (nullable) | FK to categories, null for income/savings |
| source | text (nullable) | For income: 'salary', 'freelance', 'other' |
| note | text (nullable) | Optional note |
| date | dateTime | Transaction date |
| created_at | dateTime | Auto-set on insert |

### categories_table

| Column | Type | Notes |
|--------|------|-------|
| id | int (auto-increment) | Primary key |
| name | text | Category name |
| icon | text | Icon identifier string |
| color | int | Color value as int |
| is_predefined | bool | true for default 6 categories |
| is_dollar_category | bool | true if used in dollar tracker only |

**Seed data:** Food, Transport, Utilities, Health, Shopping, Other (is_predefined = true)

### savings_goals_table

| Column | Type | Notes |
|--------|------|-------|
| id | int (auto-increment) | Primary key |
| name | text | Goal name |
| target_amount | real | Target in BDT |
| deadline | dateTime (nullable) | Optional deadline |
| is_completed | bool | Default false |
| completed_at | dateTime (nullable) | When marked complete |
| created_at | dateTime | Auto-set |

### dollar_expenses_table

| Column | Type | Notes |
|--------|------|-------|
| id | int (auto-increment) | Primary key |
| amount | real | Amount in USD |
| purpose | text | Description |
| category_id | int | FK to categories (where is_dollar_category = true) |
| date | dateTime | Expense date |
| created_at | dateTime | Auto-set |

### app_settings (SharedPreferences keys)

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `biometric_enabled` | bool | false | Lock screen toggle |
| `dollar_annual_limit` | double | 12000.0 | USD annual spending limit |
| `dollar_limit_year` | int | current year | Which year the limit applies to |
| `initial_balance` | double | 0.0 | Starting balance when app first used |

---

## Calculated Values (not stored, derived)

```
Total Balance = initial_balance
              + SUM(income amounts)
              - SUM(expense amounts)

Savings Balance = SUM(savings_deposit amounts)
                - SUM(savings_withdrawal amounts)

Available Balance = Total Balance - Savings Balance

This Month Income = SUM(income amounts WHERE date is current month)
This Month Expenses = SUM(expense amounts WHERE date is current month)
This Month Saved = SUM(savings_deposit WHERE current month)
                 - SUM(savings_withdrawal WHERE current month)

Dollar Spent YTD = SUM(dollar_expenses WHERE year = dollar_limit_year)
Dollar Remaining = dollar_annual_limit - Dollar Spent YTD
```

---

## Navigation (GoRouter)

```dart
/ (ShellRoute with BottomNavBar)
├── /                    → DashboardScreen (index 0)
├── /transactions        → TransactionsScreen (index 1)
├── /monthly             → MonthlyScreen (index 3)
├── /goals               → GoalsScreen (index 4)
└── /dollar-tracker      → DollarTrackerScreen (push, not tab)

/lock                    → LockScreen (initial route if biometric enabled)
```

The center "+" tab (index 2) does NOT navigate — it triggers `showModalBottomSheet` for AddTransactionSheet.

---

## Edit/Delete Patterns

- **Edit:** Tap transaction → opens AddTransactionSheet pre-filled → button says "Update"
- **Delete:** Swipe left → red delete panel → on confirm → snackbar "Deleted" with **Undo** (3 seconds to undo, then permanent delete)
- **Goals:** Three-dot menu → Edit (opens sheet) / Mark Complete / Delete (confirmation dialog)

---

## Empty States

Each list screen shows a centered empty state when no data:

| Screen | Illustration | Text |
|--------|-------------|------|
| Transactions | Empty wallet line art | "No transactions yet.\nTap + to add your first one." |
| Monthly | Empty calendar | "No data for this month." |
| Goals | Target with arrow | "Set your first savings goal!" |
| Dollar Tracker | Globe with $ | "No foreign expenses tracked yet." |

Use `flutter_animate` for a subtle fade-in + slide-up on empty states.

---

## Micro-interactions & Polish

- **Number count-up animation** on Dashboard balance amounts (on screen load / pull-to-refresh)
- **Shimmer loading** skeletons on first data load (shimmer package on glass cards)
- **Haptic feedback** on: FAB tap, save button, swipe delete confirm
- **Spring physics** on bottom sheet open/close (modal_bottom_sheet handles this)
- **Hero transitions** on balance card if navigating to a detail view
- **Pull-to-refresh** on Dashboard (recalculates all derived values from DB)
- **Animated progress bars** — fill from 0 to current on screen appear (flutter_animate)
- **Chart bar animations** — bars grow upward with staggered delay (fl_chart built-in)

---

## What NOT to Implement

- ❌ Cloud sync / backup
- ❌ Multiple accounts
- ❌ Notifications / reminders
- ❌ Recurring transactions
- ❌ Currency conversion (dollar tracker is flat USD, no BDT conversion)
- ❌ Dark/light mode toggle (dark only)
- ❌ Onboarding tutorial
- ❌ Export to CSV/PDF (can add later)
- ❌ Widgets (home screen widgets — can add later)
