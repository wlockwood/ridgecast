# Sidebar workbench implementation plan

> Execute inline using the executing-plans skill. The selected design and implementation are authorized by the user.

**Goal:** Replace the long combined sidebar with Network, Coverage, and a pinnable Layers drawer after publishing the unchanged release.

**Architecture:** Separate panel bodies behind the existing sidebar entry point; retain shared application state and asynchronous persistence. Remember drawer visibility/pinning in MapSettings with Serde defaults.

**Validation:** Focused configuration and coverage-selection regression tests, full Cargo checks/tests, doc link checker, and an application UI smoke check where desktop access permits.

- [x] Publish v0.1.0 from e213692, verify all assets, and preserve a local release tag.
- [x] Add regression tests for drawer persistence and compatible defaults; observe failure before implementation.
- [x] Split the Network, Coverage, and Layers presentations while preserving cached node ordering and incident links.
- [x] Add floating/pinned drawer controls, map Fit menu, accurate selection/mode handling, test-radio summary, and advanced calculation controls.
- [x] Update user documentation, run required checks, and obtain one independent final review.
- [x] Address material review findings and verify the final application.

## Review Focus

Check selection changes and mode availability, zero/single/multiple eligible radios and amateur selections, pin/open/close transitions, map width on smaller windows, hidden-overlay data preparation access, context menus and cached node/link performance, persistence compatibility, tooltips, and old documentation navigation references. Automated tests do not exercise GPU/native-window rendering or downloading real terrain.

## Validation record

The pre-change v0.1.0 release was published before product edits. Configuration
persistence, responsive pinning, disabled document surfaces, and unavailable
comparison explanations each have observed failing-to-passing regressions.
The final desktop suite passed 1,819 tests with 16 integration tests ignored;
MCP passed 14 tests. Cargo check, formatting, strict all-target/all-feature
Clippy, and local documentation links (54 Markdown files) passed.

An independent source reviewer found the loading-time Window/Area enable-state
bug; it was reproduced and fixed. Native synthetic-data captures checked
pinned/floating layouts and a 1024×768 fallback. Native pointer automation was
limited by desktop lock/focus; captures verify rendering, not a complete native
interaction or real-download test. The fixture alone redirects configuration
paths; the shipped source has no fixture override.
