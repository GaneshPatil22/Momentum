# Momentum — Feature Specification

> Source of truth for **what** we are building. Architectural **how** lives in [ARCHITECTURE.md](ARCHITECTURE.md); the data shape in [DATA-MODEL.md](DATA-MODEL.md); the **when** in [PHASES.md](PHASES.md).

---

## 1. Concept

A personal command center for someone running several parallel initiatives. Each initiative has a visible **pulse**; the app surfaces which one is going cold and the smallest next step to revive it.

- **Free, on-device, private** (CloudKit private DB, no accounts, no servers).
- **Dogfooded.**

**The pain it solves**

> "I start five things strong, silently let two die, and don't notice until it's too late."

Momentum makes neglect **visible before abandonment**.

---

## 2. Entities & Data Model

### `Initiative` — a thing you're trying to keep alive
| Field | Type | Notes |
|---|---|---|
| `name` | `String` | |
| `colorHex` | `String` | one of 6–8 presets |
| `createdAt` | `Date` | |
| `lastActivityAt` | `Date` | **the pulse anchor** |
| `tasks` | `[TaskItem]` | to-many, cascade delete |
| `daysSinceActivity` | `Int` *(derived)* | never stored |
| `pulse` | `Pulse` *(derived)* | never stored |

### `TaskItem` — a concrete action under an initiative
| Field | Type | Notes |
|---|---|---|
| `title` | `String` | |
| `isDone` | `Bool` | |
| `createdAt` | `Date` | |
| `completedAt` | `Date?` | |
| `initiative` | `Initiative` | to-one inverse |

### `Pulse` (enum)
| Case | Range | Meaning |
|---|---|---|
| `active` | 0–2 days | healthy |
| `cooling` | 3–6 days | warning |
| `cold` | 7+ days | needs attention |

Thresholds are tunable in Settings (P7).

### Activity (the only thing that resets the pulse)
- Adding a task to an initiative ✓
- Completing a task under it ✓
- Editing / deleting / reordering — **do not** count.

Both qualifying events call `registerActivity()`, which sets `lastActivityAt = .now`.

---

## 3. The Pulse Mechanic (the heart)

- Every initiative shows its pulse **everywhere** it appears: a colored dot/ring + an **"Nd"** days-since readout in rounded numerals (vital-signs styling).
- The Initiatives list sorts **stalest first** by default — the thing dying floats to the top, unprompted.
- A `cold` initiative gets a visible **"Needs attention"** treatment: row tint + an Attention banner on Today.
- **P1** ships dot + days. **P4** adds animated pulse rings, a 14-day activity sparkline per initiative, and the Momentum dashboard.

---

## 4. Screens

For each: purpose · key elements · interactions · iPhone vs iPad · phase.

### 4.1 Onboarding · **P7**
- **Purpose:** explain the pulse idea in 1–2 screens; create the first initiative.
- **Elements:** concept statement, animated pulse demo, "Create your first initiative" CTA.
- **iPhone:** full-screen paged. **iPad:** centered card, max-width.
- Empty-state copy is the real teacher here — see §9.

### 4.2 Initiatives (home / sidebar) · **P1** (list), **P2** (sidebar)
- **Purpose:** see all initiatives and their health at a glance.
- **Elements:** rows = pulse dot + name + task count + days-since readout; **stalest-first** sort; "+" to add; cold ones tinted.
- **Interactions:** tap → Initiative Detail; swipe → archive/delete; long-press → context menu (rename, change color, archive).
- **iPhone:** `NavigationStack`, full-width list, large title "Initiatives". **iPad:** lives in the split-view sidebar; selection drives the content column.
- **Surfaces:** `List`, sections, swipe, context menu, `@Query` (sorted).

### 4.3 Initiative Detail · **P1** (basic), **P4** (pulse header)
- **Purpose:** work the initiative — see and act on its tasks.
- **Elements:** header (name, pulse ring, days-since, color); task list split into **Open / Done**; inline "Add task" field at top; per-task checkbox.
- **Interactions:** toggle done (animates + bumps pulse); swipe to delete; drag to reorder; add task (focus field, return commits, stays focused for rapid entry); tasks can be moved to another initiative via drag (iPad) or context menu (iPhone).
- **iPhone:** pushed screen with back. **iPad:** content column; selecting a task opens the detail column.
- **Surfaces:** List editing, `@FocusState`, drag & drop, animation, pulse ring (`Canvas`/`Charts`).

### 4.4 New / Edit Initiative · **P1**
- **Purpose:** create or rename an initiative, pick a color.
- **Elements:** `Form` — name field, color swatch picker (6–8 presets), optional starting note.
- **Interactions:** presented as a sheet with `presentationDetents([.medium])`; focus name field on appear; **Add** disabled until name non-empty; Cancel/Add in nav bar.
- **iPhone & iPad:** same sheet, iPad centered/smaller.
- **Surfaces:** `Form`, sheet, detents, `@FocusState`, validation.

### 4.5 Today · **P5**
- **Purpose:** a single triage view across all initiatives.
- **Elements:** "Needs attention" banner (cold initiatives); a **suggested-focus** list (AI-assisted in P6; before that, a simple heuristic — e.g. stalest initiative's oldest open task); quick-add.
- **Interactions:** tap a suggestion → jump to that task's initiative; check off inline.
- **iPhone:** first tab. **iPad:** top item in sidebar; content fills the wide canvas (2-column grid of cards).
- **Surfaces:** `LazyVGrid` (iPad), `ScrollView`, custom layout, notifications tie-in.

### 4.6 Momentum (dashboard) · **P4**
- **Purpose:** the visual payoff — health of everything at once.
- **Elements:** grid of animated pulse rings (one per initiative); a "going cold" leaderboard sorted by days-since; a 14/30-day activity chart (Swift Charts).
- **Interactions:** tap a ring → Initiative Detail; toggle 14d/30d range.
- **iPhone:** a tab, scrollable. **iPad:** richer multi-column dashboard.
- **Surfaces:** Swift Charts, `Canvas`, animated rings, `matchedGeometryEffect`, phase/keyframe animation.

### 4.7 AI Assist · **P6**
- **Purpose:** on-device help, three jobs — **never autonomous**, always suggestions you accept/reject.
  1. **Break it down** — paste a goal → AI returns 3–6 concrete next actions you can add as tasks.
  2. **What should I focus on?** — given stale initiatives + open tasks, AI suggests today's 1–3 moves.
  3. **Weekly review** — AI summarizes what moved, what stalled, and proposes one revival step per cold initiative.
- **Elements:** entry sheet with the three actions; results shown as selectable rows with an "Add selected" button.
- **Interactions:** results stream in; each suggested task has an accept toggle; **nothing is written until you confirm**.
- **iPhone & iPad:** sheet (iPad larger). Powered by Foundation Models, `@Generable` for structured task lists.
- **Surfaces:** Foundation Models, `@Generable`, `Tool`, streaming.

### 4.8 Settings · **P7**
- Appearance (system/light/dark), pulse thresholds, notifications toggle + quiet hours, iCloud sync status, manage archived initiatives, about/version.
- `Form` with grouped sections. **iPad:** in sidebar.

### 4.9 Home-screen Widget · **P7**
- **Small:** the single coldest initiative + days-since.
- **Medium:** top 3 stalest with pulse dots.
- Tap → deep-links into that initiative (App Intents).

---

## 5. System Features

| Feature | Phase | Notes |
|---|---|---|
| **Sync** | P3 | SwiftData + CloudKit private DB. Status surfaced in Settings. No login. |
| **Notifications** | P5 | Local notification when an initiative crosses into `cold`; respects quiet hours; "open task to revive" deep link. |
| **Shortcuts / Siri** | P7 | App Intents — "Add task to <initiative>", "What's going cold?". |

---

## 6. Non-functional / Production

(All P7 unless noted.)

- **Dynamic Type to XXL** without breakage. Test early — **P2**.
- **VoiceOver:** pulse state announced as text ("CoreLearnly, cooling, 4 days since activity"), **not color alone**.
- **Reduce Motion:** pulse animations degrade to static.
- **Localization-ready** via String Catalogs (English first).
- **Empty states & error states** are written, not blank — see §9.
- **Light + dark appearances** both shipped (mockup shown in dark).

---

## 7. Out of Scope (explicit — guards against creep)

- No teams / sharing / collaboration.
- No web or Android version.
- No third-party calendar / task integrations.
- No accounts / auth (CloudKit uses the device iCloud).
- No cloud AI, no server. **On-device only.**
- No time-blocking or auto-scheduling — that's the competitor trap we're deliberately avoiding.

---

## 8. Phase Rollup

| Phase | Theme |
|---|---|
| **P1** | List + detail + create (minimal pulse) |
| **P2** | iPad / adaptive |
| **P3** | Sync (CloudKit) |
| **P4** | Momentum visuals |
| **P5** | Today + nudges |
| **P6** | AI |
| **P7** | Widgets / Shortcuts / a11y / ship |
| **P8** | Optional (Mac, tests, modularization) |

Full breakdown in [PHASES.md](PHASES.md).

---

## 9. Voice & Copy (the empty states do real work)

- **Empty Initiatives:** *"Nothing yet. Add the first thing you're trying to keep alive."* + Add button.
- **Empty tasks in an initiative:** *"No open tasks. What's the next small step?"*
- **Cold initiative banner:** *"CoreLearnly has gone quiet — 9 days. One small step brings it back."*
- **Sync error:** *"Can't reach iCloud. Your changes are saved on this device and will sync when you're back."*
- **Buttons say the outcome:** "Add task" → toast "Task added". "Add selected" on AI results.
