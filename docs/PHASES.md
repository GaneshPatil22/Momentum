# Momentum — Phased Roadmap

> Each phase is a shippable slice: it produces a build you could put in front of someone. No phase exists just to set up the next one.

| Phase | Theme | Status |
|---|---|---|
| [P1](#p1--core-loop-on-iphone) | Core loop on iPhone | not started |
| [P2](#p2--ipad--adaptive) | iPad / adaptive | not started |
| [P3](#p3--cloudkit-sync) | CloudKit sync | not started |
| [P4](#p4--momentum-visuals) | Momentum visuals | not started |
| [P5](#p5--today--nudges) | Today + nudges | not started |
| [P6](#p6--ai-assist) | AI Assist | not started |
| [P7](#p7--widgets-shortcuts-ally-ship) | Widgets, Shortcuts, a11y, ship | not started |
| [P8](#p8--optional) | Optional (Mac, tests, modularization) | not started |

---

## P1 — Core loop on iPhone

The minimum thing that is **already useful** to the dogfooder.

**Deliverables**
- `Initiative` and `TaskItem` `@Model`s + `Pulse` enum + `PulseEngine` (pure).
- `ActivityService` enforces the activity rules (see [DATA-MODEL §4](DATA-MODEL.md#4-activity-rules)).
- **Initiatives list** (`InitiativesListView`) — stalest-first, pulse dot, days-since, task count, swipe to delete.
- **Initiative detail** (`InitiativeDetailView`) — header (name + pulse dot + days-since), Open/Done sections, inline add-task field, checkbox toggle, swipe to delete tasks.
- **New / Edit Initiative sheet** — name + color preset picker.
- Empty-states with real copy (see [SPEC §9](SPEC.md#9-voice--copy-the-empty-states-do-real-work)).

**Surfaces practiced:** SwiftData `@Model`, `@Query`, `List`, sections, `@FocusState`, `NavigationStack`, sheets + detents, swipe actions, context menus.

**Exit criteria**
- Add an initiative → it appears.
- Add a task → initiative's pulse resets, list re-sorts.
- Check a task → pulse resets, task moves to Done.
- Quit & relaunch → everything is there.

**Out of P1:** iPad layout, pulse rings/animation, CloudKit, notifications, AI.

---

## P2 — iPad / adaptive

Same app, second form factor. The point is responsive layout, not new features.

**Deliverables**
- `NavigationSplitView` with sidebar (Initiatives) + content (detail).
- Adaptive sizing (`UIDevice` / `horizontalSizeClass` rather than hard checks).
- Dynamic Type tested to XXL — at least one screen needs to bend without breaking.
- Context menus and drag-source affordances for moving tasks across initiatives (iPad: drag; iPhone: context menu only — drag lands in P4 polish).

**Exit criteria**
- iPad running the build feels native, not stretched.
- iPhone build still passes everything from P1.

---

## P3 — CloudKit sync

Two devices, same iCloud, same data. No accounts, no UI screens — just configuration + a status indicator.

**Deliverables**
- `ModelContainer` configured with CloudKit private DB.
- Schema reviewed for CloudKit constraints (see [DATA-MODEL §6](DATA-MODEL.md#6-cloudkit-considerations-p3)).
- `SyncStatusService` exposes `state` (idle / syncing / error) for a Settings row.
- Friendly error copy from [SPEC §9](SPEC.md#9-voice--copy-the-empty-states-do-real-work).

**Exit criteria**
- Edit on Device A → propagates to Device B within seconds while both online.
- Edit offline on B, come back online → reconciles without data loss.
- Settings shows a meaningful status.

---

## P4 — Momentum visuals

The visual payoff. This is the phase that earns the app its name.

**Deliverables**
- `PulseRing` component: animated ring (`Canvas` + phase/keyframe animation) honoring Reduce Motion.
- Updated **Initiative Detail header** uses the ring instead of a dot.
- **Momentum dashboard** (`MomentumDashboardView`) — grid of pulse rings, "going cold" leaderboard, 14/30-day activity chart (Swift Charts).
- 14-day sparkline per row in the Initiatives list.
- `matchedGeometryEffect` between dashboard ring and detail-screen ring.

**Exit criteria**
- Animation looks alive without being noisy.
- Dashboard tells the whole story in one glance.
- Reduce Motion = static, still legible.

---

## P5 — Today + nudges

Triage + the first push the user gets from outside the app.

**Deliverables**
- `TodayView` — Attention banner (cold initiatives), suggested-focus list (heuristic: stalest initiative's oldest open task), quick-add.
- `NotificationService` — local notification when an initiative crosses into `cold`. Respects quiet hours.
- Background task (`BGAppRefreshTask`) sweeps pulses once a day and schedules a notification for any new cold initiative.
- Deep link from notification → that initiative.

**Exit criteria**
- A new cold initiative produces exactly one notification (not one per app launch).
- Quiet hours are honored.
- Tapping the notification lands you in the right detail screen, scrolled to the right task.

---

## P6 — AI Assist

On-device LLM, three concrete jobs, never autonomous.

**Deliverables**
- `AIAssistService` backed by Foundation Models.
- `@Generable` types so the model returns parseable suggestion lists.
- **Break it down** — goal → 3–6 next actions.
- **Focus for today** — stale initiatives + open tasks → 1–3 suggested moves.
- **Weekly review** — what moved, what stalled, one revival step per cold initiative.
- AI Assist sheet streams rows in; "Add selected" commits via `ActivityService`.

**Exit criteria**
- The model **never writes** directly — every suggestion requires explicit accept.
- Streaming feels responsive on a real device.
- Sensible behavior offline / when the model isn't available (graceful disable, not crash).

---

## P7 — Widgets, Shortcuts, a11y, ship

The polish-and-publish phase.

**Deliverables**
- **Widgets** — Small (coldest initiative), Medium (top 3 stalest). Deep-link via App Intents.
- **App Intents / Shortcuts** — "Add task to <initiative>", "What's going cold?".
- **Onboarding** — 1–2 screens explaining the pulse mechanic + create your first initiative.
- **Settings** — appearance, pulse thresholds, notifications + quiet hours, iCloud status, archived initiatives, about.
- **Accessibility pass** — VoiceOver labels for pulse state, dynamic type at XXL on every screen, Reduce Motion fallbacks confirmed.
- **Localization scaffolding** via `Localizable.xcstrings` (English first).
- Icon, screenshots, App Store metadata.

**Exit criteria**
- A blind user can use the app without seeing color.
- VoiceOver reads pulses as text.
- Widgets refresh sensibly and look like Apple's.
- Ready for TestFlight.

---

## P8 — Optional

Things worth doing but not required to ship.

- **macOS Catalyst** target (most of the work is sidebar polish + keyboard nav).
- **Test target** — start with `PulseEngine`, `ActivityService`, predicate correctness. SwiftData has good test ergonomics with an in-memory `ModelConfiguration`.
- **SPM modularization** — promote `Models`, `Services`, and feature folders to their own targets so the widget target and any future macOS target share a single source of truth.
- **Performance pass** — large libraries (100+ initiatives, 1000+ tasks): chart aggregation, list virtualization, predicate tuning.

---

## What gets cut if time runs short

In order:
1. P8 entirely.
2. P6 (AI). Heuristic suggestions in P5 are already useful.
3. P4 animation polish (the ring can ship as a static arc).

Nothing earlier than P4 is optional — P1–P3 + P5 is the floor for a useful, syncing, attention-grabbing app.
