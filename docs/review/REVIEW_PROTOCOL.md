# Collaborative Code Review Protocol

This document defines the procedure for AI coding agents (GitHub Copilot, OpenAI Codex, Anthropic Claude, Google Antigravity) to collaboratively review and improve the RidgeCast codebase. Every participating agent MUST read and follow this protocol in full.

## 1. Overview

A collaborative review session is a **round-based** process. In each round:

1. **Review phase** — Every agent independently reviews ALL in-scope Rust, C++,
   shader, and user-documentation files across ALL quality dimensions. Agents
   run in parallel; each writes to its own findings file.
2. **Discussion phase** — After all participating independent reviews are submitted or explicitly withdrawn, each agent reads the other agents' findings, posts agreements, disagreements, and proposed resolutions.
3. **Resolution phase** — Agents converge on which changes to implement.
4. **Implementation phase** — One or more agents make the actual code changes.

Rounds repeat until the codebase converges (no CRITICAL findings, minimal disagreements). This design is resilient: if any agent is unavailable (e.g., no credits remaining), the others still cover every quality dimension.

## 2. Project Context

RidgeCast is a desktop radio network planning application written in **Rust** with:

- **GUI**: egui (immediate-mode) rendered via wgpu
- **Propagation models**: ITM (Longley-Rice) via C++ FFI (`cpp/`), ITU-R P.1812, free-space
- **Terrain**: Downloaded GeoTIFF elevation data (3DEP, SRTM), land-cover (NLCD)
- **GPU compute**: Custom wgpu compute shaders for coverage calculation
- **Data**: SQLite (FCC amateur radio), JSON network files, disk-cached terrain tiles
- **Concurrency**: Background threads for terrain downloads, coverage computation, population analysis

### Code Conventions (from CONTRIBUTING.md)

- Prefer small domain types over long positional argument lists
- Keep expensive I/O, terrain work, and propagation off the UI thread
- Preserve cancellation checks in long loops and background jobs
- Avoid panics on downloaded, imported, or user-authored data
- Comment invariants, coordinate transforms, model assumptions, concurrency ownership, performance bounds
- Do NOT narrate straightforward code
- Keep serialized configuration backward compatible (Serde defaults/aliases)

### Key Directories

```
src/
├── main.rs              # Entry point
├── app/                 # GUI, user actions, config, exports
│   ├── actions.rs       # Core user action handlers
│   ├── ui/              # UI panels and widgets
│   └── config.rs        # Application configuration
├── engine/              # Computation core
│   ├── propagation.rs   # Propagation model dispatch
│   ├── itm.rs           # ITM C++ FFI bridge
│   ├── itm_dsm.rs       # ITM with DSM terrain
│   ├── gpu.rs           # GPU compute pipeline
│   ├── terrain/         # Terrain data management
│   ├── landcover.rs     # NLCD land cover integration
│   ├── population.rs    # Population coverage analysis
│   └── site_finder.rs   # Optimal site placement
├── graph/               # Network graph data structures
├── map/                 # Map rendering
└── shaders/             # WGSL compute shaders
cpp/                     # C++ ITM implementation
```

## 3. Standing Rules

Every agent MUST check these on every file it reviews in each round. Round 1
covers the complete configured scope; later-round coverage follows §8 and must
be reported accurately. These rules are not optional or domain-specific.

### 🔒 Rule 1: Nothing blocks the UI thread

The egui render loop runs on the main thread. Any operation that could take more than a few milliseconds MUST be offloaded to a background thread, including:

- Terrain tile loading or downloading
- Propagation calculations (ITM, P.1812, free-space)
- Coverage computation (CPU or GPU dispatch)
- SQLite queries
- File I/O (network save/load, exports, imports)
- Population analysis
- HTTP requests of any kind

Flag any `std::thread::sleep`, synchronous network calls, blocking file reads, or heavy computation found on a UI code path. This is always 🔴 CRITICAL.

### 🏷️ Rule 2: All controls must have tooltips

Every interactive egui control (buttons, sliders, checkboxes, dropdowns, text inputs, radio buttons, collapsing headers with non-obvious names) MUST have a `.on_hover_text()` or equivalent tooltip explaining what it does.

Missing tooltips are 🟡 WARNING severity.

### 📖 Rule 3: All features must be documented in the user docs

Every user-visible feature, setting, and capability must be documented on the
appropriate tutorial, how-to, reference, or concept page reachable from
`docs/README.md`. Major capabilities must also be represented in the root
`README.md`. If a feature is absent from the user documentation, or documented
only in an unreachable page, flag it as 🟡 WARNING.

## 4. Quality Dimensions

Every agent reviews ALL of these dimensions on every file. There is no domain specialization — every agent is a generalist.

### Style
- Formatting, naming conventions, idiomatic Rust
- Documentation quality and completeness
- Dead code, unused imports, redundant logic
- API ergonomics, public interface clarity

### Architecture
- Module boundaries and dependency structure
- Abstraction leaks and inappropriate coupling
- Extensibility and separation of concerns
- Public API design and module organization

### Safety
- Error handling completeness — `unwrap()`, `expect()`, `panic!()` on external data
- Concurrency bugs — data races, deadlocks, missing cancellation checks
- `unsafe` blocks and FFI boundary correctness
- Input validation, bounds checking, resource leaks

### Performance
- Hot-path algorithmic complexity
- Allocation patterns, unnecessary cloning or copying
- GPU pipeline efficiency, shader dispatch
- Parallelism, thread pool usage, cache behavior
- I/O patterns and redundant disk/network access

## 5. Session Management

### Starting or Joining a Session

1. **Create `.review/`** at the project root if it does not exist.

2. **Read `.review/session.json`**:
   - If it does not exist → create a new session (see below).
   - If `status` is `"active"` → join the existing session at its current round and phase.
   - If `status` is `"complete"` → rename to `session-<timestamp>.json`, create a new session.

3. **New `session.json`**:
```json
{
  "session_id": "<YYYY-MM-DD-HHMMSS>",
  "status": "active",
  "scope": ["."],
  "current_round": 1,
  "rounds": [
    {
      "round": 1,
      "phase": "review",
      "agents_reviewed": [],
      "agents_discussed": [],
      "agents_resolved": [],
      "changes_implemented": false,
      "critical_count": 0,
      "disagreement_count": 0
    }
  ]
}
```

The example scope means the whole tracked project: source, C++ and shaders,
root documentation and manifests, tests, tools, packaging, resources, workflows,
and agent instructions. Include explicitly requested untracked authored files.
Exclude Git internals, generated build outputs, caches/downloaded datasets, and
current review reports during independent review. Binary assets are inspected
through their purpose, metadata, and provenance rather than as source text.

For a scoped review, record the relevant roots explicitly; `src/` alone does not
include the C++ bridge, MCP crate, or root/user documentation. Throughout this
protocol and linked quick starts, **ALL files/source** means every file in that
configured session scope, plus related callers, FFI, shaders, and documentation
needed to assess the requested change; it does not silently expand a scoped
request into a whole-project review.

The first participant is the session coordinator unless participants choose
another. The coordinator serializes writes to `session.json` and phase changes;
other agents submit their status updates to it. Each findings file remains
independently owned. The coordinator merges updates into the latest session
state so one participant's status cannot overwrite another's.

### When only one agent is available

Record only the agents that actually participate. A sole participant still
completes every phase: its discussion entry states that no peer findings were
available, and its resolutions cite its own verification evidence rather than
claiming consensus with absent agents. All verification and repeat-round rules
still apply. The final summary must identify the review as single-agent and state
that independent peer review did not occur. If another agent joins while the
session is active, it follows the normal independent-review and discussion steps.

## 6. Phase 1 — Independent Review

Each agent reviews ALL source files and writes findings to its own file. Since agents run in parallel, each writes to a **separate file** to avoid conflicts.

### Procedure

1. **Determine the current round** from `session.json`.
2. **Create your findings file**: `.review/round-<N>-findings-<agent>.md`
   - Example: `.review/round-1-findings-antigravity.md`
3. **In round 1, review every file in the configured scope**; in later rounds,
   review the minimum coverage defined in §8. This includes Rust source,
   `cpp/` FFI code, WGSL shaders, and the user documentation needed to check
   the standing documentation rule. Add those roots to the session scope when
   they are relevant to the change.
4. **Check every applicable file against**:
   - All four quality dimensions (§4)
   - All three standing rules (§3)
5. **Write findings** using the format in §9.
6. **Submit a session update to the coordinator**: Add your agent name to the current round's `agents_reviewed` array.

### How many files to review

For round 1, review ALL files in scope. Later rounds cover the changed files and
affected surfaces defined in §8. Process them methodically; if context runs out,
record covered files and those remaining. Every round's report states its actual
coverage and identifies any files not revisited.

## 7. Phase 2 — Discussion

Discussion starts only after every currently participating agent has posted its
independent findings or explicitly withdrawn. Until then, reviewers do not read
one another's current-round reports. The coordinator records withdrawals and
changes the phase after this barrier is met; late joiners complete their own
independent review before reading discussion.

### Procedure

1. **Read ALL other agents' findings files** for the current round.
2. **Append to `.review/round-<N>-discussion.md`** using the format in §9.
3. For each finding from another agent:
   - **Agree** — state why and whether you found the same issue.
   - **Disagree** — state why with specific evidence (code, docs, standards).
   - **Expand** — add context, suggest a different fix, or escalate severity.
4. Raise any findings you had that OTHER agents missed.
5. **Propose resolutions** — for each agreed-upon issue, propose the specific fix.
6. **Submit a session update to the coordinator**: Add your name to `agents_discussed`. Update `disagreement_count`.

### Discussion Rules

- **Never edit or delete** another agent's entries.
- **Always append** at the bottom.
- Quote the specific finding you're responding to.
- Keep it technical. No filler.

## 8. Phase 3 — Resolution & Implementation

### Determining Resolutions

After discussion, resolutions are determined by **consensus**:
- If all participating agents agree on a fix → implement it.
- If agents disagree → the majority opinion wins. If tied, the more conservative (safer) option wins.
- 🔴 CRITICAL findings are always implemented unless a clear majority disagrees with the classification.

### Implementation

1. **Make the code changes** in the actual source files.
2. **Run verification**:
   ```bash
   cargo check
   cargo fmt --all -- --check
   cargo clippy --all-targets --all-features -- -D warnings
   cargo test
   ```
3. **Document changes** in `.review/round-<N>-changes.md`:
   - File, lines changed, what was fixed, which finding it resolves.
4. **Submit a session update to the coordinator**: Set `changes_implemented: true`.

### Deciding Whether to Run Another Round

Run another round if ANY of these conditions are true:

| Condition | Threshold |
|-----------|-----------|
| 🔴 CRITICAL findings were found | Any count > 0 |
| Significant disagreements remain | `disagreement_count` > 2 |
| Implementation changed > 100 lines | Always re-review large changes |
| Standing rule violations found | Any count > 0 |

If another round is needed:
1. Increment `current_round` in `session.json`.
2. Add a new round entry to the `rounds` array.
3. Return to Phase 1 — agents re-review all changed files plus affected callers,
   dependencies, serialization/FFI boundaries, shaders, tests, and user-facing
   documentation. Check all standing rules on those surfaces. Re-review the
   full configured scope when changes cannot be bounded safely; otherwise list
   the unchanged files not revisited instead of claiming another complete pass.

If no further rounds are needed:
1. Resolve every disagreement under the consensus/majority rules above before
   setting `status` to `"complete"`. Record the decision, evidence, minority
   objections, and any accepted noncritical limitation in the final summary.
   The `> 2` threshold selects another broad round; it does not permit closing
   with one or two unresolved disagreements. The coordinator updates the status.
2. Write `.review/final-summary.md` with the complete history of findings, resolutions, and changes across all rounds.

## 9. File Formats

### Findings File (`.review/round-<N>-findings-<agent>.md`)

```markdown
# Round <N> Findings — <Agent Name>

**Date**: <ISO-8601>
**Scope**: <directories reviewed>
**Files reviewed**: <count>

---

## <file path>

### 🔴 CRITICAL: <short title>
**Lines**: L<start>–L<end>
**Dimension**: <Style | Architecture | Safety | Performance | Standing Rule>
**Description**: <what's wrong and why it matters>
**Suggested fix**:
\```rust
// replacement code
\```

### 🟡 WARNING: <short title>
**Lines**: L<start>–L<end>
**Dimension**: <dimension>
**Description**: <explanation>
**Suggested fix**: <description or code>

### 🔵 SUGGESTION: <short title>
**Lines**: L<start>–L<end>
**Dimension**: <dimension>
**Description**: <improvement idea>

### ⚪ NOTE: <short title>
**Description**: <observation or context>

---

## Summary

**Total findings**: 🔴 <n> | 🟡 <n> | 🔵 <n> | ⚪ <n>
**Standing rule violations**: <count>
**Top concerns**:
1. <most important>
2. <second>
3. <third>
```

### Discussion File (`.review/round-<N>-discussion.md`)

```markdown
# Round <N> Discussion

---

## <Agent Name> — Discussion Entry

**Date**: <ISO-8601>
**Responding to**: <list of agents whose findings you read>

### Agreements

> **Re: <Other Agent> on <file>** — "<finding title>"
> Agree. <reasoning>. Same issue found in my review at L<line>.

### Disagreements

> **Re: <Other Agent> on <file>** — "<finding title>"
> Disagree. <evidence and reasoning>.
> **Proposed reclassification**: 🟡 WARNING → ⚪ NOTE because <reason>.

### Missed by Others

#### 🟡 WARNING: <title> in <file>
<description of finding other agents missed>

### Proposed Resolutions

| # | File | Finding | Proposed Fix | Agents Agreeing |
|---|------|---------|-------------|-----------------|
| 1 | src/engine/gpu.rs | Blocking dispatch | Move to background thread | Antigravity, Claude |
| 2 | ... | ... | ... | ... |

---
```

### Changes File (`.review/round-<N>-changes.md`)

```markdown
# Round <N> Changes

**Implemented by**: <agent name>
**Date**: <ISO-8601>

## Changes

| File | Lines | Change | Resolves |
|------|-------|--------|----------|
| src/engine/gpu.rs | L45–L60 | Moved dispatch to background thread | Round 1, Finding #3 |
| ... | ... | ... | ... |

## Verification

- `cargo check`: ✅ / ❌
- `cargo fmt`: ✅ / ❌
- `cargo clippy`: ✅ / ❌
- `cargo test`: ✅ / ❌

## Notes

<any context about the changes>
```

## 10. Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| 🔴 CRITICAL | Bug, security flaw, data loss risk, UI thread block, correctness issue | Must fix this round |
| 🟡 WARNING | Code smell, missing tooltip, undocumented feature, fragile pattern | Should fix this round |
| 🔵 SUGGESTION | Improvement idea — cleaner API, better naming, optimization | Fix if time permits |
| ⚪ NOTE | Observation, context, or explanation for other agents | No action needed |

## 11. Invoking This Review

Tell any agent:

> "Perform a collaborative code review following the review protocol."

Or scoped:

> "Perform a collaborative code review of `src/engine/` following the review protocol."

### Agent-Specific Triggers

| Agent | How to trigger |
|-------|---------------|
| **Copilot** | Open the prompt picker in VS Code → select **code-review** |
| **Codex** | Ask: *"Perform a collaborative code review"* (reads AGENTS.md automatically) |
| **Claude** | Ask: *"Perform a collaborative code review"* (reads CLAUDE.md automatically) |
| **Antigravity** | Skill auto-discovered as `collaborative-review`, or ask for a "collaborative code review" |
