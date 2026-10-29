---
name: SpendSplit
description: One bank balance split into Available and Savings, set as a gridded type specimen with coupon-ticket entries.
colors:
  ground: "#101113"
  surface: "#17181B"
  surface-light: "#1F2024"
  surface-raised: "#26272C"
  surface-highest: "#2C2D33"
  nav-bar: "#101113F0"
  grid-line: "#1C1E22"
  hairline: "#2A2C31"
  outline-variant: "#3A3C42"
  signal-orange: "#FF5A1F"
  signal-orange-bright: "#FF8452"
  on-signal: "#140A05"
  savings-bone: "#E8E4DC"
  savings-bone-dim: "#A9A59D"
  spend-magenta: "#FF3D6E"
  income-green: "#3DDC97"
  warning-yellow: "#FFC53D"
  usd-blue: "#4C7DFF"
  ink: "#F2F2F0"
  ink-secondary: "#A2A6AD"
  ink-tertiary: "#7C8088"
  on-surface-variant: "#C4C7CC"
  category-rosewood: "#B5677E"
  category-slate: "#7F93B0"
  category-sand: "#C9B48A"
  category-teal: "#4DB8AC"
  category-violet: "#9C8CFF"
  category-olive: "#A3B35C"
  category-clay: "#B98A6E"
  category-grey: "#62676F"
typography:
  figure:
    fontFamily: "Doto"
    fontSize: "88px"
    fontWeight: 900
    lineHeight: 0.9
    letterSpacing: "0em"
    fontFeature: "tnum"
    fontVariation: "'wght' 900"
  large-title:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.1
    fontFeature: "tnum"
  headline:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "22px"
    fontWeight: 700
    fontFeature: "tnum"
  title:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "20px"
    fontWeight: 600
    fontFeature: "tnum"
  headline-row:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "17px"
    fontWeight: 600
    fontFeature: "tnum"
  body:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.35
    fontFeature: "tnum"
  body-secondary:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.4
    fontFeature: "tnum"
  footnote:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.35
    fontFeature: "tnum"
  label:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "13px"
    fontWeight: 500
    letterSpacing: "0em"
    fontFeature: "tnum"
  button:
    fontFamily: "SF Pro, Roboto, system-ui"
    fontSize: "15px"
    fontWeight: 600
    fontFeature: "tnum"
rounded:
  module: "0px"
  stamp: "3px"
  sheet: "14px"
spacing:
  xxs: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "20px"
  xl: "24px"
  section: "28px"
  xxl: "32px"
  nav-clearance: "108px"
components:
  button-primary:
    backgroundColor: "{colors.signal-orange}"
    textColor: "{colors.on-signal}"
    typography: "{typography.button}"
    rounded: "{rounded.module}"
    height: "52px"
  button-primary-disabled:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.ink-tertiary}"
    rounded: "{rounded.module}"
    height: "52px"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.module}"
    height: "52px"
  tab-add:
    backgroundColor: "{colors.signal-orange}"
    textColor: "{colors.on-signal}"
    rounded: "{rounded.module}"
    width: "52px"
    height: "44px"
  panel:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.module}"
    padding: "16px"
  coupon-posted:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.module}"
    padding: "12px 14px"
    height: "60px"
  coupon-upcoming:
    backgroundColor: "transparent"
    textColor: "{colors.ink-tertiary}"
    rounded: "{rounded.module}"
    padding: "12px 14px"
  review-stamp:
    backgroundColor: "{colors.ground}"
    textColor: "{colors.spend-magenta}"
    rounded: "{rounded.stamp}"
    padding: "1px 6px"
  chip-filter:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.button}"
    rounded: "{rounded.module}"
    padding: "8px 14px"
    height: "36px"
  chip-filter-selected:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.ground}"
    rounded: "{rounded.module}"
  input-field:
    backgroundColor: "{colors.surface-light}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.module}"
  bottom-sheet:
    backgroundColor: "{colors.surface-light}"
    rounded: "{rounded.sheet}"
  tab-bar:
    backgroundColor: "{colors.nav-bar}"
    textColor: "{colors.ink-tertiary}"
    height: "49px"
  split-bar:
    height: "44px"
    rounded: "{rounded.module}"
---

# Design System: SpendSplit

## Overview

**Creative North Star: "The Grid Numerals Ticket Wallet"**

A Crouwel-style gridded type specimen, fused with a jet-age ticket wallet. Each screen may carry one monumental figure, built from Doto dot-grid numerals on a faint square construction grid whose cell is exactly one tenth of the figure size, so every dot lands in a cell. Everything else is small, exact and tabular: the platform sans (SF Pro on iOS, Roboto on Android) in iOS text-style sizes, with tabular figures throughout. Home's figure is Available; Goals and a goal's detail use a bone Savings figure; the Dollar Tracker uses a blue USD figure. The add sheet sets its amount entry as a dot-grid figure.

Colour works as a legend, not as decoration. Each saturated hue has one meaning and appears only where that meaning applies. Surfaces are square, flat modules one value step above a near-black ground; edges come from layering and hairlines, never from glow, gradient or shadow. Entries are coupons: a date stub, a perforation with two half-round notches, then the body. Their state is drawn as form: posted entries are solid, upcoming ones are dashed outlines, and SMS entries awaiting review carry a red rubber stamp.

Navigation is native iOS: large titles that collapse to inline titles on scroll, a floating frosted-glass icon-only tab bar, and the add action as a square orange block. Dark appearance only.

**Key Characteristics:**
- At most one dot-grid figure per screen, always on its construction grid.
- A strict colour legend: orange Available, bone Savings, green income, magenta-red spending, yellow warnings, blue USD.
- Square corners on every module; the only softness comes from coupon notches, the stamp and the platform sheet.
- Hairlines (0.5px) and flat value layering replace borders, glows and shadows.
- Entries are coupons whose state shows in their form.
- Platform sans with tabular figures, sentence case, no tracking.

## Colors

A near-black ground with value-stepped grey modules, plus six saturated legend hues. Each hue has exactly one job.

### Primary
- **Signal Orange** (signal-orange): the Available balance (hero figure, split-bar segment) and the primary action (Save, the centre + tab, a screen's single primary bar action, the unlock button). Switches, the text cursor, focus rings, selection and spinners are controls and draw in ink. Ink on orange is **On-Signal** (on-signal), a near-black, because white fails contrast there. **Signal Orange Bright** (signal-orange-bright) is its container and pressed tint only.

### Secondary
- **Savings Bone** (savings-bone): the Savings plane in the split bar, Savings figures and values, goal progress fills. **Bone Dim** (savings-bone-dim) is the tertiary role in the colour scheme.

### Tertiary (semantic legend)
- **Spend Magenta** (spend-magenta): spending, negative amounts, overdrawn Available, over-budget, delete, and the needs-review stamp.
- **Income Green** (income-green): income and positive amounts.
- **Warning Yellow** (warning-yellow): spending ahead of pace, deadlines, projected overspend, a stale USD allowance.
- **USD Blue** (usd-blue): the Dollar Tracker figure and bar, and USD values wherever they appear. Never used for taka.

### Category Ramp
A muted data series (rosewood, slate, sand, teal, violet, olive, clay, grey) held apart from the legend hues, so a category never reads as Available, income or spending. Older stored colours that collide with the legend are drawn as their nearest ramp colour, and the stored value is left unchanged.

### Neutral
- **Ground** (ground): the scaffold and large-title background.
- **Surface** (surface), **Surface Light** (surface-light), **Surface Raised** (surface-raised), **Surface Highest** (surface-highest): module layers in rising value. Panels and coupons sit on Surface; inputs, sheets and dialogs on Surface Light; snackbars and disabled fills on Surface Raised; bar tracks on Surface Highest.
- **Nav Bar** (nav-bar): a 94% Ground tint under the collapsed title bar.
- **Nav Glass** (nav-glass): a 28% #2C2D33 wash over the tab bar's blur, edged in 18% white.
- **Grid Line** (grid-line): the construction grid behind hero figures only.
- **Hairline** (hairline): 0.5px rules between rows, stat-strip dividers, bar edges. **Outline Variant** (outline-variant): the outlined button stroke, the sheet grabber and the coupon perforation.
- **Ink** (ink), **Ink Secondary** (ink-secondary), **Ink Tertiary** (ink-tertiary): primary text, secondary text and labels, and inactive tabs, upcoming stubs and hints.

### Named Rules
**The Legend Rule.** Every saturated hue has one meaning. If a colour would appear somewhere its meaning does not apply, use Ink or a neutral instead.

**The Orange Is Available Rule.** Signal Orange marks the Available balance and the single primary action on a screen. Nothing else: not selected filters, not icons, not decoration.

**The Controls Are Ink Rule.** Selection states for filters, segmented controls and active tabs invert to Ink on Ground or brighten to Ink. Controls are not data, so they carry no legend colour. A selected category tile takes its own ramp colour as an outline.

## Typography

**Display Font:** Doto (variable dot-grid face, OFL), hero figures only
**Body Font:** the platform sans (SF Pro on iOS, Roboto on Android), with no bundled substitute
**Label/Mono Font:** none distinct; tabular figures (`tnum`) on every style keep amounts aligned

**Character:** Doto is a specimen-sheet numeral built from square dots. The platform sans is quiet and native, so the one figure does all the shouting.

### Hierarchy
- **Figure** (Doto, weight 900, up to 88px on Home and 72px on Goals and the Dollar Tracker, line height 0.9 with even leading, no tracking): the hero number. Its size is floored so the whole final value fits the width. Doto has no ৳ glyph, so the currency sign is set in the platform sans (weight 600, 3.4 cells) inside a box four cells wide.
- **Large Title** (700, 34px, 1.1): the collapsing iOS title on each top-level tab.
- **Headline** (700, 22px): a goal name on its detail screen.
- **Title** (600, 20px): sheet and dialog titles.
- **Headline Row** (600, 17px): section headers, row amounts, stat-strip values.
- **Body** (400, 17px, 1.35): row titles. **Body Secondary** (400, 15px, 1.4, Ink Secondary): captions. **Footnote** (400, 13px, 1.35).
- **Label** (500, 13px, Ink Secondary, sentence case): stat-strip labels and split-bar percentages. **Button** (600, 15px).

### Named Rules
**The One Figure Rule.** Doto appears at most once per screen, always over its construction grid (cell = size / 10), with no letter spacing and the 0.9 even leading, so each dot sits in a whole cell. Don't use it for row amounts or labels.

**The Sentence Case Rule.** Labels and section titles use sentence case with no tracking ("Available", "This month"). The only uppercase, tracked text in the system is the UNCHECKED review stamp, which is a stamped object rather than a label.

## Layout

Single column with 16px page gutters (`PageBody`). Each top-level tab is a sliver scroll under a `CupertinoSliverNavigationBar` large title, which collapses inline and shows its material and a 0.5px hairline only once content scrolls under it. Spacing runs on a 4px base (4 / 8 / 12 / 16 / 20 / 24 / 32), with 28px between sections and 8px under a section header. Pages reserve 108px at the bottom so the last row, fully scrolled, clears the floating tab bar; rows pass under its glass while scrolling.

The hero zone sits on its own grid: label height, gaps and the currency box are all whole cells, so the figure's origin stays on a grid line. Related figures go side by side in a stat strip (label above value, 0.5px vertical hairlines with 12px gutters) instead of one card per number. Touch targets are at least 44pt; coupons are at least 60px tall.

## Elevation & Depth

Flat. No shadows anywhere: the colour scheme's shadow colour is transparent, and cards, app bars and the tab bar all have zero elevation. Depth comes only from value layering (Ground, then Surface, Surface Light, Surface Raised) and from platform blur: the collapsed title bar blurs what is behind it (sigma 24) under a 94% Ground tint with a 0.5px Hairline edge, and the floating tab bar is lighter frosted glass: a sigma 10 blur under a thin Nav Glass wash, so content shows through.

### Named Rules
**The No-Glow Rule.** No shadows, glows, gradients or orbs. If something needs to stand apart, raise its value one step or rule it with a hairline.

## Shapes

Square by default: every module, button, chip, input, coupon, bar and the centre add tab has a 0px radius. Three exceptions are allowed. The coupon notches are two 6px-radius half-circles cut from the top and bottom edges at the stub line. The review stamp has 3px corners and the sheet grabber has 3px rounded ends. Bottom sheets and dialogs keep the platform's 14px top corners. The split bar's one diagonal cut (10px slant, 3px gap) is the system's single oblique line. Outlined states use a 1.5px stroke; rules use 0.5px.

## Components

### Buttons
- **Shape:** square (0px), full width, 52px tall.
- **Primary:** Signal Orange fill, On-Signal text, 15px/600. One per screen or sheet (Save, Update).
- **Disabled:** Surface Raised fill, Ink Tertiary text.
- **Outlined:** transparent with a 1.5px Outline Variant stroke and Ink text, for secondary full-width actions.
- **Text:** at least 44×44pt. Section-header actions ("All", "Details") use On-Surface-Variant (on-surface-variant), not orange.

### Chips
- **Style:** square Surface module, 36px minimum height, 8px × 14px padding, Ink Secondary label.
- **State:** selected inverts to an Ink fill with Ground text. No legend colour.

### Cards / Containers
- **Corner Style:** square (0px).
- **Background:** Surface, one value step above Ground.
- **Shadow Strategy:** none (see Elevation & Depth).
- **Border:** none. Rows inside a panel are separated by an indented 0.5px Hairline.
- **Internal Padding:** 16px.

### Inputs / Fields
- **Style:** filled Surface Light, square, no stroke; hints in Ink Tertiary.
- **Focus:** a 1.5px Signal Orange outline.
- **Segmented type control (add sheet):** a Surface track; the selected segment inverts to Ink with Ground text.

### Navigation
- **Tab bar:** floats 16px in from each side and above the home indicator (at least 12px from the bottom edge), 60px tall, square, frosted glass (sigma 10 blur under Nav Glass) with a 0.5px Nav Glass Edge all round. Five icon-only tabs (24px Lucide line icons; the tab name goes to VoiceOver): Ink when active, Ink Tertiary when inactive. Order: Home, History, add, Monthly, Graphs, Goals, in six equal cells. The add cell holds a 52×44 square Signal Orange block with an On-Signal plus. Selection-click haptic on tab change, light-impact haptic on add.
- **Title bar:** iOS large title that collapses inline, with a trailing 44pt icon action (settings) or a screen's primary text action.

### Dot Figure (signature)
A label (15px/600, Ink Secondary) sitting on whole cells, then an optional sans currency box and Doto numerals, all painted over a Grid Line construction grid with cell = size / 10. The figure counts up over 650ms, and its size is fixed from the final value so the grid stays still while it counts. Colour follows the legend: orange for Available (magenta-red when overdrawn), bone for Savings and goal funding, blue for USD (magenta-red when over the allowance), and on the add sheet the colour of the entry type.

### Coupon (signature)
A 64px stub (date or time, centred) and a perforation (1.5px dashes, 3px on and 4px off, in Outline Variant) with 6px notches top and bottom, then the body with 12px × 14px padding. **Posted:** solid Surface Raised, one step above panels so entries stand off the ground. **Upcoming:** no fill, dashed 1.5px Ink Tertiary outline (5px on, 4px off), tertiary stub. **Needs review:** solid, with the UNCHECKED stamp: Ground fill, 1.5px Spend Magenta stroke, 11px/800 caps, rotated -0.07rad, overhanging the top edge by 7px.

### Split Bar (signature)
A 44px bar showing Available (orange) and Savings (bone) at their true proportion, joined by one diagonal cut. It fills over 700ms with ease-out-expo. Percentages appear underneath in Label style. When there is nothing to split, it shows a Hairline outline and "Nothing to split yet".

### Progress Bars
Flat bars: a square fill on a Surface Highest track, 6–8px tall, filling once over 700ms with ease-out-expo; zero duration under Reduce Motion. Budget bars add a 2px Ink tick at the month-pace share and turn Warning Yellow when spending is ahead of pace and Spend Magenta when over budget.

## Do's and Don'ts

### Do:
- **Do** give a screen at most one Doto figure, on its construction grid with cell = size / 10.
- **Do** colour by the legend: orange for Available and the primary action, bone for Savings, green for income, magenta-red for spending and stamps, yellow for warnings, blue for USD.
- **Do** draw entries as coupons and show their state as form: solid, dashed, or stamped.
- **Do** keep every module square and separate modules with value steps and 0.5px Hairlines.
- **Do** use the platform sans with tabular figures, in sentence case.
- **Do** use native iOS structure: collapsing large titles, a floating frosted icon-only tab bar, 44pt targets, and VoiceOver labels on figures and bars.
- **Do** honour Reduce Motion by setting fills and count-ups to zero duration.

### Don't:
- **Don't** use Signal Orange for selection states, icons, filters or decoration.
- **Don't** use USD Blue for anything taka, or the legend hues for categories.
- **Don't** add shadows, glows, gradients, glass orbs or rounded cards.
- **Don't** set row amounts, labels or titles in Doto, or track or letter-space Doto.
- **Don't** add uppercase tracked eyebrow labels above titles or figures.
- **Don't** add 1px borders around posted modules; outlines belong only to state (upcoming, focus, stamp, selected tile).
