# Site Finder: full quality and mixed-device fast scans

Approved by the user on 2026-10-08: retain both a CPU-only full scan and an
explicit fast scan across CPU cores and available physical GPUs. Full quality
must never lose accuracy to accommodate GPU execution.

Full quality evaluates every candidate using the captured propagation settings
and existing CPU calculation, including full ITM where selected. Fast evaluates
every candidate with a versioned free-space / three-edge diffraction / two-ray
approximation matching the existing GPU shader. Fast CPU fallback must use that
same approximation, never switch a subset of candidates to full ITM. GPU failure,
missing GPUs and different CPU/GPU ratios must not change the selected model.

Fast uses a bounded shared CPU pool and independent hardware GPU queues with
dynamic work allocation. Available GPUs are those exposed by one selected compute
backend, disclosed in documentation; cross-backend enumeration cannot reliably
deduplicate identical cards through the current public identifiers.
All scoring inputs, terrain, clutter, noise, terminal
heights and origin conventions are frozen across queues. Cancellation and once
only candidate publication remain intact. GPU initialization stays off the UI
thread. Unsupported inputs fail explicitly rather than changing models.

The UI provides separate Full quality (CPU) and Fast (CPU + GPUs) actions, explains
their quality difference, records the model in retained/imported results, and
refines using the saved mode. Older cpu and gpu snapshots remain readable.
Full ITM on GPU is outside this implementation: the current shader is approximate.

Qualification includes CPU/shader path and candidate score parity on varied
terrain, cancellation/failure tests, full-quality mode regression tests, an
offline repeatable benchmark across worker budgets and adapter combinations,
and complete repository checks. Timings are evidence, never proof of accuracy.
