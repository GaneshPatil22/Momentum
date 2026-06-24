# Momentum — UI Reference

> Design tokens, component vocabulary, and screen breakdown extracted from the HTML demo at [mockup.html](mockup.html). The mockup is the source of truth for **visual treatment**; [SPEC.md](SPEC.md) remains the source of truth for **behavior**.

---

## 1. Design tokens

### 1.1 Semantic colors

Tokens are named by **role**, not by hue, so light mode can flip them without renaming anywhere.

| Token | Role | Dark hex | Light hex *(derived)* |
|---|---|---|---|
| `bg` | App / screen background | `#0E1116` | `#F2F2F7` |
| `surface` | Card / group background | `#171B22` | `#FFFFFF` |
| `surface2` | Secondary surface (add-bar fill, sheet field) | `#1E232C` | `#F5F5F7` |
| `surface3` | Tertiary surface (grabber, chart inactive bar) | `#262C36` | `#E5E5EA` |
| `hairline` | 1pt dividers and borders | `#2A313C` | `#D1D1D6` |
| `text` | Primary text | `#EEF2F6` | `#11151C` |
| `text2` | Secondary text (meta lines) | `#9BA6B4` | `#545B66` |
| `text3` | Tertiary text (captions, subscripts) | `#69707C` | `#8A92A0` |
| `accent` | Interactive (nav buttons, "+", selected) | `#5B8DEF` | `#2C6EE3` |

### 1.2 Pulse colors — the signature

> **Big change from current P1:** cold is **gray**, not red. Cold initiatives *fade* — they don't alarm. Red is reserved for destructive/danger states (delete confirmations, sync error banner).

| State | Token | Dark hex | Light hex *(derived)* | Halo (box-shadow equivalent) |
|---|---|---|---|---|
| Active (0–2 days) | `pulseActive` | `#2FD4A7` | `#16A271` | `rgba(47,212,167,.16)` × 4pt |
| Cooling (3–6 days) | `pulseCooling` | `#F6B23C` | `#C97A00` | `rgba(246,178,60,.14)` × 4pt |
| Cold (7+ days) | `pulseCold` | `#6B7686` | `#8E939C` | *(no halo — drained)* |
| Danger | `danger` | `#FF6B6B` | `#E03333` | — |

Pulse halo in SwiftUI: a larger transparent `Circle` painted *behind* the colored dot — not a true blur, just a flat ring of low-alpha color.

### 1.3 Typography

| Role | Font | Size | Weight | Letter-spacing |
|---|---|---|---|---|
| Large title | `.system` | 30 | 800 (heavy) | `-0.02em` |
| Section title | `.system` | 18 | 700 | — |
| Row title | `.system` | 16 | 600 | — |
| Body | `.system` | 15 | regular | — |
| Caption | `.system` | 12.5 | regular | — |
| Eyebrow (group header) | `.system` | 12 | 600 | `0.06em` uppercase |
| Days number | `.rounded` | 15 | 700 | — |
| Days subscript "DAYS" / "DAY" / "TODAY" | `.rounded` | 9 | 600 | `0.08em` uppercase |
| Ring numeric | `.rounded` | 13 | 800 | — |

Map to SwiftUI:
- `.system` → `.font(.body)` etc. with default design
- `.rounded` → `.fontDesign(.rounded)`
- Headings exceed `.largeTitle`'s default weight; use `.font(.system(size: 30, weight: .heavy))` for the giant titles.

### 1.4 Radii

| Token | Value | Used for |
|---|---|---|
| `radiusCard` | 16 | groups, banners, AI action rows |
| `radiusRow` | 12 | add-bar, AI result rows, primary buttons |
| `radiusSheet` | 26 | sheet top corners |
| `radiusCheckbox` | 50% | task checkbox (circle) |
| `radiusAIPick` | 6 | AI multi-select picker squares |

### 1.5 Spacing

| Token | Value | Used for |
|---|---|---|
| `padScreen` | 16 horizontal | screen body content insets |
| `padCardInner` | 13–15 | row inner padding |
| `gapRow` | 12–13 | between dot, title block, days, chevron |
| `gapGroup` | 20 vertical | between group sections |

---

## 2. Component vocabulary

Each row maps an HTML class from the demo to its SwiftUI equivalent, plus the file in our code where it lives.

| Mockup class | SwiftUI component | Our file | Notes |
|---|---|---|---|
| `.pulse-dot` (+ halo) | `PulseDot` view | `Components/PulseDot.swift` | **Add halo** — background `Circle` 4pt wider, 14–16% alpha. Cold has no halo. |
| `.days` (stacked) | `DaysSinceLabel` | `Components/DaysSinceLabel.swift` | **Restructure** — `VStack` with big number + tiny "DAYS"/"DAY"/"TODAY" subscript. |
| `.group` | `List` rows inside `Section`, `.listStyle(.insetGrouped)` | various | Cards with hairline border, 16pt radius. |
| `.row` | `InitiativeRow` inside `NavigationLink` | `Features/Initiatives/InitiativeRow.swift` | Title + meta line, days on right, chevron auto-supplied by `NavigationLink`. |
| `.row.attention` | Cold-row tint | `InitiativeRow.swift` | **Change** — gradient `gray.opacity(0.16) → clear` left-to-right, not red flat. |
| `.addbar` | `AddBar` (new) | TBD — see §6 | Dashed border, `surface2` fill, blue `+`, placeholder text. Tappable → focuses inline field. |
| `.check` / `.check.done` | Task checkbox | `InitiativeDetailView.swift` (private `TaskItemRow`) | **Change** — empty circle outline, fills green with white ✓ when done. Use `Circle().strokeBorder` + animated fill. |
| `.task.is-done .t` | Strikethrough done task | already in place | — |
| `.banner` | `AttentionBanner` (P5) | `Features/Today/AttentionBanner.swift` (future) | Gradient background, warning glyph, title + body. |
| `.ring-wrap` | Detail header with `PulseRing` | `InitiativeDetailView.swift` | Static arc in P1.5, animated in P4. |
| `.sheet` | `.sheet` + `.presentationDetents` + `.presentationDragIndicator(.visible)` | `NewInitiativeSheet.swift` | Grabber, sheet-h with Cancel/title/Add, rounded 26pt top. |
| `.sw` / `.sw.sel` | Color swatch in `NewInitiativeSheet` | already in place | Update palette to mockup hexes (see §1). |
| `.ai-action` | AI Assist action card (P6) | `Features/AIAssist/AIAssistSheet.swift` (future) | — |
| `.ai-pick` | AI multi-select | (P6) | Square (6pt radius), 2pt accent stroke, fills accent when selected. |
| `.tabbar` | `TabView` (root) | `ContentView.swift` (rework) | Blurred background, 3 tabs: Today · Initiatives · Momentum. |
| `.ipad` `.col` × 3 | `NavigationSplitView` (3-column) | P2 | Sidebar + content + detail. |

---

## 3. Screen-by-screen (iPhone)

### Today (tab 1) — P5 functional, P1.5 placeholder
- Attention banner (cold initiatives) — gradient surface.
- "Suggested focus" group — tasks with parent-initiative pulse dot on the right.
- Quick-add `AddBar`.
- **P1.5 ships a placeholder**: empty state with "Coming in P5" copy so the tab compiles and visually exists.

### Initiatives (tab 2) — already P1, **needs visual update**
- Toolbar `+ New` (top-right).
- Large title "Initiatives".
- Grouped list of `InitiativeRow`s.
- Stalest-first sort; cold row has gray gradient tint.
- Empty state: `ContentUnavailableView` ("Nothing yet. Add the first thing you're trying to keep alive.").
- Caption below list: "Sorted stalest-first — the dying thing floats up on its own."

### Initiative Detail (push) — already P1, **needs ring header in P1.5**
- Nav: `‹ Initiatives` back, `Assist` button top-right (deferred to P6, hidden in P1.5).
- `.ring-wrap` — static partial-fill `PulseRing` + name + "Cooling · 5 days since activity" line.
- `AddBar` for new tasks.
- Open / Done sections.

### Momentum (tab 3) — P4 functional, P1.5 placeholder
- 2-column grid of rings.
- "Going cold" leaderboard.
- 14-day activity sparkline.
- **P1.5 ships placeholder**.

### Sheets
- **New Initiative**: medium detent, grabber, name field, color swatches grid, Cancel/Add toolbar. Palette: blue, teal, amber, red, purple, sky.
- **Assist** (P6): action cards stacked, suggested-tasks group, "Add N selected" primary button.

---

## 4. Screen-by-screen (iPad) — P2

Three-column `NavigationSplitView`:

1. **Sidebar (264pt)** — sections "Momentum" (Today, Momentum) + "Initiatives" (list with pulse dots + tiny days) + "Settings" at bottom.
2. **Content (340pt)** — selected initiative's task list; selected task highlighted with accent tint (~14% alpha).
3. **Detail (flex)** — selected task: ring + title + "initiative · pulse · days" line, plus Notes / Created sections.

---

## 5. Navigation structure

### iPhone (compact)

```
TabView                                  ← MainTabView (new)
 ├── TodayView         · NavigationStack
 ├── InitiativesListView · NavigationStack ← already P1
 │     └── InitiativeDetailView (push)
 └── MomentumDashboardView · NavigationStack
```

### iPad (regular)

```
NavigationSplitView
 ├── Sidebar (Today / Momentum / Initiatives list / Settings)
 ├── Content (selected initiative's tasks)
 └── Detail (selected task)
```

The same models drive both; sources are `@Query` for the list, plus `AppRouter.selected{Initiative,Task}` for the iPad split-view selection (P2).

---

## 6. Deltas from current P1

What we ship today doesn't match the demo. These are the items to close in P1.5.

| # | What's in P1 now | What the demo says | Change |
|---|---|---|---|
| 1 | Pulse cold = system `.red` | Cold = mockup gray `#6B7686` | Replace pulse color tokens |
| 2 | Cold row background = `Color.red.opacity(0.08)` flat | Gray-tinted **horizontal gradient** | Use `LinearGradient` listRowBackground |
| 3 | Days label = inline `"5d"` | **Stacked** big number + tiny "DAYS" subscript | Rewrite `DaysSinceLabel` to a `VStack` |
| 4 | Pulse dot = flat colored circle | Active/cooling have **halo** (low-alpha ring) | Add background `Circle` for halo |
| 5 | Pulse colors = `.green` / `.yellow` / `.red` | `#2FD4A7` / `#F6B23C` / `#6B7686` | New semantic colors with light/dark variants |
| 6 | App is single-screen (InitiativesListView at root) | **3-tab app** (Today / Initiatives / Momentum) | Wrap in `TabView` with placeholder Today/Momentum |
| 7 | Detail header uses dot only | **Static pulse ring** + name + state line | Build `PulseRing` (static fill = days / coldAt clamped) |
| 8 | Inline "Add task" = plain `TextField` in a `Section` | **`AddBar`** — dashed border, blue `+`, distinct fill | Build `AddBar` component |
| 9 | Task checkbox = SF Symbol filled/empty circle | Custom — green-filled circle with white ✓ when done | Tighten checkbox styling |
| 10 | Sheet color palette = iOS system colors | Mockup palette (`#5B8DEF`, `#2FD4A7`, `#F6B23C`, `#FF6B6B`, `#A77BF0`, `#4FB6E0`) | Update palette in `NewInitiativeSheet` |
| 11 | Only dark mode tested | **Both dark and light** must work | Define semantic colors with both variants |
| 12 | Group headers default | All-caps eyebrow style "OPEN" / "DONE" | `.textCase(.uppercase)` + `.tracking(0.06)` |
| 13 | No Today / Momentum screens | Tab bar shows them | Add empty placeholders with "Coming soon" |

---

## 7. P1.5 plan summary

**Goal:** Match the demo visually and support both appearances. **Behavior is unchanged.**

| Step | Touches | New file? |
|---|---|---|
| Define semantic colors | new `Theme.swift` | **yes** |
| Refresh `PulseDot` (halo, new colors) | existing | no |
| Rewrite `DaysSinceLabel` (stacked) | existing | no |
| New `AddBar` component | new `AddBar.swift` | **yes** |
| Static `PulseRing` (used in detail) | new `PulseRing.swift` | **yes** |
| Update `InitiativeRow` (gradient tint, gray cold) | existing | no |
| Update `NewInitiativeSheet` (palette, polish) | existing | no |
| Update `InitiativeDetailView` (ring header, `AddBar`, eyebrows, checkbox styling) | existing | no |
| Wrap root in `TabView` | existing `ContentView.swift` | no |
| Today placeholder | new `TodayView.swift` (placeholder body for now) | **yes** |
| Momentum placeholder | new `MomentumDashboardView.swift` (placeholder body for now) | **yes** |

Out of P1.5 scope (stays in their original phases):
- Real Today triage logic (P5)
- Real Momentum dashboard charts + animated rings (P4)
- Settings screen (P7)
- iPad split view (P2)
- AI Assist sheet (P6)

After P1.5 lands → P2 (iPad / adaptive) per the unchanged roadmap.
