# Momentum — Build Progress

> What's actually shipped, phase by phase. The roadmap and exit criteria live in [PHASES.md](PHASES.md); this file is the build log — *what landed and when*.

---

## Status snapshot

| Phase | Theme | Status | Landed |
|---|---|---|---|
| **P1** | Core loop on iPhone | ✅ done | 2026-06-24 |
| **P1.5** | Visual polish + light mode | ✅ done | 2026-06-24 |
| **P2** | iPad / adaptive | ⏳ next | — |
| **P3** | CloudKit sync | ⏳ | — |
| **P4** | Momentum visuals | ⏳ | — |
| **P5** | Today + nudges | ⏳ | — |
| **P6** | AI Assist | ⏳ | — |
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

## What's next

**P2 — iPad / adaptive.** Adopt `NavigationSplitView` for regular size class, validate Dynamic Type to XXL on at least one screen, add long-press context menus (rename / recolor / archive). Exit when iPad feels native (not stretched) and iPhone hasn't regressed.

Full P2 brief in [PHASES.md § P2](PHASES.md#p2--ipad--adaptive).
