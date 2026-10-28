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
- The Runner stays at iOS 13. The widget extension targets iOS 17
  (`containerBackground`). The App Intent is `@available(iOS 16, *)`.
- SMS rows go through the existing `parseTrustBankSms` → `importSmsMessages`
  path. No second parser in Swift.
- Old plans in `docs/superpowers/plans/` keep their `com.example` references
  as history.

---

## Phase 0 — New app ID + iOS baseline

- [ ] Android: `applicationId` + `namespace` → `com.abrar.spendsplit`; move
      the Kotlin sources to `kotlin/com/abrar/spendsplit/` and update their
      `package` lines.
- [ ] iOS: `PRODUCT_BUNDLE_IDENTIFIER` → `com.abrar.spendsplit`
      (RunnerTests → `.RunnerTests`).
- [ ] App Group → `group.com.abrar.spendsplit` in
      `WidgetDataService._appGroupId` and `AppDelegate.swift`.
- [ ] `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- [ ] **[Mac]** Open `ios/Runner.xcworkspace`, select the Runner target, then
      Signing & Capabilities:
  - Team = your Personal Team;
  - **+ Capability → App Groups** → add `group.com.abrar.spendsplit`.
  - **Gate:** this confirms App Groups work on a free team. The widget can't
    read app data without them; SMS import doesn't need them, since the App
    Intent runs in the app's own process. If it fails, report the error
    before Phase 1.
- [ ] **[Mac]** Commit the generated `Runner.entitlements` + `project.pbxproj`
      changes.
- [ ] **[Mac]** `flutter run --release` on the iPhone. Then:
  - restore the JSON backup;
  - check Face ID unlock;
  - add a transaction;
  - confirm the balances match the old phone.

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
  - a SwiftUI view in the app's style: pure-black `containerBackground`,
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

iOS never lets apps read SMS. The route here is a **Personal Automation**:
- trigger *Message* → *Message Contains* `Balance TK`, set to *Run
  Immediately*;
- it passes the message text to a SpendSplit **App Intent**;
- the intent queues the text;
- the app drains the queue through the existing importer on open/resume.

- [ ] **[Mac]** First, confirm that Shortcuts offers the *Message* trigger
      with *Run Immediately* on the phone's iOS version.
- [ ] Swift `ImportBankSmsIntent: AppIntent` in the Runner target
      (`@available(iOS 16, *)`, `openAppWhenRun = false`), plus an
      `AppShortcutsProvider` so it shows up as "Import Bank SMS".
      `perform()` appends `{body, receivedMillis: now}` to a JSON queue in
      the App Group defaults (standard defaults if Phase 0 found no App
      Group) and prunes entries older than 30 days.
- [ ] `AppDelegate.swift`: handle the `spendsplit/sms` channel on iOS:
  - `readInbox(sinceMillis)` returns the queued rows with
    `receivedMillis > since`, oldest first, in the same shape as Android;
  - `hasPermission` / `requestPermission` return `{read: true, receive: false}`.
- [ ] `SmsGateway`: allow iOS through. `backgroundDone` stays Android-only.
- [ ] SMS settings screen on iOS: replace the permission prompt with the
      Shortcut setup steps. Enabling still sets `sms_import_since` to now.
      Add a widget test for the iOS copy using `FakeSmsGateway`.
- [ ] **[Mac]** Create the automation and wait for a real alert. Open the
      app: the transaction should be flagged `needs_review`, the widget count
      should go up, and the reconciliation card should appear.
- [ ] Update `AGENTS.md` / `README.md`.

**Known limits:**
- No background import on iOS. Rows land, and the widget updates, when the
  app next opens.
- `receivedMillis` is when the Shortcut ran, not the carrier timestamp. An
  automation that fires twice for one SMS could create a duplicate. That's
  unlikely, and the review flag catches it.
- iOS may show a "Running your automation" banner each time.
