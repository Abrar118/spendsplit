# iOS: Review-Count Widget + Bank SMS via Shortcuts

**Goal:** Bring SpendSplit's Android-only features to the owner's iPhone 17:
- a home-screen widget, on **both** platforms, showing **only the number of
  transactions waiting for review** (no balances);
- Trust Bank SMS import through a Shortcuts automation.

**Workflow:** Code is edited on Windows; the owner pulls and builds on a Mac
(`flutter run --release` with the iPhone connected). Steps marked **[Mac]**
need Xcode. Every phase ends with a device check before the next one starts.

## Decisions

- SMS on iOS goes through a Shortcuts automation. No PWA.
- **Free Apple ID** (personal team), with these limits:
  - builds expire after 7 days; re-run `flutter run --release` from the Mac
    weekly (installing over the old build keeps the data);
  - at most 3 sideloaded apps per device;
  - each extension uses up an App ID (10 per 7 days).
- The iPhone needs **Developer Mode** turned on (Settings → Privacy &
  Security). Trust the developer profile under Settings → General →
  VPN & Device Management.
- **App/bundle ID `com.abrar.spendsplit`** on iOS and Android. Android gets a
  new package (`namespace` + Kotlin package), because `home_widget` looks
  widget providers up under the app ID. Both platforms install as a fresh
  app; restore the JSON backup afterwards. It carries all six tables plus the
  settings, including initial balance and card number.
- App Group: `group.com.abrar.spendsplit`.
- Optional: GitHub Actions running `flutter build ios --no-codesign` as a
  compile check for Swift written on Windows. It needs no Apple account.

## Global Constraints

- No new pub dependencies.
- The Runner targets iOS 15.0 (PR #4; Xcode's recommended target broke
  `pod install`). The widget extension targets iOS 17 (`containerBackground`).
- SMS rows go through the existing `parseTrustBankSms` → `importSmsMessages`
  path. No second parser in Swift.
- Old plans in `docs/superpowers/plans/` keep their `com.example` references
  as history.

---

## Phase 0 — New app ID + iOS baseline

- [x] Android: `applicationId` + `namespace` → `com.abrar.spendsplit`; move
      the Kotlin sources to `kotlin/com/abrar/spendsplit/` and update their
      `package` lines.
- [x] iOS: `PRODUCT_BUNDLE_IDENTIFIER` → `com.abrar.spendsplit`
      (RunnerTests → `.RunnerTests`).
- [x] App Group → `group.com.abrar.spendsplit` in
      `WidgetDataService._appGroupId` and `AppDelegate.swift`.
- [x] `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- [ ] **[Mac]** Open `ios/Runner.xcworkspace`, select the Runner target, then
      Signing & Capabilities:
  - [x] Team = your Personal Team (PR #4);
  - [ ] **+ Capability → App Groups** → add `group.com.abrar.spendsplit`.
  - **Gate:** this confirms App Groups work on a free team. The widget can't
    read app data without them; SMS import doesn't need them, since the inbox
    folder is in the app's own Documents. If it fails, report the error
    before Phase 1.
- [ ] **[Mac]** Commit the generated `Runner.entitlements` + `project.pbxproj`
      changes.
- [x] **[Mac]** `flutter run --release` on the iPhone (PR #4). Then:
  - [x] restore the JSON backup;
  - [ ] check Face ID unlock;
  - [ ] add a transaction;
  - [ ] confirm the balances match the old phone.

## Phase 1 — Review-count widget (Android + iOS)

**Shared (Dart):**
- [ ] `WidgetDataService`: replace `updateBalance` with
      `updateReviewCount(int count)`. It saves `review_count` (int) and
      reloads both widgets. Drop the `available_balance` / `savings_percent`
      keys and the amount formatters.
- [ ] `syncHomeWidget`: return early until `transactionsProvider` has loaded,
      so a cold start doesn't flash 0. Then push `needsReviewCountProvider`.
      In `app.dart`, listen to `needsReviewCountProvider` instead of the
      balance and savings providers.
- [ ] Tapping the widget opens Transactions filtered to review
      (`/transactions?review=1`):
  - URI `spendsplit://review?homeWidget`;
  - handled through `HomeWidget.initiallyLaunchedFromHomeWidget()` +
    `HomeWidget.widgetClicked`;
  - when the app is locked, the router keeps the target and goes there after
    unlock, instead of dropping to the dashboard.

**Android:**
- [ ] Redo `widget_spendsplit.xml`:
  - large count + tracked "TO REVIEW" label;
  - "All reviewed" when the count is 0;
  - drop the ৳ amount and the decorative "+".
- [ ] `SpendSplitWidgetProvider` reads `review_count` and sets the click
      intent with `HomeWidgetLaunchIntent.getActivity(…, Uri.parse(…))`.
- [ ] Verify with `flutter build apk`. No Android device on hand, so this
      check is build-only.

**iOS:**
- [ ] **[Mac]** File → New → Target → **Widget Extension**, named
      `SpendSplitWidget`. Turn off Live Activity and the configuration intent.
      Set the deployment target to 17.0 and add the same App Group. Commit.
- [ ] Replace the generated Swift:
  - a `TimelineProvider` reads `review_count` from
    `UserDefaults(suiteName: "group.com.abrar.spendsplit")`, with a `.never`
    refresh policy;
  - a SwiftUI view in the app's style: charcoal `#1D1D20` `containerBackground`,
    count in gold `#ECBB7E`, tracked "TO REVIEW" label, an "All reviewed"
    state;
  - `widgetURL(spendsplit://review?homeWidget)`;
  - family `.systemSmall`.
- [ ] **[Mac]** Build and add the widget. Flag a transaction for review,
      e.g. through a CSV import or later through SMS. The count should update
      when the app goes to the background, and tapping it should open the
      review filter.
- [ ] Update `AGENTS.md` / `README.md`.

## Phase 2 — Trust Bank SMS via a Shortcuts automation

**Done (PR #4), as a file inbox instead of the planned App Intent.** iOS
never lets apps read SMS. A **Personal Automation** (*Message Contains*
`Balance TK`, *Run Immediately*) saves each alert as a file in
`Documents/SMS Inbox`, exposed in Files via `UIFileSharingEnabled`. It needs
no App Group, no Swift intent and no `spendsplit/sms` channel on iOS.

- [x] `SmsImportRunner` imports and deletes the inbox files on open/resume,
      through the existing `parseTrustBankSms` → `importSmsMessages` path and
      `sms_ref` dedupe. Receive time = file mtime.
- [x] Shortcuts saves text copied from Messages as RTFD, so `AppDelegate.swift`
      decodes RTFD/RTF/UTF-8 natively (`spendsplit/text` channel). An
      unreadable file is kept and skipped.
- [x] The first iOS import switches `sms_import_since` on, so the
      reconciliation card works.
- [x] **[Mac]** A real Trust Bank SMS imported end to end on the iPhone.
- [x] Update `AGENTS.md`.
- [ ] Widget count going up after an import: blocked on Phase 1.

**Known limits:**
- No background import on iOS. Rows land, and the widget will update, when
  the app next opens or resumes.
- iOS may show a "Running your automation" banner each time.
