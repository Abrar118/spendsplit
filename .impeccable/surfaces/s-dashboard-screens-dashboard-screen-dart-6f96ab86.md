---
version: 1
slug: "s-dashboard-screens-dashboard-screen-dart-6f96ab86"
primary_target: "lib/features/dashboard/screens/dashboard_screen.dart"
related_targets: ["lib/features/transactions/screens/transactions_screen.dart","lib/features/monthly/screens/monthly_screen.dart","lib/features/goals/screens/goals_screen.dart","lib/features/transactions/widgets/add_transaction_sheet.dart"]
---

# Surface brief: SpendSplit app (Home first, then History, Monthly, Goals, add sheet)

Scope: whole app redesign, Operate mode, iOS-first Flutter, dark only. Home leads; the other tabs and the add sheet inherit the same world.
Audience/job: the owner checks Available, logs purchases, reviews bank-SMS entries, reviews the month, keeps savings separate, tracks USD allowance.
Constraints: native controls and navigation; Dynamic Type; 44pt targets; VoiceOver labels; Dollar Tracker stays visually and numerically separate.
Chosen: Grid Numerals (user choice over the roll), with coupon-wallet entry states folded in at the user's request.
Memorable moment: one monumental dot-grid Available figure over a construction grid, and the split bar cut on a diagonal.

## Direction contract

THESIS: Available is the one monumental figure, built from dots on a visible construction grid; everything else is small, exact and tabular. Refuses the gradient-card-plus-glowing-stat-tiles fintech dashboard.

OWN-WORLD: near-black ground with a faint square construction grid behind hero figures only; ink white; signal orange only for Available and the primary action; bone plane for Savings; green income; magenta-red spending and stamps; yellow warnings; blue only for USD. Dot-grid numerals for hero figures, the platform sans with tabular figures for everything else. Square-cornered modules, hairline rules, no glows, no gradients. Entries are coupons: date stub, perforation, body; posted solid, upcoming dashed, needs-review stamped.

STORY: open, read Available in one glance, see how the balance splits, see what needs review, log with +.

FIRST VIEWPORT: large title Home with settings; Available label then ৳ and a ~88pt dot-grid figure over the grid; full-width split bar, orange Available meeting bone Savings on one diagonal cut at true proportion, percentages under it; Savings and Total line; review coupons when any; This month table (income, spent, to savings). Native-style labelled tab bar, orange + in the centre.

FORM: catalog challenger crouwel-grid-specimen chosen by the user (not on the grounded list), fused with vernacular-ephemera-jet-age-ticket-wallet coupon states at the user's request. seed: d2f33dabe2ce722c

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
