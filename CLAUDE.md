# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Momentum — a SwiftUI iOS app (iPhone + iPad, `TARGETED_DEVICE_FAMILY = "1,2"`).

- Bundle ID: `testing.Momentum`
- Swift 5.0, `IPHONEOS_DEPLOYMENT_TARGET = 26.5` (Xcode 26)
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES` — new types are MainActor-isolated by default. Only annotate `nonisolated` / explicit actors when intentionally leaving the main actor.

## Build / run / test

Open `Momentum.xcodeproj` in Xcode and use ⌘R / ⌘U, or from CLI:

```bash
# Build for the iOS Simulator
xcodebuild -project Momentum.xcodeproj -scheme Momentum \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests (no test target exists yet — add one before this works)
xcodebuild -project Momentum.xcodeproj -scheme Momentum \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Single test method
xcodebuild ... test -only-testing:MomentumTests/SomeTests/testSomething
```

Adjust `-destination` to a simulator that exists locally (`xcrun simctl list devices available`).

## Project layout & adding files

The Xcode target uses `PBXFileSystemSynchronizedRootGroup` pointing at `Momentum/`. **Any `.swift` file added under `Momentum/` is automatically included in the build** — do not hand-edit `Momentum.xcodeproj/project.pbxproj` to register new sources. Resources go through `Momentum/Assets.xcassets`.

Entry point is `Momentum/MomentumApp.swift` (`@main`), which hosts `ContentView`. Everything else is greenfield as of this commit.

## Vendored skills (auto-loaded from `.claude/skills/`)

- **`swiftui-pro`** — invoke when reading, writing, or reviewing SwiftUI. Refs cover navigation, layout, animations, state, accessibility, deprecated APIs.
- **`swiftdata-pro`** — invoke for any SwiftData model, query, predicate, migration, or CloudKit-sync work.
- **`swift-concurrency-pro`** — invoke for async/await, actors, `Sendable`, structured concurrency, cancellation. Especially relevant here because the target has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- **`git-commit`** — `/git-commit` to stage everything and write a feature-title + 2–3 line body.

These ship with the repo (`.claude/skills/<name>/SKILL.md` + `references/`). Source: `twostraws/SwiftUI-Agent-Skill`, `twostraws/SwiftData-Agent-Skill`, `twostraws/Swift-Concurrency-Agent-Skill` (MIT).
