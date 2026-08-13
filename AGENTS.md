# ActionMenu: Agent Guidelines

You are an AI engineering agent helping build **ActionMenu**, a SwiftUI library that provides a flexible and easy-to-use menu component for iOS applications, similar to the one in Apple's built-in mail app.

## Core Directives

1. **Adhere to the docs:** Always validate your plan against `README.md`, `Package.swift`, and `AGENTS.md`.
2. **Documentation Maintenance (Mandatory):** You are responsible for keeping all documentation files accurate and synchronised with the codebase.
3. **SwiftUI Previews:** Ensure every reusable component has a working `#Preview` with sample data.
4. **No Clutter:** Do not create files outside the established project structure.
5. **Public API is sacred:** Never break backward compatibility without a documented deprecation path.
6. **Load skills before relevant work:** Before starting a task that matches a skill's description, use the `skill` tool to load it. Skills are NOT loaded automatically — you must invoke them explicitly. Refer to the Installed Agent Skills table below to determine which skill applies.

## Technical Stack

- **Language:** Swift 6.3
- **UI Framework:** SwiftUI (iOS 18+)
- **Package Manager:** SPM (single target: `ActionMenu`)
- **Concurrency:** Swift strict concurrency checking (`Sendable`, `@MainActor`)
- **Testing:** Swift Testing framework

## Project Conventions

### Public API Design

- Use `.actionMenu(...)` view modifier as the primary entry point
- Support custom styling via `ActionMenuStyle` protocol and `.actionMenuStyle(...)` modifier
- Use `@available(iOS, introduced: X, renamed: "newName")` for API migration
- Prefer protocol-based customisation over closure-based
- All public types must be `public` (not `open` unless subclassing is intended)
- Use `struct` over `class` for all model and configuration types
- Conform to `Sendable` for all public model/value types

### Backporting Pattern

When using iOS version-gated APIs, use the backporting pattern:

```swift
extension View {
  @ViewBuilder
  func _someModifier() -> some View {
    if #available(iOS 26, *) {
      self.modifier(ModernModifier())
    } else {
      self.modifier(LegacyModifier())
    }
  }
}
```

### Documentation Comments

All public API must have DocC documentation comments:

```swift
/// The style for the action menu's background and appearance.
///
/// To configure the style for all action menus in a view hierarchy,
/// use the `.actionMenuStyle(_:)` modifier.
public protocol ActionMenuStyle: Sendable {
  // ...
}
```

### ContentBuilder Adoption

The library uses Apple's `@ContentBuilder` (introduced at WWDC26) instead of `@ViewBuilder` for all public API content closures.

- Requires Swift 6.0+ / Xcode 27+ to build
- Fully backward compatible at runtime — works with any deployment target
- Source-compatible with `@ViewBuilder` — existing code compiles without changes
- Provides better type-checking performance for complex menu content

**Convention:**

```swift
public func actionMenu(
  title: String,
  isPresented: Binding<Bool>,
  @ContentBuilder content: @escaping () -> some View
) -> some View {
  // ...
}
```

Do NOT add `@available` guards — `@ContentBuilder` is a compiler feature that does not
affect runtime compatibility.

### Styling System

- Define a `ActionMenuStyle` protocol with required methods
- Provide a default style that mimics Apple's Mail app appearance
- Use environment-based style propagation via `@Environment(\.actionMenuStyle)`

### Module Structure

```
Sources/
  ActionMenu/
    ActionMenu.swift         — View modifier entry point
    Styling.swift            — Button and label styles (MenuLabelStyle, ActionMenuButtonStyle)
    Backport.swift           — iOS version backporting utilities

Examples/
  ActionMenuSample/          — Sample iOS app demonstrating usage
```

## Tooling & Skills

### Luca

Tooling is managed by Luca CLI. Luca version is pinned in `.luca-version`.

### Setup

Run `luca install` in the project root to install all tools and skills.

### Installed Agent Skills

| Skill | Source | Purpose |
|-------|--------|---------|
| **swiftui-pro** | twostraws/SwiftUI-Agent-Skill | SwiftUI best practices, view modifiers, data flow, accessibility |
| **swift-concurrency-pro** | twostraws/Swift-Concurrency-Agent-Skill | async/await, actors, Sendable, structured concurrency |
| **swift-testing-pro** | twostraws/Swift-Testing-Agent-Skill | Swift Testing framework patterns, test structure |
| **stratos-core** | peterfriese/Stratos | API design via Progressive Disclosure methodology |
| **stratos-swift** | peterfriese/Stratos | Swift library/SDK design patterns |
| **stratos-swiftui** | peterfriese/Stratos | SwiftUI component design patterns, modifier chains, Style protocols |

### When to Load Which Skill

| Task type | Skill to load |
|-----------|---------------|
| Designing new public API, protocols, modifiers | `stratos-core`, `stratos-swift`, `stratos-swiftui` |
| Implementing a SwiftUI component or ViewModifier | `stratos-swiftui`, `swiftui-pro` |
| Reviewing SwiftUI code for best practices | `swiftui-pro` |
| Reviewing concurrency correctness (Sendable, actors) | `swift-concurrency-pro` |
| Writing unit tests with Swift Testing | `swift-testing-pro` |
| Building a Swift library/SDK | `stratos-swift` |

All skills live in `.agents/skills/`. Skills must be loaded explicitly using the `skill` tool when a task matches the skill's description. See Core Directive 6.

## OpenCode Agent Fleet

ActionMenu uses a fleet of specialised OpenCode agents. The **chief-of-staff** is the sole primary agent; all expert agents are `mode: subagent` — hidden from the GUI and invocable only by the chief-of-staff via the `task` tool. Configuration lives in `.opencode/agents/` at the project root.

### Hierarchy

```
User (GUI)
  │
  ▼
chief-of-staff         ←─ Primary agent, always visible in dropdown, Flash on Go
  │  edit: deny | bash: deny | task: * allow
  │  Controls ALL delegation — CANNOT write files or run commands itself
  │
  ├──→ architect (subagent, Pro on Go $1.74/$3.48)
  │     Produces: API design reviews, protocol blueprints, modifier chain proposals
  │
  ├──→ engineer (subagent, Flash on Go $0.14/$0.28)
  │     Receives: tasks from chief of staff with clear acceptance criteria
  │     Returns: implemented code → verified by chief of staff
  │
  ├──→ code-reviewer (subagent, Flash on Go $0.14/$0.28)
  │     Produces: review reports (ERROR/WARNING/NITPICK)
  │
  ├──→ quality-assurance (subagent, Flash on Go $0.14/$0.28)
  │     Receives: tasks from chief of staff
  │     Returns: tests → verified by chief of staff
  │
  ├──→ docs-writer (subagent, Flash on Go $0.14/$0.28)
  │     Produces: README updates, DocC comments, migration guides
  │
  └──→ boilerplate (subagent, North Mini Code Free on Zen — FREE)
        Only for trivial formatting, preview scaffolding, simple renames
```

### Provider Strategy

Two providers are configured in `opencode.jsonc`:

| Provider | Model Prefix | Cost Model | Use Case |
|----------|-------------|------------|----------|
| **Go** | `opencode-go/` | $10/mo subscription | Primary — all agents route here for cost efficiency |
| **Zen** | `opencode/` | Pay-as-you-go | Fallback and free-tier models |

### Agents

| Agent | Mode | Model | Cost (in/out per 1M) | Purpose |
|-------|------|-------|----------------------|---------|
| **chief-of-staff** (default) | `primary` | DeepSeek V4 Flash | $0.14 / $0.28 | Orchestration, planning, general Q&A |
| **architect** | `subagent` | DeepSeek V4 Pro | $1.74 / $3.48 | Public API design, protocol design, styling system |
| **engineer** | `subagent` | DeepSeek V4 Flash | $0.14 / $0.28 | Feature implementation, bug fixes, refactoring |
| **code-reviewer** | `subagent` | DeepSeek V4 Flash | $0.14 / $0.28 | Code review, iOS idioms, concurrency safety |
| **quality-assurance** | `subagent` | DeepSeek V4 Flash | $0.14 / $0.28 | Swift Testing tests, edge cases, preview coverage |
| **docs-writer** | `subagent` | DeepSeek V4 Flash | $0.14 / $0.28 | README, DocC, migration guides |
| **boilerplate** | `subagent` | North Mini Code Free | FREE | Lightweight formatting, scaffolding |

### Custom Commands

| Command | Description |
|---------|-------------|
| `/audit` | Runs @architect, @code-reviewer, and @docs-writer in sequence, consolidates findings |

### Cost-Saving Rules

1. **Chief of staff is always Flash:** DeepSeek V4 Flash via Go (~158K requests/month within the $10 flat fee). Covers 90%+ of runtime cost.
2. **Pro sparingly, on architecture only:** Architect uses DeepSeek V4 Pro but is invoked infrequently — only when API design decisions are needed.
3. **Subagent-only access:** Expert agents are `mode: subagent` — hidden from the GUI dropdown. Only the chief-of-staff can invoke them via the `task` tool. This prevents accidental selection of expensive models and enforces the orchestration hierarchy.
4. **Free for trivial work:** `@boilerplate` (North Mini Code Free on Zen) for formatting, scaffolding — keeps trivial work off the Go cap.

## Session & Process Rules (Mandatory)

### 1. Phase Gate Checkpoint

Before executing ANY implementation task, you MUST:
- Present a 2-3 bullet plan of what you're about to do
- Wait for user confirmation before proceeding
- **Orchestrator override:** If the task prompt explicitly states "Plan already approved" or "Skip the phase gate" at the top, bypass the gate and proceed directly to implementation.

### 2. Build & Compilation Discipline

- NEVER claim the library compiles without actually running the build command
- If the same build issue persists after 2 fix attempts, STOP and ask the user for strategy

### 3. Documentation Sync (Every Task)

After completing any task, IMMEDIATELY update:
- `README.md` — if API surface, installation, or usage changed
- `AGENTS.md` — add any new rules, patterns, or lessons learned

### 4. Prohibited Technologies

- No UIKit unless SwiftUI is genuinely impossible for the use case
  - **Documented exception — programmatic share presentation:** SwiftUI's `ShareLink`
    only presents when its rendered view is tapped; there is no programmatic API to
    present a share sheet from a button *action*. When an action must present a share
    sheet after the action menu dismisses (the deferred-trigger contract), use UIKit's
    `UIActivityViewController`, presented from the presenting root view. Reference
    implementation: `Examples/ActionMenuSample/ActionMenuSample/ShareAction.swift`.
- No Combine unless explicitly approved — prefer async/await and `@Observable`
- No third-party dependencies unless explicitly approved — this is a dependency-free library

### 5. Git & Commit Discipline

- All commits MUST follow [Conventional Commits](https://www.conventionalcommits.org/):
  - `feat:` — new feature
  - `fix:` — bug fix
  - `chore:` — tooling, config, CI, project setup
  - `docs:` — documentation only
  - `refactor:` — code change that is neither a fix nor a feature
  - `test:` — adding or updating tests
  - `style:` — formatting, whitespace (no logic change)
- Keep commit messages concise (<72 chars for the subject line)

### 6. Self-Improvement (Mandatory)

Keep this file current. After every significant change (new dependency, new pattern, new workflow rule), update `AGENTS.md` to reflect it. This file is your primary memory across sessions — if it's stale, you'll repeat the same mistakes.

### 7. When to Delegate to Subagents

| If the task is... | Then... |
|---|---|
| A single-file change with an obvious root cause | **Always use @engineer** — CoS cannot write files |
| A bug involving state transitions, concurrency, or SwiftUI lifecycle | **Always use @engineer** or review with @code-reviewer first |
| A public API change (new modifier, protocol, style) | Use @architect for design, then @engineer for implementation |
| Crosses 3+ files or multiple concerns (view + modifier + style) | Use @architect first, then @engineer |
| Your first fix attempt failed | Reassess and escalate with more context |
| Involves SwiftUI List/ForEach/identity/crash | Use @engineer (notoriously tricky) |
| Writing tests | Use @quality-assurance after implementation |
| Updating README or documentation | Use @docs-writer |
| Trivial formatting or preview scaffolding | Use @boilerplate (free tier) |

## Patterns & Lessons Learned

### `.actionMenu` Modifier Pattern

The primary entry point for ActionMenu is the `.actionMenu` ViewModifier, which presents a bottom sheet with configurable actions. The modifier follows SwiftUI's standard presentation pattern:

```swift
.actionMenu(title: "Actions", isPresented: $isShowing) {
  Button("Option 1") { /* action */ }
  Button("Option 2") { /* action */ }
}
```

### Styling via Environment

Styles are propagated through the SwiftUI environment:

```swift
struct ActionMenuStyleKey: EnvironmentKey {
  static let defaultValue: any ActionMenuStyle = DefaultActionMenuStyle()
}

extension EnvironmentValues {
  var actionMenuStyle: any ActionMenuStyle {
    get { self[ActionMenuStyleKey.self] }
    set { self[ActionMenuStyleKey.self] = newValue }
  }
}
```

### Backporting for iOS Version Differences

Use `@available` checks for iOS version-specific features. The `.glassProminent` button style is available on iOS 26+ — use the backporting pattern for older versions:

```swift
extension View {
  @ViewBuilder
  func _tintProminentButtonStyle() -> some View {
    if #available(iOS 26, *) {
      self.buttonStyle(.glassProminent)
    } else {
      self.tint(.accentColor)
    }
  }
}

### Preventing Accent Color Bleed in Menu Buttons

When building a sheet-based menu with buttons (like ActionMenu), SwiftUI's `Button` automatically tints its label using the environment's accent color. This causes icons and text to render in the blue accent color instead of a neutral foreground color, which is inconsistent with Apple's Mail.app-style action menu appearance.

To fix this, apply two changes:

1. **On the container:** Add `.tint(.primary)` to the outermost container (List, VStack, etc.) to neutralise the environment tint for all buttons inside.
2. **On label styles:** Ensure any custom `LabelStyle` used for menu rows explicitly sets `.foregroundStyle(Color.primary)` on icons, rather than relying on `.foregroundStyle(Color.accentColor)` or the default tint.

**Pattern:**

```swift
struct ActionMenu: View {
  var body: some View {
    List {
      Button("Reply") { /* ... */ }
      Button("Forward") { /* ... */ }
    }
    .tint(.primary)  // Prevents accent color from bleeding into buttons
  }
}

struct MenuLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.icon
        .foregroundStyle(Color.primary)  // Explicitly use primary, not accent
      configuration.title
    }
  }
}
```

This pattern ensures buttons render with neutral foreground colors regardless of the app's accent/tint color configuration.

### Deferred Action Trigger (Sheet-Level Pending Action)

Action menu buttons must run their action only after the sheet is gone. The first attempt at this is **deprecated** because it was unreliable.

**Deprecated (buggy) pattern:** `@State shouldExecuteAction` inside a `PrimitiveButtonStyle`, firing `configuration.trigger()` from the *style's* own `onDisappear`. Failure modes:

- **Actions silently dropped** when `dismiss()` is a no-op (no sheet to dismiss) — the armed flag is never consumed, so the trigger never runs.
- **Armed flag misfiring** on a later, unrelated `onDisappear` (swipe-dismiss cancellation, row recycling, toolbar dismissal), running an action that was never tapped.
- **Two different buttons firing** during the dismiss animation, because each button's style armed its own flag and both `onDisappear` callbacks ran.

**Current pattern:** the sheet view owns the pending action, not the button style:

```swift
struct ActionMenu<Content: View>: View {
  @State private var pendingAction: (() -> Void)? = nil
  // ...
  .buttonStyle(ActionMenuButtonStyle(pendingAction: $pendingAction))
  .onDisappear {
    pendingAction?()
    pendingAction = nil
  }
  .onAppear {
    pendingAction = nil
  }
}
```

The button style receives `@Binding var pendingAction: (() -> Void)?`. On tap it stores the trigger and dismisses:

```swift
Button {
  pendingAction = { configuration.trigger() }
  dismiss()
} label: { /* ... */ }
```

**Contract:**
- The action fires exactly once, and only after the sheet is gone (`onDisappear`).
- Swipe-dismiss fires nothing — `pendingAction` was never armed.
- Rapid double-tap: last write wins — at most one action fires.

**Destructive-action awareness:** `Styling.swift` uses a private `IsDestructiveActionKey` `EnvironmentKey` (`\.isDestructiveAction`) so `MenuLabelStyle` can color the row's icon red for destructive roles without a per-row parameter.

This behavior is covered by the `ActionMenuSampleUITests` XCUITest suite.

### Self-Sizing Sheet (Internal Modifier)

`ActionMenu` sizes its sheet via an internal `SelfSizingSheetModifier` in `ActionMenu.swift` instead of leaking a `contentSize: Binding<CGSize>` through `ActionMenu.init`.

- The modifier owns `@State private var contentHeight: CGFloat` and applies it as a `.height` presentation detent.
- It measures the rows' geometry at runtime: each row gets a `GeometryReader` background (via `.listRowBackground`) that reports its **global** frame through a private `RowBoundsKey` `PreferenceKey`; `ActionMenu` aggregates the last row's bottom edge (`rowsBottom`) and the rows' leading margin (`sideMargin`), and also tracks the sheet root's global top (`sheetTop`, via `onGeometryChange` on the `NavigationStack`). The row background is rendered with the system grouped card color (`Color(uiColor: .secondarySystemGroupedBackground)`) so the measurement does not alter the row's appearance — do not "simplify" it back to `Color.clear`.
- The detent is **detent-independent** (no fixed point): it uses the rows' position relative to the sheet root, `rowsBottomInSheet = rowsBottom - sheetTop`, which is invariant under detent changes — the global measurements shift together and cancel out, so handle drags and detent cycling can never corrupt `contentHeight`. The target is `rowsBottomInSheet + sideMargin - sheetTopChrome`, where `sheetTopChrome` (≈21pt) is the sheet's grabber/rounded-top area that the presentation renders above the `.height` value — a fixed presentation constant, not a device or list style. Measuring inside a named coordinate space anchored at the sheet root was tried but is unreliable: the `.listRowBackground` views do not resolve the SwiftUI named space correctly.
- It falls back to `.medium` until the first measurement so the sheet never flashes at zero height, and keeps `.large` as an additional detent. The zero-sized pre-layout scroll-geometry callback is skipped so it cannot collapse the sheet.
- It throttles detent updates: re-applies only when the target changes meaningfully since the last applied detent (`contentHeight == 0 || abs(target - contentHeight) > 1`).
- Conventions: `title` defaults to `"Options"` consistently on both `ActionMenu.init` and the public `.actionMenu(...)` modifier; public content closures are non-escaping `@ContentBuilder` closures (consumed synchronously).

### Share Action Inside the Menu (Deferred + UIKit Exception)

The sample's Share row cannot be a `ShareLink` rendered inside the action menu:
- `share(...)`/`ShareLink` returns a *view* that only presents when tapped while alive
  in the hierarchy. Calling it from a `Button` action builds and discards the view — a
  silent no-op.
- A `ShareLink` row inside the menu is also subject to the ambient
  `.buttonStyle(ActionMenuButtonStyle)`, which dismisses the sheet without presenting.

Working pattern: a menu `Button` sets a deferred flag (fires after the menu dismisses,
per the deferred-trigger contract); the root view then presents a UIKit
`UIActivityViewController` (via a `UIViewControllerRepresentable` in a `.sheet`, or from
the root view controller). This is the project's documented UIKit exception — programmatic
share presentation is genuinely impossible in pure SwiftUI.
