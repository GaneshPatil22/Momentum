# SwiftUI — Learning by Reading Your Own App

> A guided tour of SwiftUI, using Momentum as the worked example. You know Swift well, so we skip syntax basics and focus on what's *new* about SwiftUI: the declarative model, property wrappers, view composition, data flow, and the family of standard containers / modifiers.
>
> Each section pairs a concept with a real file in this repo and (where it matters) the alternatives you could have used instead.

---

## 0 · How to use this doc

You're on the `learning` branch. This file exists only here — `main` doesn't carry it. The plan:

1. Read this doc top to bottom once — just to know what's in your toolbox.
2. Then read the **app files in the order in §3** — you'll be reading SwiftUI you already wrote.
3. Try the **exercises in §20** — most are "open this file, change *this*, see what happens".
4. When you hit something confusing, jump to the relevant section here.

You can break the app freely on this branch. `git checkout main` undoes everything you did here.

---

## 1 · SwiftUI in 60 seconds (the mental model)

**UIKit is imperative.** You build a tree of `UIView`s once, then mutate it every time state changes (`label.text = "..."`, `view.addSubview(...)`).

**SwiftUI is declarative.** You write a *function* that returns "what the UI looks like right now, given this state". When state changes, SwiftUI calls the function again. The framework diffs the old and new output, and updates the actual screen.

```
view = f(state)
```

That's it. Three implications you'll feel constantly:

- **Views are cheap, throw-away `struct`s.** SwiftUI re-creates them on every render. Don't store anything in them you want to *keep* — that's what `@State` (and friends) are for.
- **You don't reach into the view tree.** You change state; SwiftUI handles the rest.
- **Single source of truth.** Each piece of state lives in *one* place. Other views read it via bindings. If two views both think they own the same state, you'll fight the framework.

The whole language of property wrappers (`@State`, `@Binding`, `@Environment`, `@Observable`, …) exists to answer one question: *who owns this state, and who reads it?*

---

## 2 · The `View` protocol

Every screen, every row, every tiny component is a `struct: View`. The only required member is `var body: some View`.

```swift
struct PulseDot: View {
    let pulse: Pulse                       // input
    var body: some View {                  // declarative description
        Circle().fill(pulse.color)
    }
}
```

- `some View` is an **opaque return type**. It hides the (often gnarly) concrete type from the caller. You don't write `Circle<…fill…padding…>` by hand; the compiler tracks it.
- `body` is a computed property called *many* times per second. **Keep it pure and cheap.** Don't `print`, don't open files, don't compute big things — derive everything from the view's stored properties.

**Where in our code:** every file in `Momentum/Components/` and `Momentum/Features/Initiatives/` is a `View`. Good ones to start with: `Components/PulseDot.swift`, `Components/DaysSinceLabel.swift`.

### View composition

A view's `body` is *another* view. You build big screens by nesting small views.

```swift
struct InitiativeRow: View {
    let initiative: Initiative
    var body: some View {
        HStack {
            PulseDot(pulse: initiative.pulse())     // ← reuse a smaller view
            Text(initiative.name)
            DaysSinceLabel(days: initiative.daysSinceActivity())
        }
    }
}
```

That's literally how all real SwiftUI apps look. **There is no `addSubview` ever.**

---

## 3 · Reading the app in order

Read these files in this order — each one introduces ~2 new ideas:

| # | File | What it teaches |
|---|---|---|
| 1 | `Momentum/MomentumApp.swift` | `@main`, `App`, `Scene`, `WindowGroup`, environment injection |
| 2 | `Momentum/ContentView.swift` | `TabView` + `Tab`, `@modelContainer`, previews |
| 3 | `Momentum/Models/Initiative.swift` & `TaskItem.swift` | SwiftData `@Model` (not a SwiftUI thing, but you'll meet it everywhere) |
| 4 | `Momentum/Models/Pulse.swift` | Plain Swift type + extension on a model |
| 5 | `Momentum/Theme/Theme.swift` | Custom `Color` extensions, dynamic dark/light |
| 6 | `Momentum/Components/PulseDot.swift` | `@ScaledMetric`, `@Environment`, accessibility hide |
| 7 | `Momentum/Components/DaysSinceLabel.swift` | `VStack`, `Text` modifiers, accessibility label |
| 8 | `Momentum/Components/AddBar.swift` | `@Binding`, `@FocusState.Binding`, `TextField`, custom border |
| 9 | `Momentum/Components/PulseRing.swift` | `ZStack`, `Circle.trim()`, `StrokeStyle` |
| 10 | `Momentum/Services/PulseEngine.swift` & `ActivityService.swift` | `@Observable`, why services aren't views |
| 11 | `Momentum/Features/Initiatives/InitiativeRow.swift` | View composition, `@ViewBuilder`, `listRowBackground` |
| 12 | `Momentum/Features/Initiatives/InitiativesListView.swift` | `@Query`, `NavigationStack`, `.navigationDestination`, `.sheet` |
| 13 | `Momentum/Features/Initiatives/NewInitiativeSheet.swift` | `Form`, `LazyVGrid`, `@FocusState`, `.presentationDetents` |
| 14 | `Momentum/Features/Initiatives/InitiativeDetailView.swift` | The big one — `Section`s, `@Environment(ActivityService.self)`, custom checkbox, `.contentTransition` |
| 15 | `Momentum/Features/Today/TodayView.swift` & `Momentum/Features/Momentum/MomentumDashboardView.swift` | `ContentUnavailableView` |

You can re-read this doc with each file open in Xcode.

---

## 4 · Property wrappers — the SwiftUI superpower

This is the chapter that matters most. SwiftUI's data flow IS its property wrappers.

### `@State` — local mutable storage owned by the view

```swift
@State private var showingSheet = false      // InitiativesListView.swift
@State private var newTaskTitle = ""         // InitiativeDetailView.swift
```

- **The view doesn't own it directly** — it's stored in SwiftUI's framework. The view just has a *reference* to it.
- That's why `struct`s being thrown away on each render doesn't lose your state.
- Use `@State` for **transient, view-local** state: a toggle, an entry field, a presentation flag.
- The `private` is convention — `@State` belongs to *this* view; nobody else should touch it.

**Alternatives**
- For state that lives outside the view → `@Observable` class + `@Environment`.
- For state that lives in a *parent* → pass `Binding` (next).

### `@Binding` — two-way reference to someone else's state

```swift
struct AddBar: View {
    @Binding var text: String     // parent owns the actual String
    @FocusState.Binding var isFocused: Bool
    ...
}

// Caller:
AddBar(text: $newTaskTitle, isFocused: $newTaskFocused, ...)
```

- `$variable` returns the binding to a `@State`/`@Bindable`/`@Observable` property.
- Use `@Binding` when a child view needs to **read AND write** state that a parent owns.

**Alternatives**
- If a child just *reads*, pass the value, not a binding.
- If a child needs to *signal an event* (rather than mutate), pass a closure: `let onSubmit: () -> Void` (see `AddBar`).

### `@FocusState` — which field is the keyboard pointed at?

```swift
@FocusState private var nameFocused: Bool                // NewInitiativeSheet.swift
TextField("Name", text: $name).focused($nameFocused)
.onAppear { nameFocused = true }
```

- Lives on a view; you mutate it to focus / unfocus a field.
- Pass it to children with `@FocusState.Binding` (we do this in `AddBar`).
- Variants: `@FocusState var f: SomeEnum?` lets you express "which of N fields is focused".

### `@Environment` — read values from the surrounding context

Two flavors:

```swift
@Environment(\.modelContext) private var context              // keyPath form (system values)
@Environment(\.dismiss) private var dismiss
@Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

@Environment(ActivityService.self) private var activityService    // type form (your @Observable values)
```

- The **keyPath form** reads built-in values: model context, dismiss action, accessibility settings, color scheme, etc.
- The **type form** (iOS 17+) reads custom `@Observable` objects you put in the environment with `.environment(myService)`.

**Where it's set up:** `MomentumApp.swift` injects `ActivityService` once, all views downstream just read it.

**Alternatives (legacy)**
- `@EnvironmentObject` (pre-iOS 17) — same idea but required `ObservableObject` + `@Published`. We don't use it.

### `@Observable` — the modern "this class can drive views"

```swift
@Observable
final class ActivityService {
    @ObservationIgnored private let context: ModelContext   // not observable
    func toggleDone(_ task: TaskItem) { ... }
}
```

- Macro-generated. Stored properties become observable automatically. Views that **read** any property re-render when it changes.
- `@ObservationIgnored` opts a property *out* — useful for things like `ModelContext` that you don't want SwiftUI tracking.
- Inject with `.environment(service)`, read with `@Environment(ActivityService.self)`.

**Alternatives (legacy)**
- `ObservableObject` + `@Published` + `@StateObject` / `@ObservedObject` — the iOS 13–16 way. Still works, but the new system is faster (observes the *properties you read*, not the whole object) and has less ceremony.

### `@Bindable` — make an `@Observable`/`@Model` instance bindable from another view

```swift
@Bindable var task: TaskItem    // can now write TextField("Title", text: $task.title)
```

- You'd use this when a view *receives* a model and needs to bind to its properties without owning them.
- We don't use it in P1.5 because all our task mutations go through `ActivityService`, not direct binding.

### `@ScaledMetric` — scale a number with Dynamic Type

```swift
@ScaledMetric private var scaledSize: CGFloat
init(pulse: Pulse, size: CGFloat = 12) {
    _scaledSize = ScaledMetric(wrappedValue: size)
}
Circle().frame(width: scaledSize, height: scaledSize)
```

- For numeric values that should grow when the user picks a larger text size (icon dimensions, custom paddings).
- Wraps any `CGFloat`-like value.

### `@Query` — SwiftData live results (not SwiftUI per se, but lives in views)

```swift
@Query(
  filter: #Predicate<Initiative> { !$0.isArchived },
  sort: \Initiative.lastActivityAt, order: .forward
)
private var initiatives: [Initiative]
```

- Re-runs when the underlying store changes; the view re-renders automatically.
- **Only works inside a `View`.** Don't use in services / non-view classes — fetch through `ModelContext` instead.

### Summary table

| Wrapper | Used for | Typical scope |
|---|---|---|
| `@State` | Local mutable view state | This view only |
| `@Binding` | Read+write parent's state | Child views |
| `@FocusState` | Keyboard focus tracking | One screen |
| `@Environment(\.x)` | Built-in env values | Any depth |
| `@Environment(T.self)` | Custom `@Observable` instance | Any depth |
| `@Observable` (class) | Shared mutable state class | Service / VM |
| `@Bindable` | Bind to props of `@Observable`/`@Model` | Any view |
| `@ScaledMetric` | Dynamic-Type-aware CGFloat | Any |
| `@Query` | SwiftData live fetch | Inside a `View` only |

---

## 5 · Modifiers — order matters

A modifier wraps a view in another view. They chain top-to-bottom.

```swift
Text("Hello")
    .font(.title)              // wraps in a font-applying view
    .foregroundStyle(.red)     // wraps that in a foreground-style view
    .padding()                 // wraps that in a padding view
    .background(.blue)         // wraps that in a background view
```

`.padding().background(.blue)` gives padding INSIDE a blue background.
`.background(.blue).padding()` gives padding OUTSIDE a blue background.
Same modifiers, different outcomes.

**Rule of thumb:** sizing/layout modifiers (`.padding`, `.frame`, `.background`) compose order-sensitively. Style modifiers (`.font`, `.foregroundStyle`, `.opacity`) generally don't.

**Modern API choices (project conventions, from `.claude/skills/swiftui-pro/references/api.md`):**

| Use | Not |
|---|---|
| `.foregroundStyle(...)` | `.foregroundColor(...)` |
| `.clipShape(.rect(cornerRadius: 12))` | `.cornerRadius(12)` |
| `Tab("Title", systemImage: "...") { ... }` (iOS 18+) | `.tabItem { Label(...) }` |
| `.overlay(alignment:) { ... }` | `.overlay(content, alignment:)` |
| `.topBarLeading` / `.topBarTrailing` | `.navigationBarLeading` / `.navigationBarTrailing` |
| `.scrollIndicators(.hidden)` | `showsIndicators: false` |
| `Text("\(red)\(blue)")` (interpolation) | `Text(...) + Text(...)` |

---

## 6 · Layout containers

### `VStack` / `HStack` / `ZStack`

```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Title")
    Text("Subtitle").foregroundStyle(.secondary)
}
```

- `VStack` — vertical. `HStack` — horizontal. `ZStack` — depth (overlap).
- `alignment` is on the *cross axis*: VStack aligns horizontally, HStack aligns vertically.
- `spacing` is between children; nil means default.

**Where:** `InitiativeRow` is an `HStack`; the row's title block is a `VStack`; `PulseDot`'s halo + dot uses `.background { Circle() … }` rather than `ZStack` — both work.

### `Spacer`

```swift
HStack {
    Text("Left")
    Spacer()           // eats all available space
    Text("Right")
}
```

That's how `InitiativeRow` pushes the days-since label to the right.

### `frame`, `padding`

```swift
.frame(width: 12, height: 12)            // fixed size
.frame(maxWidth: .infinity, alignment: .leading)   // greedy width, content aligned left
.padding(.horizontal, 15)
.padding(.vertical, 12)
.padding(15)                                       // all sides
```

### `LazyVGrid` / `Grid`

```swift
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
    ForEach(presets, id: \.self) { hex in
        Circle().fill(Color(hex: hex) ?? .gray)
    }
}
```

- `LazyVGrid` — column-based, lazy (children created as scrolled into view). Used in `NewInitiativeSheet`.
- `Grid` (iOS 16+) — a true 2D grid; you write rows explicitly. More expressive but eager.

**Alternatives**
- For static rows/columns, just nest `HStack`s in a `VStack`.
- For one big flexible layout, look into the `Layout` protocol (iOS 16+) to write custom layouts.

---

## 7 · `List`, `Section`, `ForEach`

The bread and butter of any iOS app.

```swift
List {
    Section { ... }
    Section("Open") {
        ForEach(openTasks) { task in
            TaskItemRow(task: task)
        }
        .onDelete { offsets in deleteTasks(openTasks, at: offsets) }
    }
}
```

- `List` is a scrollable container with built-in styling.
- `Section` groups rows. The trailing closure variant takes a string for the header.
- `ForEach` iterates an `Identifiable` collection — your `@Model`s and most Swift collections work directly.
- `.onDelete` adds swipe-to-delete. `.onMove` adds reorder.

**Variants**
- `.listStyle(.insetGrouped)` — the rounded-card look (our default).
- `.listStyle(.plain)` — edge-to-edge rows.
- `.listRowBackground(view)` — replace per-row background (we use it for the cold-row gradient tint).
- `.listRowSeparator(.hidden)` — hide the divider for a row.
- `.scrollContentBackground(.hidden)` — make the list itself transparent so a custom background shows through.

**Alternatives**
- `ScrollView` + `LazyVStack` — when you don't want any List styling and want full control.
- `LazyVGrid` — when you want multi-column.

---

## 8 · Navigation

### `NavigationStack` + `NavigationLink` + `.navigationDestination`

```swift
NavigationStack {
    List {
        ForEach(initiatives) { initiative in
            NavigationLink(value: initiative) {       // ← VALUE, not destination
                InitiativeRow(initiative: initiative)
            }
        }
    }
    .navigationDestination(for: Initiative.self) { initiative in
        InitiativeDetailView(initiative: initiative)
    }
    .navigationTitle("Initiatives")
}
```

- This is the **value-based** navigation API (iOS 16+). `NavigationLink` only carries a value; the destination is registered separately by type.
- Why? You can drive the same destination from multiple links *and* from code (`@State path` binding).
- The old API `NavigationLink(destination:)` and `NavigationView` are deprecated.

### `TabView` with the new `Tab` API (iOS 18+)

```swift
TabView {
    Tab("Today", systemImage: "sun.max") { TodayView() }
    Tab("Initiatives", systemImage: "list.bullet.rectangle") { InitiativesListView() }
}
.tint(AppColor.accent)
```

- The old `.tabItem { Label(...) }` form still works but `Tab` is cleaner.
- Each tab has its own `NavigationStack`; switching tabs preserves the nav state.

### `NavigationSplitView` (P2 — iPad)

Three-column layout (sidebar / content / detail) that collapses gracefully on iPhone. We'll use it in P2.

```swift
NavigationSplitView {
    SidebarView()
} content: {
    InitiativeListColumn()
} detail: {
    TaskDetailColumn()
}
```

---

## 9 · Sheets & modals

```swift
@State private var showingNewSheet = false

.sheet(isPresented: $showingNewSheet) {
    NewInitiativeSheet()
}
```

Inside the sheet:

```swift
.presentationDetents([.medium, .large])
.presentationDragIndicator(.visible)
```

- `.sheet(item:)` is a richer variant: pass an `Identifiable?` binding; non-nil → present a sheet with that item; setting to nil → dismiss.
- `Environment(\.dismiss)` gives the sheet a closure to dismiss itself.

**Alternatives**
- `.fullScreenCover(isPresented:)` — same idea but covers the whole screen.
- `.popover(isPresented:)` — iPad/macOS popover style.
- `.alert(_:isPresented:)` / `.confirmationDialog(...)` — for short questions.

---

## 10 · Text & SF Symbols

```swift
Text("Hello")
    .font(.body)                       // dynamic — scales with text size setting
    .font(.system(size: 16, weight: .semibold))   // explicit (use sparingly)
    .fontDesign(.rounded)
    .monospacedDigit()
    .foregroundStyle(.secondary)
    .strikethrough(task.isDone)
    .tracking(0.7)                     // letter-spacing
```

```swift
Image(systemName: "checkmark.circle.fill")
    .font(.title3)                     // scale via font
    .foregroundStyle(.green)
    .contentTransition(.symbolEffect(.replace))   // morphs symbol on change
```

- SF Symbols are *first-party iconography* — use them whenever you can. Browse at: SF Symbols app from Apple.
- `Label("Add task", systemImage: "plus")` combines text + symbol; SwiftUI picks the right style for the context.

---

## 11 · Color & ShapeStyle

```swift
Color.red
Color(.systemBackground)
Color(red: 0.5, green: 0.6, blue: 0.9)

// Our custom dynamic colors:
AppColor.surface             // dark or light depending on appearance
PulseColor.active            // dark or light variant of green
```

Anywhere a "color" goes you can also pass a more general **ShapeStyle**:

```swift
.foregroundStyle(.primary)              // semantic — light/dark adapts
.foregroundStyle(.secondary)
.foregroundStyle(.tint)                 // current tint color (set via .tint(...))
.foregroundStyle(.tertiary)
.foregroundStyle(LinearGradient(colors: [.red, .blue], startPoint: .leading, endPoint: .trailing))
```

ShapeStyle includes solid colors, hierarchical (`.primary`/`.secondary`/etc.), gradients, materials (`.regularMaterial`), and more.

---

## 12 · Shapes & paths

```swift
Circle()
RoundedRectangle(cornerRadius: 12)
Rectangle()
Capsule()
```

Shapes ARE views. Common modifiers:

```swift
Circle()
    .fill(PulseColor.active)                       // solid
    .stroke(.red, lineWidth: 2)                    // outline
    .strokeBorder(.red, lineWidth: 2)              // outline inset (so it doesn't extend outside the shape)
    .frame(width: 12, height: 12)

Circle()
    .trim(from: 0, to: 0.7)                        // partial arc
    .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
    .rotationEffect(.degrees(-90))                 // start at the top
```

That last pattern is `PulseRing.swift`. The arc grows from 0 to `progress` as the initiative gets stale.

**For custom shapes:** make a `struct: Shape` with a `path(in:)` method. We don't need it yet — most needs are covered by built-ins + trim.

---

## 13 · Animation basics

Two patterns:

### 1. Implicit animation — "animate any state change to this view"

```swift
.animation(.spring, value: someState)
```

### 2. Explicit transaction — "wrap this change in an animation"

```swift
withAnimation(.spring) {
    showingDetail.toggle()
}
```

For symbol replacement:

```swift
.contentTransition(.symbolEffect(.replace))
```

For matched-geometry (one view morphs into another):

```swift
.matchedGeometryEffect(id: "ring-\(id)", in: namespace)
```

We'll lean on these heavily in P4 (animated pulse rings).

**Respect Reduce Motion:**

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
let animation: Animation? = reduceMotion ? nil : .spring
```

---

## 14 · SwiftData × SwiftUI

The integration points:

```swift
// MomentumApp.swift
WindowGroup { ContentView() }
    .modelContainer(container)           // injects \.modelContext too

// Any view
@Environment(\.modelContext) private var context
@Query(filter: ..., sort: ...) private var initiatives: [Initiative]

context.insert(newTask)
try context.save()
context.delete(someInitiative)
```

Three rules from the vendored SwiftData skill:

- **`ModelContext` never crosses actor boundaries.** Stay on MainActor (the project default).
- **`@Query` only works inside a `View`.** For non-view code, do `try context.fetch(FetchDescriptor<T>(...))`.
- **Models are observable by default.** Reading a model property in a view body subscribes the view to that property's changes.

---

## 15 · Accessibility

The bar for accessibility in iOS is *high* and SwiftUI makes it cheap.

Patterns we already use:

```swift
.accessibilityHidden(true)                          // hide decorative element from VoiceOver
.accessibilityLabel("CoreLearnly, cooling, 4 days since activity")
.accessibilityValue("Completed")
.accessibilityAddTraits(.isButton)
.accessibilityElement(children: .combine)           // combine child labels into one
```

Environment readbacks:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@Environment(\.accessibilityDifferentiateWithoutColor) private var diffColor
@Environment(\.dynamicTypeSize) private var typeSize
```

Then *act on them* — e.g. our `PulseDot` swaps to SF Symbols (which vary by shape, not just color) when Differentiate Without Color is on.

---

## 16 · Previews

```swift
#Preview {
    PulseDot(pulse: .cooling)
        .padding()
}

#Preview("Cold dot, big") {
    PulseDot(pulse: .cold, size: 24)
}
```

- The trailing closure returns a `View`. You can wire up environment values, sample data, dark mode, etc.
- For previews that need SwiftData:

```swift
#Preview {
    let container = try! ModelContainer(
        for: Initiative.self, TaskItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ContentView()
        .modelContainer(container)
        .environment(ActivityService(context: container.mainContext))
}
```

- Previews crash silently sometimes — check the canvas's diagnostics panel.

---

## 17 · Architecture options

This is where SwiftUI is opinionated but not dogmatic.

| Pattern | Idea | Our take |
|---|---|---|
| **MV + `@Observable`** | Views own their state; small `@Observable` services for shared state. No VM layer. | **What we use.** Modern, low ceremony, plays well with SwiftData. |
| **MVVM** (per-screen ViewModel) | Each screen has a `@Observable` class that holds its state and business logic. | Works, but with SwiftUI's data flow you mostly end up writing thin pass-through VMs. We chose to skip the layer. |
| **TCA** (The Composable Architecture, Point-Free) | Reducers + immutable state + effects. Strong testability, formal structure. | Excellent for big apps with complex flows. Heavy for a 1-developer app this size. Not used here. |
| **MVC / classic UIKit-style** | Doesn't really map to SwiftUI; SwiftUI's data flow replaces it. | n/a |
| **Redux / Flux clones** (RxSwift / Combine / custom) | Streams of state changes. | SwiftUI's own observation already does this — extra layers usually subtract clarity. |

Read `docs/ARCHITECTURE.md` for our specific reasoning.

---

## 18 · Common pitfalls

- **Mutating `@State` outside the main thread** — silent failure or crashes. The project's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` saves you, but if you ever step into background code, hop back to MainActor before mutating.
- **Computing in `body`** — `body` runs *a lot*. Don't sort/filter big arrays inside it; cache derived values in a computed property or `@State`.
- **Two sources of truth** — duplicating state ("the parent has `count`, the child has `count`") is a bug. Pass `Binding<Int>` instead.
- **`GeometryReader` everywhere** — usually wrong. Use `containerRelativeFrame`, `.frame(maxWidth:.infinity)`, or the `Layout` protocol.
- **`onTapGesture` on a non-button** — bad for VoiceOver. Use `Button` and style it `.buttonStyle(.plain)` if you don't want default button looks.
- **Forgetting `try context.save()` after a SwiftData mutation** — autosave is unpredictable; be explicit for anything that matters.
- **`@StateObject` vs `@ObservedObject`** confusion (legacy) — irrelevant when you use `@Observable` + `@Environment`. Just use the new system.
- **Trying to read `@Environment(\.modelContext)` in `App.init()`** — it doesn't exist there. Create the container manually in `init` (see `MomentumApp.swift`).
- **Putting `@Query` in a non-view class** — silently broken. Use `ModelContext.fetch(...)`.

---

## 19 · The big SwiftUI vocabulary cheat sheet

| You want to | Use |
|---|---|
| Show text | `Text("Hello")` |
| Show an icon | `Image(systemName: "checkmark")` |
| Stack vertically | `VStack { ... }` |
| Stack horizontally | `HStack { ... }` |
| Overlap | `ZStack { ... }` |
| Push apart | `Spacer()` |
| Pad | `.padding(...)` |
| Make it big/small | `.frame(width:height:)` |
| Make it scrollable | `ScrollView { ... }` |
| Tabular UI | `List { ... }` |
| Repeat | `ForEach(items) { item in ... }` |
| Section header | `Section("Title") { ... }` |
| Make a button | `Button("Tap me") { action() }` |
| Push a new screen | `NavigationLink(value: x) { row }` + `.navigationDestination(for:)` |
| Present a sheet | `.sheet(isPresented: $flag) { content }` |
| Confirm with the user | `.alert(...)` or `.confirmationDialog(...)` |
| Local toggle state | `@State private var flag = false` |
| Parent's state in child | `@Binding var flag: Bool` |
| Shared mutable object | `@Observable class …` + `.environment(obj)` + `@Environment(Obj.self)` |
| SwiftData fetch | `@Query(filter:sort:)` |
| SwiftData write | `@Environment(\.modelContext)` then `context.insert/delete` + `try context.save()` |
| Animate a state change | `.animation(.spring, value: x)` or `withAnimation { ... }` |
| Accessibility label | `.accessibilityLabel("...")` |
| Custom dark/light color | extension on `Color` (see `Theme.swift`) |

---

## 20 · Practice exercises

Each one is small. Try them in order — they build on each other.

### Set 1 — Modifiers and layout (easy)

1. **Open `Components/PulseDot.swift`.** Change the default `size` from 12 to 20 and see every dot in the app scale up. Then revert.
2. **Open `Components/DaysSinceLabel.swift`.** Swap the `VStack` for an `HStack` and the layout flips to "5 DAYS" inline. Restore.
3. **In `Features/Initiatives/InitiativeRow.swift`**, add a `.background(AppColor.surface2)` *before* the `.listRowBackground` line. Notice you broke the row tinting — explain to yourself why (order matters; `listRowBackground` sets the row's actual background, but `.background` paints inside the row).
4. **In `InitiativeRow`**, change `HStack(spacing: 13)` to `HStack(spacing: 30)` and observe how everything just spreads out. SwiftUI re-renders, you didn't have to recalculate frames.

### Set 2 — State and bindings

5. **In `InitiativesListView.swift`**, find `@State private var showingNewSheet = false`. Add a `Text("Sheet flag is \(showingNewSheet ? "on" : "off")")` just under the toolbar — toggle the sheet, see the text flip.
6. **Build a tiny counter view** in a new file (ask first per the no-new-files rule, or just inline at the bottom of `ContentView.swift`):
   ```swift
   struct Counter: View {
       @State private var count = 0
       var body: some View {
           Button("Tapped \(count)") { count += 1 }
       }
   }
   ```
   Add `Counter()` to one of the tabs. Notice you didn't have to wire `IBAction`, `@objc`, or anything — the closure IS the action.
7. **Convert the counter to use a `@Binding`** — make the parent own `count`, pass `$count` in. Same behavior, different ownership.

### Set 3 — SwiftUI ↔ SwiftData

8. **In `InitiativeDetailView.swift`**, look at the `openTasks` and `doneTasks` computed properties. They `.filter` and `.sorted` on every render. Why is that OK here? (Hint: small data, runs on main actor, would be a P8 perf concern only.)
9. **Open `InitiativesListView.swift`** and change the `@Query` sort order from `.forward` (stalest-first) to `.reverse` (most-recent-first). Run the app — the list reorders without you doing anything else.
10. **Add a "Mark all done" button** to `InitiativeDetailView`. It should iterate open tasks and call `activityService.toggleDone(task)` for each. Try with and without explicit `try? context.save()` — the service already saves, so the explicit call is unnecessary.

### Set 4 — Navigation and presentation

11. **Add a confirm dialog** when deleting an initiative in `InitiativesListView`. Use `.confirmationDialog("Delete this initiative?", isPresented: $showingDelete, titleVisibility: .visible)`.
12. **Make the new-initiative sheet use only the `.medium` detent.** Notice you can't drag it bigger.
13. **Add a "long-press to rename" context menu** on `InitiativeRow`. Use `.contextMenu { Button("Rename", action: …) }`.

### Set 5 — Modern API

14. **Open `Theme.swift`**. Change a dark-mode hex (say `AppColor.bg`) to something jarring (`0xFF00FF`). Run in dark mode → magenta everywhere. Run in light mode → unchanged. That's how the dynamic provider isolates the variants.
15. **In `ContentView.swift`**, change `.tint(AppColor.accent)` to `.tint(.orange)`. Every nav button, tab indicator, and primary control turns orange.
16. **Read `Components/PulseRing.swift`** and trace what `Circle().trim(from: 0, to: progress)` does. Try `trim(from: 0.2, to: 0.8)` — you get a partial arc starting at 20% and ending at 80%.

### Set 6 — Accessibility

17. **Turn on VoiceOver in the simulator** (Cmd+Option+5 or settings). Tap an initiative row. The label should read "CoreLearnly, cooling, 4 days since activity" — that's our `.accessibilityLabel(...)` doing its job.
18. **Toggle Differentiate Without Color** in simulator accessibility settings. The pulse dots should switch from "all colored circles" to "differently-shaped SF Symbols (circle.fill / circle.lefthalf.filled / circle)".
19. **Set Dynamic Type to AX5 (the largest)** in simulator settings. Notice that the dots grow too — that's `@ScaledMetric`. The days number also grows. The whole row should reflow without truncating.

---

## 21 · Further reading

- **Apple docs:**
  - [Learning SwiftUI](https://developer.apple.com/tutorials/swiftui) — the official tutorial
  - [SwiftUI framework reference](https://developer.apple.com/documentation/swiftui)
  - [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- **In-repo:**
  - `.claude/skills/swiftui-pro/references/` — modern API rules, accessibility, navigation, performance, hygiene
  - `.claude/skills/swiftdata-pro/references/` — SwiftData specifics (predicates, indexing, CloudKit)
- **Community:**
  - **Hacking with Swift** — Paul Hudson's *100 Days of SwiftUI* is the most-recommended free course
  - **objc.io** — Swift Talk podcast (deep architectural conversations)
  - **Point-Free** — paid, leans toward TCA; great for *why* not just *how*

---

## TL;DR

If you remember three things:

1. **`view = f(state)`** — change state, SwiftUI re-renders. You never mutate views.
2. **Property wrappers describe who owns and reads state** — `@State` (this view), `@Binding` (parent's), `@Environment` (anywhere up the tree), `@Observable` (shared object).
3. **Modifiers wrap, in order.** `.padding().background(.blue)` and `.background(.blue).padding()` are different views.

Everything else is vocabulary.
