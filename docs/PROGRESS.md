# Momentum — Build Progress

> What's actually shipped, phase by phase. The roadmap and exit criteria live in [PHASES.md](PHASES.md); this file is the build log — *what landed and when*.

---

## Status snapshot

| Phase | Theme | Status | Landed |
|---|---|---|---|
| **P1** | Core loop on iPhone | ✅ done | 2026-06-24 |
| **P1.5** | Visual polish + light mode | ✅ done | 2026-06-24 |
| **P2** | iPad / adaptive | ✅ done | 2026-06-27 |
| **P3** | CloudKit sync | 🔧 code-complete · sync verify pending | 2026-06-27 |
| **P4** | Momentum visuals | ✅ done | 2026-06-27 |
| **P5** | Today + nudges | 🔧 code-complete · notif/BG verify pending | 2026-06-28 |
| **P6** | AI Assist | ⏳ next | — |
| **P7** | Widgets, Shortcuts, a11y, ship | ⏳ | — |
| **P8** | Optional (Mac, tests, modularization) | ⏳ | — |

---

## P1 — Core loop on iPhone *(2026-06-24)*

The minimum thing that's already useful to the dogfooder.

### What landed

**Models** — `Initiative`, `TaskItem`, `Pulse` (+ `PulseThresholds`).
- Both `@Model` classes are CloudKit-compatible up front: every property defaulted, to-one relationships optional, no `#Unique`.
- `@Relationship(deleteRule: .cascade, inverse: \TaskItem.initiative)` on `Initiative.tasks` only — macro on one side, explicit inverse, cascade so tasks vanish with their initiative.
- `#Index<Initiative>([\.lastActivityAt], [\.isArchived])` and `#Index<TaskItem>([\.isDone])` for the columns the home list sorts/filters on.
- `Pulse` is **derived from `lastActivityAt`** via an extension — never stored.

**Services** — `PulseEngine`, `ActivityService`.
- `PulseEngine` — pure namespace with `sortedStalestFirst` and `coldInitiatives` helpers. Sparkline lands in P4.
- `ActivityService` — `@Observable`, holds the `ModelContext`. Single chokepoint for any forward-motion mutation (`registerActivity`, `addTask`, `toggleDone`). Explicit `try context.save()` after each mutation — autosave is too unpredictable for an activity-tracking app.

**Components** — `PulseDot`, `DaysSinceLabel`.
- `PulseDot` — adapts to `accessibilityDifferentiateWithoutColor` by swapping in shape-varying SF Symbols (`circle.fill` / `circle.lefthalf.filled` / `circle`).
- `DaysSinceLabel` — rounded monospaced numeral, accessibility text pluralized.

**Features** — `InitiativesListView`, `InitiativeRow`, `NewInitiativeSheet`, `InitiativeDetailView`.
- `@Query` sorted by `lastActivityAt` ascending = stalest-first, the spec's defining behavior.
- `ContentUnavailableView` empty state with the exact copy from [SPEC §9](SPEC.md#9-voice--copy-the-empty-states-do-real-work).
- Detail screen: header + inline add-task field + Open / Done sections; check-toggle fires `ActivityService.toggleDone` which resets pulse only when `false → true` (unchecking is not forward motion).
- `NewInitiativeSheet` — name + color preset grid, Add disabled until name non-empty, name field auto-focused, `.medium` / `.large` detents.

**App wiring** — `MomentumApp.swift` creates a single `ModelContainer` and a single `ActivityService` bound to `container.mainContext`; both injected via `.modelContainer(container)` and `.environment(activityService)`. `@Query` and the service share the same context — no two-context drift.

### Key design choices
- **MV + `@Observable`** — no ViewModel layer.
- **Pulse is derived, never stored** — single source of truth in `lastActivityAt`.
- **Only forward motion** counts as activity — adding or completing a task, nothing else.
- **MainActor by default** (project setting `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
- **CloudKit-ready schema from day one** — no schema migration needed in P3.

### Verification
- `xcodebuild` clean against `iPhone 17 Pro` simulator (iOS 26.5).
- Manual: empty state → add initiative → row appears → tap → detail → add task → check → pulse resets → persists across relaunch.

### Deferred (intentional)
- Long-press menus (rename / recolor / archive) — P2
- iPad split view — P2
- CloudKit sync — P3
- Pulse rings / sparkline — P4
- Today triage + notifications — P5
- AI Assist — P6
- Widgets / Shortcuts / Settings / Onboarding — P7

---

## P1.5 — Visual polish + light mode *(2026-06-24)*

Make the app look like [`docs/mockup.html`](mockup.html) and ship both appearances. Behavior unchanged; this is a pure presentation-layer pass.

### What landed

**New foundations**
- **`Theme/Theme.swift`** — semantic color tokens (`AppColor.*`, `PulseColor.*`) with dark + light hex pairs, backed by a `UIColor` traits provider. Colors flip the moment the system switches appearance. No asset catalog dependency.
- **`Components/AddBar.swift`** — dashed-border quick-add row. Accepts a `Binding<String>` for text and `@FocusState.Binding<Bool>` for focus so the parent owns the state.
- **`Components/PulseRing.swift`** — static partial-fill arc. Progress = `days / coldAt` clamped at 1.0. Stroke width 6pt, rounded caps. Animation lands in P4.

**Component refreshes**
- **`PulseDot`** — gains a 4pt halo behind active/cooling dots (low-alpha ring). Cold has no halo. Colors pull from `PulseColor`, not system colors.
- **`DaysSinceLabel`** — restructured to stacked layout: big rounded number on top, tiny uppercase `"TODAY"` / `"DAY"` / `"DAYS"` below with letter-spacing. Number colors to the pulse state.

**Screen updates**
- **`InitiativeRow`** — cold-row background switches from flat red to a horizontal gray gradient (`PulseColor.coldRowTint → clear`, left-to-right). Title/meta typography matches mockup.
- **`InitiativeDetailView`** — header is a card with `PulseRing` + name + `"Cooling · 5 days since activity"` status line in pulse color. Inline "Add task" uses the new `AddBar`. Section headers use the all-caps eyebrow style.
- **`NewInitiativeSheet`** — color palette updated to mockup hexes (Blue, Teal, Amber, Coral, Purple, Sky).

**Navigation shell**
- **`ContentView`** — root is now a `TabView` using the iOS 18+ `Tab` API. Three tabs: Today (placeholder), Initiatives (real), Momentum (placeholder). `.tint(AppColor.accent)` makes the selected tab and nav buttons blue everywhere.
- **`TodayView` / `MomentumDashboardView`** — `ContentUnavailableView` placeholders explaining which phase brings the real screen.

### Key design choices
- **Cold is gray, not red.** Cold initiatives *fade*, they don't alarm. Red is reserved for destructive/danger states. Big semantic shift from the system-color P1 build.
- **Colors live in code, not assets.** `UIColor { traits in … }` dynamic colors give us dark/light support without asset-catalog churn. Easier to refactor and reason about.
- **Tab bar lands now even though Today / Momentum are placeholders.** Makes the navigation shape match the mockup; the placeholder views explain themselves and tease the next phases.

### Verification
- `xcodebuild` clean.
- Manual: rendered in dark mode → matches mockup intent (gray cold, halos, stacked days, ring header). Switched simulator to light mode → all screens still coherent, contrast preserved.

### Deferred (intentional)
- Real Today triage screen — P5
- Real Momentum dashboard (rings + leaderboard + chart) — P4
- Animated pulse rings + sparkline — P4
- iPad three-column split view — P2
- Settings screen — P7

---

## P2 — iPad / adaptive *(2026-06-27)*

Same app, second form factor — responsive layout, not new features. **Zero new files** (the target's synchronized group plus the Xcode-registration constraint meant everything landed by editing existing sources).

### What landed

**Adaptive navigation**
- **`InitiativesListView`** — `NavigationStack` replaced with `NavigationSplitView`. Sidebar hosts the `List`, now selection-driven (`List(selection:)` + `.tag(initiative)`) instead of `NavigationLink(value:)`. The detail column shows `InitiativeDetailView` for the selection, or a `"Select an initiative"` `ContentUnavailableView` placeholder when nothing's picked. `NavigationSplitView` auto-collapses to a push stack on compact width — one code path serves iPhone (stack) and iPad (two-column).

**Context menus**
- Each row gains a `.contextMenu`: **Rename**, **Change color**, **Archive**, **Delete**. Rename and Change color both open the form sheet prefilled; Archive flips `isArchived` (the `@Query` filter drops it from the list); Delete removes it. Selection is cleared if the affected initiative was selected, so the detail pane never dangles.

**Dual-purpose sheet**
- **`NewInitiativeSheet`** — gained an optional `editing: Initiative?`. Title/button switch between New/Add and Edit/Save; name + color prefill from the edited initiative. Auto-focus only fires for create. Edit path mutates `name`/`colorHex` and saves **without** touching `lastActivityAt`.

**Dynamic Type**
- Fixed `.system(size:)` fonts on the Initiatives list + detail converted to text-style-relative fonts (`.body` / `.caption` / `.title2` / `.footnote`) so they scale to XXL. Row title gains `lineLimit(2)` so long names wrap instead of shoving the days-readout off-screen.

### Key design choices
- **One `NavigationSplitView`, not a size-class branch.** `NavigationSplitView`'s built-in collapse behavior is the adaptive layer — no manual `horizontalSizeClass` switch between a stack and a split view.
- **Non-forward-motion edits bypass `ActivityService`.** Rename / recolor / archive save inline via `context.save()` and leave `lastActivityAt` untouched — consistent with how `delete` already worked, and faithful to "only forward motion counts as activity."
- **Reused the create sheet for editing** rather than adding an edit-specific view — keeps the form in one file and respects the no-new-files constraint.

### Verification
- `xcodebuild` clean on **iPhone 17 Pro** and **iPad Pro 11-inch (M5)** (iOS 26.5).
- Launched on the iPad simulator without crash.
- Manual visual sign-off (split-view columns, context menus, XXL Dynamic Type) confirmed by the user.

### Deferred (intentional)
- Drag-to-move tasks across initiatives — P4 polish (iPhone stays context-menu only).
- Archived-initiatives management UI — P7 Settings.

---

## P3 — CloudKit sync *(2026-06-27)*

Two devices, same iCloud, same data — configuration + a status indicator. The code is in place behind a **local-fallback scaffold**; the app builds and runs today in the current local-signing state and flips to real sync the moment the iCloud capability is enabled (no code change needed).

### What landed

**Container wiring** — `MomentumApp`
- Tries `ModelConfiguration(cloudKitDatabase: .automatic)` first (resolves the container from the iCloud entitlement). If that throws — no entitlement yet, or CloudKit unavailable — it falls back to a local `.none` store so the app always runs. A `cloudKitActive` flag records which path won.

**`SyncStatusService`** — `Services/SyncStatusService.swift` (new file)
- `@Observable @MainActor`. Observes `NSPersistentCloudKitContainer.eventChangedNotification` (the event stream behind SwiftData's CloudKit mirroring) and maps events to `State`: `localOnly` / `idle` / `syncing` / `error(message)`.
- Event→state mapping lives in a `nonisolated static` helper so the `@Sendable` notification closure stays concurrency-clean; state is applied via `MainActor.assumeIsolated` (the observer is registered on `.main`).
- Carries the SPEC §9 error copy: *"Can't reach iCloud. Your changes are saved on this device and will sync when you're back."* Exposes `systemImage`, `accessibilityLabel`, and `alertMessage` for the UI.

**Status indicator** — `InitiativesListView`
- Leading toolbar item: a cloud glyph reflecting state (`icloud.slash` / `checkmark.icloud` / spinner / red `exclamationmark.icloud`). Tappable only in the error state → alert with the friendly copy. (Permanent home is the P7 Settings screen; the toolbar is the interim P3 surface.)
- `SyncStatusService` injected into the environment in `MomentumApp` and into the `ContentView` preview.

### Key design choices
- **Local-fallback over hard-require.** The app never fails to launch because iCloud isn't set up — it degrades to local and self-heals when the capability appears. Keeps the build green through the manual setup gap.
- **No conflict UX.** Last-writer-wins, per [DATA-MODEL §6](DATA-MODEL.md#6-cloudkit-considerations-p3) — single user, multiple devices.
- **Schema needed zero changes.** The CloudKit-ready rules (defaulted properties, optional to-one relationship, explicit inverse, no `#Unique`) were baked in back in P1.

### Verification
- `xcodebuild` clean on iPhone 17 Pro (iOS 26.5).
- Launched on simulator without crash — fell back to local-only as expected (no entitlement), indicator state `localOnly`.

### Remaining before P3 exit criteria are met *(manual, owner-only)*
1. Xcode → target → **Signing & Capabilities**: set a **Development Team**; add **iCloud** (check **CloudKit**, create/select container e.g. `iCloud.testing.Momentum`); add **Background Modes** → **Remote notifications**.
2. Run on **two devices** signed into the same iCloud account; confirm an edit on A reaches B within seconds.
3. Edit offline on B, reconnect → reconciles without data loss.

### Deferred (intentional)
- Sync status in a real **Settings** screen — P7 (toolbar indicator is the P3 stand-in).

---

## P4 — Momentum visuals *(2026-06-27)*

The visual payoff — the phase that earns the app its name. **Key realization:** there's no separate event log, but every task's `createdAt` / `completedAt` *is* the forward-motion event stream, so the activity chart and sparklines derive straight from existing data — no schema change.

### What landed

**`ActivityHistory`** — `Services/ActivityHistory.swift` (new, pure)
- Turns a `[TaskItem]` into zero-filled daily buckets (`dailyCounts`) or bare heights (`counts`) over the last N days. Events = each task creation + completion. Deterministic (`now`/`calendar` injectable) so it's test-ready for P8.

**`Sparkline`** — `Components/Sparkline.swift` (new)
- A `Canvas` mini bar chart (not Swift Charts — cheap enough to live in every list row). Rounded bars, empty days drawn as faint stubs.

**`PulseRing`** — animated (`Components/PulseRing.swift`)
- Active/cooling rings now **breathe** (a soft glow ring scaling + fading on a `repeatForever(autoreverses:)` ease). Cold rings stay still — drained. `accessibilityReduceMotion` forces everything static. New `showsDays` option renders the day count + `TODAY`/`DAY`/`DAYS` in the ring center (used by the dashboard grid). Existing `PulseRing(pulse:days:)` call sites unchanged.

**Momentum dashboard** — `Features/Momentum/MomentumDashboardView.swift` (rewritten)
- **Activity chart** — Swift Charts `BarMark` over the window, with a **14d / 30d** segmented toggle and a "*N moves in W days*" headline.
- **Going-cold leaderboard** — cooling + cold initiatives, stalest-first (top 5), each tappable. Hidden entirely when nothing's cooling.
- **Ring grid** — 2-column `LazyVGrid` of every initiative's `PulseRing` + name.
- Tapping a grid ring pushes the detail with an iOS 18 **zoom transition** (`.matchedTransitionSource(id:in:)` + `.navigationTransition(.zoom(sourceID:in:))`) — the modern, supported successor to `matchedGeometryEffect` for cross-navigation ring continuity.

**Initiatives list** — `Features/Initiatives/InitiativeRow.swift`
- Each row gains a 14-day `Sparkline` (tinted to the row's pulse color) between the title block and the days readout.

### Key design choices
- **Zoom transition over `matchedGeometryEffect`.** The deliverable named `matchedGeometryEffect`, but across a `NavigationStack` push the idiomatic iOS 18+ tool is `matchedTransitionSource` + `.navigationTransition(.zoom)`. Same visual intent (the ring flies into the detail), properly supported.
- **Breathing, not spinning.** A subtle scale/opacity glow reads as "alive" without the noise the exit criteria warn against; cold deliberately doesn't move.
- **Derive, don't store.** Activity history comes from task timestamps — keeps the model lean and the CloudKit schema untouched.
- **Sparkline in `Canvas`, chart in Swift Charts.** Per-row needs to be cheap; the dashboard can afford the richer framework.

### Verification
- `xcodebuild` clean on iPhone 17 Pro (iOS 26.5).
- Ran with seed data: detail header ring renders the cooling/active arc; dashboard shows the Swift Charts bar chart ("8 moves in 14 days"), 14d/30d toggle, and the ring grid with centered day counts. Leaderboard correctly hidden when all initiatives are active. (Verified by temporarily rooting at the dashboard, screenshotting, then reverting `ContentView`.)

### Deferred (intentional)
- Animated/looping chart entrance — not needed; bars read fine static.
- Sparkline interaction (scrub/tooltip) — out of scope.

---

## Feature — Silent archive (auto-complete) *(2026-06-27)*

Added between P4 and P5. Momentum has no "complete" button by design — so *finishing* needed its own mechanism. A finished initiative now **archives itself silently**, and a notch tells you when something quietly moved.

### Behavior
- **Auto-archive:** an initiative with **≥1 task, all done**, that's been **idle ≥10 days** gets `isArchived = true` + `archivedAt`. (It visibly passes through cooling→cold first, then archives.) Initiatives with open tasks or no tasks never auto-archive.
- **Revival:** adding a task to an archived initiative un-archives it (`ActivityService.addTask`) and resets its pulse — it's alive again.
- **Notch:** a red count badge on the **Archive** toolbar button counts *auto*-archived initiatives you haven't seen. Opening the Archive screen clears the whole notch (persisted in `UserDefaults`, so it survives relaunch). Manual archive (context menu) deliberately does **not** notch.

### What landed
- **`Initiative.archivedAt: Date?`** (new optional property — CloudKit-safe, lightweight auto-migration verified against the existing store).
- **`ArchiveService`** (`Services/ArchiveService.swift`, new) — `sweep(now:)` archives finished+idle initiatives and bumps the `UserDefaults` unseen counter; `clearUnseen()`; plus `Initiative.allTasksComplete()` / `shouldAutoArchive()` pure helpers. Sweep runs on `scenePhase == .active` (wired in `MomentumApp`); the once-a-day `BGAppRefreshTask` version lands with P5.
- **`ArchiveListView`** (`Features/Archive/ArchiveListView.swift`, new) — archived initiatives newest-first, relative "archived N days ago" caption, swipe **Restore** / **Delete**, tap → detail (add a task to revive). Clears the notch on open.
- **`InitiativesListView`** — Archive toolbar button with the red count badge (`@AppStorage`); manual archive now stamps `archivedAt`.

### Notes
- Pulls archive management forward from the P7 Settings plan ([DATA-MODEL §8](DATA-MODEL.md#8-data-lifecycle)); the permanent Settings home still arrives in P7.
- Verified: clean build, store migration, launch. Time-dependent sweep + notch behavior to be confirmed in dogfooding.

---

## P5 — Today + nudges *(2026-06-28)*

Triage in one screen + the first push from outside the app. Following the P3 pattern, the background-task piece is gated behind a manual capability and **self-disables** until then; everything else works now.

### What landed

**`TodayView`** (rewritten, real)
- **Attention banner** — when anything's cold, a tappable gradient banner names the stalest cold initiative (*"N has gone quiet"* / *"N and X more…"*) → opens it.
- **Suggested focus** — stalest-first, each initiative's *oldest open task* (up to 3); a checkbox completes it (forward motion), the text opens the initiative, parent pulse dot on the right.
- **Quick add** — `AddBar` that drops a task onto the stalest initiative (reviving it if needed).

**`NotificationService`** (`Services/NotificationService.swift`, new)
- Requests authorization on launch. `sweepColdNotifications()` schedules one nudge per newly-cold, live initiative, **deduped** via the new `Initiative.coldNotified` flag (reset on any activity — so a revived-then-cold initiative nudges again, but app relaunches don't re-nudge). SPEC §9 copy.
- **Quiet hours** (`QuietHours`, default 22:00–08:00): a nudge that would fire in the window is deferred to the window's end via a calendar trigger.
- `UNUserNotificationCenterDelegate` shows nudges in-foreground and routes taps to the initiative.

**`AppRouter`** (`Services/AppRouter.swift`, new)
- Owns `selectedTab` + `selectedInitiative`. `ContentView`'s `TabView` and the Initiatives split-view selection now read from it, so `openInitiative(id:)` (from a notification tap) lands on the right detail. `InitiativesListView` selection was lifted from local `@State` into the router.

**`BackgroundRefresh`** (`Services/BackgroundRefresh.swift`, new)
- `BGAppRefreshTask` registration + ~12h scheduling for a daily archive + cold-nudge sweep. Guarded by `isEnabled` (checks Info.plist for the permitted identifier) so it cleanly no-ops until the capability is added.

**Model** — `Initiative.coldNotified: Bool` (CloudKit-safe; lightweight migration verified). `ActivityService.registerActivity` resets it.

### Key design choices
- **Dedupe in the model, not a side table.** `coldNotified` rides with the initiative, syncs via CloudKit, and naturally re-arms on activity — "exactly one notification per cold episode" falls out for free.
- **Defer, don't drop, in quiet hours.** A cold nudge still arrives — just at 8am, not 2am.
- **Today taps reuse the deep-link path.** Tapping a suggestion calls the same `AppRouter.open` a notification uses, so there's one routing path to reason about.
- **Background self-disables.** No crash without the Info.plist identifier; the on-foreground sweep (`scenePhase == .active`) keeps archiving + nudging working for dogfooding.

### Verification
- `xcodebuild` clean on iPhone 17 Pro; no concurrency warnings.
- Ran with seed data: Today shows suggested-focus rows with parent initiatives + pulse dots and the quick-add bar; the notification authorization prompt fires on launch; `coldNotified` migration succeeded (no crash).

### Remaining before P5 exit criteria are met *(manual / on-device)*
1. Xcode → **Background Modes** (Background processing) + add `testing.Momentum.refresh` to **`BGTaskSchedulerPermittedIdentifiers`** (Info.plist) to switch on the daily background sweep.
2. On a real device: confirm a newly-cold initiative delivers exactly one notification, quiet hours hold, and tapping it lands on that initiative's detail.

### Notes / deferred
- Nudges are **initiative-level** (an initiative went cold), so a tap lands on the initiative detail rather than a specific task — matches the trigger.
- User-tunable quiet hours + thresholds live in the P7 Settings screen; defaults are hardcoded for now.

---

## What's next

**P6 — AI Assist.** On-device LLM (Foundation Models), never autonomous: *Break it down* (goal → 3–6 next actions), *Focus for today* (stale initiatives + open tasks → 1–3 suggested moves), *Weekly review* (what moved / stalled + one revival step per cold initiative). `@Generable` types for parseable suggestion lists; an Assist sheet streams rows in; "Add selected" commits via `ActivityService`. The model never writes directly — every suggestion needs explicit accept; graceful disable when the model's unavailable.

Full P6 brief in [PHASES.md § P6](PHASES.md#p6--ai-assist).
