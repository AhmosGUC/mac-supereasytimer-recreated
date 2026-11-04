# Instructions for AI coding agents

1. Read `docs/PRODUCT_SPEC.md`, `docs/CLEAN_ROOM.md` and the issue you're working on. The clean-room rules are mandatory.
2. Workflow: branch `issue-<N>-slug`, one issue per PR, `Closes #N`, fill the PR template checklist.
3. Environment: on Linux only `TimerCore` builds — run `swift test` (install Swift via swiftly if missing). App code must be verified by macOS CI (#4). Never mark UI work done without CI green + preview PNGs.
4. Architecture: `TimerCore` stays platform-independent (Foundation only; inject time via a `Clock`-like protocol, never call `Date()` directly in logic). The app target depends on `TimerCore`, never the reverse. Use AppKit for windows/status item, SwiftUI for view content.
5. Concurrency: UI state lives on `@MainActor`. Use `@Observable` (macOS 14) for view models.
6. Style: Swift API Design Guidelines, 4-space indent, no force-unwraps outside tests, doc comments on public API.
7. Assets: never add an asset without a Provenance log entry.
8. Ask in the issue instead of guessing when the spec is ambiguous.
