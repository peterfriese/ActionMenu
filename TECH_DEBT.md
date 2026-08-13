# ActionMenu — Technical Debt Backlog

Consolidated from the full-project audit (2026-08-13). Work through items step by step; tick boxes as they land. Each item notes where it lives and a suggested fix.

> Recently completed (committed 2026-08-13):
> - `feb0908` fix: defer action trigger to sheet-level pending action
> - `8a9a640` test: add XCUITest suite for action menu behavior
> - `af12eae` docs: sync toolbar section and deferred-trigger pattern
> - `88d5877` chore: align sample deployment target to 18.6
> - `d45cedc` chore: enable Swift 6 language mode in sample app
> - `a0f75dc` refactor: replace UIKit share sheet with ShareLink
> - `f559c06` refactor: extract shared fruit demo into reusable view
> - `0071e43` fix: delete only the first matching fruit row
> - `1b93cd3` refactor: self-size action menu sheet detent
> - `1c5cc61` refactor: throttle detent size updates
> - `8d20ed9` refactor: drop escaping from actionMenu content
> - `8972b31` refactor: default actionMenu title to Options
> - `b189e40` refactor: tighten detent throttle comparison
> - `7c6a3a8` docs: document actionMenu title default
> - `a9d351e` fix: present deferred share sheet via UIActivityViewController
> - `9b5dd6f` test: assert share sheet presents after menu dismisses

## 1. Docs describe a library that doesn't exist (needs a decision)

- [ ] **Decide & reconcile the documented `ActionMenuStyle` styling system** — `AGENTS.md` and `README.md` promise an `ActionMenuStyle` protocol, `.actionMenuStyle(_:)` modifier, `DefaultActionMenuStyle`, and `@Environment(\.actionMenuStyle)` propagation. None exist in `Sources/`. Option A: implement the styling system (real customization story). Option B: rewrite the docs to describe the actual `ButtonStyle`/`LabelStyle` approach (`.buttonStyle(.action)`, `.labelStyle(.menu)`). Needs an @architect recommendation first. Effort: L (A) / S (B).
- [ ] **Remove `Backport.swift` from the AGENTS.md module map** — the file does not exist; backports are inline `#available`. Effort: S.
- [ ] **Remove the stale `.glassProminent` / `_tintProminentButtonStyle()` lesson from AGENTS.md** — that code was removed; the guidance would mislead a future session. Effort: S.
- [ ] **Bump README install snippet to `from: "0.3.0"`** — currently `0.2.1`. Effort: S.
- [ ] **Fix the README claim that `ActionMenu.init(...)` is public API** — the struct is internal. Effort: S.
- [ ] **Update `.opencode/agents/architect.md`** — it treats `ActionMenuStyle` as an existing design surface. Effort: S.

## 2. Build / toolchain honesty

- [ ] **Fix `swift build` on macOS** — `Package.swift` declares only `.iOS(.v18)`, so `swift build` targets the macOS host (default macOS 12.0) and fails on `@Previewable`/`NavigationStack`/`onScrollGeometryChange` etc. Only builds via Xcode today. Fix: add a `.macOS(.v15)` platform (or gate the source, or document Xcode-only builds). Effort: S.
- [ ] **Bump `swift-tools-version` to match the `@ContentBuilder` toolchain requirement** — currently `6.0`, but `@ContentBuilder` needs Xcode 27+/Swift 6.2+. Also align the three version claims (manifest `6.0` / README `6.0+` / AGENTS.md `6.3`) on one number. Effort: S.
- [ ] **Clean stale `.build/` artifacts** from an older toolchain (`.build/debug.yaml` references a removed dual-target invocation). Effort: S.

## 3. Library design

- [x] **Replace the `contentSize: Binding<CGSize>` + magic `+34` detent with an internal self-sizing modifier** — `ActionMenu.init` leaks an implementation detail (callers must pass a binding just to size the sheet), and the sheet jumps from `.medium` to content height on first presentation. Reference pattern: Daniel Saidi's size-to-fit sheet modifier (https://danielsaidi.com/blog/2026/05/22/making-a-swiftui-sheet-automatically-size-to-fit-its-content) — a modifier owns `@State` height measured via geometry and applies `.height` as the detent. Adapt, don't copy: keep measuring the List's scroll content size (`onScrollGeometryChange`) to avoid a frame↔detent feedback loop, and keep a fallback for the unmeasured first frame. Effort: M. *(Committed 2026-08-13: `1b93cd3` — new internal `SelfSizingSheetModifier` owns `@State contentHeight`, measures the List's scroll content size via `onScrollGeometryChange` (avoids frame↔detent feedback loop), falls back to `.medium` until the first measurement, and removes the `contentSize` binding and the `+34` magic number. Verified: build-for-testing + 4/4 UI tests on a dedicated simulator.)*
- [ ] **Make `.action` / `.menu` styles public** (or fold into the styling-system decision in §1) — consumers currently can't use `.buttonStyle(.action)` / `.labelStyle(.menu)` outside the module. Effort: S.
- [x] **Throttle detent recomputation** — detents recompute on every scroll-geometry change. Effort: S. *(Committed 2026-08-13: `1c5cc61`, `b189e40` — detent re-applied only when the height changes meaningfully since the last applied detent.)*
- [x] **Remove `@escaping` from the public content closure** — it is consumed synchronously. Effort: S. *(Committed 2026-08-13: `8d20ed9` — the closure is consumed synchronously in `ActionMenuModifier.init`; `@ContentBuilder` kept.)*
- [x] **Resolve the asymmetric `title` default ("Options")** between `ActionMenu.init` and the public modifier. Effort: S. *(Committed 2026-08-13: `8972b31` — `title` defaults to `"Options"` on both `ActionMenu.init` and the public `.actionMenu(...)` modifier.)*
- [x] **Decide on the `ActionMenu` type/module name collision** — consider `ActionMenuView` if the type becomes public. Effort: S. *(Committed 2026-08-13: decision — keep the internal `ActionMenu` type as-is (no consumer-facing collision while internal); rename to `ActionMenuView` only if the type is ever made public.)*

## 4. Sample app

- [x] **Align `IPHONEOS_DEPLOYMENT_TARGET`** — `18.2` at project level vs `18.6` at target level in `project.pbxproj`. Effort: S. *(Committed 2026-08-13: `88d5877` — project level now `18.6`; all targets at `18.6`.)*
- [x] **Bump `SWIFT_VERSION` from 5.0 to 6.0** — the app builds against a Swift-6 package. Effort: S. *(Committed 2026-08-13: `d45cedc` — app target now Swift 6.0; zero strict-concurrency errors surfaced.)*
- [x] **Replace `ShareAction.swift`'s `UIActivityViewController` with `ShareLink`/`Transferable`** — UIKit violates the project's own no-UIKit rule; also drop the dead `subject:`/`message:` parameters, fix the inert `@preconcurrency`/Sendable gap, and drop `public` on the app-target type. Effort: S. *(Committed 2026-08-13: `a0f75dc`. The `ShareLink`-in-menu approach was subsequently abandoned: `ShareLink`/`share(...)` returns a view that only presents when tapped, so a share row rendered inside the menu silently no-ops (and the ambient `ActionMenuButtonStyle` dismisses without presenting). The share sheet is now presented after the menu dismisses via UIKit's `UIActivityViewController` (`a9d351e`) — the project's documented UIKit exception for programmatic share presentation, see AGENTS.md.)*
- [x] **De-triplicate the fruit-demo logic** — the two library `#Preview` blocks and the sample app each re-implement the same uppercase/lowercase/delete demo. Extract a shared demo view/model. Effort: M. *(Committed 2026-08-13: `f559c06` — the sample-side extraction is done: new `FruitStore` + `FruitDemoView`, hosted by `ContentView`; the two library `#Preview` blocks in `Sources/ActionMenu/ActionMenu.swift` still duplicate the demo and are tracked as a WP4 follow-up.)*

## 5. Testing

- [ ] **Add an SPM test target (`Tests/`) with unit tests** for the modifier/detent logic — currently no fast-feedback coverage; note `swift test` requires the §2 macOS-build fix first. Effort: M.
- [ ] **Add a non-UI unit test for the pending-action contract** (fires exactly once, last-wins) — depends on exposing testable internals. Effort: S–M.
