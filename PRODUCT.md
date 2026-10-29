# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

Flutter app shipping to iOS and Android. iOS conventions lead (the owner uses an iPhone 17); Android receives the same screens. Dark appearance only.

## Users

The owner: one person in Bangladesh with a single Trust Bank account, tracking their own money on their phone. The app may be published for other people in Bangladesh later, so nothing should assume it can only ever be one person's tool, but there are no other users today.

## Product Purpose

SpendSplit splits one real bank balance into two: Available (money that can be spent) and Savings (money set aside). It answers "what can I actually spend right now?" without a second bank account, while keeping a full record of income, spending, savings and goals. It is offline-only; nothing leaves the device.

Success: a glance at Home gives a trustworthy Available number; logging a purchase takes seconds; bank SMS alerts become reviewed entries with little effort; the month can be reviewed at a glance.

## Positioning

One account, split in software. Savings is a ledger inside the same balance, not a separate account, so Available = Total − Savings at all times. Bank SMS import and balance reconciliation keep that number honest against the real bank balance.

## Operating Context

Why the owner opens the app, all confirmed:
- Check what can be spent (Available) before or after buying something.
- Log a purchase right after paying (center "+" opens the add sheet).
- Review entries created from Trust Bank SMS alerts (flagged `needs_review`).
- Review the month: where money went, category budgets, savings progress.
- Keep savings and current (available) money separate: deposits, withdrawals, goals.
- Track USD card spending against a yearly allowance (Dollar Tracker), fully separate from taka.

SMS arrives on Android via a receiver; on iOS via a user-built Shortcuts automation that drops alert files into the app's Documents folder.

## Capabilities and Constraints

- Currency: BDT (৳) for the main tracker; USD ($) only in the Dollar Tracker. No conversion; the Dollar Tracker never feeds taka balances, charts or summaries.
- Amounts are stored positive; type decides direction (income, expense, savings deposit, savings withdrawal).
- Future-dated entries are excluded from balances and shown as Upcoming.
- 6 locked predefined categories plus user-created ones; per-category monthly budgets.
- Goals hold linked savings deposits; a goal's amount equals its linked deposits minus withdrawals.
- Templates (quick chips, expected-monthly checklist) stand in for recurring transactions.
- Biometric lock; privacy cover in the app switcher.
- Export/backup: CSV, PDF, JSON snapshot and restore.
- Android-only today: home-screen widget.
- Out of scope: cloud sync, multiple accounts, push notifications, recurring transactions, currency conversion, light mode, onboarding tutorial.
- Terminology in use: Available, Savings, Total Balance, Upcoming, Dollar Tracker, Goals, Monthly, History (tab label for transactions).

## Brand Commitments

- Name: SpendSplit.
- App icon exists (`asset/app-icon.png`: white split wallet on a teal-to-indigo gradient). Not confirmed as binding for the in-app look.
- Dark appearance only (confirmed).

## Evidence on Hand

- Real personal financial data lives on the owner's device only; design work uses synthetic demo data, labelled as such.
- No testimonials, users, press or metrics exist; none may be invented.

## Product Principles

1. Available is the answer. Every screen should make the spendable number easy to trust and hard to misread.
2. The split is the product. Savings and current money are always shown as two parts of one balance.
3. Fast in, honest out. Logging and reviewing must be quick; numbers must reconcile with the bank.
4. Personal, not corporate. It is one person's money; it should feel like theirs, not like a bank's app.
5. Separate currencies stay separate. USD tracking never leaks into taka views.

## Accessibility & Inclusion

Follow iOS expectations: Dynamic Type, 44pt touch targets, VoiceOver labels on every tappable element, Reduce Motion honoured.
